// ============================================================
// RAVIGNEAUX V13 — 100% PARAMETRIC (Zero STL Dependencies)
// ============================================================
//
// FEATURES:
//   - ALL 13 component types fully parametric (no STL imports)
//   - Hand-rolled involute gear profiles (no BOSL2 dependency)
//   - Internal ring gear via boolean subtraction
//   - Planet self-rotation animation
//   - Animation: 3 independent input shafts, computed ring output
//   - Sealed ring enclosure (top lid + bottom lid + bearing seats)
//   - V-groove on ring OD for rope
//   - Stage 2 drive system (horizontal shafts + helical pinions)
//
// KINEMATIC CHAIN:
//   Input 1 (SL large sun)   ──┐
//   Input 2 (Ss small sun)   ──┤── planets ──→ Ring = OUTPUT
//   Input 3 (Carrier)         ──┘                  │
//                                              V-groove → rope → hanging element
// ============================================================

$fn = 64;

// ============================================================
// GEAR SPECS
// ============================================================
NORM_MOD   = 0.866;                          // normal module (mm)
HELIX_ANG  = 30;                             // helix angle (deg, right-hand)
TRANS_MOD  = NORM_MOD / cos(HELIX_ANG);      // transverse module = 1.0mm
PRESS_ANG  = 20;                             // pressure angle (deg)
DYN_CLEAR  = 0.25;                           // dynamic clearance (mm)

// Tooth counts
T_SS   = 31;    // small sun
T_SL   = 38;    // large sun
T_PI   = 24;    // short pinion (meshes Ss + Po)
T_PO   = 25;    // long pinion (meshes SL + Ring)
T_RING = 88;    // ring gear (internal)

// Ravigneaux constraint verification
// assert(T_SL + 2 * T_PO == T_RING);  // 38 + 50 = 88 ✓

// Derived pitch radii (transverse)
PR_RING = T_RING * TRANS_MOD / 2;    // 44.0mm
PR_SL   = T_SL * TRANS_MOD / 2;      // 19.0mm
PR_SS   = T_SS * TRANS_MOD / 2;      // 15.5mm
PR_PO   = T_PO * TRANS_MOD / 2;      // 12.5mm
PR_PI   = T_PI * TRANS_MOD / 2;      // 12.0mm

// Center distances (from tooth counts)
CD_SL_PO = PR_SL + PR_PO;            // 31.5mm = Po orbit radius
CD_SS_PI = PR_SS + PR_PI;            // 27.5mm ≈ Pi orbit radius

// ============================================================
// ANIMATION CONTROLS
// ============================================================
DRIVE_SL_DEG      = 360;    // Input 1: Large sun — deg per cycle
DRIVE_SS_DEG      = 0;      // Input 2: Small sun — deg per cycle
DRIVE_CARRIER_DEG = 0;      // Input 3: Carrier — deg per cycle

// Manual position sliders [0:1:360]
MANUAL_SL      = 0;
MANUAL_SS      = 0;
MANUAL_CARRIER = 0;

// Compute current angles = animation + manual
ANG_SL      = DRIVE_SL_DEG * $t + MANUAL_SL;
ANG_SS      = DRIVE_SS_DEG * $t + MANUAL_SS;
ANG_CARRIER = DRIVE_CARRIER_DEG * $t + MANUAL_CARRIER;

// Ring output (Willis equation, SL drive path)
ANG_RING = -(T_SL / T_RING) * (ANG_SL - ANG_CARRIER) + ANG_CARRIER;

// Planet self-rotation on pin axis
ANG_PO_SELF = -(T_SL / T_PO) * (ANG_SL - ANG_CARRIER);
ANG_PI_SELF = -(T_SS / T_PI) * (ANG_SS - ANG_CARRIER);

// ============================================================
// DIMENSIONS
// ============================================================
RING_OD       = 96;
RING_WALL     = 3;
RING_ID       = RING_OD - 2 * RING_WALL;  // 90

GEAR_ZONE_BOT = 0;
GEAR_ZONE_TOP = 22;

// Planet gear Z ranges
PO_ZBOT = 0;        // long pinion bottom
PO_ZTOP = 22;       // long pinion top
PI_ZBOT = 12;       // short pinion bottom
PI_ZTOP = 22;       // short pinion top

// Planet pin orbital radii
PO_ORBIT = 31.5;          // long pinion orbit radius (= CD_SL_PO)
PI_ORBIT_ACTUAL = 27.44;  // short pinion orbit (STL-measured, ≈ CD_SS_PI)
PI_ANG_OFFSET   = 71.5;   // Pi angular offset from Po (degrees)

// Planet pin bore
PIN_BORE_D = 8;            // axial bore through planet gears

// Washer dimensions
WASHER_OD   = 13;
WASHER_ID   = 6;
WASHER_H    = 1.2;

// Central thrust washer dims (W1, W9)
THRUST_WASHER_OD = 40;
THRUST_WASHER_ID = 20;
THRUST_WASHER_H  = 1.2;

// Carrier_1 dimensions
CARRIER1_OD      = 78;
CARRIER1_BOSS_OD = 35;
CARRIER1_ZTOP    = 26.5;
CARRIER1_HC_ZBOT = 22;
CARRIER1_HC_H    = CARRIER1_ZTOP - CARRIER1_HC_ZBOT;  // 4.5mm
CARRIER1_HUB_H   = 5;           // hub extends above plate
CARRIER1_BORE    = 26;           // clears SL shaft OD=25 + gap
CARRIER1_PIN_STUB_H = 3;        // pin stubs protrude below plate
CARRIER1_PIN_STUB_D = 8;        // match planet bore

// Sun shaft tube ODs
SUN_TUBE_OD      = 33;

// Bearings
BEARING_TOP_OD  = 26;
BEARING_TOP_ID  = 10;
BEARING_TOP_H   = RING_WALL;
CARRIER_SHAFT_OD = 33;
BEARING_BOT_OD   = 42;
BEARING_BOT_ID   = 35;
BEARING_BOT_H    = RING_WALL;
BEARING_CLR   = 0.25;

// ============================================================
// RING ENCLOSURE
// ============================================================
RING_EXT_SLIDER   = 23;       // [0:1:40]

RING_ORIG_ZBOT = 12;          // where teeth start (Po mesh zone)
RING_ORIG_ZTOP = 30;          // original ring top (from STL ref)
RING_ORIG_H    = RING_ORIG_ZTOP - RING_ORIG_ZBOT;

RING_EXT_H     = RING_EXT_SLIDER;
RING_BOT_Z     = RING_ORIG_ZBOT - RING_EXT_H;
RING_GAP_TOP   = 1.6;
RING_TOP_PLATE = 3;
RING_TOP_Z     = CARRIER1_ZTOP + RING_GAP_TOP + RING_TOP_PLATE;

LID_BOT_Z      = RING_BOT_Z;
LID_BOT_H      = RING_WALL;
LID_BOT_BORE   = SUN_TUBE_OD + 2 * BEARING_CLR + 2;

LID_TOP_Z      = RING_TOP_Z - RING_WALL;
LID_TOP_H      = RING_WALL;
LID_TOP_BORE   = CARRIER1_BOSS_OD + 2 * BEARING_CLR + 2;

RING_ADD_BOT_ZBOT = RING_BOT_Z;
RING_ADD_BOT_ZTOP = RING_ORIG_ZBOT;
RING_ADD_BOT_H    = RING_ADD_BOT_ZTOP - RING_ADD_BOT_ZBOT;

RING_ADD_TOP_ZBOT = RING_ORIG_ZTOP;
RING_ADD_TOP_ZTOP = RING_TOP_Z;
RING_ADD_TOP_H    = RING_ADD_TOP_ZTOP - RING_ADD_TOP_ZBOT;

// V-groove
GROOVE_WIDTH   = 4;
GROOVE_DEPTH   = 2;
GROOVE_Z       = (RING_BOT_Z + RING_TOP_Z) / 2;

// ============================================================
// STAGE 2 — DRIVE SHAFTS
// ============================================================
T_SS_SHAFT  = 17;   T_SL_SHAFT  = 23;   T_CAR_SHAFT = 29;
T_DRV_SS  = 20;     T_DRV_SL  = 20;     T_DRV_CAR = 20;

DRV_SS_OD  = T_DRV_SS  * TRANS_MOD + 2 * NORM_MOD;
DRV_SL_OD  = T_DRV_SL  * TRANS_MOD + 2 * NORM_MOD;
DRV_CAR_OD = T_DRV_CAR * TRANS_MOD + 2 * NORM_MOD;

DRV_SHAFT_D = 8;

DRV_SS_ANG  = 0;      DRV_SL_ANG  = 120;    DRV_CAR_ANG = 240;

CD_SS_DRV  = (T_SS_SHAFT  + T_DRV_SS)  * TRANS_MOD / 2;
CD_SL_DRV  = (T_SL_SHAFT  + T_DRV_SL)  * TRANS_MOD / 2;
CD_CAR_DRV = (T_CAR_SHAFT + T_DRV_CAR) * TRANS_MOD / 2;

DRV_SHAFT_LEN = 120;

ANCHOR_SHAFT_D  = 10;
ANCHOR_SHAFT_ZBOT = -70;
ANCHOR_SHAFT_ZTOP = 40;

// ============================================================
// VISIBILITY TOGGLES
// ============================================================
SHOW_SHAFT          = true;
SHOW_SMALL_SUN      = true;
SHOW_BIG_SUN        = true;
SHOW_LONG_PINION    = true;
SHOW_SHORT_PINION   = true;
SHOW_CARRIER_1      = true;
SHOW_CARRIER_2      = true;
SHOW_CARRIER_3      = true;
SHOW_RING           = true;
SHOW_WASHERS        = true;
SHOW_CLIPS          = true;

SHOW_V_GROOVE       = true;
SHOW_BEARINGS       = true;

SHOW_MOUNT_GEAR     = false;
SHOW_DRIVE          = false;
SHOW_ANCHOR         = false;

CROSS_SECTION       = false;
EXPLODE             = 0;

// ============================================================
// CUSTOMIZER SLIDERS
// ============================================================
CARRIER_SHAFT_EXT = 12.75;    // [5:0.25:20]
CAR_HUB_LEN       = 16;       // [4:0.5:16]
SL_HUB_LEN        = 16;       // [4:0.5:16]
SS_HUB_LEN        = 15;       // [4:0.5:15]
INNER_SHAFT_EXT   = 29;       // [0:0.5:40]
SL_SHAFT_EXT      = 12.75;    // [5:0.25:20]
SS_SHAFT_EXT      = 12.75;    // [5:0.25:20]

// ============================================================
// COLORS
// ============================================================
C_SHAFT     = [0.75, 0.75, 0.78];
C_SS        = [0.15, 0.55, 0.30];
C_SL        = [0.76, 0.60, 0.22];
C_PO        = [0.85, 0.25, 0.20];
C_PI        = [1.0,  0.85, 0.0];
C_CAR       = [0.55, 0.55, 0.58];
C_CAR2      = [0.45, 0.45, 0.50];
C_CAR3      = [0.60, 0.60, 0.65];
C_RING      = [0.25, 0.25, 0.28];
C_THRUST    = [0.85, 0.55, 0.20];
C_WASHER    = [0.95, 0.80, 0.10];
C_CLIP      = [0.3, 0.3, 0.9];
C_GROOVE    = [0.35, 0.20, 0.10];
C_BEARING   = [0.30, 0.60, 0.85];
C_LID       = [0.30, 0.28, 0.32];
C_DRV_SHAFT = [0.40, 0.40, 0.45];
C_DRV_SS    = [0.15, 0.55, 0.30];
C_DRV_SL    = [0.76, 0.60, 0.22];
C_DRV_CAR   = [0.55, 0.55, 0.58];
C_ANCHOR    = [0.70, 0.20, 0.20];

// ============================================================
// HELPERS
// ============================================================
module zcyl(d, zbot, h) {
    translate([0, 0, zbot]) cylinder(d=d, h=h);
}
module zcyl_hollow(od, id, zbot, h) {
    difference() {
        zcyl(od, zbot, h);
        translate([0, 0, zbot - 0.1]) cylinder(d=id, h=h + 0.2);
    }
}

// ============================================================
// LAYER 1: INVOLUTE MATH
// ============================================================
function _inv_polar(rb, alpha_deg) =
    let(a_rad = alpha_deg * PI / 180,
        x = rb * (cos(alpha_deg) + a_rad * sin(alpha_deg)),
        y = rb * (sin(alpha_deg) - a_rad * cos(alpha_deg)),
        r = sqrt(x*x + y*y),
        ang = atan2(y, x))
    [r, ang];

// ============================================================
// LAYER 2: 2D PROFILES
// ============================================================

// --- External involute gear 2D profile (hand-rolled) ---
module involute_gear_2d(teeth, mod, pressure_angle=20, clearance=0.25) {
    pitch_r  = teeth * mod / 2;
    base_r   = pitch_r * cos(pressure_angle);
    tip_r    = pitch_r + mod;
    root_r   = pitch_r - 1.25 * mod;

    alpha_tip = (base_r < tip_r) ? acos(base_r / tip_r) : 0;

    half_tooth_deg = (PI * mod / 2) / pitch_r * (180 / PI) / 2;

    pitch_polar = _inv_polar(base_r, pressure_angle);
    inv_ang_at_pitch = pitch_polar[1];

    right_offset = half_tooth_deg - inv_ang_at_pitch;

    steps = 30;

    tip_polar = _inv_polar(base_r, alpha_tip);
    right_tip_ang = tip_polar[1] + right_offset;
    left_tip_ang = -right_tip_ang;

    union() {
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * 360 / teeth])
            polygon(
                concat(
                    [[root_r * cos(-180/teeth), root_r * sin(-180/teeth)],
                     [root_r * cos(right_offset), root_r * sin(right_offset)]],

                    [for (s = [0:steps])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = p[1] + right_offset)
                        [r * cos(ang), r * sin(ang)]
                    ],

                    [for (s = [1:3])
                        let(ang = right_tip_ang + s * (left_tip_ang - right_tip_ang) / 4)
                        [tip_r * cos(ang), tip_r * sin(ang)]
                    ],

                    [for (s = [steps:-1:0])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = -(p[1] + right_offset))
                        [r * cos(ang), r * sin(ang)]
                    ],

                    [[root_r * cos(-right_offset), root_r * sin(-right_offset)],
                     [root_r * cos(180/teeth), root_r * sin(180/teeth)]]
                )
            );
        }
        circle(r=root_r, $fn=teeth * 8);
    }
}

// --- Internal involute gear 2D profile (boolean subtraction) ---
// Internal teeth: subtract external profile from annular blank.
// Root of internal gear is outward, tip is inward.
module internal_gear_2d(teeth, mod, pressure_angle=20, clearance=0.25) {
    pitch_r  = teeth * mod / 2;
    // Internal root radius = outward (dedendum outward from pitch)
    int_root_r = pitch_r + 1.25 * mod;

    difference() {
        circle(r = int_root_r, $fn = teeth * 4);
        involute_gear_2d(teeth, mod, pressure_angle, clearance);
    }
}

// --- Carrier_2 star plate 2D profile (180-point polygon from STL trace) ---
CAR_PROFILE_PTS = [
    [  40.00,    0.00], [  39.98,    1.40], [  39.90,    2.79],
    [  39.78,    4.18], [  39.61,    5.57], [  39.39,    6.95],
    [  38.82,    8.25], [  38.20,    9.52], [  36.92,   10.59],
    [  35.00,   11.37], [  33.07,   12.04], [  25.70,   10.38],
    [  18.49,    8.23], [  14.83,    7.23], [  14.57,    7.75],
    [  14.29,    8.25], [  13.99,    8.74], [  13.68,    9.23],
    [  13.35,    9.70], [  13.00,   10.16], [  12.64,   10.61],
    [  12.26,   11.04], [  11.87,   11.46], [  13.55,   14.03],
    [  17.08,   18.97], [  20.27,   24.16], [  20.16,   25.81],
    [  19.96,   27.48], [  19.58,   29.02], [  19.02,   30.43],
    [  18.38,   31.84], [  17.43,   32.78], [  16.44,   33.70],
    [  15.37,   34.52], [  14.23,   35.22], [  13.06,   35.89],
    [  11.79,   36.29], [  10.51,   36.66], [   9.20,   36.89],
    [   7.87,   37.01], [   6.54,   37.07], [   5.15,   36.65],
    [   3.80,   36.18], [   2.48,   35.48], [   1.21,   34.54],
    [   0.00,   33.56], [  -1.14,   32.69], [  -2.22,   31.79],
    [  -3.36,   32.01], [  -4.69,   33.34], [  -6.10,   34.62],
    [  -7.64,   35.97], [  -9.29,   37.25], [ -10.85,   37.84],
    [ -12.26,   37.74], [ -13.68,   37.59], [ -14.98,   37.09],
    [ -16.27,   36.54], [ -17.53,   35.95], [ -18.78,   35.32],
    [ -20.00,   34.64], [ -21.20,   33.92], [ -22.37,   33.16],
    [ -23.51,   32.36], [ -24.63,   31.52], [ -25.71,   30.64],
    [ -26.55,   29.49], [ -27.35,   28.32], [ -27.63,   26.68],
    [ -27.35,   24.62], [ -26.96,   22.62], [ -21.84,   17.06],
    [ -16.37,   11.90], [ -13.68,    9.23], [ -13.99,    8.74],
    [ -14.29,    8.25], [ -14.57,    7.75], [ -14.83,    7.23],
    [ -15.07,    6.71], [ -15.30,    6.18], [ -15.50,    5.64],
    [ -15.69,    5.10], [ -15.86,    4.55], [ -18.93,    4.72],
    [ -24.97,    5.31], [ -31.06,    5.48], [ -32.43,    4.56],
    [ -33.78,    3.55], [ -34.92,    2.44], [ -35.86,    1.25],
    [ -36.76,    0.00], [ -37.11,   -1.30], [ -37.40,   -2.62],
    [ -37.58,   -3.95], [ -37.62,   -5.29], [ -37.61,   -6.63],
    [ -37.33,   -7.93], [ -37.00,   -9.23], [ -36.55,  -10.48],
    [ -35.98,  -11.69], [ -35.37,  -12.87], [ -34.32,  -13.86],
    [ -33.24,  -14.80], [ -31.97,  -15.59], [ -30.52,  -16.23],
    [ -29.06,  -16.78], [ -27.74,  -17.33], [ -26.42,  -17.82],
    [ -26.04,  -18.92], [ -26.53,  -20.73], [ -26.93,  -22.59],
    [ -27.33,  -24.60], [ -27.62,  -26.67], [ -27.34,  -28.31],
    [ -26.55,  -29.49], [ -25.71,  -30.64], [ -24.63,  -31.52],
    [ -23.51,  -32.36], [ -22.37,  -33.16], [ -21.20,  -33.92],
    [ -20.00,  -34.64], [ -18.78,  -35.32], [ -17.53,  -35.95],
    [ -16.27,  -36.54], [ -14.98,  -37.09], [ -13.68,  -37.59],
    [ -12.26,  -37.74], [ -10.85,  -37.84], [  -9.29,  -37.27],
    [  -7.65,  -35.99], [  -6.11,  -34.66], [  -3.86,  -27.44],
    [  -2.12,  -20.13], [  -1.15,  -16.46], [  -0.58,  -16.49],
    [  -0.00,  -16.50], [   0.58,  -16.49], [   1.15,  -16.46],
    [   1.72,  -16.41], [   2.30,  -16.34], [   2.87,  -16.25],
    [   3.43,  -16.14], [   3.99,  -16.01], [   5.38,  -18.75],
    [   7.89,  -24.27], [  10.79,  -29.64], [  12.27,  -30.37],
    [  13.81,  -31.03], [  15.35,  -31.46], [  16.85,  -31.68],
    [  18.38,  -31.84], [  19.67,  -31.49], [  20.97,  -31.09],
    [  22.21,  -30.57], [  23.39,  -29.93], [  24.55,  -29.26],
    [  25.54,  -28.36], [  26.49,  -27.43], [  27.35,  -26.41],
    [  28.11,  -25.31], [  28.83,  -24.19], [  29.17,  -22.79],
    [  29.44,  -21.39], [  29.49,  -19.89], [  29.31,  -18.32],
    [  29.06,  -16.78], [  28.88,  -15.36], [  28.64,  -13.97],
    [  29.40,  -13.09], [  31.21,  -12.61], [  33.03,  -12.02],
    [  34.97,  -11.36], [  36.90,  -10.58], [  38.19,   -9.52],
    [  38.81,   -8.25], [  39.39,   -6.95], [  39.61,   -5.57],
    [  39.78,   -4.18], [  39.90,   -2.79], [  39.98,   -1.40]
];

module carrier_plate_2d() {
    polygon(CAR_PROFILE_PTS);
}

// ============================================================
// LAYER 3: 3D GEAR PRIMITIVES
// ============================================================

// --- External helical gear (twist extrusion of involute 2D) ---
module helical_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    rotate([0, 0, -twist/2])
    linear_extrude(height=height, twist=twist, slices=80, convexity=10)
    involute_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// --- Internal helical ring gear (twist extrusion of internal 2D) ---
// Boolean subtraction: annular blank minus external involute profile.
// Twist direction: same as external gear (RH external meshes with RH tooth space).
module helical_ring_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    rotate([0, 0, -twist/2])
    linear_extrude(height=height, twist=twist, slices=80, convexity=10)
    internal_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// --- Planet gear (helical external + axial bore) ---
module planet_gear(teeth, mod, helix_angle, height, bore_d, pressure_angle=20) {
    difference() {
        helical_gear(teeth, mod, helix_angle, height, pressure_angle);
        translate([0, 0, -0.1])
        cylinder(d=bore_d, h=height + 0.2, $fn=32);
    }
}

// ============================================================
// LAYER 4: SHAFT / COUPLING
// ============================================================

// --- Spline parameters ---
SPLINE_COUNT   = 6;
SPLINE_DEPTH   = 0.6;
SPLINE_DUTY    = 0.45;
SPLINE_LEADIN  = 1.5;
SPLINE_PILOT   = 0.5;
SPLINE_CHAMFER_TOP = 0.3;
SPLINE_CLEARANCE = 0.2;

// --- Splined shaft tube ---
module splined_tube(od, id, h, n_splines=SPLINE_COUNT, depth=SPLINE_DEPTH, duty=SPLINE_DUTY) {
    ridge_ang = 360 / n_splines * duty;
    pilot = min(SPLINE_PILOT, h * 0.1);
    leadin = min(SPLINE_LEADIN, h * 0.25);
    chamfer_top = min(SPLINE_CHAMFER_TOP, h * 0.1);
    z_ridge_start = pilot;
    z_full_start = pilot + leadin;
    z_full_end = h - chamfer_top;

    difference() {
        union() {
            cylinder(d=od, h=h, $fn=64);
            for (i = [0:n_splines-1])
                rotate([0, 0, i * 360 / n_splines])
                rotate_extrude(angle=ridge_ang, $fn=64)
                translate([od/2, 0])
                polygon([
                    [0,     z_ridge_start],
                    [depth, z_full_start],
                    [depth, z_full_end],
                    [0,     h - 0.01],
                ]);
        }
        translate([0, 0, -0.1])
        cylinder(d=id, h=h + 0.2, $fn=64);
    }
}

// --- Splined bore ---
module splined_bore(bore_d, h, n_splines=SPLINE_COUNT, depth=SPLINE_DEPTH, duty=SPLINE_DUTY, clearance=SPLINE_CLEARANCE) {
    ridge_ang = 360 / n_splines * duty;
    translate([0, 0, -0.1])
    cylinder(d=bore_d + clearance * 2, h=h + 0.2, $fn=64);
    for (i = [0:n_splines-1])
        rotate([0, 0, i * 360 / n_splines])
        rotate_extrude(angle=ridge_ang + 1, $fn=64)
        translate([bore_d/2 - 0.1, -0.1])
        square([depth + clearance + 0.1, h + 0.2]);
}

// ============================================================
// LAYER 5: HARDWARE
// ============================================================

// --- E-clip (retaining clip) ---
module e_clip(od=10, id=8, h=1, gap_angle=40) {
    difference() {
        cylinder(d=od, h=h, $fn=32);
        translate([0, 0, -0.1])
        cylinder(d=id, h=h + 0.2, $fn=32);
        // Cut gap sector
        rotate([0, 0, -gap_angle/2])
        linear_extrude(height=h + 0.2)
        polygon([
            [0, 0],
            [od, 0],
            [od * cos(gap_angle), od * sin(gap_angle)],
        ]);
    }
}

// --- Thrust washer (thin annular ring) ---
module thrust_washer(od, id, h) {
    zcyl_hollow(od, id, 0, h);
}

// ============================================================
// SHAFT EXTENSION DIMENSIONS (computed from sliders)
// ============================================================

// Mating gear specs
GEAR_FW       = 10;
LIP_H         = 1.5;
LIP_EXTRA     = 4;
LIP_GAP       = 0.25;
CHAMFER_TIP   = 1;

T_MATE_CAR = 40;
T_MATE_SL  = 32;
T_MATE_SS  = 26;

// Carrier plate dims
CAR_PLATE_ZTOP = -1.5;
CAR_PLATE_ZBOT = -3.5;
CAR_PLATE_OD   = 80;
CAR_PO_PIN_D   = 8;
CAR_PI_PIN_D   = 13.4;     // oversized to clear carrier_3 boss
CAR_PIN_DEPTH  = 2;
CAR_PLATE_H = CAR_PLATE_ZTOP - CAR_PLATE_ZBOT;

// Hub tube
CAR_HUB_ZTOP   = CAR_PLATE_ZBOT;
CAR_HUB_ZBOT   = CAR_PLATE_ZBOT - CAR_HUB_LEN;
CAR_HUB_OD     = 33;
CAR_HUB_ID     = 26;
CAR_HUB_COLLAR_Z = -6.5;

// Bottom cap
CAR_CAP_H     = 2;
CAR_CAP_ZTOP  = CAR_HUB_ZBOT;
CAR_CAP_ZBOT  = CAR_HUB_ZBOT - CAR_CAP_H;
CAR_CAP_OD    = 33;
CAR_CAP_ID    = 27.25;

// Extensions
CAR_EXT_H     = CARRIER_SHAFT_EXT;
CAR_EXT_OD    = 33;
CAR_EXT_ID    = 26;
CAR_EXT_ZTOP  = CAR_CAP_ZBOT;
CAR_EXT_ZBOT  = CAR_CAP_ZBOT - CAR_EXT_H;

SL_EXT_H      = SL_SHAFT_EXT;
SL_EXT_ZTOP   = -(GEAR_ZONE_TOP + SL_HUB_LEN);
SL_EXT_ZBOT   = SL_EXT_ZTOP - SL_EXT_H;
SL_EXT_OD     = 25;
SL_EXT_ID     = 20;

SS_EXT_H      = SS_SHAFT_EXT;
SS_EXT_ZTOP   = SL_EXT_ZTOP - SS_HUB_LEN;
SS_EXT_ZBOT   = SS_EXT_ZTOP - SS_EXT_H;
SS_EXT_OD     = 18.75;
SS_EXT_ID     = 12;

// Drive pinion Z positions (centered on bottom mating gears)
DRV_SS_FW  = GEAR_FW;
DRV_SL_FW  = GEAR_FW;
DRV_CAR_FW = GEAR_FW;
DRV_SS_Z   = SS_EXT_ZBOT  - GEAR_FW / 2;
DRV_SL_Z   = SL_EXT_ZBOT  - GEAR_FW / 2;
DRV_CAR_Z  = CAR_EXT_ZBOT - GEAR_FW / 2;

// Inner shaft
INNER_SHAFT_D    = 10;
INNER_SHAFT_ZTOP = 26 + INNER_SHAFT_EXT / 2;
INNER_SHAFT_ZBOT = SS_EXT_ZTOP - INNER_SHAFT_EXT / 2;

// Bearing Z positions
CARRIER2_ZBOT = -21.5;
BEARING_BOT_Z = RING_BOT_Z;
BEARING_TOP_Z = CARRIER1_ZTOP + RING_GAP_TOP;

// ============================================================
// LAYER 6: COMPONENT MODULES
// ============================================================

// --- Ring gear (100% parametric — internal helical teeth + walls + lids) ---
module new_ring() {
    rotate([0, 0, ANG_RING]) {
        // Internal helical teeth (gear zone Z=0 to 22)
        color(C_RING, 0.11)
        translate([0, 0, GEAR_ZONE_BOT])
        difference() {
            helical_ring_gear(teeth=T_RING, mod=NORM_MOD,
                helix_angle=HELIX_ANG,
                height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            // Clip to ring wall OD (remove anything beyond ring wall)
            // Not needed — helical_ring_gear already bounded by int_root_r
        }

        // Outer wall: full height from RING_BOT_Z to RING_TOP_Z
        color(C_RING, 0.11)
        zcyl_hollow(RING_OD, RING_ID, RING_BOT_Z, RING_TOP_Z - RING_BOT_Z);

        // Bottom inward plate (bearing seat)
        color(C_LID, 0.11)
        zcyl_hollow(RING_ID, BEARING_BOT_OD, RING_BOT_Z, RING_WALL);

        // Top inward plate (bearing seat)
        color(C_LID, 0.11)
        zcyl_hollow(RING_ID, BEARING_TOP_OD, CARRIER1_ZTOP + RING_GAP_TOP, RING_TOP_PLATE);
    }
}

// --- Ss (small sun) — full parametric ---
module ss_full_shaft() {
    rotate([0, 0, ANG_SS]) {
        // Splined shaft tube (extension bottom to gearbox top)
        color(C_SS)
        translate([0, 0, SS_EXT_ZBOT])
        splined_tube(od=SS_EXT_OD, id=SS_EXT_ID,
            h=GEAR_ZONE_TOP - SS_EXT_ZBOT);

        // Sun gear teeth inside gearbox (Ss = 31T, Z=0 to 22)
        color(C_SS)
        difference() {
            translate([0, 0, GEAR_ZONE_BOT])
            helical_gear(teeth=T_SS, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            translate([0, 0, GEAR_ZONE_BOT - 0.1])
            cylinder(d=SS_EXT_ID, h=GEAR_ZONE_TOP - GEAR_ZONE_BOT + 0.2, $fn=64);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_SS)
        difference() {
            translate([0, 0, SS_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_SS, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_FW);
            translate([0, 0, SS_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=SS_EXT_OD, h=GEAR_FW);
        }
    }
}

// --- SL (big sun) — full parametric ---
module sl_full_shaft() {
    rotate([0, 0, ANG_SL]) {
        // Splined shaft tube (extension bottom to gearbox top)
        color(C_SL)
        translate([0, 0, SL_EXT_ZBOT])
        splined_tube(od=SL_EXT_OD, id=SL_EXT_ID,
            h=GEAR_ZONE_TOP - SL_EXT_ZBOT);

        // Sun gear teeth inside gearbox (SL = 38T, Z=0 to 22)
        color(C_SL)
        difference() {
            translate([0, 0, GEAR_ZONE_BOT])
            helical_gear(teeth=T_SL, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            translate([0, 0, GEAR_ZONE_BOT - 0.1])
            cylinder(d=SL_EXT_ID, h=GEAR_ZONE_TOP - GEAR_ZONE_BOT + 0.2, $fn=64);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_SL)
        difference() {
            translate([0, 0, SL_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_SL, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_FW);
            translate([0, 0, SL_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=SL_EXT_OD, h=GEAR_FW);
        }
    }
}

// --- Carrier_2 (bottom carrier) — full parametric ---
module carrier_full_shaft() {
    rotate([0, 0, ANG_CARRIER]) {
        color(C_CAR2)
        difference() {
            union() {
                // Star plate
                translate([0, 0, CAR_PLATE_ZBOT])
                linear_extrude(height=CAR_PLATE_H)
                carrier_plate_2d();

                // Hub tube
                translate([0, 0, CAR_CAP_ZTOP])
                cylinder(d=CAR_HUB_OD, h=CAR_HUB_ZTOP - CAR_CAP_ZTOP, $fn=64);

                // Bottom cap
                translate([0, 0, CAR_CAP_ZBOT])
                cylinder(d=CAR_CAP_OD, h=CAR_CAP_ZTOP - CAR_CAP_ZBOT, $fn=64);

                // Splined extension
                translate([0, 0, CAR_EXT_ZBOT])
                splined_tube(od=CAR_EXT_OD, id=CAR_EXT_ID,
                    h=CAR_CAP_ZBOT - CAR_EXT_ZBOT);
            }

            // Central bore through hub + plate
            translate([0, 0, CAR_CAP_ZBOT - 0.1])
            cylinder(d=CAR_HUB_ID, h=CAR_PLATE_ZTOP - CAR_CAP_ZBOT + 0.2, $fn=64);

            // Extension bore
            translate([0, 0, CAR_EXT_ZBOT - 0.1])
            cylinder(d=CAR_EXT_ID, h=CAR_CAP_ZBOT - CAR_EXT_ZBOT + 0.2, $fn=64);

            // Po pin holes (3x at 0/120/240)
            for (i = [0:2])
                rotate([0, 0, i * 120])
                translate([PO_ORBIT, 0, CAR_PLATE_ZBOT - 0.1])
                cylinder(d=CAR_PO_PIN_D, h=CAR_PIN_DEPTH + 0.2, $fn=24);

            // Pi pin holes (3x at 71.5/191.5/311.5, oversized for carrier_3 boss)
            for (i = [0:2])
                rotate([0, 0, i * 120 + PI_ANG_OFFSET])
                translate([PI_ORBIT_ACTUAL, 0, CAR_PLATE_ZBOT - 0.1])
                cylinder(d=CAR_PI_PIN_D, h=CAR_PIN_DEPTH + 0.2, $fn=24);
        }

        // Bottom mating gear
        if (SHOW_MOUNT_GEAR)
        color(C_CAR2)
        difference() {
            translate([0, 0, CAR_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_CAR, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_FW);
            translate([0, 0, CAR_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=CAR_EXT_OD, h=GEAR_FW);
        }
    }
}

// --- Carrier_1 (top plate) — NEW parametric ---
module carrier_1() {
    rotate([0, 0, ANG_CARRIER]) {
        color(C_CAR)
        difference() {
            union() {
                // Main plate (Z=22 to 26.5)
                zcyl(CARRIER1_OD, CARRIER1_HC_ZBOT, CARRIER1_HC_H);

                // Central hub (extends above plate)
                zcyl(CARRIER1_BOSS_OD, CARRIER1_ZTOP, CARRIER1_HUB_H);

                // Pin stubs on underside — Po positions (3x)
                for (i = [0:2])
                    rotate([0, 0, i * 120])
                    translate([PO_ORBIT, 0, 0])
                    zcyl(CARRIER1_PIN_STUB_D,
                         CARRIER1_HC_ZBOT - CARRIER1_PIN_STUB_H,
                         CARRIER1_PIN_STUB_H);

                // Pin stubs on underside — Pi positions (3x)
                for (i = [0:2])
                    rotate([0, 0, i * 120 + PI_ANG_OFFSET])
                    translate([PI_ORBIT_ACTUAL, 0, 0])
                    zcyl(CARRIER1_PIN_STUB_D,
                         CARRIER1_HC_ZBOT - CARRIER1_PIN_STUB_H,
                         CARRIER1_PIN_STUB_H);
            }

            // Central bore (clears SL shaft + gap)
            translate([0, 0, CARRIER1_HC_ZBOT - CARRIER1_PIN_STUB_H - 0.1])
            cylinder(d=CARRIER1_BORE,
                     h=CARRIER1_HC_H + CARRIER1_HUB_H + CARRIER1_PIN_STUB_H + 0.2,
                     $fn=64);
        }
    }
}

// --- Carrier_3 (pin cage) — NEW parametric ---
// One sector: two pin bosses (Po + Pi) + bridging web
// 3 sectors at 120° intervals
CAGE_BOSS_OD = 10;     // outer diameter of pin boss
CAGE_BOSS_ID = 8;      // pin bore = planet bore
CAGE_WEB_W   = 3;      // bridging web width
CAGE_WEB_H   = 2;      // bridging web thickness

module carrier_3_sector(sector_ang) {
    // Po boss — full gearbox height Z=0 to 22
    rotate([0, 0, sector_ang])
    translate([PO_ORBIT, 0, PO_ZBOT])
    difference() {
        cylinder(d=CAGE_BOSS_OD, h=PO_ZTOP - PO_ZBOT, $fn=24);
        translate([0, 0, -0.1])
        cylinder(d=CAGE_BOSS_ID, h=PO_ZTOP - PO_ZBOT + 0.2, $fn=24);
    }

    // Pi boss — Z = PI_ZBOT-2 to PI_ZTOP (extends below Pi gear for support)
    // This boss passes through carrier_2's oversized Pi holes (D=13.4)
    PI_BOSS_ZBOT = PI_ZBOT - 2;
    rotate([0, 0, sector_ang + PI_ANG_OFFSET])
    translate([PI_ORBIT_ACTUAL, 0, PI_BOSS_ZBOT])
    difference() {
        cylinder(d=CAGE_BOSS_OD, h=PI_ZTOP - PI_BOSS_ZBOT, $fn=24);
        translate([0, 0, -0.1])
        cylinder(d=CAGE_BOSS_ID, h=PI_ZTOP - PI_BOSS_ZBOT + 0.2, $fn=24);
    }

    // Bridging web between Po and Pi bosses (structural strut)
    // Positioned at mid-height of Pi zone, connecting the two boss centers
    WEB_Z = (PI_ZBOT + PI_ZTOP) / 2 - CAGE_WEB_H / 2;
    po_x = PO_ORBIT * cos(sector_ang);
    po_y = PO_ORBIT * sin(sector_ang);
    pi_x = PI_ORBIT_ACTUAL * cos(sector_ang + PI_ANG_OFFSET);
    pi_y = PI_ORBIT_ACTUAL * sin(sector_ang + PI_ANG_OFFSET);

    bridge_len = sqrt((pi_x - po_x) * (pi_x - po_x) + (pi_y - po_y) * (pi_y - po_y));
    bridge_ang = atan2(pi_y - po_y, pi_x - po_x);

    translate([po_x, po_y, WEB_Z])
    rotate([0, 0, bridge_ang])
    translate([0, -CAGE_WEB_W/2, 0])
    cube([bridge_len, CAGE_WEB_W, CAGE_WEB_H]);
}

module carrier_3_assembly() {
    color(C_CAR3)
    rotate([0, 0, ANG_CARRIER])
    for (i = [0:2])
        carrier_3_sector(i * 120);
}

// --- Inner shaft (solid 10mm rod) ---
module inner_shaft() {
    rotate([0, 0, ANG_SS])
    color(C_SHAFT)
    translate([0, 0, INNER_SHAFT_ZBOT])
    cylinder(d=INNER_SHAFT_D, h=INNER_SHAFT_ZTOP - INNER_SHAFT_ZBOT, $fn=32);
}

// ============================================================
// LAYER 7: SUBASSEMBLIES
// ============================================================

// --- Planet assembly (Po x3 + Pi x3 with self-rotation) ---
module planet_assembly() {
    for (i = [0:2]) {
        ang = i * 120;

        // Long pinion (Po) — orbits with carrier, self-rotates on pin
        if (SHOW_LONG_PINION)
        color(C_PO)
        rotate([0, 0, ANG_CARRIER + ang])
        translate([PO_ORBIT, 0, 0])
        rotate([0, 0, ANG_PO_SELF])
        translate([0, 0, PO_ZBOT])
        planet_gear(teeth=T_PO, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=PO_ZTOP - PO_ZBOT,
            bore_d=PIN_BORE_D);

        // Short pinion (Pi) — orbits with carrier, self-rotates on pin
        if (SHOW_SHORT_PINION)
        color(C_PI)
        rotate([0, 0, ANG_CARRIER + ang + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, 0])
        rotate([0, 0, ANG_PI_SELF])
        translate([0, 0, PI_ZBOT])
        planet_gear(teeth=T_PI, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=PI_ZTOP - PI_ZBOT,
            bore_d=PIN_BORE_D);
    }
}

// --- Washer assembly (all parametric) ---
// W1: Ring top lid ↔ Carrier_1 top       → central thrust washer
// W2: Carrier_1 underside ↔ Po gear top  → pin washer x3
// W3: Carrier_1 underside ↔ Pi gear top  → pin washer x3
// W4: Pi gear bottom ↔ Carrier_3 shelf   → pin washer x3
// W5: SL top ↔ interface                 → big sun thrust ring
// W6: Ss top ↔ SL inner bore             → small sun thrust ring
// W7: Po gear bottom ↔ Carrier_2 top     → pin washer x3
// W8: SL bottom ↔ Carrier_2              → big sun thrust ring
// W9: Carrier_2 bottom ↔ Ring bottom lid → central thrust washer

// Thrust ring dimensions
BIG_SUN_RING_OD = SL_EXT_OD;      // 25mm
BIG_SUN_RING_ID = SL_EXT_ID;      // 20mm
BIG_SUN_RING_H  = 1.5;

SM_SUN_RING_OD = SS_EXT_OD;       // 18.75mm
SM_SUN_RING_ID = SS_EXT_ID;       // 12mm
SM_SUN_RING_H  = 1.5;

module washer_assembly() {
    // W1: Central thrust washer at ring top lid ↔ carrier_1 top
    color(C_THRUST)
    rotate([0, 0, ANG_CARRIER])
    translate([0, 0, CARRIER1_ZTOP + RING_GAP_TOP - THRUST_WASHER_H])
    thrust_washer(THRUST_WASHER_OD, THRUST_WASHER_ID, THRUST_WASHER_H);

    // W2: Pin washers x3 at Po gear top ↔ carrier_1 underside
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120])
        translate([PO_ORBIT, 0, PO_ZTOP])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W3: Pin washers x3 at Pi gear top ↔ carrier_1 underside
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120 + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, PI_ZTOP])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W4: Pin washers x3 at Pi gear bottom ↔ carrier_3 shelf
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120 + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, PI_ZBOT - WASHER_H])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W5: Big sun thrust ring at SL top face
    color(C_THRUST)
    rotate([0, 0, ANG_SL])
    translate([0, 0, GEAR_ZONE_TOP])
    thrust_washer(BIG_SUN_RING_OD, BIG_SUN_RING_ID, BIG_SUN_RING_H);

    // W6: Small sun thrust ring at Ss top face
    color(C_THRUST)
    rotate([0, 0, ANG_SS])
    translate([0, 0, GEAR_ZONE_TOP])
    thrust_washer(SM_SUN_RING_OD, SM_SUN_RING_ID, SM_SUN_RING_H);

    // W7: Pin washers x3 at Po gear bottom ↔ carrier_2 top
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120])
        translate([PO_ORBIT, 0, PO_ZBOT - WASHER_H])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W8: Big sun thrust ring at SL bottom ↔ carrier_2 top
    color(C_THRUST)
    rotate([0, 0, ANG_SL])
    translate([0, 0, CAR_PLATE_ZTOP - BIG_SUN_RING_H])
    thrust_washer(BIG_SUN_RING_OD, BIG_SUN_RING_ID, BIG_SUN_RING_H);

    // W9: Central thrust washer at carrier_2 bottom ↔ ring bottom lid
    color(C_THRUST)
    rotate([0, 0, ANG_CARRIER])
    translate([0, 0, CARRIER2_ZBOT - THRUST_WASHER_H])
    thrust_washer(THRUST_WASHER_OD, THRUST_WASHER_ID, THRUST_WASHER_H);
}

// --- Clip assembly (all parametric e-clips) ---
module clip_assembly() {
    // E-clips at Po pin tops (above carrier_1 underside)
    for (i = [0:2])
        color(C_CLIP)
        rotate([0, 0, ANG_CARRIER + i * 120])
        translate([PO_ORBIT, 0, PO_ZTOP + WASHER_H + 0.3])
        e_clip();

    // E-clips at Pi pin tops (above carrier_1 underside)
    for (i = [0:2])
        color(C_CLIP)
        rotate([0, 0, ANG_CARRIER + i * 120 + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, PI_ZTOP + WASHER_H + 0.3])
        e_clip();
}

// ============================================================
// LAYER 8: DRIVE / BEARINGS / ANCHOR
// ============================================================

// --- Drive pinion module ---
module drive_pinion(ang, drv_z, gear_teeth, gear_fw, cd, shaft_color, gear_color) {
    rotate([0, 0, ang])
    translate([cd, 0, drv_z])
    rotate([0, 90, 0]) {
        // Drive shaft (horizontal steel rod)
        color(shaft_color)
        translate([0, 0, -DRV_SHAFT_LEN/2])
        cylinder(d=DRV_SHAFT_D, h=DRV_SHAFT_LEN, $fn=32);

        // Helical drive gear (bored for shaft)
        color(gear_color, 0.85)
        difference() {
            translate([0, 0, -gear_fw/2])
            helical_gear(teeth=gear_teeth, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=gear_fw);
            translate([0, 0, -gear_fw/2 - 0.1])
            cylinder(d=DRV_SHAFT_D + 0.4, h=gear_fw + 0.2, $fn=32);
        }
    }
}

module drive_assembly() {
    drive_pinion(DRV_SS_ANG, DRV_SS_Z, T_DRV_SS,
                 DRV_SS_FW, CD_SS_DRV, C_DRV_SHAFT, C_DRV_SS);
    drive_pinion(DRV_SL_ANG, DRV_SL_Z, T_DRV_SL,
                 DRV_SL_FW, CD_SL_DRV, C_DRV_SHAFT, C_DRV_SL);
    drive_pinion(DRV_CAR_ANG, DRV_CAR_Z, T_DRV_CAR,
                 DRV_CAR_FW, CD_CAR_DRV, C_DRV_SHAFT, C_DRV_CAR);
}

// --- Bearings ---
module bearings() {
    if (SHOW_BEARINGS) {
        color(C_BEARING, 0.9)
        zcyl_hollow(BEARING_BOT_OD, BEARING_BOT_ID, BEARING_BOT_Z, BEARING_BOT_H);
        color(C_BEARING, 0.9)
        zcyl_hollow(BEARING_TOP_OD, BEARING_TOP_ID, BEARING_TOP_Z, BEARING_TOP_H);
    }
}

// --- V-groove ---
module v_groove() {
    rotate([0, 0, ANG_RING]) {
        color(C_RING, 0.9)
        zcyl_hollow(RING_OD + 0.1, RING_OD - 0.1, GROOVE_Z - GROOVE_WIDTH / 2, GROOVE_WIDTH);

        color(C_GROOVE, 0.8)
        translate([0, 0, GROOVE_Z])
        rotate_extrude(convexity=4)
        translate([RING_OD / 2 - GROOVE_DEPTH * 0.3, 0, 0])
        circle(d=GROOVE_WIDTH * 0.5);
    }
}

// --- Frame anchor shaft ---
module anchor_shaft() {
    color(C_ANCHOR)
    zcyl(ANCHOR_SHAFT_D, ANCHOR_SHAFT_ZBOT, ANCHOR_SHAFT_ZTOP - ANCHOR_SHAFT_ZBOT);
}

// ============================================================
// LAYER 9: FULL ASSEMBLY
// ============================================================
module full_assembly() {
    // Concentric shafts (innermost to outermost)
    if (SHOW_SHAFT)       inner_shaft();
    if (SHOW_SMALL_SUN)   ss_full_shaft();
    if (SHOW_BIG_SUN)     sl_full_shaft();

    // Carrier system
    if (SHOW_CARRIER_2)   carrier_full_shaft();
    if (SHOW_CARRIER_1)   carrier_1();
    if (SHOW_CARRIER_3)   carrier_3_assembly();

    // Planet gears
    planet_assembly();

    // Ring enclosure
    if (SHOW_RING)        new_ring();

    // Hardware
    if (SHOW_WASHERS)     washer_assembly();
    if (SHOW_CLIPS)       clip_assembly();

    // External features
    if (SHOW_V_GROOVE)    v_groove();
    if (SHOW_BEARINGS)    bearings();
    if (SHOW_DRIVE)       drive_assembly();
    if (SHOW_ANCHOR)      anchor_shaft();
}

// ============================================================
// MAIN
// ============================================================
if (CROSS_SECTION) {
    difference() {
        rotate([180, 0, 0]) full_assembly();
        translate([-200, 0, -200]) cube([400, 200, 400]);
    }
} else {
    rotate([180, 0, 0]) full_assembly();
}

// ============================================================
// ECHO + ASSERTIONS
// ============================================================
echo("==============================================");
echo("  RAVIGNEAUX V13 — 100% PARAMETRIC");
echo("==============================================");
echo(str("Ravigneaux check: ", T_SL, " + 2*", T_PO, " = ", T_SL + 2*T_PO,
         " (Ring=", T_RING, ") ", (T_SL + 2*T_PO == T_RING) ? "OK" : "FAIL"));
echo(str("Pitch radii — Ring:", PR_RING, " SL:", PR_SL, " Ss:", PR_SS,
         " Po:", PR_PO, " Pi:", PR_PI));
echo(str("Center dist — SL-Po:", CD_SL_PO, " (PO_ORBIT=", PO_ORBIT, ") ",
         abs(CD_SL_PO - PO_ORBIT) < 0.01 ? "OK" : "MISMATCH"));
echo(str("Center dist — Ss-Pi:", CD_SS_PI, " (PI_ORBIT=", PI_ORBIT_ACTUAL, ") ",
         "diff=", abs(CD_SS_PI - PI_ORBIT_ACTUAL)));
echo(str("Input SL:      ", DRIVE_SL_DEG, " deg/cycle → angle=", ANG_SL));
echo(str("Input Ss:      ", DRIVE_SS_DEG, " deg/cycle → angle=", ANG_SS));
echo(str("Input Carrier: ", DRIVE_CARRIER_DEG, " deg/cycle → angle=", ANG_CARRIER));
echo(str("OUTPUT Ring:   angle=", ANG_RING, " (ratio SL→Ring = ", -T_SL/T_RING, ")"));
echo(str("V-groove: Z=", GROOVE_Z));
echo("ANIMATION: Use View->Animate (FPS=10, Steps=100) OR drag MANUAL_SL/SS/CARRIER sliders");
