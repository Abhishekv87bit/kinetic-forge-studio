/*
 * WAVE OCEAN v5 - PRINT PARTS
 *
 * PART SELECTION:
 *   0  = Full plate preview
 *   1  = Single wave slat (print 22x)
 *   2  = ALL 22 waves on plate
 *   3  = Hinge axle (simple cylinder)
 *   4  = Camshaft with integrated cams (one piece)
 *   5  = Camshaft section 1 (cams 1-11) - if too long
 *   6  = Camshaft section 2 (cams 12-22) - if too long
 *   7  = Hand crank
 *   8  = Frame left side
 *   9  = Frame right side
 *   10 = Frame base
 *   11 = Hardware list (no geometry)
 */

PART_SELECT = 0;

// ============================================
// PARAMETERS
// ============================================

WALL = 2;

WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

HINGE_SLOT_LENGTH = 8;       // OPTIMIZED (reduced from 12mm)
HINGE_SLOT_HEIGHT = 4;
HINGE_SLOT_CENTER_Y = 4;     // OPTIMIZED (adjusted for shorter slot)
HINGE_SLOT_CENTER_Z = 0;

CAM_HOUSING_SIZE = 14;
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

HINGE_EXT_WIDTH = HINGE_SLOT_LENGTH + 2 * WALL;
HINGE_EXT_Y_START = HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2 - WALL;
HINGE_EXT_Z_BOTTOM = HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2 - WALL;

CAM_EXT_WIDTH = CAM_HOUSING_SIZE + 2 * WALL;
CAM_EXT_Y_START = CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2 - WALL;
CAM_EXT_Z_BOTTOM = CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2 - WALL;

HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;

NUM_WAVES = 22;
UNIT_PITCH = 10;
CAM_THICKNESS = 4;
SHAFT_LENGTH = 240;

PHASE_OFFSET = 360 / NUM_WAVES;

function cam_major(i) = 10 + (i / (NUM_WAVES - 1)) * 2.5;  // OPTIMIZED: 10mm to 12.5mm
function cam_minor(i) = 9 - (i / (NUM_WAVES - 1)) * 2.5;   // OPTIMIZED: 9mm to 6.5mm
function cam_phase(i) = i * PHASE_OFFSET;

$fn = 48;

// ============================================
// PRINT MODULES
// ============================================

// Single wave slat - print flat on Y-Z face
module print_wave_slat() {
    difference() {
        union() {
            // Main wave body
            cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);

            // Hinge extension
            translate([0, HINGE_EXT_Y_START, HINGE_EXT_Z_BOTTOM])
                cube([WAVE_THICKNESS, HINGE_EXT_WIDTH, -HINGE_EXT_Z_BOTTOM]);

            // Cam housing extension
            translate([0, CAM_EXT_Y_START, CAM_EXT_Z_BOTTOM])
                cube([WAVE_THICKNESS, CAM_EXT_WIDTH, -CAM_EXT_Z_BOTTOM]);
        }

        // Hinge slot
        translate([-1, HINGE_SLOT_CENTER_Y - HINGE_SLOT_LENGTH/2,
                   HINGE_SLOT_CENTER_Z - HINGE_SLOT_HEIGHT/2])
            cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);

        // Cam housing
        translate([-1, CAM_HOUSING_CENTER_Y - CAM_HOUSING_SIZE/2,
                   CAM_HOUSING_CENTER_Z - CAM_HOUSING_SIZE/2])
            cube([WAVE_THICKNESS + 2, CAM_HOUSING_SIZE, CAM_HOUSING_SIZE]);
    }
}

// All 22 waves on plate
module print_all_waves() {
    spacing_x = WAVE_THICKNESS + 4;
    spacing_y = WAVE_LENGTH + 5;
    cols = 4;

    for (i = [0:NUM_WAVES-1]) {
        row = floor(i / cols);
        col = i % cols;
        translate([col * spacing_x, row * spacing_y, 0])
            print_wave_slat();
    }
}

// Hinge axle - simple cylinder
module print_hinge_axle() {
    cylinder(d=HINGE_AXLE_DIA, h=SHAFT_LENGTH);
}

// Camshaft with ALL integrated cams
module print_camshaft_with_cams() {
    // Main shaft
    cylinder(d=CAMSHAFT_DIA, h=SHAFT_LENGTH);

    // Cams at each position
    for (i = [0:NUM_WAVES-1]) {
        cam_z = 10 + i * UNIT_PITCH;  // Start 10mm from end
        major = cam_major(i);
        minor = cam_minor(i);
        phase = cam_phase(i);

        translate([0, 0, cam_z])
            rotate([0, 0, phase])
                difference() {
                    scale([major/10, minor/10, 1])
                        cylinder(r=5, h=CAM_THICKNESS, center=true);
                    // No hole needed - integrated with shaft
                }
    }
}

// Camshaft section 1 (cams 1-11) - for printers with <250mm bed
module print_camshaft_section1() {
    section_length = 120;

    cylinder(d=CAMSHAFT_DIA, h=section_length);

    for (i = [0:10]) {
        cam_z = 10 + i * UNIT_PITCH;
        major = cam_major(i);
        minor = cam_minor(i);
        phase = cam_phase(i);

        translate([0, 0, cam_z])
            rotate([0, 0, phase])
                scale([major/10, minor/10, 1])
                    cylinder(r=5, h=CAM_THICKNESS, center=true);
    }

    // Joint socket at end
    translate([0, 0, section_length])
        difference() {
            cylinder(d=CAMSHAFT_DIA + 4, h=10);
            translate([0, 0, 2])
                cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
        }
}

// Camshaft section 2 (cams 12-22)
module print_camshaft_section2() {
    section_length = 120;

    // Joint pin
    cylinder(d=CAMSHAFT_DIA, h=8);

    // Main shaft
    translate([0, 0, 8])
        cylinder(d=CAMSHAFT_DIA, h=section_length);

    for (i = [11:21]) {
        cam_z = 8 + (i - 11) * UNIT_PITCH + 10;
        major = cam_major(i);
        minor = cam_minor(i);
        phase = cam_phase(i);

        translate([0, 0, cam_z])
            rotate([0, 0, phase])
                scale([major/10, minor/10, 1])
                    cylinder(r=5, h=CAM_THICKNESS, center=true);
    }
}

// Hand crank
module print_hand_crank() {
    CRANK_ARM = 25;
    CRANK_KNOB_DIA = 10;
    CRANK_KNOB_H = 15;

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

// Frame left/right side
module print_frame_side() {
    FRAME_DEPTH = 90;
    FRAME_HEIGHT = 50;
    FRAME_WALL = 5;

    difference() {
        cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

        // Hinge hole
        translate([-1, 20, 20])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);

        // Camshaft hole
        translate([-1, 68, 20])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
    }
}

// Frame base
module print_frame_base() {
    FRAME_LENGTH = 260;
    FRAME_DEPTH = 90;
    FRAME_WALL = 5;

    cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    echo("=== FULL PLATE PREVIEW ===");

    // Sample waves
    color("BurlyWood")
    for (i = [0:3])
        translate([i * 10, 0, 0]) print_wave_slat();

    // Hinge axle
    color("Gray")
    translate([60, 0, 0])
        rotate([0, 90, 0]) print_hinge_axle();

    // Camshaft preview (shortened)
    color("DarkGray")
    translate([60, 40, 0])
        rotate([0, 90, 0]) {
            cylinder(d=CAMSHAFT_DIA, h=50);
            for (i = [0:4]) {
                translate([0, 0, 5 + i*10])
                    rotate([0, 0, cam_phase(i)])
                        scale([cam_major(i)/10, cam_minor(i)/10, 1])
                            cylinder(r=5, h=4, center=true);
            }
        }

    // Crank
    color("Peru")
    translate([130, 20, 0]) print_hand_crank();

    echo("Use PART_SELECT 1-11 for individual parts");
}
else if (PART_SELECT == 1) {
    echo("Part 1: SINGLE WAVE SLAT - Print 22x");
    print_wave_slat();
}
else if (PART_SELECT == 2) {
    echo("Part 2: ALL 22 WAVES");
    print_all_waves();
}
else if (PART_SELECT == 3) {
    echo("Part 3: HINGE AXLE - 3mm x 240mm");
    print_hinge_axle();
}
else if (PART_SELECT == 4) {
    echo("Part 4: CAMSHAFT WITH 22 CAMS");
    echo("NOTE: 240mm long - check your printer bed!");
    print_camshaft_with_cams();
}
else if (PART_SELECT == 5) {
    echo("Part 5: CAMSHAFT SECTION 1 (cams 1-11)");
    print_camshaft_section1();
}
else if (PART_SELECT == 6) {
    echo("Part 6: CAMSHAFT SECTION 2 (cams 12-22)");
    print_camshaft_section2();
}
else if (PART_SELECT == 7) {
    echo("Part 7: HAND CRANK");
    print_hand_crank();
}
else if (PART_SELECT == 8) {
    echo("Part 8: FRAME LEFT SIDE");
    print_frame_side();
}
else if (PART_SELECT == 9) {
    echo("Part 9: FRAME RIGHT SIDE");
    print_frame_side();
}
else if (PART_SELECT == 10) {
    echo("Part 10: FRAME BASE");
    print_frame_base();
}
else if (PART_SELECT == 11) {
    echo("Part 11: HARDWARE LIST");
}

// ============================================
// BILL OF MATERIALS
// ============================================

echo("");
echo("╔════════════════════════════════════════════════════════════╗");
echo("║          BILL OF MATERIALS - WAVE OCEAN v5                 ║");
echo("╠════════════════════════════════════════════════════════════╣");
echo("║                                                            ║");
echo("║  ALL 3D PRINTED PARTS:                                     ║");
echo("║    22× Wave slats (4×70×10mm + extensions)                 ║");
echo("║     1× Hinge axle (3mm dia × 240mm)                        ║");
echo("║     1× Camshaft with 22 cams (6mm dia × 240mm)             ║");
echo("║        OR 2× Camshaft sections (if bed < 250mm)            ║");
echo("║     1× Hand crank                                          ║");
echo("║     2× Frame sides (5×90×50mm)                             ║");
echo("║     1× Frame base (260×90×5mm)                             ║");
echo("║                                                            ║");
echo("║  NO METAL HARDWARE NEEDED!                                 ║");
echo("║                                                            ║");
echo("╠════════════════════════════════════════════════════════════╣");
echo("║  TOTALS:                                                   ║");
echo("║    Printed parts: 28 (or 29 if camshaft split)             ║");
echo("║    Est. print time: 6-8 hours                              ║");
echo("║    Est. filament: ~150g PLA                                ║");
echo("╚════════════════════════════════════════════════════════════╝");
