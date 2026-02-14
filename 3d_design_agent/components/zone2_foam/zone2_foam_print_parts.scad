// ============================================================
// Zone 2 Foam Gear - Print Parts
// ============================================================
// Individual parts for 3D printing
// Select part using PART_SELECT parameter
// ============================================================

// === PART SELECTION ===
// 1 = Base plate
// 2 = Gear only
// 3 = Shaft
// 4 = Gear + arm + foam as one piece
PART_SELECT = 1;

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
arm_length = 15;
arm_width = 4;
arm_thickness = 3;

// Foam parameters (MEDIUM)
foam_diameter = 12;

// Base plate parameters
base_width = 40;
base_depth = 40;
base_height = 5;

// Smoothness
$fn = 64;

// === MODULES ===

// Simple gear with teeth
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

// === PART 1: Base Plate ===
module part_base_plate() {
    difference() {
        translate([-base_width/2, -base_depth/2, 0])
            cube([base_width, base_depth, base_height]);

        // Shaft hole with clearance
        translate([0, 0, -0.1])
            cylinder(h=base_height + 0.2, d=shaft_diameter + 0.4);
    }
}

// === PART 2: Gear Only ===
module part_gear() {
    simple_gear(gear_teeth, gear_module, gear_thickness, gear_shaft_hole);
}

// === PART 3: Shaft ===
module part_shaft() {
    cylinder(h=shaft_height, d=shaft_diameter);
}

// === PART 4: Gear + Arm + Foam Combined ===
module part_gear_arm_foam() {
    union() {
        // Gear
        simple_gear(gear_teeth, gear_module, gear_thickness, gear_shaft_hole);

        // Arm on top of gear
        translate([0, 0, gear_thickness])
            foam_arm(arm_length, arm_width, arm_thickness);

        // Foam piece at end of arm
        // Positioned so bottom of sphere meets arm
        translate([arm_length, 0, gear_thickness + arm_thickness + foam_diameter/2 - 1])
            foam_piece(foam_diameter);
    }
}

// === RENDER SELECTED PART ===

echo(str("Rendering Part: ", PART_SELECT));

if (PART_SELECT == 1) {
    echo("Part 1: Base Plate");
    echo(str("Dimensions: ", base_width, " x ", base_depth, " x ", base_height, " mm"));
    part_base_plate();
}
else if (PART_SELECT == 2) {
    echo("Part 2: Gear Only");
    echo(str("Teeth: ", gear_teeth, ", Pitch radius: ", gear_pitch_radius, " mm"));
    part_gear();
}
else if (PART_SELECT == 3) {
    echo("Part 3: Shaft");
    echo(str("Diameter: ", shaft_diameter, " mm, Height: ", shaft_height, " mm"));
    part_shaft();
}
else if (PART_SELECT == 4) {
    echo("Part 4: Gear + Arm + Foam Combined");
    echo("Print with supports for foam overhang");
    part_gear_arm_foam();
}
else {
    echo("Invalid PART_SELECT. Use 1-4.");
}
