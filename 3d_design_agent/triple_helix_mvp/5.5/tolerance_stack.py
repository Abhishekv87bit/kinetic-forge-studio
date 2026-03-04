"""
Tolerance Stack Analysis -- Triple Helix MVP V5.5
===================================================
Catches "validates in software, fails at assembly" by analyzing tolerance chains.
When parts stack together (shaft -> bearing -> mount -> frame), each tolerance adds
up. If the stack exceeds the functional limit, the assembly won't work even if each
individual part is within spec.

Usage:
    python tolerance_stack.py                   # run analysis
    python tolerance_stack.py --verbose         # per-component breakdown
    python tolerance_stack.py --config FILE     # use alternate config file

Exit code: 0 if no FAILs, 1 if any FAILs.
"""

import sys
import os
import re
import math
import argparse
from pathlib import Path

# ================================================================
# PATH SETUP
# ================================================================
SCRIPT_DIR = Path(__file__).resolve().parent

# ================================================================
# TOLERANCE SOURCES (embedded constants)
# ================================================================
TOL_FDM_SMALL = 0.10    # mm, small features (<10mm)
TOL_FDM_MEDIUM = 0.20   # mm, medium features (10-50mm)
TOL_FDM_LARGE = 0.30    # mm, large features (>50mm)
TOL_GROUND_ROD = 0.005  # mm, precision ground steel rod
TOL_BEARING = 0.004     # mm, bearing bore/OD (ABEC-1)
TOL_ECLIP = 0.05        # mm, E-clip groove position
TOL_PRESS_FIT = 0.05    # mm, interference fit target

# ================================================================
# CONFIG PARSER (reused pattern from consistency_audit.py)
# ================================================================

def parse_scad_assignments(filepath):
    """
    Parse top-level OpenSCAD variable assignments from a file.
    Returns dict of { VAR_NAME: raw_value_string }.
    Handles:  VARNAME = <value>;  (including multi-line with continuation)
    Skips lines starting with // or inside /* ... */ blocks.
    """
    assignments = {}
    if not filepath.is_file():
        return assignments

    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    # Remove block comments
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)

    # Remove line comments (but preserve newlines for structure)
    lines = content.split('\n')
    cleaned_lines = []
    for line in lines:
        # Remove // comments but keep the code part
        if '//' in line:
            line = line[:line.index('//')]
        cleaned_lines.append(line)
    content = '\n'.join(cleaned_lines)

    # Join continuation lines: if a line doesn't end with ';' and the next line
    # continues an expression, merge them
    merged = []
    buf = ""
    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped:
            if buf:
                merged.append(buf)
                buf = ""
            continue
        if buf:
            buf += " " + stripped
        else:
            buf = stripped
        if ';' in buf:
            merged.append(buf)
            buf = ""
    if buf:
        merged.append(buf)

    for line in merged:
        line = line.strip()
        # Match: NAME = value ;
        m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*([^;]+);', line)
        if m:
            var_name = m.group(1)
            var_value = m.group(2).strip()
            assignments[var_name] = var_value

    return assignments


def _safe_eval(expr_str):
    """
    Evaluate a numeric expression string with math functions available.
    Returns float or None.
    """
    safe_ns = {
        "__builtins__": {},
        "math": math,
        "sqrt": math.sqrt,
        "sin": lambda x: math.sin(math.radians(x)),  # OpenSCAD uses degrees
        "cos": lambda x: math.cos(math.radians(x)),
        "tan": lambda x: math.tan(math.radians(x)),
        "abs": abs,
        "floor": math.floor,
        "ceil": math.ceil,
        "max": max,
        "min": min,
        "PI": math.pi,
        "round": round,
        "pow": pow,
        "len": len,
    }
    try:
        val = eval(expr_str, safe_ns)
        return float(val)
    except Exception:
        return None


def try_eval_numeric(raw):
    """Evaluate a raw value string as a numeric. Returns float or None."""
    raw = raw.strip()
    # Strip inline comments
    if "//" in raw:
        raw = raw[:raw.index("//")].strip()
    # Skip things we truly cannot evaluate
    if any(kw in raw for kw in ["let(", "for ", "[", "function", "if "]):
        return None
    cleaned = raw.replace("true", "True").replace("false", "False")
    result = _safe_eval(cleaned)
    if result is not None:
        return result
    try:
        return float(raw)
    except ValueError:
        return None


def load_config(config_path):
    """
    Load config and resolve derived values iteratively.
    Returns dict of { VAR_NAME: float_value } for all evaluable parameters.
    Runs multiple passes to resolve chains of dependencies.
    """
    raw = parse_scad_assignments(config_path)
    resolved = {}

    # Sort by name length (shorter names first) to avoid partial substitution issues
    # e.g., CAM_BRG_W before CAM_BRG_WID
    sorted_names = sorted(raw.keys(), key=lambda n: -len(n))

    # Resolve OpenSCAD function calls that we can compute
    # _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET)
    # where HEX_FF = HEX_R * sqrt(3)
    def _resolve_functions(expr, resolved_vals):
        """Replace known OpenSCAD function calls with computed values."""
        result = expr
        # _half_count()
        if '_half_count()' in result:
            hex_r = resolved_vals.get("HEX_R")
            stack_offset = resolved_vals.get("STACK_OFFSET")
            if hex_r is not None and stack_offset is not None:
                hex_ff = hex_r * math.sqrt(3)
                half_count = math.floor((hex_ff / 2 - stack_offset / 2) / stack_offset)
                result = result.replace('_half_count()', str(half_count))
        return result

    # Iterative resolution: keep trying until no new values resolve
    max_passes = 15
    for pass_num in range(max_passes):
        newly_resolved = 0
        for name in raw:
            if name in resolved:
                continue
            expr = raw[name]
            # Substitute all known resolved values (longest names first)
            substituted = expr
            for rname in sorted_names:
                if rname in resolved:
                    substituted = re.sub(rf'\b{re.escape(rname)}\b',
                                         str(resolved[rname]), substituted)
            # Resolve known function calls
            substituted = _resolve_functions(substituted, resolved)
            val = try_eval_numeric(substituted)
            if val is not None:
                resolved[name] = val
                newly_resolved += 1
        if newly_resolved == 0:
            break

    return resolved


# ================================================================
# RESULT TRACKING
# ================================================================
_results = []  # list of (status, chain_name, message)


def _pass(chain, msg):
    _results.append(("PASS", chain, msg))


def _warn(chain, msg):
    _results.append(("WARN", chain, msg))


def _fail(chain, msg):
    _results.append(("FAIL", chain, msg))


# ================================================================
# ANALYSIS HELPERS
# ================================================================

def worst_case(tol_list):
    """Worst-case tolerance stack: sum of absolute tolerances."""
    return sum(abs(t) for t in tol_list)


def rss(tol_list):
    """Root-sum-square tolerance stack (statistical)."""
    return math.sqrt(sum(t * t for t in tol_list))


def verdict(margin):
    """Return verdict string based on margin."""
    if margin > 0.05:
        return "PASS"
    elif margin >= 0:
        return "WARN"
    else:
        return "FAIL"


def analyze_chain(chain_name, nominal, limit, tol_list, part_labels,
                  description, limit_description, verbose=False):
    """
    Analyze a tolerance chain and record results.

    Args:
        chain_name: Display name for the chain
        nominal: Nominal dimension (mm)
        limit: Functional limit (mm) -- the maximum allowable stack
        tol_list: List of (tolerance_value, part_count) tuples
        part_labels: List of (label, tolerance, count) for verbose output
        description: What this chain represents
        limit_description: What happens if limit is exceeded
        verbose: Show per-component breakdown
    """
    # Build flat tolerance list
    flat_tols = []
    for tol_val, count in tol_list:
        flat_tols.extend([tol_val] * count)

    total_parts = len(flat_tols)
    wc = worst_case(flat_tols)
    rs = rss(flat_tols)
    margin_wc = limit - wc
    margin_rss = limit - rs
    verd = verdict(margin_wc)

    # Record result
    record = _pass if verd == "PASS" else (_warn if verd == "WARN" else _fail)
    record(chain_name,
           f"WC margin={margin_wc:+.2f}mm, RSS margin={margin_rss:+.2f}mm "
           f"({total_parts} parts)")

    return {
        "chain_name": chain_name,
        "description": description,
        "nominal": nominal,
        "limit": limit,
        "limit_description": limit_description,
        "total_parts": total_parts,
        "worst_case": wc,
        "rss": rs,
        "margin_wc": margin_wc,
        "margin_rss": margin_rss,
        "verdict": verd,
        "part_labels": part_labels,
    }


# ================================================================
# CHAIN DEFINITIONS
# ================================================================

def chain_axial_disc_stack(cfg, verbose=False):
    """
    Chain 1: Axial Disc Stack (9 discs + 9 collars on shaft)
    E-clip -> [disc -> collar] x 9 -> E-clip
    """
    num_cams = int(cfg.get("NUM_CAMS", 9))
    disc_thick = cfg.get("DISC_THICK", 5.0)
    collar_thick = cfg.get("COLLAR_THICK", 3.0)
    axial_pitch = cfg.get("AXIAL_PITCH", 8.0)
    helix_length = cfg.get("HELIX_LENGTH", 72.0)

    nominal_total = num_cams * disc_thick + num_cams * collar_thick
    # Available shaft length = HELIX_LENGTH (space between E-clips)
    available = helix_length

    # Each disc and collar is a small FDM part
    tol_list = [
        (TOL_FDM_SMALL, num_cams),   # discs
        (TOL_FDM_SMALL, num_cams),   # collars
    ]

    part_labels = [
        (f"Cam disc (x{num_cams})", TOL_FDM_SMALL, num_cams),
        (f"Collar (x{num_cams})", TOL_FDM_SMALL, num_cams),
    ]

    # E-clip groove positions add additional uncertainty to end constraints
    # but the functional limit is how much axial play the E-clips can absorb.
    # E-clips on 4mm shaft have ~0.5mm groove engagement.
    # Some axial play is acceptable (spring-loaded or gravity-seated).
    functional_limit = 2.0  # mm of total stack error the E-clips can absorb

    return analyze_chain(
        "Chain 1: Axial Disc Stack",
        nominal=nominal_total,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"{num_cams} discs ({disc_thick}mm) + {num_cams} collars ({collar_thick}mm) "
            f"on shaft. Nominal total={nominal_total:.1f}mm, "
            f"available={available:.1f}mm"
        ),
        limit_description=(
            "E-clip groove captures; some axial play is acceptable. "
            "If stack too long, last disc won't seat. "
            "If too short, excessive axial rattle."
        ),
        verbose=verbose,
    )


def chain_matrix_in_frame(cfg, verbose=False):
    """
    Chain 2: Matrix-in-Frame Fit (sliding fit)
    Frame ring bore (FRAME_RING_R_IN) vs Matrix hex (HEX_R)
    """
    hex_r = cfg.get("HEX_R", 43.0)
    ring_r_in = cfg.get("_RING_R_IN_CFG", 45.0)

    nominal_gap = ring_r_in - hex_r
    # Frame ring is a large circle (>50mm radius)
    # Matrix hex is also large
    tol_list = [
        (TOL_FDM_LARGE, 1),   # frame ring bore
        (TOL_FDM_LARGE, 1),   # matrix hex outer
    ]

    part_labels = [
        (f"Frame ring bore (R_in={ring_r_in}mm)", TOL_FDM_LARGE, 1),
        (f"Matrix hex (HEX_R={hex_r}mm)", TOL_FDM_LARGE, 1),
    ]

    # Must fit (gap > 0) but not rattle excessively (gap < ~3mm)
    # We check the MINIMUM gap (worst case tight)
    min_gap = nominal_gap - worst_case([TOL_FDM_LARGE, TOL_FDM_LARGE])
    max_gap = nominal_gap + worst_case([TOL_FDM_LARGE, TOL_FDM_LARGE])

    # For this chain, the "limit" is 0 (must not go negative)
    functional_limit = nominal_gap  # the total tolerance budget IS the nominal gap

    return analyze_chain(
        "Chain 2: Matrix-in-Frame Fit",
        nominal=nominal_gap,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Frame ring bore R_in={ring_r_in}mm vs matrix hex R={hex_r}mm. "
            f"Nominal radial gap={nominal_gap:.1f}mm. "
            f"Worst-case range: {min_gap:.2f}mm to {max_gap:.2f}mm"
        ),
        limit_description=(
            "Gap must be > 0 (matrix fits inside frame). "
            f"Min gap={min_gap:.2f}mm {'(OK)' if min_gap > 0 else '(INTERFERENCE!)'}. "
            f"Max gap={max_gap:.2f}mm {'(rattly but functional)' if max_gap > 3 else '(OK)'}."
        ),
        verbose=verbose,
    )


def chain_bearing_bore_fit(cfg, verbose=False):
    """
    Chain 3: Bearing Bore Fit
    Ground rod shaft -> MR84ZZ bearing bore -> 3D-printed bearing mount
    """
    shaft_dia = cfg.get("SHAFT_DIA", 4.0)
    brg_id = cfg.get("FRAME_BRG_ID", 4.0)
    brg_od = cfg.get("FRAME_BRG_OD", 8.0)

    # Shaft-to-bearing: both precision parts, line-to-line fit
    # Worst case interference: shaft max, bearing bore min
    worst_interference = (shaft_dia + TOL_GROUND_ROD) - (brg_id - TOL_BEARING)
    # Worst case clearance: shaft min, bearing bore max
    worst_clearance = (brg_id + TOL_BEARING) - (shaft_dia - TOL_GROUND_ROD)

    tol_list = [
        (TOL_GROUND_ROD, 1),  # shaft
        (TOL_BEARING, 1),     # bearing bore
    ]

    part_labels = [
        (f"Ground rod shaft ({shaft_dia}mm +/-{TOL_GROUND_ROD}mm)", TOL_GROUND_ROD, 1),
        (f"MR84ZZ bearing bore ({brg_id}mm +/-{TOL_BEARING}mm)", TOL_BEARING, 1),
    ]

    # For precision bearing fits, 0.009mm interference is normal and expected.
    # MR84ZZ bearings accept light press / finger press at this scale.
    # The functional limit is 0.015mm -- beyond that, bearing won't slide on.
    functional_limit = 0.015

    result = analyze_chain(
        "Chain 3: Bearing Bore Fit (Shaft-to-MR84ZZ)",
        nominal=0.0,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Shaft {shaft_dia}mm (+/-{TOL_GROUND_ROD}) in "
            f"MR84ZZ bore {brg_id}mm (+/-{TOL_BEARING}). "
            f"Worst interference: {worst_interference:+.3f}mm. "
            f"Worst clearance: {worst_clearance:+.3f}mm"
        ),
        limit_description=(
            "Line-to-line fit is normal for miniature bearings. "
            f"Worst interference={worst_interference:.3f}mm -- "
            f"acceptable for MR84ZZ (finger-press fit up to ~0.015mm)."
        ),
        verbose=verbose,
    )

    # Also check printed bearing mount bore
    # The mount bore should be designed slightly undersized for press fit
    # or slightly oversized with Loctite. FDM tolerance dominates.
    mount_clearance_designed = 0.0  # line-to-line design intent
    mount_min_gap = mount_clearance_designed - TOL_BEARING - TOL_FDM_SMALL
    mount_max_gap = mount_clearance_designed + TOL_BEARING + TOL_FDM_SMALL

    mount_tol_list = [
        (TOL_BEARING, 1),       # bearing OD
        (TOL_FDM_SMALL, 1),     # printed bore
    ]

    mount_labels = [
        (f"MR84ZZ bearing OD ({brg_od}mm +/-{TOL_BEARING}mm)", TOL_BEARING, 1),
        (f"Printed mount bore (+/-{TOL_FDM_SMALL}mm)", TOL_FDM_SMALL, 1),
    ]

    # For printed bores, +/-0.1mm is common. Bearing needs to be retained.
    # Press fit range: -0.05 to +0.10mm. Loose fit: > +0.10mm (use Loctite).
    # Functional limit: the tolerance budget before we lose either press-fit
    # or assemblability. With reaming, this is very forgiving.
    analyze_chain(
        "Chain 3b: Bearing Mount Bore (MR84ZZ in printed carrier)",
        nominal=mount_clearance_designed,
        limit=0.15,  # generous: ream to fit, or Loctite if loose
        tol_list=mount_tol_list,
        part_labels=mount_labels,
        description=(
            f"MR84ZZ OD {brg_od}mm in printed bore. "
            f"Recommend +0.05mm oversize bore for press fit. "
            f"Worst-case gap range: {mount_min_gap:+.3f} to {mount_max_gap:+.3f}mm"
        ),
        limit_description=(
            "Bearing must be retained in mount. "
            "Too loose: use Loctite 638 or CA glue. "
            "Too tight: ream bore with 8mm drill bit. "
            "FDM bore accuracy is the limiting factor."
        ),
        verbose=verbose,
    )

    return result


def chain_cam_disc_on_shaft(cfg, verbose=False):
    """
    Chain 4: Cam Disc on Shaft
    Shaft (ground rod with D-flat) -> Disc bore (SHAFT_BORE with D-flat)
    Two independent fits: round clearance and D-flat clearance.
    """
    shaft_dia = cfg.get("SHAFT_DIA", 4.0)
    d_flat_depth = cfg.get("D_FLAT_DEPTH", 0.4)
    shaft_bore = cfg.get("SHAFT_BORE", 4.2)
    d_bore_flat = cfg.get("D_BORE_FLAT", 3.2)

    # Round direction: bore vs shaft
    round_clearance = shaft_bore - shaft_dia  # 0.2mm nominal

    # D-flat direction: bore flat vs shaft flat
    shaft_flat = shaft_dia - 2 * d_flat_depth  # 3.2mm
    flat_clearance = d_bore_flat - shaft_flat  # 0mm nominal

    # The round fit determines assemblability (can the disc slide on?)
    # Only shaft rod tolerance + printed bore tolerance matter here.
    # The D-flat is a separate feature -- its tolerance affects angular play,
    # not assemblability.
    tol_list = [
        (TOL_GROUND_ROD, 1),   # shaft diameter
        (TOL_FDM_SMALL, 1),    # printed bore diameter
    ]

    part_labels = [
        (f"Ground rod shaft ({shaft_dia}mm +/-{TOL_GROUND_ROD}mm)", TOL_GROUND_ROD, 1),
        (f"Printed disc bore ({shaft_bore}mm +/-{TOL_FDM_SMALL}mm)", TOL_FDM_SMALL, 1),
    ]

    # Functional limit: the designed 0.2mm round clearance.
    # Worst case tight: shaft max (4.005) in bore min (4.1) = 0.095mm clearance (OK)
    # Worst case loose: shaft min (3.995) in bore max (4.3) = 0.305mm clearance (sloppy but OK)
    # The disc slides on as long as clearance > 0.
    functional_limit = round_clearance

    return analyze_chain(
        "Chain 4: Cam Disc on Shaft (D-flat keyed)",
        nominal=round_clearance,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Shaft {shaft_dia}mm (D-flat depth={d_flat_depth}mm) in "
            f"disc bore {shaft_bore}mm (D-bore flat={d_bore_flat}mm). "
            f"Round clearance={round_clearance:.1f}mm, "
            f"flat clearance={flat_clearance:.1f}mm (anti-rotation only)"
        ),
        limit_description=(
            "Disc must slide onto shaft but not wobble excessively. "
            "D-flat prevents free rotation -- its clearance affects angular play only. "
            "CA glue + keyed collar bump provides final angular lock."
        ),
        verbose=verbose,
    )


def chain_guide_plate_in_ring(cfg, verbose=False):
    """
    Chain 5: Guide Plate in Lower Ring
    Guide plate hex (PLATE_HEX_R = HEX_R - SLEEVE_CLEARANCE) into hex sleeve bore.
    The sleeve bore is cut at HEX_R (same as the matrix hex profile).
    Clearance = SLEEVE_CLEARANCE between plate and sleeve.
    """
    hex_r = cfg.get("HEX_R", 43.0)
    sleeve_clearance = cfg.get("SLEEVE_CLEARANCE", 0.15)
    plate_hex_r = cfg.get("PLATE_HEX_R", hex_r - sleeve_clearance)

    # The hex sleeve bore is cut at HEX_R.
    # The plate is undersized by SLEEVE_CLEARANCE.
    # Both are hex profiles so the clearance applies across flats.
    nominal_clearance = sleeve_clearance  # 0.15mm

    # Both the plate and sleeve are ~43mm hex features (medium FDM tolerance).
    # However, they are printed as PART OF different assemblies:
    #   - Plate: standalone print, hex perimeter ~43mm across flats
    #   - Ring sleeve: part of monolith frame, internal hex pocket
    # Internal pockets on FDM tend to shrink (material pulling inward),
    # so the sleeve bore may be slightly undersized.
    # The plate outer hex may be slightly oversized (same shrinkage effect).
    # Using medium tolerance for both is conservative.
    tol_plate = TOL_FDM_MEDIUM  # 0.20mm for plate hex (~43mm)
    tol_sleeve = TOL_FDM_MEDIUM  # 0.20mm for sleeve bore (~43mm)

    tol_list = [
        (tol_plate, 1),    # plate hex outer
        (tol_sleeve, 1),   # sleeve bore inner
    ]

    part_labels = [
        (f"Guide plate hex (R={plate_hex_r:.2f}mm +/-{tol_plate}mm)", tol_plate, 1),
        (f"Ring hex sleeve bore (R={hex_r}mm +/-{tol_sleeve}mm)", tol_sleeve, 1),
    ]

    min_clearance = nominal_clearance - tol_plate - tol_sleeve
    max_clearance = nominal_clearance + tol_plate + tol_sleeve

    # Functional limit: clearance must remain > 0 for assembly.
    # But unlike a sliding fit, this is a drop-in fit with hex anti-rotation.
    # If tight: sand the plate corners. If loose: hex shape still keys rotation.
    # Generous limit because remediation is easy.
    functional_limit = nominal_clearance

    return analyze_chain(
        "Chain 5: Guide Plate in Lower Ring",
        nominal=nominal_clearance,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Plate hex R={plate_hex_r:.2f}mm in sleeve bore R={hex_r}mm. "
            f"Nominal clearance={nominal_clearance:.2f}mm. "
            f"Range: {min_clearance:.2f}mm to {max_clearance:.2f}mm"
        ),
        limit_description=(
            f"Plate must drop into ring sleeve. "
            f"Min clearance={min_clearance:.2f}mm "
            f"{'(INTERFERENCE -- sand plate corners)' if min_clearance < 0 else '(OK)'}. "
            f"Hex shape prevents rotation -- loose radial fit is acceptable. "
            f"Increase SLEEVE_CLEARANCE to 0.30mm if tight on first print."
        ),
        verbose=verbose,
    )


def chain_follower_ring_on_cam_bearing(cfg, verbose=False):
    """
    Chain 6: Follower Ring on Cam Bearing
    Cam bearing OD (6704ZZ, 27mm) -> Follower ring ID (27.3mm)
    """
    cam_brg_od = cfg.get("CAM_BRG_OD", 27.0)
    follower_ring_id = cfg.get("FOLLOWER_RING_ID", cam_brg_od + 0.3)

    nominal_clearance = follower_ring_id - cam_brg_od

    tol_list = [
        (TOL_BEARING, 1),       # bearing OD (precision)
        (TOL_FDM_MEDIUM, 1),    # printed ring ID (~27mm feature)
    ]

    part_labels = [
        (f"6704ZZ bearing OD ({cam_brg_od}mm +/-{TOL_BEARING}mm)", TOL_BEARING, 1),
        (f"Follower ring ID ({follower_ring_id:.1f}mm +/-{TOL_FDM_MEDIUM}mm)", TOL_FDM_MEDIUM, 1),
    ]

    min_clearance = nominal_clearance - TOL_BEARING - TOL_FDM_MEDIUM
    max_clearance = nominal_clearance + TOL_BEARING + TOL_FDM_MEDIUM

    functional_limit = nominal_clearance

    return analyze_chain(
        "Chain 6: Follower Ring on Cam Bearing",
        nominal=nominal_clearance,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"6704ZZ OD={cam_brg_od}mm, follower ring ID={follower_ring_id:.1f}mm. "
            f"Nominal clearance={nominal_clearance:.1f}mm. "
            f"Range: {min_clearance:.3f}mm to {max_clearance:.3f}mm"
        ),
        limit_description=(
            f"Ring must orbit freely on bearing. "
            f"Min clearance={min_clearance:.3f}mm "
            f"{'(tight but functional)' if min_clearance > 0.05 else '(BINDING RISK!)' if min_clearance > 0 else '(INTERFERENCE!)'}. "
            f"Max clearance={max_clearance:.3f}mm "
            f"{'(rattly but functional)' if max_clearance < 0.8 else '(very loose)'}."
        ),
        verbose=verbose,
    )


def chain_channel_slider_clearance(cfg, verbose=False):
    """
    Chain 7: Channel Width (Slider Clearance)
    Two channel walls define the gap; slider plate must fit through.
    """
    wall_thickness = cfg.get("WALL_THICKNESS", 1.5)
    stack_offset = cfg.get("STACK_OFFSET", 8.0)
    ch_gap = cfg.get("CH_GAP", stack_offset - wall_thickness)

    # Slider plate thickness -- not directly in config, estimate from CH_GAP
    # Slider needs to fit through channel with clearance on both sides
    # Typical slider plate ~ CH_GAP - 2 * clearance_per_side
    # From the design: slider plate fits within the channel
    # The channel gap IS the available space
    slider_thickness_est = ch_gap - 1.0  # ~1mm total side clearance (0.5mm/side)

    tol_list = [
        (TOL_FDM_SMALL, 2),    # two channel walls
        (TOL_FDM_SMALL, 1),    # slider plate
    ]

    part_labels = [
        (f"Channel wall (x2, {wall_thickness}mm each +/-{TOL_FDM_SMALL}mm)", TOL_FDM_SMALL, 2),
        (f"Slider plate (~{slider_thickness_est:.1f}mm +/-{TOL_FDM_SMALL}mm)", TOL_FDM_SMALL, 1),
    ]

    # Nominal clearance per side
    per_side_clearance = (ch_gap - slider_thickness_est) / 2  # 0.5mm
    total_clearance = ch_gap - slider_thickness_est  # 1.0mm

    functional_limit = total_clearance  # must remain > 0 for slider to move

    return analyze_chain(
        "Chain 7: Channel Slider Clearance",
        nominal=total_clearance,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Channel gap={ch_gap:.1f}mm (stack_offset={stack_offset:.1f} - wall={wall_thickness}mm). "
            f"Slider plate ~{slider_thickness_est:.1f}mm. "
            f"Nominal clearance={total_clearance:.1f}mm ({per_side_clearance:.1f}mm/side)"
        ),
        limit_description=(
            "Slider must slide freely in channel without binding. "
            "Both walls and slider subject to FDM tolerance. "
            "If clearance goes negative, slider jams."
        ),
        verbose=verbose,
    )


def chain_collar_bump_engagement(cfg, verbose=False):
    """
    Chain 8: Collar Bump/Dimple Angular Indexing
    Bump hemisphere must engage dimple for angular locking.
    """
    bump_dia = cfg.get("COLLAR_BUMP_DIA", 1.5)
    bump_h = cfg.get("COLLAR_BUMP_H", 0.6)
    dimple_depth = cfg.get("COLLAR_DIMPLE_DEPTH", bump_h + 0.1)
    collar_thick = cfg.get("COLLAR_THICK", 3.0)

    # The bump protrudes from collar face; dimple is cut into disc face.
    # When disc + collar are pressed face-to-face, bump must enter dimple.
    # Clearance = dimple_depth - bump_h (designed as 0.1mm)
    nominal_engagement = dimple_depth - bump_h  # 0.1mm

    tol_list = [
        (TOL_FDM_SMALL, 1),    # bump height
        (TOL_FDM_SMALL, 1),    # dimple depth
    ]

    part_labels = [
        (f"Collar bump height ({bump_h}mm +/-{TOL_FDM_SMALL}mm)", TOL_FDM_SMALL, 1),
        (f"Disc dimple depth ({dimple_depth:.1f}mm +/-{TOL_FDM_SMALL}mm)", TOL_FDM_SMALL, 1),
    ]

    functional_limit = nominal_engagement

    return analyze_chain(
        "Chain 8: Collar Bump/Dimple Engagement",
        nominal=nominal_engagement,
        limit=functional_limit,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Bump protrusion={bump_h}mm, dimple depth={dimple_depth:.1f}mm. "
            f"Nominal engagement gap={nominal_engagement:.1f}mm. "
            f"Bump dia={bump_dia}mm (x{int(cfg.get('COLLAR_BUMP_COUNT', 2))} per face)"
        ),
        limit_description=(
            "Bump must click into dimple for angular registration. "
            "If bump is taller than dimple, faces won't seat flush -> axial stack grows. "
            "CA glue is the final lock; bump/dimple is alignment aid."
        ),
        verbose=verbose,
    )


def chain_shaft_total_length(cfg, verbose=False):
    """
    Chain 9: Total Shaft Length Budget
    Shaft must span: helix + carrier extensions + GT2/free extensions.
    Checks if the required length fits available stock.
    """
    helix_length = cfg.get("HELIX_LENGTH", 72.0)
    shaft_ext_to_carrier = cfg.get("SHAFT_EXT_TO_CARRIER", None)
    shaft_ext_beyond_drive = cfg.get("SHAFT_EXT_BEYOND_DRIVE", 11.0)
    shaft_ext_beyond_free = cfg.get("SHAFT_EXT_BEYOND_FREE", 7.0)
    shaft_total_cfg = cfg.get("SHAFT_TOTAL_LENGTH", None)

    # If SHAFT_EXT_TO_CARRIER wasn't resolved (complex derivation),
    # back-compute it from SHAFT_TOTAL_LENGTH if available
    if shaft_ext_to_carrier is None and shaft_total_cfg is not None:
        shaft_ext_to_carrier = (shaft_total_cfg - helix_length
                                 - shaft_ext_beyond_drive
                                 - shaft_ext_beyond_free) / 2.0
    elif shaft_ext_to_carrier is None:
        # Fallback: use a reasonable estimate
        shaft_ext_to_carrier = 30.0

    # Compute total required length
    computed_total = (helix_length
                      + shaft_ext_to_carrier * 2
                      + shaft_ext_beyond_drive
                      + shaft_ext_beyond_free)

    if shaft_total_cfg is not None:
        # Use config value if available (it is the authoritative source)
        computed_total = shaft_total_cfg

    # Standard ground rod stock comes in 100mm, 150mm, 200mm, 300mm lengths
    stock_lengths = [100, 150, 200, 300]
    best_stock = None
    for s in stock_lengths:
        if s >= computed_total + 1.0:  # need at least 1mm margin for cut
            best_stock = s
            break
    if best_stock is None:
        best_stock = 300  # longest common stock

    # Tolerance on cut length (hacksaw + deburr)
    cut_tol = 0.5  # mm

    # Each E-clip groove position has tolerance
    eclip_count = 2

    tol_list = [
        (cut_tol, 1),          # shaft cut length
        (TOL_ECLIP, eclip_count),  # E-clip groove positions
    ]

    part_labels = [
        (f"Shaft cut length (+/-{cut_tol}mm)", cut_tol, 1),
        (f"E-clip groove position (x{eclip_count}, +/-{TOL_ECLIP}mm)", TOL_ECLIP, eclip_count),
    ]

    # Functional limit: margin between stock length and required length.
    # Shaft can be up to stock length, but must be at least computed_total.
    # Cut tolerance means the actual length varies around the target.
    stock_margin = best_stock - computed_total

    return analyze_chain(
        "Chain 9: Total Shaft Length",
        nominal=computed_total,
        limit=stock_margin,
        tol_list=tol_list,
        part_labels=part_labels,
        description=(
            f"Helix={helix_length:.0f}mm + 2x ext_to_carrier={shaft_ext_to_carrier:.1f}mm "
            f"+ drive_ext={shaft_ext_beyond_drive:.1f}mm + free_ext={shaft_ext_beyond_free:.1f}mm "
            f"= {computed_total:.1f}mm required. "
            f"Best stock: {best_stock}mm rod (margin={stock_margin:.1f}mm)"
        ),
        limit_description=(
            f"Cut from {best_stock}mm stock. "
            f"Margin to stock: {stock_margin:.1f}mm. "
            f"Cut with hacksaw + file to length. "
            f"{'Order 200mm stock for extra margin.' if stock_margin < 5 else 'Adequate margin.'}"
        ),
        verbose=verbose,
    )


# ================================================================
# MAIN
# ================================================================

def print_chain_detail(result, verbose=False):
    """Print formatted output for a single chain analysis."""
    r = result
    print(f"\n{r['chain_name']}")
    print(f"  {r['description']}")
    print(f"  Parts count:      {r['total_parts']}")
    print(f"  Worst-case stack: +/-{r['worst_case']:.2f}mm")
    print(f"  RSS stack:        +/-{r['rss']:.2f}mm")
    print(f"  Functional limit: +/-{r['limit']:.2f}mm")
    print(f"  Margin (WC):      {r['margin_wc']:+.2f}mm")
    print(f"  Margin (RSS):     {r['margin_rss']:+.2f}mm")
    print(f"  Verdict:          {r['verdict']}"
          f"{' (worst-case margin positive)' if r['verdict'] == 'PASS' else ''}"
          f"{' (marginal -- consider tighter tolerances)' if r['verdict'] == 'WARN' else ''}"
          f"{' (WILL NOT ASSEMBLE under worst-case)' if r['verdict'] == 'FAIL' else ''}")

    if verbose and r['part_labels']:
        print(f"  --- Per-component breakdown ---")
        for label, tol, count in r['part_labels']:
            contribution_wc = tol * count
            contribution_rss = math.sqrt(count) * tol
            print(f"    {label}: WC={contribution_wc:+.3f}mm, RSS={contribution_rss:+.3f}mm")

    print(f"  Note: {r['limit_description']}")


def main():
    global _results
    _results = []  # reset for clean run

    parser = argparse.ArgumentParser(
        description="Tolerance Stack Analysis for Triple Helix MVP V5.5"
    )
    parser.add_argument("--verbose", action="store_true",
                        help="Show per-component breakdown for each chain")
    parser.add_argument("--config", type=str, default=None,
                        help="Path to config .scad file (default: config_v5_5.scad in script dir)")
    args = parser.parse_args()

    # Locate config
    if args.config:
        config_path = Path(args.config).resolve()
    else:
        config_path = SCRIPT_DIR / "config_v5_5.scad"

    if not config_path.is_file():
        print(f"ERROR: Config file not found: {config_path}")
        return 1

    # Load config
    cfg = load_config(config_path)
    if not cfg:
        print(f"ERROR: Could not parse any parameters from {config_path}")
        return 1

    # Banner
    print("=" * 56)
    print("TOLERANCE STACK ANALYSIS")
    print("Triple Helix MVP V5.5b")
    print("=" * 56)
    print(f"\nConfig: {config_path}")
    print(f"Parameters loaded: {len(cfg)}")

    # Print key config values used
    key_params = [
        "HEX_R", "SHAFT_DIA", "DISC_THICK", "COLLAR_THICK",
        "AXIAL_PITCH", "HELIX_LENGTH", "NUM_CAMS",
        "CAM_BRG_ID", "CAM_BRG_OD", "FRAME_BRG_ID", "FRAME_BRG_OD",
        "SLEEVE_CLEARANCE", "WALL_THICKNESS", "STACK_OFFSET", "CH_GAP",
    ]
    print("\nKey parameters:")
    for p in key_params:
        if p in cfg:
            print(f"  {p} = {cfg[p]}")

    print(f"\nTolerance assumptions:")
    print(f"  FDM small (<10mm):    +/-{TOL_FDM_SMALL}mm")
    print(f"  FDM medium (10-50mm): +/-{TOL_FDM_MEDIUM}mm")
    print(f"  FDM large (>50mm):    +/-{TOL_FDM_LARGE}mm")
    print(f"  Ground rod:           +/-{TOL_GROUND_ROD}mm")
    print(f"  Bearing (ABEC-1):     +/-{TOL_BEARING}mm")
    print(f"  E-clip groove:        +/-{TOL_ECLIP}mm")

    # Run all chains
    chains = [
        chain_axial_disc_stack,
        chain_matrix_in_frame,
        chain_bearing_bore_fit,
        chain_cam_disc_on_shaft,
        chain_guide_plate_in_ring,
        chain_follower_ring_on_cam_bearing,
        chain_channel_slider_clearance,
        chain_collar_bump_engagement,
        chain_shaft_total_length,
    ]

    results = []
    for chain_fn in chains:
        result = chain_fn(cfg, verbose=args.verbose)
        if result is not None:
            results.append(result)

    # Print detailed results
    for r in results:
        print_chain_detail(r, verbose=args.verbose)

    # Summary
    passes = sum(1 for s, _, _ in _results if s == "PASS")
    warns = sum(1 for s, _, _ in _results if s == "WARN")
    fails = sum(1 for s, _, _ in _results if s == "FAIL")

    print("\n" + "=" * 56)
    print(f"SUMMARY: {passes} PASS / {warns} WARN / {fails} FAIL")
    print("=" * 56)

    # Recommendations
    recommendations = []

    for r in results:
        if r["verdict"] == "FAIL":
            recommendations.append(
                f"CRITICAL -- {r['chain_name']}: Redesign required. "
                f"Margin={r['margin_wc']:+.2f}mm"
            )
        elif r["verdict"] == "WARN":
            recommendations.append(
                f"CAUTION -- {r['chain_name']}: Print test fit before committing. "
                f"Margin={r['margin_wc']:+.2f}mm"
            )

    # Standard recommendations based on common failure modes
    if any("Bearing Bore" in r["chain_name"] for r in results):
        recommendations.append(
            "Chain 3 (bearing bore): Consider reaming printed bores to +0.05mm "
            "for consistent press fit"
        )
    if any("Axial Disc" in r["chain_name"] for r in results):
        recommendations.append(
            "Chain 1 (disc stack): Print test stack of 3 discs + 3 collars to validate "
            "axial pitch before printing all 18"
        )
    if any("Guide Plate" in r["chain_name"] and r["verdict"] != "PASS" for r in results):
        recommendations.append(
            "Chain 5 (guide plate): Increase SLEEVE_CLEARANCE to 0.3mm if "
            "plate does not slide into ring easily"
        )
    if any("Bump" in r["chain_name"] for r in results):
        recommendations.append(
            "Chain 8 (collar indexing): Bump/dimple is an alignment aid, not a lock. "
            "CA glue is the real retention -- bumps can be sanded down if oversized"
        )

    if recommendations:
        print("\nRECOMMENDATIONS:")
        for rec in recommendations:
            print(f"  - {rec}")

    print()
    return 1 if fails > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
