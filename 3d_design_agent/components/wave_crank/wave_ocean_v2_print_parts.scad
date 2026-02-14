/*
 * WAVE OCEAN v2 - PRINT PARTS
 *
 * Based on classic wave machine automata
 * 22 thin waves + 22 thin elliptical cams
 *
 * PART SELECTION:
 *   0  = Full assembly (plate layout)
 *   1  = Frame left side
 *   2  = Frame right side
 *   3  = Frame base plate
 *   4  = Frame back rail
 *   5  = Frame front rail
 *   6  = Hand crank
 *   7  = Single wave slat (print 22x)
 *   8  = All waves on plate
 *   9  = Cam 1 (smallest)
 *   10 = Cam 11 (medium)
 *   11 = Cam 22 (largest)
 *   12 = All cams on plate
 *   13 = Hardware list only
 */

PART_SELECT = 0;

// ============================================
// PARAMETERS (from main file, REVISED values)
// ============================================

WAVE_AREA_START_X = 78;
WAVE_AREA_END_X = 302;
WAVE_AREA_WIDTH = 224;

WAVE_THICKNESS = 4;
CAM_THICKNESS = 4;
WAVE_GAP = 1;
UNIT_PITCH = 10;
NUM_WAVES = 22;

CAMSHAFT_DIA = 6;
CAMSHAFT_HOLE = 6.4;
CAMSHAFT_LENGTH = 264;
CAMSHAFT_Y = 70;
CAMSHAFT_Z = 28;

HINGE_AXLE_DIA = 5;
HINGE_AXLE_HOLE = 5.4;
HINGE_AXLE_LENGTH = 264;
HINGE_AXLE_Y = 0;
HINGE_AXLE_Z = 25;

WAVE_LENGTH = 75;
WAVE_HEIGHT = 25;
SLOT_LENGTH = 15;
SLOT_HEIGHT = 5.4;

FRAME_LENGTH = 284;
FRAME_DEPTH = 100;
FRAME_HEIGHT = 60;
FRAME_WALL = 5;
FRAME_X_START = 48;
FRAME_Y_START = -20;

CRANK_ARM = 30;
CRANK_KNOB_DIA = 12;
CRANK_KNOB_H = 20;

// Cam sizing
function cam_major(i) = 8 + (i / NUM_WAVES) * 16;
function cam_minor(i) = 4 + (i / NUM_WAVES) * 6;

$fn = 48;

// ============================================
// PRINT-ORIENTED MODULES
// ============================================

// Frame left side - print flat on back
module print_frame_left() {
    difference() {
        cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

        // Camshaft hole
        translate([-1, CAMSHAFT_Y - FRAME_Y_START, CAMSHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_HOLE, h=FRAME_WALL + 2);

        // Hinge axle hole
        translate([-1, HINGE_AXLE_Y - FRAME_Y_START, HINGE_AXLE_Z])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
    }
}

// Frame right side - same as left
module print_frame_right() {
    print_frame_left();
}

// Frame base plate - print flat
module print_frame_base() {
    cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);
}

// Frame back rail - print flat
module print_frame_back_rail() {
    difference() {
        cube([FRAME_LENGTH, FRAME_WALL + 5, FRAME_HEIGHT/2]);

        // Hinge axle channel
        translate([-1, FRAME_WALL/2, HINGE_AXLE_Z])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_LENGTH + 2);
    }
}

// Frame front rail - print flat
module print_frame_front_rail() {
    difference() {
        cube([FRAME_LENGTH, FRAME_WALL + 15, FRAME_HEIGHT/2 + 10]);

        // Camshaft channel
        translate([-1, 10, CAMSHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_HOLE, h=FRAME_LENGTH + 2);
    }
}

// Hand crank - print flat
module print_hand_crank() {
    // Hub
    difference() {
        cylinder(d=16, h=6);
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_DIA + 0.3, h=8);
    }

    // Arm
    translate([0, -4, 0])
        cube([CRANK_ARM, 8, 6]);

    // Knob
    translate([CRANK_ARM, 0, 0])
        cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
}

// Single wave slat - print flat
module print_wave_slat() {
    difference() {
        // Main body
        cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_HEIGHT]);

        // Rectangular slot at hinge end
        translate([-1, -1, WAVE_HEIGHT/2 - SLOT_HEIGHT/2])
            cube([WAVE_THICKNESS + 2, SLOT_LENGTH + 1, SLOT_HEIGHT]);
    }

    // Cam follower nub
    translate([WAVE_THICKNESS/2, WAVE_LENGTH - 5, WAVE_HEIGHT/2])
        rotate([0, 90, 0])
            cylinder(d=6, h=WAVE_THICKNESS, center=true);
}

// Single elliptical cam - print flat
module print_cam(cam_num) {
    major = cam_major(cam_num);
    minor = cam_minor(cam_num);

    difference() {
        // Elliptical disc
        scale([1, minor/major, 1])
            cylinder(d=major, h=CAM_THICKNESS);

        // Shaft hole
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_DIA + 0.3, h=CAM_THICKNESS + 2);

        // Keyway for indexing
        translate([-1, CAMSHAFT_DIA/2 - 0.5, -1])
            cube([2, 2, CAM_THICKNESS + 2]);
    }
}

// All waves arranged on print plate
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

// All cams arranged on print plate
module print_all_cams() {
    // Arrange in rows, largest first (they need more space)
    spacing = 35;  // Max cam is 24mm, so 35mm spacing
    cols = 6;

    for (i = [0:NUM_WAVES-1]) {
        row = floor(i / cols);
        col = i % cols;
        translate([col * spacing, row * spacing, 0])
            print_cam(i);
    }
}

// ============================================
// PART SELECTION RENDERING
// ============================================

if (PART_SELECT == 0) {
    // Full assembly plate view
    echo("=== FULL ASSEMBLY PLATE VIEW ===");
    echo("All parts laid out for visualization");

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

    // Sample waves (showing 5)
    color("BurlyWood")
        for (i = [0:4]) {
            translate([400 + i*10, 0, 0]) print_wave_slat();
        }

    // Sample cams (showing 5)
    color("Sienna")
        for (i = [0:4]) {
            translate([400 + i*30, 100, 0]) print_cam(i * 5);
        }

    echo("");
    echo("NOTE: This shows a SAMPLE. Use PART_SELECT 8 for all waves, 12 for all cams");
}
else if (PART_SELECT == 1) {
    echo("Part 1: FRAME LEFT SIDE - 5×100×60mm");
    echo("Print: Flat on 100×60 face");
    print_frame_left();
}
else if (PART_SELECT == 2) {
    echo("Part 2: FRAME RIGHT SIDE - 5×100×60mm");
    echo("Print: Flat on 100×60 face (same as left)");
    print_frame_right();
}
else if (PART_SELECT == 3) {
    echo("Part 3: FRAME BASE PLATE - 284×100×5mm");
    echo("Print: Flat (may need large bed or split)");
    print_frame_base();
}
else if (PART_SELECT == 4) {
    echo("Part 4: FRAME BACK RAIL - 284×10×30mm");
    echo("Print: Flat on 284×10 face");
    print_frame_back_rail();
}
else if (PART_SELECT == 5) {
    echo("Part 5: FRAME FRONT RAIL - 284×20×40mm");
    echo("Print: Flat on 284×20 face");
    print_frame_front_rail();
}
else if (PART_SELECT == 6) {
    echo("Part 6: HAND CRANK");
    echo("Print: Flat on hub face");
    print_hand_crank();
}
else if (PART_SELECT == 7) {
    echo("Part 7: SINGLE WAVE SLAT - 4×75×25mm");
    echo("Print: Flat on 4×75 face");
    echo("QUANTITY NEEDED: 22");
    print_wave_slat();
}
else if (PART_SELECT == 8) {
    echo("Part 8: ALL 22 WAVES ON PLATE");
    echo("Print: Flat, arranged in grid");
    echo("Plate size needed: ~50×500mm");
    print_all_waves();
}
else if (PART_SELECT == 9) {
    echo("Part 9: CAM 1 (SMALLEST) - 8×4mm ellipse");
    echo("Print: Flat");
    print_cam(0);
}
else if (PART_SELECT == 10) {
    echo("Part 10: CAM 11 (MEDIUM) - 16×7mm ellipse");
    echo("Print: Flat");
    print_cam(10);
}
else if (PART_SELECT == 11) {
    echo("Part 11: CAM 22 (LARGEST) - 24×10mm ellipse");
    echo("Print: Flat");
    print_cam(21);
}
else if (PART_SELECT == 12) {
    echo("Part 12: ALL 22 CAMS ON PLATE");
    echo("Print: Flat, arranged in grid");
    echo("Plate size needed: ~210×140mm");
    print_all_cams();
}
else if (PART_SELECT == 13) {
    echo("Part 13: HARDWARE LIST (no geometry)");
    // No geometry, just BOM
}

// ============================================
// BILL OF MATERIALS (always shown)
// ============================================

echo("");
echo("╔══════════════════════════════════════════════════════════════╗");
echo("║           BILL OF MATERIALS - WAVE OCEAN v2                  ║");
echo("╠══════════════════════════════════════════════════════════════╣");
echo("║ PRINTED PARTS:                                               ║");
echo("║   1× Frame left side (5×100×60mm)                            ║");
echo("║   1× Frame right side (5×100×60mm)                           ║");
echo("║   1× Frame base plate (284×100×5mm)                          ║");
echo("║   1× Frame back rail (284×10×30mm)                           ║");
echo("║   1× Frame front rail (284×20×40mm)                          ║");
echo("║   1× Hand crank                                              ║");
echo("║  22× Wave slats (4×75×25mm each)                             ║");
echo("║  22× Elliptical cams (4mm thick, progressive sizes)          ║");
echo("║                                                              ║");
echo("║ HARDWARE (BUY - DO NOT PRINT):                               ║");
echo("║   1× Steel rod 6mm dia × 270mm (camshaft)                    ║");
echo("║   1× Steel rod 5mm dia × 270mm (hinge axle)                  ║");
echo("║   8× M3×12 screws                                            ║");
echo("║   8× M3 nuts                                                 ║");
echo("║   Super glue for cam-to-shaft bonding                        ║");
echo("║                                                              ║");
echo("╠══════════════════════════════════════════════════════════════╣");
echo("║ TOTALS:                                                      ║");
echo("║   Printed parts: 50                                          ║");
echo("║   Estimated print time: 4-5 hours                            ║");
echo("║   Estimated filament: ~100g PLA                              ║");
echo("╚══════════════════════════════════════════════════════════════╝");
echo("");
echo("CAM SIZES (for reference):");
for (i = [0:NUM_WAVES-1]) {
    echo(str("  Cam ", i+1, ": ", cam_major(i), "×", cam_minor(i), "mm"));
}
