/*
 * FOLLOWER ARM - Pivoting Arm with Roller
 *
 * Printable part: 24x
 * Print orientation: Flat (Z up)
 *
 * Features:
 * - Pivot hole at one end (connects to slat pivot boss)
 * - Roller axle hole at other end (holds 624 bearing)
 * - Arm swings in Y-Z plane to track worm groove
 *
 * Built lying flat: pivot at origin, roller at +Y
 * When installed: rotated so arm hangs down from slat
 */

include <../common.scad>

$fn = 32;

// ============================================
// ARM PARAMETERS
// ============================================

ARM_MAIN_LENGTH = ARM_LENGTH;        // 35mm from pivot to roller
ARM_PIVOT_BOSS_DIA = 10;
ARM_ROLLER_BOSS_DIA = 14;

// ============================================
// MAIN FOLLOWER ARM MODULE
// ============================================

module follower_arm() {
    difference() {
        union() {
            // Main arm body
            arm_body();

            // Pivot boss
            pivot_boss();

            // Roller boss
            roller_boss();
        }

        // Pivot hole
        pivot_hole();

        // Roller axle hole
        roller_axle_hole();
    }
}

// ============================================
// ARM BODY
// ============================================

module arm_body() {
    // Straight beam from pivot (origin) to roller (+Y)
    hull() {
        cylinder(d=ARM_WIDTH, h=ARM_THICKNESS);

        translate([0, ARM_MAIN_LENGTH, 0])
            cylinder(d=ARM_WIDTH, h=ARM_THICKNESS);
    }
}

// ============================================
// PIVOT BOSS
// ============================================

module pivot_boss() {
    cylinder(d=ARM_PIVOT_BOSS_DIA, h=ARM_THICKNESS);
}

// ============================================
// ROLLER BOSS
// ============================================

module roller_boss() {
    translate([0, ARM_MAIN_LENGTH, 0])
        cylinder(d=ARM_ROLLER_BOSS_DIA, h=ARM_THICKNESS);
}

// ============================================
// HOLES
// ============================================

module pivot_hole() {
    translate([0, 0, -1])
        cylinder(d=PIVOT_HOLE, h=ARM_THICKNESS + 2, $fn=24);
}

module roller_axle_hole() {
    translate([0, ARM_MAIN_LENGTH, -1])
        cylinder(d=ROLLER_AXLE_HOLE, h=ARM_THICKNESS + 2, $fn=24);
}

// ============================================
// RENDER
// ============================================

color(C_ARM)
follower_arm();

// Visualization: 624 bearing
%translate([0, ARM_MAIN_LENGTH, ARM_THICKNESS/2])
    cylinder(d=BEARING_624_OD, h=BEARING_624_H, center=true, $fn=32);

// ============================================
// INFO
// ============================================

echo("=== FOLLOWER ARM ===");
echo(str("Length: ", ARM_MAIN_LENGTH, "mm"));
echo(str("Thickness: ", ARM_THICKNESS, "mm"));
echo("Print quantity: 24");
