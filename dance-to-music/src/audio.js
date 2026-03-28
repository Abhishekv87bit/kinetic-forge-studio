/**
 * audio.js — Tone.js audio engine.
 *
 * In STEM mode: provides accent instruments (kick, hi-hat) and shared effects chain.
 * Stems connect to the same panner → reverb → speakers chain via getEffectsChain().
 *
 * In RULES/ML mode (backward compat): full synthesis with melody, bass, pad, kick, hat.
 *
 * Effects:
 *   - Reverb (global)  ← jerk magnitude (smooth=wet, sharp=dry)
 *   - Stereo panner    ← body tilt (lean left/right)
 *
 * Tone.js is loaded as a global <script> — accessed via window.Tone.
 */

const T = () => window.Tone;

export class AudioEngine {
  constructor() {
    // Shared effects
    this.reverb = null;
    this.panner = null;

    // Accent instruments (used in stem mode and synth modes)
    this.kickSynth = null;
    this.hatSynth = null;

    // Full synth instruments (backward compat for Rules/ML modes)
    this.melodySynth = null;
    this.bassSynth = null;
    this.padSynth = null;

    this.ready = false;
    this._padChord = null;
    this._padVolume = -40;
  }

  /** Must be called from a user gesture (click/tap handler). */
  async init() {
    const Tone = T();
    await Tone.start();

    // --- Shared effects chain ---
    this.reverb = new Tone.Reverb({ decay: 2.5, wet: 0.15 });
    await this.reverb.generate();

    this.panner = new Tone.Panner(0);
    this.panner.connect(this.reverb);
    this.reverb.toDestination();

    // --- Accent: Kick drum (foot contact) ---
    this.kickSynth = new Tone.MembraneSynth({
      pitchDecay: 0.05,
      octaves: 6,
      oscillator: { type: "sine" },
      envelope: { attack: 0.001, decay: 0.3, sustain: 0, release: 0.3 },
      volume: -2,
    });
    this.kickSynth.connect(this.panner);

    // --- Accent: Hi-hat (head bob) ---
    this.hatSynth = new Tone.NoiseSynth({
      noise: { type: "white" },
      envelope: { attack: 0.001, decay: 0.08, sustain: 0, release: 0.03 },
      volume: -10,
    });
    const hatFilter = new Tone.Filter({ frequency: 8000, type: "highpass" });
    this.hatSynth.connect(hatFilter);
    hatFilter.connect(this.panner);

    // --- Backward compat: Full synth instruments (for Rules/ML modes) ---

    // Melody synth
    this.melodySynth = new Tone.PolySynth(Tone.Synth, {
      maxPolyphony: 4,
      oscillator: { type: "triangle" },
      envelope: { attack: 0.01, decay: 0.25, sustain: 0.05, release: 0.6 },
      volume: -6,
    });
    this.melodySynth.connect(this.panner);

    // Bass synth
    this.bassSynth = new Tone.MonoSynth({
      oscillator: { type: "sine" },
      envelope: { attack: 0.01, decay: 0.4, sustain: 0.2, release: 0.8 },
      filterEnvelope: {
        attack: 0.01, decay: 0.2, sustain: 0.3, release: 0.5,
        baseFrequency: 80, octaves: 2,
      },
      volume: -4,
    });
    this.bassSynth.connect(this.panner);

    // String pad
    this.padSynth = new Tone.PolySynth(Tone.Synth, {
      maxPolyphony: 6,
      oscillator: { type: "sine" },
      envelope: { attack: 0.8, decay: 0.3, sustain: 0.8, release: 1.5 },
      volume: -40,
    });
    this.padSynth.connect(this.panner);

    this.ready = true;
  }

  /**
   * Get the shared effects chain for StemPlayer to connect to.
   * @returns {{ panner: Tone.Panner, reverb: Tone.Reverb }}
   */
  getEffectsChain() {
    return { panner: this.panner, reverb: this.reverb };
  }

  // --- Accent play methods (used in both stem and synth modes) ---

  playKick(velocity) {
    if (!this.ready) return;
    this.kickSynth.triggerAttackRelease("C1", "8n", undefined, velocity);
  }

  playHiHat(velocity) {
    if (!this.ready) return;
    this.hatSynth.triggerAttackRelease("16n", undefined, velocity);
  }

  // --- Effects control ---

  setPan(pan) {
    if (!this.ready) return;
    this.panner.pan.rampTo(Math.max(-1, Math.min(1, pan)), 0.05);
  }

  setReverb(wet) {
    if (!this.ready) return;
    this.reverb.wet.rampTo(Math.max(0, Math.min(0.6, wet)), 0.1);
  }

  // --- Full synth methods (backward compat for Rules/ML modes) ---

  playMelody(note, velocity, duration) {
    if (!this.ready) return;
    this.melodySynth.triggerAttackRelease(note, duration, undefined, velocity);
  }

  playBass(note, velocity, duration) {
    if (!this.ready) return;
    this.bassSynth.triggerAttackRelease(note, duration, undefined, velocity);
  }

  updatePad(chord, volume) {
    if (!this.ready) return;
    const Tone = T();
    const targetDb = -40 + volume * 30;
    this.padSynth.volume.rampTo(targetDb, 0.1);

    const chordKey = chord.join(",");
    if (chordKey !== this._padChord) {
      this.padSynth.releaseAll();
      if (volume > 0.05) {
        const now = Tone.now();
        chord.forEach((note, i) => {
          this.padSynth.triggerAttack(note, now + i * 0.02, 0.3);
        });
      }
      this._padChord = chordKey;
    }

    if (volume < 0.03 && this._padChord) {
      this.padSynth.releaseAll();
      this._padChord = null;
    }
  }
}
