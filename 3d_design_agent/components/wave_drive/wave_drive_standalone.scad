// ============================================
// WAVE DRIVE (30T) + HAND CRANK - STANDALONE
// ============================================
// Purpose: Test wave drive gear rotation in isolation
// Part of: Starry Night Kinetic Sculpture
// Version: 1.0
//
// Test procedure:
// 1. F5 preview - check all parts visible
// 2. Set $t = 0, 0.25, 0.5, 0.75 to check rotation
// 3. F6 render - check for errors
// 4. Export STL for print test
// ============================================

// ==========================================
// PARAMETERS (from geometry checklist)
// ==========================================

// Animation (0-1 cycle)
// Set MANUAL_ANGLE to override $t for static renders
// -1 = use $t animation, 0/90/180/270 = fixed angle
MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// Gear parameters
GEAR_TEETH = 30;
GEAR_PITCH_RADIUS = 15;  // mm
GEAR_THICKNESS = 6;      // mm
GEAR_SHAFT_HOLE = 5.3;   // mm (5mm + 0.3mm clearance)
GEAR_ADDENDUM = 1.2;     // tooth height above pitch circle

// Shaft parameters
SHAFT_DIAMETER = 5;      // mm (nominal)
SHAFT_PRINT_DIA = 4.7;   // mm (for 0.3mm clearance in 5mm hole)
SHAFT_LENGTH = 20;       // mm
SHAFT_Z_BOTTOM = -8;     // mm

// Base plate parameters
BASE_SIZE = 50;          // mm (square)
BASE_THICKNESS = 3;      // mm
BASE_Z = -8;             // mm (bottom surface)
BUSHING_OD = 8;          // mm
BUSHING_HEIGHT = 5;      // mm

// Crank parameters
CRANK_LENGTH = 30;       // mm
CRANK_WIDTH = 5;         // mm
CRANK_THICKNESS = 3;     // mm
CRANK_Z = 8;             // mm (bottom of crank)

// Knob parameters
KNOB_DIAMETER = 10;      // mm
KNOB_HEIGHT = 12;        // mm

// Print clearance
CLEARANCE = 0.3;         // mm

// Colors for debugging
C_GEAR = [0.85, 0.65, 0.12];      // Gold
C_SHAFT = [0.7, 0.7, 0.7];        // Silver
C_BASE = [0.3, 0.3, 0.3];         // Dark gray
C_CRANK = [0.4, 0.4, 0.8];        // Blue
C_KNOB = [0.8, 0.2, 0.2];         // Red

// Resolution
$fn = 64;

// ==========================================
// MODULES
// ==========================================

// Simple gear with visible teeth
module simple_gear(teeth, pitch_radius, thickness, shaft_hole) {
    tooth_height = pitch_radius * 0.08;
    difference() {
        union() {
            // Main body
            cylinder(r=pitch_radius - tooth_height*0.3, h=thickness);
            // Teeth
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                    translate([pitch_radius, 0, 0])
                        cylinder(r=tooth_height, h=thickness, $fn=6);
            }
        }
        // Shaft hole
        translate([0, 0, -1])
            cylinder(d=shaft_hole, h=thickness+2);

        // Weight reduction holes (for gears > 20mm pitch radius)
        if (pitch_radius > 10) {
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                    translate([pitch_radius * 0.5, 0, -1])
                        cylinder(r=pitch_radius * 0.15, h=thickness+2);
            }
        }
    }
}

// Base plate with bushing
module base_plate() {
    difference() {
        // Plate
        translate([-BASE_SIZE/2, -BASE_SIZE/2, BASE_Z])
            cube([BASE_SIZE, BASE_SIZE, BASE_THICKNESS]);

        // Shaft hole
        translate([0, 0, BASE_Z - 1])
            cylinder(d=SHAFT_DIAMETER + CLEARANCE, h=BASE_THICKNESS + 2);
    }

    // Bushing (support collar)
    difference() {
        translate([0, 0, BASE_Z])
            cylinder(d=BUSHING_OD, h=BUSHING_HEIGHT);
        translate([0, 0, BASE_Z - 1])
            cylinder(d=SHAFT_DIAMETER + CLEARANCE, h=BUSHING_HEIGHT + 2);
    }
}

// Shaft
module shaft() {
    cylinder(d=SHAFT_PRINT_DIA, h=SHAFT_LENGTH);
}

// Crank arm
module crank_arm() {
    // Arm
    hull() {
        cylinder(d=CRANK_WIDTH, h=CRANK_THICKNESS);
        translate([CRANK_LENGTH, 0, 0])
            cylinder(d=CRANK_WIDTH, h=CRANK_THICKNESS);
    }
}

// Knob
module crank_knob() {
    // Ergonomic knob - cylinder with rounded top
    cylinder(d=KNOB_DIAMETER, h=KNOB_HEIGHT * 0.7);
    translate([0, 0, KNOB_HEIGHT * 0.7])
        scale([1, 1, 0.6])
            sphere(d=KNOB_DIAMETER);
}

// ==========================================
// ASSEMBLY
// ==========================================

module wave_drive_assembly() {
    // Base plate (static)
    color(C_BASE) base_plate();

    // Rotating group - everything attached to shaft
    rotate([0, 0, theta]) {
        // Shaft
        color(C_SHAFT)
            translate([0, 0, SHAFT_Z_BOTTOM])
                shaft();

        // Gear on shaft (Z=0 to Z=6)
        color(C_GEAR)
            simple_gear(GEAR_TEETH, GEAR_PITCH_RADIUS, GEAR_THICKNESS, GEAR_SHAFT_HOLE);

        // Crank arm (at Z=8, 2mm above gear)
        color(C_CRANK)
            translate([0, 0, CRANK_Z])
                crank_arm();

        // Knob at end of crank
        color(C_KNOB)
            translate([CRANK_LENGTH, 0, CRANK_Z])
                crank_knob();
    }
}

// ==========================================
// RENDER
// ==========================================

wave_drive_assembly();

// ==========================================
// DEBUG INFO
// ==========================================

echo("=== WAVE DRIVE STANDALONE ===");
echo(str("Gear: ", GEAR_TEETH, "T, pitch radius = ", GEAR_PITCH_RADIUS, "mm"));
echo(str("Gear outer diameter = ", (GEAR_PITCH_RADIUS + GEAR_ADDENDUM) * 2, "mm"));
echo(str("Shaft diameter = ", SHAFT_PRINT_DIA, "mm (for ", SHAFT_DIAMETER, "mm hole)"));
echo(str("Current angle = ", theta, " degrees ($t = ", $t, ")"));
echo(str("Crank reach = ", CRANK_LENGTH, "mm from center"));
echo("=============================");
