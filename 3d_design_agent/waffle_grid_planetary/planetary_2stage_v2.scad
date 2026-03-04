// ============================================================
// 2-STAGE COMPOUND PLANETARY DIFFERENTIAL — v2
// ============================================================
// Complete rebuild using BOSL2 gear_spin for all mesh phasing.
// 3 parallel input shafts (A=red, B=green, C=blue).
// Internal: MOD=1.0, External ring teeth: EXT_MOD=1.5.
//
// Kinematic chain:
//   A-shaft ──HEX──▶ Sun1 ──mesh──▶ Planet1 ──pin──▶ Carrier1
//   B-shaft ──HEX──▶ Pinion1 ──mesh──▶ Ring1(ext) ═══ Ring1(int) ──mesh──▶ Planet1
//   Carrier1 ──HEX──▶ Coupling Tube ──HEX──▶ Sun2
//   C-shaft ──HEX──▶ Pinion2 ──mesh──▶ Ring2(ext) ═══ Ring2(int) ──mesh──▶ Planet2
//   Planet2 ──pin──▶ Carrier2 ──▶ Spool ──▶ Thread ──▶ Pixel
//
// Differential equations:
//   CAR1 = (A*S1 + B*R1) / (S1+R1)
//   SUN2 = CAR1
//   CAR2 = (SUN2*S2 + C*R2) / (S2+R2)
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// ============================================================
// CUSTOMIZER — Animation
// ============================================================
/* [Animation] */
// Enable OpenSCAD View→Animate (FPS=10, Steps=100) for live animation.
USE_ANIMATION = true;
MANUAL_POSITION = 0.0; // [0:0.01:1]

/* [Shaft Inputs (degrees)] */
A_INPUT = 0; // [0:1:720] A-shaft (red) drives Sun1
B_INPUT = 0; // [0:1:720] B-shaft (green) drives Ring1
C_INPUT = 0; // [0:1:720] C-shaft (blue) drives Ring2

// ============================================================
// CUSTOMIZER — Visibility
// ============================================================
/* [Show/Hide Parts] */
SHOW_SUN1 = true;
SHOW_RING1 = true;
SHOW_PLANETS1 = true;
SHOW_CARRIER1 = true;
SHOW_BPINION = true;

SHOW_SUN2 = true;
SHOW_RING2 = true;
SHOW_PLANETS2 = true;
SHOW_CARRIER2 = true;
SHOW_CPINION = true;

SHOW_COUPLING = true;
SHOW_SHAFTS = true;
SHOW_BEARINGS = true;
SHOW_ENVELOPE = false;

/* [Display Options] */
EXPLODE = 0;           // [0:0.5:30]
CROSS_SECTION = false;
SIMPLE_GEO = false;    // Use cylinders instead of involute gears
FLAT_LAYOUT = false;    // Spread parts for 3D printing

// ============================================================
// PRIMARY PARAMETERS
// ============================================================
/* [Gear Parameters] */
MOD = 1.0;
EXT_MOD = 1.5;
PA = 20;
GFW = 6;
EXT_GFW = 6;
CARRIER_T = 2;
GAP = 3;
PIN_D = 2;
RING_WALL = 3;
N_PLANETS = 3;
BACKLASH = 0.21;

S1_T = 13;
P1_T = 8;
R1_T = 29;

S2_T = 11;
P2_T = 9;
R2_T = 29;

EXT_T = 26;
BPIN_T = 8;

/* [Shaft & Tolerances] */
SHAFT_D = 5;       // hex across-flats
PIP_TOL = 0.35;
BEARING_WALL = 1.5;

$fn = 64;

// ============================================================
// DERIVED VALUES
// ============================================================

// Center distances
S1_ORB = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                   profile_shift1=0, profile_shift2=0);
S2_ORB = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                   profile_shift1=0, profile_shift2=0);
DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=BPIN_T,
                     profile_shift1=0, profile_shift2=0);

// Ring body geometry
R1_ROOT_R = root_radius(mod=MOD, teeth=R1_T, internal=true);
R2_ROOT_R = root_radius(mod=MOD, teeth=R2_T, internal=true);
RING_INNER_R = R1_ROOT_R + RING_WALL;
EXT_OUTER_R = outer_radius(mod=EXT_MOD, teeth=EXT_T);

// Shaft hex geometry
HEX_CIRC_R = SHAFT_D / (2 * cos(30));
BEARING_ID = HEX_CIRC_R * 2 + 2 * PIP_TOL;
BEARING_OD = BEARING_ID + 2 * BEARING_WALL;

// Coupling tube hex (OD that mates with carrier1 and sun2)
COUPLING_HEX_AF = BEARING_OD + 1;  // across-flats of coupling hex OD
COUPLING_HEX_CR = (COUPLING_HEX_AF) / (2 * cos(30));

// Stage heights
STAGE1_H = CARRIER_T + GFW + CARRIER_T;  // 10mm
STAGE2_H = CARRIER_T + GFW + CARRIER_T;  // 10mm
TOTAL_STACK = STAGE1_H + GAP + STAGE2_H; // 23mm

// Axial positions (Z-axis = along shafts)
// Stage 1 centered at Z=0, Stage 2 offset by STAGE1_H/2 + GAP + STAGE2_H/2
STAGE1_Z = 0;
STAGE2_Z = STAGE1_H/2 + GAP + STAGE2_H/2;

// ============================================================
// PLANET PHASING — BOSL2 formulas from gears.scad:3685-3699
// ============================================================

// Stage 1
S1_QUANT = 360 / (S1_T + R1_T);
S1_PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    S1_QUANT * round(i * 360 / N_PLANETS / S1_QUANT)
];
S1_RING_SPIN0 = 180/R1_T * (1 - (S1_T % 2));
S1_PLANET_SPINS0 = [for (ang = S1_PLANET_ANGLES)
    (S1_T/P1_T) * (ang - 90) + 90 + ang + 180/P1_T
];

// Stage 2
S2_QUANT = 360 / (S2_T + R2_T);
S2_PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    S2_QUANT * round(i * 360 / N_PLANETS / S2_QUANT)
];
S2_RING_SPIN0 = 180/R2_T * (1 - (S2_T % 2));
S2_PLANET_SPINS0 = [for (ang = S2_PLANET_ANGLES)
    (S2_T/P2_T) * (ang - 90) + 90 + ang + 180/P2_T
];

// ============================================================
// DIFFERENTIAL KINEMATICS
// ============================================================
T = USE_ANIMATION ? $t : MANUAL_POSITION;

// Shaft rotations
A_DEG = A_INPUT + T * 360;  // sun1 input
B_DEG = B_INPUT;             // ring1 input (via B-pinion)
C_DEG = C_INPUT;             // ring2 input (via C-pinion)

// Stage 1 differential
CAR1_DEG = (A_DEG * S1_T + B_DEG * R1_T) / (S1_T + R1_T);
P1_SELF = -(A_DEG - CAR1_DEG) * S1_T / P1_T;

// Coupling: carrier1 → sun2
SUN2_DEG = CAR1_DEG;

// Stage 2 differential
CAR2_DEG = (SUN2_DEG * S2_T + C_DEG * R2_T) / (S2_T + R2_T);
P2_SELF = -(SUN2_DEG - CAR2_DEG) * S2_T / P2_T;

// Pinion rotations (external mesh)
BPIN_DEG = -B_DEG * EXT_T / BPIN_T;
CPIN_DEG = -C_DEG * EXT_T / BPIN_T;

echo("=== DIFFERENTIAL OUTPUT ===");
echo(A_DEG=A_DEG, B_DEG=B_DEG, C_DEG=C_DEG);
echo(CAR1_DEG=CAR1_DEG, SUN2_DEG=SUN2_DEG, CAR2_DEG=CAR2_DEG);

// ============================================================
// UTILITY MODULES
// ============================================================

module hex_profile(af, tol=0) {
    r = (af + 2*tol) / (2 * cos(30));
    circle(r=r, $fn=6);
}

module bearing_bushing(h) {
    color("goldenrod")
    difference() {
        cylinder(h=h, d=BEARING_OD, center=true);
        cylinder(h=h+1, d=BEARING_ID, center=true);
    }
}

// ============================================================
// STAGE 1 PARTS
// ============================================================

module sun1() {
    color("red")
    translate([0, 0, STAGE1_Z])
    difference() {
        if (SIMPLE_GEO)
            cylinder(h=GFW, r=pitch_radius(mod=MOD, teeth=S1_T), center=true);
        else
            spur_gear(mod=MOD, teeth=S1_T, pressure_angle=PA, thickness=GFW,
                      profile_shift=0, backlash=BACKLASH/2, gear_spin=A_DEG);
        // Hex bore for A-shaft
        linear_extrude(GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

module ring1() {
    translate([0, 0, STAGE1_Z]) {
        // Internal teeth (MOD=1.0, 29T)
        color("royalblue", 0.7)
        if (SIMPLE_GEO)
            difference() {
                cylinder(h=GFW, r=RING_INNER_R, center=true);
                cylinder(h=GFW+1, r=root_radius(mod=MOD, teeth=R1_T, internal=true), center=true);
            }
        else
            ring_gear(mod=MOD, teeth=R1_T, pressure_angle=PA, thickness=GFW,
                      backing=RING_WALL, profile_shift=0, backlash=BACKLASH/2,
                      gear_spin=S1_RING_SPIN0 + B_DEG);

        // External teeth (EXT_MOD=1.5, 26T)
        color("steelblue", 0.8)
        if (SIMPLE_GEO)
            difference() {
                cylinder(h=EXT_GFW, r=EXT_OUTER_R, center=true);
                cylinder(h=EXT_GFW+1, r=RING_INNER_R-0.01, center=true);
            }
        else
            difference() {
                spur_gear(mod=EXT_MOD, teeth=EXT_T, pressure_angle=PA,
                          thickness=EXT_GFW, profile_shift=0, backlash=BACKLASH/2,
                          gear_spin=-90 + B_DEG);
                cylinder(h=EXT_GFW+2, r=RING_INNER_R-0.01, center=true, $fn=64);
            }
    }
}

module planets1() {
    for (i = [0:N_PLANETS-1]) {
        orbit_i = S1_PLANET_ANGLES[i];
        spin0_i = S1_PLANET_SPINS0[i];
        current_orbit = orbit_i + CAR1_DEG;
        px = S1_ORB * cos(current_orbit);
        py = S1_ORB * sin(current_orbit);

        color("green")
        translate([px, py, STAGE1_Z])
        if (SIMPLE_GEO)
            cylinder(h=GFW, r=pitch_radius(mod=MOD, teeth=P1_T), center=true);
        else
            spur_gear(mod=MOD, teeth=P1_T, pressure_angle=PA, thickness=GFW,
                      profile_shift=0, backlash=BACKLASH/2,
                      gear_spin=spin0_i + P1_SELF);
    }
}

module carrier1() {
    car_r = S1_ORB + PIN_D/2 + 2;
    bot_z = STAGE1_Z - GFW/2 - CARRIER_T;
    top_z = STAGE1_Z + GFW/2;

    // Bottom plate
    color("orange", 0.6)
    translate([0, 0, bot_z + CARRIER_T/2])
    rotate([0, 0, CAR1_DEG])
    difference() {
        cylinder(h=CARRIER_T, r=car_r, center=true);
        cylinder(h=CARRIER_T+1, d=BEARING_OD + 2*PIP_TOL, center=true);
    }

    // Top plate
    color("orange", 0.6)
    translate([0, 0, top_z + CARRIER_T/2])
    rotate([0, 0, CAR1_DEG])
    difference() {
        cylinder(h=CARRIER_T, r=car_r, center=true);
        cylinder(h=CARRIER_T+1, d=BEARING_OD + 2*PIP_TOL, center=true);
    }

    // Planet pins (rotate with carrier)
    for (i = [0:N_PLANETS-1]) {
        orbit_i = S1_PLANET_ANGLES[i];
        current_orbit = orbit_i + CAR1_DEG;
        px = S1_ORB * cos(current_orbit);
        py = S1_ORB * sin(current_orbit);

        color("silver")
        translate([px, py, STAGE1_Z])
        cylinder(h=GFW + 2*CARRIER_T + 1, d=PIN_D, center=true);
    }
}

module b_pinion() {
    translate([DRIVE_CD, 0, STAGE1_Z])
    color("limegreen")
    difference() {
        if (SIMPLE_GEO)
            cylinder(h=EXT_GFW, r=pitch_radius(mod=EXT_MOD, teeth=BPIN_T), center=true);
        else
            spur_gear(mod=EXT_MOD, teeth=BPIN_T, pressure_angle=PA,
                      thickness=EXT_GFW, profile_shift=0, backlash=BACKLASH/2,
                      gear_spin=90-180/BPIN_T + BPIN_DEG);
        linear_extrude(EXT_GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// STAGE 2 PARTS
// ============================================================

module sun2() {
    color("magenta")
    translate([0, 0, STAGE2_Z])
    difference() {
        if (SIMPLE_GEO)
            cylinder(h=GFW, r=pitch_radius(mod=MOD, teeth=S2_T), center=true);
        else
            spur_gear(mod=MOD, teeth=S2_T, pressure_angle=PA, thickness=GFW,
                      profile_shift=0, backlash=BACKLASH/2, gear_spin=SUN2_DEG);
        // Hex bore — keyed to coupling tube hex OD
        linear_extrude(GFW+2, center=true)
        hex_profile(COUPLING_HEX_AF, PIP_TOL);
    }
}

module ring2() {
    translate([0, 0, STAGE2_Z]) {
        // Internal teeth
        color("royalblue", 0.7)
        if (SIMPLE_GEO)
            difference() {
                cylinder(h=GFW, r=RING_INNER_R, center=true);
                cylinder(h=GFW+1, r=root_radius(mod=MOD, teeth=R2_T, internal=true), center=true);
            }
        else
            ring_gear(mod=MOD, teeth=R2_T, pressure_angle=PA, thickness=GFW,
                      backing=RING_WALL, profile_shift=0, backlash=BACKLASH/2,
                      gear_spin=S2_RING_SPIN0 + C_DEG);

        // External teeth
        color("steelblue", 0.8)
        if (SIMPLE_GEO)
            difference() {
                cylinder(h=EXT_GFW, r=EXT_OUTER_R, center=true);
                cylinder(h=EXT_GFW+1, r=RING_INNER_R-0.01, center=true);
            }
        else
            difference() {
                spur_gear(mod=EXT_MOD, teeth=EXT_T, pressure_angle=PA,
                          thickness=EXT_GFW, profile_shift=0, backlash=BACKLASH/2,
                          gear_spin=-90 + C_DEG);
                cylinder(h=EXT_GFW+2, r=RING_INNER_R-0.01, center=true, $fn=64);
            }
    }
}

module planets2() {
    for (i = [0:N_PLANETS-1]) {
        orbit_i = S2_PLANET_ANGLES[i];
        spin0_i = S2_PLANET_SPINS0[i];
        current_orbit = orbit_i + CAR2_DEG;
        px = S2_ORB * cos(current_orbit);
        py = S2_ORB * sin(current_orbit);

        color("yellowgreen")
        translate([px, py, STAGE2_Z])
        if (SIMPLE_GEO)
            cylinder(h=GFW, r=pitch_radius(mod=MOD, teeth=P2_T), center=true);
        else
            spur_gear(mod=MOD, teeth=P2_T, pressure_angle=PA, thickness=GFW,
                      profile_shift=0, backlash=BACKLASH/2,
                      gear_spin=spin0_i + P2_SELF);
    }
}

module carrier2() {
    car_r = S2_ORB + PIN_D/2 + 2;
    bot_z = STAGE2_Z - GFW/2 - CARRIER_T;
    top_z = STAGE2_Z + GFW/2;

    // Bottom plate
    color("darkorange", 0.6)
    translate([0, 0, bot_z + CARRIER_T/2])
    rotate([0, 0, CAR2_DEG])
    difference() {
        cylinder(h=CARRIER_T, r=car_r, center=true);
        cylinder(h=CARRIER_T+1, d=BEARING_OD + 2*PIP_TOL, center=true);
    }

    // Top plate
    color("darkorange", 0.6)
    translate([0, 0, top_z + CARRIER_T/2])
    rotate([0, 0, CAR2_DEG])
    difference() {
        cylinder(h=CARRIER_T, r=car_r, center=true);
        cylinder(h=CARRIER_T+1, d=BEARING_OD + 2*PIP_TOL, center=true);
    }

    // Planet pins
    for (i = [0:N_PLANETS-1]) {
        orbit_i = S2_PLANET_ANGLES[i];
        current_orbit = orbit_i + CAR2_DEG;
        px = S2_ORB * cos(current_orbit);
        py = S2_ORB * sin(current_orbit);

        color("silver")
        translate([px, py, STAGE2_Z])
        cylinder(h=GFW + 2*CARRIER_T + 1, d=PIN_D, center=true);
    }

    // Output hub (spool attachment)
    color("darkorange", 0.8)
    translate([0, 0, top_z + CARRIER_T + 1])
    rotate([0, 0, CAR2_DEG])
    difference() {
        cylinder(h=4, r=BEARING_OD/2 + 1, center=true);
        cylinder(h=5, d=BEARING_ID, center=true);
    }
}

module c_pinion() {
    translate([DRIVE_CD, 0, STAGE2_Z])
    color("cyan")
    difference() {
        if (SIMPLE_GEO)
            cylinder(h=EXT_GFW, r=pitch_radius(mod=EXT_MOD, teeth=BPIN_T), center=true);
        else
            spur_gear(mod=EXT_MOD, teeth=BPIN_T, pressure_angle=PA,
                      thickness=EXT_GFW, profile_shift=0, backlash=BACKLASH/2,
                      gear_spin=90-180/BPIN_T + CPIN_DEG);
        linear_extrude(EXT_GFW+2, center=true)
        hex_profile(SHAFT_D, PIP_TOL);
    }
}

// ============================================================
// COUPLING TUBE — bridges Carrier1 to Sun2
// ============================================================
module coupling_tube() {
    // Spans from carrier1 top plate to sun2 bottom
    c_bot = STAGE1_Z + GFW/2 + CARRIER_T;  // top of carrier1 top plate
    c_top = STAGE2_Z - GFW/2;               // bottom of sun2
    c_len = c_top - c_bot;
    c_mid = (c_bot + c_top) / 2;

    color("gold", 0.8)
    translate([0, 0, c_mid])
    rotate([0, 0, CAR1_DEG])  // rotates with carrier1 = sun2
    difference() {
        // Hex OD (mates with carrier1 hub and sun2 bore)
        linear_extrude(c_len, center=true)
        hex_profile(COUPLING_HEX_AF);
        // Round bore (bearing on A-shaft — free-spinning)
        cylinder(h=c_len+2, d=BEARING_ID, center=true, $fn=32);
    }
}

// ============================================================
// SHAFTS
// ============================================================
module shafts() {
    total_len = TOTAL_STACK + 20;

    // A-shaft (red) — through center, full length
    color("red", 0.4)
    translate([0, 0, TOTAL_STACK/4])
    linear_extrude(total_len, center=true)
    hex_profile(SHAFT_D);

    // B-shaft (green) — at DRIVE_CD, stage 1 height only
    color("green", 0.4)
    translate([DRIVE_CD, 0, STAGE1_Z])
    linear_extrude(STAGE1_H + 10, center=true)
    hex_profile(SHAFT_D);

    // C-shaft (blue) — at DRIVE_CD, stage 2 height only
    color("blue", 0.4)
    translate([DRIVE_CD, 0, STAGE2_Z])
    linear_extrude(STAGE2_H + 10, center=true)
    hex_profile(SHAFT_D);
}

// ============================================================
// BEARINGS (printed journal bushings)
// ============================================================
module bearings() {
    // Carrier1 bearings on A-shaft
    translate([0, 0, STAGE1_Z - GFW/2 - CARRIER_T/2])
    bearing_bushing(CARRIER_T);
    translate([0, 0, STAGE1_Z + GFW/2 + CARRIER_T/2])
    bearing_bushing(CARRIER_T);

    // Coupling tube bearing on A-shaft
    c_bot = STAGE1_Z + GFW/2 + CARRIER_T;
    c_top = STAGE2_Z - GFW/2;
    c_len = c_top - c_bot;
    c_mid = (c_bot + c_top) / 2;
    translate([0, 0, c_mid])
    bearing_bushing(c_len);

    // Carrier2 bearings on A-shaft
    translate([0, 0, STAGE2_Z - GFW/2 - CARRIER_T/2])
    bearing_bushing(CARRIER_T);
    translate([0, 0, STAGE2_Z + GFW/2 + CARRIER_T/2])
    bearing_bushing(CARRIER_T);
}

// ============================================================
// ENVELOPE GHOST (50mm grid reference)
// ============================================================
module envelope() {
    color("white", 0.1)
    translate([0, 0, TOTAL_STACK/4])
    cube([50, 50, 50], center=true);
}

// ============================================================
// FLAT PRINT LAYOUT
// ============================================================
module flat_layout() {
    spacing = EXT_OUTER_R * 2.5;
    row2 = spacing;

    // Row 1: Sun1, Sun2, Coupling tube
    translate([0, 0, 0]) sun1();
    translate([spacing, 0, 0]) sun2();
    translate([spacing*2, 0, 0]) coupling_tube();

    // Row 2: Ring1, Ring2
    translate([0, row2, 0]) ring1();
    translate([spacing, row2, 0]) ring2();

    // Row 3: Carrier plates
    translate([0, row2*2, 0]) carrier1();
    translate([spacing, row2*2, 0]) carrier2();

    // Row 4: Pinions + bearings
    translate([0, row2*3, 0]) b_pinion();
    translate([spacing, row2*3, 0]) c_pinion();
}

// ============================================================
// MAIN ASSEMBLY
// ============================================================
module full_assembly() {
    // Stage 1
    if (SHOW_SUN1)     translate([0, 0, -EXPLODE]) sun1();
    if (SHOW_RING1)    ring1();
    if (SHOW_PLANETS1) planets1();
    if (SHOW_CARRIER1) translate([0, 0, -EXPLODE*0.5]) carrier1();
    if (SHOW_BPINION)  b_pinion();

    // Coupling
    if (SHOW_COUPLING) translate([0, 0, EXPLODE*0.3]) coupling_tube();

    // Stage 2
    if (SHOW_SUN2)     translate([0, 0, EXPLODE]) sun2();
    if (SHOW_RING2)    translate([0, 0, EXPLODE]) ring2();
    if (SHOW_PLANETS2) translate([0, 0, EXPLODE]) planets2();
    if (SHOW_CARRIER2) translate([0, 0, EXPLODE*1.5]) carrier2();
    if (SHOW_CPINION)  translate([0, 0, EXPLODE]) c_pinion();

    // Infrastructure
    if (SHOW_SHAFTS)   shafts();
    if (SHOW_BEARINGS) bearings();
    if (SHOW_ENVELOPE) envelope();
}

// ============================================================
// RENDER
// ============================================================
if (FLAT_LAYOUT) {
    flat_layout();
} else if (CROSS_SECTION) {
    difference() {
        full_assembly();
        translate([0, -100, -50]) cube([200, 200, 200]);
    }
} else {
    full_assembly();
}
