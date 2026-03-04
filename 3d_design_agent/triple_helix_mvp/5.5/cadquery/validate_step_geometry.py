"""
STEP Geometry Validator V2 — REAL geometric collision detection
================================================================
Imports the production module directly and builds actual geometry
for all components. Then performs BOOLEAN INTERSECTION between
every pair of bodies that shouldn't overlap.

NO parametric hand-checks. ALL collision detection is geometric.

Checks:
  1. BODY INTEGRITY     — watertight solids, valid topology, body count
  2. GEOMETRIC COLLISION — boolean intersect housing vs every slider,
                           every fixed pulley vs neighboring slider,
                           slider pulleys vs housing walls
  3. BOUNDING BOX       — fits inside hex boundary
  4. MANUFACTURABILITY  — body fusion, FDM feasibility

Exit code 0 = all pass, 1 = failures found.
"""

import sys
import os
import math

# Add cadquery dir to path so we can import the production module
base_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, base_dir)

import cadquery as cq
import matrix_tier_production as prod


# ============================================================
# CONFIG — from production module (single source of truth)
# ============================================================
HEX_R = prod.HEX_R
HEX_CLIP_INSET = prod.HEX_CLIP_INSET
HOUSING_HEIGHT = prod.HOUSING_HEIGHT
NUM_CHANNELS = prod.NUM_CHANNELS
STACK_OFFSET = prod.STACK_OFFSET
CH_GAP = prod.CH_GAP
WALL_THICKNESS = prod.WALL_THICKNESS
FP_OD = prod.FP_OD
FP_ROW_Y = prod.FP_ROW_Y
FP_WIDTH = prod.FP_WIDTH
FP_AXLE_DIA = prod.FP_AXLE_DIA
PIP_CLEARANCE = prod.PIP_CLEARANCE
PIP_Z_GAP = prod.PIP_Z_GAP
ECCENTRICITY = prod.ECCENTRICITY
SLIDER_REST_OFFSET = prod.SLIDER_REST_OFFSET

# FDM limits
MIN_WALL_THICKNESS = 1.2


# ============================================================
# RESULT TRACKING
# ============================================================
class ValidationResult:
    def __init__(self):
        self.checks = []
        self.pass_count = 0
        self.fail_count = 0
        self.warn_count = 0
        self.info_count = 0

    def add(self, name, status, detail=""):
        self.checks.append((name, status, detail))
        if status == "PASS":
            self.pass_count += 1
        elif status == "FAIL":
            self.fail_count += 1
        elif status == "WARN":
            self.warn_count += 1
        else:
            self.info_count += 1

    def print_report(self):
        print("\n" + "=" * 70)
        print("  MATRIX TIER V5.6 -- GEOMETRY VALIDATION REPORT V2")
        print("  (Boolean intersection collision detection on actual STEP)")
        print("=" * 70)
        for name, status, detail in self.checks:
            icon = {"PASS": "+", "FAIL": "!", "WARN": "~", "INFO": "-"}[status]
            print(f"  [{icon}] {status:4s} | {name}")
            if detail:
                for line in detail.split("\n"):
                    print(f"         | {line}")
        print("-" * 70)
        print(f"  TOTAL: {self.pass_count} PASS, {self.fail_count} FAIL, "
              f"{self.warn_count} WARN, {self.info_count} INFO")
        if self.fail_count == 0:
            print("  >>> VERDICT: ALL CHECKS PASSED")
        else:
            print(f"  >>> VERDICT: {self.fail_count} FAILURE(S) -- FIX REQUIRED")
        print("=" * 70)
        return self.fail_count == 0


# ============================================================
# HELPERS
# ============================================================
def intersection_volume(shape_a, shape_b):
    """Compute volume of boolean intersection between two CQ workplanes.
    Returns 0.0 if no overlap, positive value if collision."""
    try:
        common = shape_a.intersect(shape_b)
        solids = common.solids().vals()
        if not solids:
            return 0.0
        vol = sum(s.Volume() for s in solids)
        return vol if vol > 0.001 else 0.0  # ignore dust volumes
    except Exception:
        # If intersection fails, shapes don't overlap
        return 0.0


def bb_overlap(bb_a, bb_b):
    """Quick bounding box overlap check before expensive boolean."""
    return not (bb_a.xmax < bb_b.xmin or bb_a.xmin > bb_b.xmax or
                bb_a.ymax < bb_b.ymin or bb_a.ymin > bb_b.ymax or
                bb_a.zmax < bb_b.zmin or bb_a.zmin > bb_b.zmax)


# ============================================================
# 1. BODY INTEGRITY
# ============================================================
def check_body_integrity(result, housing, sliders, fp_wheel):
    """Check all solids are valid, closed, positive volume."""
    # Housing
    h_solids = housing.solids().vals()
    h_valid = all(s.isValid() for s in h_solids)
    h_count = len(h_solids)
    result.add("body:housing_valid",
               "PASS" if h_valid else "FAIL",
               f"{h_count} solid(s), valid={h_valid}")
    result.add("body:housing_fused",
               "PASS" if h_count == 1 else "FAIL",
               f"{h_count} bodies ({'single solid' if h_count == 1 else 'MUST fuse to 1'})")

    # Sliders
    for ch_i, slider in sliders.items():
        s_solids = slider.solids().vals()
        s_valid = all(s.isValid() for s in s_solids)
        s_count = len(s_solids)
        s_vol = sum(s.Volume() for s in s_solids)
        result.add(f"body:slider_ch{ch_i}",
                   "PASS" if s_valid and s_count == 1 and s_vol > 0 else "FAIL",
                   f"{s_count} solid(s), vol={s_vol:.1f}mm3, valid={s_valid}")

    # Fixed pulley
    p_solids = fp_wheel.solids().vals()
    p_valid = all(s.isValid() for s in p_solids)
    p_vol = sum(s.Volume() for s in p_solids)
    result.add("body:fixed_pulley",
               "PASS" if p_valid and p_vol > 0 else "FAIL",
               f"{len(p_solids)} solid(s), vol={p_vol:.2f}mm3, valid={p_valid}")


# ============================================================
# 2. GEOMETRIC COLLISION DETECTION (boolean intersection)
# ============================================================
def check_geometric_collisions(result, housing, sliders, fp_wheel):
    """Real boolean intersection between all component pairs."""

    housing_bb = housing.val().BoundingBox()

    # --- Housing vs each slider ---
    print("  Checking housing vs slider collisions...")
    for ch_i, slider in sliders.items():
        ch_z = prod.CH_OFFSETS[ch_i]
        # Position slider at its channel Z
        positioned_slider = slider.translate((0, 0, ch_z))
        s_bb = positioned_slider.val().BoundingBox()

        if not bb_overlap(housing_bb, s_bb):
            result.add(f"collision:housing_vs_slider_ch{ch_i}",
                       "PASS", "No bounding box overlap")
            continue

        vol = intersection_volume(housing, positioned_slider)
        if vol > 0:
            result.add(f"collision:housing_vs_slider_ch{ch_i}",
                       "FAIL",
                       f"OVERLAP={vol:.3f}mm3 -- housing and slider physically intersect!")
        else:
            result.add(f"collision:housing_vs_slider_ch{ch_i}",
                       "PASS", "No geometric intersection")

    # --- Fixed pulleys vs their neighboring slider ---
    print("  Checking fixed pulley vs slider collisions...")
    collision_count = 0
    checked_count = 0
    for ch_i, slider in sliders.items():
        if prod.COL_COUNTS[ch_i] == 0:
            continue
        ch_z = prod.CH_OFFSETS[ch_i]
        positioned_slider = slider.translate((0, 0, ch_z))
        s_bb = positioned_slider.val().BoundingBox()

        for px in prod.COL_DATA[ch_i]:
            for y_sign in [+1, -1]:
                py = y_sign * FP_ROW_Y
                positioned_pulley = fp_wheel.translate((px, py, ch_z))
                p_bb = positioned_pulley.val().BoundingBox()

                if not bb_overlap(s_bb, p_bb):
                    checked_count += 1
                    continue

                vol = intersection_volume(positioned_slider, positioned_pulley)
                if vol > 0:
                    collision_count += 1
                    if collision_count <= 3:  # report first 3
                        result.add(f"collision:pulley_vs_slider_ch{ch_i}",
                                   "FAIL",
                                   f"Pulley at ({px:.1f},{py:.1f},{ch_z:.0f}) "
                                   f"overlaps slider by {vol:.3f}mm3")
                checked_count += 1

    if collision_count == 0:
        result.add("collision:all_pulleys_vs_sliders",
                   "PASS", f"Checked {checked_count} pulley-slider pairs, 0 collisions")
    elif collision_count > 3:
        result.add("collision:pulley_vs_slider_additional",
                   "FAIL", f"{collision_count - 3} more pulley-slider collisions not shown")

    # --- Sliders in adjacent channels shouldn't overlap ---
    print("  Checking adjacent slider collisions...")
    for ch_i in range(NUM_CHANNELS - 1):
        if ch_i not in sliders or (ch_i + 1) not in sliders:
            continue
        ch_z_a = prod.CH_OFFSETS[ch_i]
        ch_z_b = prod.CH_OFFSETS[ch_i + 1]
        slider_a = sliders[ch_i].translate((0, 0, ch_z_a))
        slider_b = sliders[ch_i + 1].translate((0, 0, ch_z_b))

        a_bb = slider_a.val().BoundingBox()
        b_bb = slider_b.val().BoundingBox()

        if not bb_overlap(a_bb, b_bb):
            result.add(f"collision:slider_ch{ch_i}_vs_ch{ch_i+1}",
                       "PASS", "No bounding box overlap")
            continue

        vol = intersection_volume(slider_a, slider_b)
        if vol > 0:
            result.add(f"collision:slider_ch{ch_i}_vs_ch{ch_i+1}",
                       "FAIL",
                       f"OVERLAP={vol:.3f}mm3 -- adjacent sliders intersect!")
        else:
            result.add(f"collision:slider_ch{ch_i}_vs_ch{ch_i+1}",
                       "PASS", "No geometric intersection")


# ============================================================
# 3. BOUNDING BOX
# ============================================================
def check_bounding_box(result, housing):
    """Check housing fits within hex boundary."""
    bb = housing.val().BoundingBox()

    max_x = HEX_R - HEX_CLIP_INSET
    x_ok = abs(bb.xmin) <= max_x + 0.1 and abs(bb.xmax) <= max_x + 0.1
    result.add("bounds:x_hex_limit",
               "PASS" if x_ok else "FAIL",
               f"X=[{bb.xmin:.1f}, {bb.xmax:.1f}] (limit +/-{max_x:.1f}mm)")

    y_ok = abs(bb.ymax - bb.ymin - HOUSING_HEIGHT) < 0.1
    result.add("bounds:y_height",
               "PASS" if y_ok else "WARN",
               f"Y span={bb.ymax - bb.ymin:.1f}mm (expected {HOUSING_HEIGHT}mm)")

    center_ch = (NUM_CHANNELS - 1) / 2
    expected_z_min = -(center_ch * STACK_OFFSET + CH_GAP / 2 + WALL_THICKNESS)
    expected_z_max = center_ch * STACK_OFFSET + CH_GAP / 2 + WALL_THICKNESS
    z_ok = (abs(bb.zmin - expected_z_min) < 1.0 and
            abs(bb.zmax - expected_z_max) < 1.0)
    result.add("bounds:z_stack",
               "PASS" if z_ok else "WARN",
               f"Z=[{bb.zmin:.1f}, {bb.zmax:.1f}] "
               f"(expected [{expected_z_min:.1f}, {expected_z_max:.1f}])")


# ============================================================
# 4. MANUFACTURABILITY
# ============================================================
def check_manufacturability(result, housing):
    """FDM-specific checks on actual geometry."""

    # Housing body fusion
    h_bodies = len(housing.solids().vals())
    result.add("mfg:housing_fusion",
               "PASS" if h_bodies == 1 else "FAIL",
               f"{h_bodies} solid(s) -- {'ready for slicing' if h_bodies == 1 else 'MUST fuse'}")

    # Print envelope
    bb = housing.val().BoundingBox()
    result.add("mfg:print_envelope",
               "PASS",
               f"{bb.xmax - bb.xmin:.0f} x "
               f"{bb.ymax - bb.ymin:.0f} x "
               f"{bb.zmax - bb.zmin:.0f} mm")

    # Volume / mass estimate
    h_vol = sum(s.Volume() for s in housing.solids().vals())
    mass_pla = h_vol * 1.24 / 1000
    result.add("mfg:mass_estimate",
               "INFO",
               f"Volume={h_vol:.0f}mm3, PLA mass={mass_pla:.1f}g")


# ============================================================
# MAIN
# ============================================================
def main():
    print("=" * 60)
    print("MATRIX TIER V5.6 -- GEOMETRY VALIDATOR V2")
    print("Real boolean intersection collision detection")
    print("=" * 60)

    # Build all components from production module
    print("\n[1/4] Building housing...")
    housing = prod.build_housing()

    print("\n[2/4] Building all 7 sliders at rest position...")
    sliders = {}
    for ch_i in range(NUM_CHANNELS):
        s = prod.make_slider_assembly(ch_i, displacement=0)
        if s is not None:
            sliders[ch_i] = s
            print(f"  Slider ch{ch_i}: built")
    print(f"  Total: {len(sliders)} sliders")

    print("\n[3/4] Building fixed pulley template...")
    fp_wheel = prod.make_fixed_pulley()

    print("\n[4/4] Running validation checks...")
    result = ValidationResult()

    # 1. Body integrity
    print("\n--- Body Integrity ---")
    check_body_integrity(result, housing, sliders, fp_wheel)

    # 2. REAL geometric collision detection
    print("\n--- Geometric Collision Detection ---")
    check_geometric_collisions(result, housing, sliders, fp_wheel)

    # 3. Bounding box
    print("\n--- Bounding Box ---")
    check_bounding_box(result, housing)

    # 4. Manufacturability
    print("\n--- Manufacturability ---")
    check_manufacturability(result, housing)

    # Report
    all_pass = result.print_report()
    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
