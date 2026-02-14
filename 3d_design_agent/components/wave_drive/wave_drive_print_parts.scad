// ============================================
// WAVE DRIVE - PRINT PARTS (SEPARATED)
// ============================================
// Export each part separately for printing
// Set PART_SELECT to choose which part to export
// ============================================

// PART SELECTION
// 1 = Base plate only
// 2 = Gear only (print flat)
// 3 = Shaft only
// 4 = Crank arm + knob (print as one piece)
// 0 = All parts assembled (for reference only)
PART_SELECT = 0;

// ==========================================
// PARAMETERS (same as standalone)
// ==========================================

// Gear parameters
GEAR_TEETH = 30;
GEAR_PITCH_RADIUS = 15;
GEAR_THICKNESS = 6;
GEAR_SHAFT_HOLE = 5.3;

// Shaft parameters
SHAFT_DIAMETER = 5;
SHAFT_PRINT_DIA = 4.7;
SHAFT_LENGTH = 20;

// Base plate parameters
BASE_SIZE = 50;
BASE_THICKNESS = 3;
BUSHING_OD = 8;
BUSHING_HEIGHT = 5;

// Crank parameters
CRANK_LENGTH = 30;
CRANK_WIDTH = 5;
CRANK_THICKNESS = 3;

// Knob parameters
KNOB_DIAMETER = 10;
KNOB_HEIGHT = 12;

// Clearance
CLEARANCE = 0.3;

$fn = 64;

// ==========================================
// MODULES (same as standalone)
// ==========================================

module simple_gear(teeth, pitch_radius, thickness, shaft_hole) {
    tooth_height = pitch_radius * 0.08;
    difference() {
        union() {
            cylinder(r=pitch_radius - tooth_height*0.3, h=thickness);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                    translate([pitch_radius, 0, 0])
                        cylinder(r=tooth_height, h=thickness, $fn=6);
            }
        }
        translate([0, 0, -1])
            cylinder(d=shaft_hole, h=thickness+2);
        if (pitch_radius > 10) {
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                    translate([pitch_radius * 0.5, 0, -1])
                        cylinder(r=pitch_radius * 0.15, h=thickness+2);
            }
        }
    }
}

module base_plate() {
    difference() {
        translate([-BASE_SIZE/2, -BASE_SIZE/2, 0])
            cube([BASE_SIZE, BASE_SIZE, BASE_THICKNESS]);
        translate([0, 0, -1])
            cylinder(d=SHAFT_DIAMETER + CLEARANCE, h=BASE_THICKNESS + 2);
    }
    // Bushing
    difference() {
        cylinder(d=BUSHING_OD, h=BUSHING_HEIGHT);
        translate([0, 0, -1])
            cylinder(d=SHAFT_DIAMETER + CLEARANCE, h=BUSHING_HEIGHT + 2);
    }
}

module shaft() {
    cylinder(d=SHAFT_PRINT_DIA, h=SHAFT_LENGTH);
}

module crank_with_knob() {
    // Arm
    hull() {
        cylinder(d=CRANK_WIDTH, h=CRANK_THICKNESS);
        translate([CRANK_LENGTH, 0, 0])
            cylinder(d=CRANK_WIDTH, h=CRANK_THICKNESS);
    }
    // Shaft attachment hole (negative)
    // Actually make it solid with a shaft stub
    translate([0, 0, -8]) cylinder(d=SHAFT_PRINT_DIA, h=8);

    // Knob
    translate([CRANK_LENGTH, 0, 0]) {
        cylinder(d=KNOB_DIAMETER, h=KNOB_HEIGHT * 0.7);
        translate([0, 0, KNOB_HEIGHT * 0.7])
            scale([1, 1, 0.6])
                sphere(d=KNOB_DIAMETER);
    }
}

// ==========================================
// PART SELECTION
// ==========================================

if (PART_SELECT == 1) {
    // Base plate - print flat
    base_plate();
    echo("Exporting: BASE PLATE");
}
else if (PART_SELECT == 2) {
    // Gear - print flat (teeth up)
    simple_gear(GEAR_TEETH, GEAR_PITCH_RADIUS, GEAR_THICKNESS, GEAR_SHAFT_HOLE);
    echo("Exporting: GEAR (30T)");
}
else if (PART_SELECT == 3) {
    // Shaft - print standing or lying
    shaft();
    echo("Exporting: SHAFT");
}
else if (PART_SELECT == 4) {
    // Crank with integrated shaft stub and knob
    crank_with_knob();
    echo("Exporting: CRANK + KNOB (with shaft stub)");
}
else {
    // Assembly view
    echo("ASSEMBLY VIEW - not for printing");

    color([0.3, 0.3, 0.3])
        translate([0, 0, -8]) base_plate();

    color([0.7, 0.7, 0.7])
        translate([0, 0, -8]) shaft();

    color([0.85, 0.65, 0.12])
        simple_gear(GEAR_TEETH, GEAR_PITCH_RADIUS, GEAR_THICKNESS, GEAR_SHAFT_HOLE);

    color([0.4, 0.4, 0.8])
        translate([0, 0, 8]) {
            hull() {
                cylinder(d=CRANK_WIDTH, h=CRANK_THICKNESS);
                translate([CRANK_LENGTH, 0, 0])
                    cylinder(d=CRANK_WIDTH, h=CRANK_THICKNESS);
            }
        }

    color([0.8, 0.2, 0.2])
        translate([CRANK_LENGTH, 0, 8]) {
            cylinder(d=KNOB_DIAMETER, h=KNOB_HEIGHT * 0.7);
            translate([0, 0, KNOB_HEIGHT * 0.7])
                scale([1, 1, 0.6])
                    sphere(d=KNOB_DIAMETER);
        }
}
