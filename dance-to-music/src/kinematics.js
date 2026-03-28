/**
 * kinematics.js — Real-time motion physics from pose landmarks.
 *
 * V2: Computes 13 features including research-backed additions:
 *   Original 7: totalKE, handSpeed, footSpeed, coreSpeed, hipY, armSpread, symmetry
 *   New 6:      footContact, ankleAccel, handAccel, jerkMagnitude, headBob, bodyTilt
 *
 * Research refs:
 *   - MotionBeat (2025): foot contact = strongest beat signal
 *   - Dance2MIDI (2023): decompose rhythm (feet) vs melody (hands)
 *   - Back to MLP (WACV 2023): acceleration/jerk features
 */

import { LANDMARKS } from "./pose.js?v=3";

// --- Jitter suppression constants ---
const DEADZONE = 0.025;      // min displacement to register (filters sitting-still jitter)
const VIS_THRESHOLD = 0.65;  // below this, scale speed by visibility
const SPEED_CAP = 8.0;       // max per-joint speed (rejects tracking glitches)

// Foot contact detection thresholds (MotionBeat 2025)
const FOOT_CONTACT_DECEL_THRESHOLD = 3.0;  // deceleration to register as strike
const FOOT_CONTACT_SPEED_FLOOR = 0.08;     // ankle must have been faster than this
const FOOT_CONTACT_WINDOW = 3;              // frames to look back

// Head bob running mean window
const HEAD_BOB_WINDOW = 15;                // ~0.25s at 60fps

// Body-part groups (landmark indices)
const GROUPS = {
  hands:  [LANDMARKS.LEFT_WRIST, LANDMARKS.RIGHT_WRIST],
  feet:   [LANDMARKS.LEFT_ANKLE, LANDMARKS.RIGHT_ANKLE],
  core:   [LANDMARKS.LEFT_HIP, LANDMARKS.RIGHT_HIP,
           LANDMARKS.LEFT_SHOULDER, LANDMARKS.RIGHT_SHOULDER],
  upper:  [LANDMARKS.LEFT_SHOULDER, LANDMARKS.RIGHT_SHOULDER,
           LANDMARKS.LEFT_ELBOW, LANDMARKS.RIGHT_ELBOW,
           LANDMARKS.LEFT_WRIST, LANDMARKS.RIGHT_WRIST],
  lower:  [LANDMARKS.LEFT_HIP, LANDMARKS.RIGHT_HIP,
           LANDMARKS.LEFT_KNEE, LANDMARKS.RIGHT_KNEE,
           LANDMARKS.LEFT_ANKLE, LANDMARKS.RIGHT_ANKLE],
};

/**
 * KinematicsEngine — accumulates landmark frames and outputs
 * smoothed energy / speed features every frame.
 */
export class KinematicsEngine {
  /**
   * @param {number} bufferSize  How many frames to keep (default 10)
   * @param {number} smoothing   EMA alpha 0–1 (default 0.3)
   */
  constructor(bufferSize = 10, smoothing = 0.3) {
    this.bufferSize = bufferSize;
    this.alpha = smoothing;
    this.buffer = [];          // circular array of [{x,y,z}[33], timestamp]
    this.prev = null;          // previous smoothed output (for EMA)

    // V2: History buffers for acceleration, foot contact, head bob
    this.speedHistory = [];    // last N frames of per-joint speeds
    this.velHistory = [];      // last N frames of per-joint velocities
    this.headYHistory = [];    // last N head Y positions for running mean
  }

  /** Clear all state — call when no person is detected. */
  reset() {
    this.buffer = [];
    this.prev = null;
    this.speedHistory = [];
    this.velHistory = [];
    this.headYHistory = [];
  }

  /**
   * Push a new frame of landmarks and return computed features.
   * @param {Array<{x:number,y:number,z:number,visibility:number}>} landmarks
   * @param {number} dt  seconds since last frame
   * @returns {MotionFeatures|null}  null if not enough frames yet
   */
  push(landmarks, dt) {
    // Store positions AND visibility (visibility used for jitter filtering)
    const positions = landmarks.map(lm => ({
      x: lm.x, y: lm.y, z: lm.z, v: lm.visibility ?? 1
    }));
    this.buffer.push({ positions, dt });
    if (this.buffer.length > this.bufferSize) this.buffer.shift();

    // Need at least 3 frames for central-difference velocity
    if (this.buffer.length < 3) return null;

    const n = this.buffer.length;
    const cur  = this.buffer[n - 1].positions;   // current frame
    const prev = this.buffer[n - 3].positions;   // 2 frames ago
    const dt2  = this._dtSpan(n - 3, n - 1);     // time between those frames

    if (dt2 <= 0) return null;

    // --- Per-joint velocity & speed (with jitter suppression) ---
    const velocities = new Array(33);
    const speeds     = new Array(33);
    for (let j = 0; j < 33; j++) {
      const dx = cur[j].x - prev[j].x;
      const dy = cur[j].y - prev[j].y;
      const dz = cur[j].z - prev[j].z;
      const rawDisplacement = Math.sqrt(dx * dx + dy * dy + dz * dz);

      // Jitter filter 1: Deadzone — ignore tiny displacements (tracking noise)
      // 0.005 in normalized coords ≈ a few pixels of jitter
      if (rawDisplacement < DEADZONE) {
        velocities[j] = { x: 0, y: 0, z: 0 };
        speeds[j] = 0;
        continue;
      }

      const vx = dx / dt2;
      const vy = dy / dt2;
      const vz = dz / dt2;
      let speed = Math.sqrt(vx * vx + vy * vy + vz * vz);

      // Jitter filter 2: Visibility weighting — low-confidence joints contribute less
      const vis = Math.min(cur[j].v, prev[j].v);
      if (vis < VIS_THRESHOLD) {
        speed *= vis; // fade contribution as visibility drops
      }

      // Jitter filter 3: Speed cap — reject tracking glitches
      speed = Math.min(speed, SPEED_CAP);

      velocities[j] = { x: vx, y: vy, z: vz };
      speeds[j] = speed;
    }

    // --- Aggregate features (original 7) ---
    const totalKE   = this._kineticEnergy(speeds);
    const handSpeed = this._groupSpeed(speeds, GROUPS.hands);
    const footSpeed = this._groupSpeed(speeds, GROUPS.feet);
    const coreSpeed = this._groupSpeed(speeds, GROUPS.core);

    // Hip midpoint Y (for vertical bounce detection)
    const hipY = (cur[LANDMARKS.LEFT_HIP].y + cur[LANDMARKS.RIGHT_HIP].y) / 2;

    // Arm spread (wrist-to-wrist distance, normalized by shoulder width)
    const armSpread = this._distance(
      cur[LANDMARKS.LEFT_WRIST], cur[LANDMARKS.RIGHT_WRIST]
    );

    // Left-right speed asymmetry (0 = symmetric, 1 = fully one-sided)
    const leftSpeed  = (speeds[LANDMARKS.LEFT_WRIST] + speeds[LANDMARKS.LEFT_ANKLE]) / 2;
    const rightSpeed = (speeds[LANDMARKS.RIGHT_WRIST] + speeds[LANDMARKS.RIGHT_ANKLE]) / 2;
    const maxLR = Math.max(leftSpeed + rightSpeed, 0.001);
    const symmetry = 1 - Math.abs(leftSpeed - rightSpeed) / maxLR;

    // Right wrist Y (for melody pitch mapping later)
    const rightWristY = cur[LANDMARKS.RIGHT_WRIST].y;
    const leftWristY  = cur[LANDMARKS.LEFT_WRIST].y;

    // --- V2 features (research-backed) ---

    // Store speed/velocity history for acceleration and foot contact
    this.speedHistory.push([...speeds]);
    this.velHistory.push(velocities.map(v => ({ x: v.x, y: v.y, z: v.z })));
    if (this.speedHistory.length > this.bufferSize) {
      this.speedHistory.shift();
      this.velHistory.shift();
    }

    // Head Y running mean for head bob detection
    this.headYHistory.push(cur[LANDMARKS.NOSE].y);
    if (this.headYHistory.length > HEAD_BOB_WINDOW) this.headYHistory.shift();

    // Foot contact detection (MotionBeat 2025)
    const footContact = this._detectFootContact(speeds);

    // Acceleration (2nd derivative) — needs at least 2 velocity frames
    let ankleAccel = 0, handAccel = 0;
    if (this.velHistory.length >= 2) {
      const prevVel = this.velHistory[this.velHistory.length - 2];
      ankleAccel = this._groupAccel(velocities, prevVel, GROUPS.feet, dt);
      handAccel  = this._groupAccel(velocities, prevVel, GROUPS.hands, dt);
    }

    // Jerk magnitude (3rd derivative) — needs at least 3 speed frames
    let jerkMagnitude = 0;
    if (this.speedHistory.length >= 3) {
      const sh = this.speedHistory;
      const len = sh.length;
      const prevAccel = this._meanSpeed(sh[len - 2]) - this._meanSpeed(sh[len - 3]);
      const curAccel  = this._meanSpeed(sh[len - 1]) - this._meanSpeed(sh[len - 2]);
      jerkMagnitude = Math.abs(curAccel - prevAccel) / (dt * dt);
    }

    // Head bob (deviation from running mean)
    let headBob = 0;
    if (this.headYHistory.length >= 3) {
      const mean = this.headYHistory.reduce((a, b) => a + b, 0) / this.headYHistory.length;
      headBob = Math.abs(cur[LANDMARKS.NOSE].y - mean);
    }

    // Body tilt (shoulder line angle from horizontal)
    const ls = cur[LANDMARKS.LEFT_SHOULDER];
    const rs = cur[LANDMARKS.RIGHT_SHOULDER];
    const sDy = rs.y - ls.y;
    const sDx = Math.max(Math.abs(rs.x - ls.x), 0.001);
    const bodyTilt = Math.abs(Math.atan2(sDy, sDx));

    const raw = {
      totalKE, handSpeed, footSpeed, coreSpeed,
      hipY, armSpread, symmetry,
      // V2 features
      footContact, ankleAccel, handAccel,
      jerkMagnitude, headBob, bodyTilt,
      // Extra (not in model input, used by rule mapper)
      rightWristY, leftWristY, speeds, velocities,
    };

    // --- Smooth with EMA ---
    const smoothKeys = [
      "totalKE", "handSpeed", "footSpeed", "coreSpeed",
      "hipY", "armSpread", "symmetry",
      "footContact", "ankleAccel", "handAccel",
      "jerkMagnitude", "headBob", "bodyTilt",
    ];

    if (!this.prev) {
      this.prev = {};
      for (const k of smoothKeys) this.prev[k] = raw[k];
    } else {
      const a = this.alpha;
      for (const k of smoothKeys) {
        this.prev[k] = this.prev[k] + a * (raw[k] - this.prev[k]);
      }
    }

    return {
      raw,
      smoothed: { ...this.prev },
      rightWristY,
      leftWristY,
    };
  }

  /** Sum dt across buffer indices [from, to]. */
  _dtSpan(from, to) {
    let total = 0;
    for (let i = from + 1; i <= to; i++) total += this.buffer[i].dt;
    return total;
  }

  /**
   * Total kinetic energy: sum(0.5 * speed^2) — but ONLY for visible joints.
   * When sitting at a desk, MediaPipe guesses lower body positions and they jitter,
   * creating false energy. We only count joints with visibility > threshold.
   */
  _kineticEnergy(speeds) {
    let ke = 0;
    let visibleCount = 0;
    const cur = this.buffer[this.buffer.length - 1].positions;
    for (let i = 0; i < speeds.length; i++) {
      if (cur[i].v >= VIS_THRESHOLD) {
        ke += speeds[i] * speeds[i];
        visibleCount++;
      }
    }
    // Scale KE by fraction of visible joints to penalize partial body
    // Full body (33 joints visible) = 1.0x, half body (16) = 0.48x
    const visFraction = visibleCount / 33;
    return 0.5 * ke * visFraction;
  }

  /** Average speed of a joint group. */
  _groupSpeed(speeds, indices) {
    let sum = 0;
    for (const i of indices) sum += speeds[i];
    return sum / indices.length;
  }

  /** Euclidean distance between two 3D points. */
  _distance(a, b) {
    const dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * Detect foot strike via sharp ankle deceleration (MotionBeat 2025).
   * Returns 1.0 if strike detected, 0.0 otherwise.
   */
  _detectFootContact(speeds) {
    if (this.speedHistory.length < FOOT_CONTACT_WINDOW + 1) return 0;

    const sh = this.speedHistory;
    const len = sh.length;

    for (const idx of GROUPS.feet) {
      const currentSpeed = speeds[idx];

      // Check recent max speed (was foot recently moving?)
      let recentMax = 0;
      for (let i = Math.max(0, len - 1 - FOOT_CONTACT_WINDOW); i < len - 1; i++) {
        if (sh[i][idx] > recentMax) recentMax = sh[i][idx];
      }

      if (recentMax < FOOT_CONTACT_SPEED_FLOOR) continue;

      // Check for sharp deceleration
      const dt = this.buffer[this.buffer.length - 1].dt || 0.033;
      const decel = (recentMax - currentSpeed) / (FOOT_CONTACT_WINDOW * dt);
      if (decel > FOOT_CONTACT_DECEL_THRESHOLD) return 1.0;
    }
    return 0.0;
  }

  /** Acceleration magnitude for a joint group (velocity difference / dt). */
  _groupAccel(curVel, prevVel, indices, dt) {
    let sum = 0;
    for (const i of indices) {
      const dx = curVel[i].x - prevVel[i].x;
      const dy = curVel[i].y - prevVel[i].y;
      const dz = curVel[i].z - prevVel[i].z;
      sum += Math.sqrt(dx * dx + dy * dy + dz * dz) / dt;
    }
    return sum / indices.length;
  }

  /** Mean of all joint speeds in a frame. */
  _meanSpeed(speedArray) {
    let sum = 0;
    for (let i = 0; i < speedArray.length; i++) sum += speedArray[i];
    return sum / speedArray.length;
  }
}
