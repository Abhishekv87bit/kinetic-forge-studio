/*
 * SLAT TYPE B - Foam Crest
 *
 * Quantity: 8x
 * Height: 55mm (taller than A)
 * Character: Irregular foam fingers, more dramatic white area
 * Use: Accent pieces, adds texture variety
 *
 * Profile:
 *       ∿╭─╮∿
 *       ╱    ╲
 *      ╱      ╲
 *     │        │
 *     │   ▯    │ ← Back tab
 *     ╰────────╯ ← Curved cam follower
 */

include <common.scad>

$fn = 48;

// ============================================
// MAIN MODULE
// ============================================

module slat_type_B() {
    union() {
        // Main wave body (blue)
        color(C_SLAT_B)
        wave_body_B();

        // Foam crest (white) - separate for color
        color(C_FOAM)
        foam_crest_B();

        // Back tab
        color(C_SLAT_B)
        back_tab_B();

        // Cam follower
        color(C_SLAT_B)
        cam_follower_B();
    }
}

// ============================================
// WAVE BODY - Taller, ends before foam
// ============================================

module wave_body_B() {
    height = SLAT_B_HEIGHT;
    foam_start = height - 12;  // Foam takes top 12mm

    // Main body
    hull() {
        // Base
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, foam_start - 10]);

        // Shoulder before foam
        translate([0, 0, foam_start])
        scale([1, 0.7, 0.5])
        rotate([90, 0, 0])
            cylinder(d = SLAT_THICKNESS + 4, h = SLAT_DEPTH * 0.7, center = true, $fn = 24);
    }
}

// ============================================
// FOAM CREST - Irregular fingers
// ============================================

module foam_crest_B() {
    height = SLAT_B_HEIGHT;
    foam_base = height - 12;

    // Central dome
    translate([0, 0, foam_base])
    hull() {
        cylinder(d = SLAT_THICKNESS + 2, h = 1, $fn = 24);
        translate([0, 0, 10])
        scale([1, 0.5, 1])
            sphere(d = SLAT_THICKNESS, $fn = 24);
    }

    // Foam fingers - irregular protrusions
    // Left finger
    translate([-2, -4, foam_base + 5])
    rotate([15, 20, 0])
    scale([0.6, 0.8, 1.5])
        sphere(d = 6, $fn = 16);

    // Right finger
    translate([1, 3, foam_base + 7])
    rotate([-10, -15, 0])
    scale([0.7, 0.9, 1.3])
        sphere(d = 5, $fn = 16);

    // Top splash
    translate([0, -2, height])
    scale([0.8, 0.6, 1.2])
        sphere(d = 5, $fn = 16);

    // Back drip
    translate([0, 5, foam_base + 3])
    scale([0.5, 1, 0.8])
        sphere(d = 4, $fn = 12);
}

// ============================================
// BACK TAB
// ============================================

module back_tab_B() {
    tab_start_z = -TAB_HEIGHT_EXTENSION;
    tab_end_z = SLAT_B_HEIGHT - 15;
    tab_total_height = tab_end_z - tab_start_z;

    translate([-TAB_WIDTH/2, SLAT_DEPTH/2 - 2, tab_start_z])
        cube([TAB_WIDTH, TAB_DEPTH, tab_total_height]);
}

// ============================================
// CAM FOLLOWER
// ============================================

module cam_follower_B() {
    follower_height = 8;

    translate([0, 0, -follower_height])
    difference() {
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, follower_height + 1]);

        translate([0, 0, -FOLLOWER_CURVE_RADIUS + follower_height - 1])
        rotate([90, 0, 0])
            cylinder(r = FOLLOWER_CURVE_RADIUS, h = SLAT_DEPTH + 2, center = true, $fn = 64);
    }
}

// ============================================
// RENDER
// ============================================

slat_type_B();

// Reference
%translate([0, 0, -FOLLOWER_CURVE_RADIUS - 8])
rotate([90, 0, 0])
    cylinder(r = CAM_CORE_RADIUS, h = SLAT_DEPTH + 20, center = true, $fn = 32);

echo("=== SLAT TYPE B: Foam Crest ===");
echo(str("Height: ", SLAT_B_HEIGHT, "mm"));
echo("Print quantity: 8");
echo("Note: Foam detail may need supports");
