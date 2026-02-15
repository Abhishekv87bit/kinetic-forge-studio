// =========================================================
// CONFIG V5.2 — Single Source of Truth for Triple Helix MVP
// =========================================================
// V5.2 PROTOTYPE: true 75% scale + monolithic print-in-place matrix.
//
// INCLUDE this file (not `use`) in every V5.2 module.
// All shared parameters live here. No file duplicates any value.
//
// KEY CHANGES from V5:
//   V5.2: HEX_R=89 (true 75% of 118mm) → 11 channels, monolithic matrix (zero-gap, print-in-place)
//   - INTER_TIER_GAP = 0 (monolithic print-in-place matrix, no tier separation)
//   - Alignment pins added for hex registration of anchor/guide plates
//   - All formulas unchanged — only base parameters updated
//
// DECOUPLED SPACING (the "middle way"):
//   Matrix channels spaced at STACK_OFFSET = 12mm (tight matrix, 11 ch)
//   Cam discs spaced at AXIAL_PITCH = 14mm (thick discs, spread out)
//   Each cam drives one channel via cable — physical spacing needn't match.
//   This gives 11 channels with comfortable disc geometry.
//
// Architecture:
//   HEX_R → derives channels, column positions, hex geometry
//   STACK_OFFSET → derives channel spacing (matrix only)
//   AXIAL_PITCH → derives cam pitch, disc thickness, helix length (cam only)
//   ECCENTRICITY → derives stroke, slider bias, travel limits
//   SHAFT_DIA → derives D-bore, set screw boss, frame bearings
//
// Stagger system: odd channels offset by COL_PITCH/2 in X.
//   All files that place columns MUST use col_x(count, idx, ch_idx).
// =========================================================

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// HEX GEOMETRY — the ONE sizing parameter
// =============================================
/* [Hex Tier] */
HEX_R         = 89;       // true 75% of full-scale 118mm → 11 channels

HEX_C2C       = 2 * HEX_R;                     // corner-to-corner = 178mm
HEX_FF        = HEX_R * sqrt(3);               // flat-to-flat = 154.1mm
HEX_LONGEST_DIA = HEX_C2C;                     // alias

/* [Column Spacing] */
COL_PITCH     = 12;        // [8:1:30] column-to-column X pitch
WALL_MARGIN   = 8;         // [4:1:15] clearance from hex edge to first column

/* [Channel Stacking] */
STACK_OFFSET  = 12.0;      // channel center-to-center in matrix (12mm → 11 channels)

// Channel count (derived from hex geometry)
function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;  // 11 at HEX_R=89, STACK_OFFSET=12

// Channel offsets and widths
_CENTER_CH = (NUM_CHANNELS - 1) / 2;
CH_OFFSETS = [for (i = [0:NUM_CHANNELS-1]) (i - _CENTER_CH) * STACK_OFFSET];

function hex_w(d) =
    let(max_d = HEX_FF / 2)
    (abs(d) > max_d) ? 0 : 2 * (HEX_R - abs(d) / sqrt(3));

function ch_len(d) = max(0, hex_w(d) - 2 * WALL_MARGIN);

CH_LENS = [for (i = [0:NUM_CHANNELS-1]) ch_len(CH_OFFSETS[i])];

// =============================================
// PULLEY DIMENSIONS (declared early — column culling depends on these)
// =============================================
/* [Pulleys] */
FP_OD         = 8.0;       // fixed pulley OD
SP_OD         = 8.0;       // slider pulley OD
_MIN_ROPE_GAP = 2.0;       // gap between FP and SP rows for rope passage

FP_ROW_Y      = (FP_OD + SP_OD) / 2 + _MIN_ROPE_GAP;  // derived: 10mm for 8mm pulleys

// =============================================
// PULLEY STAGGER — prevents adjacent channels sharing X positions
// =============================================
STAGGER_HALF_PITCH = COL_PITCH / 2;  // 6mm offset on odd channels

function _col_x_base(count, idx) =
    -((count - 1) / 2) * COL_PITCH + idx * COL_PITCH;

function _ch_stagger(ch_idx) = (ch_idx % 2) * STAGGER_HALF_PITCH;

function col_x(count, idx, ch_idx=0) =
    _col_x_base(count, idx) + _ch_stagger(ch_idx);

function col_inside_hex(px, d) =
    let(max_od = max(FP_OD, SP_OD))
    (abs(px) + max_od/2 + 1) < (hex_w(d) / 2);

function raw_col_count(len) =
    (len < COL_PITCH) ? ((len > max(FP_OD, SP_OD)) ? 1 : 0) :
    floor(len / COL_PITCH) + 1;

function culled_col_count(ch_idx) =
    let(d = CH_OFFSETS[ch_idx],
        len = CH_LENS[ch_idx],
        raw = raw_col_count(len))
    len <= 0 ? 0 :
    let(valid = [for (j = [0:max(0, raw-1)])
        if (col_inside_hex(col_x(raw, j, ch_idx), d)) 1])
    len(valid);

COL_COUNTS = [for (i = [0:NUM_CHANNELS-1]) culled_col_count(i)];

// =============================================
// MECHANICS
// =============================================
/* [Mechanics] */
ECCENTRICITY  = 12.0;      // mm cam throw — per master prompt (gentler wave at 75% scale)
CAM_STROKE    = 2 * ECCENTRICITY;  // 24mm peak-to-peak

/* [Slider Bias] */
SLIDER_BIAS        = 0.80;     // per master prompt (rest position bias toward helix)
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS;  // 9.6mm toward helix side

// =============================================
// HOUSING / TIER
// =============================================
WALL_THICKNESS = 2.5;
CH_GAP         = STACK_OFFSET - WALL_THICKNESS;     // 11.5mm
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2;         // 30mm (derived)

// =============================================
// TIER STACKING
// =============================================
NUM_TIERS     = 3;
TIER_ANGLES   = [0, 120, 240];
INTER_TIER_GAP = 0.0;                                // zero-gap: monolithic print-in-place matrix
TIER_PITCH    = HOUSING_HEIGHT + INTER_TIER_GAP;     // 30mm (housing + gap)

// Z-layout: matrix centered at Z=0
TIER1_TOP     = TIER_PITCH + HOUSING_HEIGHT / 2;     // +45
TIER3_BOT     = -TIER_PITCH - HOUSING_HEIGHT / 2;    // -45

// =============================================
// ANCHOR & GUIDE PLATES
// =============================================
ANCHOR_THICK      = 5.0;
GP1_THICK         = 3.0;
GP2_THICK         = 5.0;
GUIDE_PLATE_GAP   = 15.0;

ANCHOR_Z  = TIER1_TOP;                               // +45
GP1_Z     = TIER3_BOT;                               // -45
GP2_Z     = GP1_Z - GP1_THICK - GUIDE_PLATE_GAP;     // -63
GP2_BOT   = GP2_Z - GP2_THICK;                        // -68

// =============================================
// ALIGNMENT PINS — hex registration for anchor/guide plates
// =============================================
ALIGN_PIN_DIA     = 3.0;       // pin diameter
ALIGN_PIN_HOLE    = 3.2;       // hole in plate (clearance fit)
ALIGN_PIN_DEPTH   = 5.0;       // insertion depth per side
ALIGN_PIN_COUNT   = 3;         // 3 pins at 60° intervals on hex perimeter
ALIGN_PIN_R       = HEX_R - 5; // pin circle radius (5mm inboard of hex edge)

// =============================================
// CENTRAL SHAFT — 5mm stainless steel rod (V5)
// =============================================
// Replaces V4 shaftless disc-to-disc bolt design.
// One continuous rod per helix, D-flat for indexing.
SHAFT_DIA         = 5.0;       // rod diameter
D_FLAT_DEPTH      = 0.5;       // D-flat cut depth (chord distance from surface)
SHAFT_BORE        = SHAFT_DIA + 0.2;  // bore in disc for sliding fit
D_BORE_FLAT       = SHAFT_DIA - 2 * D_FLAT_DEPTH;  // chord width of D-flat

// =============================================
// FRAME BEARINGS — 625ZZ (5x16x5mm)
// =============================================
// 6 total: 2 per helix, press-fit into carrier plates at arm End B.
// These are purchased steel ball bearings (not printed).
FRAME_BRG_ID  = 5.0;
FRAME_BRG_OD  = 16.0;
FRAME_BRG_W   = 5.0;

// =============================================
// HELIX CAM — Central Shaft Disc Parameters (V5.2)
// =============================================
NUM_CAMS       = NUM_CHANNELS;                        // 11 discs (1 cam per channel)
TWIST_PER_CAM  = 360.0 / NUM_CAMS;                   // 32.73°
HELIX_ANGLES   = [180, 300, 60];                      // where 3 helices sit

// DISC-AROUND-SHAFT ECCENTRIC CAM (V5)
//
// DESIGN: Large circular disc with shaft boss at disc edge.
//   The disc IS the eccentric — its center is offset from the shaft.
//   A large bearing wraps the entire disc outer circumference.
//   A follower ring rides on the bearing outer race — decoupled.
//
//   Cross-section (looking along shaft Z-axis):
//
//        ╭─────────────────╮
//       │  CAM DISC (big)   │  ← bearing wraps this OD
//       │                   │
//       │       ┌───┐       │
//       │       │ ○ │ shaft │  ← shaft boss at disc edge
//       │       └───┘       │
//       │                   │
//        ╰─────────────────╯
//
//   Shaft center is OFFSET from disc center by ECCENTRICITY.
//   When shaft rotates, disc orbits → bearing outer race traces eccentric path.
//   Follower on bearing OD produces wave motion.
//
// ASSEMBLY ORDER (per cam station):
//   1. Cam disc = large circle, shaft hole offset from center
//   2. 6810ZZ bearing slides OVER the disc outer surface
//   3. Follower ring clips onto bearing OUTER race (65mm OD)
//   4. Spacer collar sits on shaft between discs
//
// INDEXING: D-flat shaft + pre-angled discs (Option A)
//   Each disc printed with D-bore at different angle from disc center
//   → different phase angle when locked onto shaft D-flat
//   9 unique STLs, numbered for assembly order
//
// NO RIB-SHAFT COLLISION: follower is on OUTSIDE of disc,
//   shaft is at disc edge. Nothing crosses the shaft zone.

// Cam bearing — 61808ZZ (40×50×6) thin-section, wraps disc
CAM_BRG_ID        = 40.0;      // bearing inner bore (disc fits inside)
CAM_BRG_OD        = 50.0;      // bearing outer diameter
CAM_BRG_W         = 6.0;       // bearing width

// Cam disc — the eccentric body
// Disc OD = press-fit into bearing inner bore
DISC_OD           = CAM_BRG_ID - 0.1;                 // 39.9mm
DISC_WALL         = 3.0;       // minimum wall thickness in disc body

// Shaft boss — at disc edge, offset from disc center
SHAFT_BOSS_OD     = SHAFT_DIA + 6;                     // 11mm (3mm wall around shaft)
SET_SCREW_DIA     = 3.0;       // M3 set screw
SET_SCREW_BORE    = 2.5;       // M3 tap drill (2.5mm)
SET_SCREW_DEPTH   = 5.0;       // tap depth into shaft boss wall

// Eccentricity = distance from shaft center to disc center
// Shaft boss is tangent to disc edge:
//   ECC = disc_radius - boss_radius = 20.0 - 5.5 = 14.5mm
CAM_ECC           = DISC_OD/2 - SHAFT_BOSS_OD/2;       // 14.45mm

// Keeper lip — retains bearing axially on disc
KEEPER_LIP_DIA    = CAM_BRG_ID + 2;                   // 42mm (lip over bearing inner edge)
KEEPER_LIP_H      = 0.8;

// Disc axial geometry
DISC_THICK        = CAM_BRG_W + 1;                     // 7mm (bearing width + clearance)
FLANGE_H          = 1.0;       // base flange below bearing zone
BEARING_ZONE_H    = CAM_BRG_W + 0.5;                  // 6.5mm
AXIAL_PITCH       = 14.0;      // cam-to-cam spacing (DECOUPLED from matrix STACK_OFFSET=12)
                                // Kept at 14mm for thick discs + generous collar
COLLAR_THICK      = AXIAL_PITCH - DISC_THICK;          // 7.0mm spacer between discs
HELIX_LENGTH      = NUM_CAMS * AXIAL_PITCH;            // 154mm (11 × 14)

// Shaft extension — from last disc to frame bearing carrier plate
// Carrier plates sit at shaft crossing on frame arms.
// With _STAR_RATIO=2.5, crossings are very far out → long shaft needed.
// Extension set generously; frame verifies actual clearance.
SHAFT_EXT_TO_CARRIER = 120.0; // mm from last disc face to carrier plate center
SHAFT_EXT_BEYOND     = 15.0;  // mm beyond carrier for retainer/pulley
SHAFT_TOTAL_LENGTH   = HELIX_LENGTH + 2 * (SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND);  // 424mm

// Shaft retainer — E-clip groove on shaft beyond each carrier plate
// Prevents axial sliding. E-clip sits in groove on steel rod.
ECLIP_GROOVE_DIA     = SHAFT_DIA - 0.8;  // 4.2mm (0.4mm deep groove each side)
ECLIP_GROOVE_W       = 1.2;              // groove width for E-5 clip
ECLIP_OD             = 11.0;             // E-clip outer diameter (visual only)

// Follower ring — rides on bearing OUTER race, cable eyelet
// No arm needed — cable attaches directly to follower ring eyelet
// The entire ring orbits with the eccentric but doesn't rotate
FOLLOWER_RING_ID  = CAM_BRG_OD + 0.3;                 // 65.3mm (clearance on 65mm OD)
FOLLOWER_RING_OD  = CAM_BRG_OD + 8;                   // 73mm
FOLLOWER_RING_H   = 5.0;                              // ring height
FOLLOWER_EYELET_DIA = 2.0;                            // cable hole
FOLLOWER_ARM_LENGTH = 12.0;                            // short arm for cable attachment
FOLLOWER_ARM_W    = 5.0;                               // arm width

// =============================================
// DAMPENER BAR — one piece per helix, parallel to cam shaft
// =============================================
DAMPENER_BAR_OD     = 10.0;
DAMPENER_BAR_BORE   = 2.0;
DAMPENER_BAR_LENGTH = HELIX_LENGTH + 20;
DAMPENER_BAR_HOLE_PITCH = STACK_OFFSET;  // matches matrix channel spacing
DAMPENER_TAB_W      = 12.0;
DAMPENER_TAB_H      = 4.0;
DAMPENER_TAB_BOLT   = 3.2;

// =============================================
// FRAME POSTS
// =============================================
POST_DIA       = 4.5;         // M4 clearance (4mm rod + 0.5mm gap)
POST_NOTCH_R   = HEX_R;       // notch center at hex vertex radius

// =============================================
// LEGS — 3 at stub vertices, screw-on
// =============================================
LEG_DIA        = 12.0;        // leg tube OD
LEG_LENGTH     = 200.0;       // leg height
LEG_THREAD     = 8.0;         // M8 heat-set insert bore

// =============================================
// STRING / CABLE
// =============================================
STRING_DIA        = 0.5;       // 0.5mm braided Dyneema
GUIDE_BUSHING_BORE = 2.0;
GUIDE_FUNNEL_DIA  = 5.0;
STRING_HOLE_DIA   = 2.0;
RETAINER_DIA      = 5.0;
RETAINER_DEPTH    = 1.5;

// =============================================
// BEARING MOUNTS — journal geometry (frame arm geometry)
// =============================================
// These are used by hex_frame_v5.scad for positioning frame bearings (625ZZ)
JOURNAL_LENGTH    = 10.0;     // stub extension from helix center along shaft
JOURNAL_EXT       = 150.0;    // extension beyond discs to carrier plates
// JOURNAL_TOTAL_REACH = HELIX_LENGTH/2 + JOURNAL_LENGTH + JOURNAL_EXT (derived at compile)

// =============================================
// HEXAGRAM FRAME — key geometry constants
// =============================================
// These are used by hex_frame_v5.scad but defined here
// so other files can reference helix positions.
_STAR_RATIO       = 2.5;      // dramatic extension (was 1.5) — helixes far from matrix
_BLOCK_DROP       = 75;
_BLOCK_HEIGHT_CFG = 15;
_CORRIDOR_GAP_CFG = 65.0;    // widened corridor for 11-cam helix (follower OD=58mm + clearance)

// GT2 drive (belt between helices)
GT2_TEETH       = 20;
GT2_PD          = GT2_TEETH * 2 / PI;                 // 12.73mm
GT2_OD          = GT2_PD + 1.5;                        // ~14.2mm
GT2_BOSS_H      = 8;
GT2_BELT_W      = 6;

// =============================================
// MANUFACTURING — V5.2 monolithic matrix
// =============================================
// The entire 3-tier matrix is ONE 3D-printed piece (print-in-place).
// All sliders, pulleys, and channels functional as printed.
// Side-walls only (no top/bottom walls on channels) — enables
// vertical string routing through the monolithic piece.
// Anchor plate sits on top, 2 guide plates below.
// Hex frame rings compress the sandwich.
// Alignment pins register rotation before clamping.

// =============================================
// COLORS
// =============================================
C_ACRYLIC   = [0.85, 0.92, 0.95, 0.3];
C_NYLON     = [0.95, 0.95, 0.92, 1.0];
C_STEEL     = [0.7,  0.7,  0.75, 1.0];
C_STRING    = [0.1,  0.1,  0.1,  1.0];
C_BLOCK     = [0.82, 0.71, 0.55, 1.0];
C_SLIDER    = [0.9,  0.4,  0.4,  1.0];
C_WALL      = [0.6,  0.6,  1.0,  0.8];
C_DISC      = [0.3,  0.6,  0.9,  0.9];
C_RIB       = [0.8,  0.5,  0.2,  0.9];
C_BEARING   = [0.5,  0.5,  0.55, 0.7];
C_ENDPLT    = [0.5,  0.5,  0.55, 0.9];
C_BOLT      = [0.3,  0.3,  0.3,  1.0];
C_HEX_GHOST = [0.3,  0.8,  0.3,  0.1];

// =============================================
// VERIFICATION (silent — only warns on problems)
// =============================================
// Shaft boss must enclose shaft bore with adequate wall
_boss_wall = (SHAFT_BOSS_OD - SHAFT_BORE) / 2;
if (_boss_wall < 2.0)
    echo(str("CONFIG !! Shaft boss wall too thin: ", round(_boss_wall*10)/10, "mm"));

// Shaft boss must fit inside disc (tangent or inside edge)
_boss_margin = DISC_OD/2 - CAM_ECC - SHAFT_BOSS_OD/2;
if (_boss_margin < -0.5)
    echo(str("CONFIG !! Shaft boss protrudes from disc by ", round(-_boss_margin*10)/10, "mm"));

// Disc must fit inside bearing bore
if (DISC_OD >= CAM_BRG_ID)
    echo(str("CONFIG !! Disc OD=", DISC_OD, " >= bearing bore=", CAM_BRG_ID, "!"));

// Follower ring must clear bearing OD
if (FOLLOWER_RING_ID <= CAM_BRG_OD)
    echo(str("CONFIG !! Follower ring ID=", FOLLOWER_RING_ID, " <= bearing OD=", CAM_BRG_OD, "!"));

// Collar must be positive (disc doesn't exceed axial pitch)
if (COLLAR_THICK < 1.0)
    echo(str("CONFIG !! Collar too thin: ", round(COLLAR_THICK*10)/10, "mm"));

// CAM_ECC vs ECCENTRICITY warning
if (abs(CAM_ECC - ECCENTRICITY) > 1.0)
    echo(str("CONFIG !! CAM_ECC=", round(CAM_ECC*10)/10, " differs from ECCENTRICITY=", ECCENTRICITY, " by >1mm"));

// Stagger doesn't kill columns on shortest channels
_shortest_ch = min([for (i=[0:NUM_CHANNELS-1]) CH_LENS[i]]);
if (_shortest_ch > 0) {
    _shortest_half_w = hex_w(CH_OFFSETS[0]) / 2;
    if (STAGGER_HALF_PITCH + max(FP_OD, SP_OD)/2 + 1 > _shortest_half_w)
        echo(str("CONFIG !! Stagger may clip columns on shortest channel"));
}

echo(str("=== CONFIG V5.2 (TRUE 75% + MONOLITHIC MATRIX) ==="));
echo(str("HEX_R=", HEX_R, " | Channels=", NUM_CHANNELS, " | Cams=", NUM_CAMS));
echo(str("STACK_OFFSET=", STACK_OFFSET, "mm (matrix) | AXIAL_PITCH=", AXIAL_PITCH, "mm (cams) — DECOUPLED"));
echo(str("ECCENTRICITY=", ECCENTRICITY, " CAM_ECC=", round(CAM_ECC*10)/10));
echo(str("HOUSING_HEIGHT=", HOUSING_HEIGHT, " | DISC_THICK=", DISC_THICK));
echo(str("HELIX_LENGTH=", HELIX_LENGTH, "mm | Stagger=", STAGGER_HALF_PITCH, "mm"));
echo(str("Shaft: ", SHAFT_DIA, "mm D-flat=", D_FLAT_DEPTH, "mm | Total=", SHAFT_TOTAL_LENGTH, "mm"));
echo(str("Frame bearing: 625ZZ (", FRAME_BRG_ID, "/", FRAME_BRG_OD, "/", FRAME_BRG_W, ")"));
echo(str("Cam bearing: 61808ZZ (", CAM_BRG_ID, "/", CAM_BRG_OD, "/", CAM_BRG_W, ")"));
echo(str("Disc OD=", DISC_OD, "mm Boss=", SHAFT_BOSS_OD, "mm Follower=", FOLLOWER_RING_OD, "mm"));
echo(str("Twist/cam=", round(TWIST_PER_CAM*100)/100, "deg | Collar=", COLLAR_THICK, "mm"));
