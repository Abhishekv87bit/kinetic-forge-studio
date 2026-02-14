/*
 * WAVE OCEAN V10 - STAGGERED BARREL CAMS + FISH WIRE
 *
 * FINAL DESIGN:
 * - 3 barrel cams, each with X-axis shaft
 * - Staggered in BOTH Y and Z to avoid collision
 * - Fish wire suspension for slat guidance
 * - Channel guides for lateral constraint
 * - True traveling wave per layer (helical cam profile)
 *
 * LAYER ORDER:
 * - Layer 0 = BACK (Y=20, dark blue)
 * - Layer 1 = MID (Y=10, medium blue)
 * - Layer 2 = FRONT (Y=0, light blue)
 *
 * All dimensions in mm
 */

// ============================================
// PRINT TOLERANCES
// ============================================

TOL_CLEARANCE = 0.2;
TOL_SLIDING = 0.3;
TOL_PRESS_FIT = -0.1;

// ============================================
// HARDWARE
// ============================================

BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

SHAFT_DIA = 8;
SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;

M3_HOLE = 3.2;
M3_HEAD_DIA = 5.5;
M4_HOLE = 4.2;

// ============================================
// BARREL CAM DIMENSIONS (COMPACT)
// ============================================

CAM_LENGTH = 180;              // Along X-axis
CAM_MAX_RADIUS = 12;           // Reduced for collision avoidance
CAM_CORE_RADIUS = 5;
CAM_RIDGE_HEIGHT = 7;          // 12-5 = 7mm wave amplitude
CAM_WIDTH = 10;                // Y dimension of cam body

NUM_RIDGES = 2;                // 2 waves per rotation
HELIX_TURNS = NUM_RIDGES;

// ============================================
// STAGGERED CAM POSITIONS (KEY FIX!)
// ============================================

// Cams are offset in BOTH Y and Z to avoid collision
// Each cam is positioned BEHIND its layer (in +Y direction)

// Cam Y positions (behind each layer's slats)
CAM_Y = [30, 15, 0];           // Cam 0 behind Layer 0, etc.

// Cam Z positions (staggered vertically)
CAM_Z = [15, 30, 45];          // 15mm spacing > max radius (12mm)

// Layer Y positions (slat centers)
LAYER_Y_CENTER = [20, 10, 0];  // Back to front

// Follower arm length = distance from slat to cam
// CAM_Y[i] - LAYER_Y_CENTER[i]
FOLLOWER_ARM_Y = [10, 5, 0];   // Layer 0: 30-20=10, Layer 1: 15-10=5, Layer 2: 0-0=0

// ============================================
// SLAT DIMENSIONS (X interlocking preserved)
// ============================================

SLAT_THICKNESS = 2;            // X dimension
SLAT_DEPTH = 10;               // Y dimension
SLAT_BASE_HEIGHT = 35;
SLAT_HEIGHT_VAR = 12;

SLAT_SPACING = 9;              // X spacing (3x thickness for interlocking)
NUM_SLATS = floor(CAM_LENGTH / SLAT_SPACING);  // 20 slats per layer

// X-OFFSET for true finger interlocking
LAYER_X_OFFSET = [0, 3, 6];    // Each layer offset by spacing/3

// Height variation function
function slat_height(i) =
    SLAT_BASE_HEIGHT + SLAT_HEIGHT_VAR *
    (0.5 + 0.3 * sin(i * 45) + 0.2 * sin(i * 90));

// Slat X position with layer offset
function slat_x(i, layer) =
    (i - (NUM_SLATS - 1) / 2) * SLAT_SPACING + LAYER_X_OFFSET[layer];

// ============================================
// FOLLOWER SPECIFICATIONS
// ============================================

FOLLOWER_ROLLER_DIA = 4;
FOLLOWER_ROLLER_WIDTH = 3;
FOLLOWER_ARM_DIA = 2;

// ============================================
// WIRE SUSPENSION
// ============================================

WIRE_DIA = 0.35;
WIRE_HOLE_DIA = 1.0;           // Through slat top
WIRE_LENGTH = 65;              // Cut length per wire

// ============================================
// GUIDE SYSTEM (Channel combs)
// ============================================

CHANNEL_WIDTH = SLAT_THICKNESS + 0.5;  // 2.5mm
CHANNEL_DEPTH = 3;             // Captures slat sides
CHANNEL_HEIGHT = 60;           // Guide length
CHANNEL_WALL = 1.5;            // Wall thickness

// ============================================
// TOP RAIL (Wire attachment)
// ============================================

TOP_RAIL_Z = 100;              // Height above base
TOP_RAIL_WIDTH = 15;           // Y dimension
TOP_RAIL_HEIGHT = 8;           // Z dimension
TOP_RAIL_LENGTH = CAM_LENGTH + 40;  // X dimension

// Rail Y positions
FRONT_RAIL_Y = -5;             // In front of Layer 2
BACK_RAIL_Y = 25;              // Behind Layer 0

// ============================================
// FRAME STRUCTURE
// ============================================

BASE_LENGTH = CAM_LENGTH + 60;  // X
BASE_WIDTH = 60;                // Y (spans all cam Y positions)
BASE_THICKNESS = 10;            // Z

COLUMN_WIDTH = 12;
COLUMN_DEPTH = 12;
COLUMN_HEIGHT = TOP_RAIL_Z;

// Column X positions
COLUMN_X = [-CAM_LENGTH/2 - 10, CAM_LENGTH/2 + 10];

// ============================================
// BEARING BLOCK (holds 3 staggered shafts)
// ============================================

BB_WIDTH = 30;                  // X dimension
BB_DEPTH = 50;                  // Y dimension (spans all cam Y positions)
BB_HEIGHT = 60;                 // Z dimension (spans all cam Z positions)

BB_LEFT_X = -CAM_LENGTH/2 - BB_WIDTH/2 - 5;
BB_RIGHT_X = CAM_LENGTH/2 + BB_WIDTH/2 + 5;

// ============================================
// SHAFT LENGTH
// ============================================

SHAFT_LENGTH = CAM_LENGTH + BB_WIDTH * 2 + 40;

// ============================================
// PHASE OFFSETS (between layers)
// ============================================

LAYER_PHASE_OFFSET = [0, 40, 80];  // Cascading wave effect

// ============================================
// PHASE CALCULATION (for traveling wave)
// ============================================

function slat_phase(i, layer, theta) =
    let(x = slat_x(i, layer))
    let(helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    helix_angle + theta + LAYER_PHASE_OFFSET[layer];

function cam_surface_at_slat(i, layer, theta) =
    let(phase = slat_phase(i, layer, theta))
    CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(phase));

function slat_z(i, layer, theta) =
    CAM_Z[layer] + cam_surface_at_slat(i, layer, theta);

// ============================================
// LAYER CONFIGURATION
// ============================================

NUM_LAYERS = 3;

// Colors (back=dark, front=light)
LAYER_COLORS = [
    [0.08, 0.25, 0.50],      // Layer 0 (back) - dark blue
    [0.15, 0.40, 0.65],      // Layer 1 (mid) - medium blue
    [0.25, 0.55, 0.80]       // Layer 2 (front) - light blue
];

function slat_color(layer) = LAYER_COLORS[layer];

// ============================================
// COMPONENT COLORS
// ============================================

C_CAM = [0.65, 0.5, 0.3];
C_BB = [0.35, 0.35, 0.4];
C_SHAFT = [0.6, 0.6, 0.65];
C_FRAME = [0.25, 0.22, 0.20];
C_RAIL = [0.4, 0.35, 0.30];
C_GUIDE = [0.3, 0.3, 0.35];
C_WIRE = [0.7, 0.7, 0.75];
C_FOLLOWER = [0.5, 0.45, 0.4];

// ============================================
// QUALITY
// ============================================

$fn = 48;

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("============================================");
echo("  STAGGERED BARREL CAM WAVE SYSTEM");
echo("============================================");
echo("");
echo("CAM POSITIONS (staggered Y + Z):");
echo(str("  Cam 0: Y=", CAM_Y[0], "mm, Z=", CAM_Z[0], "mm (back)"));
echo(str("  Cam 1: Y=", CAM_Y[1], "mm, Z=", CAM_Z[1], "mm (mid)"));
echo(str("  Cam 2: Y=", CAM_Y[2], "mm, Z=", CAM_Z[2], "mm (front)"));
echo("");
echo("COLLISION CHECK:");
echo(str("  Cam max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("  Z spacing: ", CAM_Z[1] - CAM_Z[0], "mm"));
echo(str("  Gap: ", (CAM_Z[1] - CAM_Z[0]) - CAM_MAX_RADIUS, "mm (should be > 0)"));
echo("");
echo("LAYER POSITIONS:");
echo(str("  Layer 0 (back):  Y=", LAYER_Y_CENTER[0], "mm"));
echo(str("  Layer 1 (mid):   Y=", LAYER_Y_CENTER[1], "mm"));
echo(str("  Layer 2 (front): Y=", LAYER_Y_CENTER[2], "mm"));
echo("");
echo("FOLLOWER ARM LENGTHS:");
echo(str("  Layer 0: ", FOLLOWER_ARM_Y[0], "mm"));
echo(str("  Layer 1: ", FOLLOWER_ARM_Y[1], "mm"));
echo(str("  Layer 2: ", FOLLOWER_ARM_Y[2], "mm"));
echo("");
echo("INTERLOCKING:");
echo(str("  LAYER_X_OFFSET: ", LAYER_X_OFFSET, "mm"));
echo(str("  Slat thickness: ", SLAT_THICKNESS, "mm"));
echo(str("  Slat spacing: ", SLAT_SPACING, "mm"));
echo(str("  Gap between slats: ", SLAT_SPACING/3 - SLAT_THICKNESS, "mm"));
echo("");
echo(str("Slats per layer: ", NUM_SLATS));
echo(str("Total slats: ", NUM_SLATS * NUM_LAYERS));
