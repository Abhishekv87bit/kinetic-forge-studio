/**
 * ml-mapper.js — V2 ML-based motion-to-music mapper with pure JS inference.
 *
 * Implements the V2 model forward pass manually — no TF.js dependency needed.
 *
 * V2 Architecture (research-backed):
 *   BiLSTM(48) → LSTM(48) → Dense(48,relu)  [shared encoder]
 *   ├─ Rhythm head: Dense(24,relu) → Dense(3,sigmoid)  [bass trigger/pitch/velocity]
 *   ├─ Melody head: Dense(24,relu) → Dense(4,sigmoid)  [melody trigger/pitch/velocity/sustain]
 *   └─ Energy head: Dense(16,relu) → Dense(2,sigmoid)  [energy level, rhythm density]
 *
 * Input: 13 features (7 original + 6 research-backed)
 * Output: 9 targets (was 7)
 *
 * Research refs:
 *   - MotionBeat (2025): foot contact → rhythm head
 *   - Dance2MIDI (2023): decomposed rhythm vs melody heads
 *   - Back to MLP (WACV 2023): acceleration/jerk features
 *
 * Weights loaded from exported JSON (~1.2MB, 57K params).
 */

// Pentatonic scales (same as rule-based mapper)
const ML_MELODY_SCALE = ["C4","D4","E4","G4","A4","C5","D5","E5","G5","A5","C6"];
const ML_BASS_SCALE   = ["C2","D2","E2","G2","A2","C3"];

const SEQ_LEN = 32;
const NUM_FEATURES = 13;

// Duration constants
const MELODY_DURATION_SHORT  = "16n";
const MELODY_DURATION_NORMAL = "8n";
const MELODY_DURATION_LONG   = "4n";
const BASS_DURATION = "4n";

// --- Pure JS math helpers ---
function sigmoid(x) { return 1 / (1 + Math.exp(-Math.max(-20, Math.min(20, x)))); }

/**
 * LSTM cell: one timestep.
 * Keras stores gates as [i, f, c, o] interleaved across the units dimension.
 */
function lstmStep(x, hPrev, cPrev, kernel, recKernel, bias, units, inputDim) {
  const g4 = 4 * units;
  const gates = new Float32Array(g4);

  // gates = kernel @ x + recurrent_kernel @ h_prev + bias
  for (let g = 0; g < g4; g++) {
    let sum = bias[g];
    for (let j = 0; j < inputDim; j++) sum += kernel[j * g4 + g] * x[j];
    for (let j = 0; j < units; j++) sum += recKernel[j * g4 + g] * hPrev[j];
    gates[g] = sum;
  }

  const h = new Float32Array(units);
  const c = new Float32Array(units);

  for (let i = 0; i < units; i++) {
    const ig = sigmoid(gates[i]);              // input gate
    const fg = sigmoid(gates[units + i]);      // forget gate
    const cg = Math.tanh(gates[2 * units + i]);// cell candidate
    const og = sigmoid(gates[3 * units + i]);  // output gate

    c[i] = fg * cPrev[i] + ig * cg;
    h[i] = og * Math.tanh(c[i]);
  }
  return { h, c };
}

/** Dense layer: output = activation(kernel @ input + bias) */
function denseLayer(input, kernel, bias, inputDim, outputDim, activation = "relu") {
  const out = new Float32Array(outputDim);
  for (let i = 0; i < outputDim; i++) {
    let sum = bias[i];
    for (let j = 0; j < inputDim; j++) sum += kernel[j * outputDim + i] * input[j];
    if (activation === "relu") {
      out[i] = sum > 0 ? sum : 0;
    } else if (activation === "sigmoid") {
      out[i] = sigmoid(sum);
    } else {
      out[i] = sum; // linear
    }
  }
  return out;
}


export class MLMapper {
  constructor() {
    this.weights = null;
    this.ready = false;
    this.buffer = [];
    this.lastMelodyTime = 0;
    this.lastBassTime = 0;
    this.melodyDebounceMs = 100;
    this.bassDebounceMs = 180;
    this.version = 1; // detected from weights
  }

  /**
   * Load model weights from JSON.
   * Auto-detects V1 vs V2 based on weight keys.
   */
  async init(weightsUrl) {
    try {
      // Try V2 first, fall back to V1
      let url = weightsUrl;
      const v2Url = weightsUrl.replace("model_weights.json", "model_weights_v2.json");

      console.log("MLMapper: Trying V2 weights from", v2Url);
      let resp = await fetch(v2Url);

      if (resp.ok) {
        url = v2Url;
        this.version = 2;
      } else {
        console.log("MLMapper: V2 not found, trying V1 from", weightsUrl);
        resp = await fetch(weightsUrl);
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
        this.version = 1;
      }

      const raw = await resp.json();

      // Parse weights into typed arrays
      this.w = {};
      for (const [name, { shape, data }] of Object.entries(raw)) {
        this.w[name] = { shape, data: new Float32Array(data) };
      }

      this.ready = true;
      console.log(`MLMapper: V${this.version} model ready (${Object.keys(this.w).length} weight tensors, pure JS inference)`);
      return true;
    } catch (err) {
      console.error("MLMapper: Failed to load weights:", err);
      return false;
    }
  }

  update(features) {
    if (!features || !this.ready) return { melody: null, bass: null };

    const { smoothed } = features;

    // Build input frame — V2 has 13 features, V1 has 7
    let frame;
    if (this.version >= 2) {
      frame = new Float32Array([
        smoothed.totalKE, smoothed.handSpeed, smoothed.footSpeed,
        smoothed.coreSpeed, smoothed.hipY, smoothed.armSpread, smoothed.symmetry,
        smoothed.footContact ?? 0, smoothed.ankleAccel ?? 0, smoothed.handAccel ?? 0,
        smoothed.jerkMagnitude ?? 0, smoothed.headBob ?? 0, smoothed.bodyTilt ?? 0,
      ]);
    } else {
      frame = new Float32Array([
        smoothed.totalKE, smoothed.handSpeed, smoothed.footSpeed,
        smoothed.coreSpeed, smoothed.hipY, smoothed.armSpread, smoothed.symmetry,
      ]);
    }

    this.buffer.push(frame);
    if (this.buffer.length > SEQ_LEN) this.buffer.shift();
    const empty = { melody: null, bass: null, kick: null, hihat: null, pad: null, pan: 0, reverb: 0.15 };
    if (this.buffer.length < SEQ_LEN) return empty;

    // Flatten buffer
    const numFeat = frame.length;
    const seq = new Float32Array(SEQ_LEN * numFeat);
    for (let t = 0; t < SEQ_LEN; t++) seq.set(this.buffer[t], t * numFeat);

    const pred = this.version >= 2 ? this._inferV2(seq) : this._inferV1(seq);
    if (!pred) return empty;

    // ML model drives melody + bass. Other instruments from features directly.
    let melody, bass;
    if (this.version >= 2) {
      melody = this._decodeMelodyV2(pred, features);
      bass = this._decodeBassV2(pred);
    } else {
      melody = this._decodeMelodyV1(pred, features);
      bass = this._decodeBassV1(pred);
    }

    // Kick/hihat/pad/pan/reverb from features (same logic as rule mapper)
    const kick = this._mapKick(smoothed);
    const hihat = this._mapHiHat(smoothed);
    const pad = this._mapPad(smoothed);
    const pan = this._mapPan(smoothed);
    const reverb = this._mapReverb(smoothed);

    return { melody, bass, kick, hihat, pad, pan, reverb };
  }

  // ─── V2 Inference: BiLSTM(48) → LSTM(48) → shared Dense(48) → 3 heads ───

  _inferV2(seq) {
    const w = this.w;
    if (!w) return null;

    const get = (key) => {
      for (const [name, val] of Object.entries(w)) {
        if (name.includes(key)) return val.data;
      }
      return null;
    };

    const units = 48;
    const inputDim = NUM_FEATURES;

    // --- BiLSTM encoder ---
    const fwdK = get("forward_bilstm__lstm_cell__kernel");
    const fwdR = get("forward_bilstm__lstm_cell__recurrent_kernel");
    const fwdB = get("forward_bilstm__lstm_cell__bias");
    const bwdK = get("backward_bilstm__lstm_cell__kernel");
    const bwdR = get("backward_bilstm__lstm_cell__recurrent_kernel");
    const bwdB = get("backward_bilstm__lstm_cell__bias");

    if (!fwdK || !bwdK) return null;

    // Forward LSTM
    const fwdH = new Float32Array(SEQ_LEN * units);
    let fh = new Float32Array(units), fc = new Float32Array(units);
    for (let t = 0; t < SEQ_LEN; t++) {
      const x = seq.subarray(t * inputDim, (t + 1) * inputDim);
      ({ h: fh, c: fc } = lstmStep(x, fh, fc, fwdK, fwdR, fwdB, units, inputDim));
      fwdH.set(fh, t * units);
    }

    // Backward LSTM
    const bwdH = new Float32Array(SEQ_LEN * units);
    let bh = new Float32Array(units), bc = new Float32Array(units);
    for (let t = SEQ_LEN - 1; t >= 0; t--) {
      const x = seq.subarray(t * inputDim, (t + 1) * inputDim);
      ({ h: bh, c: bc } = lstmStep(x, bh, bc, bwdK, bwdR, bwdB, units, inputDim));
      bwdH.set(bh, t * units);
    }

    // Concatenate → (SEQ_LEN, 96)
    const biDim = 2 * units;
    const biOut = new Float32Array(SEQ_LEN * biDim);
    for (let t = 0; t < SEQ_LEN; t++) {
      for (let i = 0; i < units; i++) {
        biOut[t * biDim + i] = fwdH[t * units + i];
        biOut[t * biDim + units + i] = bwdH[t * units + i];
      }
    }

    // --- Second LSTM (return_sequences=False) ---
    const l2K = get("encoder_lstm__lstm_cell__kernel");
    const l2R = get("encoder_lstm__lstm_cell__recurrent_kernel");
    const l2B = get("encoder_lstm__lstm_cell__bias");
    let h2 = new Float32Array(units), c2 = new Float32Array(units);
    for (let t = 0; t < SEQ_LEN; t++) {
      const x = biOut.subarray(t * biDim, (t + 1) * biDim);
      ({ h: h2, c: c2 } = lstmStep(x, h2, c2, l2K, l2R, l2B, units, biDim));
    }

    // --- Shared Dense(48, relu) ---
    const sdK = get("shared_dense__kernel");
    const sdB = get("shared_dense__bias");
    const shared = denseLayer(h2, sdK, sdB, units, 48, "relu");

    // --- Rhythm head: Dense(24,relu) → Dense(3,sigmoid) ---
    const rhK = get("rhythm_dense__kernel");
    const rhB = get("rhythm_dense__bias");
    const rh = denseLayer(shared, rhK, rhB, 48, 24, "relu");

    const roK = get("rhythm_output__kernel");
    const roB = get("rhythm_output__bias");
    const rhythmOut = denseLayer(rh, roK, roB, 24, 3, "sigmoid");

    // --- Melody head: Dense(24,relu) → Dense(4,sigmoid) ---
    const mhK = get("melody_dense__kernel");
    const mhB = get("melody_dense__bias");
    const mh = denseLayer(shared, mhK, mhB, 48, 24, "relu");

    const moK = get("melody_output__kernel");
    const moB = get("melody_output__bias");
    const melodyOut = denseLayer(mh, moK, moB, 24, 4, "sigmoid");

    // --- Energy head: Dense(16,relu) → Dense(2,sigmoid) ---
    const ehK = get("energy_dense__kernel");
    const ehB = get("energy_dense__bias");
    const eh = denseLayer(shared, ehK, ehB, 48, 16, "relu");

    const eoK = get("energy_output__kernel");
    const eoB = get("energy_output__bias");
    const energyOut = denseLayer(eh, eoK, eoB, 16, 2, "sigmoid");

    // Concatenate: [bass(3), melody(4), energy(2)] = 9 outputs
    return {
      // Rhythm head
      bassTrigger:   rhythmOut[0],
      bassPitch:     rhythmOut[1],
      bassVelocity:  rhythmOut[2],
      // Melody head
      melodyTrigger:  melodyOut[0],
      melodyPitch:    melodyOut[1],
      melodyVelocity: melodyOut[2],
      melodySustain:  melodyOut[3],
      // Energy head
      energyLevel:   energyOut[0],
      rhythmDensity: energyOut[1],
    };
  }

  // ─── V2 Decode: Rhythm head → bass commands ───

  _decodeBassV2(pred) {
    if (pred.bassTrigger < 0.5) return null;

    const now = performance.now();
    if (now - this.lastBassTime < this.bassDebounceMs) return null;
    this.lastBassTime = now;

    const idx = Math.round(Math.max(0, Math.min(1, pred.bassPitch)) * (ML_BASS_SCALE.length - 1));
    const note = ML_BASS_SCALE[idx];
    const velocity = Math.max(0.3, Math.min(1.0, pred.bassVelocity));

    return { note, velocity, duration: BASS_DURATION };
  }

  // ─── V2 Decode: Melody head → melody commands ───

  _decodeMelodyV2(pred, features) {
    if (pred.melodyTrigger < 0.5) return null;

    const now = performance.now();
    if (now - this.lastMelodyTime < this.melodyDebounceMs) return null;
    this.lastMelodyTime = now;

    // Blend model pitch with hand height (70/30 — model learns timing, hands control pitch)
    const modelPitch = Math.max(0, Math.min(1, pred.melodyPitch));
    const handPitch = features.rightWristY != null
      ? 1 - Math.max(0.1, Math.min(0.9, features.rightWristY))
      : modelPitch;
    const blended = 0.7 * modelPitch + 0.3 * handPitch;

    const idx = Math.round(blended * (ML_MELODY_SCALE.length - 1));
    const note = ML_MELODY_SCALE[Math.max(0, Math.min(idx, ML_MELODY_SCALE.length - 1))];
    const velocity = Math.max(0.2, Math.min(1.0, pred.melodyVelocity));

    // Sustain: model predicts note duration (staccato vs legato)
    // Low sustain → short note, high sustain → long note
    let duration = MELODY_DURATION_NORMAL;
    if (pred.melodySustain < 0.3) {
      duration = MELODY_DURATION_SHORT;   // staccato — sharp hand movement
    } else if (pred.melodySustain > 0.7) {
      duration = MELODY_DURATION_LONG;    // legato — smooth hand movement
    }

    return { note, velocity, duration };
  }

  // ─── V1 Inference (backward compat) ───

  _inferV1(seq) {
    const w = this.w;
    if (!w) return null;

    const get = (key) => {
      for (const [name, val] of Object.entries(w)) {
        if (name.includes(key)) return val.data;
      }
      return null;
    };

    const units = 32;
    const inputDim = 7;

    // BiLSTM
    const fwdK = get("forward_lstm__lstm_cell__kernel");
    const fwdR = get("forward_lstm__lstm_cell__recurrent_kernel");
    const fwdB = get("forward_lstm__lstm_cell__bias");
    const bwdK = get("backward_lstm__lstm_cell__kernel");
    const bwdR = get("backward_lstm__lstm_cell__recurrent_kernel");
    const bwdB = get("backward_lstm__lstm_cell__bias");

    if (!fwdK || !bwdK) return null;

    const fwdH = new Float32Array(SEQ_LEN * units);
    let fh = new Float32Array(units), fc = new Float32Array(units);
    for (let t = 0; t < SEQ_LEN; t++) {
      const x = seq.subarray(t * inputDim, (t + 1) * inputDim);
      ({ h: fh, c: fc } = lstmStep(x, fh, fc, fwdK, fwdR, fwdB, units, inputDim));
      fwdH.set(fh, t * units);
    }

    const bwdH = new Float32Array(SEQ_LEN * units);
    let bh = new Float32Array(units), bc = new Float32Array(units);
    for (let t = SEQ_LEN - 1; t >= 0; t--) {
      const x = seq.subarray(t * inputDim, (t + 1) * inputDim);
      ({ h: bh, c: bc } = lstmStep(x, bh, bc, bwdK, bwdR, bwdB, units, inputDim));
      bwdH.set(bh, t * units);
    }

    const biOut = new Float32Array(SEQ_LEN * 64);
    for (let t = 0; t < SEQ_LEN; t++) {
      for (let i = 0; i < units; i++) {
        biOut[t * 64 + i] = fwdH[t * units + i];
        biOut[t * 64 + units + i] = bwdH[t * units + i];
      }
    }

    // Second LSTM
    const l2K = get("lstm_1__lstm_cell__kernel");
    const l2R = get("lstm_1__lstm_cell__recurrent_kernel");
    const l2B = get("lstm_1__lstm_cell__bias");
    let h2 = new Float32Array(units), c2 = new Float32Array(units);
    for (let t = 0; t < SEQ_LEN; t++) {
      const x = biOut.subarray(t * 64, (t + 1) * 64);
      ({ h: h2, c: c2 } = lstmStep(x, h2, c2, l2K, l2R, l2B, units, 64));
    }

    // Dense layers
    const dK = get("dense__sequential__dense__kernel");
    const dB = get("dense__sequential__dense__bias");
    const d1 = denseLayer(h2, dK, dB, 32, 32, "relu");

    const oK = get("dense_1__sequential__dense_1__kernel");
    const oB = get("dense_1__sequential__dense_1__bias");
    return denseLayer(d1, oK, oB, 32, 7, "sigmoid");
  }

  _decodeMelodyV1(pred, features) {
    if (pred[0] < 0.5) return null;
    const now = performance.now();
    if (now - this.lastMelodyTime < this.melodyDebounceMs) return null;
    this.lastMelodyTime = now;

    const modelPitch = Math.max(0, Math.min(1, pred[1]));
    const handPitch = features.rightWristY != null
      ? 1 - Math.max(0.1, Math.min(0.9, features.rightWristY))
      : modelPitch;
    const blended = 0.7 * modelPitch + 0.3 * handPitch;
    const idx = Math.round(blended * (ML_MELODY_SCALE.length - 1));
    const note = ML_MELODY_SCALE[Math.max(0, Math.min(idx, ML_MELODY_SCALE.length - 1))];
    const velocity = Math.max(0.2, Math.min(1.0, pred[2]));
    return { note, velocity, duration: MELODY_DURATION_NORMAL };
  }

  _decodeBassV1(pred) {
    if (pred[3] < 0.5) return null;
    const now = performance.now();
    if (now - this.lastBassTime < this.bassDebounceMs) return null;
    this.lastBassTime = now;

    const idx = Math.round(Math.max(0, Math.min(1, pred[4])) * (ML_BASS_SCALE.length - 1));
    const note = ML_BASS_SCALE[idx];
    const velocity = Math.max(0.3, Math.min(1.0, pred[5]));
    return { note, velocity, duration: BASS_DURATION };
  }

  // --- Shared body-part → instrument helpers (used by both ML and rules) ---

  _mapKick(smoothed) {
    if ((smoothed.footContact ?? 0) < 0.3) return null;
    const now = performance.now();
    if (now - this._lastKickTime < 150) return null;
    this._lastKickTime = now;
    const velocity = Math.min(1.0, 0.4 + Math.min(smoothed.ankleAccel ?? 0, 20) / 30);
    return { velocity };
  }

  _mapHiHat(smoothed) {
    if ((smoothed.headBob ?? 0) < 0.005) return null;
    const now = performance.now();
    if (now - this._lastHatTime < 100) return null;
    this._lastHatTime = now;
    return { velocity: Math.min(0.8, 0.2 + (smoothed.headBob ?? 0) * 20) };
  }

  _mapPad(smoothed) {
    const spread = smoothed.armSpread;
    let volume = spread > 0.15 ? Math.min(1.0, (spread - 0.15) / 0.45) : 0;
    const energy = smoothed.totalKE;
    const chord = energy < 2 ? ["C3","E3","G3"]
                : energy < 5 ? ["C3","E3","G3","A3"]
                : ["C3","E3","G3","A3","D4"];
    return { chord, volume };
  }

  _mapPan(smoothed) {
    return Math.max(-1, Math.min(1, (smoothed.bodyTilt ?? 0) * 8.0));
  }

  _mapReverb(smoothed) {
    const jerk = smoothed.jerkMagnitude ?? 0;
    return Math.max(0.05, 0.4 - Math.min(jerk, 50) / 50 * 0.35);
  }

  reset() {
    this.buffer = [];
    this.lastMelodyTime = 0;
    this.lastBassTime = 0;
    this._lastKickTime = 0;
    this._lastHatTime = 0;
  }
}
