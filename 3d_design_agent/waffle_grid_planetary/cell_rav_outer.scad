// ============================================================
// RAVIGNEAUX CELL TEST — OUTER: Large Sun (SL) + Outer Planet (Po) + Ring (R)
// Verifies mesh at MOD 0.8, N_SL=27, N_Po=9, N_R=45
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// Parameters
MOD = 0.8;
PA = 20;
HELIX_ANGLE = 20;
GFW = 6;
BACKLASH = 0.21;
RING_WALL = 1.5;

N_SL = 27;
N_Po = 9;
N_R  = 45;

// Animation
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_ANIMATION = true;
T = USE_ANIMATION ? $t : MANUAL_POSITION;
SUN_DEG = T * 360;

$fn = 64;

// Derived
CD_SL_Po = gear_dist(mod=MOD, teeth1=N_SL, teeth2=N_Po,
                     profile_shift1=0, profile_shift2=0);
ORB_Po = CD_SL_Po;  // Outer planet orbit = SL-Po center distance

// Ring gear spin phasing
RING_SPIN0 = 180/N_R * (1 - (N_SL % 2));

// Planet phasing
QUANT = 360 / (N_SL + N_R);
PLANET_ANGLES = [for (i = [0:2])
    QUANT * round(i * 360 / 3 / QUANT)
];
PLANET_SPINS0 = [for (ang = PLANET_ANGLES)
    (N_SL/N_Po) * (ang - 90) + 90 + ang + 180/N_Po
];

// Carrier rotation (ring free, only sun input)
// With ring free: carrier = sun * N_SL / (N_SL + N_R) approximately
// For visualization, assume ring stationary:
CARRIER_DEG = SUN_DEG * N_SL / (N_SL + N_R);
PLANET_SELF = -(SUN_DEG - CARRIER_DEG) * N_SL / N_Po;

echo(str("SL-Po CD = ", CD_SL_Po, "mm"));
echo(str("ORB_Po = ", ORB_Po, "mm"));
echo(str("Ring root R = ", root_radius(mod=MOD, teeth=N_R, internal=true)));

// Large Sun — magenta
color("magenta")
difference() {
    spur_gear(mod=MOD, teeth=N_SL, pressure_angle=PA,
              thickness=GFW, backlash=BACKLASH/2,
              helical=HELIX_ANGLE, herringbone=true,
              gear_spin=SUN_DEG, anchor=CENTER);
    cylinder(h=GFW+2, d=10, center=true);  // B-tube bore
}

// Ring — blue (stationary for this test)
color("royalblue", 0.7)
ring_gear(mod=MOD, teeth=N_R, pressure_angle=PA,
          thickness=GFW, backing=RING_WALL,
          backlash=BACKLASH/2,
          helical=HELIX_ANGLE, herringbone=true,
          gear_spin=RING_SPIN0, anchor=CENTER);

// 3 Outer Planets — yellowgreen
for (i = [0:2]) {
    orbit_angle_i = PLANET_ANGLES[i];
    planet_spin0_i = PLANET_SPINS0[i];
    current_orbit = orbit_angle_i + CARRIER_DEG;
    px = ORB_Po * cos(current_orbit);
    py = ORB_Po * sin(current_orbit);

    color("yellowgreen")
    translate([px, py, 0])
    difference() {
        spur_gear(mod=MOD, teeth=N_Po, pressure_angle=PA,
                  thickness=GFW, backlash=BACKLASH/2,
                  helical=HELIX_ANGLE, herringbone=true,
                  gear_spin=planet_spin0_i + PLANET_SELF, anchor=CENTER);
        cylinder(h=GFW+2, d=2, center=true);  // pin bore
    }
}
