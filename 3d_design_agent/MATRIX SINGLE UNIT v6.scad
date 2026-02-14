// MATRIX SINGLE UNIT V6
// 5 channels, 3+4+5+4+3 = 19 positions
// Smooth axles (no pulleys), sliders still ride rails
// Wall thickness scaling (X, Y, Z)
// Per-row compression sliders (top, mid, bottom)

$fn = 60;

/* [Global] */
STACK_OFFSET   = 22.0;   // [10:0.5:50]
HOUSING_HEIGHT = 85.0;   // [20:1:200]
WALL_THICKNESS = 3.0;    // [1:0.5:10]
FP_ROW_Y       = 31.0;   // [10:0.5:60]

/* [Wall Thickness Scaling] */
// 1.0 = original, 0.5 = half thickness. Uniformly scales wall body.
WALL_SCALE_X = 1.0;  // [0.2:0.05:2.0]
WALL_SCALE_Y = 1.0;  // [0.2:0.05:2.0]
WALL_SCALE_Z = 1.0;  // [0.2:0.05:2.0]

/* [Row Compression] */
// Compress axle rows closer to Y=0 center. 0 = default spacing, positive = compress inward.
ROW_TOP_COMPRESS = 0.0;  // [0:0.5:25]  CH1+CH2
ROW_MID_COMPRESS = 0.0;  // [0:0.5:25]  CH3
ROW_BOT_COMPRESS = 0.0;  // [0:0.5:25]  CH4+CH5

/* [Guide Rail] */
RAIL_HEIGHT    = 4.0;    // [2:0.5:10]
RAIL_DEPTH     = 1.5;    // [0.5:0.5:5]
RAIL_TOLERANCE = 0.4;    // [0.1:0.1:1.0]
END_STOP_W     = 5.0;    // [2:0.5:15]
WINDOW_WIDTH   = 40.0;   // [10:1:200]
WINDOW_HEIGHT  = 30.0;   // [10:1:100]

/* [Print-in-Place] */
PIP_CLEARANCE  = 0.3;    // [0.1:0.05:0.5]
PIP_Z_GAP      = 0.3;    // [0.1:0.05:0.5]

/* [Visibility] */
SHOW_WALLS          = true;
SHOW_SLIDER_PLATES  = true;
SHOW_FIXED_AXLES    = true;
SHOW_SLIDER_AXLES   = true;

// --- CH1 (Top) ---

/* [CH1 Housing] */
CH1_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH1_HOUSING_LENGTH   = 83.0;  // [20:1:300]
CH1_HOUSING_CENTER_X = -51.0; // [-200:1:200]

/* [CH1 Fixed Axles] */
CH1_FIXED_COUNT  = 3;    // [0:1:10]
CH1_FP_PITCH     = 29.0; // [10:0.5:80]
CH1_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]

/* [CH1 Slider] */
CH1_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH1_SLIDER_LENGTH   = 166.0; // [20:1:300]
CH1_SLIDER_CENTER_X = -44.0; // [-200:1:200]
CH1_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH1 Slider Axles] */
CH1_SLIDER_COUNT = 3;    // [0:1:10]
CH1_SP_PITCH     = 46.0; // [10:0.5:80]
CH1_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]

// --- CH2 ---

/* [CH2 Housing] */
CH2_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH2_HOUSING_LENGTH   = 111.0; // [20:1:300]
CH2_HOUSING_CENTER_X = -51.0; // [-200:1:200]

/* [CH2 Fixed Axles] */
CH2_FIXED_COUNT  = 4;    // [0:1:10]
CH2_FP_PITCH     = 29.0; // [10:0.5:80]
CH2_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]

/* [CH2 Slider] */
CH2_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH2_SLIDER_LENGTH   = 222.0; // [20:1:300]
CH2_SLIDER_CENTER_X = -44.0; // [-200:1:200]
CH2_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH2 Slider Axles] */
CH2_SLIDER_COUNT = 4;    // [0:1:10]
CH2_SP_PITCH     = 46.0; // [10:0.5:80]
CH2_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]

// --- CH3 (Middle) ---

/* [CH3 Housing] */
CH3_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH3_HOUSING_LENGTH   = 136.0; // [20:1:300]
CH3_HOUSING_CENTER_X = -51.0; // [-200:1:200]

/* [CH3 Fixed Axles] */
CH3_FIXED_COUNT  = 5;    // [0:1:10]
CH3_FP_PITCH     = 29.0; // [10:0.5:80]
CH3_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]

/* [CH3 Slider] */
CH3_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH3_SLIDER_LENGTH   = 272.0; // [20:1:300]
CH3_SLIDER_CENTER_X = -51.0; // [-200:1:200]
CH3_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH3 Slider Axles] */
CH3_SLIDER_COUNT = 5;    // [0:1:10]
CH3_SP_PITCH     = 46.0; // [10:0.5:80]
CH3_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]

// --- CH4 ---

/* [CH4 Housing] */
CH4_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH4_HOUSING_LENGTH   = 112.0; // [20:1:300]
CH4_HOUSING_CENTER_X = -53.0; // [-200:1:200]

/* [CH4 Fixed Axles] */
CH4_FIXED_COUNT  = 4;    // [0:1:10]
CH4_FP_PITCH     = 29.0; // [10:0.5:80]
CH4_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]

/* [CH4 Slider] */
CH4_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH4_SLIDER_LENGTH   = 224.0; // [20:1:300]
CH4_SLIDER_CENTER_X = -44.0; // [-200:1:200]
CH4_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH4 Slider Axles] */
CH4_SLIDER_COUNT = 4;    // [0:1:10]
CH4_SP_PITCH     = 46.0; // [10:0.5:80]
CH4_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]

// --- CH5 (Bottom) ---

/* [CH5 Housing] */
CH5_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH5_HOUSING_LENGTH   = 83.0;  // [20:1:300]
CH5_HOUSING_CENTER_X = -53.0; // [-200:1:200]

/* [CH5 Fixed Axles] */
CH5_FIXED_COUNT  = 3;    // [0:1:10]
CH5_FP_PITCH     = 29.0; // [10:0.5:80]
CH5_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]

/* [CH5 Slider] */
CH5_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH5_SLIDER_LENGTH   = 166.0; // [20:1:300]
CH5_SLIDER_CENTER_X = -45.0; // [-200:1:200]
CH5_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH5 Slider Axles] */
CH5_SLIDER_COUNT = 3;    // [0:1:10]
CH5_SP_PITCH     = 46.0; // [10:0.5:80]
CH5_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]

/* [Hidden] */
// Channel data packed for loop access
H_GAPS    = [CH1_HOUSING_GAP, CH2_HOUSING_GAP, CH3_HOUSING_GAP, CH4_HOUSING_GAP, CH5_HOUSING_GAP];
H_LENS    = [CH1_HOUSING_LENGTH, CH2_HOUSING_LENGTH, CH3_HOUSING_LENGTH, CH4_HOUSING_LENGTH, CH5_HOUSING_LENGTH];
H_CXS     = [CH1_HOUSING_CENTER_X, CH2_HOUSING_CENTER_X, CH3_HOUSING_CENTER_X, CH4_HOUSING_CENTER_X, CH5_HOUSING_CENTER_X];
FP_COUNTS = [CH1_FIXED_COUNT, CH2_FIXED_COUNT, CH3_FIXED_COUNT, CH4_FIXED_COUNT, CH5_FIXED_COUNT];
FP_PITCHS = [CH1_FP_PITCH, CH2_FP_PITCH, CH3_FP_PITCH, CH4_FP_PITCH, CH5_FP_PITCH];
FP_AX_DS  = [CH1_FP_AXLE_DIA, CH2_FP_AXLE_DIA, CH3_FP_AXLE_DIA, CH4_FP_AXLE_DIA, CH5_FP_AXLE_DIA];
S_GAPS    = [CH1_SLIDER_GAP, CH2_SLIDER_GAP, CH3_SLIDER_GAP, CH4_SLIDER_GAP, CH5_SLIDER_GAP];
S_LENS    = [CH1_SLIDER_LENGTH, CH2_SLIDER_LENGTH, CH3_SLIDER_LENGTH, CH4_SLIDER_LENGTH, CH5_SLIDER_LENGTH];
S_CXS     = [CH1_SLIDER_CENTER_X, CH2_SLIDER_CENTER_X, CH3_SLIDER_CENTER_X, CH4_SLIDER_CENTER_X, CH5_SLIDER_CENTER_X];
S_YS      = [CH1_SLIDER_Y_SHIFT, CH2_SLIDER_Y_SHIFT, CH3_SLIDER_Y_SHIFT, CH4_SLIDER_Y_SHIFT, CH5_SLIDER_Y_SHIFT];
SP_COUNTS = [CH1_SLIDER_COUNT, CH2_SLIDER_COUNT, CH3_SLIDER_COUNT, CH4_SLIDER_COUNT, CH5_SLIDER_COUNT];
SP_PITCHS = [CH1_SP_PITCH, CH2_SP_PITCH, CH3_SP_PITCH, CH4_SP_PITCH, CH5_SP_PITCH];
SP_AX_DS  = [CH1_SP_AXLE_DIA, CH2_SP_AXLE_DIA, CH3_SP_AXLE_DIA, CH4_SP_AXLE_DIA, CH5_SP_AXLE_DIA];

// Row compression mapping: which channels belong to which row group
// Top row = CH1(0), CH2(1) | Mid row = CH3(2) | Bot row = CH4(3), CH5(4)
ROW_COMPRESS = [ROW_TOP_COMPRESS, ROW_TOP_COMPRESS, ROW_MID_COMPRESS, ROW_BOT_COMPRESS, ROW_BOT_COMPRESS];

// Derived wall thickness after scaling
WT_Z = WALL_THICKNESS * WALL_SCALE_Z;


// ==================================================
// MAIN RENDER
// ==================================================

anim_val = sin($t * 360) * 68;

// Channel Z-centers
CH_Z = [for (i = [0:4]) i * STACK_OFFSET - 2 * STACK_OFFSET];

// Validate shared wall fit
for (i = [0:3]) {
    required = H_GAPS[i]/2 + WT_Z + H_GAPS[i+1]/2;
    if (abs(STACK_OFFSET - required) > 0.01)
        echo(str("⚠ Wall ", i, "-", i+1, ": STACK_OFFSET=", STACK_OFFSET,
                  " but need ", required, " for gaps ", H_GAPS[i], "/", H_GAPS[i+1],
                  " (with WALL_SCALE_Z=", WALL_SCALE_Z, ")"));
}

rotate([90, 0, 0]) {

    // --- WALLS (6 walls for 5 channels, shared where adjacent) ---
    if (SHOW_WALLS) {
        // CH1 bottom wall (single face, rail on +Z into gap)
        translate([H_CXS[0], 0, CH_Z[0] - H_GAPS[0] / 2 - WT_Z])
            single_face_wall(H_LENS[0], true);

        // 4 shared walls between adjacent channels
        for (i = [0 : 3]) {
            top_z = CH_Z[i] + H_GAPS[i] / 2;

            left_a  = H_CXS[i] - H_LENS[i] / 2;
            right_a = H_CXS[i] + H_LENS[i] / 2;
            left_b  = H_CXS[i + 1] - H_LENS[i + 1] / 2;
            right_b = H_CXS[i + 1] + H_LENS[i + 1] / 2;
            wall_left  = min(left_a, left_b);
            wall_right = max(right_a, right_b);
            wall_len = wall_right - wall_left;
            wall_cx  = (wall_left + wall_right) / 2;

            translate([wall_cx, 0, top_z])
                shared_wall(wall_len,
                    H_CXS[i] - wall_cx,
                    H_CXS[i + 1] - wall_cx);
        }

        // CH5 top wall (single face, rail on -Z into gap)
        translate([H_CXS[4], 0, CH_Z[4] + H_GAPS[4] / 2])
            single_face_wall(H_LENS[4], false);
    }

    // --- CHANNEL INTERNALS (axles + sliders, no walls) ---
    for (i = [0 : 4]) {
        translate([0, 0, CH_Z[i]])
            channel_internals(anim_val, i + 1,
                H_GAPS[i], H_CXS[i],
                FP_COUNTS[i], FP_PITCHS[i], FP_AX_DS[i],
                S_GAPS[i], S_LENS[i], S_CXS[i], S_YS[i],
                SP_COUNTS[i], SP_PITCHS[i], SP_AX_DS[i],
                ROW_COMPRESS[i]);
    }
}


// ==================================================
// CHANNEL INTERNALS (no walls — just axles + slider)
// ==================================================

module channel_internals(slide_pos, ch_num,
    h_gap, h_cx,
    fp_count, fp_pitch, fp_ax_dia,
    s_gap, s_len, s_cx, s_y_shift,
    sp_count, sp_pitch, sp_ax_dia,
    row_compress)
{
    plate_t = (h_gap / 2) - (s_gap / 2) - PIP_Z_GAP;
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;

    // Axle lengths: fixed axles span housing gap + walls, slider axles span slider gap
    fp_ax_len = h_gap + 2 * WT_Z - 0.2;
    sp_ax_len = s_gap + 2 * (plate_t - slot_d) - 0.2;

    if (plate_t < 2)
        echo(str("⚠ CH", ch_num, ": plate_t=", plate_t, "mm — too thin"));

    // Effective FP row Y position (compressed toward center)
    fp_row_y_eff = FP_ROW_Y - row_compress;
    fp_row_y_safe = max(fp_row_y_eff, fp_ax_dia / 2 + 2);  // don't overlap center

    // Fixed Axles at Z=0 center, spanning into walls
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

            color([0.9, 0.4, 0.4, 1.0])
            difference() {
                translate([-s_len / 2, -7.5, -(s_gap / 2 + plate_t)])
                    cube([s_len, 15, plate_t]);
                translate([-(s_len / 2) - 1, -slot_h / 2, -(s_gap / 2 + plate_t) - 0.1])
                    cube([s_len + 2, slot_h, slot_d]);
            }

            color([0.9, 0.4, 0.4, 1.0])
            difference() {
                translate([-s_len / 2, -7.5, s_gap / 2])
                    cube([s_len, 15, plate_t]);
                translate([-(s_len / 2) - 1, -slot_h / 2, s_gap / 2 + plate_t - slot_d + 0.1])
                    cube([s_len + 2, slot_h, slot_d]);
            }
        }

        if (SHOW_SLIDER_AXLES)
            axle_row(sp_count, sp_pitch, sp_ax_dia, sp_ax_len);
    }
}


// ==================================================
// WALL MODULES
// ==================================================

// Shared wall between two channels.
module shared_wall(length, cx_above, cx_below)
{
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z = (WT_Z + stop_depth) * 2 + 2;

    // Scaled dimensions
    len_scaled = length * WALL_SCALE_X;
    h_scaled = HOUSING_HEIGHT * WALL_SCALE_Y;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            // Wall body
            translate([-len_scaled / 2, -h_scaled / 2, 0])
                cube([len_scaled, h_scaled, WT_Z]);

            // Bottom face rail + end-stops
            translate([-len_scaled / 2, -RAIL_HEIGHT / 2, -RAIL_DEPTH])
                cube([len_scaled, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-len_scaled / 2, -RAIL_HEIGHT / 2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([len_scaled / 2 - END_STOP_W, -RAIL_HEIGHT / 2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);

            // Top face rail + end-stops
            translate([-len_scaled / 2, -RAIL_HEIGHT / 2, WT_Z])
                cube([len_scaled, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-len_scaled / 2, -RAIL_HEIGHT / 2, WT_Z])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([len_scaled / 2 - END_STOP_W, -RAIL_HEIGHT / 2, WT_Z])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
        }

        // Window — channel above
        translate([cx_above, 0, -stop_depth - 1])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);

        // Window — channel below
        translate([cx_below, 0, WT_Z + stop_depth + 1])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
    }
}

// Single-face wall (CH1 bottom, CH5 top).
module single_face_wall(length, rail_inward) {
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z = (WT_Z + stop_depth) * 2 + 2;

    // Scaled dimensions
    len_scaled = length * WALL_SCALE_X;
    h_scaled = HOUSING_HEIGHT * WALL_SCALE_Y;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-len_scaled / 2, -h_scaled / 2, 0])
                cube([len_scaled, h_scaled, WT_Z]);

            if (rail_inward) {
                translate([-len_scaled / 2, -RAIL_HEIGHT / 2, WT_Z])
                    cube([len_scaled, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-len_scaled / 2, -RAIL_HEIGHT / 2, WT_Z])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([len_scaled / 2 - END_STOP_W, -RAIL_HEIGHT / 2, WT_Z])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            } else {
                translate([-len_scaled / 2, -RAIL_HEIGHT / 2, -RAIL_DEPTH])
                    cube([len_scaled, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-len_scaled / 2, -RAIL_HEIGHT / 2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([len_scaled / 2 - END_STOP_W, -RAIL_HEIGHT / 2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            }
        }

        translate([0, 0, WT_Z / 2])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
    }
}


// ==================================================
// AXLE ROW (smooth axles only — no pulley discs)
// ==================================================

module axle_row(count, pitch, ax_dia, ax_len) {
    start_x = -((count - 1) / 2) * pitch;
    for (i = [0 : count - 1]) {
        translate([start_x + i * pitch, 0, 0]) {
            color([0.5, 0.5, 0.5])
            cylinder(d = ax_dia, h = ax_len, center = true);
        }
    }
}
