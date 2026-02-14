/*
 * CAM - Dual Ridge Twisted Cam
 *
 * Printable part: 1x
 * Print orientation: Horizontal (X axis along bed)
 *
 * DESIGN:
 * - 2 helical ridges create 2 traveling waves
 * - 36 slats ride on surface at different phases
 * - Smooth sinusoidal profile for quiet operation
 * - 8mm shaft hole with set screws
 *
 * TRAVELING WAVE PHYSICS:
 * - 2 ridges spiral 180mm length
 * - 36 slats = 18 slats per wave cycle
 * - Adjacent slats are 20° apart in phase
 * - Creates smooth flowing wave motion
 */

include <../common.scad>

$fn = 72;

// ============================================
// MAIN CAM MODULE
// ============================================

module cam() {
    difference() {
        union() {
            // Main cam body with ridges
            cam_body();

            // End caps
            end_caps();
        }

        // Shaft hole
        shaft_hole();

        // Set screw holes
        set_screw_holes();
    }
}

// ============================================
// CAM BODY - Dual helical ridges
// ============================================

module cam_body() {
    // Build cam as swept cross-sections
    segments = 240;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this position
        // HELIX_TURNS (2) complete rotations over CAM_LENGTH
        phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.01)
            cam_cross_section(phase);
    }
}

// ============================================
// CAM CROSS-SECTION
// ============================================

module cam_cross_section(phase) {
    // Smooth sinusoidal profile
    // Ridge follows cosine curve for smooth motion

    points = [for (a = [0 : 5 : 355])
        let(
            // Smooth ridge height using cosine
            // (0.5 + 0.5*cos) gives range 0 to 1
            ridge = CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(a - phase))
        )
        let(r = CAM_CORE_RADIUS + ridge)
        [r * cos(a), r * sin(a)]
    ];

    polygon(points);
}

// ============================================
// END CAPS
// ============================================

module end_caps() {
    cap_thickness = 3;
    cap_radius = CAM_CORE_RADIUS + 2;

    // Left cap
    translate([-CAM_LENGTH/2 - cap_thickness, 0, 0])
    rotate([0, 90, 0])
        cylinder(r = cap_radius, h = cap_thickness, $fn = 48);

    // Right cap
    translate([CAM_LENGTH/2, 0, 0])
    rotate([0, 90, 0])
        cylinder(r = cap_radius, h = cap_thickness, $fn = 48);
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
    // M3 set screws near each end, 90° apart

    for (x_pos = [-CAM_LENGTH/2 + 8, CAM_LENGTH/2 - 8]) {
        // Vertical
        translate([x_pos, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS + 5, $fn = 16);

        // Horizontal
        translate([x_pos, 0, 0])
        rotate([90, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS + 5, $fn = 16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_CAM)
cam();

// Show shaft
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);

// ============================================
// INFO
// ============================================

echo("=== CAM (Traveling Wave) ===");
echo(str("Length: ", CAM_LENGTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("Max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("Ridge height: ", CAM_RIDGE_HEIGHT, "mm"));
echo(str("Number of ridges: ", HELIX_TURNS));
echo(str("Slats served: ", NUM_SLATS));
echo(str("Phase per slat: ", 360 * HELIX_TURNS / NUM_SLATS, "°"));
echo("");
echo("Print: 1x");
echo("Orientation: Horizontal");
