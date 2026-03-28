# Dance-to-Music ML Pipeline

## Architecture

```
AIST++ Data (offline)                    Browser (real-time)
┌─────────────────────┐                  ┌─────────────────────────┐
│ keypoints3d (17j)   │                  │ MediaPipe (33 landmarks)│
│        ↓            │                  │        ↓                │
│ kinematics.py       │                  │ kinematics.js           │
│ (same features)     │                  │ (same features)         │
│        ↓            │                  │        ↓                │
│ music audio (wav)   │                  │ ┌───────────────────┐   │
│        ↓            │   export tfjs    │ │ ML Mapper (tfjs)  │   │
│ audio_features.py   │ ──────────────→  │ │ OR                │   │
│        ↓            │                  │ │ Rule-based Mapper │   │
│ train_model.py      │                  │ └───────────────────┘   │
│ (motion→music)      │                  │        ↓                │
└─────────────────────┘                  │ Tone.js → speakers      │
                                         └─────────────────────────┘
```

## Feature Alignment

Both JS (browser) and Python (training) compute the same 7 features:
1. totalKE — total kinetic energy
2. handSpeed — average wrist speed
3. footSpeed — average ankle speed
4. coreSpeed — average core (hips+shoulders) speed
5. hipY — hip midpoint vertical position
6. armSpread — wrist-to-wrist distance
7. symmetry — left/right speed balance

## Model Output

The model predicts musical parameters per frame:
- melody_trigger (0/1) — should a melody note play?
- melody_pitch (0–1) — maps to scale degree
- melody_velocity (0–1) — loudness
- bass_trigger (0/1) — should a bass note play?
- bass_pitch (0–1) — maps to bass scale degree
- bass_velocity (0–1) — loudness
- energy_level (0–1) — overall musical energy

## Requirements

```
pip install numpy librosa tensorflow soundfile
```
