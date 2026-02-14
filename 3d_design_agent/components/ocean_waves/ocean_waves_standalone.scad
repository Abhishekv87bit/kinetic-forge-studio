// =============================================================================
// OCEAN WAVE LAYERS - Standalone Component
// Starry Night Kinetic Sculpture - Static Decorative Elements
// =============================================================================
// 3 layered wave shapes creating depth in ocean area (Zone 1 - Far Ocean)
// STATIC - No animation required
// =============================================================================

$fn = 64;

// =============================================================================
// PARAMETERS
// =============================================================================

// Layer dimensions
WAVE_WIDTH = 100;       // mm - along X-axis
WAVE_DEPTH = 40;        // mm - along Y-axis
WAVE_THICKNESS = 3;     // mm - Z height of each layer

// Z positions for each layer
L1_Z = 0;               // Base layer (darkest)
L2_Z = 5;               // Middle layer
L3_Z = 10;              // Top layer (lightest)

// Wave profile parameters (vary per layer for organic look)
L1_AMPLITUDE = 4;       // mm - wave height
L1_FREQUENCY = 3.5;     // cycles across width
L1_PHASE = 0;           // degrees

L2_AMPLITUDE = 5;       // mm - slightly larger
L2_FREQUENCY = 4.0;     // slightly more waves
L2_PHASE = 30;          // offset for variation

L3_AMPLITUDE = 6;       // mm - largest waves
L3_FREQUENCY = 4.5;     // most waves
L3_PHASE = 60;          // further offset

// Colors - blue gradient (dark to light)
L1_COLOR = [0.1, 0.2, 0.5];    // Dark blue
L2_COLOR = [0.2, 0.4, 0.7];    // Medium blue
L3_COLOR = [0.4, 0.6, 0.9];    // Light blue

// Resolution for wave polygon
WAVE_RESOLUTION = 2;    // mm step size along X

// =============================================================================
// WAVE LAYER MODULE
// =============================================================================

// Creates a single wave layer with wavy top edge
// Parameters:
//   width      - total width along X
//   depth      - depth along Y (base depth before waves)
//   thickness  - extrusion height (Z)
//   amplitude  - wave height variation
//   frequency  - number of wave cycles
//   phase      - phase offset in degrees
module wave_layer(width, depth, thickness, amplitude, frequency, phase=0) {

    // Calculate angular frequency (degrees per mm)
    ang_freq = frequency * 360 / width;

    linear_extrude(height = thickness) {
        polygon(
            concat(
                // Top edge - wavy profile using sin()
                [for (x = [0 : WAVE_RESOLUTION : width])
                    [x, depth/2 + amplitude * sin(x * ang_freq + phase)]
                ],
                // Ensure we hit the exact end point
                [[width, depth/2 + amplitude * sin(width * ang_freq + phase)]],
                // Bottom edge - flat, closing the polygon
                [[width, 0]],
                [[0, 0]]
            )
        );
    }
}

// =============================================================================
// INDIVIDUAL LAYER MODULES
// =============================================================================

// Layer 1 - Deepest, darkest blue
module ocean_wave_L1() {
    color(L1_COLOR)
    translate([0, 0, L1_Z])
    wave_layer(
        width = WAVE_WIDTH,
        depth = WAVE_DEPTH,
        thickness = WAVE_THICKNESS,
        amplitude = L1_AMPLITUDE,
        frequency = L1_FREQUENCY,
        phase = L1_PHASE
    );
}

// Layer 2 - Middle, medium blue
module ocean_wave_L2() {
    color(L2_COLOR)
    translate([0, 0, L2_Z])
    wave_layer(
        width = WAVE_WIDTH,
        depth = WAVE_DEPTH,
        thickness = WAVE_THICKNESS,
        amplitude = L2_AMPLITUDE,
        frequency = L2_FREQUENCY,
        phase = L2_PHASE
    );
}

// Layer 3 - Top, lightest blue
module ocean_wave_L3() {
    color(L3_COLOR)
    translate([0, 0, L3_Z])
    wave_layer(
        width = WAVE_WIDTH,
        depth = WAVE_DEPTH,
        thickness = WAVE_THICKNESS,
        amplitude = L3_AMPLITUDE,
        frequency = L3_FREQUENCY,
        phase = L3_PHASE
    );
}

// =============================================================================
// ASSEMBLED VIEW MODULE
// =============================================================================

// All 3 layers stacked together
module ocean_waves_assembled() {
    ocean_wave_L1();
    ocean_wave_L2();
    ocean_wave_L3();
}

// =============================================================================
// MAIN - Show assembled view when run directly
// =============================================================================

ocean_waves_assembled();

// =============================================================================
// NOTES
// =============================================================================
// - Each layer is a separate printable piece
// - Print in different shades of blue filament for effect
// - Layers stack with 2mm gaps between tops
// - Wave profiles vary to create organic, natural look
// - Static shapes - no rotation or animation required
// =============================================================================
