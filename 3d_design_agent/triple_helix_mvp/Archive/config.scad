// =========================================================
// TRIPLE HELIX MVP — MASTER CONFIGURATION
// =========================================================
// Single source of truth. All dimensions in mm.
// Based on MATRIX SINGLE UNIT v5.scad (the proven tier design).
//
// Architecture:
//   - Each tier = V5 unit (5 channels, 19 pulleys)
//   - 3 tiers stacked at 0°/120°/240° rotation
//   - 3 helix camshafts (one per tier, at opposite hex vertices)
//   - Single motor → belt/chain → 3 helices
//   - 19 ropes → 19 blocks
// =========================================================

$fn = 60;

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;  // -1 = use $t; 0.0-1.0 = static debug
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// V5 CHANNEL DIMENSIONS — COMPRESSED
// =============================================
// Based on MATRIX SINGLE UNIT v5.scad, with vertical compression:
//   - CH_GAP: 19 → 12mm (smaller pulleys + thinner slider)
//   - WALL: 3 → 2mm (5 perimeters at 0.4mm nozzle)
//   - S_GAP: 8 → 5mm (4mm slider pulleys)
//   - FP_ROW_Y: 22.5 → 12mm (tighter U-detour)
//   - HOUSING_HEIGHT: 70 → 40mm
//   - Pulleys: FP 13→8mm, SP 10→8mm, widths 18→4mm/7→4mm
//
// Math validation:
//   plate_t = (12/2)-(5/2)-0.3 = 3.2mm ≥ slot_d(1.8mm) ✓
//   FP fits: 8mm < 12-0.6=11.4mm ✓
//   SP fits: SP_WIDTH=4mm < S_GAP-0.6=4.4mm ✓ (SP_OD=8mm is perpendicular, not in gap)
//   sp_w_real = min(4, 5-0.6) = 4mm ✓
//   fp_ax_real = 12 + 2*2 - 0.2 = 15.8mm ✓
//   sp_ax_real = 5 + 2*(3.2-1.8) - 0.2 = 7.6mm ✓
// =============================================

NUM_CHANNELS      = 5;
TOTAL_PULLEYS     = 19;  // 3+4+5+4+3

/* [Global — Compressed] */
STACK_OFFSET      = 14.0;   // CH_GAP + WALL = 12 + 2
HOUSING_HEIGHT    = 40.0;   // 2×FP_ROW_Y + FP_OD + 4 = 2×12+8+4 = 36 → 40mm
WALL_THICKNESS    = 2.0;    // 5 perimeters at 0.4mm nozzle
FP_ROW_Y          = 12.0;   // redirect pulley Y-offset (compressed from 22.5)

/* [Guide Rail] */
RAIL_HEIGHT       = 4.0;
RAIL_DEPTH        = 1.0;    // reduced from 1.5 (still functional guide)
RAIL_TOLERANCE    = 0.4;
END_STOP_W        = 5.0;
WINDOW_WIDTH      = 30.0;   // reduced from 40 (fits smaller housing)
WINDOW_HEIGHT     = 20.0;   // reduced from 30

/* [Print-in-Place] */
PIP_CLEARANCE     = 0.3;
PIP_Z_GAP         = 0.3;

// --- Per-Channel Specs ---
// Housing gaps (compressed from 19mm)
CH_GAPS    = [12.0, 12.0, 12.0, 12.0, 12.0];
// Housing lengths (unchanged — hex boundary geometry)
CH_LENS    = [83.0, 111.0, 136.0, 112.0, 83.0];
// Housing center X offsets (unchanged — hex boundary geometry)
CH_CXS     = [-51.0, -51.0, -51.0, -53.0, -53.0];

// Fixed pulley counts per channel (unchanged)
FP_COUNTS  = [3, 4, 5, 4, 3];
// Fixed pulley specs — compressed
FP_PITCH   = 29.0;     // unchanged (pulley spacing along channel)
FP_OD      = 8.0;      // was 13 — 8mm min for V-groove with 0.5mm Dyneema
FP_WIDTH   = 4.0;      // was 18 — groove(1.5) + 2×flange(1.25)
FP_AXLE_DIA = 3.0;     // was 5 — M3 steel pin
FP_AXLE_LEN = 16.0;    // was 25.2 — spans CH_GAP+2×WALL = 12+4 = 16

// Slider gaps (compressed from 8mm)
CH_S_GAPS  = [5.0, 5.0, 5.0, 5.0, 5.0];
// Slider lengths (unchanged — determined by pulley count × pitch + travel)
CH_S_LENS  = [166.0, 222.0, 272.0, 224.0, 166.0];
// Slider center X offsets (unchanged)
CH_S_CXS   = [-44.0, -44.0, -51.0, -44.0, -45.0];
// Slider Y shifts (all zero)
CH_S_YS    = [0.0, 0.0, 0.0, 0.0, 0.0];

// Slider pulley counts per channel (matches fixed)
SP_COUNTS  = [3, 4, 5, 4, 3];
// Slider pulley specs — compressed
SP_PITCH   = 46.0;     // unchanged
SP_OD      = 8.0;      // was 10 — matches FP_OD for consistency
SP_WIDTH   = 4.0;      // was 7 — same as FP_WIDTH
SP_AXLE_DIA = 3.0;     // was 5
SP_AXLE_LEN = 8.0;     // unchanged — spans slider gap

// =============================================
// TIER ENVELOPE (derived — all computed from compressed values)
// =============================================
// Channel Z-centers: (i-2)*STACK_OFFSET
// CH1 at Z=-28, CH2=-14, CH3=0, CH4=+14, CH5=+28
// Top of CH5: 28 + 6(half gap) + 2(wall) = 36
// Bottom of CH1: -28 - 6 - 2 = -36
// Total tier height = 72mm
TIER_ENVELOPE_H   = 4*STACK_OFFSET + CH_GAPS[0] + 2*WALL_THICKNESS;  // 4×14+12+4 = 72mm

// Tier geometric center in V5 local X coordinate
// Bounding box: leftmost = min(CX - LEN/2) = -119, rightmost = max(CX + LEN/2) = 17
// CENTER_X = (-119 + 17) / 2 = -51
TIER_CENTER_X     = -51.0;  // CRITICAL — rotation pivot for tier stacking

// =============================================
// MATRIX STACK (3 tiers)
// =============================================
NUM_TIERS         = 3;
TIER_ANGLES       = [0, 120, 240];

/* [Matrix Stack] */
// Tiers stacked with ZERO gap — direct contact, snap-fit.
// Guide plates go BELOW the entire matrix stack (not between tiers).
// Ropes transition between tiers through holes in the shared boundary walls.
INTER_TIER_GAP    = 0;  // zero — pancakes stacked directly

// CRITICAL: After rotate([90,0,0]), the vertical height of each tier
// in display space = HOUSING_HEIGHT (V5 Y → display Z).
// NOT TIER_ENVELOPE_H (which is the front-to-back channel spread).
//
// TIER_DISPLAY_HEIGHT = HOUSING_HEIGHT = 40mm (the "pancake thickness")
// TIER_ENVELOPE_H = 72mm = front-to-back depth (channel stacking → display Y)
//
TIER_DISPLAY_HEIGHT = HOUSING_HEIGHT;  // 40mm — actual vertical extent per tier

// Tier pitch = vertical center-to-center distance between adjacent tiers
TIER_PITCH        = TIER_DISPLAY_HEIGHT + INTER_TIER_GAP;  // 40mm — zero gap

// Total matrix stack display height (in vertical/Z direction after rotation)
// = 3 tiers × 40mm display height + 0mm gaps = 120mm
MATRIX_TOTAL_H    = NUM_TIERS * TIER_DISPLAY_HEIGHT + (NUM_TIERS - 1) * INTER_TIER_GAP;

// =============================================
// HELIX CAMSHAFT
// =============================================
NUM_CAMS          = 5;        // one per CHANNEL STRIP (not per pulley!)
TWIST_PER_CAM     = 360.0 / NUM_CAMS;  // 72°
ECCENTRICITY      = 12.0;    // mm cam throw (±12mm slider travel)
CAM_STROKE        = 2 * ECCENTRICITY;  // 24mm peak-to-peak

// Bearing: 6800ZZ (10/19/5mm)
BEARING_ID        = 10.0;
BEARING_OD        = 19.0;
BEARING_W         = 5.0;

// Hub attachment: press-fit + set screw (no bolt pattern — bore too small)
SETSCREW_DIA      = 3.0;     // M3 set screw
SHAFT_DIA         = 10.0;    // matches bearing ID (shaft through bearing bore)

// Helix stack
AXIAL_PITCH       = 8.0;     // mm per cam disc (bearing_w=5 + collar=3)
HELIX_LENGTH      = NUM_CAMS * AXIAL_PITCH;  // 40mm (5 × 8)
CENTER_PIN_DIA    = 5.0;     // alignment pin through shaft center
COLLAR_THICK      = AXIAL_PITCH - BEARING_W;  // 3mm spacer

// Gravity rib (cam follower arm)
// Arm reach must bridge from helix shaft to matrix slider entry.
// Derived after frame/helix positioning — placeholder until geometry settles.
RIB_ARM_LENGTH    = 40.0;    // will be re-derived from helix-to-matrix distance
RIB_THICK         = 5.0;     // was 6
RIB_ARM_WIDTH     = 6.0;     // was 8
RIB_TAPER_TIP     = 4.0;     // was 5
RIB_EYELET_DIA    = 2.0;     // was 3 — sized for 0.5mm Dyneema
SOFT_STOP_ANGLE   = 15;
GUIDE_SLOT_W      = 2.0;
GUIDE_SLOT_H      = 20.0;    // was 30 — proportional to smaller rib ring

// =============================================
// HELIX POSITIONING (CRITICAL — from user's drawings)
// =============================================
// Each helix shaft is PERPENDICULAR to its tier's slider direction.
// Positioned at the hex vertex OPPOSITE to the slider entry side.
// Followers extend INWARD (toward matrix center), PARALLEL to sliders.
//
// Tier 0° sliders → Helix at 180° vertex, shaft along ~90°
// Tier 120° sliders → Helix at 300° vertex, shaft along ~210°
// Tier 240° sliders → Helix at 60° vertex, shaft along ~330°

/* [Helix Positioning — Configurable] */
HELIX_DISTANCE    = 30.0;   // [10:1:80] mm from hex edge to helix shaft center
DAMPENER_LENGTH   = 20.0;   // [5:1:50] mm dampener tube length
DAMPENER_DIA      = 6.0;    // [3:0.5:12] mm dampener tube OD
WIRE_DIA          = 0.5;    // mm braided Dyneema/PE (same as STRING_DIA)

// Helix vertex angles (where each helix shaft is centered)
// These are hex vertices, not face centers
HELIX_VERTEX_ANGLES = [180, 300, 60];  // for tiers at [0, 120, 240]

// =============================================
// FRAME
// =============================================
// Matrix circumscribed circle (after centering + rotation):
//   halfW = max(|-119-(-51)|, |17-(-51)|) = max(68, 68) = 68mm
//   halfH = 2×STACK_OFFSET + CH_GAP/2 + WALL = 2×14+6+2 = 36mm
//   circ_R = sqrt(68² + 36²) = sqrt(4624+1296) = sqrt(5920) = 77mm
// Frame F-F must clear this by ~15mm per side:
//   FRAME_DIAMETER = 2×(77+15) = 184mm → round to 185mm
FRAME_DIAMETER    = 185;     // mm flat-to-flat (hex) — was 300
FRAME_HEX_R      = FRAME_DIAMETER / 2;
FRAME_CORNER_R   = FRAME_HEX_R / cos(30);
FRAME_HEIGHT      = 350;     // was 500 — proportional to compressed stack
FRAME_ROD_DIA     = 6.0;    // M6 threaded rod
FRAME_WALL        = 4.0;

// =============================================
// DRIVE SYSTEM (BELT/CHAIN)
// =============================================
// Single motor drives one helix; belts distribute to other two
DRIVE_PULLEY_DIA  = 30.0;   // belt pulley on each helix shaft end
BELT_WIDTH        = 10.0;

/* [Drive — Configurable] */
MOTOR_POSITION_ANGLE = 180;  // [0:10:350] degrees on frame where motor sits
CRANK_ARM         = 80.0;    // mm hand crank arm length
CRANK_HANDLE_DIA  = 12.0;
CRANK_HANDLE_LEN  = 30.0;

// =============================================
// GUIDE PLATE (post-matrix dampener)
// =============================================
GUIDE_PLATE_THICK = 3.0;
GUIDE_PLATE_GAP   = 15.0;
GUIDE_BUSHING_BORE = 2.0;
GUIDE_FUNNEL_DIA  = 5.0;
POST_MATRIX_GAP   = 30.0;   // gap between Tier 3 bottom and guide plate 1

// =============================================
// BLOCK GRID
// =============================================
HEX_RINGS         = 2;
NUM_BLOCKS        = 19;
BLOCK_FF          = 30;      // flat-to-flat
BLOCK_HEIGHT      = 20;
BLOCK_SPACING     = 32;      // center-to-center
BLOCK_WEIGHT      = 80;      // grams

// =============================================
// STRING / CABLE — unified 0.5mm braided Dyneema/PE
// =============================================
// Both block suspension strings AND cam-follower-to-slider wires
// use the same material for MVP simplicity.
// Breaking strength: ~45-60N (0.5mm braided Dyneema)
// Block load: 0.785N → safety factor 57×
// Worst-case cam-to-slider load (CH3, 5 strings): 9.7N → safety factor 4.6×
// Stretch: <1% → responsive motion
STRING_DIA        = 0.5;     // mm — braided Dyneema/PE
CABLE_SLOT_W      = 3.0;
CABLE_SLOT_H      = CAM_STROKE + 4.0;  // 28mm
CABLE_DIA         = 0.5;     // mm — same as STRING_DIA (unified)

// Friction — Dyneema on PLA/PTFE pulleys
FRICTION_PER_PULLEY  = 0.97;   // Dyneema on smooth PLA V-groove
FRICTION_PER_BUSHING = 0.995;  // Dyneema through PTFE guide bushing
PULLEYS_PER_STRING   = 9;      // 3 per tier × 3 tiers (redirect_in + slider + redirect_out)
BUSHINGS_PER_STRING  = 2;      // guide plate bushings
FRICTION_EFF = pow(FRICTION_PER_PULLEY, PULLEYS_PER_STRING) *
               pow(FRICTION_PER_BUSHING, BUSHINGS_PER_STRING);  // = 75.0%

// =============================================
// COLORS
// =============================================
C_ACRYLIC = [0.85, 0.92, 0.95, 0.3];
C_NYLON   = [0.95, 0.95, 0.92, 1.0];
C_STEEL   = [0.7,  0.7,  0.75, 1.0];
C_STRING  = [0.1,  0.1,  0.1,  1.0];
C_BLOCK   = [0.82, 0.71, 0.55, 1.0];
C_SLIDER  = [0.9,  0.4,  0.4,  1.0];
C_FRAME   = [0.4,  0.4,  0.45, 1.0];
C_GUIDE   = [0.6,  0.85, 0.6,  0.8];
C_WIRE    = [0.3,  0.3,  0.3,  1.0];
C_BELT    = [0.2,  0.2,  0.2,  0.8];

// =============================================
// PRINT BED: Creality K2 Plus
// =============================================
BED_X = 350;
BED_Y = 350;
BED_Z = 350;

// =============================================
// HEX GRID GENERATOR
// =============================================
function hex_grid(rings, spacing) =
    [for (q = [-rings : rings])
        for (r = [-rings : rings])
            let(s = -q - r)
            if (abs(s) <= rings)
                [spacing * (q + r / 2), spacing * r * sqrt(3) / 2]
    ];

// =============================================
// WAVE FUNCTIONS
// =============================================
WAVE_DIRS = [[1, 0], [-0.5, 0.866], [-0.5, -0.866]];
WAVE_K = TWIST_PER_CAM / BLOCK_SPACING;

function slider_phase(block_pos, helix_idx) =
    WAVE_K * (block_pos[0] * WAVE_DIRS[helix_idx][0] +
              block_pos[1] * WAVE_DIRS[helix_idx][1]);

function slider_disp(block_pos, helix_idx, t) =
    ECCENTRICITY * sin(t * 360 + slider_phase(block_pos, helix_idx));

GAIN_PER_TIER = 1.0;
function block_disp(block_pos, t) =
    GAIN_PER_TIER * (
        slider_disp(block_pos, 0, t) +
        slider_disp(block_pos, 1, t) +
        slider_disp(block_pos, 2, t)
    );

_hex_positions = hex_grid(HEX_RINGS, BLOCK_SPACING);
function block_disp_idx(block_idx, t) =
    block_disp(_hex_positions[block_idx], t);

// =============================================
// CAM-TO-CHANNEL MAPPING (1:1 — one cam per channel strip)
// =============================================
// Cam 0 → CH1 strip (3 pulleys), Cam 1 → CH2 (4), Cam 2 → CH3 (5),
// Cam 3 → CH4 (4), Cam 4 → CH5 (3)
function cam_to_channel(cam_idx) = cam_idx;  // direct 1:1

// Channel Z-centers (from V5: centered around 0, before tier rotation)
function channel_z(ch_idx) = (ch_idx - 2) * STACK_OFFSET;

// Block-to-channel mapping
// Blocks are ordered by channel: CH1 has 3 (idx 0-2), CH2 has 4 (idx 3-6),
// CH3 has 5 (idx 7-11), CH4 has 4 (idx 12-15), CH5 has 3 (idx 16-18)
// Cumulative: [0, 3, 7, 12, 16, 19]
_FP_CUM = [0,
    FP_COUNTS[0],
    FP_COUNTS[0] + FP_COUNTS[1],
    FP_COUNTS[0] + FP_COUNTS[1] + FP_COUNTS[2],
    FP_COUNTS[0] + FP_COUNTS[1] + FP_COUNTS[2] + FP_COUNTS[3],
    TOTAL_PULLEYS
];

// Which channel does block i belong to?
function block_channel(i) =
    (i < _FP_CUM[1]) ? 0 :
    (i < _FP_CUM[2]) ? 1 :
    (i < _FP_CUM[3]) ? 2 :
    (i < _FP_CUM[4]) ? 3 : 4;

// Which position within its channel is block i?
function block_pos_in_channel(i) = i - _FP_CUM[block_channel(i)];

// Fixed pulley X position for block i (absolute, in tier-local frame)
function block_fp_x(i) =
    pulley_x_in_channel(block_channel(i), block_pos_in_channel(i));

// Slider pulley X for block i (at rest — slider centered)
// Slider pulleys use SP_PITCH spacing, centered on channel
function block_sp_x(i) =
    let(ch = block_channel(i),
        pos = block_pos_in_channel(i),
        count = SP_COUNTS[ch],
        start_x = -((count - 1) / 2) * SP_PITCH)
    CH_S_CXS[ch] + start_x + pos * SP_PITCH;

// Pulley X position within a channel (centered around channel center_x)
function pulley_x_in_channel(ch_idx, pulley_idx) =
    let(count = FP_COUNTS[ch_idx],
        start_x = -((count - 1) / 2) * FP_PITCH)
    CH_CXS[ch_idx] + start_x + pulley_idx * FP_PITCH;

// =============================================
// INTERNAL VALIDATION — silent unless failure
// =============================================
// plate_t check
_plate_t = (CH_GAPS[0]/2) - (CH_S_GAPS[0]/2) - PIP_Z_GAP;
_slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;
if (_plate_t < _slot_d)
    echo(str("⚠ PLATE_T FAIL: ", _plate_t, " < slot_d ", _slot_d));

// Stack offset check
_required_so = CH_GAPS[0]/2 + WALL_THICKNESS + CH_GAPS[0]/2;
if (abs(STACK_OFFSET - _required_so) > 0.1)
    echo(str("⚠ STACK_OFFSET FAIL: is ", STACK_OFFSET, " need ", _required_so));

// FP fit check
if (FP_OD > CH_GAPS[0] - 2*PIP_Z_GAP)
    echo(str("⚠ FP_OD FAIL: ", FP_OD, " > gap ", CH_GAPS[0] - 2*PIP_Z_GAP));

// SP fit check
_sp_w_real = min(SP_WIDTH, CH_S_GAPS[0] - 2*PIP_Z_GAP);
if (SP_WIDTH > CH_S_GAPS[0] - 2*PIP_Z_GAP)
    echo(str("⚠ SP clamped: ", SP_WIDTH, " → ", _sp_w_real));

// Housing depth check
_min_hh = 2*FP_ROW_Y + FP_OD + 4;
if (HOUSING_HEIGHT < _min_hh)
    echo(str("⚠ HOUSING_HEIGHT FAIL: ", HOUSING_HEIGHT, " < min ", _min_hh));

// =============================================
// VERIFICATION ECHOES
// =============================================
echo(str("=== TRIPLE HELIX MVP CONFIG — COMPRESSED ==="));
echo(str("Channels/tier: ", NUM_CHANNELS, " | Pulleys/tier: ", TOTAL_PULLEYS,
         " | Cams/helix: ", NUM_CAMS));
echo(str("Tier height: ", TIER_ENVELOPE_H, "mm (was 113)"));
echo(str("Tier pitch: ", TIER_PITCH, "mm | Stack display H: ", MATRIX_TOTAL_H, "mm | Depth: ", TIER_ENVELOPE_H, "mm"));
echo(str("Tier center X: ", TIER_CENTER_X, "mm (rotation pivot)"));
echo(str("Helix: ", HELIX_LENGTH, "mm | Bearing: 6800ZZ (", BEARING_ID, "/", BEARING_OD, "/", BEARING_W, ")"));
echo(str("Frame: ", FRAME_DIAMETER, "mm F-F (was 300) | Corner: ", round(FRAME_CORNER_R*2), "mm"));
echo(str("Friction: ", round(FRICTION_EFF * 1000) / 10, "% | plate_t: ", _plate_t, "mm"));
echo(str("Max travel: ±", GAIN_PER_TIER * ECCENTRICITY * 3, "mm"));

// Bed fit checks
_longest_ch = max(CH_LENS[0], CH_LENS[1], CH_LENS[2], CH_LENS[3], CH_LENS[4]);
echo(str("BED: channel=", _longest_ch, ((_longest_ch < BED_X) ? " ✓" : " ⚠"),
         " | helix=", HELIX_LENGTH, ((HELIX_LENGTH < BED_Z) ? " ✓" : " ⚠"),
         " | frame=", round(FRAME_CORNER_R*2), ((FRAME_CORNER_R*2 < BED_X) ? " ✓" : " ⚠")));

_hex_check = len(hex_grid(HEX_RINGS, BLOCK_SPACING));
echo(str("Hex grid: ", _hex_check, " blocks (expected ", NUM_BLOCKS, ")"));
