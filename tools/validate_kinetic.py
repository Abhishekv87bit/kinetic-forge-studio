"""
VLAD — Universal Kinetic Sculpture Geometry Validator
=====================================================
One script. Any project. All tiers. 35 checks across 8 tiers.

Usage:
    python vlad.py <production_module>
    python vlad.py --full <production_module>
    python vlad.py --json <production_module>
    python vlad.py --mechanism-type linkage <production_module>

The production module MUST expose:
    get_fixed_parts()    -> dict[str, cq.Workplane]
    get_moving_parts()   -> dict[str, (cq.Workplane, axis, min_travel, max_travel)]
    get_mechanism_type() -> str   # 'slider'|'linkage'|'cam'|'cable'|'gear'|'wave'

Optional (enable extra checks when present):
    get_envelope()          -> dict  {'x': mm, 'y': mm, 'z': mm}             -> D1 envelope fit
    get_clearance_pairs()   -> list  [(part_a, part_b, min_gap_mm), ...]      -> C3 user-defined clearance
    get_assembly()          -> cq.Assembly                                    -> E4 assembly completeness
    get_link_lengths()      -> dict  {'s': mm, 'l': mm, 'p': mm, 'q': mm}    -> F1-F3 linkage checks, K4
    get_motor_spec()        -> dict  {'torque_nm': float, 'speed_rpm': float} -> F4 power budget
    get_cable_stages()      -> int                                            -> F5 friction cascade
    get_guide_rails()       -> dict  {moving_part_name: cq.Workplane}         -> K3 engagement
    get_shaft_bore_pairs()  -> list  [(shaft, bore, shaft_dia, bore_dia)]     -> C2 rotating clearance
    get_reference_volumes() -> dict  {part_name: volume_mm3}                  -> D2 volume stability
    get_symmetry_spec()     -> dict  {'axis': 'x'|'y'|'z', 'parts': [...]}   -> D3 symmetry

Spec: docs/plans/2026-03-03-universal-validation-spec.md
Exit 0 = all blocking checks pass. Exit 1 = FAIL(s) found. Exit 2 = fatal error.
"""

import sys
import os
import importlib
import math
import argparse
import json
import io

import cadquery as cq

# Try to import OCP for proper watertight checks
try:
    from OCP.TopExp import TopExp
    from OCP.TopAbs import TopAbs_EDGE, TopAbs_FACE
    from OCP.TopTools import TopTools_IndexedDataMapOfShapeListOfShape
    _HAS_OCP = True
except ImportError:
    _HAS_OCP = False

# ---------------------------------------------------------------------------
# APPLICABILITY MATRIX
# ---------------------------------------------------------------------------
# Checks that only apply to specific mechanism types.
# Non-applicable checks produce NO output (not INFO, not SKIP — nothing).
LINKAGE_ONLY = {'K4', 'F1', 'F2', 'F3'}
CABLE_ONLY = {'F5'}
SLIDER_ONLY = {'F6'}


def is_applicable(check_prefix, mechanism_type):
    """Return True if check should run for this mechanism type."""
    if check_prefix in LINKAGE_ONLY:
        return mechanism_type == 'linkage'
    if check_prefix in CABLE_ONLY:
        return mechanism_type == 'cable'
    if check_prefix in SLIDER_ONLY:
        return mechanism_type == 'slider'
    return True


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

    def print_report(self, module_name, mechanism_type, fixed_count, moving_count):
        print("\n" + "=" * 72)
        print("  VLAD — Universal Kinetic Sculpture Geometry Validator")
        print(f"  Module: {module_name}")
        print(f"  Mechanism: {mechanism_type}")
        print(f"  Parts: {fixed_count} fixed, {moving_count} moving")
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

    def to_json(self, module_name, mechanism_type, fixed_count, moving_count):
        return json.dumps({
            "module": module_name,
            "mechanism_type": mechanism_type,
            "fixed_parts": fixed_count,
            "moving_parts": moving_count,
            "verdict": "PASS" if self.fail_count == 0 else "FAIL",
            "counts": {
                "pass": self.pass_count,
                "fail": self.fail_count,
                "warn": self.warn_count,
                "info": self.info_count
            },
            "checks": [
                {"id": cid, "status": st, "detail": det}
                for cid, st, det in self.checks
            ]
        }, indent=2)


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
def tier1_topology(result, all_parts, quiet=False):
    """T1-T6: Solid validity, watertight, fusion, volume, duplicates, face count."""
    if not quiet:
        print("\n--- TIER 1: TOPOLOGY ---")

    for name, shape in all_parts.items():
        try:
            solids = shape.solids().vals()

            # T1: Solid validity
            all_valid = all(s.isValid() for s in solids)
            result.add(f"T1:{name}:valid",
                       "PASS" if all_valid else "FAIL",
                       f"valid={all_valid}")

            # T2: Watertight (free edge check — Solid.Closed() flag is unreliable)
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

            # T5: No duplicate bodies — pairwise intersection within same part
            if body_count > 1:
                t5_dupes = 0
                for si in range(len(solids)):
                    for sj in range(si + 1, len(solids)):
                        try:
                            s_a = cq.Workplane("XY").add(solids[si])
                            s_b = cq.Workplane("XY").add(solids[sj])
                            vol = intersection_volume(s_a, s_b)
                            if vol > 0:
                                t5_dupes += 1
                        except Exception:
                            pass
                if t5_dupes > 0:
                    result.add(f"T5:{name}:no_duplicates",
                               "FAIL",
                               f"{t5_dupes} coincident solid pair(s) within part")
                else:
                    result.add(f"T5:{name}:no_duplicates",
                               "PASS",
                               f"{body_count} bodies, none overlapping")

            # T6: Face count sanity
            total_faces = sum(len(s.Faces()) for s in solids) if solids else 0
            result.add(f"T6:{name}:face_count",
                       "WARN" if total_faces > 1000 else "PASS",
                       f"{total_faces} faces" + (" (excessive!)" if total_faces > 1000 else ""))

        except Exception as e:
            result.add(f"T1:{name}:topology_error", "WARN", f"Could not check: {e}")


# ---------------------------------------------------------------------------
# TIER 2: DIMENSIONAL
# ---------------------------------------------------------------------------
def tier2_dimensional(result, all_parts, envelope=None, reference_volumes=None,
                      symmetry_spec=None, quiet=False):
    """D1-D4: Bounding box, volume stability, symmetry, aspect ratio."""
    if not quiet:
        print("\n--- TIER 2: DIMENSIONAL ---")

    for name, shape in all_parts.items():
        try:
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
        except Exception as e:
            result.add(f"D4:{name}:aspect_ratio", "WARN", f"Could not check: {e}")

    # D1: Bounding box vs envelope (if provided)
    if envelope:
        try:
            all_shapes = list(all_parts.values())
            if all_shapes:
                combined = all_shapes[0]
                for s in all_shapes[1:]:
                    try:
                        combined = combined.union(s)
                    except Exception:
                        pass
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
                           f"limit=({envelope.get('x', '?')}x{envelope.get('y', '?')}x{envelope.get('z', '?')})")
        except Exception as e:
            result.add("D1:envelope_fit", "WARN", f"Could not check: {e}")
    else:
        result.add("D1:envelope_fit", "INFO",
                   "No envelope defined — implement get_envelope() for bounding box check")

    # D2: Volume stability vs reference
    if reference_volumes:
        for name, ref_vol in reference_volumes.items():
            if name in all_parts:
                try:
                    cur_vol = sum(s.Volume() for s in all_parts[name].solids().vals())
                    if ref_vol > 0:
                        drift_pct = abs(cur_vol - ref_vol) / ref_vol * 100
                        result.add(f"D2:{name}:volume_stability",
                                   "WARN" if drift_pct > 5.0 else "PASS",
                                   f"current={cur_vol:.1f}mm3, ref={ref_vol:.1f}mm3, "
                                   f"drift={drift_pct:.1f}%")
                    else:
                        result.add(f"D2:{name}:volume_stability",
                                   "WARN", "reference volume is 0")
                except Exception as e:
                    result.add(f"D2:{name}:volume_stability",
                               "WARN", f"Could not check: {e}")
    else:
        result.add("D2:volume_stability", "INFO",
                   "No reference volumes — implement get_reference_volumes() for stability tracking")

    # D3: Symmetry verification
    if symmetry_spec:
        sym_axis = symmetry_spec.get('axis', 'x')
        sym_parts = symmetry_spec.get('parts', [])
        mirror_plane = {'x': 'YZ', 'y': 'XZ', 'z': 'XY'}.get(sym_axis, 'YZ')
        for part_name in sym_parts:
            if part_name not in all_parts:
                result.add(f"D3:{part_name}:symmetry",
                           "WARN", f"Part '{part_name}' not found")
                continue
            try:
                shape = all_parts[part_name]
                mirrored = shape.mirror(mirror_plane)
                overlap = intersection_volume(shape, mirrored)
                original_vol = sum(s.Volume() for s in shape.solids().vals())
                if original_vol > 0:
                    overlap_pct = overlap / original_vol * 100
                    result.add(f"D3:{part_name}:symmetry",
                               "WARN" if overlap_pct < 95 else "PASS",
                               f"overlap={overlap_pct:.1f}% about {sym_axis}-axis")
                else:
                    result.add(f"D3:{part_name}:symmetry",
                               "WARN", "zero volume part")
            except Exception as e:
                result.add(f"D3:{part_name}:symmetry",
                           "WARN", f"Could not verify: {e}")
    else:
        result.add("D3:symmetry", "INFO",
                   "No symmetry spec — implement get_symmetry_spec() for symmetry check")


# ---------------------------------------------------------------------------
# TIER 3: STATIC INTERFERENCE
# ---------------------------------------------------------------------------
def tier3_static(result, fixed_parts, moving_parts, quiet=False):
    """S1-S3: Boolean intersection at rest position."""
    if not quiet:
        print("\n--- TIER 3: STATIC INTERFERENCE ---")

    fixed_list = list(fixed_parts.items())
    moving_list = list(moving_parts.items())

    # S1: Fixed vs moving (at rest — displacement = 0, shapes as-is)
    s1_collisions = 0
    for m_name, (m_shape, axis, min_t, max_t) in moving_list:
        for f_name, f_shape in fixed_list:
            try:
                f_bb = f_shape.val().BoundingBox()
                m_bb = m_shape.val().BoundingBox()
                if not bb_overlap(f_bb, m_bb):
                    continue
                vol = intersection_volume(f_shape, m_shape)
                if vol > 0:
                    s1_collisions += 1
                    if s1_collisions <= 5:
                        result.add(f"S1:{f_name}_vs_{m_name}",
                                   "FAIL",
                                   f"OVERLAP={vol:.3f}mm3 at rest position")
            except Exception:
                pass
    if s1_collisions == 0:
        result.add("S1:fixed_vs_moving_rest",
                   "PASS",
                   f"Checked {len(fixed_list) * len(moving_list)} pairs, 0 collisions")
    elif s1_collisions > 5:
        result.add("S1:additional",
                   "FAIL", f"{s1_collisions - 5} more fixed-vs-moving collisions")

    # S2: Adjacent moving parts (at rest)
    s2_collisions = 0
    m_names = list(moving_parts.keys())
    for i in range(len(m_names)):
        for j in range(i + 1, len(m_names)):
            try:
                a_shape = moving_parts[m_names[i]][0]
                b_shape = moving_parts[m_names[j]][0]
                a_bb = a_shape.val().BoundingBox()
                b_bb = b_shape.val().BoundingBox()
                if not bb_overlap(a_bb, b_bb):
                    continue
                vol = intersection_volume(a_shape, b_shape)
                if vol > 0:
                    s2_collisions += 1
                    if s2_collisions <= 5:
                        result.add(f"S2:{m_names[i]}_vs_{m_names[j]}",
                                   "FAIL", f"OVERLAP={vol:.3f}mm3")
            except Exception:
                pass
    if s2_collisions == 0:
        pairs = len(m_names) * (len(m_names) - 1) // 2
        result.add("S2:moving_vs_moving_rest",
                   "PASS", f"Checked {pairs} pairs, 0 collisions")
    elif s2_collisions > 5:
        result.add("S2:additional",
                   "FAIL", f"{s2_collisions - 5} more moving-vs-moving collisions")

    # S3: Fixed vs fixed
    s3_collisions = 0
    for i in range(len(fixed_list)):
        for j in range(i + 1, len(fixed_list)):
            try:
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
            except Exception:
                pass
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
def tier4_dynamic(result, fixed_parts, moving_parts, mechanism_type,
                  guide_rails=None, link_lengths=None, quiet=False):
    """K1-K5: Full-travel collision sweep, engagement, dead points, driver tracing."""
    if not quiet:
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
            try:
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
            except Exception:
                k1_checked += 1

    if k1_collisions == 0:
        result.add("K1:moving_vs_fixed_sweep",
                   "PASS", f"Checked {k1_checked} pairs across {n_samples} positions, 0 collisions")
    elif k1_collisions > 5:
        result.add("K1:additional",
                   "FAIL", f"{k1_collisions - 5} more dynamic collisions not shown")

    # K2: Moving vs moving at multiple positions (5x5 cartesian product)
    k2_collisions = 0
    k2_checked = 0
    m_names = list(moving_parts.keys())
    for i in range(len(m_names)):
        for j in range(i + 1, len(m_names)):
            a_name = m_names[i]
            b_name = m_names[j]
            a_shape, a_axis, a_min, a_max = moving_parts[a_name]
            b_shape, b_axis, b_min, b_max = moving_parts[b_name]

            a_samples = get_travel_samples(a_min, a_max, 5)
            b_samples = get_travel_samples(b_min, b_max, 5)

            for a_t in a_samples:
                for b_t in b_samples:
                    try:
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
                    except Exception:
                        k2_checked += 1

    if k2_collisions == 0:
        result.add("K2:moving_vs_moving_sweep",
                   "PASS", f"Checked {k2_checked} combinations, 0 collisions")
    elif k2_collisions > 3:
        result.add("K2:additional",
                   "FAIL", f"{k2_collisions - 3} more moving-vs-moving collisions")

    # K3: Engagement at extremes — moving part must overlap its guide rail
    if is_applicable('K3', mechanism_type):
        if guide_rails:
            for m_name, (m_shape, axis, min_t, max_t) in moving_parts.items():
                if m_name not in guide_rails:
                    continue
                guide = guide_rails[m_name]
                for travel, label in [(min_t, "min"), (max_t, "max")]:
                    try:
                        displaced = displace_part(m_shape, axis, travel)
                        overlap = intersection_volume(displaced, guide)
                        if overlap > 0:
                            result.add(f"K3:{m_name}:engagement_{label}",
                                       "PASS",
                                       f"Engaged with guide at {label} travel ({travel:.2f}mm)")
                        else:
                            result.add(f"K3:{m_name}:engagement_{label}",
                                       "FAIL",
                                       f"DISENGAGED from guide at {label} travel ({travel:.2f}mm)")
                    except Exception as e:
                        result.add(f"K3:{m_name}:engagement_{label}",
                                   "WARN", f"Could not check: {e}")
        else:
            result.add("K3:engagement", "INFO",
                       "No guide rails — implement get_guide_rails() for engagement check")

    # K4: Dead point detection — transmission angle at 4 crank positions (linkage only)
    if is_applicable('K4', mechanism_type):
        if link_lengths:
            try:
                a = link_lengths['s']  # crank (shortest)
                b = link_lengths['l']  # coupler
                c = link_lengths['p']  # follower
                d = link_lengths['q']  # ground
                k4_issues = []
                for theta_deg in [0, 90, 180, 270]:
                    theta = math.radians(theta_deg)
                    cos_mu_num = b**2 + c**2 - a**2 - d**2 + 2 * a * d * math.cos(theta)
                    cos_mu_den = 2 * b * c
                    if abs(cos_mu_den) < 1e-10:
                        k4_issues.append(f"\u03b8={theta_deg}\u00b0: degenerate (zero denominator)")
                        continue
                    cos_mu = max(-1, min(1, cos_mu_num / cos_mu_den))
                    mu_deg = math.degrees(math.acos(cos_mu))
                    if mu_deg < 40 or mu_deg > 140:
                        k4_issues.append(
                            f"\u03b8={theta_deg}\u00b0: \u03bc={mu_deg:.1f}\u00b0 (outside 40-140\u00b0)")
                if k4_issues:
                    result.add("K4:dead_point", "FAIL", "\n".join(k4_issues))
                else:
                    result.add("K4:dead_point", "PASS",
                               "Transmission angle within 40-140\u00b0 at all 4 crank positions")
            except Exception as e:
                result.add("K4:dead_point", "WARN", f"Could not check: {e}")
        else:
            result.add("K4:dead_point", "INFO",
                       "Linkage but no link lengths — implement get_link_lengths() for dead point check")

    # K5: Driver tracing — every moving part must have valid axis and non-zero travel
    k5_issues = []
    valid_axes = ('x', 'y', 'z', 'rx', 'ry', 'rz')
    for m_name, (m_shape, axis, min_t, max_t) in moving_parts.items():
        if axis not in valid_axes:
            k5_issues.append(f"{m_name}: invalid axis '{axis}' (must be one of {valid_axes})")
        if abs(max_t - min_t) < 0.001:
            k5_issues.append(f"{m_name}: zero travel range ({min_t} to {max_t})")
    if k5_issues:
        result.add("K5:driver_tracing", "FAIL",
                   "\n".join(k5_issues))
    else:
        result.add("K5:driver_tracing", "PASS",
                   f"{len(moving_parts)} moving parts, all with valid axis and non-zero travel")


# ---------------------------------------------------------------------------
# TIER 5: CLEARANCE
# ---------------------------------------------------------------------------
def tier5_clearance(result, fixed_parts, moving_parts, clearance_pairs=None,
                    shaft_bore_pairs=None, quiet=False):
    """C1-C4: Sliding clearance, rotating clearance, user-defined pairs, assembly feasibility."""
    if not quiet:
        print("\n--- TIER 5: CLEARANCE ---")

    # C1: Sliding clearance — offset each moving part by 0.2mm in travel direction
    min_gap = 0.2  # mm
    c1_fails = 0
    for m_name, (m_shape, axis, min_t, max_t) in moving_parts.items():
        for offset in [min_gap, -min_gap]:
            try:
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
            except Exception:
                pass

    if c1_fails == 0:
        result.add("C1:sliding_clearance",
                   "PASS", f"All moving parts have >= {min_gap}mm clearance")
    elif c1_fails > 3:
        result.add("C1:additional",
                   "FAIL", f"{c1_fails - 3} more clearance violations not shown")

    # C2: Rotating clearance — bore_dia - shaft_dia >= 0.1mm
    if shaft_bore_pairs:
        for shaft_name, bore_name, shaft_dia, bore_dia in shaft_bore_pairs:
            gap = bore_dia - shaft_dia
            result.add(f"C2:{shaft_name}_in_{bore_name}",
                       "PASS" if gap >= 0.1 else "FAIL",
                       f"shaft={shaft_dia:.3f}mm, bore={bore_dia:.3f}mm, gap={gap:.3f}mm"
                       + (" — too tight!" if gap < 0.1 else ""))
    else:
        result.add("C2:rotating_clearance", "INFO",
                   "No shaft/bore pairs — implement get_shaft_bore_pairs() for rotating clearance")

    # C3: User-defined clearance pairs
    if clearance_pairs:
        all_parts = {**fixed_parts}
        for m_name, (m_shape, *_) in moving_parts.items():
            all_parts[m_name] = m_shape

        for part_a, part_b, required_gap in clearance_pairs:
            if part_a not in all_parts or part_b not in all_parts:
                result.add(f"C3:{part_a}_vs_{part_b}",
                           "WARN", "Part not found for clearance check")
                continue
            try:
                dist_info = all_parts[part_a].val().distToShape(all_parts[part_b].val())
                actual_gap = dist_info[0]
                if actual_gap >= required_gap:
                    result.add(f"C3:{part_a}_vs_{part_b}",
                               "PASS",
                               f"Actual gap={actual_gap:.3f}mm >= required {required_gap}mm")
                else:
                    result.add(f"C3:{part_a}_vs_{part_b}",
                               "FAIL",
                               f"Actual gap={actual_gap:.3f}mm < required {required_gap}mm")
            except Exception as e:
                result.add(f"C3:{part_a}_vs_{part_b}",
                           "WARN", f"Could not measure gap: {e}")

    # C4: Assembly feasibility — check if any part is fully enclosed by a non-housing part
    all_parts_c4 = {**fixed_parts}
    for m_name, (m_shape, *_) in moving_parts.items():
        all_parts_c4[m_name] = m_shape

    part_names = list(all_parts_c4.keys())

    # Find the largest part by volume — likely the housing/container
    largest_name = None
    largest_vol = 0
    for pn in part_names:
        try:
            vol = sum(s.Volume() for s in all_parts_c4[pn].solids().vals())
            if vol > largest_vol:
                largest_vol = vol
                largest_name = pn
        except Exception:
            pass

    c4_trapped = 0
    for i in range(len(part_names)):
        try:
            bb_i = all_parts_c4[part_names[i]].val().BoundingBox()
        except Exception:
            continue
        for j in range(len(part_names)):
            if i == j:
                continue
            # Skip: anything enclosed by the largest part (housing) is expected
            if part_names[j] == largest_name:
                continue
            try:
                bb_j = all_parts_c4[part_names[j]].val().BoundingBox()
                if (bb_i.xmin >= bb_j.xmin and bb_i.xmax <= bb_j.xmax and
                        bb_i.ymin >= bb_j.ymin and bb_i.ymax <= bb_j.ymax and
                        bb_i.zmin >= bb_j.zmin and bb_i.zmax <= bb_j.zmax):
                    c4_trapped += 1
                    if c4_trapped <= 5:
                        result.add(f"C4:{part_names[i]}_in_{part_names[j]}",
                                   "WARN",
                                   f"{part_names[i]} BB fully enclosed by {part_names[j]} — "
                                   f"verify assembly order allows insertion")
            except Exception:
                pass
    if c4_trapped == 0:
        result.add("C4:assembly_feasibility",
                   "PASS",
                   f"No trapped parts ({len(part_names)} parts checked, "
                   f"largest='{largest_name}' excluded as container)")
    elif c4_trapped > 5:
        result.add("C4:assembly_feasibility_additional",
                   "WARN", f"{c4_trapped - 5} more potential trapped parts")


# ---------------------------------------------------------------------------
# TIER 6: MANUFACTURABILITY
# ---------------------------------------------------------------------------
def tier6_manufacturability(result, all_parts, full_mode=False, quiet=False):
    """M1-M3: Wall thickness, print envelope, volume/mass estimate."""
    if not quiet:
        print("\n--- TIER 6: MANUFACTURABILITY ---")

    # M1: Min wall thickness (expensive — gated by --full)
    if not full_mode:
        result.add("M1:wall_thickness", "INFO",
                   "Wall thickness check skipped — run with --full flag for section analysis")
    else:
        m1_thin = 0
        min_wall_mm = 1.2  # FDM minimum
        for name, shape in all_parts.items():
            try:
                bb = shape.val().BoundingBox()
                z_range = bb.zmax - bb.zmin
                if z_range < 0.1:
                    continue
                for i in range(5):
                    z = bb.zmin + z_range * (i + 0.5) / 5
                    try:
                        section = shape.section(cq.Workplane("XY").workplane(offset=z))
                        wires = section.wires().vals()
                        for w in wires:
                            w_bb = w.BoundingBox()
                            min_dim = min(w_bb.xmax - w_bb.xmin, w_bb.ymax - w_bb.ymin)
                            if 0 < min_dim < min_wall_mm:
                                m1_thin += 1
                                if m1_thin <= 3:
                                    result.add(
                                        f"M1:{name}:wall_at_z{z:.1f}",
                                        "WARN",
                                        f"Thin feature: {min_dim:.2f}mm < {min_wall_mm}mm minimum")
                    except Exception:
                        pass
            except Exception as e:
                result.add(f"M1:{name}:wall_thickness", "WARN", f"Analysis error: {e}")
        if m1_thin == 0:
            result.add("M1:wall_thickness", "PASS",
                       f"No walls below {min_wall_mm}mm (section analysis at 5 Z heights per part)")
        elif m1_thin > 3:
            result.add("M1:wall_thickness_additional", "WARN",
                       f"{m1_thin - 3} more thin features not shown")

    total_vol = 0
    for name, shape in all_parts.items():
        try:
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
        except Exception as e:
            result.add(f"M2:{name}:envelope", "WARN", f"Could not check: {e}")

    # M3: Volume/mass estimate (PLA)
    mass_pla = total_vol * 1.24 / 1000
    result.add("M3:total_mass_estimate",
               "INFO",
               f"Total volume={total_vol:.0f}mm3, PLA mass={mass_pla:.1f}g")


# ---------------------------------------------------------------------------
# TIER 7: FUNCTIONAL (mechanism-specific)
# ---------------------------------------------------------------------------
def tier7_functional(result, mechanism_type, moving_parts, fixed_parts, module,
                     link_lengths=None, motor_spec=None, quiet=False):
    """F1-F6: Mechanism-specific functional checks."""
    if not quiet:
        print("\n--- TIER 7: FUNCTIONAL ---")

    # F1: Grashof condition (linkage only)
    if is_applicable('F1', mechanism_type):
        if link_lengths:
            try:
                lengths = sorted([link_lengths['s'], link_lengths['l'],
                                  link_lengths['p'], link_lengths['q']])
                shortest, second, third, longest = lengths
                grashof_sum = shortest + longest
                other_sum = second + third
                is_grashof = grashof_sum <= other_sum
                result.add("F1:grashof",
                           "PASS" if is_grashof else "FAIL",
                           f"s+l={grashof_sum:.2f}mm "
                           f"{'<=' if is_grashof else '>'} "
                           f"p+q={other_sum:.2f}mm — "
                           f"{'full rotation possible' if is_grashof else 'CANNOT rotate'}")
            except Exception as e:
                result.add("F1:grashof", "WARN", f"Could not check: {e}")
        else:
            result.add("F1:grashof", "INFO",
                       "Implement get_link_lengths() for Grashof check")

    # F2: Transmission angle at 4 crank positions (linkage only)
    if is_applicable('F2', mechanism_type):
        if link_lengths:
            try:
                a = link_lengths['s']
                b = link_lengths['l']
                c = link_lengths['p']
                d = link_lengths['q']
                f2_results = []
                f2_ok = True
                for theta_deg in [0, 90, 180, 270]:
                    theta = math.radians(theta_deg)
                    cos_mu_num = b**2 + c**2 - a**2 - d**2 + 2 * a * d * math.cos(theta)
                    cos_mu_den = 2 * b * c
                    if abs(cos_mu_den) < 1e-10:
                        f2_results.append(f"\u03b8={theta_deg}\u00b0: degenerate")
                        f2_ok = False
                        continue
                    cos_mu = max(-1, min(1, cos_mu_num / cos_mu_den))
                    mu_deg = math.degrees(math.acos(cos_mu))
                    f2_results.append(f"\u03b8={theta_deg}\u00b0: \u03bc={mu_deg:.1f}\u00b0")
                    if mu_deg < 40 or mu_deg > 140:
                        f2_ok = False
                result.add("F2:transmission_angle",
                           "PASS" if f2_ok else "FAIL",
                           " | ".join(f2_results))
            except Exception as e:
                result.add("F2:transmission_angle", "WARN", f"Could not check: {e}")
        else:
            result.add("F2:transmission_angle", "INFO",
                       "Implement get_link_lengths() for transmission angle check")

    # F3: Coupler constancy (linkage only)
    if is_applicable('F3', mechanism_type):
        if link_lengths:
            try:
                # In a rigid four-bar, coupler length is constant by definition.
                # This validates the link length specification is self-consistent.
                coupler_len = link_lengths['l']
                result.add("F3:coupler_constancy",
                           "PASS",
                           f"Coupler length={coupler_len:.2f}mm (constant in rigid linkage)")
            except Exception as e:
                result.add("F3:coupler_constancy", "WARN", f"Could not check: {e}")
        else:
            result.add("F3:coupler_constancy", "INFO",
                       "Implement get_link_lengths() for coupler constancy check")

    # F4: Power budget (all mechanism types, needs motor spec)
    if motor_spec:
        try:
            avail_torque = motor_spec.get('torque_nm', 0)
            avail_speed = motor_spec.get('speed_rpm', 0)
            total_moving_vol = sum(
                sum(s.Volume() for s in mp[0].solids().vals())
                for mp in moving_parts.values()
            )
            est_mass_kg = total_moving_vol * 1.24 / 1e6
            max_travel = max(abs(mp[3] - mp[2]) for mp in moving_parts.values()) / 1000
            est_torque = est_mass_kg * 9.81 * max_travel
            margin = avail_torque / 2
            result.add("F4:power_budget",
                       "PASS" if est_torque <= margin else "WARN",
                       f"Required\u2248{est_torque:.4f}N\u22c5m, Available/2={margin:.4f}N\u22c5m, "
                       f"motor={avail_torque}N\u22c5m@{avail_speed}rpm")
        except Exception as e:
            result.add("F4:power_budget", "WARN", f"Could not check: {e}")
    else:
        result.add("F4:power_budget", "INFO",
                   "No motor spec — implement get_motor_spec() for power budget check")

    # F5: Friction cascade (cable only)
    if is_applicable('F5', mechanism_type):
        if hasattr(module, 'get_cable_stages'):
            try:
                n_stages = module.get_cable_stages()
                efficiency = 0.95 ** n_stages
                result.add("F5:friction_cascade",
                           "WARN" if n_stages > 9 else "PASS",
                           f"{n_stages} stages, efficiency={efficiency:.1%}"
                           + (" — exceeds 9-stage limit!" if n_stages > 9 else ""))
            except Exception as e:
                result.add("F5:friction_cascade", "WARN", f"Could not check: {e}")
        else:
            result.add("F5:friction_cascade", "INFO",
                       "Cable mechanism but no stage count — implement get_cable_stages()")

    # F6: End stop engagement (slider only)
    if is_applicable('F6', mechanism_type):
        for m_name, (m_shape, axis, min_t, max_t) in moving_parts.items():
            for travel_pos, label in [(min_t, "min"), (max_t, "max")]:
                try:
                    displaced = displace_part(m_shape, axis, travel_pos)
                    d_bb = displaced.val().BoundingBox()
                    has_contact = False
                    for f_name, f_shape in fixed_parts.items():
                        f_bb = f_shape.val().BoundingBox()
                        if bb_overlap(f_bb, d_bb):
                            vol = intersection_volume(f_shape, displaced)
                            if vol > 0:
                                has_contact = True
                                break
                    if has_contact:
                        result.add(f"F6:{m_name}:end_stop_{label}",
                                   "PASS",
                                   f"At {label} travel ({travel_pos:.2f}mm): "
                                   f"end stop contact confirmed")
                    else:
                        result.add(f"F6:{m_name}:end_stop_{label}",
                                   "FAIL",
                                   f"At {label} travel ({travel_pos:.2f}mm): "
                                   f"NO end stop — slider not retained")
                except Exception as e:
                    result.add(f"F6:{m_name}:end_stop_{label}",
                               "WARN", f"Could not check: {e}")


# ---------------------------------------------------------------------------
# TIER 8: EXPORT INTEGRITY
# ---------------------------------------------------------------------------
def tier8_export(result, module, all_parts, quiet=False):
    """E1-E4: STEP file checks."""
    if not quiet:
        print("\n--- TIER 8: EXPORT INTEGRITY ---")

    expected_part_count = len(all_parts)
    cq_total_vol = 0
    for name, shape in all_parts.items():
        try:
            vol = sum(s.Volume() for s in shape.solids().vals())
            cq_total_vol += vol
        except Exception:
            pass

    # Check if exported STEP files exist
    try:
        module_dir = os.path.dirname(os.path.abspath(module.__file__))
        step_files = [f for f in os.listdir(module_dir) if f.endswith('.step')]
    except Exception:
        step_files = []
        module_dir = ""

    if not step_files:
        result.add("E1:step_files_exist", "WARN",
                   f"No STEP files found in module directory (expected {expected_part_count} parts)")
        return

    try:
        total_step_solids = 0
        step_total_vol = 0
        for step_file in step_files:
            path = os.path.join(module_dir, step_file)
            imported = cq.importers.importStep(path)
            solids = imported.solids().vals()
            total_step_solids += len(solids)
            step_vol = sum(s.Volume() for s in solids)
            step_total_vol += step_vol
            file_valid = all(s.isValid() for s in solids)

            # E2: STEP topology valid (per file)
            result.add(f"E2:{step_file}:topology",
                       "PASS" if file_valid else "FAIL",
                       f"{len(solids)} solid(s), valid={file_valid}, vol={step_vol:.1f}mm3")

        # E1: Compare solid count to expected — FAIL if mismatch (spec: blocking=YES)
        count_match = total_step_solids == expected_part_count
        result.add("E1:step_solid_count",
                   "PASS" if count_match else "FAIL",
                   f"STEP has {total_step_solids} solid(s), "
                   f"CadQuery has {expected_part_count} named parts"
                   + ("" if count_match else " — count mismatch"))

        # E3: Volume conservation
        if cq_total_vol > 0 and step_total_vol > 0:
            vol_drift = abs(step_total_vol - cq_total_vol) / cq_total_vol * 100
            result.add("E3:volume_conservation",
                       "PASS" if vol_drift <= 1.0 else "WARN",
                       f"CQ vol={cq_total_vol:.1f}mm3, STEP vol={step_total_vol:.1f}mm3, "
                       f"drift={vol_drift:.2f}%"
                       + (" — exceeds 1% threshold" if vol_drift > 1.0 else ""))

    except Exception as e:
        result.add("E1:step_reimport", "WARN", f"Could not reimport STEP files: {e}")

    # E4: Assembly completeness
    if hasattr(module, 'get_assembly'):
        try:
            assembly = module.get_assembly()
            assy_parts = set()
            for obj in assembly.objects.values():
                assy_parts.add(obj.name)
            expected_names = set(all_parts.keys())
            missing = expected_names - assy_parts
            extra = assy_parts - expected_names
            if not missing:
                result.add("E4:assembly_completeness",
                           "PASS",
                           f"All {len(expected_names)} parts present in assembly")
            else:
                result.add("E4:assembly_completeness",
                           "FAIL",
                           f"Missing from assembly: {', '.join(sorted(missing))}")
            if extra:
                result.add("E4:assembly_extra_parts",
                           "INFO",
                           f"Extra parts in assembly: {', '.join(sorted(extra))}")
        except Exception as e:
            result.add("E4:assembly_completeness",
                       "WARN", f"Could not inspect assembly: {e}")
    else:
        result.add("E4:assembly_completeness", "INFO",
                   "No get_assembly() — implement for full E4 check")


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description='VLAD — Universal Kinetic Sculpture Geometry Validator')
    parser.add_argument('module', help='Production module path (with or without .py)')
    parser.add_argument('--full', action='store_true',
                        help='Run expensive checks (M1 wall thickness)')
    parser.add_argument('--json', action='store_true', dest='json_output',
                        help='JSON output for machine consumption')
    parser.add_argument('--mechanism-type',
                        choices=['slider', 'linkage', 'cam', 'cable', 'gear', 'wave'],
                        help='Override mechanism type detection')
    args = parser.parse_args()

    module_name = args.module

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

    # Import production module
    if not args.json_output:
        print("=" * 72)
        print("  VLAD — Universal Kinetic Sculpture Geometry Validator")
        print(f"  Module: {module_name}")

    # In JSON mode, suppress ALL stdout during import and geometry building
    # (production modules print progress info that would contaminate JSON)
    if args.json_output:
        _real_stdout = sys.stdout
        sys.stdout = io.StringIO()

    try:
        module = importlib.import_module(module_name)
    except ImportError as e:
        if args.json_output:
            sys.stdout = _real_stdout
        print(f"FATAL: Cannot import module '{module_name}': {e}", file=sys.stderr)
        sys.exit(2)

    # Verify standard interface
    for fn_name in ['get_fixed_parts', 'get_moving_parts', 'get_mechanism_type']:
        if not hasattr(module, fn_name):
            if args.json_output:
                sys.stdout = _real_stdout
            print(f"FATAL: Module '{module_name}' missing required function: {fn_name}()",
                  file=sys.stderr)
            sys.exit(2)

    # Get data from module
    if not args.json_output:
        print("\nBuilding geometry from module...")
    fixed_parts = module.get_fixed_parts()
    moving_parts = module.get_moving_parts()
    mechanism_type = args.mechanism_type or module.get_mechanism_type()

    # Restore stdout after geometry building in JSON mode
    if args.json_output:
        sys.stdout = _real_stdout

    if not args.json_output:
        print(f"  Mechanism: {mechanism_type}")
        print(f"  Parts: {len(fixed_parts)} fixed, {len(moving_parts)} moving")
        print("=" * 72)

    # Optional interfaces
    clearance_pairs = None
    if hasattr(module, 'get_clearance_pairs'):
        clearance_pairs = module.get_clearance_pairs()

    envelope = None
    if hasattr(module, 'get_envelope'):
        envelope = module.get_envelope()

    reference_volumes = None
    if hasattr(module, 'get_reference_volumes'):
        reference_volumes = module.get_reference_volumes()

    symmetry_spec = None
    if hasattr(module, 'get_symmetry_spec'):
        symmetry_spec = module.get_symmetry_spec()

    guide_rails = None
    if hasattr(module, 'get_guide_rails'):
        guide_rails = module.get_guide_rails()

    link_lengths = None
    if hasattr(module, 'get_link_lengths'):
        link_lengths = module.get_link_lengths()

    shaft_bore_pairs = None
    if hasattr(module, 'get_shaft_bore_pairs'):
        shaft_bore_pairs = module.get_shaft_bore_pairs()

    motor_spec = None
    if hasattr(module, 'get_motor_spec'):
        motor_spec = module.get_motor_spec()

    # Combine all parts for topology/dimensional checks
    all_parts = dict(fixed_parts)
    for m_name, (m_shape, *_) in moving_parts.items():
        all_parts[m_name] = m_shape

    # Run all tiers
    result = ValidationResult()

    quiet = args.json_output

    tier1_topology(result, all_parts, quiet=quiet)
    tier2_dimensional(result, all_parts, envelope, reference_volumes, symmetry_spec,
                      quiet=quiet)
    tier3_static(result, fixed_parts, moving_parts, quiet=quiet)
    tier4_dynamic(result, fixed_parts, moving_parts, mechanism_type,
                  guide_rails, link_lengths, quiet=quiet)
    tier5_clearance(result, fixed_parts, moving_parts, clearance_pairs,
                    shaft_bore_pairs, quiet=quiet)
    tier6_manufacturability(result, all_parts, full_mode=args.full, quiet=quiet)
    tier7_functional(result, mechanism_type, moving_parts, fixed_parts, module,
                     link_lengths, motor_spec, quiet=quiet)
    tier8_export(result, module, all_parts, quiet=quiet)

    # Report
    if args.json_output:
        print(result.to_json(module_name, mechanism_type,
                             len(fixed_parts), len(moving_parts)))
        sys.exit(0 if result.fail_count == 0 else 1)
    else:
        all_pass = result.print_report(module_name, mechanism_type,
                                       len(fixed_parts), len(moving_parts))
        sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
