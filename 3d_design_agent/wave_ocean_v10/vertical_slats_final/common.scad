/*
 * WAVE OCEAN V10 - VERTICAL SLAT SYSTEM
 * ENGINEERING GRADE DESIGN - CORRECTED GEOMETRY
 *
 * COORDINATE SYSTEM:
 * - X: Left-Right (along cam axis)
 * - Y: Front-Back (viewer at -Y looking toward +Y)
 * - Z: Up-Down (gravity in -Z)
 *
 * SPATIAL LAYOUT (side view, looking from +X):
 *
 *        SLAT (front)     CAM (center)     BACKPLATE (back)
 *             |               |                  |
 *     Y: -30            0                  +30
 *
 * The cam rotates around X-axis. Its ridges sweep in Y-Z plane.
 * Slats are in FRONT of cam, contact TOP of cam surface.
 * Backplate is BEHIND cam, provides groove guidance for slat tabs.
 */

// ============================================
// PRINT TOLERANCES (FDM, 0.4mm nozzle)
// ============================================

TOL_TIGHT = 0.15;            // Press fit (bearing in pocket)
TOL_SLIDING = 0.4;           // Sliding fit (slat in groove)
TOL_CLEARANCE = 0.3;         // Clearance fit (shaft in hole)
TOL_LOOSE = 0.5;             // Loose fit (easy assembly)

// ============================================
// HARDWARE - 608 BEARING
// ============================================

BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

// Bearing pocket (press fit - slightly smaller)
BEARING_POCKET_DIA = BEARING_608_OD - TOL_TIGHT;  // 21.85mm
BEARING_POCKET_DEPTH = BEARING_608_H + 0.3;        // 7.3mm

// ============================================
// HARDWARE - SHAFT
// ============================================

SHAFT_DIA = 8;
SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;  // 8.3mm

// ============================================
// HARDWARE - FASTENERS
// ============================================

M3_DIA = 3;
M3_HOLE = M3_DIA + TOL_CLEARANCE;        // 3.3mm
M3_HEAD_DIA = 5.5;
M3_HEAD_H = 3;

M4_DIA = 4;
M4_HOLE = M4_DIA + TOL_CLEARANCE;        // 4.3mm
M4_HEAD_DIA = 7;
M4_HEAD_H = 4;
M4_NUT_FLAT = 7;
M4_NUT_H = 3.2;

// ============================================
// CAM DESIGN - 3 SEPARATE CAMS on Shared Shaft
// ============================================
// Each layer has its own cam barrel at its Y position
// All 3 cams share the same shaft (X axis)
// Different ridge heights create varying wave amplitudes
//
// COLLISION-FREE GEOMETRY:
// - Layer spacing: 15mm center-to-center
// - Cam width: 12mm each
// - Gap between cams: 3mm (15 - 12 = 3)

CAM_LENGTH = 180;                         // Active length (X direction)
CAM_CORE_RADIUS = 12;                     // Minimum radius (shaft clearance + strength)

// Per-layer ridge heights (back bigger, front smaller)
// Layer 0 (front, Y=-15): small amplitude = small waves
// Layer 1 (mid, Y=0): medium amplitude = medium waves
// Layer 2 (back, Y=+15): large amplitude = large waves
LAYER_RIDGE_HEIGHT = [4, 7, 10];          // mm - front/mid/back

// Cam dimensions - MUST NOT EXCEED layer spacing to avoid collision
CAM_WIDTH = 12;                           // Y dimension of each cam (12mm)
CAM_GAP = 3;                              // Gap between adjacent cams (3mm)
CAM_DISC_THICKNESS = CAM_WIDTH;           // Alias for backwards compatibility

// Maximum radius (for bearing block clearance calculations)
CAM_MAX_RADIUS = CAM_CORE_RADIUS + max(LAYER_RIDGE_HEIGHT[0], LAYER_RIDGE_HEIGHT[1], LAYER_RIDGE_HEIGHT[2]);  // 22mm

// Legacy compatibility
CAM_RIDGE_HEIGHT = LAYER_RIDGE_HEIGHT[1]; // Use mid layer for legacy code

// Traveling wave: 2 ridges per cam
NUM_RIDGES = 2;
HELIX_TURNS = NUM_RIDGES;

// End caps
CAM_END_CAP = 4;
CAM_TOTAL_LENGTH = CAM_LENGTH + 2 * CAM_END_CAP;  // 188mm

// ============================================
// 3-LAYER WAVE SYSTEM
// ============================================
// Three wave layers at different Y depths create parallax effect
// Each layer has its own cam section on the shared shaft

NUM_LAYERS = 3;

// Y positions (front to back) - COMPACT to fit within cam sweep
// Layer 0 = front (closest to viewer)
// Layer 2 = back (furthest from viewer)
// Cam radius 22mm reaches Y = ±22mm, so layers must be within that
LAYER_Y_SPACING = 15;                             // Gap between layers (compact)
LAYER_Y_OFFSET = [                                // Y position of each layer
    -LAYER_Y_SPACING,                             // Front: Y = -15mm
    0,                                            // Mid:   Y = 0mm
    LAYER_Y_SPACING                               // Back:  Y = +15mm
];

// Height scaling (front taller, back shorter for perspective)
LAYER_HEIGHT_SCALE = [1.0, 0.75, 0.5];            // Front=100%, Mid=75%, Back=50%

// Phase offsets (adjustable for wave motion tuning)
// Positive = leads, Negative = lags
LAYER_PHASE_OFFSET = [0, 30, 60];                 // Degrees - cascade front to back

// Colors per layer (front dark, back light)
LAYER_COLORS = [
    [0.08, 0.25, 0.50],                           // Front: dark blue
    [0.15, 0.40, 0.65],                           // Mid: medium blue
    [0.25, 0.55, 0.80]                            // Back: light blue
];

// Cam section lengths (one section per layer)
CAM_SECTION_LENGTH = CAM_LENGTH / NUM_LAYERS;     // 60mm each
CAM_SECTION_GAP = 5;                              // Gap between sections for visual separation

// ============================================
// SLAT DESIGN - Thin overlapping slats
// ============================================

SLAT_THICKNESS = 3;                       // X dimension (width)
SLAT_DEPTH = 10;                          // Y dimension (thin for overlap)
SLAT_BASE_HEIGHT = 50;                    // Z - visible wave height
SLAT_HEIGHT_VAR = 20;                     // Height variation (increased for drama)

// Layer overlap - slats from adjacent layers overlap in Y
SLAT_OVERLAP = 5;                         // mm of overlap between layers
// With LAYER_Y_SPACING=15 and SLAT_DEPTH=10, overlap = 15-10 = 5mm gap
// To get actual overlap, layers need: LAYER_Y_SPACING < SLAT_DEPTH
// Current: 15mm spacing, 10mm depth = 5mm gap (no overlap yet)
// For 5mm overlap: effective reach = SLAT_DEPTH/2 from each side

// Spacing
SLAT_GAP = 2;
SLAT_SPACING = SLAT_THICKNESS + SLAT_GAP; // 5mm center-to-center
NUM_SLATS = floor(CAM_LENGTH / SLAT_SPACING);  // 36 slats

// ============================================
// SLAT FOLLOWER (contacts cam)
// ============================================

// Follower is a small foot at bottom-back of slat
// It rides on TOP of the cam surface
FOLLOWER_WIDTH = SLAT_THICKNESS - 0.5;    // Slightly narrower
FOLLOWER_LENGTH = 15;                      // Along Y (front-back)
FOLLOWER_HEIGHT = 5;                       // Thickness of follower pad

// ============================================
// SLAT GUIDANCE (self-aligning, no mechanical guides)
// ============================================
// Slats self-align through:
// - Overlap between adjacent layers (constrains Y)
// - Cam follower contact + gravity (constrains Z)
// - Cam end caps (constrain X at edges)
//
// No snap-fit, no backplate tabs, no T-slots needed.

// ============================================
// SPATIAL POSITIONS
// ============================================

// BASE PLATE (thin - no guidance grooves needed)
BASE_PLATE_HEIGHT = 8;                    // Simple structural support

// BEARING BLOCKS sit on pedestals on base plate
BB_WIDTH = 30;
BB_DEPTH = 35;
BB_HEIGHT = 35;                           // Shaft at top of block

// Pedestal raises bearing blocks above base plate
BB_PEDESTAL_HEIGHT = 25;                  // Height of pedestal
BB_Z = BASE_PLATE_HEIGHT + BB_PEDESTAL_HEIGHT;  // Bottom of bearing block (~33mm)
CAM_CENTER_Z = BB_Z + BB_HEIGHT;          // Cam centerline height (~68mm)

// Bearing block X positions (outside cam)
BB_LEFT_X = -CAM_TOTAL_LENGTH/2 - BB_WIDTH/2 - 5;   // ~-114mm
BB_RIGHT_X = CAM_TOTAL_LENGTH/2 + BB_WIDTH/2 + 5;    // ~+114mm

// CAM sweeps Y = -CAM_MAX_RADIUS to +CAM_MAX_RADIUS = ±22mm
// Slats must be positioned so follower contacts TOP of cam

// SLAT Y position: Centered at Y = 0
// Slat front face at Y = -SLAT_DEPTH/2 = -12.5mm
// Slat back face at Y = +SLAT_DEPTH/2 = +12.5mm
// Follower extends from back of slat toward cam center
SLAT_Y = 0;

// BACKPLATE: Behind the cam's sweep area
// Cam reaches Y = +22mm at max, add clearance
BACKPLATE_Y_FRONT = CAM_MAX_RADIUS + 5;   // 27mm - front face of backplate
BACKPLATE_THICKNESS = 15;
BACKPLATE_WIDTH = CAM_LENGTH + 40;        // 220mm
BACKPLATE_HEIGHT = 100;                   // Full height for tab travel

// BACKPLATE GROOVES - DEPRECATED
// Self-aligning slats don't use backplate tabs/grooves
// Keeping commented for reference if needed later
// TAB_THICKNESS = 3;
// TAB_DEPTH = 25;
// GROOVE_WIDTH = TAB_THICKNESS + 0.5;
// GROOVE_DEPTH = TAB_DEPTH + 2;

// ============================================
// SLAT POSITION FUNCTIONS (SINGLE LAYER - legacy)
// ============================================

// X position of slat i (centered on cam)
function slat_x(i) = (i - (NUM_SLATS - 1) / 2) * SLAT_SPACING;

// Phase angle at slat i based on X position
function slat_phase(i, theta) =
    let(x = slat_x(i))
    let(helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    helix_angle + theta;

// Cam surface height at position (relative to cam center)
function cam_top_z_at(i, theta) =
    let(phase = slat_phase(i, theta))
    let(angle_at_top = 90)
    let(r = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(angle_at_top - phase)))
    r;

// Slat Z position (bottom of slat body)
function slat_z(i, theta) =
    CAM_CENTER_Z + cam_top_z_at(i, theta) + FOLLOWER_HEIGHT;

// Slat height - GOLDEN RATIO variation for organic look
// Uses golden angle (137.5°) to create non-repeating pattern
GOLDEN_ANGLE = 137.5077;  // degrees

function slat_height(i) =
    let(
        // Primary wave (golden angle based)
        primary = sin(i * GOLDEN_ANGLE),
        // Secondary wave (slower, different frequency)
        secondary = sin(i * GOLDEN_ANGLE * 0.618) * 0.4,
        // Tertiary ripple (faster, subtle)
        tertiary = sin(i * 47) * 0.15,
        // Combined and normalized to 0-1 range
        combined = (primary + secondary + tertiary + 1.55) / 3.1
    )
    SLAT_BASE_HEIGHT + SLAT_HEIGHT_VAR * combined;

// ============================================
// MULTI-LAYER SLAT FUNCTIONS
// ============================================

// Y position of slat in layer L
function layer_slat_y(L) = LAYER_Y_OFFSET[L];

// Phase for slat i in layer L (includes layer phase offset)
function layer_slat_phase(i, L, theta) =
    let(x = slat_x(i))
    let(helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    helix_angle + theta + LAYER_PHASE_OFFSET[L];

// Cam height for slat i in layer L (uses per-layer ridge height)
function layer_cam_top_z(i, L, theta) =
    let(phase = layer_slat_phase(i, L, theta))
    let(angle_at_top = 90)
    let(ridge = LAYER_RIDGE_HEIGHT[L])  // Per-layer: [4, 7, 10] front-to-back
    let(r = CAM_CORE_RADIUS + ridge * (0.5 + 0.5 * cos(angle_at_top - phase)))
    r;

// Z position for slat i in layer L
function layer_slat_z(i, L, theta) =
    CAM_CENTER_Z + layer_cam_top_z(i, L, theta) + FOLLOWER_HEIGHT;

// Height for slat i in layer L (scaled by layer + golden ratio variation)
function layer_slat_height(i, L) =
    slat_height(i) * LAYER_HEIGHT_SCALE[L];

// Color for slat in layer L
function layer_slat_color(L) = LAYER_COLORS[L];

// ============================================
// SHAFT
// ============================================

SHAFT_LENGTH = BB_RIGHT_X - BB_LEFT_X + BB_WIDTH + 30;  // Full length through bearings

// ============================================
// BASE PLATE
// ============================================

BASE_LENGTH = BACKPLATE_WIDTH + 20;       // 240mm
BASE_WIDTH = BACKPLATE_Y_FRONT + BACKPLATE_THICKNESS + 20;  // ~62mm

// ============================================
// COLORS
// ============================================

C_SLAT = [0.15, 0.4, 0.7];
C_CAM = [0.65, 0.5, 0.3];
C_BACKPLATE = [0.2, 0.18, 0.15];
C_BB = [0.35, 0.35, 0.4];
C_BASE = [0.25, 0.25, 0.3];
C_SHAFT = [0.6, 0.6, 0.65];

function slat_color(i) =
    let(t = (sin(i * 360 / NUM_SLATS) + 1) / 2)
    [0.1 + 0.1*t, 0.3 + 0.2*t, 0.5 + 0.3*t];

// ============================================
// QUALITY
// ============================================

$fn = 48;

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("========================================");
echo("  WAVE OCEAN V10 - GEOMETRY VERIFICATION");
echo("========================================");
echo("");
echo("CAM:");
echo(str("  Center Z: ", CAM_CENTER_Z, "mm"));
echo(str("  Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("  Max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("  Sweeps Y: ±", CAM_MAX_RADIUS, "mm"));
echo("");
echo("SLATS:");
echo(str("  Count: ", NUM_SLATS));
echo(str("  Y position: ", SLAT_Y, "mm (centered)"));
echo(str("  Follower contacts TOP of cam"));
echo("");
echo("3-LAYER SYSTEM:");
echo(str("  Layers: ", NUM_LAYERS));
echo(str("  Layer Y positions: ", LAYER_Y_OFFSET[0], ", ", LAYER_Y_OFFSET[1], ", ", LAYER_Y_OFFSET[2], "mm"));
echo(str("  Ridge heights: ", LAYER_RIDGE_HEIGHT[0], ", ", LAYER_RIDGE_HEIGHT[1], ", ", LAYER_RIDGE_HEIGHT[2], "mm"));
echo(str("  Disc thickness: ", CAM_DISC_THICKNESS, "mm"));
