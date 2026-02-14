# Zone 1 Foam Gear - Geometry Checklist

## Reference Point
- **Origin**: Gear shaft center at local (0, 0, 0)
- **Z-orientation**: Gear sits on XY plane, shaft extends in +Z

## Parts List

| Part | Dimensions | Material |
|------|------------|----------|
| 1. Test Base Plate | 40mm x 40mm x 3mm | PLA (gray) |
| 2. 12T Gear | pitch_r=6mm, OD~13.2mm, thickness=5mm, shaft_hole=3.3mm | PLA (gold) |
| 3. Shaft | diameter=3mm, length=15mm | PLA or metal rod |
| 4. Foam Arm | length=12mm, width=4mm, thickness=3mm | PLA (blue) |
| 5. Foam Piece | ~8mm diameter organic blob | PLA (white) |

## Detailed Dimensions

### Gear (12T)
- Teeth: 12
- Module: 1.0 (standard)
- Pitch radius: 6mm (module × teeth / 2)
- Addendum: 1.0mm
- Dedendum: 1.25mm
- Outer diameter: 6 + 1.0 = 7.0mm (tip radius)
- Root diameter: 6 - 1.25 = 4.75mm
- Thickness: 5mm
- Shaft hole: 3.3mm (0.3mm clearance for 3mm shaft)

### Shaft
- Diameter: 3mm
- Length: 15mm (extends through base + gear + arm attachment)
- Base insert depth: 3mm
- Above base: 12mm

### Foam Arm
- Attached to gear top surface
- Length from center: 12mm
- Width: 4mm
- Thickness: 3mm
- Extends radially outward

### Foam Piece
- Organic blob shape using hull of spheres
- Overall size: ~8mm diameter
- Height: ~6mm
- Positioned at end of arm (center at 12mm from shaft)

### Base Plate (Test Stand)
- Size: 40mm x 40mm x 3mm
- Center hole: 3.3mm for shaft
- Mounting holes: 4x M3 at corners (optional)

## Connection Verification

| Connection | Gap Check | Status |
|------------|-----------|--------|
| Shaft → Base hole | 3.0mm shaft in 3.3mm hole = 0.3mm clearance | [x] PASS |
| Shaft → Gear hole | 3.0mm shaft in 3.3mm hole = 0.3mm clearance | [x] PASS |
| Gear → Shaft (axial) | Gear sits on base, shaft through center | [x] PASS |
| Arm → Gear top | Arm attached at Z=5mm (gear top) | [x] PASS |
| Foam → Arm end | Foam centered at arm tip (12mm from center) | [x] PASS |

## Collision Check at 4 Positions

### Position θ = 0° (Arm pointing +X)
- Foam at (12, 0, 8) - clears base edge at X=20mm | [x] PASS
- Arm clears gear teeth | [x] PASS

### Position θ = 90° (Arm pointing +Y)
- Foam at (0, 12, 8) - clears base edge at Y=20mm | [x] PASS
- Arm clears gear teeth | [x] PASS

### Position θ = 180° (Arm pointing -X)
- Foam at (-12, 0, 8) - clears base edge at X=-20mm | [x] PASS
- Arm clears gear teeth | [x] PASS

### Position θ = 270° (Arm pointing -Y)
- Foam at (0, -12, 8) - clears base edge at Y=-20mm | [x] PASS
- Arm clears gear teeth | [x] PASS

## Meshing Verification (with Wave Drive 30T)
- Wave Drive pitch radius: 15mm
- Zone 1 Gear pitch radius: 6mm
- Center distance: 15 + 6 = 21mm
- Gear ratio: 12/30 = 0.4x (Zone 1 turns 0.4 revolutions per Wave Drive revolution)
- Module match: Both use module 1.0 | [x] PASS

## Summary
- [x] All parts dimensioned
- [x] All connections verified (gap = 0 or proper clearance)
- [x] No collisions at any position
- [x] Gear parameters match meshing gear
- [x] Ready for code generation

**GEOMETRY STATUS: ALL PASS - PROCEED TO CODE**
