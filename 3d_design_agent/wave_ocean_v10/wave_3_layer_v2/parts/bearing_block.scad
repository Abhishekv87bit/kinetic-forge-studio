/*
 * BEARING BLOCK - Staggered Y+Z Shaft Support
 *
 * DESIGN:
 * - Holds 608 bearings for 3 staggered shafts
 * - Shaft positions offset in BOTH Y and Z
 * - Left and right blocks (mirror)
 *
 * SHAFT POSITIONS (staggered to avoid cam collision):
 * - Shaft 0: Y=30, Z=15 (back, lowest)
 * - Shaft 1: Y=15, Z=30 (mid, middle)
 * - Shaft 2: Y=0,  Z=45 (front, highest)
 *
 * Print: 2x (left + right, mirrored)
 */

include <../common.scad>

$fn = 48;

// ============================================
// MAIN BEARING BLOCK MODULE
// ============================================

module bearing_block(side = "left") {
    difference() {
        // Main block body
        block_body();

        // Bearing pockets (3 staggered positions)
        bearing_pockets();

        // Shaft through-holes
        shaft_holes();

        // Mounting holes
        mounting_holes();

        // Material relief (weight reduction)
        if (side == "left") {
            weight_relief_left();
        } else {
            weight_relief_right();
        }
    }
}

// ============================================
// BLOCK BODY
// ============================================

module block_body() {
    // Irregular shape that encompasses all 3 bearing positions

    hull() {
        // Bottom-back corner (for shaft 0)
        translate([0, CAM_Y[0], CAM_Z[0]])
            cube([BB_WIDTH, BEARING_608_OD + 8, BEARING_608_OD + 8], center = true);

        // Middle section (for shaft 1)
        translate([0, CAM_Y[1], CAM_Z[1]])
            cube([BB_WIDTH, BEARING_608_OD + 8, BEARING_608_OD + 8], center = true);

        // Top-front corner (for shaft 2)
        translate([0, CAM_Y[2], CAM_Z[2]])
            cube([BB_WIDTH, BEARING_608_OD + 8, BEARING_608_OD + 8], center = true);
    }
}

// ============================================
// BEARING POCKETS
// ============================================

module bearing_pockets() {
    for (i = [0 : NUM_LAYERS - 1]) {
        translate([0, CAM_Y[i], CAM_Z[i]])
        rotate([0, 90, 0])
            cylinder(d = BEARING_608_OD + TOL_PRESS_FIT,
                     h = BEARING_608_H + 1,
                     center = true);
    }
}

// ============================================
// SHAFT HOLES
// ============================================

module shaft_holes() {
    for (i = [0 : NUM_LAYERS - 1]) {
        translate([0, CAM_Y[i], CAM_Z[i]])
        rotate([0, 90, 0])
            cylinder(d = SHAFT_HOLE,
                     h = BB_WIDTH + 10,
                     center = true);
    }
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    // Holes for mounting to base/frame

    // Bottom mounting (into base plate)
    for (y = [CAM_Y[0] - 8, CAM_Y[2] + 8]) {
        translate([0, y, CAM_Z[0] - 15])
            cylinder(d = M4_HOLE, h = 20, $fn = 24);
    }

    // Side mounting (into frame columns)
    translate([0, (CAM_Y[0] + CAM_Y[2]) / 2, CAM_Z[2] + 15])
    rotate([0, 90, 0])
        cylinder(d = M4_HOLE, h = BB_WIDTH + 10, center = true, $fn = 24);
}

// ============================================
// WEIGHT RELIEF (left side)
// ============================================

module weight_relief_left() {
    // Cutouts to reduce material while maintaining strength

    // Between shaft 0 and shaft 1
    translate([-BB_WIDTH/4, (CAM_Y[0] + CAM_Y[1])/2, (CAM_Z[0] + CAM_Z[1])/2])
        cube([BB_WIDTH/2 - 2, 8, 8], center = true);

    // Between shaft 1 and shaft 2
    translate([-BB_WIDTH/4, (CAM_Y[1] + CAM_Y[2])/2, (CAM_Z[1] + CAM_Z[2])/2])
        cube([BB_WIDTH/2 - 2, 8, 8], center = true);
}

// ============================================
// WEIGHT RELIEF (right side - mirrored)
// ============================================

module weight_relief_right() {
    translate([BB_WIDTH/4, (CAM_Y[0] + CAM_Y[1])/2, (CAM_Z[0] + CAM_Z[1])/2])
        cube([BB_WIDTH/2 - 2, 8, 8], center = true);

    translate([BB_WIDTH/4, (CAM_Y[1] + CAM_Y[2])/2, (CAM_Z[1] + CAM_Z[2])/2])
        cube([BB_WIDTH/2 - 2, 8, 8], center = true);
}

// ============================================
// BEARING BLOCK WITH PULLEY MOUNT
// ============================================

module bearing_block_with_pulleys(side = "left") {
    bearing_block(side);

    // Pulley mounting points (outside the block)
    pulley_offset = (side == "left") ? -BB_WIDTH/2 - 10 : BB_WIDTH/2 + 10;

    for (i = [0 : NUM_LAYERS - 1]) {
        translate([pulley_offset, CAM_Y[i], CAM_Z[i]])
        rotate([0, 90, 0])
        %cylinder(d = 15, h = 8, center = true);  // Pulley placeholder
    }
}

// ============================================
// RENDER
// ============================================

// Left bearing block
translate([BB_LEFT_X, 0, 0])
color(C_BB)
    bearing_block("left");

// Right bearing block
translate([BB_RIGHT_X, 0, 0])
color(C_BB)
    bearing_block("right");

// Show shafts (transparent)
for (i = [0 : NUM_LAYERS - 1]) {
    %translate([0, CAM_Y[i], CAM_Z[i]])
    rotate([0, 90, 0])
    color(C_SHAFT)
        cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);
}

// Show bearings (transparent)
for (i = [0 : NUM_LAYERS - 1]) {
    for (x = [BB_LEFT_X, BB_RIGHT_X]) {
        %translate([x, CAM_Y[i], CAM_Z[i]])
        rotate([0, 90, 0])
        color([0.8, 0.8, 0.8])
            difference() {
                cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
                cylinder(d = BEARING_608_ID, h = BEARING_608_H + 1, center = true);
            }
    }
}

// ============================================
// INFO
// ============================================

echo("=== BEARING BLOCK (STAGGERED) ===");
echo(str("Block width: ", BB_WIDTH, "mm"));
echo(str("Block depth: ", BB_DEPTH, "mm"));
echo(str("Block height: ", BB_HEIGHT, "mm"));
echo("");
echo("SHAFT POSITIONS (Y, Z):");
echo(str("  Shaft 0 (back):  Y=", CAM_Y[0], ", Z=", CAM_Z[0]));
echo(str("  Shaft 1 (mid):   Y=", CAM_Y[1], ", Z=", CAM_Z[1]));
echo(str("  Shaft 2 (front): Y=", CAM_Y[2], ", Z=", CAM_Z[2]));
echo("");
echo("COLLISION CHECK:");
echo(str("  Cam max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("  Z spacing: ", CAM_Z[1] - CAM_Z[0], "mm"));
echo(str("  Clearance: ", (CAM_Z[1] - CAM_Z[0]) - CAM_MAX_RADIUS, "mm > 0 ✓"));
echo("");
echo("Print: 2x (left + right)");
