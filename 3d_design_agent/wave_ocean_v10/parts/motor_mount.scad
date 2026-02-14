/*
 * MOTOR MOUNT - N20 Geared Motor Bracket
 *
 * Printable part: 1x
 * Print orientation: Base down
 *
 * Features:
 * - Clamp for N20 motor body
 * - Alignment with worm shaft
 * - Base mounting holes
 */

include <../common.scad>

$fn = 32;

// ============================================
// MOTOR MOUNT PARAMETERS
// ============================================

MOUNT_WIDTH = 30;
MOUNT_DEPTH = 25;
// MOUNT_HEIGHT is defined in common.scad

CLAMP_GAP = 2;  // Gap for clamping screw

// ============================================
// MAIN MOTOR MOUNT MODULE
// ============================================

module motor_mount() {
    difference() {
        union() {
            // Base
            mount_base();

            // Motor clamp tower
            clamp_tower();
        }

        // Motor body pocket
        motor_pocket();

        // Clamp slot
        clamp_slot();

        // Clamp screw hole
        clamp_screw_hole();

        // Base mounting holes
        base_mount_holes();
    }
}

// ============================================
// MOUNT BASE
// ============================================

module mount_base() {
    translate([-MOUNT_WIDTH/2, -MOUNT_DEPTH/2, 0])
        cube([MOUNT_WIDTH, MOUNT_DEPTH, 5]);
}

// ============================================
// CLAMP TOWER
// ============================================

module clamp_tower() {
    // Vertical section that holds motor
    tower_dia = N20_BODY_DIA + 8;

    translate([0, 0, 5])
        cylinder(d=tower_dia, h=MOUNT_HEIGHT - 5);

    // Support ribs
    for (angle = [45, 135, 225, 315]) {
        rotate([0, 0, angle])
        translate([0, 0, 5])
        linear_extrude(height=MOUNT_HEIGHT - 20)
            polygon([[0, 0], [tower_dia/2 + 5, 0], [tower_dia/2 + 5, 3], [0, 3]]);
    }
}

// ============================================
// MOTOR POCKET
// ============================================

module motor_pocket() {
    // Pocket for N20 motor body
    pocket_dia = N20_BODY_DIA + 0.5;  // Slight clearance
    pocket_depth = N20_BODY_LENGTH + 5;

    translate([0, 0, MOUNT_HEIGHT - pocket_depth])
        cylinder(d=pocket_dia, h=pocket_depth + 1);

    // Gearbox clearance
    translate([0, 0, MOUNT_HEIGHT - pocket_depth - N20_GEARBOX_LENGTH])
        cylinder(d=N20_GEARBOX_DIA + 1, h=N20_GEARBOX_LENGTH + 1);

    // Shaft exit hole
    translate([0, 0, -1])
        cylinder(d=N20_SHAFT_DIA + 2, h=MOUNT_HEIGHT);
}

// ============================================
// CLAMP MECHANISM
// ============================================

module clamp_slot() {
    // Slot that allows clamp to squeeze
    translate([-CLAMP_GAP/2, -20, 5])
        cube([CLAMP_GAP, 40, MOUNT_HEIGHT]);
}

module clamp_screw_hole() {
    // M3 screw hole perpendicular to clamp slot
    translate([15, 0, MOUNT_HEIGHT - 15])
    rotate([0, -90, 0]) {
        cylinder(d=M3_HOLE_DIA, h=30, $fn=16);

        // Nut trap
        translate([0, 0, 20])
        rotate([0, 0, 30])
            cylinder(d=M3_NUT_FLAT * 2 / sqrt(3), h=5, $fn=6);
    }
}

// ============================================
// BASE MOUNTING HOLES
// ============================================

module base_mount_holes() {
    for (dx = [-10, 10]) {
        for (dy = [-10, 10]) {
            translate([dx, dy, -1])
                cylinder(d=M3_HOLE_DIA, h=10, $fn=16);
        }
    }
}

// ============================================
// RENDER
// ============================================

color(C_MOTOR)
motor_mount();

// Visualization: N20 motor
%translate([0, 0, MOUNT_HEIGHT + 2]) {
    // Body
    cylinder(d=N20_BODY_DIA, h=N20_BODY_LENGTH);

    // Gearbox
    translate([0, 0, -N20_GEARBOX_LENGTH])
        cylinder(d=N20_GEARBOX_DIA, h=N20_GEARBOX_LENGTH);

    // Shaft
    translate([0, 0, -N20_GEARBOX_LENGTH - N20_SHAFT_LENGTH])
        cylinder(d=N20_SHAFT_DIA, h=N20_SHAFT_LENGTH);
}

// ============================================
// INFO
// ============================================

echo("=== MOTOR MOUNT ===");
echo(str("Mount height: ", MOUNT_HEIGHT, "mm"));
echo(str("For N20 motor: ", N20_BODY_DIA, "mm body"));
echo("");
echo("Print quantity: 1");
echo("Print orientation: Base down");
echo("Assembly: Insert motor, tighten clamp screw");
