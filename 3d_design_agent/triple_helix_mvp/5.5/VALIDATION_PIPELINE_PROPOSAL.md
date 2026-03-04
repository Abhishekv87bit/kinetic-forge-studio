# Validation Pipeline Improvement Proposal
## Triple Helix MVP — V5.5

**Date:** 2026-02-17
**Scope:** Six categories of improvement to the existing compile/validate/render pipeline

---

## Current State

The existing pipeline runs three Python scripts plus manual visual inspection:

| Step | Tool | What it checks | Checks |
|------|------|----------------|--------|
| 1 | `openscad.com -o test.csg` | Compile — syntax, include resolution | pass/fail |
| 2 | `validate_geometry.py` | Spatial constraints — bearing axis alignment, Z positions, clearances, parametric chain | ~20 |
| 3 | `v5_5_math_validation.py` | Physics formulas — cam fit, wall thickness, collision budget, assembly stack | 85 |
| 4 | `consistency_audit.py` | Drift — checkpoint sync, cross-file parameter matching, stale comments, orphan includes | 69 |
| 5 | Manual PNG inspection | Visual sanity | human |

**Files under validation:**
- `config_v5_5.scad` (single source of truth, ~462 lines)
- `monolith_v5_5.scad` (frame, ~800+ lines)
- `helix_cam_v5_5.scad` (cam assembly)
- `matrix_stack_v5_5.scad` (matrix tiers)
- `anchor_plate_v5_5.scad` (top plate)
- `guide_plate_v5_5.scad` (bottom plate)

**Include graph:**
```
config_v5_5.scad
  |
  +--- helix_cam_v5_5.scad      (include)
  +--- matrix_stack_v5_5.scad   (include)
  +--- anchor_plate_v5_5.scad   (include)
  +--- guide_plate_v5_5.scad    (include)
  +--- monolith_v5_5.scad       (include config, use helix_cam, use matrix_stack)
```

**Environment:**
- OpenSCAD 2021.01 (CLI: `openscad.com` for console, `openscad.exe` for GUI/render)
- Python 3.x with numpy, scipy, pillow installed
- Windows 11, K2 Plus 350mm build plate
- trimesh, imagehash, pymeshlab NOT currently installed

---

## A. AUTOMATED RENDER COMPARISON

### Problem
Visual inspection is manual and unreliable. Changes that subtly shift geometry (a dampener moving 2mm, a carrier plate rotating) pass math checks but look wrong. Nobody saves reference PNGs, so there is no baseline to compare against.

### Proposed Solution

**Render at known camera angles and animation positions, compare against stored baselines using perceptual hashing.**

#### Camera Angles (6 canonical views)
```python
VIEWS = {
    "iso_front":   "--camera=0,0,0,55,0,25,800",    # standard isometric
    "iso_back":    "--camera=0,0,0,55,0,205,800",   # back isometric
    "top_down":    "--camera=0,0,0,0,0,0,600 --projection=ortho",
    "front":       "--camera=0,0,0,90,0,0,600 --projection=ortho",
    "side":        "--camera=0,0,0,90,0,90,600 --projection=ortho",
    "detail_cam":  "--camera=0,0,0,55,0,25,300",    # close-up on cam area
}
```

#### Animation Positions (4 key positions)
```python
POSITIONS = [0.0, 0.25, 0.5, 0.75]  # maps to 0/90/180/270 degrees
```

#### Comparison Method
Use `imagehash` (Python, pip install) for perceptual hashing with a tunable threshold:

```python
from PIL import Image
import imagehash

def compare_renders(baseline_path, current_path, threshold=8):
    """Returns (match, distance). distance < threshold = match."""
    h1 = imagehash.phash(Image.open(baseline_path), hash_size=16)
    h2 = imagehash.phash(Image.open(current_path), hash_size=16)
    distance = h1 - h2
    return distance < threshold, distance
```

When a regression is detected, also produce a pixel-diff image using Pillow:

```python
from PIL import ImageChops
diff = ImageChops.difference(Image.open(baseline), Image.open(current))
diff.save("diff_output.png")
```

#### Workflow
1. First run: render all views at all positions, store as `baselines/` directory
2. After code change: re-render, compare each against baseline
3. If any exceed threshold: FAIL with diff image showing what changed
4. Deliberate changes: `--update-baselines` flag replaces stored baselines

#### Implementation: `render_regression.py`

```python
# render_regression.py
import subprocess, sys, os
from pathlib import Path
from PIL import Image
import imagehash

OPENSCAD = r"C:\Program Files\OpenSCAD\openscad.exe"
VIEWS = { ... }
POSITIONS = [0.0, 0.25, 0.5, 0.75]
THRESHOLD = 8

def render(scad_file, view_name, camera_args, position, output_dir):
    fname = f"{view_name}_pos{position:.2f}.png"
    out = output_dir / fname
    cmd = [OPENSCAD, camera_args, f"--imgsize=1200,900",
           "--colorscheme=Tomorrow Night",
           f"-D", f"MANUAL_POSITION={position}",
           "-o", str(out), str(scad_file)]
    subprocess.run(cmd, capture_output=True, timeout=120)
    return out

def compare(baseline_dir, current_dir):
    failures = []
    for png in current_dir.glob("*.png"):
        baseline = baseline_dir / png.name
        if not baseline.exists():
            failures.append((png.name, "NO BASELINE"))
            continue
        h1 = imagehash.phash(Image.open(baseline), hash_size=16)
        h2 = imagehash.phash(Image.open(png), hash_size=16)
        dist = h1 - h2
        if dist >= THRESHOLD:
            failures.append((png.name, f"distance={dist}"))
    return failures
```

### Feasibility
- OpenSCAD CLI PNG rendering: fully supported (`openscad.exe -o output.png --camera=...`)
- `imagehash`: pip install, pure Python, lightweight
- `Pillow`: already installed
- OpenSCAD 2021.01 supports all needed flags

### Effort: 4-6 hours
- 2h: write `render_regression.py` with render + compare functions
- 1h: determine optimal camera angles and hash threshold by experiment
- 1h: generate initial baselines for monolith + individual modules
- 1h: integrate into validation pipeline (call from main runner)

### Impact: HIGH
Catches the class of bugs that math checks miss entirely: visual misalignment, parts that look wrong but pass clearance checks, accidental geometry inversion. This is the single most impactful improvement because it covers the "does it look right" question that currently requires a human.

### Priority: 1 (do first)

---

## B. ANIMATION SWEEP VALIDATION

### Problem
Currently checking 4 positions (0/90/180/270 degrees). Real collisions and clearance violations often occur at intermediate angles (e.g., 37 degrees where two followers cross). Missing these means a design that validates but jams when animated.

### Proposed Solution

**Pure Python sweep at 1-degree increments (360 checks per helix), computing clearances analytically from the parametric equations.**

OpenSCAD is too slow for this. Rendering 360 frames would take ~6-12 hours. Instead, replicate the kinematic equations in Python (they are already partially duplicated in `v5_5_math_validation.py`) and sweep analytically.

#### What to Check at Each Angle

1. **Follower-to-follower axial clearance** — Adjacent follower rings must not overlap. At angle `theta` for cam `i`, the follower is at axial position `i * AXIAL_PITCH` and radial position determined by `ECCENTRICITY * cos(theta + i * TWIST_PER_CAM)`. Check that the radial envelope of adjacent followers never intersects.

2. **Slider travel within channel bounds** — For each cam angle, compute the slider displacement = `ECCENTRICITY * cos(theta + i * TWIST_PER_CAM) + SLIDER_REST_OFFSET`. Verify this stays within `[-CH_LEN/2, +CH_LEN/2]` for every channel at every angle.

3. **String tension** — The string path from dampener through pulleys to block must never go slack. At every angle, compute the total string path length change and verify it stays positive (taut).

4. **Cam disc-to-bearing clearance** — Verify the eccentric disc stays within the bearing bore at all angles: `CAM_ECC + DISC_OD/2 < CAM_BRG_ID/2` (this is angle-independent and already checked, but worth including for completeness).

#### Implementation

```python
# sweep_validation.py
import math

def sweep_all_angles(config, step_deg=1):
    """Sweep cam rotation 0..359 degrees, check constraints at each step."""
    failures = []
    for theta in range(0, 360, step_deg):
        for ch in range(config['NUM_CHANNELS']):
            cam_angle = theta + ch * config['TWIST_PER_CAM']
            displacement = config['ECCENTRICITY'] * math.cos(math.radians(cam_angle))
            slider_pos = displacement + config['SLIDER_REST_OFFSET']

            # Check slider within channel bounds
            half_len = config['CH_LENS'][ch] / 2
            if abs(slider_pos) > half_len - 2:  # 2mm safety margin
                failures.append(f"theta={theta} ch={ch}: slider at {slider_pos:.1f}mm "
                              f"exceeds channel half-len {half_len:.1f}mm")

        # Check follower axial spacing (followers on same shaft)
        for i in range(config['NUM_CHANNELS'] - 1):
            # Followers are axially spaced by AXIAL_PITCH
            # but radially displaced by eccentricity at different angles
            # The critical check is radial overlap of follower arms
            angle_i = theta + i * config['TWIST_PER_CAM']
            angle_j = theta + (i+1) * config['TWIST_PER_CAM']
            r_i = config['ECCENTRICITY'] * math.cos(math.radians(angle_i))
            r_j = config['ECCENTRICITY'] * math.cos(math.radians(angle_j))
            # Arms point radially inward; check they don't cross
            # (This is mostly an axial constraint, verified by AXIAL_PITCH > FOLLOWER_RING_H)

    return failures
```

### Feasibility
- Pure Python math, no external dependencies
- The kinematic model is already partially implemented in `v5_5_math_validation.py`
- 360 steps x 9 channels x 3 helixes = ~9720 checks, runs in <1 second

### Effort: 3-4 hours
- 1h: extract kinematic equations from config into reusable Python functions
- 1h: implement sweep loop with all constraint checks
- 1h: test against known-good config, verify no false positives
- 0.5h: integrate into pipeline

### Impact: MEDIUM
The current 4-position check catches most issues because the kinematic model is sinusoidal (smooth, no discontinuities). The sweep adds confidence for edge cases and future config changes where intermediate angles might matter. Highest value when experimenting with new `ECCENTRICITY`, `STACK_OFFSET`, or `SLIDER_BIAS` values.

### Priority: 3

---

## C. PRINT FEASIBILITY CHECKS

### Problem
Currently, print feasibility is checked by manual inspection and a few hardcoded minimum-thickness checks in `v5_5_math_validation.py` (e.g., "wall >= 0.8mm", "carrier >= 5mm"). These don't catch geometric problems like unsupported overhangs in the actual STL mesh, thin features from boolean subtractions, or bridge spans that are too long.

### Proposed Solution

**Two-tier approach: parametric checks (fast, from config) + STL mesh analysis (thorough, from exported STL).**

#### Tier 1: Parametric Checks (extend existing math validation)

Already partially done. Add:

```python
# Additional print feasibility checks for v5_5_math_validation.py

# Minimum wall: 2 perimeters at 0.4mm nozzle = 0.8mm
# Structural wall: 3 perimeters = 1.2mm
NOZZLE_DIA = 0.4
MIN_WALL = 2 * NOZZLE_DIA           # 0.8mm absolute minimum
STRUCTURAL_WALL = 3 * NOZZLE_DIA    # 1.2mm for load-bearing

check("Housing wall printable",
      WALL_THICKNESS >= STRUCTURAL_WALL,
      f"Wall={WALL_THICKNESS}mm (structural min={STRUCTURAL_WALL}mm)")

check("Collar bump printable (height >= layer height)",
      COLLAR_BUMP_H >= 0.2,
      f"Bump H={COLLAR_BUMP_H}mm (min layer=0.2mm)")

check("Collar bump printable (dia >= 2*nozzle)",
      COLLAR_BUMP_DIA >= 2 * NOZZLE_DIA,
      f"Bump dia={COLLAR_BUMP_DIA}mm (min={2*NOZZLE_DIA}mm)")

check("Guide funnel printable as bridge",
      GUIDE_FUNNEL_DIA <= 10,  # PLA bridge limit
      f"Funnel dia={GUIDE_FUNNEL_DIA}mm (bridge limit ~10mm)")

check("Post diameter printable",
      POST_DIA >= 2 * NOZZLE_DIA,
      f"Post={POST_DIA}mm (min={2*NOZZLE_DIA}mm)")
```

#### Tier 2: STL Mesh Analysis (requires trimesh)

Export STL via CLI, then analyze with trimesh:

```python
# print_feasibility.py
import trimesh
import numpy as np

def analyze_stl(stl_path, min_wall=0.8, max_overhang_deg=45):
    mesh = trimesh.load(stl_path)
    results = []

    # 1. Watertight check
    results.append(("Watertight", mesh.is_watertight))

    # 2. Overhang detection
    build_dir = np.array([0, 0, -1])  # Z-up, print from bottom
    normals = mesh.face_normals
    angles = np.degrees(np.arccos(np.clip(
        np.dot(normals, build_dir), -1, 1)))
    overhang_faces = np.sum(angles < (180 - max_overhang_deg))
    overhang_pct = overhang_faces / len(normals) * 100
    results.append(("Overhang faces", overhang_pct < 10,
                    f"{overhang_pct:.1f}% faces > {max_overhang_deg}deg"))

    # 3. Thin feature detection (ray-based thickness)
    # Sample face centers, shoot rays inward along -normal
    centers = mesh.triangles_center
    thickness = trimesh.proximity.thickness(mesh, centers, normals)
    min_thick = np.min(thickness[np.isfinite(thickness)])
    results.append(("Min thickness", min_thick >= min_wall,
                    f"min={min_thick:.2f}mm (limit={min_wall}mm)"))

    # 4. Volume sanity
    results.append(("Volume", mesh.volume > 0,
                    f"{mesh.volume:.1f}mm^3"))

    return results
```

#### STL Export Pipeline Addition

```python
# Add to validation pipeline:
# 1. Export: openscad.com -o monolith_v5_5.stl monolith_v5_5.scad
# 2. Analyze: python print_feasibility.py monolith_v5_5.stl
```

**Key consideration:** STL export from OpenSCAD is SLOW (CGAL full render). The monolith at `$fn=24` might take 5-30 minutes. This should be an opt-in step, not part of the fast validation loop.

### Feasibility
- Tier 1 (parametric): trivially added to existing `v5_5_math_validation.py`, no new deps
- Tier 2 (STL analysis): requires `pip install trimesh` (~5MB), OpenSCAD STL export (slow)
- `trimesh.proximity.thickness()` works but has caveats for complex meshes
- Overhang detection via face normals is straightforward

### Effort
- Tier 1: 1-2 hours (add 10-15 more checks to existing script)
- Tier 2: 6-8 hours (STL export pipeline, trimesh analysis, threshold tuning, handling slow renders)

### Impact
- Tier 1: MEDIUM (catches obvious parametric mistakes, easy wins)
- Tier 2: MEDIUM-LOW for this project (the geometry is relatively simple -- hex extrusions, cylindrical bores -- and most overhang issues are caught by design experience. The slow render time makes this impractical for rapid iteration.)

### Recommendation
Do Tier 1 now (1-2 hours, add parametric checks). Defer Tier 2 until a part actually fails to print, then add targeted STL checks for that failure mode.

### Priority: 4 (Tier 1 now, Tier 2 later)

---

## D. BOM (BILL OF MATERIALS) GENERATION

### Problem
No automated list of purchased components. When preparing to build, you manually scan the .scad files to count bearings, E-clips, string lengths, etc. This is error-prone and annoying.

### Proposed Solution

**Parse the config file and module files to auto-extract all purchased components, compute quantities, and output structured BOM.**

#### Implementation: `bom_generator.py`

```python
# bom_generator.py
"""
Auto-generate Bill of Materials from config_v5_5.scad.
Outputs CSV and formatted text.
"""
import re, csv, math
from pathlib import Path

def generate_bom(config_path):
    """Parse config and compute BOM."""
    # Parse all config values (reuse parse_scad_config from validate_geometry.py)
    config = parse_config(config_path)

    bom = []

    # === BEARINGS ===
    # Frame bearings: MR84ZZ (4x8x3mm) -- 2 per helix x 3 helixes = 6
    bom.append({
        'category': 'Bearing',
        'part': 'MR84ZZ',
        'spec': f"{config['FRAME_BRG_ID']}x{config['FRAME_BRG_OD']}x{config['FRAME_BRG_W']}mm",
        'qty': 6,
        'notes': '2 per helix (near + far carrier plate)'
    })

    # Cam bearings: 6704ZZ (20x27x4mm) -- 1 per cam disc x NUM_CAMS x 3 helixes
    num_cam_bearings = config['NUM_CAMS'] * 3
    bom.append({
        'category': 'Bearing',
        'part': '6704ZZ',
        'spec': f"{config['CAM_BRG_ID']}x{config['CAM_BRG_OD']}x{config['CAM_BRG_W']}mm",
        'qty': num_cam_bearings,
        'notes': f'{config["NUM_CAMS"]} per helix x 3 helixes'
    })

    # === SHAFT ===
    bom.append({
        'category': 'Shaft',
        'part': f'Stainless steel rod {config["SHAFT_DIA"]}mm D-flat',
        'spec': f'{config["SHAFT_DIA"]}mm dia, D-flat {config["D_FLAT_DEPTH"]}mm',
        'qty': 3,
        'notes': f'~{config.get("SHAFT_TOTAL_LENGTH", "TBD")}mm each'
    })

    # === E-CLIPS ===
    bom.append({
        'category': 'Retainer',
        'part': f'E-clip {config["SHAFT_DIA"]}mm shaft',
        'spec': f'Groove dia {config["ECLIP_GROOVE_DIA"]}mm',
        'qty': 6,
        'notes': '2 per shaft (near + far side)'
    })

    # === GT2 PULLEYS ===
    bom.append({
        'category': 'Drive',
        'part': f'GT2 pulley {config["GT2_TEETH"]}T',
        'spec': f'{config["GT2_TEETH"]} teeth, {config["SHAFT_DIA"]}mm bore',
        'qty': 3,
        'notes': '1 per helix shaft (drive side)'
    })

    # === BELT ===
    # Belt length computation would require the full drive path geometry
    bom.append({
        'category': 'Drive',
        'part': 'GT2 belt 6mm',
        'spec': f'2mm pitch, {config["GT2_BELT_W"]}mm wide',
        'qty': 1,
        'notes': 'Length TBD from drive path geometry'
    })

    # === MOTOR ===
    bom.append({
        'category': 'Drive',
        'part': 'DC geared motor',
        'spec': f'{config["MOTOR_BODY_DIA"]}mm dia, {config["MOTOR_SHAFT_DIA"]}mm shaft',
        'qty': 1,
        'notes': 'Low RPM geared motor'
    })

    # === IDLERS ===
    bom.append({
        'category': 'Drive',
        'part': 'GT2 idler (smooth)',
        'spec': f'{config["IDLER_OD"]}mm OD, {config["IDLER_BORE"]}mm bore',
        'qty': 3,
        'notes': 'Belt routing between helixes'
    })

    # === STRING ===
    num_strings = config['NUM_CHANNELS'] * 3  # 9 channels x 3 tiers per string
    string_per = config.get('BLOCK_DROP', 36) + 50  # drop + routing margin
    bom.append({
        'category': 'String',
        'part': f'Braided line {config["STRING_DIA"]}mm',
        'spec': f'{config["STRING_DIA"]}mm diameter',
        'qty': config['NUM_CHANNELS'],
        'notes': f'{num_strings} routes, ~{string_per}mm per block + routing'
    })

    # === BLOCKS ===
    bom.append({
        'category': 'Block',
        'part': 'Hanging block (printed)',
        'spec': f'Drop={config.get("BLOCK_DROP", 36)}mm',
        'qty': config['NUM_CHANNELS'],
        'notes': 'One per channel, all 3 tiers share one string'
    })

    # === ADHESIVE ===
    bom.append({
        'category': 'Consumable',
        'part': 'CA glue (cyanoacrylate)',
        'spec': 'Medium viscosity',
        'qty': 1,
        'notes': 'Collar faces, anchor plate retention'
    })

    return bom

def write_csv(bom, output_path):
    with open(output_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['category','part','spec','qty','notes'])
        w.writeheader()
        w.writerows(bom)

def write_text(bom):
    print(f"{'Category':<12} {'Part':<30} {'Qty':>4}  {'Spec'}")
    print("-" * 80)
    for item in bom:
        print(f"{item['category']:<12} {item['part']:<30} {item['qty']:>4}  {item['spec']}")
```

### Feasibility
- Pure Python, no dependencies beyond stdlib
- Config parsing already exists in `validate_geometry.py` (reuse `parse_scad_config`)
- String/cable lengths require drive path geometry that is partially in the monolith

### Effort: 3-4 hours
- 1h: enumerate all purchased components from config + design knowledge
- 1h: write parser + CSV/text output
- 1h: compute derived quantities (cable lengths, block counts per channel)
- 0.5h: test against current config

### Impact: MEDIUM
Practical for build planning, not for catching bugs. Highest value when preparing a physical prototype build. Prevents "oops, I only ordered 18 cam bearings but need 27" mistakes.

### Priority: 5 (do before first physical build, not urgent for design iteration)

---

## E. DEPENDENCY GRAPH

### Problem
With 6 .scad files and 3 Python validation scripts, it is easy to lose track of which files depend on which, which config parameters flow to which derived values, and whether any parameters are defined but never used (orphans) or used but never defined (dangling references).

### Proposed Solution

**Two tools: (1) file-level include/use graph, (2) parameter dependency DAG.**

#### Tool 1: File Include Graph

```python
# dep_graph.py
import re
from pathlib import Path

def build_include_graph(directory):
    """Scan all .scad files, extract include/use directives, build adjacency list."""
    graph = {}  # file -> [(directive_type, target_file), ...]
    for scad in Path(directory).glob("*.scad"):
        deps = []
        with open(scad, 'r') as f:
            for line in f:
                m = re.match(r'^\s*(include|use)\s*<([^>]+)>', line)
                if m:
                    deps.append((m.group(1), m.group(2)))
        graph[scad.name] = deps
    return graph

def print_graph(graph):
    for source, deps in sorted(graph.items()):
        if deps:
            for dtype, target in deps:
                print(f"  {source} --[{dtype}]--> {target}")
        else:
            print(f"  {source} (no dependencies)")

def check_circular(graph):
    """Detect circular include chains."""
    # Simple DFS cycle detection
    ...
```

This is trivial -- the current `consistency_audit.py` already has `audit_orphan_includes()` which checks that include targets exist. Extending it to a full graph visualization is straightforward.

#### Tool 2: Parameter Dependency DAG

More valuable. Parse config file, identify which parameters depend on which:

```python
def build_param_dag(config_path):
    """Parse config, build DAG of parameter dependencies."""
    assignments = {}  # var_name -> (rhs_expression, [referenced_vars])
    with open(config_path) as f:
        for line in f:
            m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*([^;]+);', line.strip())
            if not m:
                continue
            var_name = m.group(1)
            rhs = m.group(2)
            # Find all variable references in RHS
            refs = re.findall(r'[A-Z_][A-Z0-9_]*', rhs)
            # Filter to only known variables (exclude function names, builtins)
            assignments[var_name] = (rhs, refs)

    # Build DAG
    dag = {}
    for var, (rhs, refs) in assignments.items():
        dag[var] = [r for r in refs if r in assignments and r != var]

    # Find orphans (defined but never referenced by any other variable)
    all_referenced = set()
    for deps in dag.values():
        all_referenced.update(deps)
    orphans = [v for v in dag if v not in all_referenced
               and not v.startswith('C_')  # colors are leaf nodes
               and not v.startswith('SHOW_')]  # toggles are leaf nodes

    # Find roots (no dependencies)
    roots = [v for v, deps in dag.items() if not deps]

    return dag, roots, orphans
```

Output format -- text-based DAG:
```
HEX_R (ROOT)
  +-- HEX_C2C = 2 * HEX_R
  +-- HEX_FF = HEX_R * sqrt(3)
  |     +-- NUM_CHANNELS = f(HEX_FF, STACK_OFFSET)
  |           +-- NUM_CAMS = NUM_CHANNELS
  |                 +-- HELIX_LENGTH = NUM_CAMS * AXIAL_PITCH
  +-- FRAME_RING_R_IN = HEX_R + 2
        +-- POST_NOTCH_R = ...
```

Optional: output Graphviz DOT format for visual rendering:
```python
def write_dot(dag, output_path):
    with open(output_path, 'w') as f:
        f.write("digraph params {\n")
        f.write("  rankdir=LR;\n")
        for var, deps in dag.items():
            for dep in deps:
                f.write(f'  "{dep}" -> "{var}";\n')
        f.write("}\n")
    # Render: dot -Tpng params.dot -o params.png
```

### Feasibility
- Tool 1: trivial regex parsing, already partially done in `consistency_audit.py`
- Tool 2: config parsing already exists; DAG construction is straightforward
- Graphviz (optional) needs separate install for visual output
- Circular dependency detection: simple DFS, standard algorithm

### Effort: 3-4 hours
- 1h: file include graph (extend existing orphan-include check)
- 2h: parameter DAG builder with root/orphan/circular detection
- 0.5h: text output formatter
- 0.5h: optional Graphviz DOT export

### Impact: MEDIUM
Most useful during refactoring (renaming parameters, splitting configs). The parameter DAG directly answers "if I change HEX_R, what else changes?" -- a question you currently answer by grep. Catches orphan parameters that clutter the config.

### Priority: 6 (nice-to-have, not a bug catcher)

---

## F. TOLERANCE STACK ANALYSIS

### Problem
For a chain of mating parts (shaft inside bearing inside mount inside frame), tolerances accumulate. The current approach is manual: you know the shaft is 4.0mm, the bearing bore is 4.0mm, and the clearance is 0.2mm, but you check these individually rather than computing the cumulative stack.

### Proposed Solution

**Define tolerance chains as data, compute worst-case and RSS (root-sum-square) stack-ups automatically.**

#### Tolerance Chain Definition

```python
# tolerance_stacks.py

CHAINS = [
    {
        "name": "Shaft through frame bearing",
        "links": [
            ("Shaft OD",       4.0,  -0.05, +0.0),    # ground to -0.05
            ("MR84ZZ bore",    4.0,  +0.0,  +0.008),  # bearing spec
            ("Press fit",      0.0,  -0.1,  +0.0),    # mount bore undersized
        ],
        "max_clearance": 0.15,  # max acceptable
        "min_clearance": 0.0,   # min acceptable (0 = press fit OK)
    },
    {
        "name": "Cam disc in bearing bore",
        "links": [
            ("Disc OD (printed)", 19.6, -0.2, +0.2),  # FDM tolerance
            ("6704ZZ bore",       20.0, +0.0, +0.012), # bearing spec
        ],
        "max_clearance": 0.8,
        "min_clearance": 0.1,
    },
    {
        "name": "Matrix hex in frame sleeve",
        "links": [
            ("Matrix hex R (printed)", 43.0,  -0.3, +0.3),  # FDM at this scale
            ("Frame ring bore R",      45.0,  -0.2, +0.2),  # FDM
            ("Sleeve clearance",       0.15,  -0.05, +0.05),
        ],
        "max_clearance": 1.0,
        "min_clearance": 0.0,
    },
    {
        "name": "Axial disc-collar stack (full helix)",
        "links": [
            # 9 discs at 5mm + 8 collars at 3mm = 69mm
            # Each disc: +/- 0.1mm (FDM)
            # Each collar: +/- 0.1mm (FDM)
            ("9x disc thick",   45.0, -0.9, +0.9),   # 9 * 5mm, 9 * 0.1mm tol
            ("8x collar thick", 24.0, -0.8, +0.8),   # 8 * 3mm, 8 * 0.1mm tol
        ],
        "max_clearance": 3.0,   # total length variation budget
        "min_clearance": None,   # N/A for length stack
    },
]

def analyze_chain(chain):
    """Compute worst-case and RSS tolerance stack."""
    nominal = sum(link[1] for link in chain['links'])
    worst_neg = sum(link[2] for link in chain['links'])  # all at min
    worst_pos = sum(link[3] for link in chain['links'])  # all at max

    import math
    rss_neg = -math.sqrt(sum(link[2]**2 for link in chain['links']))
    rss_pos = math.sqrt(sum(link[3]**2 for link in chain['links']))

    return {
        'nominal': nominal,
        'worst_case': (nominal + worst_neg, nominal + worst_pos),
        'rss': (nominal + rss_neg, nominal + rss_pos),
    }
```

### Feasibility
- Pure Python, stdlib math only
- The hard part is DEFINING the chains correctly (requires design knowledge)
- The computation is trivial once chains are defined
- FDM tolerances are empirical -- typical values for PLA at 0.2mm layer height are +/-0.2mm for outer dimensions, +/-0.1mm for holes (they shrink)

### Effort: 4-6 hours
- 2h: enumerate all tolerance chains in the design (requires careful design review)
- 1h: implement worst-case and RSS analysis
- 1h: integrate with config values (pull nominal dimensions from config)
- 1h: empirical FDM tolerance lookup table (by feature type and size)

### Impact: MEDIUM-HIGH
Catches the insidious "it validated in software but doesn't assemble" bug. Especially valuable for the axial disc-collar stack (9 discs + 8 collars = 17 parts, each with FDM tolerance) and the matrix-in-frame fit. This is the kind of problem that only shows up when you print.

### Priority: 2 (high value for first physical build)

---

## Summary: Priority-Ordered Recommendations

| Priority | Category | Effort | Impact | When |
|----------|----------|--------|--------|------|
| **1** | A. Render Comparison | 4-6h | HIGH | Now -- catches visual regressions that nothing else catches |
| **2** | F. Tolerance Stack | 4-6h | MED-HIGH | Before first build -- catches assembly-time failures |
| **3** | B. Animation Sweep | 3-4h | MEDIUM | Next iteration -- adds confidence for parameter changes |
| **4** | C. Print Feasibility (Tier 1 only) | 1-2h | MEDIUM | Now -- trivial to add parametric checks |
| **5** | D. BOM Generation | 3-4h | MEDIUM | Before ordering parts |
| **6** | E. Dependency Graph | 3-4h | MEDIUM | During refactoring |

### Quick Wins (do immediately, <2 hours total)

1. Add `pip install imagehash` to the environment
2. Add 10-15 parametric print feasibility checks to `v5_5_math_validation.py` (Tier 1 of C)
3. Generate initial render baselines for the monolith at 4 key positions

### Recommended First Sprint (8-10 hours)

1. Build `render_regression.py` (Category A) -- 5h
2. Add parametric print checks (Category C, Tier 1) -- 1.5h
3. Define the 4-5 critical tolerance chains (Category F) -- 3h

### Deferred

- STL mesh analysis (Category C, Tier 2): wait until a part fails to print
- Full dependency graph visualization (Category E): wait for major refactoring
- BOM generator (Category D): wait until preparing for physical build

---

## Dependencies to Install

```powershell
pip install imagehash   # for render comparison (Category A)
pip install trimesh     # ONLY if doing STL analysis (Category C Tier 2, deferred)
```

No other new dependencies needed. All other tools use stdlib Python (re, math, csv, pathlib, subprocess).

---

## Integration: Unified Pipeline Runner

All tools should be callable from a single entry point:

```python
# run_validation.py
"""
Unified validation pipeline for Triple Helix MVP V5.5.

Usage:
    python run_validation.py                    # fast checks only (compile + math + consistency)
    python run_validation.py --full             # + render comparison + sweep
    python run_validation.py --render-baseline  # generate new baselines
    python run_validation.py --bom              # generate BOM
    python run_validation.py --tolerance        # run tolerance analysis
"""
import sys, subprocess
from pathlib import Path

SCRIPTS = {
    'compile':     ('openscad.com', ['-o', 'test.csg']),
    'geometry':    ('python', ['validate_geometry.py']),
    'math':        ('python', ['v5_5_math_validation.py']),
    'consistency': ('python', ['consistency_audit.py']),
    'render':      ('python', ['render_regression.py']),
    'sweep':       ('python', ['sweep_validation.py']),
    'tolerance':   ('python', ['tolerance_stacks.py']),
    'bom':         ('python', ['bom_generator.py']),
}

FAST = ['compile', 'geometry', 'math', 'consistency']
FULL = FAST + ['render', 'sweep']
```

Exit code: 0 if all pass, 1 if any fail. Each script's output is captured and summarized. Total runtime for FAST pipeline: ~15 seconds. For FULL: ~3-5 minutes (render time).
