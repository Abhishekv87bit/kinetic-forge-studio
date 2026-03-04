// ============================================================
// SPLINES — Splined shaft tube + splined bore
// ============================================================

include <../params.scad>

// --- Splined shaft tube ---
module splined_tube(od, id, h, n_splines=SPLINE_COUNT, depth=SPLINE_DEPTH, duty=SPLINE_DUTY) {
    ridge_ang = 360 / n_splines * duty;
    pilot = min(SPLINE_PILOT, h * 0.1);
    leadin = min(SPLINE_LEADIN, h * 0.25);
    chamfer_top = min(SPLINE_CHAMFER_TOP, h * 0.1);
    z_ridge_start = pilot;
    z_full_start = pilot + leadin;
    z_full_end = h - chamfer_top;

    difference() {
        union() {
            cylinder(d=od, h=h);
            for (i = [0:n_splines-1])
                rotate([0, 0, i * 360 / n_splines])
                rotate_extrude(angle=ridge_ang)
                translate([od/2, 0])
                polygon([
                    [0,     z_ridge_start],
                    [depth, z_full_start],
                    [depth, z_full_end],
                    [0,     h - 0.01],
                ]);
        }
        translate([0, 0, -0.1])
        cylinder(d=id, h=h + 0.2);
    }
}

// --- Splined bore ---
module splined_bore(bore_d, h, n_splines=SPLINE_COUNT, depth=SPLINE_DEPTH, duty=SPLINE_DUTY, clearance=SPLINE_CLEARANCE) {
    ridge_ang = 360 / n_splines * duty;
    translate([0, 0, -0.1])
    cylinder(d=bore_d + clearance * 2, h=h + 0.2);
    for (i = [0:n_splines-1])
        rotate([0, 0, i * 360 / n_splines])
        rotate_extrude(angle=ridge_ang + 1)
        translate([bore_d/2 - 0.1, -0.1])
        square([depth + clearance + 0.1, h + 0.2]);
}

// ============================================================
// STANDALONE PREVIEW ($fn=24 for fast render)
// ============================================================
$fn = 24;

color("SteelBlue")
splined_tube(od=25, id=20, h=30);

translate([40, 0, 0])
color("Tomato")
difference() {
    cylinder(d=30, h=15);
    splined_bore(bore_d=25, h=15);
}
