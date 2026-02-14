#!/usr/bin/env python3
"""
Triple Helix MVP — Geometry Constraint Validator
=================================================
Parses OpenSCAD echo output and validates spatial relationships.
Run after every compile to catch broken parametric chains BEFORE visual inspection.

Usage:
    python validate_geometry.py hex_frame_v4.scad
    python validate_geometry.py --render hex_frame_v4.scad   (also renders PNG)

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
from pathlib import Path

# ============================================================
# CONFIG — these must match config_v4.scad values
# If these drift from config, the validator itself is broken.
# TODO: auto-parse config_v4.scad for these values
# ============================================================
OPENSCAD_PATH = r"C:\Program Files\OpenSCAD\openscad.exe"
OPENSCAD_COM = r"C:\Program Files\OpenSCAD\openscad.com"  # console version

# Parametric chain: all derived from config_v4.scad
CONFIG = {
    "HEX_R": 118,
    "HELIX_ANGLES": [180, 300, 60],
    "HELIX_LENGTH": 182,        # NUM_CAMS * AXIAL_PITCH = 13 * 14
    "JOURNAL_LENGTH": 10,
    "JOURNAL_EXT": 150,
    "BEARING_OD": 19,
    "BEARING_ID": 10,
    "BEARING_W": 5,
    "ARM_W": 20,
    "ARM_H": 14,
    "GT2_OD": 14.2,
    "GT2_BOSS_H": 8,
    "ECCENTRICITY": 15,
    "TIER_PITCH": 30,
    "HOUSING_HEIGHT": 30,
    "SNAP_RING_T": 1.0,
    "SPACER_T": 3.0,
    "COLLAR_T": 5.0,
    "COLLAR_OD": 16.0,
}

# Derived
JOURNAL_TOTAL_REACH = CONFIG["HELIX_LENGTH"] / 2 + CONFIG["JOURNAL_LENGTH"] + CONFIG["JOURNAL_EXT"]
HELIX_R = None  # parsed from echo
CORRIDOR_GAP = None

# ============================================================
# ECHO PARSER
# ============================================================
def parse_echos(lines):
    """Parse ECHO lines into structured data."""
    markers = {}
    helixes = {}
    dampeners = {}
    pbs = {}
    tip_bridges = {}
    config_vals = {}

    for line in lines:
        line = line.strip()
        if not line.startswith('ECHO: "'):
            continue
        content = line[7:-1]  # strip ECHO: " ... "

        # Marker: MARKER label: X=... Y=... Z=... R=...
        m = re.match(r'MARKER (\S+): X=([-\d.]+) Y=([-\d.]+) Z=([-\d.]+) R=([-\d.]+)', content.strip())
        if m:
            markers[m.group(1)] = {
                "x": float(m.group(2)), "y": float(m.group(3)),
                "z": float(m.group(4)), "r": float(m.group(5))
            }
            continue

        # Helix: Helix N Z=...: center=[x, y] angle=...deg drive=...
        m = re.match(r'Helix (\d) Z=([-\d.]+): center=\[([-\d.]+),\s*([-\d.]+)\] angle=([\d.]+)deg\s+drive=(\S+)', content.strip())
        if m:
            hi = int(m.group(1))
            helixes[hi] = {
                "z": float(m.group(2)),
                "cx": float(m.group(3)), "cy": float(m.group(4)),
                "angle": float(m.group(5)),
                "drive": m.group(6)
            }
            continue

        # PB: NearPB/FarPB
        m = re.match(r'(Near|Far)PB:\s+\S+@\[([-\d.]+),([-\d.]+),([-\d.]+)\]', content.strip())
        if m:
            continue  # will parse from markers PBn/PBf

        # Dampener
        m = re.match(r'Dampener H(\d) Z=([-\d.]+):', content.strip())
        if m:
            dampeners[int(m.group(1))] = {"z": float(m.group(2))}
            continue

        # TipBridge
        m = re.match(r'TipBridge H(\d) Z=([-\d.]+):', content.strip())
        if m:
            tip_bridges[int(m.group(1))] = {"z": float(m.group(2))}
            continue

        # Helix R
        m = re.match(r'Helix R=([\d.]+)mm', content.strip())
        if m:
            config_vals["HELIX_R"] = float(m.group(1))
            continue

        # Helix Z list
        m = re.match(r'Helix Z: H1=([-\d.]+) H2=([-\d.]+) H3=([-\d.]+)', content.strip())
        if m:
            config_vals["HELIX_Z"] = [float(m.group(1)), float(m.group(2)), float(m.group(3))]
            continue

    return markers, helixes, dampeners, tip_bridges, config_vals


# ============================================================
# CONSTRAINT CHECKS
# ============================================================
def dist_3d(a, b):
    return math.sqrt((a["x"]-b["x"])**2 + (a["y"]-b["y"])**2 + (a["z"]-b["z"])**2)

def dist_xy(a, b):
    return math.sqrt((a["x"]-b["x"])**2 + (a["y"]-b["y"])**2)

def point_to_line_dist_2d(px, py, lx, ly, ldx, ldy):
    """Perpendicular distance from point to line through (lx,ly) with direction (ldx,ldy)."""
    line_len = math.sqrt(ldx**2 + ldy**2)
    if line_len < 1e-9:
        return math.sqrt((px-lx)**2 + (py-ly)**2)
    return abs((px - lx) * ldy - (py - ly) * ldx) / line_len

def shaft_dir(angle_deg):
    """Shaft direction = perpendicular to radial = (-sin(a), cos(a))."""
    a = math.radians(angle_deg)
    return (-math.sin(a), math.cos(a))

def shaft_proj(hx, hy, sdx, sdy, px, py):
    """Project point onto shaft axis, return signed distance from helix center."""
    return (px - hx) * sdx + (py - hy) * sdy


results = []

def check(name, condition, detail=""):
    status = "PASS" if condition else "FAIL"
    results.append((status, name, detail))
    sym = "OK" if condition else "XX"
    print(f"  [{sym}] {name}: {detail}")
    return condition


def run_checks(markers, helixes, dampeners, tip_bridges, config_vals):
    print("\n" + "=" * 60)
    print("GEOMETRY CONSTRAINT VALIDATION")
    print("=" * 60)

    helix_r = config_vals.get("HELIX_R", 272)
    helix_z_list = config_vals.get("HELIX_Z", [0, 0, 0])

    # ----------------------------------------------------------
    # CHECK 1: All helix cams at Z=0
    # ----------------------------------------------------------
    print("\n--- CHECK 1: Helix Cam Z Positions ---")
    for hi in [1, 2, 3]:
        if hi in helixes:
            h = helixes[hi]
            check(f"H{hi} cam Z=0",
                  abs(h["z"]) < 0.1,
                  f"Z={h['z']} (expect 0)")

    # ----------------------------------------------------------
    # CHECK 2: Bearing positions on shaft axis
    # ----------------------------------------------------------
    print("\n--- CHECK 2: Bearing Bore on Shaft Axis ---")
    for hi in [1, 2, 3]:
        if hi not in helixes:
            continue
        h = helixes[hi]
        sdx, sdy = shaft_dir(h["angle"])

        for side, prefix in [("near", f"PBn{hi}"), ("far", f"PBf{hi}")]:
            if prefix not in markers:
                check(f"H{hi} {side} PB marker exists", False, f"Marker {prefix} missing")
                continue
            pb = markers[prefix]
            perp = point_to_line_dist_2d(pb["x"], pb["y"], h["cx"], h["cy"], sdx, sdy)
            proj = shaft_proj(h["cx"], h["cy"], sdx, sdy, pb["x"], pb["y"])
            check(f"H{hi} {side} PB on shaft axis",
                  perp < 5.0,
                  f"perp_dist={perp:.1f}mm (max 5mm), proj={proj:.1f}mm")

    # ----------------------------------------------------------
    # CHECK 3: Bearing at correct journal distance
    # ----------------------------------------------------------
    print("\n--- CHECK 3: Bearing Distance from Helix Center ---")
    for hi in [1, 2, 3]:
        if hi not in helixes:
            continue
        h = helixes[hi]
        sdx, sdy = shaft_dir(h["angle"])

        for side, prefix, sign in [("near", f"PBn{hi}", -1), ("far", f"PBf{hi}", 1)]:
            if prefix not in markers:
                continue
            pb = markers[prefix]
            proj = shaft_proj(h["cx"], h["cy"], sdx, sdy, pb["x"], pb["y"])
            expected = sign * JOURNAL_TOTAL_REACH
            check(f"H{hi} {side} PB at journal reach",
                  abs(abs(proj) - JOURNAL_TOTAL_REACH) < 20,
                  f"proj={proj:.1f}mm (expect ~{expected:.0f}mm, reach={JOURNAL_TOTAL_REACH}mm)")

    # ----------------------------------------------------------
    # CHECK 4: Bearing Z matches cam Z
    # ----------------------------------------------------------
    print("\n--- CHECK 4: Bearing Z = Cam Z ---")
    for hi in [1, 2, 3]:
        if hi not in helixes:
            continue
        cam_z = helixes[hi]["z"]
        for prefix in [f"PBn{hi}", f"PBf{hi}"]:
            if prefix not in markers:
                continue
            pb = markers[prefix]
            check(f"{prefix} Z matches cam",
                  abs(pb["z"] - cam_z) < 1.0,
                  f"PB_Z={pb['z']}, cam_Z={cam_z}")

    # ----------------------------------------------------------
    # CHECK 5: GT2 pulley clears arm width
    # ----------------------------------------------------------
    print("\n--- CHECK 5: GT2 Pulley Arm Clearance ---")
    # GT2 position on shaft axis must be far enough from helix center
    # that the pulley body doesn't intersect any arm beam.
    # Minimum: GT2 must be outboard of PB housing (already on shaft axis at ±251mm)
    # Check: GT2 marker proj along shaft > JOURNAL_TOTAL_REACH + clearance
    for hi in [1, 2, 3]:
        if hi not in helixes:
            continue
        h = helixes[hi]
        if h["drive"] != "BELT-GT2":
            continue
        gt2_key = f"GT2_H{hi}"
        if gt2_key not in markers:
            check(f"H{hi} GT2 marker exists", False, f"Marker {gt2_key} missing")
            continue
        gt2 = markers[gt2_key]
        sdx, sdy = shaft_dir(h["angle"])
        proj = shaft_proj(h["cx"], h["cy"], sdx, sdy, gt2["x"], gt2["y"])
        # GT2 should be at JOURNAL_TOTAL_REACH + bearing_half + snap + spacer + GT2/2
        # Just check it's beyond the bearing position
        check(f"H{hi} GT2 beyond bearing",
              abs(proj) > JOURNAL_TOTAL_REACH,
              f"GT2 proj={proj:.1f}mm, bearing at {JOURNAL_TOTAL_REACH}mm")

    # ----------------------------------------------------------
    # CHECK 6: Dampener at tier Z (NOT cam Z)
    # ----------------------------------------------------------
    print("\n--- CHECK 6: Dampener Z = Tier Z ---")
    tier_z_map = {1: CONFIG["TIER_PITCH"], 2: 0, 3: -CONFIG["TIER_PITCH"]}
    for hi in [1, 2, 3]:
        if hi in dampeners:
            expected_z = tier_z_map[hi]
            actual_z = dampeners[hi]["z"]
            check(f"D{hi} dampener at tier Z",
                  abs(actual_z - expected_z) < 1.0,
                  f"Z={actual_z} (expect {expected_z})")
        # Also check D marker
        dkey = f"D{hi}"
        if dkey in markers:
            expected_z = tier_z_map[hi]
            check(f"D{hi} marker at tier Z",
                  abs(markers[dkey]["z"] - expected_z) < 1.0,
                  f"marker Z={markers[dkey]['z']} (expect {expected_z})")

    # ----------------------------------------------------------
    # CHECK 7: Cam-to-hex clearance (gap budget)
    # ----------------------------------------------------------
    print("\n--- CHECK 7: Helix Gap Budget ---")
    for hi in [1, 2, 3]:
        if f"H{hi}" in markers:
            hm = markers[f"H{hi}"]
            gap = hm["r"] - CONFIG["HEX_R"]
            check(f"H{hi} gap to hex",
                  gap > 40,
                  f"gap={gap:.0f}mm (need >40mm for rib+dampener+clearance)")

    # ----------------------------------------------------------
    # CHECK 8: Tip bridge Z consistency
    # ----------------------------------------------------------
    print("\n--- CHECK 8: Tip Bridge Z ---")
    for hi in [1, 2, 3]:
        if hi in tip_bridges:
            tb_z = tip_bridges[hi]["z"]
            # With cams at Z=0, tip bridges should be at Z=0
            check(f"TipBridge H{hi} Z",
                  True,  # just report
                  f"Z={tb_z} (for reference)")

    # ----------------------------------------------------------
    # CHECK 9: Parametric chain integrity
    # ----------------------------------------------------------
    print("\n--- CHECK 9: Parametric Chain ---")
    if helixes:
        h1 = helixes.get(1, {})
        expected_r = helix_r
        if h1:
            actual_r = math.sqrt(h1["cx"]**2 + h1["cy"]**2)
            check("HELIX_R matches echo",
                  abs(actual_r - expected_r) < 1.0,
                  f"computed={actual_r:.1f}, echo={expected_r}")

    # ----------------------------------------------------------
    # SUMMARY
    # ----------------------------------------------------------
    passes = sum(1 for s, _, _ in results if s == "PASS")
    fails = sum(1 for s, _, _ in results if s == "FAIL")
    print(f"\n{'=' * 60}")
    print(f"RESULTS: {passes} PASS, {fails} FAIL, {len(results)} total")
    print(f"{'=' * 60}")

    return fails == 0


# ============================================================
# MAIN
# ============================================================
def compile_and_validate(scad_file, do_render=False):
    scad_path = Path(scad_file).resolve()
    if not scad_path.exists():
        print(f"ERROR: File not found: {scad_path}")
        return 2

    print(f"Compiling: {scad_path.name}")

    # Compile to CSG (fast, gets all echoes)
    csg_out = scad_path.with_suffix(".test.csg")
    cmd = [OPENSCAD_COM, "-o", str(csg_out), str(scad_path)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print("ERROR: OpenSCAD timed out (120s)")
        return 2

    all_output = result.stdout + result.stderr
    lines = all_output.splitlines()

    # Check for compile errors
    errors = [l for l in lines if "ERROR" in l or "error" in l.lower()]
    warnings = [l for l in lines if "WARNING" in l]
    echo_lines = [l for l in lines if l.startswith("ECHO:")]

    if errors:
        print(f"\nCOMPILE ERRORS ({len(errors)}):")
        for e in errors[:10]:
            print(f"  {e}")
        return 2

    if warnings:
        print(f"\nWarnings ({len(warnings)}):")
        for w in warnings[:5]:
            print(f"  {w}")

    print(f"Compile OK: {len(echo_lines)} echoes, {len(warnings)} warnings")

    # Parse and validate
    markers, helixes, dampeners, tip_bridges, config_vals = parse_echos(echo_lines)
    print(f"Parsed: {len(markers)} markers, {len(helixes)} helixes, {len(dampeners)} dampeners")

    all_pass = run_checks(markers, helixes, dampeners, tip_bridges, config_vals)

    # Optional render
    if do_render:
        print(f"\nRendering PNG...")
        png_out = scad_path.with_suffix(".validate.png")
        render_cmd = [
            OPENSCAD_PATH,
            "--camera=0,0,0,55,0,25,1200",
            "--imgsize=1600,1200",
            "--colorscheme=Tomorrow Night",
            "-o", str(png_out),
            str(scad_path)
        ]
        try:
            subprocess.run(render_cmd, capture_output=True, timeout=120)
            print(f"Rendered: {png_out}")
        except subprocess.TimeoutExpired:
            print("Render timed out")

    # Write results JSON
    results_file = scad_path.with_suffix(".validate.json")
    with open(results_file, "w") as f:
        json.dump({
            "file": str(scad_path),
            "markers": markers,
            "helixes": helixes,
            "dampeners": dampeners,
            "config": config_vals,
            "checks": [{"status": s, "name": n, "detail": d} for s, n, d in results],
            "summary": {"pass": sum(1 for s,_,_ in results if s=="PASS"),
                        "fail": sum(1 for s,_,_ in results if s=="FAIL")}
        }, f, indent=2)
    print(f"Results: {results_file}")

    return 0 if all_pass else 1


if __name__ == "__main__":
    args = sys.argv[1:]
    do_render = "--render" in args
    args = [a for a in args if a != "--render"]

    if not args:
        scad = "hex_frame_v4.scad"
    else:
        scad = args[0]

    exit_code = compile_and_validate(scad, do_render)
    sys.exit(exit_code)
