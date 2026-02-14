/*
 * WAVE LAYER: CURL (Layer 1 - Middle)
 * ====================================
 *
 * Light blue, curling wave tip - the iconic Hokusai shape
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
// CURL PROFILE PARAMETERS
// ============================================

// Base dimensions (before scaling)
CURL_WIDTH = 55;           // X extent
CURL_HEIGHT = 45;          // Z extent (when upright)

// Tab position on profile
TAB_ATTACH_Z = 10;         // Height above profile bottom

// ============================================
// MAIN MODULE - CURL LAYER
// ============================================

module wave_layer_curl(scale = 1.0) {
    /*
     * Complete curl layer with mounting tab
     * Oriented for printing: flat on build plate
     * Assembly: rotate 90 degrees to stand upright
     */

    color(C_CURL)
    union() {
        // Main wave profile
        linear_extrude(height = LAYER_THICKNESS)
            curl_profile_2d(scale);

        // Mounting tab (integral with profile)
        translate([CURL_WIDTH/2 * scale - 5, TAB_ATTACH_Z * scale, 0])
            mounting_tab(scale);
    }
}

// ============================================
// 2D CURL PROFILE
// ============================================

module curl_profile_2d(scale = 1.0) {
    /*
     * Hokusai wave curl shape
     * The iconic curling "finger" of the wave
     * Creates the distinctive breaking wave appearance
     */

    s = scale;

    scale([s, s])
    union() {
        // Main curl body - rising part
        hull() {
            translate([15, -10]) circle(d = 18);
            translate([0, 5]) circle(d = 20);
            translate([-18, 18]) circle(d = 22);
        }

        // Curl overhang - the characteristic finger
        hull() {
            translate([-18, 18]) circle(d = 22);
            translate([-32, 15]) circle(d = 15);
            translate([-42, 8]) circle(d = 10);
        }

        // Curl tip - tapering end
        hull() {
            translate([-42, 8]) circle(d = 10);
            translate([-48, 2]) circle(d = 6);
            translate([-52, -5]) circle(d = 4);
        }

        // Inner curl detail - secondary curve
        hull() {
            translate([-28, 8]) circle(d = 10);
            translate([-38, 2]) circle(d = 6);
            translate([-44, -4]) circle(d = 4);
        }

        // Base connection
        hull() {
            translate([15, -10]) circle(d = 18);
            translate([5, -18]) circle(d = 12);
            translate([-10, -22]) circle(d = 10);
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
// CURL LAYER FOR SPECIFIC WAVE
// ============================================

module curl_layer_wave(wave_num) {
    /*
     * Curl layer scaled for specific wave number
     */
    wave_layer_curl(wave_scale(wave_num));
}

// ============================================
// PRINTABLE ORIENTATION
// ============================================

module curl_layer_printable(scale = 1.0) {
    /*
     * Oriented flat for 3D printing
     * Profile lies in XY plane, thickness in Z
     */
    wave_layer_curl(scale);
}

// ============================================
// RENDER PREVIEW
// ============================================

// Show single layer
wave_layer_curl(1.0);

// Show all three wave variants
translate([0, 70, 0]) {
    echo("Wave 0 (scale 1.0):");
    curl_layer_wave(0);
}

translate([0, 140, 0]) {
    echo("Wave 1 (scale 1.15):");
    curl_layer_wave(1);
}

translate([0, 210, 0]) {
    echo("Wave 2 (scale 0.9):");
    curl_layer_wave(2);
}

// Info
echo("============================================");
echo("WAVE LAYER: CURL");
echo("============================================");
echo(str("Profile thickness: ", LAYER_THICKNESS, "mm"));
echo(str("Base dimensions: ~", CURL_WIDTH, " x ", CURL_HEIGHT, "mm"));
echo(str("Tab size: ", PROFILE_TAB_WIDTH, " x ", PROFILE_TAB_HEIGHT, "mm"));
echo("Print: 3 copies (one per wave, at different scales)");
echo("============================================");
