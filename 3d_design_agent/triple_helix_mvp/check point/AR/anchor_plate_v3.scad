// =========================================================
// ANCHOR PLATE V3 — Hex String Tie-Off Plate + M4 Bolt Flange
// =========================================================
// Sits on TOP of the main stack (above Tier 1).
// All strings are anchored here — one hole per column position.
// Same hex shape as matrix tiers (HEX_R=100) with 6 flange ears
// at vertices for M4 bolt-through clamping.
//
// Features:
//   - Regular hex plate (HEX_R=100), 5mm thick
//   - 6 flange ears at hex vertices extending to FLANGE_R=110
//   - M4 counterbored bolt holes (flush head on top surface)
//   - String tie-off holes at every culled column position
//   - Retainer recesses on top face for knot/washer
//
// Coordinate system: same as tier after rotate([90,0,0])
//   X,Y = hex plane    Z = up (plate thickness)
// =========================================================

$fn = 40;

// =============================================
// HEX GEOMETRY (matching matrix_tier_v3.scad)
// =============================================
HEX_R         = 118;
WALL_MARGIN   = 8;
COL_PITCH     = 12;
STACK_OFFSET  = 14.0;
FP_OD         = 8.0;
SP_OD         = 8.0;

HEX_C2C = 2 * HEX_R;
HEX_FF  = HEX_R * sqrt(3);

function hex_w(d) =
    let(max_d = HEX_R * sqrt(3) / 2)
    (abs(d) > max_d) ? 0 : 2 * (HEX_R - abs(d) / sqrt(3));

function ch_len(d) = max(0, hex_w(d) - 2 * WALL_MARGIN);

function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;
_CENTER = (NUM_CHANNELS - 1) / 2;

CH_OFFSETS = [for (i = [0:NUM_CHANNELS-1]) (i - _CENTER) * STACK_OFFSET];
CH_LENS = [for (i = [0:NUM_CHANNELS-1]) ch_len(CH_OFFSETS[i])];

// Column culling (same logic as matrix_tier_v3)
function col_x(count, idx) =
    -((count - 1) / 2) * COL_PITCH + idx * COL_PITCH;

function col_inside_hex(px, d) =
    let(max_od = max(FP_OD, SP_OD))
    (abs(px) + max_od/2 + 1) < (hex_w(d) / 2);

function raw_col_count(len) =
    (len < COL_PITCH) ? ((len > max(FP_OD, SP_OD)) ? 1 : 0) :
    floor(len / COL_PITCH) + 1;

// =============================================
// PLATE PARAMETERS
// =============================================
PLATE_THICK       = 5.0;
STRING_HOLE_DIA   = 2.0;      // clearance for 0.5mm Dyneema + knot
RETAINER_DIA      = 5.0;      // washer/knot retainer recess
RETAINER_DEPTH    = 1.5;

// =============================================
// FRAME POST NOTCHES
// =============================================
POST_DIA          = 4.5;      // M4 post clearance (4mm rod + 0.5mm gap)

// =============================================
// COLORS
// =============================================
C_ANCHOR = [0.6, 0.6, 0.7, 0.8];

// =============================================
// STANDALONE RENDER
// =============================================
anchor_plate_v3();

// =============================================
// VERIFICATION
// =============================================
function _sum(arr, i=0) = (i >= len(arr)) ? 0 : arr[i] + _sum(arr, i+1);

_col_counts = [for (i = [0:NUM_CHANNELS-1])
    let(d = CH_OFFSETS[i], len = CH_LENS[i], raw = raw_col_count(len))
    len <= 0 ? 0 :
    len([for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j), d)) 1])
];
_total_holes = _sum(_col_counts);

echo(str("=== ANCHOR PLATE V3 ==="));
echo(str("HEX_R=", HEX_R, "mm | Channels=", NUM_CHANNELS));
echo(str("String holes: ", _total_holes));
echo(str("Plate: ", HEX_C2C, "mm C2C × ", PLATE_THICK, "mm thick"));
echo(str("Post notches: 6 × ", POST_DIA, "mm at hex vertices"));


// =========================================================
// ANCHOR PLATE MODULE
// =========================================================
// Plain hex plate with string holes and 6 edge notches for
// frame posts. No flange ears — frame provides all clamping.
module anchor_plate_v3() {

    color(C_ANCHOR)
    difference() {
        // Hex plate body
        cylinder(r = HEX_R, h = PLATE_THICK, $fn = 6);

        // String holes at every culled column position
        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j);
                    if (col_inside_hex(px, d)) {
                        // Through-hole
                        translate([px, -d, -1])
                            cylinder(d = STRING_HOLE_DIA, h = PLATE_THICK + 2, $fn = 12);
                        // Retainer recess on top face
                        translate([px, -d, PLATE_THICK - RETAINER_DEPTH])
                            cylinder(d = RETAINER_DIA, h = RETAINER_DEPTH + 1, $fn = 16);
                    }
                }
            }
        }

        // 6 semicircular post notches at hex vertices
        for (i = [0 : 5]) {
            a = i * 60;
            translate([HEX_R * cos(a), HEX_R * sin(a), -1])
                cylinder(d = POST_DIA, h = PLATE_THICK + 2, $fn = 12);
        }
    }
}
