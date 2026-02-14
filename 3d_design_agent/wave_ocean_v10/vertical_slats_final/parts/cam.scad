/*
 * CAM - 3 Thin Cam Discs Stacked in Y
 *
 * GEOMETRY:
 * - 3 separate thin cam discs sharing X-axis shaft
 * - Each disc is a circular cam profile EXTRUDED ALONG Y
 * - Disc thickness = CAM_DISC_THICKNESS (12mm)
 * - Different ridge heights create varying amplitudes
 *
 * KEY INSIGHT:
 * The 2D cam profile is in the X-Z plane (a circle with varying radius).
 * It gets extruded along Y to create the disc thickness.
 * This way, each disc is truly separate in Y space.
 *
 * LAYOUT (top view, looking from +Z down):
 *
 *    Y=-21 to -9    Y=-6 to +6    Y=+9 to +21
 *   ┌───────────┐  ┌───────────┐  ┌───────────┐
 *   │  DISC 0   │  │  DISC 1   │  │  DISC 2   │
 *   │  ridge=4  │  │  ridge=7  │  │  ridge=10 │
 *   └───────────┘  └───────────┘  └───────────┘
 *        gap=3         gap=3
 */

include <../common.scad>

$fn = 72;

// ============================================
// MAIN CAM MODULE
// ============================================

module cam() {
    difference() {
        union() {
            // Three separate cam discs
            for (L = [0 : NUM_LAYERS - 1]) {
                cam_disc(L);
            }

            // End caps connect all discs
            end_caps();
        }

        // Shaft hole
        shaft_hole();

        // Set screws
        set_screw_holes();
    }
}

// ============================================
// SINGLE CAM DISC
// ============================================
// Creates one thin disc at layer L's Y position.
// The disc is CAM_DISC_THICKNESS wide in Y.
// The profile is a circle with varying radius (helical cam).

module cam_disc(L) {
    disc_y = LAYER_Y_OFFSET[L];
    ridge = LAYER_RIDGE_HEIGHT[L];
    phase_off = LAYER_PHASE_OFFSET[L];

    // Y bounds of this disc
    y_front = disc_y - CAM_DISC_THICKNESS/2;

    // Build disc from X-slices
    segments = 90;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        // Helix phase at this X position
        helix_phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS + phase_off;

        // Create thin X-slice of cam, extruded along Y
        translate([x, y_front, 0])
        rotate([-90, 0, 0])
        linear_extrude(height = CAM_DISC_THICKNESS)
            cam_profile_2d(helix_phase, ridge);
    }
}

// ============================================
// 2D CAM PROFILE
// ============================================
// Circle in X-Z plane with radius varying by angle.
// When extruded along Y, becomes the cam disc.

module cam_profile_2d(phase, ridge) {
    steps = 72;

    points = [for (a = [0 : steps - 1])
        let(angle = a * 360 / steps)
        let(wave = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + ridge * wave)
        [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// ============================================
// END CAPS
// ============================================

module end_caps() {
    max_ridge = max(LAYER_RIDGE_HEIGHT[0], LAYER_RIDGE_HEIGHT[1], LAYER_RIDGE_HEIGHT[2]);
    cap_r = CAM_CORE_RADIUS + max_ridge + 3;

    y_front = LAYER_Y_OFFSET[0] - CAM_DISC_THICKNESS/2 - 2;
    y_back = LAYER_Y_OFFSET[NUM_LAYERS-1] + CAM_DISC_THICKNESS/2 + 2;
    cap_depth = y_back - y_front;

    // Left cap
    translate([-CAM_LENGTH/2 - CAM_END_CAP, y_front, 0])
    rotate([-90, 0, 0])
        cylinder(r = cap_r, h = cap_depth, $fn = 48);

    // Right cap
    translate([CAM_LENGTH/2, y_front, 0])
    rotate([-90, 0, 0])
        cylinder(r = cap_r, h = cap_depth, $fn = 48);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    rotate([0, 90, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_TOTAL_LENGTH + 20, center = true, $fn = 32);
}

// ============================================
// SET SCREW HOLES
// ============================================

module set_screw_holes() {
    for (x = [-CAM_LENGTH/2 + 10, CAM_LENGTH/2 - 10]) {
        translate([x, 0, CAM_CORE_RADIUS + 5])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS, $fn = 16);

        translate([x, CAM_CORE_RADIUS + 5, 0])
        rotate([-90, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS, $fn = 16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_CAM)
cam();

// Ghost shaft
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);

// ============================================
// DEBUG: Show disc Y bounds
// ============================================

echo("=== CAM: 3 Y-SEPARATED DISCS ===");
for (L = [0 : NUM_LAYERS - 1]) {
    y1 = LAYER_Y_OFFSET[L] - CAM_DISC_THICKNESS/2;
    y2 = LAYER_Y_OFFSET[L] + CAM_DISC_THICKNESS/2;
    echo(str("Disc ", L, ": Y=[", y1, " to ", y2, "], ridge=", LAYER_RIDGE_HEIGHT[L], "mm"));
}
echo(str("Disc thickness: ", CAM_DISC_THICKNESS, "mm"));
gap = LAYER_Y_SPACING - CAM_DISC_THICKNESS;
echo(str("Gap between discs: ", gap, "mm"));
