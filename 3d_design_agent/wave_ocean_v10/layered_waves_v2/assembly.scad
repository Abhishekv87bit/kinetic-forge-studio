/*
 * HORIZONTAL LAYERED WAVE SYSTEM V2 - COMPLETE ASSEMBLY
 * ======================================================
 *
 * Hokusai-style waves: 2D profiles stacked in depth
 * 3 complete waves, each with 3 layers (body, curl, foam)
 * Single cam drives all 9 layers via follower arms
 * Phase offset between layers creates rolling wave illusion
 *
 * ANIMATION:
 *   OpenSCAD: View -> Animate
 *   FPS: 30
 *   Steps: 120
 *
 * MECHANISM PHYSICS:
 * - Twisted cam rotates on horizontal axis
 * - Each layer's follower arm contacts cam at different X position
 * - Helix twist in cam means different X = different phase
 * - Back layers (body) lead, front layers (foam) lag
 * - Result: wave appears to roll forward as it rises
 */

include <common.scad>
use <parts/wave_layer_body.scad>
use <parts/wave_layer_curl.scad>
use <parts/wave_layer_foam.scad>
use <parts/layer_slider.scad>
use <parts/follower_arm.scad>
use <parts/cam.scad>
use <parts/guide_frame.scad>
use <parts/bearing_block.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_WAVES = true;
SHOW_SLIDERS = true;
SHOW_FOLLOWERS = true;
SHOW_CAM = true;
SHOW_FRAME = true;
SHOW_BEARINGS = true;
SHOW_GUIDE_RODS = true;

// Debug mode (shows all mechanism parts)
DEBUG_MODE = false;

// ============================================
// ANIMATION CONTROL
// ============================================

// Manual angle override: set 0-360 for static pose, -1 for animation
MANUAL_ANGLE = -1;

// Calculate current rotation angle
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// Animation speed factor (for visual tuning)
SPEED_FACTOR = 1.0;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {
    /*
     * Complete kinetic sculpture assembly
     * All parts positioned at correct locations
     * Animation shows rolling wave motion
     */

    // ========== STRUCTURAL FRAME ==========
    if (SHOW_FRAME) {
        translate([0, 0, FRAME_BASE_Z])
        color(C_FRAME)
            guide_frame();
    }

    // ========== GUIDE RODS ==========
    if (SHOW_GUIDE_RODS) {
        guide_rods_assembly();
    }

    // ========== WAVE LAYERS ==========
    if (SHOW_WAVES) {
        for (w = [0 : NUM_WAVES - 1]) {
            wave_assembly(w, theta);
        }
    }

    // ========== CAM SYSTEM ==========
    if (SHOW_CAM) {
        cam_assembly(theta);
    }

    // ========== BEARING BLOCKS ==========
    if (SHOW_BEARINGS) {
        bearing_assembly();
    }
}

// ============================================
// SINGLE WAVE ASSEMBLY (3 layers)
// ============================================

module wave_assembly(wave_num, angle) {
    /*
     * Complete wave with all 3 layers
     * Each layer animated with phase offset
     */

    scale = wave_scale(wave_num);

    for (l = [0 : NUM_LAYERS - 1]) {
        layer_assembly(wave_num, l, scale, angle);
    }
}

// ============================================
// SINGLE LAYER ASSEMBLY
// ============================================

module layer_assembly(wave_num, layer_num, scale, angle) {
    /*
     * Single layer with:
     * - Wave profile piece
     * - Slider block on guide rod
     * - Follower arm to cam
     */

    // Calculate positions
    wx = wave_x(wave_num);
    ly = layer_y(layer_num);
    lz = layer_z(wave_num, layer_num, angle);

    guide_x = wx + GUIDE_OFFSET_X;

    // Wave profile (rotated to stand upright)
    translate([wx, ly, lz])
    rotate([90, 0, 0])
        wave_layer_by_num(layer_num, scale);

    // Slider on guide rod
    if (SHOW_SLIDERS) {
        translate([guide_x, ly, lz])
        color(C_MECHANISM)
            layer_slider();
    }

    // Follower arm
    if (SHOW_FOLLOWERS) {
        follower_assembly(wave_num, layer_num, lz, angle);
    }
}

// ============================================
// WAVE LAYER BY NUMBER
// ============================================

module wave_layer_by_num(layer_num, scale) {
    /*
     * Select correct layer module based on number
     * Layer 0: Foam (front)
     * Layer 1: Curl (middle)
     * Layer 2: Body (back)
     */

    if (layer_num == 0) {
        wave_layer_foam(scale);
    } else if (layer_num == 1) {
        wave_layer_curl(scale);
    } else if (layer_num == 2) {
        wave_layer_body(scale);
    }
}

// ============================================
// FOLLOWER ARM ASSEMBLY
// ============================================

module follower_assembly(wave_num, layer_num, slider_z, angle) {
    /*
     * Follower arm connecting slider to cam
     * Animates to track slider position
     */

    wx = wave_x(wave_num);
    ly = layer_y(layer_num);
    guide_x = wx + GUIDE_OFFSET_X;

    // Pivot point on slider
    pivot_x = guide_x;
    pivot_y = ly;
    pivot_z = slider_z - 6;  // Below slider body

    // Cam contact point (on cam surface below)
    cam_surface_z = CAM_CENTER_Z + cam_radius(wx, angle - layer_phase(layer_num));

    // Calculate arm angle
    vertical_distance = pivot_z - cam_surface_z;
    y_offset = ly;  // Distance from cam axis (Y)

    arm_angle = atan2(y_offset, vertical_distance);

    // Position and rotate follower arm
    translate([pivot_x, pivot_y, pivot_z])
    rotate([arm_angle - 90, 0, 0])
    color(C_MECHANISM)
        follower_arm();
}

// ============================================
// CAM ASSEMBLY
// ============================================

module cam_assembly(angle) {
    /*
     * Cam with rotation animation
     */

    translate([0, 0, CAM_CENTER_Z])
    rotate([angle * SPEED_FACTOR, 0, 0])
        twisted_cam();

    // Shaft extends beyond cam
    translate([0, 0, CAM_CENTER_Z])
    rotate([0, 90, 0])
    color([0.6, 0.6, 0.65])
        cylinder(d = SHAFT_DIA, h = CAM_TOTAL_LENGTH + 40, center = true);
}

// ============================================
// BEARING ASSEMBLY
// ============================================

module bearing_assembly() {
    /*
     * Bearing blocks at each end of cam
     */

    // Left bearing block
    translate([-CAM_TOTAL_LENGTH/2 - 10, 0, CAM_CENTER_Z])
    rotate([0, 90, 0])
    rotate([0, 0, 90])
        bearing_block();

    // Right bearing block
    translate([CAM_TOTAL_LENGTH/2 + 10, 0, CAM_CENTER_Z])
    rotate([0, -90, 0])
    rotate([0, 0, 90])
        bearing_block();
}

// ============================================
// GUIDE RODS ASSEMBLY
// ============================================

module guide_rods_assembly() {
    /*
     * All 9 guide rods in position
     */

    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            guide_x = wave_x(w) + GUIDE_OFFSET_X;
            guide_y = layer_y(l);
            guide_z = FRAME_BASE_Z + 10;  // Start above frame bottom

            color(C_GUIDE)
            translate([guide_x, guide_y, guide_z])
                cylinder(d = GUIDE_ROD_DIA, h = GUIDE_ROD_LENGTH);
        }
    }
}

// ============================================
// EXPLODED VIEW
// ============================================

module assembly_exploded(explode = 30) {
    /*
     * Exploded view for assembly visualization
     * Components separated for clarity
     */

    // Frame (base)
    translate([0, 0, FRAME_BASE_Z])
        guide_frame();

    // Cam (below, offset down)
    translate([0, 0, -explode])
        cam_assembly(0);

    // Bearing blocks (offset outward)
    translate([-CAM_TOTAL_LENGTH/2 - 10 - explode/2, 0, CAM_CENTER_Z])
    rotate([0, 90, 0])
    rotate([0, 0, 90])
        bearing_block();

    translate([CAM_TOTAL_LENGTH/2 + 10 + explode/2, 0, CAM_CENTER_Z])
    rotate([0, -90, 0])
    rotate([0, 0, 90])
        bearing_block();

    // Wave layers (offset up)
    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            wx = wave_x(w);
            ly = layer_y(l);
            lz = FRAME_BASE_Z + 40 + l * explode/2;

            translate([wx, ly, lz + explode])
            rotate([90, 0, 0])
                wave_layer_by_num(l, wave_scale(w));
        }
    }
}

// ============================================
// RENDER
// ============================================

assembly();

// Show exploded view offset to side
// translate([0, 200, 0])
//     assembly_exploded(40);

// ============================================
// INFO OUTPUT
// ============================================

echo("============================================");
echo("HORIZONTAL LAYERED WAVE SYSTEM V2");
echo("============================================");
echo("");
echo(str("Current angle: ", theta, " degrees"));
echo(str("Animation: $t = ", $t));
echo("");
echo("CONFIGURATION:");
echo(str("  Waves: ", NUM_WAVES));
echo(str("  Layers per wave: ", NUM_LAYERS));
echo(str("  Total profiles: ", NUM_WAVES * NUM_LAYERS));
echo(str("  Wave amplitude: ", WAVE_AMPLITUDE, "mm"));
echo(str("  Phase offset/layer: ", PHASE_OFFSET_PER_LAYER, " degrees"));
echo("");
echo("LAYER POSITIONS AT CURRENT ANGLE:");
for (w = [0 : NUM_WAVES - 1]) {
    echo(str("  Wave ", w, ":"));
    for (l = [0 : NUM_LAYERS - 1]) {
        z = layer_z(w, l, theta);
        echo(str("    Layer ", l, " (", LAYER_NAMES[l], "): Z = ", round(z * 10) / 10, "mm"));
    }
}
echo("");
echo("ANIMATION:");
echo("  1. View -> Animate");
echo("  2. Set FPS = 30");
echo("  3. Set Steps = 120");
echo("  4. Enjoy the rolling waves!");
echo("");
echo("MECHANISM VERIFICATION:");
echo(str("  Guide rod hole: ", GUIDE_ROD_HOLE, "mm"));
echo(str("  Bearing pocket: ", BEARING_POCKET_DIA, "mm"));
echo(str("  Cam max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("  Follower arm length: ", FOLLOWER_ARM_LENGTH, "mm"));
echo("============================================");
