/*
 * FRAME - Base Plate + Support Columns
 *
 * DESIGN:
 * - Sturdy base plate for bearing blocks and motor
 * - Four corner columns supporting top rail
 * - Motor mount position
 *
 * Print: Multiple parts
 * - 1x base plate
 * - 4x columns (or print integrated with base)
 * - 1x motor mount
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN FRAME MODULE
// ============================================

module frame_complete() {
    // Base plate
    color(C_FRAME)
        base_plate();

    // Support columns
    for (x = COLUMN_X) {
        for (y = [FRONT_RAIL_Y - 5, BACK_RAIL_Y + 5]) {
            translate([x, y, BASE_THICKNESS])
            color(C_FRAME)
                support_column();
        }
    }

    // Motor mount (back center)
    translate([0, BASE_WIDTH/2 - 10, BASE_THICKNESS])
    color(C_FRAME)
        motor_mount();
}

// ============================================
// BASE PLATE
// ============================================

module base_plate() {
    difference() {
        // Main plate
        translate([0, BASE_WIDTH/2 - 20, BASE_THICKNESS/2])
            cube([BASE_LENGTH, BASE_WIDTH, BASE_THICKNESS], center = true);

        // Bearing block mounting holes (left)
        translate([BB_LEFT_X, 0, 0])
            bearing_block_mount_holes();

        // Bearing block mounting holes (right)
        translate([BB_RIGHT_X, 0, 0])
            bearing_block_mount_holes();

        // Column mounting holes
        for (x = COLUMN_X) {
            for (y = [FRONT_RAIL_Y - 5, BACK_RAIL_Y + 5]) {
                translate([x, y, 0])
                    cylinder(d = M4_HOLE, h = BASE_THICKNESS + 1, $fn = 24);
            }
        }

        // Wire routing slots (if needed)
        wire_routing_slots();
    }
}

// ============================================
// BEARING BLOCK MOUNT HOLES
// ============================================

module bearing_block_mount_holes() {
    for (y = [CAM_Y[0] - 8, CAM_Y[2] + 8]) {
        translate([0, y, 0])
            cylinder(d = M4_HOLE, h = BASE_THICKNESS + 1, $fn = 24);
    }
}

// ============================================
// WIRE ROUTING SLOTS
// ============================================

module wire_routing_slots() {
    // Slots for wire routing if wires need to pass through base
    // (Usually not needed since wires go upward)
}

// ============================================
// SUPPORT COLUMN
// ============================================

module support_column() {
    difference() {
        // Column body
        cube([COLUMN_WIDTH, COLUMN_DEPTH, COLUMN_HEIGHT]);

        // Bottom mounting hole (into base)
        translate([COLUMN_WIDTH/2, COLUMN_DEPTH/2, 0])
            cylinder(d = M4_HOLE, h = 15, $fn = 24);

        // Top mounting hole (for rail)
        translate([COLUMN_WIDTH/2, COLUMN_DEPTH/2, COLUMN_HEIGHT - 10])
            cylinder(d = M4_HOLE, h = 15, $fn = 24);

        // Weight relief cutouts
        for (z = [COLUMN_HEIGHT * 0.3, COLUMN_HEIGHT * 0.6]) {
            translate([COLUMN_WIDTH/2, -1, z])
            rotate([-90, 0, 0])
                cylinder(d = 6, h = COLUMN_DEPTH + 2, $fn = 24);
        }
    }
}

// ============================================
// MOTOR MOUNT
// ============================================

module motor_mount() {
    motor_plate_size = 42;  // NEMA 17 mounting
    motor_hole_spacing = 31;

    difference() {
        union() {
            // Vertical plate
            cube([motor_plate_size + 10, 8, motor_plate_size + 20]);

            // Base flange
            translate([0, 0, 0])
                cube([motor_plate_size + 10, 20, 8]);
        }

        // Motor shaft hole
        translate([motor_plate_size/2 + 5, -1, CAM_Z[0]])
        rotate([-90, 0, 0])
            cylinder(d = 25, h = 10, $fn = 32);

        // Motor mounting holes (NEMA 17 pattern)
        for (dx = [-motor_hole_spacing/2, motor_hole_spacing/2]) {
            for (dz = [-motor_hole_spacing/2, motor_hole_spacing/2]) {
                translate([motor_plate_size/2 + 5 + dx, -1, CAM_Z[0] + dz])
                rotate([-90, 0, 0])
                    cylinder(d = M3_HOLE, h = 10, $fn = 24);
            }
        }

        // Base mounting holes
        for (x = [8, motor_plate_size + 2]) {
            translate([x, 10, 0])
                cylinder(d = M4_HOLE, h = 10, $fn = 24);
        }
    }
}

// ============================================
// PULLEY SYSTEM (connects 3 shafts)
// ============================================

module pulley_system() {
    // GT2 pulleys on each shaft (outside left bearing block)
    pulley_x = BB_LEFT_X - BB_WIDTH/2 - 15;

    for (i = [0 : NUM_LAYERS - 1]) {
        translate([pulley_x, CAM_Y[i], CAM_Z[i]])
        rotate([0, 90, 0])
        color([0.3, 0.3, 0.35])
            difference() {
                cylinder(d = 15, h = 8, center = true);  // 20-tooth GT2
                cylinder(d = SHAFT_DIA + 0.2, h = 10, center = true);
            }
    }

    // Belt path visualization (simplified)
    color([0.2, 0.2, 0.2, 0.5])
    translate([pulley_x, 0, 0])
    hull() {
        for (i = [0 : NUM_LAYERS - 1]) {
            translate([0, CAM_Y[i], CAM_Z[i]])
            rotate([0, 90, 0])
                cylinder(d = 17, h = 2, center = true);
        }
    }
}

// ============================================
// RENDER
// ============================================

frame_complete();

// Show pulley system
pulley_system();

// Show bearing blocks (transparent reference)
%translate([BB_LEFT_X, 0, 0])
    cube([BB_WIDTH, BB_DEPTH, BB_HEIGHT], center = true);

%translate([BB_RIGHT_X, 0, 0])
    cube([BB_WIDTH, BB_DEPTH, BB_HEIGHT], center = true);

// ============================================
// INFO
// ============================================

echo("=== FRAME STRUCTURE ===");
echo(str("Base plate: ", BASE_LENGTH, " x ", BASE_WIDTH, " x ", BASE_THICKNESS, "mm"));
echo(str("Columns: ", COLUMN_WIDTH, " x ", COLUMN_DEPTH, " x ", COLUMN_HEIGHT, "mm"));
echo("");
echo("POSITIONS:");
echo(str("  Column X: ", COLUMN_X));
echo(str("  Bearing block X: ", BB_LEFT_X, " / ", BB_RIGHT_X));
echo("");
echo("Print:");
echo("  1x base plate");
echo("  4x columns");
echo("  1x motor mount");
