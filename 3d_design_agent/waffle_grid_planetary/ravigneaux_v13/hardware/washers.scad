// ============================================================
// WASHERS — Thrust washers + pin washers (W1-W9)
// ============================================================

include <../params.scad>

// --- Thrust washer (thin annular ring) ---
module thrust_washer(od, id, h) {
    zcyl_hollow(od, id, 0, h);
}

// --- Washer assembly (all parametric) ---
// W1: Ring top lid <-> Carrier_1 top       -> central thrust washer
// W2: Carrier_1 underside <-> Po gear top  -> pin washer x3
// W3: Carrier_1 underside <-> Pi gear top  -> pin washer x3
// W4: Pi gear bottom <-> Carrier_3 shelf   -> pin washer x3
// W5: SL top <-> interface                 -> big sun thrust ring
// W6: Ss top <-> SL inner bore             -> small sun thrust ring
// W7: Po gear bottom <-> Carrier_2 top     -> pin washer x3
// W8: SL bottom <-> Carrier_2              -> big sun thrust ring
// W9: Carrier_2 bottom <-> Ring bottom lid -> central thrust washer

module washer_assembly() {
    // W1: Central thrust washer at ring top lid <-> carrier_1 top
    color(C_THRUST)
    rotate([0, 0, ANG_CARRIER])
    translate([0, 0, CARRIER1_ZTOP + RING_GAP_TOP - THRUST_WASHER_H])
    thrust_washer(THRUST_WASHER_OD, THRUST_WASHER_ID, THRUST_WASHER_H);

    // W2: Pin washers x3 at Po gear top <-> carrier_1 underside
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120])
        translate([PO_ORBIT, 0, PO_ZTOP])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W3: Pin washers x3 at Pi gear top <-> carrier_1 underside
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120 + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, PI_ZTOP])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W4: Pin washers x3 at Pi gear bottom <-> carrier_3 shelf
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120 + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, PI_ZBOT - WASHER_H])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W5: Big sun thrust ring at SL top face
    color(C_THRUST)
    rotate([0, 0, ANG_SL])
    translate([0, 0, GEAR_ZONE_TOP])
    thrust_washer(BIG_SUN_RING_OD, BIG_SUN_RING_ID, BIG_SUN_RING_H);

    // W6: Small sun thrust ring at Ss top face
    color(C_THRUST)
    rotate([0, 0, ANG_SS])
    translate([0, 0, GEAR_ZONE_TOP])
    thrust_washer(SM_SUN_RING_OD, SM_SUN_RING_ID, SM_SUN_RING_H);

    // W7: Pin washers x3 at Po gear bottom <-> carrier_2 top
    for (i = [0:2])
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER + i * 120])
        translate([PO_ORBIT, 0, PO_ZBOT - WASHER_H])
        thrust_washer(WASHER_OD, WASHER_ID, WASHER_H);

    // W8: Big sun thrust ring at SL bottom <-> carrier_2 top
    color(C_THRUST)
    rotate([0, 0, ANG_SL])
    translate([0, 0, CAR_PLATE_ZTOP - BIG_SUN_RING_H])
    thrust_washer(BIG_SUN_RING_OD, BIG_SUN_RING_ID, BIG_SUN_RING_H);

    // W9: Central thrust washer at carrier_2 bottom <-> ring bottom lid
    color(C_THRUST)
    rotate([0, 0, ANG_CARRIER])
    translate([0, 0, CARRIER2_ZBOT - THRUST_WASHER_H])
    thrust_washer(THRUST_WASHER_OD, THRUST_WASHER_ID, THRUST_WASHER_H);
}

// ============================================================
// STANDALONE PREVIEW ($fn=24 for fast render)
// ============================================================
$fn = 24;
rotate([180, 0, 0]) washer_assembly();
