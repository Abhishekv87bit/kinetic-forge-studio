/*
 * SLAT - Thin Wave Element with Cam Follower
 *
 * GEOMETRY:
 * - Main body: Thin wave shape (symmetric, centered on Y)
 * - Follower: Pad at bottom that rides ON TOP of cam
 * - NO guidance tabs - slats self-align through:
 *   - Overlap with adjacent layers
 *   - Cam contact (gravity holds them down)
 *   - Cam end caps (prevent X drift)
 *
 * ORIENTATION (looking from front, -Y toward +Y):
 * - Slat body centered at Y = 0
 * - Follower extends DOWN from slat bottom (contacts cam top)
 *
 * Print: 36x per layer (108 total for 3 layers)
 * Orientation: Upright
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN SLAT MODULE
// ============================================

module slat(height = SLAT_BASE_HEIGHT) {
    union() {
        // Main visible wave body
        wave_body(height);

        // Cam follower (bottom, rides on cam)
        cam_follower();
    }
}

// ============================================
// WAVE BODY - Thin symmetric profile
// ============================================

module wave_body(height) {
    // Thin symmetric wave shape - allows layer overlap
    hull() {
        // Base (Z = 0 is bottom of visible slat) - full depth, centered
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 1]);

        // Lower body - maintains depth
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, height * 0.4])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 1]);

        // Middle taper - 80% depth, CENTERED
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH * 0.4, height * 0.65])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.8, 1]);

        // Upper taper - 50% depth, CENTERED
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH * 0.25, height * 0.85])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.5, 1]);

        // Crest (rounded dome top) - centered
        translate([0, 0, height])
        scale([1, 0.3, 0.4])
        rotate([0, 90, 0])
            cylinder(d = 6, h = SLAT_THICKNESS, center = true, $fn = 16);
    }
}

// ============================================
// CAM FOLLOWER - Rides on top of cam
// ============================================

module cam_follower() {
    // Follower pad extends DOWN from slat bottom
    // It contacts the TOP surface of the rotating cam

    // Follower centered in Y to contact cam at slat's Y position
    translate([-FOLLOWER_WIDTH/2, -FOLLOWER_LENGTH/2, -FOLLOWER_HEIGHT])
        cube([FOLLOWER_WIDTH, FOLLOWER_LENGTH, FOLLOWER_HEIGHT]);

    // Rounded bottom edge for smooth cam contact
    translate([0, 0, -FOLLOWER_HEIGHT])
    rotate([0, 90, 0])
    scale([1, FOLLOWER_LENGTH/FOLLOWER_HEIGHT, 1])
        cylinder(d = FOLLOWER_HEIGHT, h = FOLLOWER_WIDTH, center = true, $fn = 16);
}

// ============================================
// SLAT FOR SPECIFIC INDEX
// ============================================

module slat_i(i) {
    slat(slat_height(i));
}

// ============================================
// RENDER - Display sample slats showing height variation
// ============================================

// Show slats with golden ratio heights
echo("=== SAMPLE SLAT HEIGHTS (Golden Ratio) ===");
for (i = [0 : 7]) {
    h = slat_height(i * 4);
    echo(str("  Slat ", i*4, ": height = ", h, "mm"));

    translate([i * 15, 0, 0])
    color(slat_color(i * 4))
        slat(h);
}

// ============================================
// VERIFICATION
// ============================================

echo("");
echo("=== SLAT VERIFICATION ===");
echo(str("Body: ", SLAT_THICKNESS, " x ", SLAT_DEPTH, " x ", SLAT_BASE_HEIGHT, "-", SLAT_BASE_HEIGHT + SLAT_HEIGHT_VAR, "mm"));
echo(str("Follower: ", FOLLOWER_WIDTH, " x ", FOLLOWER_LENGTH, " x ", FOLLOWER_HEIGHT, "mm"));
echo("");
echo("GUIDANCE: Self-aligning (no mechanical guides)");
echo("  - Layer overlap constrains Y");
echo("  - Cam contact + gravity constrains Z");
echo("  - Cam end caps constrain X");
