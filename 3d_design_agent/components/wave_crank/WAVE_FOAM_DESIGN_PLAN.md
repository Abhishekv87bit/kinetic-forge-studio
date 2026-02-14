# WAVE OCEAN v6 - DESIGN PLAN
## Progressive Eccentricity + Rising Foam Elements

**Date:** 2026-01-21
**Status:** PLAN FOR IMPLEMENTATION

---

## PROBLEM 1: Progressive Eccentricity Not Visible Enough

### Current Issue
The current cam formulas produce only 2mm difference in tip motion across 22 waves:
- Wave 1: ~4.1mm tip motion
- Wave 22: ~6.1mm tip motion
- **Ratio: 1.49x (not visually dramatic)**

### Solution: New Cam Formulas

```openscad
// OLD (insufficient progression):
// cam_major(i) = 10 + (i/21) * 2.5    // 10mm to 12.5mm
// cam_minor(i) = 9 - (i/21) * 2.5     // 9mm to 6.5mm

// NEW (dramatic progression):
cam_major(i) = 9 + (i/21) * 3.5        // 9mm to 12.5mm
cam_minor(i) = 9 - (i/21) * 3          // 9mm to 6mm
```

### Verification Table

| Wave | Major | Minor | Eccentricity | Diagonal @ 45° | Tip Motion |
|------|-------|-------|--------------|----------------|------------|
| 1    | 9.0   | 9.0   | 0mm (circular) | 6.4mm radius | ~2.5mm |
| 7    | 10.2  | 8.0   | 1.1mm | 6.5mm radius | ~4.0mm |
| 14   | 11.3  | 7.0   | 2.2mm | 6.7mm radius | ~5.5mm |
| 22   | 12.5  | 6.0   | 3.25mm | 6.9mm radius | ~7.5mm |

**Diagonal extent check**: 6.9mm × 2 = 13.8mm < 14mm housing ✓

**New ratio: 7.5/2.5 = 3.0x (visually dramatic!)**

---

## PROBLEM 2: Rising/Falling Foam Elements

### Recommended Approach: DIRECT WAVE MOUNT

**Why this approach:**
1. Zero additional mechanism (simplest)
2. Foam rises/falls exactly with wave
3. 6° tilt is acceptable for viewing
4. Progressive sizing creates visual intensity gradient

### Foam Element Specifications

```
╔═════════════════════════════════════════════════════════════╗
║  FOAM SIZES (Progressive)                                    ║
╠═════════════════════════════════════════════════════════════╣
║                                                             ║
║  ZONE A - GENTLE (Waves 1-7):                               ║
║    Shape: Small bubble cluster                              ║
║    Size: 8mm wide × 6mm tall × 3mm deep                     ║
║    Mount: 2mm dia post, 3mm tall                            ║
║    Mass: ~0.5g                                              ║
║                                                             ║
║  ZONE B - MEDIUM (Waves 8-14):                              ║
║    Shape: Medium foam spray                                 ║
║    Size: 12mm wide × 9mm tall × 4mm deep                    ║
║    Mount: 2.5mm dia post, 4mm tall                          ║
║    Mass: ~1.5g                                              ║
║                                                             ║
║  ZONE C - DRAMATIC (Waves 15-22):                           ║
║    Shape: Large breaking foam OR fish                       ║
║    Size: 16mm wide × 12mm tall × 5mm deep                   ║
║    Mount: 3mm dia post, 5mm tall                            ║
║    Mass: ~3g                                                ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
```

### Mount Position on Wave

```
SIDE VIEW (single wave):

                   FOAM
                    ●  ← embossed face toward viewer (+Y)
                    │
              mount post
         ╔══════════╧═══════════════════════╗
         ║                                  ║ Z=10mm (top)
         ║         WAVE BODY                ║
         ║                                  ║ Z=0 (baseline)
    ╔════╩════╗                      ╔══════╩══════╗
    ║ HINGE   ║                      ║ CAM HOUSING ║
    ║  SLOT   ║                      ║             ║
    ╚═════════╝                      ╚═════════════╝
       Y=4                  Y=35           Y=53       Y=70
                         (foam mount)

Mount position: Y=35mm, Z=10mm (centered on wave face, on top surface)
Mount hole: Through wave body, accepts foam post
```

### Visual from Viewer Perspective

```
FRONT VIEW (viewer looking at waves):

   Waves 1-7          Waves 8-14        Waves 15-22
   (gentle)           (medium)          (dramatic)

      ○ ○ ○            ◎ ◎ ◎             ● ● ● ●
      │ │ │            │ │ │             │ │ │ │
    ╔═╧═╧═╧═╗        ╔═╧═╧═╧═╗         ╔═╧═╧═╧═╧═╗
    ║       ║        ║       ║         ║         ║
    ╚═══════╝        ╚═══════╝         ╚═══════════╝

    Small bubbles    Medium foam       Large foam/fish
    Small motion     Medium motion     Dramatic motion

    ○ = 8mm          ◎ = 12mm          ● = 16mm
```

---

## MECHANISM DIAGRAM (Combined)

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                    WAVE OCEAN v6 - COMPLETE SYSTEM                         ║
║                         (Cross-Section View)                               ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║   ← VIEWER                                                                ║
║                                                                           ║
║   Zone A (Gentle)    Zone B (Medium)     Zone C (Dramatic)                ║
║   Waves 1-7          Waves 8-14          Waves 15-22                      ║
║                                                                           ║
║       ○   ○             ◎   ◎              ●     ●       FOAM             ║
║       │   │             │   │              │     │       (rises/falls     ║
║     ╔═╧═╗╔═╧═╗        ╔═╧═╗╔═╧═╗         ╔═╧═╗ ╔═╧═╗     with wave)      ║
║     ║   ║║   ║        ║   ║║   ║         ║   ║ ║   ║                      ║
║     ╚═╤═╝╚═╤═╝        ╚═╤═╝╚═╤═╝         ╚═╤═╝ ╚═╤═╝     WAVES            ║
║       │     │           │     │            │      │      (rock up/down)   ║
║     ──●─────●──       ──●─────●──        ──●──────●──    HINGE AXLE       ║
║       │     │           │     │            │      │      (Y=4mm, static)  ║
║      ○○○   ○○○         ◯◯◯   ◯◯◯          ◯◯◯    ◯◯◯                      ║
║       │     │           │     │            │      │      CAMs             ║
║     ══════════════════════════════════════════════════   CAMSHAFT         ║
║                                                          (Y=53mm, rotates)║
║                                                                           ║
║   LEGEND:                                                                 ║
║   ○ = small (9×9mm cam, 8mm foam)                                         ║
║   ◎ = medium (11×7mm cam, 12mm foam)                                      ║
║   ● = large (12.5×6mm cam, 16mm foam)                                     ║
║                                                                           ║
║   Motion amplitude:                                                       ║
║   Zone A: ±2.5mm at tip                                                   ║
║   Zone B: ±5mm at tip                                                     ║
║   Zone C: ±7.5mm at tip                                                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## GEOMETRY CHECKLIST UPDATES NEEDED

### New Parts to Verify:

1. **Foam mount holes** in wave body
   - Position: Y=35mm, Z=10mm (top surface)
   - Hole diameter: 2.1mm / 2.6mm / 3.1mm (per zone)
   - Depth: through (4mm)

2. **Foam elements** (22 pieces, 3 sizes)
   - Post fits in mount hole
   - No collision with adjacent waves
   - No collision with frame

3. **Revised cam sizes**
   - Verify diagonal fit at all angles
   - Verify progressive eccentricity

### Collision Check: Foam to Adjacent Wave

```
Wave spacing: 10mm pitch
Wave thickness: 4mm
Gap between waves: 10 - 4 - 4 = 2mm (cam space)

Foam width:
  - Small: 8mm (centered on 4mm wave = 2mm overhang each side)
  - Medium: 12mm (4mm overhang each side)
  - Large: 16mm (6mm overhang each side)

COLLISION CHECK:
  Large foam overhang (6mm) vs gap (2mm + 4mm cam) = 6mm available
  At rest: Foam edges touch adjacent cam space - TIGHT but OK

  At maximum tilt (6°):
  Foam edge moves: 12mm height × sin(6°) = 1.3mm

  MARGINAL - may need to reduce large foam width to 14mm
```

---

## IMPLEMENTATION STEPS

### Step 1: Update Cam Formulas
```openscad
// In wave_ocean_v5.scad, change:
function cam_major(i) = 9 + (i / (NUM_WAVES - 1)) * 3.5;  // 9mm to 12.5mm
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 3;    // 9mm to 6mm
```

### Step 2: Add Foam Mount Holes to Wave Module
```openscad
// Add to wave_slat module:
FOAM_MOUNT_Y = 35;
FOAM_MOUNT_Z = 10;

// Mount hole diameter based on zone
function foam_mount_dia(i) =
    i < 7 ? 2.1 :      // Zone A
    i < 14 ? 2.6 :     // Zone B
    3.1;               // Zone C

// In wave difference():
translate([0, FOAM_MOUNT_Y, FOAM_MOUNT_Z - 0.1])
    cylinder(d=foam_mount_dia(i), h=WAVE_THICKNESS + 0.2);
```

### Step 3: Create Foam Element Modules
```openscad
// foam_elements.scad

module foam_small() { ... }   // 8×6×3mm + post
module foam_medium() { ... }  // 12×9×4mm + post
module foam_large() { ... }   // 14×12×5mm + post (reduced from 16mm)
```

### Step 4: Test Single Wave + Foam
- Print wave 1 with small foam
- Print wave 22 with large foam
- Verify fit, visibility, motion

### Step 5: Full Assembly
- Update print parts file
- Add foam to BOM
- Test complete system

---

## ALTERNATIVE: FISH OPTION

If fish are preferred over foam:

```
╔═══════════════════════════════════════════════════════════╗
║  FISH ELEMENT SPECIFICATIONS                               ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  SMALL FISH (Waves 1-7):                                  ║
║    Length: 10mm, Height: 5mm, Depth: 3mm                  ║
║    Facing: Sideways (profile toward viewer)               ║
║    Detail: Eye dot, simple fin                            ║
║                                                           ║
║  MEDIUM FISH (Waves 8-14):                                ║
║    Length: 15mm, Height: 8mm, Depth: 4mm                  ║
║    Facing: Sideways                                       ║
║    Detail: Eye, gill, fin                                 ║
║                                                           ║
║  LARGE FISH/DOLPHIN (Waves 15-22):                        ║
║    Length: 20mm, Height: 10mm, Depth: 5mm                 ║
║    Facing: Jumping pose (arched body)                     ║
║    Detail: Eye, fin, tail                                 ║
║                                                           ║
║  NOTE: Fish face sideways (+X or -X), not toward viewer   ║
║        This shows profile silhouette as wave rises        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

## DECISION NEEDED FROM USER

1. **Foam or Fish?** (or mix?)
2. **Large element width**: 14mm (safe) or 16mm (tight)?
3. **Foam shape**: Bubbles, spray, or organic blob?

---

## FILES TO CREATE/MODIFY

| File | Action |
|------|--------|
| `wave_ocean_v6.scad` | New file with corrected cams + foam mounts |
| `foam_elements.scad` | New file with foam/fish modules |
| `wave_ocean_v6_print_parts.scad` | Updated print parts |
| `0_geometry_v6.md` | New geometry checklist |
| `parts/04_wave_with_foam_test.scad` | Single wave + foam test |
