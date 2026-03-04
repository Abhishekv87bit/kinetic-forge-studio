// ============================================================
// STAGE 1 ASSEMBLY — PIP PROTOTYPE (v2: herringbone + fixes)
// Sun1 + Ring1(int+ext) + 3×Planet1 + Carrier1 + B-pinion
// ============================================================
// CHANGES from v1:
//   Fix 1: RING_WALL 3→1.5 (ext root truncation)
//   Fix 5: CAR_PAD 2→1.5 (carrier-ring tip margin)
//   Fix 6: AXIAL_GAP 0→0.2 (ring-carrier clearance)
//   Fix 7: Herringbone on sun/planets/ring-internal (smooth + self-centering)
//          External ring teeth + B-pinion stay SPUR (different MOD, easy assembly)
// ============================================================
// Gear phasing uses BOSL2 gear_spin — formulas from gears.scad.
// Ring gear is TWO concentric gears: internal MOD=1 herringbone + external MOD=1.5 spur.
// Carrier1 is full PIP cage (plates + pins + planets + hex boss fused).
// ============================================================
//
// CONNECTION AUDIT (PIP prototype):
//
// Part             Interface      Type           Mates With
// ────────────────────────────────────────────────────────────
// Sun1 bore        hex bore       HEX KEYED      A-shaft (torque)
// Ring1            free-floating  NONE           (driven by planets + B-pinion)
// B-pinion bore    hex bore       HEX KEYED      B-shaft (torque)
// Carrier1         PIP cage       FUSED          bot plate + pins + top plate + hex boss
// Carrier1 bot     bearing bore   BEARING        A-shaft (decoupled)
// Carrier1 top     bearing bore   BEARING        A-shaft (decoupled)
// Carrier1 top     hex boss       HEX KEYED (M)  Sun2 bore + Stage 2 female socket
// Planets          pin bore       PIP CLEARANCE  Carrier pins (captured in cage)
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

/* [Animation] */
// Use OpenSCAD View→Animate (FPS=10, Steps=100) for live animation.
// Or use MANUAL_POSITION slider in Customizer.
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_ANIMATION = true;  // true = use $t, false = use MANUAL_POSITION

/* [Inputs] */
// A-shaft drives Sun1. B-shaft drives Ring1 via external pinion.
A_INPUT = 0; // [0:1:360] degrees
B_INPUT = 0; // [0:1:360] degrees

/* [Visibility] */
SHOW_SUN = true;
SHOW_RING = true;
SHOW_PLANETS = true;
SHOW_CARRIER = true;
SHOW_BOT_PLATE = true;  // toggle bottom (white) carrier plate
SHOW_BPINION = true;
SHOW_SHAFTS = true;
SHOW_BEARINGS = true;
SHOW_WASHERS = true;

/* [Options] */
CROSS_SECTION = false;
EXPLODE = 0; // [0:0.5:20]

// ============================================================
// PARAMETERS (from planetary_params.scad)
// ============================================================
MOD = 1.0;
EXT_MOD = 1.5;
PA = 20;
HELIX_ANGLE = 20;       // herringbone helix angle (internal mesh)
GFW = 6;
EXT_GFW = 6;
CARRIER_T = 2;
PIN_D = 2;
CAR_PAD = 1.5;          // Fix 5: carrier plate radial pad (was 2.0)
THRUST_WASHER_T = 0.5;  // PTFE thrust washer thickness (mm)
AXIAL_GAP = 0.2 + THRUST_WASHER_T;  // 0.7mm: 0.2 clearance + 0.5 washer
RING_WALL = 1.5;        // Fix 1: reduced from 3.0 (ext root margin 0.375mm)
N_PLANETS = 3;
BACKLASH = 0.21;

S1_T = 13;
P1_T = 8;
R1_T = 29;
EXT_T = 26;
BPIN_T = 8;

SHAFT_D = 5;       // hex across-flats
PIP_TOL = 0.35;
BEARING_WALL = 1.5;

$fn = 64;

// ============================================================
// DERIVED VALUES
// ============================================================
// Center distances (helical=0 for gear_dist — herringbone doesn't change CD)
S1_ORB = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                   profile_shift1=0, profile_shift2=0);
DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=BPIN_T,
                     profile_shift1=0, profile_shift2=0);

// Ring radii
R1_ROOT_R = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_INNER_R = R1_ROOT_R + RING_WALL;
EXT_OUTER_R = outer_radius(mod=EXT_MOD, teeth=EXT_T);

// Shaft hex
HEX_R = SHAFT_D / 2;  // across-flats / 2
HEX_CIRC_R = SHAFT_D / (2 * cos(30));  // circumscribed radius

// Bearing
BEARING_ID = HEX_CIRC_R * 2 + 2 * PIP_TOL;
BEARING_OD = BEARING_ID + 2 * BEARING_WALL;

// Planet phasing (from BOSL2 gears.scad:3685-3699)
QUANT = 360 / (S1_T + R1_T);
PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    QUANT * round(i * 360 / N_PLANETS / QUANT)
];
RING_SPIN0 = 180/R1_T * (1 - (S1_T % 2));  // S1=13 odd → 0
PLANET_SPINS0 = [for (ang = PLANET_ANGLES)
    (S1_T/P1_T) * (ang - 90) + 90 + ang + 180/P1_T
];

// Animation / manual input
T = USE_ANIMATION ? $t : MANUAL_POSITION;
SUN_DEG = A_INPUT + T * 360;   // sun rotation (from A-shaft)
RING_DEG = B_INPUT;              // ring rotation (from B-shaft via ext pinion)

// Differential: carrier = (sun*S + ring*R)/(S+R)
CARRIER_DEG = (SUN_DEG * S1_T + RING_DEG * R1_T) / (S1_T + R1_T);
// Planet self-spin relative to carrier
PLANET_SELF = -(SUN_DEG - CARRIER_DEG) * S1_T / P1_T;

// B-pinion rotation (meshes with ring external teeth)
BPIN_DEG = -RING_DEG * EXT_T / BPIN_T;

// Axial positions — Fix 6: AXIAL_GAP between ring faces and carrier plates
SUN_Z = 0;
RING_Z = 0;
CARRIER_BOT_Z = -GFW/2 - AXIAL_GAP - CARRIER_T;
CARRIER_TOP_Z = GFW/2 + AXIAL_GAP;

// ============================================================
// MODULES
// ============================================================

// Hex profile (2D) for keyed connections
module hex_profile(af, tol=0) {
    // af = across-flats dimension
    r = (af + 2*tol) / (2 * cos(30));
    circle(r=r, $fn=6);
}

// Bearing bushing
module bearing_bushing(h, id, od) {
    color("goldenrod")
    difference() {
        cylinder(h=h, d=od, center=true);
        cylinder(h=h+1, d=id, center=true);
    }
}

// PTFE thrust washer — thin annular cylinder
module thrust_washer(id, od, h=THRUST_WASHER_T) {
    color("yellow", 0.7)
    difference() {
        cylinder(h=h, d=od, center=true, $fn=48);
        cylinder(h=h+1, d=id, center=true, $fn=48);
    }
}

// ============================================================
// THRUST WASHERS — Stage 1 interfaces
// ============================================================
module stage1_washers() {
    car_r = S1_ORB + PIN_D/2 + CAR_PAD;
    bearing_bore_d = BEARING_OD + 2*PIP_TOL;

    // 1. Carrier1 bot plate ↔ Ring1 bottom face
    translate([0, 0, CARRIER_BOT_Z + CARRIER_T + THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=car_r*2);

    // 2. Carrier1 top plate ↔ Ring1 top face
    translate([0, 0, CARRIER_TOP_Z - THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=car_r*2);
}

// ============================================================
// SUN1 GEAR — red, hex keyed to A-shaft, HERRINGBONE
// ============================================================
module sun1() {
    color("red")
    difference() {
        spur_gear(
            mod=MOD, teeth=S1_T,
            pressure_angle=PA,
            thickness=GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            helical=HELIX_ANGLE,
            herringbone=true,
            gear_spin=SUN_DEG
        );
        // Hex bore for A-shaft
        linear_extrude(GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// RING1 — blue, dual teeth:
//   Internal: MOD=1 herringbone (meshes with planets)
//   External: MOD=1.5 SPUR (meshes with B-pinion)
// ============================================================
module ring1() {
    // Internal teeth (MOD=1.0, 29T, HERRINGBONE)
    color("royalblue", 0.7)
    ring_gear(
        mod=MOD, teeth=R1_T,
        pressure_angle=PA,
        thickness=GFW,
        backing=RING_WALL,
        profile_shift=0,
        backlash=BACKLASH/2,
        helical=HELIX_ANGLE,
        herringbone=true,
        gear_spin=RING_SPIN0 + RING_DEG
    );

    // External teeth (MOD=1.5, 26T, SPUR) — concentric, same rotation
    // gear_spin handles rotation — NO additional rotate() wrapper
    color("steelblue", 0.8)
    difference() {
        spur_gear(
            mod=EXT_MOD, teeth=EXT_T,
            pressure_angle=PA,
            thickness=EXT_GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            gear_spin=-90 + RING_DEG
        );
        // Remove center (ring body is already there from internal gear)
        cylinder(h=EXT_GFW+2, r=RING_INNER_R - 0.01, center=true, $fn=64);
    }
}

// ============================================================
// PLANETS — green, on carrier pins, HERRINGBONE
// ============================================================
module planets() {
    pin_bore_d = PIN_D + 2*PIP_TOL;  // clearance bore for pin
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = PLANET_ANGLES[i];
        planet_spin0_i = PLANET_SPINS0[i];

        // Current orbit angle (carrier rotation shifts it)
        current_orbit = orbit_angle_i + CARRIER_DEG;
        px = S1_ORB * cos(current_orbit);
        py = S1_ORB * sin(current_orbit);

        color("green")
        translate([px, py, 0])
        difference() {
            spur_gear(
                mod=MOD, teeth=P1_T,
                pressure_angle=PA,
                thickness=GFW,
                profile_shift=0,
                backlash=BACKLASH/2,
                helical=HELIX_ANGLE,
                herringbone=true,
                gear_spin=planet_spin0_i + PLANET_SELF
            );
            // Pin bore — planet spins freely on shoulder pin
            cylinder(h=GFW+2, d=pin_bore_d, center=true);
        }
    }
}

// ============================================================
// CARRIER1 — FULL print-in-place cage
//   Bottom plate + pins + top plate + male hex boss = ONE fused piece
//   Planets captured on pins with PIP clearance (spin freely)
//   Everything prints as a single unit
// ============================================================
LIP_DEPTH = 0.6;
LIP_ID = BEARING_ID;

module carrier1() {
    car_r = S1_ORB + PIN_D/2 + CAR_PAD;  // Fix 5: CAR_PAD=1.5 (was +2)
    bearing_bore = BEARING_OD + 2*PIP_TOL;

    // ---- BOTTOM PLATE (white) — toggled by SHOW_BOT_PLATE ----
    if (SHOW_BOT_PLATE) {
        color("white", 0.9)
        translate([0, 0, CARRIER_BOT_Z + CARRIER_T/2])
        difference() {
            cylinder(h=CARRIER_T, r=car_r, center=true);
            cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
        }
        // Bottom plate lip (inner face, retains bearing)
        color("white")
        translate([0, 0, CARRIER_BOT_Z + CARRIER_T - LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
            cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
        }
    }

    // ---- TOP PLATE (sienna) ----
    color("sienna", 0.9)
    translate([0, 0, CARRIER_TOP_Z + CARRIER_T/2])
    difference() {
        cylinder(h=CARRIER_T, r=car_r, center=true);
        cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
    }
    // Top plate lip (inner face, retains bearing)
    color("sienna")
    translate([0, 0, CARRIER_TOP_Z + LIP_DEPTH/2])
    difference() {
        cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
        cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
    }

    // ---- PINS (fused to both plates, continuous print) ----
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = PLANET_ANGLES[i];
        current_orbit = orbit_angle_i + CARRIER_DEG;
        px = S1_ORB * cos(current_orbit);
        py = S1_ORB * sin(current_orbit);

        color("silver")
        translate([px, py, 0])
        cylinder(h=GFW + 2*CARRIER_T + 2*AXIAL_GAP, d=PIN_D, center=true);
    }

    // NOTE: Hex boss removed — replaced by compound carrier in full_assembly.scad
    // The compound carrier fuses Carrier1 top plate with Sun2 gear teeth directly.
}

// ============================================================
// B-PINION — lime green, hex keyed to B-shaft, SPUR (matches ext ring)
// ============================================================
module b_pinion() {
    translate([DRIVE_CD, 0, 0])
    color("limegreen")
    difference() {
        spur_gear(
            mod=EXT_MOD, teeth=BPIN_T,
            pressure_angle=PA,
            thickness=EXT_GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            gear_spin=90-180/BPIN_T + BPIN_DEG
        );
        // Hex bore for B-shaft
        linear_extrude(EXT_GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// SHAFTS
// ============================================================
module shafts() {
    SHAFT_LEN = GFW + 2*CARRIER_T + 2*AXIAL_GAP + 10;

    // A-shaft (red) — through center
    color("red", 0.5)
    linear_extrude(SHAFT_LEN, center=true)
    hex_profile(SHAFT_D);

    // B-shaft (green) — at drive CD
    color("green", 0.5)
    translate([DRIVE_CD, 0, 0])
    linear_extrude(SHAFT_LEN, center=true)
    hex_profile(SHAFT_D);
}

// ============================================================
// BEARINGS
// ============================================================
module bearings() {
    // Carrier1 bearing on A-shaft (in bottom plate)
    translate([0, 0, CARRIER_BOT_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, BEARING_ID, BEARING_OD);

    // Carrier1 bearing on A-shaft (in top plate)
    translate([0, 0, CARRIER_TOP_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, BEARING_ID, BEARING_OD);
}

// ============================================================
// ASSEMBLY
// ============================================================

module stage1_assembly() {
    // Group 1: Carrier cage (PIP unit — plates + pins + planets + bearings)
    translate([0, 0, -EXPLODE * 1]) {
        if (SHOW_CARRIER)  carrier1();
        if (SHOW_PLANETS)  planets();
        if (SHOW_BEARINGS) bearings();
    }
    // Group 2: Sun gear (slides onto shaft)
    if (SHOW_SUN)      translate([0, 0,  EXPLODE * 1])   sun1();
    // Group 3: Ring gear (slides over from outside)
    if (SHOW_RING)     translate([0, 0,  EXPLODE * 2])   ring1();
    // Group 4: B-pinion (on B-shaft)
    if (SHOW_BPINION)  translate([0, 0,  EXPLODE * 2])   b_pinion();
    // Shafts stay fixed as reference
    if (SHOW_SHAFTS)   shafts();
    // Thrust washers
    if (SHOW_WASHERS)  stage1_washers();
}

// Cross-section
if (CROSS_SECTION) {
    difference() {
        stage1_assembly();
        translate([0, -100, -50]) cube([200, 200, 200]);
    }
} else {
    stage1_assembly();
}
