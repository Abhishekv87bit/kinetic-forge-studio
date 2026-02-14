/*
 * SLAT.SCAD - Simple Wave Slat
 *
 * Whack-a-mole design: NO followers, NO wires, NO hinges!
 * Just a simple rectangular slat that:
 * - Slides through floor slit
 * - Bottom rests on cam surface
 * - Gravity keeps contact with cam
 *
 * The slit provides all guidance - no additional mechanisms needed.
 */

include <../common.scad>

$fn = 24;

// ============================================
// SIMPLE SLAT MODULE
// ============================================

module slat(height = SLAT_TOTAL_HEIGHT, layer = 0) {
    // Simple rectangular slat
    // Visible portion above floor + hidden portion below

    union() {
        // Main slat body
        slat_body(height);

        // Rounded bottom for smooth cam contact
        slat_bottom();
    }
}

// ============================================
// SLAT BODY
// ============================================

module slat_body(height) {
    // Rectangular body
    cube([SLAT_THICKNESS, SLAT_DEPTH, height], center = true);
}

// ============================================
// SLAT BOTTOM - Rounded for cam contact
// ============================================

module slat_bottom() {
    // Rounded bottom edge for smooth sliding on cam
    translate([0, 0, -SLAT_TOTAL_HEIGHT/2])
    rotate([0, 90, 0])
    hull() {
        // Rounded edge
        translate([0, 0, -SLAT_THICKNESS/4])
            cylinder(d = SLAT_DEPTH * 0.8, h = SLAT_THICKNESS/2, center = true);
        translate([3, 0, -SLAT_THICKNESS/4])
            cylinder(d = SLAT_DEPTH * 0.8, h = SLAT_THICKNESS/2, center = true);
    }
}

// ============================================
// SLAT WITH VARIABLE HEIGHT
// ============================================

module wave_slat(i, layer = 0) {
    // Slat with height that varies for visual interest
    h = slat_height(i);
    slat(h, layer);
}

// ============================================
// SLAT ROW (one layer)
// ============================================

module slat_row(layer = 0) {
    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i, layer);
        y = LAYER_Y_CENTER[layer];
        h = slat_height(i);

        translate([x, y, FLOOR_Z + h/2 - SLAT_BELOW_FLOOR])
        color(slat_color(layer))
            slat(h, layer);
    }
}

// ============================================
// RENDER - Show all 3 layers of slats
// ============================================

for (layer = [0 : NUM_LAYERS - 1]) {
    slat_row(layer);
}

// Show floor level reference
%translate([0, 10, FLOOR_Z])
    cube([CAM_LENGTH, 1, 0.5], center = true);

// ============================================
// INFO
// ============================================

echo("=== SIMPLE WAVE SLATS ===");
echo(str("Dimensions: ", SLAT_THICKNESS, " x ", SLAT_DEPTH, " x ", SLAT_TOTAL_HEIGHT, "mm"));
echo(str("Visible above floor: ", SLAT_VISIBLE_HEIGHT, "mm"));
echo(str("Below floor (contacts cam): ", SLAT_BELOW_FLOOR, "mm"));
echo(str("Count: ", NUM_SLATS, " per layer x ", NUM_LAYERS, " layers"));
echo("");
echo("DESIGN: Simple rectangular slat");
echo("  - Slides through floor slit");
echo("  - Bottom rests on cam surface");
echo("  - Gravity maintains cam contact");
echo("  - Slit provides X/Y guidance");
