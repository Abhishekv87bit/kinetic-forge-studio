// =========================================================
// FRAME V5.6 — Frame + Drive System (Original Routing)
// =========================================================
// Drive architecture:
//   - N20 motor direct-coupled to H3 camshaft via 3mm→4mm coupler
//   - Belt A: H3 far-end GT2 → I1 (stub 0) → H2 GT2
//   - Belt B: H3 motor-side GT2 → I2 (stub 1) → H1 GT2
//   - 2 idler pulleys at stubs 0° and 120°
//   - Motor mounted at H3 corridor (helix index 2, 60°)
// =========================================================

include <config_v5_5.scad>
use <monolith_v5_5.scad>

$fn = 24;

// =============================================
// STL IDLER ASSEMBLY — imported parts + parametric base
// =============================================
_STL_BASE = "D:/Claude local/3d_design_agent/Pulley/no-3-pulleys-and-right-angle-guides-507-mechanical-movements-model_files";

// STL part dimensions (measured from binary STL)
_PULLEY_STL_OD    = 20;
_PULLEY_STL_H     = 20;
_BOLT_STL_SHAFT_D = 4.5;
_BOLT_STL_LEN     = 32.5;
_CLAMP_STL_T      = 2;

// Parametric fork dimensions (kept for reference)
_FORK_WALL        = 3;
_FORK_BOLT_D      = _BOLT_STL_SHAFT_D + 0.4;

// Frame geometry — derived from config
_FRAME_RING_W_56  = 5;
_FRAME_RING_R_IN_56  = HEX_R + 2;
_FRAME_RING_R_OUT_56 = _FRAME_RING_R_IN_56 + _FRAME_RING_W_56;
_STUB_LENGTH_56   = 15;
_STUB_W_56        = 10;
_STUB_R_END_56    = _FRAME_RING_R_OUT_56 + _STUB_LENGTH_56;
_JUNCTION_R_56    = _STUB_R_END_56 + _STUB_W_56 / 2;
_IDLER_OFFSET_R_56 = _STUB_W_56/2 + IDLER_OD/2 + 2;
_BRACKET_ARM_W_56 = 4;
_STUB_ANGLES_56   = [0, 120, 240];

// Idler base dimensions
_BASE_W           = 12;
_BASE_D           = 8;
_BASE_T           = _FORK_WALL;
_PULLEY_CLEARANCE = 1.0;
_BOLT_EMBED       = 2;

// =============================================
// IDLER BASE + ASSEMBLY (pedestal mount, bolt axis = +Z)
// =============================================
module _idler_base() {
    color(C_BRACKET)
    difference() {
        translate([0, 0, -_BASE_T/2])
            cube([_BASE_W, _BASE_D, _BASE_T], center=true);
        cylinder(d=_FORK_BOLT_D, h=_BASE_T + 2, center=true);
    }
}

module _idler_assembly_56() {
    _idler_base();

    color(C_BOLT)
    translate([0, 0, -_BOLT_EMBED])
        import(str(_STL_BASE, "/bolt_x1.stl"));

    color(C_IDLER)
    translate([0, 0, _PULLEY_CLEARANCE])
        import(str(_STL_BASE, "/big-pulley_x1.stl"));

    color([0.2, 0.7, 0.3, 0.9])
    translate([0, 0, _PULLEY_CLEARANCE + _PULLEY_STL_H + 0.5])
        import(str(_STL_BASE, "/c-clamp_x2.stl"));
}

// =============================================
// N20 MOTOR + COUPLER ASSEMBLY — at H3 helix corridor
// =============================================
// N20 motor: 12mm W x 10mm D x 24mm L, 3mm D-shaft, ~9mm shaft
// Coupler: 3mm→4mm rigid, ~15mm long, ~10mm OD
// Motor axis = horizontal (along H3 shaft direction)
// Origin = coupler-to-camshaft junction (where camshaft begins)
// =============================================
_N20_W            = 12;
_N20_D            = 10;
_N20_L            = 24;
_N20_SHAFT_DIA    = 3;      // standard N20 output shaft
_N20_SHAFT_LEN    = 9;      // standard shaft length

// Coupler: joins 3mm motor shaft to 4mm camshaft
_COUPLER_LEN      = 15;
_COUPLER_OD       = 10;
_COUPLER_BORE_M   = _N20_SHAFT_DIA + 0.1;  // motor side bore
_COUPLER_BORE_C   = SHAFT_DIA + 0.1;       // camshaft side bore (4mm)

// Motor clamp
_N20_CLAMP_T      = 2;
_N20_CLAMP_CLR    = 0.3;

// Motor assembly: motor → shaft → coupler → [camshaft starts at origin]
// Axis along +X (local). Origin = where camshaft begins.
module _n20_motor_with_coupler() {
    // Coupler — centered on axis, from X=0 back toward motor
    color([0.7, 0.7, 0.2, 0.9])
    rotate([0, 90, 0])
    translate([0, 0, -_COUPLER_LEN])
        difference() {
            cylinder(d=_COUPLER_OD, h=_COUPLER_LEN, $fn=24);
            // Motor bore (left half)
            translate([0, 0, -0.5])
                cylinder(d=_COUPLER_BORE_M, h=_COUPLER_LEN/2 + 0.5, $fn=16);
            // Camshaft bore (right half)
            translate([0, 0, _COUPLER_LEN/2])
                cylinder(d=_COUPLER_BORE_C, h=_COUPLER_LEN/2 + 0.5, $fn=16);
        }

    // Motor shaft stub — from coupler back to motor face
    _shaft_start_x = -_COUPLER_LEN;
    _motor_gap = 1;  // gap between coupler and motor face
    color([0.5, 0.5, 0.5])
    rotate([0, 90, 0])
    translate([0, 0, _shaft_start_x - _motor_gap - _N20_SHAFT_LEN])
        cylinder(d=_N20_SHAFT_DIA, h=_N20_SHAFT_LEN, $fn=12);

    // Motor body
    _motor_face_x = _shaft_start_x - _motor_gap - _N20_SHAFT_LEN;
    _motor_center_x = _motor_face_x - _N20_L/2;
    color(C_MOTOR)
    translate([_motor_center_x, 0, 0])
        cube([_N20_L, _N20_W, _N20_D], center=true);

    // Motor clamp ring
    _clamp_w = _N20_L;  // along axis
    _clamp_h = _N20_W + 2 * (_N20_CLAMP_T + _N20_CLAMP_CLR);
    _clamp_d = _N20_D + 2 * (_N20_CLAMP_T + _N20_CLAMP_CLR);
    color(C_BRACKET)
    translate([_motor_center_x, 0, 0])
        difference() {
            cube([10, _clamp_h, _clamp_d], center=true);  // 10mm wide band
            cube([11, _N20_W + 2*_N20_CLAMP_CLR,
                      _N20_D + 2*_N20_CLAMP_CLR], center=true);
        }

    // Wiring leads (visual)
    color([1, 0, 0, 0.7])
    translate([_motor_center_x - _N20_L/2 - 1, -2, 0])
        rotate([0, -90, 0]) cylinder(d=0.8, h=6, $fn=8);
    color([0, 0, 0, 0.7])
    translate([_motor_center_x - _N20_L/2 - 1, 2, 0])
        rotate([0, -90, 0]) cylinder(d=0.8, h=6, $fn=8);
}

// =============================================
// IDLER BRACKETS — 2 idlers at stubs 0° and 120°
// =============================================
_IDLER_SCALE = 0.7;
_IDLER_Z_OFFSET = 0;

module _idler_brackets_v56() {
    for (si = [0, 1]) {
        _stub_a = _STUB_ANGLES_56[si];
        _pos_r  = _JUNCTION_R_56 + _IDLER_OFFSET_R_56;
        _px     = _pos_r * cos(_stub_a);
        _py     = _pos_r * sin(_stub_a);
        _jx     = _JUNCTION_R_56 * cos(_stub_a);
        _jy     = _JUNCTION_R_56 * sin(_stub_a);
        _toward_junc = atan2(_jy - _py, _jx - _px);

        // Bracket arm
        color(C_BRACKET)
        hull() {
            translate([_jx, _jy, _IDLER_Z_OFFSET])
                cube([_BRACKET_ARM_W_56, _BRACKET_ARM_W_56,
                      _BASE_D * _IDLER_SCALE], center=true);
            translate([_px, _py, _IDLER_Z_OFFSET])
                cube([_BRACKET_ARM_W_56, _BRACKET_ARM_W_56,
                      _BASE_D * _IDLER_SCALE], center=true);
        }

        // STL idler assembly
        translate([_px, _py, _IDLER_Z_OFFSET])
            rotate([0, 0, _toward_junc])
                scale([_IDLER_SCALE, _IDLER_SCALE, _IDLER_SCALE])
                    _idler_assembly_56();
    }
}

// =============================================
// MOTOR PLACEMENT — N20 at H3 corridor (helix index 2, 60°)
// =============================================
// Helix geometry — use config values for consistency
_HELIX_ANGLES_56  = [180, 300, 60];
_HELIX_R_56       = _CFG_HELIX_R;  // from config (uses _STAR_RATIO=2.5, _CORRIDOR_GAP_CFG=31.4)

function _helix_center_56(hi) =
    [_HELIX_R_56 * cos(_HELIX_ANGLES_56[hi]),
     _HELIX_R_56 * sin(_HELIX_ANGLES_56[hi])];

function _shaft_dir_56(hi) =
    let(a = _HELIX_ANGLES_56[hi] + 90)
    [cos(a), sin(a)];

module _motor_at_h3() {
    _hi = MOTOR_HELIX_IDX;  // 2 → helix at 60°
    _hc = _helix_center_56(_hi);
    _sd = _shaft_dir_56(_hi);
    _sa = _HELIX_ANGLES_56[_hi] + 90;  // shaft direction angle

    // Motor coupler origin = shaft tip (beyond carrier + GT2)
    // Shaft layout from helix center outward along shaft direction:
    //   HELIX_LENGTH/2 → SHAFT_EXT_TO_CARRIER → carrier plate → GT2 → shaft end
    _shaft_end_offset = HELIX_LENGTH/2 + SHAFT_EXT_TO_CARRIER
                      + CARRIER_PLATE_T_CFG/2 + GT2_BOSS_H + 12;  // 12mm clearance past GT2 (clears carrier fork)
    _motor_attach_x = _hc[0] + _sd[0] * _shaft_end_offset;
    _motor_attach_y = _hc[1] + _sd[1] * _shaft_end_offset;

    // Place motor assembly, axis along shaft direction
    // _n20_motor_with_coupler() has coupler+motor extending along -X (local)
    // We need motor body to extend OUTWARD (away from frame center)
    // So rotate 180° from shaft angle to flip motor outward
    translate([_motor_attach_x, _motor_attach_y, 0])
        rotate([0, 0, _sa + 180])
            _n20_motor_with_coupler();

    // Bracket arm from nearest junction to motor position
    // H3 at 60° sits between stubs 0° and 120°
    // Motor-side extends toward ~150° — nearest junction is stub 1 (120°)
    _jx = _JUNCTION_R_56 * cos(120);
    _jy = _JUNCTION_R_56 * sin(120);
    color(C_BRACKET)
    hull() {
        translate([_jx, _jy, 0])
            cube([_BRACKET_ARM_W_56, _BRACKET_ARM_W_56, 6], center=true);
        translate([_motor_attach_x, _motor_attach_y, 0])
            cube([_BRACKET_ARM_W_56, _BRACKET_ARM_W_56, 6], center=true);
    }
}

// =========================================================
// FRAME V5.6 ASSEMBLY
// =========================================================

// --- HEX RINGS ---
_hex_ring_ledge_top();
_hex_ring_ledge_bot();

// --- THREE UNIFIED CORRIDORS ---
for (si = [0 : 2])
    _render_corridor(si);

// --- FRAME POSTS ---
_all_frame_posts();

// --- IDLER BRACKETS (2x STL pulley at stubs 0° and 120°) ---
_idler_brackets_v56();

// --- MOTOR (N20 + coupler at H3 corridor) ---
_motor_at_h3();
