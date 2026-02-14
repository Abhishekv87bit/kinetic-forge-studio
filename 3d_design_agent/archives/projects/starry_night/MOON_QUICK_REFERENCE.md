# MOON SYSTEM - QUICK REFERENCE

## SPEED VERIFICATION ✓

```
moon_phase_rot = t × 360 × 0.1  ← Correct

Calculation chain:
  Master phase (t × 360°)
    ↓ × 0.25 (drive pulley)
  Drive rotation (t × 90°)
    ↓ × 0.4 (16T÷40T ratio)
  Moon rotation (t × 36°)
    ↓ Total = t × 360 × 0.1 ✓
  Result: 3 RPM, full cycle every 10 seconds
```

---

## BELT PATH ✓

```
Drive @ (204, 164)  ─66.5mm─┐
                             │
Moon @ (269.5, 175.5) ◄──────┘

Moon ─50.6mm─ Tensioner @ (219, 179)
                      │
                ─21.2mm─
                      │
          Back to Drive ◄─────

Total belt length: 138.3mm (GT2 2.0mm pitch)
```

---

## Z-CLEARANCE ⚠️ CONFLICT DETECTED

```
BEFORE FIX (V56):
  Z=7: STAR BELT ═══════════
  Z=7: MOON BELT ═══════════  ← CONFLICT!
  Result: Same layer = visual/physical overlap

AFTER FIX (V57):
  Z=7:  STAR BELT ═══════════
  Z=12: MOON BELT ═══════════  ← 5mm separation
  Result: Clear separation ✓
```

**Required code changes:**
1. Add: `MOON_BELT_Z = Z_STAR_GEAR + 2;  // = 12`
2. Line 539: `Z_MOON_PHASE - 8` → `MOON_BELT_Z`
3. Lines 543-545: `Z_MOON_PHASE - 8` → `MOON_BELT_Z` (3 times)
4. Line 553: `Z_MOON_PHASE - 6` → `MOON_BELT_Z + 3`

---

## PHYSICAL CONNECTION ✓

```
Belt Drive (Z=12)
    ↓ rotates
40T Pulley (Z=12, bore=4mm)
    ↓
Central shaft (d=4mm, h=30mm)
    ↓
├─ Phase disc (Z=15, rotates with moon_phase_rot) ✓
├─ Crescent (Z=20, FIXED, no rotation) ✓
└─ LED backing (Z=2, supports assembly)
```

**Key:** Phase disc rotates, crescent provides static reference shape

---

## ROTATION MECHANISM ✓

```
Phase Disc (Rotates):
  - 8 cylindrical "teeth" around perimeter
  - Rotated by moon_phase_rot
  - Shows waxing/waning as teeth occlude

Crescent (Fixed):
  - Concentric hole creates crescent shape
  - Does NOT rotate
  - Provides visual backup silhouette

Result: Realistic moon phase display
```

---

## VERIFICATION CHECKLIST (V57)

At θ=0°, 90°, 180°, 270°:

- [ ] Moon belt visible at Z=12 (not Z=7)
- [ ] 2mm separation from star belt confirmed
- [ ] Phase disc rotates smoothly ±360°
- [ ] Crescent remains static (facing same direction)
- [ ] Belt tension maintained (5mm at tensioner)
- [ ] No Z-collision warnings in render
- [ ] Center distance 66.5mm verified
- [ ] Pulleys on same XY plane (moon zone)

---

## FILE LOCATIONS

**Main file:** `/3d_design_agent/starry_night_v56_SIMPLIFIED.scad`
**Analysis:** `/3d_design_agent/projects/starry_night/MOON_ANALYSIS_V57.md`
**Implementation status:** READY FOR CODING

---

## STATUS SUMMARY

| Component | Result | Action |
|-----------|--------|--------|
| Speed | ✓ VERIFIED | No change |
| Belt path | ✓ VERIFIED | No change |
| **Z-clearance** | ⚠ CONFLICT | **APPLY FIX** |
| Connection | ✓ VERIFIED | No change |
| Rotation | ✓ VERIFIED | No change |

**Overall:** 4/5 components verified. Z-conflict requires immediate fix before V57 release.
