# Universal Kinetic Validation Framework — Full Build Prompt

## Date: 2026-03-04
## Type: Plan-mode session prompt — execute from scratch
## Test data: `3d_design_agent/triple_helix_mvp/5.5/cadquery/matrix_tier_production.py`

---

## HOW TO USE THIS PROMPT

Paste everything below into a new Claude Code session. Enter plan mode. The session should:
1. Read ALL reference documents listed below
2. Produce a plan that covers EVERY feature, requirement, and integration point
3. Implement everything — verify existing code, build missing pieces, fix deviations
4. Validate using the test module (triple helix is test data, NOT the target project)
5. Exit with zero unexpected FAILs

---

# BUILD THE UNIVERSAL KINETIC VALIDATION FRAMEWORK

## VISION

Build a **deterministic, geometry-based validation engine** for kinetic sculpture production scripts.

One script. One interface. Every project. No AI calls. Pure geometry and math.

**The problem it solves:** Claude generates CadQuery production code for kinetic sculptures — mechanisms with moving parts, tolerances, collisions, and manufacturing constraints. Without validation, designs silently break: parts overlap, sliders escape channels, linkages jam at dead points, wall thickness drops below printability. The validator catches ALL of this before delivery.

**The core contract:** Every CadQuery production module implements a standard interface. `validate_kinetic.py` imports the module, builds geometry, runs 35 checks across 8 tiers, reports PASS/FAIL. Claude cannot deliver code with any blocking FAIL.

---

## REFERENCE DOCUMENTS (Read These First)

1. **Spec (source of truth):** `docs/plans/2026-03-03-universal-validation-spec.md`
2. **Current implementation:** `tools/validate_kinetic.py`
3. **Rule 99 config:** `kinetic-forge-studio/backend/data/rule99_config.yaml`
4. **KFS design v2:** `docs/plans/2026-02-23-kinetic-forge-studio-design-v2.md` (Section 6: Validation & Gate Enforcement)
5. **CLAUDE.md mandate:** `CLAUDE.md` (Validation Pipeline section)
6. **Test module:** `3d_design_agent/triple_helix_mvp/5.5/cadquery/matrix_tier_production.py`
7. **Gap analysis (advisory only):** `docs/plans/2026-03-04-universal-validator-completion-prompt.md` — previous audit identified gaps. Use as cross-reference only. Do NOT treat its "23 of 35 done" claim as fact — verify every check yourself.

---

## ARCHITECTURE

### Three-Layer Design

```
Layer 1: validate_kinetic.py (ENGINE — HOW)
  Pure geometry validation. No opinions. Just checks.
  Input: any CadQuery module with standard interface
  Output: PASS/FAIL/WARN/INFO per check + exit code

Layer 2: Rule 99 Consultants (ADVISORY — WHAT)
  Deterministic consultant dispatcher. No AI.
  Maps consultants → validator tiers.
  Tells the engine WHICH checks to run for the current gate level.

Layer 3: Rule 500 Pipeline (ORCHESTRATION — WHEN)
  32-step production pipeline.
  Calls the engine at specific steps with specific tier subsets.
  Gates block advancement until validator passes.
```

**This session builds Layer 1 completely.** Layers 2-3 consume Layer 1 but are built separately.

### Exit Codes

| Code | Meaning | Claude Action |
|------|---------|---------------|
| 0 | All blocking checks pass | May deliver code |
| 1 | One or more blocking FAILs | Must fix before delivery |
| 2 | Fatal error (import failure, missing interface) | Cannot validate |

### Result Levels

| Level | Icon | Meaning | Blocks Delivery |
|-------|------|---------|-----------------|
| PASS | [+] | Check passed | No |
| FAIL | [!] | Blocking failure | YES |
| WARN | [~] | Advisory warning | No (user decides) |
| INFO | [-] | Metric or skipped check | No |

---

## STANDARD INTERFACE CONTRACT

### Required Functions (every production module MUST expose)

```python
def get_fixed_parts() -> dict[str, cq.Workplane]:
    """All geometry that does not move during operation.
    Keys are unique part names. Values are CadQuery Workplane shapes.
    Example: {'housing': housing_shape, 'fp_0': pulley_0, ...}"""

def get_moving_parts() -> dict[str, tuple[cq.Workplane, str, float, float]]:
    """All geometry that moves during operation.
    Returns: {name: (shape, axis, min_travel, max_travel)}
    axis: 'x', 'y', 'z' for linear (mm), 'rx','ry','rz' for rotation (degrees)
    min_travel/max_travel: displacement range from rest position.
    Example: {'slider_ch0': (slider_shape, 'x', -3.84, 0.96)}"""

def get_mechanism_type() -> str:
    """Primary mechanism classification.
    One of: 'slider', 'linkage', 'cam', 'cable', 'gear', 'wave'
    Determines which tier 7 (functional) checks apply."""
```

### Optional Functions (fire extra checks when present)

```python
def get_envelope() -> dict:
    """Project bounding volume. Enables D1 envelope fit check.
    Returns: {'x': max_width_mm, 'y': max_depth_mm, 'z': max_height_mm}"""

def get_clearance_pairs() -> list[tuple[str, str, float]]:
    """Critical clearance specifications. Enables C3 user-defined pairs.
    Returns: [(part_a_name, part_b_name, min_gap_mm), ...]
    Validator measures actual gap and compares to min_gap."""

def get_assembly() -> cq.Assembly:
    """Full CadQuery Assembly object. Enables E4 completeness check.
    Validator verifies all named parts from get_fixed_parts() and
    get_moving_parts() appear in the assembly."""

def get_link_lengths() -> dict:
    """Four-bar linkage dimensions. Enables F1, F2, F3, K4.
    Returns: {'s': shortest, 'l': longest, 'p': third, 'q': fourth}
    All values in mm. Only meaningful for mechanism_type == 'linkage'."""

def get_motor_spec() -> dict:
    """Motor specification. Enables F4 power budget check.
    Returns: {'torque_nm': float, 'speed_rpm': float}"""

def get_cable_stages() -> int:
    """Number of pulley/friction stages. Enables F5 friction cascade.
    Returns: integer count of stages. Only for mechanism_type == 'cable'."""

def get_guide_rails() -> dict[str, cq.Workplane]:
    """Guide/rail geometry for each moving part. Enables K3 engagement.
    Returns: {moving_part_name: guide_rail_shape}
    Validator checks overlap at travel extremes."""

def get_shaft_bore_pairs() -> list[tuple[str, str, float, float]]:
    """Shaft/bore dimensional pairs. Enables C2 rotating clearance.
    Returns: [(shaft_name, bore_name, shaft_dia_mm, bore_dia_mm), ...]"""

def get_reference_volumes() -> dict[str, float]:
    """Baseline volumes for stability tracking. Enables D2 volume stability.
    Returns: {part_name: reference_volume_mm3}"""

def get_symmetry_spec() -> dict:
    """Symmetry requirements. Enables D3 symmetry verification.
    Returns: {'axis': 'x'|'y'|'z', 'parts': ['part1', 'part2', ...]}"""
```

---

## THE 35 CHECKS: Complete Specification

### TIER 1: TOPOLOGY (6 checks) — Does the geometry exist correctly?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| T1 | Solid validity | `.isValid()` on every solid in every named part | Any solid invalid | YES |
| T2 | Watertight closure | OCP edge-face map: count edges belonging to <2 faces (free edges). Fallback: `.isValid()` + `.Volume() > 0` | Any free edges found | YES |
| T3 | Single body fusion | `len(shape.solids().vals())` per named part | >1 solid per named part | YES |
| T4 | Positive volume | `.Volume()` on each part | Zero or negative volume | YES |
| T5 | No duplicate bodies | When T3 detects >1 solid: pairwise boolean intersection between solids within same part | Coincident/overlapping solids (volume > 0.001mm3) | YES |
| T6 | Face count sanity | Count faces per part | >1000 faces (likely boolean failure artifacts) | WARN |

**Implementation notes:**
- T2 uses OCP `TopExp.MapShapesAndAncestors_s()` — the OCCT `Solid.Closed()` flag is unreliable after boolean operations (metadata flag, not computed)
- T5 only fires when T3 already detected multi-body; it distinguishes "separate disconnected bodies" from "overlapping duplicates"
- Run per-part: each named part from `get_fixed_parts()` and `get_moving_parts()` gets all 6 checks

### TIER 2: DIMENSIONAL (4 checks) — Are the numbers right?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| D1 | Bounding box vs envelope | Compute overall BB of all parts, compare to `get_envelope()` | Exceeds allocated space | YES |
| D2 | Volume stability | Compare current volume to `get_reference_volumes()` | >5% drift from reference | WARN |
| D3 | Symmetry verification | Mirror specified parts about specified axis, compute intersection | Asymmetric when spec says symmetric (overlap <95%) | WARN |
| D4 | Aspect ratio sanity | `max_dim / min_dim` per part | Ratio > 50:1 (degenerate geometry) | WARN |

**Implementation notes:**
- D1: If `get_envelope()` not present → report INFO with instruction to implement
- D2: If `get_reference_volumes()` not present → report INFO
- D3: If `get_symmetry_spec()` not present → report INFO
- D4: Handle degenerate dimensions (near-zero) gracefully

### TIER 3: STATIC INTERFERENCE (3 checks) — Do parts collide at rest?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| S1 | Fixed vs moving (rest) | Boolean intersection of each moving part (at rest position, displacement=0) against all fixed parts | Volume > 0.001 mm3 | YES |
| S2 | Adjacent moving parts (rest) | Boolean intersection of all pairwise moving part combinations at rest | Volume > 0.001 mm3 | YES |
| S3 | Fixed vs fixed | Boolean intersection of all pairwise fixed part combinations | Volume > 0.001 mm3 | YES |

**Implementation notes:**
- Use bounding box pre-filter (`bb_overlap()`) to skip 99%+ of pairs before expensive boolean intersection
- `intersection_volume()` helper: `shape_a.intersect(shape_b)` → sum solid volumes → threshold 0.001mm3
- Limit detailed output to first 3-5 collisions; aggregate remainder as "N more collisions"
- Moving parts are tested AS-IS from `get_moving_parts()` (displacement=0 is rest position)

### TIER 4: DYNAMIC INTERFERENCE (5 checks) — Do parts collide during motion?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| K1 | Full-travel collision | For each moving part: displace to 5 positions (min, 25%, 50%, 75%, max), test against ALL fixed parts | Volume > 0.001 mm3 at any position | YES |
| K2 | Moving vs moving sweep | For each pair of moving parts: cartesian product of 5x5 positions, test pairwise | Volume > 0.001 mm3 at any combination | YES |
| K3 | Engagement at extremes | At min/max travel, check each moving part still overlaps its guide/rail from `get_guide_rails()` | Overlap volume = 0 (disengaged from guide) | YES |
| K4 | Dead point detection | For linkages: compute transmission angle at 0, 90, 180, 270 degrees using `get_link_lengths()` | Angle < 40 or > 140 degrees | YES (linkage) |
| K5 | Driver tracing | Every moving part must have valid axis and non-zero travel range | Invalid axis or zero travel (orphan animation) | YES |

**Implementation notes:**
- K1/K2: Use `get_travel_samples(min, max, 5)` helper for evenly-spaced positions
- K1/K2: Use `displace_part(shape, axis, amount)` helper for translation/rotation
- K2: 5x5 cartesian product = 25 checks per pair (not 3x3 = 9)
- K3: Guard with `hasattr(module, 'get_guide_rails')`. If missing → INFO
- K4: Guard with `mechanism_type == 'linkage'` AND `hasattr(module, 'get_link_lengths')`. If missing → INFO
- K5: Validate axis is one of ('x', 'y', 'z', 'rx', 'ry', 'rz') and `abs(max_t - min_t) > 0.001`

### TIER 5: CLEARANCE (4 checks) — Can parts actually move freely?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| C1 | Sliding clearance | Offset each moving part by ±min_gap (0.2mm) along travel axis, intersect with fixed parts | Still touching (overlap > 0) | YES |
| C2 | Rotating clearance | For each pair from `get_shaft_bore_pairs()`: check `bore_dia - shaft_dia` | Gap < 0.1mm | YES |
| C3 | User-defined pairs | For each pair from `get_clearance_pairs()`: measure actual gap using `distToShape()` | Actual gap < specified minimum | YES |
| C4 | Assembly feasibility | Check if any part's bounding box is fully enclosed by a non-housing part | Trapped part (can't be assembled) | WARN |

**Implementation notes:**
- C1: 0.2mm hardcoded as minimum sliding gap (FDM tolerance)
- C2: Guard with `hasattr(module, 'get_shaft_bore_pairs')`. If missing → INFO
- C3: Guard with `hasattr(module, 'get_clearance_pairs')`. If missing → skip entirely (no output)
- C3: Use `shape_a.val().distToShape(shape_b.val())[0]` for actual gap measurement
- C4: Exclude the volumetrically largest part (housing/frame) from "encloser" comparisons — everything inside a housing is expected. Only flag parts enclosed by non-housing parts.

### TIER 6: MANUFACTURABILITY (3 checks) — Can it be 3D printed?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| M1 | Min wall thickness | Section analysis at multiple Z heights per part. Measure minimum wire-to-wire distance | Wall < 1.2mm (FDM minimum) | WARN |
| M2 | Print envelope fit | Bounding box vs printer bed (220x220x250mm default) | Exceeds printer bed | WARN |
| M3 | Volume/mass estimate | Sum all solid volumes × PLA density (1.24 g/cm3) | Info only | INFO |

**Implementation notes:**
- M1: Computationally expensive. Only run when `--full` CLI flag is provided. Without `--full`, report INFO explaining the check was skipped for performance
- M1: Implementation approach: `cq.Workplane.section()` at 5 evenly-spaced Z heights per part, measure minimum distance between wire segments
- M2: Bed size 220x220x250 hardcoded (typical Ender 3 / Prusa)
- M3: PLA density 1.24 g/cm3. Report total volume and estimated mass

### TIER 7: FUNCTIONAL (6 checks) — Does the mechanism actually work?

| ID | Check | Method | FAIL Condition | Blocking | Applies To |
|----|-------|--------|----------------|----------|------------|
| F1 | Grashof condition | `s + l <= p + q` from `get_link_lengths()` | Cannot complete full rotation | YES | linkage |
| F2 | Transmission angle | Compute at 0/90/180/270 deg crank positions | Angle < 40 or > 140 degrees | YES | linkage |
| F3 | Coupler constancy | Measure coupler length at 4 crank positions | Length varies > 0.1mm | YES | linkage |
| F4 | Power budget | Required torque < available/2 from `get_motor_spec()` | Underpowered (required > available/2) | WARN | all (if motor) |
| F5 | Friction cascade | `efficiency = 0.95^n` from `get_cable_stages()` | n > 9 stages (efficiency < 63%) | WARN | cable |
| F6 | End stop engagement | At min/max travel, check if any fixed part intersects the displaced slider | No contact (slider not retained) | YES | slider |

**Implementation notes:**
- F1/F2/F3: Guard with `mechanism_type == 'linkage'` AND `hasattr(module, 'get_link_lengths')`. If mechanism isn't linkage → skip (no output). If linkage but no link lengths → three separate INFO results with instructions
- F1: Classic Grashof check: sort link lengths, verify `shortest + longest <= sum_of_other_two`
- F2: Compute transmission angle `mu = arccos((b^2 + c^2 - a^2 - d^2) / (2*b*c))` at 4 crank positions. Report angle at each position. FAIL if any angle outside 40-140 range
- F3: Forward kinematics at 0, 90, 180, 270 deg crank. Compute coupler length at each. FAIL if variation > 0.1mm
- F4: Guard with `hasattr(module, 'get_motor_spec')`. If missing → INFO
- F5: Guard with `mechanism_type == 'cable'` AND `hasattr(module, 'get_cable_stages')`. If not cable → skip. If cable but no stages → INFO
- F6: Guard with `mechanism_type == 'slider'`. Displace to min/max travel, boolean intersect with all fixed parts. PASS if contact, FAIL if no contact

### TIER 8: EXPORT INTEGRITY (4 checks) — Is the exported file usable?

| ID | Check | Method | FAIL Condition | Blocking |
|----|-------|--------|----------------|----------|
| E1 | STEP solid count | Count solids in all `.step` files in module directory, compare to number of named CadQuery parts | Count mismatch | YES |
| E2 | STEP topology valid | Reimport each STEP file via `cq.importers.importStep()`, check `.isValid()` on all solids | Any invalid solid after reimport | YES |
| E3 | Volume conservation | Compare total CadQuery volume to total STEP reimport volume | Drift > 1% | WARN |
| E4 | Assembly completeness | If `get_assembly()` present: check all named parts appear in assembly | Missing component in assembly | YES |

**Implementation notes:**
- E1: If no STEP files found → WARN (not FAIL — files may not have been exported yet)
- E1: Compute expected count from `len(all_parts)` (fixed + moving)
- E2: Per-file check with per-file result
- E3: Volume drift computed as `abs(step_vol - cq_vol) / cq_vol * 100`
- E4: Guard with `hasattr(module, 'get_assembly')`. If missing → INFO

---

## APPLICABILITY MATRIX

Not every check fires for every mechanism type. The validator MUST auto-select based on `get_mechanism_type()`:

| Check | slider | linkage | cam | cable | gear | wave |
|-------|--------|---------|-----|-------|------|------|
| T1-T6 (Topology) | YES | YES | YES | YES | YES | YES |
| D1-D4 (Dimensional) | YES | YES | YES | YES | YES | YES |
| S1-S3 (Static) | YES | YES | YES | YES | YES | YES |
| K1-K2 (Dynamic) | YES | YES | YES | YES | YES | YES |
| K3 (Engagement) | YES | YES | YES | YES | YES | YES |
| K4 (Dead point) | - | YES | - | - | - | - |
| K5 (Drivers) | YES | YES | YES | YES | YES | YES |
| C1-C4 (Clearance) | YES | YES | YES | YES | YES | YES |
| M1-M3 (Manufact.) | YES | YES | YES | YES | YES | YES |
| F1 (Grashof) | - | YES | - | - | - | - |
| F2 (Trans. angle) | - | YES | - | - | - | - |
| F3 (Coupler) | - | YES | - | - | - | - |
| F4 (Power) | YES | YES | YES | YES | YES | YES |
| F5 (Friction) | - | - | - | YES | - | - |
| F6 (End stop) | YES | - | - | - | - | - |
| E1-E4 (Export) | YES | YES | YES | YES | YES | YES |

**Enforcement:** Non-applicable checks must be SKIPPED entirely (no output, no INFO). Only applicable checks that are missing their optional interface should report INFO.

---

## CLI INTERFACE

### Current Usage
```bash
python tools/validate_kinetic.py <module_path>
```

### Required CLI Features

```bash
# Basic run (all applicable checks except computationally expensive ones)
python tools/validate_kinetic.py path/to/module

# Full run (includes M1 wall thickness analysis)
python tools/validate_kinetic.py --full path/to/module

# JSON output for machine consumption (Rule 99 / Rule 500 integration)
python tools/validate_kinetic.py --json path/to/module

# Override mechanism type (force specific checks)
python tools/validate_kinetic.py --mechanism-type linkage path/to/module
```

### Output Format (human-readable, default)

```
========================================================================
  UNIVERSAL KINETIC SCULPTURE GEOMETRY VALIDATOR
  Module: matrix_tier_production
  Mechanism: slider
  Parts: 143 fixed, 7 moving
========================================================================

--- TIER 1: TOPOLOGY ---
  [+] PASS | T1:housing:valid     | valid=True
  [+] PASS | T2:housing:watertight | watertight=True
  ...

--- TIER 7: FUNCTIONAL ---
  [!] FAIL | F6:slider_ch0:end_stop_min | At min travel (-3.84mm): NO end stop
  ...

========================================================================
  TOTAL: 1068 PASS, 14 FAIL, 2 WARN, 4 INFO
  >>> VERDICT: 14 FAILURE(S) -- FIX REQUIRED
========================================================================
```

### Output Format (JSON, with --json flag)

```json
{
  "module": "matrix_tier_production",
  "mechanism_type": "slider",
  "fixed_parts": 143,
  "moving_parts": 7,
  "verdict": "FAIL",
  "counts": {"pass": 1068, "fail": 14, "warn": 2, "info": 4},
  "checks": [
    {"id": "T1:housing:valid", "status": "PASS", "detail": "valid=True"},
    {"id": "F6:slider_ch0:end_stop_min", "status": "FAIL", "detail": "..."}
  ]
}
```

---

## INTEGRATION ARCHITECTURE

### Rule 99 Consultant → Validator Tier Mapping

| Rule 99 Consultant | Validator Tier IDs |
|--------------------|--------------------|
| mechanism | F1, F2, F3 |
| physics | F4, F5, K5 |
| kinematic_chain | K3, K4, K5 |
| vertical_budget | D1 |
| collision_enhanced | S1, S2, S3, K1, K2 |
| iso286 | C2 |
| stackup | C1, C3 |
| fdm_ground_truth | M1, M2, M3 |
| freecad_export | E1, E2, E3, E4 |

### Rule 500 Pipeline Step → Validator Tier Mapping

| Step | Pipeline Stage | Tiers Run |
|------|----------------|-----------|
| 7 | Geometry Validation | T1, T2 |
| 13 | Collision Detection | T3, T4, T5 |
| 14 | Manufacturability | T6 |
| 18 | STEP Analysis | T8 |
| 20 | CadQuery B-Rep Rebuild | T1, T3, T4 |

### KFS Gate System

| Gate | When | Required Validator Tiers |
|------|------|-------------------------|
| DESIGN | "design locked" | F1-F3, F4, F5, K3-K5, D1 |
| PROTOTYPE | "prototype validated" | S1-S3, K1-K2, C1-C3, M1-M3 |
| PRODUCTION | Export | E1-E4 |

---

## IMPLEMENTATION APPROACH

### Treat As A From-Scratch Build

A file `tools/validate_kinetic.py` exists with partial implementation. **DO NOT assume any of it is correct.** The implementation approach is:

1. **Read the existing file** to understand the current structure and patterns
2. **For EVERY one of the 35 checks:** compare the existing implementation (if any) to the spec above
3. **If the implementation matches the spec exactly:** keep it (retrofit)
4. **If the implementation deviates in ANY way** (wrong threshold, wrong level, wrong logic, wrong guard, wrong output format): **rewrite it to match the spec**
5. **If the check is missing or stubbed:** implement it from scratch per the spec
6. **Do NOT skip any check.** Every single one of the 35 check IDs must be verified against the spec

### Implementation Checklist — ALL 35 Checks

**Each check must be verified or built. Mark each one as you go:**

#### Tier 1: Topology (6 checks)
- [ ] T1 — Solid validity: `.isValid()` per solid, FAIL if invalid
- [ ] T2 — Watertight: OCP edge-face map (NOT `Solid.Closed()`), FAIL if free edges
- [ ] T3 — Single body: solid count per part, FAIL if >1
- [ ] T4 — Positive volume: `.Volume() > 0`, FAIL if not
- [ ] T5 — Duplicate bodies: pairwise intersection within multi-body parts, FAIL if overlap >0.001mm3
- [ ] T6 — Face count: count faces, WARN if >1000

#### Tier 2: Dimensional (4 checks)
- [ ] D1 — Envelope fit: BB vs `get_envelope()`, FAIL if exceeds. INFO if no envelope function
- [ ] D2 — Volume stability: compare to `get_reference_volumes()`, WARN if >5% drift. INFO if no function
- [ ] D3 — Symmetry: mirror+intersect per `get_symmetry_spec()`, WARN if <95% overlap. INFO if no function
- [ ] D4 — Aspect ratio: max_dim/min_dim per part, WARN if >50:1

#### Tier 3: Static Interference (3 checks)
- [ ] S1 — Fixed vs moving at rest: boolean intersection, FAIL if >0.001mm3
- [ ] S2 — Moving vs moving at rest: boolean intersection, FAIL if >0.001mm3
- [ ] S3 — Fixed vs fixed: boolean intersection, FAIL if >0.001mm3

#### Tier 4: Dynamic Interference (5 checks)
- [ ] K1 — Full-travel collision: 5 positions per moving part vs all fixed, FAIL if overlap
- [ ] K2 — Moving vs moving sweep: 5x5 cartesian product per pair, FAIL if overlap
- [ ] K3 — Engagement at extremes: overlap with guide rail at min/max, FAIL if disengaged. INFO if no `get_guide_rails()`
- [ ] K4 — Dead point detection: transmission angle at 4 positions (linkage only), FAIL if <40 or >140 deg. INFO if linkage but no `get_link_lengths()`. SKIP if not linkage
- [ ] K5 — Driver tracing: valid axis + non-zero travel for every moving part, FAIL if invalid

#### Tier 5: Clearance (4 checks)
- [ ] C1 — Sliding clearance: offset by 0.2mm along axis, intersect with fixed, FAIL if touching
- [ ] C2 — Rotating clearance: bore_dia - shaft_dia from `get_shaft_bore_pairs()`, FAIL if <0.1mm. INFO if no function
- [ ] C3 — User-defined pairs: `distToShape()` from `get_clearance_pairs()`, FAIL if gap < min. Skip if no function
- [ ] C4 — Assembly feasibility: trapped part check (exclude housing/largest part), WARN if trapped

#### Tier 6: Manufacturability (3 checks)
- [ ] M1 — Wall thickness: section analysis (only with `--full` flag), WARN if <1.2mm. INFO if --full not set
- [ ] M2 — Print envelope: BB vs 220x220x250mm bed, WARN if exceeds
- [ ] M3 — Mass estimate: volume × 1.24 g/cm3, INFO only

#### Tier 7: Functional (6 checks)
- [ ] F1 — Grashof: s+l <= p+q (linkage only), FAIL if cannot rotate. INFO if linkage but no `get_link_lengths()`. SKIP if not linkage
- [ ] F2 — Transmission angle: at 4 crank positions (linkage only), FAIL if <40 or >140. SKIP if not linkage
- [ ] F3 — Coupler constancy: at 4 positions (linkage only), FAIL if varies >0.1mm. SKIP if not linkage
- [ ] F4 — Power budget: required < available/2 from `get_motor_spec()`, WARN if underpowered. INFO if no function
- [ ] F5 — Friction cascade: 0.95^n from `get_cable_stages()` (cable only), WARN if n>9. SKIP if not cable
- [ ] F6 — End stop engagement: boolean intersect at min/max travel (slider only), FAIL if no contact. SKIP if not slider

#### Tier 8: Export Integrity (4 checks)
- [ ] E1 — STEP solid count: count vs expected, WARN if no STEP files, FAIL if mismatch
- [ ] E2 — STEP topology: reimport + `.isValid()`, FAIL if invalid
- [ ] E3 — Volume conservation: CQ vol vs STEP vol, WARN if >1% drift
- [ ] E4 — Assembly completeness: all parts in `get_assembly()`, FAIL if missing. INFO if no function

### Cross-Cutting Requirements

These apply across ALL checks and must also be verified:

- [ ] **Applicability matrix enforced:** Non-applicable checks produce NO output (not INFO, not SKIP — just nothing). Only applicable checks with missing optional interfaces produce INFO.
- [ ] **Module docstring:** Lists ALL 9 optional interfaces with return types and purpose
- [ ] **CLI `--full` flag:** Gates M1 wall thickness (computationally expensive)
- [ ] **CLI `--json` flag:** Machine-readable JSON output for Rule 99 / Rule 500 integration
- [ ] **CLI `--mechanism-type` flag:** Override mechanism type detection
- [ ] **Bounding box pre-filter:** `bb_overlap()` used before ALL boolean intersections (S1-S3, K1-K2, C1)
- [ ] **Collision threshold:** 0.001mm3 everywhere
- [ ] **Helper functions exist:** `displace_part()`, `get_travel_samples()`, `intersection_volume()`, `bb_overlap()`
- [ ] **Error handling:** Each check wrapped in try/except, reports WARN on error, continues
- [ ] **Output header:** Shows module name, mechanism type, fixed/moving part counts
- [ ] **Exit code:** 0 = all blocking pass, 1 = any blocking FAIL, 2 = fatal error

---

## VERIFICATION

### Run Against Test Module

```bash
python tools/validate_kinetic.py 3d_design_agent/triple_helix_mvp/5.5/cadquery/matrix_tier_production
```

**The test module is a SLIDER mechanism.** Expected results after full implementation:

| Tier | Expected Results |
|------|-----------------|
| T1-T6 | All PASS (geometry is clean) |
| D1 | INFO (no `get_envelope()` in test module) |
| D2 | INFO (no `get_reference_volumes()`) |
| D3 | INFO (no `get_symmetry_spec()`) |
| D4 | All PASS (no degenerate parts) |
| S1-S3 | All PASS (no collisions at rest) |
| K1-K2 | All PASS (no dynamic collisions) |
| K3 | INFO (no `get_guide_rails()`) |
| K4 | SKIPPED (not linkage) — no output |
| K5 | PASS (all parts have valid axis + travel) |
| C1 | All PASS (adequate sliding clearance) |
| C2 | INFO (no `get_shaft_bore_pairs()`) |
| C3 | No output (no `get_clearance_pairs()`) |
| C4 | PASS (no trapped parts, housing excluded) |
| M1 | INFO "skipped — run with --full" OR WARN if walls < 1.2mm |
| M2 | All PASS (parts fit printer bed) |
| M3 | INFO (mass estimate) |
| F1-F3 | SKIPPED (not linkage) — no output |
| F4 | INFO (no `get_motor_spec()`) |
| F5 | SKIPPED (not cable) — no output |
| F6 | 14 FAIL (7 sliders x 2 extremes — known design finding: no physical end stops) |
| E1 | WARN (stale STEP files in directory) |
| E2 | PASS (STEP topology valid) |
| E3 | WARN (volume drift — stale STEP) |
| E4 | INFO (no `get_assembly()`) |

**Only blocking FAILs should be the 14 F6 end-stop findings.** These are a legitimate design issue in the test module, NOT a validator bug.

### Collision Injection Test

After implementation, verify the collision detection is real (not stubbed):
```python
# In test script: shift a slider into the housing wall
slider = module.get_moving_parts()['slider_ch3'][0]
shifted = slider.translate((0, 0, -6))  # Z shift into wall
vol = intersection_volume(housing, shifted)
assert vol > 100, f"Expected collision, got {vol}"
```

### Syntax Check Before Running

```bash
python -c "import ast; ast.parse(open('tools/validate_kinetic.py').read()); print('SYNTAX OK')"
```

---

## CODE QUALITY REQUIREMENTS

1. **Follow existing patterns:** `result.add(check_id, status, detail)` for every check
2. **Check IDs must be spec-compliant:** `T1:{part}:valid`, `F6:{part}:end_stop_min`, etc.
3. **Guard optional interfaces:** `hasattr(module, 'get_xxx')` before calling
4. **Guard mechanism types:** Skip non-applicable checks entirely (no output)
5. **Limit verbose output:** Show first 3-5 failures, aggregate remainder
6. **BB pre-filter:** Always use `bb_overlap()` before boolean intersection
7. **Threshold:** 0.001mm3 for all collision checks
8. **No hardcoded positions:** Use `displace_part()` and `get_travel_samples()` helpers
9. **Error handling:** Catch exceptions in individual checks, report as WARN, continue
10. **Imports:** `import cadquery as cq` at top level. OCP imports in try/except block

---

## DELIVERABLES

At the end of this session, the following must be true:

1. `tools/validate_kinetic.py` implements ALL 35 checks from the spec
2. Applicability matrix is enforced — non-applicable checks produce no output
3. Optional interfaces are documented in docstring and auto-detected
4. `--full` flag enables M1 wall thickness
5. `--json` flag produces machine-readable output
6. Running against test module produces EXACTLY the expected results above
7. The file is syntactically valid Python
8. All changes are committed with a descriptive message
