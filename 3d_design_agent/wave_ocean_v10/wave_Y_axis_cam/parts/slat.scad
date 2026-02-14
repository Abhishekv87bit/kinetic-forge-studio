/*
 * SLAT - Vertical Wave Element with Bottom Follower
 *
 * DESIGN:
 * - Thin vertical body
 * - Follower pad at bottom contacts cam surface
 * - Variable heights for organic wave look
 *
 * PRINT:
 * - Orientation: Upright
 * - Quantity: 36 per layer × 3 layers = 108 total
 */

include <../common.scad>

// ============================================
// SLAT MODULE
// ============================================

module slat(height = SLAT_BASE_HEIGHT) {
    union() {
        // Main wave body
        wave_body(height);

        // Cam follower at bottom
        cam_follower();
    }
}

// ============================================
// WAVE BODY
// ============================================

module wave_body(height) {
    // Tapered wave shape

    hull() {
        // Base - full size
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 1]);

        // Mid section
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, height * 0.6])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.9, 1]);

        // Upper taper
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH * 0.3, height * 0.85])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.6, 1]);

        // Rounded crest
        translate([0, 0, height])
        scale([1, 0.3, 0.5])
        rotate([0, 90, 0])
            cylinder(d = 6, h = SLAT_THICKNESS, center = true, $fn = 16);
    }
}

// ============================================
// CAM FOLLOWER
// ============================================

module cam_follower() {
    // Simple pad at bottom that rides on cam surface

    translate([0, 0, -FOLLOWER_HEIGHT])
    hull() {
        // Top of follower (connects to slat body)
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, FOLLOWER_HEIGHT - 0.5])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 0.5]);

        // Bottom of follower (contacts cam) - slightly rounded
        translate([0, 0, 0])
        scale([SLAT_THICKNESS/2, SLAT_DEPTH/2, 1])
            cylinder(r = 1, h = 0.5, $fn = 16);
    }
}

// ============================================
// RENDER - Sample slats showing height variation
// ============================================

for (i = [0 : 5]) {
    h = slat_height(i * 6);

    translate([i * 15, 0, 0])
    color(LAYER_COLORS[1])
        slat(h);
}

// ============================================
// INFO
// ============================================

echo("=== SLAT ===");
echo(str("Thickness (X): ", SLAT_THICKNESS, "mm"));
echo(str("Depth (Y): ", SLAT_DEPTH, "mm"));
echo(str("Height range: ", SLAT_BASE_HEIGHT, " - ", SLAT_BASE_HEIGHT + SLAT_HEIGHT_VAR, "mm"));
echo(str("Follower height: ", FOLLOWER_HEIGHT, "mm"));
echo("");
echo(str("Total slats: ", NUM_SLATS * NUM_LAYERS));
