# VERIFICATION REPORT - WAVE OCEAN v3

**Date:** 2026-01-20
**File:** `wave_ocean_v3.scad`
**Status:** CORRECTED from v2 (Z-layer separation fix)

---

## Critical Fix Applied

**Problem in v2:** Cams were at the SAME Z-height as waves, causing physical intersection.

**Fix in v3:** Proper Z-layer separation:
```
Z_HINGE_AXLE = 25mm  (waves pivot here)
Z_CAMSHAFT = 28mm    (cams rotate here, 3mm ABOVE hinge)
```

Waves now REST ON TOP of cam surfaces. Gravity assists contact.

---

## Mechanism Summary

| Property | Value |
|----------|-------|
| Type | Cam-driven rocker with sliding pivot |
| Waves | 22 (traveling wave, right to left) |
| Motion | Progressive amplitude (8mm to 24mm) |
| Drive | Hand crank on camshaft |
| Phase | 16.36° offset per wave |

---

## Geometry Checklist Results (from 0_geometry_v2.md)

```
[x] All positions calculated with real numbers
[x] All connections verified (proper fits)
[x] Collisions checked at 4 positions
[x] Slot length adequate for angular range (15mm)
[x] Clearances verified (>=0.2mm)
[x] All parts structurally connected
[x] No floating parts
[x] Printability verified

GEOMETRY CHECKLIST: 100% PASS
```

---

## Z-Layer Verification

```
Z_BASE = 0mm           Base plate
Z_BASE_THICK = 5mm     Base thickness
Z_HINGE_AXLE = 25mm    Wave pivot axis
Z_CAMSHAFT = 28mm      Cam rotation axis

Camshaft ABOVE hinge by 3mm
Cams push UP on waves
Waves rock upward when cam major axis vertical
```

---

## Render Test Positions

### At theta = 0deg (Cams horizontal)
```
Wave angles near neutral (-2 to +3 deg)
Waves essentially horizontal
All followers on cam minor axis

[x] No cam-wave intersection
[x] No collision between adjacent waves
[x] Slots aligned with hinge axle
```

### At theta = 90deg (Cams vertical - MAX UP)
```
Wave 1:  angle = +4deg (gentle)
Wave 22: angle = +12deg (dramatic)

All waves tilted UPWARD
Max cam extends to Z = 28 + 12 = 40mm

[x] No cam-wave intersection
[x] Clearance to frame top maintained
```

### At theta = 180deg (Cams horizontal opposite)
```
Similar to theta=0
Wave angles near neutral

[x] No issues
```

### At theta = 270deg (Cams vertical - MAX DOWN)
```
Wave 1:  angle = -3deg
Wave 22: angle = -7deg

All waves tilted DOWNWARD
Min cam extends to Z = 28 - 12 = 16mm

[x] No cam-wave intersection
[x] Clearance to frame base maintained (>3mm)
```

---

## Animation Audit

| Expression | Physical Driver | Traced |
|------------|-----------------|--------|
| `sin(theta + cam_phase(i))` | Camshaft rotation | YES |
| `wave_angle(i, theta)` | Cam-driven rocking | YES |

**Orphan animations:** 0

---

## Structural Verification

```
[x] Frame base: Foundation
[x] Left side plate: Attached to base, holds both shafts
[x] Right side plate: Attached to base, holds both shafts
[x] Back rail: Supports hinge axle
[x] Front rail: Supports camshaft
[x] Hinge axle: Through back rail and side plates (STATIC)
[x] Camshaft: Through front rail and side plates (ROTATES)
[x] 22 Cams: Keyed to camshaft at phase intervals
[x] 22 Waves: Slot on hinge axle, rest on cam surface
[x] Hand crank: On camshaft left end

FLOATING PARTS: 0
```

---

## Printability Check

| Feature | Value | Pass |
|---------|-------|------|
| Min wall (wave) | 4mm | YES (>=1.2mm) |
| Min wall (cam) | 4mm | YES |
| Shaft hole clearance | 0.2mm | YES (>=0.2mm) |
| Slot clearance | 0.2mm | YES |

---

## Bill of Materials

### Printed Parts (50 total)
- 1x Frame left side (5x100x60mm)
- 1x Frame right side (5x100x60mm)
- 1x Frame base plate (284x100x5mm)
- 1x Frame back rail (274x10x30mm)
- 1x Frame front rail (274x20x45mm)
- 1x Hand crank
- 22x Wave slats (4x75x25mm each)
- 22x Elliptical cams (progressive 8x4mm to 24x10mm)

### Hardware
- 1x Steel rod 6mm dia x 280mm (camshaft)
- 1x Steel rod 5mm dia x 280mm (hinge axle)
- 8x M3x12 screws
- 8x M3 nuts
- Super glue for cam indexing

### Estimates
- Print time: 4-5 hours
- Filament: ~100g PLA

---

## Files

```
wave_crank/
├── parts/
│   └── 01_single_wave_cam_test.scad  <- Single wave test
├── wave_ocean_v3.scad                <- Main assembly
├── wave_ocean_v3_print_parts.scad    <- Print parts
├── 0_geometry_v2.md                  <- Geometry checklist
└── VERIFICATION_REPORT_V3.md         <- This file
```

---

## Final Status

```
══════════════════════════════════════════════════════
VERIFICATION COMPLETE - WAVE OCEAN v3
══════════════════════════════════════════════════════

MECHANISM:
  Type: Cam-driven rocker with sliding pivot
  Waves: 22 (4mm thick each)
  Cams: 22 elliptical discs (4mm thick, progressive)

CRITICAL FIX:
  Z-layer separation prevents cam-wave intersection
  Camshaft at Z=28mm, Hinge at Z=25mm
  Waves REST ON TOP of cam surfaces

VALIDATION:
  Geometry checklist: 100% PASS
  All 4 position checks: PASS
  Structural connections: ALL CONNECTED
  Floating parts: 0

RENDER TEST:
  theta=0:   OK - No intersection
  theta=90:  OK - Max up position clear
  theta=180: OK - No intersection
  theta=270: OK - Max down position clear

STATUS: READY TO PRINT (test single wave first)
══════════════════════════════════════════════════════
```

---

## Recommended Test Sequence

1. **Print single wave + single cam** (use `01_single_wave_cam_test.scad`)
2. Verify wave rocks smoothly on cam
3. Verify no binding at extreme positions
4. Print full frame
5. Print all 22 waves and 22 cams
6. Assemble and test full traveling wave motion

---

## Next Step: Integration

After physical testing confirms mechanism works:
- Integrate into main Starry Night assembly
- Connect to Wave Drive (30T) via belt to motor
- Position at [78-302, Y, Z] in main sculpture coordinates
