// =========================================================
// MATRIX STACK V3 — 3 Hex Tiers at 0°/120°/240°
// =========================================================
// Three V3 hex tiers stacked vertically with 120° rotation.
// Regular hexagon tiers → hex 60° symmetry → edges align
// when tiers rotate by 120° (2 × 60°).
//
// Vertical layout (display Z-axis):
//   Tier 1 (top):    Z = +TIER_PITCH    rotation = 0°
//   Tier 2 (middle): Z = 0              rotation = 120°
//   Tier 3 (bottom): Z = -TIER_PITCH    rotation = 240°
//
// Transform order per tier (inside-out):
//   1. matrix_tier_v3(disps) — local coords: X=slider, Y=depth, Z=stack
//   2. rotate([90,0,0])      — stand up: Z-stack → display -Y, Y-depth → display Z
//   3. rotate([0,0,angle])   — spin to 0°/120°/240°
//   4. translate([0,0,z])    — stack vertically
//
// No TIER_CENTER_X offset needed — V3 channels are centered at origin.
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
// NOTE: matrix_tier_v3 uses `use` not `include`, so its variables
// are internal to its modules. These duplicated values are ONLY
// used by the stack for positioning/phasing. If you change HEX_R
// or STACK_OFFSET in matrix_tier_v3.scad, update here too.
// =============================================
HEX_R          = 118;
STACK_OFFSET   = 14.0;
CH_GAP         = 12.0;
WALL_THICKNESS = 2.0;
ECCENTRICITY   = 12.0;
FP_ROW_Y       = 10.0;
FP_OD          = 8.0;
HOUSING_HEIGHT = 2 * FP_ROW_Y + FP_OD + 2;  // 30mm

HEX_FF = HEX_R * sqrt(3);
function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;  // 13 at R=118

// =============================================
// TIER STACKING
// =============================================
NUM_TIERS         = 3;
TIER_ANGLES       = [0, 120, 240];
TIER_COLORS       = [[0.6, 0.6, 1.0, 0.7],    // blue
                     [1.0, 0.6, 0.6, 0.7],    // red
                     [0.6, 1.0, 0.6, 0.7]];   // green

INTER_TIER_GAP    = 0;         // zero — direct contact, snap-fit
TIER_DISPLAY_HEIGHT = HOUSING_HEIGHT;  // 30mm per tier (Y→Z after rotation)
TIER_PITCH        = TIER_DISPLAY_HEIGHT + INTER_TIER_GAP;  // 30mm

// Total tier envelope in stacking direction (front-to-back in display)
TIER_ENVELOPE_H = (NUM_CHANNELS - 1) * STACK_OFFSET + CH_GAP + 2 * WALL_THICKNESS;
// = 10×14 + 12 + 4 = 156mm (stacking depth, display Y)

// Total stack height = 3 × 30mm = 90mm
MATRIX_TOTAL_H = NUM_TIERS * TIER_DISPLAY_HEIGHT + (NUM_TIERS - 1) * INTER_TIER_GAP;

// =============================================
// HELIX CAM PHASING
// =============================================
// Each tier has NUM_CHANNELS slider strips, each driven by one cam.
// Phase between channels creates the traveling wave.
// With 11 channels: TWIST_PER_CAM = 32.73° per channel.
NUM_CAMS = NUM_CHANNELS;   // one cam per channel strip
TWIST_PER_CAM = 360.0 / NUM_CAMS;  // 32.73° with 11 channels

/* [Visibility] */
SHOW_TIER_1    = true;
SHOW_TIER_2    = true;
SHOW_TIER_3    = true;

/* [Debug] */
EXPLODE        = 0;         // [0:5:150] exploded view spacing

// =============================================
// RENDER
// =============================================
matrix_stack_v3(anim_t());


// =========================================================
// MATRIX STACK V3 ASSEMBLY
// =========================================================
module matrix_stack_v3(t = 0) {

    for (tier_idx = [0 : 2]) {
        tier_angle = TIER_ANGLES[tier_idx];
        tier_z = (1 - tier_idx) * TIER_PITCH;     // T1=+30, T2=0, T3=-30
        explode_z = (1 - tier_idx) * EXPLODE;

        show = (tier_idx == 0 && SHOW_TIER_1) ||
               (tier_idx == 1 && SHOW_TIER_2) ||
               (tier_idx == 2 && SHOW_TIER_3);

        if (show) {
            // Compute displacement for each channel strip.
            // Phase progresses linearly across channels for traveling wave.
            ch_disps = [for (ch = [0 : NUM_CHANNELS - 1])
                let(phase = ch * TWIST_PER_CAM)
                ECCENTRICITY * sin(t * 360 + phase)
            ];

            // V3 tier is centered at origin — no TIER_CENTER_X offset needed!
            translate([0, 0, tier_z + explode_z])
                rotate([0, 0, tier_angle])
                    rotate([90, 0, 0])
                        matrix_tier_v3(ch_disps);
        }
    }

    // NOTE: External spacer posts removed — tiers now have integral
    // flange ears at hex vertices with M4 bolt through-holes.
    // Alignment is handled by the M4 bolts in main_stack_v3.scad.

    // ---- Echoes ----
    echo(str("=== MATRIX STACK V3 ==="));
    echo(str("HEX_R=", HEX_R, "mm | Channels/tier=", NUM_CHANNELS));
    echo(str("Tier display H=", TIER_DISPLAY_HEIGHT, "mm | Pitch=", TIER_PITCH, "mm"));
    echo(str("Stack total H=", MATRIX_TOTAL_H, "mm (3 tiers × ", TIER_DISPLAY_HEIGHT, "mm)"));
    echo(str("Tier envelope depth=", TIER_ENVELOPE_H, "mm (front-to-back)"));
    echo(str("Twist/cam=", TWIST_PER_CAM, "° | Cams/helix=", NUM_CAMS));
    echo(str("Tier angles: ", TIER_ANGLES));
}
