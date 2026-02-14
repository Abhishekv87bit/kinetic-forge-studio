// =========================================================
// MAIN STACK V5 — Matrix Assembly (Frame-Clamped)
// =========================================================
// Anchor plate + 3 hex tiers (full detail) + 2 guide plates.
//
// 75% scale: HEX_R=88.5, 9 channels per tier, 3 tiers at 0/120/240.
//
// Tiers render with full internal detail (pulleys, sliders, walls).
// Anchor and guide plates render as simplified hex shapes to stay
// under OpenSCAD's CSG element limit.
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

include <config_v5.scad>
use <matrix_tier_v5.scad>

$fn = 40;

// =============================================
// COLORS
// =============================================
C_ANCHOR_MS  = [0.6, 0.6, 0.7, 0.8];
C_GUIDE_MS   = [0.6, 0.85, 0.6, 0.8];

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
// DERIVED
// =============================================
TOTAL_STACK_H = ANCHOR_Z + ANCHOR_THICK - GP2_BOT;

// =============================================
// STANDALONE RENDER
// =============================================
main_stack_v5(anim_t());


// =========================================================
// MAIN STACK V5 ASSEMBLY
// =========================================================
module main_stack_v5(t = 0) {

    explode_anchor = EXPLODE * 2;
    explode_gp     = EXPLODE;

    // ---- ANCHOR PLATE (simplified hex shape) ----
    if (SHOW_ANCHOR) {
        color(C_ANCHOR_MS)
        translate([0, 0, ANCHOR_Z + explode_anchor])
            cylinder(r = HEX_R, h = ANCHOR_THICK, $fn = 6);
    }

    // ---- MATRIX TIERS (3 at 0/120/240 deg — FULL DETAIL) ----
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
                        matrix_tier_v5(ch_disps);
        }
    }

    // ---- GUIDE PLATES (simplified hex shapes) ----
    if (SHOW_GUIDE_PLATES) {
        color(C_GUIDE_MS) {
            translate([0, 0, GP1_Z - explode_gp])
                cylinder(r = HEX_R, h = GP1_THICK, $fn = 6);
            translate([0, 0, GP2_Z - explode_gp])
                cylinder(r = HEX_R, h = GP2_THICK, $fn = 6);
        }
    }

    // ---- ECHOES ----
    echo(str("=== MAIN STACK V5 ==="));
    echo(str("HEX_R=", HEX_R, "mm | C2C=", HEX_C2C, "mm"));
    echo(str("Channels/tier=", NUM_CHANNELS, " | Tiers=", NUM_TIERS));
    echo(str("Stack height=", TOTAL_STACK_H, "mm (anchor top to GP2 bottom)"));
    echo(str("Twist/cam=", round(TWIST_PER_CAM*100)/100, "deg"));
    echo(str("Z layout: Anchor=", ANCHOR_Z, "(+", ANCHOR_THICK, ") T1=+", TIER_PITCH,
             " T2=0 T3=-", TIER_PITCH, " GP1=", GP1_Z, " GP2=", GP2_Z, "(-", GP2_THICK, ")" ));
}
