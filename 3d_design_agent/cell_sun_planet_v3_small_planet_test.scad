// ============================================================
// P0b: V3 SMALL PLANET TEST — Willis Variant V3 (S=19, P=5, R=29)
// Tests 5-tooth planet gear feasibility
// P=5 is near practical minimum (ravigneaux_params Assert 12: P≥6)
// ============================================================
// Compares V3 (S=19,P=5) vs V2 (S=13,P=8) vs V1 (S=7,P=11)
// All at PA=25, profile_shift=+0.5 on sun (our recommended config)
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// === PARAMETERS ===
MOD = 1.0;
PA  = 25;            // PA=25 per P0 recommendation
GFW = 6;
BL  = 0.21;
R_T = 29;            // Ring teeth (shared across all variants)

// Profile shift (applied to sun only, per P0 findings)
X_SUN = 0.5;
X_PLANET = -0.5;     // Compensating shift

// === 3 VARIANTS ===
// V1: S=7, P=11 (C-dominated, w_C=0.806)
V1_S = 7;   V1_P = 11;
// V2: S=13, P=8 (moderate, w_C=0.690)
V2_S = 13;  V2_P = 8;
// V3: S=19, P=5 (balanced, w_C=0.604) — P=5 IS THE RISK
V3_S = 19;  V3_P = 5;

MANUAL_POSITION = 0.0; // [0:0.01:1]
$fn = 64;

T   = MANUAL_POSITION;
ANG = T * 360;
SPACING = 40;

// === CENTER DISTANCES ===
d1 = gear_dist(mod=MOD, teeth1=V1_S, teeth2=V1_P,
               profile_shift1=X_SUN, profile_shift2=X_PLANET);
d2 = gear_dist(mod=MOD, teeth1=V2_S, teeth2=V2_P,
               profile_shift1=X_SUN, profile_shift2=X_PLANET);
d3 = gear_dist(mod=MOD, teeth1=V3_S, teeth2=V3_P,
               profile_shift1=X_SUN, profile_shift2=X_PLANET);

// === DIAGNOSTICS ===
echo("╔══════════════════════════════════════════╗");
echo("║   3 WILLIS VARIANTS — PA=25, x=+0.5     ║");
echo("╠══════════════════════════════════════════╣");
echo(str("║ V1: S=", V1_S, " P=", V1_P, "  CD=", d1,
         "mm  w=[.038,.157,.806] ║"));
echo(str("║ V2: S=", V2_S, " P=", V2_P, "  CD=", d2,
         "mm  w=[.096,.214,.690] ║"));
echo(str("║ V3: S=", V3_S, " P=", V3_P, "   CD=", d3,
         "mm  w=[.157,.239,.604] ║"));
echo("╠══════════════════════════════════════════╣");

// Min teeth check for planets (no shift on planet in production?)
// Actually planet gets X_PLANET=-0.5 → needs check too
MIN_P_TEETH = ceil(2 * (1 - abs(X_PLANET)) / pow(sin(PA), 2));
echo(str("║ Min planet teeth (PA=25, |x|=0.5): ", MIN_P_TEETH, "T         ║"));
echo(str("║ V3 planet = ", V3_P, "T → ",
         V3_P >= MIN_P_TEETH ? "PASS" : "FAIL — P=5 too small!", "              ║"));

// Root diameter check: planet must have positive root circle
V3_P_ROOT_DIA = MOD * (V3_P - 2.5 + 2 * X_PLANET);
echo(str("║ V3 planet root dia: ", V3_P_ROOT_DIA, "mm ",
         V3_P_ROOT_DIA > 0 ? "(positive ✓)" : "(NEGATIVE — gear impossible!)", "   ║"));

// Sun root diameter for each variant
V1_S_ROOT = MOD * (V1_S - 2.5 + 2 * X_SUN);
V2_S_ROOT = MOD * (V2_S - 2.5 + 2 * X_SUN);
V3_S_ROOT = MOD * (V3_S - 2.5 + 2 * X_SUN);
echo(str("║ Sun root dia: V1=", V1_S_ROOT, " V2=", V2_S_ROOT, " V3=", V3_S_ROOT, "mm  ║"));

// Orbit radius check (sun + planet = ring constraint)
echo("╠══════════════════════════════════════════╣");
echo(str("║ V1: S+2P = ", V1_S + 2*V1_P, " (need ", R_T, ") → ",
         V1_S + 2*V1_P == R_T ? "✓" : "✗", "            ║"));
echo(str("║ V2: S+2P = ", V2_S + 2*V2_P, " (need ", R_T, ") → ",
         V2_S + 2*V2_P == R_T ? "✓" : "✗", "            ║"));
echo(str("║ V3: S+2P = ", V3_S + 2*V3_P, " (need ", R_T, ") → ",
         V3_S + 2*V3_P == R_T ? "✓" : "✗", "            ║"));
echo("╚══════════════════════════════════════════╝");

// === LAYOUT ===
total_w = d1 + d2 + d3 + 2 * SPACING;
x1 = -total_w/2 + d1/2;
x2 = x1 + d1/2 + SPACING + d2/2;
x3 = x2 + d2/2 + SPACING + d3/2;

// === V1: S=7, P=11 (pink tones) ===
translate([x1, 0, 0]) {
    color([0.9, 0.3, 0.4], 0.9)
    spur_gear(mod=MOD, teeth=V1_S, pressure_angle=PA, thickness=GFW,
              profile_shift=X_SUN, backlash=BL/2,
              gear_spin=-90 + ANG);

    color([0.8, 0.5, 0.5], 0.9)
    right(d1)
    spur_gear(mod=MOD, teeth=V1_P, pressure_angle=PA, thickness=GFW,
              profile_shift=X_PLANET, backlash=BL/2,
              gear_spin=90 - 180/V1_P - ANG * V1_S/V1_P);
}

// === V2: S=13, P=8 (blue tones — current design) ===
translate([x2, 0, 0]) {
    color([0.3, 0.4, 0.9], 0.9)
    spur_gear(mod=MOD, teeth=V2_S, pressure_angle=PA, thickness=GFW,
              profile_shift=X_SUN, backlash=BL/2,
              gear_spin=-90 + ANG);

    color([0.5, 0.5, 0.8], 0.9)
    right(d2)
    spur_gear(mod=MOD, teeth=V2_P, pressure_angle=PA, thickness=GFW,
              profile_shift=X_PLANET, backlash=BL/2,
              gear_spin=90 - 180/V2_P - ANG * V2_S/V2_P);
}

// === V3: S=19, P=5 (green tones — THIS IS THE TEST) ===
translate([x3, 0, 0]) {
    color([0.2, 0.8, 0.3], 0.9)
    spur_gear(mod=MOD, teeth=V3_S, pressure_angle=PA, thickness=GFW,
              profile_shift=X_SUN, backlash=BL/2,
              gear_spin=-90 + ANG);

    color([0.4, 0.7, 0.4], 0.9)
    right(d3)
    spur_gear(mod=MOD, teeth=V3_P, pressure_angle=PA, thickness=GFW,
              profile_shift=X_PLANET, backlash=BL/2,
              gear_spin=90 - 180/V3_P - ANG * V3_S/V3_P);
}

// === LABELS ===
label_z = GFW + 1;

translate([x1, -18, label_z]) color([0.9, 0.3, 0.4])
linear_extrude(0.5)
text(str("V1: S=", V1_S, " P=", V1_P), size=2, halign="center", font="Arial:style=Bold");

translate([x2, -18, label_z]) color([0.3, 0.4, 0.9])
linear_extrude(0.5)
text(str("V2: S=", V2_S, " P=", V2_P), size=2, halign="center", font="Arial:style=Bold");

translate([x3, -18, label_z]) color([0.2, 0.8, 0.3])
linear_extrude(0.5)
text(str("V3: S=", V3_S, " P=", V3_P), size=2, halign="center", font="Arial:style=Bold");

translate([x1, -22, label_z]) color([0.9, 0.3, 0.4])
linear_extrude(0.5)
text("w_C=0.806", size=1.5, halign="center");

translate([x2, -22, label_z]) color([0.3, 0.4, 0.9])
linear_extrude(0.5)
text("w_C=0.690", size=1.5, halign="center");

translate([x3, -22, label_z]) color([0.2, 0.8, 0.3])
linear_extrude(0.5)
text("w_C=0.604", size=1.5, halign="center");

translate([0, 22, label_z]) color("white")
linear_extrude(0.5)
text("3 Willis Variants — All PA=25, shift=+0.5", size=2.5, halign="center", font="Arial:style=Bold");
