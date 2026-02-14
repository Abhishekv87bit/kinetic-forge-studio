# 3D Mechanical Design Agent - Skills Reference v2.0
## World-Class Kinetic Sculpture Design Tools

---

## Overview

This document defines **12 specialized Skills** (slash commands) for the cutting-edge 3D Mechanical Design Agent. These skills enforce mathematical precision, systematic verification, and world-class design methodology for kinetic art, gear trains, and mechanical assemblies.

**Core Principle**: NEVER approximate or place components "visually" - ALWAYS calculate mathematically and verify systematically.

**New in v2.0**: Added 6 skills based on KINETIC_SCULPTURE_COMPENDIUM domains (10-14) for quality, longevity, assembly, and theatrical design.

---

## SKILL CATEGORIES

| Category | Skills | Purpose |
|----------|--------|---------|
| **Calculation** | /gear-calc, /linkage-check, /torque-chain, /balance-check | Mathematical precision |
| **Verification** | /component-survival, /version-diff, /z-stack, /animation-test | Quality assurance |
| **Export** | /svg-extract, /bom-generate | Output generation |
| **Quality** | /quality-audit, /longevity-report | Professional standards |

---

# CATEGORY 1: CALCULATION SKILLS

## SKILL 1: `/gear-calc` - Gear Train Calculator

### Purpose
Calculate precise gear mesh geometry including pitch radii, center distances, and gear ratios. Outputs ready-to-use OpenSCAD code for exact gear placement.

### Formulas

```
Pitch Radius = (Teeth × Module) / 2
Center Distance = Pitch_Radius_1 + Pitch_Radius_2
Center Distance = (T1 + T2) × Module / 2
Gear Ratio = T_driven / T_driver
Output Speed = Input_Speed / Gear_Ratio
Output Torque = Input_Torque × Gear_Ratio × Efficiency
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `teeth1` | int | required | Number of teeth on gear 1 (driver) |
| `teeth2` | int | required | Number of teeth on gear 2 (driven) |
| `module` | float | 1.0 | Gear module (tooth size parameter) |
| `pressure_angle` | float | 20 | Pressure angle in degrees |
| `gear1_pos` | [x,y,z] | [0,0,0] | Position of gear 1 center |
| `axis` | string | "x" | Axis along which to place gear 2 |

### Output Format

```
============================================================
                    GEAR MESH CALCULATION
============================================================

INPUT:
  Gear 1 (Driver):  T1 = {teeth1} teeth
  Gear 2 (Driven):  T2 = {teeth2} teeth
  Module:           m  = {module} mm

CALCULATED VALUES:
  ┌─────────────────────────────────────────────────────────┐
  │ Gear 1 Pitch Radius:  r1 = T1 × m / 2 = {r1} mm        │
  │ Gear 2 Pitch Radius:  r2 = T2 × m / 2 = {r2} mm        │
  │ Center Distance:      CD = r1 + r2 = {cd} mm           │
  │ Gear Ratio:           GR = T2 / T1 = {ratio}:1         │
  │ Minimum Teeth (20°PA): 14 teeth (check undercut)       │
  │ Backlash (3D print):  0.1-0.2mm radial recommended     │
  └─────────────────────────────────────────────────────────┘

QUICK CHECKS (from Compendium QRC-1):
  [ ] Gears spin freely by hand?
  [ ] No clicking or grinding?
  [ ] Teeth fully engage (not just tips)?
  [ ] Backlash consistent around full rotation?

OPENSCAD CODE:
------------------------------------------------------------
// Gear parameters - CALCULATED, NOT ESTIMATED
gear1_teeth = {teeth1};
gear2_teeth = {teeth2};
gear_module = {module};
center_distance = (gear1_teeth + gear2_teeth) * gear_module / 2;
------------------------------------------------------------
============================================================
```

---

## SKILL 2: `/linkage-check` - Four-Bar Linkage Validator

### Purpose
Validate four-bar linkage geometry using the Grashof condition, classify linkage type, calculate motion range, and identify dead points.

### Grashof Condition

```
s + l < p + q  →  Grashof linkage (at least one link can fully rotate)
s + l > p + q  →  Non-Grashof linkage (no link can fully rotate)
s + l = p + q  →  Change-point linkage (special case)
```

### Physical Connection Validation (V54 Lesson)

```
MANDATORY CHECKS (from Compendium QRC-2):
[ ] Coupler START connected to crank pin?
[ ] Coupler END connected to output?
[ ] All intermediate positions reachable?
[ ] No lockup at extreme positions?
[ ] Motion type matches joint type?
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ground` | float | required | Ground link length (fixed frame) |
| `crank` | float | required | Input crank length (driver) |
| `coupler` | float | required | Coupler link length (floating) |
| `rocker` | float | required | Output rocker length (follower) |

### Output Format

```
============================================================
                 FOUR-BAR LINKAGE ANALYSIS
============================================================

GRASHOF CONDITION:
  s + l = {s_plus_l} mm
  p + q = {p_plus_q} mm
  Result: {grashof_result}

LINKAGE CLASSIFICATION:
  Type: {linkage_type}
  Behavior: {behavior_description}

MOTION ANALYSIS:
  Crank rotation range:  {crank_range}
  Transmission angle:    min={trans_min} deg, max={trans_max} deg
  Dead points:           {dead_point_positions}

  WARNING: Transmission angle < 40° or > 140° causes lockup

PHYSICAL CONNECTION TRACE:
  Motor shaft
    ↓ (fixed)
  Crank pivot (ground)
    ↓ (pin joint - rotation)
  Crank arm
    ↓ (pin joint - rotation)
  Coupler
    ↓ (pin joint - rotation)
  Output element

  ✓ All connections valid
============================================================
```

---

## SKILL 3: `/torque-chain` - Torque Flow Analysis (NEW)

### Purpose
Trace torque from motor to output, calculate torque at each stage, estimate efficiency, and validate motor capacity against mechanism load.

### The 10× Rule (from Compendium Domain 2)

```
Design for 10× the load you expect:
- Measure or estimate actual load
- Multiply by 3× for safety factor
- Multiply by 3× for friction you forgot
- Result: 10× initial estimate
```

### Torque Chain Formula

```
Stage Torque = Previous_Torque × Gear_Ratio × Efficiency

Efficiency per stage:
- Spur gears: 95-98%
- Worm gear: 50-90%
- Belt/chain: 95-98%
- Four-bar linkage: 80-95%
- Sliding friction: 70-90%
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to analyze |
| `motor_torque` | float | required | Motor torque in kg·cm or N·mm |
| `motor_speed` | float | required | Motor speed in RPM |

### Output Format

```
============================================================
                    TORQUE CHAIN ANALYSIS
============================================================

MOTOR INPUT:
  Torque: {motor_torque} kg·cm
  Speed:  {motor_speed} RPM

STAGE-BY-STAGE ANALYSIS:
┌─────────────────────────────────────────────────────────────┐
│ Stage              │ Ratio │ Eff  │ Torque   │ Speed       │
├─────────────────────────────────────────────────────────────┤
│ Motor output       │ 1:1   │ 100% │ 0.5 kg·cm│ 100 RPM     │
│ Pinion→Master      │ 1:6   │ 96%  │ 2.88 kg·cm│ 16.7 RPM   │
│ Master→Crank       │ 1:1   │ 95%  │ 2.74 kg·cm│ 16.7 RPM   │
│ Four-bar linkage   │ ~1:1  │ 85%  │ 2.33 kg·cm│ oscil.     │
│ Output mechanism   │ —     │ 80%  │ 1.86 kg·cm│ —          │
└─────────────────────────────────────────────────────────────┘

LOAD ESTIMATION:
  Estimated mechanism load: 0.5 kg·cm
  Available torque:         1.86 kg·cm
  Margin:                   3.7× (OK, should be ≥3×)

ARCHIMEDES CHECK:
  ✓ Torque traced from input to output
  ✓ Each stage is cascaded levers
  ✓ Gears are rotating levers (pitch radius = lever arm)

POWER BUDGET:
  Input power:  {input_power} W
  Output power: {output_power} W
  Overall efficiency: {total_efficiency}%
============================================================
```

---

## SKILL 4: `/balance-check` - Center of Gravity Analysis (NEW)

### Purpose
Calculate center of gravity for mechanism at rest and during motion, assess stability, and recommend counterweights if needed.

### Archimedes Principle

```
x_cg = Σ(mᵢ × xᵢ) / Σ(mᵢ)
y_cg = Σ(mᵢ × yᵢ) / Σ(mᵢ)
z_cg = Σ(mᵢ × zᵢ) / Σ(mᵢ)

For uniform density (3D prints): Use volume instead of mass
For holes/cutouts: Treat as NEGATIVE mass
```

### Stability Conditions

```
CG above pivot → Unstable equilibrium (tips over)
CG at pivot    → Neutral equilibrium (stays where placed)
CG below pivot → Stable equilibrium (returns when disturbed)
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to analyze |
| `material_density` | float | 1.25 | Material density in g/cm³ |
| `check_motion` | bool | true | Analyze CG shift during motion |

### Output Format

```
============================================================
                  CENTER OF GRAVITY ANALYSIS
============================================================

STATIC ANALYSIS (at rest):
  ┌─────────────────────────────────────────────────────────┐
  │ Component          │ Volume  │ Weight │ CG (x,y,z)      │
  ├─────────────────────────────────────────────────────────┤
  │ Base frame         │ 45 cm³  │ 56g    │ (50, 50, 5)     │
  │ Gear assembly      │ 12 cm³  │ 15g    │ (75, 50, 25)    │
  │ Wave mechanism     │ 8 cm³   │ 10g    │ (50, 100, 45)   │
  │ Decorative elements│ 5 cm³   │ 6g     │ (50, 75, 60)    │
  └─────────────────────────────────────────────────────────┘

  COMBINED CG (at rest): ({x_cg}, {y_cg}, {z_cg})
  Total weight: {total_weight} g

STABILITY ASSESSMENT:
  Base footprint: {footprint_x} × {footprint_y} mm
  CG projection:  ({x_cg}, {y_cg})

  ✓ CG within base footprint - STABLE

DYNAMIC ANALYSIS (during motion):
  CG shift range: ±{cg_shift} mm
  Maximum CG position: ({max_x}, {max_y}, {max_z})

  ⚠ CG shifts by {cg_shift}mm during operation
  ⚠ May cause slight rocking if not secured

COUNTERWEIGHT RECOMMENDATION:
  Not required for stability
  Optional: {counterweight}g at ({cx}, {cy}, {cz}) for smoother motion
============================================================
```

---

# CATEGORY 2: VERIFICATION SKILLS

## SKILL 5: `/component-survival` - Component Checklist Runner

### Purpose
Verify that all required components survive after code modifications. Prevents accidental deletion or loss of critical design elements.

### Standard Kinetic Art Checklist

```
STRUCTURAL COMPONENTS:
  □ Enclosure base/back wall
  □ Enclosure side walls
  □ Mounting tabs

DRIVE TRAIN:
  □ Motor mount
  □ Pinion gear (with calculated position)
  □ Master gear (with calculated position)
  □ Gear center distance = CALCULATED value

MECHANISM:
  □ Four-bar linkages (validated connections)
  □ Output elements (waves, figures, etc.)

CONNECTIONS:
  □ All joints physically connected
  □ No "fake" animations (sin/cos without connection)
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to check |
| `checklist` | string | "kinetic_art" | Preset checklist name |
| `custom_items` | array | [] | Additional items to verify |

### Output Format

```
============================================================
              COMPONENT SURVIVAL CHECKLIST
============================================================

FILE: {filepath}
CHECKLIST: {checklist_name}

COMPONENT STATUS:
┌─────────────────────────────────────────────────────────────┐
│ Component                    │ Status │ Line  │ Notes      │
├─────────────────────────────────────────────────────────────┤
│ STRUCTURAL                   │        │       │            │
│   Enclosure back wall        │   ✓    │  45   │            │
│   Motor mount                │   ✓    │  95   │            │
├─────────────────────────────────────────────────────────────┤
│ DRIVE TRAIN                  │        │       │            │
│   Pinion gear                │   ✓    │ 102   │ 10T        │
│   Master gear                │   ✓    │ 108   │ 60T        │
│   Gear center distance       │   ✓    │ 100   │ 52.5mm     │
├─────────────────────────────────────────────────────────────┤
│ MECHANISM                    │        │       │            │
│   Four-bar crank             │   ✓    │ 125   │ Connected  │
│   Four-bar coupler           │   ✓    │ 132   │ Connected  │
│   Wave layers                │   ✓    │ 145   │ 5 layers   │
└─────────────────────────────────────────────────────────────┘

SUMMARY:
  Total items:    {total}
  Present (✓):    {present}
  Missing (✗):    {missing}
  Warnings (⚠):   {warnings}
============================================================
```

---

## SKILL 6: `/version-diff` - Safe Version Comparison

### Purpose
Compare versions to ensure only intended changes occurred. Verify the formula:

```
V[N] = V[N-1] + (targeted changes) - (nothing else)
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file_old` | string | required | Previous version file path |
| `file_new` | string | required | New version file path |
| `intent` | string | "" | Description of intended changes |

### Output Format

```
============================================================
                  VERSION COMPARISON REPORT
============================================================

STATED INTENT: "{intent}"

CHANGE ANALYSIS:
  Lines added:      +{added}
  Lines removed:    -{removed}
  Lines modified:   ~{modified}

COMPONENTS AFFECTED:
┌─────────────────────────────────────────────────────────────┐
│ Component              │ Change Type │ Expected? │ Details  │
├─────────────────────────────────────────────────────────────┤
│ gear_module            │ MODIFIED    │    ✓      │ 1.0→1.5  │
│ center_distance        │ MODIFIED    │    ✓      │ 35→52.5  │
│ wave_layer_1           │ UNCHANGED   │    ✓      │          │
│ enclosure_width        │ MODIFIED    │    ✗      │ UNEXPECTED│
└─────────────────────────────────────────────────────────────┘

FORMULA VERIFICATION:
  ✗ CHANGES EXCEED STATED INTENT

RECOMMENDATION:
  ▶ REVERT unexpected changes before proceeding
============================================================
```

---

## SKILL 7: `/z-stack` - Z-Layer Collision Analyzer

### Purpose
Analyze Z-axis positioning of all components, identify overlaps, calculate clearances, and flag collision risks.

### Clearance Requirements (from Compendium QRC-3)

```
Static clearance:  ≥ 0.3mm (3D printing tolerance)
Moving clearance:  ≥ 2.0mm (dynamic envelope)
Gear mesh:         0.1-0.2mm backlash
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to analyze |
| `min_clearance` | float | 0.3 | Minimum static clearance (mm) |
| `motion_clearance` | float | 2.0 | Required clearance for moving parts |

### Output Format

```
============================================================
                   Z-LAYER COLLISION ANALYSIS
============================================================

COMPONENT INVENTORY (sorted by Z):
┌─────────────────────────────────────────────────────────────┐
│ Z Pos  │ Component          │ Height │ Z Range    │ Motion │
├─────────────────────────────────────────────────────────────┤
│  0.0   │ enclosure_base     │  3.0   │  0.0- 3.0  │ static │
│  5.0   │ master_gear        │  4.0   │  5.0- 9.0  │ rotate │
│  9.5   │ crank_arm          │  3.0   │  9.5-12.5  │ rotate │
└─────────────────────────────────────────────────────────────┘

COLLISION ANALYSIS:
  ✓ No collisions detected
  ⚠ Tight clearance at Z=9.0 (0.5mm between gear and crank)

Z-STACK DIAGRAM (side view):
------------------------------------------------------------
Z=12.5 └─crank_arm─┘
              ← 0.5mm clearance (⚠)
Z=9.0  └─master_gear─┘
Z=5.0  ┌─motor_mount─┐
Z=0.0  └─enclosure_base─┘
------------------------------------------------------------
============================================================
```

---

## SKILL 8: `/animation-test` - Animation Frame Validator (NEW)

### Purpose
Validate animation at multiple $t positions, check for collisions, verify coupler constraints, and detect impossible physics.

### The V53 Disconnect Lesson

```
NEVER animate without physical connection:
- Every sin()/cos() must correspond to a physical crank or cam
- Motion amplitude must match physical stroke/angle limit
- Phase offsets must match physical gear/linkage arrangement
- Coupler lengths must remain CONSTANT (not stretching)
```

### Test Positions

```
$t = 0.00: Initial position, all elements at start
$t = 0.25: Quarter cycle, check intermediate positions
$t = 0.50: Half cycle, maximum excursion point
$t = 0.75: Three-quarter cycle, returning
$t = 1.00: Should match $t = 0.00 exactly
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to test |
| `positions` | array | [0, 0.25, 0.5, 0.75, 1.0] | $t values to test |
| `check_couplers` | bool | true | Verify coupler lengths constant |

### Output Format

```
============================================================
                  ANIMATION FRAME VALIDATION
============================================================

TESTING AT 5 POSITIONS: $t = 0, 0.25, 0.5, 0.75, 1.0

POSITION-BY-POSITION ANALYSIS:
┌─────────────────────────────────────────────────────────────┐
│ $t   │ Collisions │ Min Clear │ Coupler L │ Status         │
├─────────────────────────────────────────────────────────────┤
│ 0.00 │ None       │ 2.3mm     │ 45.0mm    │ ✓ OK           │
│ 0.25 │ None       │ 1.8mm     │ 45.0mm    │ ✓ OK           │
│ 0.50 │ None       │ 0.9mm     │ 45.0mm    │ ⚠ Tight        │
│ 0.75 │ 1 detected │ -0.2mm    │ 45.1mm    │ ✗ COLLISION    │
│ 1.00 │ None       │ 2.3mm     │ 45.0mm    │ ✓ OK           │
└─────────────────────────────────────────────────────────────┘

COLLISION DETAILS:
  At $t = 0.75:
    - crank_arm contacts wave_layer_3
    - Interference: 0.2mm
    - Suggestion: Increase Z separation or reduce crank radius

COUPLER CONSTRAINT CHECK:
  Expected length: 45.0mm (constant)
  Measured range:  45.0mm - 45.1mm
  ⚠ Slight stretch at $t=0.75 (0.1mm) - check connection points

PHYSICAL CONNECTION VERIFICATION:
  ✓ wave_layer_1: driven by coupler_1 via pin joint
  ✓ wave_layer_2: driven by coupler_2 via pin joint
  ✗ wave_layer_3: animated with sin() but NO physical connection!
    → V53 DISCONNECT DETECTED - animation without mechanism

RECOMMENDATION:
  1. Fix collision at $t=0.75
  2. Add physical coupler connection to wave_layer_3
  3. Re-run validation after fixes
============================================================
```

---

# CATEGORY 3: EXPORT SKILLS

## SKILL 9: `/svg-extract` - SVG Coordinate Extractor

### Purpose
Extract REAL coordinate data from SVG files for use in OpenSCAD. **NEVER use placeholder shapes.**

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | Path to SVG file |
| `target_width` | float | null | Scale to fit this width |
| `center` | bool | true | Center output at origin |

### Output Format

```
============================================================
                   SVG COORDINATE EXTRACTION
============================================================

SOURCE FILE: {filepath}

FILE ANALYSIS:
  Paths found:    {path_count}
  Total points:   {point_count}
  Bounding box:   [{min_x}, {min_y}] to [{max_x}, {max_y}]

OPENSCAD CODE:
------------------------------------------------------------
// Extracted from: {filepath}
// Points: {point_count}, Scale: {scale}

wave_outline_points = [
    [{x1}, {y1}],
    [{x2}, {y2}],
    // ... {remaining_count} more points ...
];

module wave_outline_shape(height=3) {
    linear_extrude(height=height)
        polygon(points=wave_outline_points);
}
------------------------------------------------------------

VERIFICATION:
  ✓ Real coordinates extracted (NOT placeholders)
  ✓ Point count: {point_count} points from source file
============================================================
```

---

## SKILL 10: `/bom-generate` - Bill of Materials Generator (NEW)

### Purpose
Generate comprehensive bill of materials including 3D printed parts, hardware, bearings, motor, and fasteners.

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to analyze |
| `include_hardware` | bool | true | Include bolts, nuts, bearings |
| `include_materials` | bool | true | Include filament estimates |

### Output Format

```
============================================================
                   BILL OF MATERIALS
============================================================

PROJECT: {project_name}
VERSION: {version}

3D PRINTED PARTS:
┌─────────────────────────────────────────────────────────────┐
│ Part Name              │ Qty │ Material │ Est. Weight │ Time│
├─────────────────────────────────────────────────────────────┤
│ enclosure_back         │  1  │ PLA      │ 45g         │ 2.5h│
│ enclosure_left         │  1  │ PLA      │ 25g         │ 1.5h│
│ master_gear_60t        │  1  │ PETG     │ 12g         │ 1.0h│
│ pinion_gear_10t        │  1  │ PETG     │ 3g          │ 0.3h│
│ wave_layer (×5)        │  5  │ PLA      │ 8g ea       │ 0.8h│
└─────────────────────────────────────────────────────────────┘

HARDWARE:
┌─────────────────────────────────────────────────────────────┐
│ Item                   │ Qty │ Size     │ Source          │
├─────────────────────────────────────────────────────────────┤
│ Ball bearing           │  6  │ 608 (8mm)│ Amazon/AliExpress│
│ Motor (geared DC)      │  1  │ N20 100RPM│ Amazon          │
│ M3 socket head screw   │ 12  │ M3×10    │ Hardware store  │
│ M3 nut                 │ 12  │ M3       │ Hardware store  │
│ M3 heat-set insert     │  8  │ M3×5     │ McMaster-Carr   │
│ Steel shaft            │  3  │ 3mm×50mm │ Amazon          │
└─────────────────────────────────────────────────────────────┘

CONSUMABLES:
  PLA filament:  ~150g
  PETG filament: ~20g
  PTFE lubricant: Small amount

ESTIMATED TOTAL COST: ${total_cost}

PRINT SETTINGS (from Compendium QRC-3):
  Gears:      0.12mm layer, 4+ perimeters, 50%+ infill
  Structure:  0.2mm layer, 3 perimeters, 20% infill
============================================================
```

---

# CATEGORY 4: QUALITY SKILLS

## SKILL 11: `/quality-audit` - Professional Quality Assessment (NEW)

### Purpose
Run full quality assessment based on Compendium Domain 14 (Perceived Quality) and Domain 12 (Theatrical Kinetics).

### The 3-Second Assessment

```
What experts notice in 3 seconds:
1. Finish quality - Are edges clean? Surfaces smooth?
2. Alignment - Are things parallel that should be? Square?
3. Motion quality - Smooth or jerky? Consistent?
4. Sound - Quiet confidence or grinding struggle?
5. Balance - Does it look stable? Intentional?
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to audit |
| `check_theatrical` | bool | true | Include theatrical assessment |
| `check_finish` | bool | true | Check finish details |

### Output Format

```
============================================================
                  PROFESSIONAL QUALITY AUDIT
============================================================

PROJECT: {project_name}

3-SECOND ASSESSMENT:
┌─────────────────────────────────────────────────────────────┐
│ Criterion              │ Score │ Notes                      │
├─────────────────────────────────────────────────────────────┤
│ Finish quality         │  8/10 │ Edges chamfered, clean     │
│ Alignment precision    │  7/10 │ Slight gap at joint #3     │
│ Motion smoothness      │  9/10 │ No jerk, consistent speed  │
│ Sound quality          │  8/10 │ Soft hum, no grinding      │
│ Visual balance         │  9/10 │ Stable, intentional look   │
└─────────────────────────────────────────────────────────────┘

OVERALL QUALITY SCORE: 82/100 (Professional Grade)

THEATRICAL CHECK (Domain 12):
  Viewing distance:    30-60cm (optimal for 350mm piece)
  Foreground motion:   Waves - fast, attention-grabbing
  Background motion:   Moon - slow, contemplative
  Cycle time:          45 seconds (ideal: 30-90s) ✓
  Discovery moments:   3 identified (bird, rice tube, foam curl)

FINISH DETAILS (Domain 14):
  ✓ All edges chamfered (1mm radius)
  ✓ Visible surfaces sanded to 400 grit
  ⚠ Fastener alignment: 2 of 8 screws slightly off-axis
  ✓ No hot glue visible
  ✓ Wire routing clean

MOTION QUALITY SIGNALS:
  ✓ Smooth acceleration/deceleration
  ✓ Backlash within acceptable limits (0.15mm)
  ✓ No hunting or stutter
  ⚠ Start/stop has slight jerk (add flywheel mass?)

PROFESSIONAL VS AMATEUR:
  This design rates: PROFESSIONAL
  Key strengths: Motion quality, discovery moments
  Areas to improve: Fastener alignment, start/stop smoothness

RECOMMENDATIONS:
  1. Align fasteners consistently (all slots horizontal)
  2. Add 5g flywheel mass to smooth start/stop
  3. Consider side lighting to emphasize motion depth
============================================================
```

---

## SKILL 12: `/longevity-report` - Durability Assessment (NEW)

### Purpose
Assess long-term durability based on Compendium Domain 10 (Longevity Engineering), identify wear surfaces, predict failure points, and recommend maintenance schedule.

### Lessons from Surviving Automata

```
18th-century automata still run because:
1. Oversized components - Built with 10× safety factor
2. Accessible design - Can be disassembled for repair
3. Quality materials - Brass, steel, not plastic
4. Regular maintenance - Professional care every 5-10 years
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to analyze |
| `operation_hours` | float | 8 | Expected hours per day of operation |
| `target_lifespan` | float | 5 | Target lifespan in years |

### Output Format

```
============================================================
                    LONGEVITY REPORT
============================================================

PROJECT: {project_name}
TARGET LIFESPAN: {target_lifespan} years
OPERATION: {operation_hours} hours/day

WEAR SURFACE ANALYSIS:
┌─────────────────────────────────────────────────────────────┐
│ Location             │ Material│ Motion  │ Est. Life │ Risk │
├─────────────────────────────────────────────────────────────┤
│ Pinion teeth         │ PETG    │ Rotate  │ 3-5 years │ Med  │
│ Master gear teeth    │ PETG    │ Rotate  │ 4-6 years │ Low  │
│ Crank pivot bearing  │ Bronze  │ Rotate  │ 10+ years │ Low  │
│ Coupler pin joints   │ PLA/PLA │ Oscil.  │ 1-2 years │ HIGH │
│ Wave slider surfaces │ PLA/PLA │ Slide   │ 2-3 years │ Med  │
└─────────────────────────────────────────────────────────────┘

FAILURE PREDICTION:
  First expected failure: Coupler pin joints (1-2 years)
  Reason: PLA-on-PLA sliding with high cycle count

  RECOMMENDATION:
    - Replace PLA pins with brass or steel
    - Add bronze bushings at pivot points
    - Consider Delrin for high-wear surfaces

LUBRICATION STRATEGY:
  Initial:        Dry PTFE spray on all gear meshes
  After 6 months: Light machine oil if squeaking
  Annual:         Clean and re-apply PTFE

MAINTENANCE SCHEDULE:
┌─────────────────────────────────────────────────────────────┐
│ Interval     │ Task                                         │
├─────────────────────────────────────────────────────────────┤
│ Weekly       │ Visual inspection, dust removal              │
│ Monthly      │ Listen for sound changes, check for drift    │
│ Quarterly    │ Full lubrication, fastener check             │
│ Annually     │ Complete inspection, replace wear parts      │
│ 5 years      │ Full overhaul, consider gear replacement     │
└─────────────────────────────────────────────────────────────┘

MAINTENANCE ACCESS ASSESSMENT:
  ✓ Back panel removable (4 screws)
  ✓ Motor accessible without full disassembly
  ⚠ Coupler pin joints require partial disassembly
  ✗ Wave layer 3 trapped - difficult to replace

DESIGN FOR MAINTAINABILITY RECOMMENDATIONS:
  1. Add access port for coupler inspection
  2. Make wave layers modular for easy replacement
  3. Document assembly sequence for future rebuilds

10-YEAR OPERATION ESTIMATE:
  Total cycles: ~10.5 million (at 40 RPM, 8h/day)
  Parts requiring replacement: Coupler pins (×3), wave layers (×2)
  Estimated maintenance cost: $50-100 over 10 years
============================================================
```

---

## QUICK REFERENCE CARD

```
┌─────────────────────────────────────────────────────────────┐
│                    SKILL QUICK REFERENCE v2.0               │
├─────────────────────────────────────────────────────────────┤
│ CALCULATION SKILLS:                                         │
│   /gear-calc teeth1=T1 teeth2=T2 module=M                   │
│   /linkage-check ground=G crank=C coupler=L rocker=R        │
│   /torque-chain file=PATH motor_torque=T                    │
│   /balance-check file=PATH                                  │
├─────────────────────────────────────────────────────────────┤
│ VERIFICATION SKILLS:                                        │
│   /component-survival file=PATH                             │
│   /version-diff file_old=V1 file_new=V2 intent="..."        │
│   /z-stack file=PATH min_clearance=C                        │
│   /animation-test file=PATH                                 │
├─────────────────────────────────────────────────────────────┤
│ EXPORT SKILLS:                                              │
│   /svg-extract file=PATH target_width=W                     │
│   /bom-generate file=PATH                                   │
├─────────────────────────────────────────────────────────────┤
│ QUALITY SKILLS:                                             │
│   /quality-audit file=PATH                                  │
│   /longevity-report file=PATH target_lifespan=Y             │
└─────────────────────────────────────────────────────────────┘

WORKFLOW: New Project
  1. /svg-extract     → Get real shape data
  2. /gear-calc       → Calculate exact gear positions
  3. /linkage-check   → Validate mechanism geometry
  4. /torque-chain    → Verify motor capacity
  5. /balance-check   → Assess stability
  6. /z-stack         → Verify layer clearances
  7. /animation-test  → Validate all positions
  8. /component-survival → Confirm all parts present
  9. /quality-audit   → Professional assessment
  10./longevity-report→ Durability planning

GOLDEN RULES:
  ✗ NEVER place gears visually    → ALWAYS /gear-calc first
  ✗ NEVER use placeholder shapes  → ALWAYS /svg-extract real data
  ✗ NEVER assume mechanism works  → ALWAYS /linkage-check
  ✗ NEVER animate without physics → ALWAYS /animation-test
  ✗ NEVER skip quality check      → ALWAYS /quality-audit
  ✗ NEVER ignore maintenance      → ALWAYS /longevity-report
```

---

*Document Version: 2.0*
*Created: For Cutting-Edge 3D Mechanical Design Agent*
*Based on: KINETIC_SCULPTURE_COMPENDIUM.md domains 10-14*
*Principle: Mathematical precision + World-class quality*
