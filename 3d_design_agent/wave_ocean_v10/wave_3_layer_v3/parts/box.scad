/*
 * BOX.SCAD - Whack-a-Mole Enclosure
 *
 * Box with slits on top. Slats slide through slits.
 * Cams hidden inside push slats up from below.
 *
 * STRUCTURE:
 * - Base plate (bottom)
 * - Four walls
 * - Floor plate with slits (top of box, slats emerge here)
 * - Shaft holes in side walls
 */

include <../common.scad>

$fn = 32;

// ============================================
// COMPLETE BOX MODULE
// ============================================

module box_complete() {
    difference() {
        union() {
            // Base plate
            base_plate();

            // Walls
            walls();

            // Floor plate with slits
            translate([0, 0, FLOOR_Z - SLIT_FLOOR_THICKNESS])
                floor_plate();
        }

        // Shaft holes through side walls
        shaft_holes();

        // Motor access hole (back wall)
        motor_access();
    }
}

// ============================================
// BASE PLATE
// ============================================

module base_plate() {
    translate([0, BOX_WIDTH/2, WALL_THICKNESS/2])
        cube([BOX_LENGTH, BOX_WIDTH, WALL_THICKNESS], center = true);
}

// ============================================
// WALLS
// ============================================

module walls() {
    // Left wall (-X)
    translate([-BOX_LENGTH/2 + WALL_THICKNESS/2, BOX_WIDTH/2, BOX_HEIGHT/2])
        cube([WALL_THICKNESS, BOX_WIDTH, BOX_HEIGHT], center = true);

    // Right wall (+X)
    translate([BOX_LENGTH/2 - WALL_THICKNESS/2, BOX_WIDTH/2, BOX_HEIGHT/2])
        cube([WALL_THICKNESS, BOX_WIDTH, BOX_HEIGHT], center = true);

    // Back wall (+Y)
    translate([0, BOX_WIDTH - WALL_THICKNESS/2, BOX_HEIGHT/2])
        cube([BOX_LENGTH, WALL_THICKNESS, BOX_HEIGHT], center = true);

    // Front wall (-Y) - partial, leaves viewing window
    translate([0, WALL_THICKNESS/2, BOX_HEIGHT/2])
        cube([BOX_LENGTH, WALL_THICKNESS, BOX_HEIGHT], center = true);
}

// ============================================
// FLOOR PLATE WITH SLITS
// ============================================

module floor_plate() {
    difference() {
        // Solid floor
        translate([0, BOX_WIDTH/2, SLIT_FLOOR_THICKNESS/2])
            cube([BOX_LENGTH - WALL_THICKNESS * 2, BOX_WIDTH - WALL_THICKNESS * 2, SLIT_FLOOR_THICKNESS], center = true);

        // Cut slits for all slats (shared slit bank)
        slits();
    }
}

// ============================================
// SLITS - WHERE SLATS EMERGE
// ============================================

module slits() {
    // All 60 slats share this slit area
    // Each slat gets its own slit at its layer's Y position

    for (layer = [0 : NUM_LAYERS - 1]) {
        for (i = [0 : NUM_SLATS - 1]) {
            x = slat_x(i, layer);
            y = LAYER_Y_BOX[layer];  // Use absolute box coordinates!

            // Each slat gets its own narrow slit
            translate([x, y, SLIT_FLOOR_THICKNESS/2])
                cube([SLIT_WIDTH, SLAT_DEPTH + TOL_CLEARANCE * 2, SLIT_FLOOR_THICKNESS + 1], center = true);
        }
    }
}

// ============================================
// SHAFT HOLES - Through side walls
// ============================================

module shaft_holes() {
    // 3 shafts, one per cam layer
    for (layer = [0 : NUM_LAYERS - 1]) {
        y = CAM_Y_BOX[layer];  // Use absolute box coordinates!
        z = CAM_Z[layer];

        // Left side hole
        translate([-BOX_LENGTH/2 - 1, y, z])
        rotate([0, 90, 0])
            cylinder(d = SHAFT_HOLE, h = WALL_THICKNESS + 2);

        // Right side hole
        translate([BOX_LENGTH/2 - WALL_THICKNESS - 1, y, z])
        rotate([0, 90, 0])
            cylinder(d = SHAFT_HOLE, h = WALL_THICKNESS + 2);
    }
}

// ============================================
// MOTOR ACCESS - Hole in back wall
// ============================================

module motor_access() {
    // Large hole for motor/belt access
    translate([0, BOX_WIDTH, CAM_Z[0]])
    rotate([90, 0, 0])
        cylinder(d = 30, h = WALL_THICKNESS + 2);
}

// ============================================
// BOX WITH VIEWING WINDOW
// ============================================

module box_with_window() {
    difference() {
        box_complete();

        // Front viewing window (optional - see cams inside)
        translate([0, -1, BOX_HEIGHT/2])
            cube([BOX_LENGTH - 40, 10, BOX_HEIGHT - 20], center = true);
    }
}

// ============================================
// INDIVIDUAL COMPONENTS FOR PRINTING
// ============================================

module box_base_only() {
    difference() {
        union() {
            base_plate();
            walls();
        }
        shaft_holes();
        motor_access();
    }
}

module floor_plate_only() {
    floor_plate();
}

// ============================================
// RENDER
// ============================================

color(C_BOX)
    box_complete();

// Show slit positions (debug)
// %for (layer = [0 : NUM_LAYERS - 1]) {
//     for (i = [0 : 2 : NUM_SLATS - 1]) {
//         x = slat_x(i, layer);
//         y = LAYER_Y_CENTER[layer] + BOX_WIDTH/2 - LAYER_Y_CENTER[0];
//         translate([x, y, FLOOR_Z])
//             cylinder(d = 2, h = 20, $fn = 8);
//     }
// }

// ============================================
// INFO
// ============================================

echo("=== BOX ENCLOSURE ===");
echo(str("Dimensions: ", BOX_LENGTH, " x ", BOX_WIDTH, " x ", BOX_HEIGHT, "mm"));
echo(str("Wall thickness: ", WALL_THICKNESS, "mm"));
echo(str("Floor Z: ", FLOOR_Z, "mm"));
echo(str("Slit dimensions: ", SLIT_WIDTH, " x ", SLAT_DEPTH + TOL_CLEARANCE * 2, "mm"));
echo(str("Total slits: ", NUM_SLATS * NUM_LAYERS));
