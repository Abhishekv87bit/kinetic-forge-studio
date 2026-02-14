/*
 * BACKPLATE - Structural Support with 36 Grooves
 *
 * Printable part: 1x (or 2 halves for smaller beds)
 * Print orientation: Flat on back
 *
 * DESIGN:
 * - 36 vertical grooves aligned with slat positions
 * - Grooves sized for 2.5mm slat tabs
 * - Integrates bearing block mounting
 * - All guidance hidden from viewer
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN BACKPLATE MODULE
// ============================================

module backplate() {
    difference() {
        union() {
            // Main plate body
            plate_body();

            // Bearing block mounting flanges
            bearing_flanges();
        }

        // Slat grooves
        slat_grooves();

        // Bearing mounting holes
        bearing_holes();

        // Weight reduction
        weight_reduction();
    }
}

// ============================================
// PLATE BODY
// ============================================

module plate_body() {
    translate([-BACKPLATE_WIDTH/2, 0, 0])
        cube([BACKPLATE_WIDTH, BACKPLATE_THICKNESS, BACKPLATE_HEIGHT]);
}

// ============================================
// SLAT GROOVES - 36 precisely positioned
// ============================================

module slat_grooves() {
    groove_start = 3;
    groove_end = BACKPLATE_HEIGHT - 3;
    groove_length = groove_end - groove_start;

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);

        // Main groove channel
        translate([x - GROOVE_WIDTH/2,
                   BACKPLATE_THICKNESS - GROOVE_DEPTH,
                   groove_start])
            cube([GROOVE_WIDTH, GROOVE_DEPTH + 1, groove_length]);

        // Entry chamfer
        translate([x - GROOVE_WIDTH/2 - 0.3,
                   BACKPLATE_THICKNESS - 0.5,
                   groove_start])
            cube([GROOVE_WIDTH + 0.6, 1, groove_length]);
    }
}

// ============================================
// BEARING FLANGES
// ============================================

module bearing_flanges() {
    flange_width = 22;
    flange_depth = BB_DEPTH;
    flange_height = BB_HEIGHT + 5;

    for (x_sign = [-1, 1]) {
        x_pos = x_sign * (BACKPLATE_WIDTH/2) - (x_sign > 0 ? flange_width : 0);

        translate([x_pos, -flange_depth + BACKPLATE_THICKNESS, 0])
            cube([flange_width, flange_depth, flange_height]);
    }
}

// ============================================
// BEARING MOUNTING HOLES
// ============================================

module bearing_holes() {
    for (x_sign = [-1, 1]) {
        x_pos = x_sign * (BACKPLATE_WIDTH/2 - 11);

        for (z = [8, BB_HEIGHT - 3]) {
            // Through hole
            translate([x_pos, -BB_DEPTH, z])
            rotate([-90, 0, 0])
                cylinder(d = M4_HOLE, h = BB_DEPTH + BACKPLATE_THICKNESS + 2, $fn = 24);

            // Counterbore
            translate([x_pos, BACKPLATE_THICKNESS - 2, z])
            rotate([-90, 0, 0])
                cylinder(d = M4_HEAD_DIA + 1, h = 3, $fn = 24);
        }
    }
}

// ============================================
// WEIGHT REDUCTION
// ============================================

module weight_reduction() {
    pocket_depth = BACKPLATE_THICKNESS - 5;

    // Central pocket
    translate([-BACKPLATE_WIDTH/2 + 25, -1, 35])
        cube([BACKPLATE_WIDTH - 50, pocket_depth, 20]);
}

// ============================================
// RENDER
// ============================================

color(C_BACKPLATE)
backplate();

echo("=== BACKPLATE ===");
echo(str("Size: ", BACKPLATE_WIDTH, " x ", BACKPLATE_THICKNESS, " x ", BACKPLATE_HEIGHT, "mm"));
echo(str("Grooves: ", NUM_SLATS, " x ", GROOVE_WIDTH, "mm"));
