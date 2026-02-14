/*
 * OPTION A: SINGLE BARREL CAM (Original Design)
 *
 * CHARACTERISTICS:
 * - One helical cam spanning full X length
 * - All 3 layers share SAME ridge height (7mm)
 * - All wave amplitudes identical
 * - Simpler to manufacture (one cam piece)
 *
 * TRADE-OFFS:
 * + Easier to print (single piece)
 * + Simpler assembly
 * - Less visual depth/parallax
 * - Uniform amplitude looks mechanical, not organic
 *
 * This file shows the original cam design for comparison.
 */

include <../common.scad>

$fn = 72;

// ============================================
// SINGLE CAM PARAMETERS (Override per-layer)
// ============================================

SINGLE_RIDGE_HEIGHT = 7;  // Same for all layers

// ============================================
// SINGLE BARREL CAM MODULE
// ============================================

module single_cam() {
    difference() {
        union() {
            // One continuous helical cam
            cam_barrel();

            // End caps
            end_caps_single();
        }

        // Shaft hole
        shaft_hole();

        // Set screw holes
        set_screw_holes_single();
    }
}

// ============================================
// CAM BARREL - Continuous helix along X
// ============================================

module cam_barrel() {
    // Full Y depth to contact all 3 layers
    barrel_y_min = LAYER_Y_OFFSET[0] - 5;   // -20mm
    barrel_y_max = LAYER_Y_OFFSET[2] + 5;   // +20mm
    barrel_depth = barrel_y_max - barrel_y_min;

    segments = 90;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this X position
        helix_phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

        translate([x, barrel_y_min, 0])
        rotate([-90, 0, 0])
        linear_extrude(height = barrel_depth)
            cam_profile_2d_single(helix_phase);
    }
}

// ============================================
// CAM CROSS-SECTION (uniform ridge)
// ============================================

module cam_profile_2d_single(phase) {
    steps = 72;
    points = [for (i = [0 : steps - 1])
        let(angle = i * 360 / steps)
        let(wave_factor = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + SINGLE_RIDGE_HEIGHT * wave_factor)
        [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// ============================================
// END CAPS (single cam version)
// ============================================

module end_caps_single() {
    cap_r = CAM_CORE_RADIUS + SINGLE_RIDGE_HEIGHT + 3;

    barrel_y_min = LAYER_Y_OFFSET[0] - 5;
    barrel_y_max = LAYER_Y_OFFSET[2] + 5;
    cap_depth = barrel_y_max - barrel_y_min;

    // Left cap
    translate([-CAM_LENGTH/2 - CAM_END_CAP, barrel_y_min, 0])
    rotate([-90, 0, 0])
        cylinder(r = cap_r, h = cap_depth, $fn = 48);

    // Right cap
    translate([CAM_LENGTH/2, barrel_y_min, 0])
    rotate([-90, 0, 0])
        cylinder(r = cap_r, h = cap_depth, $fn = 48);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    rotate([0, 90, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_TOTAL_LENGTH + 20, center = true, $fn = 32);
}

// ============================================
// SET SCREW HOLES
// ============================================

module set_screw_holes_single() {
    screw_depth = CAM_CORE_RADIUS;

    for (x = [-CAM_LENGTH/2 + 10, CAM_LENGTH/2 - 10]) {
        translate([x, 0, CAM_CORE_RADIUS + 5])
            cylinder(d = M3_HOLE, h = screw_depth, $fn = 16);

        translate([x, CAM_CORE_RADIUS + 5, 0])
        rotate([-90, 0, 0])
            cylinder(d = M3_HOLE, h = screw_depth, $fn = 16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_CAM)
single_cam();

// Ghost shaft
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);

// ============================================
// VERIFICATION
// ============================================

echo("=== OPTION A: SINGLE BARREL CAM ===");
echo(str("Cam length: ", CAM_LENGTH, "mm"));
echo(str("Uniform ridge height: ", SINGLE_RIDGE_HEIGHT, "mm"));
echo(str("All layers: SAME amplitude"));
echo("");
echo("PROS:");
echo("  - Single piece, easier to print");
echo("  - Simpler assembly");
echo("");
echo("CONS:");
echo("  - Uniform wave amplitude (less organic)");
echo("  - No parallax depth effect");
