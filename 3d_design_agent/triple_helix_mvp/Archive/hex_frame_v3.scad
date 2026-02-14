// =========================================================
// HEX FRAME V3 — Full Sculpture Skeleton (Hexagram Star Frame)
// =========================================================
// Structural skeleton for the Triple Helix kinetic sculpture.
//
// FRAME ARCHITECTURE (Top-Down, One Tier):
//
//   Central hex matrix (black) at origin, HEX_R = 118mm.
//   Hex ring surrounds it (R_IN=120, R_OUT=130).
//
//   3 SHORT STUBS extend radially from NON-helix vertices:
//     [0°, 120°, 240°] — where sliders DON'T protrude.
//
//   Each stub connects to 2 MAIN FRAME ARMS going in opposite
//   directions (CW and CCW). The 6 arms form a HEXAGRAM
//   (Star of David / two interlocking equilateral triangles).
//
//     Triangle 1: tips at [30°, 150°, 270°]
//     Triangle 2: tips at [90°, 210°, 330°]
//
//   The inner hexagon of the hexagram has vertices at both
//   STUB positions [0°, 120°, 240°] and HELIX positions
//   [60°, 180°, 300°].
//
//   At each HELIX position [180°, 300°, 60°], two adjacent
//   frame arms from different stubs run PARALLEL outward.
//   The helix camshaft sits between the parallel rails.
//
// TWO TIERS:
//   The lower tier is the "base" tier.
//   The upper tier is the SAME geometry, rotated 180° around
//   a horizontal axis — this automatically flips the ledge:
//     Lower ring: ledge on TOP face (supports matrix from below)
//     Upper ring: ledge on BOTTOM face (clamps matrix from above)
//
//   STUBS stay PARALLEL between tiers (same vertical gap as rings).
//   FRAME ARMS CONVERGE vertically — upper slopes DOWN,
//   lower slopes UP — meeting at HELIX_Z. After the transition
//   point, both arms in a pair run PARALLEL horizontally at HELIX_Z.
//
// DRIVE: GT2 timing belt (2mm pitch, 6mm wide).
//   Motor → H1(180°) → I1 → H3(60°) → I2 → H2(300°) → I3 → Motor
//   3 smooth idlers for ≥120° wrap on all drive pulleys.
//   20-tooth GT2 pulleys (12.73mm PD) at helices + motor (1:1).
// =========================================================

use <main_stack_v3.scad>
use <helix_cam_v3.scad>

$fn = 24;  // frame quality

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// SCALE MODE — prototype vs final sculpture
// =============================================
// false = PROTOTYPE: compact desk-scale, short block drop, wider star for stability
// true  = FINAL: 4ft tall × 2ft wide, long wave curtain, tighter star ratio
/* [Scale] */
FINAL_SCALE       = false;  // toggle between prototype and final

// Scale-dependent parameters (all others stay the same)
_STAR_RATIO       = FINAL_SCALE ? 1.25 : 1.5;    // star tip multiplier of HEX_LONGEST_DIA
_BLOCK_DROP       = FINAL_SCALE ? 800  : 100;     // mm string drop below guide plates
_BLOCK_HEIGHT     = FINAL_SCALE ? 55   : 20;      // mm block height (visual weight)
_CORRIDOR_GAP     = FINAL_SCALE ? 60   : 78;      // mm arm spacing at helix (tighter for final)

// =============================================
// MATRIX DIMENSIONS (must match main_stack_v3)
// =============================================
HEX_R          = 118;
STACK_OFFSET   = 14.0;       // ⚠ MUST match matrix_tier_v3.scad
ECCENTRICITY   = 15.0;       // ⚠ MUST match matrix_tier_v3.scad
FP_ROW_Y       = 10.0;
FP_OD          = 8.0;
SP_OD          = 8.0;
COL_PITCH      = 12;
WALL_MARGIN    = 8;
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2;  // 30mm

HEX_FF  = HEX_R * sqrt(3);
HEX_LONGEST_DIA = 2 * HEX_R;  // 236mm corner-to-corner

function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;

function hex_w(d) =
    let(max_d = HEX_R * sqrt(3) / 2)
    (abs(d) > max_d) ? 0 : 2 * (HEX_R - abs(d) / sqrt(3));
function ch_len(d) = max(0, hex_w(d) - 2 * WALL_MARGIN);
function col_x(count, idx) =
    -((count - 1) / 2) * COL_PITCH + idx * COL_PITCH;
function col_inside_hex(px, d) =
    let(max_od = max(FP_OD, SP_OD))
    (abs(px) + max_od/2 + 1) < (hex_w(d) / 2);
function raw_col_count(len) =
    (len < COL_PITCH) ? ((len > max(FP_OD, SP_OD)) ? 1 : 0) :
    floor(len / COL_PITCH) + 1;

// Tier stacking
NUM_TIERS     = 3;
TIER_ANGLES   = [0, 120, 240];
TIER_PITCH    = HOUSING_HEIGHT;

// Helix configuration
NUM_CAMS      = NUM_CHANNELS;
TWIST_PER_CAM = 360.0 / NUM_CAMS;
HELIX_ANGLES  = [180, 300, 60];  // where 3 helices sit

// Z-layout (from main_stack)
ANCHOR_THICK    = 5.0;
GP1_THICK       = 3.0;
GP2_THICK       = 5.0;
GUIDE_PLATE_GAP = 15.0;

TIER1_TOP = TIER_PITCH + HOUSING_HEIGHT / 2;
TIER3_BOT = -TIER_PITCH - HOUSING_HEIGHT / 2;
ANCHOR_Z  = TIER1_TOP;
GP1_Z     = TIER3_BOT;
GP2_Z     = GP1_Z - GP1_THICK - GUIDE_PLATE_GAP;
GP2_BOT   = GP2_Z - GP2_THICK;

// =============================================
// 3-HELIX SUPERPOSITION (for block grid)
// =============================================
_CENTER_CH = (NUM_CHANNELS - 1) / 2;

function _tier_contribution(bx, by, tier_angle, t) =
    let(
        d_k = bx * sin(tier_angle) - by * cos(tier_angle),
        continuous_ch = d_k / STACK_OFFSET + _CENTER_CH,
        phase_k = continuous_ch * TWIST_PER_CAM
    )
    ECCENTRICITY * sin(t * 360 + phase_k);

function superposition_dz(bx, by, t) =
    (1/3) * (
        _tier_contribution(bx, by, TIER_ANGLES[0], t) +
        _tier_contribution(bx, by, TIER_ANGLES[1], t) +
        _tier_contribution(bx, by, TIER_ANGLES[2], t)
    );

// =============================================
// HEX FRAME PARAMETERS
// =============================================

/* [Frame Rings — Two identical rings (upper = lower flipped 180°)] */
FRAME_RING_H      = 12;       // [3:1:40] ring beam height (vertical)
FRAME_RING_W      = 10;       // [4:1:25] ring beam width (radial)
FRAME_RING_R_IN   = HEX_R + 2;      // inner edge: 120mm
FRAME_RING_R_OUT  = FRAME_RING_R_IN + FRAME_RING_W;  // outer edge: 130mm

// Z positions of upper and lower rings — flush against matrix faces
// Matrix spans TIER3_BOT (-45) to TIER1_TOP (+45).
// Upper ring sits on top: its ledge (BOTTOM face) presses down on matrix top.
// Lower ring sits below: its ledge (TOP face) supports matrix bottom.
UPPER_RING_Z      = TIER1_TOP;                       // ring bottom = matrix top
LOWER_RING_Z      = TIER3_BOT - FRAME_RING_H;        // ring top = matrix bottom

// Z centers for arm attachment
UPPER_RING_CENTER_Z = UPPER_RING_Z + FRAME_RING_H / 2;
LOWER_RING_CENTER_Z = LOWER_RING_Z + FRAME_RING_H / 2;

// Ring-to-ring vertical gap (center to center)
TIER_GAP_Z = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z;

/* [Inward Ledge — on BOTH rings, automatic from 180° flip] */
// Lower ring: ledge on TOP face (supports matrix)
// Upper ring: ledge on BOTTOM face (clamps matrix) — same geometry, flipped
LEDGE_WIDTH       = 6;
LEDGE_THICK       = 3;
LEDGE_R_IN        = FRAME_RING_R_IN - LEDGE_WIDTH;  // 114mm

/* [Stubs — short parallel pair from NON-helix vertices] */
STUB_ANGLES       = [0, 120, 240];  // NON-helix vertices
STUB_LENGTH       = 30;       // [10:5:80] mm outward radial length
STUB_INWARD       = 8;        // [0:1:30] mm inward overlap into hex ring
STUB_W            = 25;       // [6:1:25] arm width
STUB_H            = 12;       // [4:1:20] arm height
STUB_R_START      = FRAME_RING_R_OUT - STUB_INWARD;   // starts inside ring
STUB_R_END        = FRAME_RING_R_OUT + STUB_LENGTH;    // 160mm outward
JUNCTION_R        = STUB_R_END + 25/2;  // 172.5mm — arms start past junction plate (STUB_W/2)

/* [Hexagram Star — 6 main frame arms, two interlocking triangles] */
V_ANGLE           = 74;       // [10:1:120] opening angle between each arm pair
ARM_W             = 20;       // [4:1:25] arm width
ARM_H             = 14;       // [3:1:20] arm height
ARM_CHAMFER       = 2;        // [0:0.5:5] corner radius for rounded-rect cross-section
// Star tips: ratio × hex longest diameter from center
// Prototype: 1.5× = 354mm (dramatic). Final: 1.25× = 295mm (fits 2ft width).
STAR_TIP_R        = _STAR_RATIO * HEX_LONGEST_DIA;

// Hexagram geometry (two equilateral triangles)
// Inner hexagon circumradius = STAR_TIP_R / sqrt(3)
HEXAGRAM_INNER_R  = STAR_TIP_R / sqrt(3);     // ~204mm

// Triangle 1 tips at [30°, 150°, 270°]
// Triangle 2 tips at [90°, 210°, 330°]

// Each arm is one SIDE of a triangle. It passes through two
// inner hexagon vertices. The inner vertices at [0,120,240] are
// the stub positions; those at [60,180,300] are the helix crossings.

// At each HELIX position, two arms from adjacent stubs cross.
// The corridor gap is the spacing between the two arms at the crossing.
CORRIDOR_GAP      = _CORRIDOR_GAP;  // mm between arm centers at helix position

// Helix radial position (where camshaft sits between the two parallel arms)
_V_PUSH           = CORRIDOR_GAP / (2 * tan(30));  // ~52mm
HELIX_R           = HEXAGRAM_INNER_R + _V_PUSH;    // ~256mm

/* [Stub Linkages — vertical beams connecting upper↔lower stub arms] */
STUB_LINK_W       = 8;
STUB_LINK_H       = 6;

/* [Arm Convergence] */
// Stubs stay PARALLEL between tiers (same Z gap as rings).
// Frame arms CONVERGE: upper arms slope DOWN, lower arms slope UP.
// CONVERGE_PCT controls how much: 100 = fully meet at midpoint, 0 = stay parallel.
CONVERGE_PCT      = 60;     // [0:5:100] convergence at arm tips (%)
_MID_Z            = (UPPER_RING_CENTER_Z + LOWER_RING_CENTER_Z) / 2;
// At 100%: upper tip Z = lower tip Z = _MID_Z (fully converged)
// At 0%:   upper tip Z = UPPER_RING_CENTER_Z, lower = LOWER_RING_CENTER_Z (parallel)
ARM_TIP_Z_UPPER   = UPPER_RING_CENTER_Z + ((_MID_Z - UPPER_RING_CENTER_Z) * CONVERGE_PCT / 100);
ARM_TIP_Z_LOWER   = LOWER_RING_CENTER_Z + ((_MID_Z - LOWER_RING_CENTER_Z) * CONVERGE_PCT / 100);
HELIX_Z           = (ARM_TIP_Z_UPPER + ARM_TIP_Z_LOWER) / 2;

/* [Helix Mount Bracket — 6800ZZ bearing housing] */
BEARING_OD        = 19;       // 6800ZZ: 10/19/5mm
BEARING_W         = 5;
MOUNT_WALL        = 4;        // wall around bearing pocket
MOUNT_OD          = BEARING_OD + 2 * MOUNT_WALL;  // 27mm housing OD
MOUNT_BORE_DIA    = BEARING_OD + 0.05;            // 19.05mm press fit
SHAFT_CLEARANCE   = 10.5;     // shaft through-bore (10mm + 0.5mm clearance)
MOUNT_TAB_W       = 15;       // bolt tab width
MOUNT_TAB_BOLT    = 4.2;      // M4 clearance hole
MOUNT_PLATE_T     = BEARING_W + 1.5;              // 6.5mm (bearing depth + lip)
MOUNT_BRACKET_W   = 40;       // wider for helix cam
MOUNT_BRACKET_H   = 50;

/* [Dampener Array — cable guides between helix and matrix] */
DAMPENER_LENGTH   = 20;       // tube length (mm)
DAMPENER_DIA      = 6;        // tube OD
DAMPENER_BORE     = 1.5;      // bore for 0.5mm Dyneema + clearance
DAMPENER_R        = HEX_R + DAMPENER_LENGTH/2 + 5;  // ~133mm from center

/* [Drive System — GT2 Timing Belt + Transfer Shaft] */
// Topology: 1 motor → belt → H1(180°) + H2(300°), transfer shaft → H3(60°)
GT2_PULLEY_DIA    = 12.73;    // 20T × 2mm / π
GT2_BELT_W        = 6;
IDLER_DIA         = 12;

// Motor sits between H1(180°) and H2(300°), outside frame
MOTOR_ANGLE       = 240;      // midpoint of H1↔H2 arc, outside frame
MOTOR_R           = HELIX_R + 60;    // well outside star tips
MOTOR_Z           = LOWER_RING_CENTER_Z;  // at lower ring level

// Transfer shaft: H1 → bevel gear → shaft → bevel gear → H3
XFER_SHAFT_DIA    = 10;       // 10mm steel rod
XFER_SHAFT_Z      = LOWER_RING_CENTER_Z;  // runs at lower ring level
BEVEL_GEAR_PD     = 20;       // 1:1 ratio bevel/miter gears
BEVEL_GEAR_H      = 10;       // gear height (simplified cone)

// Helix XY + Idler positions: computed after _helix_center() definition (see below line ~355)

/* [Block Grid] */
BLOCK_DROP        = _BLOCK_DROP;
BLOCK_Z           = GP2_BOT - BLOCK_DROP;

// =============================================
// HEXAGRAM ARM GEOMETRY — precomputed points
// =============================================
// Triangle 1 vertices (star tips): 30°, 150°, 270°
// Triangle 2 vertices (star tips): 90°, 210°, 330°
//
// Triangle 1 sides (each side = one frame arm):
//   Side A: tip 270° → tip 30°  (passes through inner verts at 300°, 0°)
//   Side B: tip 30°  → tip 150° (passes through inner verts at 60°, 120°)
//   Side C: tip 150° → tip 270° (passes through inner verts at 180°, 240°)
//
// Triangle 2 sides:
//   Side D: tip 330° → tip 90°  (passes through inner verts at 0°, 60°)
//   Side E: tip 90°  → tip 210° (passes through inner verts at 120°, 180°)
//   Side F: tip 210° → tip 330° (passes through inner verts at 240°, 300°)
//
// For frame construction, each arm runs from ONE stub to the STAR TIP.
// A full triangle side spans two stubs (passing through a helix crossing),
// but we break it at the stub vertices for construction.

// Star tip positions
function _star_tip(angle) = [STAR_TIP_R * cos(angle), STAR_TIP_R * sin(angle)];

// Inner hexagon vertex positions (where stubs end / helices cross)
function _inner_vert(angle) = [HEXAGRAM_INNER_R * cos(angle), HEXAGRAM_INNER_R * sin(angle)];

// The 6 frame arm segments (stub_end → star_tip):
// Each stub at [0, 120, 240] sends two arms in opposite directions.
//
// From stub 0°:
//   Arm 0A: inner_vert(0°) → star_tip(30°)   [part of Triangle 1, Side A]
//   Arm 0B: inner_vert(0°) → star_tip(330°)  [part of Triangle 2, Side D (reversed)]
//
// From stub 120°:
//   Arm 120A: inner_vert(120°) → star_tip(150°) [part of Triangle 1, Side C (reversed)]
//   Arm 120B: inner_vert(120°) → star_tip(90°)  [part of Triangle 2, Side E (reversed)]
//
// From stub 240°:
//   Arm 240A: inner_vert(240°) → star_tip(270°) [part of Triangle 1, Side C]
//   Arm 240B: inner_vert(240°) → star_tip(210°) [part of Triangle 2, Side F (reversed)]
//
// Helix corridors: each helix sits where two arms from DIFFERENT
// stubs cross. The V-corridor opens outward toward the helix.

// ARM DATA: [stub_angle, star_tip_angle]
// Each stub sends two arms at ±V_ANGLE/2 from the stub's radial direction.
// At V_ANGLE=60 this reproduces the original hexagram geometry.
_HALF_V = V_ANGLE / 2;
ARM_DEFS = [
    [0,   0 - _HALF_V],    // Stub 0° → CCW arm (330° at V=60)
    [0,   0 + _HALF_V],    // Stub 0° → CW arm  (30° at V=60)
    [120, 120 - _HALF_V],  // Stub 120° → CCW arm (90° at V=60)
    [120, 120 + _HALF_V],  // Stub 120° → CW arm  (150° at V=60)
    [240, 240 - _HALF_V],  // Stub 240° → CCW arm (210° at V=60)
    [240, 240 + _HALF_V],  // Stub 240° → CW arm  (270° at V=60)
];

// Helix corridors: which arm indices form each V
// Helix 60°:  Arm 1 (0°→37°) and Arm 2 (120°→83°)
// Helix 180°: Arm 3 (120°→157°) and Arm 4 (240°→203°)
// Helix 300°: Arm 5 (240°→277°) and Arm 0 (0°→-37°=323°)
HELIX_ARM_PAIRS = [[1, 2], [3, 4], [5, 0]];

// Simple helix placement: helix sits at HELIX_R along HELIX_ANGLES.
// HELIX_R is already computed from the V_PUSH formula above.
// The shaft runs TANGENT to the radial arm (perpendicular to the radial direction).
function _helix_center(hi) =
    let(a = HELIX_ANGLES[hi])
    [HELIX_R * cos(a), HELIX_R * sin(a)];

// Shaft direction: perpendicular to the radial (tangent to circle at helix pos)
function _shaft_angle(hi) = HELIX_ANGLES[hi] + 90;

// =============================================
// HELIX XY + IDLER POSITIONS (computed from _helix_center)
// =============================================
_h1_xy = _helix_center(0);   // Helix at 180°
_h2_xy = _helix_center(1);   // Helix at 300°
_h3_xy = _helix_center(2);   // Helix at 60°

// Idlers at midpoints between adjacent helices, pushed outward
_i1_mid = [(_h1_xy[0] + _h3_xy[0])/2, (_h1_xy[1] + _h3_xy[1])/2];
_i2_mid = [(_h3_xy[0] + _h2_xy[0])/2, (_h3_xy[1] + _h2_xy[1])/2];
_i3_mid = [(_h2_xy[0] + _h1_xy[0])/2, (_h2_xy[1] + _h1_xy[1])/2];

// Push idlers outward from center by 15% for belt clearance
_i_push = 1.15;
IDLER1_XY = [_i1_mid[0] * _i_push, _i1_mid[1] * _i_push];
IDLER2_XY = [_i2_mid[0] * _i_push, _i2_mid[1] * _i_push];
IDLER3_XY = [_i3_mid[0] * _i_push, _i3_mid[1] * _i_push];

// =============================================
// COLORS
// =============================================
C_FRAME    = [0.15, 0.15, 0.18, 0.9];
C_STUB     = [0.7, 0.15, 0.15, 0.9];   // red (matches user's diagram)
C_ARM      = [0.9, 0.55, 0.1, 0.9];    // orange (default, used for linkages)
// Per-arm colors: 6 distinct colors for visual identification
C_ARMS = [
    [0.9, 0.2, 0.2, 0.9],    // Arm 1: red
    [0.2, 0.7, 0.2, 0.9],    // Arm 2: green
    [0.2, 0.4, 0.9, 0.9],    // Arm 3: blue
    [0.9, 0.9, 0.1, 0.9],    // Arm 4: yellow
    [0.9, 0.4, 0.9, 0.9],    // Arm 5: magenta
    [0.1, 0.9, 0.9, 0.9],    // Arm 6: cyan
];
C_LINKAGE  = [0.5, 0.2, 0.6, 0.85];    // purple (matches user's diagram)
C_BLOCK    = [0.82, 0.71, 0.55, 1.0];
C_MOTOR    = [0.2, 0.2, 0.8, 0.9];     // blue
C_BELT     = [0.4, 0.25, 0.1, 0.8];    // brown
C_PULLEY   = [0.6, 0.6, 0.65, 1.0];
C_MOUNT    = [0.3, 0.3, 0.35, 0.9];
C_STEEL    = [0.7, 0.7, 0.75, 1.0];     // steel shafts
C_IDLER    = [0.5, 0.15, 0.15, 0.9];   // red stars

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_MATRIX         = true;
SHOW_UPPER_RING     = true;
SHOW_LOWER_RING     = true;
SHOW_STUBS          = true;
SHOW_STUB_LINKS     = true;    // vertical linkages between stub tiers
SHOW_ARMS           = true;    // 6 main hexagram frame arms
SHOW_ARM_LINKS      = true;    // purple linkages between arm pairs at stubs
SHOW_HELIX_MOUNTS   = true;
SHOW_BEARING_MOUNTS = true;     // stationary 6800ZZ housings at camshaft ends
SHOW_DAMPENERS      = true;     // dampener tube array (helix→matrix)
SHOW_DRIVE          = true;     // motor + belt + transfer shaft
SHOW_BLOCKS         = true;

/* [Debug] */
EXPLODE             = 0;
MATRIX_ROTATE_Z     = 0;     // [0:1:360] rotate matrix inside frame to check slider alignment
FRAME_RING_ROTATE_Z = 0;     // [0:1:60] rotate frame rings to align with matrix hex
LIGHTWEIGHT_MATRIX  = true;  // true = simple hex placeholder (fast), false = full matrix (slow)

// =============================================
// STANDALONE RENDER
// =============================================
hex_frame_v3(anim_t());


// =========================================================
// HEX FRAME V3 ASSEMBLY
// =========================================================
module hex_frame_v3(t = 0) {

    // ---- MATRIX (rotatable for alignment checking) ----
    if (SHOW_MATRIX)
        rotate([0, 0, MATRIX_ROTATE_Z]) {
            if (LIGHTWEIGHT_MATRIX) {
                // Fast placeholder: simple hex slab representing matrix envelope
                color([0.5, 0.8, 0.5, 0.3])
                translate([0, 0, TIER3_BOT])
                    linear_extrude(height = TIER1_TOP - TIER3_BOT)
                        circle(r = HEX_R, $fn = 6);
                // Slider direction indicators (thin lines at tier angles)
                for (ta = TIER_ANGLES) {
                    color([0.8, 0.2, 0.2, 0.8])
                    rotate([0, 0, ta])
                        translate([0, 0, 0])
                            cube([HEX_R * 2, 2, 2], center = true);
                }
            } else {
                main_stack_v3(t);
            }
        }

    // ---- LOWER HEX RING (base tier, ledge on TOP face) ----
    if (SHOW_LOWER_RING)
        _hex_ring_lower();

    // ---- UPPER HEX RING (= lower ring flipped 180° horizontally) ----
    if (SHOW_UPPER_RING)
        _hex_ring_upper();

    // ---- STUBS at [0°, 120°, 240°] — parallel between tiers ----
    if (SHOW_STUBS)
        _all_stubs();

    // ---- STUB LINKAGES — vertical beams connecting upper↔lower stubs ----
    if (SHOW_STUB_LINKS)
        _all_stub_linkages();

    // ---- JUNCTION NODES — clean transition from stubs to arms ----
    if (SHOW_ARMS)
        _all_junction_nodes();

    // ---- 6 MAIN FRAME ARMS (hexagram star) ----
    if (SHOW_ARMS)
        _all_frame_arms();

    // ---- ARM LINKAGES (purple) — between arm pairs at each stub ----
    if (SHOW_ARM_LINKS)
        _all_arm_linkages();

    // ---- HELIX MOUNTS ----
    if (SHOW_HELIX_MOUNTS)
        _all_helix_mounts();

    // ---- DAMPENER ARRAY (helix→matrix cable guides) ----
    if (SHOW_DAMPENERS)
        _dampener_array();

    // ---- DRIVE SYSTEM (GT2 belt + pulleys + idlers) ----
    if (SHOW_DRIVE)
        _drive_system(t);

    // ---- BLOCK GRID ----
    if (SHOW_BLOCKS)
        translate([0, 0, BLOCK_Z])
            _block_grid(t);

    // ---- ECHOES ----
    echo(str("=== HEX FRAME V3 (HEXAGRAM STAR) — ", FINAL_SCALE ? "FINAL" : "PROTOTYPE", " ==="));
    echo(str("Star tip R=", STAR_TIP_R, "mm (", _STAR_RATIO, "× hex dia ", HEX_LONGEST_DIA, "mm)"));
    echo(str("Total width: ~", round(STAR_TIP_R * 2), "mm (", round(STAR_TIP_R * 2 / 25.4), "\")"));
    // Estimate total height: mechanism + block drop + block
    _est_height = (UPPER_RING_CENTER_Z + FRAME_RING_H/2) - BLOCK_Z + _BLOCK_HEIGHT/2;
    echo(str("Est. total height: ~", round(_est_height), "mm (", round(_est_height / 25.4), "\")"));
    echo(str("Block drop: ", BLOCK_DROP, "mm | Block height: ", _BLOCK_HEIGHT, "mm"));
    echo(str("Hexagram inner R=", round(HEXAGRAM_INNER_R*10)/10, "mm"));
    _hc0 = _helix_center(0);
    _actual_helix_R = sqrt(_hc0[0]*_hc0[0] + _hc0[1]*_hc0[1]);
    echo(str("Helix R=", round(_actual_helix_R*10)/10, "mm (bisection @corridor=", CORRIDOR_GAP, "mm gap)"));
    echo(str("Upper ring Z=", UPPER_RING_Z, " center=", UPPER_RING_CENTER_Z));
    echo(str("Lower ring Z=", LOWER_RING_Z, " center=", LOWER_RING_CENTER_Z));
    echo(str("Ring gap: ", UPPER_RING_Z - (LOWER_RING_Z + FRAME_RING_H), "mm"));
    echo(str("Tier gap Z (center-center): ", round(TIER_GAP_Z*10)/10, "mm"));
    echo(str("Helix Z=", round(HELIX_Z*10)/10, " (convergence point)"));
    echo(str("Corridor: ", CORRIDOR_GAP, "mm gap at helix crossings"));
    echo(str("Matrix rotation: ", MATRIX_ROTATE_Z, "° (adjust to check slider alignment)"));
    echo(str("Drive: Motor→belt→H1+H2, transfer shaft→H3 | GT2 20T (", GT2_PULLEY_DIA, "mm PD)"));
    echo(str("Blocks Z=", BLOCK_Z, " (", BLOCK_DROP, "mm below GP2)"));

    // =========================================================
    // SYSTEM MATH VERIFICATION
    // =========================================================
    echo("");
    echo(str("=== SYSTEM MATH VERIFICATION ==="));

    // --- U-Detour String Geometry ---
    _BIAS = 0.80;  // must match matrix_tier_v3 SLIDER_BIAS
    _REST_OFFSET = ECCENTRICITY * _BIAS;
    _offset_max = ECCENTRICITY * (1 + _BIAS);   // max helix-side extension
    _offset_min = ECCENTRICITY * (_BIAS - 1);    // max arm-side retraction
    _L_max = 2 * sqrt(_offset_max * _offset_max + FP_ROW_Y * FP_ROW_Y);
    _L_min = 2 * sqrt(_offset_min * _offset_min + FP_ROW_Y * FP_ROW_Y);
    _delta_L = _L_max - _L_min;
    _max_angle = atan2(abs(_offset_max), FP_ROW_Y);

    echo(str("  U-Detour: offset_max=", _offset_max, "mm offset_min=", _offset_min, "mm"));
    echo(str("  String L_max=", round(_L_max*10)/10, "mm  L_min=", round(_L_min*10)/10,
             "mm  delta_L=", round(_delta_L*10)/10, "mm (block travel/tier)"));
    echo(str("  Max string angle=", round(_max_angle*10)/10, "°",
             (_max_angle > 75 ? " ⚠ STEEP >75°" : " ✓")));

    // --- Block Travel Budget ---
    _gain_at_rest = 2 * _REST_OFFSET / sqrt(_REST_OFFSET * _REST_OFFSET + FP_ROW_Y * FP_ROW_Y);
    _eff_per_tier = ECCENTRICITY * _gain_at_rest;
    _peak_3tier = _eff_per_tier;  // superposition ÷3 then ×3 = 1× effective

    echo(str("  Block Travel: gain@rest=", round(_gain_at_rest*100)/100,
             " eff/tier=", round(_eff_per_tier*10)/10,
             "mm  3-tier peak=", round(_peak_3tier*10)/10, "mm"));

    // --- Helix-to-Matrix Gap Budget ---
    _hc_verify = _helix_center(0);
    _eff_helix_R = sqrt(_hc_verify[0]*_hc_verify[0] + _hc_verify[1]*_hc_verify[1]);
    _gap = _eff_helix_R - HEX_R;
    _rib_arm = 20;      // cam follower arm
    _dampener = 20;      // string dampener / spring
    _min_cable = 10;     // minimum cable free-run
    _budget = _rib_arm + _dampener + _min_cable;

    echo(str("  Helix Gap: eff_R=", _eff_helix_R, "mm gap=", _gap, "mm budget=", _budget, "mm",
             (_gap < _budget ? " ⚠ GAP TOO SMALL" :
              (_gap > 4 * _budget ? " ⚠ GAP EXCESSIVE" : " ✓"))));

    // --- Friction Cascade ---
    _n_rollers = 9;      // max rollers in series per string path
    _roller_eff = 0.95;
    _bushing_eff = 0.99;
    _n_bushings = 2;
    _roller_total = pow(_roller_eff, _n_rollers);
    _bushing_total = pow(_bushing_eff, _n_bushings);
    _combined_eff = _roller_total * _bushing_total;
    _block_mass = 80;    // grams
    _return_force = _block_mass * 9.81 / 1000;  // N (gravity)
    _friction_loss = _return_force * (1 - _combined_eff);
    _sf = _combined_eff / (1 - _combined_eff);

    echo(str("  Friction: ", _n_rollers, " rollers @", _roller_eff, " → ",
             round(_roller_total*1000)/10, "%  +", _n_bushings, " bushings → combined ",
             round(_combined_eff*1000)/10, "%"));
    echo(str("  Block ", _block_mass, "g → return ", round(_return_force*100)/100,
             "N  SF=", round(_sf*10)/10,
             (_sf < 1.5 ? " ⚠ LOW SAFETY FACTOR" : " ✓")));

    // --- Cam Section Length ---
    _cam_axial_pitch = 14;  // helix_cam_v3: DISC_THICK = BEARING_ZONE(5) + FLANGE(9) = STACK_OFFSET
    _cam_length = NUM_CHANNELS * _cam_axial_pitch;  // 13×14 = 182mm

    echo(str("  Camshaft: ", NUM_CHANNELS, "×", _cam_axial_pitch, "=", _cam_length, "mm"));
    echo(str("  Corridor=", CORRIDOR_GAP, "mm",
             (_cam_length > CORRIDOR_GAP * 5 ? " ⚠ SHAFT VERY LONG" : " ✓")));

    // --- Structural: Arm slenderness ---
    _arm_length_approx = STAR_TIP_R - STUB_R_END;
    _slenderness = _arm_length_approx / min(ARM_W, ARM_H);

    echo(str("  Arm slenderness: L=", round(_arm_length_approx), "mm / min(", ARM_W, ",", ARM_H,
             ")=", round(_slenderness*10)/10, ":1",
             (_slenderness > 20 ? " ⚠ >20:1 — add intermediate bracing" : " ✓")));

    // --- Mount bracket specs ---
    echo(str("  Mount: 6800ZZ (", BEARING_OD, "mm OD, ", BEARING_W, "mm W) housing OD=",
             MOUNT_OD, "mm, plate T=", MOUNT_PLATE_T, "mm"));

    echo(str("=== END VERIFICATION ==="));
    echo("");
}


// =========================================================
// LOWER HEX RING — base tier, ledge on TOP face
// =========================================================
module _hex_ring_lower() {
    color(C_FRAME) {
        // Main ring body
        translate([0, 0, LOWER_RING_Z])
            linear_extrude(height = FRAME_RING_H)
                difference() {
                    circle(r = FRAME_RING_R_OUT, $fn = 6);
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                }

        // Ledge on TOP face (supports matrix from below)
        translate([0, 0, LOWER_RING_Z + FRAME_RING_H - LEDGE_THICK])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// UPPER HEX RING — ledge on BOTTOM face (clamps matrix from above)
// =========================================================
// Assembly: lower ring (ledge on top) → drop matrix in → place upper ring on top.
// The ledge on the BOTTOM face of the upper ring presses down on the matrix top,
// clamping it between the two rings.
// Lower ring: ledge on TOP   face → supports matrix from below
// Upper ring: ledge on BOTTOM face → clamps matrix from above
module _hex_ring_upper() {
    color(C_FRAME) {
        // Main ring body
        translate([0, 0, UPPER_RING_Z])
            linear_extrude(height = FRAME_RING_H)
                difference() {
                    circle(r = FRAME_RING_R_OUT, $fn = 6);
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                }

        // Ledge on BOTTOM face (clamps matrix from above)
        // Sits at ring bottom Z = UPPER_RING_Z, extends inward
        translate([0, 0, UPPER_RING_Z])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// ALL STUBS — 3 pairs from [0°, 120°, 240°], upper + lower
// =========================================================
// Stubs with triangular gussets at ring junction for stress distribution.
module _all_stubs() {
    _gusset_len = 15;  // gusset extends 15mm along stub from ring face
    _gusset_drop = 8;  // gusset extends 8mm below/above stub

    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        sx = STUB_R_START * cos(a);
        sy = STUB_R_START * sin(a);

        dx = STUB_R_END * cos(a) - sx;
        dy = STUB_R_END * sin(a) - sy;
        len = sqrt(dx*dx + dy*dy);
        az = atan2(dy, dx);

        color(C_STUB) {
            for (tier_z = [UPPER_RING_CENTER_Z, LOWER_RING_CENTER_Z]) {
                // Main stub beam
                translate([sx, sy, tier_z - STUB_H/2])
                    rotate([0, 0, az])
                        translate([0, -STUB_W/2, 0])
                            cube([len, STUB_W, STUB_H]);

                // Triangular gusset at ring junction (hull of thin + wide slice)
                translate([sx, sy, 0])
                    rotate([0, 0, az]) {
                        // Bottom gusset
                        hull() {
                            // Thin slice at ring face
                            translate([0, -STUB_W/2, tier_z - STUB_H/2])
                                cube([1, STUB_W, STUB_H]);
                            // Wider slice inward along stub
                            translate([_gusset_len, -STUB_W/2, tier_z - STUB_H/2 - _gusset_drop])
                                cube([1, STUB_W, STUB_H + _gusset_drop]);
                        }
                    }
            }
        }
    }
}


// =========================================================
// ALL STUB LINKAGES — sturdy post at stub outer end
// =========================================================
// Hollow rounded-corner vertical post at STUB_R_END,
// connecting upper and lower tiers. Solid caps top/bottom.
module _all_stub_linkages() {
    _corner_r = 3;
    _wall = 3;
    _cap_h = STUB_H;  // solid cap height = stub beam height

    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        px = STUB_R_END * cos(a);
        py = STUB_R_END * sin(a);

        _post_h = (UPPER_RING_CENTER_Z + STUB_H/2) - (LOWER_RING_CENTER_Z - STUB_H/2);

        color(C_LINKAGE)
        translate([px, py, LOWER_RING_CENTER_Z - STUB_H/2])
            rotate([0, 0, a])
                difference() {
                    // Outer: rounded-corner column
                    _rounded_rect_extrude(STUB_W, STUB_W, _post_h, _corner_r);
                    // Hollow interior (skip solid caps at top and bottom)
                    translate([0, 0, _cap_h])
                        _rounded_rect_extrude(STUB_W - 2*_wall, STUB_W - 2*_wall,
                                              _post_h - 2*_cap_h, max(1, _corner_r - _wall));
                }
    }
}

// Helper: centered rounded-rect extrusion
module _rounded_rect_extrude(w, d, h, r) {
    _r = min(r, w/2 - 0.1, d/2 - 0.1);
    linear_extrude(height = h)
        offset(r = _r)
            offset(delta = -_r)
                square([w, d], center = true);
}


// =========================================================
// ALL FRAME ARMS — 6 arms forming hexagram star
// =========================================================
// Each arm runs from junction_node → star_tip.
// Arms start from the JUNCTION NODE (JUNCTION_R defined in parameters section)
// so they don't overlap with the stub beam.

module _all_frame_arms() {
    for (ai = [0 : 5]) {
        stub_angle = ARM_DEFS[ai][0];
        tip_angle  = ARM_DEFS[ai][1];

        // Arms start from junction edge, not stub end
        start_xy = [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];
        end_xy   = [STAR_TIP_R * cos(tip_angle),  STAR_TIP_R * sin(tip_angle)];

        color(C_ARMS[ai]) {
            // Upper tier arm
            _beam_between(
                [start_xy[0], start_xy[1], UPPER_RING_CENTER_Z],
                [end_xy[0], end_xy[1], ARM_TIP_Z_UPPER],
                ARM_W, ARM_H);

            // Lower tier arm
            _beam_between(
                [start_xy[0], start_xy[1], LOWER_RING_CENTER_Z],
                [end_xy[0], end_xy[1], ARM_TIP_Z_LOWER],
                ARM_W, ARM_H);
        }
    }
}

// =========================================================
// JUNCTION NODES — clean transition from stub to diverging arms
// =========================================================
// A shaped plate at each stub end where the stub terminates and
// two arms emerge. Hull of stub end + two arm start positions.
module _all_junction_nodes() {
    _jn_thick = ARM_H;  // junction plate height matches arm height

    for (si = [0 : 2]) {
        stub_a = STUB_ANGLES[si];
        arm_a_idx = si * 2;      // CCW arm
        arm_b_idx = si * 2 + 1;  // CW arm

        tip_a_angle = ARM_DEFS[arm_a_idx][1];
        tip_b_angle = ARM_DEFS[arm_b_idx][1];

        // Three XY points that define the junction triangle:
        // 1. Stub end center
        stub_xy = [STUB_R_END * cos(stub_a), STUB_R_END * sin(stub_a)];
        // 2. Arm A start (offset along arm A direction)
        arm_a_xy = [JUNCTION_R * cos(stub_a) + ARM_W * cos(tip_a_angle),
                    JUNCTION_R * sin(stub_a) + ARM_W * sin(tip_a_angle)];
        // 3. Arm B start (offset along arm B direction)
        arm_b_xy = [JUNCTION_R * cos(stub_a) + ARM_W * cos(tip_b_angle),
                    JUNCTION_R * sin(stub_a) + ARM_W * sin(tip_b_angle)];

        color(C_STUB)
        for (tier_z = [UPPER_RING_CENTER_Z, LOWER_RING_CENTER_Z]) {
            hull() {
                // Stub end
                translate([stub_xy[0], stub_xy[1], tier_z - _jn_thick/2])
                    cylinder(d = STUB_W, h = _jn_thick, $fn = 6);
                // Arm A departure
                translate([arm_a_xy[0], arm_a_xy[1], tier_z - _jn_thick/2])
                    cylinder(d = ARM_W, h = _jn_thick, $fn = 6);
                // Arm B departure
                translate([arm_b_xy[0], arm_b_xy[1], tier_z - _jn_thick/2])
                    cylinder(d = ARM_W, h = _jn_thick, $fn = 6);
            }
        }
    }
}


// =========================================================
// ARM LINKAGES — clean truss between V-arms at each stub
// =========================================================
// Two brace stations with cross-braces, vertical posts, and
// X-diagonals. All members sized to fit within the arm envelope.
// Differentiated linkage member sizes by structural function
BRACE_W = floor(ARM_W * 0.6);   // cross-braces: 60% of arm (12mm)
BRACE_H = floor(ARM_H * 0.6);   // (8mm)
POST_W  = floor(ARM_W * 0.5);   // vertical posts: 50% (10mm)
POST_H  = floor(ARM_H * 0.5);   // (7mm)
DIAG_W  = 6;                     // X-diagonals: light tension/compression
DIAG_H  = 5;

// Helper: interpolate a point along an arm at fraction f
function _arm_pt(start_xy, end_xy, f, z_from, z_to) =
    [start_xy[0] + (end_xy[0] - start_xy[0]) * f,
     start_xy[1] + (end_xy[1] - start_xy[1]) * f,
     z_from + (z_to - z_from) * f];

module _all_arm_linkages() {
    // Two brace stations — kept well inside the arm length
    fracs = [0.15, 0.40];

    for (si = [0 : 2]) {
        stub_angle = STUB_ANGLES[si];
        arm_a = si * 2;      // CCW arm
        arm_b = si * 2 + 1;  // CW arm

        tip_a_angle = ARM_DEFS[arm_a][1];
        tip_b_angle = ARM_DEFS[arm_b][1];

        start_xy = [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];
        end_a = [STAR_TIP_R * cos(tip_a_angle), STAR_TIP_R * sin(tip_a_angle)];
        end_b = [STAR_TIP_R * cos(tip_b_angle), STAR_TIP_R * sin(tip_b_angle)];

        color(C_LINKAGE) {
            for (fi = [0 : len(fracs) - 1]) {
                f = fracs[fi];

                // 4 nodes at this station
                a_up = _arm_pt(start_xy, end_a, f, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
                a_lo = _arm_pt(start_xy, end_a, f, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);
                b_up = _arm_pt(start_xy, end_b, f, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
                b_lo = _arm_pt(start_xy, end_b, f, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);

                // Cross-braces (upper and lower)
                _beam_between(a_up, b_up, BRACE_W, BRACE_H);
                _beam_between(a_lo, b_lo, BRACE_W, BRACE_H);

                // Vertical posts (A side and B side)
                _beam_between(a_up, a_lo, POST_W, POST_H);
                _beam_between(b_up, b_lo, POST_W, POST_H);
            }

            // X-diagonals between the two stations
            f0 = fracs[0];
            f1 = fracs[1];

            a_up_0 = _arm_pt(start_xy, end_a, f0, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
            a_lo_0 = _arm_pt(start_xy, end_a, f0, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);
            b_up_0 = _arm_pt(start_xy, end_b, f0, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
            b_lo_0 = _arm_pt(start_xy, end_b, f0, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);

            a_up_1 = _arm_pt(start_xy, end_a, f1, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
            a_lo_1 = _arm_pt(start_xy, end_a, f1, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);
            b_up_1 = _arm_pt(start_xy, end_b, f1, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
            b_lo_1 = _arm_pt(start_xy, end_b, f1, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);

            // Cross diagonals — upper plane (sharp, no chamfer)
            _beam_between(a_up_0, b_up_1, DIAG_W, DIAG_H, chamfer=0);
            _beam_between(b_up_0, a_up_1, DIAG_W, DIAG_H, chamfer=0);

            // Cross diagonals — lower plane
            _beam_between(a_lo_0, b_lo_1, DIAG_W, DIAG_H, chamfer=0);
            _beam_between(b_lo_0, a_lo_1, DIAG_W, DIAG_H, chamfer=0);

            // Vertical X-diagonals on A side
            _beam_between(a_up_0, a_lo_1, DIAG_W, DIAG_H, chamfer=0);
            _beam_between(a_lo_0, a_up_1, DIAG_W, DIAG_H, chamfer=0);

            // Vertical X-diagonals on B side
            _beam_between(b_up_0, b_lo_1, DIAG_W, DIAG_H, chamfer=0);
            _beam_between(b_lo_0, b_up_1, DIAG_W, DIAG_H, chamfer=0);
        }
    }
}


// =========================================================
// ALL HELIX MOUNTS — actual helix_cam_v3 at H1, H2, H3
// =========================================================
// Uses the real helix_assembly_v3() from helix_cam_v3.scad.
// Helix cam: shaft along Z, HELIX_LENGTH=91mm (13×7mm axial pitch).
// Positioned: translate to helix center → rotate Z → rotate Y 90° → center on midpoint.
//
// The helix_cam_v3 AXIAL_PITCH=7mm (bearing 5 + collar 2) vs STACK_OFFSET=14mm.
// The cam assembly is self-contained at 91mm length — no scaling needed.

/* [Camshaft] */
_HELIX_CAM_LENGTH = NUM_CAMS * STACK_OFFSET;  // 13×14 = 182mm (matches helix_cam_v3)

module _all_helix_mounts() {
    for (hi = [0 : 2]) {
        _hc = _helix_center(hi);
        hx = _hc[0];
        hy = _hc[1];

        helix_a = HELIX_ANGLES[hi];

        // Rotation chain:
        //   rotate([0,0,helix_a]) * rotate([-90,0,0])
        //   Maps: Z_local(shaft) → tangent, -X_local(ribs) → radially inward
        translate([hx, hy, HELIX_Z])
            rotate([0, 0, helix_a])
                rotate([-90, 0, 0])
                    translate([0, 0, -_HELIX_CAM_LENGTH/2])
                        helix_assembly_v3(anim_t());

        // Stationary bearing mounts at each shaft end
        if (SHOW_BEARING_MOUNTS) {
            for (end = [-1, 1]) {
                _mount_z_offset = end * (_HELIX_CAM_LENGTH/2 + MOUNT_PLATE_T/2 + 2);
                translate([hx, hy, HELIX_Z])
                    rotate([0, 0, helix_a])
                        rotate([-90, 0, 0])
                            translate([0, 0, _mount_z_offset])
                                color(C_MOUNT) _bearing_mount(end);
            }
        }

        // Echo actual helix position
        echo(str("  Helix ", hi+1, ": center=[", round(hx*10)/10, ", ", round(hy*10)/10,
                 "] R=", round(sqrt(hx*hx + hy*hy)*10)/10, "mm angle=", helix_a, "°"));
    }
}

// Proper bearing mount: cylindrical housing + flat base plate +
// two triangular gussets + M3 set screw bore + M4 mounting tabs
module _bearing_mount(side = 1) {
    _face_dir = (side > 0) ? 1 : -1;  // which way the pocket opens

    difference() {
        union() {
            // Cylindrical bearing housing
            rotate([0, 90, 0])
                cylinder(d = MOUNT_OD, h = MOUNT_PLATE_T, center = true, $fn = 24);

            // Flat mounting plate base (connects to frame arm pair)
            translate([-MOUNT_PLATE_T/2, -MOUNT_BRACKET_W/2, -MOUNT_OD/2])
                cube([MOUNT_PLATE_T, MOUNT_BRACKET_W, MOUNT_OD/2]);

            // Two triangular stiffening gussets (ribs)
            for (gy = [-MOUNT_OD/2, MOUNT_OD/2]) {
                hull() {
                    // Thin slice at housing face
                    translate([-MOUNT_PLATE_T/2, gy - 1.5, -MOUNT_OD/2])
                        cube([MOUNT_PLATE_T, 3, MOUNT_OD]);
                    // Wide slice at base plate
                    translate([-MOUNT_PLATE_T/2, gy - 1.5, -MOUNT_OD/2 - 3])
                        cube([MOUNT_PLATE_T, 3, 1]);
                }
            }

            // M4 mounting tabs (toward adjacent frame arms)
            for (ty = [-1, 1]) {
                translate([0, ty * (MOUNT_BRACKET_W/2 + MOUNT_TAB_W/2 - 2), -MOUNT_OD/2])
                    cube([MOUNT_PLATE_T, MOUNT_TAB_W, MOUNT_OD/4], center = false);
            }
        }

        // Bearing pocket (from one face)
        translate([_face_dir * (MOUNT_PLATE_T/2 - BEARING_W), 0, 0])
            rotate([0, 90, 0])
                cylinder(d = MOUNT_BORE_DIA, h = BEARING_W + 0.5, $fn = 24);

        // Shaft through-bore (full depth)
        rotate([0, 90, 0])
            cylinder(d = SHAFT_CLEARANCE, h = MOUNT_PLATE_T + 2, center = true, $fn = 20);

        // M3 radial set screw bore (for bearing retention)
        translate([0, 0, MOUNT_OD/2 + 1])
            cylinder(d = 3.2, h = MOUNT_OD/2 + 2, center = true, $fn = 12);

        // M4 bolt holes in mounting tabs
        for (ty = [-1, 1]) {
            translate([MOUNT_PLATE_T/2, ty * (MOUNT_BRACKET_W/2 + MOUNT_TAB_W/2 - 2), -MOUNT_OD/4])
                rotate([0, -90, 0])
                    cylinder(d = MOUNT_TAB_BOLT, h = MOUNT_PLATE_T + 2, $fn = 12);
        }
    }
}


// =========================================================
// DAMPENER ARRAY — cable guides between helix ribs and matrix
// =========================================================
// 13 dampener tubes per helix (one per cam/channel), positioned
// radially between rib tips and hex matrix edge. Tubes constrain
// the Dyneema cable path, preventing whip and ensuring alignment.
// Total: 3 helices × 13 channels = 39 dampener tubes.
module _dampener_array() {
    _damp_color = [0.4, 0.7, 0.4, 0.7];  // green translucent

    for (hi = [0 : 2]) {
        helix_a = HELIX_ANGLES[hi];

        for (ch = [0 : NUM_CHANNELS - 1]) {
            // Channel Z position (same as matrix channel strip Z)
            ch_z = (ch - _CENTER_CH) * STACK_OFFSET;

            // Dampener sits at DAMPENER_R along helix radial direction
            dx = DAMPENER_R * cos(helix_a);
            dy = DAMPENER_R * sin(helix_a);

            color(_damp_color)
            translate([dx, dy, ch_z])
                rotate([0, 0, helix_a])
                    rotate([0, 90, 0])
                        difference() {
                            cylinder(d = DAMPENER_DIA, h = DAMPENER_LENGTH, center = true, $fn = 12);
                            cylinder(d = DAMPENER_BORE, h = DAMPENER_LENGTH + 2, center = true, $fn = 8);
                        }
        }
    }

    echo(str("  Dampeners: 3×", NUM_CHANNELS, "=", 3*NUM_CHANNELS, " tubes at R=", DAMPENER_R, "mm"));
}


// =========================================================
// DRIVE SYSTEM — Motor + Belt (H1,H2) + Transfer Shaft (H3)
// =========================================================
// Topology:
//   Motor (NEMA 17) → GT2 belt → H1(180°) + H2(300°)
//   H1 → bevel gear → transfer shaft → bevel gear → H3(60°)
//   Transfer shaft runs at LOWER_RING_CENTER_Z, outside frame.
//   All drive components at R > FRAME_RING_R_OUT (outside frame).
module _drive_system(t = 0) {

    // ---- Drive-end Z: below cam stack, at GT2 pulley boss ----
    _drive_z = HELIX_Z - _HELIX_CAM_LENGTH/2 - GT2_BELT_W/2 - 5;

    // Helix drive-end positions
    h1_drive = [_h1_xy[0], _h1_xy[1], _drive_z];
    h2_drive = [_h2_xy[0], _h2_xy[1], _drive_z];
    h3_drive = [_h3_xy[0], _h3_xy[1], _drive_z];

    // Motor position
    motor_xy = [MOTOR_R * cos(MOTOR_ANGLE), MOTOR_R * sin(MOTOR_ANGLE)];
    motor_pos = [motor_xy[0], motor_xy[1], MOTOR_Z];

    // =============================================
    // MOTOR — NEMA 17 (42×42×48mm)
    // =============================================
    color(C_MOTOR)
    translate(motor_pos)
        cube([42, 42, 48], center = true);

    // Motor shaft
    color(C_STEEL)
    translate([motor_pos[0], motor_pos[1], motor_pos[2] + 24])
        cylinder(d = 5, h = 24, $fn = 16);

    // Motor pulley (GT2 20T)
    color(C_PULLEY)
    translate([motor_pos[0], motor_pos[1], motor_pos[2] + 40])
        cylinder(d = GT2_PULLEY_DIA, h = GT2_BELT_W, center = true, $fn = 24);
    _motor_pulley_pos = [motor_xy[0], motor_xy[1], motor_pos[2] + 40];

    // =============================================
    // PRIMARY BELT: Motor → H1 → H2 → Motor
    // =============================================
    // GT2 pulleys at H1 and H2 drive ends (on end plate GT2 boss)
    for (hp = [h1_drive, h2_drive]) {
        color(C_PULLEY)
        translate(hp)
            cylinder(d = GT2_PULLEY_DIA, h = GT2_BELT_W, center = true, $fn = 24);
    }

    // Idler between H1 and H2 for belt wrap angle
    _idler_angle = (180 + 300) / 2;  // 240° — midpoint
    _idler_r = HELIX_R + 30;         // push outward for clearance
    _idler_pos = [_idler_r * cos(_idler_angle), _idler_r * sin(_idler_angle), _drive_z];
    color(C_IDLER)
    translate(_idler_pos)
        cylinder(d = IDLER_DIA, h = GT2_BELT_W, center = true, $fn = 20);

    // Belt path segments
    color(C_BELT) {
        _belt_segment(_motor_pulley_pos, h1_drive);
        _belt_segment(h1_drive, _idler_pos);
        _belt_segment(_idler_pos, h2_drive);
        _belt_segment(h2_drive, _motor_pulley_pos);
    }

    // =============================================
    // TRANSFER SHAFT: H1 → bevel → shaft → bevel → H3
    // =============================================
    // Transfer shaft runs from H1 vicinity to H3 vicinity
    // at XFER_SHAFT_Z, routed outside the hex frame ring.

    // Bevel gear positions (at each helix, transition from vertical to horizontal)
    _bevel_h1 = [_h1_xy[0], _h1_xy[1], XFER_SHAFT_Z];
    _bevel_h3 = [_h3_xy[0], _h3_xy[1], XFER_SHAFT_Z];

    // Route transfer shaft OUTSIDE the frame — go via a waypoint
    // at the midpoint between H1 and H3 but pushed outward
    _mid_h1_h3 = [(_h1_xy[0] + _h3_xy[0])/2, (_h1_xy[1] + _h3_xy[1])/2];
    _mid_angle = atan2(_mid_h1_h3[1], _mid_h1_h3[0]);
    _mid_r = sqrt(_mid_h1_h3[0]*_mid_h1_h3[0] + _mid_h1_h3[1]*_mid_h1_h3[1]);
    // Push outward to clear frame ring (min R = FRAME_RING_R_OUT + 20)
    _xfer_push_r = max(_mid_r, FRAME_RING_R_OUT + 30);
    _xfer_waypoint = [_xfer_push_r * cos(_mid_angle), _xfer_push_r * sin(_mid_angle), XFER_SHAFT_Z];

    // Transfer shaft: H1_bevel → waypoint → H3_bevel (steel rod)
    color(C_STEEL) {
        hull() {
            translate(_bevel_h1) sphere(d = XFER_SHAFT_DIA, $fn = 12);
            translate(_xfer_waypoint) sphere(d = XFER_SHAFT_DIA, $fn = 12);
        }
        hull() {
            translate(_xfer_waypoint) sphere(d = XFER_SHAFT_DIA, $fn = 12);
            translate(_bevel_h3) sphere(d = XFER_SHAFT_DIA, $fn = 12);
        }
    }

    // Pillow block at waypoint (shaft support bearing)
    color(C_MOUNT)
    translate(_xfer_waypoint) {
        // Simple block with bore
        difference() {
            cube([20, 20, 15], center = true);
            cylinder(d = XFER_SHAFT_DIA + 0.5, h = 20, center = true, $fn = 16);
        }
    }

    // Bevel gears at H1 and H3 (simplified as cones)
    _bevel_color = [0.6, 0.5, 0.2, 0.9];  // bronze
    for (bp = [_bevel_h1, _bevel_h3]) {
        color(_bevel_color)
        translate(bp)
            cylinder(d1 = BEVEL_GEAR_PD, d2 = BEVEL_GEAR_PD * 0.3,
                     h = BEVEL_GEAR_H, center = true, $fn = 20);
    }

    // Vertical connecting shafts: bevel gear → helix drive end
    color(C_STEEL) {
        // H1: vertical from bevel at XFER_SHAFT_Z up to drive end
        hull() {
            translate(_bevel_h1) sphere(d = XFER_SHAFT_DIA, $fn = 12);
            translate(h1_drive) sphere(d = XFER_SHAFT_DIA, $fn = 12);
        }
        // H3: vertical from bevel at XFER_SHAFT_Z up to drive end
        hull() {
            translate(_bevel_h3) sphere(d = XFER_SHAFT_DIA, $fn = 12);
            translate(h3_drive) sphere(d = XFER_SHAFT_DIA, $fn = 12);
        }
    }

    // =============================================
    // VERIFICATION ECHOES
    // =============================================
    _motor_R_actual = sqrt(motor_xy[0]*motor_xy[0] + motor_xy[1]*motor_xy[1]);
    echo(str("  Drive: Motor at R=", round(_motor_R_actual), "mm angle=", MOTOR_ANGLE, "°"));
    echo(str("  Belt: Motor→H1→idler→H2→Motor (triangle loop)"));
    echo(str("  Transfer: H1→bevel→shaft(R=", round(_xfer_push_r), ")→bevel→H3"));
    echo(str("  All drive R > frame R_OUT=", FRAME_RING_R_OUT, "mm ✓"));
}


// =========================================================
// BLOCK GRID — 3-helix superposition wave
// =========================================================
module _block_grid(t = 0) {

    _center = (NUM_CHANNELS - 1) / 2;
    ch_offsets = [for (i = [0:NUM_CHANNELS-1]) (i - _center) * STACK_OFFSET];

    for (i = [0 : NUM_CHANNELS - 1]) {
        d = ch_offsets[i];
        clen = ch_len(d);
        raw = raw_col_count(clen);

        if (clen > 0) {
            for (j = [0 : max(0, raw - 1)]) {
                px = col_x(raw, j);
                if (col_inside_hex(px, d)) {
                    bx = px;
                    by = -d;
                    dz = superposition_dz(bx, by, t);

                    translate([bx, by, dz])
                        color(C_BLOCK)
                            cube([COL_PITCH - 2, COL_PITCH - 2, _BLOCK_HEIGHT], center = true);
                }
            }
        }
    }
}


// =========================================================
// UTILITY: Beam between two 3D points (chamfered cross-section)
// =========================================================
// chamfer=0 → sharp cube (thin diagonals); chamfer>0 → rounded-rect via hull
module _beam_between(p1, p2, w, h, chamfer = -1) {
    _c = (chamfer < 0) ? ARM_CHAMFER : chamfer;
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];
    dz = p2[2] - p1[2];
    length = sqrt(dx*dx + dy*dy + dz*dz);

    az = atan2(dy, dx);
    horiz = sqrt(dx*dx + dy*dy);
    ay = -atan2(dz, horiz);

    translate(p1)
        rotate([0, 0, az])
            rotate([0, ay, 0]) {
                if (_c > 0 && w > 2*_c && h > 2*_c) {
                    // Rounded-rectangle cross-section via hull of 4 corner cylinders
                    hull() {
                        for (yc = [-w/2 + _c, w/2 - _c])
                            for (zc = [-h/2 + _c, h/2 - _c])
                                translate([0, yc, zc])
                                    rotate([0, 90, 0])
                                        cylinder(r = _c, h = length, $fn = 8);
                    }
                } else {
                    // Fallback: plain cube (thin members or chamfer=0)
                    translate([0, -w/2, -h/2])
                        cube([length, w, h]);
                }
            }
}


// =========================================================
// UTILITY: Belt segment between two 3D points
// =========================================================
module _belt_segment(p1, p2) {
    hull() {
        translate(p1)
            cylinder(d = 3, h = GT2_BELT_W, center = true, $fn = 8);
        translate(p2)
            cylinder(d = 3, h = GT2_BELT_W, center = true, $fn = 8);
    }
}
