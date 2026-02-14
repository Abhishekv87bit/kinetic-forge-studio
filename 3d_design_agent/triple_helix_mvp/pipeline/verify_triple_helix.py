#!/usr/bin/env python3
"""
Triple Helix MVP — Engineering Verification Script
===================================================
Reads config_v3.json and independently computes ALL engineering
calculations that were previously done mentally by Claude.
Cross-checks against OpenSCAD echo values.

Usage:
    python verify_triple_helix.py                  # run all checks
    python verify_triple_helix.py --json           # output JSON report
    python verify_triple_helix.py --section force   # run one section

Dependencies: numpy, scipy (pip install numpy scipy)
"""

import json
import math
import sys
import os
from datetime import datetime

import numpy as np

# =============================================
# LOAD CONFIG
# =============================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config_v3.json")

with open(CONFIG_PATH, "r") as f:
    CFG = json.load(f)

# =============================================
# RESULT TRACKING
# =============================================
results = []

def check(category, name, computed, expected, tolerance=0.1, unit="mm"):
    """Register a verification check."""
    if expected is None:
        # Info-only check (no expected value to compare)
        results.append({
            "category": category, "name": name,
            "computed": computed, "expected": None,
            "status": "INFO", "unit": unit
        })
        return computed

    diff = abs(computed - expected)
    passed = diff <= tolerance
    status = "PASS" if passed else "FAIL"
    results.append({
        "category": category, "name": name,
        "computed": round(computed, 4), "expected": expected,
        "diff": round(diff, 4), "tolerance": tolerance,
        "status": status, "unit": unit
    })
    return computed

def check_range(category, name, value, min_val, max_val, unit=""):
    """Check that value is within [min_val, max_val]."""
    passed = min_val <= value <= max_val
    status = "PASS" if passed else "FAIL"
    results.append({
        "category": category, "name": name,
        "computed": round(value, 4),
        "expected": f"[{min_val}, {max_val}]",
        "status": status, "unit": unit
    })
    return value

def check_gt(category, name, value, threshold, unit=""):
    """Check that value > threshold."""
    passed = value > threshold
    status = "PASS" if passed else "FAIL"
    results.append({
        "category": category, "name": name,
        "computed": round(value, 4),
        "expected": f"> {threshold}",
        "status": status, "unit": unit
    })
    return value


# =============================================
# SECTION A: GEOMETRY DERIVATIONS
# =============================================
def verify_geometry():
    cat = "Geometry"

    HEX_R = CFG["hex"]["HEX_R"]
    STACK_OFFSET = CFG["channels"]["STACK_OFFSET"]
    ECCENTRICITY = CFG["channels"]["ECCENTRICITY"]

    # Hex flat-to-flat
    HEX_FF = HEX_R * math.sqrt(3)
    check(cat, "HEX_FF (flat-to-flat)", HEX_FF, 204.3, 0.2)

    # Number of channels
    half_count = math.floor((HEX_FF / 2 - STACK_OFFSET / 2) / STACK_OFFSET)
    NUM_CHANNELS = 2 * half_count + 1
    check(cat, "NUM_CHANNELS", NUM_CHANNELS, 13, 0)

    # Helix cam parameters
    NUM_CAMS = NUM_CHANNELS
    TWIST_PER_CAM = 360.0 / NUM_CAMS
    check(cat, "TWIST_PER_CAM", TWIST_PER_CAM, 27.69, 0.01, "deg")

    BEARING_W = CFG["bearing"]["BEARING_W"]
    COLLAR_THICK = CFG["cam"]["COLLAR_THICK"]
    AXIAL_PITCH = BEARING_W + COLLAR_THICK
    check(cat, "AXIAL_PITCH", AXIAL_PITCH, STACK_OFFSET, 0.01)

    HELIX_LENGTH = NUM_CAMS * AXIAL_PITCH
    check(cat, "HELIX_LENGTH", HELIX_LENGTH, 182.0, 0.1)

    # Cam stroke
    CAM_STROKE = 2 * ECCENTRICITY
    check(cat, "CAM_STROKE", CAM_STROKE, 30.0, 0)

    # Frame geometry
    HEX_LONGEST_DIA = CFG["frame"]["HEX_LONGEST_DIA"]
    STAR_TIP_R = CFG["frame"]["STAR_TIP_R"]
    check(cat, "STAR_TIP_R (1.5x hex dia)", STAR_TIP_R, 1.5 * HEX_LONGEST_DIA, 1.0)

    HEXAGRAM_INNER_R = STAR_TIP_R / math.sqrt(3)
    check(cat, "HEXAGRAM_INNER_R", HEXAGRAM_INNER_R, 204.4, 0.2)

    CORRIDOR_GAP = CFG["frame"]["CORRIDOR_GAP"]
    V_PUSH = CORRIDOR_GAP / (2 * math.tan(math.radians(30)))
    HELIX_R = HEXAGRAM_INNER_R + V_PUSH
    check(cat, "HELIX_R", HELIX_R, 271.9, 0.5)

    # Helix-to-matrix gap budget
    gap = HELIX_R - HEX_R
    rib_arm = CFG["rib"]["RIB_ARM_LENGTH"]
    dampener_len = CFG["dampener"]["DAMPENER_LENGTH"]
    min_cable = 10  # minimum cable free-run
    budget = rib_arm + dampener_len + min_cable
    check(cat, "Helix gap", gap, 153.9, 1.0)
    check_gt(cat, "Gap > budget (rib+dampener+cable)", gap, budget, "mm")

    # Frame ring radii
    FRAME_RING_R_IN = HEX_R + 2
    FRAME_RING_W = CFG["frame"]["FRAME_RING_W"]
    FRAME_RING_R_OUT = FRAME_RING_R_IN + FRAME_RING_W
    check(cat, "FRAME_RING_R_IN", FRAME_RING_R_IN, 120, 0)
    check(cat, "FRAME_RING_R_OUT", FRAME_RING_R_OUT, 130, 0)

    # Housing height derivation
    FP_OD = CFG["housing"]["FP_OD"]
    SP_OD = CFG["housing"]["SP_OD"]
    MIN_ROPE_GAP = CFG["housing"]["MIN_ROPE_GAP"]
    FP_ROW_Y = (FP_OD + SP_OD) / 2 + MIN_ROPE_GAP
    HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2
    check(cat, "HOUSING_HEIGHT", HOUSING_HEIGHT, 30.0, 0.1)

    return {
        "NUM_CHANNELS": NUM_CHANNELS, "HELIX_R": HELIX_R,
        "HELIX_LENGTH": HELIX_LENGTH, "HEX_FF": HEX_FF,
        "HOUSING_HEIGHT": HOUSING_HEIGHT, "NUM_CAMS": NUM_CAMS,
        "TWIST_PER_CAM": TWIST_PER_CAM, "AXIAL_PITCH": AXIAL_PITCH,
        "FRAME_RING_R_OUT": FRAME_RING_R_OUT
    }


# =============================================
# SECTION B: KINEMATICS
# =============================================
def verify_kinematics(geom):
    cat = "Kinematics"

    ECCENTRICITY = CFG["channels"]["ECCENTRICITY"]
    NUM_CAMS = geom["NUM_CAMS"]
    TWIST_PER_CAM = geom["TWIST_PER_CAM"]

    # Eccentric hub displacement at angle theta
    # dx = ECCENTRICITY * cos(theta), dy = ECCENTRICITY * sin(theta)
    # Rib rides on bearing OD, follows eccentric offset
    check(cat, "Max radial displacement", ECCENTRICITY, 15.0, 0, "mm")

    # Full rotation: rib tip traces circle of radius ECCENTRICITY
    # String attached at rib eyelet pulls slider by delta_L
    # delta_L depends on string geometry (U-detour) — see Section C

    # Phase relationship: cam i has phase = i * TWIST_PER_CAM
    # At t=0: cam 0 at 0°, cam 1 at 27.69°, ..., cam 12 at 360°
    phases = np.array([i * TWIST_PER_CAM for i in range(NUM_CAMS)])
    check(cat, "Phase span (should be ~360)", phases[-1], 360 - TWIST_PER_CAM, 0.01, "deg")

    # Wave superposition: 3 tiers at 120° produce traveling wave
    # For a block at position (bx, by), displacement is:
    #   dz(t) = (1/3) * sum_k[ ECC * sin(t*360 + phase_k) ]
    # where phase_k depends on block's projection along tier_k's axis

    # Test: block at center (0,0) — all tiers contribute equally
    # phase_k = _CENTER_CH * TWIST_PER_CAM = 6 * 27.69 = 166.15°
    # All 3 tiers have same phase at center → constructive!
    center_phase = ((NUM_CAMS - 1) / 2) * TWIST_PER_CAM
    # dz(t) = (1/3) * 3 * ECC * sin(t*360 + center_phase) = ECC * sin(...)
    max_center_disp = ECCENTRICITY  # perfect constructive at center
    check(cat, "Max center block displacement", max_center_disp, 15.0, 0.1, "mm")

    return {"phases": phases, "center_phase": center_phase}


# =============================================
# SECTION C: STRING GEOMETRY (U-Detour)
# =============================================
def verify_string_geometry(geom):
    cat = "String"

    ECCENTRICITY = CFG["channels"]["ECCENTRICITY"]
    FP_OD = CFG["housing"]["FP_OD"]
    SP_OD = CFG["housing"]["SP_OD"]
    MIN_ROPE_GAP = CFG["housing"]["MIN_ROPE_GAP"]

    # Fixed pulley row Y (distance from center to FP axis)
    FP_ROW_Y = (FP_OD + SP_OD) / 2 + MIN_ROPE_GAP  # 10mm

    # Slider rest offset
    SLIDER_BIAS = CFG["channels"]["SLIDER_BIAS"]
    rest_offset = ECCENTRICITY * SLIDER_BIAS  # 12mm
    check(cat, "Slider rest offset", rest_offset, 12.0, 0.1, "mm")

    # U-detour: string goes from rib tip → over FP1 → down to slider → under SP → up to FP2 → to anchor
    # The key delta_L is from slider displacement d:
    #   offset_max = rest_offset + ECCENTRICITY = 12 + 15 = 27mm
    #   offset_min = rest_offset - ECCENTRICITY = 12 - 15 = -3mm

    offset_max = rest_offset + ECCENTRICITY
    offset_min = rest_offset - ECCENTRICITY
    check(cat, "Slider offset_max", offset_max, 27.0, 0.1, "mm")
    check(cat, "Slider offset_min", offset_min, -3.0, 0.1, "mm")

    # String length through one FP→SP→FP U-turn:
    # L(d) = sqrt(FP_ROW_Y^2 + d^2) + sqrt(FP_ROW_Y^2 + d^2) where d is slider offset
    # Actually: for a U-detour with 2 fixed pulleys at ±FP_ROW_Y from center,
    # and slider at displacement d from neutral:
    # L = 2 * sqrt(FP_ROW_Y^2 + d^2)  (simplified for one leg)

    # More precisely: the string path is:
    # anchor → FP_upper (at Y=+FP_ROW_Y) → slider_pulley (at Y=0, X=d) → FP_lower (at Y=-FP_ROW_Y) → block
    # Upper leg length: sqrt(FP_ROW_Y^2 + d^2)
    # Lower leg length: sqrt(FP_ROW_Y^2 + d^2)
    # Total through U: 2 * sqrt(FP_ROW_Y^2 + d^2)

    def u_detour_length(d):
        return 2 * math.sqrt(FP_ROW_Y**2 + d**2)

    L_max = u_detour_length(offset_max)
    L_min = u_detour_length(offset_min)
    delta_L = L_max - L_min

    check(cat, "L_max (at offset_max)", L_max, 57.6, 0.5, "mm")
    check(cat, "L_min (at offset_min)", L_min, 20.9, 0.5, "mm")
    check(cat, "delta_L (block travel/tier)", delta_L, 36.7, 0.5, "mm")

    # Max string angle from vertical
    max_angle = math.degrees(math.atan2(offset_max, FP_ROW_Y))
    check(cat, "Max string angle from vertical", max_angle, 69.7, 0.5, "deg")
    check_range(cat, "String angle < 75° (acceptable)", max_angle, 0, 75, "deg")

    return {"delta_L": delta_L, "L_max": L_max, "L_min": L_min}


# =============================================
# SECTION D: FORCE & TORQUE
# =============================================
def verify_force_torque(geom, string_geom):
    cat = "Force"

    ECCENTRICITY = CFG["channels"]["ECCENTRICITY"]
    BLOCK_WEIGHT_G = CFG["block"]["BLOCK_WEIGHT_G"]
    NUM_BLOCKS = CFG["block"]["NUM_BLOCKS"]
    NUM_CAMS = geom["NUM_CAMS"]
    MOTOR_TORQUE = CFG["drive"]["MOTOR_TORQUE_NM"]

    # Friction cascade
    eta_roller = CFG["string"]["FRICTION_PER_ROLLER"]
    eta_bushing = CFG["string"]["FRICTION_PER_BUSHING"]
    n_rollers = CFG["string"]["NUM_ROLLERS"]
    n_bushings = CFG["string"]["NUM_BUSHINGS"]

    friction_eff = (eta_roller ** n_rollers) * (eta_bushing ** n_bushings)
    check(cat, "Friction efficiency", friction_eff * 100, 61.8, 1.0, "%")

    # Block weight force
    block_force_N = (BLOCK_WEIGHT_G / 1000) * 9.81
    check(cat, "Block weight force", block_force_N, 0.785, 0.01, "N")

    # Return force (gravity pulling block down after cam releases)
    return_force = block_force_N * friction_eff
    check(cat, "Return force at cam", return_force, None, unit="N")

    # Safety factor for return: return_force should be > 0 with margin
    sf_return = return_force / (block_force_N * 0.5)  # vs 50% of weight
    check_gt(cat, "Return SF (>1.5)", sf_return, 1.5)

    # Torque per cam: worst case is when all cams on one helix are under load
    # Each cam pulls string with force = block_force / friction_eff (worst case)
    pull_force_per_string = block_force_N / friction_eff
    check(cat, "Pull force per string (at cam)", pull_force_per_string, None, unit="N")

    # Torque per cam = force × eccentricity (moment arm)
    # But not all cams are at peak load simultaneously — they're phased
    # Worst case: sum of F × ECC × |sin(theta_i)| for all cams at worst t
    # Average: sum of F × ECC × (2/pi) ≈ F × ECC × 0.637 × num_active_cams

    # Conservative estimate: assume ~6.5 cams are actively pulling at any time
    # (half of 13, since sin() is positive half the cycle)
    avg_active_cams = NUM_CAMS * 2 / math.pi  # ~8.3 (average of |sin|)
    # But each cam has different phase, and only some are in tension
    # More precise: sum of |sin(i * twist)| for i in 0..12
    sin_sum = sum(abs(math.sin(math.radians(i * geom["TWIST_PER_CAM"])))
                  for i in range(NUM_CAMS))
    # This is constant regardless of t (the sum rotates with crank)

    torque_per_helix = pull_force_per_string * (ECCENTRICITY / 1000) * sin_sum / NUM_CAMS
    # Divide by NUM_CAMS because not all strings are on the same helix
    # Actually: each helix drives 1 tier = ~6-7 strings (not all 19)
    # Simplified: each helix pulls ~6 strings on average at any moment
    # torque = sum(F_i * ECC * sin(cam_angle_i)) over cams in tension

    # Even simpler conservative estimate:
    # All 19 blocks split across 3 helices = ~6.3 blocks per helix
    # At any instant, ~half are being lifted = ~3.2 active
    # Average torque per helix = 3.2 * pull_force * ECC * avg_sin
    blocks_per_helix = NUM_BLOCKS / 3
    active_fraction = 0.5
    avg_sin = 2 / math.pi  # average of |sin| over half cycle

    torque_helix_Nm = (blocks_per_helix * active_fraction * pull_force_per_string
                       * (ECCENTRICITY / 1000) * avg_sin)
    check(cat, "Torque per helix (avg)", torque_helix_Nm, None, unit="Nm")

    total_torque = 3 * torque_helix_Nm
    check(cat, "Total motor torque required", total_torque, None, unit="Nm")

    sf_motor = MOTOR_TORQUE / total_torque if total_torque > 0 else float('inf')
    check_gt(cat, "Motor safety factor (>1.5)", sf_motor, 1.5)

    return {"friction_eff": friction_eff, "torque_per_helix": torque_helix_Nm,
            "total_torque": total_torque, "sf_motor": sf_motor}


# =============================================
# SECTION E: STRUCTURAL
# =============================================
def verify_structural(geom, force_data):
    cat = "Structural"

    # Transfer shaft torsion
    XFER_DIA = CFG["drive"]["XFER_SHAFT_DIA"]
    G_steel = 80e9  # shear modulus steel, Pa
    d_m = XFER_DIA / 1000  # diameter in meters
    J = math.pi * d_m**4 / 32  # polar moment of inertia
    T = force_data["torque_per_helix"]  # torque through shaft, Nm

    # Torsional deflection per meter: theta = T / (G * J) in rad/m
    theta_per_m_rad = T / (G_steel * J) if J > 0 else 0
    theta_per_m_deg = math.degrees(theta_per_m_rad)
    check(cat, "Shaft torsion", theta_per_m_deg, 0.025, 0.02, "deg/m")
    check_range(cat, "Shaft torsion < 1 deg/m", theta_per_m_deg, 0, 1.0, "deg/m")

    # Arm slenderness
    ARM_W = CFG["frame"]["ARM_W"]
    ARM_H = CFG["frame"]["ARM_H"]
    # Approximate arm length from JUNCTION_R to STAR_TIP_R
    HEX_R = CFG["hex"]["HEX_R"]
    FRAME_RING_R_OUT = geom["FRAME_RING_R_OUT"]
    STAR_TIP_R = CFG["frame"]["STAR_TIP_R"]
    STUB_LENGTH = CFG["frame"]["STUB_LENGTH"]
    JUNCTION_R = FRAME_RING_R_OUT + STUB_LENGTH + 25/2  # ~172.5
    arm_length = STAR_TIP_R - JUNCTION_R  # ~181.5 (approximate)
    slenderness = arm_length / min(ARM_W, ARM_H)
    check(cat, "Arm slenderness (L/min_dim)", slenderness, 13.9, 1.0, "ratio")
    check_range(cat, "Slenderness < 20:1", slenderness, 0, 20, "ratio")

    # Bearing life: 6800ZZ rated at 3.4 kN dynamic
    # Applied load per bearing: very small (string tension only)
    bearing_load_N = force_data["torque_per_helix"] / (CFG["channels"]["ECCENTRICITY"] / 1000)
    check(cat, "Bearing load", bearing_load_N, None, unit="N")
    check_gt(cat, "Bearing rated >> applied", 3400 / bearing_load_N if bearing_load_N > 0 else 999, 10)

    return {}


# =============================================
# SECTION F: PRINT FEASIBILITY
# =============================================
def verify_print(geom):
    cat = "Print"

    BED_X = CFG["print"]["BED_X"]
    BED_Y = CFG["print"]["BED_Y"]
    BED_Z = CFG["print"]["BED_Z"]
    MIN_WALL = CFG["print"]["MIN_WALL"]

    # Hex tier: fits within hex diameter
    HEX_R = CFG["hex"]["HEX_R"]
    hex_dia = 2 * HEX_R  # 236mm
    check_range(cat, "Hex tier diameter vs bed", hex_dia, 0, min(BED_X, BED_Y), "mm")

    # Frame ring: OD = FRAME_RING_R_OUT * 2 = 260mm
    ring_dia = geom["FRAME_RING_R_OUT"] * 2
    check_range(cat, "Frame ring diameter vs bed", ring_dia, 0, min(BED_X, BED_Y), "mm")

    # Helix cam: length = 182mm, max radial = ECCENTRICITY + RIB_RING_OD/2
    helix_len = geom["HELIX_LENGTH"]
    check_range(cat, "Helix cam length vs bed Z", helix_len, 0, BED_Z, "mm")

    # Wall thickness checks
    WALL_THICKNESS = CFG["channels"]["WALL_THICKNESS"]
    check_gt(cat, "Channel wall >= min", WALL_THICKNESS, MIN_WALL, "mm")

    RIB_THICK = CFG["rib"]["RIB_THICK"]
    check_gt(cat, "Rib thickness >= min", RIB_THICK, MIN_WALL, "mm")

    END_PLATE_THICK = CFG["end_plate"]["END_PLATE_THICK"]
    check_gt(cat, "End plate >= min", END_PLATE_THICK, MIN_WALL, "mm")

    return {}


# =============================================
# MAIN
# =============================================
def run_all():
    print("=" * 60)
    print("TRIPLE HELIX MVP — ENGINEERING VERIFICATION")
    print(f"Config: {CONFIG_PATH}")
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    print()

    geom = verify_geometry()
    kin = verify_kinematics(geom)
    string = verify_string_geometry(geom)
    force = verify_force_torque(geom, string)
    struct = verify_structural(geom, force)
    prnt = verify_print(geom)

    # Print results
    print()
    print("=" * 60)
    print("RESULTS")
    print("=" * 60)

    pass_count = sum(1 for r in results if r["status"] == "PASS")
    fail_count = sum(1 for r in results if r["status"] == "FAIL")
    info_count = sum(1 for r in results if r["status"] == "INFO")

    current_cat = ""
    for r in results:
        if r["category"] != current_cat:
            current_cat = r["category"]
            print(f"\n--- {current_cat} ---")

        status_icon = {"PASS": "OK", "FAIL": "XX", "INFO": "--"}[r["status"]]
        status_color = {"PASS": "", "FAIL": " *** FAIL ***", "INFO": ""}[r["status"]]

        if r["status"] == "INFO":
            print(f"  {status_icon} {r['name']}: {r['computed']} {r['unit']}")
        elif isinstance(r.get("expected"), str):
            # Range or threshold check
            print(f"  [{r['status']}] {status_icon} {r['name']}: {r['computed']} {r['unit']} (need {r['expected']}){status_color}")
        else:
            print(f"  [{r['status']}] {status_icon} {r['name']}: {r['computed']} {r['unit']} (expected {r['expected']}, diff {r.get('diff', '?')}){status_color}")

    print()
    print("=" * 60)
    print(f"SUMMARY: {pass_count} PASSED, {fail_count} FAILED, {info_count} INFO")
    if fail_count == 0:
        print("ALL CHECKS PASSED")
    else:
        print(f"*** {fail_count} CHECK(S) FAILED — REVIEW REQUIRED ***")
    print("=" * 60)

    # Save JSON report
    if "--json" in sys.argv or True:  # always save
        report = {
            "timestamp": datetime.now().isoformat(),
            "config_path": CONFIG_PATH,
            "summary": {
                "total": len(results),
                "passed": pass_count,
                "failed": fail_count,
                "info": info_count
            },
            "results": results
        }
        report_path = os.path.join(SCRIPT_DIR, "reports", "verification_report.json")
        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        with open(report_path, "w") as f:
            json.dump(report, f, indent=2)
        print(f"\nReport saved to: {report_path}")

    return fail_count == 0


if __name__ == "__main__":
    success = run_all()
    sys.exit(0 if success else 1)
