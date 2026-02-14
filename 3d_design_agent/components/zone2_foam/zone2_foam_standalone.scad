// ============================================================
// Zone 2 Foam Gear - Standalone Test Module
// ============================================================
// Part of Starry Night kinetic sculpture wave assembly
// 12T gear meshes with Wave Drive 30T gear
// Gear ratio: 12/30 = 0.4x speed
// ============================================================

// === CONFIGURATION ===
// Set to -1 for animation, or 0/90/180/270 for static positions
MANUAL_ANGLE = -1;  // -1 = animate with $t

// Calculate current angle
current_angle = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// === PARAMETERS ===
// Gear parameters
gear_teeth = 12;
gear_module = 1.0;
gear_pitch_radius = gear_teeth * gear_module / 2;  // 6mm
gear_outer_radius = gear_pitch_radius + gear_module;  // 7mm
gear_thickness = 5;
gear_shaft_hole = 3.3;  // 3mm shaft + 0.3mm clearance

// Shaft parameters
shaft_diameter = 3;
shaft_height = 15;

// Arm parameters
arm_length = 15;  // From gear center to foam center
arm_width = 4;
arm_thickness = 3;

// Foam parameters (MEDIUM - slightly larger than zone 1)
foam_diameter = 12;

// Base plate parameters
base_width = 40;
base_depth = 40;
base_height = 5;

// Z positions
base_z = 0;
shaft_z = base_height;
gear_z = shaft_z + 3;  // Gear sits 3mm up on shaft
arm_z = gear_z + gear_thickness;  // Arm on top of gear
foam_z = arm_z;

// Smoothness
$fn = 64;

// === DEBUG OUTPUT ===
echo("=== Zone 2 Foam Gear Debug ===");
echo(str("Current angle: ", current_angle, " degrees"));
echo(str("Gear pitch radius: ", gear_pitch_radius, " mm"));
echo(str("Gear outer radius: ", gear_outer_radius, " mm"));
echo(str("Foam position: (", arm_length * cos(current_angle), ", ",
         arm_length * sin(current_angle), ", ", foam_z, ")"));
echo(str("Foam diameter: ", foam_diameter, " mm (MEDIUM)"));

// === MODULES ===

// Simple gear with teeth (visual representation)
module simple_gear(teeth, mod, thickness, bore) {
    pitch_r = teeth * mod / 2;
    outer_r = pitch_r + mod;
    root_r = pitch_r - 1.25 * mod;
    tooth_angle = 360 / teeth;

    difference() {
        union() {
            // Root cylinder
            cylinder(h=thickness, r=root_r);

            // Teeth
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * tooth_angle])
                hull() {
                    translate([root_r - 0.5, 0, 0])
                        cylinder(h=thickness, r=0.5);
                    translate([outer_r - 0.3, 0, 0])
                        cylinder(h=thickness, r=0.3);
                }
            }
        }

        // Center bore
        translate([0, 0, -0.1])
            cylinder(h=thickness + 0.2, d=bore);
    }
}

// Foam arm
module foam_arm(length, width, thickness) {
    // Arm from center outward
    hull() {
        cylinder(h=thickness, d=width);
        translate([length - width/2, 0, 0])
            cylinder(h=thickness, d=width);
    }
}

// Foam piece (MEDIUM size)
module foam_piece(diameter) {
    sphere(d=diameter);
}

// Test base plate with shaft hole
module base_plate() {
    difference() {
        // Plate
        translate([-base_width/2, -base_depth/2, 0])
            cube([base_width, base_depth, base_height]);

        // Shaft hole
        translate([0, 0, -0.1])
            cylinder(h=base_height + 0.2, d=shaft_diameter + 0.4);
    }
}

// Shaft
module shaft() {
    cylinder(h=shaft_height, d=shaft_diameter);
}

// === ASSEMBLY ===

// Base plate (gray)
color("DimGray")
translate([0, 0, base_z])
    base_plate();

// Shaft (silver)
color("Silver")
translate([0, 0, shaft_z])
    shaft();

// Rotating assembly
rotate([0, 0, current_angle]) {
    // Gear (gold)
    color("Gold")
    translate([0, 0, gear_z])
        simple_gear(gear_teeth, gear_module, gear_thickness, gear_shaft_hole);

    // Arm (green)
    color("Green")
    translate([0, 0, arm_z])
        foam_arm(arm_length, arm_width, arm_thickness);

    // Foam piece (white) - MEDIUM size
    color("White")
    translate([arm_length, 0, foam_z + arm_thickness/2])
        foam_piece(foam_diameter);
}

// === COORDINATE REFERENCE ===
// Small axes indicator for debugging
module axes(length=5) {
    color("Red") cylinder(h=length, r=0.3);
    color("Green") rotate([0, 90, 0]) cylinder(h=length, r=0.3);
    color("Blue") rotate([-90, 0, 0]) cylinder(h=length, r=0.3);
}

// Uncomment to show axes at origin
// translate([0, 0, 0.1]) axes(10);
