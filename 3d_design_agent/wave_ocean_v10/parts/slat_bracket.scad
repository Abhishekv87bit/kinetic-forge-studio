/*
 * SLAT BRACKET - Connects Slat to Guide Rail and Holds Arm Pivot
 *
 * Printable part: 24x
 * Print orientation: Upright (Z up)
 *
 * Features:
 * - Mounts to back of slat via M3 bolts
 * - Guide engagement tabs (front and back rails)
 * - Pivot mount for follower arm
 */

include <../common.scad>

$fn = 32;

// ============================================
// BRACKET PARAMETERS
// ============================================

BRACKET_MAIN_WIDTH = BRACKET_WIDTH;      // 10mm
BRACKET_MAIN_DEPTH = BRACKET_DEPTH;      // 15mm
BRACKET_MAIN_HEIGHT = BRACKET_HEIGHT;    // 20mm

PIVOT_MOUNT_OFFSET = 12;  // Distance below bracket top

// ============================================
// MAIN BRACKET MODULE
// ============================================

module slat_bracket() {
    difference() {
        union() {
            // Main body
            bracket_body();

            // Front guide tab
            front_guide_tab();

            // Back guide tab
            back_guide_tab();

            // Pivot mount
            pivot_mount();
        }

        // Slat mounting holes
        slat_mount_holes();

        // Pivot pin hole
        pivot_pin_hole();
    }
}

// ============================================
// BRACKET BODY
// ============================================

module bracket_body() {
    // Main vertical piece
    translate([-BRACKET_MAIN_WIDTH/2, 0, 0])
        cube([BRACKET_MAIN_WIDTH, BRACKET_MAIN_DEPTH, BRACKET_MAIN_HEIGHT]);
}

// ============================================
// GUIDE TABS
// ============================================

module front_guide_tab() {
    // Tab that engages front guide rail slot
    tab_height = 15;
    tab_depth = 6;

    translate([-GUIDE_TAB_WIDTH/2, -tab_depth, BRACKET_MAIN_HEIGHT - tab_height])
        cube([GUIDE_TAB_WIDTH, tab_depth, tab_height]);
}

module back_guide_tab() {
    // Tab that engages back guide rail slot
    tab_height = 15;
    tab_depth = 6;

    translate([-GUIDE_TAB_WIDTH/2, BRACKET_MAIN_DEPTH, BRACKET_MAIN_HEIGHT - tab_height])
        cube([GUIDE_TAB_WIDTH, tab_depth, tab_height]);
}

// ============================================
// PIVOT MOUNT
// ============================================

module pivot_mount() {
    // Boss that holds the follower arm pivot pin

    boss_dia = 12;
    boss_length = PIVOT_PIN_LENGTH + 4;  // Pin length + retention

    translate([0, BRACKET_MAIN_DEPTH/2, BRACKET_MAIN_HEIGHT - PIVOT_MOUNT_OFFSET])
    rotate([0, -90, 0]) {
        // Pivot boss (extends to side)
        cylinder(d=boss_dia, h=boss_length/2 + BRACKET_MAIN_WIDTH/2);

        // Other side
        rotate([0, 180, 0])
            cylinder(d=boss_dia, h=boss_length/2 + BRACKET_MAIN_WIDTH/2);
    }
}

// ============================================
// HOLES
// ============================================

module slat_mount_holes() {
    // 2x M3 clearance holes to bolt to slat
    for (z = [5, 15]) {
        translate([0, -1, z])
        rotate([-90, 0, 0])
            cylinder(d=M3_HOLE_DIA, h=BRACKET_MAIN_DEPTH + 10, $fn=16);
    }
}

module pivot_pin_hole() {
    // Through hole for 3mm pivot pin
    translate([-20, BRACKET_MAIN_DEPTH/2, BRACKET_MAIN_HEIGHT - PIVOT_MOUNT_OFFSET])
    rotate([0, 90, 0])
        cylinder(d=PIVOT_HOLE, h=40, $fn=24);
}

// ============================================
// RENDER
// ============================================

color(C_BRACKET)
slat_bracket();

// ============================================
// INFO
// ============================================

echo("=== SLAT BRACKET ===");
echo(str("Width: ", BRACKET_MAIN_WIDTH, "mm"));
echo(str("Depth: ", BRACKET_MAIN_DEPTH, "mm"));
echo(str("Height: ", BRACKET_MAIN_HEIGHT, "mm"));
echo(str("Pivot hole: ", PIVOT_HOLE, "mm"));
echo("");
echo("Print quantity: 24");
echo("Print orientation: Upright (as shown)");
echo("Assembly: Bolt to slat back with M3x8 screws");
