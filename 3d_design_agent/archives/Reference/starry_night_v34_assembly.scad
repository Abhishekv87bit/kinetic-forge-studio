// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V34 - HIGH-END MECHANICAL ART
// Based on V30 with refined mechanical systems
// Pure mechanical - no microchips, all gears/belts/pulleys
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

// CLIFF DIMENSIONS (75mm shorter on X axis)
CLIFF_WIDTH = 90;    // Was 165, now 90 (75mm shorter)
CLIFF_HEIGHT = 105;

// ═══════════════════════════════════════════════════════════════════════════
// MECHANICAL DRIVE SYSTEM
// All animation derived from single master drive via gear ratios
// This simulates a hand crank or slow motor driving everything
// ═══════════════════════════════════════════════════════════════════════════
t = $t;

// Master drive rotation (equivalent to motor shaft)
master_drive = t * 360;

// GEAR RATIOS - All motion derives from master
// Higher ratio = slower motion = more meditative

// Swirl rotations (45:1 and 40:1 reduction)
swirl_rot_1 = master_drive / 45;
swirl_counter_1 = -master_drive / 55;  // Counter rotation
swirl_rot_2 = -master_drive / 40;
swirl_counter_2 = master_drive / 50;

// Moon (70:1 reduction - slowest, most majestic)
moon_rot = master_drive / 70;
moon_halo_1 = -master_drive / 85;
moon_halo_2 = master_drive / 100;

// Stars (30:1 reduction)
star_rot = master_drive / 30;
star_halo_rot = -master_drive / 38;

// Wave mechanism (25:1 reduction with cam)
wave_cam = master_drive / 25;
wave_drift = 6 * sin(wave_cam);
wave_surge = 4 * sin(wave_cam * 1.2);
wave_tilt = 5 * sin(wave_cam * 0.8);
wave_crash = 7 * sin(wave_cam * 1.1);

// Sky gears (decorative, 10:1 to 18:1)
gear_sky_1 = master_drive / 10;
gear_sky_2 = -master_drive / 12;
gear_sky_3 = master_drive / 15;
gear_sky_4 = -master_drive / 18;

// Bottom gears (wave drive, 25:1)
gear_bottom = master_drive / 25;

// Belt/chain phase
belt_phase = master_drive / 8;

// Lighthouse beam (200:1 - very slow)
lighthouse_beam = master_drive / 200;

// Bird flock movement
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
C_SWIRL_GREY = "#555555";      // Grey counter-rotating disc
C_SWIRL_GREY_DARK = "#454545"; // Darker grey for texture
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
C_BELT = "#4a3a2a";
C_CHAIN = "#454038";
C_LIGHTHOUSE = "#d4c4a8";
C_BIRD = "#2a2a2a";
C_WIRE = "#3a3a3a";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS (only sky gears in foreground)
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_BOTTOM_GEARS = 6;      // Under waves, near bottom
Z_MOON = 10;
Z_STARS = 12;
Z_SWIRL_BACK = 14;       // Grey counter-rotating disc
Z_SWIRL_FRONT = 18;      // Blue main disc
Z_WIND = 22;
Z_BELTS = 24;
Z_CLIFFS = 28;
Z_LIGHTHOUSE = 32;
Z_WAVE_1 = 35;
Z_WAVE_2 = 39;
Z_WAVE_3 = 43;
Z_WAVE_CRASH = 46;
Z_CYPRESS = 50;
Z_SKY_GEARS = 52;        // ONLY sky gears in foreground
Z_BIRD_WIRE = 54;
Z_FRAME = 58;

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
// STAR GEAR WITH DUAL COUNTER-ROTATING HALOS
// ═══════════════════════════════════════════════════════════════════════════
module star_gear(r, rot, halo_rot) {
    // Inner star gear
    rotate([0,0,rot]) {
        color(C_STAR) difference() {
            cylinder(r=r, h=4);
            translate([0,0,-1]) cylinder(r=r*0.12, h=6);
            for(i=[0:4]) rotate([0,0,i*72]) translate([r*0.55,0,-1]) cylinder(r=r*0.1, h=6);
        }
        color(C_STAR) for(i=[0:7]) rotate([0,0,i*45])
            translate([r*0.75,0,0]) cylinder(r=r*0.12, h=4, $fn=3);
    }
    
    // Halo A (outer)
    translate([0,0,-3]) rotate([0,0,halo_rot])
    color(C_GEAR_DARK, 0.8) difference() {
        cylinder(r=r*1.55, h=2);
        translate([0,0,-1]) cylinder(r=r*1.05, h=4);
        for(i=[0:5]) rotate([0,0,i*60]) translate([r*1.30,0,-1]) cylinder(r=r*0.13, h=4);
    }
    
    // Halo B (middle) - opposite rotation
    translate([0,0,-6]) rotate([0,0,-halo_rot*0.8])
    color(C_GEAR, 0.7) difference() {
        cylinder(r=r*1.32, h=2);
        translate([0,0,-1]) cylinder(r=r*0.92, h=4);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([r*1.12,0,-1]) cylinder(r=r*0.1, h=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUNTER-ROTATING SWIRL DISC (like moon halos, grey color)
// Two distinct parts rotating in different directions
// ═══════════════════════════════════════════════════════════════════════════
module swirl_disc_counter_rotating(r, rot_main, rot_counter) {
    // PART A - Main swirl disc (blue)
    rotate([0,0,rot_main]) 
    color(C_SWIRL_BLUE, 0.92)
    difference() {
        cylinder(r=r, h=5);
        translate([0,0,-1]) cylinder(r=r*0.07, h=7);
        // Van Gogh spiral cutouts
        for(i=[0:2]) rotate([0,0,i*120]) 
            translate([r*0.52,0,-1]) cylinder(r=r*0.12, h=7);
        // Decorative ring groove
        translate([0,0,3])
        difference() {
            cylinder(r=r*0.92, h=3);
            cylinder(r=r*0.78, h=4);
        }
    }
    
    // Center hub (brass)
    translate([0,0,4])
    color(C_GEAR)
    cylinder(r=r*0.10, h=3);
    
    // 1mm gap
    
    // PART B - Counter-rotating disc (grey, like moon halos)
    translate([0,0,-6]) 
    rotate([0,0,rot_counter]) 
    color(C_SWIRL_GREY, 0.88)
    difference() {
        cylinder(r=r*0.88, h=4);
        translate([0,0,-1]) cylinder(r=r*0.08, h=6);
        // Radial slot texture (different from main disc)
        for(i=[0:9]) rotate([0,0,i*36]) 
            translate([r*0.30, -1.2, -1]) cube([r*0.48, 2.4, 6]);
    }
    
    // PART C - Outer ring (darker grey, opposite to Part B)
    translate([0,0,-10]) 
    rotate([0,0,-rot_counter*0.7]) 
    color(C_SWIRL_GREY_DARK, 0.82)
    difference() {
        cylinder(r=r*1.05, h=3);
        translate([0,0,-1]) cylinder(r=r*0.80, h=5);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([r*0.92,0,-1]) cylinder(r=r*0.08, h=5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON ASSEMBLY (dual counter-rotating halos)
// ═══════════════════════════════════════════════════════════════════════════
module moon_assembly(rot, halo1_rot, halo2_rot) {
    s = 0.85;  // 15% smaller
    
    // Outer halo A
    translate([0,0,-5]) rotate([0,0,halo1_rot])
    color(C_MOON_HALO_A, 0.48) difference() {
        cylinder(r=50*s, h=3);
        translate([0,0,-1]) cylinder(r=38*s, h=5);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([44*s,0,-1]) cylinder(r=3.2*s, h=5);
    }
    
    // Inner halo B (opposite rotation)
    translate([0,0,-9]) rotate([0,0,halo2_rot])
    color(C_MOON_HALO_B, 0.55) difference() {
        cylinder(r=42*s, h=3);
        translate([0,0,-1]) cylinder(r=32*s, h=5);
        for(i=[0:5]) rotate([0,0,i*60]) translate([37*s,0,-1]) cylinder(r=2.4*s, h=5);
    }
    
    // Glow base
    color(C_MOON, 0.2) cylinder(r=35*s, h=2);
    
    // Core moon
    translate([0,0,2]) color(C_MOON) cylinder(r=22*s, h=5);
    
    // Rotating rings
    translate([0,0,2]) rotate([0,0,rot])
    color(C_MOON, 0.8) for(r_val=[27*s, 32*s, 37*s]) difference() {
        cylinder(r=r_val+1.5, h=4);
        translate([0,0,-1]) cylinder(r=r_val-1, h=6);
        for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([45*s, 2.8, 6]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BELT/CHAIN MECHANISM
// ═══════════════════════════════════════════════════════════════════════════
module belt_segment(x1, y1, x2, y2, phase) {
    dx = x2 - x1; dy = y2 - y1;
    len = sqrt(dx*dx + dy*dy);
    ang = atan2(dy, dx);
    spacing = 4.5;
    
    color(C_CHAIN)
    translate([x1, y1, 0])
    rotate([0, 0, ang])
    for(i=[0:floor(len/spacing)-1]) {
        pos = (i * spacing + phase * 0.12) % max(len, 1);
        if(pos < len - 3)
        translate([pos, -1.1, 0])
        hull() {
            cylinder(r=1.1, h=1.5);
            translate([3.2, 0, 0]) cylinder(r=1.1, h=1.5);
        }
    }
}

module belt_pulley(r, rot) {
    rotate([0,0,rot]) color(C_GEAR_DARK) difference() {
        cylinder(r=r, h=3);
        translate([0,0,-1]) cylinder(r=r*0.25, h=5);
        for(i=[0:11]) rotate([0,0,i*30]) translate([r*0.65,0,-1]) cylinder(r=1, h=5);
    }
}

// Star-to-Swirl belt connections
module belt_connections(phase) {
    // Belt from left stars to big swirl
    belt_segment(IW*0.15, IH*0.88, IW*0.20, IH*0.75, phase);
    belt_segment(IW*0.20, IH*0.75, IW*0.22, IH*0.62, phase);
    
    // Belt from right stars to small swirl
    belt_segment(IW*0.55, IH*0.82, IW*0.48, IH*0.70, phase*1.1);
    belt_segment(IW*0.48, IH*0.70, IW*0.44, IH*0.52, phase*1.1);
    
    // Belt to moon
    belt_segment(IW*0.68, IH*0.90, IW*0.78, IH*0.82, phase*0.9);
    belt_segment(IW*0.78, IH*0.82, IW*0.88, IH*0.82, phase*0.9);
    
    // Pulleys
    translate([IW*0.20, IH*0.75, 0]) belt_pulley(5, phase*0.3);
    translate([IW*0.48, IH*0.70, 0]) belt_pulley(4, -phase*0.35);
    translate([IW*0.78, IH*0.82, 0]) belt_pulley(5, phase*0.25);
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF (75mm shorter, with layered texture)
// ═══════════════════════════════════════════════════════════════════════════
module cliff_assembly() {
    // Base cliff
    color(C_CLIFF)
    linear_extrude(height=10)
    polygon([
        [0, 0],
        [0, CLIFF_HEIGHT],
        [CLIFF_WIDTH * 0.18, CLIFF_HEIGHT * 1.04],
        [CLIFF_WIDTH * 0.40, CLIFF_HEIGHT * 1.0],
        [CLIFF_WIDTH * 0.62, CLIFF_HEIGHT * 0.92],
        [CLIFF_WIDTH * 0.82, CLIFF_HEIGHT * 0.78],
        [CLIFF_WIDTH * 1.0, CLIFF_HEIGHT * 0.58],
        [CLIFF_WIDTH * 1.08, CLIFF_HEIGHT * 0.38],
        [CLIFF_WIDTH * 1.02, CLIFF_HEIGHT * 0.20],
        [CLIFF_WIDTH * 0.85, CLIFF_HEIGHT * 0.08],
        [CLIFF_WIDTH * 0.55, CLIFF_HEIGHT * 0.03],
        [CLIFF_WIDTH * 0.25, CLIFF_HEIGHT * 0.01],
        [0, 0]
    ]);
    
    // Middle layer
    translate([0, 0, 10])
    color(C_CLIFF_LAYER)
    linear_extrude(height=5)
    polygon([
        [3, CLIFF_HEIGHT * 0.12],
        [2, CLIFF_HEIGHT * 0.82],
        [CLIFF_WIDTH * 0.22, CLIFF_HEIGHT * 0.90],
        [CLIFF_WIDTH * 0.48, CLIFF_HEIGHT * 0.85],
        [CLIFF_WIDTH * 0.70, CLIFF_HEIGHT * 0.70],
        [CLIFF_WIDTH * 0.88, CLIFF_HEIGHT * 0.50],
        [CLIFF_WIDTH * 0.92, CLIFF_HEIGHT * 0.28],
        [CLIFF_WIDTH * 0.78, CLIFF_HEIGHT * 0.14],
        [CLIFF_WIDTH * 0.50, CLIFF_HEIGHT * 0.08],
        [CLIFF_WIDTH * 0.22, CLIFF_HEIGHT * 0.06],
        [3, CLIFF_HEIGHT * 0.12]
    ]);
    
    // Grass top
    translate([0, CLIFF_HEIGHT * 0.82, 15])
    color(C_CLIFF_GRASS)
    linear_extrude(height=4)
    polygon([
        [0, 0],
        [0, CLIFF_HEIGHT * 0.22],
        [CLIFF_WIDTH * 0.20, CLIFF_HEIGHT * 0.26],
        [CLIFF_WIDTH * 0.45, CLIFF_HEIGHT * 0.22],
        [CLIFF_WIDTH * 0.65, CLIFF_HEIGHT * 0.12],
        [CLIFF_WIDTH * 0.75, CLIFF_HEIGHT * 0.02],
        [CLIFF_WIDTH * 0.60, -CLIFF_HEIGHT * 0.06],
        [CLIFF_WIDTH * 0.32, -CLIFF_HEIGHT * 0.02],
        [0, 0]
    ]);
    
    // Rock texture lines
    color(C_CLIFF_DARK)
    for(i=[0:3]) {
        translate([4+i*15, CLIFF_HEIGHT*(0.15+i*0.15), 15])
        rotate([0,0,-12+i*6])
        linear_extrude(height=2)
        polygon([[0,0],[12,-0.6],[10,0.6]]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    // Keeper's house (LEFT of tower)
    translate([-16, -3, 0])
    color(C_LIGHTHOUSE) {
        cube([13, 10, 8]);
        translate([0, 5, 8])
        rotate([90, 0, 90])
        linear_extrude(height=13)
        polygon([[0,0], [5, 4], [10, 0]]);
    }
    
    // Main tower
    color(C_LIGHTHOUSE)
    linear_extrude(height=42, scale=0.70)
    circle(r=7);
    
    // Stripes
    color("#7a5535")
    for(z=[6, 17, 28])
        translate([0, 0, z])
        linear_extrude(height=4)
        circle(r=6.5 - z*0.04);
    
    // Platform
    translate([0, 0, 42])
    color("#333") cylinder(r=9.5, h=2.5);
    
    // Lamp room
    translate([0, 0, 44.5])
    color("LightYellow", 0.65)
    difference() {
        cylinder(r=7, h=9);
        translate([0, 0, 1.5]) cylinder(r=6, h=10);
    }
    
    // Light
    translate([0, 0, 50])
    color("Yellow", 0.9)
    sphere(r=3.2);
    
    // Very slow rotating beam
    translate([0, 0, 49])
    rotate([0, 0, beam_rot * 360])
    color("Yellow", 0.42)
    linear_extrude(height=4)
    polygon([[0,0], [22, -1.6], [22, 1.6]]);
    
    // Roof
    translate([0, 0, 53.5])
    color("#7a5535")
    cylinder(r1=8.5, r2=2.2, h=6.5);
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD FLOCK ON LOOPED WIRE
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

function wire_pos(t_val, wire_num) = 
    let(
        x = IW * (0.12 + 0.78 * t_val),
        y_base = wire_num == 0 ? IH * 0.50 : IH * 0.50 + 7,
        y_wave = 7 * sin(t_val * 360 * 2.2)
    )
    [x, y_base + y_wave];

module bird_flock_wires(progress, bob) {
    // Wire 1 (lower)
    color(C_WIRE)
    for(i=[0:32]) {
        p1 = wire_pos(i/32, 0);
        p2 = wire_pos((i+1)/32, 0);
        hull() {
            translate([p1[0], p1[1], 0]) sphere(r=0.55);
            translate([p2[0], p2[1], 0]) sphere(r=0.55);
        }
    }
    
    // Wire 2 (upper, 7mm apart)
    color(C_WIRE)
    for(i=[0:32]) {
        p1 = wire_pos(i/32, 1);
        p2 = wire_pos((i+1)/32, 1);
        hull() {
            translate([p1[0], p1[1], 0]) sphere(r=0.55);
            translate([p2[0], p2[1], 0]) sphere(r=0.55);
        }
    }
    
    // Loop connectors
    color(C_WIRE) {
        translate([IW*0.12, IH*0.50 + 3.5, 0]) 
        rotate([90, 0, 90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.55);
        translate([IW*0.90, IH*0.50 + 3.5, 0]) 
        rotate([90, 0, -90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.55);
    }
    
    // Wire supports
    color(C_GEAR_DARK) {
        translate([IW*0.08, IH*0.50, -7]) cylinder(r=1.8, h=9);
        translate([IW*0.92, IH*0.50, -7]) cylinder(r=1.8, h=9);
    }
    
    // Birds
    bird1_pos = wire_pos(progress, 0);
    translate([bird1_pos[0], bird1_pos[1], 2 + bob]) bird_simple();
    
    bird2_pos = wire_pos((progress + 0.35) % 1, 0);
    translate([bird2_pos[0], bird2_pos[1], 2 + bob*0.85]) bird_simple();
    
    bird3_pos = wire_pos(1 - progress, 1);
    translate([bird3_pos[0], bird3_pos[1], 2 + bob*1.1]) rotate([0, 0, 180]) bird_simple();
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_placed() {
    translate([IW * 0.38, IH * 0.68, 0])
    scale([0.125, 0.138, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS
// ═══════════════════════════════════════════════════════════════════════════
module cypress_placed() {
    // Moved right, 5mm from cliff waves
    translate([CLIFF_WIDTH + 15, IH * 0.42, 0])
    scale([0.85, 0.85, 1])
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVES - Surrounding cliff, going up to cliff top height
// ═══════════════════════════════════════════════════════════════════════════

// Wave start position (shifted right to surround cliff)
WAVE_X = CLIFF_WIDTH + 5;  // Start just past cliff edge

// Cliff waves - surrounding cliff, going high
module cliff_waves_surrounding(drift, surge, crash, tilt) {
    // Wave layer 1 - at cliff base, going right
    translate([WAVE_X + drift*0.7, 8 + surge*0.8, 0])
    scale([0.34, 0.34, 1])
    color(C_WAVE_DARK)
    cliff_wave_L1(1);
    
    // Wave layer 2 - slightly higher
    translate([WAVE_X + 12 + drift*0.55, 15 + surge*0.7, 0])
    scale([0.32, 0.32, 1])
    color(C_WAVE_MED)
    cliff_wave_L2(1);
    
    // Crashing wave 1 - climbing cliff side
    translate([WAVE_X - 15 + drift*0.4, 25 + crash, 0])
    rotate([0, 0, 12 + tilt])
    scale([0.30, 0.30, 1])
    color(C_WAVE_MED)
    cliff_wave_L3(1);
    
    // Crashing wave 2 - mid cliff
    translate([WAVE_X - 25 + drift*0.3, 48 + crash*0.85, 0])
    rotate([0, 0, 22 + tilt*0.8])
    scale([0.26, 0.26, 1])
    color(C_WAVE_FOAM, 0.92)
    cliff_wave_L3(1);
    
    // Crashing wave 3 - near cliff top
    translate([WAVE_X - 32 + drift*0.2, 72 + crash*0.65, 0])
    rotate([0, 0, 32 + tilt*0.6])
    scale([0.22, 0.22, 1])
    color(C_WAVE_FOAM, 0.85)
    cliff_wave_L3(1);
    
    // Spray at cliff top
    translate([WAVE_X - 38 + drift*0.12, 92 + crash*0.45, 0])
    rotate([0, 0, 42 + tilt*0.4])
    scale([0.18, 0.18, 1])
    color(C_WAVE_FOAM, 0.75)
    cliff_wave_L3(1);
}

// Ocean waves - extending to right edge
module ocean_waves_extended(drift, surge) {
    // Layer 1 (back)
    translate([WAVE_X + 45 + drift*0.6, IH*0.12 + surge, 0])
    scale([1.25, 1.25, 1])
    color(C_WAVE_DARK)
    ocean_wave_L1(1);
    
    // Layer 2 (mid)
    translate([WAVE_X + 70 + drift*0.45, IH*0.14 + surge*0.85, 0])
    scale([1.20, 1.20, 1])
    color(C_WAVE_MED)
    ocean_wave_L2(1);
    
    // Layer 3 (front)
    translate([WAVE_X + 95 + drift*0.32, IH*0.16 + surge*0.7, 0])
    scale([1.15, 1.15, 1])
    color(C_WAVE_FOAM)
    ocean_wave_L3(1);
    
    // Far right waves
    translate([IW*0.78 + drift*0.22, IH*0.13 + surge*0.5, 0])
    scale([1.0, 1.0, 1])
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
// SKY GEARS (FOREGROUND ONLY)
// ═══════════════════════════════════════════════════════════════════════════
module sky_gears_foreground(r1, r2, r3, r4) {
    // Left cluster
    translate([IW*0.06, IH*0.62, 0]) rotate([0,0,r1]) gear(16, 14, 4);
    translate([IW*0.16, IH*0.55, 0]) rotate([0,0,r2]) gear(13, 11, 4);
    translate([IW*0.04, IH*0.50, 0]) rotate([0,0,r3]) gear(11, 9, 3);
    
    // Top center
    translate([IW*0.34, IH*0.94, 0]) rotate([0,0,r1*0.85]) gear(14, 12, 4);
    translate([IW*0.46, IH*0.90, 0]) rotate([0,0,r2*0.92]) gear(11, 9, 3);
    
    // Right cluster
    translate([IW*0.70, IH*0.84, 0]) rotate([0,0,r3*1.08]) gear(13, 11, 4);
    translate([IW*0.76, IH*0.70, 0]) rotate([0,0,r4]) gear(10, 8, 3);
    translate([IW*0.66, IH*0.74, 0]) rotate([0,0,r1*1.15]) gear(10, 8, 3);
    
    // Scattered
    translate([IW*0.54, IH*0.80, 0]) rotate([0,0,r2*1.05]) gear(8, 6, 3);
    translate([IW*0.24, IH*0.84, 0]) rotate([0,0,r4*0.88]) gear(9, 7, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS (SMALL, UNDER WAVES, NEAR FRAME EDGE)
// ═══════════════════════════════════════════════════════════════════════════
module bottom_gears_small(rot) {
    // Very small gears, positioned low near bottom frame edge
    // Clearance above wave layer ensured by Z positioning
    
    translate([IW*0.52, IH*0.018, 0]) rotate([0,0,rot]) 
        gear(10, 8, 3, 1.5, C_GEAR_DARK);
    
    translate([IW*0.64, IH*0.028, 0]) rotate([0,0,-rot*0.88]) 
        gear(8, 6.5, 3, 1.3, C_GEAR_DARK);
    
    translate([IW*0.74, IH*0.018, 0]) rotate([0,0,rot*1.12]) 
        gear(7, 5.5, 2.5, 1.2, C_GEAR_DARK);
    
    translate([IW*0.83, IH*0.025, 0]) rotate([0,0,-rot*1.28]) 
        gear(6, 4.5, 2.5, 1, C_GEAR_DARK);
    
    translate([IW*0.91, IH*0.015, 0]) rotate([0,0,rot*1.45]) 
        gear(5, 3.5, 2, 0.8, C_GEAR_DARK);
    
    // Linkage arm connecting to wave mechanism
    translate([IW*0.58, IH*0.05, 0])
    rotate([0, 0, rot*0.5])
    color(C_GEAR)
    hull() {
        cylinder(r=1.5, h=2.5);
        translate([12, 0, 0]) cylinder(r=1.2, h=2.5);
    }
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
color(C_SKY, 0.72)
translate([FW, FW, Z_SKY])
cube([IW, IH, 2]);

// BOTTOM GEARS (under waves, near frame edge)
translate([FW, FW, Z_BOTTOM_GEARS])
bottom_gears_small(gear_bottom);

// MOON (right side)
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON])
moon_assembly(moon_rot, moon_halo_1, moon_halo_2);

// STARS
translate([FW, FW, Z_STARS])
all_stars(star_rot, star_halo_rot);

// SWIRL DISCS (positioned under wind path cutouts)
// Large swirl - center-left
translate([FW + IW*0.22, FW + IH*0.62, Z_SWIRL_BACK])
swirl_disc_counter_rotating(35, swirl_rot_1, swirl_counter_1);

// Small swirl - center-right
translate([FW + IW*0.44, FW + IH*0.52, Z_SWIRL_BACK])
swirl_disc_counter_rotating(26, swirl_rot_2, swirl_counter_2);

// WIND PATH
translate([FW, FW, Z_WIND])
wind_path_placed();

// BELT CONNECTIONS
translate([FW, FW, Z_BELTS])
belt_connections(belt_phase);

// CLIFF (75mm shorter)
translate([FW, FW, Z_CLIFFS])
cliff_assembly();

// LIGHTHOUSE
translate([FW + CLIFF_WIDTH * 0.30, FW + CLIFF_HEIGHT * 0.92, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_beam);

// CLIFF WAVES (surrounding cliff, going high)
translate([FW, FW, Z_WAVE_1])
cliff_waves_surrounding(wave_drift, wave_surge, wave_crash, wave_tilt);

// OCEAN WAVES (extended to right)
translate([FW, FW, Z_WAVE_2])
ocean_waves_extended(wave_drift, wave_surge);

// CYPRESS (moved right)
translate([FW, FW, Z_CYPRESS])
cypress_placed();

// SKY GEARS (FOREGROUND ONLY)
translate([FW, FW, Z_SKY_GEARS])
sky_gears_foreground(gear_sky_1, gear_sky_2, gear_sky_3, gear_sky_4);

// BIRD FLOCK WIRE
translate([FW, FW, Z_BIRD_WIRE])
bird_flock_wires(bird_progress, bird_bob);

// FRAME
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V34 - HIGH-END MECHANICAL ART");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "mm | Inner:", IW, "×", IH, "mm");
echo("");
echo("KEY CHANGES FROM V30:");
echo("  • Cliff: 75mm shorter (now", CLIFF_WIDTH, "mm)");
echo("  • Cliff waves: Shifted right, surrounding cliff");
echo("  • Cliff waves: Rising to cliff top height (spray at 92mm)");
echo("  • Sky gears: ONLY foreground gears (Z=52)");
echo("  • Bottom gears: Smaller (3.5-8mm), under waves (Z=6)");
echo("  • Swirl discs: Counter-rotating grey discs (like moon halos)");
echo("  • Swirl discs: 3-part design (blue + grey + dark grey ring)");
echo("");
echo("MECHANICAL DRIVE SYSTEM:");
echo("  Master drive → all motion via gear ratios");
echo("  No microchips - pure mechanical art");
echo("");
echo("GEAR RATIOS:");
echo("  Swirls:      45:1, 40:1 (slow, hypnotic)");
echo("  Moon:        70:1 to 100:1 (slowest)");
echo("  Stars:       30:1 (subtle)");
echo("  Wave cam:    25:1 (ocean rhythm)");
echo("  Lighthouse:  200:1 (very slow beam)");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
