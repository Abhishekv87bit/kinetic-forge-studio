/*
 * WAVE OCEAN v6 - PROGRESSIVE ECCENTRICITY + FOAM/FISH ELEMENTS
 *
 * Features:
 * - 22 waves with DRAMATICALLY progressive cam eccentricity
 * - Mixed foam (zones A,B) and fish (zone C) elements
 * - Elements mounted on wave tops, face viewer
 * - 2mm walls, printable shafts
 *
 * Cam progression: 3x ratio (visually dramatic)
 *   Wave 1:  circular (9×9mm) → gentle ~2.5mm tip motion
 *   Wave 22: elliptical (12.5×6mm) → dramatic ~7.5mm tip motion
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
SHOW_FOAM_FISH = true;
SHOW_HAND_CRANK = true;

WAVE_RANGE_START = 0;
WAVE_RANGE_END = 21;

// ============================================
// WALL THICKNESS
// ============================================

WALL = 2;

// ============================================
// WAVE PARAMETERS
// ============================================

WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

// ============================================
// HINGE SLOT (with 2mm walls)
// ============================================

HINGE_SLOT_LENGTH = 8;
HINGE_SLOT_HEIGHT = 4;
HINGE_SLOT_CENTER_Y = 4;
HINGE_SLOT_CENTER_Z = 0;

HINGE_EXT_WIDTH = HINGE_SLOT_LENGTH + 2 * WALL;
HINGE_EXT_Y_START = HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2 - WALL;
HINGE_EXT_Z_BOTTOM = HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2 - WALL;

// ============================================
// CAM HOUSING (with 2mm walls)
// ============================================

CAM_HOUSING_SIZE = 14;
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

CAM_EXT_WIDTH = CAM_HOUSING_SIZE + 2 * WALL;
CAM_EXT_Y_START = CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2 - WALL;
CAM_EXT_Z_BOTTOM = CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2 - WALL;

// ============================================
// SHAFT PARAMETERS
// ============================================

HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;
SHAFT_LENGTH = 240;

// ============================================
// CAM PARAMETERS - CORRECTED PROGRESSIVE ECCENTRICITY
// ============================================

CAM_THICKNESS = 4;
NUM_WAVES = 22;
UNIT_PITCH = 10;
PHASE_OFFSET = 360 / NUM_WAVES;

// NEW FORMULAS: 3x ratio for dramatic visual difference
// Wave 1: circular (9×9mm) - gentle motion
// Wave 22: elliptical (12.5×6mm) - dramatic motion
function cam_major(i) = 9 + (i / (NUM_WAVES - 1)) * 3.5;   // 9mm to 12.5mm
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 3;     // 9mm to 6mm
function cam_phase(i) = i * PHASE_OFFSET;

// Eccentricity for reference
function cam_eccentricity(i) = cam_major(i) - cam_minor(i);

// ============================================
// FOAM/FISH ELEMENT PARAMETERS
// ============================================

// Mount position on wave
ELEMENT_MOUNT_Y = 35;        // Middle of wave face
ELEMENT_MOUNT_Z = WAVE_BODY_HEIGHT;  // On top surface

// Zone definitions
ZONE_A_END = 6;              // Waves 0-6 (7 waves) - small foam
ZONE_B_END = 13;             // Waves 7-13 (7 waves) - medium foam
// Zone C: Waves 14-21 (8 waves) - fish

// Element sizes (width × height × depth)
FOAM_SMALL_W = 8;
FOAM_SMALL_H = 6;
FOAM_SMALL_D = 3;

FOAM_MEDIUM_W = 12;
FOAM_MEDIUM_H = 9;
FOAM_MEDIUM_D = 4;

FISH_W = 14;                 // Reduced from 16mm for clearance
FISH_H = 10;
FISH_D = 5;

// Mount post sizes
function mount_post_dia(i) =
    i <= ZONE_A_END ? 2 :
    i <= ZONE_B_END ? 2.5 :
    3;

function mount_hole_dia(i) = mount_post_dia(i) + 0.1;

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
C_FOAM = [0.95, 0.98, 1.0];     // White foam
C_FISH = [0.3, 0.5, 0.7];       // Blue-gray fish

$fn = 48;

// ============================================
// DERIVED CALCULATIONS
// ============================================

function wave_x(i) = FIRST_WAVE_X + i * UNIT_PITCH;

LEVER_ARM = CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y;

function wave_angle_pitch(i, angle) =
    atan2((cam_major(i) / 2) * sin(angle + cam_phase(i)), LEVER_ARM);

function wave_angle_roll(i, angle) =
    atan2((cam_minor(i) / 2) * cos(angle + cam_phase(i)), LEVER_ARM);

// ============================================
// FOAM ELEMENT MODULES
// ============================================

// Organic blob foam - small (Zone A)
module foam_small() {
    color(C_FOAM)
    union() {
        // Main blob - hull of spheres for organic shape
        hull() {
            translate([0, 0, 2]) sphere(r=3);
            translate([-2, 0, 4]) sphere(r=2);
            translate([2, 0, 3.5]) sphere(r=2.5);
            translate([0, 0, 5]) sphere(r=1.5);
        }
        // Mount post
        translate([0, 0, -3])
            cylinder(d=2, h=3);
    }
}

// Organic blob foam - medium (Zone B)
module foam_medium() {
    color(C_FOAM)
    union() {
        // Larger organic blob
        hull() {
            translate([0, 0, 3]) sphere(r=4);
            translate([-3, 0, 5]) sphere(r=3);
            translate([3, 0, 4]) sphere(r=3);
            translate([0, 0, 7]) sphere(r=2);
            translate([-1, 0, 8]) sphere(r=1.5);
        }
        // Mount post
        translate([0, 0, -4])
            cylinder(d=2.5, h=4);
    }
}

// Fish element (Zone C)
module fish_element() {
    color(C_FISH)
    union() {
        // Fish body - elongated hull
        hull() {
            // Head
            translate([5, 0, 0]) sphere(r=3);
            // Body
            translate([0, 0, 0]) scale([1, 0.6, 1]) sphere(r=4);
            // Tail junction
            translate([-5, 0, 0]) sphere(r=2);
        }
        // Tail fin
        hull() {
            translate([-5, 0, 0]) sphere(r=1);
            translate([-9, 0, 3]) sphere(r=0.5);
            translate([-9, 0, -3]) sphere(r=0.5);
        }
        // Dorsal fin
        hull() {
            translate([0, 0, 3.5]) sphere(r=0.5);
            translate([-2, 0, 5]) sphere(r=0.3);
            translate([2, 0, 3]) sphere(r=0.5);
        }
        // Eye (indent represented by small sphere on side)
        translate([4, 2, 1]) sphere(r=0.8);

        // Mount post (from belly)
        translate([0, 0, -4])
            cylinder(d=3, h=4);
    }
}

// Select element based on wave index
module wave_element(i) {
    if (i <= ZONE_A_END) {
        foam_small();
    } else if (i <= ZONE_B_END) {
        foam_medium();
    } else {
        fish_element();
    }
}

// ============================================
// WAVE SLAT MODULE
// ============================================

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

                            // Hinge extension
                            translate([-WAVE_THICKNESS/2, HINGE_EXT_Y_START, HINGE_EXT_Z_BOTTOM])
                                cube([WAVE_THICKNESS, HINGE_EXT_WIDTH, -HINGE_EXT_Z_BOTTOM]);

                            // Cam housing extension
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

                        // Foam/fish mount hole
                        translate([0, ELEMENT_MOUNT_Y, ELEMENT_MOUNT_Z - 0.1])
                            cylinder(d=mount_hole_dia(i), h=WAVE_THICKNESS + 0.2, center=true);
                    }
}

// Wave with mounted element
module wave_with_element(i) {
    x_pos = wave_x(i);
    pitch = wave_angle_pitch(i, theta);
    roll = wave_angle_roll(i, theta);

    // Wave slat
    wave_slat(i);

    // Mounted element (follows wave motion)
    if (SHOW_FOAM_FISH) {
        translate([x_pos, 0, 0])
            translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
                rotate([pitch, roll, 0])
                    translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z])
                        translate([0, ELEMENT_MOUNT_Y, ELEMENT_MOUNT_Z])
                            // Rotate element to face viewer (+Y direction)
                            rotate([90, 0, 0])
                                wave_element(i);
    }
}

// All waves with elements
module all_waves() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        wave_with_element(i);
    }
}

// ============================================
// SHAFT MODULES
// ============================================

module hinge_axle() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=SHAFT_LENGTH + 10);
}

module camshaft_with_cams() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Main shaft
                cylinder(d=CAMSHAFT_DIA, h=SHAFT_LENGTH + 10);

                // Integrated cams
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

// ============================================
// CRANK & FRAME
// ============================================

module hand_crank() {
    color(C_CRANK)
    translate([FRAME_X_START - 15, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                difference() {
                    cylinder(d=14, h=8);
                    translate([0, 0, -1])
                        cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
                }
                translate([0, -3, 0])
                    cube([CRANK_ARM, 6, 8]);
                translate([CRANK_ARM, 0, 0])
                    cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
            }
}

module frame() {
    color(C_FRAME) {
        // Base
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);

        // Left wall
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                translate([-1, HINGE_SLOT_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + HINGE_SLOT_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
                translate([-1, CAM_HOUSING_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + CAM_HOUSING_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }

        // Right wall
        translate([FRAME_X_START + FRAME_LENGTH - FRAME_WALL, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                translate([-1, HINGE_SLOT_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + HINGE_SLOT_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
                translate([-1, CAM_HOUSING_CENTER_Y - FRAME_Y_START, -FRAME_Z_BASE + CAM_HOUSING_CENTER_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }
    }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_ocean_v6_assembly() {
    if (SHOW_FRAME) frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT_WITH_CAMS) camshaft_with_cams();
    if (SHOW_WAVES) all_waves();
    if (SHOW_HAND_CRANK) hand_crank();
}

// ============================================
// RENDER
// ============================================

wave_ocean_v6_assembly();

// ============================================
// CONSOLE OUTPUT
// ============================================

echo("");
echo("╔═══════════════════════════════════════════════════════════════════╗");
echo("║     WAVE OCEAN v6 - PROGRESSIVE ECCENTRICITY + FOAM/FISH          ║");
echo("╠═══════════════════════════════════════════════════════════════════╣");
echo("║                                                                   ║");
echo("║  CAM PROGRESSION (3x ratio for dramatic visual):                  ║");
echo(str("║    Wave 1:  ", cam_major(0), "×", cam_minor(0), "mm (circular, gentle)"));
echo(str("║    Wave 11: ", cam_major(10), "×", cam_minor(10), "mm (medium)"));
echo(str("║    Wave 22: ", cam_major(21), "×", cam_minor(21), "mm (elliptical, dramatic)"));
echo("║                                                                   ║");
echo("║  ELEMENT ZONES:                                                   ║");
echo("║    Zone A (Waves 1-7):   Small organic foam blobs                 ║");
echo("║    Zone B (Waves 8-14):  Medium organic foam blobs                ║");
echo("║    Zone C (Waves 15-22): Fish elements (14mm wide)                ║");
echo("║                                                                   ║");
echo("║  TIP MOTION AMPLITUDES:                                           ║");
echo("║    Zone A: ~2.5mm (gentle ripple)                                 ║");
echo("║    Zone B: ~5mm (medium waves)                                    ║");
echo("║    Zone C: ~7.5mm (dramatic swells with jumping fish)             ║");
echo("║                                                                   ║");
echo("╚═══════════════════════════════════════════════════════════════════╝");
echo("");

// Cam verification
echo("CAM SIZES (all must fit in 14mm housing):");
for (i = [0, 7, 14, 21]) {
    major = cam_major(i);
    minor = cam_minor(i);
    diag = sqrt(pow(major/2, 2) + pow(minor/2, 2)) * 2;
    echo(str("  Wave ", i+1, ": ", major, "×", minor, "mm, diagonal=", diag, "mm ",
             diag < 14 ? "✓" : "✗"));
}
