# Universal Kinetic Sculpture Validation Specification
## Date: 2026-03-03
## Status: ACTIVE — All projects must comply

---

## Purpose

One validation script. One interface. Every project. No excuses.

Every CadQuery production script implements 3 standard functions.
VLAD (`tools/vlad.py`) imports the module, runs all applicable checks,
reports PASS/FAIL. Claude cannot deliver code with any FAIL.

---

## Standard Interface Contract

Every production module MUST expose:

```python
def get_fixed_parts() -> dict[str, cq.Workplane]:
    """All geometry that does not move. Keys = part names."""

def get_moving_parts() -> dict[str, tuple[cq.Workplane, str, float, float]]:
    """All geometry that moves during operation.
    Returns: {name: (shape, axis, min_travel, max_travel)}
    axis: 'x', 'y', 'z', or 'rx','ry','rz' for rotation (degrees)
    min_travel/max_travel: displacement range in mm or degrees."""

def get_mechanism_type() -> str:
    """One of: 'slider', 'linkage', 'cam', 'cable', 'gear', 'wave'"""
```

Optional (fires extra checks if present):

```python
def get_clearance_pairs() -> list[tuple[str, str, float]]:
    """(part_a_name, part_b_name, min_gap_mm). Validator checks actual gap >= min_gap."""

def get_assembly() -> cq.Assembly:
    """Full assembly for export integrity checks."""
```

---

## Validation Tiers

### TIER 1: TOPOLOGY — Does the geometry exist correctly?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| T1  | Solid validity         | `.isValid()` on every solid   | Any solid invalid           | YES      |
| T2  | Watertight closure     | Free edge count (OCP edge-face map) | Any free edges (edge in <2 faces) | YES |
| T3  | Single body fusion     | `len(shape.solids().vals())`  | >1 solid per named part     | YES      |
| T4  | Positive volume        | `.Volume() > 0`              | Zero or negative volume     | YES      |
| T5  | No duplicate bodies    | Pairwise volume intersection within same part | Coincident solids | YES |
| T6  | Face count sanity      | Count faces, flag if >1000    | Likely boolean failure      | WARN     |

### TIER 2: DIMENSIONAL — Are the numbers right?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| D1  | Bounding box vs envelope | Compare BB to project envelope | Exceeds allocated space   | YES      |
| D2  | Volume stability       | Compare to stored reference   | >5% drift from reference    | WARN     |
| D3  | Symmetry verification  | Mirror and intersect          | Asymmetric when shouldn't be| WARN     |
| D4  | Aspect ratio sanity    | Max dim / min dim per part    | Ratio > 50:1                | WARN     |

### TIER 3: STATIC INTERFERENCE — Do parts collide at rest?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| S1  | Fixed vs moving (rest) | Boolean intersect each moving part vs all fixed at rest position | Volume > 0.001 mm3 | YES |
| S2  | Adjacent moving parts  | Boolean intersect neighboring moving parts at rest | Volume > 0.001 mm3 | YES |
| S3  | Fixed vs fixed         | Boolean intersect all fixed part pairs | Volume > 0.001 mm3 | YES |

### TIER 4: DYNAMIC INTERFERENCE — Do parts collide during motion?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| K1  | Full-travel collision  | Test at min, 25%, 50%, 75%, max displacement for each moving part vs all fixed | Volume > 0.001 mm3 | YES |
| K2  | Moving vs moving sweep | For each pair of moving parts, test at 5 sample positions | Volume > 0.001 mm3 | YES |
| K3  | Engagement at extremes | At min/max travel, check moving part still overlaps its guide/rail | Overlap volume = 0 | YES |
| K4  | Dead point detection   | For linkages: check transmission angle at 0/90/180/270 | Angle < 40 or > 140 deg | YES (linkage) |
| K5  | Driver tracing         | Every moving part has a physical driver defined | Orphan animation | YES |

### TIER 5: CLEARANCE — Can parts actually move freely?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| C1  | Sliding clearance      | Offset moving part by min_gap, intersect with fixed | Still touching | YES |
| C2  | Rotating clearance     | For shafts/bearings: bore_dia - shaft_dia check | Gap < 0.1mm | YES |
| C3  | User-defined pairs     | From `get_clearance_pairs()`: measure actual gap | Gap < specified min | YES |
| C4  | Assembly feasibility   | Check no part is fully enclosed by others | Trapped part | WARN |

### TIER 6: MANUFACTURABILITY — Can it be made?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| M1  | Min wall thickness     | Ray-cast or section analysis  | Wall < 1.2mm (FDM)         | WARN     |
| M2  | Print envelope fit     | BB vs printer dimensions      | Exceeds bed                 | WARN     |
| M3  | Volume/mass estimate   | Volume * density              | Info only                   | INFO     |

### TIER 7: FUNCTIONAL — Does the mechanism work?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| F1  | Grashof condition      | s+l <= p+q for four-bar       | Cannot complete rotation    | YES (linkage) |
| F2  | Transmission angle     | Check at 0/90/180/270 deg     | < 40 or > 140 deg          | YES (linkage) |
| F3  | Coupler constancy      | Measure coupler at 4 positions | Length varies > 0.1mm      | YES (linkage) |
| F4  | Power budget           | Required torque < available/2  | Underpowered               | WARN     |
| F5  | Friction cascade       | efficiency = 0.95^n           | n > 9 stages               | WARN (cable) |
| F6  | End stop engagement    | At max travel, end stop contacts moving part | No contact | YES (slider) |

### TIER 8: EXPORT INTEGRITY — Is the file usable downstream?

| ID  | Check                  | Method                        | FAIL condition              | Blocking |
|-----|------------------------|-------------------------------|-----------------------------|----------|
| E1  | STEP solid count       | Count solids in exported STEP | Mismatch with expected      | YES      |
| E2  | STEP topology valid    | FreeCAD reimport `.isValid()` | Invalid topology            | YES      |
| E3  | Volume conservation    | CadQuery vol vs reimport vol  | >1% drift                  | WARN     |
| E4  | Assembly completeness  | All named parts present       | Missing component           | YES      |

---

## Applicability Matrix

Not every tier fires for every mechanism. The validator auto-selects based on `get_mechanism_type()`:

| Tier | slider | linkage | cam | cable | gear | wave |
|------|--------|---------|-----|-------|------|------|
| T1 Topology      | YES | YES | YES | YES | YES | YES |
| T2 Dimensional   | YES | YES | YES | YES | YES | YES |
| T3 Static        | YES | YES | YES | YES | YES | YES |
| T4 Dynamic       | YES | YES | YES | YES | YES | YES |
| T5 Clearance     | YES | YES | YES | YES | YES | YES |
| T6 Manufacture   | YES | YES | YES | YES | YES | YES |
| T7-F1 Grashof    | -   | YES | -   | -   | -   | -   |
| T7-F2 TransAngle | -   | YES | -   | -   | -   | -   |
| T7-F3 Coupler    | -   | YES | -   | -   | -   | -   |
| T7-F5 Friction   | -   | -   | -   | YES | -   | -   |
| T7-F6 End stop   | YES | -   | -   | -   | -   | -   |

---

## CLAUDE.md Mandate (exact text)

```
## Validation (MANDATORY)
Every CadQuery production script must implement the standard validation interface
(get_fixed_parts, get_moving_parts, get_mechanism_type — see docs/plans/2026-03-03-universal-validation-spec.md).
Run `python tools/vlad.py <module_name>` after every build. Zero FAILs required before delivery.
```

---

## Rule 99 Mapping

| Rule 99 Consultant      | Validation Tier(s)     |
|--------------------------|------------------------|
| mechanism                | T7: F1, F2, F3         |
| physics                  | T7: F4, F5, K5         |
| kinematic_chain          | T4: K3, K4, K5         |
| vertical_budget          | T2: D1                 |
| collision_enhanced       | T3: S1-S3, T4: K1-K2  |
| iso286                   | T5: C2                 |
| stackup                  | T5: C1, C3             |
| fdm_ground_truth         | T6: M1-M3              |
| freecad_export           | T8: E1-E4              |

## Rule 500 Step Mapping

| Step | Name                  | Tiers Run              |
|------|-----------------------|------------------------|
| 7    | Geometry Validation   | T1, T2                 |
| 13   | Collision Detection   | T3, T4, T5             |
| 14   | Manufacturability     | T6                     |
| 18   | STEP Analysis         | T8                     |
| 20   | CadQuery B-Rep Gen    | T1, T3, T4 (rebuild)   |

---

## Exit Criteria

**Script exits 0** = all blocking checks pass. Claude may deliver.
**Script exits 1** = one or more blocking FAILs. Claude must fix before delivery.
**WARNs** = reported but don't block. User decides.
**INFOs** = metrics only.
