// =========================================================
// ANCHOR PLATE V5.3 — Hex String Tie-Off Plate with Alignment Pins
// =========================================================
// Sits on TOP of the main stack (above Tier 1).
// All strings are anchored here — one hole per column position.
// Same hex shape as matrix tiers (HEX_R=89) with 6
// post notches at vertices for frame rod clearance.
// Alignment pins protrude downward to register into the
// monolithic matrix and guide plate holes.
//
// All geometry parameters sourced from config_v5_3.scad.
// Staggered column positions via col_x(count, idx, ch_idx).
// =========================================================

include <config_v5_3.scad>

$fn = 40;

// =============================================
// COLORS
// =============================================
C_ANCHOR = [0.6, 0.6, 0.7, 0.8];

// =============================================
// STANDALONE RENDER
// =============================================
anchor_plate_v5_3();

// =============================================
// VERIFICATION
// =============================================
function _sum(arr, i=0) = (i >= len(arr)) ? 0 : arr[i] + _sum(arr, i+1);

_col_counts = [for (i = [0:NUM_CHANNELS-1])
    let(d = CH_OFFSETS[i], clen = CH_LENS[i], raw = raw_col_count(clen))
    clen <= 0 ? 0 :
    len([for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, i), d)) 1])
];
_total_holes = _sum(_col_counts);

echo(str("=== ANCHOR PLATE V5.3 ==="));
echo(str("HEX_R=", HEX_R, "mm | Channels=", NUM_CHANNELS));
echo(str("String holes: ", _total_holes));
echo(str("Plate: ", HEX_C2C, "mm C2C x ", ANCHOR_THICK, "mm thick"));
echo(str("Post notches: 6 x ", POST_DIA, "mm at hex vertices"));
echo(str("Alignment pins: ", ALIGN_PIN_COUNT, " x ", ALIGN_PIN_DIA, "mm protruding ", ALIGN_PIN_DEPTH, "mm below at R=", ALIGN_PIN_R, "mm"));


// =========================================================
// ANCHOR PLATE MODULE
// =========================================================
module anchor_plate_v5_3() {

    // Main plate body
    color(C_ANCHOR)
    difference() {
        cylinder(r = HEX_R, h = ANCHOR_THICK, $fn = 6);

        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j, i);
                    if (col_inside_hex(px, d)) {
                        translate([px, -d, -1])
                            cylinder(d = STRING_HOLE_DIA, h = ANCHOR_THICK + 2, $fn = 12);
                        translate([px, -d, ANCHOR_THICK - RETAINER_DEPTH])
                            cylinder(d = RETAINER_DIA, h = RETAINER_DEPTH + 1, $fn = 16);
                    }
                }
            }
        }

        for (i = [0 : 5]) {
            a = i * 60;
            translate([HEX_R * cos(a), HEX_R * sin(a), -1])
                cylinder(d = POST_DIA, h = ANCHOR_THICK + 2, $fn = 12);
        }
    }

    // Alignment pins — protrude downward from bottom face
    // These register into the monolithic matrix and guide plate holes
    color([0.8, 0.8, 0.3, 1.0])  // gold color for pins
    for (i = [0 : ALIGN_PIN_COUNT - 1]) {
        a = i * (360 / ALIGN_PIN_COUNT);  // 0, 120, 240
        translate([ALIGN_PIN_R * cos(a), ALIGN_PIN_R * sin(a), -ALIGN_PIN_DEPTH])
            cylinder(d = ALIGN_PIN_DIA, h = ALIGN_PIN_DEPTH, $fn = 16);
    }
}
