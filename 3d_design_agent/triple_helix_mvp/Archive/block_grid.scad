// =========================================================
// BLOCK GRID — 19 Hex Blocks on 2-Ring Grid
// =========================================================
// Gravity-loaded output blocks. Each block hangs from one string,
// displaced vertically by the wave computation.
//
// Block: hex shell (30mm FF x 20mm H) with cavity for steel shot.
// Weight: 80g total (30g PLA shell + 50g steel shot).
// String attachment: through-hole at top center with retainer.
//
// Reference: TRIPLE_HELIX_MVP_MASTER_PROMPT.md Section 4
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_BLOCKS     = true;
SHOW_STRINGS    = true;
SHOW_SHOT_FILL  = true;

/* [Block Detail] */
SHELL_THICK     = 2.0;   // mm wall thickness
STRING_HOLE_DIA = 1.5;   // mm through-hole for string
RETAINER_DIA    = 4.0;   // mm washer/knot retainer recess
RETAINER_DEPTH  = 1.5;   // mm

// =========================================================
// MAIN RENDER
// =========================================================

block_grid_assembly(anim_t());


// =========================================================
// BLOCK GRID ASSEMBLY
// =========================================================

module block_grid_assembly(t = 0) {
    positions = hex_grid(HEX_RINGS, BLOCK_SPACING);

    for (i = [0 : len(positions) - 1]) {
        pos = positions[i];
        dz = block_disp(pos, t);  // wave displacement (pos = [x,y])

        translate([pos[0], pos[1], dz]) {
            if (SHOW_BLOCKS)
                hex_block();

            // String stub (from block up toward guide plate)
            if (SHOW_STRINGS)
                color(C_STRING)
                translate([0, 0, BLOCK_HEIGHT])
                    cylinder(d = STRING_DIA * 3, h = max(5, 50 - dz), $fn = 8);
        }
    }

    echo(str("=== BLOCK GRID ==="));
    echo(str("Block count: ", len(positions)));
    echo(str("Grid diameter: ", grid_diameter(positions), "mm"));
    echo(str("Block weight: ", BLOCK_WEIGHT, "g"));
}


// =========================================================
// HEX BLOCK
// =========================================================
// Hollow hex prism with fill cavity and string attachment.
// NOTE: Cavity volume ~9.8 cm³ — use fine steel shot (#8 or smaller)
// for 50g fill. String hole sealed at bottom with washer+knot.

module hex_block() {
    ff = BLOCK_FF;
    h  = BLOCK_HEIGHT;
    r  = ff / sqrt(3);  // circumscribed radius from flat-to-flat

    color(C_BLOCK)
    difference() {
        // Outer hex
        cylinder(r = r, h = h, $fn = 6);

        // Inner cavity (for steel shot fill)
        translate([0, 0, SHELL_THICK])
            cylinder(r = r - SHELL_THICK, h = h - SHELL_THICK * 2, $fn = 6);

        // String through-hole (top center)
        translate([0, 0, -1])
            cylinder(h = h + 2, d = STRING_HOLE_DIA);

        // Retainer recess on top face
        translate([0, 0, h - RETAINER_DEPTH])
            cylinder(h = RETAINER_DEPTH + 1, d = RETAINER_DIA);

        // Fill hole on bottom (for loading steel shot, sealed with tape/plug)
        translate([0, 0, -1])
            cylinder(h = SHELL_THICK + 2, d = 8); // 8mm fill port
    }

    // Steel shot fill visualization
    if (SHOW_SHOT_FILL)
        color([0.5, 0.5, 0.5, 0.4])
        translate([0, 0, SHELL_THICK + 1])
            cylinder(r = r - SHELL_THICK - 0.5, h = h - SHELL_THICK * 2 - 2, $fn = 6);
}


// =========================================================
// UTILITY
// =========================================================

function grid_diameter(positions) =
    let(
        max_r = max([for (p = positions) sqrt(p[0]*p[0] + p[1]*p[1])])
    ) 2 * max_r + BLOCK_FF;
