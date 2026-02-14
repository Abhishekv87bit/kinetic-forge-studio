# GEOMETRY CHECKLIST - ZONE GAP FISH MECHANISM

**Mechanism:** Shared fish elements in gaps between wave zones
**Motion:** Left-right arc swing driven by adjacent wave motion
**Date:** 2026-01-21

---

## Part 1: Zone Layout with Gaps

### Current Layout (No Gaps)
```
Waves are continuous with 10mm spacing:
  Wave 0 at X = 88mm
  Wave 6 at X = 88 + 6×10 = 148mm  (end of Zone A)
  Wave 7 at X = 88 + 7×10 = 158mm  (start of Zone B)

  Gap between Zone A and B = 0mm (waves are adjacent)
```

### Proposed Layout (With Gaps)
```
Insert 30mm gaps between zones for fish mechanisms:

ZONE A: Waves 0-6 (7 waves)
  Wave 0:  X = 88mm
  Wave 6:  X = 88 + 6×10 = 148mm

GAP 1: X = 148 to 178mm (30mm gap)
  Fish 1 at X = 163mm (center of gap)

ZONE B: Waves 7-13 (7 waves) - SHIFTED +30mm
  Wave 7:  X = 178mm (was 158mm)
  Wave 13: X = 178 + 6×10 = 238mm

GAP 2: X = 238 to 268mm (30mm gap)
  Fish 2 at X = 253mm (center of gap)

ZONE C: Waves 14-21 (8 waves) - SHIFTED +60mm
  Wave 14: X = 268mm (was 228mm)
  Wave 21: X = 268 + 7×10 = 338mm

TOTAL NEW WIDTH: 338 - 88 = 250mm (was 210mm)
Added: 2 × 30mm gaps = 60mm extra
```

### Updated Wave Position Formula
```
OLD: wave_x(i) = FIRST_WAVE_X + i × UNIT_PITCH

NEW: wave_x(i) = FIRST_WAVE_X + i × UNIT_PITCH
                 + (i > 6 ? GAP_WIDTH : 0)     // Gap after Zone A
                 + (i > 13 ? GAP_WIDTH : 0)    // Gap after Zone B

Where:
  FIRST_WAVE_X = 88mm
  UNIT_PITCH = 10mm
  GAP_WIDTH = 30mm
```

---

## Part 2: Fish Mechanism in Gap

### Concept: Wave-Driven Arc Swing
```
SIDE VIEW (looking along Y, toward viewer):
═══════════════════════════════════════════════════════════════

    Zone A                    GAP                    Zone B
    (wave 6)                                        (wave 7)
       │                       │                       │
       │      pivot ○──────────┼──────────○ pivot     │
       │           │          fish          │         │
       │           │           ●            │         │
       │    arm────┤          /│\           ├────arm  │
       │           │         / │ \          │         │
       │           ●        ↙  │  ↘         ●         │
       │        follower      swing      follower     │
       │           │           │            │         │
    ───┴───────────┴───────────┴────────────┴─────────┴───
    wave 6 rocks    30mm gap    wave 7 rocks
    this follower              this follower


The fish is suspended between two followers, one on each adjacent wave.
When wave 6 goes UP and wave 7 goes DOWN (180° out of phase),
the fish swings LEFT.
When wave 6 goes DOWN and wave 7 goes UP,
the fish swings RIGHT.
```

### Detailed Mechanism
```
TOP VIEW:
═══════════════════════════════════════════════════════════════

                        fish body (14mm)
                      ╭─────●─────╮
                      │           │
    wave 6 ──────●────┼───────────┼────●────── wave 7
               arm A  │   pivot   │  arm B
               (15mm) │   point   │  (15mm)
                      │           │
                      ╰───────────╯

    Arms extend from waves into gap
    Fish pivots at center, driven by differential wave motion


FRONT VIEW (viewer's perspective):
═══════════════════════════════════════════════════════════════

                         ● fish
                        /│\
                       / │ \  arc swing left-right
                      /  │  \
                     ↙   │   ↘
                         │
           arm A ────────○──────── arm B
             │           │           │
    wave 6 ──┴─          │         ──┴── wave 7
    goes UP              │              goes DOWN
                    fish swings LEFT
```

---

## Part 3: Part Dimensions

### Part 1: DRIVE ARM (2 per fish, mirror image)
```
Shape: Angled arm extending from wave into gap
Length: 15mm (from wave edge to pivot point)
Width: 4mm
Thickness: 3mm

Wave attachment: Clips onto wave top at Y=35mm
Pivot end: 3mm hole for shared pivot pin

Print quantity: 4 (2 per fish × 2 fish)
```

### Part 2: FISH BODY WITH PIVOT
```
Reuse fish design from v6:
  Body: 14mm × 10mm × 5mm
  Added: Central pivot tube (3mm ID, 5mm OD, 8mm tall)

The fish hangs from the pivot, can swing freely

Print quantity: 2
```

### Part 3: PIVOT POST (stationary, mounted to frame)
```
Vertical post in center of gap
Height: 40mm (from frame base to pivot point)
Diameter: 6mm
Top: 3mm pivot pin extending horizontally (in X direction)

Fish hangs from this pin
Drive arms connect to fish body sides

Print quantity: 2
```

### Part 4: CONNECTING ROD (links wave to fish swing)
```
Rather than arms on waves, use connecting rods:

Rod length: 20mm
Rod diameter: 2mm
Ball ends: 3mm spheres with 1.5mm bores

One end attaches to wave (at Y=35mm, rises/falls with wave)
Other end attaches to fish body side (converts to horizontal swing)

Print quantity: 4 (2 per fish)
```

---

## Part 4: Kinematics Analysis

### Wave Phase Relationship
```
Wave 6 (end of Zone A): phase = 6 × (360/22) = 98°
Wave 7 (start of Zone B): phase = 7 × (360/22) = 115°

Phase difference: 115° - 98° = 17°

At any moment, waves 6 and 7 are 17° out of phase.
This means they move in SIMILAR directions, not opposite!

PROBLEM: We need waves moving in OPPOSITE directions for max swing.

SOLUTION: Use waves that ARE opposite phase:
  Wave 6: phase = 98°
  Wave 17: phase = 17 × 16.36° = 278°
  Difference: 278° - 98° = 180° ✓

But wave 17 is far away (in Zone C)...
```

### Alternative: Single Wave Drive
```
Instead of differential drive, use SINGLE wave with bell crank:

    SIDE VIEW (looking at gap from zone A side):

                      fish ●
                          /│\
                         / │ \ swing arc
                        /  │  \
                       ↙   │   ↘
                           │
                  pivot ───○─── frame post
                           │
                    arm ───┤
                           │
                           ● follower on wave 6
                           │
                      ~~~~~│~~~~~ wave 6 top
                           ↑↓

    Single wave drives fish through bell crank
    Fish swings LEFT-RIGHT as wave rocks UP-DOWN

    This is the bell crank we already designed, just placed in gap!
```

### Revised Mechanism: Bell Crank in Gap
```
POSITION:
  - Pivot post in center of 30mm gap (X = 163mm for Gap 1)
  - Bell crank arm extends back to wave 6 (15mm reach)
  - Fish mounted on other arm, swings in X direction

ORIENTATION:
  - Pivot axis is VERTICAL (parallel to Z)
  - Vertical arm extends toward wave 6 (in -X direction)
  - Horizontal arm carries fish, swings in X-Y plane

Wait, this still gives Y swing not X swing...
```

---

## Part 5: Correct Geometry for X-Direction Swing

### The Key Insight
```
For fish to swing LEFT-RIGHT (X direction):
  - Pivot axis must be parallel to Y (horizontal, pointing at viewer)
  - Wave vertical motion (Z) converts to fish horizontal motion (X)

This is EXACTLY what the bell crank does, but rotated 90°!

CORRECTED MECHANISM:
═══════════════════════════════════════════════════════════════

TOP VIEW:
                                    Y (toward viewer)
                                    ↑
                                    │
        wave 6                      │                      wave 7
           │                        │                         │
           │     ●──────────────────○──────────────────●      │
           │   follower        pivot axis           follower  │
           │   (on wave 6)    (horizontal,          (on wave 7)
           │                   into page)
           │                        │
           └────────────────────────┼─────────────────────────┘
                                    │
                                    │
                              fish ●┼● swings LEFT-RIGHT
                                  ←│→
                                   X


SIDE VIEW (looking along X):

                    fish ● swings into/out of page (X direction)
                        │
              pivot ────○──── axis horizontal (Y direction)
                       /│\
                      / │ \
                     /  │  \
               arm  /   │   \ arm
                   ●    │    ●
              follower  │  follower
                 │      │      │
    wave 6 ~~~~~~│~~~~~~│~~~~~~│~~~~~~ wave 7
    up/down             │           up/down
                     (gap)
```

### Final Mechanism: Dual-Input Rocker
```
TYPE: Differential rocker with two inputs

INPUTS:
  - Follower A rides wave 6 (up/down)
  - Follower B rides wave 7 (up/down)

OUTPUT:
  - Fish swings left-right based on DIFFERENCE of inputs

ADVANTAGE:
  - When both waves go same direction: fish stays centered
  - When waves go opposite: fish swings maximally
  - Creates natural "jumping at wave crest" timing

GEOMETRY:
  Pivot: X = 163mm (gap center), Y = 35mm, Z = 25mm
  Pivot axis: Parallel to Y

  Arm to wave 6: 15mm in -X direction, drops to Z=10mm (wave top)
  Arm to wave 7: 15mm in +X direction, drops to Z=10mm (wave top)

  Fish arm: 20mm in +Y direction (toward viewer), fish at end
```

---

## Part 6: Simplified Single-Input Version

Given complexity of dual-input, let's simplify:

### Single Wave Bell Crank (Placed in Gap)
```
CONCEPT: Same bell crank as before, but:
  - Mounted in the 30mm gap between zones
  - Driven by wave 6 only (last wave of Zone A)
  - Fish swings left-right above the gap

GEOMETRY:
═══════════════════════════════════════════════════════════════

FRONT VIEW (viewer's perspective):

                    LEFT ←── fish ──→ RIGHT
                              ●
                             /│\
                            / │ \
                           /  │  \
              swing arc   ↙   │   ↘
                              │
                      pivot ──○── (axis into page, parallel to Y)
                              │
                              │ vertical arm (12mm)
                              │
                              ● roller
                              │
              wave 6 ─────────┴───────── surface (rocks up/down)


SIDE VIEW (looking along X):

              pivot axis ═══○═══ (horizontal, in Y)
                            │
                            │ arm down to wave
                            │
                            ● roller on wave 6
                            │
                   ~~~~~~~~~│~~~~~~~~~ wave 6 rocks up/down


TOP VIEW:

                    Y (viewer)
                    ↑
                    │
                    │     fish swings LEFT-RIGHT
                    │         ←─●─→
                    │           │
    wave 6 ─────────┼───────────○─────────────── wave 7
         (Zone A)   │      pivot post      (Zone B)
                    │      (in gap)
                    │
                    └────────────────────────────→ X


KEY DIMENSIONS:
  - Gap width: 30mm
  - Pivot post at gap center: X = 163mm
  - Pivot height: Z = 25mm (above wave tops)
  - Vertical arm: 15mm (pivot to roller)
  - Fish arm: 20mm (pivot to fish, toward viewer in +Y)
  - Fish at: Y = 55mm, Z = 25mm, swings in X: ±10mm
```

---

## Part 7: Parts List (Simplified Version)

### For Each Gap (2 gaps total):

**Part 1: Pivot Post**
```
Height: 30mm (from frame to pivot)
Base: 8mm × 8mm mounting plate
Shaft: 5mm diameter
Top: Horizontal pivot pin 3mm × 10mm (in Y direction)
```

**Part 2: Bell Crank Arm**
```
L-shaped, single piece
Vertical segment: 15mm (to roller)
Horizontal segment: 20mm (to fish, in +Y direction)
Width: 4mm, Thickness: 3mm
Pivot bore: 3mm
```

**Part 3: Roller**
```
Diameter: 4mm
Length: 4mm
Bore: 2mm
```

**Part 4: Fish Body**
```
Standard fish from v6: 14mm × 10mm × 5mm
Mount: 2.5mm bore at belly
Orientation: Faces +Y (viewer), swings in X
```

**Total per gap: 4 parts**
**Total for 2 gaps: 8 parts**

---

## Part 8: Position Summary

```
GAP 1 (between Zone A and Zone B):
════════════════════════════════════════
  Location: X = 148 to 178mm (after wave 6, before wave 7)
  Pivot post: X = 163mm, Y = 35mm, Z = 0 to 25mm
  Roller contacts: Wave 6 at X = 148mm
  Fish swings: X = 153 to 173mm (±10mm from center)
  Fish Y position: 55mm (20mm toward viewer from pivot)
  Fish Z position: 25mm (same as pivot)

GAP 2 (between Zone B and Zone C):
════════════════════════════════════════
  Location: X = 238 to 268mm (after wave 13, before wave 14)
  Pivot post: X = 253mm, Y = 35mm, Z = 0 to 25mm
  Roller contacts: Wave 13 at X = 238mm
  Fish swings: X = 243 to 263mm (±10mm from center)
  Fish Y position: 55mm
  Fish Z position: 25mm
```

---

## Part 9: Wave Position Update Required

```
NEW wave_x function needed:

function wave_x(i) =
    FIRST_WAVE_X
    + i * UNIT_PITCH
    + (i > 6 ? GAP_WIDTH : 0)      // 30mm gap after wave 6
    + (i > 13 ? GAP_WIDTH : 0);    // 30mm gap after wave 13

Where:
  FIRST_WAVE_X = 88mm
  UNIT_PITCH = 10mm
  GAP_WIDTH = 30mm

Results:
  Wave 0:  88mm
  Wave 6:  148mm
  Wave 7:  188mm (148 + 10 + 30)
  Wave 13: 248mm
  Wave 14: 288mm (248 + 10 + 30)
  Wave 21: 358mm

Fish 1: X = 163mm (between waves 6 and 7)
Fish 2: X = 268mm (between waves 13 and 14)

FRAME WIDTH: Must increase from 260mm to ~300mm
```

---

## Part 10: Final Checklist

```
[x] Gap positions defined (30mm each)
[x] Fish mechanism type: Bell crank (single input)
[x] Pivot axis: Horizontal (Y direction) for X-swing output
[x] Parts list complete (4 parts per gap)
[x] Wave position formula updated
[x] Fish swing direction: LEFT-RIGHT (X axis) ✓
[x] Fish faces viewer: YES (oriented +Y) ✓

READY FOR CODE
```

---

## Summary

```
╔═══════════════════════════════════════════════════════════════════════╗
║           ZONE GAP FISH - LEFT-RIGHT SWING                            ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  LAYOUT:                                                              ║
║    Zone A (waves 0-6) │ GAP+FISH │ Zone B (7-13) │ GAP+FISH │ Zone C ║
║                                                                       ║
║  GAP WIDTH: 30mm (fits fish + mechanism)                              ║
║                                                                       ║
║  MECHANISM: Bell crank in gap                                         ║
║    - Pivot axis horizontal (Y)                                        ║
║    - Roller rides last wave of previous zone                          ║
║    - Fish swings LEFT-RIGHT (X direction)                             ║
║                                                                       ║
║  FISH COUNT: 2 total (one per gap)                                    ║
║                                                                       ║
║  MOTION:                                                              ║
║    Wave 6 UP → Fish 1 swings RIGHT                                    ║
║    Wave 6 DOWN → Fish 1 swings LEFT                                   ║
║    (Same for Fish 2 driven by wave 13)                                ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
```
