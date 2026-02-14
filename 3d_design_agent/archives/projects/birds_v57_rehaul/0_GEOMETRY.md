# GEOMETRY CHECKLIST - BIRDS V57 CRANK-SLIDER MECHANISM

**Status:** READY FOR VALIDATION
**Component:** Bird Pendulum System with Crank-Slider Drive
**Analysis Date:** 2026-01-19

---

## Part 1: Reference Point

```
Reference name: Pendulum Pivot Mount Center
Reference position: X=172mm, Y=127mm, Z=122mm
What is it: Center of 12mm diameter pivot cylinder where pendulum arm rotates
  - Calculated from frame dimensions in V56:
  - X = TAB_W (4) + INNER_W/2 (168) = 172mm
  - Y = TAB_W (4) + INNER_H (133) - 10 = 127mm
  - Z = Z_BIRD_WIRE (82) + 40 = 122mm
```

---

## Part 2: Part List with Dimensions

### Part 1: Pivot Mount Assembly
```
Dimensions: 12mm diameter × 6mm height (cylinder) + 20×20×10mm (cube base)
Position relative to reference:
  X = 172 - 0 = 172mm (center)
  Y = 127 - 0 = 127mm (center)
  Z = 122 - 6 = 116mm (top face of cylinder, where arm pivots)
Connects to: Pendulum arm at 116mm height
Color: C_GEAR_DARK (#8b7355)
```

### Part 2: Pendulum Arm (main rotation member)
```
Dimensions: 4mm × 6mm × 80mm rod (centered on axis)
Position relative to reference (AT REST, θ=0°):
  X = 172mm (pivot center, rotation axis parallel to X)
  Y = 127mm (pivot center, rotation axis parallel to X)
  Z = 122 - 40 = 82mm (center of arm length)

Connects to:
  - Pivot at Z=122mm (top end)
  - Bird carrier at Z=42mm (bottom end, when extended -Z)

Rotation axis: Parallel to X-axis, passing through (172, 127, 122)
Rotation range: ±30° (target swing from crank-slider mechanism)
Color: C_METAL (#708090)
```

### Part 3: Crank Gear (drive element)
```
Dimensions: 10mm diameter × 4mm height gear with 5mm eccentric throw
Position relative to reference:
  X = 172 + 25 = 197mm (offset from pivot)
  Y = 127 + 0 = 127mm (same Y as pivot)
  Z = 122 - 5 = 117mm (slightly lower than pivot)

Connects to: Push-pull rod at eccentric pin (5mm offset from gear center)
Rotation: Driven by master_phase * 0.5 (0.5x master speed)
Rotational range: 0° to 360° continuous
Crank pin position (as it rotates):
  X_pin = 197 + 5*sin(crank_angle)  (varies ±5mm in X)
  Y_pin = 127                        (fixed)
  Z_pin = 117                        (fixed)
Color: C_GEAR (#daa520)
```

### Part 4: Push-Pull Connecting Rod
```
Dimensions: 30mm × 4mm × 3mm rigid bar (sliding constraint)
Position relative to reference:
  BASE at crank pin: (197 + 5*sin(crank), 127, 117)
  END at pendulum: (172, 127, 122)

Displacement range: Moves along X-axis as crank rotates
  At crank θ=0°:   pin at X=197, rod connects to X=172, gap filled with ±5mm guides
  At crank θ=90°:  pin at X=202, rod shifts, maintains 30mm nominal length
  At crank θ=180°: pin at X=197, rod returns to nominal position
  At crank θ=270°: pin at X=192, rod shifts again

Connection type: Sliding pivot with ±5mm play in X-direction
Actual rod length: 30mm ± 0.5mm (accounts for pivot geometry)
Color: C_METAL (#708090)
```

### Part 5: Bird Carrier Platform
```
Dimensions: 60mm × 6mm × 4mm platform
Position relative to reference (AT REST, θ=0°):
  X = 172mm (centered below pivot)
  Y = 127mm (centered below pivot)
  Z = 82 - 80 = 2mm (bottom surface at minimum Z)

Full extent when extended:
  Z_max (arm points up): 122 + 80 = 202mm (EXCEEDS FRAME! See collision note)
  Z_min (arm points down): 2mm

Carries: 3 bird shapes + counterweight sphere below
Rotation: Coupled 1:1 with pendulum arm
Color: C_GEAR_DARK (#8b7355)
```

### Part 6: Bird Shape (×3 instances)
```
Dimensions: ~10mm × 3.6mm × 2.1mm each (scale [1.8, 0.6, 0.35] applied to 3mm radius sphere)
Positions on carrier (relative to carrier center at [172, 127, 2]):
  Bird 1 (left):   X = 172 - 22 = 150mm,  Y = 127 + 4 = 131mm,  Z = 2 - 3 = -1mm
  Bird 2 (center): X = 172,               Y = 127 + 4 = 131mm,  Z = 2 - 3 = -1mm
  Bird 3 (right):  X = 172 + 22 = 194mm,  Y = 127 + 4 = 131mm,  Z = 2 - 3 = -1mm

Animation: Each wings flap at wing_flap + i*40 degrees (offset 40° apart)
Wing flap speed: 4x master (reduced from 8x in V56)
Color: #222 (dark gray)
```

### Part 7: Counterweight Extension
```
Dimensions: 6mm diameter × 25mm post + 18mm diameter × 8mm cap
Position relative to reference (rotates WITH arm):
  At θ=0°: X = 172mm, Y = 127mm, Z = 122 + 20 + 25 + 8 = 175mm
  (extends upward above pivot)

At θ=±30° (swing):
  X = 172 ± 80*sin(30°) = 172 ± 40 = 132 to 212mm (swings with arm)
  Y = 127mm
  Z = 175mm (height constant)

Purpose: Balances moment arm of 50g bird carrier at Z=2mm
Moment calculation:
  Carrier arm: 50g × 80mm = 4000g·mm (downward)
  Counter arm: M × 175mm (upward to pivot)
  Required mass: M = 4000/175 ≈ 23g
  Use 30g brass weight for stability (60×30mm cylinder)

Color: C_GEAR (#daa520) for cap, C_GEAR_DARK (#8b7355) for post
```

### Part 8: Counterweight Sphere (balancing element)
```
Dimensions: 8mm diameter sphere
Position relative to reference:
  X = 172mm (centered on pivot)
  Y = 127mm (centered on pivot)
  Z = 42 - 12 = 30mm (below carrier)

Purpose: Additional moment compensation for bird carrier
Moment arm: 30mm below pivot = 30mm upward
Color: C_GEAR (#daa520)
```

---

## Part 3: Connection Verification

### Connection 1: Pivot Mount ↔ Pendulum Arm
```
Pivot mount top face: Z = 116mm (top of cylinder)
Pendulum arm pivot point: Z = 122mm (center of rotation axis)
Gap in Z: 122 - 116 = 6mm (fits within acceptable bearing stack height)

At θ=0° (arm pointing downward):
  Arm attachment point: (172, 127, 122)
  Pivot center: (172, 127, 122)
  Gap: 0mm ✓ PASS

At θ=90° (arm perpendicular):
  Arm attachment point: (172, 127, 122) [rotation axis doesn't move]
  Pivot center: (172, 127, 122)
  Gap: 0mm ✓ PASS

Status: PASS - Rigid pivot connection
```

### Connection 2: Crank Gear Pin ↔ Push-Pull Rod
```
Crank pin position: (197 + 5*sin(crank_angle), 127, 117)
Rod end connection: (197 + 5*sin(crank_angle), 127, 117)

At θ=0°:
  Pin: (197 + 0, 127, 117) = (197, 127, 117)
  Rod end: (197, 127, 117)
  Gap: 0mm ✓ PASS

At θ=90°:
  Pin: (197 + 5, 127, 117) = (202, 127, 117)
  Rod end: (202, 127, 117) [rod slides to accommodate]
  Gap: 0mm (sliding connection) ✓ PASS

At θ=180°:
  Pin: (197 + 0, 127, 117) = (197, 127, 117)
  Rod end: (197, 127, 117)
  Gap: 0mm ✓ PASS

At θ=270°:
  Pin: (197 - 5, 127, 117) = (192, 127, 117)
  Rod end: (192, 127, 117) [rod slides]
  Gap: 0mm (sliding connection) ✓ PASS

Status: PASS - Sliding crank pin connection
```

### Connection 3: Push-Pull Rod ↔ Pendulum Pivot
```
Rod end at pendulum: (172, 127, 122) [approximate, from crank throw geometry]
Pendulum pivot: (172, 127, 122)

At all crank angles:
  Rod must connect to pendulum rotation axis
  Actual mechanism: Rod endpoints constrain pendulum swing angle
  Gap: 0mm (kinematic constraint) ✓ PASS

Constraint detail:
  - Rod is rigidly attached to crank pin (revolute at pin)
  - Rod is rigidly attached to pendulum arm (revolute at pivot)
  - This forms closed 4-bar loop: Crank gear → Crank pin → Rod → Pendulum pivot → (back to frame)

Status: PASS - Kinematic linkage constraint
```

### Connection 4: Pendulum Arm ↔ Bird Carrier
```
Arm end position (at rest, θ=0°):
  X = 172, Y = 127, Z = 82 - 40 = 42mm

Carrier platform position:
  X = 172, Y = 127, Z = 2mm (bottom face, where birds attach)

Gap: 42 - 2 = 40mm (carrier suspended below arm extension point)
No rigid connection - carrier is mounted on extension

At θ=±30°:
  Arm extends to: X = 172 ± 40, Y = 127, Z = varies
  Carrier follows arm motion exactly

Status: PASS - Rigid mounted extension
```

---

## Part 4: Collision Check

### Moving Part 1: Pendulum Arm with Bird Carrier

**At θ=0° (arm points downward in -Z direction):**
```
Arm position: (172, 127, 82) center, extends from Z=122 to Z=42
Carrier position: (172, 127, 2) bottom
Nearest obstacle: Back panel at Z=0
Clearance in Z: 2 - 0 = 2mm ✓ PASS (>0.3mm)

No X-Y collision (carrier centered within frame)
```

**At θ=+30° (arm swings rightward +X direction):**
```
Arm extension in X: 80mm * sin(30°) = 40mm
Arm center moves to: X = 172 + 40 = 212mm
Carrier position: (212, 127, 2)

Frame inner bounds: X = 4 + 4 = 8mm (left), X = 4 + 4 + 168 = 176mm (right)
ISSUE: Carrier at X=212mm EXCEEDS frame right bound (176mm)

Collision distance: 212 - 176 = 36mm BEYOND frame
Frame wall thickness: 20mm
Actual collision point: At X = 196mm (frame outer edge)

⚠ CRITICAL COLLISION: Carrier swings outside frame at ±30°

Recommended fixes:
  A) Reduce swing amplitude to ±20° (fits within ±33mm frame width)
  B) Reposition pivot further left: X_pivot = 140mm instead of 172mm
  C) Reduce carrier width from 60mm to 40mm

Current status: ✗ FAIL - Must resolve before code generation
```

**At θ=+30° (arm swings upward, Z direction):**
```
Arm extension in Z: 80mm * (worst case swing up)
At full +30° swing with upward vertical component:
  Arm top reaches: Z = 122 + 80 = 202mm

Frame height: Z = 0 to 95mm
Frame extends to: Z = 92mm (including exterior frame mounting)

ISSUE: Arm extends WAY beyond frame height (202 > 95mm)

⚠ CRITICAL COLLISION: Carrier/arm extends outside frame in Z-direction

Analysis:
  - Current V56 design places arm INSIDE frame with 95mm max height
  - Pendulum motion must be purely horizontal (Y-axis) OR
  - Frame height must increase to 202+10=212mm minimum OR
  - Swing angle must be in horizontal plane only

Current status: ✗ FAIL - Requires design decision
```

**At θ=90° (arm perpendicular, pointing +X forward):**
```
Arm endpoint: (172 + 80, 127, 82) = (252, 127, 82)
Carrier: (252, 127, 2)

Frame inner right bound: X = 176mm
Frame outer right: X = 350mm (total width)

Clearance: 350 - 252 = 98mm to frame edge ✓ PASS

Clearance to obstacle (none in path): Safe ✓ PASS
```

**At θ=180° (arm points upward +Z direction):**
```
Same issue as θ=+30° upward case above.
Arm extends to Z=202mm, frame only goes to Z=95mm.

Status: ✗ FAIL
```

**At θ=270° (arm perpendicular, pointing -X backward):**
```
Arm endpoint: (172 - 80, 127, 82) = (92, 127, 82)
Carrier: (92, 127, 2)

Frame inner left bound: X = 8mm
Frame outer left: X = 0mm

Clearance to frame: 92 - 8 = 84mm ✓ PASS
```

### Collision Summary

```
Swing in horizontal plane (Y-axis): ✓ PASS at ±30°
Swing in forward-backward (X-axis): ✗ FAIL - exceeds frame width
Swing in vertical (Z-axis): ✗ FAIL - exceeds frame height

REQUIRED DESIGN DECISION:
  1. Confirm actual swing axis (is it purely Y-axis rotation?)
  2. If Y-only: all ±30° swings are safe ✓
  3. If 3D swing: must reduce amplitude or increase frame
```

---

## Part 5: Linkage Length Verification

### Crank-Slider Linkage Parameters

```
Crank offset (throw): 5mm (from gear center)
Rod length: 30mm (rigid constraint)
Pendulum arm: 80mm (leverage multiplier)
```

### Verification at 4 Crank Positions

**At θ=0° (crank horizontal):**
```
Crank pin position: (197 + 5*sin(0), 127, 117) = (197, 127, 117)
Pendulum pivot:     (172, 127, 122)

Distance check:
  ΔX = 197 - 172 = 25mm
  ΔY = 127 - 127 = 0mm
  ΔZ = 117 - 122 = -5mm

Distance = sqrt(25² + 0² + 5²) = sqrt(625 + 25) = sqrt(650) = 25.5mm

Declared rod length: 30mm
Actual distance: 25.5mm
Gap: 30 - 25.5 = 4.5mm

⚠ DISCREPANCY: Rod is 4.5mm too long at this position
This means the rod cannot be rigid and must have 4.5mm compliance

Status: ✗ FAIL (rod geometry mismatch)
```

**At θ=90° (crank pointing +X):**
```
Crank pin: (197 + 5*sin(90), 127, 117) = (197 + 5, 127, 117) = (202, 127, 117)
Pivot:     (172, 127, 122)

Distance check:
  ΔX = 202 - 172 = 30mm
  ΔY = 0mm
  ΔZ = -5mm

Distance = sqrt(30² + 0² + 5²) = sqrt(900 + 25) = sqrt(925) = 30.4mm

Declared rod length: 30mm
Actual distance: 30.4mm
Gap: 0.4mm (rod is tight but not rigid)

Status: ✗ MARGINAL FAIL (0.4mm interference)
```

**At θ=180° (crank horizontal opposite):**
```
Crank pin: (197 + 5*sin(180), 127, 117) = (197 + 0, 127, 117) = (197, 127, 117)
Pivot:     (172, 127, 122)

Distance: Same as θ=0° = 25.5mm
Gap: 4.5mm

Status: ✗ FAIL
```

**At θ=270° (crank pointing -X):**
```
Crank pin: (197 + 5*sin(270), 127, 117) = (197 - 5, 127, 117) = (192, 127, 117)
Pivot:     (172, 127, 122)

Distance check:
  ΔX = 192 - 172 = 20mm
  ΔY = 0mm
  ΔZ = -5mm

Distance = sqrt(20² + 0² + 5²) = sqrt(400 + 25) = sqrt(425) = 20.6mm

Declared rod length: 30mm
Actual distance: 20.6mm
Gap: 30 - 20.6 = 9.4mm

Status: ✗ FAIL (rod is 9.4mm too long)
```

### Linkage Verification Summary

```
Max deviation from declared 30mm: 9.4mm (at θ=270°)
Average deviation: (4.5 + 0.4 + 4.5 + 9.4) / 4 = 4.7mm

CRITICAL ISSUE: Rod geometry is inconsistent

Root cause: The static geometry (horizontal offset 25mm, vertical offset 5mm)
cannot produce a constant 30mm distance as the crank rotates.

For a proper slider-crank with constant rod length, need to either:
  A) Reposition the pivot height or pivot X-offset
  B) Use a different mechanism (e.g., eccentric/spiral cam)
  C) Use a compliant rod with ±5mm play

RECOMMENDATION: Use option A - recalculate pivot position

Revised calculation for 30mm constant rod:
  If pivot at (172, 127, Z_adj), find Z_adj where:
  For all θ: sqrt((197 + 5*sin(θ) - 172)² + 0² + (117 - Z_adj)²) ≈ 30

  This requires: (25 + 5*sin(θ))² + (117 - Z_adj)² = 900

  At θ=0°: 625 + (117 - Z_adj)² = 900 → (117 - Z_adj)² = 275 → Z_adj = 117 ± 16.6
  At θ=90°: 900 + (117 - Z_adj)² = 900 → Z_adj = 117

  Compromise: Z_adj = 117mm (same height as crank pin)

  Verification with Z_adj = 117:
    At θ=0°: sqrt(625 + 0) = 25mm (too short by 5mm)
    At θ=90°: sqrt(900 + 0) = 30mm ✓
    At θ=180°: sqrt(625 + 0) = 25mm (too short by 5mm)
    At θ=270°: sqrt(400 + 0) = 20mm (too short by 10mm)

  Still doesn't work with constant 30mm!

Revised approach: Use sliding guide with ±5mm play
  Rod base: 25mm at nominal, varies ±5mm as crank rotates
  Effective length range: 20mm to 30mm

  Status: ✓ PASS with sliding guide bearing

Recommended fix: Implement with sliding bearing/guide block
```

---

## Part 6: Final Checklist

```
[✗] All parts have explicit XYZ positions (no guessing)
    - ISSUE: Pending resolution of collision with frame bounds
    - ISSUE: Slider-crank rod geometry requires sliding guide implementation

[✗] All connections verified (gap = 0)
    - ISSUE: Rod geometry varies from 20mm to 30.4mm (not constant)
    - ISSUE: Requires sliding guide bearing with compliance

[✗] All collisions checked at 4 positions
    - ISSUE: Carrier exceeds frame bounds in X-direction at ±30°
    - ISSUE: Arm exceeds frame bounds in Z-direction

[✗] Linkage lengths verified constant
    - ISSUE: Rod varies ±5mm from nominal 30mm
    - ISSUE: Requires slider bearing with ±5mm play

[✓] All numbers are ACTUAL values, not placeholders
    - ✓ All positions calculated from V56 frame geometry
    - ✓ All dimensions based on existing parts
    - ✓ All angles verified at 4 keyframes

Checklist completed by: Agent 2D
Date: 2026-01-19

STATUS: NOT READY FOR CODE GENERATION

BLOCKING ISSUES (must resolve in DESIGN phase):
  1. Confirm swing axis (Y-only vs 3D swing) → affects frame collision
  2. Reduce swing amplitude to ±20° OR reposition pivot
  3. Implement slider bearing for rod (±5mm compliance)
  4. Recalculate rod geometry for constant-length operation
  5. Verify counterweight balance calculations
```

---

## DESIGN DECISIONS REQUIRED

Before proceeding to code generation, resolve:

1. **Swing Axis Definition**:
   - Option A: Y-only rotation (hinge left-right) → safe at ±30°
   - Option B: 3D swing (all directions) → collides with frame
   - **Recommendation**: Y-only (simpler, matches bird biomechanics)

2. **Frame Collision**:
   - Carrier extends ±40mm at ±30° swing
   - Frame width: 176mm inner
   - **Options**:
     A) Reduce swing to ±20° (±27mm swing = fits safely)
     B) Move pivot left to X=140mm (gives ±40mm swing room)
     C) Reduce carrier width from 60mm to 40mm
   - **Recommendation**: Option A (±20° is still visually prominent)

3. **Slider Bearing Implementation**:
   - Rod must vary 20-30mm as crank rotates
   - Need sliding guide with 5mm play
   - **Recommendation**: Implement as bearing block with clearance bore

4. **Counterweight Verification**:
   - Current specification: 30g at 175mm arm
   - Verify structural load analysis
   - **Recommendation**: FEA simulation or empirical test

