/*
 * STRUCTURAL BACKPLATE
 *
 * Printable part: 1x (or 2 halves for smaller printers)
 * Print orientation: Flat on back
 *
 * Features:
 * - 24 vertical grooves for slat back tabs
 * - Hides all guidance mechanism from viewer
 * - Structural support for entire assembly
 * - Mounting points for bearing blocks
 * - Can be painted/finished as background
 */

include <common.scad>

$fn = 32;

// ============================================
// CONFIGURATION
// ============================================

SPLIT_BACKPLATE = false;  // Set true for 2 halves

// ============================================
// MAIN MODULE
// ============================================

module backplate() {
    difference() {
        union() {
            // Main plate body
            backplate_body();

            // Bearing block mounting bosses
            bearing_bosses();

            // Bottom support rail
            bottom_rail();
        }

        // Vertical grooves for slat tabs
        slat_grooves();

        // Bearing block mounting holes
        bearing_holes();

        // Weight reduction pockets (back side)
        weight_reduction();

        // Optional: mounting holes for frame
        frame_mounting_holes();
    }
}

// ============================================
// BACKPLATE BODY
// ============================================

module backplate_body() {
    // Main structural plate
    translate([-BACKPLATE_WIDTH/2, 0, 0])
        cube([BACKPLATE_WIDTH, BACKPLATE_THICKNESS, BACKPLATE_HEIGHT]);
}

// ============================================
// SLAT GROOVES - Vertical channels
// ============================================

module slat_grooves() {
    // Each groove is sized for TAB_WIDTH + tolerance
    // Grooves run vertically for full slat travel range

    groove_bottom = 5;  // Start above base
    groove_top = BACKPLATE_HEIGHT - 5;
    groove_length = groove_top - groove_bottom;

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);

        // Main groove channel
        translate([x - GROOVE_WIDTH/2, BACKPLATE_THICKNESS - GROOVE_DEPTH, groove_bottom])
            cube([GROOVE_WIDTH, GROOVE_DEPTH + 1, groove_length]);

        // Chamfer at groove entrance (easier insertion)
        translate([x - GROOVE_WIDTH/2 - 0.5, BACKPLATE_THICKNESS - 2, groove_bottom])
            cube([GROOVE_WIDTH + 1, 3, groove_length]);
    }
}

// ============================================
// BEARING BLOCK MOUNTING BOSSES
// ============================================

module bearing_bosses() {
    boss_width = 35;
    boss_height = 40;
    boss_depth = 10;

    // Left boss
    translate([-BACKPLATE_WIDTH/2 - boss_width/2 + 20, BACKPLATE_THICKNESS, 0])
        cube([boss_width, boss_depth, boss_height]);

    // Right boss
    translate([BACKPLATE_WIDTH/2 - 20 - boss_width/2, BACKPLATE_THICKNESS, 0])
        cube([boss_width, boss_depth, boss_height]);
}

// ============================================
// BEARING BLOCK HOLES
// ============================================

module bearing_holes() {
    hole_spacing = 18;

    for (x_pos = [-BACKPLATE_WIDTH/2 + 20, BACKPLATE_WIDTH/2 - 20]) {
        for (x_off = [-hole_spacing/2, hole_spacing/2]) {
            for (z_off = [10, 28]) {
                translate([x_pos + x_off, BACKPLATE_THICKNESS - 1, z_off])
                rotate([-90, 0, 0])
                    cylinder(d = M4_HOLE, h = 15, $fn = 24);
            }
        }
    }
}

// ============================================
// BOTTOM SUPPORT RAIL
// ============================================

module bottom_rail() {
    // Extends forward to support bearing blocks
    rail_depth = 40;
    rail_height = 10;

    translate([-BACKPLATE_WIDTH/2, -rail_depth + BACKPLATE_THICKNESS, 0])
        cube([BACKPLATE_WIDTH, rail_depth, rail_height]);
}

// ============================================
// WEIGHT REDUCTION (back side)
// ============================================

module weight_reduction() {
    // Pockets on back side to reduce material
    // Not visible from front

    pocket_depth = BACKPLATE_THICKNESS - 8;  // Leave 8mm front wall

    // Large central pocket
    translate([-60, -1, 30])
        cube([120, pocket_depth, 50]);

    // Side pockets
    for (x_sign = [-1, 1]) {
        translate([x_sign * 80, -1, 25])
            cube([30, pocket_depth, 60]);
    }
}

// ============================================
// FRAME MOUNTING HOLES
// ============================================

module frame_mounting_holes() {
    // Holes at corners for mounting to external frame

    for (x_sign = [-1, 1]) {
        for (z = [15, BACKPLATE_HEIGHT - 15]) {
            translate([x_sign * (BACKPLATE_WIDTH/2 - 15), -1, z])
            rotate([-90, 0, 0])
                cylinder(d = 5, h = BACKPLATE_THICKNESS + 2, $fn = 24);
        }
    }
}

// ============================================
// RENDER
// ============================================

color(C_BACKPLATE)
backplate();

// Show groove positions
for (i = [0 : NUM_SLATS - 1]) {
    x = slat_x(i);
    %translate([x, BACKPLATE_THICKNESS - GROOVE_DEPTH/2, BACKPLATE_HEIGHT/2])
        cube([1, 1, BACKPLATE_HEIGHT - 20], center = true);
}

echo("=== STRUCTURAL BACKPLATE ===");
echo(str("Size: ", BACKPLATE_WIDTH, " x ", BACKPLATE_THICKNESS, " x ", BACKPLATE_HEIGHT, "mm"));
echo(str("Grooves: ", NUM_SLATS, " x ", GROOVE_WIDTH, "mm wide"));
echo("");
if (SPLIT_BACKPLATE) {
    echo("Print: 2 halves");
} else {
    echo("Print: 1 piece (requires 240mm bed)");
}
echo("Orientation: Flat on back (grooves up)");
