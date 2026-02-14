# Zone 2 Foam Gear - Geometry Checklist

## Reference Point
- **Origin**: Gear shaft center at local (0, 0, 0)
- **Z=0**: Bottom of base plate

## Parts List with Dimensions

| Part | Dimensions | Position (relative to origin) |
|------|------------|-------------------------------|
| 1. Test base plate | 40 x 40 x 5 mm | Center at (0, 0, 2.5) |
| 2. 12T Gear | pitch_r=6mm, OD=14.4mm, thickness=5mm, shaft_hole=3.3mm | Center at (0, 0, 10.5) |
| 3. Shaft | diameter=3mm, height=15mm | (0, 0, 5) to (0, 0, 20) |
| 4. Foam arm | 15mm length, 4mm wide, 3mm thick | From (0, 0, 13) extending radially |
| 5. Foam piece MEDIUM | ~12mm diameter sphere | At (15, 0, 13) when angle=0 |

## Gear Parameters
- Teeth: 12
- Module: 1.0 (assumed standard)
- Pitch radius: 6mm (teeth * module / 2 = 12 * 1.0 / 2 = 6mm)
- Outer diameter: 14.4mm (pitch_d + 2*module = 12 + 2.4)
- Shaft hole: 3.3mm (3mm shaft + 0.3mm clearance)
- Thickness: 5mm

## Connection Verification

| Connection | Part A | Part B | Gap | Status |
|------------|--------|--------|-----|--------|
| Base to shaft | Base plate top (Z=5) | Shaft bottom (Z=5) | 0mm | [x] PASS |
| Shaft to gear | Shaft passes through gear (Z=8 to Z=13) | Gear bore (3.3mm) | 0.15mm clearance | [x] PASS |
| Gear to arm | Gear top (Z=13) | Arm bottom (Z=13) | 0mm | [x] PASS |
| Arm to foam | Arm end at r=15mm | Foam center at r=15mm | 0mm | [x] PASS |

## Collision Check at 4 Positions

| Angle | Foam Position | Collision with Base? | Collision with Shaft? | Status |
|-------|---------------|----------------------|----------------------|--------|
| 0° | (15, 0, 13) | No - foam at Z=13, base top at Z=5 | No - 15mm away | [x] PASS |
| 90° | (0, 15, 13) | No - foam at Z=13, base top at Z=5 | No - 15mm away | [x] PASS |
| 180° | (-15, 0, 13) | No - foam at Z=13, base top at Z=5 | No - 15mm away | [x] PASS |
| 270° | (0, -15, 13) | No - foam at Z=13, base top at Z=5 | No - 15mm away | [x] PASS |

## Arm Length Verification
- Arm length: 15mm (constant, rigid part)
- Foam orbit radius: 15mm (constant)
- [x] PASS - Rigid arm, no length change

## Clearances
- Shaft to gear bore: 3.3mm - 3.0mm = 0.3mm clearance [x] PASS
- Foam to base: 13mm - 5mm = 8mm gap (foam bottom at ~7mm) [x] PASS
- Foam to shaft: 15mm - 1.5mm = 13.5mm (foam edge to shaft edge) [x] PASS

## Final Checklist
- [x] All parts have defined dimensions
- [x] All connections verified (gap = 0 where needed)
- [x] All clearances >= 0.3mm for moving parts
- [x] No collisions at any rotation angle
- [x] Arm length is constant (rigid body)

## GEOMETRY STATUS: ALL PASS - READY FOR CODE
