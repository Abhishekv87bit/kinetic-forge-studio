# Single Wave Mechanism - Design Phase

## Goal
One slider-crank mechanism that ACTUALLY works - every part physically connected.

## Mechanism: Slider-Crank

```
Motor Shaft (fixed position)
    │
    ▼
Crank Disc (rotates with shaft)
    │
    ● ← Crank Pin (offset 15mm from center)
    │
Coupler Rod (60mm, connects pin to slider)
    │
    ▼
Slider (constrained to vertical motion)
    │
Wave Piece (attached to slider)
```

## Parts List

| # | Part | Dimensions | Material | Connects To |
|---|------|------------|----------|-------------|
| 1 | Frame | 200×100×50mm | PLA | Base |
| 2 | Back Panel | 200×100×3mm | PLA | Frame |
| 3 | Motor | N20 gearmotor | Metal | Back Panel |
| 4 | Crank Disc | ø40×5mm | PETG | Motor shaft |
| 5 | Crank Pin | ø4×10mm | Steel | Crank (r=15mm offset) |
| 6 | Coupler | 60×8×3mm | PETG | Pin + Slider |
| 7 | Slider | 80×40×10mm | PLA | Coupler + Rails |
| 8 | Rails | 2× 5×5×40mm | PLA | Frame |

## Key Dimensions

- Frame: 200mm wide × 100mm tall × 50mm deep
- Motor position: X=100mm (center), Z=30mm (low)
- Crank radius: 15mm
- Coupler length: 60mm
- Slider travel: ~30mm (2× crank radius)

## Connection Rules

1. **Motor shaft** is the ONLY fixed reference point
2. **Crank pin** position = motor_pos + 15mm × (cos(θ), sin(θ))
3. **Slider Z** = calculated from slider-crank kinematics
4. **Wave** = attached rigidly to slider

## Why This Will Work

Unlike previous designs:
- NO separate translate() calls with independent coordinates
- Every part position DERIVES from the motor shaft
- Coupler rod endpoints literally connect pin to slider
- ~100 lines of code, not 2400
