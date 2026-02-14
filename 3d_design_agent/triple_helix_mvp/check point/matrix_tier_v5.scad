// =========================================================
// MATRIX TIER V5 — Hex-Parametric Prototype (Single Tier)
// =========================================================
// 75% scale: HEX_R=88.5 → 9 channels (was 13).
// Everything derives from HEX_R via config_v5.scad.
//
// Print-in-place with captive sliders and pulleys.
// Side walls only — no top/bottom plates (tiers stack openly).
//
// Coordinate system (before assembly rotation):
//   X = slider travel (channel direction) — corner-to-corner
//   Y = housing depth (rope routing direction)
//   Z = channel stacking — flat-to-flat
// =========================================================

include <config_v5.scad>

$fn = 40;

// =============================================
// DISPLAY TOGGLES
// =============================================
SHOW_WALLS          = true;
SHOW_SLIDER_PLATES  = true;
SHOW_FIXED_PULLEYS  = true;
SHOW_SLIDER_PULLEYS = true;
SHOW_HEX_CLIP       = true;
SHOW_HEX_GHOST      = true;

// =============================================
// TIER-SPECIFIC PRINT TOLERANCES
// =============================================
/* [Print-in-Place] */
PIP_CLEARANCE  = 0.3;      // slider-to-axle gap
PIP_Z_GAP      = 0.3;      // Z gap for captive parts
PIP_PULLEY_GAP = 0.4;      // pulley-to-wall gap (V5 addition)

// =============================================
// TIER-SPECIFIC DERIVED DIMENSIONS
// =============================================

/* [Guide Rail] */
RAIL_HEIGHT    = 4.0;
RAIL_DEPTH     = 1.0;
RAIL_TOLERANCE = 0.4;
END_STOP_W     = 5.0;
WINDOW_WIDTH   = 20.0;
WINDOW_HEIGHT  = min(16.0, HOUSING_HEIGHT - 4);

/* [Pulleys — ROLLERS (0.5mm clearance each side)] */
FP_WIDTH       = CH_GAP - 1.0;                // 10.5mm
FP_AXLE_DIA    = 3.0;
S_GAP          = 5.0;
SP_WIDTH       = S_GAP - 1.0;                 // 4.0mm
SP_AXLE_DIA    = 3.0;

// Slider plate Y-dimension
SLIDER_PLATE_Y = SP_OD + 2;  // 10mm

// Wall margin for axle pocket
WALL_MARGIN_AXLE = 4;

// Slider strip lengths — asymmetric
SLIDER_MARGIN_HELIX = SP_OD/2 + END_STOP_W + 1;  // 10mm
SLIDER_MARGIN_ARM   = SP_OD/2 + 1;                // 5mm

// Axle lengths
FP_AXLE_LEN = CH_GAP + 2 * WALL_THICKNESS - 0.2;
_plate_t = (CH_GAP/2) - (S_GAP/2) - PIP_Z_GAP;
_slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;
SP_AXLE_LEN = S_GAP + 2 * (_plate_t - _slot_d) - 0.2;

// =============================================
// DERIVED ARRAYS
// =============================================

function _culled_span(ch_idx) =
    let(d = CH_OFFSETS[ch_idx],
        len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) == 0 ? 0 :
    let(min_x = min(cols), max_x = max(cols),
        maxp = max(abs(min_x), abs(max_x)))
    2 * (maxp + FP_OD/2 + WALL_MARGIN_AXLE);

CH_WALL_LENS = [for (i = [0:NUM_CHANNELS-1])
    max(CH_LENS[i], _culled_span(i))
];

function _culled_col_span(ch_idx) =
    let(d = CH_OFFSETS[ch_idx],
        len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) <= 1 ? 0 : max(cols) - min(cols);

CH_S_LENS = [for (i = [0:NUM_CHANNELS-1])
    (COL_COUNTS[i] > 0) ?
        _culled_col_span(i) + SLIDER_MARGIN_HELIX + SLIDER_MARGIN_ARM : 0
];

// =============================================
// VERIFICATION ECHOES
// =============================================
echo(str("===== MATRIX TIER V5 — 75% PROTOTYPE ====="));
echo(str("HEX_R=", HEX_R, "  C2C=", HEX_C2C, "mm  FF=", round(HEX_FF*10)/10, "mm"));
echo(str("Channels: ", NUM_CHANNELS, " (odd)"));
echo(str("COL_PITCH=", COL_PITCH, "mm | HOUSING_HEIGHT=", HOUSING_HEIGHT, "mm"));
echo(str("Stagger: half-pitch=", STAGGER_HALF_PITCH, "mm"));
echo(str("Roller widths: FP=", FP_WIDTH, "mm  SP=", SP_WIDTH, "mm"));
echo(str("PIP clearances: slider=", PIP_CLEARANCE, " Z=", PIP_Z_GAP, " pulley=", PIP_PULLEY_GAP));

for (i = [0:NUM_CHANNELS-1]) {
    echo(str("  CH", i+1,
             ": d=", round(CH_OFFSETS[i]*10)/10, "mm",
             "  hex_len=", round(CH_LENS[i]*10)/10,
             "  wall_len=", round(CH_WALL_LENS[i]*10)/10,
             "  cols=", COL_COUNTS[i],
             "  stagger=", round(_ch_stagger(i)*10)/10, "mm",
             (i == _CENTER_CH ? "  <- CENTER" : "")));
}

function _sum_arr(arr, i=0) =
    (i >= len(arr)) ? 0 : arr[i] + _sum_arr(arr, i+1);
_total_cols = _sum_arr(COL_COUNTS);
echo(str("  TOTAL columns: ", _total_cols,
         " (", _total_cols * 3, " rollers)"));

echo(str("  plate_t=", _plate_t, "mm",
         (_plate_t >= _slot_d ? " ok" : " !! TOO THIN")));
echo(str("  FP fits gap: OD=", FP_OD, " W=", FP_WIDTH, " in ", CH_GAP, "mm gap",
         (FP_OD < CH_GAP ? " ok" : " !!")));
echo(str("  Col gap: ", COL_PITCH - max(FP_OD, SP_OD), "mm between rollers",
         (COL_PITCH - max(FP_OD, SP_OD) >= 2 ? " ok" : " !! TIGHT")));
_fp_sp_gap = FP_ROW_Y - (FP_OD + SP_OD) / 2;
echo(str("  FP-SP gap: ", _fp_sp_gap, "mm (need >=2mm for rope)",
         (_fp_sp_gap >= 2 ? " ok" : " !! TOO CLOSE")));


// =============================================
// STANDALONE RENDER
// =============================================
_ch_disps = [for (i = [0:NUM_CHANNELS-1])
    let(phase = i * (360.0 / NUM_CHANNELS))
    sin(anim_t() * 360 + phase) * ECCENTRICITY
];

rotate([90, 0, 0])
    matrix_tier_v5(_ch_disps);


// =========================================================
// MATRIX TIER V5 MODULE
// =========================================================
module matrix_tier_v5(ch_slider_disps) {

    difference() {
        union() {
            if (SHOW_HEX_CLIP) {
                difference() {
                    _static_geometry();
                    _hex_clip_negative();
                }
            } else {
                _static_geometry();
            }
        }

        // 6 semicircular edge notches at hex vertices for frame posts
        for (i = [0 : 5]) {
            a = i * 60;
            nx = POST_NOTCH_R * cos(a);
            nz = POST_NOTCH_R * sin(a);
            translate([nx, 0, nz])
                rotate([-90, 0, 0])
                    cylinder(d = POST_DIA, h = HOUSING_HEIGHT + 2,
                             $fn = 12, center = true);
        }
    }

    // Sliders NOT clipped — extend freely through walls
    _all_sliders(ch_slider_disps);

    // Ghost hex outline
    if (SHOW_HEX_GHOST)
        color(C_HEX_GHOST)
        rotate([90, 0, 0])
            cylinder(r = HEX_R, h = HOUSING_HEIGHT, $fn = 6, center = true);
}


// =========================================================
// STATIC GEOMETRY: walls + fixed rollers (hex-clipped)
// =========================================================
module _static_geometry() {

    if (SHOW_WALLS) {
        translate([0, 0, CH_OFFSETS[0] - CH_GAP/2 - WALL_THICKNESS])
            _boundary_wall(CH_WALL_LENS[0], 1);

        for (i = [0 : NUM_CHANNELS - 2]) {
            z_top = CH_OFFSETS[i] + CH_GAP / 2;
            wall_len = max(CH_WALL_LENS[i], CH_WALL_LENS[i+1]);
            translate([0, 0, z_top])
                _shared_wall(wall_len);
        }

        translate([0, 0, CH_OFFSETS[NUM_CHANNELS-1] + CH_GAP/2])
            _boundary_wall(CH_WALL_LENS[NUM_CHANNELS-1], -1);
    }

    if (SHOW_FIXED_PULLEYS) {
        for (i = [0 : NUM_CHANNELS - 1]) {
            if (CH_LENS[i] > 0 && COL_COUNTS[i] > 0) {
                translate([0, 0, CH_OFFSETS[i]])
                    _fixed_rollers(i);
            }
        }
    }
}


// =========================================================
// ALL SLIDERS
// =========================================================
module _all_sliders(ch_slider_disps) {
    for (i = [0 : NUM_CHANNELS - 1]) {
        if (CH_LENS[i] > 0 && COL_COUNTS[i] > 0) {
            disp = (i < len(ch_slider_disps)) ? ch_slider_disps[i] : 0;
            translate([0, 0, CH_OFFSETS[i]])
                _slider_assembly(i, disp);
        }
    }
}


// =========================================================
// FIXED ROLLERS for one channel
// =========================================================
module _fixed_rollers(ch_idx) {
    h_len = CH_LENS[ch_idx];
    d     = CH_OFFSETS[ch_idx];
    raw_n = raw_col_count(h_len);

    for (j = [0 : max(0, raw_n - 1)]) {
        px = col_x(raw_n, j, ch_idx);
        if (col_inside_hex(px, d)) {
            translate([px, FP_ROW_Y, 0])
                _roller(FP_OD, FP_WIDTH, FP_AXLE_DIA, FP_AXLE_LEN);
            translate([px, -FP_ROW_Y, 0])
                _roller(FP_OD, FP_WIDTH, FP_AXLE_DIA, FP_AXLE_LEN);
        }
    }
}


// =========================================================
// SLIDER ASSEMBLY for one channel
// =========================================================
module _slider_assembly(ch_idx, slide_disp) {
    h_len  = CH_WALL_LENS[ch_idx];
    n_cols = COL_COUNTS[ch_idx];
    s_len  = CH_S_LENS[ch_idx];
    d      = CH_OFFSETS[ch_idx];
    raw_n  = raw_col_count(CH_LENS[ch_idx]);

    if (n_cols > 0) {
        translate([slide_disp + SLIDER_REST_OFFSET, 0, 0]) {
            _strip_offset = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2;

            if (SHOW_SLIDER_PLATES) {
                slot_h = RAIL_HEIGHT + RAIL_TOLERANCE * 2;
                _half_y = SLIDER_PLATE_Y / 2;

                // Bottom plate
                color(C_SLIDER)
                difference() {
                    translate([-s_len/2 + _strip_offset, -_half_y, -(S_GAP/2 + _plate_t)])
                        cube([s_len, SLIDER_PLATE_Y, _plate_t]);
                    translate([-s_len/2 + _strip_offset - 1, -slot_h/2, -(S_GAP/2 + _plate_t) - 0.1])
                        cube([s_len + 2, slot_h, _slot_d]);
                }

                // Top plate
                color(C_SLIDER)
                difference() {
                    translate([-s_len/2 + _strip_offset, -_half_y, S_GAP/2])
                        cube([s_len, SLIDER_PLATE_Y, _plate_t]);
                    translate([-s_len/2 + _strip_offset - 1, -slot_h/2, S_GAP/2 + _plate_t - _slot_d + 0.1])
                        cube([s_len + 2, slot_h, _slot_d]);
                }
            }

            if (SHOW_SLIDER_PULLEYS) {
                for (j = [0 : max(0, raw_n - 1)]) {
                    px = col_x(raw_n, j, ch_idx);
                    if (col_inside_hex(px, d)) {
                        translate([px + _strip_offset, 0, 0])
                            _roller(SP_OD, SP_WIDTH, SP_AXLE_DIA, SP_AXLE_LEN);
                    }
                }
            }
        }
    }
}


// =========================================================
// BOUNDARY WALL
// =========================================================
module _boundary_wall(length, rail_dir) {
    _sd = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    _stop = WALL_THICKNESS - PIP_Z_GAP;
    _win_w = min(WINDOW_WIDTH, length * 0.5);
    _win_z = WALL_THICKNESS + 4;

    difference() {
        color(C_WALL) {
            translate([-length/2, -HOUSING_HEIGHT/2, 0])
                cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);

            if (rail_dir > 0) {
                translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                    cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                    cube([END_STOP_W, RAIL_HEIGHT, _stop]);
                translate([length/2 - END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
                    cube([END_STOP_W, RAIL_HEIGHT, _stop]);
            } else {
                translate([-length/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
                    cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-length/2, -RAIL_HEIGHT/2, -_stop])
                    cube([END_STOP_W, RAIL_HEIGHT, _stop]);
                translate([length/2 - END_STOP_W, -RAIL_HEIGHT/2, -_stop])
                    cube([END_STOP_W, RAIL_HEIGHT, _stop]);
            }
        }

        translate([0, 0, WALL_THICKNESS/2])
            cube([_win_w, WINDOW_HEIGHT, _win_z], center = true);
    }
}


// =========================================================
// SHARED WALL
// =========================================================
module _shared_wall(wall_len) {
    _sd = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    _stop = WALL_THICKNESS - PIP_Z_GAP;
    _win_z = (WALL_THICKNESS + _stop) * 2 + 2;
    _win_w = min(WINDOW_WIDTH, wall_len * 0.5);

    difference() {
        color(C_WALL)
        union() {
            translate([-wall_len/2, -HOUSING_HEIGHT/2, 0])
                cube([wall_len, HOUSING_HEIGHT, WALL_THICKNESS]);

            translate([-wall_len/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
                cube([wall_len, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-wall_len/2, -RAIL_HEIGHT/2, -_stop])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);
            translate([wall_len/2 - END_STOP_W, -RAIL_HEIGHT/2, -_stop])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);

            translate([-wall_len/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([wall_len, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-wall_len/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);
            translate([wall_len/2 - END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);
        }

        translate([0, 0, -_stop - 1])
            cube([_win_w, WINDOW_HEIGHT, _win_z], center = true);
        translate([0, 0, WALL_THICKNESS + _stop + 1])
            cube([_win_w, WINDOW_HEIGHT, _win_z], center = true);
    }
}


// =========================================================
// ROLLER
// =========================================================
module _roller(od, width, ax_dia, ax_len) {
    bore = ax_dia + PIP_CLEARANCE * 2;

    color(C_STEEL)
    cylinder(d = ax_dia, h = ax_len, center = true);

    color(C_NYLON)
    difference() {
        cylinder(d = od, h = width, center = true);
        cylinder(d = bore, h = width + 2, center = true);
    }
}


// =========================================================
// HEX CLIP NEGATIVE
// =========================================================
module _hex_clip_negative() {
    total_z = (NUM_CHANNELS + 2) * STACK_OFFSET;

    difference() {
        cube([HEX_C2C + 100, HOUSING_HEIGHT + 100, total_z + 50], center = true);

        rotate([90, 0, 0])
            cylinder(r = HEX_R - 0.5, h = HOUSING_HEIGHT + 10, $fn = 6, center = true);
    }
}
