// Side by side: original STL (left) vs new star plate (right)
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// LEFT: Original STL
translate([-50, 0, 0])
color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);

// RIGHT: New parametric star carrier
translate([50, 0, 0]) {
    _ext_od = 33;
    _ext_id = 26;
    _plate_thick = 3;
    _plate_h = 9;
    _plate_ztop = 0;
    _plate_zbot = -9;
    _taper_h = _plate_h - _plate_thick;
    _ext_zbot = -34.25;
    _po_orbit = 31.5;
    _pi_orbit = 29.5;
    _pin_d = 5;
    _boss_d = 14;

    color("skyblue")
    difference() {
        union() {
            // Star plate
            translate([0, 0, _plate_ztop - _plate_thick])
            linear_extrude(height=_plate_thick)
            union() {
                circle(d=_ext_od + 6, $fn=64);
                for (i = [0:2]) {
                    hull() {
                        circle(d=_ext_od + 2, $fn=64);
                        rotate([0, 0, i * 120])
                        translate([_po_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                    }
                    hull() {
                        circle(d=_ext_od + 2, $fn=64);
                        rotate([0, 0, i * 120 + 60])
                        translate([_pi_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                    }
                    hull() {
                        rotate([0, 0, i * 120])
                        translate([_po_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                        rotate([0, 0, i * 120 + 60])
                        translate([_pi_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                    }
                }
            }
            // Transition
            translate([0, 0, _plate_ztop - _plate_thick - _taper_h])
            linear_extrude(height=_taper_h)
            union() {
                circle(d=_ext_od + 6, $fn=64);
                for (i = [0:2]) {
                    hull() {
                        circle(d=_ext_od + 2, $fn=64);
                        rotate([0, 0, i * 120])
                        translate([_po_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                    }
                    hull() {
                        circle(d=_ext_od + 2, $fn=64);
                        rotate([0, 0, i * 120 + 60])
                        translate([_pi_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                    }
                    hull() {
                        rotate([0, 0, i * 120])
                        translate([_po_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                        rotate([0, 0, i * 120 + 60])
                        translate([_pi_orbit, 0])
                        circle(d=_boss_d, $fn=32);
                    }
                }
            }
            // Hub tube
            translate([0, 0, _ext_zbot])
            cylinder(d=_ext_od, h=-_ext_zbot, $fn=64);
        }
        // Bore
        translate([0, 0, _ext_zbot - 0.1])
        cylinder(d=_ext_id, h=-_ext_zbot + 0.2, $fn=64);
        // Pin holes
        for (i = [0:2]) {
            rotate([0, 0, i * 120])
            translate([_po_orbit, 0, _plate_zbot - 0.1])
            cylinder(d=_pin_d, h=10, $fn=24);
            rotate([0, 0, i * 120 + 60])
            translate([_pi_orbit, 0, _plate_zbot - 0.1])
            cylinder(d=_pin_d, h=10, $fn=24);
        }
    }
}
