/*
 * WAVE OCEAN V10 - HORIZONTAL LAYERED WAVE ASSEMBLY
 *
 * Hokusai-style waves: 2D profiles stacked in depth
 * 3 complete waves, each with 4 layers
 * Layers move with phase offset creating rolling illusion
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * MECHANISM:
 * - Twisted cam rotates below scene
 * - Each layer has follower arm connected to cam
 * - Layers at different X positions = different cam phase
 * - Front layers lag behind back layers = rolling effect
 */

include <common.scad>
use <wave_profiles.scad>
use <layer_slider.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_WAVES = true;
SHOW_MECHANISM = true;
SHOW_CAM = true;
SHOW_FRAME = true;

// Debug
SHOW_GUIDE_RODS = true;
SHOW_SLIDERS = false;          // Hide for clean view

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;             // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {

    // ========== WAVE LAYERS ==========
    if (SHOW_WAVES) {
        for (w = [0 : NUM_WAVES - 1]) {
            wave_assembly(w);
        }
    }

    // ========== CAM SYSTEM ==========
    if (SHOW_CAM) {
        translate([0, CAM_CENTER_Y, CAM_CENTER_Z])
        rotate([theta, 0, 0])
        color(C_CAM)
            multi_ridge_cam();
    }

    // ========== FRAME ==========
    if (SHOW_FRAME) {
        color(C_FRAME)
            support_frame();
    }
}

// ============================================
// SINGLE WAVE ASSEMBLY (4 layers)
// ============================================

module wave_assembly(wave_num) {
    wx = wave_x(wave_num);
    scale = wave_scale(wave_num);

    for (l = [0 : NUM_LAYERS - 1]) {
        layer_at_position(wave_num, l, scale);
    }
}

// ============================================
// SINGLE LAYER POSITIONING
// ============================================

module layer_at_position(wave_num, layer_num, scale) {
    wx = wave_x(wave_num);
    ly = layer_y(layer_num);
    lz = layer_z(wave_num, layer_num, theta);

    translate([wx, ly, lz])
    rotate([90, 0, 0])  // Stand profile upright
        wave_layer(layer_num, scale);

    // Show slider mechanism
    if (SHOW_SLIDERS) {
        translate([wx + 30 * scale, ly, lz])
        color(C_MECHANISM)
            layer_slider();
    }

    // Show guide rods
    if (SHOW_GUIDE_RODS && layer_num == 0) {  // Only show once per wave
        %translate([wx + 35 * scale, ly, GUIDE_FRAME_Z - 10])
            cylinder(d = GUIDE_ROD_DIA, h = GUIDE_ROD_LENGTH);
    }
}

// ============================================
// MULTI-RIDGE CAM
// ============================================

module multi_ridge_cam() {
    // Cam with multiple ridges (one per wave)
    // Creates synchronized wave peaks

    segments = 200;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;
        phase = ((x + CAM_LENGTH/2) / CAM_LENGTH) * 360 * HELIX_TURNS;

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            cam_profile(phase);
    }

    // Shaft
    rotate([0, 90, 0])
        cylinder(d = SHAFT_DIA, h = CAM_LENGTH + 40, center = true);
}

module cam_profile(phase) {
    // Cross-section with single ridge
    points = [for (a = [0 : 360/48 : 359])
        let(ridge = CAM_RIDGE_HEIGHT * max(0, cos(a - phase - 90)))
        let(r = CAM_CORE_RADIUS + ridge)
        [r * cos(a), r * sin(a)]
    ];
    polygon(points);
}

// ============================================
// SUPPORT FRAME
// ============================================

module support_frame() {
    // Structural frame holding everything
    // Hidden behind waves when viewed from front

    frame_width = SCENE_WIDTH + 60;
    frame_height = SCENE_HEIGHT + 40;
    frame_depth = SCENE_DEPTH + 40;
    wall = 5;

    // Back panel
    translate([-frame_width/2, SCENE_DEPTH/2, CAM_CENTER_Z - 20])
        cube([frame_width, wall, frame_height + 40]);

    // Bottom panel (has cam cutout)
    difference() {
        translate([-frame_width/2, -frame_depth/2 + SCENE_DEPTH/2, CAM_CENTER_Z - 25])
            cube([frame_width, frame_depth, wall]);

        // Cam clearance
        translate([0, 0, CAM_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d = CAM_MAX_RADIUS * 2 + 10, h = CAM_LENGTH + 20, center = true);
    }

    // Side panels
    for (x_sign = [-1, 1]) {
        translate([x_sign * (frame_width/2 - wall), -frame_depth/2 + SCENE_DEPTH/2, CAM_CENTER_Z - 20])
            cube([wall, frame_depth, frame_height + 40]);
    }
}

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("==========================================");
echo("  WAVE OCEAN V10 - LAYERED WAVE SYSTEM");
echo("==========================================");
echo("");
echo(str("Animation angle: ", theta, "°"));
echo(str("Waves: ", NUM_WAVES));
echo(str("Layers per wave: ", NUM_LAYERS));
echo(str("Total layers: ", NUM_WAVES * NUM_LAYERS));
echo("");
echo("LAYER PHASE OFFSETS:");
for (l = [0 : NUM_LAYERS - 1]) {
    echo(str("  Layer ", l, ": ", layer_phase_offset(l), "° delay"));
}
echo("");
echo("The phase offset between layers creates the");
echo("illusion of waves ROLLING forward as they rise.");
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
