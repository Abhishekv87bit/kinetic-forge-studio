// =========================================================
// MATRIX TIER — V5-Based Single Tier Module
// =========================================================
// Direct port of MATRIX SINGLE UNIT v5.scad as a reusable module.
// 5 channels, 19 total pulley positions (3+4+5+4+3).
// Each channel's slider strip driven by its cam displacement.
//
// Coordinate system (BEFORE assembly rotation):
//   X = slider travel direction (channel length)
//   Y = housing depth
//   Z = channel stacking direction (CH1 bottom, CH5 top)
//
// The assembly applies rotate([90,0,0]) to match V5's display,
// then rotates about vertical axis for tier angle (0/120/240).
//
// Reference: MATRIX SINGLE UNIT v5.scad (V107)
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_WALLS          = true;
SHOW_SLIDER_PLATES  = true;
SHOW_FIXED_PULLEYS  = true;
SHOW_SLIDER_PULLEYS = true;

// =========================================================
// STANDALONE RENDER (when opening this file directly)
// =========================================================
_standalone_anim = sin(anim_t() * 360) * ECCENTRICITY;
// All 5 channel strips share same displacement in standalone mode
_standalone_ch_disps = [for (i = [0:4]) _standalone_anim];

rotate([90, 0, 0])
    matrix_tier(_standalone_ch_disps);


// =========================================================
// MATRIX TIER MODULE
// =========================================================
// ch_slider_disps: array of 5 displacement values (one per CHANNEL strip)
//   [CH1_disp, CH2_disp, CH3_disp, CH4_disp, CH5_disp]
//   Each value = how far the entire slider strip in that channel moves along X.
//   In the real machine, each strip is pulled by wire from one cam position.
//
// NOTE: In V5, all channels share one anim_val. In the triple helix,
// each channel's slider is driven by one cam. Since each channel has
// multiple pulleys on one strip, the strip moves as one unit.
// The 19 cams map to: CH1(3 cams share 1 strip), CH2(4→1), etc.
// Actually, each channel has ONE slider strip with N pulleys.
// Each cam on the helix connects to ONE pulley position on ONE strip.
// But the strip moves as a unit — so effectively one cam per strip
// would suffice, but the helix has 19 cams for phase distribution.
// For animation: ch_slider_disps[ch_idx] = displacement of that strip.

module matrix_tier(ch_slider_disps) {

    // Channel Z-centers (centered around 0)
    ch_z = [for (i = [0:4]) (i - 2) * STACK_OFFSET];

    // Validate shared wall fit
    for (i = [0:3]) {
        required = CH_GAPS[i]/2 + WALL_THICKNESS + CH_GAPS[i+1]/2;
        if (abs(STACK_OFFSET - required) > 0.01)
            echo(str("  Wall ", i, "-", i+1, ": STACK_OFFSET=", STACK_OFFSET,
                      " but need ", required));
    }

    // ---- WALLS ----
    if (SHOW_WALLS) {
        // CH1 bottom wall
        translate([CH_CXS[0], 0, ch_z[0] - CH_GAPS[0]/2 - WALL_THICKNESS])
            single_face_wall(CH_LENS[0], true);

        // 4 shared walls
        for (i = [0 : 3]) {
            top_z = ch_z[i] + CH_GAPS[i] / 2;
            left_a  = CH_CXS[i]   - CH_LENS[i]   / 2;
            right_a = CH_CXS[i]   + CH_LENS[i]   / 2;
            left_b  = CH_CXS[i+1] - CH_LENS[i+1] / 2;
            right_b = CH_CXS[i+1] + CH_LENS[i+1] / 2;
            wall_left  = min(left_a, left_b);
            wall_right = max(right_a, right_b);
            wall_len = wall_right - wall_left;
            wall_cx  = (wall_left + wall_right) / 2;

            translate([wall_cx, 0, top_z])
                shared_wall(wall_len,
                    CH_CXS[i] - wall_cx,
                    CH_CXS[i+1] - wall_cx);
        }

        // CH5 top wall
        translate([CH_CXS[4], 0, ch_z[4] + CH_GAPS[4]/2])
            single_face_wall(CH_LENS[4], false);
    }

    // ---- CHANNEL INTERNALS ----
    for (i = [0 : 4]) {
        slide_pos = ch_slider_disps[i];

        translate([0, 0, ch_z[i]])
            channel_internals(slide_pos, i + 1,
                CH_GAPS[i], CH_CXS[i], CH_LENS[i],
                FP_COUNTS[i], FP_PITCH, FP_OD, FP_WIDTH, FP_AXLE_DIA, FP_AXLE_LEN,
                CH_S_GAPS[i], CH_S_LENS[i], CH_S_CXS[i], CH_S_YS[i],
                SP_COUNTS[i], SP_PITCH, SP_OD, SP_WIDTH, SP_AXLE_DIA, SP_AXLE_LEN);
    }
}


// =========================================================
// CHANNEL INTERNALS (ported from V5 — identical logic)
// =========================================================

module channel_internals(slide_pos, ch_num,
    h_gap, h_cx, h_len,
    fp_count, fp_pitch, fp_od, fp_w, fp_ax_dia, fp_ax_len,
    s_gap, s_len, s_cx, s_y_shift,
    sp_count, sp_pitch, sp_od, sp_w, sp_ax_dia, sp_ax_len)
{
    plate_t = (h_gap / 2) - (s_gap / 2) - PIP_Z_GAP;
    slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    fp_max_w = h_gap - 2 * PIP_Z_GAP;
    fp_w_clamped = min(fp_w, fp_max_w);
    sp_ax_real = s_gap + 2 * (plate_t - slot_d) - 0.2;
    sp_w_real = min(sp_w, s_gap - 2 * PIP_Z_GAP);
    fp_ax_real = h_gap + 2 * WALL_THICKNESS - 0.2;

    if (fp_w > fp_max_w)
        echo(str("  CH", ch_num, ": FP_WIDTH clamped to ", fp_w_clamped));
    if (plate_t < 2)
        echo(str("  CH", ch_num, ": plate_t=", plate_t, "mm — too thin"));

    // Fixed Pulleys — upper and lower rows
    if (SHOW_FIXED_PULLEYS) {
        translate([h_cx, FP_ROW_Y, 0])
            pulley_row(fp_count, fp_pitch, fp_od, fp_w_clamped, fp_ax_dia, fp_ax_real);
        translate([h_cx, -FP_ROW_Y, 0])
            pulley_row(fp_count, fp_pitch, fp_od, fp_w_clamped, fp_ax_dia, fp_ax_real);
    }

    // Slider Assembly (entire strip moves by slide_pos)
    // NOTE: Slider strips are intentionally longer than housing channels.
    // CH3 example: strip=272mm, housing=136mm — pulleys need wider span.
    // The housing walls are structural supports for fixed pulleys and rails,
    // not containment walls for the slider. Slider overhang is by design.
    translate([slide_pos + s_cx, s_y_shift, 0]) {
        if (SHOW_SLIDER_PLATES) {
            slot_h = RAIL_HEIGHT + (RAIL_TOLERANCE * 2);

            // Bottom slider plate
            color(C_SLIDER)
            difference() {
                translate([-s_len/2, -7.5, -(s_gap/2 + plate_t)])
                    cube([s_len, 15, plate_t]);
                translate([-(s_len/2) - 1, -slot_h/2, -(s_gap/2 + plate_t) - 0.1])
                    cube([s_len + 2, slot_h, slot_d]);
            }

            // Top slider plate
            color(C_SLIDER)
            difference() {
                translate([-s_len/2, -7.5, s_gap/2])
                    cube([s_len, 15, plate_t]);
                translate([-(s_len/2) - 1, -slot_h/2, s_gap/2 + plate_t - slot_d + 0.1])
                    cube([s_len + 2, slot_h, slot_d]);
            }
        }

        // Slider pulleys
        if (SHOW_SLIDER_PULLEYS)
            pulley_row(sp_count, sp_pitch, sp_od, sp_w_real, sp_ax_dia, sp_ax_real);
    }
}


// =========================================================
// WALL MODULES (ported from V5 — identical)
// =========================================================

module shared_wall(length, cx_above, cx_below) {
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z = (WALL_THICKNESS + stop_depth) * 2 + 2;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-length/2, -HOUSING_HEIGHT/2, 0])
                cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);
            translate([-length/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
                cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-length/2, -RAIL_HEIGHT/2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([length/2 - END_STOP_W, -RAIL_HEIGHT/2, -stop_depth])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            translate([length/2 - END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
        }
        translate([cx_above, 0, -stop_depth - 1])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
        translate([cx_below, 0, WALL_THICKNESS + stop_depth + 1])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
    }
}

module single_face_wall(length, rail_inward) {
    slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    stop_depth = slot_d - PIP_Z_GAP;
    win_z = (WALL_THICKNESS + stop_depth) * 2 + 2;

    difference() {
        color([0.6, 0.6, 1.0, 1.0])
        union() {
            translate([-length/2, -HOUSING_HEIGHT/2, 0])
                cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);
            if (rail_inward) {
                translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                    cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-length/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([length/2 - END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            } else {
                translate([-length/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
                    cube([length, RAIL_HEIGHT, RAIL_DEPTH]);
                translate([-length/2, -RAIL_HEIGHT/2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
                translate([length/2 - END_STOP_W, -RAIL_HEIGHT/2, -stop_depth])
                    cube([END_STOP_W, RAIL_HEIGHT, stop_depth]);
            }
        }
        translate([0, 0, WALL_THICKNESS/2])
            cube([WINDOW_WIDTH, WINDOW_HEIGHT, win_z], center = true);
    }
}


// =========================================================
// PULLEY ROW (ported from V5 — identical)
// =========================================================

module pulley_row(count, pitch, od, width, ax_dia, ax_len) {
    bore = ax_dia + PIP_CLEARANCE * 2;
    start_x = -((count - 1) / 2) * pitch;
    for (i = [0 : count - 1]) {
        translate([start_x + i * pitch, 0, 0]) {
            color(C_STEEL)
            union() {
                cylinder(d = ax_dia, h = ax_len, center = true);
                cylinder(d = ax_dia + 1.5, h = 2.0, center = true);
            }
            color(C_NYLON)
            difference() {
                cylinder(d = od, h = width, center = true);
                cylinder(d = bore, h = width + 2, center = true);
                cylinder(d = bore + 1.4, h = 2.5, center = true);
            }
        }
    }
}
