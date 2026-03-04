// Slice planetary_1 at multiple Z heights to find top/mid split
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// planetary_1 bounding box: dia=78, Z=[-9, 26.5]
// We suspect it's two parts:
//   planetary_top = honeycomb plate (upper)
//   planetary_mid = drum/boss (lower)

// Show at different Z slices
module p1_slice(z_cut) {
    intersection() {
        import(str(STL_DIR, "planetary_1.stl"), convexity=8);
        translate([0, 0, z_cut]) cube([200, 200, 0.5], center=true);
    }
}

// Show the full part with a thin cross-section
color([0.55, 0.55, 0.58])
difference() {
    import(str(STL_DIR, "planetary_1.stl"), convexity=8);
    translate([-100, 0, -100]) cube([200, 100, 200]);
}
