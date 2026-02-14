/*
 * DRIP-ACTUATED PENDULUM v2
 * Mechanism: Simple pendulum with catch cup
 * Validated: From /validate calculations
 *
 * HOW IT WORKS:
 * 1. Water drips into cup
 * 2. Weight accumulates, pendulum tips
 * 3. Water drains through hole
 * 4. Pendulum swings back
 * 5. Repeat
 *
 * POWER: Gravity (no motor needed)
 * MOVING PARTS: 1 (pendulum assembly)
 */

// ==========================================
// PARAMETERS (from 2_calculations.md)
// ==========================================

// Pendulum arm
ARM_LENGTH = 60;        // mm - pivot to attachment points
ARM_WIDTH = 8;          // mm
ARM_THICKNESS = 4;      // mm
PIVOT_HOLE = 3.3;       // mm - for 3mm rod, 0.3mm clearance

// Fish (counterweight side)
FISH_LENGTH = 40;       // mm
FISH_HEIGHT = 15;       // mm
FISH_THICKNESS = 5;     // mm
FISH_OFFSET = 30;       // mm from pivot (left side)

// Catch cup (water side)
CUP_OUTER_D = 15;       // mm
CUP_INNER_D = 12;       // mm (wall = 1.5mm)
CUP_DEPTH = 12;         // mm
CUP_DRAIN = 2;          // mm diameter drain hole
CUP_OFFSET = 30;        // mm from pivot (right side)

// Counterweight (balances fish)
COUNTERWEIGHT_D = 8;    // mm - small cylinder
COUNTERWEIGHT_H = 4;    // mm - adds ~1.85g

// Frame
FRAME_WIDTH = 100;      // mm
FRAME_HEIGHT = 90;      // mm
FRAME_THICKNESS = 5;    // mm
FRAME_WALL = 3;         // mm
PIVOT_HEIGHT = 70;      // mm - pivot above base

// Printability thresholds
WALL_MIN = 1.2;
CLEARANCE_MIN = 0.3;

// ==========================================
// ANIMATION
// ==========================================

// Pendulum swing angle (simulates drip cycle)
// Physical driver: gravity + water weight imbalance
swing_angle = 25 * sin($t * 360);  // ±25° swing

// ==========================================
// PENDULUM ASSEMBLY (1 moving part)
// ==========================================

module pendulum() {
    // Central arm with pivot
    color("SaddleBrown")
    difference() {
        // Arm body
        hull() {
            // Center pivot area
            cylinder(h=ARM_THICKNESS, d=ARM_WIDTH*1.5, center=true, $fn=32);
            // Left end (fish side)
            translate([-FISH_OFFSET, 0, 0])
            cylinder(h=ARM_THICKNESS, d=ARM_WIDTH, center=true, $fn=24);
            // Right end (cup side)
            translate([CUP_OFFSET, 0, 0])
            cylinder(h=ARM_THICKNESS, d=ARM_WIDTH, center=true, $fn=24);
        }
        // Pivot hole
        cylinder(h=ARM_THICKNESS+2, d=PIVOT_HOLE, center=true, $fn=32);
    }

    // Fish on left side
    translate([-FISH_OFFSET, 0, 0])
    fish();

    // Catch cup on right side
    translate([CUP_OFFSET, 0, 0])
    catch_cup();

    // Counterweight (under cup)
    translate([CUP_OFFSET, 0, -ARM_THICKNESS/2 - COUNTERWEIGHT_H/2])
    color("Gray")
    cylinder(h=COUNTERWEIGHT_H, d=COUNTERWEIGHT_D, center=true, $fn=24);
}

// ==========================================
// FISH (decorative counterweight)
// ==========================================

module fish() {
    color("Coral")
    translate([0, 0, -ARM_THICKNESS/2 - FISH_HEIGHT/2])
    rotate([90, 0, 180])  // Fish faces outward
    scale([FISH_LENGTH/40, FISH_HEIGHT/15, FISH_THICKNESS/5])
    fish_shape();
}

module fish_shape() {
    // Simple stylized fish
    hull() {
        // Head
        translate([-15, 0, 0])
        sphere(d=12, $fn=24);
        // Body
        translate([0, 0, 0])
        sphere(d=10, $fn=24);
        // Tail base
        translate([12, 0, 0])
        scale([1, 0.4, 0.5])
        sphere(d=8, $fn=20);
    }
    // Tail fin
    hull() {
        translate([12, 0, 0])
        scale([0.5, 0.2, 0.3])
        sphere(d=6, $fn=16);
        translate([18, 3, 0])
        scale([0.3, 0.5, 0.2])
        sphere(d=5, $fn=16);
        translate([18, -3, 0])
        scale([0.3, 0.5, 0.2])
        sphere(d=5, $fn=16);
    }
}

// ==========================================
// CATCH CUP (collects water)
// ==========================================

module catch_cup() {
    color("SteelBlue")
    translate([0, 0, -ARM_THICKNESS/2 - CUP_DEPTH/2])
    difference() {
        // Outer cup
        cylinder(h=CUP_DEPTH, d=CUP_OUTER_D, center=true, $fn=32);
        // Inner hollow
        translate([0, 0, 1.5])  // Leave bottom thickness
        cylinder(h=CUP_DEPTH, d=CUP_INNER_D, center=true, $fn=32);
        // Drain hole at bottom
        translate([0, 0, -CUP_DEPTH/2])
        cylinder(h=4, d=CUP_DRAIN, center=true, $fn=16);
    }
}

// ==========================================
// FRAME (static)
// ==========================================

module frame() {
    color("BurlyWood", 0.9)
    difference() {
        union() {
            // Base plate
            translate([0, 0, FRAME_THICKNESS/2])
            cube([FRAME_WIDTH, FRAME_THICKNESS*2, FRAME_THICKNESS], center=true);

            // Left upright
            translate([-FRAME_WIDTH/2 + FRAME_WALL/2, 0, FRAME_HEIGHT/2])
            cube([FRAME_WALL, FRAME_THICKNESS*2, FRAME_HEIGHT], center=true);

            // Right upright
            translate([FRAME_WIDTH/2 - FRAME_WALL/2, 0, FRAME_HEIGHT/2])
            cube([FRAME_WALL, FRAME_THICKNESS*2, FRAME_HEIGHT], center=true);

            // Top cross beam (holds pivot)
            translate([0, 0, PIVOT_HEIGHT])
            cube([FRAME_WIDTH, FRAME_THICKNESS*2, FRAME_WALL], center=true);
        }

        // Pivot hole through top beam
        translate([0, 0, PIVOT_HEIGHT])
        rotate([90, 0, 0])
        cylinder(h=FRAME_THICKNESS*3, d=PIVOT_HOLE, center=true, $fn=32);
    }
}

// ==========================================
// PIVOT ROD (hardware)
// ==========================================

module pivot_rod() {
    color("Silver")
    translate([0, 0, PIVOT_HEIGHT])
    rotate([90, 0, 0])
    cylinder(h=FRAME_THICKNESS*2 + 10, d=3, center=true, $fn=24);
}

// ==========================================
// ASSEMBLY
// ==========================================

module assembly() {
    // Static frame
    frame();

    // Pivot rod
    pivot_rod();

    // Animated pendulum
    translate([0, 0, PIVOT_HEIGHT])
    rotate([0, swing_angle, 0])  // Swing about pivot
    pendulum();
}

// ==========================================
// RENDER
// ==========================================

assembly();

// ==========================================
// POWER PATH VERIFICATION
// ==========================================

echo("=== POWER PATH ===");
echo("Water drips → Catch cup (weight accumulates)");
echo("  → Gravity tips pendulum");
echo("  → Drain hole empties cup");
echo("  → Pendulum swings back (gravity)");
echo("Physical driver for swing_angle: GRAVITY + WATER WEIGHT");
echo("=== END POWER PATH ===");

// ==========================================
// PRINTABILITY VERIFICATION
// ==========================================

CUP_WALL = (CUP_OUTER_D - CUP_INNER_D) / 2;
PIVOT_CLEARANCE = PIVOT_HOLE - 3;

echo("=== PRINTABILITY ===");
echo(str("Cup wall: ", CUP_WALL, "mm - ", CUP_WALL >= WALL_MIN ? "PASS" : "FAIL"));
echo(str("Arm thickness: ", ARM_THICKNESS, "mm - ", ARM_THICKNESS >= WALL_MIN ? "PASS" : "FAIL"));
echo(str("Pivot clearance: ", PIVOT_CLEARANCE, "mm - ", PIVOT_CLEARANCE >= CLEARANCE_MIN ? "PASS" : "FAIL"));
echo("=== END PRINTABILITY ===");

// ==========================================
// INDIVIDUAL PARTS FOR PRINTING
// ==========================================

// Uncomment one at a time to export:
// translate([0, 80, 0]) pendulum();
// translate([0, -80, 0]) frame();
