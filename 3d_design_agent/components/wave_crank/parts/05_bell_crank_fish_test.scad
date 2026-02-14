/*
 * BELL CRANK FISH ARC TEST
 *
 * Mechanism: L-shaped bell crank converts wave vertical rock
 *            to fish arc motion (toward/away from viewer)
 *
 * Tests:
 * - Bell crank geometry and motion
 * - Roller contact with wave top
 * - Fish arc swing
 * - Progressive amplitude across zones
 *
 * PART_SELECT:
 *   0 = Single wave with bell crank fish (Zone C - dramatic)
 *   1 = Zone comparison (A, B, C side by side)
 *   2 = Bell crank arm only (for print test)
 *   3 = Full mechanism exploded view
 */

PART_SELECT = 0;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE
// ============================================

SHOW_WAVE = true;
SHOW_BELL_CRANK = true;
SHOW_FISH = true;
SHOW_ROLLER = true;
SHOW_PIVOT_MOUNT = true;
SHOW_CAM = true;
SHOW_SHAFTS = true;
SHOW_FRAME = true;

// ============================================
// WAVE PARAMETERS (from v6)
// ============================================

WALL = 2;
WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

HINGE_SLOT_LENGTH = 8;
HINGE_SLOT_HEIGHT = 4;
HINGE_SLOT_CENTER_Y = 4;
HINGE_SLOT_CENTER_Z = 0;

HINGE_EXT_WIDTH = HINGE_SLOT_LENGTH + 2 * WALL;
HINGE_EXT_Y_START = HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2 - WALL;
HINGE_EXT_Z_BOTTOM = HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2 - WALL;

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

// ============================================
// CAM PARAMETERS (v6 - 3x ratio)
// ============================================

NUM_WAVES = 22;
PHASE_OFFSET = 360 / NUM_WAVES;
CAM_THICKNESS = 4;

function cam_major(i) = 9 + (i / (NUM_WAVES - 1)) * 3.5;
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 3;
function cam_phase(i) = i * PHASE_OFFSET;

// ============================================
// BELL CRANK PARAMETERS
// ============================================

// Pivot position (relative to wave baseline)
PIVOT_Y = 38;        // Middle-back of wave
PIVOT_Z = 24;        // Above wave top (wave top at Z=10)

// Arm lengths
ARM_VERTICAL = 12;   // Lb - pivot to roller
ARM_HORIZONTAL = 25; // La - pivot to fish

// Arm dimensions
ARM_WIDTH = 4;
ARM_THICKNESS = 3;

// Roller
ROLLER_DIA = 4;
ROLLER_LENGTH = 3;

// Rest angle (arm angled toward viewer)
REST_ANGLE = 30;     // Degrees from vertical

// Pin sizes
PIVOT_PIN_DIA = 3;
ROLLER_PIN_DIA = 2;
FISH_PIN_DIA = 2.5;

// ============================================
// ZONE DEFINITIONS
// ============================================

ZONE_A_END = 6;
ZONE_B_END = 13;

// ============================================
// LEVER ARM & MOTION CALCULATIONS
// ============================================

LEVER_ARM = CAM_HOUSING_CENTER_Y - HINGE_SLOT_CENTER_Y;  // 49mm

function wave_angle_pitch(i, angle) =
    atan2((cam_major(i) / 2) * sin(angle + cam_phase(i)), LEVER_ARM);

// Wave surface Z at roller contact point
function wave_z_at_roller(i, angle) =
    WAVE_BODY_HEIGHT + (PIVOT_Y - HINGE_SLOT_CENTER_Y) * tan(wave_angle_pitch(i, angle));

// Bell crank swing angle from wave motion
function bell_crank_swing(i, angle) =
    let(
        wave_z = wave_z_at_roller(i, angle),
        roller_rest_z = PIVOT_Z - ARM_VERTICAL,
        delta_z = wave_z - WAVE_BODY_HEIGHT,  // Wave surface deviation from rest
        swing_rad = asin(delta_z / ARM_VERTICAL)
    ) swing_rad;

// ============================================
// COLORS
// ============================================

C_WAVE = [0.75, 0.6, 0.45];
C_CAM = [0.8, 0.5, 0.2];
C_SHAFT = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.25, 0.2];
C_BELL_CRANK = [0.6, 0.4, 0.3];
C_ROLLER = [0.4, 0.4, 0.45];
C_FISH = [0.3, 0.5, 0.7];
C_PIVOT = [0.5, 0.5, 0.5];

$fn = 48;

// ============================================
// BELL CRANK MODULE
// ============================================

module bell_crank_arm() {
    color(C_BELL_CRANK)
    difference() {
        union() {
            // Vertical arm (pointing down)
            translate([-ARM_THICKNESS/2, -ARM_WIDTH/2, -ARM_VERTICAL])
                cube([ARM_THICKNESS, ARM_WIDTH, ARM_VERTICAL]);

            // Horizontal arm (angled, toward viewer at rest angle)
            rotate([REST_ANGLE, 0, 0])
                translate([-ARM_THICKNESS/2, -ARM_WIDTH/2, 0])
                    cube([ARM_THICKNESS, ARM_WIDTH, ARM_HORIZONTAL]);

            // Pivot hub
            rotate([0, 90, 0])
                cylinder(d=ARM_WIDTH + 2, h=ARM_THICKNESS, center=true);
        }

        // Pivot hole
        rotate([0, 90, 0])
            cylinder(d=PIVOT_PIN_DIA + 0.2, h=ARM_THICKNESS + 2, center=true);

        // Roller hole (at bottom of vertical arm)
        translate([0, 0, -ARM_VERTICAL])
            rotate([0, 90, 0])
                cylinder(d=ROLLER_PIN_DIA + 0.2, h=ARM_THICKNESS + 2, center=true);

        // Fish mount hole (at end of horizontal arm)
        rotate([REST_ANGLE, 0, 0])
            translate([0, 0, ARM_HORIZONTAL])
                rotate([0, 90, 0])
                    cylinder(d=FISH_PIN_DIA + 0.2, h=ARM_THICKNESS + 2, center=true);
    }
}

// ============================================
// ROLLER MODULE
// ============================================

module roller() {
    color(C_ROLLER)
    rotate([0, 90, 0])
        difference() {
            cylinder(d=ROLLER_DIA, h=ROLLER_LENGTH, center=true);
            cylinder(d=ROLLER_PIN_DIA, h=ROLLER_LENGTH + 1, center=true);
        }
}

// ============================================
// FISH MODULE (from v6)
// ============================================

module fish_body() {
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
    }
}

// ============================================
// PIVOT MOUNT MODULE
// ============================================

module pivot_mount() {
    color(C_PIVOT)
    difference() {
        // Block
        translate([-4, -4, -5])
            cube([8, 8, 10]);

        // Pivot hole (through X)
        rotate([0, 90, 0])
            cylinder(d=PIVOT_PIN_DIA + 0.2, h=20, center=true);

        // Mounting holes (for screws to wave bracket)
        translate([0, 0, -5])
            cylinder(d=2.5, h=6);
    }
}

// ============================================
// WAVE MODULE (from v6, simplified)
// ============================================

module wave_body_simple(i) {
    pitch = wave_angle_pitch(i, theta);

    color(C_WAVE)
    translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([pitch, 0, 0])
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

                        // Bell crank pivot bracket
                        translate([-WAVE_THICKNESS/2, PIVOT_Y - 3, WAVE_BODY_HEIGHT])
                            cube([WAVE_THICKNESS, 6, PIVOT_Z - WAVE_BODY_HEIGHT + 5]);
                    }

                    // Cutouts
                    translate([-WAVE_THICKNESS/2 - 1,
                               HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                               HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
                        cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);

                    translate([-WAVE_THICKNESS/2 - 1,
                               CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2,
                               CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2])
                        cube([WAVE_THICKNESS + 2, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE]);
                }
}

// ============================================
// BELL CRANK ASSEMBLY (animated)
// ============================================

module bell_crank_fish_assembly(i) {
    pitch = wave_angle_pitch(i, theta);

    // Calculate bell crank swing based on wave motion
    // Simplified: swing proportional to wave pitch
    swing = pitch * (ARM_HORIZONTAL / ARM_VERTICAL) * 0.8;  // 0.8 damping factor

    // Wave body (with bracket)
    if (SHOW_WAVE)
        wave_body_simple(i);

    // Bell crank mechanism (follows wave rotation for pivot position)
    translate([0, HINGE_SLOT_CENTER_Y, HINGE_SLOT_CENTER_Z])
        rotate([pitch, 0, 0])
            translate([0, -HINGE_SLOT_CENTER_Y, -HINGE_SLOT_CENTER_Z])
                translate([0, PIVOT_Y, PIVOT_Z]) {
                    // Pivot mount
                    if (SHOW_PIVOT_MOUNT)
                        pivot_mount();

                    // Bell crank arm (swings with wave input)
                    rotate([-swing, 0, 0]) {
                        if (SHOW_BELL_CRANK)
                            bell_crank_arm();

                        // Roller at bottom of vertical arm
                        if (SHOW_ROLLER)
                            translate([0, 0, -ARM_VERTICAL])
                                roller();

                        // Fish at end of horizontal arm
                        if (SHOW_FISH)
                            rotate([REST_ANGLE, 0, 0])
                                translate([0, 0, ARM_HORIZONTAL])
                                    rotate([0, 90, 0])
                                        rotate([0, 0, 90])
                                            fish_body();
                    }
                }
}

// ============================================
// CAM AND SHAFTS
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

module simple_frame() {
    color(C_FRAME) {
        translate([-25, -10, -15])
            difference() {
                cube([4, 80, 50]);
                translate([-1, HINGE_SLOT_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=HINGE_AXLE_DIA+0.4, h=6);
                translate([-1, CAM_HOUSING_CENTER_Y + 10, 15])
                    rotate([0, 90, 0]) cylinder(d=CAMSHAFT_DIA+0.4, h=6);
            }
        translate([21, -10, -15])
            difference() {
                cube([4, 80, 50]);
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

module single_wave_bell_crank_test(wave_index) {
    if (SHOW_FRAME) simple_frame();
    if (SHOW_SHAFTS) {
        hinge_axle();
        camshaft();
    }
    if (SHOW_CAM) cam_on_shaft(wave_index);
    bell_crank_fish_assembly(wave_index);
}

module zone_comparison_test() {
    spacing = 60;

    // Zone A - Wave 3
    translate([-spacing, 0, 0]) {
        single_wave_bell_crank_test(3);
        translate([0, -20, 35])
            color("white")
                linear_extrude(1)
                    text("Zone A", size=5, halign="center");
    }

    // Zone B - Wave 10
    translate([0, 0, 0]) {
        single_wave_bell_crank_test(10);
        translate([0, -20, 35])
            color("white")
                linear_extrude(1)
                    text("Zone B", size=5, halign="center");
    }

    // Zone C - Wave 18
    translate([spacing, 0, 0]) {
        single_wave_bell_crank_test(18);
        translate([0, -20, 35])
            color("white")
                linear_extrude(1)
                    text("Zone C", size=5, halign="center");
    }
}

module bell_crank_arm_print() {
    // Oriented for printing flat
    rotate([90, 0, 0])
        bell_crank_arm();
}

module exploded_view() {
    // Wave body
    wave_body_simple(18);

    // Pivot mount (exploded up)
    translate([0, PIVOT_Y, PIVOT_Z + 20])
        pivot_mount();

    // Bell crank arm (exploded further)
    translate([0, PIVOT_Y, PIVOT_Z + 40])
        bell_crank_arm();

    // Roller (exploded)
    translate([0, PIVOT_Y, PIVOT_Z + 40 - ARM_VERTICAL - 10])
        roller();

    // Fish (exploded)
    translate([0, PIVOT_Y + 30, PIVOT_Z + 60])
        rotate([0, 90, 0])
            rotate([0, 0, 90])
                fish_body();

    // Labels
    translate([15, PIVOT_Y, PIVOT_Z + 20])
        color("black") linear_extrude(1) text("Pivot Mount", size=3);
    translate([15, PIVOT_Y, PIVOT_Z + 40])
        color("black") linear_extrude(1) text("Bell Crank", size=3);
    translate([15, PIVOT_Y, PIVOT_Z + 40 - ARM_VERTICAL - 10])
        color("black") linear_extrude(1) text("Roller", size=3);
    translate([15, PIVOT_Y + 30, PIVOT_Z + 60])
        color("black") linear_extrude(1) text("Fish", size=3);
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    echo("=== SINGLE WAVE WITH BELL CRANK FISH (Zone C) ===");
    single_wave_bell_crank_test(18);
}
else if (PART_SELECT == 1) {
    echo("=== ZONE COMPARISON (A, B, C) ===");
    zone_comparison_test();
}
else if (PART_SELECT == 2) {
    echo("=== BELL CRANK ARM (Print Orientation) ===");
    bell_crank_arm_print();
}
else if (PART_SELECT == 3) {
    echo("=== EXPLODED VIEW ===");
    exploded_view();
}

// ============================================
// DEBUG OUTPUT
// ============================================

echo("");
echo("╔═══════════════════════════════════════════════════════════════════╗");
echo("║           BELL CRANK FISH ARC TEST                                ║");
echo("╠═══════════════════════════════════════════════════════════════════╣");
echo("║                                                                   ║");
echo("║  MECHANISM: L-shaped bell crank                                   ║");
echo("║  MOTION: Wave vertical → Fish arc (toward/away viewer)            ║");
echo("║                                                                   ║");
echo(str("║  Pivot position: Y=", PIVOT_Y, "mm, Z=", PIVOT_Z, "mm"));
echo(str("║  Vertical arm (Lb): ", ARM_VERTICAL, "mm"));
echo(str("║  Horizontal arm (La): ", ARM_HORIZONTAL, "mm"));
echo(str("║  Amplification ratio: ", ARM_HORIZONTAL/ARM_VERTICAL, "x"));
echo("║                                                                   ║");
echo("╚═══════════════════════════════════════════════════════════════════╝");
echo("");

// Motion analysis
echo("FISH ARC SWING BY ZONE:");
for (i = [3, 10, 18]) {
    zone = i <= ZONE_A_END ? "A" : (i <= ZONE_B_END ? "B" : "C");
    pitch_max = wave_angle_pitch(i, 90);  // Maximum pitch
    swing_max = pitch_max * (ARM_HORIZONTAL / ARM_VERTICAL) * 0.8;
    echo(str("  Wave ", i+1, " (Zone ", zone, "): pitch=", pitch_max, "° → fish swing=", swing_max, "°"));
}

echo("");
echo(str("Current angle: ", theta, "°"));
echo("");
echo("VISUAL CHECKS:");
echo("  [ ] Fish swings toward viewer as wave crests");
echo("  [ ] Fish swings away as wave troughs");
echo("  [ ] Roller maintains contact with wave surface");
echo("  [ ] Progressive swing amplitude (C > B > A)");
echo("  [ ] No collision between fish and wave body");
