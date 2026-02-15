// =========================================================
// HEX FRAME V5.3 -- Hexagram Star Frame + Integrated Cams
// =========================================================
// V5.3 PROTOTYPE: 8mm shaft, 688ZZ frame bearings, face-pin cams.
//
// V5.3 CHANGES FROM V5.2:
//   - 8mm shaft + 688ZZ bearings (same 16mm OD as 625ZZ → bore unchanged)
//   - E-clip-only shaft retention (no printed boss — simplest option)
//   - E-clip grooves on shaft inboard of each carrier (see helix_cam_v5_3)
//   - Dampener V-grooves: string separator combs on dampener bars
//   - Block gap reduced to 0.8mm (was COL_PITCH-2 ≈ 10mm)
//   - Arm linkages match main arm proportions (BRACE_W=ARM_W, BRACE_H=ARM_H)
//   - Carrier plates = structural arm nodes (arms widen around bearing bore)
//
// FRAME ARCHITECTURE:
//   Central hex matrix (ghost placeholder) at origin.
//   Hex ring sleeve: upper (ledge-top) + lower (ledge-bot)
//   3 STUBS at [0, 120, 240]
//   6 HEXAGRAM ARMS -- PARALLEL corridor pairs
//   3 HELIX CORRIDORS -- carrier bridge plates with 688ZZ bearings
//   Helix cam assemblies mounted at corridor centers
//   Dampener bars with V-groove combs across corridors
//   Eiffel-tower splayed legs at stub vertices
//   Block grid below matrix
// =========================================================

include <config_v5_3.scad>
use <helix_cam_v5_3.scad>

$fn = 24;

// =============================================
// FRAME PARAMETERS
// =============================================

/* [Frame Rings] */
FRAME_RING_H      = 12;
FRAME_RING_W      = 10;
FRAME_RING_R_IN   = HEX_R + 2;                          // 91mm
FRAME_RING_R_OUT  = FRAME_RING_R_IN + FRAME_RING_W;     // 101mm

// Z positions: sleeve sandwich
UPPER_RING_Z      = TIER1_TOP;                           // +31.5
LOWER_RING_Z      = TIER3_BOT - FRAME_RING_H;           // -43.5
UPPER_RING_CENTER_Z = UPPER_RING_Z + FRAME_RING_H / 2;  // +37.5
LOWER_RING_CENTER_Z = LOWER_RING_Z + FRAME_RING_H / 2;  // -37.5
TIER_GAP_Z        = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z;  // 75mm

/* [Inward Ledge] */
LEDGE_WIDTH       = 6;
LEDGE_THICK       = 3;
LEDGE_R_IN        = FRAME_RING_R_IN - LEDGE_WIDTH;      // 85mm

/* [Hexagram Star -- 6 main frame arms] */
ARM_W             = 20;
ARM_H             = 14;

/* [Stubs] */
STUB_ANGLES       = [0, 120, 240];
STUB_LENGTH       = 30;
STUB_INWARD       = 8;
STUB_W            = 20;
STUB_H            = ARM_H;
STUB_R_START      = FRAME_RING_R_OUT - STUB_INWARD;     // 93mm
STUB_R_END        = FRAME_RING_R_OUT + STUB_LENGTH;     // 131mm
JUNCTION_R        = STUB_R_END + STUB_W / 2;            // 141mm
GUSSET_THICK      = 3;
ARM_CHAMFER       = 2;
STAR_TIP_R        = _STAR_RATIO * HEX_LONGEST_DIA;
HEXAGRAM_INNER_R  = STAR_TIP_R / sqrt(3);
CORRIDOR_GAP      = _CORRIDOR_GAP_CFG;

/* [V_ANGLE -- auto-computed for corridor arm parallelism] */
// Two arms from different stubs meet at each helix corridor.
// For the cam shaft to thread straight through both carrier plates,
// these arms must be parallel. Solved from:
//   T^2*sin(120-V) - 2JT*sin(120-V/2) + J^2*sin(120) = 0
// where T=STAR_TIP_R, J=JUNCTION_R.
function _par_residual(V, T, J) =
    T*T*sin(120-V) - 2*J*T*sin(120-V/2) + J*J*sin(120);

function _find_parallel_V(T, J, lo=10, hi=150, depth=0) =
    depth > 50 ? (lo+hi)/2 :
    let(mid = (lo+hi)/2,
        r = _par_residual(mid, T, J))
    abs(r) < 0.0001 ? mid :
    r > 0 ? _find_parallel_V(T, J, mid, hi, depth+1) :
             _find_parallel_V(T, J, lo, mid, depth+1);

V_ANGLE           = _find_parallel_V(STAR_TIP_R, JUNCTION_R);

// Helix radial position
_V_PUSH           = CORRIDOR_GAP / (2 * tan(30));       // 56.3mm
HELIX_R           = HEXAGRAM_INNER_R + _V_PUSH;         // 313.2mm

/* [Arm Convergence] */
CONVERGE_PCT      = 60;
_MID_Z            = (UPPER_RING_CENTER_Z + LOWER_RING_CENTER_Z) / 2;
ARM_TIP_Z_UPPER   = UPPER_RING_CENTER_Z + ((_MID_Z - UPPER_RING_CENTER_Z) * CONVERGE_PCT / 100);
ARM_TIP_Z_LOWER   = LOWER_RING_CENTER_Z + ((_MID_Z - LOWER_RING_CENTER_Z) * CONVERGE_PCT / 100);

// =============================================
// HELIX POSITION & SHAFT CROSSING GEOMETRY
// =============================================
HELIX_Z_LIST      = [0, 0, 0];
HELIX_Z           = 0;

// Tier Z mapping for dampeners
DAMPENER_TIER_Z   = [TIER_PITCH, 0, -TIER_PITCH];

// Arm definitions: [stub_angle, tip_angle]
_HALF_V = V_ANGLE / 2;
ARM_DEFS = [
    [0,   0 - _HALF_V],       // A0
    [0,   0 + _HALF_V],       // A1
    [120, 120 - _HALF_V],     // A2
    [120, 120 + _HALF_V],     // A3
    [240, 240 - _HALF_V],     // A4
    [240, 240 + _HALF_V],     // A5
];

// Arm-to-helix mapping
HELIX_ARM_PAIRS = [[3, 4], [5, 0], [1, 2]];
ARM_HELIX       = [1, 2, 2, 0, 0, 1];

// Shaft direction for each helix: perpendicular to radial arm in XY
function _shaft_dir(hi) =
    let(a = HELIX_ANGLES[hi])
    [-sin(a), cos(a)];

function _helix_center(hi) =
    let(a = HELIX_ANGLES[hi])
    [HELIX_R * cos(a), HELIX_R * sin(a)];

function _shaft_angle(hi) = HELIX_ANGLES[hi] + 90;

// =============================================
// ARM GEOMETRY FUNCTIONS
// =============================================
function _junction_xy(arm_idx) =
    let(stub_angle = ARM_DEFS[arm_idx][0])
    [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];

function _star_tip_xy(arm_idx) =
    let(tip_angle = ARM_DEFS[arm_idx][1])
    [STAR_TIP_R * cos(tip_angle), STAR_TIP_R * sin(tip_angle)];

// Arm direction (unit vector from junction to star tip)
function _arm_dir(arm_idx) =
    let(jxy = _junction_xy(arm_idx),
        txy = _star_tip_xy(arm_idx),
        dx = txy[0] - jxy[0],
        dy = txy[1] - jxy[1],
        len = sqrt(dx*dx + dy*dy))
    [dx/len, dy/len];

// Arm length from junction to star tip
function _arm_full_len(arm_idx) =
    let(jxy = _junction_xy(arm_idx),
        txy = _star_tip_xy(arm_idx),
        dx = txy[0] - jxy[0],
        dy = txy[1] - jxy[1])
    sqrt(dx*dx + dy*dy);

// =============================================
// SHAFT CROSSING -- FIXED (now returns 0-1 fraction)
// =============================================
// Where shaft axis line crosses a given arm centerline.
// Returns fraction f (0=junction, 1=star_tip).
//
// BUG FIX: _arm_dir() returns a unit vector, so the raw
// line intersection gives parameter t in mm. Divide by
// _arm_full_len() to get 0-1 fraction.

function _shaft_crossing_frac(arm_idx, hi) =
    let(hc = _helix_center(hi),
        sd = _shaft_dir(hi),
        jxy = _junction_xy(arm_idx),
        ad = _arm_dir(arm_idx),
        // Cross product (2D): ad x sd
        cross = ad[0] * sd[1] - ad[1] * sd[0],
        // Vector from junction to helix center
        djx = hc[0] - jxy[0],
        djy = hc[1] - jxy[1],
        // Raw t in mm (because ad is unit vector)
        t_mm = (djx * sd[1] - djy * sd[0]) / cross,
        // Convert to 0-1 fraction
        flen = _arm_full_len(arm_idx))
    abs(cross) < 0.001 ? 0.5 :  // parallel fallback
    t_mm / flen;

// XY position where shaft crosses arm
function _shaft_crossing_xy(arm_idx, hi) =
    let(jxy = _junction_xy(arm_idx),
        ad = _arm_dir(arm_idx),
        f = _shaft_crossing_frac(arm_idx, hi),
        len = _arm_full_len(arm_idx))
    [jxy[0] + ad[0] * f * len,
     jxy[1] + ad[1] * f * len];

// Radial distance of shaft crossing point from origin
function _shaft_crossing_R(arm_idx, hi) =
    let(xy = _shaft_crossing_xy(arm_idx, hi))
    sqrt(xy[0]*xy[0] + xy[1]*xy[1]);

// Z of upper/lower beam at a given fraction along arm
function _beam_z_at_frac(frac, is_upper) =
    is_upper ?
        UPPER_RING_CENTER_Z + (ARM_TIP_Z_UPPER - UPPER_RING_CENTER_Z) * frac :
        LOWER_RING_CENTER_Z + (ARM_TIP_Z_LOWER - LOWER_RING_CENTER_Z) * frac;

// =============================================
// CARRIER NODE DIMENSIONS (V5.3)
// =============================================
// The carrier is NOT a separate piece — it's a structural node where
// two arms from a corridor pair widen and merge around the bearing bore.
// Arms extend past the bearing by CARRIER_OVERSHOOT, forming bracket tabs.
// This is standard practice: clevis/yoke bracket integral with the arm.
CARRIER_PLATE_T   = CARRIER_PLATE_T_CFG;              // 20mm (from config)
CARRIER_BRG_BORE  = FRAME_BRG_OD + 0.05;             // 16.05mm press-fit (688ZZ)
CARRIER_WALL      = 4;
CARRIER_NODE_BULGE = 4;                               // extra width at bearing zone
CARRIER_OVERSHOOT  = 15;                              // arm extends past bearing center

_CARRIER_CLEARANCE = CARRIER_PLATE_T / 2 + CARRIER_OVERSHOOT;  // total past crossing

// Compute ARM_END_R from shaft crossing (using H1 corridor / A3 as reference)
_REF_CROSSING_FRAC = _shaft_crossing_frac(3, 0);
_REF_CROSSING_R = _shaft_crossing_R(3, 0);
ARM_END_R = _REF_CROSSING_R + _CARRIER_CLEARANCE;

// Fraction along arm where ARM_END_R falls
function _arm_end_frac(arm_idx) =
    let(jxy = _junction_xy(arm_idx),
        ad = _arm_dir(arm_idx),
        full_len = _arm_full_len(arm_idx),
        hi = ARM_HELIX[arm_idx],
        cross_frac = _shaft_crossing_frac(arm_idx, hi),
        cross_len = cross_frac * full_len,
        end_len = cross_len + _CARRIER_CLEARANCE)
    min(1.0, end_len / full_len);

// =============================================
// TOPOLOGY-OPTIMIZED EIFFEL TOWER LEGS
// =============================================
// Generative-design-inspired legs: parabolic curves tapering
// upward, triangulated space-frame lattice, perimeter tension
// ring at base. 3 leg assemblies × 2 struts = 6 feet.
// Designed for torsion + vibration resistance (kinetic sculpture).
//
// Aesthetic: brushed aluminum / carbon fiber look
// OpenSCAD approximation -- final version in Fusion 360 generative.

LEG_HEIGHT        = 300;                  // 300mm elevation per design brief
LEG_STRUT_W_BASE  = 25;                  // strut width at foot (wide)
LEG_STRUT_W_TOP   = 12;                  // strut width at hub (tapered)
LEG_STRUT_H       = round(ARM_H * 1.5);  // 1.5× arm thickness = 21mm
LEG_SPLAY_ANGLE   = 20;                  // degrees outward from vertical
LEG_SPREAD_ANGLE  = 30;                  // degrees ±from stub radial

// Parabolic curve: at fraction f (0=top, 1=bottom),
// horizontal offset = LEG_HEIGHT * f^1.5 * tan(splay)
// This gives the Eiffel-tower curve (steep near top, flaring at base)

// Lattice parameters
LEG_LATTICE_LEVELS = 5;                  // number of lattice cross-brace levels
LEG_LATTICE_STRUT_D = 4;                 // lattice diagonal strut diameter
LEG_CROSS_BRACE_W = 6;                   // cross brace beam width
LEG_CROSS_BRACE_H = 5;                   // cross brace beam height

// Foot pads
LEG_FOOT_PAD_DIA  = 35;                  // hex foot pad
LEG_FOOT_PAD_H    = 4;

// Tension ring at base
TENSION_RING_H    = 8;                   // ring height
TENSION_RING_W    = 10;                  // ring wall thickness
// Tension ring radius = computed from foot positions (see module)

// Mounting hub at top
LEG_HUB_DIA       = STUB_W + 8;         // hub merges into stub junction
LEG_HUB_H         = 15;                  // transition zone height

/* [Block Grid] */
BLOCK_DROP        = _BLOCK_DROP;
BLOCK_Z           = GP2_BOT - BLOCK_DROP;

// =============================================
// COLORS
// =============================================
C_FRAME    = [0.15, 0.15, 0.18, 0.9];
C_STUB     = [0.7, 0.15, 0.15, 0.9];
C_ARMS_COL = [
    [0.9, 0.2, 0.2, 0.9],
    [0.2, 0.7, 0.2, 0.9],
    [0.2, 0.4, 0.9, 0.9],
    [0.9, 0.9, 0.1, 0.9],
    [0.9, 0.4, 0.9, 0.9],
    [0.1, 0.9, 0.9, 0.9],
];
C_LINKAGE  = [0.5, 0.2, 0.6, 0.85];
C_MOUNT    = [0.85, 0.55, 0.1, 1.0];
C_MARKER   = [1.0, 0.0, 1.0, 0.8];
C_LEG      = [0.6, 0.62, 0.65, 0.92];  // brushed aluminum aesthetic
C_CARRIER  = [0.85, 0.6, 0.2, 1.0];

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
SHOW_CARRIER_PLATES = true;
SHOW_HELIX_MOUNTS   = true;
SHOW_DAMPENERS      = true;
SHOW_BLOCKS         = true;
SHOW_LEGS           = true;
SHOW_MARKERS        = false;

/* [Debug] */
EXPLODE             = 0;

// =============================================
// STANDALONE RENDER
// =============================================
hex_frame_v5(anim_t());


// =========================================================
// HEX FRAME V5.3 ASSEMBLY
// =========================================================
module hex_frame_v5(t = 0) {

    // ---- PLACEHOLDER MATRIX (ghost hex) ----
    if (SHOW_MATRIX)
        color(C_HEX_GHOST)
            translate([0, 0, TIER3_BOT])
                linear_extrude(height = TIER1_TOP - TIER3_BOT)
                    circle(r = HEX_R, $fn = 6);

    if (SHOW_UPPER_RING) _hex_ring_ledge_top();
    if (SHOW_LOWER_RING) _hex_ring_ledge_bot();
    if (SHOW_STUBS) _all_stubs();
    if (SHOW_STUB_LINKS) _all_stub_linkages();
    if (SHOW_ARMS) { _all_junction_nodes(); _all_frame_arms(); }
    if (SHOW_ARM_LINKS) _all_arm_linkages();
    if (SHOW_CARRIER_PLATES) _all_carrier_plates();
    if (SHOW_HELIX_MOUNTS) _all_helix_mounts(t);
    if (SHOW_DAMPENERS) _dampener_array();
    if (SHOW_BLOCKS) translate([0, 0, BLOCK_Z]) _block_grid(t);
    if (SHOW_LEGS) _all_legs();
    if (SHOW_MARKERS) _all_markers();

    // ---- ECHOES ----
    echo(str("=== HEX FRAME V5.3 -- 8mm SHAFT + FACE-PIN + SOLID WALLS ==="));
    echo(str("V_ANGLE=", round(V_ANGLE*100)/100, " (auto-computed for parallelism)"));
    echo(str("Star tip R=", round(STAR_TIP_R*10)/10, "mm"));
    echo(str("ARM_END_R=", round(ARM_END_R*10)/10, "mm (past HELIX_R=", round(HELIX_R*10)/10, "mm)"));
    echo(str("Shaft crossing R=", round(_REF_CROSSING_R*10)/10, "mm at frac=", round(_REF_CROSSING_FRAC*1000)/1000));
    echo(str("Corridor gap=", CORRIDOR_GAP, "mm"));
    echo(str("Leg: ", LEG_STRUT_W_BASE, "→", LEG_STRUT_W_TOP, "x", LEG_STRUT_H,
             "mm parabolic, splay=", LEG_SPLAY_ANGLE, "deg, H=", LEG_HEIGHT, "mm"));

    // Beam Z at shaft crossing
    _cross_z_up = _beam_z_at_frac(_REF_CROSSING_FRAC, true);
    _cross_z_lo = _beam_z_at_frac(_REF_CROSSING_FRAC, false);
    echo(str("Beam Z at crossing: upper=", round(_cross_z_up*10)/10,
             " lower=", round(_cross_z_lo*10)/10,
             " gap=", round((_cross_z_up - _cross_z_lo)*10)/10, "mm"));
}


// =========================================================
// UPPER HEX RING -- ledge on TOP face
// =========================================================
module _hex_ring_ledge_top() {
    color(C_FRAME) {
        translate([0, 0, UPPER_RING_Z])
            linear_extrude(height = FRAME_RING_H)
                difference() {
                    circle(r = FRAME_RING_R_OUT, $fn = 6);
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                }
        translate([0, 0, UPPER_RING_Z + FRAME_RING_H - LEDGE_THICK])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// LOWER HEX RING -- ledge on BOTTOM face
// =========================================================
module _hex_ring_ledge_bot() {
    color(C_FRAME) {
        translate([0, 0, LOWER_RING_Z])
            linear_extrude(height = FRAME_RING_H)
                difference() {
                    circle(r = FRAME_RING_R_OUT, $fn = 6);
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                }
        translate([0, 0, LOWER_RING_Z])
            linear_extrude(height = LEDGE_THICK)
                difference() {
                    circle(r = FRAME_RING_R_IN, $fn = 6);
                    circle(r = LEDGE_R_IN, $fn = 6);
                }
    }
}


// =========================================================
// ALL STUBS -- 3 radial beams at [0, 120, 240]
// =========================================================
module _all_stubs() {
    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        sx = STUB_R_START * cos(a);
        sy = STUB_R_START * sin(a);
        ex = STUB_R_END * cos(a);
        ey = STUB_R_END * sin(a);

        color(C_STUB) {
            _beam_between(
                [sx, sy, UPPER_RING_CENTER_Z],
                [ex, ey, UPPER_RING_CENTER_Z],
                STUB_W, STUB_H);
            _beam_between(
                [sx, sy, LOWER_RING_CENTER_Z],
                [ex, ey, LOWER_RING_CENTER_Z],
                STUB_W, STUB_H);
        }
    }
}


// =========================================================
// STUB LINKAGE POSTS -- vertical ties at junction
// =========================================================
module _all_stub_linkages() {
    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        px = JUNCTION_R * cos(a);
        py = JUNCTION_R * sin(a);
        _post_h = UPPER_RING_CENTER_Z - LOWER_RING_CENTER_Z;

        color(C_STUB)
        translate([px, py, LOWER_RING_CENTER_Z - STUB_H/2])
            cylinder(d = STUB_W, h = _post_h + STUB_H, $fn = 6);
    }
}


// =========================================================
// ALL FRAME ARMS -- extend to ARM_END_R (past shaft crossing)
// =========================================================
module _all_frame_arms() {
    for (ai = [0 : 5]) {
        stub_angle = ARM_DEFS[ai][0];
        start_xy = [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];

        _ad = _arm_dir(ai);
        _flen = _arm_full_len(ai);
        _end_frac = _arm_end_frac(ai);
        _end_len = _end_frac * _flen;
        end_xy = [start_xy[0] + _ad[0] * _end_len,
                  start_xy[1] + _ad[1] * _end_len];

        // Z at end point (interpolated by convergence)
        _end_z_up = _beam_z_at_frac(_end_frac, true);
        _end_z_lo = _beam_z_at_frac(_end_frac, false);

        color(C_ARMS_COL[ai]) {
            // Upper beam
            _beam_between(
                [start_xy[0], start_xy[1], UPPER_RING_CENTER_Z],
                [end_xy[0], end_xy[1], _end_z_up],
                ARM_W, ARM_H);
            // Lower beam
            _beam_between(
                [start_xy[0], start_xy[1], LOWER_RING_CENTER_Z],
                [end_xy[0], end_xy[1], _end_z_lo],
                ARM_W, ARM_H);
        }
    }
}


// =========================================================
// JUNCTION NODES -- triangular pads at stub/arm split
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
// ARM LINKAGES -- cross-brace between arm pairs
// =========================================================
// V5.3: Linkage braces match main arm proportions for visual consistency
BRACE_W = ARM_W;  // 20mm (was 8mm in V5.2)
BRACE_H = ARM_H;  // 14mm (was 6mm in V5.2)

function _arm_pt(start_xy, end_xy, f, z_from, z_to) =
    [start_xy[0] + (end_xy[0] - start_xy[0]) * f,
     start_xy[1] + (end_xy[1] - start_xy[1]) * f,
     z_from + (z_to - z_from) * f];

module _all_arm_linkages() {
    _frac = 0.35;

    for (si = [0 : 2]) {
        stub_angle = STUB_ANGLES[si];
        _ai_a = si * 2;
        _ai_b = si * 2 + 1;

        start_xy = [JUNCTION_R * cos(stub_angle), JUNCTION_R * sin(stub_angle)];

        _ad_a = _arm_dir(_ai_a);
        _flen_a = _arm_full_len(_ai_a);
        _ef_a = _arm_end_frac(_ai_a);
        end_a = [start_xy[0] + _ad_a[0] * _ef_a * _flen_a,
                 start_xy[1] + _ad_a[1] * _ef_a * _flen_a];

        _ad_b = _arm_dir(_ai_b);
        _flen_b = _arm_full_len(_ai_b);
        _ef_b = _arm_end_frac(_ai_b);
        end_b = [start_xy[0] + _ad_b[0] * _ef_b * _flen_b,
                 start_xy[1] + _ad_b[1] * _ef_b * _flen_b];

        _end_z_up_a = _beam_z_at_frac(_ef_a, true);
        _end_z_lo_a = _beam_z_at_frac(_ef_a, false);
        _end_z_up_b = _beam_z_at_frac(_ef_b, true);
        _end_z_lo_b = _beam_z_at_frac(_ef_b, false);

        a_up = _arm_pt(start_xy, end_a, _frac, UPPER_RING_CENTER_Z, _end_z_up_a);
        a_lo = _arm_pt(start_xy, end_a, _frac, LOWER_RING_CENTER_Z, _end_z_lo_a);
        b_up = _arm_pt(start_xy, end_b, _frac, UPPER_RING_CENTER_Z, _end_z_up_b);
        b_lo = _arm_pt(start_xy, end_b, _frac, LOWER_RING_CENTER_Z, _end_z_lo_b);

        color(C_LINKAGE) {
            _beam_between(a_up, b_up, BRACE_W, BRACE_H);
            _beam_between(a_lo, b_lo, BRACE_W, BRACE_H);
        }
    }
}


// =========================================================
// ALL CARRIER NODES (V5.3) — Structural arm-integrated brackets
// =========================================================
// Industry best practice: the carrier is NOT a separate piece bolted
// between the arms. It IS the arms — a structural node where the
// upper and lower beams of each arm widen to encompass the bearing
// bore, then continue past as bracket tabs.
//
// Shape: The arm beams approach from the junction side (inboard).
// At the shaft crossing they hull() into a bearing ring (wider than
// the arm). The beams continue past the bearing by CARRIER_OVERSHOOT,
// forming outboard tabs that stiffen the node. The bearing press-fits
// into the bore. Shaft passes through a clearance hole. Two E-clips
// on the shaft (one per side) provide axial retention.
//
// Color: SAME as the parent arm pair — not a separate carrier color.
// This makes the node look like one continuous structural member.
//
// No boss, no flange — just bearing press-fit + E-clips.

// Node zone fraction: how far before/after crossing the widening starts
_NODE_BLEND_LEN = 30;  // mm: gradual taper into node (each side of crossing)

module _all_carrier_plates() {
    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        _hz = HELIX_Z;
        _sa = _shaft_angle(hi);

        for (side = [0, 1]) {
            _ai = _pair[side];
            _cross_frac = _shaft_crossing_frac(_ai, hi);
            _cross_xy = _shaft_crossing_xy(_ai, hi);
            _flen = _arm_full_len(_ai);
            _ad = _arm_dir(_ai);
            _jxy = _junction_xy(_ai);
            _end_frac = _arm_end_frac(_ai);

            _z_up = _beam_z_at_frac(_cross_frac, true);
            _z_lo = _beam_z_at_frac(_cross_frac, false);

            // Node zone fractions along arm
            _blend_frac = _NODE_BLEND_LEN / _flen;
            _node_start_frac = max(0, _cross_frac - _blend_frac);
            _node_end_frac = min(_end_frac, _cross_frac + _blend_frac);

            // Points along arm at node boundaries
            _ns_len = _node_start_frac * _flen;
            _ne_len = _node_end_frac * _flen;
            _ns_xy = [_jxy[0] + _ad[0] * _ns_len, _jxy[1] + _ad[1] * _ns_len];
            _ne_xy = [_jxy[0] + _ad[0] * _ne_len, _jxy[1] + _ad[1] * _ne_len];

            _ns_z_up = _beam_z_at_frac(_node_start_frac, true);
            _ns_z_lo = _beam_z_at_frac(_node_start_frac, false);
            _ne_z_up = _beam_z_at_frac(_node_end_frac, true);
            _ne_z_lo = _beam_z_at_frac(_node_end_frac, false);

            // Node bearing ring diameter
            _node_ring_d = CARRIER_BRG_BORE + CARRIER_WALL * 2 + CARRIER_NODE_BULGE;

            // ---- Structural node body (arm-integrated) ----
            color(C_ARMS_COL[_ai])
            difference() {
                hull() {
                    // Inboard arm pad (where node starts blending from arm)
                    // Upper beam pad
                    translate([_ns_xy[0], _ns_xy[1], _ns_z_up])
                        rotate([0, 0, _sa])
                            rotate([0, 90, 0])
                                cylinder(d = ARM_H, h = CARRIER_PLATE_T, center = true, $fn = 16);
                    // Lower beam pad
                    translate([_ns_xy[0], _ns_xy[1], _ns_z_lo])
                        rotate([0, 0, _sa])
                            rotate([0, 90, 0])
                                cylinder(d = ARM_H, h = CARRIER_PLATE_T, center = true, $fn = 16);

                    // Bearing ring zone at shaft crossing (widest point)
                    translate([_cross_xy[0], _cross_xy[1], _hz])
                        rotate([0, 0, _sa])
                            rotate([0, 90, 0])
                                cylinder(d = _node_ring_d,
                                         h = CARRIER_PLATE_T, center = true, $fn = 32);

                    // Outboard arm tab (bracket extension past bearing)
                    // Upper beam pad
                    translate([_ne_xy[0], _ne_xy[1], _ne_z_up])
                        rotate([0, 0, _sa])
                            rotate([0, 90, 0])
                                cylinder(d = ARM_H, h = CARRIER_PLATE_T, center = true, $fn = 16);
                    // Lower beam pad
                    translate([_ne_xy[0], _ne_xy[1], _ne_z_lo])
                        rotate([0, 0, _sa])
                            rotate([0, 90, 0])
                                cylinder(d = ARM_H, h = CARRIER_PLATE_T, center = true, $fn = 16);
                }

                // 688ZZ bearing bore — through the node
                translate([_cross_xy[0], _cross_xy[1], _hz])
                    rotate([0, 0, _sa])
                        rotate([0, 90, 0])
                            cylinder(d = CARRIER_BRG_BORE, h = CARRIER_PLATE_T + 2,
                                     center = true, $fn = 32);

                // Shaft clearance bore — beyond bearing (both sides)
                translate([_cross_xy[0], _cross_xy[1], _hz])
                    rotate([0, 0, _sa])
                        rotate([0, 90, 0])
                            cylinder(d = SHAFT_DIA + 1, h = CARRIER_PLATE_T + 40,
                                     center = true, $fn = 24);
            }

            // 688ZZ bearing visualization
            color(C_BEARING)
            translate([_cross_xy[0], _cross_xy[1], _hz])
                rotate([0, 0, _sa])
                    rotate([0, 90, 0])
                        difference() {
                            cylinder(d = FRAME_BRG_OD, h = FRAME_BRG_W, center = true, $fn = 32);
                            cylinder(d = FRAME_BRG_ID, h = FRAME_BRG_W + 2, center = true, $fn = 32);
                        }

            echo(str("  Carrier A", _ai, " H", hi+1, ": R=",
                     round(sqrt(_cross_xy[0]*_cross_xy[0] + _cross_xy[1]*_cross_xy[1])*10)/10,
                     "mm frac=", round(_cross_frac*1000)/1000,
                     " node_d=", round(_node_ring_d*10)/10, "mm"));
        }
    }
}


// =========================================================
// ALL HELIX MOUNTS -- cam assembly placement
// =========================================================
module _all_helix_mounts(t) {
    for (hi = [0 : 2]) {
        _hc = _helix_center(hi);
        hx = _hc[0];
        hy = _hc[1];
        helix_a = HELIX_ANGLES[hi];
        _hz = HELIX_Z;

        // Cam assembly -- shaft along helix tangent direction
        // helix_cam_v5 builds along Z, we need shaft along tangent
        // Tangent = helix_angle + 90, shaft runs in that direction
        translate([hx, hy, _hz])
            rotate([0, 0, helix_a])
                rotate([-90, 0, 0])
                    translate([0, 0, -HELIX_LENGTH/2])
                        helix_assembly_v5(t);

        echo(str("  Helix ", hi+1, ": [", round(hx*10)/10, ",", round(hy*10)/10,
                 "] angle=", helix_a, "deg"));
    }
}


// =========================================================
// DAMPENER ARRAY -- bar pairs with V-groove combs (V5.3)
// =========================================================
// V5.3: Each dampener bar has V-groove notches at COL_PITCH
// spacing that act as string separators (comb). Prevents
// tangling between adjacent string channels.
DAMPENER_FRAC     = 0.50;
DAMP_BAR_DIA      = DAMPENER_BAR_OD;
DAMP_BAR_GAP      = 1.5;
DAMP_BAR_OFFSET   = (DAMP_BAR_DIA + DAMP_BAR_GAP) / 2;

// V-groove comb parameters (from config)
_GROOVE_DEPTH     = DAMPENER_GROOVE_DEPTH;    // 1.0mm
_GROOVE_ANGLE     = DAMPENER_GROOVE_ANGLE;    // 60 degrees

module _dampener_array() {
    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        _hz = DAMPENER_TIER_Z[hi];

        _start_a = [JUNCTION_R * cos(ARM_DEFS[_pair[0]][0]),
                    JUNCTION_R * sin(ARM_DEFS[_pair[0]][0])];
        _ad_a = _arm_dir(_pair[0]);
        _flen_a = _arm_full_len(_pair[0]);
        _ef_a = _arm_end_frac(_pair[0]);
        _end_a = [_start_a[0] + _ad_a[0] * _ef_a * _flen_a,
                  _start_a[1] + _ad_a[1] * _ef_a * _flen_a];

        _start_b = [JUNCTION_R * cos(ARM_DEFS[_pair[1]][0]),
                    JUNCTION_R * sin(ARM_DEFS[_pair[1]][0])];
        _ad_b = _arm_dir(_pair[1]);
        _flen_b = _arm_full_len(_pair[1]);
        _ef_b = _arm_end_frac(_pair[1]);
        _end_b = [_start_b[0] + _ad_b[0] * _ef_b * _flen_b,
                  _start_b[1] + _ad_b[1] * _ef_b * _flen_b];

        _end_z_up_a = _beam_z_at_frac(_ef_a, true);
        _end_z_lo_a = _beam_z_at_frac(_ef_a, false);
        _end_z_up_b = _beam_z_at_frac(_ef_b, true);
        _end_z_lo_b = _beam_z_at_frac(_ef_b, false);

        _pt_a_raw = _arm_pt(_start_a, _end_a, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _end_z_up_a);
        _pt_b_raw = _arm_pt(_start_b, _end_b, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _end_z_up_b);

        // Dampener bars with V-groove combs
        color(C_STUB) {
            _dampener_bar_with_grooves(
                [_pt_a_raw[0], _pt_a_raw[1], _hz + DAMP_BAR_OFFSET],
                [_pt_b_raw[0], _pt_b_raw[1], _hz + DAMP_BAR_OFFSET]);
            _dampener_bar_with_grooves(
                [_pt_a_raw[0], _pt_a_raw[1], _hz - DAMP_BAR_OFFSET],
                [_pt_b_raw[0], _pt_b_raw[1], _hz - DAMP_BAR_OFFSET]);
        }

        // Vertical tie posts at dampener attachment points
        _da_up = _arm_pt(_start_a, _end_a, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _end_z_up_a);
        _da_lo = _arm_pt(_start_a, _end_a, DAMPENER_FRAC, LOWER_RING_CENTER_Z, _end_z_lo_a);
        _db_up = _arm_pt(_start_b, _end_b, DAMPENER_FRAC, UPPER_RING_CENTER_Z, _end_z_up_b);
        _db_lo = _arm_pt(_start_b, _end_b, DAMPENER_FRAC, LOWER_RING_CENTER_Z, _end_z_lo_b);

        color(C_STUB) {
            translate([_pt_a_raw[0], _pt_a_raw[1], _da_lo[2] - STUB_H/2])
                cylinder(d = STUB_W, h = _da_up[2] - _da_lo[2] + STUB_H, $fn = 6);
            translate([_pt_b_raw[0], _pt_b_raw[1], _db_lo[2] - STUB_H/2])
                cylinder(d = STUB_W, h = _db_up[2] - _db_lo[2] + STUB_H, $fn = 6);
        }
    }
}

// V5.3: Dampener bar with V-groove string separator comb
// V-grooves at COL_PITCH spacing along bar length
module _dampener_bar_with_grooves(p1, p2) {
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];
    dz = p2[2] - p1[2];
    bar_len = sqrt(dx*dx + dy*dy + dz*dz);
    az = atan2(dy, dx);
    horiz = sqrt(dx*dx + dy*dy);
    ay = -atan2(dz, horiz);

    // Number of grooves that fit along bar
    _n_grooves = floor(bar_len / COL_PITCH);

    translate(p1)
        rotate([0, 0, az])
            rotate([0, ay, 0])
                difference() {
                    // Bar body (rectangular beam)
                    translate([0, -DAMP_BAR_DIA/2, -DAMP_BAR_DIA/2])
                        cube([bar_len, DAMP_BAR_DIA, DAMP_BAR_DIA]);

                    // V-groove notches at COL_PITCH spacing
                    _groove_w = 2 * _GROOVE_DEPTH * tan(_GROOVE_ANGLE / 2);
                    for (gi = [1 : _n_grooves - 1]) {
                        _gx = gi * COL_PITCH;
                        translate([_gx, 0, DAMP_BAR_DIA/2 - _GROOVE_DEPTH])
                            rotate([0, 0, 45])
                                cube([_groove_w, _groove_w, _GROOVE_DEPTH + 1],
                                     center = true);
                    }
                }
}


// =========================================================
// TOPOLOGY-OPTIMIZED EIFFEL TOWER LEGS
// =========================================================
// Generative-design-inspired: parabolic curved struts with
// space-frame lattice, perimeter tension ring, hex foot pads.
// 3 leg assemblies at stub vertices, each with 2 splayed struts
// connected by triangulated lattice web panels.
//
// Parabolic curve: offset = H * f^1.5 * tan(splay)
//   f=0 at top (hub), f=1 at bottom (foot)
//   Steep near top, flaring dramatically at base -- Eiffel profile

// Parabolic offset at fraction f along leg (0=top, 1=bottom)
function _leg_offset(f) = LEG_HEIGHT * pow(f, 1.5) * tan(LEG_SPLAY_ANGLE);

// Strut width at fraction f (tapers from base to top)
function _strut_w_at(f) = LEG_STRUT_W_TOP + (LEG_STRUT_W_BASE - LEG_STRUT_W_TOP) * f;

// Point on a strut at fraction f
// top_xy = [x,y] at hub, splay_angle = direction of splay
function _strut_pt(top_xy, splay_a, f, top_z) =
    let(h_off = _leg_offset(f))
    [top_xy[0] + h_off * cos(splay_a),
     top_xy[1] + h_off * sin(splay_a),
     top_z - f * LEG_HEIGHT];

module _all_legs() {
    _top_z = LOWER_RING_CENTER_Z - STUB_H/2;
    _bot_z = _top_z - LEG_HEIGHT;

    // Collect all foot positions for tension ring
    _foot_positions = [
        for (si = [0 : 2])
            let(a = STUB_ANGLES[si],
                tx = STUB_R_END * cos(a),
                ty = STUB_R_END * sin(a))
            for (side = [-1, 1])
                let(sa = a + side * LEG_SPREAD_ANGLE,
                    h_off = _leg_offset(1.0))
                [tx + h_off * cos(sa), ty + h_off * sin(sa)]
    ];

    // ---- PER-STUB LEG ASSEMBLY ----
    for (si = [0 : 2]) {
        a = STUB_ANGLES[si];
        _top_xy = [STUB_R_END * cos(a), STUB_R_END * sin(a)];

        _splay_a_L = a - LEG_SPREAD_ANGLE;
        _splay_a_R = a + LEG_SPREAD_ANGLE;

        // ---- PARABOLIC STRUTS (segmented for curve) ----
        _num_seg = 8;  // segments per strut
        for (side_a = [_splay_a_L, _splay_a_R]) {
            for (seg = [0 : _num_seg - 1]) {
                _f0 = seg / _num_seg;
                _f1 = (seg + 1) / _num_seg;
                _p0 = _strut_pt(_top_xy, side_a, _f0, _top_z);
                _p1 = _strut_pt(_top_xy, side_a, _f1, _top_z);
                _w0 = _strut_w_at(_f0);
                _w1 = _strut_w_at(_f1);
                // Average width for this segment
                _avg_w = (_w0 + _w1) / 2;

                color(C_LEG)
                    _beam_between(_p0, _p1, _avg_w, LEG_STRUT_H);
            }
        }

        // ---- SPACE-FRAME LATTICE between strut pair ----
        // Horizontal cross-braces + diagonal X-braces
        for (lev = [0 : LEG_LATTICE_LEVELS]) {
            _f = lev / LEG_LATTICE_LEVELS;
            _pL = _strut_pt(_top_xy, _splay_a_L, _f, _top_z);
            _pR = _strut_pt(_top_xy, _splay_a_R, _f, _top_z);

            // Horizontal cross-brace at this level
            color(C_LEG)
                _beam_between(_pL, _pR, LEG_CROSS_BRACE_W, LEG_CROSS_BRACE_H);

            // Diagonal X-brace to NEXT level (if not last)
            if (lev < LEG_LATTICE_LEVELS) {
                _f_next = (lev + 1) / LEG_LATTICE_LEVELS;
                _pL_next = _strut_pt(_top_xy, _splay_a_L, _f_next, _top_z);
                _pR_next = _strut_pt(_top_xy, _splay_a_R, _f_next, _top_z);

                // X-pattern: L→R_next and R→L_next
                color([0.4, 0.4, 0.45, 0.85])
                    _beam_between(_pL, _pR_next,
                                  LEG_LATTICE_STRUT_D, LEG_LATTICE_STRUT_D, 0);
                color([0.4, 0.4, 0.45, 0.85])
                    _beam_between(_pR, _pL_next,
                                  LEG_LATTICE_STRUT_D, LEG_LATTICE_STRUT_D, 0);
            }
        }

        // ---- MOUNTING HUB at top ----
        // Tapered cylinder merging strut tops into stub
        color(C_LEG)
        translate([_top_xy[0], _top_xy[1], _top_z - LEG_HUB_H])
            cylinder(d1 = LEG_HUB_DIA, d2 = STUB_W, h = LEG_HUB_H, $fn = 6);

        // ---- HEX FOOT PADS ----
        for (side_a = [_splay_a_L, _splay_a_R]) {
            _foot = _strut_pt(_top_xy, side_a, 1.0, _top_z);
            color([0.25, 0.25, 0.28, 1.0])
            translate([_foot[0], _foot[1], _foot[2] - LEG_FOOT_PAD_H])
                cylinder(d = LEG_FOOT_PAD_DIA, h = LEG_FOOT_PAD_H, $fn = 6);
        }
    }

    // ---- PERIMETER TENSION RING ----
    // Hex ring connecting all 6 feet to prevent splaying
    // Route: foot0→foot1→foot2→...→foot5→foot0
    color([0.5, 0.5, 0.55, 0.9])
    for (fi = [0 : 5]) {
        _fi_next = (fi + 1) % 6;
        _fp = _foot_positions[fi];
        _fn = _foot_positions[_fi_next];
        _ring_z = _bot_z - LEG_FOOT_PAD_H / 2;

        _beam_between(
            [_fp[0], _fp[1], _ring_z],
            [_fn[0], _fn[1], _ring_z],
            TENSION_RING_W, TENSION_RING_H);
    }
}


// =========================================================
// BLOCK GRID -- 3-helix superposition wave
// =========================================================
function _tier_contribution(bx, by, tier_angle, t) =
    let(
        d_k = bx * sin(tier_angle) - by * cos(tier_angle),
        continuous_ch = d_k / STACK_OFFSET + _CENTER_CH,
        phase_k = continuous_ch * TWIST_PER_CAM
    )
    ECCENTRICITY * sin(t * 360 + phase_k);

// Block displacement = SUM of all tier contributions (not averaged).
// Each tier's slider laterally deflects the string, shortening the
// vertical path. These length changes are additive.
// Max constructive = 3 × ECCENTRICITY ≈ ±43.5mm.
function superposition_dz(bx, by, t) =
    _tier_contribution(bx, by, TIER_ANGLES[0], t) +
    _tier_contribution(bx, by, TIER_ANGLES[1], t) +
    _tier_contribution(bx, by, TIER_ANGLES[2], t);

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

                    // V5.3: block size uses _BLOCK_GAP (0.8mm) for tight packing
                    translate([bx, by, dz])
                        color(C_BLOCK)
                            cube([COL_PITCH - _BLOCK_GAP, COL_PITCH - _BLOCK_GAP,
                                  _BLOCK_HEIGHT_CFG], center = true);
                }
            }
        }
    }
}


// =========================================================
// COORDINATE MARKERS (debug -- off by default)
// =========================================================
MARKER_SIZE = 5;

module _all_markers() {
    _marker([0, 0, 0], "ORIGIN", [1, 1, 1, 0.9]);

    for (si = [0 : 2]) {
        _a = STUB_ANGLES[si];
        _marker([STUB_R_END * cos(_a), STUB_R_END * sin(_a), 0],
                str("S", si), C_STUB);
    }

    for (hi = [0 : 2]) {
        _hc = _helix_center(hi);
        _marker([_hc[0], _hc[1], HELIX_Z], str("H", hi+1), [1, 0, 0, 0.9]);
    }

    for (hi = [0 : 2]) {
        _pair = HELIX_ARM_PAIRS[hi];
        for (side = [0, 1]) {
            _ai = _pair[side];
            _cxy = _shaft_crossing_xy(_ai, hi);
            _marker([_cxy[0], _cxy[1], HELIX_Z],
                    str("CP_A", _ai), C_CARRIER);
        }
    }
}

module _marker(pos, label, col = [1, 0, 1, 0.8]) {
    _s = MARKER_SIZE;
    color(col)
        translate(pos)
            sphere(r = _s, $fn = 12);

    color([1, 1, 1, 0.9])
    translate([pos[0], pos[1], pos[2] + _s + 3])
        linear_extrude(1)
            text(label, size = 6, halign = "center", valign = "center");

    echo(str("  MARKER ", label, ": R=",
             round(sqrt(pos[0]*pos[0] + pos[1]*pos[1])*10)/10, "mm"));
}


// =========================================================
// UTILITY: Beam between two 3D points (chamfered rectangular)
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

    if (length > 0.1)
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
