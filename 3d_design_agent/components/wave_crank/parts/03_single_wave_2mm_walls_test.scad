/*
 * SINGLE WAVE TEST - 2mm WALLS
 *
 * Tests:
 * - 2mm thick walls around hinge slot
 * - 2mm thick walls around cam housing
 * - Cam fits and rotates inside housing
 * - Wave pivots smoothly on hinge axle
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

// ============================================
// WALL THICKNESS
// ============================================

WALL = 2;  // 2mm walls

// ============================================
// WAVE PARAMETERS
// ============================================

WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

// ============================================
// HINGE SLOT
// ============================================

HINGE_SLOT_LENGTH = 8;       // OPTIMIZED
HINGE_SLOT_HEIGHT = 4;
HINGE_SLOT_CENTER_Y = 4;     // OPTIMIZED
HINGE_SLOT_CENTER_Z = 0;

// Extension with walls
HINGE_EXT_WIDTH = HINGE_SLOT_LENGTH + 2 * WALL;   // 16mm
HINGE_EXT_HEIGHT = HINGE_SLOT_HEIGHT + 2 * WALL;  // 8mm
HINGE_EXT_Y_START = HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2 - WALL;
HINGE_EXT_Z_BOTTOM = HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2 - WALL;

// ============================================
// CAM HOUSING
// ============================================

CAM_HOUSING_SIZE = 14;
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

// Extension with walls
CAM_EXT_WIDTH = CAM_HOUSING_SIZE + 2 * WALL;   // 18mm
CAM_EXT_HEIGHT = CAM_HOUSING_SIZE + 2 * WALL;  // 18mm
CAM_EXT_Y_START = CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2 - WALL;
CAM_EXT_Z_BOTTOM = CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2 - WALL;

// ============================================
// SHAFTS
// ============================================

HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;

// ============================================
// CAM (middle-dramatic for test)
// ============================================

CAM_MAJOR = 11;
CAM_MINOR = 8;
CAM_THICKNESS = 4;

// ============================================
// COLORS
// ============================================

C_WAVE = [0.75, 0.6, 0.45];
C_CAM = [0.8, 0.5, 0.2];
C_SHAFT = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.25, 0.2];

$fn = 48;

// ============================================
// CALCULATIONS
// ============================================

LEVER_ARM = CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y;

cam_push_z = (CAM_MAJOR / 2) * sin(theta);
cam_push_y = (CAM_MINOR / 2) * cos(theta);

wave_pitch = atan2(cam_push_z, LEVER_ARM);
wave_roll = atan2(cam_push_y, LEVER_ARM);

// ============================================
// MODULES
// ============================================

// Wave slat with 2mm walls
module wave_slat() {
    color(C_WAVE)
    translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([wave_pitch, wave_roll, 0])
            translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z])
                difference() {
                    union() {
                        // Main wave body
                        translate([-WAVE_THICKNESS/2, 0, 0])
                            cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);

                        // Hinge extension (slot + 2mm walls)
                        translate([-WAVE_THICKNESS/2, HINGE_EXT_Y_START, HINGE_EXT_Z_BOTTOM])
                            cube([WAVE_THICKNESS, HINGE_EXT_WIDTH, -HINGE_EXT_Z_BOTTOM]);

                        // Cam housing extension (housing + 2mm walls)
                        translate([-WAVE_THICKNESS/2, CAM_EXT_Y_START, CAM_EXT_Z_BOTTOM])
                            cube([WAVE_THICKNESS, CAM_EXT_WIDTH, -CAM_EXT_Z_BOTTOM]);
                    }

                    // Hinge slot cutout
                    translate([-WAVE_THICKNESS/2 - 1,
                               HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                               HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
                        cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);

                    // Cam housing cutout
                    translate([-WAVE_THICKNESS/2 - 1,
                               CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2,
                               CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2])
                        cube([WAVE_THICKNESS + 2, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE]);
                }
}

// Elliptical cam on camshaft
module cam_on_shaft() {
    color(C_CAM)
    translate([0, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta])
                scale([CAM_MAJOR/10, CAM_MINOR/10, 1])
                    cylinder(r=5, h=CAM_THICKNESS, center=true);
}

// Hinge axle
module hinge_axle() {
    color(C_SHAFT)
    translate([-30, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=60);
}

// Camshaft
module camshaft() {
    color(C_SHAFT)
    translate([-30, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=CAMSHAFT_DIA, h=60);
}

// Simple frame
module frame() {
    color(C_FRAME) {
        // Left wall
        translate([-25, -10, -15])
            difference() {
                cube([4, 80, 35]);
                translate([-1, HINGE_SLOT_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=HINGE_AXLE_DIA+0.4, h=6);
                translate([-1, CAM_HOUSING_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=CAMSHAFT_DIA+0.4, h=6);
            }

        // Right wall
        translate([21, -10, -15])
            difference() {
                cube([4, 80, 35]);
                translate([-1, HINGE_SLOT_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=HINGE_AXLE_DIA+0.4, h=6);
                translate([-1, CAM_HOUSING_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=CAMSHAFT_DIA+0.4, h=6);
            }

        // Base
        translate([-25, -10, -15])
            cube([50, 80, 4]);
    }
}

// ============================================
// ASSEMBLY
// ============================================

module test_assembly() {
    if (SHOW_FRAME) frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft();
    if (SHOW_CAM) cam_on_shaft();
    if (SHOW_WAVE) wave_slat();
}

// ============================================
// RENDER
// ============================================

test_assembly();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("");
echo("╔════════════════════════════════════════════════════════════╗");
echo("║      SINGLE WAVE TEST - 2mm WALLS                          ║");
echo("╚════════════════════════════════════════════════════════════╝");
echo("");
echo("WALL VERIFICATION:");
echo(str("  Wall thickness: ", WALL, "mm"));
echo(str("  Hinge extension: ", HINGE_EXT_WIDTH, "×", -HINGE_EXT_Z_BOTTOM, "mm"));
echo(str("  Cam housing ext: ", CAM_EXT_WIDTH, "×", -CAM_EXT_Z_BOTTOM, "mm"));
echo("");
echo("CUTOUT INTERIORS:");
echo(str("  Hinge slot: ", HINGE_SLOT_LENGTH, "×", HINGE_SLOT_HEIGHT, "mm"));
echo(str("  Cam housing: ", CAM_HOUSING_SIZE, "×", CAM_HOUSING_SIZE, "mm"));
echo("");
echo(str("CAM: ", CAM_MAJOR, "×", CAM_MINOR, "mm"));
echo(str("  Diagonal: ", sqrt(CAM_MAJOR*CAM_MAJOR + CAM_MINOR*CAM_MINOR)/sqrt(2)*sqrt(2)));
echo(str("  Fits in ", CAM_HOUSING_SIZE, "mm housing? ",
         sqrt(CAM_MAJOR*CAM_MAJOR/4 + CAM_MINOR*CAM_MINOR/4)*2 < CAM_HOUSING_SIZE ? "YES" : "NO"));
echo("");
echo(str("Current angle: ", theta, "°"));
echo(str("Wave pitch: ", wave_pitch, "°"));
echo(str("Wave roll: ", wave_roll, "°"));
echo("");
echo("VISUAL CHECK:");
echo("  [ ] Walls visible around both cutouts (2mm thick)");
echo("  [ ] Cam stays inside housing at all angles");
echo("  [ ] Wave rocks smoothly up/down and toward/away");
echo("  [ ] No intersection between parts");
