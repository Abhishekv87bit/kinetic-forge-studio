/*
 * WAVE OCEAN V10 - FULL ASSEMBLY
 *
 * Complete animated assembly of all parts
 * Animation: View -> Animate, FPS=30, Steps=120
 *
 * COORDINATE SYSTEM:
 * - X: Along worm axis (left to right)
 * - Y: Front to back (viewer looks at -Y)
 * - Z: Up
 *
 * MECHANISM:
 * - Worm at Z = WORM_CENTER_Z (35mm), rotates around X axis
 * - Slats above worm in guide rails, slide up/down in Z
 * - Follower arms connect slat bottom to worm groove
 * - As worm rotates, groove pushes arms, arms push slats
 */

include <common.scad>
use <parts/worm_cam.scad>
use <parts/slat.scad>
use <parts/follower_arm.scad>
use <parts/guide_rail_front.scad>
use <parts/guide_rail_back.scad>
use <parts/bearing_block_L.scad>
use <parts/bearing_block_R.scad>
use <parts/base_plate.scad>
use <parts/motor_mount.scad>
use <parts/shaft_coupler.scad>

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_BASE = true;
SHOW_BEARING_BLOCKS = true;
SHOW_GUIDE_RAILS = true;
SHOW_WORM = true;
SHOW_SHAFT = true;
SHOW_SLATS = true;
SHOW_FOLLOWER_ARMS = true;
SHOW_MOTOR = false;          // Motor mount needs redesign
SHOW_COUPLER = false;

// Debug
SHOW_BEARINGS = true;
SHOW_GROOVE_PATH = true;     // Show where groove is

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;           // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MAIN ASSEMBLY
// ============================================

module assembly() {
    // ========== BASE STRUCTURE ==========

    // Base plate
    if (SHOW_BASE) {
        color(C_BASE)
        base_plate();
    }

    // Bearing blocks
    if (SHOW_BEARING_BLOCKS) {
        // Left block
        translate([BEARING_L_X, 0, BASE_THICKNESS])
        color(C_BEARING_BLOCK)
            bearing_block_L();

        // Right block
        translate([BEARING_R_X, 0, BASE_THICKNESS])
        color(C_BEARING_BLOCK)
            bearing_block_R();
    }

    // Guide rails
    if (SHOW_GUIDE_RAILS) {
        // Front rail
        translate([0, GUIDE_FRONT_Y, GUIDE_Z])
        color(C_GUIDE)
            guide_rail_front();

        // Back rail
        translate([0, GUIDE_BACK_Y, GUIDE_Z])
        color(C_GUIDE)
            guide_rail_back();
    }

    // ========== ROTATING PARTS ==========

    // Worm shaft
    if (SHOW_SHAFT) {
        translate([0, 0, WORM_CENTER_Z])
        rotate([0, 90, 0])
        color(C_SHAFT)
            cylinder(d=WORM_SHAFT_DIA, h=WORM_SHAFT_LENGTH, center=true);
    }

    // Worm cam
    if (SHOW_WORM) {
        translate([0, 0, WORM_CENTER_Z])
        rotate([theta, 0, 0])  // Rotate around X axis
        color(C_WORM)
            worm_cam();
    }

    // ========== SLAT ASSEMBLIES ==========

    for (i = [0 : NUM_SLATS - 1]) {
        slat_assembly(i);
    }

    // Debug: groove path
    if (SHOW_GROOVE_PATH) {
        groove_visualization();
    }
}

// ============================================
// SINGLE SLAT ASSEMBLY
// ============================================

module slat_assembly(i) {
    // X position along worm
    sx = slat_x(i);

    // Groove position for this slat at current theta
    gy = groove_y(sx, theta);
    gz = groove_z(sx, theta);

    // Slat Z position - tracks groove via follower arm
    // When groove is at top (gz = WORM_CENTER_Z + GROOVE_RADIUS), slat is up
    // When groove at bottom (gz = WORM_CENTER_Z - GROOVE_RADIUS), slat is down
    sz = slat_z(i, theta);

    // Slat (centered at sx, Y=0, bottom at sz)
    if (SHOW_SLATS) {
        translate([sx, 0, sz])
        color(slat_color(i))
            slat();
    }

    // Follower arm
    if (SHOW_FOLLOWER_ARMS) {
        // Pivot point is at slat bottom (sz - 10)
        pivot_x = sx;
        pivot_y = 0;
        pivot_z = sz - 10;

        // Roller point is in groove
        roller_x = sx;
        roller_y = gy;
        roller_z = gz;

        // Calculate arm angle to reach from pivot to roller
        // Arm is built with pivot at origin, roller at +Y
        // We need to rotate it so roller reaches groove

        dy = roller_y - pivot_y;
        dz = roller_z - pivot_z;
        arm_angle = atan2(dz, dy);

        translate([pivot_x, pivot_y, pivot_z])
        rotate([0, 90, 0])           // Pivot axis along X
        rotate([0, 0, arm_angle])    // Swing arm to point at groove
        rotate([0, -90, 0])          // Bring back to Y-Z plane
        translate([0, 0, -ARM_THICKNESS/2])  // Center on pivot
        color(C_ARM)
            follower_arm();

        // Visualize roller bearing at groove
        if (SHOW_BEARINGS) {
            %translate([sx, gy, gz])
            rotate([0, 90, 0])
                cylinder(d=BEARING_624_OD, h=BEARING_624_H, center=true, $fn=24);
        }
    }
}

// ============================================
// HELPER MODULES
// ============================================

module groove_visualization() {
    // Show groove centerline
    color([1, 0, 0, 0.5])
    for (x = [-WORM_LENGTH/2 : 10 : WORM_LENGTH/2]) {
        gy = groove_y(x, theta);
        gz = groove_z(x, theta);
        translate([x, gy, gz])
            sphere(d=4, $fn=8);
    }
}

// Slat color gradient
function slat_color(i) =
    let(t = 1 - i / (NUM_SLATS - 1))
    [0.15 + 0.35*t, 0.35 + 0.30*t, 0.55 + 0.35*t];

// ============================================
// RENDER
// ============================================

assembly();

// ============================================
// INFO
// ============================================

echo("=== WAVE OCEAN V10 - ASSEMBLY ===");
echo(str("Theta: ", theta, "°"));
echo(str("Worm center Z: ", WORM_CENTER_Z, "mm"));
echo(str("Guide Z: ", GUIDE_Z, "mm"));
echo(str("Groove radius: ", GROOVE_RADIUS, "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=120");
