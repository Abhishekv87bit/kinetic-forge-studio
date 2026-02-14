// =============================================================================
// OCEAN WAVE LAYERS - Print Parts Selector
// Starry Night Kinetic Sculpture - Static Decorative Elements
// =============================================================================
// Use PART_SELECT to choose which part to render for printing
// =============================================================================

// PART SELECTION
// 0 = All layers stacked (reference view only - not for printing)
// 1 = Layer 1 only (darkest blue - base)
// 2 = Layer 2 only (medium blue - middle)
// 3 = Layer 3 only (lightest blue - top)
PART_SELECT = 0;

// =============================================================================
// INCLUDE STANDALONE DEFINITIONS
// =============================================================================

$fn = 64;

// Layer dimensions
WAVE_WIDTH = 100;
WAVE_DEPTH = 40;
WAVE_THICKNESS = 3;

// Z positions (only used for assembled view)
L1_Z = 0;
L2_Z = 5;
L3_Z = 10;

// Wave profile parameters
L1_AMPLITUDE = 4;
L1_FREQUENCY = 3.5;
L1_PHASE = 0;

L2_AMPLITUDE = 5;
L2_FREQUENCY = 4.0;
L2_PHASE = 30;

L3_AMPLITUDE = 6;
L3_FREQUENCY = 4.5;
L3_PHASE = 60;

// Colors
L1_COLOR = [0.1, 0.2, 0.5];
L2_COLOR = [0.2, 0.4, 0.7];
L3_COLOR = [0.4, 0.6, 0.9];

WAVE_RESOLUTION = 2;

// =============================================================================
// WAVE LAYER MODULE
// =============================================================================

module wave_layer(width, depth, thickness, amplitude, frequency, phase=0) {
    ang_freq = frequency * 360 / width;

    linear_extrude(height = thickness) {
        polygon(
            concat(
                [for (x = [0 : WAVE_RESOLUTION : width])
                    [x, depth/2 + amplitude * sin(x * ang_freq + phase)]
                ],
                [[width, depth/2 + amplitude * sin(width * ang_freq + phase)]],
                [[width, 0]],
                [[0, 0]]
            )
        );
    }
}

// =============================================================================
// PRINT-READY MODULES (at Z=0 for slicing)
// =============================================================================

// Layer 1 - positioned at Z=0 for printing
module print_L1() {
    color(L1_COLOR)
    wave_layer(
        width = WAVE_WIDTH,
        depth = WAVE_DEPTH,
        thickness = WAVE_THICKNESS,
        amplitude = L1_AMPLITUDE,
        frequency = L1_FREQUENCY,
        phase = L1_PHASE
    );
}

// Layer 2 - positioned at Z=0 for printing
module print_L2() {
    color(L2_COLOR)
    wave_layer(
        width = WAVE_WIDTH,
        depth = WAVE_DEPTH,
        thickness = WAVE_THICKNESS,
        amplitude = L2_AMPLITUDE,
        frequency = L2_FREQUENCY,
        phase = L2_PHASE
    );
}

// Layer 3 - positioned at Z=0 for printing
module print_L3() {
    color(L3_COLOR)
    wave_layer(
        width = WAVE_WIDTH,
        depth = WAVE_DEPTH,
        thickness = WAVE_THICKNESS,
        amplitude = L3_AMPLITUDE,
        frequency = L3_FREQUENCY,
        phase = L3_PHASE
    );
}

// Assembled reference view
module assembled_reference() {
    translate([0, 0, L1_Z]) print_L1();
    translate([0, 0, L2_Z]) print_L2();
    translate([0, 0, L3_Z]) print_L3();
}

// =============================================================================
// PART SELECTOR
// =============================================================================

if (PART_SELECT == 0) {
    // Reference view - all layers stacked
    assembled_reference();
} else if (PART_SELECT == 1) {
    // Layer 1 only - print ready at Z=0
    print_L1();
} else if (PART_SELECT == 2) {
    // Layer 2 only - print ready at Z=0
    print_L2();
} else if (PART_SELECT == 3) {
    // Layer 3 only - print ready at Z=0
    print_L3();
}

// =============================================================================
// PRINT INSTRUCTIONS
// =============================================================================
/*
PRINTING GUIDE:

1. Set PART_SELECT to desired layer (1, 2, or 3)
2. Render (F6) and export STL
3. Print flat on bed - no supports needed

RECOMMENDED FILAMENT COLORS:
- Layer 1: Dark navy blue (e.g., Prusament Galaxy Blue)
- Layer 2: Medium blue (e.g., Prusament Azure Blue)
- Layer 3: Light sky blue (e.g., Prusament Lipstick Red... just kidding, Light Blue)

PRINT SETTINGS:
- Layer height: 0.2mm
- Infill: 20% (these are thin, mostly perimeters)
- Perimeters: 3
- No supports needed

ASSEMBLY:
- Stack layers with L1 at bottom, L3 at top
- Use small dabs of glue or mounting tabs
- Or design a frame to hold all three
*/
// =============================================================================
