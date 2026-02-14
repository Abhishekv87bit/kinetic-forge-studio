/*
 * SINGLE WAVE + FOAM/FISH TEST
 *
 * Tests:
 * - Wave motion with mounted element
 * - Element visibility from viewer direction
 * - Foam/fish riding the wave motion
 * - Mount hole and post fit
 *
 * PART_SELECT:
 *   0 = Wave 1 (Zone A - small foam) - gentlest motion
 *   1 = Wave 11 (Zone B - medium foam) - medium motion
 *   2 = Wave 22 (Zone C - fish) - most dramatic motion
 *   3 = All three side by side for comparison
 */

PART_SELECT = 3;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE
// ============================================

SHOW_WAVE = true;
SHOW_ELEMENT = true;
SHOW_CAM = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT = true;
SHOW_FRAME = true;

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
// HINGE SLOT
// ============================================

HINGE_SLOT_LENGTH = 8;
HINGE_SLOT_HEIGHT = 4;
HINGE_SLOT_CENTER_Y = 4;
HINGE_SLOT_CENTER_Z = 0;

HINGE_EXT_WIDTH = HINGE_SLOT_LENGTH + 2 * WALL;
HINGE_EXT_Y_START = HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2 - WALL;
HINGE_EXT_Z_BOTTOM = HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2 - WALL;

// ============================================
// CAM HOUSING
// ============================================

CAM_HOUSING_SIZE = 14;
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

CAM_EXT_WIDTH = CAM_HOUSING_SIZE + 2 * WALL;
CAM_EXT_Y_START = CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2 - WALL;
CAM_EXT_Z_BOTTOM = CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2 - WALL;

// ============================================
// SHAFTS
// ============================================

HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;

// ============================================
// CAM PARAMETERS - CORRECTED 3x RATIO
// ============================================

NUM_WAVES = 22;
PHASE_OFFSET = 360 / NUM_WAVES;
CAM_THICKNESS = 4;

// v6 formulas: 3x ratio
function cam_major(i) = 9 + (i / (NUM_WAVES - 1)) * 3.5;   // 9mm to 12.5mm
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 3;     // 9mm to 6mm
function cam_phase(i) = i * PHASE_OFFSET;

// ============================================
// ELEMENT PARAMETERS
// ============================================

ELEMENT_MOUNT_Y = 35;
ELEMENT_MOUNT_Z = WAVE_BODY_HEIGHT;

ZONE_A_END = 6;
ZONE_B_END = 13;

function mount_post_dia(i) = i <= ZONE_A_END ? 2 : i <= ZONE_B_END ? 2.5 : 3;
function mount_hole_dia(i) = mount_post_dia(i) + 0.1;

// ============================================
// COLORS
// ============================================

C_WAVE = [0.75, 0.6, 0.45];
C_CAM = [0.8, 0.5, 0.2];
C_SHAFT = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.25, 0.2];
C_FOAM = [0.95, 0.98, 1.0];
C_FISH = [0.3, 0.5, 0.7];

$fn = 48;

// ============================================
// CALCULATIONS
// ============================================

LEVER_ARM = CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y;

function wave_angle_pitch(i, angle) =
    atan2((cam_major(i) / 2) * sin(angle + cam_phase(i)), LEVER_ARM);

function wave_angle_roll(i, angle) =
    atan2((cam_minor(i) / 2) * cos(angle + cam_phase(i)), LEVER_ARM);

// ============================================
// ELEMENT MODULES
// ============================================

module foam_small() {
    color(C_FOAM)
    union() {
        hull() {
            translate([0, 0, 2]) sphere(r=3);
            translate([-2, 0, 4]) sphere(r=2);
            translate([2, 0, 3.5]) sphere(r=2.5);
            translate([0, 0, 5]) sphere(r=1.5);
        }
        translate([0, 0, -3])
            cylinder(d=2, h=3.5);
    }
}

module foam_medium() {
    color(C_FOAM)
    union() {
        hull() {
            translate([0, 0, 3]) sphere(r=4);
            translate([-3, 0, 5]) sphere(r=3);
            translate([3, 0, 4]) sphere(r=3);
            translate([0, 0, 7]) sphere(r=2);
            translate([-1, 0, 8]) sphere(r=1.5);
        }
        translate([0, 0, -4])
            cylinder(d=2.5, h=4.5);
    }
}

module fish_element() {
    color(C_FISH)
    union() {
        // Body
        hull() {
            translate([5, 0, 0]) sphere(r=3);
            translate([0, 0, 0]) scale([1, 0.6, 1]) sphere(r=4);
            translate([-5, 0, 0]) sphere(r=2);
        }
        // Tail
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
        // Eye
        translate([4, 2.5, 1]) sphere(r=0.8);
        // Mount post
        translate([0, 0, -5])
            cylinder(d=3, h=5.5);
    }
}

module wave_element(i) {
    if (i <= ZONE_A_END) foam_small();
    else if (i <= ZONE_B_END) foam_medium();
    else fish_element();
}

// ============================================
// WAVE MODULE
// ============================================

module wave_slat_with_element(i) {
    pitch = wave_angle_pitch(i, theta);
    roll = wave_angle_roll(i, theta);

    translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([pitch, roll, 0])
            translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z]) {
                // Wave body
                if (SHOW_WAVE)
                color(C_WAVE)
                difference() {
                    union() {
                        translate([-WAVE_THICKNESS/2, 0, 0])
                            cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);
                        translate([-WAVE_THICKNESS/2, HINGE_EXT_Y_START, HINGE_EXT_Z_BOTTOM])
                            cube([WAVE_THICKNESS, HINGE_EXT_WIDTH, -HINGE_EXT_Z_BOTTOM]);
                        translate([-WAVE_THICKNESS/2, CAM_EXT_Y_START, CAM_EXT_Z_BOTTOM])
                            cube([WAVE_THICKNESS, CAM_EXT_WIDTH, -CAM_EXT_Z_BOTTOM]);
                    }
                    translate([-WAVE_THICKNESS/2 - 1,
                               HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                               HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
                        cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);
                    translate([-WAVE_THICKNESS/2 - 1,
                               CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2,
                               CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2])
                        cube([WAVE_THICKNESS + 2, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE]);
                    translate([0, ELEMENT_MOUNT_Y, ELEMENT_MOUNT_Z - 0.1])
                        cylinder(d=mount_hole_dia(i), h=WAVE_THICKNESS + 0.2, center=true);
                }

                // Mounted element
                if (SHOW_ELEMENT)
                translate([0, ELEMENT_MOUNT_Y, ELEMENT_MOUNT_Z])
                    rotate([90, 0, 0])
                        wave_element(i);
            }
}

// ============================================
// CAM MODULE
// ============================================

module cam_on_shaft(i) {
    major = cam_major(i);
    minor = cam_minor(i);
    phase = cam_phase(i);

    color(C_CAM)
    translate([0, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta + phase])
                scale([major/10, minor/10, 1])
                    cylinder(r=5, h=CAM_THICKNESS, center=true);
}

// ============================================
// SHAFT MODULES
// ============================================

module hinge_axle() {
    color(C_SHAFT)
    translate([-30, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=60);
}

module camshaft() {
    color(C_SHAFT)
    translate([-30, CAM_HOUSING_CENTER_Y, CAM_HOUSING_CENTER_Z])
        rotate([0, 90, 0])
            cylinder(d=CAMSHAFT_DIA, h=60);
}

// ============================================
// FRAME
// ============================================

module simple_frame() {
    color(C_FRAME) {
        translate([-25, -10, -15])
            difference() {
                cube([4, 80, 35]);
                translate([-1, HINGE_SLOT_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=HINGE_AXLE_DIA+0.4, h=6);
                translate([-1, CAM_HOUSING_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=CAMSHAFT_DIA+0.4, h=6);
            }
        translate([21, -10, -15])
            difference() {
                cube([4, 80, 35]);
                translate([-1, HINGE_SLOT_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=HINGE_AXLE_DIA+0.4, h=6);
                translate([-1, CAM_HOUSING_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=CAMSHAFT_DIA+0.4, h=6);
            }
        translate([-25, -10, -15])
            cube([50, 80, 4]);
    }
}

// ============================================
// TEST ASSEMBLIES
// ============================================

module single_wave_test(wave_index) {
    if (SHOW_FRAME) simple_frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft();
    if (SHOW_CAM) cam_on_shaft(wave_index);
    wave_slat_with_element(wave_index);
}

module comparison_test() {
    spacing = 60;

    // Wave 1 (Zone A - small foam)
    translate([-spacing, 0, 0]) {
        single_wave_test(0);
        translate([0, -20, 20])
            color("white")
                linear_extrude(1)
                    text("Wave 1", size=5, halign="center");
    }

    // Wave 11 (Zone B - medium foam)
    translate([0, 0, 0]) {
        single_wave_test(10);
        translate([0, -20, 20])
            color("white")
                linear_extrude(1)
                    text("Wave 11", size=5, halign="center");
    }

    // Wave 22 (Zone C - fish)
    translate([spacing, 0, 0]) {
        single_wave_test(21);
        translate([0, -20, 20])
            color("white")
                linear_extrude(1)
                    text("Wave 22", size=5, halign="center");
    }
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    echo("=== WAVE 1 TEST (Zone A - Small Foam) ===");
    single_wave_test(0);
}
else if (PART_SELECT == 1) {
    echo("=== WAVE 11 TEST (Zone B - Medium Foam) ===");
    single_wave_test(10);
}
else if (PART_SELECT == 2) {
    echo("=== WAVE 22 TEST (Zone C - Fish) ===");
    single_wave_test(21);
}
else if (PART_SELECT == 3) {
    echo("=== COMPARISON TEST (All Three) ===");
    comparison_test();
}

// ============================================
// DEBUG OUTPUT
// ============================================

echo("");
echo("=========================================================");
echo("     SINGLE WAVE + ELEMENT TEST");
echo("=========================================================");
echo("");
echo("CAM PROGRESSION (3x ratio):");
echo(str("  Wave 1:  ", cam_major(0), " x ", cam_minor(0), "mm (eccentricity: ", cam_major(0)-cam_minor(0), "mm)"));
echo(str("  Wave 11: ", cam_major(10), " x ", cam_minor(10), "mm (eccentricity: ", cam_major(10)-cam_minor(10), "mm)"));
echo(str("  Wave 22: ", cam_major(21), " x ", cam_minor(21), "mm (eccentricity: ", cam_major(21)-cam_minor(21), "mm)"));
echo("");
echo("ELEMENT ZONES:");
echo("  Zone A (0-6):   Small organic foam");
echo("  Zone B (7-13):  Medium organic foam");
echo("  Zone C (14-21): Fish elements");
echo("");
echo(str("Current angle: ", theta, " deg"));
echo(str("Wave 1 pitch:  ", wave_angle_pitch(0, theta), " deg"));
echo(str("Wave 11 pitch: ", wave_angle_pitch(10, theta), " deg"));
echo(str("Wave 22 pitch: ", wave_angle_pitch(21, theta), " deg"));
echo("");
echo("VISUAL CHECKS:");
echo("  [ ] Elements face viewer (+Y direction)");
echo("  [ ] Elements rise/fall with wave motion");
echo("  [ ] Progressive amplitude visible (Wave 22 > Wave 11 > Wave 1)");
echo("  [ ] Fish is larger than foam blobs");
echo("  [ ] No collision between element and cam housing");
echo("");
