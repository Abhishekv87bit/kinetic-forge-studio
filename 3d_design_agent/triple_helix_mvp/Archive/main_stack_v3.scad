// =========================================================
// MAIN STACK V3 — Matrix Assembly (Frame-Clamped)
// =========================================================
// Anchor plate + 3 hex tiers (full detail) + 2 guide plates.
//
// No bolt flanges — frame posts pass through edge notches at
// hex vertices. Frame compression clamps the entire stack.
//
// Tiers render with full internal detail (pulleys, sliders, walls).
// Anchor and guide plates render as simplified hex shapes to stay
// under OpenSCAD's 100K CSG element limit.
// Open anchor_plate_v3.scad or guide_plate_v3.scad individually
// to see their full detail.
//
// Z-Layout (matrix center = Z=0):
//   +50  Anchor plate top (5mm thick)
//   +45  Anchor plate bottom / Tier 1 top
//   +15  Tier 1 bottom / Tier 2 top
//   -15  Tier 2 bottom / Tier 3 top
//   -45  Tier 3 bottom / Guide Plate 1 top
//   -48  Guide Plate 1 bottom (3mm)
//   -63  Guide Plate 2 top (after 15mm spacer gap)
//   -68  Guide Plate 2 bottom (5mm)
// =========================================================

use <matrix_tier_v3.scad>

$fn = 40;

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// HEX GEOMETRY (must match matrix_tier_v3.scad!)
// =============================================
HEX_R          = 118;
STACK_OFFSET   = 14.0;       // ⚠ sync: matrix_tier, hex_frame, helix_cam
WALL_THICKNESS = 2.5;                          // ⚠ sync: matrix_tier_v3 source of truth
CH_GAP         = STACK_OFFSET - WALL_THICKNESS;  // 14 - 2.5 = 11.5mm
ECCENTRICITY   = 15.0;       // ⚠ sync: matrix_tier, hex_frame, helix_cam
FP_ROW_Y       = 10.0;
FP_OD          = 8.0;
SP_OD          = 8.0;
COL_PITCH      = 12;
WALL_MARGIN    = 8;
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2;  // 30mm

HEX_C2C = 2 * HEX_R;
HEX_FF  = HEX_R * sqrt(3);

function hex_w(d) =
    let(max_d = HEX_R * sqrt(3) / 2)
    (abs(d) > max_d) ? 0 : 2 * (HEX_R - abs(d) / sqrt(3));
function ch_len(d) = max(0, hex_w(d) - 2 * WALL_MARGIN);
function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;

// =============================================
// TIER STACKING
// =============================================
NUM_TIERS     = 3;
TIER_ANGLES   = [0, 120, 240];
TIER_PITCH    = HOUSING_HEIGHT;  // 30mm (zero gap)

// =============================================
// HELIX PHASING
// =============================================
NUM_CAMS      = NUM_CHANNELS;
TWIST_PER_CAM = 360.0 / NUM_CAMS;

// =============================================
// PLATE DIMENSIONS
// =============================================
ANCHOR_THICK      = 5.0;
GP1_THICK         = 3.0;
GP2_THICK         = 5.0;
GUIDE_PLATE_GAP   = 15.0;

// =============================================
// Z-LAYOUT
// =============================================
TIER1_TOP = TIER_PITCH + HOUSING_HEIGHT / 2;       // +45
TIER3_BOT = -TIER_PITCH - HOUSING_HEIGHT / 2;      // -45

ANCHOR_Z  = TIER1_TOP;                              // +45
GP1_Z     = TIER3_BOT;                              // -45
GP2_Z     = GP1_Z - GP1_THICK - GUIDE_PLATE_GAP;   // -63
GP2_BOT   = GP2_Z - GP2_THICK;                      // -68

TOTAL_STACK_H = ANCHOR_Z + ANCHOR_THICK - GP2_BOT;

// =============================================
// COLORS
// =============================================
C_ANCHOR  = [0.6, 0.6, 0.7, 0.8];
C_GUIDE   = [0.6, 0.85, 0.6, 0.8];

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_ANCHOR         = true;
SHOW_TIER_1         = true;
SHOW_TIER_2         = true;
SHOW_TIER_3         = true;
SHOW_GUIDE_PLATES   = true;

/* [Debug] */
EXPLODE             = 0;      // [0:5:150] exploded view spacing

// =============================================
// STANDALONE RENDER
// =============================================
main_stack_v3(anim_t());


// =========================================================
// MAIN STACK V3 ASSEMBLY
// =========================================================
module main_stack_v3(t = 0) {

    explode_anchor = EXPLODE * 2;
    explode_gp     = EXPLODE;

    // ---- ANCHOR PLATE (simplified hex shape) ----
    if (SHOW_ANCHOR) {
        color(C_ANCHOR)
        translate([0, 0, ANCHOR_Z + explode_anchor])
            cylinder(r = HEX_R, h = ANCHOR_THICK, $fn = 6);
    }

    // ---- MATRIX TIERS (3 at 0/120/240° — FULL DETAIL) ----
    for (tier_idx = [0 : 2]) {
        tier_angle = TIER_ANGLES[tier_idx];
        tier_z = (1 - tier_idx) * TIER_PITCH;
        explode_z = (1 - tier_idx) * EXPLODE * 0.5;

        show = (tier_idx == 0 && SHOW_TIER_1) ||
               (tier_idx == 1 && SHOW_TIER_2) ||
               (tier_idx == 2 && SHOW_TIER_3);

        if (show) {
            ch_disps = [for (ch = [0 : NUM_CHANNELS - 1])
                let(phase = ch * TWIST_PER_CAM)
                ECCENTRICITY * sin(t * 360 + phase)
            ];

            translate([0, 0, tier_z + explode_z])
                rotate([0, 0, tier_angle])
                    rotate([90, 0, 0])
                        matrix_tier_v3(ch_disps);
        }
    }

    // ---- GUIDE PLATES (simplified hex shapes) ----
    if (SHOW_GUIDE_PLATES) {
        color(C_GUIDE) {
            // GP1
            translate([0, 0, GP1_Z - explode_gp])
                cylinder(r = HEX_R, h = GP1_THICK, $fn = 6);
            // GP2
            translate([0, 0, GP2_Z - explode_gp])
                cylinder(r = HEX_R, h = GP2_THICK, $fn = 6);
        }
    }

    // ---- ECHOES ----
    echo(str("=== MAIN STACK V3 ==="));
    echo(str("HEX_R=", HEX_R, "mm | C2C=", HEX_C2C, "mm"));
    echo(str("Channels/tier=", NUM_CHANNELS, " | Tiers=", NUM_TIERS));
    echo(str("Stack height=", TOTAL_STACK_H, "mm (anchor top → GP2 bottom)"));
    echo(str("Twist/cam=", round(TWIST_PER_CAM*100)/100, "deg"));
    echo(str("Z layout: Anchor=", ANCHOR_Z, "(+", ANCHOR_THICK, ") T1=+", TIER_PITCH,
             " T2=0 T3=-", TIER_PITCH, " GP1=", GP1_Z, " GP2=", GP2_Z, "(-", GP2_THICK, ")"));
}
