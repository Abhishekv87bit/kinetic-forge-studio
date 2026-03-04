$fn=64;
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Show each part individually to verify 3-way symmetry

// Long pinion — already 3 copies?
color([0.85, 0.25, 0.20])
import(str(STL_DIR, "long_pinion.stl"), convexity=4);

// Short pinion — already 3 copies?
color([1.0, 0.85, 0.0])
import(str(STL_DIR, "short_pinion.stl"), convexity=4);

// planetary_3 — already 3 copies?
color([0.60, 0.60, 0.65, 0.7])
import(str(STL_DIR, "planetary_3.stl"), convexity=4);
