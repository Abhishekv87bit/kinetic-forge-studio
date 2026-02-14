// V107: NO WALL HOLES, ANCHORED SLIDER AXLES, MAX WINDOWS

$fn = 60;

/* [Global] */
STACK_OFFSET   = 22.0;   // [10:0.5:50]
HOUSING_HEIGHT = 85.0;   // [20:1:200]
WALL_THICKNESS = 3.0;    // [1:0.5:10]
FP_ROW_Y       = 31.0;   // [10:0.5:60]

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
SHOW_FIXED_PULLEYS  = true;
SHOW_SLIDER_PULLEYS = true;

// --- CH1 (Top) ---

/* [CH1 Housing] */
CH1_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH1_HOUSING_LENGTH   = 83.0;  // [20:1:300]
CH1_HOUSING_CENTER_X = -51.0; // [-200:1:200]

/* [CH1 Fixed Pulleys] */
CH1_FIXED_COUNT  = 3;    // [0:1:10]
CH1_FP_PITCH     = 29.0; // [10:0.5:80]
CH1_FP_OD        = 13.0; // [5:0.5:30]
CH1_FP_WIDTH     = 18.0; // [3:0.5:30]
CH1_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH1_FP_AXLE_LEN  = 25.2; // [5:0.5:50]

/* [CH1 Slider] */
CH1_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH1_SLIDER_LENGTH   = 166.0; // [20:1:300]
CH1_SLIDER_CENTER_X = -44.0; // [-200:1:200]
CH1_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH1 Slider Pulleys] */
CH1_SLIDER_COUNT = 3;    // [0:1:10]
CH1_SP_PITCH     = 46.0; // [10:0.5:80]
CH1_SP_OD        = 10.0; // [5:0.5:30]
CH1_SP_WIDTH     = 7.0;  // [3:0.5:30]
CH1_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH1_SP_AXLE_LEN  = 8.0;  // [3:0.5:30]

// --- CH2 ---

/* [CH2 Housing] */
CH2_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH2_HOUSING_LENGTH   = 111.0; // [20:1:300]
CH2_HOUSING_CENTER_X = -51.0; // [-200:1:200]

/* [CH2 Fixed Pulleys] */
CH2_FIXED_COUNT  = 4;    // [0:1:10]
CH2_FP_PITCH     = 29.0; // [10:0.5:80]
CH2_FP_OD        = 13.0; // [5:0.5:30]
CH2_FP_WIDTH     = 18.0; // [3:0.5:30]
CH2_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH2_FP_AXLE_LEN  = 25.2; // [5:0.5:50]

/* [CH2 Slider] */
CH2_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH2_SLIDER_LENGTH   = 222.0; // [20:1:300]
CH2_SLIDER_CENTER_X = -44.0; // [-200:1:200]
CH2_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH2 Slider Pulleys] */
CH2_SLIDER_COUNT = 4;    // [0:1:10]
CH2_SP_PITCH     = 46.0; // [10:0.5:80]
CH2_SP_OD        = 10.0; // [5:0.5:30]
CH2_SP_WIDTH     = 7.0;  // [3:0.5:30]
CH2_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH2_SP_AXLE_LEN  = 8.0;  // [3:0.5:30]

// --- CH3 (Middle) ---

/* [CH3 Housing] */
CH3_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH3_HOUSING_LENGTH   = 136.0; // [20:1:300]
CH3_HOUSING_CENTER_X = -51.0; // [-200:1:200]

/* [CH3 Fixed Pulleys] */
CH3_FIXED_COUNT  = 5;    // [0:1:10]
CH3_FP_PITCH     = 29.0; // [10:0.5:80]
CH3_FP_OD        = 13.0; // [5:0.5:30]
CH3_FP_WIDTH     = 18.0; // [3:0.5:30]
CH3_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH3_FP_AXLE_LEN  = 25.2; // [5:0.5:50]

/* [CH3 Slider] */
CH3_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH3_SLIDER_LENGTH   = 272.0; // [20:1:300]
CH3_SLIDER_CENTER_X = -51.0; // [-200:1:200]
CH3_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH3 Slider Pulleys] */
CH3_SLIDER_COUNT = 5;    // [0:1:10]
CH3_SP_PITCH     = 46.0; // [10:0.5:80]
CH3_SP_OD        = 10.0; // [5:0.5:30]
CH3_SP_WIDTH     = 7.0;  // [3:0.5:30]
CH3_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH3_SP_AXLE_LEN  = 8.0;  // [3:0.5:30]

// --- CH4 ---

/* [CH4 Housing] */
CH4_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH4_HOUSING_LENGTH   = 112.0; // [20:1:300]
CH4_HOUSING_CENTER_X = -53.0; // [-200:1:200]

/* [CH4 Fixed Pulleys] */
CH4_FIXED_COUNT  = 4;    // [0:1:10]
CH4_FP_PITCH     = 29.0; // [10:0.5:80]
CH4_FP_OD        = 13.0; // [5:0.5:30]
CH4_FP_WIDTH     = 18.0; // [3:0.5:30]
CH4_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH4_FP_AXLE_LEN  = 25.2; // [5:0.5:50]

/* [CH4 Slider] */
CH4_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH4_SLIDER_LENGTH   = 224.0; // [20:1:300]
CH4_SLIDER_CENTER_X = -44.0; // [-200:1:200]
CH4_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH4 Slider Pulleys] */
CH4_SLIDER_COUNT = 4;    // [0:1:10]
CH4_SP_PITCH     = 46.0; // [10:0.5:80]
CH4_SP_OD        = 10.0; // [5:0.5:30]
CH4_SP_WIDTH     = 7.0;  // [3:0.5:30]
CH4_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH4_SP_AXLE_LEN  = 8.0;  // [3:0.5:30]

// --- CH5 (Bottom) ---

/* [CH5 Housing] */
CH5_HOUSING_GAP      = 19.0;  // [5:0.5:40]
CH5_HOUSING_LENGTH   = 83.0;  // [20:1:300]
CH5_HOUSING_CENTER_X = -53.0; // [-200:1:200]

/* [CH5 Fixed Pulleys] */
CH5_FIXED_COUNT  = 3;    // [0:1:10]
CH5_FP_PITCH     = 29.0; // [10:0.5:80]
CH5_FP_OD        = 13.0; // [5:0.5:30]
CH5_FP_WIDTH     = 18.0; // [3:0.5:30]
CH5_FP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH5_FP_AXLE_LEN  = 25.2; // [5:0.5:50]

/* [CH5 Slider] */
CH5_SLIDER_GAP      = 8.0;   // [3:0.5:30]
CH5_SLIDER_LENGTH   = 166.0; // [20:1:300]
CH5_SLIDER_CENTER_X = -45.0; // [-200:1:200]
CH5_SLIDER_Y_SHIFT  = 0.0;   // [-50:0.5:50]

/* [CH5 Slider Pulleys] */
CH5_SLIDER_COUNT = 3;    // [0:1:10]
CH5_SP_PITCH     = 46.0; // [10:0.5:80]
CH5_SP_OD        = 10.0; // [5:0.5:30]
CH5_SP_WIDTH     = 7.0;  // [3:0.5:30]
CH5_SP_AXLE_DIA  = 5.0;  // [2:0.5:12]
CH5_SP_AXLE_LEN  = 8.0;  // [3:0.5:30]

/* [Hidden] */
// Channel data packed for loop access
H_GAPS    = [CH1_HOUSING_GAP, CH2_HOUSING_GAP, CH3_HOUSING_GAP, CH4_HOUSING_GAP, CH5_HOUSING_GAP];
H_LENS    = [CH1_HOUSING_LENGTH, CH2_HOUSING_LENGTH, CH3_HOUSING_LENGTH, CH4_HOUSING_LENGTH, CH5_HOUSING_LENGTH];
H_CXS     = [CH1_HOUSING_CENTER_X, CH2_HOUSING_CENTER_X, CH3_HOUSING_CENTER_X, CH4_HOUSING_CENTER_X, CH5_HOUSING_CENTER_X];
FP_COUNTS = [CH1_FIXED_COUNT, CH2_FIXED_COUNT, CH3_FIXED_COUNT, CH4_FIXED_COUNT, CH5_FIXED_COUNT];
FP_PITCHS = [CH1_FP_PITCH, CH2_FP_PITCH, CH3_FP_PITCH, CH4_FP_PITCH, CH5_FP_PITCH];
FP_ODS    = [CH1_FP_OD, CH2_FP_OD, CH3_FP_OD, CH4_FP_OD, CH5_FP_OD];
FP_WS     = [CH1_FP_WIDTH, CH2_FP_WIDTH, CH3_FP_WIDTH, CH4_FP_WIDTH, CH5_FP_WIDTH];
FP_AX_DS  = [CH1_FP_AXLE_DIA, CH2_FP_AXLE_DIA, CH3_FP_AXLE_DIA, CH4_FP_AXLE_DIA, CH5_FP_AXLE_DIA];
FP_AX_LS  = [CH1_FP_AXLE_LEN, CH2_FP_AXLE_LEN, CH3_FP_AXLE_LEN, CH4_FP_AXLE_LEN, CH5_FP_AXLE_LEN];
S_GAPS    = [CH1_SLIDER_GAP, CH2_SLIDER_GAP, CH3_SLIDER_GAP, CH4_SLIDER_GAP, CH5_SLIDER_GAP];
S_LENS    = [CH1_SLIDER_LENGTH, CH2_SLIDER_LENGTH, CH3_SLIDER_LENGTH, CH4_SLIDER_LENGTH, CH5_SLIDER_LENGTH];
S_CXS     = [CH1_SLIDER_CENTER_X, CH2_SLIDER_CENTER_X, CH3_SLIDER_CENTER_X, CH4_SLIDER_CENTER_X, CH5_SLIDER_CENTER_X];
S_YS      = [CH1_SLIDER_Y_SHIFT, CH2_SLIDER_Y_SHIFT, CH3_SLIDER_Y_SHIFT, CH4_SLIDER_Y_SHIFT, CH5_SLIDER_Y_SHIFT];
SP_COUNTS = [CH1_SLIDER_COUNT, CH2_SLIDER_COUNT, CH3_SLIDER_COUNT, CH4_SLIDER_COUNT, CH5_SLIDER_COUNT];
SP_PITCHS = [CH1_SP_PITCH, CH2_SP_PITCH, CH3_SP_PITCH, CH4_SP_PITCH, CH5_SP_PITCH];
SP_ODS    = [CH1_SP_OD, CH2_SP_OD, CH3_SP_OD, CH4_SP_OD, CH5_SP_OD];
SP_WS     = [CH1_SP_WIDTH, CH2_SP_WIDTH, CH3_SP_WIDTH, CH4_SP_WIDTH, CH5_SP_WIDTH];
SP_AX_DS  = [CH1_SP_AXLE_DIA, CH2_SP_AXLE_DIA, CH3_SP_AXLE_DIA, CH4_SP_AXLE_DIA, CH5_SP_AXLE_DIA];
SP_AX_LS  = [CH1_SP_AXLE_LEN, CH2_SP_AXLE_LEN, CH3_SP_AXLE_LEN, CH4_SP_AXLE_LEN, CH5_SP_AXLE_LEN];


// ==================================================
// MAIN RENDER
// ==================================================

anim_val = sin($t * 360) * 68;

// Channel Z-centers
CH_Z = [for (i = [0:4]) i * STACK_OFFSET - 2 * STACK_OFFSET];

// Validate shared wall fit: STACK_OFFSET must equal (gap_i + gap_i+1)/2 + WALL_THICKNESS
for (i = [0:3]) {
    required = H_GAPS[i]/2 + WALL_THICKNESS + H_GAPS[i+1]/2;
    if (abs(STACK_OFFSET - required) > 0.01)
        echo(str("⚠ Wall ", i, "-", i+1, ": STACK_OFFSET=", STACK_OFFSET,
                  " but need ", required, " for gaps ", H_GAPS[i], "/", H_GAPS[i+1]));
}

rotate([90, 0, 0]) {

    // --- WALLS (6 walls for 5 channels, shared where adjacent) ---
    if (SHOW_WALLS) {
        // CH1 bottom wall (single face, rail on +Z into gap)
        translate([H_CXS[0], 0, CH_Z[0] - H_GAPS[0] / 2 - WALL_THICKNESS])
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

    // --- CHANNEL INTERNALS (pulleys + sliders, no walls) ---
    for (i = [0 : 4]) {
        translate([0, 0, CH_Z[i]])
            channel_internals(anim_val, i + 1,
                H_GAPS[i], H_CXS[i],
                FP_COUNTS[i], FP_PITCHS[i], FP_ODS[i], FP_WS[i], FP_AX_DS[i], FP_AX_LS[i],
                S_GAPS[i], S_LENS[i], S_CXS[i], S_YS[i],
                SP_COUNTS[i], SP_PITCHS[i], SP_ODS[i], SP_WS[i], SP_AX_DS[i], SP_AX_LS[i]);
    }
}


// ==================================================
// CHANNEL INTERNALS (no walls — just pulleys + slider)
// ==================================================

module channel_internals(slide_pos, ch_num,
    h_gap, h_cx,
    fp_count, fp_pitch, fp_od, fp_w, fp_ax_dia, fp_ax_len,
    s_gap, s_len, s_cx, s_y_shift,
    sp_count, sp_pitch, sp_od, sp_w, sp_ax_dia, sp_ax_len)
{
    plate_t = (h_gap / 2) - (s_gap / 2) - PIP_Z_GAP;
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    fp_max_w = h_gap - 2 * PIP_Z_GAP;
    fp_w_clamped = min(fp_w, fp_max_w);
    sp_ax_real = s_gap + 2 * (plate_t - slot_d) - 0.2;
    sp_w_real = min(sp_w, s_gap - 2 * PIP_Z_GAP);

    fp_ax_real = h_gap + 2 * WALL_THICKNESS - 0.2;

    if (fp_w > fp_max_w)
        echo(str("⚠ CH", ch_num, ": FP_WIDTH clamped to ", fp_w_clamped));
    if (plate_t < 2)
        echo(str("⚠ CH", ch_num, ": plate_t=", plate_t, "mm — too thin"));

    // Fixed Pulleys at Z=0 center, axles anchored into walls
    if (SHOW_FIXED_PULLEYS) {
        translate([h_cx, FP_ROW_Y, 0])
            pulley_row(fp_count, fp_pitch, fp_od, fp_w_clamped, fp_ax_dia, fp_ax_real);
        translate([h_cx, -FP_ROW_Y, 0])
            pulley_row(fp_count, fp_pitch, fp_od, fp_w_clamped, fp_ax_dia, fp_ax_real);
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

        if (SHOW_SLIDER_PULLEYS)
            pulley_row(sp_count, sp_pitch, sp_od, sp_w_real, sp_ax_dia, sp_ax_real);
    }
}


// ==================================================
// WALL MODULES
// ==================================================

// Shared wall between two channels.
// Z=0 is channel_above top inner face. Wall body: Z=0 to WALL_T.
// Bottom face rail goes -Z (into channel above). Top face rail goes +Z (into channel below).
module shared_wall(length, cx_above, cx_below)
{
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z = (WALL_THICKNESS + stop_depth) * 2 + 2;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-length / 2, -HOUSING_HEIGHT / 2, 0])
                cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);

            // Bottom face rail + end-stops
            translate([-length / 2, -RAIL_HEIGHT / 2, -RAIL_DEPTH])
                cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-length / 2, -RAIL_HEIGHT / 2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([length / 2 - END_STOP_W, -RAIL_HEIGHT / 2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);

            // Top face rail + end-stops
            translate([-length / 2, -RAIL_HEIGHT / 2, WALL_THICKNESS])
                cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-length / 2, -RAIL_HEIGHT / 2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([length / 2 - END_STOP_W, -RAIL_HEIGHT / 2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
        }

        // Window — channel above
        translate([cx_above, 0, -stop_depth - 1])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);

        // Window — channel below
        translate([cx_below, 0, WALL_THICKNESS + stop_depth + 1])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
    }
}

// Single-face wall (CH1 bottom, CH5 top).
// rail_inward=true: rail on +Z face. false: rail on -Z face.
module single_face_wall(length, rail_inward) {
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z = (WALL_THICKNESS + stop_depth) * 2 + 2;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-length / 2, -HOUSING_HEIGHT / 2, 0])
                cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);

            if (rail_inward) {
                translate([-length / 2, -RAIL_HEIGHT / 2, WALL_THICKNESS])
                    cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-length / 2, -RAIL_HEIGHT / 2, WALL_THICKNESS])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([length / 2 - END_STOP_W, -RAIL_HEIGHT / 2, WALL_THICKNESS])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            } else {
                translate([-length / 2, -RAIL_HEIGHT / 2, -RAIL_DEPTH])
                    cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-length / 2, -RAIL_HEIGHT / 2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([length / 2 - END_STOP_W, -RAIL_HEIGHT / 2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            }
        }

        translate([0, 0, WALL_THICKNESS / 2])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
    }
}


// ==================================================
// PULLEY ROW
// ==================================================

module pulley_row(count, pitch, od, width, ax_dia, ax_len) {
    bore = ax_dia + PIP_CLEARANCE * 2;
    start_x = -((count - 1) / 2) * pitch;
    for (i = [0 : count - 1]) {
        translate([start_x + i * pitch, 0, 0]) {
            color([0.5, 0.5, 0.5])
            union() {
                cylinder(d = ax_dia, h = ax_len, center = true);
                cylinder(d = ax_dia + 1.5, h = 2.0, center = true);
            }
            color([0.95, 0.95, 0.95])
            difference() {
                cylinder(d = od, h = width, center = true);
                cylinder(d = bore, h = width + 2, center = true);
                cylinder(d = bore + 1.4, h = 2.5, center = true);
            }
        }
    }
}
