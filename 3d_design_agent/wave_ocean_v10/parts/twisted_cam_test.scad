/*
 * TWISTED CAM TEST - Helical Ridge Surface
 *
 * A cylinder with a helical ridge/bulge that spirals around it.
 * Slats rest on top, lifted by the passing ridge.
 * Creates traveling wave as ridge passes each slat.
 *
 * Animation: View -> Animate, FPS=30, Steps=120
 */

$fn = 64;

// ============================================
// PARAMETERS
// ============================================

// Worm dimensions
WORM_LENGTH = 200;
WORM_CORE_RADIUS = 10;       // Core cylinder
RIDGE_HEIGHT = 12;            // How much ridge sticks out
RIDGE_WIDTH_ANGLE = 60;       // Angular width of ridge (degrees)
HELIX_TURNS = 2;              // Number of spiral turns along length

// Slat dimensions
NUM_SLATS = 20;
SLAT_WIDTH = 6;
SLAT_DEPTH = 25;
SLAT_HEIGHT = 40;
SLAT_SPACING = WORM_LENGTH / (NUM_SLATS - 1);

// Animation
theta = $t * 360;

// ============================================
// TWISTED CAM (Helical Ridge)
// ============================================

module twisted_cam() {
    // Core cylinder
    rotate([0, 90, 0])
        cylinder(r = WORM_CORE_RADIUS, h = WORM_LENGTH, center=true);

    // Helical ridge - swept along helix path
    helical_ridge();
}

module helical_ridge() {
    // Create ridge as series of positioned segments
    segments = 200;
    dx = WORM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -WORM_LENGTH/2 + i * dx;

        // Helix angle at this X position
        helix_angle = (i / segments) * 360 * HELIX_TURNS;

        // Ridge cross-section at this position
        translate([x, 0, 0])
        rotate([helix_angle, 0, 0])  // Rotate around X to follow helix
        translate([0, WORM_CORE_RADIUS, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            ridge_profile();
    }
}

module ridge_profile() {
    // Smooth bump profile
    hull() {
        circle(r = 0.5);  // Base
        translate([0, RIDGE_HEIGHT * 0.8, 0])
            circle(r = 4);  // Top of ridge
    }
}

// ============================================
// ALTERNATIVE: Smooth sinusoidal twisted surface
// ============================================

module twisted_cam_smooth() {
    segments_along = 100;
    segments_around = 48;

    dx = WORM_LENGTH / segments_along;

    for (i = [0 : segments_along - 1]) {
        x = -WORM_LENGTH/2 + i * dx;
        helix_phase = (i / segments_along) * 360 * HELIX_TURNS;

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            twisted_profile(helix_phase);
    }
}

module twisted_profile(phase) {
    // Cross-section with ONE sinusoidal bulge that rotates around
    points = [for (a = [0 : 360/48 : 359])
        let(
            // Single smooth bulge
            bulge = RIDGE_HEIGHT * max(0, cos(a - phase - 90))
        )
        let(r = WORM_CORE_RADIUS + bulge)
        [r * cos(a), r * sin(a)]
    ];
    polygon(points);
}

// ============================================
// SLAT HEIGHT CALCULATION
// ============================================

function ridge_z(x, cam_angle) =
    // At position X, where is the top of the cam surface?
    let(helix_phase = ((x + WORM_LENGTH/2) / WORM_LENGTH) * 360 * HELIX_TURNS)
    let(local_angle = helix_phase + cam_angle)
    let(bulge = RIDGE_HEIGHT * max(0, cos(local_angle - 90)))
    WORM_CORE_RADIUS + bulge;

// ============================================
// SIMPLE SLAT
// ============================================

module simple_slat() {
    // Wave crest shape
    hull() {
        translate([-SLAT_WIDTH/2, -SLAT_DEPTH/2, 0])
            cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT - 8]);

        translate([0, 0, SLAT_HEIGHT])
        scale([1, 0.5, 1.5])
            sphere(d = SLAT_WIDTH);
    }
}

// ============================================
// MINIMAL GUIDE RAIL
// ============================================

module minimal_guide() {
    // Thin vertical slots - barely visible
    guide_height = 50;
    guide_thickness = 3;

    color([0.3, 0.3, 0.3, 0.3])
    difference() {
        // Thin bar
        translate([-WORM_LENGTH/2 - 10, SLAT_DEPTH/2 + 2, 15])
            cube([WORM_LENGTH + 20, guide_thickness, guide_height]);

        // Slots for slats
        for (i = [0 : NUM_SLATS - 1]) {
            x = -WORM_LENGTH/2 + i * SLAT_SPACING;
            translate([x, SLAT_DEPTH/2, 10])
                cube([SLAT_WIDTH + 1, guide_thickness + 2, guide_height + 20], center=true);
        }
    }
}

// ============================================
// ASSEMBLY
// ============================================

module assembly() {
    // Twisted cam (rotates around X axis)
    color([0.6, 0.4, 0.2])
    rotate([theta, 0, 0])
        twisted_cam_smooth();

    // Slats
    for (i = [0 : NUM_SLATS - 1]) {
        x = -WORM_LENGTH/2 + i * SLAT_SPACING;
        sz = ridge_z(x, theta);

        // Ocean blue gradient
        t = i / (NUM_SLATS - 1);
        c = [0.1 + 0.2*t, 0.3 + 0.3*t, 0.5 + 0.4*t];

        translate([x, 0, sz])
        color(c)
            simple_slat();
    }

    // Minimal front guide
    minimal_guide();

    // Back guide (mirror)
    mirror([0, 1, 0])
        minimal_guide();

    // Shaft
    color([0.5, 0.5, 0.5])
    rotate([0, 90, 0])
        cylinder(d = 8, h = WORM_LENGTH + 40, center=true);
}

assembly();

echo("=== TWISTED CAM TEST ===");
echo("Single helical ridge creates traveling wave");
echo("Animate: View -> Animate, FPS=30, Steps=120");
