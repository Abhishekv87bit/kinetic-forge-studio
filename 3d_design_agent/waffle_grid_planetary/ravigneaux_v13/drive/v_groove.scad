// ============================================================
// V-GROOVE — Rope groove on ring OD
// ============================================================

include <../params.scad>

module v_groove() {
    rotate([0, 0, ANG_RING]) {
        color(C_RING, 0.9)
        zcyl_hollow(RING_OD + 0.1, RING_OD - 0.1, GROOVE_Z - GROOVE_WIDTH / 2, GROOVE_WIDTH);

        color(C_GROOVE, 0.8)
        translate([0, 0, GROOVE_Z])
        rotate_extrude(convexity=4)
        translate([RING_OD / 2 - GROOVE_DEPTH * 0.3, 0, 0])
        circle(d=GROOVE_WIDTH * 0.5);
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) v_groove();
