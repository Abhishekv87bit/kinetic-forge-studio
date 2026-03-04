// ============================================================
// REFERENCE ASSEMBLY — Direct STL Import (Complete)
// ============================================================
// Imports ALL of FatigMaker's reference STLs into OpenSCAD.
// Parts pre-positioned from original Fusion 360 assembly.
//
// COMPLETE PARTS LIST (13 STL files):
//   shaft.stl               — main shaft (dia=10, h=88.2, Z=[-54.8, 33.5])
//   small_sun.stl           — Ss small sun gear+shaft (dia=33, h=75, Z=[-53, 22])
//   big_sun_0_5_backlash.stl — SL large sun gear+tube (dia=40, h=48, Z=[-38, 10])
//   long_pinion.stl         — Po outer planet x3 (dia=27, h=22, Z=[0, 22])
//   short_pinion.stl        — Pi inner planet x3 (dia=26, h=10, Z=[12, 22])
//   planetary_1.stl         — Carrier top half (dia=78, h=35.5, Z=[-9, 26.5])
//   planetary_2.stl         — Carrier bottom half (dia=78, h=20, Z=[-21.5, -1.5])
//   planetary_3.stl         — Planet sub-assembly/cage (dia=43, h=16, Z=[-5.5, 10.5])
//   ring_low_profile.stl    — Ring gear housing (dia=96, h=18, Z=[12, 30])
//   big_sun_ring.stl        — Thrust ring for big sun (dia=32, h=1.2, Z=[-1.4, -0.1])
//   small_sun_ring.stl      — Thrust ring for small sun (dia=24, h=1.9, Z=[10.1, 11.9])
//   small_washer.stl        — Washer x14 (dia=13, h=1.2, Z=[-1.3, -0.1])
//   clip.stl                — Retaining clip x7 (dia=14, h=1.2, Z=[-6.9, -5.6])
// ============================================================

$fn = 64;

// Path to reference STLs
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// ============================================================
// VISIBILITY TOGGLES
// ============================================================
SHOW_SHAFT          = true;
SHOW_SMALL_SUN      = true;
SHOW_BIG_SUN        = true;
SHOW_LONG_PINION    = true;
SHOW_SHORT_PINION   = true;
SHOW_CARRIER_1      = true;   // planetary_1 (top carrier half)
SHOW_CARRIER_2      = true;   // planetary_2 (bottom carrier half)
SHOW_CARRIER_3      = true;   // planetary_3 (sub-assembly/cage)
SHOW_RING           = true;
SHOW_BIG_SUN_RING   = true;   // thrust ring for big sun
SHOW_SMALL_SUN_RING = true;   // thrust ring for small sun
SHOW_WASHERS        = true;
SHOW_CLIPS          = true;

CROSS_SECTION       = false;
EXPLODE             = 0;       // [0:1:50] explode distance

// ============================================================
// COLORS
// ============================================================
C_SHAFT     = [0.75, 0.75, 0.78];   // silver
C_SS        = [0.15, 0.55, 0.30];   // green (small sun)
C_SL        = [0.76, 0.60, 0.22];   // gold (large sun)
C_PO        = [0.85, 0.25, 0.20];   // red (long/outer pinion)
C_PI        = [1.0,  0.85, 0.0];    // yellow (short/inner pinion)
C_CAR       = [0.55, 0.55, 0.58];   // grey (carrier)
C_CAR2      = [0.45, 0.45, 0.50];   // darker grey (carrier bottom)
C_CAR3      = [0.60, 0.60, 0.65];   // lighter grey (sub-assembly)
C_RING      = [0.25, 0.25, 0.28];   // dark (ring)
C_THRUST    = [0.85, 0.55, 0.20];   // orange (thrust rings)
C_WASHER    = [0.95, 0.80, 0.10];   // yellow-gold (washers)
C_CLIP      = [0.3, 0.3, 0.9];      // blue (clips)

// ============================================================
// ASSEMBLY
// ============================================================
module ref_assembly() {
    // --- SHAFT (through the center) ---
    if (SHOW_SHAFT)
        color(C_SHAFT)
        translate([0, 0, -EXPLODE*2])
        import(str(STL_DIR, "shaft.stl"), convexity=4);

    // --- SMALL SUN (Ss) — green, sits on shaft ---
    if (SHOW_SMALL_SUN)
        color(C_SS)
        translate([0, 0, -EXPLODE])
        import(str(STL_DIR, "small_sun.stl"), convexity=4);

    // --- BIG SUN (SL) — gold, wraps around Ss ---
    if (SHOW_BIG_SUN)
        color(C_SL)
        translate([0, 0, -EXPLODE*0.5])
        import(str(STL_DIR, "big_sun_0_5_backlash.stl"), convexity=4);

    // --- LONG PINION (Po) — red, outer planets x3 at 120° ---
    if (SHOW_LONG_PINION)
        color(C_PO)
        import(str(STL_DIR, "long_pinion.stl"), convexity=4);

    // --- SHORT PINION (Pi) — yellow, inner planets x3 at 120° ---
    if (SHOW_SHORT_PINION)
        color(C_PI)
        import(str(STL_DIR, "short_pinion.stl"), convexity=4);

    // --- CARRIER TOP HALF (planetary_1) — grey ---
    if (SHOW_CARRIER_1)
        color(C_CAR)
        translate([0, 0, EXPLODE*0.5])
        import(str(STL_DIR, "planetary_1.stl"), convexity=4);

    // --- CARRIER BOTTOM HALF (planetary_2) — darker grey ---
    if (SHOW_CARRIER_2)
        color(C_CAR2)
        translate([0, 0, -EXPLODE*0.5])
        import(str(STL_DIR, "planetary_2.stl"), convexity=4);

    // --- PLANET SUB-ASSEMBLY/CAGE (planetary_3) ---
    if (SHOW_CARRIER_3)
        color(C_CAR3)
        import(str(STL_DIR, "planetary_3.stl"), convexity=4);

    // --- RING GEAR HOUSING ---
    if (SHOW_RING)
        color(C_RING, 0.7)
        translate([0, 0, EXPLODE])
        import(str(STL_DIR, "ring_low_profile.stl"), convexity=4);

    // --- BIG SUN THRUST RING (dia=32, Z=[-1.4, -0.1]) ---
    if (SHOW_BIG_SUN_RING)
        color(C_THRUST)
        import(str(STL_DIR, "big_sun_ring.stl"), convexity=4);

    // --- SMALL SUN THRUST RING (dia=24, Z=[10.1, 11.9]) ---
    if (SHOW_SMALL_SUN_RING)
        color(C_THRUST, 0.8)
        import(str(STL_DIR, "small_sun_ring.stl"), convexity=4);

    // --- WASHERS x14 (dia=13, Z=[-1.3, -0.1]) ---
    if (SHOW_WASHERS)
        color(C_WASHER)
        import(str(STL_DIR, "small_washer.stl"), convexity=4);

    // --- CLIPS x7 (dia=14, Z=[-6.9, -5.6]) ---
    if (SHOW_CLIPS)
        color(C_CLIP)
        import(str(STL_DIR, "clip.stl"), convexity=4);
}

// ============================================================
// MAIN
// ============================================================
if (CROSS_SECTION) {
    difference() {
        ref_assembly();
        translate([-200, 0, -200]) cube([400, 200, 400]);
    }
} else {
    ref_assembly();
}
