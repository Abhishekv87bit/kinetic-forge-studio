/*
 * COMMON.SCAD - Whack-a-Mole Box Design (V3)
 *
 * CONCEPT: Box with slits on top. Slats sit in slits (guidance built-in).
 * Cams hidden underneath push slats up - like arcade whack-a-mole.
 *
 * KEY FIX: Phase offsets EMBEDDED in cam geometry (not just animation)
 */

$fn = 48;

// ============================================
// BOX DIMENSIONS
// ============================================

BOX_LENGTH = 200;          // X - spans all slats
BOX_WIDTH = 50;            // Y - fits 3 cam rows
BOX_HEIGHT = 60;           // Z - cam radius + clearance
WALL_THICKNESS = 5;

FLOOR_Z = BOX_HEIGHT;      // Top of box = slat emergence point

// ============================================
// SLAT PARAMETERS
// ============================================

NUM_LAYERS = 3;
NUM_SLATS = 20;            // Per layer

SLAT_THICKNESS = 2;        // X dimension
SLAT_DEPTH = 10;           // Y dimension
SLAT_VISIBLE_HEIGHT = 50;  // Z - portion above floor
SLAT_BELOW_FLOOR = 35;     // Z - portion inside box (contacts cam)
SLAT_TOTAL_HEIGHT = SLAT_VISIBLE_HEIGHT + SLAT_BELOW_FLOOR;

SLAT_SPACING = 9;          // X spacing between slats in same layer

// X-OFFSET for interlocking (slats from different layers interleave)
LAYER_X_OFFSET = [0, 3, 6];

// ============================================
// FLOOR SLIT PARAMETERS
// ============================================

// Shared slit configuration - all 3 layers use same slit bank
SLIT_WIDTH = 2.2;          // X - slat thickness + clearance
SLIT_LENGTH = 35;          // Y - spans all 3 layer Y positions
SLIT_FLOOR_THICKNESS = 5;  // Structural thickness of floor plate

// ============================================
// LAYER Y POSITIONS (front to back)
// ============================================

// Layer 2 = front (Y=0), Layer 0 = back (Y=20)
// These are RELATIVE positions (used for calculations)
LAYER_Y_CENTER = [20, 10, 0];  // Back, mid, front

// ============================================
// ABSOLUTE BOX COORDINATES
// ============================================
// Box spans Y from 0 to BOX_WIDTH (0 to 50mm)
// These are the ACTUAL Y positions inside the box

// Layer positions in box coordinates (Y=0 is front wall, Y=50 is back wall)
LAYER_Y_BOX = [45, 35, 25];  // Layer 0 (back), Layer 1 (mid), Layer 2 (front)

// Cam Y positions - same as layer positions (cam directly below each layer's slats)
CAM_Y_BOX = [45, 35, 25];    // Matches LAYER_Y_BOX

// ============================================
// BARREL CAM PARAMETERS
// ============================================

CAM_LENGTH = 180;          // X - spans slat array
CAM_MAX_RADIUS = 12;       // Maximum radius at ridge peak
CAM_MIN_RADIUS = 5;        // Core radius
CAM_RIDGE_HEIGHT = CAM_MAX_RADIUS - CAM_MIN_RADIUS;  // 7mm amplitude
HELIX_TURNS = 2;           // Number of wave cycles along cam length

// Cam positions (INSIDE BOX, staggered in Y and Z)
// Each cam directly below its layer's slats
CAM_Y = [20, 10, 0];       // Same as LAYER_Y_CENTER

// Z positions staggered to avoid collision
// Gap = 12mm between each (cam diameter 24mm total)
CAM_Z = [15, 27, 39];      // Back lowest, front highest

// ============================================
// PHASE OFFSETS - EMBEDDED IN CAM GEOMETRY
// ============================================

// This is the KEY FIX: phase offset baked into cam shape
// NOT applied at animation time - physically different cams!
LAYER_PHASE_OFFSET = [0, 40, 80];  // degrees

// ============================================
// SHAFT PARAMETERS
// ============================================

SHAFT_DIA = 8;
SHAFT_LENGTH = 220;        // Extends past box for bearings/pulleys

BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

// ============================================
// HELPER FUNCTIONS
// ============================================

// Slat X position (with layer interlocking offset)
function slat_x(i, layer) =
    (i - (NUM_SLATS - 1) / 2) * SLAT_SPACING + LAYER_X_OFFSET[layer];

// Slat Z position based on cam rotation
// This calculates where the slat bottom rests on the cam surface
function slat_z(i, layer, theta) =
    let(
        x = slat_x(i, layer),
        // Helix phase based on X position + layer phase offset (EMBEDDED)
        helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS,
        // Animation rotation + embedded layer offset
        phase = helix_angle + theta + LAYER_PHASE_OFFSET[layer],
        // Cam surface height at this phase
        cam_height = CAM_MIN_RADIUS + CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(phase))
    )
    // Slat bottom sits on cam, slat extends upward
    FLOOR_Z - SLAT_BELOW_FLOOR + (CAM_Z[layer] + cam_height);

// Slat height varies for visual interest (wave-like appearance)
function slat_height(i) =
    SLAT_TOTAL_HEIGHT + 5 * sin(i * 20);

// ============================================
// COLORS
// ============================================

// Slat colors - darker in back, lighter in front
function slat_color(layer) =
    layer == 0 ? [0.08, 0.25, 0.50] :   // Back - dark blue
    layer == 1 ? [0.15, 0.40, 0.65] :   // Mid - medium blue
                 [0.25, 0.55, 0.80];    // Front - light blue

C_BOX = [0.9, 0.85, 0.75];       // Warm wood color
C_FLOOR = [0.85, 0.80, 0.70];    // Slightly darker floor
C_CAM = [0.7, 0.5, 0.3];         // Brown cam
C_SHAFT = [0.7, 0.7, 0.7];       // Steel shaft

// ============================================
// TOLERANCES
// ============================================

TOL_CLEARANCE = 0.2;       // General clearance
TOL_PRESS_FIT = 0.1;       // Press fit tolerance
SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;

// ============================================
// HARDWARE SIZES
// ============================================

M3_HOLE = 3.2;
M4_HOLE = 4.2;

// ============================================
// ECHO PARAMETERS
// ============================================

echo("=== WHACK-A-MOLE BOX V3 ===");
echo(str("Box: ", BOX_LENGTH, " x ", BOX_WIDTH, " x ", BOX_HEIGHT, "mm"));
echo(str("Floor Z: ", FLOOR_Z, "mm"));
echo("");
echo("SLATS:");
echo(str("  Count: ", NUM_SLATS, " per layer x ", NUM_LAYERS, " layers = ", NUM_SLATS * NUM_LAYERS));
echo(str("  Dimensions: ", SLAT_THICKNESS, " x ", SLAT_DEPTH, " x ", SLAT_TOTAL_HEIGHT, "mm"));
echo(str("  Spacing: ", SLAT_SPACING, "mm"));
echo(str("  X offsets: ", LAYER_X_OFFSET));
echo("");
echo("CAMS:");
echo(str("  Length: ", CAM_LENGTH, "mm"));
echo(str("  Radius: ", CAM_MIN_RADIUS, " to ", CAM_MAX_RADIUS, "mm"));
echo(str("  Y positions: ", CAM_Y));
echo(str("  Z positions: ", CAM_Z));
echo("");
echo("PHASE OFFSETS (EMBEDDED IN GEOMETRY):");
echo(str("  Layer 0 (back):  ", LAYER_PHASE_OFFSET[0], " deg"));
echo(str("  Layer 1 (mid):   ", LAYER_PHASE_OFFSET[1], " deg"));
echo(str("  Layer 2 (front): ", LAYER_PHASE_OFFSET[2], " deg"));
