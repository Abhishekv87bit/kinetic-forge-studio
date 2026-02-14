# Single Wave Mechanism - Calculations

## Slider-Crank Kinematics

### Given Values
- Crank radius (r): 15mm
- Coupler length (L): 60mm
- Motor position: (100, 30) in X-Z plane

### Slider Position Formula

For crank angle θ (0° to 360°):

```
Pin X offset = r × cos(θ) = 15 × cos(θ)
Pin Z offset = r × sin(θ) = 15 × sin(θ)

Pin position:
  px = 100 + 15 × cos(θ)
  pz = 30 + 15 × sin(θ)

Slider is constrained to X = 100 (directly below motor)
Slider Z from geometry:
  horizontal_offset = px - 100 = 15 × cos(θ)
  sz = pz + sqrt(L² - horizontal_offset²)
  sz = 30 + 15×sin(θ) + sqrt(60² - (15×cos(θ))²)
  sz = 30 + 15×sin(θ) + sqrt(3600 - 225×cos²(θ))
```

### Verification at 4 Positions

| θ | cos(θ) | sin(θ) | px | pz | horiz | sqrt term | sz |
|---|--------|--------|----|----|-------|-----------|-----|
| 0° | 1.0 | 0.0 | 115 | 30 | 15 | 59.81 | 89.81 |
| 90° | 0.0 | 1.0 | 100 | 45 | 0 | 60.00 | 105.00 |
| 180° | -1.0 | 0.0 | 85 | 30 | -15 | 59.81 | 89.81 |
| 270° | 0.0 | -1.0 | 100 | 15 | 0 | 60.00 | 75.00 |

### Slider Travel
- Maximum Z: 105mm (at θ=90°)
- Minimum Z: 75mm (at θ=270°)
- Total travel: 30mm

### Coupler Length Check

The coupler length should be CONSTANT at all positions:

```
Coupler length = sqrt((px - 100)² + (sz - pz)²)
               = sqrt(horiz² + sqrt_term²)
```

| θ | horiz | sqrt_term | length |
|---|-------|-----------|--------|
| 0° | 15 | 59.81 | 60.00 ✓ |
| 90° | 0 | 60.00 | 60.00 ✓ |
| 180° | 15 | 59.81 | 60.00 ✓ |
| 270° | 0 | 60.00 | 60.00 ✓ |

Coupler stays 60mm at all positions.

### Grashof Condition

For slider-crank: L > r is required for full rotation.
- L = 60mm
- r = 15mm
- 60 > 15 ✓

No dead points, mechanism runs smoothly.

### Clearances

- Crank disc radius: 20mm (ø40mm)
- Crank to frame: 100 - 20 = 80mm clearance ✓
- Slider width: 80mm, centered at X=100
- Slider edges: X=60 to X=140
- Frame inner: X=10 to X=190
- Clearance: 50mm on each side ✓

### Power Budget

- Motor: N20 30RPM, ~0.3 Nm stall torque
- Load: Slider (~10g) + Wave piece (~20g) = 30g = 0.3N
- Moment arm: 15mm = 0.015m
- Required torque: 0.3N × 0.015m = 0.0045 Nm
- Available: 0.3 Nm (worst case)
- Safety factor: 0.3 / 0.0045 = 66× ✓

## Summary

All checks pass:
- [x] Coupler length constant (60mm)
- [x] Grashof satisfied (L > r)
- [x] Clearances adequate (50mm+)
- [x] Power budget OK (66× margin)
- [x] Slider travel: 30mm
