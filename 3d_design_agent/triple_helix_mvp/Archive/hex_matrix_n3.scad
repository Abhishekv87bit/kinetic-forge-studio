// =========================================================
// HEX MATRIX N=3 — 54 Shafts, 3 Tiers, 3 Channels/Tier
// =========================================================
// Regular hex, 4 walls per tier, 3 channel gaps per tier.
// Each channel has ONE slider strip with multiple eyelets.
// One cam per channel → 3 cams per helix → 9 cams total.
//
// Per tier:
//   - 4 walls (colored by tier)
//   - 3 slider strips (one per channel gap)
//   - Each strip has eyelets at shaft positions in that channel
//   - Top/bottom hex plates with rope pass-through holes
//
// 3 tiers at 0/120/240 → walls form 54 equilateral triangle shafts.
// Each shaft = 1 block. Block displacement = sum of 3 slider motions.
//
// Cam phases (per helix, 3 cams): 0°, 120°, 240°
// =========================================================

$fn = 36;

// =============================================
// CONTROLS
// =============================================

/* [Display] */
NUM_TIERS       = 3;       // [1:1:3]
TIER_GAP        = 0;       // [0:0.5:20]
SHOW_PLATES     = true;
SHOW_WALLS      = true;
SHOW_SLIDERS    = true;
SHOW_ROPE_HOLES = true;
SHOW_SHAFTS     = false;

/* [Hex Size] */
WALL_SPACING    = 25.0;    // [10:1:80]

/* [Animation] */
MANUAL_POS      = -1;      // [-1:0.01:1]
function anim_t() = (MANUAL_POS >= 0) ? MANUAL_POS : $t;

// =============================================
// DIMENSIONS
// =============================================

LINE_DIA        = 0.3;
WALL_T          = 1.5;
PLATE_T         = 1.5;
SLIDER_BODY     = 2.0;
CH_GAP          = 4.0;
ROPE_HOLE_DIA   = 1.5;
EYELET_DIA      = 1.0;
ECCENTRICITY    = 3.0;
CAM_STROKE      = 2 * ECCENTRICITY;

// =============================================
// HEX GEOMETRY
// =============================================

N_CHANNELS      = 3;
N_WALLS         = N_CHANNELS + 1;           // 4
HEX_FTF         = N_CHANNELS * WALL_SPACING; // 3 × 25 = 75mm
HEX_CORNER_R    = HEX_FTF / 2 / cos(30);
TRI_SIDE        = WALL_SPACING / sin(60);
TRI_INSCRIBED_R = TRI_SIDE / (2 * sqrt(3));

// Cams
CAMS_PER_HELIX  = N_CHANNELS;               // 3
CAMS_TOTAL      = CAMS_PER_HELIX * 3;       // 9
CAM_PHASE_STEP  = 360 / CAMS_PER_HELIX;     // 120°

// =============================================
// TIER
// =============================================

TIER_THICK      = CH_GAP + 2 * PLATE_T;     // 7mm
WALL_H          = CH_GAP;
TIER_PITCH      = TIER_THICK + TIER_GAP;
STACK_TOTAL     = NUM_TIERS * TIER_THICK + (NUM_TIERS - 1) * TIER_GAP;

// =============================================
// SLIDER STRIP DIMENSIONS
// =============================================

STRIP_WIDTH_Y   = WALL_SPACING - WALL_T - 1.0;
STRIP_THICK_Z   = SLIDER_BODY;

// =============================================
// COLORS
// =============================================

C_PLATE   = [0.65, 0.65, 1.0, 0.35];
C_WALL_1  = [1.0, 0.25, 0.25, 0.9];
C_WALL_2  = [0.25, 0.75, 0.25, 0.9];
C_WALL_3  = [0.25, 0.45, 1.0, 0.9];
C_WALLS   = [C_WALL_1, C_WALL_2, C_WALL_3];
C_STRIP_0 = [0.95, 0.55, 0.2, 0.85];
C_STRIP_1 = [0.95, 0.75, 0.2, 0.85];
C_STRIP_2 = [0.85, 0.40, 0.7, 0.85];
C_STRIPS  = [C_STRIP_0, C_STRIP_1, C_STRIP_2];
C_SHAFT   = [1.0, 1.0, 0.3, 0.4];

// =============================================
// SHAFT POSITIONS
// =============================================
// Follow the same pattern as N=2 (hex_matrix_n2.scad):
//   Walls centered symmetrically: wall w at (w - (N_WALLS-1)/2) * WS
//   N=3: walls at -1.5WS, -0.5WS, +0.5WS, +1.5WS
//   Channel centers (strip positions): -WS, 0, +WS
//
// For triangle finding: each channel index maps to a strip center.
// _STRIP_POS[ch] = channel center Y in tier-local coords.

function _perp(a) = [cos(a+90), sin(a+90)];
_D0 = _perp(0);
_D1 = _perp(120);
_D2 = _perp(240);

// Channel center positions (symmetric about 0)
_STRIP_POS = [for (ch = [0 : N_CHANNELS-1]) (ch - (N_CHANNELS-1)/2) * WALL_SPACING];
// N=3: [-25, 0, 25]

// Triangle center for channel indices (s0,s1,s2) and orientation (0 or 1)
// Same math as N=2: shift by ±1/6 WS from channel center
function _tri_center(s0, s1, s2, orient) =
    let(
        shift = ((orient==0) ? 1/3 - 0.5 : 2/3 - 0.5) * WALL_SPACING,
        p0 = _STRIP_POS[s0] + shift,
        p1 = _STRIP_POS[s1] + shift,
        p2 = _STRIP_POS[s2] + shift,
        det = _D0[0]*_D1[1] - _D0[1]*_D1[0],
        x = (p0*_D1[1] - p1*_D0[1]) / det,
        y = (_D0[0]*p1 - _D1[0]*p0) / det,
        p2c = _D2[0]*x + _D2[1]*y
    )
    (abs(p2c - p2) < WALL_SPACING*0.35 && _in_hex(x, y, HEX_CORNER_R - 1))
    ? [x, y] : undef;

function _in_hex(x, y, r) =
    let(f = r*cos(30))
    abs(y) <= f &&
    abs(x*sin(60) + y*cos(60)) <= f &&
    abs(x*sin(60) - y*cos(60)) <= f;

function _all_shafts() =
    let(
        raw = [for (s0=[0:N_CHANNELS-1])
               for (s1=[0:N_CHANNELS-1])
               for (s2=[0:N_CHANNELS-1])
               for (o=[0:1])
                   _tri_center(s0, s1, s2, o)],
        valid = [for (p=raw) if (p != undef) p]
    ) _dedup(valid, WALL_SPACING*0.1);

function _dedup(pts, tol, i=0, acc=[]) =
    i >= len(pts) ? acc :
    _dedup(pts, tol, i+1,
           _near(pts[i], acc, tol) ? acc : concat(acc, [pts[i]]));

function _near(p, arr, tol, j=0) =
    j >= len(arr) ? false :
    norm([p[0]-arr[j][0], p[1]-arr[j][1]]) < tol ? true :
    _near(p, arr, tol, j+1);

SHAFT_POS = _all_shafts();

// 2D rotation helper
function _rot2d(p, a) = [p[0]*cos(a) - p[1]*sin(a),
                          p[0]*sin(a) + p[1]*cos(a)];

// Which channel does a local Y coordinate fall in?
// Walls at: -1.5WS, -0.5WS, +0.5WS, +1.5WS
// CH0: -1.5WS to -0.5WS (center = -WS)
// CH1: -0.5WS to +0.5WS (center = 0)
// CH2: +0.5WS to +1.5WS (center = +WS)
function _which_channel(ly) =
    let(
        shifted = ly + N_CHANNELS * WALL_SPACING / 2,
        ch = floor(shifted / WALL_SPACING)
    )
    max(0, min(N_CHANNELS - 1, ch));

// Channel center Y in local coords
function _ch_center_y(ch) = _STRIP_POS[ch];

// Hex width at a given Y offset from center
function _hex_width_at_y(y) =
    let(
        ay = abs(y),
        ftf_half = HEX_FTF / 2
    )
    (ay > ftf_half) ? 0 :
    2 * (HEX_CORNER_R - ay / cos(30)) * cos(30);

// =============================================
// ECHO
// =============================================

echo(str("=== HEX MATRIX N=3 ==="));
echo(str("Hex: ", HEX_FTF, "mm FTF | ", round(2*HEX_CORNER_R*10)/10, "mm C-C"));
echo(str("Tier: ", TIER_THICK, "mm | Stack: ", STACK_TOTAL, "mm"));
echo(str("Tri side: ", round(TRI_SIDE*10)/10, "mm"));
echo(str("Shafts found: ", len(SHAFT_POS), " (expect 54)"));
echo(str("Channels/tier: ", N_CHANNELS, " | Cams/helix: ", CAMS_PER_HELIX, " | Total cams: ", CAMS_TOTAL));
echo(str("Strip positions: ", _STRIP_POS));
echo(str("Strip: width_Y=", STRIP_WIDTH_Y, " thick_Z=", STRIP_THICK_Z));

// Per-channel shaft count
for (ch = [0 : N_CHANNELS-1]) {
    _count = len([for (p=SHAFT_POS)
        if (_which_channel(p[1]) == ch && _in_hex(p[0], p[1], HEX_CORNER_R-2)) 1]);
    echo(str("Tier 0 — CH", ch, ": ", _count, " shafts (center Y=", _STRIP_POS[ch], ")"));
}

// =============================================
// RENDER
// =============================================

hex_matrix();

module hex_matrix() {
    t = anim_t();

    for (i = [0 : NUM_TIERS-1]) {
        translate([0, 0, -i * TIER_PITCH])
            rotate([0, 0, i * 120])
                hex_tier(i, t);
    }

    // Center axis
    %color("red")
    cylinder(d=1, h=STACK_TOTAL + 20, center=true, $fn=8);

    // Shaft indicators
    if (SHOW_SHAFTS)
        for (p = SHAFT_POS) {
            color(C_SHAFT)
            translate([p[0], p[1], -STACK_TOTAL])
                cylinder(d=0.6, h=STACK_TOTAL + 10, $fn=6);
        }
}

// =============================================
// SINGLE TIER
// =============================================

module hex_tier(tier_idx, t) {

    wall_color = C_WALLS[tier_idx];
    ta = tier_idx * 120;

    // Cam phases: 3 cams, 120° apart on helix
    cam_phase = [for (c = [0 : N_CHANNELS-1]) c * CAM_PHASE_STEP];

    // ---- HEX PLATES with rope holes ----
    if (SHOW_PLATES) {
        for (zs = [-1, 1]) {
            pz = zs * (TIER_THICK/2 - PLATE_T/2);
            difference() {
                color(C_PLATE)
                translate([0, 0, pz])
                    linear_extrude(PLATE_T, center=true)
                        rotate([0, 0, 30])
                            circle(r=HEX_CORNER_R, $fn=6);

                if (SHOW_ROPE_HOLES)
                    for (p = SHAFT_POS) {
                        lp = _rot2d(p, -ta);
                        if (_in_hex(lp[0], lp[1], HEX_CORNER_R-1))
                            translate([lp[0], lp[1], pz])
                                cylinder(d=ROPE_HOLE_DIA, h=PLATE_T+1, center=true, $fn=12);
                    }
            }
        }
    }

    // ---- WALLS (4 per tier, clipped to hex) ----
    // Wall positions: (w - 1.5) * WS → -37.5, -12.5, +12.5, +37.5
    if (SHOW_WALLS) {
        for (w = [0 : N_WALLS-1]) {
            wy = (w - (N_WALLS-1)/2) * WALL_SPACING;

            difference() {
                color(wall_color)
                intersection() {
                    translate([0, wy, 0])
                        cube([HEX_CORNER_R*3, WALL_T, WALL_H], center=true);
                    linear_extrude(WALL_H, center=true)
                        rotate([0, 0, 30])
                            circle(r=HEX_CORNER_R, $fn=6);
                }

                if (SHOW_ROPE_HOLES)
                    for (p = SHAFT_POS) {
                        lp = _rot2d(p, -ta);
                        if (abs(lp[1] - wy) < WALL_SPACING/2 + 1)
                            translate([lp[0], wy, 0])
                                rotate([90, 0, 0])
                                    cylinder(d=ROPE_HOLE_DIA, h=WALL_T+2, center=true, $fn=12);
                    }
            }
        }
    }

    // ---- SLIDER STRIPS (3 per tier, one per channel) ----
    if (SHOW_SLIDERS) {
        for (ch = [0 : N_CHANNELS-1]) {
            ch_y = _ch_center_y(ch);

            // Strip displacement from cam
            disp = ECCENTRICITY * sin(t * 360 + cam_phase[ch]);

            // Hex width at this channel's Y position = strip length
            strip_len = _hex_width_at_y(ch_y) - 2;

            color(C_STRIPS[ch])
            intersection() {
                translate([disp, ch_y, 0])
                    _slider_strip_with_eyelets(strip_len, ch, ta, disp);

                // Clip to hex interior
                linear_extrude(WALL_H, center=true)
                    rotate([0, 0, 30])
                        circle(r=HEX_CORNER_R - WALL_T, $fn=6);
            }
        }
    }
}

// =============================================
// SLIDER STRIP WITH EYELETS
// =============================================

module _slider_strip_with_eyelets(strip_len, ch, tier_angle, disp_x) {
    ch_cy = _ch_center_y(ch);

    difference() {
        cube([strip_len, STRIP_WIDTH_Y, STRIP_THICK_Z], center=true);

        // Eyelets at shaft positions within this channel
        for (p = SHAFT_POS) {
            lp = _rot2d(p, -tier_angle);
            if (_in_hex(lp[0], lp[1], HEX_CORNER_R-2) && _which_channel(lp[1]) == ch) {
                // Strip-local coords: strip origin is at [disp_x, ch_cy] in tier space
                translate([lp[0] - disp_x, lp[1] - ch_cy, 0])
                    cylinder(d=EYELET_DIA, h=STRIP_THICK_Z+1, center=true, $fn=12);
            }
        }
    }
}
