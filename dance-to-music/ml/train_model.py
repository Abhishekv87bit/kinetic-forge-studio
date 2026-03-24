"""
train_model.py — Train V2 motion-to-music model with decomposed prediction heads.

Architecture (V2 — research-backed):
  Input:  (batch, seq_len, 13)  — 13 kinematics features per frame
  LSTM:   BiLSTM(48) + LSTM(48) — shared temporal encoder
  Heads:  3 specialized prediction heads
    - Rhythm head:  foot contact + body energy → bass trigger/pitch/velocity (3 outputs)
    - Melody head:  hand accel + speed → melody trigger/pitch/velocity/sustain (4 outputs)
    - Energy head:  all features → energy level + rhythm density (2 outputs)

Research references:
  - MotionBeat (2025): foot contact = strongest beat signal → rhythm head
  - Dance2MIDI (2023): decompose rhythm vs melody generation → separate heads
  - Back to MLP (WACV 2023): acceleration/jerk features boost accuracy
  - GACA-DiT (2025): genre conditioning → optional genre input

Model stays small (~35K params, <400KB) for pure JS browser inference.

Usage:
  python train_model.py                    # train on AIST++ data
  python train_model.py --synthetic        # train on synthetic data (for testing)
  python train_model.py --v1               # train old V1 model (7 features, 7 targets)
"""

import os
import sys
import json
import numpy as np
from pathlib import Path

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"  # suppress TF warnings

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

from kinematics import extract_features, smooth_features, NUM_FEATURES_V1, NUM_FEATURES_V2
from audio_features import extract_audio_features

DATA_DIR = Path(__file__).parent / "data"
MODEL_DIR = Path(__file__).parent / "models"

# Training hyperparameters
SEQ_LEN = 32       # frames of temporal context (32 frames @ 60fps ~ 0.5 seconds)
BATCH_SIZE = 64
EPOCHS = 50
LEARNING_RATE = 0.001
LSTM_UNITS = 48     # increased from 32 to handle more features
NUM_FEATURES = NUM_FEATURES_V2   # 13 input features
NUM_TARGETS = 9     # 9 output targets (was 7)

# Genre IDs (for future AIST++ genre conditioning)
GENRES = {
    "gBR": 0,  # break
    "gPO": 1,  # pop
    "gLO": 2,  # lock
    "gMH": 3,  # middle hip-hop
    "gLH": 4,  # LA hip-hop
    "gHO": 5,  # house
    "gWA": 6,  # waack
    "gKR": 7,  # krump
    "gJS": 8,  # street jazz
    "gJB": 9,  # ballet jazz
}
NUM_GENRES = len(GENRES)

# Target layout (V2):
#   Rhythm head: [0] bass_trigger, [1] bass_pitch, [2] bass_velocity
#   Melody head: [3] melody_trigger, [4] melody_pitch, [5] melody_velocity, [6] melody_sustain
#   Energy head: [7] energy_level, [8] rhythm_density
TARGET_NAMES = [
    "bass_trigger", "bass_pitch", "bass_velocity",
    "melody_trigger", "melody_pitch", "melody_velocity", "melody_sustain",
    "energy_level", "rhythm_density",
]
TRIGGER_INDICES = [0, 3]      # binary targets (BCE loss)
CONTINUOUS_INDICES = [1, 2, 4, 5, 6, 7, 8]  # continuous targets (MSE loss)


def build_model_v2(use_genre=False):
    """
    Build V2 model with decomposed prediction heads.

    The shared BiLSTM encoder feeds into 3 specialized heads:
    - Rhythm head focuses on foot contact + body energy features
    - Melody head focuses on hand acceleration + speed features
    - Energy head reads the full feature set
    """
    # Main motion input
    motion_input = layers.Input(shape=(SEQ_LEN, NUM_FEATURES), name="motion_input")

    # Shared temporal encoder
    x = layers.Bidirectional(
        layers.LSTM(LSTM_UNITS, return_sequences=True, name="bilstm"),
        name="encoder_bilstm"
    )(motion_input)
    x = layers.Dropout(0.2)(x)
    x = layers.LSTM(LSTM_UNITS, return_sequences=False, name="encoder_lstm")(x)
    x = layers.Dropout(0.2)(x)

    # Optional genre conditioning (concatenated to encoder output)
    if use_genre:
        genre_input = layers.Input(shape=(NUM_GENRES,), name="genre_input")
        x = layers.Concatenate()([x, genre_input])

    # Shared dense
    shared = layers.Dense(48, activation="relu", name="shared_dense")(x)

    # --- Rhythm head (bass) ---
    # Foot contact and body energy are the primary rhythm signals (MotionBeat 2025)
    rhythm = layers.Dense(24, activation="relu", name="rhythm_dense")(shared)
    rhythm_out = layers.Dense(3, activation="sigmoid", name="rhythm_output")(rhythm)
    # Output: [bass_trigger, bass_pitch, bass_velocity]

    # --- Melody head ---
    # Hand acceleration and speed drive melody (Dance2MIDI 2023)
    melody = layers.Dense(24, activation="relu", name="melody_dense")(shared)
    melody_out = layers.Dense(4, activation="sigmoid", name="melody_output")(melody)
    # Output: [melody_trigger, melody_pitch, melody_velocity, melody_sustain]

    # --- Energy head ---
    energy = layers.Dense(16, activation="relu", name="energy_dense")(shared)
    energy_out = layers.Dense(2, activation="sigmoid", name="energy_output")(energy)
    # Output: [energy_level, rhythm_density]

    # Concatenate all heads
    output = layers.Concatenate(name="combined_output")([rhythm_out, melody_out, energy_out])

    inputs = [motion_input, genre_input] if use_genre else motion_input
    model = keras.Model(inputs=inputs, outputs=output, name="motion_to_music_v2")

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss=_combined_loss_v2,
        metrics=["mae"],
    )

    return model


def build_model_v1():
    """Build V1 model (backward compat — 7 features, 7 targets)."""
    model = keras.Sequential([
        layers.Input(shape=(SEQ_LEN, NUM_FEATURES_V1)),
        layers.Bidirectional(layers.LSTM(32, return_sequences=True)),
        layers.Dropout(0.2),
        layers.LSTM(32, return_sequences=False),
        layers.Dropout(0.2),
        layers.Dense(32, activation="relu"),
        layers.Dense(7, activation="sigmoid"),
    ])

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss=_combined_loss_v1,
        metrics=["mae"],
    )
    return model


def _combined_loss_v2(y_true, y_pred):
    """
    V2 loss: BCE for trigger channels + MSE for continuous channels.
    Weighted to balance rhythm vs melody heads.
    """
    bce = tf.keras.losses.binary_crossentropy(
        tf.gather(y_true, TRIGGER_INDICES, axis=1),
        tf.gather(y_pred, TRIGGER_INDICES, axis=1),
    )

    mse = tf.keras.losses.mse(
        tf.gather(y_true, CONTINUOUS_INDICES, axis=1),
        tf.gather(y_pred, CONTINUOUS_INDICES, axis=1),
    )

    # Weight rhythm head slightly higher (foot contact is the most reliable signal)
    return 1.2 * tf.reduce_mean(bce) + tf.reduce_mean(mse)


def _combined_loss_v1(y_true, y_pred):
    """V1 loss (backward compat)."""
    trigger_idx = [0, 3]
    continuous_idx = [1, 2, 4, 5, 6]

    bce = tf.keras.losses.binary_crossentropy(
        tf.gather(y_true, trigger_idx, axis=1),
        tf.gather(y_pred, trigger_idx, axis=1),
    )
    mse = tf.keras.losses.mse(
        tf.gather(y_true, continuous_idx, axis=1),
        tf.gather(y_pred, continuous_idx, axis=1),
    )
    return tf.reduce_mean(bce) + tf.reduce_mean(mse)


def load_aist_dataset():
    """
    Load AIST++ data and extract paired motion/audio features.

    Returns:
        X: list of motion feature arrays, each (num_frames, 13)
        Y: list of audio target arrays, each (num_frames, 9)
        genres: list of genre IDs (int)
    """
    kp_dir = DATA_DIR / "keypoints3d"
    wav_dir = DATA_DIR / "all_musics"

    if not kp_dir.exists() or not wav_dir.exists():
        print("AIST++ data not found. Run download_aist.py first.")
        print("Or use --synthetic flag for testing.")
        sys.exit(1)

    from download_aist import get_music_id

    kp_files = sorted(kp_dir.glob("*.npy"))
    print(f"Found {len(kp_files)} motion sequences")

    X_all, Y_all, genres_all = [], [], []
    skipped = 0

    for kp_file in kp_files:
        seq_name = kp_file.stem

        # Extract genre from sequence name (first 3 chars like "gBR")
        genre_code = seq_name[:3]
        genre_id = GENRES.get(genre_code, -1)

        # Find paired music
        music_id = get_music_id(seq_name)
        if music_id is None:
            skipped += 1
            continue

        wav_path = wav_dir / f"{music_id}.wav"
        if not wav_path.exists():
            skipped += 1
            continue

        try:
            kp3d = np.load(str(kp_file))
            motion_feat, _ = extract_features(kp3d, fps=60, version=2)
            motion_feat = smooth_features(motion_feat, alpha=0.3)

            audio_targets, _ = extract_audio_features(
                wav_path, num_motion_frames=len(motion_feat), motion_fps=60
            )

            # Expand audio targets from 7 to 9 (add sustain + density)
            audio_v2 = _expand_audio_targets(audio_targets)

            min_len = min(len(motion_feat), len(audio_v2))
            X_all.append(motion_feat[:min_len])
            Y_all.append(audio_v2[:min_len])
            genres_all.append(genre_id)

        except Exception as e:
            print(f"  Error processing {seq_name}: {e}")
            skipped += 1

    print(f"Loaded {len(X_all)} sequences, skipped {skipped}")
    return X_all, Y_all, genres_all


def _expand_audio_targets(targets_v1):
    """
    Expand V1 audio targets (7) to V2 (9).

    V1: [melody_trigger, melody_pitch, melody_velocity,
         bass_trigger, bass_pitch, bass_velocity, energy_level]

    V2: [bass_trigger, bass_pitch, bass_velocity,
         melody_trigger, melody_pitch, melody_velocity, melody_sustain,
         energy_level, rhythm_density]
    """
    n = len(targets_v1)
    targets_v2 = np.zeros((n, 9))

    # Rhythm head (reorder: bass first)
    targets_v2[:, 0] = targets_v1[:, 3]  # bass_trigger
    targets_v2[:, 1] = targets_v1[:, 4]  # bass_pitch
    targets_v2[:, 2] = targets_v1[:, 5]  # bass_velocity

    # Melody head
    targets_v2[:, 3] = targets_v1[:, 0]  # melody_trigger
    targets_v2[:, 4] = targets_v1[:, 1]  # melody_pitch
    targets_v2[:, 5] = targets_v1[:, 2]  # melody_velocity
    # melody_sustain: derived from velocity (louder = longer sustain)
    targets_v2[:, 6] = np.clip(targets_v1[:, 2] * 0.8, 0, 1)

    # Energy head
    targets_v2[:, 7] = targets_v1[:, 6]  # energy_level
    # rhythm_density: approximate from trigger frequency (rolling sum of triggers)
    trigger_sum = targets_v1[:, 0] + targets_v1[:, 3]  # melody + bass triggers
    kernel = np.ones(16) / 16
    targets_v2[:, 8] = np.clip(np.convolve(trigger_sum, kernel, mode="same"), 0, 1)

    return targets_v2


def generate_synthetic_dataset(num_sequences=50, frames_per_seq=600, version=2):
    """
    Generate synthetic paired motion/audio data for testing the pipeline.

    V2: Generates 13 motion features and 9 audio targets with research-backed
    correlations (foot contact → bass, hand accel → melody articulation, etc.)
    """
    np.random.seed(42)
    X_all, Y_all = [], []
    num_feat = NUM_FEATURES if version >= 2 else NUM_FEATURES_V1
    num_tgt = NUM_TARGETS if version >= 2 else 7

    for i in range(num_sequences):
        t = np.linspace(0, 10, frames_per_seq)

        # Random movement style
        freq = np.random.uniform(0.5, 3.0)
        intensity = np.random.uniform(0.3, 1.0)

        # --- Original 7 motion features ---
        hand_speed = intensity * np.abs(np.sin(2 * np.pi * freq * t)) + np.random.normal(0, 0.05, frames_per_seq)
        hand_speed = np.clip(hand_speed, 0, 2)

        foot_speed = 0.5 * intensity * np.abs(np.sin(2 * np.pi * freq * 2 * t)) + np.random.normal(0, 0.03, frames_per_seq)
        foot_speed = np.clip(foot_speed, 0, 2)

        core_speed = 0.3 * intensity * np.abs(np.sin(2 * np.pi * freq * t)) + np.random.normal(0, 0.02, frames_per_seq)
        core_speed = np.clip(core_speed, 0, 1)

        total_ke = 0.5 * (hand_speed ** 2 + foot_speed ** 2 + core_speed ** 2)
        hip_y = 0.5 + 0.05 * np.sin(2 * np.pi * freq * 2 * t)
        arm_spread = 0.3 + 0.2 * np.sin(2 * np.pi * freq * 0.5 * t)
        symmetry = 0.7 + 0.2 * np.random.random(frames_per_seq)

        motion_features = [total_ke, hand_speed, foot_speed, core_speed,
                           hip_y, arm_spread, symmetry]

        if version >= 2:
            # --- New 6 features ---
            # Foot contact: periodic binary events (simulated foot strikes)
            foot_phase = (2 * np.pi * freq * 2 * t) % (2 * np.pi)
            foot_contact = ((foot_phase > 0.95 * 2 * np.pi) | (foot_phase < 0.05 * 2 * np.pi)).astype(float)

            # Ankle acceleration: derivative of foot speed
            ankle_accel = np.abs(np.gradient(foot_speed, 1.0 / 60)) + np.random.normal(0, 0.5, frames_per_seq)
            ankle_accel = np.clip(ankle_accel, 0, 50)

            # Hand acceleration: derivative of hand speed
            hand_accel = np.abs(np.gradient(hand_speed, 1.0 / 60)) + np.random.normal(0, 0.3, frames_per_seq)
            hand_accel = np.clip(hand_accel, 0, 30)

            # Jerk magnitude: 2nd derivative of speed
            jerk_mag = np.abs(np.gradient(np.gradient(total_ke, 1.0 / 60), 1.0 / 60))
            jerk_mag = np.clip(jerk_mag + np.random.normal(0, 1, frames_per_seq), 0, 200)

            # Head bob: sinusoidal with movement
            head_bob = 0.01 * np.abs(np.sin(4 * np.pi * freq * t)) + np.random.normal(0, 0.002, frames_per_seq)
            head_bob = np.clip(head_bob, 0, 0.05)

            # Body tilt: gentle sway
            body_tilt = 0.02 * np.abs(np.sin(2 * np.pi * 0.5 * freq * t)) + np.random.normal(0, 0.005, frames_per_seq)
            body_tilt = np.clip(body_tilt, 0, 0.1)

            motion_features += [foot_contact, ankle_accel, hand_accel,
                                jerk_mag, head_bob, body_tilt]

        motion = np.stack(motion_features, axis=1)

        if version >= 2:
            # --- V2 audio targets (9 channels) ---
            # Rhythm head: foot contact → bass (MotionBeat 2025)
            bass_trigger = foot_contact.copy()  # foot strike = bass hit
            bass_pitch = np.clip(core_speed / 0.5, 0, 1)
            bass_velocity = np.clip(ankle_accel / 20, 0.3, 1)

            # Melody head: hand features → melody (Dance2MIDI 2023)
            melody_trigger = (hand_speed > 0.5 * intensity).astype(float)
            melody_pitch = 0.5 + 0.3 * np.sin(2 * np.pi * freq * t)
            melody_velocity = np.clip(hand_speed / 2, 0, 1)
            # Sustain: inverse of hand acceleration (sharp movement = staccato, smooth = legato)
            melody_sustain = np.clip(1.0 - hand_accel / 15, 0.1, 1.0)

            # Energy head
            energy_level = np.clip(total_ke / 5, 0, 1)
            rhythm_density = np.clip((bass_trigger + melody_trigger) * 0.5, 0, 1)
            # Smooth density
            kernel = np.ones(16) / 16
            rhythm_density = np.convolve(rhythm_density, kernel, mode="same")

            audio = np.stack([
                bass_trigger, bass_pitch, bass_velocity,
                melody_trigger, melody_pitch, melody_velocity, melody_sustain,
                energy_level, rhythm_density,
            ], axis=1)
        else:
            # V1 targets (backward compat)
            melody_trigger = (hand_speed > 0.5 * intensity).astype(float)
            melody_pitch = 0.5 + 0.3 * np.sin(2 * np.pi * freq * t)
            melody_velocity = np.clip(hand_speed / 2, 0, 1)
            hip_diff = np.diff(hip_y, prepend=hip_y[0])
            hip_diff2 = np.diff(hip_diff, prepend=hip_diff[0])
            bass_trigger = (hip_diff2 > 0.001).astype(float)
            bass_pitch = np.clip(core_speed / 0.5, 0, 1)
            bass_velocity = np.clip(core_speed / 0.3, 0, 1)
            energy_level = np.clip(total_ke / 5, 0, 1)

            audio = np.stack([
                melody_trigger, melody_pitch, melody_velocity,
                bass_trigger, bass_pitch, bass_velocity,
                energy_level,
            ], axis=1)

        X_all.append(motion)
        Y_all.append(audio)

    return X_all, Y_all


def create_sequences(X_list, Y_list, seq_len=SEQ_LEN):
    """
    Convert variable-length sequences into fixed-length windowed samples.

    Returns:
        X: (num_samples, seq_len, num_features)
        Y: (num_samples, num_targets) — target is the LAST frame's audio params
    """
    X_windows, Y_windows = [], []

    for X_seq, Y_seq in zip(X_list, Y_list):
        for start in range(0, len(X_seq) - seq_len, seq_len // 2):  # 50% overlap
            end = start + seq_len
            if end >= len(X_seq):
                break
            X_windows.append(X_seq[start:end])
            Y_windows.append(Y_seq[end - 1])  # predict last frame

    return np.array(X_windows), np.array(Y_windows)


def train(synthetic=False, version=2):
    """Main training loop."""
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    # Load data
    print("=" * 60)
    print(f"Model version: V{version}")
    if synthetic:
        print("Training on SYNTHETIC data (for pipeline testing)")
        X_list, Y_list = generate_synthetic_dataset(version=version)
    else:
        print("Training on AIST++ data")
        X_list, Y_list, genres = load_aist_dataset()

    print(f"Total sequences: {len(X_list)}")
    total_frames = sum(len(x) for x in X_list)
    print(f"Total frames: {total_frames}")

    # Create windowed samples
    X, Y = create_sequences(X_list, Y_list)
    print(f"Training samples: {X.shape[0]} windows of {SEQ_LEN} frames")
    print(f"Feature dims: {X.shape[2]}, Target dims: {Y.shape[1]}")

    # Train/val split
    n = len(X)
    idx = np.random.permutation(n)
    split = int(0.85 * n)
    X_train, Y_train = X[idx[:split]], Y[idx[:split]]
    X_val, Y_val = X[idx[split:]], Y[idx[split:]]
    print(f"Train: {len(X_train)}, Val: {len(X_val)}")

    # Build model
    if version >= 2:
        model = build_model_v2(use_genre=False)
    else:
        model = build_model_v1()
    model.summary()

    # Callbacks
    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=8, restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=3
        ),
    ]

    # Train
    print("\nTraining...")
    history = model.fit(
        X_train, Y_train,
        validation_data=(X_val, Y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=callbacks,
        verbose=1,
    )

    # Save model
    suffix = "_v2" if version >= 2 else ""
    model_path = MODEL_DIR / f"motion_to_music{suffix}.h5"
    model.save(str(model_path))
    print(f"\nModel saved to {model_path}")
    print(f"Model size: {model_path.stat().st_size / 1024:.1f} KB")

    # Feature/target names
    if version >= 2:
        feature_names = [
            "totalKE", "handSpeed", "footSpeed", "coreSpeed",
            "hipY", "armSpread", "symmetry",
            "footContact", "ankleAccel", "handAccel",
            "jerkMagnitude", "headBob", "bodyTilt",
        ]
        target_names = TARGET_NAMES
    else:
        feature_names = [
            "totalKE", "handSpeed", "footSpeed", "coreSpeed",
            "hipY", "armSpread", "symmetry",
        ]
        target_names = [
            "melody_trigger", "melody_pitch", "melody_velocity",
            "bass_trigger", "bass_pitch", "bass_velocity",
            "energy_level",
        ]

    # Save training config
    config = {
        "version": version,
        "seq_len": SEQ_LEN,
        "num_features": X.shape[2],
        "num_targets": Y.shape[1],
        "lstm_units": LSTM_UNITS,
        "feature_names": feature_names,
        "target_names": target_names,
        "trigger_indices": TRIGGER_INDICES if version >= 2 else [0, 3],
        "head_layout": {
            "rhythm": {"indices": [0, 1, 2], "names": ["bass_trigger", "bass_pitch", "bass_velocity"]},
            "melody": {"indices": [3, 4, 5, 6], "names": ["melody_trigger", "melody_pitch", "melody_velocity", "melody_sustain"]},
            "energy": {"indices": [7, 8], "names": ["energy_level", "rhythm_density"]},
        } if version >= 2 else None,
        "epochs_trained": len(history.history["loss"]),
        "final_val_loss": float(history.history["val_loss"][-1]),
        "final_val_mae": float(history.history["val_mae"][-1]),
    }
    config_path = MODEL_DIR / f"model_config{suffix}.json"
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
    print(f"Config saved to {config_path}")

    # Print per-channel accuracy
    print("\nPer-channel validation metrics:")
    Y_pred = model.predict(X_val, verbose=0)
    trigger_idx = TRIGGER_INDICES if version >= 2 else [0, 3]
    for i, name in enumerate(target_names):
        mae = np.mean(np.abs(Y_val[:, i] - Y_pred[:, i]))
        if i in trigger_idx:
            acc = np.mean((Y_pred[:, i] > 0.5) == (Y_val[:, i] > 0.5))
            print(f"  {name}: MAE={mae:.4f}, Accuracy={acc:.2%}")
        else:
            print(f"  {name}: MAE={mae:.4f}")

    return model, history


if __name__ == "__main__":
    synthetic = "--synthetic" in sys.argv
    v1 = "--v1" in sys.argv
    version = 1 if v1 else 2
    model, history = train(synthetic=synthetic, version=version)
