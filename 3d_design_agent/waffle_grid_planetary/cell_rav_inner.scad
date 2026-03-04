// ============================================================
// RAVIGNEAUX CELL TEST — INNER: Small Sun (Ss) + Inner Planet (Pi)
// Verifies mesh at MOD 0.8, N_Ss=11, N_Pi=8
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

// Animation
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_ANIMATION = true;
T = USE_ANIMATION ? $t : MANUAL_POSITION;
SUN_DEG = T * 360;

$fn = 64;

// Derived
CD = gear_dist(mod=MOD, teeth1=N_Ss, teeth2=N_Pi,
               profile_shift1=0, profile_shift2=0);
PLANET_SELF = -SUN_DEG * N_Ss / N_Pi;

echo(str("Ss-Pi CD = ", CD, "mm"));
echo(str("Ss outer R = ", outer_radius(mod=MOD, teeth=N_Ss)));
echo(str("Pi outer R = ", outer_radius(mod=MOD, teeth=N_Pi)));

// Small Sun — red, hex bore
color("red")
difference() {
    spur_gear(mod=MOD, teeth=N_Ss, pressure_angle=PA,
              thickness=GFW, backlash=BACKLASH/2,
              helical=HELIX_ANGLE, herringbone=true,
              gear_spin=SUN_DEG, anchor=CENTER);
    cylinder(h=GFW+2, d=5, center=true, $fn=6);  // hex bore
}

// 3 Inner Planets — green
for (i = [0:2]) {
    ang = i * 120 + T * 360 * N_Ss / (N_Ss + 2*N_Pi);  // carrier rotation
    px = CD * cos(ang);
    py = CD * sin(ang);
    p_self = -(SUN_DEG - ang) * N_Ss / N_Pi;

    color("green")
    translate([px, py, 0])
    difference() {
        spur_gear(mod=MOD, teeth=N_Pi, pressure_angle=PA,
                  thickness=GFW, backlash=BACKLASH/2,
                  helical=HELIX_ANGLE, herringbone=true,
                  gear_spin=p_self, anchor=CENTER);
        cylinder(h=GFW+2, d=2, center=true);  // pin bore
    }
}
