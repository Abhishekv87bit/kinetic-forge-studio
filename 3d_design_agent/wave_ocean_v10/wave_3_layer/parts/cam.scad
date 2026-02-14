/*
 * CAM - Helical Barrel Cam (Cylindrical)
 *
 * POWER: Single shaft drives ALL 3 cams
 * - One continuous 8mm shaft runs along X-axis
 * - All 3 cams are keyed/set-screwed to same shaft
 * - Motor drives shaft, shaft drives all cams simultaneously
 *
 * GEOMETRY: True cylindrical barrel with helical ridge
 * - Full 360° round cross-section (NOT elliptical!)
 * - Helical ridge wraps around barrel
 * - Slats ride on TOP of cam as it rotates
 *
 * Printable part: 3x (one per layer, on same shaft)
 * Print orientation: Horizontal (X axis along bed)
 *
 * SHAFT AXIS: X (parallel to slat row)
 * ROTATION: Around X-axis with rotate([theta, 0, 0])
 */

include <../common.scad>

$fn = 72;

// ============================================
// MAIN CAM MODULE
// ============================================

module cam(layer = 0) {
    difference() {
        // Main cam body - TRUE CYLINDRICAL with helical ridge
        cam_body_cylindrical();

        // Shaft hole through center
        shaft_hole();

        // Set screw holes to lock to shaft
        set_screw_holes();
    }
}

// ============================================
// CAM BODY - TRUE CYLINDRICAL BARREL
// ============================================

module cam_body_cylindrical() {
    // Build cam as series of rotated cross-sections along X
    // Each slice is a CIRCLE with varying radius (helical ridge)
    segments = 180;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this X position
        // This creates the traveling wave along the barrel
        phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.01)
            cam_cross_section_circular(phase);
    }
}

// ============================================
// CAM CROSS-SECTION - TRUE CIRCULAR
// ============================================

module cam_cross_section_circular(phase) {
    // CIRCULAR cross-section with sinusoidal ridge
    // The ridge height varies around the circumference
    // creating the helical profile

    points = [for (a = [0 : 5 : 355])
        let(
            // Ridge height varies sinusoidally around circumference
            ridge = CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(a - phase))
        )
        let(r = CAM_CORE_RADIUS + ridge)
        [r * cos(a), r * sin(a)]  // TRUE CIRCLE - no scaling!
    ];

    polygon(points);
    // NO SCALING - this is a true circular cross-section
}

// ============================================
// SHAFT HOLE - 8mm through-hole for shared shaft
// ============================================

module shaft_hole() {
    // Continuous hole for the single shaft that powers all 3 cams
    rotate([0, 90, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_LENGTH + 20, center = true, $fn = 32);
}

// ============================================
// SET SCREW HOLES - Lock cam to shaft
// ============================================

module set_screw_holes() {
    // M3 set screws to lock each cam to the shared shaft
    // These transfer rotational power from shaft to cam
    for (x_pos = [-CAM_LENGTH/2 + 8, CAM_LENGTH/2 - 8]) {
        // Radial holes pointing at shaft center
        translate([x_pos, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS + 5, $fn = 16);
    }
}

// ============================================
// RENDER - All 3 cams on SINGLE SHARED SHAFT
// ============================================

// All 3 cams at their Y positions
// They share ONE shaft - motor drives shaft, shaft drives all cams
for (L = [0 : NUM_LAYERS - 1]) {
    translate([0, CAM_Y[L], 0])
    color(C_CAM)
        cam(L);
}

// Show the SINGLE SHARED SHAFT (transparent)
// This is what the motor drives - it powers all 3 cams
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);

// ============================================
// INFO
// ============================================

echo("=== CYLINDRICAL BARREL CAM ===");
echo(str("Length: ", CAM_LENGTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("Max radius (with ridge): ", CAM_MAX_RADIUS, "mm"));
echo(str("Ridge height: ", CAM_RIDGE_HEIGHT, "mm"));
echo("");
echo("POWER DISTRIBUTION:");
echo("  - Single 8mm shaft runs full length");
echo("  - All 3 cams keyed to same shaft");
echo("  - Motor drives shaft → shaft drives all cams");
echo(str("  - Cam Y positions: ", CAM_Y));
echo("");
echo("GEOMETRY: True cylindrical barrel");
echo("  - Full 360° round cross-section");
echo("  - Helical ridge wraps around barrel");
echo("  - Slats ride on TOP as cam rotates");
echo("");
echo("Print: 3x (one per layer)");
