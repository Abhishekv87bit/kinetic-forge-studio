// =============================================================
// 2-STAGE PLANETARY DIFFERENTIAL — 3 Parallel Input Shafts
// PRINT-IN-PLACE — 50mm envelope
//
// KINEMATIC CHAIN:
//   A-shaft → Sun1          (Input 1)
//   B-shaft → Ring1 arm     (Input 2)
//   C-shaft → Ring2 arm     (Input 3)
//   Carrier1 → coupling → Sun2  (bridge)
//   Carrier2 = OUTPUT → spool
//
// All 3 shafts parallel along X-axis.
// Rings driven by integral arms (no external teeth/pinions).
//
// BOSL2 CONVENTION: tooth 0 center at +Y axis.
// Mesh phasing: planet angle2 = -angle1*T1/T2 + 180/T2
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

$fn = 48;

/* [Print-in-Place] */
PIP_TOL        = 0.35;   // [0.2:0.05:0.5] Gap between rotating parts (mm)

// ---- ANIMATION ----
MANUAL_POSITION = 0.25;
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL      = PIP_TOL;
BACKLASH = PIP_TOL * 0.6;

// =============================================================
// GEAR PARAMETERS — MOD 1.5 for printable teeth
// =============================================================
MOD = 1.5;
PA  = 20;

// =============================================================
// TOOTH COUNTS
// =============================================================
// Stage 1: S1 + 2*P1 = R1
S1_T = 9;   P1_T = 6;  R1_T = 21;
assert(S1_T + 2*P1_T == R1_T, "Stage1: S+2P!=R");

// Stage 2: S2 + 2*P2 = R2
S2_T = 7;   P2_T = 7;  R2_T = 21;
assert(S2_T + 2*P2_T == R2_T, "Stage2: S+2P!=R");

// Profile shifts: all zero for consistent planetary center distances
// Small tooth counts (6-9T) will have slight undercut — acceptable for FDM prototype
PS_S1 = 0;  PS_P1 = 0;
PS_S2 = 0;  PS_P2 = 0;

// Orbit radii (center distances)
ORB1 = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                 profile_shift1=PS_S1, profile_shift2=PS_P1);
ORB2 = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                 profile_shift1=PS_S2, profile_shift2=PS_P2);

// Ring gear profile shifts: 0 for 21T (above undercut limit)
PS_R1 = 0;
PS_R2 = 0;

// Planet-to-ring center distance (internal mesh)
// For a correct planetary: ORB_sun_planet should equal ORB_planet_ring
// = (R_T - P_T) * MOD / 2 for standard gears
ORB1_R_NOMINAL = (R1_T - P1_T) * MOD / 2;
ORB2_R_NOMINAL = (R2_T - P2_T) * MOD / 2;

echo("ORB1 sun-planet=", ORB1, " planet-ring nominal=", ORB1_R_NOMINAL);
echo("ORB2 sun-planet=", ORB2, " planet-ring nominal=", ORB2_R_NOMINAL);
echo("ORB1 check: sun_orbit + planet_ring should match → ", ORB1, " vs ", ORB1_R_NOMINAL);

// =============================================================
// MESH PHASING — BOSL2 tooth 0 at +Y
// =============================================================
// For external mesh: gear2 phase = -sun_angle*T_sun/T_planet + 180/T_planet
// For internal mesh (planet-ring): ring phase accounts for both being "same direction"

// Base phase offsets (at animation=0, planet0 on +X axis)
// Planet sits at angle 0 from sun center (along +X in local coords)
// Sun tooth 0 at +Y. Planet at +X needs phase to align valleys.
// Phase = 90 * T_sun/T_planet + 180/T_planet (90° because planet is at +X, tooth is at +Y)
P1_PHASE0 = 90 * S1_T / P1_T + 180 / P1_T;
P2_PHASE0 = 90 * S2_T / P2_T + 180 / P2_T;

// Ring base phase: ring tooth 0 at +Y. Planet0 at +X from center.
// Ring internal teeth mesh with planet at distance ORB from center.
// Ring phase = -(planet_orbit_angle) * ... this is complex. Compute from constraint:
// At rest position, planet0 at angle=0 (on +X), ring must have a gap aligned there.
// Ring phase = 90 * (R1_T / R1_T) ... actually for internal gear:
// The ring mesh offset = orbit_angle * R_T / R_T + 180/R_T ...
// Simplification: ring needs half-tooth offset from planet at its orbit position
R1_PHASE0 = -90 * P1_T / R1_T + 180 / R1_T;
R2_PHASE0 = -90 * P2_T / R2_T + 180 / R2_T;

echo("P1_PHASE0=", P1_PHASE0, " R1_PHASE0=", R1_PHASE0);
echo("P2_PHASE0=", P2_PHASE0, " R2_PHASE0=", R2_PHASE0);

// =============================================================
// RING GEOMETRY — ring-as-housing, no external teeth
// =============================================================
RING_WALL = 3;
R1_RR = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_OR = R1_RR + RING_WALL;

// Drive arm
ARM_W  = 4;
ARM_T  = 3;
SHAFT_GAP = 2;
BC_R   = RING_OR + SHAFT_GAP;

// =============================================================
// PHYSICAL DIMENSIONS
// =============================================================
GFW       = 8;      // gear face width
RING_FW   = 10;     // ring face width (wider for retention lips)
GAP       = 3;      // gap between stages
CARRIER_T = 3;      // carrier plate thickness
SHAFT_D   = 5;      // shaft diameter
CPLG_OD   = 8;      // coupling tube OD
CPLG_ID   = SHAFT_D + PIP_TOL*2;  // coupling bore (clears A-shaft)
PIN_D     = 3;      // planet pin diameter
HEX_AF    = 5;      // hex across-flats for keyed connections (< CPLG_OD)

// =============================================================
// 50mm ENVELOPE CHECK
// =============================================================
ENVELOPE  = 50;
assert(RING_OR * 2 <= ENVELOPE - 2, str("Ring OD ", RING_OR*2, " exceeds envelope"));
assert(BC_R + SHAFT_D/2 <= ENVELOPE/2, str("Shaft extends to ", BC_R+SHAFT_D/2, " > ", ENVELOPE/2));

echo("RING_OR=", RING_OR, " dia=", RING_OR*2);
echo("BC_R=", BC_R, " BC_edge=", BC_R + SHAFT_D/2);
echo("ORB1=", ORB1, " ORB2=", ORB2);

P1_OR = outer_radius(mod=MOD, teeth=P1_T, profile_shift=PS_P1);
P2_OR = outer_radius(mod=MOD, teeth=P2_T, profile_shift=PS_P2);
S1_OR = outer_radius(mod=MOD, teeth=S1_T, profile_shift=PS_S1);
S2_OR = outer_radius(mod=MOD, teeth=S2_T, profile_shift=PS_S2);

echo("P1_OR=", P1_OR, " P2_OR=", P2_OR);
echo("S1_OR=", S1_OR, " S2_OR=", S2_OR);

// =============================================================
// AXIAL LAYOUT
// =============================================================
S1_X = -(GAP/2 + RING_FW/2);
S2_X =  (GAP/2 + RING_FW/2);

SPOOL_GAP = 2;
SPOOL_R   = 8;
SPOOL_H   = 8;
SPOOL_X   = S2_X + RING_FW/2 + SPOOL_GAP + SPOOL_H/2;
FLANGE_R  = SPOOL_R + 3;
FLANGE_T  = 1.5;

THREAD_LEN = 40;
PIXEL_W = 12;
PIXEL_H = 3;

// B-shaft above, C-shaft to side
B_Y = 0;       B_Z = BC_R;
C_Y = BC_R;    C_Z = 0;

SHAFT_LEN = abs(S1_X) + abs(SPOOL_X) + 30;
SHAFT_MID = (S1_X + SPOOL_X) / 2;

// =============================================================
// KINEMATICS
// =============================================================
A_IN = POS * 360;
B_IN = POS * 360 * 1.13;
C_IN = POS * 360 * 0.87;

// Planetary differential: carrier = (sun*Ts + ring*Tr) / (Ts+Tr)
CAR1_A = (A_IN * S1_T + B_IN * R1_T) / (S1_T + R1_T);
SUN2_A = CAR1_A;  // coupling transfers carrier1 rotation to sun2
CAR2_A = (SUN2_A * S2_T + C_IN * R2_T) / (S2_T + R2_T);

// Planet self-rotation (in carrier's rotating frame)
// planet_self = -(carrier - sun) * Ts / Tp
P1_SELF = -(CAR1_A - A_IN) * S1_T / P1_T;
P2_SELF = -(CAR2_A - SUN2_A) * S2_T / P2_T;

echo("CAR1=", CAR1_A, " CAR2(output)=", CAR2_A);

// =============================================================
// COLORS
// =============================================================
C_SUN1  = [0.85, 0.25, 0.20];
C_SUN2  = [0.75, 0.20, 0.30];
C_RING1 = [0.95, 0.40, 0.60];
C_RING2 = [0.68, 0.62, 0.25];
C_PLN1  = [0.50, 0.75, 0.50];
C_PLN2  = [0.40, 0.65, 0.40];
C_CAR1  = [0.30, 0.50, 0.80];
C_CAR2  = [0.25, 0.42, 0.72];
C_CPLG  = [0.45, 0.65, 0.90];
C_SPOOL = [0.58, 0.40, 0.22];
C_THR   = [0.82, 0.82, 0.88];
C_PIX   = [0.74, 0.60, 0.40];
C_SHA   = [0.88, 0.30, 0.22];
C_SHB   = [0.22, 0.75, 0.30];
C_SHC   = [0.22, 0.38, 0.90];
C_PIN   = [0.65, 0.65, 0.68];
C_ARM   = [0.70, 0.50, 0.50];

// =============================================================
// CUSTOMIZER TOGGLES
// =============================================================

/* [Show / Hide] */
SHOW_SHAFTS    = true;
SHOW_SUN1      = true;
SHOW_RING1     = true;
SHOW_PLANETS1  = true;
SHOW_CARRIER1  = true;
SHOW_SUN2      = true;
SHOW_RING2     = true;
SHOW_PLANETS2  = true;
SHOW_CARRIER2  = true;
SHOW_COUPLING  = true;
SHOW_SPOOL     = true;
SHOW_THREAD    = true;
SHOW_PIXEL     = true;
SHOW_ENVELOPE  = false;

/* [Exploded View] */
EXPLODE        = 0;  // [0:0.5:40] Explode distance
FLAT_LAYOUT    = false;  // Lay all parts flat for printing

/* [Cross Section] */
CROSS_SECTION  = false;

/* [Performance] */
SIMPLE_GEO     = false;

/* [Hidden] */

EX_S1     = -EXPLODE * 2;
EX_CAR1   = -EXPLODE * 1;
EX_S2     =  EXPLODE * 1;
EX_CAR2   =  EXPLODE * 2;
EX_SPOOL  =  EXPLODE * 3;

// =============================================================
// HELPER MODULES
// =============================================================

// Hex profile for keyed connections (torque transfer)
module hex_key(af, h) {
    // af = across flats, h = height
    cylinder(d=af / cos(30), h=h, center=true, $fn=6);
}

module simple_spur(mod, teeth, thickness, shaft_diam=0, profile_shift=0,
                   pressure_angle=20, helical=0, herringbone=false,
                   slices=1, backlash=0, anchor=CENTER) {
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
                  helical=helical, herringbone=herringbone, slices=slices,
                  backlash=backlash, profile_shift=profile_shift, anchor=anchor);
    }
}

module simple_ring(mod, teeth, thickness, backing=3,
                   pressure_angle=20, profile_shift=0, helical=0,
                   herringbone=false, slices=1, backlash=0, anchor=CENTER) {
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
                  helical=helical, herringbone=herringbone, slices=slices,
                  backlash=backlash, anchor=anchor);
    }
}

// Drive arm — connects ring to B/C shaft
module drive_arm(angle, fw) {
    arm_len = BC_R - RING_OR + SHAFT_D/2;
    rotate([0, 0, angle])
    translate([RING_OR + arm_len/2 - 1, 0, 0])
    color(C_ARM)
    difference() {
        cube([arm_len + 2, ARM_W, fw], center=true);
        translate([arm_len/2 - SHAFT_D/2, 0, 0])
        cylinder(d=SHAFT_D + PIP_TOL*2, h=fw+1, center=true);
    }
}

// =============================================================
// MAIN
// =============================================================
if (CROSS_SECTION) {
    difference() {
        main();
        translate([0, 50, 0]) cube([200, 100, 200], center=true);
    }
} else {
    main();
}

module main() {
    if (FLAT_LAYOUT) {
        flat_print_layout();
    } else {
        if (SHOW_SHAFTS)    shafts();
        if (SHOW_SUN1 || SHOW_RING1 || SHOW_PLANETS1)
            translate([EX_S1, 0, 0]) stage1();
        if (SHOW_SUN2 || SHOW_RING2 || SHOW_PLANETS2)
            translate([EX_S2, 0, 0]) stage2();
        if (SHOW_CARRIER1 || SHOW_CARRIER2 || SHOW_COUPLING) carriers();
        if (SHOW_SPOOL)     translate([EX_SPOOL, 0, 0]) spool();
        if (SHOW_THREAD)    translate([EX_SPOOL, 0, 0]) thread();
        if (SHOW_PIXEL)     translate([EX_SPOOL, 0, 0]) pixel();
        if (SHOW_ENVELOPE)  envelope();
    }
}

// =============================================================
// 50mm ENVELOPE GHOST
// =============================================================
module envelope() {
    %translate([(S1_X+SPOOL_X)/2, 0, 0])
    cube([abs(SPOOL_X-S1_X)+SPOOL_H+FLANGE_T*2, ENVELOPE, ENVELOPE], center=true);
}

// =============================================================
// 3 PARALLEL SHAFTS — hex profile for torque keying
// =============================================================
module shafts() {
    // A-shaft (center) — hex for sun keying
    color(C_SHA)
    translate([SHAFT_MID, 0, 0])
    rotate([0, 90, 0]) rotate([0, 0, A_IN])
    hex_key(af=SHAFT_D, h=SHAFT_LEN);

    // B-shaft (above) — hex
    color(C_SHB)
    translate([SHAFT_MID, B_Y, B_Z])
    rotate([0, 90, 0]) rotate([0, 0, B_IN])
    hex_key(af=SHAFT_D, h=SHAFT_LEN);

    // C-shaft (side) — hex
    color(C_SHC)
    translate([SHAFT_MID, C_Y, C_Z])
    rotate([0, 90, 0]) rotate([0, 0, C_IN])
    hex_key(af=SHAFT_D, h=SHAFT_LEN);
}

// =============================================================
// STAGE 1 — Sun1 + Ring1 + 3x Planet1
// =============================================================
module stage1() {
    N_PLANETS = 3;
    translate([S1_X, 0, 0])
    rotate([0, 90, 0]) {
        // --- Sun1 on A-shaft ---
        if (SHOW_SUN1)
        color(C_SUN1) rotate([0, 0, A_IN])
        difference() {
            simple_spur(mod=MOD, teeth=S1_T, thickness=GFW,
                      pressure_angle=PA, backlash=BACKLASH,
                      profile_shift=PS_S1, anchor=CENTER);
            hex_key(af=SHAFT_D + PIP_TOL*2, h=GFW+1);
        }

        // --- Ring1 keyed to B-shaft via arm ---
        if (SHOW_RING1)
        rotate([0, 0, B_IN + R1_PHASE0]) {
            color(C_RING1)
            simple_ring(mod=MOD, teeth=R1_T, thickness=RING_FW,
                      backing=RING_WALL, pressure_angle=PA,
                      profile_shift=PS_R1,
                      backlash=BACKLASH, anchor=CENTER);
            b_local = atan2(B_Y, B_Z) - (B_IN + R1_PHASE0);
            drive_arm(b_local, RING_FW);
        }

        // --- 3x Planet1 ---
        if (SHOW_PLANETS1)
        rotate([0, 0, CAR1_A])
        for (i = [0:N_PLANETS-1]) {
            orbit_angle = i * 360 / N_PLANETS;
            rotate([0, 0, orbit_angle])
            translate([ORB1, 0, 0])
            color(C_PLN1)
            rotate([0, 0, P1_PHASE0 + P1_SELF - orbit_angle * S1_T / P1_T])
            simple_spur(mod=MOD, teeth=P1_T, thickness=GFW - PIP_TOL*2,
                      shaft_diam=PIN_D + PIP_TOL*2, pressure_angle=PA,
                      backlash=BACKLASH, profile_shift=PS_P1, anchor=CENTER);
        }
    }
}

// =============================================================
// STAGE 2 — Sun2 + Ring2 + 3x Planet2
// =============================================================
module stage2() {
    N_PLANETS = 3;
    translate([S2_X, 0, 0])
    rotate([0, 90, 0]) {
        // --- Sun2 driven by coupling (keyed hex) ---
        if (SHOW_SUN2)
        color(C_SUN2) rotate([0, 0, SUN2_A])
        difference() {
            simple_spur(mod=MOD, teeth=S2_T, thickness=GFW,
                      pressure_angle=PA, backlash=BACKLASH,
                      profile_shift=PS_S2, anchor=CENTER);
            hex_key(af=HEX_AF + PIP_TOL*2, h=GFW+1);
        }

        // --- Ring2 keyed to C-shaft via arm ---
        if (SHOW_RING2)
        rotate([0, 0, C_IN + R2_PHASE0]) {
            color(C_RING2)
            simple_ring(mod=MOD, teeth=R2_T, thickness=RING_FW,
                      backing=RING_WALL, pressure_angle=PA,
                      profile_shift=PS_R2,
                      backlash=BACKLASH, anchor=CENTER);
            c_local = atan2(C_Y, C_Z) - (C_IN + R2_PHASE0);
            drive_arm(c_local, RING_FW);
        }

        // --- 3x Planet2 ---
        if (SHOW_PLANETS2)
        rotate([0, 0, CAR2_A])
        for (i = [0:N_PLANETS-1]) {
            orbit_angle = i * 360 / N_PLANETS;
            rotate([0, 0, orbit_angle])
            translate([ORB2, 0, 0])
            color(C_PLN2)
            rotate([0, 0, P2_PHASE0 + P2_SELF - orbit_angle * S2_T / P2_T])
            simple_spur(mod=MOD, teeth=P2_T, thickness=GFW - PIP_TOL*2,
                      shaft_diam=PIN_D + PIP_TOL*2, pressure_angle=PA,
                      backlash=BACKLASH, profile_shift=PS_P2, anchor=CENTER);
        }
    }
}

// =============================================================
// CARRIERS + COUPLING
// =============================================================
LIP_H = 0.8;
LIP_W = 1.5;

module carriers() {
    CAR1_OR = ORB1 + PIN_D + 2;
    CAR2_OR = ORB2 + PIN_D + 2;
    N_PLANETS = 3;

    // --- Carrier 1 ---
    if (SHOW_CARRIER1)
    translate([EX_CAR1, 0, 0])
    translate([S1_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        // Two carrier plates sandwiching planets
        for (side = [-1, 1])
            translate([0, 0, side * (GFW/2 + CARRIER_T/2)])
            color(C_CAR1)
            difference() {
                union() {
                    cylinder(r=CAR1_OR, h=CARRIER_T, center=true);
                    // Retention lip
                    translate([0, 0, -side * (CARRIER_T/2 + LIP_H/2)])
                    difference() {
                        cylinder(r=CAR1_OR, h=LIP_H, center=true);
                        cylinder(r=CAR1_OR - LIP_W, h=LIP_H+1, center=true);
                    }
                }
                // Hex bore for coupling tube
                hex_key(af=HEX_AF + PIP_TOL*2, h=CARRIER_T + LIP_H*2 + 1);
                // Pin holes
                for (j = [0:N_PLANETS-1])
                    rotate([0, 0, j * 360/N_PLANETS])
                    translate([ORB1, 0, 0])
                    cylinder(d=PIN_D, h=CARRIER_T + LIP_H*2 + 1, center=true);
            }

        // Planet pins
        for (i = [0:N_PLANETS-1])
            rotate([0, 0, i * 360/N_PLANETS])
            translate([ORB1, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + LIP_H*2, center=true);

        // Center hub (hex outside for keying to coupling)
        color(C_CAR1)
        difference() {
            hex_key(af=HEX_AF, h=GFW + CARRIER_T*2);
            cylinder(d=SHAFT_D + PIP_TOL*2, h=GFW + CARRIER_T*2 + 1, center=true);
        }
    }

    // --- Coupling tube (hex cross-section for torque transfer) ---
    if (SHOW_COUPLING)
    translate([S1_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        cplg_start = GFW/2 + CARRIER_T/2;
        cplg_end   = (S2_X - S1_X);
        cplg_len   = cplg_end - cplg_start;
        color(C_CPLG)
        translate([0, 0, cplg_start + cplg_len/2])
        difference() {
            hex_key(af=HEX_AF, h=cplg_len);
            cylinder(d=CPLG_ID, h=cplg_len+1, center=true);
        }
    }

    // --- Carrier 2 (OUTPUT) ---
    if (SHOW_CARRIER2)
    translate([EX_CAR2, 0, 0])
    translate([S2_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        for (side = [-1, 1])
            translate([0, 0, side * (GFW/2 + CARRIER_T/2)])
            color(C_CAR2)
            difference() {
                union() {
                    cylinder(r=CAR2_OR, h=CARRIER_T, center=true);
                    translate([0, 0, -side * (CARRIER_T/2 + LIP_H/2)])
                    difference() {
                        cylinder(r=CAR2_OR, h=LIP_H, center=true);
                        cylinder(r=CAR2_OR - LIP_W, h=LIP_H+1, center=true);
                    }
                }
                // Round bore for output shaft
                cylinder(d=SHAFT_D + PIP_TOL*2, h=CARRIER_T + LIP_H*2 + 1, center=true);
                for (j = [0:N_PLANETS-1])
                    rotate([0, 0, j * 360/N_PLANETS])
                    translate([ORB2, 0, 0])
                    cylinder(d=PIN_D, h=CARRIER_T + LIP_H*2 + 1, center=true);
            }

        // Planet pins
        for (i = [0:N_PLANETS-1])
            rotate([0, 0, i * 360/N_PLANETS])
            translate([ORB2, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + LIP_H*2, center=true);

        // Center hub
        color(C_CAR2)
        difference() {
            cylinder(d=SHAFT_D + PIP_TOL*2 + 3, h=GFW + CARRIER_T*2, center=true);
            cylinder(d=SHAFT_D + PIP_TOL*2, h=GFW + CARRIER_T*2 + 1, center=true);
        }

        // Output stub to spool
        out_len = SPOOL_X - S2_X - GFW/2 - CARRIER_T;
        color(C_CAR2)
        translate([0, 0, GFW/2 + CARRIER_T + out_len/2])
        difference() {
            cylinder(d=SHAFT_D + 3, h=out_len, center=true);
            cylinder(d=SHAFT_D + PIP_TOL*2, h=out_len+1, center=true);
        }
    }
}

// =============================================================
// SPOOL
// =============================================================
module spool() {
    translate([SPOOL_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        color(C_SPOOL)
        difference() {
            cylinder(r=SPOOL_R, h=SPOOL_H, center=true);
            cylinder(r=SPOOL_R - 2, h=SPOOL_H+1, center=true);
        }
        for (s = [-1, 1])
            translate([0, 0, s * (SPOOL_H/2 + FLANGE_T/2)])
            color(C_SPOOL)
            difference() {
                cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
                cylinder(r=SPOOL_R - 2, h=FLANGE_T+1, center=true);
            }
    }
}

// =============================================================
// THREAD + PIXEL
// =============================================================
module thread() {
    color(C_THR)
    translate([SPOOL_X, 0, -(SPOOL_R + THREAD_LEN/2)])
    cylinder(d=0.6, h=THREAD_LEN, center=true);
}

module pixel() {
    pz = -(SPOOL_R + THREAD_LEN + PIXEL_H/2);
    translate([SPOOL_X, 0, pz]) {
        color(C_PIX)
        rotate([0, 0, CAR2_A * 0.05])
        cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);
        color(C_THR) translate([0, 0, PIXEL_H/2 + 0.5]) sphere(r=0.6);
    }
}

// =============================================================
// FLAT PRINT LAYOUT — every part laid flat for 3D printing
// =============================================================
module flat_print_layout() {
    SP = 30;  // spacing between parts

    // Row 1: Sun gears
    translate([0, 0, 0])
    color(C_SUN1) difference() {
        simple_spur(mod=MOD, teeth=S1_T, thickness=GFW,
                  pressure_angle=PA, profile_shift=PS_S1, anchor=CENTER);
        hex_key(af=SHAFT_D + PIP_TOL*2, h=GFW+1);
    }
    translate([SP, 0, 0])
    color(C_SUN2) difference() {
        simple_spur(mod=MOD, teeth=S2_T, thickness=GFW,
                  pressure_angle=PA, profile_shift=PS_S2, anchor=CENTER);
        hex_key(af=HEX_AF + PIP_TOL*2, h=GFW+1);
    }

    // Row 2: Ring gears
    translate([0, SP*2, 0]) {
        color(C_RING1)
        simple_ring(mod=MOD, teeth=R1_T, thickness=RING_FW,
                  backing=RING_WALL, pressure_angle=PA,
                  profile_shift=PS_R1, anchor=CENTER);
    }
    translate([SP*2, SP*2, 0]) {
        color(C_RING2)
        simple_ring(mod=MOD, teeth=R2_T, thickness=RING_FW,
                  backing=RING_WALL, pressure_angle=PA,
                  profile_shift=PS_R2, anchor=CENTER);
    }

    // Row 3: Planet gears (6 total: 3 per stage)
    for (i = [0:2])
        translate([i*SP*0.6, -SP, 0])
        color(C_PLN1)
        simple_spur(mod=MOD, teeth=P1_T, thickness=GFW - PIP_TOL*2,
                  shaft_diam=PIN_D + PIP_TOL*2, pressure_angle=PA,
                  profile_shift=PS_P1, anchor=CENTER);
    for (i = [0:2])
        translate([(i+3)*SP*0.6, -SP, 0])
        color(C_PLN2)
        simple_spur(mod=MOD, teeth=P2_T, thickness=GFW - PIP_TOL*2,
                  shaft_diam=PIN_D + PIP_TOL*2, pressure_angle=PA,
                  profile_shift=PS_P2, anchor=CENTER);

    // Row 4: Carrier plates (4 discs) + coupling tube
    CAR1_OR = ORB1 + PIN_D + 2;
    CAR2_OR = ORB2 + PIN_D + 2;
    for (p = [0:1])
        translate([p*SP, -SP*2.5, 0])
        color(C_CAR1)
        difference() {
            cylinder(r=CAR1_OR, h=CARRIER_T, center=true);
            hex_key(af=HEX_AF + PIP_TOL*2, h=CARRIER_T+1);
            for (j = [0:2])
                rotate([0, 0, j*120])
                translate([ORB1, 0, 0])
                cylinder(d=PIN_D, h=CARRIER_T+1, center=true);
        }
    for (p = [0:1])
        translate([(p+2)*SP, -SP*2.5, 0])
        color(C_CAR2)
        difference() {
            cylinder(r=CAR2_OR, h=CARRIER_T, center=true);
            cylinder(d=SHAFT_D + PIP_TOL*2, h=CARRIER_T+1, center=true);
            for (j = [0:2])
                rotate([0, 0, j*120])
                translate([ORB2, 0, 0])
                cylinder(d=PIN_D, h=CARRIER_T+1, center=true);
        }

    // Coupling tube (laid on side)
    translate([SP*4.5, -SP*2.5, 0]) {
        cplg_len = (S2_X - S1_X) - (GFW/2 + CARRIER_T/2);
        color(C_CPLG)
        difference() {
            hex_key(af=HEX_AF, h=cplg_len);
            cylinder(d=CPLG_ID, h=cplg_len+1, center=true);
        }
    }
}
