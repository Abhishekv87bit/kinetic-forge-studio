# GEOMETRY CHECKLIST - BELL CRANK FISH ARC MECHANISM

**Mechanism:** Bell crank lever converting wave vertical motion to fish horizontal arc
**Date:** 2026-01-21
**Status:** DESIGN VALIDATION

---

## Part 1: Reference Point

```
Reference name: WAVE_TOP_SURFACE
Reference position: Y=35mm (middle of wave face), Z=10mm (wave top)
Relative to: Individual wave baseline

Global: Each wave at X = FIRST_WAVE_X + i × UNIT_PITCH
```

---

## Part 2: Mechanism Concept

```
BELL CRANK OPERATION:
═════════════════════════════════════════════════════════════════════════

SIDE VIEW (looking along X axis):
─────────────────────────────────────────

                        ● fish body (faces viewer)
                       /
                      / horizontal arm (La = 35mm)
                     /
    frame mount ────○──── pivot point (Z = 20mm above wave top)
                    │
                    │ vertical arm (Lb = 15mm)
                    │
                    ● cam follower (roller)
                    │
            ~~~~~~~~│~~~~~~~~ wave top surface (Z = 10mm)
                    ↑↓ wave motion (+/- 3.7mm tip travel)


TOP VIEW (viewer looking down):
─────────────────────────────────────────

    wave direction →

    ┌─────────────────────────────────┐
    │           wave body             │
    │                                 │
    │    ○─────●  bell crank          │
    │    pivot  fish swings ←→        │
    │                                 │
    └─────────────────────────────────┘

    Fish swings LEFT-RIGHT as wave rocks UP-DOWN


MOTION CONVERSION:
─────────────────────────────────────────

Wave input: Vertical rocking (pitch angle from cam)
  - Zone A (waves 0-6):   tip travel ±3.4mm
  - Zone B (waves 7-13):  tip travel ±4.7mm
  - Zone C (waves 14-21): tip travel ±7.4mm

At bell crank contact point (Y=35mm from hinge):
  - Zone A: travel ≈ ±2.1mm (scaled by 35/66)
  - Zone B: travel ≈ ±2.5mm
  - Zone C: travel ≈ ±3.9mm

Bell crank amplification: La/Lb = 35/15 = 2.33×

Fish horizontal arc:
  - Zone A: 2.1 × 2.33 = ±4.9mm → 9.8mm total swing
  - Zone B: 2.5 × 2.33 = ±5.8mm → 11.6mm total swing
  - Zone C: 3.9 × 2.33 = ±9.1mm → 18.2mm total swing
```

---

## Part 3: Part List with Dimensions

### Part 1: BELL CRANK ARM
```
Shape: L-shaped lever arm
Material: PLA (printed as one piece)

Vertical arm (wave follower):
  Length: Lb = 15mm (pivot to roller center)
  Width: 4mm
  Thickness: 3mm (in X direction)

Horizontal arm (fish mount):
  Length: La = 35mm (pivot to fish mount)
  Width: 4mm
  Thickness: 3mm (in X direction)

Pivot hole: 3mm diameter (for M3 pin or 3mm rod)
Roller mount: 2mm diameter hole at end of vertical arm
Fish mount: 2mm diameter hole at end of horizontal arm

Total part envelope: ~38mm × 18mm × 3mm
```

### Part 2: PIVOT MOUNT (on frame)
```
Dimensions: 8mm × 8mm × 10mm block
Pivot hole: 3.2mm diameter (clearance for 3mm pin)
Position: Mounted to frame or wave body extension
  Y = 35mm (middle of wave)
  Z = 30mm (20mm above wave top at Z=10)
```

### Part 3: ROLLER FOLLOWER
```
Type: Small cylinder riding on wave top surface
Diameter: 4mm
Length: 3mm (matches arm thickness)
Bore: 2mm (press fit on 2mm pin)
Material: PLA or PETG (low friction)
```

### Part 4: FISH BODY
```
Same fish design from v6:
  Envelope: 14mm × 10mm × 5mm
  Mount: 2mm diameter pin hole
  Orientation: Faces +Y (toward viewer)

Mounted at end of horizontal arm
Swings in Y-Z plane (left-right from viewer perspective)
```

### Part 5: PINS
```
Pivot pin: 3mm diameter × 6mm length (or M3 screw)
Roller pin: 2mm diameter × 5mm length
Fish mount pin: 2mm diameter × 5mm length
```

---

## Part 4: Position Calculations

### Wave Motion at Contact Point
```
Wave pivot: Y = 4mm (hinge slot center)
Wave tip: Y = 70mm
Bell crank contact: Y = 35mm

Lever ratio from wave pivot to contact point:
  (35 - 4) / (70 - 4) = 31/66 = 0.47

For wave tip travel of ±7.4mm (Zone C):
  Contact point travel = 7.4 × 0.47 = ±3.5mm vertical
```

### Bell Crank Geometry
```
Pivot position (relative to wave baseline):
  Y = 35mm (aligned with wave middle)
  Z = 30mm (20mm above wave top surface)

Vertical arm:
  From pivot Z=30 to roller at Z=15
  Arm length Lb = 15mm

Horizontal arm:
  From pivot to fish mount
  Arm length La = 35mm
  Fish at Y = 35mm + 35mm = 70mm (but swings in Z)

Wait - need to reconsider coordinate system...

CORRECTED:
The bell crank converts Z motion (up/down) to Y motion (left/right)

Pivot at: Y=35mm, Z=30mm (fixed to frame/wave extension)
Vertical arm points DOWN: roller at Y=35mm, Z=15mm (contacts wave at Z≈10-13mm)
Horizontal arm points toward viewer: fish at Y=70mm, Z=30mm

When wave rocks UP: roller pushed UP → fish swings toward viewer
When wave rocks DOWN: roller drops → fish swings away from viewer

MOTION PLANE: Y-Z plane
ARC DIRECTION: Fish moves in/out (toward/away from viewer)

Hmm, this gives front-back motion, not left-right...
```

### Corrected Bell Crank Orientation for LEFT-RIGHT Arc
```
For fish to swing LEFT-RIGHT (parallel to wave array, in X direction):

Pivot axis must be parallel to Y (front-back)
Vertical arm swings in X-Z plane
Horizontal arm swings in X-Z plane

NEW GEOMETRY:
─────────────────────────────────────────

TOP VIEW:
                    wave array direction →

         X
    fish ●─────────○ pivot (axis points at viewer)
    swings         │
    ←→ left/right  │ vertical arm
                   │
                   ● roller on wave top


SIDE VIEW (looking along wave array):

              ● fish swings into/out of page
             /
            / horizontal arm
           /
    pivot ○
           \
            \ vertical arm
             \
              ● roller
              │
        ~~~~~│~~~~~ wave top (moves up/down with wave rock)
              ↑↓


This gives LEFT-RIGHT fish arc (in X direction) from UP-DOWN wave motion!
```

### Final Position Calculations
```
Pivot mount position (relative to wave baseline):
  X = 0mm (centered on wave)
  Y = 35mm (middle of wave face)
  Z = 30mm (20mm above wave top surface)
  Pivot AXIS: parallel to Y (horizontal, pointing at viewer)

Vertical arm (Lb = 15mm):
  From pivot, pointing DOWN and slightly BACK
  Roller contacts wave top at approximately:
    X = 0mm
    Y = 35mm (same as pivot Y)
    Z = 10-15mm (wave top surface, varies with rock)

Horizontal arm (La = 35mm):
  From pivot, extends in +X or -X direction
  Fish position at rest:
    X = +35mm (or -35mm) from pivot
    Y = 35mm (same as pivot Y)
    Z = 30mm (same as pivot Z)
  Fish swings in X-Z arc

WAIT - this puts fish way outside the wave body...
Need fish to stay above its own wave, not extend to neighboring wave.

REVISED APPROACH:
Make horizontal arm extend UPWARD, not sideways.
Fish swings in Y-Z arc (toward/away from viewer + up/down)
```

---

## Part 5: Revised Geometry for Compact Design

```
COMPACT BELL CRANK - Fish above its own wave:
═════════════════════════════════════════════════════════════════════════

SIDE VIEW (looking along X, along wave array):
─────────────────────────────────────────

                    fish ● ← swings in arc
                        /    (toward/away from viewer)
                       /
                      / arm La=25mm (angled up-back)
                     /
    pivot axis ─────○───── horizontal (parallel to X)
      (into page)   │
                    │ arm Lb=12mm (down)
                    │
                    ● roller
                    │
            ~~~~~~~~│~~~~~~~~ wave top (rocks up/down)


FRONT VIEW (viewer's perspective):
─────────────────────────────────────────

                        fish ●
                            /│\
                           / │ \ arc path
                          /  │  \
                         ↙   │   ↘
                             │
              wave ─────┬────│────┬─────
                   rock │    ○    │ rock
                  down  │  pivot  │  up
                        │ (hidden)│


TOP VIEW:
─────────────────────────────────────────

              Y (toward viewer)
              ↑
              │
    wave ─────┼───────────────
              │     ● fish (swings left-right)
              │    /
              │   /
              │  ○ pivot
              │  │
              └──│───────────────→ X (along wave array)
                 │
                 ● roller contact


MOTION:
- Wave rocks up → roller pushed up → fish swings toward viewer (and up)
- Wave rocks down → roller drops → fish swings away from viewer (and down)
- Fish appears to "jump" in an arc toward the viewer as wave crests!
```

---

## Part 6: Final Dimensions

```
BELL CRANK FISH - FINAL GEOMETRY:
═════════════════════════════════════════════════════════════════════════

Part: Bell Crank Arm (L-shaped)
─────────────────────────────────────────
  Vertical segment: 12mm length, 4mm wide, 3mm thick
  Horizontal segment: 25mm length, 4mm wide, 3mm thick
  Angle: 90° between segments
  Pivot hole: 3mm at junction
  Roller hole: 2mm at bottom of vertical segment
  Fish hole: 2.5mm at end of horizontal segment

Part: Pivot Mount
─────────────────────────────────────────
  Block: 6mm × 6mm × 5mm
  Hole: 3.2mm through (for pivot pin)
  Position relative to wave baseline:
    X = 0mm (centered)
    Y = 38mm (slightly behind wave middle)
    Z = 22mm (12mm above wave top)
  Attached to: Wave body via small bracket

Part: Roller
─────────────────────────────────────────
  Cylinder: 4mm diameter × 3mm length
  Bore: 2mm
  Position at rest:
    Z = 10mm (resting on wave top)

Part: Fish Body
─────────────────────────────────────────
  Dimensions: 14mm × 10mm × 5mm (from v6 design)
  Mount bore: 2.5mm
  Position at rest (end of arm):
    X = 0mm
    Y = 38mm + 25mm×sin(arm_angle) ≈ 55mm
    Z = 22mm + 25mm×cos(arm_angle) ≈ 45mm

Arm rest angle: ~30° from vertical (angled toward viewer)
  - Allows fish to swing both directions
  - Fish at roughly 45° above horizontal


MOTION CALCULATION:
─────────────────────────────────────────
Wave tip amplitude (Zone C): ±7.4mm
At roller contact (Y=38mm): ±7.4 × (38-4)/(70-4) = ±3.8mm

Bell crank ratio: La/Lb = 25/12 = 2.08×
Fish arc amplitude: 3.8 × 2.08 = ±7.9mm

Total fish swing: 15.8mm arc
Arc angle: 2 × asin(7.9/25) = 2 × 18.4° = 36.8° total

RESULT: Fish swings through ~37° arc as wave passes!
```

---

## Part 7: Connection Verification

### Connection 1: Pivot to Frame/Wave
```
Pivot mount attaches to wave body extension
Extension: Small bracket above wave at Y=38mm
Bracket clearance from wave surface: 12mm

[x] PASS - Mount position defined
```

### Connection 2: Roller to Wave Top
```
Roller rests on wave top surface at Z=10mm
Wave surface is flat (top of wave body cube)
Roller must track wave rock motion

At rest: roller at Z=10mm
Wave up (3.8mm): roller at Z=13.8mm
Wave down (3.8mm): roller at Z=6.2mm

[x] PASS - Contact maintained (gravity keeps roller on surface)
```

### Connection 3: Fish to Bell Crank Arm
```
Fish has 2.5mm bore
Arm has 2.5mm hole
Pin: 2.5mm diameter × 5mm

Fish rotates freely on pin (can self-level)

[x] PASS - Standard pin joint
```

---

## Part 8: Collision Check

### Bell Crank vs Wave Body
```
Pivot at Z=22mm, wave top at Z=10mm
Clearance: 12mm

Vertical arm length: 12mm
Arm bottom: Z = 22 - 12 = 10mm (exactly at wave top level)

Roller diameter: 4mm, radius 2mm
Roller center at arm end: Z=10mm at rest
Roller bottom: Z = 10 - 2 = 8mm

Wave top at Z=10mm... roller bottom at Z=8mm?

ISSUE: Roller goes 2mm BELOW wave top surface!

FIX: Raise pivot by 2mm
New pivot Z = 24mm
Roller center at rest: Z = 24 - 12 = 12mm (2mm above wave top)
Roller bottom: Z = 12 - 2 = 10mm (exactly at wave top)

[x] PASS (with pivot at Z=24mm)
```

### Fish vs Adjacent Wave
```
Wave spacing: 10mm in X direction
Fish width: 14mm in X direction

Fish centered on its wave: X = -7mm to +7mm
Adjacent wave at X = ±10mm

Clearance: 10 - 7 = 3mm each side

BUT: Fish swings in Y-Z plane, NOT X direction
No X motion at all!

[x] PASS - No collision with adjacent waves
```

### Fish vs Own Wave Body
```
Fish at rest: Z ≈ 45mm
Wave top: Z = 10mm
Clearance: 35mm

Fish swing: ±18° from rest position
At maximum swing, fish Z = 45 - 25×sin(18°) = 45 - 7.7 = 37.3mm
Still 27mm above wave top

[x] PASS
```

---

## Part 9: Physics Check

### Gravity Bias
```
Fish mass: ~3g
Arm mass: ~1g
Total moving mass: 4g

CG of arm+fish: approximately at fish position (fish is heavier)

At rest (arm at 30° from vertical toward viewer):
  Gravity creates torque pushing fish TOWARD viewer
  Roller pressed AGAINST wave surface by gravity

Good! Gravity keeps roller in contact with wave.

[x] PASS - Gravity maintains contact
```

### Friction
```
Roller on wave surface (PLA on PLA):
  Contact force ≈ 40mN (from gravity)
  Friction coefficient ≈ 0.3 (rolling)
  Friction force ≈ 12mN

Torque to lift fish: 4g × 9.81 × 25mm × sin(swing) ≈ 15 mN·m at max swing

Wave force available: Much higher (cam system has 10× margin)

[x] PASS - Wave can easily drive bell crank
```

---

## Part 10: Final Checklist

```
[x] All parts have explicit XYZ positions
[x] All connections verified
[x] Collision checks passed (with Z=24mm pivot)
[x] Gravity keeps roller in contact
[x] Wave force sufficient to drive mechanism
[x] Fish arc: ~37° total swing
[x] Fish motion: toward/away from viewer (Y direction) + up/down (Z)
[x] Printable: all features ≥ 2mm

Date: 2026-01-21
```

---

## FINAL DESIGN SUMMARY

```
╔═══════════════════════════════════════════════════════════════════════╗
║           BELL CRANK FISH ARC MECHANISM                               ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  PIVOT POSITION: Y=38mm, Z=24mm (above wave middle)                   ║
║  VERTICAL ARM: Lb = 12mm (to roller)                                  ║
║  HORIZONTAL ARM: La = 25mm (to fish, angled 30° toward viewer)        ║
║  AMPLIFICATION: 2.08× (La/Lb)                                         ║
║                                                                       ║
║  FISH ARC:                                                            ║
║    Zone A: 16.5° total swing (gentle)                                 ║
║    Zone B: 21.4° total swing (medium)                                 ║
║    Zone C: 36.8° total swing (dramatic)                               ║
║                                                                       ║
║  MOTION CHARACTER:                                                    ║
║    - Fish "jumps" toward viewer as wave crests                        ║
║    - Fish "dives" away as wave troughs                                ║
║    - Progressive: Zone C fish jump highest                            ║
║                                                                       ║
║  PARTS PER FISH: 4                                                    ║
║    1. Bell crank arm (L-shaped)                                       ║
║    2. Pivot mount bracket                                             ║
║    3. Roller (4mm cylinder)                                           ║
║    4. Fish body (reuse v6 design)                                     ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```
