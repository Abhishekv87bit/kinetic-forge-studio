// =========================================================
// MATRIX TIER V4 — Hex-Parametric Prototype (Single Tier)
// =========================================================
// Everything derives from HEX_R (circumradius) via config_v4.scad.
//   - Flat-top hex: vertices along X (channel travel direction)
//   - Channel stacking along Z (flat-to-flat axis)
//   - W(d) = 2*(R - |d|/sqrt(3)) = hex width at stacking offset d
//   - Odd number of channels, center channel longest
//
// CRITICAL: One "column" = upper_FP + slider_pulley + lower_FP
//   All three share the same X position and same pitch (COL_PITCH).
//   Culling is per-COLUMN: all 3 go or all 3 stay.
//
// Pulleys are smooth ROLLERS — as wide as the gap allows, no grooves.
// Housing walls and slider plates are minimum height for clearance.
//
// Coordinate system (before assembly rotation):
//   X = slider travel (channel direction) — corner-to-corner
//   Y = housing depth (rope routing direction)
//   Z = channel stacking — flat-to-flat
// =========================================================

include <config_v4.scad>

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
PIP_CLEARANCE  = 0.3;
PIP_Z_GAP      = 0.3;

// =============================================
// TIER-SPECIFIC DERIVED DIMENSIONS
// =============================================

/* [Guide Rail] */
RAIL_HEIGHT    = 4.0;
RAIL_DEPTH     = 1.0;
RAIL_TOLERANCE = 0.4;
END_STOP_W     = 5.0;
WINDOW_WIDTH   = 20.0;
WINDOW_HEIGHT  = min(16.0, HOUSING_HEIGHT - 4);  // scale with housing

/* [Pulleys — ROLLERS (0.5mm clearance each side)] */
// Fixed pulleys: 0.5mm play per side for shrinkage/moisture tolerance
FP_WIDTH       = CH_GAP - 1.0;                // 11.5 - 1.0 = 10.5mm (0.5mm/side)
FP_AXLE_DIA    = 3.0;

// Slider pulleys: 0.5mm play per side
S_GAP          = 5.0;
SP_WIDTH       = S_GAP - 1.0;                 // 5 - 1.0 = 4.0mm (0.5mm/side)
SP_AXLE_DIA    = 3.0;

// Slider plate Y-dimension — just enough to cover roller + rail slot
SLIDER_PLATE_Y = SP_OD + 2;  // 8 + 2 = 10mm

// Wall lengths: must cover the outermost culled column's axle + margin
// The axle extends FP_AXLE_LEN/2 = ~8mm from pulley center, but the wall
// is what the axle mounts into. Wall must reach past the outermost pulley.
// Wall length = span of culled columns + 2×(FP_OD/2 + WALL_MARGIN_AXLE)
WALL_MARGIN_AXLE = 4;  // mm beyond outermost pulley center for axle pocket

// Slider strip lengths — CULLED to pulley coverage, ASYMMETRIC
// HELIX SIDE (+X): slider extends toward helix, needs end stop catch.
// ARM SIDE (−X): slider NEVER travels this way (arms block it).
//   Only needs enough to cover edge pulley, no end stop.
SLIDER_MARGIN_HELIX = SP_OD/2 + END_STOP_W + 1;  // 4+5+1 = 10mm (catch surface)
SLIDER_MARGIN_ARM   = SP_OD/2 + 1;                // 4+1   =  5mm (bare minimum)

// Axle lengths
FP_AXLE_LEN = CH_GAP + 2 * WALL_THICKNESS - 0.2;  // spans gap + both walls
_plate_t = (CH_GAP/2) - (S_GAP/2) - PIP_Z_GAP;
_slot_d  = PIP_Z_GAP + RAIL_DEPTH + 0.5;
SP_AXLE_LEN = S_GAP + 2 * (_plate_t - _slot_d) - 0.2;

// =============================================
// DERIVED ARRAYS (tier-specific computations)
// =============================================

// Housing wall lengths: max of hex-derived length and culled span
function _culled_span(ch_idx) =
    let(d = CH_OFFSETS[ch_idx],
        len = CH_LENS[ch_idx],
        raw = raw_col_count(len),
        // Find outermost culled column positions (with stagger)
        cols = [for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, ch_idx), d)) col_x(raw, j, ch_idx)])
    len(cols) == 0 ? 0 :
    let(min_x = min(cols), max_x = max(cols),
        maxp = max(abs(min_x), abs(max_x)))
    2 * (maxp + FP_OD/2 + WALL_MARGIN_AXLE);

CH_WALL_LENS = [for (i = [0:NUM_CHANNELS-1])
    max(CH_LENS[i], _culled_span(i))
];

// Slider length computed from actual staggered column span
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
echo(str("===== MATRIX TIER V4 — HEX PROTOTYPE ====="));
echo(str("HEX_R=", HEX_R, "  C2C=", HEX_C2C, "mm  FF=", round(HEX_FF*10)/10, "mm"));
echo(str("Channels: ", NUM_CHANNELS, " (odd)"));
echo(str("COL_PITCH=", COL_PITCH, "mm | HOUSING_HEIGHT=", HOUSING_HEIGHT, "mm"));
echo(str("Stagger: half-pitch=", STAGGER_HALF_PITCH, "mm (odd channels offset +", STAGGER_HALF_PITCH, "mm)"));
echo(str("Roller widths: FP=", FP_WIDTH, "mm  SP=", SP_WIDTH, "mm"));

for (i = [0:NUM_CHANNELS-1]) {
    echo(str("  CH", i+1,
             ": d=", round(CH_OFFSETS[i]*10)/10, "mm",
             "  hex_len=", round(CH_LENS[i]*10)/10,
             "  wall_len=", round(CH_WALL_LENS[i]*10)/10,
             "  cols=", COL_COUNTS[i],
             "  stagger=", round(_ch_stagger(i)*10)/10, "mm",
             (i == _CENTER_CH ? "  ← CENTER" : "")));
}

function _sum_arr(arr, i=0) =
    (i >= len(arr)) ? 0 : arr[i] + _sum_arr(arr, i+1);
_total_cols = _sum_arr(COL_COUNTS);
echo(str("  TOTAL columns: ", _total_cols,
         " (", _total_cols * 3, " rollers)"));

// Clearance checks
echo(str("  plate_t=", _plate_t, "mm",
         (_plate_t >= _slot_d ? " ✓" : " ⚠ TOO THIN")));
echo(str("  FP fits gap: OD=", FP_OD, " W=", FP_WIDTH, " in ", CH_GAP, "mm gap",
         (FP_OD < CH_GAP ? " ✓" : " ⚠")));
echo(str("  Col gap: ", COL_PITCH - max(FP_OD, SP_OD), "mm between rollers",
         (COL_PITCH - max(FP_OD, SP_OD) >= 2 ? " ✓" : " ⚠ TIGHT")));
// Verify FP ↔ SP row clearance (roller-to-roller gap at Y=0 ↔ ±FP_ROW_Y)
_fp_sp_gap = FP_ROW_Y - (FP_OD + SP_OD) / 2;
echo(str("  FP-SP gap: ", _fp_sp_gap, "mm (need ≥2mm for rope)",
         (_fp_sp_gap >= 2 ? " ✓" : " ⚠ TOO CLOSE")));
echo(str("  Slider plate Y: ", SLIDER_PLATE_Y, "mm"));

echo(str("  Slider offset: BIAS=", SLIDER_BIAS, " REST_OFFSET=", SLIDER_REST_OFFSET, "mm"));
echo(str("  Slider margins: helix=", SLIDER_MARGIN_HELIX, "mm (catch)  arm=", SLIDER_MARGIN_ARM, "mm (bare)"));
echo(str("  Wall: ", WALL_THICKNESS, "mm  CH_GAP: ", CH_GAP, "mm (STACK_OFFSET-WALL)"));

// Plate-vs-wall travel check
for (i = [0:NUM_CHANNELS-1]) {
    if (COL_COUNTS[i] > 0) {
        _plate_half = CH_S_LENS[i] / 2;
        _wall_half = CH_WALL_LENS[i] / 2 - END_STOP_W;
        _max_travel_helix = SLIDER_REST_OFFSET + ECCENTRICITY;
        _max_travel_arm = abs(ECCENTRICITY - SLIDER_REST_OFFSET);
        if (_plate_half + _max_travel_helix > _wall_half)
            echo(str("  ⚠ CH", i+1, " plate exceeds wall at max helix travel (",
                     round((_plate_half + _max_travel_helix - _wall_half)*10)/10, "mm over)"));
        if (_plate_half + _max_travel_arm > _wall_half)
            echo(str("  ⚠ CH", i+1, " plate exceeds wall at max arm travel (",
                     round((_plate_half + _max_travel_arm - _wall_half)*10)/10, "mm over)"));
    }
}


// =============================================
// STANDALONE RENDER
// =============================================
// Per-channel helical phase — wave propagates across slider array
// (matches main_stack behavior)
_ch_disps = [for (i = [0:NUM_CHANNELS-1])
    let(phase = i * (360.0 / NUM_CHANNELS))
    sin(anim_t() * 360 + phase) * ECCENTRICITY
];

rotate([90, 0, 0])
    matrix_tier_v4(_ch_disps);


// =========================================================
// MATRIX TIER V4 MODULE
// =========================================================
module matrix_tier_v4(ch_slider_disps) {

    difference() {
        union() {
            // Hex clip ONLY on walls + fixed pulleys (static geometry)
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
        // Posts (M4 threaded rod, 4mm) pass through these notches.
        // Notch = cylinder along Y at each hex vertex in XZ plane.
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
        // Bottom boundary wall — rail faces INWARD (+Z toward channel)
        translate([0, 0, CH_OFFSETS[0] - CH_GAP/2 - WALL_THICKNESS])
            _boundary_wall(CH_WALL_LENS[0], 1);  // rail_dir = +1 = inward/up

        // Shared walls between adjacent channels
        for (i = [0 : NUM_CHANNELS - 2]) {
            z_top = CH_OFFSETS[i] + CH_GAP / 2;
            wall_len = max(CH_WALL_LENS[i], CH_WALL_LENS[i+1]);
            translate([0, 0, z_top])
                _shared_wall(wall_len);
        }

        // Top boundary wall — rail faces INWARD (-Z toward channel)
        translate([0, 0, CH_OFFSETS[NUM_CHANNELS-1] + CH_GAP/2])
            _boundary_wall(CH_WALL_LENS[NUM_CHANNELS-1], -1);  // rail_dir = -1 = inward/down
    }

    // Fixed rollers (upper + lower redirect rows)
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
// ALL SLIDERS (NOT hex-clipped)
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
        px = col_x(raw_n, j, ch_idx);  // staggered X
        if (col_inside_hex(px, d)) {
            // Upper redirect roller
            translate([px, FP_ROW_Y, 0])
                _roller(FP_OD, FP_WIDTH, FP_AXLE_DIA, FP_AXLE_LEN);
            // Lower redirect roller
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
        // slide_disp = cam displacement (±ECCENTRICITY)
        // SLIDER_REST_OFFSET = static bias toward helix side
        // Net: slider protrudes mostly toward helix, barely toward arm
        translate([slide_disp + SLIDER_REST_OFFSET, 0, 0]) {
            // Asymmetric plate: helix side has end-stop catch,
            // arm side is bare-minimum pulley coverage.
            // _strip_offset shifts plate+pulleys so pulley grid
            // is centered within the asymmetric plate.
            _strip_offset = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2;  // 2.5mm

            // Slider plates
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

            // Slider rollers — shifted with plate as one rigid unit
            if (SHOW_SLIDER_PULLEYS) {
                for (j = [0 : max(0, raw_n - 1)]) {
                    px = col_x(raw_n, j, ch_idx);  // staggered X
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
// BOUNDARY WALL (top or bottom of tier)
// =========================================================
// rail_dir: +1 = rail on +Z face (bottom wall, rail faces channel above)
//           -1 = rail on -Z face (top wall, rail faces channel below)
module _boundary_wall(length, rail_dir) {
    _sd = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    _stop = WALL_THICKNESS - PIP_Z_GAP;
    _win_w = min(WINDOW_WIDTH, length * 0.5);
    _win_z = WALL_THICKNESS + 4;

    difference() {
        color(C_WALL) {
            // Main wall plate
            translate([-length/2, -HOUSING_HEIGHT/2, 0])
                cube([length, HOUSING_HEIGHT, WALL_THICKNESS]);

            // Guide rail on correct face
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

        // Rope routing window (centered)
        translate([0, 0, WALL_THICKNESS/2])
            cube([_win_w, WINDOW_HEIGHT, _win_z], center = true);
    }
}


// =========================================================
// SHARED WALL between two channels (rails on both faces)
// =========================================================
module _shared_wall(wall_len) {
    _sd = PIP_Z_GAP + RAIL_DEPTH + 0.5;
    _stop = WALL_THICKNESS - PIP_Z_GAP;
    _win_z = (WALL_THICKNESS + _stop) * 2 + 2;
    _win_w = min(WINDOW_WIDTH, wall_len * 0.5);

    difference() {
        color(C_WALL)
        union() {
            // Main wall plate
            translate([-wall_len/2, -HOUSING_HEIGHT/2, 0])
                cube([wall_len, HOUSING_HEIGHT, WALL_THICKNESS]);

            // Bottom-facing rail (-Z, for channel below)
            translate([-wall_len/2, -RAIL_HEIGHT/2, -RAIL_DEPTH])
                cube([wall_len, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-wall_len/2, -RAIL_HEIGHT/2, -_stop])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);
            translate([wall_len/2 - END_STOP_W, -RAIL_HEIGHT/2, -_stop])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);

            // Top-facing rail (+Z, for channel above)
            translate([-wall_len/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([wall_len, RAIL_HEIGHT, RAIL_DEPTH]);
            translate([-wall_len/2, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);
            translate([wall_len/2 - END_STOP_W, -RAIL_HEIGHT/2, WALL_THICKNESS])
                cube([END_STOP_W, RAIL_HEIGHT, _stop]);
        }

        // Rope pass-through windows (centered)
        translate([0, 0, -_stop - 1])
            cube([_win_w, WINDOW_HEIGHT, _win_z], center = true);
        translate([0, 0, WALL_THICKNESS + _stop + 1])
            cube([_win_w, WINDOW_HEIGHT, _win_z], center = true);
    }
}


// =========================================================
// ROLLER (full-width pulley)
// =========================================================
module _roller(od, width, ax_dia, ax_len) {
    bore = ax_dia + PIP_CLEARANCE * 2;

    // Axle
    color(C_STEEL)
    cylinder(d = ax_dia, h = ax_len, center = true);

    // Roller body — smooth, full width
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

        // Keep hex interior — XZ cross-section, extruded along Y
        rotate([90, 0, 0])
            cylinder(r = HEX_R - 0.5, h = HOUSING_HEIGHT + 10, $fn = 6, center = true);
    }
}
