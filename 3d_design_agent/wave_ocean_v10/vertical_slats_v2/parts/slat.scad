/*
 * SLAT - Clean Minimal Wave Profile
 *
 * Printable part: 36x (varying heights)
 * Print orientation: Upright (Z up)
 *
 * DESIGN:
 * - Ultra-thin (2.5mm) for tight packing
 * - Clean smooth profile - no protrusions
 * - Back tab slides in backplate groove
 * - Curved bottom rides on cam
 *
 * All slats same SHAPE, different HEIGHTS
 */

include <../common.scad>

$fn = 32;

// ============================================
// PARAMETRIC SLAT MODULE
// ============================================

module slat(height = SLAT_BASE_HEIGHT) {
    union() {
        // Main wave body
        wave_body(height);

        // Back tab for groove guidance
        back_tab(height);

        // Cam follower bottom
        cam_follower();
    }
}

// ============================================
// WAVE BODY - Clean tapered profile
// ============================================

module wave_body(height) {
    // Simple elegant wave shape
    // Smooth taper to rounded crest

    hull() {
        // Base - full width
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 0.5]);

        // Mid section
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, height * 0.7])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.9, 0.5]);

        // Upper taper
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH * 0.3, height * 0.9])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.6, 0.5]);

        // Crest - simple rounded top
        translate([0, 0, height])
        scale([1, 0.35, 0.8])
        rotate([0, 90, 0])
            cylinder(d = 6, h = SLAT_THICKNESS, center = true, $fn = 16);
    }
}

// ============================================
// BACK TAB - Groove guidance
// ============================================

module back_tab(height) {
    // Tab extends from back of slat into backplate groove

    tab_bottom = -TAB_EXTRA_HEIGHT;
    tab_top = height * 0.6;
    tab_height = tab_top - tab_bottom;

    translate([-TAB_THICKNESS/2, SLAT_DEPTH/2 - 1, tab_bottom])
        cube([TAB_THICKNESS, TAB_DEPTH, tab_height]);
}

// ============================================
// CAM FOLLOWER - Curved bottom
// ============================================

module cam_follower() {
    // Concave bottom that rides on cam surface

    translate([0, 0, -FOLLOWER_HEIGHT])
    difference() {
        // Solid base
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, FOLLOWER_HEIGHT + 0.5]);

        // Concave curve
        translate([0, 0, -FOLLOWER_CURVE_RADIUS + FOLLOWER_HEIGHT])
        rotate([90, 0, 0])
            cylinder(r = FOLLOWER_CURVE_RADIUS, h = SLAT_DEPTH + 2, center = true, $fn = 48);
    }
}

// ============================================
// RENDER - Show sample slats
// ============================================

// Display a few slats showing height variation
for (i = [0 : 5]) {
    translate([i * 12, 0, 0])
    color(slat_color(i * 6))
        slat(slat_height(i * 6));
}

// ============================================
// INFO
// ============================================

echo("=== SLAT ===");
echo(str("Thickness: ", SLAT_THICKNESS, "mm"));
echo(str("Depth: ", SLAT_DEPTH, "mm"));
echo(str("Height range: ", SLAT_BASE_HEIGHT, "-", SLAT_BASE_HEIGHT + SLAT_HEIGHT_VARIATION, "mm"));
echo(str("Total slats: ", NUM_SLATS));
echo("");
echo("Print all slats - heights calculated from slat_height(i)");
