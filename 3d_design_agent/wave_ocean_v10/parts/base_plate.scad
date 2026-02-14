/*
 * BASE PLATE - Main Structural Base
 *
 * Printable part: 1x (or 2x if split)
 * Print orientation: Flat
 *
 * Features:
 * - Mounting holes for guide rails
 * - Mounting holes for bearing blocks
 * - Motor mount extension
 * - Optional split line for smaller printers
 */

include <../common.scad>

$fn = 32;

// ============================================
// SPLIT OPTIONS
// ============================================

SPLIT_PLATE = false;         // Set true to split for smaller printers
SHOW_LEFT_HALF = true;
SHOW_RIGHT_HALF = true;

// ============================================
// MAIN BASE PLATE MODULE
// ============================================

module base_plate() {
    difference() {
        union() {
            // Main plate
            main_plate();

            // Motor mount extension
            motor_extension();

            // Guide rail mounting standoffs
            guide_standoffs();
        }

        // Guide rail mounting holes
        guide_rail_holes();

        // Bearing block mounting holes
        bearing_block_holes();

        // Motor mount holes
        motor_mount_holes();

        // Split alignment holes (if splitting)
        if (SPLIT_PLATE) {
            alignment_holes();
        }

        // Lightening holes
        lightening_holes();
    }
}

// ============================================
// MAIN PLATE
// ============================================

module main_plate() {
    translate([-BASE_LENGTH/2, -BASE_WIDTH/2, 0])
        cube([BASE_LENGTH, BASE_WIDTH, BASE_THICKNESS]);
}

// ============================================
// MOTOR EXTENSION
// ============================================

module motor_extension() {
    // Extension on right side for motor mount
    ext_length = 40;
    ext_width = 40;

    translate([BASE_LENGTH/2, -ext_width/2, 0])
        cube([ext_length, ext_width, BASE_THICKNESS]);

    // Transition fillet
    translate([BASE_LENGTH/2, -BASE_WIDTH/2, 0])
    linear_extrude(height=BASE_THICKNESS)
        polygon([[0, 0], [ext_length, BASE_WIDTH/2 - ext_width/2], [0, BASE_WIDTH/2 - ext_width/2]]);

    translate([BASE_LENGTH/2, BASE_WIDTH/2, 0])
    linear_extrude(height=BASE_THICKNESS)
        polygon([[0, 0], [ext_length, -(BASE_WIDTH/2 - ext_width/2)], [0, -(BASE_WIDTH/2 - ext_width/2)]]);
}

// ============================================
// GUIDE STANDOFFS
// ============================================

module guide_standoffs() {
    // Raised areas where guide rails mount
    standoff_height = 3;

    // Front guide standoff
    translate([-GUIDE_LENGTH/2, GUIDE_FRONT_Y - 5, BASE_THICKNESS])
        cube([GUIDE_LENGTH, 15, standoff_height]);

    // Back guide standoff
    translate([-GUIDE_LENGTH/2, GUIDE_BACK_Y - 5, BASE_THICKNESS])
        cube([GUIDE_LENGTH, 15, standoff_height]);
}

// ============================================
// MOUNTING HOLES
// ============================================

module guide_rail_holes() {
    // Front guide rail - 4 holes
    for (x = [-GUIDE_LENGTH/2 + 20, -GUIDE_LENGTH/4, GUIDE_LENGTH/4, GUIDE_LENGTH/2 - 20]) {
        translate([x, GUIDE_FRONT_Y, -1])
            cylinder(d=M3_HOLE_DIA, h=BASE_THICKNESS + 10, $fn=16);
    }

    // Back guide rail - 4 holes
    for (x = [-GUIDE_LENGTH/2 + 20, -GUIDE_LENGTH/4, GUIDE_LENGTH/4, GUIDE_LENGTH/2 - 20]) {
        translate([x, GUIDE_BACK_Y, -1])
            cylinder(d=M3_HOLE_DIA, h=BASE_THICKNESS + 10, $fn=16);
    }
}

module bearing_block_holes() {
    // Left bearing block - 2 holes
    hole_offset = BEARING_BLOCK_WIDTH/2 - 5;
    for (x = [-hole_offset, hole_offset]) {
        translate([BEARING_L_X + x, 0, -1]) {
            cylinder(d=M3_HOLE_DIA, h=BASE_THICKNESS + 10, $fn=16);
            // Nut trap on bottom
            translate([0, 0, -M3_NUT_H + 1])
            rotate([0, 0, 30])
                cylinder(d=M3_NUT_FLAT * 2 / sqrt(3), h=M3_NUT_H + 1, $fn=6);
        }
    }

    // Right bearing block - 2 holes
    for (x = [-hole_offset, hole_offset]) {
        translate([BEARING_R_X + x, 0, -1]) {
            cylinder(d=M3_HOLE_DIA, h=BASE_THICKNESS + 10, $fn=16);
            translate([0, 0, -M3_NUT_H + 1])
            rotate([0, 0, 30])
                cylinder(d=M3_NUT_FLAT * 2 / sqrt(3), h=M3_NUT_H + 1, $fn=6);
        }
    }
}

module motor_mount_holes() {
    // 4 holes for motor mount
    motor_x = BASE_LENGTH/2 + 25;

    for (dx = [-10, 10]) {
        for (dy = [-10, 10]) {
            translate([motor_x + dx, dy, -1])
                cylinder(d=M3_HOLE_DIA, h=BASE_THICKNESS + 10, $fn=16);
        }
    }
}

// ============================================
// ALIGNMENT AND LIGHTENING
// ============================================

module alignment_holes() {
    // Dowel holes at split line for alignment
    for (y = [-20, 0, 20]) {
        translate([0, y, BASE_THICKNESS/2])
        rotate([0, 90, 0])
            cylinder(d=4.1, h=20, center=true, $fn=16);
    }
}

module lightening_holes() {
    // Optional holes to reduce material/weight
    // Large cutouts between mounting points

    for (x = [-60, 0, 60]) {
        translate([x, 0, -1])
            cylinder(d=25, h=BASE_THICKNESS + 2, $fn=32);
    }
}

// ============================================
// RENDER
// ============================================

color(C_BASE)
if (SPLIT_PLATE) {
    if (SHOW_LEFT_HALF) {
        intersection() {
            base_plate();
            translate([-200, -100, -1])
                cube([200, 200, 20]);
        }
    }
    if (SHOW_RIGHT_HALF) {
        intersection() {
            base_plate();
            translate([0, -100, -1])
                cube([200, 200, 20]);
        }
    }
} else {
    base_plate();
}

// ============================================
// INFO
// ============================================

echo("=== BASE PLATE ===");
echo(str("Length: ", BASE_LENGTH, "mm + 40mm motor extension"));
echo(str("Width: ", BASE_WIDTH, "mm"));
echo(str("Thickness: ", BASE_THICKNESS, "mm"));
echo("");
echo("Print quantity: 1 (or 2 if SPLIT_PLATE=true)");
echo("Print orientation: Flat");
echo("Set SPLIT_PLATE=true if plate exceeds print bed");
