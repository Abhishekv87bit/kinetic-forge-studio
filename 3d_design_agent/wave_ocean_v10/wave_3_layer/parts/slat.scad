/*
 * SLAT - Thin Interlocking Wave Element
 *
 * CORRECTED:
 * - SLAT_THICKNESS = 2mm (reduced for interlocking gaps)
 * - Back tab on Layer 0 (BACK layer), not Layer 2
 *
 * Print: 20x per layer = 60 total
 */

include <../common.scad>

$fn = 32;

// ============================================
// PARAMETRIC SLAT MODULE
// ============================================

module slat(height = SLAT_BASE_HEIGHT, layer = 0) {
    union() {
        // Main wave body
        wave_body(height);

        // Cam follower bottom
        cam_follower();

        // Back tab (Layer 0 only - the BACK layer)
        if (layer == 0) {
            back_tab(height);
        }
    }
}

// ============================================
// WAVE BODY - Thin profile (2mm)
// ============================================

module wave_body(height) {
    hull() {
        // Base
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 0.5]);

        // Mid section
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, height * 0.7])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.9, 0.5]);

        // Upper taper
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH * 0.25, height * 0.9])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.5, 0.5]);

        // Rounded crest
        translate([0, 0, height])
        scale([1, 0.25, 0.5])
        rotate([0, 90, 0])
            cylinder(d = 4, h = SLAT_THICKNESS, center = true, $fn = 16);
    }

    // Hinge block on back
    hinge_block(height);
}

// ============================================
// HINGE BLOCK
// ============================================

module hinge_block(height) {
    block_height = 8;
    block_depth = 3;

    translate([-SLAT_THICKNESS/2, SLAT_DEPTH/2 - 1, HINGE_HEIGHT_FROM_BOTTOM - block_height/2])
        cube([SLAT_THICKNESS, block_depth, block_height]);
}

// ============================================
// CAM FOLLOWER
// ============================================

module cam_follower() {
    translate([0, 0, -FOLLOWER_HEIGHT])
    difference() {
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, FOLLOWER_HEIGHT + 0.5]);

        translate([0, 0, -FOLLOWER_CURVE_RADIUS + FOLLOWER_HEIGHT])
        rotate([90, 0, 0])
            cylinder(r = FOLLOWER_CURVE_RADIUS, h = SLAT_DEPTH + 2, center = true, $fn = 48);
    }
}

// ============================================
// BACK TAB (Layer 0 = BACK layer only)
// ============================================

module back_tab(height) {
    tab_bottom = 5;

    translate([-TAB_THICKNESS/2, SLAT_DEPTH/2, tab_bottom])
        cube([TAB_THICKNESS, TAB_DEPTH, TAB_HEIGHT]);
}

// ============================================
// SLAT WITH HINGE HOLE
// ============================================

module slat_with_hinge_hole(height = SLAT_BASE_HEIGHT, layer = 0) {
    difference() {
        slat(height, layer);

        translate([0, SLAT_DEPTH/2, HINGE_HEIGHT_FROM_BOTTOM])
        rotate([0, 90, 0])
            cylinder(d = HINGE_ROD_DIA + TOL_CLEARANCE, h = SLAT_THICKNESS + 2, center = true, $fn = 16);
    }
}

// ============================================
// RENDER - Show slats from each layer
// ============================================

// Layer 0 (BACK) - WITH back tab
translate([0, 0, 0])
color(LAYER_COLORS[0])
    slat_with_hinge_hole(slat_height(0), 0);

// Layer 1 (MID) - no back tab
translate([12, 0, 0])
color(LAYER_COLORS[1])
    slat_with_hinge_hole(slat_height(3), 1);

// Layer 2 (FRONT) - no back tab
translate([24, 0, 0])
color(LAYER_COLORS[2])
    slat_with_hinge_hole(slat_height(6), 2);

// ============================================
// INFO
// ============================================

echo("=== SLAT (CORRECTED) ===");
echo(str("Thickness (X): ", SLAT_THICKNESS, "mm"));
echo(str("Depth (Y): ", SLAT_DEPTH, "mm"));
echo("");
echo("Layer 0 (BACK): Has back tab for backplate");
echo("Layer 1, 2: No back tab");
echo(str("Total slats: ", NUM_SLATS * NUM_LAYERS));
