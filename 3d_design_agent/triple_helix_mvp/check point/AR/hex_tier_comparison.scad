// =========================================================
// HEX TIER — Prototype with FP_PITCH=12, SP_PITCH=16
// =========================================================
// Reuben's design: ODD number of channels, channels run parallel
// to flat hex edges, stacking perpendicular. Channel lengths
// taper naturally from hex boundary geometry.
//
// FLAT-TOP hex orientation:
//   - Flat edges at top/bottom (parallel to channels)
//   - Vertices at left/right (channel travel direction)
//   - Channel direction (X) = corner-to-corner = 2R (LONGEST)
//   - Stacking direction (Y) = flat-to-flat = R*sqrt(3)
//
// Width formula at stacking offset d from center:
//   W(d) = 2 * (R - |d| / sqrt(3))
//
// View: numpad 5 (ortho) + numpad 7 (top)
// Use customizer slider for HEX_R to explore sizes.
// =========================================================

/* [Hex Parameters] */
HEX_R = 80;       // [40:1:150] circumradius — single sizing control

/* [Channel Spacing] */
FP_PITCH   = 12;  // [8:1:30] fixed pulley pitch (prototype: 12mm)
SP_PITCH   = 16;  // [10:1:50] slider pulley pitch (prototype: 16mm)

/* [Display] */
SHOW_HEX_OUTLINE  = true;
SHOW_PULLEYS      = true;
SHOW_SLIDERS      = true;
SHOW_LABELS       = true;
SHOW_3TIER_STACK  = false;  // toggle to see 3-tier 120° rotation

$fn = 30;

// === FIXED CONSTANTS (compressed prototype) ===
STACK_OFFSET   = 14.0;   // CH_GAP(12) + WALL(2)
WALL_THICKNESS = 2.0;
CH_GAP         = 12.0;
WALL_MARGIN    = 6.0;    // reduced — tighter with smaller pulleys
ECCENTRICITY   = 12.0;
FP_OD          = 8.0;
SP_OD          = 8.0;
FP_ROW_Y       = 12.0;
HOUSING_HEIGHT = 40.0;

// Colors
C_WALL   = [0.6, 0.6, 1.0, 0.6];
C_FP     = [0.95, 0.95, 0.92, 1.0];
C_SP     = [0.9, 0.4, 0.4, 0.8];
C_HEX    = [0.3, 0.8, 0.3, 0.2];
C_SLIDER = [0.9, 0.4, 0.4, 0.5];
C_LABEL  = [0.1, 0.1, 0.1, 1.0];

// =========================================================
// HEX GEOMETRY
// =========================================================
// Flat-top hex: vertices along X (channel direction)
// W(d) = 2*(R - |d|/sqrt(3))  where d = stacking offset

function hex_width(R, d) =
    let(max_d = R * sqrt(3) / 2)
    (abs(d) > max_d) ? 0 : 2 * (R - abs(d) / sqrt(3));

// Usable channel length at stacking offset d
function ch_length(R, d) = max(0, hex_width(R, d) - 2 * WALL_MARGIN);

// Number of channels (odd!) that fit within the hex stacking range
// Stacking range = ±R*sqrt(3)/2 (flat-to-flat/2)
function num_channels(R) =
    let(half_ff = R * sqrt(3) / 2,
        // outermost channel center must have usable length > 0
        max_usable_d = R * sqrt(3) / 2 - WALL_MARGIN / sqrt(3) * 0,
        half_count = floor((half_ff - STACK_OFFSET/2) / STACK_OFFSET))
    2 * half_count + 1;

// Pulley count for a given channel length
function pulley_count(ch_len, pitch) =
    (ch_len < pitch) ? ((ch_len > 0) ? 1 : 0) :
    floor(ch_len / pitch) + 1;

// =========================================================
// COMPUTE AND ECHO
// =========================================================

N_CH = num_channels(HEX_R);
HEX_FF = HEX_R * sqrt(3);
HEX_C2C = 2 * HEX_R;

echo(str("===== HEX TIER: R=", HEX_R, " ====="));
echo(str("Corner-to-corner (channel dir) = ", HEX_C2C, "mm"));
echo(str("Flat-to-flat (stacking dir) = ", round(HEX_FF*10)/10, "mm"));
echo(str("Channels: ", N_CH, " (odd ✓)"));
echo(str("FP_PITCH=", FP_PITCH, "  SP_PITCH=", SP_PITCH));

// Compute all channel data
total_fp = 0;
for (i = [0 : N_CH-1]) {
    center_idx = (N_CH - 1) / 2;
    d = (i - center_idx) * STACK_OFFSET;
    w = hex_width(HEX_R, d);
    l = ch_length(HEX_R, d);
    fp_n = pulley_count(l, FP_PITCH);
    echo(str("  CH", i+1,
             ": d=", round(d*10)/10, "mm",
             "  hex_w=", round(w*10)/10, "mm",
             "  usable=", round(l*10)/10, "mm",
             "  FP=", fp_n,
             "  SP=", pulley_count(l, SP_PITCH)));
}

// Total pulleys
_center = (N_CH - 1) / 2;
_total_fp = [for (i=[0:N_CH-1]) pulley_count(ch_length(HEX_R, (i-_center)*STACK_OFFSET), FP_PITCH)];
echo(str("  TOTAL fixed pulleys: ",
    _total_fp[0]
    + (N_CH > 1 ? _total_fp[1] : 0)
    + (N_CH > 2 ? _total_fp[2] : 0)
    + (N_CH > 3 ? _total_fp[3] : 0)
    + (N_CH > 4 ? _total_fp[4] : 0)
    + (N_CH > 5 ? _total_fp[5] : 0)
    + (N_CH > 6 ? _total_fp[6] : 0)
    + (N_CH > 7 ? _total_fp[7] : 0)
    + (N_CH > 8 ? _total_fp[8] : 0)
    + (N_CH > 9 ? _total_fp[9] : 0)
    + (N_CH > 10 ? _total_fp[10] : 0)
    + (N_CH > 11 ? _total_fp[11] : 0)
    + (N_CH > 12 ? _total_fp[12] : 0)
    + (N_CH > 13 ? _total_fp[13] : 0)
    + (N_CH > 14 ? _total_fp[14] : 0)
));

// =========================================================
// RENDER
// =========================================================

if (SHOW_3TIER_STACK) {
    // 3 tiers at 0°, 120°, 240° — view from top to check alignment
    for (a = [0, 120, 240]) {
        color_t = (a == 0) ? [0.6,0.6,1,0.4] :
                  (a == 120) ? [1,0.6,0.6,0.4] : [0.6,1,0.6,0.4];
        color(color_t)
        rotate([0, 0, a])
            hex_tier_topview(HEX_R, N_CH, false);
    }
    // Hex outline on top
    if (SHOW_HEX_OUTLINE)
        color([0, 0, 0, 0.3])
        linear_extrude(0.5)
            rotate([0, 0, 30])
                difference() {
                    circle(r = HEX_R + 1, $fn = 6);
                    circle(r = HEX_R - 1, $fn = 6);
                }
} else {
    hex_tier_topview(HEX_R, N_CH, true);
}


// =========================================================
// MODULE: Top-down view of a single hex tier
// =========================================================
module hex_tier_topview(R, N, show_details) {
    center_idx = (N - 1) / 2;
    FF = R * sqrt(3);

    // Hex outline
    if (SHOW_HEX_OUTLINE && show_details) {
        color(C_HEX)
        linear_extrude(height = 0.5)
            rotate([0, 0, 30])  // flat-top: rotate 30° from default pointy
                difference() {
                    circle(r = R, $fn = 6);
                    circle(r = R - 2, $fn = 6);
                }
    }

    // Channels
    for (i = [0 : N-1]) {
        d = (i - center_idx) * STACK_OFFSET;  // stacking offset
        len_i = ch_length(R, d);
        fp_n = pulley_count(len_i, FP_PITCH);
        sp_n = pulley_count(len_i, SP_PITCH);

        if (len_i > 0) {
            // Housing walls
            color(C_WALL)
            translate([0, d, 0])
                difference() {
                    linear_extrude(1.5)
                        square([len_i + 2*WALL_THICKNESS, CH_GAP + 2*WALL_THICKNESS], center=true);
                    translate([0, 0, -0.5])
                    linear_extrude(2.5)
                        square([len_i, CH_GAP], center=true);
                }

            // Fixed pulleys
            if (SHOW_PULLEYS && show_details) {
                color(C_FP)
                translate([0, d, 2]) {
                    fp_start = -((fp_n - 1) / 2) * FP_PITCH;
                    for (j = [0:fp_n-1]) {
                        // Upper redirect row
                        translate([fp_start + j*FP_PITCH, FP_ROW_Y/3, 0])
                            cylinder(d=FP_OD, h=1.5, $fn=16);
                        // Lower redirect row
                        translate([fp_start + j*FP_PITCH, -FP_ROW_Y/3, 0])
                            cylinder(d=FP_OD, h=1.5, $fn=16);
                    }
                }

                // Slider pulleys
                color(C_SP)
                translate([0, d, 4]) {
                    sp_start = -((sp_n - 1) / 2) * SP_PITCH;
                    for (j = [0:sp_n-1])
                        translate([sp_start + j*SP_PITCH, 0, 0])
                            cylinder(d=SP_OD, h=1.5, $fn=16);
                }
            }

            // Slider strip (extends beyond hex)
            if (SHOW_SLIDERS && show_details) {
                slider_len = max(len_i, (sp_n-1)*SP_PITCH + 2*(ECCENTRICITY + 8));
                color(C_SLIDER)
                translate([0, d, 0.5])
                    linear_extrude(0.5)
                        square([slider_len, 3], center=true);
            }

            // Labels
            if (SHOW_LABELS && show_details) {
                hw = hex_width(R, d);
                is_center = (i == center_idx);
                label_color = is_center ? [1,0,0,1] : C_LABEL;
                color(label_color)
                translate([hw/2 + 5, d, 0])
                    linear_extrude(0.5)
                        text(str(fp_n, "p"),
                             size=3, halign="left", valign="center");
            }
        }
    }

    // Dimension labels
    if (show_details) {
        color([1, 0, 0, 0.8])
        translate([0, -FF/2 - 10, 0])
            linear_extrude(0.5)
                text(str("C2C=", 2*R, " (chan)  FF=", round(FF*10)/10, " (stack)"),
                     size=4, halign="center");
    }
}
