"""
kinematics.py — Python port of kinematics.js for AIST++ feature extraction.

Computes 13 motion features from COCO 17-joint keypoints that the
browser version computes from MediaPipe 33-joint landmarks.

V2 feature set (research-backed upgrades):
  Original 7: totalKE, handSpeed, footSpeed, coreSpeed, hipY, armSpread, symmetry
  New 6:      footContact, ankleAccel, handAccel, jerkMagnitude, headBob, bodyTilt

Research references:
  - MotionBeat (2025): foot contact events = strongest beat signal
  - Dance2MIDI (2023): decompose rhythm (feet/body) vs melody (hands)
  - Back to MLP (WACV 2023): acceleration/jerk features boost accuracy

COCO 17 joints:
  0=nose, 1=left_eye, 2=right_eye, 3=left_ear, 4=right_ear,
  5=left_shoulder, 6=right_shoulder, 7=left_elbow, 8=right_elbow,
  9=left_wrist, 10=right_wrist, 11=left_hip, 12=right_hip,
  13=left_knee, 14=right_knee, 15=left_ankle, 16=right_ankle
"""

import numpy as np

# COCO 17-joint indices (equivalent to LANDMARKS in pose.js)
COCO = {
    "NOSE": 0,
    "LEFT_SHOULDER": 5,
    "RIGHT_SHOULDER": 6,
    "LEFT_ELBOW": 7,
    "RIGHT_ELBOW": 8,
    "LEFT_WRIST": 9,
    "RIGHT_WRIST": 10,
    "LEFT_HIP": 11,
    "RIGHT_HIP": 12,
    "LEFT_KNEE": 13,
    "RIGHT_KNEE": 14,
    "LEFT_ANKLE": 15,
    "RIGHT_ANKLE": 16,
}

# Body-part groups (mirrors GROUPS in kinematics.js)
GROUPS = {
    "hands": [COCO["LEFT_WRIST"], COCO["RIGHT_WRIST"]],
    "feet": [COCO["LEFT_ANKLE"], COCO["RIGHT_ANKLE"]],
    "core": [
        COCO["LEFT_HIP"], COCO["RIGHT_HIP"],
        COCO["LEFT_SHOULDER"], COCO["RIGHT_SHOULDER"],
    ],
}

# Jitter suppression constants (same as JS)
DEADZONE = 0.012
SPEED_CAP = 8.0

# Foot contact detection thresholds (MotionBeat 2025)
FOOT_CONTACT_DECEL_THRESHOLD = 3.0    # deceleration magnitude to register strike
FOOT_CONTACT_SPEED_FLOOR = 0.08       # ankle must have been moving faster than this
FOOT_CONTACT_WINDOW = 3               # frames to look back for prior speed

# Feature count
NUM_FEATURES_V1 = 7
NUM_FEATURES_V2 = 13


def extract_features(keypoints3d, fps=60, version=2):
    """
    Extract motion features from a sequence of COCO 17-joint keypoints.

    Args:
        keypoints3d: numpy array of shape (num_frames, 17, 3) — x,y,z positions
        fps: frames per second (AIST++ is 60fps)
        version: 1 for original 7 features, 2 for upgraded 13 features

    Returns:
        features: numpy array of shape (num_frames, N) — N features per frame
        feature_names: list of feature names
    """
    num_frames, num_joints, _ = keypoints3d.shape
    dt = 1.0 / fps

    # Normalize keypoints to 0-1 range (like MediaPipe does)
    kp = _normalize_keypoints(keypoints3d)

    num_feat = NUM_FEATURES_V2 if version >= 2 else NUM_FEATURES_V1
    features = np.zeros((num_frames, num_feat))

    feature_names = [
        "totalKE", "handSpeed", "footSpeed", "coreSpeed",
        "hipY", "armSpread", "symmetry",
    ]
    if version >= 2:
        feature_names += [
            "footContact", "ankleAccel", "handAccel",
            "jerkMagnitude", "headBob", "bodyTilt",
        ]

    # Pre-compute per-joint speeds for all frames (needed for foot contact lookback)
    all_speeds = np.zeros((num_frames, num_joints))
    all_velocity = np.zeros((num_frames, num_joints, 3))

    for t in range(1, num_frames - 1):
        dt2 = 2 * dt
        diff = kp[t + 1] - kp[t - 1]
        displacement = np.linalg.norm(diff, axis=1)
        vel = diff / dt2
        spd = np.linalg.norm(vel, axis=1)
        spd[displacement < DEADZONE] = 0.0
        spd = np.minimum(spd, SPEED_CAP)
        all_speeds[t] = spd
        all_velocity[t] = vel

    # Compute acceleration (2nd derivative) for v2 features
    if version >= 2:
        all_accel = np.zeros((num_frames, num_joints))
        for t in range(2, num_frames - 2):
            # Acceleration = change in speed over time
            accel_vec = (all_velocity[t + 1] - all_velocity[t - 1]) / (2 * dt)
            all_accel[t] = np.linalg.norm(accel_vec, axis=1)

        # Head Y running mean for head bob detection
        head_y = kp[:, COCO["NOSE"], 1]
        # Running mean with 15-frame window (~0.25s at 60fps)
        head_y_mean = np.convolve(head_y, np.ones(15) / 15, mode="same")

    # Main feature extraction loop
    for t in range(1, num_frames - 1):
        speed = all_speeds[t]

        # --- Original 7 features ---
        total_ke = 0.5 * np.sum(speed ** 2)
        hand_speed = np.mean(speed[GROUPS["hands"]])
        foot_speed = np.mean(speed[GROUPS["feet"]])
        core_speed = np.mean(speed[GROUPS["core"]])

        hip_y = (kp[t, COCO["LEFT_HIP"], 1] + kp[t, COCO["RIGHT_HIP"], 1]) / 2

        arm_spread = np.linalg.norm(
            kp[t, COCO["LEFT_WRIST"]] - kp[t, COCO["RIGHT_WRIST"]]
        )

        left_speed = (speed[COCO["LEFT_WRIST"]] + speed[COCO["LEFT_ANKLE"]]) / 2
        right_speed = (speed[COCO["RIGHT_WRIST"]] + speed[COCO["RIGHT_ANKLE"]]) / 2
        max_lr = max(left_speed + right_speed, 0.001)
        symmetry = 1 - abs(left_speed - right_speed) / max_lr

        features[t, :7] = [
            total_ke, hand_speed, foot_speed, core_speed,
            hip_y, arm_spread, symmetry,
        ]

        if version >= 2 and t >= 2 and t < num_frames - 2:
            # --- Foot contact detection (MotionBeat 2025) ---
            # Key insight: it's the DECELERATION (high→low speed transition) that
            # marks a beat, not just low speed (which is standing still).
            foot_contact = _detect_foot_contact(
                all_speeds, t, GROUPS["feet"], dt
            )

            # --- Ankle acceleration (continuous version of foot contact) ---
            ankle_accel = np.mean(all_accel[t, GROUPS["feet"]])

            # --- Hand acceleration (note articulation sharpness) ---
            hand_accel = np.mean(all_accel[t, GROUPS["hands"]])

            # --- Jerk magnitude (3rd derivative — "snap" quality) ---
            # jerk = d(accel)/dt, approximated via finite differences on accel
            if t >= 3 and t < num_frames - 3:
                jerk_val = abs(all_accel[t + 1].mean() - all_accel[t - 1].mean()) / (2 * dt)
            else:
                jerk_val = 0.0

            # --- Head bob (vertical oscillation relative to running mean) ---
            head_bob = abs(head_y[t] - head_y_mean[t])

            # --- Body tilt (shoulder line angle from horizontal) ---
            ls = kp[t, COCO["LEFT_SHOULDER"]]
            rs = kp[t, COCO["RIGHT_SHOULDER"]]
            shoulder_dy = rs[1] - ls[1]
            shoulder_dx = max(abs(rs[0] - ls[0]), 0.001)
            body_tilt = abs(np.arctan2(shoulder_dy, shoulder_dx))  # radians, 0=level

            features[t, 7:13] = [
                foot_contact, ankle_accel, hand_accel,
                jerk_val, head_bob, body_tilt,
            ]

    # First and last frames: copy neighbors
    features[0] = features[1]
    features[-1] = features[-2]
    if version >= 2:
        features[1] = features[2]  # frame 1 has no accel data
        features[-2] = features[-3]

    return features, feature_names


def _detect_foot_contact(all_speeds, t, foot_indices, dt):
    """
    Detect foot strike via sharp ankle deceleration (MotionBeat 2025).

    A foot contact occurs when:
    1. Ankle was recently moving (speed > FOOT_CONTACT_SPEED_FLOOR in last N frames)
    2. Ankle speed drops sharply (deceleration > threshold)

    Returns: 1.0 if foot strike detected, 0.0 otherwise
    """
    for idx in foot_indices:
        current_speed = all_speeds[t, idx]

        # Check if foot was recently moving
        lookback = min(t, FOOT_CONTACT_WINDOW)
        if lookback < 1:
            continue

        recent_max = np.max(all_speeds[t - lookback:t, idx])
        if recent_max < FOOT_CONTACT_SPEED_FLOOR:
            continue

        # Check for sharp deceleration
        decel = (recent_max - current_speed) / (lookback * dt)
        if decel > FOOT_CONTACT_DECEL_THRESHOLD:
            return 1.0

    return 0.0


def smooth_features(features, alpha=0.3):
    """
    Apply exponential moving average (same as JS EMA smoothing).

    Args:
        features: (num_frames, 7) array
        alpha: smoothing factor (0-1), same as KinematicsEngine constructor

    Returns:
        smoothed: (num_frames, 7) array
    """
    smoothed = np.zeros_like(features)
    smoothed[0] = features[0]

    for t in range(1, len(features)):
        smoothed[t] = smoothed[t - 1] + alpha * (features[t] - smoothed[t - 1])

    return smoothed


def _normalize_keypoints(keypoints3d):
    """
    Normalize 3D keypoints to 0-1 range per sequence.

    MediaPipe outputs normalized coordinates (0-1 relative to frame).
    AIST++ has absolute meter coordinates. We normalize to match.
    """
    # Use per-sequence bounding box (not per-frame, to preserve motion scale)
    kp = keypoints3d.copy()

    # Flatten to find global bounds
    all_pts = kp.reshape(-1, 3)
    mins = np.percentile(all_pts, 2, axis=0)  # robust to outliers
    maxs = np.percentile(all_pts, 98, axis=0)
    ranges = maxs - mins
    ranges[ranges < 1e-6] = 1.0  # avoid division by zero

    # Normalize to 0-1
    kp = (kp - mins) / ranges

    return kp


if __name__ == "__main__":
    # Quick test with synthetic data
    print("Testing kinematics.py V2 with synthetic data...")
    np.random.seed(42)

    # Simulate 5 seconds of motion at 60fps
    frames = 300
    joints = 17
    t = np.linspace(0, 5, frames)

    # Base pose + sinusoidal hand movement
    kp = np.zeros((frames, joints, 3))
    for j in range(joints):
        kp[:, j, 0] = 0.3 + 0.1 * j / joints  # spread in x
        kp[:, j, 1] = 0.5  # centered in y
        kp[:, j, 2] = 0.0  # flat in z

    # Animate wrists (joints 9, 10) — sinusoidal up/down
    kp[:, COCO["RIGHT_WRIST"], 1] = 0.3 + 0.2 * np.sin(2 * np.pi * t)
    kp[:, COCO["LEFT_WRIST"], 1] = 0.3 + 0.2 * np.sin(2 * np.pi * t + np.pi / 2)

    # Animate hips — subtle bounce
    for hip in [COCO["LEFT_HIP"], COCO["RIGHT_HIP"]]:
        kp[:, hip, 1] = 0.6 + 0.02 * np.sin(4 * np.pi * t)

    # Animate ankles — periodic foot strikes (speed up then stop)
    for ankle in [COCO["LEFT_ANKLE"], COCO["RIGHT_ANKLE"]]:
        # Sawtooth-like: foot moves then plants
        ankle_motion = 0.05 * np.abs(np.sin(2 * np.pi * 2 * t))
        kp[:, ankle, 1] = 0.8 + ankle_motion

    # Animate head — bobbing
    kp[:, COCO["NOSE"], 1] = 0.2 + 0.015 * np.sin(4 * np.pi * t)

    # Animate shoulders — slight tilt
    kp[:, COCO["LEFT_SHOULDER"], 1] = 0.35 + 0.01 * np.sin(2 * np.pi * 0.5 * t)
    kp[:, COCO["RIGHT_SHOULDER"], 1] = 0.35 - 0.01 * np.sin(2 * np.pi * 0.5 * t)
    kp[:, COCO["LEFT_SHOULDER"], 0] = 0.35
    kp[:, COCO["RIGHT_SHOULDER"], 0] = 0.65

    # Test V1 (backward compat)
    features_v1, names_v1 = extract_features(kp, fps=60, version=1)
    print(f"  V1: {features_v1.shape[0]} frames x {features_v1.shape[1]} features")
    assert features_v1.shape[1] == 7, f"V1 should have 7 features, got {features_v1.shape[1]}"

    # Test V2
    features, names = extract_features(kp, fps=60, version=2)
    smoothed = smooth_features(features, alpha=0.3)

    print(f"  V2: {features.shape[0]} frames x {features.shape[1]} features")
    assert features.shape[1] == 13, f"V2 should have 13 features, got {features.shape[1]}"
    print(f"  Feature names: {names}")

    print(f"  Raw ranges:")
    for i, name in enumerate(names):
        print(f"    {name}: [{features[:, i].min():.4f}, {features[:, i].max():.4f}]")

    # Check foot contact fires
    foot_contacts = features[:, names.index("footContact")]
    num_contacts = np.sum(foot_contacts > 0.5)
    print(f"  Foot contacts detected: {num_contacts}")

    # Check new features have non-zero values
    for new_feat in ["ankleAccel", "handAccel", "jerkMagnitude", "headBob", "bodyTilt"]:
        idx = names.index(new_feat)
        maxval = features[:, idx].max()
        print(f"    {new_feat} max: {maxval:.4f} {'OK' if maxval > 0 else 'ZERO!'}")

    print("  PASS")
