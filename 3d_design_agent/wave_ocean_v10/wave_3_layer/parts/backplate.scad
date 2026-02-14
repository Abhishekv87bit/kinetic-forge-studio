/*
 * BACKPLATE - Guide Grooves for Layer 0 (BACK) Slats
 *
 * CORRECTED: Now positioned behind Layer 0 (Y > 25)
 * Layer 0 is the BACK layer at Y=20
 *
 * Contains 20 vertical grooves for Layer 0 slat tabs.
 */

include <../common.scad>

$fn = 32;

// ============================================
// BACKPLATE MODULE
// ============================================

module backplate() {
    difference() {
        plate_body();
        slat_grooves();
        mounting_holes();
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
// SLAT GROOVES (for Layer 0 tabs - using LAYER_X_OFFSET)
// ============================================

module slat_grooves() {
    // 20 vertical grooves for Layer 0 slat tabs
    // Layer 0 has X offset = 0

    for (i = [0 : NUM_SLATS - 1]) {
        // Use slat_x with layer=0 to get correct X positions
        x = slat_x(i, 0);

        groove_width = GROOVE_WIDTH;
        groove_height = BACKPLATE_HEIGHT - 10;

        translate([x - groove_width/2, -1, 5])
            cube([groove_width, GROOVE_DEPTH + 1, groove_height]);
    }
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    hole_inset = 10;

    for (x = [-BACKPLATE_WIDTH/2 + hole_inset, BACKPLATE_WIDTH/2 - hole_inset]) {
        for (z = [hole_inset, BACKPLATE_HEIGHT - hole_inset]) {
            translate([x, BACKPLATE_THICKNESS/2, z])
            rotate([90, 0, 0])
                cylinder(d = M4_HOLE, h = BACKPLATE_THICKNESS + 2, center = true, $fn = 16);
        }
    }
}

// ============================================
// RENDER
// ============================================

color(C_BACKPLATE)
    backplate();

// Show sample Layer 0 slat position
translate([slat_x(10, 0), -SLAT_DEPTH/2 - TAB_DEPTH + 2, 25])
color(LAYER_COLORS[0], 0.5)
    cube([SLAT_THICKNESS, SLAT_DEPTH + TAB_DEPTH, 35]);

// ============================================
// INFO
// ============================================

echo("=== BACKPLATE (CORRECTED) ===");
echo(str("Position: Y=", BACKPLATE_Y, "mm (behind Layer 0)"));
echo(str("Width: ", BACKPLATE_WIDTH, "mm"));
echo(str("Height: ", BACKPLATE_HEIGHT, "mm"));
echo("");
echo(str("Grooves: ", NUM_SLATS, " (for Layer 0 slats)"));
echo("Layer 0 is BACK layer, has back tabs");
