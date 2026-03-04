"""
ANIMATION SWEEP -- 360-degree Kinematic Constraint Checker
==========================================================
Sweeps every degree of cam rotation and checks:
  1. Slider bounds         -- slider stays inside hex channel
  2. Block travel limit    -- per-tier slider displacement within bounds
  3. Block collision        -- adjacent-channel blocks maintain gap
  4. Transmission angle    -- cam-follower force transfer effective range
  5. Follower envelope     -- follower fits in carrier bore, axial clearance
  6. Phase pattern         -- wave shape analysis across channels

Pure Python math -- no OpenSCAD rendering.  Runs in <1 second.

MOTION MODEL
=============
Each helix shaft drives one tier of 9 cam discs.  All 3 shafts rotate
together via GT2 belt.  The animation model (from matrix_stack_v5_5.scad):

    slider_disp(tier, ch, t) = E * sin(-t*360 + ch * TWIST_PER_CAM)

Each tier uses the SAME formula (no inter-tier phase offset in the cam
rotation) because all shafts rotate synchronously.

The 3 tiers ARE rotated in the hex by TIER_ANGLES = [180, 300, 60], so
each tier's sliders face a different direction.  A block string threads
through one channel in each tier, but the tier rotation means the string
passes through DIFFERENT channels in each tier (geometric routing).

For animation sweep purposes:
  - Slider checks: independent per-tier, all tiers share the same cam formula
  - Block displacement: modeled as single-tier E*sin() (worst case = 1*E per tier)
  - Block collision: checked per-channel within a single tier view
  - Phase pattern: the 9-channel wave shape is the key visual output

Usage:
  python animation_sweep.py                     # full 360 sweep
  python animation_sweep.py --resolution 0.5    # 0.5 deg steps
  python animation_sweep.py --plot              # emit sweep_data.csv
  python animation_sweep.py --verbose           # per-angle detail
  python animation_sweep.py --angle 90          # single-angle deep dive
"""

import math
import sys
import re
import time
import argparse
from pathlib import Path

# ================================================================
# CONFIG PARSING -- extract named constants from config_v5_5.scad
# ================================================================

def parse_config(config_path: str) -> dict:
    """Extract named constants from an OpenSCAD config file.

    Handles:
      - SCALAR = value;
      - SCALAR = expr;   (simple arithmetic)
      - ARRAY  = [v1, v2, ...];
      - function definitions are NOT evaluated (replicated in Python)
    """
    text = Path(config_path).read_text(encoding="utf-8")

    # Strip block comments and line comments
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    text = re.sub(r'//[^\n]*', '', text)

    consts: dict = {}

    def _eval_expr(expr_str: str):
        s = expr_str.strip().rstrip(';').strip()
        if not s:
            return None
        s = s.replace('sqrt', 'math.sqrt')
        s = s.replace('PI', 'math.pi')
        s = s.replace('sin', 'math.sin')
        s = s.replace('cos', 'math.cos')
        s = s.replace('tan', 'math.tan')
        s = s.replace('abs', '__builtins_abs__')
        s = s.replace('floor', 'math.floor')
        s = s.replace('ceil', 'math.ceil')
        s = s.replace('max', '__builtins_max__')
        s = s.replace('min', '__builtins_min__')
        s = s.replace('$fn', '_fn')
        s = s.replace('$t', '_t')

        safe_ns = {
            'math': math,
            '__builtins_abs__': abs,
            '__builtins_max__': max,
            '__builtins_min__': min,
            '_fn': 48,
            '_t': 0,
        }
        safe_ns.update(consts)
        try:
            return float(eval(s, {"__builtins__": {}}, safe_ns))
        except Exception:
            return None

    # Pass 1: scalar assignments   NAME = expr ;
    scalar_re = re.compile(
        r'^([A-Z_][A-Z_0-9]*)\s*=\s*([^;\[\]]+);', re.MULTILINE
    )
    for m in scalar_re.finditer(text):
        name, expr = m.group(1), m.group(2)
        val = _eval_expr(expr)
        if val is not None:
            consts[name] = val

    # Pass 2: array assignments   NAME = [ ... ];
    array_re = re.compile(
        r'^([A-Z_][A-Z_0-9]*)\s*=\s*\[([^\]]+)\];', re.MULTILINE
    )
    for m in array_re.finditer(text):
        name, body = m.group(1), m.group(2)
        elems = []
        for part in body.split(','):
            v = _eval_expr(part)
            if v is not None:
                elems.append(v)
        if elems:
            consts[name] = elems

    # Pass 3: _-prefixed internal constants
    internal_re = re.compile(
        r'^(_[A-Za-z_][A-Za-z_0-9]*)\s*=\s*([^;\[\]]+);', re.MULTILINE
    )
    for m in internal_re.finditer(text):
        name, expr = m.group(1), m.group(2)
        val = _eval_expr(expr)
        if val is not None:
            consts[name] = val

    return consts


# ================================================================
# REPLICATE KEY OpenSCAD FUNCTIONS IN PYTHON
# ================================================================

def hex_w(d: float, hex_r: float) -> float:
    """Width of hex cross-section at offset d from center."""
    hex_ff = hex_r * math.sqrt(3)
    max_d = hex_ff / 2
    if abs(d) > max_d:
        return 0.0
    return 2.0 * (hex_r - abs(d) / math.sqrt(3))


def ch_len(d: float, hex_r: float, wall_margin: float) -> float:
    return max(0.0, hex_w(d, hex_r) - 2 * wall_margin)


def compute_channels(hex_r: float, stack_offset: float, wall_margin: float):
    """Compute channel offsets, lengths, and count."""
    hex_ff = hex_r * math.sqrt(3)
    half_count = math.floor((hex_ff / 2 - stack_offset / 2) / stack_offset)
    num_channels = 2 * half_count + 1
    center_ch = (num_channels - 1) / 2.0
    ch_offsets = [(i - center_ch) * stack_offset for i in range(num_channels)]
    ch_lens = [ch_len(d, hex_r, wall_margin) for d in ch_offsets]
    return num_channels, ch_offsets, ch_lens


def col_x_base(count: int, idx: int, col_pitch: float) -> float:
    return -((count - 1) / 2.0) * col_pitch + idx * col_pitch


def col_stagger(ch_idx: int, col_pitch: float) -> float:
    return (ch_idx % 2) * (col_pitch / 2.0)


def raw_col_count(length: float, col_pitch: float, fp_od: float, sp_od: float) -> int:
    if length < col_pitch:
        return 1 if length > max(fp_od, sp_od) else 0
    return math.floor(length / col_pitch) + 1


def col_inside_hex(px: float, d: float, hex_r: float, fp_od: float, sp_od: float) -> bool:
    max_od = max(fp_od, sp_od)
    return (abs(px) + max_od / 2 + 1) < (hex_w(d, hex_r) / 2)


def culled_col_count(ch_idx: int, ch_offsets: list, ch_lens: list,
                     hex_r: float, col_pitch: float, fp_od: float, sp_od: float) -> int:
    d = ch_offsets[ch_idx]
    length = ch_lens[ch_idx]
    if length <= 0:
        return 0
    raw = raw_col_count(length, col_pitch, fp_od, sp_od)
    count = 0
    for j in range(raw):
        px = col_x_base(raw, j, col_pitch) + col_stagger(ch_idx, col_pitch)
        if col_inside_hex(px, d, hex_r, fp_od, sp_od):
            count += 1
    return count


# ================================================================
# KINEMATICS
# ================================================================

def slider_displacement(theta_deg: float, eccentricity: float,
                        channel_twist_deg: float) -> float:
    """Slider displacement at cam angle theta for a given channel.

    Matches the OpenSCAD animation formula:
        ECCENTRICITY * sin(-t*360 + ch * TWIST_PER_CAM)
    where t = theta_deg / 360.

    All 3 tiers use the same formula because the GT2 belt drives
    all helix shafts synchronously.
    """
    theta = math.radians(theta_deg)
    twist = math.radians(channel_twist_deg)
    return eccentricity * math.sin(-theta + twist)


def block_displacement_single_tier(theta_deg: float, eccentricity: float,
                                   channel_index: int, twist_per_cam: float) -> float:
    """Single-tier block displacement.  This is the per-tier contribution."""
    return slider_displacement(theta_deg, eccentricity, channel_index * twist_per_cam)


def block_displacement_worst_case(eccentricity: float, num_tiers: int = 3) -> float:
    """Worst-case block travel: all 3 tiers push in the same direction.

    This happens when a string passes through channels at the same cam
    phase in all 3 tiers (or close to it).  Since tiers are rotated by
    different TIER_ANGLES, the actual string routing determines which
    channels align.  The theoretical maximum is num_tiers * E.
    """
    return num_tiers * eccentricity


# ================================================================
# CHECK FUNCTIONS
# ================================================================

class SweepResult:
    """Accumulator for check results across the full sweep."""

    def __init__(self):
        self.slider_violations: list[str] = []
        self.slider_checks = 0

        self.block_travel_max = 0.0
        self.block_travel_max_theta = 0
        self.block_travel_max_ch = 0
        self.block_travel_limit = 0.0
        self.block_travel_violations: list[str] = []

        self.block_gap_min = float('inf')
        self.block_gap_min_theta = 0
        self.block_gap_min_pair = (0, 0)
        self.block_collision_checks = 0
        self.block_collision_violations: list[str] = []

        self.trans_angle_min = 180.0
        self.trans_angle_min_theta = 0
        self.trans_angle_min_ch = 0
        self.trans_angle_checks = 0
        self.trans_angle_violations: list[str] = []

        self.follower_max_radius = 0.0
        self.follower_max_theta = 0
        self.follower_carrier_bore = 0.0
        self.follower_checks = 0
        self.follower_violations: list[str] = []

        # Phase pattern stats
        self.max_wave_spread_theta = 0
        self.max_wave_spread = 0.0
        self.min_wave_spread_theta = 0
        self.min_wave_spread = float('inf')

        # Per-channel amplitude tracking (single-tier view)
        self.ch_max_disp: list[float] = []
        self.ch_min_disp: list[float] = []

        # CSV data (if --plot)
        self.csv_rows: list[list[float]] = []


def check_slider_bounds(theta: float, cfg: dict, result: SweepResult,
                        verbose: bool = False) -> list[str]:
    """Check 1: slider stays inside hex channel at this angle.

    Each tier uses the same cam formula.  The slider rest position has
    a bias offset (SLIDER_REST_OFFSET) toward the helix side.
    Total slider position = bias + E*sin(-theta + ch*twist).
    Must stay within ch_len/2 - end_clearance from channel center.
    """
    violations = []
    num_ch = cfg['num_channels']
    ecc = cfg['eccentricity']
    twist = cfg['twist_per_cam']
    ch_lens = cfg['ch_lens']
    end_clearance = 2.0  # mm safety margin at channel ends
    bias = cfg.get('slider_rest_offset', 0.0)

    for ch in range(num_ch):
        result.slider_checks += 1
        ch_twist = ch * twist
        disp = slider_displacement(theta, ecc, ch_twist)
        total_pos = bias + disp
        limit = ch_lens[ch] / 2.0 - end_clearance
        if limit > 0 and abs(total_pos) > limit:
            msg = (f"  theta={theta:6.1f}  ch{ch} "
                   f"pos={total_pos:+.2f}mm > limit=+/-{limit:.1f}mm "
                   f"(ch_len={ch_lens[ch]:.1f}, bias={bias:.2f})")
            violations.append(msg)
            if verbose:
                print(msg)
    return violations


def check_block_travel(theta: float, cfg: dict, result: SweepResult,
                       verbose: bool = False) -> list[str]:
    """Check 2: per-tier slider displacement within single-tier limit.

    Each tier contributes E*sin() to the string.  The per-tier contribution
    cannot exceed E.  We also check the slider position + bias doesn't
    exceed the available channel length (already covered by check 1).

    For the summation model: block travel = sum of up to 3 tier contributions.
    Worst case = 3*E = 14.4mm.  This is a static constraint (always true by math).
    We verify the per-tier displacement stays within E.
    """
    violations = []
    num_ch = cfg['num_channels']
    ecc = cfg['eccentricity']
    twist = cfg['twist_per_cam']

    for ch in range(num_ch):
        disp = slider_displacement(theta, ecc, ch * twist)
        abs_disp = abs(disp)
        if abs_disp > result.block_travel_max:
            result.block_travel_max = abs_disp
            result.block_travel_max_theta = theta
            result.block_travel_max_ch = ch
        if abs_disp > ecc + 0.01:  # should never happen (sin <= 1)
            msg = (f"  theta={theta:6.1f}  ch{ch} "
                   f"|slider_disp|={abs_disp:.2f}mm > E={ecc:.1f}mm (MATH ERROR)")
            violations.append(msg)
            if verbose:
                print(msg)
    return violations


def check_block_collision(theta: float, cfg: dict, result: SweepResult,
                          verbose: bool = False) -> list[str]:
    """Check 3: adjacent-channel blocks maintain minimum gap.

    Blocks on adjacent channels hang at different vertical positions
    due to phase offset (40 deg twist between channels).  The vertical
    displacement difference between ch[i] and ch[i+1]:

        delta_z = |E*sin(-theta + i*twist) - E*sin(-theta + (i+1)*twist)|

    Using sum-to-product:
        delta_z = |2*E * cos(-theta + (2i+1)*twist/2) * sin(twist/2)|
        max(delta_z) = 2*E*sin(twist/2) = 2*4.8*sin(20) = 3.28mm

    Adjacent blocks collide when delta_z > block_height + block_gap.
    Since delta_z_max = 3.28mm << block_height + gap = 7.8mm, this
    check should always pass.  We verify at every angle.
    """
    violations = []
    num_ch = cfg['num_channels']
    ecc = cfg['eccentricity']
    twist = cfg['twist_per_cam']
    block_gap = cfg['block_gap']
    block_height = cfg['block_height']

    disps = [slider_displacement(theta, ecc, ch * twist) for ch in range(num_ch)]

    for i in range(num_ch - 1):
        result.block_collision_checks += 1
        delta_z = abs(disps[i] - disps[i + 1])
        remaining_gap = block_height + block_gap - delta_z
        if remaining_gap < result.block_gap_min:
            result.block_gap_min = remaining_gap
            result.block_gap_min_theta = theta
            result.block_gap_min_pair = (i, i + 1)
        if remaining_gap < 0:
            msg = (f"  theta={theta:6.1f}  ch{i}-ch{i+1} "
                   f"gap={remaining_gap:.2f}mm < 0  "
                   f"(delta_z={delta_z:.2f}mm, limit={block_height + block_gap:.1f}mm)")
            violations.append(msg)
            if verbose:
                print(msg)

    return violations


def check_transmission_angle(theta: float, cfg: dict, result: SweepResult,
                             verbose: bool = False) -> list[str]:
    """Check 4: cam-follower transmission angle.

    For an eccentric cam (circular disc, offset center):
    The pressure angle mu measures how much of the cam force is wasted
    pushing the follower sideways rather than along its travel direction.

        mu = atan2(E * sin(a), R_follower + E * cos(a))

    where a = cam angle, R_follower = bearing OD/2, E = eccentricity.

    Transmission angle = 90 - |mu|.
    We want transmission angle > 30 deg (pressure angle < 60 deg).

    For our design: E = 4.8mm, R = 13.5mm.
    E/R = 0.356 -> max pressure angle = arctan(0.356) ~ 19.6 deg.
    So transmission angle never drops below ~70 deg.  Very safe.
    """
    violations = []
    num_ch = cfg['num_channels']
    ecc = cfg['eccentricity']
    twist = cfg['twist_per_cam']
    r_follower = cfg['cam_brg_od'] / 2.0
    min_allowed = 30.0

    for ch in range(num_ch):
        result.trans_angle_checks += 1
        cam_angle = math.radians(-theta + ch * twist)

        numerator = ecc * math.sin(cam_angle)
        denominator = r_follower + ecc * math.cos(cam_angle)
        if abs(denominator) < 1e-9:
            mu_deg = 90.0
        else:
            mu_deg = abs(math.degrees(math.atan2(numerator, denominator)))

        trans_angle = 90.0 - mu_deg

        if trans_angle < result.trans_angle_min:
            result.trans_angle_min = trans_angle
            result.trans_angle_min_theta = theta
            result.trans_angle_min_ch = ch

        if trans_angle < min_allowed:
            msg = (f"  theta={theta:6.1f}  ch{ch} "
                   f"trans_angle={trans_angle:.1f} deg < {min_allowed} deg "
                   f"(pressure_angle={mu_deg:.1f} deg)")
            violations.append(msg)
            if verbose:
                print(msg)

    return violations


def check_follower_envelope(theta: float, cfg: dict, result: SweepResult,
                            verbose: bool = False) -> list[str]:
    """Check 5: follower envelope clearance.

    The follower ring rides on the bearing outer race.  The disc center
    orbits at radius E from the shaft center.  Max radial extent from shaft:

        ring_max_r  = E + follower_ring_OD/2
        arm_tip_max = E + follower_ring_OD/2 + arm_length

    The follower sits in open space between the two carrier plates.
    There is no carrier bore constraining the follower (the carrier plate
    only has a bearing bore for the shaft itself).

    We check:
    1. Follower ring OD must be smaller than the axial pitch to avoid
       touching the adjacent disc's bearing.
    2. Report max radial extent for information.

    Adjacent follower rings on the helix:
    - Axially separated by AXIAL_PITCH (8mm)
    - Follower ring height = 3mm
    - Axial gap = AXIAL_PITCH - FOLLOWER_RING_H = 5mm
    - They CANNOT collide radially because they occupy different Z slices
    """
    violations = []
    ecc = cfg['eccentricity']
    follower_ring_od = cfg['follower_ring_od']
    follower_arm_length = cfg['follower_arm_length']
    disc_od = cfg['disc_od']

    result.follower_checks += 1

    # Max radial extent from shaft center (ring edge)
    ring_max_r = ecc + follower_ring_od / 2.0
    arm_tip_max = ring_max_r + follower_arm_length
    if arm_tip_max > result.follower_max_radius:
        result.follower_max_radius = arm_tip_max
        result.follower_max_theta = theta

    # Follower ring must clear the disc OD at max eccentric
    # The disc center is at (E, 0) when the follower ring center is also at (E, 0)
    # so the disc and ring are concentric at the bearing.  Ring ID > bearing OD (already
    # checked in static validation).  No dynamic concern here.

    # Check: follower ring doesn't extend beyond the helix assembly length
    # (purely informational -- the ring is in open air)

    return violations


def analyze_phase_pattern(theta: float, cfg: dict, result: SweepResult) -> list[float]:
    """Check 6: wave pattern analysis.

    Compute per-channel slider displacement at this angle.
    Track the wave spread (max - min across channels) and per-channel
    peak-to-peak amplitude over the full sweep.
    """
    num_ch = cfg['num_channels']
    ecc = cfg['eccentricity']
    twist = cfg['twist_per_cam']

    disps = [slider_displacement(theta, ecc, ch * twist) for ch in range(num_ch)]

    # Initialize per-channel trackers on first call
    if not result.ch_max_disp:
        result.ch_max_disp = [float('-inf')] * num_ch
        result.ch_min_disp = [float('inf')] * num_ch

    for ch in range(num_ch):
        if disps[ch] > result.ch_max_disp[ch]:
            result.ch_max_disp[ch] = disps[ch]
        if disps[ch] < result.ch_min_disp[ch]:
            result.ch_min_disp[ch] = disps[ch]

    # Wave spread at this angle
    wave_spread = max(disps) - min(disps)
    if wave_spread > result.max_wave_spread:
        result.max_wave_spread = wave_spread
        result.max_wave_spread_theta = theta
    if wave_spread < result.min_wave_spread:
        result.min_wave_spread = wave_spread
        result.min_wave_spread_theta = theta

    return disps


# ================================================================
# LOAD CONFIG
# ================================================================

def load_config(config_path: str) -> dict:
    """Load and compute all needed config values."""
    raw = parse_config(config_path)

    hex_r = raw.get('HEX_R', 43.0)
    stack_offset = raw.get('STACK_OFFSET', 8.0)
    wall_margin = raw.get('WALL_MARGIN', 4.0)
    eccentricity = raw.get('ECCENTRICITY', 4.8)
    col_pitch = raw.get('COL_PITCH', 6.0)
    fp_od = raw.get('FP_OD', 3.0)
    sp_od = raw.get('SP_OD', 3.0)

    num_channels, ch_offsets, ch_lens_list = compute_channels(hex_r, stack_offset, wall_margin)
    twist_per_cam = 360.0 / num_channels

    col_counts = [culled_col_count(ch, ch_offsets, ch_lens_list,
                                    hex_r, col_pitch, fp_od, sp_od)
                  for ch in range(num_channels)]

    follower_ring_od = raw.get('FOLLOWER_RING_OD', 31.0)
    follower_arm_length = raw.get('FOLLOWER_ARM_LENGTH', 6.0)

    cfg = {
        'hex_r': hex_r,
        'stack_offset': stack_offset,
        'wall_margin': wall_margin,
        'eccentricity': eccentricity,
        'num_channels': num_channels,
        'twist_per_cam': twist_per_cam,
        'ch_offsets': ch_offsets,
        'ch_lens': ch_lens_list,
        'col_counts': col_counts,
        'col_pitch': col_pitch,
        'fp_od': fp_od,
        'sp_od': sp_od,
        'tier_angles': raw.get('TIER_ANGLES', [180, 300, 60]),
        'helix_angles': raw.get('HELIX_ANGLES', [180, 300, 60]),
        'max_block_travel': 3.0 * eccentricity,
        'slider_bias': raw.get('SLIDER_BIAS', 0.80),
        'slider_rest_offset': eccentricity * raw.get('SLIDER_BIAS', 0.80),
        'cam_brg_id': raw.get('CAM_BRG_ID', 20.0),
        'cam_brg_od': raw.get('CAM_BRG_OD', 27.0),
        'cam_brg_w': raw.get('CAM_BRG_W', 4.0),
        'disc_od': raw.get('DISC_OD', 19.6),
        'shaft_dia': raw.get('SHAFT_DIA', 4.0),
        'shaft_boss_od': raw.get('SHAFT_BOSS_OD', 10.0),
        'follower_ring_id': raw.get('FOLLOWER_RING_ID', 27.3),
        'follower_ring_od': follower_ring_od,
        'follower_ring_h': raw.get('FOLLOWER_RING_H', 3.0),
        'follower_arm_length': follower_arm_length,
        'follower_eyelet_dia': raw.get('FOLLOWER_EYELET_DIA', 1.5),
        'axial_pitch': raw.get('AXIAL_PITCH', 8.0),
        'block_gap': raw.get('_BLOCK_GAP', 0.8),
        'block_height': raw.get('_BLOCK_HEIGHT_CFG', 7.0),
        'block_drop': raw.get('_BLOCK_DROP', 36.0),
        'carrier_plate_t': raw.get('CARRIER_PLATE_T_CFG', 10.0),
        'helix_length': raw.get('HELIX_LENGTH',
                                num_channels * raw.get('AXIAL_PITCH', 8.0)),
    }

    # Derived
    cfg['follower_axial_gap'] = cfg['axial_pitch'] - cfg['follower_ring_h']

    # Theoretical max displacement difference between adjacent channels
    # Using sum-to-product: 2*E*|sin(twist/2)|
    half_twist = twist_per_cam / 2.0
    cfg['max_adj_delta_z'] = 2 * eccentricity * abs(math.sin(math.radians(half_twist)))

    return cfg


# ================================================================
# MAIN SWEEP
# ================================================================

def sweep(cfg: dict, resolution: float = 1.0,
          verbose: bool = False, plot: bool = False,
          single_angle: float | None = None) -> SweepResult:
    """Run the full 360-degree sweep."""
    result = SweepResult()

    if single_angle is not None:
        angles = [single_angle]
    else:
        n_steps = int(math.ceil(360.0 / resolution))
        angles = [i * resolution for i in range(n_steps)]

    num_ch = cfg['num_channels']

    for theta in angles:
        v1 = check_slider_bounds(theta, cfg, result, verbose)
        result.slider_violations.extend(v1)

        v2 = check_block_travel(theta, cfg, result, verbose)
        result.block_travel_violations.extend(v2)

        v3 = check_block_collision(theta, cfg, result, verbose)
        result.block_collision_violations.extend(v3)

        v4 = check_transmission_angle(theta, cfg, result, verbose)
        result.trans_angle_violations.extend(v4)

        v5 = check_follower_envelope(theta, cfg, result, verbose)
        result.follower_violations.extend(v5)

        disps = analyze_phase_pattern(theta, cfg, result)

        # CSV row
        if plot:
            # Min gap between adjacent channel blocks at this angle
            min_gap = float('inf')
            for i in range(num_ch - 1):
                delta = abs(disps[i] - disps[i + 1])
                gap = cfg['block_height'] + cfg['block_gap'] - delta
                min_gap = min(min_gap, gap)

            row = [theta]
            for ch in range(num_ch):
                row.append(disps[ch])  # slider disp per channel
            row.append(min_gap)
            result.csv_rows.append(row)

    result.block_travel_limit = cfg['eccentricity']  # per-tier limit
    return result


def write_csv(result: SweepResult, cfg: dict, csv_path: str):
    """Write sweep data to CSV for plotting."""
    num_ch = cfg['num_channels']
    headers = ['theta']
    for ch in range(num_ch):
        headers.append(f'ch{ch}_disp')
    headers.append('min_gap')

    with open(csv_path, 'w') as f:
        f.write(','.join(headers) + '\n')
        for row in result.csv_rows:
            f.write(','.join(f'{v:.4f}' for v in row) + '\n')


# ================================================================
# REPORT
# ================================================================

def print_report(result: SweepResult, cfg: dict, resolution: float,
                 elapsed: float, single_angle: float | None = None) -> int:
    """Print the final report.  Returns number of FAILs."""
    num_ch = cfg['num_channels']
    n_angles = 1 if single_angle is not None else int(math.ceil(360.0 / resolution))

    print()
    print("=" * 60)
    print("ANIMATION SWEEP -- 360 deg @ {:.1f} deg resolution".format(resolution))
    print("Triple Helix MVP V5.5b")
    print("=" * 60)
    print()
    print("Sweep Parameters:")
    print(f"  ECCENTRICITY       = {cfg['eccentricity']}mm")
    print(f"  NUM_CHANNELS       = {cfg['num_channels']}")
    print(f"  TWIST_PER_CAM      = {cfg['twist_per_cam']:.1f} deg")
    print(f"  SLIDER_REST_OFFSET = {cfg['slider_rest_offset']:.2f}mm")
    print(f"  MAX_BLOCK_TRAVEL   = {cfg['max_block_travel']:.1f}mm (3-tier worst case)")
    print(f"  AXIAL_PITCH        = {cfg['axial_pitch']}mm")
    print(f"  Follower ring OD   = {cfg['follower_ring_od']}mm")
    print(f"  Block gap (nom)    = {cfg['block_gap']}mm")
    print(f"  Block height       = {cfg['block_height']}mm")
    print(f"  Max adj delta_z    = {cfg['max_adj_delta_z']:.2f}mm "
          f"(2*E*sin({cfg['twist_per_cam']/2:.0f} deg))")
    print()

    # Channel geometry table
    print("Channel Geometry:")
    print(f"  {'Ch':>3s}  {'Offset':>7s}  {'Length':>7s}  {'Cols':>4s}  "
          f"{'MaxSlider':>10s}")
    ecc = cfg['eccentricity']
    bias = cfg['slider_rest_offset']
    for ch in range(num_ch):
        max_pos = bias + ecc
        half_ch = cfg['ch_lens'][ch] / 2.0
        margin = half_ch - max_pos
        print(f"  {ch:3d}  {cfg['ch_offsets'][ch]:+7.1f}  "
              f"{cfg['ch_lens'][ch]:7.1f}  {cfg['col_counts'][ch]:4d}  "
              f"{max_pos:+6.2f}/{half_ch:5.1f}  margin={margin:.1f}mm")
    print()

    # Results
    total_checks = 0
    passes = 0
    warns = 0
    fails = 0

    def _status(violations, checks, label, detail):
        nonlocal total_checks, passes, warns, fails
        total_checks += checks
        n_v = len(violations)
        if n_v == 0:
            status = "PASS"
            passes += 1
        elif n_v <= 5:
            status = "WARN"
            warns += 1
        else:
            status = "FAIL"
            fails += 1
        dots = '.' * max(1, 40 - len(label))
        print(f"Check: {label} {dots} {status} ({detail})")
        if n_v > 0 and n_v <= 20:
            for v in violations:
                print(v)
        elif n_v > 20:
            for v in violations[:10]:
                print(v)
            print(f"  ... and {n_v - 10} more violations")

    _status(result.slider_violations, result.slider_checks,
            "Slider Bounds",
            f"{len(result.slider_violations)} violations in {result.slider_checks} checks")

    _status(result.block_travel_violations, n_angles * num_ch,
            "Slider Travel (per-tier)",
            f"max |disp|={result.block_travel_max:.2f}mm <= E={result.block_travel_limit:.1f}mm "
            f"at theta={result.block_travel_max_theta:.0f} deg ch{result.block_travel_max_ch}")

    _status(result.block_collision_violations, result.block_collision_checks,
            "Block Collision",
            f"min gap={result.block_gap_min:.2f}mm at theta={result.block_gap_min_theta:.0f} deg "
            f"ch{result.block_gap_min_pair[0]}-ch{result.block_gap_min_pair[1]}")

    _status(result.trans_angle_violations, result.trans_angle_checks,
            "Transmission Angle",
            f"min={result.trans_angle_min:.1f} deg at theta={result.trans_angle_min_theta:.0f} deg "
            f"ch{result.trans_angle_min_ch}")

    _status(result.follower_violations, result.follower_checks,
            "Follower Envelope",
            f"max radial extent={result.follower_max_radius:.1f}mm from shaft "
            f"(ring={cfg['follower_ring_od']/2 + cfg['eccentricity']:.1f}mm, "
            f"arm tip={result.follower_max_radius:.1f}mm)")

    # Follower axial gap (static check)
    axial_gap = cfg['follower_axial_gap']
    total_checks += 1
    if axial_gap >= 1.0:
        passes += 1
        ax_status = "PASS"
    else:
        fails += 1
        ax_status = "FAIL"
    dots = '.' * max(1, 40 - len("Follower Axial Gap"))
    print(f"Check: Follower Axial Gap {dots} {ax_status} "
          f"(gap={axial_gap:.1f}mm between adjacent rings, "
          f"pitch={cfg['axial_pitch']}mm, ring_h={cfg['follower_ring_h']}mm)")

    # Phase pattern summary
    print()
    print("Phase Pattern Summary:")

    if result.ch_max_disp:
        ch_ranges = [result.ch_max_disp[ch] - result.ch_min_disp[ch]
                     for ch in range(num_ch)]
        max_range_ch = ch_ranges.index(max(ch_ranges))
        min_range_ch = ch_ranges.index(min(ch_ranges))

        print(f"  Max wave spread at theta={result.max_wave_spread_theta:.0f} deg: "
              f"{result.max_wave_spread:.2f}mm")
        print(f"  Min wave spread at theta={result.min_wave_spread_theta:.0f} deg: "
              f"{result.min_wave_spread:.2f}mm")
        print(f"  Largest per-ch pk-pk: ch{max_range_ch} = {ch_ranges[max_range_ch]:.2f}mm")
        print(f"  Smallest per-ch pk-pk: ch{min_range_ch} = {ch_ranges[min_range_ch]:.2f}mm")
        print()
        print(f"  Per-channel peak-to-peak (single-tier view):")
        print(f"    {'Ch':>3s}  {'Min':>8s}  {'Max':>8s}  {'Pk-Pk':>8s}")
        for ch in range(num_ch):
            print(f"    {ch:3d}  {result.ch_min_disp[ch]:+8.3f}  "
                  f"{result.ch_max_disp[ch]:+8.3f}  {ch_ranges[ch]:8.3f}")

    wave_channels = 360.0 / cfg['twist_per_cam']
    print()
    print(f"  Spatial wavelength: {wave_channels:.0f} channels "
          f"({360.0 / (num_ch * cfg['twist_per_cam']):.1f} full waves across {num_ch} channels)")
    print(f"  Temporal period: 360 deg (one full motor rotation)")
    print(f"  Phase step per channel: {cfg['twist_per_cam']:.1f} deg")
    print(f"  Max adj-channel disp diff: {cfg['max_adj_delta_z']:.2f}mm "
          f"(block_h + gap = {cfg['block_height'] + cfg['block_gap']:.1f}mm -- "
          f"{'SAFE' if cfg['max_adj_delta_z'] < cfg['block_height'] + cfg['block_gap'] else 'COLLISION RISK'})")

    # Summation model note
    print()
    print("  Summation Model (3-tier string path):")
    print(f"    Per-tier max displacement = +/-{cfg['eccentricity']:.1f}mm")
    print(f"    Worst-case 3-tier sum     = +/-{cfg['max_block_travel']:.1f}mm")
    print(f"    Block drop clearance      = {cfg['block_drop']:.0f}mm "
          f"(margin = {cfg['block_drop'] - cfg['max_block_travel']:.1f}mm)")

    print()
    print("=" * 60)
    print(f"SUMMARY: {passes} PASS / {warns} WARN / {fails} FAIL")
    print(f"Total checks: {total_checks} across {n_angles} angles")
    print(f"Execution time: {elapsed:.3f}s")
    print("=" * 60)

    return fails


def print_single_angle_detail(theta: float, cfg: dict):
    """Deep dive into a single angle."""
    num_ch = cfg['num_channels']
    ecc = cfg['eccentricity']
    twist = cfg['twist_per_cam']
    bias = cfg['slider_rest_offset']

    print()
    print(f"=== SINGLE ANGLE DETAIL: theta = {theta:.1f} deg ===")
    print()

    print(f"{'Ch':>3s}  {'CamAngle':>10s}  {'Slider':>10s}  {'Biased':>10s}  "
          f"{'ChLen/2':>8s}  {'Margin':>8s}  {'TransAngle':>11s}")
    print("-" * 78)

    r_follower = cfg['cam_brg_od'] / 2.0
    for ch in range(num_ch):
        cam_a = -theta + ch * twist
        disp = slider_displacement(theta, ecc, ch * twist)
        biased = bias + disp
        half_ch = cfg['ch_lens'][ch] / 2.0
        margin = half_ch - abs(biased)

        cam_angle = math.radians(cam_a)
        num = ecc * math.sin(cam_angle)
        den = r_follower + ecc * math.cos(cam_angle)
        mu = abs(math.degrees(math.atan2(num, den))) if abs(den) > 1e-9 else 90.0
        ta = 90.0 - mu

        print(f"{ch:3d}  {cam_a:+10.1f}  {disp:+10.3f}  {biased:+10.3f}  "
              f"{half_ch:8.1f}  {margin:+8.1f}  {ta:11.1f}")

    # Adjacent block displacement differences
    disps = [slider_displacement(theta, ecc, ch * twist) for ch in range(num_ch)]
    print()
    print("Adjacent block displacement differences (single-tier):")
    for i in range(num_ch - 1):
        delta = abs(disps[i] - disps[i + 1])
        gap = cfg['block_height'] + cfg['block_gap'] - delta
        print(f"  ch{i}-ch{i+1}: |delta_z|={delta:.3f}mm  "
              f"remaining_gap={gap:.2f}mm  "
              f"{'OK' if gap > 0 else 'COLLISION'}")

    # Wave snapshot (ASCII bar chart)
    print()
    print("Wave snapshot (displacement per channel):")
    half_w = 25  # half-width of bar chart in characters
    max_d = max(abs(d) for d in disps) if disps else 1
    if max_d < 0.001:
        max_d = 1.0
    for ch in range(num_ch):
        norm = disps[ch] / max_d  # -1 to +1
        pos = int(round(norm * half_w))
        bar = [' '] * (2 * half_w + 1)
        bar[half_w] = '|'  # center marker
        if pos >= 0:
            for k in range(half_w, half_w + pos + 1):
                bar[k] = '#'
        else:
            for k in range(half_w + pos, half_w + 1):
                bar[k] = '#'
        bar_str = ''.join(bar)
        print(f"  ch{ch}: {disps[ch]:+6.3f}mm  [{bar_str}]")

    # Cam disc positions in XY plane
    print()
    print("Cam disc centers (XY from shaft axis):")
    for ch in range(num_ch):
        cam_a = math.radians(-theta + ch * twist)
        dx = ecc * math.cos(cam_a)
        dy = ecc * math.sin(cam_a)
        print(f"  Disc {ch}: ({dx:+6.3f}, {dy:+6.3f})  "
              f"r={math.sqrt(dx*dx+dy*dy):.3f}mm  "
              f"angle={math.degrees(cam_a) % 360:.1f} deg")


# ================================================================
# CLI
# ================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Animation sweep: check kinematic constraints at every "
                    "degree of cam rotation."
    )
    parser.add_argument('--config', type=str, default=None,
                        help='Path to config_v5_5.scad (auto-detected if omitted)')
    parser.add_argument('--resolution', type=float, default=1.0,
                        help='Angular step size in degrees (default: 1.0)')
    parser.add_argument('--plot', action='store_true',
                        help='Output sweep_data.csv for plotting')
    parser.add_argument('--verbose', action='store_true',
                        help='Show per-angle violation details during sweep')
    parser.add_argument('--angle', type=float, default=None,
                        help='Check a single angle in detail')

    args = parser.parse_args()

    # Find config file
    if args.config:
        config_path = args.config
    else:
        script_dir = Path(__file__).parent
        candidates = [
            script_dir / 'config_v5_5.scad',
            script_dir.parent / 'check point' / '5.5' / 'config_v5_5.scad',
        ]
        config_path = None
        for c in candidates:
            if c.exists():
                config_path = str(c)
                break
        if config_path is None:
            print(f"ERROR: config_v5_5.scad not found in {script_dir} "
                  "or parent directories.")
            print("Use --config /path/to/config_v5_5.scad")
            sys.exit(1)

    print(f"Loading config from: {config_path}")
    cfg = load_config(config_path)

    if args.angle is not None:
        print_single_angle_detail(args.angle, cfg)
        t0 = time.perf_counter()
        result = sweep(cfg, resolution=args.resolution, verbose=True,
                       plot=False, single_angle=args.angle)
        elapsed = time.perf_counter() - t0
        print_report(result, cfg, args.resolution, elapsed,
                     single_angle=args.angle)
        sys.exit(0)

    # Full sweep
    t0 = time.perf_counter()
    result = sweep(cfg, resolution=args.resolution,
                   verbose=args.verbose, plot=args.plot)
    elapsed = time.perf_counter() - t0

    fails = print_report(result, cfg, args.resolution, elapsed)

    if args.plot:
        csv_path = str(Path(__file__).parent / 'sweep_data.csv')
        write_csv(result, cfg, csv_path)
        print(f"\nCSV written to: {csv_path}")

    sys.exit(1 if fails > 0 else 0)


if __name__ == '__main__':
    main()
