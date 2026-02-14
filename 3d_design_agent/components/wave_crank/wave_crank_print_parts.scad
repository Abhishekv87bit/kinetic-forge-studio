/*
 * WAVE CRANK MECHANISM - PRINT PARTS
 *
 * Set PART_SELECT to export individual parts for printing
 */

// PART SELECTION
// 0 = Assembly view (not for printing)
// 1 = Base frame
// 2 = Crankshaft (printed horizontally)
// 3 = Wave segment 1
// 4 = Wave segment 2
// 5 = Wave segment 3
// 6 = Guide rail (print 2x)
// 7 = Belt pulley
// 8 = Hand crank
PART_SELECT = 0;

// ============================================
// PARAMETERS (same as standalone)
// ============================================

CRANK_SHAFT_DIA = 8;
CRANK_SHAFT_LEN = 90;
CRANK_SHAFT_HOLE = 8.3;

THROW_ECCENTRICITY = 8;
THROW_DIAMETER = 10;
THROW_WIDTH = 15;

THROW_1_Z = 0;
THROW_2_Z = 25;
THROW_3_Z = 50;

SEGMENT_WIDTH = 70;
SEGMENT_DEPTH = 40;
SEGMENT_THICKNESS = 3;
SLOT_WIDTH = 12;
SLOT_LENGTH = 30;

GUIDE_WIDTH = 5;
GUIDE_LENGTH = 90;
GUIDE_HEIGHT = 20;

BASE_WIDTH = 100;
BASE_DEPTH = 60;
BASE_THICKNESS = 5;

PULLEY_OD = 32;
PULLEY_WIDTH = 8;

BEARING_OD = 16;
BEARING_HEIGHT = 8;

$fn = 64;

// ============================================
// PRINT-ORIENTED MODULES
// ============================================

// Base frame - print flat
module print_base_frame() {
    difference() {
        union() {
            // Main plate
            cube([BASE_WIDTH, BASE_DEPTH, BASE_THICKNESS]);
            // Bearing mount
            translate([BASE_WIDTH/2, BASE_DEPTH/2, BASE_THICKNESS])
                cylinder(d=BEARING_OD, h=BEARING_HEIGHT);
        }
        // Shaft hole through everything
        translate([BASE_WIDTH/2, BASE_DEPTH/2, -1])
            cylinder(d=CRANK_SHAFT_HOLE, h=BASE_THICKNESS + BEARING_HEIGHT + 2);
    }
}

// Crankshaft - print horizontally (rotated 90°)
module print_crankshaft() {
    rotate([0, 90, 0]) {
        // Main shaft
        cylinder(d=CRANK_SHAFT_DIA, h=CRANK_SHAFT_LEN);

        // Throw 1 at Z=7.5 (center of throw)
        translate([THROW_ECCENTRICITY, 0, 7.5])
            cylinder(d=THROW_DIAMETER, h=THROW_WIDTH, center=true);
        // Web 1
        translate([0, 0, 0])
            linear_extrude(height=3)
                hull() {
                    circle(d=CRANK_SHAFT_DIA);
                    translate([THROW_ECCENTRICITY, 0]) circle(d=THROW_DIAMETER);
                }

        // Throw 2 at Z=32.5 (120° offset in XY)
        rotate([0, 0, 120])
            translate([THROW_ECCENTRICITY, 0, 32.5])
                cylinder(d=THROW_DIAMETER, h=THROW_WIDTH, center=true);
        translate([0, 0, 25])
            rotate([0, 0, 120])
                linear_extrude(height=3)
                    hull() {
                        circle(d=CRANK_SHAFT_DIA);
                        translate([THROW_ECCENTRICITY, 0]) circle(d=THROW_DIAMETER);
                    }

        // Throw 3 at Z=57.5 (240° offset in XY)
        rotate([0, 0, 240])
            translate([THROW_ECCENTRICITY, 0, 57.5])
                cylinder(d=THROW_DIAMETER, h=THROW_WIDTH, center=true);
        translate([0, 0, 50])
            rotate([0, 0, 240])
                linear_extrude(height=3)
                    hull() {
                        circle(d=CRANK_SHAFT_DIA);
                        translate([THROW_ECCENTRICITY, 0]) circle(d=THROW_DIAMETER);
                    }
    }
}

// Wave segment - print flat
module print_wave_segment() {
    difference() {
        cube([SEGMENT_WIDTH, SEGMENT_DEPTH, SEGMENT_THICKNESS]);
        // Slot centered
        translate([SEGMENT_WIDTH/2 - SLOT_WIDTH/2, SEGMENT_DEPTH/2 - SLOT_LENGTH/2, -1])
            cube([SLOT_WIDTH, SLOT_LENGTH, SEGMENT_THICKNESS + 2]);
    }
}

// Guide rail - print standing
module print_guide_rail() {
    cube([GUIDE_WIDTH, GUIDE_HEIGHT, GUIDE_LENGTH]);
}

// Belt pulley
module print_belt_pulley() {
    difference() {
        cylinder(d=PULLEY_OD, h=PULLEY_WIDTH);
        // Shaft hole
        translate([0, 0, -1])
            cylinder(d=CRANK_SHAFT_HOLE, h=PULLEY_WIDTH + 2);
        // Belt groove
        translate([0, 0, 2])
            difference() {
                cylinder(d=PULLEY_OD + 1, h=4);
                cylinder(d=PULLEY_OD - 4, h=4);
            }
    }
}

// Hand crank
module print_hand_crank() {
    crank_arm = 25;

    // Flat on print bed
    union() {
        // Hub
        difference() {
            cylinder(d=CRANK_SHAFT_DIA + 6, h=5);
            translate([0, 0, -1])
                cylinder(d=CRANK_SHAFT_DIA + 0.3, h=7);  // Tight fit on shaft
        }
        // Arm
        translate([0, -4, 0])
            cube([crank_arm, 8, 5]);
        // Knob base
        translate([crank_arm, 0, 0])
            cylinder(d=12, h=18);
    }
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    // Assembly preview - not for printing
    echo("Assembly view - not for printing. Set PART_SELECT 1-8.");

    color([0.3, 0.3, 0.3]) translate([-BASE_WIDTH/2, -BASE_DEPTH/2, -30])
        print_base_frame();

    color([0.7, 0.7, 0.7]) translate([0, 0, -20])
        rotate([0, -90, 0]) translate([-45, 0, 0])
            print_crankshaft();

    for (i = [0:2]) {
        color([0.3, 0.5, 0.8])
            translate([-SEGMENT_WIDTH/2, -SEGMENT_DEPTH/2, i*25])
                print_wave_segment();
    }
}
else if (PART_SELECT == 1) {
    echo("Part 1: Base Frame");
    print_base_frame();
}
else if (PART_SELECT == 2) {
    echo("Part 2: Crankshaft (print horizontally with supports)");
    print_crankshaft();
}
else if (PART_SELECT == 3) {
    echo("Part 3: Wave Segment 1");
    print_wave_segment();
}
else if (PART_SELECT == 4) {
    echo("Part 4: Wave Segment 2");
    print_wave_segment();
}
else if (PART_SELECT == 5) {
    echo("Part 5: Wave Segment 3");
    print_wave_segment();
}
else if (PART_SELECT == 6) {
    echo("Part 6: Guide Rail (print 2x)");
    print_guide_rail();
}
else if (PART_SELECT == 7) {
    echo("Part 7: Belt Pulley");
    print_belt_pulley();
}
else if (PART_SELECT == 8) {
    echo("Part 8: Hand Crank");
    print_hand_crank();
}
