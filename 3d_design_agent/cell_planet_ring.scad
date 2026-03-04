// Cell: Planet-Ring Internal Mesh (MOD=1.0, 8T inside 29T)
// Validated in Phase 0 test harness. Standalone animated cell.
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

MOD=1; PA=20; GFW=6; BL=0.21;
P_T=8; R_T=29; RING_WALL=3;
MANUAL_POSITION = 0.0; // [0:0.01:1]
$fn=64;

T = MANUAL_POSITION;
ANG = T * 360;
d = gear_dist(mod=MOD, teeth1=R_T, teeth2=P_T, internal1=true,
              profile_shift1=0, profile_shift2=0);

color("blue", 0.5)
ring_gear(mod=MOD, teeth=R_T, pressure_angle=PA, thickness=GFW,
          backing=RING_WALL, profile_shift=0, backlash=BL/2, gear_spin=0);

color("green")
back(d)
spur_gear(mod=MOD, teeth=P_T, pressure_angle=PA, thickness=GFW,
          profile_shift=0, backlash=BL/2, gear_spin=ANG);
