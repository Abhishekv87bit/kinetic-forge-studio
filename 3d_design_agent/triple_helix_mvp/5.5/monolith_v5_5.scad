// =========================================================
// MONOLITH V5.5 — One-Piece Frame Print (NO matrix)
// =========================================================
// Frame-only monolith. Matrix stack is a SEPARATE print that
// slides into the frame from above through the open upper ring.
//
// INCLUDED COMPONENTS (all one mesh):
//   - Upper hex ring (NO ledge — open bore for insertion)
//   - Lower hex ring (ledge faces UP — catches everything)
//   - Lower ring extended sleeve for guide plates
//   - 3 stubs at [0, 120, 240]
//   - 6 hexagram arms (parallel corridor pairs)
//   - Junction nodes (stub-to-arm transitions)
//   - Stub linkage columns (vertical ties between upper/lower)
//   - Arm linkage braces (cross-brace between arm pairs)
//   - Carrier plate nodes (with MR84ZZ bearing bores)
//   - Dampener bars (with V-groove string holes)
//   - Dampener carrier nodes
//   - Idler posts + brackets
//   - Motor bracket
//   - 3 frame posts at STUB vertices [0,120,240] only
//
// EXCLUDED:
//   - Matrix stack (separate: matrix_stack_v5_5.scad)
//   - Anchor plate (drops in from above, CA glue)
//   - Guide plates (drop in from above, rest on lower ledge)
//   - Legs (on hold)
//   - Blocks (separate hanging elements)
//   - Helix cam assemblies (separate module)
//   - GT2 pulleys (on shaft)
//   - Drive belt (not printed)
//
// Assembly order (top-down):
//   1. Guide plates drop through upper ring, land on lower ledge
//   2. Route strings through guide plate tapered holes
//   3. Thread strings through matrix tiers
//   4. Matrix slides through upper ring, seats on guide plates
//   5. Anchor plate placed on top in upper ring sleeve, CA glue
//
// Build plate constraint: ARM_END_R * 2 <= 349mm (K2)
//
// V5.5c PRINT NOTE (R4): Dampener bars span ~40-60mm between arm
// pairs at Z=0. These horizontal bridges may need print support
// underneath. Use tree supports or paint-on supports in slicer.
// Carrier bearing bores (horizontal, 8mm) should be reamed after
// printing for circularity (R3).
// =========================================================

include <config_v5_5.scad>
use <helix_cam_v5_5.scad>
use <matrix_stack_v5_5.scad>

$fn = 24;

// =============================================
// FRAME PARAMETERS
// =============================================

/* [Frame Rings] */
FRAME_RING_H      = 6;
FRAME_RING_W      = 5;
FRAME_RING_R_IN   = HEX_R + 2;                              // 45mm
FRAME_RING_R_OUT  = FRAME_RING_R_IN + FRAME_RING_W;         // 50mm

UPPER_RING_Z      = TIER1_TOP;                               // +19.5
LOWER_RING_Z      = TIER3_BOT - FRAME_RING_H;               // -25.5
UPPER_RING_CENTER_Z = UPPER_RING_Z + FRAME_RING_H / 2;      // +22.5
LOWER_RING_CENTER_Z = LOWER_RING_Z + FRAME_RING_H / 2;      // -22.5
TIER_GAP_Z        = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z;

/* [Inward Ledge] */
LEDGE_WIDTH       = 3;
LEDGE_THICK       = 2;
LEDGE_R_IN        = FRAME_RING_R_IN - LEDGE_WIDTH;          // 42mm

/* [Hexagram Star] */
ARM_W             = 10;
ARM_H             = 7;

/* [Stubs] */
STUB_ANGLES       = [0, 120, 240];
STUB_LENGTH       = 15;
STUB_INWARD       = 4;
STUB_W            = 10;
STUB_H            = ARM_H;
STUB_R_START      = FRAME_RING_R_OUT - STUB_INWARD;
STUB_R_END        = FRAME_RING_R_OUT + STUB_LENGTH;
JUNCTION_R        = STUB_R_END + STUB_W / 2;
GUSSET_THICK      = 2;
ARM_CHAMFER       = 1;
STAR_TIP_R        = _STAR_RATIO * HEX_LONGEST_DIA;
HEXAGRAM_INNER_R  = STAR_TIP_R / sqrt(3);
CORRIDOR_GAP      = _CORRIDOR_GAP_CFG;

/* [V_ANGLE] */
function _par_residual(V, T, J) =
    T*T*sin(120-V) - 2*J*T*sin(120-V/2) + J*J*sin(120);
function _find_parallel_V(T, J, lo=10, hi=150, depth=0) =
    depth > 50 ? (lo+hi)/2 :
    let(mid = (lo+hi)/2, r = _par_residual(mid, T, J))
    abs(r) < 0.0001 ? mid :
    r > 0 ? _find_parallel_V(T, J, mid, hi, depth+1) :
             _find_parallel_V(T, J, lo, mid, depth+1);
V_ANGLE           = _find_parallel_V(STAR_TIP_R, JUNCTION_R);

_V_PUSH           = CORRIDOR_GAP / (2 * tan(30));
HELIX_R           = HEXAGRAM_INNER_R + _V_PUSH;

/* [Arm Convergence] */
CONVERGE_PCT      = 30;
_MID_Z            = (UPPER_RING_CENTER_Z + LOWER_RING_CENTER_Z) / 2;
ARM_TIP_Z_UPPER   = UPPER_RING_CENTER_Z + ((_MID_Z - UPPER_RING_CENTER_Z) * CONVERGE_PCT / 100);
ARM_TIP_Z_LOWER   = LOWER_RING_CENTER_Z + ((_MID_Z - LOWER_RING_CENTER_Z) * CONVERGE_PCT / 100);

// =============================================
// HELIX & ARM GEOMETRY FUNCTIONS
// =============================================
HELIX_Z           = 0;
DAMPENER_TIER_Z   = [TIER_PITCH, 0, -TIER_PITCH];

_HALF_V = V_ANGLE / 2;
ARM_DEFS = [
    [0,   0 - _HALF_V],
    [0,   0 + _HALF_V],
    [120, 120 - _HALF_V],
    [120, 120 + _HALF_V],
    [240, 240 - _HALF_V],
    [240, 240 + _HALF_V],
];

HELIX_ARM_PAIRS = [[3, 4], [5, 0], [1, 2]];
ARM_HELIX       = [1, 2, 2, 0, 0, 1];

function _shaft_dir(hi) =
    let(a = HELIX_ANGLES[hi]) [-sin(a), cos(a)];
function _helix_center(hi) =
    let(a = HELIX_ANGLES[hi]) [HELIX_R * cos(a), HELIX_R * sin(a)];
function _shaft_angle(hi) = HELIX_ANGLES[hi] + 90;

function _junction_xy(arm_idx) =
    let(stub_angle = ARM_DEFS[arm_idx][0])
    [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];
function _star_tip_xy(arm_idx) =
    let(tip_angle = ARM_DEFS[arm_idx][1])
    [STAR_TIP_R * cos(tip_angle), STAR_TIP_R * sin(tip_angle)];
function _arm_dir(arm_idx) =
    let(jxy = _junction_xy(arm_idx),
        txy = _star_tip_xy(arm_idx),
        dx = txy[0] - jxy[0], dy = txy[1] - jxy[1],
        len = sqrt(dx*dx + dy*dy))
    [dx/len, dy/len];
function _arm_full_len(arm_idx) =
    let(jxy = _junction_xy(arm_idx),
        txy = _star_tip_xy(arm_idx),
        dx = txy[0] - jxy[0], dy = txy[1] - jxy[1])
    sqrt(dx*dx + dy*dy);

function _shaft_crossing_frac(arm_idx, hi) =
    let(hc = _helix_center(hi), sd = _shaft_dir(hi),
        jxy = _junction_xy(arm_idx), ad = _arm_dir(arm_idx),
        cross = ad[0] * sd[1] - ad[1] * sd[0],
        djx = hc[0] - jxy[0], djy = hc[1] - jxy[1],
        t_mm = (djx * sd[1] - djy * sd[0]) / cross,
        flen = _arm_full_len(arm_idx))
    abs(cross) < 0.001 ? 0.5 : t_mm / flen;
function _shaft_crossing_xy(arm_idx, hi) =
    let(jxy = _junction_xy(arm_idx), ad = _arm_dir(arm_idx),
        f = _shaft_crossing_frac(arm_idx, hi),
        len = _arm_full_len(arm_idx))
    [jxy[0] + ad[0] * f * len, jxy[1] + ad[1] * f * len];
function _shaft_crossing_R(arm_idx, hi) =
    let(xy = _shaft_crossing_xy(arm_idx, hi))
    sqrt(xy[0]*xy[0] + xy[1]*xy[1]);

function _beam_z_at_frac(frac, is_upper) =
    is_upper ?
        UPPER_RING_CENTER_Z + ((ARM_TIP_Z_UPPER - UPPER_RING_CENTER_Z) * frac) :
        LOWER_RING_CENTER_Z + ((ARM_TIP_Z_LOWER - LOWER_RING_CENTER_Z) * frac);

// =============================================
// CARRIER NODE DIMENSIONS
// =============================================
CARRIER_PLATE_T   = CARRIER_PLATE_T_CFG;
CARRIER_BRG_BORE  = FRAME_BRG_OD + 0.15;   // V5.5c R3: was +0.05 — ream-friendly for FDM horizontal bores
CARRIER_WALL      = 2;
CARRIER_NODE_BULGE = 2;
CARRIER_OVERSHOOT  = 6.5;

_CARRIER_CLEARANCE = CARRIER_PLATE_T / 2 + CARRIER_OVERSHOOT;
_REF_CROSSING_FRAC = _shaft_crossing_frac(3, 0);
_REF_CROSSING_R = _shaft_crossing_R(3, 0);
ARM_END_R = _REF_CROSSING_R + _CARRIER_CLEARANCE;

function _arm_end_frac(arm_idx) =
    let(jxy = _junction_xy(arm_idx), ad = _arm_dir(arm_idx),
        full_len = _arm_full_len(arm_idx),
        hi = ARM_HELIX[arm_idx],
        cross_frac = _shaft_crossing_frac(arm_idx, hi),
        cross_len = cross_frac * full_len,
        end_len = cross_len + _CARRIER_CLEARANCE)
    min(1.0, end_len / full_len);

function _arm_pt(start_xy, end_xy, f, z_from, z_to) =
    [start_xy[0] + (end_xy[0] - start_xy[0]) * f,
     start_xy[1] + (end_xy[1] - start_xy[1]) * f,
     z_from + (z_to - z_from) * f];

// =============================================
// DRIVE CHAIN GEOMETRY
// =============================================
_GT2_OFFSET_FROM_HELIX = HELIX_LENGTH/2 + SHAFT_EXT_TO_CARRIER
                         + CARRIER_PLATE_T/2 + GT2_BOSS_H/2;
function _gt2_world_xy(hi, sign=1) =
    let(hc = _helix_center(hi), sd = _shaft_dir(hi))
    [hc[0] + sd[0] * sign * _GT2_OFFSET_FROM_HELIX,
     hc[1] + sd[1] * sign * _GT2_OFFSET_FROM_HELIX];

_IDLER_OFFSET_R = STUB_W/2 + IDLER_OD/2 + 2;
function _idler_world_xy(si) =
    let(a = STUB_ANGLES[si])
    [(JUNCTION_R + _IDLER_OFFSET_R) * cos(a),
     (JUNCTION_R + _IDLER_OFFSET_R) * sin(a)];

// =============================================
// MATRIX TIER PARAMETERS (local copies — `use` doesn't import variables)
// =============================================
PIP_CLEARANCE  = 0.3;
PIP_Z_GAP      = 0.35;     // V5.5c R1: was 0.2 — more FDM clearance for print-in-place
PIP_PULLEY_GAP = 0.4;
RAIL_HEIGHT    = 2.0;
RAIL_DEPTH     = 0.3;
RAIL_TOLERANCE = 0.4;
END_STOP_W     = 2.5;
FP_WIDTH       = CH_GAP - 0.6;
FP_AXLE_DIA    = 1.5;
SP_PIN_DIA     = 1.5;
S_GAP          = 1.5;
SP_WIDTH       = S_GAP;
SP_AXLE_DIA    = SP_PIN_DIA;
SLIDER_PLATE_Y = SP_OD + 1;
WALL_MARGIN_AXLE = 2;
SLIDER_MARGIN_HELIX = SP_OD/2 + END_STOP_W + 0.5;
SLIDER_MARGIN_ARM   = SP_OD/2 + 0.5;
SLIDER_PULLEY_BIAS_X = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2;
// V5.5c: Corrected axle lengths — must match matrix_stack_v5_5.scad
FP_AXLE_LEN = CH_GAP - 0.4;                     // 6.1mm (within gap, no wall bleed)
_plate_t = (CH_GAP/2) - (S_GAP/2) - PIP_Z_GAP;  // 2.15mm (was 2.30 with PIP_Z_GAP=0.2)
_slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;         // 1.15mm (was 1.00)
SP_AXLE_LEN = S_GAP - 0.2;                       // 1.30mm (between plates, no bleed)

// Derived arrays for matrix
function _culled_span(ch_idx) =
    let(d = CH_OFFSETS[ch_idx], len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) == 0 ? 0 :
    let(maxp = max([for (c=cols) abs(c)]))
    2 * (maxp + FP_OD/2 + WALL_MARGIN_AXLE);

CH_WALL_LENS = [for (i = [0:NUM_CHANNELS-1])
    max(CH_LENS[i], _culled_span(i))
];

_BUG2_STRIP_OFFSET = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2;

function _culled_col_bounds(ch_idx) =
    let(d = CH_OFFSETS[ch_idx], len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) == 0 ? [0, 0] : [min(cols), max(cols)];

CH_S_LEFT = [for (i = [0:NUM_CHANNELS-1])
    (COL_COUNTS[i] > 0) ?
        _culled_col_bounds(i)[0] + _BUG2_STRIP_OFFSET - SP_OD/2 - SLIDER_MARGIN_ARM : 0
];
CH_S_RIGHT = [for (i = [0:NUM_CHANNELS-1])
    (COL_COUNTS[i] > 0) ?
        _culled_col_bounds(i)[1] + _BUG2_STRIP_OFFSET + SP_OD/2 + SLIDER_MARGIN_ARM : 0
];
CH_S_LENS = [for (i = [0:NUM_CHANNELS-1])
    CH_S_RIGHT[i] - CH_S_LEFT[i]
];

// =============================================
// BUILD PLATE / BRACKET CONSTANTS
// =============================================
_BUILD_PLATE_DIA  = 349;    // K2 build plate diameter
_BUILD_PLATE_Z    = -200;   // visual Z offset for build plate ghost
_BRACKET_ARM_W    = 4;      // idler bracket arm width & depth
_BRACKET_EXTRA_H  = 3;      // extra height beyond idler stack
_MOTOR_BRACKET_T  = 3;      // motor bracket thickness
_MOTOR_BRACKET_CLR = 6;     // motor bracket clearance (each side)

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_FRAME          = true;
SHOW_MATRIX         = true;
SHOW_HELIX_MOUNTS   = true;
SHOW_DRIVE          = true;
SHOW_BUILD_PLATE    = true;
SHOW_BLOCKS         = true;

// =============================================
// COLORS
// =============================================
C_FRAME    = [0.15, 0.15, 0.18, 0.9];
C_STUB     = [0.7, 0.15, 0.15, 0.9];
C_ARMS_COL = [
    [0.9, 0.2, 0.2, 0.9], [0.2, 0.7, 0.2, 0.9],
    [0.2, 0.4, 0.9, 0.9], [0.9, 0.9, 0.1, 0.9],
    [0.9, 0.4, 0.9, 0.9], [0.1, 0.9, 0.9, 0.9],
];
C_LINKAGE  = [0.5, 0.2, 0.6, 0.85];
C_CARRIER  = [0.85, 0.6, 0.2, 1.0];
C_LEG      = [0.6, 0.62, 0.65, 0.92];

// =============================================
// STANDALONE RENDER
// =============================================
monolith_v5_5(anim_t());


// =========================================================
// MONOLITH V5.5 ASSEMBLY — FRAME ONLY
// =========================================================
module monolith_v5_5(t = 0) {

    // === FRAME (single monolithic mesh) ===
    if (SHOW_FRAME) {
        // Hex rings (upper: no ledge, lower: ledge UP + extended sleeve)
        _hex_ring_ledge_top();
        _hex_ring_ledge_bot();

        // Three unified corridors — each is ONE solid piece:
        // fork + arms + linkage + carrier bridges + dampener ties
        for (si = [0 : 2])
            _render_corridor(si);

        // Frame posts at stub vertices only [0,120,240]
        _all_frame_posts();

        // Idler brackets + posts (structural, part of frame)
        _all_idler_brackets();

        // Motor bracket
        _motor_bracket();
    }

    // === MATRIX STACK (separate print — shown as visual reference) ===
    if (SHOW_MATRIX) {
        matrix_stack_v5_5(t);
    }

    // === HELIX CAM ASSEMBLIES (separate — not part of monolith mesh) ===
    if (SHOW_HELIX_MOUNTS) {
        for (hi = [0 : 2]) {
            _hc = _helix_center(hi);
            helix_a = HELIX_ANGLES[hi];
            translate([_hc[0], _hc[1], HELIX_Z])
                rotate([0, 0, helix_a])
                    rotate([-90, 0, 0])
                        translate([0, 0, -HELIX_LENGTH/2])
                            helix_assembly_v5(t);
        }
    }

    // === DRIVE VISUALS (GT2, idlers, motor — NOT printed) ===
    if (SHOW_DRIVE) _drive_chain_visuals();

    // === BLOCK GRID ===
    if (SHOW_BLOCKS)
        translate([0, 0, GUIDE_BOT - _BLOCK_DROP])
            _block_grid(t);

    // === BUILD PLATE OUTLINE ===
    if (SHOW_BUILD_PLATE)
        color([0.4, 0.4, 0.4, 0.15])
            translate([0, 0, _BUILD_PLATE_Z])
                cylinder(r = _BUILD_PLATE_DIA / 2, h = 0.5, $fn = 64);

    // === ECHOES ===
    echo(str("=== MONOLITH V5.5 — FRAME ONLY (matrix separate) ==="));
    echo(str("V_ANGLE=", round(V_ANGLE*100)/100));
    echo(str("Star tip R=", round(STAR_TIP_R*10)/10, "mm"));
    echo(str("ARM_END_R=", round(ARM_END_R*10)/10, "mm → dia=", round(ARM_END_R*2*10)/10, "mm"));
    echo(str("HELIX_R=", round(HELIX_R*10)/10, "mm"));
    echo(str("Lower ring extended: ", _LOWER_RING_EXT_H, "mm (sleeve for guide plates)"));

    if (ARM_END_R * 2 > _BUILD_PLATE_DIA + 0.5)
        echo(str("WARNING! ARM_END_R diameter exceeds ", _BUILD_PLATE_DIA, "mm plate!"));

    // V5.5c R7: Follower-to-carrier clearance check
    // Max follower reach from shaft = CAM_ECC + FOLLOWER_RING_OD/2 + FOLLOWER_ARM_LENGTH
    // Carrier node inner edge from shaft = node starts at _NODE_BLEND_LEN before crossing
    _follower_reach = CAM_ECC + FOLLOWER_RING_OD/2 + FOLLOWER_ARM_LENGTH;
    echo(str("Follower max reach from shaft: ", round(_follower_reach*10)/10, "mm"));
    echo(str("Carrier node blend: ", _NODE_BLEND_LEN, "mm from crossing"));
    echo(str("V5.5c: PIP_Z_GAP=", PIP_Z_GAP, "mm | plate_t=", round(_plate_t*100)/100,
             "mm | slot_d=", round(_slot_d*100)/100, "mm"));
    echo(str("V5.5c: CARRIER_BRG_BORE=", CARRIER_BRG_BORE, "mm (ream-friendly)"));
    echo(str("V5.5c: D_FLAT_DEPTH=", D_FLAT_DEPTH, "mm"));
}


// =========================================================
// HEX RINGS
// =========================================================
module _hex_ring_ledge_top() {
    // V5.6 U7: Beveled outer edges on upper ring
    color(C_FRAME) {
        translate([0, 0, UPPER_RING_Z])
            hull() {
                // Bottom face — inset outer edge by bevel
                translate([0, 0, 0])
                    linear_extrude(height = 0.01)
                        difference() {
                            circle(r = FRAME_RING_R_OUT - RING_BEVEL, $fn = 6);
                            circle(r = FRAME_RING_R_IN, $fn = 6);
                        }
                // Main body — full outer edge
                translate([0, 0, RING_BEVEL])
                    linear_extrude(height = FRAME_RING_H - 2 * RING_BEVEL)
                        difference() {
                            circle(r = FRAME_RING_R_OUT, $fn = 6);
                            circle(r = FRAME_RING_R_IN, $fn = 6);
                        }
                // Top face — inset outer edge by bevel
                translate([0, 0, FRAME_RING_H - 0.01])
                    linear_extrude(height = 0.01)
                        difference() {
                            circle(r = FRAME_RING_R_OUT - RING_BEVEL, $fn = 6);
                            circle(r = FRAME_RING_R_IN, $fn = 6);
                        }
            }
    }
}

// V5.5: Lower ring extended downward to sleeve guide plates.
// Ledge faces UP at top of lower ring (catches guide plates + matrix).
// Ring extends down by GUIDE_STACK_H below the ledge.
_LOWER_RING_EXT_H = FRAME_RING_H + GUIDE_STACK_H;  // 6 + 5 = 11mm

module _hex_ring_ledge_bot() {
    // V5.6 U7: Beveled outer edges on lower ring (extended sleeve)
    color(C_FRAME) {
        // Extended ring wall — beveled top and bottom outer edges
        _ext_z = LOWER_RING_Z - GUIDE_STACK_H;
        translate([0, 0, _ext_z])
            hull() {
                // Bottom face — inset outer edge by bevel
                translate([0, 0, 0])
                    linear_extrude(height = 0.01)
                        difference() {
                            circle(r = FRAME_RING_R_OUT - RING_BEVEL, $fn = 6);
                            circle(r = FRAME_RING_R_IN, $fn = 6);
                        }
                // Main body — full outer edge
                translate([0, 0, RING_BEVEL])
                    linear_extrude(height = _LOWER_RING_EXT_H - 2 * RING_BEVEL)
                        difference() {
                            circle(r = FRAME_RING_R_OUT, $fn = 6);
                            circle(r = FRAME_RING_R_IN, $fn = 6);
                        }
                // Top face — inset outer edge by bevel
                translate([0, 0, _LOWER_RING_EXT_H - 0.01])
                    linear_extrude(height = 0.01)
                        difference() {
                            circle(r = FRAME_RING_R_OUT - RING_BEVEL, $fn = 6);
                            circle(r = FRAME_RING_R_IN, $fn = 6);
                        }
            }
        // Ledge faces UP — at top of original lower ring position
        // Guide plates rest on this ledge
        translate([0, 0, LOWER_RING_Z])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// UNIFIED CORRIDOR — One solid piece per stub vertex
// =========================================================
// Each corridor = one stub vertex with its two arms. Everything
// rendered as ONE union/difference: fork node, both arm U-loops,
// linkage brace, carrier bridges, dampener ties + bar.
// All CNC-from-one-billet — no seams, no color breaks.
//
// The difference() cuts bearing bores through the combined solid.
C_CORRIDOR = [
    [0.9, 0.2, 0.2, 0.9],   // Corridor 0 (stub at 0°)
    [0.2, 0.7, 0.2, 0.9],   // Corridor 1 (stub at 120°)
    [0.2, 0.4, 0.9, 0.9],   // Corridor 2 (stub at 240°)
];

module _render_corridor(si) {
    _ai_a = si * 2;
    _ai_b = si * 2 + 1;

    // Bearing bore data for both arms
    _hi_a = ARM_HELIX[_ai_a];
    _hi_b = ARM_HELIX[_ai_b];
    _sa_a = _shaft_angle(_hi_a);
    _sa_b = _shaft_angle(_hi_b);
    _cross_xy_a = _shaft_crossing_xy(_ai_a, _hi_a);
    _cross_xy_b = _shaft_crossing_xy(_ai_b, _hi_b);

    color(C_CORRIDOR[si])
    difference() {
        union() {
            // --- Fork node (stem + branches + spine + gusset) ---
            _fork_node_geom(si);

            // --- Arm A U-loop ---
            _arm_u_loop_geom(_ai_a);

            // --- Arm B U-loop ---
            _arm_u_loop_geom(_ai_b);

            // --- Linkage brace between arm A and arm B ---
            _linkage_geom(si);

            // --- Carrier bridge on arm A ---
            _carrier_bridge_geom(_ai_a);

            // --- Carrier bridge on arm B ---
            _carrier_bridge_geom(_ai_b);

            // --- Dampener ties + bar ---
            _dampener_geom_for_corridor(si);
        }

        // --- Bearing bores (subtractive) ---
        // Arm A bearing bore
        translate([_cross_xy_a[0], _cross_xy_a[1], HELIX_Z])
            rotate([0, 0, _sa_a]) rotate([0, 90, 0])
                cylinder(d = CARRIER_BRG_BORE, h = BRIDGE_W + 4,
                         center = true, $fn = 32);
        // Arm A shaft clearance
        translate([_cross_xy_a[0], _cross_xy_a[1], HELIX_Z])
            rotate([0, 0, _sa_a]) rotate([0, 90, 0])
                cylinder(d = SHAFT_DIA + 1, h = 200,
                         center = true, $fn = 24);
        // Arm B bearing bore
        translate([_cross_xy_b[0], _cross_xy_b[1], HELIX_Z])
            rotate([0, 0, _sa_b]) rotate([0, 90, 0])
                cylinder(d = CARRIER_BRG_BORE, h = BRIDGE_W + 4,
                         center = true, $fn = 32);
        // Arm B shaft clearance
        translate([_cross_xy_b[0], _cross_xy_b[1], HELIX_Z])
            rotate([0, 0, _sa_b]) rotate([0, 90, 0])
                cylinder(d = SHAFT_DIA + 1, h = 200,
                         center = true, $fn = 24);
    }

    // Visual bearings (outside the difference — not cut)
    for (_ai = [_ai_a, _ai_b]) {
        _hi = ARM_HELIX[_ai];
        _sa = _shaft_angle(_hi);
        _cxy = _shaft_crossing_xy(_ai, _hi);
        color(C_BEARING)
        translate([_cxy[0], _cxy[1], HELIX_Z])
            rotate([0, 0, _sa]) rotate([0, 90, 0])
                difference() {
                    cylinder(d=FRAME_BRG_OD, h=FRAME_BRG_W, center=true, $fn=32);
                    cylinder(d=FRAME_BRG_ID, h=FRAME_BRG_W+2, center=true, $fn=32);
                }
    }
}


// =========================================================
// FORK NODE GEOMETRY (no color — called from _render_corridor)
// =========================================================
// Each hex ring vertex sends material outward that forks into
// two arm directions. One continuous forking shape — no seams.
//
// Architecture: TWO hulls per tier, each spanning the FULL path
// from ring face through fork center to one arm departure.
// Both hulls share the ring-face and fork-center profiles, so
// they merge into one seamless Y-shape with no internal edges.
//
// Per tier:
//   Hull A: ring face + fork center + arm A departure (3 profiles)
//   Hull B: ring face + fork center + arm B departure (3 profiles)
//
// The convex hull of {ring, fork, arm_departure} naturally creates
// a smooth transition from stem to branch — no separate pieces.
//
// Vertical spine includes branch departure profiles at both tiers
// so it's a wide Y-column, not a thin post.
_FORK_DEPART = 15;   // mm into each arm direction for branch blend

// Fork node geometry for one stub vertex (no color)
module _fork_node_geom(si) {
    a = STUB_ANGLES[si];
    _ai_a = si * 2;
    _ai_b = si * 2 + 1;
    _ad_a = _arm_dir(_ai_a);
    _ad_b = _arm_dir(_ai_b);

    _ring_x = FRAME_RING_R_OUT * cos(a);
    _ring_y = FRAME_RING_R_OUT * sin(a);
    _jx = JUNCTION_R * cos(a);
    _jy = JUNCTION_R * sin(a);

    _dep_ax = _jx + _ad_a[0] * _FORK_DEPART;
    _dep_ay = _jy + _ad_a[1] * _FORK_DEPART;
    _dep_bx = _jx + _ad_b[0] * _FORK_DEPART;
    _dep_by = _jy + _ad_b[1] * _FORK_DEPART;

    for (tier_z = [UPPER_RING_CENTER_Z, LOWER_RING_CENTER_Z]) {
        // Stem: ring face → fork center (widens into both arm directions)
        hull() {
            translate([_ring_x, _ring_y, tier_z])
                _stub_end_profile(a);
            translate([_jx, _jy, tier_z])
                _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_a);
            translate([_jx, _jy, tier_z])
                _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_b);
        }
        // Branch A: fork center → arm A departure
        hull() {
            translate([_jx, _jy, tier_z])
                _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_a);
            translate([_dep_ax, _dep_ay, tier_z])
                _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_a);
        }
        // Branch B: fork center → arm B departure
        hull() {
            translate([_jx, _jy, tier_z])
                _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_b);
            translate([_dep_bx, _dep_by, tier_z])
                _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_b);
        }
        // Ring gusset
        hull() {
            translate([_ring_x, _ring_y, tier_z])
                _stub_end_profile(a);
            translate([FRAME_RING_R_IN * cos(a),
                       FRAME_RING_R_IN * sin(a), tier_z])
                rotate([0, 0, a]) rotate([0, 90, 0])
                    cube([min(STUB_H, FRAME_RING_H),
                          STUB_W + 4, FRAME_RING_W], center = true);
        }
    }
    // Vertical spine
    hull() {
        translate([_jx, _jy, UPPER_RING_CENTER_Z])
            _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_a);
        translate([_jx, _jy, UPPER_RING_CENTER_Z])
            _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_b);
        translate([_jx, _jy, LOWER_RING_CENTER_Z])
            _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_a);
        translate([_jx, _jy, LOWER_RING_CENTER_Z])
            _chamfered_rect_profile(ARM_W, ARM_H, CHAMFER_ARM_ROOT, _ai_b);
    }
}


// =========================================================
// UNIFIED ARM CORRIDORS — V5.8: True Continuous Frame
// =========================================================
// Architecture: Each arm pair shares a U-BRIDGE at the carrier
// point. The upper arm curves down, the lower arm curves up,
// meeting at a smooth U-shaped bridge where the bearing sits.
// NO swells/blobs — just the arm curving to meet its partner.
//
// Junction: stub, spine, and arm departures are ONE hull chain.
// The stub's end profile sweeps continuously through the junction
// center into each arm's first segment — no separate shapes.
//
// Taper: arms taper from root (ARM_W×ARM_H) to tip dimensions.
// The carrier zone simply IS where the arm meets the bridge.
// =========================================================

_ARM_TIP_W = ARM_W * ARM_TAPER_RATIO;
_ARM_TIP_H = ARM_H * ARM_TAPER_RATIO;
_NODE_BLEND_LEN = 15;
_NODE_SWELL_D = STUB_W * NODE_SWELL_FACTOR;
_BOSS_RING_D = CARRIER_BRG_BORE + CARRIER_WALL*2 + CARRIER_NODE_BULGE + CARRIER_BOSS_EXTRA;
DAMPENER_FRAC = 0.50;

// U-bridge parameters (used by arm vertical section housing calcs)
_BRIDGE_BEARING_WALL = 2.5;  // wall thickness around bearing bore in arm body

// Bridge block parameters (approved carrier_test.scad design)
// One solid block per arm at shaft crossing. Added by _all_carrier_plates().
// Arms are NOT modified — the bridge is separate geometry that overlaps and
// merges with the arm body via OpenSCAD union.
// BRIDGE_D = depth along arm direction (enough to house bearing with 4mm wall).
// BRIDGE_W = width perpendicular to arm direction (flush with arms).
// BRIDGE_CHAMFER = edge chamfer (matches arm language).
// Z extents computed per-arm from actual arm Z at crossing (convergence-adjusted).
BRIDGE_HOUSING_WALL = 4.0;                                       // wall around bearing bore
BRIDGE_D      = FRAME_BRG_OD + BRIDGE_HOUSING_WALL * 2;          // 16mm depth along arm
BRIDGE_W      = ARM_W;                                            // 10mm — flush with arms
BRIDGE_CHAMFER = ARM_CHAMFER;                                     // 1mm — matches arm edges

// Compute arm cross-section at any fraction (pure taper, no swell)
function _arm_w_at(frac, end_frac) =
    let(t = min(1, frac / max(0.01, end_frac)))
    ARM_W + (_ARM_TIP_W - ARM_W) * t;
function _arm_h_at(frac, end_frac) =
    let(t = min(1, frac / max(0.01, end_frac)))
    ARM_H + (_ARM_TIP_H - ARM_H) * t;
function _arm_chamfer_at(frac, end_frac) =
    let(t = min(1, frac / max(0.01, end_frac)))
    CHAMFER_ARM_ROOT + (CHAMFER_ARM_TIP - CHAMFER_ARM_ROOT) * t;

// =========================================================
// ARM U-LOOP GEOMETRY (no color/bore — called from _render_corridor)
// =========================================================
module _arm_u_loop_geom(ai) {
    _jxy = _junction_xy(ai);
    _ad = _arm_dir(ai);
    _flen = _arm_full_len(ai);
    _ef = _arm_end_frac(ai);
    hi = ARM_HELIX[ai];
    _cross_frac = _shaft_crossing_frac(ai, hi);
    _z_upper = UPPER_RING_CENTER_Z;
    _z_lower = LOWER_RING_CENTER_Z;
    _z_cross_up = _beam_z_at_frac(_cross_frac, true);
    _z_cross_lo = _beam_z_at_frac(_cross_frac, false);
    _cross_len = _cross_frac * _flen;
    _cx = _jxy[0]+_ad[0]*_cross_len;
    _cy = _jxy[1]+_ad[1]*_cross_len;
    _cw = _arm_w_at(_cross_frac, _ef);
    _ch = _arm_h_at(_cross_frac, _ef);
    _cc = _arm_chamfer_at(_cross_frac, _ef);

    // Outbound: junction (upper) → crossing (upper)
    for (i = [0 : _U_SEGS_HORIZ - 1]) {
        _s0 = _u_arm_station(i, _U_SEGS_HORIZ, _jxy, _ad,
                              _cross_frac, _flen, _ef, _z_upper, _z_cross_up);
        _s1 = _u_arm_station(i+1, _U_SEGS_HORIZ, _jxy, _ad,
                              _cross_frac, _flen, _ef, _z_upper, _z_cross_up);
        hull() {
            translate([_s0[0], _s0[1], _s0[2]])
                _chamfered_rect_profile(_s0[3], _s0[4], _s0[5], ai);
            translate([_s1[0], _s1[1], _s1[2]])
                _chamfered_rect_profile(_s1[3], _s1[4], _s1[5], ai);
        }
    }
    // Vertical section: upper → lower at crossing
    for (i = [0 : _U_SEGS_VERT * 2 - 1]) {
        t0 = i / (_U_SEGS_VERT * 2);
        t1 = (i + 1) / (_U_SEGS_VERT * 2);
        _z0 = _z_cross_up + (_z_cross_lo - _z_cross_up) * t0;
        _z1 = _z_cross_up + (_z_cross_lo - _z_cross_up) * t1;
        hull() {
            translate([_cx, _cy, _z0])
                _chamfered_rect_profile(_cw, _ch, _cc, ai);
            translate([_cx, _cy, _z1])
                _chamfered_rect_profile(_cw, _ch, _cc, ai);
        }
    }
    // Return: crossing (lower) → junction (lower)
    for (i = [0 : _U_SEGS_HORIZ - 1]) {
        _s0 = _u_arm_station(_U_SEGS_HORIZ - i, _U_SEGS_HORIZ, _jxy, _ad,
                              _cross_frac, _flen, _ef, _z_lower, _z_cross_lo);
        _s1 = _u_arm_station(_U_SEGS_HORIZ - (i+1), _U_SEGS_HORIZ, _jxy, _ad,
                              _cross_frac, _flen, _ef, _z_lower, _z_cross_lo);
        hull() {
            translate([_s0[0], _s0[1], _s0[2]])
                _chamfered_rect_profile(_s0[3], _s0[4], _s0[5], ai);
            translate([_s1[0], _s1[1], _s1[2]])
                _chamfered_rect_profile(_s1[3], _s1[4], _s1[5], ai);
        }
    }
}

// =========================================================
// LINKAGE GEOMETRY (no color — called from _render_corridor)
// =========================================================
// V5.8b: Linkage endpoints coincide with dampener buttress-arm
// junctions. Cross-section matches buttress flare dimensions
// for a clean unified node where arm + buttress + linkage meet.
module _linkage_geom(si) {
    stub_angle = STUB_ANGLES[si];
    _ai_a = si*2; _ai_b = si*2+1;
    start_xy = [JUNCTION_R*cos(stub_angle), JUNCTION_R*sin(stub_angle)];
    _ad_a = _arm_dir(_ai_a); _flen_a = _arm_full_len(_ai_a); _ef_a = _arm_end_frac(_ai_a);
    end_a = [start_xy[0]+_ad_a[0]*_ef_a*_flen_a, start_xy[1]+_ad_a[1]*_ef_a*_flen_a];
    _ad_b = _arm_dir(_ai_b); _flen_b = _arm_full_len(_ai_b); _ef_b = _arm_end_frac(_ai_b);
    end_b = [start_xy[0]+_ad_b[0]*_ef_b*_flen_b, start_xy[1]+_ad_b[1]*_ef_b*_flen_b];
    _ezua = _beam_z_at_frac(_ef_a, true); _ezla = _beam_z_at_frac(_ef_a, false);
    _ezub = _beam_z_at_frac(_ef_b, true); _ezlb = _beam_z_at_frac(_ef_b, false);
    a_up = _arm_pt(start_xy, end_a, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _ezua);
    a_lo = _arm_pt(start_xy, end_a, DAMPENER_FRAC, LOWER_RING_CENTER_Z, _ezla);
    b_up = _arm_pt(start_xy, end_b, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _ezub);
    b_lo = _arm_pt(start_xy, end_b, DAMPENER_FRAC, LOWER_RING_CENTER_Z, _ezlb);
    // Cross-section matches buttress flare at arm junction (unified node)
    _bw = DAMPENER_BAR_W * _BUTTRESS_ARM_FLARE;
    _bh = DAMPENER_BAR_H * _BUTTRESS_ARM_FLARE;
    _beam_curved(a_up, b_up, _bw, _bh, LINKAGE_SAG, LINKAGE_SEGMENTS, CHAMFER_LINKAGE);
    _beam_curved(a_lo, b_lo, _bw, _bh, LINKAGE_SAG, LINKAGE_SEGMENTS, CHAMFER_LINKAGE);
}

// =========================================================
// CARRIER BRIDGE GEOMETRY (no color/bore — called from _render_corridor)
// =========================================================
module _carrier_bridge_geom(ai) {
    hi = ARM_HELIX[ai];
    _cross_frac = _shaft_crossing_frac(ai, hi);
    _flen = _arm_full_len(ai);
    _ef = _arm_end_frac(ai);
    _jxy = _junction_xy(ai);
    _ad = _arm_dir(ai);
    _cross_len = _cross_frac * _flen;
    _cx = _jxy[0] + _ad[0] * _cross_len;
    _cy = _jxy[1] + _ad[1] * _cross_len;
    _z_cross_up = _beam_z_at_frac(_cross_frac, true);
    _z_cross_lo = _beam_z_at_frac(_cross_frac, false);
    _ch = _arm_h_at(_cross_frac, _ef);
    _bz_top = _z_cross_up + _ch / 2 - BRIDGE_CHAMFER;
    _bz_bot = _z_cross_lo - _ch / 2 + BRIDGE_CHAMFER;
    _bridge_block_at(_cx, _cy, ai, _bz_top, _bz_bot);
}

// =========================================================
// DAMPENER GEOMETRY for one corridor (no color — called from _render_corridor)
// =========================================================
// V5.8b: Tapered buttresses replace flimsy vertical ties.
// Each arm gets a vertical buttress that WIDENS at the arm junction
// (top and bottom) and narrows at bar Z — like a column with flared
// feet. This reads as "load flowing from arm into bar" and provides
// fillet-like stress relief at the T-junction.
//
// Bar: FULL span (not split), rendered by both corridors (OpenSCAD
// union handles the overlap). Hole pattern preserved: NUM_CAMS holes
// at STACK_OFFSET spacing, centered on full bar span.
// =========================================================

// Buttress sizing: bar face matches DAMPENER_BAR dimensions (7×7mm),
// arm junction face flares 20% wider than bar for fillet-like stress relief.
// Depth along arm direction = DAMPENER_BAR_W (so buttress is a solid block,
// not a thin wall). At arm junctions, depth also flares.
_BUTTRESS_ARM_FLARE = 1.20;  // arm junction face = 120% of bar dimensions
_BUTTRESS_DEPTH     = DAMPENER_BAR_W;  // depth along arm direction at bar Z

module _dampener_geom_for_corridor(si) {
    _ai_a = si * 2;
    _ai_b = si * 2 + 1;

    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        // Only render if this helix pair includes one of our arms
        if (_pair[0] == _ai_a || _pair[0] == _ai_b ||
            _pair[1] == _ai_a || _pair[1] == _ai_b) {

            _hz = DAMPENER_TIER_Z[hi];

            // Compute both arms of the helix pair
            _start_a = [JUNCTION_R*cos(ARM_DEFS[_pair[0]][0]),
                        JUNCTION_R*sin(ARM_DEFS[_pair[0]][0])];
            _ad_a = _arm_dir(_pair[0]);
            _flen_a = _arm_full_len(_pair[0]);
            _ef_a = _arm_end_frac(_pair[0]);
            _end_a = [_start_a[0]+_ad_a[0]*_ef_a*_flen_a,
                      _start_a[1]+_ad_a[1]*_ef_a*_flen_a];

            _start_b = [JUNCTION_R*cos(ARM_DEFS[_pair[1]][0]),
                        JUNCTION_R*sin(ARM_DEFS[_pair[1]][0])];
            _ad_b = _arm_dir(_pair[1]);
            _flen_b = _arm_full_len(_pair[1]);
            _ef_b = _arm_end_frac(_pair[1]);
            _end_b = [_start_b[0]+_ad_b[0]*_ef_b*_flen_b,
                      _start_b[1]+_ad_b[1]*_ef_b*_flen_b];

            _ezua = _beam_z_at_frac(_ef_a, true); _ezla = _beam_z_at_frac(_ef_a, false);
            _ezub = _beam_z_at_frac(_ef_b, true); _ezlb = _beam_z_at_frac(_ef_b, false);

            // Arm points — upper and lower tiers
            _da_up = _arm_pt(_start_a,_end_a,DAMPENER_FRAC,UPPER_RING_CENTER_Z,_ezua);
            _da_lo = _arm_pt(_start_a,_end_a,DAMPENER_FRAC,LOWER_RING_CENTER_Z,_ezla);
            _db_up = _arm_pt(_start_b,_end_b,DAMPENER_FRAC,UPPER_RING_CENTER_Z,_ezub);
            _db_lo = _arm_pt(_start_b,_end_b,DAMPENER_FRAC,LOWER_RING_CENTER_Z,_ezlb);

            // Bar endpoint XY (same as upper arm XY at DAMPENER_FRAC)
            _bar_a = [_da_up[0], _da_up[1], _hz];
            _bar_b = [_db_up[0], _db_up[1], _hz];

            // Cross-sections matched to arm taper at DAMPENER_FRAC
            _tw_a = _arm_w_at(DAMPENER_FRAC, _ef_a);
            _th_a = _arm_h_at(DAMPENER_FRAC, _ef_a);
            _tw_b = _arm_w_at(DAMPENER_FRAC, _ef_b);
            _th_b = _arm_h_at(DAMPENER_FRAC, _ef_b);
            _tc = _arm_chamfer_at(DAMPENER_FRAC, _ef_a);

            // --- TAPERED BUTTRESSES for arms belonging to this corridor ---
            // Each buttress: hull chain from upper arm → bar Z → lower arm
            // with cross-section widening at the arm faces (flared feet)
            if (_pair[0] == _ai_a || _pair[0] == _ai_b) {
                _dampener_buttress(
                    _da_up, _bar_a, _da_lo,
                    _tw_a, _th_a, _tc, _pair[0]);
            }
            if (_pair[1] == _ai_a || _pair[1] == _ai_b) {
                _dampener_buttress(
                    _db_up, _bar_b, _db_lo,
                    _tw_b, _th_b, _tc, _pair[1]);
            }

            // --- FULL-SPAN BAR (shared between corridors, rendered from both) ---
            _dampener_guide_bar(_bar_a, _bar_b);
        }
    }
}

// Tapered buttress: vertical member that widens at arm junctions.
// p_up = upper arm attachment point (full cross-section)
// p_bar = bar attachment point (narrowed cross-section)
// p_lo = lower arm attachment point (full cross-section)
// w, h = arm cross-section at DAMPENER_FRAC
// tc = chamfer at this arm fraction
// ai = arm index (for profile orientation)
module _dampener_buttress(p_up, p_bar, p_lo, w, h, tc, ai) {
    // Bar-level face: match dampener bar dimensions (thick, solid)
    _bw = DAMPENER_BAR_W;
    _bh = DAMPENER_BAR_H;
    // Arm junction face: flared wider than bar for fillet-like stress relief
    _aw = _bw * _BUTTRESS_ARM_FLARE;
    _ah = _bh * _BUTTRESS_ARM_FLARE;

    // Arm direction unit vector (for depth offset along arm)
    _ad = _arm_dir(ai);
    // Depth along arm: at bar Z = _BUTTRESS_DEPTH, at arm junction = flared
    _bd = _BUTTRESS_DEPTH;       // depth at bar Z
    _ad_depth = _bd * _BUTTRESS_ARM_FLARE;  // depth at arm junction (flared)

    // Helper: place two profiles offset ±d/2 along arm direction
    // This gives the buttress real depth (block, not thin wall)

    // Upper segment: arm junction face (flared) → bar face (solid)
    for (i = [0 : 2]) {
        _t0 = i / 3;
        _t1 = (i + 1) / 3;
        _w0 = _aw + (_bw - _aw) * _t0;
        _h0 = _ah + (_bh - _ah) * _t0;
        _d0 = _ad_depth + (_bd - _ad_depth) * _t0;
        _w1 = _aw + (_bw - _aw) * _t1;
        _h1 = _ah + (_bh - _ah) * _t1;
        _d1 = _ad_depth + (_bd - _ad_depth) * _t1;
        _p0 = [p_up[0] + (p_bar[0]-p_up[0])*_t0,
               p_up[1] + (p_bar[1]-p_up[1])*_t0,
               p_up[2] + (p_bar[2]-p_up[2])*_t0];
        _p1 = [p_up[0] + (p_bar[0]-p_up[0])*_t1,
               p_up[1] + (p_bar[1]-p_up[1])*_t1,
               p_up[2] + (p_bar[2]-p_up[2])*_t1];
        hull() {
            // Station 0: two profiles offset along arm for depth
            translate([_p0[0]+_ad[0]*_d0/2, _p0[1]+_ad[1]*_d0/2, _p0[2]])
                _chamfered_rect_profile(_w0, _h0, tc, ai);
            translate([_p0[0]-_ad[0]*_d0/2, _p0[1]-_ad[1]*_d0/2, _p0[2]])
                _chamfered_rect_profile(_w0, _h0, tc, ai);
            // Station 1: two profiles offset along arm for depth
            translate([_p1[0]+_ad[0]*_d1/2, _p1[1]+_ad[1]*_d1/2, _p1[2]])
                _chamfered_rect_profile(_w1, _h1, tc, ai);
            translate([_p1[0]-_ad[0]*_d1/2, _p1[1]-_ad[1]*_d1/2, _p1[2]])
                _chamfered_rect_profile(_w1, _h1, tc, ai);
        }
    }

    // Lower segment: bar face (solid) → arm junction face (flared)
    for (i = [0 : 2]) {
        _t0 = i / 3;
        _t1 = (i + 1) / 3;
        _w0 = _bw + (_aw - _bw) * _t0;
        _h0 = _bh + (_ah - _bh) * _t0;
        _d0 = _bd + (_ad_depth - _bd) * _t0;
        _w1 = _bw + (_aw - _bw) * _t1;
        _h1 = _bh + (_ah - _bh) * _t1;
        _d1 = _bd + (_ad_depth - _bd) * _t1;
        _p0 = [p_bar[0] + (p_lo[0]-p_bar[0])*_t0,
               p_bar[1] + (p_lo[1]-p_bar[1])*_t0,
               p_bar[2] + (p_lo[2]-p_bar[2])*_t0];
        _p1 = [p_bar[0] + (p_lo[0]-p_bar[0])*_t1,
               p_bar[1] + (p_lo[1]-p_bar[1])*_t1,
               p_bar[2] + (p_lo[2]-p_bar[2])*_t1];
        hull() {
            translate([_p0[0]+_ad[0]*_d0/2, _p0[1]+_ad[1]*_d0/2, _p0[2]])
                _chamfered_rect_profile(_w0, _h0, tc, ai);
            translate([_p0[0]-_ad[0]*_d0/2, _p0[1]-_ad[1]*_d0/2, _p0[2]])
                _chamfered_rect_profile(_w0, _h0, tc, ai);
            translate([_p1[0]+_ad[0]*_d1/2, _p1[1]+_ad[1]*_d1/2, _p1[2]])
                _chamfered_rect_profile(_w1, _h1, tc, ai);
            translate([_p1[0]-_ad[0]*_d1/2, _p1[1]-_ad[1]*_d1/2, _p1[2]])
                _chamfered_rect_profile(_w1, _h1, tc, ai);
        }
    }
}

// Stub end cross-section — a chamfered rect matching stub dimensions
// Used at both the stub endpoint AND the junction spine, ensuring
// seamless material flow (no sphere-vs-rect seam)
module _stub_end_profile(angle) {
    _c = CHAMFER_STUB;
    rotate([0, 0, angle])
    if (_c > 0.2 && STUB_W > 2*_c && STUB_H > 2*_c)
        for (yc = [-STUB_W/2+_c, STUB_W/2-_c])
            for (zc = [-STUB_H/2+_c, STUB_H/2-_c])
                translate([0, yc, zc])
                    sphere(r = _c, $fn = 8);
    else
        cube([0.01, STUB_W, STUB_H], center = true);
}


// =========================================================
// ARM SPINES — V5.8: Each arm is ONE continuous U-loop
// =========================================================
// Each arm is a SINGLE continuous shape:
//   junction(upper Z) → outward → tip → curve down → HELIX_Z
//   → curve back up → inward → junction(lower Z)
//
// Like bending a metal rod into a U lying on its side.
// Not "two separate tiers + bridge" — ONE piece that loops.
//
// The hull chain traces this path with consistent cross-section.
// At the U-turn (arm tip), the arm curves down from upper tier Z
// through HELIX_Z and back up to lower tier Z. The bearing bore
// is carved through the arm body where the shaft crosses it.
//
// Path parameterized as t in [0..1]:
//   t=0.0 : junction at UPPER tier Z (arm root)
//   t=0.5 : arm tip at HELIX_Z (U-turn bottom)
//   t=1.0 : junction at LOWER tier Z (arm root)
//
// The outbound half (0→0.5) tapers root→tip.
// The return half (0.5→1) tapers tip→root.
// This gives the arm a symmetrical U-shape.
module _all_frame_arms() {
    for (ai = [0 : 5]) {
        _render_arm_u_loop(ai);
    }
}

// Number of segments per section
_U_SEGS_HORIZ = 10;   // horizontal arm run (junction → crossing)
_U_SEGS_VERT = 5;     // vertical descent/ascent at crossing

// Render one arm as a continuous U-loop.
// Path: junction(upper) → crossing(upper) → descent → bearing housing
//       → ascent → crossing(lower) → junction(lower)
//
// The vertical legs and bearing housing at the bottom of the U are
// sized to completely enclose the bearing. The arm is ONE shape.
module _render_arm_u_loop(ai) {
    _jxy = _junction_xy(ai);
    _ad = _arm_dir(ai);
    _flen = _arm_full_len(ai);
    _ef = _arm_end_frac(ai);

    hi = ARM_HELIX[ai];
    _sa = _shaft_angle(hi);
    _cross_frac = _shaft_crossing_frac(ai, hi);
    _cross_xy = _shaft_crossing_xy(ai, hi);

    // Z values
    _z_upper = UPPER_RING_CENTER_Z;
    _z_lower = LOWER_RING_CENTER_Z;
    _z_cross_up = _beam_z_at_frac(_cross_frac, true);
    _z_cross_lo = _beam_z_at_frac(_cross_frac, false);

    // Crossing XY on this arm
    _cross_len = _cross_frac * _flen;
    _cx = _jxy[0]+_ad[0]*_cross_len;
    _cy = _jxy[1]+_ad[1]*_cross_len;

    // Arm cross-section at crossing (tapered)
    _cw = _arm_w_at(_cross_frac, _ef);
    _ch = _arm_h_at(_cross_frac, _ef);
    _cc = _arm_chamfer_at(_cross_frac, _ef);

    // Bearing housing dimensions — must fully enclose the bearing
    // Width along shaft axis: bearing width + wall on each side
    _housing_w = max(_cw, FRAME_BRG_W + _BRIDGE_BEARING_WALL * 2);
    // Height perpendicular to shaft: bearing OD + wall on each side
    _housing_h = FRAME_BRG_OD + _BRIDGE_BEARING_WALL * 2;
    // Depth along arm direction: bearing OD + walls
    _housing_d = FRAME_BRG_OD + _BRIDGE_BEARING_WALL * 2;

    color(C_ARMS_COL[ai])
    difference() {
        union() {
            // === 1. OUTBOUND: junction (upper Z) → crossing (upper Z) ===
            for (i = [0 : _U_SEGS_HORIZ - 1]) {
                _s0 = _u_arm_station(i, _U_SEGS_HORIZ, _jxy, _ad,
                                      _cross_frac, _flen, _ef, _z_upper, _z_cross_up);
                _s1 = _u_arm_station(i+1, _U_SEGS_HORIZ, _jxy, _ad,
                                      _cross_frac, _flen, _ef, _z_upper, _z_cross_up);
                hull() {
                    translate([_s0[0], _s0[1], _s0[2]])
                        _chamfered_rect_profile(_s0[3], _s0[4], _s0[5], ai);
                    translate([_s1[0], _s1[1], _s1[2]])
                        _chamfered_rect_profile(_s1[3], _s1[4], _s1[5], ai);
                }
            }

            // === 2-4. VERTICAL SECTION: upper arm → bearing → lower arm ===
            // Same cross-section as the arm. No widening. The arm IS thick
            // enough to house the bearing (ARM_W/ARM_H sized for bearing).
            // Just a vertical run of the same arm profile.
            for (i = [0 : _U_SEGS_VERT * 2 - 1]) {
                t0 = i / (_U_SEGS_VERT * 2);
                t1 = (i + 1) / (_U_SEGS_VERT * 2);
                _z0 = _z_cross_up + (_z_cross_lo - _z_cross_up) * t0;
                _z1 = _z_cross_up + (_z_cross_lo - _z_cross_up) * t1;
                hull() {
                    translate([_cx, _cy, _z0])
                        _chamfered_rect_profile(_cw, _ch, _cc, ai);
                    translate([_cx, _cy, _z1])
                        _chamfered_rect_profile(_cw, _ch, _cc, ai);
                }
            }

            // === 5. RETURN: crossing (lower Z) → junction (lower Z) ===
            for (i = [0 : _U_SEGS_HORIZ - 1]) {
                // Reversed: crossing back to junction
                _s0 = _u_arm_station(_U_SEGS_HORIZ - i, _U_SEGS_HORIZ, _jxy, _ad,
                                      _cross_frac, _flen, _ef, _z_lower, _z_cross_lo);
                _s1 = _u_arm_station(_U_SEGS_HORIZ - (i+1), _U_SEGS_HORIZ, _jxy, _ad,
                                      _cross_frac, _flen, _ef, _z_lower, _z_cross_lo);
                hull() {
                    translate([_s0[0], _s0[1], _s0[2]])
                        _chamfered_rect_profile(_s0[3], _s0[4], _s0[5], ai);
                    translate([_s1[0], _s1[1], _s1[2]])
                        _chamfered_rect_profile(_s1[3], _s1[4], _s1[5], ai);
                }
            }
        }

        // Bearing bore — through the housing at shaft crossing
        translate([_cross_xy[0], _cross_xy[1], HELIX_Z])
            rotate([0, 0, _sa]) rotate([0, 90, 0])
                cylinder(d=CARRIER_BRG_BORE, h=_housing_w+4, center=true, $fn=32);
        // Shaft clearance — extends well beyond housing
        translate([_cross_xy[0], _cross_xy[1], HELIX_Z])
            rotate([0, 0, _sa]) rotate([0, 90, 0])
                cylinder(d=SHAFT_DIA+1, h=200, center=true, $fn=24);
    }

    // Visual bearing
    color(C_BEARING)
    translate([_cross_xy[0], _cross_xy[1], HELIX_Z])
        rotate([0, 0, _sa]) rotate([0, 90, 0])
            difference() {
                cylinder(d=FRAME_BRG_OD, h=FRAME_BRG_W, center=true, $fn=32);
                cylinder(d=FRAME_BRG_ID, h=FRAME_BRG_W+2, center=true, $fn=32);
            }
}

// Compute a station along the horizontal arm path.
// seg_idx from 0 (junction) to num_segs (crossing).
function _u_arm_station(seg_idx, num_segs, jxy, ad, cross_frac, flen, ef, z_junc, z_cross) =
    let(
        arm_t = seg_idx / num_segs,
        frac = arm_t * cross_frac,
        len_mm = frac * flen,
        px = jxy[0] + ad[0] * len_mm,
        py = jxy[1] + ad[1] * len_mm,
        pz = z_junc + (z_cross - z_junc) * arm_t,
        w = _arm_w_at(frac, ef),
        h = _arm_h_at(frac, ef),
        c = _arm_chamfer_at(frac, ef),
        flare = (frac < 0.001) ? 1.0 : (frac < 0.08) ? max(0, 1 - frac/0.08) : 0,
        fw = w + (STUB_W - w) * flare,
        fh = h + (STUB_H - h) * flare,
        fc = c + (CHAMFER_STUB - c) * flare
    )
    [px, py, pz, fw, fh, fc];

// Arm-oriented chamfered rectangle profile
// Oriented along the arm direction so all segments share the same
// cross-section plane — no orientation discontinuities
module _chamfered_rect_profile(w, h, chamfer, ai) {
    _az = atan2(_arm_dir(ai)[1], _arm_dir(ai)[0]);
    rotate([0, 0, _az])
    if (chamfer > 0.2 && w > 2*chamfer && h > 2*chamfer)
        for (yc = [-w/2+chamfer, w/2-chamfer])
            for (zc = [-h/2+chamfer, h/2-chamfer])
                translate([0, yc, zc])
                    sphere(r = chamfer, $fn = 8);
    else
        cube([0.01, max(0.5, w), max(0.5, h)], center = true);
}


// =========================================================
// BRIDGE BLOCK — solid bearing mount between upper & lower arm
// =========================================================
// One continuous block from upper arm outer face to lower arm
// outer face. BRIDGE_D deep along the arm direction, ARM_W wide
// (flush with arms), chamfered edges matching arm language.
// z_top/z_bot = outer faces of upper/lower arm AT THE CROSSING
// (accounts for arm convergence — NOT the junction Z values).
// Bearing bore carved by the parent difference() in _render_arm_u_loop.
module _bridge_block_at(cx, cy, ai, z_top, z_bot) {
    _az = atan2(_arm_dir(ai)[1], _arm_dir(ai)[0]);
    hull() {
        translate([cx, cy, z_top])
            _bridge_block_profile(_az);
        translate([cx, cy, z_bot])
            _bridge_block_profile(_az);
    }
}

// Bridge cross-section: BRIDGE_D along arm direction, BRIDGE_W perpendicular.
// Chamfered edges use BRIDGE_CHAMFER for visual consistency with arms.
module _bridge_block_profile(az) {
    _c = BRIDGE_CHAMFER;
    rotate([0, 0, az])
    if (_c > 0.2 && BRIDGE_D > 2*_c && BRIDGE_W > 2*_c)
        for (xc = [-BRIDGE_D/2+_c, BRIDGE_D/2-_c])
            for (yc = [-BRIDGE_W/2+_c, BRIDGE_W/2-_c])
                translate([xc, yc, 0])
                    sphere(r = _c, $fn = 8);
    else
        cube([BRIDGE_D, BRIDGE_W, 0.01], center=true);
}


// =========================================================
// ARM LINKAGES — matched cross-section at attachment points
// =========================================================
module _all_arm_linkages() {
    for (si = [0 : 2]) {
        stub_angle = STUB_ANGLES[si];
        _ai_a = si*2; _ai_b = si*2+1;
        start_xy = [JUNCTION_R*cos(stub_angle), JUNCTION_R*sin(stub_angle)];

        _ad_a = _arm_dir(_ai_a); _flen_a = _arm_full_len(_ai_a); _ef_a = _arm_end_frac(_ai_a);
        end_a = [start_xy[0]+_ad_a[0]*_ef_a*_flen_a, start_xy[1]+_ad_a[1]*_ef_a*_flen_a];

        _ad_b = _arm_dir(_ai_b); _flen_b = _arm_full_len(_ai_b); _ef_b = _arm_end_frac(_ai_b);
        end_b = [start_xy[0]+_ad_b[0]*_ef_b*_flen_b, start_xy[1]+_ad_b[1]*_ef_b*_flen_b];

        _ezua = _beam_z_at_frac(_ef_a, true); _ezla = _beam_z_at_frac(_ef_a, false);
        _ezub = _beam_z_at_frac(_ef_b, true); _ezlb = _beam_z_at_frac(_ef_b, false);

        a_up = _arm_pt(start_xy, end_a, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _ezua);
        a_lo = _arm_pt(start_xy, end_a, DAMPENER_FRAC, LOWER_RING_CENTER_Z, _ezla);
        b_up = _arm_pt(start_xy, end_b, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _ezub);
        b_lo = _arm_pt(start_xy, end_b, DAMPENER_FRAC, LOWER_RING_CENTER_Z, _ezlb);

        // Cross-section at attachment points — MATCHES arm taper at DAMPENER_FRAC
        _bw_a = _arm_w_at(DAMPENER_FRAC, _ef_a);
        _bh_a = _arm_h_at(DAMPENER_FRAC, _ef_a);
        _bw_b = _arm_w_at(DAMPENER_FRAC, _ef_b);
        _bh_b = _arm_h_at(DAMPENER_FRAC, _ef_b);
        // Brace cross-section: use the SMALLER of the two arm profiles (flush fit)
        _bw = min(_bw_a, _bw_b);
        _bh = min(_bh_a, _bh_b);

        // V5.7: Braces use matched cross-section — no overhang beyond arm surface
        color(C_LINKAGE) {
            _beam_curved(a_up, b_up, _bw, _bh, LINKAGE_SAG, LINKAGE_SEGMENTS, CHAMFER_LINKAGE);
            _beam_curved(a_lo, b_lo, _bw, _bh, LINKAGE_SAG, LINKAGE_SEGMENTS, CHAMFER_LINKAGE);
        }
    }
}


// =========================================================
// CARRIER BEARING BRIDGES — solid block per arm at shaft crossing
// =========================================================
// Each arm gets a solid bridge block at the shaft crossing point.
// The bridge spans from the upper arm outer face to the lower arm
// outer face, providing a reinforced housing for the MR84ZZ bearing.
//
// The bridge is SEPARATE geometry from the arms — it overlaps and
// merges via OpenSCAD union. Arms are NOT modified.
//
// Parametric controls: BRIDGE_D (depth along arm), BRIDGE_W (width
// perpendicular to arm), BRIDGE_CHAMFER (edge rounding).
// Height is derived from actual arm Z at each crossing (convergence-adjusted).
module _all_carrier_plates() {
    for (ai = [0 : 5]) {
        hi = ARM_HELIX[ai];
        _sa = _shaft_angle(hi);
        _cross_frac = _shaft_crossing_frac(ai, hi);
        _cross_xy = _shaft_crossing_xy(ai, hi);
        _flen = _arm_full_len(ai);
        _ef = _arm_end_frac(ai);
        _jxy = _junction_xy(ai);
        _ad = _arm_dir(ai);

        // Crossing XY on arm
        _cross_len = _cross_frac * _flen;
        _cx = _jxy[0] + _ad[0] * _cross_len;
        _cy = _jxy[1] + _ad[1] * _cross_len;

        // Arm Z at crossing (convergence-adjusted)
        _z_cross_up = _beam_z_at_frac(_cross_frac, true);
        _z_cross_lo = _beam_z_at_frac(_cross_frac, false);

        // Arm cross-section at crossing (for flush Z alignment)
        _ch = _arm_h_at(_cross_frac, _ef);

        // Bridge Z extents: flush with upper/lower arm outer faces at crossing.
        // Profile spheres (radius BRIDGE_CHAMFER) extend beyond the hull anchor
        // point, so inset by BRIDGE_CHAMFER to keep actual face flush.
        _bz_top = _z_cross_up + _ch / 2 - BRIDGE_CHAMFER;
        _bz_bot = _z_cross_lo - _ch / 2 + BRIDGE_CHAMFER;

        color(C_CARRIER)
        difference() {
            // Solid bridge block
            _bridge_block_at(_cx, _cy, ai, _bz_top, _bz_bot);

            // Bearing bore — through-hole at HELIX_Z
            translate([_cross_xy[0], _cross_xy[1], HELIX_Z])
                rotate([0, 0, _sa]) rotate([0, 90, 0])
                    cylinder(d = CARRIER_BRG_BORE, h = BRIDGE_W + 4,
                             center = true, $fn = 32);

            // Shaft clearance — extends well beyond bridge
            translate([_cross_xy[0], _cross_xy[1], HELIX_Z])
                rotate([0, 0, _sa]) rotate([0, 90, 0])
                    cylinder(d = SHAFT_DIA + 1, h = 200,
                             center = true, $fn = 24);
        }
    }
}


// =========================================================
// DAMPENER ARRAY — V5.8b: tapered buttresses (standalone version)
// =========================================================
// Kept for reference/debug — primary path is _dampener_geom_for_corridor()
module _dampener_array() {
    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        _hz = DAMPENER_TIER_Z[hi];

        _start_a = [JUNCTION_R*cos(ARM_DEFS[_pair[0]][0]),
                    JUNCTION_R*sin(ARM_DEFS[_pair[0]][0])];
        _ad_a = _arm_dir(_pair[0]);
        _flen_a = _arm_full_len(_pair[0]);
        _ef_a = _arm_end_frac(_pair[0]);
        _end_a = [_start_a[0]+_ad_a[0]*_ef_a*_flen_a,
                  _start_a[1]+_ad_a[1]*_ef_a*_flen_a];

        _start_b = [JUNCTION_R*cos(ARM_DEFS[_pair[1]][0]),
                    JUNCTION_R*sin(ARM_DEFS[_pair[1]][0])];
        _ad_b = _arm_dir(_pair[1]);
        _flen_b = _arm_full_len(_pair[1]);
        _ef_b = _arm_end_frac(_pair[1]);
        _end_b = [_start_b[0]+_ad_b[0]*_ef_b*_flen_b,
                  _start_b[1]+_ad_b[1]*_ef_b*_flen_b];

        _ezua = _beam_z_at_frac(_ef_a, true); _ezla = _beam_z_at_frac(_ef_a, false);
        _ezub = _beam_z_at_frac(_ef_b, true); _ezlb = _beam_z_at_frac(_ef_b, false);

        // Arm points — upper and lower tiers
        _da_up = _arm_pt(_start_a,_end_a,DAMPENER_FRAC,UPPER_RING_CENTER_Z,_ezua);
        _da_lo = _arm_pt(_start_a,_end_a,DAMPENER_FRAC,LOWER_RING_CENTER_Z,_ezla);
        _db_up = _arm_pt(_start_b,_end_b,DAMPENER_FRAC,UPPER_RING_CENTER_Z,_ezub);
        _db_lo = _arm_pt(_start_b,_end_b,DAMPENER_FRAC,LOWER_RING_CENTER_Z,_ezlb);

        // Bar endpoints
        _bar_a = [_da_up[0], _da_up[1], _hz];
        _bar_b = [_db_up[0], _db_up[1], _hz];

        // Cross-sections
        _tw_a = _arm_w_at(DAMPENER_FRAC, _ef_a);
        _th_a = _arm_h_at(DAMPENER_FRAC, _ef_a);
        _tw_b = _arm_w_at(DAMPENER_FRAC, _ef_b);
        _th_b = _arm_h_at(DAMPENER_FRAC, _ef_b);
        _tc = _arm_chamfer_at(DAMPENER_FRAC, _ef_a);

        // Dampener bar (full span — hole pattern centered on full length)
        color(C_STUB)
        _dampener_guide_bar(_bar_a, _bar_b);

        // Tapered buttresses
        color(C_STUB) {
            _dampener_buttress(_da_up, _bar_a, _da_lo,
                _tw_a, _th_a, _tc, _pair[0]);
            _dampener_buttress(_db_up, _bar_b, _db_lo,
                _tw_b, _th_b, _tc, _pair[1]);
        }
    }
}

// Vertical tie cross-section — chamfered rect matching arm profile
module _tie_profile(w, h, chamfer) {
    if (chamfer > 0.2 && w > 2*chamfer && h > 2*chamfer)
        for (yc = [-w/2+chamfer, w/2-chamfer])
            for (zc = [-h/2+chamfer, h/2-chamfer])
                translate([0, yc, zc])
                    sphere(r = chamfer, $fn = 8);
    else
        cube([0.01, max(0.5, w), max(0.5, h)], center = true);
}

// V5.5c R6: Dampener holes now have funnel taper on both entry faces
// for easier cable threading. Funnel mouth = 2× hole dia, taper depth = 1mm.
_DAMP_FUNNEL_MOUTH = DAMPENER_HOLE_DIA * 2;   // 4.0mm
_DAMP_FUNNEL_DEPTH = 1.0;                       // 1mm taper per face

module _dampener_guide_bar(p1, p2) {
    // V5.6 U5: Tapered bar — wider at ends, narrower at center (follows load path)
    // Height tapers from DAMPENER_BAR_H at ends to DAMP_TAPER_CENTER_H at midspan
    dx = p2[0]-p1[0]; dy = p2[1]-p1[1];
    bar_len = sqrt(dx*dx+dy*dy);
    az = atan2(dy, dx);
    _pattern_len = (NUM_CAMS-1) * STACK_OFFSET;
    _x_start = (bar_len - _pattern_len) / 2;
    _damp_segs = 8;
    _damp_chamfer = 1.0;  // edge rounding

    translate([p1[0],p1[1],p1[2]])
        rotate([0,0,az])
            difference() {
                // Tapered bar body — hull of segments with varying height
                for (si = [0 : _damp_segs - 1]) {
                    t0 = si / _damp_segs;
                    t1 = (si + 1) / _damp_segs;
                    x0 = t0 * bar_len;
                    x1 = t1 * bar_len;
                    // Parabolic taper: full height at ends (t=0,1), min at center (t=0.5)
                    _h0 = DAMPENER_BAR_H - (DAMPENER_BAR_H - DAMP_TAPER_CENTER_H) * 4 * t0 * (1 - t0);
                    _h1 = DAMPENER_BAR_H - (DAMPENER_BAR_H - DAMP_TAPER_CENTER_H) * 4 * t1 * (1 - t1);
                    hull() {
                        // Slice at t0 — chamfered rectangle cross-section
                        translate([x0, 0, 0])
                        if (_damp_chamfer > 0.2 && DAMPENER_BAR_W > 2*_damp_chamfer && _h0 > 2*_damp_chamfer)
                            for (yc = [-DAMPENER_BAR_W/2+_damp_chamfer, DAMPENER_BAR_W/2-_damp_chamfer])
                                for (zc = [-_h0/2+_damp_chamfer, _h0/2-_damp_chamfer])
                                    translate([0, yc, zc])
                                        sphere(r = _damp_chamfer, $fn = 8);
                        else
                            cube([0.01, DAMPENER_BAR_W, max(0.5, _h0)], center = true);
                        // Slice at t1
                        translate([x1, 0, 0])
                        if (_damp_chamfer > 0.2 && DAMPENER_BAR_W > 2*_damp_chamfer && _h1 > 2*_damp_chamfer)
                            for (yc = [-DAMPENER_BAR_W/2+_damp_chamfer, DAMPENER_BAR_W/2-_damp_chamfer])
                                for (zc = [-_h1/2+_damp_chamfer, _h1/2-_damp_chamfer])
                                    translate([0, yc, zc])
                                        sphere(r = _damp_chamfer, $fn = 8);
                        else
                            cube([0.01, DAMPENER_BAR_W, max(0.5, _h1)], center = true);
                    }
                }
                // Through-holes with funnel tapers (R6 preserved)
                for (ci = [0 : NUM_CAMS-1]) {
                    _gx = _x_start + ci * STACK_OFFSET;
                    // Through-hole
                    translate([_gx, -DAMPENER_BAR_W/2-1, 0])
                        rotate([-90,0,0])
                            cylinder(d=DAMPENER_HOLE_DIA, h=DAMPENER_BAR_W+2, $fn=16);
                    // Funnel taper — front face
                    translate([_gx, -DAMPENER_BAR_W/2-0.01, 0])
                        rotate([-90,0,0])
                            cylinder(d1=_DAMP_FUNNEL_MOUTH, d2=DAMPENER_HOLE_DIA,
                                     h=_DAMP_FUNNEL_DEPTH, $fn=16);
                    // Funnel taper — back face
                    translate([_gx, DAMPENER_BAR_W/2-_DAMP_FUNNEL_DEPTH+0.01, 0])
                        rotate([-90,0,0])
                            cylinder(d1=DAMPENER_HOLE_DIA, d2=_DAMP_FUNNEL_MOUTH,
                                     h=_DAMP_FUNNEL_DEPTH, $fn=16);
                }
            }
}


// =========================================================
// FRAME POSTS — stub vertices only [0, 120, 240]
// =========================================================
// V5.5: Only 3 posts at stub vertices. Helix-facing vertices
// [60, 180, 300] left clear for slider travel.
module _all_frame_posts() {
    _post_h = UPPER_RING_Z + FRAME_RING_H - (LOWER_RING_Z - GUIDE_STACK_H);

    for (si = [0 : FRAME_POST_COUNT - 1]) {
        a = FRAME_POST_ANGLES[si];
        px = POST_NOTCH_R * cos(a);
        py = POST_NOTCH_R * sin(a);

        color(C_FRAME)
        translate([px, py, LOWER_RING_Z - GUIDE_STACK_H])
            cylinder(d = POST_DIA, h = _post_h, $fn = 12);
    }
}


// =========================================================
// IDLER BRACKETS (structural — part of monolith)
// =========================================================
// Switchable clevis bracket design (V5.5d):
//   "printed" mode: monolithic smooth disc + printed bolt + c-clamp
//   "bolt" mode:    M3 clearance hole for purchased GT2 flanged idler
// Both modes use identical clevis walls with 3.2mm bore.
// Toggle via IDLER_MODE in config_v5_5.scad.
// Reference: 507 Mechanical Movements No.3/4 (Marcos Cerro),
//            various-pulleys bracket (Aaron C).

// Clevis geometry — consistent block for all idler positions
_CLEVIS_WALL_T     = IDLER_CLEVIS_WALL;            // each wall thickness (3mm)
_CLEVIS_INNER_GAP  = IDLER_CLEVIS_GAP;             // gap between walls (~8.6mm)
_CLEVIS_BORE_D     = IDLER_M3_CLEARANCE;           // 3.2mm — accepts M3 bolt or printed 3mm shaft
_CLEVIS_PLATE_W    = IDLER_FLANGE_OD + 4;          // wall width/depth (clears flange + margin)
_CLEVIS_FULL_SPAN  = _CLEVIS_INNER_GAP + 2 * _CLEVIS_WALL_T;  // total span across walls

// Z placement — at lower ring center (below helix midplane)
_IDLER_Z           = LOWER_RING_CENTER_Z;

// Printed idler disc (for "printed" mode — monolithic with bracket)
_PRINTED_GUIDE_D   = IDLER_OD;
_PRINTED_GUIDE_H   = GT2_BELT_W + 1;
_PRINTED_FLANGE_D  = IDLER_FLANGE_OD;
_PRINTED_FLANGE_H  = 0.8;
_PRINTED_BORE_D    = IDLER_BORE;                   // 3mm — slides onto printed bolt or M3

module _idler_bracket(pos, jx, jy, stub_ang) {
    // Clevis walls oriented perpendicular to stub radial direction.
    // Bore axis runs along stub radial (so bolt points outward from center).
    // This gives consistent appearance regardless of which stub.

    // --- Bracket arm: hull from junction node → clevis base ---
    hull() {
        translate([jx, jy, _IDLER_Z])
            cube([_BRACKET_ARM_W, _BRACKET_ARM_W, _CLEVIS_PLATE_W], center = true);
        translate([pos[0], pos[1], _IDLER_Z])
            cube([_CLEVIS_PLATE_W, _CLEVIS_PLATE_W, _CLEVIS_PLATE_W], center = true);
    }

    // --- Clevis block at idler position ---
    translate([pos[0], pos[1], _IDLER_Z])
    rotate([0, 0, stub_ang]) {
        // Bore runs along local X (radial direction from center).
        // Walls are perpendicular plates at ±offset along local X.
        difference() {
            union() {
                // Two clevis walls perpendicular to bore axis (local X)
                for (_side = [-1, 1]) {
                    translate([_side * (_CLEVIS_INNER_GAP/2 + _CLEVIS_WALL_T/2), 0, 0])
                        cube([_CLEVIS_WALL_T, _CLEVIS_PLATE_W, _CLEVIS_PLATE_W], center = true);
                }
                // Base block connecting the two walls (bottom half)
                translate([0, 0, -_CLEVIS_PLATE_W/4])
                    cube([_CLEVIS_FULL_SPAN, _CLEVIS_PLATE_W, _CLEVIS_PLATE_W/2], center = true);
            }

            // M3 clearance bore through both walls (along local X = radial)
            rotate([0, 90, 0])
                cylinder(d = _CLEVIS_BORE_D, h = _CLEVIS_FULL_SPAN + 2, center = true, $fn = 24);
        }

        // --- Idler disc (mode-dependent) ---
        if (IDLER_MODE == "printed") {
            // Monolithic printed smooth idler centered in clevis gap
            rotate([0, 90, 0])
            translate([0, 0, -_PRINTED_GUIDE_H/2 - _PRINTED_FLANGE_H]) {
                // Lower flange
                cylinder(d = _PRINTED_FLANGE_D, h = _PRINTED_FLANGE_H, $fn = 32);
                // Guide cylinder
                translate([0, 0, _PRINTED_FLANGE_H])
                    difference() {
                        cylinder(d = _PRINTED_GUIDE_D, h = _PRINTED_GUIDE_H, $fn = 32);
                        translate([0, 0, -0.1])
                            cylinder(d = _PRINTED_BORE_D, h = _PRINTED_GUIDE_H + 0.2, $fn = 24);
                    }
                // Upper flange
                translate([0, 0, _PRINTED_FLANGE_H + _PRINTED_GUIDE_H])
                    cylinder(d = _PRINTED_FLANGE_D, h = _PRINTED_FLANGE_H, $fn = 32);
            }
        }
        // "bolt" mode: empty gap — user inserts M3 bolt + purchased idler + nut
    }
}

module _all_idler_brackets() {
    for (si = [0, 1]) {
        pos = _idler_world_xy(si);
        stub_a = STUB_ANGLES[si];
        _jx = JUNCTION_R * cos(stub_a);
        _jy = JUNCTION_R * sin(stub_a);

        color(C_BRACKET)
            _idler_bracket(pos, _jx, _jy, stub_a);
    }
}


// =========================================================
// MOTOR BRACKET (structural — part of monolith)
// =========================================================
module _motor_bracket() {
    _hi = MOTOR_HELIX_IDX;
    _hc = _helix_center(_hi);
    _sd = _shaft_dir(_hi);
    _sa = HELIX_ANGLES[_hi] + 90;

    _mxy_offset = _GT2_OFFSET_FROM_HELIX + GT2_BOSS_H/2 + MOTOR_GAP + MOTOR_BODY_LEN/2;
    _mxy = [_hc[0] + _sd[0] * _mxy_offset, _hc[1] + _sd[1] * _mxy_offset];

    color(C_BRACKET)
    translate([_mxy[0], _mxy[1], HELIX_Z])
        rotate([0, 0, _sa])
            cube([_MOTOR_BRACKET_T, MOTOR_BODY_DIA + _MOTOR_BRACKET_CLR, MOTOR_BODY_DIA + _MOTOR_BRACKET_CLR], center = true);
}


// =========================================================
// DRIVE CHAIN VISUALS (GT2, idlers, motor — NOT printed in monolith)
// =========================================================
module _drive_chain_visuals() {
    // GT2 pulleys
    for (hi = [0 : 2]) {
        for (sign = [-1, 1]) {
            _gxy = _gt2_world_xy(hi, sign);
            _sa = HELIX_ANGLES[hi] + 90;
            // Only render GT2s that are used in drive chain
            _show = (hi == 0 && sign == -1) ||
                    (hi == 1 && sign == 1) ||
                    (hi == 2);
            if (_show) {
                translate([_gxy[0], _gxy[1], HELIX_Z])
                    rotate([0, 0, _sa]) rotate([0, 90, 0]) {
                        color([0.9, 0.75, 0.0, 0.9])
                        difference() {
                            cylinder(d = GT2_OD, h = GT2_BOSS_H, center = true, $fn = 32);
                            cylinder(d = SHAFT_DIA + 0.2, h = GT2_BOSS_H + 1,
                                     center = true, $fn = 24);
                        }
                    }
            }
        }
    }

    // Idlers — now printed monolithic with brackets (see _idler_bracket).
    // No separate visual needed for prototype.

    // Motor (visual only)
    _hi = MOTOR_HELIX_IDX;
    _hc = _helix_center(_hi);
    _sd = _shaft_dir(_hi);
    _sa = HELIX_ANGLES[_hi] + 90;
    _mxy_offset = _GT2_OFFSET_FROM_HELIX + GT2_BOSS_H/2 + MOTOR_GAP + MOTOR_BODY_LEN/2;
    _mxy = [_hc[0] + _sd[0] * _mxy_offset, _hc[1] + _sd[1] * _mxy_offset];
    color(C_MOTOR)
    translate([_mxy[0], _mxy[1], HELIX_Z])
        rotate([0, 0, _sa]) rotate([0, 90, 0])
            cylinder(d = MOTOR_BODY_DIA, h = MOTOR_BODY_LEN, center = true, $fn = 24);
}


// =========================================================
// MATRIX TIER MODULES — REMOVED
// =========================================================
// V5.5: All matrix tier geometry moved to matrix_stack_v5_5.scad.
// The matrix is a separate print that slides into the frame.


// =========================================================
// BLOCK GRID
// =========================================================
function _tier_contribution(bx, by, tier_angle, t) =
    let(d_k = bx * sin(tier_angle) - by * cos(tier_angle),
        continuous_ch = d_k / STACK_OFFSET + _CENTER_CH,
        phase_k = continuous_ch * TWIST_PER_CAM)
    ECCENTRICITY * sin(t * 360 + phase_k);

function superposition_dz(bx, by, t) =
    _tier_contribution(bx, by, TIER_ANGLES[0], t) +
    _tier_contribution(bx, by, TIER_ANGLES[1], t) +
    _tier_contribution(bx, by, TIER_ANGLES[2], t);

module _block_grid(t = 0) {
    for (i = [0 : NUM_CHANNELS - 1]) {
        d = CH_OFFSETS[i]; clen = ch_len(d); raw = raw_col_count(clen);
        if (clen > 0) {
            for (j = [0 : max(0, raw - 1)]) {
                px = col_x(raw, j, i);
                if (col_inside_hex(px, d)) {
                    bx = px; by = -d;
                    dz = superposition_dz(bx, by, t);
                    translate([bx, by, dz])
                        color(C_BLOCK)
                            cube([COL_PITCH-_BLOCK_GAP, COL_PITCH-_BLOCK_GAP,
                                  _BLOCK_HEIGHT_CFG], center = true);
                }
            }
        }
    }
}


// =========================================================
// UTILITY: Beam between two 3D points (original — kept for stubs/simple)
// =========================================================
module _beam_between(p1, p2, w, h, chamfer = -1) {
    _c = (chamfer < 0) ? ARM_CHAMFER : chamfer;
    dx = p2[0]-p1[0]; dy = p2[1]-p1[1]; dz = p2[2]-p1[2];
    length = sqrt(dx*dx+dy*dy+dz*dz);
    az = atan2(dy, dx);
    horiz = sqrt(dx*dx+dy*dy);
    ay = -atan2(dz, horiz);

    if (length > 0.1)
    translate(p1)
        rotate([0,0,az]) rotate([0,ay,0]) {
            if (_c > 0 && w > 2*_c && h > 2*_c)
                hull()
                    for (yc = [-w/2+_c, w/2-_c])
                        for (zc = [-h/2+_c, h/2-_c])
                            translate([0, yc, zc])
                                rotate([0, 90, 0])
                                    cylinder(r = _c, h = length, $fn = 8);
            else
                translate([0, -w/2, -h/2])
                    cube([length, w, h]);
        }
}


// =========================================================
// UTILITY: Tapered beam — V5.6 sculptural upgrade
// =========================================================
// Cross-section graduates from (w1,h1) at p1 to (w2,h2) at p2.
// Chamfer graduates from c1 to c2 along length.
// Built from `segments` hull slices for smooth taper.
module _beam_tapered(p1, p2, w1, h1, w2, h2, c1=1, c2=1, segments=12) {
    dx = p2[0]-p1[0]; dy = p2[1]-p1[1]; dz = p2[2]-p1[2];
    length = sqrt(dx*dx+dy*dy+dz*dz);
    az = atan2(dy, dx);
    horiz = sqrt(dx*dx+dy*dy);
    ay = -atan2(dz, horiz);

    if (length > 0.1)
    translate(p1)
        rotate([0,0,az]) rotate([0,ay,0])
            for (i = [0 : segments - 1]) {
                t0 = i / segments;
                t1 = (i + 1) / segments;
                x0 = t0 * length;
                x1 = t1 * length;
                _w0 = w1 + (w2 - w1) * t0;
                _h0 = h1 + (h2 - h1) * t0;
                _w1 = w1 + (w2 - w1) * t1;
                _h1 = h1 + (h2 - h1) * t1;
                _c0 = c1 + (c2 - c1) * t0;
                _c1 = c1 + (c2 - c1) * t1;
                hull() {
                    // Start slice
                    translate([x0, 0, 0])
                    if (_c0 > 0.2 && _w0 > 2*_c0 && _h0 > 2*_c0)
                        for (yc = [-_w0/2+_c0, _w0/2-_c0])
                            for (zc = [-_h0/2+_c0, _h0/2-_c0])
                                translate([0, yc, zc])
                                    sphere(r = _c0, $fn = 8);
                    else
                        cube([0.01, max(0.5, _w0), max(0.5, _h0)], center = true);
                    // End slice
                    translate([x1, 0, 0])
                    if (_c1 > 0.2 && _w1 > 2*_c1 && _h1 > 2*_c1)
                        for (yc = [-_w1/2+_c1, _w1/2-_c1])
                            for (zc = [-_h1/2+_c1, _h1/2-_c1])
                                translate([0, yc, zc])
                                    sphere(r = _c1, $fn = 8);
                    else
                        cube([0.01, max(0.5, _w1), max(0.5, _h1)], center = true);
                }
            }
}


// =========================================================
// UTILITY: Curved beam — catenary/parabolic sag between points
// =========================================================
module _beam_curved(p1, p2, w, h, sag, segments=8, chamfer=1) {
    for (i = [0 : segments - 1]) {
        t0 = i / segments;
        t1 = (i + 1) / segments;
        // Parabolic sag: max at midspan (t=0.5), zero at ends
        sag0 = sag * 4 * t0 * (1 - t0);
        sag1 = sag * 4 * t1 * (1 - t1);
        pt0 = [p1[0]+(p2[0]-p1[0])*t0,
               p1[1]+(p2[1]-p1[1])*t0,
               p1[2]+(p2[2]-p1[2])*t0 - sag0];
        pt1 = [p1[0]+(p2[0]-p1[0])*t1,
               p1[1]+(p2[1]-p1[1])*t1,
               p1[2]+(p2[2]-p1[2])*t1 - sag1];
        _beam_between(pt0, pt1, w, h, chamfer);
    }
}
