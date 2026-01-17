// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V44 - CLOCK-STYLE INTERCONNECTED GEAR SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════
// KEY FIXES:
// - GEAR SUPPORT PLATE (skeleton) with bearing holes for all axles
// - ALL GEARS MESH DIRECTLY (no belts, no shafts bridging gaps)
// - Motor pinion PROPERLY MESHES with master gear
// - Cliff at X=0, Y=0 (bottom-left corner)
// - Cypress bottom at enclosure inside surface (Y=0)
// - Lighthouse glued to cliff top
// - All gears rotate via tooth-to-tooth contact
// ═══════════════════════════════════════════════════════════════════════════════════
$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         SHOW/HIDE CONTROLS
// ═══════════════════════════════════════════════════════════════════════════════════
SHOW_ENCLOSURE      = true;
SHOW_BACK_PANEL     = true;
SHOW_GEAR_PLATE     = true;   // Support skeleton for gears
SHOW_CLIFF          = true;
SHOW_LIGHTHOUSE     = true;
SHOW_CYPRESS        = true;
SHOW_WAVES          = true;
SHOW_WIND_PATH      = true;
SHOW_BIG_SWIRL      = true;
SHOW_SMALL_SWIRL    = true;
SHOW_MOON           = true;
SHOW_MOTOR          = true;
SHOW_GEAR_TRAIN     = true;   // Complete interconnected gear system
SHOW_BIRD_WIRE      = true;
SHOW_RICE_TUBE      = true;
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
MOUNT_TAB_D = 15;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS [X_min, X_max, Y_min, Y_max]
// ═══════════════════════════════════════════════════════════════════════════════════
ZONE_CLIFF        = [0, 108, 0, 65];
ZONE_LIGHTHOUSE   = [73, 82, 65, 117];
ZONE_CYPRESS      = [35, 95, 0, 121];
ZONE_COMBINED_WAVES = [108, 302, 0, 69];
ZONE_BIG_SWIRL    = [86, 160, 110, 170];
ZONE_SMALL_SWIRL  = [151, 198, 105, 154];
ZONE_MOON         = [231, 300, 141, 202];
ZONE_BIRD_WIRE    = [0, 302, 130, 150];

function zone_w(z) = z[1] - z[0];
function zone_h(z) = z[3] - z[2];
function zone_cx(z) = (z[0] + z[1]) / 2;
function zone_cy(z) = (z[2] + z[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════
Z_BACK_PANEL      = 0;
Z_GEAR_PLATE      = 5;        // Support plate for all gear axles
Z_GEARS           = 8;        // All gears in XY plane at this Z
Z_RICE_TUBE       = 6;
Z_MOON            = 22;
Z_SWIRL_BACK      = 28;
Z_SWIRL_FRONT     = 33;
Z_WIND_PATH       = 38;
Z_BIRD_WIRE       = 42;
Z_CLIFF           = 45;
Z_LIGHTHOUSE      = 48;
Z_WAVES           = 52;
Z_CYPRESS         = 65;
Z_FRONT           = 76;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════════
t = $t;
motor_rot = t * 360 * 6;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         GEAR SPECIFICATIONS (Module 1.5 for strength)
// ═══════════════════════════════════════════════════════════════════════════════════
GEAR_MOD = 1.5;  // Larger module for better meshing visibility

// Tooth counts
T_MOTOR   = 12;   // Motor pinion
T_MASTER  = 48;   // Master gear (4:1 reduction)
T_IDLER   = 18;   // Standard idler gear
T_SWIRL   = 24;   // Swirl output gear

// Pitch radii = teeth * module / 2
R_MOTOR  = T_MOTOR * GEAR_MOD / 2;    // 9mm
R_MASTER = T_MASTER * GEAR_MOD / 2;   // 36mm
R_IDLER  = T_IDLER * GEAR_MOD / 2;    // 13.5mm
R_SWIRL  = T_SWIRL * GEAR_MOD / 2;    // 18mm

// Center distances for meshing
CD_MOTOR_MASTER = R_MOTOR + R_MASTER;  // 45mm
CD_IDLER_IDLER = R_IDLER + R_IDLER;    // 27mm
CD_IDLER_SWIRL = R_IDLER + R_SWIRL;    // 31.5mm

// ═══════════════════════════════════════════════════════════════════════════════════
//                         GEAR POSITION LAYOUT
// All positions carefully calculated for proper meshing
// ═══════════════════════════════════════════════════════════════════════════════════

// MOTOR - Position sets the origin of the gear train
MOTOR_X = 30;
MOTOR_Y = 25;

// MASTER GEAR - Meshes with motor pinion
MASTER_X = MOTOR_X + CD_MOTOR_MASTER;  // 30 + 45 = 75
MASTER_Y = MOTOR_Y;                     // 25

// Calculate all idler positions to bridge from MASTER to SWIRLS
// Big swirl target: ~123, 140
// Small swirl target: ~175, 130

// IDLER CHAIN TO BIG SWIRL (need ~6 gears to span the distance)
// From master (75, 25) to big swirl (123, 140)
// Direction: mostly upward (+Y) with slight right (+X)

IDLER1_X = MASTER_X;                           // 75
IDLER1_Y = MASTER_Y + R_MASTER + R_IDLER;     // 25 + 36 + 13.5 = 74.5

IDLER2_X = IDLER1_X + CD_IDLER_IDLER * 0.5;   // 75 + 13.5 = 88.5
IDLER2_Y = IDLER1_Y + CD_IDLER_IDLER * 0.866; // 74.5 + 23.4 = 97.9

IDLER3_X = IDLER2_X + CD_IDLER_IDLER * 0.3;   // 88.5 + 8.1 = 96.6
IDLER3_Y = IDLER2_Y + CD_IDLER_IDLER * 0.95;  // 97.9 + 25.65 = 123.55

// Big swirl position (must mesh with IDLER3)
BIG_SWIRL_X = IDLER3_X + CD_IDLER_SWIRL * 0.6;  // 96.6 + 18.9 = 115.5
BIG_SWIRL_Y = IDLER3_Y + CD_IDLER_SWIRL * 0.8;  // 123.55 + 25.2 = 148.75

// IDLER CHAIN TO SMALL SWIRL (branches from IDLER2)
IDLER4_X = IDLER2_X + CD_IDLER_IDLER;          // 88.5 + 27 = 115.5
IDLER4_Y = IDLER2_Y;                            // 97.9

IDLER5_X = IDLER4_X + CD_IDLER_IDLER;          // 115.5 + 27 = 142.5
IDLER5_Y = IDLER4_Y + CD_IDLER_IDLER * 0.5;    // 97.9 + 13.5 = 111.4

// Small swirl position (must mesh with IDLER5)
SMALL_SWIRL_X = IDLER5_X + CD_IDLER_SWIRL;     // 142.5 + 31.5 = 174
SMALL_SWIRL_Y = IDLER5_Y;                       // 111.4

// WAVE DRIVE - Meshes with master on the right side
WAVE_X = MASTER_X + R_MASTER + R_IDLER;        // 75 + 36 + 13.5 = 124.5
WAVE_Y = MASTER_Y;                              // 25

// RICE TUBE CAM - Meshes with wave drive
RICE_X = WAVE_X + CD_IDLER_IDLER;              // 124.5 + 27 = 151.5
RICE_Y = WAVE_Y;                                // 25

// Store all gear positions in array for gear plate
GEAR_POSITIONS = [
    [MOTOR_X, MOTOR_Y, R_MOTOR],
    [MASTER_X, MASTER_Y, R_MASTER],
    [IDLER1_X, IDLER1_Y, R_IDLER],
    [IDLER2_X, IDLER2_Y, R_IDLER],
    [IDLER3_X, IDLER3_Y, R_IDLER],
    [BIG_SWIRL_X, BIG_SWIRL_Y, R_SWIRL],
    [IDLER4_X, IDLER4_Y, R_IDLER],
    [IDLER5_X, IDLER5_Y, R_IDLER],
    [SMALL_SWIRL_X, SMALL_SWIRL_Y, R_SWIRL],
    [WAVE_X, WAVE_Y, R_IDLER],
    [RICE_X, RICE_Y, R_IDLER]
];

// ═══════════════════════════════════════════════════════════════════════════════════
//                         COLORS
// ═══════════════════════════════════════════════════════════════════════════════════
C_ENCLOSURE     = "#3a3028";
C_BACK_PANEL    = "#2a2018";
C_GEAR_PLATE    = "#4a4a4a";
C_CLIFF         = "#6b5344";
C_LIGHTHOUSE    = "#c4b498";
C_LH_STRIPE     = "#8b6914";
C_CYPRESS       = "#1a3a1a";
C_WAVE_1        = "#0a2a5e";
C_WAVE_2        = "#1a4a7e";
C_WIND          = "#2a5a9e";
C_SWIRL         = "#4a7ab0";
C_MOON          = "#f0d060";
C_GEAR          = "#b8860b";   // Dark goldenrod (brass-like)
C_SHAFT         = "#c0c0c0";
C_MOTOR         = "#333333";
C_RICE_TUBE     = "#8b6914";
C_WIRE          = "#666666";

// ═══════════════════════════════════════════════════════════════════════════════════
//                         INCLUDES
// ═══════════════════════════════════════════════════════════════════════════════════
use <cliffs_wrapper.scad>
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>

CLIFF_SCALE = 0.924;
CYPRESS_SCALE = 0.69;
WIND_SCALE = 0.1375;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SPUR GEAR (Proper involute-style teeth)
// ═══════════════════════════════════════════════════════════════════════════════════
module spur_gear(teeth, mod=1.5, thick=8, bore=2) {
    pitch_r = teeth * mod / 2;
    outer_r = pitch_r + mod;
    root_r = pitch_r - 1.25 * mod;
    tooth_w = mod * 1.4;
    
    color(C_GEAR)
    difference() {
        union() {
            // Root cylinder
            cylinder(r=root_r, h=thick);
            
            // Teeth
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                linear_extrude(height=thick)
                polygon([
                    [root_r, -tooth_w/2],
                    [pitch_r, -tooth_w/2.5],
                    [outer_r, -tooth_w/4],
                    [outer_r, tooth_w/4],
                    [pitch_r, tooth_w/2.5],
                    [root_r, tooth_w/2]
                ]);
            }
        }
        
        // Center bore
        translate([0, 0, -1])
        cylinder(r=bore, h=thick+2);
        
        // Spoke cutouts for larger gears
        if (pitch_r > 15) {
            spokes = teeth > 30 ? 6 : 4;
            spoke_r = (pitch_r - bore*2) / 2.5;
            for (i = [0:spokes-1]) {
                rotate([0, 0, i * 360/spokes + 180/spokes])
                translate([pitch_r * 0.55, 0, -1])
                cylinder(r=spoke_r, h=thick+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SHAFT/AXLE
// ═══════════════════════════════════════════════════════════════════════════════════
module axle(length, d=4) {
    color(C_SHAFT)
    cylinder(r=d/2, h=length);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: GEAR SUPPORT PLATE (Skeleton)
// Like a clock movement plate - holds all axle bearings
// ═══════════════════════════════════════════════════════════════════════════════════
module gear_support_plate() {
    plate_thickness = 4;
    
    color(C_GEAR_PLATE, 0.7)
    difference() {
        // Main plate shape - covers gear area
        linear_extrude(height=plate_thickness)
        hull() {
            // Bottom left (motor area)
            translate([MOTOR_X - 20, MOTOR_Y - 15])
            circle(r=10);
            
            // Bottom right (wave area)
            translate([RICE_X + 20, WAVE_Y - 10])
            circle(r=10);
            
            // Top left (big swirl area)
            translate([BIG_SWIRL_X - 10, BIG_SWIRL_Y + 10])
            circle(r=10);
            
            // Top right (small swirl area)
            translate([SMALL_SWIRL_X + 10, SMALL_SWIRL_Y + 10])
            circle(r=10);
        }
        
        // Bearing holes for all axles
        for (pos = GEAR_POSITIONS) {
            translate([pos[0], pos[1], -1])
            cylinder(r=2.5, h=plate_thickness+2);
        }
        
        // Large cutout in center to reduce material/weight
        translate([100, 80, -1])
        cylinder(r=25, h=plate_thickness+2);
    }
    
    // Standoffs to mount plate to back panel
    color(C_GEAR_PLATE)
    for (pos = [
        [MOTOR_X - 15, MOTOR_Y - 10],
        [RICE_X + 15, WAVE_Y - 5],
        [BIG_SWIRL_X, BIG_SWIRL_Y + 15],
        [SMALL_SWIRL_X + 5, SMALL_SWIRL_Y + 15]
    ]) {
        translate([pos[0], pos[1], -Z_GEAR_PLATE + Z_BACK_PANEL + WALL_T])
        cylinder(r=4, h=Z_GEAR_PLATE - Z_BACK_PANEL - WALL_T);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ENCLOSURE WITH FRONT MOUNTING TABS
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
    
    // Front mounting tabs (at Z = TOTAL_D)
    color(C_GEAR_PLATE) {
        translate([TAB_W - 10, 0, TOTAL_D])
        cube([CANVAS_W + 20, MOUNT_TAB_D, WALL_T]);
        
        translate([TAB_W - 10, TOTAL_H - MOUNT_TAB_D, TOTAL_D])
        cube([CANVAS_W + 20, MOUNT_TAB_D, WALL_T]);
        
        translate([0, TAB_W - 10, TOTAL_D])
        cube([MOUNT_TAB_D, CANVAS_H + 20, WALL_T]);
        
        translate([TOTAL_W - MOUNT_TAB_D, TAB_W - 10, TOTAL_D])
        cube([MOUNT_TAB_D, CANVAS_H + 20, WALL_T]);
    }
}

module back_panel() {
    color(C_BACK_PANEL)
    difference() {
        translate([WALL_T+2, WALL_T+2, 0])
        cube([TOTAL_W - 2*WALL_T-4, TOTAL_H - 2*WALL_T-4, WALL_T-1]);
        
        // Motor access cutout
        translate([TAB_W + MOTOR_X - 20, TAB_W + MOTOR_Y - 20, -1])
        cube([60, 50, WALL_T+2]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: COMPLETE GEAR TRAIN
// All gears mesh directly - NO BELTS, NO GAPS
// ═══════════════════════════════════════════════════════════════════════════════════
module complete_gear_train() {
    // Calculate rotation for each gear based on mesh direction
    // Meshing gears rotate in OPPOSITE directions
    // Gear ratio affects speed
    
    // MOTOR PINION (input)
    rot_motor = motor_rot;
    
    // MASTER GEAR (meshes with motor, opposite direction)
    rot_master = -motor_rot * T_MOTOR / T_MASTER;  // 4:1 reduction
    
    // IDLER1 (meshes with master, opposite to master)
    rot_idler1 = -rot_master * T_MASTER / T_IDLER;
    
    // IDLER2 (meshes with idler1)
    rot_idler2 = -rot_idler1;
    
    // IDLER3 (meshes with idler2)
    rot_idler3 = -rot_idler2;
    
    // BIG SWIRL (meshes with idler3)
    rot_big_swirl = -rot_idler3 * T_IDLER / T_SWIRL;
    
    // IDLER4 (meshes with idler2, same as idler3 direction)
    rot_idler4 = -rot_idler2;
    
    // IDLER5 (meshes with idler4)
    rot_idler5 = -rot_idler4;
    
    // SMALL SWIRL (meshes with idler5)
    rot_small_swirl = -rot_idler5 * T_IDLER / T_SWIRL;
    
    // WAVE DRIVE (meshes with master)
    rot_wave = -rot_master * T_MASTER / T_IDLER;
    
    // RICE CAM (meshes with wave drive)
    rot_rice = -rot_wave;
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MOTOR (N20 with shaft pointing in +Z direction)
    // ═══════════════════════════════════════════════════════════════════════════
    translate([MOTOR_X, MOTOR_Y, -15]) {
        // Motor body (behind gear plane)
        color(C_MOTOR) {
            translate([-6, -5, 0])
            cube([12, 10, 12]);
        }
        
        // Motor shaft
        color(C_SHAFT)
        cylinder(r=1.5, h=25);
    }
    
    // Motor pinion
    translate([MOTOR_X, MOTOR_Y, 0])
    rotate([0, 0, rot_motor])
    spur_gear(T_MOTOR, GEAR_MOD, 10, 1.5);
    
    // Axle
    translate([MOTOR_X, MOTOR_Y, -5])
    axle(20, 3);
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MASTER GEAR (meshes with motor pinion)
    // ═══════════════════════════════════════════════════════════════════════════
    translate([MASTER_X, MASTER_Y, 0])
    rotate([0, 0, rot_master])
    spur_gear(T_MASTER, GEAR_MOD, 10, 3);
    
    translate([MASTER_X, MASTER_Y, -5])
    axle(25, 6);
    
    // ═══════════════════════════════════════════════════════════════════════════
    // IDLER CHAIN TO BIG SWIRL
    // ═══════════════════════════════════════════════════════════════════════════
    
    // IDLER1
    translate([IDLER1_X, IDLER1_Y, 0])
    rotate([0, 0, rot_idler1])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([IDLER1_X, IDLER1_Y, -5])
    axle(20, 4);
    
    // IDLER2
    translate([IDLER2_X, IDLER2_Y, 0])
    rotate([0, 0, rot_idler2])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([IDLER2_X, IDLER2_Y, -5])
    axle(20, 4);
    
    // IDLER3
    translate([IDLER3_X, IDLER3_Y, 0])
    rotate([0, 0, rot_idler3])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([IDLER3_X, IDLER3_Y, -5])
    axle(20, 4);
    
    // BIG SWIRL GEAR
    translate([BIG_SWIRL_X, BIG_SWIRL_Y, 0])
    rotate([0, 0, rot_big_swirl])
    spur_gear(T_SWIRL, GEAR_MOD, 8, 2);
    translate([BIG_SWIRL_X, BIG_SWIRL_Y, -5])
    axle(Z_SWIRL_BACK, 4);
    
    // ═══════════════════════════════════════════════════════════════════════════
    // IDLER CHAIN TO SMALL SWIRL (branches from IDLER2)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // IDLER4
    translate([IDLER4_X, IDLER4_Y, 0])
    rotate([0, 0, rot_idler4])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([IDLER4_X, IDLER4_Y, -5])
    axle(20, 4);
    
    // IDLER5
    translate([IDLER5_X, IDLER5_Y, 0])
    rotate([0, 0, rot_idler5])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([IDLER5_X, IDLER5_Y, -5])
    axle(20, 4);
    
    // SMALL SWIRL GEAR
    translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, 0])
    rotate([0, 0, rot_small_swirl])
    spur_gear(T_SWIRL, GEAR_MOD, 8, 2);
    translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, -5])
    axle(Z_SWIRL_BACK, 4);
    
    // ═══════════════════════════════════════════════════════════════════════════
    // WAVE DRIVE CHAIN (from master to wave mechanism)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // WAVE DRIVE GEAR
    translate([WAVE_X, WAVE_Y, 0])
    rotate([0, 0, rot_wave])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([WAVE_X, WAVE_Y, -5])
    axle(Z_WAVES, 4);
    
    // RICE CAM GEAR
    translate([RICE_X, RICE_Y, 0])
    rotate([0, 0, rot_rice])
    spur_gear(T_IDLER, GEAR_MOD, 8, 2);
    translate([RICE_X, RICE_Y, -5])
    axle(20, 4);
    
    // ═══════════════════════════════════════════════════════════════════════════
    // DEBUG: Show mesh connections
    // ═══════════════════════════════════════════════════════════════════════════
    color("red", 0.3) {
        // Motor to Master
        mesh_line(MOTOR_X, MOTOR_Y, MASTER_X, MASTER_Y);
        
        // Master to Idler1
        mesh_line(MASTER_X, MASTER_Y, IDLER1_X, IDLER1_Y);
        
        // Idler chain to big swirl
        mesh_line(IDLER1_X, IDLER1_Y, IDLER2_X, IDLER2_Y);
        mesh_line(IDLER2_X, IDLER2_Y, IDLER3_X, IDLER3_Y);
        mesh_line(IDLER3_X, IDLER3_Y, BIG_SWIRL_X, BIG_SWIRL_Y);
        
        // Idler chain to small swirl
        mesh_line(IDLER2_X, IDLER2_Y, IDLER4_X, IDLER4_Y);
        mesh_line(IDLER4_X, IDLER4_Y, IDLER5_X, IDLER5_Y);
        mesh_line(IDLER5_X, IDLER5_Y, SMALL_SWIRL_X, SMALL_SWIRL_Y);
        
        // Master to Wave
        mesh_line(MASTER_X, MASTER_Y, WAVE_X, WAVE_Y);
        
        // Wave to Rice
        mesh_line(WAVE_X, WAVE_Y, RICE_X, RICE_Y);
    }
}

module mesh_line(x1, y1, x2, y2) {
    hull() {
        translate([x1, y1, 5]) sphere(r=1);
        translate([x2, y2, 5]) sphere(r=1);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SWIRL DISC
// ═══════════════════════════════════════════════════════════════════════════════════
module swirl_disc(radius, rot=0, thick=5) {
    rotate([0, 0, rot])
    color(C_SWIRL)
    difference() {
        cylinder(r=radius, h=thick);
        translate([0, 0, -1]) cylinder(r=2, h=thick+2);
        for (i = [0:5]) {
            rotate([0, 0, i*60])
            translate([radius*0.55, 0, -1])
            cylinder(r=radius*0.18, h=thick+2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: RICE TUBE (XY plane see-saw)
// ═══════════════════════════════════════════════════════════════════════════════════
module rice_tube(rot=0) {
    tilt = 15 * sin(rot);
    tube_len = 140;
    tube_r = 8;
    
    // Position to right of gear area
    pivot_x = 200;
    pivot_y = 30;
    
    translate([pivot_x, pivot_y, 0]) {
        rotate([0, 0, tilt]) {
            translate([-tube_len/2, 0, 0]) {
                color(C_RICE_TUBE)
                rotate([0, 90, 0])
                difference() {
                    cylinder(r=tube_r, h=tube_len);
                    translate([0, 0, 3])
                    cylinder(r=tube_r-2, h=tube_len-6);
                }
            }
        }
        
        // Pivot mount
        color("#444")
        translate([0, 0, -3])
        cylinder(r=4, h=6);
    }
    
    // Linkage from rice cam to rice tube
    link_angle = atan2(pivot_y - RICE_Y, pivot_x - RICE_X);
    link_len = sqrt(pow(pivot_x - RICE_X, 2) + pow(pivot_y - RICE_Y, 2));
    
    color(C_GEAR)
    translate([RICE_X, RICE_Y, 12])
    rotate([0, 0, link_angle])
    cube([link_len, 3, 3]);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WAVE LAYERS
// ═══════════════════════════════════════════════════════════════════════════════════
module wave_layers(rot) {
    wave_cx = zone_cx(ZONE_COMBINED_WAVES);
    wave_cy = zone_cy(ZONE_COMBINED_WAVES);
    
    osc1 = 10 * sin(rot);
    osc2 = 10 * sin(rot + 60);
    
    translate([wave_cx, wave_cy - 5, 0])
    rotate([0, 0, osc1])
    color(C_WAVE_1)
    import("ocean_layer_1.stl");
    
    translate([wave_cx, wave_cy + 5, 5])
    rotate([0, 0, osc2])
    color(C_WAVE_2)
    import("ocean_layer_2.stl");
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: BIRD WIRE (20mm spacing)
// ═══════════════════════════════════════════════════════════════════════════════════
module bird_wire() {
    wire_y1 = ZONE_BIRD_WIRE[2];
    wire_y2 = ZONE_BIRD_WIRE[3];
    
    color(C_WIRE) {
        translate([0, wire_y1, 0])
        rotate([0, 90, 0])
        cylinder(r=1, h=CANVAS_W);
        
        translate([0, wire_y2, 0])
        rotate([0, 90, 0])
        cylinder(r=1, h=CANVAS_W);
    }
}

module bird(pos) {
    x = 20 + pos * (CANVAS_W - 40);
    y = zone_cy(ZONE_BIRD_WIRE);
    
    translate([x, y, 3])
    color("#222")
    scale([1, 0.5, 0.4])
    sphere(r=5);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: LIGHTHOUSE (Upright, on cliff top)
// ═══════════════════════════════════════════════════════════════════════════════════
module lighthouse(rot=0) {
    height = 45;
    
    rotate([-90, 0, 0]) {
        color(C_LIGHTHOUSE)
        cylinder(r1=5, r2=3.5, h=height*0.7);
        
        color(C_LH_STRIPE)
        for (z = [8, 20, 32])
            translate([0, 0, z])
            cylinder(r=4.5 - z/15, h=5);
        
        translate([0, 0, height*0.7])
        color("#444")
        cylinder(r=5, h=2);
        
        translate([0, 0, height*0.75])
        color("LightYellow", 0.5)
        cylinder(r=4.5, h=8);
        
        translate([0, 0, height*0.75])
        rotate([0, 0, rot])
        color("#333", 0.6)
        difference() {
            cylinder(r=5, h=6);
            translate([-6, -1, -1])
            cube([12, 2, 8]);
        }
        
        translate([0, 0, height*0.88])
        color(C_LH_STRIPE)
        cylinder(r1=5, r2=2, h=6);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CLIFF (Bottom-left corner at 0,0)
// ═══════════════════════════════════════════════════════════════════════════════════
module cliff_shape() {
    // Cliff origin is at X=0, Y=0 (flush to bottom-left of canvas)
    scale([CLIFF_SCALE, CLIFF_SCALE, 1])
    color(C_CLIFF)
    cliffs_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CYPRESS (Bottom at Y=0, glued to enclosure surface)
// ═══════════════════════════════════════════════════════════════════════════════════
module cypress_shape_module() {
    // Cypress must have its bottom at Y=0
    // The traced shape has its own origin, need to translate
    orig_y_min = -112.572;
    orig_cx = 21;
    
    translate([zone_cx(ZONE_CYPRESS), 0, 0])
    scale([CYPRESS_SCALE, CYPRESS_SCALE, 1])
    translate([-orig_cx, -orig_y_min, 0])
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WIND PATH
// ═══════════════════════════════════════════════════════════════════════════════════
module wind_path_module() {
    translate([zone_cx(ZONE_WIND_PATH), zone_cy(ZONE_WIND_PATH), 0])
    scale([WIND_SCALE, WIND_SCALE, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MOON
// ═══════════════════════════════════════════════════════════════════════════════════
module moon(rot=0) {
    r = 26;
    color(C_MOON, 0.2) cylinder(r=r+8, h=2);
    translate([0, 0, 2]) color(C_MOON) cylinder(r=r*0.55, h=4);
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.8)
    difference() {
        cylinder(r=r, h=4);
        translate([0, 0, -1]) cylinder(r=r*0.6, h=6);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ZONE OUTLINE
// ═══════════════════════════════════════════════════════════════════════════════════
module zone_outline(zone, col) {
    color(col, 0.3)
    translate([zone[0], zone[2], 0])
    linear_extrude(height=1)
    difference() {
        square([zone_w(zone), zone_h(zone)]);
        translate([2, 2]) square([zone_w(zone)-4, zone_h(zone)-4]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════

// Enclosure
if (SHOW_ENCLOSURE) enclosure();
if (SHOW_BACK_PANEL) translate([0, 0, Z_BACK_PANEL]) back_panel();

// Gear support plate (skeleton)
if (SHOW_GEAR_PLATE) {
    translate([TAB_W, TAB_W, Z_GEAR_PLATE])
    gear_support_plate();
}

// Complete interconnected gear train
if (SHOW_GEAR_TRAIN) {
    translate([TAB_W, TAB_W, Z_GEARS])
    complete_gear_train();
}

// Rice tube
if (SHOW_RICE_TUBE) {
    translate([TAB_W, TAB_W, Z_RICE_TUBE])
    rice_tube(motor_rot * T_MOTOR / T_MASTER);
}

// Moon
if (SHOW_MOON) {
    translate([TAB_W + zone_cx(ZONE_MOON), TAB_W + zone_cy(ZONE_MOON), Z_MOON])
    moon(motor_rot * 0.1);
}

// Swirl discs (driven by gear train)
if (SHOW_BIG_SWIRL) {
    // Calculate big swirl rotation from gear train
    big_rot = motor_rot * T_MOTOR / T_MASTER * T_MASTER / T_IDLER;
    
    translate([TAB_W + BIG_SWIRL_X, TAB_W + BIG_SWIRL_Y, Z_SWIRL_BACK])
    swirl_disc(28, big_rot, 5);
    
    translate([TAB_W + BIG_SWIRL_X, TAB_W + BIG_SWIRL_Y, Z_SWIRL_FRONT])
    swirl_disc(20, -big_rot * 1.3, 4);
}

if (SHOW_SMALL_SWIRL) {
    small_rot = -motor_rot * T_MOTOR / T_MASTER * T_MASTER / T_IDLER;
    
    translate([TAB_W + SMALL_SWIRL_X, TAB_W + SMALL_SWIRL_Y, Z_SWIRL_BACK])
    swirl_disc(20, small_rot, 5);
    
    translate([TAB_W + SMALL_SWIRL_X, TAB_W + SMALL_SWIRL_Y, Z_SWIRL_FRONT])
    swirl_disc(14, -small_rot * 1.3, 4);
}

// Wind path
if (SHOW_WIND_PATH) {
    translate([TAB_W, TAB_W, Z_WIND_PATH])
    wind_path_module();
}

// Bird wire
if (SHOW_BIRD_WIRE) {
    translate([TAB_W, TAB_W, Z_BIRD_WIRE]) {
        bird_wire();
        bird(t);
        bird(fmod(t + 0.4, 1));
    }
}

// CLIFF (origin at X=0, Y=0)
if (SHOW_CLIFF) {
    translate([TAB_W + 0, TAB_W + 0, Z_CLIFF])  // X=0, Y=0
    cliff_shape();
}

// LIGHTHOUSE (on cliff top, Y = 65)
if (SHOW_LIGHTHOUSE) {
    // Lighthouse position: X centered in zone, Y at cliff top
    lh_x = zone_cx(ZONE_LIGHTHOUSE);  // ~77.5
    lh_y = ZONE_CLIFF[3];             // 65 (cliff top)
    
    translate([TAB_W + lh_x, TAB_W + lh_y, Z_LIGHTHOUSE])
    lighthouse(motor_rot * 3);
}

// Waves
if (SHOW_WAVES) {
    wave_rot = motor_rot * T_MOTOR / T_MASTER * T_MASTER / T_IDLER;
    translate([TAB_W, TAB_W, Z_WAVES])
    wave_layers(wave_rot);
}

// CYPRESS (bottom at Y=0, glued to enclosure top inside surface)
if (SHOW_CYPRESS) {
    translate([TAB_W + 0, TAB_W + 0, Z_CYPRESS])  // Y=0
    cypress_shape_module();
}

// Zone outlines
if (SHOW_ZONE_OUTLINES) {
    translate([TAB_W, TAB_W, 70]) {
        zone_outline(ZONE_CLIFF, "#8B4513");
        zone_outline(ZONE_LIGHTHOUSE, "#FFD700");
        zone_outline(ZONE_CYPRESS, "#228B22");
        zone_outline(ZONE_COMBINED_WAVES, "#4169E1");
        zone_outline(ZONE_BIG_SWIRL, "#FF00FF");
        zone_outline(ZONE_SMALL_SWIRL, "#FF69B4");
        zone_outline(ZONE_BIRD_WIRE, "#696969");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V44 - CLOCK-STYLE GEAR SYSTEM");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("GEAR TRAIN (all mesh directly, NO BELTS):");
echo("  Motor(12T) → Master(48T) → Idler1 → Idler2 → Idler3 → Big Swirl(24T)");
echo("                                   └→ Idler4 → Idler5 → Small Swirl(24T)");
echo("                         └→ Wave(18T) → Rice Cam(18T)");
echo("");
echo("GEAR POSITIONS:");
echo("  Motor:      X=", MOTOR_X, " Y=", MOTOR_Y);
echo("  Master:     X=", MASTER_X, " Y=", MASTER_Y);
echo("  Big Swirl:  X=", BIG_SWIRL_X, " Y=", BIG_SWIRL_Y);
echo("  Small Swirl:X=", SMALL_SWIRL_X, " Y=", SMALL_SWIRL_Y);
echo("");
echo("CENTER DISTANCES (for proper mesh):");
echo("  Motor-Master: ", CD_MOTOR_MASTER, "mm");
echo("  Idler-Idler:  ", CD_IDLER_IDLER, "mm");
echo("  Idler-Swirl:  ", CD_IDLER_SWIRL, "mm");
echo("");
echo("COMPONENT POSITIONS:");
echo("  Cliff:      X=0, Y=0 (flush bottom-left)");
echo("  Lighthouse: X=77.5, Y=65 (on cliff top)");
echo("  Cypress:    bottom at Y=0 (glued to surface)");
echo("");
echo("SUPPORT: Gear plate (skeleton) holds all axles");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
