// =========================================================
// MATRIX TIER V5.6 — Single Tier Module
// =========================================================
// One tier of the hex matrix: walls, channels, fixed pulleys,
// captive sliders with print-in-place pulleys and string pins.
//
// This file is the SINGLE SOURCE for tier geometry.
// matrix_stack uses this via `use <matrix_tier_v5_6.scad>`.
// Changes here flow to the full stack automatically.
//
// Coordinate system (local, before world transform):
//   X = slider travel axis
//   Y = housing depth (perpendicular to slider face)
//   Z = channel stacking axis
//
// To render standalone:  open this file directly in OpenSCAD
// To use in stack:       use <matrix_tier_v5_6.scad>
// =========================================================

include <config_v5_5.scad>

$fn = 24;

// =============================================
// MATRIX-SPECIFIC PARAMETERS
// =============================================
PIP_CLEARANCE  = 0.3;   // radial clearance for pulleys on axles
PIP_Z_GAP      = 0.35;  // V5.5c R1: FDM clearance for print-in-place
PIP_PULLEY_GAP = 0.4;
RAIL_HEIGHT    = 2.0;    // rail cross-section height (Y dimension)
RAIL_DEPTH     = 0.8;    // V5.6: 2 perimeters at 0.4mm nozzle
RAIL_TOLERANCE = 0.4;    // extra slot height for rail clearance
S_GAP          = 3.0;    // V5.6: wider pulley zone for robust PIP

END_STOP_W     = 2.5;    // end-stop width (X dimension)
FP_WIDTH       = CH_GAP - 0.6;  // fixed pulley wheel width
FP_AXLE_DIA    = 1.5;
SP_PIN_DIA     = 1.5;    // slider string pin diameter
SP_AXLE_DIA    = SP_PIN_DIA;
SP_WIDTH       = S_GAP - 2 * PIP_PULLEY_GAP;  // pulley wheel width (2.2mm)
SLIDER_PLATE_Y = SP_OD + 1;  // slider plate depth (Y dimension)
WALL_MARGIN_AXLE = 2;
SLIDER_MARGIN_HELIX = SP_OD/2 + END_STOP_W + 0.5;
SLIDER_MARGIN_ARM   = SP_OD/2 + 0.5;
SLIDER_PULLEY_BIAS_X = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2;

// =============================================
// Z-STACK BUDGET
// =============================================
// CH_GAP/2 = 4.25mm (STACK_OFFSET=10, WALL=1.5)
// Layout from wall face toward center:
//   PIP_Z_GAP (0.35)  — clearance
//   _plate_t  (2.40)  — slider plate
//   S_GAP/2   (1.50)  — half pulley zone
//   ---- center ----

_plate_t = (CH_GAP/2) - (S_GAP/2) - PIP_Z_GAP;           // 2.40mm
_slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;                  // 1.65mm
_end_stop_max = PIP_Z_GAP + _slot_d - 0.15;               // 1.85mm
_end_stop_protrusion = min(WALL_THICKNESS - PIP_Z_GAP, _end_stop_max);  // 1.15mm

SP_AXLE_LEN = S_GAP - 2 * PIP_PULLEY_GAP;                 // 2.2mm
_MT_FP_AXLE_LEN = CH_GAP - 0.4;                           // 8.1mm
_MT_SP_AXLE_LEN = SP_AXLE_LEN;

// =============================================
// DERIVED GEOMETRY — column layout
// =============================================
function _culled_span(ch_idx) =
    let(d = CH_OFFSETS[ch_idx], len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) == 0 ? 0 :
    let(maxp = max([for (c=cols) abs(c)]))
    2 * (maxp + FP_OD/2 + WALL_MARGIN_AXLE);

CH_WALL_LENS = [for (i = [0:NUM_CHANNELS-1])
    max(CH_LENS[i], _culled_span(i))
];

_BUG2_STRIP_OFFSET = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2;

function _culled_col_bounds(ch_idx) =
    let(d = CH_OFFSETS[ch_idx], len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) == 0 ? [0, 0] : [min(cols), max(cols)];

CH_S_LEFT = [for (i = [0:NUM_CHANNELS-1])
    (COL_COUNTS[i] > 0) ?
        _culled_col_bounds(i)[0] + _BUG2_STRIP_OFFSET - SP_OD/2 - SLIDER_MARGIN_ARM : 0
];
CH_S_RIGHT = [for (i = [0:NUM_CHANNELS-1])
    (COL_COUNTS[i] > 0) ?
        _culled_col_bounds(i)[1] + _BUG2_STRIP_OFFSET + SP_OD/2 + SLIDER_MARGIN_ARM : 0
];
CH_S_LENS = [for (i = [0:NUM_CHANNELS-1])
    CH_S_RIGHT[i] - CH_S_LEFT[i]
];

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_WALLS         = true;
SHOW_FIXED_PULLEYS = true;
SHOW_SLIDERS       = true;
SHOW_SLIDER_PLATES = true;
SHOW_SLIDER_PINS   = true;
SHOW_SLIDER_PULLEYS = true;

// =============================================
// STANDALONE RENDER — shows single tier
// =============================================
_standalone_disps = [for (ch = [0 : NUM_CHANNELS - 1])
    ECCENTRICITY * sin(ch * TWIST_PER_CAM)
];
matrix_tier(_standalone_disps);

echo(str("=== MATRIX TIER V5.6 — ", NUM_CHANNELS, " CHANNELS (standalone) ==="));
echo(str("STACK_OFFSET=", STACK_OFFSET, "mm | CH_GAP=", CH_GAP, "mm | HOUSING=", HOUSING_HEIGHT, "mm"));
echo(str("Plate_t=", _plate_t, "mm | Slot_d=", _slot_d, "mm | S_GAP=", S_GAP, "mm"));
echo(str("End-stop=", _end_stop_protrusion, "mm (max=", _end_stop_max, "mm)"));
echo(str("SP_AXLE=", SP_AXLE_LEN, "mm | FP_AXLE=", _MT_FP_AXLE_LEN, "mm"));
echo(str("FP_OD=", FP_OD, " SP_OD=", SP_OD, " FP_ROW_Y=", FP_ROW_Y, "mm"));


// =========================================================
// PUBLIC MODULE: matrix_tier
// =========================================================
// ch_slider_disps = array of NUM_CHANNELS displacement values
//   Each entry is the X displacement for that channel's slider.
//
// Usage from stack:
//   use <matrix_tier_v5_6.scad>
//   matrix_tier(displacements);
// =========================================================
module matrix_tier(ch_slider_disps) {
    if (SHOW_WALLS || SHOW_FIXED_PULLEYS) {
        difference() {
            union() {
                difference() {
                    _mt_static_geometry();
                    _mt_hex_clip_negative();
                }
            }
            // Post notches at stub vertices [0,120,240]
            for (si = [0 : FRAME_POST_COUNT - 1]) {
                a = FRAME_POST_ANGLES[si];
                translate([POST_NOTCH_R*cos(a), 0, POST_NOTCH_R*sin(a)])
                    rotate([-90,0,0])
                        cylinder(d = POST_DIA + 0.3, h = HOUSING_HEIGHT + 2,
                                 $fn = 12, center = true);
            }
        }
    }

    // Sliders (captive, print-in-place)
    if (SHOW_SLIDERS) _mt_all_sliders(ch_slider_disps);
}


// =========================================================
// STATIC GEOMETRY (walls + fixed rollers)
// =========================================================
module _mt_static_geometry() {
    if (SHOW_WALLS) {
        // First boundary wall (bottom of stack)
        translate([0, 0, CH_OFFSETS[0] - CH_GAP/2 - WALL_THICKNESS])
            _mt_boundary_wall(CH_WALL_LENS[0], 1);

        // Shared (interior) walls between channels
        for (i = [0 : NUM_CHANNELS - 2]) {
            z_top = CH_OFFSETS[i] + CH_GAP / 2;
            wall_len = max(CH_WALL_LENS[i], CH_WALL_LENS[i+1]);
            translate([0, 0, z_top])
                _mt_shared_wall(wall_len);
        }

        // Last boundary wall (top of stack)
        translate([0, 0, CH_OFFSETS[NUM_CHANNELS-1] + CH_GAP/2])
            _mt_boundary_wall(CH_WALL_LENS[NUM_CHANNELS-1], -1);
    }

    // Fixed rollers
    if (SHOW_FIXED_PULLEYS) for (i = [0 : NUM_CHANNELS - 1]) {
        if (CH_LENS[i] > 0 && COL_COUNTS[i] > 0) {
            translate([0, 0, CH_OFFSETS[i]])
                _mt_fixed_rollers(i);
        }
    }
}


// =========================================================
// SLIDERS
// =========================================================
module _mt_all_sliders(ch_slider_disps) {
    for (i = [0 : NUM_CHANNELS - 1]) {
        if (CH_LENS[i] > 0 && COL_COUNTS[i] > 0) {
            disp = (i < len(ch_slider_disps)) ? ch_slider_disps[i] : 0;
            translate([0, 0, CH_OFFSETS[i]])
                _mt_slider_assembly(i, disp);
        }
    }
}

module _mt_slider_assembly(ch_idx, slide_disp) {
    n_cols = COL_COUNTS[ch_idx];
    s_len = CH_S_LENS[ch_idx];
    s_left = CH_S_LEFT[ch_idx];
    d = CH_OFFSETS[ch_idx];
    raw_n = raw_col_count(CH_LENS[ch_idx]);

    if (n_cols > 0) {
        translate([slide_disp + SLIDER_REST_OFFSET, 0, 0]) {
            slot_h = RAIL_HEIGHT + RAIL_TOLERANCE * 2;
            _half_y = SLIDER_PLATE_Y / 2;

            if (SHOW_SLIDER_PLATES) color(C_SLIDER) {
                // Bottom plate
                difference() {
                    translate([s_left, -_half_y, -(S_GAP/2 + _plate_t)])
                        cube([s_len, SLIDER_PLATE_Y, _plate_t]);
                    translate([s_left - 1, -slot_h/2, -(S_GAP/2 + _plate_t) - 0.1])
                        cube([s_len + 2, slot_h, _slot_d + 0.1]);
                }
                // Top plate
                difference() {
                    translate([s_left, -_half_y, S_GAP/2])
                        cube([s_len, SLIDER_PLATE_Y, _plate_t]);
                    translate([s_left - 1, -slot_h/2, S_GAP/2 + _plate_t - _slot_d])
                        cube([s_len + 2, slot_h, _slot_d + 0.1]);
                }
            }

            // String pins — span both plates
            _sp_min_x = s_left + SP_OD/2;
            _sp_max_x = s_left + s_len - SP_OD/2;
            if (SHOW_SLIDER_PINS) for (j = [0 : max(0, raw_n - 1)]) {
                px = col_x(raw_n, j, ch_idx);
                if (col_inside_hex(px, d) &&
                    px + _BUG2_STRIP_OFFSET >= _sp_min_x &&
                    px + _BUG2_STRIP_OFFSET <= _sp_max_x) {
                    translate([px + _BUG2_STRIP_OFFSET, 0, 0])
                        color(C_NYLON)
                            cylinder(d = SP_PIN_DIA, h = S_GAP, center = true);
                }
            }

            // Slider pulleys — in S_GAP between plates
            if (SHOW_SLIDER_PULLEYS) for (j = [0 : max(0, raw_n - 1)]) {
                px = col_x(raw_n, j, ch_idx);
                if (col_inside_hex(px, d) &&
                    px + _BUG2_STRIP_OFFSET >= _sp_min_x &&
                    px + _BUG2_STRIP_OFFSET <= _sp_max_x) {
                    translate([px + _BUG2_STRIP_OFFSET, 0, 0])
                        _mt_slider_pulley();
                }
            }
        }
    }
}

module _mt_slider_pulley() {
    bore = SP_AXLE_DIA + PIP_CLEARANCE * 2;
    color(C_STEEL)
        cylinder(d = SP_AXLE_DIA, h = _MT_SP_AXLE_LEN, center = true);
    color(C_NYLON)
    difference() {
        cylinder(d = SP_OD, h = SP_WIDTH, center = true);
        cylinder(d = bore, h = SP_WIDTH + 2, center = true);
    }
}


// =========================================================
// FIXED ROLLERS
// =========================================================
module _mt_fixed_rollers(ch_idx) {
    h_len = CH_LENS[ch_idx];
    d = CH_OFFSETS[ch_idx];
    raw_n = raw_col_count(h_len);
    for (j = [0 : max(0, raw_n - 1)]) {
        px = col_x(raw_n, j, ch_idx);
        if (col_inside_hex(px, d)) {
            translate([px, FP_ROW_Y, 0])
                _mt_roller(FP_OD, FP_WIDTH, FP_AXLE_DIA, _MT_FP_AXLE_LEN);
            translate([px, -FP_ROW_Y, 0])
                _mt_roller(FP_OD, FP_WIDTH, FP_AXLE_DIA, _MT_FP_AXLE_LEN);
        }
    }
}


// =========================================================
// WALL MODULES
// =========================================================
module _mt_boundary_wall(length, rail_dir) {
    color(C_WALL) {
        translate([-length/2, -HOUSING_HEIGHT/2, 0])
            cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);

        if (rail_dir > 0) {
            translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
            translate([length/2-END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
        } else {
            translate([-length/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
                cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-length/2, -RAIL_HEIGHT/2, -_end_stop_protrusion])
                cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
            translate([length/2-END_STOP_W, -RAIL_HEIGHT/2, -_end_stop_protrusion])
                cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
        }
    }
}

module _mt_shared_wall(wall_len) {
    color(C_WALL)
    union() {
        translate([-wall_len/2, -HOUSING_HEIGHT/2, 0])
            cube([wall_len, HOUSING_HEIGHT, WALL_THICKNESS]);

        translate([-wall_len/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
            cube([wall_len, RAIL_HEIGHT, RAIL_DEPTH]);
        translate([-wall_len/2, -RAIL_HEIGHT/2, -_end_stop_protrusion])
            cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
        translate([wall_len/2-END_STOP_W, -RAIL_HEIGHT/2, -_end_stop_protrusion])
            cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);

        translate([-wall_len/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
            cube([wall_len, RAIL_HEIGHT, RAIL_DEPTH]);
        translate([-wall_len/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
            cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
        translate([wall_len/2-END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
            cube([END_STOP_W, RAIL_HEIGHT, _end_stop_protrusion]);
    }
}


// =========================================================
// ROLLER (axle + pulley wheel)
// =========================================================
module _mt_roller(od, width, ax_dia, ax_len) {
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
_CLIP_OVERSIZE = 100;
_CLIP_Z_EXTRA  = 50;
_HEX_CLIP_INSET = 0.5;

module _mt_hex_clip_negative() {
    total_z = (NUM_CHANNELS + 2) * STACK_OFFSET;
    difference() {
        cube([HEX_C2C + _CLIP_OVERSIZE, HOUSING_HEIGHT + _CLIP_OVERSIZE, total_z + _CLIP_Z_EXTRA], center = true);
        rotate([90, 0, 0])
            cylinder(r = HEX_R - _HEX_CLIP_INSET, h = HOUSING_HEIGHT + 10, $fn = 6, center = true);
    }
}
