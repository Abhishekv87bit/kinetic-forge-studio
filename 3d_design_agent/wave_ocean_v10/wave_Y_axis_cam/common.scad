/*
 * WAVE OCEAN - Y-AXIS BARREL CAM SYSTEM
 * CORRECT GEOMETRY FOR TRAVELING WAVE
 *
 * COORDINATE SYSTEM:
 * - X: Along slat row (left-right) - WAVE TRAVELS THIS DIRECTION
 * - Y: Front-back (viewer at -Y) - CAM SHAFT AXIS
 * - Z: Up-down (gravity in -Z)
 *
 * KEY INSIGHT:
 * For a traveling wave, the cam shaft must be PERPENDICULAR to the slat row.
 * Shaft along Y-axis, slats along X-axis.
 * As cam rotates around Y, the helical ridge peak travels along X.
 *
 * All dimensions in mm
 */

// ============================================
// PRINT TOLERANCES
// ============================================

TOL_CLEARANCE = 0.2;
TOL_SLIDING = 0.3;

// ============================================
// HARDWARE
// ============================================

// 608 Bearing
BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

// Shaft (along Y-axis)
SHAFT_DIA = 8;
SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;

// ============================================
// SLAT CONFIGURATION
// ============================================

// Slat dimensions
SLAT_THICKNESS = 3;           // X dimension
SLAT_DEPTH = 10;              // Y dimension
SLAT_BASE_HEIGHT = 35;        // Z - minimum height
SLAT_HEIGHT_VAR = 15;         // Height variation

// Spacing
SLAT_SPACING = 5;             // Center-to-center along X
NUM_SLATS = 36;               // Per layer
SLAT_ROW_LENGTH = NUM_SLATS * SLAT_SPACING;  // 180mm

// Height variation using golden ratio
GOLDEN_ANGLE = 137.5077;
function slat_height(i) =
    let(
        primary = sin(i * GOLDEN_ANGLE),
        secondary = sin(i * GOLDEN_ANGLE * 0.618) * 0.4,
        combined = (primary + secondary + 1.4) / 2.8
    )
    SLAT_BASE_HEIGHT + SLAT_HEIGHT_VAR * combined;

// Slat X position (centered)
function slat_x(i) = (i - (NUM_SLATS - 1) / 2) * SLAT_SPACING;

// ============================================
// LAYER CONFIGURATION
// ============================================

NUM_LAYERS = 3;
LAYER_SPACING = 12;           // Y spacing between layers

// Layer Y positions (front to back)
LAYER_Y = [
    -LAYER_SPACING,           // Layer 0 (front): Y = -12
    0,                        // Layer 1 (mid):   Y = 0
    LAYER_SPACING             // Layer 2 (back):  Y = +12
];

// Ridge heights per layer (different amplitudes)
LAYER_RIDGE_HEIGHT = [4, 7, 10];  // Front=small, Mid=medium, Back=large

// Layer colors (front=dark, back=light for depth)
LAYER_COLORS = [
    [0.08, 0.25, 0.50],       // Dark blue (front)
    [0.15, 0.40, 0.65],       // Medium blue
    [0.25, 0.55, 0.80]        // Light blue (back)
];

// ============================================
// CAM CONFIGURATION
// ============================================

// Cam extends along X (same length as slat row)
CAM_LENGTH = SLAT_ROW_LENGTH;  // 180mm along X
CAM_CORE_RADIUS = 15;          // Minimum radius
CAM_WIDTH = 10;                // Y dimension of each cam section

// Helix: number of complete waves visible
HELIX_TURNS = 2;

// Maximum radius (core + largest ridge)
CAM_MAX_RADIUS = CAM_CORE_RADIUS + max(LAYER_RIDGE_HEIGHT);  // 25mm

// ============================================
// CAM SURFACE CALCULATION
// ============================================

// The key formula for traveling wave:
// At position X along cam, the phase depends on X.
// As cam rotates (theta increases), the "peak" of the wave travels along X.

function cam_surface_z(x, layer, theta) =
    let(
        // Helix angle at this X position
        helix_angle = (x / CAM_LENGTH + 0.5) * 360 * HELIX_TURNS,
        // Effective angle (theta - helix creates traveling effect)
        effective_angle = theta - helix_angle,
        // Ridge height for this layer
        ridge = LAYER_RIDGE_HEIGHT[layer],
        // Cam surface: cosine wave
        surface = CAM_CORE_RADIUS + ridge * (0.5 + 0.5 * cos(effective_angle))
    )
    surface;

// ============================================
// SLAT Z POSITION
// ============================================

FOLLOWER_HEIGHT = 3;          // Height of follower pad
CAM_CENTER_Z = 30;            // Height of cam shaft axis

function slat_z(i, layer, theta) =
    let(
        x = slat_x(i),
        cam_top = cam_surface_z(x, layer, theta)
    )
    CAM_CENTER_Z + cam_top + FOLLOWER_HEIGHT;

// ============================================
// ASSEMBLY POSITIONS
// ============================================

// Bearing mounts at front and back of cam stack
MOUNT_Y_FRONT = LAYER_Y[0] - CAM_WIDTH/2 - 15;   // ~-27
MOUNT_Y_BACK = LAYER_Y[2] + CAM_WIDTH/2 + 15;    // ~+27

// Shaft length
SHAFT_LENGTH = MOUNT_Y_BACK - MOUNT_Y_FRONT + 60;  // Extra for motor

// ============================================
// COLORS
// ============================================

C_CAM = [0.65, 0.5, 0.3];
C_SHAFT = [0.6, 0.6, 0.65];
C_MOUNT = [0.3, 0.3, 0.35];
C_FRAME = [0.25, 0.25, 0.28];

// ============================================
// QUALITY
// ============================================

$fn = 48;

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("============================================");
echo("  Y-AXIS BARREL CAM - TRAVELING WAVE");
echo("============================================");
echo("");
echo("GEOMETRY:");
echo(str("  Slat row along X: ", SLAT_ROW_LENGTH, "mm"));
echo(str("  Slats per layer: ", NUM_SLATS));
echo(str("  Layers: ", NUM_LAYERS, " at Y = ", LAYER_Y));
echo("");
echo("CAM:");
echo(str("  Shaft axis: Y (perpendicular to slat row)"));
echo(str("  Cam length: ", CAM_LENGTH, "mm along X"));
echo(str("  Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("  Ridge heights: ", LAYER_RIDGE_HEIGHT, "mm"));
echo(str("  Helix turns: ", HELIX_TURNS, " = ", HELIX_TURNS, " waves visible"));
echo("");
echo("WAVE BEHAVIOR:");
echo("  As cam rotates around Y, the peak travels along X.");
echo("  This creates a TRUE traveling wave effect.");
