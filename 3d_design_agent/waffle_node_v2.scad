// =============================================================
// WAFFLE GRID — SINGLE NODE V2 (BOSL2 Involute)
// 2-Stage Compound Planetary Differential with Housing
//
// ARCHITECTURE:
//   Fixed cylindrical housing contains both stages.
//   Ring gears have external spur teeth on their OD.
//   B/C shafts run parallel to A-shaft, pass through housing.
//   Drive pinions on B/C shafts mesh ring external teeth.
//   Carrier2 output shaft exits housing → spool outside.
//   Thread wraps around spool, drops by gravity.
//
// KINEMATIC CHAIN:
//   A-shaft (Y=0 Z=0) → hex → Sun1
//   Sun1 ↔ 3×Planet1 ↔ Ring1 (internal)
//   Ring1 external teeth ↔ B-pinion on B-shaft
//   Carrier1 → coupling → Sun2
//   Sun2 ↔ 3×Planet2 ↔ Ring2 (internal)
//   Ring2 external teeth ↔ C-pinion on C-shaft
//   Carrier2 → output shaft → spool
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

$fn = 48;
MANUAL_POSITION = 0.25;
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL      = 0.25;
BACKLASH = 0.1;

// ---- GEAR MODULE ----
MOD = 1.0;
PA  = 20;

// =============================================================
// STAGE 1
// =============================================================
S1_T = 13;  P1_T = 8;  R1_T = 29;
assert(S1_T + 2*P1_T == R1_T, "S1+2P1!=R1");

PS_S1 = auto_profile_shift(teeth=S1_T, pressure_angle=PA);
PS_P1 = auto_profile_shift(teeth=P1_T, pressure_angle=PA);

S1_PR = pitch_radius(mod=MOD, teeth=S1_T);
P1_PR = pitch_radius(mod=MOD, teeth=P1_T);
R1_PR = pitch_radius(mod=MOD, teeth=R1_T);

ORB1 = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                 profile_shift1=PS_S1, profile_shift2=PS_P1);

// =============================================================
// STAGE 2
// =============================================================
S2_T = 11;  P2_T = 9;  R2_T = 29;
assert(S2_T + 2*P2_T == R2_T, "S2+2P2!=R2");

PS_S2 = auto_profile_shift(teeth=S2_T, pressure_angle=PA);
PS_P2 = auto_profile_shift(teeth=P2_T, pressure_angle=PA);

S2_PR = pitch_radius(mod=MOD, teeth=S2_T);
P2_PR = pitch_radius(mod=MOD, teeth=P2_T);
R2_PR = pitch_radius(mod=MOD, teeth=R2_T);

ORB2 = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                 profile_shift1=PS_S2, profile_shift2=PS_P2);

// =============================================================
// RING GEAR GEOMETRY
// =============================================================
RING_WALL = 3.0;
R1_RR = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_INNER_R = R1_RR + RING_WALL;  // outer surface of ring housing body

// External drive teeth ON the ring body
// Use SAME module (MOD=1) so the teeth are the same size as the internal teeth
// Number of ext teeth sized so pitch circle ≈ ring body outer surface
EXT_T = floor(2 * RING_INNER_R * PI / (PI * MOD));  // ≈ floor(2*RING_INNER_R/MOD)
// Clean it: round to nearest even for symmetry
EXT_T_CLEAN = EXT_T - (EXT_T % 2);  // make even
EXT_PR = pitch_radius(mod=MOD, teeth=EXT_T_CLEAN);
EXT_OR = outer_radius(mod=MOD, teeth=EXT_T_CLEAN);
PS_EXT = auto_profile_shift(teeth=EXT_T_CLEAN, pressure_angle=PA);

// =============================================================
// DRIVE PINIONS (B/C shafts)
// Same MOD=1 as external ring teeth
// =============================================================
BPIN_T  = 10;
PS_BPIN = auto_profile_shift(teeth=BPIN_T, pressure_angle=PA);
BPIN_PR = pitch_radius(mod=MOD, teeth=BPIN_T);
BPIN_OR = outer_radius(mod=MOD, teeth=BPIN_T);

// Center distance: ext gear + pinion (external-external mesh)
DRIVE_CD = gear_dist(mod=MOD, teeth1=EXT_T_CLEAN, teeth2=BPIN_T,
                     profile_shift1=PS_EXT, profile_shift2=PS_BPIN);
DRIVE_Y  = DRIVE_CD;

// =============================================================
// ENVELOPE CHECK
// =============================================================
GRID_PITCH    = 50;
NODE_ENVELOPE = 45;
assert(EXT_OR * 2 <= NODE_ENVELOPE,
       str("Ring ext OD=", EXT_OR*2, " > envelope=", NODE_ENVELOPE));

// =============================================================
// PHYSICAL DIMENSIONS
// =============================================================
GFW        = 6;
EXT_GFW    = 5;     // external teeth face width
GAP        = 3;
CARRIER_T  = 2;
SHAFT_D    = 4;     // A-shaft (hex), runs through BOTH stages continuously
BC_SHAFT_D = 3;
// Coupling is a HOLLOW TUBE concentric around A-shaft
// Keyed to Carrier1, engages Sun2
CPLG_ID    = SHAFT_D + 0.5;  // 4.5mm — clears A-shaft hex
CPLG_OD    = 7;               // coupling tube outer diameter
PIN_D      = 2;     // planet dowel pins
OUT_SHAFT_D= 3;

BRG_OD = 8; BRG_ID = 4; BRG_W = 3;

// =============================================================
// STACK LAYOUT
// =============================================================
S1_X = -(GAP/2 + GFW/2);       // -4.5
S2_X =  (GAP/2 + GFW/2);       //  4.5
STACK_HALF  = GFW/2 + CARRIER_T;  // 5.0
TOTAL_STACK = (GFW + CARRIER_T*2)*2 + GAP;

// Housing dimensions
HSG_IR = EXT_OR + 1;       // housing inner radius: clears ext gear tips
HSG_WALL = 2;
HSG_OR = HSG_IR + HSG_WALL;
HSG_LEN = TOTAL_STACK + 6; // a bit longer than stack for end caps

// Spool — on output shaft past housing
SPOOL_GAP = 2;
SPOOL_X   = HSG_LEN/2 + SPOOL_GAP + 5;  // past housing right end
SPOOL_R   = 8;    SPOOL_H  = 8;
FLANGE_R  = 11;   FLANGE_T = 1.5;

// Thread
THREAD_LEN = 60;
PIXEL_W = 18;  PIXEL_H = 3;

// Output shaft
OUT_SHAFT_START = S2_X + STACK_HALF;
OUT_SHAFT_END   = SPOOL_X;
OUT_SHAFT_LEN   = OUT_SHAFT_END - OUT_SHAFT_START;

// =============================================================
// KINEMATICS
// =============================================================
A_IN = POS * 360;
B_IN = POS * 360 * 1.13;
C_IN = POS * 360 * 0.87;

SUN1_A  = A_IN;
RING1_A = B_IN;
CAR1_A  = (SUN1_A*S1_T + RING1_A*R1_T) / (S1_T + R1_T);

SUN2_A  = CAR1_A;
RING2_A = C_IN;
CAR2_A  = (SUN2_A*S2_T + RING2_A*R2_T) / (S2_T + R2_T);
SPOOL_A = CAR2_A;

P1_SELF = -(CAR1_A - SUN1_A) * S1_T / P1_T;
P2_SELF = -(CAR2_A - SUN2_A) * S2_T / P2_T;

// Pinion rotation matches ring ext teeth
BPIN_A = -RING1_A * EXT_T_CLEAN / BPIN_T;
CPIN_A = -RING2_A * EXT_T_CLEAN / BPIN_T;

// =============================================================
// COLORS
// =============================================================
C_SUN  = [0.85, 0.25, 0.20];
C_SUN2 = [0.70, 0.20, 0.25];
C_RING = [0.78, 0.72, 0.25];
C_RING2= [0.68, 0.62, 0.25];
C_EXT  = [0.90, 0.80, 0.30];
C_EXT2 = [0.80, 0.70, 0.28];
C_PLN1 = [0.35, 0.72, 0.35];
C_PLN2 = [0.28, 0.60, 0.28];
C_CAR  = [0.30, 0.50, 0.80];
C_CPLG = [0.45, 0.65, 0.90];
C_SPL  = [0.58, 0.40, 0.22];
C_THR  = [0.80, 0.80, 0.86];
C_PIX  = [0.74, 0.60, 0.40];
C_SHA  = [0.88, 0.30, 0.22];
C_SHB  = [0.22, 0.75, 0.30];
C_SHC  = [0.22, 0.38, 0.90];
C_PIN  = [0.65, 0.65, 0.68];
C_BPIN = [0.50, 0.80, 0.50];
C_CPIN = [0.40, 0.50, 0.90];
C_BRG  = [0.45, 0.45, 0.50];
C_OUT  = [0.55, 0.35, 0.65];
C_HSG  = [0.40, 0.40, 0.45, 0.30];  // semi-transparent housing

// =============================================================
// TOGGLES
// =============================================================
SHOW_SHAFTS   = true;
SHOW_STAGE1   = true;
SHOW_STAGE2   = true;
SHOW_CARRIERS = true;
SHOW_PINIONS  = true;
SHOW_OUTPUT   = true;
SHOW_SPOOL    = true;
SHOW_THREAD   = true;
SHOW_PIXEL    = true;
SHOW_BEARINGS = true;
SHOW_HOUSING  = true;
SHOW_ENVELOPE = false;

// =============================================================
// MAIN
// =============================================================
main();

module main() {
    if (SHOW_ENVELOPE) envelope_ghost();
    if (SHOW_HOUSING)  housing();
    if (SHOW_SHAFTS)   shafts();
    if (SHOW_STAGE1)   stage1();
    if (SHOW_STAGE2)   stage2();
    if (SHOW_CARRIERS) carriers();
    if (SHOW_PINIONS)  drive_pinions();
    if (SHOW_OUTPUT)   output_shaft();
    if (SHOW_SPOOL)    spool_assy();
    if (SHOW_THREAD)   thread();
    if (SHOW_PIXEL)    pixel();
    if (SHOW_BEARINGS) bearings_assy();
}

module envelope_ghost() {
    color([0.5, 0.5, 0.8, 0.08])
    cube([GRID_PITCH, GRID_PITCH, GRID_PITCH], center=true);
}

// =============================================================
// HOUSING — fixed cylindrical shell
// Semi-transparent so internals are visible
// Slots for B/C shafts to pass through wall
// =============================================================
module housing() {
    color(C_HSG)
    rotate([0, 90, 0])
    difference() {
        cylinder(r=HSG_OR, h=HSG_LEN, center=true);
        // Inner bore
        cylinder(r=HSG_IR, h=HSG_LEN + 1, center=true);
        // A-shaft pass-through (left end cap)
        cylinder(d=SHAFT_D + TOL*4, h=HSG_LEN + 2, center=true);
        // B-shaft slot (at Y=+DRIVE_Y)
        translate([DRIVE_Y, 0, 0])
        cylinder(d=BC_SHAFT_D + TOL*4, h=HSG_LEN + 2, center=true);
        // C-shaft slot (at Y=-DRIVE_Y)
        translate([-DRIVE_Y, 0, 0])
        cylinder(d=BC_SHAFT_D + TOL*4, h=HSG_LEN + 2, center=true);
        // Output shaft exit (right end)
        cylinder(d=OUT_SHAFT_D + TOL*4, h=HSG_LEN + 2, center=true);
    }
}

// =============================================================
// SHAFTS
// =============================================================
module shafts() {
    // A-shaft: CONTINUOUS through both stages and beyond
    // In the grid, this rod runs the full row length
    a_len = TOTAL_STACK + 40;
    color(C_SHA)
    rotate([0, 90, 0])
    rotate([0, 0, SUN1_A])
    cylinder(d=SHAFT_D, h=a_len, center=true, $fn=6);

    // B-shaft
    bc_len = TOTAL_STACK + 40;
    color(C_SHB)
    translate([0, DRIVE_Y, 0])
    rotate([0, 90, 0])
    rotate([0, 0, B_IN])
    cylinder(d=BC_SHAFT_D, h=bc_len, center=true);

    // C-shaft
    color(C_SHC)
    translate([0, -DRIVE_Y, 0])
    rotate([0, 90, 0])
    rotate([0, 0, C_IN])
    cylinder(d=BC_SHAFT_D, h=bc_len, center=true);
}

// =============================================================
// EXTERNAL RING GEAR MODULE
// Creates an annular ring of involute teeth using BOSL2
// The inner bore is cut to RING_INNER_R so it sits on the ring body
// =============================================================
module ext_ring_gear(teeth, gfw) {
    linear_extrude(gfw, center=true)
    difference() {
        // Full spur gear profile from BOSL2
        spur_gear2d(mod=MOD, teeth=teeth, pressure_angle=PA,
                    backlash=BACKLASH, profile_shift=PS_EXT);
        // Cut out inner bore at ring body OD
        circle(r=RING_INNER_R - 0.5);  // slight overlap for structural join
    }
}

// =============================================================
// STAGE 1
// =============================================================
module stage1() {
    translate([S1_X, 0, 0])
    rotate([0, 90, 0]) {
        // SUN1
        color(C_SUN)
        rotate([0, 0, SUN1_A])
        spur_gear(mod=MOD, teeth=S1_T, thickness=GFW,
                  shaft_diam=SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S1,
                  anchor=CENTER);

        // RING1 (BOSL2 ring gear with backing)
        color(C_RING)
        rotate([0, 0, RING1_A])
        ring_gear(mod=MOD, teeth=R1_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING1 EXTERNAL TEETH — annular involute teeth on ring body OD
        color(C_EXT)
        rotate([0, 0, RING1_A])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET1
        rotate([0, 0, CAR1_A])
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([ORB1, 0, 0]) {
                color(C_PLN1)
                rotate([0, 0, P1_SELF])
                spur_gear(mod=MOD, teeth=P1_T, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          backlash=BACKLASH, profile_shift=PS_P1,
                          anchor=CENTER);
            }
    }
}

// =============================================================
// STAGE 2
// =============================================================
module stage2() {
    translate([S2_X, 0, 0])
    rotate([0, 90, 0]) {
        // SUN2 — driven by coupling TUBE (not A-shaft)
        // A-shaft passes through center freely; coupling tube engages Sun2
        color(C_SUN2)
        rotate([0, 0, SUN2_A])
        spur_gear(mod=MOD, teeth=S2_T, thickness=GFW,
                  shaft_diam=CPLG_OD, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S2,
                  anchor=CENTER);

        color(C_RING2)
        rotate([0, 0, RING2_A])
        ring_gear(mod=MOD, teeth=R2_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        color(C_EXT2)
        rotate([0, 0, RING2_A])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        rotate([0, 0, CAR2_A])
        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([ORB2, 0, 0]) {
                color(C_PLN2)
                rotate([0, 0, P2_SELF])
                spur_gear(mod=MOD, teeth=P2_T, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          backlash=BACKLASH, profile_shift=PS_P2,
                          anchor=CENTER);
            }
    }
}

// =============================================================
// CARRIERS + COUPLING
// =============================================================
module carriers() {
    // CARRIER 1
    translate([S1_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=ORB1 + PIN_D + 1, h=CARRIER_T, center=true);
                // Center bore clears the coupling tube OD (A-shaft inside)
                cylinder(d=CPLG_OD + TOL*2, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0,0,j*120])
                    translate([ORB1,0,0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }
        for (i = [0:2])
            rotate([0,0,i*120])
            translate([ORB1,0,0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // COUPLING TUBE — hollow tube concentric around A-shaft
        // Keyed to Carrier1, extends through GAP, engages Sun2 bore
        cplg_start = GFW/2 + CARRIER_T;
        cplg_end   = cplg_start + GAP + GFW/2;
        cplg_len   = cplg_end - cplg_start;
        color(C_CPLG)
        translate([0, 0, cplg_start + cplg_len/2])
        difference() {
            cylinder(d=CPLG_OD, h=cplg_len, center=true);
            cylinder(d=CPLG_ID, h=cplg_len+1, center=true);  // A-shaft passes through
        }
    }

    // CARRIER 2
    translate([S2_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=ORB2 + PIN_D + 1, h=CARRIER_T, center=true);
                // Center bore clears A-shaft (which passes through freely)
                cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0,0,j*120+30])
                    translate([ORB2,0,0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }
        for (i = [0:2])
            rotate([0,0,i*120+30])
            translate([ORB2,0,0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // Output stub → spool
        out_start = GFW/2 + CARRIER_T;
        out_len   = SPOOL_GAP + SPOOL_H/2;
        color(C_OUT)
        translate([0, 0, out_start + out_len/2])
        cylinder(d=OUT_SHAFT_D, h=out_len, center=true);
    }
}

// =============================================================
// DRIVE PINIONS — BOSL2 spur gears, same MOD as ring ext teeth
// =============================================================
module drive_pinions() {
    // B-pinion at Stage1
    translate([S1_X, DRIVE_Y, 0])
    rotate([0, 90, 0]) {
        color(C_BPIN)
        rotate([0, 0, BPIN_A])
        spur_gear(mod=MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }

    // C-pinion at Stage2
    translate([S2_X, -DRIVE_Y, 0])
    rotate([0, 90, 0]) {
        color(C_CPIN)
        rotate([0, 0, CPIN_A])
        spur_gear(mod=MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }
}

// =============================================================
// OUTPUT SHAFT
// =============================================================
module output_shaft() {
    color(C_OUT)
    translate([(OUT_SHAFT_START + OUT_SHAFT_END)/2, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A])
    cylinder(d=OUT_SHAFT_D, h=OUT_SHAFT_LEN, center=true);
}

// =============================================================
// SPOOL — coaxial, past housing
// =============================================================
module spool_assy() {
    translate([SPOOL_X, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, SPOOL_A]) {
        color(C_SPL) cylinder(r=SPOOL_R, h=SPOOL_H, center=true);
        color([C_SPL[0]+0.1, C_SPL[1]+0.06, C_SPL[2]+0.02])
        for (sz = [-1, 1])
            translate([0,0,sz*SPOOL_H/2])
            cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
        color(C_THR) translate([SPOOL_R-0.5,0,0]) sphere(r=0.5);
    }
}

module thread() {
    color(C_THR)
    translate([SPOOL_X, 0, -SPOOL_R - THREAD_LEN/2])
    cylinder(d=0.6, h=THREAD_LEN, center=true);
}

module pixel() {
    pz = -SPOOL_R - THREAD_LEN - PIXEL_H/2;
    translate([SPOOL_X, 0, pz]) {
        color(C_PIX) rotate([0,0,SPOOL_A*0.05+15])
        cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);
        color(C_THR) translate([0,0,PIXEL_H/2+0.5]) sphere(r=0.8);
    }
}

// =============================================================
// BEARINGS
// =============================================================
module brg(od=BRG_OD, id=BRG_ID, w=BRG_W) {
    color(C_BRG) difference() {
        cylinder(d=od, h=w, center=true);
        cylinder(d=id, h=w+1, center=true);
    }
}

module bearings_assy() {
    // A-shaft: 2 bearings at housing end caps
    for (bx = [-HSG_LEN/2, HSG_LEN/2])
        translate([bx, 0, 0]) rotate([0,90,0]) brg();

    // B-shaft: 2 bearings (flanking pinion)
    for (bx = [S1_X - EXT_GFW/2 - BRG_W - 1, S1_X + EXT_GFW/2 + BRG_W + 1])
        translate([bx, DRIVE_Y, 0]) rotate([0,90,0]) brg(id=BC_SHAFT_D);

    // C-shaft: 2 bearings
    for (bx = [S2_X - EXT_GFW/2 - BRG_W - 1, S2_X + EXT_GFW/2 + BRG_W + 1])
        translate([bx, -DRIVE_Y, 0]) rotate([0,90,0]) brg(id=BC_SHAFT_D);

    // Output: 1 bearing at housing exit
    translate([S2_X + STACK_HALF + 1, 0, 0]) rotate([0,90,0]) brg(id=OUT_SHAFT_D);
}
