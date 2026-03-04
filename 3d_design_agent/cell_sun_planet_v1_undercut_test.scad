// ============================================================
// P0: S=7 UNDERCUT TEST — Willis Variant V1 (S=7, P=11, R=29)
// Tests profile_shift correction for 7-tooth sun gear
// Reuleaux G3 warns: S≥36 for smooth mesh. Our S=7 is aggressive.
// ============================================================
// 3-WAY COMPARISON (left to right):
//   A) PA=20, no shift     → UNDERCUT (min=18T, we have 7T)
//   B) PA=20, shift=+0.5   → STILL UNDERCUT (min=9T with shift)
//   C) PA=25, shift=+0.5   → FIXED (min=6T with shift at PA=25)
// Animate with MANUAL_POSITION to verify mesh engagement.
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// === CORE PARAMETERS ===
MOD = 1.0;           // Module (mm)
GFW = 6;             // Gear face width (mm)
BL  = 0.21;          // Total backlash (mm)

// Willis Variant V1: S=7, P=11, R=29
// Willis weights: w_A=0.038, w_B=0.157, w_C=0.806
S_T = 7;             // Sun teeth (UNDERCUT RISK)
P_T = 11;            // Planet teeth

// Profile shift coefficients
X_SUN    = 0.5;      // Positive shift on sun → reduces undercut
X_PLANET = -0.5;     // Compensating negative on planet → standard CD

// === ANIMATION ===
MANUAL_POSITION = 0.0; // [0:0.01:1]
$fn = 64;

T   = MANUAL_POSITION;
ANG = T * 360;

// === DISPLAY TOGGLES ===
SHOW_A = true;   // PA=20, no shift (undercut baseline)
SHOW_B = true;   // PA=20, shift=+0.5 (partial fix)
SHOW_C = true;   // PA=25, shift=+0.5 (RECOMMENDED)
SHOW_LABELS = true;
COL_SPACING = 30;  // Gap between pairs (mm)

// === 3 CONFIGURATIONS ===
// Config A: PA=20, no shift
PA_A = 20;  XS_A = 0;     XP_A = 0;
d_A = gear_dist(mod=MOD, teeth1=S_T, teeth2=P_T,
                profile_shift1=XS_A, profile_shift2=XP_A);

// Config B: PA=20, shift=+0.5
PA_B = 20;  XS_B = X_SUN;  XP_B = X_PLANET;
d_B = gear_dist(mod=MOD, teeth1=S_T, teeth2=P_T,
                profile_shift1=XS_B, profile_shift2=XP_B);

// Config C: PA=25, shift=+0.5
PA_C = 25;  XS_C = X_SUN;  XP_C = X_PLANET;
d_C = gear_dist(mod=MOD, teeth1=S_T, teeth2=P_T,
                profile_shift1=XS_C, profile_shift2=XP_C);

// === UNDERCUT DIAGNOSTICS ===
function min_teeth(pa) = ceil(2 / pow(sin(pa), 2));
function min_teeth_shifted(pa, x) = ceil(2 * (1 - x) / pow(sin(pa), 2));
function undercut_status(pa, x) =
    let(mt = x == 0 ? min_teeth(pa) : min_teeth_shifted(pa, x))
    S_T >= mt ? "PASS" : "FAIL";

echo("╔══════════════════════════════════════════╗");
echo("║     P0: S=7 UNDERCUT TEST RESULTS       ║");
echo("╠══════════════════════════════════════════╣");
echo(str("║ Config A: PA=20, x=0   → min=", min_teeth(20),
         "T → ", undercut_status(20, 0), "     ║"));
echo(str("║ Config B: PA=20, x=0.5 → min=", min_teeth_shifted(20, 0.5),
         "T → ", undercut_status(20, 0.5), "     ║"));
echo(str("║ Config C: PA=25, x=0.5 → min=", min_teeth_shifted(25, 0.5),
         "T → ", undercut_status(25, 0.5), "     ║"));
echo("╠══════════════════════════════════════════╣");
echo(str("║ Center dist A: ", d_A, " mm                  ║"));
echo(str("║ Center dist B: ", d_B, " mm                  ║"));
echo(str("║ Center dist C: ", d_C, " mm                  ║"));
echo("╠══════════════════════════════════════════╣");
echo("║ RECOMMENDATION: Config C (PA=25, x=+0.5)║");
echo("║ Next: Print Config C pair, test mesh     ║");
echo("╚══════════════════════════════════════════╝");

// === LAYOUT POSITIONS ===
// 3 pairs side-by-side, centered at origin
total_w = d_A + d_B + d_C + 2 * COL_SPACING;
x_A = -total_w/2 + d_A/2;
x_B = x_A + d_A/2 + COL_SPACING + d_B/2;
x_C = x_B + d_B/2 + COL_SPACING + d_C/2;

// === CONFIG A: PA=20, NO SHIFT (red = danger) ===
if (SHOW_A) {
    translate([x_A, 0, 0]) {
        color("red", 0.9)
        spur_gear(mod=MOD, teeth=S_T, pressure_angle=PA_A, thickness=GFW,
                  profile_shift=XS_A, backlash=BL/2,
                  gear_spin=-90 + ANG);

        color([1, 0.4, 0.4], 0.9)
        right(d_A)
        spur_gear(mod=MOD, teeth=P_T, pressure_angle=PA_A, thickness=GFW,
                  profile_shift=XP_A, backlash=BL/2,
                  gear_spin=90 - 180/P_T - ANG * S_T/P_T);
    }
}

// === CONFIG B: PA=20, SHIFT=+0.5 (yellow = warning) ===
if (SHOW_B) {
    translate([x_B, 0, 0]) {
        color("yellow", 0.9)
        spur_gear(mod=MOD, teeth=S_T, pressure_angle=PA_B, thickness=GFW,
                  profile_shift=XS_B, backlash=BL/2,
                  gear_spin=-90 + ANG);

        color([0.9, 0.8, 0.3], 0.9)
        right(d_B)
        spur_gear(mod=MOD, teeth=P_T, pressure_angle=PA_B, thickness=GFW,
                  profile_shift=XP_B, backlash=BL/2,
                  gear_spin=90 - 180/P_T - ANG * S_T/P_T);
    }
}

// === CONFIG C: PA=25, SHIFT=+0.5 (green = pass) ===
if (SHOW_C) {
    translate([x_C, 0, 0]) {
        color("green", 0.9)
        spur_gear(mod=MOD, teeth=S_T, pressure_angle=PA_C, thickness=GFW,
                  profile_shift=XS_C, backlash=BL/2,
                  gear_spin=-90 + ANG);

        color([0.3, 0.8, 0.5], 0.9)
        right(d_C)
        spur_gear(mod=MOD, teeth=P_T, pressure_angle=PA_C, thickness=GFW,
                  profile_shift=XP_C, backlash=BL/2,
                  gear_spin=90 - 180/P_T - ANG * S_T/P_T);
    }
}

// === LABELS ===
if (SHOW_LABELS) {
    label_z = GFW + 1;
    label_y = -15;

    // Config A label
    translate([x_A, label_y, label_z])
    color("red")
    linear_extrude(0.5)
    text("A: PA20 x=0", size=2, halign="center", font="Arial:style=Bold");

    translate([x_A, label_y - 4, label_z])
    color("red")
    linear_extrude(0.5)
    text("UNDERCUT", size=1.8, halign="center");

    // Config B label
    translate([x_B, label_y, label_z])
    color("yellow")
    linear_extrude(0.5)
    text("B: PA20 x=0.5", size=2, halign="center", font="Arial:style=Bold");

    translate([x_B, label_y - 4, label_z])
    color("yellow")
    linear_extrude(0.5)
    text("STILL UNDERCUT", size=1.8, halign="center");

    // Config C label
    translate([x_C, label_y, label_z])
    color("green")
    linear_extrude(0.5)
    text("C: PA25 x=0.5", size=2, halign="center", font="Arial:style=Bold");

    translate([x_C, label_y - 4, label_z])
    color("green")
    linear_extrude(0.5)
    text("PASS", size=1.8, halign="center");

    // Title
    translate([0, 22, label_z])
    color("white")
    linear_extrude(0.5)
    text(str("P0: V1 Sun=", S_T, "T Planet=", P_T, "T  Undercut Comparison"),
         size=2.5, halign="center", font="Arial:style=Bold");
}
