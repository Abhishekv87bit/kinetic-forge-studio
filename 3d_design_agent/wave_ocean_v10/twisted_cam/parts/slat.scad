/*
 * SLAT - Wave Piece with Cam Follower Bottom
 *
 * Printable part: 24x
 * Print orientation: Upright (Z up)
 *
 * Features:
 * - Wave crest profile at top (decorative)
 * - Curved bottom to ride on cam surface
 * - Smooth surface for quiet cam contact
 * - Rectangular body slides in guide slots
 */

include <../common.scad>

$fn = 48;

// ============================================
// MAIN SLAT MODULE
// ============================================

module slat() {
    union() {
        // Main body
        slat_body();

        // Wave crest top
        wave_crest();

        // Cam follower bottom
        cam_follower();
    }
}

// ============================================
// SLAT BODY
// ============================================

module slat_body() {
    // Rectangular body that slides in guide rail slots
    translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, 0])
        cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT - 10]);
}

// ============================================
// WAVE CREST TOP
// ============================================

module wave_crest() {
    // Tapered, rounded top for wave visual
    hull() {
        // Top of main body
        translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, SLAT_HEIGHT - 12])
            cube([SLAT_WIDTH, SLAT_DEPTH, 2]);

        // Crest peak - rounded ellipse
        translate([0, 0, SLAT_HEIGHT])
        scale([1, 0.5, 1.8])
            sphere(d = SLAT_WIDTH, $fn = 24);
    }
}

// ============================================
// CAM FOLLOWER BOTTOM
// ============================================

module cam_follower() {
    // Curved bottom that rides on cam surface
    // Concave curve matches cam core radius + clearance

    follower_height = 8;
    curve_radius = SLAT_CURVE_RADIUS;

    translate([0, 0, -follower_height])
    difference() {
        // Solid base block
        translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_WIDTH, SLAT_DEPTH, follower_height + 1]);

        // Concave curve (cut out)
        translate([0, 0, -curve_radius + follower_height - 1])
        rotate([90, 0, 0])
            cylinder(r = curve_radius, h = SLAT_DEPTH + 2, center = true, $fn = 64);
    }
}

// ============================================
// SLAT WITH WEAR PAD (Optional upgrade)
// ============================================

module slat_with_pad() {
    // Version with replaceable wear pad at bottom
    // For quieter operation or if using harder cam material

    difference() {
        slat();

        // Pocket for wear pad (felt or PTFE)
        translate([0, 0, -6])
        translate([-SLAT_WIDTH/2 + 1, -SLAT_DEPTH/2 + 2, 0])
            cube([SLAT_WIDTH - 2, SLAT_DEPTH - 4, 3]);
    }
}

// ============================================
// RENDER
// ============================================

color(C_SLAT)
slat();

// Show cam surface for reference
%translate([0, 0, -SLAT_CURVE_RADIUS - 5])
rotate([90, 0, 0])
    cylinder(r = CAM_CORE_RADIUS, h = SLAT_DEPTH + 10, center = true);

// ============================================
// INFO
// ============================================

echo("=== SLAT ===");
echo(str("Width: ", SLAT_WIDTH, "mm"));
echo(str("Depth: ", SLAT_DEPTH, "mm"));
echo(str("Height: ", SLAT_HEIGHT, "mm"));
echo(str("Follower curve radius: ", SLAT_CURVE_RADIUS, "mm"));
echo("");
echo("Print: 24x");
echo("Orientation: Upright (Z up)");
echo("Material: PLA (or PETG for durability)");
echo("Tip: Sand bottom curve smooth for quiet operation");
