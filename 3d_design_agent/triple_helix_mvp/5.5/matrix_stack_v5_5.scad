// =========================================================
// MATRIX STACK V5.6 — 3-Tier Assembly
// =========================================================
// Assembles 3 matrix tiers from matrix_tier_v5_6.scad.
// Changes to the tier module flow here automatically.
//
// Separate print from frame. Slides into frame from above
// through the open upper hex ring, seats on lower ring ledge.
//
// Tiers at Z = [+TIER_PITCH, 0, -TIER_PITCH]
// Rotated to TIER_ANGLES = [180, 300, 60] — sliders face helixes
// =========================================================

include <config_v5_5.scad>
use <matrix_tier_v5_6.scad>

$fn = 24;

// =============================================
// STANDALONE RENDER
// =============================================
matrix_stack(anim_t());

echo(str("=== MATRIX STACK V5.6 — 3 tiers x ", NUM_CHANNELS, " channels ==="));
echo(str("TIER_PITCH=", TIER_PITCH, "mm | TIER_ANGLES=[", TIER_ANGLES[0], ",", TIER_ANGLES[1], ",", TIER_ANGLES[2], "]"));
echo(str("Total stack: ", TIER1_TOP - TIER3_BOT, "mm (TIER1_TOP=", TIER1_TOP, " TIER3_BOT=", TIER3_BOT, ")"));


// =========================================================
// MATRIX STACK — 3 tiers
// =========================================================
module matrix_stack(t = 0) {
    for (tier_idx = [0 : 2]) {
        tier_angle = TIER_ANGLES[tier_idx];
        tier_z = (1 - tier_idx) * TIER_PITCH;

        ch_disps = [for (ch = [0 : NUM_CHANNELS - 1])
            let(phase = ch * TWIST_PER_CAM)
            ECCENTRICITY * sin(-t * 360 + phase)
        ];

        translate([0, 0, tier_z])
            rotate([0, 0, tier_angle])
                rotate([90, 0, 0])
                    matrix_tier(ch_disps);
    }
}
