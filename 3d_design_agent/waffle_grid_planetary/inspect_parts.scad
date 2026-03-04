$fn = 64;
STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// Show ALL parts separated vertically for identification
// Each part offset in Y to see them individually

// Row 1: Core shaft components
color([0.75, 0.75, 0.78]) translate([0, 0, 0])
    import(str(STL_DIR, "shaft.stl"), convexity=4);

color([0.15, 0.55, 0.30]) translate([0, 0, 0])
    import(str(STL_DIR, "small_sun.stl"), convexity=4);

color([0.76, 0.60, 0.22]) translate([0, 0, 0])
    import(str(STL_DIR, "big_sun_0_5_backlash.stl"), convexity=4);

// Planets
color([0.85, 0.25, 0.20]) translate([0, 0, 0])
    import(str(STL_DIR, "long_pinion.stl"), convexity=4);

color([1.0, 0.85, 0.0]) translate([0, 0, 0])
    import(str(STL_DIR, "short_pinion.stl"), convexity=4);

// Carrier parts - show separately
color([0.55, 0.55, 0.58, 0.6]) translate([0, 0, 0])
    import(str(STL_DIR, "planetary_1.stl"), convexity=4);

color([0.45, 0.45, 0.50]) translate([0, 0, 0])
    import(str(STL_DIR, "planetary_2.stl"), convexity=4);

color([0.60, 0.60, 0.65]) translate([0, 0, 0])
    import(str(STL_DIR, "planetary_3.stl"), convexity=4);

// Ring
color([0.25, 0.25, 0.28, 0.5]) translate([0, 0, 0])
    import(str(STL_DIR, "ring_low_profile.stl"), convexity=4);

// Small parts
color([0.85, 0.55, 0.20]) translate([0, 0, 0])
    import(str(STL_DIR, "big_sun_ring.stl"), convexity=4);

color([0.85, 0.55, 0.20, 0.8]) translate([0, 0, 0])
    import(str(STL_DIR, "small_sun_ring.stl"), convexity=4);

color([0.95, 0.80, 0.10]) translate([0, 0, 0])
    import(str(STL_DIR, "small_washer.stl"), convexity=4);

color([0.3, 0.3, 0.9]) translate([0, 0, 0])
    import(str(STL_DIR, "clip.stl"), convexity=4);
