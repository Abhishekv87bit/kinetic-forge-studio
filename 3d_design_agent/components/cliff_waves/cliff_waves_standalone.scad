// ============================================
// CLIFF WAVE LAYERS - Static Breaking Wave
// Starry Night Kinetic Sculpture Component
// ============================================
// 3 layered wave shapes for cliff "breaking wave" zone
// MORE DRAMATIC profile than ocean waves
// Color gradient: medium blue to white foam
// STATIC - no animation
// ============================================

$fn = 64;

// === DIMENSIONS ===
WAVE_WIDTH = 80;      // X dimension
WAVE_DEPTH = 50;      // Y dimension
LAYER_THICKNESS = 3;  // Each layer

// Layer Z positions
L1_Z = 0;
L2_Z = 5;
L3_Z = 10;

// === COLORS ===
COLOR_L1 = [0.3, 0.5, 0.8];      // Medium blue (base)
COLOR_L2 = [0.5, 0.7, 0.9];      // Light blue (mid)
COLOR_L3 = [0.95, 0.98, 1.0];   // White foam (top)

// === WAVE PROFILE PARAMETERS ===
// Multi-frequency for turbulent effect
AMP1 = 4;     // Primary amplitude
AMP2 = 2;     // Secondary turbulence
AMP3 = 1.5;   // Low-frequency swell

FREQ1 = 0.15; // Primary frequency
FREQ2 = 0.25; // Secondary frequency
FREQ3 = 0.08; // Swell frequency

// Breaking curl parameters (L3 only)
CURL_HEIGHT = 5;
CURL_OVERHANG = 8;

// ============================================
// TURBULENT WAVE PROFILE FUNCTION
// Combines multiple sine waves for dramatic effect
// ============================================
function turbulent_wave(x, phase=0) =
    AMP1 * sin(x * FREQ1 * 360/WAVE_WIDTH + phase) +
    AMP2 * sin(x * FREQ2 * 1.7 * 360/WAVE_WIDTH + phase * 1.3) +
    AMP3 * sin(x * FREQ3 * 0.5 * 360/WAVE_WIDTH + phase * 0.7);

// ============================================
// WAVE LAYER MODULE - Base turbulent shape
// ============================================
module wave_layer_base(layer_num=1) {
    // Phase offset per layer for visual variety
    phase = layer_num * 30;

    // Generate wave profile points
    points = [
        for (x = [0:2:WAVE_WIDTH])
            [x, turbulent_wave(x, phase) + WAVE_DEPTH/2]
    ];

    // Complete polygon with base
    full_points = concat(
        [[0, 0]],
        points,
        [[WAVE_WIDTH, 0]]
    );

    linear_extrude(height = LAYER_THICKNESS)
        polygon(full_points);
}

// ============================================
// LAYER 1 - Base Wave (Medium Blue)
// ============================================
module cliff_wave_L1() {
    color(COLOR_L1)
    translate([0, 0, L1_Z])
    wave_layer_base(1);
}

// ============================================
// LAYER 2 - Mid Foam (Light Blue)
// Slightly more turbulent profile
// ============================================
module cliff_wave_L2() {
    color(COLOR_L2)
    translate([0, 0, L2_Z])
    wave_layer_base(2);
}

// ============================================
// LAYER 3 - Top Foam with Breaking Curl
// Most dramatic - includes curl effect
// ============================================
module cliff_wave_L3() {
    color(COLOR_L3)
    translate([0, 0, L3_Z]) {
        // Main wave layer
        wave_layer_base(3);

        // Breaking wave curl at leading edge
        translate([WAVE_WIDTH * 0.7, WAVE_DEPTH/2, 0])
        breaking_curl();
    }
}

// ============================================
// BREAKING CURL - Foam spray effect
// Creates the iconic breaking wave curl
// ============================================
module breaking_curl() {
    // Curved overhang representing breaking wave
    hull() {
        // Base connection
        translate([0, 0, 0])
        cylinder(h=LAYER_THICKNESS, r=3);

        // Curl peak - forward and up
        translate([CURL_OVERHANG, -5, CURL_HEIGHT])
        sphere(r=2);

        // Spray tip
        translate([CURL_OVERHANG + 3, -8, CURL_HEIGHT - 1])
        sphere(r=1.5);
    }

    // Additional foam spray particles
    for (i = [0:4]) {
        translate([
            CURL_OVERHANG + i*2 + rands(-1,1,1)[0],
            -6 - i*1.5,
            CURL_HEIGHT - i*0.5
        ])
        sphere(r = 1 - i*0.15);
    }
}

// ============================================
// COMPLETE ASSEMBLY - All 3 layers stacked
// ============================================
module cliff_waves_assembly() {
    cliff_wave_L1();
    cliff_wave_L2();
    cliff_wave_L3();
}

// ============================================
// RENDER PREVIEW
// ============================================
cliff_waves_assembly();

// ============================================
// COMPONENT INFO
// ============================================
// File: cliff_waves_standalone.scad
// Purpose: Static breaking wave decoration
// Layers: 3 (L1=base blue, L2=light blue, L3=white foam)
// Dimensions: 80mm x 50mm x 13mm total
// Animation: NONE (static)
// Print: See cliff_waves_print_parts.scad
// ============================================
