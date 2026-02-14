/*
 * BASE PLATE - Main Foundation
 *
 * Printable part: 1x (or 2x halves if bed < 260mm)
 * Print orientation: Flat (Z up)
 *
 * Features:
 * - Mounting holes for bearing blocks
 * - Slots for optional frame attachment
 * - Can be split into 2 halves for smaller printers
 */

include <../common.scad>

$fn = 32;

// ============================================
// CONFIGURATION
// ============================================

SPLIT_BASE = false;  // Set true to create 2 halves

// ============================================
// MAIN BASE PLATE MODULE
// ============================================

module base_plate() {
    if (SPLIT_BASE) {
        base_half();
    } else {
        base_full();
    }
}

module base_full() {
    difference() {
        // Main plate
        plate_body();

        // Bearing block mounting holes
        bearing_block_holes();

        // Weight reduction cutouts
        weight_cutouts();

        // Frame mounting slots
        frame_slots();
    }
}

module base_half() {
    // Left or right half for smaller printers
    difference() {
        base_full();

        // Cut off right half
        translate([0, -BASE_WIDTH, -1])
            cube([BASE_LENGTH, BASE_WIDTH * 2, BASE_THICKNESS + 2]);
    }
}

// ============================================
// PLATE BODY
// ============================================

module plate_body() {
    // Rounded rectangle base
    hull() {
        for (x = [-1, 1]) {
            for (y = [-1, 1]) {
                translate([x * (BASE_LENGTH/2 - 10), y * (BASE_WIDTH/2 - 10), 0])
                    cylinder(r = 10, h = BASE_THICKNESS);
            }
        }
    }
}

// ============================================
// BEARING BLOCK MOUNTING HOLES
// ============================================

module bearing_block_holes() {
    hole_spacing = 18;

    for (x_pos = [BB_LEFT_X, BB_RIGHT_X]) {
        for (x_off = [-1, 1]) {
            for (y_off = [-1, 1]) {
                translate([x_pos + x_off * hole_spacing/2,
                          y_off * hole_spacing/2,
                          -1])
                    cylinder(d = M4_HOLE, h = BASE_THICKNESS + 2, $fn = 24);
            }
        }
    }
}

// ============================================
// WEIGHT REDUCTION
// ============================================

module weight_cutouts() {
    // Oval cutouts between bearing blocks
    cutout_length = 60;
    cutout_width = 25;

    for (x = [-50, 50]) {
        translate([x, 0, -1])
        hull() {
            translate([-cutout_length/2, 0, 0])
                cylinder(d = cutout_width, h = BASE_THICKNESS + 2, $fn = 32);
            translate([cutout_length/2, 0, 0])
                cylinder(d = cutout_width, h = BASE_THICKNESS + 2, $fn = 32);
        }
    }
}

// ============================================
// FRAME MOUNTING SLOTS
// ============================================

module frame_slots() {
    // Slots at corners for mounting to external frame/canvas
    slot_length = 15;
    slot_width = 5;

    for (x_sign = [-1, 1]) {
        for (y_sign = [-1, 1]) {
            translate([x_sign * (BASE_LENGTH/2 - 20),
                      y_sign * (BASE_WIDTH/2 - 10),
                      -1])
            hull() {
                cylinder(d = slot_width, h = BASE_THICKNESS + 2, $fn = 16);
                translate([x_sign * slot_length, 0, 0])
                    cylinder(d = slot_width, h = BASE_THICKNESS + 2, $fn = 16);
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
// INFO
// ============================================

echo("=== BASE PLATE ===");
echo(str("Size: ", BASE_LENGTH, " x ", BASE_WIDTH, " x ", BASE_THICKNESS, "mm"));
echo("");
if (SPLIT_BASE) {
    echo("Print: 2x halves (set SPLIT_BASE = true)");
} else {
    echo("Print: 1x full (requires 260mm bed)");
    echo("Set SPLIT_BASE = true for smaller printers");
}
echo("Orientation: Flat (Z up)");
echo("Material: PLA or PETG");
