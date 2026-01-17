// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V37 - HIGH-END MECHANICAL ART
// All corrections from V36 feedback
// ═══════════════════════════════════════════════════════════════════════════
$fn = 64;

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
// CLIFF DIMENSIONS - New shape: rectangle + inverted triangle
// Rectangle: x=0 to x=100
// Inverted triangle: base at top (y=CLIFF_HEIGHT), hypotenuse toward center
// Top extends to x=165, bottom of triangle at x=100
// "Top goes 10mm further into center than bottom" 
// ═══════════════════════════════════════════════════════════════════════════
CLIFF_WIDTH = 165;   // Total width
CLIFF_RECT_WIDTH = 100;  // Rectangle portion
CLIFF_HEIGHT = 105;

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH - Shape bounds: X[-892, 892], Y[-267, 267] = 1784×533mm original
// Scale to fit canvas width, position so left edge touches X=0
// ═══════════════════════════════════════════════════════════════════════════
WIND_SCALE = 0.165;  // Scale to fit ~295mm width
WIND_ORIG_MIN_X = -892.309;
WIND_ORIG_MIN_Y = -266.834;
// After scaling, left edge at: -892.309 * 0.165 = -147.2mm
// Translate X by +147.2 to bring left edge to X=0
WIND_TRANSLATE_X = -WIND_ORIG_MIN_X * WIND_SCALE;  // 147.2mm
WIND_TRANSLATE_Y = IH * 0.55;  // Center vertically in upper portion

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH CIRCULAR CUTOUTS - As big as possible
// ═══════════════════════════════════════════════════════════════════════════
BIG_CUTOUT_X = IW * 0.24;
BIG_CUTOUT_Y = IH * 0.62;
BIG_CUTOUT_R = 42;  // Increased for bigger cutout

SMALL_CUTOUT_X = IW * 0.48;
SMALL_CUTOUT_Y = IH * 0.52;
SMALL_CUTOUT_R = 30;  // Increased for bigger cutout

// Swirl disc sizes (1.8mm gap from cutout edge)
// Big disc: +3mm diameter = +1.5mm radius
BIG_SWIRL_R = BIG_CUTOUT_R - 1.8 + 1.5;   // 41.7mm (was 36.2, now +3mm diameter)
SMALL_SWIRL_R = SMALL_CUTOUT_R - 1.8;      // 28.2mm

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS - Shape bounds: Y[-112.572, 48.404]
// To place bottom at Y=0, translate by +112.572 (after scaling)
// ═══════════════════════════════════════════════════════════════════════════
CYPRESS_SCALE = 0.82;
CYPRESS_ORIG_MIN_Y = -112.572;
// After scaling, bottom at: -112.572 * 0.82 = -92.31mm
// Translate Y by +92.31 to bring bottom to Y=0
CYPRESS_TRANSLATE_Y = -CYPRESS_ORIG_MIN_Y * CYPRESS_SCALE;  // 92.31mm

// ═══════════════════════════════════════════════════════════════════════════
// WAVE POSITIONING
// ═══════════════════════════════════════════════════════════════════════════
WAVE_ZONE_START = CLIFF_WIDTH + 15;  // Start past cliff
WAVE_ZONE_END = IW - 5;

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS - 4 gears, NOT in straight line, near right side
// ═══════════════════════════════════════════════════════════════════════════
GEAR1_X = IW * 0.55;
GEAR1_Y = IH * 0.07;
GEAR1_R = 12;

GEAR2_X = IW * 0.70;
GEAR2_Y = IH * 0.03;
GEAR2_R = 15;

GEAR3_X = IW * 0.84;
GEAR3_Y = IH * 0.08;
GEAR3_R = 10;

GEAR4_X = IW * 0.96;  // Near right corner
GEAR4_Y = IH * 0.02;  // Very close to bottom
GEAR4_R = 7;

OCEAN_WAVES_Y_BASE = max(GEAR1_Y, GEAR2_Y, GEAR3_Y, GEAR4_Y) + 15 + 5;

// ═══════════════════════════════════════════════════════════════════════════
// MECHANICAL DRIVE SYSTEM
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
master_drive = t * 360;

// Swirl rotations - BIG: CW, SMALL: CCW
swirl_rot_big = master_drive / 45;        // CW (positive)
swirl_counter_big = -master_drive / 55;
swirl_rot_small = -master_drive / 40;     // CCW (negative)
swirl_counter_small = master_drive / 50;

// Moon - 3x faster halos
moon_rot = master_drive / 70;
moon_halo_1 = -master_drive / 28;
moon_halo_2 = master_drive / 33;

// Stars - 3x faster halos
star_rot = master_drive / 30;
star_halo_rot = -master_drive / 12;

// Swirl halos - 3x faster
swirl_halo_speed = master_drive / 18;

// Wave mechanism
wave_cam = master_drive / 25;
wave_drift = 6 * sin(wave_cam);
wave_surge = 4 * sin(wave_cam * 1.2);
wave_tilt = 5 * sin(wave_cam * 0.8);
wave_crash = 7 * sin(wave_cam * 1.1);

// Gears
gear_sky_1 = master_drive / 10;
gear_sky_2 = -master_drive / 12;
gear_sky_3 = master_drive / 15;
gear_sky_4 = -master_drive / 18;
gear_bottom = master_drive / 25;

belt_phase = master_drive / 8;
lighthouse_beam = master_drive / 200;

bird_progress = t;
bird_bob = 2 * sin(master_drive / 15);

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = "#5a4030";
C_SKY = "#4a7ab0";
C_CLIFF = "#8b7355";
C_CLIFF_LAYER = "#9a8565";
C_CLIFF_GRASS = "#6a8a5a";
C_CLIFF_DARK = "#6b5344";
C_WIND = "#3a6a9e";
C_SWIRL_BLUE = "#2a5a8e";
C_SWIRL_GREY = "#555555";
C_SWIRL_GREY_DARK = "#454545";
C_WAVE_DARK = "#1a4a6a";
C_WAVE_MED = "#2a6a8a";
C_WAVE_FOAM = "#f0f0e8";
C_CYPRESS = "#1a3a1a";
C_MOON = "#f0d050";
C_MOON_HALO_A = "#e8c840";
C_MOON_HALO_B = "#d0b030";
C_GEAR = "#b8a060";
C_GEAR_DARK = "#8a7040";
C_STAR = "#c0a050";
C_CHAIN = "#454038";
C_LIGHTHOUSE = "#d4c4a8";
C_BIRD = "#2a2a2a";
C_WIRE = "#3a3a3a";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_BOTTOM_GEARS = 6;
Z_BIRD_SUPPORTS = 8;
Z_MOON_HALO_BACK = 10;
Z_MOON_HALO_FRONT = 14;
Z_MOON = 16;
Z_STARS = 18;
Z_SWIRL_HALO_BACK = 20;
Z_SWIRL_HALO_FRONT = 24;
Z_SWIRL_MAIN = 28;
Z_WIND = 32;
Z_LEFT_GEARS = 33;
Z_BELTS = 34;
Z_CLIFFS = 36;
Z_LIGHTHOUSE = 40;
Z_WAVE_1 = 42;
Z_WAVE_2 = 45;
Z_WAVE_3 = 48;
Z_WAVE_CRASH = 50;
Z_CYPRESS = 52;
Z_SKY_GEARS = 54;
Z_BIRD_WIRE = 56;
Z_FRAME = 60;

// ═══════════════════════════════════════════════════════════════════════════
// GEAR MODULE
// ═══════════════════════════════════════════════════════════════════════════
module gear(teeth, r, th=4, hole_r=0, col=C_GEAR) {
    tooth_h = r * 0.14;
    actual_hole = hole_r > 0 ? hole_r : max(1.5, r * 0.12);
    color(col)
    difference() {
        union() {
            cylinder(r=r-tooth_h*0.4, h=th);
            for(i=[0:teeth-1]) rotate([0,0,i*360/teeth])
                translate([r-tooth_h*0.2,0,0]) cylinder(r=tooth_h*1.1, h=th, $fn=6);
        }
        translate([0,0,-1]) cylinder(r=actual_hole, h=th+2);
        if(r > 12) for(i=[0:4]) rotate([0,0,i*72+36])
            translate([r*0.52,0,-1]) cylinder(r=r*0.15, h=th+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON - Concentric halos, larger behind, smaller 4mm in front
// ═══════════════════════════════════════════════════════════════════════════
module moon_halo_back(rot) {
    rotate([0,0,rot])
    color(C_MOON_HALO_A, 0.5)
    difference() {
        cylinder(r=50, h=3, $fn=96);
        translate([0,0,-1]) cylinder(r=42, h=5, $fn=96);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([46,0,-1]) cylinder(r=3.5, h=5);
    }
}

module moon_halo_front(rot) {
    rotate([0,0,rot])
    color(C_MOON_HALO_B, 0.6)
    difference() {
        cylinder(r=42, h=3, $fn=96);
        translate([0,0,-1]) cylinder(r=34, h=5, $fn=96);
        for(i=[0:5]) rotate([0,0,i*60]) 
            translate([38,0,-1]) cylinder(r=2.8, h=5);
    }
}

module moon_core(rot) {
    color(C_MOON, 0.2) cylinder(r=32, h=2, $fn=96);
    translate([0,0,2]) color(C_MOON) cylinder(r=20, h=5, $fn=96);
    translate([0,0,2]) rotate([0,0,rot])
    color(C_MOON, 0.8) for(r_val=[24, 28, 32]) difference() {
        cylinder(r=r_val+1.5, h=4, $fn=96);
        translate([0,0,-1]) cylinder(r=r_val-1, h=6, $fn=96);
        for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([40, 2.8, 6]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIRL DISC - Concentric halos, 3x faster
// ═══════════════════════════════════════════════════════════════════════════
module swirl_halo_back(r, rot) {
    rotate([0,0,rot])
    color(C_SWIRL_GREY_DARK, 0.82)
    difference() {
        cylinder(r=r*1.08, h=3, $fn=96);
        translate([0,0,-1]) cylinder(r=r*0.78, h=5, $fn=96);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([r*0.93,0,-1]) cylinder(r=r*0.08, h=5);
    }
}

module swirl_halo_front(r, rot) {
    rotate([0,0,rot])
    color(C_SWIRL_GREY, 0.88)
    difference() {
        cylinder(r=r*0.88, h=4, $fn=96);
        translate([0,0,-1]) cylinder(r=r*0.08, h=6, $fn=96);
        for(i=[0:9]) rotate([0,0,i*36]) 
            translate([r*0.30, -1.2, -1]) cube([r*0.48, 2.4, 6]);
    }
}

module swirl_main(r, rot) {
    rotate([0,0,rot]) 
    color(C_SWIRL_BLUE, 0.92)
    difference() {
        cylinder(r=r, h=5, $fn=96);
        translate([0,0,-1]) cylinder(r=r*0.07, h=7, $fn=96);
        for(i=[0:2]) rotate([0,0,i*120]) 
            translate([r*0.52,0,-1]) cylinder(r=r*0.12, h=7);
        translate([0,0,3])
        difference() {
            cylinder(r=r*0.92, h=3, $fn=96);
            cylinder(r=r*0.78, h=4, $fn=96);
        }
    }
    translate([0,0,4]) color(C_GEAR) cylinder(r=r*0.10, h=3);
}

// ═══════════════════════════════════════════════════════════════════════════
// STAR GEAR
// ═══════════════════════════════════════════════════════════════════════════
module star_gear(r, rot, halo_rot) {
    rotate([0,0,rot]) {
        color(C_STAR) difference() {
            cylinder(r=r, h=4, $fn=64);
            translate([0,0,-1]) cylinder(r=r*0.12, h=6);
            for(i=[0:4]) rotate([0,0,i*72]) translate([r*0.55,0,-1]) cylinder(r=r*0.1, h=6);
        }
        color(C_STAR) for(i=[0:7]) rotate([0,0,i*45])
            translate([r*0.75,0,0]) cylinder(r=r*0.12, h=4, $fn=3);
    }
    translate([0,0,-4]) rotate([0,0,halo_rot])
    color(C_GEAR_DARK, 0.8) difference() {
        cylinder(r=r*1.55, h=2, $fn=64);
        translate([0,0,-1]) cylinder(r=r*1.05, h=4, $fn=64);
        for(i=[0:5]) rotate([0,0,i*60]) translate([r*1.30,0,-1]) cylinder(r=r*0.13, h=4);
    }
    translate([0,0,0]) rotate([0,0,-halo_rot*0.8])
    color(C_GEAR, 0.7) difference() {
        cylinder(r=r*1.32, h=2, $fn=64);
        translate([0,0,-1]) cylinder(r=r*0.92, h=4, $fn=64);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([r*1.12,0,-1]) cylinder(r=r*0.1, h=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH - Properly positioned to touch left edge with circular cutouts
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_with_circular_cutouts() {
    difference() {
        // Wind path - translate so left edge touches X=0
        translate([WIND_TRANSLATE_X, WIND_TRANSLATE_Y, 0])
        scale([WIND_SCALE, WIND_SCALE, 1])
        color(C_WIND)
        wind_path_shape(1);
        
        // Big circular cutout (perfect circle)
        translate([BIG_CUTOUT_X, BIG_CUTOUT_Y, -1])
        cylinder(r=BIG_CUTOUT_R, h=20, $fn=128);
        
        // Small circular cutout (perfect circle)
        translate([SMALL_CUTOUT_X, SMALL_CUTOUT_Y, -1])
        cylinder(r=SMALL_CUTOUT_R, h=20, $fn=128);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF - Rectangle (x=0 to 100) + Inverted Triangle (base at top, to x=165)
// ═══════════════════════════════════════════════════════════════════════════
module cliff_assembly() {
    // Main cliff shape: Rectangle + Inverted Triangle
    // Rectangle: x=0 to CLIFF_RECT_WIDTH (100mm), full height
    // Triangle: Base at top (y=CLIFF_HEIGHT) from x=100 to x=165
    //           Point at bottom at x=100
    color(C_CLIFF)
    linear_extrude(height=10)
    polygon([
        [0, 0],                           // bottom left
        [CLIFF_RECT_WIDTH, 0],            // bottom of rectangle (x=100)
        [CLIFF_WIDTH, CLIFF_HEIGHT],      // top right (x=165, triangle base end)
        [0, CLIFF_HEIGHT]                 // top left
    ]);
    
    // Middle layer (slightly inset)
    translate([2, 0, 10])
    color(C_CLIFF_LAYER)
    linear_extrude(height=5)
    polygon([
        [0, CLIFF_HEIGHT * 0.08],
        [CLIFF_RECT_WIDTH - 5, CLIFF_HEIGHT * 0.05],
        [CLIFF_WIDTH - 10, CLIFF_HEIGHT * 0.95],
        [0, CLIFF_HEIGHT * 0.95]
    ]);
    
    // Grass top
    translate([0, CLIFF_HEIGHT * 0.85, 15])
    color(C_CLIFF_GRASS)
    linear_extrude(height=4)
    polygon([
        [0, 0],
        [0, CLIFF_HEIGHT * 0.19],
        [CLIFF_WIDTH - 15, CLIFF_HEIGHT * 0.19],
        [CLIFF_WIDTH - 5, CLIFF_HEIGHT * 0.08],
        [CLIFF_RECT_WIDTH + 20, -CLIFF_HEIGHT * 0.02],
        [0, 0]
    ]);
    
    // Rock texture lines
    color(C_CLIFF_DARK)
    for(i=[0:4]) {
        translate([5+i*18, CLIFF_HEIGHT*(0.12+i*0.14), 15])
        rotate([0,0,-10+i*4])
        linear_extrude(height=2)
        polygon([[0,0],[14,-0.6],[12,0.6]]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    translate([-16, -3, 0])
    color(C_LIGHTHOUSE) {
        cube([13, 10, 8]);
        translate([0, 5, 8])
        rotate([90, 0, 90])
        linear_extrude(height=13)
        polygon([[0,0], [5, 4], [10, 0]]);
    }
    
    color(C_LIGHTHOUSE)
    linear_extrude(height=42, scale=0.70)
    circle(r=7);
    
    color("#7a5535")
    for(z=[6, 17, 28])
        translate([0, 0, z])
        linear_extrude(height=4)
        circle(r=6.5 - z*0.04);
    
    translate([0, 0, 42]) color("#333") cylinder(r=9.5, h=2.5);
    translate([0, 0, 44.5])
    color("LightYellow", 0.65) difference() {
        cylinder(r=7, h=9);
        translate([0, 0, 1.5]) cylinder(r=6, h=10);
    }
    translate([0, 0, 50]) color("Yellow", 0.9) sphere(r=3.2);
    translate([0, 0, 49]) rotate([0, 0, beam_rot * 360])
    color("Yellow", 0.42) linear_extrude(height=4)
    polygon([[0,0], [22, -1.6], [22, 1.6]]);
    translate([0, 0, 53.5]) color("#7a5535") cylinder(r1=8.5, r2=2.2, h=6.5);
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD WIRE - Full width from X=0 to X=IW
// ═══════════════════════════════════════════════════════════════════════════
module bird_simple() {
    color(C_BIRD) {
        scale([1, 0.5, 0.35]) sphere(r=4);
        translate([3.5, 0, 1]) sphere(r=2);
        for(s=[-1,1]) translate([0, s*3, 0]) rotate([s*14, 0, 6])
            scale([1.1, 0.1, 0.48]) sphere(r=4);
        translate([-4, 0, 0]) rotate([0, -11, 0]) scale([1.2, 0.08, 0.32]) sphere(r=3);
    }
    translate([5.5, 0, 1]) color("#c8a040") rotate([0, 90, 0]) cylinder(r1=0.7, r2=0, h=2.2, $fn=6);
}

function wire_y(t_val, wire_num) = 
    let(y_base = wire_num == 0 ? IH * 0.52 : IH * 0.52 + 7)
    y_base + 6 * sin(t_val * 360 * 2.5);

module bird_wire_full_width(progress, bob) {
    wire_y_base = IH * 0.52;
    
    color(C_WIRE)
    for(i=[0:40]) {
        x1 = IW * (i/40); x2 = IW * ((i+1)/40);
        y1 = wire_y(i/40, 0); y2 = wire_y((i+1)/40, 0);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.55);
            translate([x2, y2, 0]) sphere(r=0.55);
        }
    }
    
    color(C_WIRE)
    for(i=[0:40]) {
        x1 = IW * (i/40); x2 = IW * ((i+1)/40);
        y1 = wire_y(i/40, 1); y2 = wire_y((i+1)/40, 1);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.55);
            translate([x2, y2, 0]) sphere(r=0.55);
        }
    }
    
    color(C_WIRE) {
        translate([0, wire_y_base + 3.5, 0]) 
        rotate([90, 0, 90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.55);
        translate([IW, wire_y_base + 3.5, 0]) 
        rotate([90, 0, -90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.55);
    }
    
    bird1_x = IW * progress;
    translate([bird1_x, wire_y(progress, 0), 2 + bob]) bird_simple();
    
    bird2_x = IW * ((progress + 0.35) % 1);
    translate([bird2_x, wire_y((progress + 0.35) % 1, 0), 2 + bob*0.85]) bird_simple();
    
    bird3_x = IW * (1 - progress);
    translate([bird3_x, wire_y(1 - progress, 1), 2 + bob*1.1]) rotate([0, 0, 180]) bird_simple();
}

module bird_wire_supports() {
    color(C_GEAR_DARK) {
        translate([2, IH * 0.52, 0]) cylinder(r=2, h=8);
        translate([IW - 2, IH * 0.52, 0]) cylinder(r=2, h=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS - Base touching bottom inner edge (Y=0)
// Shape min Y = -112.572, so translate by +112.572 * scale to bring to Y=0
// ═══════════════════════════════════════════════════════════════════════════
module cypress_at_bottom() {
    // Position X to right of cliff, Y translated so bottom is at Y=0
    translate([CLIFF_WIDTH + 20, CYPRESS_TRANSLATE_Y, 0])
    scale([CYPRESS_SCALE, CYPRESS_SCALE, 1])
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF WAVES - White/foam waves rotated 70° on Z axis
// ═══════════════════════════════════════════════════════════════════════════
module cliff_waves(drift, surge, crash, tilt) {
    sf = 0.85;
    
    // Wave layer 1 - darker, no rotation
    translate([WAVE_ZONE_START + drift*0.7, 10 + surge*0.8, 0])
    scale([0.28*sf, 0.28*sf, 1])
    color(C_WAVE_DARK)
    cliff_wave_L1(1);
    
    // Wave layer 2 - medium, no rotation
    translate([WAVE_ZONE_START + 18 + drift*0.55, 20 + surge*0.7, 0])
    scale([0.26*sf, 0.26*sf, 1])
    color(C_WAVE_MED)
    cliff_wave_L2(1);
    
    // Wave layer 3 (WHITE/FOAM) - ROTATED 70° on Z axis
    translate([WAVE_ZONE_START - 8 + drift*0.4, 38 + crash, 0])
    rotate([0, 0, 70])  // Z axis rotation
    scale([0.24*sf, 0.24*sf, 1])
    color(C_WAVE_FOAM, 0.95)
    cliff_wave_L3(1);
    
    // Additional foam spray 1 - ROTATED 70° on Z axis
    translate([WAVE_ZONE_START - 18 + drift*0.3, 58 + crash*0.85, 0])
    rotate([0, 0, 70])  // Z axis rotation
    scale([0.20*sf, 0.20*sf, 1])
    color(C_WAVE_FOAM, 0.88)
    cliff_wave_L3(1);
    
    // Foam spray 2 near cliff top - ROTATED 70° on Z axis
    translate([WAVE_ZONE_START - 26 + drift*0.2, 80 + crash*0.65, 0])
    rotate([0, 0, 70])  // Z axis rotation
    scale([0.16*sf, 0.16*sf, 1])
    color(C_WAVE_FOAM, 0.78)
    cliff_wave_L3(1);
    
    // Highest spray - ROTATED 70° on Z axis
    translate([WAVE_ZONE_START - 32 + drift*0.12, 98 + crash*0.45, 0])
    rotate([0, 0, 70])  // Z axis rotation
    scale([0.12*sf, 0.12*sf, 1])
    color(C_WAVE_FOAM, 0.68)
    cliff_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// OCEAN WAVES
// ═══════════════════════════════════════════════════════════════════════════
module ocean_waves(drift, surge) {
    sf = 0.85;
    
    translate([WAVE_ZONE_START + 50 + drift*0.6, OCEAN_WAVES_Y_BASE + surge, 0])
    scale([1.0*sf, 1.0*sf, 1])
    color(C_WAVE_DARK)
    ocean_wave_L1(1);
    
    translate([WAVE_ZONE_START + 80 + drift*0.45, OCEAN_WAVES_Y_BASE + 10 + surge*0.85, 0])
    scale([0.95*sf, 0.95*sf, 1])
    color(C_WAVE_MED)
    ocean_wave_L2(1);
    
    translate([WAVE_ZONE_START + 105 + drift*0.32, IH*0.20 + surge*0.7, 0])
    scale([0.90*sf, 0.90*sf, 1])
    color(C_WAVE_FOAM)
    ocean_wave_L3(1);
    
    translate([WAVE_ZONE_END - 45 + drift*0.22, IH*0.17 + surge*0.5, 0])
    scale([0.80*sf, 0.80*sf, 1])
    color(C_WAVE_FOAM, 0.9)
    ocean_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// STARS
// ═══════════════════════════════════════════════════════════════════════════
module all_stars(rot, halo_rot) {
    translate([IW*0.15, IH*0.90, 0]) star_gear(7, rot, halo_rot);
    translate([IW*0.28, IH*0.78, 0]) star_gear(6, -rot*1.1, -halo_rot*0.9);
    translate([IW*0.42, IH*0.94, 0]) star_gear(6, rot*0.85, halo_rot*1.08);
    translate([IW*0.55, IH*0.82, 0]) star_gear(5, -rot*1.25, -halo_rot*0.82);
    translate([IW*0.35, IH*0.70, 0]) star_gear(5, rot*1.05, halo_rot*0.92);
    translate([IW*0.68, IH*0.92, 0]) star_gear(6, -rot*0.92, -halo_rot*1.05);
}

// ═══════════════════════════════════════════════════════════════════════════
// LEFT GEARS - Behind lighthouse, +20mm Y
// ═══════════════════════════════════════════════════════════════════════════
module left_gears_behind_lighthouse(r1, r2, r3, r4) {
    lighthouse_x = CLIFF_RECT_WIDTH * 0.35;
    y_offset = 20;
    
    translate([lighthouse_x - 12, IH*0.60 + y_offset, 0]) rotate([0,0,r1]) gear(16, 14, 4);
    translate([lighthouse_x + 8, IH*0.53 + y_offset, 0]) rotate([0,0,r2]) gear(13, 11, 4);
    translate([lighthouse_x - 22, IH*0.48 + y_offset, 0]) rotate([0,0,r3]) gear(11, 9, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// SKY GEARS (FOREGROUND) - Without left cluster
// ═══════════════════════════════════════════════════════════════════════════
module sky_gears_foreground(r1, r2, r3, r4) {
    translate([IW*0.34, IH*0.94, 0]) rotate([0,0,r1*0.85]) gear(14, 12, 4);
    translate([IW*0.46, IH*0.90, 0]) rotate([0,0,r2*0.92]) gear(11, 9, 3);
    translate([IW*0.70, IH*0.84, 0]) rotate([0,0,r3*1.08]) gear(13, 11, 4);
    translate([IW*0.76, IH*0.70, 0]) rotate([0,0,r4]) gear(10, 8, 3);
    translate([IW*0.66, IH*0.74, 0]) rotate([0,0,r1*1.15]) gear(10, 8, 3);
    translate([IW*0.54, IH*0.80, 0]) rotate([0,0,r2*1.05]) gear(8, 6, 3);
    translate([IW*0.24, IH*0.84, 0]) rotate([0,0,r4*0.88]) gear(9, 7, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS - 4 gears, NOT in straight line
// ═══════════════════════════════════════════════════════════════════════════
module bottom_gears_four(rot) {
    translate([GEAR1_X, GEAR1_Y, 0]) rotate([0,0,rot]) gear(14, GEAR1_R, 4, 2, C_GEAR_DARK);
    translate([GEAR2_X, GEAR2_Y, 0]) rotate([0,0,-rot*0.85]) gear(18, GEAR2_R, 4, 2.5, C_GEAR_DARK);
    translate([GEAR3_X, GEAR3_Y, 0]) rotate([0,0,rot*1.15]) gear(12, GEAR3_R, 3, 1.8, C_GEAR_DARK);
    translate([GEAR4_X, GEAR4_Y, 0]) rotate([0,0,-rot*1.35]) gear(9, GEAR4_R, 3, 1.5, C_GEAR_DARK);
    
    color(C_GEAR) {
        hull() {
            translate([GEAR1_X, GEAR1_Y, 0]) cylinder(r=1.8, h=2);
            translate([GEAR2_X, GEAR2_Y, 0]) cylinder(r=1.8, h=2);
        }
        hull() {
            translate([GEAR2_X, GEAR2_Y, 0]) cylinder(r=1.8, h=2);
            translate([GEAR3_X, GEAR3_Y, 0]) cylinder(r=1.5, h=2);
        }
        hull() {
            translate([GEAR3_X, GEAR3_Y, 0]) cylinder(r=1.5, h=2);
            translate([GEAR4_X, GEAR4_Y, 0]) cylinder(r=1.2, h=2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BELT CONNECTIONS
// ═══════════════════════════════════════════════════════════════════════════
module belt_segment(x1, y1, x2, y2, phase) {
    dx = x2 - x1; dy = y2 - y1;
    len = sqrt(dx*dx + dy*dy);
    ang = atan2(dy, dx);
    spacing = 4.5;
    color(C_CHAIN)
    translate([x1, y1, 0]) rotate([0, 0, ang])
    for(i=[0:floor(len/spacing)-1]) {
        pos = (i * spacing + phase * 0.12) % max(len, 1);
        if(pos < len - 3)
        translate([pos, -1.1, 0]) hull() {
            cylinder(r=1.1, h=1.5);
            translate([3.2, 0, 0]) cylinder(r=1.1, h=1.5);
        }
    }
}

module belt_connections(phase) {
    belt_segment(IW*0.24, IH*0.84, IW*0.24, IH*0.72, phase);
    belt_segment(IW*0.24, IH*0.72, BIG_CUTOUT_X, BIG_CUTOUT_Y, phase);
    belt_segment(IW*0.55, IH*0.82, IW*0.50, IH*0.66, phase*1.1);
    belt_segment(IW*0.50, IH*0.66, SMALL_CUTOUT_X, SMALL_CUTOUT_Y, phase*1.1);
    belt_segment(IW*0.68, IH*0.90, IW*0.78, IH*0.82, phase*0.9);
    belt_segment(IW*0.78, IH*0.82, IW*0.88, IH*0.82, phase*0.9);
}

// ═══════════════════════════════════════════════════════════════════════════
// FRAME
// ═══════════════════════════════════════════════════════════════════════════
module frame() {
    color(C_FRAME)
    difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1]) cube([IW, IH, 12]);
        translate([FW-1.5, FW-1.5, 7]) cube([IW+3, IH+3, 5]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// SKY
color(C_SKY, 0.72) translate([FW, FW, Z_SKY]) cube([IW, IH, 2]);

// BOTTOM GEARS
translate([FW, FW, Z_BOTTOM_GEARS]) bottom_gears_four(gear_bottom);

// BIRD WIRE SUPPORTS (hidden behind)
translate([FW, FW, Z_BIRD_SUPPORTS]) bird_wire_supports();

// MOON HALOS (larger behind, smaller 4mm front)
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON_HALO_BACK]) moon_halo_back(moon_halo_1);
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON_HALO_FRONT]) moon_halo_front(moon_halo_2);

// MOON CORE
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON]) moon_core(moon_rot);

// STARS
translate([FW, FW, Z_STARS]) all_stars(star_rot, star_halo_rot);

// SWIRL DISC 1 (BIG) - CW rotation, +3mm diameter
translate([FW + BIG_CUTOUT_X, FW + BIG_CUTOUT_Y, Z_SWIRL_HALO_BACK])
swirl_halo_back(BIG_SWIRL_R, swirl_halo_speed);
translate([FW + BIG_CUTOUT_X, FW + BIG_CUTOUT_Y, Z_SWIRL_HALO_FRONT])
swirl_halo_front(BIG_SWIRL_R, -swirl_halo_speed*0.7);
translate([FW + BIG_CUTOUT_X, FW + BIG_CUTOUT_Y, Z_SWIRL_MAIN])
swirl_main(BIG_SWIRL_R, swirl_rot_big);

// SWIRL DISC 2 (SMALL) - CCW rotation
translate([FW + SMALL_CUTOUT_X, FW + SMALL_CUTOUT_Y, Z_SWIRL_HALO_BACK])
swirl_halo_back(SMALL_SWIRL_R, -swirl_halo_speed*1.1);
translate([FW + SMALL_CUTOUT_X, FW + SMALL_CUTOUT_Y, Z_SWIRL_HALO_FRONT])
swirl_halo_front(SMALL_SWIRL_R, swirl_halo_speed*0.8);
translate([FW + SMALL_CUTOUT_X, FW + SMALL_CUTOUT_Y, Z_SWIRL_MAIN])
swirl_main(SMALL_SWIRL_R, swirl_rot_small);

// WIND PATH (touching left edge, circular cutouts)
translate([FW, FW, Z_WIND]) wind_path_with_circular_cutouts();

// LEFT GEARS (behind lighthouse)
translate([FW, FW, Z_LEFT_GEARS]) left_gears_behind_lighthouse(gear_sky_1, gear_sky_2, gear_sky_3, gear_sky_4);

// BELT CONNECTIONS
translate([FW, FW, Z_BELTS]) belt_connections(belt_phase);

// CLIFF (165mm wide, rectangle + inverted triangle)
translate([FW, FW, Z_CLIFFS]) cliff_assembly();

// LIGHTHOUSE
translate([FW + CLIFF_RECT_WIDTH * 0.35, FW + CLIFF_HEIGHT * 0.92, Z_LIGHTHOUSE])
rotate([-90, 0, 0]) lighthouse(lighthouse_beam);

// CLIFF WAVES (foam rotated 70° on Z axis)
translate([FW, FW, Z_WAVE_1]) cliff_waves(wave_drift, wave_surge, wave_crash, wave_tilt);

// OCEAN WAVES
translate([FW, FW, Z_WAVE_2]) ocean_waves(wave_drift, wave_surge);

// CYPRESS (base at Y=0, inside frame)
translate([FW, FW, Z_CYPRESS]) cypress_at_bottom();

// SKY GEARS (foreground)
translate([FW, FW, Z_SKY_GEARS]) sky_gears_foreground(gear_sky_1, gear_sky_2, gear_sky_3, gear_sky_4);

// BIRD WIRE (full width)
translate([FW, FW, Z_BIRD_WIRE]) bird_wire_full_width(bird_progress, bird_bob);

// FRAME
translate([0, 0, Z_FRAME]) frame();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V37 - HIGH-END MECHANICAL ART");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "mm | Inner:", IW, "×", IH, "mm");
echo("");
echo("FIXES IMPLEMENTED:");
echo("  1. Wind path: Scale", WIND_SCALE, ", translate X=", WIND_TRANSLATE_X, "to touch left edge");
echo("  2. Cliff waves (foam): Rotated 70° on Z axis");
echo("  3. Cypress: Translate Y=", CYPRESS_TRANSLATE_Y, "to place base at Y=0");
echo("  4. Cliff: Rectangle (0-100) + Inverted triangle (100-165), total", CLIFF_WIDTH, "mm");
echo("  5. Big swirl disc: R=", BIG_SWIRL_R, "mm (+3mm diameter)");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
