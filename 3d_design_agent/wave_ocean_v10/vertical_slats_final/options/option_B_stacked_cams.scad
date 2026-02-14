/*
 * OPTION B: 3 Y-STACKED THIN CAMS (Recommended)
 *
 * CHARACTERISTICS:
 * - 3 separate thin cam discs on shared X-axis shaft
 * - Each disc is Y-bounded (12mm thick) at its layer position
 * - Different ridge heights: back=10mm, mid=7mm, front=4mm
 * - Creates parallax depth effect with overlapping amplitudes
 *
 * LAYOUT (side view, looking from +X along shaft):
 *
 *              Y=-15        Y=0         Y=+15
 *                |           |            |
 *        ████████░░░████████░░░████████░░░
 *        DISC 0    gap   DISC 1    gap   DISC 2
 *        (4mm)           (7mm)           (10mm)
 *
 * TRADE-OFFS:
 * + Organic, ocean-like wave motion
 * + Back waves visually larger (perspective depth)
 * + More artistic, less mechanical
 * - Slightly more complex geometry
 */

include <../common.scad>

$fn = 72;

// ============================================
// 3-STACKED CAM MODULE
// ============================================

module stacked_cam() {
    difference() {
        union() {
            // Three cam discs, one per layer
            for (L = [0 : NUM_LAYERS - 1]) {
                cam_disc_thin(L);
            }

            // End caps at X extremes
            end_caps_stacked();
        }

        // Shaft hole through all cams
        shaft_hole();

        // Set screw holes
        set_screw_holes_stacked();
    }
}

// ============================================
// SINGLE CAM DISC - Thin Y-bounded slab
// ============================================

module cam_disc_thin(layer_index) {
    disc_y = LAYER_Y_OFFSET[layer_index];
    ridge_height = LAYER_RIDGE_HEIGHT[layer_index];
    phase_offset = LAYER_PHASE_OFFSET[layer_index];

    // Bounding box limits this disc to its Y range
    intersection() {
        // Full helical barrel
        helical_barrel_b(ridge_height, phase_offset);

        // Y-bounded box - creates thin slab at disc_y
        translate([0, disc_y, 0])
            cube([CAM_LENGTH + 10, CAM_DISC_THICKNESS, 100], center=true);
    }
}

// ============================================
// HELICAL BARREL - Full-radius cam shape
// ============================================

module helical_barrel_b(ridge_height, phase_offset) {
    segments = 90;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;
        helix_phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;
        total_phase = helix_phase + phase_offset;

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            cam_profile_2d_b(total_phase, ridge_height);
    }
}

// ============================================
// CAM CROSS-SECTION PROFILE
// ============================================

module cam_profile_2d_b(phase, ridge_height) {
    steps = 72;
    points = [for (i = [0 : steps - 1])
        let(angle = i * 360 / steps)
        let(wave_factor = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + ridge_height * wave_factor)
        [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// ============================================
// END CAPS
// ============================================

module end_caps_stacked() {
    max_ridge = max(LAYER_RIDGE_HEIGHT[0], LAYER_RIDGE_HEIGHT[1], LAYER_RIDGE_HEIGHT[2]);
    cap_r = CAM_CORE_RADIUS + max_ridge + 3;

    y_min = LAYER_Y_OFFSET[0] - CAM_DISC_THICKNESS/2 - 2;
    y_max = LAYER_Y_OFFSET[NUM_LAYERS-1] + CAM_DISC_THICKNESS/2 + 2;
    cap_depth = y_max - y_min;

    // Left cap
    translate([-CAM_LENGTH/2 - CAM_END_CAP, y_min, 0])
    rotate([-90, 0, 0])
        cylinder(r = cap_r, h = cap_depth, $fn = 48);

    // Right cap
    translate([CAM_LENGTH/2, y_min, 0])
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

module set_screw_holes_stacked() {
    screw_depth = CAM_CORE_RADIUS;

    for (x = [-CAM_LENGTH/2 + 10, CAM_LENGTH/2 - 10]) {
        translate([x, 0, CAM_CORE_RADIUS + 5])
            cylinder(d = M3_HOLE, h = screw_depth, $fn = 16);

        translate([x, CAM_CORE_RADIUS + 5, 0])
        rotate([-90, 0, 0])
            cylinder(d = M3_HOLE, h = screw_depth, $fn = 16);
    }
}

// ============================================
// RENDER
// ============================================

color(C_CAM)
stacked_cam();

// Ghost shaft
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);

// ============================================
// VERIFICATION
// ============================================

echo("=== OPTION B: 3 Y-STACKED THIN CAMS ===");
echo(str("Total X length: ", CAM_LENGTH, "mm (active), ", CAM_TOTAL_LENGTH, "mm (with caps)"));
echo(str("Disc thickness: ", CAM_DISC_THICKNESS, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo("");
echo("PER-LAYER CONFIGURATION:");
for (L = [0 : NUM_LAYERS - 1]) {
    y_start = LAYER_Y_OFFSET[L] - CAM_DISC_THICKNESS/2;
    y_end = LAYER_Y_OFFSET[L] + CAM_DISC_THICKNESS/2;
    echo(str("  Layer ", L, ": Y=[", y_start, " to ", y_end, "], ridge=", LAYER_RIDGE_HEIGHT[L], "mm"));
}
echo("");
echo("PROS:");
echo("  - Organic depth effect (back waves bigger)");
echo("  - More artistic, ocean-like motion");
echo("  - Each layer independently tunable");
echo("");
echo("CONS:");
echo("  - Slightly more complex geometry");
