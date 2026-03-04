// Iterate window size to match original STL
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Original STL
translate([-50, 0, 0])
color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);

// Try larger windows
// Key insight from data: at 30°, R_max=16.5 (hub only)
// At 60°, R_max=37.27; at 90°, R_max=35.33
// Window must cut from hub edge to near-rim
// The window center and size must eat all material between arms

// Window: center at R=28, D=38 (much larger)
translate([50, 0, 0]) {
    color("skyblue")
    difference() {
        union() {
            translate([0, 0, -3])
            linear_extrude(height=3)
            difference() {
                circle(d=80, $fn=96);
                for (i = [0:2])
                    rotate([0, 0, i * 120 + 30])
                    translate([28, 0])
                    circle(d=38, $fn=64);
            }
            // Hub tube
            translate([0, 0, -21.5])
            cylinder(d=33, h=21.5, $fn=64);
        }
        // Bore
        translate([0, 0, -21.6])
        cylinder(d=27, h=21.8, $fn=64);
        // Pin holes
        for (i = [0:2]) {
            rotate([0, 0, i * 120])
            translate([31.5, 0, -3.1])
            cylinder(d=5, h=4, $fn=24);
            rotate([0, 0, i * 120 + 60])
            translate([29.5, 0, -3.1])
            cylinder(d=5, h=4, $fn=24);
        }
    }
}
