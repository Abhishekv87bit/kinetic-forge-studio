// Cell: External Ring Teeth + Pinion (EXT_MOD=1.5, 26T+8T)
// New mesh type — needs visual validation.
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

EXT_MOD=1.5; PA=20; GFW=6; BL=0.21;
EXT_T=26; BPIN_T=8;
// Ring body inner radius (from internal teeth)
RING_INNER_R = 16.5;  // root_radius(mod=1, teeth=29, internal=true) + 3

MANUAL_POSITION = 0.0; // [0:0.01:1]
$fn=64;

T = MANUAL_POSITION;
ANG = T * 360;

d = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=BPIN_T,
              profile_shift1=0, profile_shift2=0);

echo(DRIVE_CD=d);
echo(EXT_OR=outer_radius(mod=EXT_MOD, teeth=EXT_T));
echo(BPIN_OR=outer_radius(mod=EXT_MOD, teeth=BPIN_T));

// Ring external gear (simulated as spur gear with center hole)
color("blue", 0.7)
difference() {
    spur_gear(mod=EXT_MOD, teeth=EXT_T, pressure_angle=PA, thickness=GFW,
              profile_shift=0, backlash=BL/2, gear_spin=-90 + ANG);
    // Hollow center (ring body)
    cylinder(h=GFW+2, r=RING_INNER_R, center=true, $fn=64);
}

// Pinion on B/C shaft
color("green")
right(d)
spur_gear(mod=EXT_MOD, teeth=BPIN_T, pressure_angle=PA, thickness=GFW,
          profile_shift=0, backlash=BL/2,
          gear_spin=90-180/BPIN_T - ANG*EXT_T/BPIN_T);

// Center distance line
color("gray", 0.3)
translate([0,0,-1])
linear_extrude(0.5) hull() { circle(0.3); translate([d,0]) circle(0.3); }
