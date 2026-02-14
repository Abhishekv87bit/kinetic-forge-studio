/*
 * GUIDE RAIL BACK - Back Guide Rail with Slots
 *
 * Printable part: 1x
 * Print orientation: Flat on back
 *
 * Features:
 * - 24 vertical slots for slats to slide in
 * - Mirror of front rail
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN GUIDE RAIL MODULE
// ============================================

module guide_rail_back() {
    // Same as front rail
    difference() {
        union() {
            rail_body();
            mounting_tabs();
        }

        slat_slots();
        mounting_holes();
    }
}

module rail_body() {
    translate([-GUIDE_LENGTH/2, -GUIDE_DEPTH/2, 0])
        cube([GUIDE_LENGTH, GUIDE_DEPTH, GUIDE_HEIGHT]);
}

module mounting_tabs() {
    tab_width = 20;
    tab_depth = 15;
    tab_height = 10;

    for (x_sign = [-1, 1]) {
        translate([x_sign * (GUIDE_LENGTH/2 - tab_width/2), -GUIDE_DEPTH/2 - tab_depth/2, 0])
            cube([tab_width, tab_depth, tab_height], center=true);
    }
}

module slat_slots() {
    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);
        translate([x, 0, -1])
            cube([SLOT_WIDTH, GUIDE_DEPTH + 2, GUIDE_HEIGHT + 2], center=true);
    }
}

module mounting_holes() {
    for (x_sign = [-1, 1]) {
        translate([x_sign * (GUIDE_LENGTH/2 - 10), 0, GUIDE_HEIGHT/2])
        rotate([90, 0, 0])
            cylinder(d=M3_HOLE_DIA, h=GUIDE_DEPTH + 20, center=true, $fn=16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_GUIDE)
guide_rail_back();

echo("=== GUIDE RAIL BACK ===");
echo("Same as FRONT rail");
echo("Print quantity: 1");
