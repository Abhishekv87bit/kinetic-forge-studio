/*
 * WAVE OCEAN V10 - VERTICAL SLAT SYSTEM
 * COMMON PARAMETERS
 *
 * Three slat designs: Standard (A), Foam (B), Breaking Curl (C)
 * Structural backplate with vertical grooves
 * No front guide rails - clean viewer POV
 */

// ============================================
// PRINT TOLERANCES
// ============================================

TOL_CLEARANCE = 0.2;
TOL_SLIDING = 0.3;
TOL_PRESS_FIT = -0.15;

// ============================================
// HARDWARE
// ============================================

BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

SHAFT_DIA = 8;
SHAFT_LENGTH = 260;

M3_HOLE = 3.2;
M4_HOLE = 4.2;

// ============================================
// TWISTED CAM DIMENSIONS
// ============================================

CAM_LENGTH = 200;
CAM_CORE_RADIUS = 12;
CAM_RIDGE_HEIGHT = 12;           // Wave amplitude
CAM_MAX_RADIUS = CAM_CORE_RADIUS + CAM_RIDGE_HEIGHT;  // 24mm

HELIX_TURNS = 2;
HELIX_PITCH = CAM_LENGTH / HELIX_TURNS;

// ============================================
// SLAT COMMON DIMENSIONS
// ============================================

NUM_SLATS = 24;
SLAT_SPACING = CAM_LENGTH / NUM_SLATS;  // 8.33mm

SLAT_THICKNESS = 5;              // X dimension (along cam axis)
SLAT_DEPTH = 25;                 // Y dimension (into backplate)

// Individual slat heights (Z dimension)
SLAT_A_HEIGHT = 50;              // Standard
SLAT_B_HEIGHT = 55;              // Foam crest (taller)
SLAT_C_HEIGHT = 60;              // Breaking curl (tallest)

// Back tab dimensions (slides in backplate groove)
TAB_WIDTH = 4;
TAB_DEPTH = 15;                  // How deep into backplate
TAB_HEIGHT_EXTENSION = 25;       // Extra height for groove engagement

// Cam follower bottom
FOLLOWER_CURVE_RADIUS = CAM_CORE_RADIUS + 2;  // 14mm

// ============================================
// SLAT TYPE ASSIGNMENT
// Pattern: A=Standard, B=Foam, C=Breaking Curl
// C types placed at wave peak positions
// ============================================

// 0-indexed array: which type for each position
SLAT_TYPES = [
    "A", "B", "A", "A", "C",    // 0-4
    "A", "B", "A", "C", "A",    // 5-9
    "A", "B", "A", "C", "A",    // 10-14
    "B", "A", "A", "C", "A",    // 15-19
    "B", "A", "A", "B"          // 20-23
];

function slat_type(i) = SLAT_TYPES[i];

function slat_height(i) =
    let(t = slat_type(i))
    t == "A" ? SLAT_A_HEIGHT :
    t == "B" ? SLAT_B_HEIGHT :
    t == "C" ? SLAT_C_HEIGHT : SLAT_A_HEIGHT;

// ============================================
// BACKPLATE DIMENSIONS
// ============================================

BACKPLATE_WIDTH = CAM_LENGTH + 40;   // 240mm
BACKPLATE_HEIGHT = 100;               // Tall enough for wave travel + slats
BACKPLATE_THICKNESS = 20;             // Structural thickness

// Groove dimensions
GROOVE_WIDTH = TAB_WIDTH + TOL_SLIDING;  // 4.3mm
GROOVE_DEPTH = TAB_DEPTH + 2;            // 17mm into backplate
GROOVE_HEIGHT = CAM_RIDGE_HEIGHT * 2 + SLAT_C_HEIGHT + 20;  // Full travel range

// ============================================
// ASSEMBLY POSITIONS
// ============================================

BASE_THICKNESS = 5;

// Cam center height
CAM_CENTER_Z = 35;

// Backplate position (behind slats)
BACKPLATE_Y = SLAT_DEPTH / 2 + 5;     // 17.5mm behind center
BACKPLATE_Z = CAM_CENTER_Z - 10;       // Starts below cam center

// ============================================
// COLORS
// ============================================

C_SLAT_A = [0.15, 0.35, 0.65];        // Standard blue
C_SLAT_B = [0.2, 0.45, 0.75];         // Lighter blue (foam)
C_SLAT_C = [0.1, 0.3, 0.55];          // Darker blue (curl)
C_FOAM = [0.95, 0.97, 1.0];           // White foam
C_BACKPLATE = [0.25, 0.2, 0.15];      // Dark wood
C_CAM = [0.7, 0.55, 0.3];
C_SHAFT = [0.6, 0.6, 0.65];

// ============================================
// HELPER FUNCTIONS
// ============================================

function helix_phase(x) = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

function ridge_height(x, theta) =
    let(phase = helix_phase(x) + theta)
    CAM_RIDGE_HEIGHT * max(0, cos(phase - 90));

function cam_radius(x, theta) = CAM_CORE_RADIUS + ridge_height(x, theta);

function slat_x(i) = i * SLAT_SPACING - CAM_LENGTH/2 + SLAT_SPACING/2;

function slat_z(i, theta) =
    let(x = slat_x(i))
    CAM_CENTER_Z + cam_radius(x, theta);

// ============================================
// QUALITY
// ============================================

$fn = 48;
