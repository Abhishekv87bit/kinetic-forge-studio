/*
 * WAVE PROFILES - Hokusai-style 2D Wave Shapes
 *
 * Each wave consists of 4 layers (front to back):
 *   Layer 0: Foam spray (white, irregular)
 *   Layer 1: Curl tip (light blue, curling shape)
 *   Layer 2: Wave crest (medium blue, main curve)
 *   Layer 3: Wave body (dark blue, base shape)
 *
 * Profiles are 2D shapes extruded to LAYER_THICKNESS
 * Each layer has different shape to create depth illusion
 */

include <common.scad>

$fn = 48;

// ============================================
// WAVE SIZE VARIANTS
// ============================================

// Three wave sizes for variety
WAVE_SCALE_LARGE = 1.2;
WAVE_SCALE_MEDIUM = 1.0;
WAVE_SCALE_SMALL = 0.8;

// Which wave gets which size
WAVE_SCALES = [WAVE_SCALE_LARGE, WAVE_SCALE_MEDIUM, WAVE_SCALE_SMALL];

function wave_scale(w) = WAVE_SCALES[w % 3];

// ============================================
// LAYER 0: FOAM SPRAY (Frontmost)
// ============================================

module foam_profile_2d(scale = 1.0) {
    // Irregular foam spray shape
    // Multiple disconnected blobs for spray effect

    s = scale;

    union() {
        // Main foam mass
        translate([0, 25 * s])
        scale([s, s])
        hull() {
            circle(d = 12);
            translate([8, 5]) circle(d = 8);
            translate([-5, 8]) circle(d = 6);
        }

        // Spray droplets
        translate([15 * s, 35 * s]) circle(d = 5 * s);
        translate([-12 * s, 38 * s]) circle(d = 4 * s);
        translate([20 * s, 28 * s]) circle(d = 3 * s);
        translate([-18 * s, 32 * s]) circle(d = 4 * s);
        translate([8 * s, 42 * s]) circle(d = 3 * s);

        // Dripping foam fingers
        translate([0, 15 * s])
        scale([s, s])
        hull() {
            translate([-8, 0]) circle(d = 4);
            translate([-10, -12]) circle(d = 2);
        }

        translate([10 * s, 18 * s])
        scale([s, s])
        hull() {
            circle(d = 5);
            translate([3, -10]) circle(d = 2);
        }
    }
}

module foam_layer(scale = 1.0) {
    color(C_WAVE_FOAM)
    linear_extrude(height = LAYER_THICKNESS)
        foam_profile_2d(scale);
}

// ============================================
// LAYER 1: CURL TIP
// ============================================

module curl_profile_2d(scale = 1.0) {
    // Curling wave tip - the iconic Hokusai shape
    s = scale;

    scale([s, s])
    union() {
        // Main curl body
        hull() {
            translate([0, 0]) circle(d = 15);
            translate([-20, 25]) circle(d = 20);
            translate([-35, 20]) circle(d = 12);
        }

        // Curl overhang (the finger)
        hull() {
            translate([-35, 20]) circle(d = 12);
            translate([-45, 10]) circle(d = 8);
            translate([-48, 0]) circle(d = 5);
        }

        // Inner curl detail
        hull() {
            translate([-30, 10]) circle(d = 8);
            translate([-38, 5]) circle(d = 5);
        }
    }
}

module curl_layer(scale = 1.0) {
    color(C_WAVE_CURL)
    linear_extrude(height = LAYER_THICKNESS)
        curl_profile_2d(scale);
}

// ============================================
// LAYER 2: WAVE CREST
// ============================================

module crest_profile_2d(scale = 1.0) {
    // Main wave crest - smooth curve
    s = scale;

    scale([s, s])
    union() {
        // Rising wave face
        hull() {
            translate([25, -20]) circle(d = 20);
            translate([10, 5]) circle(d = 25);
            translate([-15, 25]) circle(d = 30);
        }

        // Crest peak
        hull() {
            translate([-15, 25]) circle(d = 30);
            translate([-30, 20]) circle(d = 20);
            translate([-40, 5]) circle(d = 10);
        }

        // Back slope
        hull() {
            translate([-40, 5]) circle(d = 10);
            translate([-35, -15]) circle(d = 15);
            translate([-20, -25]) circle(d = 12);
        }
    }
}

module crest_layer(scale = 1.0) {
    color(C_WAVE_CREST)
    linear_extrude(height = LAYER_THICKNESS)
        crest_profile_2d(scale);
}

// ============================================
// LAYER 3: WAVE BODY (Backmost)
// ============================================

module body_profile_2d(scale = 1.0) {
    // Full wave body - largest, most solid
    s = scale;

    scale([s, s])
    union() {
        // Main wave mass
        hull() {
            translate([35, -30]) circle(d = 25);
            translate([20, -10]) circle(d = 30);
            translate([0, 10]) circle(d = 35);
            translate([-25, 20]) circle(d = 30);
        }

        // Upper portion
        hull() {
            translate([-25, 20]) circle(d = 30);
            translate([-40, 10]) circle(d = 20);
            translate([-45, -5]) circle(d = 15);
        }

        // Trough connection
        hull() {
            translate([-45, -5]) circle(d = 15);
            translate([-40, -25]) circle(d = 20);
            translate([-25, -35]) circle(d = 18);
        }

        // Base extension
        hull() {
            translate([35, -30]) circle(d = 25);
            translate([45, -40]) circle(d = 15);
        }
    }
}

module body_layer(scale = 1.0) {
    color(C_WAVE_BODY)
    linear_extrude(height = LAYER_THICKNESS)
        body_profile_2d(scale);
}

// ============================================
// COMPLETE WAVE (all layers)
// ============================================

module complete_wave_static(scale = 1.0) {
    // All 4 layers at their default positions
    // For visualization only - not for animation

    // Layer 3: Body (back)
    translate([0, layer_y(3), 0])
        body_layer(scale);

    // Layer 2: Crest
    translate([0, layer_y(2), 5])
        crest_layer(scale);

    // Layer 1: Curl
    translate([0, layer_y(1), 10])
        curl_layer(scale);

    // Layer 0: Foam (front)
    translate([0, layer_y(0), 15])
        foam_layer(scale);
}

// ============================================
// SINGLE LAYER MODULE (for animation)
// ============================================

module wave_layer(layer_num, scale = 1.0) {
    if (layer_num == 0) {
        foam_layer(scale);
    } else if (layer_num == 1) {
        curl_layer(scale);
    } else if (layer_num == 2) {
        crest_layer(scale);
    } else if (layer_num == 3) {
        body_layer(scale);
    }
}

// ============================================
// RENDER TEST
// ============================================

// Show all layers separated
translate([-80, 0, 0]) {
    echo("Layer 3: Body");
    body_layer(1.0);
}

translate([-30, 0, 0]) {
    echo("Layer 2: Crest");
    crest_layer(1.0);
}

translate([20, 0, 0]) {
    echo("Layer 1: Curl");
    curl_layer(1.0);
}

translate([70, 0, 0]) {
    echo("Layer 0: Foam");
    foam_layer(1.0);
}

// Show complete wave stacked
translate([0, 60, 0])
    complete_wave_static(1.0);

echo("=== WAVE PROFILES ===");
echo("4 layers per wave: Body, Crest, Curl, Foam");
echo("Each layer thickness: ", LAYER_THICKNESS, "mm");
