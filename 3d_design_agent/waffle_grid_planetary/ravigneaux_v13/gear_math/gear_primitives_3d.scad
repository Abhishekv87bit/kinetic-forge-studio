// ============================================================
// 3D GEAR PRIMITIVES — Helical extrusions of 2D profiles
// ============================================================
// External helical, internal helical ring, planet (with bore).
// ============================================================

use <gear_profiles_2d.scad>

// --- External helical gear (twist extrusion of involute 2D) ---
module helical_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    rotate([0, 0, -twist/2])
    linear_extrude(height=height, twist=twist, slices=80, convexity=10)
    involute_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// --- Internal helical ring gear (twist extrusion of internal 2D) ---
// Boolean subtraction: annular blank minus external involute profile.
// Twist direction: same as external gear (RH external meshes with RH tooth space).
module helical_ring_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    rotate([0, 0, -twist/2])
    linear_extrude(height=height, twist=twist, slices=80, convexity=10)
    internal_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// --- Planet gear (helical external + axial bore) ---
module planet_gear(teeth, mod, helix_angle, height, bore_d, pressure_angle=20) {
    difference() {
        helical_gear(teeth, mod, helix_angle, height, pressure_angle);
        translate([0, 0, -0.1])
        cylinder(d=bore_d, h=height + 0.2, $fn=32);
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
$fn = 64;
// Ss (31T external)
color([0.15, 0.55, 0.30])
helical_gear(teeth=31, mod=0.866, helix_angle=30, height=22);

// Po (25T planet with bore) — offset for visibility
translate([40, 0, 0])
color([0.85, 0.25, 0.20])
planet_gear(teeth=25, mod=0.866, helix_angle=30, height=22, bore_d=8);

// Ring (88T internal) — offset
translate([100, 0, 0])
color([0.25, 0.25, 0.28], 0.5)
helical_ring_gear(teeth=88, mod=0.866, helix_angle=30, height=22);
