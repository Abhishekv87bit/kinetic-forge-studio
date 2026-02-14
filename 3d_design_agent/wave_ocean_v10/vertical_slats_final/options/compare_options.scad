/*
 * WAVE OCEAN V10 - OPTION COMPARISON
 *
 * Toggle OPTION_SELECT to compare cam designs:
 *   "A" = Single barrel cam (uniform amplitude)
 *   "B" = 3 Y-stacked cams (per-layer amplitude)
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 */

include <../common.scad>
use <../parts/slat.scad>
use <../parts/bearing_block.scad>
use <../parts/base_plate.scad>

// ============================================
// OPTION SELECTOR
// ============================================

OPTION_SELECT = "B";  // "A" or "B"

// ============================================
// ANIMATION
// ============================================

theta = $t * 360;

// ============================================
// OPTION A: Single Barrel Cam Functions
// ============================================

SINGLE_RIDGE = 7;  // Uniform for all layers

function option_a_cam_top_z(i, L, theta) =
    let(x = slat_x(i))
    let(helix_angle = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS)
    let(phase = helix_angle + theta + LAYER_PHASE_OFFSET[L])
    let(r = CAM_CORE_RADIUS + SINGLE_RIDGE * (0.5 + 0.5 * cos(90 - phase)))
    r;

function option_a_slat_z(i, L, theta) =
    CAM_CENTER_Z + option_a_cam_top_z(i, L, theta) + FOLLOWER_HEIGHT;

// ============================================
// OPTION B: Stacked Cam Functions (uses common.scad)
// ============================================

// layer_cam_top_z and layer_slat_z already defined in common.scad

// ============================================
// CAM MODULES
// ============================================

module option_a_cam() {
    // Single barrel with uniform ridge
    barrel_y_min = LAYER_Y_OFFSET[0] - 5;
    barrel_y_max = LAYER_Y_OFFSET[2] + 5;
    barrel_depth = barrel_y_max - barrel_y_min;

    segments = 60;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;
        helix_phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS + theta;

        translate([x, barrel_y_min, 0])
        rotate([-90, 0, 0])
        linear_extrude(height = barrel_depth)
            cam_profile_uniform(helix_phase);
    }
}

module cam_profile_uniform(phase) {
    steps = 48;
    points = [for (i = [0 : steps - 1])
        let(angle = i * 360 / steps)
        let(wave_factor = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + SINGLE_RIDGE * wave_factor)
        [r * cos(angle), r * sin(angle)]
    ];
    polygon(points);
}

module option_b_cam() {
    // 3 stacked discs with per-layer ridge
    for (L = [0 : NUM_LAYERS - 1]) {
        disc_y = LAYER_Y_OFFSET[L];
        ridge = LAYER_RIDGE_HEIGHT[L];

        segments = 60;
        dx = CAM_LENGTH / segments;

        translate([0, disc_y, 0])
        for (i = [0 : segments - 1]) {
            x = -CAM_LENGTH/2 + i * dx;
            helix_phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;
            total_phase = helix_phase + theta + LAYER_PHASE_OFFSET[L];

            translate([x, 0, 0])
            rotate([0, 90, 0])
            linear_extrude(height = dx + 0.1)
                cam_profile_layer(total_phase, ridge);
        }
    }
}

module cam_profile_layer(phase, ridge) {
    steps = 48;
    points = [for (i = [0 : steps - 1])
        let(angle = i * 360 / steps)
        let(wave_factor = 0.5 + 0.5 * cos(angle - phase))
        let(r = CAM_CORE_RADIUS + ridge * wave_factor)
        [r * cos(angle), r * sin(angle)]
    ];
    polygon(points);
}

// ============================================
// SLAT LAYERS
// ============================================

module render_slats_option_a() {
    for (L = [0 : NUM_LAYERS - 1]) {
        y = layer_slat_y(L);
        col = layer_slat_color(L);

        for (i = [0 : NUM_SLATS - 1]) {
            x = slat_x(i);
            z = option_a_slat_z(i, L, theta);
            h = layer_slat_height(i, L);

            color(col)
            translate([x, y, z])
                slat(h);
        }
    }
}

module render_slats_option_b() {
    for (L = [0 : NUM_LAYERS - 1]) {
        y = layer_slat_y(L);
        col = layer_slat_color(L);

        for (i = [0 : NUM_SLATS - 1]) {
            x = slat_x(i);
            z = layer_slat_z(i, L, theta);
            h = layer_slat_height(i, L);

            color(col)
            translate([x, y, z])
                slat(h);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {
    // Base plate
    color(C_BASE)
    translate([0, 0, 0])
        base_plate();

    // Bearing blocks
    color(C_BB)
    translate([BB_LEFT_X, 0, BB_Z])
    rotate([0, 0, 180])
        bearing_block();

    color(C_BB)
    translate([BB_RIGHT_X, 0, BB_Z])
        bearing_block();

    // Shaft
    color(C_SHAFT)
    translate([0, 0, CAM_CENTER_Z])
    rotate([0, 90, 0])
        cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true, $fn = 24);

    // Cam and slats based on option
    translate([0, 0, CAM_CENTER_Z]) {
        if (OPTION_SELECT == "A") {
            color(C_CAM)
                option_a_cam();
        } else {
            color(C_CAM)
                option_b_cam();
        }
    }

    if (OPTION_SELECT == "A") {
        render_slats_option_a();
    } else {
        render_slats_option_b();
    }
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("================================================");
echo(str("  OPTION ", OPTION_SELECT, " SELECTED"));
echo("================================================");

if (OPTION_SELECT == "A") {
    echo("Single barrel cam - uniform amplitude");
    echo(str("All layers: ridge = ", SINGLE_RIDGE, "mm"));
} else {
    echo("3 Y-stacked cams - per-layer amplitude");
    echo(str("Front (L0): ridge = ", LAYER_RIDGE_HEIGHT[0], "mm (small)"));
    echo(str("Mid   (L1): ridge = ", LAYER_RIDGE_HEIGHT[1], "mm (medium)"));
    echo(str("Back  (L2): ridge = ", LAYER_RIDGE_HEIGHT[2], "mm (large)"));
}
echo("");
echo("Change OPTION_SELECT to \"A\" or \"B\" to compare");
