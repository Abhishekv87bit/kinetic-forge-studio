/*
 * OPTION A: Single Barrel Cam (Press-On Design)
 *
 * Print 3 of these with different ridge heights.
 * Each slides onto the shared 8mm shaft and locks with set screw.
 *
 * MECHANICAL DESIGN:
 * - Full-width barrel cam (40mm in Y) - STRONG
 * - Helical profile creates traveling wave along X
 * - End flanges prevent slat followers from drifting off
 * - Set screw locks cam to shaft at desired phase angle
 *
 * ASSEMBLY:
 * 1. Slide cam onto shaft
 * 2. Position at correct Y location
 * 3. Tighten M3 set screw against shaft
 * 4. Repeat for other 2 cams
 *
 * PRINT:
 * - Orientation: Shaft hole vertical (standing on end flange)
 * - Supports: Minimal (just for set screw hole overhang)
 * - Infill: 20-30% for strength
 */

include <../common.scad>

$fn = 72;

// ============================================
// PARAMETERS
// ============================================

// Cam width in Y direction (thick = strong)
CAM_BARREL_WIDTH = 40;

// End flange dimensions
FLANGE_EXTRA_RADIUS = 3;      // How much larger than max cam radius
FLANGE_THICKNESS = 4;          // Thickness in Y

// Set screw
SET_SCREW_DIA = M3_HOLE;
SET_SCREW_DEPTH = 15;          // Deep enough to reach shaft

// ============================================
// MAIN MODULE - Parameterized barrel cam
// ============================================

module barrel_cam(ridge_height, phase_offset = 0) {
    difference() {
        union() {
            // Main helical barrel
            helical_barrel(ridge_height, phase_offset);

            // End flanges (prevent slat drift)
            end_flanges(ridge_height);
        }

        // Shaft hole (through entire cam)
        shaft_hole();

        // Set screw hole (radial, at center)
        set_screw_hole(ridge_height);
    }
}

// ============================================
// HELICAL BARREL
// ============================================

module helical_barrel(ridge_height, phase_offset) {
    // Build barrel from X-slices, each extruded along Y

    segments = 90;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this X position
        phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS + phase_offset;

        // 2D profile extruded along Y
        translate([x, -CAM_BARREL_WIDTH/2, 0])
        rotate([-90, 0, 0])
        linear_extrude(height = CAM_BARREL_WIDTH)
            cam_profile_2d(phase, ridge_height);
    }
}

// ============================================
// 2D CAM PROFILE
// ============================================

module cam_profile_2d(phase, ridge_height) {
    // Circle with radius varying by angle
    // Creates the cam lobe shape

    steps = 72;
    points = [for (a = [0 : steps - 1])
        let(angle = a * 360 / steps)
        let(wave = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + ridge_height * wave)
        [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// ============================================
// END FLANGES
// ============================================

module end_flanges(ridge_height) {
    // Flanges at Y extremes prevent slat followers from drifting off

    max_r = CAM_CORE_RADIUS + ridge_height + FLANGE_EXTRA_RADIUS;

    // Front flange (Y-)
    translate([0, -CAM_BARREL_WIDTH/2 - FLANGE_THICKNESS, 0])
    rotate([-90, 0, 0])
    linear_extrude(height = FLANGE_THICKNESS)
        circle(r = max_r);

    // Back flange (Y+)
    translate([0, CAM_BARREL_WIDTH/2, 0])
    rotate([-90, 0, 0])
    linear_extrude(height = FLANGE_THICKNESS)
        circle(r = max_r);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    // Through-hole for 8mm shaft
    // Slightly oversized for sliding fit

    rotate([0, 90, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_LENGTH + 50, center = true, $fn = 32);
}

// ============================================
// SET SCREW HOLE
// ============================================

module set_screw_hole(ridge_height) {
    // Radial hole from top (Z+) down to shaft
    // M3 set screw tightens against shaft to lock position

    // Position at center of cam (X=0)
    translate([0, 0, CAM_CORE_RADIUS + ridge_height/2])
        cylinder(d = SET_SCREW_DIA, h = SET_SCREW_DEPTH, $fn = 16);
}

// ============================================
// RENDER - Show all 3 cams for comparison
// ============================================

// Cam 0: Front layer (small amplitude)
color([0.7, 0.5, 0.3])
translate([0, -60, 0])
    barrel_cam(LAYER_RIDGE_HEIGHT[0], LAYER_PHASE_OFFSET[0]);

// Cam 1: Mid layer (medium amplitude)
color([0.6, 0.5, 0.4])
translate([0, 0, 0])
    barrel_cam(LAYER_RIDGE_HEIGHT[1], LAYER_PHASE_OFFSET[1]);

// Cam 2: Back layer (large amplitude)
color([0.5, 0.5, 0.5])
translate([0, 60, 0])
    barrel_cam(LAYER_RIDGE_HEIGHT[2], LAYER_PHASE_OFFSET[2]);

// Ghost shafts showing how they mount
%translate([0, -60, 0]) rotate([0, 90, 0]) cylinder(d = SHAFT_DIA, h = CAM_LENGTH + 20, center = true);
%translate([0, 0, 0]) rotate([0, 90, 0]) cylinder(d = SHAFT_DIA, h = CAM_LENGTH + 20, center = true);
%translate([0, 60, 0]) rotate([0, 90, 0]) cylinder(d = SHAFT_DIA, h = CAM_LENGTH + 20, center = true);

// ============================================
// VERIFICATION
// ============================================

echo("=== OPTION A: PRESSED-ON BARREL CAMS ===");
echo(str("Cam length (X): ", CAM_LENGTH, "mm"));
echo(str("Cam width (Y): ", CAM_BARREL_WIDTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo("");
echo("THREE CAMS TO PRINT:");
echo(str("  Cam 0 (front): ridge = ", LAYER_RIDGE_HEIGHT[0], "mm, max_r = ", CAM_CORE_RADIUS + LAYER_RIDGE_HEIGHT[0], "mm"));
echo(str("  Cam 1 (mid):   ridge = ", LAYER_RIDGE_HEIGHT[1], "mm, max_r = ", CAM_CORE_RADIUS + LAYER_RIDGE_HEIGHT[1], "mm"));
echo(str("  Cam 2 (back):  ridge = ", LAYER_RIDGE_HEIGHT[2], "mm, max_r = ", CAM_CORE_RADIUS + LAYER_RIDGE_HEIGHT[2], "mm"));
echo("");
echo("ASSEMBLY:");
echo("  Slide each cam onto shaft at Y = -15, 0, +15");
echo("  Lock with M3 set screw");
