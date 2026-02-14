/*
 * BARREL CAM - Y-Axis Rotation, Helical Ridge
 *
 * This cam creates a traveling wave when rotated around Y-axis.
 * The helical ridge spirals along the cam body.
 *
 * COORDINATE CONVENTION:
 * - Cam body extends along X (180mm)
 * - Shaft is along Y-axis (through cam center)
 * - When theta=0, the ridge peak faces +Z at X=0
 * - As theta increases, the peak at X=0 rotates around Y
 * - The helix means adjacent X positions have offset phase
 *
 * MATCHING slat_z() IN common.scad:
 * cam_surface_z(x, layer, theta) uses:
 *   helix_angle = (x/CAM_LENGTH + 0.5) * 360 * HELIX_TURNS
 *   effective_angle = theta - helix_angle
 *   surface = CORE + ridge * (0.5 + 0.5 * cos(effective_angle))
 *
 * When effective_angle = 0, surface is maximum (peak).
 * This happens when theta = helix_angle.
 * At X=0, helix_angle = 180° (for 2 turns).
 * So at theta=180°, the peak should face +Z at X=0.
 */

include <../common.scad>

// ============================================
// BARREL CAM MODULE
// ============================================

module barrel_cam(layer = 0) {
    ridge_height = LAYER_RIDGE_HEIGHT[layer];

    difference() {
        // Cam body with helical surface
        helical_barrel(ridge_height);

        // Shaft hole (along Y-axis, through center)
        shaft_hole();
    }
}

// ============================================
// HELICAL BARREL SURFACE
// ============================================

module helical_barrel(ridge_height) {
    // Build the cam from thin slices along X
    // Each slice is a disk whose radius varies around its circumference

    slices = 90;
    dx = CAM_LENGTH / slices;

    for (i = [0 : slices - 1]) {
        x = -CAM_LENGTH/2 + i * dx;

        hull() {
            translate([x, 0, 0])
                cam_slice(x, ridge_height);
            translate([x + dx, 0, 0])
                cam_slice(x + dx, ridge_height);
        }
    }
}

// ============================================
// SINGLE CAM SLICE
// ============================================

module cam_slice(x, ridge_height) {
    // Helix angle at this X position (from common.scad formula)
    helix_angle = ((x / CAM_LENGTH) + 0.5) * 360 * HELIX_TURNS;

    // Create the 2D profile and extrude it thin along Y
    // The profile is in the X-Z plane at this X position

    // We need to orient the 2D profile so that:
    // - When theta=0 in the assembly, the cam is at its "home" position
    // - The profile's "peak" should be at the correct angle

    // The 2D profile is created in the X-Y plane of the polygon
    // We'll rotate it to align properly

    translate([0, -0.25, 0])  // Center the thin slice on Y=0
    rotate([90, 0, 0])         // Flip so profile is in X-Z plane
    linear_extrude(height = 0.5)
        cam_profile_2d(helix_angle, ridge_height);
}

// ============================================
// 2D CAM PROFILE
// ============================================

module cam_profile_2d(helix_angle, ridge_height) {
    // Create a polar profile in X-Y coordinates
    // After rotate([90, 0, 0]), this becomes X-Z plane
    //
    // angle=0 → +X direction (right)
    // angle=90 → +Y direction → becomes +Z after rotation (up)
    //
    // To match slat_z formula:
    // When assembly rotates cam by theta, slat sees:
    //   effective_angle = theta - helix_angle
    //   peak when effective_angle = 0, i.e., theta = helix_angle
    //
    // In the static (theta=0) cam, we want peak at angle = helix_angle
    // So it faces the direction where, when theta=helix_angle later,
    // the peak will face +Z.
    //
    // If we rotate the whole cam by theta around Y-axis (global),
    // and the profile peak is at local angle = helix_angle,
    // then the peak faces +Z when theta = helix_angle.
    //
    // Wait, let me think again...
    // In the 2D profile, angle=90 faces +Z (after the rotate).
    // If helix_angle=180 at X=0, we want peak at angle=90+180=270 (or -90)
    // when theta=0, so that when theta=180, it rotates to face +Z.
    //
    // General: peak at angle = (90 - helix_angle)
    // But wait, that means peak direction rotates OPPOSITE to helix_angle.
    //
    // Actually simpler: the peak should be at angle=90 (up direction)
    // offset by helix_angle. So peak is at angle = 90 - helix_angle.
    //
    // No wait, I'm overcomplicating this. Let's just match the math:
    // cos(angle - helix_angle) is maximum when angle = helix_angle.
    // We want maximum radius (peak) at angle = helix_angle in the profile.
    // After rotate([90,0,0]), +Y becomes +Z.
    // So angle=90 in 2D → +Y → +Z direction.
    //
    // If helix_angle = H, peak is at angle = H in 2D.
    // After rotation, that direction is:
    //   - angle=0 → +X (stays +X)
    //   - angle=90 → +Y → +Z
    //   - angle=180 → -X
    //   - angle=270 → -Y → -Z
    //
    // So peak at angle=H means it points at angle H in the X-Z plane.
    // When we rotate the cam around Y by theta, the peak direction
    // rotates by theta. We want peak to face +Z when theta=H.
    // Peak starts at angle H, so after rotating by theta, it's at angle H+theta.
    // Peak faces +Z when H+theta = 90, i.e., theta = 90-H.
    //
    // But slat_z expects peak at theta=H, not theta=90-H.
    // So there's a 90° offset issue.
    //
    // Let me fix by putting peak at angle = 90 - helix_angle.
    // Then peak is at angle (90-H)+theta after rotation by theta.
    // Peak faces +Z (angle=90) when (90-H)+theta = 90, i.e., theta=H. ✓

    steps = 72;
    points = [
        for (a = [0 : steps - 1])
            let(
                angle = a * 360 / steps,
                // Peak at angle = (90 - helix_angle)
                // cos is max when angle = 90 - helix_angle
                wave = 0.5 + 0.5 * cos(angle - (90 - helix_angle)),
                r = CAM_CORE_RADIUS + ridge_height * wave
            )
            [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// ============================================
// SHAFT HOLE (along Y-axis)
// ============================================

module shaft_hole() {
    translate([0, -CAM_WIDTH/2 - 5, 0])
    rotate([-90, 0, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_WIDTH + 10, $fn = 24);
}

// ============================================
// RENDER - Show all 3 cams (static preview)
// ============================================

for (L = [0 : NUM_LAYERS - 1]) {
    translate([0, LAYER_Y[L], 0])
    color(C_CAM)
        barrel_cam(L);
}

// Ghost shaft
%rotate([-90, 0, 0])
    cylinder(d = SHAFT_DIA, h = 100, center = true, $fn = 24);

// ============================================
// INFO
// ============================================

echo("=== BARREL CAM ===");
echo(str("Length (X): ", CAM_LENGTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("Ridge heights: ", LAYER_RIDGE_HEIGHT));
echo(str("Helix turns: ", HELIX_TURNS));
echo("");
echo("Shaft axis: Y");
echo("Rotation around Y creates traveling wave along X");
