// =========================================================
// GUIDE PLATE V3 — Hex Dampener Plates (Frame-Clamped)
// =========================================================
// Two parallel hex plates below Tier 3, sandwiched tightly.
// Captures angled strings via funnel bushings, constrains to vertical.
//
// Same hex shape as matrix tiers (HEX_R=118). No bolt flanges —
// frame posts pass through edge notches at hex vertices.
// Frame compression clamps the entire stack.
//
// Assembly order (top-down):
//   Upper plate (GP1): 3mm thick, funnel bushings
//   15mm spacer gap
//   Lower plate (GP2): 5mm thick, vertical bores
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
GP1_THICK         = 3.0;       // upper guide plate (clearance holes only)
GP2_THICK         = 5.0;       // lower guide plate (nut pocket needs depth)
GUIDE_PLATE_GAP   = 15.0;     // gap between upper and lower plates

// Bushing dimensions
GUIDE_BUSHING_BORE = 2.0;     // string passage diameter
GUIDE_FUNNEL_DIA   = 5.0;     // funnel entry diameter
BUSHING_OD         = 5.0;     // press-fit body OD
BUSHING_FLANGE_OD  = 7.0;     // flange OD

// =============================================
// FRAME POST NOTCHES
// =============================================
POST_DIA          = 4.5;      // M4 post clearance (4mm rod + 0.5mm gap)

/* [Visibility] */
SHOW_UPPER    = true;
SHOW_LOWER    = true;
SHOW_BUSHINGS = true;

// =============================================
// COLORS
// =============================================
C_GUIDE   = [0.6, 0.85, 0.6, 0.8];
C_BUSHING = [0.85, 0.85, 0.8, 1.0];

// =============================================
// STANDALONE RENDER
// =============================================
guide_plate_assembly_v3();

// =============================================
// VERIFICATION
// =============================================
function _sum(arr, i=0) = (i >= len(arr)) ? 0 : arr[i] + _sum(arr, i+1);

_col_counts = [for (i = [0:NUM_CHANNELS-1])
    let(d = CH_OFFSETS[i], clen = CH_LENS[i], raw = raw_col_count(clen))
    clen <= 0 ? 0 :
    len([for (j = [0:max(0, raw-1)]) if (col_inside_hex(col_x(raw, j), d)) 1])
];
_total_bushings = _sum(_col_counts);

echo(str("=== GUIDE PLATE V3 ==="));
echo(str("HEX_R=", HEX_R, "mm | Channels=", NUM_CHANNELS));
echo(str("Bushings per plate: ", _total_bushings));
echo(str("GP1=", GP1_THICK, "mm | Gap=", GUIDE_PLATE_GAP, "mm | GP2=", GP2_THICK, "mm"));
echo(str("Total assembly height: ", GP1_THICK + GUIDE_PLATE_GAP + GP2_THICK, "mm"));
echo(str("Post notches: 6 × ", POST_DIA, "mm at hex vertices"));


// =========================================================
// GUIDE PLATE ASSEMBLY — Both plates + spacers
// =========================================================
module guide_plate_assembly_v3() {

    // Upper plate (GP1) — at Z=0 (top face up), 3mm thick
    if (SHOW_UPPER)
        _guide_plate_body(GP1_THICK);

    // Lower plate (GP2) — thicker
    if (SHOW_LOWER)
        translate([0, 0, -GP1_THICK - GUIDE_PLATE_GAP - GP2_THICK])
            _guide_plate_body(GP2_THICK);

    // (No spacer sleeves — frame posts handle alignment externally)

    // PTFE bushing visualization
    if (SHOW_BUSHINGS) {
        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j);
                    if (col_inside_hex(px, d)) {
                        bx = px;
                        by = -d;
                        // Upper bushing (funnel on top)
                        translate([bx, by, -0.5])
                            ptfe_bushing_v3(GP1_THICK);
                        // Lower bushing
                        translate([bx, by, -GP1_THICK - GUIDE_PLATE_GAP - GP2_THICK - 0.5])
                            ptfe_bushing_v3(GP2_THICK);
                    }
                }
            }
        }
    }
}


// =========================================================
// GUIDE PLATE BODY — hex plate + bushing holes + post notches
// =========================================================
// thick: plate thickness (GP1=3mm, GP2=5mm)
module _guide_plate_body(thick) {

    color(C_GUIDE)
    difference() {
        // Hex plate body
        cylinder(r = HEX_R, h = thick, $fn = 6);

        // Bushing holes at every culled column position
        for (i = [0 : NUM_CHANNELS - 1]) {
            d = CH_OFFSETS[i];
            clen = CH_LENS[i];
            raw = raw_col_count(clen);

            if (clen > 0) {
                for (j = [0 : max(0, raw - 1)]) {
                    px = col_x(raw, j);
                    if (col_inside_hex(px, d)) {
                        translate([px, -d, -1]) {
                            // Through-bore for bushing press-fit
                            cylinder(d = GUIDE_FUNNEL_DIA + 0.2, h = thick + 2, $fn = 16);
                        }
                        // Funnel chamfer on top (entry side)
                        translate([px, -d, thick - 0.3])
                            cylinder(h = 0.5, d1 = GUIDE_FUNNEL_DIA + 0.2,
                                     d2 = GUIDE_FUNNEL_DIA + 3, $fn = 16);
                    }
                }
            }
        }

        // 6 semicircular post notches at hex vertices
        for (i = [0 : 5]) {
            a = i * 60;
            translate([HEX_R * cos(a), HEX_R * sin(a), -1])
                cylinder(d = POST_DIA, h = thick + 2, $fn = 12);
        }
    }
}



// =========================================================
// PTFE BUSHING — Flanged Grommet
// =========================================================
module ptfe_bushing_v3(plate_thick = 3.0) {
    color(C_BUSHING)
    difference() {
        union() {
            // Body
            cylinder(h = plate_thick + 1, d = BUSHING_OD, $fn = 16);
            // Top flange (funnel shape)
            translate([0, 0, plate_thick + 1])
                cylinder(h = 0.5, d1 = BUSHING_OD, d2 = BUSHING_FLANGE_OD, $fn = 16);
            // Bottom flange
            cylinder(h = 0.5, d = BUSHING_FLANGE_OD, $fn = 16);
        }

        // Through-bore
        translate([0, 0, -1])
            cylinder(h = plate_thick + 4, d = GUIDE_BUSHING_BORE, $fn = 12);

        // Funnel taper at top
        translate([0, 0, plate_thick])
            cylinder(h = 2, d1 = GUIDE_BUSHING_BORE, d2 = BUSHING_OD - 0.5, $fn = 16);
    }
}
