/*
 * WAVE OCEAN V10 - VERTICAL SLAT SYSTEM V2
 * COMMON PARAMETERS
 *
 * DESIGN PRINCIPLES:
 * - TRUE TRAVELING WAVE (not synchronized bobbing)
 * - Maximum slats with minimum spacing
 * - 2 cam ridges = 2 visible waves traveling across
 * - Clean minimal slat design
 *
 * KEY INSIGHT:
 * For traveling wave: NUM_RIDGES << NUM_SLATS
 * Each slat experiences different phase of the wave
 *
 * All dimensions in mm
 */

// ============================================
// PRINT TOLERANCES (FDM tuned)
// ============================================

TOL_CLEARANCE = 0.2;         // Shaft in hole
TOL_SLIDING = 0.3;           // Slat in groove
TOL_PRESS_FIT = -0.1;        // Bearing press-fit

// ============================================
// HARDWARE SPECIFICATIONS
// ============================================

// 608 Bearing (main shaft)
BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

// Main shaft
SHAFT_DIA = 8;
SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;  // 8.2mm

// Fasteners
M3_HOLE = 3.2;
M3_HEAD_DIA = 5.5;
M3_HEAD_H = 3;
M4_HOLE = 4.2;
M4_HEAD_DIA = 7;

// ============================================
// SLAT CONFIGURATION - MAXIMIZED
// ============================================

// Slat dimensions (THIN for tight packing)
SLAT_THICKNESS = 2.5;                // X dimension - very thin
SLAT_DEPTH = 18;                     // Y dimension (front to back)

// Spacing calculation
// Minimum = thickness + clearance for movement
SLAT_CLEARANCE = 2.5;                // Gap between slats
SLAT_SPACING = SLAT_THICKNESS + SLAT_CLEARANCE;  // 5mm

// Cam and slat count
CAM_LENGTH = 180;                    // Active cam length
NUM_SLATS = floor(CAM_LENGTH / SLAT_SPACING);  // 36 slats!

// Height variations
SLAT_BASE_HEIGHT = 35;               // Minimum height
SLAT_HEIGHT_VARIATION = 12;          // Max additional height

// Height pattern: gradual variation for organic look
function slat_height(i) =
    SLAT_BASE_HEIGHT + SLAT_HEIGHT_VARIATION *
    (0.5 + 0.3 * sin(i * 45) + 0.2 * sin(i * 90));

// Back tab for groove guidance
TAB_THICKNESS = SLAT_THICKNESS;      // Same as slat
TAB_DEPTH = 10;                      // Into backplate
TAB_EXTRA_HEIGHT = 15;               // Below slat body

// Cam follower (curved bottom)
FOLLOWER_HEIGHT = 5;

// ============================================
// CAM CONFIGURATION - TRAVELING WAVE
// ============================================

// KEY: Few ridges = traveling wave effect
// 2 ridges = 2 complete waves visible at any time
NUM_RIDGES = 2;                      // Only 2 ridges!

CAM_CORE_RADIUS = 8;                 // Smaller core
CAM_RIDGE_HEIGHT = 10;               // Wave amplitude
CAM_MAX_RADIUS = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT;  // 18mm

// Helix: 2 turns over cam length = 2 ridges
HELIX_TURNS = NUM_RIDGES;            // 2 turns

// Follower curve matches cam
FOLLOWER_CURVE_RADIUS = CAM_CORE_RADIUS + 1;

// ============================================
// PHASE CALCULATION - THE KEY TO TRAVELING WAVE
// ============================================

// Slat X position (centered, evenly spaced)
function slat_x(i) = (i - (NUM_SLATS - 1) / 2) * SLAT_SPACING;

// Phase at slat position
// This determines WHERE on the wave cycle this slat is
function slat_phase(i, theta) =
    let(x = slat_x(i))
    // Helix angle based on position along cam
    let(helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    // Add cam rotation
    helix_angle + theta;

// Cam surface height at slat position
// Uses cosine for smooth wave: 1 at peak, -1 at trough
function cam_surface_at_slat(i, theta) =
    let(phase = slat_phase(i, theta))
    CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT * (0.5 + 0.5 * cos(phase));

// Slat Z position (bottom of slat rests on cam)
function slat_z(i, theta) =
    CAM_CENTER_Z + cam_surface_at_slat(i, theta);

// ============================================
// BACKPLATE CONFIGURATION
// ============================================

BACKPLATE_WIDTH = CAM_LENGTH + 30;   // 210mm
BACKPLATE_HEIGHT = 70;               // Enough for travel + slat height
BACKPLATE_THICKNESS = 12;            // Structural

// Groove dimensions
GROOVE_WIDTH = TAB_THICKNESS + TOL_SLIDING;  // 2.8mm
GROOVE_DEPTH = TAB_DEPTH + 2;                 // 12mm

// ============================================
// BEARING BLOCK CONFIGURATION
// ============================================

BB_WIDTH = 28;
BB_DEPTH = 28;
BB_HEIGHT = CAM_MAX_RADIUS + 8;      // 26mm

BEARING_POCKET_DIA = BEARING_608_OD - TOL_PRESS_FIT;  // 22.1mm
BEARING_POCKET_DEPTH = BEARING_608_H + 0.5;

// ============================================
// ASSEMBLY POSITIONS
// ============================================

// Cam center height (shaft axis)
CAM_CENTER_Z = BB_HEIGHT;            // 26mm above base

// Backplate position
BACKPLATE_Y = SLAT_DEPTH / 2 + 2;    // Behind slats
BACKPLATE_Z = 0;                     // Starts at base

// Bearing block X positions
BB_LEFT_X = -CAM_LENGTH / 2 - BB_WIDTH / 2 - 5;
BB_RIGHT_X = CAM_LENGTH / 2 + BB_WIDTH / 2 + 5;

// Shaft length
SHAFT_LENGTH = CAM_LENGTH + BB_WIDTH * 2 + 40;

// ============================================
// COLORS
// ============================================

C_SLAT = [0.15, 0.4, 0.7];           // Ocean blue
C_CAM = [0.65, 0.5, 0.3];            // Wood brown
C_BACKPLATE = [0.2, 0.18, 0.15];     // Dark wood
C_BB = [0.35, 0.35, 0.4];            // Gray
C_SHAFT = [0.6, 0.6, 0.65];          // Steel

// Slat color gradient (wave-like coloring)
function slat_color(i) =
    let(t = (sin(i * 360 / NUM_SLATS) + 1) / 2)  // 0 to 1 wave pattern
    [0.08 + 0.12*t, 0.25 + 0.2*t, 0.5 + 0.3*t];

// ============================================
// VERIFICATION
// ============================================

echo("============================================");
echo("  VERTICAL SLAT SYSTEM V2 - TRAVELING WAVE");
echo("============================================");
echo("");
echo("SLAT CONFIGURATION:");
echo(str("  Number of slats: ", NUM_SLATS));
echo(str("  Slat thickness: ", SLAT_THICKNESS, "mm"));
echo(str("  Slat spacing: ", SLAT_SPACING, "mm"));
echo(str("  Gap between slats: ", SLAT_CLEARANCE, "mm"));
echo("");
echo("CAM CONFIGURATION:");
echo(str("  Cam ridges: ", NUM_RIDGES, " (creates ", NUM_RIDGES, " traveling waves)"));
echo(str("  Slats per wave: ", NUM_SLATS / NUM_RIDGES));
echo(str("  Phase between adjacent slats: ", 360 * HELIX_TURNS / NUM_SLATS, "°"));
echo("");
echo("WAVE MOTION:");
echo(str("  Amplitude: ", CAM_RIDGE_HEIGHT, "mm"));
echo(str("  Core radius: ", CAM_CORE_RADIUS, "mm"));
echo("");
echo("This creates a TRUE traveling wave where adjacent");
echo("slats are at different phases of the wave cycle.");

// ============================================
// QUALITY SETTING
// ============================================

$fn = 48;
