/*
 * BASE PLATE - Simple Structural Foundation
 *
 * FEATURES:
 * - Supports bearing blocks at ends
 * - Thin profile - no guidance grooves needed
 * - Slats self-align through overlap + cam contact
 * - End caps on cam prevent X drift
 *
 * Print: 1x
 * Orientation: Flat
 */

include <../common.scad>

$fn = 32;

// ============================================
// BASE DIMENSIONS (simplified)
// ============================================

// Thin base - just structural support
BASE_HEIGHT = 8;                          // Much thinner without T-slots

// Width in Y to support the wave area
BASE_Y_FRONT = LAYER_Y_OFFSET[0] - 20;    // ~-35mm
BASE_Y_BACK = LAYER_Y_OFFSET[NUM_LAYERS-1] + 30;  // ~+45mm (extra for bearing blocks)
BASE_TOTAL_DEPTH = BASE_Y_BACK - BASE_Y_FRONT;

// ============================================
// MAIN BASE PLATE MODULE
// ============================================

module base_plate() {
    difference() {
        union() {
            // Main plate body
            plate_body();

            // Bearing block support pedestals
            bearing_pedestals();
        }

        // Bearing block mounting holes
        bearing_block_holes();

        // Corner mounting slots
        corner_slots();

        // Weight reduction cutouts
        weight_reduction();
    }
}

// ============================================
// PLATE BODY
// ============================================

module plate_body() {
    // Simple rounded rectangle
    hull() {
        for (x = [-BASE_LENGTH/2 + 8, BASE_LENGTH/2 - 8]) {
            for (y = [BASE_Y_FRONT + 8, BASE_Y_BACK - 8]) {
                translate([x, y, 0])
                    cylinder(r = 8, h = BASE_HEIGHT, $fn = 24);
            }
        }
    }
}

// ============================================
// BEARING PEDESTALS
// ============================================

module bearing_pedestals() {
    // Raised blocks under bearing blocks
    pedestal_width = BB_WIDTH + 10;
    pedestal_depth = BB_DEPTH + 10;
    pedestal_height = BB_Z - BASE_HEIGHT;  // Height to reach BB_Z

    for (bb_x = [BB_LEFT_X, BB_RIGHT_X]) {
        translate([bb_x - pedestal_width/2, -pedestal_depth/2, BASE_HEIGHT])
            cube([pedestal_width, pedestal_depth, pedestal_height]);
    }
}

// ============================================
// BEARING BLOCK MOUNTING HOLES
// ============================================

module bearing_block_holes() {
    hole_spacing_x = 20;
    hole_spacing_y = 20;

    for (bb_x = [BB_LEFT_X, BB_RIGHT_X]) {
        for (dx = [-hole_spacing_x/2, hole_spacing_x/2]) {
            for (dy = [-hole_spacing_y/2, hole_spacing_y/2]) {
                translate([bb_x + dx, dy, -1])
                    cylinder(d = M4_HOLE, h = BASE_HEIGHT + BB_Z + 2, $fn = 24);
            }
        }
    }
}

// ============================================
// CORNER MOUNTING SLOTS
// ============================================

module corner_slots() {
    slot_length = 10;

    for (x_sign = [-1, 1]) {
        for (y_val = [BASE_Y_FRONT + 12, BASE_Y_BACK - 12]) {
            translate([x_sign * (BASE_LENGTH/2 - 20), y_val, -1])
            hull() {
                cylinder(d = 4.5, h = BASE_HEIGHT + 2, $fn = 16);
                translate([x_sign * slot_length, 0, 0])
                    cylinder(d = 4.5, h = BASE_HEIGHT + 2, $fn = 16);
            }
        }
    }
}

// ============================================
// WEIGHT REDUCTION
// ============================================

module weight_reduction() {
    // Oval cutouts in center area (away from pedestals)
    if (BASE_LENGTH > 150) {
        for (x = [-60, 0, 60]) {
            translate([x, (BASE_Y_FRONT + BASE_Y_BACK)/2, -1])
            hull() {
                translate([-15, 0, 0]) cylinder(d = 20, h = BASE_HEIGHT + 2, $fn = 24);
                translate([15, 0, 0]) cylinder(d = 20, h = BASE_HEIGHT + 2, $fn = 24);
            }
        }
    }
}

// ============================================
// RENDER
// ============================================

color(C_BASE)
base_plate();

// ============================================
// VERIFICATION
// ============================================

echo("=== BASE PLATE VERIFICATION (SIMPLIFIED) ===");
echo(str("Size: ", BASE_LENGTH, " x ", BASE_TOTAL_DEPTH, " x ", BASE_HEIGHT, "mm"));
echo(str("Y range: ", BASE_Y_FRONT, " to ", BASE_Y_BACK));
echo("");
echo("NOTE: No guidance grooves - slats self-align via:");
echo("  - Overlap between layers");
echo("  - Cam contact (followers ride on cam)");
echo("  - Cam end caps (prevent X drift)");
