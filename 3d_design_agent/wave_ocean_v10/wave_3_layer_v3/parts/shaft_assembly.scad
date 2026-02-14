/*
 * SHAFT_ASSEMBLY.SCAD - Drive System
 *
 * 3 parallel shafts with:
 * - Barrel cams mounted on shafts
 * - Bearings at each end
 * - GT2 pulleys for belt drive
 * - Motor drives one shaft, belt drives others
 */

include <../common.scad>

$fn = 32;

// ============================================
// PULLEY PARAMETERS
// ============================================

PULLEY_TEETH = 20;
PULLEY_DIA = 12.7;         // 20-tooth GT2 pulley
PULLEY_WIDTH = 8;
PULLEY_BOSS_DIA = 16;
PULLEY_BOSS_HEIGHT = 4;

// Belt positioning (left side of box)
BELT_X = -BOX_LENGTH/2 - 15;

// ============================================
// COMPLETE SHAFT ASSEMBLY
// ============================================

module shaft_assembly() {
    // 3 shafts with bearings, cams, and pulleys
    for (layer = [0 : NUM_LAYERS - 1]) {
        shaft_with_components(layer);
    }

    // Belt visualization
    belt_path();
}

// ============================================
// SINGLE SHAFT WITH ALL COMPONENTS
// ============================================

module shaft_with_components(layer) {
    y = CAM_Y_BOX[layer];  // Use absolute box coordinates!
    z = CAM_Z[layer];

    // Shaft
    translate([0, y, z])
    rotate([0, 90, 0])
    color(C_SHAFT)
        cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);

    // Left bearing
    translate([-BOX_LENGTH/2 - 5, y, z])
        bearing_608();

    // Right bearing
    translate([BOX_LENGTH/2 + 5, y, z])
        bearing_608();

    // Pulley (left side, outside box)
    translate([BELT_X, y, z])
    rotate([0, 90, 0])
        gt2_pulley();
}

// ============================================
// 608 BEARING
// ============================================

module bearing_608() {
    rotate([0, 90, 0])
    color([0.8, 0.8, 0.8])
    difference() {
        cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
        cylinder(d = BEARING_608_ID, h = BEARING_608_H + 1, center = true);
    }
}

// ============================================
// GT2 PULLEY (20-tooth)
// ============================================

module gt2_pulley() {
    color([0.3, 0.3, 0.35])
    difference() {
        union() {
            // Main pulley body
            cylinder(d = PULLEY_DIA, h = PULLEY_WIDTH, center = true);

            // Boss/hub
            translate([0, 0, -PULLEY_WIDTH/2 - PULLEY_BOSS_HEIGHT/2])
                cylinder(d = PULLEY_BOSS_DIA, h = PULLEY_BOSS_HEIGHT, center = true);
        }

        // Shaft hole
        cylinder(d = SHAFT_HOLE, h = PULLEY_WIDTH + PULLEY_BOSS_HEIGHT + 2, center = true);

        // Teeth grooves (simplified)
        for (a = [0 : 18 : 359]) {
            rotate([0, 0, a])
            translate([PULLEY_DIA/2, 0, 0])
                cube([2, 1, PULLEY_WIDTH + 1], center = true);
        }
    }
}

// ============================================
// BELT PATH VISUALIZATION
// ============================================

module belt_path() {
    // Simplified belt path connecting all 3 pulleys
    color([0.2, 0.2, 0.2, 0.7])
    translate([BELT_X, 0, 0])
    linear_extrude(height = 6, center = true)
    hull() {
        for (layer = [0 : NUM_LAYERS - 1]) {
            translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Use absolute coordinates!
            rotate([90, 0, 0])
                circle(d = PULLEY_DIA + 4);
        }
    }

    // Note: Real belt would wrap around pulleys
    // This is simplified visualization
}

// ============================================
// BEARING BLOCKS (mount bearings to box walls)
// ============================================

module bearing_block() {
    // Block that holds 3 bearings in staggered Y+Z positions
    // Mounts to inside of box wall

    difference() {
        // Block body
        hull() {
            for (layer = [0 : NUM_LAYERS - 1]) {
                translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Use absolute coordinates!
                rotate([0, 90, 0])
                    cylinder(d = BEARING_608_OD + 8, h = 10, center = true);
            }
        }

        // Bearing pockets
        for (layer = [0 : NUM_LAYERS - 1]) {
            translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Use absolute coordinates!
            rotate([0, 90, 0])
                cylinder(d = BEARING_608_OD + TOL_PRESS_FIT, h = BEARING_608_H + 1, center = true);
        }

        // Shaft through-holes
        for (layer = [0 : NUM_LAYERS - 1]) {
            translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Use absolute coordinates!
            rotate([0, 90, 0])
                cylinder(d = SHAFT_HOLE, h = 20, center = true);
        }
    }
}

// ============================================
// MOTOR MOUNT
// ============================================

module motor_mount() {
    // NEMA 17 motor mount (outside back of box)
    motor_plate = 42;
    motor_spacing = 31;

    translate([BELT_X, BOX_WIDTH + 20, CAM_Z[0]])
    rotate([90, 0, 0])
    color([0.4, 0.4, 0.4])
    difference() {
        // Mount plate
        cube([motor_plate + 10, motor_plate + 10, 5], center = true);

        // Motor shaft hole
        cylinder(d = 25, h = 10, center = true);

        // Mounting holes
        for (dx = [-motor_spacing/2, motor_spacing/2]) {
            for (dy = [-motor_spacing/2, motor_spacing/2]) {
                translate([dx, dy, 0])
                    cylinder(d = M3_HOLE, h = 10, center = true);
            }
        }
    }
}

// ============================================
// RENDER
// ============================================

shaft_assembly();

// Show bearing blocks
translate([-BOX_LENGTH/2, 0, 0])
color([0.6, 0.6, 0.6, 0.5])
    bearing_block();

translate([BOX_LENGTH/2, 0, 0])
color([0.6, 0.6, 0.6, 0.5])
    bearing_block();

// Show motor mount
motor_mount();

// ============================================
// INFO
// ============================================

echo("=== SHAFT ASSEMBLY ===");
echo(str("Shaft diameter: ", SHAFT_DIA, "mm"));
echo(str("Shaft length: ", SHAFT_LENGTH, "mm"));
echo("");
echo("SHAFT POSITIONS (BOX COORDINATES):");
for (layer = [0 : NUM_LAYERS - 1]) {
    echo(str("  Shaft ", layer, ": Y=", CAM_Y_BOX[layer], ", Z=", CAM_Z[layer]));
}
echo("");
echo("COMPONENTS:");
echo("  3x 608 bearings per side (6 total)");
echo("  3x GT2 20-tooth pulleys");
echo("  1x GT2 belt (connects all 3 pulleys)");
echo("  1x NEMA 17 motor");
