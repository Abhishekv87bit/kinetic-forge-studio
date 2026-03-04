// ============================================================
// RING GEAR — Internal helical teeth + walls + lids
// ============================================================

include <../params.scad>
use <../gear_math/gear_primitives_3d.scad>

module new_ring() {
    rotate([0, 0, ANG_RING]) {
        // Internal helical teeth (gear zone Z=0 to 22)
        color(C_RING, 0.11)
        translate([0, 0, GEAR_ZONE_BOT])
        helical_ring_gear(teeth=T_RING, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);

        // Outer wall: full height from RING_BOT_Z to RING_TOP_Z
        color(C_RING, 0.11)
        zcyl_hollow(RING_OD, RING_ID, RING_BOT_Z, RING_TOP_Z - RING_BOT_Z);

        // Bottom inward plate (bearing seat)
        color(C_LID, 0.11)
        zcyl_hollow(RING_ID, BEARING_BOT_OD, RING_BOT_Z, RING_WALL);

        // Top inward plate (bearing seat)
        color(C_LID, 0.11)
        zcyl_hollow(RING_ID, BEARING_TOP_OD, CARRIER1_ZTOP + RING_GAP_TOP, RING_TOP_PLATE);
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) new_ring();
