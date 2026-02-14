/*
 * LAYER SLIDER - Mounting Block for Wave Layers
 * ==============================================
 *
 * Each wave layer attaches to a slider block
 * Slider rides on vertical 4mm guide rod
 * Has pivot hole for follower arm attachment
 * Has slot to capture wave profile mounting tab
 *
 * Print: 9x (3 waves x 3 layers)
 * Material: PLA or PETG
 * Layer height: 0.2mm
 * Infill: 30% (structural part)
 * Orientation: Print upright (guide hole vertical)
 */

include <../common.scad>

// ============================================
// SLIDER PARAMETERS
// ============================================

// All from common.scad:
// SLIDER_WIDTH = 16mm
// SLIDER_DEPTH = 12mm
// SLIDER_HEIGHT = 18mm
// GUIDE_ROD_HOLE = 4.3mm
// MOUNT_TAB_SLOT_WIDTH = 4.4mm

// Additional features
PIVOT_BOSS_DIA = 12;       // Boss around follower pivot
PIVOT_BOSS_HEIGHT = 6;     // Below slider body

// Anti-rotation features
GUIDE_SLOT_WIDTH = GUIDE_ROD_HOLE + 1;   // Slot instead of hole for anti-rotation

// ============================================
// MAIN MODULE - LAYER SLIDER
// ============================================

module layer_slider() {
    /*
     * Complete slider block with all features:
     * - Guide rod bearing surface (vertical hole)
     * - Layer mounting slot (side)
     * - Follower arm pivot (bottom)
     * - Anti-rotation guide slot
     */

    difference() {
        union() {
            // Main body
            slider_body();

            // Layer mounting tab
            layer_mount_tab();

            // Follower pivot boss
            follower_pivot_boss();
        }

        // Guide rod hole (vertical through body)
        guide_rod_hole();

        // Follower pivot hole (horizontal through boss)
        follower_pivot_hole();

        // Layer mounting slot
        layer_mount_slot();

        // Set screw for layer retention
        layer_set_screw_hole();
    }
}

// ============================================
// SLIDER BODY
// ============================================

module slider_body() {
    /*
     * Main block with chamfered edges
     * Guide rod passes vertically through center
     */

    chamfer = 2;

    translate([-SLIDER_WIDTH/2, -SLIDER_DEPTH/2, 0])
    hull() {
        // Main body with chamfers
        translate([chamfer, chamfer, 0])
            cube([SLIDER_WIDTH - 2*chamfer, SLIDER_DEPTH - 2*chamfer, SLIDER_HEIGHT]);

        // Chamfer corners
        translate([chamfer, chamfer, chamfer])
            cube([SLIDER_WIDTH - 2*chamfer, SLIDER_DEPTH - 2*chamfer, SLIDER_HEIGHT - 2*chamfer]);

        translate([0, chamfer, chamfer])
            cube([SLIDER_WIDTH, SLIDER_DEPTH - 2*chamfer, SLIDER_HEIGHT - 2*chamfer]);

        translate([chamfer, 0, chamfer])
            cube([SLIDER_WIDTH - 2*chamfer, SLIDER_DEPTH, SLIDER_HEIGHT - 2*chamfer]);
    }
}

// ============================================
// LAYER MOUNT TAB
// ============================================

module layer_mount_tab() {
    /*
     * Tab extending to side for wave layer slot
     * Wave profile mounting tab inserts into slot here
     */

    tab_z = 3;  // Height above slider base

    translate([SLIDER_WIDTH/2, -MOUNT_TAB_DEPTH/2, tab_z])
        cube([MOUNT_TAB_WIDTH, MOUNT_TAB_DEPTH, SLIDER_HEIGHT - tab_z - 2]);
}

// ============================================
// FOLLOWER PIVOT BOSS
// ============================================

module follower_pivot_boss() {
    /*
     * Reinforced boss on bottom for follower arm pivot
     * Pivot pin passes horizontally through this
     */

    translate([0, 0, -PIVOT_BOSS_HEIGHT])
    hull() {
        // Cylinder for pivot
        cylinder(d = PIVOT_BOSS_DIA, h = PIVOT_BOSS_HEIGHT);

        // Blend into body
        translate([-PIVOT_BOSS_DIA/2 + 2, -4, PIVOT_BOSS_HEIGHT - 1])
            cube([PIVOT_BOSS_DIA - 4, 8, 1]);
    }
}

// ============================================
// GUIDE ROD HOLE
// ============================================

module guide_rod_hole() {
    /*
     * Vertical hole for 4mm guide rod
     * 4.3mm diameter for sliding fit
     * Full length through slider
     */

    translate([0, 0, -PIVOT_BOSS_HEIGHT - 1])
        cylinder(d = GUIDE_ROD_HOLE, h = SLIDER_HEIGHT + PIVOT_BOSS_HEIGHT + 2);

    // Entry chamfer top
    translate([0, 0, SLIDER_HEIGHT - 1])
        cylinder(d1 = GUIDE_ROD_HOLE, d2 = GUIDE_ROD_HOLE + 2, h = 2);

    // Entry chamfer bottom
    translate([0, 0, -PIVOT_BOSS_HEIGHT - 1])
        cylinder(d2 = GUIDE_ROD_HOLE, d1 = GUIDE_ROD_HOLE + 2, h = 2);
}

// ============================================
// FOLLOWER PIVOT HOLE
// ============================================

module follower_pivot_hole() {
    /*
     * Horizontal hole for 3mm pivot pin
     * Passes through pivot boss
     * Follower arm rotates on this pin
     */

    // Main hole
    translate([0, -PIVOT_BOSS_DIA/2 - 1, -PIVOT_BOSS_HEIGHT/2])
    rotate([-90, 0, 0])
        cylinder(d = PIVOT_HOLE, h = PIVOT_BOSS_DIA + 2);

    // Countersink one side for pin retention
    translate([0, PIVOT_BOSS_DIA/2, -PIVOT_BOSS_HEIGHT/2])
    rotate([90, 0, 0])
        cylinder(d1 = PIVOT_HOLE, d2 = PIVOT_HOLE + 2, h = 2);
}

// ============================================
// LAYER MOUNT SLOT
// ============================================

module layer_mount_slot() {
    /*
     * Vertical slot to capture wave profile mounting tab
     * Slot width = layer thickness + tolerance
     */

    slot_depth = MOUNT_TAB_WIDTH - 2;  // Leave 2mm wall
    slot_height = SLIDER_HEIGHT + 2;

    translate([SLIDER_WIDTH/2 + MOUNT_TAB_WIDTH - slot_depth,
               -MOUNT_TAB_SLOT_WIDTH/2,
               -1])
        cube([slot_depth + 1, MOUNT_TAB_SLOT_WIDTH, slot_height]);
}

// ============================================
// LAYER SET SCREW
// ============================================

module layer_set_screw_hole() {
    /*
     * M3 set screw to lock layer tab in slot
     * Accessible from outside
     */

    screw_z = SLIDER_HEIGHT/2;

    translate([SLIDER_WIDTH/2 + MOUNT_TAB_WIDTH/2, -MOUNT_TAB_DEPTH/2 - 1, screw_z])
    rotate([-90, 0, 0])
        cylinder(d = M3_HOLE, h = MOUNT_TAB_DEPTH + 2);
}

// ============================================
// SLIDER WITH LAYER ATTACHED (visualization)
// ============================================

module slider_with_layer_preview() {
    /*
     * Preview showing how layer attaches
     */

    // Slider
    color(C_MECHANISM)
        layer_slider();

    // Ghost of layer tab
    %translate([SLIDER_WIDTH/2 + 2, -LAYER_THICKNESS/2, 4])
        cube([MOUNT_TAB_WIDTH - 4, LAYER_THICKNESS, SLIDER_HEIGHT - 8]);

    // Ghost of guide rod
    %translate([0, 0, -20])
        cylinder(d = GUIDE_ROD_DIA, h = GUIDE_ROD_LENGTH);

    // Ghost of follower arm pivot
    %translate([0, -PIVOT_BOSS_DIA/2, -PIVOT_BOSS_HEIGHT/2])
    rotate([-90, 0, 0])
        cylinder(d = PIVOT_PIN_DIA, h = PIVOT_BOSS_DIA);
}

// ============================================
// PRINT PLATE - MULTIPLE SLIDERS
// ============================================

module slider_print_plate() {
    /*
     * 9 sliders arranged for printing
     * Spaced 25mm apart
     */

    spacing = 25;

    for (row = [0:2]) {
        for (col = [0:2]) {
            translate([col * spacing, row * spacing, 0])
                layer_slider();
        }
    }
}

// ============================================
// RENDER
// ============================================

// Single slider
slider_with_layer_preview();

// Print plate preview
translate([80, 0, 0])
    slider_print_plate();

// Info
echo("============================================");
echo("LAYER SLIDER");
echo("============================================");
echo(str("Size: ", SLIDER_WIDTH, " x ", SLIDER_DEPTH, " x ", SLIDER_HEIGHT, "mm"));
echo(str("Guide rod hole: ", GUIDE_ROD_HOLE, "mm"));
echo(str("Layer slot: ", MOUNT_TAB_SLOT_WIDTH, "mm wide"));
echo(str("Pivot hole: ", PIVOT_HOLE, "mm"));
echo("Print: 9 copies (3 waves x 3 layers)");
echo("Orientation: Guide hole vertical");
echo("Infill: 30% recommended");
echo("============================================");
