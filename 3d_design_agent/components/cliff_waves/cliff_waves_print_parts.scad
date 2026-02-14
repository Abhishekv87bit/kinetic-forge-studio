// ============================================
// CLIFF WAVE LAYERS - Print Parts
// Select individual layers for 3D printing
// ============================================

// === PART SELECTION ===
// 0 = All layers stacked (preview)
// 1 = Layer 1 only (base, medium blue)
// 2 = Layer 2 only (mid, light blue)
// 3 = Layer 3 only (top foam, white)
PART_SELECT = 0;

$fn = 64;

// === DIMENSIONS ===
WAVE_WIDTH = 80;
WAVE_DEPTH = 50;
LAYER_THICKNESS = 3;

L1_Z = 0;
L2_Z = 5;
L3_Z = 10;

// === WAVE PARAMETERS ===
AMP1 = 4;
AMP2 = 2;
AMP3 = 1.5;
FREQ1 = 0.15;
FREQ2 = 0.25;
FREQ3 = 0.08;

CURL_HEIGHT = 5;
CURL_OVERHANG = 8;

// === FUNCTIONS ===
function turbulent_wave(x, phase=0) =
    AMP1 * sin(x * FREQ1 * 360/WAVE_WIDTH + phase) +
    AMP2 * sin(x * FREQ2 * 1.7 * 360/WAVE_WIDTH + phase * 1.3) +
    AMP3 * sin(x * FREQ3 * 0.5 * 360/WAVE_WIDTH + phase * 0.7);

// === MODULES ===
module wave_layer_base(layer_num=1) {
    phase = layer_num * 30;
    points = [
        for (x = [0:2:WAVE_WIDTH])
            [x, turbulent_wave(x, phase) + WAVE_DEPTH/2]
    ];
    full_points = concat(
        [[0, 0]],
        points,
        [[WAVE_WIDTH, 0]]
    );
    linear_extrude(height = LAYER_THICKNESS)
        polygon(full_points);
}

module breaking_curl() {
    hull() {
        translate([0, 0, 0])
        cylinder(h=LAYER_THICKNESS, r=3);
        translate([CURL_OVERHANG, -5, CURL_HEIGHT])
        sphere(r=2);
        translate([CURL_OVERHANG + 3, -8, CURL_HEIGHT - 1])
        sphere(r=1.5);
    }
    for (i = [0:4]) {
        translate([
            CURL_OVERHANG + i*2 + rands(-1,1,1)[0],
            -6 - i*1.5,
            CURL_HEIGHT - i*0.5
        ])
        sphere(r = 1 - i*0.15);
    }
}

// Layer modules for printing (flat on bed)
module layer1_print() {
    wave_layer_base(1);
}

module layer2_print() {
    wave_layer_base(2);
}

module layer3_print() {
    // Main wave
    wave_layer_base(3);
    // Breaking curl
    translate([WAVE_WIDTH * 0.7, WAVE_DEPTH/2, 0])
    breaking_curl();
}

// Stacked preview
module all_layers_preview() {
    color([0.3, 0.5, 0.8])
    translate([0, 0, L1_Z])
    layer1_print();

    color([0.5, 0.7, 0.9])
    translate([0, 0, L2_Z])
    layer2_print();

    color([0.95, 0.98, 1.0])
    translate([0, 0, L3_Z])
    layer3_print();
}

// === RENDER SELECTION ===
if (PART_SELECT == 0) {
    all_layers_preview();
} else if (PART_SELECT == 1) {
    layer1_print();
} else if (PART_SELECT == 2) {
    layer2_print();
} else if (PART_SELECT == 3) {
    layer3_print();
}

// ============================================
// PRINT INSTRUCTIONS
// ============================================
// Layer 1: Print in medium blue filament
//          0.2mm layer height, 20% infill
//
// Layer 2: Print in light blue filament
//          0.2mm layer height, 20% infill
//
// Layer 3: Print in white filament
//          0.15mm layer height for curl detail
//          Supports needed for curl overhang
//
// Assembly: Stack L1 -> L2 -> L3
//           Optional: glue at corners
// ============================================
