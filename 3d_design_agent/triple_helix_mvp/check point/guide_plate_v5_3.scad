// =========================================================
// GUIDE PLATE V5.3 — Hex Dampener Plates (Monolithic Matrix)
// =========================================================
// Two parallel hex plates below Tier 3.
// Captures angled strings via funnel bushings, constrains to vertical.
//
// Same hex shape as matrix tiers (HEX_R=89). No bolt flanges --
// frame posts pass through edge notches at hex vertices.
// Alignment pin holes register hex rotation before clamping.
//
// V5.2 changes from V5:
//   - Alignment pin holes (3 x 3.2mm clearance) for hex registration
//   - Monolithic matrix (zero-gap print-in-place) compatibility
//   - config_v5_3.scad (true 75% scale parameters)
//
// Assembly order (top-down):
//   Upper plate (GP1): 3mm thick, funnel bushings
//   15mm spacer gap
//   Lower plate (GP2): 5mm thick, vertical bores
// =========================================================

include <config_v5_3.scad>

$fn = 40;

// =============================================
// LOCAL PARAMETERS
// =============================================
BUSHING_GP_OD         = 5.0;
BUSHING_GP_FLANGE_OD  = 7.0;

/* [Visibility] */
SHOW_UPPER    = true;
SHOW_LOWER    = true;
SHOW_BUSHINGS = true;

// =============================================
// COLORS
// =============================================
C_GUIDE   = [0.6, 0.85, 0.6, 0.8];
C_BUSHING_GP = [0.85, 0.85, 0.8, 1.0];

// =============================================
// STANDALONE RENDER
// =============================================
guide_plate_assembly_v5_3();

// =============================================
// VERIFICATION
// =============================================
function _gp_sum(arr, i=0) = (i >= len(arr)) ? 0 : arr[i] + _gp_sum(arr, i+1);

_col_counts_gp = [for (i = [0:NUM_CHANNELS-1])
    let(d = CH_OFFSETS[i], clen = CH_LENS[i], raw = raw_col_count(clen))
    clen <= 0 ? 0 :
    len([for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j, i), d)) 1])
];
_total_bushings = _gp_sum(_col_counts_gp);

echo(str("=== GUIDE PLATE V5.3 ==="));
echo(str("HEX_R=", HEX_R, "mm | Channels=", NUM_CHANNELS));
echo(str("Bushings per plate: ", _total_bushings));
echo(str("GP1=", GP1_THICK, "mm | Gap=", GUIDE_PLATE_GAP, "mm | GP2=", GP2_THICK, "mm"));
echo(str("Total assembly height: ", GP1_THICK + GUIDE_PLATE_GAP + GP2_THICK, "mm"));
echo(str("Post notches: 6 x ", POST_DIA, "mm at hex vertices"));
echo(str("Alignment pin holes: ", ALIGN_PIN_COUNT, " x ", ALIGN_PIN_HOLE, "mm at R=", ALIGN_PIN_R, "mm"));


// =========================================================
// GUIDE PLATE ASSEMBLY
// =========================================================
module guide_plate_assembly_v5_3() {

    if (SHOW_UPPER)
        _guide_plate_body(GP1_THICK);

    if (SHOW_LOWER)
        translate([0, 0, -GP1_THICK - GUIDE_PLATE_GAP - GP2_THICK])
            _guide_plate_body(GP2_THICK);

    if (SHOW_BUSHINGS) {
        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j, i);
                    if (col_inside_hex(px, d)) {
                        bx = px;
                        by = -d;
                        translate([bx, by, -0.5])
                            ptfe_bushing_v5(GP1_THICK);
                        translate([bx, by, -GP1_THICK - GUIDE_PLATE_GAP - GP2_THICK - 0.5])
                            ptfe_bushing_v5(GP2_THICK);
                    }
                }
            }
        }
    }
}


// =========================================================
// GUIDE PLATE BODY
// =========================================================
module _guide_plate_body(thick) {

    color(C_GUIDE)
    difference() {
        cylinder(r = HEX_R, h = thick, $fn = 6);

        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j, i);
                    if (col_inside_hex(px, d)) {
                        translate([px, -d, -1])
                            cylinder(d = GUIDE_FUNNEL_DIA + 0.2, h = thick + 2, $fn = 16);
                        translate([px, -d, thick - 0.3])
                            cylinder(h = 0.5, d1 = GUIDE_FUNNEL_DIA + 0.2,
                                     d2 = GUIDE_FUNNEL_DIA + 3, $fn = 16);
                    }
                }
            }
        }

        // Post notches at hex vertices
        for (i = [0 : 5]) {
            a = i * 60;
            translate([HEX_R * cos(a), HEX_R * sin(a), -1])
                cylinder(d = POST_DIA, h = thick + 2, $fn = 12);
        }

        // Alignment pin holes (clearance fit)
        for (i = [0 : ALIGN_PIN_COUNT - 1]) {
            a = i * (360 / ALIGN_PIN_COUNT);  // 0, 120, 240
            translate([ALIGN_PIN_R * cos(a), ALIGN_PIN_R * sin(a), -1])
                cylinder(d = ALIGN_PIN_HOLE, h = thick + 2, $fn = 16);
        }
    }
}


// =========================================================
// PTFE BUSHING
// =========================================================
module ptfe_bushing_v5(plate_thick = 3.0) {
    color(C_BUSHING_GP)
    difference() {
        union() {
            cylinder(h = plate_thick + 1, d = BUSHING_GP_OD, $fn = 16);
            translate([0, 0, plate_thick + 1])
                cylinder(h = 0.5, d1 = BUSHING_GP_OD, d2 = BUSHING_GP_FLANGE_OD, $fn = 16);
            cylinder(h = 0.5, d = BUSHING_GP_FLANGE_OD, $fn = 16);
        }

        translate([0, 0, -1])
            cylinder(h = plate_thick + 4, d = GUIDE_BUSHING_BORE, $fn = 12);

        translate([0, 0, plate_thick])
            cylinder(h = 2, d1 = GUIDE_BUSHING_BORE, d2 = BUSHING_GP_OD - 0.5, $fn = 16);
    }
}
