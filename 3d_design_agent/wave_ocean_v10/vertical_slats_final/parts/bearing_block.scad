/*
 * BEARING BLOCK - 608 Bearing Mount
 *
 * Supports the cam shaft at each end.
 * Bearing pocket sized for press-fit of 608 bearing.
 *
 * Print: 2x (identical, mount mirrored)
 * Orientation: Upright
 */

include <../common.scad>

$fn = 48;

// ============================================
// MAIN BEARING BLOCK MODULE
// ============================================

module bearing_block() {
    difference() {
        union() {
            // Main block body
            block_body();

            // Mounting flange (toward backplate)
            mounting_flange();
        }

        // Bearing pocket (press fit)
        bearing_pocket();

        // Shaft through-hole
        shaft_hole();

        // Mounting screw holes
        mounting_holes();
    }
}

// ============================================
// BLOCK BODY
// ============================================

module block_body() {
    translate([-BB_WIDTH/2, -BB_DEPTH/2, 0])
        cube([BB_WIDTH, BB_DEPTH, BB_HEIGHT]);
}

// ============================================
// MOUNTING FLANGE
// ============================================

module mounting_flange() {
    flange_width = BB_WIDTH - 6;
    flange_depth = 12;

    translate([-flange_width/2, BB_DEPTH/2 - 2, 0])
        cube([flange_width, flange_depth, BB_HEIGHT]);
}

// ============================================
// BEARING POCKET (Press Fit)
// ============================================

module bearing_pocket() {
    // Pocket from inward face (toward cam)
    // Press fit: pocket slightly smaller than bearing OD

    translate([BB_WIDTH/2 + 1, 0, BB_HEIGHT])
    rotate([0, -90, 0])
        cylinder(d = BEARING_POCKET_DIA, h = BEARING_POCKET_DEPTH + 1, $fn = 64);
}

// ============================================
// SHAFT THROUGH-HOLE
// ============================================

module shaft_hole() {
    // Clearance hole for shaft
    translate([0, 0, BB_HEIGHT])
    rotate([0, 90, 0])
        cylinder(d = BEARING_608_ID + 1, h = BB_WIDTH + 10, center = true, $fn = 32);
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    hole_z_positions = [10, BB_HEIGHT - 5];

    for (z = hole_z_positions) {
        // Through hole from front to back
        translate([0, -BB_DEPTH/2 - 1, z])
        rotate([-90, 0, 0])
            cylinder(d = M4_HOLE, h = BB_DEPTH + 20, $fn = 24);

        // Counterbore on front
        translate([0, -BB_DEPTH/2 + M4_HEAD_H, z])
        rotate([-90, 0, 0])
            cylinder(d = M4_HEAD_DIA + 1, h = M4_HEAD_H + 1, $fn = 24);
    }
}

// ============================================
// RENDER
// ============================================

color(C_BB)
bearing_block();

// Ghost bearing
%translate([BB_WIDTH/2 - BEARING_POCKET_DEPTH + BEARING_608_H/2, 0, BB_HEIGHT])
rotate([0, 90, 0])
difference() {
    cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
    cylinder(d = BEARING_608_ID, h = BEARING_608_H + 1, center = true);
}

// Ghost shaft
%translate([0, 0, BB_HEIGHT])
rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = BB_WIDTH + 40, center = true, $fn = 24);

// ============================================
// VERIFICATION
// ============================================

echo("=== BEARING BLOCK VERIFICATION ===");
echo(str("Size: ", BB_WIDTH, " x ", BB_DEPTH, " x ", BB_HEIGHT, "mm"));
echo(str("Bearing pocket: Ø", BEARING_POCKET_DIA, " x ", BEARING_POCKET_DEPTH, "mm"));
echo(str("Shaft center: Z = ", BB_HEIGHT, "mm"));
echo("");
echo("BEARING FIT:");
echo(str("  Bearing OD: ", BEARING_608_OD, "mm"));
echo(str("  Pocket dia: ", BEARING_POCKET_DIA, "mm"));
echo(str("  Interference: ", BEARING_608_OD - BEARING_POCKET_DIA, "mm (press fit)"));
