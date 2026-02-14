/*
 * GUIDE RAIL FRONT - Front Guide Rail with Slots
 *
 * Printable part: 1x
 * Print orientation: Flat on back
 *
 * Features:
 * - 24 vertical slots for slats to slide in
 * - Slats slide UP/DOWN through slots
 * - Mounting holes for base plate attachment
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN GUIDE RAIL MODULE
// ============================================

module guide_rail_front() {
    difference() {
        union() {
            // Main rail body
            rail_body();

            // Mounting tabs at ends
            mounting_tabs();
        }

        // Slots for slats to slide through
        slat_slots();

        // Mounting holes
        mounting_holes();
    }
}

// ============================================
// RAIL BODY
// ============================================

module rail_body() {
    // Main rail - long in X, thin in Y, tall in Z
    // Rail sits at Y = GUIDE_FRONT_Y, slats pass through in Z direction
    translate([-GUIDE_LENGTH/2, -GUIDE_DEPTH/2, 0])
        cube([GUIDE_LENGTH, GUIDE_DEPTH, GUIDE_HEIGHT]);
}

// ============================================
// MOUNTING TABS
// ============================================

module mounting_tabs() {
    // Tabs at each end that attach to vertical supports
    tab_width = 20;
    tab_depth = 15;
    tab_height = 10;

    for (x_sign = [-1, 1]) {
        translate([x_sign * (GUIDE_LENGTH/2 - tab_width/2), GUIDE_DEPTH/2, 0])
            cube([tab_width, tab_depth, tab_height], center=true);
    }
}

// ============================================
// SLAT SLOTS
// ============================================

module slat_slots() {
    // 24 vertical slots for slats to slide through
    // Slots are in Z direction, slats move up/down

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);

        // Slot through rail (Z direction)
        translate([x, 0, -1])
            cube([SLOT_WIDTH, GUIDE_DEPTH + 2, GUIDE_HEIGHT + 2], center=true);
    }
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    // M3 holes at ends for attachment to vertical supports
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
guide_rail_front();

// ============================================
// INFO
// ============================================

echo("=== GUIDE RAIL FRONT ===");
echo(str("Length: ", GUIDE_LENGTH, "mm"));
echo(str("Height: ", GUIDE_HEIGHT, "mm"));
echo(str("Depth: ", GUIDE_DEPTH, "mm"));
echo(str("Slots: ", NUM_SLATS, " x ", SLOT_WIDTH, "mm wide"));
echo("");
echo("Print quantity: 1");
echo("Print orientation: Flat (lying on side)");
