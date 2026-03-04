// =============================================================
// WAFFLE UNIT — Single Node with 3 Shafts
// Complete detail view of one compound planetary differential
//
// ARCHITECTURE:
//   A-shaft (red hex): center, drives Sun1
//   B-shaft (green): ABOVE at Z=+DRIVE_CD, drives Ring1 via ext teeth
//   C-shaft (blue): SIDE at Y=+DRIVE_CD, drives Ring2 via ext teeth
//
//   90° separation between B and C shafts — no collision.
//
// GEAR MODULES:
//   Internal planetary: MOD=1 (compact, inside ring)
//   External drive pair: EXT_MOD=2 (chunky teeth, same profile
//   on both ring ext gear AND pinion — visually identical mesh)
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

$fn = 48;   // high quality for tooth visibility
MANUAL_POSITION = 0.15;
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL      = 0.25;
BACKLASH = 0.1;

// ---- GEAR MODULES ----
MOD     = 1.0;    // internal planetary
EXT_MOD = 2.0;    // external drive (ring ext + pinion)
PA      = 20;

// =============================================================
// STAGE 1 INTERNAL PLANETARY (MOD=1)
// =============================================================
S1_T = 13;  P1_T = 8;  R1_T = 29;
assert(S1_T + 2*P1_T == R1_T, "S1+2P1!=R1");

PS_S1 = auto_profile_shift(teeth=S1_T, pressure_angle=PA);
PS_P1 = auto_profile_shift(teeth=P1_T, pressure_angle=PA);
S1_PR = pitch_radius(mod=MOD, teeth=S1_T);
P1_PR = pitch_radius(mod=MOD, teeth=P1_T);
R1_PR = pitch_radius(mod=MOD, teeth=R1_T);
ORB1  = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                  profile_shift1=PS_S1, profile_shift2=PS_P1);

// =============================================================
// STAGE 2 INTERNAL PLANETARY (MOD=1)
// =============================================================
S2_T = 11;  P2_T = 9;  R2_T = 29;
assert(S2_T + 2*P2_T == R2_T, "S2+2P2!=R2");

PS_S2 = auto_profile_shift(teeth=S2_T, pressure_angle=PA);
PS_P2 = auto_profile_shift(teeth=P2_T, pressure_angle=PA);
S2_PR = pitch_radius(mod=MOD, teeth=S2_T);
P2_PR = pitch_radius(mod=MOD, teeth=P2_T);
R2_PR = pitch_radius(mod=MOD, teeth=R2_T);
ORB2  = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                  profile_shift1=PS_S2, profile_shift2=PS_P2);

// =============================================================
// RING BODY
// =============================================================
RING_WALL    = 3.0;
R1_RR        = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_INNER_R = R1_RR + RING_WALL;   // outer surface of ring body ≈16.5mm

// =============================================================
// RING EXTERNAL TEETH (EXT_MOD = 2)
//
// These teeth are on the OUTSIDE of the ring body.
// EXT_MOD=2 gives chunky, visible teeth — SAME size as pinion teeth.
// Both ext ring gear and pinion use the same spur_gear() with EXT_MOD.
// =============================================================
EXT_T_RAW   = ceil(2 * (RING_INNER_R + 0.5 + 1.25*EXT_MOD) / EXT_MOD);
EXT_T_CLEAN = EXT_T_RAW + (EXT_T_RAW % 2);  // round to even
PS_EXT      = auto_profile_shift(teeth=EXT_T_CLEAN, pressure_angle=PA);
EXT_PR      = pitch_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
EXT_OR      = outer_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
EXT_RR      = root_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);

echo("=== EXTERNAL DRIVE (EXT_MOD=2) ===");
echo("EXT_T=", EXT_T_CLEAN, "EXT_PR=", EXT_PR, "EXT_OR=", EXT_OR,
     "EXT_RR=", EXT_RR, "RING_INNER_R=", RING_INNER_R);
echo("root_margin=", EXT_RR - RING_INNER_R);

assert(EXT_RR >= RING_INNER_R + 0.3,
       str("Ext root=", EXT_RR, " too close to ring=", RING_INNER_R));

// =============================================================
// DRIVE PINIONS (EXT_MOD = 2) — same module as ext ring teeth
// =============================================================
BPIN_T  = 6;
PS_BPIN = auto_profile_shift(teeth=BPIN_T, pressure_angle=PA);
BPIN_PR = pitch_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_OR = outer_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_RR = root_radius(mod=EXT_MOD, teeth=BPIN_T);

DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T_CLEAN, teeth2=BPIN_T,
                     profile_shift1=PS_EXT, profile_shift2=PS_BPIN);

echo("BPIN_T=", BPIN_T, "BPIN_PR=", BPIN_PR, "BPIN_OR=", BPIN_OR,
     "DRIVE_CD=", DRIVE_CD);
echo("tip_clearance_ext_to_pin=", DRIVE_CD - EXT_OR - BPIN_RR);
echo("tip_clearance_pin_to_ext=", DRIVE_CD - BPIN_OR - EXT_RR);

// =============================================================
// SHAFT LAYOUT — 90° separation
//
//         B-shaft (green) ← Z = +DRIVE_CD (above)
//            |
//   A-shaft (red hex) ———— C-shaft (blue) ← Y = +DRIVE_CD (side)
//            |
//        [thread drops -Z]
// =============================================================
B_DY = 0;          B_DZ = DRIVE_CD;    // B above
C_DY = DRIVE_CD;   C_DZ = 0;           // C side

// =============================================================
// PHYSICAL DIMENSIONS
// =============================================================
GFW        = 6;      // internal gear face width
EXT_GFW    = 6;      // external teeth face width (same as internal now)
GAP        = 3;      // gap between stages
CARRIER_T  = 2;      // carrier plate thickness
SHAFT_D    = 4;      // A-shaft hex
BC_SHAFT_D = 4;      // B/C shaft diameter (slightly larger for EXT_MOD=2)
CPLG_ID    = SHAFT_D + 0.5;
CPLG_OD    = 7;
PIN_D      = 2;      // planet dowel pin

BRG_OD = 8;  BRG_ID = 4;  BRG_W = 3;
NEEDLE_OD = 6; NEEDLE_ID = SHAFT_D + TOL; NEEDLE_W = 3;

// =============================================================
// NODE STACK LAYOUT (axial = X direction)
// =============================================================
S1_LOCAL    = -(GAP/2 + GFW/2);
S2_LOCAL    =  (GAP/2 + GFW/2);
STACK_HALF  = GFW/2 + CARRIER_T;
TOTAL_STACK = (GFW + CARRIER_T*2)*2 + GAP;
STACK_LEFT  = S1_LOCAL - STACK_HALF;
STACK_RIGHT = S2_LOCAL + STACK_HALF;

// Spool drum
SPOOL_OD   = 22;
SPOOL_WALL = 2;
SPOOL_ID   = SPOOL_OD - 2*SPOOL_WALL;
SPOOL_LEN  = 10;
SPOOL_GAP  = 1;
SPOOL_START  = STACK_RIGHT + SPOOL_GAP;
SPOOL_CENTER = SPOOL_START + SPOOL_LEN/2;
FLANGE_R     = SPOOL_OD/2 + 2;
FLANGE_T     = 1.0;

// Thread and pixel
THREAD_LEN = 70;
PIXEL_W    = 18;
PIXEL_H    = 3;

// Shaft extends well past the node on both sides
SHAFT_EXT   = 30;
SHAFT_LEN   = TOTAL_STACK + SPOOL_LEN + SPOOL_GAP + 2*SHAFT_EXT;
SHAFT_X_MID = (STACK_LEFT + SPOOL_START + SPOOL_LEN) / 2;

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
BPIN_A  = -RING1_A * EXT_T_CLEAN / BPIN_T;
CPIN_A  = -RING2_A * EXT_T_CLEAN / BPIN_T;

// =============================================================
// COLORS
// =============================================================
C_SUN   = [0.85, 0.25, 0.20];       // red — sun1
C_SUN2  = [0.70, 0.20, 0.25];       // dark red — sun2
C_RING  = [0.78, 0.72, 0.25];       // gold — ring internal
C_RING2 = [0.68, 0.62, 0.25];
C_EXT   = [0.90, 0.80, 0.30];       // yellow — ring external teeth
C_EXT2  = [0.80, 0.70, 0.28];
C_PLN1  = [0.50, 0.75, 0.50];       // green — planets
C_PLN2  = [0.40, 0.65, 0.40];
C_CAR   = [0.30, 0.50, 0.80];       // blue — carriers
C_CAR2  = [0.25, 0.42, 0.72];
C_CPLG  = [0.45, 0.65, 0.90];       // light blue — coupling
C_SPL   = [0.58, 0.40, 0.22];       // brown — spool
C_FLNG  = [0.65, 0.48, 0.28];
C_THR   = [0.82, 0.82, 0.88];       // white — thread
C_PIX   = [0.74, 0.60, 0.40];       // wood — pixel block
C_SHA   = [0.88, 0.30, 0.22];       // red — A-shaft
C_SHB   = [0.22, 0.75, 0.30];       // green — B-shaft
C_SHC   = [0.22, 0.38, 0.90];       // blue — C-shaft
C_PIN   = [0.65, 0.65, 0.68];       // silver — dowel pins
C_BPIN  = [0.30, 0.80, 0.30];       // green — B-pinion
C_CPIN  = [0.30, 0.40, 0.90];       // blue — C-pinion
C_BRG   = [0.45, 0.45, 0.50];       // grey — bearings

// =============================================================
// TOGGLES
// =============================================================
SHOW_SHAFTS    = true;
SHOW_GEARS     = true;
SHOW_CARRIERS  = true;
SHOW_PINIONS   = true;
SHOW_THREADS   = true;
SHOW_PIXELS    = true;
SHOW_BEARINGS  = true;

// =============================================================
// MAIN
// =============================================================
main();

module main() {
    // --- 3 SHAFTS ---
    if (SHOW_SHAFTS) {
        // A-shaft (red hex) — center
        color(C_SHA)
        translate([SHAFT_X_MID, 0, 0])
        rotate([0, 90, 0])
        rotate([0, 0, SUN1_A])
        cylinder(d=SHAFT_D, h=SHAFT_LEN, center=true, $fn=6);

        // B-shaft (green) — ABOVE at Z=+DRIVE_CD
        color(C_SHB)
        translate([SHAFT_X_MID, B_DY, B_DZ])
        rotate([0, 90, 0])
        rotate([0, 0, B_IN])
        cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);

        // C-shaft (blue) — SIDE at Y=+DRIVE_CD
        color(C_SHC)
        translate([SHAFT_X_MID, C_DY, C_DZ])
        rotate([0, 90, 0])
        rotate([0, 0, C_IN])
        cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);
    }

    // --- NODE GUTS ---
    if (SHOW_GEARS) {
        stage1();
        stage2();
    }
    if (SHOW_PINIONS) pinions();
    if (SHOW_CARRIERS) carriers();
    if (SHOW_THREADS) thread();
    if (SHOW_PIXELS)  pixel();
}

// =============================================================
// STAGE 1 — Sun1 + Ring1(internal) + Ring1(ext teeth) + 3×Planet1
// =============================================================
module stage1() {
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN1 (red) — keyed to A-shaft
        color(C_SUN)
        rotate([0, 0, SUN1_A])
        spur_gear(mod=MOD, teeth=S1_T, thickness=GFW,
                  shaft_diam=SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S1,
                  anchor=CENTER);

        // RING1 internal teeth (gold)
        color(C_RING)
        rotate([0, 0, RING1_A])
        ring_gear(mod=MOD, teeth=R1_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING1 EXTERNAL TEETH (yellow) — EXT_MOD=2, chunky
        color(C_EXT)
        rotate([0, 0, RING1_A])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET1 (green) — on dowel pins in Carrier1
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
// STAGE 2 — Sun2 + Ring2(internal) + Ring2(ext teeth) + 3×Planet2
// =============================================================
module stage2() {
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN2 (dark red) — keyed to coupling tube
        color(C_SUN2)
        rotate([0, 0, SUN2_A])
        spur_gear(mod=MOD, teeth=S2_T, thickness=GFW,
                  shaft_diam=CPLG_OD, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S2,
                  anchor=CENTER);

        // RING2 internal teeth
        color(C_RING2)
        rotate([0, 0, RING2_A])
        ring_gear(mod=MOD, teeth=R2_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING2 EXTERNAL TEETH (yellow) — EXT_MOD=2
        color(C_EXT2)
        rotate([0, 0, RING2_A])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET2
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
// PINIONS — on B and C shafts
//
// B-pinion at STAGE1, positioned ABOVE ring (Z=+DRIVE_CD)
// C-pinion at STAGE2, positioned SIDE of ring (Y=+DRIVE_CD)
//
// SAME EXT_MOD, same spur_gear() → teeth look IDENTICAL to ext ring teeth
// =============================================================
module pinions() {
    // B-pinion — above Stage1
    translate([S1_LOCAL, B_DY, B_DZ])
    rotate([0, 90, 0]) {
        color(C_BPIN)
        rotate([0, 0, BPIN_A])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }

    // C-pinion — side of Stage2
    translate([S2_LOCAL, C_DY, C_DZ])
    rotate([0, 90, 0]) {
        color(C_CPIN)
        rotate([0, 0, CPIN_A])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }
}

// =============================================================
// EXTERNAL RING GEAR — EXT_MOD=2, same as pinions
// =============================================================
module ext_ring_gear(teeth, gfw) {
    spur_gear(mod=EXT_MOD, teeth=teeth, thickness=gfw,
              shaft_diam=RING_INNER_R * 2,
              pressure_angle=PA, backlash=BACKLASH,
              profile_shift=PS_EXT, anchor=CENTER);
}

// =============================================================
// CARRIERS + COUPLING + SPOOL DRUM
// =============================================================
module carriers() {
    // ======== CARRIER 1 ========
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=ORB1 + PIN_D + 1, h=CARRIER_T, center=true);
                cylinder(d=CPLG_OD + TOL*2, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0, 0, j*120])
                    translate([ORB1, 0, 0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }

        // Planet dowel pins
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([ORB1, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // Needle bearing
        color(C_BRG) cylinder(d=NEEDLE_OD, h=NEEDLE_W, center=true);

        // Coupling tube
        cplg_start = GFW/2 + CARRIER_T;
        cplg_len   = GAP + GFW/2;
        color(C_CPLG)
        translate([0, 0, cplg_start + cplg_len/2])
        difference() {
            cylinder(d=CPLG_OD, h=cplg_len, center=true);
            cylinder(d=CPLG_ID, h=cplg_len+1, center=true);
        }
    }

    // ======== CARRIER 2 + SPOOL ========
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR2)
            difference() {
                cylinder(r=ORB2 + PIN_D + 1, h=CARRIER_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0, 0, j*120 + 30])
                    translate([ORB2, 0, 0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }

        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([ORB2, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        color(C_BRG) cylinder(d=NEEDLE_OD, h=NEEDLE_W, center=true);

        // Spool drum
        spool_z = GFW/2 + CARRIER_T + SPOOL_GAP + SPOOL_LEN/2;
        color(C_SPL)
        translate([0, 0, spool_z])
        difference() {
            cylinder(d=SPOOL_OD, h=SPOOL_LEN, center=true);
            cylinder(d=SHAFT_D + TOL*4, h=SPOOL_LEN + 1, center=true);
        }

        // Flanges
        color(C_FLNG)
        for (fz = [spool_z - SPOOL_LEN/2 - FLANGE_T/2,
                   spool_z + SPOOL_LEN/2 + FLANGE_T/2])
            translate([0, 0, fz])
            difference() {
                cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=FLANGE_T + 1, center=true);
            }

        // Connecting webs
        web_start = GFW/2 + CARRIER_T/2;
        web_end = spool_z - SPOOL_LEN/2;
        web_len = web_end - web_start;
        for (a = [0:2])
            rotate([0, 0, a*120 + 15])
            color(C_CAR2)
            translate([(SHAFT_D/2 + TOL + SPOOL_ID/2)/2, 0,
                       web_start + web_len/2])
            cube([SPOOL_ID/2 - SHAFT_D/2 - TOL, 2, web_len], center=true);
    }
}

// =============================================================
// THREAD — drops from spool drum bottom (-Z)
// =============================================================
module thread() {
    spool_drop_z = -(SPOOL_OD/2);
    color(C_THR)
    translate([SPOOL_CENTER, 0, spool_drop_z - THREAD_LEN/2])
    cylinder(d=0.6, h=THREAD_LEN, center=true);
}

// =============================================================
// PIXEL — suspended wood block
// =============================================================
module pixel() {
    pz = -(SPOOL_OD/2 + THREAD_LEN + PIXEL_H/2);
    translate([SPOOL_CENTER, 0, pz]) {
        color(C_PIX)
        rotate([0, 0, SPOOL_A * 0.05 + 15])
        cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);
        color(C_THR) translate([0, 0, PIXEL_H/2 + 0.5]) sphere(r=0.6);
    }
}
