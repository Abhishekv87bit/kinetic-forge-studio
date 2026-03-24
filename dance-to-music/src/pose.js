/**
 * pose.js — MediaPipe Pose Landmarker wrapper.
 * Detects 33 body landmarks from camera feed at ~30fps.
 */
import { PoseLandmarker, FilesetResolver } from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.18/vision_bundle.mjs";

const MODEL_URL =
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task";
const WASM_URL =
  "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.18/wasm";

// Skeleton connections (pairs of landmark indices for drawing bones)
const CONNECTIONS = [
  // Torso
  [11, 12], [11, 23], [12, 24], [23, 24],
  // Left arm
  [11, 13], [13, 15],
  // Right arm
  [12, 14], [14, 16],
  // Left leg
  [23, 25], [25, 27],
  // Right leg
  [24, 26], [26, 28],
  // Left hand
  [15, 17], [15, 19], [15, 21],
  // Right hand
  [16, 18], [16, 20], [16, 22],
  // Left foot
  [27, 29], [27, 31], [29, 31],
  // Right foot
  [28, 30], [28, 32], [30, 32],
];

// Key landmark indices (exported for kinematics module)
export const LANDMARKS = {
  NOSE: 0,
  LEFT_SHOULDER: 11,
  RIGHT_SHOULDER: 12,
  LEFT_ELBOW: 13,
  RIGHT_ELBOW: 14,
  LEFT_WRIST: 15,
  RIGHT_WRIST: 16,
  LEFT_HIP: 23,
  RIGHT_HIP: 24,
  LEFT_KNEE: 25,
  RIGHT_KNEE: 26,
  LEFT_ANKLE: 27,
  RIGHT_ANKLE: 28,
};

export class PoseTracker {
  constructor(video, canvas) {
    this.video = video;
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.landmarker = null;
    this.running = false;
    this.onFrame = null; // callback: (landmarks, dt) => void
  }

  async init(onStatus) {
    onStatus?.("Loading AI model...");
    const vision = await FilesetResolver.forVisionTasks(WASM_URL);

    this.landmarker = await PoseLandmarker.createFromOptions(vision, {
      baseOptions: { modelAssetPath: MODEL_URL, delegate: "GPU" },
      runningMode: "VIDEO",
      numPoses: 1,
    });

    onStatus?.("Starting camera...");
    let stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user", width: { ideal: 640 }, height: { ideal: 480 } },
        audio: false,
      });
    } catch (camErr) {
      if (camErr.name === "NotAllowedError") {
        throw new Error("Camera blocked. Tap the lock icon in your address bar → allow Camera, then reload.");
      }
      if (camErr.name === "NotFoundError") {
        throw new Error("No camera found. This app needs a camera to track your dance.");
      }
      throw camErr;
    }
    this.video.srcObject = stream;
    await new Promise((r) => (this.video.onloadedmetadata = r));
    await this.video.play();

    // Match canvas resolution to video
    this.canvas.width = this.video.videoWidth;
    this.canvas.height = this.video.videoHeight;

    onStatus?.("Ready");
  }

  start() {
    this.running = true;
    this._lastTimestamp = performance.now();
    this._detect();
  }

  stop() {
    this.running = false;
  }

  _detect() {
    if (!this.running) return;

    const now = performance.now();
    const dt = (now - this._lastTimestamp) / 1000; // seconds
    this._lastTimestamp = now;

    const results = this.landmarker.detectForVideo(this.video, now);
    const { width, height } = this.canvas;

    // Clear canvas
    this.ctx.clearRect(0, 0, width, height);

    if (results.landmarks.length > 0) {
      const lm = results.landmarks[0];
      this._drawSkeleton(lm, width, height);
      this.onFrame?.(lm, dt);
    } else {
      // No person detected — signal null so meters decay to zero
      this.onFrame?.(null, dt);
    }

    requestAnimationFrame(() => this._detect());
  }

  _drawSkeleton(landmarks, w, h) {
    const ctx = this.ctx;

    // Draw bones
    ctx.strokeStyle = "#22c55e";
    ctx.lineWidth = 3;
    ctx.lineCap = "round";
    for (const [i, j] of CONNECTIONS) {
      const a = landmarks[i];
      const b = landmarks[j];
      if (a.visibility > 0.5 && b.visibility > 0.5) {
        ctx.beginPath();
        ctx.moveTo(a.x * w, a.y * h);
        ctx.lineTo(b.x * w, b.y * h);
        ctx.stroke();
      }
    }

    // Draw joints
    for (const lm of landmarks) {
      if (lm.visibility > 0.5) {
        ctx.fillStyle = "#fff";
        ctx.beginPath();
        ctx.arc(lm.x * w, lm.y * h, 4, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
