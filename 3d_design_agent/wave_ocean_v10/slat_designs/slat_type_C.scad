/*
 * SLAT TYPE C - Breaking Curl
 *
 * Quantity: 6x
 * Height: 60mm (TALLEST)
 * Character: Asymmetric, curling forward like Hokusai wave
 * Use: Drama pieces at wave peaks
 *
 * Profile:
 *          ╭╮
 *         ╱╱ ╲    ← Curl overhang (forward lean)
 *        ╱╱   ╲
 *       ││     ╲
 *      ╱ │      │
 *     │  │      │
 *     │  ▯      │ ← Back tab
 *     ╰──────────╯ ← Curved cam follower
 */

include <common.scad>

$fn = 48;

// ============================================
// MAIN MODULE
// ============================================

module slat_type_C() {
    union() {
        // Main wave body (dark blue)
        color(C_SLAT_C)
        wave_body_C();

        // Curling lip (lighter blue)
        color(C_SLAT_B)
        curl_lip();

        // Foam spray (white)
        color(C_FOAM)
        foam_spray_C();

        // Back tab
        color(C_SLAT_C)
        back_tab_C();

        // Cam follower
        color(C_SLAT_C)
        cam_follower_C();
    }
}

// ============================================
// WAVE BODY - Asymmetric, curving forward
// ============================================

module wave_body_C() {
    height = SLAT_C_HEIGHT;

    // Main mass - leans forward
    hull() {
        // Base (centered)
        translate([-SLAT_THICKNESS/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH, 15]);

        // Mid section (starts leaning forward)
        translate([-SLAT_THICKNESS/2 - 1, -SLAT_DEPTH/2, 30])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.8, 5]);

        // Upper shoulder (more forward lean)
        translate([-SLAT_THICKNESS/2 - 3, -SLAT_DEPTH/2, height - 20])
        rotate([0, 10, 0])
            cube([SLAT_THICKNESS, SLAT_DEPTH * 0.6, 5]);
    }

    // Back slope (fills gap from lean)
    hull() {
        translate([-SLAT_THICKNESS/2, SLAT_DEPTH/4, 15])
            cube([SLAT_THICKNESS, SLAT_DEPTH/4, 1]);

        translate([-SLAT_THICKNESS/2, SLAT_DEPTH/3, height - 25])
            cube([SLAT_THICKNESS - 2, SLAT_DEPTH/6, 1]);
    }
}

// ============================================
// CURLING LIP - The breaking part
// ============================================

module curl_lip() {
    height = SLAT_C_HEIGHT;

    // Curl that goes forward and down
    translate([-5, 0, height - 15])
    rotate([0, 25, 0])  // Lean forward
    hull() {
        // Base of curl
        cylinder(d = SLAT_THICKNESS + 2, h = 3, $fn = 24);

        // Curl tip (forward and slightly down)
        translate([-8, 0, 12])
        rotate([0, 45, 0])
        scale([1.5, 0.6, 0.8])
            sphere(d = 6, $fn = 24);
    }

    // Inner curl detail
    translate([-8, 0, height - 8])
    rotate([0, 50, 0])
    scale([1, 0.5, 0.6])
        sphere(d = 8, $fn = 20);
}

// ============================================
// FOAM SPRAY - Dramatic splash
// ============================================

module foam_spray_C() {
    height = SLAT_C_HEIGHT;

    // Main foam on curl tip
    translate([-12, 0, height])
    scale([1.2, 0.8, 1])
        sphere(d = 6, $fn = 20);

    // Spray fingers
    for (i = [0:4]) {
        angle = -30 + i * 15;
        len = 4 + (i % 2) * 2;

        translate([-10, 0, height - 2])
        rotate([angle, 20 + i * 5, i * 20])
        translate([0, 0, len])
        scale([0.4, 0.5, 1.2])
            sphere(d = 3, $fn = 12);
    }

    // Back splash
    translate([-3, -6, height + 3])
    scale([0.6, 0.8, 1.5])
        sphere(d = 4, $fn = 12);

    translate([-2, 5, height + 2])
    scale([0.7, 0.7, 1.3])
        sphere(d = 3, $fn = 12);
}

// ============================================
// BACK TAB - Longer for stability
// ============================================

module back_tab_C() {
    // C type needs more support due to forward lean
    tab_start_z = -TAB_HEIGHT_EXTENSION - 5;  // Extra length
    tab_end_z = SLAT_C_HEIGHT - 20;
    tab_total_height = tab_end_z - tab_start_z;

    // Main tab
    translate([-TAB_WIDTH/2, SLAT_DEPTH/2 - 2, tab_start_z])
        cube([TAB_WIDTH, TAB_DEPTH, tab_total_height]);

    // Extra stabilizer tab (prevent rotation from curl weight)
    translate([-TAB_WIDTH/2 - 3, SLAT_DEPTH/2 - 2, tab_start_z])
        cube([TAB_WIDTH, TAB_DEPTH - 5, 30]);
}

// ============================================
// CAM FOLLOWER - Wider base for stability
// ============================================

module cam_follower_C() {
    follower_height = 10;  // Taller for stability

    translate([0, 0, -follower_height])
    difference() {
        // Wider base
        hull() {
            translate([-SLAT_THICKNESS/2 - 2, -SLAT_DEPTH/2, 0])
                cube([SLAT_THICKNESS + 4, SLAT_DEPTH, follower_height + 1]);
        }

        // Concave curve
        translate([0, 0, -FOLLOWER_CURVE_RADIUS + follower_height - 1])
        rotate([90, 0, 0])
            cylinder(r = FOLLOWER_CURVE_RADIUS, h = SLAT_DEPTH + 2, center = true, $fn = 64);
    }
}

// ============================================
// RENDER
// ============================================

slat_type_C();

// Reference
%translate([0, 0, -FOLLOWER_CURVE_RADIUS - 10])
rotate([90, 0, 0])
    cylinder(r = CAM_CORE_RADIUS, h = SLAT_DEPTH + 20, center = true, $fn = 32);

echo("=== SLAT TYPE C: Breaking Curl ===");
echo(str("Height: ", SLAT_C_HEIGHT, "mm (TALLEST)"));
echo("Print quantity: 6");
echo("Note: Print with supports for curl overhang");
echo("Tip: Orient with back tab down for best support");
