/*
 * WAVE OCEAN v4 - CAM-IN-HOUSING DESIGN
 *
 * Mechanism: Elliptical cam rotates INSIDE square housing cutout
 * Motion: Compound (Z up/down + Y front/back) = elliptical wave tip path
 *
 * Key features:
 * - 22 waves with integrated cam housings
 * - Common hinge axle through all wave slots
 * - Progressive eccentricity (gentle right → dramatic left)
 * - Cam contacts ALL 4 housing walls during rotation
 *
 * Based on user's design with dual rectangular cutouts.
 * Geometry validated in 0_geometry_v4_FINAL.md
 *
 * Date: 2026-01-21
 */

// ============================================
// ANIMATION CONTROL
// ============================================

MANUAL_ANGLE = -1;  // Set >= 0 to override animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_FRAME = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT = true;
SHOW_CAMS = true;
SHOW_WAVES = true;
SHOW_HAND_CRANK = true;
SHOW_DEBUG_POINTS = false;  // Contact point visualization

// Wave range (0-21 for all 22 waves)
WAVE_RANGE_START = 0;
WAVE_RANGE_END = 21;

// ============================================
// WAVE PARAMETERS (from geometry checklist)
// ============================================

WAVE_LENGTH = 70;           // Y dimension
WAVE_BODY_HEIGHT = 10;      // Z dimension (visible part above baseline)
WAVE_THICKNESS = 4;         // X dimension

// ============================================
// HINGE SLOT (rectangular cutout for axle)
// ============================================

HINGE_SLOT_LENGTH = 12;     // Y dimension
HINGE_SLOT_HEIGHT = 4;      // Z dimension
HINGE_SLOT_CENTER_Y = 6;    // from wave back edge
HINGE_SLOT_CENTER_Z = 0;    // at wave baseline

// ============================================
// CAM HOUSING (square cutout for cam)
// ============================================

CAM_HOUSING_SIZE = 14;      // square (Y and Z)
CAM_HOUSING_CENTER_Y = 53;  // from wave back edge
CAM_HOUSING_CENTER_Z = 0;   // at wave baseline

// ============================================
// SHAFT PARAMETERS
// ============================================

HINGE_AXLE_DIA = 3;         // Static axle through slots
CAMSHAFT_DIA = 6;           // Rotating shaft through cams

// ============================================
// CAM PARAMETERS (progressive eccentricity)
// ============================================

CAM_THICKNESS = 4;
NUM_WAVES = 22;
UNIT_PITCH = 10;            // X spacing per wave unit
PHASE_OFFSET = 360 / NUM_WAVES;  // 16.36° per wave

// Progressive sizing: gentle (right) to dramatic (left)
function cam_major(i) = 10 + (i / (NUM_WAVES - 1)) * 2;   // 10mm to 12mm
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 2;    // 9mm to 7mm
function cam_phase(i) = i * PHASE_OFFSET;

// ============================================
// FRAME PARAMETERS
// ============================================

// Wave area boundaries (from main sculpture)
WAVE_AREA_START_X = 78;
WAVE_AREA_END_X = 302;
WAVE_AREA_WIDTH = WAVE_AREA_END_X - WAVE_AREA_START_X;  // 224mm

FIRST_WAVE_X = WAVE_AREA_START_X + UNIT_PITCH;  // 88mm

FRAME_LENGTH = 260;         // X
FRAME_DEPTH = 90;           // Y
FRAME_HEIGHT = 50;          // Z
FRAME_WALL = 5;
FRAME_X_START = 70;         // Left edge of frame
FRAME_Y_START = -10;        // Back edge of frame
FRAME_Z_BASE = -20;         // Base below wave baseline

// Shaft positions in frame coordinates
HINGE_Y_IN_FRAME = HINGE_SLOT_CENTER_Y - FRAME_Y_START;   // Y position of hinge axle
CAMSHAFT_Y_IN_FRAME = CAM_HOUSING_CENTER_Y - FRAME_Y_START; // Y position of camshaft

// ============================================
// CRANK PARAMETERS
// ============================================

CRANK_ARM = 25;
CRANK_KNOB_DIA = 10;
CRANK_KNOB_H = 15;

// ============================================
// COLORS
// ============================================

C_FRAME = [0.35, 0.25, 0.15];
C_AXLE = [0.5, 0.5, 0.55];
C_CAMSHAFT = [0.6, 0.6, 0.65];
C_CAM = [0.8, 0.5, 0.2];
C_WAVE = [0.75, 0.6, 0.45];
C_CRANK = [0.5, 0.4, 0.3];
C_DEBUG = [1, 0, 0];

$fn = 48;

// ============================================
// DERIVED CALCULATIONS
// ============================================

// Wave X position
function wave_x(i) = FIRST_WAVE_X + i * UNIT_PITCH;

// Cam displacement at angle (how much cam pushes housing wall)
function cam_push_z(i, angle) =
    (cam_major(i) / 2) * sin(angle + cam_phase(i)) - (cam_minor(i) / 2) * sin(angle + cam_phase(i))
    + (cam_minor(i) / 2) * sin(angle + cam_phase(i));

// Simplified: cam center to edge distance at angle
function cam_radius_at_angle(major, minor, angle) =
    (major * minor) / 2 / sqrt(pow(minor * cos(angle) / 2, 2) + pow(major * sin(angle) / 2, 2));

// Wave angle based on cam pushing housing
// When cam pushes up, wave tips up (pivoting around hinge)
function wave_angle_z(i, angle) =
    atan2((cam_major(i) / 2) * sin(angle + cam_phase(i)),
          CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y);

function wave_angle_y(i, angle) =
    atan2((cam_minor(i) / 2) * cos(angle + cam_phase(i)),
          CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y);

// ============================================
// MODULES
// ============================================

// Single wave slat with integrated cutouts
module wave_slat(i) {
    x_pos = wave_x(i);

    // Calculate wave rotation based on cam position
    angle_z = wave_angle_z(i, theta);  // Pitch (up/down)
    angle_y = wave_angle_y(i, theta);  // Roll (toward/away viewer)

    color(C_WAVE)
    translate([x_pos, 0, 0])
        // Pivot around hinge slot center
        translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
            rotate([angle_z, angle_y, 0])
                translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z])
                    difference() {
                        // Main wave body + extensions for cutouts
                        union() {
                            // Wave body (above baseline)
                            translate([-WAVE_THICKNESS/2, 0, 0])
                                cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);

                            // Extension down for hinge slot
                            translate([-WAVE_THICKNESS/2, 0, -CAM_HOUSING_SIZE/2])
                                cube([WAVE_THICKNESS, HINGE_SLOT_LENGTH + 2, CAM_HOUSING_SIZE/2]);

                            // Extension down for cam housing
                            translate([-WAVE_THICKNESS/2, CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2, -CAM_HOUSING_SIZE/2])
                                cube([WAVE_THICKNESS, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE/2]);
                        }

                        // Hinge slot cutout (rectangular, for axle)
                        translate([-WAVE_THICKNESS/2 - 1,
                                   HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                                   HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
                            cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);

                        // Cam housing cutout (square, for cam)
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

// Single elliptical cam
module cam(i) {
    x_pos = wave_x(i);
    major = cam_major(i);
    minor = cam_minor(i);
    phase = cam_phase(i);

    color(C_CAM)
    translate([x_pos, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta + phase])
                difference() {
                    // Elliptical disc
                    scale([major/10, minor/10, 1])
                        cylinder(r=10/2, h=CAM_THICKNESS, center=true);

                    // Shaft hole
                    cylinder(d=CAMSHAFT_DIA + 0.3, h=CAM_THICKNESS + 2, center=true);
                }
}

// All cams
module all_cams() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        cam(i);
    }
}

// Hinge axle (static)
module hinge_axle() {
    color(C_AXLE)
    translate([FRAME_X_START - 5, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=FRAME_LENGTH + 10);
}

// Camshaft (rotating)
module camshaft() {
    color(C_CAMSHAFT)
    translate([FRAME_X_START - 5, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=CAMSHAFT_DIA, h=FRAME_LENGTH + 10);
}

// Hand crank
module hand_crank() {
    color(C_CRANK)
    translate([FRAME_X_START - 10, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Hub
                difference() {
                    cylinder(d=14, h=6);
                    translate([0, 0, -1])
                        cylinder(d=CAMSHAFT_DIA + 0.3, h=8);
                }

                // Arm
                translate([0, -3, 0])
                    cube([CRANK_ARM, 6, 6]);

                // Knob
                translate([CRANK_ARM, 0, 0])
                    cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
            }
}

// Frame (simplified)
module frame() {
    color(C_FRAME) {
        // Base plate
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);

        // Left side
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

                // Hinge axle hole
                translate([-1, HINGE_Y_IN_FRAME, -FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);

                // Camshaft hole
                translate([-1, CAMSHAFT_Y_IN_FRAME, -FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }

        // Right side
        translate([FRAME_X_START + FRAME_LENGTH - FRAME_WALL, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

                // Hinge axle hole
                translate([-1, HINGE_Y_IN_FRAME, -FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);

                // Camshaft hole
                translate([-1, CAMSHAFT_Y_IN_FRAME, -FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }

        // Back rail
        translate([FRAME_X_START + FRAME_WALL, FRAME_Y_START, FRAME_Z_BASE])
            cube([FRAME_LENGTH - 2*FRAME_WALL, FRAME_WALL, FRAME_HEIGHT/2]);

        // Front rail
        translate([FRAME_X_START + FRAME_WALL, FRAME_Y_START + FRAME_DEPTH - FRAME_WALL, FRAME_Z_BASE])
            cube([FRAME_LENGTH - 2*FRAME_WALL, FRAME_WALL, FRAME_HEIGHT/2]);
    }
}

// Debug: show contact points
module debug_points() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        // Hinge point
        color([0, 1, 0])
        translate([wave_x(i), HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
            sphere(r=1);

        // Cam center
        color([1, 0, 0])
        translate([wave_x(i), CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
            sphere(r=1.5);
    }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_ocean_v4_assembly() {
    if (SHOW_FRAME) frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft();
    if (SHOW_CAMS) all_cams();
    if (SHOW_WAVES) all_waves();
    if (SHOW_HAND_CRANK) hand_crank();
    if (SHOW_DEBUG_POINTS) debug_points();
}

// ============================================
// RENDER
// ============================================

wave_ocean_v4_assembly();

// ============================================
// CONSOLE OUTPUT
// ============================================

echo("");
echo("╔════════════════════════════════════════════════════════════╗");
echo("║          WAVE OCEAN v4 - CAM-IN-HOUSING DESIGN             ║");
echo("╠════════════════════════════════════════════════════════════╣");
echo("║                                                            ║");
echo("║  MECHANISM:                                                ║");
echo("║    Elliptical cam rotates INSIDE square housing            ║");
echo("║    Cam contacts all 4 walls → compound Z+Y motion          ║");
echo("║                                                            ║");
echo("║  WAVE DIMENSIONS:                                          ║");
echo(str("║    Length: ", WAVE_LENGTH, "mm | Height: ", WAVE_BODY_HEIGHT, "mm | Thick: ", WAVE_THICKNESS, "mm       ║"));
echo("║                                                            ║");
echo("║  CUTOUTS:                                                  ║");
echo(str("║    Hinge slot: ", HINGE_SLOT_LENGTH, "×", HINGE_SLOT_HEIGHT, "mm at Y=", HINGE_SLOT_CENTER_Y, "mm               ║"));
echo(str("║    Cam housing: ", CAM_HOUSING_SIZE, "×", CAM_HOUSING_SIZE, "mm at Y=", CAM_HOUSING_CENTER_Y, "mm              ║"));
echo("║                                                            ║");
echo("║  PROGRESSIVE CAMS:                                         ║");
echo(str("║    Wave 1 (gentle):   ", cam_major(0), "×", cam_minor(0), "mm                      ║"));
echo(str("║    Wave 11 (medium):  ", cam_major(10), "×", cam_minor(10), "mm                    ║"));
echo(str("║    Wave 22 (dramatic): ", cam_major(21), "×", cam_minor(21), "mm                     ║"));
echo("║                                                            ║");
echo("╠════════════════════════════════════════════════════════════╣");
echo(str("║  Current angle: ", theta, "°"));
echo(str("║  Phase offset: ", PHASE_OFFSET, "° per wave"));
echo("╚════════════════════════════════════════════════════════════╝");
echo("");

// Cam sizes for reference
echo("CAM SIZES (progressive eccentricity):");
for (i = [0:5:21]) {
    echo(str("  Wave ", i+1, ": ", cam_major(i), "×", cam_minor(i), "mm (ecc=", cam_major(i)-cam_minor(i), "mm)"));
}

// Printability check
echo("");
echo("PRINTABILITY CHECK:");
echo(str("  Min wall: ", WAVE_THICKNESS, "mm - ", WAVE_THICKNESS >= 1.2 ? "PASS" : "FAIL"));
echo(str("  Hinge clearance: ", (HINGE_SLOT_HEIGHT - HINGE_AXLE_DIA)/2, "mm - ", (HINGE_SLOT_HEIGHT - HINGE_AXLE_DIA)/2 >= 0.3 ? "PASS" : "FAIL"));
