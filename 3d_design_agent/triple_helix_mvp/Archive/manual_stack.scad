// =========================================================
// MANUAL STACK — Place tiers yourself, see the result
// =========================================================
// Each tier is a V5 unit. You control how many and where.
// Rotation auto-increments 120° per tier.
//
// CONTROLS:
//   NUM_TIERS_SHOW  — how many tiers to display (1, 2, or 3)
//   TIER_GAP        — vertical gap between tiers (0 = touching)
//   TIER_CENTER_X   — V5 geometric center offset (for alignment)
//
// After rotate([90,0,0]):
//   V5 X (slider travel)     → display X
//   V5 Y (housing depth)     → display Z  (tier "thickness")
//   V5 Z (channel stacking)  → display -Y (front-to-back)
//
// So each tier is a pancake:
//   thickness = HOUSING_HEIGHT (in Z)
//   diameter  = channel lengths (in X-Y)
// =========================================================

include <config.scad>
use <matrix_tier_v2.scad>

/* [Manual Controls] */
NUM_TIERS_SHOW = 3;     // [1:1:3] how many tiers to show
TIER_GAP       = 0;     // [0:1:50] gap between tiers (mm)

// =========================================================
// PLACE TIERS
// =========================================================

// Tier thickness in display Z = HOUSING_HEIGHT
tier_thick = HOUSING_HEIGHT;

// Static displacement (no animation — just show the shape)
static_disps = [0, 0, 0, 0, 0];

for (i = [0 : NUM_TIERS_SHOW - 1]) {

    tier_angle = i * 120;
    tier_z     = -i * (tier_thick + TIER_GAP);  // stack downward

    color(i == 0 ? [0.6, 0.6, 1.0, 0.8] :
          i == 1 ? [1.0, 0.5, 0.5, 0.8] :
                   [0.5, 1.0, 0.5, 0.8])
    translate([0, 0, tier_z])
        rotate([0, 0, tier_angle])
            rotate([90, 0, 0])
                translate([-TIER_CENTER_X, 0, 0])
                    matrix_tier(static_disps);
}

// Center axis (pencil through the stack)
%color("red")
cylinder(d = 2, h = tier_thick * 4, center = true, $fn = 12);

echo(str("Tiers shown: ", NUM_TIERS_SHOW));
echo(str("Tier thickness (Z): ", tier_thick, "mm"));
echo(str("Gap: ", TIER_GAP, "mm"));
echo(str("Total stack height: ", NUM_TIERS_SHOW * tier_thick + (NUM_TIERS_SHOW - 1) * TIER_GAP, "mm"));
