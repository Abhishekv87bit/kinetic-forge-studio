// ============================================================
// BIG SUN (SL) — 38T helical + splined shaft tube
// ============================================================

include <../params.scad>
use <../gear_math/gear_primitives_3d.scad>
use <../hardware/splines.scad>

module sl_full_shaft() {
    rotate([0, 0, ANG_SL]) {
        // Splined shaft tube (extension bottom to gearbox top)
        color(C_SL)
        translate([0, 0, SL_EXT_ZBOT])
        splined_tube(od=SL_EXT_OD, id=SL_EXT_ID,
            h=GEAR_ZONE_TOP - SL_EXT_ZBOT);

        // Sun gear teeth inside gearbox (SL = 38T, Z=0 to 22)
        color(C_SL)
        difference() {
            translate([0, 0, GEAR_ZONE_BOT])
            helical_gear(teeth=T_SL, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            translate([0, 0, GEAR_ZONE_BOT - 0.1])
            cylinder(d=SL_EXT_ID, h=GEAR_ZONE_TOP - GEAR_ZONE_BOT + 0.2, $fn=64);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_SL)
        difference() {
            translate([0, 0, SL_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_SL, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_FW);
            translate([0, 0, SL_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=SL_EXT_OD, h=GEAR_FW);
        }
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) sl_full_shaft();
