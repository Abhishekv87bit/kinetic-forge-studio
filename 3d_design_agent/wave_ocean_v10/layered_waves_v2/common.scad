/*
 * HORIZONTAL LAYERED WAVE SYSTEM V2 - COMMON PARAMETERS
 * ======================================================
 *
 * Complete engineering for 3D printing
 * Hokusai-style waves: 2D profiles stacked in depth
 * 3 waves x 3 layers = 9 wave profiles
 *
 * MECHANISM: Single cam drives all layers via follower arms
 * Phase offset between layers creates rolling wave illusion
 */

// ============================================
// PRINT TOLERANCES (verified for FDM)
// ============================================

TOL_CLEARANCE = 0.2;      // General clearance (press fits)
TOL_SLIDING = 0.3;        // Sliding fits (guide rods)
TOL_LOOSE = 0.4;          // Loose fits (easy assembly)

// Hole size adjustments
HOLE_ADJUSTMENT = 0.2;    // Add to nominal for printed holes

// ============================================
// HARDWARE SPECIFICATIONS
// ============================================

// 608 Bearing (skateboard bearing)
BEARING_608_ID = 8;       // Inner diameter
BEARING_608_OD = 22;      // Outer diameter
BEARING_608_H = 7;        // Height

// Press-fit pocket for 608 (slightly undersized)
BEARING_POCKET_DIA = BEARING_608_OD + 0.1;  // 22.1mm
BEARING_POCKET_DEPTH = BEARING_608_H + 0.5;

// Main shaft
SHAFT_DIA = 8;            // Matches bearing ID
SHAFT_HOLE = SHAFT_DIA + TOL_SLIDING;  // 8.3mm

// Guide rods (4mm steel)
GUIDE_ROD_DIA = 4;
GUIDE_ROD_HOLE = GUIDE_ROD_DIA + TOL_SLIDING;  // 4.3mm

// Fasteners
M3_HOLE = 3.0 + HOLE_ADJUSTMENT;   // 3.2mm
M3_HEAD_DIA = 5.5;
M3_HEAD_DEPTH = 3;
M3_NUT_ACROSS = 5.5;
M3_NUT_H = 2.4;

M4_HOLE = 4.0 + HOLE_ADJUSTMENT;   // 4.2mm
M4_HEAD_DIA = 7;
M4_HEAD_DEPTH = 4;

// Set screw
SET_SCREW_DIA = 3;        // M3 set screw
SET_SCREW_DEPTH = 4;

// Pivot pins
PIVOT_PIN_DIA = 3;        // 3mm steel rod
PIVOT_HOLE = PIVOT_PIN_DIA + TOL_SLIDING;  // 3.3mm

// ============================================
// SCENE DIMENSIONS
// ============================================

SCENE_WIDTH = 250;        // Total width (X direction)
SCENE_HEIGHT = 100;       // Visible wave area height (Z)
SCENE_DEPTH = 50;         // Front to back (Y direction)

// ============================================
// WAVE CONFIGURATION
// ============================================

NUM_WAVES = 3;                              // Number of waves
WAVE_SPACING = SCENE_WIDTH / NUM_WAVES;     // 83.33mm between wave centers

// Layer configuration (per wave)
NUM_LAYERS = 3;                             // body, curl, foam
LAYER_SPACING = 12;                         // Y distance between layers
LAYER_THICKNESS = 4;                        // Profile extrusion thickness

// Wave motion parameters
WAVE_AMPLITUDE = 15;                        // Vertical travel (mm)
PHASE_OFFSET_PER_LAYER = 20;                // Degrees phase difference

// ============================================
// LAYER DEFINITIONS
// Layer 0 = Foam (front, white)
// Layer 1 = Curl (middle, light blue)
// Layer 2 = Body (back, dark blue)
// ============================================

LAYER_NAMES = ["foam", "curl", "body"];

// Layer colors
C_FOAM = [0.95, 0.97, 1.0];        // White foam
C_CURL = [0.2, 0.45, 0.7];         // Light blue curl
C_BODY = [0.1, 0.25, 0.5];         // Dark blue body

LAYER_COLORS = [C_FOAM, C_CURL, C_BODY];

// ============================================
// CALCULATED POSITIONS
// ============================================

// Wave X positions (center of each wave)
function wave_x(w) = w * WAVE_SPACING - SCENE_WIDTH/2 + WAVE_SPACING/2;

// Layer Y positions (depth into scene, front to back)
// Front of scene is at Y = -SCENE_DEPTH/2
function layer_y(l) = -SCENE_DEPTH/2 + (l + 0.5) * LAYER_SPACING;

// Phase offset for each layer (front lags behind back)
function layer_phase(l) = (NUM_LAYERS - 1 - l) * PHASE_OFFSET_PER_LAYER;

// ============================================
// CAM SYSTEM
// ============================================

// Cam extends beyond scene width for bearing mounts
CAM_LENGTH = SCENE_WIDTH;              // Active cam length
CAM_EXTENSION = 25;                    // Extension for bearings
CAM_TOTAL_LENGTH = CAM_LENGTH + 2 * CAM_EXTENSION;  // 300mm total

// Cam profile
CAM_CORE_RADIUS = 12;                  // Minimum radius
CAM_RIDGE_HEIGHT = WAVE_AMPLITUDE;     // 15mm
CAM_MAX_RADIUS = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT;  // 27mm

// Number of ridges (one per wave)
CAM_RIDGES = NUM_WAVES;                // 3 ridges
HELIX_ANGLE_PER_MM = 360 * CAM_RIDGES / CAM_LENGTH;  // degrees per mm

// Shaft hole with set screw positions
CAM_SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;

// ============================================
// GUIDE SYSTEM
// ============================================

// Guide rod positions are calculated for each wave/layer combination
// Guide rods are vertical (Z direction)

// Horizontal distance from wave profile center to guide rod
GUIDE_OFFSET_X = 50;                   // Guide rod offset from wave center

// Guide rod length (enough for full travel plus margins)
GUIDE_ROD_LENGTH = WAVE_AMPLITUDE + 40;  // 55mm

// Frame Z position (bottom of guide rods)
// Must be above cam max radius
CAM_CENTER_Z = -50;                    // Cam axis height
FRAME_BASE_Z = CAM_CENTER_Z + CAM_MAX_RADIUS + 5;  // Bottom of frame

// Top of frame
FRAME_TOP_Z = FRAME_BASE_Z + GUIDE_ROD_LENGTH + 10;

// ============================================
// SLIDER DIMENSIONS
// ============================================

SLIDER_WIDTH = 16;                     // X dimension
SLIDER_DEPTH = 12;                     // Y dimension
SLIDER_HEIGHT = 18;                    // Z dimension

// Guide rod boss (reinforced area around guide hole)
GUIDE_BOSS_DIA = GUIDE_ROD_HOLE + 6;   // 10.3mm

// Layer mounting tab
MOUNT_TAB_WIDTH = 15;                  // X extension for layer attachment
MOUNT_TAB_DEPTH = 8;                   // Y dimension
MOUNT_TAB_SLOT_WIDTH = LAYER_THICKNESS + TOL_LOOSE;  // 4.4mm slot

// ============================================
// FOLLOWER ARM DIMENSIONS
// ============================================

// Follower arm connects slider (above) to cam (below)
// Pivot at slider, roller contact at cam

// Distance from guide rod to cam surface
VERTICAL_DISTANCE = FRAME_BASE_Z + SLIDER_HEIGHT/2 - CAM_CENTER_Z - CAM_MAX_RADIUS;

// Follower must reach from slider pivot to cam surface
// Account for layer Y offset from cam centerline
MAX_LAYER_Y_OFFSET = layer_y(NUM_LAYERS - 1);  // Furthest layer from cam

// Follower arm length (calculated for proper reach)
// arm_length^2 = vertical_distance^2 + y_offset^2
// Adding margin for roller radius
FOLLOWER_ARM_LENGTH = sqrt(pow(VERTICAL_DISTANCE, 2) + pow(abs(MAX_LAYER_Y_OFFSET), 2)) + 10;

FOLLOWER_ARM_WIDTH = 10;               // Width of arm
FOLLOWER_ARM_THICKNESS = 5;            // Thickness

// Roller at bottom of follower
FOLLOWER_ROLLER_DIA = 8;               // 608 bearing OD/3
FOLLOWER_ROLLER_WIDTH = 6;

// ============================================
// BEARING BLOCK DIMENSIONS
// ============================================

BEARING_BLOCK_WIDTH = BEARING_608_OD + 12;   // 34mm
BEARING_BLOCK_HEIGHT = BEARING_608_H + 8;     // 15mm
BEARING_BLOCK_DEPTH = BEARING_608_OD + 8;     // 30mm

// ============================================
// FRAME DIMENSIONS
// ============================================

FRAME_WALL = 5;                        // Wall thickness
FRAME_WIDTH = SCENE_WIDTH + 80;        // Total frame width
FRAME_DEPTH = SCENE_DEPTH + 60;        // Total frame depth
FRAME_HEIGHT = FRAME_TOP_Z - FRAME_BASE_Z + 20;

// Guide rod socket holes in frame
GUIDE_SOCKET_DEPTH = 8;                // How deep guide rod inserts

// ============================================
// WAVE PROFILE DIMENSIONS
// ============================================

// Each wave profile has a mounting tab on its edge
// Tab inserts into slider slot
PROFILE_TAB_WIDTH = 10;
PROFILE_TAB_HEIGHT = SLIDER_HEIGHT - 4;
PROFILE_TAB_THICKNESS = LAYER_THICKNESS;

// Wave scale variations for visual interest
WAVE_SCALES = [1.0, 1.15, 0.9];        // Wave 0, 1, 2 scales
function wave_scale(w) = WAVE_SCALES[w % 3];

// ============================================
// MECHANISM COLORS
// ============================================

C_FRAME = [0.3, 0.25, 0.2];            // Dark wood
C_CAM = [0.6, 0.5, 0.3];               // Bronze cam
C_MECHANISM = [0.5, 0.5, 0.55];        // Steel gray
C_GUIDE = [0.7, 0.7, 0.75];            // Light steel
C_BEARING = [0.4, 0.4, 0.45];          // Dark steel

// ============================================
// HELPER FUNCTIONS
// ============================================

// Cam phase at position X along cam length
// x is measured from cam center (0 = middle)
function cam_phase_at_x(x) =
    (x + CAM_LENGTH/2) / CAM_LENGTH * 360 * CAM_RIDGES;

// Cam surface height at position X, rotation theta
// Returns radius from cam center
function cam_radius(x, theta) =
    let(helix_phase = cam_phase_at_x(x))
    let(total_phase = helix_phase + theta)
    CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT * max(0, cos(total_phase - 90));

// Layer Z position for wave w, layer l, at rotation angle theta
function layer_z(w, l, theta) =
    let(x = wave_x(w))
    let(phase_offset = layer_phase(l))
    let(effective_theta = theta - phase_offset)
    let(cam_r = cam_radius(x, effective_theta))
    let(lift = cam_r - CAM_CORE_RADIUS)
    FRAME_BASE_Z + SLIDER_HEIGHT/2 + lift;

// ============================================
// QUALITY SETTINGS
// ============================================

$fn = 48;

// ============================================
// VERIFICATION OUTPUTS
// ============================================

echo("============================================");
echo("LAYERED WAVE SYSTEM V2 - PARAMETERS");
echo("============================================");
echo("");
echo(str("Scene: ", SCENE_WIDTH, " x ", SCENE_DEPTH, " x ", SCENE_HEIGHT, " mm"));
echo(str("Waves: ", NUM_WAVES, ", Layers per wave: ", NUM_LAYERS));
echo(str("Total profiles: ", NUM_WAVES * NUM_LAYERS));
echo("");
echo("GUIDE ROD POSITIONS:");
for (w = [0 : NUM_WAVES - 1]) {
    for (l = [0 : NUM_LAYERS - 1]) {
        echo(str("  Wave ", w, " Layer ", l, ": X=", wave_x(w) + GUIDE_OFFSET_X,
                 ", Y=", layer_y(l)));
    }
}
echo("");
echo(str("Cam length: ", CAM_TOTAL_LENGTH, "mm"));
echo(str("Cam radius range: ", CAM_CORE_RADIUS, " - ", CAM_MAX_RADIUS, "mm"));
echo(str("Follower arm length: ", FOLLOWER_ARM_LENGTH, "mm"));
echo("");
echo("PRINT VERIFICATION:");
echo(str("  Guide rod hole: ", GUIDE_ROD_HOLE, "mm (4mm rod + ", TOL_SLIDING, "mm)"));
echo(str("  Bearing pocket: ", BEARING_POCKET_DIA, "mm (22mm OD + 0.1mm)"));
echo(str("  Layer slot: ", MOUNT_TAB_SLOT_WIDTH, "mm (", LAYER_THICKNESS, "mm + ", TOL_LOOSE, "mm)"));
echo("============================================");
