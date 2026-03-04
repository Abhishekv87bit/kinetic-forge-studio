// Check pin positions on carrier_1 and carrier_3
$fn = 64;
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Show carrier_1 from top
color([0.55, 0.55, 0.58])
import(str(STL_DIR, "planetary_1.stl"), convexity=4);

// Show one carrier_3 cage to see both pin positions
color([0.60, 0.60, 0.65, 0.5])
import(str(STL_DIR, "planetary_3.stl"), convexity=4);

// Mark Po pin position with red cylinder (orbit ~31.5mm)
color([1, 0, 0])
translate([31.5, 0, 25]) cylinder(d=3, h=5);

// Show clip at native position for reference
color([0.3, 0.3, 0.9])
translate([0, 0, 27])
import(str(STL_DIR, "clip.stl"), convexity=4);

// Show washer at native XY to verify pin location
color([0.95, 0.80, 0.10])
import(str(STL_DIR, "small_washer.stl"), convexity=4);
