// ============================================================
// PLANET ASSEMBLY — Po x3 + Pi x3 with self-rotation
// ============================================================

include <../params.scad>
use <../gear_math/gear_primitives_3d.scad>

module planet_assembly() {
    for (i = [0:2]) {
        ang = i * 120;

        // Long pinion (Po) — orbits with carrier, self-rotates on pin
        if (SHOW_LONG_PINION)
        color(C_PO)
        rotate([0, 0, ANG_CARRIER + ang])
        translate([PO_ORBIT, 0, 0])
        rotate([0, 0, ANG_PO_SELF])
        translate([0, 0, PO_ZBOT])
        planet_gear(teeth=T_PO, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=PO_ZTOP - PO_ZBOT,
            bore_d=PIN_BORE_D);

        // Short pinion (Pi) — orbits with carrier, self-rotates on pin
        if (SHOW_SHORT_PINION)
        color(C_PI)
        rotate([0, 0, ANG_CARRIER + ang + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, 0])
        rotate([0, 0, ANG_PI_SELF])
        translate([0, 0, PI_ZBOT])
        planet_gear(teeth=T_PI, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=PI_ZTOP - PI_ZBOT,
            bore_d=PIN_BORE_D);
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) planet_assembly();
