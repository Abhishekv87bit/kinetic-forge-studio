/*
 * WAVE OCEAN V10 - TWISTED CAM SYSTEM
 * COMMON PARAMETERS
 *
 * Simplified mechanism: slats rest on cam surface, no follower arms
 * Single helical ridge creates traveling wave as cam rotates
 *
 * All dimensions in mm
 */

// ============================================
// PRINT TOLERANCES (tune for your printer)
// ============================================

TOL_CLEARANCE = 0.2;         // Shaft in hole clearance
TOL_PRESS_FIT = -0.15;       // Bearing press-fit interference
TOL_SLIDING = 0.3;           // Sliding fit (slats in guides)

// ============================================
// HARDWARE - BEARINGS
// ============================================

// 608 bearing (main shaft) - common, cheap
BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

// ============================================
// HARDWARE - FASTENERS
// ============================================

M3_HOLE = 3.2;
M3_HEAD_DIA = 5.5;
M3_HEAD_H = 3;
M4_HOLE = 4.2;

// ============================================
// MAIN SHAFT
// ============================================

SHAFT_DIA = 8;                   // 8mm steel rod
SHAFT_LENGTH = 260;              // Total shaft length
SHAFT_HOLE = SHAFT_DIA + TOL_CLEARANCE;  // 8.2mm

// ============================================
// TWISTED CAM DIMENSIONS
// ============================================

CAM_LENGTH = 200;                // Active wave zone
CAM_CORE_RADIUS = 12;            // Base cylinder radius
CAM_RIDGE_HEIGHT = 10;           // How much ridge sticks out
CAM_RIDGE_WIDTH = 8;             // Width of ridge (smoothness)
CAM_MAX_RADIUS = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT;  // 22mm

// Helix parameters
HELIX_TURNS = 2;                 // Number of complete spirals
HELIX_PITCH = CAM_LENGTH / HELIX_TURNS;  // 100mm per turn

// ============================================
// SLAT DIMENSIONS
// ============================================

NUM_SLATS = 24;
SLAT_SPACING = CAM_LENGTH / NUM_SLATS;  // 8.33mm

SLAT_WIDTH = 6;                  // X dimension (along cam axis)
SLAT_DEPTH = 30;                 // Y dimension (front to back)
SLAT_HEIGHT = 50;                // Z dimension (wave visual height)

// Slat bottom - curved to nest on cam surface
SLAT_CURVE_RADIUS = CAM_CORE_RADIUS + 2;  // Slightly larger than core

// Wave motion
WAVE_AMPLITUDE = CAM_RIDGE_HEIGHT;  // Total Z travel = ridge height

// ============================================
// GUIDE RAIL DIMENSIONS
// ============================================

// Minimal guides - thin vertical slots, barely visible
GUIDE_LENGTH = CAM_LENGTH + 20;  // 220mm
GUIDE_HEIGHT = WAVE_AMPLITUDE + SLAT_HEIGHT + 10;  // 70mm
GUIDE_THICKNESS = 3;             // Very thin - minimal visual impact
GUIDE_WALL = 2;

SLOT_WIDTH = SLAT_WIDTH + TOL_SLIDING;  // 6.3mm
SLOT_HEIGHT = WAVE_AMPLITUDE + 15;       // 25mm vertical travel

// ============================================
// BEARING BLOCK DIMENSIONS
// ============================================

BB_WIDTH = 30;
BB_DEPTH = 30;
BB_HEIGHT = CAM_MAX_RADIUS + 8;  // 30mm - cam clears base

BEARING_POCKET_DIA = BEARING_608_OD - TOL_PRESS_FIT;  // 22.15mm press fit
BEARING_POCKET_DEPTH = BEARING_608_H + 0.5;           // 7.5mm

// ============================================
// BASE PLATE DIMENSIONS
// ============================================

BASE_LENGTH = CAM_LENGTH + 60;   // 260mm
BASE_WIDTH = SLAT_DEPTH + 40;    // 70mm
BASE_THICKNESS = 5;

// ============================================
// ASSEMBLY POSITIONS
// ============================================

// Cam center Z (shaft axis height above base)
CAM_CENTER_Z = BASE_THICKNESS + BB_HEIGHT;  // 35mm

// Bearing blocks X positions
BB_LEFT_X = -CAM_LENGTH/2 - BB_WIDTH/2 - 5;   // -120mm
BB_RIGHT_X = CAM_LENGTH/2 + BB_WIDTH/2 + 5;   // +120mm

// Guide rails Y positions (front and back of slats)
GUIDE_FRONT_Y = -SLAT_DEPTH/2 - GUIDE_THICKNESS - 1;  // -17mm
GUIDE_BACK_Y = SLAT_DEPTH/2 + 1;                       // +16mm

// Guide rails Z position (bottom of guide)
GUIDE_Z = CAM_CENTER_Z + CAM_MAX_RADIUS - 5;  // 52mm

// ============================================
// COLORS
// ============================================

C_CAM = [0.7, 0.5, 0.25];        // Wood brown
C_SLAT = [0.15, 0.35, 0.6];      // Ocean blue
C_GUIDE = [0.3, 0.3, 0.35, 0.5]; // Dark gray, semi-transparent
C_BB = [0.35, 0.35, 0.4];        // Bearing block gray
C_BASE = [0.25, 0.25, 0.3];      // Dark base
C_SHAFT = [0.6, 0.6, 0.65];      // Steel

// ============================================
// HELPER FUNCTIONS
// ============================================

// Helix phase at position X along cam (0-360 per turn)
function helix_phase(x) = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

// Cam surface height at position X, given cam rotation angle theta
// Returns how far the ridge sticks up at that X position
function ridge_height(x, theta) =
    let(phase = helix_phase(x) + theta)
    let(ridge = CAM_RIDGE_HEIGHT * max(0, cos(phase - 90)))
    ridge;

// Total cam radius at position X, angle theta
function cam_radius(x, theta) = CAM_CORE_RADIUS + ridge_height(x, theta);

// Slat X position (evenly spaced)
function slat_x(i) = i * SLAT_SPACING - CAM_LENGTH/2 + SLAT_SPACING/2;

// Slat Z position (bottom of slat rests on cam surface)
function slat_z(i, theta) =
    let(x = slat_x(i))
    CAM_CENTER_Z + cam_radius(x, theta);

// ============================================
// QUALITY
// ============================================

$fn = 48;

// ============================================
// VERIFICATION
// ============================================

echo("=== TWISTED CAM SYSTEM ===");
echo(str("Cam length: ", CAM_LENGTH, "mm"));
echo(str("Cam radius: ", CAM_CORE_RADIUS, "-", CAM_MAX_RADIUS, "mm"));
echo(str("Ridge height (wave amplitude): ", CAM_RIDGE_HEIGHT, "mm"));
echo(str("Helix turns: ", HELIX_TURNS));
echo(str("Slats: ", NUM_SLATS, " @ ", SLAT_SPACING, "mm spacing"));
echo(str("Slat gap: ", SLAT_SPACING - SLAT_WIDTH, "mm"));
