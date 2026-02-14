// PIVOT BRACKET MODULE
// For Starry Night Wave Surge Mechanism
// Mounts foam arm to wave structure with pivot connection
//
// Two variants:
//   Zone 2: 12mm x 8mm x 5mm at X=201, Y=42, Z=68mm
//   Zone 3: 15mm x 10mm x 6mm at X=126, Y=54, Z=77mm
//
// Features:
//   - Pivot hole for connecting rod
//   - Mounting holes for M3 screws to wave layer
//   - Foam arm attachment point

// === PARAMETERS ===

// Zone 2 Bracket (Mid Ocean)
ZONE2_BRACKET_SIZE = [12, 8, 5];    // [width, depth, height] mm
ZONE2_FOAM_ARM = 15;                // mm

// Zone 3 Bracket (Breaking Wave)
ZONE3_BRACKET_SIZE = [15, 10, 6];   // [width, depth, height] mm
ZONE3_FOAM_ARM = 20;                // mm

// Common parameters
PIVOT_HOLE_DIA = 3.3;              // mm (3mm pin + 0.3mm clearance)
PIN_DIAMETER = 3;                   // mm
MOUNTING_HOLE_DIA = 3.2;           // mm (M3 clearance)
ARM_WIDTH = 4;                      // mm
ARM_THICKNESS = 3;                  // mm

// Colors
C_BRACKET = [0.7, 0.7, 0.75];      // Metal color
C_ARM = [0.6, 0.6, 0.65];          // Slightly darker

// === MODULES ===

module pivot_bracket(size, arm_length) {
    // Bracket with pivot hole, mounting holes, and foam arm
    // size = [width, depth, height]
    // arm_length = distance to foam attachment point

    width = size[0];
    depth = size[1];
    height = size[2];

    // Bracket body
    color(C_BRACKET)
    difference() {
        // Main body
        translate([-width/2, -depth/2, 0])
            cube([width, depth, height]);

        // Pivot hole (vertical, for connecting rod)
        translate([0, 0, -1])
            cylinder(d=PIVOT_HOLE_DIA, h=height+2, $fn=24);

        // Mounting holes (2x, for M3 screws)
        for(x_off = [-width/4, width/4]) {
            translate([x_off, depth/4, -1])
                cylinder(d=MOUNTING_HOLE_DIA, h=height+2, $fn=16);
        }
    }

    // Pivot pin (extends up from bracket for rod connection)
    color(C_ARM)
    translate([0, 0, height])
        cylinder(d=PIN_DIAMETER, h=8, $fn=24);

    // Foam arm (extends horizontally)
    color(C_ARM)
    translate([0, 0, height])
        rotate([0, 0, 0])
            foam_arm(arm_length);
}

module foam_arm(arm_length) {
    // Arm that holds foam piece
    // Extends from pivot bracket to foam attachment point

    // Arm body
    hull() {
        // Base at pivot
        cylinder(d=ARM_WIDTH+2, h=ARM_THICKNESS, $fn=24);

        // End at foam attachment
        translate([arm_length, 0, 0])
            cylinder(d=ARM_WIDTH, h=ARM_THICKNESS, $fn=24);
    }

    // Foam attachment boss
    translate([arm_length, 0, ARM_THICKNESS])
        cylinder(d=ARM_WIDTH+2, h=2, $fn=24);
}

// Zone-specific convenience modules
module zone2_pivot_bracket() {
    pivot_bracket(ZONE2_BRACKET_SIZE, ZONE2_FOAM_ARM);
}

module zone3_pivot_bracket() {
    pivot_bracket(ZONE3_BRACKET_SIZE, ZONE3_FOAM_ARM);
}

// Bracket with vertical slider motion capability
// For the actual surge motion implementation
module surge_pivot_assembly(size, arm_length, surge_height=0) {
    // surge_height = current vertical offset from slider-crank kinematics

    width = size[0];
    depth = size[1];
    height = size[2];

    // Guide rail (fixed to structure)
    color(C_BRACKET)
    translate([-width/2-2, -depth/2, -5])
        cube([4, depth, 25]);

    // Sliding bracket (moves vertically)
    translate([0, 0, surge_height]) {
        // Slider body
        color(C_ARM)
        difference() {
            translate([-width/2, -depth/2, 0])
                cube([width, depth, height]);

            // Pivot hole for connecting rod
            translate([0, 0, -1])
                cylinder(d=PIVOT_HOLE_DIA, h=height+2, $fn=24);
        }

        // Foam arm
        translate([0, 0, height])
            foam_arm(arm_length);
    }
}

// === TEST RENDER ===

// Show both bracket variants
translate([0, 0, 0])
    zone2_pivot_bracket();

translate([30, 0, 0])
    zone3_pivot_bracket();

// Show surge assembly at different heights (uncomment)
// translate([60, 0, 0]) surge_pivot_assembly(ZONE3_BRACKET_SIZE, ZONE3_FOAM_ARM, 0);
// translate([90, 0, 0]) surge_pivot_assembly(ZONE3_BRACKET_SIZE, ZONE3_FOAM_ARM, 8);
// translate([120, 0, 0]) surge_pivot_assembly(ZONE3_BRACKET_SIZE, ZONE3_FOAM_ARM, 16);

// Animation test (uncomment)
// surge_h = sin($t * 360) * 8 + 8;  // 0 to 16mm stroke
// surge_pivot_assembly(ZONE3_BRACKET_SIZE, ZONE3_FOAM_ARM, surge_h);
