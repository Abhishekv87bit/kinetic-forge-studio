/*
 * WAVE OCEAN V10 - HORIZONTAL LAYERED WAVE SYSTEM
 * COMMON PARAMETERS
 *
 * Hokusai-style waves: 2D profiles stacked in depth layers
 * Each wave is 3-4 layers (body, curl, foam)
 * Layers move with phase offset for rolling illusion
 *
 * This creates the dramatic Japanese woodblock print aesthetic
 */

// ============================================
// PRINT TOLERANCES
// ============================================

TOL_CLEARANCE = 0.2;
TOL_SLIDING = 0.3;

// ============================================
// HARDWARE
// ============================================

BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

SHAFT_DIA = 8;
M3_HOLE = 3.2;
M4_HOLE = 4.2;

// ============================================
// SCENE DIMENSIONS
// ============================================

SCENE_WIDTH = 250;               // Total width of wave scene
SCENE_HEIGHT = 120;              // Visible wave area height
SCENE_DEPTH = 60;                // Front to back depth

// ============================================
// WAVE CONFIGURATION
// ============================================

NUM_WAVES = 3;                   // Number of complete wave forms
WAVE_SPACING = SCENE_WIDTH / NUM_WAVES;  // ~83mm per wave

// Layer configuration per wave
NUM_LAYERS = 4;                  // Layers per wave
LAYER_SPACING = 10;              // Depth between layers (Y direction)
LAYER_THICKNESS = 4;             // Thickness of each profile piece

// Wave motion
WAVE_AMPLITUDE = 15;             // Vertical travel
PHASE_OFFSET_PER_LAYER = 20;     // Degrees phase difference between layers

// ============================================
// LAYER DEFINITIONS
// Layer 0 = Frontmost (foam/spray)
// Layer 3 = Backmost (wave body base)
// ============================================

// Heights relative to base
LAYER_HEIGHTS = [
    45,     // Layer 0: Foam spray (front, highest)
    50,     // Layer 1: Curl tip
    55,     // Layer 2: Wave crest
    40      // Layer 3: Wave body (back, lowest)
];

// Y positions (depth into scene)
function layer_y(l) = -SCENE_DEPTH/2 + l * LAYER_SPACING + LAYER_SPACING/2;

// Phase offset per layer (front layers lag behind)
function layer_phase_offset(l) = l * PHASE_OFFSET_PER_LAYER;

// ============================================
// CAM SYSTEM (drives wave motion)
// ============================================

CAM_LENGTH = SCENE_WIDTH + 40;   // 290mm
CAM_CORE_RADIUS = 12;
CAM_RIDGE_HEIGHT = WAVE_AMPLITUDE;
CAM_MAX_RADIUS = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT;

// One cam ridge per wave
CAM_RIDGES = NUM_WAVES;
HELIX_TURNS = NUM_WAVES;         // 3 ridges = 3 waves visible

// ============================================
// MOUNTING SYSTEM
// ============================================

// Each wave layer has a vertical guide rod
GUIDE_ROD_DIA = 4;               // 4mm steel rod
GUIDE_ROD_LENGTH = WAVE_AMPLITUDE + 30;

// Slider block connects layer to guide rod
SLIDER_WIDTH = 12;
SLIDER_DEPTH = LAYER_THICKNESS + 4;
SLIDER_HEIGHT = 15;

// Follower arm connects slider to cam
FOLLOWER_ARM_LENGTH = 35;
FOLLOWER_ARM_WIDTH = 8;

// ============================================
// ASSEMBLY POSITIONS
// ============================================

BASE_THICKNESS = 5;
CAM_CENTER_Z = -30;              // Below visible scene
CAM_CENTER_Y = 0;

// Guide frame position
GUIDE_FRAME_Z = CAM_CENTER_Z + CAM_MAX_RADIUS + 10;

// ============================================
// COLORS
// ============================================

C_WAVE_BODY = [0.1, 0.25, 0.5];      // Dark blue (back layer)
C_WAVE_CREST = [0.15, 0.35, 0.6];    // Medium blue
C_WAVE_CURL = [0.2, 0.45, 0.7];      // Light blue
C_WAVE_FOAM = [0.95, 0.97, 1.0];     // White
C_FRAME = [0.3, 0.25, 0.2];          // Dark wood
C_CAM = [0.6, 0.5, 0.3];
C_MECHANISM = [0.5, 0.5, 0.55];

// Layer colors (front to back)
LAYER_COLORS = [
    C_WAVE_FOAM,    // Layer 0: Foam
    C_WAVE_CURL,    // Layer 1: Curl
    C_WAVE_CREST,   // Layer 2: Crest
    C_WAVE_BODY     // Layer 3: Body
];

// ============================================
// HELPER FUNCTIONS
// ============================================

// Cam phase at position X
function cam_phase(x, theta) =
    let(helix_phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    helix_phase + theta;

// Cam surface height at position X, rotation theta
function cam_height(x, theta) =
    let(phase = cam_phase(x, theta))
    CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT * max(0, cos(phase - 90));

// Wave X position (center of each wave)
function wave_x(w) = w * WAVE_SPACING - SCENE_WIDTH/2 + WAVE_SPACING/2;

// Layer Z position for wave w, layer l, at rotation theta
function layer_z(w, l, theta) =
    let(x = wave_x(w))
    let(phase_offset = layer_phase_offset(l))
    let(adjusted_theta = theta - phase_offset)
    let(base_z = GUIDE_FRAME_Z)
    let(cam_z = cam_height(x, adjusted_theta) - CAM_CORE_RADIUS)
    base_z + cam_z;

// ============================================
// QUALITY
// ============================================

$fn = 48;
