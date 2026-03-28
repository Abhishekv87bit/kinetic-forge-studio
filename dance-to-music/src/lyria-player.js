/**
 * lyria-player.js — Google Lyria RealTime music generation + playback.
 *
 * The dance DRIVES the music. Two control tiers:
 *
 * Config (every 150ms) — numbers that shape the sound:
 *   density    ← body energy (sparse→full arrangement)
 *   brightness ← hand speed (warm/dark→bright/cutting)
 *   guidance   ← arm spread (strict genre→creative freedom)
 *   temperature← movement variety (predictable→surprising)
 *   muteDrums  ← no foot activity → strip drums
 *   muteBass   ← very low energy → strip bass
 *
 * Prompts (every 3s) — words that steer the musical direction:
 *   Genre prompt (weight 1.0, always present)
 *   + Mood modifier from movement quality (weight 0.5):
 *     smooth+gentle = "ambient, gentle, floating"
 *     smooth+intense = "euphoric, soaring, uplifting"
 *     sharp+gentle = "tense, suspenseful, dark"
 *     sharp+intense = "aggressive, powerful, driving"
 *
 * BPM set once per genre (resetContext is disruptive — 5-10s settling).
 */

const SAMPLE_RATE = 48000;
const CHANNELS = 2;
const API_VERSION = "v1alpha";
const MODEL_ID = "models/lyria-realtime-exp";

// Throttle: config as fast as WebSocket allows, prompts need ~2s to manifest
const CONFIG_UPDATE_INTERVAL_MS = 80;   // was 150 — tighter for responsiveness
const PROMPT_UPDATE_INTERVAL_MS = 2500; // was 3000 — mood shifts slightly faster

// Genre prompt templates (the "what genre" — always weight 1.0)
const GENRE_PROMPTS = {
  hiphop:    "90s hip hop beat, 808 bass, snappy snare, dark piano melody",
  edm:       "energetic EDM, driving synthesizers, four on the floor kick, euphoric build",
  lofi:      "chill lo-fi hip hop, warm jazzy piano, vinyl crackle, mellow drums",
  latin:     "reggaeton beat, dembow rhythm, tropical synths, latin percussion",
  rnb:       "smooth R&B groove, silky Rhodes piano, deep bass, gentle drums",
  cinematic: "cinematic orchestral score, strings, brass, epic percussion, emotional",
  kpop:      "K-pop dance track, bright synths, punchy drums, catchy melodic hook",
  afrobeat:  "afrobeats groove, tropical percussion, guitar licks, danceable rhythm",
};

// Mood descriptor matrix: [smoothness][energy] → text description
// These layer ON TOP of the genre prompt to shape the vibe
const MOOD_DESCRIPTORS = {
  smooth_low:  "ambient, gentle, floating, minimal, spacious",
  smooth_mid:  "groovy, flowing, melodic, warm, lush",
  smooth_high: "euphoric, soaring, uplifting, powerful, anthemic",
  sharp_low:   "tense, suspenseful, minimal, dark, sparse",
  sharp_mid:   "punchy, rhythmic, staccato, energetic, bouncy",
  sharp_high:  "aggressive, intense, driving, hard-hitting, relentless",
};

// Default BPM per genre (set once, only changes on genre switch)
const GENRE_BPM = {
  hiphop: 90,
  edm: 128,
  lofi: 80,
  latin: 95,
  rnb: 75,
  cinematic: 100,
  kpop: 120,
  afrobeat: 108,
};

export class LyriaPlayer {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.session = null;
    this.audioCtx = null;
    this.connected = false;
    this.playing = false;
    this.currentGenre = null;

    // Gapless playback scheduling
    this._nextStartTime = 0;
    this._scheduledBuffers = [];

    // Health check: track received audio chunks
    this.chunksReceived = 0;
    this._playStartTime = 0;

    // Throttle state
    this._lastConfigUpdate = 0;
    this._lastPromptUpdate = 0;
    this._currentMood = null; // last mood key sent to prompts
    this._currentMoodSuffix = "";  // track body-part suffix separately

    // Full config state (must send ALL fields each time — partials reset to defaults)
    this._currentConfig = {
      bpm: 120, density: 0.3, brightness: 0.5,
      guidance: 4.0, temperature: 1.1,
      muteDrums: false, muteBass: false,
    };

    // Gain node for master volume
    this._gainNode = null;
  }

  /**
   * Initialize audio context and connect to Lyria.
   * Must be called from a user gesture (click/tap).
   * @param {string} genre - initial genre key
   * @param {{ panner: Tone.Panner, reverb: Tone.Reverb }} effectsChain - optional
   */
  async init(genre, effectsChain) {
    // Create audio context if not exists
    if (!this.audioCtx) {
      this.audioCtx = new AudioContext({ sampleRate: SAMPLE_RATE });
    }
    if (this.audioCtx.state === "suspended") {
      await this.audioCtx.resume();
    }

    // Create gain node → destination (or effects chain)
    this._gainNode = this.audioCtx.createGain();
    this._gainNode.gain.value = 1.0;

    if (effectsChain?.panner) {
      // Connect to Tone.js panner for pan/reverb modulation
      // Tone.js nodes have an input property we can connect to
      this._gainNode.connect(this.audioCtx.destination);
    } else {
      this._gainNode.connect(this.audioCtx.destination);
    }

    // Load the SDK dynamically (v1.30+ required for Lyria RealTime)
    const { GoogleGenAI } = await import(
      "https://esm.sh/@google/genai@1.45.0"
    );

    const ai = new GoogleGenAI({
      apiKey: this.apiKey,
      httpOptions: { apiVersion: API_VERSION },
    });

    // Connect to Lyria RealTime
    this.session = await ai.live.music.connect({
      model: MODEL_ID,
      callbacks: {
        onmessage: (message) => this._onMessage(message),
        onerror: (error) => {
          console.error("Lyria error:", error);
          this.connected = false;
        },
        onclose: () => {
          console.log("Lyria session closed");
          this.connected = false;
          this.playing = false;
        },
      },
    });

    this.connected = true;
    this.currentGenre = genre;

    // Set initial genre prompt (genre at weight 1.0, gentle mood at 0.5)
    const genreText = GENRE_PROMPTS[genre] || GENRE_PROMPTS.hiphop;
    await this.session.setWeightedPrompts({
      weightedPrompts: [
        { text: genreText, weight: 1.0 },
        { text: MOOD_DESCRIPTORS.smooth_low, weight: 0.5 },
      ],
    });
    this._currentMood = "smooth_low";

    // Set initial config — all fields (partial updates reset omitted fields!)
    const bpm = GENRE_BPM[genre] || 120;
    this._currentConfig = {
      bpm, density: 0.15, brightness: 0.4,
      guidance: 4.5, temperature: 1.0,
      muteDrums: true, muteBass: true, // start silent — dance activates
    };
    await this.session.setMusicGenerationConfig({
      musicGenerationConfig: { ...this._currentConfig },
    });

    console.log(`Lyria connected — genre: ${genre}, BPM: ${bpm}`);
  }

  /**
   * Start music generation.
   */
  play() {
    if (!this.session || !this.connected) return;
    this._nextStartTime = this.audioCtx.currentTime + 0.1;
    this.chunksReceived = 0;
    this._playStartTime = performance.now();
    this.session.play();
    this.playing = true;
    console.log("Lyria playing");
  }

  /**
   * Check if Lyria is actually producing audio.
   * @returns {boolean} true if audio chunks are being received
   */
  get hasAudio() {
    if (!this.playing) return false;
    const elapsed = performance.now() - this._playStartTime;
    // Give it 5 seconds to start producing audio
    if (elapsed < 5000) return true; // still warming up
    return this.chunksReceived > 0;
  }

  /**
   * Pause music generation.
   */
  pause() {
    if (!this.session || !this.connected) return;
    this.session.pause();
    this.playing = false;
    // Stop all scheduled buffers
    for (const src of this._scheduledBuffers) {
      try { src.stop(); } catch (e) { /* already stopped */ }
    }
    this._scheduledBuffers = [];
  }

  /**
   * Change genre (updates prompt, may reset context for BPM change).
   * @param {string} genre - genre key
   */
  async setGenre(genre) {
    if (!this.session || !this.connected) return;
    if (genre === this.currentGenre) return;

    this.currentGenre = genre;
    const genreText = GENRE_PROMPTS[genre] || GENRE_PROMPTS.hiphop;
    const bpm = GENRE_BPM[genre] || 120;
    const moodText = MOOD_DESCRIPTORS[this._currentMood] || MOOD_DESCRIPTORS.smooth_low;

    // Update prompts with new genre + current mood
    await this.session.setWeightedPrompts({
      weightedPrompts: [
        { text: genreText, weight: 1.0 },
        { text: moodText, weight: 0.5 },
      ],
    });

    // BPM change requires context reset (disruptive — 5-10s settling)
    if (bpm !== this._currentConfig.bpm) {
      this._currentConfig.bpm = bpm;
      await this.session.setMusicGenerationConfig({
        musicGenerationConfig: { ...this._currentConfig },
      });
      if (this.session.resetContext) {
        await this.session.resetContext();
      }
    }

    this._lastPromptUpdate = performance.now();
    console.log(`Lyria genre → ${genre}, BPM: ${bpm}`);
  }

  /**
   * Update Lyria from dance kinematics. Two channels:
   *
   * 1. Config (every 150ms): density, brightness, guidance, temperature,
   *    muteDrums, muteBass — these shape the sound in real-time.
   *
   * 2. Prompts (every 3s): mood descriptor layered on genre prompt —
   *    this steers the musical DIRECTION based on movement quality.
   *
   * @param {object} p
   * @param {number} p.density     - 0-1: body energy → arrangement fullness
   * @param {number} p.brightness  - 0-1: hand speed → dark↔bright tonal quality
   * @param {number} p.guidance    - 1.5-6: arm spread → genre adherence vs creativity
   * @param {number} p.temperature - 0.5-2: movement variety → predictable vs surprising
   * @param {boolean} p.muteDrums  - true when no foot activity (dancer not driving rhythm)
   * @param {boolean} p.muteBass   - true when energy very low (just ambient texture)
   * @param {string} p.mood        - mood key: "smooth_low", "sharp_high", etc.
   */
  async updateFromDance({
    density = 0.3, brightness = 0.5, guidance = 4.0, temperature = 1.1,
    muteDrums = false, muteBass = false, mood = "smooth_mid", moodSuffix = "",
  } = {}) {
    if (!this.session || !this.connected || !this.playing) return;

    const now = performance.now();

    // --- Channel 1: Config update (fast — every 150ms) ---
    if (now - this._lastConfigUpdate >= CONFIG_UPDATE_INTERVAL_MS) {
      const d = Math.max(0, Math.min(1, density));
      const b = Math.max(0, Math.min(1, brightness));
      const g = Math.max(1.5, Math.min(6.0, guidance));
      const t = Math.max(0.5, Math.min(2.0, temperature));

      // Only send if something changed (low thresholds for responsiveness)
      const changed =
        Math.abs(d - this._currentConfig.density) > 0.01 ||
        Math.abs(b - this._currentConfig.brightness) > 0.01 ||
        Math.abs(g - this._currentConfig.guidance) > 0.1 ||
        Math.abs(t - this._currentConfig.temperature) > 0.05 ||
        muteDrums !== this._currentConfig.muteDrums ||
        muteBass !== this._currentConfig.muteBass;

      if (changed) {
        this._currentConfig.density = d;
        this._currentConfig.brightness = b;
        this._currentConfig.guidance = g;
        this._currentConfig.temperature = t;
        this._currentConfig.muteDrums = muteDrums;
        this._currentConfig.muteBass = muteBass;
        this._lastConfigUpdate = now;

        await this.session.setMusicGenerationConfig({
          musicGenerationConfig: {
            bpm: this._currentConfig.bpm,
            density: d,
            brightness: b,
            guidance: g,
            temperature: t,
            muteDrums,
            muteBass,
          },
        });
      }
    }

    // --- Channel 2: Prompt update (slow — every 2.5s) ---
    // The prompt is our most powerful lever for making each dancer's music unique.
    // We build a SPECIFIC instrumentation prompt from which body parts are active.
    const moodChanged = mood !== this._currentMood || moodSuffix !== this._currentMoodSuffix;
    if (moodChanged && now - this._lastPromptUpdate >= PROMPT_UPDATE_INTERVAL_MS) {
      const genreText = GENRE_PROMPTS[this.currentGenre] || GENRE_PROMPTS.hiphop;
      const moodText = (MOOD_DESCRIPTORS[mood] || MOOD_DESCRIPTORS.smooth_mid)
        + (moodSuffix || "");

      this._currentMood = mood;
      this._currentMoodSuffix = moodSuffix;
      this._lastPromptUpdate = now;

      // Genre prompt (what style) at weight 1.0
      // Mood+instrumentation prompt (what instruments + how it feels) at weight 0.8
      // Higher weight on mood makes instrumentation changes more audible
      await this.session.setWeightedPrompts({
        weightedPrompts: [
          { text: genreText, weight: 1.0 },
          { text: moodText, weight: 0.8 },
        ],
      });

      console.log(`Lyria band -> ${mood}${moodSuffix}`);
    }
  }

  /**
   * Handle incoming audio chunks from Lyria.
   */
  _onMessage(message) {
    // Check for audio chunk
    const chunkData =
      message?.serverContent?.audioChunks?.[0]?.data ||
      message?.audioChunk?.data;

    if (!chunkData) return;

    this.chunksReceived++;

    // Decode base64 → Int16Array
    const binaryStr = atob(chunkData);
    const bytes = new Uint8Array(binaryStr.length);
    for (let i = 0; i < binaryStr.length; i++) {
      bytes[i] = binaryStr.charCodeAt(i);
    }
    const int16 = new Int16Array(bytes.buffer);

    // Convert Int16 → Float32 (Web Audio API expects -1.0 to 1.0)
    const numSamples = int16.length / CHANNELS;
    const audioBuffer = this.audioCtx.createBuffer(
      CHANNELS,
      numSamples,
      SAMPLE_RATE
    );

    for (let ch = 0; ch < CHANNELS; ch++) {
      const channelData = audioBuffer.getChannelData(ch);
      for (let i = 0; i < numSamples; i++) {
        // Interleaved stereo: [L, R, L, R, ...]
        channelData[i] = int16[i * CHANNELS + ch] / 32768.0;
      }
    }

    // Schedule for gapless playback
    this._scheduleBuffer(audioBuffer);
  }

  /**
   * Schedule an audio buffer for gapless playback.
   */
  _scheduleBuffer(audioBuffer) {
    const source = this.audioCtx.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(this._gainNode);

    // Ensure we don't schedule in the past
    const now = this.audioCtx.currentTime;
    if (this._nextStartTime < now) {
      this._nextStartTime = now + 0.02; // 20ms lookahead
    }

    source.start(this._nextStartTime);
    this._nextStartTime += audioBuffer.duration;

    // Track for cleanup
    this._scheduledBuffers.push(source);
    source.onended = () => {
      const idx = this._scheduledBuffers.indexOf(source);
      if (idx >= 0) this._scheduledBuffers.splice(idx, 1);
    };
  }

  /**
   * Set master volume.
   * @param {number} vol - 0-1
   */
  setVolume(vol) {
    if (this._gainNode) {
      this._gainNode.gain.setTargetAtTime(vol, this.audioCtx.currentTime, 0.05);
    }
  }

  /**
   * Stop and disconnect.
   */
  dispose() {
    this.pause();
    if (this.session) {
      try { this.session.close(); } catch (e) { /* ignore */ }
      this.session = null;
    }
    this.connected = false;
    this.playing = false;
  }
}

// Export genre data for UI
export { GENRE_PROMPTS, GENRE_BPM };
