include <config_v4.scad>

// Where does each arm physically cross the shaft axis?
// Arm: from junction point to star tip
// Shaft: line through helix center in helix_a direction
//
// For H3 (60°): arms 1 and 2
// Arm 1: stub=0° tip=37°. From JR(170) to STR(354)
// Arm 2: stub=120° tip=83°

JR = 170; STR = 354;
HR_val = 354 / sqrt(3) + 78 / (2 * tan(30));  // 271.9

// H3 center
hcx = HR_val * cos(60);  // 136
hcy = HR_val * sin(60);  // 235.5
sdx = cos(60);  // shaft direction
sdy = sin(60);

// Arm 1 (green): junction at (170,0) → tip at (354*cos(37), 354*sin(37))
a1_jx = 170; a1_jy = 0;
a1_tx = 354*cos(37); a1_ty = 354*sin(37);

// Arm 1 direction
a1_dx = a1_tx - a1_jx; a1_dy = a1_ty - a1_jy;

// Find parameter s where arm1(s) is closest to shaft line
// Arm point: (a1_jx + s*a1_dx, a1_jy + s*a1_dy)
// Shaft line: (hcx + t*sdx, hcy + t*sdy)
// Perpendicular distance = |cross product| / |shaft dir| (shaft dir is unit)
// perp(s) = (a1_jx+s*a1_dx - hcx)*sdy - (a1_jy+s*a1_dy - hcy)*sdx
// Set perp=0: (a1_jx-hcx)*sdy + s*a1_dx*sdy - (a1_jy-hcy)*sdx - s*a1_dy*sdx = 0
// s*(a1_dx*sdy - a1_dy*sdx) = (a1_jy-hcy)*sdx - (a1_jx-hcx)*sdy
s1_num = (a1_jy-hcy)*sdx - (a1_jx-hcx)*sdy;
s1_den = a1_dx*sdy - a1_dy*sdx;
s1 = s1_num / s1_den;

// Arm 1 crossing point
cx1 = a1_jx + s1*a1_dx;
cy1 = a1_jy + s1*a1_dy;
proj1 = (cx1-hcx)*sdx + (cy1-hcy)*sdy;

echo(str("=== H3 (60°) shaft crossings ==="));
echo(str("  Arm A1: crosses shaft at frac=", round(s1*1000)/1000, " XY=[", round(cx1*10)/10, ",", round(cy1*10)/10, "] proj=", round(proj1*10)/10, "mm"));

// Arm 2 (blue): junction at (170*cos(120), 170*sin(120)) → tip at (354*cos(83), 354*sin(83))
a2_jx = 170*cos(120); a2_jy = 170*sin(120);
a2_tx = 354*cos(83); a2_ty = 354*sin(83);
a2_dx = a2_tx - a2_jx; a2_dy = a2_ty - a2_jy;

s2_num = (a2_jy-hcy)*sdx - (a2_jx-hcx)*sdy;
s2_den = a2_dx*sdy - a2_dy*sdx;
s2 = s2_num / s2_den;

cx2 = a2_jx + s2*a2_dx;
cy2 = a2_jy + s2*a2_dy;
proj2 = (cx2-hcx)*sdx + (cy2-hcy)*sdy;

echo(str("  Arm A2: crosses shaft at frac=", round(s2*1000)/1000, " XY=[", round(cx2*10)/10, ",", round(cy2*10)/10, "] proj=", round(proj2*10)/10, "mm"));

echo(str("  Cam: -91 to +91mm | Journals: -101 to +101mm"));
echo(str("  Need journal to extend to: near=", round(proj2*10)/10, " far=", round(proj1*10)/10));
