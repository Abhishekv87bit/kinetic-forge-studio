/*
 * WAVE LAYER: FOAM (Layer 0 - Frontmost)
 * =======================================
 *
 * White, irregular foam/spray shapes
 * Smallest, most detailed layer
 * 2D profile extruded to 4mm thickness
 * Mounting tab on right edge for slider connection
 *
 * Print: 3x (one per wave)
 * Material: White PLA/PETG
 * Layer height: 0.2mm
 * Infill: 15%
 */

include <../common.scad>

// ============================================
// FOAM PROFILE PARAMETERS
// ============================================

// Base dimensions (before scaling)
FOAM_WIDTH = 45;           // X extent
FOAM_HEIGHT = 40;          // Z extent (when upright)

// Tab position on profile
TAB_ATTACH_Z = 8;          // Height above profile bottom

// ============================================
// MAIN MODULE - FOAM LAYER
// ============================================

module wave_layer_foam(scale = 1.0) {
    /*
     * Complete foam layer with mounting tab
     * Oriented for printing: flat on build plate
     * Assembly: rotate 90 degrees to stand upright
     */

    color(C_FOAM)
    union() {
        // Main wave profile
        linear_extrude(height = LAYER_THICKNESS)
            foam_profile_2d(scale);

        // Mounting tab (integral with profile)
        translate([FOAM_WIDTH/2 * scale - 8, TAB_ATTACH_Z * scale, 0])
            mounting_tab(scale);
    }
}

// ============================================
// 2D FOAM PROFILE
// ============================================

module foam_profile_2d(scale = 1.0) {
    /*
     * Hokusai foam spray shape
     * Multiple disconnected blobs for spray effect
     * Irregular, organic appearance
     *
     * Note: Disconnected parts will print fine as separate islands
     * Consider bridging if needed
     */

    s = scale;

    // Main foam mass - connected for structural integrity
    union() {
        // Primary foam blob
        scale([s, s])
        hull() {
            translate([0, 20]) circle(d = 14);
            translate([8, 25]) circle(d = 10);
            translate([-6, 28]) circle(d = 8);
        }

        // Secondary foam mass (connected)
        scale([s, s])
        hull() {
            translate([0, 20]) circle(d = 14);
            translate([-12, 15]) circle(d = 10);
            translate([-8, 8]) circle(d = 8);
        }

        // Upper spray extensions
        scale([s, s])
        hull() {
            translate([-6, 28]) circle(d = 8);
            translate([-10, 35]) circle(d = 5);
        }

        scale([s, s])
        hull() {
            translate([8, 25]) circle(d = 10);
            translate([14, 32]) circle(d = 6);
        }

        // Dripping foam fingers (connected to main mass)
        scale([s, s])
        hull() {
            translate([-8, 8]) circle(d = 8);
            translate([-12, 0]) circle(d = 5);
            translate([-10, -8]) circle(d = 3);
        }

        scale([s, s])
        hull() {
            translate([0, 20]) circle(d = 14);
            translate([10, 12]) circle(d = 8);
            translate([12, 2]) circle(d = 4);
        }

        // Spray droplets (separate islands - OK for 3D printing)
        translate([18 * s, 28 * s]) circle(d = 5 * s);
        translate([-16 * s, 32 * s]) circle(d = 4 * s);
        translate([22 * s, 22 * s]) circle(d = 4 * s);
        translate([-20 * s, 25 * s]) circle(d = 3 * s);
        translate([6 * s, 38 * s]) circle(d = 4 * s);
        translate([-4 * s, 40 * s]) circle(d = 3 * s);
    }
}

// ============================================
// FOAM PROFILE SOLID VERSION
// ============================================

module foam_profile_2d_solid(scale = 1.0) {
    /*
     * Alternative: Fully connected foam shape
     * Use this if printer struggles with separate islands
     */

    s = scale;

    scale([s, s])
    union() {
        // Main connected mass
        hull() {
            translate([0, 20]) circle(d = 14);
            translate([8, 25]) circle(d = 10);
            translate([-6, 28]) circle(d = 8);
            translate([-12, 15]) circle(d = 10);
            translate([10, 12]) circle(d = 8);
        }

        // Upper extension
        hull() {
            translate([-6, 28]) circle(d = 8);
            translate([8, 25]) circle(d = 10);
            translate([0, 35]) circle(d = 8);
        }

        // Lower drips
        hull() {
            translate([-12, 15]) circle(d = 10);
            translate([-10, 0]) circle(d = 6);
        }

        hull() {
            translate([10, 12]) circle(d = 8);
            translate([12, 2]) circle(d = 4);
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
// FOAM LAYER FOR SPECIFIC WAVE
// ============================================

module foam_layer_wave(wave_num) {
    /*
     * Foam layer scaled for specific wave number
     */
    wave_layer_foam(wave_scale(wave_num));
}

// ============================================
// PRINTABLE ORIENTATION
// ============================================

module foam_layer_printable(scale = 1.0) {
    /*
     * Oriented flat for 3D printing
     * Profile lies in XY plane, thickness in Z
     */
    wave_layer_foam(scale);
}

// ============================================
// RENDER PREVIEW
// ============================================

// Show single layer
wave_layer_foam(1.0);

// Show solid version for comparison
translate([60, 0, 0]) {
    echo("Solid version (alternative):");
    color(C_FOAM)
    linear_extrude(height = LAYER_THICKNESS)
        foam_profile_2d_solid(1.0);
}

// Show all three wave variants
translate([0, 60, 0]) {
    echo("Wave 0 (scale 1.0):");
    foam_layer_wave(0);
}

translate([0, 120, 0]) {
    echo("Wave 1 (scale 1.15):");
    foam_layer_wave(1);
}

translate([0, 180, 0]) {
    echo("Wave 2 (scale 0.9):");
    foam_layer_wave(2);
}

// Info
echo("============================================");
echo("WAVE LAYER: FOAM");
echo("============================================");
echo(str("Profile thickness: ", LAYER_THICKNESS, "mm"));
echo(str("Base dimensions: ~", FOAM_WIDTH, " x ", FOAM_HEIGHT, "mm"));
echo(str("Tab size: ", PROFILE_TAB_WIDTH, " x ", PROFILE_TAB_HEIGHT, "mm"));
echo("Print: 3 copies (one per wave, at different scales)");
echo("Note: Profile has separate islands - OK for FDM printing");
echo("============================================");
