// Top view: carrier_1 + carrier_3 cages + both gears to see all 6 pin positions
$fn = 64;
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Carrier_1 (top plate with 6 pin holes)
color([0.55, 0.55, 0.58])
import(str(STL_DIR, "planetary_1.stl"), convexity=4);

// All 3 carrier_3 cages
for (i = [0:2])
    color([0.60, 0.60, 0.65, 0.6])
    rotate([0, 0, i * 120])
    import(str(STL_DIR, "planetary_3.stl"), convexity=4);

// All 3 long pinions (Po) - shows one pin position
for (i = [0:2])
    color([0.85, 0.25, 0.20])
    rotate([0, 0, i * 120])
    import(str(STL_DIR, "long_pinion.stl"), convexity=4);

// All 3 short pinions (Pi) - shows the OTHER pin position
for (i = [0:2])
    color([1.0, 0.85, 0.0])
    rotate([0, 0, i * 120])
    import(str(STL_DIR, "short_pinion.stl"), convexity=4);

// Existing clips at native (Po) position
for (i = [0:2])
    color([0.3, 0.3, 0.9])
    rotate([0, 0, i * 120])
    translate([0, 0, 30.2])
    import(str(STL_DIR, "clip.stl"), convexity=4);
