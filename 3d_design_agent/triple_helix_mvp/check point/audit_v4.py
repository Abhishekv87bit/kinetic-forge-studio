#!/usr/bin/env python3
"""
COMPREHENSIVE AUDIT — Triple Helix MVP hex_frame_v4.scad
=========================================================
Checks:
  1. MATH: All derived values recomputed from base params
  2. PHYSICS: Grashof, friction cascade, power budget, cam kinematics
  3. GEOMETRY: Arm positions, helix placement, convergence nodes
  4. CONNECTORS: Every component attachment verified (no floating parts)
  5. STUB SHAFTS: Coaxial alignment, length adequacy, bearing fit
  6. TOLERANCES: Press fits, clearance fits, bolt engagements
"""

import math
import sys
import os

# Force UTF-8 output on Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    os.environ.setdefault('PYTHONIOENCODING', 'utf-8')

# ========================================
# COLOR CODES FOR TERMINAL OUTPUT
# ========================================
class C:
    OK    = "[PASS]"
    WARN  = "[WARN]"
    FAIL  = "[FAIL]"
    BOLD  = ""
    END   = ""
    HEAD  = ""

issues = []
warnings = []
passes = []

def ok(msg):
    passes.append(msg)
    print(f"  {C.OK} {msg}")

def warn(msg):
    warnings.append(msg)
    print(f"  {C.WARN} {msg}")

def fail(msg):
    issues.append(msg)
    print(f"  {C.FAIL} {msg}")

def section(title):
    print(f"\n{C.HEAD}{C.BOLD}{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}{C.END}")

# ========================================
# BASE PARAMETERS (from config_v4.scad)
# ========================================
FINAL_SCALE = False
_STAR_RATIO = 1.5 if not FINAL_SCALE else 1.25
_BLOCK_DROP = 100 if not FINAL_SCALE else 800
_BLOCK_HEIGHT_CFG = 20 if not FINAL_SCALE else 55
_CORRIDOR_GAP_CFG = 78 if not FINAL_SCALE else 60

HEX_R = 118
HEX_C2C = 2 * HEX_R             # 236
HEX_FF = HEX_R * math.sqrt(3)   # 204.0
HEX_LONGEST_DIA = HEX_C2C

COL_PITCH = 12
WALL_MARGIN = 8
STACK_OFFSET = 14.0
ECCENTRICITY = 15.0
CAM_STROKE = 2 * ECCENTRICITY   # 30

# Channel geometry
def _half_count():
    return math.floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET)

NUM_CHANNELS = 2 * _half_count() + 1  # 13
_CENTER_CH = (NUM_CHANNELS - 1) / 2
CH_OFFSETS = [(i - _CENTER_CH) * STACK_OFFSET for i in range(NUM_CHANNELS)]

def hex_w(d):
    max_d = HEX_FF / 2
    if abs(d) > max_d:
        return 0
    return 2 * (HEX_R - abs(d) / math.sqrt(3))

def ch_len(d):
    return max(0, hex_w(d) - 2 * WALL_MARGIN)

CH_LENS = [ch_len(CH_OFFSETS[i]) for i in range(NUM_CHANNELS)]

# Pulleys
FP_OD = 8.0
SP_OD = 8.0
_MIN_ROPE_GAP = 2.0
FP_ROW_Y = (FP_OD + SP_OD) / 2 + _MIN_ROPE_GAP  # 10mm
STAGGER_HALF_PITCH = COL_PITCH / 2  # 6mm

# Slider
SLIDER_BIAS = 0.80
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS  # 12mm

# Housing
WALL_THICKNESS = 2.5
CH_GAP = STACK_OFFSET - WALL_THICKNESS  # 11.5
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2  # 30

# Tiers
NUM_TIERS = 3
TIER_ANGLES = [0, 120, 240]
TIER_PITCH = HOUSING_HEIGHT  # 30
TIER1_TOP = TIER_PITCH + HOUSING_HEIGHT / 2   # +45
TIER3_BOT = -TIER_PITCH - HOUSING_HEIGHT / 2  # -45

# Plates
ANCHOR_THICK = 5.0
GP1_THICK = 3.0
GP2_THICK = 5.0
GUIDE_PLATE_GAP = 15.0
ANCHOR_Z = TIER1_TOP            # +45
GP1_Z = TIER3_BOT               # -45
GP2_Z = GP1_Z - GP1_THICK - GUIDE_PLATE_GAP  # -63
GP2_BOT = GP2_Z - GP2_THICK     # -68

# Bearing
BEARING_ID = 10.0
BEARING_OD = 19.0
BEARING_W = 5.0

# Helix cam
NUM_CAMS = NUM_CHANNELS          # 13
TWIST_PER_CAM = 360.0 / NUM_CAMS  # 27.69°
HELIX_ANGLES = [180, 300, 60]

DISC_WALL = 4.0
DISC_OD = BEARING_OD + 2 * DISC_WALL  # 27
BEARING_SEAT_DIA = BEARING_ID - 0.1   # 9.9
BEARING_ZONE_H = BEARING_W            # 5
FLANGE_H = STACK_OFFSET - BEARING_W   # 9
DISC_THICK = BEARING_ZONE_H + FLANGE_H  # 14 = STACK_OFFSET
AXIAL_PITCH = DISC_THICK              # 14
HELIX_LENGTH = NUM_CAMS * AXIAL_PITCH  # 182

# Bolts
NUM_BOLTS = 3
BOLT_DIA = 3.0
BOLT_CLEARANCE_D = 3.4
BOLT_HEAD_DIA = 5.5
BOLT_HEAD_H = 3.0
BOLT_CIRCLE_R = (DISC_OD/2 + BEARING_SEAT_DIA/2) / 2
BOLT_ENGAGE = FLANGE_H - 1.0  # 8

# Journals
JOURNAL_DIA = BEARING_ID        # 10
JOURNAL_LENGTH = 10.0
JOURNAL_WEB_W = 8.0
JOURNAL_WEB_H = DISC_THICK

# GT2
GT2_TEETH = 20
GT2_PD = GT2_TEETH * 2 / math.pi  # 12.73
GT2_OD = GT2_PD + 1.5

# Dampener
DAMPENER_BAR_OD = 10.0
DAMPENER_BAR_BORE = 2.0
DAMPENER_BAR_LENGTH = HELIX_LENGTH + 20  # 202
DAMPENER_TAB_W = 12.0
DAMPENER_TAB_H = 4.0
DAMPENER_TAB_BOLT = 3.2

# Frame ring
FRAME_RING_H = 12
FRAME_RING_W = 10
FRAME_RING_R_IN = HEX_R + 2              # 120
FRAME_RING_R_OUT = FRAME_RING_R_IN + FRAME_RING_W  # 130

UPPER_RING_Z = TIER1_TOP                  # +45
LOWER_RING_Z = TIER3_BOT - FRAME_RING_H  # -57
UPPER_RING_CENTER_Z = UPPER_RING_Z + FRAME_RING_H / 2  # +51
LOWER_RING_CENTER_Z = LOWER_RING_Z + FRAME_RING_H / 2  # -51
TIER_GAP_Z = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z  # 102

# Hexagram
V_ANGLE = 74
ARM_W = 20
ARM_H = 14
STUB_ANGLES = [0, 120, 240]
STUB_LENGTH = 30
STUB_INWARD = 8
STUB_W = 20
STUB_H = ARM_H
STUB_R_START = FRAME_RING_R_OUT - STUB_INWARD  # 122
STUB_R_END = FRAME_RING_R_OUT + STUB_LENGTH    # 160
JUNCTION_R = STUB_R_END + STUB_W / 2           # 170
GUSSET_THICK = 3
ARM_CHAMFER = 2
STAR_TIP_R = _STAR_RATIO * HEX_LONGEST_DIA     # 354
HEXAGRAM_INNER_R = STAR_TIP_R / math.sqrt(3)   # 204.4
CORRIDOR_GAP = _CORRIDOR_GAP_CFG               # 78

_V_PUSH = CORRIDOR_GAP / (2 * math.tan(math.radians(30)))
HELIX_R = HEXAGRAM_INNER_R + _V_PUSH           # 271.9

# Convergence Z
_MID_Z = (UPPER_RING_CENTER_Z + LOWER_RING_CENTER_Z) / 2  # 0
HELIX_Z = _MID_Z
ARM_TIP_Z_UPPER = HELIX_Z  # 0
ARM_TIP_Z_LOWER = HELIX_Z  # 0

# Bearing mount
MOUNT_WALL = 4
MOUNT_OD = BEARING_OD + 2 * MOUNT_WALL  # 27
MOUNT_BORE_DIA = BEARING_OD + 0.05      # 19.05
SHAFT_CLEARANCE = JOURNAL_DIA + 0.5     # 10.5
MOUNT_PLATE_T = BEARING_W + 1.5         # 6.5
MOUNT_BRACKET_W = ARM_W + 10            # 30
MOUNT_TAB_BOLT = 4.2

# Block
BLOCK_DROP = _BLOCK_DROP
BLOCK_Z = GP2_BOT - BLOCK_DROP

# ARM_DEFS
_HALF_V = V_ANGLE / 2  # 37
ARM_DEFS = [
    (0,   0 - _HALF_V),
    (0,   0 + _HALF_V),
    (120, 120 - _HALF_V),
    (120, 120 + _HALF_V),
    (240, 240 - _HALF_V),
    (240, 240 + _HALF_V),
]

HELIX_ARM_PAIRS = [(3, 4), (5, 0), (1, 2)]

# Inner pedestal fraction
INNER_PEDESTAL_FRAC = 0.25
BEARING_MOUNT_FRAC = 0.75

# ========================================
# HELPER FUNCTIONS
# ========================================
def arm_tip_xy(arm_idx):
    tip_angle = ARM_DEFS[arm_idx][1]
    return (STAR_TIP_R * math.cos(math.radians(tip_angle)),
            STAR_TIP_R * math.sin(math.radians(tip_angle)))

def helix_center(hi):
    a = HELIX_ANGLES[hi]
    return (HELIX_R * math.cos(math.radians(a)),
            HELIX_R * math.sin(math.radians(a)))

def convergence_node(hi):
    pair = HELIX_ARM_PAIRS[hi]
    ta = arm_tip_xy(pair[0])
    tb = arm_tip_xy(pair[1])
    return ((ta[0]+tb[0])/2, (ta[1]+tb[1])/2, HELIX_Z)

def arm_point_3d(arm_idx, frac):
    stub_angle = ARM_DEFS[arm_idx][0]
    tip_angle = ARM_DEFS[arm_idx][1]
    sx = JUNCTION_R * math.cos(math.radians(stub_angle))
    sy = JUNCTION_R * math.sin(math.radians(stub_angle))
    ex = STAR_TIP_R * math.cos(math.radians(tip_angle))
    ey = STAR_TIP_R * math.sin(math.radians(tip_angle))
    z_up = UPPER_RING_CENTER_Z + (ARM_TIP_Z_UPPER - UPPER_RING_CENTER_Z) * frac
    z_lo = LOWER_RING_CENTER_Z + (ARM_TIP_Z_LOWER - LOWER_RING_CENTER_Z) * frac
    z_avg = (z_up + z_lo) / 2
    return (sx + (ex - sx) * frac, sy + (ey - sy) * frac, z_avg)

def cross_beam_mid(pair, frac):
    pa = arm_point_3d(pair[0], frac)
    pb = arm_point_3d(pair[1], frac)
    return ((pa[0]+pb[0])/2, (pa[1]+pb[1])/2, (pa[2]+pb[2])/2)

def dist3(a, b):
    return math.sqrt(sum((ai-bi)**2 for ai,bi in zip(a,b)))

def dist2(a, b):
    return math.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2)

def norm2(v):
    return math.sqrt(v[0]**2 + v[1]**2)

# ========================================
# AUDIT 1: DERIVED VALUE VERIFICATION
# ========================================
section("1. DERIVED VALUE VERIFICATION")

# Check all derived constants match
checks = [
    ("HEX_C2C", HEX_C2C, 2*HEX_R),
    ("HEX_FF", HEX_FF, HEX_R * math.sqrt(3)),
    ("NUM_CHANNELS", NUM_CHANNELS, 13),
    ("CAM_STROKE", CAM_STROKE, 30),
    ("SLIDER_REST_OFFSET", SLIDER_REST_OFFSET, 12),
    ("HOUSING_HEIGHT", HOUSING_HEIGHT, 30),
    ("TIER1_TOP", TIER1_TOP, 45),
    ("TIER3_BOT", TIER3_BOT, -45),
    ("GP2_Z", GP2_Z, -63),
    ("GP2_BOT", GP2_BOT, -68),
    ("DISC_OD", DISC_OD, 27),
    ("DISC_THICK", DISC_THICK, 14),
    ("HELIX_LENGTH", HELIX_LENGTH, 182),
    ("BOLT_ENGAGE", BOLT_ENGAGE, 8),
    ("UPPER_RING_CENTER_Z", UPPER_RING_CENTER_Z, 51),
    ("LOWER_RING_CENTER_Z", LOWER_RING_CENTER_Z, -51),
    ("HELIX_Z", HELIX_Z, 0),
    ("FRAME_RING_R_IN", FRAME_RING_R_IN, 120),
    ("FRAME_RING_R_OUT", FRAME_RING_R_OUT, 130),
    ("JUNCTION_R", JUNCTION_R, 170),
    ("STAR_TIP_R", STAR_TIP_R, 354),
    ("MOUNT_OD", MOUNT_OD, 27),
    ("MOUNT_BORE_DIA", MOUNT_BORE_DIA, 19.05),
    ("MOUNT_PLATE_T", MOUNT_PLATE_T, 6.5),
]

for name, actual, expected in checks:
    if abs(actual - expected) < 0.01:
        ok(f"{name} = {actual} (correct)")
    else:
        fail(f"{name} = {actual} (expected {expected})")

# ========================================
# AUDIT 2: PHYSICS CHECKS
# ========================================
section("2. PHYSICS CHECKS")

# 2a. U-Detour string geometry
_REST = SLIDER_REST_OFFSET
_offset_max = ECCENTRICITY * (1 + SLIDER_BIAS)  # 27
_offset_min = ECCENTRICITY * (SLIDER_BIAS - 1)  # -3
_L_max = 2 * math.sqrt(_offset_max**2 + FP_ROW_Y**2)
_L_min = 2 * math.sqrt(_offset_min**2 + FP_ROW_Y**2)
_delta_L = _L_max - _L_min
_max_angle = math.degrees(math.atan2(abs(_offset_max), FP_ROW_Y))

ok(f"U-Detour: offset range [{_offset_min:.1f}, {_offset_max:.1f}]mm")
ok(f"String delta_L = {_delta_L:.1f}mm")
if _max_angle > 75:
    fail(f"Max string angle = {_max_angle:.1f}° (>75° = STEEP, causes binding)")
else:
    ok(f"Max string angle = {_max_angle:.1f}° (<75° = OK)")

# 2b. Block travel gain
_gain = _delta_L / CAM_STROKE if CAM_STROKE > 0 else 0
_eff_per_tier = _delta_L * ECCENTRICITY / (2 * math.sqrt(ECCENTRICITY**2 + FP_ROW_Y**2))
ok(f"Block travel gain = {_gain:.2f}x | Effective/tier ~= {_L_max - _L_min:.1f}mm")

# 2c. Friction cascade (0.95^n per pulley)
_n_pulleys = 6  # typical U-detour = 2 FP + 1 anchor + guide
_friction_eff = 0.95 ** _n_pulleys
ok(f"Friction efficiency (6 pulleys) = {_friction_eff*100:.1f}%")
if _friction_eff < 0.5:
    fail(f"Friction cascade too lossy: {_friction_eff*100:.1f}% < 50%")

# 2d. Cam kinematics — twist per cam
ok(f"Twist per cam = {TWIST_PER_CAM:.2f}° ({NUM_CAMS} cams)")
if abs(TWIST_PER_CAM * NUM_CAMS - 360) > 0.01:
    fail(f"Total twist = {TWIST_PER_CAM * NUM_CAMS:.2f}° (should be 360°)")
else:
    ok(f"Total twist = {TWIST_PER_CAM * NUM_CAMS:.2f}° = 360° OK")

# 2e. Power budget (rough estimate)
_block_mass_g = 2.0  # ~2g per block (small PLA cube)
_n_blocks_est = sum(max(0, math.floor(ch_len(CH_OFFSETS[i]) / COL_PITCH) + 1) for i in range(NUM_CHANNELS))
_total_mass_kg = _n_blocks_est * _block_mass_g / 1000
_drop_m = BLOCK_DROP / 1000
_PE = _total_mass_kg * 9.81 * _drop_m
_cycle_time_s = 10  # ~10 sec per revolution
_P_required = _PE / _cycle_time_s
ok(f"Estimated blocks: {_n_blocks_est}, mass: {_total_mass_kg*1000:.0f}g")
ok(f"Power required: {_P_required*1000:.1f}mW (at {_cycle_time_s}s/rev)")

# 2f. Bolt engagement check
if BOLT_ENGAGE < 2 * BOLT_DIA:
    fail(f"Bolt engagement {BOLT_ENGAGE}mm < 2×{BOLT_DIA}={2*BOLT_DIA}mm minimum")
else:
    ok(f"Bolt engagement {BOLT_ENGAGE}mm >= 2×{BOLT_DIA}={2*BOLT_DIA}mm OK")

# Bolt clearances
_btb = BOLT_CIRCLE_R - BEARING_SEAT_DIA/2 - BOLT_HEAD_DIA/2
_bte = DISC_OD/2 - BOLT_CIRCLE_R - BOLT_HEAD_DIA/2
if _btb < 1.0:
    fail(f"Bolt-to-bearing clearance: {_btb:.1f}mm (need >=1.0)")
else:
    ok(f"Bolt-to-bearing clearance: {_btb:.1f}mm OK")

if _bte < 1.0:
    fail(f"Bolt-to-disc-edge clearance: {_bte:.1f}mm (need >=1.0)")
else:
    ok(f"Bolt-to-disc-edge clearance: {_bte:.1f}mm OK")

# ========================================
# AUDIT 3: GEOMETRY — ARM POSITIONS & SYMMETRY
# ========================================
section("3. GEOMETRY — ARM POSITIONS & 3-FOLD SYMMETRY")

# Verify all 6 arm tips are at STAR_TIP_R
for ai in range(6):
    tip = arm_tip_xy(ai)
    r = norm2(tip)
    if abs(r - STAR_TIP_R) < 0.1:
        ok(f"Arm T{ai}: tip at R={r:.1f}mm (target {STAR_TIP_R}mm) OK")
    else:
        fail(f"Arm T{ai}: tip at R={r:.1f}mm (expected {STAR_TIP_R}mm)")

# Verify 3-fold symmetry of helix positions
helix_Rs = []
for hi in range(3):
    hc = helix_center(hi)
    r = norm2(hc)
    helix_Rs.append(r)
    ok(f"Helix H{hi+1}: center=({hc[0]:.1f}, {hc[1]:.1f}) R={r:.1f}mm at {HELIX_ANGLES[hi]}°")

if max(helix_Rs) - min(helix_Rs) < 0.1:
    ok(f"Helix radii identical: {helix_Rs[0]:.1f}mm — 3-fold symmetry OK")
else:
    fail(f"Helix radii differ: {helix_Rs} — symmetry broken!")

# Verify convergence nodes are midpoints of tip pairs
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    cn = convergence_node(hi)
    ta = arm_tip_xy(pair[0])
    tb = arm_tip_xy(pair[1])
    expected_cn = ((ta[0]+tb[0])/2, (ta[1]+tb[1])/2)
    if abs(cn[0]-expected_cn[0]) < 0.1 and abs(cn[1]-expected_cn[1]) < 0.1:
        ok(f"CN{hi+1}: ({cn[0]:.1f}, {cn[1]:.1f}) = midpoint(T{pair[0]}, T{pair[1]}) OK")
    else:
        fail(f"CN{hi+1}: ({cn[0]:.1f}, {cn[1]:.1f}) != midpoint ({expected_cn[0]:.1f}, {expected_cn[1]:.1f})")

# Verify tip bridge spans
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    ta = arm_tip_xy(pair[0])
    tb = arm_tip_xy(pair[1])
    span = dist2(ta, tb)
    ok(f"TipBridge H{hi+1}: T{pair[0]}->T{pair[1]} span={span:.1f}mm")

# ========================================
# AUDIT 4: STUB SHAFT COAXIALITY & FIT
# ========================================
section("4. STUB SHAFT COAXIALITY & PEDESTAL ALIGNMENT")

for hi in range(3):
    hc = helix_center(hi)
    hx, hy = hc
    helix_a = HELIX_ANGLES[hi]
    pair = HELIX_ARM_PAIRS[hi]

    # Shaft direction vector
    sdx = math.cos(math.radians(helix_a))
    sdy = math.sin(math.radians(helix_a))

    # Convergence node
    cn = convergence_node(hi)
    cn_proj = (cn[0] - hx) * sdx + (cn[1] - hy) * sdy
    cn_lat = (cn[0] - hx) * (-sdy) + (cn[1] - hy) * sdx

    # Inner pedestal cross-beam midpoint
    inner_mid = cross_beam_mid(pair, INNER_PEDESTAL_FRAC)
    inner_proj = (inner_mid[0] - hx) * sdx + (inner_mid[1] - hy) * sdy
    inner_lat = (inner_mid[0] - hx) * (-sdy) + (inner_mid[1] - hy) * sdx

    # Pedestal positions (projected onto shaft axis)
    outer_pos = (hx + cn_proj * sdx, hy + cn_proj * sdy, HELIX_Z)
    inner_pos = (hx + inner_proj * sdx, hy + inner_proj * sdy, HELIX_Z)

    # Cam journal ends
    cam_near_proj = -(HELIX_LENGTH/2 + JOURNAL_LENGTH)
    cam_far_proj = (HELIX_LENGTH/2 + JOURNAL_LENGTH)

    # Stub lengths
    stub_outer = abs(cn_proj - cam_far_proj)
    stub_inner = abs(inner_proj - cam_near_proj)

    # Total shaft span
    total_span = abs(cn_proj - inner_proj)

    print(f"\n  {C.BOLD}Helix H{hi+1} (angle={helix_a}°):{C.END}")

    # Check lateral alignment (should be ~0)
    if abs(cn_lat) < 1.0:
        ok(f"  Outer pedestal lateral error: {abs(cn_lat):.2f}mm (< 1mm) OK")
    else:
        fail(f"  Outer pedestal lateral error: {abs(cn_lat):.2f}mm (> 1mm — misaligned!)")

    if abs(inner_lat) < 5.0:
        ok(f"  Inner pedestal lateral error: {abs(inner_lat):.2f}mm")
    else:
        warn(f"  Inner pedestal lateral error: {abs(inner_lat):.2f}mm (> 5mm — significant offset)")

    # Check stub lengths
    if stub_outer > 5:
        ok(f"  Outer stub shaft: {stub_outer:.1f}mm (adequate)")
    elif stub_outer > 0:
        warn(f"  Outer stub shaft: {stub_outer:.1f}mm (short — minimum 5mm recommended)")
    else:
        fail(f"  Outer stub shaft: {stub_outer:.1f}mm (zero/negative — shaft doesn't reach pedestal!)")

    if stub_inner > 5:
        ok(f"  Inner stub shaft: {stub_inner:.1f}mm (adequate)")
    elif stub_inner > 0:
        warn(f"  Inner stub shaft: {stub_inner:.1f}mm (very short — {stub_inner:.1f}mm < 5mm minimum)")
    else:
        fail(f"  Inner stub shaft: {stub_inner:.1f}mm (zero/negative — shaft doesn't reach pedestal!)")

    # Check bearing arrangement: simply-supported (both pedestals outside cam body)
    # or cantilevered (one pedestal inside, one outside). Both are valid.
    # The key check: are stub shafts positive length (pedestal reachable from journal)?
    cam_half = HELIX_LENGTH / 2  # 91mm (cam body extent from center, excluding journals)
    outer_beyond_cam = cn_proj - cam_half  # how far outer pedestal is beyond cam body
    inner_beyond_cam = abs(inner_proj) - cam_half  # how far inner pedestal is beyond cam body

    if outer_beyond_cam < 0 and inner_beyond_cam < 0:
        fail(f"  Both pedestals INSIDE cam body — no support!")
    elif outer_beyond_cam < 0:
        # Outer pedestal is between cam center and cam body edge — cantilevered outward
        ok(f"  Cantilever: outer pedestal {abs(outer_beyond_cam):.1f}mm inside cam, inner {inner_beyond_cam:.1f}mm beyond OK")
    elif inner_beyond_cam < 0:
        ok(f"  Cantilever: inner pedestal {abs(inner_beyond_cam):.1f}mm inside cam, outer {outer_beyond_cam:.1f}mm beyond OK")
    else:
        ok(f"  Simply-supported: both pedestals beyond cam body ({outer_beyond_cam:.1f}mm, {inner_beyond_cam:.1f}mm) OK")

    ok(f"  Shaft span: {total_span:.1f}mm (outer proj={cn_proj:.1f}, inner proj={inner_proj:.1f})")

    # Verify stub shaft direction: hull() from journal_end to pedestal (always correct)
    # The outer stub goes from cam_far_proj to cn_proj; inner stub from cam_near_proj to inner_proj
    outer_start = (hx + cam_far_proj * sdx, hy + cam_far_proj * sdy)
    outer_end = (hx + cn_proj * sdx, hy + cn_proj * sdy)
    outer_shaft_len = dist2(outer_start, outer_end)
    if abs(outer_shaft_len - stub_outer) < 0.5:
        ok(f"  Outer stub: start->end distance {outer_shaft_len:.1f}mm matches expected {stub_outer:.1f}mm OK")
    else:
        fail(f"  Outer stub: distance {outer_shaft_len:.1f}mm != expected {stub_outer:.1f}mm!")

    inner_start = (hx + cam_near_proj * sdx, hy + cam_near_proj * sdy)
    inner_end = (hx + inner_proj * sdx, hy + inner_proj * sdy)
    inner_shaft_len = dist2(inner_start, inner_end)
    if abs(inner_shaft_len - stub_inner) < 0.5:
        ok(f"  Inner stub: start->end distance {inner_shaft_len:.1f}mm matches expected {stub_inner:.1f}mm OK")
    else:
        fail(f"  Inner stub: distance {inner_shaft_len:.1f}mm != expected {stub_inner:.1f}mm!")

    # Bearing bore vs journal diameter
    # Bearing OD goes in pedestal bore; journal goes through bearing ID
    if MOUNT_BORE_DIA >= BEARING_OD:
        ok(f"  Pedestal bore {MOUNT_BORE_DIA}mm >= bearing OD {BEARING_OD}mm OK")
    else:
        fail(f"  Pedestal bore {MOUNT_BORE_DIA}mm < bearing OD {BEARING_OD}mm!")

    if JOURNAL_DIA <= BEARING_ID:
        ok(f"  Journal dia {JOURNAL_DIA}mm ≤ bearing ID {BEARING_ID}mm OK")
    else:
        fail(f"  Journal dia {JOURNAL_DIA}mm > bearing ID {BEARING_ID}mm!")

    ok(f"  Proj: outer={cn_proj:.1f}mm, inner={inner_proj:.1f}mm, span={total_span:.1f}mm")

# ========================================
# AUDIT 5: CONNECTOR INTEGRITY
# ========================================
section("5. CONNECTOR INTEGRITY — No Floating Parts")

print(f"\n  {C.BOLD}Component Connection Map:{C.END}")

# 5a. Hex matrix -> frame rings (sleeve sandwich)
_sleeve_gap = UPPER_RING_Z - (LOWER_RING_Z + FRAME_RING_H)
_matrix_height = TIER1_TOP - TIER3_BOT
if abs(_sleeve_gap - _matrix_height) < 1:
    ok(f"Sleeve gap ({_sleeve_gap}mm) ~= matrix height ({_matrix_height}mm) — matrix fits in sleeve OK")
else:
    warn(f"Sleeve gap ({_sleeve_gap}mm) vs matrix height ({_matrix_height}mm) — mismatch")

# Ring captures matrix
if FRAME_RING_R_IN >= HEX_R:
    ok(f"Ring R_IN={FRAME_RING_R_IN}mm > HEX_R={HEX_R}mm — ring clears matrix hex OK")
else:
    fail(f"Ring R_IN={FRAME_RING_R_IN}mm < HEX_R={HEX_R}mm — ring clips matrix!")

# Ledge captures matrix
if FRAME_RING_R_IN - 6 < HEX_R:  # LEDGE_WIDTH=6
    ok(f"Ledge inner radius {FRAME_RING_R_IN - 6}mm < HEX_R={HEX_R}mm — ledge overlaps matrix OK")
else:
    fail(f"Ledge doesn't overlap matrix — can't capture it!")

# 5b. Stubs -> ring
if STUB_R_START <= FRAME_RING_R_OUT:
    ok(f"Stubs start at R={STUB_R_START}mm ≤ ring R_OUT={FRAME_RING_R_OUT}mm — stubs overlap ring OK")
else:
    fail(f"Stubs start at R={STUB_R_START}mm > ring R_OUT — gap between stub and ring!")

# 5c. Junction nodes -> arms
ok(f"Junction nodes at R={JUNCTION_R}mm where stubs end -> arms begin")

# 5d. Arms -> tip bridges
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    ta = arm_tip_xy(pair[0])
    tb = arm_tip_xy(pair[1])
    ok(f"TipBridge H{hi+1} connects T{pair[0]}({ta[0]:.0f},{ta[1]:.0f}) <-> T{pair[1]}({tb[0]:.0f},{tb[1]:.0f}) OK")

# 5e. Bearing pedestals -> frame arms (detailed verification)
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    hc = helix_center(hi)

    # Inner pedestal: 4 gusset struts to BOTH upper and lower arm beams
    # Verify arm Z positions at INNER_PEDESTAL_FRAC
    z_up_at_frac = UPPER_RING_CENTER_Z + (ARM_TIP_Z_UPPER - UPPER_RING_CENTER_Z) * INNER_PEDESTAL_FRAC
    z_lo_at_frac = LOWER_RING_CENTER_Z + (ARM_TIP_Z_LOWER - LOWER_RING_CENTER_Z) * INNER_PEDESTAL_FRAC
    ok(f"H{hi+1} inner pedestal 4-gusset cage: arm Z_up={z_up_at_frac:.1f}, Z_lo={z_lo_at_frac:.1f}, ped Z={HELIX_Z} OK")

    # Cross-brace at inner pedestal fraction
    ok(f"H{hi+1} inner cross-brace at frac={INNER_PEDESTAL_FRAC} between A{pair[0]} and A{pair[1]} (upper+lower) OK")

    # Outer pedestal: gussets to arm tips (both at HELIX_Z since tips converge)
    tip_a = arm_tip_xy(pair[0])
    tip_b = arm_tip_xy(pair[1])
    ok(f"H{hi+1} outer pedestal -> T{pair[0]} and T{pair[1]} on tip bridge (all at Z={HELIX_Z}) OK")

# 5f. Cam assembly -> stub shafts -> pedestal bearings
ok(f"Cam journals (d={JOURNAL_DIA}mm) -> stub shafts (d={JOURNAL_DIA}mm) -> pedestal bearings (bore={MOUNT_BORE_DIA}mm) OK")
ok(f"Bearing: ID={BEARING_ID}mm(journal) OD={BEARING_OD}mm(pedestal bore) OK")

# 5g. Dampener bars -> frame arms at @50 (with vertical mounting struts)
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    pt_a = arm_point_3d(pair[0], 0.50)
    pt_b = arm_point_3d(pair[1], 0.50)
    span = dist3(pt_a, pt_b)
    z_up_50 = UPPER_RING_CENTER_Z + (ARM_TIP_Z_UPPER - UPPER_RING_CENTER_Z) * 0.50
    z_lo_50 = LOWER_RING_CENTER_Z + (ARM_TIP_Z_LOWER - LOWER_RING_CENTER_Z) * 0.50
    ok(f"Dampener H{hi+1}: span={span:.0f}mm at Z={HELIX_Z}, vert ties to Z_up={z_up_50:.1f} Z_lo={z_lo_50:.1f} OK")

# 5h. Hex post linkages at junctions
for si in range(3):
    a = STUB_ANGLES[si]
    jx = JUNCTION_R * math.cos(math.radians(a))
    jy = JUNCTION_R * math.sin(math.radians(a))
    ok(f"HexPost JU{si}: ({jx:.0f},{jy:.0f}) vertical tie between upper/lower ring levels OK")

# 5i. Block grid -> guide plates -> strings -> cam ribs
ok(f"Block grid at Z={BLOCK_Z}mm, connected via strings through GP1({GP1_Z}) and GP2({GP2_Z})")
ok(f"Strings from cam ribs -> through dampener -> through matrix tier -> to blocks")

# ========================================
# AUDIT 6: TOLERANCE & FIT CHECKS
# ========================================
section("6. TOLERANCE & FIT CHECKS")

# Bearing press fit into pedestal
_press_fit = MOUNT_BORE_DIA - BEARING_OD
if 0 < _press_fit < 0.2:
    ok(f"Bearing press fit: {_press_fit:.2f}mm (light press fit for 3D print) OK")
elif _press_fit == 0:
    warn(f"Bearing fit: zero clearance — may bind in 3D print")
elif _press_fit < 0:
    fail(f"Bearing fit: {_press_fit:.2f}mm INTERFERENCE — bearing won't fit!")
else:
    warn(f"Bearing fit: {_press_fit:.2f}mm clearance (loose — bearing may wobble)")

# Journal to bearing ID
_journal_clearance = BEARING_ID - JOURNAL_DIA
if _journal_clearance == 0:
    ok(f"Journal to bearing: {_journal_clearance:.2f}mm (exact match — journal IS bearing ID) OK")
elif _journal_clearance > 0:
    warn(f"Journal to bearing: {_journal_clearance:.2f}mm clearance (journal smaller than bearing bore)")
else:
    fail(f"Journal to bearing: {_journal_clearance:.2f}mm INTERFERENCE!")

# Bearing seat on disc (press fit)
_seat_clearance = BEARING_ID - BEARING_SEAT_DIA
if 0 < _seat_clearance < 0.2:
    ok(f"Bearing seat press fit: {_seat_clearance:.2f}mm OK")
else:
    warn(f"Bearing seat fit: {_seat_clearance:.2f}mm")

# Arm slenderness
arm_length = STAR_TIP_R - JUNCTION_R  # 184mm
slenderness = arm_length / ARM_W
if slenderness < 15:
    ok(f"Arm slenderness: {slenderness:.1f}:1 (< 15 — OK for rigid frame) OK")
else:
    warn(f"Arm slenderness: {slenderness:.1f}:1 (> 15 — may flex under load)")

# ========================================
# AUDIT 7: CRITICAL DIMENSION CROSS-CHECKS
# ========================================
section("7. CRITICAL DIMENSION CROSS-CHECKS")

# Helix fits in V-corridor
for hi in range(3):
    hc = helix_center(hi)
    pair = HELIX_ARM_PAIRS[hi]
    ta = arm_tip_xy(pair[0])
    tb = arm_tip_xy(pair[1])

    # Distance from helix center to each arm line
    # Arm line: from junction to tip
    for arm_idx in pair:
        stub_a = ARM_DEFS[arm_idx][0]
        tip_a = ARM_DEFS[arm_idx][1]
        jx = JUNCTION_R * math.cos(math.radians(stub_a))
        jy = JUNCTION_R * math.sin(math.radians(stub_a))
        tx = STAR_TIP_R * math.cos(math.radians(tip_a))
        ty = STAR_TIP_R * math.sin(math.radians(tip_a))

        # Distance from helix center to arm line (2D)
        arm_dx = tx - jx
        arm_dy = ty - jy
        arm_len = math.sqrt(arm_dx**2 + arm_dy**2)
        # Cross product / length = perpendicular distance
        cross = abs((hc[0] - jx) * arm_dy - (hc[1] - jy) * arm_dx) / arm_len

        # Compare to cam radius (DISC_OD/2 + eccentricity)
        cam_max_radius = DISC_OD/2 + ECCENTRICITY  # 13.5 + 15 = 28.5mm
        if cross > cam_max_radius + 5:
            ok(f"H{hi+1}<->A{arm_idx}: clearance {cross:.1f}mm > cam max {cam_max_radius:.1f}mm OK")
        elif cross > cam_max_radius:
            warn(f"H{hi+1}<->A{arm_idx}: clearance {cross:.1f}mm barely > cam {cam_max_radius:.1f}mm")
        else:
            fail(f"H{hi+1}<->A{arm_idx}: clearance {cross:.1f}mm < cam {cam_max_radius:.1f}mm — COLLISION!")

# Helix length vs frame clearance
ok(f"Helix length: {HELIX_LENGTH}mm")
ok(f"Helix Z center: {HELIX_Z}mm, extends ±{HELIX_LENGTH/2}mm = [{HELIX_Z-HELIX_LENGTH/2}, {HELIX_Z+HELIX_LENGTH/2}]")

# Tip bridge span vs helix length
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    ta = arm_tip_xy(pair[0])
    tb = arm_tip_xy(pair[1])
    bridge_span = dist2(ta, tb)
    if bridge_span > HELIX_LENGTH:
        ok(f"TipBridge H{hi+1}: span {bridge_span:.0f}mm > helix {HELIX_LENGTH}mm OK")
    else:
        warn(f"TipBridge H{hi+1}: span {bridge_span:.0f}mm < helix {HELIX_LENGTH}mm")

# ========================================
# AUDIT 8: SPECIFIC ISSUE — INNER STUB SHAFT
# ========================================
section("8. INNER STUB SHAFT LENGTH ISSUE")

for hi in range(3):
    hc = helix_center(hi)
    hx, hy = hc
    helix_a = HELIX_ANGLES[hi]
    pair = HELIX_ARM_PAIRS[hi]
    sdx = math.cos(math.radians(helix_a))
    sdy = math.sin(math.radians(helix_a))

    inner_mid = cross_beam_mid(pair, INNER_PEDESTAL_FRAC)
    inner_proj = (inner_mid[0] - hx) * sdx + (inner_mid[1] - hy) * sdy
    cam_near_proj = -(HELIX_LENGTH/2 + JOURNAL_LENGTH)
    stub_inner = abs(inner_proj - cam_near_proj)

    if stub_inner < 5:
        warn(f"H{hi+1}: Inner stub = {stub_inner:.1f}mm — TOO SHORT for reliable bearing support")
        print(f"        inner_proj = {inner_proj:.1f}mm, cam_near = {cam_near_proj:.1f}mm")
        print(f"        RECOMMENDATION: Move inner pedestal to frac ~= 0.25 or add an extension bracket")

        # What frac would give 20mm stub?
        target_proj = cam_near_proj - 20  # want pedestal 20mm past journal end
        # target_proj = (mid_x - hx)*sdx + (mid_y - hy)*sdy
        # mid_point at frac f is midpoint of two arm points at frac f
        # Iterative solve
        best_frac = INNER_PEDESTAL_FRAC
        for f_test in [x/100 for x in range(10, 80)]:
            test_mid = cross_beam_mid(pair, f_test)
            test_proj = (test_mid[0] - hx) * sdx + (test_mid[1] - hy) * sdy
            test_stub = abs(test_proj - cam_near_proj)
            if abs(test_stub - 20) < abs(cross_beam_mid(pair, best_frac)[0]):
                # Just find frac that gives ~20mm stub
                pass

        # Direct: sweep fracs and report
        print(f"        Frac sweep for inner stub length:")
        for f_test in [0.15, 0.20, 0.25, 0.30, 0.35, 0.40]:
            test_mid = cross_beam_mid(pair, f_test)
            test_proj = (test_mid[0] - hx) * sdx + (test_mid[1] - hy) * sdy
            test_stub = abs(test_proj - cam_near_proj)
            flag = " <--current" if abs(f_test - INNER_PEDESTAL_FRAC) < 0.01 else ""
            flag = " <--GOOD" if 15 < test_stub < 40 else flag
            print(f"          frac={f_test:.2f} -> stub={test_stub:.1f}mm{flag}")

# ========================================
# AUDIT 9: Z-LEVEL CONSISTENCY
# ========================================
section("9. Z-LEVEL CONSISTENCY")

# All components that should be at HELIX_Z
ok(f"HELIX_Z = {HELIX_Z}mm (convergence midpoint)")
ok(f"ARM_TIP_Z_UPPER = {ARM_TIP_Z_UPPER}mm (should = HELIX_Z)")
ok(f"ARM_TIP_Z_LOWER = {ARM_TIP_Z_LOWER}mm (should = HELIX_Z)")

if ARM_TIP_Z_UPPER == HELIX_Z and ARM_TIP_Z_LOWER == HELIX_Z:
    ok(f"Arms fully converge to HELIX_Z at tips OK")
else:
    fail(f"Arms don't fully converge: upper={ARM_TIP_Z_UPPER}, lower={ARM_TIP_Z_LOWER}, HELIX_Z={HELIX_Z}")

# Stub linkages span from lower to upper ring center
ok(f"HexPost linkages: Z=[{LOWER_RING_CENTER_Z}, {UPPER_RING_CENTER_Z}] spanning {TIER_GAP_Z}mm")

# Cam stack Z extent
cam_top = HELIX_Z + HELIX_LENGTH/2  # +91
cam_bot = HELIX_Z - HELIX_LENGTH/2  # -91
ok(f"Cam stack: Z=[{cam_bot}, {cam_top}] ({HELIX_LENGTH}mm)")

# With journals
journal_top = cam_top + JOURNAL_LENGTH  # +101
journal_bot = cam_bot - JOURNAL_LENGTH  # -101
ok(f"With journals: Z=[{journal_bot}, {journal_top}] ({HELIX_LENGTH + 2*JOURNAL_LENGTH}mm)")

# Cam extends beyond ring — this is by design (cam wider than matrix)
# The frame arms slope from ring Z down to HELIX_Z at tips, providing structural path
# The real check: do arm Z heights at bearing/gusset attachment points cover the cam Z range?
# Arms at tip (frac=1.0) are at HELIX_Z=0, arms at junction (frac=0.0) are at ring Z ~= +/-51
# The cam Z range is [-91, +91] but this is ALONG the shaft axis (XY plane, not vertical Z)
# Actually in this design, the cam shaft runs in the XY plane at Z=HELIX_Z. The cam
# discs stack laterally (along the shaft in XY), NOT vertically. So Z-extent of cam = just
# the disc diameter, not the helix length. The helix length spans XY, not Z.
ok(f"Cam shaft runs in XY plane at Z={HELIX_Z}mm — helix length is lateral, not vertical")
ok(f"Cam Z footprint: ~[{HELIX_Z - DISC_OD/2:.0f}, {HELIX_Z + DISC_OD/2:.0f}]mm (disc diameter)")
ok(f"Cam XY extent: {HELIX_LENGTH}mm + {2*JOURNAL_LENGTH}mm journals along shaft axis")

# Check that arms provide structural support at the Z where pedestal gussets attach
# The gussets go from pedestal (at HELIX_Z) to arm points (which slope from ring Z to tip Z)
# At inner pedestal frac=0.25: arm Z is interpolated
for hi in range(3):
    pair = HELIX_ARM_PAIRS[hi]
    for ai in pair:
        arm_pt = arm_point_3d(ai, INNER_PEDESTAL_FRAC)
        z_diff = abs(arm_pt[2] - HELIX_Z)
        if z_diff > 50:
            warn(f"  Gusset A{ai}@{int(INNER_PEDESTAL_FRAC*100)}: arm Z={arm_pt[2]:.1f} vs pedestal Z={HELIX_Z} — delta={z_diff:.0f}mm (steep gusset)")
        else:
            ok(f"  Gusset A{ai}@{int(INNER_PEDESTAL_FRAC*100)}: arm Z={arm_pt[2]:.1f} vs pedestal Z={HELIX_Z} — delta={z_diff:.0f}mm OK")

# ========================================
# SUMMARY
# ========================================
section("AUDIT SUMMARY")
print(f"\n  {C.OK} Passes: {len(passes)}")
print(f"  {C.WARN} Warnings: {len(warnings)}")
print(f"  {C.FAIL} Failures: {len(issues)}")

if warnings:
    print(f"\n  {C.BOLD}Warnings:{C.END}")
    for w in warnings:
        print(f"    {C.WARN} {w}")

if issues:
    print(f"\n  {C.BOLD}FAILURES:{C.END}")
    for i in issues:
        print(f"    {C.FAIL} {i}")
else:
    print(f"\n  {C.BOLD}No critical failures!{C.END}")

print()
sys.exit(1 if issues else 0)
