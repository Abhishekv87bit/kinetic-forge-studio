// Side by side comparison — disc-minus-circles approach
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// LEFT: Original STL
translate([-50, 0, 0])
color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);

// RIGHT: New parametric
translate([50, 0, 0]) {
    color("skyblue")
    difference() {
        union() {
            // Star plate
            translate([0, 0, -9])
            linear_extrude(height=9)
            difference() {
                circle(d=78, $fn=96);
                for (i = [0:2])
                    rotate([0, 0, i * 120 + 30])
                    translate([27, 0])
                    circle(d=28, $fn=64);
            }
            // Hub tube
            translate([0, 0, -34.25])
            cylinder(d=33, h=34.25, $fn=64);
        }
        // Bore
        translate([0, 0, -34.35])
        cylinder(d=26, h=34.55, $fn=64);
        // Pin holes
        for (i = [0:2]) {
            rotate([0, 0, i * 120])
            translate([31.5, 0, -9.1])
            cylinder(d=5, h=10, $fn=24);
            rotate([0, 0, i * 120 + 60])
            translate([29.5, 0, -9.1])
            cylinder(d=5, h=10, $fn=24);
        }
    }
}
