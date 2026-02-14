/*
 * WAVE OCEAN v3 - PRINT PARTS
 *
 * Individual parts for STL export
 * Based on corrected Z-layer geometry
 *
 * PART SELECTION:
 *   0  = Full assembly (plate layout preview)
 *   1  = Frame left side
 *   2  = Frame right side
 *   3  = Frame base plate
 *   4  = Frame back rail
 *   5  = Frame front rail
 *   6  = Hand crank
 *   7  = Single wave slat (print 22x)
 *   8  = ALL 22 waves on plate
 *   9  = Cam 1 (smallest, 8x4mm)
 *   10 = Cam 11 (medium, 16x7mm)
 *   11 = Cam 22 (largest, 24x10mm)
 *   12 = ALL 22 cams on plate
 *   13 = Hardware list only (no geometry)
 */

PART_SELECT = 0;

// ============================================
// PARAMETERS (from wave_ocean_v3.scad)
// ============================================

NUM_WAVES = 22;

WAVE_THICKNESS = 4;
CAM_THICKNESS = 4;

WAVE_LENGTH = 75;
WAVE_HEIGHT = 25;

SLOT_WIDTH = 5.4;
SLOT_LENGTH = 15;

CAMSHAFT_DIA = 6;
HINGE_AXLE_DIA = 5;

FRAME_LENGTH = 284;
FRAME_DEPTH = 100;
FRAME_HEIGHT = 60;
FRAME_WALL = 5;

Z_HINGE_AXLE = 25;
Z_CAMSHAFT = 28;

CRANK_ARM = 30;
CRANK_KNOB_DIA = 12;
CRANK_KNOB_H = 20;

// Cam sizing (progressive)
function cam_major(i) = 8 + (i / (NUM_WAVES - 1)) * 16;
function cam_minor(i) = 4 + (i / (NUM_WAVES - 1)) * 6;

$fn = 48;

// ============================================
// PRINT-ORIENTED MODULES (flat on bed)
// ============================================

// Frame left side - print flat
module print_frame_left() {
    difference() {
        cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

        // Hinge axle hole
        translate([-1, 20, Z_HINGE_AXLE])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);

        // Camshaft hole
        translate([-1, 90, Z_CAMSHAFT])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
    }
}

// Frame right side - same as left
module print_frame_right() {
    print_frame_left();
}

// Frame base plate
module print_frame_base() {
    cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);
}

// Frame back rail
module print_frame_back_rail() {
    difference() {
        cube([FRAME_LENGTH - 2*FRAME_WALL, FRAME_WALL + 5, FRAME_HEIGHT/2]);

        // Hinge axle channel
        translate([-1, FRAME_WALL/2, Z_HINGE_AXLE])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_LENGTH);
    }
}

// Frame front rail
module print_frame_front_rail() {
    difference() {
        cube([FRAME_LENGTH - 2*FRAME_WALL, 20, FRAME_HEIGHT/2 + 15]);

        // Camshaft channel
        translate([-1, 10, Z_CAMSHAFT])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_LENGTH);
    }
}

// Hand crank
module print_hand_crank() {
    // Hub
    difference() {
        cylinder(d=16, h=8);
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
    }

    // Arm
    translate([0, -4, 0])
        cube([CRANK_ARM, 8, 8]);

    // Knob
    translate([CRANK_ARM, 0, 0])
        cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
}

// Single wave slat
module print_wave_slat() {
    difference() {
        // Main body
        cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_HEIGHT]);

        // Rectangular slot at hinge end
        translate([-1, -1, WAVE_HEIGHT/2 - SLOT_WIDTH/2])
            cube([WAVE_THICKNESS + 2, SLOT_LENGTH + 1, SLOT_WIDTH]);
    }
}

// Single elliptical cam
module print_cam(cam_num) {
    major = cam_major(cam_num);
    minor = cam_minor(cam_num);

    difference() {
        // Elliptical disc
        scale([1, minor/major, 1])
            cylinder(r=major/2, h=CAM_THICKNESS);

        // Shaft hole
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_DIA + 0.3, h=CAM_THICKNESS + 2);

        // Keyway for phase indexing
        translate([-1, CAMSHAFT_DIA/2 - 0.5, -1])
            cube([2, 2, CAM_THICKNESS + 2]);
    }
}

// All 22 waves on print plate
module print_all_waves() {
    rows = 6;
    cols = 4;
    spacing_x = WAVE_THICKNESS + 5;
    spacing_y = WAVE_LENGTH + 5;

    for (i = [0:NUM_WAVES-1]) {
        row = floor(i / cols);
        col = i % cols;
        translate([col * spacing_x, row * spacing_y, 0])
            print_wave_slat();
    }
}

// All 22 cams on print plate
module print_all_cams() {
    spacing = 30;  // Largest cam is 24mm
    cols = 6;

    for (i = [0:NUM_WAVES-1]) {
        row = floor(i / cols);
        col = i % cols;
        translate([col * spacing, row * spacing, 0])
            print_cam(i);
    }
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    echo("=== FULL ASSEMBLY PLATE VIEW ===");

    // Frame pieces
    color("SaddleBrown") {
        translate([0, 0, 0]) print_frame_base();
        translate([0, 110, 0]) print_frame_back_rail();
        translate([0, 160, 0]) print_frame_front_rail();
        translate([300, 0, 0]) rotate([0, 0, 90]) print_frame_left();
        translate([320, 0, 0]) rotate([0, 0, 90]) print_frame_right();
    }

    // Crank
    color("Peru")
        translate([350, 50, 0]) print_hand_crank();

    // Sample waves (5 shown)
    color("BurlyWood")
        for (i = [0:4]) {
            translate([400 + i*10, 0, 0]) print_wave_slat();
        }

    // Sample cams (5 shown)
    color("Sienna")
        for (i = [0:4]) {
            translate([400 + i*30, 100, 0]) print_cam(i * 5);
        }

    echo("Use PART_SELECT 8 for all 22 waves, PART_SELECT 12 for all 22 cams");
}
else if (PART_SELECT == 1) {
    echo("Part 1: FRAME LEFT SIDE");
    print_frame_left();
}
else if (PART_SELECT == 2) {
    echo("Part 2: FRAME RIGHT SIDE");
    print_frame_right();
}
else if (PART_SELECT == 3) {
    echo("Part 3: FRAME BASE PLATE (284x100x5mm)");
    print_frame_base();
}
else if (PART_SELECT == 4) {
    echo("Part 4: FRAME BACK RAIL");
    print_frame_back_rail();
}
else if (PART_SELECT == 5) {
    echo("Part 5: FRAME FRONT RAIL");
    print_frame_front_rail();
}
else if (PART_SELECT == 6) {
    echo("Part 6: HAND CRANK");
    print_hand_crank();
}
else if (PART_SELECT == 7) {
    echo("Part 7: SINGLE WAVE SLAT (4x75x25mm) - PRINT 22x");
    print_wave_slat();
}
else if (PART_SELECT == 8) {
    echo("Part 8: ALL 22 WAVES ON PLATE");
    print_all_waves();
}
else if (PART_SELECT == 9) {
    echo(str("Part 9: CAM 1 (smallest) - ", cam_major(0), "x", cam_minor(0), "mm"));
    print_cam(0);
}
else if (PART_SELECT == 10) {
    echo(str("Part 10: CAM 11 (medium) - ", cam_major(10), "x", cam_minor(10), "mm"));
    print_cam(10);
}
else if (PART_SELECT == 11) {
    echo(str("Part 11: CAM 22 (largest) - ", cam_major(21), "x", cam_minor(21), "mm"));
    print_cam(21);
}
else if (PART_SELECT == 12) {
    echo("Part 12: ALL 22 CAMS ON PLATE");
    print_all_cams();
}
else if (PART_SELECT == 13) {
    echo("Part 13: HARDWARE LIST (no geometry)");
}

// ============================================
// BILL OF MATERIALS
// ============================================

echo("");
echo("========================================");
echo("  BILL OF MATERIALS - WAVE OCEAN v3");
echo("========================================");
echo("");
echo("PRINTED PARTS:");
echo("  1x Frame left side (5x100x60mm)");
echo("  1x Frame right side (5x100x60mm)");
echo("  1x Frame base plate (284x100x5mm)");
echo("  1x Frame back rail (274x10x30mm)");
echo("  1x Frame front rail (274x20x45mm)");
echo("  1x Hand crank");
echo("  22x Wave slats (4x75x25mm each)");
echo("  22x Elliptical cams (4mm thick, progressive)");
echo("");
echo("HARDWARE (BUY - DO NOT PRINT):");
echo("  1x Steel rod 6mm x 280mm (camshaft)");
echo("  1x Steel rod 5mm x 280mm (hinge axle)");
echo("  8x M3x12 screws");
echo("  8x M3 nuts");
echo("  Super glue for cam indexing");
echo("");
echo("TOTALS:");
echo("  Printed parts: 50");
echo("  Est. print time: 4-5 hours");
echo("  Est. filament: ~100g PLA");
echo("========================================");
echo("");
echo("CAM SIZES (for reference):");
for (i = [0:NUM_WAVES-1]) {
    echo(str("  Cam ", i+1, ": ", cam_major(i), " x ", cam_minor(i), "mm"));
}
