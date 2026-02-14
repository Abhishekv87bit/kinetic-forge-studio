// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V28 - OPTIMIZED ASSEMBLY
// All updates per user specifications
// ═══════════════════════════════════════════════════════════════════════════
$fn = 32;

// COMPONENT INCLUDES
use <cliffs_wrapper.scad>
use <cliff_wave_L1_wrapper.scad>
use <cliff_wave_L2_wrapper.scad>
use <cliff_wave_L3_wrapper.scad>
use <ocean_wave_L1_wrapper.scad>
use <ocean_wave_L2_wrapper.scad>
use <ocean_wave_L3_wrapper.scad>
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
W = 350;
H = 275;
FW = 20;
IW = W - FW*2;  // 310mm
IH = H - FW*2;  // 235mm

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
swirl_rot_1 = t * 360 * 0.4;
swirl_rot_2 = -t * 360 * 0.55;
moon_rot = t * 360 * 0.25;
wave_drift = 5 * sin(t * 360);
wave_surge = 3 * sin(t * 360);
gear_rot = t * 360 * 0.35;
lighthouse_beam = t * 360 * 5;

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = "#5a4030";
C_SKY = "#4a7ab0";
C_CLIFF = "#8b7355";
C_WIND = "#3a6a9e";
C_SWIRL = "#2a5a8e";
C_WAVE_DARK = "#1a4a6a";
C_WAVE_MED = "#2a6a8a";
C_WAVE_FOAM = "#f0f0e8";
C_CYPRESS = "#1a3a1a";
C_MOON = "#f0d050";
C_GEAR = "#b8a060";
C_LIGHTHOUSE = "#d4c4a8";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS (back to front)
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_GEARS_BACK = 3;
Z_SWIRLS = 10;
Z_MOON = 12;
Z_WIND = 18;
Z_CLIFFS = 22;
Z_LIGHTHOUSE = 25;
Z_CLIFF_WAVE_1 = 28;
Z_CLIFF_WAVE_2 = 33;
Z_CLIFF_WAVE_3 = 38;
Z_OCEAN_WAVE_1 = 30;
Z_OCEAN_WAVE_2 = 35;
Z_OCEAN_WAVE_3 = 40;
Z_GEARS_FRONT = 42;
Z_CYPRESS = 48;
Z_FRAME = 55;

// ═══════════════════════════════════════════════════════════════════════════
// MODULES
// ═══════════════════════════════════════════════════════════════════════════

// GEAR - variable sizes
module gear(teeth, r, th=4) {
    tooth_h = r * 0.14;
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=r-tooth_h, h=th);
            for(i=[0:teeth-1]) rotate([0,0,i*360/teeth])
                translate([r-tooth_h,0,0]) cylinder(r=tooth_h*1.2, h=th, $fn=6);
        }
        translate([0,0,-1]) cylinder(r=r*0.15, h=th+2);
        if(r > 15) for(i=[0:4]) rotate([0,0,i*72+36])
            translate([r*0.5,0,-1]) cylinder(r=r*0.18, h=th+2);
    }
}

// SWIRL DISC
module swirl_disc(r, rot) {
    rotate([0,0,rot]) color(C_SWIRL, 0.9)
    difference() {
        cylinder(r=r, h=6);
        translate([0,0,-1]) cylinder(r=r*0.1, h=8);
        for(i=[0:2]) rotate([0,0,i*120]) translate([r*0.55,0,-1]) cylinder(r=r*0.12, h=8);
    }
}

// LIGHTHOUSE (hut on LEFT)
module lighthouse(beam_rot) {
    // Hut on LEFT side
    translate([-18, -3, 0]) color(C_LIGHTHOUSE) {
        cube([14, 10, 8]);
        translate([0, 5, 8]) rotate([90,0,90]) linear_extrude(14) polygon([[0,0],[5,4],[10,0]]);
    }
    // Tower
    color(C_LIGHTHOUSE) linear_extrude(45, scale=0.7) circle(r=8);
    // Stripes
    color("#8b6914") for(z=[6,18,30]) translate([0,0,z]) linear_extrude(4) circle(r=7-z*0.03);
    // Platform & lamp
    translate([0,0,45]) { color("#333") cylinder(r=10, h=2); }
    translate([0,0,47]) color("LightYellow", 0.7) difference() { cylinder(r=7,h=8); translate([0,0,1]) cylinder(r=6,h=9); }
    translate([0,0,52]) color("Yellow") sphere(r=3);
    // Rotating beam
    translate([0,0,50]) rotate([0,0,beam_rot]) color("Yellow", 0.5) linear_extrude(5) polygon([[0,0],[20,-1.5],[20,1.5]]);
    // Roof
    translate([0,0,55]) color("#8b4513") cylinder(r1=9, r2=2, h=7);
}

// MOON (right side)
module moon_assembly(rot) {
    color(C_MOON, 0.2) cylinder(r=50, h=2);
    translate([0,0,2]) color(C_MOON) cylinder(r=28, h=5);
    translate([0,0,2]) rotate([0,0,rot]) color(C_MOON, 0.75)
        for(r=[34,40,46]) difference() {
            cylinder(r=r+2, h=4);
            translate([0,0,-1]) cylinder(r=r-1, h=6);
            for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([55,4,6]);
        }
}

// FRAME
module frame() {
    color(C_FRAME) difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1]) cube([IW, IH, 12]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACED COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

// CLIFFS - scaled to 175×150mm from lower-left
// Original: 140×69mm, center at origin
module cliffs_placed() {
    // Scale to fit 175×150mm, position at lower-left of inner canvas
    translate([70.1 * 1.25, 34.6 * 2.17, 0])  // Offset to place corner at origin
    scale([1.25, 2.17, 1])  // 175/140=1.25, 150/69=2.17
    color(C_CLIFF)
    cliffs_shape(1);
}

// WIND PATH - left swirl at left edge, covers ~55% width
// Original: 1784×533mm centered at origin
module wind_path_placed() {
    // Scale: want ~170mm width (55% of 310), so 170/1784 ≈ 0.095
    // Position: left edge at x=0, vertical center in upper area
    translate([892 * 0.095, IH * 0.72, 0])  // Left edge at canvas left
    scale([0.095, 0.095, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// CLIFF WAVES - touching bottom frame edge
// Original: ~426×149mm centered
module cliff_wave_1_placed(drift) {
    translate([IW * 0.28 + drift, 45.6 * 0.4, 0])  // Bottom at y=0
    scale([0.40, 0.40, 1])
    color(C_WAVE_DARK) cliff_wave_L1(1);
}

module cliff_wave_2_placed(drift) {
    translate([IW * 0.30 + drift*0.7, 65.5 * 0.38, 0])
    scale([0.38, 0.38, 1])
    color(C_WAVE_MED) cliff_wave_L2(1);
}

module cliff_wave_3_placed(drift) {
    translate([IW * 0.25 + drift*0.4, 88.9 * 0.32, 0])
    scale([0.32, 0.32, 1])
    color(C_WAVE_FOAM) cliff_wave_L3(1);
}

// OCEAN WAVES - same height (elevated from bottom)
// Original: ~112×31mm centered
module ocean_wave_1_placed(drift) {
    translate([IW * 0.65 + drift*0.3, IH * 0.12, 0])  // Keep elevated
    scale([1.5, 1.5, 1])
    color(C_WAVE_DARK) ocean_wave_L1(1);
}

module ocean_wave_2_placed(drift) {
    translate([IW * 0.68 + drift*0.5, IH * 0.14, 0])
    scale([1.45, 1.45, 1])
    color(C_WAVE_MED) ocean_wave_L2(1);
}

module ocean_wave_3_placed(surge) {
    translate([IW * 0.62, IH * 0.16 + surge, 0])
    scale([1.4, 1.4, 1])
    color(C_WAVE_FOAM) ocean_wave_L3(1);
}

// CYPRESS - frontmost, base at bottom edge
// Original: 87×161mm
module cypress_placed() {
    translate([IW * 0.08, 112.6 * 0.9, 0])  // Base at bottom
    scale([0.9, 0.9, 1])
    color(C_CYPRESS) cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM RIGHT GEARS - spread out, different sizes
// ═══════════════════════════════════════════════════════════════════════════
module bottom_right_gears(rot) {
    // Large gear
    translate([IW*0.72, IH*0.06, Z_GEARS_BACK])
    rotate([0,0,rot]) gear(28, 30, 5);
    
    // Medium-large
    translate([IW*0.88, IH*0.10, Z_GEARS_BACK+2])
    rotate([0,0,-rot*0.9]) gear(24, 26, 5);
    
    // Medium
    translate([IW*0.78, IH*0.18, Z_GEARS_BACK+4])
    rotate([0,0,rot*1.1]) gear(20, 22, 4);
    
    // Small-medium
    translate([IW*0.95, IH*0.04, Z_GEARS_BACK+1])
    rotate([0,0,-rot*1.3]) gear(18, 20, 4);
    
    // Small
    translate([IW*0.65, IH*0.02, Z_GEARS_BACK+3])
    rotate([0,0,rot*1.5]) gear(14, 16, 3);
    
    // Tiny
    translate([IW*0.85, IH*0.22, Z_GEARS_BACK+5])
    rotate([0,0,-rot*1.8]) gear(12, 13, 3);
    
    // Extra small
    translate([IW*0.92, IH*0.16, Z_GEARS_BACK+6])
    rotate([0,0,rot*2]) gear(10, 11, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// SKY BACKGROUND
color(C_SKY, 0.7) translate([FW, FW, Z_SKY]) cube([IW, IH, 2]);

// BACK GEARS (under cliffs)
translate([FW + 20, FW + IH*0.15, Z_GEARS_BACK]) rotate([0,0,gear_rot]) gear(26, 28, 4);
translate([FW + 55, FW + IH*0.08, Z_GEARS_BACK+2]) rotate([0,0,-gear_rot*0.85]) gear(22, 24, 4);
translate([FW + 35, FW + IH*0.25, Z_GEARS_BACK+3]) rotate([0,0,gear_rot*1.2]) gear(18, 20, 4);

// SWIRL DISCS (inside wind path cutouts)
// Left swirl - at left edge of wind path
translate([FW + IW*0.18, FW + IH*0.68, Z_SWIRLS])
swirl_disc(28, swirl_rot_1);

// Right swirl - center-ish
translate([FW + IW*0.38, FW + IH*0.58, Z_SWIRLS])
swirl_disc(22, swirl_rot_2);

// MOON (right side only - no moon on left)
translate([FW + IW*0.82, FW + IH*0.72, Z_MOON])
moon_assembly(moon_rot);

// WIND PATH (left ~55% of sky)
translate([FW, FW, Z_WIND])
wind_path_placed();

// CLIFFS (lower-left, 175×150mm)
translate([FW, FW, Z_CLIFFS])
cliffs_placed();

// LIGHTHOUSE (on cliff, hut on LEFT)
translate([FW + 85, FW + 95, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_beam);

// CLIFF WAVES (touching bottom edge)
translate([FW, FW, Z_CLIFF_WAVE_1]) cliff_wave_1_placed(wave_drift);
translate([FW, FW, Z_CLIFF_WAVE_2]) cliff_wave_2_placed(wave_drift*0.7);
translate([FW, FW, Z_CLIFF_WAVE_3]) cliff_wave_3_placed(wave_drift*0.4);

// OCEAN WAVES (elevated, same height as before)
translate([FW, FW, Z_OCEAN_WAVE_1]) ocean_wave_1_placed(wave_drift*0.5);
translate([FW, FW, Z_OCEAN_WAVE_2]) ocean_wave_2_placed(wave_drift*0.6);
translate([FW, FW, Z_OCEAN_WAVE_3]) ocean_wave_3_placed(wave_surge);

// BOTTOM RIGHT GEARS (spread out, different sizes)
translate([FW, FW, 0])
bottom_right_gears(gear_rot);

// CYPRESS (FRONTMOST - highest Z, base at bottom)
translate([FW, FW, Z_CYPRESS])
cypress_placed();

// FRAME
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
echo("STARRY NIGHT V28 - OPTIMIZED");
echo("Canvas:", W, "×", H, "| Inner:", IW, "×", IH);
echo("Cliffs: 175×150mm from lower-left");
echo("Wind path: Left ~55% of sky");
echo("Cypress: Frontmost at Z=", Z_CYPRESS);
echo("Animation: View > Animate | FPS=30, Steps=360");
