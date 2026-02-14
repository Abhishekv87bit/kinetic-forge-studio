// =========================================================
// HEX FRAME V4.3 — Clean Frame with Arm-Mounted Components
// =========================================================
// Structural skeleton for the Triple Helix kinetic sculpture.
// Standards: ISO 128 (technical drawing), DFAM (3D print design)
//
// V4.3 changes (from requirements REQ-RING1 through REQ-CLN1):
//   - Ring sandwich sleeve: ledge-top ring at upper Z, ledge-bot at lower Z
//     Ledges face inward forming a sleeve that captures hex matrix
//   - Drive system removed (REQ-DS1)
//   - Convergence hex rings removed, replaced with tip bridges (REQ-CN1)
//   - Bearing brackets ON arm @75 markers, not at helix center (REQ-BM1)
//   - Extension rods from cam journals to arm bearing mounts (REQ-EXT1)
//   - Dampener bars as frame geometry at arm @50 markers (REQ-DMP1)
//   - Stub linkage posts: hex cylinders at JU markers (REQ-STB1)
//   - All legacy/redundant geometry removed (REQ-CLN1)
//
// FRAME ARCHITECTURE (Top-Down):
//   Central hex matrix (HEX_R=118) at origin.
//   Hex ring surrounds it (R_IN=120, R_OUT=130).
//   SLEEVE: upper ring (ledge-top, hangs down) + lower ring (ledge-bot, pokes up)
//   3 STUBS at [0, 120, 240] — clean radial beams.
//   3 HEX POST LINKAGES at JU0/JU1/JU2 — vertical hex cylinders.
//   6 HEXAGRAM ARMS with hex nodes at 0/25/50/75/100%.
//   3 TIP BRIDGES — rectangular beams connecting arm tip pairs.
//   Bearing brackets at @75 on each arm, dampeners at @50.
//   Extension rods from cam stacks to bearing brackets.
// =========================================================

include <config_v4.scad>
use <main_stack_v4.scad>
use <helix_cam_v4.scad>

$fn = 24;  // frame quality (lower than tier $fn=40 for performance)

// =============================================
// FRAME PARAMETERS (frame-specific, not in config)
// =============================================

/* [Frame Rings] */
FRAME_RING_H      = 12;
FRAME_RING_W      = 10;
FRAME_RING_R_IN   = HEX_R + 2;                          // 120mm
FRAME_RING_R_OUT  = FRAME_RING_R_IN + FRAME_RING_W;     // 130mm

// Z positions: SLEEVE SANDWICH — rings swap so ledges face inward
// "Ledge-top" ring sits ABOVE matrix → ledge hangs DOWN into matrix
// "Ledge-bottom" ring sits BELOW matrix → ledge pokes UP into matrix
// Together they form a sleeve capturing the hex matrix block
UPPER_RING_Z      = TIER1_TOP;                           // +45 (ledge-top ring here)
LOWER_RING_Z      = TIER3_BOT - FRAME_RING_H;           // -57 (ledge-bottom ring here)
UPPER_RING_CENTER_Z = UPPER_RING_Z + FRAME_RING_H / 2;  // +51
LOWER_RING_CENTER_Z = LOWER_RING_Z + FRAME_RING_H / 2;  // -51
TIER_GAP_Z        = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z;  // 102mm

/* [Inward Ledge] */
LEDGE_WIDTH       = 6;
LEDGE_THICK       = 3;
LEDGE_R_IN        = FRAME_RING_R_IN - LEDGE_WIDTH;      // 114mm

/* [Hexagram Star — 6 main frame arms] */
V_ANGLE           = 74;
ARM_W             = 20;
ARM_H             = 14;

/* [Stubs — clean gusset plates from NON-helix vertices] */
STUB_ANGLES       = [0, 120, 240];
STUB_LENGTH       = 30;
STUB_INWARD       = 8;
STUB_W            = 20;        // reduced width — cleaner profile
STUB_H            = ARM_H;     // match arm thickness for visual consistency
STUB_R_START      = FRAME_RING_R_OUT - STUB_INWARD;     // 122mm
STUB_R_END        = FRAME_RING_R_OUT + STUB_LENGTH;     // 160mm
JUNCTION_R        = STUB_R_END + STUB_W / 2;            // 170mm
GUSSET_THICK      = 3;         // thin gusset plate thickness
ARM_CHAMFER       = 2;
STAR_TIP_R        = _STAR_RATIO * HEX_LONGEST_DIA;      // proto: 354mm
HEXAGRAM_INNER_R  = STAR_TIP_R / sqrt(3);
CORRIDOR_GAP      = _CORRIDOR_GAP_CFG;                   // proto: 78mm

// Helix radial position
_V_PUSH           = CORRIDOR_GAP / (2 * tan(30));
HELIX_R           = HEXAGRAM_INNER_R + _V_PUSH;

/* [Stub Linkage Posts — hex cylinders at JU markers] */

/* [Arm Convergence — two-stage: main arm spread + convergence extension (REQ-PB3/ARM1/TZ1)] */
// REQ-REVERT-TZ1: All helical cams at Z=0 — cams do NOT need to match tier Z.
// The dampener at each tier Z redirects the string from cam follower (Z=0)
// to the correct tier Z for the corresponding slider row.
// String path: cam follower (Z=0) → dampener (tier Z) → slider (tier Z).
HELIX_Z_LIST      = [0, 0, 0];  // all cams at Z=0
HELIX_Z           = 0;

// Tier Z mapping for dampeners: H1→Tier1(+30), H2→Tier2(0), H3→Tier3(-30)
DAMPENER_TIER_Z   = [TIER_PITCH, 0, -TIER_PITCH];

// Which helix does each arm serve? ARM_HELIX[arm_idx] = helix_index
// H1=[A3,A4], H2=[A5,A0], H3=[A1,A2]
ARM_HELIX         = [1, 2, 2, 0, 0, 1];  // A0→H2, A1→H3, A2→H3, A3→H1, A4→H1, A5→H2

// === ARM CONVERGENCE (V3 style) ===
// Stubs stay PARALLEL between tiers (same Z gap as rings).
// Frame arms CONVERGE: upper arms slope DOWN, lower arms slope UP.
// CONVERGE_PCT controls how much: 100 = fully meet at midpoint, 0 = stay parallel.
CONVERGE_PCT      = 60;     // [0:5:100] convergence at arm tips (%)
_MID_Z            = (UPPER_RING_CENTER_Z + LOWER_RING_CENTER_Z) / 2;
ARM_TIP_Z_UPPER   = UPPER_RING_CENTER_Z + ((_MID_Z - UPPER_RING_CENTER_Z) * CONVERGE_PCT / 100);
ARM_TIP_Z_LOWER   = LOWER_RING_CENTER_Z + ((_MID_Z - LOWER_RING_CENTER_Z) * CONVERGE_PCT / 100);

/* [Bearing Mount Bracket — sits ON arm convergence nodes] */
MOUNT_WALL        = 4;
MOUNT_OD          = BEARING_OD + 2 * MOUNT_WALL;        // 27mm
MOUNT_BORE_DIA    = BEARING_OD + 0.05;                  // 19.05mm press fit
SHAFT_CLEARANCE   = JOURNAL_DIA + 0.5;                  // 10.5mm
MOUNT_PLATE_T     = BEARING_W + 1.5;                    // 6.5mm
MOUNT_BRACKET_W   = ARM_W + 10;                         // spans arm width + margin
MOUNT_TAB_BOLT    = 4.2;                                // M4 bolt holes
// JOURNAL_EXT now in config_v4.scad (shared with helix_cam_v4.scad)

/* [Dampener Bar — frame geometry at arm @50 markers] */
// Uses DAMPENER_BAR_* params from config_v4.scad

/* [Block Grid] */
BLOCK_DROP        = _BLOCK_DROP;
BLOCK_Z           = GP2_BOT - BLOCK_DROP;

// =============================================
// HEXAGRAM ARM GEOMETRY — precomputed points
// =============================================
_HALF_V = V_ANGLE / 2;
ARM_DEFS = [
    [0,   0 - _HALF_V],
    [0,   0 + _HALF_V],
    [120, 120 - _HALF_V],
    [120, 120 + _HALF_V],
    [240, 240 - _HALF_V],
    [240, 240 + _HALF_V],
];

// HELIX_ARM_PAIRS[hi] = [arm_idx_A, arm_idx_B] — the two arms forming each V-corridor
// H1 at 180° sits between arm 3 (tip 157°) and arm 4 (tip 203°)
// H2 at 300° sits between arm 5 (tip 277°) and arm 0 (tip -37°≡323°)
// H3 at 60°  sits between arm 1 (tip 37°)  and arm 2 (tip 83°)
HELIX_ARM_PAIRS = [[3, 4], [5, 0], [1, 2]];

function _star_tip(angle) = [STAR_TIP_R * cos(angle), STAR_TIP_R * sin(angle)];
function _inner_vert(angle) = [HEXAGRAM_INNER_R * cos(angle), HEXAGRAM_INNER_R * sin(angle)];
function _helix_center(hi) =
    let(a = HELIX_ANGLES[hi])
    [HELIX_R * cos(a), HELIX_R * sin(a)];
function _shaft_angle(hi) = HELIX_ANGLES[hi] + 90;

// Helix XY positions
_h1_xy = _helix_center(0);  // at 180 deg
_h2_xy = _helix_center(1);  // at 300 deg
_h3_xy = _helix_center(2);  // at 60 deg

// Main arm star tip XY — where main arm ends (before convergence extension)
function _star_tip_xy(arm_idx) =
    let(tip_angle = ARM_DEFS[arm_idx][1])
    [STAR_TIP_R * cos(tip_angle), STAR_TIP_R * sin(tip_angle)];

// Junction start XY — where arm begins at stub
function _junction_xy(arm_idx) =
    let(stub_angle = ARM_DEFS[arm_idx][0])
    [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];

// Arm tip XY — same as star tip (V3 style, no convergence extension)
function _arm_tip_xy(arm_idx) = _star_tip_xy(arm_idx);

// Arm tip position with Z — all at HELIX_Z (V3 style, no per-arm convergence)
function _arm_tip_pos(arm_idx) =
    let(tip = _arm_tip_xy(arm_idx))
    [tip[0], tip[1], HELIX_Z];

// Convergence node: midpoint between two arm tips at helix Z
function _convergence_node(hi) =
    let(pair = HELIX_ARM_PAIRS[hi],
        tip_a = _arm_tip_xy(pair[0]),
        tip_b = _arm_tip_xy(pair[1]))
    [(tip_a[0] + tip_b[0]) / 2, (tip_a[1] + tip_b[1]) / 2, HELIX_Z_LIST[hi]];

// Arm-to-bearing XY lookup (for tip bridge echo compatibility)
function _arm_bearing_xy(arm_idx) =
    let(hi = ARM_HELIX[arm_idx],
        is_near = (arm_idx == PB_NEAR_ARMS[hi]),
        pos = is_near ? _mount_pos_near(hi) : _mount_pos_far(hi))
    [pos[0], pos[1]];

// JOURNAL_TOTAL_REACH: distance from helix center to bearing center along shaft axis
// = half helix length + journal stub + journal extension
JOURNAL_TOTAL_REACH = HELIX_LENGTH/2 + JOURNAL_LENGTH + JOURNAL_EXT;  // 91+10+150 = 251mm

// Shaft direction for each helix: perpendicular to radial arm in XY plane
// shaft_dir = (-sin(helix_angle), cos(helix_angle)) — tangent to radial arm
function _shaft_dir(hi) =
    let(a = HELIX_ANGLES[hi])
    [-sin(a), cos(a)];

// Bearing mount positions: ON SHAFT AXIS at ±JOURNAL_TOTAL_REACH from helix center
// REQ-PB7: position = cam_center + shaft_dir * journal_reach
function _mount_pos_near(hi) =
    let(hc = _helix_center(hi), sd = _shaft_dir(hi))
    [hc[0] + sd[0] * (-JOURNAL_TOTAL_REACH),
     hc[1] + sd[1] * (-JOURNAL_TOTAL_REACH),
     HELIX_Z];  // all cams at Z=0

function _mount_pos_far(hi) =
    let(hc = _helix_center(hi), sd = _shaft_dir(hi))
    [hc[0] + sd[0] * JOURNAL_TOTAL_REACH,
     hc[1] + sd[1] * JOURNAL_TOTAL_REACH,
     HELIX_Z];

// 3-helix superposition (for block grid)
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
// COLORS (frame-specific)
// =============================================
C_FRAME    = [0.15, 0.15, 0.18, 0.9];
C_STUB     = [0.7, 0.15, 0.15, 0.9];
C_ARMS = [
    [0.9, 0.2, 0.2, 0.9],
    [0.2, 0.7, 0.2, 0.9],
    [0.2, 0.4, 0.9, 0.9],
    [0.9, 0.9, 0.1, 0.9],
    [0.9, 0.4, 0.9, 0.9],
    [0.1, 0.9, 0.9, 0.9],
];
C_LINKAGE  = [0.5, 0.2, 0.6, 0.85];
C_MOUNT    = [0.85, 0.55, 0.1, 1.0];  // bronze/amber — visible against all arm colors
C_MARKER   = [1.0, 0.0, 1.0, 0.8];  // magenta for coordinate markers

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_MATRIX         = true;
SHOW_UPPER_RING     = true;
SHOW_LOWER_RING     = true;
SHOW_STUBS          = true;
SHOW_STUB_LINKS     = true;
SHOW_ARMS           = true;
SHOW_ARM_LINKS      = true;
SHOW_HELIX_MOUNTS   = true;
SHOW_BEARING_MOUNTS = true;
SHOW_DAMPENERS      = true;
SHOW_BLOCKS         = true;
SHOW_MARKERS        = true;   // coordinate markers for debugging

/* [Debug] */
EXPLODE             = 0;
MATRIX_ROTATE_Z     = 0;
FRAME_RING_ROTATE_Z = 0;
LIGHTWEIGHT_MATRIX  = false;  // false = full tier detail with sliders

// =============================================
// STANDALONE RENDER
// =============================================
hex_frame_v4(anim_t());


// =========================================================
// HEX FRAME V4 ASSEMBLY
// =========================================================
module hex_frame_v4(t = 0) {

    // ---- MATRIX ----
    if (SHOW_MATRIX)
        rotate([0, 0, MATRIX_ROTATE_Z]) {
            if (LIGHTWEIGHT_MATRIX) {
                color([0.5, 0.8, 0.5, 0.3])
                translate([0, 0, TIER3_BOT])
                    linear_extrude(height = TIER1_TOP - TIER3_BOT)
                        circle(r = HEX_R, $fn = 6);
                for (ta = TIER_ANGLES) {
                    color([0.8, 0.2, 0.2, 0.8])
                    rotate([0, 0, ta])
                        cube([HEX_R * 2, 2, 2], center = true);
                }
            } else {
                main_stack_v4(t);
            }
        }

    if (SHOW_UPPER_RING) _hex_ring_ledge_top();   // ledge-on-top ring at UPPER Z
    if (SHOW_LOWER_RING) _hex_ring_ledge_bot();
    if (SHOW_STUBS) _all_stubs();
    if (SHOW_STUB_LINKS) _all_stub_linkages();
    if (SHOW_ARMS) { _all_junction_nodes(); _all_frame_arms(); _all_tip_bridges(); }
    if (SHOW_ARM_LINKS) _all_arm_linkages();
    if (SHOW_HELIX_MOUNTS) _all_helix_mounts();
    if (SHOW_DAMPENERS) _dampener_array();
    if (SHOW_BLOCKS) translate([0, 0, BLOCK_Z]) _block_grid(t);
    if (SHOW_MARKERS) _all_markers();

    // ---- ECHOES ----
    echo(str("=== HEX FRAME V4.3 CLEAN FRAME -- ", FINAL_SCALE ? "FINAL (4ft)" : "PROTOTYPE (desk)", " ==="));
    echo(str("Star tip R=", STAR_TIP_R, "mm (", _STAR_RATIO, "x hex dia ", HEX_LONGEST_DIA, "mm)"));
    echo(str("Total width: ~", round(STAR_TIP_R * 2), "mm (", round(STAR_TIP_R * 2 / 25.4), "\")"));
    _est_height = (UPPER_RING_CENTER_Z + FRAME_RING_H/2) - BLOCK_Z + _BLOCK_HEIGHT_CFG/2;
    echo(str("Est. total height: ~", round(_est_height), "mm (", round(_est_height / 25.4), "\")"));
    echo(str("Block drop: ", BLOCK_DROP, "mm | Block height: ", _BLOCK_HEIGHT_CFG, "mm"));
    echo(str("Hexagram inner R=", round(HEXAGRAM_INNER_R*10)/10, "mm"));
    _hc0 = _helix_center(0);
    _actual_helix_R = sqrt(_hc0[0]*_hc0[0] + _hc0[1]*_hc0[1]);
    echo(str("Helix R=", round(_actual_helix_R*10)/10, "mm (corridor=", CORRIDOR_GAP, "mm)"));
    echo(str("Ledge-top ring (upper) Z=", UPPER_RING_Z, " center=", UPPER_RING_CENTER_Z, " ledge hangs DOWN"));
    echo(str("Ledge-bot ring (lower) Z=", LOWER_RING_Z, " center=", LOWER_RING_CENTER_Z, " ledge pokes UP"));
    _sleeve_gap = UPPER_RING_Z - (LOWER_RING_Z + FRAME_RING_H);
    echo(str("Sleeve gap: ", _sleeve_gap, "mm | Matrix height: ", TIER1_TOP - TIER3_BOT, "mm"));
    echo(str("Helix Z: H1=", HELIX_Z_LIST[0], " H2=", HELIX_Z_LIST[1], " H3=", HELIX_Z_LIST[2], " (all Z=0, REQ-REVERT-TZ1)"));
    echo(str("Dampener tier Z: D1=", DAMPENER_TIER_Z[0], " D2=", DAMPENER_TIER_Z[1], " D3=", DAMPENER_TIER_Z[2], " (string redirect to tier)"));
    echo(str("Convergence: ", CONVERGE_PCT, "% | ARM_TIP_Z_UPPER=", ARM_TIP_Z_UPPER, " ARM_TIP_Z_LOWER=", ARM_TIP_Z_LOWER));
    echo(str("Blocks Z=", BLOCK_Z, " (", BLOCK_DROP, "mm below GP2)"));

    // =========================================================
    // SYSTEM MATH VERIFICATION
    // =========================================================
    echo("");
    echo(str("=== SYSTEM MATH VERIFICATION ==="));

    // --- U-Detour String Geometry ---
    _REST = SLIDER_REST_OFFSET;
    _offset_max = ECCENTRICITY * (1 + SLIDER_BIAS);
    _offset_min = ECCENTRICITY * (SLIDER_BIAS - 1);
    _L_max = 2 * sqrt(_offset_max * _offset_max + FP_ROW_Y * FP_ROW_Y);
    _L_min = 2 * sqrt(_offset_min * _offset_min + FP_ROW_Y * FP_ROW_Y);
    _delta_L = _L_max - _L_min;
    _max_angle = atan2(abs(_offset_max), FP_ROW_Y);

    echo(str("  U-Detour: max=", _offset_max, "mm min=", _offset_min, "mm"));
    echo(str("  String delta_L=", round(_delta_L*10)/10, "mm | max angle=", round(_max_angle*10)/10, "deg",
             (_max_angle > 75 ? " !! STEEP" : " ok")));

    // --- Block Travel ---
    _gain_at_rest = 2 * _REST / sqrt(_REST * _REST + FP_ROW_Y * FP_ROW_Y);
    _eff_per_tier = ECCENTRICITY * _gain_at_rest;
    echo(str("  Block travel: gain=", round(_gain_at_rest*100)/100, " eff/tier=", round(_eff_per_tier*10)/10, "mm"));

    // --- Helix Gap Budget ---
    _eff_helix_R = sqrt(_hc0[0]*_hc0[0] + _hc0[1]*_hc0[1]);
    _gap = _eff_helix_R - HEX_R;
    _budget = RIB_ARM_LENGTH + DAMPENER_BAR_OD + 10;
    echo(str("  Helix gap: ", round(_gap), "mm vs budget ", _budget, "mm",
             (_gap < _budget ? " !! TOO SMALL" : " ok")));

    // --- Friction Cascade ---
    _n_rollers = 9;
    _combined_eff = pow(0.95, _n_rollers) * pow(0.99, 2);
    _sf = _combined_eff / (1 - _combined_eff);
    echo(str("  Friction: ", round(_combined_eff*1000)/10, "% | SF=", round(_sf*10)/10,
             (_sf < 1.5 ? " !! LOW" : " ok")));

    // --- Cam Section Length ---
    echo(str("  Camshaft: ", NUM_CAMS, "x", AXIAL_PITCH, "mm = ", HELIX_LENGTH, "mm"));

    // --- Arm Slenderness ---
    _arm_len = STAR_TIP_R - STUB_R_END;
    _slender = _arm_len / min(ARM_W, ARM_H);
    echo(str("  Arm slenderness: ", round(_slender*10)/10, ":1",
             (_slender > 20 ? " !! add bracing" : " ok")));

    // --- Convergence node positions ---
    for (hi = [0 : 2]) {
        _cn = _convergence_node(hi);
        echo(str("  Conv.node H", hi+1, ": [", round(_cn[0]*10)/10, ", ", round(_cn[1]*10)/10, ", ", round(_cn[2]*10)/10, "]"));
    }

    echo(str("=== END VERIFICATION ==="));
}


// =========================================================
// UPPER HEX RING — ledge on TOP face, positioned ABOVE matrix
// Ledge hangs DOWN into matrix cavity from above
// =========================================================
module _hex_ring_ledge_top() {
    color(C_FRAME) {
        // Ring body — at UPPER Z position
        translate([0, 0, UPPER_RING_Z])
            linear_extrude(height = FRAME_RING_H)
                difference() {
                    circle(r = FRAME_RING_R_OUT, $fn = 6);
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                }
        // Inward ledge on TOP face — extends inward, hangs DOWN
        // Ledge sits at the TOP of the ring body but faces downward into matrix
        translate([0, 0, UPPER_RING_Z + FRAME_RING_H - LEDGE_THICK])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// LOWER HEX RING — ledge on BOTTOM face, positioned BELOW matrix
// Ledge pokes UP into matrix cavity from below
// =========================================================
module _hex_ring_ledge_bot() {
    color(C_FRAME) {
        // Ring body — at LOWER Z position
        translate([0, 0, LOWER_RING_Z])
            linear_extrude(height = FRAME_RING_H)
                difference() {
                    circle(r = FRAME_RING_R_OUT, $fn = 6);
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                }
        // Inward ledge on BOTTOM face — extends inward, pokes UP
        // Ledge sits at the BOTTOM of the ring body and faces upward into matrix
        translate([0, 0, LOWER_RING_Z])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// ALL STUBS — clean radial beams matching arm profile
// =========================================================
// Each stub is a pair of beams (upper + lower) from the ring to the
// junction point, matching the arm width and height. No gusset blocks.
// A thin vertical gusset plate at the stub end ties upper/lower together.
module _all_stubs() {
    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        // Start and end positions
        sx = STUB_R_START * cos(a);
        sy = STUB_R_START * sin(a);
        ex = STUB_R_END * cos(a);
        ey = STUB_R_END * sin(a);

        color(C_STUB) {
            // Upper stub beam
            _beam_between(
                [sx, sy, UPPER_RING_CENTER_Z],
                [ex, ey, UPPER_RING_CENTER_Z],
                STUB_W, STUB_H);
            // Lower stub beam
            _beam_between(
                [sx, sy, LOWER_RING_CENTER_Z],
                [ex, ey, LOWER_RING_CENTER_Z],
                STUB_W, STUB_H);
        }
    }
}


// =========================================================
// STUB LINKAGE POSTS — hexagonal vertical cylinders at JU markers (REQ-STB1)
// =========================================================
// Hex-section posts centered at JU0/JU1/JU2 (junction node positions).
// Each post extends vertically from upper ring center Z downward to lower ring center Z.
// Cross-section: hexagonal ($fn=6), diameter = STUB_W.
module _all_stub_linkages() {
    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        // JU marker position: at JUNCTION_R along stub angle
        px = JUNCTION_R * cos(a);
        py = JUNCTION_R * sin(a);
        _post_h = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z;

        color(C_STUB)
        translate([px, py, LOWER_RING_CENTER_Z - STUB_H/2])
            cylinder(d = STUB_W, h = _post_h + STUB_H, $fn = 6);

        echo(str("  HexPost JU", si, ": [", round(px*10)/10, ",", round(py*10)/10,
                 "] Z=", LOWER_RING_CENTER_Z, " to ", UPPER_RING_CENTER_Z,
                 " dia=", STUB_W, "mm hex"));
    }
}


// =========================================================
// ALL FRAME ARMS — extend fully from junction to star tip
// Upper arms slope DOWN to HELIX_Z, lower arms slope UP to HELIX_Z
// Hex nodes at regular intervals along each arm for honeycomb aesthetic.
// =========================================================
HEX_NODE_DIA  = ARM_W + 6;  // hex node slightly wider than arm
HEX_NODE_H    = ARM_H;
ARM_NODE_FRACS = [0.0, 0.25, 0.50, 0.75, 1.0];  // hex nodes at these fractions

module _all_frame_arms() {
    // V3-style: straight arms from junction to star tip, convergence-controlled Z
    for (ai = [0 : 5]) {
        stub_angle = ARM_DEFS[ai][0];
        tip_angle  = ARM_DEFS[ai][1];
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

// Utility: point along arm (also used by arm linkages and markers)
function _arm_pt(start_xy, end_xy, f, z_from, z_to) =
    [start_xy[0] + (end_xy[0] - start_xy[0]) * f,
     start_xy[1] + (end_xy[1] - start_xy[1]) * f,
     z_from + (z_to - z_from) * f];


// =========================================================
// TIP BRIDGES — REMOVED (REQ-CN-REMOVE)
// =========================================================
// Tip bridge bars (CN) are no longer needed. The camshaft spanning
// between integrated bearing mounts provides structural connection.
// Arms now terminate at their respective bearing positions (REQ-PB8).

module _all_tip_bridges() {
    // REQ-CN-REMOVE: Tip bridges removed.
    // Echo retained for validator compatibility (reports Z=0 for reference).
    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        _brg_a = _arm_bearing_xy(_pair[0]);
        _brg_b = _arm_bearing_xy(_pair[1]);
        _hz = HELIX_Z_LIST[hi];
        echo(str("  TipBridge H", hi+1, " Z=", _hz, ": REMOVED (bearing mounts at [",
                 round(_brg_a[0]*10)/10, ",", round(_brg_a[1]*10)/10,
                 "] and [",
                 round(_brg_b[0]*10)/10, ",", round(_brg_b[1]*10)/10, "])"));
    }
}


// =========================================================
// JUNCTION NODES
// =========================================================
module _all_junction_nodes() {
    _jn_thick = ARM_H;
    for (si = [0 : 2]) {
        stub_a = STUB_ANGLES[si];
        tip_a_angle = ARM_DEFS[si * 2][1];
        tip_b_angle = ARM_DEFS[si * 2 + 1][1];

        stub_xy = [STUB_R_END * cos(stub_a), STUB_R_END * sin(stub_a)];
        arm_a_xy = [JUNCTION_R * cos(stub_a) + ARM_W * cos(tip_a_angle),
                    JUNCTION_R * sin(stub_a) + ARM_W * sin(tip_a_angle)];
        arm_b_xy = [JUNCTION_R * cos(stub_a) + ARM_W * cos(tip_b_angle),
                    JUNCTION_R * sin(stub_a) + ARM_W * sin(tip_b_angle)];

        color(C_STUB)
        for (tier_z = [UPPER_RING_CENTER_Z, LOWER_RING_CENTER_Z])
            hull() {
                translate([stub_xy[0], stub_xy[1], tier_z - _jn_thick/2])
                    cylinder(d = STUB_W, h = _jn_thick, $fn = 6);
                translate([arm_a_xy[0], arm_a_xy[1], tier_z - _jn_thick/2])
                    cylinder(d = ARM_W, h = _jn_thick, $fn = 6);
                translate([arm_b_xy[0], arm_b_xy[1], tier_z - _jn_thick/2])
                    cylinder(d = ARM_W, h = _jn_thick, $fn = 6);
            }
    }
}


// =========================================================
// ARM LINKAGES — minimal cross-brace between V-arm pairs
// =========================================================
// Each stub has two arms diverging outward. We add:
//   1. One thin cross-brace at 35% along the arms (between arm A and B)
//   2. Thin gusset plates to keep each arm pair from spreading
// This is structurally sufficient because:
//   - The arms themselves are thick (20x14mm)
//   - The convergence node at tips provides rigidity
//   - The dampener bar at 50% acts as additional bracing

BRACE_W = 8;   // thin cross-brace width
BRACE_H = 6;   // thin cross-brace height

// _arm_pt function defined above with frame arms

module _all_arm_linkages() {
    _frac = 0.35;  // single brace point at 35% along arms

    for (si = [0 : 2]) {
        stub_angle = STUB_ANGLES[si];
        _ai_a = si * 2;
        _ai_b = si * 2 + 1;
        tip_a_angle = ARM_DEFS[_ai_a][1];
        tip_b_angle = ARM_DEFS[_ai_b][1];

        start_xy = [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];
        end_a = [STAR_TIP_R * cos(tip_a_angle), STAR_TIP_R * sin(tip_a_angle)];
        end_b = [STAR_TIP_R * cos(tip_b_angle), STAR_TIP_R * sin(tip_b_angle)];

        // Per-arm tip Z (REQ-TZ1) — arms from same stub may go to different helix Z
        a_up = _arm_pt(start_xy, end_a, _frac, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
        a_lo = _arm_pt(start_xy, end_a, _frac, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);
        b_up = _arm_pt(start_xy, end_b, _frac, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
        b_lo = _arm_pt(start_xy, end_b, _frac, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);

        color(C_LINKAGE) {
            // Cross-brace between arm A and arm B (upper tier)
            _beam_between(a_up, b_up, BRACE_W, BRACE_H);
            // Cross-brace between arm A and arm B (lower tier)
            _beam_between(a_lo, b_lo, BRACE_W, BRACE_H);
        }
    }
}


// =========================================================
// ALL HELIX MOUNTS — Pillow Block Bearing Mounts at arm @75 (REQ-PB1)
// =========================================================
// Industry-standard UCP-style pillow block bearing housings.
// One pillow block per arm at @75, bolted to the arm beam.
// 6 total (2 per camshaft).
//
// MOUNT ASSIGNMENT (per user specification):
//   H1 (180°): Near journal → A3@75, Far journal → A4@75
//   H2 (300°): Near journal → A0@75, Far journal → A5@75
//   H3 (60°):  Near journal → A2@75, Far journal → A1@75
//
// GEOMETRY:
//   Both arms @75 project to shaft_proj = -6.3mm (center of cam body).
//   Perpendicular distance from arm @75 to shaft axis = 140.5mm.
//   Bearing bore at HELIX_Z (Z=0), aligned along helix_a direction.
//   Extension rods connect each pillow block bore to journal ends.
//   Near journal end: -101mm on shaft axis
//   Far journal end:  +101mm on shaft axis

// Helper: compute arm point at given fraction (XY + interpolated Z)
// Uses per-arm convergence Z (REQ-TZ1)
function _arm_point_3d(arm_idx, frac) =
    let(stub_angle = ARM_DEFS[arm_idx][0],
        tip_angle  = ARM_DEFS[arm_idx][1],
        sx = JUNCTION_R * cos(stub_angle),
        sy = JUNCTION_R * sin(stub_angle),
        ex = STAR_TIP_R * cos(tip_angle),
        ey = STAR_TIP_R * sin(tip_angle),
        _tz_up = ARM_TIP_Z_UPPER,
        _tz_lo = ARM_TIP_Z_LOWER,
        z_up = UPPER_RING_CENTER_Z + (_tz_up - UPPER_RING_CENTER_Z) * frac,
        z_lo = LOWER_RING_CENTER_Z + (_tz_lo - LOWER_RING_CENTER_Z) * frac,
        z_avg = (z_up + z_lo) / 2)
    [sx + (ex - sx) * frac, sy + (ey - sy) * frac, z_avg];

// Midpoint of cross-beam between arm pair at given fraction
function _cross_beam_mid(pair, frac) =
    let(pa = _arm_point_3d(pair[0], frac),
        pb = _arm_point_3d(pair[1], frac))
    [(pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2, (pa[2] + pb[2]) / 2];

// Shaft-local coordinate of a point (projection onto shaft axis)
function _shaft_proj(hx, hy, shaft_dx, shaft_dy, pt) =
    (pt[0] - hx) * shaft_dx + (pt[1] - hy) * shaft_dy;

// 3D point on shaft axis at given signed distance from helix center
function _shaft_point(hx, hy, shaft_dx, shaft_dy, dist) =
    [hx + dist * shaft_dx, hy + dist * shaft_dy, 0];  // Z filled by caller

// Solve: at what arm fraction does the shaft axis project to a given value?
function _frac_for_shaft_proj(pair, hx, hy, sdx, sdy, target) =
    let(mid0 = _cross_beam_mid(pair, 0),
        mid1 = _cross_beam_mid(pair, 1),
        p0 = _shaft_proj(hx, hy, sdx, sdy, mid0),
        p1 = _shaft_proj(hx, hy, sdx, sdy, mid1),
        dp = p1 - p0)
    (abs(dp) < 0.1) ? 0.5 : (target - p0) / dp;

// =============================================
// PILLOW BLOCK PARAMETERS
// =============================================
// UCP-style: rectangular base, cylindrical housing, bolt flanges.
// All dimensions derived from config values — no hardcoded numbers.
// Ordered to avoid forward references (OpenSCAD requires declaration before use).

PB_MOUNT_FRAC     = 0.50;                              // mount at 50% along convergence extension

// Tolerances (consistent with config patterns)
PB_TOL_PRESS      = 0.05;                              // press-fit clearance for bearing
PB_TOL_SLIDING    = 0.3;                               // sliding clearance for shaft/journal
PB_LIP_MARGIN     = BEARING_W * 0.4;                   // retaining lip height beyond bearing

// Housing dimensions — derived from bearing (config: BEARING_OD, BEARING_W, MOUNT_WALL)
PB_BEARING_OD     = BEARING_OD;                         // 6800ZZ OD
PB_BORE           = BEARING_OD + PB_TOL_PRESS;         // press-fit bore for bearing
PB_HOUSING_OD     = PB_BEARING_OD + 2 * MOUNT_WALL;    // housing OD
PB_HOUSING_H      = BEARING_W + PB_LIP_MARGIN;         // housing height = bearing W + lips

// Bolt pattern — derived from config MOUNT_TAB_BOLT
PB_BOLT_DIA       = MOUNT_TAB_BOLT;                    // bolt hole diameter (M4)
PB_BOLT_INSET     = PB_BOLT_DIA + MOUNT_WALL;          // bolt center from base edge

// Base plate — derived from housing + bolt pattern
PB_BASE_W         = PB_HOUSING_OD + 2 * PB_BOLT_INSET; // base width = housing + 2 bolt flanges
PB_BASE_L         = PB_HOUSING_H + MOUNT_WALL;         // base length along shaft = housing + margin
PB_BASE_T         = BEARING_W;                          // base thickness = bearing width

// Web reinforcement
PB_WEB_T          = GUSSET_THICK;                       // web thickness (from frame gusset param)

// Grease groove (visual detail on housing)
PB_GROOVE_DEPTH   = PB_TOL_SLIDING;                     // groove depth into housing wall
PB_GROOVE_WIDTH   = PB_GROOVE_DEPTH * 2;                // groove width (axial)

// Near/far mount arm indices per helix [near_arm, far_arm]
// (User-specified: H1 A3/A4, H2 A0/A5, H3 A2/A1)
PB_NEAR_ARMS      = [3, 0, 2];
PB_FAR_ARMS       = [4, 5, 1];

// =============================================
// BEARING PEDESTAL — bolt-on block (REQ-PB5)
// =============================================
// Printed separately, bolted onto arm beam at @75.
// Assembly: press bearing in → slide journal through → bolt to arm.
// Oriented with bore along local Z (shaft axis direction).
// Base plate sits flat on arm beam surface. Housing rises from center.
//
// ASSEMBLY SEQUENCE:
//   1. Press 6800ZZ bearing into bore (off-frame, interference fit)
//   2. Slide journal through bearing (off-frame)
//   3. Add thrust washer + snap ring on journal
//   4. Place block+bearing+camshaft onto arm at @75
//   5. Bolt tabs down to arm — 4× M4 bolts through tabs into arm
//   6. Add spacer, GT2 pulley, collar on outboard journal end
module _bearing_pedestal() {
    _hd = PB_HOUSING_OD;              // housing cylinder OD
    _hh = PB_HOUSING_H;               // housing height (centered on bore)
    _bd = PB_BORE;                     // bearing bore diameter
    _base_w = PB_BASE_W;              // total width including bolt tabs
    _base_l = PB_BASE_L;              // length along shaft
    _base_t = PB_BASE_T;              // base plate thickness
    _bolt_d = PB_BOLT_DIA;
    _bolt_in = PB_BOLT_INSET;
    _web_t = PB_WEB_T;

    difference() {
        union() {
            // === BASE PLATE — sits flat on arm beam top surface ===
            translate([-_base_l/2, -_base_w/2, -_base_t])
                cube([_base_l, _base_w, _base_t]);

            // Bolt tabs — extend beyond base for M4 through-bolts
            for (sy = [-1, 1])
                translate([0, sy * (_base_w/2 - _bolt_in), -_base_t])
                    cylinder(d = _bolt_in * 2, h = _base_t, $fn = 20);

            // === CYLINDRICAL HOUSING — grows up from base ===
            // Open-top cradle: housing is only bottom 2/3 (bearing drops in from top)
            // Full cylinder for strength, with bearing bore through it
            cylinder(d = _hd, h = _hh/2, $fn = 32);
            mirror([0, 0, 1])
                cylinder(d = _hd, h = _hh/2, $fn = 32);

            // Web gussets: housing to base plate
            for (sy = [-1, 1])
                translate([-_hd/4, sy * _hd/4 - _web_t/2, -_base_t])
                    cube([_hd/2, _web_t, _base_t + _hh/2]);
        }

        // === BEARING BORE — through housing ===
        translate([0, 0, -_hh/2 - 1])
            cylinder(d = _bd, h = _hh + 2, $fn = 32);

        // === BOLT HOLES — 4× M4 through base tabs ===
        for (sx = [-1, 1])
            for (sy = [-1, 1])
                translate([sx * (_base_l/2 - _bolt_in/2),
                           sy * (_base_w/2 - _bolt_in),
                           -_base_t - 1])
                    cylinder(d = _bolt_d, h = _base_t + 2, $fn = 16);

        // === GREASE GROOVE ===
        rotate_extrude($fn = 32)
            translate([_hd/2 - PB_GROOVE_DEPTH, 0, 0])
                square([PB_GROOVE_DEPTH * 2, PB_GROOVE_WIDTH], center = true);
    }
}

// =============================================
// CAMSHAFT ASSEMBLY COMPONENTS — industry standard modules (REQ-CAM1)
// =============================================
// All oriented with bore/axis along local Z. Placed by _all_helix_mounts().

// Frame bearing 6800ZZ — sits inside pillow block bore
module _bearing_6800zz_frame() {
    difference() {
        cylinder(d = BEARING_OD, h = BEARING_W, center = true, $fn = 32);
        cylinder(d = BEARING_ID, h = BEARING_W + 2, center = true, $fn = 32);
    }
}

// Thrust washer — controls axial endplay
module _thrust_washer() {
    difference() {
        cylinder(d = THRUST_WASHER_OD, h = THRUST_WASHER_T, center = true, $fn = 32);
        cylinder(d = THRUST_WASHER_ID, h = THRUST_WASHER_T + 2, center = true, $fn = 32);
    }
}

// Snap ring / E-clip — retains bearing axially
module _snap_ring() {
    difference() {
        cylinder(d = SNAP_RING_OD, h = SNAP_RING_T, center = true, $fn = 32);
        cylinder(d = BEARING_ID + 0.5, h = SNAP_RING_T + 2, center = true, $fn = 32);
        // Gap in ring (C-clip style)
        translate([SNAP_RING_OD/4, 0, 0])
            cube([SNAP_RING_OD/2, 1.5, SNAP_RING_T + 2], center = true);
    }
}

// Spacer — between pillow block and pulley/collar
module _shaft_spacer() {
    difference() {
        cylinder(d = SPACER_OD, h = SPACER_T, center = true, $fn = 24);
        cylinder(d = JOURNAL_DIA + 0.3, h = SPACER_T + 2, center = true, $fn = 24);
    }
}

// GT2-20T pulley — belt drive input
module _gt2_pulley_frame() {
    difference() {
        union() {
            // Toothed body
            cylinder(d = GT2_OD, h = GT2_BOSS_H, center = true, $fn = 40);
            // Flanges top and bottom
            for (_z = [-GT2_BOSS_H/2, GT2_BOSS_H/2 - 1])
                translate([0, 0, _z])
                    cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
        }
        // Bore
        cylinder(d = JOURNAL_DIA + 0.1, h = GT2_BOSS_H + 2, center = true, $fn = 32);
        // Set screw hole (radial)
        rotate([90, 0, 0])
            cylinder(d = 3.0, h = GT2_OD, $fn = 12);
    }
}

// Shaft collar — final axial retention with set screw
module _shaft_collar() {
    difference() {
        cylinder(d = COLLAR_OD, h = COLLAR_T, center = true, $fn = 32);
        // Bore
        cylinder(d = COLLAR_BORE, h = COLLAR_T + 2, center = true, $fn = 32);
        // Set screw hole (radial, M3)
        rotate([90, 0, 0])
            cylinder(d = COLLAR_SET_SCREW, h = COLLAR_OD, $fn = 12);
    }
}


// =============================================
// ALL HELIX MOUNTS — Assembly (REQ-CAM1, BRG1, PB2, GT1)
// =============================================
// Journals are part of the cam assembly (blue, animated) — REQ-JE1/JE2
// Frame mounts: pillow blocks, bearings, thrust washers, snap rings,
// spacers, GT2 pulleys, shaft collars — all STATIC on frame.
// The extension shaft connects the journal end to the pillow block bore.
module _all_helix_mounts() {
    for (hi = [0 : 2]) {
        _hc = _helix_center(hi);
        hx = _hc[0];
        hy = _hc[1];
        helix_a = HELIX_ANGLES[hi];
        _pair = HELIX_ARM_PAIRS[hi];
        _sdx = cos(helix_a);
        _sdy = sin(helix_a);

        // Per-helix Z (REQ-TZ1)
        _hz = HELIX_Z_LIST[hi];

        // Cam assembly — positioned at helix center, at per-helix Z
        translate([hx, hy, _hz])
            rotate([0, 0, helix_a])
                rotate([-90, 0, 0])
                    translate([0, 0, -HELIX_LENGTH/2])
                        helix_assembly_v4(anim_t());

        // --- SHAFT AXIS GEOMETRY (REQ-PB7) ---
        // Shaft direction = perpendicular to radial in XY = (-sin(helix_a), cos(helix_a))
        _shaft_dx = -_sdy;
        _shaft_dy =  _sdx;
        _shaft_a  = atan2(_shaft_dy, _shaft_dx);

        // Bearing position ON SHAFT AXIS at journal endpoint (REQ-PB7)
        // position = cam_center + shaft_dir * journal_total_reach
        _near_pb_pos = _mount_pos_near(hi);  // on shaft axis, Z=0
        _far_pb_pos  = _mount_pos_far(hi);   // on shaft axis, Z=0

        // For bearings, shaft pos = PB pos (both on shaft axis now)
        _near_shaft_pos = _near_pb_pos;
        _far_shaft_pos  = _far_pb_pos;

        // --- FRAME-MOUNTED COMPONENTS (REQ-CAM1, BRG1, PB5, GT1) ---
        // Journals are now part of cam assembly (blue, animated) — REQ-JE1
        // Frame only places: pillow blocks, bearings, thrust washers, snap rings,
        // spacers, GT2 pulley, shaft collars — all STATIC (don't rotate)

        if (SHOW_BEARING_MOUNTS) {
            // Rotation chain to orient components along shaft axis:
            //   rotate([0,0,_shaft_a]) → face along shaft in XY
            //   rotate([0,90,0]) → bore (local Z) aligned with shaft

            for (_side = [0, 1]) {  // 0=near, 1=far
                _pb = (_side == 0) ? _near_pb_pos : _far_pb_pos;
                _shaft = (_side == 0) ? _near_shaft_pos : _far_shaft_pos;
                _dir = (_side == 0) ? -1 : 1;

                // REQ-PB8: Integrated bearing housing on shaft axis
                // Press-fit bore for 6800ZZ, positioned at journal endpoint
                translate(_pb)
                    rotate([0, 0, _shaft_a])
                        rotate([0, 90, 0])
                            color(C_MOUNT)
                            difference() {
                                cylinder(d = MOUNT_OD, h = MOUNT_PLATE_T, center = true, $fn = 32);
                                cylinder(d = MOUNT_BORE_DIA, h = MOUNT_PLATE_T + 2, center = true, $fn = 32);
                            }

                // Bearing 6800ZZ on shaft axis (REQ-BRG1)
                translate(_shaft)
                    rotate([0, 0, _shaft_a])
                        rotate([0, 90, 0])
                            color(C_BEARING) _bearing_6800zz_frame();

                // Thrust washer — inboard face of bearing
                _tw_pos = [_shaft[0] + _shaft_dx * _dir * (-BEARING_W/2 - THRUST_WASHER_T/2),
                           _shaft[1] + _shaft_dy * _dir * (-BEARING_W/2 - THRUST_WASHER_T/2),
                           _hz];
                translate(_tw_pos)
                    rotate([0, 0, _shaft_a])
                        rotate([0, 90, 0])
                            color(C_STEEL) _thrust_washer();

                // Snap ring — outboard face of bearing
                _sr_pos = [_shaft[0] + _shaft_dx * _dir * (BEARING_W/2 + SNAP_RING_T/2),
                           _shaft[1] + _shaft_dy * _dir * (BEARING_W/2 + SNAP_RING_T/2),
                           _hz];
                translate(_sr_pos)
                    rotate([0, 0, _shaft_a])
                        rotate([0, 90, 0])
                            color([0.9, 0.8, 0.1, 1.0]) _snap_ring();

                // Spacer — outboard of snap ring
                _sp_pos = [_shaft[0] + _shaft_dx * _dir * (BEARING_W/2 + SNAP_RING_T + SPACER_T/2),
                           _shaft[1] + _shaft_dy * _dir * (BEARING_W/2 + SNAP_RING_T + SPACER_T/2),
                           _hz];
                translate(_sp_pos)
                    rotate([0, 0, _shaft_a])
                        rotate([0, 90, 0])
                            color(C_STEEL) _shaft_spacer();

                // GT2 pulley — far side only, belt-driven helixes only (REQ-GT2B)
                // H1 (hi=0) = direct motor drive, no GT2. H2/H3 (hi=1,2) = belt driven.
                // Pulley placed OUTBOARD of PB housing to clear arm width.
                _has_gt2 = (_side == 1) && (hi > 0);
                if (_has_gt2) {
                    _gt2_offset = BEARING_W/2 + SNAP_RING_T + SPACER_T + GT2_BOSS_H/2;
                    _gt_pos = [_shaft[0] + _shaft_dx * _dir * _gt2_offset,
                               _shaft[1] + _shaft_dy * _dir * _gt2_offset,
                               _hz];
                    translate(_gt_pos)
                        rotate([0, 0, _shaft_a])
                            rotate([0, 90, 0])
                                color(C_ENDPLT) _gt2_pulley_frame();

                    // GT2 marker echo for validator (REQ-GT2B)
                    echo(str("  MARKER GT2_H", hi+1, ": X=", round(_gt_pos[0]*10)/10,
                             " Y=", round(_gt_pos[1]*10)/10,
                             " Z=", round(_gt_pos[2]*10)/10,
                             " R=", round(sqrt(_gt_pos[0]*_gt_pos[0]+_gt_pos[1]*_gt_pos[1])*10)/10, "mm"));
                }

                // Shaft collar — final retention (outboard of everything)
                _collar_offset = _has_gt2
                    ? BEARING_W/2 + SNAP_RING_T + SPACER_T + GT2_BOSS_H + COLLAR_T/2
                    : BEARING_W/2 + SNAP_RING_T + SPACER_T + COLLAR_T/2;
                _cl_pos = [_shaft[0] + _shaft_dx * _dir * _collar_offset,
                           _shaft[1] + _shaft_dy * _dir * _collar_offset,
                           _hz];
                translate(_cl_pos)
                    rotate([0, 0, _shaft_a])
                        rotate([0, 90, 0])
                            color([0.2, 0.2, 0.2, 1.0]) _shaft_collar();
            }
        }

        _drive_type = (hi == 0) ? "MOTOR-DIRECT" : "BELT-GT2";
        echo(str("  Helix ", hi+1, " Z=", _hz, ": center=[", round(hx*10)/10, ", ", round(hy*10)/10,
                 "] angle=", helix_a, "deg  drive=", _drive_type));
        echo(str("    NearPB: shaft_axis@[", round(_near_pb_pos[0]*10)/10, ",",
                 round(_near_pb_pos[1]*10)/10, ",", round(_near_pb_pos[2]*10)/10,
                 "]  reach=", JOURNAL_TOTAL_REACH, "mm"));
        echo(str("    FarPB:  shaft_axis@[", round(_far_pb_pos[0]*10)/10, ",",
                 round(_far_pb_pos[1]*10)/10, ",", round(_far_pb_pos[2]*10)/10,
                 "]  reach=", JOURNAL_TOTAL_REACH, "mm"));
    }
}


// =========================================================
// DAMPENER — twin parallel bars for string pass-through (REQ-DMP3)
// =========================================================
// Two thin round bars per helix. String from cam follower passes
// between them — bars press lightly on string from above and below,
// providing friction dampening and preventing flutter.
// Anchored at arm @50 with hex post vertical ties.

DAMPENER_FRAC     = 0.50;  // dampener at @50 along arms
DAMP_BAR_DIA      = DAMPENER_BAR_OD;  // from config (10mm) — single source of truth
DAMP_BAR_GAP      = 1.5;   // gap between bars (string passes through)
DAMP_BAR_OFFSET   = (DAMP_BAR_DIA + DAMP_BAR_GAP) / 2;  // ±5.75mm from center in Z

module _dampener_array() {
    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        _hz = DAMPENER_TIER_Z[hi];  // dampener at TIER Z, not cam Z (REQ-REVERT-TZ1)

        // Arm start/end XY for both arms in the pair
        _start_a = [JUNCTION_R * cos(ARM_DEFS[_pair[0]][0]), JUNCTION_R * sin(ARM_DEFS[_pair[0]][0])];
        _end_a   = [STAR_TIP_R * cos(ARM_DEFS[_pair[0]][1]), STAR_TIP_R * sin(ARM_DEFS[_pair[0]][1])];
        _start_b = [JUNCTION_R * cos(ARM_DEFS[_pair[1]][0]), JUNCTION_R * sin(ARM_DEFS[_pair[1]][0])];
        _end_b   = [STAR_TIP_R * cos(ARM_DEFS[_pair[1]][1]), STAR_TIP_R * sin(ARM_DEFS[_pair[1]][1])];

        // Upper/lower arm positions at @50 (per-arm Z)
        _da_up = _arm_pt(_start_a, _end_a, DAMPENER_FRAC, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
        _da_lo = _arm_pt(_start_a, _end_a, DAMPENER_FRAC, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);
        _db_up = _arm_pt(_start_b, _end_b, DAMPENER_FRAC, UPPER_RING_CENTER_Z, ARM_TIP_Z_UPPER);
        _db_lo = _arm_pt(_start_b, _end_b, DAMPENER_FRAC, LOWER_RING_CENTER_Z, ARM_TIP_Z_LOWER);

        // Dampener center positions: XY from arm @50, Z forced to helix Z
        // String runs from cam follower (at helix Z) through dampener to slider (at tier Z = helix Z).
        // Dampener must be at helix Z for straight string path.
        _pt_a_raw = _arm_point_3d(_pair[0], DAMPENER_FRAC);
        _pt_b_raw = _arm_point_3d(_pair[1], DAMPENER_FRAC);
        _pt_a = [_pt_a_raw[0], _pt_a_raw[1], _hz];  // force Z to helix Z
        _pt_b = [_pt_b_raw[0], _pt_b_raw[1], _hz];

        _damp_span = sqrt((_pt_b[0]-_pt_a[0])*(_pt_b[0]-_pt_a[0]) +
                          (_pt_b[1]-_pt_a[1])*(_pt_b[1]-_pt_a[1]) +
                          (_pt_b[2]-_pt_a[2])*(_pt_b[2]-_pt_a[2]));

        // Twin bars: upper bar and lower bar, with gap between for strings
        // Bars are round (cylinders rendered as beams for simplicity)
        color(C_STUB) {
            // Upper dampener bar (+offset in Z from center)
            _beam_between(
                [_pt_a[0], _pt_a[1], _hz + DAMP_BAR_OFFSET],
                [_pt_b[0], _pt_b[1], _hz + DAMP_BAR_OFFSET],
                DAMP_BAR_DIA, DAMP_BAR_DIA);
            // Lower dampener bar (-offset in Z from center)
            _beam_between(
                [_pt_a[0], _pt_a[1], _hz - DAMP_BAR_OFFSET],
                [_pt_b[0], _pt_b[1], _hz - DAMP_BAR_OFFSET],
                DAMP_BAR_DIA, DAMP_BAR_DIA);
        }

        // Hex post vertical ties — connects to upper and lower arm tiers
        _damp_post_h_a = _da_up[2] - _da_lo[2] + STUB_H;
        _damp_post_h_b = _db_up[2] - _db_lo[2] + STUB_H;
        color(C_STUB) {
            translate([_pt_a[0], _pt_a[1], _da_lo[2] - STUB_H/2])
                cylinder(d = STUB_W, h = _damp_post_h_a, $fn = 6);
            translate([_pt_b[0], _pt_b[1], _db_lo[2] - STUB_H/2])
                cylinder(d = STUB_W, h = _damp_post_h_b, $fn = 6);
        }

        echo(str("  Dampener H", hi+1, " Z=", _hz, ": twin bars dia=", DAMP_BAR_DIA,
                 "mm gap=", DAMP_BAR_GAP, "mm span=", round(_damp_span), "mm"));
        echo(str("    anchors: A", _pair[0], "@50[", round(_pt_a[0]*10)/10, ",", round(_pt_a[1]*10)/10,
                 "] → A", _pair[1], "@50[", round(_pt_b[0]*10)/10, ",", round(_pt_b[1]*10)/10, "]"));
    }
}

// Dampener bar with custom length (spans between two arms)
module _dampener_bar_custom(span) {
    difference() {
        union() {
            // Main cylindrical bar
            cylinder(d = DAMPENER_BAR_OD, h = span, $fn = 20);
            // Mounting tabs at each end (for arm attachment)
            for (end_z = [0, span - DAMPENER_TAB_H]) {
                translate([-DAMPENER_TAB_W/2, -DAMPENER_BAR_OD/2 - 2, end_z])
                    cube([DAMPENER_TAB_W, DAMPENER_BAR_OD + 4, DAMPENER_TAB_H]);
            }
        }
        // String pass-through holes — one per channel, lateral
        // Space them evenly along the bar (adapted to actual span)
        _hole_pitch = (span - 20) / max(1, NUM_CHANNELS - 1);
        for (ch = [0 : NUM_CHANNELS - 1]) {
            z_pos = 10 + ch * _hole_pitch;
            if (z_pos > 0 && z_pos < span)
                translate([0, 0, z_pos])
                    rotate([90, 0, 0])
                        cylinder(d = DAMPENER_BAR_BORE, h = DAMPENER_BAR_OD + 10,
                                 center = true, $fn = 12);
        }
        // Mounting bolt holes in tabs
        for (end_z = [DAMPENER_TAB_H/2, span - DAMPENER_TAB_H/2]) {
            translate([0, 0, end_z])
                rotate([90, 0, 0])
                    cylinder(d = DAMPENER_TAB_BOLT, h = DAMPENER_BAR_OD + 10,
                             center = true, $fn = 12);
        }
    }
}


// (Drive system removed per REQ-DS1)


// =========================================================
// COORDINATE MARKERS — parametric anchor point system
// =========================================================
// Every key structural point gets a marker with:
//   - Magenta sphere (visible at any zoom)
//   - 3-axis cross-hair (XYZ indicator)
//   - Text label
//   - ECHO with exact coordinates
//
// All positions derived from the same parameters as the geometry,
// so markers always track the real positions automatically.
// Toggle with SHOW_MARKERS.
//
// Marker Types:
//   ORIGIN  = center of hex matrix
//   Sn      = stub end (n=0,1,2 at 0/120/240 deg)
//   JUn     = junction node (where arms leave stub)
//   Tn      = arm tip / star tip (n=0..5)
//   Hn      = helix center (n=1,2,3 at 180/300/60 deg)
//   CNn     = convergence node (midpoint between arm tip pair)
//   Dn      = dampener bar center
//   MOTOR   = motor position

MARKER_SIZE = 5;  // sphere radius and cross-hair length

module _all_markers() {
    echo(str(""));
    echo(str("=== COORDINATE MARKERS (all positions in mm) ==="));

    // Origin
    _marker([0, 0, 0], "ORIGIN", [1, 1, 1, 0.9]);

    // Stub ends (at Z=0 since stubs are between tiers)
    for (si = [0 : 2]) {
        _a = STUB_ANGLES[si];
        _marker([STUB_R_END * cos(_a), STUB_R_END * sin(_a), 0],
                str("S", si), C_STUB);
    }

    // Junction nodes
    for (si = [0 : 2]) {
        _a = STUB_ANGLES[si];
        _marker([JUNCTION_R * cos(_a), JUNCTION_R * sin(_a), UPPER_RING_CENTER_Z],
                str("JU", si), C_LINKAGE);
    }

    // Star tips (6 arm tips) — at per-arm convergence Z (REQ-TZ1)
    for (ai = [0 : 5]) {
        _tip = _arm_tip_xy(ai);
        _marker([_tip[0], _tip[1], HELIX_Z], str("T", ai), C_ARMS[ai]);
    }

    // Markers along all 6 main arms at 25% intervals (upper tier, per-arm Z)
    for (ai = [0 : 5]) {
        stub_angle = ARM_DEFS[ai][0];
        tip_angle  = ARM_DEFS[ai][1];
        _start = [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];
        _end   = [STAR_TIP_R * cos(tip_angle),  STAR_TIP_R * sin(tip_angle)];
        for (f = [0.25, 0.50, 0.75]) {
            _px = _start[0] + (_end[0] - _start[0]) * f;
            _py = _start[1] + (_end[1] - _start[1]) * f;
            _pz = UPPER_RING_CENTER_Z + (ARM_TIP_Z_UPPER - UPPER_RING_CENTER_Z) * f;
            _marker([_px, _py, _pz], str("A", ai, "@", round(f*100)), C_ARMS[ai]);
        }
    }

    // Helix centers — per-helix Z (REQ-TZ1)
    for (hi = [0 : 2]) {
        _hc = _helix_center(hi);
        _marker([_hc[0], _hc[1], HELIX_Z_LIST[hi]], str("H", hi+1), [1, 0, 0, 0.9]);
    }

    // Convergence nodes
    for (hi = [0 : 2]) {
        _cn = _convergence_node(hi);
        _marker(_cn, str("CN", hi+1), [1, 0.5, 0, 0.9]);
    }

    // Dampener bar centers (at @50 along arms, Z = TIER Z for string redirect)
    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        _da = _arm_point_3d(_pair[0], DAMPENER_FRAC);
        _db = _arm_point_3d(_pair[1], DAMPENER_FRAC);
        _dhz = DAMPENER_TIER_Z[hi];  // tier Z, not cam Z
        _dc = [(_da[0] + _db[0])/2, (_da[1] + _db[1])/2, _dhz];
        _marker(_dc, str("D", hi+1), C_STUB);
    }

    // Bearing pedestal markers — ON SHAFT AXIS at journal endpoints (REQ-PB7)
    for (hi = [0 : 2]) {
        _near_pt = _mount_pos_near(hi);
        _far_pt  = _mount_pos_far(hi);
        _marker(_near_pt, str("PBn", hi+1), C_MOUNT);
        _marker(_far_pt,  str("PBf", hi+1), C_MOUNT);
    }

    echo(str("=== END MARKERS ==="));
}

module _marker(pos, label, col = [1, 0, 1, 0.8]) {
    _s = MARKER_SIZE;
    _cross = _s * 2;  // cross-hair half-length

    color(col) {
        // Central sphere
        translate(pos)
            sphere(r = _s, $fn = 12);

        // XYZ cross-hairs (thin cylinders along each axis)
        // X axis (red tint)
        translate([pos[0] - _cross, pos[1], pos[2]])
            rotate([0, 90, 0])
                cylinder(d = 1, h = _cross * 2, $fn = 6);
        // Y axis (green tint)
        translate([pos[0], pos[1] - _cross, pos[2]])
            rotate([-90, 0, 0])
                cylinder(d = 1, h = _cross * 2, $fn = 6);
        // Z axis (blue tint)
        translate([pos[0], pos[1], pos[2] - _cross])
                cylinder(d = 1, h = _cross * 2, $fn = 6);
    }

    // Text label above marker
    color([1, 1, 1, 0.9])
    translate([pos[0], pos[1], pos[2] + _s + 3])
        linear_extrude(1)
            text(label, size = 6, halign = "center", valign = "center");

    // Echo exact coordinates
    echo(str("  MARKER ", label, ": X=", round(pos[0]*10)/10,
             " Y=", round(pos[1]*10)/10,
             " Z=", round(pos[2]*10)/10,
             " R=", round(sqrt(pos[0]*pos[0] + pos[1]*pos[1])*10)/10, "mm"));
}


// =========================================================
// BLOCK GRID — 3-helix superposition wave (STAGGERED col_x)
// =========================================================
module _block_grid(t = 0) {
    for (i = [0 : NUM_CHANNELS - 1]) {
        d = CH_OFFSETS[i];
        clen = ch_len(d);
        raw = raw_col_count(clen);

        if (clen > 0) {
            for (j = [0 : max(0, raw - 1)]) {
                px = col_x(raw, j, i);
                if (col_inside_hex(px, d)) {
                    bx = px;
                    by = -d;
                    dz = superposition_dz(bx, by, t);

                    translate([bx, by, dz])
                        color(C_BLOCK)
                            cube([COL_PITCH - 2, COL_PITCH - 2, _BLOCK_HEIGHT_CFG], center = true);
                }
            }
        }
    }
}


// =========================================================
// UTILITY: Beam between two 3D points
// =========================================================
module _beam_between(p1, p2, w, h, chamfer = -1) {
    _c = (chamfer < 0) ? ARM_CHAMFER : chamfer;
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];
    dz = p2[2] - p1[2];
    length = sqrt(dx*dx + dy*dy + dz*dz);
    az = atan2(dy, dx);
    horiz = sqrt(dx*dx + dy*dy);
    ay = -atan2(dz, horiz);

    if (length > 0.1)  // guard against zero-length beams
    translate(p1)
        rotate([0, 0, az])
            rotate([0, ay, 0]) {
                if (_c > 0 && w > 2*_c && h > 2*_c)
                    hull()
                        for (yc = [-w/2 + _c, w/2 - _c])
                            for (zc = [-h/2 + _c, h/2 - _c])
                                translate([0, yc, zc])
                                    rotate([0, 90, 0])
                                        cylinder(r = _c, h = length, $fn = 8);
                else
                    translate([0, -w/2, -h/2])
                        cube([length, w, h]);
            }
}


// (Belt segment utility removed per REQ-DS1)
