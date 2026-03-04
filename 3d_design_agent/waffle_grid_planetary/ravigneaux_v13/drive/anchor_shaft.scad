// ============================================================
// ANCHOR SHAFT — Frame mounting rod
// ============================================================

include <../params.scad>

module anchor_shaft() {
    color(C_ANCHOR)
    zcyl(ANCHOR_SHAFT_D, ANCHOR_SHAFT_ZBOT, ANCHOR_SHAFT_ZTOP - ANCHOR_SHAFT_ZBOT);
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
rotate([180, 0, 0]) anchor_shaft();
