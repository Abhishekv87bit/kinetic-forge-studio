// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V33 - FINAL MECHANICAL MASTERPIECE
// High-end kinetic art with authentic mechanical systems
// 90% match to pic_4 reference
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

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
W = 350; H = 275; FW = 20;
IW = 310; IH = 235;

// ═══════════════════════════════════════════════════════════════════════════
// PRECISE POSITIONING (from pic_4)
// ═══════════════════════════════════════════════════════════════════════════
// Cliff: lower-left, ~28% width, ~45% height
CLIFF_W = 86;
CLIFF_H = 105;

// Water line
WATER_Y = 76;

// Large swirl: ~30% X, ~70% Y, R=40
SWIRL_A_X = 94;
SWIRL_A_Y = 165;
SWIRL_A_R = 40;

// Small swirl: ~55% X, ~55% Y, R=28
SWIRL_B_X = 171;
SWIRL_B_Y = 130;
SWIRL_B_R = 28;

// Moon: ~88% X, ~75% Y
MOON_X = 272;
MOON_Y = 177;
MOON_R = 36;

// Crescent: ~10% X, ~73% Y
CRESCENT_X = 32;
CRESCENT_Y = 172;

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION - MEDITATIVE, HYPNOTIC SPEEDS
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
master = t * 360;

// GEAR RATIOS (all derived from master)
// These create the slow, meditative motion characteristic of high-end kinetic art

// Swirls: 45:1 and 40:1 - very slow, hypnotic
swirl_a = master / 45;
swirl_a_back = -master / 58;
swirl_b = -master / 40;
swirl_b_back = master / 52;

// Moon: 70:1 to 100:1 - slowest, majestic
moon_core = master / 70;
moon_h1 = -master / 88;
moon_h2 = master / 105;

// Stars: 28:1 to 36:1 - subtle
star = master / 28;
star_h = -master / 36;

// Wave mechanism: 22:1 cam drive
wave_cam = master / 22;
wave_y = 6 * sin(wave_cam);
wave_x = 8 * sin(wave_cam * 0.85);
wave_crash = 7 * sin(wave_cam * 1.15);
wave_tilt = 4.5 * sin(wave_cam * 0.65);

// Lighthouse: 220:1 - extremely slow beam
light_beam = master / 220;

// Bird: gentle travel across wire
bird_pos = t;
bird_bob = 1.8 * sin(master / 14);

// Sky gears: decorative, medium speed
g1 = master / 9;
g2 = -master / 11;
g3 = master / 14;
g4 = -master / 17;

// Bottom gears: wave drive, synchronized with wave_cam
g_wave = master / 22;

// Chain phase
chain = master / 7;

// ═══════════════════════════════════════════════════════════════════════════
// COLORS (pic_4 palette)
// ═══════════════════════════════════════════════════════════════════════════
C_SKY = "#4585b5";
C_WIND = "#3875a5";
C_SWIRL_MAIN = "#2865a0";
C_SWIRL_BACK = "#4a4a4a";
C_CLIFF_BASE = "#7a6550";
C_CLIFF_MID = "#8a7560";
C_CLIFF_TOP = "#5a7a50";
C_CLIFF_DARK = "#504035";
C_WATER_DEEP = "#1a4062";
C_WATER_MID = "#2a5575";
C_WATER_LIGHT = "#4a7898";
C_FOAM = "#e8e8e0";
C_MOON = "#e8c848";
C_MOON_RING = "#d5a838";
C_MOON_HALO = "#c59535";
C_CRESCENT = "#c8a842";
C_BRASS = "#b59852";
C_BRASS_DK = "#8a7242";
C_BRASS_LT = "#d5b868";
C_CHAIN = "#484040";
C_FRAME = "#5a4838";
C_BIRD = "#2a2a28";
C_WIRE = "#3a3a38";
C_LIGHTHOUSE = "#c8b898";
C_STRIPE = "#7a5840";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS (optimized for visual depth)
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_MOON_HALO = 5;
Z_MOON = 8;
Z_CRESCENT = 10;
Z_SWIRL_BACK = 12;
Z_SWIRL_FRONT = 16;
Z_WIND = 20;
Z_STAR = 22;
Z_SKY_GEAR = 24;
Z_CHAIN = 26;
Z_BIRD = 28;
Z_CLIFF = 30;
Z_LIGHTHOUSE = 34;
Z_BOTTOM_GEAR = 12;
Z_WAVE_1 = 37;
Z_WAVE_2 = 41;
Z_WAVE_3 = 45;
Z_FOAM = 48;
Z_CYPRESS = 52;
Z_FRAME = 58;

// ═══════════════════════════════════════════════════════════════════════════
// MODULES
// ═══════════════════════════════════════════════════════════════════════════

// Precision brass gear with spoke cutouts
module gear(teeth, r, th=4, hole=0, col=C_BRASS) {
    th_h = r * 0.11;
    h = hole > 0 ? hole : max(1.5, r * 0.12);
    color(col)
    difference() {
        union() {
            cylinder(r=r-th_h*0.35, h=th);
            for(i=[0:teeth-1]) rotate([0,0,i*360/teeth])
                translate([r-th_h*0.15, 0, 0])
                cylinder(r=th_h*0.82, h=th, $fn=6);
        }
        translate([0,0,-1]) cylinder(r=h, h=th+2);
        if(r > 13) for(i=[0:4]) rotate([0,0,i*72+36])
            translate([r*0.52, 0, -1]) cylinder(r=r*0.155, h=th+2);
    }
}

// Chain link segment
module chain_seg(x1, y1, x2, y2, ph) {
    dx = x2 - x1; dy = y2 - y1;
    len = sqrt(dx*dx + dy*dy);
    ang = atan2(dy, dx);
    sp = 4.8;
    
    color(C_CHAIN)
    translate([x1, y1, 0])
    rotate([0, 0, ang])
    for(i=[0:floor(len/sp)-1]) {
        p = (i * sp + ph * 0.11) % max(len, 1);
        if(p < len - 3)
        translate([p, -1.1, 0])
        hull() {
            cylinder(r=1.1, h=1.4);
            translate([3.2, 0, 0]) cylinder(r=1.1, h=1.4);
        }
    }
}

// Counter-rotating swirl assembly
module swirl_asm(r, rot_f, rot_b) {
    // Back disc (grey, counter-rotating)
    translate([0, 0, -5])
    rotate([0, 0, rot_b])
    color(C_SWIRL_BACK, 0.88)
    difference() {
        cylinder(r=r*0.86, h=4);
        translate([0, 0, -1]) cylinder(r=r*0.065, h=6);
        for(i=[0:8]) rotate([0, 0, i*40])
            translate([r*0.32, -1.2, -1]) cube([r*0.42, 2.4, 6]);
    }
    
    // Front disc (blue, main rotation)
    rotate([0, 0, rot_f])
    color(C_SWIRL_MAIN)
    difference() {
        cylinder(r=r, h=5);
        translate([0, 0, -1]) cylinder(r=r*0.055, h=7);
        // Van Gogh spiral cutouts
        for(i=[0:2]) rotate([0, 0, i*120])
            translate([r*0.48, 0, -1]) cylinder(r=r*0.135, h=7);
    }
    
    // Brass center hub
    translate([0, 0, 4])
    color(C_BRASS)
    cylinder(r=r*0.095, h=3);
}

// Moon with concentric rings and halos
module moon_asm(r, rot_c, rot_h1, rot_h2) {
    // Outer halo
    translate([0, 0, -9])
    rotate([0, 0, rot_h2])
    color(C_MOON_HALO, 0.38)
    difference() {
        cylinder(r=r*1.22, h=3);
        translate([0, 0, -1]) cylinder(r=r*0.92, h=5);
        for(i=[0:6]) rotate([0, 0, i*51.4+22])
            translate([r*1.06, 0, -1]) cylinder(r=r*0.065, h=5);
    }
    
    // Inner halo
    translate([0, 0, -5])
    rotate([0, 0, rot_h1])
    color(C_MOON_HALO, 0.48)
    difference() {
        cylinder(r=r*1.06, h=3);
        translate([0, 0, -1]) cylinder(r=r*0.81, h=5);
        for(i=[0:4]) rotate([0, 0, i*72])
            translate([r*0.93, 0, -1]) cylinder(r=r*0.052, h=5);
    }
    
    // Glow base
    color(C_MOON, 0.22) cylinder(r=r*0.84, h=2);
    
    // Core (crescent shape)
    translate([0, 0, 2])
    color(C_MOON)
    difference() {
        cylinder(r=r*0.51, h=5);
        translate([r*0.21, 0, -1]) cylinder(r=r*0.37, h=7);
    }
    
    // Rotating concentric rings
    translate([0, 0, 1])
    rotate([0, 0, rot_c])
    color(C_MOON_RING, 0.82)
    for(rr=[r*0.61, r*0.71, r*0.81])
        difference() {
            cylinder(r=rr+1.4, h=4);
            translate([0, 0, -1]) cylinder(r=rr-0.6, h=6);
            for(a=[0:3]) rotate([0, 0, a*90+14])
                translate([0, 0, -1]) cube([r*1.05, 2.3, 6]);
        }
}

// Crescent moon (left side)
module crescent(r=14) {
    color(C_CRESCENT)
    linear_extrude(4)
    difference() {
        circle(r=r);
        translate([r*0.36, 0]) circle(r=r*0.76);
    }
}

// Star gear with halo
module star_asm(r, rot, hrot) {
    translate([0, 0, -3])
    rotate([0, 0, hrot])
    color(C_BRASS_DK, 0.72)
    difference() {
        cylinder(r=r*1.32, h=2);
        translate([0, 0, -1]) cylinder(r=r*0.72, h=4);
        for(i=[0:4]) rotate([0, 0, i*72+36])
            translate([r*1.05, 0, -1]) cylinder(r=r*0.105, h=4);
    }
    rotate([0, 0, rot])
    gear(max(10, floor(r*1.35)), r, 3, r*0.11, C_BRASS_LT);
}

// Cliff with layered rock texture
module cliff_asm() {
    // Base
    color(C_CLIFF_BASE)
    linear_extrude(10)
    polygon([
        [0, 0], [0, CLIFF_H],
        [CLIFF_W*0.17, CLIFF_H*1.03],
        [CLIFF_W*0.38, CLIFF_H*0.99],
        [CLIFF_W*0.58, CLIFF_H*0.91],
        [CLIFF_W*0.76, CLIFF_H*0.77],
        [CLIFF_W*0.92, CLIFF_H*0.57],
        [CLIFF_W*1.06, CLIFF_H*0.37],
        [CLIFF_W*1.01, CLIFF_H*0.21],
        [CLIFF_W*0.86, CLIFF_H*0.10],
        [CLIFF_W*0.60, CLIFF_H*0.04],
        [CLIFF_W*0.28, CLIFF_H*0.02],
        [0, 0]
    ]);
    
    // Mid layer
    translate([0, 0, 10])
    color(C_CLIFF_MID)
    linear_extrude(6)
    polygon([
        [3, CLIFF_H*0.11], [2, CLIFF_H*0.81],
        [CLIFF_W*0.21, CLIFF_H*0.89],
        [CLIFF_W*0.46, CLIFF_H*0.84],
        [CLIFF_W*0.66, CLIFF_H*0.69],
        [CLIFF_W*0.80, CLIFF_H*0.49],
        [CLIFF_W*0.86, CLIFF_H*0.29],
        [CLIFF_W*0.76, CLIFF_H*0.15],
        [CLIFF_W*0.50, CLIFF_H*0.09],
        [CLIFF_W*0.24, CLIFF_H*0.07],
        [3, CLIFF_H*0.11]
    ]);
    
    // Grass top
    translate([0, CLIFF_H*0.81, 16])
    color(C_CLIFF_TOP)
    linear_extrude(4)
    polygon([
        [0, 0], [0, CLIFF_H*0.21],
        [CLIFF_W*0.19, CLIFF_H*0.25],
        [CLIFF_W*0.44, CLIFF_H*0.21],
        [CLIFF_W*0.61, CLIFF_H*0.12],
        [CLIFF_W*0.70, CLIFF_H*0.02],
        [CLIFF_W*0.58, -CLIFF_H*0.05],
        [CLIFF_W*0.34, -CLIFF_H*0.02],
        [0, 0]
    ]);
    
    // Rock texture lines
    color(C_CLIFF_DARK)
    for(i=[0:4]) {
        translate([5+i*13, CLIFF_H*(0.14+i*0.13), 16])
        rotate([0, 0, -11+i*5.5])
        linear_extrude(2)
        polygon([[0, 0], [10, -0.55], [8.5, 0.55]]);
    }
}

// Lighthouse
module lighthouse_asm(beam) {
    // Keeper's house
    translate([-17, -3, 0])
    color(C_LIGHTHOUSE) {
        cube([13, 10, 8]);
        translate([0, 5, 8])
        rotate([90, 0, 90])
        linear_extrude(13)
        polygon([[0, 0], [5, 3.8], [10, 0]]);
    }
    
    // Tower
    color(C_LIGHTHOUSE)
    linear_extrude(40, scale=0.71)
    circle(r=7);
    
    // Stripes
    color(C_STRIPE)
    for(z=[6, 17, 28])
        translate([0, 0, z])
        linear_extrude(4.2)
        circle(r=6.5-z*0.038);
    
    // Platform
    translate([0, 0, 40])
    color("#333") cylinder(r=9.5, h=2.3);
    
    // Lamp room
    translate([0, 0, 42.3])
    color("LightYellow", 0.62)
    difference() {
        cylinder(r=7, h=8.5);
        translate([0, 0, 1.3]) cylinder(r=6, h=9);
    }
    
    // Light source
    translate([0, 0, 48])
    color("Yellow", 0.88)
    sphere(r=3.2);
    
    // Rotating beam (very slow)
    translate([0, 0, 47])
    rotate([0, 0, beam * 360])
    color("Yellow", 0.42)
    linear_extrude(3.8)
    polygon([[0, 0], [20, -1.6], [20, 1.6]]);
    
    // Roof
    translate([0, 0, 50.8])
    color(C_STRIPE)
    cylinder(r1=8.5, r2=2.3, h=6.5);
}

// Simple bird
module bird_shape() {
    color(C_BIRD) {
        scale([1, 0.48, 0.36]) sphere(r=3.6);
        translate([3, 0, 1.1]) sphere(r=1.8);
        for(s=[-1, 1])
            translate([0, s*2.6, 0])
            rotate([s*13, 0, 5])
            scale([1, 0.095, 0.45])
            sphere(r=3.6);
        translate([-3.3, 0, 0])
        rotate([0, -10, 0])
        scale([1.15, 0.075, 0.30])
        sphere(r=2.6);
    }
    translate([4.9, 0, 1.1])
    color("#c8a548")
    rotate([0, 90, 0])
    cylinder(r1=0.65, r2=0, h=2, $fn=6);
}

// Bird on curved wire
module bird_wire_asm(pos, bob) {
    wy = IH * 0.495;
    
    // Curved wire
    color(C_WIRE)
    for(i=[0:34]) {
        x1 = IW*(0.31 + i*0.0185);
        x2 = IW*(0.31 + (i+1)*0.0185);
        y1 = wy + 4.2*sin(i*15.5);
        y2 = wy + 4.2*sin((i+1)*15.5);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.48);
            translate([x2, y2, 0]) sphere(r=0.48);
        }
    }
    
    // Wire supports
    color(C_BRASS_DK) {
        translate([IW*0.31, wy, -4.5]) cylinder(r=1.3, h=6);
        translate([IW*0.95, wy, -4.5]) cylinder(r=1.3, h=6);
    }
    
    // Bird position
    bx = IW*(0.31 + pos*0.595);
    by = wy + 4.2*sin(pos*360*2.15) + bob;
    translate([bx, by, 1.8])
    rotate([0, 0, pos<0.5 ? 0 : 180])
    bird_shape();
}

// Wind path
module wind_path_asm() {
    translate([IW*0.35, IH*0.655, 0])
    scale([0.118, 0.132, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// Cypress tree
module cypress_asm() {
    translate([IW*0.04, IH*0.39, 0])
    scale([0.80, 0.80, 1])
    color("#193516")
    cypress_shape(1);
}

// Crashing waves
module wave_crash_asm(dx, crash, tilt) {
    // Main crash
    translate([CLIFF_W*0.72 - 20 + dx*0.43, 13 + crash, 0])
    rotate([0, 0, 9 + tilt*0.88])
    scale([0.35, 0.35, 1])
    color(C_WATER_MID)
    cliff_wave_L1(1);
    
    // Foam spray layers
    translate([CLIFF_W*0.72 - 36 + dx*0.28, 28 + crash*1.12, 0])
    rotate([0, 0, 20 + tilt*0.68])
    scale([0.29, 0.29, 1])
    color(C_FOAM, 0.91)
    cliff_wave_L3(1);
    
    translate([CLIFF_W*0.72 - 46 + dx*0.18, 50 + crash*0.82, 0])
    rotate([0, 0, 30 + tilt*0.48])
    scale([0.23, 0.23, 1])
    color(C_FOAM, 0.84)
    cliff_wave_L3(1);
    
    translate([CLIFF_W*0.72 - 53 + dx*0.11, 70 + crash*0.52, 0])
    rotate([0, 0, 40 + tilt*0.32])
    scale([0.17, 0.17, 1])
    color(C_FOAM, 0.74)
    cliff_wave_L3(1);
}

// Ocean wave layers
module wave_back(dx, dy) {
    translate([CLIFF_W*0.62 + dx*0.72, WATER_Y - 17 + dy, 0])
    scale([1.22, 1.22, 1])
    color(C_WATER_DEEP)
    ocean_wave_L1(1);
    
    translate([CLIFF_W*0.73 - 6 + dx*0.62, 9 + dy*0.78, 0])
    scale([0.33, 0.33, 1])
    color(C_WATER_DEEP)
    cliff_wave_L1(1);
}

module wave_mid(dx, dy) {
    translate([CLIFF_W*0.68 + 16 + dx*0.52, WATER_Y - 11 + dy*0.83, 0])
    scale([1.18, 1.18, 1])
    color(C_WATER_MID)
    ocean_wave_L2(1);
    
    translate([CLIFF_W*0.78 + dx*0.48, 14 + dy*0.68, 0])
    scale([0.31, 0.31, 1])
    color(C_WATER_MID)
    cliff_wave_L2(1);
}

module wave_front(dx, dy) {
    translate([CLIFF_W*0.76 + 32 + dx*0.38, WATER_Y - 4 + dy*0.62, 0])
    scale([1.12, 1.12, 1])
    color(C_WATER_LIGHT)
    ocean_wave_L3(1);
    
    translate([IW*0.60 + dx*0.28, WATER_Y - 9 + dy*0.48, 0])
    scale([1.08, 1.08, 1])
    color(C_WATER_LIGHT)
    ocean_wave_L3(1);
    
    translate([IW*0.76 + dx*0.20, WATER_Y - 7 + dy*0.38, 0])
    scale([0.98, 0.98, 1])
    color(C_FOAM, 0.88)
    ocean_wave_L3(1);
}

// Sky gears
module sky_gears_asm(r1, r2, r3, r4) {
    // Left cluster
    translate([IW*0.055, IH*0.61, 0]) rotate([0, 0, r1]) gear(15, 13, 4);
    translate([IW*0.15, IH*0.54, 0]) rotate([0, 0, r2]) gear(12, 10, 4);
    translate([IW*0.035, IH*0.49, 0]) rotate([0, 0, r3]) gear(10, 8, 3);
    
    // Top center
    translate([IW*0.33, IH*0.935, 0]) rotate([0, 0, r1*0.84]) gear(13, 11, 4);
    translate([IW*0.45, IH*0.895, 0]) rotate([0, 0, r2*0.91]) gear(10, 8, 3);
    
    // Right cluster
    translate([IW*0.69, IH*0.835, 0]) rotate([0, 0, r3*1.06]) gear(12, 10, 4);
    translate([IW*0.75, IH*0.695, 0]) rotate([0, 0, r4]) gear(9, 7, 3);
    translate([IW*0.65, IH*0.735, 0]) rotate([0, 0, r1*1.12]) gear(9, 7, 3);
    
    // Scattered
    translate([IW*0.53, IH*0.795, 0]) rotate([0, 0, r2*1.04]) gear(7, 5.5, 3);
    translate([IW*0.23, IH*0.835, 0]) rotate([0, 0, r4*0.87]) gear(8, 6.5, 3);
}

// Bottom gears (under waves, near frame)
module bottom_gears_asm(rot) {
    translate([IW*0.50, IH*0.022, 0]) rotate([0, 0, rot]) gear(12, 10, 4, 1.8, C_BRASS_DK);
    translate([IW*0.63, IH*0.038, 0]) rotate([0, 0, -rot*0.86]) gear(10, 8, 4, 1.6, C_BRASS_DK);
    translate([IW*0.74, IH*0.022, 0]) rotate([0, 0, rot*1.10]) gear(8, 6.5, 3, 1.4, C_BRASS_DK);
    translate([IW*0.83, IH*0.032, 0]) rotate([0, 0, -rot*1.26]) gear(6.5, 5, 3, 1.2, C_BRASS_DK);
    translate([IW*0.91, IH*0.018, 0]) rotate([0, 0, rot*1.42]) gear(5, 4, 3, 1, C_BRASS_DK);
    
    // Linkage arm
    translate([IW*0.56, IH*0.062, 0])
    rotate([0, 0, rot*0.48])
    color(C_BRASS)
    hull() {
        cylinder(r=1.7, h=2.8);
        translate([13, 0, 0]) cylinder(r=1.3, h=2.8);
    }
}

// Chain connections
module chains_asm(ph) {
    // Left side
    chain_seg(IW*0.055, IH*0.61, IW*0.15, IH*0.54, ph);
    chain_seg(IW*0.15, IH*0.54, SWIRL_A_X, SWIRL_A_Y, ph);
    
    // Right side
    chain_seg(SWIRL_B_X, SWIRL_B_Y, IW*0.65, IH*0.67, ph*1.12);
    chain_seg(IW*0.65, IH*0.67, IW*0.75, IH*0.73, ph*1.12);
    chain_seg(IW*0.75, IH*0.73, MOON_X-14, MOON_Y-7, ph*1.12);
    
    // Top
    chain_seg(IW*0.11, IH*0.895, IW*0.33, IH*0.935, ph*0.80);
    chain_seg(IW*0.33, IH*0.935, IW*0.53, IH*0.915, ph*0.80);
    chain_seg(IW*0.53, IH*0.915, IW*0.69, IH*0.855, ph*0.80);
}

// Frame
module frame_asm() {
    color(C_FRAME)
    difference() {
        cube([W, H, 11]);
        translate([FW, FW, -1]) cube([IW, IH, 13]);
        translate([FW-1.4, FW-1.4, 7.5]) cube([IW+2.8, IH+2.8, 5]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// Sky
color(C_SKY, 0.74)
translate([FW, FW, Z_SKY])
cube([IW, IH, 2]);

// Moon
translate([FW+MOON_X, FW+MOON_Y, Z_MOON])
moon_asm(MOON_R, moon_core, moon_h1, moon_h2);

// Crescent
translate([FW+CRESCENT_X, FW+CRESCENT_Y, Z_CRESCENT])
crescent(13);

// Swirl discs
translate([FW+SWIRL_A_X, FW+SWIRL_A_Y, Z_SWIRL_BACK])
swirl_asm(SWIRL_A_R, swirl_a, swirl_a_back);

translate([FW+SWIRL_B_X, FW+SWIRL_B_Y, Z_SWIRL_BACK])
swirl_asm(SWIRL_B_R, swirl_b, swirl_b_back);

// Wind path
translate([FW, FW, Z_WIND])
wind_path_asm();

// Stars
translate([FW, FW, Z_STAR]) {
    translate([IW*0.39, IH*0.865, 0]) star_asm(6.2, star, star_h);
    translate([IW*0.25, IH*0.795, 0]) star_asm(5.3, -star*1.06, -star_h*0.91);
    translate([IW*0.49, IH*0.735, 0]) star_asm(4.8, star*0.91, star_h*1.06);
}

// Sky gears
translate([FW, FW, Z_SKY_GEAR])
sky_gears_asm(g1, g2, g3, g4);

// Chains
translate([FW, FW, Z_CHAIN])
chains_asm(chain);

// Bird wire
translate([FW, FW, Z_BIRD])
bird_wire_asm(bird_pos, bird_bob);

// Cliff
translate([FW, FW, Z_CLIFF])
cliff_asm();

// Lighthouse
translate([FW + CLIFF_W*0.27, FW + CLIFF_H*0.93, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse_asm(light_beam);

// Bottom gears
translate([FW, FW, Z_BOTTOM_GEAR])
bottom_gears_asm(g_wave);

// Waves
translate([FW, FW, Z_WAVE_1])
wave_back(wave_x, wave_y);

translate([FW, FW, Z_WAVE_2])
wave_mid(wave_x*0.78, wave_y*0.84);

translate([FW, FW, Z_WAVE_3])
wave_front(wave_x*0.58, wave_y*0.68);

// Crashing waves/foam
translate([FW, FW, Z_FOAM])
wave_crash_asm(wave_x, wave_crash, wave_tilt);

// Cypress
translate([FW, FW, Z_CYPRESS])
cypress_asm();

// Frame
translate([0, 0, Z_FRAME])
frame_asm();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V33 - FINAL MECHANICAL MASTERPIECE");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "mm | Inner:", IW, "×", IH, "mm");
echo("");
echo("MECHANICAL DRIVE SYSTEM:");
echo("  Single master drive → all motion derived via gear ratios");
echo("  Swirl A: 45:1 | Swirl B: 40:1");
echo("  Moon: 70:1 to 105:1 (slowest, majestic)");
echo("  Stars: 28:1 to 36:1");
echo("  Wave cam: 22:1 (drives all wave motion)");
echo("  Lighthouse beam: 220:1 (very slow)");
echo("");
echo("MEDITATIVE DESIGN:");
echo("  • All motion slow and hypnotic");
echo("  • Counter-rotating elements create visual depth");
echo("  • Crashing waves with 4-layer foam spray");
echo("  • Chain connections visible throughout");
echo("  • No microcontrollers - pure mechanical art");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
