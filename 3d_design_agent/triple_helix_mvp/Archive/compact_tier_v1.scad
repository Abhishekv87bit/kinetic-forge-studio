// =========================================================
// COMPACT TIER V1 — Thin V5 Prototype
// =========================================================
// Exact V5 layout (5 channels, 3+4+5+4+3 = 19 eyelets).
// Pulleys → eyelets. Guide rails → axle pins.
// Hex plates top & bottom. Central shaft hole for load wire.
// 3 tiers stacked at 0°/120°/240° rotation.
// =========================================================

$fn = 36;

/* [Display] */
NUM_TIERS       = 3;       // [1:1:3]
TIER_GAP        = 1.0;     // [0:0.5:20]
SHOW_WALLS      = true;
SHOW_SLIDERS    = true;
SHOW_AXLES      = true;
SHOW_PLATES     = true;
EXPLODE         = 0;       // [0:1:50]

/* [Animation] */
MANUAL_POS      = -1;      // [-1:0.01:1]
function anim_t() = (MANUAL_POS >= 0) ? MANUAL_POS : $t;

// =============================================
// V5 REFERENCE VALUES
// =============================================

CH_LENS     = [83, 111, 136, 112, 83];   // channel housing lengths (mm)
FP_COUNTS   = [3, 4, 5, 4, 3];           // eyelets per channel (19 total)
FP_PITCH    = 29.0;                       // eyelet spacing (mm)
SP_COUNTS   = [3, 4, 5, 4, 3];           // slider eyelets per channel
SP_PITCH    = 46.0;                       // slider eyelet spacing (mm)

// =============================================
// THIN DIMENSIONS
// =============================================

WALL_T          = 1.5;     // wall thickness (Z direction, was 3mm)
CH_GAP          = 3.0;     // channel internal Z height (was 19mm)
SLIDER_T        = 1.5;     // slider strip Y thickness
PLATE_T         = 1.0;     // hex plate Z thickness
AXLE_DIA        = 2.0;     // guide pin diameter
AXLE_CLEAR      = 0.3;     // slider slot clearance
EYELET_DIA      = 1.5;     // rope hole in slider
ROPE_HOLE_DIA   = 2.0;     // rope hole in plates
ECCENTRICITY    = 3.0;     // ±3mm slider travel
SHAFT_HOLE_DIA  = 3.0;     // central hole for load wire

// =============================================
// DERIVED GEOMETRY
// =============================================

// Channel stacking (Z direction)
STACK_OFF   = CH_GAP + WALL_T;                     // 4.5mm between channel centers
CH_Z        = [for (i = [0:4]) (i - 2) * STACK_OFF]; // [-9, -4.5, 0, 4.5, 9]

// Tier envelope
TIER_INNER  = 4 * STACK_OFF + CH_GAP;              // 21mm (wall-to-wall span)
TIER_H      = TIER_INNER + 2 * PLATE_T;            // 23mm total
TIER_P      = TIER_H + TIER_GAP;                   // 24mm pitch
STACK_H     = NUM_TIERS * TIER_H + (NUM_TIERS - 1) * TIER_GAP;

// Hex boundary — fits longest channel + margin
HEX_FTF     = CH_LENS[2] + 10;                     // 146mm
HEX_R       = HEX_FTF / (2 * cos(30));

// Cam phases
CAM_PHASE   = 72;                                   // 360/5 = 72° per channel

// =============================================
// COLORS
// =============================================

C_PLATE = [0.65, 0.65, 1.0, 0.3];
C_TIER  = [[1,0.25,0.25,0.85], [0.25,0.75,0.25,0.85], [0.25,0.45,1,0.85]];
C_SLIDE = [[0.95,0.55,0.2,0.85], [0.95,0.75,0.2,0.85], [0.85,0.4,0.7,0.85],
            [0.5,0.9,0.5,0.85], [0.9,0.5,0.9,0.85]];

// =============================================
// ECHO
// =============================================

echo(str("=== COMPACT TIER v1 ==="));
echo(str("Hex FTF=", HEX_FTF, "  Tier H=", TIER_H, "  Stack=", round(STACK_H*10)/10));
for (i = [0:4])
    echo(str("  CH", i+1, ": Z=", CH_Z[i], " len=", CH_LENS[i], " eyes=", FP_COUNTS[i]));

// =============================================
// MAIN
// =============================================

triple_stack();

module triple_stack() {
    t = anim_t();
    for (tier = [0:NUM_TIERS-1])
        translate([0, 0, -tier * TIER_P + tier * EXPLODE])
            rotate([0, 0, tier * 120])
                one_tier(tier, t);
    %color("red") cylinder(d=0.5, h=STACK_H+20, center=true, $fn=6);
}

// Flat-top hex: flat edges at top/bottom, parallel to walls (X direction)
module hex2d(r) { rotate([0,0,30]) circle(r=r, $fn=6); }

// =============================================
// ONE TIER
// =============================================

module one_tier(ti, t) {

    // --- HEX PLATES ---
    if (SHOW_PLATES)
        for (s = [-1, 1]) {
            pz = s * (TIER_INNER/2 + PLATE_T/2);
            color(C_PLATE)
            difference() {
                translate([0, 0, pz])
                    linear_extrude(PLATE_T, center=true) hex2d(HEX_R);
                // Rope holes at each eyelet X position, at each channel's Y=0
                // (plates are flat in XY, holes go through Z)
                for (ch = [0:4])
                    for (i = [0:FP_COUNTS[ch]-1]) {
                        ex = (i - (FP_COUNTS[ch]-1)/2) * FP_PITCH;
                        translate([ex, 0, pz])
                            cylinder(d=ROPE_HOLE_DIA, h=PLATE_T+1, center=true, $fn=12);
                    }
                // Central shaft hole
                translate([0, 0, pz])
                    cylinder(d=SHAFT_HOLE_DIA, h=PLATE_T+1, center=true, $fn=16);
            }
        }

    // --- WALLS ---
    // 6 walls (below CH1, between CH1-2, CH2-3, CH3-4, CH4-5, above CH5)
    // Each wall: slab in XY, thin in Z, clipped to hex
    if (SHOW_WALLS)
        for (w = [0:5]) {
            wz = (w == 0) ? CH_Z[0] - CH_GAP/2 - WALL_T/2 :
                 (w == 5) ? CH_Z[4] + CH_GAP/2 + WALL_T/2 :
                 (CH_Z[w-1] + CH_Z[w]) / 2;
            wlen = (w == 0) ? CH_LENS[0] :
                   (w == 5) ? CH_LENS[4] :
                   max(CH_LENS[w-1], CH_LENS[w]);

            color(C_TIER[ti])
            difference() {
                intersection() {
                    translate([0, 0, wz])
                        cube([wlen+4, HEX_FTF, WALL_T], center=true);
                    linear_extrude(TIER_INNER+2, center=true) hex2d(HEX_R);
                }
                // Central shaft hole
                translate([0, 0, wz])
                    cylinder(d=SHAFT_HOLE_DIA, h=WALL_T+1, center=true, $fn=16);
            }
        }

    // --- SLIDERS ---
    // One strip per channel, slides along X, guided by axle pins
    if (SHOW_SLIDERS)
        for (ch = [0:4]) {
            disp = ECCENTRICITY * sin(t * 360 + ch * CAM_PHASE);
            color(C_SLIDE[ch])
            translate([disp, 0, CH_Z[ch]])
                slider_strip(ch);
        }

    // --- AXLE PINS ---
    // Two per channel, near ends, spanning wall-to-wall in Z
    if (SHOW_AXLES)
        for (ch = [0:4])
            for (s = [-1, 1]) {
                ax = s * (CH_LENS[ch]/2 - 5);
                color([0.5,0.5,0.5,0.8])
                translate([ax, 0, CH_Z[ch]])
                    cylinder(d=AXLE_DIA, h=CH_GAP+WALL_T*2, center=true, $fn=12);
            }
}

// =============================================
// SLIDER STRIP
// =============================================

module slider_strip(ch) {
    slen = CH_LENS[ch] - 4;
    sh   = CH_GAP - 0.6;     // Z height, fits inside channel gap

    difference() {
        cube([slen, SLIDER_T, sh], center=true);

        // Eyelets — rope goes through Z
        for (i = [0:SP_COUNTS[ch]-1]) {
            ex = (i - (SP_COUNTS[ch]-1)/2) * SP_PITCH;
            translate([ex, 0, 0])
                cylinder(d=EYELET_DIA, h=sh+1, center=true, $fn=12);
        }

        // Axle slots — elongated in X for ±travel
        for (s = [-1, 1]) {
            ax = s * (CH_LENS[ch]/2 - 5);
            hull() {
                translate([ax - ECCENTRICITY, 0, 0])
                    cylinder(d=AXLE_DIA+2*AXLE_CLEAR, h=sh+1, center=true, $fn=12);
                translate([ax + ECCENTRICITY, 0, 0])
                    cylinder(d=AXLE_DIA+2*AXLE_CLEAR, h=sh+1, center=true, $fn=12);
            }
        }
    }
}
