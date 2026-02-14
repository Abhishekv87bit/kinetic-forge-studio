/*
 * BEARING BLOCK - 608 Bearing Mount
 *
 * Printable part: 2x (left and right identical)
 * Print orientation: Upright (Z up)
 *
 * Features:
 * - 608 bearing pocket (press fit)
 * - Mounting holes for base plate
 * - Integrated guide rail support
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

            // Guide rail support arm
            guide_support();
        }

        // Bearing pocket
        bearing_pocket();

        // Shaft clearance
        shaft_clearance();

        // Base mounting holes
        mounting_holes();

        // Guide rail mounting holes
        guide_mounting_holes();
    }
}

// ============================================
// BLOCK BODY
// ============================================

module block_body() {
    // Main structural block
    translate([-BB_WIDTH/2, -BB_DEPTH/2, 0])
        cube([BB_WIDTH, BB_DEPTH, BB_HEIGHT]);
}

// ============================================
// GUIDE RAIL SUPPORT
// ============================================

module guide_support() {
    // Upright arm that holds guide rail
    support_width = 10;
    support_depth = 8;
    support_height = GUIDE_Z + GUIDE_HEIGHT - BASE_THICKNESS;

    // Front support
    translate([-support_width/2, -BB_DEPTH/2 - support_depth + 2, 0])
        cube([support_width, support_depth, support_height]);

    // Back support
    translate([-support_width/2, BB_DEPTH/2 - 2, 0])
        cube([support_width, support_depth, support_height]);
}

// ============================================
// BEARING POCKET
// ============================================

module bearing_pocket() {
    // Press-fit pocket for 608 bearing
    // Bearing sits with axis horizontal (along X)

    translate([BB_WIDTH/2 + 1, 0, BB_HEIGHT])
    rotate([0, 90, 0])
        cylinder(d = BEARING_POCKET_DIA, h = BEARING_POCKET_DEPTH + 1);

    // Also from other side for symmetry
    translate([-BB_WIDTH/2 - 1, 0, BB_HEIGHT])
    rotate([0, -90, 0])
        cylinder(d = BEARING_POCKET_DIA, h = BEARING_POCKET_DEPTH + 1);
}

// ============================================
// SHAFT CLEARANCE
// ============================================

module shaft_clearance() {
    // Through hole for shaft (larger than bearing ID)
    translate([0, 0, BB_HEIGHT])
    rotate([0, 90, 0])
        cylinder(d = BEARING_608_ID + 2, h = BB_WIDTH + 10, center = true);
}

// ============================================
// BASE MOUNTING HOLES
// ============================================

module mounting_holes() {
    // M4 holes for base plate attachment
    hole_spacing = 18;

    for (x_sign = [-1, 1]) {
        for (y_sign = [-1, 1]) {
            translate([x_sign * hole_spacing/2, y_sign * hole_spacing/2, -1])
                cylinder(d = M4_HOLE, h = 10, $fn = 24);

            // Counterbore for screw head
            translate([x_sign * hole_spacing/2, y_sign * hole_spacing/2, -1])
                cylinder(d = 8, h = 4, $fn = 24);
        }
    }
}

// ============================================
// GUIDE RAIL MOUNTING HOLES
// ============================================

module guide_mounting_holes() {
    support_height = GUIDE_Z + GUIDE_HEIGHT/2 - BASE_THICKNESS;

    // Front guide rail hole
    translate([0, -BB_DEPTH/2 - 5, support_height])
    rotate([90, 0, 0])
        cylinder(d = M3_HOLE, h = 20, center = true, $fn = 16);

    // Back guide rail hole
    translate([0, BB_DEPTH/2 + 5, support_height])
    rotate([90, 0, 0])
        cylinder(d = M3_HOLE, h = 20, center = true, $fn = 16);
}

// ============================================
// RENDER
// ============================================

color(C_BB)
bearing_block();

// Show bearing for reference
%translate([BB_WIDTH/2 - BEARING_POCKET_DEPTH/2, 0, BB_HEIGHT])
rotate([0, 90, 0])
    cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);

// ============================================
// INFO
// ============================================

echo("=== BEARING BLOCK ===");
echo(str("Size: ", BB_WIDTH, " x ", BB_DEPTH, " x ", BB_HEIGHT, "mm"));
echo(str("Bearing: 608 (", BEARING_608_OD, "mm OD)"));
echo(str("Bearing pocket: ", BEARING_POCKET_DIA, "mm (press fit)"));
echo("");
echo("Print: 2x (identical, mount facing inward)");
echo("Orientation: Upright (Z up)");
echo("Material: PETG recommended (stronger)");
