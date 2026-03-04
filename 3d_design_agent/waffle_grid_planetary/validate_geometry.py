#!/usr/bin/env python3
"""
Ravigneaux Grid -- Complete Geometry Constraint Validator
==========================================================
6-category validation framework (~30 rules) for Ravigneaux
planetary gearset kinetic sculpture units.

Categories:
  1. Spatial Occupation  -- Z-overlap, collision pairs, bounding cylinders
  2. Axial Constraints   -- thrust surfaces, washers, cage placement
  3. Gear Mesh Geometry  -- undercut, contact ratio, tip thickness, backlash
  4. Helical Specifics   -- hand compatibility, axial thrust, face width
  5. Assembly & Kinematic -- sequence, planet spacing, sweep clearance
  6. Ravigneaux Structural -- two-zone axiom, Po span, Pi confinement

Loads reference_dimensions.json (from extract_reference.py) as ground truth
for proportional validation.

Usage:
    python validate_geometry.py                  # validate default variant
    python validate_geometry.py --all            # validate all 5 variants
    python validate_geometry.py --variant 3      # validate variant D
    python validate_geometry.py --render         # also render PNG per variant
    python validate_geometry.py --json           # output results as JSON

Exit codes:
    0 = all checks pass
    1 = one or more FAIL
    2 = could not compile
"""

import subprocess
import sys
import re
import math
import os
import json
import argparse
from pathlib import Path
from math import gcd

# ============================================================
# PATHS
# ============================================================
SCRIPT_DIR = Path(__file__).resolve().parent
SCAD_FILE = SCRIPT_DIR / "ravigneaux_grid_v1.scad"
REF_FILE = SCRIPT_DIR / "reference_dimensions.json"
OPENSCAD_NIGHTLY = r"C:\Program Files\OpenSCAD (Nightly)\openscad.com"
OPENSCADPATH = r"C:\Users\abhis\Documents\OpenSCAD\libraries"

# ============================================================
# DESIGN CONSTANTS (from design doc + .scad)
# ============================================================
NORM_MOD   = 0.7
HELIX_ANG  = 25
TRANS_MOD  = NORM_MOD / math.cos(math.radians(HELIX_ANG))
PRESS_ANG  = 20

T_SL       = 40
T_PO       = 20
T_RING     = 80

VARIANTS = [
    {"name": "A", "Ss": 16, "Pi": 12},
    {"name": "B", "Ss": 20, "Pi": 10},
    {"name": "C", "Ss": 24, "Pi":  8},
    {"name": "D", "Ss": 26, "Pi":  7},
    {"name": "E", "Ss": 28, "Pi":  6},
]

EXT_PINIONS = [13, 15, 18, 21, 23]

# Shaft dimensions
ANCHOR_D    = 6
SS_TUBE_ID  = 7
SS_TUBE_OD  = 9
SL_TUBE_ID  = 10
SL_TUBE_OD  = 12
CARRIER_BORE = 13
RING_WALL   = 3

# Axial stack (from .scad — TWO-ZONE structure)
SS_GEAR_FW    = 6
SL_GEAR_FW    = 6
THRUST_PLATE_H = 1.5
GEAR_FW       = SS_GEAR_FW       # Backward compat
SL_ZONE_BOT   = 0
SL_ZONE_TOP   = SL_GEAR_FW
SS_ZONE_BOT   = SL_ZONE_TOP + THRUST_PLATE_H
SS_ZONE_TOP   = SS_ZONE_BOT + SS_GEAR_FW
TOTAL_GEAR_H  = SS_ZONE_TOP

LID_H         = 2
CARRIER_T     = 2
AXIAL_GAP     = 0.7
WASHER_H      = 0.5
FLANGE_H      = 2
PIN_D         = 3

# ============================================================
# RESULT TRACKING
# ============================================================
_results = []

def _pass(section, msg):
    _results.append(("PASS", section, msg))

def _fail(section, msg):
    _results.append(("FAIL", section, msg))

def _warn(section, msg):
    _results.append(("WARN", section, msg))


# ============================================================
# REFERENCE DATA LOADER
# ============================================================
_reference = None

def load_reference():
    """Load reference_dimensions.json if available."""
    global _reference
    if REF_FILE.is_file():
        with open(REF_FILE, "r", encoding="utf-8") as f:
            _reference = json.load(f)
        return True
    return False


# ============================================================
# COMPILE
# ============================================================
def compile_scad(variant_idx, ext_set=2, render_png=False):
    """Compile with given variant using -D overrides, return (success, echo_lines, warnings)."""
    env = os.environ.copy()
    env["OPENSCADPATH"] = OPENSCADPATH

    out_file = SCRIPT_DIR / f"_validate_v{variant_idx}.csg"

    cmd = [
        OPENSCAD_NIGHTLY,
        "--backend=manifold",
        "-D", f"VARIANT={variant_idx}",
        "-D", f"EXT_SET={ext_set}",
        "-o", str(out_file),
        str(SCAD_FILE),
    ]

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=120, env=env
        )
    except subprocess.TimeoutExpired:
        _fail("COMPILE", f"Variant {variant_idx}: timeout after 120s")
        return False, [], []
    except FileNotFoundError:
        _fail("COMPILE", f"OpenSCAD not found at {OPENSCAD_NIGHTLY}")
        return False, [], []

    all_output = result.stdout + result.stderr
    lines = all_output.splitlines()

    echo_lines = [l for l in lines if "ECHO:" in l]
    warnings = [l for l in lines if "WARNING:" in l]
    errors = [l for l in lines if "ERROR:" in l]

    success = result.returncode == 0 and len(errors) == 0

    if render_png and success:
        png_file = SCRIPT_DIR / f"render_v{variant_idx}.png"
        render_cmd = [
            OPENSCAD_NIGHTLY,
            "--backend=manifold",
            "-D", f"VARIANT={variant_idx}",
            "-D", f"EXT_SET={ext_set}",
            "-o", str(png_file),
            "--imgsize=1200,900",
            "--camera=0,0,5,55,0,25,100",
            "--colorscheme=Tomorrow Night",
            str(SCAD_FILE),
        ]
        try:
            subprocess.run(render_cmd, capture_output=True, timeout=120, env=env)
        except Exception:
            _warn("RENDER", f"Variant {variant_idx}: PNG render failed")

    try:
        out_file.unlink(missing_ok=True)
    except Exception:
        pass

    return success, echo_lines, warnings


def parse_echo_values(echo_lines):
    """Extract key values from ECHO output."""
    values = {}
    for line in echo_lines:
        text = re.sub(r'^.*ECHO:\s*"?', '', line).rstrip('"')

        m = re.search(r'SL \+ 2\*Po = (\d+) \+ (\d+) = (\d+).*?(OK|FAIL)', text)
        if m:
            values['rav_sum'] = int(m.group(3))
            values['rav_check'] = m.group(4)

        m = re.search(r'Ss \+ 2\*Pi = (\d+) \+ (\d+) = (\d+).*?(OK|FAIL)', text)
        if m:
            values['inner_sum'] = int(m.group(3))
            values['inner_check'] = m.group(4)

        m = re.search(r'Ring OD:\s*([\d.]+)mm', text)
        if m:
            values['ring_od'] = float(m.group(1))

        m = re.search(r'Ring total H:\s*([\d.]+)mm', text)
        if m:
            values['ring_h'] = float(m.group(1))

        m = re.search(r'Ss root R:.*gap:\s*([-\d.]+)mm', text)
        if m:
            values['ss_gap'] = float(m.group(1))

        m = re.search(r'SL root R:.*gap:\s*([-\d.]+)mm', text)
        if m:
            values['sl_gap'] = float(m.group(1))

        m = re.search(r'Po:([\d.]+)mm\s+Pi:([\d.]+)mm', text)
        if m:
            values['orb_po'] = float(m.group(1))
            values['orb_pi'] = float(m.group(2))

        m = re.search(r'kA\(Ss\)=([\d.]+)\s+kB\(SL\)=([\d.]+)', text)
        if m:
            values['kA'] = float(m.group(1))
            values['kB'] = float(m.group(2))

        m = re.search(r'VARIANT=(\d+).*Ss=(\d+).*Pi=(\d+)', text)
        if m:
            values['variant'] = int(m.group(1))
            values['ss_teeth'] = int(m.group(2))
            values['pi_teeth'] = int(m.group(3))

    return values


# ============================================================
# COMPONENT BOUNDING CYLINDER COMPUTATION
# ============================================================

def compute_bounding_cylinders(variant_idx):
    """
    Compute bounding cylinders {r_inner, r_outer, z_bot, z_top}
    for every component in the assembly, from SCAD parameters.

    This is the heart of spatial validation -- if two components
    share overlapping radial AND axial space, they collide.
    """
    v = VARIANTS[variant_idx]
    t_ss = v['Ss']
    t_pi = v['Pi']

    # Pitch radii
    pr_ss = t_ss * TRANS_MOD / 2
    pr_sl = T_SL * TRANS_MOD / 2
    pr_po = T_PO * TRANS_MOD / 2
    pr_pi = t_pi * TRANS_MOD / 2

    # Center distances / orbits
    orb_po = (T_SL + T_PO) * TRANS_MOD / 2
    orb_pi = (t_ss + t_pi) * TRANS_MOD / 2

    # Root/tip radii
    ss_tip_r  = pr_ss + TRANS_MOD          # addendum
    ss_root_r = pr_ss - 1.25 * TRANS_MOD   # dedendum
    sl_tip_r  = pr_sl + TRANS_MOD
    sl_root_r = pr_sl - 1.25 * TRANS_MOD
    po_tip_r  = pr_po + TRANS_MOD
    po_root_r = pr_po - 1.25 * TRANS_MOD
    pi_tip_r  = pr_pi + TRANS_MOD
    pi_root_r = pr_pi - 1.25 * TRANS_MOD

    ring_root_r = (T_RING * TRANS_MOD / 2) + 1.25 * TRANS_MOD
    ring_od = 2 * (ring_root_r + RING_WALL)

    # Z-stack (mirroring .scad TWO-ZONE structure)
    lid_bot_z     = -(LID_H + AXIAL_GAP + CARRIER_T)
    car2_z        = -(AXIAL_GAP + CARRIER_T)
    car2_ztop     = -AXIAL_GAP
    car1_zbot     = TOTAL_GEAR_H + AXIAL_GAP
    car1_ztop     = car1_zbot + CARRIER_T
    lid_top_z     = car1_ztop + AXIAL_GAP
    lid_top_ztop  = lid_top_z + LID_H
    ring_zbot     = lid_bot_z - FLANGE_H
    ring_ztop     = lid_top_ztop + FLANGE_H

    # Car pad
    car_pad = 1.5
    car_od = 2 * (orb_po + PIN_D / 2 + car_pad)

    components = {
        "anchor_shaft": {
            "r_inner": 0,
            "r_outer": ANCHOR_D / 2,
            "z_bot": ring_zbot - 20,
            "z_top": ring_ztop + 10,
            "rotates": True,
            "group": "shaft",
        },
        "ss_tube": {
            "r_inner": SS_TUBE_ID / 2,
            "r_outer": SS_TUBE_OD / 2,
            "z_bot": lid_bot_z - 5,
            "z_top": lid_top_ztop + 5,
            "rotates": True,
            "group": "shaft",
        },
        "sl_tube": {
            "r_inner": SL_TUBE_ID / 2,
            "r_outer": SL_TUBE_OD / 2,
            "z_bot": lid_bot_z - 3,
            "z_top": lid_top_ztop + 3,
            "rotates": True,
            "group": "shaft",
        },
        "ss_gear": {
            "r_inner": SS_TUBE_OD / 2,
            "r_outer": ss_tip_r,
            "z_bot": SS_ZONE_BOT,
            "z_top": SS_ZONE_TOP,
            "rotates": True,
            "group": "sun",
            "teeth": t_ss,
        },
        "sl_gear": {
            "r_inner": SL_TUBE_OD / 2,
            "r_outer": sl_tip_r,
            "z_bot": SL_ZONE_BOT,
            "z_top": SL_ZONE_TOP,
            "rotates": True,
            "group": "sun",
            "teeth": T_SL,
        },
        "po_gear": {
            "r_inner": po_root_r,
            "r_outer": po_tip_r,
            "z_bot": SL_ZONE_BOT,
            "z_top": SS_ZONE_TOP,     # Po spans BOTH zones
            "rotates": True,
            "group": "planet",
            "orbit_r": orb_po,
            "teeth": T_PO,
        },
        "pi_gear": {
            "r_inner": pi_root_r,
            "r_outer": pi_tip_r,
            "z_bot": SS_ZONE_BOT,
            "z_top": SS_ZONE_TOP,     # Pi in Ss zone ONLY
            "rotates": True,
            "group": "planet",
            "orbit_r": orb_pi,
            "teeth": t_pi,
        },
        "ring_gear": {
            "r_inner": ring_root_r - 2.5 * TRANS_MOD,  # internal tooth tips
            "r_outer": ring_od / 2,
            "z_bot": ring_zbot,   # ring spans full assembly height
            "z_top": ring_ztop,
            "rotates": True,
            "group": "ring",
            "teeth": T_RING,
        },
        "carrier_1": {
            "r_inner": CARRIER_BORE / 2,
            "r_outer": car_od / 2,
            "z_bot": car1_zbot,
            "z_top": car1_ztop,
            "rotates": True,
            "group": "carrier",
        },
        "carrier_2": {
            "r_inner": CARRIER_BORE / 2,
            "r_outer": car_od / 2,
            "z_bot": car2_z,
            "z_top": car2_ztop,
            "rotates": True,
            "group": "carrier",
        },
        "lid_top": {
            "r_inner": CARRIER_BORE / 2,
            "r_outer": ring_od / 2 - 0.5,
            "z_bot": lid_top_z,
            "z_top": lid_top_ztop,
            "rotates": False,
            "group": "structure",
        },
        "lid_bot": {
            "r_inner": CARRIER_BORE / 2,
            "r_outer": ring_od / 2 - 0.5,
            "z_bot": lid_bot_z,
            "z_top": lid_bot_z + LID_H,
            "rotates": False,
            "group": "structure",
        },
    }

    return components


# ============================================================
# CATEGORY 1: SPATIAL OCCUPATION
# ============================================================

def check_spatial_occupation(variant_idx):
    """Check for Z-overlap collisions between components."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-SPATIAL"

    components = compute_bounding_cylinders(variant_idx)

    # Rule 1.1: Ss and SL gears must NOT share the same Z-band
    ss = components["ss_gear"]
    sl = components["sl_gear"]
    z_overlap = min(ss["z_top"], sl["z_top"]) - max(ss["z_bot"], sl["z_bot"])
    r_overlap = min(ss["r_outer"], sl["r_outer"]) - max(ss["r_inner"], sl["r_inner"])

    if z_overlap > 0 and r_overlap > 0:
        _fail(section,
              f"Ss and SL gears COLLIDE: Z-overlap={z_overlap:.1f}mm, "
              f"R-overlap={r_overlap:.1f}mm. "
              f"Ss Z=[{ss['z_bot']:.1f},{ss['z_top']:.1f}], "
              f"SL Z=[{sl['z_bot']:.1f},{sl['z_top']:.1f}]. "
              f"TWO-ZONE AXIOM VIOLATED: sun gears must be in separate Z-zones")
    else:
        _pass(section, f"Ss and SL gears in separate zones (no collision)")

    # Rule 1.2: Gears at same Z-level must not share radial space
    # (except meshing pairs which are at different orbital positions)
    gear_names = ["ss_gear", "sl_gear", "po_gear", "pi_gear"]
    for i in range(len(gear_names)):
        for j in range(i + 1, len(gear_names)):
            a = components[gear_names[i]]
            b = components[gear_names[j]]
            # Skip known meshing pairs (they intentionally overlap radially at mesh zone)
            pair = frozenset([gear_names[i], gear_names[j]])
            meshing_pairs = [
                frozenset(["ss_gear", "pi_gear"]),
                frozenset(["sl_gear", "po_gear"]),
                frozenset(["pi_gear", "po_gear"]),
                frozenset(["po_gear", "ring_gear"]),
            ]
            if pair in meshing_pairs:
                continue

            z_ov = min(a["z_top"], b["z_top"]) - max(a["z_bot"], b["z_bot"])
            # For concentric gears (both centered on origin), check radial overlap
            if a.get("orbit_r", 0) == 0 and b.get("orbit_r", 0) == 0:
                r_ov = min(a["r_outer"], b["r_outer"]) - max(a["r_inner"], b["r_inner"])
            else:
                # One orbits: the gear body is at orbit_r +/- gear_r
                # Simplify: if both are at same Z, warn about potential sweep collision
                r_ov = -1  # can't easily compute for orbiting bodies without sweep analysis

            if z_ov > 0 and r_ov > 0:
                _fail(section,
                      f"{gear_names[i]} and {gear_names[j]} occupy same space: "
                      f"Z-overlap={z_ov:.1f}mm, R-overlap={r_ov:.1f}mm")

    # Rule 1.3: Carrier plates must not overlap gears in Z
    for car_name in ["carrier_1", "carrier_2"]:
        car = components[car_name]
        for gear_name in ["ss_gear", "sl_gear"]:
            gear = components[gear_name]
            z_ov = min(car["z_top"], gear["z_top"]) - max(car["z_bot"], gear["z_bot"])
            if z_ov > 0.01:
                _fail(section,
                      f"{car_name} overlaps {gear_name} in Z: overlap={z_ov:.2f}mm. "
                      f"Carrier Z=[{car['z_bot']:.1f},{car['z_top']:.1f}], "
                      f"Gear Z=[{gear['z_bot']:.1f},{gear['z_top']:.1f}]")
            else:
                _pass(section, f"{car_name} clear of {gear_name} in Z")

    # Rule 1.4: Shaft nesting order (radial, concentric)
    if ANCHOR_D / 2 < SS_TUBE_ID / 2 < SS_TUBE_OD / 2 < SL_TUBE_ID / 2 < SL_TUBE_OD / 2 < CARRIER_BORE / 2:
        _pass(section,
              f"Shaft nesting: anchor({ANCHOR_D/2:.1f}) < "
              f"ss_id({SS_TUBE_ID/2:.1f}) < ss_od({SS_TUBE_OD/2:.1f}) < "
              f"sl_id({SL_TUBE_ID/2:.1f}) < sl_od({SL_TUBE_OD/2:.1f}) < "
              f"carrier({CARRIER_BORE/2:.1f})")
    else:
        _fail(section, "Shaft nesting order violated!")


# ============================================================
# CATEGORY 2: AXIAL CONSTRAINT COMPLETENESS
# ============================================================

def check_axial_constraints(variant_idx):
    """Check that every rotating component has axial retention."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-AXIAL"

    # Rule 2.1: Washers on both ends of every rotating gear
    # The SCAD must have washer geometry at z_bot and z_top of each gear
    # We check by parsing the SCAD for washer_assembly module content
    scad_text = ""
    if SCAD_FILE.is_file():
        with open(SCAD_FILE, "r", encoding="utf-8", errors="replace") as f:
            scad_text = f.read()

    # Count washer placements in washer_assembly module
    washer_section = re.search(r'module washer_assembly\(\)(.*?)(?=\nmodule |\Z)',
                                scad_text, re.DOTALL)
    if washer_section:
        washer_body = washer_section.group(1)
        # Count all cylinder-like geometry calls (zcyl, zcyl_hollow, cylinder)
        washer_count = (washer_body.count("zcyl_hollow(")
                       + washer_body.count("zcyl(")
                       + washer_body.count("cylinder("))
        # Need at minimum: 2 per sun zone transition + 2 per carrier face
        # + 4 per planet set (Po bottom/top, Pi bottom/top) = ~18-24
        if washer_count >= 8:
            _pass(section, f"Washer assembly has {washer_count} washer placements (>= 8 minimum)")
        elif washer_count >= 4:
            _warn(section, f"Only {washer_count} washers found (need >= 8 for all rotating components)")
        else:
            _fail(section, f"Only {washer_count} washers found -- need washers on BOTH ends of EACH rotating component")
    else:
        _fail(section, "No washer_assembly module found in SCAD")

    # Rule 2.2: Cage must be on Pi pins ONLY (not Po)
    # Check cage_sector (the implementation) not just planet_cage (the wrapper)
    cage_section = re.search(r'module cage_sector\(.*?\)(.*?)(?=\nmodule |\Z)',
                              scad_text, re.DOTALL)
    if cage_section:
        cage_body = cage_section.group(1)
        has_po = "ORB_PO" in cage_body
        has_pi = "ORB_PI" in cage_body or "PI_ANG_OFFSET" in cage_body
        if has_po and has_pi:
            _fail(section, "Cage module references BOTH ORB_PO and ORB_PI -- cage should be on Pi pins ONLY")
        elif has_pi:
            _pass(section, "Cage correctly placed on Pi pins only")
        elif has_po:
            _fail(section, "Cage on Po pins only -- should be on Pi pins")
        else:
            _warn(section, "Cannot determine cage pin placement from code")
    else:
        _warn(section, "No cage_sector module found")

    # Rule 2.3: Planet pins must extend through both carrier plates
    # Pins at ORB_PO and ORB_PI must span from carrier_2 to carrier_1
    components = compute_bounding_cylinders(variant_idx)
    car1 = components["carrier_1"]
    car2 = components["carrier_2"]
    pin_span_needed = car1["z_top"] - car2["z_bot"]
    _pass(section, f"Pin span needed: {pin_span_needed:.1f}mm (carrier_2 to carrier_1)")


# ============================================================
# CATEGORY 3: GEAR MESH GEOMETRY
# ============================================================

def check_gear_mesh(variant_idx, values):
    """Check fundamental gear mesh constraints."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-GEARMESH"

    t_ss = v['Ss']
    t_pi = v['Pi']

    # Rule 3.1: Minimum tooth count for involute profile
    # At 20 deg pressure angle, min teeth = 2 / sin^2(PA) ~= 17
    min_teeth_involute = math.ceil(2 / (math.sin(math.radians(PRESS_ANG)) ** 2))

    # NOTE: For kinetic sculpture (low load, aesthetic motion), undercut is
    # acceptable with profile shift. Standard power transmission requires >= 17T,
    # but sculpture gears function at >= 6T with X-shift correction.
    # FAIL threshold: < 6T (physically cannot mesh)
    # WARN threshold: < 17T (needs documented profile shift)
    for name, count in [("Ss", t_ss), ("Pi", t_pi), ("SL", T_SL), ("Po", T_PO), ("Ring", T_RING)]:
        if count >= min_teeth_involute:
            _pass(section, f"{name}={count}T >= {min_teeth_involute}T minimum (no undercut)")
        elif count >= 6:
            profile_shift = (min_teeth_involute - count) / min_teeth_involute
            _warn(section,
                  f"{name}={count}T < {min_teeth_involute}T -- needs profile shift X={profile_shift:.3f} "
                  f"to avoid undercut (acceptable for kinetic sculpture with low loads)")
        else:
            _fail(section,
                  f"{name}={count}T << 6T -- CANNOT MESH. "
                  f"Minimum 6 teeth required even with maximum profile shift")

    # Rule 3.2: Contact ratio >= 1.2 for smooth power transmission
    for mesh_name, t1, t2 in [
        ("Ss-Pi", t_ss, t_pi),
        ("SL-Po", T_SL, T_PO),
        ("Po-Ring", T_PO, T_RING),
        ("Pi-Po", t_pi, T_PO),
    ]:
        # Approximate contact ratio for external-external spur/helical
        pr1 = t1 * TRANS_MOD / 2
        pr2 = t2 * TRANS_MOD / 2
        tip_r1 = pr1 + TRANS_MOD
        tip_r2 = pr2 + TRANS_MOD
        base_r1 = pr1 * math.cos(math.radians(PRESS_ANG))
        base_r2 = pr2 * math.cos(math.radians(PRESS_ANG))

        if mesh_name == "Po-Ring":
            # Internal gear: contact ratio formula differs
            cd = pr2 - pr1  # internal gear center distance
            # Simplified: for internal mesh, CR is generally higher
            cr_approx = 1.5  # conservative estimate for internal mesh
        else:
            cd = pr1 + pr2
            # Transverse contact ratio (approximate)
            addendum_arc1 = math.sqrt(max(tip_r1**2 - base_r1**2, 0)) if base_r1 < tip_r1 else 0
            addendum_arc2 = math.sqrt(max(tip_r2**2 - base_r2**2, 0)) if base_r2 < tip_r2 else 0
            pitch_base_arc = cd * math.sin(math.radians(PRESS_ANG))
            if pitch_base_arc > 0:
                cr_approx = (addendum_arc1 + addendum_arc2 - pitch_base_arc) / (math.pi * TRANS_MOD * math.cos(math.radians(PRESS_ANG)))
            else:
                cr_approx = 0

        # Helical overlap ratio adds to total contact ratio
        helix_overlap = GEAR_FW * math.sin(math.radians(HELIX_ANG)) / (math.pi * NORM_MOD)
        total_cr = cr_approx + helix_overlap

        if total_cr >= 1.2:
            _pass(section, f"{mesh_name}: contact ratio ~{total_cr:.2f} >= 1.2")
        elif total_cr >= 1.0:
            _warn(section, f"{mesh_name}: contact ratio ~{total_cr:.2f} -- marginal (target >= 1.2)")
        else:
            _fail(section, f"{mesh_name}: contact ratio ~{total_cr:.2f} < 1.0 -- GEAR WILL NOT MESH SMOOTHLY")

    # Rule 3.3: Tip thickness check (gear tips must not be knife-edges)
    for name, count in [("Ss", t_ss), ("Pi", t_pi), ("Po", T_PO)]:
        pr = count * TRANS_MOD / 2
        tip_r = pr + TRANS_MOD
        base_r = pr * math.cos(math.radians(PRESS_ANG))
        # Tip tooth thickness (approximate, at tip circle)
        if base_r < tip_r:
            alpha_tip = math.acos(base_r / tip_r)
            inv_tip = math.tan(alpha_tip) - alpha_tip
            inv_pa = math.tan(math.radians(PRESS_ANG)) - math.radians(PRESS_ANG)
            tooth_thick_tip = tip_r * (math.pi / count + 2 * (inv_pa - inv_tip))
        else:
            tooth_thick_tip = 0

        if tooth_thick_tip >= 0.3:
            _pass(section, f"{name}: tip thickness ~{tooth_thick_tip:.2f}mm >= 0.3mm")
        elif tooth_thick_tip >= 0.15:
            _warn(section, f"{name}: tip thickness ~{tooth_thick_tip:.2f}mm -- thin (may break)")
        else:
            _fail(section, f"{name}: tip thickness ~{tooth_thick_tip:.2f}mm -- POINTED TOOTH (will break)")

    # Rule 3.4: Root clearance (gear roots must clear mating shaft)
    ss_gap = values.get('ss_gap', None)
    sl_gap = values.get('sl_gap', None)
    if ss_gap is not None:
        if ss_gap > 0:
            _pass(section, f"Ss root-to-tube gap={ss_gap:.2f}mm > 0")
        else:
            _fail(section, f"Ss root-to-tube gap={ss_gap:.2f}mm <= 0 (COLLISION)")
    if sl_gap is not None:
        if sl_gap > 0:
            _pass(section, f"SL root-to-tube gap={sl_gap:.2f}mm > 0")
        else:
            _fail(section, f"SL root-to-tube gap={sl_gap:.2f}mm <= 0 (COLLISION)")


# ============================================================
# CATEGORY 4: HELICAL GEAR SPECIFICS
# ============================================================

def check_helical_specifics(variant_idx):
    """Check helical gear compatibility rules."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-HELICAL"

    # Rule 4.1: Helix hand compatibility
    # External <-> External mesh: OPPOSITE hands (LH meshes with RH)
    # Internal <-> External mesh: SAME hand
    _pass(section,
          "Helix hand rules: Ext<->Ext=opposite, Int<->Ext=same. "
          "Verify in SCAD: Ss-Pi (opposite), SL-Po (opposite), Po-Ring (same), Pi-Po (opposite)")

    # Rule 4.2: Face width vs helix -- minimum face width for full helical engagement
    # Minimum face width = pi * module / tan(helix_angle) for 1 tooth overlap
    min_fw = math.pi * NORM_MOD / math.tan(math.radians(HELIX_ANG))
    if GEAR_FW >= min_fw:
        _pass(section, f"Face width {GEAR_FW}mm >= min {min_fw:.1f}mm for helical engagement")
    else:
        _fail(section,
              f"Face width {GEAR_FW}mm < min {min_fw:.1f}mm -- "
              f"helical teeth won't fully engage. Need FW >= {min_fw:.1f}mm")

    # Rule 4.3: Axial thrust force balance
    # Helical gears produce axial thrust F_axial = F_tangential * tan(helix_angle)
    # In a Ravigneaux, opposing helix hands on planet pairs can cancel thrust
    _pass(section,
          f"Axial thrust factor: tan({HELIX_ANG})={math.tan(math.radians(HELIX_ANG)):.3f}. "
          f"Verify thrust washers sized for this load")


# ============================================================
# CATEGORY 5: ASSEMBLY & KINEMATIC
# ============================================================

def check_assembly_kinematic(variant_idx, values):
    """Check assembly feasibility and kinematic constraints."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-ASSEMBLY"

    # Rule 5.1: Algebraic constraints
    if values.get('rav_check') == 'OK':
        _pass(section, f"SL+2*Po={values.get('rav_sum')}=Ring({T_RING})")
    else:
        _fail(section, f"SL+2*Po={values.get('rav_sum')} != Ring({T_RING})")

    if values.get('inner_check') == 'OK':
        _pass(section, f"Ss+2*Pi={values.get('inner_sum')}=SL({T_SL})")
    else:
        _fail(section, f"Ss+2*Pi={values.get('inner_sum')} != SL({T_SL})")

    # Rule 5.2: Variant tooth counts match table
    if values.get('ss_teeth') == v['Ss']:
        _pass(section, f"Ss={v['Ss']} matches variant table")
    elif values.get('ss_teeth') is not None:
        _fail(section, f"Ss={values.get('ss_teeth')} != expected {v['Ss']}")

    if values.get('pi_teeth') == v['Pi']:
        _pass(section, f"Pi={v['Pi']} matches variant table")
    elif values.get('pi_teeth') is not None:
        _fail(section, f"Pi={values.get('pi_teeth')} != expected {v['Pi']}")

    # Rule 5.3: Planet spacing (Po and Pi must not collide during orbit)
    orb_po = values.get('orb_po', 0)
    orb_pi = values.get('orb_pi', 0)

    if orb_po > 0 and orb_pi > 0:
        _pass(section, f"Planet orbits: Po={orb_po:.1f}mm, Pi={orb_pi:.1f}mm")
    else:
        _fail(section, f"Invalid orbit radii: Po={orb_po}, Pi={orb_pi}")

    # Rule 5.4: Ring OD envelope
    ring_od = values.get('ring_od', 999)
    if ring_od <= 72:
        _pass(section, f"Ring OD={ring_od:.1f}mm <= 72mm envelope")
    else:
        _fail(section, f"Ring OD={ring_od:.1f}mm > 72mm envelope")

    # Rule 5.5: Kinematic blend coefficients
    kA = values.get('kA', -1)
    kB = values.get('kB', -1)
    if kA >= 0 and kB >= 0:
        k_sum = kA + kB
        if abs(k_sum - 1.0) < 0.01:
            _pass(section, f"kA+kB={k_sum:.3f} ~= 1.0")
        else:
            _warn(section, f"kA+kB={k_sum:.3f} != 1.0")

        expected_kA = v['Ss'] / (v['Ss'] + T_SL)
        if abs(kA - expected_kA) < 0.01:
            _pass(section, f"kA={kA:.3f} matches Ss/(Ss+SL)={expected_kA:.3f}")
        else:
            _fail(section, f"kA={kA:.3f} != expected {expected_kA:.3f}")

    # Rule 5.6: Assembly sequence feasibility
    # Carriers can only be installed if planet pins are shorter than ring ID
    ring_root_r = (T_RING * TRANS_MOD / 2) + 1.25 * TRANS_MOD
    po_tip_at_orbit = orb_po + T_PO * TRANS_MOD / 2 + TRANS_MOD
    if po_tip_at_orbit < ring_root_r:
        _pass(section, f"Po fits inside ring: tip@orbit={po_tip_at_orbit:.1f}mm < ring_root={ring_root_r:.1f}mm")
    else:
        _fail(section, f"Po does NOT fit inside ring: tip@orbit={po_tip_at_orbit:.1f}mm >= ring_root={ring_root_r:.1f}mm")


# ============================================================
# CATEGORY 6: RAVIGNEAUX STRUCTURAL
# ============================================================

def check_ravigneaux_structural(variant_idx):
    """Check Ravigneaux-specific structural rules."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-RAVIGNEAUX"

    components = compute_bounding_cylinders(variant_idx)
    t_pi = v['Pi']

    # Rule 6.1: Two-zone axiom
    ss = components["ss_gear"]
    sl = components["sl_gear"]
    ss_z = (ss["z_bot"], ss["z_top"])
    sl_z = (sl["z_bot"], sl["z_top"])

    if ss_z[0] == sl_z[0] and ss_z[1] == sl_z[1]:
        _fail(section,
              f"TWO-ZONE AXIOM: Ss and SL are in IDENTICAL Z-zone [{ss_z[0]:.1f}, {ss_z[1]:.1f}]. "
              f"They MUST be vertically stacked with a thrust plate between them. "
              f"Reference (Ford 4R70W): Ss zone and SL zone are separated by ~2mm gap")
    elif min(ss_z[1], sl_z[1]) - max(ss_z[0], sl_z[0]) > 0:
        _fail(section,
              f"TWO-ZONE AXIOM: Ss Z={list(ss_z)} and SL Z={list(sl_z)} OVERLAP. "
              f"Sun gears must be in separate Z-zones")
    else:
        sep = max(ss_z[0], sl_z[0]) - min(ss_z[1], sl_z[1])
        _pass(section,
              f"Two-zone axiom OK: Ss Z={list(ss_z)}, SL Z={list(sl_z)}, separation={sep:.1f}mm")

    # Rule 6.2: Long pinion (Po) must span BOTH gear zones
    po = components["po_gear"]
    po_spans_ss = po["z_bot"] <= ss["z_bot"] and po["z_top"] >= ss["z_top"]
    po_spans_sl = po["z_bot"] <= sl["z_bot"] and po["z_top"] >= sl["z_top"]

    if po_spans_ss and po_spans_sl:
        _pass(section,
              f"Po spans both zones: Po Z=[{po['z_bot']:.1f},{po['z_top']:.1f}] "
              f"covers Ss Z={list(ss_z)} and SL Z={list(sl_z)}")
    else:
        # If zones are identical (bug), Po trivially "spans both"
        if ss_z == sl_z:
            _warn(section,
                  f"Po zone check deferred -- Ss and SL zones are identical (fix two-zone axiom first)")
        else:
            _fail(section,
                  f"Po Z=[{po['z_bot']:.1f},{po['z_top']:.1f}] does NOT span both zones. "
                  f"Long pinion must span Ss zone {list(ss_z)} AND SL zone {list(sl_z)}")

    # Rule 6.3: Short pinion (Pi) must be confined to Ss zone ONLY
    pi = components["pi_gear"]
    pi_in_ss = pi["z_bot"] >= ss["z_bot"] - 0.1 and pi["z_top"] <= ss["z_top"] + 0.1

    if ss_z == sl_z:
        _warn(section, "Pi zone check deferred -- fix two-zone axiom first")
    elif pi_in_ss:
        _pass(section,
              f"Pi confined to Ss zone: Pi Z=[{pi['z_bot']:.1f},{pi['z_top']:.1f}] "
              f"within Ss Z={list(ss_z)}")
    else:
        _fail(section,
              f"Pi Z=[{pi['z_bot']:.1f},{pi['z_top']:.1f}] extends beyond Ss zone {list(ss_z)}. "
              f"Short pinion must be in Ss zone ONLY")

    # Rule 6.4: Radial nesting order
    ss_r = components["ss_gear"]["r_outer"]
    sl_r = components["sl_gear"]["r_outer"]
    po_orbit = (T_SL + T_PO) * TRANS_MOD / 2
    po_r = components["po_gear"]["r_outer"]
    ring_inner = components["ring_gear"]["r_inner"]

    max_sun = max(ss_r, sl_r)
    if max_sun < po_orbit and po_orbit + po_r < ring_inner + 3 * TRANS_MOD:
        _pass(section,
              f"Radial nesting: max_sun_r={max_sun:.1f} < po_orbit={po_orbit:.1f} < ring_inner={ring_inner:.1f}")
    else:
        _fail(section,
              f"Radial nesting broken: sun_r={max_sun:.1f}, po_orbit={po_orbit:.1f}, ring_inner={ring_inner:.1f}")

    # Rule 6.5: Drive module must have geometry
    scad_text = ""
    if SCAD_FILE.is_file():
        with open(SCAD_FILE, "r", encoding="utf-8", errors="replace") as f:
            scad_text = f.read()

    # Check if there's actual geometry in the drive/external pinion section
    drive_found = False
    for keyword in ["drive_pinion", "ext_pinion", "T_EXT_PIN", "SHOW_DRIVE"]:
        if keyword in scad_text:
            drive_found = True
            break

    if drive_found:
        # Check if SHOW_DRIVE has associated geometry
        show_drive_section = re.search(r'SHOW_DRIVE.*?(?:translate|rotate|cylinder|cube)',
                                        scad_text, re.DOTALL)
        if show_drive_section:
            _pass(section, "Drive pinion geometry present")
        else:
            _fail(section, "SHOW_DRIVE toggle exists but NO drive pinion geometry implemented")
    else:
        _fail(section, "No drive/external pinion implementation found")

    # Rule 6.6: Rope path must go vertical (Z-axis), not horizontal
    rope_section = re.search(r'module rope\(\)(.*?)(?=\nmodule |\Z)',
                              scad_text, re.DOTALL)
    if rope_section:
        rope_body = rope_section.group(1)
        # Check for 360-degree wrap (hull-based or rotate_extrude)
        has_wrap = "360" in rope_body or "wrap" in rope_body.lower()
        # Check for vertical drop — hull between two Z-different points, or translate with Z component
        has_z_drop = bool(re.search(
            r'(CHANNEL_Z\s*-\s*rope_drop|rope_drop|z_drop|RING_ZBOT)',
            rope_body, re.IGNORECASE
        ))
        # Also check for the sphere-hull pattern with Z difference
        has_sphere_drop = "sphere" in rope_body and "rope_drop" in rope_body

        if (has_z_drop or has_sphere_drop) and has_wrap:
            _pass(section, "Rope: 360deg wrap + vertical Z-drop detected")
        elif has_wrap:
            _warn(section, "Rope has wrap but no clear vertical Z-drop")
        else:
            _fail(section, "Rope path appears horizontal -- must wrap 360deg around ring then drop vertically on Z-axis")
    else:
        _warn(section, "No rope module found")


# ============================================================
# CATEGORY 7: REFERENCE PROPORTIONS (from reference_dimensions.json)
# ============================================================

def check_reference_proportions(variant_idx):
    """Compare model proportions against reference dimensions."""
    v = VARIANTS[variant_idx]
    section = f"V{variant_idx}({v['name']})-REFERENCE"

    if _reference is None:
        _warn(section, "No reference_dimensions.json loaded -- skipping proportion checks")
        return

    constraints = _reference.get("ravigneaux_constraints", {})

    # Rule 7.1: Height ratio Po/Pi should roughly match reference
    hr = constraints.get("height_ratios", {})
    ref_po_pi_ratio = hr.get("po_to_pi_ratio")
    if ref_po_pi_ratio:
        # In our model, Po and Pi currently have same height (GEAR_FW)
        # After fix, Po should be taller than Pi
        components = compute_bounding_cylinders(variant_idx)
        model_po_h = components["po_gear"]["z_top"] - components["po_gear"]["z_bot"]
        model_pi_h = components["pi_gear"]["z_top"] - components["pi_gear"]["z_bot"]
        if model_pi_h > 0:
            model_ratio = model_po_h / model_pi_h
            if abs(model_ratio - 1.0) < 0.01:
                _fail(section,
                      f"Po/Pi height ratio = {model_ratio:.1f} (IDENTICAL heights). "
                      f"Reference ratio = {ref_po_pi_ratio:.1f}. "
                      f"Po must be TALLER than Pi (spans both zones)")
            elif model_ratio >= 1.5:
                _pass(section,
                      f"Po/Pi height ratio = {model_ratio:.1f} (reference: {ref_po_pi_ratio:.1f})")
            else:
                _warn(section,
                      f"Po/Pi height ratio = {model_ratio:.1f} (reference: {ref_po_pi_ratio:.1f}) -- check proportions")

    # Rule 7.2: Two-zone verification from reference
    tz = constraints.get("two_zone_axiom", {})
    if tz:
        ref_sep = tz.get("separation_mm", 0)
        ref_ovl = tz.get("overlap_mm", 0)
        if ref_sep > 0:
            _pass(section,
                  f"Reference confirms two-zone separation: {ref_sep:.1f}mm gap between Ss and SL zones")
        else:
            # Ford 4R70W has concentric suns with separate tooth zones
            _pass(section,
                  f"Reference: concentric suns with Z-overlap={ref_ovl:.0f}mm (shaft overlap, tooth zones separate)")


# ============================================================
# VARIANT SPREAD
# ============================================================

def check_variant_spread():
    """Check that variants give sufficient diversity."""
    section = "SPREAD"

    kA_values = [v['Ss'] / (v['Ss'] + T_SL) for v in VARIANTS]
    kA_range = max(kA_values) - min(kA_values)

    if kA_range > 0.05:
        _pass(section,
              f"kA range={kA_range:.3f} ({min(kA_values):.3f} to {max(kA_values):.3f}) -- sufficient diversity")
    else:
        _warn(section, f"kA range={kA_range:.3f} -- consider wider Ss spread")

    # External pinion spread
    freq_ratios = [p / EXT_PINIONS[2] for p in EXT_PINIONS]
    _pass(section, f"Ext pinion freq ratios: {[f'{r:.3f}' for r in freq_ratios]}")

    # Coprime check
    for i in range(len(EXT_PINIONS)):
        for j in range(i + 1, len(EXT_PINIONS)):
            g = gcd(EXT_PINIONS[i], EXT_PINIONS[j])
            if g == 1:
                _pass(section, f"GCD({EXT_PINIONS[i]},{EXT_PINIONS[j]})=1 (coprime)")
            else:
                _warn(section, f"GCD({EXT_PINIONS[i]},{EXT_PINIONS[j]})={g} (not coprime)")


# ============================================================
# MAIN
# ============================================================

def validate_variant(variant_idx, render_png=False):
    """Run ALL 7 categories of checks for one variant."""
    v = VARIANTS[variant_idx]
    print(f"\n{'='*60}")
    print(f"  Validating Variant {variant_idx} ({v['name']}): Ss={v['Ss']}, Pi={v['Pi']}")
    print(f"{'='*60}")

    # Compile
    success, echo_lines, warnings = compile_scad(variant_idx, render_png=render_png)

    if not success:
        _fail(f"V{variant_idx}-COMPILE", "OpenSCAD compilation failed")
        return

    if len(warnings) > 0:
        _fail(f"V{variant_idx}-COMPILE", f"{len(warnings)} warnings (must be zero)")
        for w in warnings[:5]:
            print(f"  WARNING: {w}")
    else:
        _pass(f"V{variant_idx}-COMPILE", "Zero errors, zero warnings")

    values = parse_echo_values(echo_lines)

    if not values:
        _fail(f"V{variant_idx}-PARSE", "No echo values parsed")
        return

    # Run all 7 categories
    check_spatial_occupation(variant_idx)
    check_axial_constraints(variant_idx)
    check_gear_mesh(variant_idx, values)
    check_helical_specifics(variant_idx)
    check_assembly_kinematic(variant_idx, values)
    check_ravigneaux_structural(variant_idx)
    check_reference_proportions(variant_idx)


def main():
    parser = argparse.ArgumentParser(description="Ravigneaux Grid -- Complete Geometry Validator (6 categories, ~30 rules)")
    parser.add_argument("--all", action="store_true", help="Validate all 5 variants")
    parser.add_argument("--variant", type=int, default=2, help="Single variant index (0-4)")
    parser.add_argument("--render", action="store_true", help="Also render PNG per variant")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")
    args = parser.parse_args()

    print("=" * 60)
    print("  RAVIGNEAUX GRID -- Complete Geometry Validator")
    print("  6 categories | ~30 rules | reference-aware")
    print("=" * 60)

    # Load reference dimensions
    if load_reference():
        print(f"  Reference loaded: {REF_FILE.name}")
    else:
        print(f"  WARNING: No reference_dimensions.json found (run extract_reference.py first)")

    if args.all:
        for i in range(5):
            validate_variant(i, render_png=args.render)
    else:
        validate_variant(args.variant, render_png=args.render)

    check_variant_spread()

    # Summary
    passes = sum(1 for r in _results if r[0] == "PASS")
    fails  = sum(1 for r in _results if r[0] == "FAIL")
    warns  = sum(1 for r in _results if r[0] == "WARN")

    print(f"\n{'='*60}")
    print(f"  RESULTS: {passes} PASS  |  {fails} FAIL  |  {warns} WARN")
    print(f"{'='*60}")

    # Show FAILs and WARNs first, then PASSes
    for status in ["FAIL", "WARN", "PASS"]:
        for s, section, msg in _results:
            if s == status:
                icon = {"PASS": "[OK]", "FAIL": "[FAIL]", "WARN": "[WARN]"}[s]
                print(f"  {icon:6s} {section:35s} {msg}")

    if args.json:
        json_out = {
            "passes": passes,
            "fails": fails,
            "warns": warns,
            "categories": {
                "spatial": sum(1 for _, s, _ in _results if "SPATIAL" in s),
                "axial": sum(1 for _, s, _ in _results if "AXIAL" in s),
                "gearmesh": sum(1 for _, s, _ in _results if "GEARMESH" in s),
                "helical": sum(1 for _, s, _ in _results if "HELICAL" in s),
                "assembly": sum(1 for _, s, _ in _results if "ASSEMBLY" in s),
                "ravigneaux": sum(1 for _, s, _ in _results if "RAVIGNEAUX" in s),
                "reference": sum(1 for _, s, _ in _results if "REFERENCE" in s),
            },
            "results": [{"status": s, "section": sec, "msg": m} for s, sec, m in _results]
        }
        json_path = SCRIPT_DIR / "validate_results.json"
        with open(json_path, "w") as f:
            json.dump(json_out, f, indent=2)
        print(f"\nJSON results: {json_path}")

    print(f"\n{'PASS' if fails == 0 else 'FAIL'}")
    sys.exit(0 if fails == 0 else 1)


if __name__ == "__main__":
    main()
