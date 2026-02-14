/*
 * BEARING BLOCK RIGHT - Right Side Bearing Mount
 *
 * Printable part: 1x
 * Print orientation: Base down
 *
 * Features:
 * - 608 bearing pocket (press fit) - HORIZONTAL orientation
 * - Shaft passes through along X axis
 * - Base mounting holes
 * - Mirror of left block (bearing faces -X toward worm)
 */

include <../common.scad>

$fn = 48;

// ============================================
// MAIN BEARING BLOCK MODULE
// ============================================

module bearing_block_R() {
    difference() {
        // Main body
        block_body();

        // Bearing pocket (horizontal, facing -X toward worm)
        bearing_pocket();

        // Shaft through hole (along X axis)
        shaft_hole();

        // Mounting holes
        mounting_holes();
    }
}

// ============================================
// BLOCK BODY
// ============================================

module block_body() {
    // Main block
    translate([-BEARING_BLOCK_WIDTH/2, -BEARING_BLOCK_DEPTH/2, 0])
        cube([BEARING_BLOCK_WIDTH, BEARING_BLOCK_DEPTH, BEARING_BLOCK_HEIGHT]);

    // Bearing boss (extends toward worm, -X direction)
    translate([-BEARING_BLOCK_WIDTH/2, 0, BEARING_BLOCK_HEIGHT])
    rotate([0, -90, 0])
        cylinder(d=BEARING_608_OD + 6, h=5);
}

// ============================================
// BEARING POCKET
// ============================================

module bearing_pocket() {
    // Pocket for 608 bearing - horizontal, facing -X
    translate([-BEARING_BLOCK_WIDTH/2 + BEARING_POCKET_DEPTH - 1, 0, BEARING_BLOCK_HEIGHT])
    rotate([0, -90, 0])
        cylinder(d=BEARING_POCKET_DIA, h=BEARING_POCKET_DEPTH + 5, $fn=64);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    // Through hole for shaft along X axis
    shaft_clearance = WORM_SHAFT_DIA + 1;

    translate([-BEARING_BLOCK_WIDTH/2 - 1, 0, BEARING_BLOCK_HEIGHT])
    rotate([0, 90, 0])
        cylinder(d=shaft_clearance, h=BEARING_BLOCK_WIDTH + 10, $fn=32);
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    // 2x M3 holes for base attachment
    hole_spacing = 20;

    for (y = [-hole_spacing/2, hole_spacing/2]) {
        translate([0, y, -1]) {
            // Through hole
            cylinder(d=M3_HOLE_DIA, h=BEARING_BLOCK_HEIGHT + 2, $fn=16);

            // Countersink at bottom
            cylinder(d=M3_HEAD_DIA, h=M3_HEAD_H + 1, $fn=16);
        }
    }
}

// ============================================
// RENDER
// ============================================

color(C_BEARING_BLOCK)
bearing_block_R();

// Visualization: 608 bearing in horizontal position
%translate([-BEARING_BLOCK_WIDTH/2 + BEARING_608_H/2, 0, BEARING_BLOCK_HEIGHT])
rotate([0, 90, 0])
    difference() {
        cylinder(d=BEARING_608_OD, h=BEARING_608_H, center=true, $fn=48);
        cylinder(d=BEARING_608_ID, h=BEARING_608_H + 1, center=true, $fn=32);
    }

// ============================================
// INFO
// ============================================

echo("=== BEARING BLOCK RIGHT ===");
echo(str("Block size: ", BEARING_BLOCK_WIDTH, "x", BEARING_BLOCK_DEPTH, "x", BEARING_BLOCK_HEIGHT, "mm"));
echo("Mirror of LEFT block");
echo("Print quantity: 1");
echo("Print orientation: Base down");
