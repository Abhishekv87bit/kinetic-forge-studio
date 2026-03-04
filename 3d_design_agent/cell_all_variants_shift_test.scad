// ============================================================
// P0 FINAL: ALL 3 WILLIS VARIANTS — Correct Profile Shift Strategy
// ============================================================
// KEY INSIGHT: Compensating shifts (x_sun=+0.5, x_planet=-0.5)
// are WRONG — the negative shift on planet causes undercut there!
//
// CORRECT APPROACH: Both shifts POSITIVE (extended center distance)
// - Both gears avoid undercut
// - Center distance increases (BOSL2 gear_dist handles this)
// - Each variant already has different orbits, so CD variation is OK
//
// Formula: min_teeth = ceil(2 * (1 - x) / sin²(PA))
//   Negative x INCREASES min_teeth → undercut gets WORSE
//   Positive x DECREASES min_teeth → undercut gets BETTER
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// === CORE PARAMETERS ===
MOD = 1.0;
PA  = 25;            // PA=25 confirmed from P0 undercut test
GFW = 6;
BL  = 0.21;
R_T = 29;            // Ring teeth (shared housing for all variants)

// === PROFILE SHIFT STRATEGY (ALL POSITIVE) ===
// V1 (S=7,P=11): Sun needs big shift, planet is fine
V1_XS = 0.5;  V1_XP = 0.3;  // Sum = +0.8, extended CD
// V2 (S=13,P=8): Both near borderline at PA=25 (min=12)
V2_XS = 0.3;  V2_XP = 0.4;  // Sum = +0.7, extended CD
// V3 (S=19,P=5): Sun is fine, planet needs big shift
V3_XS = 0.0;  V3_XP = 0.6;  // Sum = +0.6, extended CD

// === VARIANT TOOTH COUNTS ===
V1_S = 7;   V1_P = 11;   // Willis: w_A=0.038, w_B=0.157, w_C=0.806
V2_S = 13;  V2_P = 8;    // Willis: w_A=0.096, w_B=0.214, w_C=0.690
V3_S = 19;  V3_P = 5;    // Willis: w_A=0.157, w_B=0.239, w_C=0.604

// === ANIMATION ===
MANUAL_POSITION = 0.0; // [0:0.01:1]
$fn = 64;
T   = MANUAL_POSITION;
ANG = T * 360;

// === CENTER DISTANCES (BOSL2 computes exact working CD) ===
d1 = gear_dist(mod=MOD, teeth1=V1_S, teeth2=V1_P,
               profile_shift1=V1_XS, profile_shift2=V1_XP);
d2 = gear_dist(mod=MOD, teeth1=V2_S, teeth2=V2_P,
               profile_shift1=V2_XS, profile_shift2=V2_XP);
d3 = gear_dist(mod=MOD, teeth1=V3_S, teeth2=V3_P,
               profile_shift1=V3_XS, profile_shift2=V3_XP);

// Standard CDs (no shift) for comparison
d1_std = gear_dist(mod=MOD, teeth1=V1_S, teeth2=V1_P, profile_shift1=0, profile_shift2=0);
d2_std = gear_dist(mod=MOD, teeth1=V2_S, teeth2=V2_P, profile_shift1=0, profile_shift2=0);
d3_std = gear_dist(mod=MOD, teeth1=V3_S, teeth2=V3_P, profile_shift1=0, profile_shift2=0);

// === UNDERCUT DIAGNOSTICS ===
function min_t(pa, x) = ceil(2 * (1 - x) / pow(sin(pa), 2));
function uc_check(teeth, pa, x) = teeth >= min_t(pa, x) ? "PASS" : "FAIL";

echo("╔═══════════════════════════════════════════════════════════╗");
echo("║    P0 FINAL: ALL VARIANTS — CORRECT SHIFT STRATEGY       ║");
echo("║    PA=25°, ALL shifts POSITIVE (extended center dist)     ║");
echo("╠═══════════════════════════════════════════════════════════╣");
echo("║                                                           ║");
echo("║ VARIANT 1: S=7, P=11  (C-dominated)                      ║");
echo(str("║   Sun  x=+", V1_XS, ": min=", min_t(PA, V1_XS),
         "T, have ", V1_S, "T → ", uc_check(V1_S, PA, V1_XS), "              ║"));
echo(str("║   Planet x=+", V1_XP, ": min=", min_t(PA, V1_XP),
         "T, have ", V1_P, "T → ", uc_check(V1_P, PA, V1_XP), "            ║"));
echo(str("║   CD: ", d1, "mm (std: ", d1_std, "mm, delta: +",
         d1 - d1_std, "mm)                  ║"));
echo("║                                                           ║");
echo("║ VARIANT 2: S=13, P=8  (moderate)                         ║");
echo(str("║   Sun  x=+", V2_XS, ": min=", min_t(PA, V2_XS),
         "T, have ", V2_S, "T → ", uc_check(V2_S, PA, V2_XS), "            ║"));
echo(str("║   Planet x=+", V2_XP, ": min=", min_t(PA, V2_XP),
         "T, have ", V2_P, "T → ", uc_check(V2_P, PA, V2_XP), "             ║"));
echo(str("║   CD: ", d2, "mm (std: ", d2_std, "mm, delta: +",
         d2 - d2_std, "mm)               ║"));
echo("║                                                           ║");
echo("║ VARIANT 3: S=19, P=5  (balanced)                         ║");
echo(str("║   Sun  x=+", V3_XS, ": min=", min_t(PA, V3_XS),
         "T, have ", V3_S, "T → ", uc_check(V3_S, PA, V3_XS), "            ║"));
echo(str("║   Planet x=+", V3_XP, ": min=", min_t(PA, V3_XP),
         "T, have ", V3_P, "T → ", uc_check(V3_P, PA, V3_XP), "             ║"));
echo(str("║   CD: ", d3, "mm (std: ", d3_std, "mm, delta: +",
         d3 - d3_std, "mm)               ║"));
echo("║                                                           ║");
echo("╠═══════════════════════════════════════════════════════════╣");

// Ring mesh check: planet must also mesh with ring
// For planet-ring internal mesh, undercut is different (internal gears)
// Internal gear min teeth ≈ R_min = 2.5 * P + constant (less restrictive)
// At R=29, this is generally fine for external planets
echo("║ RING MESH (R=29, internal):                               ║");
// For internal gears, the constraint is different — interference check
// (R - P) must be ≥ 4 for standard, less with shift
echo(str("║   V1: R-P = ", R_T - V1_P, " (≥4 → ",
         R_T - V1_P >= 4 ? "OK" : "RISK", ")                              ║"));
echo(str("║   V2: R-P = ", R_T - V2_P, " (≥4 → ",
         R_T - V2_P >= 4 ? "OK" : "RISK", ")                             ║"));
echo(str("║   V3: R-P = ", R_T - V3_P, " (≥4 → ",
         R_T - V3_P >= 4 ? "OK" : "RISK", ")                             ║"));
echo("║                                                           ║");

// Orbit radius = working center distance (sun to planet center)
// Must also check: orbit + planet_OA ≤ ring_pitch_radius for clearance
echo("║ ORBIT RADII (working center distances):                   ║");
echo(str("║   V1 orbit: ", d1, "mm                                       ║"));
echo(str("║   V2 orbit: ", d2, "mm                                     ║"));
echo(str("║   V3 orbit: ", d3, "mm                                       ║"));
echo(str("║   Ring pitch radius: ", MOD * R_T / 2, "mm                        ║"));
echo("║                                                           ║");

// Carrier plate: all orbits must fit inside ring
echo("║ CARRIER FIT CHECK:                                        ║");
// Planet addendum = MOD * (1 + x_planet) for shifted gears
V1_PA_OD = MOD * (V1_P + 2 * (1 + V1_XP));
V2_PA_OD = MOD * (V2_P + 2 * (1 + V2_XP));
V3_PA_OD = MOD * (V3_P + 2 * (1 + V3_XP));
echo(str("║   V1: orbit + planet_tip = ", d1 + V1_PA_OD/2,
         "mm vs ring_dedendum=", MOD*(R_T - 2*1.25)/2, "mm → ",
         d1 + V1_PA_OD/2 < MOD*(R_T - 2*1.25)/2 ? "FITS" : "TIGHT", " ║"));
echo(str("║   V2: orbit + planet_tip = ", d2 + V2_PA_OD/2,
         "mm vs ring_dedendum=", MOD*(R_T - 2*1.25)/2, "mm → ",
         d2 + V2_PA_OD/2 < MOD*(R_T - 2*1.25)/2 ? "FITS" : "TIGHT", " ║"));
echo(str("║   V3: orbit + planet_tip = ", d3 + V3_PA_OD/2,
         "mm vs ring_dedendum=", MOD*(R_T - 2*1.25)/2, "mm → ",
         d3 + V3_PA_OD/2 < MOD*(R_T - 2*1.25)/2 ? "FITS" : "TIGHT", " ║"));

echo("╠═══════════════════════════════════════════════════════════╣");
echo("║ CONCLUSION: ALL 6 GEARS PASS UNDERCUT CHECK              ║");
echo("║ ACTION: Print V1 pair (most stressed) for physical test  ║");
echo("╚═══════════════════════════════════════════════════════════╝");

// === VISUAL LAYOUT ===
SPACING = 45;
total_w = d1 + d2 + d3 + 2 * SPACING;
x1 = -total_w/2 + d1/2;
x2 = x1 + d1/2 + SPACING + d2/2;
x3 = x2 + d2/2 + SPACING + d3/2;

// V1 pair (pink/salmon)
translate([x1, 0, 0]) {
    color([0.9, 0.3, 0.4], 0.9)
    spur_gear(mod=MOD, teeth=V1_S, pressure_angle=PA, thickness=GFW,
              profile_shift=V1_XS, backlash=BL/2,
              gear_spin=-90 + ANG);
    color([0.8, 0.5, 0.5], 0.9)
    right(d1)
    spur_gear(mod=MOD, teeth=V1_P, pressure_angle=PA, thickness=GFW,
              profile_shift=V1_XP, backlash=BL/2,
              gear_spin=90 - 180/V1_P - ANG * V1_S/V1_P);
}

// V2 pair (blue)
translate([x2, 0, 0]) {
    color([0.3, 0.4, 0.9], 0.9)
    spur_gear(mod=MOD, teeth=V2_S, pressure_angle=PA, thickness=GFW,
              profile_shift=V2_XS, backlash=BL/2,
              gear_spin=-90 + ANG);
    color([0.5, 0.5, 0.8], 0.9)
    right(d2)
    spur_gear(mod=MOD, teeth=V2_P, pressure_angle=PA, thickness=GFW,
              profile_shift=V2_XP, backlash=BL/2,
              gear_spin=90 - 180/V2_P - ANG * V2_S/V2_P);
}

// V3 pair (green)
translate([x3, 0, 0]) {
    color([0.2, 0.8, 0.3], 0.9)
    spur_gear(mod=MOD, teeth=V3_S, pressure_angle=PA, thickness=GFW,
              profile_shift=V3_XS, backlash=BL/2,
              gear_spin=-90 + ANG);
    color([0.4, 0.7, 0.4], 0.9)
    right(d3)
    spur_gear(mod=MOD, teeth=V3_P, pressure_angle=PA, thickness=GFW,
              profile_shift=V3_XP, backlash=BL/2,
              gear_spin=90 - 180/V3_P - ANG * V3_S/V3_P);
}

// Labels
lz = GFW + 1;
translate([x1, -20, lz]) color([0.9, 0.3, 0.4])
linear_extrude(0.5) text(str("V1: S=", V1_S, " P=", V1_P), size=2.2,
                          halign="center", font="Arial:style=Bold");
translate([x1, -24, lz]) color([0.9, 0.3, 0.4])
linear_extrude(0.5) text(str("x=[+", V1_XS, ",+", V1_XP, "] CD=", d1, "mm"),
                          size=1.6, halign="center");

translate([x2, -20, lz]) color([0.3, 0.4, 0.9])
linear_extrude(0.5) text(str("V2: S=", V2_S, " P=", V2_P), size=2.2,
                          halign="center", font="Arial:style=Bold");
translate([x2, -24, lz]) color([0.3, 0.4, 0.9])
linear_extrude(0.5) text(str("x=[+", V2_XS, ",+", V2_XP, "] CD=", d2, "mm"),
                          size=1.6, halign="center");

translate([x3, -20, lz]) color([0.2, 0.8, 0.3])
linear_extrude(0.5) text(str("V3: S=", V3_S, " P=", V3_P), size=2.2,
                          halign="center", font="Arial:style=Bold");
translate([x3, -24, lz]) color([0.2, 0.8, 0.3])
linear_extrude(0.5) text(str("x=[+", V3_XS, ",+", V3_XP, "] CD=", d3, "mm"),
                          size=1.6, halign="center");

translate([0, 24, lz]) color("white")
linear_extrude(0.5) text("P0 FINAL: All Variants PA=25 — Both Shifts Positive",
                          size=2.5, halign="center", font="Arial:style=Bold");
