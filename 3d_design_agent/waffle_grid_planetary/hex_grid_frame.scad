// =============================================================
// HEX OFFSET GRID FRAME — 5×5 Brick Pattern (25 units)
//
// Adapted from waffle_grid_5x5.scad:
//   - Same gear params as full_assembly.scad v4
//   - Hex offset: odd rows shifted +UNIT_PITCH/2 in X
//   - 3 parallel shafts per row (A center, B above, C side)
//   - 5 rows × 3 shafts = 15 shafts total
//
// DETAIL CONTROL:
//   DETAIL_ROW = which row shows actual units (0-4, or -1 for all)
//   DETAIL_COLS = how many units in that row get full gear detail
//   All other rows/units: ghost envelope + thread + block
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

$fn = 36;
MANUAL_POSITION = -1;  // set >= 0 to freeze at that position, -1 = use $t animation
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL      = 0.25;
BACKLASH = 0.21;

// ============================================================
// PARAMETERS — from full_assembly.scad v4
// ============================================================
MOD         = 1.0;       // Internal planetary module
EXT_MOD     = 1.5;       // External ring teeth module
PA          = 20;        // Pressure angle
HELIX_ANGLE = 20;        // Herringbone helix angle
GFW         = 6;         // Gear face width
EXT_GFW     = 6;         // External gear face width
CARRIER_T   = 2;         // Carrier plate thickness
PIN_D       = 2;         // Planet pin diameter
CAR_PAD     = 1.5;       // Carrier plate radial pad
AXIAL_GAP   = 0.2;       // Gap between ring face and carrier plate
RING_WALL   = 1.5;       // Ring backing
N_PLANETS   = 3;
PIP_TOL     = 0.35;
BEARING_WALL = 1.5;

// Stage 1: S1 + 2*P1 = R1
S1_T = 13;  P1_T = 8;  R1_T = 29;
// Stage 2: mirrors Stage 1
S2_T = 13;  P2_T = 8;  R2_T = 29;
// External teeth (both rings identical)
EXT_T  = 26;
BPIN_T = 8;    // B-shaft pinion teeth
CPIN_T = 8;    // C-shaft pinion teeth

SHAFT_D    = 5;       // Hex across-flats
BC_SHAFT_D = 3;       // B/C shaft diameter

// Spool
SPOOL_R    = 8;
SPOOL_OD   = SPOOL_R * 2;    // 16
SPOOL_H    = 6;
SPOOL_WALL = 2;
SPOOL_ID   = SPOOL_OD - 2*SPOOL_WALL;
SPOOL_GAP  = 1;
FLANGE_R   = SPOOL_R + 3;    // 11
FLANGE_T   = 1.5;
THREAD_LEN = 300;      // blocks hang ~210mm below plate at rest (300-90=210)
PIXEL_H    = 75;       // block height
SPOOL_TRAVEL = 90;     // total vertical travel range

// Coupling tube
CPLG_ID = SHAFT_D + 0.5;
CPLG_OD = 7;

// Bearings
BRG_OD = 8;  BRG_ID = 4;  BRG_W = 3;
NEEDLE_OD = 6;  NEEDLE_ID = SHAFT_D + TOL;  NEEDLE_W = 3;

// ============================================================
// ASSERTIONS
// ============================================================
assert(S1_T + 2*P1_T == R1_T, str("Stage1: S+2P!=R"));
assert(S2_T + 2*P2_T == R2_T, str("Stage2: S+2P!=R"));

// ============================================================
// DERIVED VALUES — STAGE 1
// ============================================================
PS_S1 = auto_profile_shift(teeth=S1_T, pressure_angle=PA);
PS_P1 = auto_profile_shift(teeth=P1_T, pressure_angle=PA);
S1_PR = pitch_radius(mod=MOD, teeth=S1_T);
P1_PR = pitch_radius(mod=MOD, teeth=P1_T);
R1_PR = pitch_radius(mod=MOD, teeth=R1_T);
ORB1  = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                  profile_shift1=PS_S1, profile_shift2=PS_P1);

R1_RR = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_INNER_R = R1_RR + RING_WALL;

// ============================================================
// DERIVED VALUES — STAGE 2
// ============================================================
PS_S2 = auto_profile_shift(teeth=S2_T, pressure_angle=PA);
PS_P2 = auto_profile_shift(teeth=P2_T, pressure_angle=PA);
S2_PR = pitch_radius(mod=MOD, teeth=S2_T);
P2_PR = pitch_radius(mod=MOD, teeth=P2_T);
R2_PR = pitch_radius(mod=MOD, teeth=R2_T);
ORB2  = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                  profile_shift1=PS_S2, profile_shift2=PS_P2);

// ============================================================
// EXTERNAL RING TEETH — EXT_MOD
// ============================================================
PS_EXT = auto_profile_shift(teeth=EXT_T, pressure_angle=PA);
EXT_PR = pitch_radius(mod=EXT_MOD, teeth=EXT_T);
EXT_OR = outer_radius(mod=EXT_MOD, teeth=EXT_T);
EXT_RR = root_radius(mod=EXT_MOD, teeth=EXT_T);

assert(EXT_RR >= RING_INNER_R + 0.3,
       str("Ext gear root=", EXT_RR, " too close to ring body=", RING_INNER_R));

// ============================================================
// DRIVE PINIONS
// ============================================================
PS_BPIN = auto_profile_shift(teeth=BPIN_T, pressure_angle=PA);
BPIN_PR = pitch_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_OR = outer_radius(mod=EXT_MOD, teeth=BPIN_T);

DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=BPIN_T,
                     profile_shift1=PS_EXT, profile_shift2=PS_BPIN);

echo("DRIVE_CD=", DRIVE_CD, "EXT_OR=", EXT_OR, "BPIN_OR=", BPIN_OR);

// ============================================================
// SHAFT LAYOUT — symmetric V on top (10:10 and 1:50 clock positions)
// ±25° from 12 o'clock = both shafts above center, nothing sideways
// ============================================================
SHAFT_ANGLE = 25;  // degrees from vertical (12 o'clock)
B_SHAFT_DY = -DRIVE_CD * sin(SHAFT_ANGLE);  // upper LEFT  (-11.1mm)
B_SHAFT_DZ =  DRIVE_CD * cos(SHAFT_ANGLE);  // up          (+23.8mm)
C_SHAFT_DY =  DRIVE_CD * sin(SHAFT_ANGLE);  // upper RIGHT (+11.1mm)
C_SHAFT_DZ =  DRIVE_CD * cos(SHAFT_ANGLE);  // up          (+23.8mm)

// ============================================================
// SQUARE GRID — 5×5, no offset
// ============================================================
GRID_NX = 5;
GRID_NY = 5;
UNIT_PITCH = 44;       // min X: ext gear OD=42mm + 2mm clearance
ROW_PITCH  = 44;       // min Y: 2×EXT_OR(42) + 2mm ring-to-ring clearance

function node_x(row, col) = col * UNIT_PITCH;
function row_y(row) = row * ROW_PITCH;

// Guide plate: redirects threads from unit pitch to tighter block pitch
GUIDE_PLATE_T  = 5;        // plate thickness
GUIDE_PLATE_Z  = -35;      // Z position (well below units, above blocks)
GUIDE_HOLE_D   = 4;        // thread hole diameter
FILLET_R       = 1.4;      // fillet radius

// Hexagonal block parameters
HEX_BLOCK_AF  = 25;        // hex across-flats (flat-to-flat diameter)
HEX_BLOCK_AC  = HEX_BLOCK_AF / cos(30);  // across-corners ≈ 28.87

// Hex tessellation pitch — offset rows for interlocking
// For hex brick pattern: col pitch = across-flats + gap, row pitch = AC * 0.75 + gap
HEX_GAP        = 0.5;      // minimal gap — nearly touching
BLOCK_PITCH_X  = HEX_BLOCK_AF + HEX_GAP;  // 25.5mm
BLOCK_PITCH_Y  = HEX_BLOCK_AC * 0.75 + HEX_GAP;  // ~22.15mm
HEX_ROW_OFFSET = BLOCK_PITCH_X / 2;  // odd block-rows shift by half pitch

// Block grid center = same as unit grid center
UNIT_CENTER_X  = (GRID_NX - 1) * UNIT_PITCH / 2;
UNIT_CENTER_Y  = (GRID_NY - 1) * ROW_PITCH / 2;

// Block positions — hex tessellation grid centered on same center point
// Odd rows offset by half pitch for honeycomb interlocking
function block_x(row, col) = UNIT_CENTER_X + (col - (GRID_NX-1)/2) * BLOCK_PITCH_X
                              + (row % 2 == 1 ? HEX_ROW_OFFSET : 0);
function block_y(row, col) = UNIT_CENTER_Y + (row - (GRID_NY-1)/2) * BLOCK_PITCH_Y;

// C-shaft clearance check between adjacent rows
// C-shaft DY = DRIVE_CD * sin(SHAFT_ANGLE), must clear adj row's ring
C_SHAFT_MAX_DY = abs(C_SHAFT_DY);  // max sideways extent of B or C pinion
C_SHAFT_TO_ADJ_RING = ROW_PITCH - C_SHAFT_MAX_DY - EXT_OR;
echo("C_SHAFT_TO_ADJ_RING=", C_SHAFT_TO_ADJ_RING);
assert(C_SHAFT_TO_ADJ_RING > 0,
       str("C-shaft collision with adj ring, gap=", C_SHAFT_TO_ADJ_RING));

// Node envelope check within row
assert(EXT_OR * 2 < UNIT_PITCH,
       str("Ext gear OD=", EXT_OR*2, " exceeds pitch=", UNIT_PITCH));

// ============================================================
// NODE STACK — axial layout (X direction, local to node)
// ============================================================
GAP = 3;        // gap between stages
S1_LOCAL    = -(GAP/2 + GFW/2);
S2_LOCAL    =  (GAP/2 + GFW/2);
STACK_HALF  = GFW/2 + CARRIER_T;
TOTAL_STACK = (GFW + CARRIER_T*2)*2 + GAP;
STACK_LEFT  = S1_LOCAL - STACK_HALF;
STACK_RIGHT = S2_LOCAL + STACK_HALF;
SPOOL_START = STACK_RIGHT + SPOOL_GAP;
SPOOL_CENTER = SPOOL_START + SPOOL_H/2;
NODE_X_MAX  = SPOOL_START + SPOOL_H + FLANGE_T;
NODE_X_MIN  = STACK_LEFT;
NODE_TOTAL_X = NODE_X_MAX - NODE_X_MIN;

assert(NODE_TOTAL_X < UNIT_PITCH,
       str("Node X extent=", NODE_TOTAL_X, " > pitch=", UNIT_PITCH));

// ============================================================
// FRAME DIMENSIONS
// ============================================================
FRAME_BAR    = 8;
FRAME_MARGIN = 35;
LEG_HEIGHT   = 480;   // thread(220) + spool(8) + block(75) + clearance
LEG_SECTION  = 10;
CLIP_W       = 1;
CLIP_OD      = SHAFT_D + 2;

// Grid extents — equal grid, no offset
GRID_X_MIN = 0;
GRID_X_MAX = (GRID_NX-1) * UNIT_PITCH;                           // 200
GRID_Y_MAX = (GRID_NY-1) * ROW_PITCH;                             // row 4

FRAME_X_MIN = GRID_X_MIN + NODE_X_MIN - FRAME_MARGIN;
FRAME_X_MAX = GRID_X_MAX + NODE_X_MAX + FRAME_MARGIN;
FRAME_Y_MIN = -FRAME_MARGIN;
FRAME_Y_MAX = GRID_Y_MAX + C_SHAFT_MAX_DY + BPIN_OR + FRAME_MARGIN;
FRAME_X_LEN = FRAME_X_MAX - FRAME_X_MIN;
FRAME_Y_LEN = FRAME_Y_MAX - FRAME_Y_MIN;
FRAME_MX    = (FRAME_X_MIN + FRAME_X_MAX) / 2;
FRAME_MY    = (FRAME_Y_MIN + FRAME_Y_MAX) / 2;

FRAME_Z = max(B_SHAFT_DZ, C_SHAFT_DZ) + BPIN_OR + 8;

// Shaft lengths: span full frame width
SHAFT_X_START = FRAME_X_MIN + FRAME_BAR + 2;
SHAFT_X_END   = FRAME_X_MAX - FRAME_BAR - 2;
SHAFT_LEN     = SHAFT_X_END - SHAFT_X_START;
SHAFT_X_MID   = (SHAFT_X_START + SHAFT_X_END) / 2;

// ============================================================
// KINEMATICS
// ============================================================
A_IN = POS * 360;
B_IN = POS * 360 * 1.13;
C_IN = POS * 360 * 0.87;

SUN1_A  = A_IN;
RING1_A = B_IN;
CAR1_A  = (SUN1_A*S1_T + RING1_A*R1_T) / (S1_T + R1_T);
SUN2_A  = CAR1_A;
RING2_A = C_IN;
CAR2_A  = (SUN2_A*S2_T + RING2_A*R2_T) / (S2_T + R2_T);
SPOOL_A = CAR2_A;

// ============================================================
// WAVE PATTERN SELECTOR — change PATTERN to switch
// ============================================================
// Speeds MUST be integers for seamless $t looping.
// Phase offsets between waves create interference.
// Phase gradients (X/Y) control spatial wavelength.
//
// ── SPEED CONTROL DEMOS (what stepper speed ratios produce) ──
//  #  Name              SpdA SpdB SpdC  PhsA PhsB PhsC  PhX  PhY  Character
//  0  Evolving Ripple    3    4    2     0   120  240    45   45   Organic, never repeats
//  1  Equal Speed        3    3    3     0   120  240    45   45   All same → 3-phase standing beat
//  2  Frozen + Sweep     0    0    3     0     0    0    45   45   Two motors OFF, one sweeps
//  3  Reverse B          3   -3    2     0   120  240    45   45   B reversed → wave flips direction
//  4  Harmonic 1:2:3     1    2    3     0     0    0    45   45   Musical chord — pure harmonics
//  5  Fast Chaos         5    7    3     0    72  144    45   45   Many crossings, turbulent
//  6  Heartbeat          2    4    6     0     0    0    45   45   Harmonics 1:2:3 doubled, punchy
//  7  One Motor Only     3    0    0     0     0    0    45   45   Single clean sine wave
//
// ── PHASE CONTROL DEMOS (what phase offsets produce) ──
//  8  3-Phase 120°       3    3    3     0   120  240    45   45   Balanced 3-phase (same as #1)
//  9  In-Phase All       3    4    2     0     0    0    45   45   All start together → big peaks
// 10  Anti-Phase B       3    3    3     0   180    0    45   45   B cancels A → quieter wave
// 11  Spiral             3    3    3     0   120  240    72  -72   Phase wraps around grid = rotation
//
// ── SPATIAL GRADIENT DEMOS (wavelength across grid) ──
// 12  Long Wavelength    1    1    1     0   120  240    20   20   Tsunami — huge gentle roll
// 13  X-Only Wave        3    3    3     0     0    0    72    0   Wave travels left→right only
// 14  Y-Only Wave        3    3    3     0     0    0     0   72   Wave travels front→back only
//
// ── SPECIAL COMBOS ──
// 15  Breathing          2    2   -2     0     0  180    45   45   Expand/contract like lungs
// 16  Colliding          3   -3    1     0   180    0    60   60   Two waves smash head-on
// 17  Standing Wave      3   -3    0     0   180    0    45   45   Oscillate in place, no travel
// 18  Rain               1    3    7     0    60  170    50   37   Pseudo-random organic
// 19  Glitch             5    8   13     0    45   90    45   45   Fibonacci speeds, erratic
// 20  Pendulum           2    2    2     0   180    0    90    0   Left/right halves swing opposite
// 21  Slow Roll          1    2    3     0    90  180    30   30   Gentle, long wavelength
// 22  Frozen Interfer.   3    3    0     0    90    0    45   45   Two waves frozen interference
//
PATTERN = 0;   // <— CHANGE THIS NUMBER TO SWITCH PATTERNS

_PRESETS = [
//        [SpdA, SpdB, SpdC, PhaseA, PhaseB, PhaseC, PhaseX, PhaseY]
// ── SPEED CONTROL ──
/* 0  */  [  3,    4,    2,     0,    120,    240,     45,     45],  // Evolving Ripple
/* 1  */  [  3,    3,    3,     0,    120,    240,     45,     45],  // Equal Speed
/* 2  */  [  0,    0,    3,     0,      0,      0,     45,     45],  // Frozen + Sweep
/* 3  */  [  3,   -3,    2,     0,    120,    240,     45,     45],  // Reverse B
/* 4  */  [  1,    2,    3,     0,      0,      0,     45,     45],  // Harmonic 1:2:3
/* 5  */  [  5,    7,    3,     0,     72,    144,     45,     45],  // Fast Chaos
/* 6  */  [  2,    4,    6,     0,      0,      0,     45,     45],  // Heartbeat
/* 7  */  [  3,    0,    0,     0,      0,      0,     45,     45],  // One Motor Only
// ── PHASE CONTROL ──
/* 8  */  [  3,    3,    3,     0,    120,    240,     45,     45],  // 3-Phase 120°
/* 9  */  [  3,    4,    2,     0,      0,      0,     45,     45],  // In-Phase All
/* 10 */  [  3,    3,    3,     0,    180,      0,     45,     45],  // Anti-Phase B
/* 11 */  [  3,    3,    3,     0,    120,    240,     72,    -72],  // Spiral
// ── SPATIAL GRADIENT ──
/* 12 */  [  1,    1,    1,     0,    120,    240,     20,     20],  // Tsunami
/* 13 */  [  3,    3,    3,     0,      0,      0,     72,      0],  // X-Only Wave
/* 14 */  [  3,    3,    3,     0,      0,      0,      0,     72],  // Y-Only Wave
// ── SPECIAL COMBOS ──
/* 15 */  [  2,    2,   -2,     0,      0,    180,     45,     45],  // Breathing
/* 16 */  [  3,   -3,    1,     0,    180,      0,     60,     60],  // Colliding
/* 17 */  [  3,   -3,    0,     0,    180,      0,     45,     45],  // Standing Wave
/* 18 */  [  1,    3,    7,     0,     60,    170,     50,     37],  // Rain
/* 19 */  [  5,    8,   13,     0,     45,     90,     45,     45],  // Glitch
/* 20 */  [  2,    2,    2,     0,    180,      0,     90,      0],  // Pendulum
/* 21 */  [  1,    2,    3,     0,     90,    180,     30,     30],  // Slow Roll
/* 22 */  [  3,    3,    0,     0,     90,      0,     45,     45],  // Frozen Interference
];

_P = _PRESETS[PATTERN];
WAVE_A_SPD   = _P[0];
WAVE_B_SPD   = _P[1];
WAVE_C_SPD   = _P[2];
WAVE_A_PHASE = _P[3];
WAVE_B_PHASE = _P[4];
WAVE_C_PHASE = _P[5];
WAVE_PHASE_X = _P[6];
WAVE_PHASE_Y = _P[7];

echo(str("PATTERN=", PATTERN,
         " spd=[", WAVE_A_SPD, ",", WAVE_B_SPD, ",", WAVE_C_SPD, "]",
         " phase=[", WAVE_A_PHASE, ",", WAVE_B_PHASE, ",", WAVE_C_PHASE, "]",
         " grad=[", WAVE_PHASE_X, ",", WAVE_PHASE_Y, "]"));

function wave(row, col, spd, phase) =
    (1 + sin(POS * 360 * spd + col * WAVE_PHASE_X + row * WAVE_PHASE_Y + phase)) / 2;

function node_drop(row, col) =
    SPOOL_TRAVEL * (
        wave(row, col, WAVE_A_SPD, WAVE_A_PHASE) +
        wave(row, col, WAVE_B_SPD, WAVE_B_PHASE) +
        wave(row, col, WAVE_C_SPD, WAVE_C_PHASE)
    ) / 3;

P1_SELF = -(CAR1_A - SUN1_A) * S1_T / P1_T;
P2_SELF = -(CAR2_A - SUN2_A) * S2_T / P2_T;
BPIN_A  = -RING1_A * EXT_T / BPIN_T;
CPIN_A  = -RING2_A * EXT_T / BPIN_T;

// Planet phasing — Stage 1
S1_QUANT = 360 / (S1_T + R1_T);
S1_PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    S1_QUANT * round(i * 360 / N_PLANETS / S1_QUANT)
];
S1_RING_SPIN0 = 180/R1_T * (1 - (S1_T % 2));
S1_PLANET_SPINS0 = [for (ang = S1_PLANET_ANGLES)
    (S1_T/P1_T) * (ang - 90) + 90 + ang + 180/P1_T
];

// Planet phasing — Stage 2
S2_QUANT = 360 / (S2_T + R2_T);
S2_PLANET_ANGLES = [for (i = [0:N_PLANETS-1])
    S2_QUANT * round(i * 360 / N_PLANETS / S2_QUANT)
];
S2_RING_SPIN0 = 180/R2_T * (1 - (S2_T % 2));
S2_PLANET_SPINS0 = [for (ang = S2_PLANET_ANGLES)
    (S2_T/P2_T) * (ang - 90) + 90 + ang + 180/P2_T
];

// ============================================================
// COLORS
// ============================================================
C_SUN   = [0.85, 0.25, 0.20];
C_SUN2  = [0.70, 0.20, 0.25];
C_RING  = [0.78, 0.72, 0.25];
C_RING2 = [0.68, 0.62, 0.25];
C_EXT   = [0.90, 0.80, 0.30];
C_EXT2  = [0.80, 0.70, 0.28];
C_PLN1  = [0.35, 0.72, 0.35];
C_PLN2  = [0.28, 0.60, 0.28];
C_CAR   = [0.30, 0.50, 0.80];
C_CAR2  = [0.25, 0.42, 0.72];
C_CPLG  = [0.45, 0.65, 0.90];
C_SPL   = [0.58, 0.40, 0.22];
C_FLNG  = [0.65, 0.48, 0.28];
C_THR   = [0.82, 0.82, 0.88];
C_PIX   = [0.74, 0.60, 0.40];
C_SHA   = [0.88, 0.30, 0.22];
C_SHB   = [0.22, 0.75, 0.30];
C_SHC   = [0.22, 0.38, 0.90];
C_PIN   = [0.65, 0.65, 0.68];
C_BPIN  = [0.50, 0.80, 0.50];
C_CPIN  = [0.40, 0.50, 0.90];
C_BRG   = [0.45, 0.45, 0.50];
C_CLIP  = [0.55, 0.55, 0.58];
C_FRAME = [0.25, 0.25, 0.28];
C_LEG   = [0.30, 0.30, 0.32];

// ============================================================
// TOGGLES
// ============================================================
// ANIMATE_ONLY: set true for smooth animation — renders ONLY blocks + threads
// (skips all gears, frame, shafts → instant per frame)
ANIMATE_ONLY   = true;

SHOW_FRAME     = true;
SHOW_SHAFTS    = true;
SHOW_GEARS     = true;
SHOW_CARRIERS  = true;
SHOW_PINIONS   = true;
SHOW_THREADS   = true;
SHOW_PIXELS    = true;
SHOW_CLIPS     = true;
SHOW_BEARINGS  = true;

// DETAIL CONTROL:
// DETAIL_ROW = which row gets actual units (-1 = all rows)
// DETAIL_COLS = how many units in detail row get full gear teeth (rest = simple)
DETAIL_ROW  = -1;  // all rows show simple units
DETAIL_COLS = 0;   // 0 = no BOSL2 gear teeth (all simple shapes)

// ============================================================
// MAIN ASSEMBLY
// ============================================================
main();

module main() {
    if (ANIMATE_ONLY) {
        // Fast path: guide plate + blocks + threads
        guide_plate();
        for (row = [0 : GRID_NY-1])
            for (col = [0 : GRID_NX-1]) {
                drop = node_drop(row, col);
                // Spool position (unit grid)
                ux = node_x(row, col) + SPOOL_CENTER;
                uy = row_y(row);
                // Block position (tighter grid)
                bx = block_x(row, col);
                by = block_y(row, col);
                // Thread: spool → guide plate hole → block
                guided_thread(ux, uy, bx, by, drop);
                // Block at tighter position
                guided_pixel(bx, by, drop);
            }
    } else {
        // Full assembly
        if (SHOW_FRAME)    frame();
        if (SHOW_SHAFTS)   all_shafts();
        if (SHOW_CLIPS)    all_retaining_clips();
        if (SHOW_BEARINGS) all_shaft_bearings();
        guide_plate();

        for (row = [0 : GRID_NY-1])
            for (col = [0 : GRID_NX-1]) {
                nx = node_x(row, col);
                ny = row_y(row);
                drop = node_drop(row, col);

                // Unit (gears, spool, carriers — NO thread/pixel, those go through guide plate)
                translate([nx, ny, 0])
                if (DETAIL_ROW < 0 || row == DETAIL_ROW) {
                    if (col < DETAIL_COLS)
                        node_assy_no_thread(drop);
                    else
                        simple_node_no_thread(drop);
                } else {
                    ghost_node_no_thread(drop);
                }

                // Guided thread + hex block (through guide plate)
                if (SHOW_THREADS || SHOW_PIXELS) {
                    ux = nx + SPOOL_CENTER;
                    uy = ny;
                    bx = block_x(row, col);
                    by = block_y(row, col);
                    if (SHOW_THREADS) guided_thread(ux, uy, bx, by, drop);
                    if (SHOW_PIXELS)  guided_pixel(bx, by, drop);
                }
            }
    }
}

// ============================================================
// GHOST NODE — envelope only (placeholder rows)
// ============================================================
module ghost_node(drop=0) {
    // Ring envelope cylinders (semi-transparent)
    for (sx = [S1_LOCAL, S2_LOCAL])
        translate([sx, 0, 0])
        rotate([0, 90, 0])
        color([0.6, 0.6, 0.4, 0.25])
        cylinder(r=EXT_OR, h=GFW + CARRIER_T*2, center=true);

    // Spool envelope
    translate([SPOOL_CENTER, 0, 0])
    rotate([0, 90, 0])
    color([0.5, 0.35, 0.2, 0.25])
    cylinder(d=SPOOL_OD, h=SPOOL_H, center=true);

    // Thread + pixel (animated) — used when NOT using guide plate
    if (SHOW_THREADS) node_thread(drop);
    if (SHOW_PIXELS)  node_pixel(drop);
}

// Ghost node WITHOUT thread/pixel (guide plate handles those)
module ghost_node_no_thread(drop=0) {
    for (sx = [S1_LOCAL, S2_LOCAL])
        translate([sx, 0, 0])
        rotate([0, 90, 0])
        color([0.6, 0.6, 0.4, 0.25])
        cylinder(r=EXT_OR, h=GFW + CARRIER_T*2, center=true);
    translate([SPOOL_CENTER, 0, 0])
    rotate([0, 90, 0])
    color([0.5, 0.35, 0.2, 0.25])
    cylinder(d=SPOOL_OD, h=SPOOL_H, center=true);
}

// ============================================================
// SIMPLIFIED NODE — ring bodies + spool, no gear teeth
// ============================================================
module simple_node(drop=0) {
    // Ring bodies
    for (sx = [S1_LOCAL, S2_LOCAL])
        translate([sx, 0, 0])
        rotate([0, 90, 0]) {
            color(C_RING) cylinder(r=RING_INNER_R, h=GFW, center=true);
            // Ext ring body (no teeth, just OD)
            color(C_EXT)
            difference() {
                cylinder(r=EXT_OR, h=EXT_GFW, center=true);
                cylinder(r=RING_INNER_R, h=EXT_GFW+1, center=true);
            }
        }

    // Carrier plates (simple discs)
    for (sx = [S1_LOCAL, S2_LOCAL]) {
        car_r = (sx < 0) ? ORB1 + PIN_D + 1 : ORB2 + PIN_D + 1;
        for (side = [-1, 1])
            translate([sx, 0, 0])
            rotate([0, 90, 0])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=car_r, h=CARRIER_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
            }
    }

    // Spool drum
    translate([SPOOL_CENTER, 0, 0])
    rotate([0, 90, 0]) {
        color(C_SPL) cylinder(d=SPOOL_OD, h=SPOOL_H, center=true);
        color(C_FLNG)
        for (sz = [-1, 1])
            translate([0, 0, sz*(SPOOL_H/2 + FLANGE_T/2)])
            cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
    }

    // Drive pinions (simple cylinders)
    if (SHOW_PINIONS) {
        // B-pinion
        translate([S1_LOCAL, B_SHAFT_DY, B_SHAFT_DZ])
        rotate([0, 90, 0])
        color(C_BPIN) cylinder(r=BPIN_OR, h=EXT_GFW, center=true);
        // C-pinion
        translate([S2_LOCAL, C_SHAFT_DY, C_SHAFT_DZ])
        rotate([0, 90, 0])
        color(C_CPIN) cylinder(r=BPIN_OR, h=EXT_GFW, center=true);
    }

    if (SHOW_THREADS) node_thread(drop);
    if (SHOW_PIXELS)  node_pixel(drop);
}

// Simple node WITHOUT thread/pixel (guide plate handles those)
module simple_node_no_thread(drop=0) {
    for (sx = [S1_LOCAL, S2_LOCAL])
        translate([sx, 0, 0])
        rotate([0, 90, 0]) {
            color(C_RING) cylinder(r=RING_INNER_R, h=GFW, center=true);
            color(C_EXT)
            difference() {
                cylinder(r=EXT_OR, h=EXT_GFW, center=true);
                cylinder(r=RING_INNER_R, h=EXT_GFW+1, center=true);
            }
        }
    for (sx = [S1_LOCAL, S2_LOCAL]) {
        car_r = (sx < 0) ? ORB1 + PIN_D + 1 : ORB2 + PIN_D + 1;
        for (side = [-1, 1])
            translate([sx, 0, 0])
            rotate([0, 90, 0])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=car_r, h=CARRIER_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
            }
    }
    translate([SPOOL_CENTER, 0, 0])
    rotate([0, 90, 0]) {
        color(C_SPL) cylinder(d=SPOOL_OD, h=SPOOL_H, center=true);
        color(C_FLNG)
        for (sz = [-1, 1])
            translate([0, 0, sz*(SPOOL_H/2 + FLANGE_T/2)])
            cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
    }
    if (SHOW_PINIONS) {
        translate([S1_LOCAL, B_SHAFT_DY, B_SHAFT_DZ])
        rotate([0, 90, 0])
        color(C_BPIN) cylinder(r=BPIN_OR, h=EXT_GFW, center=true);
        translate([S2_LOCAL, C_SHAFT_DY, C_SHAFT_DZ])
        rotate([0, 90, 0])
        color(C_CPIN) cylinder(r=BPIN_OR, h=EXT_GFW, center=true);
    }
}

// ============================================================
// FULL DETAIL NODE — with BOSL2 gear teeth
// ============================================================
module node_assy(drop=0) {
    if (SHOW_GEARS)    node_stage1();
    if (SHOW_GEARS)    node_stage2();
    if (SHOW_CARRIERS) node_carriers();
    if (SHOW_PINIONS)  node_pinions();
    if (SHOW_THREADS)  node_thread(drop);
    if (SHOW_PIXELS)   node_pixel(drop);
}

// Full detail node WITHOUT thread/pixel (guide plate handles those)
module node_assy_no_thread(drop=0) {
    if (SHOW_GEARS)    node_stage1();
    if (SHOW_GEARS)    node_stage2();
    if (SHOW_CARRIERS) node_carriers();
    if (SHOW_PINIONS)  node_pinions();
}

// ============================================================
// NODE STAGE 1 — Sun1 + Ring1 + 3×Planet1 + Ring1 ext teeth
// ============================================================
module node_stage1() {
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN1
        color(C_SUN)
        rotate([0, 0, SUN1_A])
        spur_gear(mod=MOD, teeth=S1_T, thickness=GFW,
                  shaft_diam=SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S1,
                  anchor=CENTER);

        // RING1 internal
        color(C_RING)
        rotate([0, 0, RING1_A])
        ring_gear(mod=MOD, teeth=R1_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING1 external teeth
        color(C_EXT)
        rotate([0, 0, RING1_A])
        ext_ring_gear(EXT_T, EXT_GFW);

        // 3× PLANET1
        rotate([0, 0, CAR1_A])
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([ORB1, 0, 0]) {
                color(C_PLN1)
                rotate([0, 0, P1_SELF])
                spur_gear(mod=MOD, teeth=P1_T, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          backlash=BACKLASH, profile_shift=PS_P1,
                          anchor=CENTER);
            }
    }
}

// ============================================================
// NODE STAGE 2 — Sun2 + Ring2 + 3×Planet2 + Ring2 ext teeth
// ============================================================
module node_stage2() {
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN2
        color(C_SUN2)
        rotate([0, 0, SUN2_A])
        spur_gear(mod=MOD, teeth=S2_T, thickness=GFW,
                  shaft_diam=CPLG_OD, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S2,
                  anchor=CENTER);

        // RING2 internal
        color(C_RING2)
        rotate([0, 0, RING2_A])
        ring_gear(mod=MOD, teeth=R2_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING2 external teeth
        color(C_EXT2)
        rotate([0, 0, RING2_A])
        ext_ring_gear(EXT_T, EXT_GFW);

        // 3× PLANET2
        rotate([0, 0, CAR2_A])
        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([ORB2, 0, 0]) {
                color(C_PLN2)
                rotate([0, 0, P2_SELF])
                spur_gear(mod=MOD, teeth=P2_T, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          backlash=BACKLASH, profile_shift=PS_P2,
                          anchor=CENTER);
            }
    }
}

// ============================================================
// NODE CARRIERS + COUPLING + SPOOL
// ============================================================
module node_carriers() {
    // ======== CARRIER 1 ========
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=ORB1 + PIN_D + 1, h=CARRIER_T, center=true);
                cylinder(d=CPLG_OD + TOL*2, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0, 0, j*120])
                    translate([ORB1, 0, 0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }

        // Planet dowel pins
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([ORB1, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // Needle bearing
        color(C_BRG)
        cylinder(d=NEEDLE_OD, h=NEEDLE_W, center=true);

        // Coupling tube
        cplg_start = GFW/2 + CARRIER_T;
        cplg_len   = GAP + GFW/2;
        color(C_CPLG)
        translate([0, 0, cplg_start + cplg_len/2])
        difference() {
            cylinder(d=CPLG_OD, h=cplg_len, center=true);
            cylinder(d=CPLG_ID, h=cplg_len+1, center=true);
        }
    }

    // ======== CARRIER 2 + SPOOL ========
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR2)
            difference() {
                cylinder(r=ORB2 + PIN_D + 1, h=CARRIER_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0, 0, j*120 + 30])
                    translate([ORB2, 0, 0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }

        // Planet dowel pins
        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([ORB2, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // Needle bearing
        color(C_BRG)
        cylinder(d=NEEDLE_OD, h=NEEDLE_W, center=true);

        // Spool drum
        spool_z = GFW/2 + CARRIER_T + SPOOL_GAP + SPOOL_H/2;
        color(C_SPL)
        translate([0, 0, spool_z])
        difference() {
            cylinder(d=SPOOL_OD, h=SPOOL_H, center=true);
            cylinder(d=SHAFT_D + TOL*4, h=SPOOL_H + 1, center=true);
        }

        // Spool flanges
        color(C_FLNG)
        for (fz = [spool_z - SPOOL_H/2 - FLANGE_T/2,
                   spool_z + SPOOL_H/2 + FLANGE_T/2])
            translate([0, 0, fz])
            difference() {
                cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=FLANGE_T + 1, center=true);
            }

        // Web: carrier plate → spool
        web_start = GFW/2 + CARRIER_T/2;
        web_end = spool_z - SPOOL_H/2;
        web_len = web_end - web_start;
        for (a = [0:2])
            rotate([0, 0, a*120 + 15])
            color(C_CAR2)
            translate([(SHAFT_D/2 + TOL + SPOOL_ID/2)/2, 0, web_start + web_len/2])
            cube([SPOOL_ID/2 - SHAFT_D/2 - TOL, 2, web_len], center=true);
    }
}

// ============================================================
// NODE PINIONS
// ============================================================
module node_pinions() {
    // B-pinion at Stage1 — ABOVE
    translate([S1_LOCAL, B_SHAFT_DY, B_SHAFT_DZ])
    rotate([0, 90, 0]) {
        color(C_BPIN)
        rotate([0, 0, BPIN_A])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }

    // C-pinion at Stage2 — SIDE
    translate([S2_LOCAL, C_SHAFT_DY, C_SHAFT_DZ])
    rotate([0, 90, 0]) {
        color(C_CPIN)
        rotate([0, 0, CPIN_A])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }
}

// ============================================================
// NODE THREAD + PIXEL
// ============================================================
module node_thread(drop=0) {
    // drop > 0 = thread shorter = block higher (wound onto spool)
    active_len = THREAD_LEN - drop;
    spool_drop_z = -(SPOOL_OD/2);
    color(C_THR)
    translate([SPOOL_CENTER, 0, spool_drop_z - active_len/2])
    cylinder(d=0.6, h=active_len, center=true);
}

module node_pixel(drop=0) {
    active_len = THREAD_LEN - drop;
    pz = -(SPOOL_OD/2 + active_len + PIXEL_H/2);
    translate([SPOOL_CENTER, 0, pz]) {
        color(C_PIX)
        rotate([0, 0, 30])  // flat side faces X neighbors
        cylinder(d=HEX_BLOCK_AC, h=PIXEL_H, center=true, $fn=6);
        color(C_THR) translate([0, 0, PIXEL_H/2 + 0.5]) sphere(r=0.6);
    }
}

// ============================================================
// GUIDE PLATE — redirects threads from unit grid to tighter block grid
// ============================================================
module guide_plate() {
    // Plate extends to frame edges — sits on L-bracket shelves
    gp_x_min = FRAME_X_MIN;
    gp_x_max = FRAME_X_MAX;
    gp_y_min = FRAME_Y_MIN;
    gp_y_max = FRAME_Y_MAX;
    gp_cx = (gp_x_min + gp_x_max) / 2;
    gp_cy = (gp_y_min + gp_y_max) / 2;
    gp_sx = gp_x_max - gp_x_min;
    gp_sy = gp_y_max - gp_y_min;

    color([0.4, 0.4, 0.45, 0.15])  // very transparent — units visible through
    translate([gp_cx, gp_cy, GUIDE_PLATE_Z])
    difference() {
        cube([gp_sx, gp_sy, GUIDE_PLATE_T], center=true);
        for (row = [0 : GRID_NY-1])
            for (col = [0 : GRID_NX-1]) {
                hx = block_x(row, col) - gp_cx;
                hy = block_y(row, col) - gp_cy;
                // Through hole
                translate([hx, hy, 0])
                cylinder(d=GUIDE_HOLE_D, h=GUIDE_PLATE_T+2, center=true, $fn=24);
                // Top dimple — countersink fillet
                translate([hx, hy, GUIDE_PLATE_T/2 - FILLET_R + 0.01])
                cylinder(d1=GUIDE_HOLE_D, d2=GUIDE_HOLE_D + FILLET_R*2,
                         h=FILLET_R, $fn=24);
                // Bottom dimple — countersink fillet
                translate([hx, hy, -GUIDE_PLATE_T/2 - 0.01])
                cylinder(d1=GUIDE_HOLE_D + FILLET_R*2, d2=GUIDE_HOLE_D,
                         h=FILLET_R, $fn=24);
            }
    }
}

// Thread from spool position (ux,uy) through guide plate to block position (bx,by)
module guided_thread(ux, uy, bx, by, drop) {
    td = 0.6;
    hanging_len = THREAD_LEN - SPOOL_TRAVEL + drop;
    spool_z = -(SPOOL_OD/2);
    guide_z = GUIDE_PLATE_Z;
    block_z = guide_z - hanging_len;

    // Segment 1: spool → guide plate (angled)
    color(C_THR)
    hull() {
        translate([ux, uy, spool_z]) sphere(d=td, $fn=8);
        translate([bx, by, guide_z]) sphere(d=td, $fn=8);
    }
    // Segment 2: guide plate → block (straight down)
    color(C_THR)
    translate([bx, by, (guide_z + block_z) / 2])
    cylinder(d=td, h=hanging_len, center=true);
}

// Block at guide plate position — hexagonal
module guided_pixel(bx, by, drop) {
    // drop = how much thread released (0=retracted/high, max=extended/low)
    hanging_len = THREAD_LEN - SPOOL_TRAVEL + drop;  // min hang + wave drop
    block_z = GUIDE_PLATE_Z - hanging_len - PIXEL_H/2;
    translate([bx, by, block_z]) {
        color(C_PIX)
        cylinder(d=HEX_BLOCK_AF, h=PIXEL_H, center=true, $fn=6);
    }
}

// ============================================================
// EXTERNAL RING GEAR MODULE (BOSL2)
// ============================================================
module ext_ring_gear(teeth, gfw) {
    spur_gear(mod=EXT_MOD, teeth=teeth, thickness=gfw,
              shaft_diam=RING_INNER_R * 2,
              pressure_angle=PA, backlash=BACKLASH,
              profile_shift=PS_EXT, anchor=CENTER);
}

// ============================================================
// ALL SHAFTS — 5 rows × 3 shafts = 15 shafts
// ============================================================
module all_shafts() {
    for (row = [0 : GRID_NY-1]) {
        ry = row_y(row);

        // A-shaft (hex)
        color(C_SHA)
        translate([SHAFT_X_MID, ry, 0])
        rotate([0, 90, 0])
        rotate([0, 0, SUN1_A])
        cylinder(d=SHAFT_D, h=SHAFT_LEN, center=true, $fn=6);

        // B-shaft — ABOVE
        color(C_SHB)
        translate([SHAFT_X_MID, ry + B_SHAFT_DY, B_SHAFT_DZ])
        rotate([0, 90, 0])
        rotate([0, 0, B_IN])
        cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);

        // C-shaft — SIDE
        color(C_SHC)
        translate([SHAFT_X_MID, ry + C_SHAFT_DY, C_SHAFT_DZ])
        rotate([0, 90, 0])
        rotate([0, 0, C_IN])
        cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);
    }
}

// ============================================================
// RETAINING CLIPS
// ============================================================
module all_retaining_clips() {
    for (row = [0 : GRID_NY-1]) {
        ry = row_y(row);
        for (col = [0 : GRID_NX-1]) {
            nx = node_x(row, col);
            // Clip before node
            color(C_CLIP)
            translate([nx + NODE_X_MIN - CLIP_W/2 - 0.5, ry, 0])
            rotate([0, 90, 0])
            difference() {
                cylinder(d=CLIP_OD, h=CLIP_W, center=true);
                cylinder(d=SHAFT_D + TOL, h=CLIP_W+1, center=true);
            }
            // Clip after node
            color(C_CLIP)
            translate([nx + NODE_X_MAX + CLIP_W/2 + 0.5, ry, 0])
            rotate([0, 90, 0])
            difference() {
                cylinder(d=CLIP_OD, h=CLIP_W, center=true);
                cylinder(d=SHAFT_D + TOL, h=CLIP_W+1, center=true);
            }
        }
    }
}

// ============================================================
// SHAFT BEARINGS — at frame ends
// ============================================================
module all_shaft_bearings() {
    for (row = [0 : GRID_NY-1]) {
        ry = row_y(row);
        for (end_x = [SHAFT_X_START + BRG_W/2, SHAFT_X_END - BRG_W/2]) {
            // A-shaft bearing
            translate([end_x, ry, 0])
            rotate([0, 90, 0])
            brg(BRG_OD, BRG_ID, BRG_W);

            // B-shaft bearing
            translate([end_x, ry + B_SHAFT_DY, B_SHAFT_DZ])
            rotate([0, 90, 0])
            brg(BRG_OD, BC_SHAFT_D, BRG_W);

            // C-shaft bearing
            translate([end_x, ry + C_SHAFT_DY, C_SHAFT_DZ])
            rotate([0, 90, 0])
            brg(BRG_OD, BC_SHAFT_D, BRG_W);
        }
    }
}

// ============================================================
// FRAME
// ============================================================
module frame() {
    fz = FRAME_Z;

    // ==== PERIMETER RAILS ====
    // Front
    color(C_FRAME)
    translate([FRAME_MX, FRAME_Y_MIN, fz])
    cube([FRAME_X_LEN, FRAME_BAR, FRAME_BAR], center=true);
    // Back
    color(C_FRAME)
    translate([FRAME_MX, FRAME_Y_MAX, fz])
    cube([FRAME_X_LEN, FRAME_BAR, FRAME_BAR], center=true);
    // Left
    color(C_FRAME)
    translate([FRAME_X_MIN, FRAME_MY, fz])
    cube([FRAME_BAR, FRAME_Y_LEN + FRAME_BAR*2, FRAME_BAR], center=true);
    // Right
    color(C_FRAME)
    translate([FRAME_X_MAX, FRAME_MY, fz])
    cube([FRAME_BAR, FRAME_Y_LEN + FRAME_BAR*2, FRAME_BAR], center=true);

    // ==== CROSS-BARS at each row ====
    for (row = [0 : GRID_NY-1]) {
        ry = row_y(row);
        color([0.30, 0.30, 0.33])
        translate([FRAME_MX, ry, fz])
        cube([FRAME_X_LEN, FRAME_BAR*0.6, FRAME_BAR], center=true);
    }

    // ==== BEARING DROPS ====
    for (row = [0 : GRID_NY-1]) {
        ry = row_y(row);
        for (end_x = [SHAFT_X_START, SHAFT_X_END]) {
            // A-shaft drop
            color([0.32, 0.32, 0.35])
            translate([end_x, ry, fz/2])
            cube([FRAME_BAR*0.4, FRAME_BAR*0.4, fz], center=true);

            // B-shaft drop (short)
            b_drop_h = fz - B_SHAFT_DZ;
            color([0.32, 0.32, 0.35])
            translate([end_x, ry + B_SHAFT_DY, B_SHAFT_DZ + b_drop_h/2])
            cube([FRAME_BAR*0.3, FRAME_BAR*0.3, b_drop_h], center=true);

            // C-shaft drop (also elevated now)
            c_drop_h = fz - C_SHAFT_DZ;
            color([0.32, 0.32, 0.35])
            translate([end_x, ry + C_SHAFT_DY, C_SHAFT_DZ + c_drop_h/2])
            cube([FRAME_BAR*0.3, FRAME_BAR*0.3, c_drop_h], center=true);
        }
    }

    // ==== GUIDE PLATE ANCHOR BRACKETS ====
    // L-brackets: vertical drop from frame rail → horizontal shelf under plate
    bracket_w = 5;
    bracket_t = 3;  // thickness of L-bracket arms
    gp_drop_h = fz - GUIDE_PLATE_Z + GUIDE_PLATE_T/2;  // frame rail to plate bottom
    shelf_len = 20;  // horizontal shelf extending inward under the plate

    // 4 brackets at frame corners
    for (bx = [FRAME_X_MIN, FRAME_X_MAX])
        for (by = [FRAME_Y_MIN, FRAME_Y_MAX]) {
            // Inward direction for shelf
            sx = bx < FRAME_MX ? 1 : -1;
            sy = by < FRAME_MY ? 1 : -1;

            color([0.45, 0.45, 0.48]) {
                // Vertical drop: frame rail down to plate level
                translate([bx, by, GUIDE_PLATE_Z - GUIDE_PLATE_T/2 + gp_drop_h/2])
                cube([bracket_w, bracket_t, gp_drop_h], center=true);

                // Horizontal shelf: extends inward under the plate
                translate([bx + sx * shelf_len/2, by, GUIDE_PLATE_Z - GUIDE_PLATE_T/2 - bracket_t/2])
                cube([shelf_len, bracket_t, bracket_t], center=true);
            }
        }

    // ==== 4 LEGS ====
    leg_pos = [
        [FRAME_X_MIN, FRAME_Y_MIN],
        [FRAME_X_MAX, FRAME_Y_MIN],
        [FRAME_X_MIN, FRAME_Y_MAX],
        [FRAME_X_MAX, FRAME_Y_MAX]
    ];
    for (lp = leg_pos)
        color(C_LEG)
        translate([lp[0], lp[1], fz - LEG_HEIGHT/2 - FRAME_BAR/2])
        cube([LEG_SECTION, LEG_SECTION, LEG_HEIGHT], center=true);
}

// ============================================================
// BEARING (utility)
// ============================================================
module brg(od, id, w) {
    color(C_BRG) difference() {
        cylinder(d=od, h=w, center=true);
        cylinder(d=id, h=w+1, center=true);
    }
}
