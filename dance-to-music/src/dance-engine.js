/**
 * dance-engine.js — Orchestrator for stem-based dance-to-music.
 *
 * Reads kinematics features every frame and produces:
 *   1. Genre classification (via GenreDetector)
 *   2. Energy-based layer activation (which stems are audible)
 *   3. Accent triggers (body parts add percussive hits on top of stems)
 *   4. Modulation signals (filter, pan, reverb, playback rate)
 *
 * The dance AS A WHOLE drives the groove (genre + energy layers).
 * Body-part accents add life on top — kicks from stomps, hats from head bobs.
 * Beyond volume, movement also controls filter brightness, stereo field,
 * reverb space, and playback tempo feel.
 */

import { GenreDetector } from "./genre-detector.js?v=3";

// Energy thresholds for layer activation (with hysteresis)
// ON threshold → OFF threshold (30% lower to prevent flicker)
const LAYER_THRESHOLDS = {
  drums:  { on: 0.08, off: 0.05 },
  bass:   { on: 0.25, off: 0.17 },
  pad:    { on: 0.45, off: 0.32 },
  melody: { on: 0.65, off: 0.45 },
};

// Volume levels when a layer is ON (linear gain, 0-1)
const LAYER_VOLUMES = {
  drums:  0.7,
  bass:   0.5,
  pad:    0.35,
  melody: 0.45,
};

// Normalization constant for total KE
const KE_MAX = 15;

// Debounce timers for percussive accents
const KICK_DEBOUNCE_MS = 150;
const HAT_DEBOUNCE_MS = 100;

export class DanceEngine {
  constructor() {
    this.genreDetector = new GenreDetector();

    // Layer state (with hysteresis)
    this.layersActive = {
      drums: false,
      bass: false,
      pad: false,
      melody: false,
    };

    // Debounce timestamps for percussive accents
    this._lastKickTime = 0;
    this._lastHatTime = 0;
  }

  /**
   * Process one frame of kinematics features.
   * @param {object} features — output from KinematicsEngine.push()
   * @returns {{ genre: string, genreConfidence: number, genreScores: object,
   *             layers: object, accents: object }}
   */
  update(features) {
    if (!features) {
      return this._idleResult();
    }

    const { smoothed } = features;
    const now = performance.now();

    // 1. Genre detection
    const genreResult = this.genreDetector.update(smoothed);

    // 2. Energy → layer activation
    const energy = Math.min(1, Math.max(0, smoothed.totalKE / KE_MAX));
    const layers = this._computeLayers(energy);

    // 3. Body-part accents
    const accents = this._computeAccents(smoothed, features, now);

    return {
      genre: genreResult.genre,
      genreConfidence: genreResult.confidence,
      genreScores: genreResult.scores,
      layers,
      accents,
      energy,
    };
  }

  /**
   * Compute which layers are active based on energy (with hysteresis).
   * Returns linear gain values for each stem (0 = silent).
   */
  _computeLayers(energy) {
    const result = {};

    for (const [layer, thresholds] of Object.entries(LAYER_THRESHOLDS)) {
      if (this.layersActive[layer]) {
        // Currently ON — use lower threshold to turn OFF
        if (energy < thresholds.off) {
          this.layersActive[layer] = false;
        }
      } else {
        // Currently OFF — use higher threshold to turn ON
        if (energy >= thresholds.on) {
          this.layersActive[layer] = true;
        }
      }

      result[layer] = this.layersActive[layer] ? LAYER_VOLUMES[layer] : 0;
    }

    // Modulate pad volume with arm spread (when pad layer is active)
    // This is applied later in main.js via accents.padVolumeBoost

    return result;
  }

  /**
   * Compute accent triggers + modulation signals.
   *
   * Accents (percussive hits layered on stems):
   *   - Foot stomp → kick accent
   *   - Head bob → hi-hat accent
   *
   * Modulation (continuous shaping of stems):
   *   - Hand speed → melody filter cutoff (dark↔bright)
   *   - Arm spread → pad volume boost
   *   - Body tilt → stereo pan
   *   - Jerk → reverb (smooth=wet, sharp=dry)
   *   - Overall energy → playback rate (tempo feel: slow dance=slightly slower)
   */
  _computeAccents(smoothed, features, now) {
    // Hands → melody stem filter cutoff (0=dark, 1=bright)
    const filterCutoff = Math.min(1, Math.max(0, smoothed.handSpeed / 2.0));

    // Foot contact → kick drum accent (lowered threshold for phone cameras)
    let drumAccent = null;
    if (smoothed.footContact > 0.12 && now - this._lastKickTime > KICK_DEBOUNCE_MS) {
      this._lastKickTime = now;
      const velocity = Math.min(1, 0.5 + Math.min(smoothed.ankleAccel, 20) / 25);
      drumAccent = { velocity };
    }

    // Head bob → synth hi-hat accent (lowered threshold)
    let hatAccent = null;
    if (smoothed.headBob > 0.003 && now - this._lastHatTime > HAT_DEBOUNCE_MS) {
      this._lastHatTime = now;
      const velocity = Math.min(1, 0.3 + smoothed.headBob * 25);
      hatAccent = { velocity };
    }

    // Arm spread → pad stem volume boost (0-1)
    const padVolumeBoost = Math.min(1, Math.max(0,
      (smoothed.armSpread - 0.15) / 0.45
    ));

    // Body tilt → stereo pan (-1 to 1)
    const pan = Math.max(-1, Math.min(1, smoothed.bodyTilt * 8.0));

    // Jerk → reverb wet/dry (smooth = wet, sharp = dry)
    const jerkNorm = Math.min(smoothed.jerkMagnitude, 50) / 50;
    const reverb = Math.max(0.05, 0.4 - jerkNorm * 0.35);

    // Overall energy → playback rate (tempo feel)
    // Low energy = slightly slower (0.92x), high energy = slightly faster (1.08x)
    // This makes slow dancing feel dreamy and fast dancing feel urgent
    const energyNorm = Math.min(1, smoothed.totalKE / KE_MAX);
    const playbackRate = 0.92 + energyNorm * 0.16; // range: 0.92 - 1.08

    return {
      filterCutoff, drumAccent, hatAccent, padVolumeBoost,
      pan, reverb, playbackRate,
    };
  }

  /**
   * Return an idle result (no features / no person detected).
   */
  _idleResult() {
    return {
      genre: this.genreDetector.currentGenre,
      genreConfidence: 0,
      genreScores: {},
      layers: { drums: 0, bass: 0, melody: 0, pad: 0 },
      accents: {
        filterCutoff: 0.5,
        drumAccent: null,
        hatAccent: null,
        padVolumeBoost: 0,
        pan: 0,
        reverb: 0.3,
        playbackRate: 1.0,
      },
      energy: 0,
    };
  }

  /**
   * Reset all state.
   */
  reset() {
    this.genreDetector.reset();
    this.layersActive = { drums: false, bass: false, pad: false, melody: false };
    this._lastKickTime = 0;
    this._lastHatTime = 0;
  }
}
