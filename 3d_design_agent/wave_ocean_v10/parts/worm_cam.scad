/*
 * WORM CAM - Helical Groove Cam
 *
 * Printable part: 1x
 * Print orientation: Horizontal (along X axis)
 *
 * Features:
 * - Helical groove for follower rollers
 * - 8mm shaft hole with set screw flats
 * - 2x M3 set screw holes (radial)
 *
 * The groove follows a simple helix at GROOVE_RADIUS from center.
 * Wave motion comes from the phase difference between adjacent slats.
 */

include <../common.scad>

// Override $fn for this part
$fn = 64;

// ============================================
// MAIN WORM CAM MODULE
// ============================================

module worm_cam() {
    difference() {
        // Main body
        worm_body();

        // Shaft hole
        shaft_hole();

        // Helical groove (simple helix, no radial variation)
        helical_groove();

        // Set screw holes
        set_screw_holes();
    }
}

// ============================================
// WORM BODY
// ============================================

module worm_body() {
    // Main cylinder - lies along X axis
    rotate([0, 90, 0])
        cylinder(r=WORM_OUTER_RADIUS, h=WORM_LENGTH, center=true);

    // End caps (slightly larger for strength at bearing interface)
    for (x_sign = [-1, 1]) {
        translate([x_sign * (WORM_LENGTH/2 - 3), 0, 0])
        rotate([0, 90, 0])
            cylinder(r=WORM_OUTER_RADIUS + 1, h=6, center=true);
    }
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    // Through hole for 8mm shaft
    rotate([0, 90, 0])
        cylinder(d=WORM_SHAFT_HOLE, h=WORM_LENGTH + 20, center=true, $fn=32);
}

// ============================================
// HELICAL GROOVE
// ============================================

module helical_groove() {
    // Simple helix: groove center at constant GROOVE_RADIUS from shaft
    // Groove makes one full rotation per HELIX_PITCH mm along X

    turns = WORM_LENGTH / HELIX_PITCH;
    steps_per_turn = 36;  // 10° resolution
    total_steps = ceil(turns * steps_per_turn);
    step_len = WORM_LENGTH / total_steps;

    for (i = [0 : total_steps - 1]) {
        x1 = -WORM_LENGTH/2 + i * step_len;
        x2 = x1 + step_len;

        // Helix angle at each position
        angle1 = helix_angle(x1);
        angle2 = helix_angle(x2);

        // Groove center in Y-Z plane (at constant radius)
        gy1 = GROOVE_RADIUS * sin(angle1);
        gz1 = GROOVE_RADIUS * cos(angle1);

        gy2 = GROOVE_RADIUS * sin(angle2);
        gz2 = GROOVE_RADIUS * cos(angle2);

        // Hull between consecutive groove cross-sections
        hull() {
            translate([x1, gy1, gz1])
            rotate([angle1, 0, 0])
                groove_cross_section();

            translate([x2, gy2, gz2])
            rotate([angle2, 0, 0])
                groove_cross_section();
        }
    }
}

// Groove cross-section - sized for 624 bearing (13mm OD) with clearance
module groove_cross_section() {
    // Groove uses GROOVE_DEPTH (radial) and GROOVE_WIDTH (axial) from common.scad
    // GROOVE_DEPTH = 9.5mm, GROOVE_WIDTH = 7mm
    // 624 bearing: 13mm OD (6.5mm radius), 5mm thick

    // Rounded rectangle cross-section
    rotate([0, 90, 0])
    hull() {
        translate([GROOVE_DEPTH/2 - GROOVE_WIDTH/2, 0, 0])
            cylinder(d=GROOVE_WIDTH, h=0.1, center=true, $fn=16);
        translate([-GROOVE_DEPTH/2 + GROOVE_WIDTH/2, 0, 0])
            cylinder(d=GROOVE_WIDTH, h=0.1, center=true, $fn=16);
    }
}

// ============================================
// SET SCREW HOLES
// ============================================

module set_screw_holes() {
    // M3 set screws at each end to lock worm to shaft
    for (x_sign = [-1, 1]) {
        translate([x_sign * (WORM_LENGTH/2 - 15), 0, 0])
        rotate([0, 0, 0]) {
            // Radial hole from top
            translate([0, 0, WORM_CORE_RADIUS])
                cylinder(d=M3_HOLE_DIA, h=WORM_OUTER_RADIUS, $fn=16);
        }
    }
}

// ============================================
// RENDER
// ============================================

color(C_WORM)
worm_cam();

// ============================================
// INFO
// ============================================

echo("=== WORM CAM ===");
echo(str("Length: ", WORM_LENGTH, "mm"));
echo(str("Outer diameter: ", WORM_OUTER_RADIUS * 2, "mm"));
echo(str("Shaft hole: ", WORM_SHAFT_HOLE, "mm"));
echo(str("Groove radius: ", GROOVE_RADIUS, "mm"));
echo(str("Helix pitch: ", HELIX_PITCH, "mm (", WORM_LENGTH/HELIX_PITCH, " turns)"));
echo("");
echo("Print quantity: 1");
echo("Print orientation: Horizontal (X axis along bed)");
echo("Supports: Needed for groove overhangs");
