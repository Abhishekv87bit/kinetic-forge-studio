// ============================================================
// SMALL SUN (Ss) — 31T helical + splined shaft tube
// ============================================================

include <../params.scad>
use <../gear_math/gear_primitives_3d.scad>
use <../hardware/splines.scad>

module ss_full_shaft() {
    rotate([0, 0, ANG_SS]) {
        // Splined shaft tube (extension bottom to gearbox top)
        color(C_SS)
        translate([0, 0, SS_EXT_ZBOT])
        splined_tube(od=SS_EXT_OD, id=SS_EXT_ID,
            h=GEAR_ZONE_TOP - SS_EXT_ZBOT);

        // Sun gear teeth inside gearbox (Ss = 31T, Z=0 to 22)
        color(C_SS)
        difference() {
            translate([0, 0, GEAR_ZONE_BOT])
            helical_gear(teeth=T_SS, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            translate([0, 0, GEAR_ZONE_BOT - 0.1])
            cylinder(d=SS_EXT_ID, h=GEAR_ZONE_TOP - GEAR_ZONE_BOT + 0.2, $fn=64);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_SS)
        difference() {
            translate([0, 0, SS_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_SS, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=GEAR_FW);
            translate([0, 0, SS_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=SS_EXT_OD, h=GEAR_FW);
        }
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) ss_full_shaft();
