// =========================================================
// CONFIG V5.6 — Single Source of Truth for Triple Helix MVP
// =========================================================
// V5.6 CHANGES FROM V5.5c:
//   C8:  7 channels (STACK_OFFSET 8→10, Rule 99 matrix audit)
//   C9:  FP/SP_OD 3→4mm (8:1 bend ratio for 0.5mm Dyneema)
//   C12: HOUSING_HEIGHT 13→16mm, total stack 39→48mm
//        RAIL_DEPTH 0.3→0.8mm, S_GAP 1.5→3.0mm (FDM fixes)
//
// V5.5c CHANGES (Rule 99 audit):
//   R1: PIP_Z_GAP 0.2→0.35mm (print-in-place clearance for FDM)
//   R2: D_FLAT_DEPTH 0.4→0.6mm (better set screw bite on GT2)
//   R3: CARRIER_BRG_BORE clearance +0.05→+0.15mm (ream-friendly)
//   R4: Dampener bar print support advisory
//   R5: Collar bump hemisphere→cone (FDM-friendly indexing)
//   R6: Dampener holes funneled entry on both faces
//   R7: Follower-to-carrier clearance verification echo
//
// V5.5 CHANGES FROM V5.4:
//   C1: Frame is monolith (rings+stubs+arms+carriers+dampeners)
//   C2: Hex sleeve retention — no bayonet, hex shape locks rotation
//   C3: Face pins REMOVED — D-flat + keyed collar bump/dimple + CA glue
//   C4: TIER_ANGLES fixed to [180,300,60] — sliders face helixes
//   C5: Frame posts only at stub vertices [0,120,240]
//   C6: Dampener bar height unified with arm height
//
// DIMENSIONS:
//   HEX_R=43, DISC_OD=19.6, ECCENTRICITY=4.8, 7 channels,
//   6704ZZ/MR84ZZ bearings, 4mm shaft, 349mm build plate limit.
//
// INCLUDE this file (not `use`) in every V5.6 module.
// =========================================================

// Scale factor (for reference — NOT used in computations)
_SCALE = 0.4831;

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// HEX GEOMETRY — the ONE sizing parameter
// =============================================
/* [Hex Tier] */
HEX_R         = 43;
HEX_C2C       = 2 * HEX_R;
HEX_FF        = HEX_R * sqrt(3);
HEX_LONGEST_DIA = HEX_C2C;

/* [Column Spacing] */
COL_PITCH     = 6;
WALL_MARGIN   = 4;

/* [Channel Stacking] */
STACK_OFFSET  = 10.0;  // V5.6: was 8.0 (9ch). Now 10.0 for 7 channels — Rule 99 matrix audit

// Channel count
function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;  // 7 (V5.6: was 9)

_CENTER_CH = (NUM_CHANNELS - 1) / 2;
CH_OFFSETS = [for (i = [0:NUM_CHANNELS-1]) (i - _CENTER_CH) * STACK_OFFSET];

function hex_w(d) =
    let(max_d = HEX_FF / 2)
    (abs(d) > max_d) ? 0 : 2 * (HEX_R - abs(d) / sqrt(3));

function ch_len(d) = max(0, hex_w(d) - 2 * WALL_MARGIN);

CH_LENS = [for (i = [0:NUM_CHANNELS-1]) ch_len(CH_OFFSETS[i])];

// =============================================
// PULLEY DIMENSIONS
// =============================================
/* [Pulleys] */
FP_OD         = 4.0;   // V5.6: was 3.0 — 8:1 bend ratio for 0.5mm Dyneema
SP_OD         = 4.0;   // V5.6: was 3.0 — 2.4-perimeter walls at 0.4mm nozzle
_MIN_ROPE_GAP = 1.5;
FP_ROW_Y      = (FP_OD + SP_OD) / 2 + _MIN_ROPE_GAP;  // 5.5mm (V5.6: was 4.5)

// =============================================
// PULLEY STAGGER
// =============================================
STAGGER_HALF_PITCH = COL_PITCH / 2;  // 3mm

function _col_x_base(count, idx) =
    -((count - 1) / 2) * COL_PITCH + idx * COL_PITCH;

function _ch_stagger(ch_idx) = (ch_idx % 2) * STAGGER_HALF_PITCH;

function col_x(count, idx, ch_idx=0) =
    _col_x_base(count, idx) + _ch_stagger(ch_idx);

function col_inside_hex(px, d) =
    let(max_od = max(FP_OD, SP_OD))
    (abs(px) + max_od/2 + 1) < (hex_w(d) / 2);

function raw_col_count(len) =
    (len < COL_PITCH) ? ((len > max(FP_OD, SP_OD)) ? 1 : 0) :
    floor(len / COL_PITCH) + 1;

function culled_col_count(ch_idx) =
    let(d = CH_OFFSETS[ch_idx],
        len = CH_LENS[ch_idx],
        raw = raw_col_count(len))
    len <= 0 ? 0 :
    let(valid = [for (j = [0:max(0, raw-1)])
        if (col_inside_hex(col_x(raw, j, ch_idx), d)) 1])
    len(valid);

COL_COUNTS = [for (i = [0:NUM_CHANNELS-1]) culled_col_count(i)];

// =============================================
// MECHANICS
// =============================================
/* [Mechanics] */
ECCENTRICITY  = 4.8;
// CAM_ECC = ECCENTRICITY (unified in V5.5b — no cosine loss, cable runs tangent to slider)
CAM_STROKE    = 2 * ECCENTRICITY;  // 9.6mm

/* [Block Motion] */
// Summation model: each tier independently adds/removes rope length.
// 3 tiers × ECCENTRICITY = max one-sided displacement.
MAX_BLOCK_TRAVEL = 3 * ECCENTRICITY;  // 14.4mm (±14.4mm = 28.8mm total stroke)

/* [Slider Bias] */
SLIDER_BIAS        = 0.80;
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS;  // 3.84mm

// =============================================
// HOUSING / TIER
// =============================================
WALL_THICKNESS = 1.5;
CH_GAP         = STACK_OFFSET - WALL_THICKNESS;     // 8.5mm (V5.6: was 6.5)
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 1;         // 16mm (V5.6: was 13)

// =============================================
// TIER STACKING
// =============================================
NUM_TIERS     = 3;
TIER_ANGLES   = [180, 300, 60];  // V5.5: sliders face their helixes
INTER_TIER_GAP = 0.0;
TIER_PITCH    = HOUSING_HEIGHT + INTER_TIER_GAP;     // 16mm (V5.6: was 13)

TIER1_TOP     = TIER_PITCH + HOUSING_HEIGHT / 2;     // +24 (V5.6: was +19.5)
TIER3_BOT     = -TIER_PITCH - HOUSING_HEIGHT / 2;    // -24 (V5.6: was -19.5)

// =============================================
// ANCHOR & GUIDE PLATES
// =============================================
ANCHOR_THICK      = 3.0;

// V5.5b: Single guide plate replaces dual GP1+GP2+gap.
// Tapered through-holes (funnel on top, straight bore on bottom).
// No PTFE bushings — just printed funnel-to-bore holes.
GUIDE_THICK       = 5.0;          // single plate thickness
GUIDE_FUNNEL_TAPER = 2.0;        // depth of funnel taper from top face

ANCHOR_Z  = TIER1_TOP;
GUIDE_Z   = TIER3_BOT;           // top face of guide plate = bottom of matrix
GUIDE_BOT = GUIDE_Z - GUIDE_THICK;  // bottom face of guide plate

// =============================================
// HEX SLEEVE RETENTION (V5.5 — replaces bayonet)
// =============================================
// Hex ring sleeves lock plate rotation. No twist mechanism needed.
// Upper ring: open bore (no ledge) — matrix + anchor slide through from top
// Lower ring: ledge faces UP — catches guide plate, matrix stack, everything
// Anchor plate: friction fit in upper ring sleeve + CA glue
// Guide plate: rests on lower ring ledge, sandwiched by matrix above
SLEEVE_CLEARANCE      = 0.15;      // radial clearance between plate hex and ring bore
PLATE_HEX_R           = HEX_R - SLEEVE_CLEARANCE;  // plate sized to fit inside ring

// Frame posts — only at stub vertices (clear slider paths at helix vertices)
FRAME_POST_ANGLES     = [0, 120, 240];  // stub vertices only
FRAME_POST_COUNT      = 3;

// Lower ring extension — must contain guide plate
GUIDE_STACK_H         = GUIDE_THICK;  // 5mm (was 12mm with dual plates)

// =============================================
// CENTRAL SHAFT — 4mm stainless steel rod
// =============================================
SHAFT_DIA         = 4.0;
D_FLAT_DEPTH      = 0.6;       // V5.5c R2: was 0.4 — deeper for GT2 set screw bite
SHAFT_BORE        = SHAFT_DIA + 0.2;  // 4.2mm
D_BORE_FLAT       = SHAFT_DIA - 2 * D_FLAT_DEPTH;  // 2.8mm (was 3.2mm)

// =============================================
// FRAME BEARINGS — MR84ZZ (4x8x3mm)
// =============================================
FRAME_BRG_ID  = 4.0;
FRAME_BRG_OD  = 8.0;
FRAME_BRG_W   = 3.0;

// =============================================
// HELIX CAM — Central Shaft Disc Parameters
// =============================================
NUM_CAMS       = NUM_CHANNELS;
TWIST_PER_CAM  = 360.0 / NUM_CAMS;
HELIX_ANGLES   = [180, 300, 60];

// Cam bearing — 6704ZZ (20x27x4)
CAM_BRG_ID        = 20.0;
CAM_BRG_OD        = 27.0;
CAM_BRG_W         = 4.0;

// Cam disc
DISC_OD           = CAM_BRG_ID - 0.4;                 // 19.6mm
DISC_WALL         = 2.0;
SHAFT_BOSS_OD     = SHAFT_DIA + 6;                     // 10mm

// Set screw (GT2 pulley only)
SET_SCREW_DIA     = 2.0;
SET_SCREW_BORE    = 1.6;
SET_SCREW_DEPTH   = 3.0;

// Eccentricity — CAM_ECC = ECCENTRICITY (unified in V5.5b — no cosine loss, cable runs tangent to slider)
CAM_ECC           = DISC_OD/2 - SHAFT_BOSS_OD/2;       // 4.8mm

// Keeper lip
KEEPER_LIP_DIA    = CAM_BRG_ID + 1.5;                 // 21.5mm
KEEPER_LIP_H      = 0.6;

// =============================================
// V5.5c: KEYED COLLAR FACES (replaces face pins + index jig)
// =============================================
// Cone bump on collar front face, matching conical dimple on disc back face.
// V5.5c R5: changed from hemisphere to cone — prints cleanly on FDM without
// bridging artifacts. Cone self-centers like a hemisphere but with crisp geometry.
// D-flat shaft prevents gross rotation; bump/dimple provides fine angular lock.
// CA glue between collar faces for permanent bond.
COLLAR_BUMP_DIA       = 1.5;       // cone base diameter (bump and dimple)
COLLAR_BUMP_H         = 0.6;       // cone protrusion height
COLLAR_BUMP_TIP_DIA   = 0.4;      // V5.5c R5: cone tip diameter (0 = sharp point)
COLLAR_BUMP_R         = SHAFT_BOSS_OD/2 - 1.2;  // radial position on collar face (3.8mm)
COLLAR_DIMPLE_DEPTH   = COLLAR_BUMP_H + 0.1;  // dimple slightly deeper for clearance
COLLAR_BUMP_COUNT     = 2;         // 2 bumps at 180deg for stronger alignment

// Disc axial geometry
AXIAL_PITCH       = 8.0;
DISC_THICK        = CAM_BRG_W + 1;                     // 5mm
FLANGE_H          = 0.8;
BEARING_ZONE_H    = CAM_BRG_W + 0.3;                  // 4.3mm
COLLAR_THICK      = AXIAL_PITCH - DISC_THICK;          // 3.0mm
HELIX_LENGTH      = NUM_CAMS * AXIAL_PITCH;            // 56mm (7×8) — V5.6: was 72mm (9×8)

// =============================================
// HEXAGRAM FRAME — key geometry constants (defined early for shaft extension)
// =============================================
_STAR_RATIO       = 2.5;
_CORRIDOR_GAP_CFG = 31.4;
_BLOCK_DROP       = 36;
_BLOCK_HEIGHT_CFG = 7;
_BLOCK_GAP        = 0.8;
_RING_R_IN_CFG    = HEX_R + 2;  // 45mm (matches monolith FRAME_RING_R_IN)
_RING_W_CFG       = 5;           // matches monolith FRAME_RING_W

// =============================================
// SHAFT EXTENSION — DERIVED from hexagram frame geometry
// =============================================
_CFG_STUB_LEN       = 15;
_CFG_STUB_W         = 10;

_CFG_STAR_TIP_R     = _STAR_RATIO * 2 * HEX_R;
_CFG_HEXAGRAM_INNER = _CFG_STAR_TIP_R / sqrt(3);
_CFG_V_PUSH         = _CORRIDOR_GAP_CFG / (2 * tan(30));
_CFG_HELIX_R        = _CFG_HEXAGRAM_INNER + _CFG_V_PUSH;
_CFG_STUB_R_END     = (HEX_R + 2 + _RING_W_CFG) + _CFG_STUB_LEN;
_CFG_JUNCTION_R     = _CFG_STUB_R_END + _CFG_STUB_W / 2;

function _cfg_par_res(V, T, J) = T*T*sin(120-V) - 2*J*T*sin(120-V/2) + J*J*sin(120);
function _cfg_find_V(T, J, lo=10, hi=150, d=0) =
    d > 50 ? (lo+hi)/2 :
    let(mid=(lo+hi)/2, r=_cfg_par_res(mid,T,J))
    abs(r) < 0.0001 ? mid :
    r > 0 ? _cfg_find_V(T,J,mid,hi,d+1) : _cfg_find_V(T,J,lo,mid,d+1);
_CFG_V_ANGLE        = _cfg_find_V(_CFG_STAR_TIP_R, _CFG_JUNCTION_R);

_CFG_STUB_A = 120;
_CFG_TIP_A  = _CFG_STUB_A + _CFG_V_ANGLE / 2;
_CFG_JX     = _CFG_JUNCTION_R * cos(_CFG_STUB_A);
_CFG_JY     = _CFG_JUNCTION_R * sin(_CFG_STUB_A);
_CFG_TX     = _CFG_STAR_TIP_R * cos(_CFG_TIP_A);
_CFG_TY     = _CFG_STAR_TIP_R * sin(_CFG_TIP_A);
_CFG_ADX    = _CFG_TX - _CFG_JX;
_CFG_ADY    = _CFG_TY - _CFG_JY;
_CFG_ALEN   = sqrt(_CFG_ADX*_CFG_ADX + _CFG_ADY*_CFG_ADY);
_CFG_SDX    = -sin(180);
_CFG_SDY    = cos(180);
_CFG_HCX    = _CFG_HELIX_R * cos(180);
_CFG_HCY    = _CFG_HELIX_R * sin(180);
_CFG_CROSS  = (_CFG_ADX/_CFG_ALEN) * _CFG_SDY - (_CFG_ADY/_CFG_ALEN) * _CFG_SDX;
_CFG_DJX    = _CFG_HCX - _CFG_JX;
_CFG_DJY    = _CFG_HCY - _CFG_JY;
_CFG_T_MM   = (_CFG_DJX * _CFG_SDY - _CFG_DJY * _CFG_SDX) / _CFG_CROSS;
_CFG_CX     = _CFG_JX + (_CFG_ADX/_CFG_ALEN) * _CFG_T_MM;
_CFG_CY     = _CFG_JY + (_CFG_ADY/_CFG_ALEN) * _CFG_T_MM;
_SHAFT_TANGENT_DIST = abs((_CFG_CX - _CFG_HCX) * _CFG_SDX + (_CFG_CY - _CFG_HCY) * _CFG_SDY);

SHAFT_EXT_TO_CARRIER = _SHAFT_TANGENT_DIST - HELIX_LENGTH / 2;

// Shaft retainer — E-clip groove
ECLIP_GROOVE_DIA     = SHAFT_DIA - 0.6;
ECLIP_GROOVE_W       = 0.6;
ECLIP_OD             = 8.0;

// Carrier plate thickness
CARRIER_PLATE_T_CFG  = 10;
ECLIP_INBOARD_OFFSET = CARRIER_PLATE_T_CFG / 2 + 1;

// GT2 extension
_GT2_BOSS_H_REF         = 5;
SHAFT_EXT_BEYOND_DRIVE  = CARRIER_PLATE_T_CFG / 2 + _GT2_BOSS_H_REF + 1;
SHAFT_EXT_BEYOND_FREE   = CARRIER_PLATE_T_CFG / 2 + 2;
SHAFT_EXT_BEYOND        = SHAFT_EXT_BEYOND_DRIVE;
SHAFT_TOTAL_LENGTH      = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER * 2
                          + SHAFT_EXT_BEYOND_DRIVE + SHAFT_EXT_BEYOND_FREE;

// Follower ring
FOLLOWER_RING_ID  = CAM_BRG_OD + 0.3;
FOLLOWER_RING_OD  = CAM_BRG_OD + 4;
FOLLOWER_RING_H   = 3.0;
FOLLOWER_EYELET_DIA = 1.5;
FOLLOWER_ARM_LENGTH = 6.0;
FOLLOWER_ARM_W    = 3.0;

// =============================================
// DAMPENER
// =============================================
DAMPENER_BAR_W      = 7.0;   // V5.8: widened from 5→7mm for more wall around cable holes
DAMPENER_BAR_H      = 7.0;   // V5.5: unified with ARM_H
DAMPENER_HOLE_DIA   = 2.0;
DAMP_BRACE_SCALE    = 0.80;  // V5.8: brace cross-section = 80% of arm (secondary structure)

// =============================================
// FRAME POSTS
// =============================================
POST_DIA       = 2.5;
// V5.5b FIX: Posts centered in ring wall body, NOT at bore edge.
// Ring wall: R_IN = HEX_R+2 = 45mm, R_OUT = HEX_R+7 = 50mm, 5mm thick.
// Posts at midpoint of wall = 47.5mm. Post edges 46.25–48.75mm.
// Fully embedded in ring wall — clear of inner sleeve bore.
// (_RING_R_IN_CFG and _RING_W_CFG defined in HEXAGRAM FRAME section above)
POST_NOTCH_R   = _RING_R_IN_CFG + _RING_W_CFG / 2;  // 47.5mm (centered in ring wall)

// =============================================
// SCULPTURAL FRAME PARAMS (V5.6 Aesthetic Upgrade)
// =============================================
/* [Frame Aesthetics] */
// U1: Tapered arms — gradient cross-section from root to tip
ARM_TAPER_RATIO   = 0.6;       // tip width = root width × ratio
ARM_SEGMENTS      = 12;        // hull segments per arm (render budget)

// U2: Junction node swell — organic bulge at stress points
NODE_SWELL_FACTOR = 1.4;       // node diameter = STUB_W × swell

// U3: Variable chamfers — hierarchy expression
CHAMFER_STUB      = 2.0;       // thick root structure
CHAMFER_ARM_ROOT  = 1.5;       // arm at junction
CHAMFER_ARM_TIP   = 1.0;       // arm at carrier end
CHAMFER_LINKAGE   = 1.0;       // secondary bracing

// U4: Carrier bearing boss expression
CARRIER_BOSS_EXTRA = 2.0;      // extra diameter around bearing bore ring
CARRIER_RIM_LIP   = 0.5;       // cosmetic raised lip on bore face

// U5: Dampener bar taper
DAMP_TAPER_CENTER_H = 5.0;     // center height (vs DAMPENER_BAR_H at ends)

// U6: Curved linkage braces
LINKAGE_SAG       = 0;         // V5.8b: straight (was 2.5mm catenary sag)
LINKAGE_SEGMENTS  = 8;         // hull segments per linkage curve

// U7: Ring edge bevel
RING_BEVEL        = 1.0;       // outer edge chamfer on hex rings

// =============================================
// LEGS — ON HOLD
// =============================================
LEG_HEIGHT_CFG    = 200;
LEG_TOP_R_CFG     = 9;
LEG_BOT_R_CFG     = 32;
LEG_WAIST_R_CFG   = 6;
LEG_WAIST_FRAC_CFG = 0.38;
LEG_WALL_T        = 2.5;
LEG_OPEN_ANGLE    = 130;
LEG_ROUNDING      = 0.15;
LEG_SLICES        = 60;
LEG_CIRC_SEG      = 24;
LEG_FOOT_PAD_DIA  = 20;
LEG_FOOT_PAD_H    = 3;

// =============================================
// STRING / CABLE
// =============================================
STRING_DIA        = 0.5;
GUIDE_MIN_BORE    = 1.5;     // min bore for string passage (guide plate computes actual bore)
GUIDE_FUNNEL_DIA  = 3.0;
STRING_HOLE_DIA   = 1.5;
RETAINER_DIA      = 3.0;
RETAINER_DEPTH    = 1.0;

// =============================================
// BEARING MOUNTS
// =============================================
JOURNAL_LENGTH    = 5.0;
JOURNAL_EXT       = 75.0;

// GT2 drive pulleys
GT2_TEETH       = 12;
GT2_PD          = GT2_TEETH * 2 / PI;
GT2_OD          = GT2_PD + 1.5;
GT2_BOSS_H      = 5;
GT2_BELT_W      = 6;

// =============================================
// DRIVE CHAIN
// =============================================
/* [Motor] */
MOTOR_HELIX_IDX   = 2;
MOTOR_BODY_DIA    = 10;
MOTOR_BODY_LEN    = 15;
MOTOR_SHAFT_DIA   = 2;
MOTOR_SHAFT_LEN   = 6;
MOTOR_GAP         = 2;

/* [Idlers] */
// IDLER_MODE: "printed" = monolithic smooth disc (no hardware)
//             "bolt"    = M3 bolt-through for purchased GT2 flanged idler w/ bearings
IDLER_MODE        = "bolt";      // toggle: "printed" or "bolt"
IDLER_OD          = GT2_OD;
IDLER_BORE        = 3.0;         // 3mm bore — fits M3 bolt or printed 3mm shaft
IDLER_H           = GT2_BOSS_H;
IDLER_FLANGE_OD   = GT2_OD + 2;
IDLER_STACK_GAP   = 1;

// Clevis bracket dimensions (switchable design)
IDLER_M3_CLEARANCE = 3.2;        // M3 clearance hole through clevis walls
IDLER_CLEVIS_WALL  = 3.0;        // each clevis wall thickness
IDLER_CLEVIS_GAP   = GT2_BELT_W + 2 * 0.8 + 1;  // inner gap: belt + 2 flanges + clearance
IDLER_CLEVIS_SPAN  = IDLER_CLEVIS_GAP + 2 * IDLER_CLEVIS_WALL;  // total clevis width

/* [Belt] */
DRIVE_BELT_W      = GT2_BELT_W;
DRIVE_BELT_DIA    = 1.0;

/* [Drive Colors] */
C_MOTOR    = [0.2, 0.5, 0.9, 0.9];
C_IDLER    = [0.8, 0.2, 0.2, 0.9];
C_BELT     = [0.5, 0.25, 0.1, 0.85];
C_BRACKET  = [0.5, 0.5, 0.55, 0.9];

// =============================================
// COLORS
// =============================================
C_ACRYLIC   = [0.85, 0.92, 0.95, 0.3];
C_NYLON     = [0.95, 0.95, 0.92, 1.0];
C_STEEL     = [0.7,  0.7,  0.75, 1.0];
C_STRING    = [0.1,  0.1,  0.1,  1.0];
C_BLOCK     = [0.82, 0.71, 0.55, 1.0];
C_SLIDER    = [0.9,  0.4,  0.4,  1.0];
C_WALL      = [0.6,  0.6,  1.0,  0.8];
C_DISC      = [0.3,  0.6,  0.9,  0.9];
C_RIB       = [0.8,  0.5,  0.2,  0.9];
C_BEARING   = [0.5,  0.5,  0.55, 0.7];
C_ENDPLT    = [0.5,  0.5,  0.55, 0.9];
C_BOLT      = [0.3,  0.3,  0.3,  1.0];
C_HEX_GHOST = [0.3,  0.8,  0.3,  0.1];
C_PIN       = [0.9,  0.85, 0.3,  1.0];

// =============================================
// VERIFICATION
// =============================================
_boss_wall = (SHAFT_BOSS_OD - SHAFT_BORE) / 2;
if (_boss_wall < 1.5)
    echo(str("CONFIG !! Shaft boss wall too thin: ", round(_boss_wall*10)/10, "mm"));

_boss_margin = DISC_OD/2 - CAM_ECC - SHAFT_BOSS_OD/2;
if (_boss_margin < -0.5)
    echo(str("CONFIG !! Shaft boss protrudes from disc by ", round(-_boss_margin*10)/10, "mm"));

if (DISC_OD >= CAM_BRG_ID)
    echo(str("CONFIG !! Disc OD=", DISC_OD, " >= bearing bore=", CAM_BRG_ID, "!"));

if (FOLLOWER_RING_ID <= CAM_BRG_OD)
    echo(str("CONFIG !! Follower ring ID=", FOLLOWER_RING_ID, " <= bearing OD=", CAM_BRG_OD, "!"));

if (COLLAR_THICK < 1.0)
    echo(str("CONFIG !! Collar too thin: ", round(COLLAR_THICK*10)/10, "mm"));

if (abs(CAM_ECC - ECCENTRICITY) > 0.01)
    echo(str("CONFIG !! CAM_ECC=", round(CAM_ECC*10)/10, " differs from ECCENTRICITY=", round(ECCENTRICITY*10)/10));

_shortest_ch = min([for (i=[0:NUM_CHANNELS-1]) CH_LENS[i]]);
if (_shortest_ch > 0) {
    _shortest_half_w = hex_w(CH_OFFSETS[0]) / 2;
    if (STAGGER_HALF_PITCH + max(FP_OD, SP_OD)/2 + 1 > _shortest_half_w)
        echo(str("CONFIG !! Stagger may clip columns on shortest channel"));
}

echo(str("=== CONFIG V5.6 (7ch, 4mm pulleys, 16mm housing) ==="));
echo(str("Scale: 0.4831 | HEX_R=", HEX_R, " | Channels=", NUM_CHANNELS, " | Cams=", NUM_CAMS));
echo(str("STACK_OFFSET=", STACK_OFFSET, "mm | CH_GAP=", CH_GAP, "mm | HOUSING_HEIGHT=", HOUSING_HEIGHT, "mm"));
echo(str("FP_OD=", FP_OD, " SP_OD=", SP_OD, " FP_ROW_Y=", FP_ROW_Y, "mm"));
echo(str("ECCENTRICITY=", ECCENTRICITY, " CAM_ECC=", round(CAM_ECC*10)/10));
echo(str("HELIX_LENGTH=", HELIX_LENGTH, "mm (", NUM_CAMS, "x", AXIAL_PITCH, "mm) | TWIST/CAM=", round(TWIST_PER_CAM*10)/10, "deg"));
echo(str("Shaft: ", SHAFT_DIA, "mm D-flat=", D_FLAT_DEPTH, "mm | Total=", round(SHAFT_TOTAL_LENGTH*10)/10, "mm"));
echo(str("TIER_PITCH=", TIER_PITCH, "mm | TIER1_TOP=", TIER1_TOP, " TIER3_BOT=", TIER3_BOT, " | Stack=", TIER1_TOP-TIER3_BOT, "mm"));
echo(str("TIER_ANGLES=[", TIER_ANGLES[0], ",", TIER_ANGLES[1], ",", TIER_ANGLES[2], "] — sliders face helixes"));
echo(str("Frame posts at stub vertices only [0,120,240]"));
echo(str("Matrix separate — slides into frame from above"));
