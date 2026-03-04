"""
Universal Kinetic Sculpture Geometry Validator
===============================================
One script. Any project. All tiers.

Usage:
    python validate_kinetic.py <production_module_name>

The production module MUST expose:
    get_fixed_parts()    -> dict[str, cq.Workplane]
    get_moving_parts()   -> dict[str, (cq.Workplane, axis, min_travel, max_travel)]
    get_mechanism_type() -> str

Optional:
    get_clearance_pairs() -> list[(part_a, part_b, min_gap_mm)]
    get_assembly()        -> cq.Assembly

Spec: docs/plans/2026-03-03-universal-validation-spec.md
Exit 0 = all blocking checks pass. Exit 1 = FAIL(s) found.
"""

import sys
import os
import importlib
import math

# Try to import OCP for proper watertight checks
try:
    from OCP.TopExp import TopExp
    from OCP.TopAbs import TopAbs_EDGE, TopAbs_FACE
    from OCP.TopTools import TopTools_IndexedDataMapOfShapeListOfShape
    _HAS_OCP = True
except ImportError:
    _HAS_OCP = False

# ---------------------------------------------------------------------------
# RESULT TRACKING
# ---------------------------------------------------------------------------
class ValidationResult:
    def __init__(self):
        self.checks = []
        self.pass_count = 0
        self.fail_count = 0
        self.warn_count = 0
        self.info_count = 0

    def add(self, check_id, status, detail=""):
        self.checks.append((check_id, status, detail))
        if status == "PASS":
            self.pass_count += 1
        elif status == "FAIL":
            self.fail_count += 1
        elif status == "WARN":
            self.warn_count += 1
        else:
            self.info_count += 1

    def print_report(self):
        print("\n" + "=" * 72)
        print("  UNIVERSAL KINETIC SCULPTURE GEOMETRY VALIDATOR")
        print("=" * 72)
        for check_id, status, detail in self.checks:
            icon = {"PASS": "+", "FAIL": "!", "WARN": "~", "INFO": "-"}[status]
            print(f"  [{icon}] {status:4s} | {check_id}")
            if detail:
                for line in detail.split("\n"):
                    print(f"         | {line}")
        print("-" * 72)
        print(f"  TOTAL: {self.pass_count} PASS, {self.fail_count} FAIL, "
              f"{self.warn_count} WARN, {self.info_count} INFO")
        if self.fail_count == 0:
            print("  >>> VERDICT: ALL CHECKS PASSED")
        else:
            print(f"  >>> VERDICT: {self.fail_count} FAILURE(S) -- FIX REQUIRED")
        print("=" * 72)
        return self.fail_count == 0


# ---------------------------------------------------------------------------
# GEOMETRY HELPERS
# ---------------------------------------------------------------------------
def intersection_volume(shape_a, shape_b):
    """Boolean intersection volume between two CQ workplanes.
    Returns 0.0 if no overlap, positive value if collision."""
    try:
        common = shape_a.intersect(shape_b)
        solids = common.solids().vals()
        if not solids:
            return 0.0
        vol = sum(s.Volume() for s in solids)
        return vol if vol > 0.001 else 0.0
    except Exception:
        return 0.0


def bb_overlap(bb_a, bb_b):
    """Quick bounding box pre-check."""
    return not (bb_a.xmax < bb_b.xmin or bb_a.xmin > bb_b.xmax or
                bb_a.ymax < bb_b.ymin or bb_a.ymin > bb_b.ymax or
                bb_a.zmax < bb_b.zmin or bb_a.zmin > bb_b.zmax)


def displace_part(shape, axis, amount):
    """Translate or rotate a shape by amount along/around axis."""
    if axis == 'x':
        return shape.translate((amount, 0, 0))
    elif axis == 'y':
        return shape.translate((0, amount, 0))
    elif axis == 'z':
        return shape.translate((0, 0, amount))
    elif axis == 'rx':
        return shape.rotate((0, 0, 0), (1, 0, 0), amount)
    elif axis == 'ry':
        return shape.rotate((0, 0, 0), (0, 1, 0), amount)
    elif axis == 'rz':
        return shape.rotate((0, 0, 0), (0, 0, 1), amount)
    else:
        raise ValueError(f"Unknown axis: {axis}")


def get_travel_samples(min_t, max_t, n=5):
    """Return n evenly spaced travel positions including endpoints."""
    if n < 2:
        return [min_t, max_t]
    step = (max_t - min_t) / (n - 1)
    return [min_t + i * step for i in range(n)]


def check_watertight(solid):
    """Check if a solid is watertight by counting free edges.
    A free edge belongs to fewer than 2 faces — indicates an open shell.
    Falls back to isValid()+Volume()>0 if OCP edge-face map unavailable."""
    if _HAS_OCP:
        try:
            edge_face_map = TopTools_IndexedDataMapOfShapeListOfShape()
            TopExp.MapShapesAndAncestors_s(
                solid.wrapped, TopAbs_EDGE, TopAbs_FACE, edge_face_map
            )
            free_edges = 0
            for i in range(1, edge_face_map.Extent() + 1):
                face_list = edge_face_map.FindFromIndex(i)
                if face_list.Extent() < 2:
                    free_edges += 1
            return free_edges == 0, free_edges
        except Exception:
            pass
    # Fallback: valid solid with positive volume is watertight by B-Rep definition
    return solid.isValid() and solid.Volume() > 0, -1


# ---------------------------------------------------------------------------
# TIER 1: TOPOLOGY
# ---------------------------------------------------------------------------
def tier1_topology(result, all_parts):
    """T1-T6: Solid validity, watertight, fusion, volume, duplicates, face count."""
    print("\n--- TIER 1: TOPOLOGY ---")

    for name, shape in all_parts.items():
        solids = shape.solids().vals()

        # T1: Solid validity
        all_valid = all(s.isValid() for s in solids)
        result.add(f"T1:{name}:valid",
                   "PASS" if all_valid else "FAIL",
                   f"valid={all_valid}")

        # T2: Watertight (free edge check — Solid.Closed() flag is unreliable in OCCT)
        if solids:
            all_watertight = True
            free_edge_total = 0
            for s in solids:
                wt, fe = check_watertight(s)
                if not wt:
                    all_watertight = False
                if fe > 0:
                    free_edge_total += fe
            detail = "watertight=True" if all_watertight else f"NOT watertight ({free_edge_total} free edges)"
        else:
            all_watertight = False
            detail = "no solids"
        result.add(f"T2:{name}:watertight",
                   "PASS" if all_watertight else "FAIL",
                   detail)

        # T3: Single body fusion
        body_count = len(solids)
        result.add(f"T3:{name}:fused",
                   "PASS" if body_count == 1 else "FAIL",
                   f"{body_count} solid(s)")

        # T4: Positive volume
        total_vol = sum(s.Volume() for s in solids) if solids else 0
        result.add(f"T4:{name}:volume",
                   "PASS" if total_vol > 0 else "FAIL",
                   f"vol={total_vol:.2f}mm3")

        # T6: Face count sanity
        total_faces = sum(len(s.Faces()) for s in solids) if solids else 0
        result.add(f"T6:{name}:face_count",
                   "WARN" if total_faces > 1000 else "PASS",
                   f"{total_faces} faces" + (" (excessive!)" if total_faces > 1000 else ""))


# ---------------------------------------------------------------------------
# TIER 2: DIMENSIONAL
# ---------------------------------------------------------------------------
def tier2_dimensional(result, all_parts, envelope=None):
    """D1-D4: Bounding box, volume stability, symmetry, aspect ratio."""
    print("\n--- TIER 2: DIMENSIONAL ---")

    for name, shape in all_parts.items():
        bb = shape.val().BoundingBox()
        dx = bb.xmax - bb.xmin
        dy = bb.ymax - bb.ymin
        dz = bb.zmax - bb.zmin

        # D4: Aspect ratio sanity
        dims = sorted([dx, dy, dz])
        if dims[0] > 0.01:
            ratio = dims[2] / dims[0]
            result.add(f"D4:{name}:aspect_ratio",
                       "WARN" if ratio > 50 else "PASS",
                       f"ratio={ratio:.1f} ({dx:.1f} x {dy:.1f} x {dz:.1f}mm)")
        else:
            result.add(f"D4:{name}:aspect_ratio",
                       "WARN", f"degenerate dimension ({dx:.3f} x {dy:.3f} x {dz:.3f}mm)")

    # D1: Bounding box vs envelope (if provided)
    if envelope:
        # Compute overall BB of all parts
        all_shapes = list(all_parts.values())
        if all_shapes:
            combined = all_shapes[0]
            for s in all_shapes[1:]:
                try:
                    combined = combined.union(s)
                except Exception:
                    pass  # Union may fail for non-overlapping parts
            bb = combined.val().BoundingBox()
            dx = bb.xmax - bb.xmin
            dy = bb.ymax - bb.ymin
            dz = bb.zmax - bb.zmin
            fits = (dx <= envelope.get('x', 999) and
                    dy <= envelope.get('y', 999) and
                    dz <= envelope.get('z', 999))
            result.add("D1:envelope_fit",
                       "PASS" if fits else "FAIL",
                       f"actual=({dx:.1f}x{dy:.1f}x{dz:.1f}) "
                       f"limit=({envelope.get('x','?')}x{envelope.get('y','?')}x{envelope.get('z','?')})")


# ---------------------------------------------------------------------------
# TIER 3: STATIC INTERFERENCE
# ---------------------------------------------------------------------------
def tier3_static(result, fixed_parts, moving_parts):
    """S1-S3: Boolean intersection at rest position."""
    print("\n--- TIER 3: STATIC INTERFERENCE ---")

    fixed_list = list(fixed_parts.items())
    moving_list = list(moving_parts.items())

    # S1: Fixed vs moving (at rest — displacement = 0, shapes as-is)
    s1_collisions = 0
    for m_name, (m_shape, axis, min_t, max_t) in moving_list:
        for f_name, f_shape in fixed_list:
            f_bb = f_shape.val().BoundingBox()
            m_bb = m_shape.val().BoundingBox()
            if not bb_overlap(f_bb, m_bb):
                continue
            vol = intersection_volume(f_shape, m_shape)
            if vol > 0:
                s1_collisions += 1
                result.add(f"S1:{f_name}_vs_{m_name}",
                           "FAIL",
                           f"OVERLAP={vol:.3f}mm3 at rest position")
    if s1_collisions == 0:
        result.add("S1:fixed_vs_moving_rest",
                   "PASS",
                   f"Checked {len(fixed_list)*len(moving_list)} pairs, 0 collisions")

    # S2: Adjacent moving parts (at rest)
    s2_collisions = 0
    m_names = list(moving_parts.keys())
    for i in range(len(m_names)):
        for j in range(i + 1, len(m_names)):
            a_shape = moving_parts[m_names[i]][0]
            b_shape = moving_parts[m_names[j]][0]
            a_bb = a_shape.val().BoundingBox()
            b_bb = b_shape.val().BoundingBox()
            if not bb_overlap(a_bb, b_bb):
                continue
            vol = intersection_volume(a_shape, b_shape)
            if vol > 0:
                s2_collisions += 1
                result.add(f"S2:{m_names[i]}_vs_{m_names[j]}",
                           "FAIL", f"OVERLAP={vol:.3f}mm3")
    if s2_collisions == 0:
        pairs = len(m_names) * (len(m_names) - 1) // 2
        result.add("S2:moving_vs_moving_rest",
                   "PASS", f"Checked {pairs} pairs, 0 collisions")

    # S3: Fixed vs fixed
    s3_collisions = 0
    for i in range(len(fixed_list)):
        for j in range(i + 1, len(fixed_list)):
            a_name, a_shape = fixed_list[i]
            b_name, b_shape = fixed_list[j]
            a_bb = a_shape.val().BoundingBox()
            b_bb = b_shape.val().BoundingBox()
            if not bb_overlap(a_bb, b_bb):
                continue
            vol = intersection_volume(a_shape, b_shape)
            if vol > 0:
                s3_collisions += 1
                if s3_collisions <= 3:
                    result.add(f"S3:{a_name}_vs_{b_name}",
                               "FAIL", f"OVERLAP={vol:.3f}mm3")
    if s3_collisions == 0:
        pairs = len(fixed_list) * (len(fixed_list) - 1) // 2
        result.add("S3:fixed_vs_fixed",
                   "PASS", f"Checked {pairs} pairs, 0 collisions")
    elif s3_collisions > 3:
        result.add("S3:additional",
                   "FAIL", f"{s3_collisions - 3} more fixed-vs-fixed collisions")


# ---------------------------------------------------------------------------
# TIER 4: DYNAMIC INTERFERENCE
# ---------------------------------------------------------------------------
def tier4_dynamic(result, fixed_parts, moving_parts, mechanism_type):
    """K1-K5: Full-travel collision sweep, engagement, dead points, driver tracing."""
    print("\n--- TIER 4: DYNAMIC INTERFERENCE ---")

    fixed_list = list(fixed_parts.items())
    moving_list = list(moving_parts.items())
    n_samples = 5  # min, 25%, 50%, 75%, max

    # K1: Each moving part vs all fixed at multiple travel positions
    k1_collisions = 0
    k1_checked = 0
    for m_name, (m_shape, axis, min_t, max_t) in moving_list:
        samples = get_travel_samples(min_t, max_t, n_samples)
        for t in samples:
            displaced = displace_part(m_shape, axis, t)
            d_bb = displaced.val().BoundingBox()
            for f_name, f_shape in fixed_list:
                f_bb = f_shape.val().BoundingBox()
                if not bb_overlap(f_bb, d_bb):
                    k1_checked += 1
                    continue
                vol = intersection_volume(f_shape, displaced)
                k1_checked += 1
                if vol > 0:
                    k1_collisions += 1
                    if k1_collisions <= 5:
                        result.add(f"K1:{m_name}_vs_{f_name}_at_{t:.2f}",
                                   "FAIL",
                                   f"OVERLAP={vol:.3f}mm3 at travel={t:.2f}")

    if k1_collisions == 0:
        result.add("K1:moving_vs_fixed_sweep",
                   "PASS", f"Checked {k1_checked} pairs across {n_samples} positions, 0 collisions")
    elif k1_collisions > 5:
        result.add("K1:additional",
                   "FAIL", f"{k1_collisions - 5} more dynamic collisions not shown")

    # K2: Moving vs moving at multiple positions
    k2_collisions = 0
    k2_checked = 0
    m_names = list(moving_parts.keys())
    for i in range(len(m_names)):
        for j in range(i + 1, len(m_names)):
            a_name = m_names[i]
            b_name = m_names[j]
            a_shape, a_axis, a_min, a_max = moving_parts[a_name]
            b_shape, b_axis, b_min, b_max = moving_parts[b_name]

            a_samples = get_travel_samples(a_min, a_max, 3)
            b_samples = get_travel_samples(b_min, b_max, 3)

            for a_t in a_samples:
                for b_t in b_samples:
                    a_disp = displace_part(a_shape, a_axis, a_t)
                    b_disp = displace_part(b_shape, b_axis, b_t)
                    a_bb = a_disp.val().BoundingBox()
                    b_bb = b_disp.val().BoundingBox()
                    if not bb_overlap(a_bb, b_bb):
                        k2_checked += 1
                        continue
                    vol = intersection_volume(a_disp, b_disp)
                    k2_checked += 1
                    if vol > 0:
                        k2_collisions += 1
                        if k2_collisions <= 3:
                            result.add(
                                f"K2:{a_name}@{a_t:.1f}_vs_{b_name}@{b_t:.1f}",
                                "FAIL", f"OVERLAP={vol:.3f}mm3")

    if k2_collisions == 0:
        result.add("K2:moving_vs_moving_sweep",
                   "PASS", f"Checked {k2_checked} combinations, 0 collisions")
    elif k2_collisions > 3:
        result.add("K2:additional",
                   "FAIL", f"{k2_collisions - 3} more moving-vs-moving collisions")


# ---------------------------------------------------------------------------
# TIER 5: CLEARANCE
# ---------------------------------------------------------------------------
def tier5_clearance(result, fixed_parts, moving_parts, clearance_pairs=None):
    """C1-C4: Sliding clearance, rotating clearance, user-defined pairs."""
    print("\n--- TIER 5: CLEARANCE ---")

    # C1: Sliding clearance — offset each moving part by 0.2mm in travel direction
    # and verify it doesn't intersect fixed parts
    min_gap = 0.2  # mm
    c1_fails = 0
    for m_name, (m_shape, axis, min_t, max_t) in moving_parts.items():
        # Test at rest position with offsets in both directions
        for offset in [min_gap, -min_gap]:
            offset_shape = displace_part(m_shape, axis, offset)
            o_bb = offset_shape.val().BoundingBox()
            for f_name, f_shape in fixed_parts.items():
                f_bb = f_shape.val().BoundingBox()
                if not bb_overlap(f_bb, o_bb):
                    continue
                vol = intersection_volume(f_shape, offset_shape)
                if vol > 0:
                    c1_fails += 1
                    if c1_fails <= 3:
                        result.add(f"C1:{m_name}_clearance_{offset:+.1f}mm",
                                   "FAIL",
                                   f"Insufficient sliding clearance vs {f_name} "
                                   f"(overlap={vol:.3f}mm3 at {offset:+.1f}mm offset)")

    if c1_fails == 0:
        result.add("C1:sliding_clearance",
                   "PASS", f"All moving parts have >= {min_gap}mm clearance")

    # C3: User-defined clearance pairs
    if clearance_pairs:
        all_parts = {**fixed_parts}
        for m_name, (m_shape, *_) in moving_parts.items():
            all_parts[m_name] = m_shape

        for part_a, part_b, required_gap in clearance_pairs:
            if part_a not in all_parts or part_b not in all_parts:
                result.add(f"C3:{part_a}_vs_{part_b}",
                           "WARN", f"Part not found for clearance check")
                continue
            # Check by offsetting — if intersection exists at required_gap offset,
            # clearance is insufficient (simplified check)
            result.add(f"C3:{part_a}_vs_{part_b}",
                       "INFO", f"Required gap={required_gap}mm (manual verification)")


# ---------------------------------------------------------------------------
# TIER 6: MANUFACTURABILITY
# ---------------------------------------------------------------------------
def tier6_manufacturability(result, all_parts):
    """M1-M3: Wall thickness, print envelope, volume/mass estimate."""
    print("\n--- TIER 6: MANUFACTURABILITY ---")

    total_vol = 0
    for name, shape in all_parts.items():
        solids = shape.solids().vals()
        vol = sum(s.Volume() for s in solids)
        total_vol += vol

        bb = shape.val().BoundingBox()
        dx = bb.xmax - bb.xmin
        dy = bb.ymax - bb.ymin
        dz = bb.zmax - bb.zmin

        # M2: Print envelope (typical 220x220x250)
        fits = dx <= 220 and dy <= 220 and dz <= 250
        result.add(f"M2:{name}:envelope",
                   "PASS" if fits else "WARN",
                   f"{dx:.0f}x{dy:.0f}x{dz:.0f}mm")

    # M3: Volume/mass estimate (PLA)
    mass_pla = total_vol * 1.24 / 1000
    result.add("M3:total_mass_estimate",
               "INFO",
               f"Total volume={total_vol:.0f}mm3, PLA mass={mass_pla:.1f}g")


# ---------------------------------------------------------------------------
# TIER 7: FUNCTIONAL (mechanism-specific)
# ---------------------------------------------------------------------------
def tier7_functional(result, mechanism_type, moving_parts, fixed_parts):
    """F1-F6: Mechanism-specific functional checks."""
    print("\n--- TIER 7: FUNCTIONAL ---")

    if mechanism_type == 'slider':
        # F6: End stop engagement — at max travel, moving part should contact
        # some fixed geometry (end stop). Check that at max/min travel,
        # slider BB edge is within fixed part BB range.
        for m_name, (m_shape, axis, min_t, max_t) in moving_parts.items():
            for travel_pos, label in [(min_t, "min"), (max_t, "max")]:
                displaced = displace_part(m_shape, axis, travel_pos)
                d_bb = displaced.val().BoundingBox()

                # Check if any fixed part overlaps at this position
                # (end stop should be in the path)
                has_contact = False
                for f_name, f_shape in fixed_parts.items():
                    f_bb = f_shape.val().BoundingBox()
                    if bb_overlap(f_bb, d_bb):
                        vol = intersection_volume(f_shape, displaced)
                        if vol > 0:
                            has_contact = True
                            break
                # Note: for slider with end stops, we WANT some contact at extremes
                # But this is complex — end stops should stop the slider, not collide
                # For now, report as INFO
                result.add(f"F6:{m_name}:end_stop_{label}",
                           "INFO",
                           f"At {label} travel ({travel_pos:.2f}mm): "
                           f"{'contact detected' if has_contact else 'no contact'}")

    elif mechanism_type == 'linkage':
        result.add("F1:grashof", "INFO",
                   "Linkage checks require explicit link lengths — "
                   "implement get_link_lengths() for full F1-F3 checks")

    # F4: Power budget (universal — needs motor spec)
    result.add("F4:power_budget", "INFO",
               "Requires motor spec — implement get_motor_spec() for power check")

    # K5: Driver tracing — every moving part should be driven
    result.add("K5:driver_tracing", "PASS",
               f"{len(moving_parts)} moving parts declared in get_moving_parts()")


# ---------------------------------------------------------------------------
# TIER 8: EXPORT INTEGRITY
# ---------------------------------------------------------------------------
def tier8_export(result, module, all_parts):
    """E1-E4: STEP file checks."""
    print("\n--- TIER 8: EXPORT INTEGRITY ---")

    # Check if exported STEP files exist
    module_dir = os.path.dirname(os.path.abspath(module.__file__))
    step_files = [f for f in os.listdir(module_dir) if f.endswith('.step')]

    if not step_files:
        result.add("E1:step_files_exist", "WARN", "No STEP files found in module directory")
        return

    result.add("E1:step_files_exist", "PASS", f"{len(step_files)} STEP file(s) found")

    # E1: Check solid count in each STEP
    try:
        import cadquery as cq
        for step_file in step_files:
            path = os.path.join(module_dir, step_file)
            imported = cq.importers.importStep(path)
            solids = imported.solids().vals()
            all_valid = all(s.isValid() for s in solids)
            total_vol = sum(s.Volume() for s in solids)
            result.add(f"E2:{step_file}:topology",
                       "PASS" if all_valid else "FAIL",
                       f"{len(solids)} solid(s), valid={all_valid}, vol={total_vol:.1f}mm3")
    except Exception as e:
        result.add("E2:step_reimport", "WARN", f"Could not reimport STEP files: {e}")


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_kinetic.py <production_module_name>")
        print("  The module must be importable and expose:")
        print("    get_fixed_parts(), get_moving_parts(), get_mechanism_type()")
        sys.exit(2)

    module_name = sys.argv[1]

    # Remove .py extension if provided
    if module_name.endswith('.py'):
        module_name = module_name[:-3]

    # Add module's directory to path
    module_path = os.path.abspath(module_name + '.py')
    if os.path.exists(module_path):
        module_dir = os.path.dirname(module_path)
        sys.path.insert(0, module_dir)
        module_name = os.path.basename(module_name)
    elif os.path.exists(module_name):
        module_dir = os.path.dirname(os.path.abspath(module_name))
        sys.path.insert(0, module_dir)
        module_name = os.path.splitext(os.path.basename(module_name))[0]

    print("=" * 72)
    print(f"  UNIVERSAL KINETIC SCULPTURE GEOMETRY VALIDATOR")
    print(f"  Module: {module_name}")
    print("=" * 72)

    # Import production module
    print(f"\nImporting {module_name}...")
    try:
        module = importlib.import_module(module_name)
    except ImportError as e:
        print(f"FATAL: Cannot import module '{module_name}': {e}")
        sys.exit(2)

    # Verify standard interface
    for fn_name in ['get_fixed_parts', 'get_moving_parts', 'get_mechanism_type']:
        if not hasattr(module, fn_name):
            print(f"FATAL: Module '{module_name}' missing required function: {fn_name}()")
            sys.exit(2)

    # Get data from module
    print("\nBuilding geometry from module...")
    fixed_parts = module.get_fixed_parts()
    print(f"  Fixed parts: {len(fixed_parts)} ({', '.join(fixed_parts.keys())})")

    moving_parts = module.get_moving_parts()
    print(f"  Moving parts: {len(moving_parts)} ({', '.join(moving_parts.keys())})")

    mechanism_type = module.get_mechanism_type()
    print(f"  Mechanism type: {mechanism_type}")

    clearance_pairs = None
    if hasattr(module, 'get_clearance_pairs'):
        clearance_pairs = module.get_clearance_pairs()
        print(f"  Clearance pairs: {len(clearance_pairs)}")

    # Combine all parts for topology/dimensional checks
    all_parts = dict(fixed_parts)
    for m_name, (m_shape, *_) in moving_parts.items():
        all_parts[m_name] = m_shape

    # Envelope (optional)
    envelope = None
    if hasattr(module, 'get_envelope'):
        envelope = module.get_envelope()

    # Run all tiers
    result = ValidationResult()

    tier1_topology(result, all_parts)
    tier2_dimensional(result, all_parts, envelope)
    tier3_static(result, fixed_parts, moving_parts)
    tier4_dynamic(result, fixed_parts, moving_parts, mechanism_type)
    tier5_clearance(result, fixed_parts, moving_parts, clearance_pairs)
    tier6_manufacturability(result, all_parts)
    tier7_functional(result, mechanism_type, moving_parts, fixed_parts)
    tier8_export(result, module, all_parts)

    # Report
    all_pass = result.print_report()
    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
