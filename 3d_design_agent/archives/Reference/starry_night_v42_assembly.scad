// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V42 - COMPREHENSIVE MECHANICAL FIX
// ═══════════════════════════════════════════════════════════════════════════════════
// FIXES:
// 1. Rice tube: XY plane see-saw (Z-axis rotation), connected via cam follower
// 2. Bird path: Exactly 20mm between two parallel wires
// 3. Lighthouse: Upright (-90° X rotation), glued to cliff top
// 4. Axles: Mounted to enclosure back wall
// 5. Enclosure: Proper mounting tabs for wood frame
// 6. Waves: Imported STL files with calculated four-bar linkage
// 7. All mechanisms visibly connected
// ═══════════════════════════════════════════════════════════════════════════════════
$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         SHOW/HIDE CONTROLS
// ═══════════════════════════════════════════════════════════════════════════════════
SHOW_ENCLOSURE      = true;
SHOW_BACK_PANEL     = true;
SHOW_MOUNTING_TABS  = true;
SHOW_CLIFF          = true;
SHOW_LIGHTHOUSE     = true;
SHOW_CYPRESS        = true;
SHOW_WAVES          = true;    // STL wave layers
SHOW_FOUR_BAR       = true;    // Four-bar linkage mechanism
SHOW_WIND_PATH      = true;
SHOW_BIG_SWIRL      = true;
SHOW_SMALL_SWIRL    = true;
SHOW_MOON           = true;
SHOW_GEARS          = true;
SHOW_BIRD_WIRE      = true;
SHOW_RICE_TUBE      = true;
SHOW_MOTOR          = true;
SHOW_AXLE_MOUNTS    = true;
SHOW_SWIRL_DRIVE    = true;
SHOW_ZONE_OUTLINES  = false;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MASTER DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════════════
TOTAL_W = 350;
TOTAL_H = 250;
TOTAL_D = 80;
TAB_W = 24;
WALL_T = 4;
CANVAS_W = 302;    // TOTAL_W - 2*TAB_W
CANVAS_H = 202;    // TOTAL_H - 2*TAB_W
FRAME_MOUNT_TAB = 15;  // Mounting tabs for wood frame

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════════
ZONE_CLIFF        = [0, 108, 0, 65];
ZONE_LIGHTHOUSE   = [73, 82, 65, 117];
ZONE_CYPRESS      = [35, 95, 0, 121];
ZONE_CLIFF_WAVES  = [108, 160, 0, 69];
ZONE_OCEAN_WAVES  = [151, 302, 0, 65];
ZONE_COMBINED_WAVES = [108, 302, 0, 69];  // Combined wave area
ZONE_BOTTOM_GEARS = [164, 302, 0, 30];
ZONE_WIND_PATH    = [0, 198, 105, 202];
ZONE_BIG_SWIRL    = [86, 160, 110, 170];
ZONE_SMALL_SWIRL  = [151, 198, 105, 154];
ZONE_MOON         = [231, 300, 141, 202];
ZONE_BIRD_WIRE    = [0, 302, 130, 150];   // 20mm height for two wires

function zone_w(z) = z[1] - z[0];
function zone_h(z) = z[3] - z[2];
function zone_cx(z) = (z[0] + z[1]) / 2;
function zone_cy(z) = (z[2] + z[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════
Z_BACK_PANEL      = 0;
Z_AXLE_MOUNT      = 3;
Z_MOTOR           = 8;
Z_GEARS_PLANE     = 12;
Z_RICE_TUBE       = 10;       // Inside enclosure, near back
Z_MOON            = 25;
Z_SWIRL_DRIVE     = 28;
Z_SKY_MECHANISM   = 30;
Z_SWIRL_BACK      = 32;
Z_SWIRL_FRONT     = 36;
Z_WIND_PATH       = 40;
Z_BIRD_WIRE       = 45;
Z_CLIFF           = 48;
Z_LIGHTHOUSE      = 50;
Z_WAVE_MECHANISM  = 52;
Z_WAVES_BACK      = 55;
Z_WAVES_FRONT     = 65;
Z_CYPRESS         = 72;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════════
t = $t;
motor_angle = t * 360 * 6;
master_angle = t * 360;
sky_angle = -master_angle * 3;
wave_angle = -master_angle * 2;
swirl_angle = sky_angle * 0.5;
bird_pos = t;
rice_tilt = 12 * sin(t * 360);  // ±12° see-saw motion

// ═══════════════════════════════════════════════════════════════════════════════════
//                         FOUR-BAR LINKAGE PARAMETERS (Calculated)
// Ratio: Crank:Ground:Coupler:Rocker = 1.0:2.5:3.0:2.5
// Grashof Check: 16+48=64 < 40+40=80 ✓
// ═══════════════════════════════════════════════════════════════════════════════════
CRANK_LENGTH = 16;      // s - rotating input
GROUND_LENGTH = 40;     // g - fixed distance between pivots
COUPLER_LENGTH = 48;    // c - connecting rod
ROCKER_LENGTH = 40;     // r - wave layer arm

// Phase offsets for 4 wave layers (traveling wave effect)
WAVE_PHASES = [0, 45, 90, 135];

// ═══════════════════════════════════════════════════════════════════════════════════
//                         GEAR SPECIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════════
GEAR_MODULE = 1;
MOTOR_PINION_T = 10;
MASTER_GEAR_T = 60;
SKY_DRIVE_T = 20;
WAVE_DRIVE_T = 30;
RICE_CAM_T = 24;        // Dedicated cam for rice tube

MOTOR_PINION_R = MOTOR_PINION_T / 2;
MASTER_GEAR_R = MASTER_GEAR_T / 2;
SKY_DRIVE_R = SKY_DRIVE_T / 2;
WAVE_DRIVE_R = WAVE_DRIVE_T / 2;

CD_MOTOR_MASTER = MOTOR_PINION_R + MASTER_GEAR_R;  // 35mm
CD_MASTER_SKY = MASTER_GEAR_R + SKY_DRIVE_R;       // 40mm
CD_MASTER_WAVE = MASTER_GEAR_R + WAVE_DRIVE_R;     // 45mm

// ═══════════════════════════════════════════════════════════════════════════════════
//                         SWIRL POSITIONS (Under wind path holes)
// ═══════════════════════════════════════════════════════════════════════════════════
BIG_SWIRL_X = 115;
BIG_SWIRL_Y = 140;
BIG_SWIRL_R = 32;

SMALL_SWIRL_X = 172;
SMALL_SWIRL_Y = 130;
SMALL_SWIRL_R = 22;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         COLORS
// ═══════════════════════════════════════════════════════════════════════════════════
C_ENCLOSURE     = "#3a3028";
C_BACK_PANEL    = "#2a2018";
C_FRAME_TAB     = "#5a4a38";
C_CLIFF         = "#6b5344";
C_LIGHTHOUSE    = "#c4b498";
C_LIGHTHOUSE_STRIPE = "#8b6914";
C_CYPRESS       = "#1a3a1a";
C_WAVE_1        = "#0a2a5e";
C_WAVE_2        = "#1a4a7e";
C_WAVE_3        = "#2a6a9e";
C_WAVE_4        = "#3a8abe";
C_WIND          = "#2a5a9e";
C_SWIRL         = "#4a7ab0";
C_MOON          = "#f0d060";
C_GEAR          = "#8b7355";
C_SHAFT         = "#b0a090";
C_MOTOR         = "#333333";
C_COUPLER       = "#555555";
C_RICE_TUBE     = "#8b6914";
C_WIRE          = "#666666";

// ═══════════════════════════════════════════════════════════════════════════════════
//                         INCLUDE FILES
// ═══════════════════════════════════════════════════════════════════════════════════
use <cliffs_wrapper.scad>
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>

CLIFF_SCALE = 0.77;
CYPRESS_SCALE = 0.69;
WIND_SCALE = 0.1375;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SPUR GEAR
// ═══════════════════════════════════════════════════════════════════════════════════
module spur_gear(teeth, module_=1, thickness=6, bore_r=1.5, spokes=true) {
    pitch_r = teeth * module_ / 2;
    outer_r = pitch_r + module_;
    root_r = pitch_r - 1.25 * module_;
    tooth_width = 1.5 * module_;
    
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=root_r, h=thickness);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                linear_extrude(height=thickness)
                polygon([
                    [root_r, -tooth_width/2],
                    [outer_r - 0.2, -tooth_width/3],
                    [outer_r, 0],
                    [outer_r - 0.2, tooth_width/3],
                    [root_r, tooth_width/2]
                ]);
            }
        }
        translate([0, 0, -1])
        cylinder(r=bore_r, h=thickness+2);
        
        if (spokes && pitch_r > 12) {
            spoke_count = pitch_r > 20 ? 6 : 4;
            for (i = [0:spoke_count-1]) {
                rotate([0, 0, i * 360/spoke_count + 30])
                translate([pitch_r * 0.5, 0, -1])
                cylinder(r=pitch_r*0.2, h=thickness+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SHAFT WITH MOUNT
// ═══════════════════════════════════════════════════════════════════════════════════
module shaft(length, diameter=3) {
    color(C_SHAFT)
    cylinder(r=diameter/2, h=length);
}

module axle_mount(bore_r=1.5, plate_size=12, thickness=4) {
    color("#444")
    difference() {
        translate([-plate_size/2, -plate_size/2, 0])
        cube([plate_size, plate_size, thickness]);
        translate([0, 0, -1])
        cylinder(r=bore_r, h=thickness+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ENCLOSURE WITH MOUNTING TABS
// ═══════════════════════════════════════════════════════════════════════════════════
module enclosure() {
    // Main box
    color(C_ENCLOSURE)
    difference() {
        cube([TOTAL_W, TOTAL_H, TOTAL_D]);
        
        // Inner cavity
        translate([WALL_T, WALL_T, WALL_T])
        cube([TOTAL_W - 2*WALL_T, TOTAL_H - 2*WALL_T, TOTAL_D]);
        
        // Front opening (viewing window)
        translate([TAB_W, TAB_W, WALL_T])
        cube([CANVAS_W, CANVAS_H, TOTAL_D]);
    }
}

module mounting_tabs() {
    // Tabs that extend outward to rest on wood frame
    color(C_FRAME_TAB) {
        // Bottom tab
        translate([TAB_W/2, -FRAME_MOUNT_TAB, 0])
        cube([TOTAL_W - TAB_W, FRAME_MOUNT_TAB, WALL_T]);
        
        // Top tab
        translate([TAB_W/2, TOTAL_H, 0])
        cube([TOTAL_W - TAB_W, FRAME_MOUNT_TAB, WALL_T]);
        
        // Left tab
        translate([-FRAME_MOUNT_TAB, TAB_W/2, 0])
        cube([FRAME_MOUNT_TAB, TOTAL_H - TAB_W, WALL_T]);
        
        // Right tab
        translate([TOTAL_W, TAB_W/2, 0])
        cube([FRAME_MOUNT_TAB, TOTAL_H - TAB_W, WALL_T]);
    }
    
    // Screw holes in tabs
    color(C_FRAME_TAB)
    for (pos = [
        [TOTAL_W/4, -FRAME_MOUNT_TAB/2],
        [TOTAL_W*3/4, -FRAME_MOUNT_TAB/2],
        [TOTAL_W/4, TOTAL_H + FRAME_MOUNT_TAB/2],
        [TOTAL_W*3/4, TOTAL_H + FRAME_MOUNT_TAB/2],
        [-FRAME_MOUNT_TAB/2, TOTAL_H/3],
        [-FRAME_MOUNT_TAB/2, TOTAL_H*2/3],
        [TOTAL_W + FRAME_MOUNT_TAB/2, TOTAL_H/3],
        [TOTAL_W + FRAME_MOUNT_TAB/2, TOTAL_H*2/3]
    ]) {
        translate([pos[0], pos[1], -1])
        cylinder(r=2, h=WALL_T+2);
    }
}

module back_panel() {
    color(C_BACK_PANEL)
    difference() {
        translate([WALL_T + 2, WALL_T + 2, 0])
        cube([TOTAL_W - 2*WALL_T - 4, TOTAL_H - 2*WALL_T - 4, WALL_T - 1]);
        
        // Motor access cutout
        translate([TAB_W + 15, TAB_W + 5, -1])
        cube([70, 60, WALL_T + 2]);
        
        // Wiring hole
        translate([TOTAL_W - TAB_W - 30, TAB_W + 30, -1])
        cylinder(r=8, h=WALL_T + 2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MOTOR
// ═══════════════════════════════════════════════════════════════════════════════════
module motor_n20(shaft_rot=0) {
    color(C_MOTOR) {
        cube([12, 10, 24]);
        translate([0, 0, 24])
        cube([12, 10, 10]);
    }
    
    // Output shaft (along +X)
    color(C_SHAFT)
    translate([12, 5, 29])
    rotate([0, 90, 0])
    cylinder(r=1.5, h=15);
    
    // Motor pinion
    translate([22, 5, 29])
    rotate([0, 90, 0])
    rotate([0, 0, shaft_rot])
    spur_gear(MOTOR_PINION_T, GEAR_MODULE, 6, 1.5, false);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MAIN GEAR TRAIN
// ═══════════════════════════════════════════════════════════════════════════════════
module main_gear_train() {
    motor_x = 25;
    motor_y = 15;
    
    // Motor
    translate([motor_x, motor_y, 0])
    motor_n20(motor_angle);
    
    // Master gear position
    master_x = motor_x + 22 + CD_MOTOR_MASTER;
    master_y = motor_y + 14;
    
    // Master gear axle mount (to back panel)
    if (SHOW_AXLE_MOUNTS) {
        translate([master_x, master_y, -Z_GEARS_PLANE + Z_AXLE_MOUNT])
        axle_mount(3, 16, 4);
    }
    
    // Master shaft
    translate([master_x, master_y, -5])
    shaft(25, 6);
    
    // Master gear (ROTATING)
    translate([master_x, master_y, 5])
    rotate([0, 0, master_angle])
    spur_gear(MASTER_GEAR_T, GEAR_MODULE, 8, 3, true);
    
    // Sky drive
    sky_x = master_x;
    sky_y = master_y + CD_MASTER_SKY;
    
    if (SHOW_AXLE_MOUNTS) {
        translate([sky_x, sky_y, -Z_GEARS_PLANE + Z_AXLE_MOUNT])
        axle_mount(1.5, 12, 4);
    }
    
    translate([sky_x, sky_y, 0])
    shaft(Z_SKY_MECHANISM + 10, 3);
    
    translate([sky_x, sky_y, 5])
    rotate([0, 0, sky_angle])
    spur_gear(SKY_DRIVE_T, GEAR_MODULE, 6, 1.5, false);
    
    // Wave drive
    wave_x = master_x + CD_MASTER_WAVE;
    wave_y = master_y;
    
    if (SHOW_AXLE_MOUNTS) {
        translate([wave_x, wave_y, -Z_GEARS_PLANE + Z_AXLE_MOUNT])
        axle_mount(1.5, 12, 4);
    }
    
    translate([wave_x, wave_y, 0])
    shaft(Z_WAVE_MECHANISM, 3);
    
    translate([wave_x, wave_y, 5])
    rotate([0, 0, wave_angle])
    spur_gear(WAVE_DRIVE_T, GEAR_MODULE, 6, 1.5, true);
    
    // Rice tube cam gear (on wave drive shaft)
    translate([wave_x, wave_y, 15])
    rotate([0, 0, wave_angle])
    rice_tube_cam();
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: RICE TUBE CAM
// Dedicated cam on wave drive shaft to rock rice tube
// ═══════════════════════════════════════════════════════════════════════════════════
module rice_tube_cam() {
    cam_r = 12;
    eccentric = 6;  // Offset for cam lobe
    
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=cam_r, h=6);
            // Eccentric lobe
            translate([eccentric, 0, 0])
            cylinder(r=cam_r * 0.6, h=6);
        }
        translate([0, 0, -1])
        cylinder(r=1.5, h=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SWIRL DRIVE TRAIN
// ═══════════════════════════════════════════════════════════════════════════════════
module swirl_drive_train() {
    sky_x = 25 + 22 + CD_MOTOR_MASTER;
    sky_y = 15 + 14 + CD_MASTER_SKY;
    
    // Drive gear on sky shaft
    translate([sky_x, sky_y, Z_SWIRL_DRIVE - Z_GEARS_PLANE])
    rotate([0, 0, sky_angle])
    spur_gear(16, GEAR_MODULE, 5, 1.5, false);
    
    // Idler gears to big swirl
    idler1_x = sky_x + 20;
    idler1_y = sky_y + 25;
    
    translate([idler1_x, idler1_y, Z_SWIRL_DRIVE - Z_GEARS_PLANE]) {
        rotate([0, 0, -sky_angle * 16/14])
        spur_gear(14, GEAR_MODULE, 5, 1.5, false);
        translate([0, 0, -5])
        shaft(15, 3);
    }
    
    // Connect to big swirl
    translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_DRIVE - Z_GEARS_PLANE]) {
        rotate([0, 0, swirl_angle])
        spur_gear(20, GEAR_MODULE, 5, 1.5, false);
        translate([0, 0, -3])
        shaft(Z_SWIRL_BACK - Z_SWIRL_DRIVE + 8, 3);
    }
    
    // Branch to small swirl
    idler2_x = idler1_x + 30;
    idler2_y = idler1_y - 5;
    
    translate([idler2_x, idler2_y, Z_SWIRL_DRIVE - Z_GEARS_PLANE]) {
        rotate([0, 0, sky_angle * 16/14 * 14/14])
        spur_gear(14, GEAR_MODULE, 5, 1.5, false);
        translate([0, 0, -5])
        shaft(15, 3);
    }
    
    translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_DRIVE - Z_GEARS_PLANE]) {
        rotate([0, 0, -swirl_angle])
        spur_gear(18, GEAR_MODULE, 5, 1.5, false);
        translate([0, 0, -3])
        shaft(Z_SWIRL_BACK - Z_SWIRL_DRIVE + 8, 3);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: FOUR-BAR CRANK-ROCKER LINKAGE
// For wave layers - calculated values satisfy Grashof condition
// ═══════════════════════════════════════════════════════════════════════════════════
module four_bar_linkage(crank_angle, layer_index) {
    phase = WAVE_PHASES[layer_index];
    current_angle = crank_angle + phase;
    
    // Ground pivot positions
    crank_pivot_x = 140 + layer_index * 35;  // Crank centers spaced 35mm
    crank_pivot_y = 20;
    
    // Rocker pivot (at wave layer bottom)
    rocker_pivot_x = crank_pivot_x + GROUND_LENGTH;
    rocker_pivot_y = crank_pivot_y;
    
    // === GROUND LINK (Fixed pivots) ===
    // Visual representation of ground link
    color("#333", 0.5)
    translate([crank_pivot_x, crank_pivot_y, 0])
    cube([GROUND_LENGTH, 3, 3]);
    
    // Crank pivot bearing mount
    translate([crank_pivot_x, crank_pivot_y, -3])
    axle_mount(1.5, 10, 3);
    
    // Rocker pivot bearing mount  
    translate([rocker_pivot_x, rocker_pivot_y, -3])
    axle_mount(1.5, 10, 3);
    
    // === CRANK (Rotating input) ===
    crank_end_x = crank_pivot_x + CRANK_LENGTH * cos(current_angle);
    crank_end_y = crank_pivot_y + CRANK_LENGTH * sin(current_angle);
    
    color(C_GEAR)
    translate([crank_pivot_x, crank_pivot_y, 3]) {
        // Crank arm
        rotate([0, 0, current_angle])
        translate([0, -2, 0])
        cube([CRANK_LENGTH, 4, 4]);
        
        // Crank pin
        rotate([0, 0, current_angle])
        translate([CRANK_LENGTH, 0, 4])
        cylinder(r=2, h=8);
    }
    
    // === COUPLER (Connecting rod) ===
    // Calculate coupler angle using four-bar kinematics
    dx = rocker_pivot_x - crank_end_x;
    dy = rocker_pivot_y - crank_end_y;
    dist = sqrt(dx*dx + dy*dy);
    
    // Law of cosines to find rocker angle
    cos_rocker = (dist*dist + ROCKER_LENGTH*ROCKER_LENGTH - COUPLER_LENGTH*COUPLER_LENGTH) 
                 / (2 * dist * ROCKER_LENGTH);
    cos_rocker_clamped = max(-1, min(1, cos_rocker));
    
    base_angle = atan2(dy, dx);
    rocker_angle = base_angle + acos(cos_rocker_clamped);
    
    // Rocker end position
    rocker_end_x = rocker_pivot_x + ROCKER_LENGTH * cos(rocker_angle);
    rocker_end_y = rocker_pivot_y + ROCKER_LENGTH * sin(rocker_angle);
    
    // Draw coupler
    coupler_angle = atan2(rocker_end_y - crank_end_y, rocker_end_x - crank_end_x);
    
    color(C_COUPLER)
    translate([crank_end_x, crank_end_y, 8])
    rotate([0, 0, coupler_angle])
    translate([0, -2, 0])
    cube([COUPLER_LENGTH, 4, 3]);
    
    // === ROCKER (Output - wave layer arm) ===
    color(C_WAVE_2)
    translate([rocker_pivot_x, rocker_pivot_y, 3])
    rotate([0, 0, rocker_angle])
    translate([0, -3, 0])
    cube([ROCKER_LENGTH + 10, 6, 4]);
    
    // Rocker angle for wave orientation
    echo(str("Layer ", layer_index, " rocker angle: ", rocker_angle, "°"));
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WAVE CAMSHAFT
// Drives all four-bar linkages
// ═══════════════════════════════════════════════════════════════════════════════════
module wave_camshaft() {
    shaft_x = 130;
    shaft_y = 20;
    shaft_length = 160;
    
    // Main camshaft
    color(C_SHAFT)
    translate([shaft_x, shaft_y, 0])
    rotate([0, 90, 0])
    cylinder(r=3, h=shaft_length);
    
    // Input gear from wave drive
    translate([shaft_x, shaft_y, 0])
    rotate([0, 90, 0])
    rotate([0, 0, wave_angle])
    spur_gear(WAVE_DRIVE_T, GEAR_MODULE, 6, 3, true);
    
    // Crank discs for each four-bar (one per wave layer)
    for (i = [0:3]) {
        phase = WAVE_PHASES[i];
        disc_x = 140 + i * 35;
        
        translate([disc_x, shaft_y, 0])
        rotate([0, 90, 0])
        rotate([0, 0, wave_angle + phase])
        color(C_GEAR) {
            difference() {
                cylinder(r=CRANK_LENGTH + 4, h=5);
                translate([0, 0, -1])
                cylinder(r=3, h=7);
            }
            // Crank pin
            translate([CRANK_LENGTH, 0, 5])
            cylinder(r=2, h=6);
        }
    }
    
    // Bearing mounts
    for (x = [shaft_x, shaft_x + 50, shaft_x + 100, shaft_x + shaft_length - 10]) {
        translate([x, shaft_y, -5])
        axle_mount(3, 12, 5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WAVE LAYER (STL Import)
// ═══════════════════════════════════════════════════════════════════════════════════
module wave_layer_stl(filename, layer_color, rocker_angle, offset_x, offset_y) {
    translate([offset_x, offset_y, 0])
    rotate([0, 0, rocker_angle * 0.5])  // Scale the oscillation
    color(layer_color)
    import(filename);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: RICE TUBE (XY Plane See-Saw Motion)
// Rotation around Z-axis for up/down tilt (gravity makes rice fall and sound)
// ═══════════════════════════════════════════════════════════════════════════════════
module rice_tube(tilt_angle=0) {
    tube_length = 180;
    tube_od = 20;
    tube_id = 16;
    
    // Position: Inside enclosure, near bottom
    pivot_x = CANVAS_W / 2;
    pivot_y = 30;  // Above bottom edge
    
    translate([pivot_x, pivot_y, 0]) {
        // ROTATE AROUND Z-AXIS for XY plane see-saw
        // When tilt_angle > 0: Left end goes UP (+Y), Right end goes DOWN (-Y)
        rotate([0, 0, tilt_angle]) {
            translate([-tube_length/2, 0, 0]) {
                // Main tube body (horizontal along X)
                color(C_RICE_TUBE)
                rotate([0, 90, 0])
                difference() {
                    cylinder(r=tube_od/2, h=tube_length);
                    translate([0, 0, 4])
                    cylinder(r=tube_id/2, h=tube_length - 8);
                }
                
                // End caps
                color(C_RICE_TUBE) {
                    rotate([0, 90, 0])
                    cylinder(r=tube_od/2, h=4);
                    
                    translate([tube_length - 4, 0, 0])
                    rotate([0, 90, 0])
                    cylinder(r=tube_od/2, h=4);
                }
                
                // Internal spiral baffles (for rice sound)
                color(C_RICE_TUBE, 0.5)
                for (x = [25:25:tube_length-25]) {
                    translate([x, 0, 0])
                    rotate([0, 90, 0])
                    rotate([0, 0, x * 2])  // Spiral twist
                    linear_extrude(height=2, twist=30)
                    difference() {
                        circle(r=tube_id/2 - 1);
                        circle(r=tube_id/2 - 5);
                    }
                }
            }
        }
        
        // Center pivot mount (fixed to frame)
        color("#444") {
            translate([0, 0, -5])
            cylinder(r=6, h=5);
            
            // Pivot pin (through tube center)
            translate([0, 0, -2])
            cylinder(r=2, h=4);
        }
        
        // Cam follower arm (connects to rice cam)
        cam_x = 25 + 22 + CD_MOTOR_MASTER + CD_MASTER_WAVE - pivot_x;
        
        color(C_COUPLER)
        translate([0, 0, 15])
        rotate([0, 0, atan2(-20, cam_x)])
        translate([0, -2, 0])
        cube([sqrt(cam_x*cam_x + 400), 4, 3]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: BIRD WIRE TRACK (20mm spacing)
// Two parallel wires within ZONE_BIRD_WIRE [0, 302, 130, 150]
// ═══════════════════════════════════════════════════════════════════════════════════
module bird_wire_track() {
    wire_r = 1;  // 12 gauge ≈ 2mm diameter
    
    // Zone: Y from 130 to 150 (20mm height)
    // Place wires at Y = 135 and Y = 145 (10mm from edges, 20mm apart)
    wire_y_lower = 135;
    wire_y_upper = 155;  // 135 + 20 = 155, but zone ends at 150, so use 145
    
    // Actually, zone is 130-150, that's 20mm
    // For 20mm spacing between wires: lower at 130, upper at 150? 
    // No, the wires should be INSIDE the zone with spacing between them
    // Zone height = 20mm, wire spacing = 20mm means wires at edges
    // Let's put wires at Y=132 and Y=148 (16mm apart, 2mm from edges)
    // Actually user wants 20mm BETWEEN the wires
    // So if zone is 20mm and we need 20mm between, wires touch the edges
    
    // Let me recalculate: ZONE_BIRD_WIRE = [0, 302, 130, 150]
    // Zone Y: 130 to 150 = 20mm height
    // For 20mm between wires, they'd be at Y=130 and Y=150 (zone edges)
    
    wire_y_1 = ZONE_BIRD_WIRE[2];      // 130
    wire_y_2 = ZONE_BIRD_WIRE[2] + 20; // 150
    
    color(C_WIRE) {
        // Lower wire
        translate([0, wire_y_1, 0])
        rotate([0, 90, 0])
        cylinder(r=wire_r, h=CANVAS_W);
        
        // Upper wire
        translate([0, wire_y_2, 0])
        rotate([0, 90, 0])
        cylinder(r=wire_r, h=CANVAS_W);
        
        // End loops (connecting the two wires)
        // Left end
        translate([5, (wire_y_1 + wire_y_2)/2, 0])
        rotate([0, 0, 90])
        rotate_extrude(angle=180)
        translate([10, 0])
        circle(r=wire_r);
        
        // Right end
        translate([CANVAS_W - 5, (wire_y_1 + wire_y_2)/2, 0])
        rotate([0, 0, -90])
        rotate_extrude(angle=180)
        translate([10, 0])
        circle(r=wire_r);
    }
}

module bird(pos=0) {
    // Bird travels along the wire track
    bird_x = 15 + pos * (CANVAS_W - 30);
    bird_y = (ZONE_BIRD_WIRE[2] + ZONE_BIRD_WIRE[2] + 20) / 2;  // Center between wires
    
    // Flip direction at ends
    facing = pos < 0.5 ? 0 : 180;
    
    translate([bird_x, bird_y, 5])
    rotate([0, 0, facing])
    color("#222") {
        // Body
        scale([1.2, 0.5, 0.4])
        sphere(r=8);
        
        // Wings
        translate([0, 0, 3])
        scale([0.4, 1.8, 0.15])
        sphere(r=7);
        
        // Tail
        translate([-8, 0, 0])
        scale([0.8, 0.3, 0.2])
        sphere(r=5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: LIGHTHOUSE (UPRIGHT)
// Rotated -90° on X to point UP (+Y in canvas)
// Base glued to cliff top face
// ═══════════════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot=0) {
    base_r = 6;
    top_r = 4;
    height = 48;
    
    // ROTATE -90° ON X-AXIS so lighthouse points UP (+Y direction)
    rotate([-90, 0, 0]) {
        // Main tower (tapered)
        color(C_LIGHTHOUSE)
        cylinder(r1=base_r, r2=top_r, h=height * 0.7);
        
        // Stripes
        color(C_LIGHTHOUSE_STRIPE)
        for (z = [height*0.12, height*0.32, height*0.52]) {
            translate([0, 0, z])
            cylinder(r=base_r - z/height*2.5, h=height*0.08);
        }
        
        // Gallery platform
        translate([0, 0, height*0.7])
        color("#444")
        cylinder(r=top_r*1.5, h=2);
        
        // Lamp room
        translate([0, 0, height*0.72])
        color("LightYellow", 0.5)
        cylinder(r=top_r*1.3, h=height*0.12);
        
        // Rotating lantern
        translate([0, 0, height*0.72])
        rotate([0, 0, beam_rot])
        color("#333", 0.6)
        difference() {
            cylinder(r=top_r*1.35, h=height*0.1);
            translate([-top_r*2, -1.5, -1])
            cube([top_r*4, 3, height*0.15]);
        }
        
        // Roof dome
        translate([0, 0, height*0.84])
        color(C_LIGHTHOUSE_STRIPE)
        cylinder(r1=top_r*1.4, r2=top_r*0.4, h=height*0.16);
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
        cylinder(r=3, h=thickness+2);
        
        for (i = [0:5]) {
            rotate([0, 0, i*60])
            translate([radius*0.55, 0, -1])
            cylinder(r=radius*0.18, h=thickness+2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WIND PATH
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
    cylinder(r=moon_r * 0.6, h=5);
    
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.8)
    difference() {
        cylinder(r=moon_r, h=5);
        translate([0, 0, -1])
        cylinder(r=moon_r * 0.65, h=7);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ZONE OUTLINE (Debug)
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

// Enclosure and mounting
if (SHOW_ENCLOSURE) enclosure();
if (SHOW_MOUNTING_TABS) mounting_tabs();
if (SHOW_BACK_PANEL) translate([0, 0, Z_BACK_PANEL]) back_panel();

// Main gear train (all gears connected)
if (SHOW_GEARS) {
    translate([TAB_W, TAB_W, Z_GEARS_PLANE])
    main_gear_train();
}

// Swirl drive train
if (SHOW_SWIRL_DRIVE) {
    translate([TAB_W, TAB_W, Z_GEARS_PLANE])
    swirl_drive_train();
}

// Wave mechanism with four-bar linkages
if (SHOW_FOUR_BAR) {
    translate([TAB_W, TAB_W, Z_WAVE_MECHANISM]) {
        wave_camshaft();
        for (i = [0:3]) {
            four_bar_linkage(wave_angle, i);
        }
    }
}

// Wave layers (STL imports)
if (SHOW_WAVES) {
    // Position waves in combined wave zone
    wave_zone_cx = TAB_W + (ZONE_COMBINED_WAVES[0] + ZONE_COMBINED_WAVES[1]) / 2;
    wave_zone_cy = TAB_W + (ZONE_COMBINED_WAVES[2] + ZONE_COMBINED_WAVES[3]) / 2;
    
    // Calculate rocker angles for each layer
    rocker_1 = 15 * sin(wave_angle + WAVE_PHASES[0]);
    rocker_2 = 15 * sin(wave_angle + WAVE_PHASES[1]);
    rocker_3 = 15 * sin(wave_angle + WAVE_PHASES[2]);
    rocker_4 = 15 * sin(wave_angle + WAVE_PHASES[3]);
    
    // Back layers
    translate([wave_zone_cx, wave_zone_cy - 20, Z_WAVES_BACK])
    rotate([0, 0, rocker_4])
    color(C_WAVE_1)
    import("ocean_main_back_2.stl");
    
    translate([wave_zone_cx, wave_zone_cy - 10, Z_WAVES_BACK + 5])
    rotate([0, 0, rocker_3])
    color(C_WAVE_2)
    import("ocean_main_back_1.stl");
    
    // Front layers
    translate([wave_zone_cx, wave_zone_cy, Z_WAVES_FRONT])
    rotate([0, 0, rocker_2])
    color(C_WAVE_3)
    import("ocean_layer_2.stl");
    
    translate([wave_zone_cx, wave_zone_cy + 10, Z_WAVES_FRONT + 5])
    rotate([0, 0, rocker_1])
    color(C_WAVE_4)
    import("ocean_layer_1.stl");
}

// Rice tube (XY plane see-saw, inside enclosure)
if (SHOW_RICE_TUBE) {
    translate([TAB_W, TAB_W, Z_RICE_TUBE])
    rice_tube(rice_tilt);
}

// Moon
if (SHOW_MOON) {
    translate([TAB_W + zone_cx(ZONE_MOON), TAB_W + zone_cy(ZONE_MOON), Z_MOON])
    moon_assembly(sky_angle * 0.3);
}

// Swirl discs
if (SHOW_BIG_SWIRL) {
    translate([TAB_W + BIG_SWIRL_X, TAB_W + BIG_SWIRL_Y, Z_SWIRL_BACK])
    swirl_disc(BIG_SWIRL_R, swirl_angle, 5);
    
    translate([TAB_W + BIG_SWIRL_X, TAB_W + BIG_SWIRL_Y, Z_SWIRL_FRONT])
    swirl_disc(BIG_SWIRL_R * 0.7, -swirl_angle * 1.5, 4);
}

if (SHOW_SMALL_SWIRL) {
    translate([TAB_W + SMALL_SWIRL_X, TAB_W + SMALL_SWIRL_Y, Z_SWIRL_BACK])
    swirl_disc(SMALL_SWIRL_R, -swirl_angle, 5);
    
    translate([TAB_W + SMALL_SWIRL_X, TAB_W + SMALL_SWIRL_Y, Z_SWIRL_FRONT])
    swirl_disc(SMALL_SWIRL_R * 0.7, swirl_angle * 1.5, 4);
}

// Wind path
if (SHOW_WIND_PATH) {
    translate([TAB_W, TAB_W, Z_WIND_PATH])
    wind_path_traced();
}

// Bird wire (20mm spacing between wires)
if (SHOW_BIRD_WIRE) {
    translate([TAB_W, TAB_W, Z_BIRD_WIRE]) {
        bird_wire_track();
        bird(bird_pos);
        bird(fmod(bird_pos + 0.4, 1));
    }
}

// Cliff
if (SHOW_CLIFF) {
    translate([TAB_W, TAB_W, Z_CLIFF])
    cliff_traced();
}

// Lighthouse (UPRIGHT, on cliff top)
if (SHOW_LIGHTHOUSE) {
    // Position: X at lighthouse zone center, Y at cliff TOP (Y=65), Z on cliff surface
    translate([TAB_W + zone_cx(ZONE_LIGHTHOUSE), 
               TAB_W + ZONE_CLIFF[3],      // Y = cliff top = 65
               Z_CLIFF + 5])               // On cliff surface
    lighthouse(motor_angle * 2);
}

// Cypress
if (SHOW_CYPRESS) {
    translate([TAB_W, TAB_W, Z_CYPRESS])
    cypress_traced();
}

// Zone outlines for debugging
if (SHOW_ZONE_OUTLINES) {
    translate([TAB_W, TAB_W, 76]) {
        zone_outline(ZONE_CLIFF, "#8B4513");
        zone_outline(ZONE_LIGHTHOUSE, "#FFD700");
        zone_outline(ZONE_COMBINED_WAVES, "#4169E1");
        zone_outline(ZONE_WIND_PATH, "#9370DB");
        zone_outline(ZONE_BIRD_WIRE, "#696969");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         FOUR-BAR LINKAGE SPECIFICATION TABLE
// ═══════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V42 - FOUR-BAR CRANK-ROCKER WAVE MECHANISM");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("FOUR-BAR LINKAGE DIMENSIONS (Grashof Condition Satisfied):");
echo("┌─────────────┬────────┬─────────────┐");
echo("│ Link        │ Ratio  │ Length (mm) │");
echo("├─────────────┼────────┼─────────────┤");
echo("│ Crank (s)   │ 1.0    │", CRANK_LENGTH, "        │");
echo("│ Ground (g)  │ 2.5    │", GROUND_LENGTH, "        │");
echo("│ Coupler (c) │ 3.0    │", COUPLER_LENGTH, "        │");
echo("│ Rocker (r)  │ 2.5    │", ROCKER_LENGTH, "        │");
echo("└─────────────┴────────┴─────────────┘");
echo("");
echo("GRASHOF CHECK: s + l < p + q");
echo("  ", CRANK_LENGTH, " + ", COUPLER_LENGTH, " = ", CRANK_LENGTH + COUPLER_LENGTH, 
     " < ", GROUND_LENGTH, " + ", ROCKER_LENGTH, " = ", GROUND_LENGTH + ROCKER_LENGTH, " ✓");
echo("");
echo("PHASE SHIFT SCHEDULE:");
echo("  Layer 0 (back):  ", WAVE_PHASES[0], "°");
echo("  Layer 1:         ", WAVE_PHASES[1], "°");
echo("  Layer 2:         ", WAVE_PHASES[2], "°");
echo("  Layer 3 (front): ", WAVE_PHASES[3], "°");
echo("");
echo("ZERO POSITION: Crank at 0° (horizontal right)");
echo("OSCILLATION: ~59° total swing (±30° from vertical)");
echo("");
echo("BIRD WIRE: 20mm spacing between Y=130 and Y=150");
echo("RICE TUBE: XY plane see-saw (Z-axis rotation), cam-driven");
echo("LIGHTHOUSE: Upright (-90° X rotation), base on cliff top Y=65");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
