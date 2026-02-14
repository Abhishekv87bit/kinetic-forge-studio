// ============================================================
// ZONE 3 FOAM GEAR (16T) + FOAM CURL - PRINT PARTS
// ============================================================
// Export individual parts for 3D printing
// Use PART_SELECT to choose which part to export
// ============================================================

// === PART SELECTION ===
// 1 = Base plate only
// 2 = Gear only (16T)
// 3 = Shaft only
// 4 = Gear + arm + foam curl as one printable piece
PART_SELECT = 1;  // [1, 2, 3, 4]

// Quality settings
$fn = 64;

// === DIMENSIONS (all in mm) ===
// Gear parameters
GEAR_TEETH = 16;
GEAR_MODULE = 1.0;
GEAR_PITCH_RADIUS = 8;
GEAR_OUTER_RADIUS = 9;
GEAR_THICKNESS = 5;
SHAFT_HOLE_DIA = 3.3;

// Shaft parameters
SHAFT_DIA = 3.0;
SHAFT_LENGTH = 15;

// Arm parameters
ARM_LENGTH = 20;
ARM_WIDTH = 4;
ARM_HEIGHT = 3;

// Foam curl parameters
CURL_MAIN_SPHERE = 6;
CURL_MID_SPHERE = 5;
CURL_BASE_SPHERE = 4;

// Base plate
BASE_SIZE = 50;
BASE_THICKNESS = 3;
BASE_HOLE_DIA = 3.3;

// === MODULES ===

// Part 1: Base plate
module part_base_plate() {
    difference() {
        cube([BASE_SIZE, BASE_SIZE, BASE_THICKNESS], center=true);

        // Center shaft hole
        cylinder(h=BASE_THICKNESS + 2, d=BASE_HOLE_DIA, center=true);

        // Corner mounting holes
        for (x = [-1, 1], y = [-1, 1]) {
            translate([x * 20, y * 20, 0])
            cylinder(h=BASE_THICKNESS + 2, d=3.5, center=true);
        }
    }
}

// Part 2: 16T Gear only
module part_gear_only() {
    difference() {
        union() {
            // Base cylinder
            cylinder(h=GEAR_THICKNESS, r=GEAR_PITCH_RADIUS - 0.5, center=false);

            // Teeth
            for (i = [0:GEAR_TEETH-1]) {
                rotate([0, 0, i * 360/GEAR_TEETH])
                translate([GEAR_PITCH_RADIUS - 0.5, 0, 0])
                linear_extrude(height=GEAR_THICKNESS)
                polygon([
                    [0, -0.8],
                    [1.8, -0.4],
                    [1.8, 0.4],
                    [0, 0.8]
                ]);
            }
        }
        // Center shaft hole
        translate([0, 0, -1])
        cylinder(h=GEAR_THICKNESS + 2, d=SHAFT_HOLE_DIA, center=false);
    }
}

// Part 3: Shaft
module part_shaft() {
    cylinder(h=SHAFT_LENGTH, d=SHAFT_DIA, center=false);
}

// Part 4: Gear + Arm + Foam Curl (combined print piece)
module part_gear_arm_foam() {
    // Gear
    difference() {
        union() {
            // Base cylinder
            cylinder(h=GEAR_THICKNESS, r=GEAR_PITCH_RADIUS - 0.5, center=false);

            // Teeth
            for (i = [0:GEAR_TEETH-1]) {
                rotate([0, 0, i * 360/GEAR_TEETH])
                translate([GEAR_PITCH_RADIUS - 0.5, 0, 0])
                linear_extrude(height=GEAR_THICKNESS)
                polygon([
                    [0, -0.8],
                    [1.8, -0.4],
                    [1.8, 0.4],
                    [0, 0.8]
                ]);
            }

            // Arm
            translate([GEAR_PITCH_RADIUS/2, -ARM_WIDTH/2, GEAR_THICKNESS])
            cube([ARM_LENGTH - GEAR_PITCH_RADIUS/2, ARM_WIDTH, ARM_HEIGHT]);

            // Arm fillet
            translate([0, 0, GEAR_THICKNESS])
            cylinder(h=ARM_HEIGHT, r=ARM_WIDTH/2, center=false);

            // Foam curl at end of arm
            translate([ARM_LENGTH, 0, GEAR_THICKNESS + ARM_HEIGHT/2])
            rotate([0, 0, -30])
            foam_curl_solid();
        }
        // Center shaft hole
        translate([0, 0, -1])
        cylinder(h=GEAR_THICKNESS + 2, d=SHAFT_HOLE_DIA, center=false);
    }
}

// Foam curl shape (solid for printing)
module foam_curl_solid() {
    // Main curl body
    hull() {
        // Main curl tip
        translate([0, 0, 8])
        sphere(d=CURL_MAIN_SPHERE);

        // Curl body
        translate([-4, 0, 5])
        sphere(d=CURL_MID_SPHERE);

        // Lower curl
        translate([-7, 0, 1])
        sphere(d=CURL_BASE_SPHERE);

        // Back of curl
        translate([-3, 0, -2])
        sphere(d=3);

        // Extension
        translate([2, 0, 4])
        sphere(d=4);
    }

    // Spray detail
    for (i = [0:4]) {
        translate([2 + i*1.5, 0, 9 + i*0.5])
        sphere(d=2 - i*0.3);
    }

    // Side spray
    for (i = [0:2]) {
        translate([0, 3 + i*2, 7 - i])
        sphere(d=1.5);
        translate([0, -3 - i*2, 7 - i])
        sphere(d=1.5);
    }
}

// === RENDER SELECTED PART ===
if (PART_SELECT == 1) {
    echo("Rendering: Part 1 - Base Plate");
    part_base_plate();
}
else if (PART_SELECT == 2) {
    echo("Rendering: Part 2 - 16T Gear Only");
    part_gear_only();
}
else if (PART_SELECT == 3) {
    echo("Rendering: Part 3 - Shaft");
    part_shaft();
}
else if (PART_SELECT == 4) {
    echo("Rendering: Part 4 - Gear + Arm + Foam Curl");
    part_gear_arm_foam();
}
else {
    echo("ERROR: Invalid PART_SELECT value. Use 1, 2, 3, or 4.");
}

// Debug output
echo(str("=== ZONE 3 PRINT PARTS ==="));
echo(str("Selected part: ", PART_SELECT));
echo(str("Gear teeth: ", GEAR_TEETH));
echo(str("Arm length: ", ARM_LENGTH, "mm"));
