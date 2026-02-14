/*
 * SLAT TYPE A - Standard Wave
 *
 * Quantity: 10x
 * Height: 50mm
 * Character: Rounded symmetric crest, subtle foam texture
 * Use: Most common, fills space between accent pieces
 *
 * Profile:
 *        ╭──╮
 *       ╱    ╲
 *      ╱      ╲
 *     │        │
 *     │   ▯    │ ← Back tab
 *     ╰────────╯ ← Curved cam follower
 */

include <common.scad>

$fn = 48;

// ============================================
// MAIN MODULE
// ============================================

module slat_type_A() {
    color(C_SLAT_A)
    union() {
        // Main wave body
        wave_body_A();

        // Back tab for groove
        back_tab();

        // Cam follower bottom
        cam_follower();
    }
}

// ============================================
// WAVE BODY - Standard rounded profile
// ============================================

module wave_body_A() {
    height = SLAT_A_HEIGHT;

    // Main body with rounded crest
    hull() {
        // Base
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, height - 15]);

        // Crest - symmetric rounded peak
        translate([0, 0, height])
        scale([1, 0.6, 1])
        rotate([90, 0, 0])
            cylinder(d = SLAT_THICKNESS + 2, h = SLAT_DEPTH * 0.6, center = true, $fn = 32);
    }

    // Subtle foam bumps on top
    foam_texture_A();
}

// ============================================
// FOAM TEXTURE - Subtle bumps
// ============================================

module foam_texture_A() {
    height = SLAT_A_HEIGHT;

    // Small bumps along crest
    for (y = [-6, 0, 6]) {
        translate([0, y, height + 2])
        scale([0.8, 1, 1.2])
            sphere(d = 4, $fn = 16);
    }
}

// ============================================
// BACK TAB - Slides in backplate groove
// ============================================

module back_tab() {
    // Tab extends from back of slat into backplate groove
    // Provides vertical guidance without front rails

    tab_start_z = -TAB_HEIGHT_EXTENSION;
    tab_end_z = SLAT_A_HEIGHT - 10;
    tab_total_height = tab_end_z - tab_start_z;

    translate([-TAB_WIDTH/2, SLAT_DEPTH/2 - 2, tab_start_z])
        cube([TAB_WIDTH, TAB_DEPTH, tab_total_height]);
}

// ============================================
// CAM FOLLOWER - Curved bottom
// ============================================

module cam_follower() {
    follower_height = 8;

    translate([0, 0, -follower_height])
    difference() {
        // Solid base
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, follower_height + 1]);

        // Concave curve to ride on cam
        translate([0, 0, -FOLLOWER_CURVE_RADIUS + follower_height - 1])
        rotate([90, 0, 0])
            cylinder(r = FOLLOWER_CURVE_RADIUS, h = SLAT_DEPTH + 2, center = true, $fn = 64);
    }
}

// ============================================
// RENDER
// ============================================

slat_type_A();

// Reference: cam surface
%translate([0, 0, -FOLLOWER_CURVE_RADIUS - 8])
rotate([90, 0, 0])
    cylinder(r = CAM_CORE_RADIUS, h = SLAT_DEPTH + 20, center = true, $fn = 32);

echo("=== SLAT TYPE A: Standard Wave ===");
echo(str("Height: ", SLAT_A_HEIGHT, "mm"));
echo(str("Thickness: ", SLAT_THICKNESS, "mm"));
echo("Print quantity: 10");
