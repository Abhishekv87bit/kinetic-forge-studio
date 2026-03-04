// ============================================================
// CARRIER_3 — Pin cage (3 sectors, each with Po + Pi boss + web)
// ============================================================

include <../params.scad>

module carrier_3_sector(sector_ang) {
    // Po boss — full gearbox height Z=0 to 22
    rotate([0, 0, sector_ang])
    translate([PO_ORBIT, 0, PO_ZBOT])
    difference() {
        cylinder(d=CAGE_BOSS_OD, h=PO_ZTOP - PO_ZBOT, $fn=24);
        translate([0, 0, -0.1])
        cylinder(d=CAGE_BOSS_ID, h=PO_ZTOP - PO_ZBOT + 0.2, $fn=24);
    }

    // Pi boss — Z = PI_ZBOT-2 to PI_ZTOP (extends below Pi gear for support)
    // This boss passes through carrier_2's oversized Pi holes (D=13.4)
    PI_BOSS_ZBOT = PI_ZBOT - 2;
    rotate([0, 0, sector_ang + PI_ANG_OFFSET])
    translate([PI_ORBIT_ACTUAL, 0, PI_BOSS_ZBOT])
    difference() {
        cylinder(d=CAGE_BOSS_OD, h=PI_ZTOP - PI_BOSS_ZBOT, $fn=24);
        translate([0, 0, -0.1])
        cylinder(d=CAGE_BOSS_ID, h=PI_ZTOP - PI_BOSS_ZBOT + 0.2, $fn=24);
    }

    // Bridging web between Po and Pi bosses (structural strut)
    // Positioned at mid-height of Pi zone, connecting the two boss centers
    WEB_Z = (PI_ZBOT + PI_ZTOP) / 2 - CAGE_WEB_H / 2;
    po_x = PO_ORBIT * cos(sector_ang);
    po_y = PO_ORBIT * sin(sector_ang);
    pi_x = PI_ORBIT_ACTUAL * cos(sector_ang + PI_ANG_OFFSET);
    pi_y = PI_ORBIT_ACTUAL * sin(sector_ang + PI_ANG_OFFSET);

    bridge_len = sqrt((pi_x - po_x) * (pi_x - po_x) + (pi_y - po_y) * (pi_y - po_y));
    bridge_ang = atan2(pi_y - po_y, pi_x - po_x);

    translate([po_x, po_y, WEB_Z])
    rotate([0, 0, bridge_ang])
    translate([0, -CAGE_WEB_W/2, 0])
    cube([bridge_len, CAGE_WEB_W, CAGE_WEB_H]);
}

module carrier_3_assembly() {
    color(C_CAR3)
    rotate([0, 0, ANG_CARRIER])
    for (i = [0:2])
        carrier_3_sector(i * 120);
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) carrier_3_assembly();
