// Washer analysis: show carrier_2 pins + all planet gears + single washer + single clip
// to figure out washer placement per pin
$fn = 64;
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Show carrier_2 (bottom plate with all 6 pins visible)
color([0.45, 0.45, 0.50])
import(str(STL_DIR, "planetary_2.stl"), convexity=4);

// Show carrier_3 cages at 120 deg (3x)
for (i = [0:2])
    color([0.60, 0.60, 0.65])
    rotate([0, 0, i * 120])
    import(str(STL_DIR, "planetary_3.stl"), convexity=4);

// Show original single washer (as imported - no rotation)
color([0.95, 0.80, 0.10])
import(str(STL_DIR, "small_washer.stl"), convexity=4);

// Show original single clip (as imported - no rotation)
color([0.3, 0.3, 0.9])
import(str(STL_DIR, "clip.stl"), convexity=4);

// Show planet gears at 120 deg (3x)
for (i = [0:2]) {
    rotate([0, 0, i * 120]) {
        color([0.85, 0.25, 0.20])
        import(str(STL_DIR, "long_pinion.stl"), convexity=4);
        color([1.0, 0.85, 0.0])
        import(str(STL_DIR, "short_pinion.stl"), convexity=4);
    }
}
