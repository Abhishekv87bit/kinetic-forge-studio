// =========================================================
// DRIVE BELT V5.6 — 2-Belt + Direct Drive Architecture
// =========================================================
// Motor directly drives H3's camshaft (shaft-coupled, no belt).
// Two independent GT2 belt segments distribute power:
//
//   Belt A: H3 far-end GT2 → I1(0°) → H2 GT2
//           (motor torque passes through H3's shaft, powers H2)
//
//   Belt B: Motor-side GT2 on H3 → I2(120°) → H1 GT2
//           (motor GT2 pulley on H3 shaft, powers H1)
//
// Only 2 idlers needed (I1 at stub 0°, I2 at stub 120°).
// Stub 240° has no idler.
//
// Components rendered:
//   - GT2 pulleys (gold) — H1, H2, + 2x on H3 shaft (far & motor side)
//   - Smooth idlers (red) — I1 and I2
//   - Motor body (blue) — direct-coupled to H3
//   - Belt A (brown) — H3-far → I1 → H2
//   - Belt B (brown) — H3-motor-side GT2 → I2 → H1
//   - Idler brackets (grey) — I1 and I2
//   - Motor bracket (grey)
//
// This file is STANDALONE — include config, replicate
// frame geometry functions needed for placement.
// =========================================================

include <config_v5_5.scad>

$fn = 24;

// =============================================
// FRAME GEOMETRY — replicated from monolith
// (monolith is frozen; these are the canonical formulas)
// =============================================

/* [Frame Rings] */
_DB_FRAME_RING_H      = 6;
_DB_FRAME_RING_W      = 5;
_DB_FRAME_RING_R_IN   = HEX_R + 2;                         // 45mm
_DB_FRAME_RING_R_OUT  = _DB_FRAME_RING_R_IN + _DB_FRAME_RING_W;  // 50mm

/* [Stubs] */
_DB_STUB_ANGLES       = [0, 120, 240];
_DB_STUB_W            = 10;
_DB_STUB_LENGTH       = 15;
_DB_STUB_INWARD       = 4;
_DB_STUB_R_END        = _DB_FRAME_RING_R_OUT + _DB_STUB_LENGTH;
_DB_JUNCTION_R        = _DB_STUB_R_END + _DB_STUB_W / 2;

/* [Hexagram Derived] */
_DB_STAR_TIP_R        = _STAR_RATIO * HEX_LONGEST_DIA;
_DB_HEXAGRAM_INNER_R  = _DB_STAR_TIP_R / sqrt(3);
_DB_CORRIDOR_GAP      = _CORRIDOR_GAP_CFG;

/* [V_ANGLE] */
function _db_par_res(V, T, J) =
    T*T*sin(120-V) - 2*J*T*sin(120-V/2) + J*J*sin(120);
function _db_find_V(T, J, lo=10, hi=150, d=0) =
    d > 50 ? (lo+hi)/2 :
    let(mid=(lo+hi)/2, r=_db_par_res(mid,T,J))
    abs(r) < 0.0001 ? mid :
    r > 0 ? _db_find_V(T,J,mid,hi,d+1) : _db_find_V(T,J,lo,mid,d+1);
_DB_V_ANGLE           = _db_find_V(_DB_STAR_TIP_R, _DB_JUNCTION_R);

_DB_V_PUSH            = _DB_CORRIDOR_GAP / (2 * tan(30));
_DB_HELIX_R           = _DB_HEXAGRAM_INNER_R + _DB_V_PUSH;

/* [Carrier Nodes] */
_DB_CARRIER_PLATE_T   = CARRIER_PLATE_T_CFG;

// =============================================
// HELIX GEOMETRY FUNCTIONS
// =============================================
_DB_HELIX_Z           = 0;

function _db_shaft_dir(hi) =
    let(a = HELIX_ANGLES[hi]) [-sin(a), cos(a)];
function _db_helix_center(hi) =
    let(a = HELIX_ANGLES[hi]) [_DB_HELIX_R * cos(a), _DB_HELIX_R * sin(a)];
function _db_shaft_angle(hi) = HELIX_ANGLES[hi] + 90;

// =============================================
// DRIVE CHAIN GEOMETRY
// =============================================
// GT2 pulley offset along shaft from helix center
_DB_GT2_OFFSET = HELIX_LENGTH/2 + SHAFT_EXT_TO_CARRIER
                 + _DB_CARRIER_PLATE_T/2 + GT2_BOSS_H/2;

// GT2 pulley world XY (sign: +1 = along shaft_dir, -1 = opposite)
function _db_gt2_xy(hi, sign=1) =
    let(hc = _db_helix_center(hi), sd = _db_shaft_dir(hi))
    [hc[0] + sd[0] * sign * _DB_GT2_OFFSET,
     hc[1] + sd[1] * sign * _DB_GT2_OFFSET];

// Idler offset from junction center (radially outward from stub)
_DB_IDLER_OFFSET_R = _DB_STUB_W/2 + IDLER_OD/2 + 2;

function _db_idler_xy(si) =
    let(a = _DB_STUB_ANGLES[si])
    [(_DB_JUNCTION_R + _DB_IDLER_OFFSET_R) * cos(a),
     (_DB_JUNCTION_R + _DB_IDLER_OFFSET_R) * sin(a)];

// Motor position — direct-coupled to H3, on shaft extension
_DB_MOTOR_HI = MOTOR_HELIX_IDX;   // 2 → Helix 3 at 60°
_DB_MOTOR_OFFSET = _DB_GT2_OFFSET + GT2_BOSS_H/2 + MOTOR_GAP + MOTOR_BODY_LEN/2;
_DB_MOTOR_XY = let(hc = _db_helix_center(_DB_MOTOR_HI),
                   sd = _db_shaft_dir(_DB_MOTOR_HI))
    [hc[0] + sd[0] * _DB_MOTOR_OFFSET,
     hc[1] + sd[1] * _DB_MOTOR_OFFSET];

// =============================================
// GT2 PULLEY POSITIONS — 2-belt architecture
// =============================================
// H3 has GT2 pulleys on BOTH ends of its shaft:
//   Motor side (+1): drives Belt B → I2 → H2
//   Far side   (-1): drives Belt A → I1 → H1
//
// H1 and H2 each have ONE GT2 (receiving end).
// Sign chosen so the GT2 faces the idler it connects to.
//
//   H3 motor-side (sign=+1): toward stub 120° → connects via I2 to H2
//   H3 far-side   (sign=-1): toward stub 0°   → connects via I1 to H1
//   H1 (hi=0, 180°, sign=-1): GT2 toward 0° stub → faces I1
//   H2 (hi=1, 300°, sign=+1): GT2 toward 120° stub → faces I2
//
_DB_H3_GT2_FAR   = _db_gt2_xy(2, -1);   // H3 far end (Belt A)
_DB_H3_GT2_MOTOR = _db_gt2_xy(2, +1);   // H3 motor side (Belt B)
_DB_H1_GT2       = _db_gt2_xy(0, -1);   // H1 receiving pulley
_DB_H2_GT2       = _db_gt2_xy(1, +1);   // H2 receiving pulley

_DB_I1 = _db_idler_xy(0);   // Stub 0 (0°) — Belt A
_DB_I2 = _db_idler_xy(1);   // Stub 1 (120°) — Belt B

// =============================================
// BELT PATH DEFINITIONS — two independent segments
// =============================================
// Belt A: H3-far → I1 → H2  (far end of H3 shaft powers Helix 2)
_DB_BELT_A = [_DB_H3_GT2_FAR, _DB_I1, _DB_H2_GT2];
_DB_BELT_A_RADII = [GT2_OD/2, IDLER_OD/2, GT2_OD/2];

// Belt B: H3-motor → I2 → H1  (motor side of H3 shaft powers Helix 1)
_DB_BELT_B = [_DB_H3_GT2_MOTOR, _DB_I2, _DB_H1_GT2];
_DB_BELT_B_RADII = [GT2_OD/2, IDLER_OD/2, GT2_OD/2];

// Bracket dimensions
_DB_BRACKET_ARM_W    = 4;
_DB_BRACKET_EXTRA_H  = 3;
_DB_MOTOR_BRACKET_T  = 3;
_DB_MOTOR_BRACKET_CLR = 6;

// =============================================
// DISPLAY TOGGLES
// =============================================
SHOW_GT2_PULLEYS   = true;
SHOW_IDLERS        = true;
SHOW_MOTOR         = true;
SHOW_BELT_A        = true;
SHOW_BELT_B        = true;
SHOW_BRACKETS      = true;
SHOW_HEX_GHOST     = true;
SHOW_LABELS        = true;
_LABEL_Z           = 15;     // height above Z=0 for label text
_LABEL_SIZE        = 8;      // font size

// =============================================
// VERIFICATION ECHOES
// =============================================
echo(str("=== DRIVE BELT V5.6 (2-belt + direct drive) ==="));
echo(str("GT2: teeth=", GT2_TEETH, " PD=", round(GT2_PD*100)/100,
         "mm OD=", round(GT2_OD*100)/100, "mm boss_h=", GT2_BOSS_H, "mm"));
echo(str("GT2 offset from helix center = ", round(_DB_GT2_OFFSET*10)/10, "mm"));
echo(str("HELIX_R = ", round(_DB_HELIX_R*10)/10, "mm"));
echo(str("JUNCTION_R = ", round(_DB_JUNCTION_R*10)/10, "mm"));
echo(str("Motor DIRECT to H3 (hi=", _DB_MOTOR_HI, ", ", HELIX_ANGLES[_DB_MOTOR_HI], "deg)"));

// Belt A nodes
echo(str("Belt A: H3-far[",
    round(_DB_H3_GT2_FAR[0]*10)/10, ",", round(_DB_H3_GT2_FAR[1]*10)/10,
    "] → I1[",
    round(_DB_I1[0]*10)/10, ",", round(_DB_I1[1]*10)/10,
    "] → H2[",
    round(_DB_H2_GT2[0]*10)/10, ",", round(_DB_H2_GT2[1]*10)/10, "]"));

// Belt B nodes
echo(str("Belt B: H3-mtr[",
    round(_DB_H3_GT2_MOTOR[0]*10)/10, ",", round(_DB_H3_GT2_MOTOR[1]*10)/10,
    "] → I2[",
    round(_DB_I2[0]*10)/10, ",", round(_DB_I2[1]*10)/10,
    "] → H1[",
    round(_DB_H1_GT2[0]*10)/10, ",", round(_DB_H1_GT2[1]*10)/10, "]"));

// Belt lengths (center-to-center, each segment is open: 3 nodes = 2 spans)
function _seg_len(p1, p2) =
    let(dx = p2[0]-p1[0], dy = p2[1]-p1[1]) sqrt(dx*dx + dy*dy);

_DB_BELT_A_LEN = _seg_len(_DB_BELT_A[0], _DB_BELT_A[1])
               + _seg_len(_DB_BELT_A[1], _DB_BELT_A[2]);
_DB_BELT_B_LEN = _seg_len(_DB_BELT_B[0], _DB_BELT_B[1])
               + _seg_len(_DB_BELT_B[1], _DB_BELT_B[2]);

echo(str("Belt A length (c-c) ≈ ", round(_DB_BELT_A_LEN*10)/10, "mm"));
echo(str("Belt B length (c-c) ≈ ", round(_DB_BELT_B_LEN*10)/10, "mm"));

// =============================================
// STANDALONE RENDER
// =============================================
drive_belt_assembly();


// =========================================================
// DRIVE BELT ASSEMBLY
// =========================================================
module drive_belt_assembly() {
    // Reference hex (ghost)
    if (SHOW_HEX_GHOST)
        color(C_HEX_GHOST)
            linear_extrude(1, center = true)
                circle(r = HEX_R, $fn = 6);

    // GT2 pulleys
    if (SHOW_GT2_PULLEYS)
        _render_gt2_pulleys();

    // Idlers (I1 and I2 only)
    if (SHOW_IDLERS)
        _render_idlers();

    // Motor (direct-coupled to H3)
    if (SHOW_MOTOR)
        _render_motor();

    // Belt A: H3-far → I1 → H2
    if (SHOW_BELT_A)
        _render_belt_segment(_DB_BELT_A, _DB_BELT_A_RADII, C_BELT);

    // Belt B: H3-motor → I2 → H1
    if (SHOW_BELT_B)
        _render_belt_segment(_DB_BELT_B, _DB_BELT_B_RADII,
            [0.6, 0.3, 0.15, 0.85]);  // slightly different brown for distinction

    // Brackets
    if (SHOW_BRACKETS) {
        _render_idler_brackets();
        _render_motor_bracket();
    }

    // Labels
    if (SHOW_LABELS)
        _render_labels();
}


// =========================================================
// GT2 PULLEYS — 4 total (2 on H3, 1 each on H1 & H2)
// =========================================================
module _render_gt2_pulleys() {
    // H3 far-end GT2 (Belt A source)
    _render_one_gt2(_DB_H3_GT2_FAR, _db_shaft_angle(2));
    // H3 motor-side GT2 (Belt B source)
    _render_one_gt2(_DB_H3_GT2_MOTOR, _db_shaft_angle(2));
    // H1 GT2 (Belt A destination)
    _render_one_gt2(_DB_H1_GT2, _db_shaft_angle(0));
    // H2 GT2 (Belt B destination)
    _render_one_gt2(_DB_H2_GT2, _db_shaft_angle(1));
}

module _render_one_gt2(pos, shaft_a) {
    color([0.9, 0.75, 0.0, 0.9])
    translate([pos[0], pos[1], _DB_HELIX_Z])
        rotate([0, 0, shaft_a]) rotate([0, 90, 0])
            difference() {
                cylinder(d = GT2_OD, h = GT2_BOSS_H, center = true, $fn = 32);
                cylinder(d = SHAFT_BORE, h = GT2_BOSS_H + 1, center = true, $fn = 24);
            }
}


// =========================================================
// IDLERS — STL big-pulley + bolt + c-clamp + parametric fork
// Parts from: Pulley/no-3-pulleys-and-right-angle-guides-507-mechanical-movements-model_files
// =========================================================
_STL_BASE = "D:/Claude local/3d_design_agent/Pulley/no-3-pulleys-and-right-angle-guides-507-mechanical-movements-model_files";

// STL part dimensions (measured from binary STL)
_PULLEY_STL_OD   = 20;
_PULLEY_STL_H    = 20;    // Z extent in native orientation
_BOLT_STL_HEAD_D = 8.5;
_BOLT_STL_SHAFT_D = 4.5;
_BOLT_STL_LEN    = 32.5;
_CLAMP_STL_T     = 2;

// Parametric fork dimensions
_FORK_WALL       = 3;
_FORK_CLEARANCE  = 0.5;
_FORK_GAP        = _PULLEY_STL_H + 2 * _FORK_CLEARANCE;  // 21mm
_FORK_ARM_UP     = _PULLEY_STL_OD/2 + 3;   // 13mm above bolt center
_FORK_ARM_DOWN   = _PULLEY_STL_OD/2 + 2;   // 12mm below bolt center
_FORK_ARM_W      = 12;
_FORK_BOLT_D     = _BOLT_STL_SHAFT_D + 0.4;
_FORK_BASE_T     = 4;
_FORK_SPAN       = _FORK_GAP + 2 * _FORK_WALL;  // 27mm

// Single idler fork body (parametric clevis)
// Origin = bolt center. Bolt axis along Z. Base toward -Y.
module _idler_fork() {
    color(C_BRACKET)
    difference() {
        union() {
            // Left arm plate (negative Z)
            translate([0, (_FORK_ARM_UP - _FORK_ARM_DOWN)/2,
                       -_FORK_GAP/2 - _FORK_WALL/2])
                cube([_FORK_ARM_W, _FORK_ARM_UP + _FORK_ARM_DOWN,
                      _FORK_WALL], center=true);
            // Right arm plate (positive Z)
            translate([0, (_FORK_ARM_UP - _FORK_ARM_DOWN)/2,
                       _FORK_GAP/2 + _FORK_WALL/2])
                cube([_FORK_ARM_W, _FORK_ARM_UP + _FORK_ARM_DOWN,
                      _FORK_WALL], center=true);
            // Base tab connecting arms
            translate([0, -_FORK_ARM_DOWN + _FORK_BASE_T/2, 0])
                cube([_FORK_ARM_W, _FORK_BASE_T, _FORK_SPAN], center=true);
        }
        // Bolt clearance hole
        cylinder(d=_FORK_BOLT_D, h=_FORK_SPAN + 2, center=true);
    }
}

// Full idler assembly: fork + STL pulley + STL bolt + STL c-clamps
// Origin = bolt/pulley center. Bolt axis = Z. Fork base toward -Y.
module _idler_assembly() {
    // Fork
    _idler_fork();

    // Big pulley (gold) — STL native Z=[0,20] → center on origin
    color(C_IDLER)
    translate([0, 0, -_PULLEY_STL_H/2])
        import(str(_STL_BASE, "/big-pulley_x1.stl"));

    // Bolt (dark grey) — STL native Z=[0,32.5] → center on origin
    color(C_BOLT)
    translate([0, 0, -_BOLT_STL_LEN/2])
        import(str(_STL_BASE, "/bolt_x1.stl"));

    // C-clamps (green) — outside each fork arm
    color([0.2, 0.7, 0.3, 0.9]) {
        translate([0, 0, _FORK_GAP/2 + _FORK_WALL + 0.5])
            import(str(_STL_BASE, "/c-clamp_x2.stl"));
        translate([0, 0, -_FORK_GAP/2 - _FORK_WALL - 0.5 - _CLAMP_STL_T])
            import(str(_STL_BASE, "/c-clamp_x2.stl"));
    }
}

module _render_idlers() {
    for (si = [0, 1]) {   // only stubs 0 and 1
        _pos = _db_idler_xy(si);
        _stub_a = _DB_STUB_ANGLES[si];
        // Junction center (where fork base mounts)
        _jx = _DB_JUNCTION_R * cos(_stub_a);
        _jy = _DB_JUNCTION_R * sin(_stub_a);
        // Angle from idler toward junction (fork base faces this way)
        _toward_junc = atan2(_jy - _pos[1], _jx - _pos[0]);

        translate([_pos[0], _pos[1], _DB_HELIX_Z])
            rotate([0, 0, _toward_junc])  // base faces junction
                _idler_assembly();
    }
}


// =========================================================
// MOTOR — direct-coupled to H3 shaft (no belt to motor)
// =========================================================
module _render_motor() {
    _sa = _db_shaft_angle(_DB_MOTOR_HI);

    // Motor body
    color(C_MOTOR)
    translate([_DB_MOTOR_XY[0], _DB_MOTOR_XY[1], _DB_HELIX_Z])
        rotate([0, 0, _sa]) rotate([0, 90, 0])
            cylinder(d = MOTOR_BODY_DIA, h = MOTOR_BODY_LEN, center = true, $fn = 24);

    // Coupling indicator (small cylinder between motor and H3 GT2)
    _hc = _db_helix_center(_DB_MOTOR_HI);
    _sd = _db_shaft_dir(_DB_MOTOR_HI);
    _coupling_start = _DB_GT2_OFFSET + GT2_BOSS_H/2;
    _coupling_end   = _coupling_start + MOTOR_GAP;
    _mid_offset     = (_coupling_start + _coupling_end) / 2;
    _coupling_len   = MOTOR_GAP;
    _cx = _hc[0] + _sd[0] * _mid_offset;
    _cy = _hc[1] + _sd[1] * _mid_offset;

    color([0.4, 0.4, 0.4, 0.8])
    translate([_cx, _cy, _DB_HELIX_Z])
        rotate([0, 0, _sa]) rotate([0, 90, 0])
            cylinder(d = SHAFT_DIA, h = _coupling_len + 2, center = true, $fn = 16);
}


// =========================================================
// BELT SEGMENT — open path (not a closed loop)
// hull'd spheres between consecutive nodes
// =========================================================
module _render_belt_segment(nodes, radii, belt_color) {
    _n = len(nodes);

    color(belt_color) {
        // Straight spans between consecutive nodes
        for (i = [0 : _n - 2]) {
            _p1 = nodes[i];
            _p2 = nodes[i + 1];
            hull() {
                translate([_p1[0], _p1[1], _DB_HELIX_Z])
                    sphere(d = DRIVE_BELT_DIA, $fn = 8);
                translate([_p2[0], _p2[1], _DB_HELIX_Z])
                    sphere(d = DRIVE_BELT_DIA, $fn = 8);
            }
        }

        // Wrap arcs around middle nodes (idlers)
        // End nodes (GT2) don't need wrap — belt terminates there
        for (i = [1 : _n - 2]) {
            _center = nodes[i];
            _r = radii[i];
            _prev = nodes[i - 1];
            _next = nodes[i + 1];

            _dx_in  = _prev[0] - _center[0];
            _dy_in  = _prev[1] - _center[1];
            _dx_out = _next[0] - _center[0];
            _dy_out = _next[1] - _center[1];

            _a_in  = atan2(_dy_in, _dx_in);
            _a_out = atan2(_dy_out, _dx_out);

            // Belt wraps the LONG way around the idler
            _raw_sweep = _a_out - _a_in;
            _sweep = (_raw_sweep > 180) ? _raw_sweep - 360 :
                     (_raw_sweep < -180) ? _raw_sweep + 360 : _raw_sweep;
            _wrap = (_sweep > 0) ? _sweep - 360 : _sweep + 360;

            _arc_segs = 8;
            for (s = [0 : _arc_segs - 1]) {
                _f1 = s / _arc_segs;
                _f2 = (s + 1) / _arc_segs;
                _ang1 = _a_in + _wrap * _f1;
                _ang2 = _a_in + _wrap * _f2;
                hull() {
                    translate([_center[0] + _r * cos(_ang1),
                               _center[1] + _r * sin(_ang1),
                               _DB_HELIX_Z])
                        sphere(d = DRIVE_BELT_DIA, $fn = 8);
                    translate([_center[0] + _r * cos(_ang2),
                               _center[1] + _r * sin(_ang2),
                               _DB_HELIX_Z])
                        sphere(d = DRIVE_BELT_DIA, $fn = 8);
                }
            }
        }
    }
}


// =========================================================
// IDLER BRACKETS — arm from junction to fork base
// (Fork is part of _idler_assembly, this adds the mounting arm)
// =========================================================
module _render_idler_brackets() {
    for (si = [0, 1]) {
        _pos = _db_idler_xy(si);
        _stub_a = _DB_STUB_ANGLES[si];
        _jx = _DB_JUNCTION_R * cos(_stub_a);
        _jy = _DB_JUNCTION_R * sin(_stub_a);

        // Arm from junction to idler fork base
        color(C_BRACKET)
        hull() {
            translate([_jx, _jy, _DB_HELIX_Z])
                cube([_DB_BRACKET_ARM_W, _DB_BRACKET_ARM_W,
                      _FORK_SPAN], center = true);
            translate([_pos[0], _pos[1], _DB_HELIX_Z])
                cube([_DB_BRACKET_ARM_W, _DB_BRACKET_ARM_W,
                      _FORK_SPAN], center = true);
        }
    }
}


// =========================================================
// MOTOR BRACKET
// =========================================================
module _render_motor_bracket() {
    _sa = _db_shaft_angle(_DB_MOTOR_HI);

    color(C_BRACKET)
    translate([_DB_MOTOR_XY[0], _DB_MOTOR_XY[1], _DB_HELIX_Z])
        rotate([0, 0, _sa])
            cube([_DB_MOTOR_BRACKET_T,
                  MOTOR_BODY_DIA + _DB_MOTOR_BRACKET_CLR,
                  MOTOR_BODY_DIA + _DB_MOTOR_BRACKET_CLR], center = true);
}


// =========================================================
// LABELS — floating text above each component
// =========================================================
module _label(pos, txt, col = [0, 0, 0, 1]) {
    color(col)
    translate([pos[0], pos[1], _LABEL_Z])
        linear_extrude(1)
            text(txt, size = _LABEL_SIZE, halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
}

module _render_labels() {
    // Helix centers (for reference)
    _hc0 = _db_helix_center(0);
    _hc1 = _db_helix_center(1);
    _hc2 = _db_helix_center(2);

    // Helix labels at helix centers
    _label(_hc0, "HELIX 1 (180°)", [0.3, 0.3, 0.8]);
    _label(_hc1, "HELIX 2 (300°)", [0.3, 0.3, 0.8]);
    _label(_hc2, "HELIX 3 (60°)",  [0.3, 0.3, 0.8]);

    // GT2 pulley labels (offset slightly above pulley)
    _label(_DB_H1_GT2,       "H1 GT2",     [0.7, 0.6, 0.0]);
    _label(_DB_H2_GT2,       "H2 GT2",     [0.7, 0.6, 0.0]);
    _label(_DB_H3_GT2_FAR,   "H3 GT2 far", [0.7, 0.6, 0.0]);
    _label(_DB_H3_GT2_MOTOR, "H3 GT2 mtr", [0.7, 0.6, 0.0]);

    // Idler labels
    _label(_DB_I1, "I1 (0°)",   [0.8, 0.2, 0.2]);
    _label(_DB_I2, "I2 (120°)", [0.8, 0.2, 0.2]);

    // Motor label
    _label(_DB_MOTOR_XY, "MOTOR (M)", [0.2, 0.5, 0.9]);

    // Stub 240° — no idler
    _no_idler_pos = _db_idler_xy(2);
    _label(_no_idler_pos, "(no idler)", [0.5, 0.5, 0.5]);
}
