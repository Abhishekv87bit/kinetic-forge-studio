// ============================================================================
// ZONE 1 FOAM GEAR - Print Parts
// ============================================================================
// Export individual parts for 3D printing
// Set PART_SELECT to choose which part to render/export
// ============================================================================

// === PART SELECTION ===
// 1 = Base plate only
// 2 = Gear only (no arm/foam)
// 3 = Shaft only
// 4 = Gear + Arm + Foam as one piece (recommended for printing)
PART_SELECT = 4;

// === PARAMETERS (same as standalone) ===
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
echo("=== PRINT PARTS MODE ===");
echo("Selected part:", PART_SELECT);
part_names = ["", "Base Plate", "Gear Only", "Shaft", "Gear+Arm+Foam"];
echo("Part name:", part_names[PART_SELECT]);

// === MODULES ===

// Simple gear tooth profile
module gear_tooth_2d(pitch_r, addendum, dedendum, tooth_angle) {
    tip_r = pitch_r + addendum;
    root_r = pitch_r - dedendum;

    // Simplified tooth profile
    tooth_width_pitch = tooth_angle * 0.4;
    tooth_width_tip = tooth_angle * 0.25;

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
        circle(r = root_r);
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * tooth_angle])
                gear_tooth_2d(pitch_r, addendum, dedendum, tooth_angle);
        }
    }
}

// === PART 1: Base Plate ===
module print_base_plate() {
    // Oriented flat for printing
    difference() {
        cube([base_size, base_size, base_thickness]);

        // Center shaft hole
        translate([base_size/2, base_size/2, -0.1])
            cylinder(h = base_thickness + 0.2, d = shaft_hole);

        // Corner mounting holes
        corner_offset = 5;
        for (x = [corner_offset, base_size - corner_offset])
            for (y = [corner_offset, base_size - corner_offset])
                translate([x, y, -0.1])
                    cylinder(h = base_thickness + 0.2, d = 3.2);
    }
}

// === PART 2: Gear Only ===
module print_gear_only() {
    // Gear flat on bed
    difference() {
        linear_extrude(height = gear_thickness)
            gear_profile_2d(gear_teeth, gear_module);

        // Shaft hole
        translate([0, 0, -0.1])
            cylinder(h = gear_thickness + 0.2, d = shaft_hole);
    }
}

// === PART 3: Shaft ===
module print_shaft() {
    // Shaft lying flat for printing (better layer adhesion)
    rotate([90, 0, 0])
        cylinder(h = shaft_length, d = shaft_diameter);
}

// === PART 4: Gear + Arm + Foam Combined ===
module print_gear_arm_foam() {
    // Gear with arm and foam as single piece
    union() {
        // Gear
        difference() {
            linear_extrude(height = gear_thickness)
                gear_profile_2d(gear_teeth, gear_module);

            // Shaft hole
            translate([0, 0, -0.1])
                cylinder(h = gear_thickness + 0.2, d = shaft_hole);
        }

        // Arm
        translate([arm_width/2, -arm_width/2, gear_thickness])
            cube([arm_length - arm_width/2, arm_width, arm_thickness]);

        // Foam piece (organic blob)
        translate([arm_length, 0, gear_thickness + arm_thickness])
        hull() {
            translate([0, 0, foam_height/2])
                sphere(d = foam_diameter * 0.8);
            translate([0, 0, foam_height * 0.8])
                sphere(d = foam_diameter * 0.5);
            translate([foam_diameter * 0.2, foam_diameter * 0.15, foam_height * 0.4])
                sphere(d = foam_diameter * 0.4);
            translate([-foam_diameter * 0.15, -foam_diameter * 0.2, foam_height * 0.5])
                sphere(d = foam_diameter * 0.35);
        }
    }
}

// === RENDER SELECTED PART ===
if (PART_SELECT == 1) {
    echo("Rendering: Base Plate");
    echo("Dimensions: ", base_size, "x", base_size, "x", base_thickness, "mm");
    print_base_plate();
}
else if (PART_SELECT == 2) {
    echo("Rendering: Gear Only");
    echo("Outer diameter:", gear_outer_radius * 2, "mm");
    echo("Thickness:", gear_thickness, "mm");
    print_gear_only();
}
else if (PART_SELECT == 3) {
    echo("Rendering: Shaft");
    echo("Diameter:", shaft_diameter, "mm");
    echo("Length:", shaft_length, "mm");
    print_shaft();
}
else if (PART_SELECT == 4) {
    echo("Rendering: Gear + Arm + Foam (combined)");
    echo("Recommended print orientation: gear flat on bed");
    echo("May need supports for foam overhang");
    print_gear_arm_foam();
}
else {
    echo("ERROR: Invalid PART_SELECT value. Use 1-4.");
}
