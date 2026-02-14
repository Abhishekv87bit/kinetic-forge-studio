/*
 * WAVE OCEAN V10 - HELICAL CAM V2 - REAL GROOVE GEOMETRY
 *
 * Proper helical groove cam - not spheres!
 * Groove is a channel cut into a cylinder following sinusoidal helix path
 * Follower pins ride IN the groove (positive engagement)
 */

$fn = 64;

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_WORM = true;
SHOW_SHAFT = true;
SHOW_SLATS = true;
SHOW_FOLLOWERS = true;
SHOW_FRAME = false;
SHOW_BEARINGS = false;

// Debug
SHOW_GROOVE_PATH = false;    // Red line showing groove center
CROSS_SECTION = false;       // Cut worm in half to see groove

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// WORM PARAMETERS
// ============================================

WORM_LENGTH = 200;
WORM_RADIUS = 14;            // Outer radius of cylinder
WORM_CORE_RADIUS = 6;        // Inner shaft area

// Groove cut into the surface
GROOVE_WIDTH = 5;            // Width of channel
GROOVE_DEPTH = 5;            // How deep into cylinder

// Wave motion
WAVE_AMPLITUDE = 8;          // Vertical motion range
HELIX_PITCH = 25;            // mm per full rotation (wavelength)

// Shaft
SHAFT_DIA = 5;
SHAFT_LENGTH = WORM_LENGTH + 50;

// Position
WORM_X = 0;
WORM_Y = 0;
WORM_Z = WORM_RADIUS + 10;

// ============================================
// SLAT PARAMETERS
// ============================================

NUM_SLATS = 24;
SLAT_SPACING = WORM_LENGTH / NUM_SLATS;

SLAT_WIDTH = 3;
SLAT_DEPTH = 35;
SLAT_HEIGHT = 45;

FOLLOWER_DIA = 4;
FOLLOWER_LENGTH = 10;

// ============================================
// COLORS
// ============================================

C_WORM = [0.75, 0.55, 0.2];
C_SHAFT = [0.5, 0.5, 0.55];
C_FOLLOWER = [0.45, 0.45, 0.5];
C_FRAME = [0.3, 0.3, 0.35];

function slat_color(i) =
    let(t = 1 - i / (NUM_SLATS - 1))
    [0.15 + 0.35*t, 0.35 + 0.30*t, 0.55 + 0.35*t];

// ============================================
// KINEMATICS
// ============================================

// Helix angle at position x along worm
function helix_angle_at_x(x) = (x / HELIX_PITCH) * 360;

// Groove center Z position (sinusoidal wave)
function groove_z(x) =
    let(angle = helix_angle_at_x(x) - theta)
    WORM_Z + WAVE_AMPLITUDE * sin(angle);

// Slat positions
function slat_x(i) = i * SLAT_SPACING - WORM_LENGTH/2 + SLAT_SPACING/2;
function slat_z(i) = groove_z(slat_x(i)) + GROOVE_DEPTH/2 + FOLLOWER_DIA/2;

// ============================================
// HELICAL GROOVE CAM - REAL GEOMETRY
// ============================================

// The groove follows a SINUSOIDAL HELIX:
// - Wraps around cylinder (helix)
// - BUT the radius varies sinusoidally (creates up/down motion)
//
// We build this by sweeping a groove profile along the helix path

module helix_groove_cam() {
    // Parameters for groove path
    turns = WORM_LENGTH / HELIX_PITCH;
    steps_per_turn = 36;
    total_steps = ceil(turns * steps_per_turn);
    step_length = WORM_LENGTH / total_steps;

    color(C_WORM)
    difference() {
        // Solid cylinder (worm body)
        translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(r=WORM_RADIUS, h=WORM_LENGTH);

        // Carve out the helical groove
        // Groove follows sinusoidal path around cylinder
        for (i = [0 : total_steps - 1]) {
            x = -WORM_LENGTH/2 + i * step_length;
            angle = helix_angle_at_x(x) - theta;

            // Groove position on cylinder surface
            // The "radius" where groove sits varies sinusoidally
            groove_r = WORM_RADIUS - GROOVE_DEPTH/2;

            // Groove center position in world coords
            // Angle around cylinder = helix angle
            // Height offset = sinusoidal
            wave_offset = WAVE_AMPLITUDE * sin(angle);

            // Position groove segment
            translate([x + step_length/2, WORM_Y, WORM_Z])
            rotate([0, 90, 0])
            rotate([0, 0, angle])
            translate([groove_r, 0, 0])
            // Groove cross-section (cylinder segment)
                cylinder(d=GROOVE_WIDTH, h=step_length + 1, center=true, $fn=16);
        }

        // Shaft hole through center
        translate([-WORM_LENGTH/2 - 5, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(d=SHAFT_DIA + 0.5, h=WORM_LENGTH + 10);
    }
}

// Alternative: Build groove as a swept solid path
// This creates the groove walls explicitly
module helix_groove_cam_v2() {
    turns = WORM_LENGTH / HELIX_PITCH;
    steps = ceil(turns * 48);
    step_len = WORM_LENGTH / steps;

    color(C_WORM)
    difference() {
        // Main cylinder
        translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(r=WORM_RADIUS, h=WORM_LENGTH);

        // Groove channel - hull between consecutive groove positions
        for (i = [0 : steps - 1]) {
            x1 = -WORM_LENGTH/2 + i * step_len;
            x2 = x1 + step_len;

            angle1 = helix_angle_at_x(x1) - theta;
            angle2 = helix_angle_at_x(x2) - theta;

            wave1 = WAVE_AMPLITUDE * sin(angle1);
            wave2 = WAVE_AMPLITUDE * sin(angle2);

            groove_r = WORM_RADIUS - GROOVE_DEPTH/2;

            // Groove center positions
            gy1 = WORM_Y + groove_r * sin(angle1);
            gz1 = WORM_Z + groove_r * cos(angle1) + wave1 * 0.15;

            gy2 = WORM_Y + groove_r * sin(angle2);
            gz2 = WORM_Z + groove_r * cos(angle2) + wave2 * 0.15;

            hull() {
                translate([x1, gy1, gz1])
                    sphere(d=GROOVE_WIDTH, $fn=12);
                translate([x2, gy2, gz2])
                    sphere(d=GROOVE_WIDTH, $fn=12);
            }
        }

        // Shaft hole
        translate([-WORM_LENGTH/2 - 5, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(d=SHAFT_DIA + 0.5, h=WORM_LENGTH + 10);
    }
}

// Simplest approach: Cylindrical cam with sinusoidal surface profile
// The "groove" is the wavy surface itself - follower rides on TOP
module sinusoidal_surface_cam() {
    steps = 120;
    step_len = WORM_LENGTH / steps;

    color(C_WORM)
    union() {
        // Core cylinder
        translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(r=WORM_CORE_RADIUS, h=WORM_LENGTH);

        // Wavy surface built from stacked profiles
        for (i = [0 : steps - 1]) {
            x = -WORM_LENGTH/2 + i * step_len;
            angle = helix_angle_at_x(x) - theta;
            wave = WAVE_AMPLITUDE * sin(angle);

            // This slice's profile - cylinder with offset center
            translate([x, WORM_Y, WORM_Z + wave * 0.5])
            rotate([0, 90, 0])
            difference() {
                cylinder(r=WORM_RADIUS - 2, h=step_len + 0.5, $fn=32);
                // Cut groove channel
                rotate([0, 0, angle])
                translate([WORM_RADIUS - GROOVE_DEPTH, 0, -1])
                    cylinder(d=GROOVE_WIDTH, h=step_len + 2, $fn=16);
            }
        }
    }

    // Shaft hole
    color(C_WORM)
    difference() {
        translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(r=WORM_CORE_RADIUS, h=WORM_LENGTH);

        translate([-WORM_LENGTH/2 - 5, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(d=SHAFT_DIA + 0.5, h=WORM_LENGTH + 10);
    }
}

// BEST VERSION: True helical groove with walls
module helical_groove_cam_final() {
    wall_thickness = 2;  // Groove wall thickness

    color(C_WORM)
    difference() {
        union() {
            // Core cylinder
            translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
            rotate([0, 90, 0])
                cylinder(r=WORM_CORE_RADIUS + 2, h=WORM_LENGTH);

            // Helical thread (groove walls)
            // Two parallel helices forming the groove channel
            for (wall = [-1, 1]) {  // Two walls
                for (x = [-WORM_LENGTH/2 : 2 : WORM_LENGTH/2 - 2]) {
                    angle = helix_angle_at_x(x) - theta;
                    wave = WAVE_AMPLITUDE * sin(angle);

                    // Wall position (offset from groove center)
                    wall_angle = angle + wall * (GROOVE_WIDTH/2) / WORM_RADIUS * 180 / PI;

                    translate([x + 1, WORM_Y, WORM_Z])
                    rotate([0, 90, 0])
                    rotate([0, 0, wall_angle])
                    translate([WORM_CORE_RADIUS + 2 + wave * 0.1, 0, 0])
                    // Thread tooth
                    cylinder(d=wall_thickness * 2, h=2, center=true, $fn=12);
                }
            }
        }

        // Shaft hole
        translate([-WORM_LENGTH/2 - 5, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(d=SHAFT_DIA + 0.5, h=WORM_LENGTH + 10);
    }
}

// ============================================
// SHAFT
// ============================================

module shaft() {
    color(C_SHAFT)
    translate([-SHAFT_LENGTH/2, WORM_Y, WORM_Z])
    rotate([0, 90, 0])
        cylinder(d=SHAFT_DIA, h=SHAFT_LENGTH);
}

// ============================================
// GROOVE PATH DEBUG
// ============================================

module groove_path_debug() {
    for (x = [-WORM_LENGTH/2 : 3 : WORM_LENGTH/2]) {
        angle = helix_angle_at_x(x) - theta;
        groove_r = WORM_RADIUS - GROOVE_DEPTH/2;

        gy = WORM_Y + groove_r * sin(angle);
        gz = WORM_Z + groove_r * cos(angle);

        color([1, 0, 0])
        translate([x, gy, gz])
            sphere(d=1.5, $fn=8);
    }
}

// ============================================
// SLATS AND FOLLOWERS
// ============================================

module single_slat(i) {
    sx = slat_x(i);
    sz = slat_z(i);

    // Slat body
    color(slat_color(i))
    translate([sx - SLAT_WIDTH/2, -SLAT_DEPTH/2, sz])
        cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT]);

    // Rounded top
    color(slat_color(i))
    translate([sx, 0, sz + SLAT_HEIGHT])
    rotate([90, 0, 0])
        cylinder(d=SLAT_WIDTH, h=SLAT_DEPTH, center=true, $fn=12);
}

module single_follower(i) {
    sx = slat_x(i);
    sz = slat_z(i);
    angle = helix_angle_at_x(sx) - theta;

    // Follower pin position (in groove)
    groove_r = WORM_RADIUS - GROOVE_DEPTH/2;
    fy = WORM_Y + groove_r * sin(angle);
    fz = WORM_Z + groove_r * cos(angle);

    // Pin oriented tangent to groove
    color(C_FOLLOWER)
    translate([sx, fy, fz])
    rotate([angle, 0, 0])
    rotate([0, 90, 0])
        cylinder(d=FOLLOWER_DIA, h=FOLLOWER_LENGTH, center=true);

    // Connection to slat
    color(C_FOLLOWER)
    hull() {
        translate([sx, fy, fz])
            sphere(d=FOLLOWER_DIA, $fn=12);
        translate([sx, 0, sz])
            cube([SLAT_WIDTH, 4, 4], center=true);
    }
}

module all_slats() {
    for (i = [0:NUM_SLATS-1]) {
        single_slat(i);
    }
}

module all_followers() {
    for (i = [0:NUM_SLATS-1]) {
        single_follower(i);
    }
}

// ============================================
// FRAME (minimal)
// ============================================

module frame_base() {
    color(C_FRAME)
    translate([-WORM_LENGTH/2 - 20, -15, 0])
        cube([WORM_LENGTH + 40, 30, 5]);
}

module bearings() {
    bearing_h = WORM_Z - 5;

    color(C_FRAME) {
        // Left
        translate([-WORM_LENGTH/2 - 15, -10, 5])
        difference() {
            cube([15, 20, bearing_h]);
            translate([7.5, 10, bearing_h])
            rotate([0, 90, 0])
                cylinder(d=SHAFT_DIA + 1, h=20, center=true);
        }

        // Right
        translate([WORM_LENGTH/2, -10, 5])
        difference() {
            cube([15, 20, bearing_h]);
            translate([7.5, 10, bearing_h])
            rotate([0, 90, 0])
                cylinder(d=SHAFT_DIA + 1, h=20, center=true);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_helix_v2() {
    if (SHOW_FRAME) frame_base();
    if (SHOW_BEARINGS) bearings();
    if (SHOW_SHAFT) shaft();

    if (SHOW_WORM) {
        if (CROSS_SECTION) {
            difference() {
                helix_groove_cam_v2();
                translate([-150, 0, -50])
                    cube([300, 100, 150]);
            }
        } else {
            helix_groove_cam_v2();
        }
    }

    if (SHOW_SLATS) all_slats();
    if (SHOW_FOLLOWERS) all_followers();
    if (SHOW_GROOVE_PATH) groove_path_debug();
}

// ============================================
// RENDER
// ============================================

wave_ocean_v10_helix_v2();

// ============================================
// DEBUG
// ============================================

echo("=== WAVE OCEAN V10 - HELIX V2 (REAL GROOVE) ===");
echo(str("Worm radius: ", WORM_RADIUS, "mm"));
echo(str("Groove width: ", GROOVE_WIDTH, "mm"));
echo(str("Groove depth: ", GROOVE_DEPTH, "mm"));
echo(str("Wave amplitude: ", WAVE_AMPLITUDE, "mm"));
echo(str("Helix pitch: ", HELIX_PITCH, "mm"));
echo(str("Slats: ", NUM_SLATS));
echo("");
echo("Toggle CROSS_SECTION = true to see groove cut view");
echo("Toggle SHOW_GROOVE_PATH = true to see groove centerline");
