/*
 * WAVE OCEAN MECHANISM - PRINT PARTS
 *
 * Set PART_SELECT to export individual parts for printing
 */

// PART SELECTION
// 0 = Assembly view (not for printing)
// 1 = Frame base
// 2 = Slot rail
// 3 = Left side wall
// 4 = Right side wall
// 5 = Left bearing block
// 6 = Right bearing block
// 7 = Top beam
// 8 = Camshaft (print horizontally)
// 9 = Cam 1 (smallest)
// 10 = Cam 2
// 11 = Cam 3
// 12 = Cam 4 (medium)
// 13 = Cam 5
// 14 = Cam 6
// 15 = Cam 7 (largest)
// 16 = Wave segment (print 7x)
// 17 = Belt pulley
// 18 = Hand crank
PART_SELECT = 0;

// ============================================
// PARAMETERS (same as main file)
// ============================================

WAVE_AREA_START = 78;
NUM_WAVES = 7;
PHASE_OFFSET = 360 / NUM_WAVES;

WAVE_WIDTH = 36;
WAVE_OVERLAP = 5;
WAVE_SPACING = WAVE_WIDTH - WAVE_OVERLAP;
WAVE_LENGTH = 70;
WAVE_THICKNESS = 3;

TAB_WIDTH = 8;
TAB_HEIGHT = 4;

CAMSHAFT_DIA = 8;
CAMSHAFT_LENGTH = 250;
CAMSHAFT_HOLE = 8.6;
CAMSHAFT_Y = 60;
CAMSHAFT_Z = 20;

CAM_PROFILES = [
    [6, 3, 2],
    [7, 3.5, 2],
    [8, 4, 2.5],
    [10, 5, 2.5],
    [12, 6, 3],
    [14, 7, 3],
    [16, 8, 3]
];

SLOT_LENGTHS = [3, 4, 5, 6, 7, 8, 10];

FRAME_WIDTH = 260;
FRAME_DEPTH = 100;
FRAME_HEIGHT = 60;
FRAME_WALL = 5;
FRAME_X = WAVE_AREA_START - 10;
FRAME_Y = -10;
FRAME_Z = 0;

SLOT_RAIL_HEIGHT = 15;
SLOT_RAIL_Y = 0;
SLOT_RAIL_Z = 10;

BEARING_BLOCK_SIZE = 20;

CRANK_ARM_LENGTH = 35;
CRANK_KNOB_DIA = 15;
CRANK_KNOB_HEIGHT = 25;

PULLEY_OD = 30;
PULLEY_WIDTH = 8;

$fn = 64;

function wave_x(i) = WAVE_AREA_START + 20 + i * WAVE_SPACING;

// ============================================
// PRINT-ORIENTED MODULES
// ============================================

// Frame base - print flat
module print_frame_base() {
    difference() {
        cube([FRAME_WIDTH, FRAME_DEPTH, FRAME_WALL]);
        // Cutout for camshaft clearance
        translate([10, CAMSHAFT_Y - FRAME_Y - 15, -1])
            cube([FRAME_WIDTH - 20, 30, FRAME_WALL + 2]);
    }
}

// Slot rail - print flat
module print_slot_rail() {
    difference() {
        cube([FRAME_WIDTH, FRAME_WALL + 5, SLOT_RAIL_HEIGHT]);
        // Horizontal slots
        for (i = [0:NUM_WAVES-1]) {
            slot_x = wave_x(i) - FRAME_X - TAB_WIDTH/2;
            translate([slot_x, -1, SLOT_RAIL_HEIGHT/2 - TAB_HEIGHT/2 - 0.5])
                cube([TAB_WIDTH + 0.6, FRAME_WALL + 7, TAB_HEIGHT + 1]);
        }
    }
}

// Side wall - print flat
module print_side_wall() {
    cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
}

// Bearing block - print flat
module print_bearing_block() {
    difference() {
        cube([FRAME_WALL + 5, BEARING_BLOCK_SIZE, BEARING_BLOCK_SIZE]);
        translate([-1, BEARING_BLOCK_SIZE/2, BEARING_BLOCK_SIZE/2])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_HOLE, h=FRAME_WALL + 7);
    }
}

// Top beam - print flat
module print_top_beam() {
    cube([FRAME_WIDTH, 15, FRAME_WALL]);
}

// Camshaft - print horizontally
module print_camshaft() {
    rotate([0, 90, 0])
        cylinder(d=CAMSHAFT_DIA, h=CAMSHAFT_LENGTH);
}

// Elliptical cam - print flat
module print_cam(cam_num) {
    major = CAM_PROFILES[cam_num][0];
    minor = CAM_PROFILES[cam_num][1];
    groove_depth = CAM_PROFILES[cam_num][2];
    width = WAVE_WIDTH - 2;

    difference() {
        // Main elliptical body
        scale([major/10, minor/10, 1])
            cylinder(r=10, h=width);
        // Groove channel
        translate([0, 0, 2])
            scale([(major-groove_depth)/10, (minor-groove_depth)/10, 1])
                cylinder(r=10, h=width-4);
        // Shaft hole with keyway
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_DIA+0.3, h=width+2);
        // Keyway
        translate([-1, CAMSHAFT_DIA/2 - 0.5, -1])
            cube([2, 2, width+2]);
    }
}

// Wave segment - print flat
module print_wave_segment() {
    // Main body
    cube([WAVE_WIDTH, WAVE_LENGTH, WAVE_THICKNESS]);
    // Tab
    translate([WAVE_WIDTH/2 - TAB_WIDTH/2, -5, WAVE_THICKNESS/2 - TAB_HEIGHT/2])
        cube([TAB_WIDTH, 8, TAB_HEIGHT]);
    // Follower pin mounting holes
    translate([5, WAVE_LENGTH - 5, -1])
        cylinder(d=4.3, h=WAVE_THICKNESS + 2);
    translate([WAVE_WIDTH - 5, WAVE_LENGTH - 5, -1])
        cylinder(d=4.3, h=WAVE_THICKNESS + 2);
}

// Belt pulley - print standing
module print_belt_pulley() {
    difference() {
        union() {
            cylinder(d=PULLEY_OD, h=PULLEY_WIDTH);
            cylinder(d=PULLEY_OD + 4, h=1);
            translate([0, 0, PULLEY_WIDTH - 1])
                cylinder(d=PULLEY_OD + 4, h=1);
        }
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_HOLE, h=PULLEY_WIDTH + 2);
    }
}

// Hand crank - print flat
module print_hand_crank() {
    // Hub
    difference() {
        cylinder(d=20, h=8);
        translate([0, 0, -1])
            cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
    }
    // Arm
    translate([0, -5, 0])
        cube([CRANK_ARM_LENGTH, 10, 8]);
    // Knob
    translate([CRANK_ARM_LENGTH, 0, 0])
        cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_HEIGHT);
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    echo("Assembly view - not for printing. Set PART_SELECT 1-18.");

    // Quick assembly preview
    color([0.3, 0.3, 0.35]) {
        print_frame_base();
        translate([0, 0, SLOT_RAIL_Z])
            print_slot_rail();
    }
}
else if (PART_SELECT == 1) {
    echo("Part 1: Frame Base - 260×100×5mm");
    print_frame_base();
}
else if (PART_SELECT == 2) {
    echo("Part 2: Slot Rail - 260×10×15mm with 7 slots");
    print_slot_rail();
}
else if (PART_SELECT == 3) {
    echo("Part 3: Left Side Wall - 5×100×60mm");
    print_side_wall();
}
else if (PART_SELECT == 4) {
    echo("Part 4: Right Side Wall - 5×100×60mm");
    print_side_wall();
}
else if (PART_SELECT == 5) {
    echo("Part 5: Left Bearing Block - 10×20×20mm");
    print_bearing_block();
}
else if (PART_SELECT == 6) {
    echo("Part 6: Right Bearing Block - 10×20×20mm");
    print_bearing_block();
}
else if (PART_SELECT == 7) {
    echo("Part 7: Top Beam - 260×15×5mm");
    print_top_beam();
}
else if (PART_SELECT == 8) {
    echo("Part 8: Camshaft - 8mm dia × 250mm (print with supports)");
    print_camshaft();
}
else if (PART_SELECT == 9) {
    echo("Part 9: Cam 1 (smallest) - 12×6mm ellipse");
    print_cam(0);
}
else if (PART_SELECT == 10) {
    echo("Part 10: Cam 2 - 14×7mm ellipse");
    print_cam(1);
}
else if (PART_SELECT == 11) {
    echo("Part 11: Cam 3 - 16×8mm ellipse");
    print_cam(2);
}
else if (PART_SELECT == 12) {
    echo("Part 12: Cam 4 (medium) - 20×10mm ellipse");
    print_cam(3);
}
else if (PART_SELECT == 13) {
    echo("Part 13: Cam 5 - 24×12mm ellipse");
    print_cam(4);
}
else if (PART_SELECT == 14) {
    echo("Part 14: Cam 6 - 28×14mm ellipse");
    print_cam(5);
}
else if (PART_SELECT == 15) {
    echo("Part 15: Cam 7 (largest) - 32×16mm ellipse");
    print_cam(6);
}
else if (PART_SELECT == 16) {
    echo("Part 16: Wave Segment - 36×70×3mm (PRINT 7x)");
    print_wave_segment();
}
else if (PART_SELECT == 17) {
    echo("Part 17: Belt Pulley - 30mm OD × 8mm");
    print_belt_pulley();
}
else if (PART_SELECT == 18) {
    echo("Part 18: Hand Crank");
    print_hand_crank();
}

// ============================================
// BOM ECHO
// ============================================

echo("");
echo("=== BILL OF MATERIALS ===");
echo("");
echo("PRINTED PARTS:");
echo("  1× Frame Base (260×100×5mm)");
echo("  1× Slot Rail (260×10×15mm)");
echo("  2× Side Walls (5×100×60mm)");
echo("  2× Bearing Blocks (10×20×20mm)");
echo("  1× Top Beam (260×15×5mm)");
echo("  1× Camshaft (8mm × 250mm)");
echo("  7× Cams (progressive sizes)");
echo("  7× Wave Segments (36×70×3mm)");
echo("  1× Belt Pulley (30mm)");
echo("  1× Hand Crank");
echo("");
echo("HARDWARE:");
echo("  14× M3×8 screws (frame assembly)");
echo("  14× M3 nuts");
echo("  7× 4mm × 30mm pins (cam followers)");
echo("");
echo("Total printed parts: 24");
echo("Estimated print time: 8-10 hours");
