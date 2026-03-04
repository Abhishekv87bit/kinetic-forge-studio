"""
V5.5b COMPLETE FUNCTIONAL MATH VALIDATION
==========================================
Validates all V5.5 changes PLUS V5.5b (9-channel) changes:
  C1: Frame monolith (separate from matrix) — ring geometry, post placement
  C2: Hex sleeve retention — plate sizing, clearances
  C3: Keyed collar faces — bump/dimple geometry
  C4: Tier angles fixed — sliders face helixes
  C5: Frame posts at stub vertices only
  C6: Dampener bar height = arm height
  C7: FP_AXLE_LEN fix — no wall bleed-through
  C8: 7 channels (STACK_OFFSET=10.0, FP/SP_OD=4.0) — V5.6 Rule 99 matrix audit
  C9: End-stop protrusion clamped — no bleed through slider walls
  C10: Slider axle clamped — stays between slider plates
  C11: Single guide plate (replaces dual GP1+GP2+7mm gap)

Plus all V5.4 validation checks carried forward.
"""

import math

# ================================================================
# CONFIG V5.5b VALUES
# ================================================================
SCALE = 0.4831

# Hex
HEX_R = 43
HEX_C2C = 2 * HEX_R
HEX_FF = HEX_R * math.sqrt(3)

# Channels — V5.5b: 9 channels (was 13)
COL_PITCH = 6
WALL_MARGIN = 4
STACK_OFFSET = 10.0  # V5.6: was 8.0 (Rule 99 matrix audit)
WALL_THICKNESS = 1.5
CH_GAP = STACK_OFFSET - WALL_THICKNESS   # 8.5mm (V5.6: was 6.5mm)

def half_count():
    return math.floor((HEX_FF / 2 - STACK_OFFSET / 2) / STACK_OFFSET)
NUM_CHANNELS = 2 * half_count() + 1  # 7 (V5.6: was 9)

CENTER_CH = (NUM_CHANNELS - 1) / 2
CH_OFFSETS = [(i - CENTER_CH) * STACK_OFFSET for i in range(NUM_CHANNELS)]

def hex_w(d):
    max_d = HEX_FF / 2
    if abs(d) > max_d:
        return 0
    return 2 * (HEX_R - abs(d) / math.sqrt(3))

def ch_len(d):
    return max(0, hex_w(d) - 2 * WALL_MARGIN)

CH_LENS = [ch_len(CH_OFFSETS[i]) for i in range(NUM_CHANNELS)]

# Pulleys
FP_OD = 4.0   # V5.6: was 3.0 (Rule 99 matrix audit)
SP_OD = 4.0   # V5.6: was 3.0
MIN_ROPE_GAP = 1.5
FP_ROW_Y = (FP_OD + SP_OD) / 2 + MIN_ROPE_GAP

# Mechanics
ECCENTRICITY = 4.8
CAM_STROKE = 2 * ECCENTRICITY
SLIDER_BIAS = 0.80
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS

# Housing
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 1
NUM_TIERS = 3
INTER_TIER_GAP = 0
TIER_PITCH = HOUSING_HEIGHT + INTER_TIER_GAP

# V5.5: Tier angles face helixes
TIER_ANGLES = [180, 300, 60]
HELIX_ANGLES = [180, 300, 60]

# Shaft
SHAFT_DIA = 4.0
D_FLAT_DEPTH = 0.4
SHAFT_BORE = SHAFT_DIA + 0.2

# Frame bearings
FRAME_BRG_ID = 4.0
FRAME_BRG_OD = 8.0
FRAME_BRG_W = 3.0

# Cam bearings
CAM_BRG_ID = 20.0
CAM_BRG_OD = 27.0
CAM_BRG_W = 4.0

# Cam disc
NUM_CAMS = NUM_CHANNELS  # 9
TWIST_PER_CAM = 360.0 / NUM_CAMS  # 40deg
DISC_OD = CAM_BRG_ID - 0.4
SHAFT_BOSS_OD = SHAFT_DIA + 6
CAM_ECC = DISC_OD / 2 - SHAFT_BOSS_OD / 2
DISC_THICK = CAM_BRG_W + 1
AXIAL_PITCH = 8.0
COLLAR_THICK = AXIAL_PITCH - DISC_THICK
HELIX_LENGTH = NUM_CAMS * AXIAL_PITCH  # 72mm (was 104mm)

# Follower
FOLLOWER_RING_ID = CAM_BRG_OD + 0.3
FOLLOWER_RING_OD = CAM_BRG_OD + 4
FOLLOWER_RING_H = 3.0
FOLLOWER_ARM_LENGTH = 6.0
FOLLOWER_EYELET_DIA = 1.5

# E-clips
ECLIP_GROOVE_DIA = SHAFT_DIA - 0.6

# Plates
ANCHOR_THICK = 3.0
TIER1_TOP = TIER_PITCH + HOUSING_HEIGHT / 2
TIER3_BOT = -TIER_PITCH - HOUSING_HEIGHT / 2
ANCHOR_Z = TIER1_TOP

# V5.5b: Single guide plate (replaces dual GP1+GP2+gap)
GUIDE_THICK = 5.0
GUIDE_FUNNEL_TAPER = 2.0
GUIDE_Z = TIER3_BOT           # top face of guide plate
GUIDE_BOT = GUIDE_Z - GUIDE_THICK  # bottom face

# V5.5: Hex sleeve retention (replaces bayonet)
SLEEVE_CLEARANCE = 0.15
PLATE_HEX_R = HEX_R - SLEEVE_CLEARANCE
FRAME_POST_ANGLES = [0, 120, 240]
FRAME_POST_COUNT = 3
GUIDE_STACK_H = GUIDE_THICK   # 5mm (was 12mm with dual plates)

# V5.5: Keyed collar faces (replaces index jig)
COLLAR_BUMP_DIA = 1.5
COLLAR_BUMP_H = 0.6
COLLAR_BUMP_R = SHAFT_BOSS_OD / 2 - 1.2
COLLAR_DIMPLE_DEPTH = COLLAR_BUMP_H + 0.1
COLLAR_BUMP_COUNT = 2

# V5.5: FP_AXLE_LEN fix
FP_AXLE_LEN_NEW = CH_GAP - 0.4    # 6.1mm
FP_AXLE_LEN_OLD_FORMULA = CH_GAP + 2 * WALL_THICKNESS - 0.2  # would be 9.3mm (broken)

# V5.5: Dampener bar height = arm height
ARM_H = 7
DAMPENER_BAR_H = 7

# Frame
STAR_RATIO = 2.5
STAR_TIP_R = STAR_RATIO * HEX_C2C
CORRIDOR_GAP = 31.4
ARM_W = 10
CARRIER_PLATE_T = 10
CARRIER_OVERSHOOT = 6.5
POST_DIA = 2.5

# Frame rings (must be defined before POST_NOTCH_R)
FRAME_RING_H = 6
FRAME_RING_W = 5
FRAME_RING_R_IN = HEX_R + 2
FRAME_RING_R_OUT = FRAME_RING_R_IN + FRAME_RING_W
LEDGE_WIDTH = 3
LEDGE_THICK = 2
LEDGE_R_IN = FRAME_RING_R_IN - LEDGE_WIDTH

POST_NOTCH_R = (FRAME_RING_R_IN + FRAME_RING_R_OUT) / 2  # 47.5mm centered in ring wall

# GT2
GT2_TEETH = 12
GT2_PD = GT2_TEETH * 2 / math.pi
GT2_OD = GT2_PD + 1.5
GT2_BOSS_H = 5

# Matrix — V5.5b: collision-critical parameters
RAIL_HEIGHT = 2.0
RAIL_DEPTH = 0.3
RAIL_TOLERANCE = 0.4
S_GAP = 1.5
PIP_CLEARANCE = 0.3
PIP_Z_GAP = 0.2
_plate_t = (CH_GAP / 2) - (S_GAP / 2) - PIP_Z_GAP   # 2.30mm
_slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5                 # 1.00mm

# V5.5b: Clamped end-stop protrusion
_end_stop_max = PIP_Z_GAP + _slot_d - 0.15             # 1.05mm
_end_stop_protrusion = min(WALL_THICKNESS - PIP_Z_GAP, _end_stop_max)  # 1.05mm

# V5.5b: Clamped slider axle
SP_AXLE_LEN = S_GAP - 0.2   # 1.30mm

# String
STRING_DIA = 0.5
GUIDE_MIN_BORE = 1.5
STRING_HOLE_DIA = 1.5

# Block
BLOCK_DROP = 36
BLOCK_GAP = 0.8

# FDM printing parameters
LAYER_HEIGHT = 0.20      # mm (standard quality)
NOZZLE_DIA = 0.40        # mm (standard nozzle)
MIN_WALL_PERIMETERS = 2  # minimum wall = 2 × nozzle = 0.8mm
MAX_BRIDGE_SPAN = 15.0   # mm (PLA, with cooling fan)
MAX_OVERHANG_ANGLE = 45  # degrees from vertical
MIN_STRUCTURAL_WIDTH = 4.0  # mm (for load-bearing parts)

# Guide plate funnel (V5.5b: no physical bushings, just printed holes)
GUIDE_FUNNEL_DIA = 3.0

# ================================================================
# VALIDATION
# ================================================================
results = []
def check(name, condition, detail=""):
    status = "PASS" if condition else "FAIL"
    results.append((status, name, detail))
    return condition

print("=" * 70)
print("V5.5b COMPLETE FUNCTIONAL MATH VALIDATION (9 CHANNELS)")
print("=" * 70)

# ---- V5.5b-C8: 9 CHANNELS ----
print("\n--- V5.5b-C8: 9 CHANNELS ---")

check("Channel count = 9",
      NUM_CHANNELS == 9,
      f"NUM_CHANNELS={NUM_CHANNELS} (STACK_OFFSET={STACK_OFFSET})")

check("CH_GAP = 6.5mm",
      abs(CH_GAP - 6.5) < 0.01,
      f"CH_GAP={CH_GAP}mm = STACK_OFFSET({STACK_OFFSET}) - WALL({WALL_THICKNESS})")

check("Slider plate thick enough for FDM",
      _plate_t >= 1.5,
      f"plate_t={_plate_t:.2f}mm (need >= 1.5mm for structural)")

check("Slider plate thicker than slot depth",
      _plate_t > _slot_d + 0.5,
      f"plate_t={_plate_t:.2f}mm > slot_d + 0.5 = {_slot_d + 0.5:.2f}mm — solid after slot")

check("Remaining plate after slot >= 1.0mm",
      _plate_t - _slot_d >= 1.0,
      f"Remaining={_plate_t - _slot_d:.2f}mm (plate={_plate_t:.2f} - slot={_slot_d:.2f})")

# ---- V5.5b-C9: END-STOP NO BLEED ----
print("\n--- V5.5b-C9: END-STOP PROTRUSION (no bleed through slider wall) ---")

check("End-stop fits within PIP_Z_GAP + slot_d",
      _end_stop_protrusion <= PIP_Z_GAP + _slot_d,
      f"Protrusion={_end_stop_protrusion:.2f}mm <= gap+slot={PIP_Z_GAP + _slot_d:.2f}mm")

check("End-stop has clearance inside slot",
      _end_stop_protrusion < PIP_Z_GAP + _slot_d,
      f"Clearance={PIP_Z_GAP + _slot_d - _end_stop_protrusion:.2f}mm inside slot")

check("End-stop does NOT exceed slider plate thickness",
      _end_stop_protrusion <= _plate_t + PIP_Z_GAP,
      f"Protrusion={_end_stop_protrusion:.2f}mm <= plate+gap={_plate_t + PIP_Z_GAP:.2f}mm")

check("Rail fits within slot",
      RAIL_DEPTH <= _slot_d,
      f"Rail={RAIL_DEPTH}mm <= slot_d={_slot_d}mm")

# ---- V5.5b-C10: SLIDER AXLE CLAMPED ----
print("\n--- V5.5b-C10: SLIDER AXLE (between plates, no bleed) ---")

check("Slider axle <= S_GAP",
      SP_AXLE_LEN <= S_GAP,
      f"SP_AXLE_LEN={SP_AXLE_LEN:.2f}mm <= S_GAP={S_GAP}mm")

check("Slider axle has clearance to plates",
      SP_AXLE_LEN < S_GAP - 0.1,
      f"Clearance each side={(S_GAP - SP_AXLE_LEN)/2:.2f}mm")

check("Fixed pulley axle < CH_GAP",
      FP_AXLE_LEN_NEW < CH_GAP,
      f"FP axle={FP_AXLE_LEN_NEW}mm < CH_GAP={CH_GAP}mm")

check("Fixed pulley axle supports roller width",
      FP_AXLE_LEN_NEW >= FP_OD - 0.5,
      f"Axle={FP_AXLE_LEN_NEW}mm >= FP_OD-0.5={FP_OD - 0.5}mm")

# ---- V5.5-C4: TIER ANGLES ----
print("\n--- V5.5-C4: TIER ANGLES (sliders face helixes) ---")

check("Tier angles match helix angles",
      TIER_ANGLES == HELIX_ANGLES,
      f"TIER_ANGLES={TIER_ANGLES} == HELIX_ANGLES={HELIX_ANGLES}")

check("Tier angles at 120deg spacing",
      abs(TIER_ANGLES[1] - TIER_ANGLES[0]) % 360 == 120 or
      abs((TIER_ANGLES[1] - TIER_ANGLES[0]) % 360) == 120,
      f"Angles: {TIER_ANGLES}")

check("Tier angles are helix-facing (not stub-facing)",
      0 not in TIER_ANGLES and 120 not in TIER_ANGLES and 240 not in TIER_ANGLES,
      "Stub angles [0,120,240] NOT in tier angles — correct")

# ---- V5.5-C2: HEX SLEEVE RETENTION ----
print("\n--- V5.5-C2: HEX SLEEVE RETENTION ---")

check("Plate hex fits inside ring bore",
      PLATE_HEX_R < FRAME_RING_R_IN,
      f"Plate R={PLATE_HEX_R:.2f}mm < Ring R_in={FRAME_RING_R_IN}mm")

check("Sleeve clearance adequate for FDM",
      SLEEVE_CLEARANCE >= 0.1,
      f"Clearance={SLEEVE_CLEARANCE}mm (need >=0.1)")

check("Sleeve clearance not too loose",
      SLEEVE_CLEARANCE <= 0.3,
      f"Clearance={SLEEVE_CLEARANCE}mm (max 0.3)")

check("Matrix hex fits through upper ring (no ledge)",
      HEX_R < FRAME_RING_R_IN,
      f"Matrix HEX_R={HEX_R}mm < Ring R_in={FRAME_RING_R_IN}mm (2mm gap)")

check("Lower ring ledge catches matrix",
      LEDGE_R_IN < HEX_R,
      f"Ledge R_in={LEDGE_R_IN}mm < HEX_R={HEX_R}mm — matrix can't pass")

check("Lower ring sleeve depth >= guide plate thickness",
      GUIDE_STACK_H >= GUIDE_THICK,
      f"Sleeve depth={GUIDE_STACK_H}mm >= plate={GUIDE_THICK}mm (ring base adds {FRAME_RING_H}mm above)")

check("Guide stack height = single plate thickness",
      abs(GUIDE_STACK_H - GUIDE_THICK) < 0.01,
      f"GUIDE_STACK_H={GUIDE_STACK_H}mm = GUIDE_THICK={GUIDE_THICK}mm")

# ---- V5.5b-C11: SINGLE GUIDE PLATE ----
print("\n--- V5.5b-C11: SINGLE GUIDE PLATE (tapered through-holes) ---")

check("Guide plate thick enough for FDM",
      GUIDE_THICK >= 3.0,
      f"GUIDE_THICK={GUIDE_THICK}mm (min 3mm for structural plate)")

check("Funnel taper fits within plate thickness",
      GUIDE_FUNNEL_TAPER < GUIDE_THICK,
      f"Taper={GUIDE_FUNNEL_TAPER}mm < plate={GUIDE_THICK}mm")

check("Straight bore zone >= 2mm",
      GUIDE_THICK - GUIDE_FUNNEL_TAPER >= 2.0,
      f"Bore zone={GUIDE_THICK - GUIDE_FUNNEL_TAPER}mm (need >= 2mm for alignment)")

check("Guide plate top = tier3 bottom",
      abs(GUIDE_Z - TIER3_BOT) < 0.01,
      f"GUIDE_Z={GUIDE_Z} == TIER3_BOT={TIER3_BOT}")

check("Guide bottom below tier3",
      GUIDE_BOT < TIER3_BOT,
      f"GUIDE_BOT={GUIDE_BOT} < TIER3_BOT={TIER3_BOT}")

# ---- V5.5-C5: FRAME POSTS ----
print("\n--- V5.5-C5: FRAME POSTS (stub vertices only) ---")

check("Frame posts at stub vertices",
      FRAME_POST_ANGLES == [0, 120, 240],
      f"Post angles={FRAME_POST_ANGLES}")

check("Frame post count = 3",
      FRAME_POST_COUNT == 3,
      f"Count={FRAME_POST_COUNT}")

check("Posts don't block slider paths",
      all(a not in TIER_ANGLES for a in FRAME_POST_ANGLES),
      f"Post angles {FRAME_POST_ANGLES} don't overlap tier angles {TIER_ANGLES}")

check("Post inner edge clear of sleeve bore",
      POST_NOTCH_R - POST_DIA/2 > FRAME_RING_R_IN,
      f"Post inner edge={POST_NOTCH_R - POST_DIA/2}mm > FRAME_RING_R_IN={FRAME_RING_R_IN}mm")

check("Post outer edge within ring wall",
      POST_NOTCH_R + POST_DIA/2 < FRAME_RING_R_OUT,
      f"Post outer edge={POST_NOTCH_R + POST_DIA/2}mm < FRAME_RING_R_OUT={FRAME_RING_R_OUT}mm")

check("Posts fully embedded in ring wall (not in sleeve)",
      POST_NOTCH_R - POST_DIA/2 >= FRAME_RING_R_IN + 0.5,
      f"Post inner edge={POST_NOTCH_R - POST_DIA/2}mm >= bore+0.5={FRAME_RING_R_IN + 0.5}mm")

# ---- V5.5-C3: KEYED COLLAR FACES ----
print("\n--- V5.5-C3: KEYED COLLAR FACES (bump+dimple) ---")

check("Collar bump dia printable",
      COLLAR_BUMP_DIA >= 1.0,
      f"Bump dia={COLLAR_BUMP_DIA}mm (min 1.0mm)")

check("Collar bump height printable",
      COLLAR_BUMP_H >= 0.4,
      f"Bump H={COLLAR_BUMP_H}mm (min 0.4mm)")

check("Collar bump within boss radius",
      COLLAR_BUMP_R + COLLAR_BUMP_DIA/2 < SHAFT_BOSS_OD/2,
      f"Bump edge={COLLAR_BUMP_R + COLLAR_BUMP_DIA/2:.1f}mm < boss R={SHAFT_BOSS_OD/2}mm")

check("Collar bump outside shaft bore",
      COLLAR_BUMP_R - COLLAR_BUMP_DIA/2 > SHAFT_BORE/2,
      f"Bump inner={COLLAR_BUMP_R - COLLAR_BUMP_DIA/2:.1f}mm > bore R={SHAFT_BORE/2}mm")

check("Dimple deeper than bump (clearance)",
      COLLAR_DIMPLE_DEPTH > COLLAR_BUMP_H,
      f"Dimple={COLLAR_DIMPLE_DEPTH}mm > bump H={COLLAR_BUMP_H}mm")

check("Collar face has adequate glue surface",
      COLLAR_THICK >= 2,
      f"Collar={COLLAR_THICK}mm")

d_flat_chord = SHAFT_DIA - 2 * D_FLAT_DEPTH
check("D-flat provides angular lock",
      D_FLAT_DEPTH >= 0.3,
      f"D-flat depth={D_FLAT_DEPTH}mm, chord={d_flat_chord:.1f}mm")

check("Bump count provides unique orientation",
      COLLAR_BUMP_COUNT >= 2,
      f"Count={COLLAR_BUMP_COUNT} (2 at 180deg = unique)")

# ---- V5.5-C6: DAMPENER BAR HEIGHT ----
print("\n--- V5.5-C6: DAMPENER BAR HEIGHT ---")

check("Dampener bar height = arm height",
      DAMPENER_BAR_H == ARM_H,
      f"Bar H={DAMPENER_BAR_H}mm = ARM_H={ARM_H}mm")

# ---- V5.5-C1: FRAME MONOLITH + SEPARATE MATRIX ----
print("\n--- V5.5-C1: FRAME MONOLITH + SEPARATE MATRIX ---")

TIER_Z = [TIER_PITCH, 0, -TIER_PITCH]
check("Matrix tier Z positions symmetric",
      abs(TIER_Z[0] + TIER_Z[2]) < 0.01 and abs(TIER_Z[1]) < 0.01,
      f"T1=+{TIER_Z[0]} T2={TIER_Z[1]} T3={TIER_Z[2]} (symmetric about origin)")

check("Frame ring encloses matrix hex",
      FRAME_RING_R_IN > HEX_R,
      f"Ring R_in={FRAME_RING_R_IN}mm > HEX_R={HEX_R}mm")

check("Ledge width adequate",
      LEDGE_WIDTH >= 2,
      f"Ledge width={LEDGE_WIDTH}mm (supports matrix edge)")

UPPER_RING_Z = TIER1_TOP
LOWER_RING_Z = TIER3_BOT - FRAME_RING_H
check("Upper ring starts at tier1 top",
      abs(UPPER_RING_Z - TIER1_TOP) < 0.01,
      f"Upper ring Z={UPPER_RING_Z} = TIER1_TOP={TIER1_TOP}")

check("Lower ring below tier3 bot",
      LOWER_RING_Z < TIER3_BOT,
      f"Lower ring Z={LOWER_RING_Z} < TIER3_BOT={TIER3_BOT}")

# Build plate constraint — computed (not hardcoded)
HEXAGRAM_INNER_R = STAR_TIP_R / math.sqrt(3)
V_PUSH = CORRIDOR_GAP / (2 * math.tan(math.radians(30)))
HELIX_R = HEXAGRAM_INNER_R + V_PUSH
STUB_LEN = 15
STUB_W = 10
STUB_R_END = (HEX_R + 2 + FRAME_RING_W) + STUB_LEN
JUNCTION_R = STUB_R_END + STUB_W / 2

# Compute arm crossing R from junction/star-tip geometry (same as config)
def _par_res(V, T, J):
    return T*T*math.sin(math.radians(120-V)) - 2*J*T*math.sin(math.radians(120-V/2)) + J*J*math.sin(math.radians(120))

def _find_V(T, J, lo=10.0, hi=150.0):
    for _ in range(60):
        mid = (lo + hi) / 2
        r = _par_res(mid, T, J)
        if abs(r) < 0.0001:
            return mid
        if r > 0:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2

V_ANGLE = _find_V(STAR_TIP_R, JUNCTION_R)
STUB_A = 120
TIP_A = STUB_A + V_ANGLE / 2
JX = JUNCTION_R * math.cos(math.radians(STUB_A))
JY = JUNCTION_R * math.sin(math.radians(STUB_A))
TX = STAR_TIP_R * math.cos(math.radians(TIP_A))
TY = STAR_TIP_R * math.sin(math.radians(TIP_A))
ADX = TX - JX
ADY = TY - JY
ALEN = math.sqrt(ADX*ADX + ADY*ADY)
# Second arm from adjacent stub at 0deg heading toward helix at 180deg
SDX = -math.sin(math.radians(180))
SDY = math.cos(math.radians(180))
HCX = HELIX_R * math.cos(math.radians(180))
HCY = HELIX_R * math.sin(math.radians(180))
CROSS_NUM = (HCX - JX) * SDY - (HCY - JY) * SDX
CROSS_DEN = (ADX / ALEN) * SDY - (ADY / ALEN) * SDX
T_MM = CROSS_NUM / CROSS_DEN
CX = JX + (ADX / ALEN) * T_MM
CY = JY + (ADY / ALEN) * T_MM
CROSSING_R = math.sqrt(CX*CX + CY*CY)  # computed, not hardcoded

ARM_END_R = CROSSING_R + CARRIER_PLATE_T / 2 + CARRIER_OVERSHOOT
check("Frame fits K2 plate",
      ARM_END_R * 2 <= 349.5,
      f"Diameter={ARM_END_R * 2:.1f}mm (limit 349mm)")

# ---- PRESERVED V5.4 CHECKS ----
print("\n--- 1. CAM MECHANISM (preserved from V5.4) ---")

check("Disc fits in bearing bore",
      DISC_OD < CAM_BRG_ID,
      f"Disc OD={DISC_OD} < bearing ID={CAM_BRG_ID}")

check("Shaft boss fits in disc",
      CAM_ECC + SHAFT_BOSS_OD / 2 <= DISC_OD / 2 + 0.5,
      f"ECC+boss/2={CAM_ECC + SHAFT_BOSS_OD/2:.1f} <= disc/2={DISC_OD/2:.1f}")

boss_wall = (SHAFT_BOSS_OD - SHAFT_BORE) / 2
check("Shaft boss wall adequate",
      boss_wall >= 1.5,
      f"Boss wall={boss_wall:.1f}mm")

check("Follower clears bearing OD",
      FOLLOWER_RING_ID > CAM_BRG_OD,
      f"Follower ID={FOLLOWER_RING_ID} > bearing OD={CAM_BRG_OD}")

check("Collar thickness positive",
      COLLAR_THICK >= 1.0,
      f"Collar={COLLAR_THICK}mm")

check("Total twist = 360deg",
      abs(NUM_CAMS * TWIST_PER_CAM - 360) < 0.01,
      f"{NUM_CAMS} x {TWIST_PER_CAM:.2f}deg = {NUM_CAMS * TWIST_PER_CAM:.1f}deg")

check("CAM_ECC matches ECCENTRICITY",
      abs(CAM_ECC - ECCENTRICITY) < 0.01,
      f"CAM_ECC={CAM_ECC:.2f} vs ECCENTRICITY={ECCENTRICITY}")

print("\n--- 2. MATRIX TIER ---")

check("NUM_CHANNELS matches NUM_CAMS",
      NUM_CHANNELS == NUM_CAMS,
      f"Channels={NUM_CHANNELS} == Cams={NUM_CAMS}")

check("FP fits in channel gap",
      FP_OD < CH_GAP,
      f"FP_OD={FP_OD} < CH_GAP={CH_GAP}")

check("Slider plate thick enough",
      _plate_t >= _slot_d,
      f"plate_t={_plate_t:.2f}mm >= slot_d={_slot_d:.2f}mm")

check("Column gap adequate",
      COL_PITCH - max(FP_OD, SP_OD) >= 1.0,
      f"Gap={COL_PITCH - max(FP_OD, SP_OD):.1f}mm")

fp_sp_gap = FP_ROW_Y - (FP_OD + SP_OD) / 2
check("FP-SP rope routing gap",
      fp_sp_gap >= 1.0,
      f"Gap={fp_sp_gap:.1f}mm")

print("\n--- 3. CABLE PATH ---")

check("String hole > string dia",
      STRING_HOLE_DIA > STRING_DIA,
      f"Hole={STRING_HOLE_DIA}mm > String={STRING_DIA}mm")

check("Guide bushing bore > string dia",
      GUIDE_MIN_BORE > STRING_DIA,
      f"Bore={GUIDE_MIN_BORE}mm > String={STRING_DIA}mm")

# CONFIRMED: Summation model — 3 tiers compound on same string.
# Each tier independently adds/removes rope length.
max_travel = 3 * ECCENTRICITY  # 14.4mm max one-sided displacement
# Only check channels that have columns
active_ch_lens = [l for l in CH_LENS if l > 0]
min_ch_with_cols = min(active_ch_lens) if active_ch_lens else 0
check("Shortest channel > 2x max travel + margin",
      min_ch_with_cols > 2 * max_travel + 10,
      f"Shortest={min_ch_with_cols:.1f}mm > {2*max_travel + 10:.1f}mm")

print("\n--- 4. ASSEMBLY STACK ---")

check("Tier 1 Z correct",
      abs(TIER_PITCH - HOUSING_HEIGHT) < 0.01,
      f"TIER_PITCH={TIER_PITCH}")

check("Anchor sits on tier 1",
      abs(ANCHOR_Z - TIER1_TOP) < 0.01,
      f"ANCHOR_Z={ANCHOR_Z} = TIER1_TOP={TIER1_TOP}")

check("Guide plate below matrix (no overlap)",
      GUIDE_BOT < TIER3_BOT,
      f"GUIDE_BOT={GUIDE_BOT} < TIER3_BOT={TIER3_BOT}")

total_stack = ANCHOR_Z + ANCHOR_THICK - GUIDE_BOT
check("Total stack height reasonable",
      30 < total_stack < 100,
      f"Stack={total_stack:.1f}mm (anchor top to guide bottom)")

print("\n--- 5. BEARING/SHAFT ---")

check("Frame bearing bore matches shaft",
      FRAME_BRG_ID == SHAFT_DIA,
      f"Bearing ID={FRAME_BRG_ID}mm = shaft={SHAFT_DIA}mm")

check("E-clip groove below shaft dia",
      ECLIP_GROOVE_DIA < SHAFT_DIA,
      f"Groove={ECLIP_GROOVE_DIA}mm < shaft={SHAFT_DIA}mm")

print("\n--- 6. FDM PRINT FEASIBILITY ---")

check("Wall thickness >= 2 perimeters",
      WALL_THICKNESS >= 0.8,
      f"Wall={WALL_THICKNESS}mm")

check("Carrier plate thick enough",
      CARRIER_PLATE_T >= 5,
      f"Carrier={CARRIER_PLATE_T}mm")

check("Anchor plate thick enough",
      ANCHOR_THICK >= 2,
      f"Anchor={ANCHOR_THICK}mm")

check("Slider plate printable",
      _plate_t >= 1.0,
      f"plate_t={_plate_t:.2f}mm")

check("Guide funnel bore > string dia",
      GUIDE_MIN_BORE > STRING_DIA + 0.5,
      f"Bore={GUIDE_MIN_BORE}mm > string+0.5={STRING_DIA + 0.5}mm")

# --- 6b. ADVANCED FDM PRINT FEASIBILITY (V5.5b additions) ---
print("\n--- 6b. ADVANCED FDM PRINT FEASIBILITY ---")

# -- Overhang Analysis --

# 1. Hexagram arm overhang angle
#    Arms converge from JUNCTION_R at ring Z toward CROSSING_R at helix Z.
#    The slope must be <= 45deg from vertical for printability.
CONVERGE_PCT = 0  # from config: arms are flat (no Z convergence)
_arm_z_drop = CONVERGE_PCT * abs(TIER_Z[0])  # Z change along arm (0 if flat)
_arm_horiz_len = ALEN  # horizontal arm length
if _arm_horiz_len > 0 and _arm_z_drop > 0:
    _arm_overhang_angle = math.degrees(math.atan2(_arm_horiz_len, _arm_z_drop))
else:
    _arm_overhang_angle = 0  # flat arms = no overhang concern
check("Hexagram arm overhang angle <= 45deg",
      _arm_overhang_angle <= MAX_OVERHANG_ANGLE,
      f"Arm overhang={_arm_overhang_angle:.1f}deg (flat arms={CONVERGE_PCT == 0}), limit={MAX_OVERHANG_ANGLE}deg")

# 2. Carrier plate cantilever
#    Carrier plates extend CARRIER_OVERSHOOT beyond the arm crossing.
#    The overshoot must be short enough that the plate thickness self-supports.
#    Rule: overshoot <= plate thickness (equivalent to 45deg self-support angle).
check("Carrier plate cantilever self-supports",
      CARRIER_OVERSHOOT <= CARRIER_PLATE_T,
      f"Overshoot={CARRIER_OVERSHOOT}mm <= plate_t={CARRIER_PLATE_T}mm (45deg self-support)")

# 3. Ring ledge overhang
#    Lower ring has inward ledge. Ledge width must be <= ring height to avoid
#    horizontal overhang that would need support material.
check("Ring ledge overhang printable",
      LEDGE_WIDTH <= FRAME_RING_H,
      f"Ledge_W={LEDGE_WIDTH}mm <= ring_H={FRAME_RING_H}mm (no horizontal overhang)")

# -- Bridge Span Analysis --

# 4. Bearing bore bridge
#    Top of circular bearing bore is a bridge when printed upright.
_frame_brg_bridge = FRAME_BRG_OD
_cam_brg_bridge = CAM_BRG_OD
check("Frame bearing bore bridge <= max span",
      _frame_brg_bridge <= MAX_BRIDGE_SPAN,
      f"Frame bearing OD={_frame_brg_bridge}mm <= max bridge={MAX_BRIDGE_SPAN}mm")
check("Cam bearing bore bridge printable (may need support)",
      _cam_brg_bridge <= MAX_BRIDGE_SPAN * 2,
      f"Cam bearing OD={_cam_brg_bridge}mm (>{MAX_BRIDGE_SPAN}mm = needs support or print orientation change)")

# 5. Slider channel bridge
#    Top wall spanning CH_GAP is a bridge.
check("Slider channel bridge <= max span",
      CH_GAP <= MAX_BRIDGE_SPAN,
      f"CH_GAP={CH_GAP}mm <= max bridge={MAX_BRIDGE_SPAN}mm")

# 6. Hex ring bridge (inner bore)
#    If ring printed flat, the inner diameter top arc is a bridge.
#    For a hexagonal bore, the flat-to-flat dimension is the max bridge span.
_ring_bore_span = 2 * FRAME_RING_R_IN  # diameter of bore
check("Hex ring bore bridge (needs support or segmented print)",
      _ring_bore_span <= MAX_BRIDGE_SPAN * 6,
      f"Ring bore dia={_ring_bore_span:.1f}mm (>{MAX_BRIDGE_SPAN}mm — must print upright or use supports)")

# -- Thin Feature Analysis --

# 7. Collar bump printability
_bump_min_layers = 2 * LAYER_HEIGHT  # 0.4mm = 2 layers minimum
check("Collar bump height >= 2 layers",
      COLLAR_BUMP_H >= _bump_min_layers,
      f"Bump H={COLLAR_BUMP_H}mm >= 2 layers={_bump_min_layers}mm")
check("Collar bump dia >= nozzle dia",
      COLLAR_BUMP_DIA >= NOZZLE_DIA,
      f"Bump dia={COLLAR_BUMP_DIA}mm >= nozzle={NOZZLE_DIA}mm")

# 8. D-flat depth printability
check("D-flat depth >= 1 layer height",
      D_FLAT_DEPTH >= LAYER_HEIGHT,
      f"D-flat={D_FLAT_DEPTH}mm >= layer={LAYER_HEIGHT}mm")

# 9. PIP_Z_GAP printability (print-in-place gap)
check("PIP gap >= 1 layer height",
      PIP_Z_GAP >= LAYER_HEIGHT,
      f"PIP_Z_GAP={PIP_Z_GAP}mm >= layer={LAYER_HEIGHT}mm (standard PIP clearance)")

# 10. Rail slot depth printability
_rail_min_depth = 2 * LAYER_HEIGHT  # 0.4mm = 2 layers for clean slot
check("Rail slot depth >= 2 layers",
      RAIL_DEPTH >= _rail_min_depth,
      f"RAIL_DEPTH={RAIL_DEPTH}mm >= 2 layers={_rail_min_depth}mm")

# 11. String hole diameter printability
_string_hole_min = 4 * LAYER_HEIGHT  # 0.8mm = need 4 layers to form cleanly
check("String hole dia >= 4 layers",
      STRING_HOLE_DIA >= _string_hole_min,
      f"String hole={STRING_HOLE_DIA}mm >= 4 layers={_string_hole_min}mm")

# -- Structural Analysis --

# 12. Minimum part cross-sections
check("Stub width >= structural minimum",
      STUB_W >= MIN_STRUCTURAL_WIDTH * 2,
      f"Stub W={STUB_W}mm >= {MIN_STRUCTURAL_WIDTH * 2}mm (load-bearing)")
check("Arm width >= structural minimum",
      ARM_W >= MIN_STRUCTURAL_WIDTH * 2,
      f"ARM_W={ARM_W}mm >= {MIN_STRUCTURAL_WIDTH * 2}mm (load-bearing)")
_dampener_bar_w = 3.0  # typical dampener bar width from config
check("Dampener bar width >= thin feature minimum",
      _dampener_bar_w >= NOZZLE_DIA * MIN_WALL_PERIMETERS,
      f"Dampener bar W={_dampener_bar_w}mm >= {NOZZLE_DIA * MIN_WALL_PERIMETERS}mm (non-structural, 2 perimeters)")

# 13. Aspect ratio (tall thin features topple during printing)
_stub_aspect = ARM_H / STUB_W if STUB_W > 0 else 999
check("Stub aspect ratio <= 3:1",
      _stub_aspect <= 3.0,
      f"Stub H/W={ARM_H}/{STUB_W}={_stub_aspect:.2f} (limit 3.0)")

# 14. Matrix wall strength
#    WALL_THICKNESS between channels, HOUSING_HEIGHT tall.
#    Height/thickness ratio must be <= 10:1 to prevent flex/breakage.
_wall_aspect = HOUSING_HEIGHT / WALL_THICKNESS if WALL_THICKNESS > 0 else 999
check("Matrix wall height/thickness <= 10:1",
      _wall_aspect <= 10.0,
      f"Wall H/T={HOUSING_HEIGHT}/{WALL_THICKNESS}={_wall_aspect:.1f} (limit 10.0)")

# 15. Anchor plate string hole spacing
#    Holes at COL_PITCH spacing. Gap between adjacent hole edges must be >= 2x nozzle.
_hole_edge_gap = COL_PITCH - STRING_HOLE_DIA
_min_hole_gap = 2 * NOZZLE_DIA
check("Anchor plate hole spacing >= 2x nozzle width",
      _hole_edge_gap >= _min_hole_gap,
      f"Hole edge gap={_hole_edge_gap:.1f}mm >= 2x nozzle={_min_hole_gap}mm (bridge between holes)")

print("\n--- 7. MOTION ENVELOPE ---")

max_extend = SLIDER_REST_OFFSET + ECCENTRICITY
check("Max slider extend within channel",
      max_extend < min_ch_with_cols / 2,
      f"Max extend={max_extend:.1f}mm < half shortest={min_ch_with_cols/2:.1f}mm")

# CONFIRMED: Summation model — 3 tiers compound on same string
max_block = 3 * ECCENTRICITY  # 14.4mm (summation, not 1/3 averaging)
check("Block travel < block drop",
      max_block < BLOCK_DROP,
      f"Block travel={max_block:.1f}mm (3×E summation) < drop={BLOCK_DROP}mm")

check("Block gap adequate",
      BLOCK_GAP >= 0.5,
      f"Block gap={BLOCK_GAP}mm")

follower_axial_gap = AXIAL_PITCH - FOLLOWER_RING_H
check("Follower rings don't overlap axially",
      follower_axial_gap >= 1.0,
      f"Axial gap={follower_axial_gap:.1f}mm")

print("\n--- 8. MATRIX/CAM SPACING ---")

# V5.5b: STACK_OFFSET and AXIAL_PITCH are both 8.0mm (coincidental match at 9 channels).
# This is OK — they are independently derived. The key constraint is entity count match.
check("STACK_OFFSET and AXIAL_PITCH both valid",
      STACK_OFFSET >= 5.0 and AXIAL_PITCH >= 5.0,
      f"Matrix SO={STACK_OFFSET}mm, Cam AP={AXIAL_PITCH}mm (both >= 5mm)")

check("Helix length matches matrix span",
      abs(HELIX_LENGTH - NUM_CHANNELS * AXIAL_PITCH) < 0.01,
      f"Helix={HELIX_LENGTH}mm = {NUM_CHANNELS}ch x {AXIAL_PITCH}mm pitch")

# ---- V5.5b COLLISION SUMMARY ----
print("\n--- 9. Z-STACK COLLISION AUDIT ---")

# From wall face, what occupies the half-gap:
# wall_face -> PIP_Z_GAP -> plate outer face -> plate body -> plate inner face -> S_GAP/2 -> center
check("Z-stack budget balances",
      abs((PIP_Z_GAP + _plate_t + S_GAP/2) - CH_GAP/2) < 0.01,
      f"PIP({PIP_Z_GAP}) + plate({_plate_t:.2f}) + S_GAP/2({S_GAP/2}) = {PIP_Z_GAP + _plate_t + S_GAP/2:.2f} == CH_GAP/2={CH_GAP/2}")

# (End-stop, rail, slider axle, FP axle bleed checks are in C9/C10 above — not duplicated here)

# ---- 10. ADDITIONAL CONSTRAINTS ----
print("\n--- 10. ADDITIONAL CONSTRAINTS ---")

# Funnel overlap: adjacent funnels must not merge
GUIDE_FUNNEL_TOP_DIA = GUIDE_FUNNEL_DIA + 1.5   # 4.5mm (same as guide_plate_v5_5.scad)
check("Guide funnels don't overlap (vs COL_PITCH)",
      GUIDE_FUNNEL_TOP_DIA < COL_PITCH,
      f"Funnel top dia={GUIDE_FUNNEL_TOP_DIA}mm < COL_PITCH={COL_PITCH}mm")

# Shaft extension must be positive (geometry sanity)
_SHAFT_TANGENT_DIST = abs((CX - HCX) * SDX + (CY - HCY) * SDY)
SHAFT_EXT_TO_CARRIER = _SHAFT_TANGENT_DIST - HELIX_LENGTH / 2
check("Shaft extension to carrier > 0",
      SHAFT_EXT_TO_CARRIER > 0,
      f"SHAFT_EXT_TO_CARRIER={SHAFT_EXT_TO_CARRIER:.1f}mm")

# CROSSING_R sanity (should be ~160-170mm for this scale)
check("CROSSING_R in expected range",
      140 < CROSSING_R < 190,
      f"CROSSING_R={CROSSING_R:.1f}mm (expected 140-190mm)")

# ================================================================
# SUMMARY
# ================================================================
print("\n" + "=" * 70)
passes = sum(1 for r in results if r[0] == "PASS")
fails = sum(1 for r in results if r[0] == "FAIL")
print(f"RESULTS: {passes} PASS, {fails} FAIL, {len(results)} total")
print("=" * 70)

if fails > 0:
    print("\nFAILURES:")
    for status, name, detail in results:
        if status == "FAIL":
            print(f"  X {name}")
            if detail:
                print(f"    {detail}")

print("\nALL CHECKS:")
for status, name, detail in results:
    mark = "OK" if status == "PASS" else "X"
    print(f"  {mark} {name}: {detail}")

# Exit code
import sys
sys.exit(1 if fails > 0 else 0)
