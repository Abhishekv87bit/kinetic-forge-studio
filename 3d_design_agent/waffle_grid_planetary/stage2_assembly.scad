// ============================================================
// STAGE 2 ASSEMBLY — PIP PROTOTYPE (v2: herringbone + fixes)
// Sun2 + Ring2(int+ext) + 3×Planet2 + Carrier2 + C-pinion
// ============================================================
// CHANGES from v1:
//   Fix 1: RING_WALL 3→1.5 (ext root truncation)
//   Fix 2: Sun2 socket outer body ROUND + 1.5mm wall (passthrough shrunk)
//   Fix 3: S2=13, P2=8, R2=29 (mirrors Stage 1, equal planet spacing)
//   Fix 4: Carrier2 bottom plate rides on Sun2 journal (not shaft bearing)
//   Fix 5: CAR_PAD 2→1.5 (carrier-ring tip margin)
//   Fix 6: AXIAL_GAP 0→0.2 (ring-carrier clearance)
//   Fix 7: Herringbone on sun/planets/ring-internal (smooth + self-centering)
//          External ring teeth + C-pinion stay SPUR
// ============================================================
// Sun2 is a coupling piece: female hex socket (bottom) receives
// Carrier1 male post, sun gear teeth (top) drive Stage 2 planets.
// Sun2 rides freely on A-shaft (round bore, clearance fit).
// Sun2 socket body outer surface = bearing journal for Carrier2 bottom plate.
// Carrier2 is a PIP cage (output to spool).
// ============================================================
//
// CONNECTION AUDIT (PIP prototype):
//
// Part             Interface      Type           Mates With
// ────────────────────────────────────────────────────────────
// Sun2 socket      hex socket (F) HEX KEYED      Carrier1 male hex post (torque in)
// Sun2 bore        round bore     CLEARANCE      A-shaft (decoupled)
// Sun2 socket OD   round journal  BEARING        Carrier2 bottom plate bore
// Ring2            free-floating  NONE           (driven by planets + C-pinion)
// C-pinion bore    hex bore       HEX KEYED      C-shaft (torque)
// Carrier2         PIP cage       FUSED          bot plate + pins + top plate (output)
// Carrier2 bot     journal bore   BEARING        Sun2 socket journal (decoupled)
// Carrier2 top     bearing bore   BEARING        A-shaft (decoupled)
// Planets          pin bore       PIP CLEARANCE  Carrier pins (captured in cage)
//
// HEX SIZES:
//   Sun2 socket hex AF = 12mm (MUST match Carrier1 COUPLING_HEX_AF)
//   Sun2 socket outer = ROUND, R = hex_circ_R(12+tol) + 1.5 = 8.83mm
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

/* [Animation] */
// Use OpenSCAD View→Animate (FPS=10, Steps=100) for live animation.
// Or use MANUAL_POSITION slider in Customizer.
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_ANIMATION = true;  // true = use $t, false = use MANUAL_POSITION

/* [Inputs] */
SUN2_INPUT = 0; // [0:1:360] from coupling tube
C_INPUT = 0;    // [0:1:360] C-shaft drives ring2

/* [Visibility] */
SHOW_SUN = true;
SHOW_RING = true;
SHOW_PLANETS = true;
SHOW_CARRIER = true;
SHOW_BOT_PLATE = true;  // toggle bottom (white) carrier plate
SHOW_CPINION = true;
SHOW_SHAFTS = true;
SHOW_BEARINGS = true;
SHOW_WASHERS = true;

/* [Options] */
CROSS_SECTION = false;
EXPLODE = 0; // [0:0.5:20]

// ============================================================
// PARAMETERS
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
SOCKET_WALL = 1.5;      // Fix 2: Sun2 socket round outer wall thickness
N_PLANETS = 3;
BACKLASH = 0.21;

// Fix 3: S2=13, P2=8, R2=29 — mirrors Stage 1 (equal spacing, parts commonality)
S2_T = 13;
P2_T = 8;
R2_T = 29;
EXT_T = 26;
CPIN_T = 8;  // C-shaft pinion (same as B-shaft pinion)

SHAFT_D = 5;
PIP_TOL = 0.35;
BEARING_WALL = 1.5;

$fn = 64;

// ============================================================
// DERIVED VALUES
// ============================================================
S2_ORB = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                   profile_shift1=0, profile_shift2=0);
DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=CPIN_T,
                     profile_shift1=0, profile_shift2=0);

R2_ROOT_R = root_radius(mod=MOD, teeth=R2_T, internal=true);
RING_INNER_R = R2_ROOT_R + RING_WALL;
EXT_OUTER_R = outer_radius(mod=EXT_MOD, teeth=EXT_T);

HEX_R = SHAFT_D / 2;
HEX_CIRC_R = SHAFT_D / (2 * cos(30));
BEARING_ID = HEX_CIRC_R * 2 + 2 * PIP_TOL;
BEARING_OD = BEARING_ID + 2 * BEARING_WALL;

// Planet phasing
QUANT = 360 / (S2_T + R2_T);
PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    QUANT * round(i * 360 / N_PLANETS / QUANT)
];
RING_SPIN0 = 180/R2_T * (1 - (S2_T % 2));  // S2=13 odd → 0
PLANET_SPINS0 = [for (ang = PLANET_ANGLES)
    (S2_T/P2_T) * (ang - 90) + 90 + ang + 180/P2_T
];

// Animation
T = USE_ANIMATION ? $t : MANUAL_POSITION;
SUN_DEG = SUN2_INPUT + T * 360;
RING_DEG = C_INPUT;

// Differential
CARRIER_DEG = (SUN_DEG * S2_T + RING_DEG * R2_T) / (S2_T + R2_T);
PLANET_SELF = -(SUN_DEG - CARRIER_DEG) * S2_T / P2_T;
CPIN_DEG = -RING_DEG * EXT_T / CPIN_T;

// Axial positions — Fix 6: AXIAL_GAP between ring faces and carrier plates
CARRIER_BOT_Z = -GFW/2 - AXIAL_GAP - CARRIER_T;
CARRIER_TOP_Z = GFW/2 + AXIAL_GAP;

// ============================================================
// SUN2 COUPLING — geometry constants
// ============================================================
COUPLING_HEX_AF = 12;              // hex across-flats (MUST match Carrier1)
SUN2_SOCKET_H = 3;                  // female hex socket depth
SUN2_SHAFT_BORE = SHAFT_D + 2*PIP_TOL;  // round bore on A-shaft (~5.7mm)

// Fix 2: Sun2 socket outer is ROUND (not hex), wall = SOCKET_WALL
// Hex pocket circumscribed R = (AF + 2*tol) / (2*cos(30))
SUN2_HEX_CIRC_R = (COUPLING_HEX_AF + 2*PIP_TOL) / (2 * cos(30));  // ~7.33mm
SUN2_JOURNAL_R = SUN2_HEX_CIRC_R + SOCKET_WALL;   // ~8.83mm
SUN2_JOURNAL_OD = SUN2_JOURNAL_R * 2;               // ~17.66mm

// Fix 4: Carrier2 bottom plate bore rides on Sun2 journal
SUN2_JOURNAL_BORE = SUN2_JOURNAL_OD + 2*PIP_TOL;   // ~18.36mm

// ============================================================
// MODULES
// ============================================================

module hex_profile(af, tol=0) {
    r = (af + 2*tol) / (2 * cos(30));
    circle(r=r, $fn=6);
}

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
// THRUST WASHERS — Stage 2 interfaces
// ============================================================
module stage2_washers() {
    car_r = S2_ORB + PIN_D/2 + CAR_PAD;
    bearing_bore_d = BEARING_OD + 2*PIP_TOL;
    journal_bore = SUN2_JOURNAL_BORE;

    // 1. Carrier2 bot plate ↔ Ring2 bottom face
    translate([0, 0, CARRIER_BOT_Z + CARRIER_T + THRUST_WASHER_T/2])
    thrust_washer(id=journal_bore, od=car_r*2);

    // 2. Carrier2 top plate ↔ Ring2 top face
    translate([0, 0, CARRIER_TOP_Z - THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=car_r*2);
}

// ============================================================
// SUN2 — magenta, HERRINGBONE gear + integrated female hex socket BELOW
// Socket outer body is ROUND (journal for Carrier2 bottom plate)
// ============================================================
module sun2() {
    // Sun2 is ONE solid piece: herringbone gear teeth + round socket sleeve.
    // spur_gear centered at Z=0 (spans -GFW/2 to +GFW/2).
    // Socket below: from Z = -GFW/2 - SUN2_SOCKET_H to Z = -GFW/2.
    // A solid hub cylinder spans the FULL height to guarantee no gaps.

    BOTTOM_Z = -GFW/2 - SUN2_SOCKET_H;
    TOP_Z = GFW/2;
    FULL_H = TOP_Z - BOTTOM_Z;  // GFW + SUN2_SOCKET_H
    sun2_root_d = (S2_T - 2.5) * MOD;  // gear root diameter for hub size

    color("magenta")
    difference() {
        union() {
            // 1. Sun gear teeth (centered at Z=0) — HERRINGBONE
            spur_gear(
                mod=MOD, teeth=S2_T,
                pressure_angle=PA,
                thickness=GFW,
                profile_shift=0,
                backlash=BACKLASH/2,
                helical=HELIX_ANGLE,
                herringbone=true,
                gear_spin=SUN_DEG
            );
            // 2. Solid hub cylinder spanning FULL height (gear + socket)
            //    Diameter = gear root so it doesn't poke through teeth
            translate([0, 0, BOTTOM_Z])
            cylinder(h=FULL_H, d=sun2_root_d, $fn=64);
            // 3. Socket outer wall — ROUND cylinder (Fix 2: was hex)
            //    Extends into gear zone by 1mm for solid overlap
            translate([0, 0, BOTTOM_Z])
            cylinder(h=SUN2_SOCKET_H + 1, r=SUN2_JOURNAL_R, $fn=64);
        }
        // A. Shaft bore through entire piece
        translate([0, 0, BOTTOM_Z - 1])
        cylinder(h=FULL_H + 2, d=SUN2_SHAFT_BORE, $fn=64);
        // B. Hex pocket cut from bottom into socket only
        translate([0, 0, BOTTOM_Z - 0.5])
        linear_extrude(SUN2_SOCKET_H + 0.5)
        hex_profile(COUPLING_HEX_AF, PIP_TOL);
    }
}

// ============================================================
// RING2 — blue, dual teeth:
//   Internal: MOD=1 herringbone (meshes with planets)
//   External: MOD=1.5 SPUR (meshes with C-pinion)
// ============================================================
module ring2() {
    // Internal teeth (MOD=1.0, 29T, HERRINGBONE)
    color("royalblue", 0.7)
    ring_gear(
        mod=MOD, teeth=R2_T,
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
        cylinder(h=EXT_GFW+2, r=RING_INNER_R - 0.01, center=true, $fn=64);
    }
}

// ============================================================
// PLANETS — yellowgreen, on carrier pins, HERRINGBONE
// ============================================================
module planets2() {
    pin_bore_d = PIN_D + 2*PIP_TOL;  // clearance bore for pin
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = PLANET_ANGLES[i];
        planet_spin0_i = PLANET_SPINS0[i];
        current_orbit = orbit_angle_i + CARRIER_DEG;
        px = S2_ORB * cos(current_orbit);
        py = S2_ORB * sin(current_orbit);

        color("yellowgreen")
        translate([px, py, 0])
        difference() {
            spur_gear(
                mod=MOD, teeth=P2_T,
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
// CARRIER2 — FULL print-in-place cage (OUTPUT)
//   Bottom plate + pins + top plate = ONE fused piece
//   Planets captured on pins with PIP clearance (spin freely)
//   Bottom plate rides on Sun2 journal (Fix 4)
//   Top plate rides on A-shaft bearing (standard)
// ============================================================
LIP_DEPTH = 0.6;
LIP_ID = BEARING_ID;

module carrier2() {
    car_r = S2_ORB + PIN_D/2 + CAR_PAD;  // Fix 5: CAR_PAD=1.5 (was +2)
    bearing_bore = BEARING_OD + 2*PIP_TOL;

    // Fix 4: Bottom plate bore rides on Sun2 journal (round)
    // No longer a wide passthrough — just clears the journal OD with PIP_TOL
    journal_bore = SUN2_JOURNAL_BORE;  // ~18.36mm diameter

    // ---- BOTTOM PLATE (white) — toggled by SHOW_BOT_PLATE ----
    // Bore sized to ride on Sun2 socket journal (bearing interface)
    if (SHOW_BOT_PLATE) {
        color("white", 0.9)
        translate([0, 0, CARRIER_BOT_Z + CARRIER_T/2])
        difference() {
            cylinder(h=CARRIER_T, r=car_r, center=true);
            cylinder(h=CARRIER_T+1, d=journal_bore, center=true);
        }
        // Bottom plate lip (inner face, retains on journal)
        color("white")
        translate([0, 0, CARRIER_BOT_Z + CARRIER_T - LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=journal_bore, center=true);
            cylinder(h=LIP_DEPTH+1, d=journal_bore - 2*1.0, center=true);
                // lip inset 1.0mm — catches journal shoulder
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
        px = S2_ORB * cos(current_orbit);
        py = S2_ORB * sin(current_orbit);

        color("silver")
        translate([px, py, 0])
        cylinder(h=GFW + 2*CARRIER_T + 2*AXIAL_GAP, d=PIN_D, center=true);
    }
}

// ============================================================
// C-PINION — cyan, hex keyed to C-shaft, SPUR (matches ext ring)
// ============================================================
module c_pinion() {
    translate([DRIVE_CD, 0, 0])
    color("cyan")
    difference() {
        spur_gear(
            mod=EXT_MOD, teeth=CPIN_T,
            pressure_angle=PA,
            thickness=EXT_GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            gear_spin=90-180/CPIN_T + CPIN_DEG
        );
        linear_extrude(EXT_GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// SHAFTS
// ============================================================
module shafts() {
    SHAFT_LEN = GFW + 2*CARRIER_T + 2*AXIAL_GAP + 10;

    // A-shaft (red) — through center (carrier2 rides on this via top bearing)
    color("red", 0.5)
    linear_extrude(SHAFT_LEN, center=true)
    hex_profile(SHAFT_D);

    // C-shaft (blue)
    color("blue", 0.5)
    translate([DRIVE_CD, 0, 0])
    linear_extrude(SHAFT_LEN, center=true)
    hex_profile(SHAFT_D);
}

// ============================================================
// BEARINGS
// ============================================================
module bearings2() {
    // Fix 4: Bottom bearing is Sun2 journal interface — no separate bushing needed.
    // The Sun2 socket body outer surface IS the journal, Carrier2 bottom bore IS the bearing.
    // We show a visual indicator ring for clarity.
    color("goldenrod", 0.5)
    translate([0, 0, CARRIER_BOT_Z + CARRIER_T/2])
    difference() {
        cylinder(h=CARRIER_T, d=SUN2_JOURNAL_BORE, center=true);
        cylinder(h=CARRIER_T+1, d=SUN2_JOURNAL_OD, center=true);
    }

    // Carrier2 bearing on A-shaft (top plate) — standard
    translate([0, 0, CARRIER_TOP_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, BEARING_ID, BEARING_OD);
}

// ============================================================
// ASSEMBLY
// ============================================================
module stage2_assembly() {
    // Group 1: Carrier cage (PIP unit — plates + pins + planets + bearings)
    translate([0, 0, -EXPLODE * 1]) {
        if (SHOW_CARRIER)  carrier2();
        if (SHOW_PLANETS)  planets2();
        if (SHOW_BEARINGS) bearings2();
    }
    // Group 2: Sun gear (slides onto Carrier1 hex post)
    if (SHOW_SUN)      translate([0, 0,  EXPLODE * 1])   sun2();
    // Group 3: Ring gear (slides over from outside)
    if (SHOW_RING)     translate([0, 0,  EXPLODE * 2])   ring2();
    // Group 4: C-pinion (on C-shaft)
    if (SHOW_CPINION)  translate([0, 0,  EXPLODE * 2])   c_pinion();
    // Shafts stay fixed as reference
    if (SHOW_SHAFTS)   shafts();
    // Thrust washers
    if (SHOW_WASHERS)  stage2_washers();
}

if (CROSS_SECTION) {
    difference() {
        stage2_assembly();
        translate([0, -100, -50]) cube([200, 200, 200]);
    }
} else {
    stage2_assembly();
}
