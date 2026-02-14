/*
 * WAVE OCEAN - TRUE INTERLOCKING ASSEMBLY
 *
 * CRITICAL FIX: Uses slat_x(i, L) with X-OFFSET per layer
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * LAYER ORDER:
 * - Layer 0 = BACK (Y=20, dark, has back tabs)
 * - Layer 1 = MID (Y=10, medium)
 * - Layer 2 = FRONT (Y=0, light, closest to viewer)
 */

include <common.scad>
use <parts/cam.scad>
use <parts/slat.scad>
use <parts/hinge.scad>
use <parts/backplate.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_SLATS = true;
SHOW_CAMS = true;
SHOW_SHAFT = true;
SHOW_HINGES = true;
SHOW_BACKPLATE = true;
SHOW_FRAME = true;

SHOW_LAYER = [true, true, true];

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== SHAFT ==========
    if (SHOW_SHAFT) {
        shaft_y = (CAM_Y[0] + CAM_Y[2]) / 2;  // Center between all cams

        translate([0, shaft_y, CAM_CENTER_Z])
        rotate([0, 90, 0])
        color(C_SHAFT)
            cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);
    }

    // ========== CAMS ==========
    if (SHOW_CAMS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYER[L]) {
                translate([0, CAM_Y[L], CAM_CENTER_Z])
                rotate([theta, 0, 0])
                color(C_CAM)
                    cam(L);
            }
        }
    }

    // ========== SLATS (with X-OFFSET per layer!) ==========
    if (SHOW_SLATS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYER[L]) {
                layer_slats(L);
            }
        }
    }

    // ========== HINGES ==========
    if (SHOW_HINGES) {
        all_hinges();
    }

    // ========== BACKPLATE (behind Layer 0) ==========
    if (SHOW_BACKPLATE) {
        translate([0, BACKPLATE_Y, 0])
        color(C_BACKPLATE)
            backplate();
    }

    // ========== FRAME ==========
    if (SHOW_FRAME) {
        frame();
    }
}

// ============================================
// SLATS FOR ONE LAYER - KEY FIX: slat_x(i, L)
// ============================================

module layer_slats(L) {
    y = LAYER_Y_CENTER[L];
    col = LAYER_COLORS[L];

    for (i = [0 : NUM_SLATS - 1]) {
        // KEY FIX: Use slat_x(i, L) not slat_x(i)
        x = slat_x(i, L);
        z = slat_z(i, L, theta);
        h = slat_height(i);

        translate([x, y, z])
        color(col)
            slat_with_hinge_hole(h, L);
    }
}

// ============================================
// HINGES
// ============================================

module all_hinges() {
    hinge_interval = 3;

    for (i = [0 : hinge_interval : NUM_SLATS - 1]) {
        z0 = slat_z(i, 0, theta);
        z1 = slat_z(i, 1, theta);
        z2 = slat_z(i, 2, theta);

        // Note: slats are at different X positions due to LAYER_X_OFFSET
        // Hinges need to connect across this offset
        hinge_set_corrected(i, z0, z1, z2);
    }
}

// ============================================
// CORRECTED HINGE SET
// ============================================

module hinge_set_corrected(i, z0, z1, z2) {
    // Each layer has different X position
    x0 = slat_x(i, 0);
    x1 = slat_x(i, 1);
    x2 = slat_x(i, 2);

    // Hinge between Layer 0 (back) and Layer 1 (mid)
    // Y position between the two layers
    hinge_y_01 = (LAYER_Y_CENTER[0] + LAYER_Y_CENTER[1]) / 2;
    hinge_z_01 = (z0 + z1) / 2 + HINGE_HEIGHT_FROM_BOTTOM;
    hinge_x_01 = (x0 + x1) / 2;

    translate([hinge_x_01, hinge_y_01, hinge_z_01])
    color(C_HINGE)
        hinge_rod_angled(x0, x1);

    // Hinge between Layer 1 (mid) and Layer 2 (front)
    hinge_y_12 = (LAYER_Y_CENTER[1] + LAYER_Y_CENTER[2]) / 2;
    hinge_z_12 = (z1 + z2) / 2 + HINGE_HEIGHT_FROM_BOTTOM;
    hinge_x_12 = (x1 + x2) / 2;

    translate([hinge_x_12, hinge_y_12, hinge_z_12])
    color(C_HINGE)
        hinge_rod_angled(x1, x2);
}

// ============================================
// ANGLED HINGE ROD (connects offset slats)
// ============================================

module hinge_rod_angled(x_from, x_to) {
    x_diff = x_to - x_from;
    y_span = 10;  // Distance between layers in Y
    length = sqrt(x_diff * x_diff + y_span * y_span);
    angle = atan2(x_diff, y_span);

    rotate([90, 0, angle])
    cylinder(d = HINGE_ROD_DIA, h = length, center = true, $fn = 16);

    // End caps
    for (end = [-1, 1]) {
        translate([end * x_diff/2, end * y_span/2, 0])
        rotate([90, 0, angle])
            cylinder(d = HINGE_ROD_DIA + 1, h = 1.5, center = true, $fn = 16);
    }
}

// ============================================
// FRAME
// ============================================

module frame() {
    // Base plate
    color(C_FRAME)
    translate([0, (CAM_Y[0] + CAM_Y[2])/2, -5])
        cube([SHAFT_LENGTH + 20, 40, 10], center = true);

    // Left bearing block
    color(C_BB)
    translate([BB_LEFT_X, (CAM_Y[0] + CAM_Y[2])/2, BB_HEIGHT/2])
        cube([BB_WIDTH, BB_DEPTH, BB_HEIGHT], center = true);

    // Right bearing block
    color(C_BB)
    translate([BB_RIGHT_X, (CAM_Y[0] + CAM_Y[2])/2, BB_HEIGHT/2])
        cube([BB_WIDTH, BB_DEPTH, BB_HEIGHT], center = true);
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("============================================");
echo("  TRUE INTERLOCKING WAVE ASSEMBLY");
echo("============================================");
echo("");
echo(str("Animation theta: ", theta, " degrees"));
echo("");
echo("KEY FIX: slat_x(i, L) includes LAYER_X_OFFSET");
echo(str("  LAYER_X_OFFSET: ", LAYER_X_OFFSET));
echo("");
echo("LAYER ORDER:");
echo(str("  Layer 0 (BACK):  Y=", LAYER_Y_CENTER[0], ", X offset=", LAYER_X_OFFSET[0]));
echo(str("  Layer 1 (MID):   Y=", LAYER_Y_CENTER[1], ", X offset=", LAYER_X_OFFSET[1]));
echo(str("  Layer 2 (FRONT): Y=", LAYER_Y_CENTER[2], ", X offset=", LAYER_X_OFFSET[2]));
echo("");
echo("Slats interleave like fingers - no collision!");
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
