// ============================================================
// E-CLIPS — Retaining clips for planet pins
// ============================================================

include <../params.scad>

// --- E-clip (retaining clip) ---
module e_clip(od=10, id=8, h=1, gap_angle=40) {
    difference() {
        cylinder(d=od, h=h, $fn=24);
        translate([0, 0, -0.1])
        cylinder(d=id, h=h + 0.2, $fn=24);
        // Cut gap sector
        rotate([0, 0, -gap_angle/2])
        linear_extrude(height=h + 0.2)
        polygon([
            [0, 0],
            [od, 0],
            [od * cos(gap_angle), od * sin(gap_angle)],
        ]);
    }
}

// --- Clip assembly (all parametric e-clips) ---
module clip_assembly() {
    // E-clips at Po pin tops (above carrier_1 underside)
    for (i = [0:2])
        color(C_CLIP)
        rotate([0, 0, ANG_CARRIER + i * 120])
        translate([PO_ORBIT, 0, PO_ZTOP + WASHER_H + 0.3])
        e_clip();

    // E-clips at Pi pin tops (above carrier_1 underside)
    for (i = [0:2])
        color(C_CLIP)
        rotate([0, 0, ANG_CARRIER + i * 120 + PI_ANG_OFFSET])
        translate([PI_ORBIT_ACTUAL, 0, PI_ZTOP + WASHER_H + 0.3])
        e_clip();
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
$fn = 24;
rotate([180, 0, 0]) clip_assembly();
