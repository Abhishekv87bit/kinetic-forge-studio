/*
 * WAVE OCEAN V10 - APPROACH D: STACKED HORIZONTAL LAYERS
 *
 * Concept: Multiple wave-profile sheets stacked in depth (Y axis)
 *          Each layer moves up/down with phase offset
 *          Overlapping layers create sense of depth and volume
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   Sees multiple wave profiles overlapping
 *   Creates 3D volumetric wave effect
 *   Wave travels RIGHT to LEFT
 *
 * Like looking at ocean from shore - waves at different distances
 */

$fn = 32;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// LAYOUT PARAMETERS
// ============================================

NUM_LAYERS = 6;              // Number of wave layers (depth)
LAYER_SPACING = 12;          // Y distance between layers (mm)
TOTAL_DEPTH = (NUM_LAYERS - 1) * LAYER_SPACING;

NUM_CRESTS = 4;              // Wave crests per layer
CREST_SPACING = 45;          // X distance between crests

PHASE_OFFSET_LAYER = 15;     // Phase offset between layers (depth)
PHASE_OFFSET_CREST = 90;     // Phase offset between crests (creates travel)

// ============================================
// WAVE PROFILE DIMENSIONS
// ============================================

PROFILE_WIDTH = 180;         // Total X span
PROFILE_HEIGHT = 25;         // Base height of wave
PROFILE_THICKNESS = 3;       // Y thickness of each layer

AMPLITUDE = 8;               // Vertical motion amplitude
AMPLITUDE_SCALE = 1.3;       // Front layers move more (1.3x per layer)

// ============================================
// COLORS (depth gradient)
// ============================================

function layer_color(i) =
    let(t = i / (NUM_LAYERS - 1))
    [0.05 + 0.45 * t,   // R: deep to light
     0.15 + 0.50 * t,   // G
     0.40 + 0.50 * t,   // B
     0.7 + 0.3 * t];    // Alpha: back more transparent

C_FRAME = [0.3, 0.3, 0.35];

// ============================================
// KINEMATICS
// ============================================

// Layer phase (back layers lag behind front)
function layer_phase(layer) = theta + layer * PHASE_OFFSET_LAYER;

// Amplitude increases for front layers (more dramatic)
function layer_amplitude(layer) = AMPLITUDE * pow(AMPLITUDE_SCALE, layer);

// Wave profile height at position x for given layer
function wave_height(x, layer) =
    let(
        phase = layer_phase(layer),
        // Multiple crests along X
        local_phase = phase + (x / CREST_SPACING) * PHASE_OFFSET_CREST,
        amp = layer_amplitude(layer)
    )
    PROFILE_HEIGHT + amp * sin(local_phase);

// ============================================
// MODULES
// ============================================

// Single wave layer (organic wave profile)
module wave_layer(layer) {
    y_pos = -TOTAL_DEPTH/2 + layer * LAYER_SPACING;
    phase = layer_phase(layer);
    amp = layer_amplitude(layer);

    // Wave profile as series of points
    points = [
        for (x = [0:5:PROFILE_WIDTH])
            [x - PROFILE_WIDTH/2, wave_height(x, layer)]
    ];

    // Close the polygon at bottom
    closed_points = concat(
        points,
        [[PROFILE_WIDTH/2, 0], [-PROFILE_WIDTH/2, 0]]
    );

    color(layer_color(layer))
    translate([0, y_pos, 0])
    rotate([90, 0, 0])
    linear_extrude(height=PROFILE_THICKNESS)
        polygon(closed_points);
}

// Foam caps on crests (front layers only)
module foam_caps(layer) {
    if (layer >= NUM_LAYERS - 2) {  // Only front 2 layers
        y_pos = -TOTAL_DEPTH/2 + layer * LAYER_SPACING;
        phase = layer_phase(layer);

        for (crest = [0:NUM_CRESTS-1]) {
            crest_x = crest * CREST_SPACING - PROFILE_WIDTH/2 + 20;
            crest_phase = phase + crest * PHASE_OFFSET_CREST;
            crest_z = PROFILE_HEIGHT + layer_amplitude(layer) * sin(crest_phase);

            // Only show foam near crest peak
            if (sin(crest_phase) > 0.7) {
                color([0.9, 0.95, 1.0, 0.8])
                translate([crest_x, y_pos - PROFILE_THICKNESS, crest_z])
                scale([1.5, 0.5, 0.8])
                    sphere(d=8);
            }
        }
    }
}

// Frame base
module frame() {
    color(C_FRAME)
    translate([-PROFILE_WIDTH/2 - 10, -TOTAL_DEPTH/2 - 10, -5])
        cube([PROFILE_WIDTH + 20, TOTAL_DEPTH + 20, 5]);
}

// Guide rails (one per layer, simplified)
module guide_rails() {
    for (layer = [0:NUM_LAYERS-1]) {
        y_pos = -TOTAL_DEPTH/2 + layer * LAYER_SPACING;

        color([0.4, 0.4, 0.45])
        translate([-PROFILE_WIDTH/2 - 8, y_pos - 2, 0]) {
            cube([4, 4, PROFILE_HEIGHT + AMPLITUDE * 2]);
        }

        color([0.4, 0.4, 0.45])
        translate([PROFILE_WIDTH/2 + 4, y_pos - 2, 0]) {
            cube([4, 4, PROFILE_HEIGHT + AMPLITUDE * 2]);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_layersD() {
    frame();
    // guide_rails();  // Uncomment to see guides

    // Render back to front for proper transparency
    for (layer = [0:NUM_LAYERS-1]) {
        wave_layer(layer);
        foam_caps(layer);
    }
}

// Render
wave_ocean_v10_layersD();

// ============================================
// DEBUG
// ============================================

echo("=== WAVE OCEAN V10 - APPROACH D: STACKED LAYERS ===");
echo(str("Layers: ", NUM_LAYERS));
echo(str("Total depth: ", TOTAL_DEPTH, "mm"));
echo(str("Crests per layer: ", NUM_CRESTS));
echo(str("Phase offset (depth): ", PHASE_OFFSET_LAYER, " degrees"));
echo(str("Phase offset (travel): ", PHASE_OFFSET_CREST, " degrees per crest"));
echo("");
echo("Amplitude progression:");
for (i = [0:NUM_LAYERS-1]) {
    echo(str("  Layer ", i, ": ", layer_amplitude(i), "mm"));
}
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Watch from FRONT (F5, rotate to -Y) - overlapping waves");

// ============================================
// PHYSICAL MECHANISM NOTES
// ============================================

/*
 * Each layer is a flexible wave-profile sheet.
 * Driven at ends by vertical guide rails.
 *
 * OPTION 1: Rigid layers on linear guides
 *   - Each layer rides on vertical rails at both ends
 *   - Driven by crank at one end
 *   - Phase offset by crank angle
 *
 * OPTION 2: Flexible sheets with actuated points
 *   - Thin flexible plastic sheets
 *   - Cam followers at multiple points push sheet up
 *   - Sheet flexes to create wave profile
 *
 * OPTION 3: Articulated segments
 *   - Each layer is multiple hinged segments
 *   - Like a snake/caterpillar
 *   - Each segment driven by its own cam
 *
 * This visualization shows OPTION 1 concept.
 */
