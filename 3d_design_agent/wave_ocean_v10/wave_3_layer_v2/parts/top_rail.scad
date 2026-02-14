/*
 * TOP RAIL - Wire Attachment System
 *
 * DESIGN:
 * - Two parallel rails (front + back)
 * - Wire holes for fish wire suspension
 * - Supports channel guides
 * - Structural element connecting columns
 *
 * Wire routing:
 * - Each slat has a wire running up to the rail
 * - Wire passes through hole, secured with knot or crimp
 * - 60 total wires (20 per layer)
 *
 * Print: 2x (front rail + back rail)
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN TOP RAIL MODULE
// ============================================

module top_rail(position = "front") {
    y_pos = (position == "front") ? FRONT_RAIL_Y : BACK_RAIL_Y;

    difference() {
        // Rail body
        rail_body();

        // Wire holes
        wire_holes(position);

        // Mounting holes for columns
        column_mounting_holes();
    }
}

// ============================================
// RAIL BODY
// ============================================

module rail_body() {
    translate([0, 0, 0])
        cube([TOP_RAIL_LENGTH, TOP_RAIL_WIDTH, TOP_RAIL_HEIGHT], center = true);
}

// ============================================
// WIRE HOLES
// ============================================

module wire_holes(position) {
    // Determine which layers this rail serves
    // Front rail: Layer 2 (all) + Layer 1 (alternates)
    // Back rail: Layer 0 (all) + Layer 1 (alternates)

    if (position == "front") {
        // Layer 2 - all 20 wires
        for (i = [0 : NUM_SLATS - 1]) {
            x = slat_x(i, 2);
            y_offset = (LAYER_Y_CENTER[2] - FRONT_RAIL_Y);

            translate([x, y_offset, 0])
                cylinder(d = WIRE_HOLE_DIA + 0.5, h = TOP_RAIL_HEIGHT + 1, center = true);
        }

        // Layer 1 - front half of wires (odd indices)
        for (i = [0 : 2 : NUM_SLATS - 1]) {
            x = slat_x(i, 1);
            y_offset = (LAYER_Y_CENTER[1] - FRONT_RAIL_Y);

            translate([x, y_offset, 0])
                cylinder(d = WIRE_HOLE_DIA + 0.5, h = TOP_RAIL_HEIGHT + 1, center = true);
        }
    } else {
        // Layer 0 - all 20 wires
        for (i = [0 : NUM_SLATS - 1]) {
            x = slat_x(i, 0);
            y_offset = (LAYER_Y_CENTER[0] - BACK_RAIL_Y);

            translate([x, y_offset, 0])
                cylinder(d = WIRE_HOLE_DIA + 0.5, h = TOP_RAIL_HEIGHT + 1, center = true);
        }

        // Layer 1 - back half of wires (even indices)
        for (i = [1 : 2 : NUM_SLATS - 1]) {
            x = slat_x(i, 1);
            y_offset = (LAYER_Y_CENTER[1] - BACK_RAIL_Y);

            translate([x, y_offset, 0])
                cylinder(d = WIRE_HOLE_DIA + 0.5, h = TOP_RAIL_HEIGHT + 1, center = true);
        }
    }
}

// ============================================
// COLUMN MOUNTING HOLES
// ============================================

module column_mounting_holes() {
    for (x = COLUMN_X) {
        translate([x, 0, 0])
            cylinder(d = M4_HOLE, h = TOP_RAIL_HEIGHT + 1, center = true);
    }
}

// ============================================
// COMBINED RAIL ASSEMBLY
// ============================================

module top_rail_assembly() {
    // Front rail
    translate([0, FRONT_RAIL_Y, TOP_RAIL_Z])
    color(C_RAIL)
        top_rail("front");

    // Back rail
    translate([0, BACK_RAIL_Y, TOP_RAIL_Z])
    color(C_RAIL)
        top_rail("back");

    // Cross braces connecting front and back rails
    for (x = COLUMN_X) {
        translate([x, (FRONT_RAIL_Y + BACK_RAIL_Y) / 2, TOP_RAIL_Z])
        color(C_RAIL)
            cube([8, BACK_RAIL_Y - FRONT_RAIL_Y, TOP_RAIL_HEIGHT], center = true);
    }
}

// ============================================
// RENDER
// ============================================

top_rail_assembly();

// Show wires (transparent)
for (L = [0 : NUM_LAYERS - 1]) {
    for (i = [0, 5, 10, 15, 19]) {
        x = slat_x(i, L);
        y = LAYER_Y_CENTER[L];

        // Wire from rail down to slat height
        %translate([x, y, TOP_RAIL_Z - 30])
        color(C_WIRE)
            cylinder(d = WIRE_DIA, h = 60, $fn = 8);
    }
}

// ============================================
// INFO
// ============================================

echo("=== TOP RAIL ASSEMBLY ===");
echo(str("Rail length: ", TOP_RAIL_LENGTH, "mm"));
echo(str("Rail width: ", TOP_RAIL_WIDTH, "mm"));
echo(str("Rail height: ", TOP_RAIL_HEIGHT, "mm"));
echo(str("Rail Z position: ", TOP_RAIL_Z, "mm"));
echo("");
echo("RAIL POSITIONS:");
echo(str("  Front rail: Y=", FRONT_RAIL_Y, "mm"));
echo(str("  Back rail: Y=", BACK_RAIL_Y, "mm"));
echo("");
echo("WIRE HOLES:");
echo(str("  Hole diameter: ", WIRE_HOLE_DIA + 0.5, "mm"));
echo(str("  Total holes: 60 (distributed between rails)"));
echo("");
echo("Print: 2x rails + 2x cross braces");
