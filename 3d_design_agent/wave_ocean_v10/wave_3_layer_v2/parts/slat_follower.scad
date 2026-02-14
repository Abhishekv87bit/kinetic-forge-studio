/*
 * SLAT WITH FOLLOWER ARM
 *
 * DESIGN:
 * - Wave-shaped slat body
 * - Wire attachment hole at top (for fish wire suspension)
 * - Follower arm at bottom (extends toward cam)
 * - Roller at end of arm (contacts cam surface)
 *
 * Each layer's slats have different follower arm lengths
 * to reach their respective cams at different Y positions.
 *
 * Print: 60x total (20 per layer)
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN SLAT MODULE
// ============================================

module slat_follower(height = SLAT_BASE_HEIGHT, layer = 0) {
    union() {
        // Main wave body
        wave_body(height);

        // Follower arm at bottom (extends in +Y toward cam)
        follower_arm(layer);

        // Wire attachment point at top
        wire_attachment(height);
    }
}

// ============================================
// WAVE BODY
// ============================================

module wave_body(height) {
    hull() {
        // Base
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 0.5]);

        // Mid section
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, height * 0.7])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.9, 0.5]);

        // Upper taper
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH * 0.25, height * 0.9])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.5, 0.5]);

        // Rounded crest
        translate([0, 0, height])
        scale([1, 0.25, 0.5])
        rotate([0, 90, 0])
            cylinder(d = 4, h = SLAT_THICKNESS, center = true, $fn = 16);
    }
}

// ============================================
// FOLLOWER ARM (extends toward cam)
// ============================================

module follower_arm(layer) {
    arm_length = FOLLOWER_ARM_Y[layer];

    if (arm_length > 0) {
        // Arm extends in +Y direction toward cam
        translate([0, SLAT_DEPTH/2, 0])
        rotate([-90, 0, 0]) {
            // Arm body
            cylinder(d = FOLLOWER_ARM_DIA, h = arm_length, $fn = 16);

            // Roller at end
            translate([0, 0, arm_length])
                follower_roller();
        }
    } else {
        // Layer 2: cam is directly below, just add roller pad
        translate([0, 0, -FOLLOWER_ROLLER_DIA/2])
            follower_roller();
    }
}

// ============================================
// FOLLOWER ROLLER
// ============================================

module follower_roller() {
    // Roller that contacts cam surface
    rotate([90, 0, 0])
        cylinder(d = FOLLOWER_ROLLER_DIA, h = FOLLOWER_ROLLER_WIDTH, center = true, $fn = 24);
}

// ============================================
// WIRE ATTACHMENT
// ============================================

module wire_attachment(height) {
    // Reinforced area at top for wire hole
    translate([0, 0, height - 3])
    difference() {
        // Thickened top
        hull() {
            translate([-SLAT_THICKNESS/2, -2, 0])
                cube([SLAT_THICKNESS, 4, 4]);
        }

        // Wire hole
        translate([0, 0, 2])
            cylinder(d = WIRE_HOLE_DIA, h = 6, center = true, $fn = 16);
    }
}

// ============================================
// SLAT WITH GUIDE TAB (for channel guides)
// ============================================

module slat_with_guide_tab(height = SLAT_BASE_HEIGHT, layer = 0) {
    union() {
        slat_follower(height, layer);

        // Guide tabs on sides (fit into channel guides)
        for (side = [-1, 1]) {
            translate([side * (SLAT_THICKNESS/2 + 0.5), 0, height/2])
                cube([1, 3, height * 0.8], center = true);
        }
    }
}

// ============================================
// RENDER - Show sample slats from each layer
// ============================================

// Layer 0 (back) - longest follower arm
translate([0, LAYER_Y_CENTER[0], 0])
color(LAYER_COLORS[0])
    slat_follower(slat_height(0), 0);

// Layer 1 (mid) - medium follower arm
translate([12, LAYER_Y_CENTER[1], 0])
color(LAYER_COLORS[1])
    slat_follower(slat_height(5), 1);

// Layer 2 (front) - no follower arm (cam directly below)
translate([24, LAYER_Y_CENTER[2], 0])
color(LAYER_COLORS[2])
    slat_follower(slat_height(10), 2);

// Show where cams would be (transparent)
for (L = [0 : NUM_LAYERS - 1]) {
    x_pos = L * 12;
    %translate([x_pos, CAM_Y[L], CAM_Z[L]])
    rotate([0, 90, 0])
        cylinder(d = CAM_MAX_RADIUS * 2, h = 5, center = true);
}

// ============================================
// INFO
// ============================================

echo("=== SLAT WITH FOLLOWER ===");
echo(str("Slat thickness: ", SLAT_THICKNESS, "mm"));
echo(str("Slat depth: ", SLAT_DEPTH, "mm"));
echo(str("Wire hole: ", WIRE_HOLE_DIA, "mm"));
echo("");
echo("FOLLOWER ARM LENGTHS:");
echo(str("  Layer 0: ", FOLLOWER_ARM_Y[0], "mm"));
echo(str("  Layer 1: ", FOLLOWER_ARM_Y[1], "mm"));
echo(str("  Layer 2: ", FOLLOWER_ARM_Y[2], "mm (direct contact)"));
echo("");
echo("Print: 60x total (20 per layer)");
