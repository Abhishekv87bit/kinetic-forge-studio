// ============================================================
// RAVIGNEAUX V13 — MAIN ASSEMBLY
// ============================================================
// One file per component, grouped by type.
// This file includes all components and composes full_assembly().
//
// Directory layout:
//   params.scad              — all shared constants, colors, animation
//   gear_math/
//     involute_math.scad     — _inv_polar() function
//     gear_profiles_2d.scad  — involute_gear_2d(), internal_gear_2d()
//     gear_primitives_3d.scad— helical_gear(), helical_ring_gear(), planet_gear()
//   components/
//     ring_gear.scad         — new_ring()
//     small_sun.scad         — ss_full_shaft()
//     big_sun.scad           — sl_full_shaft()
//     carrier_1.scad         — carrier_1()
//     carrier_2.scad         — carrier_full_shaft(), carrier_plate_2d()
//     carrier_3.scad         — carrier_3_sector(), carrier_3_assembly()
//     planets.scad           — planet_assembly()
//     inner_shaft.scad       — inner_shaft()
//   hardware/
//     splines.scad           — splined_tube(), splined_bore()
//     washers.scad           — thrust_washer(), washer_assembly()
//     clips.scad             — e_clip(), clip_assembly()
//   drive/
//     drive_assembly.scad    — drive_pinion(), drive_assembly()
//     bearings.scad          — bearings()
//     v_groove.scad          — v_groove()
//     anchor_shaft.scad      — anchor_shaft()
// ============================================================

include <params.scad>

// Components
use <components/ring_gear.scad>
use <components/small_sun.scad>
use <components/big_sun.scad>
use <components/carrier_1.scad>
use <components/carrier_2.scad>
use <components/carrier_3.scad>
use <components/planets.scad>
use <components/inner_shaft.scad>

// Hardware
use <hardware/washers.scad>
use <hardware/clips.scad>

// Drive / External
use <drive/drive_assembly.scad>
use <drive/bearings.scad>
use <drive/v_groove.scad>
use <drive/anchor_shaft.scad>

// ============================================================
// FULL ASSEMBLY
// ============================================================
module full_assembly() {
    // Concentric shafts (innermost to outermost)
    if (SHOW_SHAFT)       inner_shaft();
    if (SHOW_SMALL_SUN)   ss_full_shaft();
    if (SHOW_BIG_SUN)     sl_full_shaft();

    // Carrier system
    if (SHOW_CARRIER_2)   carrier_full_shaft();
    if (SHOW_CARRIER_1)   carrier_1();
    if (SHOW_CARRIER_3)   carrier_3_assembly();

    // Planet gears
    planet_assembly();

    // Ring enclosure
    if (SHOW_RING)        new_ring();

    // Hardware
    if (SHOW_WASHERS)     washer_assembly();
    if (SHOW_CLIPS)       clip_assembly();

    // External features
    if (SHOW_V_GROOVE)    v_groove();
    if (SHOW_BEARINGS)    bearings();
    if (SHOW_DRIVE)       drive_assembly();
    if (SHOW_ANCHOR)      anchor_shaft();
}

// ============================================================
// MAIN
// ============================================================
if (CROSS_SECTION) {
    difference() {
        rotate([180, 0, 0]) full_assembly();
        translate([-200, 0, -200]) cube([400, 200, 400]);
    }
} else {
    rotate([180, 0, 0]) full_assembly();
}

// ============================================================
// ECHO + ASSERTIONS
// ============================================================
echo("==============================================");
echo("  RAVIGNEAUX V13 — 100% PARAMETRIC (SPLIT)");
echo("==============================================");
echo(str("Ravigneaux check: ", T_SL, " + 2*", T_PO, " = ", T_SL + 2*T_PO,
         " (Ring=", T_RING, ") ", (T_SL + 2*T_PO == T_RING) ? "OK" : "FAIL"));
echo(str("Pitch radii — Ring:", PR_RING, " SL:", PR_SL, " Ss:", PR_SS,
         " Po:", PR_PO, " Pi:", PR_PI));
echo(str("Center dist — SL-Po:", CD_SL_PO, " (PO_ORBIT=", PO_ORBIT, ") ",
         abs(CD_SL_PO - PO_ORBIT) < 0.01 ? "OK" : "MISMATCH"));
echo(str("Center dist — Ss-Pi:", CD_SS_PI, " (PI_ORBIT=", PI_ORBIT_ACTUAL, ") ",
         "diff=", abs(CD_SS_PI - PI_ORBIT_ACTUAL)));
echo(str("Input SL:      ", DRIVE_SL_DEG, " deg/cycle → angle=", ANG_SL));
echo(str("Input Ss:      ", DRIVE_SS_DEG, " deg/cycle → angle=", ANG_SS));
echo(str("Input Carrier: ", DRIVE_CARRIER_DEG, " deg/cycle → angle=", ANG_CARRIER));
echo(str("OUTPUT Ring:   angle=", ANG_RING, " (ratio SL→Ring = ", -T_SL/T_RING, ")"));
echo(str("V-groove: Z=", GROOVE_Z));
echo("ANIMATION: Use View->Animate (FPS=10, Steps=100) OR drag MANUAL_SL/SS/CARRIER sliders");
