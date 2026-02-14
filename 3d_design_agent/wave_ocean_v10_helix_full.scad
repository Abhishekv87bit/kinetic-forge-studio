/*
 * WAVE OCEAN V10 - HELICAL CAM - FULL DETAIL BUILD
 *
 * REAL BUILDABLE MECHANISM - COMPLETE GEOMETRY
 *
 * Concept:
 *   - Single helical cam (worm) with sinusoidal groove
 *   - Slats with follower pins ride in groove
 *   - Groove = positive engagement both directions
 *   - Frame is UNDERNEATH, not around - clear view of waves
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   Wave travels RIGHT to LEFT
 */

$fn = 48;

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_WORM = true;            // Helical cam
SHOW_WORM_SHAFT = true;      // Central shaft
SHOW_SLATS = true;           // Wave slats
SHOW_FOLLOWERS = true;       // Follower pins
SHOW_GUIDE_RAILS = false;    // Guide rails (behind slats)
SHOW_FRAME = false;          // Base frame (underneath)
SHOW_BEARINGS = false;       // Bearing blocks
SHOW_MOTOR = false;          // Motor placeholder

SHOW_GROOVE_PATH = false;    // Debug: groove centerline
SHOW_SECTION_CUT = false;    // Debug: cut view of worm

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;           // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// WORM CAM PARAMETERS
// ============================================

WORM_LENGTH = 200;           // Total X length
WORM_CORE_RADIUS = 8;        // Inner cylinder radius
WORM_OUTER_RADIUS = 16;      // Outer radius at thread peaks

// Groove channel
GROOVE_WIDTH = 5;            // Channel width (follower rides here)
GROOVE_DEPTH = 4;            // How deep groove cuts into thread

// Sinusoidal amplitude of groove position (creates wave motion)
WAVE_AMPLITUDE = 8;          // mm vertical motion of groove center

// Helix
HELIX_PITCH = 25;            // mm per 360° rotation
THREAD_ANGLE = atan(HELIX_PITCH / (2 * PI * WORM_OUTER_RADIUS));

// Shaft
WORM_SHAFT_DIA = 6;
WORM_SHAFT_LENGTH = WORM_LENGTH + 40;

// Position
WORM_Y = 0;
WORM_Z = WORM_OUTER_RADIUS + 15;  // Elevated above base

// ============================================
// SLAT PARAMETERS
// ============================================

NUM_SLATS = 24;
SLAT_SPACING = WORM_LENGTH / NUM_SLATS;

SLAT_WIDTH = 3;              // X (thin)
SLAT_DEPTH = 35;             // Y (toward viewer)
SLAT_HEIGHT = 40;            // Z (above worm)

// Follower
FOLLOWER_DIA = 4;            // Rides in groove
FOLLOWER_LENGTH = 8;

// ============================================
// FRAME (underneath, minimal)
// ============================================

FRAME_WIDTH = WORM_LENGTH + 50;
FRAME_DEPTH = 30;
FRAME_HEIGHT = 5;
FRAME_Z = 0;

BEARING_SIZE = 20;

// ============================================
// COLORS
// ============================================

C_WORM_CORE = [0.7, 0.5, 0.2];
C_WORM_THREAD = [0.8, 0.6, 0.25];
C_SHAFT = [0.55, 0.55, 0.6];
C_FOLLOWER = [0.5, 0.5, 0.55];
C_FRAME = [0.25, 0.25, 0.3];
C_GUIDE = [0.3, 0.3, 0.35];
C_BEARING = [0.4, 0.35, 0.3];
C_MOTOR = [0.3, 0.3, 0.35];

// Slat color gradient (ocean: right=deep, left=light foam)
function slat_color(i) =
    let(t = 1 - i / (NUM_SLATS - 1))  // Invert so left is light
    [0.15 + 0.35 * t, 0.35 + 0.30 * t, 0.55 + 0.35 * t];

// ============================================
// KINEMATICS
// ============================================

// Phase at position X along worm (based on helix)
function helix_phase_at_x(x) = (x / HELIX_PITCH) * 360;

// Groove center Z at position X (sinusoidal variation)
function groove_z_at_x(x) =
    let(phase = helix_phase_at_x(x) - theta)
    WORM_Z + WAVE_AMPLITUDE * sin(phase);

// Groove center Y at position X (follows helix around cylinder)
function groove_y_at_x(x) =
    let(
        phase = helix_phase_at_x(x) - theta,
        radius = WORM_CORE_RADIUS + (WORM_OUTER_RADIUS - WORM_CORE_RADIUS) / 2
    )
    WORM_Y + radius * 0.3 * cos(phase);  // Slight Y wobble

// Slat position
function slat_x(i) = i * SLAT_SPACING - WORM_LENGTH / 2 + SLAT_SPACING / 2;
function slat_z(i) = groove_z_at_x(slat_x(i)) + FOLLOWER_DIA/2 + 2;

// ============================================
// WORM CAM - FULL GEOMETRY
// ============================================

// Single thread segment (cross-section extruded along helix)
module thread_segment(x_start, x_end) {
    steps = ceil((x_end - x_start) / 2);

    for (i = [0:steps-1]) {
        x1 = x_start + i * (x_end - x_start) / steps;
        x2 = x_start + (i + 1) * (x_end - x_start) / steps;

        phase1 = helix_phase_at_x(x1) - theta;
        phase2 = helix_phase_at_x(x2) - theta;

        // Thread profile at this position
        hull() {
            translate([x1, WORM_Y, WORM_Z])
            rotate([0, 90, 0])
            rotate([0, 0, phase1])
            translate([WORM_CORE_RADIUS + WAVE_AMPLITUDE * sin(phase1) * 0.3, 0, 0])
                cylinder(d=GROOVE_WIDTH + 4, h=0.5, center=true);

            translate([x2, WORM_Y, WORM_Z])
            rotate([0, 90, 0])
            rotate([0, 0, phase2])
            translate([WORM_CORE_RADIUS + WAVE_AMPLITUDE * sin(phase2) * 0.3, 0, 0])
                cylinder(d=GROOVE_WIDTH + 4, h=0.5, center=true);
        }
    }
}

// Complete worm with helical thread
module worm_cam() {
    // Core cylinder
    color(C_WORM_CORE)
    translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
    rotate([0, 90, 0])
        cylinder(r=WORM_CORE_RADIUS, h=WORM_LENGTH);

    // Helical thread with groove
    color(C_WORM_THREAD)
    difference() {
        // Thread body - series of lobes following helix
        union() {
            for (x = [-WORM_LENGTH/2 : 2 : WORM_LENGTH/2 - 2]) {
                phase = helix_phase_at_x(x) - theta;
                wave_offset = WAVE_AMPLITUDE * sin(phase);

                translate([x, WORM_Y, WORM_Z])
                rotate([0, 90, 0])
                rotate([0, 0, phase]) {
                    // Main lobe
                    translate([WORM_CORE_RADIUS + 3 + wave_offset * 0.2, 0, 0])
                    hull() {
                        cylinder(d=8, h=2, center=true);
                        translate([4, 0, 0])
                            cylinder(d=5, h=2, center=true);
                    }
                }
            }
        }

        // Groove channel (carved out)
        for (x = [-WORM_LENGTH/2 - 5 : 1.5 : WORM_LENGTH/2 + 5]) {
            phase = helix_phase_at_x(x) - theta;
            wave_offset = WAVE_AMPLITUDE * sin(phase);
            groove_radius = WORM_CORE_RADIUS + 5 + wave_offset * 0.2;

            translate([x, WORM_Y, WORM_Z])
            rotate([0, 90, 0])
            rotate([0, 0, phase])
            translate([groove_radius, 0, 0])
                cylinder(d=GROOVE_WIDTH, h=2, center=true, $fn=16);
        }
    }
}

// Alternative: Simplified worm (faster render)
module worm_cam_simple() {
    // Core
    color(C_WORM_CORE)
    translate([-WORM_LENGTH/2, WORM_Y, WORM_Z])
    rotate([0, 90, 0])
        cylinder(r=WORM_CORE_RADIUS, h=WORM_LENGTH);

    // Thread as connected spheres
    color(C_WORM_THREAD)
    for (x = [-WORM_LENGTH/2 : 3 : WORM_LENGTH/2]) {
        phase = helix_phase_at_x(x) - theta;
        wave_offset = WAVE_AMPLITUDE * sin(phase);

        translate([x, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
        rotate([0, 0, phase])
        translate([WORM_CORE_RADIUS + 4 + wave_offset * 0.15, 0, 0])
            sphere(d=7, $fn=16);
    }
}

// Worm shaft
module worm_shaft() {
    color(C_SHAFT)
    translate([-WORM_SHAFT_LENGTH/2, WORM_Y, WORM_Z])
    rotate([0, 90, 0])
        cylinder(d=WORM_SHAFT_DIA, h=WORM_SHAFT_LENGTH);
}

// Groove path visualization (debug)
module groove_path_debug() {
    color([1, 0, 0, 0.8])
    for (x = [-WORM_LENGTH/2 : 2 : WORM_LENGTH/2]) {
        gz = groove_z_at_x(x);
        gy = groove_y_at_x(x);
        translate([x, gy, gz])
            sphere(d=2, $fn=8);
    }
}

// ============================================
// SLATS AND FOLLOWERS
// ============================================

module single_slat(i) {
    sx = slat_x(i);
    sz = slat_z(i);

    // Main slat body
    color(slat_color(i))
    translate([sx - SLAT_WIDTH/2, -SLAT_DEPTH/2, sz])
        cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT]);

    // Rounded top (wave crest shape)
    color(slat_color(i))
    translate([sx, 0, sz + SLAT_HEIGHT])
    rotate([90, 0, 0])
    scale([1, 1.5, 1])
        cylinder(d=SLAT_WIDTH, h=SLAT_DEPTH, center=true, $fn=16);

    // Foam tip on front slats (optional visual)
    if (i < 4) {
        color([0.9, 0.95, 1.0, 0.8])
        translate([sx, -SLAT_DEPTH/2 + 3, sz + SLAT_HEIGHT + 2])
        scale([0.8, 0.5, 0.6])
            sphere(d=SLAT_WIDTH * 2, $fn=12);
    }
}

module single_follower(i) {
    sx = slat_x(i);
    sz = slat_z(i);

    // Follower pin
    color(C_FOLLOWER)
    translate([sx, WORM_Y, sz - FOLLOWER_DIA/2 - 2])
    rotate([90, 0, 0])
        cylinder(d=FOLLOWER_DIA, h=FOLLOWER_LENGTH, center=true);

    // Follower bracket (connects pin to slat)
    color(C_FOLLOWER)
    translate([sx - SLAT_WIDTH/2 - 0.5, -FOLLOWER_LENGTH/2 + 2, sz - 5])
        cube([SLAT_WIDTH + 1, 4, 5]);
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
// GUIDE RAILS (behind slats, minimal)
// ============================================

module guide_rails() {
    rail_z_bottom = WORM_Z + WORM_OUTER_RADIUS;
    rail_z_top = rail_z_bottom + SLAT_HEIGHT + 20;
    rail_height = rail_z_top - rail_z_bottom;

    // Back rail (behind worm, not visible from front)
    color(C_GUIDE)
    translate([-WORM_LENGTH/2, SLAT_DEPTH/2 + 5, rail_z_bottom])
    difference() {
        cube([WORM_LENGTH, 4, rail_height]);

        // Slots for slats
        for (i = [0:NUM_SLATS-1]) {
            slot_x = slat_x(i) + WORM_LENGTH/2 - 3;
            translate([slot_x, -1, -1])
                cube([6, 6, rail_height + 2]);
        }
    }
}

// ============================================
// FRAME (underneath only)
// ============================================

module frame_base() {
    // Minimal base - just two rails under the bearings
    color(C_FRAME)
    translate([-FRAME_WIDTH/2, -8, FRAME_Z])
        cube([FRAME_WIDTH, 16, FRAME_HEIGHT]);
}

module bearing_blocks() {
    bearing_z = FRAME_HEIGHT;
    bearing_height = WORM_Z - bearing_z;

    // Left bearing
    color(C_BEARING)
    translate([-WORM_LENGTH/2 - 15, -BEARING_SIZE/2, bearing_z])
    difference() {
        cube([BEARING_SIZE, BEARING_SIZE, bearing_height]);
        translate([BEARING_SIZE/2, BEARING_SIZE/2, bearing_height])
        rotate([0, 90, 0])
            cylinder(d=WORM_SHAFT_DIA + 1, h=BEARING_SIZE + 2, center=true);
    }

    // Right bearing
    color(C_BEARING)
    translate([WORM_LENGTH/2 - 5, -BEARING_SIZE/2, bearing_z])
    difference() {
        cube([BEARING_SIZE, BEARING_SIZE, bearing_height]);
        translate([BEARING_SIZE/2, BEARING_SIZE/2, bearing_height])
        rotate([0, 90, 0])
            cylinder(d=WORM_SHAFT_DIA + 1, h=BEARING_SIZE + 2, center=true);
    }
}

module motor_placeholder() {
    motor_x = WORM_LENGTH/2 + 25;

    color(C_MOTOR) {
        // Motor body
        translate([motor_x, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(d=20, h=30);

        // Coupling
        translate([WORM_LENGTH/2 + 10, WORM_Y, WORM_Z])
        rotate([0, 90, 0])
            cylinder(d=10, h=15);
    }
}

// ============================================
// SECTION CUT (debug)
// ============================================

module section_cut_view() {
    difference() {
        children();

        // Cut away front half
        translate([-WORM_LENGTH, -100, -10])
            cube([WORM_LENGTH * 2, 100, 200]);
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_helix_full() {
    // Frame and supports (underneath)
    if (SHOW_FRAME) frame_base();
    if (SHOW_BEARINGS) bearing_blocks();
    if (SHOW_MOTOR) motor_placeholder();

    // Worm mechanism
    if (SHOW_WORM_SHAFT) worm_shaft();
    if (SHOW_WORM) {
        if (SHOW_SECTION_CUT) {
            section_cut_view() worm_cam_simple();
        } else {
            worm_cam_simple();  // Use _simple for faster render
            // worm_cam();      // Use this for full detail (slow)
        }
    }

    // Wave elements
    if (SHOW_SLATS) all_slats();
    if (SHOW_FOLLOWERS) all_followers();

    // Guides (behind)
    if (SHOW_GUIDE_RAILS) guide_rails();

    // Debug
    if (SHOW_GROOVE_PATH) groove_path_debug();
}

// ============================================
// RENDER
// ============================================

wave_ocean_v10_helix_full();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("=== WAVE OCEAN V10 - HELIX FULL DETAIL ===");
echo("");
echo("VISIBILITY TOGGLES (edit at top of file):");
echo(str("  SHOW_WORM = ", SHOW_WORM));
echo(str("  SHOW_SLATS = ", SHOW_SLATS));
echo(str("  SHOW_FOLLOWERS = ", SHOW_FOLLOWERS));
echo(str("  SHOW_FRAME = ", SHOW_FRAME));
echo(str("  SHOW_GUIDE_RAILS = ", SHOW_GUIDE_RAILS));
echo("");
echo("DIMENSIONS:");
echo(str("  Worm length: ", WORM_LENGTH, "mm"));
echo(str("  Wave amplitude: ", WAVE_AMPLITUDE, "mm"));
echo(str("  Helix pitch: ", HELIX_PITCH, "mm"));
echo(str("  Slats: ", NUM_SLATS));
echo(str("  Slat spacing: ", SLAT_SPACING, "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Best view: FRONT (looking at -Y), slightly elevated");

// ============================================
// PARTS LIST FOR PRINTING
// ============================================

/*
 * PRINT LIST:
 *
 * 1. WORM CAM (1x)
 *    - Print horizontally or split into 2-3 sections
 *    - 200mm long, ~32mm diameter
 *    - Helical groove on surface
 *    - 6mm shaft hole through center
 *
 * 2. SLATS (24x)
 *    - 3mm x 35mm x 40mm each
 *    - Print flat, many at once
 *    - 4mm hole at bottom for follower pin
 *
 * 3. FOLLOWER PINS (24x)
 *    - 4mm diameter x 8mm long
 *    - Use metal pins or print in hard material
 *
 * 4. BEARING BLOCKS (2x)
 *    - 20mm x 20mm x ~25mm
 *    - 7mm hole for shaft + bearing
 *
 * 5. GUIDE RAIL (1x, optional)
 *    - 200mm x 4mm x ~60mm
 *    - 24 slots for slats
 *
 * 6. SHAFT (1x)
 *    - 6mm diameter steel rod
 *    - 240mm long
 *
 * HARDWARE:
 *    - 2x 606 bearings (6mm ID)
 *    - N20 motor with coupling
 *    - M3 screws for assembly
 */
