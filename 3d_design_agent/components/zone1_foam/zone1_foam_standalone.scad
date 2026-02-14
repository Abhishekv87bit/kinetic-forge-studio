// ============================================================================
// ZONE 1 FOAM GEAR + FOAM PIECE - Standalone Test Assembly
// ============================================================================
// Component: 12T gear with foam decoration on arm
// Meshes with: Wave Drive 30T gear (pitch_radius=15mm)
// Gear ratio: 12/30 = 0.4x speed
// ============================================================================

// === CONFIGURATION ===
// Set to -1 for animation, or 0/90/180/270 for static render positions
MANUAL_ANGLE = -1;  // [-1:animation, 0, 90, 180, 270]

// === CALCULATED ANGLE ===
current_angle = (MANUAL_ANGLE < 0) ? $t * 360 : MANUAL_ANGLE;

// === PARAMETERS ===
// Gear parameters (12T, module 1.0)
gear_teeth = 12;
gear_module = 1.0;
gear_pitch_radius = gear_teeth * gear_module / 2;  // = 6mm
gear_thickness = 5;
gear_addendum = gear_module;           // 1.0mm
gear_dedendum = gear_module * 1.25;    // 1.25mm
gear_outer_radius = gear_pitch_radius + gear_addendum;  // 7mm
gear_root_radius = gear_pitch_radius - gear_dedendum;   // 4.75mm

// Shaft parameters
shaft_diameter = 3.0;
shaft_hole = 3.3;  // 0.3mm clearance
shaft_length = 15;

// Arm parameters
arm_length = 12;      // from center to foam center
arm_width = 4;
arm_thickness = 3;

// Foam parameters
foam_diameter = 8;
foam_height = 6;

// Base parameters
base_size = 40;
base_thickness = 3;

// Quality
$fn = 64;

// === DEBUG OUTPUT ===
echo("=== ZONE 1 FOAM GEAR DEBUG ===");
echo("Current angle:", current_angle);
echo("Gear pitch radius:", gear_pitch_radius);
echo("Gear outer radius:", gear_outer_radius);
echo("Arm reaches to:", arm_length, "mm from center");
echo("Foam position at angle", current_angle, ":",
     [arm_length * cos(current_angle), arm_length * sin(current_angle)]);

// === MODULES ===

// Simple gear tooth profile
module gear_tooth_2d(pitch_r, addendum, dedendum, tooth_angle) {
    tip_r = pitch_r + addendum;
    root_r = pitch_r - dedendum;

    // Simplified tooth profile
    tooth_width_pitch = tooth_angle * 0.4;  // tooth width at pitch circle
    tooth_width_tip = tooth_angle * 0.25;   // narrower at tip

    polygon([
        [root_r * cos(-tooth_angle/2), root_r * sin(-tooth_angle/2)],
        [pitch_r * cos(-tooth_width_pitch), pitch_r * sin(-tooth_width_pitch)],
        [tip_r * cos(-tooth_width_tip), tip_r * sin(-tooth_width_tip)],
        [tip_r * cos(tooth_width_tip), tip_r * sin(tooth_width_tip)],
        [pitch_r * cos(tooth_width_pitch), pitch_r * sin(tooth_width_pitch)],
        [root_r * cos(tooth_angle/2), root_r * sin(tooth_angle/2)]
    ]);
}

// Complete gear profile
module gear_profile_2d(teeth, mod) {
    pitch_r = teeth * mod / 2;
    addendum = mod;
    dedendum = mod * 1.25;
    root_r = pitch_r - dedendum;
    tooth_angle = 360 / teeth;

    union() {
        // Root circle
        circle(r = root_r);

        // Teeth
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * tooth_angle])
                gear_tooth_2d(pitch_r, addendum, dedendum, tooth_angle);
        }
    }
}

// 3D Gear with shaft hole
module gear_12t() {
    color("Gold")
    difference() {
        linear_extrude(height = gear_thickness)
            gear_profile_2d(gear_teeth, gear_module);

        // Shaft hole
        translate([0, 0, -0.1])
            cylinder(h = gear_thickness + 0.2, d = shaft_hole);
    }
}

// Foam arm
module foam_arm() {
    color("DodgerBlue")
    translate([arm_width/2, -arm_width/2, gear_thickness])
        cube([arm_length - arm_width/2, arm_width, arm_thickness]);
}

// Organic foam piece using hull of spheres
module foam_piece() {
    color("White")
    translate([arm_length, 0, gear_thickness + arm_thickness])
    hull() {
        // Main blob
        translate([0, 0, foam_height/2])
            sphere(d = foam_diameter * 0.8);
        // Top bulge
        translate([0, 0, foam_height * 0.8])
            sphere(d = foam_diameter * 0.5);
        // Side details
        translate([foam_diameter * 0.2, foam_diameter * 0.15, foam_height * 0.4])
            sphere(d = foam_diameter * 0.4);
        translate([-foam_diameter * 0.15, -foam_diameter * 0.2, foam_height * 0.5])
            sphere(d = foam_diameter * 0.35);
    }
}

// Shaft
module shaft() {
    color("Silver")
    translate([0, 0, -base_thickness])
        cylinder(h = shaft_length, d = shaft_diameter);
}

// Test base plate
module base_plate() {
    color("DimGray")
    translate([-base_size/2, -base_size/2, -base_thickness])
    difference() {
        cube([base_size, base_size, base_thickness]);

        // Center shaft hole
        translate([base_size/2, base_size/2, -0.1])
            cylinder(h = base_thickness + 0.2, d = shaft_hole);

        // Corner mounting holes (optional M3)
        corner_offset = 5;
        for (x = [corner_offset, base_size - corner_offset])
            for (y = [corner_offset, base_size - corner_offset])
                translate([x, y, -0.1])
                    cylinder(h = base_thickness + 0.2, d = 3.2);
    }
}

// Combined gear + arm + foam (rotates together)
module gear_assembly() {
    gear_12t();
    foam_arm();
    foam_piece();
}

// === MAIN ASSEMBLY ===
module zone1_foam_assembly() {
    // Static parts
    base_plate();
    shaft();

    // Rotating parts
    rotate([0, 0, current_angle])
        gear_assembly();
}

// Render the assembly
zone1_foam_assembly();

// === POSITION MARKERS (for visual debugging) ===
// Uncomment to show reference circles
/*
color("Red", 0.3)
translate([0, 0, 0.1])
    difference() {
        cylinder(h = 0.2, r = gear_pitch_radius);
        cylinder(h = 0.4, r = gear_pitch_radius - 0.5);
    }
*/
