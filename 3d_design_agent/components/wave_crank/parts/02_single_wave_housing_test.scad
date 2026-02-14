/*
 * SINGLE WAVE + CAM HOUSING TEST
 *
 * Tests the v4 mechanism:
 * - Elliptical cam INSIDE square housing
 * - Cam contacts all 4 walls
 * - Wave pivots on hinge slot
 * - Compound motion (Z + Y)
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

SHOW_WAVE = true;
SHOW_CAM = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT = true;
SHOW_FRAME = true;
SHOW_HOUSING_OUTLINE = true;  // Debug: show housing boundary

// ============================================
// PARAMETERS (from geometry checklist)
// ============================================

// Wave
WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

// Hinge slot
HINGE_SLOT_LENGTH = 12;
HINGE_SLOT_HEIGHT = 4;
HINGE_SLOT_CENTER_Y = 6;
HINGE_SLOT_CENTER_Z = 0;

// Cam housing (SQUARE)
CAM_HOUSING_SIZE = 14;
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

// Shafts
HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;

// Cam (using middle-dramatic size for test)
CAM_MAJOR = 11;    // Test with middle size
CAM_MINOR = 8;
CAM_THICKNESS = 4;

// Frame
FRAME_WIDTH = 40;
FRAME_DEPTH = 80;
FRAME_HEIGHT = 40;
FRAME_WALL = 4;

$fn = 48;

// ============================================
// COLORS
// ============================================

C_WAVE = [0.75, 0.6, 0.45];
C_CAM = [0.8, 0.5, 0.2];
C_AXLE = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.25, 0.2];
C_DEBUG = [1, 0, 0, 0.3];

// ============================================
// MOTION CALCULATIONS
// ============================================

// Lever arm (distance from hinge to cam)
LEVER_ARM = CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y;  // 47mm

// Cam push amount at current angle
cam_push_z = (CAM_MAJOR / 2) * sin(theta);
cam_push_y = (CAM_MINOR / 2) * cos(theta);

// Wave angles from cam push
wave_angle_pitch = atan2(cam_push_z, LEVER_ARM);  // Up/down tilt
wave_angle_roll = atan2(cam_push_y, LEVER_ARM);   // Toward/away tilt

// ============================================
// MODULES
// ============================================

// Wave slat with cutouts
module wave_slat() {
    color(C_WAVE)
    // Pivot around hinge center
    translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([wave_angle_pitch, wave_angle_roll, 0])
            translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z])
                difference() {
                    union() {
                        // Wave body (above baseline)
                        translate([-WAVE_THICKNESS/2, 0, 0])
                            cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);

                        // Extension for hinge slot
                        translate([-WAVE_THICKNESS/2, 0, -CAM_HOUSING_SIZE/2])
                            cube([WAVE_THICKNESS, HINGE_SLOT_LENGTH + 2, CAM_HOUSING_SIZE/2]);

                        // Extension for cam housing
                        translate([-WAVE_THICKNESS/2, CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2, -CAM_HOUSING_SIZE/2])
                            cube([WAVE_THICKNESS, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE/2]);
                    }

                    // Hinge slot cutout
                    translate([-WAVE_THICKNESS/2 - 1,
                               HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                               HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
                        cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);

                    // Cam housing cutout (SQUARE)
                    translate([-WAVE_THICKNESS/2 - 1,
                               CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2,
                               CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2])
                        cube([WAVE_THICKNESS + 2, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE]);
                }
}

// Elliptical cam
module cam() {
    color(C_CAM)
    translate([0, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta])
                difference() {
                    // Elliptical disc
                    scale([CAM_MAJOR/10, CAM_MINOR/10, 1])
                        cylinder(r=5, h=CAM_THICKNESS, center=true);

                    // Shaft hole
                    cylinder(d=CAMSHAFT_DIA + 0.3, h=CAM_THICKNESS + 2, center=true);
                }
}

// Hinge axle
module hinge_axle() {
    color(C_AXLE)
    translate([-FRAME_WIDTH/2, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=FRAME_WIDTH);
}

// Camshaft
module camshaft() {
    color(C_AXLE)
    translate([-FRAME_WIDTH/2, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=CAMSHAFT_DIA, h=FRAME_WIDTH);
}

// Simple frame
module frame() {
    color(C_FRAME) {
        // Base
        translate([-FRAME_WIDTH/2, -5, -FRAME_HEIGHT/2 - 5])
            cube([FRAME_WIDTH, FRAME_DEPTH, FRAME_WALL]);

        // Left wall
        translate([-FRAME_WIDTH/2, -5, -FRAME_HEIGHT/2 - 5])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                // Hinge hole
                translate([-1, HINGE_SLOT_CENTER_Y + 5, FRAME_HEIGHT/2 + 5])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
                // Camshaft hole
                translate([-1, CAM_HOUSING_CENTER_Y + 5, FRAME_HEIGHT/2 + 5])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }

        // Right wall
        translate([FRAME_WIDTH/2 - FRAME_WALL, -5, -FRAME_HEIGHT/2 - 5])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                // Hinge hole
                translate([-1, HINGE_SLOT_CENTER_Y + 5, FRAME_HEIGHT/2 + 5])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
                // Camshaft hole
                translate([-1, CAM_HOUSING_CENTER_Y + 5, FRAME_HEIGHT/2 + 5])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }
    }
}

// Debug: housing outline (transparent)
module housing_outline() {
    color(C_DEBUG)
    translate([0, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            difference() {
                cube([CAM_HOUSING_SIZE, CAM_HOUSING_SIZE, WAVE_THICKNESS + 2], center=true);
                cube([CAM_HOUSING_SIZE - 1, CAM_HOUSING_SIZE - 1, WAVE_THICKNESS + 4], center=true);
            }
}

// ============================================
// ASSEMBLY
// ============================================

module single_wave_test() {
    if (SHOW_FRAME) frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft();
    if (SHOW_CAM) cam();
    if (SHOW_WAVE) wave_slat();
    if (SHOW_HOUSING_OUTLINE) housing_outline();
}

// ============================================
// RENDER
// ============================================

single_wave_test();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("");
echo("╔════════════════════════════════════════════════════════════╗");
echo("║       SINGLE WAVE + CAM HOUSING TEST                       ║");
echo("╚════════════════════════════════════════════════════════════╝");
echo("");
echo("MECHANISM:");
echo("  Elliptical cam rotates INSIDE square housing");
echo("  Cam contacts all 4 walls → compound motion");
echo("");
echo("DIMENSIONS:");
echo(str("  Wave: ", WAVE_LENGTH, "×", WAVE_BODY_HEIGHT, "×", WAVE_THICKNESS, "mm"));
echo(str("  Hinge slot: ", HINGE_SLOT_LENGTH, "×", HINGE_SLOT_HEIGHT, "mm at Y=", HINGE_SLOT_CENTER_Y));
echo(str("  Cam housing: ", CAM_HOUSING_SIZE, "×", CAM_HOUSING_SIZE, "mm at Y=", CAM_HOUSING_CENTER_Y));
echo(str("  Cam: ", CAM_MAJOR, "×", CAM_MINOR, "mm (eccentricity=", CAM_MAJOR-CAM_MINOR, "mm)"));
echo("");
echo(str("Current angle: ", theta, "°"));
echo(str("Cam push Z: ", cam_push_z, "mm"));
echo(str("Cam push Y: ", cam_push_y, "mm"));
echo(str("Wave pitch angle: ", wave_angle_pitch, "°"));
echo(str("Wave roll angle: ", wave_angle_roll, "°"));
echo("");
echo("VERIFICATION:");
echo(str("  Cam fits in housing? Major ", CAM_MAJOR, " < ", CAM_HOUSING_SIZE, " = ",
         CAM_MAJOR < CAM_HOUSING_SIZE ? "YES" : "NO"));
echo(str("  Diagonal check (at 45°): ",
         CAM_MAJOR * 0.707 + CAM_MINOR * 0.707, " < ", CAM_HOUSING_SIZE, " = ",
         (CAM_MAJOR * 0.707 + CAM_MINOR * 0.707) < CAM_HOUSING_SIZE ? "PASS" : "JAM!"));
echo("");
echo("VISUAL CHECK:");
echo("  - Wave should rock UP/DOWN as cam rotates");
echo("  - Wave should tilt TOWARD/AWAY from viewer");
echo("  - Cam should stay INSIDE housing at all angles");
echo("  - No intersection between cam and housing walls");
