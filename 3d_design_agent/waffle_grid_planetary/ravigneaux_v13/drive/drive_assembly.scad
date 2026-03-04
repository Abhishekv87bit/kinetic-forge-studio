// ============================================================
// DRIVE ASSEMBLY — Stage 2 horizontal shafts + helical pinions
// ============================================================

include <../params.scad>
use <../gear_math/gear_primitives_3d.scad>

// --- Drive pinion module ---
module drive_pinion(ang, drv_z, gear_teeth, gear_fw, cd, shaft_color, gear_color) {
    rotate([0, 0, ang])
    translate([cd, 0, drv_z])
    rotate([0, 90, 0]) {
        // Drive shaft (horizontal steel rod)
        color(shaft_color)
        translate([0, 0, -DRV_SHAFT_LEN/2])
        cylinder(d=DRV_SHAFT_D, h=DRV_SHAFT_LEN, $fn=32);

        // Helical drive gear (bored for shaft)
        color(gear_color, 0.85)
        difference() {
            translate([0, 0, -gear_fw/2])
            helical_gear(teeth=gear_teeth, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=gear_fw);
            translate([0, 0, -gear_fw/2 - 0.1])
            cylinder(d=DRV_SHAFT_D + 0.4, h=gear_fw + 0.2, $fn=32);
        }
    }
}

module drive_assembly() {
    drive_pinion(DRV_SS_ANG, DRV_SS_Z, T_DRV_SS,
                 DRV_SS_FW, CD_SS_DRV, C_DRV_SHAFT, C_DRV_SS);
    drive_pinion(DRV_SL_ANG, DRV_SL_Z, T_DRV_SL,
                 DRV_SL_FW, CD_SL_DRV, C_DRV_SHAFT, C_DRV_SL);
    drive_pinion(DRV_CAR_ANG, DRV_CAR_Z, T_DRV_CAR,
                 DRV_CAR_FW, CD_CAR_DRV, C_DRV_SHAFT, C_DRV_CAR);
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) drive_assembly();
