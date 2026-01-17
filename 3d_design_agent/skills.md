# 3D Mechanical Design Agent - Skills Reference

## Overview

This document defines six specialized Skills (slash commands) for the 3D Mechanical Design Agent. These skills enforce mathematical precision and systematic verification for OpenSCAD projects involving kinetic art, gear trains, and mechanical assemblies.

**Core Principle**: NEVER approximate or place components "visually" - ALWAYS calculate mathematically and verify systematically.

---

## SKILL 1: `/gear-calc` - Gear Train Calculator

### Purpose
Calculate precise gear mesh geometry including pitch radii, center distances, and gear ratios. Outputs ready-to-use OpenSCAD code for exact gear placement.

### Why This Matters
Gears that are placed "by eye" or with approximate values will either:
- Bind (too close) - causing friction and motor stall
- Skip teeth (too far) - causing erratic motion and wear
- Run rough (slightly off) - causing noise and premature failure

### Formulas

```
Pitch Radius = (Teeth × Module) / 2
Center Distance = Pitch_Radius_1 + Pitch_Radius_2
Center Distance = (T1 + T2) × Module / 2
Gear Ratio = T_driven / T_driver
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `teeth1` | int | required | Number of teeth on gear 1 (driver) |
| `teeth2` | int | required | Number of teeth on gear 2 (driven) |
| `module` | float | 1.0 | Gear module (tooth size parameter) |
| `pressure_angle` | float | 20 | Pressure angle in degrees |
| `gear1_pos` | [x,y,z] | [0,0,0] | Position of gear 1 center |
| `axis` | string | "x" | Axis along which to place gear 2 ("x", "y", or angle) |

### Output Format

```
============================================================
                    GEAR MESH CALCULATION
============================================================

INPUT:
  Gear 1 (Driver):  T1 = {teeth1} teeth
  Gear 2 (Driven):  T2 = {teeth2} teeth
  Module:           m  = {module} mm
  Pressure Angle:   PA = {pressure_angle} deg

CALCULATED VALUES:
  ┌─────────────────────────────────────────────────────────┐
  │ Gear 1 Pitch Radius:  r1 = T1 × m / 2 = {r1} mm        │
  │ Gear 2 Pitch Radius:  r2 = T2 × m / 2 = {r2} mm        │
  │ Center Distance:      CD = r1 + r2 = {cd} mm           │
  │ Gear Ratio:           GR = T2 / T1 = {ratio}:1         │
  └─────────────────────────────────────────────────────────┘

GEAR 2 POSITION (if Gear 1 at origin along {axis} axis):
  Gear 2 Center: [{x2}, {y2}, {z2}]

OPENSCAD CODE:
------------------------------------------------------------
// Gear parameters - CALCULATED, NOT ESTIMATED
gear1_teeth = {teeth1};
gear2_teeth = {teeth2};
gear_module = {module};

// Pitch radii (for reference/visualization)
gear1_pitch_r = gear1_teeth * gear_module / 2;  // = {r1}
gear2_pitch_r = gear2_teeth * gear_module / 2;  // = {r2}

// Center distance - EXACT FORMULA
center_distance = (gear1_teeth + gear2_teeth) * gear_module / 2;  // = {cd}

// Gear placements
gear1_pos = {gear1_pos};
gear2_pos = gear1_pos + [{cd_vector}];  // = [{x2}, {y2}, {z2}]

// Place gears
translate(gear1_pos) gear(teeth=gear1_teeth, module=gear_module);
translate(gear2_pos) gear(teeth=gear2_teeth, module=gear_module);
------------------------------------------------------------

VERIFICATION:
  [ ] Gears mesh at pitch circles (not tips, not roots)
  [ ] Center distance matches calculated value EXACTLY
  [ ] Gear ratio provides desired speed/torque tradeoff
============================================================
```

### Example Usage

**Command:**
```
/gear-calc teeth1=10 teeth2=60 module=1.5 gear1_pos=[0,0,5] axis=x
```

**Output:**
```
============================================================
                    GEAR MESH CALCULATION
============================================================

INPUT:
  Gear 1 (Driver):  T1 = 10 teeth (Motor Pinion)
  Gear 2 (Driven):  T2 = 60 teeth (Master Gear)
  Module:           m  = 1.5 mm
  Pressure Angle:   PA = 20 deg

CALCULATED VALUES:
  ┌─────────────────────────────────────────────────────────┐
  │ Gear 1 Pitch Radius:  r1 = 10 × 1.5 / 2 = 7.5 mm       │
  │ Gear 2 Pitch Radius:  r2 = 60 × 1.5 / 2 = 45.0 mm      │
  │ Center Distance:      CD = 7.5 + 45.0 = 52.5 mm        │
  │ Gear Ratio:           GR = 60 / 10 = 6:1               │
  └─────────────────────────────────────────────────────────┘

GEAR 2 POSITION (if Gear 1 at [0,0,5] along x axis):
  Gear 2 Center: [52.5, 0, 5]

OPENSCAD CODE:
------------------------------------------------------------
// Gear parameters - CALCULATED, NOT ESTIMATED
pinion_teeth = 10;
master_teeth = 60;
gear_module = 1.5;

// Pitch radii (for reference/visualization)
pinion_pitch_r = pinion_teeth * gear_module / 2;  // = 7.5
master_pitch_r = master_teeth * gear_module / 2;  // = 45.0

// Center distance - EXACT FORMULA
center_distance = (pinion_teeth + master_teeth) * gear_module / 2;  // = 52.5

// Gear placements
pinion_pos = [0, 0, 5];
master_pos = [center_distance, 0, 5];  // = [52.5, 0, 5]

// Place gears
translate(pinion_pos)
    rotate([0, 0, 0])  // Phase adjustment if needed
    spur_gear(modul=gear_module, tooth_number=pinion_teeth, ...);

translate(master_pos)
    rotate([0, 0, 180/master_teeth])  // Mesh alignment
    spur_gear(modul=gear_module, tooth_number=master_teeth, ...);
------------------------------------------------------------
```

### Integration Notes

1. **Always run before placing any gear pair** - never estimate positions
2. **Chain calculations for gear trains** - output position of gear N becomes input for gear N+1
3. **Store calculated values as named constants** - enables parametric updates
4. **Phase adjustment**: For proper mesh, one gear may need rotation of `180/teeth` degrees

---

## SKILL 2: `/linkage-check` - Four-Bar Linkage Validator

### Purpose
Validate four-bar linkage geometry using the Grashof condition, classify linkage type, calculate motion range, and identify potential collision zones.

### Why This Matters
Four-bar linkages have strict geometric requirements:
- Wrong proportions = mechanism locks up or has dead points
- Grashof violation = no link can fully rotate
- Collision zones = physical interference during motion

### Grashof Condition

For a four-bar linkage with link lengths sorted as s (shortest), l (longest), p, q:

```
s + l < p + q  →  Grashof linkage (at least one link can fully rotate)
s + l > p + q  →  Non-Grashof linkage (no link can fully rotate)
s + l = p + q  →  Change-point linkage (special case)
```

### Linkage Classification

| Ground Link | Shortest Link | Type | Motion |
|-------------|---------------|------|--------|
| Adjacent to shortest | Shortest = crank | Crank-Rocker | Input rotates, output oscillates |
| Opposite to shortest | Shortest = coupler | Double-Rocker | Both grounded links oscillate |
| Is the shortest | Shortest = ground | Double-Crank | Both cranks can rotate fully |

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ground` | float | required | Ground link length (fixed frame) |
| `crank` | float | required | Input crank length (driver) |
| `coupler` | float | required | Coupler link length (floating) |
| `rocker` | float | required | Output rocker length (follower) |
| `crank_pivot` | [x,y] | [0,0] | Position of crank pivot (grounded) |
| `rocker_pivot` | [x,y] | [ground,0] | Position of rocker pivot (grounded) |

### Output Format

```
============================================================
                 FOUR-BAR LINKAGE ANALYSIS
============================================================

LINK LENGTHS:
  Ground (L1):  {ground} mm   [Fixed frame]
  Crank (L2):   {crank} mm    [Input/Driver]
  Coupler (L3): {coupler} mm  [Floating link]
  Rocker (L4):  {rocker} mm   [Output/Follower]

SORTED LENGTHS:
  s (shortest): {s} mm  ({s_name})
  l (longest):  {l} mm  ({l_name})
  p:            {p} mm  ({p_name})
  q:            {q} mm  ({q_name})

GRASHOF CONDITION:
  ┌─────────────────────────────────────────────────────────┐
  │ s + l = {s} + {l} = {s_plus_l} mm                       │
  │ p + q = {p} + {q} = {p_plus_q} mm                       │
  │                                                         │
  │ {s_plus_l} {comparison} {p_plus_q}                      │
  │                                                         │
  │ Result: {grashof_result}                                │
  └─────────────────────────────────────────────────────────┘

LINKAGE CLASSIFICATION:
  Type: {linkage_type}
  Behavior: {behavior_description}

MOTION ANALYSIS:
  Crank rotation range:  {crank_range}
  Rocker oscillation:    {rocker_min} deg to {rocker_max} deg
  Transmission angle:    min={trans_min} deg, max={trans_max} deg

  WARNING: Transmission angle < 40 deg causes poor force transmission

COLLISION RISK ZONES:
  {collision_analysis}

ASCII DIAGRAM (Top View):
------------------------------------------------------------
{ascii_diagram}
------------------------------------------------------------

OPENSCAD VERIFICATION CODE:
------------------------------------------------------------
{openscad_code}
------------------------------------------------------------
```

### ASCII Diagram Format

```
Position: Crank at 0 deg

    Rocker Pivot (R)
         *
        /|
       / |  L4={rocker}
      /  |
     /   |
    * ---+--- Coupler Joint
    |    L3={coupler}
    |
    | L2={crank}
    |
    *----*----*
    ^    |    ^
Crank   L1={ground}   Rocker
Pivot               Pivot
(C)                  (R)

Position: Crank at 90 deg
{...similar diagram...}

Position: Crank at 180 deg
{...similar diagram...}
```

### Example Usage

**Command:**
```
/linkage-check ground=50 crank=15 coupler=45 rocker=40
```

**Output:**
```
============================================================
                 FOUR-BAR LINKAGE ANALYSIS
============================================================

LINK LENGTHS:
  Ground (L1):  50 mm   [Fixed frame]
  Crank (L2):   15 mm   [Input/Driver]
  Coupler (L3): 45 mm   [Floating link]
  Rocker (L4):  40 mm   [Output/Follower]

SORTED LENGTHS:
  s (shortest): 15 mm  (Crank)
  l (longest):  50 mm  (Ground)
  p:            40 mm  (Rocker)
  q:            45 mm  (Coupler)

GRASHOF CONDITION:
  ┌─────────────────────────────────────────────────────────┐
  │ s + l = 15 + 50 = 65 mm                                 │
  │ p + q = 40 + 45 = 85 mm                                 │
  │                                                         │
  │ 65 < 85  ✓                                              │
  │                                                         │
  │ Result: GRASHOF LINKAGE - Continuous rotation possible  │
  └─────────────────────────────────────────────────────────┘

LINKAGE CLASSIFICATION:
  Type: CRANK-ROCKER
  Behavior: Crank (input) rotates continuously 360 deg
            Rocker (output) oscillates back and forth

MOTION ANALYSIS:
  Crank rotation range:  0 to 360 deg (continuous)
  Rocker oscillation:    -32.5 deg to +32.5 deg (65 deg total)
  Transmission angle:    min=42 deg, max=138 deg

  ✓ Transmission angles acceptable (> 40 deg)

COLLISION RISK ZONES:
  ✓ No link crossover detected
  ⚠ Coupler passes close to ground at crank=175 deg (clearance: 3.2mm)

ASCII DIAGRAM (Top View, Crank at 0 deg):
------------------------------------------------------------

        [Rocker Pivot]
              * (50, 0)
             /
            / L4=40
           /
          * Coupler Joint (57.3, 28.1)
         /
        / L3=45
       /
      * Crank Pin (15, 0)
     /
    / L2=15
   /
  * Crank Pivot (0, 0)

------------------------------------------------------------
```

### Integration Notes

1. **Run before finalizing any four-bar mechanism**
2. **Check transmission angle** - values below 40 deg mean weak force transmission
3. **Verify at multiple crank positions** - collision may only occur at certain angles
4. **For wave mechanisms**: coupler point trace defines the wave shape

---

## SKILL 3: `/svg-extract` - SVG Coordinate Extractor

### Purpose
Extract REAL coordinate data from SVG files for use in OpenSCAD. Parses path data, calculates bounds, and generates ready-to-use polygon definitions.

### Why This Matters
**NEVER use placeholder shapes.** When an SVG file is specified:
- Extract the actual coordinates from the file
- Use those exact coordinates in OpenSCAD
- Placeholders like `circle(r=10)` are ALWAYS wrong

### Extraction Workflow

```
1. READ    → Load SVG file content
2. PARSE   → Extract path 'd' attributes
3. COUNT   → Report number of paths and points
4. SAMPLE  → Show first/last few coordinates
5. BOUNDS  → Calculate bounding box
6. SCALE   → Apply user-specified scaling
7. OUTPUT  → Generate OpenSCAD polygon code
```

### Bash Commands for Extraction

```bash
# Extract all path data
cat file.svg | grep -oP 'd="[^"]*"'

# Extract viewBox for scaling reference
cat file.svg | grep -oP 'viewBox="[^"]*"'

# Count paths
cat file.svg | grep -c '<path'

# Extract specific path by id
cat file.svg | grep -oP 'id="mypath"[^>]*d="[^"]*"'
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | Path to SVG file |
| `path_id` | string | null | Specific path ID to extract (null = all) |
| `scale` | float | 1.0 | Scale factor to apply |
| `target_width` | float | null | Scale to fit this width |
| `target_height` | float | null | Scale to fit this height |
| `center` | bool | true | Center output at origin |
| `simplify` | float | 0 | Point reduction tolerance (0 = none) |

### Output Format

```
============================================================
                   SVG COORDINATE EXTRACTION
============================================================

SOURCE FILE: {filepath}
EXTRACTION METHOD: bash command parsing

FILE ANALYSIS:
  ┌─────────────────────────────────────────────────────────┐
  │ ViewBox:        {viewbox}                               │
  │ Paths found:    {path_count}                            │
  │ Total points:   {point_count}                           │
  │ Bounding box:   [{min_x}, {min_y}] to [{max_x}, {max_y}]│
  │ Original size:  {width} x {height}                      │
  └─────────────────────────────────────────────────────────┘

PATHS EXTRACTED:
  Path 1: {id1} - {point_count1} points
  Path 2: {id2} - {point_count2} points
  ...

COORDINATE SAMPLES (Path 1):
  First 5 points:  [{x1},{y1}], [{x2},{y2}], ...
  Last 5 points:   [...], [{xn-1},{yn-1}], [{xn},{yn}]

SCALING APPLIED:
  Original bounds: {orig_bounds}
  Scale factor:    {scale}
  Final bounds:    {final_bounds}
  Final size:      {final_width} x {final_height}

OPENSCAD CODE:
------------------------------------------------------------
// Extracted from: {filepath}
// Points: {point_count}, Scale: {scale}
// Bounds: [{min_x}, {min_y}] to [{max_x}, {max_y}]

{path_id}_points = [
    [{x1}, {y1}],
    [{x2}, {y2}],
    [{x3}, {y3}],
    // ... {remaining_count} more points ...
    [{xn}, {yn}]
];

module {path_id}_shape(height=3) {
    linear_extrude(height=height)
        polygon(points={path_id}_points);
}

// Usage:
// {path_id}_shape(height=3);
------------------------------------------------------------

VERIFICATION:
  [ ] Point count matches source ({point_count} points)
  [ ] Bounds are reasonable for design ({final_width} x {final_height})
  [ ] No placeholder shapes used - all real extracted data
============================================================
```

### Example Usage

**Command:**
```
/svg-extract file="wave_pattern.svg" target_width=100 center=true
```

**Output:**
```
============================================================
                   SVG COORDINATE EXTRACTION
============================================================

SOURCE FILE: wave_pattern.svg
EXTRACTION METHOD: bash command parsing

BASH COMMANDS EXECUTED:
  $ cat wave_pattern.svg | grep -oP 'viewBox="[^"]*"'
  viewBox="0 0 200 150"

  $ cat wave_pattern.svg | grep -c '<path'
  2

  $ cat wave_pattern.svg | grep -oP 'd="[^"]*"'
  [extracted path data]

FILE ANALYSIS:
  ┌─────────────────────────────────────────────────────────┐
  │ ViewBox:        0 0 200 150                             │
  │ Paths found:    2                                       │
  │ Total points:   47                                      │
  │ Bounding box:   [10, 20] to [190, 130]                  │
  │ Original size:  180 x 110                               │
  └─────────────────────────────────────────────────────────┘

PATHS EXTRACTED:
  Path 1: wave_outline - 32 points
  Path 2: wave_detail - 15 points

COORDINATE SAMPLES (wave_outline):
  First 5 points:  [10,75], [15,82], [22,88], [30,85], [38,78]
  Last 5 points:   [165,72], [173,78], [180,82], [186,79], [190,75]

SCALING APPLIED:
  Original width:  180
  Target width:    100
  Scale factor:    0.556
  Final size:      100 x 61.1

CENTERING:
  Offset applied:  [-50, -30.6]

OPENSCAD CODE:
------------------------------------------------------------
// Extracted from: wave_pattern.svg
// Points: 32, Scale: 0.556, Centered: true
// Final bounds: [-50, -30.6] to [50, 30.6]

wave_outline_points = [
    [-44.4, 0],
    [-41.7, 3.9],
    [-37.8, 7.2],
    [-33.3, 5.6],
    [-28.9, 1.7],
    // ... 22 more points ...
    [-41.7, -3.9],
    [-44.4, 0]
];

module wave_outline_shape(height=3) {
    linear_extrude(height=height)
        polygon(points=wave_outline_points);
}

// Usage:
// wave_outline_shape(height=3);
------------------------------------------------------------

CRITICAL VERIFICATION:
  ✓ Real coordinates extracted (NOT placeholders)
  ✓ Point count: 32 points from source file
  ✓ Scaling verified: 100mm width as requested
  ✓ Centering verified: bounds symmetric around origin
============================================================
```

### Integration Notes

1. **ALWAYS extract real data** - never substitute with simple shapes
2. **Verify point counts** - if extraction shows 0 points, investigate the SVG structure
3. **Check bounds** - extracted shape should match expected dimensions
4. **Handle complex paths** - SVG may contain curves (beziers) that need linearization
5. **Multiple paths** - extract each path separately for complex designs

---

## SKILL 4: `/component-survival` - Component Checklist Runner

### Purpose
Verify that all required components survive after code modifications. Prevents accidental deletion or loss of critical design elements.

### Why This Matters
During iterative development:
- Components get accidentally deleted
- Copy-paste errors lose sections
- Refactoring breaks references
- "Fixing one thing" breaks another

### Standard Kinetic Art Checklist

```
STRUCTURAL COMPONENTS:
  □ Enclosure base/back wall
  □ Enclosure left wall
  □ Enclosure right wall
  □ Enclosure front (open or frame)
  □ Mounting tabs (foreground side)

DRIVE TRAIN:
  □ Motor mount
  □ Motor body (for visualization)
  □ Pinion gear (on motor shaft)
  □ Master gear (driven by pinion)
  □ Gear center distance = CALCULATED value

MECHANISM:
  □ Four-bar ground link (or enclosure serves this)
  □ Four-bar crank (attached to master gear)
  □ Four-bar coupler (floating link)
  □ Four-bar rocker (if separate from output)
  □ Output element (wave layer, cam, etc.)

CONNECTIONS:
  □ Motor shaft → Pinion (co-axial)
  □ Pinion ↔ Master gear (meshed at calculated distance)
  □ Master gear → Crank (co-axial or attached)
  □ Crank → Coupler (pivot joint)
  □ Coupler → Output (pivot joint)
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to check |
| `checklist` | string | "kinetic_art" | Preset checklist name |
| `custom_items` | array | [] | Additional items to verify |
| `verbose` | bool | false | Show code snippets for each item |

### Output Format

```
============================================================
              COMPONENT SURVIVAL CHECKLIST
============================================================

FILE: {filepath}
CHECKLIST: {checklist_name}
TIMESTAMP: {datetime}

COMPONENT STATUS:
┌─────────────────────────────────────────────────────────────┐
│ Component                    │ Status │ Line  │ Notes      │
├─────────────────────────────────────────────────────────────┤
│ STRUCTURAL                   │        │       │            │
│   Enclosure back wall        │   ✓    │  45   │            │
│   Enclosure left wall        │   ✓    │  52   │            │
│   Enclosure right wall       │   ✓    │  59   │            │
│   Mounting tabs              │   ✓    │  78   │ 2 tabs     │
├─────────────────────────────────────────────────────────────┤
│ DRIVE TRAIN                  │        │       │            │
│   Motor mount                │   ✓    │  95   │            │
│   Pinion gear                │   ✓    │ 102   │ 10T        │
│   Master gear                │   ✓    │ 108   │ 60T        │
│   Gear center distance       │   ✓    │ 100   │ 52.5mm     │
├─────────────────────────────────────────────────────────────┤
│ MECHANISM                    │        │       │            │
│   Four-bar crank             │   ✓    │ 125   │ L=15       │
│   Four-bar coupler           │   ✓    │ 132   │ L=45       │
│   Four-bar rocker            │   ✗    │  --   │ MISSING!   │
│   Wave layer 1               │   ✓    │ 145   │            │
│   Wave layer 2               │   ✓    │ 152   │            │
├─────────────────────────────────────────────────────────────┤
│ CONNECTIONS                  │        │       │            │
│   Motor → Pinion             │   ✓    │ 102   │ same Z     │
│   Pinion ↔ Master mesh       │   ✓    │ 100   │ CD=52.5    │
│   Master → Crank             │   ✓    │ 125   │ same axis  │
│   Crank → Coupler joint      │   ✓    │ 132   │            │
│   Coupler → Output joint     │   ⚠    │ 145   │ check pos  │
└─────────────────────────────────────────────────────────────┘

SUMMARY:
  Total items:    18
  Present (✓):    16
  Missing (✗):    1
  Warnings (⚠):   1

CRITICAL ISSUES:
  ✗ Four-bar rocker - NOT FOUND IN FILE
    Expected: module rocker() or rocker_length definition
    Action: Verify if rocker is integrated into another component
            or if it was accidentally deleted

WARNINGS:
  ⚠ Coupler → Output joint - Position may need verification
    Found at line 145, but coordinates not validated

RECOMMENDATION:
  ▶ STOP - Do not proceed until rocker component is restored
  ▶ Search version history for last known good state
  ▶ Run /version-diff to identify when component was lost
============================================================
```

### Example Usage

**Command:**
```
/component-survival file="kinetic_wave.scad" verbose=true
```

**Output shows each component with its code location and verification status.**

### Integration Notes

1. **Run after EVERY significant edit** - catch losses immediately
2. **Run before committing** - ensure complete state
3. **Add custom items** for project-specific components
4. **Link with /version-diff** to find when components were lost
5. **Treat MISSING as blocking** - do not proceed with incomplete designs

---

## SKILL 5: `/version-diff` - Safe Version Comparison

### Purpose
Compare versions to ensure only intended changes occurred. Verify that modifications follow the formula:

```
V[N] = V[N-1] + (targeted changes) - (nothing else)
```

### Why This Matters
Unintended changes are the #1 cause of design regression:
- "Fixed the gear" but accidentally moved the motor
- "Added a feature" but deleted a wall
- "Cleaned up code" but changed calculated values

### Comparison Methodology

```
1. DIFF      → Generate line-by-line comparison
2. CLASSIFY  → Categorize changes (add/remove/modify)
3. MAP       → Identify which components were affected
4. VERIFY    → Check against stated intent
5. ALERT     → Flag unexpected changes
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file_old` | string | required | Previous version file path |
| `file_new` | string | required | New version file path |
| `intent` | string | "" | Description of intended changes |
| `critical_components` | array | [] | Components that should NOT change |

### Output Format

```
============================================================
                  VERSION COMPARISON REPORT
============================================================

FILES COMPARED:
  Previous: {file_old}
  Current:  {file_new}

STATED INTENT: "{intent}"

CHANGE STATISTICS:
  ┌─────────────────────────────────────────────────────────┐
  │ Lines added:      +{added}                              │
  │ Lines removed:    -{removed}                            │
  │ Lines modified:   ~{modified}                           │
  │ Net change:       {net} lines                           │
  └─────────────────────────────────────────────────────────┘

COMPONENTS AFFECTED:
┌─────────────────────────────────────────────────────────────┐
│ Component              │ Change Type │ Expected? │ Details  │
├─────────────────────────────────────────────────────────────┤
│ gear_module            │ MODIFIED    │    ✓      │ 1.0→1.5  │
│ pinion_teeth           │ UNCHANGED   │    ✓      │ 10       │
│ master_teeth           │ UNCHANGED   │    ✓      │ 60       │
│ center_distance        │ MODIFIED    │    ✓      │ 35→52.5  │
│ motor_position         │ UNCHANGED   │    ✓      │          │
│ enclosure_width        │ MODIFIED    │    ✗      │ 100→95   │ ← UNEXPECTED
│ wave_layer_1           │ DELETED     │    ✗      │          │ ← UNEXPECTED
└─────────────────────────────────────────────────────────────┘

SURVIVAL CHECKLIST IMPACT:
  Components in checklist affected by changes:
  ⚠ enclosure_width - Structural component modified
  ✗ wave_layer_1 - Mechanism component DELETED

DETAILED DIFF (relevant sections):
------------------------------------------------------------
@@ -45,7 +45,7 @@ (Enclosure parameters)
- enclosure_width = 100;
+ enclosure_width = 95;   // ← WHY DID THIS CHANGE?

@@ -142,12 +142,0 @@ (Wave layers)
- // Wave layer 1
- module wave_layer_1() {
-     ...
- }                       // ← ENTIRE MODULE DELETED
------------------------------------------------------------

FORMULA VERIFICATION:
  V[N] = V[N-1] + (targeted changes) - (nothing else)

  Targeted changes (expected):
    ✓ gear_module: 1.0 → 1.5
    ✓ center_distance: 35 → 52.5 (recalculated correctly)

  Unexpected changes (VIOLATIONS):
    ✗ enclosure_width: 100 → 95 (NOT in stated intent)
    ✗ wave_layer_1: DELETED (NOT in stated intent)

RESULT: ✗ CHANGES EXCEED STATED INTENT

RECOMMENDATION:
  ▶ REVERT unexpected changes before proceeding
  ▶ If enclosure_width change was intentional, update intent
  ▶ Restore wave_layer_1 from previous version
  ▶ Re-run /component-survival after corrections
============================================================
```

### Example Usage

**Command:**
```
/version-diff file_old="v1_kinetic.scad" file_new="v2_kinetic.scad" intent="Update gear module from 1.0 to 1.5 and recalculate center distance"
```

### Integration Notes

1. **Run after every save** during development
2. **State intent explicitly** before making changes
3. **Critical components list** should include all checklist items
4. **Zero tolerance for unexpected changes** to critical components
5. **Use with version control** for rollback capability

---

## SKILL 6: `/z-stack` - Z-Layer Collision Analyzer

### Purpose
Analyze Z-axis positioning of all components, identify overlaps in XY projection, calculate clearances, and flag collision risks.

### Why This Matters
3D assemblies require careful Z-stacking:
- Components at same Z with XY overlap = collision
- Insufficient clearance = interference during motion
- Moving parts need extra clearance for dynamics

### Analysis Methodology

```
1. INVENTORY  → List all components with Z positions
2. PROJECT    → Create XY bounding boxes at each Z
3. OVERLAP    → Detect XY overlaps between adjacent Z layers
4. CLEARANCE  → Calculate Z gaps between overlapping components
5. MOTION     → Flag moving parts with insufficient clearance
6. VISUALIZE  → Generate layer diagram
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `file` | string | required | OpenSCAD file to analyze |
| `min_clearance` | float | 0.5 | Minimum acceptable clearance (mm) |
| `motion_clearance` | float | 2.0 | Required clearance for moving parts |
| `show_diagram` | bool | true | Generate ASCII layer diagram |

### Output Format

```
============================================================
                   Z-LAYER COLLISION ANALYSIS
============================================================

FILE: {filepath}
ANALYSIS PARAMETERS:
  Minimum static clearance:  {min_clearance} mm
  Moving part clearance:     {motion_clearance} mm

COMPONENT INVENTORY (sorted by Z):
┌─────────────────────────────────────────────────────────────┐
│ Z Pos  │ Component          │ Height │ Z Range    │ Motion │
├─────────────────────────────────────────────────────────────┤
│  0.0   │ enclosure_base     │  3.0   │  0.0- 3.0  │ static │
│  3.0   │ motor_mount        │  5.0   │  3.0- 8.0  │ static │
│  5.0   │ master_gear        │  4.0   │  5.0- 9.0  │ rotate │
│  5.0   │ pinion_gear        │  4.0   │  5.0- 9.0  │ rotate │
│  9.5   │ crank_arm          │  3.0   │  9.5-12.5  │ rotate │
│ 10.0   │ wave_layer_back    │  2.0   │ 10.0-12.0  │ oscil  │
│ 12.5   │ coupler_link       │  3.0   │ 12.5-15.5  │ complex│
│ 13.0   │ wave_layer_front   │  2.0   │ 13.0-15.0  │ oscil  │
│ 16.0   │ enclosure_top      │  3.0   │ 16.0-19.0  │ static │
└─────────────────────────────────────────────────────────────┘

XY OVERLAP ANALYSIS:
┌─────────────────────────────────────────────────────────────┐
│ Component Pair             │ XY Overlap │ Z Clear │ Status  │
├─────────────────────────────────────────────────────────────┤
│ motor_mount / master_gear  │ partial    │  -3.0   │ ✗ COLL  │
│ master_gear / pinion_gear  │ edge       │   0.0   │ ✓ mesh  │
│ master_gear / crank_arm    │ center     │  +0.5   │ ⚠ tight │
│ crank_arm / wave_layer_back│ partial    │  -2.5   │ ⚠ check │
│ wave_layer_back / coupler  │ partial    │  +0.5   │ ⚠ tight │
│ coupler / wave_layer_front │ partial    │  -2.5   │ ⚠ check │
│ wave_layer_front / top     │ full       │  +1.0   │ ✓ ok    │
└─────────────────────────────────────────────────────────────┘

COLLISION DETAILS:

✗ COLLISION: motor_mount / master_gear
  Motor mount Z range:  3.0 to 8.0
  Master gear Z range:  5.0 to 9.0
  Overlap in Z:         5.0 to 8.0 (3mm interference!)
  XY overlap region:    Yes, gear passes over mount

  RESOLUTION OPTIONS:
  a) Lower motor mount to Z=0 (below gear)
  b) Raise master gear to Z=8.5 (above mount)
  c) Redesign mount to avoid gear sweep area

⚠ WARNING: master_gear / crank_arm (moving parts)
  Clearance: 0.5mm (below {motion_clearance}mm requirement)
  Both parts rotate - dynamic clearance needed

  RECOMMENDATION: Increase crank_arm Z to 10.5 or higher

Z-STACK DIAGRAM (side view, not to scale):
------------------------------------------------------------

Z=19 ┌─────────────────────┐ enclosure_top
     │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
Z=16 └─────────────────────┘
                             ← 1.0mm clearance
Z=15 ┌───────────┐           wave_layer_front
     │░░░░░░░░░░░│ (oscillates)
Z=13 └───────────┘
     ┌─────────────────┐     coupler_link
     │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│ (complex motion)
Z=12.5└────────────────┘
     ┌───────────┐           wave_layer_back
     │░░░░░░░░░░░│ (oscillates)
Z=10 └───────────┘
                             ← 0.5mm clearance (⚠ tight!)
Z=9.5┌─────┐                 crank_arm
     │▒▒▒▒▒│ (rotates)
Z=9  └─────┘═══════════════╗
     ┌─────┐  ┌───────────┐║ master_gear + pinion (mesh)
     │▒▒▒▒▒│──│▒▒▒▒▒▒▒▒▒▒▒│║ (both rotate)
Z=5  └─────┘  └───────────┘╝
     ████████               ← COLLISION ZONE
     ┌──────────────┐        motor_mount
     │██████████████│
Z=3  └──────────────┘
     ┌─────────────────────┐ enclosure_base
     │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
Z=0  └─────────────────────┘

Legend: ▓ static  ░ oscillating  ▒ rotating  █ collision
------------------------------------------------------------

RECOMMENDED Z ADJUSTMENTS:
┌─────────────────────────────────────────────────────────────┐
│ Component          │ Current Z │ New Z │ Reason             │
├─────────────────────────────────────────────────────────────┤
│ motor_mount        │    3.0    │  0.0  │ Clear gear sweep   │
│ crank_arm          │    9.5    │ 10.5  │ Motion clearance   │
│ wave_layer_back    │   10.0    │ 12.0  │ Clear crank motion │
│ coupler_link       │   12.5    │ 14.5  │ Maintain spacing   │
│ wave_layer_front   │   13.0    │ 17.0  │ Clear coupler      │
│ enclosure_top      │   16.0    │ 20.0  │ Clear wave front   │
└─────────────────────────────────────────────────────────────┘

OPENSCAD Z-POSITION CODE:
------------------------------------------------------------
// Z-layer positions (collision-free)
z_base = 0;
z_motor_mount = 0;          // Lowered from 3.0
z_gears = 5;
z_crank = 10.5;             // Raised from 9.5
z_wave_back = 12.0;         // Raised from 10.0
z_coupler = 14.5;           // Raised from 12.5
z_wave_front = 17.0;        // Raised from 13.0
z_top = 20.0;               // Raised from 16.0
------------------------------------------------------------
============================================================
```

### Example Usage

**Command:**
```
/z-stack file="kinetic_wave.scad" min_clearance=0.5 motion_clearance=2.0
```

### Integration Notes

1. **Run after placing components** - verify no collisions
2. **Re-run after ANY position change** - new collisions may appear
3. **Consider motion envelopes** - rotating/oscillating parts sweep areas
4. **Use recommended Z values** - copy directly into code
5. **Verify mesh distances** are maintained after Z adjustments

---

## Workflow Integration

### Recommended Skill Sequence for New Projects

```
1. /svg-extract     → Get real shape data
2. /gear-calc       → Calculate exact gear positions
3. /linkage-check   → Validate mechanism geometry
4. /z-stack         → Verify layer clearances
5. /component-survival → Confirm all parts present
```

### Recommended Skill Sequence for Modifications

```
1. /component-survival (before) → Document current state
2. [Make changes]
3. /version-diff    → Verify only intended changes
4. /component-survival (after)  → Confirm no losses
5. /z-stack         → Re-verify clearances
```

### Error Recovery Workflow

```
If /component-survival shows MISSING:
  1. /version-diff to find when lost
  2. Restore from version history
  3. Re-run /component-survival to confirm

If /z-stack shows COLLISION:
  1. Apply recommended Z adjustments
  2. Re-run /gear-calc if gears affected
  3. Re-run /z-stack to confirm resolution

If /linkage-check shows NON-GRASHOF:
  1. Adjust link lengths
  2. Re-run /linkage-check
  3. Update all dependent positions
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    SKILL QUICK REFERENCE                    │
├─────────────────────────────────────────────────────────────┤
│ /gear-calc teeth1=T1 teeth2=T2 module=M                     │
│   → CD = (T1+T2)*M/2, outputs OpenSCAD placement code       │
│                                                             │
│ /linkage-check ground=G crank=C coupler=L rocker=R          │
│   → Grashof test, type classification, motion range         │
│                                                             │
│ /svg-extract file=PATH target_width=W                       │
│   → Real coordinates, NEVER placeholders                    │
│                                                             │
│ /component-survival file=PATH                               │
│   → Checklist verification, find missing parts              │
│                                                             │
│ /version-diff file_old=V1 file_new=V2 intent="..."          │
│   → Verify V[N] = V[N-1] + (intent) - (nothing)            │
│                                                             │
│ /z-stack file=PATH min_clearance=C                          │
│   → Layer analysis, collision detection, Z recommendations  │
└─────────────────────────────────────────────────────────────┘

GOLDEN RULES:
  ✗ NEVER place gears visually    → ALWAYS /gear-calc first
  ✗ NEVER use placeholder shapes  → ALWAYS /svg-extract real data
  ✗ NEVER assume mechanism works  → ALWAYS /linkage-check
  ✗ NEVER skip verification       → ALWAYS /component-survival
  ✗ NEVER trust "small changes"   → ALWAYS /version-diff
  ✗ NEVER guess Z positions       → ALWAYS /z-stack
```

---

## Document Information

- **Version**: 1.0
- **Created**: For 3D Mechanical Design Agent
- **Scope**: OpenSCAD, kinetic art, mechanical assemblies
- **Principle**: Mathematical precision over visual estimation
