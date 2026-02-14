/*
 * WAVE LAYER: BODY (Layer 2 - Backmost)
 * =====================================
 *
 * Dark blue, largest shape, smooth wave curve
 * 2D profile extruded to 4mm thickness
 * Mounting tab on right edge for slider connection
 *
 * Print: 3x (one per wave)
 * Material: Any color PLA/PETG
 * Layer height: 0.2mm
 * Infill: 15%
 */

include <../common.scad>

// ============================================
// BODY PROFILE PARAMETERS
// ============================================

// Base dimensions (before scaling)
BODY_WIDTH = 60;           // X extent
BODY_HEIGHT = 50;          // Z extent (when upright)

// Tab position on profile (where slider attaches)
TAB_ATTACH_Z = 15;         // Height above profile bottom

// ============================================
// MAIN MODULE - BODY LAYER
// ============================================

module wave_layer_body(scale = 1.0) {
    /*
     * Complete body layer with mounting tab
     * Oriented for printing: flat on build plate
     * Assembly: rotate 90 degrees to stand upright
     */

    color(C_BODY)
    union() {
        // Main wave profile
        linear_extrude(height = LAYER_THICKNESS)
            body_profile_2d(scale);

        // Mounting tab (integral with profile)
        translate([BODY_WIDTH/2 * scale - 2, TAB_ATTACH_Z * scale, 0])
            mounting_tab(scale);
    }
}

// ============================================
// 2D BODY PROFILE
// ============================================

module body_profile_2d(scale = 1.0) {
    /*
     * Hokusai wave body shape
     * Largest, most solid layer
     * Smooth curves representing main wave mass
     */

    s = scale;

    scale([s, s])
    union() {
        // Main wave mass - rising face
        hull() {
            translate([25, -15]) circle(d = 20);
            translate([10, 5]) circle(d = 25);
            translate([-15, 20]) circle(d = 28);
        }

        // Upper curve - crest area
        hull() {
            translate([-15, 20]) circle(d = 28);
            translate([-30, 15]) circle(d = 20);
            translate([-38, 0]) circle(d = 12);
        }

        // Trough connection
        hull() {
            translate([-38, 0]) circle(d = 12);
            translate([-32, -20]) circle(d = 15);
            translate([-18, -28]) circle(d = 12);
        }

        // Base extension (wave trough)
        hull() {
            translate([25, -15]) circle(d = 20);
            translate([30, -25]) circle(d = 12);
        }

        // Connect all into solid mass
        hull() {
            translate([-18, -28]) circle(d = 12);
            translate([10, -30]) circle(d = 15);
            translate([25, -15]) circle(d = 20);
        }
    }
}

// ============================================
// MOUNTING TAB
// ============================================

module mounting_tab(scale = 1.0) {
    /*
     * Tab that inserts into slider slot
     * Provides rigid connection to slider mechanism
     */

    tab_width = PROFILE_TAB_WIDTH;
    tab_height = PROFILE_TAB_HEIGHT;
    tab_thick = LAYER_THICKNESS;

    // Tab body
    difference() {
        cube([tab_width, tab_height, tab_thick]);

        // Chamfer entry edge for easy insertion
        translate([-0.1, -0.1, tab_thick/2])
        rotate([0, 45, 0])
            cube([2, tab_height + 0.2, 2]);
    }

    // Retention bump (snap fit)
    translate([tab_width - 2, tab_height/2, tab_thick/2])
    rotate([90, 0, 0])
        cylinder(d = 1.5, h = 4, center = true, $fn = 12);
}

// ============================================
// BODY LAYER FOR SPECIFIC WAVE
// ============================================

module body_layer_wave(wave_num) {
    /*
     * Body layer scaled for specific wave number
     */
    wave_layer_body(wave_scale(wave_num));
}

// ============================================
// PRINTABLE ORIENTATION
// ============================================

module body_layer_printable(scale = 1.0) {
    /*
     * Oriented flat for 3D printing
     * Profile lies in XY plane, thickness in Z
     */
    wave_layer_body(scale);
}

// ============================================
// RENDER PREVIEW
// ============================================

// Show single layer
wave_layer_body(1.0);

// Show all three wave variants
translate([0, 80, 0]) {
    echo("Wave 0 (scale 1.0):");
    body_layer_wave(0);
}

translate([0, 160, 0]) {
    echo("Wave 1 (scale 1.15):");
    body_layer_wave(1);
}

translate([0, 240, 0]) {
    echo("Wave 2 (scale 0.9):");
    body_layer_wave(2);
}

// Info
echo("============================================");
echo("WAVE LAYER: BODY");
echo("============================================");
echo(str("Profile thickness: ", LAYER_THICKNESS, "mm"));
echo(str("Base dimensions: ~", BODY_WIDTH, " x ", BODY_HEIGHT, "mm"));
echo(str("Tab size: ", PROFILE_TAB_WIDTH, " x ", PROFILE_TAB_HEIGHT, "mm"));
echo("Print: 3 copies (one per wave, at different scales)");
echo("============================================");
