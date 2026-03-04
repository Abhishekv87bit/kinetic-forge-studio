// =========================================================
// GUIDE PLATE V5.5b — Single Hex Plate with Tapered Through-Holes
// =========================================================
// V5.5b CHANGES:
//   Replaces dual GP1+GP2 plates + 7mm gap + PTFE bushings.
//   Single 5mm hex plate with funnel-to-bore through-holes.
//   Funnel on top face captures angled strings.
//   Straight bore on bottom constrains to vertical.
//   No PTFE bushings — just printed holes.
//
//   Hex shape fits into lower ring sleeve.
//   Rotation locked by hex-on-hex geometry.
//   Z retention: rest on lower ring ledge, sandwiched by matrix above.
//   Plate sized with SLEEVE_CLEARANCE for snug fit in ring bore.
//
// Assembly: drops in from below through open lower ring sleeve,
//   sits on lower ring ledge. Matrix stack sits on top.
// =========================================================

include <config_v5_5.scad>

$fn = 40;

// =============================================
// LOCAL PARAMETERS
// =============================================
_BORE_CLEARANCE     = 0.2;                       // radial clearance on bore
_FUNNEL_MOUTH_EXTRA = 1.5;                       // funnel flare beyond bore dia
GUIDE_BORE_DIA     = GUIDE_FUNNEL_DIA + _BORE_CLEARANCE;    // 3.2mm straight bore (bottom)
GUIDE_FUNNEL_TOP   = GUIDE_FUNNEL_DIA + _FUNNEL_MOUTH_EXTRA; // 4.5mm funnel mouth (top)

/* [Visibility] */
SHOW_GUIDE    = true;

// =============================================
// COLORS
// =============================================
C_GUIDE      = [0.6, 0.85, 0.6, 0.8];

// =============================================
// STANDALONE RENDER
// =============================================
guide_plate_v5_5();

// =============================================
// VERIFICATION
// =============================================
function _gp_sum(arr, i=0) = (i >= len(arr)) ? 0 : arr[i] + _gp_sum(arr, i+1);

_col_counts_gp = [for (i = [0:NUM_CHANNELS-1])
    let(d = CH_OFFSETS[i], clen = CH_LENS[i], raw = raw_col_count(clen))
    clen <= 0 ? 0 :
    len([for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, i), d)) 1])
];
_total_holes_gp = _gp_sum(_col_counts_gp);

echo(str("=== GUIDE PLATE V5.5b (SINGLE PLATE — TAPERED HOLES) ==="));
echo(str("HEX_R=", HEX_R, "mm | Plate R=", PLATE_HEX_R, "mm | Clearance=", SLEEVE_CLEARANCE, "mm"));
echo(str("Channels=", NUM_CHANNELS, " | Through-holes: ", _total_holes_gp));
echo(str("Plate: ", round(PLATE_HEX_R*2*10)/10, "mm C2C x ", GUIDE_THICK, "mm thick"));
echo(str("Funnel: top=", GUIDE_FUNNEL_TOP, "mm → bore=", GUIDE_BORE_DIA, "mm, taper depth=", GUIDE_FUNNEL_TAPER, "mm"));
echo(str("Rotation locked by hex sleeve. Z: gravity + sandwiched by matrix."));


// =========================================================
// GUIDE PLATE MODULE — single hex plate, tapered through-holes
// =========================================================
module guide_plate_v5_5() {
    if (SHOW_GUIDE)
    color(C_GUIDE)
    difference() {
        // Main hex plate body — sized for sleeve fit
        cylinder(r = PLATE_HEX_R, h = GUIDE_THICK, $fn = 6);

        // Tapered through-holes: funnel on top, straight bore on bottom
        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j, i);
                    if (col_inside_hex(px, d)) {
                        // Straight bore: from bottom through most of plate
                        translate([px, -d, -1])
                            cylinder(d = GUIDE_BORE_DIA,
                                     h = GUIDE_THICK - GUIDE_FUNNEL_TAPER + 2,
                                     $fn = 16);
                        // Funnel taper: top portion of plate
                        translate([px, -d, GUIDE_THICK - GUIDE_FUNNEL_TAPER])
                            cylinder(h = GUIDE_FUNNEL_TAPER + 1,
                                     d1 = GUIDE_BORE_DIA,
                                     d2 = GUIDE_FUNNEL_TOP,
                                     $fn = 16);
                    }
                }
            }
        }

        // Post notches at stub vertices [0, 120, 240]
        for (si = [0 : FRAME_POST_COUNT - 1]) {
            a = FRAME_POST_ANGLES[si];
            translate([POST_NOTCH_R * cos(a), POST_NOTCH_R * sin(a), -1])
                cylinder(d = POST_DIA + 0.3, h = GUIDE_THICK + 2, $fn = 12);
        }
    }
}
