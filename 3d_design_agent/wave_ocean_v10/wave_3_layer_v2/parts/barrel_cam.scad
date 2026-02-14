/*
 * BARREL CAM - True Cylindrical Helical Cam
 *
 * GEOMETRY:
 * - True 360° circular cross-section
 * - Helical ridge wraps around barrel
 * - Shaft hole along X-axis (cam rotates around X)
 *
 * STAGGERED POSITIONING:
 * - Each of 3 cams at different Y and Z positions
 * - Avoids collision while maintaining traveling wave
 *
 * Print: 3x (one per layer)
 * Print orientation: Horizontal (X axis along bed)
 */

include <../common.scad>

$fn = 72;

// ============================================
// MAIN CAM MODULE
// ============================================

module barrel_cam(layer = 0) {
    difference() {
        cam_body_cylindrical();
        shaft_hole();
        set_screw_holes();
    }
}

// ============================================
// CAM BODY - TRUE CYLINDRICAL BARREL
// ============================================

module cam_body_cylindrical() {
    // Build cam as series of cross-sections along X
    // Each slice has varying radius based on helix phase
    segments = 180;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this X position
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
    // Circular cross-section with sinusoidal ridge
    // Ridge height varies around circumference = helical profile

    points = [for (a = [0 : 5 : 355])
        let(
            ridge = CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(a - phase))
        )
        let(r = CAM_CORE_RADIUS + ridge)
        [r * cos(a), r * sin(a)]
    ];

    polygon(points);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    rotate([0, 90, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_LENGTH + 20, center = true, $fn = 32);
}

// ============================================
// SET SCREW HOLES
// ============================================

module set_screw_holes() {
    // M3 set screws to lock cam to shaft
    for (x_pos = [-CAM_LENGTH/2 + 10, CAM_LENGTH/2 - 10]) {
        translate([x_pos, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_MAX_RADIUS + 5, $fn = 16);
    }
}

// ============================================
// RENDER - Show all 3 cams at staggered positions
// ============================================

for (L = [0 : NUM_LAYERS - 1]) {
    translate([0, CAM_Y[L], CAM_Z[L]])
    color(C_CAM)
        barrel_cam(L);
}

// Show shafts (transparent)
for (L = [0 : NUM_LAYERS - 1]) {
    %translate([0, CAM_Y[L], CAM_Z[L]])
    rotate([0, 90, 0])
        cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);
}

// ============================================
// INFO
// ============================================

echo("=== STAGGERED BARREL CAMS ===");
echo(str("Length: ", CAM_LENGTH, "mm"));
echo(str("Max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("Ridge height: ", CAM_RIDGE_HEIGHT, "mm"));
echo("");
echo("POSITIONS (Y, Z):");
for (L = [0 : NUM_LAYERS - 1]) {
    echo(str("  Cam ", L, ": Y=", CAM_Y[L], ", Z=", CAM_Z[L]));
}
echo("");
echo("Print: 3x (one per layer)");
echo("Orientation: X-axis horizontal");
