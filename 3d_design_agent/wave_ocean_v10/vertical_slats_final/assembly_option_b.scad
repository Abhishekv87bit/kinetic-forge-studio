/*
 * OPTION B: ASSEMBLY - Monolithic 3-Section Cam
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * LAYOUT:
 *   - Single monolithic cam with 3 Y-sections
 *   - Each section has different ridge height
 *   - Sections connected by end caps
 *   - Each layer's slats ride their respective section
 *
 * ADVANTAGES:
 *   - Single piece = simpler assembly
 *   - Sections structurally connected
 *   - Fewer parts to manage
 */

include <common.scad>
use <parts/cam_option_b.scad>
use <parts/slat.scad>
use <parts/bearing_block.scad>
use <parts/base_plate.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_BASE = true;
SHOW_BEARING_BLOCKS = true;
SHOW_SHAFT = true;
SHOW_CAM = true;
SHOW_SLATS = true;

SHOW_LAYER_0 = true;
SHOW_LAYER_1 = true;
SHOW_LAYER_2 = true;
SHOW_LAYERS = [SHOW_LAYER_0, SHOW_LAYER_1, SHOW_LAYER_2];

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly_option_b() {

    // ========== BASE PLATE ==========
    if (SHOW_BASE) {
        color(C_BASE)
            base_plate();
    }

    // ========== BEARING BLOCKS ==========
    if (SHOW_BEARING_BLOCKS) {
        color(C_BB)
        translate([BB_LEFT_X, 0, BB_Z])
        rotate([0, 0, 180])
            bearing_block();

        color(C_BB)
        translate([BB_RIGHT_X, 0, BB_Z])
            bearing_block();
    }

    // ========== SHAFT ==========
    if (SHOW_SHAFT) {
        color(C_SHAFT)
        translate([0, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);
    }

    // ========== MONOLITHIC CAM ==========
    if (SHOW_CAM) {
        color(C_CAM)
        translate([0, 0, CAM_CENTER_Z])
        rotate([theta, 0, 0])  // Rotate around X (shaft axis)
            monolithic_cam();
    }

    // ========== SLATS ==========
    if (SHOW_SLATS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYERS[L]) {
                layer_slats_b(L);
            }
        }
    }
}

// ============================================
// SLATS FOR ONE LAYER
// ============================================

module layer_slats_b(L) {
    y = LAYER_Y_OFFSET[L];
    col = LAYER_COLORS[L];

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);
        z = layer_slat_z(i, L, theta);
        h = layer_slat_height(i, L);

        color(col)
        translate([x, y, z])
            slat(h);
    }
}

// ============================================
// RENDER
// ============================================

assembly_option_b();

// ============================================
// INFO
// ============================================

echo("==============================================");
echo("  OPTION B: MONOLITHIC 3-SECTION CAM ASSEMBLY");
echo("==============================================");
echo("");
echo(str("Animation theta: ", theta, "°"));
echo("");
echo("CAM SECTIONS (Y axis):");
for (L = [0 : NUM_LAYERS - 1]) {
    y1 = LAYER_Y_OFFSET[L] - CAM_DISC_THICKNESS/2;
    y2 = LAYER_Y_OFFSET[L] + CAM_DISC_THICKNESS/2;
    echo(str("  Section ", L, ": Y = [", y1, " to ", y2, "], ridge = ", LAYER_RIDGE_HEIGHT[L], "mm"));
}
echo("");
echo("SLATS:");
echo(str("  Per layer: ", NUM_SLATS));
echo(str("  Total: ", NUM_SLATS * NUM_LAYERS));
echo("");
echo("MECHANICAL NOTES:");
echo("  - Single piece cam (print as one)");
echo("  - Sections are 12mm thick with 3mm gaps");
echo("  - End caps connect all sections");
echo("  - Fixed phase relationship");
