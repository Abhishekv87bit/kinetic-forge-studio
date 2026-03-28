/**
 * mapper.js — Maps body parts to instruments via hand-crafted rules.
 *
 * Now GENRE-AWARE: each genre has unique scales, chords, timing, and feel.
 *
 * Body → Instrument mapping:
 *   Hands (speed + height)    → Melody (pitch from height, trigger from speed)
 *   Hips (bounce)             → Bass line (dip detection → bass note)
 *   Feet (foot contact)       → Kick drum (foot strike → kick hit)
 *   Head (bob)                → Hi-hat accents (bob → metallic tick)
 *   Arms (spread)             → String pad (wide = lush, close = silent)
 *   Body (tilt)               → Stereo pan (lean left/right)
 *   Movement quality (jerk)   → Reverb (smooth = spacious, sharp = dry)
 */

// --- Genre-specific musical configurations ---
const GENRE_CONFIG = {
  hiphop: {
    melodyScale: ["C4","Eb4","F4","G4","Bb4","C5","Eb5","F5","G5","Bb5","C6"],
    bassScale:   ["C2","Eb2","F2","G2","Bb2","C3"],
    padChords: {
      low:  ["C3", "Eb3", "G3"],
      mid:  ["C3", "Eb3", "G3", "Bb3"],
      high: ["C3", "Eb3", "G3", "Bb3", "F4"],
      full: ["C3", "Eb3", "G3", "Bb3", "D4", "F4"],
    },
    melodyTrigger: 0.45,
    melodyDebounce: 140,
    melodyDuration: "8n",
    bassDebounce: 220,
    bassDuration: "4n",
    kickThreshold: 0.12,
    hatThreshold: 0.004,
  },
  edm: {
    melodyScale: ["C4","D4","E4","G4","A4","C5","D5","E5","G5","A5","C6"],
    bassScale:   ["C2","E2","G2","C3","E3","G3"],
    padChords: {
      low:  ["C3", "E3", "G3"],
      mid:  ["C3", "E3", "G3", "B3"],
      high: ["C3", "E3", "G3", "B3", "D4"],
      full: ["C3", "E3", "G3", "B3", "D4", "A4"],
    },
    melodyTrigger: 0.40,
    melodyDebounce: 90,
    melodyDuration: "16n",
    bassDebounce: 160,
    bassDuration: "8n",
    kickThreshold: 0.10,
    hatThreshold: 0.003,
  },
  lofi: {
    melodyScale: ["C4","D4","E4","G4","A4","B4","C5","D5","E5","G5","A5"],
    bassScale:   ["C2","D2","E2","G2","A2","B2"],
    padChords: {
      low:  ["C3", "E3", "A3"],
      mid:  ["D3", "F3", "A3", "C4"],
      high: ["C3", "E3", "G3", "B3"],
      full: ["D3", "F3", "A3", "C4", "E4"],
    },
    melodyTrigger: 0.50,
    melodyDebounce: 180,
    melodyDuration: "4n",
    bassDebounce: 280,
    bassDuration: "2n",
    kickThreshold: 0.15,
    hatThreshold: 0.005,
  },
  latin: {
    melodyScale: ["C4","D4","E4","F4","G4","Ab4","B4","C5","D5","E5","F5"],
    bassScale:   ["C2","D2","E2","F2","G2","C3"],
    padChords: {
      low:  ["C3", "E3", "G3"],
      mid:  ["C3", "E3", "G3", "Bb3"],
      high: ["F3", "A3", "C4", "E4"],
      full: ["C3", "E3", "G3", "Bb3", "D4", "F4"],
    },
    melodyTrigger: 0.42,
    melodyDebounce: 100,
    melodyDuration: "8n",
    bassDebounce: 180,
    bassDuration: "4n",
    kickThreshold: 0.10,
    hatThreshold: 0.003,
  },
  rnb: {
    melodyScale: ["C4","Eb4","F4","G4","Bb4","C5","D5","Eb5","F5","G5","Bb5"],
    bassScale:   ["C2","Eb2","F2","G2","Bb2","C3"],
    padChords: {
      low:  ["C3", "Eb3", "G3", "Bb3"],
      mid:  ["Ab2", "C3", "Eb3", "G3"],
      high: ["F3", "Ab3", "C4", "Eb4"],
      full: ["C3", "Eb3", "G3", "Bb3", "D4", "F4"],
    },
    melodyTrigger: 0.48,
    melodyDebounce: 160,
    melodyDuration: "4n",
    bassDebounce: 240,
    bassDuration: "4n",
    kickThreshold: 0.13,
    hatThreshold: 0.004,
  },
  cinematic: {
    melodyScale: ["C4","D4","Eb4","F4","G4","Ab4","Bb4","C5","D5","Eb5","G5"],
    bassScale:   ["C2","Eb2","F2","G2","Ab2","Bb2"],
    padChords: {
      low:  ["C3", "G3", "C4"],
      mid:  ["C3", "Eb3", "G3", "Bb3"],
      high: ["Ab2", "C3", "Eb3", "G3", "Bb3"],
      full: ["C3", "Eb3", "G3", "Bb3", "D4", "F4", "Ab4"],
    },
    melodyTrigger: 0.50,
    melodyDebounce: 200,
    melodyDuration: "2n",
    bassDebounce: 300,
    bassDuration: "2n",
    kickThreshold: 0.15,
    hatThreshold: 0.005,
  },
  kpop: {
    melodyScale: ["C4","D4","E4","F#4","G4","A4","B4","C5","D5","E5","G5"],
    bassScale:   ["C2","D2","E2","G2","A2","C3"],
    padChords: {
      low:  ["C3", "E3", "G3"],
      mid:  ["A2", "C3", "E3", "G3"],
      high: ["C3", "E3", "G3", "B3", "D4"],
      full: ["A2", "C3", "E3", "G3", "B3", "D4"],
    },
    melodyTrigger: 0.38,
    melodyDebounce: 80,
    melodyDuration: "16n",
    bassDebounce: 150,
    bassDuration: "8n",
    kickThreshold: 0.10,
    hatThreshold: 0.003,
  },
  afrobeat: {
    melodyScale: ["C4","D4","E4","F4","G4","A4","Bb4","C5","D5","E5","G5"],
    bassScale:   ["C2","D2","F2","G2","Bb2","C3"],
    padChords: {
      low:  ["C3", "E3", "G3"],
      mid:  ["C3", "E3", "G3", "Bb3"],
      high: ["F3", "A3", "C4", "Eb4"],
      full: ["C3", "E3", "G3", "Bb3", "D4", "F4"],
    },
    melodyTrigger: 0.40,
    melodyDebounce: 100,
    melodyDuration: "8n",
    bassDebounce: 170,
    bassDuration: "4n",
    kickThreshold: 0.10,
    hatThreshold: 0.003,
  },
};

// Fallback config (same as EDM)
const DEFAULT_CONFIG = GENRE_CONFIG.edm;

// --- Effects config ---
const TILT_SENSITIVITY = 8.0;
const JERK_REVERB_MAX = 50;

// --- Pad config ---
const PAD_SPREAD_MIN = 0.15;
const PAD_SPREAD_MAX = 0.6;

// --- Bass detection ---
const HIP_DIP_THRESHOLD = 0.003;


export class MotionMapper {
  constructor() {
    this.lastMelodyTime = 0;
    this.lastBassTime   = 0;
    this.lastKickTime   = 0;
    this.lastHatTime    = 0;
    this.prevHipY       = null;
    this.hipWasRising   = false;

    // Active genre config
    this.config = DEFAULT_CONFIG;
    this.currentGenre = "edm";
  }

  /**
   * Switch to a different genre's musical configuration.
   * @param {string} genre — genre key
   */
  setGenre(genre) {
    if (genre === this.currentGenre) return;
    this.config = GENRE_CONFIG[genre] || DEFAULT_CONFIG;
    this.currentGenre = genre;
    console.log(`Rules engine → ${genre}`);
  }

  /**
   * @returns {{ melody, bass, kick, hihat, pad, pan, reverb }}
   */
  update(features) {
    if (!features) return { melody: null, bass: null, kick: null, hihat: null, pad: null, pan: 0, reverb: 0.15 };

    return {
      melody:  this._mapMelody(features),
      bass:    this._mapBass(features),
      kick:    this._mapKick(features),
      hihat:   this._mapHiHat(features),
      pad:     this._mapPad(features),
      pan:     this._mapPan(features),
      reverb:  this._mapReverb(features),
    };
  }

  // --- Hands → Melody ---
  _mapMelody(features) {
    const { smoothed, rightWristY } = features;
    const handSpeed = smoothed.handSpeed;
    const scale = this.config.melodyScale;

    const y = Math.max(0.1, Math.min(0.9, rightWristY));
    const normalized = 1 - (y - 0.1) / 0.8;
    const idx = Math.round(normalized * (scale.length - 1));
    const note = scale[idx];

    const now = performance.now();
    if (handSpeed < this.config.melodyTrigger) return null;
    if (now - this.lastMelodyTime < this.config.melodyDebounce) return null;

    this.lastMelodyTime = now;
    const velocity = Math.min(1.0, 0.3 + (handSpeed - this.config.melodyTrigger) * 0.4);
    return { note, velocity, duration: this.config.melodyDuration };
  }

  // --- Hips → Bass ---
  _mapBass(features) {
    const { smoothed } = features;
    const hipY = smoothed.hipY;
    const scale = this.config.bassScale;

    if (this.prevHipY === null) {
      this.prevHipY = hipY;
      return null;
    }

    const delta = hipY - this.prevHipY;
    const wasRising = this.hipWasRising;
    this.hipWasRising = delta > 0;
    this.prevHipY = hipY;

    const now = performance.now();
    const isDip = wasRising && delta < -HIP_DIP_THRESHOLD;

    if (!isDip) return null;
    if (now - this.lastBassTime < this.config.bassDebounce) return null;

    this.lastBassTime = now;
    const coreNorm = Math.min(1.0, smoothed.coreSpeed / 1.5);
    const idx = Math.round(coreNorm * (scale.length - 1));
    const note = scale[idx];
    const velocity = Math.min(1.0, 0.4 + coreNorm * 0.5);
    return { note, velocity, duration: this.config.bassDuration };
  }

  // --- Feet → Kick drum ---
  _mapKick(features) {
    const { smoothed } = features;
    const footContact = smoothed.footContact ?? 0;

    if (footContact < this.config.kickThreshold) return null;

    const now = performance.now();
    if (now - this.lastKickTime < 150) return null;

    this.lastKickTime = now;
    const ankleAccel = smoothed.ankleAccel ?? 0;
    const velocity = Math.min(1.0, 0.5 + Math.min(ankleAccel, 20) / 25);
    return { velocity };
  }

  // --- Head → Hi-hat ---
  _mapHiHat(features) {
    const { smoothed } = features;
    const headBob = smoothed.headBob ?? 0;

    if (headBob < this.config.hatThreshold) return null;

    const now = performance.now();
    if (now - this.lastHatTime < 100) return null;

    this.lastHatTime = now;
    const velocity = Math.min(1.0, 0.3 + headBob * 25);
    return { velocity };
  }

  // --- Arms → String pad ---
  _mapPad(features) {
    const { smoothed } = features;
    const spread = smoothed.armSpread;
    const energy = smoothed.totalKE;
    const chords = this.config.padChords;

    let volume = 0;
    if (spread > PAD_SPREAD_MIN) {
      volume = Math.min(1.0, (spread - PAD_SPREAD_MIN) / (PAD_SPREAD_MAX - PAD_SPREAD_MIN));
    }

    let chord;
    if (energy < 2)       chord = chords.low;
    else if (energy < 5)  chord = chords.mid;
    else if (energy < 10) chord = chords.high;
    else                  chord = chords.full;

    return { chord, volume };
  }

  // --- Body tilt → Stereo pan ---
  _mapPan(features) {
    const { smoothed } = features;
    const tilt = smoothed.bodyTilt ?? 0;
    return Math.max(-1, Math.min(1, tilt * TILT_SENSITIVITY));
  }

  // --- Jerk → Reverb ---
  _mapReverb(features) {
    const { smoothed } = features;
    const jerk = smoothed.jerkMagnitude ?? 0;
    const wet = Math.max(0.05, 0.4 - Math.min(jerk, JERK_REVERB_MAX) / JERK_REVERB_MAX * 0.35);
    return wet;
  }
}
