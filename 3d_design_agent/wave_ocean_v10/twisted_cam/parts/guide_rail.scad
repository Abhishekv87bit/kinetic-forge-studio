/*
 * GUIDE RAIL - Minimal Vertical Slot Guide
 *
 * Printable part: 2x (front and back)
 * Print orientation: Flat on side
 *
 * Features:
 * - Very thin profile to minimize visual impact
 * - 24 vertical slots for slats to slide in
 * - Mounting tabs at ends
 * - Designed to be nearly invisible when viewing waves
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN GUIDE RAIL MODULE
// ============================================

module guide_rail() {
    difference() {
        union() {
            // Main rail body
            rail_body();

            // Mounting tabs at ends
            mounting_tabs();
        }

        // Vertical slots for slats
        slat_slots();

        // Mounting screw holes
        mounting_holes();
    }
}

// ============================================
// RAIL BODY
// ============================================

module rail_body() {
    // Very thin bar with rounded edges
    translate([-GUIDE_LENGTH/2, 0, 0])
    hull() {
        translate([0, 0, 0])
            cube([GUIDE_LENGTH, GUIDE_THICKNESS, 1]);
        translate([0, 0, GUIDE_HEIGHT - 1])
            cube([GUIDE_LENGTH, GUIDE_THICKNESS, 1]);
    }
}

// ============================================
// MOUNTING TABS
// ============================================

module mounting_tabs() {
    tab_width = 15;
    tab_depth = 12;
    tab_height = 8;

    for (x_sign = [-1, 1]) {
        translate([x_sign * (GUIDE_LENGTH/2 - tab_width/2), -tab_depth/2, 0])
            cube([tab_width, tab_depth + GUIDE_THICKNESS/2, tab_height], center = true);
    }
}

// ============================================
// SLAT SLOTS
// ============================================

module slat_slots() {
    // Vertical slots that slats slide through
    // Sized for SLAT_WIDTH + tolerance

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);

        // Through slot
        translate([x, -1, GUIDE_HEIGHT/2])
            cube([SLOT_WIDTH, GUIDE_THICKNESS + 2, SLOT_HEIGHT], center = true);
    }
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    // M3 holes in tabs for attachment to uprights

    for (x_sign = [-1, 1]) {
        translate([x_sign * (GUIDE_LENGTH/2 - 7.5), 0, 4])
        rotate([90, 0, 0])
            cylinder(d = M3_HOLE, h = 30, center = true, $fn = 16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_GUIDE)
guide_rail();

// ============================================
// INFO
// ============================================

echo("=== GUIDE RAIL ===");
echo(str("Length: ", GUIDE_LENGTH, "mm"));
echo(str("Height: ", GUIDE_HEIGHT, "mm"));
echo(str("Thickness: ", GUIDE_THICKNESS, "mm (minimal!)"));
echo(str("Slots: ", NUM_SLATS, " x ", SLOT_WIDTH, "mm"));
echo("");
echo("Print: 2x (front and back)");
echo("Orientation: Flat on side");
echo("Material: PLA or PETG");
