// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V29 - COMPLETE MECHANICAL ASSEMBLY
// All updates: dual cliffs, extended waves, stars, belts, bird wire
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

// CLIFF DIMENSIONS (updated)
CLIFF_WIDTH = 165;   // Was 175, reduced by 10mm
CLIFF_HEIGHT = 105;  // Was 150, reduced by 45mm

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
swirl_rot_1 = t * 360 * 0.4;
swirl_rot_2 = -t * 360 * 0.55;
moon_rot = t * 360 * 0.25;
moon_halo_rot = -t * 360 * 0.18;
star_rot = t * 360 * 0.6;
star_halo_rot = -t * 360 * 0.4;
wave_drift = 5 * sin(t * 360);
wave_surge = 3 * sin(t * 360);
wave_tilt = 4 * sin(t * 360);  // For tilting wave 3
gear_rot = t * 360 * 0.35;
belt_phase = t * 360;
lighthouse_beam = t * 360 * 5;
bird_bob = 3 * sin(t * 360 * 2);

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = "#5a4030";
C_SKY = "#4a7ab0";
C_CLIFF = "#8b7355";
C_CLIFF_DARK = "#6b5344";
C_ROCK = "#7a6345";
C_WIND = "#3a6a9e";
C_SWIRL = "#2a5a8e";
C_WAVE_DARK = "#1a4a6a";
C_WAVE_MED = "#2a6a8a";
C_WAVE_FOAM = "#f0f0e8";
C_CYPRESS = "#1a3a1a";
C_MOON = "#f0d050";
C_MOON_HALO = "#e8c840";
C_GEAR = "#b8a060";
C_GEAR_DARK = "#8a7040";
C_STAR = "#c0a050";
C_BELT = "#4a3a2a";
C_LIGHTHOUSE = "#d4c4a8";
C_BIRD = "#3a3a3a";
C_WIRE = "#2a2a2a";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS (back to front)
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_BELT_BACK = 2;
Z_GEARS_BACK = 4;
Z_STARS = 8;
Z_SWIRLS = 12;
Z_MOON = 14;
Z_WIND = 20;
Z_BIRD_WIRE = 23;
Z_CLIFFS = 25;
Z_LIGHTHOUSE = 28;
Z_WAVE_1 = 32;
Z_WAVE_2 = 37;
Z_WAVE_3 = 42;
Z_GEARS_FRONT = 45;
Z_CYPRESS = 50;
Z_FRAME = 58;

// ═══════════════════════════════════════════════════════════════════════════
// GEAR MODULE
// ═══════════════════════════════════════════════════════════════════════════
module gear(teeth, r, th=4, hole_r=0) {
    tooth_h = r * 0.14;
    actual_hole = hole_r > 0 ? hole_r : r * 0.15;
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=r-tooth_h, h=th);
            for(i=[0:teeth-1]) rotate([0,0,i*360/teeth])
                translate([r-tooth_h,0,0]) cylinder(r=tooth_h*1.2, h=th, $fn=6);
        }
        translate([0,0,-1]) cylinder(r=actual_hole, h=th+2);
        if(r > 12) for(i=[0:4]) rotate([0,0,i*72+36])
            translate([r*0.5,0,-1]) cylinder(r=r*0.15, h=th+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAR GEAR WITH HALO
// ═══════════════════════════════════════════════════════════════════════════
module star_gear(r, rot, halo_rot) {
    // Inner rotating gear (star)
    rotate([0,0,rot]) {
        color(C_STAR) difference() {
            cylinder(r=r, h=4);
            translate([0,0,-1]) cylinder(r=r*0.12, h=6);
            for(i=[0:4]) rotate([0,0,i*72]) translate([r*0.55,0,-1]) cylinder(r=r*0.12, h=6);
        }
        // Star points
        color(C_STAR) for(i=[0:7]) rotate([0,0,i*45])
            translate([r*0.7,0,0]) cylinder(r=r*0.15, h=4, $fn=3);
    }
    // Counter-rotating halo disc
    translate([0,0,-2]) rotate([0,0,halo_rot])
    color(C_GEAR_DARK, 0.7) difference() {
        cylinder(r=r*1.5, h=2);
        translate([0,0,-1]) cylinder(r=r*0.9, h=4);
        for(i=[0:5]) rotate([0,0,i*60+30]) translate([r*1.2,0,-1]) cylinder(r=r*0.2, h=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIRL DISC
// ═══════════════════════════════════════════════════════════════════════════
module swirl_disc(r, rot) {
    rotate([0,0,rot]) color(C_SWIRL, 0.9)
    difference() {
        cylinder(r=r, h=6);
        translate([0,0,-1]) cylinder(r=r*0.1, h=8);
        for(i=[0:2]) rotate([0,0,i*120]) translate([r*0.55,0,-1]) cylinder(r=r*0.12, h=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON ASSEMBLY WITH HALOS AND BELT
// ═══════════════════════════════════════════════════════════════════════════
module moon_assembly(rot, halo_rot) {
    // Outer counter-rotating halo
    translate([0,0,-4]) rotate([0,0,halo_rot])
    color(C_MOON_HALO, 0.4) difference() {
        cylinder(r=58, h=3);
        translate([0,0,-1]) cylinder(r=48, h=5);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([53,0,-1]) cylinder(r=4, h=5);
    }
    
    // Second halo (opposite rotation)
    translate([0,0,-2]) rotate([0,0,-halo_rot*0.7])
    color(C_MOON_HALO, 0.5) difference() {
        cylinder(r=52, h=2);
        translate([0,0,-1]) cylinder(r=42, h=4);
        for(i=[0:5]) rotate([0,0,i*60]) translate([47,0,-1]) cylinder(r=3, h=4);
    }
    
    // Glow base
    color(C_MOON, 0.2) cylinder(r=45, h=2);
    
    // Core moon
    translate([0,0,2]) color(C_MOON) cylinder(r=26, h=5);
    
    // Rotating rings
    translate([0,0,2]) rotate([0,0,rot])
    color(C_MOON, 0.8) for(r_val=[32,38,44]) difference() {
        cylinder(r=r_val+2, h=4);
        translate([0,0,-1]) cylinder(r=r_val-1, h=6);
        for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([50,3.5,6]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BELT MECHANISM
// ═══════════════════════════════════════════════════════════════════════════
module belt_segment(x1, y1, x2, y2, phase) {
    dx = x2 - x1;
    dy = y2 - y1;
    len = sqrt(dx*dx + dy*dy);
    ang = atan2(dy, dx);
    
    color(C_BELT)
    translate([x1, y1, 0])
    rotate([0, 0, ang])
    for(i=[0:floor(len/4)]) {
        offset = (i * 4 + phase * 0.1) % len;
        if(offset < len - 2)
        translate([offset, -1.5, 0]) cube([3, 3, 2]);
    }
}

module belt_pulley(r, rot) {
    rotate([0,0,rot]) color(C_GEAR_DARK) difference() {
        cylinder(r=r, h=3);
        translate([0,0,-1]) cylinder(r=r*0.3, h=5);
        for(i=[0:11]) rotate([0,0,i*30]) translate([r*0.7,0,-1]) cylinder(r=1, h=5);
    }
}

// Moon belt system
module moon_belt_system(phase) {
    // Belt path from moon to drive gears
    belt_pulley_x1 = IW*0.82;
    belt_pulley_y1 = IH*0.72;
    gear_x = IW*0.68;
    gear_y = IH*0.55;
    
    // Pulleys
    translate([belt_pulley_x1, belt_pulley_y1, 0]) belt_pulley(8, phase*0.25);
    translate([gear_x, gear_y, 0]) belt_pulley(10, -phase*0.2);
    translate([gear_x + 25, gear_y - 15, 0]) belt_pulley(6, phase*0.35);
    
    // Belt segments
    belt_segment(belt_pulley_x1, belt_pulley_y1, gear_x, gear_y, phase);
    belt_segment(gear_x, gear_y, gear_x + 25, gear_y - 15, phase);
}

// ═══════════════════════════════════════════════════════════════════════════
// DUAL CLIFFS WITH ROCKS AND CRACKS
// ═══════════════════════════════════════════════════════════════════════════
module dual_cliffs() {
    // LEFT CLIFF (larger)
    color(C_CLIFF)
    linear_extrude(height=12)
    polygon([
        [0, 0],
        [0, CLIFF_HEIGHT],
        [CLIFF_WIDTH * 0.12, CLIFF_HEIGHT * 1.02],
        [CLIFF_WIDTH * 0.25, CLIFF_HEIGHT * 0.98],
        [CLIFF_WIDTH * 0.38, CLIFF_HEIGHT * 0.92],
        [CLIFF_WIDTH * 0.45, CLIFF_HEIGHT * 0.85],  // Start of gap
        [CLIFF_WIDTH * 0.42, CLIFF_HEIGHT * 0.60],  // Down into gap
        [CLIFF_WIDTH * 0.35, CLIFF_HEIGHT * 0.40],
        [CLIFF_WIDTH * 0.30, CLIFF_HEIGHT * 0.25],
        [CLIFF_WIDTH * 0.25, CLIFF_HEIGHT * 0.12],
        [CLIFF_WIDTH * 0.15, CLIFF_HEIGHT * 0.05],
        [0, 0]
    ]);
    
    // RIGHT CLIFF (smaller, separated)
    color(C_CLIFF)
    translate([CLIFF_WIDTH * 0.48, 0, 0])
    linear_extrude(height=12)
    polygon([
        [0, CLIFF_HEIGHT * 0.15],
        [CLIFF_WIDTH * 0.05, CLIFF_HEIGHT * 0.35],
        [CLIFF_WIDTH * 0.08, CLIFF_HEIGHT * 0.55],
        [CLIFF_WIDTH * 0.12, CLIFF_HEIGHT * 0.72],
        [CLIFF_WIDTH * 0.18, CLIFF_HEIGHT * 0.82],
        [CLIFF_WIDTH * 0.28, CLIFF_HEIGHT * 0.75],
        [CLIFF_WIDTH * 0.38, CLIFF_HEIGHT * 0.62],
        [CLIFF_WIDTH * 0.45, CLIFF_HEIGHT * 0.45],
        [CLIFF_WIDTH * 0.50, CLIFF_HEIGHT * 0.28],
        [CLIFF_WIDTH * 0.48, CLIFF_HEIGHT * 0.12],
        [CLIFF_WIDTH * 0.35, CLIFF_HEIGHT * 0.05],
        [CLIFF_WIDTH * 0.15, CLIFF_HEIGHT * 0.08],
        [0, CLIFF_HEIGHT * 0.15]
    ]);
    
    // ROCKS IN GAP (between cliffs)
    color(C_ROCK)
    translate([CLIFF_WIDTH * 0.38, CLIFF_HEIGHT * 0.08, 0]) {
        linear_extrude(height=8) circle(r=6, $fn=5);
        translate([8, 12, 0]) linear_extrude(height=10) circle(r=5, $fn=6);
        translate([-3, 20, 0]) linear_extrude(height=6) circle(r=4, $fn=5);
        translate([12, 5, 0]) linear_extrude(height=7) circle(r=3, $fn=4);
        translate([5, 28, 0]) linear_extrude(height=5) circle(r=3.5, $fn=5);
    }
    
    // CRACKS/TEXTURE on left cliff
    color(C_CLIFF_DARK)
    for(i=[0:3]) {
        translate([5 + i*12, CLIFF_HEIGHT * (0.25 + i*0.15), 12])
        rotate([0, 0, -20 + i*10])
        linear_extrude(height=2)
        polygon([[0,0], [15,-1], [12,1]]);
    }
    
    // CRACKS on right cliff
    color(C_CLIFF_DARK)
    translate([CLIFF_WIDTH * 0.55, 0, 0])
    for(i=[0:2]) {
        translate([8 + i*8, CLIFF_HEIGHT * (0.30 + i*0.12), 12])
        rotate([0, 0, 15 - i*8])
        linear_extrude(height=2)
        polygon([[0,0], [10,-0.8], [8,0.8]]);
    }
    
    // Small rocks at base
    color(C_ROCK)
    for(i=[0:5]) {
        translate([10 + i*22, 3, 0])
        linear_extrude(height=4 + i%3)
        circle(r=2 + i%2, $fn=5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE (positioned on cliff top)
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    // Hut on LEFT side
    translate([-16, -2, 0]) color(C_LIGHTHOUSE) {
        cube([12, 9, 7]);
        translate([0, 4.5, 7]) rotate([90,0,90]) linear_extrude(12) polygon([[0,0],[4.5,3.5],[9,0]]);
    }
    // Tower
    color(C_LIGHTHOUSE) linear_extrude(40, scale=0.72) circle(r=7);
    // Stripes
    color("#8b6914") for(z=[5,15,25]) translate([0,0,z]) linear_extrude(4) circle(r=6.2-z*0.03);
    // Platform
    translate([0,0,40]) color("#333") cylinder(r=9, h=2);
    // Lamp room
    translate([0,0,42]) color("LightYellow", 0.7) difference() { cylinder(r=6,h=7); translate([0,0,1]) cylinder(r=5,h=8); }
    // Light
    translate([0,0,46]) color("Yellow") sphere(r=2.5);
    // Beam
    translate([0,0,44]) rotate([0,0,beam_rot]) color("Yellow", 0.5) linear_extrude(4) polygon([[0,0],[18,-1.2],[18,1.2]]);
    // Roof
    translate([0,0,49]) color("#8b4513") cylinder(r1=8, r2=2, h=6);
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD WIRE MECHANISM
// ═══════════════════════════════════════════════════════════════════════════
module bird(bob) {
    translate([0, bob, 0]) {
        // Body
        color(C_BIRD) scale([1, 0.6, 0.4]) sphere(r=5);
        // Head
        translate([4, 0, 1.5]) color(C_BIRD) sphere(r=2.5);
        // Beak
        translate([6.5, 0, 1.5]) color("#d4a030") rotate([0, 90, 0]) cylinder(r1=1, r2=0, h=3, $fn=8);
        // Wings
        color(C_BIRD) for(s=[-1,1]) translate([0, s*3.5, 0]) rotate([s*20, 0, 10])
            scale([1.2, 0.15, 0.6]) sphere(r=5);
        // Tail
        translate([-5, 0, 0]) color(C_BIRD) rotate([0, -15, 0]) scale([1.5, 0.1, 0.4]) sphere(r=3);
    }
}

module bird_wire_mechanism(bob) {
    // Wire across canvas
    color(C_WIRE) translate([0, IH*0.52, 0]) rotate([0, 90, 0]) cylinder(r=0.8, h=IW);
    
    // Bird on wire
    translate([IW*0.72, IH*0.52, 3]) rotate([0, 0, -5]) bird(bob);
    
    // Wire supports (small posts)
    color(C_GEAR_DARK) {
        translate([IW*0.15, IH*0.52, -5]) cylinder(r=1.5, h=6);
        translate([IW*0.85, IH*0.52, -5]) cylinder(r=1.5, h=6);
    }
    
    // Decorative wire curves
    color(C_WIRE) {
        translate([IW*0.25, IH*0.52, 0]) rotate([90, 0, 0]) 
            rotate_extrude(angle=180, $fn=16) translate([8, 0, 0]) circle(r=0.6);
        translate([IW*0.55, IH*0.52, 0]) rotate([90, 0, 0]) 
            rotate_extrude(angle=180, $fn=16) translate([6, 0, 0]) circle(r=0.6);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVES - Extended from cliff base to right edge
// ═══════════════════════════════════════════════════════════════════════════

// Wave start X (just past cliff edge)
WAVE_START_X = CLIFF_WIDTH - 20;
WAVE_END_X = IW - 5;
WAVE_WIDTH = WAVE_END_X - WAVE_START_X;

// CLIFF WAVES (scaled to 80%, tilting)
module cliff_wave_1_placed(drift) {
    translate([WAVE_START_X + drift, 5, 0])
    scale([0.32, 0.32, 1])  // 80% of 0.40
    color(C_WAVE_DARK) cliff_wave_L1(1);
}

module cliff_wave_2_placed(drift) {
    translate([WAVE_START_X + 15 + drift*0.7, 8, 0])
    scale([0.304, 0.304, 1])  // 80% of 0.38
    color(C_WAVE_MED) cliff_wave_L2(1);
}

// Wave 3 tilts toward cliff
module cliff_wave_3_placed(drift, tilt) {
    translate([WAVE_START_X + 5 + drift*0.4, 12, 0])
    rotate([0, 0, tilt * 0.8])  // Tilting motion
    scale([0.256, 0.256, 1])  // 80% of 0.32
    color(C_WAVE_FOAM) cliff_wave_L3(1);
}

// OCEAN WAVES (extended to right edge)
module ocean_wave_1_placed(drift) {
    translate([WAVE_START_X + WAVE_WIDTH*0.35 + drift*0.3, IH*0.08, 0])
    scale([1.4, 1.4, 1])
    color(C_WAVE_DARK) ocean_wave_L1(1);
}

module ocean_wave_2_placed(drift) {
    translate([WAVE_START_X + WAVE_WIDTH*0.5 + drift*0.5, IH*0.10, 0])
    scale([1.35, 1.35, 1])
    color(C_WAVE_MED) ocean_wave_L2(1);
}

module ocean_wave_3_placed(surge) {
    translate([WAVE_START_X + WAVE_WIDTH*0.65, IH*0.12 + surge, 0])
    scale([1.3, 1.3, 1])
    color(C_WAVE_FOAM) ocean_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH (20% larger, 65% of sky)
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_placed() {
    // Original scale was 0.095, +20% = 0.114
    // Position to cover 65% from left
    translate([892 * 0.114, IH * 0.72, 0])
    scale([0.114, 0.114, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS (moved 3mm right)
// ═══════════════════════════════════════════════════════════════════════════
module cypress_placed() {
    translate([IW * 0.08 + 3, 112.6 * 0.9, 0])  // +3mm right
    scale([0.9, 0.9, 1])
    color(C_CYPRESS) cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// STARS (gears with halos) - distributed in sky
// ═══════════════════════════════════════════════════════════════════════════
module all_stars(rot, halo_rot) {
    // Star positions in sky area
    translate([IW*0.15, IH*0.88, 0]) star_gear(8, rot, halo_rot);
    translate([IW*0.28, IH*0.78, 0]) star_gear(6, -rot*1.2, -halo_rot*0.9);
    translate([IW*0.42, IH*0.92, 0]) star_gear(7, rot*0.8, halo_rot*1.1);
    translate([IW*0.55, IH*0.82, 0]) star_gear(5, -rot*1.4, -halo_rot*0.8);
    translate([IW*0.35, IH*0.68, 0]) star_gear(6, rot*1.1, halo_rot*0.95);
    
    // Additional belt-driving stars near moon
    translate([IW*0.68, IH*0.90, 0]) star_gear(7, -rot*0.9, -halo_rot*1.05);
    translate([IW*0.58, IH*0.72, 0]) star_gear(5, rot*1.3, halo_rot*0.85);
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM RIGHT GEARS
// ═══════════════════════════════════════════════════════════════════════════
module bottom_right_gears(rot) {
    translate([IW*0.70, IH*0.04, Z_GEARS_BACK]) rotate([0,0,rot]) gear(26, 28, 5);
    translate([IW*0.85, IH*0.08, Z_GEARS_BACK+2]) rotate([0,0,-rot*0.9]) gear(22, 24, 5);
    translate([IW*0.75, IH*0.16, Z_GEARS_BACK+4]) rotate([0,0,rot*1.1]) gear(18, 20, 4);
    translate([IW*0.92, IH*0.03, Z_GEARS_BACK+1]) rotate([0,0,-rot*1.3]) gear(16, 18, 4);
    translate([IW*0.62, IH*0.02, Z_GEARS_BACK+3]) rotate([0,0,rot*1.5]) gear(14, 15, 3);
    translate([IW*0.88, IH*0.18, Z_GEARS_BACK+5]) rotate([0,0,-rot*1.8]) gear(11, 12, 3);
    translate([IW*0.95, IH*0.12, Z_GEARS_BACK+6]) rotate([0,0,rot*2]) gear(9, 10, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// SKY BACKGROUND
color(C_SKY, 0.7) translate([FW, FW, Z_SKY]) cube([IW, IH, 2]);

// BELT MECHANISM (behind everything)
translate([FW, FW, Z_BELT_BACK]) moon_belt_system(belt_phase);

// BACK GEARS (under cliffs)
translate([FW + 15, FW + IH*0.12, Z_GEARS_BACK]) rotate([0,0,gear_rot]) gear(24, 26, 4);
translate([FW + 48, FW + IH*0.06, Z_GEARS_BACK+2]) rotate([0,0,-gear_rot*0.85]) gear(20, 22, 4);
translate([FW + 30, FW + IH*0.22, Z_GEARS_BACK+3]) rotate([0,0,gear_rot*1.2]) gear(16, 18, 4);

// STARS (rotating gears with halos)
translate([FW, FW, Z_STARS]) all_stars(star_rot, star_halo_rot);

// SWIRL DISCS (inside wind path cutouts)
translate([FW + IW*0.20, FW + IH*0.68, Z_SWIRLS]) swirl_disc(30, swirl_rot_1);
translate([FW + IW*0.42, FW + IH*0.60, Z_SWIRLS]) swirl_disc(24, swirl_rot_2);

// MOON (right side with halos)
translate([FW + IW*0.82, FW + IH*0.75, Z_MOON]) moon_assembly(moon_rot, moon_halo_rot);

// WIND PATH (20% larger, 65% coverage)
translate([FW, FW, Z_WIND]) wind_path_placed();

// BIRD WIRE MECHANISM
translate([FW, FW, Z_BIRD_WIRE]) bird_wire_mechanism(bird_bob);

// DUAL CLIFFS
translate([FW, FW, Z_CLIFFS]) dual_cliffs();

// LIGHTHOUSE (on top of left cliff)
translate([FW + CLIFF_WIDTH * 0.22, FW + CLIFF_HEIGHT * 0.88, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_beam);

// WAVES (extended from cliff to right edge)
translate([FW, FW, Z_WAVE_1]) cliff_wave_1_placed(wave_drift);
translate([FW, FW, Z_WAVE_2]) cliff_wave_2_placed(wave_drift*0.7);
translate([FW, FW, Z_WAVE_3]) cliff_wave_3_placed(wave_drift*0.4, wave_tilt);

translate([FW, FW, Z_WAVE_1+1]) ocean_wave_1_placed(wave_drift*0.5);
translate([FW, FW, Z_WAVE_2+1]) ocean_wave_2_placed(wave_drift*0.6);
translate([FW, FW, Z_WAVE_3+1]) ocean_wave_3_placed(wave_surge);

// BOTTOM RIGHT GEARS
translate([FW, FW, 0]) bottom_right_gears(gear_rot);

// CYPRESS (FRONTMOST, moved 3mm right)
translate([FW, FW, Z_CYPRESS]) cypress_placed();

// FRAME
translate([0, 0, Z_FRAME]) frame();

// FRAME MODULE
module frame() {
    color(C_FRAME) difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1]) cube([IW, IH, 12]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V29 - MECHANICAL ASSEMBLY");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "| Inner:", IW, "×", IH);
echo("Cliffs: DUAL style,", CLIFF_WIDTH, "×", CLIFF_HEIGHT, "mm");
echo("Wind path: +20% size, 65% sky coverage");
echo("Stars: Rotating gears with counter-rotating halos");
echo("Moon: With halos and belt mechanism");
echo("Waves: Extended cliff-to-edge, cliff waves 80%");
echo("Bird wire: Restored with bobbing bird");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
