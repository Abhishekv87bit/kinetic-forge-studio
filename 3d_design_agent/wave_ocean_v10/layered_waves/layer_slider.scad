/*
 * LAYER SLIDER - Mounting Block for Wave Layers
 *
 * Each wave layer attaches to a slider block
 * Slider rides on vertical guide rod
 * Follower arm connects to cam below
 *
 * Printable part: 12x (3 waves × 4 layers)
 */

include <common.scad>

$fn = 32;

// ============================================
// SLIDER DIMENSIONS
// ============================================

GUIDE_HOLE_DIA = GUIDE_ROD_DIA + TOL_SLIDING;  // 4.3mm
FOLLOWER_PIVOT_DIA = 3;                          // M3 pivot
LAYER_MOUNT_WIDTH = 20;
LAYER_MOUNT_SLOT_WIDTH = LAYER_THICKNESS + 1;

// ============================================
// MAIN MODULE
// ============================================

module layer_slider() {
    difference() {
        union() {
            // Main slider body
            slider_body();

            // Layer mounting tab
            layer_mount();

            // Follower arm pivot boss
            follower_pivot_boss();
        }

        // Guide rod hole (vertical)
        guide_rod_hole();

        // Follower pivot hole
        follower_pivot_hole();

        // Layer mounting slot
        layer_mount_slot();
    }
}

// ============================================
// SLIDER BODY
// ============================================

module slider_body() {
    // Main block that slides on guide rod
    translate([-SLIDER_WIDTH/2, -SLIDER_DEPTH/2, 0])
        cube([SLIDER_WIDTH, SLIDER_DEPTH, SLIDER_HEIGHT]);
}

// ============================================
// LAYER MOUNT TAB
// ============================================

module layer_mount() {
    // Tab extending to side for wave layer attachment
    mount_height = SLIDER_HEIGHT - 4;

    translate([SLIDER_WIDTH/2, -SLIDER_DEPTH/2, 2])
        cube([LAYER_MOUNT_WIDTH, SLIDER_DEPTH, mount_height]);
}

// ============================================
// FOLLOWER PIVOT BOSS
// ============================================

module follower_pivot_boss() {
    // Boss on bottom for follower arm attachment
    boss_dia = 10;

    translate([0, 0, 0])
        cylinder(d = boss_dia, h = 5);
}

// ============================================
// GUIDE ROD HOLE
// ============================================

module guide_rod_hole() {
    // Vertical hole for guide rod
    translate([0, 0, -1])
        cylinder(d = GUIDE_HOLE_DIA, h = SLIDER_HEIGHT + 2);
}

// ============================================
// FOLLOWER PIVOT HOLE
// ============================================

module follower_pivot_hole() {
    // Horizontal hole for follower arm pivot pin
    translate([0, -SLIDER_DEPTH/2 - 1, 5])
    rotate([-90, 0, 0])
        cylinder(d = FOLLOWER_PIVOT_DIA + TOL_CLEARANCE, h = SLIDER_DEPTH + 2);
}

// ============================================
// LAYER MOUNT SLOT
// ============================================

module layer_mount_slot() {
    // Slot to capture wave layer profile edge
    slot_depth = 8;

    translate([SLIDER_WIDTH/2 + LAYER_MOUNT_WIDTH - slot_depth,
               -LAYER_MOUNT_SLOT_WIDTH/2,
               -1])
        cube([slot_depth + 1, LAYER_MOUNT_SLOT_WIDTH, SLIDER_HEIGHT + 2]);
}

// ============================================
// FOLLOWER ARM
// ============================================

module follower_arm() {
    // Arm connecting slider to cam
    // Pivot at top, roller at bottom

    arm_thickness = 5;

    difference() {
        union() {
            // Main arm
            hull() {
                // Top pivot end
                cylinder(d = 10, h = arm_thickness);

                // Bottom roller end
                translate([0, -FOLLOWER_ARM_LENGTH, 0])
                    cylinder(d = 12, h = arm_thickness);
            }
        }

        // Pivot hole (top)
        translate([0, 0, -1])
            cylinder(d = FOLLOWER_PIVOT_DIA + TOL_CLEARANCE, h = arm_thickness + 2);

        // Roller axle hole (bottom)
        translate([0, -FOLLOWER_ARM_LENGTH, -1])
            cylinder(d = 4 + TOL_CLEARANCE, h = arm_thickness + 2);
    }
}

// ============================================
// RENDER
// ============================================

color(C_MECHANISM)
layer_slider();

// Show follower arm
translate([0, 0, -5])
rotate([0, 0, 0])
color(C_MECHANISM)
    follower_arm();

// Show guide rod ghost
%translate([0, 0, -10])
    cylinder(d = GUIDE_ROD_DIA, h = GUIDE_ROD_LENGTH);

echo("=== LAYER SLIDER ===");
echo(str("Size: ", SLIDER_WIDTH, " x ", SLIDER_DEPTH, " x ", SLIDER_HEIGHT, "mm"));
echo("Print quantity: 12 (3 waves × 4 layers)");
echo("Also print: 12 follower arms");
