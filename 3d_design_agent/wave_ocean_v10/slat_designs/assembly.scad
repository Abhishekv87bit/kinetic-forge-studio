/*
 * WAVE OCEAN V10 - VERTICAL SLAT ASSEMBLY
 *
 * Three slat types (A, B, C) with structural backplate
 * Clean front view - no guide rails visible
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * Slat Types:
 *   A (×10): Standard wave, 50mm
 *   B (×8):  Foam crest, 55mm
 *   C (×6):  Breaking curl, 60mm (TALLEST)
 */

include <common.scad>
use <slat_type_A.scad>
use <slat_type_B.scad>
use <slat_type_C.scad>
use <backplate.scad>

// Also need cam from twisted_cam system
use <../twisted_cam/parts/twisted_cam.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_BACKPLATE = true;
SHOW_CAM = true;
SHOW_SHAFT = true;
SHOW_SLATS = true;
SHOW_BEARINGS = true;

// View modes
FRONT_VIEW = false;            // Hide backplate for front view
EXPLODED_VIEW = false;         // Spread parts apart

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;             // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== BACKPLATE ==========
    if (SHOW_BACKPLATE && !FRONT_VIEW) {
        explode_y = EXPLODED_VIEW ? 30 : 0;

        translate([0, BACKPLATE_Y + explode_y, BACKPLATE_Z])
        color(C_BACKPLATE)
            backplate();
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
        rotate([theta, 0, 0])
        color(C_CAM)
            twisted_cam();
    }

    // ========== SLATS ==========
    if (SHOW_SLATS) {
        for (i = [0 : NUM_SLATS - 1]) {
            slat_at_position(i);
        }
    }

    // ========== BEARINGS (ghost) ==========
    if (SHOW_BEARINGS) {
        for (x_sign = [-1, 1]) {
            %translate([x_sign * (CAM_LENGTH/2 + 20), 0, CAM_CENTER_Z])
            rotate([0, 90, 0])
                cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
        }
    }
}

// ============================================
// SLAT POSITIONING
// ============================================

module slat_at_position(i) {
    x = slat_x(i);
    z = slat_z(i, theta);
    type = slat_type(i);

    // Explode offset
    explode_z = EXPLODED_VIEW ? 40 : 0;

    translate([x, 0, z + explode_z]) {
        if (type == "A") {
            slat_type_A();
        } else if (type == "B") {
            slat_type_B();
        } else if (type == "C") {
            slat_type_C();
        }
    }
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("==========================================");
echo("  WAVE OCEAN V10 - VERTICAL SLAT SYSTEM");
echo("==========================================");
echo("");
echo(str("Animation angle: ", theta, "°"));
echo(str("Wave amplitude: ", CAM_RIDGE_HEIGHT, "mm"));
echo("");
echo("SLAT DISTRIBUTION:");
echo("  Type A (Standard): 10 pieces");
echo("  Type B (Foam):     8 pieces");
echo("  Type C (Curl):     6 pieces");
echo("  Total:             24 pieces");
echo("");
echo("PARTS LIST:");
echo("  - Backplate: 1x");
echo("  - Twisted cam: 1x");
echo("  - Slat Type A: 10x");
echo("  - Slat Type B: 8x");
echo("  - Slat Type C: 6x");
echo("  - 608 bearing: 2x");
echo("  - 8mm shaft: 260mm");
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
