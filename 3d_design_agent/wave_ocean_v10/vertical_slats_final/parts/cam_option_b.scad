/*
 * OPTION B: Monolithic 3-Section Cam
 *
 * Single piece with 3 Y-sections, each having different ridge height.
 * Sections are connected by end caps for structural integrity.
 *
 * MECHANICAL DESIGN:
 * - 3 sections along Y axis, each 12mm thick
 * - Gaps between sections (3mm) allow slat followers to be isolated
 * - End caps connect all sections and provide structural support
 * - Single shaft hole through center
 *
 * WHY THIS WORKS:
 * - Each section is built as a separate barrel
 * - Sections are unioned together
 * - End caps physically connect them
 * - No intersection/subtraction issues
 *
 * PRINT:
 * - Orientation: Shaft hole horizontal (X along bed)
 * - Supports: For gaps between sections
 * - Infill: 20-30%
 */

include <../common.scad>

$fn = 72;

// ============================================
// SECTION PARAMETERS
// ============================================

// Each section's Y extent
SECTION_THICKNESS = CAM_DISC_THICKNESS;  // 12mm

// Gap between sections (where slat followers ride)
SECTION_GAP = LAYER_Y_SPACING - SECTION_THICKNESS;  // 15 - 12 = 3mm

// ============================================
// MAIN MODULE
// ============================================

module monolithic_cam() {
    difference() {
        union() {
            // Three separate barrel sections
            for (L = [0 : NUM_LAYERS - 1]) {
                section_barrel(L);
            }

            // End caps connect all sections
            end_caps();
        }

        // Shaft hole through everything
        shaft_hole();

        // Set screw holes
        set_screw_holes();
    }
}

// ============================================
// SINGLE SECTION BARREL
// ============================================

module section_barrel(L) {
    // Y position of this section
    y_center = LAYER_Y_OFFSET[L];
    y_start = y_center - SECTION_THICKNESS/2;

    // Ridge height for this section
    ridge = LAYER_RIDGE_HEIGHT[L];

    // Phase offset for this section
    phase_off = LAYER_PHASE_OFFSET[L];

    // Build barrel from X-slices
    segments = 90;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this X
        phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS + phase_off;

        // 2D profile extruded along Y for section thickness
        translate([x, y_start, 0])
        rotate([-90, 0, 0])
        linear_extrude(height = SECTION_THICKNESS)
            cam_profile_2d(phase, ridge);
    }
}

// ============================================
// 2D CAM PROFILE
// ============================================

module cam_profile_2d(phase, ridge) {
    steps = 72;
    points = [for (a = [0 : steps - 1])
        let(angle = a * 360 / steps)
        let(wave = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + ridge * wave)
        [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// ============================================
// END CAPS
// ============================================

module end_caps() {
    // End caps span from front of section 0 to back of section 2
    // They connect all 3 sections structurally

    // Y extent
    y_front = LAYER_Y_OFFSET[0] - SECTION_THICKNESS/2 - 2;  // -23
    y_back = LAYER_Y_OFFSET[2] + SECTION_THICKNESS/2 + 2;   // +23
    cap_depth = y_back - y_front;  // 46mm

    // Cap radius (larger than max cam radius)
    max_ridge = max(LAYER_RIDGE_HEIGHT[0], LAYER_RIDGE_HEIGHT[1], LAYER_RIDGE_HEIGHT[2]);
    cap_r = CAM_CORE_RADIUS + max_ridge + 3;  // 25mm

    // Left end cap
    translate([-CAM_LENGTH/2 - CAM_END_CAP, y_front, 0])
    rotate([-90, 0, 0])
        cylinder(r = cap_r, h = cap_depth, $fn = 48);

    // Right end cap
    translate([CAM_LENGTH/2, y_front, 0])
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

module set_screw_holes() {
    // Two set screws near each end

    for (x = [-CAM_LENGTH/2 + 10, CAM_LENGTH/2 - 10]) {
        // From top (Z+)
        translate([x, 0, CAM_CORE_RADIUS + 5])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS, $fn = 16);

        // From side (Y+)
        translate([x, CAM_CORE_RADIUS + 5, 0])
        rotate([-90, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS, $fn = 16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_CAM)
monolithic_cam();

// Ghost shaft
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);

// ============================================
// DEBUG: Visualize section bounds
// ============================================

for (L = [0 : NUM_LAYERS - 1]) {
    y_start = LAYER_Y_OFFSET[L] - SECTION_THICKNESS/2;
    y_end = LAYER_Y_OFFSET[L] + SECTION_THICKNESS/2;

    // Ghost lines showing section Y bounds
    %translate([0, y_start, CAM_CORE_RADIUS + LAYER_RIDGE_HEIGHT[L] + 5])
        cube([CAM_LENGTH, 0.5, 0.5], center = true);
    %translate([0, y_end, CAM_CORE_RADIUS + LAYER_RIDGE_HEIGHT[L] + 5])
        cube([CAM_LENGTH, 0.5, 0.5], center = true);
}

// ============================================
// VERIFICATION
// ============================================

echo("=== OPTION B: MONOLITHIC 3-SECTION CAM ===");
echo(str("Total X length: ", CAM_LENGTH, "mm active, ", CAM_TOTAL_LENGTH, "mm with caps"));
echo(str("Section thickness (Y): ", SECTION_THICKNESS, "mm"));
echo(str("Gap between sections: ", SECTION_GAP, "mm"));
echo("");
echo("SECTION CONFIGURATION:");
for (L = [0 : NUM_LAYERS - 1]) {
    y1 = LAYER_Y_OFFSET[L] - SECTION_THICKNESS/2;
    y2 = LAYER_Y_OFFSET[L] + SECTION_THICKNESS/2;
    echo(str("  Section ", L, ": Y = [", y1, " to ", y2, "], ridge = ", LAYER_RIDGE_HEIGHT[L], "mm"));
}
echo("");
echo("MECHANICAL NOTES:");
echo("  - Single piece (print as one)");
echo("  - Sections connected by end caps");
echo("  - Fixed phase relationship between sections");
