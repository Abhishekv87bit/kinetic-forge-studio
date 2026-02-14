/*
 * WAVE OCEAN V10 - VERTICAL SLAT ASSEMBLY (V2)
 * TRAVELING WAVE VERSION
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * FEATURES:
 * - 36 thin slats (2.5mm) tightly packed
 * - 2 cam ridges = 2 traveling waves
 * - TRUE traveling wave motion (not synchronized bobbing)
 * - Adjacent slats at different phases
 * - Clean front view (no guide rails)
 *
 * PHYSICS:
 * - 2 ridges over 180mm = each ridge spans 90mm
 * - 36 slats = 18 slats per wave cycle
 * - Adjacent slats are 20° apart in phase
 * - Wave travels from left to right as cam rotates
 *
 * NOTE: This is SINGLE LAYER only.
 * For 3-layer system, use vertical_slats_final/assembly_option_b.scad
 */

include <common.scad>
use <parts/slat.scad>
use <parts/cam.scad>
use <parts/backplate.scad>
use <parts/bearing_block.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_SLATS = true;
SHOW_CAM = true;
SHOW_SHAFT = true;
SHOW_BACKPLATE = true;
SHOW_BEARING_BLOCKS = true;
SHOW_BEARINGS = true;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;            // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== BACKPLATE ==========
    if (SHOW_BACKPLATE) {
        translate([0, BACKPLATE_Y, BACKPLATE_Z])
        color(C_BACKPLATE)
            backplate();
    }

    // ========== BEARING BLOCKS ==========
    if (SHOW_BEARING_BLOCKS) {
        // Left block
        translate([BB_LEFT_X, 0, 0])
        rotate([0, 0, 180])
        color(C_BB)
            bearing_block();

        // Right block
        translate([BB_RIGHT_X, 0, 0])
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

    // ========== CAM ==========
    if (SHOW_CAM) {
        translate([0, 0, CAM_CENTER_Z])
        rotate([theta, 0, 0])
        color(C_CAM)
            cam();
    }

    // ========== SLATS (SINGLE LAYER) ==========
    if (SHOW_SLATS) {
        for (i = [0 : NUM_SLATS - 1]) {
            slat_at_position(i);
        }
    }

    // ========== BEARINGS ==========
    if (SHOW_BEARINGS) {
        // Left
        %translate([BB_LEFT_X + BB_WIDTH/2 - BEARING_POCKET_DEPTH/2, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);

        // Right
        %translate([BB_RIGHT_X - BB_WIDTH/2 + BEARING_POCKET_DEPTH/2, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
    }
}

// ============================================
// SLAT POSITIONING
// ============================================

module slat_at_position(i) {
    x = slat_x(i);
    z = slat_z(i, theta);
    h = slat_height(i);

    translate([x, 0, z])
    color(slat_color(i))
        slat(h);
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("============================================");
echo("  WAVE OCEAN V10 - TRAVELING WAVE SYSTEM");
echo("============================================");
echo("");
echo(str("Animation: theta = ", theta, "°"));
echo("");
echo("CONFIGURATION:");
echo(str("  Slats: ", NUM_SLATS));
echo(str("  Slat thickness: ", SLAT_THICKNESS, "mm"));
echo(str("  Slat spacing: ", SLAT_SPACING, "mm"));
echo(str("  Cam ridges: ", NUM_RIDGES));
echo(str("  Slats per wave: ", NUM_SLATS / NUM_RIDGES));
echo(str("  Phase per slat: ", 360 * HELIX_TURNS / NUM_SLATS, "°"));
echo("");
echo("WAVE MOTION:");
echo("  As cam rotates, waves travel LEFT to RIGHT");
echo("  Adjacent slats are at slightly different phases");
echo("  This creates smooth flowing wave motion");
echo("");
echo("NOTE: This is SINGLE LAYER only.");
echo("For 3-layer system, use vertical_slats_final/assembly_option_b.scad");
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
