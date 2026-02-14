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

$fn = 24;  // frame quality

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// MATRIX DIMENSIONS (must match main_stack_v3)
// =============================================
HEX_R          = 118;
STACK_OFFSET   = 14.0;
ECCENTRICITY   = 15.0;
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

/* [Hexagram Star — 6 main frame arms, two interlocking triangles] */
V_ANGLE           = 74;       // [10:1:120] opening angle between each arm pair
ARM_W             = 12;       // [4:1:25] arm width
ARM_H             = 10;       // [3:1:20] arm height
// User spec: star tips at 1.5× the hex longest diameter from center
STAR_TIP_R        = 1.5 * HEX_LONGEST_DIA;    // 354mm from center

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
CORRIDOR_GAP      = 60;       // mm between arm centers at helix crossing

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

/* [Helix Mount Bracket] */
MOUNT_PLATE_T     = 7;
MOUNT_BRACKET_W   = 40;       // wider for helix cam (13 cams × 7mm = 91mm)
MOUNT_BRACKET_H   = 50;
MOUNT_BORE_DIA    = 12;

/* [Drive System — GT2 Timing Belt] */
GT2_PULLEY_DIA    = 12.73;    // 20T × 2mm / π
GT2_BELT_W        = 6;
IDLER_DIA         = 12;

MOTOR_ANGLE       = 210;
MOTOR_R           = HELIX_R + 40;
MOTOR_Z           = LOWER_RING_Z - 50;

// Idler positions (computed for ≥120° wrap, scaled to new HELIX_R)
// These will be recomputed after we know the exact helix XY positions
_h1_xy = [HELIX_R * cos(180), HELIX_R * sin(180)];
_h2_xy = [HELIX_R * cos(300), HELIX_R * sin(300)];
_h3_xy = [HELIX_R * cos(60),  HELIX_R * sin(60)];

// Idlers at midpoints between adjacent helices, pushed outward
_i1_mid = [(_h1_xy[0] + _h3_xy[0])/2, (_h1_xy[1] + _h3_xy[1])/2];
_i2_mid = [(_h3_xy[0] + _h2_xy[0])/2, (_h3_xy[1] + _h2_xy[1])/2];
_i3_mid = [(_h2_xy[0] + _h1_xy[0])/2, (_h2_xy[1] + _h1_xy[1])/2];

// Push idlers outward from center by 20% for belt clearance
_i_push = 1.15;
IDLER1_XY = [_i1_mid[0] * _i_push, _i1_mid[1] * _i_push];
IDLER2_XY = [_i2_mid[0] * _i_push, _i2_mid[1] * _i_push];
IDLER3_XY = [_i3_mid[0] * _i_push, _i3_mid[1] * _i_push];

/* [Block Grid] */
BLOCK_DROP        = 100.0;
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
// Helix 60°:  Arm 1 (0°→30°) and Arm 2 (120°→90°)
// Helix 180°: Arm 3 (120°→150°) and Arm 4 (240°→210°)
// Helix 300°: Arm 5 (240°→270°) and Arm 0 (0°→330°)
HELIX_ARM_PAIRS = [[1, 2], [3, 4], [5, 0]];

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
SHOW_DRIVE          = false;
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

    // ---- 6 MAIN FRAME ARMS (hexagram star) ----
    if (SHOW_ARMS)
        _all_frame_arms();

    // ---- ARM LINKAGES (purple) — between arm pairs at each stub ----
    if (SHOW_ARM_LINKS)
        _all_arm_linkages();

    // ---- HELIX MOUNTS ----
    if (SHOW_HELIX_MOUNTS)
        _all_helix_mounts();

    // ---- DRIVE SYSTEM (GT2 belt + pulleys + idlers) ----
    if (SHOW_DRIVE)
        _drive_system(t);

    // ---- BLOCK GRID ----
    if (SHOW_BLOCKS)
        translate([0, 0, BLOCK_Z])
            _block_grid(t);

    // ---- ECHOES ----
    echo(str("=== HEX FRAME V3 (HEXAGRAM STAR) ==="));
    echo(str("Star tip R=", STAR_TIP_R, "mm (1.5× hex dia ", HEX_LONGEST_DIA, "mm)"));
    echo(str("Hexagram inner R=", round(HEXAGRAM_INNER_R*10)/10, "mm"));
    echo(str("Helix R=", HELIX_R, "mm (parallel corridor, gap=", CORRIDOR_GAP, "mm)"));
    echo(str("Upper ring Z=", UPPER_RING_Z, " center=", UPPER_RING_CENTER_Z));
    echo(str("Lower ring Z=", LOWER_RING_Z, " center=", LOWER_RING_CENTER_Z));
    echo(str("Ring gap: ", UPPER_RING_Z - (LOWER_RING_Z + FRAME_RING_H), "mm"));
    echo(str("Tier gap Z (center-center): ", round(TIER_GAP_Z*10)/10, "mm"));
    echo(str("Helix Z=", round(HELIX_Z*10)/10, " (convergence point)"));
    echo(str("Corridor: ", CORRIDOR_GAP, "mm gap at helix crossings"));
    echo(str("Matrix rotation: ", MATRIX_ROTATE_Z, "° (adjust to check slider alignment)"));
    echo(str("Drive: GT2 20T (", GT2_PULLEY_DIA, "mm PD), belt ", GT2_BELT_W, "mm wide"));
    echo(str("Blocks Z=", BLOCK_Z, " (", BLOCK_DROP, "mm below GP2)"));
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
// UPPER HEX RING — same as lower, rotated 180° around X-axis
// =========================================================
// Rotating the lower ring geometry 180° around X flips it vertically,
// putting the ledge on the BOTTOM face. We position it at UPPER_RING_Z.
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
        // = ledge at bottom of ring body (z = UPPER_RING_Z)
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
// Solid block stubs — full width, no gaps.
module _all_stubs() {
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
                translate([sx, sy, tier_z - STUB_H/2])
                    rotate([0, 0, az])
                        translate([0, -STUB_W/2, 0])
                            cube([len, STUB_W, STUB_H]);
            }
        }
    }
}


// =========================================================
// ALL STUB LINKAGES — sturdy post at stub outer end
// =========================================================
// A solid vertical post at STUB_R_END (where stub meets long arms),
// connecting upper and lower tiers.
module _all_stub_linkages() {
    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        // Post at outer end of stub
        px = STUB_R_END * cos(a);
        py = STUB_R_END * sin(a);

        _post_h = (UPPER_RING_CENTER_Z + STUB_H/2) - (LOWER_RING_CENTER_Z - STUB_H/2);

        color(C_LINKAGE)
        translate([px, py, LOWER_RING_CENTER_Z - STUB_H/2])
            rotate([0, 0, a])
                translate([-STUB_W/2, -STUB_W/2, 0])
                    cube([STUB_W, STUB_W, _post_h]);
    }
}


// =========================================================
// ALL FRAME ARMS — 6 arms forming hexagram star
// =========================================================
// Each arm runs from stub_end → star_tip (pure hexagram geometry).
// Upper arms slope DOWN to ARM_TIP_Z_UPPER, lower slope UP to ARM_TIP_Z_LOWER.
// At CONVERGE_PCT=100 both meet at midpoint; at 0 they stay parallel.
module _all_frame_arms() {
    for (ai = [0 : 5]) {
        stub_angle = ARM_DEFS[ai][0];
        tip_angle  = ARM_DEFS[ai][1];

        start_xy = [STUB_R_END * cos(stub_angle), STUB_R_END * sin(stub_angle)];
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
// ARM LINKAGES — clean truss between V-arms at each stub
// =========================================================
// Two brace stations with cross-braces, vertical posts, and
// X-diagonals. All members sized to fit within the arm envelope.
LINK_W = ARM_W;    // match arm width so nothing pokes out
LINK_H = ARM_H;    // match arm height
DIAG_W = 6;        // diagonal brace width
DIAG_H = 5;        // diagonal brace height

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

        start_xy = [STUB_R_END * cos(stub_angle), STUB_R_END * sin(stub_angle)];
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
                _beam_between(a_up, b_up, LINK_W, LINK_H);
                _beam_between(a_lo, b_lo, LINK_W, LINK_H);

                // Vertical posts (A side and B side)
                _beam_between(a_up, a_lo, LINK_W, LINK_H);
                _beam_between(b_up, b_lo, LINK_W, LINK_H);
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

            // Cross diagonals — upper plane
            _beam_between(a_up_0, b_up_1, DIAG_W, DIAG_H);
            _beam_between(b_up_0, a_up_1, DIAG_W, DIAG_H);

            // Cross diagonals — lower plane
            _beam_between(a_lo_0, b_lo_1, DIAG_W, DIAG_H);
            _beam_between(b_lo_0, a_lo_1, DIAG_W, DIAG_H);

            // Vertical X-diagonals on A side
            _beam_between(a_up_0, a_lo_1, DIAG_W, DIAG_H);
            _beam_between(a_lo_0, a_up_1, DIAG_W, DIAG_H);

            // Vertical X-diagonals on B side
            _beam_between(b_up_0, b_lo_1, DIAG_W, DIAG_H);
            _beam_between(b_lo_0, b_up_1, DIAG_W, DIAG_H);
        }
    }
}


// =========================================================
// ALL HELIX MOUNTS — at crossing point between parallel arms
// =========================================================
/* [Camshaft] */
CAMSHAFT_RADIAL_OFFSET = 50;  // [-100:5:100] move camshaft toward(−) or away(+) from center
CAMSHAFT_EXTEND  = 50;       // [0:5:200] extra length per side beyond cam section
CAMSHAFT_DIA     = 10;       // [5:1:20] shaft diameter
// Total = cam section + 2× extend
CAMSHAFT_CAM_LEN = NUM_CAMS * STACK_OFFSET;   // 182mm cam section
CAMSHAFT_TOTAL   = CAMSHAFT_CAM_LEN + 2 * CAMSHAFT_EXTEND;

module _all_helix_mounts() {
    for (hi = [0 : 2]) {
        ha = HELIX_ANGLES[hi];
        tier_angle = TIER_ANGLES[hi];
        shaft_angle = tier_angle + 90;

        _eff_R = HELIX_R + CAMSHAFT_RADIAL_OFFSET;
        hx = _eff_R * cos(ha);
        hy = _eff_R * sin(ha);

        // Camshaft — centered at helix position, along shaft_angle
        color(C_PULLEY)
        translate([hx, hy, HELIX_Z])
            rotate([0, 0, shaft_angle])
                rotate([0, 90, 0])
                    cylinder(d = CAMSHAFT_DIA, h = CAMSHAFT_TOTAL, center = true, $fn = 16);

        // Mount brackets at each END of the camshaft
        for (side = [-1, 1]) {
            // Shaft direction unit vector
            _sdx = cos(shaft_angle);
            _sdy = sin(shaft_angle);
            // Bracket position = helix center + half total length along shaft direction
            _bx = hx + side * (CAMSHAFT_TOTAL/2) * _sdx;
            _by = hy + side * (CAMSHAFT_TOTAL/2) * _sdy;

            color(C_MOUNT)
            translate([_bx, _by, HELIX_Z])
                rotate([0, 0, shaft_angle]) {
                    difference() {
                        translate([-MOUNT_PLATE_T/2, -MOUNT_BRACKET_W/2, -MOUNT_BRACKET_H/2])
                            cube([MOUNT_PLATE_T, MOUNT_BRACKET_W, MOUNT_BRACKET_H]);
                        rotate([0, 90, 0])
                            cylinder(d = MOUNT_BORE_DIA, h = MOUNT_PLATE_T + 2,
                                     center = true, $fn = 24);
                    }
                }
        }
    }
}


// =========================================================
// DRIVE SYSTEM — GT2 Belt + Pulleys + 3 Idlers
// =========================================================
// Belt path (convex hull order for non-crossing):
//   Motor → H1(180°) → I1 → H3(60°) → I2 → H2(300°) → I3 → Motor
module _drive_system(t = 0) {

    // Helix positions (all at HELIX_Z)
    h1 = [HELIX_R * cos(180), HELIX_R * sin(180), HELIX_Z];
    h2 = [HELIX_R * cos(300), HELIX_R * sin(300), HELIX_Z];
    h3 = [HELIX_R * cos(60),  HELIX_R * sin(60),  HELIX_Z];

    // Motor position
    motor_xy = [MOTOR_R * cos(MOTOR_ANGLE), MOTOR_R * sin(MOTOR_ANGLE)];
    motor_pos = [motor_xy[0], motor_xy[1], MOTOR_Z];

    // Idler positions (at HELIX_Z)
    i1 = [IDLER1_XY[0], IDLER1_XY[1], HELIX_Z];
    i2 = [IDLER2_XY[0], IDLER2_XY[1], HELIX_Z];
    i3 = [IDLER3_XY[0], IDLER3_XY[1], HELIX_Z];

    // Motor box (NEMA 17)
    color(C_MOTOR)
    translate(motor_pos)
        cube([42, 42, 48], center = true);

    // Motor shaft
    color([0.7, 0.7, 0.75, 1.0])
    translate([motor_pos[0], motor_pos[1], motor_pos[2] + 28])
        cylinder(d = 5, h = 20, $fn = 16);

    // Motor pulley
    motor_pulley_z = motor_pos[2] + 42;
    color(C_PULLEY)
    translate([motor_pos[0], motor_pos[1], motor_pulley_z])
        cylinder(d = GT2_PULLEY_DIA, h = GT2_BELT_W, center = true, $fn = 24);

    // Drive pulleys at each helix
    for (hp = [h1, h2, h3]) {
        color(C_PULLEY)
        translate(hp)
            cylinder(d = GT2_PULLEY_DIA, h = GT2_BELT_W, center = true, $fn = 24);
    }

    // Idler pulleys
    for (ip = [i1, i2, i3]) {
        color(C_IDLER)
        translate(ip)
            cylinder(d = IDLER_DIA, h = GT2_BELT_W, center = true, $fn = 20);
    }

    // Belt path: Motor → H1 → I1 → H3 → I2 → H2 → I3 → Motor
    motor_belt = [motor_pos[0], motor_pos[1], motor_pulley_z];
    color(C_BELT) {
        _belt_segment(motor_belt, h1);
        _belt_segment(h1, i1);
        _belt_segment(i1, h3);
        _belt_segment(h3, i2);
        _belt_segment(i2, h2);
        _belt_segment(h2, i3);
        _belt_segment(i3, motor_belt);
    }
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
                            cube([COL_PITCH - 2, COL_PITCH - 2, 8], center = true);
                }
            }
        }
    }
}


// =========================================================
// UTILITY: Beam between two 3D points
// =========================================================
module _beam_between(p1, p2, w, h) {
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];
    dz = p2[2] - p1[2];
    length = sqrt(dx*dx + dy*dy + dz*dz);

    az = atan2(dy, dx);
    horiz = sqrt(dx*dx + dy*dy);
    ay = -atan2(dz, horiz);

    translate(p1)
        rotate([0, 0, az])
            rotate([0, ay, 0])
                translate([0, -w/2, -h/2])
                    cube([length, w, h]);
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
