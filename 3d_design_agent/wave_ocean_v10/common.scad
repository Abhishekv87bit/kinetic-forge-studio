/*
 * WAVE OCEAN V10 - COMMON PARAMETERS
 *
 * Shared constants, tolerances, and hardware specifications
 * All dimensions in mm
 *
 * MECHANISM: Helical groove cam drives 24 slats via follower arms
 * - Worm rotates around X axis
 * - Groove follows helix at radius GROOVE_RADIUS
 * - Follower rollers ride in groove, push slats up/down
 * - Phase difference along X creates traveling wave illusion
 */

// ============================================
// PRINT TOLERANCES (tune for your printer)
// ============================================

TOL_CLEARANCE = 0.2;         // Shaft in hole clearance
TOL_PRESS_FIT = -0.15;       // Bearing press-fit interference
TOL_SLIDING = 0.4;           // Sliding fit (guide slots)
TOL_SCREW_HOLE = 0.2;        // Screw hole clearance

// ============================================
// HARDWARE - BEARINGS
// ============================================

// 608 bearing (worm shaft)
BEARING_608_ID = 8;
BEARING_608_OD = 22;
BEARING_608_H = 7;

// 624 bearing (follower rollers)
BEARING_624_ID = 4;
BEARING_624_OD = 13;
BEARING_624_H = 5;

// ============================================
// HARDWARE - FASTENERS
// ============================================

M3_HOLE_DIA = 3 + TOL_SCREW_HOLE;      // 3.2mm
M3_HEAD_DIA = 5.5;
M3_HEAD_H = 3;
M3_NUT_FLAT = 5.5;
M3_NUT_H = 2.4;
M3_INSERT_DIA = 4.0;                    // Heat-set insert hole
M3_INSERT_DEPTH = 5;

// ============================================
// HARDWARE - SHAFTS AND PINS
// ============================================

WORM_SHAFT_DIA = 8;
WORM_SHAFT_LENGTH = 280;               // Extends beyond worm for bearings

ROLLER_AXLE_DIA = 4;
ROLLER_AXLE_LENGTH = 12;

PIVOT_PIN_DIA = 3;
PIVOT_PIN_LENGTH = 15;

// ============================================
// WORM CAM DIMENSIONS
// ============================================

WORM_LENGTH = 200;
WORM_OUTER_RADIUS = 20;              // 40mm diameter (bigger for deeper groove)
WORM_CORE_RADIUS = 10;               // 20mm diameter core
WORM_SHAFT_HOLE = WORM_SHAFT_DIA + TOL_CLEARANCE;  // 8.2mm

// Groove sized to contain 624 bearing roller
GROOVE_WIDTH = BEARING_624_H + 2;    // 7mm wide (bearing + clearance)
GROOVE_DEPTH = BEARING_624_OD/2 + 3; // 9.5mm deep (half bearing + margin)
GROOVE_RADIUS = WORM_OUTER_RADIUS - GROOVE_DEPTH/2;  // ~15mm from center

HELIX_PITCH = 25;                    // 25mm per rotation = 8 turns over 200mm

// ============================================
// SLAT DIMENSIONS
// ============================================

NUM_SLATS = 24;
SLAT_SPACING = WORM_LENGTH / NUM_SLATS;  // 8.33mm

SLAT_WIDTH = 5;                       // X dimension (slightly wider)
SLAT_DEPTH = 30;                      // Y dimension (narrower)
SLAT_HEIGHT = 40;                     // Z dimension

// Wave motion amplitude (half of total travel)
WAVE_AMPLITUDE = 10;                  // ±10mm vertical motion

// ============================================
// FOLLOWER ARM DIMENSIONS
// ============================================

ARM_LENGTH = 35;                      // Pivot to roller center (LONGER)
ARM_WIDTH = 8;
ARM_THICKNESS = 6;

PIVOT_HOLE = PIVOT_PIN_DIA + TOL_CLEARANCE;    // 3.2mm
ROLLER_AXLE_HOLE = ROLLER_AXLE_DIA + TOL_CLEARANCE;  // 4.2mm

// ============================================
// SLAT BRACKET DIMENSIONS
// ============================================

BRACKET_WIDTH = 12;
BRACKET_DEPTH = 20;
BRACKET_HEIGHT = 25;

// ============================================
// GUIDE RAIL DIMENSIONS
// ============================================

GUIDE_LENGTH = 210;
GUIDE_HEIGHT = 30;                    // Taller for more travel
GUIDE_DEPTH = 10;
GUIDE_WALL = 3;

SLOT_WIDTH = SLAT_WIDTH + TOL_SLIDING;   // Slat slides in slot, not bracket tab
SLOT_HEIGHT = WAVE_AMPLITUDE * 2 + 10;   // Allow full travel + margin

// ============================================
// BEARING BLOCK DIMENSIONS
// ============================================

BEARING_BLOCK_WIDTH = 35;
BEARING_BLOCK_DEPTH = 35;
BEARING_BLOCK_HEIGHT = 30;

BEARING_POCKET_DIA = BEARING_608_OD + TOL_PRESS_FIT;  // 21.85mm
BEARING_POCKET_DEPTH = BEARING_608_H + 1;             // 8mm

// ============================================
// BASE PLATE DIMENSIONS
// ============================================

BASE_LENGTH = 280;                    // Longer to fit everything
BASE_WIDTH = 100;                     // Wider for stability
BASE_THICKNESS = 5;

// ============================================
// MOTOR MOUNT DIMENSIONS
// ============================================

N20_BODY_DIA = 12;
N20_BODY_LENGTH = 15;
N20_GEARBOX_DIA = 10;
N20_GEARBOX_LENGTH = 12;
N20_SHAFT_DIA = 3;
N20_SHAFT_LENGTH = 10;

// ============================================
// ASSEMBLY POSITIONS
// ============================================

// Worm center position
// Shaft runs along X axis at this Z height
WORM_CENTER_Z = BASE_THICKNESS + BEARING_BLOCK_HEIGHT;  // 35mm

// Guide rail positions (front and back of slats)
// Slats are centered at Y=0, spanning ±SLAT_DEPTH/2
GUIDE_FRONT_Y = -SLAT_DEPTH/2 - GUIDE_DEPTH/2;   // -20
GUIDE_BACK_Y = SLAT_DEPTH/2 + GUIDE_DEPTH/2;     // +20

// Guide rail Z - slats hang down from here
// Positioned so slat bottom can reach groove at top of worm
GUIDE_Z = WORM_CENTER_Z + WORM_OUTER_RADIUS + SLAT_HEIGHT/2 + 5;  // 80mm

// Bearing block X positions (at ends of worm, inward facing)
BEARING_L_X = -WORM_LENGTH/2 - BEARING_BLOCK_WIDTH/2;   // -117.5
BEARING_R_X = WORM_LENGTH/2 + BEARING_BLOCK_WIDTH/2;    // +117.5

// Motor mount X position (beyond right bearing block)
MOTOR_MOUNT_X = BEARING_R_X + BEARING_BLOCK_WIDTH/2 + 30;

// ============================================
// COLORS (for assembly visualization)
// ============================================

C_WORM = [0.75, 0.55, 0.2];
C_SLAT = [0.2, 0.45, 0.75];
C_BRACKET = [0.4, 0.4, 0.45];
C_ARM = [0.5, 0.5, 0.55];
C_GUIDE = [0.35, 0.35, 0.4];
C_BEARING_BLOCK = [0.3, 0.35, 0.4];
C_BASE = [0.25, 0.25, 0.3];
C_SHAFT = [0.6, 0.6, 0.65];
C_BEARING = [0.7, 0.7, 0.75];
C_MOTOR = [0.3, 0.3, 0.35];

// ============================================
// HELPER FUNCTIONS
// ============================================

// Helix angle at position X along worm (in degrees)
function helix_angle(x) = (x / HELIX_PITCH) * 360;

// Combined phase: helix position + shaft rotation
function phase(x, theta) = helix_angle(x) + theta;

// Groove center position in Y-Z plane (polar coordinates from shaft)
// Y = radius * sin(angle), Z = center + radius * cos(angle)
function groove_y(x, theta) = GROOVE_RADIUS * sin(phase(x, theta));
function groove_z(x, theta) = WORM_CENTER_Z + GROOVE_RADIUS * cos(phase(x, theta));

// Slat X position (evenly spaced along worm length)
function slat_x(i) = i * SLAT_SPACING - WORM_LENGTH/2 + SLAT_SPACING/2;

// Slat Z position - follows groove Z position via follower arm
// When groove is at top (cos=1), slat is pushed up
// When groove is at bottom (cos=-1), slat drops down
function slat_z(i, theta) =
    let(x = slat_x(i))
    GUIDE_Z + GROOVE_RADIUS * cos(phase(x, theta)) - GROOVE_RADIUS;

// ============================================
// CLEARANCE VERIFICATION
// ============================================

// Slat gap: SLAT_SPACING - SLAT_WIDTH = 8.33 - 5 = 3.33mm ✓
// Arm reach: ARM_LENGTH = 35mm, needs to reach ~30mm ✓
// Groove depth: 9.5mm, bearing radius 6.5mm ✓
// Wave travel: ±GROOVE_RADIUS * cos variation = ±15mm

// ============================================
// QUALITY SETTINGS
// ============================================

$fn = 48;  // Default facets
