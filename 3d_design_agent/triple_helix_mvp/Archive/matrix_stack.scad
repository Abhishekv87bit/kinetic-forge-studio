// =========================================================
// MATRIX STACK — 3 V5 Tiers at 0°/120°/240°
// =========================================================
// Stacks three V5-based matrix tiers tightly on top of each other.
// Each tier rotated 120° from the previous about the vertical axis.
//
// Vertical layout (Z-axis, looking from side):
//   Tier 1 (top):    Z = +TIER_PITCH      rotation = 0°
//   Tier 2 (middle): Z = 0                rotation = 120°
//   Tier 3 (bottom): Z = -TIER_PITCH      rotation = 240°
//
// After rotate([90,0,0]) on each tier:
//   V5 code Z (channel stacking) → display -Y
//   V5 code Y (housing depth) → display Z (vertical)
//   V5 code X (slider travel) → display X
//
// So the tier looks like V5 standing up, channels stacking front-to-back.
// Then rotate_z(tier_angle) spins the slider direction.
// =========================================================

include <config.scad>
use <matrix_tier_v2.scad>

/* [Visibility] */
SHOW_TIER_1   = true;
SHOW_TIER_2   = true;
SHOW_TIER_3   = true;
SHOW_SPACERS  = false;  // disabled — tiers sit directly on each other, no external posts needed

/* [Debug] */
EXPLODE       = 0;      // [0:5:150] exploded view spacing

// =========================================================
// STANDALONE RENDER
// =========================================================
matrix_stack_assembly(anim_t());


// =========================================================
// MATRIX STACK ASSEMBLY
// =========================================================

module matrix_stack_assembly(t = 0) {

    // Compute per-channel slider displacements for each tier
    // Each tier's 5 channels are driven by cams with progressive phase
    for (tier_idx = [0 : 2]) {
        tier_angle = TIER_ANGLES[tier_idx];
        tier_z = (1 - tier_idx) * TIER_PITCH;  // T1=+TIER_PITCH, T2=0, T3=-TIER_PITCH
        explode_z = (1 - tier_idx) * EXPLODE;

        show = (tier_idx == 0 && SHOW_TIER_1) ||
               (tier_idx == 1 && SHOW_TIER_2) ||
               (tier_idx == 2 && SHOW_TIER_3);

        if (show) {
            // Compute displacement for each of the 5 channel strips.
            // One cam per channel. Phase = cam_index × TWIST_PER_CAM.
            ch_disps = [for (ch = [0:4])
                let(phase = ch * TWIST_PER_CAM)
                ECCENTRICITY * sin(t * 360 + phase)
            ];

            // CRITICAL: Center-point alignment for tier stacking.
            // V5 tier is NOT centered at origin — it's offset at X ≈ -51.
            // We must translate the tier so its geometric center (TIER_CENTER_X, 0)
            // sits at the rotation origin BEFORE rotating by tier_angle.
            // Transform order (inside-out):
            //   1. matrix_tier() — in V5 local coords (X=slider, Y=depth, Z=stack)
            //   2. translate([-TIER_CENTER_X, 0, 0]) — shift center to origin
            //   3. rotate([90,0,0]) — stand up (Z-stack → display -Y)
            //   4. rotate([0,0,tier_angle]) — spin to 0°/120°/240°
            //   5. translate([0,0,tier_z]) — stack vertically
            translate([0, 0, tier_z + explode_z])
                rotate([0, 0, tier_angle])
                    rotate([90, 0, 0])
                        translate([-TIER_CENTER_X, 0, 0])
                            matrix_tier(ch_disps);
        }
    }

    // Spacer posts at hex corners (hold tiers together)
    // Posts must be OUTSIDE the circumscribed circle of the rotated tiers
    if (SHOW_SPACERS) {
        // After centering, tier half-width = max(|leftmost - CENTER_X|, |rightmost - CENTER_X|)
        // = max(|-119-(-51)|, |17-(-51)|) = max(68, 68) = 68mm
        // halfH = 2*STACK_OFFSET + CH_GAPS[0]/2 + WALL_THICKNESS = 36mm
        // circ_R = sqrt(68² + 36²) ≈ 77mm
        _halfW = max(abs(-119 - TIER_CENTER_X), abs(17 - TIER_CENTER_X));
        _halfH = 2*STACK_OFFSET + CH_GAPS[0]/2 + WALL_THICKNESS;
        spacer_r = sqrt(_halfW*_halfW + _halfH*_halfH) + 5;
        total_h = 2 * TIER_PITCH + TIER_ENVELOPE_H;

        for (a = [0 : 60 : 300]) {
            px = spacer_r * cos(a + 30);
            py = spacer_r * sin(a + 30);

            color(C_FRAME)
            translate([px, py, -TIER_PITCH - TIER_ENVELOPE_H/2])
                cylinder(d = 8, h = total_h, $fn = 20);
        }
    }

    echo(str("=== MATRIX STACK ==="));
    echo(str("Tier height: ", TIER_ENVELOPE_H, "mm | Pitch: ", TIER_PITCH, "mm"));
    echo(str("Total stack: ", 2 * TIER_PITCH + TIER_ENVELOPE_H, "mm"));
    echo(str("Center pivot: X=", TIER_CENTER_X, "mm (applied)"));
    echo(str("Spacer R: ", spacer_r, "mm | Angles: ", TIER_ANGLES));
}
