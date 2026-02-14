/*
 * WAVE OCEAN V10 - TWISTED CAM ASSEMBLY
 *
 * Complete animated assembly of all parts
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * MECHANISM:
 * - Twisted cam (helical ridge) rotates around X axis
 * - Slats rest on cam surface, pushed up by ridge
 * - Single ridge spirals along cam creating traveling wave
 * - No follower arms needed - gravity keeps slats on surface
 *
 * COORDINATE SYSTEM:
 * - X: Along cam axis (left to right)
 * - Y: Front to back (viewer looks at -Y)
 * - Z: Up
 */

include <common.scad>
use <parts/twisted_cam.scad>
use <parts/slat.scad>
use <parts/guide_rail.scad>
use <parts/bearing_block.scad>
use <parts/base_plate.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_BASE = true;
SHOW_BEARING_BLOCKS = true;
SHOW_CAM = true;
SHOW_SHAFT = true;
SHOW_SLATS = true;
SHOW_GUIDES = true;
SHOW_BEARINGS = true;          // Ghost bearings

// Debug visualization
SHOW_CAM_SURFACE = false;       // Show where ridge is

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;              // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== BASE STRUCTURE ==========

    if (SHOW_BASE) {
        color(C_BASE)
            base_plate();
    }

    // ========== BEARING BLOCKS ==========

    if (SHOW_BEARING_BLOCKS) {
        // Left bearing block
        translate([BB_LEFT_X, 0, BASE_THICKNESS])
        color(C_BB)
            bearing_block();

        // Right bearing block
        translate([BB_RIGHT_X, 0, BASE_THICKNESS])
        color(C_BB)
            bearing_block();
    }

    // ========== SHAFT ==========

    if (SHOW_SHAFT) {
        translate([0, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
        color(C_SHAFT)
            cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);
    }

    // ========== TWISTED CAM ==========

    if (SHOW_CAM) {
        translate([0, 0, CAM_CENTER_Z])
        rotate([theta, 0, 0])  // Rotate around X axis
        color(C_CAM)
            twisted_cam();
    }

    // ========== SLATS ==========

    if (SHOW_SLATS) {
        for (i = [0 : NUM_SLATS - 1]) {
            slat_assembly(i);
        }
    }

    // ========== GUIDE RAILS ==========

    if (SHOW_GUIDES) {
        // Front guide rail
        translate([0, GUIDE_FRONT_Y, GUIDE_Z])
        color(C_GUIDE)
            guide_rail();

        // Back guide rail
        translate([0, GUIDE_BACK_Y + GUIDE_THICKNESS, GUIDE_Z])
        color(C_GUIDE)
            guide_rail();
    }

    // ========== BEARINGS (ghost) ==========

    if (SHOW_BEARINGS) {
        // Left bearing
        %translate([BB_LEFT_X + BB_WIDTH/2 - BEARING_POCKET_DEPTH/2, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);

        // Right bearing
        %translate([BB_RIGHT_X - BB_WIDTH/2 + BEARING_POCKET_DEPTH/2, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
    }

    // ========== DEBUG: CAM SURFACE ==========

    if (SHOW_CAM_SURFACE) {
        cam_surface_visualization();
    }
}

// ============================================
// SINGLE SLAT ASSEMBLY
// ============================================

module slat_assembly(i) {
    x = slat_x(i);
    z = slat_z(i, theta);

    // Color gradient - darker at ends, lighter in middle
    t = abs(i - NUM_SLATS/2) / (NUM_SLATS/2);
    c = [
        0.1 + 0.15 * (1-t),
        0.25 + 0.25 * (1-t),
        0.5 + 0.35 * (1-t)
    ];

    translate([x, 0, z])
    color(c)
        slat();
}

// ============================================
// CAM SURFACE VISUALIZATION
// ============================================

module cam_surface_visualization() {
    // Show where the ridge currently is
    color([1, 0.5, 0, 0.5])
    for (x = [-CAM_LENGTH/2 : 10 : CAM_LENGTH/2]) {
        z = CAM_CENTER_Z + cam_radius(x, theta);
        translate([x, 0, z])
            sphere(d = 3, $fn = 8);
    }
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("===========================================");
echo("  WAVE OCEAN V10 - TWISTED CAM ASSEMBLY");
echo("===========================================");
echo("");
echo(str("Theta: ", theta, "°"));
echo(str("Cam center Z: ", CAM_CENTER_Z, "mm"));
echo(str("Cam radius: ", CAM_CORE_RADIUS, "-", CAM_MAX_RADIUS, "mm"));
echo(str("Wave amplitude: ", WAVE_AMPLITUDE, "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
echo("");
echo("PARTS LIST:");
echo("  - Twisted cam: 1x");
echo("  - Slat: 24x");
echo("  - Guide rail: 2x");
echo("  - Bearing block: 2x");
echo("  - Base plate: 1x");
echo("");
echo("HARDWARE:");
echo("  - 608 bearing: 2x");
echo("  - 8mm shaft: 260mm");
echo("  - M3 set screws: 4x");
echo("  - M4x12 screws: 8x (bearing blocks)");
echo("  - M3x8 screws: 4x (guide rails)");
