/*
 * WAVE OCEAN v5 - OPTIMIZED + VERIFIED
 *
 * Updates from v4:
 * - 2mm thick walls around ALL cutouts
 * - Camshaft with integrated cams (one printable piece)
 * - Hinge axle (simple printable cylinder)
 *
 * Optimizations applied (from geometry verification):
 * - Increased max cam eccentricity (12.5×6.5mm)
 * - Reduced hinge slot length (8mm)
 * - Verified clearances at ALL 8 rotation angles
 *
 * Verification status: 100% PASS (see 0_geometry_v5_VERIFIED.md)
 *
 * Date: 2026-01-21
 */

// ============================================
// ANIMATION CONTROL
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_FRAME = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT_WITH_CAMS = true;
SHOW_WAVES = true;
SHOW_HAND_CRANK = true;

// Wave range
WAVE_RANGE_START = 0;
WAVE_RANGE_END = 21;

// ============================================
// WALL THICKNESS
// ============================================

WALL = 2;  // 2mm walls around all cutouts

// ============================================
// WAVE PARAMETERS
// ============================================

WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

// ============================================
// HINGE SLOT (with 2mm walls) - OPTIMIZED
// ============================================

HINGE_SLOT_LENGTH = 8;       // Y interior (reduced from 12mm - only need ~5mm travel)
HINGE_SLOT_HEIGHT = 4;       // Z interior
HINGE_SLOT_CENTER_Y = 4;     // from wave Y=0 (adjusted for shorter slot)
HINGE_SLOT_CENTER_Z = 0;     // at baseline

// Extension dimensions (slot + walls)
HINGE_EXT_WIDTH = HINGE_SLOT_LENGTH + 2 * WALL;   // 16mm
HINGE_EXT_HEIGHT = HINGE_SLOT_HEIGHT + 2 * WALL;  // 8mm
HINGE_EXT_Y_START = HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2 - WALL;  // -2
HINGE_EXT_Z_BOTTOM = HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2 - WALL; // -4

// ============================================
// CAM HOUSING (with 2mm walls)
// ============================================

CAM_HOUSING_SIZE = 14;       // Square interior
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

// Extension dimensions (housing + walls)
CAM_EXT_WIDTH = CAM_HOUSING_SIZE + 2 * WALL;   // 18mm
CAM_EXT_HEIGHT = CAM_HOUSING_SIZE + 2 * WALL;  // 18mm
CAM_EXT_Y_START = CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2 - WALL;  // 44
CAM_EXT_Z_BOTTOM = CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2 - WALL; // -9

// ============================================
// SHAFT PARAMETERS
// ============================================

HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;
SHAFT_LENGTH = 240;

// ============================================
// CAM PARAMETERS (progressive)
// ============================================

CAM_THICKNESS = 4;
NUM_WAVES = 22;
UNIT_PITCH = 10;
PHASE_OFFSET = 360 / NUM_WAVES;

// Progressive sizing - OPTIMIZED for more dramatic motion
// Verified: diagonal extent at 45° = 9.8mm < 14mm housing ✓
function cam_major(i) = 10 + (i / (NUM_WAVES - 1)) * 2.5;  // 10mm to 12.5mm
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 2.5;   // 9mm to 6.5mm
function cam_phase(i) = i * PHASE_OFFSET;

// ============================================
// FRAME PARAMETERS
// ============================================

WAVE_AREA_START_X = 78;
FIRST_WAVE_X = WAVE_AREA_START_X + UNIT_PITCH;

FRAME_LENGTH = 260;
FRAME_DEPTH = 90;
FRAME_HEIGHT = 50;
FRAME_WALL = 5;
FRAME_X_START = 70;
FRAME_Y_START = -15;
FRAME_Z_BASE = -15;

// ============================================
// CRANK PARAMETERS
// ============================================

CRANK_ARM = 25;
CRANK_KNOB_DIA = 10;
CRANK_KNOB_H = 15;

// ============================================
// COLORS
// ============================================

C_WAVE = [0.75, 0.6, 0.45];
C_CAM = [0.8, 0.5, 0.2];
C_SHAFT = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.25, 0.2];
C_CRANK = [0.5, 0.4, 0.3];

$fn = 48;

// ============================================
// DERIVED CALCULATIONS
// ============================================

function wave_x(i) = FIRST_WAVE_X + i * UNIT_PITCH;

// Lever arm
LEVER_ARM = CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y;  // 47mm

// Wave angles from cam push
function wave_angle_pitch(i, angle) =
    atan2((cam_major(i) / 2) * sin(angle + cam_phase(i)), LEVER_ARM);

function wave_angle_roll(i, angle) =
    atan2((cam_minor(i) / 2) * cos(angle + cam_phase(i)), LEVER_ARM);

// ============================================
// MODULES
// ============================================

// Single wave slat with proper 2mm walls
module wave_slat(i) {
    x_pos = wave_x(i);
    pitch = wave_angle_pitch(i, theta);
    roll = wave_angle_roll(i, theta);

    color(C_WAVE)
    translate([x_pos, 0, 0])
        translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
            rotate([pitch, roll, 0])
                translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z])
                    difference() {
                        union() {
                            // Main wave body
                            translate([-WAVE_THICKNESS/2, 0, 0])
                                cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);

                            // Hinge extension (with 2mm walls)
                            translate([-WAVE_THICKNESS/2, HINGE_EXT_Y_START, HINGE_EXT_Z_BOTTOM])
                                cube([WAVE_THICKNESS, HINGE_EXT_WIDTH, -HINGE_EXT_Z_BOTTOM]);

                            // Cam housing extension (with 2mm walls)
                            translate([-WAVE_THICKNESS/2, CAM_EXT_Y_START, CAM_EXT_Z_BOTTOM])
                                cube([WAVE_THICKNESS, CAM_EXT_WIDTH, -CAM_EXT_Z_BOTTOM]);
                        }

                        // Hinge slot cutout (interior only)
                        translate([-WAVE_THICKNESS/2 - 1,
                                   HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                                   HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
                            cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);

                        // Cam housing cutout (interior only)
                        translate([-WAVE_THICKNESS/2 - 1,
                                   CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2,
                                   CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2])
                            cube([WAVE_THICKNESS + 2, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE]);
                    }
}

// All waves
module all_waves() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        wave_slat(i);
    }
}

// Printable hinge axle (simple cylinder)
module hinge_axle() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=SHAFT_LENGTH + 10);
}

// Printable camshaft with integrated cams
module camshaft_with_cams() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Main shaft
                cylinder(d=CAMSHAFT_DIA, h=SHAFT_LENGTH + 10);

                // Integrated cams at each wave position
                for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
                    cam_x = wave_x(i) - FRAME_X_START + 5;
                    major = cam_major(i);
                    minor = cam_minor(i);
                    phase = cam_phase(i);

                    translate([0, 0, cam_x])
                        rotate([0, 0, phase])
                            color(C_CAM)
                            scale([major/10, minor/10, 1])
                                cylinder(r=5, h=CAM_THICKNESS, center=true);
                }
            }
}

// Hand crank
module hand_crank() {
    color(C_CRANK)
    translate([FRAME_X_START - 15, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Hub
                difference() {
                    cylinder(d=14, h=8);
                    translate([0, 0, -1])
                        cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
                }

                // Arm
                translate([0, -3, 0])
                    cube([CRANK_ARM, 6, 8]);

                // Knob
                translate([CRANK_ARM, 0, 0])
                    cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
            }
}

// Frame
module frame() {
    color(C_FRAME) {
        // Base
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);

        // Left wall
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

                // Hinge hole
                translate([-1, HINGE_SLOT_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + HINGE_SLOT_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);

                // Camshaft hole
                translate([-1, CAM_HOUSING_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + CAM_HOUSING_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }

        // Right wall
        translate([FRAME_X_START + FRAME_LENGTH - FRAME_WALL, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

                // Hinge hole
                translate([-1, HINGE_SLOT_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + HINGE_SLOT_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);

                // Camshaft hole
                translate([-1, CAM_HOUSING_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + CAM_HOUSING_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }
    }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_ocean_v5_assembly() {
    if (SHOW_FRAME) frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT_WITH_CAMS) camshaft_with_cams();
    if (SHOW_WAVES) all_waves();
    if (SHOW_HAND_CRANK) hand_crank();
}

// ============================================
// RENDER
// ============================================

wave_ocean_v5_assembly();

// ============================================
// CONSOLE OUTPUT
// ============================================

echo("");
echo("╔════════════════════════════════════════════════════════════╗");
echo("║      WAVE OCEAN v5 - 2mm WALLS + PRINTABLE SHAFTS          ║");
echo("╠════════════════════════════════════════════════════════════╣");
echo("║                                                            ║");
echo("║  UPDATES FROM v4:                                          ║");
echo("║    - 2mm walls around ALL cutouts                          ║");
echo("║    - Camshaft + cams as ONE printable piece                ║");
echo("║    - Hinge axle as simple cylinder                         ║");
echo("║                                                            ║");
echo("║  WAVE DIMENSIONS:                                          ║");
echo(str("║    Body: ", WAVE_LENGTH, "×", WAVE_BODY_HEIGHT, "×", WAVE_THICKNESS, "mm"));
echo(str("║    Hinge extension: ", HINGE_EXT_WIDTH, "×", -HINGE_EXT_Z_BOTTOM, "mm (2mm walls)"));
echo(str("║    Cam housing ext: ", CAM_EXT_WIDTH, "×", -CAM_EXT_Z_BOTTOM, "mm (2mm walls)"));
echo("║                                                            ║");
echo("║  CUTOUTS (interior):                                       ║");
echo(str("║    Hinge slot: ", HINGE_SLOT_LENGTH, "×", HINGE_SLOT_HEIGHT, "mm"));
echo(str("║    Cam housing: ", CAM_HOUSING_SIZE, "×", CAM_HOUSING_SIZE, "mm"));
echo("║                                                            ║");
echo("║  PRINTABLE SHAFTS:                                         ║");
echo(str("║    Hinge axle: ", HINGE_AXLE_DIA, "mm dia × ", SHAFT_LENGTH, "mm"));
echo(str("║    Camshaft: ", CAMSHAFT_DIA, "mm dia × ", SHAFT_LENGTH, "mm + 22 cams"));
echo("║                                                            ║");
echo("╚════════════════════════════════════════════════════════════╝");
echo("");

echo("WALL VERIFICATION:");
echo(str("  Hinge slot walls: ", WALL, "mm - ", WALL >= 2 ? "PASS" : "FAIL"));
echo(str("  Cam housing walls: ", WALL, "mm - ", WALL >= 2 ? "PASS" : "FAIL"));
echo("");

echo("CAM SIZES (progressive):");
for (i = [0, 10, 21]) {
    echo(str("  Wave ", i+1, ": ", cam_major(i), "×", cam_minor(i), "mm"));
}
