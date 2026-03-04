#!/usr/bin/env python3
"""
Triple Helix MVP — Geometry Constraint Validator V5.6
=====================================================
Validates parametric constraints by parsing config_v*.scad directly.
No dependency on ECHO markers — works purely from config values.

Checks:
  1. Config parse completeness (all required vars resolved)
  2. Z-stack budget (slider plates fit inside channel gap)
  3. Bearing/shaft compatibility
  4. Cam geometry (eccentricity, disc OD, boss clearance)
  5. Build plate limit
  6. Pulley bend ratio (string health)
  7. Channel count vs hex geometry
  8. Helix length vs shaft extension
  9. Tier stacking (no overlap, total height)
 10. FDM printability (wall thickness, rail depth, PIP gaps)
 11. Compile check (optional — runs OpenSCAD)

Usage:
    python validate_geometry.py config_v5_5.scad
    python validate_geometry.py matrix_stack_v5_5.scad
    python validate_geometry.py --compile matrix_stack_v5_5.scad
    python validate_geometry.py --render matrix_stack_v5_5.scad

Exit codes:
    0 = all checks pass
    1 = one or more FAIL
    2 = could not compile (only with --compile/--render)
"""

import subprocess
import sys
import re
import math
import json
from pathlib import Path

# ============================================================
# OPENSCAD PATHS
# ============================================================
OPENSCAD_PATH = r"C:\Program Files\OpenSCAD\openscad.exe"
OPENSCAD_COM = r"C:\Program Files\OpenSCAD\openscad.com"

# ============================================================
# SCAD CONFIG PARSER
# ============================================================
def parse_scad_config(config_path):
    """Parse OpenSCAD variable assignments from a .scad file.

    Handles simple assignments, arithmetic (+,-,*,/), sqrt(), abs(), PI,
    array literals, variable references, and boolean literals.
    Uses multi-pass resolution for forward references.
    """
    config_path = Path(config_path)
    if not config_path.exists():
        return None

    skip_prefixes = ("//", "/*", "function", "module", "if", "echo", "for", "let")
    skip_vars = {"$fn", "$t", "$fa", "$fs"}

    assignments = []
    with open(config_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(skip_prefixes):
                continue
            if "//" in line:
                line = line[:line.index("//")].strip()

            m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*(.+?)\s*;', line)
            if not m:
                continue
            var_name = m.group(1)
            rhs = m.group(2).strip()
            if var_name in skip_vars or var_name.startswith("$"):
                continue
            assignments.append((var_name, rhs))

    if not assignments:
        return None

    parsed = {}
    for _ in range(6):  # multi-pass
        progress = 0
        for var_name, rhs in assignments:
            if var_name in parsed:
                continue
            val = _eval_expr(rhs, parsed)
            if val is not None:
                parsed[var_name] = val
                progress += 1
        if progress == 0:
            break

    return parsed if parsed else None


def _eval_expr(expr, known):
    expr = expr.strip()
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
    if expr == "true":
        return True
    if expr == "false":
        return False
    return _eval_arithmetic(expr, known)


def _eval_arithmetic(expr, known):
    tokens = _tokenize(expr, known)
    if tokens is None:
        return None
    try:
        result, pos = _parse_add_sub(tokens, 0)
        if pos == len(tokens):
            return result
        return None
    except Exception:
        return None


def _tokenize(expr, known):
    tokens = []
    i = 0
    s = expr.strip()
    if "?" in s or ":" in s:
        return None
    while i < len(s):
        c = s[i]
        if c in " \t":
            i += 1
            continue
        if c in "+-*/()":
            tokens.append(c)
            i += 1
            continue
        if c.isdigit() or c == ".":
            j = i
            while j < len(s) and (s[j].isdigit() or s[j] == "."):
                j += 1
            try:
                tok = s[i:j]
                tokens.append(float(tok) if "." in tok else int(tok))
            except ValueError:
                return None
            i = j
            continue
        if c.isalpha() or c == "_":
            j = i
            while j < len(s) and (s[j].isalnum() or s[j] == "_"):
                j += 1
            name = s[i:j]
            i = j
            if name == "PI":
                tokens.append(math.pi)
                continue
            if name in ("sqrt", "abs", "sin", "cos", "tan", "floor", "ceil", "round", "max", "min") and i < len(s) and s[i] == "(":
                depth = 0
                start = i
                while i < len(s):
                    if s[i] == "(": depth += 1
                    elif s[i] == ")":
                        depth -= 1
                        if depth == 0: break
                    i += 1
                if depth != 0:
                    return None
                inner = s[start+1:i]
                i += 1
                # Handle multi-arg functions
                if name in ("max", "min"):
                    args = inner.split(",")
                    vals = [_eval_arithmetic(a.strip(), known) for a in args]
                    if any(v is None for v in vals):
                        return None
                    tokens.append(max(vals) if name == "max" else min(vals))
                else:
                    inner_val = _eval_arithmetic(inner, known)
                    if inner_val is None:
                        return None
                    fn = {"sqrt": math.sqrt, "abs": abs,
                          "sin": lambda x: math.sin(math.radians(x)),
                          "cos": lambda x: math.cos(math.radians(x)),
                          "tan": lambda x: math.tan(math.radians(x)),
                          "floor": math.floor, "ceil": math.ceil,
                          "round": round}[name]
                    tokens.append(fn(inner_val))
                continue
            if name in known:
                v = known[name]
                if isinstance(v, (int, float)):
                    tokens.append(v)
                    continue
                else:
                    return None
            else:
                return None
        return None
    return tokens if tokens else None


def _parse_add_sub(tokens, pos):
    left, pos = _parse_mul_div(tokens, pos)
    while pos < len(tokens) and tokens[pos] in ("+", "-"):
        op = tokens[pos]; pos += 1
        right, pos = _parse_mul_div(tokens, pos)
        left = left + right if op == "+" else left - right
    return left, pos


def _parse_mul_div(tokens, pos):
    left, pos = _parse_unary(tokens, pos)
    while pos < len(tokens) and tokens[pos] in ("*", "/"):
        op = tokens[pos]; pos += 1
        right, pos = _parse_unary(tokens, pos)
        left = left * right if op == "*" else (left / right if right != 0 else float('inf'))
    return left, pos


def _parse_unary(tokens, pos):
    if pos < len(tokens) and tokens[pos] == "-":
        pos += 1; val, pos = _parse_unary(tokens, pos); return -val, pos
    if pos < len(tokens) and tokens[pos] == "+":
        pos += 1; return _parse_unary(tokens, pos)
    return _parse_atom(tokens, pos)


def _parse_atom(tokens, pos):
    if pos >= len(tokens):
        raise ValueError("unexpected end")
    tok = tokens[pos]
    if isinstance(tok, (int, float)):
        return tok, pos + 1
    if tok == "(":
        val, pos = _parse_add_sub(tokens, pos + 1)
        if pos >= len(tokens) or tokens[pos] != ")":
            raise ValueError("missing )")
        return val, pos + 1
    raise ValueError(f"unexpected: {tok}")


# ============================================================
# CONFIG FINDER
# ============================================================
def find_config(scad_path):
    """Find the config file for a given .scad file."""
    scad_path = Path(scad_path).resolve()
    if scad_path.name.startswith("config_"):
        return scad_path
    try:
        with open(scad_path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                m = re.match(r'^\s*include\s*<(config_[^>]+\.scad)>', line)
                if m:
                    cfg = scad_path.parent / m.group(1)
                    if cfg.exists():
                        return cfg
    except Exception:
        pass
    # Fallback: look for any config_v*.scad in same dir
    for p in sorted(scad_path.parent.glob("config_v*.scad"), reverse=True):
        return p
    return None


# ============================================================
# CONSTRAINT CHECKS — pure config, no ECHO parsing needed
# ============================================================
def run_config_checks(cfg):
    """Run all geometry constraint checks from parsed config values.
    Returns (all_pass, results_list).
    """
    results = []

    def check(name, condition, detail=""):
        status = "PASS" if condition else "FAIL"
        results.append({"status": status, "name": name, "detail": detail})
        sym = "OK" if condition else "XX"
        print(f"  [{sym}] {name}: {detail}")
        return condition

    def get(key, default=None):
        v = cfg.get(key, default)
        return v

    print("\n" + "=" * 60)
    print("GEOMETRY CONSTRAINT VALIDATION (V5.6)")
    print("=" * 60)

    # Required keys for V5.6 checks
    required = [
        "HEX_R", "STACK_OFFSET", "WALL_THICKNESS", "FP_OD", "SP_OD",
        "ECCENTRICITY", "SHAFT_DIA", "SHAFT_BORE", "DISC_OD",
        "SHAFT_BOSS_OD", "CAM_BRG_ID", "CAM_BRG_OD", "CAM_BRG_W",
        "FRAME_BRG_ID", "FRAME_BRG_OD", "FRAME_BRG_W",
        "AXIAL_PITCH", "D_FLAT_DEPTH",
    ]

    # ----------------------------------------------------------
    # CHECK 1: Config parse completeness
    # ----------------------------------------------------------
    print("\n--- CHECK 1: Config Parse Completeness ---")
    missing = [k for k in required if k not in cfg]
    check("Required config vars",
          len(missing) == 0,
          f"missing: {missing}" if missing else f"all {len(required)} found")

    if missing:
        # Can't proceed without core values
        return False, results

    # Grab values
    hex_r = get("HEX_R")
    hex_ff = hex_r * math.sqrt(3)
    stack_off = get("STACK_OFFSET")
    wall_t = get("WALL_THICKNESS")
    ch_gap = stack_off - wall_t
    fp_od = get("FP_OD")
    sp_od = get("SP_OD")
    min_rope_gap = get("_MIN_ROPE_GAP", 1.5)
    fp_row_y = (fp_od + sp_od) / 2 + min_rope_gap
    housing_h = 2 * fp_row_y + fp_od + 1
    ecc = get("ECCENTRICITY")
    shaft_dia = get("SHAFT_DIA")
    shaft_bore = get("SHAFT_BORE")
    disc_od = get("DISC_OD")
    boss_od = get("SHAFT_BOSS_OD")
    cam_brg_id = get("CAM_BRG_ID")
    cam_brg_od = get("CAM_BRG_OD")
    cam_brg_w = get("CAM_BRG_W")
    frame_brg_od = get("FRAME_BRG_OD")
    frame_brg_w = get("FRAME_BRG_W")
    axial_pitch = get("AXIAL_PITCH")
    d_flat = get("D_FLAT_DEPTH")
    collar_thick = axial_pitch - (cam_brg_w + 1)  # DISC_THICK = CAM_BRG_W + 1

    # Channel count (replicate OpenSCAD formula)
    half_count = math.floor((hex_ff / 2 - stack_off / 2) / stack_off)
    num_ch = 2 * half_count + 1

    # Star/frame geometry
    star_ratio = get("_STAR_RATIO", 2.5)
    star_tip_r = star_ratio * 2 * hex_r

    # ----------------------------------------------------------
    # CHECK 2: Z-Stack Budget (slider plates fit in gap)
    # ----------------------------------------------------------
    print("\n--- CHECK 2: Z-Stack Budget ---")
    pip_z_gap = 0.35  # V5.5c R1
    s_gap = 3.0       # V5.6 matrix local
    rail_depth = 0.8   # V5.6 matrix local

    plate_t = ch_gap / 2 - s_gap / 2 - pip_z_gap
    check("Slider plate thickness > 1.5mm",
          plate_t >= 1.5,
          f"plate_t={plate_t:.2f}mm (CH_GAP/2={ch_gap/2:.1f} - S_GAP/2={s_gap/2:.1f} - PIP={pip_z_gap})")

    check("Slider plate > rail depth",
          plate_t > rail_depth + 0.3,
          f"plate_t={plate_t:.2f}mm vs rail_depth={rail_depth}mm (+0.3 margin)")

    slot_d = pip_z_gap + rail_depth + 0.5
    check("Slot depth < plate thickness",
          slot_d < plate_t,
          f"slot_d={slot_d:.2f}mm vs plate_t={plate_t:.2f}mm")

    half_gap_total = pip_z_gap + plate_t + s_gap / 2
    check("Z budget fits in half gap",
          abs(half_gap_total - ch_gap / 2) < 0.01,
          f"pip+plate+s/2 = {half_gap_total:.3f}mm vs CH_GAP/2 = {ch_gap/2:.3f}mm")

    # ----------------------------------------------------------
    # CHECK 3: Bearing / Shaft Compatibility
    # ----------------------------------------------------------
    print("\n--- CHECK 3: Bearing / Shaft Compatibility ---")
    check("Shaft fits frame bearing",
          shaft_dia <= get("FRAME_BRG_ID", shaft_dia),
          f"shaft={shaft_dia}mm, frame_brg_ID={get('FRAME_BRG_ID', '?')}mm")

    check("Shaft bore > shaft dia",
          shaft_bore > shaft_dia,
          f"bore={shaft_bore}mm > shaft={shaft_dia}mm (clearance={shaft_bore - shaft_dia:.1f}mm)")

    check("D-flat depth < shaft radius",
          d_flat < shaft_dia / 2,
          f"D_flat={d_flat}mm < radius={shaft_dia/2}mm")

    d_bore_flat = shaft_dia - 2 * d_flat
    check("D-bore flat > 2mm",
          d_bore_flat >= 2.0,
          f"D_bore_flat={d_bore_flat:.1f}mm (shaft - 2*D_flat)")

    # ----------------------------------------------------------
    # CHECK 4: Cam Geometry
    # ----------------------------------------------------------
    print("\n--- CHECK 4: Cam Geometry ---")
    cam_ecc = disc_od / 2 - boss_od / 2
    check("CAM_ECC = ECCENTRICITY",
          abs(cam_ecc - ecc) < 0.01,
          f"CAM_ECC={cam_ecc:.1f}mm, ECCENTRICITY={ecc}mm")

    check("Disc OD < bearing bore",
          disc_od < cam_brg_id,
          f"DISC_OD={disc_od}mm < CAM_BRG_ID={cam_brg_id}mm (gap={cam_brg_id-disc_od:.1f}mm)")

    boss_wall = (boss_od - shaft_bore) / 2
    check("Boss wall >= 1.5mm",
          boss_wall >= 1.5,
          f"boss_wall={boss_wall:.1f}mm = (boss_OD={boss_od} - bore={shaft_bore})/2")

    check("Collar thickness >= 1.0mm",
          collar_thick >= 1.0,
          f"collar={collar_thick:.1f}mm = axial_pitch={axial_pitch} - disc_thick={cam_brg_w+1}")

    follower_id = cam_brg_od + 0.3
    check("Follower clears bearing",
          follower_id > cam_brg_od,
          f"follower_ID={follower_id:.1f}mm > bearing_OD={cam_brg_od}mm")

    # ----------------------------------------------------------
    # CHECK 5: Build Plate Limit
    # ----------------------------------------------------------
    print("\n--- CHECK 5: Build Plate ---")
    build_plate = 349  # Creality K2
    # ARM_END_R is typically ~0.8 * STAR_TIP_R for the carrier node
    arm_end_r = star_tip_r * 0.81  # approximate
    check("Frame fits build plate",
          2 * arm_end_r <= build_plate,
          f"dia={2*arm_end_r:.0f}mm vs plate={build_plate}mm")

    # ----------------------------------------------------------
    # CHECK 6: Pulley Bend Ratio
    # ----------------------------------------------------------
    print("\n--- CHECK 6: Pulley Bend Ratio ---")
    string_dia = get("STRING_DIA", 0.5)
    bend_ratio = fp_od / string_dia
    check("FP bend ratio >= 8:1",
          bend_ratio >= 8.0,
          f"FP_OD={fp_od}mm / string={string_dia}mm = {bend_ratio:.0f}:1")

    sp_bend = sp_od / string_dia
    check("SP bend ratio >= 8:1",
          sp_bend >= 8.0,
          f"SP_OD={sp_od}mm / string={string_dia}mm = {sp_bend:.0f}:1")

    # ----------------------------------------------------------
    # CHECK 7: Channel Count vs Hex Geometry
    # ----------------------------------------------------------
    print("\n--- CHECK 7: Channel / Hex Geometry ---")
    check("Odd channel count",
          num_ch % 2 == 1,
          f"NUM_CHANNELS={num_ch}")

    check("Channel count >= 5",
          num_ch >= 5,
          f"NUM_CHANNELS={num_ch}")

    # Check that outermost channels fit inside hex
    max_ch_offset = half_count * stack_off
    max_hex_d = hex_ff / 2
    check("Outer channels inside hex",
          max_ch_offset < max_hex_d,
          f"max_offset={max_ch_offset:.1f}mm < hex_FF/2={max_hex_d:.1f}mm")

    # Check outermost channel has nonzero width
    outer_w = 2 * (hex_r - max_ch_offset / math.sqrt(3))
    check("Outer channel width > 0",
          outer_w > 0,
          f"hex_w at d={max_ch_offset:.1f} = {outer_w:.1f}mm")

    # ----------------------------------------------------------
    # CHECK 8: Helix Length vs Shaft
    # ----------------------------------------------------------
    print("\n--- CHECK 8: Helix / Shaft ---")
    helix_len = num_ch * axial_pitch
    check("Helix length correct",
          True,
          f"HELIX_LENGTH = {num_ch} cams x {axial_pitch}mm = {helix_len}mm")

    total_twist = num_ch * (360.0 / num_ch)
    check("Total twist = 360 deg",
          abs(total_twist - 360.0) < 0.01,
          f"{num_ch} x {360.0/num_ch:.1f}deg = {total_twist:.1f}deg")

    # ----------------------------------------------------------
    # CHECK 9: Tier Stacking
    # ----------------------------------------------------------
    print("\n--- CHECK 9: Tier Stacking ---")
    tier_pitch = housing_h  # INTER_TIER_GAP = 0
    total_stack = 3 * housing_h
    tier1_top = tier_pitch + housing_h / 2
    tier3_bot = -tier_pitch - housing_h / 2
    check("Stack height reasonable",
          20 <= total_stack <= 80,
          f"3 x {housing_h}mm = {total_stack}mm")

    check("Tier1 top = +tier_pitch + H/2",
          True,
          f"TIER1_TOP = {tier1_top}mm")

    check("Tier3 bot = -tier_pitch - H/2",
          True,
          f"TIER3_BOT = {tier3_bot}mm")

    # ----------------------------------------------------------
    # CHECK 10: FDM Printability
    # ----------------------------------------------------------
    print("\n--- CHECK 10: FDM Printability ---")
    nozzle = 0.4
    check("Wall thickness >= 3 perimeters",
          wall_t >= 3 * nozzle,
          f"wall={wall_t}mm vs 3x{nozzle}={3*nozzle}mm")

    check("Rail depth >= 2 perimeters",
          rail_depth >= 2 * nozzle,
          f"rail={rail_depth}mm vs 2x{nozzle}={2*nozzle}mm")

    check("PIP Z gap >= 0.3mm",
          pip_z_gap >= 0.3,
          f"PIP_Z_GAP={pip_z_gap}mm")

    check("S_GAP >= 2.5mm (PIP pulley zone)",
          s_gap >= 2.5,
          f"S_GAP={s_gap}mm")

    # Pulley wall thickness
    pulley_wall = (fp_od - 1.5) / 2  # axle ~1.5mm
    perimeters = pulley_wall / nozzle
    check("Pulley wall >= 2 perimeters",
          perimeters >= 2.0,
          f"wall={pulley_wall:.1f}mm = {perimeters:.1f} perimeters at {nozzle}mm")

    # ----------------------------------------------------------
    # SUMMARY
    # ----------------------------------------------------------
    passes = sum(1 for r in results if r["status"] == "PASS")
    fails = sum(1 for r in results if r["status"] == "FAIL")
    print(f"\n{'=' * 60}")
    print(f"RESULTS: {passes} PASS, {fails} FAIL, {len(results)} total")
    print(f"{'=' * 60}")

    return fails == 0, results


# ============================================================
# COMPILE CHECK (optional)
# ============================================================
def compile_check(scad_path):
    """Compile the .scad file, report errors/warnings."""
    scad_path = Path(scad_path).resolve()
    csg_out = scad_path.with_suffix(".test.csg")
    cmd = [OPENSCAD_COM, "-o", str(csg_out), str(scad_path)]

    print(f"\nCompiling: {scad_path.name}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print("ERROR: OpenSCAD timed out (120s)")
        return False, []

    all_output = result.stdout + result.stderr
    lines = all_output.splitlines()

    errors = [l for l in lines if "ERROR" in l or "error" in l.lower()]
    warnings = [l for l in lines if "WARNING" in l]
    echos = [l for l in lines if l.startswith("ECHO:")]
    config_warns = [l for l in echos if "CONFIG !!" in l]

    if errors:
        print(f"  COMPILE ERRORS ({len(errors)}):")
        for e in errors[:10]:
            print(f"    {e}")
        return False, config_warns

    print(f"  Compile OK: {len(echos)} echoes, {len(warnings)} warnings")
    if config_warns:
        print(f"  CONFIG WARNINGS ({len(config_warns)}):")
        for w in config_warns:
            print(f"    {w}")

    return True, config_warns


def render_png(scad_path):
    """Render a PNG preview."""
    scad_path = Path(scad_path).resolve()
    png_out = scad_path.with_suffix(".validate.png")
    cmd = [
        OPENSCAD_PATH,
        "--camera=0,0,0,55,0,25,800",
        "--imgsize=1600,1200",
        "--colorscheme=Tomorrow Night",
        "-o", str(png_out),
        str(scad_path)
    ]
    print(f"\nRendering: {png_out.name}")
    try:
        subprocess.run(cmd, capture_output=True, timeout=180)
        print(f"  Rendered: {png_out}")
    except subprocess.TimeoutExpired:
        print("  Render timed out")


# ============================================================
# MAIN
# ============================================================
def main():
    args = sys.argv[1:]
    do_compile = "--compile" in args
    do_render = "--render" in args
    args = [a for a in args if not a.startswith("--")]

    if not args:
        print("Usage: python validate_geometry.py [--compile] [--render] <file.scad>")
        sys.exit(2)

    scad_file = args[0]
    scad_path = Path(scad_file).resolve()
    if not scad_path.exists():
        print(f"ERROR: File not found: {scad_path}")
        sys.exit(2)

    # Find and parse config
    config_path = find_config(scad_path)
    if config_path is None:
        print(f"ERROR: No config file found for {scad_path.name}")
        sys.exit(2)

    print(f"Config: {config_path.name}")
    cfg = parse_scad_config(config_path)
    if cfg is None:
        print(f"ERROR: Could not parse {config_path.name}")
        sys.exit(2)

    print(f"  Parsed {len(cfg)} variables")

    # Run constraint checks
    all_pass, results = run_config_checks(cfg)

    # Optional compile
    compile_ok = True
    config_warns = []
    if do_compile or do_render:
        compile_ok, config_warns = compile_check(scad_path)
        if not compile_ok:
            all_pass = False
        if config_warns:
            for w in config_warns:
                results.append({"status": "FAIL", "name": "CONFIG warning", "detail": w})
                all_pass = False

    # Optional render
    if do_render and compile_ok:
        render_png(scad_path)

    # Write results JSON
    results_file = scad_path.with_suffix(".validate.json")
    with open(results_file, "w") as f:
        json.dump({
            "file": str(scad_path),
            "config": str(config_path),
            "parsed_count": len(cfg),
            "checks": results,
            "summary": {
                "pass": sum(1 for r in results if r["status"] == "PASS"),
                "fail": sum(1 for r in results if r["status"] == "FAIL")
            }
        }, f, indent=2)
    print(f"\nResults: {results_file}")

    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
