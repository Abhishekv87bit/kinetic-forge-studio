// =========================================================
// MAIN STACK V5.3 — Monolithic Matrix Assembly
// =========================================================
// V5.3: 8mm shaft, solid walls (no windows), slider pulley bias.
// Monolithic print-in-place matrix. All 3 tiers printed as ONE piece
// with zero inter-tier gap. Side-walls-only channels enable vertical
// string routing. Anchor plate (top) + guide plates (bottom) with
// alignment pins.
//
// 75% scale: HEX_R=89, 11 channels per tier, 3 tiers at 0/120/240.
//
// Tiers render with full internal detail (pulleys, sliders, walls).
// Anchor and guide plates render via dedicated V5.3 modules.
//
// Z-Layout (matrix center = Z=0):
//   +36.5  Anchor plate top (5mm thick, 3 alignment pins protruding down)
//   +31.5  Anchor plate bottom / Tier 1 top
//   +21    Tier 1 center
//   +10.5  Tier 1 bottom / Tier 2 top   <- ZERO GAP (touching)
//     0    Tier 2 center
//   -10.5  Tier 2 bottom / Tier 3 top   <- ZERO GAP (touching)
//   -21    Tier 3 center
//   -31.5  Tier 3 bottom / Guide Plate 1 top
//   -34.5  Guide Plate 1 bottom (3mm, alignment pin holes)
//   -49.5  Guide Plate 2 top (after 15mm spacer gap)
//   -54.5  Guide Plate 2 bottom (5mm, alignment pin holes)
// =========================================================

include <config_v5_3.scad>
use <matrix_tier_v5_3.scad>
use <anchor_plate_v5_3.scad>
use <guide_plate_v5_3.scad>

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
main_stack_v5_3(anim_t());


// =========================================================
// MAIN STACK V5.3 ASSEMBLY
// =========================================================
module main_stack_v5_3(t = 0) {

    explode_anchor = EXPLODE * 2;
    explode_gp     = EXPLODE;

    // ---- ANCHOR PLATE (v5.3 — with alignment pins) ----
    if (SHOW_ANCHOR) {
        color(C_ANCHOR_MS)
        translate([0, 0, ANCHOR_Z + explode_anchor])
            anchor_plate_v5_3();
    }

    // ---- MATRIX TIERS (3 at 0/120/240 deg — FULL DETAIL, ZERO GAP) ----
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

    // ---- GUIDE PLATES (v5.3 — with alignment pin holes) ----
    if (SHOW_GUIDE_PLATES) {
        color(C_GUIDE_MS)
        translate([0, 0, -explode_gp])
            guide_plate_assembly_v5_3();
    }

    // ---- ECHOES ----
    echo(str("=== MAIN STACK V5.3 (Monolithic Matrix) ==="));
    echo(str("HEX_R=", HEX_R, "mm | C2C=", HEX_C2C, "mm"));
    echo(str("Channels/tier=", NUM_CHANNELS, " | Tiers=", NUM_TIERS, " | Inter-tier gap=0 (monolithic)"));
    echo(str("Stack height=", TOTAL_STACK_H, "mm (anchor top to GP2 bottom)"));
    echo(str("Twist/cam=", round(TWIST_PER_CAM*100)/100, "deg"));
    echo(str("Z layout: Anchor=", ANCHOR_Z, "(+", ANCHOR_THICK, ") T1=+", TIER_PITCH,
             " T2=0 T3=-", TIER_PITCH, " GP1=", GP1_Z, " GP2=", GP2_Z, "(-", GP2_THICK, ")" ));
}
