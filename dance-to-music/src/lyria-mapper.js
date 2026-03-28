/**
 * lyria-mapper.js — Body-is-the-Band mapping engine.
 *
 * YOUR BODY IS THE BAND. Each body part is a musician:
 *   - FEET = Drummer (kick, snare, hats, percussion)
 *   - CORE/HIPS = Bassist (bass lines, sub bass, low-end groove)
 *   - HANDS/ARMS = Melodist (piano, synths, guitar, melody)
 *   - HEAD = Atmosphere (pads, reverb, ambience, texture)
 *
 * Stand still = silence. Move one part = solo. Move everything = full band.
 * HOW you move shapes the character: sharp = punchy, smooth = flowing.
 *
 * Design spec: docs/superpowers/specs/2026-03-13-lyria-mapper-design.md
 */

// Body part activation thresholds
const FEET_THRESHOLD = 0.10;    // footSpeed above this = drummer plays
const CORE_THRESHOLD = 0.06;    // coreSpeed above this = bassist plays
const HANDS_THRESHOLD = 0.12;   // handSpeed above this = melodist plays
const HEAD_THRESHOLD = 0.003;   // headBob above this = atmosphere plays

// Per-part intensity normalization (maps speed to 0-1 intensity)
const FEET_MAX = 0.8;
const CORE_MAX = 0.5;
const HANDS_MAX = 1.5;
const HEAD_MAX = 0.015;

// Energy derivative (TIME-BASED -- framerate varies 15-60fps)
const ENERGY_HISTORY_SECONDS = 3.0;
const DERIVATIVE_WINDOW_SECONDS = 2.0;
const BUILD_THRESHOLD = 0.5;
const FALL_THRESHOLD = -0.5;
const FREEZE_THRESHOLD = -3.0;

// Density
const DENSITY_GAMMA = 0.6;
const BURST_DECAY = 0.85;
const BURST_MIN = 0.1;
const BURST_MAX = 0.4;

// Groove lock
const GROOVE_HISTORY_SECONDS = 2.0;
const GROOVE_VARIANCE_THRESHOLD = 0.5;
const GROOVE_GUIDANCE_FLOOR = 4.5;

// Smoothness
const JERK_MAX = 500;

// Band prompt fragments per genre -- what each "musician" sounds like
// Each body part gets genre-appropriate instrumentation language
const BAND_INSTRUMENTS = {
  hiphop: {
    drums: "punchy 808 kick, crispy snare, trap hi-hats",
    bass:  "deep 808 bass, sub bass slides",
    melody: "dark piano melody, vocal chops, synth leads",
    atmos: "vinyl crackle, reverb atmosphere, ambient pads",
    solo:  "90s hip hop",
  },
  edm: {
    drums: "four on the floor kick, driving percussion, claps",
    bass:  "heavy synthesizer bass, wobble bass",
    melody: "euphoric synth leads, arpeggiated chords, bright stabs",
    atmos: "swelling pads, white noise risers, reverb wash",
    solo:  "electronic dance music",
  },
  lofi: {
    drums: "mellow boom bap drums, soft kick, brushed snare",
    bass:  "warm upright bass, mellow bass notes",
    melody: "jazzy piano chords, warm Rhodes, gentle guitar",
    atmos: "vinyl crackle, rain sounds, tape hiss, lo-fi texture",
    solo:  "chill lo-fi hip hop",
  },
  latin: {
    drums: "dembow rhythm, congas, timbales, latin percussion",
    bass:  "reggaeton bass, deep bass hits",
    melody: "tropical synths, brass stabs, melodic hooks",
    atmos: "shaker textures, ambient tropical sounds",
    solo:  "reggaeton latin",
  },
  rnb: {
    drums: "gentle R&B drums, soft kick, finger snaps",
    bass:  "deep smooth bass, round bass notes",
    melody: "silky Rhodes piano, soulful vocal runs, warm chords",
    atmos: "lush pads, smooth reverb, atmospheric strings",
    solo:  "smooth R&B",
  },
  cinematic: {
    drums: "epic percussion, taiko drums, orchestral hits",
    bass:  "deep cello, contrabass, low brass",
    melody: "soaring strings, french horn melody, piano theme",
    atmos: "ethereal choir, string tremolo, cinematic atmosphere",
    solo:  "cinematic orchestral",
  },
  kpop: {
    drums: "punchy K-pop drums, tight snare, electronic percussion",
    bass:  "punchy synth bass, groovy bass line",
    melody: "bright synth hooks, catchy melodic riff, vocal chops",
    atmos: "shimmering pads, sparkle effects, bright atmosphere",
    solo:  "K-pop dance",
  },
  afrobeat: {
    drums: "afrobeats percussion, shekere, djembe, dancehall drums",
    bass:  "afrobeats bass guitar, deep groove bass",
    melody: "highlife guitar licks, melodic brass, tropical leads",
    atmos: "nature textures, warm reverb, African flute",
    solo:  "afrobeats",
  },
};

export class LyriaMapper {
  constructor() {
    this._energyHistory = [];
    this._elapsedTime = 0;
    this._grooveHistory = [];
    this._densityBurst = 0;
    this._arc = "cruise";
    this._grooveLocked = false;
    // Track previous band state to avoid spamming prompt updates
    this._prevBandKey = "";
  }

  reset() {
    this._energyHistory = [];
    this._grooveHistory = [];
    this._elapsedTime = 0;
    this._densityBurst = 0;
    this._arc = "cruise";
    this._grooveLocked = false;
    this._prevBandKey = "";
  }

  /**
   * @param {{ raw: object, smoothed: object }} features
   * @param {number} dt
   * @returns {{ density, brightness, guidance, temperature, muteDrums, muteBass, mood, moodSuffix, bandPrompt }}
   */
  update(features, dt = 0.033) {
    const { raw, smoothed } = features;
    this._elapsedTime += dt;

    // ===== 1. BODY PART ISOLATION — WHO IS ON STAGE =====
    const feetActive  = smoothed.footSpeed > FEET_THRESHOLD;
    const coreActive  = smoothed.coreSpeed > CORE_THRESHOLD;
    const handsActive = smoothed.handSpeed > HANDS_THRESHOLD;
    const headActive  = smoothed.headBob > HEAD_THRESHOLD;

    // Per-part intensity (0-1): how HARD each musician is playing
    const feetIntensity = feetActive
      ? Math.min(1, (smoothed.footSpeed - FEET_THRESHOLD) / (FEET_MAX - FEET_THRESHOLD))
      : 0;
    const coreIntensity = coreActive
      ? Math.min(1, (smoothed.coreSpeed - CORE_THRESHOLD) / (CORE_MAX - CORE_THRESHOLD))
      : 0;
    const handsIntensity = handsActive
      ? Math.min(1, (smoothed.handSpeed - HANDS_THRESHOLD) / (HANDS_MAX - HANDS_THRESHOLD))
      : 0;
    const headIntensity = headActive
      ? Math.min(1, (smoothed.headBob - HEAD_THRESHOLD) / (HEAD_MAX - HEAD_THRESHOLD))
      : 0;

    const activeParts = (feetActive ? 1 : 0) + (coreActive ? 1 : 0)
                      + (handsActive ? 1 : 0) + (headActive ? 1 : 0);

    // Direct instrument control
    const muteDrums = !feetActive;
    const muteBass  = !coreActive;

    // ===== 2. ENERGY DERIVATIVE (THE ARC) =====
    const now = this._elapsedTime;
    this._energyHistory.push({ energy: raw.totalKE, time: now });
    while (this._energyHistory.length > 1 &&
           now - this._energyHistory[0].time > ENERGY_HISTORY_SECONDS) {
      this._energyHistory.shift();
    }

    let derivative = 0;
    const targetTime = now - DERIVATIVE_WINDOW_SECONDS;
    if (this._energyHistory.length >= 2 && this._energyHistory[0].time <= targetTime) {
      let pastSample = this._energyHistory[0];
      for (const sample of this._energyHistory) {
        if (sample.time <= targetTime) pastSample = sample;
        else break;
      }
      const elapsed = now - pastSample.time;
      if (elapsed > 0.5) {
        derivative = (raw.totalKE - pastSample.energy) / elapsed;
      }
    }

    if (derivative < FREEZE_THRESHOLD) {
      this._arc = "freeze";
    } else if (derivative > BUILD_THRESHOLD) {
      this._arc = "build";
    } else if (derivative < FALL_THRESHOLD) {
      this._arc = "fall";
    } else {
      this._arc = "cruise";
    }

    // ===== 3. SMOOTHNESS (percussive vs fluid) =====
    const smoothness = 1 - Math.min(1, Math.max(0, smoothed.jerkMagnitude / JERK_MAX));

    // ===== 4. GROOVE LOCK =====
    this._grooveHistory.push({ energy: raw.totalKE, time: now });
    while (this._grooveHistory.length > 1 &&
           now - this._grooveHistory[0].time > GROOVE_HISTORY_SECONDS) {
      this._grooveHistory.shift();
    }

    if (this._grooveHistory.length >= 10 &&
        now - this._grooveHistory[0].time >= 1.0) {
      const values = this._grooveHistory.map(s => s.energy);
      const mean = values.reduce((a, b) => a + b, 0) / values.length;
      const variance = values.reduce((s, v) => s + (v - mean) ** 2, 0) / values.length;
      this._grooveLocked = Math.sqrt(variance) < GROOVE_VARIANCE_THRESHOLD;
    } else {
      this._grooveLocked = false;
    }

    // ===== 5. DENSITY — driven by HOW MANY parts + their intensity =====
    // Each active part contributes its intensity. Full band at full tilt = 1.0.
    // Gamma curve lifts quiet playing so even gentle movement is audible.
    const rawDensity = (feetIntensity * 0.3 + coreIntensity * 0.25
                      + handsIntensity * 0.3 + headIntensity * 0.15);
    let density = Math.pow(Math.min(1, rawDensity), DENSITY_GAMMA);

    // Foot contact burst
    if (smoothed.footContact > 0.3) {
      const burstAmount = Math.min(BURST_MAX, Math.max(BURST_MIN, smoothed.ankleAccel / 10));
      this._densityBurst = burstAmount;
    }
    density = Math.min(1, density + this._densityBurst);
    this._densityBurst *= BURST_DECAY;
    if (this._densityBurst < 0.01) this._densityBurst = 0;

    // Arc modulation
    if (this._arc === "freeze") {
      density = Math.min(1, density * 0.3);
    } else if (this._arc === "build") {
      density = Math.min(1, density * 1.15);
    }

    // ===== 6. BRIGHTNESS — movement quality + hand intensity =====
    const qualityBrightness = 1 - smoothness;
    const speedBrightness = Math.min(1, raw.handSpeed / 3.0);
    let brightness = qualityBrightness * 0.6 + speedBrightness * 0.4;
    if (smoothed.headBob > 0.005) {
      brightness = Math.min(1, brightness + 0.15);
    }

    // ===== 7. TEMPERATURE — smoothness-driven =====
    let temperature = 0.7 + smoothness * smoothness * (3 - 2 * smoothness) * 1.0;
    if (activeParts === 0) temperature = 0.8;
    if (this._arc === "build") temperature = Math.min(2.0, temperature + 0.2);
    else if (this._arc === "freeze") temperature = Math.max(0.5, temperature - 0.3);

    // ===== 8. GUIDANCE — arm spread + groove lock =====
    const armNorm = Math.min(1, Math.max(0, (smoothed.armSpread - 0.1) / 0.5));
    let guidance = 6.0 - armNorm * 4.0;
    if (this._arc === "build") guidance = Math.max(1.5, guidance - 0.5);
    if (this._grooveLocked) guidance = Math.max(guidance, GROOVE_GUIDANCE_FLOOR);

    // ===== 9. BAND PROMPT — the key differentiator =====
    // Build instrumentation prompt from active body parts.
    // This is what makes every dancer's music unique: the COMBINATION
    // of body parts that are active determines which instruments play.
    const quality = smoothness > 0.6 ? "smooth" : "sharp";
    const energyLevel = density < 0.25 ? "low" : density < 0.6 ? "mid" : "high";
    const mood = quality + "_" + energyLevel;

    // Build band roster from active parts
    const bandKey = `${feetActive ? "F" : "_"}${coreActive ? "C" : "_"}${handsActive ? "H" : "_"}${headActive ? "A" : "_"}`;

    // Construct the instrumentation prompt describing who's on stage
    let moodSuffix = "";
    if (activeParts > 0) {
      moodSuffix = this._buildBandSuffix(
        feetActive, coreActive, handsActive, headActive, activeParts
      );
    }

    // Track band key for debug
    this._prevBandKey = bandKey;

    return {
      density: Math.max(0, Math.min(1, density)),
      brightness: Math.max(0, Math.min(1, brightness)),
      guidance: Math.max(1.5, Math.min(6.0, guidance)),
      temperature: Math.max(0.5, Math.min(2.0, temperature)),
      muteDrums,
      muteBass,
      mood,
      moodSuffix,
      // Extra info for lyria-player to build the full band prompt
      bandMembers: { feetActive, coreActive, handsActive, headActive },
      bandIntensity: { feetIntensity, coreIntensity, handsIntensity, headIntensity },
    };
  }

  /**
   * Build a descriptive suffix that tells Lyria exactly which instruments
   * should be prominent based on active body parts.
   */
  _buildBandSuffix(feet, core, hands, head, count) {
    // Solo performances -- most distinctive
    if (count === 1) {
      if (feet) return ", drums solo, percussion only, no melody, no bass";
      if (core) return ", bass solo, deep groove only, no drums, no melody";
      if (hands) return ", melody solo, solo instrument, no drums, no bass";
      if (head) return ", ambient atmosphere only, pads, no rhythm, no melody";
    }

    // Duos -- clear pairings
    if (count === 2) {
      if (feet && core)  return ", drums and bass duo, rhythm section only, no melody";
      if (feet && hands) return ", drums and melody, rhythmic melody, no bass";
      if (feet && head)  return ", drums with atmospheric pads, percussive ambient";
      if (core && hands) return ", bass and melody, melodic groove, no drums";
      if (core && head)  return ", bass with ambient pads, deep atmospheric";
      if (hands && head) return ", melody with ambient pads, floating melodic, no rhythm";
    }

    // Trios
    if (count === 3) {
      if (!head)  return ", full rhythm section with melody, drums bass and lead";
      if (!hands) return ", drums bass and atmosphere, deep groove with pads";
      if (!core)  return ", drums melody and atmosphere, rhythmic and airy";
      if (!feet)  return ", bass melody and atmosphere, smooth melodic groove";
    }

    // Full band
    return ", full band, all instruments, powerful full arrangement";
  }

  get arc() { return this._arc; }
  get grooveLocked() { return this._grooveLocked; }
  get bandKey() { return this._prevBandKey; }
}
