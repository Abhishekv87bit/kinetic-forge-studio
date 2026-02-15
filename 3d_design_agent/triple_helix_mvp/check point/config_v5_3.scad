// =========================================================
// CONFIG V5.3 — Single Source of Truth for Triple Helix MVP
// =========================================================
// V5.3 PROTOTYPE: 8mm shaft, integrated disc+collar, face-pin registration,
//   solid channel walls, slider pulley bias, organic carrier bridge.
//
// INCLUDE this file (not `use`) in every V5.3 module.
// All shared parameters live here. No file duplicates any value.
//
// KEY CHANGES from V5.2:
//   R1: SHAFT_DIA 5→8mm, frame bearing 625ZZ→688ZZ, boss 11→14mm
//   R2: Integrated disc+collar with 3D-printed face pins (no separate collars)
//   R3: E-clip-only shaft retention (no printed boss)
//   R4: Dampener bars get V-grooves (comb separator)
//   R5: Channel wall windows removed (solid walls)
//   R6: Slider pulleys biased toward helix side
//   R7: Block gap reduced to 0.8mm
//   R8: Arm linkages match main arm proportions (20x14mm)
//   R9: Carrier plates = structural arm node (cohesive with arms)
//   R10: Full matrix geometry audit
//
// DECOUPLED SPACING (the "middle way"):
//   Matrix channels spaced at STACK_OFFSET = 12mm (tight matrix, 11 ch)
//   Cam discs spaced at AXIAL_PITCH = 14mm (thick discs, spread out)
//   Each cam drives one channel via cable — physical spacing needn't match.
//
// Architecture:
//   HEX_R → derives channels, column positions, hex geometry
//   STACK_OFFSET → derives channel spacing (matrix only)
//   AXIAL_PITCH → derives cam pitch, disc thickness, helix length (cam only)
//   ECCENTRICITY → derives stroke, slider bias, travel limits
//   SHAFT_DIA → derives D-bore, boss, frame bearings, collar geometry
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
FP_OD         = 5.0;       // fixed pulley OD (slim prototype — min for 0.5mm Dyneema)
SP_OD         = 5.0;       // slider pulley OD (matches FP)
_MIN_ROPE_GAP = 2.0;       // gap between FP and SP rows for rope passage (min 2mm)

FP_ROW_Y      = (FP_OD + SP_OD) / 2 + _MIN_ROPE_GAP;  // derived: 7mm for 5mm pulleys

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
// ECCENTRICITY unified with disc geometry (V5.3):
//   = DISC_OD/2 - SHAFT_BOSS_OD/2 = (CAM_BRG_ID-0.1)/2 - (SHAFT_DIA+6)/2
//   = 19.95 - 7.0 = 12.95mm  (with 8mm shaft)
// Must match CAM_ECC exactly. Config self-check verifies this at bottom.
ECCENTRICITY  = 12.95;        // mm — matches CAM_ECC (disc geometry eccentricity)
CAM_STROKE    = 2 * ECCENTRICITY;  // 25.9mm peak-to-peak

/* [Slider Bias] */
SLIDER_BIAS        = 0.80;     // rest position bias toward helix
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS;  // 10.36mm toward helix side

// =============================================
// HOUSING / TIER
// =============================================
WALL_THICKNESS = 2.5;
CH_GAP         = STACK_OFFSET - WALL_THICKNESS;     // 9.5mm
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2;         // 21mm (derived: 2*7+5+2)

// =============================================
// TIER STACKING
// =============================================
NUM_TIERS     = 3;
TIER_ANGLES   = [0, 120, 240];
INTER_TIER_GAP = 0.0;                                // zero-gap: monolithic print-in-place matrix
TIER_PITCH    = HOUSING_HEIGHT + INTER_TIER_GAP;     // 21mm (housing + gap, zero-gap)

// Z-layout: matrix centered at Z=0
TIER1_TOP     = TIER_PITCH + HOUSING_HEIGHT / 2;     // +31.5
TIER3_BOT     = -TIER_PITCH - HOUSING_HEIGHT / 2;    // -31.5

// =============================================
// ANCHOR & GUIDE PLATES
// =============================================
ANCHOR_THICK      = 5.0;
GP1_THICK         = 3.0;
GP2_THICK         = 5.0;
GUIDE_PLATE_GAP   = 15.0;

ANCHOR_Z  = TIER1_TOP;                               // +31.5
GP1_Z     = TIER3_BOT;                               // -31.5
GP2_Z     = GP1_Z - GP1_THICK - GUIDE_PLATE_GAP;     // -49.5
GP2_BOT   = GP2_Z - GP2_THICK;                        // -54.5

// =============================================
// ALIGNMENT PINS — hex registration for anchor/guide plates
// =============================================
ALIGN_PIN_DIA     = 3.0;       // pin diameter
ALIGN_PIN_HOLE    = 3.2;       // hole in plate (clearance fit)
ALIGN_PIN_DEPTH   = 5.0;       // insertion depth per side
ALIGN_PIN_COUNT   = 3;         // 3 pins at 60° intervals on hex perimeter
ALIGN_PIN_R       = HEX_R - 5; // pin circle radius (5mm inboard of hex edge)

// =============================================
// CENTRAL SHAFT — 8mm stainless steel rod (V5.3, upgraded from 5mm)
// =============================================
// One continuous rod per helix, D-flat for indexing.
// 8mm gives adequate stiffness for 424mm span with 11 loaded cams.
SHAFT_DIA         = 8.0;       // rod diameter (R1: upgraded from 5mm)
D_FLAT_DEPTH      = 0.7;       // D-flat cut depth (scaled for 8mm shaft)
SHAFT_BORE        = SHAFT_DIA + 0.2;  // bore in disc for sliding fit = 8.2mm
D_BORE_FLAT       = SHAFT_DIA - 2 * D_FLAT_DEPTH;  // chord width of D-flat = 6.6mm

// =============================================
// FRAME BEARINGS — 688ZZ (8x16x5mm) — upgraded for 8mm shaft
// =============================================
// 6 total: 2 per helix, press-fit into carrier plates at arm bridges.
// Same OD and width as 625ZZ — carrier bore unchanged.
FRAME_BRG_ID  = 8.0;          // matches SHAFT_DIA (R1)
FRAME_BRG_OD  = 16.0;         // same as 625ZZ
FRAME_BRG_W   = 5.0;          // same as 625ZZ

// =============================================
// HELIX CAM — Central Shaft Disc Parameters (V5.3)
// =============================================
NUM_CAMS       = NUM_CHANNELS;                        // 11 discs (1 cam per channel)
TWIST_PER_CAM  = 360.0 / NUM_CAMS;                   // 32.73°
HELIX_ANGLES   = [180, 300, 60];                      // where 3 helices sit

// DISC-AROUND-SHAFT ECCENTRIC CAM (V5.3)
//
// DESIGN: Large circular disc with shaft boss at disc edge.
//   The disc IS the eccentric — its center is offset from the shaft.
//   A 61808ZZ bearing wraps the entire disc outer circumference.
//   A follower ring rides on the bearing outer race — decoupled.
//
//   Cross-section (looking along shaft Z-axis):
//
//        ╭─────────────────╮
//       │  CAM DISC (big)   │  ← bearing wraps this OD
//       │                   │
//       │       ┌───┐       │
//       │       │ ○ │ shaft │  ← 8mm shaft boss at disc edge
//       │       └───┘       │
//       │                   │
//        ╰─────────────────╯
//
// V5.3 INTEGRATED DISC+COLLAR (R2):
//   Each cam = ONE printed piece: disc body + integrated collar stub.
//   Collar has 2 printed face pins for phase-lock registration.
//   No separate spacer collars, no soft stops, no set screws.
//
// ASSEMBLY ORDER (per cam station):
//   1. Slide integrated disc+collar onto D-flat shaft (D-bore indexes phase)
//   2. Previous collar pins engage this disc's receiving holes
//   3. Slide 61808ZZ bearing over disc OD from non-collar side
//   4. Clip follower ring onto bearing outer race
//   5. Thread cable through follower eyelet
//   6. Repeat for all 11 discs
//
// INDEXING: D-flat shaft + pre-angled discs + face pins
//   D-bore sets phase angle. Face pins lock rotation under load.
//   11 unique STLs, numbered for assembly order.
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
SHAFT_BOSS_OD     = SHAFT_DIA + 6;                     // 14mm (3mm wall around 8mm shaft)

// Set screw (V5.3: only used for GT2 pulley, NOT on cam discs — face pins replace set screws)
SET_SCREW_DIA     = 3.0;       // M3 set screw
SET_SCREW_BORE    = 2.5;       // M3 tap drill (2.5mm)
SET_SCREW_DEPTH   = 5.0;       // tap depth into boss wall

// Eccentricity = distance from shaft center to disc center
// Shaft boss is tangent to disc edge:
//   ECC = disc_radius - boss_radius = 19.95 - 7.0 = 12.95mm
CAM_ECC           = DISC_OD/2 - SHAFT_BOSS_OD/2;       // 12.95mm

// Keeper lip — retains bearing axially on disc
KEEPER_LIP_DIA    = CAM_BRG_ID + 2;                   // 42mm (lip over bearing inner edge)
KEEPER_LIP_H      = 0.8;
// NOTE: Keeper lip extends 0.5mm past DISC_THICK into collar zone
// (FLANGE_H + BEARING_ZONE_H = 7.5 > 7.0mm). This is intentional:
// lip merges with collar union, giving one-sided axial retention.
// Bearing is also press-fit (0.1mm interference) + gravity-seated.

// =============================================
// FACE-PIN REGISTRATION (V5.3 R2) — replaces soft stops + set screws
// =============================================
// 2 printed pins on each collar face, diametrically opposed.
// Engage matching holes on adjacent disc face.
// D-bore provides phase indexing; pins provide rotation locking.
FACE_PIN_DIA       = 2.5;      // printed pin diameter
FACE_PIN_HOLE_DIA  = 2.75;     // receiving hole (0.25mm clearance)
FACE_PIN_H         = 3.0;      // pin protrusion height
FACE_PIN_HOLE_DEPTH = 3.5;     // receiving hole depth (0.5mm bottom clearance)
FACE_PIN_R         = 5.0;      // pin radial position on collar face (0.75mm wall to collar edge)
FACE_PIN_COUNT     = 2;        // diametrically opposed

// Disc axial geometry (V5.3: integrated collar is part of disc)
AXIAL_PITCH       = 14.0;      // cam-to-cam spacing (DECOUPLED from matrix STACK_OFFSET=12)
DISC_THICK        = CAM_BRG_W + 1;                     // 7mm (bearing width + clearance)
FLANGE_H          = 1.0;       // base flange below bearing zone
BEARING_ZONE_H    = CAM_BRG_W + 0.5;                  // 6.5mm
COLLAR_THICK      = AXIAL_PITCH - DISC_THICK;          // 7.0mm integrated collar stub
HELIX_LENGTH      = NUM_CAMS * AXIAL_PITCH;            // 154mm (11 × 14)

// Shaft extension — from last disc to frame bearing carrier plate
SHAFT_EXT_TO_CARRIER = 120.0; // mm from last disc face to carrier plate center
// SHAFT_EXT_BEYOND defined below (after GT2 params, depends on GT2_BOSS_H)

// Shaft retainer — E-clip groove on shaft beyond each carrier plate (R3)
// DIN 6799 E-8 for 8mm shaft
ECLIP_GROOVE_DIA     = SHAFT_DIA - 0.9;  // 7.1mm (per DIN 6799 E-8)
ECLIP_GROOVE_W       = 0.9;              // groove width for E-8 clip
ECLIP_OD             = 15.0;             // E-clip outer diameter (visual only)

// Shaft axial retention — E-clips only (simplest, no printed boss)
// Two E-clips per shaft: one on the INSIDE edge of each carrier node.
// "Inside edge" = corridor side, facing disc stack.
// E-clip catches against the 688ZZ bearing inner race shoulder.
//
// Layout (per carrier, outside→inside):
//   GT2 pulley | arm outside face | [carrier node + 688ZZ] | E-clip | corridor → disc stack
//
// ECLIP_INBOARD_OFFSET = distance from carrier plate center to E-clip groove
// = half carrier plate thickness + 1mm clearance (right at inside face)
CARRIER_PLATE_T_CFG  = 20;                    // carrier plate thickness (also in hex_frame)
ECLIP_INBOARD_OFFSET = CARRIER_PLATE_T_CFG / 2 + 1;  // 11mm from carrier center (inside edge)

// GT2 pulley sits flush on OUTSIDE edge of carrier (pushed toward camshaft center)
// SHAFT_EXT_BEYOND = just enough for GT2 boss + 1mm clearance
_GT2_BOSS_H_REF      = 8;               // must match GT2_BOSS_H (avoids forward reference)
SHAFT_EXT_BEYOND     = _GT2_BOSS_H_REF + 1;  // 9mm (was 15mm — pulley flush with arm outside face)
SHAFT_TOTAL_LENGTH   = HELIX_LENGTH + 2 * (SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND);  // 412mm

// Follower ring — rides on bearing OUTER race, cable eyelet
// No arm needed — cable attaches directly to follower ring eyelet
// The entire ring orbits with the eccentric but doesn't rotate
// (cable tension keeps it oriented toward matrix — no soft stops needed)
FOLLOWER_RING_ID  = CAM_BRG_OD + 0.3;                 // 50.3mm (clearance on 50mm OD)
FOLLOWER_RING_OD  = CAM_BRG_OD + 8;                   // 58mm
FOLLOWER_RING_H   = 5.0;                              // ring height
FOLLOWER_EYELET_DIA = 2.0;                            // cable hole
FOLLOWER_ARM_LENGTH = 12.0;                            // short arm for cable attachment
FOLLOWER_ARM_W    = 5.0;                               // arm width

// =============================================
// DAMPENER BAR — one piece per helix, parallel to cam shaft (R4: grooved)
// =============================================
DAMPENER_BAR_OD     = 10.0;
DAMPENER_BAR_BORE   = 2.0;
DAMPENER_BAR_LENGTH = HELIX_LENGTH + 20;
DAMPENER_BAR_HOLE_PITCH = STACK_OFFSET;  // matches matrix channel spacing
DAMPENER_TAB_W      = 12.0;
DAMPENER_TAB_H      = 4.0;
DAMPENER_TAB_BOLT   = 3.2;
// V-groove comb separator (R4)
DAMPENER_GROOVE_DEPTH = 1.0;   // 1mm deep V-groove
DAMPENER_GROOVE_ANGLE = 60;    // 60° V-groove opening angle
DAMPENER_GROOVE_COUNT = NUM_CHANNELS;  // 11 grooves per bar

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
JOURNAL_LENGTH    = 10.0;     // stub extension from helix center along shaft
JOURNAL_EXT       = 150.0;    // extension beyond discs to carrier plates

// =============================================
// HEXAGRAM FRAME — key geometry constants
// =============================================
_STAR_RATIO       = 2.5;      // dramatic extension — helixes far from matrix
_BLOCK_DROP       = 75;
_BLOCK_HEIGHT_CFG = 15;
_BLOCK_GAP        = 0.8;      // R7: minimum gap between blocks (FDM clearance)
_CORRIDOR_GAP_CFG = 65.0;    // widened corridor for 11-cam helix (follower OD=58mm + clearance)

// GT2 drive (belt between helices)
GT2_TEETH       = 20;
GT2_PD          = GT2_TEETH * 2 / PI;                 // 12.73mm
GT2_OD          = GT2_PD + 1.5;                        // ~14.2mm
GT2_BOSS_H      = 8;
GT2_BELT_W      = 6;

// =============================================
// MANUFACTURING — V5.3 monolithic matrix
// =============================================
// The entire 3-tier matrix is ONE 3D-printed piece (print-in-place).
// All sliders, pulleys, and channels functional as printed.
// Side-walls only (no top/bottom walls on channels) — enables
// vertical string routing through the monolithic piece.
// Solid walls (R5: no window cutouts) for structural integrity.
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
C_PIN       = [0.9,  0.85, 0.3,  1.0];  // face pin color (gold)

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

// CAM_ECC vs ECCENTRICITY check (should be identical — unified)
if (abs(CAM_ECC - ECCENTRICITY) > 0.01)
    echo(str("CONFIG !! CAM_ECC=", round(CAM_ECC*10)/10, " differs from ECCENTRICITY=", round(ECCENTRICITY*10)/10, " — should be identical"));

// Face pin must fit on collar face (pin R + pin D/2 < collar OD/2)
if (FACE_PIN_R + FACE_PIN_DIA/2 > SHAFT_BOSS_OD/2)
    echo(str("CONFIG !! Face pin at R=", FACE_PIN_R, " exceeds collar radius=", SHAFT_BOSS_OD/2));

// Stagger doesn't kill columns on shortest channels
_shortest_ch = min([for (i=[0:NUM_CHANNELS-1]) CH_LENS[i]]);
if (_shortest_ch > 0) {
    _shortest_half_w = hex_w(CH_OFFSETS[0]) / 2;
    if (STAGGER_HALF_PITCH + max(FP_OD, SP_OD)/2 + 1 > _shortest_half_w)
        echo(str("CONFIG !! Stagger may clip columns on shortest channel"));
}

echo(str("=== CONFIG V5.3 (8mm SHAFT + FACE-PIN + SOLID WALLS) ==="));
echo(str("HEX_R=", HEX_R, " | Channels=", NUM_CHANNELS, " | Cams=", NUM_CAMS));
echo(str("STACK_OFFSET=", STACK_OFFSET, "mm (matrix) | AXIAL_PITCH=", AXIAL_PITCH, "mm (cams) — DECOUPLED"));
echo(str("ECCENTRICITY=", ECCENTRICITY, " CAM_ECC=", round(CAM_ECC*10)/10));
echo(str("HOUSING_HEIGHT=", HOUSING_HEIGHT, " | DISC_THICK=", DISC_THICK));
echo(str("HELIX_LENGTH=", HELIX_LENGTH, "mm | Stagger=", STAGGER_HALF_PITCH, "mm"));
echo(str("Shaft: ", SHAFT_DIA, "mm D-flat=", D_FLAT_DEPTH, "mm | Total=", SHAFT_TOTAL_LENGTH, "mm"));
echo(str("Frame bearing: 688ZZ (", FRAME_BRG_ID, "/", FRAME_BRG_OD, "/", FRAME_BRG_W, ")"));
echo(str("Cam bearing: 61808ZZ (", CAM_BRG_ID, "/", CAM_BRG_OD, "/", CAM_BRG_W, ")"));
echo(str("Disc OD=", DISC_OD, "mm Boss=", SHAFT_BOSS_OD, "mm Follower=", FOLLOWER_RING_OD, "mm"));
echo(str("Twist/cam=", round(TWIST_PER_CAM*100)/100, "deg | Collar=", COLLAR_THICK, "mm (integrated)"));
echo(str("Face pins: ", FACE_PIN_COUNT, "x ", FACE_PIN_DIA, "mm at R=", FACE_PIN_R, "mm"));
echo(str("E-clip: DIN 6799 E-8 groove=", ECLIP_GROOVE_DIA, "mm w=", ECLIP_GROOVE_W, "mm"));
echo(str("Block gap=", _BLOCK_GAP, "mm | Max block travel=+/-", round(3*ECCENTRICITY*10)/10, "mm"));
