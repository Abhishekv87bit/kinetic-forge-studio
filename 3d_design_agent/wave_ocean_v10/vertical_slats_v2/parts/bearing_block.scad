/*
 * BEARING BLOCK - 608 Bearing Mount
 *
 * Printable part: 2x (identical)
 * Print orientation: Upright
 *
 * DESIGN:
 * - 608 bearing pocket (press fit)
 * - Mounts to backplate flanges
 * - Compact size for smaller assembly
 */

include <../common.scad>

$fn = 48;

// ============================================
// MAIN BEARING BLOCK MODULE
// ============================================

module bearing_block() {
    difference() {
        union() {
            // Main block
            block_body();

            // Mounting tab
            mounting_tab();
        }

        // Bearing pocket
        bearing_pocket();

        // Shaft clearance
        shaft_clearance();

        // Mounting holes
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
// MOUNTING TAB
// ============================================

module mounting_tab() {
    tab_width = BB_WIDTH - 8;
    tab_depth = 8;

    translate([-tab_width/2, BB_DEPTH/2 - 2, 0])
        cube([tab_width, tab_depth, BB_HEIGHT]);
}

// ============================================
// BEARING POCKET
// ============================================

module bearing_pocket() {
    // Press-fit pocket from outward side
    translate([-BB_WIDTH/2 - 1, 0, BB_HEIGHT])
    rotate([0, 90, 0])
        cylinder(d = BEARING_POCKET_DIA, h = BEARING_POCKET_DEPTH + 1, $fn = 64);
}

// ============================================
// SHAFT CLEARANCE
// ============================================

module shaft_clearance() {
    translate([0, 0, BB_HEIGHT])
    rotate([0, 90, 0])
        cylinder(d = BEARING_608_ID + 2, h = BB_WIDTH + 20, center = true);
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    for (z = [8, BB_HEIGHT - 3]) {
        translate([0, BB_DEPTH/2 - 1, z])
        rotate([90, 0, 0])
            cylinder(d = M4_HOLE, h = BB_DEPTH + 12, $fn = 24);

        // Counterbore
        translate([0, -BB_DEPTH/2 + 2, z])
        rotate([90, 0, 0])
            cylinder(d = M4_HEAD_DIA + 1, h = 3, $fn = 24);
    }
}

// ============================================
// RENDER
// ============================================

color(C_BB)
bearing_block();

// Bearing ghost
%translate([-BB_WIDTH/2 + BEARING_POCKET_DEPTH/2, 0, BB_HEIGHT])
rotate([0, 90, 0])
    cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);

echo("=== BEARING BLOCK ===");
echo(str("Size: ", BB_WIDTH, " x ", BB_DEPTH, " x ", BB_HEIGHT, "mm"));
echo("Print: 2x");
