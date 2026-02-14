/*
 * WAVE OCEAN V10 - 3-LAYER TRUE INTERLOCKING DESIGN
 *
 * CRITICAL FIX: Slats now have X-OFFSET per layer
 * Like interlocked fingers - each layer's slats fit IN THE GAPS
 *
 * LAYER ORDER (reversed):
 * - Layer 0 = BACK (Y=20, dark blue, has back tabs)
 * - Layer 1 = MID (Y=10, medium blue)
 * - Layer 2 = FRONT (Y=0, light blue, closest to viewer)
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
// SLAT DIMENSIONS - CORRECTED FOR INTERLOCKING
// ============================================

SLAT_THICKNESS = 2;          // X dimension - REDUCED for gaps
SLAT_DEPTH = 10;             // Y dimension
SLAT_BASE_HEIGHT = 35;
SLAT_HEIGHT_VAR = 12;

// SPACING - Must be 3x thickness for 3-layer interlocking
SLAT_SPACING = 9;            // INCREASED from 5mm
CAM_LENGTH = 180;
NUM_SLATS = floor(CAM_LENGTH / SLAT_SPACING);  // 20 slats per layer

// Height variation
function slat_height(i) =
    SLAT_BASE_HEIGHT + SLAT_HEIGHT_VAR *
    (0.5 + 0.3 * sin(i * 45) + 0.2 * sin(i * 90));

// ============================================
// X-OFFSET - THE KEY TO TRUE INTERLOCKING
// ============================================

// Each layer offset by spacing/3 = 3mm
LAYER_X_OFFSET = [0, 3, 6];

// Slat X position - NOW INCLUDES LAYER OFFSET
function slat_x(i, layer) =
    (i - (NUM_SLATS - 1) / 2) * SLAT_SPACING + LAYER_X_OFFSET[layer];

/*
 * INTERLOCKING GEOMETRY:
 *
 * With SLAT_THICKNESS=2mm and SLAT_SPACING=9mm:
 *
 * Layer 0: X = 0, 9, 18...  (slats occupy X-1 to X+1)
 * Layer 1: X = 3, 12, 21... (slats occupy X+2 to X+4)
 * Layer 2: X = 6, 15, 24... (slats occupy X+5 to X+7)
 *
 * Gap between adjacent slats = 1mm (safe!)
 */

// ============================================
// LAYER CONFIGURATION - REVERSED ORDER
// ============================================

NUM_LAYERS = 3;

// Layer Y positions (REVERSED: 0=back, 2=front)
LAYER_Y_CENTER = [20, 10, 0];  // Back to front

// Colors (back=dark, front=light)
LAYER_COLORS = [
    [0.08, 0.25, 0.50],      // Layer 0 (back) - dark blue
    [0.15, 0.40, 0.65],      // Layer 1 (mid) - medium blue
    [0.25, 0.55, 0.80]       // Layer 2 (front) - light blue
];

// ============================================
// CAM CONFIGURATION
// ============================================

CAM_WIDTH = 8;               // Y dimension - thin
CAM_CORE_RADIUS = 6;
CAM_RIDGE_HEIGHT = 8;
CAM_MAX_RADIUS = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT;  // 14mm

// Cam Y positions (match layer Y positions)
CAM_Y = [20, 10, 0];         // Same as LAYER_Y_CENTER

NUM_RIDGES = 2;
HELIX_TURNS = NUM_RIDGES;

// ============================================
// PHASE OFFSETS - CASCADING WAVE
// ============================================

// Layer 0 (back) leads, Layer 2 (front) follows
LAYER_PHASE_OFFSET = [0, 40, 80];

// ============================================
// PHASE CALCULATION
// ============================================

function slat_phase(i, layer, theta) =
    let(x = slat_x(i, layer))
    let(helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    helix_angle + theta + LAYER_PHASE_OFFSET[layer];

function cam_surface_at_slat(i, layer, theta) =
    let(phase = slat_phase(i, layer, theta))
    CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(phase));

function slat_z(i, layer, theta) =
    CAM_CENTER_Z + cam_surface_at_slat(i, layer, theta);

// ============================================
// HINGE CONFIGURATION
// ============================================

HINGE_HEIGHT_FROM_BOTTOM = 20;
HINGE_ROD_DIA = 1.6;             // Reduced from 2mm for less binding risk
HINGE_SLOT_LENGTH = 15;
HINGE_SLOT_WIDTH = HINGE_ROD_DIA + TOL_SLIDING;

// ============================================
// BACKPLATE CONFIGURATION (for Layer 0 = BACK)
// ============================================

BACKPLATE_Y = LAYER_Y_CENTER[0] + SLAT_DEPTH/2 + 5;  // Behind Layer 0 (Y > 25)
BACKPLATE_WIDTH = CAM_LENGTH + 20;
BACKPLATE_HEIGHT = 70;
BACKPLATE_THICKNESS = 8;

// Back tab (on Layer 0 slats)
TAB_THICKNESS = SLAT_THICKNESS;
TAB_DEPTH = 6;
TAB_HEIGHT = 25;

GROOVE_WIDTH = TAB_THICKNESS + TOL_SLIDING;
GROOVE_DEPTH = TAB_DEPTH + 2;

// ============================================
// FOLLOWER
// ============================================

FOLLOWER_HEIGHT = 4;
FOLLOWER_CURVE_RADIUS = CAM_CORE_RADIUS + 1;

// ============================================
// ASSEMBLY POSITIONS
// ============================================

BB_WIDTH = 24;
BB_DEPTH = 30;  // Wider to span all 3 cam Y positions
BB_HEIGHT = CAM_MAX_RADIUS + 6;

BEARING_POCKET_DIA = BEARING_608_OD - TOL_PRESS_FIT;
BEARING_POCKET_DEPTH = BEARING_608_H + 0.5;

CAM_CENTER_Z = BB_HEIGHT;

BB_LEFT_X = -CAM_LENGTH / 2 - BB_WIDTH / 2 - 5;
BB_RIGHT_X = CAM_LENGTH / 2 + BB_WIDTH / 2 + 5;

SHAFT_LENGTH = CAM_LENGTH + BB_WIDTH * 2 + 40;

// ============================================
// COLORS
// ============================================

C_CAM = [0.65, 0.5, 0.3];
C_BACKPLATE = [0.2, 0.18, 0.15];
C_BB = [0.35, 0.35, 0.4];
C_SHAFT = [0.6, 0.6, 0.65];
C_FRAME = [0.25, 0.22, 0.20];
C_HINGE = [0.5, 0.5, 0.55];

function slat_color(layer) = LAYER_COLORS[layer];

// ============================================
// QUALITY
// ============================================

$fn = 48;

// ============================================
// VERIFICATION
// ============================================

echo("============================================");
echo("  TRUE INTERLOCKING WAVE DESIGN");
echo("============================================");
echo("");
echo("INTERLOCKING (X-OFFSET per layer):");
echo(str("  LAYER_X_OFFSET: ", LAYER_X_OFFSET, "mm"));
echo(str("  Slat thickness: ", SLAT_THICKNESS, "mm"));
echo(str("  Slat spacing: ", SLAT_SPACING, "mm"));
echo(str("  Gap between slats: ", SLAT_SPACING/3 - SLAT_THICKNESS, "mm"));
echo("");
echo("LAYER ORDER (reversed):");
echo(str("  Layer 0 (BACK): Y=", LAYER_Y_CENTER[0], "mm, has back tabs"));
echo(str("  Layer 1 (MID):  Y=", LAYER_Y_CENTER[1], "mm"));
echo(str("  Layer 2 (FRONT): Y=", LAYER_Y_CENTER[2], "mm"));
echo("");
echo(str("Slats per layer: ", NUM_SLATS));
echo(str("Total slats: ", NUM_SLATS * NUM_LAYERS));
