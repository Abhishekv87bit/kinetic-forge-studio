/*
 * SINGLE WAVE + CAM TEST
 *
 * Tests the fundamental mechanism:
 * - Cam BELOW wave
 * - Wave rests ON TOP of cam
 * - Gravity keeps contact
 *
 * This MUST work before scaling to 22 waves.
 */

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE
// ============================================

SHOW_FRAME = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT = true;
SHOW_CAM = true;
SHOW_WAVE = true;
SHOW_CONTACT_POINT = true;  // Debug: show where wave touches cam

// ============================================
// Z-LAYER LAYOUT (CRITICAL!)
// ============================================

// Base at Z = 0
Z_BASE = 0;
Z_BASE_THICK = 5;

// Hinge axle - waves pivot here
Z_HINGE = 15;

// Camshaft - below wave contact
Z_CAMSHAFT = 8;

// Wave bottom surface at cam contact
// Must be >= Z_CAMSHAFT + cam_major_radius
// Calculated dynamically based on cam angle

// ============================================
// FRAME PARAMETERS
// ============================================

FRAME_WIDTH = 60;    // X
FRAME_DEPTH = 100;   // Y
FRAME_HEIGHT = 50;   // Z
FRAME_WALL = 5;

// ============================================
// HINGE AXLE (waves pivot on this)
// ============================================

HINGE_AXLE_DIA = 5;
HINGE_AXLE_Y = 10;    // Near back of frame

// ============================================
// CAMSHAFT (holds cam)
// ============================================

CAMSHAFT_DIA = 6;
CAMSHAFT_Y = 80;      // Near front of frame

// ============================================
// CAM PARAMETERS
// ============================================

CAM_MAJOR = 12;       // Major radius (vertical motion)
CAM_MINOR = 6;        // Minor radius (horizontal motion)
CAM_THICK = 4;

// ============================================
// WAVE PARAMETERS
// ============================================

WAVE_THICK = 4;
WAVE_HEIGHT = 20;     // Visual height (Z)
WAVE_LENGTH = CAMSHAFT_Y - HINGE_AXLE_Y;  // Y dimension

// Slot at hinge end
SLOT_WIDTH = HINGE_AXLE_DIA + 0.4;
SLOT_LENGTH = 12;

// ============================================
// DERIVED VALUES
// ============================================

// Cam top surface (where wave contacts)
function cam_top_z() = Z_CAMSHAFT + CAM_MAJOR * sin(theta);

// Wave must rest on cam
// Wave pivot is at Z_HINGE
// Wave contact point is at Y = CAMSHAFT_Y
// Wave rotates to match cam height

function wave_contact_z() = cam_top_z();

// Wave angle from pivot
function wave_angle() =
    atan2(wave_contact_z() - Z_HINGE, CAMSHAFT_Y - HINGE_AXLE_Y);

// ============================================
// COLORS
// ============================================

C_FRAME = [0.3, 0.3, 0.3];
C_AXLE = [0.6, 0.6, 0.65];
C_CAM = [0.8, 0.6, 0.3];
C_WAVE = [0.7, 0.55, 0.4];
C_CONTACT = [1, 0, 0];  // Red debug point

$fn = 48;

// ============================================
// MODULES
// ============================================

// Frame base
module frame_base() {
    color(C_FRAME)
        translate([-FRAME_WIDTH/2, 0, Z_BASE])
            cube([FRAME_WIDTH, FRAME_DEPTH, Z_BASE_THICK]);
}

// Frame side walls
module frame_walls() {
    color(C_FRAME) {
        // Left wall
        translate([-FRAME_WIDTH/2, 0, Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                // Hinge axle hole
                translate([-1, HINGE_AXLE_Y, Z_HINGE])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA+0.4, h=FRAME_WALL+2);
                // Camshaft hole
                translate([-1, CAMSHAFT_Y, Z_CAMSHAFT])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA+0.4, h=FRAME_WALL+2);
            }
        // Right wall
        translate([FRAME_WIDTH/2 - FRAME_WALL, 0, Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                // Hinge axle hole
                translate([-1, HINGE_AXLE_Y, Z_HINGE])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA+0.4, h=FRAME_WALL+2);
                // Camshaft hole
                translate([-1, CAMSHAFT_Y, Z_CAMSHAFT])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA+0.4, h=FRAME_WALL+2);
            }
    }
}

// Hinge axle (static)
module hinge_axle() {
    color(C_AXLE)
        translate([-FRAME_WIDTH/2 - 5, HINGE_AXLE_Y, Z_HINGE])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA, h=FRAME_WIDTH + 10);
}

// Camshaft (rotating)
module camshaft() {
    color(C_AXLE)
        translate([-FRAME_WIDTH/2 - 5, CAMSHAFT_Y, Z_CAMSHAFT])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA, h=FRAME_WIDTH + 10);
}

// Elliptical cam (rotates with camshaft)
module cam() {
    color(C_CAM)
        translate([0, CAMSHAFT_Y, Z_CAMSHAFT])
            rotate([0, 90, 0])
                rotate([0, 0, theta])
                    difference() {
                        // Elliptical disc
                        scale([CAM_MAJOR/10, CAM_MINOR/10, 1])
                            cylinder(r=10, h=CAM_THICK, center=true);
                        // Shaft hole
                        cylinder(d=CAMSHAFT_DIA+0.3, h=CAM_THICK+2, center=true);
                    }
}

// Wave slat (pivots on hinge, rests on cam)
module wave() {
    angle = wave_angle();

    color(C_WAVE)
        translate([0, HINGE_AXLE_Y, Z_HINGE])
            rotate([angle, 0, 0])
                translate([-WAVE_THICK/2, 0, 0]) {
                    difference() {
                        // Main body
                        cube([WAVE_THICK, WAVE_LENGTH, WAVE_HEIGHT]);

                        // Slot at hinge end (axle passes through)
                        translate([-1, -1, WAVE_HEIGHT/2 - SLOT_WIDTH/2])
                            cube([WAVE_THICK+2, SLOT_LENGTH+1, SLOT_WIDTH]);
                    }
                }
}

// Debug: contact point visualization
module contact_point() {
    color(C_CONTACT)
        translate([0, CAMSHAFT_Y, cam_top_z()])
            sphere(r=2);
}

// ============================================
// ASSEMBLY
// ============================================

module single_wave_test() {
    if (SHOW_FRAME) {
        frame_base();
        frame_walls();
    }

    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft();
    if (SHOW_CAM) cam();
    if (SHOW_WAVE) wave();
    if (SHOW_CONTACT_POINT) contact_point();
}

// ============================================
// RENDER
// ============================================

single_wave_test();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("╔════════════════════════════════════════════╗");
echo("║     SINGLE WAVE + CAM TEST                 ║");
echo("╚════════════════════════════════════════════╝");
echo("");
echo("Z-LAYER LAYOUT:");
echo(str("  Base:      Z = ", Z_BASE, " to ", Z_BASE + Z_BASE_THICK));
echo(str("  Camshaft:  Z = ", Z_CAMSHAFT));
echo(str("  Hinge:     Z = ", Z_HINGE));
echo("");
echo(str("Current cam angle: ", theta, "°"));
echo(str("Cam top surface:   Z = ", cam_top_z(), "mm"));
echo(str("Wave angle:        ", wave_angle(), "°"));
echo("");
echo("VERIFICATION:");
echo(str("  Cam BELOW hinge? ", Z_CAMSHAFT < Z_HINGE ? "YES ✓" : "NO ✗"));
echo(str("  Wave rests on cam? (gravity assists)"));
echo("");
echo("If wave appears to pass through cam: GEOMETRY ERROR");
echo("Wave should visibly rock up/down as cam rotates");
