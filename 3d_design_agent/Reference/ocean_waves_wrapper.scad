// ═══════════════════════════════════════════════════════════════════════════════════════
//                    OCEAN WAVES STL WRAPPER
//                    Imports 5 wave layer STLs with proper positioning
//                    Connects to four-bar crank-rocker mechanism
// ═══════════════════════════════════════════════════════════════════════════════════════

// Wave STL original bounds:
// X: -124 to 101 (width: 225mm)
// Y: -115 to -67 (height: 48mm)  
// Z: 7 to 64 (5 layers at Z=7-11, 22-26, 35-39, 48-52, 60-64)

// Target zone: [78, 302, 0, 80] relative to inner canvas

// === TRANSFORMATION PARAMETERS ===
WAVE_X_OFFSET = 201.5;   // Move right to center in zone
WAVE_Y_OFFSET = 115;     // Move up (original Y was negative)
WAVE_Z_BASE = 60;        // Target Z start position

// Layer Z offsets (from original STL to target)
// Original layer Z positions: 7, 22, 35, 48, 60
// We want them at: 60, 63, 66, 69, 72 (3mm spacing)
LAYER_Z_OFFSETS = [
    WAVE_Z_BASE - 7,     // Layer 0: 60 - 7 = 53
    WAVE_Z_BASE + 3 - 22, // Layer 1: 63 - 22 = 41  
    WAVE_Z_BASE + 6 - 35, // Layer 2: 66 - 35 = 31
    WAVE_Z_BASE + 9 - 48, // Layer 3: 69 - 48 = 21
    WAVE_Z_BASE + 12 - 60 // Layer 4: 72 - 60 = 12
];

// Phase offsets for wave animation (30° per layer)
WAVE_PHASES = [0, 30, 60, 90, 120];

// Pivot point (at cliff edge, where waves hinge)
PIVOT_X = 78;
PIVOT_Y = 24;

// Animation
wave_phase = $t * 360;

// Colors for each layer (dark to light, back to front)
WAVE_COLORS = [
    [10/255, 42/255, 78/255],    // Layer 0: #0a2a4e
    [26/255, 74/255, 126/255],   // Layer 1: #1a4a7e
    [42/255, 90/255, 142/255],   // Layer 2: #2a5a8e
    [58/255, 106/255, 158/255],  // Layer 3: #3a6a9e
    [74/255, 122/255, 174/255]   // Layer 4: #4a7aae
];

// === INDIVIDUAL LAYER MODULES ===

module ocean_wave_layer_0(tilt_override=undef) {
    layer = 0;
    tilt = is_undef(tilt_override) ? 12 * sin(wave_phase + WAVE_PHASES[layer]) : tilt_override;
    
    color(WAVE_COLORS[layer])
    translate([PIVOT_X, PIVOT_Y, 0])
    rotate([tilt, 0, 0])
    translate([-PIVOT_X, -PIVOT_Y, 0])
    translate([WAVE_X_OFFSET, WAVE_Y_OFFSET, LAYER_Z_OFFSETS[layer]])
    import("ocean_wave_layer_0.stl");
}

module ocean_wave_layer_1(tilt_override=undef) {
    layer = 1;
    tilt = is_undef(tilt_override) ? 12 * sin(wave_phase + WAVE_PHASES[layer]) : tilt_override;
    
    color(WAVE_COLORS[layer])
    translate([PIVOT_X, PIVOT_Y, 0])
    rotate([tilt, 0, 0])
    translate([-PIVOT_X, -PIVOT_Y, 0])
    translate([WAVE_X_OFFSET, WAVE_Y_OFFSET, LAYER_Z_OFFSETS[layer]])
    import("ocean_wave_layer_1.stl");
}

module ocean_wave_layer_2(tilt_override=undef) {
    layer = 2;
    tilt = is_undef(tilt_override) ? 12 * sin(wave_phase + WAVE_PHASES[layer]) : tilt_override;
    
    color(WAVE_COLORS[layer])
    translate([PIVOT_X, PIVOT_Y, 0])
    rotate([tilt, 0, 0])
    translate([-PIVOT_X, -PIVOT_Y, 0])
    translate([WAVE_X_OFFSET, WAVE_Y_OFFSET, LAYER_Z_OFFSETS[layer]])
    import("ocean_wave_layer_2.stl");
}

module ocean_wave_layer_3(tilt_override=undef) {
    layer = 3;
    tilt = is_undef(tilt_override) ? 12 * sin(wave_phase + WAVE_PHASES[layer]) : tilt_override;
    
    color(WAVE_COLORS[layer])
    translate([PIVOT_X, PIVOT_Y, 0])
    rotate([tilt, 0, 0])
    translate([-PIVOT_X, -PIVOT_Y, 0])
    translate([WAVE_X_OFFSET, WAVE_Y_OFFSET, LAYER_Z_OFFSETS[layer]])
    import("ocean_wave_layer_3.stl");
}

module ocean_wave_layer_4(tilt_override=undef) {
    layer = 4;
    tilt = is_undef(tilt_override) ? 12 * sin(wave_phase + WAVE_PHASES[layer]) : tilt_override;
    
    color(WAVE_COLORS[layer])
    translate([PIVOT_X, PIVOT_Y, 0])
    rotate([tilt, 0, 0])
    translate([-PIVOT_X, -PIVOT_Y, 0])
    translate([WAVE_X_OFFSET, WAVE_Y_OFFSET, LAYER_Z_OFFSETS[layer]])
    import("ocean_wave_layer_4.stl");
}

// === COMPLETE WAVE ASSEMBLY ===

module ocean_waves_assembly() {
    ocean_wave_layer_0();
    ocean_wave_layer_1();
    ocean_wave_layer_2();
    ocean_wave_layer_3();
    ocean_wave_layer_4();
}

// === PIVOT HARDWARE ===

module wave_pivot_hardware() {
    // Pivot rod running through all wave layers at cliff edge
    color("Silver")
    translate([PIVOT_X, PIVOT_Y, WAVE_Z_BASE - 5])
    rotate([0, 90, 0])
    cylinder(d=4, h=10, center=true);
    
    // Bearing blocks at each end
    color("#8b7355") {
        translate([PIVOT_X - 8, PIVOT_Y, WAVE_Z_BASE - 5])
        cube([6, 10, 20], center=true);
        
        translate([PIVOT_X + 8, PIVOT_Y, WAVE_Z_BASE - 5])
        cube([6, 10, 20], center=true);
    }
}

// === COUPLER ROD ATTACHMENT POINTS ===
// These show where the four-bar coupler rods connect to each wave layer

module wave_coupler_attachments() {
    attachment_x = 120;  // X position where coupler connects
    
    for (layer = [0:4]) {
        layer_z = WAVE_Z_BASE + layer * 3;
        tilt = 12 * sin(wave_phase + WAVE_PHASES[layer]);
        
        // Calculate attachment point after tilt
        translate([PIVOT_X, PIVOT_Y, 0])
        rotate([tilt, 0, 0])
        translate([-PIVOT_X, -PIVOT_Y, 0])
        translate([attachment_x, 10, layer_z]) {
            color("Red")
            sphere(d=5);
            
            // Label
            color("White")
            translate([0, 0, 5])
            linear_extrude(height=1)
            text(str("L", layer), size=4, halign="center");
        }
    }
}

// === TEST RENDER ===
// Uncomment to test this file independently

// ocean_waves_assembly();
// wave_pivot_hardware();
// wave_coupler_attachments();

echo("═══════════════════════════════════════════════════════════════════════════");
echo("OCEAN WAVES STL WRAPPER");
echo("═══════════════════════════════════════════════════════════════════════════");
echo("Required STL files (place in same folder):");
echo("  - ocean_wave_layer_0.stl");
echo("  - ocean_wave_layer_1.stl");
echo("  - ocean_wave_layer_2.stl");
echo("  - ocean_wave_layer_3.stl");
echo("  - ocean_wave_layer_4.stl");
echo("");
echo("Transformation applied:");
echo("  X offset:", WAVE_X_OFFSET, "mm");
echo("  Y offset:", WAVE_Y_OFFSET, "mm");
echo("  Pivot point: (", PIVOT_X, ",", PIVOT_Y, ")");
echo("");
echo("Animation: View → Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════");
