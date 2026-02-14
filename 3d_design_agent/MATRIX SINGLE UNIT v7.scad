// MATRIX SINGLE UNIT V7
// 5 channels, 3+4+5+4+3 = 19 positions
// Smooth axles, sliders ride rails, split windows with center rail
// ONE AXLE LENGTH controls wall spacing — slide it down, walls move closer
//
// ═══════════════════════════════════════════════════════════
// PARAMETER EXPORT: In OpenSCAD Customizer panel:
//   1. Adjust sliders/values
//   2. Type a preset name in the text field at top of Customizer
//   3. Click [+] to save as a named parameter set
//   → Saved to the .json file alongside this .scad
// ═══════════════════════════════════════════════════════════

$fn = 60;


// ╔══════════════════════════════════════════════════════════╗
// ║  1. GLOBAL STRUCTURE                                     ║
// ╚══════════════════════════════════════════════════════════╝

/* [1 Global Structure] */
ALL_AXLE_LENGTH = 12.0;  // [6:0.5:40]  THE master control — fixed axle span between walls. Reduce = walls closer.
HOUSING_HEIGHT  = 40.0;  // [20:1:200]
FP_ROW_Y        = 28.0;  // [10:0.5:60]


// ╔══════════════════════════════════════════════════════════╗
// ║  2. ALL WALLS                                            ║
// ╚══════════════════════════════════════════════════════════╝

/* [2 All Walls] */
WALL_THICKNESS = 3.0;    // [1:0.5:10]
WALL_SCALE_X   = 1.0;    // [0.2:0.05:2.0]
WALL_SCALE_Y   = 0.65;   // [0.2:0.05:2.0]
WALL_SCALE_Z   = 0.60;   // [0.2:0.05:2.0]
WINDOW_WIDTH   = 41.0;   // [10:1:200]
WINDOW_HEIGHT  = 14.0;   // [10:1:100]
END_STOP_W     = 5.0;    // [2:0.5:15]

/* [2a Guide Rail] */
RAIL_HEIGHT    = 3.0;    // [2:0.5:10]
RAIL_DEPTH     = 1.5;    // [0.5:0.5:5]
RAIL_TOLERANCE = 0.4;    // [0.1:0.1:1.0]

/* [2b Print-in-Place] */
PIP_CLEARANCE  = 0.3;    // [0.1:0.05:0.5]
PIP_Z_GAP      = 0.3;    // [0.1:0.05:0.5]


// ╔══════════════════════════════════════════════════════════╗
// ║  3. ALL FIXED AXLES                                      ║
// ╚══════════════════════════════════════════════════════════╝

/* [3 All Fixed Axles] */
ALL_FP_PITCH     = 16.0;  // [10:0.5:80]   Spacing between fixed axles
ALL_FP_AXLE_DIA  = 4.0;   // [2:0.5:12]    Diameter of fixed axles


// ╔══════════════════════════════════════════════════════════╗
// ║  4. ALL SLIDERS                                          ║
// ╚══════════════════════════════════════════════════════════╝

/* [4 All Sliders] */
ALL_SP_PITCH       = 23.0;   // [10:0.5:80]   Spacing between slider axles
ALL_SP_AXLE_DIA    = 3.0;    // [2:0.5:12]    Diameter of slider axles
ALL_SLIDER_Y_SHIFT = 0.0;    // [-50:0.5:50]  Y offset
SLIDER_PLATE_H     = 9.0;    // [5:0.5:40]    Slider plate height (Y extent)
SLIDER_MARGIN      = 10.0;   // [2:1:40]      Extra length beyond outermost axle, each side
SLIDER_CX_OFFSET   = 0.0;    // [-50:0.5:50]  X offset of slider center vs housing center
MIN_PLATE_T        = 1.5;    // [0.5:0.5:5]   Minimum slider plate thickness above rail slot


// ╔══════════════════════════════════════════════════════════╗
// ║  5. ROW COMPRESSION                                      ║
// ╚══════════════════════════════════════════════════════════╝

/* [5 Row Compression] */
ROW_TOP_COMPRESS = 18.0;  // [0:0.5:25]
ROW_MID_COMPRESS = 18.0;  // [0:0.5:25]
ROW_BOT_COMPRESS = 18.0;  // [0:0.5:25]


// ╔══════════════════════════════════════════════════════════╗
// ║  6. CHANNEL COUNTS                                       ║
// ╚══════════════════════════════════════════════════════════╝

/* [6 Channel Counts] */
CH1_COUNT = 3;  // [1:1:10]  Top
CH2_COUNT = 4;  // [1:1:10]
CH3_COUNT = 5;  // [1:1:10]  Middle
CH4_COUNT = 4;  // [1:1:10]
CH5_COUNT = 3;  // [1:1:10]  Bottom


// ╔══════════════════════════════════════════════════════════╗
// ║  7. VISIBILITY                                           ║
// ╚══════════════════════════════════════════════════════════╝

/* [7 Visibility] */
SHOW_WALLS         = true;
SHOW_SLIDER_PLATES = true;
SHOW_FIXED_AXLES   = true;
SHOW_SLIDER_AXLES  = true;


// ══════════════════════════════════════════════════════════
// DERIVED (Hidden from Customizer)
// ══════════════════════════════════════════════════════════

/* [Hidden] */

WT_Z = WALL_THICKNESS * WALL_SCALE_Z;

// ALL_AXLE_LENGTH is the housing gap (distance between inner wall faces).
// Slider gap derived so plates are always thick enough:
//   plate_t = (HOUSING_GAP - SLIDER_GAP)/2 - PIP_Z_GAP  (must be ≥ slot_d + MIN_PLATE_T)
//   slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5
//   So: SLIDER_GAP = HOUSING_GAP - 2×(slot_d + MIN_PLATE_T + PIP_Z_GAP)
HOUSING_GAP = ALL_AXLE_LENGTH;
_slot_d     = PIP_Z_GAP + RAIL_DEPTH + 0.5;  // 2.3mm at current params
_min_plate  = _slot_d + MIN_PLATE_T;           // plate must be at least slot + cap
SLIDER_GAP  = max(HOUSING_GAP - 2 * (_min_plate + PIP_Z_GAP), 2);

// Stack offset = half-gap + wall + half-gap (wall-to-wall center distance)
STACK_OFFSET = HOUSING_GAP / 2 + WT_Z + HOUSING_GAP / 2;

// Channel counts array
CH_COUNTS = [CH1_COUNT, CH2_COUNT, CH3_COUNT, CH4_COUNT, CH5_COUNT];

// Auto-derive housing length from fixed axle count + pitch + edge clearance
HOUSING_EDGE = 10;
H_LENS = [for (i = [0:4]) (CH_COUNTS[i] - 1) * ALL_FP_PITCH + 2 * HOUSING_EDGE];

// Housing center X: all at origin (symmetric)
H_CXS = [for (i = [0:4]) 0];

// Slider length auto-derived from slider pitch
S_LENS = [for (i = [0:4]) (CH_COUNTS[i] - 1) * ALL_SP_PITCH + 2 * SLIDER_MARGIN];

// Slider center X
S_CXS = [for (i = [0:4]) SLIDER_CX_OFFSET];

// Row compression mapping
ROW_COMPRESS = [ROW_TOP_COMPRESS, ROW_TOP_COMPRESS, ROW_MID_COMPRESS, ROW_BOT_COMPRESS, ROW_BOT_COMPRESS];

// Channel Z-centers (symmetric about Z=0)
CH_Z = [for (i = [0:4]) i * STACK_OFFSET - 2 * STACK_OFFSET];


// ══════════════════════════════════════════════════════════
// VALIDATION
// ══════════════════════════════════════════════════════════

_plate_t_check = (HOUSING_GAP / 2) - (SLIDER_GAP / 2) - PIP_Z_GAP;
_cap_above_slot = _plate_t_check - _slot_d;
_sp_ax_len_check = SLIDER_GAP + 2 * max(_plate_t_check - _slot_d, 0) - 0.2;

echo(str("✓ Axle length=", ALL_AXLE_LENGTH, "mm → housing gap=", HOUSING_GAP,
         "mm, slider gap=", SLIDER_GAP, "mm, stack=", STACK_OFFSET, "mm"));
echo(str("  plate_t=", _plate_t_check, "mm, slot_d=", _slot_d,
         "mm, cap=", _cap_above_slot, "mm, sp_axle_len=", _sp_ax_len_check, "mm"));

if (_plate_t_check < _slot_d + 1)
    echo(str("⚠ Plate thin: only ", _cap_above_slot, "mm above slot — increase ALL_AXLE_LENGTH or MIN_PLATE_T"));
if (SLIDER_GAP <= 2)
    echo(str("⚠ Slider gap at minimum (", SLIDER_GAP, "mm) — ALL_AXLE_LENGTH too small"));

if (CH1_COUNT != CH5_COUNT)
    echo(str("⚠ SYMMETRY: CH1=", CH1_COUNT, " ≠ CH5=", CH5_COUNT));
if (CH2_COUNT != CH4_COUNT)
    echo(str("⚠ SYMMETRY: CH2=", CH2_COUNT, " ≠ CH4=", CH4_COUNT));

echo(str("✓ Positions: ", CH1_COUNT, "+", CH2_COUNT, "+",
         CH3_COUNT, "+", CH4_COUNT, "+", CH5_COUNT, " = ",
         CH1_COUNT + CH2_COUNT + CH3_COUNT + CH4_COUNT + CH5_COUNT));

for (i = [0:4])
    echo(str("  CH", i+1, ": housing=", H_LENS[i], "mm, slider=", S_LENS[i], "mm"));


// ══════════════════════════════════════════════════════════
// MAIN RENDER
// ══════════════════════════════════════════════════════════

anim_val = sin($t * 360) * 68;

rotate([90, 0, 0]) {

    // --- WALLS ---
    if (SHOW_WALLS) {
        // CH1 bottom wall
        translate([H_CXS[0], 0, CH_Z[0] - HOUSING_GAP / 2 - WT_Z])
            single_face_wall(H_LENS[0], true);

        // 4 shared walls
        for (i = [0 : 3]) {
            top_z = CH_Z[i] + HOUSING_GAP / 2;

            left_a  = H_CXS[i]     - H_LENS[i]     / 2;
            right_a = H_CXS[i]     + H_LENS[i]     / 2;
            left_b  = H_CXS[i + 1] - H_LENS[i + 1] / 2;
            right_b = H_CXS[i + 1] + H_LENS[i + 1] / 2;
            wall_left  = min(left_a, left_b);
            wall_right = max(right_a, right_b);
            wall_len = wall_right - wall_left;
            wall_cx  = (wall_left + wall_right) / 2;

            translate([wall_cx, 0, top_z])
                shared_wall(wall_len,
                    H_CXS[i]     - wall_cx,
                    H_CXS[i + 1] - wall_cx);
        }

        // CH5 top wall
        translate([H_CXS[4], 0, CH_Z[4] + HOUSING_GAP / 2])
            single_face_wall(H_LENS[4], false);
    }

    // --- CHANNEL INTERNALS ---
    for (i = [0 : 4]) {
        translate([0, 0, CH_Z[i]])
            channel_internals(anim_val, i + 1,
                HOUSING_GAP, H_CXS[i],
                CH_COUNTS[i], ALL_FP_PITCH, ALL_FP_AXLE_DIA,
                SLIDER_GAP, S_LENS[i], S_CXS[i], ALL_SLIDER_Y_SHIFT,
                CH_COUNTS[i], ALL_SP_PITCH, ALL_SP_AXLE_DIA,
                ROW_COMPRESS[i]);
    }
}


// ══════════════════════════════════════════════════════════
// CHANNEL INTERNALS
// ══════════════════════════════════════════════════════════

module channel_internals(slide_pos, ch_num,
    h_gap, h_cx,
    fp_count, fp_pitch, fp_ax_dia,
    s_gap, s_len, s_cx, s_y_shift,
    sp_count, sp_pitch, sp_ax_dia,
    row_compress)
{
    plate_t = (h_gap / 2) - (s_gap / 2) - PIP_Z_GAP;
    slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;

    fp_ax_len = h_gap + 2 * WT_Z - 0.2;
    sp_ax_len = s_gap + 2 * (plate_t - slot_d) - 0.2;

    if (plate_t < 2)
        echo(str("⚠ CH", ch_num, ": plate_t=", plate_t, "mm — too thin"));

    fp_row_y_eff  = FP_ROW_Y - row_compress;
    fp_row_y_safe = max(fp_row_y_eff, fp_ax_dia / 2 + 2);

    // Fixed Axles
    if (SHOW_FIXED_AXLES) {
        translate([h_cx, fp_row_y_safe, 0])
            axle_row(fp_count, fp_pitch, fp_ax_dia, fp_ax_len);
        translate([h_cx, -fp_row_y_safe, 0])
            axle_row(fp_count, fp_pitch, fp_ax_dia, fp_ax_len);
    }

    // Slider Assembly
    translate([slide_pos + s_cx, s_y_shift, 0]) {
        if (SHOW_SLIDER_PLATES) {
            slot_h = RAIL_HEIGHT + (RAIL_TOLERANCE * 2);

            // Bottom plate
            color([0.9, 0.4, 0.4, 1.0])
            difference() {
                translate([-s_len / 2, -SLIDER_PLATE_H / 2, -(s_gap / 2 + plate_t)])
                    cube([s_len, SLIDER_PLATE_H, plate_t]);
                translate([-(s_len / 2) - 1, -slot_h / 2, -(s_gap / 2 + plate_t) - 0.1])
                    cube([s_len + 2, slot_h, slot_d]);
            }

            // Top plate
            color([0.9, 0.4, 0.4, 1.0])
            difference() {
                translate([-s_len / 2, -SLIDER_PLATE_H / 2, s_gap / 2])
                    cube([s_len, SLIDER_PLATE_H, plate_t]);
                translate([-(s_len / 2) - 1, -slot_h / 2, s_gap / 2 + plate_t - slot_d + 0.1])
                    cube([s_len + 2, slot_h, slot_d]);
            }
        }

        if (SHOW_SLIDER_AXLES)
            axle_row(sp_count, sp_pitch, sp_ax_dia, sp_ax_len);
    }
}


// ══════════════════════════════════════════════════════════
// WALL MODULES
// ══════════════════════════════════════════════════════════

module shared_wall(length, cx_above, cx_below)
{
    slot_d     = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z      = (WT_Z + stop_depth) * 2 + 2;

    len_s = length * WALL_SCALE_X;
    h_s   = HOUSING_HEIGHT * WALL_SCALE_Y;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-len_s / 2, -h_s / 2, 0])
                cube([len_s, h_s, WT_Z]);

            // Bottom face rail + end-stops
            translate([-len_s / 2, -RAIL_HEIGHT / 2, -RAIL_DEPTH])
                cube([len_s, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-len_s / 2, -RAIL_HEIGHT / 2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([len_s / 2 - END_STOP_W, -RAIL_HEIGHT / 2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);

            // Top face rail + end-stops
            translate([-len_s / 2, -RAIL_HEIGHT / 2, WT_Z])
                cube([len_s, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-len_s / 2, -RAIL_HEIGHT / 2, WT_Z])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([len_s / 2 - END_STOP_W, -RAIL_HEIGHT / 2, WT_Z])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
        }

        // Window — channel above (split by center rail)
        win_half_h = (WINDOW_HEIGHT - RAIL_HEIGHT) / 2;
        win_upper_cy = (RAIL_HEIGHT / 2 + WINDOW_HEIGHT / 2) / 2;
        win_lower_cy = -win_upper_cy;

        translate([cx_above, win_upper_cy, -stop_depth - 1])
            cube([WINDOW_WIDTH, win_half_h, win_z], center = true);
        translate([cx_above, win_lower_cy, -stop_depth - 1])
            cube([WINDOW_WIDTH, win_half_h, win_z], center = true);

        // Window — channel below (split by center rail)
        translate([cx_below, win_upper_cy, WT_Z + stop_depth + 1])
            cube([WINDOW_WIDTH, win_half_h, win_z], center = true);
        translate([cx_below, win_lower_cy, WT_Z + stop_depth + 1])
            cube([WINDOW_WIDTH, win_half_h, win_z], center = true);
    }
}

module single_face_wall(length, rail_inward) {
    slot_d     = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z      = (WT_Z + stop_depth) * 2 + 2;

    len_s = length * WALL_SCALE_X;
    h_s   = HOUSING_HEIGHT * WALL_SCALE_Y;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-len_s / 2, -h_s / 2, 0])
                cube([len_s, h_s, WT_Z]);

            if (rail_inward) {
                translate([-len_s / 2, -RAIL_HEIGHT / 2, WT_Z])
                    cube([len_s, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-len_s / 2, -RAIL_HEIGHT / 2, WT_Z])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([len_s / 2 - END_STOP_W, -RAIL_HEIGHT / 2, WT_Z])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            } else {
                translate([-len_s / 2, -RAIL_HEIGHT / 2, -RAIL_DEPTH])
                    cube([len_s, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-len_s / 2, -RAIL_HEIGHT / 2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([len_s / 2 - END_STOP_W, -RAIL_HEIGHT / 2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            }
        }

        // Window split by center rail
        win_half_h = (WINDOW_HEIGHT - RAIL_HEIGHT) / 2;
        win_upper_cy = (RAIL_HEIGHT / 2 + WINDOW_HEIGHT / 2) / 2;
        win_lower_cy = -win_upper_cy;

        translate([0, win_upper_cy, WT_Z / 2])
            cube([WINDOW_WIDTH, win_half_h, win_z], center = true);
        translate([0, win_lower_cy, WT_Z / 2])
            cube([WINDOW_WIDTH, win_half_h, win_z], center = true);
    }
}


// ══════════════════════════════════════════════════════════
// AXLE ROW
// ══════════════════════════════════════════════════════════

module axle_row(count, pitch, ax_dia, ax_len) {
    start_x = -((count - 1) / 2) * pitch;
    for (i = [0 : count - 1]) {
        translate([start_x + i * pitch, 0, 0]) {
            color([0.5, 0.5, 0.5])
            cylinder(d = ax_dia, h = ax_len, center = true);
        }
    }
}
