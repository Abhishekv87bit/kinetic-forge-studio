// ============================================================
// 2-STAGE PLANETARY DIFFERENTIAL — FULL ASSEMBLY v3
// Compound Carrier (Carrier1 top + Sun2 integral)
// Carrier2-Spool (Carrier2 top + spool fused)
// 3 parallel input shafts → differential output → spool
// Oriented: A-shaft along X-axis, mounted on YZ plane
// ============================================================
//
// v4 CHANGES (from v3):
//   1. Spool redesign: bottom flange = carrier plate, no flat disc
//   2. Thread anchor hole on spool barrel circumference
//   3. Thread starts from barrel surface (not below center)
//
// v3 CHANGES (from v2):
//   1. Orientation: entire assembly rotated so A-shaft || X-axis
//   2. Compression: hub+bridge merged, inter-stage gap eliminated
//      → Z-stack 30.5mm → 28.5mm (saved 2.0mm)
//
// v2 CHANGES (from v1):
//   Fix 1: A-shaft bore corrected (was 5.7mm < hex 5.77mm → now 6.47mm)
//   Fix 2-3: SUN2_HUB_H 3→2, INTER_STAGE_GAP 0.4→0.2
//   Fix 4: Proper bearing_bushing between compound ↔ Carrier2
//   Fix 5: Carrier2 top plate fused with spool (no output stub, no gap)
//   Fix 6: SPOOL_H 8→6
//
// KINEMATIC CHAIN:
//   A-shaft (red)   ──HEX──▶ Sun1 ──mesh──▶ Planet1 ──pin──▶ Carrier1
//   B-shaft (green)  ──HEX──▶ Pinion1 ──mesh──▶ Ring1(ext) ═══ Ring1(int) ──mesh──▶ Planet1
//
//   Carrier1 top plate ═══ CompoundCarrier (fused Sun2 herringbone teeth)
//                          ──mesh──▶ Planet2 ──pin──▶ Carrier2
//
//   C-shaft (blue)   ──HEX──▶ Pinion2 ──mesh──▶ Ring2(ext) ═══ Ring2(int) ──mesh──▶ Planet2
//
//   Carrier2 top plate ═══ Spool (fused) ──▶ Thread ──▶ Pixel
//
// CONNECTION AUDIT:
//
// Part                Interface      Type           Mates With
// ────────────────────────────────────────────────────────────
// Sun1 bore           hex bore       HEX KEYED      A-shaft (torque)
// Ring1               free-floating  NONE           (driven by planets + B-pinion)
// B-pinion bore       hex bore       HEX KEYED      B-shaft (torque)
// Carrier1 bot        bearing bore   BEARING        A-shaft (decoupled)
// Carrier1 pins       fused          PIP FUSED      bot plate ↔ compound plate
// CompoundCarrier     fused plate    INTEGRAL       Carrier1 top + Sun2 teeth
// CompoundCarrier bore round bore    BEARING        A-shaft (decoupled)
// Compound hub OD     round journal  BEARING        Carrier2 bot plate
// Ring2               free-floating  NONE           (driven by planets + C-pinion)
// C-pinion bore       hex bore       HEX KEYED      C-shaft (torque)
// Carrier2 bot        journal bore   BEARING        Compound hub journal
// Carrier2-Spool      bearing bore   BEARING        A-shaft (decoupled)
// Carrier2-Spool      fused          INTEGRAL       top plate + spool barrel
// Planets             pin bore       PIP CLEARANCE  Carrier pins (captured)
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// ============================================================
// ANIMATION
// ============================================================
/* [Animation] */
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_ANIMATION = true;  // true = use $t, false = MANUAL_POSITION

/* [Inputs] */
A_INPUT = 0; // [0:1:360] A-shaft → Sun1
B_INPUT = 0; // [0:1:360] B-shaft → Ring1 via B-pinion
C_INPUT = 0; // [0:1:360] C-shaft → Ring2 via C-pinion

// ============================================================
// VISIBILITY TOGGLES
// ============================================================
/* [Stage 1] */
SHOW_SUN1       = true;
SHOW_RING1      = true;
SHOW_PLANETS1   = true;
SHOW_CAR1_BOT   = true;   // Carrier1 bottom plate
SHOW_BPINION    = true;

/* [Compound] */
SHOW_COMPOUND   = true;    // Compound carrier (Carrier1 top + Sun2)

/* [Stage 2] */
SHOW_RING2      = true;
SHOW_PLANETS2   = true;
SHOW_CAR2_BOT   = true;   // Carrier2 bottom plate
SHOW_CPINION    = true;

/* [Output] */
SHOW_CAR2_SPOOL = true;   // Fused Carrier2 top + spool
SHOW_THREAD     = true;
SHOW_PIXEL      = true;

/* [Infrastructure] */
SHOW_SHAFTS     = true;
SHOW_BEARINGS   = true;
SHOW_WASHERS    = true;
SHOW_ENVELOPE   = false;

/* [Options] */
CROSS_SECTION   = false;
EXPLODE         = 0;  // [0:0.5:30]
SIMPLE_GEO      = false;  // Use cylinders instead of gear teeth (faster preview)
PRINT_LAYOUT    = false;  // Lay-flat print preview — all parts spread out on XY plane

// ============================================================
// PARAMETERS — defined ONCE, shared across both stages
// ============================================================
MOD         = 1.0;       // Internal planetary module
EXT_MOD     = 1.5;       // External ring teeth module
PA          = 20;        // Pressure angle
HELIX_ANGLE = 20;        // Herringbone helix angle (internal mesh)
GFW         = 6;         // Gear face width
EXT_GFW     = 6;         // External gear face width
CARRIER_T   = 2;         // Carrier plate thickness
PIN_D       = 2;         // Planet pin diameter
CAR_PAD     = 1.5;       // Carrier plate radial pad beyond planet pins
THRUST_WASHER_T = 0.5;  // PTFE thrust washer thickness (mm)
AXIAL_GAP   = 0.2 + THRUST_WASHER_T;  // 0.7mm: 0.2 clearance + 0.5 washer
RING_WALL   = 1.5;       // Ring backing (ext root margin 0.375mm)
N_PLANETS   = 3;
BACKLASH    = 0.21;

// Stage 1: S1 + 2*P1 = R1
S1_T = 13;  P1_T = 8;  R1_T = 29;
// Stage 2: S2 + 2*P2 = R2 (mirrors Stage 1 for parts commonality)
S2_T = 13;  P2_T = 8;  R2_T = 29;
// External teeth (both rings identical)
EXT_T  = 26;
BPIN_T = 8;    // B-shaft pinion teeth
CPIN_T = 8;    // C-shaft pinion teeth

SHAFT_D       = 5;       // Hex across-flats
PIP_TOL       = 0.35;
BEARING_WALL  = 1.5;

// Spool (fused with Carrier2 top plate)
SPOOL_R   = 8;
SPOOL_H   = 6;            // v2: was 8, reduced for compactness
FLANGE_R  = SPOOL_R + 3;  // = 11
FLANGE_T  = 1.5;
THREAD_LEN = 40;
PIXEL_W   = 12;
PIXEL_H   = 3;

$fn = 64;

// ============================================================
// ASSERTIONS
// ============================================================
assert(S1_T + 2*P1_T == R1_T, str("Stage1: S+2P!=R: ", S1_T, "+", 2*P1_T, "!=", R1_T));
assert(S2_T + 2*P2_T == R2_T, str("Stage2: S+2P!=R: ", S2_T, "+", 2*P2_T, "!=", R2_T));

// ============================================================
// DERIVED VALUES — STAGE 1
// ============================================================
S1_ORB = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                   profile_shift1=0, profile_shift2=0);
DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=BPIN_T,
                     profile_shift1=0, profile_shift2=0);

R1_ROOT_R    = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING1_INNER_R = R1_ROOT_R + RING_WALL;
EXT_OUTER_R  = outer_radius(mod=EXT_MOD, teeth=EXT_T);

// Planet phasing — Stage 1 (from BOSL2 gears.scad:3685-3699)
S1_QUANT = 360 / (S1_T + R1_T);
S1_PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    S1_QUANT * round(i * 360 / N_PLANETS / S1_QUANT)
];
S1_RING_SPIN0 = 180/R1_T * (1 - (S1_T % 2));
S1_PLANET_SPINS0 = [for (ang = S1_PLANET_ANGLES)
    (S1_T/P1_T) * (ang - 90) + 90 + ang + 180/P1_T
];

// ============================================================
// DERIVED VALUES — STAGE 2
// ============================================================
S2_ORB = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                   profile_shift1=0, profile_shift2=0);

R2_ROOT_R    = root_radius(mod=MOD, teeth=R2_T, internal=true);
RING2_INNER_R = R2_ROOT_R + RING_WALL;

// Planet phasing — Stage 2
S2_QUANT = 360 / (S2_T + R2_T);
S2_PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    S2_QUANT * round(i * 360 / N_PLANETS / S2_QUANT)
];
S2_RING_SPIN0 = 180/R2_T * (1 - (S2_T % 2));
S2_PLANET_SPINS0 = [for (ang = S2_PLANET_ANGLES)
    (S2_T/P2_T) * (ang - 90) + 90 + ang + 180/P2_T
];

// ============================================================
// SHAFT / BEARING
// ============================================================
HEX_R      = SHAFT_D / 2;
HEX_CIRC_R = SHAFT_D / (2 * cos(30));  // ~2.887mm
BEARING_ID = HEX_CIRC_R * 2 + 2 * PIP_TOL;  // ~6.474mm
BEARING_OD = BEARING_ID + 2 * BEARING_WALL;   // ~9.474mm

// Fix 1: Correct A-shaft clearance bore (round hole that clears hex shaft)
// Old shaft_clear_d = SHAFT_D + 2*PIP_TOL = 5.7mm was SMALLER than hex circumscribed 5.774mm!
A_SHAFT_CLEAR_D = BEARING_ID;  // ~6.474mm — hex clears with PIP_TOL all around

// ============================================================
// COMPOUND CARRIER — derived geometry
// ============================================================
// v3: hub+bridge merged into single continuous shaft (no separate hub zone)
SUN2_ROOT_D   = (S2_T - 2.5) * MOD;   // ~10.5mm — shaft/journal OD
SUN2_JOURNAL_R = SUN2_ROOT_D / 2;      // ~5.25mm
SUN2_JOURNAL_OD = SUN2_ROOT_D;         // ~10.5mm
COMPOUND_JOURNAL_BORE = SUN2_JOURNAL_OD + 2*PIP_TOL;  // ~11.2mm

// ============================================================
// Z-STACK LAYOUT — all from center of Stage 1 gears = Z=0
// ============================================================
// v4 Z-stack: ~31mm total (was 28.5mm in v3, +2.5mm from thrust washers)
// AXIAL_GAP = 0.7mm (0.2 clearance + 0.5 PTFE washer) at all interfaces
// Compression: Carrier2 bot plate sits directly above compound plate
//
// Stage 1 gears centered at Z=0 (spans -GFW/2 to +GFW/2)
Z_S1 = 0;

// Carrier1 bottom plate
CAR1_BOT_Z = -GFW/2 - AXIAL_GAP - CARRIER_T;   // -5.2

// Carrier1 top plate = compound carrier base
CAR1_TOP_Z = GFW/2 + AXIAL_GAP;                  // 3.2

// Carrier2 bottom plate — directly above compound plate (AXIAL_GAP clearance)
CAR2_BOT_Z = CAR1_TOP_Z + CARRIER_T + AXIAL_GAP;           // 5.4 (was 7.4)

// Stage 2 gears centered
Z_S2 = CAR2_BOT_Z + CARRIER_T + AXIAL_GAP + GFW/2;         // 10.6 (was 12.6)

// Carrier2 top plate = spool plate (fused)
CAR2_TOP_Z = Z_S2 + GFW/2 + AXIAL_GAP;                     // 13.8 (was 15.8)

// Spool barrel extends directly from plate top (no stub, no gap)
SPOOL_BARREL_BOT_Z = CAR2_TOP_Z + CARRIER_T;                // 15.8 (was 17.8)
SPOOL_BARREL_TOP_Z = SPOOL_BARREL_BOT_Z + SPOOL_H;          // 21.8 (was 23.8)
SPOOL_CENTER_Z = SPOOL_BARREL_BOT_Z + SPOOL_H/2;            // 18.8 (was 20.8)

// Total stack check
TOTAL_STACK = SPOOL_BARREL_TOP_Z + FLANGE_T - CAR1_BOT_Z;   // ~28.5mm
assert(TOTAL_STACK < 35, str("Z-stack ", TOTAL_STACK, "mm exceeds 35mm envelope"));

// Carrier radii
S1_CAR_R = S1_ORB + PIN_D/2 + CAR_PAD;
S2_CAR_R = S2_ORB + PIN_D/2 + CAR_PAD;

// Assert compound journal fits inside carrier2 plate
assert(SUN2_JOURNAL_OD/2 < S2_CAR_R,
       str("Compound journal R=", SUN2_JOURNAL_OD/2, " > carrier2 R=", S2_CAR_R));
// Assert compound shaft passes through Carrier2 bore
assert(SUN2_JOURNAL_OD < COMPOUND_JOURNAL_BORE,
       str("Journal OD=", SUN2_JOURNAL_OD, " >= bore=", COMPOUND_JOURNAL_BORE));

// ============================================================
// KINEMATICS — 3-input differential
// ============================================================
T = USE_ANIMATION ? $t : MANUAL_POSITION;

// Shaft inputs (degrees) — all 3 active for animation demo
SUN1_DEG  = A_INPUT + T * 360;            // A-shaft: 1 full turn per cycle
RING1_DEG = B_INPUT + T * 360 * 0.5;     // B-shaft: half speed → Ring1
RING2_DEG = C_INPUT + T * 360 * 0.3;     // C-shaft: 0.3x speed → Ring2

// Stage 1 differential: carrier = (sun*Ts + ring*Tr) / (Ts+Tr)
CAR1_DEG = (SUN1_DEG * S1_T + RING1_DEG * R1_T) / (S1_T + R1_T);

// Compound carrier = Sun2 rotation
SUN2_DEG = CAR1_DEG;

// Stage 2 differential
CAR2_DEG = (SUN2_DEG * S2_T + RING2_DEG * R2_T) / (S2_T + R2_T);

// Planet self-rotations (in carrier's rotating frame)
P1_SELF = -(SUN1_DEG - CAR1_DEG) * S1_T / P1_T;
P2_SELF = -(SUN2_DEG - CAR2_DEG) * S2_T / P2_T;

// Pinion rotations (external mesh)
BPIN_DEG = -RING1_DEG * EXT_T / BPIN_T;
CPIN_DEG = -RING2_DEG * EXT_T / CPIN_T;

// ============================================================
// COLORS
// ============================================================
C_SPOOL = [0.58, 0.40, 0.22];
C_THR   = [0.82, 0.82, 0.88];
C_PIX   = [0.74, 0.60, 0.40];

// ============================================================
// HELPER MODULES
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

// Simple geometry wrappers for SIMPLE_GEO toggle
module simple_spur(mod, teeth, thickness, shaft_diam=0, profile_shift=0,
                   pressure_angle=20, helical=0, herringbone=false,
                   backlash=0, gear_spin=0) {
    if (SIMPLE_GEO) {
        or = outer_radius(mod=mod, teeth=teeth, profile_shift=profile_shift);
        difference() {
            cylinder(r=or, h=thickness, center=true, $fn=max(teeth*2, 16));
            if (shaft_diam > 0)
                cylinder(d=shaft_diam, h=thickness+1, center=true, $fn=16);
        }
    } else {
        spur_gear(mod=mod, teeth=teeth, thickness=thickness,
                  shaft_diam=shaft_diam, pressure_angle=pressure_angle,
                  helical=helical, herringbone=herringbone,
                  backlash=backlash, profile_shift=profile_shift,
                  gear_spin=gear_spin, anchor=CENTER);
    }
}

module simple_ring(mod, teeth, thickness, backing=3,
                   pressure_angle=20, profile_shift=0, helical=0,
                   herringbone=false, backlash=0, gear_spin=0) {
    if (SIMPLE_GEO) {
        rr = root_radius(mod=mod, teeth=teeth, internal=true);
        difference() {
            cylinder(r=rr + backing, h=thickness, center=true, $fn=max(teeth*2, 16));
            cylinder(r=rr, h=thickness+1, center=true, $fn=max(teeth*2, 16));
        }
    } else {
        ring_gear(mod=mod, teeth=teeth, thickness=thickness,
                  backing=backing, pressure_angle=pressure_angle,
                  profile_shift=profile_shift,
                  helical=helical, herringbone=herringbone,
                  backlash=backlash, gear_spin=gear_spin, anchor=CENTER);
    }
}

// ============================================================
// SUN1 — red, hex keyed to A-shaft, HERRINGBONE
// ============================================================
module sun1() {
    translate([0, 0, Z_S1])
    color("red")
    difference() {
        simple_spur(
            mod=MOD, teeth=S1_T,
            pressure_angle=PA,
            thickness=GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            helical=HELIX_ANGLE,
            herringbone=true,
            gear_spin=SUN1_DEG
        );
        linear_extrude(GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// RING1 — blue, dual teeth (internal herringbone + external spur)
// ============================================================
module ring1() {
    translate([0, 0, Z_S1]) {
        // Internal teeth (MOD=1.0, 29T, HERRINGBONE)
        color("royalblue", 0.7)
        simple_ring(
            mod=MOD, teeth=R1_T,
            pressure_angle=PA,
            thickness=GFW,
            backing=RING_WALL,
            profile_shift=0,
            backlash=BACKLASH/2,
            helical=HELIX_ANGLE,
            herringbone=true,
            gear_spin=S1_RING_SPIN0 + RING1_DEG
        );

        // External teeth (MOD=1.5, 26T, SPUR)
        color("steelblue", 0.8)
        difference() {
            simple_spur(
                mod=EXT_MOD, teeth=EXT_T,
                pressure_angle=PA,
                thickness=EXT_GFW,
                profile_shift=0,
                backlash=BACKLASH/2,
                gear_spin=-90 + RING1_DEG
            );
            cylinder(h=EXT_GFW+2, r=RING1_INNER_R - 0.01, center=true, $fn=64);
        }
    }
}

// ============================================================
// PLANETS1 — green, on carrier1 pins, HERRINGBONE
// ============================================================
module planets1() {
    pin_bore_d = PIN_D + 2*PIP_TOL;
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = S1_PLANET_ANGLES[i];
        planet_spin0_i = S1_PLANET_SPINS0[i];
        current_orbit = orbit_angle_i + CAR1_DEG;
        px = S1_ORB * cos(current_orbit);
        py = S1_ORB * sin(current_orbit);

        translate([0, 0, Z_S1])
        color("green")
        translate([px, py, 0])
        difference() {
            simple_spur(
                mod=MOD, teeth=P1_T,
                pressure_angle=PA,
                thickness=GFW,
                profile_shift=0,
                backlash=BACKLASH/2,
                helical=HELIX_ANGLE,
                herringbone=true,
                gear_spin=planet_spin0_i + P1_SELF
            );
            cylinder(h=GFW+2, d=pin_bore_d, center=true);
        }
    }
}

// ============================================================
// CARRIER1 BOTTOM PLATE — white, bearing on A-shaft
// ============================================================
LIP_DEPTH = 1.0;       // retaining ledge height — visible step
LIP_ID = BEARING_ID;   // inner bore of lip = bearing ID (~6.47mm)
// Lip OD = bearing_bore (~10.17mm), lip ID = BEARING_ID (~6.47mm)
// Creates a visible shelf: bearing OD (~9.47mm) sits on ledge,
// shaft (~6.47mm) passes through center

module carrier1_bot_plate() {
    bearing_bore = BEARING_OD + 2*PIP_TOL;

    // Bottom plate (unchanged — white plates already have visible cutout)
    color("white", 0.9)
    translate([0, 0, CAR1_BOT_Z + CARRIER_T/2])
    difference() {
        cylinder(h=CARRIER_T, r=S1_CAR_R, center=true);
        cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
    }
    // Lip (inner face, retains bearing)
    color("white")
    translate([0, 0, CAR1_BOT_Z + CARRIER_T - LIP_DEPTH/2])
    difference() {
        cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
        cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
    }
}

// ============================================================
// CARRIER1 PINS — silver, fused between bot plate and compound plate
// ============================================================
module carrier1_pins() {
    pin_span = GFW + 2*CARRIER_T + 2*AXIAL_GAP;
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = S1_PLANET_ANGLES[i];
        current_orbit = orbit_angle_i + CAR1_DEG;
        px = S1_ORB * cos(current_orbit);
        py = S1_ORB * sin(current_orbit);

        color("silver")
        translate([px, py, Z_S1])
        cylinder(h=pin_span, d=PIN_D, center=true);
    }
}

// ============================================================
// COMPOUND CARRIER — orchid
// Carrier1 top plate fused with Sun2 herringbone gear
// v3: hub+bridge merged into single continuous shaft from plate to gear
// Shaft passes through Carrier2 bot plate bore (journal bearing)
// ============================================================
module compound_carrier() {
    bearing_bore = BEARING_OD + 2*PIP_TOL;

    // ---- TOP PLATE (Carrier1 top) ----
    // Bearing pushed from Stage 1 (bottom) face — open bore visible from gear side
    // Lip on TOP face (shaft side) — retains bearing, hidden behind shaft
    color("orchid", 0.9)
    translate([0, 0, CAR1_TOP_Z + CARRIER_T/2])
    difference() {
        cylinder(h=CARRIER_T, r=S1_CAR_R, center=true);
        cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
    }
    // Lip on top (shaft) face — bearing retained here
    color("orchid")
    translate([0, 0, CAR1_TOP_Z + CARRIER_T - LIP_DEPTH/2])
    difference() {
        cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
        cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
    }

    // ---- CONTINUOUS SHAFT (plate top → gear bottom) ----
    // v3: single cylinder replaces separate hub + bridge
    // Passes through: AXIAL_GAP + Carrier2 bot plate + AXIAL_GAP
    // Journal bearing surface = where shaft overlaps Carrier2 bore
    shaft_bottom_z = CAR1_TOP_Z + CARRIER_T;   // 5.2
    gear_bottom_z = Z_S2 - GFW/2;               // 7.6
    shaft_h = gear_bottom_z - shaft_bottom_z;    // 2.4mm

    color("orchid", 0.85)
    translate([0, 0, shaft_bottom_z + shaft_h/2])
    difference() {
        cylinder(h=shaft_h, d=SUN2_JOURNAL_OD, center=true, $fn=64);
        cylinder(h=shaft_h+1, d=A_SHAFT_CLEAR_D, center=true, $fn=64);
    }

    // ---- SUN2 GEAR TEETH (herringbone, centered at Z_S2) ----
    color("orchid")
    translate([0, 0, Z_S2])
    difference() {
        simple_spur(
            mod=MOD, teeth=S2_T,
            pressure_angle=PA,
            thickness=GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            helical=HELIX_ANGLE,
            herringbone=true,
            gear_spin=SUN2_DEG
        );
        cylinder(h=GFW+2, d=A_SHAFT_CLEAR_D, center=true, $fn=64);
    }

    // Solid hub through gear zone (fills inside teeth to root diameter)
    color("orchid", 0.7)
    translate([0, 0, Z_S2])
    difference() {
        cylinder(h=GFW, d=SUN2_ROOT_D, center=true, $fn=64);
        cylinder(h=GFW+1, d=A_SHAFT_CLEAR_D, center=true, $fn=64);
    }
}

// ============================================================
// RING2 — blue, dual teeth (internal herringbone + external spur)
// ============================================================
module ring2() {
    translate([0, 0, Z_S2]) {
        // Internal teeth (MOD=1.0, 29T, HERRINGBONE)
        color("royalblue", 0.7)
        simple_ring(
            mod=MOD, teeth=R2_T,
            pressure_angle=PA,
            thickness=GFW,
            backing=RING_WALL,
            profile_shift=0,
            backlash=BACKLASH/2,
            helical=HELIX_ANGLE,
            herringbone=true,
            gear_spin=S2_RING_SPIN0 + RING2_DEG
        );

        // External teeth (MOD=1.5, 26T, SPUR)
        color("steelblue", 0.8)
        difference() {
            simple_spur(
                mod=EXT_MOD, teeth=EXT_T,
                pressure_angle=PA,
                thickness=EXT_GFW,
                profile_shift=0,
                backlash=BACKLASH/2,
                gear_spin=-90 + RING2_DEG
            );
            cylinder(h=EXT_GFW+2, r=RING2_INNER_R - 0.01, center=true, $fn=64);
        }
    }
}

// ============================================================
// PLANETS2 — yellowgreen, on carrier2 pins, HERRINGBONE
// ============================================================
module planets2() {
    pin_bore_d = PIN_D + 2*PIP_TOL;
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = S2_PLANET_ANGLES[i];
        planet_spin0_i = S2_PLANET_SPINS0[i];
        current_orbit = orbit_angle_i + CAR2_DEG;
        px = S2_ORB * cos(current_orbit);
        py = S2_ORB * sin(current_orbit);

        translate([0, 0, Z_S2])
        color("yellowgreen")
        translate([px, py, 0])
        difference() {
            simple_spur(
                mod=MOD, teeth=P2_T,
                pressure_angle=PA,
                thickness=GFW,
                profile_shift=0,
                backlash=BACKLASH/2,
                helical=HELIX_ANGLE,
                herringbone=true,
                gear_spin=planet_spin0_i + P2_SELF
            );
            cylinder(h=GFW+2, d=pin_bore_d, center=true);
        }
    }
}

// ============================================================
// CARRIER2 — bottom plate + pins only
//   Bottom plate rides on compound carrier journal
//   Pins fused between bottom plate and carrier2-spool
// ============================================================
module carrier2() {
    pin_span = GFW + 2*CARRIER_T + 2*AXIAL_GAP;

    // ---- BOTTOM PLATE — rides on compound journal (unchanged) ----
    if (SHOW_CAR2_BOT) {
        color("white", 0.9)
        translate([0, 0, CAR2_BOT_Z + CARRIER_T/2])
        difference() {
            cylinder(h=CARRIER_T, r=S2_CAR_R, center=true);
            cylinder(h=CARRIER_T+1, d=COMPOUND_JOURNAL_BORE, center=true);
        }
        // Bottom plate lip (inner face, retains on journal)
        color("white")
        translate([0, 0, CAR2_BOT_Z + CARRIER_T - LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=COMPOUND_JOURNAL_BORE, center=true);
            cylinder(h=LIP_DEPTH+1, d=COMPOUND_JOURNAL_BORE - 2*1.0, center=true);
        }
    }

    // ---- PINS (fused to bottom plate and carrier2-spool) ----
    for (i = [0:N_PLANETS-1]) {
        orbit_angle_i = S2_PLANET_ANGLES[i];
        current_orbit = orbit_angle_i + CAR2_DEG;
        px = S2_ORB * cos(current_orbit);
        py = S2_ORB * sin(current_orbit);

        color("silver")
        translate([px, py, Z_S2])
        cylinder(h=pin_span, d=PIN_D, center=true);
    }
}

// ============================================================
// CARRIER2-SPOOL — sienna/brown, ONE spool-shaped piece
// v4: No flat disc — bottom flange IS the carrier plate
// Bottom flange (R=S2_CAR_R) → barrel (R=SPOOL_R) → top flange (R=FLANGE_R)
// Planet pins attach to bottom flange. Bearing bore through center.
// Thread anchor hole on barrel circumference face.
// ============================================================
module carrier2_spool() {
    bearing_bore = BEARING_OD + 2*PIP_TOL;
    spool_inner = SPOOL_R - 2;  // barrel inner radius (thread wrap space)

    // ---- BOTTOM FLANGE (= carrier2 top plate) ----
    // Bearing pushed from Stage 2 (bottom) face — open bore visible from gear side
    // Lip on TOP face (barrel side) — retains bearing, hidden behind barrel
    color("peru", 0.9)
    translate([0, 0, CAR2_TOP_Z + CARRIER_T/2])
    difference() {
        cylinder(h=CARRIER_T, r=S2_CAR_R, center=true);
        cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
    }
    // Lip on top (barrel) face — bearing retained here
    color("peru")
    translate([0, 0, CAR2_TOP_Z + CARRIER_T - LIP_DEPTH/2])
    difference() {
        cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
        cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
    }

    // ---- SPOOL BARREL (extends from bottom flange top) ----
    color(C_SPOOL)
    translate([0, 0, SPOOL_CENTER_Z])
    difference() {
        cylinder(r=SPOOL_R, h=SPOOL_H, center=true);
        cylinder(r=spool_inner, h=SPOOL_H+1, center=true);
        // Thread anchor hole — blind hole on +X side only (thread enters here)
        translate([SPOOL_R - 1, 0, 0])
        rotate([0, 90, 0])
        cylinder(d=1.0, h=3, center=true, $fn=16);
    }

    // ---- TOP FLANGE ----
    color(C_SPOOL)
    translate([0, 0, SPOOL_BARREL_TOP_Z - FLANGE_T/2])
    difference() {
        cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
        cylinder(r=spool_inner, h=FLANGE_T+1, center=true);
    }
}

// ============================================================
// B-PINION — limegreen, hex keyed to B-shaft, SPUR
// ============================================================
module b_pinion() {
    translate([DRIVE_CD, 0, Z_S1])
    color("limegreen")
    difference() {
        simple_spur(
            mod=EXT_MOD, teeth=BPIN_T,
            pressure_angle=PA,
            thickness=EXT_GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            gear_spin=90-180/BPIN_T + BPIN_DEG
        );
        linear_extrude(EXT_GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// C-PINION — cyan, hex keyed to C-shaft, SPUR
// Positioned at 90° from B-pinion (B on +X, C on +Y)
// ============================================================
module c_pinion() {
    translate([0, DRIVE_CD, Z_S2])
    color("cyan")
    difference() {
        simple_spur(
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
// THREAD — starts at anchor hole, wraps 360° + 90° more, then falls down
// Anchor hole at [SPOOL_R, 0, SPOOL_CENTER_Z] (+X side of barrel)
// 1. Start at anchor (0°, +X)
// 2. Full 360° wrap around barrel (laps the anchor point)
// 3. Continue 90° more past anchor (total 450°, exits at +Y)
// 4. Falls straight down from exit point
// Internal -X = world -Z = gravity (after rotate([0,-90,0]))
// ============================================================
THREAD_TOTAL_ANGLE = 450;   // 360° full lap + 90° past anchor
module thread_line() {
    thread_d = 0.6;
    wrap_pitch_per_turn = thread_d * 1.5;  // Z-rise per 360° to avoid overlap
    total_z_rise = (THREAD_TOTAL_ANGLE / 360) * wrap_pitch_per_turn;

    // 450° wrap on barrel surface starting at anchor hole
    color(C_THR)
    for (a = [0 : 5 : THREAD_TOTAL_ANGLE - 5]) {
        frac1 = a / 360;   // fractional turns for Z-rise
        frac2 = (a + 5) / 360;
        hull() {
            translate([SPOOL_R * cos(a), SPOOL_R * sin(a),
                       SPOOL_CENTER_Z + frac1 * wrap_pitch_per_turn])
            sphere(d=thread_d, $fn=8);
            translate([SPOOL_R * cos(a+5), SPOOL_R * sin(a+5),
                       SPOOL_CENTER_Z + frac2 * wrap_pitch_per_turn])
            sphere(d=thread_d, $fn=8);
        }
    }

    // Exit point: at 450° = 90° position = +Y side
    // [0, SPOOL_R, SPOOL_CENTER_Z + total_z_rise]
    exit_x = SPOOL_R * cos(THREAD_TOTAL_ANGLE);  // cos(450)=cos(90)=0
    exit_y = SPOOL_R * sin(THREAD_TOTAL_ANGLE);  // sin(450)=sin(90)=SPOOL_R
    exit_z = SPOOL_CENTER_Z + total_z_rise;

    // Drop straight down from exit: internal -X = world -Z = gravity
    color(C_THR)
    hull() {
        translate([exit_x, exit_y, exit_z])
        sphere(d=thread_d, $fn=8);
        translate([exit_x - THREAD_LEN, exit_y, exit_z])
        sphere(d=thread_d, $fn=8);
    }
}

// ============================================================
// SHAFTS — 3 parallel hex shafts
// ============================================================
A_SHAFT_EXTEND = TOTAL_STACK * 0.5;  // extend beyond each end by half the stack
module shafts() {
    shaft_bot = CAR1_BOT_Z - A_SHAFT_EXTEND;
    shaft_top = SPOOL_BARREL_TOP_Z + FLANGE_T + A_SHAFT_EXTEND;
    shaft_len = shaft_top - shaft_bot;
    shaft_mid_z = (shaft_bot + shaft_top) / 2;

    // A-shaft (red) — center, extends well beyond both ends of the unit
    color("red", 0.5)
    translate([0, 0, shaft_mid_z])
    linear_extrude(shaft_len, center=true)
    hex_profile(SHAFT_D);

    // B-shaft (green) — at drive CD, Stage 1 zone only
    b_len = EXT_GFW + 10;
    color("green", 0.5)
    translate([DRIVE_CD, 0, Z_S1])
    linear_extrude(b_len, center=true)
    hex_profile(SHAFT_D);

    // C-shaft (blue) — at 90° from B-shaft (+Y axis), Stage 2 zone only
    c_len = EXT_GFW + 10;
    color("blue", 0.5)
    translate([0, DRIVE_CD, Z_S2])
    linear_extrude(c_len, center=true)
    hex_profile(SHAFT_D);
}

// ============================================================
// BEARINGS — all locations
// Fix 4: Proper bearing_bushing for compound↔Carrier2 journal
// ============================================================
module bearings_all() {
    // Carrier1 bottom plate — A-shaft bearing
    translate([0, 0, CAR1_BOT_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, BEARING_ID, BEARING_OD);

    // Compound carrier (Carrier1 top plate) — A-shaft bearing
    translate([0, 0, CAR1_TOP_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, BEARING_ID, BEARING_OD);

    // Carrier2 bottom plate — journal bearing on compound hub
    // Fix 4: proper bearing_bushing (was inline semi-transparent ring)
    translate([0, 0, CAR2_BOT_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, SUN2_JOURNAL_OD, COMPOUND_JOURNAL_BORE);

    // Carrier2-Spool (top plate) — A-shaft bearing
    translate([0, 0, CAR2_TOP_Z + CARRIER_T/2])
    bearing_bushing(CARRIER_T, BEARING_ID, BEARING_OD);
}

// ============================================================
// THRUST WASHERS — all 6 rotating interfaces
// ============================================================
module thrust_washers_all() {
    // Washer OD/ID per interface:
    // Carrier plates: ID=bearing bore, OD=carrier radius
    // Sun-carrier: ID=A-shaft clear, OD=compound journal
    // Spool-carrier: ID=bearing bore, OD=spool flange
    bearing_bore_d = BEARING_OD + 2*PIP_TOL;

    // 1. Carrier1 bot plate ↔ Ring1 bottom face
    //    Sits between carrier plate inner face and ring gear face
    translate([0, 0, CAR1_BOT_Z + CARRIER_T + THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=S1_CAR_R*2);

    // 2. Carrier1 top (compound) plate ↔ Ring1 top face
    translate([0, 0, CAR1_TOP_Z - THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=S1_CAR_R*2);

    // 3. Carrier2 bot plate ↔ Ring2 bottom face
    translate([0, 0, CAR2_BOT_Z + CARRIER_T + THRUST_WASHER_T/2])
    thrust_washer(id=COMPOUND_JOURNAL_BORE, od=S2_CAR_R*2);

    // 4. Carrier2 top (spool) plate ↔ Ring2 top face
    translate([0, 0, CAR2_TOP_Z - THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=S2_CAR_R*2);

    // 5. Sun1 hub ↔ Carrier1 bot bore (small washer on A-shaft)
    translate([0, 0, -GFW/2 - THRUST_WASHER_T/2])
    thrust_washer(id=A_SHAFT_CLEAR_D, od=BEARING_OD);

    // 6. Spool base ↔ Carrier2 top plate
    translate([0, 0, SPOOL_BARREL_BOT_Z - THRUST_WASHER_T/2])
    thrust_washer(id=bearing_bore_d, od=SPOOL_R*2);
}

// ============================================================
// ENVELOPE — 50mm ghost box
// ============================================================
module envelope() {
    total_h = SPOOL_BARREL_TOP_Z + FLANGE_T - CAR1_BOT_Z;
    mid_z = (CAR1_BOT_Z + SPOOL_BARREL_TOP_Z + FLANGE_T) / 2;
    %translate([0, 0, mid_z])
    cube([50, 50, total_h + 4], center=true);
}

// ============================================================
// FULL ASSEMBLY — orchestrator with explode groups
// ============================================================
module full_assembly() {
    // Group 0: Carrier1 bottom plate (rotates with carrier1)
    translate([0, 0, -EXPLODE * 2])
    rotate([0, 0, CAR1_DEG]) {
        if (SHOW_CAR1_BOT) carrier1_bot_plate();
    }

    // Group 1: Stage 1 gears + carrier1 pins
    translate([0, 0, -EXPLODE * 1]) {
        if (SHOW_SUN1)     sun1();
        if (SHOW_RING1)    ring1();
        if (SHOW_PLANETS1) planets1();
        carrier1_pins();
    }

    // Group 2: Compound carrier (rotates with carrier1)
    rotate([0, 0, CAR1_DEG])
    if (SHOW_COMPOUND) compound_carrier();

    // Group 3: Stage 2 gears
    translate([0, 0, EXPLODE * 1]) {
        if (SHOW_RING2)    ring2();
        if (SHOW_PLANETS2) planets2();
    }

    // Group 4: Carrier2 bottom plate + pins (rotates with carrier2)
    translate([0, 0, EXPLODE * 2])
    rotate([0, 0, CAR2_DEG])
    carrier2();

    // Group 5: Carrier2-Spool + thread (rotates with carrier2)
    translate([0, 0, EXPLODE * 3])
    rotate([0, 0, CAR2_DEG]) {
        if (SHOW_CAR2_SPOOL) carrier2_spool();
        if (SHOW_THREAD)     thread_line();
    }

    // Pinions — fixed at true position (not exploded)
    if (SHOW_BPINION) b_pinion();
    if (SHOW_CPINION) c_pinion();

    // Infrastructure — always at true position
    if (SHOW_SHAFTS)   shafts();
    if (SHOW_BEARINGS) bearings_all();
    if (SHOW_WASHERS)  thrust_washers_all();
    if (SHOW_ENVELOPE) envelope();
}

// ============================================================
// ORIENTED ASSEMBLY — A-shaft along X-axis, mounted on YZ plane
// v3: rotate so internal Z-axis maps to world X-axis
// ============================================================
module oriented_assembly() {
    rotate([0, -90, 0])   // Z→X: A-shaft now parallel to X-axis
    full_assembly();
}

// ============================================================
// PRINT LAYOUT — all parts laid flat on XY plane, spread in grid
// Each part centered at Z=0 with its flat face down
// Grid spacing: 35mm X, 35mm Y
// ============================================================
PRINT_GRID = 40;  // spacing between parts in print layout
module print_layout() {
    bearing_bore = BEARING_OD + 2*PIP_TOL;
    pin_bore_d = PIN_D + 2*PIP_TOL;
    pin_span = GFW + 2*CARRIER_T + 2*AXIAL_GAP;

    // ---- Row 0: Carrier plates with lips and integrated pins ----

    // Carrier1 bot (white) — bearing bore + lip + 3 pins on inner face
    translate([0, 0, 0]) {
        color("white", 0.9)
        translate([0, 0, CARRIER_T/2])
        difference() {
            cylinder(h=CARRIER_T, r=S1_CAR_R, center=true);
            cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
        }
        // Retaining lip
        color("white")
        translate([0, 0, CARRIER_T - LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
            cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
        }
    }

    // Compound plate (orchid) — bearing bore + lip (printed separately from shaft/gear)
    translate([PRINT_GRID, 0, 0]) {
        color("orchid", 0.9)
        translate([0, 0, CARRIER_T/2])
        difference() {
            cylinder(h=CARRIER_T, r=S1_CAR_R, center=true);
            cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
        }
        // Retaining lip
        color("orchid")
        translate([0, 0, CARRIER_T - LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
            cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
        }
    }

    // Carrier2 bot (white) — journal bore + lip
    translate([PRINT_GRID*2, 0, 0]) {
        color("white", 0.9)
        translate([0, 0, CARRIER_T/2])
        difference() {
            cylinder(h=CARRIER_T, r=S2_CAR_R, center=true);
            cylinder(h=CARRIER_T+1, d=COMPOUND_JOURNAL_BORE, center=true);
        }
        // Retaining lip
        color("white")
        translate([0, 0, CARRIER_T - LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=COMPOUND_JOURNAL_BORE, center=true);
            cylinder(h=LIP_DEPTH+1, d=COMPOUND_JOURNAL_BORE - 2*1.0, center=true);
        }
    }

    // Carrier2-Spool (brown) — bearing bore + lip + barrel + flanges
    translate([PRINT_GRID*3, 0, 0]) {
        color("sienna", 0.9) {
            // Bottom flange (= carrier plate)
            translate([0, 0, CARRIER_T/2])
            difference() {
                cylinder(h=CARRIER_T, r=S2_CAR_R, center=true);
                cylinder(h=CARRIER_T+1, d=bearing_bore, center=true);
            }
            // Barrel
            translate([0, 0, CARRIER_T + SPOOL_H/2])
            difference() {
                cylinder(r=SPOOL_R, h=SPOOL_H, center=true);
                cylinder(r=SPOOL_R-2, h=SPOOL_H+1, center=true);
            }
            // Top flange
            translate([0, 0, CARRIER_T + SPOOL_H + FLANGE_T/2])
            cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
        }
        // Retaining lip on bottom flange
        color("sienna")
        translate([0, 0, LIP_DEPTH/2])
        difference() {
            cylinder(h=LIP_DEPTH, d=bearing_bore, center=true);
            cylinder(h=LIP_DEPTH+1, d=LIP_ID, center=true);
        }
    }

    // ---- Row 1: Sun gears (with hex bores), Ring gears ----

    // Sun1 (red) — hex bore for A-shaft
    translate([0, -PRINT_GRID, 0]) {
        color("red")
        translate([0, 0, GFW/2])
        difference() {
            simple_spur(mod=MOD, teeth=S1_T, pressure_angle=PA, thickness=GFW,
                profile_shift=0, backlash=BACKLASH/2, helical=HELIX_ANGLE,
                herringbone=true, gear_spin=0);
            linear_extrude(GFW+2, center=true) hex_profile(SHAFT_D, PIP_TOL);
        }
    }

    // Compound Sun2 gear (orchid) — hex bore + journal shaft
    translate([PRINT_GRID, -PRINT_GRID, 0]) {
        color("orchid")
        translate([0, 0, GFW/2])
        difference() {
            simple_spur(mod=MOD, teeth=S2_T, pressure_angle=PA, thickness=GFW,
                profile_shift=0, backlash=BACKLASH/2, helical=HELIX_ANGLE,
                herringbone=true, gear_spin=0);
            cylinder(h=GFW+2, d=A_SHAFT_CLEAR_D, center=true);
        }
    }

    // Ring1 (blue) — with external teeth
    translate([PRINT_GRID*2, -PRINT_GRID, 0]) {
        color("royalblue", 0.7)
        translate([0, 0, GFW/2])
        simple_ring(mod=MOD, teeth=R1_T, pressure_angle=PA, thickness=GFW,
            backing=RING_WALL, profile_shift=0, backlash=BACKLASH/2,
            helical=HELIX_ANGLE, herringbone=true, gear_spin=0);
    }

    // Ring2 (blue)
    translate([PRINT_GRID*3, -PRINT_GRID, 0]) {
        color("royalblue", 0.7)
        translate([0, 0, GFW/2])
        simple_ring(mod=MOD, teeth=R2_T, pressure_angle=PA, thickness=GFW,
            backing=RING_WALL, profile_shift=0, backlash=BACKLASH/2,
            helical=HELIX_ANGLE, herringbone=true, gear_spin=0);
    }

    // ---- Row 2: Planets (with pin bores) ----

    // 3x Planet1 (green) — with axle bore
    for (i = [0:2]) {
        translate([i * PRINT_GRID, -PRINT_GRID*2, 0]) {
            color("green")
            translate([0, 0, GFW/2])
            difference() {
                simple_spur(mod=MOD, teeth=P1_T, pressure_angle=PA, thickness=GFW,
                    profile_shift=0, backlash=BACKLASH/2, helical=HELIX_ANGLE,
                    herringbone=true, gear_spin=0);
                cylinder(h=GFW+2, d=pin_bore_d, center=true);
            }
        }
    }

    // 3x Planet2 (yellow-green) — with axle bore
    for (i = [0:2]) {
        translate([(i+3) * PRINT_GRID, -PRINT_GRID*2, 0]) {
            color("yellowgreen")
            translate([0, 0, GFW/2])
            difference() {
                simple_spur(mod=MOD, teeth=P2_T, pressure_angle=PA, thickness=GFW,
                    profile_shift=0, backlash=BACKLASH/2, helical=HELIX_ANGLE,
                    herringbone=true, gear_spin=0);
                cylinder(h=GFW+2, d=pin_bore_d, center=true);
            }
        }
    }

    // ---- Row 3: Pinions (with hex bores) ----

    // B-pinion (green) — hex bore
    translate([0, -PRINT_GRID*3, 0]) {
        color("green", 0.8)
        translate([0, 0, EXT_GFW/2])
        difference() {
            simple_spur(mod=EXT_MOD, teeth=BPIN_T, pressure_angle=PA, thickness=EXT_GFW,
                profile_shift=0, backlash=BACKLASH/2, gear_spin=0);
            linear_extrude(EXT_GFW+2, center=true) hex_profile(SHAFT_D, PIP_TOL);
        }
    }

    // C-pinion (cyan) — hex bore
    translate([PRINT_GRID, -PRINT_GRID*3, 0]) {
        color("cyan", 0.8)
        translate([0, 0, EXT_GFW/2])
        difference() {
            simple_spur(mod=EXT_MOD, teeth=CPIN_T, pressure_angle=PA, thickness=EXT_GFW,
                profile_shift=0, backlash=BACKLASH/2, gear_spin=0);
            linear_extrude(EXT_GFW+2, center=true) hex_profile(SHAFT_D, PIP_TOL);
        }
    }
    // Pins are integral to carrier plates — not shown as separate parts
}

// ============================================================
// MAIN — print layout, cross-section, or normal view
// ============================================================
if (PRINT_LAYOUT) {
    print_layout();
} else if (CROSS_SECTION) {
    difference() {
        oriented_assembly();
        // Cut plane: remove Y<0 half (reveals A-shaft along X)
        translate([-200, -200, -1]) cube([400, 200, 200]);
    }
} else {
    oriented_assembly();
}
