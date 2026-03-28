/**
 * stem-player.js — Manages stem audio playback, looping, crossfading, and per-stem volume.
 *
 * Each genre has 4 stems: drums, bass, melody, pad.
 * All stems within a genre loop simultaneously.
 * Genre changes trigger a per-stem crossfade.
 * Energy-based layer activation controls per-stem volume.
 *
 * Signal chain per stem:
 *   Player → Gain → [Filter for melody] → shared panner → shared reverb → speakers
 */

const T = () => window.Tone;
const STEM_NAMES = ["drums", "bass", "melody", "pad"];
const GENRES = ["edm", "lofi", "hiphop"];

export class StemPlayer {
  constructor() {
    this.buffers = {};       // { edm: { drums: ToneAudioBuffer, ... }, ... }
    this.players = {};       // { edm: { drums: Player, ... }, ... }
    this.gains = {};         // { edm: { drums: Gain, ... }, ... }
    this.melodyFilter = null;
    this.activeGenre = null;
    this.crossfading = false;
    this._crossfadeTimer = null;
    this.ready = false;
    this._drumBaseDb = -6;   // base volume for drum accent reference
  }

  /**
   * Load all 12 stems and create audio nodes.
   * @param {{ panner: Tone.Panner, reverb: Tone.Reverb }} effectsChain
   * @param {function} onProgress - optional progress callback (0-1)
   */
  async init(effectsChain, onProgress) {
    const Tone = T();

    // Melody filter (lowpass, controlled by hand speed)
    this.melodyFilter = new Tone.Filter({
      frequency: 20000,
      type: "lowpass",
      rolloff: -12,
    });
    this.melodyFilter.connect(effectsChain.panner);

    // Load all buffers
    const totalFiles = GENRES.length * STEM_NAMES.length;
    let loaded = 0;

    for (const genre of GENRES) {
      this.buffers[genre] = {};
      this.players[genre] = {};
      this.gains[genre] = {};

      for (const stem of STEM_NAMES) {
        const url = `./assets/stems/${genre}/${stem}.wav`;
        const buffer = new Tone.ToneAudioBuffer(url);
        this.buffers[genre][stem] = buffer;

        // Create gain node for this stem
        const gain = new Tone.Gain(0); // start silent (linear 0)
        this.gains[genre][stem] = gain;

        // Wire: gain → filter (melody) or panner (others)
        if (stem === "melody") {
          gain.connect(this.melodyFilter);
        } else {
          gain.connect(effectsChain.panner);
        }
      }
    }

    // Wait for all buffers to load
    await Tone.ToneAudioBuffer.loaded();

    // Create players after buffers are loaded
    for (const genre of GENRES) {
      for (const stem of STEM_NAMES) {
        const player = new Tone.Player({
          url: this.buffers[genre][stem],
          loop: true,
          fadeIn: 0.01,
          fadeOut: 0.01,
        });
        player.connect(this.gains[genre][stem]);
        this.players[genre][stem] = player;
      }
    }

    this.ready = true;
  }

  /**
   * Start playing a genre. If already playing a different genre, crossfade.
   * @param {string} genre - "edm" | "lofi" | "hiphop"
   */
  startGenre(genre) {
    if (!this.ready) return;
    if (genre === this.activeGenre) return;

    if (this.activeGenre === null) {
      // First genre — start immediately
      this._startPlayers(genre);
      this.activeGenre = genre;
    } else {
      // Crossfade from current to new
      this._crossfade(this.activeGenre, genre, 2.5);
    }
  }

  /**
   * Start all 4 players for a genre at the same moment.
   */
  _startPlayers(genre) {
    const Tone = T();
    const now = Tone.now() + 0.05; // tiny offset to ensure sync
    for (const stem of STEM_NAMES) {
      const player = this.players[genre][stem];
      if (player.state !== "started") {
        player.start(now);
      }
    }
  }

  /**
   * Per-stem crossfade between two genres.
   */
  _crossfade(fromGenre, toGenre, duration) {
    if (this.crossfading) {
      // Cancel previous crossfade
      if (this._crossfadeTimer) clearTimeout(this._crossfadeTimer);
    }

    this.crossfading = true;
    const Tone = T();
    const now = Tone.now();

    // Start the new genre's players
    this._startPlayers(toGenre);

    // For each stem: ramp old gain down, new gain to current target
    for (const stem of STEM_NAMES) {
      const oldGain = this.gains[fromGenre][stem];
      const newGain = this.gains[toGenre][stem];

      // Get the current volume of the old stem (its target)
      const currentVol = oldGain.gain.value;

      // Ramp old down
      oldGain.gain.rampTo(0, duration, now);

      // Ramp new up to match what old was at
      newGain.gain.rampTo(currentVol, duration, now);
    }

    // After crossfade, stop old players and update state
    this._crossfadeTimer = setTimeout(() => {
      this._stopPlayers(fromGenre);
      this.activeGenre = toGenre;
      this.crossfading = false;
    }, duration * 1000 + 100);
  }

  /**
   * Stop all players for a genre.
   */
  _stopPlayers(genre) {
    for (const stem of STEM_NAMES) {
      const player = this.players[genre][stem];
      if (player.state === "started") {
        player.stop();
      }
      // Reset gain to 0 so it's ready for next start
      this.gains[genre][stem].gain.value = 0;
    }
  }

  /**
   * Set per-stem volume based on energy layer activation.
   * Values are in linear gain (0 = silent, 1 = full).
   * @param {number} drums - 0-1
   * @param {number} bass - 0-1
   * @param {number} melody - 0-1
   * @param {number} pad - 0-1
   */
  setLayerVolumes(drums, bass, melody, pad) {
    if (!this.ready || !this.activeGenre) return;

    const genre = this.activeGenre;
    const rampTime = 0.2; // smooth transitions

    this.gains[genre].drums.gain.rampTo(drums, rampTime);
    this.gains[genre].bass.gain.rampTo(bass, rampTime);
    this.gains[genre].melody.gain.rampTo(melody, rampTime);
    this.gains[genre].pad.gain.rampTo(pad, rampTime);

    // During crossfade, also update the target genre
    if (this.crossfading) {
      for (const g of GENRES) {
        if (g !== genre && this.players[g].drums.state === "started") {
          this.gains[g].drums.gain.rampTo(drums, rampTime);
          this.gains[g].bass.gain.rampTo(bass, rampTime);
          this.gains[g].melody.gain.rampTo(melody, rampTime);
          this.gains[g].pad.gain.rampTo(pad, rampTime);
        }
      }
    }
  }

  /**
   * Set melody stem filter cutoff (hand speed modulation).
   * @param {number} value - 0-1 (0=dark/filtered, 1=bright/open)
   */
  setFilterCutoff(value) {
    if (!this.ready || !this.melodyFilter) return;
    // Exponential mapping: 0→200Hz, 1→20000Hz
    const minFreq = 200;
    const maxFreq = 20000;
    const freq = minFreq * Math.pow(maxFreq / minFreq, Math.max(0, Math.min(1, value)));
    this.melodyFilter.frequency.rampTo(freq, 0.05);
  }

  /**
   * Brief volume accent on drums (triggered by foot contact).
   * @param {number} velocity - 0-1
   */
  accentDrums(velocity) {
    if (!this.ready || !this.activeGenre) return;
    const drumGain = this.gains[this.activeGenre].drums;
    const currentVol = drumGain.gain.value;
    if (currentVol < 0.01) return; // drums not active

    // Brief boost: +30-60% for 80ms, then back
    const boost = currentVol * (1 + velocity * 0.6);
    const Tone = T();
    const now = Tone.now();
    drumGain.gain.setValueAtTime(boost, now);
    drumGain.gain.rampTo(currentVol, 0.08, now + 0.02);
  }

  /**
   * Set playback rate for all active stems.
   * Subtle tempo modulation: slow dancing = slightly slower, fast = slightly faster.
   * @param {number} rate - 0.92 to 1.08
   */
  setPlaybackRate(rate) {
    if (!this.ready) return;
    const clamped = Math.max(0.88, Math.min(1.12, rate));
    for (const genre of GENRES) {
      for (const stem of STEM_NAMES) {
        const player = this.players[genre]?.[stem];
        if (player && player.state === "started") {
          player.playbackRate = clamped;
        }
      }
    }
  }

  /**
   * Stop all playback and clean up.
   */
  dispose() {
    for (const genre of GENRES) {
      for (const stem of STEM_NAMES) {
        if (this.players[genre]?.[stem]) {
          this.players[genre][stem].stop();
          this.players[genre][stem].dispose();
        }
        if (this.gains[genre]?.[stem]) {
          this.gains[genre][stem].dispose();
        }
      }
    }
    if (this.melodyFilter) this.melodyFilter.dispose();
    if (this._crossfadeTimer) clearTimeout(this._crossfadeTimer);
    this.ready = false;
  }
}
