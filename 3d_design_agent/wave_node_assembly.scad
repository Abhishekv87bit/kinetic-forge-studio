// =============================================================
// WAFFLE GRID — SINGLE NODE, 50mm PITCH
// Compound Planetary Differential with BOSL2 Involute Gears
//
// Wave Summation: Z = f(A) + g(B) + h(C) via 2-stage planetary
//   Stage 1: Sun1(A) + Ring1(B) → Carrier1
//   Stage 2: Carrier1→Sun2 + Ring2(C) → Carrier2
//   Carrier2 → output bevel → vertical spool → thread → pixel
//
// Scaled to MOD=1 for 50mm grid pitch (was MOD=2).
// Profile-shift-aware orbit radii for small tooth counts.
//
// COORDINATE SYSTEM (OpenSCAD):
//   Z+ = UP (against gravity)
//   Planetary stack axis = X (horizontal, A-shaft direction)
//   Shafts run in XY plane at different Z heights
//   Spool, thread, pixel hang below node (-Z)
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// ---- QUALITY / ANIMATION ----
$fn = 64;
MANUAL_POSITION = 0.3;  // 0..1, set to -1 for $t
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL = 0.15;

// ---- GRID ENVELOPE ----
GRID_PITCH = 50;       // mm center-to-center between nodes
NODE_ENVELOPE = 45;    // max diameter per node (pitch - 5mm clearance)

// ---- GEAR PARAMETERS ----
MOD = 1;  // gear module (was 2 — halved for 50mm pitch)

// Stage 1: Sun1 + Ring1 + 3×Planet1
S1_T = 13;   P1_T = 8;   R1_T = 29;   // S1+2*P1 = 29 ✓
// Stage 2: Sun2 + Ring2 + 3×Planet2
S2_T = 11;   P2_T = 9;   R2_T = 29;   // S2+2*P2 = 29 ✓
// Bevel gears
BV_T = 12;         // main tower bevels
BV_OUT_T = 10;     // output bevel pair

// ---- PLANETARY CONSTRAINTS (compile-time verification) ----
assert(S1_T + 2 * P1_T == R1_T, "Stage 1: S+2P must equal R!");
assert(S2_T + 2 * P2_T == R2_T, "Stage 2: S+2P must equal R!");

// ---- PROFILE SHIFTS (required for small tooth counts < 17) ----
// BOSL2 auto-computes profile shift for spur_gear, but ring_gear
// defaults to profile_shift=0. For internal meshing, ring shift
// must >= mating planet's shift. We compute planet shifts and
// apply them to ring gears explicitly.
PS_P1 = auto_profile_shift(teeth=P1_T);   // ~0.53 for 8T
PS_P2 = auto_profile_shift(teeth=P2_T);   // ~0.35 for 9T

// Derived radii (pitch radius = teeth * module / 2)
S1_PR = S1_T * MOD / 2;   // 6.5
P1_PR = P1_T * MOD / 2;   // 4.0
R1_PR = R1_T * MOD / 2;   // 14.5

S2_PR = S2_T * MOD / 2;   // 5.5
P2_PR = P2_T * MOD / 2;   // 4.5
R2_PR = R2_T * MOD / 2;   // 14.5

BV_PR = BV_T * MOD / 2;       // 6.0
BV_OUT_PR = BV_OUT_T * MOD / 2; // 5.0

// ---- ORBIT RADII (profile-shift-aware) ----
// gear_dist() accounts for profile shift, giving correct center
// distance for meshing gears. Simple S_PR+P_PR is only correct
// when profile_shift=0 for both gears.
ORB1 = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T);
ORB2 = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T);

// Circular pitch from module
CP = MOD * PI;  // ~3.14mm

// ---- ENVELOPE VERIFICATION ----
assert(2 * (R1_PR + WALL + MOD + 2) <= NODE_ENVELOPE,
       str("Stage 1 ring too large! OD=", 2*(R1_PR+WALL+MOD+2), " > ", NODE_ENVELOPE));
assert(2 * (R2_PR + WALL + MOD + 2) <= NODE_ENVELOPE,
       str("Stage 2 ring too large! OD=", 2*(R2_PR+WALL+MOD+2), " > ", NODE_ENVELOPE));

// ---- DIMENSIONS ----
GFW = 6;            // gear face width (was 12)
STAGE_GAP = 4;      // between stages along X (was 8)
WALL = 3;           // ring gear backing (was 5)
CARRIER_T = 2;      // carrier plate thickness (was 3)

SHAFT_D = 4;        // (was 8)
SHAFT_HEX = 4;      // hex across-flats for A-shaft (was 8)
BVL_SHAFT_D = 3;    // (was 6)
OUT_SHAFT_D = 3;    // (was 6)

BEARING_OD = 8;     // MR84 bearing (was 22)
BEARING_ID = 4;     // (was 8)
BEARING_W = 3;      // (was 7)

// ---- Z HEIGHTS (Z+ = UP) ----
LAY_A = 0;       // bottom: A-shaft at 0°
LAY_B = 15;      // middle: B-shafts at 60° (was 30)
LAY_C = 30;      // top: C-shafts at 120° (was 60)

// Housing
HOUSING_OR = R1_PR + WALL + MOD + 2;  // ~20.5
HOUSING_LEN = GFW * 2 + STAGE_GAP + WALL * 2;  // ~22

// Below node
OUT_BVL_Z = -(HOUSING_OR + 8);   // ~-28.5
SPOOL_Z = OUT_BVL_Z - 25;        // ~-53.5
SPOOL_R = 12;  SPOOL_H = 10;     // SPOOL_H was 16
FLANGE_R = 15; FLANGE_T = 2;     // FLANGE_R was 18

THREAD_LEN = 70;    // matches pixelTravel spec (was 100)
PIXEL_Z = SPOOL_Z - SPOOL_H / 2 - THREAD_LEN;
PIXEL_W = 20;  PIXEL_H = 3;  // birch ply wafer (scaled from 40×40×6)

SHAFT_EXT = 60;     // (was 130)

// ---- COLORS ----
C_SUN1 = [0.80, 0.22, 0.18];
C_SUN2 = [0.67, 0.18, 0.22];
C_RING1 = [0.76, 0.69, 0.22];
C_RING2 = [0.67, 0.59, 0.25];
C_PLN1 = [0.31, 0.69, 0.31];
C_PLN2 = [0.24, 0.57, 0.24];
C_CAR = [0.25, 0.45, 0.78];
C_BVL = [0.73, 0.63, 0.39];
C_SPL = [0.55, 0.37, 0.20];
C_THR = [0.78, 0.78, 0.84];
C_PIX = [0.72, 0.58, 0.38];  // birch wood color
C_SHA = [0.86, 0.29, 0.22];
C_SHB = [0.22, 0.73, 0.29];
C_SHC = [0.22, 0.37, 0.88];
C_BRG = [0.35, 0.35, 0.40];
C_HSG = [0.25, 0.25, 0.30, 0.25];
C_ENV = [0.5, 0.5, 0.8, 0.08];  // envelope ghost

// ---- TOGGLES ----
SHOW_SHAFT_A = true;
SHOW_SHAFT_B = true;
SHOW_SHAFT_C = true;
SHOW_BEVELS  = true;
SHOW_HOUSING = true;
SHOW_STAGE1  = true;
SHOW_STAGE2  = true;
SHOW_CARRIERS = true;
SHOW_OUTPUT  = true;
SHOW_SPOOL   = true;
SHOW_THREAD  = true;
SHOW_PIXEL   = true;
SHOW_BEARINGS = true;
SHOW_ENVELOPE = true;  // 50mm pitch cell ghost

// ---- KINEMATICS ----
// Each shaft spins at a different rate to create wave interference
A_IN = POS * 360;            // shaft A: 1.00×
B_IN = POS * 360 * 1.13;    // shaft B: 1.13× (rain ratio)
C_IN = POS * 360 * 0.87;    // shaft C: 0.87× (rain ratio)

SUN1_A  = A_IN;
RING1_A = B_IN;
CAR1_A  = (SUN1_A * S1_T + RING1_A * R1_T) / (S1_T + R1_T);
SUN2_A  = CAR1_A;
RING2_A = C_IN;
CAR2_A  = (SUN2_A * S2_T + RING2_A * R2_T) / (S2_T + R2_T);

// Output spool rotation (drives thread winding)
SPOOL_A = CAR2_A;

// =============================================================
// MAIN ASSEMBLY
// =============================================================
main_assembly();

module main_assembly() {
    if (SHOW_ENVELOPE) envelope_ghost();
    if (SHOW_SHAFT_A) shaft_layer_A();
    if (SHOW_SHAFT_B) shaft_layer_B();
    if (SHOW_SHAFT_C) shaft_layer_C();
    if (SHOW_BEVELS)  bevel_towers();
    if (SHOW_HOUSING) housing_shell();
    if (SHOW_STAGE1)  stage_1();
    if (SHOW_STAGE2)  stage_2();
    if (SHOW_CARRIERS) carrier_assy();
    if (SHOW_OUTPUT)  output_bevel_assy();
    if (SHOW_SPOOL)   spool_assy();
    if (SHOW_THREAD)  thread_line();
    if (SHOW_PIXEL)   pixel_block();
}

// =============================================================
// ENVELOPE GHOST — 50mm pitch cell boundary
// =============================================================

module envelope_ghost() {
    color(C_ENV)
    translate([0, 0, LAY_C / 2])
    cube([GRID_PITCH, GRID_PITCH, LAY_C + 20], center=true);
}

// =============================================================
// SHAFTS — all horizontal in XY plane
// cylinder default is Z; rotate([0,90,0]) → along X
// =============================================================

module shaft_layer_A() {
    // A-shaft along X at Z=0. Hex. IS the planetary axis.
    color(C_SHA)
    rotate([0, 90, 0])
    rotate([0, 0, SUN1_A])
    cylinder(d=SHAFT_HEX, h=SHAFT_EXT * 2, center=true, $fn=6);

    if (SHOW_BEARINGS)
        for (sx = [-1, 1])
            color(C_BRG)
            translate([sx * (HOUSING_LEN / 2 + BEARING_W / 2 + 1), 0, 0])
            rotate([0, 90, 0])
            _bearing();
}

module shaft_layer_B() {
    color(C_SHB)
    translate([0, 0, LAY_B])
    rotate([0, 0, 60])
    rotate([0, 90, 0])
    rotate([0, 0, RING1_A])
    cylinder(d=SHAFT_D, h=SHAFT_EXT * 2, center=true);

    if (SHOW_BEARINGS)
        for (sx = [-1, 1])
            color(C_BRG)
            translate([0, 0, LAY_B])
            rotate([0, 0, 60])
            translate([sx * SHAFT_EXT * 0.85, 0, 0])
            rotate([0, 90, 0])
            _bearing();
}

module shaft_layer_C() {
    color(C_SHC)
    translate([0, 0, LAY_C])
    rotate([0, 0, 120])
    rotate([0, 90, 0])
    rotate([0, 0, RING2_A])
    cylinder(d=SHAFT_D, h=SHAFT_EXT * 2, center=true);

    if (SHOW_BEARINGS)
        for (sx = [-1, 1])
            color(C_BRG)
            translate([0, 0, LAY_C])
            rotate([0, 0, 120])
            translate([sx * SHAFT_EXT * 0.85, 0, 0])
            rotate([0, 90, 0])
            _bearing();
}

// =============================================================
// BEVEL TOWERS — vertical shafts from B/C layers to rings
// =============================================================

module bevel_towers() {
    BV_THICK = 5;  // face thickness for MOD=1, BV_T=12 (was 14)

    // B-tower: B-layer → Ring1
    bt_y = R1_PR + WALL + 5;
    bt_top = LAY_B;
    bt_bot = 2;

    translate([0, bt_y, 0]) {
        // Vertical shaft
        color(C_BVL)
        translate([0, 0, (bt_top + bt_bot) / 2])
        cylinder(d=BVL_SHAFT_D, h=bt_top - bt_bot, center=true);

        // Upper bevel pair at B-layer
        translate([0, 0, bt_top]) {
            color([C_SHB[0] + 0.1, C_SHB[1] + 0.1, C_SHB[2] + 0.1])
            bevel_gear(mod=MOD, teeth=BV_T, mate_teeth=BV_T,
                       thickness=BV_THICK, shaft_diam=BVL_SHAFT_D);

            color(C_BVL)
            rotate([0, 0, 60])
            rotate([90, 0, 0])
            bevel_gear(mod=MOD, teeth=BV_T, mate_teeth=BV_T,
                       thickness=BV_THICK, shaft_diam=SHAFT_D);
        }

        // Lower bevel → connects to Ring1 gear
        translate([0, 0, bt_bot])
        color([C_BVL[0] - 0.1, C_BVL[1] - 0.1, C_BVL[2] - 0.1])
        rotate([180, 0, 0])
        bevel_gear(mod=MOD, teeth=BV_T, mate_teeth=BV_T,
                   thickness=BV_THICK, shaft_diam=BVL_SHAFT_D);
    }

    // C-tower: C-layer → Ring2
    ct_x = R2_PR + WALL + 5;
    ct_top = LAY_C;
    ct_bot = 2;

    translate([ct_x, 0, 0]) {
        color(C_BVL)
        translate([0, 0, (ct_top + ct_bot) / 2])
        cylinder(d=BVL_SHAFT_D, h=ct_top - ct_bot, center=true);

        translate([0, 0, ct_top]) {
            color([C_SHC[0] + 0.1, C_SHC[1] + 0.1, C_SHC[2] + 0.1])
            bevel_gear(mod=MOD, teeth=BV_T, mate_teeth=BV_T,
                       thickness=BV_THICK, shaft_diam=BVL_SHAFT_D);

            color(C_BVL)
            rotate([0, 0, 120])
            rotate([90, 0, 0])
            bevel_gear(mod=MOD, teeth=BV_T, mate_teeth=BV_T,
                       thickness=BV_THICK, shaft_diam=SHAFT_D);
        }

        translate([0, 0, ct_bot])
        color([C_BVL[0] - 0.1, C_BVL[1] - 0.1, C_BVL[2] - 0.1])
        rotate([180, 0, 0])
        bevel_gear(mod=MOD, teeth=BV_T, mate_teeth=BV_T,
                   thickness=BV_THICK, shaft_diam=BVL_SHAFT_D);
    }
}

// =============================================================
// HOUSING — transparent shell around both planetary stages
// =============================================================

module housing_shell() {
    color(C_HSG)
    rotate([0, 90, 0])
    difference() {
        cylinder(r=HOUSING_OR, h=HOUSING_LEN, center=true);
        cylinder(r=HOUSING_OR - WALL, h=HOUSING_LEN + 1, center=true);
        cylinder(d=SHAFT_HEX + TOL * 2, h=HOUSING_LEN + 2, center=true);
    }
}

// =============================================================
// STAGE 1 — Sun1 + Ring1 + 3×Planet1 (left side, -X)
// All BOSL2 gears sit in XY plane by default with axis Z.
// We rotate([0,90,0]) to align axis with X (A-shaft direction).
//
// Profile shift: planets have auto-shift (8T < 17T minimum).
// Ring gear must have profile_shift >= planet's shift for
// correct internal meshing.
// =============================================================

module stage_1() {
    s1x = -(GFW / 2 + STAGE_GAP / 2);

    translate([s1x, 0, 0]) {
        // SUN1 — on A-shaft (auto profile shift)
        color(C_SUN1)
        rotate([0, 90, 0])
        rotate([0, 0, SUN1_A])
        spur_gear(mod=MOD, teeth=S1_T, thickness=GFW,
                  shaft_diam=SHAFT_HEX, gear_spin=0,
                  backlash=0.1);

        // RING1 — profile_shift matches planet for internal mesh
        color(C_RING1)
        rotate([0, 90, 0])
        rotate([0, 0, RING1_A])
        ring_gear(mod=MOD, teeth=R1_T, thickness=GFW,
                  backing=WALL, gear_spin=0,
                  profile_shift=PS_P1, backlash=0.1);

        // 3 PLANETS orbiting on carrier
        rotate([0, 90, 0])
        rotate([0, 0, CAR1_A])
        for (i = [0:2]) {
            a = i * 120;
            rotate([0, 0, a])
            translate([ORB1, 0, 0]) {
                p_spin = -(CAR1_A - SUN1_A) * S1_T / P1_T;
                color(C_PLN1)
                rotate([0, 0, p_spin])
                spur_gear(mod=MOD, teeth=P1_T, thickness=GFW * 0.85,
                          shaft_diam=3, backlash=0.1);
            }
        }
    }
}

// =============================================================
// STAGE 2 — Sun2 + Ring2 + 3×Planet2 (right side, +X)
// =============================================================

module stage_2() {
    s2x = (GFW / 2 + STAGE_GAP / 2);

    translate([s2x, 0, 0]) {
        // SUN2 (auto profile shift)
        color(C_SUN2)
        rotate([0, 90, 0])
        rotate([0, 0, SUN2_A])
        spur_gear(mod=MOD, teeth=S2_T, thickness=GFW,
                  shaft_diam=SHAFT_D, backlash=0.1);

        // RING2 — profile_shift matches planet
        color(C_RING2)
        rotate([0, 90, 0])
        rotate([0, 0, RING2_A])
        ring_gear(mod=MOD, teeth=R2_T, thickness=GFW,
                  backing=WALL,
                  profile_shift=PS_P2, backlash=0.1);

        // 3 PLANETS (30° phase offset)
        rotate([0, 90, 0])
        rotate([0, 0, CAR2_A])
        for (i = [0:2]) {
            a = i * 120 + 30;
            rotate([0, 0, a])
            translate([ORB2, 0, 0]) {
                p_spin = -(CAR2_A - SUN2_A) * S2_T / P2_T;
                color(C_PLN2)
                rotate([0, 0, p_spin])
                spur_gear(mod=MOD, teeth=P2_T, thickness=GFW * 0.85,
                          shaft_diam=3, backlash=0.1);
            }
        }
    }
}

// =============================================================
// CARRIERS — plates + pins + coupling shaft
// =============================================================

module carrier_assy() {
    s1x = -(GFW / 2 + STAGE_GAP / 2);
    s2x = (GFW / 2 + STAGE_GAP / 2);

    // Carrier 1
    color(C_CAR)
    translate([s1x, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        for (side = [-1, 1])
            translate([0, 0, side * (GFW / 2 - CARRIER_T / 2)])
            cylinder(r=ORB1 + P1_PR + 2, h=CARRIER_T, center=true);
        for (i = [0:2]) {
            a = i * 120;
            rotate([0, 0, a])
            translate([ORB1, 0, 0])
            cylinder(d=3, h=GFW + 4, center=true);
        }
    }

    // Coupling shaft (carrier1 → sun2)
    color(C_CAR)
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A])
    cylinder(d=SHAFT_D - 1, h=STAGE_GAP + GFW, center=true);

    // Carrier 2
    color(C_CAR)
    translate([s2x, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        for (side = [-1, 1])
            translate([0, 0, side * (GFW / 2 - CARRIER_T / 2)])
            cylinder(r=ORB2 + P2_PR + 2, h=CARRIER_T, center=true);
        for (i = [0:2]) {
            a = i * 120 + 30;
            rotate([0, 0, a])
            translate([ORB2, 0, 0])
            cylinder(d=3, h=GFW + 4, center=true);
        }
    }
}

// =============================================================
// OUTPUT BEVEL — horizontal carrier2 → vertical spool
// =============================================================

module output_bevel_assy() {
    obx = GFW / 2 + STAGE_GAP / 2;
    OB_THICK = 5;  // MOD=1, BV_OUT_T=10 (was 12)

    translate([obx, 0, OUT_BVL_Z]) {
        // Horizontal bevel (from carrier2 axis)
        color(C_BVL)
        rotate([0, 90, 0])
        bevel_gear(mod=MOD, teeth=BV_OUT_T, mate_teeth=BV_OUT_T,
                   thickness=OB_THICK, shaft_diam=OUT_SHAFT_D);

        // Vertical bevel (turns motion downward)
        color([C_BVL[0] - 0.08, C_BVL[1] - 0.08, C_BVL[2] - 0.08])
        translate([0, 0, -OB_THICK])
        rotate([180, 0, 0])
        bevel_gear(mod=MOD, teeth=BV_OUT_T, mate_teeth=BV_OUT_T,
                   thickness=OB_THICK, shaft_diam=OUT_SHAFT_D);
    }

    // Vertical shaft: housing bottom → output bevel
    color(C_CAR)
    translate([obx, 0, (0 + OUT_BVL_Z) / 2])
    cylinder(d=OUT_SHAFT_D, h=abs(OUT_BVL_Z), center=true);

    // Vertical shaft: output bevel → spool
    color([C_CAR[0] - 0.08, C_CAR[1] - 0.08, C_CAR[2] - 0.08])
    translate([obx, 0, (OUT_BVL_Z - OB_THICK + SPOOL_Z + SPOOL_H / 2) / 2])
    cylinder(d=OUT_SHAFT_D,
             h=abs(OUT_BVL_Z - OB_THICK - SPOOL_Z - SPOOL_H / 2),
             center=true);
}

// =============================================================
// SPOOL — r=12mm per spec, winds thread for height + spin
// =============================================================

module spool_assy() {
    obx = GFW / 2 + STAGE_GAP / 2;
    translate([obx, 0, SPOOL_Z])
    rotate([0, 0, SPOOL_A * 0.5]) {
        color(C_SPL) cylinder(r=SPOOL_R, h=SPOOL_H, center=true);
        color([C_SPL[0] + 0.1, C_SPL[1] + 0.06, C_SPL[2] + 0.02])
        for (sz = [-1, 1])
            translate([0, 0, sz * SPOOL_H / 2])
            cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
        // Thread grooves
        color(C_THR)
        for (g = [-3:2:3])
            translate([0, 0, g])
            rotate_extrude() translate([SPOOL_R + 0.3, 0, 0]) circle(r=0.3);
        // Bore
        color([C_CAR[0] - 0.1, C_CAR[1] - 0.1, C_CAR[2] - 0.1])
        cylinder(d=OUT_SHAFT_D + 1.5, h=SPOOL_H + 3, center=true);
    }
}

// =============================================================
// THREAD + PIXEL (birch wood element)
// =============================================================

module thread_line() {
    obx = GFW / 2 + STAGE_GAP / 2;
    t_top = SPOOL_Z - SPOOL_H / 2 - 1;
    t_bot = PIXEL_Z + PIXEL_H / 2 + 1;
    color(C_THR)
    translate([obx, 0, (t_top + t_bot) / 2])
    cylinder(d=0.6, h=abs(t_top - t_bot), center=true);
}

module pixel_block() {
    obx = GFW / 2 + STAGE_GAP / 2;
    translate([obx, 0, PIXEL_Z]) {
        // Birch ply wafer — 20×20×3mm (half scale for viz,
        // actual: 40×40×6mm at full grid scale)
        color(C_PIX)
        rotate([0, 0, SPOOL_A * 0.04 + 15])
        cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);

        // Thread attachment point
        color(C_THR)
        translate([0, 0, PIXEL_H / 2 + 0.5])
        sphere(r=1);
    }
}

// =============================================================
// UTILITY
// =============================================================

module _bearing() {
    difference() {
        cylinder(d=BEARING_OD, h=BEARING_W, center=true);
        cylinder(d=BEARING_ID, h=BEARING_W + 1, center=true);
    }
}
