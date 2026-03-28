/**
 * genre-detector.js — Classifies dance style from kinematics features.
 *
 * Analyzes a rolling window (~3 seconds) of smoothed features to classify:
 *   - "lofi"   — smooth, balanced, flowing movements (low jerk, high symmetry)
 *   - "hiphop" — sharp, asymmetric, bouncy (high jerk, hip bounce, low symmetry)
 *   - "edm"    — fast, high-energy, lots of foot/hand activity
 *
 * Uses hysteresis to prevent rapid genre switching:
 *   - New genre must dominate 45%+ of recent classifications
 *   - 2-second cooldown between genre switches
 */

const WINDOW_SIZE = 60;         // ~2 seconds at 30fps (shorter = more responsive)
const HISTORY_SIZE = 10;        // classification history for hysteresis
const DOMINANCE_THRESHOLD = 0.45; // 45% of history must agree (was 60% — too sticky)
const SWITCH_COOLDOWN_MS = 2000; // min time between genre switches (was 4s — too slow)
const DEFAULT_GENRE = "edm";

export class GenreDetector {
  constructor() {
    this.featureBuffer = [];
    this.classHistory = [];
    this.currentGenre = DEFAULT_GENRE;
    this.lastSwitchTime = 0;
  }

  /**
   * Process one frame of features and return current genre classification.
   * @param {object} smoothed — smoothed kinematics features
   * @returns {{ genre: string, confidence: number, scores: object }}
   */
  update(smoothed) {
    // Buffer features
    this.featureBuffer.push({
      totalKE: smoothed.totalKE,
      handSpeed: smoothed.handSpeed,
      footSpeed: smoothed.footSpeed,
      jerkMagnitude: smoothed.jerkMagnitude,
      symmetry: smoothed.symmetry,
      hipY: smoothed.hipY,
      headBob: smoothed.headBob,
      footContact: smoothed.footContact,
    });

    // Keep only the window
    if (this.featureBuffer.length > WINDOW_SIZE) {
      this.featureBuffer.shift();
    }

    // Need at least half a window to classify
    if (this.featureBuffer.length < WINDOW_SIZE / 2) {
      return { genre: this.currentGenre, confidence: 0, scores: {} };
    }

    // Compute aggregate stats over window
    const stats = this._computeStats();
    const scores = this._scoreGenres(stats);
    const rawGenre = this._pickGenre(scores);

    // Push to classification history
    this.classHistory.push(rawGenre);
    if (this.classHistory.length > HISTORY_SIZE) {
      this.classHistory.shift();
    }

    // Apply hysteresis
    const stableGenre = this._applyHysteresis();
    const confidence = scores[stableGenre] || 0;

    return { genre: stableGenre, confidence, scores };
  }

  /**
   * Compute aggregate statistics over the feature buffer.
   */
  _computeStats() {
    const buf = this.featureBuffer;
    const n = buf.length;

    let sumJerk = 0, sumSym = 0, sumHandSpeed = 0, sumFootSpeed = 0, sumEnergy = 0;
    let sumFootContact = 0, sumHeadBob = 0;

    for (let i = 0; i < n; i++) {
      sumJerk += buf[i].jerkMagnitude;
      sumSym += buf[i].symmetry;
      sumHandSpeed += buf[i].handSpeed;
      sumFootSpeed += buf[i].footSpeed;
      sumEnergy += buf[i].totalKE;
      sumFootContact += buf[i].footContact;
      sumHeadBob += buf[i].headBob;
    }

    const avgJerk = sumJerk / n;
    const avgSymmetry = sumSym / n;
    const avgHandSpeed = sumHandSpeed / n;
    const avgFootSpeed = sumFootSpeed / n;
    const avgEnergy = sumEnergy / n;
    const footContactRate = sumFootContact / n;
    const avgHeadBob = sumHeadBob / n;

    // Bounce frequency: count hipY direction changes
    let bounceCount = 0;
    for (let i = 2; i < n; i++) {
      const prev = buf[i - 1].hipY - buf[i - 2].hipY;
      const curr = buf[i].hipY - buf[i - 1].hipY;
      if (prev > 0.001 && curr < -0.001) bounceCount++; // peak
    }
    const bounceFreq = bounceCount / (n / 30); // bounces per second

    // Smoothness ratio: low jerk relative to energy = smooth
    const smoothnessRatio = avgEnergy > 0.1
      ? Math.max(0, 1 - avgJerk / (avgEnergy * 10))
      : 0.5;

    return {
      avgJerk, avgSymmetry, avgHandSpeed, avgFootSpeed, avgEnergy,
      footContactRate, avgHeadBob, bounceFreq, smoothnessRatio,
    };
  }

  /**
   * Score each genre based on aggregate stats.
   * Returns normalized scores that sum to 1.
   *
   * Design:
   *   Lo-fi  = default genre for gentle/moderate movement (smooth, symmetric, low energy)
   *   Hip-hop = requires sharp, jerky movement (high jerk, low symmetry, bounce)
   *   EDM    = requires HIGH energy (totalKE > 4+, fast hands/feet)
   */
  _scoreGenres(stats) {
    // Lo-fi: smooth, balanced, moderate energy
    // Energy inverse: less energy → more lofi (it's the chill genre)
    const energyPenalty = Math.max(0.2, 1 - stats.avgEnergy / 12);
    const lofiRaw = (0.3 + stats.smoothnessRatio * 0.7)
      * (0.5 + stats.avgSymmetry * 0.5)
      * energyPenalty
      * (1 + stats.avgHeadBob * 40);

    // Hip-hop: jerky, asymmetric, bouncy
    // Power law on jerk: requires genuinely sharp movement
    const hiphopRaw = Math.pow(stats.avgJerk, 1.5) * 4
      * Math.max(0.1, 1 - stats.avgSymmetry)
      * (0.5 + stats.bounceFreq * 0.5)
      * (1 + stats.avgHeadBob * 20);

    // EDM: high energy, fast everything
    // Energy gate: soft-step that's ~0 below totalKE=4, ~1 at totalKE=12
    const edmGate = Math.max(0, stats.avgEnergy - 4) / 8;
    const edmRaw = edmGate
      * (1 + stats.avgFootSpeed)
      * (1 + stats.avgHandSpeed)
      * (1 + stats.footContactRate * 2);

    // Normalize to sum=1
    const total = lofiRaw + hiphopRaw + edmRaw;
    if (total < 0.001) {
      return { edm: 0.34, lofi: 0.33, hiphop: 0.33 };
    }

    return {
      lofi: lofiRaw / total,
      hiphop: hiphopRaw / total,
      edm: edmRaw / total,
    };
  }

  /**
   * Pick the genre with the highest score.
   */
  _pickGenre(scores) {
    let best = DEFAULT_GENRE;
    let bestScore = -1;
    for (const [genre, score] of Object.entries(scores)) {
      if (score > bestScore) {
        bestScore = score;
        best = genre;
      }
    }
    return best;
  }

  /**
   * Apply hysteresis: only switch if new genre dominates history and cooldown elapsed.
   */
  _applyHysteresis() {
    if (this.classHistory.length < 5) return this.currentGenre;

    // Count votes in recent history
    const counts = { edm: 0, lofi: 0, hiphop: 0 };
    for (const g of this.classHistory) {
      counts[g]++;
    }

    const total = this.classHistory.length;
    const now = performance.now();

    // Check if any genre dominates
    for (const [genre, count] of Object.entries(counts)) {
      if (genre !== this.currentGenre && count / total >= DOMINANCE_THRESHOLD) {
        // Check cooldown
        if (now - this.lastSwitchTime >= SWITCH_COOLDOWN_MS) {
          this.currentGenre = genre;
          this.lastSwitchTime = now;
          break;
        }
      }
    }

    return this.currentGenre;
  }

  /**
   * Reset all state.
   */
  reset() {
    this.featureBuffer = [];
    this.classHistory = [];
    this.currentGenre = DEFAULT_GENRE;
    this.lastSwitchTime = 0;
  }
}
