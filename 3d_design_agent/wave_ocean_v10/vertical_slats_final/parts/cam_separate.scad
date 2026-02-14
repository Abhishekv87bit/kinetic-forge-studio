/*
 * CAM_SEPARATE - Single Barrel Cam (12mm Y-width)
 *
 * Each cam is:
 * - 180mm long along X (shaft axis)
 * - 12mm wide in Y (CAM_WIDTH) - thin enough to not collide with neighbors
 * - Has a top surface that varies in Z (cam profile)
 * - Shaft hole through center
 *
 * The cam is essentially a rectangular bar with a curved top surface
 * that creates the wave motion.
 *
 * COORDINATE SYSTEM:
 * - X: shaft axis, cam length = 180mm
 * - Y: cam width = 12mm, centered at Y=0
 * - Z: cam height varies with helical profile
 */

include <../common.scad>

$fn = 48;

// ============================================
// MAIN MODULE
// ============================================

module separate_cam(ridge_height, phase_offset = 0) {
    /*
     * A barrel cam that is:
     * - 180mm long (X)
     * - 12mm wide (Y)
     * - ~22-32mm tall (Z) depending on ridge height
     */
    difference() {
        union() {
            // Core cylinder for shaft mounting
            cam_core();

            // Top surface with helical profile
            cam_surface(ridge_height, phase_offset);
        }

        // Shaft hole along X
        rotate([0, 90, 0])
            cylinder(d = SHAFT_HOLE, h = CAM_LENGTH + 20, center = true, $fn = 32);

        // Set screw from top
        translate([0, 0, CAM_CORE_RADIUS])
            cylinder(d = M3_HOLE, h = ridge_height + 10, $fn = 16);
    }
}

// ============================================
// CAM CORE - Cylinder for shaft mount
// ============================================

module cam_core() {
    /*
     * A cylinder of radius CAM_CORE_RADIUS, spanning full cam length.
     * BUT: we need to limit it to CAM_WIDTH in Y!
     *
     * Solution: intersect cylinder with a bounding box
     */
    intersection() {
        // Full cylinder
        rotate([0, 90, 0])
            cylinder(r = CAM_CORE_RADIUS, h = CAM_LENGTH, center = true, $fn = 48);

        // Bounding box limits Y to CAM_WIDTH
        cube([CAM_LENGTH + 1, CAM_WIDTH, CAM_CORE_RADIUS * 3], center = true);
    }
}

// ============================================
// CAM SURFACE - Top surface with helical profile
// ============================================

module cam_surface(ridge_height, phase_offset) {
    /*
     * The active cam surface that followers ride on.
     * Creates a ridge that spirals along X.
     *
     * Built from slices along X, each slice is a curved top.
     */

    num_slices = 72;
    dx = CAM_LENGTH / num_slices;

    for (i = [0 : num_slices - 1]) {
        x1 = -CAM_LENGTH/2 + i * dx;
        x2 = x1 + dx;

        // Helix phase
        phase1 = (i / num_slices) * 360 * HELIX_TURNS + phase_offset;
        phase2 = ((i + 1) / num_slices) * 360 * HELIX_TURNS + phase_offset;

        // Hull adjacent ridge slices
        hull() {
            translate([x1, 0, 0])
                ridge_slice(phase1, ridge_height);
            translate([x2, 0, 0])
                ridge_slice(phase2, ridge_height);
        }
    }
}

// ============================================
// RIDGE SLICE - Single thin slice of the ridge
// ============================================

module ridge_slice(phase, ridge_height) {
    /*
     * A thin slice showing the ridge height at one X position.
     *
     * The ridge height varies with phase:
     * - At phase = 0°: max height (ridge_height above core)
     * - At phase = 180°: min height (0 above core)
     *
     * We build the ridge as a box on top of the core cylinder.
     */

    // Ridge height at this phase (0 to ridge_height)
    extra_h = ridge_height * (0.5 + 0.5 * cos(phase));

    // Only draw if there's any ridge height
    if (extra_h > 0.01) {
        // Box sits on top of core (which has radius CAM_CORE_RADIUS)
        // Bottom at Z = CAM_CORE_RADIUS, top at Z = CAM_CORE_RADIUS + extra_h
        translate([0, 0, CAM_CORE_RADIUS + extra_h/2])
            cube([0.5, CAM_WIDTH, extra_h], center = true);
    } else {
        // Minimal marker for hulling
        translate([0, 0, CAM_CORE_RADIUS])
            cube([0.5, CAM_WIDTH, 0.1], center = true);
    }
}

// ============================================
// RENDER - Three separate cams
// ============================================

// Cam 0: front (Y = -15), small ridge
color([0.9, 0.5, 0.3])
translate([0, LAYER_Y_OFFSET[0], 0])
    separate_cam(LAYER_RIDGE_HEIGHT[0], LAYER_PHASE_OFFSET[0]);

// Cam 1: middle (Y = 0), medium ridge
color([0.8, 0.5, 0.4])
translate([0, LAYER_Y_OFFSET[1], 0])
    separate_cam(LAYER_RIDGE_HEIGHT[1], LAYER_PHASE_OFFSET[1]);

// Cam 2: back (Y = +15), large ridge
color([0.7, 0.5, 0.5])
translate([0, LAYER_Y_OFFSET[2], 0])
    separate_cam(LAYER_RIDGE_HEIGHT[2], LAYER_PHASE_OFFSET[2]);

// Ghost shaft
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);

// ============================================
// VERIFICATION
// ============================================

echo("=== 3 SEPARATE CAMS (12mm Y-width each) ===");
echo("");
echo(str("Shaft axis: X"));
echo(str("Cam length (X): ", CAM_LENGTH, "mm"));
echo(str("Cam width (Y): ", CAM_WIDTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo("");

echo("CAM POSITIONS:");
for (L = [0 : NUM_LAYERS - 1]) {
    y = LAYER_Y_OFFSET[L];
    y_min = y - CAM_WIDTH/2;
    y_max = y + CAM_WIDTH/2;
    ridge = LAYER_RIDGE_HEIGHT[L];
    echo(str("  Cam ", L, ": Y=[", y_min, " to ", y_max, "], ridge=", ridge, "mm"));
}

echo("");
echo("COLLISION CHECK:");
gap_01 = (LAYER_Y_OFFSET[1] - CAM_WIDTH/2) - (LAYER_Y_OFFSET[0] + CAM_WIDTH/2);
gap_12 = (LAYER_Y_OFFSET[2] - CAM_WIDTH/2) - (LAYER_Y_OFFSET[1] + CAM_WIDTH/2);
echo(str("  Gap Cam0-Cam1: ", gap_01, "mm ", (gap_01 > 0 ? "OK" : "COLLISION!")));
echo(str("  Gap Cam1-Cam2: ", gap_12, "mm ", (gap_12 > 0 ? "OK" : "COLLISION!")));
