// ============================================================
// BEARINGS — Top + bottom bearing indicators
// ============================================================

include <../params.scad>

module bearings() {
    if (SHOW_BEARINGS) {
        color(C_BEARING, 0.9)
        zcyl_hollow(BEARING_BOT_OD, BEARING_BOT_ID, BEARING_BOT_Z, BEARING_BOT_H);
        color(C_BEARING, 0.9)
        zcyl_hollow(BEARING_TOP_OD, BEARING_TOP_ID, BEARING_TOP_Z, BEARING_TOP_H);
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) bearings();
