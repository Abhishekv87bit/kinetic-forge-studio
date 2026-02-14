// =========================================================
// CONFIG V4 — Single Source of Truth for Triple Helix MVP
// =========================================================
// INCLUDE this file (not `use`) in every V4 module.
// All shared parameters live here. No file duplicates any value.
//
// Architecture:
//   HEX_R → derives channels, column positions, hex geometry
//   STACK_OFFSET → derives channel spacing, cam pitch, disc thickness
//   ECCENTRICITY → derives stroke, slider bias, travel limits
//   BEARING → derives mount sizes, rib geometry, disc seats
//   SCALE_MODE → switches between prototype and final dimensions
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
// SCALE MODE
// =============================================
// false = PROTOTYPE: compact desk-scale, short block drop
// true  = FINAL: ~4ft tall × ~2ft wide, long wave curtain
/* [Scale] */
FINAL_SCALE       = false;

_STAR_RATIO       = FINAL_SCALE ? 1.25 : 1.5;
_BLOCK_DROP       = FINAL_SCALE ? 800  : 100;
_BLOCK_HEIGHT_CFG = FINAL_SCALE ? 55   : 20;
_CORRIDOR_GAP_CFG = FINAL_SCALE ? 60   : 78;

// =============================================
// HEX GEOMETRY — the ONE sizing parameter
// =============================================
/* [Hex Tier] */
HEX_R         = 118;      // [40:1:200] circumradius — everything derives from this

HEX_C2C       = 2 * HEX_R;                     // corner-to-corner = 236mm
HEX_FF        = HEX_R * sqrt(3);               // flat-to-flat = 204.0mm
HEX_LONGEST_DIA = HEX_C2C;                     // alias

/* [Column Spacing] */
COL_PITCH     = 12;        // [8:1:30] column-to-column X pitch
WALL_MARGIN   = 8;         // [4:1:15] clearance from hex edge to first column

/* [Channel Stacking] */
STACK_OFFSET  = 14.0;      // channel center-to-center along stacking axis

// Channel count (derived from hex geometry)
function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;  // 13 at HEX_R=118

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

FP_ROW_Y      = (FP_OD + SP_OD) / 2 + _MIN_ROPE_GAP;  // 10mm (derived)

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
ECCENTRICITY  = 20.0;      // mm cam throw (slider travel ±20mm) — max drama per Eq.1/Eq.2 analysis
CAM_STROKE    = 2 * ECCENTRICITY;  // 30mm peak-to-peak

/* [Slider Bias] */
SLIDER_BIAS        = 0.866;    // Pareto optimal with ECC=20 (C1+C2 binding)
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS;  // 12mm toward helix side

// =============================================
// HOUSING / TIER (FP_OD, SP_OD, FP_ROW_Y declared above with column culling)
// =============================================
WALL_THICKNESS = 2.5;
CH_GAP         = STACK_OFFSET - WALL_THICKNESS;     // 11.5mm
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2;         // 30mm (derived)

// =============================================
// TIER STACKING
// =============================================
NUM_TIERS     = 3;
TIER_ANGLES   = [0, 120, 240];
TIER_PITCH    = HOUSING_HEIGHT;                      // 30mm (zero-gap stacking)

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
// BEARING — 6800ZZ (universal)
// =============================================
BEARING_ID    = 10.0;
BEARING_OD    = 19.0;
BEARING_W     = 5.0;

// =============================================
// HELIX CAM — Pinless Disc Parameters
// =============================================
NUM_CAMS       = NUM_CHANNELS;                        // 13
TWIST_PER_CAM  = 360.0 / NUM_CAMS;                   // 27.69°
HELIX_ANGLES   = [180, 300, 60];                      // where 3 helices sit

// Disc geometry — TRUE SHAFTLESS
// Each disc is a single eccentric cylinder. No center boss.
// The disc body IS the cam — centered at (ECCENTRICITY, 0) in local frame.
// Rotation axis (0,0) passes through empty space between stacked discs.
// Bolt circle is on the disc body, concentric with bearing seat.
DISC_WALL         = 4.0;                              // wall around bearing
DISC_OD           = BEARING_OD + 2 * DISC_WALL;       // 27mm — main disc body
BEARING_SEAT_DIA  = BEARING_ID - 0.1;                // 9.9mm press-fit
KEEPER_LIP_DIA    = BEARING_ID + 2;                   // 12mm
KEEPER_LIP_H      = 0.8;

BEARING_ZONE_H    = BEARING_W;                        // 5mm
FLANGE_H          = STACK_OFFSET - BEARING_W;         // 9mm
DISC_THICK        = BEARING_ZONE_H + FLANGE_H;        // 14mm = STACK_OFFSET
AXIAL_PITCH       = DISC_THICK;                        // 14mm
HELIX_LENGTH      = NUM_CAMS * AXIAL_PITCH;            // 182mm

// Bolt pattern — on disc body (centered at ECCENTRICITY, not at origin)
NUM_BOLTS         = 3;
BOLT_DIA          = 3.0;       // M3
BOLT_CLEARANCE_D  = 3.4;      // M3 clearance hole
BOLT_HEAD_DIA     = 5.5;      // M3 socket head cap
BOLT_HEAD_H       = 3.0;
BOLT_CIRCLE_R     = (DISC_OD/2 + BEARING_SEAT_DIA/2) / 2;  // between bearing and disc edge
BOLT_ENGAGE       = FLANGE_H - 1.0;                   // 8mm thread engagement

// End disc journals — at rotation axis (0,0), connected by web
JOURNAL_DIA       = BEARING_ID;                        // 10mm
JOURNAL_LENGTH    = 10.0;
JOURNAL_WEB_W     = 8.0;                              // bridge width from disc to journal
JOURNAL_WEB_H     = DISC_THICK;                        // full disc height

/* [Journal Extension — parametric slider for shaft reach] */
JOURNAL_EXT       = 150;   // [0:1:300] mm extension beyond cam stack per side

// =============================================
// CAMSHAFT ASSEMBLY COMPONENTS (industry standard)
// =============================================
// Order along shaft from cam stack outward:
//   shoulder → thrust washer → bearing → snap ring → PB housing → spacer → GT2 pulley → shaft collar

// Shoulder: machined step on end disc journal (locates bearing inboard)
SHOULDER_STEP     = 1.0;                               // step height (radial)
SHOULDER_DIA      = JOURNAL_DIA + 2 * SHOULDER_STEP;   // 12mm — stops bearing from sliding inboard

// Thrust washer: controls axial endplay
THRUST_WASHER_T   = 0.5;                               // thickness (0.3-0.8mm selection range)
THRUST_WASHER_OD  = BEARING_OD - 1.0;                  // 18mm — clears bearing outer race
THRUST_WASHER_ID  = JOURNAL_DIA + 0.5;                 // 10.5mm — clears journal

// Snap ring / E-clip: retains bearing outboard
SNAP_RING_T       = 1.0;                               // axial thickness
SNAP_RING_OD      = JOURNAL_DIA + 3.0;                 // 13mm — visible ring
SNAP_RING_GROOVE_D = JOURNAL_DIA - 1.0;                // 9mm — groove in journal
SNAP_RING_GROOVE_W = 1.2;                              // groove width

// Spacer: between pillow block and GT2 pulley
SPACER_T          = 3.0;                               // spacer length along shaft
SPACER_OD         = SHOULDER_DIA;                      // 12mm — matches shoulder

// Shaft collar: final retention outboard
COLLAR_T          = 5.0;                               // collar width along shaft
COLLAR_OD         = 16.0;                              // collar OD
COLLAR_BORE       = JOURNAL_DIA + 0.1;                 // 10.1mm — slides onto journal
COLLAR_SET_SCREW  = 3.0;                               // M3 set screw

// GT2 pulley (on drive end)
GT2_TEETH       = 20;
GT2_PD          = GT2_TEETH * 2 / PI;                 // 12.73mm
GT2_OD          = GT2_PD + 1.5;                        // ~14.2mm
GT2_BOSS_H      = 8;
GT2_BELT_W      = 6;

// Total journal extension layout (from bearing center outward):
// bearing_half + snap_ring + PB_housing_half ... spacer + GT2 + collar
// All computed in frame file where PB dimensions are known

// Gravity rib
RIB_ARM_LENGTH  = 20.0;
RIB_THICK       = 4.0;
RIB_ARM_WIDTH   = 5.0;
RIB_TAPER_TIP   = 3.0;
RIB_EYELET_DIA  = 1.5;
RIB_RING_OD     = BEARING_OD + 8;                     // 27mm
GUIDE_SLOT_W    = 2.0;
GUIDE_SLOT_H    = 15.0;

// =============================================
// DAMPENER BAR — one piece per helix, parallel to cam shaft
// =============================================
// Continuous bar with NUM_CHANNELS holes for string pass-through.
// Sits between hex matrix and helix cam, parallel to cam axis.
// Attached to frame arms at both ends (same arms as bearing mounts).
DAMPENER_BAR_OD     = 10.0;                            // bar outer diameter
DAMPENER_BAR_BORE   = 2.0;                             // string passage holes
DAMPENER_BAR_LENGTH = HELIX_LENGTH + 20;               // extends 10mm past each end
DAMPENER_BAR_HOLE_PITCH = AXIAL_PITCH;                 // matches cam pitch
DAMPENER_TAB_W      = 12.0;                            // mounting tab width
DAMPENER_TAB_H      = 4.0;                             // mounting tab thickness
DAMPENER_TAB_BOLT   = 3.2;                             // M3 mounting bolt hole

// =============================================
// FRAME POSTS
// =============================================
POST_DIA       = 4.5;         // M4 clearance (4mm rod + 0.5mm gap)
POST_NOTCH_R   = HEX_R;       // notch center at hex vertex radius

// =============================================
// STRING / CABLE
// =============================================
STRING_DIA        = 0.5;       // 0.5mm braided Dyneema
GUIDE_BUSHING_BORE = 2.0;
GUIDE_FUNNEL_DIA  = 5.0;
STRING_HOLE_DIA   = 2.0;      // anchor plate clearance hole
RETAINER_DIA      = 5.0;      // anchor plate knot recess
RETAINER_DEPTH    = 1.5;

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
// Bolt-to-bearing clearance (bolt circle is on disc body at ECCENTRICITY)
_btb = BOLT_CIRCLE_R - BEARING_SEAT_DIA/2 - BOLT_HEAD_DIA/2;
if (_btb < 1.0)
    echo(str("CONFIG !! Bolt-to-bearing clearance: ", round(_btb*10)/10, "mm (need >=1.0)"));

// Bolt-to-disc-edge clearance
_bte = DISC_OD/2 - BOLT_CIRCLE_R - BOLT_HEAD_DIA/2;
if (_bte < 1.0)
    echo(str("CONFIG !! Bolt-to-edge clearance: ", round(_bte*10)/10, "mm (need >=1.0)"));

// Bolt engagement
if (BOLT_ENGAGE < 2 * BOLT_DIA)
    echo(str("CONFIG ⚠ Bolt engagement: ", BOLT_ENGAGE, "mm (need ≥", 2*BOLT_DIA, ")"));

// Stagger doesn't kill columns on shortest channels
_shortest_ch = min([for (i=[0:NUM_CHANNELS-1]) CH_LENS[i]]);
if (_shortest_ch > 0) {
    _shortest_half_w = hex_w(CH_OFFSETS[0]) / 2;  // outermost channel
    if (STAGGER_HALF_PITCH + max(FP_OD, SP_OD)/2 + 1 > _shortest_half_w)
        echo(str("CONFIG ⚠ Stagger may clip columns on shortest channel"));
}

echo(str("=== CONFIG V4 ==="));
echo(str("Scale: ", FINAL_SCALE ? "FINAL (4ft)" : "PROTOTYPE (desk)"));
echo(str("HEX_R=", HEX_R, " | Channels=", NUM_CHANNELS, " | Cams=", NUM_CAMS));
echo(str("STACK_OFFSET=", STACK_OFFSET, " | ECCENTRICITY=", ECCENTRICITY));
echo(str("HOUSING_HEIGHT=", HOUSING_HEIGHT, " | DISC_THICK=", DISC_THICK));
echo(str("HELIX_LENGTH=", HELIX_LENGTH, "mm | Stagger=", STAGGER_HALF_PITCH, "mm"));
