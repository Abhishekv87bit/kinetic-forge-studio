"""
audio_features.py — Extract musical features from AIST++ music tracks.

For each music track, extracts frame-aligned features that become
the training targets for our motion→music model:

  - onset_strength: how strong is a note onset at this moment? (0–1)
  - spectral_centroid: brightness/pitch of the sound (Hz, normalized)
  - energy: RMS energy (loudness) of the audio (0–1)
  - beat_phase: position within the current beat (0–1, sawtooth)
  - chroma: 12-bin chromagram (which pitch classes are active)

These get reduced to our model's target space:
  - melody_trigger: onset_strength > threshold
  - melody_pitch: spectral centroid normalized to 0–1
  - melody_velocity: RMS energy normalized to 0–1
  - bass_trigger: low-frequency onset detection
  - bass_pitch: bass spectral centroid normalized
  - bass_velocity: low-frequency energy
  - energy_level: overall RMS energy
"""

import numpy as np

try:
    import librosa
    HAS_LIBROSA = True
except ImportError:
    HAS_LIBROSA = False
    print("WARNING: librosa not installed. Install with: pip install librosa")


def extract_audio_features(audio_path, num_motion_frames, motion_fps=60):
    """
    Extract audio features aligned to motion frame timestamps.

    Args:
        audio_path: path to .wav file
        num_motion_frames: number of motion frames to align to
        motion_fps: motion capture frame rate

    Returns:
        targets: numpy array of shape (num_motion_frames, 7)
                 [melody_trigger, melody_pitch, melody_velocity,
                  bass_trigger, bass_pitch, bass_velocity, energy_level]
        target_names: list of target names
    """
    if not HAS_LIBROSA:
        raise ImportError("librosa required for audio feature extraction")

    # Load audio
    y, sr = librosa.load(str(audio_path), sr=22050)
    duration = len(y) / sr

    # Frame times aligned to motion frames
    frame_times = np.arange(num_motion_frames) / motion_fps

    # Truncate to available audio
    max_time = min(frame_times[-1], duration - 0.1)
    valid_mask = frame_times <= max_time

    # --- Full-spectrum features ---
    hop_length = 512

    # Onset strength (note attacks)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop_length)
    onset_times = librosa.times_like(onset_env, sr=sr, hop_length=hop_length)

    # Spectral centroid (brightness/pitch proxy)
    centroid = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=hop_length)[0]

    # RMS energy
    rms = librosa.feature.rms(y=y, hop_length=hop_length)[0]

    # Beat tracking
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr, hop_length=hop_length)

    # --- Low-frequency features (for bass) ---
    # Isolate bass frequencies (< 250 Hz)
    y_bass = librosa.effects.preemphasis(y, coef=-0.97)  # boost lows
    # Simple low-pass via STFT
    S = librosa.stft(y, hop_length=hop_length)
    freq_bins = librosa.fft_frequencies(sr=sr)
    bass_mask = freq_bins < 250
    S_bass = S.copy()
    S_bass[~bass_mask, :] = 0
    y_bass_reconstructed = librosa.istft(S_bass, hop_length=hop_length)

    # Bass onset and energy
    bass_onset = librosa.onset.onset_strength(
        y=y_bass_reconstructed, sr=sr, hop_length=hop_length
    )
    bass_rms = librosa.feature.rms(y=y_bass_reconstructed, hop_length=hop_length)[0]
    bass_centroid = librosa.feature.spectral_centroid(
        y=y_bass_reconstructed, sr=sr, hop_length=hop_length
    )[0]

    # --- Normalize features ---
    def normalize(arr):
        mn, mx = arr.min(), arr.max()
        if mx - mn < 1e-8:
            return np.zeros_like(arr)
        return (arr - mn) / (mx - mn)

    onset_norm = normalize(onset_env)
    centroid_norm = normalize(centroid)
    rms_norm = normalize(rms)
    bass_onset_norm = normalize(bass_onset)
    bass_centroid_norm = normalize(bass_centroid)
    bass_rms_norm = normalize(bass_rms)

    # --- Interpolate to motion frame rate ---
    audio_times = librosa.times_like(onset_env, sr=sr, hop_length=hop_length)

    def interp_to_frames(feature, feature_times):
        return np.interp(frame_times, feature_times, feature)

    melody_onset = interp_to_frames(onset_norm, audio_times)
    melody_pitch = interp_to_frames(centroid_norm, audio_times)
    melody_vel = interp_to_frames(rms_norm, audio_times)
    bass_onset_interp = interp_to_frames(bass_onset_norm, audio_times)
    bass_pitch_interp = interp_to_frames(bass_centroid_norm, audio_times)
    bass_vel = interp_to_frames(bass_rms_norm, audio_times)
    energy = interp_to_frames(rms_norm, audio_times)

    # --- Convert onsets to binary triggers ---
    # Use adaptive threshold: onset > mean + 1 std
    melody_threshold = melody_onset.mean() + melody_onset.std()
    melody_trigger = (melody_onset > melody_threshold).astype(float)

    bass_threshold = bass_onset_interp.mean() + bass_onset_interp.std()
    bass_trigger = (bass_onset_interp > bass_threshold).astype(float)

    # --- Assemble targets ---
    targets = np.stack([
        melody_trigger,
        melody_pitch,
        melody_vel,
        bass_trigger,
        bass_pitch_interp,
        bass_vel,
        energy,
    ], axis=1)

    target_names = [
        "melody_trigger", "melody_pitch", "melody_velocity",
        "bass_trigger", "bass_pitch", "bass_velocity",
        "energy_level",
    ]

    return targets, target_names


if __name__ == "__main__":
    print("Testing audio_features.py...")

    if not HAS_LIBROSA:
        print("  SKIP: librosa not installed")
        print("  Install with: pip install librosa soundfile")
    else:
        # Generate a synthetic test signal
        sr = 22050
        duration = 5.0
        t = np.linspace(0, duration, int(sr * duration))

        # Melody: 440Hz sine with amplitude envelope
        melody = 0.3 * np.sin(2 * np.pi * 440 * t) * (1 + 0.5 * np.sin(2 * np.pi * 2 * t))
        # Bass: 80Hz sine with beat-like envelope
        bass = 0.4 * np.sin(2 * np.pi * 80 * t) * np.maximum(0, np.sin(2 * np.pi * 1 * t))
        y = melody + bass

        # Save temp file
        import soundfile as sf
        import tempfile
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        sf.write(tmp.name, y, sr)

        # Extract features
        targets, names = extract_audio_features(tmp.name, num_motion_frames=300, motion_fps=60)

        print(f"  Extracted {targets.shape[0]} frames × {targets.shape[1]} targets")
        print(f"  Target names: {names}")
        for i, name in enumerate(names):
            col = targets[:, i]
            print(f"    {name}: mean={col.mean():.3f}, std={col.std():.3f}, "
                  f"range=[{col.min():.3f}, {col.max():.3f}]")

        import os
        os.unlink(tmp.name)
        print("  PASS")
