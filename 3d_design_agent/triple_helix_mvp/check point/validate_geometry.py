#!/usr/bin/env python3
"""
Triple Helix MVP — Geometry Constraint Validator
=================================================
Parses OpenSCAD echo output and validates spatial relationships.
Run after every compile to catch broken parametric chains BEFORE visual inspection.

Auto-detects config_v*.scad values from the file being validated.
No hardcoded config — works with V4, V5, V5.2, and future versions.

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
# OPENSCAD PATHS
# ============================================================
OPENSCAD_PATH = r"C:\Program Files\OpenSCAD\openscad.exe"
OPENSCAD_COM = r"C:\Program Files\OpenSCAD\openscad.com"  # console version

# ============================================================
# CONFIG DEFAULTS — V4 fallback (overridden by auto-detection)
# ============================================================
CONFIG_DEFAULTS = {
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


# ============================================================
# AUTO-DETECT CONFIG from .scad files
# ============================================================
def parse_scad_config(config_path):
    """Parse OpenSCAD variable assignments from a .scad file.

    Handles:
      VAR = 123;                        simple integer
      VAR = 123.45;                     float
      VAR = -5.0;                       negative
      VAR = 2 * OTHER;                  binary expression (if OTHER parsed)
      VAR = 2 * A + B + 3;             multi-term arithmetic
      VAR = OTHER + 10;                 addition
      VAR = OTHER / 2;                  division
      VAR = OTHER - 3;                  subtraction
      VAR = [180, 300, 60];             array of numbers
      VAR = OTHER;                      alias
      VAR = sqrt(3);                    OpenSCAD math builtins

    Uses two-pass resolution: first pass parses what it can,
    second pass resolves dependencies that were missing on first pass.

    Skips:
      // comments, /* block starts, function, module, if, echo, $fn, $t lines
    """
    if not config_path.exists():
        return None

    skip_prefixes = ("//", "/*", "function", "module", "if", "echo", "for", "let")
    skip_vars = {"$fn", "$t", "$fa", "$fs"}

    # Extract all variable assignment lines first
    assignments = []  # list of (var_name, rhs_string)
    with open(config_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()

            # Skip empty, comments, structural keywords
            if not line or line.startswith(skip_prefixes):
                continue

            # Strip inline comments: VAR = 123; // comment
            if "//" in line:
                line = line[:line.index("//")].strip()

            # Match: VAR_NAME = <something>;
            m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*(.+?)\s*;', line)
            if not m:
                continue

            var_name = m.group(1)
            rhs = m.group(2).strip()

            # Skip special OpenSCAD variables
            if var_name in skip_vars or var_name.startswith("$"):
                continue

            assignments.append((var_name, rhs))

    if not assignments:
        return None

    # Multi-pass resolution: keep trying until no new values resolve
    parsed = {}
    max_passes = 4
    for pass_num in range(max_passes):
        resolved_this_pass = 0
        for var_name, rhs in assignments:
            if var_name in parsed:
                continue  # already resolved
            val = _eval_expr(rhs, parsed)
            if val is not None:
                parsed[var_name] = val
                resolved_this_pass += 1
        if resolved_this_pass == 0:
            break  # no progress, stop

    return parsed if parsed else None


def _eval_expr(expr, known):
    """Evaluate an OpenSCAD expression string given known variable values.

    Handles arithmetic (+, -, *, /), parenthesized sub-expressions,
    OpenSCAD builtins (sqrt, PI), array literals, variable references,
    and boolean literals.
    """
    expr = expr.strip()

    # Array literal: [180, 300, 60]
    m = re.match(r'^\[(.+)\]$', expr)
    if m:
        try:
            items = [x.strip() for x in m.group(1).split(",")]
            nums = []
            for item in items:
                v = _eval_expr(item, known)
                if v is not None and isinstance(v, (int, float)):
                    nums.append(v)
                else:
                    return None
            return nums
        except Exception:
            return None

    # Boolean literals
    if expr == "true":
        return True
    if expr == "false":
        return False

    # Try evaluating as arithmetic expression
    val = _eval_arithmetic(expr, known)
    return val


def _eval_arithmetic(expr, known):
    """Evaluate an arithmetic expression with +, -, *, / and parentheses.

    Tokenizes the expression and evaluates using standard precedence:
      * and / bind tighter than + and -
    """
    tokens = _tokenize(expr, known)
    if tokens is None:
        return None
    try:
        result, pos = _parse_add_sub(tokens, 0)
        if pos == len(tokens):
            return result
        return None  # leftover tokens
    except Exception:
        return None


def _tokenize(expr, known):
    """Tokenize an OpenSCAD arithmetic expression into numbers, operators, and parens.

    Resolves:
      - Numeric literals (int, float, negative)
      - Variable references (looked up in known)
      - OpenSCAD builtins: sqrt(), PI
      - Operators: +, -, *, /
      - Parentheses: (, )
      - Ternary expressions are NOT supported (returns None)
    """
    tokens = []
    i = 0
    s = expr.strip()

    # Bail on ternary expressions and conditionals
    if "?" in s or ":" in s:
        return None

    while i < len(s):
        c = s[i]

        # Whitespace
        if c in " \t":
            i += 1
            continue

        # Operators and parens
        if c in "+-*/()":
            tokens.append(c)
            i += 1
            continue

        # Number (possibly negative, but only at start or after operator/open-paren)
        if c.isdigit() or c == ".":
            j = i
            while j < len(s) and (s[j].isdigit() or s[j] == "."):
                j += 1
            tok = s[i:j]
            n = _try_number(tok)
            if n is None:
                return None
            tokens.append(n)
            i = j
            continue

        # Identifier (variable or builtin function)
        if c.isalpha() or c == "_":
            j = i
            while j < len(s) and (s[j].isalnum() or s[j] == "_"):
                j += 1
            name = s[i:j]
            i = j

            # OpenSCAD built-in constants
            if name == "PI":
                tokens.append(math.pi)
                continue

            # OpenSCAD built-in functions: sqrt(expr), abs(expr)
            if name in ("sqrt", "abs") and i < len(s) and s[i] == "(":
                # Find matching close paren
                depth = 0
                start = i
                while i < len(s):
                    if s[i] == "(":
                        depth += 1
                    elif s[i] == ")":
                        depth -= 1
                        if depth == 0:
                            break
                    i += 1
                if depth != 0:
                    return None
                inner = s[start+1:i]
                i += 1  # skip closing paren
                inner_val = _eval_arithmetic(inner, known)
                if inner_val is None:
                    return None
                if name == "sqrt":
                    tokens.append(math.sqrt(inner_val))
                elif name == "abs":
                    tokens.append(abs(inner_val))
                continue

            # Variable reference
            if name in known:
                v = known[name]
                if isinstance(v, (int, float)):
                    tokens.append(v)
                    continue
                else:
                    return None  # non-numeric variable
            else:
                return None  # unknown variable

        # Unknown character
        return None

    return tokens if tokens else None


def _parse_add_sub(tokens, pos):
    """Parse addition and subtraction (lowest precedence)."""
    left, pos = _parse_mul_div(tokens, pos)
    while pos < len(tokens) and tokens[pos] in ("+", "-"):
        op = tokens[pos]
        pos += 1
        right, pos = _parse_mul_div(tokens, pos)
        if op == "+":
            left = left + right
        else:
            left = left - right
    return left, pos


def _parse_mul_div(tokens, pos):
    """Parse multiplication and division (higher precedence)."""
    left, pos = _parse_unary(tokens, pos)
    while pos < len(tokens) and tokens[pos] in ("*", "/"):
        op = tokens[pos]
        pos += 1
        right, pos = _parse_unary(tokens, pos)
        if op == "*":
            left = left * right
        elif right != 0:
            left = left / right
        else:
            raise ValueError("division by zero")
    return left, pos


def _parse_unary(tokens, pos):
    """Parse unary minus and atoms (numbers, parenthesized expressions)."""
    if pos < len(tokens) and tokens[pos] == "-":
        pos += 1
        val, pos = _parse_unary(tokens, pos)
        return -val, pos
    if pos < len(tokens) and tokens[pos] == "+":
        pos += 1
        return _parse_unary(tokens, pos)
    return _parse_atom(tokens, pos)


def _parse_atom(tokens, pos):
    """Parse an atom: number or parenthesized expression."""
    if pos >= len(tokens):
        raise ValueError("unexpected end of expression")
    tok = tokens[pos]
    if isinstance(tok, (int, float)):
        return tok, pos + 1
    if tok == "(":
        val, pos = _parse_add_sub(tokens, pos + 1)
        if pos >= len(tokens) or tokens[pos] != ")":
            raise ValueError("missing closing paren")
        return val, pos + 1
    raise ValueError(f"unexpected token: {tok}")


def _try_number(s):
    """Try parsing a string as int or float. Returns None on failure."""
    s = s.strip()
    try:
        if "." in s:
            return float(s)
        return int(s)
    except (ValueError, TypeError):
        return None


def auto_detect_config(scad_path):
    """Auto-detect and parse config values for a given .scad file.

    Strategy:
      1. If the file IS a config file (name starts with config_), parse it directly.
      2. Otherwise, scan for 'include <config_*.scad>' and parse that config file
         from the same directory.
      3. Map parsed OpenSCAD variable names to the CONFIG dict keys the validator uses.
      4. Return merged dict (parsed values override defaults) or None if nothing found.
    """
    scad_path = Path(scad_path).resolve()
    scad_dir = scad_path.parent

    config_file = None

    # Case 1: the file itself is a config
    if scad_path.name.startswith("config_"):
        config_file = scad_path
    else:
        # Case 2: look for include <config_*.scad>
        try:
            with open(scad_path, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    m = re.match(r'^\s*include\s*<(config_[^>]+\.scad)>', line)
                    if m:
                        config_file = scad_dir / m.group(1)
                        break
        except Exception:
            return None

    if config_file is None or not config_file.exists():
        return None

    raw = parse_scad_config(config_file)
    if not raw:
        return None

    # Build CONFIG dict from parsed values
    # Direct mappings (OpenSCAD name -> CONFIG key)
    direct_map = {
        "HEX_R": "HEX_R",
        "HELIX_ANGLES": "HELIX_ANGLES",
        "HELIX_LENGTH": "HELIX_LENGTH",
        "JOURNAL_LENGTH": "JOURNAL_LENGTH",
        "JOURNAL_EXT": "JOURNAL_EXT",
        "BEARING_OD": "BEARING_OD",
        "BEARING_ID": "BEARING_ID",
        "BEARING_W": "BEARING_W",
        "BEARING_WIDTH": "BEARING_W",
        "ARM_W": "ARM_W",
        "ARM_H": "ARM_H",
        "GT2_OD": "GT2_OD",
        "GT2_BOSS_H": "GT2_BOSS_H",
        "ECCENTRICITY": "ECCENTRICITY",
        "TIER_PITCH": "TIER_PITCH",
        "HOUSING_HEIGHT": "HOUSING_HEIGHT",
        "SNAP_RING_T": "SNAP_RING_T",
        "SPACER_T": "SPACER_T",
        "COLLAR_T": "COLLAR_T",
        "COLLAR_OD": "COLLAR_OD",
    }

    config = dict(CONFIG_DEFAULTS)  # start with defaults

    for scad_name, cfg_key in direct_map.items():
        if scad_name in raw:
            config[cfg_key] = raw[scad_name]

    # Derived fallbacks — compute if components are available but the
    # composite variable wasn't directly parsed (e.g., HELIX_LENGTH
    # depends on NUM_CAMS which is function-derived in OpenSCAD)
    if "HELIX_LENGTH" not in raw:
        axial = raw.get("AXIAL_PITCH")
        num_cams = raw.get("NUM_CAMS")
        if axial is not None and num_cams is not None:
            config["HELIX_LENGTH"] = num_cams * axial
        elif axial is not None and "NUM_CHANNELS" in raw:
            # NUM_CAMS often equals NUM_CHANNELS
            config["HELIX_LENGTH"] = raw["NUM_CHANNELS"] * axial

    # Report what was auto-detected
    config_name = config_file.name
    detected_keys = [cfg_key for scad_name, cfg_key in direct_map.items() if scad_name in raw]
    print(f"Config auto-detected: {config_name} ({len(detected_keys)} values)")
    if detected_keys:
        print(f"  Keys: {', '.join(sorted(detected_keys))}")

    return config


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


def run_checks(markers, helixes, dampeners, tip_bridges, config_vals, config):
    """Run all geometry constraint checks. Returns (all_pass, results_list)."""
    results = []

    def check(name, condition, detail=""):
        status = "PASS" if condition else "FAIL"
        results.append((status, name, detail))
        sym = "OK" if condition else "XX"
        print(f"  [{sym}] {name}: {detail}")
        return condition

    # Compute derived values from the active config
    journal_total_reach = config["HELIX_LENGTH"] / 2 + config["JOURNAL_LENGTH"] + config["JOURNAL_EXT"]

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
            expected = sign * journal_total_reach
            check(f"H{hi} {side} PB at journal reach",
                  abs(abs(proj) - journal_total_reach) < 20,
                  f"proj={proj:.1f}mm (expect ~{expected:.0f}mm, reach={journal_total_reach}mm)")

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
        check(f"H{hi} GT2 beyond bearing",
              abs(proj) > journal_total_reach,
              f"GT2 proj={proj:.1f}mm, bearing at {journal_total_reach}mm")

    # ----------------------------------------------------------
    # CHECK 6: Dampener at tier Z (NOT cam Z)
    # ----------------------------------------------------------
    print("\n--- CHECK 6: Dampener Z = Tier Z ---")
    tier_z_map = {1: config["TIER_PITCH"], 2: 0, 3: -config["TIER_PITCH"]}
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
            gap = hm["r"] - config["HEX_R"]
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

    return fails == 0, results


# ============================================================
# MAIN
# ============================================================
def compile_and_validate(scad_file, do_render=False):
    scad_path = Path(scad_file).resolve()
    if not scad_path.exists():
        print(f"ERROR: File not found: {scad_path}")
        return 2

    print(f"Compiling: {scad_path.name}")

    # Auto-detect config from the .scad file
    config = auto_detect_config(scad_path)
    if config is None:
        print(f"Config auto-detect: no config found, using V4 defaults")
        config = dict(CONFIG_DEFAULTS)

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

    all_pass, results = run_checks(markers, helixes, dampeners, tip_bridges, config_vals, config)

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
            "config_source": config.get("_source", "defaults"),
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
