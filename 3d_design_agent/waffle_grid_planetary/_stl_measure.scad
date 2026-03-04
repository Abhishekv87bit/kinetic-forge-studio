// Cross-section the STL to measure exact dimensions
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Cross-section through center (cut half away)
difference() {
    color("orange") import(str(STL_DIR, "planetary_2.stl"), convexity=4);
    translate([0, -100, -100]) cube([200, 200, 200]);
}

// Reference lines
color("red") translate([0, 0, 0]) cube([50, 0.5, 0.5]);    // Z=0 line
color("blue") translate([0, 0, -9]) cube([50, 0.5, 0.5]);   // Z=-9
color("green") translate([0, 0, -21.5]) cube([50, 0.5, 0.5]); // Z=-21.5
