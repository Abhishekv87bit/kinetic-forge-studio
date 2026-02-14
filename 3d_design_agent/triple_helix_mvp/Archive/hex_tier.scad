// =========================================================
// HEX TIER — Single tier with pulleys on hex grid
// =========================================================
// Replaces matrix_tier_v2.scad (parallel channels) with
// hex-grid-aligned pulley stations.
//
// Architecture:
//   19 pulley stations on a 2-ring hex grid (spacing = HEX_SPACING)
//   5 slider rows (3+4+5+4+3) — same cam mapping as before
//   Each row = one horizontal slider strip
//   At each hex position: 2 redirect pulleys (fixed) + 1 slider pulley (moves)
//
// Coordinate system (display space — NO rotation needed):
//   X = slider travel direction
//   Y = row stacking direction (hex grid Y)
//   Z = vertical (tier thickness)
//
// The tier is a flat hexagonal pancake.
// Thickness in Z = TIER_THICK (the vertical extent).
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_HEX_PLATE     = true;
SHOW_REDIRECT_FP   = true;
SHOW_SLIDER_SP     = true;
SHOW_SLIDER_RAILS  = true;
SHOW_PASS_HOLES    = true;   // show rope pass-through holes

// =========================================================
// HEX GRID PARAMETERS (override V5 channel params)
// =========================================================

// Hex grid spacing = block spacing (so pulleys align with blocks)
HEX_SPACING = BLOCK_SPACING;  // 32mm

// Row Y-positions (hex grid rows perpendicular to slider X-direction)
ROW_YS = [
    -2 * HEX_SPACING * sqrt(3)/2,   // Row A: Y = -55.4mm (3 stations)
    -1 * HEX_SPACING * sqrt(3)/2,   // Row B: Y = -27.7mm (4 stations)
     0,                               // Row C: Y = 0       (5 stations)
     1 * HEX_SPACING * sqrt(3)/2,   // Row D: Y = +27.7mm (4 stations)
     2 * HEX_SPACING * sqrt(3)/2    // Row E: Y = +55.4mm (3 stations)
];

// Pulley counts per row (same as V5: 3+4+5+4+3 = 19)
ROW_COUNTS = [3, 4, 5, 4, 3];

// Pulley X positions per row (hex grid positions)
// Even rows (A, C, E): centered at x=0
// Odd rows (B, D): offset by HEX_SPACING/2
function row_pulley_xs(row_idx) =
    let(count = ROW_COUNTS[row_idx],
        // Hex grid: even rows (0,2,4) centered, odd rows (1,3) offset by half
        offset = (row_idx % 2 == 0) ? 0 : HEX_SPACING / 2,
        start = -((count - 1) / 2) * HEX_SPACING + offset)
    [for (i = [0 : count - 1]) start + i * HEX_SPACING];

// =========================================================
// TIER DIMENSIONS
// =========================================================

// U-detour geometry: redirect pulleys above and below slider pulley
// FP at Z = ±REDIRECT_OFFSET, SP at Z = 0
REDIRECT_OFFSET = FP_ROW_Y;  // 12mm — distance from center to redirect pulleys

// Tier thickness = total Z extent including plates
// Top plate at Z = +TIER_THICK/2, bottom plate at Z = -TIER_THICK/2
TIER_THICK = 2 * REDIRECT_OFFSET + FP_OD + 4;  // 2×12 + 8 + 4 = 36mm

// Hex plate radius (circumscribed circle of the hex grid + margin)
HEX_PLATE_R = 64 + 10;  // outermost pulley at 64mm + 10mm margin = 74mm

// Slider strip dimensions
SLIDER_STRIP_H  = 3.0;    // strip thickness in Z
SLIDER_STRIP_W  = 10.0;   // strip width in Y (perpendicular to travel)

// Rope hole diameter through top/bottom plates
ROPE_HOLE_DIA = 4.0;

// =========================================================
// STANDALONE RENDER
// =========================================================
hex_tier([0, 0, 0, 0, 0]);

// =========================================================
// HEX TIER MODULE
// =========================================================
// row_disps: array of 5 displacement values (one per ROW/slider strip)
//   [Row_A_disp, Row_B_disp, Row_C_disp, Row_D_disp, Row_E_disp]

module hex_tier(row_disps) {

    // --- TOP AND BOTTOM PLATES (hex shaped) ---
    if (SHOW_HEX_PLATE) {
        for (z_sign = [-1, 1]) {
            color([0.6, 0.6, 1.0, 0.7])
            translate([0, 0, z_sign * (TIER_THICK/2 - WALL_THICKNESS/2)])
                linear_extrude(height = WALL_THICKNESS, center = true)
                    circle(r = HEX_PLATE_R, $fn = 6);
        }
    }

    // --- PULLEY STATIONS (19 positions) ---
    for (row = [0 : 4]) {
        row_y = ROW_YS[row];
        xs = row_pulley_xs(row);
        slide_disp = row_disps[row];

        for (col = [0 : ROW_COUNTS[row] - 1]) {
            px = xs[col];

            // Fixed redirect pulleys (upper and lower)
            if (SHOW_REDIRECT_FP) {
                for (z_sign = [-1, 1]) {
                    translate([px, row_y, z_sign * REDIRECT_OFFSET])
                        redirect_pulley();
                }
            }

            // Slider pulley (moves with strip)
            if (SHOW_SLIDER_SP) {
                translate([px + slide_disp, row_y, 0])
                    slider_pulley();
            }

            // Rope pass-through holes in top and bottom plates
            if (SHOW_PASS_HOLES && SHOW_HEX_PLATE) {
                for (z_sign = [-1, 1]) {
                    color([0.3, 0.3, 0.3])
                    translate([px, row_y, z_sign * (TIER_THICK/2 - WALL_THICKNESS/2)])
                        cylinder(d = ROPE_HOLE_DIA, h = WALL_THICKNESS + 1, center = true, $fn = 16);
                }
            }
        }

        // Slider rail (one per row)
        if (SHOW_SLIDER_RAILS) {
            // Rail extends from first to last pulley + travel margin
            first_x = xs[0];
            last_x  = xs[ROW_COUNTS[row] - 1];
            rail_len = (last_x - first_x) + 2 * ECCENTRICITY + 20;
            rail_cx  = (first_x + last_x) / 2;

            color(C_SLIDER, 0.6)
            translate([rail_cx + slide_disp, row_y, 0])
                cube([rail_len, SLIDER_STRIP_W, SLIDER_STRIP_H], center = true);
        }
    }

    // --- ECHO VERIFICATION ---
    echo(str("=== HEX TIER ==="));
    echo(str("Stations: 19 on hex grid (spacing=", HEX_SPACING, "mm)"));
    echo(str("Rows: ", ROW_COUNTS));
    echo(str("Tier thickness: ", TIER_THICK, "mm"));
    echo(str("Hex plate radius: ", HEX_PLATE_R, "mm"));
    echo(str("Row Y positions: ", ROW_YS));

    // Print all 19 station positions
    for (row = [0 : 4]) {
        xs = row_pulley_xs(row);
        echo(str("  Row ", row, " (Y=", ROW_YS[row], "): X = ", xs));
    }
}


// =========================================================
// REDIRECT PULLEY (fixed — mounted to plate structure)
// =========================================================
module redirect_pulley() {
    // Pulley body
    color(C_NYLON)
    rotate([90, 0, 0])
        difference() {
            cylinder(d = FP_OD, h = FP_WIDTH, center = true, $fn = 24);
            cylinder(d = FP_AXLE_DIA + 2*PIP_CLEARANCE, h = FP_WIDTH + 1, center = true);
        }

    // Axle (vertical post segment)
    color(C_STEEL)
    rotate([90, 0, 0])
        cylinder(d = FP_AXLE_DIA, h = FP_WIDTH + 4, center = true, $fn = 16);
}


// =========================================================
// SLIDER PULLEY (moves with slider strip)
// =========================================================
module slider_pulley() {
    // Pulley body
    color(C_NYLON)
    rotate([90, 0, 0])
        difference() {
            cylinder(d = SP_OD, h = SP_WIDTH, center = true, $fn = 24);
            cylinder(d = SP_AXLE_DIA + 2*PIP_CLEARANCE, h = SP_WIDTH + 1, center = true);
        }

    // Axle
    color(C_STEEL)
    rotate([90, 0, 0])
        cylinder(d = SP_AXLE_DIA, h = SP_WIDTH + 2, center = true, $fn = 16);
}
