// =========================================================
// GUIDE PLATE — Post-Matrix Dampener Assembly
// =========================================================
// Two parallel plates with PTFE bushing holes in hex grid.
// Captures string from any angle (up to ~40°) via funnel entry,
// constrains to vertical for clean drop to blocks.
//
// Components:
//   - Upper plate (3mm thick, 19 bushing holes)
//   - Lower plate (3mm thick, 19 bushing holes)
//   - 15mm gap between plates (spacer posts)
//   - PTFE flanged grommets in each hole
//
// Mounted FIXED to frame (does NOT rotate with tiers).
// Aligned with block grid hex positions.
//
// Reference: ROPE_ROUTING_COMPLETE_ANALYSIS.md Section 6
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_UPPER = true;
SHOW_LOWER = true;
SHOW_SPACERS = true;
SHOW_BUSHINGS = true;

// =========================================================
// MAIN RENDER
// =========================================================

guide_plate_assembly();


// =========================================================
// GUIDE PLATE ASSEMBLY
// =========================================================

module guide_plate_assembly() {
    positions = hex_grid(HEX_RINGS, BLOCK_SPACING);
    plate_size = max(CH_LENS[2], 160); // cover hex grid (CH3 is longest channel)

    // Upper plate
    if (SHOW_UPPER)
        translate([0, 0, 0])
            guide_plate(positions, plate_size);

    // Lower plate
    if (SHOW_LOWER)
        translate([0, 0, -GUIDE_PLATE_THICK - GUIDE_PLATE_GAP])
            guide_plate(positions, plate_size);

    // Spacer posts (4 corners)
    // Posts span from bottom of upper plate to top of lower plate
    if (SHOW_SPACERS) {
        post_inset = 15;
        spacer_h = GUIDE_PLATE_GAP;  // 15mm gap between plates
        for (sx = [-1, 1]) for (sy = [-1, 1]) {
            px = sx * (plate_size / 2 - post_inset);
            py = sy * (plate_size / 2 - post_inset);

            // Spacer: starts at top of lower plate, extends up to bottom of upper plate
            color(C_FRAME)
            translate([px, py, -GUIDE_PLATE_THICK - spacer_h])
                cylinder(d = 8, h = spacer_h, $fn = 20);
        }
    }

    // PTFE bushing visualization
    if (SHOW_BUSHINGS) {
        for (pos = positions) {
            // Upper bushing
            translate([pos[0], pos[1], -0.5])
                ptfe_bushing();
            // Lower bushing
            translate([pos[0], pos[1], -GUIDE_PLATE_THICK - GUIDE_PLATE_GAP - 0.5])
                ptfe_bushing();
        }
    }

    echo(str("=== GUIDE PLATE ==="));
    echo(str("Bushing count: ", len(positions) * 2, " (", len(positions), " per plate)"));
    echo(str("Plate size: ", plate_size, "mm square"));
    echo(str("Gap between plates: ", GUIDE_PLATE_GAP, "mm"));
}


// =========================================================
// SINGLE GUIDE PLATE
// =========================================================

module guide_plate(positions, size) {
    color(C_GUIDE)
    difference() {
        // Plate body — rounded square
        translate([-size / 2, -size / 2, 0])
            linear_extrude(height = GUIDE_PLATE_THICK)
                offset(r = 5)
                offset(r = -5)
                    square([size, size]);

        // Bushing holes at each hex grid position
        for (pos = positions) {
            translate([pos[0], pos[1], -1]) {
                // Through-bore
                cylinder(h = GUIDE_PLATE_THICK + 2, d = GUIDE_FUNNEL_DIA + 0.2);

                // Funnel chamfer on top (entry side)
                translate([0, 0, GUIDE_PLATE_THICK + 1 - 0.3])
                    cylinder(h = 1, d1 = GUIDE_FUNNEL_DIA + 0.2, d2 = GUIDE_FUNNEL_DIA + 3);
            }
        }

        // Spacer post mounting holes
        post_inset = 15;
        for (sx = [-1, 1]) for (sy = [-1, 1]) {
            translate([sx * (size / 2 - post_inset), sy * (size / 2 - post_inset), -1])
                cylinder(h = GUIDE_PLATE_THICK + 2, d = 4.2); // M4 clearance
        }
    }
}


// =========================================================
// PTFE BUSHING (Flanged Grommet)
// =========================================================
// Press-fit into guide plate hole.
// Funnel top accepts string from angles up to ~40°.
// Bore constrains string to vertical.

module ptfe_bushing() {
    color([0.85, 0.85, 0.8])
    difference() {
        union() {
            // Body
            cylinder(h = GUIDE_PLATE_THICK + 1, d = GUIDE_FUNNEL_DIA);

            // Top flange (prevents pull-through, funnel shape)
            translate([0, 0, GUIDE_PLATE_THICK + 1])
                cylinder(h = 0.5, d1 = GUIDE_FUNNEL_DIA, d2 = GUIDE_FUNNEL_DIA + 2);

            // Bottom flange
            cylinder(h = 0.5, d = GUIDE_FUNNEL_DIA + 2);
        }

        // Through-bore
        translate([0, 0, -1])
            cylinder(h = GUIDE_PLATE_THICK + 4, d = GUIDE_BUSHING_BORE);

        // Funnel taper at top (accepts angled string)
        translate([0, 0, GUIDE_PLATE_THICK])
            cylinder(h = 2, d1 = GUIDE_BUSHING_BORE, d2 = GUIDE_FUNNEL_DIA - 0.5);
    }
}
