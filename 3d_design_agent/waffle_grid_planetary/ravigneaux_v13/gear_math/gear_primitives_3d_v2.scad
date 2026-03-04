// ============================================================
// 3D GEAR PRIMITIVES — Herringbone (Double-Helical) Upgrade
// ============================================================
use <gear_profiles_2d.scad>

// Standard single helical (kept as a base builder)
module helical_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);
    
    rotate([0, 0, -twist/2])
    linear_extrude(height=height, twist=twist, slices=80, convexity=10)
    involute_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// NEW: Herringbone Generator for zero-thrust meshing
module herringbone_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    half_h = height / 2;
    
    union() {
        // Bottom half (Right-Hand Helix)
        helical_gear(teeth, mod, helix_angle, half_h, pressure_angle);
        
        // Top half (Left-Hand Helix) — Shifted up and inverted
        translate([0, 0, half_h])
        // We rotate it slightly to ensure the teeth perfectly align at the seam
        rotate([0, 0, tan(helix_angle) * half_h / (teeth * (mod / cos(helix_angle)) / 2) * (180 / PI)])
        helical_gear(teeth, mod, -helix_angle, half_h, pressure_angle);
    }
}

// NEW: Planet Gear with 14mm bore for HK1010 Needle Bearings
module planet_bearing_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    difference() {
        herringbone_gear(teeth, mod, helix_angle, height, pressure_angle);
        
        // 14.1mm bore to perfectly press-fit a 14mm OD needle bearing
        translate([0, 0, -0.1])
        cylinder(d=14.1, h=height + 0.2, $fn=128); 
    }
}