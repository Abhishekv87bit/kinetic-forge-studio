// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V28 - COMPLETE ASSEMBLY
// Based on pic_4 reference layout
// ═══════════════════════════════════════════════════════════════════════════
// 
// All shapes from user's converted STL→SCAD files
// Layout matches pic_4 exactly
//
// COMPONENTS:
//   - Wind Path (upper area with 2 swirl holes)
//   - Cliff Waves (3 layers, lower left)
//   - Ocean Waves (3 layers, lower center-right)
//   - Cypress Tree (left side)
//   - Cliff, Lighthouse, Moon, Gears
// ═══════════════════════════════════════════════════════════════════════════
$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════
// INCLUDE USER'S CONVERTED SHAPES (with unique module names)
// ═══════════════════════════════════════════════════════════════════════════

// Cliff Waves (modules: cliff_wave_L1, cliff_wave_L2, cliff_wave_L3)
use <cliff_wave_L1_wrapper.scad>
use <cliff_wave_L2_wrapper.scad>
use <cliff_wave_L3_wrapper.scad>

// Ocean Waves (modules: ocean_wave_L1, ocean_wave_L2, ocean_wave_L3)
use <ocean_wave_L1_wrapper.scad>
use <ocean_wave_L2_wrapper.scad>
use <ocean_wave_L3_wrapper.scad>

// Cypress & Wind (modules: cypress_shape, wind_path_shape)
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS (matching your project)
// ═══════════════════════════════════════════════════════════════════════════
W = 350;            // Total width
H = 275;            // Total height  
D = 80;             // Total depth
FW = 20;            // Frame width
IW = W - FW*2;      // Inner width (310mm)
IH = H - FW*2;      // Inner height (235mm)

LAYER_T = 10;       // Layer thickness (matches STL files)

// ═══════════════════════════════════════════════════════════════════════════
// COMPONENT BOUNDING BOXES (from your files)
// ═══════════════════════════════════════════════════════════════════════════
// cliffwave1: [-213.1, -45.6, 0] to [213.1, 103.5, 10] = 426×149mm
// cliffwave2: [-213.0, -65.5, 0] to [212.4, 125.0, 10] = 425×190mm  
// cliffwave3: [-122.1, -88.9, 0] to [122.5, 88.6, 10]  = 245×177mm
// cypress:    [-22.5, -112.6, 0] to [64.6, 48.4, 10]   = 87×161mm
// ocean_L1:   [-55.9, -5.9, 0] to [55.9, 24.7, 10]     = 112×31mm
// ocean_L2:   [-56.6, -6.0, 0] to [55.1, 25.0, 10]     = 112×31mm
// ocean_L3:   [-56.3, -12.0, 0] to [55.8, 26.5, 10]    = 112×39mm
// wind_path:  [-892.3, -266.8, 0] to [892.0, 266.6, 10] = 1784×533mm

// ═══════════════════════════════════════════════════════════════════════════
// SCALING FACTORS (to fit 310×235mm inner canvas)
// ═══════════════════════════════════════════════════════════════════════════
// Based on pic_4 proportions:

WIND_SCALE = 0.165;        // Wind path fills ~60% width of upper area
CLIFF_WAVE_SCALE = 0.38;   // Cliff waves in lower-left quadrant
OCEAN_WAVE_SCALE = 1.6;    // Ocean waves scaled up to fill lower-right
CYPRESS_SCALE = 0.85;      // Cypress tree on left side

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;

// Swirl rotations (counter-rotating)
swirl_large_rot = t * 360 * 0.4;
swirl_small_rot = -t * 360 * 0.6;

// Moon rotation
moon_rot = t * 360 * 0.2;

// Wave motions
wave_drift = 6 * sin(t * 360);      // Side-to-side drift
wave_surge = 4 * sin(t * 360);      // Up-down surge

// Gear rotation
gear_rot = t * 360 * 0.3;

// Lighthouse beam
lighthouse_rot = t * 360 * 4;

// ═══════════════════════════════════════════════════════════════════════════
// COLORS (matching pic_4 palette)
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = "#6b5344";           // Brown wood frame
C_SKY = "#4a7ab0";             // Blue sky background
C_WIND = "#3a6a9e";            // Wind path blue
C_SWIRL_DARK = "#2a5a8e";      // Swirl disc dark
C_SWIRL_LIGHT = "#5a8abe";     // Swirl disc light

C_CLIFF_WAVE_1 = "#1a4a6a";    // Darkest wave blue
C_CLIFF_WAVE_2 = "#2a5a7a";    // Medium wave blue
C_CLIFF_WAVE_3 = "#e8e8e0";    // Foam white/cream

C_OCEAN_WAVE_1 = "#1a4a6a";    // Dark ocean blue
C_OCEAN_WAVE_2 = "#2a6a8a";    // Medium ocean blue
C_OCEAN_WAVE_3 = "#f0f0e8";    // Foam/whitecaps

C_CLIFF = "#8b7355";           // Cliff brown
C_LIGHTHOUSE = "#d4c4a8";      // Lighthouse tan
C_CYPRESS = "#2a4a2a";         // Dark green cypress
C_MOON = "#f0d050";            // Yellow moon
C_GEAR = "#b8a060";            // Brass gear color
C_CRESCENT = "#d0c080";        // Crescent moon

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS (back to front, based on pic_4 depth)
// ═══════════════════════════════════════════════════════════════════════════
Z_BACK = 0;
Z_GEARS_BACK = 5;
Z_CRESCENT_MOON = 8;
Z_SWIRL_DISCS = 12;
Z_WIND_PATH = 20;
Z_MOON = 15;
Z_CLIFF = 25;
Z_LIGHTHOUSE = 28;
Z_CLIFF_WAVE_1 = 32;
Z_CLIFF_WAVE_2 = 37;
Z_CLIFF_WAVE_3 = 42;
Z_OCEAN_WAVE_1 = 35;
Z_OCEAN_WAVE_2 = 40;
Z_OCEAN_WAVE_3 = 45;
Z_OCEAN_MECHANISM = 38;
Z_CYPRESS = 50;
Z_GEARS_FRONT = 48;
Z_FRAME = 65;

// ═══════════════════════════════════════════════════════════════════════════
// COMPONENT WRAPPER MODULES
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// WIND PATH - Upper area with swirl cutouts
// Position: Upper 60% of canvas, centered
// ─────────────────────────────────────────────────────────────────────────────
module wind_path_placed() {
    // Original centered at origin, scale and position
    // In pic_4: Wind path spans from ~15% to ~85% width, 40% to 95% height
    translate([IW * 0.50, IH * 0.68, 0])
    scale([WIND_SCALE, WIND_SCALE, 1])
    color(C_WIND)
    wind_path_shape(1);  // From wind_path_shape_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF WAVE LAYER 1 (Back, darkest)
// Position: Lower-left, adjacent to cliff
// ─────────────────────────────────────────────────────────────────────────────
module cliff_wave_1_placed(drift=0) {
    // Original: 426×149mm centered at origin
    // Position next to cliff base
    translate([IW * 0.35 + drift, IH * 0.18, 0])
    scale([CLIFF_WAVE_SCALE, CLIFF_WAVE_SCALE, 1])
    color(C_CLIFF_WAVE_1)
    cliff_wave_L1(1);  // From cliff_wave_L1_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF WAVE LAYER 2 (Middle)
// ─────────────────────────────────────────────────────────────────────────────
module cliff_wave_2_placed(drift=0) {
    translate([IW * 0.35 + drift * 0.7, IH * 0.20, 0])
    scale([CLIFF_WAVE_SCALE * 0.95, CLIFF_WAVE_SCALE * 0.95, 1])
    color(C_CLIFF_WAVE_2)
    cliff_wave_L2(1);  // From cliff_wave_L2_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF WAVE LAYER 3 (Front, foam)
// ─────────────────────────────────────────────────────────────────────────────
module cliff_wave_3_placed(drift=0) {
    translate([IW * 0.32 + drift * 0.4, IH * 0.22, 0])
    scale([CLIFF_WAVE_SCALE * 0.85, CLIFF_WAVE_SCALE * 0.85, 1])
    color(C_CLIFF_WAVE_3)
    cliff_wave_L3(1);  // From cliff_wave_L3_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// OCEAN WAVE LAYER 1 (Back)
// Position: Lower-right, more horizontal orientation
// ─────────────────────────────────────────────────────────────────────────────
module ocean_wave_1_placed(drift=0) {
    // Original: 112×31mm - scale up and position right of cliff waves
    translate([IW * 0.70 + drift * 0.3, IH * 0.10, 0])
    scale([OCEAN_WAVE_SCALE, OCEAN_WAVE_SCALE, 1])
    color(C_OCEAN_WAVE_1)
    ocean_wave_L1(1);  // From ocean_wave_L1_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// OCEAN WAVE LAYER 2 (Middle)
// ─────────────────────────────────────────────────────────────────────────────
module ocean_wave_2_placed(drift=0) {
    translate([IW * 0.72 + drift * 0.5, IH * 0.12, 0])
    scale([OCEAN_WAVE_SCALE * 0.95, OCEAN_WAVE_SCALE * 0.95, 1])
    color(C_OCEAN_WAVE_2)
    ocean_wave_L2(1);  // From ocean_wave_L2_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// OCEAN WAVE LAYER 3 (Front, foam/whitecaps)
// ─────────────────────────────────────────────────────────────────────────────
module ocean_wave_3_placed(surge=0) {
    translate([IW * 0.68, IH * 0.14 + surge, 0])
    scale([OCEAN_WAVE_SCALE * 0.9, OCEAN_WAVE_SCALE * 0.9, 1])
    color(C_OCEAN_WAVE_3)
    ocean_wave_L3(1);  // From ocean_wave_L3_wrapper.scad
}

// ─────────────────────────────────────────────────────────────────────────────
// CYPRESS TREE
// Position: Left side (though not prominently visible in pic_4)
// ─────────────────────────────────────────────────────────────────────────────
module cypress_placed() {
    // Original: 87×161mm, tall vertical shape
    // Position on far left, behind lighthouse area
    translate([IW * 0.12, IH * 0.55, 0])
    scale([CYPRESS_SCALE, CYPRESS_SCALE, 1])
    rotate([0, 0, 0])
    color(C_CYPRESS)
    cypress_shape(1);  // From cypress_shape_wrapper.scad
}

// ═══════════════════════════════════════════════════════════════════════════
// PROCEDURAL COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// GEAR MODULE
// ─────────────────────────────────────────────────────────────────────────────
module gear(teeth, radius, thickness=5, hole_r=3) {
    tooth_h = radius * 0.15;
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=radius-tooth_h, h=thickness);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([radius-tooth_h, 0, 0])
                cylinder(r=tooth_h*1.2, h=thickness, $fn=6);
            }
        }
        translate([0, 0, -1]) cylinder(r=hole_r, h=thickness+2);
        // Spoke cutouts for larger gears
        if (radius > 18) {
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                translate([radius*0.55, 0, -1])
                cylinder(r=radius*0.20, h=thickness+2);
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF - Lower left landmass
// ─────────────────────────────────────────────────────────────────────────────
module cliff() {
    cliff_w = IW * 0.30;
    cliff_h = IH * 0.48;
    
    color(C_CLIFF)
    linear_extrude(height=15)
    polygon([
        [0, 0],
        [0, cliff_h],
        [cliff_w * 0.10, cliff_h * 1.05],
        [cliff_w * 0.25, cliff_h * 1.02],
        [cliff_w * 0.45, cliff_h * 0.95],
        [cliff_w * 0.65, cliff_h * 0.85],
        [cliff_w * 0.85, cliff_h * 0.70],
        [cliff_w * 1.0, cliff_h * 0.55],
        [cliff_w * 0.95, cliff_h * 0.40],
        [cliff_w * 0.85, cliff_h * 0.25],
        [cliff_w * 0.70, cliff_h * 0.12],
        [cliff_w * 0.45, cliff_h * 0.05],
        [cliff_w * 0.20, cliff_h * 0.02],
        [0, 0]
    ]);
    
    // Texture ridges
    color("#7a6345")
    for (i = [0:4]) {
        translate([8 + i*15, cliff_h * 0.15 + i*cliff_h*0.12, 15])
        linear_extrude(height=3)
        scale([1.8, 0.5])
        circle(r=8);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIGHTHOUSE
// ─────────────────────────────────────────────────────────────────────────────
module lighthouse(beam_rot) {
    // Tower
    color(C_LIGHTHOUSE)
    linear_extrude(height=50, scale=0.7)
    circle(r=9);
    
    // Stripes
    color("#8b6914")
    for (z = [8, 22, 36]) {
        translate([0, 0, z])
        linear_extrude(height=5)
        circle(r=8 - z*0.04);
    }
    
    // Platform
    translate([0, 0, 50])
    color("#333") cylinder(r=11, h=3);
    
    // Lamp room
    translate([0, 0, 53])
    color("LightYellow", 0.6) {
        difference() {
            cylinder(r=8, h=10);
            translate([0, 0, 2]) cylinder(r=7, h=10);
        }
    }
    
    // Light glow
    translate([0, 0, 58])
    color("Yellow", 0.9) sphere(r=4);
    
    // Rotating beam
    translate([0, 0, 55])
    rotate([0, 0, beam_rot])
    color("Yellow", 0.4)
    linear_extrude(height=6)
    polygon([[0,0], [25, -2], [25, 2]]);
    
    // Roof
    translate([0, 0, 63])
    color("#8b4513") cylinder(r1=10, r2=3, h=8);
    
    // Keeper's house
    translate([12, -5, 0])
    color(C_LIGHTHOUSE) {
        cube([15, 12, 10]);
        // Roof
        translate([0, 6, 10])
        rotate([90, 0, 90])
        linear_extrude(height=15)
        polygon([[0, 0], [6, 5], [12, 0]]);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWIRL DISC (rotating inside wind path holes)
// ─────────────────────────────────────────────────────────────────────────────
module swirl_disc(radius, rot, layers=3) {
    for (i = [0:layers-1]) {
        translate([0, 0, i*3])
        rotate([0, 0, rot * (i % 2 == 0 ? 1 : -1)])
        color(i % 2 == 0 ? C_SWIRL_DARK : C_SWIRL_LIGHT, 0.9)
        difference() {
            cylinder(r=radius - i*2, h=3);
            translate([0, 0, -1]) cylinder(r=radius*0.1, h=5);
            // Spiral cutouts
            for (j = [0:2]) {
                rotate([0, 0, j*120 + i*40])
                translate([radius*0.5, 0, -1])
                cylinder(r=radius*0.15, h=5);
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOON (Right side, with concentric rings)
// ─────────────────────────────────────────────────────────────────────────────
module moon_assembly(rot) {
    // Glow
    color(C_MOON, 0.25)
    cylinder(r=55, h=2);
    
    // Core
    translate([0, 0, 2])
    color(C_MOON)
    cylinder(r=32, h=6);
    
    // Concentric rotating rings
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.8) {
        for (r = [38, 44, 50]) {
            difference() {
                cylinder(r=r+2, h=5);
                translate([0, 0, -1]) cylinder(r=r-1, h=7);
                // Break into arcs
                for (a = [0:3]) {
                    rotate([0, 0, a*90 + 20])
                    translate([0, 0, -1])
                    cube([60, 5, 7]);
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRESCENT MOON (Left side, per pic_4)
// ─────────────────────────────────────────────────────────────────────────────
module crescent_moon() {
    color(C_CRESCENT)
    linear_extrude(height=5)
    difference() {
        circle(r=22);
        translate([10, 0]) circle(r=18);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// GEARS CLUSTER - Under cliff
// ─────────────────────────────────────────────────────────────────────────────
module cliff_gears(rot) {
    // Large gear (back)
    translate([15, IH*0.08, Z_GEARS_BACK])
    rotate([0, 0, rot]) gear(28, 32, 5, 6);
    
    // Medium gears
    translate([50, IH*0.05, Z_GEARS_BACK+2])
    rotate([0, 0, -rot*0.85]) gear(24, 28, 5, 5);
    
    translate([25, IH*0.22, Z_GEARS_BACK+4])
    rotate([0, 0, rot*1.2]) gear(20, 24, 4, 5);
    
    // Small gears
    translate([60, IH*0.18, Z_GEARS_BACK+6])
    rotate([0, 0, -rot*1.5]) gear(16, 18, 4, 4);
    
    translate([5, IH*0.15, Z_GEARS_BACK+3])
    rotate([0, 0, rot*1.8]) gear(18, 20, 4, 4);
    
    translate([45, IH*0.28, Z_GEARS_FRONT])
    rotate([0, 0, -rot*2]) gear(14, 15, 3, 3);
}

// ─────────────────────────────────────────────────────────────────────────────
// GEARS CLUSTER - Around swirls
// ─────────────────────────────────────────────────────────────────────────────
module swirl_gears(rot) {
    // Gears visible around the swirl cutouts in pic_4
    translate([IW*0.32, IH*0.75, Z_WIND_PATH+5])
    rotate([0, 0, rot]) gear(22, 25, 4, 5);
    
    translate([IW*0.55, IH*0.82, Z_WIND_PATH+5])
    rotate([0, 0, -rot*1.1]) gear(18, 20, 4, 4);
    
    translate([IW*0.48, IH*0.58, Z_WIND_PATH+5])
    rotate([0, 0, rot*0.9]) gear(16, 18, 4, 4);
}

// ─────────────────────────────────────────────────────────────────────────────
// GEARS CLUSTER - Near moon
// ─────────────────────────────────────────────────────────────────────────────
module moon_gears(rot) {
    translate([IW*0.72, IH*0.72, Z_MOON-3])
    rotate([0, 0, rot]) gear(20, 22, 4, 5);
    
    translate([IW*0.78, IH*0.58, Z_MOON-3])
    rotate([0, 0, -rot*1.2]) gear(16, 18, 4, 4);
    
    translate([IW*0.68, IH*0.62, Z_MOON-3])
    rotate([0, 0, rot*0.8]) gear(14, 16, 3, 3);
}

// ─────────────────────────────────────────────────────────────────────────────
// OCEAN WAVE MECHANISM (visible gears, lower right)
// ─────────────────────────────────────────────────────────────────────────────
module ocean_mechanism(rot) {
    translate([IW*0.85, IH*0.08, Z_OCEAN_MECHANISM]) {
        rotate([0, 0, rot]) gear(24, 28, 5, 5);
        translate([35, 5, 0]) rotate([0, 0, -rot*1.15]) gear(20, 22, 5, 4);
        translate([18, -20, 2]) rotate([0, 0, rot*1.4]) gear(14, 16, 4, 3);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRAME
// ─────────────────────────────────────────────────────────────────────────────
module frame() {
    color(C_FRAME)
    difference() {
        cube([W, H, 12]);
        translate([FW, FW, -1])
        cube([IW, IH, 14]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// ─── LAYER 0: SKY BACKGROUND ───
color(C_SKY, 0.7)
translate([FW, FW, Z_BACK])
cube([IW, IH, 3]);

// ─── LAYER 1: GEARS (behind everything) ───
translate([FW, FW, 0])
cliff_gears(gear_rot);

// ─── LAYER 2: CRESCENT MOON (left side, per pic_4) ───
translate([FW + IW*0.12, FW + IH*0.72, Z_CRESCENT_MOON])
crescent_moon();

// ─── LAYER 3: SWIRL DISCS (behind wind path holes) ───
// Large swirl (left-center)
translate([FW + IW*0.38, FW + IH*0.62, Z_SWIRL_DISCS])
swirl_disc(32, swirl_large_rot, 3);

// Small swirl (right-center)  
translate([FW + IW*0.58, FW + IH*0.55, Z_SWIRL_DISCS])
swirl_disc(24, swirl_small_rot, 3);

// ─── LAYER 4: MOON (far right) ───
translate([FW + IW*0.88, FW + IH*0.70, Z_MOON])
moon_assembly(moon_rot);

// ─── LAYER 5: WIND PATH (your traced shape) ───
translate([FW, FW, Z_WIND_PATH])
wind_path_placed();

// ─── SWIRL AREA GEARS ───
translate([FW, FW, 0])
swirl_gears(gear_rot);

// ─── MOON AREA GEARS ───
translate([FW, FW, 0])
moon_gears(gear_rot);

// ─── LAYER 6: CLIFF ───
translate([FW, FW, Z_CLIFF])
cliff();

// ─── LAYER 7: LIGHTHOUSE ───
translate([FW + IW*0.18, FW + IH*0.50, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_rot);

// ─── LAYER 8-10: CLIFF WAVES (3 layers, your traced shapes) ───
translate([FW, FW, Z_CLIFF_WAVE_1])
cliff_wave_1_placed(wave_drift);

translate([FW, FW, Z_CLIFF_WAVE_2])
cliff_wave_2_placed(wave_drift * 0.7);

translate([FW, FW, Z_CLIFF_WAVE_3])
cliff_wave_3_placed(wave_drift * 0.4);

// ─── LAYER 11-13: OCEAN WAVES (3 layers, your traced shapes) ───
translate([FW, FW, Z_OCEAN_WAVE_1])
ocean_wave_1_placed(wave_drift * 0.5);

translate([FW, FW, Z_OCEAN_WAVE_2])
ocean_wave_2_placed(wave_drift * 0.6);

translate([FW, FW, Z_OCEAN_WAVE_3])
ocean_wave_3_placed(wave_surge);

// ─── OCEAN MECHANISM GEARS ───
translate([FW, FW, 0])
ocean_mechanism(gear_rot);

// ─── LAYER 14: CYPRESS TREE (left side) ───
translate([FW, FW, Z_CYPRESS])
cypress_placed();

// ─── LAYER 15: FRAME (front) ───
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
// DEBUG INFO
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V28 - COMPLETE ASSEMBLY (pic_4 layout)");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "mm | Inner:", IW, "×", IH, "mm");
echo("");
echo("TRACED COMPONENTS (your SCAD files):");
echo("  Wind Path:    scale", WIND_SCALE, " | 1784mm → ", 1784*WIND_SCALE, "mm");
echo("  Cliff Waves:  scale", CLIFF_WAVE_SCALE, " | 426mm → ", 426*CLIFF_WAVE_SCALE, "mm");
echo("  Ocean Waves:  scale", OCEAN_WAVE_SCALE, " | 112mm → ", 112*OCEAN_WAVE_SCALE, "mm");
echo("  Cypress:      scale", CYPRESS_SCALE, " | 87mm → ", 87*CYPRESS_SCALE, "mm");
echo("");
echo("Z-ORDER (back to front):");
echo("  0-5:  Sky, Gears back");
echo("  8:    Crescent moon");
echo("  12:   Swirl discs");
echo("  15:   Moon");
echo("  20:   Wind path");
echo("  25:   Cliff");
echo("  28:   Lighthouse");
echo("  32-42: Cliff waves (3 layers)");
echo("  35-45: Ocean waves (3 layers)");
echo("  50:   Cypress");
echo("  65:   Frame");
echo("");
echo("ANIMATION: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
