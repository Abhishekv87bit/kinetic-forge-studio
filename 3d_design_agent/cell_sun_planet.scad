// Cell: Sun-Planet External Mesh (MOD=1.0, 13T+8T)
// Validated in Phase 0 test harness. Standalone animated cell.
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

MOD=1; PA=20; GFW=6; BL=0.21;
S_T=13; P_T=8;
MANUAL_POSITION = 0.0; // [0:0.01:1]
$fn=64;

T = MANUAL_POSITION;
ANG = T * 360;
d = gear_dist(mod=MOD, teeth1=S_T, teeth2=P_T, profile_shift1=0, profile_shift2=0);

color("red")
spur_gear(mod=MOD, teeth=S_T, pressure_angle=PA, thickness=GFW,
          profile_shift=0, backlash=BL/2, gear_spin=-90 + ANG);

color("green")
right(d)
spur_gear(mod=MOD, teeth=P_T, pressure_angle=PA, thickness=GFW,
          profile_shift=0, backlash=BL/2, gear_spin=90-180/P_T - ANG*S_T/P_T);
