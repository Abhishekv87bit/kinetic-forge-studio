/*
 * FOLLOWER ARM - Connects Slider to Cam
 * ======================================
 *
 * Links each wave layer (via slider) to the cam below
 * Pivot at top connects to slider pivot boss
 * Roller at bottom rides on cam surface
 *
 * Print: 9x (3 waves x 3 layers)
 * Material: PLA or PETG
 * Layer height: 0.2mm
 * Infill: 40% (load-bearing)
 * Orientation: Flat on bed
 */

include <../common.scad>

// ============================================
// FOLLOWER ARM PARAMETERS
// ============================================

// Arm dimensions from common.scad:
// FOLLOWER_ARM_LENGTH = calculated for reach
// FOLLOWER_ARM_WIDTH = 10mm
// FOLLOWER_ARM_THICKNESS = 5mm
// FOLLOWER_ROLLER_DIA = 8mm

// Pivot end (top - attaches to slider)
PIVOT_END_DIA = 12;
PIVOT_HOLE_DIA = PIVOT_HOLE;   // 3.3mm for 3mm pin

// Roller end (bottom - contacts cam)
ROLLER_END_DIA = 14;
ROLLER_AXLE_DIA = 4 + TOL_CLEARANCE;  // 4.2mm for 4mm axle

// Arm taper
ARM_TAPER = 0.8;               // Multiply width at roller end

// ============================================
// MAIN MODULE - FOLLOWER ARM
// ============================================

module follower_arm() {
    /*
     * Complete follower arm:
     * - Pivot end at top (connects to slider)
     * - Tapered arm body
     * - Roller mount at bottom (cam contact)
     */

    color(C_MECHANISM)
    difference() {
        union() {
            // Main arm body
            arm_body();

            // Pivot end reinforcement
            pivot_end();

            // Roller end reinforcement
            roller_end();
        }

        // Pivot hole (top)
        pivot_hole();

        // Roller axle hole (bottom)
        roller_axle_hole();

        // Weight reduction slot (optional)
        // weight_reduction();
    }
}

// ============================================
// ARM BODY
// ============================================

module arm_body() {
    /*
     * Main arm connecting pivot to roller
     * Tapers from pivot (wider) to roller (narrower)
     * Hull between two shapes creates smooth taper
     */

    hull() {
        // Pivot end
        translate([0, 0, 0])
            cylinder(d = PIVOT_END_DIA, h = FOLLOWER_ARM_THICKNESS);

        // Roller end
        translate([0, -FOLLOWER_ARM_LENGTH, 0])
            cylinder(d = ROLLER_END_DIA, h = FOLLOWER_ARM_THICKNESS);
    }
}

// ============================================
// PIVOT END
// ============================================

module pivot_end() {
    /*
     * Top end where arm pivots on slider
     * Reinforced boss around pivot hole
     */

    // Already part of arm_body hull
    // Add any additional reinforcement here if needed

    // Chamfer for smooth motion
    translate([0, 0, FOLLOWER_ARM_THICKNESS])
        cylinder(d1 = PIVOT_END_DIA, d2 = PIVOT_END_DIA - 2, h = 1);
}

// ============================================
// ROLLER END
// ============================================

module roller_end() {
    /*
     * Bottom end with roller axle mount
     * Roller rides on cam surface
     */

    // Already part of arm_body hull
    // Add roller axle retention features

    // Outer washer boss (keeps roller centered)
    translate([0, -FOLLOWER_ARM_LENGTH, FOLLOWER_ARM_THICKNESS])
        cylinder(d = ROLLER_END_DIA - 2, h = 1);
}

// ============================================
// PIVOT HOLE
// ============================================

module pivot_hole() {
    /*
     * Hole for 3mm pivot pin
     * Pin connects arm to slider pivot boss
     */

    translate([0, 0, -1])
        cylinder(d = PIVOT_HOLE_DIA, h = FOLLOWER_ARM_THICKNESS + 3);
}

// ============================================
// ROLLER AXLE HOLE
// ============================================

module roller_axle_hole() {
    /*
     * Hole for roller axle (4mm)
     * Roller bearing/bushing rides on this
     */

    translate([0, -FOLLOWER_ARM_LENGTH, -1])
        cylinder(d = ROLLER_AXLE_DIA, h = FOLLOWER_ARM_THICKNESS + 3);
}

// ============================================
// WEIGHT REDUCTION (optional)
// ============================================

module weight_reduction() {
    /*
     * Optional slot to reduce arm weight
     * Uncomment in main module if needed
     */

    slot_length = FOLLOWER_ARM_LENGTH - 30;
    slot_width = FOLLOWER_ARM_WIDTH - 6;

    translate([-slot_width/2, -FOLLOWER_ARM_LENGTH + 15, -1])
        cube([slot_width, slot_length, FOLLOWER_ARM_THICKNESS + 2]);
}

// ============================================
// ROLLER (separate part)
// ============================================

module follower_roller() {
    /*
     * Roller that contacts cam surface
     * Rides on 4mm axle in roller end
     * Can use small bearing or just print bushing
     */

    roller_width = FOLLOWER_ARM_THICKNESS + 2;

    color([0.3, 0.3, 0.35])
    difference() {
        // Roller body
        cylinder(d = FOLLOWER_ROLLER_DIA, h = roller_width);

        // Axle hole
        translate([0, 0, -1])
            cylinder(d = 4 + TOL_SLIDING, h = roller_width + 2);
    }
}

// ============================================
// FOLLOWER ARM WITH ROLLER (visualization)
// ============================================

module follower_arm_assembly() {
    /*
     * Arm with roller attached for visualization
     */

    follower_arm();

    // Roller on axle
    translate([0, -FOLLOWER_ARM_LENGTH, -1])
        follower_roller();

    // Ghost of pivot pin
    %translate([0, 0, -2])
        cylinder(d = PIVOT_PIN_DIA, h = FOLLOWER_ARM_THICKNESS + 6);

    // Ghost of roller axle
    %translate([0, -FOLLOWER_ARM_LENGTH, -3])
        cylinder(d = 4, h = FOLLOWER_ARM_THICKNESS + 8);
}

// ============================================
// FOLLOWER ARM - PARAMETRIC LENGTH
// ============================================

module follower_arm_custom(arm_length) {
    /*
     * Follower arm with custom length
     * For different wave/layer positions
     */

    color(C_MECHANISM)
    difference() {
        hull() {
            cylinder(d = PIVOT_END_DIA, h = FOLLOWER_ARM_THICKNESS);
            translate([0, -arm_length, 0])
                cylinder(d = ROLLER_END_DIA, h = FOLLOWER_ARM_THICKNESS);
        }

        // Pivot hole
        translate([0, 0, -1])
            cylinder(d = PIVOT_HOLE_DIA, h = FOLLOWER_ARM_THICKNESS + 2);

        // Roller hole
        translate([0, -arm_length, -1])
            cylinder(d = ROLLER_AXLE_DIA, h = FOLLOWER_ARM_THICKNESS + 2);
    }
}

// ============================================
// PRINT PLATE - MULTIPLE ARMS
// ============================================

module follower_print_plate() {
    /*
     * 9 follower arms arranged for printing
     */

    spacing_x = 20;
    spacing_y = FOLLOWER_ARM_LENGTH + 15;

    for (col = [0:2]) {
        for (row = [0:2]) {
            translate([col * spacing_x, row * spacing_y, 0])
                follower_arm();
        }
    }
}

// ============================================
// RENDER
// ============================================

// Single arm with roller
follower_arm_assembly();

// Print plate preview
translate([60, 0, 0])
    follower_print_plate();

// Info
echo("============================================");
echo("FOLLOWER ARM");
echo("============================================");
echo(str("Arm length: ", FOLLOWER_ARM_LENGTH, "mm"));
echo(str("Arm thickness: ", FOLLOWER_ARM_THICKNESS, "mm"));
echo(str("Pivot hole: ", PIVOT_HOLE_DIA, "mm"));
echo(str("Roller axle hole: ", ROLLER_AXLE_DIA, "mm"));
echo(str("Roller diameter: ", FOLLOWER_ROLLER_DIA, "mm"));
echo("Print: 9 arms + 9 rollers");
echo("Orientation: Flat on bed");
echo("Infill: 40% for strength");
echo("============================================");
