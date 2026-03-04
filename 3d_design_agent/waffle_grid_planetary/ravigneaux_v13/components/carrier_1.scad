// ============================================================
// CARRIER_1 — Top plate + hub + 6 pin stubs
// ============================================================

include <../params.scad>

module carrier_1() {
    rotate([0, 0, ANG_CARRIER]) {
        color(C_CAR)
        difference() {
            union() {
                // Main plate (Z=22 to 26.5)
                zcyl(CARRIER1_OD, CARRIER1_HC_ZBOT, CARRIER1_HC_H);

                // Central hub (extends above plate)
                zcyl(CARRIER1_BOSS_OD, CARRIER1_ZTOP, CARRIER1_HUB_H);

                // Pin stubs on underside — Po positions (3x)
                for (i = [0:2])
                    rotate([0, 0, i * 120])
                    translate([PO_ORBIT, 0, 0])
                    zcyl(CARRIER1_PIN_STUB_D,
                         CARRIER1_HC_ZBOT - CARRIER1_PIN_STUB_H,
                         CARRIER1_PIN_STUB_H);

                // Pin stubs on underside — Pi positions (3x)
                for (i = [0:2])
                    rotate([0, 0, i * 120 + PI_ANG_OFFSET])
                    translate([PI_ORBIT_ACTUAL, 0, 0])
                    zcyl(CARRIER1_PIN_STUB_D,
                         CARRIER1_HC_ZBOT - CARRIER1_PIN_STUB_H,
                         CARRIER1_PIN_STUB_H);
            }

            // Central bore (clears SL shaft + gap)
            translate([0, 0, CARRIER1_HC_ZBOT - CARRIER1_PIN_STUB_H - 0.1])
            cylinder(d=CARRIER1_BORE,
                     h=CARRIER1_HC_H + CARRIER1_HUB_H + CARRIER1_PIN_STUB_H + 0.2,
                     $fn=64);
        }
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) carrier_1();
