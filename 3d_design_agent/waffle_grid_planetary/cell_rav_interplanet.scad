// ============================================================
// RAVIGNEAUX CELL TEST — INTERPLANET: Inner Planet (Pi) ↔ Outer Planet (Po)
// Verifies mesh at MOD 0.8, N_Pi=8, N_Po=9
// Shows both planet types at their orbit radii
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// Parameters
MOD = 0.8;
PA = 20;
HELIX_ANGLE = 20;
GFW = 6;
BACKLASH = 0.21;

N_Ss = 11;
N_Pi = 8;
N_Po = 9;

// Animation
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_ANIMATION = true;
T = USE_ANIMATION ? $t : MANUAL_POSITION;

$fn = 64;

// Derived
ORB_Pi = gear_dist(mod=MOD, teeth1=N_Ss, teeth2=N_Pi,
                   profile_shift1=0, profile_shift2=0);
CD_Pi_Po = gear_dist(mod=MOD, teeth1=N_Pi, teeth2=N_Po,
                     profile_shift1=0, profile_shift2=0);
ORB_Po = ORB_Pi + CD_Pi_Po;

echo(str("ORB_Pi = ", ORB_Pi, "mm"));
echo(str("ORB_Po = ", ORB_Po, "mm"));
echo(str("CD_Pi_Po = ", CD_Pi_Po, "mm (should be ", (N_Pi+N_Po)*MOD/2, ")"));

// Static display: one inner planet at ORB_Pi on +X, one outer planet meshing with it

// Inner planet — green (at ORB_Pi, 0)
PI_SPIN = T * 360;
color("green")
translate([ORB_Pi, 0, 0])
difference() {
    spur_gear(mod=MOD, teeth=N_Pi, pressure_angle=PA,
              thickness=GFW, backlash=BACKLASH/2,
              helical=HELIX_ANGLE, herringbone=true,
              gear_spin=PI_SPIN, anchor=CENTER);
    cylinder(h=GFW+2, d=2, center=true);
}

// Outer planet — yellowgreen (at ORB_Po, 0 — meshing with inner planet)
PO_SPIN = -PI_SPIN * N_Pi / N_Po;
color("yellowgreen")
translate([ORB_Po, 0, 0])
difference() {
    spur_gear(mod=MOD, teeth=N_Po, pressure_angle=PA,
              thickness=GFW, backlash=BACKLASH/2,
              helical=HELIX_ANGLE, herringbone=true,
              gear_spin=PO_SPIN + 180/N_Po, anchor=CENTER);
    cylinder(h=GFW+2, d=2, center=true);
}

// Reference circles
color("gray", 0.2) {
    // Inner orbit
    difference() {
        cylinder(r=ORB_Pi + 0.2, h=0.2, center=true, $fn=64);
        cylinder(r=ORB_Pi - 0.2, h=0.4, center=true, $fn=64);
    }
    // Outer orbit
    difference() {
        cylinder(r=ORB_Po + 0.2, h=0.2, center=true, $fn=64);
        cylinder(r=ORB_Po - 0.2, h=0.4, center=true, $fn=64);
    }
}
