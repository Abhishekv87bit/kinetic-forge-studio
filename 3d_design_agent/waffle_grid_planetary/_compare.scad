// Side by side: original STL (left) vs parametric carrier (right)
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// LEFT: Original STL
translate([-50, 0, 0])
color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);

// RIGHT: Just the parametric hub+plate (isolated, no rotation)
translate([50, 0, 0]) {
    // Params inline
    _plate_od = 78;
    _plate_zbot = -9;
    _plate_ztop = 0;
    _plate_h = 9;
    _ext_od = 33;
    _ext_id = 26;
    _ext_zbot = -34.25;
    _hub_ztop = 12;  // hub extends 12 above plate
    _boss_w = 7;
    _boss_l = 5;
    _boss_h = 4;
    _po_orbit = 31.5;
    _pi_orbit = 29.5;
    _pin_d = 5;

    color("skyblue")
    difference() {
        union() {
            // Plate disc
            translate([0, 0, _plate_zbot])
            cylinder(d=_plate_od, h=_plate_h, $fn=96);
            // Hub tube
            translate([0, 0, _ext_zbot])
            cylinder(d=_ext_od, h=_hub_ztop - _ext_zbot, $fn=64);
            // 6 bosses
            for (i = [0:5])
                rotate([0, 0, i * 60 + 30])
                translate([_ext_od/2 - 0.5, -_boss_w/2, _plate_ztop])
                cube([_boss_l, _boss_w, _boss_h]);
        }
        // Bore
        translate([0, 0, _ext_zbot - 0.1])
        cylinder(d=_ext_id, h=_hub_ztop - _ext_zbot + 0.2, $fn=64);
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
