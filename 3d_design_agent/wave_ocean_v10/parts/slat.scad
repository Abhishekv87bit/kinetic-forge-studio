/*
 * SLAT - Wave Profile Piece
 *
 * Printable part: 24x
 * Print orientation: Flat on back (Y face down)
 *
 * Features:
 * - Wave crest profile at top
 * - Slides directly in guide rail slots
 * - Follower arm pivot mount at bottom
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN SLAT MODULE
// ============================================

module slat() {
    difference() {
        union() {
            // Main body
            slat_body();

            // Pivot mount for follower arm
            pivot_mount();
        }

        // Pivot pin hole
        pivot_hole();
    }
}

// ============================================
// SLAT BODY
// ============================================

module slat_body() {
    // Simple rectangular body that slides in guide rail slots
    // Wave profile at top is decorative

    // Main body
    translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, 0])
        cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT]);

    // Tapered wave crest at top
    hull() {
        // Top of main body
        translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, SLAT_HEIGHT - 1])
            cube([SLAT_WIDTH, SLAT_DEPTH, 1]);

        // Crest peak (narrower, rounded)
        translate([0, 0, SLAT_HEIGHT + 8])
        rotate([90, 0, 0])
        scale([1, 1.5, 1])
            cylinder(d=SLAT_WIDTH, h=SLAT_DEPTH * 0.6, center=true, $fn=16);
    }
}

// ============================================
// PIVOT MOUNT
// ============================================

module pivot_mount() {
    // Boss at bottom of slat for follower arm pivot
    // Pivot axis is along X (allows arm to swing in Y-Z plane)

    pivot_boss_dia = 12;
    pivot_boss_len = PIVOT_PIN_LENGTH + 4;

    // Boss extends in +/- X from slat
    translate([0, 0, -10])
    rotate([0, 90, 0])
        cylinder(d=pivot_boss_dia, h=pivot_boss_len, center=true);
}

// ============================================
// PIVOT HOLE
// ============================================

module pivot_hole() {
    // Through hole for pivot pin (3mm)
    translate([0, 0, -10])
    rotate([0, 90, 0])
        cylinder(d=PIVOT_HOLE, h=30, center=true, $fn=24);
}

// ============================================
// RENDER
// ============================================

color(C_SLAT)
slat();

// ============================================
// INFO
// ============================================

echo("=== SLAT ===");
echo(str("Width: ", SLAT_WIDTH, "mm"));
echo(str("Depth: ", SLAT_DEPTH, "mm"));
echo(str("Height: ", SLAT_HEIGHT, "mm"));
echo("");
echo("Print quantity: 24");
echo("Print orientation: Flat on side");
echo("Assembly: Insert pivot pin, attach follower arm");
