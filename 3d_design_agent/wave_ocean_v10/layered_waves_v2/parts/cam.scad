/*
 * MULTI-RIDGE TWISTED CAM
 * ========================
 *
 * Single rotating cam drives all 9 wave layers
 * 3 ridges (one per wave position)
 * Smooth sinusoidal profile for organic motion
 * Helical twist creates phase offset along length
 *
 * Print: 1x (may need to print in sections)
 * Material: PLA, PETG, or ABS
 * Layer height: 0.2mm
 * Infill: 40%
 * Orientation: On side (shaft axis horizontal)
 */

include <../common.scad>

// ============================================
// CAM PARAMETERS
// ============================================

// From common.scad:
// CAM_LENGTH = 250mm (active length)
// CAM_TOTAL_LENGTH = 300mm (with extensions)
// CAM_CORE_RADIUS = 12mm
// CAM_RIDGE_HEIGHT = 15mm
// CAM_MAX_RADIUS = 27mm
// CAM_RIDGES = 3

// Shaft features
SHAFT_FLAT_WIDTH = 6;          // Flat on shaft for set screw
SHAFT_FLAT_DEPTH = 1;          // Depth of flat

// Set screw positions
NUM_SET_SCREWS = 2;            // One each end
SET_SCREW_OFFSET = 10;         // From cam end

// Resolution
CAM_SEGMENTS = 100;            // Segments along length
PROFILE_POINTS = 72;           // Points per cross-section

// ============================================
// MAIN MODULE - TWISTED CAM
// ============================================

module twisted_cam() {
    /*
     * Complete cam with:
     * - Helical multi-ridge profile
     * - Central shaft hole
     * - Set screw holes
     * - Bearing journals at ends
     */

    color(C_CAM)
    difference() {
        union() {
            // Main helical cam body
            cam_body_helical();

            // End journals for bearings
            cam_journal_left();
            cam_journal_right();
        }

        // Shaft hole (through entire length)
        shaft_hole();

        // Set screw holes
        set_screw_holes();
    }
}

// ============================================
// HELICAL CAM BODY
// ============================================

module cam_body_helical() {
    /*
     * Cam body with helical twist
     * Profile rotates along length
     * Creates phase offset for wave coordination
     *
     * Physics: Ridge position at X determines when
     * that wave reaches its peak height
     */

    dx = CAM_LENGTH / CAM_SEGMENTS;

    for (i = [0 : CAM_SEGMENTS - 1]) {
        x = -CAM_LENGTH/2 + i * dx;
        phase = cam_phase_at_x(x);

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            cam_profile_2d(phase);
    }
}

// ============================================
// CAM PROFILE 2D
// ============================================

module cam_profile_2d(phase_offset = 0) {
    /*
     * Cross-sectional profile of cam
     * Smooth sinusoidal bumps (ridges)
     * Phase offset rotates entire profile
     *
     * Ridge shape: raised when cos(angle) > 0
     * Creates smooth lift and return
     */

    points = [
        for (a = [0 : 360/PROFILE_POINTS : 359.9])
        let(
            // Base angle adjusted for phase
            adjusted_a = a - phase_offset,

            // Ridge contribution (smooth sinusoid)
            // max(0, cos) gives half-sine bump
            ridge = CAM_RIDGE_HEIGHT * max(0, cos(adjusted_a - 90)),

            // Total radius
            r = CAM_CORE_RADIUS + ridge
        )
        [r * cos(a), r * sin(a)]
    ];

    polygon(points);
}

// ============================================
// JOURNAL EXTENSIONS
// ============================================

module cam_journal_left() {
    /*
     * Left end journal for bearing support
     * Extends beyond active cam length
     * Press-fits into 608 bearing
     */

    journal_dia = SHAFT_DIA + 4;  // Larger than shaft for strength
    journal_length = CAM_EXTENSION;

    translate([-CAM_LENGTH/2 - journal_length, 0, 0])
    rotate([0, 90, 0])
    cylinder(d = journal_dia, h = journal_length);
}

module cam_journal_right() {
    /*
     * Right end journal for bearing support
     */

    journal_dia = SHAFT_DIA + 4;
    journal_length = CAM_EXTENSION;

    translate([CAM_LENGTH/2, 0, 0])
    rotate([0, 90, 0])
    cylinder(d = journal_dia, h = journal_length);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    /*
     * Central hole for 8mm shaft
     * Runs entire length of cam
     * Flat on one side for set screw engagement
     */

    // Main hole
    translate([-CAM_TOTAL_LENGTH/2 - 1, 0, 0])
    rotate([0, 90, 0])
        cylinder(d = CAM_SHAFT_HOLE, h = CAM_TOTAL_LENGTH + 2);

    // Shaft flat (for set screw)
    translate([-CAM_TOTAL_LENGTH/2 - 1,
               -SHAFT_FLAT_WIDTH/2,
               SHAFT_DIA/2 - SHAFT_FLAT_DEPTH])
        cube([CAM_TOTAL_LENGTH + 2, SHAFT_FLAT_WIDTH, SHAFT_DIA]);
}

// ============================================
// SET SCREW HOLES
// ============================================

module set_screw_holes() {
    /*
     * M3 set screw holes to lock cam to shaft
     * Radial holes targeting shaft flat
     */

    // Left end set screw
    translate([-CAM_LENGTH/2 - SET_SCREW_OFFSET, 0, CAM_CORE_RADIUS + 1])
    rotate([0, 0, 0])
        set_screw_hole();

    // Right end set screw
    translate([CAM_LENGTH/2 + SET_SCREW_OFFSET, 0, CAM_CORE_RADIUS + 1])
    rotate([0, 0, 0])
        set_screw_hole();
}

module set_screw_hole() {
    /*
     * Single M3 set screw hole
     * Countersunk for flush mounting
     */

    // Through hole
    rotate([180, 0, 0])
        cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS + 5);

    // Countersink
    cylinder(d = M3_HEAD_DIA, h = 2);
}

// ============================================
// CAM SHAFT (separate part)
// ============================================

module cam_shaft() {
    /*
     * 8mm steel shaft
     * Length: CAM_TOTAL_LENGTH + bearing extensions
     * Not 3D printed - buy steel rod
     */

    shaft_length = CAM_TOTAL_LENGTH + 40;  // Extra for bearings

    color([0.6, 0.6, 0.65])
    rotate([0, 90, 0])
        cylinder(d = SHAFT_DIA, h = shaft_length, center = true);
}

// ============================================
// CAM SECTION (for large format printing)
// ============================================

module cam_section(section_num, total_sections = 3) {
    /*
     * Divide cam into printable sections
     * Each section has alignment features
     * Glue or bolt together after printing
     */

    section_length = CAM_LENGTH / total_sections;
    section_start = -CAM_LENGTH/2 + section_num * section_length;
    section_end = section_start + section_length;

    // Alignment pin/socket dimensions
    align_dia = 4;
    align_depth = 5;

    difference() {
        // Intersect cam with section bounds
        intersection() {
            twisted_cam();

            translate([section_start - 1, -CAM_MAX_RADIUS - 5, -CAM_MAX_RADIUS - 5])
                cube([section_length + 2, CAM_MAX_RADIUS * 2 + 10, CAM_MAX_RADIUS * 2 + 10]);
        }

        // Alignment sockets on right face (except last section)
        if (section_num < total_sections - 1) {
            translate([section_end, 0, CAM_CORE_RADIUS/2])
            rotate([0, 90, 0])
                cylinder(d = align_dia + TOL_CLEARANCE, h = align_depth + 1);

            translate([section_end, 0, -CAM_CORE_RADIUS/2])
            rotate([0, 90, 0])
                cylinder(d = align_dia + TOL_CLEARANCE, h = align_depth + 1);
        }
    }

    // Alignment pins on left face (except first section)
    if (section_num > 0) {
        translate([section_start, 0, CAM_CORE_RADIUS/2])
        rotate([0, -90, 0])
            cylinder(d = align_dia, h = align_depth);

        translate([section_start, 0, -CAM_CORE_RADIUS/2])
        rotate([0, -90, 0])
            cylinder(d = align_dia, h = align_depth);
    }
}

// ============================================
// CAM PROFILE VISUALIZATION
// ============================================

module cam_profile_test() {
    /*
     * Show cam profile at different positions
     * Demonstrates helical twist
     */

    positions = [-CAM_LENGTH/2, 0, CAM_LENGTH/2];

    for (i = [0 : len(positions) - 1]) {
        x = positions[i];
        phase = cam_phase_at_x(x);

        translate([0, i * 70, 0])
        linear_extrude(height = 2)
            cam_profile_2d(phase);

        translate([35, i * 70 + 15, 0])
        text(str("X=", x, ", Phase=", round(phase), "deg"), size = 6);
    }
}

// ============================================
// RENDER
// ============================================

// Complete cam
twisted_cam();

// Show shaft ghost
%cam_shaft();

// Profile test
translate([0, 100, 0])
    cam_profile_test();

// Section preview (for large format printing)
translate([0, -80, 0]) {
    for (s = [0:2]) {
        translate([s * 5, s * 5, 0])  // Offset for visibility
            cam_section(s, 3);
    }
}

// Info
echo("============================================");
echo("MULTI-RIDGE TWISTED CAM");
echo("============================================");
echo(str("Active length: ", CAM_LENGTH, "mm"));
echo(str("Total length: ", CAM_TOTAL_LENGTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("Max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("Ridge height: ", CAM_RIDGE_HEIGHT, "mm"));
echo(str("Number of ridges: ", CAM_RIDGES));
echo(str("Shaft hole: ", CAM_SHAFT_HOLE, "mm"));
echo("");
echo("Print options:");
echo("  1. Full cam if bed >= 300mm");
echo("  2. Use cam_section() to split into 3 parts");
echo("");
echo("Assembly:");
echo("  - 8mm steel shaft");
echo("  - 2x 608 bearings");
echo("  - 2x M3 set screws");
echo("============================================");
