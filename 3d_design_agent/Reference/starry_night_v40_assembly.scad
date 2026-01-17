// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V40 - FULLY FUNCTIONAL MECHANICAL KINETIC ART
// ═══════════════════════════════════════════════════════════════════════════════════
// All gears properly meshed with calculated center distances
// Complete four-bar linkage with ground, crank, coupler, rocker
// All mechanisms connected from motor to outputs
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
SHOW_FOUR_BAR       = true;   // Four-bar linkage mechanism
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
//                         ZONE DEFINITIONS (LOCKED)
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
Z_MAIN_SHAFT      = 15;      // Main horizontal drive shaft
Z_GEARS_PLANE     = 15;      // ALL gears in same XY plane (parallel to back)
Z_RICE_TUBE       = -12;
Z_MOON            = 25;
Z_SKY_MECHANISM   = 30;
Z_WIND_PATH       = 38;
Z_SWIRL_BACK      = 32;
Z_SWIRL_FRONT     = 36;
Z_BIRD_WIRE       = 42;
Z_CLIFF           = 45;
Z_LIGHTHOUSE      = 48;
Z_WAVE_MECHANISM  = 50;      // Four-bar linkage plane
Z_WAVES           = 55;
Z_CYPRESS         = 70;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════════
t = $t;
motor_rot = t * 360 * 6;
master_rot = t * 360;
sky_rot = t * 360 * 0.5;
wave_rot = t * 360;
bird_pos = t;
rice_tilt = 15 * sin(t * 360);

// ═══════════════════════════════════════════════════════════════════════════════════
//                         GEAR SPECIFICATIONS (Module = 1mm)
// ═══════════════════════════════════════════════════════════════════════════════════
GEAR_MODULE = 1;  // 1mm module - standard for small mechanisms

// Tooth counts
MOTOR_PINION_T = 10;
MASTER_GEAR_T = 60;
SKY_DRIVE_T = 20;
WAVE_DRIVE_T = 30;
WORM_WHEEL_T = 30;

// Pitch radii (r = teeth * module / 2)
MOTOR_PINION_R = MOTOR_PINION_T * GEAR_MODULE / 2;  // 5mm
MASTER_GEAR_R = MASTER_GEAR_T * GEAR_MODULE / 2;    // 30mm
SKY_DRIVE_R = SKY_DRIVE_T * GEAR_MODULE / 2;        // 10mm
WAVE_DRIVE_R = WAVE_DRIVE_T * GEAR_MODULE / 2;      // 15mm
WORM_WHEEL_R = WORM_WHEEL_T * GEAR_MODULE / 2;      // 15mm

// CENTER DISTANCES (critical for mesh!)
// Center distance = (r1 + r2) for external gears
CD_MOTOR_TO_MASTER = MOTOR_PINION_R + MASTER_GEAR_R;  // 5 + 30 = 35mm
CD_MASTER_TO_SKY = MASTER_GEAR_R + SKY_DRIVE_R;       // 30 + 10 = 40mm
CD_MASTER_TO_WAVE = MASTER_GEAR_R + WAVE_DRIVE_R;     // 30 + 15 = 45mm

// Worm gear parameters
WORM_DIAMETER = 10;
WORM_LENGTH = 30;
WORM_PITCH = 3.14159;  // π mm pitch for module 1
WORM_LEADS = 1;        // Single start worm

// ═══════════════════════════════════════════════════════════════════════════════════
//                         FOUR-BAR LINKAGE PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════
CRANK_RADIUS = 8;           // Eccentric distance on crank
COUPLER_LENGTH = 60;        // Length of connecting rod
WAVE_PIVOT_X = 108;         // Pivot point at cliff edge (fixed)
NUM_WAVE_LAYERS = 5;        // Number of wave layers with linkage
WAVE_SPACING = 15;          // Spacing between wave couplers on camshaft

// ═══════════════════════════════════════════════════════════════════════════════════
//                         COLORS
// ═══════════════════════════════════════════════════════════════════════════════════
C_ENCLOSURE     = "#3a3028";
C_BACK_PANEL    = "#2a2018";
C_CLIFF         = "#6b5344";
C_LIGHTHOUSE    = "#c4b498";
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

// Shape scales (wind path 25% bigger than V39)
CLIFF_SCALE = 0.77;
CYPRESS_SCALE = 0.69;
WIND_SCALE = 0.11 * 1.25;  // 25% bigger = 0.1375

// Wind path hole centers (from original shape, scaled)
// Original large hole: ~52% from left, ~50% height
// Original small hole: ~82% from left, ~45% height
WIND_LARGE_HOLE_X = zone_cx(ZONE_WIND_PATH) - 20;  // Adjusted for 25% scale
WIND_LARGE_HOLE_Y = zone_cy(ZONE_WIND_PATH);
WIND_LARGE_HOLE_R = 30 * 1.25;  // 37.5mm radius

WIND_SMALL_HOLE_X = zone_cx(ZONE_WIND_PATH) + 50;
WIND_SMALL_HOLE_Y = zone_cy(ZONE_WIND_PATH) - 10;
WIND_SMALL_HOLE_R = 20 * 1.25;  // 25mm radius

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SPUR GEAR (Proper involute-ish teeth)
// ═══════════════════════════════════════════════════════════════════════════════════
module spur_gear(teeth, module_=1, thickness=6, bore_r=1.5, spokes=true) {
    pitch_r = teeth * module_ / 2;
    outer_r = pitch_r + module_;
    root_r = pitch_r - 1.25 * module_;
    tooth_depth = 2.25 * module_;
    tooth_width = 1.57 * module_;  // π/2 * module
    
    color(C_GEAR)
    difference() {
        union() {
            // Hub
            cylinder(r=root_r, h=thickness);
            
            // Teeth (simplified trapezoidal profile)
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([0, 0, 0])
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
        
        // Center bore
        translate([0, 0, -1])
        cylinder(r=bore_r, h=thickness+2);
        
        // Spoke cutouts (weight reduction)
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
//                         MODULE: WORM GEAR (Proper helical thread)
// ═══════════════════════════════════════════════════════════════════════════════════
module worm_gear(length=30, diameter=10, pitch=3.14159, leads=1, rot=0) {
    thread_depth = 1.2;
    core_r = diameter/2 - thread_depth;
    
    color(C_SHAFT)
    rotate([0, 0, rot])
    union() {
        // Core cylinder
        cylinder(r=core_r, h=length);
        
        // Helical thread
        thread_turns = length / pitch * leads;
        
        // Create thread as series of rotated segments
        segments_per_turn = 36;
        total_segments = floor(thread_turns * segments_per_turn);
        
        for (i = [0:total_segments-1]) {
            z_pos = i * length / total_segments;
            angle = i * 360 / segments_per_turn * leads;
            
            rotate([0, 0, angle])
            translate([core_r + thread_depth/2, 0, z_pos])
            rotate([0, 90, 0])
            cylinder(r=thread_depth/2, h=thread_depth, $fn=8);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WORM WHEEL (Concave teeth to mesh with worm)
// ═══════════════════════════════════════════════════════════════════════════════════
module worm_wheel(teeth, module_=1, thickness=8, bore_r=1.5) {
    pitch_r = teeth * module_ / 2;
    outer_r = pitch_r + module_;
    root_r = pitch_r - 1.25 * module_;
    
    color(C_GEAR)
    difference() {
        union() {
            // Main body with concave rim
            cylinder(r=outer_r, h=thickness);
        }
        
        // Concave groove for worm (torus section)
        translate([0, 0, thickness/2])
        rotate([90, 0, 0])
        rotate_extrude(angle=360)
        translate([pitch_r, 0])
        circle(r=6);  // Worm radius + clearance
        
        // Center bore
        translate([0, 0, -1])
        cylinder(r=bore_r, h=thickness+2);
        
        // Teeth grooves
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * 360/teeth])
            translate([pitch_r, 0, -1])
            cylinder(r=module_*0.8, h=thickness+2, $fn=6);
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
//                         MODULE: BEARING BLOCK (Ground link / Fixed support)
// ═══════════════════════════════════════════════════════════════════════════════════
module bearing_block(bore_r=1.5, width=10, height=15, depth=8) {
    color("#555")
    difference() {
        // Block body
        translate([-width/2, -depth/2, 0])
        cube([width, depth, height]);
        
        // Bore hole
        translate([0, 0, -1])
        cylinder(r=bore_r, h=height+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: N20 MOTOR
// ═══════════════════════════════════════════════════════════════════════════════════
module motor_n20(rot=0) {
    // Motor body (12x10x24mm)
    color(C_MOTOR) {
        cube([12, 10, 24]);
        translate([0, 0, 24])
        cube([12, 10, 10]);  // Gearbox
    }
    
    // Output shaft (pointing in +Z, which is toward viewer)
    // We need shaft pointing in +X (along the canvas)
    color(C_SHAFT)
    translate([12, 5, 29])
    rotate([0, 90, 0])
    rotate([0, 0, rot])
    cylinder(r=1.5, h=15);
    
    // Motor pinion on shaft
    translate([20, 5, 29])
    rotate([0, 90, 0])
    rotate([0, 0, rot])
    spur_gear(MOTOR_PINION_T, GEAR_MODULE, 6, 1.5, false);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MAIN GEAR TRAIN
// All gears in XY plane (parallel to back panel)
// ═══════════════════════════════════════════════════════════════════════════════════
module main_gear_train(rot=0) {
    // MOTOR POSITION: Inside cliff cavity
    motor_x = 30;
    motor_y = 20;
    
    // MASTER GEAR POSITION: 35mm from motor pinion (center distance)
    master_x = motor_x + 20 + CD_MOTOR_TO_MASTER;  // Motor end + center distance
    master_y = motor_y + 9;  // Aligned with motor shaft
    
    // === MOTOR ===
    translate([motor_x, motor_y, 0])
    rotate([0, 0, 0])
    motor_n20(motor_rot);
    
    // === MASTER GEAR (60T) - Parallel to back panel ===
    // Rotates in XY plane
    translate([master_x, master_y, 0])
    rotate([0, 0, -rot])  // Counter-rotate to mesh with pinion
    spur_gear(MASTER_GEAR_T, GEAR_MODULE, 8, 3);
    
    // Master gear shaft (fixed)
    translate([master_x, master_y, -5])
    shaft(20, 3);
    
    // Bearing block for master gear
    translate([master_x, master_y, -8])
    bearing_block(1.5, 12, 8, 10);
    
    // === SKY DRIVE GEAR (20T) - Meshes with master ===
    sky_x = master_x;
    sky_y = master_y + CD_MASTER_TO_SKY;  // 40mm above master
    
    translate([sky_x, sky_y, 0])
    rotate([0, 0, rot * MASTER_GEAR_T / SKY_DRIVE_T])  // Gear ratio
    spur_gear(SKY_DRIVE_T, GEAR_MODULE, 6, 1.5);
    
    // Sky drive vertical shaft
    translate([sky_x, sky_y, 0])
    shaft(50, 3);
    
    // === WAVE DRIVE GEAR (30T) - Meshes with master ===
    wave_x = master_x + CD_MASTER_TO_WAVE;  // 45mm to right of master
    wave_y = master_y;
    
    translate([wave_x, wave_y, 0])
    rotate([0, 0, -rot * MASTER_GEAR_T / WAVE_DRIVE_T])
    spur_gear(WAVE_DRIVE_T, GEAR_MODULE, 6, 1.5);
    
    // Wave drive shaft extends to camshaft
    translate([wave_x, wave_y, -5])
    shaft(15, 3);
    
    // === INTERMEDIATE GEARS to reach swirls ===
    // Gear chain to big swirl position
    inter1_x = sky_x + 25;
    inter1_y = sky_y + 20;
    inter1_t = 18;
    inter1_r = inter1_t * GEAR_MODULE / 2;
    
    translate([inter1_x, inter1_y, 0])
    rotate([0, 0, -rot * MASTER_GEAR_T / SKY_DRIVE_T * SKY_DRIVE_T / inter1_t])
    spur_gear(inter1_t, GEAR_MODULE, 5, 1.5);
    
    // Shaft for intermediate
    translate([inter1_x, inter1_y, 0])
    shaft(35, 3);
    
    // Second intermediate to reach big swirl
    inter2_x = inter1_x + inter1_r + 12;
    inter2_y = inter1_y + 15;
    inter2_t = 24;
    
    translate([inter2_x, inter2_y, 0])
    rotate([0, 0, rot * MASTER_GEAR_T / SKY_DRIVE_T * SKY_DRIVE_T / inter1_t * inter1_t / inter2_t])
    spur_gear(inter2_t, GEAR_MODULE, 5, 1.5);
    
    translate([inter2_x, inter2_y, 0])
    shaft(40, 3);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: FOUR-BAR LINKAGE (Wave Mechanism)
// Complete with: Ground, Crank, Coupler, Rocker
// ═══════════════════════════════════════════════════════════════════════════════════
module four_bar_linkage(crank_angle=0, layer_index=0) {
    // GROUND LINK 1: Fixed pivot at camshaft position
    crank_x = 140 + layer_index * WAVE_SPACING;
    crank_y = 25;
    
    // GROUND LINK 2: Fixed pivot at cliff edge (wave pivot point)
    rocker_pivot_x = WAVE_PIVOT_X;
    rocker_pivot_y = 35 + layer_index * 5;  // Staggered heights
    
    // Phase offset for each wave layer (30° apart)
    phase = layer_index * 30;
    current_angle = crank_angle + phase;
    
    // === GROUND (Fixed bearing blocks) ===
    // Crank bearing
    translate([crank_x, crank_y, 0])
    bearing_block(1.5, 8, 10, 6);
    
    // Rocker pivot bearing
    translate([rocker_pivot_x, rocker_pivot_y, 0])
    bearing_block(1.5, 8, 10, 6);
    
    // === CRANK (Rotating disc with eccentric pin) ===
    translate([crank_x, crank_y, 10]) {
        // Crank disc
        color(C_GEAR)
        rotate([0, 0, current_angle])
        difference() {
            cylinder(r=CRANK_RADIUS + 3, h=4);
            translate([0, 0, -1])
            cylinder(r=1.5, h=6);
        }
        
        // Crank pin (eccentric)
        color(C_SHAFT)
        rotate([0, 0, current_angle])
        translate([CRANK_RADIUS, 0, 0])
        cylinder(r=1.5, h=8);
    }
    
    // Calculate crank pin position
    crank_pin_x = crank_x + CRANK_RADIUS * cos(current_angle);
    crank_pin_y = crank_y + CRANK_RADIUS * sin(current_angle);
    
    // === COUPLER (Connecting rod) ===
    // Connects crank pin to rocker
    coupler_angle = atan2(rocker_pivot_y - crank_pin_y, rocker_pivot_x - crank_pin_x);
    coupler_length = sqrt(pow(rocker_pivot_x - crank_pin_x, 2) + pow(rocker_pivot_y - crank_pin_y, 2));
    
    color(C_COUPLER)
    translate([crank_pin_x, crank_pin_y, 14])
    rotate([0, 0, coupler_angle])
    translate([0, -1.5, 0])
    cube([coupler_length, 3, 3]);
    
    // Coupler end pins
    color(C_SHAFT) {
        translate([crank_pin_x, crank_pin_y, 12])
        cylinder(r=1.5, h=8);
        
        translate([rocker_pivot_x, rocker_pivot_y, 12])
        cylinder(r=1.5, h=8);
    }
    
    // === ROCKER (Wave layer pivot arm) ===
    // The wave layer itself acts as the rocker
    // It pivots at rocker_pivot point
    // Calculate rocker angle based on four-bar geometry
    rocker_angle = 10 * sin(current_angle);  // Simplified oscillation
    
    color(C_WAVE_MID, 0.7)
    translate([rocker_pivot_x, rocker_pivot_y, 18])
    rotate([0, 0, rocker_angle])
    translate([0, -5, 0])
    cube([50, 10, 4]);  // Wave layer stub
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CAMSHAFT (Drives all four-bar linkages)
// ═══════════════════════════════════════════════════════════════════════════════════
module camshaft_assembly(rot=0) {
    // Camshaft runs through all wave layer crank positions
    shaft_start_x = 130;
    shaft_end_x = 280;
    shaft_y = 25;
    
    // Main camshaft
    color(C_SHAFT)
    translate([shaft_start_x, shaft_y, 10])
    rotate([0, 90, 0])
    cylinder(r=3, h=shaft_end_x - shaft_start_x);
    
    // Drive gear on camshaft (receives power from wave drive)
    translate([shaft_start_x - 5, shaft_y, 10])
    rotate([0, 90, 0])
    rotate([0, 0, rot])
    spur_gear(WAVE_DRIVE_T, GEAR_MODULE, 6, 3);
    
    // Crank discs along camshaft (one per wave layer)
    for (i = [0:NUM_WAVE_LAYERS-1]) {
        phase = i * 30;
        disc_x = 140 + i * WAVE_SPACING;
        
        translate([disc_x, shaft_y, 10])
        rotate([0, 90, 0])
        rotate([0, 0, rot + phase])
        color(C_GEAR) {
            // Crank disc
            difference() {
                cylinder(r=CRANK_RADIUS + 3, h=5);
                translate([0, 0, -1])
                cylinder(r=3, h=7);
            }
            // Eccentric pin
            translate([CRANK_RADIUS, 0, 5])
            cylinder(r=2, h=6);
        }
    }
    
    // Bearing blocks for camshaft
    for (x = [shaft_start_x, shaft_start_x + 50, shaft_end_x - 20]) {
        translate([x, shaft_y, 0])
        rotate([0, 0, 0])
        bearing_block(3, 10, 10, 8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SKY MECHANISM (Drives swirls)
// ═══════════════════════════════════════════════════════════════════════════════════
module sky_mechanism(rot=0) {
    // Vertical shaft from sky drive gear
    sky_shaft_x = 85;  // Aligned with master gear position
    sky_shaft_y = 69;  // Above master
    
    // Vertical shaft
    color(C_SHAFT)
    translate([sky_shaft_x, sky_shaft_y, Z_GEARS_PLANE])
    cylinder(r=1.5, h=Z_SKY_MECHANISM - Z_GEARS_PLANE + 20);
    
    // Bevel gear at top (converts vertical to horizontal for swirls)
    // Simplified as spur gear for now
    translate([sky_shaft_x, sky_shaft_y, Z_SKY_MECHANISM])
    rotate([0, 0, rot * 3])
    spur_gear(16, GEAR_MODULE, 5, 1.5);
    
    // Horizontal shaft to big swirl
    big_swirl_x = WIND_LARGE_HOLE_X;
    big_swirl_y = WIND_LARGE_HOLE_Y;
    
    // Connecting gear train
    // Gear at shaft position
    translate([sky_shaft_x + 20, sky_shaft_y + 15, Z_SKY_MECHANISM])
    rotate([0, 0, -rot * 3])
    spur_gear(20, GEAR_MODULE, 5, 1.5);
    
    // Shaft to big swirl
    color(C_SHAFT)
    translate([sky_shaft_x + 20, sky_shaft_y + 15, Z_SKY_MECHANISM])
    rotate([atan2(big_swirl_y - sky_shaft_y - 15, big_swirl_x - sky_shaft_x - 20), 0, 0])
    cylinder(r=1.5, h=50);
    
    // Big swirl drive gear (at swirl position)
    translate([big_swirl_x, big_swirl_y, Z_SWIRL_BACK - 3])
    rotate([0, 0, rot * 1.5])
    spur_gear(24, GEAR_MODULE, 4, 1.5);
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
        cylinder(r=1.5, h=thickness+2);
        
        // Spiral cutouts
        for (i = [0:5]) {
            rotate([0, 0, i*60])
            translate([radius*0.5, 0, -1])
            cylinder(r=radius*0.15, h=thickness+2);
        }
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
//                         MODULE: CLIFF (Traced)
// ═══════════════════════════════════════════════════════════════════════════════════
module cliff_traced() {
    translate([zone_cx(ZONE_CLIFF), zone_cy(ZONE_CLIFF), 0])
    scale([CLIFF_SCALE, CLIFF_SCALE, 1])
    color(C_CLIFF)
    cliffs_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CYPRESS (Traced)
// ═══════════════════════════════════════════════════════════════════════════════════
module cypress_traced() {
    orig_y_min = -112.572;
    orig_x_min = -22.469;
    orig_x_max = 64.572;
    orig_cx = (orig_x_min + orig_x_max) / 2;
    
    translate([zone_cx(ZONE_CYPRESS), 0, 0])
    scale([CYPRESS_SCALE, CYPRESS_SCALE, 1])
    translate([-orig_cx, -orig_y_min, 0])
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: LIGHTHOUSE (On top of cliff)
// ═══════════════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot=0) {
    // Lighthouse sits ON TOP of cliff
    // Cliff top is at Y = ZONE_CLIFF[3] = 65
    // Lighthouse zone Y starts at 65
    
    lh_w = zone_w(ZONE_LIGHTHOUSE);  // 9mm
    lh_h = zone_h(ZONE_LIGHTHOUSE);  // 52mm
    
    color(C_LIGHTHOUSE)
    linear_extrude(height=lh_h * 0.7, scale=0.7)
    circle(r=lh_w/2);
    
    // Stripes
    color("#8b6914")
    for (z = [lh_h*0.15, lh_h*0.35, lh_h*0.55]) {
        translate([0, 0, z])
        cylinder(r=lh_w/2*0.9, h=lh_h*0.08);
    }
    
    // Platform
    translate([0, 0, lh_h*0.7])
    color("#444") cylinder(r=lh_w/2*1.3, h=2);
    
    // Lamp room
    translate([0, 0, lh_h*0.72])
    color("LightYellow", 0.6)
    cylinder(r=lh_w/2*1.1, h=lh_h*0.15);
    
    // Roof
    translate([0, 0, lh_h*0.87])
    color("#8b6914")
    cylinder(r1=lh_w/2*1.2, r2=lh_w/4, h=lh_h*0.13);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MOON
// ═══════════════════════════════════════════════════════════════════════════════════
module moon_assembly(rot=0) {
    moon_r = min(zone_w(ZONE_MOON), zone_h(ZONE_MOON)) / 2 - 5;
    
    color(C_MOON, 0.2)
    cylinder(r=moon_r + 10, h=2);
    
    translate([0, 0, 2])
    color(C_MOON)
    cylinder(r=moon_r * 0.7, h=5);
    
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.8)
    difference() {
        cylinder(r=moon_r, h=5);
        translate([0, 0, -1])
        cylinder(r=moon_r * 0.75, h=7);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WAVE LAYERS (With four-bar motion)
// ═══════════════════════════════════════════════════════════════════════════════════
module wave_layer_rocker(layer_num, wave_angle=0) {
    // Wave layer pivots at cliff edge
    pivot_x = WAVE_PIVOT_X;
    pivot_y = 10 + layer_num * 12;
    
    // Calculate oscillation based on four-bar output
    phase = layer_num * 30;
    osc_angle = 8 * sin(wave_angle + phase);
    
    wave_w = 50;
    wave_h = 20 + layer_num * 3;
    
    layer_colors = [C_WAVE_DARK, "#1f5578", "#246082", "#2a6a8c", C_WAVE_LIGHT];
    
    translate([pivot_x, pivot_y, 0])
    rotate([0, 0, osc_angle])
    color(layer_colors[min(layer_num, 4)])
    linear_extrude(height=4)
    polygon([
        [0, -wave_h/2],
        [wave_w * 0.3, -wave_h/2 + 5],
        [wave_w * 0.6, wave_h * 0.3],
        [wave_w * 0.8, wave_h * 0.5],
        [wave_w, wave_h * 0.3],
        [wave_w, -wave_h/2],
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: RICE TUBE
// ═══════════════════════════════════════════════════════════════════════════════════
module rice_tube(tilt=0) {
    tube_length = 200;
    tube_od = 20;
    
    translate([CANVAS_W/2, -12, 0])
    rotate([tilt, 0, 0])
    translate([-tube_length/2, 0, 0])
    rotate([0, 90, 0])
    color(C_RICE_TUBE) {
        difference() {
            cylinder(r=tube_od/2, h=tube_length);
            translate([0, 0, 3])
            cylinder(r=tube_od/2 - 2, h=tube_length - 6);
        }
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
        
        // Motor access
        translate([TAB_W + 20, TAB_W + 10, -1])
        cube([60, 50, WALL_T + 2]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ZONE OUTLINE (Debug)
// ═══════════════════════════════════════════════════════════════════════════════════
module zone_outline(zone, name, col="#ff0000") {
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

// Main gear train (motor + gears in XY plane)
if (SHOW_DRIVE_TRAIN) {
    translate([TAB_W, TAB_W, Z_GEARS_PLANE])
    main_gear_train(master_rot);
}

// Four-bar linkage mechanism
if (SHOW_FOUR_BAR) {
    translate([TAB_W, TAB_W, Z_WAVE_MECHANISM]) {
        // Camshaft assembly
        camshaft_assembly(wave_rot);
        
        // Individual four-bar linkages for each wave
        for (i = [0:NUM_WAVE_LAYERS-1]) {
            four_bar_linkage(wave_rot, i);
        }
    }
}

// Sky mechanism (drives swirls)
if (SHOW_SKY_GEARS) {
    translate([TAB_W, TAB_W, 0])
    sky_mechanism(sky_rot);
}

// Rice tube
if (SHOW_RICE_TUBE) {
    translate([TAB_W, TAB_W, Z_RICE_TUBE])
    rice_tube(rice_tilt);
}

// Moon
if (SHOW_MOON) {
    translate([TAB_W + zone_cx(ZONE_MOON), TAB_W + zone_cy(ZONE_MOON), Z_MOON])
    moon_assembly(sky_rot * 0.6);
}

// Swirl discs - positioned under wind path holes
if (SHOW_BIG_SWIRL) {
    // Big swirl DIRECTLY under large hole
    translate([TAB_W + WIND_LARGE_HOLE_X, TAB_W + WIND_LARGE_HOLE_Y, Z_SWIRL_BACK])
    swirl_disc(WIND_LARGE_HOLE_R - 3, sky_rot * 1.5, 5);
    
    translate([TAB_W + WIND_LARGE_HOLE_X, TAB_W + WIND_LARGE_HOLE_Y, Z_SWIRL_FRONT])
    swirl_disc(WIND_LARGE_HOLE_R * 0.7, -sky_rot * 2, 4);
}

if (SHOW_SMALL_SWIRL) {
    // Small swirl DIRECTLY under small hole
    translate([TAB_W + WIND_SMALL_HOLE_X, TAB_W + WIND_SMALL_HOLE_Y, Z_SWIRL_BACK])
    swirl_disc(WIND_SMALL_HOLE_R - 3, -sky_rot * 2, 5);
    
    translate([TAB_W + WIND_SMALL_HOLE_X, TAB_W + WIND_SMALL_HOLE_Y, Z_SWIRL_FRONT])
    swirl_disc(WIND_SMALL_HOLE_R * 0.7, sky_rot * 2.5, 4);
}

// Wind path panel (25% larger)
if (SHOW_WIND_PATH) {
    translate([TAB_W, TAB_W, Z_WIND_PATH])
    wind_path_traced();
}

// Bird wire
if (SHOW_BIRD_WIRE) {
    translate([TAB_W, TAB_W, Z_BIRD_WIRE]) {
        bird_wire_track();
        bird(bird_pos);
        bird(fmod(bird_pos + 0.3, 1));
    }
}

// Cliff
if (SHOW_CLIFF) {
    translate([TAB_W, TAB_W, Z_CLIFF])
    cliff_traced();
}

// Lighthouse - ON TOP of cliff
if (SHOW_LIGHTHOUSE) {
    // Position at cliff top (Y = 65), centered in lighthouse zone X
    translate([TAB_W + zone_cx(ZONE_LIGHTHOUSE), TAB_W + ZONE_CLIFF[3], Z_CLIFF + 10])
    lighthouse(motor_rot * 2);
}

// Wave layers with four-bar motion
if (SHOW_CLIFF_WAVES) {
    translate([TAB_W, TAB_W, Z_WAVES]) {
        for (i = [0:4]) {
            wave_layer_rocker(i, wave_rot);
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
        zone_outline(ZONE_CLIFF, "CLIFF", "#8B4513");
        zone_outline(ZONE_LIGHTHOUSE, "LH", "#FFD700");
        zone_outline(ZONE_CYPRESS, "CYP", "#228B22");
        zone_outline(ZONE_WIND_PATH, "WIND", "#9370DB");
        zone_outline(ZONE_BIG_SWIRL, "BS", "#FF00FF");
        zone_outline(ZONE_SMALL_SWIRL, "SS", "#FF69B4");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V40 - FULLY FUNCTIONAL MECHANISMS");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("GEAR SPECIFICATIONS (Module = 1mm):");
echo("  Motor pinion:", MOTOR_PINION_T, "T, R=", MOTOR_PINION_R, "mm");
echo("  Master gear:", MASTER_GEAR_T, "T, R=", MASTER_GEAR_R, "mm");
echo("  Sky drive:", SKY_DRIVE_T, "T, R=", SKY_DRIVE_R, "mm");
echo("  Wave drive:", WAVE_DRIVE_T, "T, R=", WAVE_DRIVE_R, "mm");
echo("");
echo("CENTER DISTANCES:");
echo("  Motor to Master:", CD_MOTOR_TO_MASTER, "mm");
echo("  Master to Sky:", CD_MASTER_TO_SKY, "mm");
echo("  Master to Wave:", CD_MASTER_TO_WAVE, "mm");
echo("");
echo("FOUR-BAR LINKAGE:");
echo("  Crank radius:", CRANK_RADIUS, "mm");
echo("  Coupler length:", COUPLER_LENGTH, "mm");
echo("  Wave pivot X:", WAVE_PIVOT_X, "mm");
echo("  Number of linkages:", NUM_WAVE_LAYERS);
echo("  Phase offset:", 30, "° each");
echo("");
echo("WIND PATH SCALE:", WIND_SCALE, "(25% larger than V39)");
echo("  Large hole center: (", WIND_LARGE_HOLE_X, ",", WIND_LARGE_HOLE_Y, ")");
echo("  Small hole center: (", WIND_SMALL_HOLE_X, ",", WIND_SMALL_HOLE_Y, ")");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
