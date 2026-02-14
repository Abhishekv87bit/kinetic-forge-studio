/*
 * BEARING BLOCK - 608 Bearing Mount
 * ==================================
 *
 * Supports cam shaft via 608 bearing
 * Press-fit bearing pocket
 * Mounts to guide frame with M4 bolts
 *
 * Print: 2x (one each end of cam)
 * Material: PLA or PETG
 * Layer height: 0.2mm
 * Infill: 40%
 * Orientation: Pocket facing up
 */

include <../common.scad>

// ============================================
// BEARING BLOCK PARAMETERS
// ============================================

// From common.scad:
// BEARING_608_OD = 22mm
// BEARING_608_ID = 8mm
// BEARING_608_H = 7mm
// BEARING_POCKET_DIA = 22.1mm
// BEARING_POCKET_DEPTH = 7.5mm

// Block dimensions
BLOCK_WIDTH = BEARING_608_OD + 16;    // 38mm
BLOCK_DEPTH = BEARING_608_OD + 12;    // 34mm
BLOCK_HEIGHT = BEARING_608_H + 10;     // 17mm

// Mounting holes
MOUNT_HOLE_SPACING = 20;
MOUNT_HOLE_DIA = M4_HOLE;
MOUNT_COUNTERBORE_DIA = M4_HEAD_DIA + 1;
MOUNT_COUNTERBORE_DEPTH = M4_HEAD_DEPTH;

// Bearing retention features
BEARING_LIP_HEIGHT = 1;
BEARING_LIP_WIDTH = 2;

// ============================================
// MAIN MODULE - BEARING BLOCK
// ============================================

module bearing_block() {
    /*
     * Complete bearing block with:
     * - Press-fit bearing pocket
     * - Mounting holes for frame attachment
     * - Bearing retention lip
     * - Shaft clearance
     */

    color(C_MECHANISM)
    difference() {
        union() {
            // Main block body
            block_body();

            // Bearing retention lip
            bearing_lip();
        }

        // Bearing pocket
        bearing_pocket();

        // Shaft clearance hole
        shaft_clearance();

        // Mounting holes
        mounting_holes();
    }
}

// ============================================
// BLOCK BODY
// ============================================

module block_body() {
    /*
     * Main structural body
     * Chamfered edges for strength and appearance
     */

    chamfer = 3;

    translate([-BLOCK_WIDTH/2, -BLOCK_DEPTH/2, 0])
    hull() {
        // Main body
        translate([chamfer, chamfer, 0])
            cube([BLOCK_WIDTH - 2*chamfer, BLOCK_DEPTH - 2*chamfer, BLOCK_HEIGHT]);

        // Chamfered corners
        translate([chamfer, chamfer, chamfer])
        linear_extrude(height = BLOCK_HEIGHT - chamfer)
            offset(r = chamfer)
            square([BLOCK_WIDTH - 2*chamfer, BLOCK_DEPTH - 2*chamfer]);
    }
}

// ============================================
// BEARING POCKET
// ============================================

module bearing_pocket() {
    /*
     * Pocket for 608 bearing
     * Slightly undersized for press-fit
     * Entry chamfer for easy insertion
     */

    // Main pocket
    translate([0, 0, BLOCK_HEIGHT - BEARING_POCKET_DEPTH])
        cylinder(d = BEARING_POCKET_DIA, h = BEARING_POCKET_DEPTH + 1);

    // Entry chamfer
    translate([0, 0, BLOCK_HEIGHT - 1])
        cylinder(d1 = BEARING_POCKET_DIA, d2 = BEARING_POCKET_DIA + 2, h = 2);
}

// ============================================
// BEARING LIP
// ============================================

module bearing_lip() {
    /*
     * Lip around bearing pocket to retain bearing
     * Bearing sits on this lip
     */

    lip_od = BEARING_POCKET_DIA + BEARING_LIP_WIDTH * 2;
    lip_id = BEARING_608_ID + 2;  // Clearance for shaft

    translate([0, 0, BLOCK_HEIGHT - BEARING_POCKET_DEPTH - BEARING_LIP_HEIGHT])
    difference() {
        cylinder(d = lip_od, h = BEARING_LIP_HEIGHT);
        translate([0, 0, -1])
            cylinder(d = lip_id, h = BEARING_LIP_HEIGHT + 2);
    }
}

// ============================================
// SHAFT CLEARANCE
// ============================================

module shaft_clearance() {
    /*
     * Hole for shaft to pass through
     * Larger than shaft - bearing does the alignment
     */

    clearance_dia = SHAFT_DIA + 2;

    translate([0, 0, -1])
        cylinder(d = clearance_dia, h = BLOCK_HEIGHT - BEARING_POCKET_DEPTH + 2);
}

// ============================================
// MOUNTING HOLES
// ============================================

module mounting_holes() {
    /*
     * M4 holes with counterbore for frame mounting
     */

    for (dx = [-MOUNT_HOLE_SPACING/2, MOUNT_HOLE_SPACING/2]) {
        translate([dx, 0, -1]) {
            // Through hole
            cylinder(d = MOUNT_HOLE_DIA, h = BLOCK_HEIGHT + 2);

            // Counterbore from bottom
            cylinder(d = MOUNT_COUNTERBORE_DIA, h = MOUNT_COUNTERBORE_DEPTH + 1);
        }
    }
}

// ============================================
// BEARING BLOCK WITH BEARING (visualization)
// ============================================

module bearing_block_assembly() {
    /*
     * Block with bearing and shaft installed
     */

    bearing_block();

    // 608 bearing ghost
    %translate([0, 0, BLOCK_HEIGHT - BEARING_608_H])
    difference() {
        color(C_BEARING)
        cylinder(d = BEARING_608_OD, h = BEARING_608_H);
        translate([0, 0, -1])
            cylinder(d = BEARING_608_ID, h = BEARING_608_H + 2);
    }

    // Shaft ghost
    %translate([0, 0, -20])
    color([0.6, 0.6, 0.65])
        cylinder(d = SHAFT_DIA, h = 60);
}

// ============================================
// SPLIT BEARING BLOCK (alternative design)
// ============================================

module bearing_block_split_base() {
    /*
     * Split design: base plate mounts to frame
     * Allows bearing insertion from side
     */

    difference() {
        // Base plate
        translate([-BLOCK_WIDTH/2, -BLOCK_DEPTH/2, 0])
            cube([BLOCK_WIDTH, BLOCK_DEPTH, 8]);

        // Bearing cradle (semicircle)
        translate([0, 0, 8])
        rotate([0, 90, 0])
            cylinder(d = BEARING_POCKET_DIA, h = BLOCK_WIDTH + 2, center = true);

        // Shaft clearance
        translate([0, 0, -1])
            cylinder(d = SHAFT_DIA + 2, h = 20);

        // Mounting holes
        mounting_holes();
    }
}

module bearing_block_split_cap() {
    /*
     * Cap that holds bearing in cradle
     */

    cap_height = 10;

    difference() {
        // Cap body
        translate([-BLOCK_WIDTH/2, -BLOCK_DEPTH/2, 0])
            cube([BLOCK_WIDTH, BLOCK_DEPTH, cap_height]);

        // Bearing cradle (semicircle)
        rotate([0, 90, 0])
            cylinder(d = BEARING_POCKET_DIA, h = BLOCK_WIDTH + 2, center = true);

        // Bolt holes (from top)
        for (dx = [-MOUNT_HOLE_SPACING/2, MOUNT_HOLE_SPACING/2]) {
            translate([dx, 0, -1])
                cylinder(d = M4_HOLE, h = cap_height + 2);
        }
    }
}

// ============================================
// FLANGED BEARING BLOCK (alternative)
// ============================================

module bearing_block_flanged() {
    /*
     * Version with side flanges for horizontal mounting
     */

    flange_width = 15;
    flange_thick = 5;

    union() {
        bearing_block();

        // Side flanges
        for (x_sign = [-1, 1]) {
            translate([x_sign * (BLOCK_WIDTH/2), -flange_width/2, 0])
            difference() {
                cube([flange_thick, flange_width, BLOCK_HEIGHT]);

                // Flange mounting hole
                translate([flange_thick/2, flange_width/2, -1])
                    cylinder(d = M4_HOLE, h = BLOCK_HEIGHT + 2);
            }
        }
    }
}

// ============================================
// RENDER
// ============================================

// Standard bearing block with assembly
bearing_block_assembly();

// Alternative designs
translate([60, 0, 0]) {
    echo("Split design:");
    bearing_block_split_base();
    translate([0, 0, 8])
        %bearing_block_split_cap();
}

translate([120, 0, 0]) {
    echo("Flanged design:");
    bearing_block_flanged();
}

// Info
echo("============================================");
echo("BEARING BLOCK");
echo("============================================");
echo(str("Block size: ", BLOCK_WIDTH, " x ", BLOCK_DEPTH, " x ", BLOCK_HEIGHT, "mm"));
echo(str("Bearing: 608 (", BEARING_608_OD, " x ", BEARING_608_ID, " x ", BEARING_608_H, "mm)"));
echo(str("Pocket diameter: ", BEARING_POCKET_DIA, "mm (press fit)"));
echo(str("Mounting holes: 2x M4, ", MOUNT_HOLE_SPACING, "mm spacing"));
echo("");
echo("Print: 2 copies");
echo("Orientation: Bearing pocket facing UP");
echo("============================================");
