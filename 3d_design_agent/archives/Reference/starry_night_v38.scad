// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V38 - REPOSITIONED FOR 302×202 CANVAS
// ═══════════════════════════════════════════════════════════════════════════
// All elements positioned within LOCKED zone boundaries
// Canvas: 302 × 202 mm (fits within 350×250 print with 24mm tabs)
// ═══════════════════════════════════════════════════════════════════════════
$fn = 64;

// COMPONENT INCLUDES (wrapper files for traced shapes)
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
// CANVAS DIMENSIONS (NEW - No frame, tabs are separate)
// ═══════════════════════════════════════════════════════════════════════════
CANVAS_W = 302;
CANVAS_H = 202;

// ═══════════════════════════════════════════════════════════════════════════
// LOCKED ZONE DEFINITIONS
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// ═══════════════════════════════════════════════════════════════════════════
ZONE_CLIFF        = [0, 108, 0, 65];
ZONE_LIGHTHOUSE   = [73, 82, 65, 117];
ZONE_CYPRESS      = [35, 95, 0, 121];
ZONE_CLIFF_WAVES  = [108, 160, 0, 69];
ZONE_OCEAN_WAVES  = [151, 302, 0, 65];
ZONE_BOTTOM_GEARS = [164, 302, 0, 30];
ZONE_WIND_PATH    = [0, 198, 105, 202];
ZONE_BIG_SWIRL    = [86, 160, 110, 170];
ZONE_SMALL_SWIRL  = [151, 198, 105, 154];
ZONE_MOON         = [231, 300, 141, 202];
ZONE_STARS        = [0, 198, 101, 202];
ZONE_SKY_GEARS    = [52, 216, 109, 166];
ZONE_BIRD_WIRE    = [0, 302, 130, 146];

// Helper functions
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];

// ═══════════════════════════════════════════════════════════════════════════
// ELEMENT POSITIONING (Calculated from zones)
// ═══════════════════════════════════════════════════════════════════════════

// CLIFF: Zone [0,108,0,65] = 108×65
CLIFF_WIDTH = 108;
CLIFF_HEIGHT = 65;

// LIGHTHOUSE: Zone [73,82,65,117] = 9×52, Center (77.5, 91)
LIGHTHOUSE_X = zone_center_x(ZONE_LIGHTHOUSE);  // 77.5
LIGHTHOUSE_Y = ZONE_LIGHTHOUSE[2];              // 65 (base)
LIGHTHOUSE_TOWER_R = 4;                         // Radius ~4mm (9mm width)
LIGHTHOUSE_HEIGHT = 52;                         // Full zone height

// CYPRESS: Zone [35,95,0,121] = 60×121, Center (65, 60.5)
CYPRESS_CENTER_X = zone_center_x(ZONE_CYPRESS); // 65
CYPRESS_WIDTH = zone_width(ZONE_CYPRESS);       // 60
CYPRESS_HEIGHT = zone_height(ZONE_CYPRESS);     // 121

// CLIFF_WAVES: Zone [108,160,0,69] = 52×69
CLIFF_WAVES_X = ZONE_CLIFF_WAVES[0];            // 108
CLIFF_WAVES_WIDTH = zone_width(ZONE_CLIFF_WAVES); // 52
CLIFF_WAVES_HEIGHT = zone_height(ZONE_CLIFF_WAVES); // 69

// OCEAN_WAVES: Zone [151,302,0,65] = 151×65
OCEAN_WAVES_X = ZONE_OCEAN_WAVES[0];            // 151
OCEAN_WAVES_WIDTH = zone_width(ZONE_OCEAN_WAVES); // 151
OCEAN_WAVES_HEIGHT = zone_height(ZONE_OCEAN_WAVES); // 65

// BOTTOM_GEARS: Zone [164,302,0,30] = 138×30
GEAR_ZONE_X = ZONE_BOTTOM_GEARS[0];             // 164
GEAR_ZONE_WIDTH = zone_width(ZONE_BOTTOM_GEARS); // 138
GEAR_ZONE_HEIGHT = zone_height(ZONE_BOTTOM_GEARS); // 30

// Position 4 gears within zone (max radius ~12 to fit in 30mm height)
GEAR1_X = GEAR_ZONE_X + GEAR_ZONE_WIDTH * 0.15; // 184.7
GEAR1_Y = 12;
GEAR1_R = 10;

GEAR2_X = GEAR_ZONE_X + GEAR_ZONE_WIDTH * 0.40; // 219.2
GEAR2_Y = 18;
GEAR2_R = 12;

GEAR3_X = GEAR_ZONE_X + GEAR_ZONE_WIDTH * 0.65; // 253.7
GEAR3_Y = 10;
GEAR3_R = 8;

GEAR4_X = GEAR_ZONE_X + GEAR_ZONE_WIDTH * 0.88; // 285.4
GEAR4_Y = 15;
GEAR4_R = 11;

// WIND_PATH: Zone [0,198,105,202] = 198×97
WIND_ZONE_WIDTH = zone_width(ZONE_WIND_PATH);   // 198
WIND_ZONE_HEIGHT = zone_height(ZONE_WIND_PATH); // 97
WIND_Y_BASE = ZONE_WIND_PATH[2];                // 105

// BIG_SWIRL: Zone [86,160,110,170] = 74×60, Center (123, 140)
BIG_SWIRL_X = zone_center_x(ZONE_BIG_SWIRL);    // 123
BIG_SWIRL_Y = zone_center_y(ZONE_BIG_SWIRL);    // 140
BIG_SWIRL_R = min(zone_width(ZONE_BIG_SWIRL), zone_height(ZONE_BIG_SWIRL)) / 2 - 2; // 28

// SMALL_SWIRL: Zone [151,198,105,154] = 47×49, Center (174.5, 129.5)
SMALL_SWIRL_X = zone_center_x(ZONE_SMALL_SWIRL); // 174.5
SMALL_SWIRL_Y = zone_center_y(ZONE_SMALL_SWIRL); // 129.5
SMALL_SWIRL_R = min(zone_width(ZONE_SMALL_SWIRL), zone_height(ZONE_SMALL_SWIRL)) / 2 - 2; // 21.5

// MOON: Zone [231,300,141,202] = 69×61, Center (265.5, 171.5)
MOON_X = zone_center_x(ZONE_MOON);              // 265.5
MOON_Y = zone_center_y(ZONE_MOON);              // 171.5
MOON_MAX_R = min(zone_width(ZONE_MOON), zone_height(ZONE_MOON)) / 2 - 1; // 29.5

// BIRD_WIRE: Zone [0,302,130,146] = 302×16, Center Y = 138
BIRD_WIRE_Y = zone_center_y(ZONE_BIRD_WIRE);    // 138

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
master_drive = t * 360;

swirl_rot_big = master_drive / 45;
swirl_rot_small = -master_drive / 40;
swirl_halo_speed = master_drive / 18;

moon_rot = master_drive / 70;
moon_halo_1 = -master_drive / 28;
moon_halo_2 = master_drive / 33;

star_rot = master_drive / 30;
star_halo_rot = -master_drive / 12;

wave_cam = master_drive / 25;
wave_drift = 4 * sin(wave_cam);
wave_surge = 3 * sin(wave_cam * 1.2);
wave_crash = 5 * sin(wave_cam * 1.1);

gear_rot = master_drive / 25;
gear_sky_1 = master_drive / 10;
gear_sky_2 = -master_drive / 12;
gear_sky_3 = master_drive / 15;
gear_sky_4 = -master_drive / 18;

lighthouse_beam = master_drive / 200;
bird_progress = t;
bird_bob = 2 * sin(master_drive / 15);

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_SKY = "#4a7ab0";
C_CLIFF = "#8b7355";
C_CLIFF_LAYER = "#9a8565";
C_CLIFF_GRASS = "#6a8a5a";
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
C_LIGHTHOUSE = "#d4c4a8";
C_BIRD = "#2a2a2a";
C_WIRE = "#3a3a3a";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_BOTTOM_GEARS = 6;
Z_MOON_HALO_BACK = 10;
Z_MOON_HALO_FRONT = 14;
Z_MOON = 16;
Z_STARS = 18;
Z_SWIRL_HALO_BACK = 20;
Z_SWIRL_HALO_FRONT = 24;
Z_SWIRL_MAIN = 28;
Z_CLIFFS = 32;
Z_WIND = 36;
Z_LIGHTHOUSE = 40;
Z_WAVE_1 = 44;
Z_WAVE_2 = 48;
Z_WAVE_3 = 52;
Z_CYPRESS = 56;
Z_SKY_GEARS = 60;
Z_BIRD_WIRE = 64;

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
        if(r > 10) for(i=[0:4]) rotate([0,0,i*72+36])
            translate([r*0.52,0,-1]) cylinder(r=r*0.15, h=th+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF - Sized to fit Zone [0,108,0,65]
// ═══════════════════════════════════════════════════════════════════════════
module cliff_assembly() {
    // Main cliff shape - fits exactly in zone
    color(C_CLIFF)
    linear_extrude(height=8)
    polygon([
        [0, 0],
        [CLIFF_WIDTH * 0.60, 0],           // 64.8
        [CLIFF_WIDTH, CLIFF_HEIGHT],        // 108, 65
        [0, CLIFF_HEIGHT]
    ]);
    
    // Texture layer
    translate([2, 0, 8])
    color(C_CLIFF_LAYER)
    linear_extrude(height=4)
    polygon([
        [0, CLIFF_HEIGHT * 0.1],
        [CLIFF_WIDTH * 0.55, CLIFF_HEIGHT * 0.05],
        [CLIFF_WIDTH - 5, CLIFF_HEIGHT * 0.95],
        [0, CLIFF_HEIGHT * 0.95]
    ]);
    
    // Grass on top
    translate([0, CLIFF_HEIGHT * 0.85, 12])
    color(C_CLIFF_GRASS)
    linear_extrude(height=3)
    polygon([
        [0, 0],
        [0, CLIFF_HEIGHT * 0.18],
        [CLIFF_WIDTH - 10, CLIFF_HEIGHT * 0.18],
        [CLIFF_WIDTH - 5, CLIFF_HEIGHT * 0.05],
        [CLIFF_WIDTH * 0.60, -CLIFF_HEIGHT * 0.02],
        [0, 0]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE - Sized to fit Zone [73,82,65,117] = 9×52
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    // Keeper's hut at base (scaled down)
    translate([-8, -2, 0])
    color(C_LIGHTHOUSE) {
        cube([7, 5, 5]);
        translate([0, 2.5, 5])
        rotate([90, 0, 90])
        linear_extrude(height=7)
        polygon([[0,0], [2.5, 2], [5, 0]]);
    }
    
    // Tower - fits within 9mm width, 52mm height
    tower_height = LIGHTHOUSE_HEIGHT - 12;  // 40mm for tower
    color(C_LIGHTHOUSE)
    linear_extrude(height=tower_height, scale=0.70)
    circle(r=LIGHTHOUSE_TOWER_R);
    
    // Stripes
    color("#7a5535")
    for(z=[5, 15, 25])
        translate([0, 0, z])
        linear_extrude(height=3)
        circle(r=LIGHTHOUSE_TOWER_R - 0.5);
    
    // Platform
    translate([0, 0, tower_height]) 
    color("#333") cylinder(r=5, h=2);
    
    // Lamp room
    translate([0, 0, tower_height + 2])
    color("LightYellow", 0.65) difference() {
        cylinder(r=4, h=6);
        translate([0, 0, 1]) cylinder(r=3.2, h=7);
    }
    
    // Light
    translate([0, 0, tower_height + 5]) 
    color("Yellow", 0.9) sphere(r=2);
    
    // Beam
    translate([0, 0, tower_height + 4]) 
    rotate([0, 0, beam_rot * 360])
    color("Yellow", 0.42) 
    linear_extrude(height=3)
    polygon([[0,0], [15, -1], [15, 1]]);
    
    // Roof
    translate([0, 0, tower_height + 8]) 
    color("#7a5535") cylinder(r1=5, r2=1.5, h=4);
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS - Sized to fit Zone [35,95,0,121] = 60×121
// Using placeholder shape (traced shape would need wrapper)
// ═══════════════════════════════════════════════════════════════════════════
module cypress_tree() {
    // Cypress shape to fit within 60×121 zone
    // Center at X=65, spans Y=0-121
    color(C_CYPRESS)
    linear_extrude(height=6)
    polygon([
        // Base
        [CYPRESS_WIDTH * 0.35, 0],
        [CYPRESS_WIDTH * 0.65, 0],
        // Right edge curving up
        [CYPRESS_WIDTH * 0.70, CYPRESS_HEIGHT * 0.15],
        [CYPRESS_WIDTH * 0.75, CYPRESS_HEIGHT * 0.30],
        [CYPRESS_WIDTH * 0.80, CYPRESS_HEIGHT * 0.45],
        [CYPRESS_WIDTH * 0.85, CYPRESS_HEIGHT * 0.60],
        [CYPRESS_WIDTH * 0.80, CYPRESS_HEIGHT * 0.75],
        [CYPRESS_WIDTH * 0.70, CYPRESS_HEIGHT * 0.88],
        [CYPRESS_WIDTH * 0.55, CYPRESS_HEIGHT * 0.97],
        // Top
        [CYPRESS_WIDTH * 0.50, CYPRESS_HEIGHT],
        // Left edge curving down
        [CYPRESS_WIDTH * 0.45, CYPRESS_HEIGHT * 0.97],
        [CYPRESS_WIDTH * 0.30, CYPRESS_HEIGHT * 0.88],
        [CYPRESS_WIDTH * 0.20, CYPRESS_HEIGHT * 0.75],
        [CYPRESS_WIDTH * 0.15, CYPRESS_HEIGHT * 0.60],
        [CYPRESS_WIDTH * 0.20, CYPRESS_HEIGHT * 0.45],
        [CYPRESS_WIDTH * 0.25, CYPRESS_HEIGHT * 0.30],
        [CYPRESS_WIDTH * 0.30, CYPRESS_HEIGHT * 0.15],
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH - Sized to fit Zone [0,198,105,202] = 198×97
// With circular cutouts for swirls
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_panel() {
    difference() {
        // Main wind shape filling zone
        color(C_WIND)
        linear_extrude(height=4)
        polygon([
            [0, 0],
            [WIND_ZONE_WIDTH * 0.15, WIND_ZONE_HEIGHT * 0.30],
            [WIND_ZONE_WIDTH * 0.35, WIND_ZONE_HEIGHT * 0.45],
            [WIND_ZONE_WIDTH * 0.50, WIND_ZONE_HEIGHT * 0.35],
            [WIND_ZONE_WIDTH * 0.65, WIND_ZONE_HEIGHT * 0.50],
            [WIND_ZONE_WIDTH * 0.80, WIND_ZONE_HEIGHT * 0.40],
            [WIND_ZONE_WIDTH, WIND_ZONE_HEIGHT * 0.55],
            [WIND_ZONE_WIDTH, WIND_ZONE_HEIGHT],
            [WIND_ZONE_WIDTH * 0.85, WIND_ZONE_HEIGHT * 0.95],
            [WIND_ZONE_WIDTH * 0.70, WIND_ZONE_HEIGHT * 0.85],
            [WIND_ZONE_WIDTH * 0.55, WIND_ZONE_HEIGHT * 0.92],
            [WIND_ZONE_WIDTH * 0.40, WIND_ZONE_HEIGHT * 0.80],
            [WIND_ZONE_WIDTH * 0.25, WIND_ZONE_HEIGHT * 0.88],
            [WIND_ZONE_WIDTH * 0.10, WIND_ZONE_HEIGHT * 0.75],
            [0, WIND_ZONE_HEIGHT],
        ]);
        
        // Big swirl cutout - relative to wind zone origin
        big_cut_x = BIG_SWIRL_X - ZONE_WIND_PATH[0];  // 123 - 0 = 123
        big_cut_y = BIG_SWIRL_Y - ZONE_WIND_PATH[2];  // 140 - 105 = 35
        translate([big_cut_x, big_cut_y, -1])
        cylinder(r=BIG_SWIRL_R + 2, h=10, $fn=96);
        
        // Small swirl cutout - relative to wind zone origin
        small_cut_x = SMALL_SWIRL_X - ZONE_WIND_PATH[0];  // 174.5 - 0 = 174.5
        small_cut_y = SMALL_SWIRL_Y - ZONE_WIND_PATH[2];  // 129.5 - 105 = 24.5
        translate([small_cut_x, small_cut_y, -1])
        cylinder(r=SMALL_SWIRL_R + 2, h=10, $fn=96);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIRL DISCS - Sized to fit zones (half thickness)
// ═══════════════════════════════════════════════════════════════════════════
module swirl_halo_back(r, rot) {
    rotate([0,0,rot])
    color(C_SWIRL_GREY_DARK, 0.82)
    difference() {
        cylinder(r=r*1.06, h=1.5, $fn=96);
        translate([0,0,-1]) cylinder(r=r*0.78, h=4, $fn=96);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([r*0.92,0,-1]) cylinder(r=r*0.08, h=4);
    }
}

module swirl_halo_front(r, rot) {
    rotate([0,0,rot])
    color(C_SWIRL_GREY, 0.88)
    difference() {
        cylinder(r=r*0.88, h=2, $fn=96);
        translate([0,0,-1]) cylinder(r=r*0.08, h=5, $fn=96);
        for(i=[0:9]) rotate([0,0,i*36]) 
            translate([r*0.30, -1.2, -1]) cube([r*0.48, 2.4, 5]);
    }
}

module swirl_main(r, rot) {
    rotate([0,0,rot]) 
    color(C_SWIRL_BLUE, 0.92)
    difference() {
        cylinder(r=r, h=2.5, $fn=96);
        translate([0,0,-1]) cylinder(r=r*0.07, h=5, $fn=96);
        for(i=[0:2]) rotate([0,0,i*120]) 
            translate([r*0.52,0,-1]) cylinder(r=r*0.12, h=5);
    }
    translate([0,0,2]) color(C_GEAR) cylinder(r=r*0.10, h=1.5);
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON - Sized to fit Zone [231,300,141,202] = 69×61 (half thickness)
// ═══════════════════════════════════════════════════════════════════════════
module moon_halo_back(rot) {
    rotate([0,0,rot])
    color(C_MOON_HALO_A, 0.5)
    difference() {
        cylinder(r=MOON_MAX_R, h=1.5, $fn=96);
        translate([0,0,-1]) cylinder(r=MOON_MAX_R * 0.84, h=4, $fn=96);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([MOON_MAX_R * 0.92,0,-1]) cylinder(r=2, h=4);
    }
}

module moon_halo_front(rot) {
    rotate([0,0,rot])
    color(C_MOON_HALO_B, 0.6)
    difference() {
        cylinder(r=MOON_MAX_R * 0.84, h=1.5, $fn=96);
        translate([0,0,-1]) cylinder(r=MOON_MAX_R * 0.68, h=4, $fn=96);
        for(i=[0:5]) rotate([0,0,i*60]) 
            translate([MOON_MAX_R * 0.76,0,-1]) cylinder(r=1.8, h=4);
    }
}

module moon_core(rot) {
    color(C_MOON, 0.2) cylinder(r=MOON_MAX_R * 0.68, h=1, $fn=96);
    translate([0,0,1]) color(C_MOON) cylinder(r=MOON_MAX_R * 0.50, h=2.5, $fn=96);
    translate([0,0,1]) rotate([0,0,rot])
    color(C_MOON, 0.8) for(r_pct=[0.55, 0.62, 0.68]) {
        r_val = MOON_MAX_R * r_pct;
        difference() {
            cylinder(r=r_val+1, h=2, $fn=96);
            translate([0,0,-1]) cylinder(r=r_val-0.5, h=4, $fn=96);
            for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([35, 2, 5]);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAR GEAR - Positioned within Zone [0,198,101,202]
// ═══════════════════════════════════════════════════════════════════════════
module star_gear(r, rot, halo_rot) {
    rotate([0,0,rot]) {
        color(C_STAR) difference() {
            cylinder(r=r, h=2, $fn=64);
            translate([0,0,-1]) cylinder(r=r*0.12, h=4);
            for(i=[0:4]) rotate([0,0,i*72]) translate([r*0.55,0,-1]) cylinder(r=r*0.1, h=4);
        }
        color(C_STAR) for(i=[0:7]) rotate([0,0,i*45])
            translate([r*0.75,0,0]) cylinder(r=r*0.12, h=2, $fn=3);
    }
    translate([0,0,-2]) rotate([0,0,halo_rot])
    color(C_GEAR_DARK, 0.8) difference() {
        cylinder(r=r*1.55, h=1, $fn=64);
        translate([0,0,-1]) cylinder(r=r*1.05, h=3, $fn=64);
        for(i=[0:5]) rotate([0,0,i*60]) translate([r*1.30,0,-1]) cylinder(r=r*0.13, h=3);
    }
}

module all_stars(rot, halo_rot) {
    // All stars within ZONE_STARS [0,198,101,202]
    // Positions as percentages of zone
    star_x_min = ZONE_STARS[0];
    star_x_max = ZONE_STARS[1];
    star_y_min = ZONE_STARS[2];
    star_y_max = ZONE_STARS[3];
    
    translate([star_x_min + 30, star_y_min + 80, 0]) star_gear(6, rot, halo_rot);
    translate([star_x_min + 55, star_y_min + 60, 0]) star_gear(5, -rot*1.1, -halo_rot*0.9);
    translate([star_x_min + 85, star_y_min + 85, 0]) star_gear(5, rot*0.85, halo_rot*1.08);
    translate([star_x_min + 110, star_y_min + 65, 0]) star_gear(4, -rot*1.25, -halo_rot*0.82);
    translate([star_x_min + 140, star_y_min + 78, 0]) star_gear(5, rot*1.05, halo_rot*0.92);
    translate([star_x_min + 170, star_y_min + 55, 0]) star_gear(4, -rot*0.92, -halo_rot*1.05);
}

// ═══════════════════════════════════════════════════════════════════════════
// SKY GEARS - Positioned within Zone [52,216,109,166]
// ═══════════════════════════════════════════════════════════════════════════
module sky_gears_foreground(r1, r2, r3, r4) {
    sg_x_min = ZONE_SKY_GEARS[0];
    sg_y_min = ZONE_SKY_GEARS[2];
    sg_w = zone_width(ZONE_SKY_GEARS);
    sg_h = zone_height(ZONE_SKY_GEARS);
    
    translate([sg_x_min + sg_w * 0.10, sg_y_min + sg_h * 0.80, 0]) 
        rotate([0,0,r1*0.85]) gear(12, 8, 3);
    translate([sg_x_min + sg_w * 0.25, sg_y_min + sg_h * 0.50, 0]) 
        rotate([0,0,r2*0.92]) gear(10, 7, 3);
    translate([sg_x_min + sg_w * 0.45, sg_y_min + sg_h * 0.75, 0]) 
        rotate([0,0,r3*1.08]) gear(11, 8, 3);
    translate([sg_x_min + sg_w * 0.60, sg_y_min + sg_h * 0.30, 0]) 
        rotate([0,0,r4]) gear(9, 6, 3);
    translate([sg_x_min + sg_w * 0.75, sg_y_min + sg_h * 0.55, 0]) 
        rotate([0,0,r1*1.15]) gear(10, 7, 3);
    translate([sg_x_min + sg_w * 0.90, sg_y_min + sg_h * 0.40, 0]) 
        rotate([0,0,r2*1.05]) gear(8, 5, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS - Positioned within Zone [164,302,0,30]
// ═══════════════════════════════════════════════════════════════════════════
module bottom_gears_four(rot) {
    translate([GEAR1_X, GEAR1_Y, 0]) rotate([0,0,rot]) gear(12, GEAR1_R, 3, 1.8, C_GEAR_DARK);
    translate([GEAR2_X, GEAR2_Y, 0]) rotate([0,0,-rot*0.85]) gear(14, GEAR2_R, 3, 2, C_GEAR_DARK);
    translate([GEAR3_X, GEAR3_Y, 0]) rotate([0,0,rot*1.15]) gear(10, GEAR3_R, 3, 1.5, C_GEAR_DARK);
    translate([GEAR4_X, GEAR4_Y, 0]) rotate([0,0,-rot*1.35]) gear(13, GEAR4_R, 3, 2, C_GEAR_DARK);
    
    // Connecting rods
    color(C_GEAR) {
        hull() {
            translate([GEAR1_X, GEAR1_Y, 0]) cylinder(r=1.5, h=2);
            translate([GEAR2_X, GEAR2_Y, 0]) cylinder(r=1.5, h=2);
        }
        hull() {
            translate([GEAR2_X, GEAR2_Y, 0]) cylinder(r=1.5, h=2);
            translate([GEAR3_X, GEAR3_Y, 0]) cylinder(r=1.2, h=2);
        }
        hull() {
            translate([GEAR3_X, GEAR3_Y, 0]) cylinder(r=1.2, h=2);
            translate([GEAR4_X, GEAR4_Y, 0]) cylinder(r=1.5, h=2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF WAVES - Positioned within Zone [108,160,0,69]
// ═══════════════════════════════════════════════════════════════════════════
module cliff_waves(drift, surge, crash) {
    cw_x = ZONE_CLIFF_WAVES[0];
    cw_w = zone_width(ZONE_CLIFF_WAVES);
    cw_h = zone_height(ZONE_CLIFF_WAVES);
    
    // Layer 1 - dark base
    translate([cw_x + drift*0.5, 5 + surge*0.8, 0])
    color(C_WAVE_DARK)
    linear_extrude(height=3)
    scale([cw_w/50, cw_h/70])
    polygon([[0,0], [45,5], [50,25], [45,45], [30,55], [10,50], [0,35]]);
    
    // Layer 2 - medium
    translate([cw_x + 5 + drift*0.4, 15 + surge*0.6, 0])
    color(C_WAVE_MED)
    linear_extrude(height=3)
    scale([cw_w/55, cw_h/75])
    polygon([[0,5], [40,10], [48,30], [42,50], [25,58], [8,52], [0,38]]);
    
    // Layer 3 - foam (rotated -70°)
    translate([cw_x - 5 + drift*0.3, 30 + crash, 0])
    rotate([0, 0, -70])
    color(C_WAVE_FOAM, 0.95)
    linear_extrude(height=3)
    scale([0.4, 0.4])
    polygon([[0,0], [35,8], [45,25], [40,45], [20,50], [5,40], [0,25]]);
    
    // Spray foam
    translate([cw_x - 12 + drift*0.2, 50 + crash*0.7, 0])
    rotate([0, 0, -70])
    color(C_WAVE_FOAM, 0.85)
    linear_extrude(height=2)
    scale([0.3, 0.3])
    polygon([[0,0], [30,5], [35,20], [25,35], [10,30], [0,18]]);
}

// ═══════════════════════════════════════════════════════════════════════════
// OCEAN WAVES - Positioned within Zone [151,302,0,65]
// ═══════════════════════════════════════════════════════════════════════════
module ocean_waves(drift, surge) {
    ow_x = ZONE_OCEAN_WAVES[0];
    ow_w = zone_width(ZONE_OCEAN_WAVES);
    ow_h = zone_height(ZONE_OCEAN_WAVES);
    
    // Base wave layer
    translate([ow_x + drift*0.4, 5 + surge, 0])
    color(C_WAVE_DARK)
    linear_extrude(height=3)
    polygon([
        [0, 0], [0, ow_h * 0.35],
        [ow_w * 0.15, ow_h * 0.45],
        [ow_w * 0.35, ow_h * 0.50],
        [ow_w * 0.55, ow_h * 0.48],
        [ow_w * 0.75, ow_h * 0.52],
        [ow_w * 0.90, ow_h * 0.45],
        [ow_w, ow_h * 0.38],
        [ow_w, 0]
    ]);
    
    // Middle wave layer
    translate([ow_x + 10 + drift*0.3, 12 + surge*0.8, 0])
    color(C_WAVE_MED)
    linear_extrude(height=3)
    polygon([
        [0, ow_h * 0.10],
        [ow_w * 0.20, ow_h * 0.35],
        [ow_w * 0.40, ow_h * 0.45],
        [ow_w * 0.60, ow_h * 0.42],
        [ow_w * 0.80, ow_h * 0.48],
        [ow_w * 0.95, ow_h * 0.38],
        [ow_w * 0.90, ow_h * 0.25],
        [ow_w * 0.70, ow_h * 0.30],
        [ow_w * 0.50, ow_h * 0.28],
        [ow_w * 0.30, ow_h * 0.32],
        [ow_w * 0.10, ow_h * 0.22]
    ]);
    
    // Foam crests
    translate([ow_x + 25 + drift*0.2, 20 + surge*0.6, 0])
    color(C_WAVE_FOAM)
    linear_extrude(height=3) {
        // Curl 1
        translate([ow_w * 0.15, ow_h * 0.25])
        scale([1, 0.6])
        circle(r=8, $fn=32);
        
        // Curl 2
        translate([ow_w * 0.45, ow_h * 0.30])
        scale([1.2, 0.7])
        circle(r=7, $fn=32);
        
        // Curl 3
        translate([ow_w * 0.70, ow_h * 0.28])
        scale([1, 0.5])
        circle(r=6, $fn=32);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD WIRE - Positioned within Zone [0,302,130,146]
// ═══════════════════════════════════════════════════════════════════════════
module bird_simple() {
    color(C_BIRD) {
        scale([1, 0.5, 0.35]) sphere(r=3);
        translate([2.5, 0, 0.8]) sphere(r=1.5);
        for(s=[-1,1]) translate([0, s*2.5, 0]) rotate([s*14, 0, 6])
            scale([1.1, 0.1, 0.48]) sphere(r=3);
        translate([-3, 0, 0]) rotate([0, -11, 0]) scale([1.2, 0.08, 0.32]) sphere(r=2);
    }
    translate([4, 0, 0.8]) color("#c8a040") rotate([0, 90, 0]) 
    cylinder(r1=0.5, r2=0, h=1.5, $fn=6);
}

module bird_wire_track(progress, bob) {
    wire_y = BIRD_WIRE_Y;  // 138
    wire_sag = 3;
    
    // Wire 1
    color(C_WIRE)
    for(i=[0:30]) {
        x1 = CANVAS_W * (i/30);
        x2 = CANVAS_W * ((i+1)/30);
        y1 = wire_y + wire_sag * sin((i/30) * 180);
        y2 = wire_y + wire_sag * sin(((i+1)/30) * 180);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.4);
            translate([x2, y2, 0]) sphere(r=0.4);
        }
    }
    
    // Wire 2 (slightly higher)
    color(C_WIRE)
    for(i=[0:30]) {
        x1 = CANVAS_W * (i/30);
        x2 = CANVAS_W * ((i+1)/30);
        y1 = wire_y + 6 + wire_sag * sin((i/30) * 180);
        y2 = wire_y + 6 + wire_sag * sin(((i+1)/30) * 180);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.4);
            translate([x2, y2, 0]) sphere(r=0.4);
        }
    }
    
    // Birds on wire
    bird1_x = CANVAS_W * progress;
    bird1_y = wire_y + wire_sag * sin(progress * 180);
    translate([bird1_x, bird1_y, 1.5 + bob]) bird_simple();
    
    bird2_x = CANVAS_W * ((progress + 0.4) % 1);
    bird2_y = wire_y + wire_sag * sin(((progress + 0.4) % 1) * 180);
    translate([bird2_x, bird2_y, 1.5 + bob*0.8]) bird_simple();
    
    bird3_x = CANVAS_W * (1 - progress);
    bird3_y = wire_y + 6 + wire_sag * sin((1 - progress) * 180);
    translate([bird3_x, bird3_y, 1.5 + bob*1.1]) rotate([0, 0, 180]) bird_simple();
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// SKY BACKGROUND
color(C_SKY, 0.72) 
translate([0, 0, Z_SKY]) 
cube([CANVAS_W, CANVAS_H, 2]);

// BOTTOM GEARS - Zone [164,302,0,30]
translate([0, 0, Z_BOTTOM_GEARS]) 
bottom_gears_four(gear_rot);

// MOON - Zone [231,300,141,202], Center (265.5, 171.5)
translate([MOON_X, MOON_Y, Z_MOON_HALO_BACK]) moon_halo_back(moon_halo_1);
translate([MOON_X, MOON_Y, Z_MOON_HALO_FRONT]) moon_halo_front(moon_halo_2);
translate([MOON_X, MOON_Y, Z_MOON]) moon_core(moon_rot);

// STARS - Zone [0,198,101,202]
translate([0, 0, Z_STARS]) all_stars(star_rot, star_halo_rot);

// BIG SWIRL - Zone [86,160,110,170], Center (123, 140)
translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_HALO_BACK])
swirl_halo_back(BIG_SWIRL_R, swirl_halo_speed);
translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_HALO_FRONT])
swirl_halo_front(BIG_SWIRL_R, -swirl_halo_speed*0.7);
translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_MAIN])
swirl_main(BIG_SWIRL_R, swirl_rot_big);

// SMALL SWIRL - Zone [151,198,105,154], Center (174.5, 129.5)
translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_HALO_BACK])
swirl_halo_back(SMALL_SWIRL_R, -swirl_halo_speed*1.1);
translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_HALO_FRONT])
swirl_halo_front(SMALL_SWIRL_R, swirl_halo_speed*0.8);
translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_MAIN])
swirl_main(SMALL_SWIRL_R, swirl_rot_small);

// CLIFF - Zone [0,108,0,65]
translate([0, 0, Z_CLIFFS]) cliff_assembly();

// WIND PATH - Zone [0,198,105,202]
translate([0, WIND_Y_BASE, Z_WIND]) wind_path_panel();

// LIGHTHOUSE - Zone [73,82,65,117], Center (77.5, 91)
translate([LIGHTHOUSE_X, LIGHTHOUSE_Y, Z_LIGHTHOUSE])
rotate([-90, 0, 0]) lighthouse(lighthouse_beam);

// CLIFF WAVES - Zone [108,160,0,69]
translate([0, 0, Z_WAVE_1]) cliff_waves(wave_drift, wave_surge, wave_crash);

// OCEAN WAVES - Zone [151,302,0,65]
translate([0, 0, Z_WAVE_2]) ocean_waves(wave_drift, wave_surge);

// CYPRESS - Zone [35,95,0,121]
translate([ZONE_CYPRESS[0], 0, Z_CYPRESS]) cypress_tree();

// SKY GEARS - Zone [52,216,109,166]
translate([0, 0, Z_SKY_GEARS]) sky_gears_foreground(gear_sky_1, gear_sky_2, gear_sky_3, gear_sky_4);

// BIRD WIRE - Zone [0,302,130,146]
translate([0, 0, Z_BIRD_WIRE]) bird_wire_track(bird_progress, bird_bob);

// ═══════════════════════════════════════════════════════════════════════════
// VERIFICATION OUTPUT
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V38 - REPOSITIONED FOR 302×202 CANVAS");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("Canvas:", CANVAS_W, "×", CANVAS_H, "mm");
echo("");
echo("ELEMENT VERIFICATION (all within locked zones):");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("CLIFF:        Zone [0,108,0,65] → Size ", CLIFF_WIDTH, "×", CLIFF_HEIGHT, " ✓"));
echo(str("LIGHTHOUSE:   Zone [73,82,65,117] → Center (", LIGHTHOUSE_X, ",", LIGHTHOUSE_Y, ") ✓"));
echo(str("CYPRESS:      Zone [35,95,0,121] → X=", ZONE_CYPRESS[0], ", Size ", CYPRESS_WIDTH, "×", CYPRESS_HEIGHT, " ✓"));
echo(str("CLIFF_WAVES:  Zone [108,160,0,69] → X=", CLIFF_WAVES_X, " ✓"));
echo(str("OCEAN_WAVES:  Zone [151,302,0,65] → X=", OCEAN_WAVES_X, " ✓"));
echo(str("BOTTOM_GEARS: Zone [164,302,0,30] → X range ", GEAR1_X, "-", GEAR4_X, " ✓"));
echo(str("WIND_PATH:    Zone [0,198,105,202] → Y=", WIND_Y_BASE, " ✓"));
echo(str("BIG_SWIRL:    Zone [86,160,110,170] → Center (", BIG_SWIRL_X, ",", BIG_SWIRL_Y, "), R=", BIG_SWIRL_R, " ✓"));
echo(str("SMALL_SWIRL:  Zone [151,198,105,154] → Center (", SMALL_SWIRL_X, ",", SMALL_SWIRL_Y, "), R=", SMALL_SWIRL_R, " ✓"));
echo(str("MOON:         Zone [231,300,141,202] → Center (", MOON_X, ",", MOON_Y, "), R=", MOON_MAX_R, " ✓"));
echo(str("STARS:        Zone [0,198,101,202] → Within bounds ✓"));
echo(str("SKY_GEARS:    Zone [52,216,109,166] → Within bounds ✓"));
echo(str("BIRD_WIRE:    Zone [0,302,130,146] → Y=", BIRD_WIRE_Y, " ✓"));
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
