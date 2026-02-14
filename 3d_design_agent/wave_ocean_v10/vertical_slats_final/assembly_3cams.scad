/*
 * ASSEMBLY - 3 Separate Cams on Shared Shaft
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * LAYOUT:
 * - Single 8mm shaft through all bearings
 * - 3 separate barrel cams at Y = -15, 0, +15
 * - Each cam has different ridge height (4, 7, 10mm)
 * - 3 layers of slats, each riding its respective cam
 *
 * COLLISION-FREE:
 * - Cams are 12mm wide with 3mm gaps between them
 * - Slats are 10mm deep with 5mm gaps between layers
 *
 * WAVE EFFECT:
 * - Back layer (Cam 2) has largest amplitude (10mm ridge)
 * - Front layer (Cam 0) has smallest amplitude (4mm ridge)
 * - Creates depth/parallax effect
 */

include <common.scad>
use <parts/cam_separate.scad>
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

// Per-layer visibility (for debugging)
SHOW_LAYER = [true, true, true];  // [front, mid, back]

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set 0-360 for static pose, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly_3cams() {

    // ========== BASE PLATE ==========
    if (SHOW_BASE) {
        color(C_BASE)
            base_plate();
    }

    // ========== BEARING BLOCKS ==========
    if (SHOW_BEARING_BLOCKS) {
        // Left block
        color(C_BB)
        translate([BB_LEFT_X, 0, BB_Z])
        rotate([0, 0, 180])
            bearing_block();

        // Right block
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

    // ========== 3 SEPARATE CAMS ==========
    if (SHOW_CAMS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYER[L]) {
                render_cam(L);
            }
        }
    }

    // ========== 3 LAYERS OF SLATS ==========
    if (SHOW_SLATS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYER[L]) {
                render_slats(L);
            }
        }
    }
}

// ============================================
// RENDER SINGLE CAM
// ============================================

module render_cam(L) {
    y_pos = LAYER_Y_OFFSET[L];
    ridge = LAYER_RIDGE_HEIGHT[L];
    phase = LAYER_PHASE_OFFSET[L];

    color(C_CAM)
    translate([0, y_pos, CAM_CENTER_Z])
    rotate([theta, 0, 0])  // Rotate around X (shaft axis)
        separate_cam(ridge, phase);
}

// ============================================
// RENDER SLATS FOR ONE LAYER
// ============================================

module render_slats(L) {
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

assembly_3cams();

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("================================================");
echo("  3 SEPARATE CAMS ASSEMBLY");
echo("================================================");
echo("");
echo(str("Animation theta: ", theta, "°"));
echo("");

echo("CAM CONFIGURATION:");
for (L = [0 : NUM_LAYERS - 1]) {
    y_start = LAYER_Y_OFFSET[L] - CAM_WIDTH/2;
    y_end = LAYER_Y_OFFSET[L] + CAM_WIDTH/2;
    ridge = LAYER_RIDGE_HEIGHT[L];
    echo(str("  Cam ", L, ": Y=[", y_start, " to ", y_end, "], ridge=", ridge, "mm"));
}
echo("");

echo("SLAT CONFIGURATION:");
for (L = [0 : NUM_LAYERS - 1]) {
    y_start = LAYER_Y_OFFSET[L] - SLAT_DEPTH/2;
    y_end = LAYER_Y_OFFSET[L] + SLAT_DEPTH/2;
    echo(str("  Layer ", L, ": Y=[", y_start, " to ", y_end, "]"));
}
echo("");

echo("COLLISION CHECK (flanges only on outer cams):");

// Cam 0: front flange only → back edge at Y = -15 + 6 = -9
// Cam 1: no flanges → Y = [-6, +6]
// Cam 2: back flange only → front edge at Y = +15 - 6 = +9
cam0_back = LAYER_Y_OFFSET[0] + CAM_WIDTH/2;  // -9
cam1_front = LAYER_Y_OFFSET[1] - CAM_WIDTH/2; // -6
cam1_back = LAYER_Y_OFFSET[1] + CAM_WIDTH/2;  // +6
cam2_front = LAYER_Y_OFFSET[2] - CAM_WIDTH/2; // +9

cam_gap_01 = cam1_front - cam0_back;  // -6 - (-9) = 3mm
cam_gap_12 = cam2_front - cam1_back;  // +9 - (+6) = 3mm

slat_gap_01 = (LAYER_Y_OFFSET[1] - SLAT_DEPTH/2) - (LAYER_Y_OFFSET[0] + SLAT_DEPTH/2);
slat_gap_12 = (LAYER_Y_OFFSET[2] - SLAT_DEPTH/2) - (LAYER_Y_OFFSET[1] + SLAT_DEPTH/2);

echo(str("  Cam 0 back edge: Y=", cam0_back, "mm"));
echo(str("  Cam 1 extent: Y=[", cam1_front, " to ", cam1_back, "]mm"));
echo(str("  Cam 2 front edge: Y=", cam2_front, "mm"));
echo("");
echo(str("  Cam gap 0-1: ", cam_gap_01, "mm ", (cam_gap_01 > 0 ? "✓ NO COLLISION" : "COLLISION!")));
echo(str("  Cam gap 1-2: ", cam_gap_12, "mm ", (cam_gap_12 > 0 ? "✓ NO COLLISION" : "COLLISION!")));
echo(str("  Slat gap 0-1: ", slat_gap_01, "mm ", (slat_gap_01 > 0 ? "✓" : "COLLISION!")));
echo(str("  Slat gap 1-2: ", slat_gap_12, "mm ", (slat_gap_12 > 0 ? "✓" : "COLLISION!")));
echo("");

echo("MECHANICAL NOTES:");
echo("  - Flanges: Cam 0 has FRONT flange, Cam 2 has BACK flange, Cam 1 has NONE");
echo("  - This prevents collision while keeping follower retention at edges");
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
