/*
 * BARREL_CAM.SCAD - Helical Cam with EMBEDDED Phase Offset
 *
 * THIS IS THE KEY FIX:
 * Phase offset is baked INTO the cam geometry itself.
 * Each layer's cam has its ridge at a different starting position.
 * Even at rest (no animation), the cams look different!
 *
 * Previous broken approach: phase offset applied only at animation time
 * New approach: phase offset embedded in cam geometry
 */

include <../common.scad>

$fn = 72;

// ============================================
// BARREL CAM WITH EMBEDDED PHASE
// ============================================

module barrel_cam(layer) {
    // Get phase offset for this layer
    phase_offset = LAYER_PHASE_OFFSET[layer];

    difference() {
        // Cam body with EMBEDDED phase offset
        cam_body_with_phase(phase_offset);

        // Shaft hole
        shaft_hole();

        // Set screw holes
        set_screw_holes();
    }
}

// ============================================
// CAM BODY - Phase EMBEDDED in geometry
// ============================================

module cam_body_with_phase(phase_offset) {
    // Build cam as series of cross-sections along X
    // Each slice has its own phase based on X position AND layer offset
    segments = 180;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase based on X position
        helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

        // CRITICAL: Add layer phase offset HERE (baked into geometry!)
        phase = helix_angle + phase_offset;

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.01)
            cam_cross_section(phase);
    }
}

// ============================================
// CAM CROSS-SECTION - Circular with varying ridge
// ============================================

module cam_cross_section(phase) {
    // True circular cross-section with sinusoidal ridge
    // Ridge height varies around circumference

    points = [for (a = [0 : 5 : 355])
        let(
            // Ridge height varies sinusoidally
            ridge = CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(a - phase))
        )
        let(r = CAM_MIN_RADIUS + ridge)
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
    // M3 set screws at each end
    for (x_pos = [-CAM_LENGTH/2 + 10, CAM_LENGTH/2 - 10]) {
        translate([x_pos, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_MAX_RADIUS + 5, $fn = 16);
    }
}

// ============================================
// RENDER - Show all 3 cams with embedded phases
// ============================================

// Show cams at their staggered positions (using box coordinates)
for (layer = [0 : NUM_LAYERS - 1]) {
    translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Use absolute box coordinates!
    color(C_CAM)
        barrel_cam(layer);
}

// Show shafts
for (layer = [0 : NUM_LAYERS - 1]) {
    %translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Use absolute box coordinates!
    rotate([0, 90, 0])
    color(C_SHAFT)
        cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);
}

// ============================================
// INFO
// ============================================

echo("=== BARREL CAM WITH EMBEDDED PHASE ===");
echo(str("Length: ", CAM_LENGTH, "mm"));
echo(str("Radius: ", CAM_MIN_RADIUS, " to ", CAM_MAX_RADIUS, "mm"));
echo(str("Helix turns: ", HELIX_TURNS));
echo("");
echo("EMBEDDED PHASE OFFSETS:");
echo(str("  Cam 0: ", LAYER_PHASE_OFFSET[0], " deg - ridge starts at 0 deg"));
echo(str("  Cam 1: ", LAYER_PHASE_OFFSET[1], " deg - ridge starts at 40 deg"));
echo(str("  Cam 2: ", LAYER_PHASE_OFFSET[2], " deg - ridge starts at 80 deg"));
echo("");
echo("POSITIONS (BOX COORDINATES Y, Z):");
for (layer = [0 : NUM_LAYERS - 1]) {
    echo(str("  Cam ", layer, ": Y=", CAM_Y_BOX[layer], ", Z=", CAM_Z[layer]));
}
echo("");
echo("These cams are PHYSICALLY DIFFERENT - even without animation,");
echo("their ridges are at different angular positions!");
