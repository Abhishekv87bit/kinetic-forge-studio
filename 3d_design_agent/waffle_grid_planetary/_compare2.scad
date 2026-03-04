// Side by side: original STL (left) vs new parametric (right)
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// LEFT: Original STL
translate([-50, 0, 0])
color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);

// RIGHT: New parametric spider plate
translate([50, 0, 0]) {
    _plate_od = 78;
    _plate_zbot = -9;
    _plate_h = 9;
    _ext_od = 33;
    _ext_id = 26;
    _ext_zbot = -34.25;
    _po_orbit = 31.5;
    _pi_orbit = 29.5;
    _pin_d = 5;
    _win_r = (_ext_od/2 + _plate_od/2) / 2;
    _win_d = 22;

    color("skyblue")
    difference() {
        union() {
            translate([0, 0, _plate_zbot])
            cylinder(d=_plate_od, h=_plate_h, $fn=96);
            translate([0, 0, _ext_zbot])
            cylinder(d=_ext_od, h=-_ext_zbot, $fn=64);
        }
        translate([0, 0, _ext_zbot - 0.1])
        cylinder(d=_ext_id, h=-_ext_zbot + 0.2, $fn=64);
        // Windows
        for (i = [0:5])
            rotate([0, 0, i * 60 + 30])
            translate([_win_r, 0, _plate_zbot - 0.1])
            cylinder(d=_win_d, h=_plate_h + 0.2, $fn=48);
        // Pins
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
