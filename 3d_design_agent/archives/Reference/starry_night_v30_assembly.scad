// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V30 - MECHANICAL MASTERPIECE
// Prominent gears/belts, bird flock, crashing waves, enhanced steampunk
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

// CLIFF DIMENSIONS
CLIFF_WIDTH = 165;
CLIFF_HEIGHT = 105;

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;

// Swirl rotations
swirl_rot_1 = t * 360 * 0.4;
swirl_rot_2 = -t * 360 * 0.55;
swirl_counter_1 = -t * 360 * 0.3;  // Counter rotation
swirl_counter_2 = t * 360 * 0.45;

// Moon (15% smaller)
moon_rot = t * 360 * 0.25;
moon_halo_1 = -t * 360 * 0.18;
moon_halo_2 = t * 360 * 0.22;

// Stars
star_rot = t * 360 * 0.6;
star_halo_rot = -t * 360 * 0.4;

// Waves
wave_drift = 5 * sin(t * 360);
wave_surge = 3 * sin(t * 360);
wave_tilt = 4 * sin(t * 360);

// Gears and belts
gear_rot = t * 360 * 0.35;
belt_phase = t * 360;

// Lighthouse (5x slower)
lighthouse_beam = t * 360 * 1;  // Was *5, now *1

// Bird flock movement (looping)
bird_progress = t;  // 0 to 1 for full loop
bird_bob = 2 * sin(t * 360 * 3);

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = "#5a4030";
C_SKY = "#4a7ab0";
C_CLIFF = "#8b7355";
C_CLIFF_LINE = "#6b5344";
C_WIND = "#3a6a9e";
C_SWIRL_A = "#2a5a8e";
C_SWIRL_B = "#5a5a5a";  // Grey counter-rotating
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
C_LIGHTHOUSE = "#d4c4a8";
C_BIRD = "#2a2a2a";
C_WIRE = "#3a3a3a";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS (gears/belts now FOREGROUND)
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_MOON = 8;
Z_STARS = 10;
Z_SWIRLS = 14;
Z_WIND = 18;
Z_CLIFFS = 22;
Z_LIGHTHOUSE = 25;
Z_WAVE_BASE = 28;
Z_WAVE_CRASH = 35;
Z_CYPRESS = 42;
Z_BELTS = 48;       // Foreground
Z_GEARS = 52;       // Foreground - prominent
Z_BIRD_WIRE = 55;   // Foreground
Z_FRAME = 60;

// ═══════════════════════════════════════════════════════════════════════════
// GEAR MODULE (prominent)
// ═══════════════════════════════════════════════════════════════════════════
module gear(teeth, r, th=5, hole_r=0) {
    tooth_h = r * 0.16;
    actual_hole = hole_r > 0 ? hole_r : r * 0.15;
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=r-tooth_h, h=th);
            for(i=[0:teeth-1]) rotate([0,0,i*360/teeth])
                translate([r-tooth_h,0,0]) cylinder(r=tooth_h*1.3, h=th, $fn=6);
        }
        translate([0,0,-1]) cylinder(r=actual_hole, h=th+2);
        if(r > 10) for(i=[0:4]) rotate([0,0,i*72+36])
            translate([r*0.5,0,-1]) cylinder(r=r*0.15, h=th+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAR GEAR WITH DUAL COUNTER-ROTATING HALOS (1mm spacing)
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
    
    // Halo A (outer) - rotates one way
    translate([0,0,-3]) rotate([0,0,halo_rot])
    color(C_GEAR_DARK, 0.8) difference() {
        cylinder(r=r*1.6, h=2);
        translate([0,0,-1]) cylinder(r=r*1.1, h=4);
        for(i=[0:5]) rotate([0,0,i*60]) translate([r*1.35,0,-1]) cylinder(r=r*0.15, h=4);
    }
    
    // 1mm gap
    
    // Halo B (middle) - rotates opposite
    translate([0,0,-6]) rotate([0,0,-halo_rot*0.8])
    color(C_GEAR, 0.7) difference() {
        cylinder(r=r*1.35, h=2);
        translate([0,0,-1]) cylinder(r=r*0.95, h=4);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([r*1.15,0,-1]) cylinder(r=r*0.1, h=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUNTER-ROTATING SWIRL DISC (two parts, grey texture)
// ═══════════════════════════════════════════════════════════════════════════
module swirl_disc_dual(r, rot1, rot2) {
    // Part A - main swirl (blue)
    rotate([0,0,rot1]) color(C_SWIRL_A, 0.9)
    difference() {
        cylinder(r=r, h=5);
        translate([0,0,-1]) cylinder(r=r*0.08, h=7);
        for(i=[0:2]) rotate([0,0,i*120]) translate([r*0.6,0,-1]) cylinder(r=r*0.1, h=7);
        // Spiral grooves
        for(i=[0:5]) rotate([0,0,i*60]) 
            translate([r*0.3, 0, -1]) rotate([0,0,30]) cube([r*0.5, 2, 7]);
    }
    
    // 1mm gap
    
    // Part B - counter swirl (grey, textured)
    translate([0,0,-6]) rotate([0,0,rot2]) color(C_SWIRL_B, 0.85)
    difference() {
        cylinder(r=r*0.85, h=4);
        translate([0,0,-1]) cylinder(r=r*0.1, h=6);
        // Different texture - radial slots
        for(i=[0:7]) rotate([0,0,i*45]) 
            translate([r*0.4, -1, -1]) cube([r*0.35, 2, 6]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON ASSEMBLY (15% smaller, dual halos with 1mm spacing)
// ═══════════════════════════════════════════════════════════════════════════
module moon_assembly_small(rot, halo1_rot, halo2_rot) {
    // Scale factor 0.85 (15% smaller)
    s = 0.85;
    
    // Halo A (outermost)
    translate([0,0,-5]) rotate([0,0,halo1_rot])
    color(C_MOON_HALO_A, 0.5) difference() {
        cylinder(r=50*s, h=3);
        translate([0,0,-1]) cylinder(r=38*s, h=5);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([44*s,0,-1]) cylinder(r=3.5*s, h=5);
    }
    
    // 1mm gap
    
    // Halo B (middle)
    translate([0,0,-9]) rotate([0,0,halo2_rot])
    color(C_MOON_HALO_B, 0.6) difference() {
        cylinder(r=42*s, h=3);
        translate([0,0,-1]) cylinder(r=32*s, h=5);
        for(i=[0:5]) rotate([0,0,i*60]) translate([37*s,0,-1]) cylinder(r=2.5*s, h=5);
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
        for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([45*s, 3, 6]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BELT MECHANISM (prominent, connects stars to swirls)
// ═══════════════════════════════════════════════════════════════════════════
module belt_path(points, phase, th=2) {
    color(C_BELT)
    for(i=[0:len(points)-2]) {
        x1 = points[i][0]; y1 = points[i][1];
        x2 = points[i+1][0]; y2 = points[i+1][1];
        dx = x2 - x1; dy = y2 - y1;
        len_seg = sqrt(dx*dx + dy*dy);
        ang = atan2(dy, dx);
        
        translate([x1, y1, 0]) rotate([0, 0, ang])
        for(j=[0:floor(len_seg/5)]) {
            offset = (j * 5 + phase * 0.15) % max(len_seg, 1);
            if(offset < len_seg - 3)
            translate([offset, -1.5, 0]) cube([4, 3, th]);
        }
    }
}

module belt_pulley(r, rot) {
    rotate([0,0,rot]) color(C_GEAR_DARK) difference() {
        cylinder(r=r, h=4);
        translate([0,0,-1]) cylinder(r=r*0.25, h=6);
        for(i=[0:11]) rotate([0,0,i*30]) translate([r*0.65,0,-1]) cylinder(r=1.2, h=6);
    }
}

// Star-to-Swirl belt system
module star_swirl_belts(phase) {
    // Belt from stars to big swirl
    belt_path([
        [IW*0.28, IH*0.78],  // Star
        [IW*0.22, IH*0.70],  // Bend
        [IW*0.22, IH*0.62]   // Big swirl
    ], phase, 2);
    
    // Belt from another star to small swirl
    belt_path([
        [IW*0.55, IH*0.82],  // Star
        [IW*0.50, IH*0.72],  // Bend
        [IW*0.44, IH*0.52]   // Small swirl (lowered 5mm)
    ], phase, 2);
    
    // Belt pulleys
    translate([IW*0.22, IH*0.70, 0]) belt_pulley(5, phase*0.3);
    translate([IW*0.50, IH*0.72, 0]) belt_pulley(4, -phase*0.35);
}

// Moon belt system
module moon_belt_system(phase) {
    belt_path([
        [IW*0.88, IH*0.82],  // Moon area
        [IW*0.75, IH*0.75],
        [IW*0.68, IH*0.68],
        [IW*0.65, IH*0.55]
    ], phase, 2);
    
    translate([IW*0.75, IH*0.75, 0]) belt_pulley(6, phase*0.25);
    translate([IW*0.68, IH*0.68, 0]) belt_pulley(5, -phase*0.3);
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF WITH CENTRAL LINE (illusion of two cliffs pressed together)
// ═══════════════════════════════════════════════════════════════════════════
module cliff_with_line() {
    // Main cliff body
    color(C_CLIFF)
    linear_extrude(height=12)
    polygon([
        [0, 0],
        [0, CLIFF_HEIGHT],
        [CLIFF_WIDTH * 0.15, CLIFF_HEIGHT * 1.02],
        [CLIFF_WIDTH * 0.35, CLIFF_HEIGHT * 0.96],
        [CLIFF_WIDTH * 0.55, CLIFF_HEIGHT * 0.88],
        [CLIFF_WIDTH * 0.75, CLIFF_HEIGHT * 0.72],
        [CLIFF_WIDTH * 0.90, CLIFF_HEIGHT * 0.52],
        [CLIFF_WIDTH, CLIFF_HEIGHT * 0.35],
        [CLIFF_WIDTH * 0.95, CLIFF_HEIGHT * 0.18],
        [CLIFF_WIDTH * 0.80, CLIFF_HEIGHT * 0.08],
        [CLIFF_WIDTH * 0.55, CLIFF_HEIGHT * 0.03],
        [CLIFF_WIDTH * 0.25, CLIFF_HEIGHT * 0.01],
        [0, 0]
    ]);
    
    // Central dividing line (offset right, giving illusion of two cliffs)
    color(C_CLIFF_LINE)
    translate([CLIFF_WIDTH * 0.45, 0, 12])
    linear_extrude(height=2)
    polygon([
        [0, CLIFF_HEIGHT * 0.05],
        [-3, CLIFF_HEIGHT * 0.25],
        [-2, CLIFF_HEIGHT * 0.45],
        [0, CLIFF_HEIGHT * 0.65],
        [3, CLIFF_HEIGHT * 0.80],
        [5, CLIFF_HEIGHT * 0.88],
        [4, CLIFF_HEIGHT * 0.75],
        [2, CLIFF_HEIGHT * 0.55],
        [3, CLIFF_HEIGHT * 0.35],
        [1, CLIFF_HEIGHT * 0.15],
        [0, CLIFF_HEIGHT * 0.05]
    ]);
    
    // Texture lines
    color(C_CLIFF_LINE)
    for(i=[0:4]) {
        translate([8 + i*18, CLIFF_HEIGHT * (0.15 + i*0.12), 12])
        rotate([0, 0, -15 + i*8])
        linear_extrude(height=2)
        polygon([[0,0], [12,-0.8], [10,0.8]]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    // Hut on LEFT
    translate([-16, -2, 0]) color(C_LIGHTHOUSE) {
        cube([12, 9, 7]);
        translate([0, 4.5, 7]) rotate([90,0,90]) linear_extrude(12) polygon([[0,0],[4.5,3.5],[9,0]]);
    }
    // Tower
    color(C_LIGHTHOUSE) linear_extrude(40, scale=0.72) circle(r=7);
    color("#8b6914") for(z=[5,15,25]) translate([0,0,z]) linear_extrude(4) circle(r=6.2-z*0.03);
    translate([0,0,40]) color("#333") cylinder(r=9, h=2);
    translate([0,0,42]) color("LightYellow", 0.7) difference() { cylinder(r=6,h=7); translate([0,0,1]) cylinder(r=5,h=8); }
    translate([0,0,46]) color("Yellow") sphere(r=2.5);
    // Slower beam
    translate([0,0,44]) rotate([0,0,beam_rot]) color("Yellow", 0.5) linear_extrude(4) polygon([[0,0],[18,-1.2],[18,1.2]]);
    translate([0,0,49]) color("#8b4513") cylinder(r1=8, r2=2, h=6);
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD FLOCK ON LOOPED WIRE (3 birds, 2 parallel wires)
// ═══════════════════════════════════════════════════════════════════════════
module bird_simple() {
    // Body
    color(C_BIRD) scale([1, 0.5, 0.35]) sphere(r=4);
    // Head
    translate([3.5, 0, 1]) color(C_BIRD) sphere(r=2);
    // Beak
    translate([5.5, 0, 1]) color("#d4a030") rotate([0, 90, 0]) cylinder(r1=0.8, r2=0, h=2.5, $fn=6);
    // Wings (static)
    color(C_BIRD) for(s=[-1,1]) translate([0, s*3, 0]) rotate([s*15, 0, 8])
        scale([1, 0.12, 0.5]) sphere(r=4);
    // Tail
    translate([-4, 0, 0]) color(C_BIRD) rotate([0, -12, 0]) scale([1.2, 0.08, 0.35]) sphere(r=3);
}

// Looped wire path function
function wire_pos(t_val, wire_num) = 
    let(
        // Wave pattern for loop effect
        x = IW * (0.1 + 0.8 * t_val),
        y_base = wire_num == 0 ? IH * 0.48 : IH * 0.48 + 7,
        y_wave = 8 * sin(t_val * 360 * 2)  // Two loops across
    )
    [x, y_base + y_wave];

module bird_flock_wires(progress, bob) {
    // Wire 1 (lower) - birds go L to R
    color(C_WIRE)
    for(i=[0:30]) {
        p1 = wire_pos(i/30, 0);
        p2 = wire_pos((i+1)/30, 0);
        hull() {
            translate([p1[0], p1[1], 0]) sphere(r=0.6);
            translate([p2[0], p2[1], 0]) sphere(r=0.6);
        }
    }
    
    // Wire 2 (upper, 7mm apart) - birds go R to L
    color(C_WIRE)
    for(i=[0:30]) {
        p1 = wire_pos(i/30, 1);
        p2 = wire_pos((i+1)/30, 1);
        hull() {
            translate([p1[0], p1[1], 0]) sphere(r=0.6);
            translate([p2[0], p2[1], 0]) sphere(r=0.6);
        }
    }
    
    // Loop connectors at ends
    color(C_WIRE) {
        // Left loop
        translate([IW*0.1, IH*0.48 + 3.5, 0]) 
        rotate([90, 0, 90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.6);
        // Right loop
        translate([IW*0.9, IH*0.48 + 3.5, 0]) 
        rotate([90, 0, -90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.6);
    }
    
    // Wire supports
    color(C_GEAR_DARK) {
        translate([IW*0.05, IH*0.48, -8]) cylinder(r=2, h=10);
        translate([IW*0.95, IH*0.48, -8]) cylinder(r=2, h=10);
        translate([IW*0.50, IH*0.48 + 15, -8]) cylinder(r=1.5, h=10);
    }
    
    // Bird 1 on wire 1 (L to R)
    bird1_t = progress;
    bird1_pos = wire_pos(bird1_t, 0);
    translate([bird1_pos[0], bird1_pos[1], 2 + bob]) 
    rotate([0, 0, 0])  // Facing right
    bird_simple();
    
    // Bird 2 on wire 1 (L to R, offset)
    bird2_t = (progress + 0.33) % 1;
    bird2_pos = wire_pos(bird2_t, 0);
    translate([bird2_pos[0], bird2_pos[1], 2 + bob*0.8]) 
    rotate([0, 0, 0])
    bird_simple();
    
    // Bird 3 on wire 2 (R to L)
    bird3_t = 1 - progress;  // Reverse direction
    bird3_pos = wire_pos(bird3_t, 1);
    translate([bird3_pos[0], bird3_pos[1], 2 + bob*1.2]) 
    rotate([0, 0, 180])  // Facing left
    bird_simple();
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH (10% bigger, extended down)
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_placed() {
    // Original 0.114, +10% = 0.1254
    // Scale Y more to extend breadth downward
    translate([892 * 0.1254, IH * 0.70, 0])
    scale([0.1254, 0.138, 1])  // Y stretched more
    color(C_WIND)
    wind_path_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVES
// ═══════════════════════════════════════════════════════════════════════════
WAVE_START_X = CLIFF_WIDTH - 25;
WAVE_END_X = IW - 5;

module cliff_wave_1_placed(drift) {
    translate([WAVE_START_X + drift, 5, 0])
    scale([0.32, 0.32, 1])
    color(C_WAVE_DARK) cliff_wave_L1(1);
}

module cliff_wave_2_placed(drift) {
    translate([WAVE_START_X + 15 + drift*0.7, 8, 0])
    scale([0.304, 0.304, 1])
    color(C_WAVE_MED) cliff_wave_L2(1);
}

// CRASHING WAVE 3 (4 copies wrapping around cliff base)
module crashing_waves(drift, tilt) {
    // Wave 3 copy 1 - at cliff base
    translate([WAVE_START_X - 30 + drift*0.3, 15, 0])
    rotate([0, 0, tilt * 1.2])
    scale([0.28, 0.28, 1])
    color(C_WAVE_FOAM) cliff_wave_L3(1);
    
    // Wave 3 copy 2 - climbing cliff
    translate([WAVE_START_X - 45 + drift*0.2, 35, 0])
    rotate([0, 0, 15 + tilt * 0.8])
    scale([0.24, 0.24, 1])
    color(C_WAVE_FOAM, 0.9) cliff_wave_L3(1);
    
    // Wave 3 copy 3 - higher up cliff
    translate([WAVE_START_X - 55 + drift*0.15, 55, 0])
    rotate([0, 0, 25 + tilt * 0.6])
    scale([0.20, 0.20, 1])
    color(C_WAVE_FOAM, 0.8) cliff_wave_L3(1);
    
    // Wave 3 copy 4 - near cliff top
    translate([WAVE_START_X - 60 + drift*0.1, 75, 0])
    rotate([0, 0, 35 + tilt * 0.4])
    scale([0.16, 0.16, 1])
    color(C_WAVE_FOAM, 0.7) cliff_wave_L3(1);
    
    // Original wave 3 position
    translate([WAVE_START_X + 5 + drift*0.4, 12, 0])
    rotate([0, 0, tilt * 0.8])
    scale([0.256, 0.256, 1])
    color(C_WAVE_FOAM) cliff_wave_L3(1);
}

module ocean_wave_1_placed(drift) {
    translate([WAVE_START_X + 80 + drift*0.3, IH*0.08, 0])
    scale([1.4, 1.4, 1])
    color(C_WAVE_DARK) ocean_wave_L1(1);
}

module ocean_wave_2_placed(drift) {
    translate([WAVE_START_X + 100 + drift*0.5, IH*0.10, 0])
    scale([1.35, 1.35, 1])
    color(C_WAVE_MED) ocean_wave_L2(1);
}

module ocean_wave_3_placed(surge) {
    translate([WAVE_START_X + 120, IH*0.12 + surge, 0])
    scale([1.3, 1.3, 1])
    color(C_WAVE_FOAM) ocean_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS (moved further right, 5mm from cliff waves)
// ═══════════════════════════════════════════════════════════════════════════
module cypress_placed() {
    // Position 5mm from cliff wave edge
    translate([WAVE_START_X - 50, 112.6 * 0.9, 0])
    scale([0.9, 0.9, 1])
    color(C_CYPRESS) cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// STARS
// ═══════════════════════════════════════════════════════════════════════════
module all_stars(rot, halo_rot) {
    translate([IW*0.15, IH*0.90, 0]) star_gear(7, rot, halo_rot);
    translate([IW*0.28, IH*0.78, 0]) star_gear(6, -rot*1.2, -halo_rot*0.9);
    translate([IW*0.42, IH*0.94, 0]) star_gear(6, rot*0.8, halo_rot*1.1);
    translate([IW*0.55, IH*0.82, 0]) star_gear(5, -rot*1.4, -halo_rot*0.8);
    translate([IW*0.35, IH*0.70, 0]) star_gear(5, rot*1.1, halo_rot*0.95);
    translate([IW*0.68, IH*0.92, 0]) star_gear(6, -rot*0.9, -halo_rot*1.05);
}

// ═══════════════════════════════════════════════════════════════════════════
// PROMINENT FOREGROUND GEARS
// ═══════════════════════════════════════════════════════════════════════════
module foreground_gears(rot) {
    // Large prominent gears
    translate([IW*0.12, IH*0.15, 0]) rotate([0,0,rot]) gear(30, 35, 6);
    translate([IW*0.85, IH*0.08, 0]) rotate([0,0,-rot*0.8]) gear(28, 32, 6);
    translate([IW*0.70, IH*0.18, 0]) rotate([0,0,rot*1.1]) gear(24, 28, 5);
    
    // Medium gears
    translate([IW*0.25, IH*0.08, 0]) rotate([0,0,-rot*1.2]) gear(22, 25, 5);
    translate([IW*0.92, IH*0.20, 0]) rotate([0,0,rot*0.9]) gear(20, 22, 5);
    translate([IW*0.55, IH*0.05, 0]) rotate([0,0,-rot*1.4]) gear(18, 20, 4);
    
    // Small gears
    translate([IW*0.40, IH*0.12, 0]) rotate([0,0,rot*1.6]) gear(14, 16, 4);
    translate([IW*0.78, IH*0.04, 0]) rotate([0,0,-rot*1.8]) gear(12, 14, 4);
    translate([IW*0.95, IH*0.12, 0]) rotate([0,0,rot*2]) gear(10, 11, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// FRAME
// ═══════════════════════════════════════════════════════════════════════════
module frame() {
    color(C_FRAME) difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1]) cube([IW, IH, 12]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                           MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// SKY
color(C_SKY, 0.7) translate([FW, FW, Z_SKY]) cube([IW, IH, 2]);

// MOON (15% smaller, moved top-right)
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON])
moon_assembly_small(moon_rot, moon_halo_1, moon_halo_2);

// STARS
translate([FW, FW, Z_STARS]) all_stars(star_rot, star_halo_rot);

// SWIRL DISCS (positioned under wind path cutouts)
// Big swirl - under large cutout
translate([FW + IW*0.22, FW + IH*0.62, Z_SWIRLS])
swirl_disc_dual(32, swirl_rot_1, swirl_counter_1);

// Small swirl - under smaller cutout, 5mm lower
translate([FW + IW*0.44, FW + IH*0.52, Z_SWIRLS])
swirl_disc_dual(24, swirl_rot_2, swirl_counter_2);

// WIND PATH (10% bigger)
translate([FW, FW, Z_WIND]) wind_path_placed();

// CLIFF
translate([FW, FW, Z_CLIFFS]) cliff_with_line();

// LIGHTHOUSE
translate([FW + CLIFF_WIDTH * 0.22, FW + CLIFF_HEIGHT * 0.90, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_beam);

// WAVES
translate([FW, FW, Z_WAVE_BASE]) cliff_wave_1_placed(wave_drift);
translate([FW, FW, Z_WAVE_BASE+3]) cliff_wave_2_placed(wave_drift*0.7);

// CRASHING WAVES (4 copies wrapping cliff)
translate([FW, FW, Z_WAVE_CRASH]) crashing_waves(wave_drift, wave_tilt);

// OCEAN WAVES
translate([FW, FW, Z_WAVE_BASE+1]) ocean_wave_1_placed(wave_drift*0.5);
translate([FW, FW, Z_WAVE_BASE+4]) ocean_wave_2_placed(wave_drift*0.6);
translate([FW, FW, Z_WAVE_CRASH+2]) ocean_wave_3_placed(wave_surge);

// CYPRESS
translate([FW, FW, Z_CYPRESS]) cypress_placed();

// BELT MECHANISMS (foreground)
translate([FW, FW, Z_BELTS]) {
    star_swirl_belts(belt_phase);
    moon_belt_system(belt_phase);
}

// PROMINENT GEARS (foreground)
translate([FW, FW, Z_GEARS]) foreground_gears(gear_rot);

// BIRD FLOCK WIRE (foreground)
translate([FW, FW, Z_BIRD_WIRE]) bird_flock_wires(bird_progress, bird_bob);

// FRAME
translate([0, 0, Z_FRAME]) frame();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V30 - MECHANICAL MASTERPIECE");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "| Inner:", IW, "×", IH);
echo("UPDATES:");
echo("  • Gears/belts now FOREGROUND (Z=48-52)");
echo("  • Wind path +10%, extended breadth");
echo("  • Swirls: counter-rotating dual discs");
echo("  • Moon: 15% smaller, dual halos, top-right");
echo("  • Stars connected to swirls via belts");
echo("  • All halos: dual parts, 1mm spacing");
echo("  • Lighthouse beam 5x slower");
echo("  • Cypress 5mm from waves");
echo("  • Bird flock: 3 birds, looped parallel wires");
echo("  • Crashing waves: 4x wave3 wrapping cliff");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
