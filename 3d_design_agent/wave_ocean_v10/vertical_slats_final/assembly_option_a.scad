/*
 * OPTION A: ASSEMBLY - 3 Pressed-On Cams on Single Shaft
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * LAYOUT:
 *   - Single 8mm shaft runs through all bearings
 *   - 3 separate barrel cams pressed onto shaft
 *   - Each cam at its layer's Y position
 *   - Each layer's slats ride their respective cam
 *
 * ADVANTAGES:
 *   - Each cam is full 40mm width = STRONG
 *   - Modular: can replace one cam
 *   - Adjustable phase per cam
 *   - Standard proven geometry
 */

include <common.scad>
use <parts/cam_option_a.scad>
use <parts/slat.scad>
use <parts/bearing_block.scad>
use <parts/base_plate.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_BASE = true;
SHOW_BEARING_BLOCKS = true;
SHOW_SHAFT = true;
SHOW_CAMS = true;
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
// CAM POSITIONS ON SHAFT
// ============================================

// Each cam centered at its layer's Y position
CAM_Y_POSITIONS = LAYER_Y_OFFSET;  // [-15, 0, +15]

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly_option_a() {

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

    // ========== 3 CAMS ON SHAFT ==========
    if (SHOW_CAMS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYERS[L]) {
                cam_on_shaft(L);
            }
        }
    }

    // ========== SLATS ==========
    if (SHOW_SLATS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYERS[L]) {
                layer_slats_a(L);
            }
        }
    }
}

// ============================================
// SINGLE CAM ON SHAFT
// ============================================

module cam_on_shaft(L) {
    y_pos = CAM_Y_POSITIONS[L];
    ridge = LAYER_RIDGE_HEIGHT[L];
    phase_off = LAYER_PHASE_OFFSET[L];

    color(C_CAM)
    translate([0, y_pos, CAM_CENTER_Z])
    rotate([theta, 0, 0])  // Rotate around X (shaft axis)
        barrel_cam(ridge, phase_off);
}

// ============================================
// SLATS FOR ONE LAYER
// ============================================

module layer_slats_a(L) {
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

assembly_option_a();

// ============================================
// INFO
// ============================================

echo("==============================================");
echo("  OPTION A: 3 PRESSED-ON CAMS ASSEMBLY");
echo("==============================================");
echo("");
echo(str("Animation theta: ", theta, "°"));
echo("");
echo("CAM POSITIONS (Y axis):");
for (L = [0 : NUM_LAYERS - 1]) {
    echo(str("  Cam ", L, ": Y = ", CAM_Y_POSITIONS[L], "mm, ridge = ", LAYER_RIDGE_HEIGHT[L], "mm"));
}
echo("");
echo("SLATS:");
echo(str("  Per layer: ", NUM_SLATS));
echo(str("  Total: ", NUM_SLATS * NUM_LAYERS));
echo("");
echo("MECHANICAL NOTES:");
echo("  - Each cam is 40mm wide in Y (strong!)");
echo("  - Cams lock to shaft via M3 set screw");
echo("  - Phase adjustable by rotating cam before tightening");
