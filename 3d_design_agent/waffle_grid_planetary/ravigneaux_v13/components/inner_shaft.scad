// ============================================================
// INNER SHAFT — Solid 10mm rod
// ============================================================

include <../params.scad>

module inner_shaft() {
    rotate([0, 0, ANG_SS])
    color(C_SHAFT)
    translate([0, 0, INNER_SHAFT_ZBOT])
    cylinder(d=INNER_SHAFT_D, h=INNER_SHAFT_ZTOP - INNER_SHAFT_ZBOT, $fn=32);
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) inner_shaft();
