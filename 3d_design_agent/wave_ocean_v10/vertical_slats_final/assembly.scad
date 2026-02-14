/*
 * WAVE OCEAN V10 - 3-LAYER FULL ASSEMBLY
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * COORDINATE SYSTEM:
 * - X: Left-Right (cam axis direction)
 * - Y: Front-Back (viewer at -Y)
 * - Z: Up-Down (gravity -Z)
 *
 * 3-LAYER SYSTEM:
 * - Layer 0 (front): Y = -30mm, tallest slats, dark blue
 * - Layer 1 (mid):   Y = 0mm, medium slats, medium blue
 * - Layer 2 (back):  Y = +30mm, shortest slats, light blue
 *
 * GUIDANCE: Snap-fit base grooves (no backplate needed)
 * - Each slat has snap wings at bottom
 * - Base plate has T-slot grooves for each layer
 * - Clean look - no visible rails or guides
 *
 * Each layer has its own cam section with phase offset.
 */

include <common.scad>
use <parts/slat.scad>
use <parts/cam.scad>
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

// Layer toggles (for debugging individual layers)
SHOW_LAYER_0 = true;           // Front layer
SHOW_LAYER_1 = true;           // Mid layer
SHOW_LAYER_2 = true;           // Back layer
SHOW_LAYERS = [SHOW_LAYER_0, SHOW_LAYER_1, SHOW_LAYER_2];

// Debug views
SHOW_BEARINGS = true;          // Ghost 608 bearings
SHOW_CAM_CONTACT = false;      // Show where slats contact cam

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;              // Set 0-360 for static pose, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== BASE PLATE (Z = 0) ==========
    if (SHOW_BASE) {
        color(C_BASE)
        translate([0, 0, 0])
            base_plate();
    }

    // NOTE: No backplate or guides needed
    // Slats self-align via overlap + cam contact + end caps

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

    // ========== CAM (3-section) ==========
    if (SHOW_CAM) {
        color(C_CAM)
        translate([0, 0, CAM_CENTER_Z])
        rotate([theta, 0, 0])  // Rotates around X axis
            cam();
    }

    // ========== 3-LAYER SLATS ==========
    if (SHOW_SLATS) {
        for (L = [0 : NUM_LAYERS - 1]) {
            if (SHOW_LAYERS[L]) {
                layer_slats(L);
            }
        }
    }

    // ========== 608 BEARINGS (ghost) ==========
    if (SHOW_BEARINGS) {
        // Left bearing
        %translate([BB_LEFT_X + BB_WIDTH/2 - BEARING_POCKET_DEPTH/2, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
        difference() {
            cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
            cylinder(d = BEARING_608_ID, h = BEARING_608_H + 1, center = true);
        }

        // Right bearing
        %translate([BB_RIGHT_X - BB_WIDTH/2 + BEARING_POCKET_DEPTH/2, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
        difference() {
            cylinder(d = BEARING_608_OD, h = BEARING_608_H, center = true);
            cylinder(d = BEARING_608_ID, h = BEARING_608_H + 1, center = true);
        }
    }
}

// ============================================
// LAYER SLATS - Render all slats for one layer
// ============================================

module layer_slats(L) {
    y = layer_slat_y(L);
    col = layer_slat_color(L);

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

assembly();

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("================================================");
echo("  WAVE OCEAN V10 - 3-LAYER ASSEMBLY");
echo("================================================");
echo("");
echo(str("Animation theta: ", theta, "°"));
echo("");
echo("LAYERS:");
for (L = [0 : NUM_LAYERS - 1]) {
    echo(str("  Layer ", L, ": Y=", LAYER_Y_OFFSET[L], "mm, scale=", LAYER_HEIGHT_SCALE[L], ", phase=+", LAYER_PHASE_OFFSET[L], "°"));
}
echo("");
echo("COMPONENTS:");
echo(str("  Layers: ", NUM_LAYERS));
echo(str("  Slats per layer: ", NUM_SLATS));
echo(str("  Total slats: ", NUM_LAYERS * NUM_SLATS));
echo("");
echo("CAM:");
echo(str("  Center Z: ", CAM_CENTER_Z, "mm"));
echo(str("  Max radius: ", CAM_MAX_RADIUS, "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
