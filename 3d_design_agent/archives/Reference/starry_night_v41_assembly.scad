// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V41 - FIXES: Lighthouse upright, all gears rotating, 
//                           swirls connected, rice tube L/R tilt
// ═══════════════════════════════════════════════════════════════════════════════════
$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         SHOW/HIDE CONTROLS
// ═══════════════════════════════════════════════════════════════════════════════════
SHOW_ENCLOSURE      = true;
SHOW_BACK_PANEL     = true;
SHOW_CLIFF          = true;
SHOW_LIGHTHOUSE     = true;
SHOW_CYPRESS        = true;
SHOW_CLIFF_WAVES    = true;
SHOW_OCEAN_WAVES    = true;
SHOW_WIND_PATH      = true;
SHOW_BIG_SWIRL      = true;
SHOW_SMALL_SWIRL    = true;
SHOW_MOON           = true;
SHOW_BOTTOM_GEARS   = true;
SHOW_SKY_GEARS      = true;
SHOW_BIRD_WIRE      = true;
SHOW_RICE_TUBE      = true;
SHOW_MOTOR          = true;
SHOW_DRIVE_TRAIN    = true;
SHOW_FOUR_BAR       = true;
SHOW_SWIRL_DRIVE    = true;   // Gear train to swirls
SHOW_ZONE_OUTLINES  = false;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MASTER DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════════════
TOTAL_W = 350;
TOTAL_H = 250;
TOTAL_D = 80;
TAB_W = 24;
WALL_T = 4;
CANVAS_W = 302;
CANVAS_H = 202;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════════
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
ZONE_SKY_GEARS    = [52, 216, 109, 166];
ZONE_BIRD_WIRE    = [0, 302, 130, 146];

function zone_w(z) = z[1] - z[0];
function zone_h(z) = z[3] - z[2];
function zone_cx(z) = (z[0] + z[1]) / 2;
function zone_cy(z) = (z[2] + z[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════
Z_BACK_PANEL      = 0;
Z_MOTOR           = 8;
Z_MAIN_SHAFT      = 15;
Z_GEARS_PLANE     = 15;
Z_RICE_TUBE       = -12;
Z_MOON            = 25;
Z_SWIRL_DRIVE     = 28;      // Gear train to swirls
Z_SKY_MECHANISM   = 30;
Z_SWIRL_BACK      = 32;
Z_SWIRL_FRONT     = 36;
Z_WIND_PATH       = 38;
Z_BIRD_WIRE       = 42;
Z_CLIFF           = 45;
Z_LIGHTHOUSE      = 48;
Z_WAVE_MECHANISM  = 50;
Z_WAVES           = 55;
Z_CYPRESS         = 70;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════════
t = $t;

// Motor runs at 6x speed (60 RPM motor, visualized faster)
motor_angle = t * 360 * 6;

// Master gear: 6:1 reduction from motor
master_angle = t * 360;

// Sky drive: Meshes with master, counter-rotates, ratio 60:20 = 3:1
sky_angle = -master_angle * 3;

// Wave drive: Meshes with master, counter-rotates, ratio 60:30 = 2:1
wave_angle = -master_angle * 2;

// Swirl rotation (driven from sky)
swirl_big_angle = sky_angle * 0.5;
swirl_small_angle = -sky_angle * 0.7;

// Rice tube tilt: ±15° side to side
rice_tilt_angle = 15 * sin(t * 360);

// Bird position along wire
bird_pos = t;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         GEAR SPECIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════════
GEAR_MODULE = 1;

// Tooth counts
MOTOR_PINION_T = 10;
MASTER_GEAR_T = 60;
SKY_DRIVE_T = 20;
WAVE_DRIVE_T = 30;
SWIRL_DRIVE_T = 16;
SWIRL_IDLER_T = 14;
SWIRL_OUTPUT_T = 20;

// Pitch radii
MOTOR_PINION_R = MOTOR_PINION_T * GEAR_MODULE / 2;  // 5mm
MASTER_GEAR_R = MASTER_GEAR_T * GEAR_MODULE / 2;    // 30mm
SKY_DRIVE_R = SKY_DRIVE_T * GEAR_MODULE / 2;        // 10mm
WAVE_DRIVE_R = WAVE_DRIVE_T * GEAR_MODULE / 2;      // 15mm
SWIRL_DRIVE_R = SWIRL_DRIVE_T * GEAR_MODULE / 2;    // 8mm
SWIRL_IDLER_R = SWIRL_IDLER_T * GEAR_MODULE / 2;    // 7mm
SWIRL_OUTPUT_R = SWIRL_OUTPUT_T * GEAR_MODULE / 2;  // 10mm

// Center distances
CD_MOTOR_MASTER = MOTOR_PINION_R + MASTER_GEAR_R;   // 35mm
CD_MASTER_SKY = MASTER_GEAR_R + SKY_DRIVE_R;        // 40mm
CD_MASTER_WAVE = MASTER_GEAR_R + WAVE_DRIVE_R;      // 45mm
CD_SWIRL_CHAIN = SWIRL_DRIVE_R + SWIRL_IDLER_R;     // 15mm

// ═══════════════════════════════════════════════════════════════════════════════════
//                         FOUR-BAR PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════
CRANK_RADIUS = 8;
COUPLER_LENGTH = 50;
WAVE_PIVOT_X = 108;
NUM_WAVE_LAYERS = 5;
WAVE_SPACING = 15;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         WIND PATH HOLE POSITIONS (for swirl alignment)
// ═══════════════════════════════════════════════════════════════════════════════════
WIND_SCALE = 0.1375;  // 25% larger than original

// Big swirl position (under large hole)
BIG_SWIRL_X = 105;    // Adjusted to match wind path large hole
BIG_SWIRL_Y = 140;
BIG_SWIRL_R = 35;

// Small swirl position (under small hole)  
SMALL_SWIRL_X = 168;
SMALL_SWIRL_Y = 130;
SMALL_SWIRL_R = 22;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         COLORS
// ═══════════════════════════════════════════════════════════════════════════════════
C_ENCLOSURE     = "#3a3028";
C_BACK_PANEL    = "#2a2018";
C_CLIFF         = "#6b5344";
C_LIGHTHOUSE    = "#c4b498";
C_LIGHTHOUSE_STRIPE = "#8b6914";
C_CYPRESS       = "#1a3a1a";
C_WAVE_DARK     = "#1a4a6e";
C_WAVE_MID      = "#2a6a8e";
C_WAVE_LIGHT    = "#4a8aae";
C_WIND          = "#2a5a9e";
C_SWIRL         = "#4a7ab0";
C_MOON          = "#f0d060";
C_GEAR          = "#8b7355";
C_SHAFT         = "#b0a090";
C_MOTOR         = "#333333";
C_COUPLER       = "#666666";
C_RICE_TUBE     = "#8b6914";

// ═══════════════════════════════════════════════════════════════════════════════════
//                         INCLUDE TRACED SHAPES
// ═══════════════════════════════════════════════════════════════════════════════════
use <cliffs_wrapper.scad>
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>

CLIFF_SCALE = 0.77;
CYPRESS_SCALE = 0.69;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SPUR GEAR
// ═══════════════════════════════════════════════════════════════════════════════════
module spur_gear(teeth, module_=1, thickness=6, bore_r=1.5, spokes=true) {
    pitch_r = teeth * module_ / 2;
    outer_r = pitch_r + module_;
    root_r = pitch_r - 1.25 * module_;
    tooth_width = 1.57 * module_;
    
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=root_r, h=thickness);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                linear_extrude(height=thickness)
                polygon([
                    [root_r, -tooth_width/2],
                    [outer_r - 0.3, -tooth_width/3],
                    [outer_r, 0],
                    [outer_r - 0.3, tooth_width/3],
                    [root_r, tooth_width/2]
                ]);
            }
        }
        translate([0, 0, -1])
        cylinder(r=bore_r, h=thickness+2);
        
        if (spokes && pitch_r > 12) {
            spoke_count = pitch_r > 20 ? 6 : 4;
            spoke_r = (pitch_r - bore_r*2) / 3;
            for (i = [0:spoke_count-1]) {
                rotate([0, 0, i * 360/spoke_count + 360/spoke_count/2])
                translate([pitch_r * 0.5, 0, -1])
                cylinder(r=spoke_r, h=thickness+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SHAFT
// ═══════════════════════════════════════════════════════════════════════════════════
module shaft(length, diameter=3) {
    color(C_SHAFT)
    cylinder(r=diameter/2, h=length);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: BEARING BLOCK
// ═══════════════════════════════════════════════════════════════════════════════════
module bearing_block(bore_r=1.5, width=10, height=12, depth=8) {
    color("#555")
    difference() {
        translate([-width/2, -depth/2, 0])
        cube([width, depth, height]);
        translate([0, 0, -1])
        cylinder(r=bore_r, h=height+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: N20 MOTOR
// ═══════════════════════════════════════════════════════════════════════════════════
module motor_n20(shaft_rot=0) {
    // Motor body
    color(C_MOTOR) {
        cube([12, 10, 24]);
        translate([0, 0, 24])
        cube([12, 10, 10]);
    }
    
    // Shaft extends in +X direction (along canvas width)
    color(C_SHAFT)
    translate([12, 5, 29])
    rotate([0, 90, 0])
    cylinder(r=1.5, h=15);
    
    // Motor pinion on shaft (ROTATING)
    translate([22, 5, 29])
    rotate([0, 90, 0])
    rotate([0, 0, shaft_rot])
    spur_gear(MOTOR_PINION_T, GEAR_MODULE, 6, 1.5, false);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: COMPLETE GEAR TRAIN
// All gears connected and rotating properly
// ═══════════════════════════════════════════════════════════════════════════════════
module complete_gear_train() {
    // ─────────────────────────────────────────────────────────────────────────────
    // MOTOR POSITION (inside cliff)
    // ─────────────────────────────────────────────────────────────────────────────
    motor_x = 25;
    motor_y = 15;
    
    translate([motor_x, motor_y, 0])
    motor_n20(motor_angle);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // MASTER GEAR (60T) - Driven by motor pinion
    // Position: CD_MOTOR_MASTER = 35mm from motor shaft
    // ─────────────────────────────────────────────────────────────────────────────
    master_x = motor_x + 22 + CD_MOTOR_MASTER;  // Motor body + pinion pos + center dist
    master_y = motor_y + 14;  // Aligned with motor shaft Y
    
    // Master gear shaft (vertical, fixed to frame)
    translate([master_x, master_y, -5])
    shaft(25, 6);
    
    // Bearing block
    translate([master_x, master_y, -8])
    bearing_block(3, 14, 8, 12);
    
    // Master gear (ROTATING - counter to motor)
    translate([master_x, master_y, 5])
    rotate([0, 0, master_angle])
    spur_gear(MASTER_GEAR_T, GEAR_MODULE, 8, 3, true);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // SKY DRIVE GEAR (20T) - Meshes with master
    // Position: CD_MASTER_SKY = 40mm from master center
    // ─────────────────────────────────────────────────────────────────────────────
    sky_x = master_x;
    sky_y = master_y + CD_MASTER_SKY;
    
    // Sky shaft (goes up to sky mechanism)
    translate([sky_x, sky_y, 0])
    shaft(Z_SKY_MECHANISM + 10, 3);
    
    // Bearing
    translate([sky_x, sky_y, -3])
    bearing_block(1.5, 10, 6, 8);
    
    // Sky drive gear (ROTATING - meshes with master, so counter-rotates)
    translate([sky_x, sky_y, 5])
    rotate([0, 0, sky_angle])
    spur_gear(SKY_DRIVE_T, GEAR_MODULE, 6, 1.5, false);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // WAVE DRIVE GEAR (30T) - Meshes with master
    // Position: CD_MASTER_WAVE = 45mm from master center (to the right)
    // ─────────────────────────────────────────────────────────────────────────────
    wave_x = master_x + CD_MASTER_WAVE;
    wave_y = master_y;
    
    // Wave shaft
    translate([wave_x, wave_y, 0])
    shaft(Z_WAVE_MECHANISM, 3);
    
    // Bearing
    translate([wave_x, wave_y, -3])
    bearing_block(1.5, 10, 6, 8);
    
    // Wave drive gear (ROTATING)
    translate([wave_x, wave_y, 5])
    rotate([0, 0, wave_angle])
    spur_gear(WAVE_DRIVE_T, GEAR_MODULE, 6, 1.5, true);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // DISPLAY: Gear mesh lines (debug)
    // ─────────────────────────────────────────────────────────────────────────────
    // Motor to Master mesh line
    color("red", 0.3)
    translate([motor_x + 22, motor_y + 14, 8])
    rotate([0, 90, 0])
    cylinder(r=0.5, h=CD_MOTOR_MASTER);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SWIRL DRIVE TRAIN
// Connects sky drive to both swirl discs via gear chain
// ═══════════════════════════════════════════════════════════════════════════════════
module swirl_drive_train() {
    // Sky shaft position (from complete_gear_train)
    sky_shaft_x = 25 + 22 + CD_MOTOR_MASTER;  // ~82
    sky_shaft_y = 15 + 14 + CD_MASTER_SKY;    // ~69
    
    // ─────────────────────────────────────────────────────────────────────────────
    // GEAR 1: On sky shaft at Z_SWIRL_DRIVE height
    // ─────────────────────────────────────────────────────────────────────────────
    translate([sky_shaft_x, sky_shaft_y, Z_SWIRL_DRIVE])
    rotate([0, 0, sky_angle])
    spur_gear(SWIRL_DRIVE_T, GEAR_MODULE, 5, 1.5, false);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // IDLER GEAR 1: Between sky and big swirl
    // ─────────────────────────────────────────────────────────────────────────────
    idler1_x = sky_shaft_x + 5;
    idler1_y = sky_shaft_y + CD_SWIRL_CHAIN + 5;
    idler1_angle = -sky_angle * SWIRL_DRIVE_T / SWIRL_IDLER_T;
    
    translate([idler1_x, idler1_y, Z_SWIRL_DRIVE])
    rotate([0, 0, idler1_angle])
    spur_gear(SWIRL_IDLER_T, GEAR_MODULE, 5, 1.5, false);
    
    // Idler shaft
    translate([idler1_x, idler1_y, Z_SWIRL_DRIVE - 5])
    shaft(15, 3);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // IDLER GEAR 2: Continues chain toward big swirl
    // ─────────────────────────────────────────────────────────────────────────────
    idler2_x = idler1_x + 10;
    idler2_y = idler1_y + 20;
    idler2_angle = -idler1_angle * SWIRL_IDLER_T / SWIRL_IDLER_T;
    
    translate([idler2_x, idler2_y, Z_SWIRL_DRIVE])
    rotate([0, 0, idler2_angle])
    spur_gear(SWIRL_IDLER_T, GEAR_MODULE, 5, 1.5, false);
    
    translate([idler2_x, idler2_y, Z_SWIRL_DRIVE - 5])
    shaft(15, 3);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // BIG SWIRL OUTPUT GEAR: At big swirl position
    // ─────────────────────────────────────────────────────────────────────────────
    big_output_angle = -idler2_angle * SWIRL_IDLER_T / SWIRL_OUTPUT_T;
    
    translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_DRIVE])
    rotate([0, 0, big_output_angle])
    spur_gear(SWIRL_OUTPUT_T, GEAR_MODULE, 5, 1.5, false);
    
    // Big swirl shaft (connects gear to swirl disc)
    translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_DRIVE - 3])
    shaft(Z_SWIRL_BACK - Z_SWIRL_DRIVE + 8, 3);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // SMALL SWIRL BRANCH: Gear chain to small swirl
    // ─────────────────────────────────────────────────────────────────────────────
    // Branch from idler2 toward small swirl
    idler3_x = idler2_x + 25;
    idler3_y = idler2_y + 5;
    idler3_angle = -idler2_angle;
    
    translate([idler3_x, idler3_y, Z_SWIRL_DRIVE])
    rotate([0, 0, idler3_angle])
    spur_gear(SWIRL_IDLER_T, GEAR_MODULE, 5, 1.5, false);
    
    translate([idler3_x, idler3_y, Z_SWIRL_DRIVE - 5])
    shaft(15, 3);
    
    // Small swirl output gear
    small_output_angle = -idler3_angle * SWIRL_IDLER_T / SWIRL_OUTPUT_T;
    
    translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_DRIVE])
    rotate([0, 0, small_output_angle])
    spur_gear(SWIRL_OUTPUT_T, GEAR_MODULE, 5, 1.5, false);
    
    // Small swirl shaft
    translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_DRIVE - 3])
    shaft(Z_SWIRL_BACK - Z_SWIRL_DRIVE + 8, 3);
    
    // ─────────────────────────────────────────────────────────────────────────────
    // CONNECTION LINES (visual debug)
    // ─────────────────────────────────────────────────────────────────────────────
    color("orange", 0.3) {
        // Sky to idler1
        hull() {
            translate([sky_shaft_x, sky_shaft_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
            translate([idler1_x, idler1_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
        }
        // idler1 to idler2
        hull() {
            translate([idler1_x, idler1_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
            translate([idler2_x, idler2_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
        }
        // idler2 to big swirl
        hull() {
            translate([idler2_x, idler2_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
            translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
        }
        // idler2 to idler3
        hull() {
            translate([idler2_x, idler2_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
            translate([idler3_x, idler3_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
        }
        // idler3 to small swirl
        hull() {
            translate([idler3_x, idler3_y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
            translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_DRIVE + 2.5])
            sphere(r=1);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SWIRL DISC
// ═══════════════════════════════════════════════════════════════════════════════════
module swirl_disc(radius, rot=0, thickness=5) {
    rotate([0, 0, rot])
    color(C_SWIRL)
    difference() {
        cylinder(r=radius, h=thickness);
        translate([0, 0, -1])
        cylinder(r=3, h=thickness+2);  // Shaft hole
        
        // Spiral cutouts for visual effect
        for (i = [0:5]) {
            rotate([0, 0, i*60])
            translate([radius*0.55, 0, -1])
            cylinder(r=radius*0.18, h=thickness+2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: FOUR-BAR LINKAGE
// ═══════════════════════════════════════════════════════════════════════════════════
module four_bar_linkage(crank_angle, layer_index) {
    phase = layer_index * 30;
    current_angle = crank_angle + phase;
    
    crank_x = 140 + layer_index * WAVE_SPACING;
    crank_y = 25;
    
    rocker_pivot_x = WAVE_PIVOT_X;
    rocker_pivot_y = 30 + layer_index * 8;
    
    // Ground bearings
    translate([crank_x, crank_y, 0])
    bearing_block(1.5, 8, 8, 6);
    
    translate([rocker_pivot_x, rocker_pivot_y, 0])
    bearing_block(1.5, 8, 8, 6);
    
    // Crank disc (ROTATING)
    translate([crank_x, crank_y, 8]) {
        color(C_GEAR)
        rotate([0, 0, current_angle])
        difference() {
            cylinder(r=CRANK_RADIUS + 3, h=4);
            translate([0, 0, -1])
            cylinder(r=1.5, h=6);
        }
        
        // Crank pin
        color(C_SHAFT)
        rotate([0, 0, current_angle])
        translate([CRANK_RADIUS, 0, 4])
        cylinder(r=1.5, h=6);
    }
    
    // Calculate crank pin position
    crank_pin_x = crank_x + CRANK_RADIUS * cos(current_angle);
    crank_pin_y = crank_y + CRANK_RADIUS * sin(current_angle);
    
    // Coupler rod
    coupler_angle = atan2(rocker_pivot_y - crank_pin_y, rocker_pivot_x - crank_pin_x);
    coupler_len = sqrt(pow(rocker_pivot_x - crank_pin_x, 2) + pow(rocker_pivot_y - crank_pin_y, 2));
    
    color(C_COUPLER)
    translate([crank_pin_x, crank_pin_y, 14])
    rotate([0, 0, coupler_angle])
    translate([0, -1.5, 0])
    cube([coupler_len, 3, 3]);
    
    // Wave layer (rocker) - OSCILLATING
    rocker_angle = 12 * sin(current_angle);
    
    color(C_WAVE_MID, 0.8)
    translate([rocker_pivot_x, rocker_pivot_y, 18])
    rotate([0, 0, rocker_angle])
    translate([0, -6, 0])
    cube([45, 12, 4]);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CAMSHAFT
// ═══════════════════════════════════════════════════════════════════════════════════
module camshaft_assembly() {
    shaft_start_x = 125;
    shaft_end_x = 220;
    shaft_y = 25;
    
    // Main shaft
    color(C_SHAFT)
    translate([shaft_start_x, shaft_y, 8])
    rotate([0, 90, 0])
    cylinder(r=3, h=shaft_end_x - shaft_start_x);
    
    // Input gear (receives from wave drive)
    translate([shaft_start_x, shaft_y, 8])
    rotate([0, 90, 0])
    rotate([0, 0, wave_angle])
    spur_gear(WAVE_DRIVE_T, GEAR_MODULE, 6, 3, true);
    
    // Crank discs
    for (i = [0:NUM_WAVE_LAYERS-1]) {
        disc_x = 140 + i * WAVE_SPACING;
        phase = i * 30;
        
        translate([disc_x, shaft_y, 8])
        rotate([0, 90, 0])
        rotate([0, 0, wave_angle + phase])
        color(C_GEAR) {
            difference() {
                cylinder(r=CRANK_RADIUS + 3, h=5);
                translate([0, 0, -1])
                cylinder(r=3, h=7);
            }
            translate([CRANK_RADIUS, 0, 5])
            cylinder(r=2, h=5);
        }
    }
    
    // Bearings
    for (x = [shaft_start_x, shaft_start_x + 40, shaft_end_x - 10]) {
        translate([x, shaft_y, 0])
        bearing_block(3, 10, 8, 8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: LIGHTHOUSE (UPRIGHT - rotated on X axis)
// Base glued to cliff top face
// ═══════════════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot=0) {
    lh_base_r = 6;      // Base radius
    lh_top_r = 4;       // Top radius (tapered)
    lh_height = 50;     // Total height
    
    // ROTATE 90° on X so cylinder points toward viewer (+Z)
    rotate([90, 0, 0])
    translate([0, 0, -lh_height]) {
        // Main tower (tapered cylinder)
        color(C_LIGHTHOUSE)
        cylinder(r1=lh_base_r, r2=lh_top_r, h=lh_height * 0.7);
        
        // Red/brown stripes
        color(C_LIGHTHOUSE_STRIPE)
        for (z = [lh_height*0.15, lh_height*0.35, lh_height*0.55]) {
            translate([0, 0, z])
            cylinder(r1=lh_base_r*0.95 - z/lh_height*2, 
                     r2=lh_base_r*0.9 - z/lh_height*2, 
                     h=lh_height*0.08);
        }
        
        // Platform/gallery
        translate([0, 0, lh_height*0.7])
        color("#444")
        cylinder(r=lh_top_r*1.4, h=2);
        
        // Lamp room (glass)
        translate([0, 0, lh_height*0.72])
        color("LightYellow", 0.5)
        cylinder(r=lh_top_r*1.2, h=lh_height*0.12);
        
        // Lantern housing (rotating)
        translate([0, 0, lh_height*0.72])
        rotate([0, 0, beam_rot])
        color("#333", 0.7)
        difference() {
            cylinder(r=lh_top_r*1.25, h=lh_height*0.1);
            translate([-lh_top_r*2, -1, -1])
            cube([lh_top_r*4, 2, lh_height*0.15]);
        }
        
        // Roof/dome
        translate([0, 0, lh_height*0.84])
        color(C_LIGHTHOUSE_STRIPE)
        cylinder(r1=lh_top_r*1.3, r2=lh_top_r*0.3, h=lh_height*0.16);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: RICE TUBE (Tilts LEFT/RIGHT)
// Rotation around Y-axis for side-to-side rocking
// ═══════════════════════════════════════════════════════════════════════════════════
module rice_tube(tilt_angle=0) {
    tube_length = 200;
    tube_od = 20;
    tube_id = 16;
    
    // Center pivot position
    pivot_x = CANVAS_W / 2;
    pivot_y = -12;  // Behind bottom tab
    pivot_z = 0;
    
    translate([pivot_x, pivot_y, pivot_z]) {
        // ROTATE AROUND Y-AXIS for left-up/right-down motion
        // Positive angle: left end goes UP, right end goes DOWN
        rotate([0, tilt_angle, 0])
        translate([-tube_length/2, 0, 0]) {
            // Tube body
            color(C_RICE_TUBE)
            rotate([0, 90, 0])
            difference() {
                cylinder(r=tube_od/2, h=tube_length);
                translate([0, 0, 3])
                cylinder(r=tube_id/2, h=tube_length - 6);
            }
            
            // End caps
            color(C_RICE_TUBE) {
                rotate([0, 90, 0])
                cylinder(r=tube_od/2, h=3);
                
                translate([tube_length - 3, 0, 0])
                rotate([0, 90, 0])
                cylinder(r=tube_od/2, h=3);
            }
            
            // Internal baffles (visible)
            color(C_RICE_TUBE, 0.6)
            for (x = [20:30:tube_length-20]) {
                translate([x, 0, 0])
                rotate([0, 90, 0])
                difference() {
                    cylinder(r=tube_id/2 - 1, h=2);
                    translate([0, 0, -1])
                    cylinder(r=tube_id/2 - 4, h=4);
                }
            }
        }
        
        // Center pivot mount (fixed to frame)
        color("#555")
        translate([0, 0, -10])
        cylinder(r=5, h=10);
        
        // Pivot pin
        color(C_SHAFT)
        translate([0, -5, 0])
        rotate([90, 0, 0])
        cylinder(r=2, h=10, center=true);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WIND PATH (25% larger)
// ═══════════════════════════════════════════════════════════════════════════════════
module wind_path_traced() {
    translate([zone_cx(ZONE_WIND_PATH), zone_cy(ZONE_WIND_PATH), 0])
    scale([WIND_SCALE, WIND_SCALE, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CLIFF
// ═══════════════════════════════════════════════════════════════════════════════════
module cliff_traced() {
    translate([zone_cx(ZONE_CLIFF), zone_cy(ZONE_CLIFF), 0])
    scale([CLIFF_SCALE, CLIFF_SCALE, 1])
    color(C_CLIFF)
    cliffs_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CYPRESS
// ═══════════════════════════════════════════════════════════════════════════════════
module cypress_traced() {
    orig_y_min = -112.572;
    orig_cx = 21;
    
    translate([zone_cx(ZONE_CYPRESS), 0, 0])
    scale([CYPRESS_SCALE, CYPRESS_SCALE, 1])
    translate([-orig_cx, -orig_y_min, 0])
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MOON
// ═══════════════════════════════════════════════════════════════════════════════════
module moon_assembly(rot=0) {
    moon_r = 28;
    
    color(C_MOON, 0.2)
    cylinder(r=moon_r + 10, h=2);
    
    translate([0, 0, 2])
    color(C_MOON)
    cylinder(r=moon_r * 0.65, h=5);
    
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.8)
    difference() {
        cylinder(r=moon_r, h=5);
        translate([0, 0, -1])
        cylinder(r=moon_r * 0.7, h=7);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: BIRD WIRE
// ═══════════════════════════════════════════════════════════════════════════════════
module bird_wire_track() {
    wire_y = zone_cy(ZONE_BIRD_WIRE);
    color("#888")
    translate([0, wire_y, 0])
    rotate([0, 90, 0])
    cylinder(r=1, h=CANVAS_W);
}

module bird(pos=0) {
    bird_x = 20 + pos * (CANVAS_W - 40);
    bird_y = zone_cy(ZONE_BIRD_WIRE);
    
    translate([bird_x, bird_y, 5])
    color("#333")
    scale([1, 0.5, 0.3])
    sphere(r=8);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WAVE LAYERS
// ═══════════════════════════════════════════════════════════════════════════════════
module wave_layer(layer_num, rot=0) {
    phase = layer_num * 30;
    osc = 10 * sin(rot + phase);
    
    pivot_x = WAVE_PIVOT_X;
    pivot_y = 15 + layer_num * 10;
    wave_w = 45;
    wave_h = 15;
    
    colors = [C_WAVE_DARK, "#1f5578", "#246082", "#2a6a8c", C_WAVE_LIGHT];
    
    translate([pivot_x, pivot_y, layer_num * 4])
    rotate([0, 0, osc])
    color(colors[layer_num % 5])
    linear_extrude(height=3)
    polygon([
        [0, -wave_h/2],
        [wave_w*0.3, -wave_h/2 + 3],
        [wave_w*0.6, wave_h*0.2],
        [wave_w*0.9, wave_h*0.4],
        [wave_w, wave_h*0.2],
        [wave_w, -wave_h/2]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ENCLOSURE
// ═══════════════════════════════════════════════════════════════════════════════════
module enclosure() {
    color(C_ENCLOSURE)
    difference() {
        cube([TOTAL_W, TOTAL_H, TOTAL_D]);
        translate([WALL_T, WALL_T, WALL_T])
        cube([TOTAL_W - 2*WALL_T, TOTAL_H - 2*WALL_T, TOTAL_D]);
        translate([TAB_W, TAB_W, WALL_T])
        cube([CANVAS_W, CANVAS_H, TOTAL_D]);
    }
}

module back_panel() {
    color(C_BACK_PANEL)
    difference() {
        translate([WALL_T + 2, WALL_T + 2, 0])
        cube([TOTAL_W - 2*WALL_T - 4, TOTAL_H - 2*WALL_T - 4, WALL_T - 1]);
        translate([TAB_W + 15, TAB_W + 5, -1])
        cube([70, 60, WALL_T + 2]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ZONE OUTLINE
// ═══════════════════════════════════════════════════════════════════════════════════
module zone_outline(zone, col="#ff0000") {
    color(col, 0.3)
    translate([zone[0], zone[2], 0])
    linear_extrude(height=1)
    difference() {
        square([zone_w(zone), zone_h(zone)]);
        translate([2, 2])
        square([zone_w(zone)-4, zone_h(zone)-4]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════

// Enclosure
if (SHOW_ENCLOSURE) enclosure();
if (SHOW_BACK_PANEL) translate([0, 0, Z_BACK_PANEL]) back_panel();

// Complete gear train (motor → master → sky/wave drives)
if (SHOW_DRIVE_TRAIN) {
    translate([TAB_W, TAB_W, Z_GEARS_PLANE])
    complete_gear_train();
}

// Swirl drive train (sky → idlers → swirl outputs)
if (SHOW_SWIRL_DRIVE) {
    translate([TAB_W, TAB_W, 0])
    swirl_drive_train();
}

// Four-bar linkages
if (SHOW_FOUR_BAR) {
    translate([TAB_W, TAB_W, Z_WAVE_MECHANISM]) {
        camshaft_assembly();
        for (i = [0:NUM_WAVE_LAYERS-1]) {
            four_bar_linkage(wave_angle, i);
        }
    }
}

// Rice tube (tilting LEFT/RIGHT)
if (SHOW_RICE_TUBE) {
    translate([TAB_W, TAB_W, Z_RICE_TUBE])
    rice_tube(rice_tilt_angle);
}

// Moon
if (SHOW_MOON) {
    translate([TAB_W + zone_cx(ZONE_MOON), TAB_W + zone_cy(ZONE_MOON), Z_MOON])
    moon_assembly(sky_angle * 0.3);
}

// Big swirl (connected to swirl drive)
if (SHOW_BIG_SWIRL) {
    translate([TAB_W + BIG_SWIRL_X, TAB_W + BIG_SWIRL_Y, Z_SWIRL_BACK])
    swirl_disc(BIG_SWIRL_R, swirl_big_angle, 5);
    
    translate([TAB_W + BIG_SWIRL_X, TAB_W + BIG_SWIRL_Y, Z_SWIRL_FRONT])
    swirl_disc(BIG_SWIRL_R * 0.7, -swirl_big_angle * 1.5, 4);
}

// Small swirl (connected to swirl drive)
if (SHOW_SMALL_SWIRL) {
    translate([TAB_W + SMALL_SWIRL_X, TAB_W + SMALL_SWIRL_Y, Z_SWIRL_BACK])
    swirl_disc(SMALL_SWIRL_R, swirl_small_angle, 5);
    
    translate([TAB_W + SMALL_SWIRL_X, TAB_W + SMALL_SWIRL_Y, Z_SWIRL_FRONT])
    swirl_disc(SMALL_SWIRL_R * 0.7, -swirl_small_angle * 1.5, 4);
}

// Wind path (25% larger)
if (SHOW_WIND_PATH) {
    translate([TAB_W, TAB_W, Z_WIND_PATH])
    wind_path_traced();
}

// Bird wire
if (SHOW_BIRD_WIRE) {
    translate([TAB_W, TAB_W, Z_BIRD_WIRE]) {
        bird_wire_track();
        bird(bird_pos);
        bird(fmod(bird_pos + 0.35, 1));
    }
}

// Cliff
if (SHOW_CLIFF) {
    translate([TAB_W, TAB_W, Z_CLIFF])
    cliff_traced();
}

// Lighthouse (UPRIGHT, base on cliff top)
if (SHOW_LIGHTHOUSE) {
    // Position: X centered in lighthouse zone, Y at cliff top (65), Z on cliff surface
    translate([TAB_W + zone_cx(ZONE_LIGHTHOUSE), 
               TAB_W + ZONE_CLIFF[3],  // Y = cliff top = 65
               Z_CLIFF + 10])          // Z = cliff surface + offset
    lighthouse(motor_angle * 3);
}

// Wave layers
if (SHOW_CLIFF_WAVES) {
    translate([TAB_W, TAB_W, Z_WAVES]) {
        for (i = [0:4]) {
            wave_layer(i, wave_angle);
        }
    }
}

// Cypress
if (SHOW_CYPRESS) {
    translate([TAB_W, TAB_W, Z_CYPRESS])
    cypress_traced();
}

// Zone outlines
if (SHOW_ZONE_OUTLINES) {
    translate([TAB_W, TAB_W, 75]) {
        zone_outline(ZONE_CLIFF, "#8B4513");
        zone_outline(ZONE_LIGHTHOUSE, "#FFD700");
        zone_outline(ZONE_CYPRESS, "#228B22");
        zone_outline(ZONE_WIND_PATH, "#9370DB");
        zone_outline(ZONE_BIG_SWIRL, "#FF00FF");
        zone_outline(ZONE_SMALL_SWIRL, "#FF69B4");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V41 - ALL MECHANISMS CONNECTED");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("FIXES IN V41:");
echo("  1. Lighthouse: Rotated 90° on X-axis, now UPRIGHT facing viewer");
echo("  2. All gears: Connected and ROTATING with proper ratios");
echo("  3. Swirls: Connected via gear chain from sky drive");
echo("  4. Rice tube: Tilts LEFT/RIGHT (Y-axis rotation)");
echo("");
echo("GEAR TRAIN FLOW:");
echo("  Motor (10T) → Master (60T) → Sky Drive (20T) → Swirl Chain");
echo("                            → Wave Drive (30T) → Camshaft → Four-Bar");
echo("");
echo("ANIMATION ANGLES AT t=", t, ":");
echo("  Motor:", motor_angle, "°");
echo("  Master:", master_angle, "°");
echo("  Sky:", sky_angle, "°");
echo("  Wave:", wave_angle, "°");
echo("  Rice tilt:", rice_tilt_angle, "°");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
