/*
 * BARREL CAM TEST - Sinusoidal Surface Worm
 *
 * The worm surface itself IS the wave profile.
 * Slats rest on top, pushed up by high spots.
 * No groove, no follower arms needed.
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 */

$fn = 64;

// ============================================
// PARAMETERS
// ============================================

// Worm dimensions
WORM_LENGTH = 200;
WORM_BASE_RADIUS = 12;      // Minimum radius (valleys)
WAVE_AMPLITUDE = 8;          // How much radius varies (+/-)
NUM_WAVES = 3;               // Number of sine waves around circumference

// Slat dimensions
NUM_SLATS = 20;
SLAT_WIDTH = 6;
SLAT_DEPTH = 25;
SLAT_HEIGHT = 35;
SLAT_SPACING = WORM_LENGTH / (NUM_SLATS - 1);

// Animation
theta = $t * 360;

// ============================================
// SINUSOIDAL BARREL CAM
// ============================================

module barrel_cam() {
    // The surface radius varies sinusoidally around circumference
    // AND has a helical twist along length

    segments_around = 72;
    segments_along = 100;

    dx = WORM_LENGTH / segments_along;

    for (i = [0 : segments_along - 1]) {
        x = -WORM_LENGTH/2 + i * dx;

        // Phase shift along length creates helix
        phase = (x / WORM_LENGTH) * 360 * 2;  // 2 full twists

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            sinusoidal_profile(phase);
    }
}

module sinusoidal_profile(phase) {
    // Cross-section with sinusoidal radius variation
    points = [for (a = [0 : 360/72 : 359])
        let(r = WORM_BASE_RADIUS + WAVE_AMPLITUDE * sin(NUM_WAVES * a + phase))
        [r * cos(a), r * sin(a)]
    ];
    polygon(points);
}

// ============================================
// SIMPLE SLAT (rides on top)
// ============================================

module simple_slat() {
    // Tapered wave shape
    hull() {
        translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT - 10]);

        // Rounded top
        translate([0, 0, SLAT_HEIGHT])
        scale([1, 0.6, 1.5])
            sphere(d = SLAT_WIDTH);
    }

    // Curved bottom to nest on cam
    translate([0, 0, -3])
    difference() {
        translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_WIDTH, SLAT_DEPTH, 5]);

        // Concave to match cam surface
        translate([0, 0, 8])
        rotate([90, 0, 0])
            cylinder(r = WORM_BASE_RADIUS + 2, h = SLAT_DEPTH + 2, center=true);
    }
}

// ============================================
// CALCULATE SLAT HEIGHT
// ============================================

function cam_surface_z(x, angle) =
    // At position X along cam, with cam rotated by angle,
    // what's the highest point of the surface at Y=0?
    let(phase = (x / WORM_LENGTH) * 360 * 2 + angle)
    WORM_BASE_RADIUS + WAVE_AMPLITUDE * sin(NUM_WAVES * 0 + phase);

// Actually for a multi-lobed cam, we need the TOP of the surface
// At Y=0, we're looking at where angle=90° on the profile
function slat_z_on_cam(x, cam_angle) =
    let(helix_phase = (x / WORM_LENGTH) * 360 * 2)
    let(surface_angle = 90)  // Top of cam (Y=0, Z positive)
    let(r = WORM_BASE_RADIUS + WAVE_AMPLITUDE * sin(NUM_WAVES * surface_angle + helix_phase + cam_angle))
    r;

// ============================================
// ASSEMBLY
// ============================================

module assembly() {
    // Cam (rotates around X axis)
    color([0.6, 0.4, 0.2])
    rotate([theta, 0, 0])
        barrel_cam();

    // Slats (ride on top)
    for (i = [0 : NUM_SLATS - 1]) {
        x = -WORM_LENGTH/2 + i * SLAT_SPACING;
        sz = slat_z_on_cam(x, theta);

        // Color gradient blue
        c = [0.2, 0.3 + 0.4 * i/NUM_SLATS, 0.6 + 0.3 * i/NUM_SLATS];

        translate([x, 0, sz])
        color(c)
            simple_slat();
    }

    // Shaft
    color([0.5, 0.5, 0.5])
    rotate([0, 90, 0])
        cylinder(d = 8, h = WORM_LENGTH + 40, center=true);
}

assembly();

echo("=== BARREL CAM TEST ===");
echo("Animate: View -> Animate, FPS=30, Steps=120");
echo(str("Slats ride on cam surface - no follower arms"));
