// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - WAVE CONCEPT VISUALIZATION
// Isolated wave layers based on wave formation physics
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// COMPONENT INCLUDES
use <cliff_wave_L1_wrapper.scad>
use <cliff_wave_L2_wrapper.scad>
use <cliff_wave_L3_wrapper.scad>
use <ocean_wave_L1_wrapper.scad>
use <ocean_wave_L2_wrapper.scad>
use <ocean_wave_L3_wrapper.scad>

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS (for reference)
// ═══════════════════════════════════════════════════════════════════════════
IW = 310;  // Inner width
IH = 235;  // Inner height
CLIFF_X = 165;  // Cliff extends to here

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
master = t * 360;

// Phase offsets for each zone (creates rolling motion toward cliff)
phase_far = master;
phase_mid = master + 20;
phase_approach = master + 45;
phase_break = master + 70;
phase_spray = master + 90;

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════
// Far ocean (deepest)
C_FAR_1 = "#0a2a4a";
C_FAR_2 = "#0c3052";
C_FAR_3 = "#0e365a";

// Mid ocean
C_MID_1 = "#1a4a7a";
C_MID_2 = "#1e5282";
C_MID_3 = "#225a8a";

// Approaching
C_APPROACH_1 = "#2a6a9a";
C_APPROACH_2 = "#3278a8";

// Breaking
C_BREAK_1 = "#3a8ab8";
C_BREAK_2 = "#4a9ac8";

// Foam/Spray
C_FOAM = "#f0f0e8";

// ═══════════════════════════════════════════════════════════════════════════
// ZONE 1: FAR OCEAN (Right side - small, smooth, circular orbit)
// 3 overlapping waves at small scales
// ═══════════════════════════════════════════════════════════════════════════
module zone_far_ocean() {
    // Motion: gentle vertical bob
    bob1 = 2 * sin(phase_far);
    bob2 = 2 * sin(phase_far + 12);
    bob3 = 2 * sin(phase_far + 24);
    
    // Wave 1 - furthest (smallest)
    translate([IW * 0.92, IH * 0.06 + bob1, 0])
    scale([0.35, 0.35, 1])
    color(C_FAR_1, 0.95)
    ocean_wave_L1(1);
    
    // Wave 2 - overlapping
    translate([IW * 0.86, IH * 0.07 + bob2, 2])
    scale([0.40, 0.40, 1])
    color(C_FAR_2, 0.92)
    ocean_wave_L1(1);
    
    // Wave 3 - closest of far zone
    translate([IW * 0.80, IH * 0.08 + bob3, 4])
    scale([0.45, 0.45, 1])
    color(C_FAR_3, 0.90)
    ocean_wave_L2(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE 2: MID OCEAN (Middle - medium, building, orbit becoming elliptical)
// 3 overlapping waves at medium scales
// ═══════════════════════════════════════════════════════════════════════════
module zone_mid_ocean() {
    // Motion: rolling drift + vertical bob
    drift = 3 * sin(phase_mid * 0.8);
    bob1 = 4 * sin(phase_mid);
    bob2 = 4 * sin(phase_mid + 15);
    bob3 = 4 * sin(phase_mid + 30);
    
    // Wave 4
    translate([IW * 0.72 + drift, IH * 0.10 + bob1, 0])
    scale([0.55, 0.55, 1])
    color(C_MID_1, 0.90)
    ocean_wave_L2(1);
    
    // Wave 5
    translate([IW * 0.65 + drift, IH * 0.11 + bob2, 2])
    scale([0.65, 0.65, 1])
    color(C_MID_2, 0.88)
    ocean_wave_L3(1);
    
    // Wave 6
    translate([IW * 0.58 + drift, IH * 0.12 + bob3, 4])
    scale([0.75, 0.75, 1])
    color(C_MID_3, 0.85)
    ocean_wave_L2(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE 3: APPROACHING SHORE (Getting close - large, cresting, elliptical orbit)
// 2 waves at larger scales
// ═══════════════════════════════════════════════════════════════════════════
module zone_approaching() {
    // Motion: strong surge + higher bob
    surge = 5 * sin(phase_approach * 0.7);
    bob1 = 6 * sin(phase_approach);
    bob2 = 7 * sin(phase_approach + 20);
    
    // Wave 7
    translate([IW * 0.50 + surge, IH * 0.13 + bob1, 0])
    scale([0.85, 0.85, 1])
    color(C_APPROACH_1, 0.85)
    ocean_wave_L3(1);
    
    // Wave 8 - largest before breaking
    translate([IW * 0.42 + surge, IH * 0.14 + bob2, 3])
    scale([1.0, 1.0, 1])
    color(C_APPROACH_2, 0.82)
    ocean_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE 4: BREAKING ZONE (Near cliff - dramatic curl)
// Using cliff_wave shapes for the dramatic break
// ═══════════════════════════════════════════════════════════════════════════
module zone_breaking() {
    // Motion: dramatic crash surge
    crash = 10 * sin(phase_break * 0.6);
    surge = 8 * sin(phase_break);
    
    // Wave 9 - base swell (cliff_wave_L1)
    translate([IW * 0.35 + surge * 0.5, IH * 0.08 + crash * 0.3, 0])
    scale([0.22, 0.22, 1])
    color(C_BREAK_1, 0.85)
    cliff_wave_L1(1);
    
    // Wave 10 - rising crest (cliff_wave_L2)
    translate([IW * 0.28 + surge * 0.7, IH * 0.12 + crash * 0.5, 3])
    scale([0.20, 0.20, 1])
    color(C_BREAK_2, 0.82)
    cliff_wave_L2(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE 5: CLIFF IMPACT (At cliff - foam spray shooting up)
// Using cliff_wave_L3 rotated -70° for spray effect
// ═══════════════════════════════════════════════════════════════════════════
module zone_cliff_spray() {
    // Motion: burst upward timed to crash
    burst = 8 * sin(phase_spray * 0.5);
    
    // Spray 1 - lowest
    translate([CLIFF_X + 25 + burst * 0.3, IH * 0.25 + burst, 0])
    rotate([0, 0, -70])
    scale([0.28, 0.28, 1])
    color(C_FOAM, 0.95)
    cliff_wave_L3(1);
    
    // Spray 2 - middle
    translate([CLIFF_X + 15 + burst * 0.2, IH * 0.42 + burst * 0.8, 2])
    rotate([0, 0, -70])
    scale([0.22, 0.22, 1])
    color(C_FOAM, 0.90)
    cliff_wave_L3(1);
    
    // Spray 3 - highest
    translate([CLIFF_X + 8 + burst * 0.1, IH * 0.58 + burst * 0.6, 4])
    rotate([0, 0, -70])
    scale([0.16, 0.16, 1])
    color(C_FOAM, 0.85)
    cliff_wave_L3(1);
    
    // Spray 4 - peak (smallest, highest)
    translate([CLIFF_X + 3, IH * 0.72 + burst * 0.4, 6])
    rotate([0, 0, -70])
    scale([0.12, 0.12, 1])
    color(C_FOAM, 0.75)
    cliff_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// REFERENCE ELEMENTS
// ═══════════════════════════════════════════════════════════════════════════
module reference_cliff() {
    color("#8b7355", 0.5)
    linear_extrude(height=5)
    polygon([
        [0, 0],
        [100, 0],
        [CLIFF_X, 85],
        [0, 85]
    ]);
}

module reference_frame() {
    color("#5a4030", 0.3)
    difference() {
        square([IW, IH]);
        translate([2, 2]) square([IW-4, IH-4]);
    }
}

module zone_labels() {
    // Zone labels for reference
    color("white") {
        translate([IW * 0.88, IH * 0.02, 20])
        linear_extrude(1) text("FAR", size=8);
        
        translate([IW * 0.65, IH * 0.02, 20])
        linear_extrude(1) text("MID", size=8);
        
        translate([IW * 0.45, IH * 0.02, 20])
        linear_extrude(1) text("APPROACH", size=6);
        
        translate([IW * 0.28, IH * 0.02, 20])
        linear_extrude(1) text("BREAK", size=6);
        
        translate([CLIFF_X + 5, IH * 0.02, 20])
        linear_extrude(1) text("SPRAY", size=6);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// Background
color("#4a7ab0", 0.5) cube([IW, IH, 1]);

// Reference cliff (semi-transparent)
translate([0, 0, 0]) reference_cliff();

// ZONE 1: Far Ocean
translate([0, 0, 32]) zone_far_ocean();

// ZONE 2: Mid Ocean  
translate([0, 0, 36]) zone_mid_ocean();

// ZONE 3: Approaching
translate([0, 0, 40]) zone_approaching();

// ZONE 4: Breaking
translate([0, 0, 43]) zone_breaking();

// ZONE 5: Cliff Spray
translate([0, 0, 47]) zone_cliff_spray();

// Labels (comment out for clean view)
// zone_labels();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("WAVE CONCEPT VISUALIZATION");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Zone 1 - FAR OCEAN: 3 waves, scales 0.35-0.45, Z=32-34");
echo("Zone 2 - MID OCEAN: 3 waves, scales 0.55-0.75, Z=36-38");
echo("Zone 3 - APPROACHING: 2 waves, scales 0.85-1.0, Z=40-41");
echo("Zone 4 - BREAKING: 2 cliff waves, scales 0.20-0.22, Z=43-45");
echo("Zone 5 - CLIFF SPRAY: 4 foam bursts, rotated -70°, Z=47-50");
echo("");
echo("TOTAL: 14 wave layers");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
