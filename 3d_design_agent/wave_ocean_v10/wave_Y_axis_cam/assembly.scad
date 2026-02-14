/*
 * WAVE OCEAN - Y-AXIS BARREL CAM ASSEMBLY
 * TRUE TRAVELING WAVE
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * KEY GEOMETRY:
 * - Slats arranged along X-axis (36 per layer)
 * - Cam shaft along Y-axis (perpendicular to slats)
 * - 3 barrel cams, one per layer
 * - As cam rotates around Y, wave travels along X
 *
 * WHY THIS WORKS:
 * The helical ridge on each cam spirals around Y.
 * When the cam rotates, the "peak" of the helix appears to
 * move along X. Slats positioned along X get pushed up
 * in sequence = traveling wave.
 */

include <common.scad>
use <parts/barrel_cam.scad>
use <parts/slat.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_SLATS = true;
SHOW_CAMS = true;
SHOW_SHAFT = true;
SHOW_FRAME = true;

// Layer toggles
SHOW_LAYER = [true, true, true];

// ============================================
// ANIMATION
// ============================================

// theta: cam rotation angle around Y-axis
MANUAL_ANGLE = -1;  // Set 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== SHAFT (along Y-axis) ==========
    if (SHOW_SHAFT) {
        translate([0, 0, CAM_CENTER_Z])
        rotate([-90, 0, 0])
        color(C_SHAFT)
            cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);
    }

    // ========== CAMS (3 layers) ==========
    if (SHOW_CAMS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYER[L]) {
                cam_at_layer(L);
            }
        }
    }

    // ========== SLATS (3 layers × 36 each) ==========
    if (SHOW_SLATS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYER[L]) {
                layer_slats(L);
            }
        }
    }

    // ========== FRAME (simple support) ==========
    if (SHOW_FRAME) {
        frame();
    }
}

// ============================================
// CAM AT LAYER
// ============================================

module cam_at_layer(L) {
    y = LAYER_Y[L];

    // The cam is built with:
    // - Body extending along X
    // - Shaft hole along Y
    // - Profile in X-Z plane
    //
    // To rotate around Y-axis (the shaft), we use rotate([0, theta, 0])
    // But the cam profile is built for rotation around its local axis
    //
    // Actually, let me reconsider: the barrel_cam module creates
    // a profile where the radius varies based on angle in X-Z plane.
    // The helix_angle determines WHERE on the circumference the ridge is.
    //
    // When we rotate the entire cam around Y, we're effectively
    // changing which part of the circumference faces "up" (+Z).
    //
    // But wait - the cam_profile_2d uses angle in polar coordinates,
    // and helix_angle offsets where the ridge peak is.
    // When we physically rotate the cam, we change which part faces up.
    //
    // The math in slat_z uses theta to compute the surface height,
    // which accounts for this rotation. So we just need to visually
    // rotate the cam to match.

    translate([0, y, CAM_CENTER_Z])
    rotate([0, theta, 0])  // Rotate around Y-axis
    color(C_CAM)
        barrel_cam(L);
}

// ============================================
// SLATS FOR ONE LAYER
// ============================================

module layer_slats(L) {
    y = LAYER_Y[L];
    col = LAYER_COLORS[L];

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);
        z = slat_z(i, L, theta);
        h = slat_height(i);

        translate([x, y, z])
        color(col)
            slat(h);
    }
}

// ============================================
// SIMPLE FRAME
// ============================================

module frame() {
    // Base plate
    color(C_FRAME)
    translate([0, 0, -5])
        cube([SLAT_ROW_LENGTH + 40, 80, 10], center = true);

    // Side supports
    for (x = [-SLAT_ROW_LENGTH/2 - 10, SLAT_ROW_LENGTH/2 + 10]) {
        color(C_MOUNT)
        translate([x, 0, CAM_CENTER_Z/2])
            cube([10, 50, CAM_CENTER_Z + 10], center = true);
    }
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("============================================");
echo("  Y-AXIS BARREL CAM - TRAVELING WAVE");
echo("============================================");
echo("");
echo(str("Animation theta: ", theta, "°"));
echo("");
echo("CONFIGURATION:");
echo(str("  Slats along X: ", NUM_SLATS, " per layer"));
echo(str("  Layers: ", NUM_LAYERS));
echo(str("  Total slats: ", NUM_SLATS * NUM_LAYERS));
echo("");
echo("CAM SHAFT:");
echo("  Axis: Y (perpendicular to slat row)");
echo("  Rotation: Around Y creates traveling wave along X");
echo("");
echo("WAVE BEHAVIOR:");
echo("  Watch the wave travel from left to right as theta increases");
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
