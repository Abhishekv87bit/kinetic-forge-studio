/*
 * CHANNEL GUIDE - Comb-Style Lateral Constraint
 *
 * DESIGN:
 * - U-channel comb structure for each layer
 * - Slats slide vertically within channels
 * - Prevents X/Y drift while allowing Z motion
 * - Works with fish wire suspension
 *
 * Each layer has its own guide comb positioned at its Y location.
 * Channels are spaced to match slat X positions with layer offset.
 *
 * Print: 3x (one per layer)
 */

include <../common.scad>

$fn = 24;

// ============================================
// MAIN CHANNEL GUIDE MODULE
// ============================================

module channel_guide(layer = 0) {
    difference() {
        // Main comb body
        comb_body(layer);

        // Cut channels for slats
        slat_channels(layer);
    }
}

// ============================================
// COMB BODY
// ============================================

module comb_body(layer) {
    // Solid block that will have channels cut from it

    // Calculate total width needed
    first_slat_x = slat_x(0, layer);
    last_slat_x = slat_x(NUM_SLATS - 1, layer);

    body_length = last_slat_x - first_slat_x + CHANNEL_WIDTH + CHANNEL_WALL * 4;
    body_center_x = (first_slat_x + last_slat_x) / 2;

    translate([body_center_x, 0, CHANNEL_HEIGHT/2])
        cube([body_length, CHANNEL_DEPTH * 2 + CHANNEL_WALL, CHANNEL_HEIGHT], center = true);
}

// ============================================
// SLAT CHANNELS (cut from comb body)
// ============================================

module slat_channels(layer) {
    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i, layer);

        // U-channel cut-out
        translate([x, 0, CHANNEL_HEIGHT/2])
            cube([CHANNEL_WIDTH, CHANNEL_DEPTH * 2, CHANNEL_HEIGHT + 1], center = true);
    }
}

// ============================================
// SINGLE U-CHANNEL (for visualization)
// ============================================

module single_channel() {
    difference() {
        // Channel walls
        cube([CHANNEL_WIDTH + CHANNEL_WALL * 2, CHANNEL_DEPTH * 2 + CHANNEL_WALL, CHANNEL_HEIGHT], center = true);

        // Channel opening
        translate([0, CHANNEL_WALL/2, 0])
            cube([CHANNEL_WIDTH, CHANNEL_DEPTH * 2, CHANNEL_HEIGHT + 1], center = true);
    }
}

// ============================================
// MOUNTING TABS
// ============================================

module guide_with_mounting(layer = 0) {
    union() {
        channel_guide(layer);

        // Mounting tabs at ends
        first_x = slat_x(0, layer);
        last_x = slat_x(NUM_SLATS - 1, layer);

        for (x = [first_x - 15, last_x + 15]) {
            translate([x, 0, CHANNEL_HEIGHT/2])
            difference() {
                cube([10, CHANNEL_DEPTH * 2 + CHANNEL_WALL + 10, 8], center = true);

                // Mounting hole
                cylinder(d = M4_HOLE, h = 10, center = true);
            }
        }
    }
}

// ============================================
// RENDER - Show all 3 guides at layer positions
// ============================================

for (L = [0 : NUM_LAYERS - 1]) {
    translate([0, LAYER_Y_CENTER[L], 50])
    color(C_GUIDE)
        channel_guide(L);
}

// Show sample slats in channels (transparent)
for (L = [0 : NUM_LAYERS - 1]) {
    for (i = [0, 5, 10, 15, 19]) {
        x = slat_x(i, L);
        z_base = 50 + 5;  // Guide Z + some offset

        %translate([x, LAYER_Y_CENTER[L], z_base])
        color(slat_color(L))
            cube([SLAT_THICKNESS, SLAT_DEPTH, 30], center = true);
    }
}

// ============================================
// INFO
// ============================================

echo("=== CHANNEL GUIDE ===");
echo(str("Channel width: ", CHANNEL_WIDTH, "mm (slat ", SLAT_THICKNESS, "mm + ", CHANNEL_WIDTH - SLAT_THICKNESS, "mm clearance)"));
echo(str("Channel depth: ", CHANNEL_DEPTH, "mm"));
echo(str("Channel height: ", CHANNEL_HEIGHT, "mm"));
echo(str("Channels per guide: ", NUM_SLATS));
echo("");
echo("LAYER POSITIONS:");
echo(str("  Layer 0 guide: Y=", LAYER_Y_CENTER[0], "mm"));
echo(str("  Layer 1 guide: Y=", LAYER_Y_CENTER[1], "mm"));
echo(str("  Layer 2 guide: Y=", LAYER_Y_CENTER[2], "mm"));
echo("");
echo("Print: 3x (one per layer)");
