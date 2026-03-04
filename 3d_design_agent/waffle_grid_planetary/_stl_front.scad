// Front orthographic cross section for measurement
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

difference() {
    color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);
    translate([0, -100, -100]) cube([200, 200, 200]);
}

// Z reference lines with labels
color("red",0.5)   translate([-50, 0, -1.5]) cube([100, 0.3, 0.3]);
color("blue",0.5)  translate([-50, 0, -3.5]) cube([100, 0.3, 0.3]);
color("green",0.5) translate([-50, 0, -9]) cube([100, 0.3, 0.3]);
color("white",0.5) translate([-50, 0, -21.5]) cube([100, 0.3, 0.3]);

// Radial reference — hub OD at R=16.5
color("cyan",0.5) translate([16.5, 0, -25]) cube([0.3, 0.3, 30]);
// Plate OD at R=39
color("magenta",0.5) translate([39, 0, -25]) cube([0.3, 0.3, 30]);
