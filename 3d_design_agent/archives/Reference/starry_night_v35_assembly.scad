// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V35 - HIGH-END MECHANICAL ART
// All changes implemented from V34 feedback
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
W = 350;
H = 275;
FW = 20;
IW = W - FW*2;  // 310mm
IH = H - FW*2;  // 235mm

// CLIFF DIMENSIONS (75mm shorter)
CLIFF_WIDTH = 90;
CLIFF_HEIGHT = 105;

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH CIRCULAR CUTOUTS - Positioned for swirl discs
// Wind path must touch left edge (X=0)
// ═══════════════════════════════════════════════════════════════════════════
// Big cutout center (positioned under wind path)
BIG_CUTOUT_X = IW * 0.22;
BIG_CUTOUT_Y = IH * 0.62;
BIG_CUTOUT_R = 38;  // Radius of circular cutout

// Small cutout center
SMALL_CUTOUT_X = IW * 0.44;
SMALL_CUTOUT_Y = IH * 0.52;
SMALL_CUTOUT_R = 28;  // Radius of circular cutout

// Swirl disc sizes (1.8mm gap all around from cutout)
BIG_SWIRL_R = BIG_CUTOUT_R - 1.8;    // 36.2mm
SMALL_SWIRL_R = SMALL_CUTOUT_R - 1.8; // 26.2mm

// ═══════════════════════════════════════════════════════════════════════════
// WAVE POSITIONING
// All waves between cliff (X=90) and right edge (X=310)
// Reduced by 10mm in length, moved further right
// ═══════════════════════════════════════════════════════════════════════════
WAVE_ZONE_START = CLIFF_WIDTH + 20;  // Start at 110mm
WAVE_ZONE_END = IW - 5;              // End at 305mm
WAVE_ZONE_WIDTH = WAVE_ZONE_END - WAVE_ZONE_START;  // 195mm

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS - 3 gears positioned so ocean waves rest upon them (Y plane)
// Spanning IW*0.52 to IW*0.91, different sizes, max coverage
// ═══════════════════════════════════════════════════════════════════════════
// Gear positions and sizes calculated for max coverage without overlap
GEAR1_X = IW * 0.55;
GEAR1_R = 12;
GEAR2_X = IW * 0.72;
GEAR2_R = 14;
GEAR3_X = IW * 0.88;
GEAR3_R = 10;

// Gears Y position (near bottom)
GEARS_Y = IH * 0.04;

// Ocean waves Y position (5mm clearance above gears in Y plane)
OCEAN_WAVES_Y_BASE = GEARS_Y + GEAR2_R + 5;  // ~19 + 5 = 24 from bottom

// ═══════════════════════════════════════════════════════════════════════════
// MECHANICAL DRIVE SYSTEM
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
master_drive = t * 360;

// Swirl rotations (45:1 and 40:1 reduction)
swirl_rot_1 = master_drive / 45;
swirl_counter_1 = -master_drive / 55;
swirl_rot_2 = -master_drive / 40;
swirl_counter_2 = master_drive / 50;

// Moon (70:1 reduction)
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

// Sky gears
gear_sky_1 = master_drive / 10;
gear_sky_2 = -master_drive / 12;
gear_sky_3 = master_drive / 15;
gear_sky_4 = -master_drive / 18;

// Bottom gears
gear_bottom = master_drive / 25;

// Belt/chain phase
belt_phase = master_drive / 8;

// Lighthouse beam (200:1)
lighthouse_beam = master_drive / 200;

// Bird movement
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
C_BELT = "#4a3a2a";
C_CHAIN = "#454038";
C_LIGHTHOUSE = "#d4c4a8";
C_BIRD = "#2a2a2a";
C_WIRE = "#3a3a3a";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYERS
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY = 0;
Z_BOTTOM_GEARS = 6;
Z_BIRD_SUPPORTS = 8;     // Bird assembly gears/supports BEHIND foreground
Z_MOON_HALO_BACK = 10;   // Larger halo behind
Z_MOON_HALO_FRONT = 14;  // Smaller halo 4mm in front
Z_MOON = 16;
Z_STARS = 18;
Z_SWIRL_HALO_BACK = 20;  // Larger grey ring behind
Z_SWIRL_HALO_FRONT = 24; // Smaller grey disc 4mm in front
Z_SWIRL_MAIN = 28;       // Blue main disc
Z_WIND = 32;
Z_BELTS = 34;
Z_CLIFFS = 36;
Z_LIGHTHOUSE = 40;
Z_WAVE_1 = 42;
Z_WAVE_2 = 45;
Z_WAVE_3 = 48;
Z_WAVE_CRASH = 50;
Z_CYPRESS = 52;
Z_SKY_GEARS = 54;        // Sky gears in foreground
Z_BIRD_WIRE = 56;        // Bird wire in foreground
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
// MOON ASSEMBLY - Concentric circle halos, larger behind, smaller 4mm front
// ═══════════════════════════════════════════════════════════════════════════
module moon_halo_back(rot) {
    // LARGER halo - BEHIND (at Z_MOON_HALO_BACK)
    rotate([0,0,rot])
    color(C_MOON_HALO_A, 0.5)
    difference() {
        cylinder(r=50, h=3);
        translate([0,0,-1]) cylinder(r=42, h=5);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([46,0,-1]) cylinder(r=3.5, h=5);
    }
}

module moon_halo_front(rot) {
    // SMALLER halo - 4mm IN FRONT (at Z_MOON_HALO_FRONT)
    rotate([0,0,rot])
    color(C_MOON_HALO_B, 0.6)
    difference() {
        cylinder(r=42, h=3);
        translate([0,0,-1]) cylinder(r=34, h=5);
        for(i=[0:5]) rotate([0,0,i*60]) 
            translate([38,0,-1]) cylinder(r=2.8, h=5);
    }
}

module moon_core(rot) {
    // Glow base
    color(C_MOON, 0.2) cylinder(r=32, h=2);
    
    // Core moon
    translate([0,0,2]) color(C_MOON) cylinder(r=20, h=5);
    
    // Rotating rings
    translate([0,0,2]) rotate([0,0,rot])
    color(C_MOON, 0.8) for(r_val=[24, 28, 32]) difference() {
        cylinder(r=r_val+1.5, h=4);
        translate([0,0,-1]) cylinder(r=r_val-1, h=6);
        for(a=[0:3]) rotate([0,0,a*90+15]) translate([0,0,-1]) cube([40, 2.8, 6]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIRL DISC - Concentric circle halos, larger behind, smaller 4mm front
// Main blue disc on top
// ═══════════════════════════════════════════════════════════════════════════
module swirl_halo_back(r, rot) {
    // LARGER grey ring - BEHIND
    rotate([0,0,rot])
    color(C_SWIRL_GREY_DARK, 0.82)
    difference() {
        cylinder(r=r*1.08, h=3);
        translate([0,0,-1]) cylinder(r=r*0.78, h=5);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) 
            translate([r*0.93,0,-1]) cylinder(r=r*0.08, h=5);
    }
}

module swirl_halo_front(r, rot) {
    // SMALLER grey disc - 4mm IN FRONT
    rotate([0,0,rot])
    color(C_SWIRL_GREY, 0.88)
    difference() {
        cylinder(r=r*0.88, h=4);
        translate([0,0,-1]) cylinder(r=r*0.08, h=6);
        // Radial slot texture
        for(i=[0:9]) rotate([0,0,i*36]) 
            translate([r*0.30, -1.2, -1]) cube([r*0.48, 2.4, 6]);
    }
}

module swirl_main(r, rot) {
    // Blue main disc - FRONT
    rotate([0,0,rot]) 
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
}

// ═══════════════════════════════════════════════════════════════════════════
// STAR GEAR WITH CONCENTRIC HALOS
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
    
    // Larger halo behind
    translate([0,0,-4]) rotate([0,0,halo_rot])
    color(C_GEAR_DARK, 0.8) difference() {
        cylinder(r=r*1.55, h=2);
        translate([0,0,-1]) cylinder(r=r*1.05, h=4);
        for(i=[0:5]) rotate([0,0,i*60]) translate([r*1.30,0,-1]) cylinder(r=r*0.13, h=4);
    }
    
    // Smaller halo 4mm in front of larger
    translate([0,0,0]) rotate([0,0,-halo_rot*0.8])
    color(C_GEAR, 0.7) difference() {
        cylinder(r=r*1.32, h=2);
        translate([0,0,-1]) cylinder(r=r*0.92, h=4);
        for(i=[0:7]) rotate([0,0,i*45+22.5]) translate([r*1.12,0,-1]) cylinder(r=r*0.1, h=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH - Touches left edge (X=0), with CIRCULAR cutouts
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_with_circular_cutouts() {
    // Wind path positioned to touch left edge
    // Scale adjusted so leftmost point reaches X=0
    difference() {
        // Base wind path shape - repositioned to touch X=0
        translate([0, IH * 0.50, 0])
        scale([0.135, 0.145, 1])
        color(C_WIND)
        wind_path_shape(1);
        
        // Cut out PERFECT CIRCLES for swirl discs
        // Big cutout
        translate([BIG_CUTOUT_X, BIG_CUTOUT_Y, -1])
        cylinder(r=BIG_CUTOUT_R, h=20);
        
        // Small cutout
        translate([SMALL_CUTOUT_X, SMALL_CUTOUT_Y, -1])
        cylinder(r=SMALL_CUTOUT_R, h=20);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF
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
    
    translate([0, 0, 42])
    color("#333") cylinder(r=9.5, h=2.5);
    
    translate([0, 0, 44.5])
    color("LightYellow", 0.65)
    difference() {
        cylinder(r=7, h=9);
        translate([0, 0, 1.5]) cylinder(r=6, h=10);
    }
    
    translate([0, 0, 50])
    color("Yellow", 0.9)
    sphere(r=3.2);
    
    translate([0, 0, 49])
    rotate([0, 0, beam_rot * 360])
    color("Yellow", 0.42)
    linear_extrude(height=4)
    polygon([[0,0], [22, -1.6], [22, 1.6]]);
    
    translate([0, 0, 53.5])
    color("#7a5535")
    cylinder(r1=8.5, r2=2.2, h=6.5);
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD WIRE - Full width from left edge to right edge (IW*0 to IW*1)
// Supports at edges, gears hidden behind foreground
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

// Wire Y position function - full width
function wire_y(t_val, wire_num) = 
    let(y_base = wire_num == 0 ? IH * 0.52 : IH * 0.52 + 7)
    y_base + 6 * sin(t_val * 360 * 2.5);

module bird_wire_full_width(progress, bob) {
    wire_y_base = IH * 0.52;
    
    // Wire 1 (lower) - FULL WIDTH from 0 to IW
    color(C_WIRE)
    for(i=[0:40]) {
        x1 = IW * (i/40);
        x2 = IW * ((i+1)/40);
        y1 = wire_y(i/40, 0);
        y2 = wire_y((i+1)/40, 0);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.55);
            translate([x2, y2, 0]) sphere(r=0.55);
        }
    }
    
    // Wire 2 (upper, 7mm apart) - FULL WIDTH
    color(C_WIRE)
    for(i=[0:40]) {
        x1 = IW * (i/40);
        x2 = IW * ((i+1)/40);
        y1 = wire_y(i/40, 1);
        y2 = wire_y((i+1)/40, 1);
        hull() {
            translate([x1, y1, 0]) sphere(r=0.55);
            translate([x2, y2, 0]) sphere(r=0.55);
        }
    }
    
    // Loop connectors at edges
    color(C_WIRE) {
        translate([0, wire_y_base + 3.5, 0]) 
        rotate([90, 0, 90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.55);
        translate([IW, wire_y_base + 3.5, 0]) 
        rotate([90, 0, -90]) rotate_extrude(angle=180, $fn=16) translate([3.5, 0, 0]) circle(r=0.55);
    }
    
    // Birds
    bird1_x = IW * progress;
    bird1_y = wire_y(progress, 0);
    translate([bird1_x, bird1_y, 2 + bob]) bird_simple();
    
    bird2_x = IW * ((progress + 0.35) % 1);
    bird2_y = wire_y((progress + 0.35) % 1, 0);
    translate([bird2_x, bird2_y, 2 + bob*0.85]) bird_simple();
    
    bird3_x = IW * (1 - progress);
    bird3_y = wire_y(1 - progress, 1);
    translate([bird3_x, bird3_y, 2 + bob*1.1]) rotate([0, 0, 180]) bird_simple();
}

// Bird wire supports - at edges, BEHIND foreground (Z_BIRD_SUPPORTS)
module bird_wire_supports() {
    color(C_GEAR_DARK) {
        translate([2, IH * 0.52, 0]) cylinder(r=2, h=8);
        translate([IW - 2, IH * 0.52, 0]) cylinder(r=2, h=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS - Moved to touch bottom frame (Y=0)
// ═══════════════════════════════════════════════════════════════════════════
module cypress_at_bottom() {
    // Base of trunk at Y=0
    translate([CLIFF_WIDTH + 15, 0, 0])
    scale([0.85, 0.85, 1])
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF WAVES - Surrounding cliff, wave 3 rotated 70° in Y (falling over)
// All waves reduced by 10mm, moved further right
// ═══════════════════════════════════════════════════════════════════════════
module cliff_waves(drift, surge, crash, tilt) {
    // Wave scale factor (reduced by ~10mm equivalent)
    sf = 0.85;  // Scale factor reduction
    
    // Wave layer 1 - at cliff base
    translate([WAVE_ZONE_START + drift*0.7, 10 + surge*0.8, 0])
    scale([0.30*sf, 0.30*sf, 1])
    color(C_WAVE_DARK)
    cliff_wave_L1(1);
    
    // Wave layer 2 - slightly higher
    translate([WAVE_ZONE_START + 15 + drift*0.55, 18 + surge*0.7, 0])
    scale([0.28*sf, 0.28*sf, 1])
    color(C_WAVE_MED)
    cliff_wave_L2(1);
    
    // Wave layer 3 - ROTATED 70° in Y axis (falling over onto cliff)
    // Foam crest comes up touching cliff face
    translate([WAVE_ZONE_START - 10 + drift*0.4, 35 + crash, 0])
    rotate([0, 70, 0])  // Falling over on right side
    rotate([0, 0, 15 + tilt])
    scale([0.26*sf, 0.26*sf, 1])
    color(C_WAVE_FOAM, 0.95)
    cliff_wave_L3(1);
    
    // Additional crashing spray
    translate([WAVE_ZONE_START - 20 + drift*0.3, 55 + crash*0.85, 0])
    rotate([0, 0, 25 + tilt*0.8])
    scale([0.22*sf, 0.22*sf, 1])
    color(C_WAVE_FOAM, 0.88)
    cliff_wave_L3(1);
    
    // Spray at cliff top
    translate([WAVE_ZONE_START - 28 + drift*0.2, 78 + crash*0.65, 0])
    rotate([0, 0, 38 + tilt*0.6])
    scale([0.18*sf, 0.18*sf, 1])
    color(C_WAVE_FOAM, 0.78)
    cliff_wave_L3(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// OCEAN WAVES - Between cliff and right edge
// Waves 1&2 moved down to rest on gears (Y plane), wave 3 maintains height
// Reduced by 10mm, positioned in wave zone
// ═══════════════════════════════════════════════════════════════════════════
module ocean_waves(drift, surge) {
    sf = 0.85;  // Scale factor (10mm reduction)
    
    // Layer 1 (back) - MOVED DOWN to rest on gears
    translate([WAVE_ZONE_START + 50 + drift*0.6, OCEAN_WAVES_Y_BASE + surge, 0])
    scale([1.10*sf, 1.10*sf, 1])
    color(C_WAVE_DARK)
    ocean_wave_L1(1);
    
    // Layer 2 (mid) - MOVED DOWN to rest on gears
    translate([WAVE_ZONE_START + 85 + drift*0.45, OCEAN_WAVES_Y_BASE + 8 + surge*0.85, 0])
    scale([1.05*sf, 1.05*sf, 1])
    color(C_WAVE_MED)
    ocean_wave_L2(1);
    
    // Layer 3 (front) - MAINTAINS HEIGHT (higher up)
    translate([WAVE_ZONE_START + 115 + drift*0.32, IH*0.18 + surge*0.7, 0])
    scale([1.0*sf, 1.0*sf, 1])
    color(C_WAVE_FOAM)
    ocean_wave_L3(1);
    
    // Far right wave - also maintains height
    translate([WAVE_ZONE_END - 40 + drift*0.22, IH*0.15 + surge*0.5, 0])
    scale([0.90*sf, 0.90*sf, 1])
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
// SKY GEARS (FOREGROUND)
// ═══════════════════════════════════════════════════════════════════════════
module sky_gears_foreground(r1, r2, r3, r4) {
    translate([IW*0.06, IH*0.62, 0]) rotate([0,0,r1]) gear(16, 14, 4);
    translate([IW*0.16, IH*0.55, 0]) rotate([0,0,r2]) gear(13, 11, 4);
    translate([IW*0.04, IH*0.50, 0]) rotate([0,0,r3]) gear(11, 9, 3);
    translate([IW*0.34, IH*0.94, 0]) rotate([0,0,r1*0.85]) gear(14, 12, 4);
    translate([IW*0.46, IH*0.90, 0]) rotate([0,0,r2*0.92]) gear(11, 9, 3);
    translate([IW*0.70, IH*0.84, 0]) rotate([0,0,r3*1.08]) gear(13, 11, 4);
    translate([IW*0.76, IH*0.70, 0]) rotate([0,0,r4]) gear(10, 8, 3);
    translate([IW*0.66, IH*0.74, 0]) rotate([0,0,r1*1.15]) gear(10, 8, 3);
    translate([IW*0.54, IH*0.80, 0]) rotate([0,0,r2*1.05]) gear(8, 6, 3);
    translate([IW*0.24, IH*0.84, 0]) rotate([0,0,r4*0.88]) gear(9, 7, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS - 3 gears, spaced out, ocean waves rest upon them (Y plane)
// ═══════════════════════════════════════════════════════════════════════════
module bottom_gears_three(rot) {
    // Gear 1 - leftmost, medium size
    translate([GEAR1_X, GEARS_Y, 0]) 
    rotate([0,0,rot]) 
    gear(14, GEAR1_R, 4, 2, C_GEAR_DARK);
    
    // Gear 2 - center, largest
    translate([GEAR2_X, GEARS_Y, 0]) 
    rotate([0,0,-rot*0.85]) 
    gear(18, GEAR2_R, 4, 2.5, C_GEAR_DARK);
    
    // Gear 3 - rightmost, smallest
    translate([GEAR3_X, GEARS_Y, 0]) 
    rotate([0,0,rot*1.15]) 
    gear(12, GEAR3_R, 3, 1.8, C_GEAR_DARK);
    
    // Linkage connecting gears
    color(C_GEAR)
    hull() {
        translate([GEAR1_X, GEARS_Y, 0]) cylinder(r=2, h=2);
        translate([GEAR2_X, GEARS_Y, 0]) cylinder(r=2, h=2);
    }
    color(C_GEAR)
    hull() {
        translate([GEAR2_X, GEARS_Y, 0]) cylinder(r=2, h=2);
        translate([GEAR3_X, GEARS_Y, 0]) cylinder(r=1.5, h=2);
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

module belt_connections(phase) {
    belt_segment(IW*0.15, IH*0.88, IW*0.20, IH*0.75, phase);
    belt_segment(IW*0.20, IH*0.75, BIG_CUTOUT_X, BIG_CUTOUT_Y, phase);
    belt_segment(IW*0.55, IH*0.82, IW*0.48, IH*0.70, phase*1.1);
    belt_segment(IW*0.48, IH*0.70, SMALL_CUTOUT_X, SMALL_CUTOUT_Y, phase*1.1);
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
color(C_SKY, 0.72)
translate([FW, FW, Z_SKY])
cube([IW, IH, 2]);

// BOTTOM GEARS (3 gears, under waves)
translate([FW, FW, Z_BOTTOM_GEARS])
bottom_gears_three(gear_bottom);

// BIRD WIRE SUPPORTS (behind foreground)
translate([FW, FW, Z_BIRD_SUPPORTS])
bird_wire_supports();

// MOON HALOS (concentric, larger behind, smaller 4mm front)
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON_HALO_BACK])
moon_halo_back(moon_halo_1);

translate([FW + IW*0.88, FW + IH*0.82, Z_MOON_HALO_FRONT])
moon_halo_front(moon_halo_2);

// MOON CORE
translate([FW + IW*0.88, FW + IH*0.82, Z_MOON])
moon_core(moon_rot);

// STARS
translate([FW, FW, Z_STARS])
all_stars(star_rot, star_halo_rot);

// SWIRL DISC 1 (BIG) - Halos then main disc
translate([FW + BIG_CUTOUT_X, FW + BIG_CUTOUT_Y, Z_SWIRL_HALO_BACK])
swirl_halo_back(BIG_SWIRL_R, swirl_counter_1);

translate([FW + BIG_CUTOUT_X, FW + BIG_CUTOUT_Y, Z_SWIRL_HALO_FRONT])
swirl_halo_front(BIG_SWIRL_R, -swirl_counter_1*0.7);

translate([FW + BIG_CUTOUT_X, FW + BIG_CUTOUT_Y, Z_SWIRL_MAIN])
swirl_main(BIG_SWIRL_R, swirl_rot_1);

// SWIRL DISC 2 (SMALL) - Halos then main disc
translate([FW + SMALL_CUTOUT_X, FW + SMALL_CUTOUT_Y, Z_SWIRL_HALO_BACK])
swirl_halo_back(SMALL_SWIRL_R, swirl_counter_2);

translate([FW + SMALL_CUTOUT_X, FW + SMALL_CUTOUT_Y, Z_SWIRL_HALO_FRONT])
swirl_halo_front(SMALL_SWIRL_R, -swirl_counter_2*0.7);

translate([FW + SMALL_CUTOUT_X, FW + SMALL_CUTOUT_Y, Z_SWIRL_MAIN])
swirl_main(SMALL_SWIRL_R, swirl_rot_2);

// WIND PATH (touching left edge, with circular cutouts)
translate([FW, FW, Z_WIND])
wind_path_with_circular_cutouts();

// BELT CONNECTIONS
translate([FW, FW, Z_BELTS])
belt_connections(belt_phase);

// CLIFF
translate([FW, FW, Z_CLIFFS])
cliff_assembly();

// LIGHTHOUSE
translate([FW + CLIFF_WIDTH * 0.30, FW + CLIFF_HEIGHT * 0.92, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_beam);

// CLIFF WAVES (including wave 3 rotated 70° in Y)
translate([FW, FW, Z_WAVE_1])
cliff_waves(wave_drift, wave_surge, wave_crash, wave_tilt);

// OCEAN WAVES (moved down except wave 3)
translate([FW, FW, Z_WAVE_2])
ocean_waves(wave_drift, wave_surge);

// CYPRESS (touching bottom frame)
translate([FW, FW, Z_CYPRESS])
cypress_at_bottom();

// SKY GEARS (foreground)
translate([FW, FW, Z_SKY_GEARS])
sky_gears_foreground(gear_sky_1, gear_sky_2, gear_sky_3, gear_sky_4);

// BIRD WIRE (full width, foreground)
translate([FW, FW, Z_BIRD_WIRE])
bird_wire_full_width(bird_progress, bird_bob);

// FRAME
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V35 - HIGH-END MECHANICAL ART");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "mm | Inner:", IW, "×", IH, "mm");
echo("");
echo("CHANGES IMPLEMENTED:");
echo("  1. Halos: Concentric circles, larger behind, smaller 4mm front");
echo("  2. Cliff wave L3: Rotated 70° in Y axis (falling over)");
echo("  3. Wind path: Circular cutouts, touches left edge");
echo("  4. Swirl discs: 1.8mm gap from cutout edges");
echo("     Big swirl R:", BIG_SWIRL_R, "mm (cutout R:", BIG_CUTOUT_R, "mm)");
echo("     Small swirl R:", SMALL_SWIRL_R, "mm (cutout R:", SMALL_CUTOUT_R, "mm)");
echo("  5. Waves: Moved right, reduced 10mm, between cliff and edge");
echo("  6. Ocean waves 1&2: Lowered, resting on gears (Y plane)");
echo("     Gears Y:", GEARS_Y, "| Waves Y:", OCEAN_WAVES_Y_BASE, "(5mm clearance)");
echo("  7. Bottom gears: 3 gears (R:", GEAR1_R, ",", GEAR2_R, ",", GEAR3_R, "mm)");
echo("  8. Bird wire: Full width (0 to", IW, "mm)");
echo("  9. Bird supports: Behind foreground (Z=", Z_BIRD_SUPPORTS, ")");
echo("  10. Cypress: Base at Y=0 (touching bottom)");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
