/*
 * SHAFT COUPLER - 3mm Motor Shaft to 8mm Worm Shaft
 *
 * Printable part: 1x
 * Print orientation: Standing (coupler axis vertical)
 *
 * Features:
 * - 3mm D-shaft bore (motor side)
 * - 8mm bore with set screw (worm shaft side)
 * - Flexible section for misalignment
 */

include <../common.scad>

$fn = 48;

// ============================================
// COUPLER PARAMETERS
// ============================================

COUPLER_OD = 16;
COUPLER_LENGTH = 25;

MOTOR_BORE = 3.1;            // 3mm + clearance
MOTOR_BORE_DEPTH = 10;
MOTOR_D_FLAT = 0.5;          // D-shaft flat depth

WORM_BORE = 8.1;             // 8mm + clearance
WORM_BORE_DEPTH = 12;

FLEX_SLOTS = 3;              // Number of flex slots
FLEX_DEPTH = 8;              // How deep slots cut

// ============================================
// MAIN COUPLER MODULE
// ============================================

module shaft_coupler() {
    difference() {
        // Main body
        coupler_body();

        // Motor bore (3mm D-shaft)
        motor_bore();

        // Worm bore (8mm)
        worm_bore();

        // Flex slots
        flex_slots();

        // Set screws
        set_screws();
    }
}

// ============================================
// COUPLER BODY
// ============================================

module coupler_body() {
    cylinder(d=COUPLER_OD, h=COUPLER_LENGTH);
}

// ============================================
// BORES
// ============================================

module motor_bore() {
    // 3mm bore from bottom
    translate([0, 0, -1])
        cylinder(d=MOTOR_BORE, h=MOTOR_BORE_DEPTH + 1);

    // D-shaft flat
    translate([MOTOR_BORE/2 - MOTOR_D_FLAT, -MOTOR_BORE, -1])
        cube([MOTOR_D_FLAT + 1, MOTOR_BORE * 2, MOTOR_BORE_DEPTH + 1]);
}

module worm_bore() {
    // 8mm bore from top
    translate([0, 0, COUPLER_LENGTH - WORM_BORE_DEPTH])
        cylinder(d=WORM_BORE, h=WORM_BORE_DEPTH + 1);
}

// ============================================
// FLEX SLOTS
// ============================================

module flex_slots() {
    // Helical slots for flexibility
    slot_width = 2;

    for (i = [0 : FLEX_SLOTS - 1]) {
        angle = i * 360 / FLEX_SLOTS;

        rotate([0, 0, angle])
        translate([0, -slot_width/2, MOTOR_BORE_DEPTH])
            cube([COUPLER_OD, slot_width, FLEX_DEPTH]);
    }
}

// ============================================
// SET SCREWS
// ============================================

module set_screws() {
    // Motor side set screw
    translate([0, 0, MOTOR_BORE_DEPTH/2])
    rotate([90, 0, 0])
        cylinder(d=M3_HOLE_DIA, h=COUPLER_OD, $fn=16);

    // Worm side set screw
    translate([0, 0, COUPLER_LENGTH - WORM_BORE_DEPTH/2])
    rotate([90, 0, 45])
        cylinder(d=M3_HOLE_DIA, h=COUPLER_OD, $fn=16);
}

// ============================================
// RENDER
// ============================================

color([0.5, 0.5, 0.55])
shaft_coupler();

// ============================================
// INFO
// ============================================

echo("=== SHAFT COUPLER ===");
echo(str("OD: ", COUPLER_OD, "mm"));
echo(str("Length: ", COUPLER_LENGTH, "mm"));
echo(str("Motor bore: ", MOTOR_BORE, "mm (D-shaft)"));
echo(str("Worm bore: ", WORM_BORE, "mm"));
echo("");
echo("Print quantity: 1");
echo("Print orientation: Vertical (standing)");
echo("Material: PETG or ABS recommended for flexibility");
