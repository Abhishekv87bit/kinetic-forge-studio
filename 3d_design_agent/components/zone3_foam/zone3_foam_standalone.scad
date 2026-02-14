// ============================================================
// ZONE 3 FOAM GEAR (16T) + FOAM CURL - STANDALONE TEST
// ============================================================
// Component: 16T gear with 20mm arm and large CURL foam piece
// Purpose: Breaking wave zone - most dramatic foam motion
// Position in assembly: [197, 50] at Z=77
// Meshes with: Wave Drive 30T gear (pitch_radius=15mm)
// ============================================================

// === CONFIGURATION ===
// Set to -1 for animation, or 0/90/180/270 for static positions
MANUAL_ANGLE = -1;  // [-1:animation, 0, 90, 180, 270]

// Quality settings
$fn = 64;

// === DIMENSIONS (all in mm) ===
// Gear parameters
GEAR_TEETH = 16;
GEAR_MODULE = 1.0;
GEAR_PITCH_RADIUS = 8;  // = teeth * module / 2
GEAR_OUTER_RADIUS = 9;  // pitch + 1 module
GEAR_THICKNESS = 5;
SHAFT_HOLE_DIA = 3.3;   // 3mm shaft + 0.3mm clearance

// Shaft parameters
SHAFT_DIA = 3.0;
SHAFT_LENGTH = 15;

// Arm parameters
ARM_LENGTH = 20;        // LONGEST arm - dramatic motion
ARM_WIDTH = 4;
ARM_HEIGHT = 3;

// Foam curl parameters (large breaking wave)
CURL_MAIN_SPHERE = 6;   // Main curl tip
CURL_MID_SPHERE = 5;    // Middle of curl
CURL_BASE_SPHERE = 4;   // Base of curl
CURL_TOTAL_SIZE = 15;   // Overall curl extent

// Base plate for testing
BASE_SIZE = 50;
BASE_THICKNESS = 3;
BASE_HOLE_DIA = 3.3;

// Colors
COLOR_GEAR = "Gold";
COLOR_ARM = "Orange";
COLOR_FOAM = [0.9, 0.95, 1.0];  // Light blue-white
COLOR_BASE = "DimGray";
COLOR_SHAFT = "Silver";

// === CALCULATED VALUES ===
current_angle = (MANUAL_ANGLE < 0) ? $t * 360 : MANUAL_ANGLE;

// Debug output
echo("=== ZONE 3 FOAM GEAR DEBUG ===");
echo(str("Current angle: ", current_angle, " degrees"));
echo(str("Gear: ", GEAR_TEETH, "T, pitch_radius=", GEAR_PITCH_RADIUS, "mm"));
echo(str("Arm length: ", ARM_LENGTH, "mm"));
echo(str("Animation: ", (MANUAL_ANGLE < 0) ? "ON" : "OFF"));

// === MODULES ===

// Simple gear with involute-like teeth
module simple_gear_16t() {
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

// Foam arm - rectangular cross-section
module foam_arm() {
    translate([GEAR_PITCH_RADIUS/2, 0, GEAR_THICKNESS])
    cube([ARM_LENGTH - GEAR_PITCH_RADIUS/2, ARM_WIDTH, ARM_HEIGHT], center=false);

    // Fillet at gear connection
    translate([0, ARM_WIDTH/2, GEAR_THICKNESS])
    rotate([0, 0, 0])
    cylinder(h=ARM_HEIGHT, r=ARM_WIDTH/2, center=false);
}

// Large foam CURL - breaking wave shape
// Uses hull of spheres arranged in a dramatic curl pattern
module foam_curl() {
    // Create a dramatic breaking wave curl shape
    hull() {
        // Main curl tip - largest sphere, positioned forward and up
        translate([0, 0, 8])
        sphere(d=CURL_MAIN_SPHERE);

        // Curl body - sweeps back
        translate([-4, 0, 5])
        sphere(d=CURL_MID_SPHERE);

        // Lower curl
        translate([-7, 0, 1])
        sphere(d=CURL_BASE_SPHERE);

        // Back of curl - creates the hollow feel
        translate([-3, 0, -2])
        sphere(d=3);

        // Extension for dramatic effect
        translate([2, 0, 4])
        sphere(d=4);
    }

    // Add spray detail - small spheres emanating from curl
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

// Test base plate
module base_plate() {
    difference() {
        translate([-BASE_SIZE/2, -BASE_SIZE/2, -BASE_THICKNESS])
        cube([BASE_SIZE, BASE_SIZE, BASE_THICKNESS]);

        // Shaft hole
        translate([0, 0, -BASE_THICKNESS - 1])
        cylinder(h=BASE_THICKNESS + 2, d=BASE_HOLE_DIA, center=false);

        // Corner mounting holes
        for (x = [-1, 1], y = [-1, 1]) {
            translate([x * 20, y * 20, -BASE_THICKNESS - 1])
            cylinder(h=BASE_THICKNESS + 2, d=3.5, center=false);
        }
    }
}

// Shaft
module shaft() {
    translate([0, 0, -BASE_THICKNESS])
    cylinder(h=SHAFT_LENGTH, d=SHAFT_DIA, center=false);
}

// === COMPLETE ASSEMBLY ===
module zone3_foam_assembly() {
    // Base plate (gray)
    color(COLOR_BASE)
    base_plate();

    // Shaft (silver)
    color(COLOR_SHAFT)
    shaft();

    // Rotating parts
    rotate([0, 0, current_angle]) {
        // 16T Gear (gold)
        color(COLOR_GEAR)
        simple_gear_16t();

        // Arm (orange)
        color(COLOR_ARM)
        translate([0, -ARM_WIDTH/2, 0])
        foam_arm();

        // Foam CURL at end of arm (light blue-white)
        color(COLOR_FOAM)
        translate([ARM_LENGTH, 0, GEAR_THICKNESS + ARM_HEIGHT/2])
        rotate([0, 0, -30])  // Tilt curl for dramatic effect
        foam_curl();
    }
}

// === RENDER ===
zone3_foam_assembly();

// === REFERENCE MARKERS (for debugging) ===
// Uncomment to show reference geometry
/*
// Pitch circle
%color("Red", 0.3)
translate([0, 0, GEAR_THICKNESS/2])
difference() {
    cylinder(h=0.5, r=GEAR_PITCH_RADIUS, center=true);
    cylinder(h=1, r=GEAR_PITCH_RADIUS - 0.2, center=true);
}

// Arm sweep circle
%color("Blue", 0.2)
translate([0, 0, GEAR_THICKNESS + ARM_HEIGHT/2])
difference() {
    cylinder(h=0.5, r=ARM_LENGTH + 8, center=true);
    cylinder(h=1, r=ARM_LENGTH - 2, center=true);
}
*/
