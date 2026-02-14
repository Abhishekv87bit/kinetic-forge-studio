/*
 * HINGE - Connects Slats Between Layers
 *
 * CORRECTED for new layer order:
 * - Layer 0 = BACK (Y=20)
 * - Layer 1 = MID (Y=10)
 * - Layer 2 = FRONT (Y=0)
 *
 * Hinges connect slats diagonally due to X-OFFSET between layers.
 */

include <../common.scad>

$fn = 24;

// ============================================
// HINGE ROD MODULE
// ============================================

module hinge_rod() {
    rod_length = 12;

    rotate([90, 0, 0])
    cylinder(d = HINGE_ROD_DIA, h = rod_length, center = true);

    for (y = [-rod_length/2, rod_length/2]) {
        translate([0, y, 0])
        rotate([90, 0, 0])
            cylinder(d = HINGE_ROD_DIA + 1.5, h = 1.5, center = true);
    }
}

// ============================================
// HINGE SET FOR SLAT POSITION i
// ============================================

module hinge_set(i, z0, z1, z2) {
    // Get X positions for each layer
    x0 = slat_x(i, 0);
    x1 = slat_x(i, 1);
    x2 = slat_x(i, 2);

    // Hinge 0-1: Between Layer 0 (back) and Layer 1 (mid)
    hinge_y_01 = (LAYER_Y_CENTER[0] + LAYER_Y_CENTER[1]) / 2;  // Y=15
    hinge_z_01 = (z0 + z1) / 2 + HINGE_HEIGHT_FROM_BOTTOM;
    hinge_x_01 = (x0 + x1) / 2;

    translate([hinge_x_01, hinge_y_01, hinge_z_01])
    color(C_HINGE)
        angled_hinge(x0, x1, LAYER_Y_CENTER[0], LAYER_Y_CENTER[1]);

    // Hinge 1-2: Between Layer 1 (mid) and Layer 2 (front)
    hinge_y_12 = (LAYER_Y_CENTER[1] + LAYER_Y_CENTER[2]) / 2;  // Y=5
    hinge_z_12 = (z1 + z2) / 2 + HINGE_HEIGHT_FROM_BOTTOM;
    hinge_x_12 = (x1 + x2) / 2;

    translate([hinge_x_12, hinge_y_12, hinge_z_12])
    color(C_HINGE)
        angled_hinge(x1, x2, LAYER_Y_CENTER[1], LAYER_Y_CENTER[2]);
}

// ============================================
// ANGLED HINGE (connects X-offset slats)
// ============================================

module angled_hinge(x_from, x_to, y_from, y_to) {
    dx = x_to - x_from;
    dy = y_to - y_from;
    length = sqrt(dx*dx + dy*dy);
    angle_xy = atan2(dx, -dy);  // Angle in XY plane

    rotate([90, 0, angle_xy])
    cylinder(d = HINGE_ROD_DIA, h = length, center = true, $fn = 16);

    // End caps
    translate([dx/2, dy/2, 0])
    sphere(d = HINGE_ROD_DIA + 1, $fn = 12);

    translate([-dx/2, -dy/2, 0])
    sphere(d = HINGE_ROD_DIA + 1, $fn = 12);
}

// ============================================
// RENDER - Show sample hinges
// ============================================

for (i = [0, 5, 10, 15]) {
    z0 = 30 + 5 * sin(i * 30);
    z1 = 30 + 5 * sin(i * 30 + 40);
    z2 = 30 + 5 * sin(i * 30 + 80);

    hinge_set(i, z0, z1, z2);
}

// ============================================
// INFO
// ============================================

echo("=== HINGE (CORRECTED) ===");
echo("Connects slats between layers");
echo("Hinges are angled due to X-OFFSET between layers");
echo("");
echo("Layer order:");
echo(str("  0 (BACK):  Y=", LAYER_Y_CENTER[0], ", X offset=", LAYER_X_OFFSET[0]));
echo(str("  1 (MID):   Y=", LAYER_Y_CENTER[1], ", X offset=", LAYER_X_OFFSET[1]));
echo(str("  2 (FRONT): Y=", LAYER_Y_CENTER[2], ", X offset=", LAYER_X_OFFSET[2]));
