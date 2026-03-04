// =========================================================
// ANCHOR PLATE V5.5 — Plain Hex String Tie-Off Plate
// =========================================================
// V5.5 CHANGES:
//   Bayonet L-slots REMOVED. Hex shape fits into upper ring sleeve.
//   Rotation locked by hex-on-hex geometry (plate hex in ring hex bore).
//   Z retention: friction fit + CA glue.
//   Plate sized with SLEEVE_CLEARANCE for snug fit in ring bore.
//
// Assembly: drops in from above through open upper ring,
// sits on top of matrix stack. CA glue to secure.
//
// All string hole positions unchanged from V5.4.
// =========================================================

include <config_v5_5.scad>

$fn = 40;

// =============================================
// COLORS
// =============================================
C_ANCHOR = [0.6, 0.6, 0.7, 0.8];

// =============================================
// STANDALONE RENDER
// =============================================
anchor_plate_v5_5();

// =============================================
// VERIFICATION
// =============================================
function _ap_sum(arr, i=0) = (i >= len(arr)) ? 0 : arr[i] + _ap_sum(arr, i+1);

_col_counts_ap = [for (i = [0:NUM_CHANNELS-1])
    let(d = CH_OFFSETS[i], clen = CH_LENS[i], raw = raw_col_count(clen))
    clen <= 0 ? 0 :
    len([for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, i), d)) 1])
];
_total_holes_ap = _ap_sum(_col_counts_ap);

echo(str("=== ANCHOR PLATE V5.5 (HEX SLEEVE FIT) ==="));
echo(str("HEX_R=", HEX_R, "mm | Plate R=", PLATE_HEX_R, "mm | Clearance=", SLEEVE_CLEARANCE, "mm"));
echo(str("Channels=", NUM_CHANNELS, " | String holes: ", _total_holes_ap));
echo(str("Plate: ", round(PLATE_HEX_R*2*10)/10, "mm C2C x ", ANCHOR_THICK, "mm thick"));
echo(str("Rotation locked by hex sleeve. Z: friction + CA glue."));


// =========================================================
// ANCHOR PLATE MODULE — plain hex, no bayonet
// =========================================================
module anchor_plate_v5_5() {

    color(C_ANCHOR)
    difference() {
        // Main hex plate body — sized for sleeve fit
        cylinder(r = PLATE_HEX_R, h = ANCHOR_THICK, $fn = 6);

        // String holes (count computed from 9-channel layout)
        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j, i);
                    if (col_inside_hex(px, d)) {
                        // Through hole for string
                        translate([px, -d, -1])
                            cylinder(d = STRING_HOLE_DIA, h = ANCHOR_THICK + 2, $fn = 12);
                        // Retainer countersink on top
                        translate([px, -d, ANCHOR_THICK - RETAINER_DEPTH])
                            cylinder(d = RETAINER_DIA, h = RETAINER_DEPTH + 1, $fn = 16);
                    }
                }
            }
        }

        // Post notches at stub vertices [0, 120, 240]
        for (si = [0 : FRAME_POST_COUNT - 1]) {
            a = FRAME_POST_ANGLES[si];
            translate([POST_NOTCH_R * cos(a), POST_NOTCH_R * sin(a), -1])
                cylinder(d = POST_DIA + 0.3, h = ANCHOR_THICK + 2, $fn = 12);
        }
    }
}
