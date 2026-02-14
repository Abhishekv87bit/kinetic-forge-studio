/*
 * WAVE OCEAN V10 - APPROACH A: ECCENTRIC CRANK
 * Single wave test - validates mechanism geometry
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   X = horizontal (left/right)
 *   Z = vertical (up/down)
 *   Y = depth (into screen)
 *
 * MECHANISM: Eccentric crank drives wave in elliptical path
 *   - Rotating disc with offset pin
 *   - Crank arm connects pin to wave element
 *   - Guide rails constrain wave to vertical + slight horizontal
 *
 * Expected motion: Wave rises while drifting RIGHT, falls while drifting LEFT
 */

$fn = 48;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// PHYSICAL DIMENSIONS (mm)
// ============================================

// Drive shaft (horizontal, runs along X axis)
SHAFT_DIA = 4;
SHAFT_LENGTH = 60;
SHAFT_Y = 0;        // Center of mechanism (depth)
SHAFT_Z = 20;       // Height of shaft axis

// Eccentric disc (mounted on shaft)
DISC_OUTER_DIA = 24;
DISC_THICKNESS = 5;
ECCENTRIC_RADIUS = 8;  // Distance from shaft center to pin center
                       // This sets amplitude: wave moves +/- 8mm vertically

// Crank pin (on disc, offset from center)
PIN_DIA = 3;
PIN_LENGTH = 15;       // Must be long enough to reach crank arm

// Crank arm (connects pin to wave)
CRANK_LENGTH = 35;     // Distance from pin axis to wave pivot
CRANK_WIDTH = 8;
CRANK_THICKNESS = 4;
CRANK_HOLE_DIA = 3.2;  // Clearance for pin

// Wave element (the visible moving part)
WAVE_WIDTH = 40;       // X dimension (visible width)
WAVE_HEIGHT = 25;      // Z dimension (visible height)
WAVE_DEPTH = 4;        // Y dimension (thickness)

// Guide rail (constrains wave motion)
GUIDE_HEIGHT = 60;     // Total height of guide
GUIDE_SLOT_WIDTH = 6;  // Horizontal slot allows slight X drift
GUIDE_SLOT_HEIGHT = 40;// Vertical travel range
GUIDE_THICKNESS = 5;

// Wave pivot tab (rides in guide slot)
TAB_WIDTH = 5;
TAB_HEIGHT = 8;
TAB_DEPTH = WAVE_DEPTH;

// Frame reference
FRAME_WIDTH = 80;
FRAME_DEPTH = 40;
FRAME_HEIGHT = 5;

// ============================================
// COLORS
// ============================================

C_SHAFT = [0.6, 0.6, 0.65];
C_DISC = [0.8, 0.5, 0.2];      // Bronze
C_PIN = [0.5, 0.5, 0.55];
C_CRANK = [0.7, 0.7, 0.75];
C_WAVE = [0.25, 0.45, 0.75];   // Ocean blue
C_GUIDE = [0.35, 0.35, 0.4];
C_FRAME = [0.3, 0.3, 0.35];

// ============================================
// KINEMATICS
// ============================================

// Pin position (traces circle as disc rotates)
function pin_x() = 0;  // Pin stays at disc X position
function pin_y() = SHAFT_Y + ECCENTRIC_RADIUS * sin(theta);
function pin_z() = SHAFT_Z + ECCENTRIC_RADIUS * cos(theta);

// Wave center position (connected to pin via crank arm)
// Crank arm is rigid, length CRANK_LENGTH
// Wave is constrained to move mostly vertically by guide rail
// Simplified: wave Z follows pin Z, wave X drifts based on pin Y
function wave_z() = pin_z() + (CRANK_LENGTH - 10);  // Offset above pin
function wave_x_drift() = pin_y() * 0.3;  // Partial horizontal coupling

// Crank arm angle (geometry)
function crank_angle() = atan2(pin_y(), pin_z() - SHAFT_Z);

// ============================================
// MODULES: MECHANISM PARTS
// ============================================

// Drive shaft (rotates around X axis)
module drive_shaft() {
    color(C_SHAFT)
    translate([-SHAFT_LENGTH/2, SHAFT_Y, SHAFT_Z])
    rotate([0, 90, 0])
        cylinder(d=SHAFT_DIA, h=SHAFT_LENGTH);
}

// Eccentric disc with pin (mounted on shaft, rotates with it)
module eccentric_disc() {
    disc_x = 0;

    color(C_DISC)
    translate([disc_x, SHAFT_Y, SHAFT_Z])
    rotate([0, 90, 0])  // Disc face perpendicular to X axis
    rotate([0, 0, theta])  // Rotate with animation
    difference() {
        // Disc body
        cylinder(d=DISC_OUTER_DIA, h=DISC_THICKNESS, center=true);
        // Shaft hole (center)
        cylinder(d=SHAFT_DIA + 0.4, h=DISC_THICKNESS + 2, center=true);
    }

    // Crank pin (offset from center by ECCENTRIC_RADIUS)
    color(C_PIN)
    translate([disc_x, pin_y(), pin_z()])
    rotate([0, 90, 0])
        cylinder(d=PIN_DIA, h=PIN_LENGTH, center=true);
}

// Crank arm (connects pin to wave)
module crank_arm() {
    arm_x = 0;

    color(C_CRANK)
    translate([arm_x, pin_y(), pin_z()])
    rotate([crank_angle(), 0, 0])  // Rotate to follow pin
    translate([0, 0, CRANK_LENGTH/2])
    difference() {
        // Arm body
        cube([CRANK_WIDTH, CRANK_THICKNESS, CRANK_LENGTH], center=true);
        // Pin hole at bottom
        translate([0, 0, -CRANK_LENGTH/2])
        rotate([90, 0, 0])
            cylinder(d=CRANK_HOLE_DIA, h=CRANK_THICKNESS + 2, center=true);
        // Pivot hole at top
        translate([0, 0, CRANK_LENGTH/2])
        rotate([90, 0, 0])
            cylinder(d=CRANK_HOLE_DIA, h=CRANK_THICKNESS + 2, center=true);
    }
}

// Wave element (the visible ocean wave shape)
module wave_element() {
    wz = wave_z();
    wx_drift = wave_x_drift();

    color(C_WAVE)
    translate([wx_drift, -15, wz])  // Positioned in front (toward viewer)
    rotate([90, 0, 0])
    linear_extrude(height=WAVE_DEPTH)
    // Wave profile (simple curved shape)
    polygon([
        [-WAVE_WIDTH/2, 0],
        [-WAVE_WIDTH/2 + 5, WAVE_HEIGHT * 0.3],
        [-WAVE_WIDTH/4, WAVE_HEIGHT * 0.7],
        [0, WAVE_HEIGHT],                        // Peak
        [WAVE_WIDTH/4, WAVE_HEIGHT * 0.8],
        [WAVE_WIDTH/2 - 5, WAVE_HEIGHT * 0.4],
        [WAVE_WIDTH/2, 0]
    ]);

    // Pivot tab (connects to crank, rides in guide)
    color(C_WAVE)
    translate([wx_drift - TAB_WIDTH/2, -10, wz - WAVE_HEIGHT/2])
        cube([TAB_WIDTH, TAB_DEPTH, TAB_HEIGHT]);
}

// Guide rail (constrains wave to vertical path with slight horizontal play)
module guide_rail() {
    guide_x = -WAVE_WIDTH/2 - 10;
    guide_y = -10;
    guide_z = SHAFT_Z;

    color(C_GUIDE)
    translate([guide_x, guide_y, guide_z])
    difference() {
        // Rail body
        cube([GUIDE_THICKNESS, GUIDE_THICKNESS, GUIDE_HEIGHT]);
        // Slot for wave tab
        translate([-1, -1, GUIDE_HEIGHT/2 - GUIDE_SLOT_HEIGHT/2])
            cube([GUIDE_THICKNESS + 2, GUIDE_THICKNESS + 2, GUIDE_SLOT_HEIGHT]);
    }

    // Second guide rail (right side)
    color(C_GUIDE)
    translate([WAVE_WIDTH/2 + 5, guide_y, guide_z])
    difference() {
        cube([GUIDE_THICKNESS, GUIDE_THICKNESS, GUIDE_HEIGHT]);
        translate([-1, -1, GUIDE_HEIGHT/2 - GUIDE_SLOT_HEIGHT/2])
            cube([GUIDE_THICKNESS + 2, GUIDE_THICKNESS + 2, GUIDE_SLOT_HEIGHT]);
    }
}

// Base frame (static reference)
module base_frame() {
    color(C_FRAME)
    translate([-FRAME_WIDTH/2, -FRAME_DEPTH/2, 0])
        cube([FRAME_WIDTH, FRAME_DEPTH, FRAME_HEIGHT]);

    // Shaft supports
    color(C_FRAME) {
        translate([-SHAFT_LENGTH/2 - 5, SHAFT_Y - 5, 0])
        difference() {
            cube([10, 10, SHAFT_Z + 5]);
            translate([5, 5, SHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=SHAFT_DIA + 0.6, h=12, center=true);
        }

        translate([SHAFT_LENGTH/2 - 5, SHAFT_Y - 5, 0])
        difference() {
            cube([10, 10, SHAFT_Z + 5]);
            translate([5, 5, SHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=SHAFT_DIA + 0.6, h=12, center=true);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_crankA() {
    base_frame();
    drive_shaft();
    eccentric_disc();
    crank_arm();
    wave_element();
    // guide_rail();  // Uncomment to see guides
}

// Render
wave_ocean_v10_crankA();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("=== WAVE OCEAN V10 - APPROACH A: ECCENTRIC CRANK ===");
echo(str("theta = ", theta, " degrees"));
echo(str("Pin position: Y=", pin_y(), " Z=", pin_z()));
echo(str("Wave Z = ", wave_z(), ", X drift = ", wave_x_drift()));
echo("");
echo("Mechanism check:");
echo(str("  Eccentric radius: ", ECCENTRIC_RADIUS, "mm (vertical amplitude)"));
echo(str("  Crank arm length: ", CRANK_LENGTH, "mm (CONSTANT - must not change during rotation)"));
echo(str("  Shaft through disc: ", SHAFT_DIA, "mm shaft, ", SHAFT_DIA + 0.4, "mm hole = ", 0.4, "mm clearance"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Watch from FRONT (looking at -Y) to see wave motion");

// ============================================
// VERIFICATION: CRANK LENGTH CONSTANT
// ============================================

// At theta=0: pin at (0, 0, 28), wave at ~(0, -15, 53)
// At theta=90: pin at (0, 8, 20), wave at ~(2.4, -15, 45)
// At theta=180: pin at (0, 0, 12), wave at ~(0, -15, 37)
// At theta=270: pin at (0, -8, 20), wave at ~(-2.4, -15, 45)
//
// Crank length = sqrt((wave_y - pin_y)^2 + (wave_z - pin_z)^2)
// Should be ~35mm at all angles (CRANK_LENGTH = 35)

verify_crank = sqrt(pow(-15 - pin_y(), 2) + pow(wave_z() - pin_z(), 2));
echo(str("Crank length at current theta: ", verify_crank, "mm (should be ~35mm)"));
