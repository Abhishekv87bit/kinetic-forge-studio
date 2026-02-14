// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V38 - COMPLETE MECHANICAL KINETIC ART
// ═══════════════════════════════════════════════════════════════════════════════
// Canvas: 302 × 202 mm art area (350 × 250 mm total with tabs)
// Depth: 78mm (target 80mm max)
// Drive: Single N20 motor, gear train to all mechanisms
// ═══════════════════════════════════════════════════════════════════════════════
$fn = 64;

// COMPONENT INCLUDES (wrapper files for traced shapes)
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>
use <cliffs_wrapper.scad>

// ═══════════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════════
CANVAS_W = 302;
CANVAS_H = 202;
TOTAL_W = 350;
TOTAL_H = 250;
TAB_WIDTH = 24;
TOTAL_DEPTH = 78;

// ═══════════════════════════════════════════════════════════════════════════════
// LOCKED ZONE DEFINITIONS
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// ═══════════════════════════════════════════════════════════════════════════════
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
ZONE_BIRD_WIRE    = [0, 302, 130, 150];
ZONE_RICE_TUBE    = [50, 250, -24, 0];

// Helper functions
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];

// ═══════════════════════════════════════════════════════════════════════════════
// Z-LAYER DEFINITIONS (Back to Front)
// ═══════════════════════════════════════════════════════════════════════════════
Z_BACK_PLATE = 0;
Z_MOTOR = 4;
Z_DRIVE_SHAFT = 5;
Z_VERTICAL_SHAFT = 8;

// Sky mechanism
Z_MOON_HALO_BACK = 11;
Z_MOON_HALO_FRONT = 13;
Z_MOON_CORE = 15;
Z_STARS = 18;
Z_SWIRL_HALO_BACK = 21;
Z_SWIRL_HALO_FRONT = 23;
Z_SWIRL_MAIN = 25;
Z_WIND_PATH = 28;
Z_SKY_GEARS = 31;
Z_SKY_CONNECTIONS = 34;

// Bird mechanism
Z_BIRD_WIRE = 38;
Z_BIRD_CARRIAGE = 43;

// Ground elements
Z_CLIFF = 48;
Z_LIGHTHOUSE = 53;

// Wave mechanism
Z_OCEAN_WAVES = 57;
Z_BOTTOM_GEARS = 57;
Z_WAVE_COUPLERS = 61;

// Cliff waves
Z_CLIFF_WAVES = 64;
Z_FOAM_CURLS = 68;
Z_CAM_RAIL = 70;

// Frontmost
Z_CYPRESS = 73;

// Behind (negative Z)
Z_RICE_TUBE = -15;

// ═══════════════════════════════════════════════════════════════════════════════
// MECHANICAL CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

// Motor specifications (N20 gear motor)
MOTOR_RPM = 60;
MOTOR_SHAFT_D = 3;
MOTOR_BODY_L = 25;
MOTOR_BODY_D = 12;

// Shaft specifications
SHAFT_D = 3;                    // 3mm brass rod
BEARING_ID = 3;                 // 683ZZ inner diameter
BEARING_OD = 7;                 // 683ZZ outer diameter
BEARING_H = 3;                  // 683ZZ thickness

// Gear module (tooth size)
GEAR_MODULE = 1.0;              // 1mm module for compact gears

// Master gear train (from motor)
MOTOR_PINION_T = 10;            // Motor pinion teeth
MASTER_GEAR_T = 60;             // Master gear teeth (6:1 reduction)
SKY_DRIVE_T = 20;               // Sky mechanism drive (3:1 from master)
WAVE_DRIVE_T = 30;              // Wave mechanism drive (2:1 from master)
BIRD_DRIVE_T = 15;              // Bird mechanism drive (4:1 from master)

// Gear radii (module × teeth / 2)
MOTOR_PINION_R = MOTOR_PINION_T * GEAR_MODULE / 2;
MASTER_GEAR_R = MASTER_GEAR_T * GEAR_MODULE / 2;
SKY_DRIVE_R = SKY_DRIVE_T * GEAR_MODULE / 2;
WAVE_DRIVE_R = WAVE_DRIVE_T * GEAR_MODULE / 2;
BIRD_DRIVE_R = BIRD_DRIVE_T * GEAR_MODULE / 2;

// Swirl gear train
SWIRL_DRIVE_T = 12;             // Input to swirl
SWIRL_MAIN_T = 36;              // Main swirl gear (3:1)
SWIRL_IDLER_T = 20;             // Idler for counter-rotation
SWIRL_HALO_T = 36;              // Halo gear (same as main, opposite direction)

// Moon gear train
MOON_DRIVE_T = 14;
MOON_CORE_T = 42;
MOON_IDLER_T = 18;
MOON_HALO_T = 40;

// Camshaft specifications
CAMSHAFT_D = 3;                 // 3mm shaft
CAM_LOBE_OFFSET = 5;            // 5mm cam lobe offset from center
CAM_LOBE_D = 8;                 // Cam lobe diameter
CLIFF_WAVE_COUNT = 5;
OCEAN_WAVE_COUNT = 6;
TOTAL_CAM_LOBES = CLIFF_WAVE_COUNT + OCEAN_WAVE_COUNT;  // 11 lobes
CAM_PHASE_SHIFT = 30;           // 30° between adjacent cams

// Four-bar linkage dimensions
FULCRUM_OFFSET = 15;            // Distance from wave edge to fulcrum
COUPLER_LENGTH = 45;            // Coupler rod length
COUPLER_D = 2;                  // Coupler rod diameter (SS)
WAVE_LENGTH = 100;              // Approximate wave layer length
WAVE_AMPLITUDE = 12;            // Wave tip vertical motion

// Crank wheel (visible)
CRANK_WHEEL_R = 12;             // 24mm diameter
CRANK_WHEEL_T = 4;              // Thickness
CRANK_PIN_OFFSET = 5;           // Pin offset from center

// Bird mechanism
BIRD_WIRE_GAUGE = 2.0;          // 12 gauge = 2.0mm
BIRD_SPACING = 30;              // 30mm between birds
BIRD_PULLEY_R = 8;              // Pulley radius at ends

// Rice tube
RICE_TUBE_LENGTH = 200;
RICE_TUBE_OD = 20;
RICE_TUBE_ID = 16;
RICE_TUBE_ROCK_ANGLE = 15;      // ±15° rocking

// ═══════════════════════════════════════════════════════════════════════════════
// DERIVED POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════

// Motor position (inside cliff)
MOTOR_X = 35;
MOTOR_Y = 30;

// Master gear position
MASTER_GEAR_X = MOTOR_X + MOTOR_PINION_R + MASTER_GEAR_R;
MASTER_GEAR_Y = MOTOR_Y;

// Sky mechanism centers
BIG_SWIRL_X = zone_center_x(ZONE_BIG_SWIRL);      // 123
BIG_SWIRL_Y = zone_center_y(ZONE_BIG_SWIRL);      // 140
BIG_SWIRL_R = min(zone_width(ZONE_BIG_SWIRL), zone_height(ZONE_BIG_SWIRL)) / 2 - 2;  // 28

SMALL_SWIRL_X = zone_center_x(ZONE_SMALL_SWIRL);  // 174.5
SMALL_SWIRL_Y = zone_center_y(ZONE_SMALL_SWIRL);  // 129.5
SMALL_SWIRL_R = min(zone_width(ZONE_SMALL_SWIRL), zone_height(ZONE_SMALL_SWIRL)) / 2 - 2;  // 21.5

MOON_X = zone_center_x(ZONE_MOON);                // 265.5
MOON_Y = zone_center_y(ZONE_MOON);                // 171.5
MOON_R = min(zone_width(ZONE_MOON), zone_height(ZONE_MOON)) / 2 - 1;  // 29.5

// Camshaft position
CAMSHAFT_Y = 12;                // Low, behind waves
CAMSHAFT_X_START = 115;         // Start of camshaft (cliff waves)
CAMSHAFT_X_END = 280;           // End of camshaft (crank wheel)

// Wave fulcrum positions (cliff side for cliff waves, left side for ocean waves)
CLIFF_WAVE_FULCRUM_X = ZONE_CLIFF_WAVES[0] + FULCRUM_OFFSET;
OCEAN_WAVE_FULCRUM_X = ZONE_OCEAN_WAVES[0] + FULCRUM_OFFSET;

// Bird wire
BIRD_WIRE_Y = zone_center_y(ZONE_BIRD_WIRE);      // 140

// Rice tube
RICE_TUBE_X = zone_center_x(ZONE_RICE_TUBE);      // 150
RICE_TUBE_Y = -12;                                 // Behind bottom tab

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════
t = $t;                         // 0 to 1 animation parameter
master_angle = t * 360;         // Master rotation (one full cycle)

// Motor to master gear reduction (6:1)
motor_angle = master_angle * 6;

// Sky mechanism (18:1 total from motor - slow, mesmerizing)
sky_angle = master_angle / 3;
swirl_big_angle = sky_angle;
swirl_big_halo_angle = -sky_angle * 0.8;          // Counter-rotation, slightly slower
swirl_small_angle = -sky_angle * 1.2;             // Opposite direction
swirl_small_halo_angle = sky_angle * 0.9;

moon_angle = sky_angle * 0.7;
moon_halo_back_angle = -sky_angle * 0.5;
moon_halo_front_angle = sky_angle * 0.6;

star_angle = sky_angle * 0.4;
star_halo_angle = -sky_angle * 0.3;

// Wave mechanism (12:1 total from motor - gentle undulation)
wave_angle = master_angle / 2;
camshaft_angle = wave_angle;

// Individual wave phases (30° offset each)
function wave_phase(index) = camshaft_angle + index * CAM_PHASE_SHIFT;
function wave_height(index) = CAM_LOBE_OFFSET * sin(wave_phase(index));

// Foam curl activation (based on wave height and cam rail)
function foam_curl_angle(index) = max(0, wave_height(index) - 2) * 8;  // Curls when wave is high

// Bird mechanism (24:1 total from motor - very slow traverse)
bird_angle = master_angle / 4;
bird_progress = (bird_angle % 360) / 360;         // 0 to 1 progress along track
bird_rotation = bird_progress < 0.1 ? bird_progress * 1800 :
                bird_progress > 0.9 ? (1 - bird_progress) * 1800 + 180 :
                bird_progress < 0.5 ? 180 : 0;    // Rotates at ends

// Rice tube rocking (synchronized with waves)
rice_tube_angle = RICE_TUBE_ROCK_ANGLE * sin(wave_angle);

// Sky gear rotations
sky_gear_1 = sky_angle * 1.2;
sky_gear_2 = -sky_angle * 0.9;
sky_gear_3 = sky_angle * 1.5;
sky_gear_4 = -sky_angle * 0.7;

// Bottom gear rotations
bottom_gear_angle = wave_angle;

// ═══════════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════════
C_SKY = "#1a3a6e";
C_SKY_LIGHT = "#2a5a9e";
C_CLIFF = "#8b7355";
C_CLIFF_DARK = "#6b5344";
C_CLIFF_GRASS = "#5a7a4a";
C_WIND = "#3a6a9e";
C_SWIRL_BLUE = "#2a5a8e";
C_SWIRL_HALO = "#4a4a4a";
C_SWIRL_HALO_DARK = "#3a3a3a";
C_MOON = "#f0d050";
C_MOON_HALO_A = "#e8c840";
C_MOON_HALO_B = "#d0b030";
C_STAR = "#c0a050";
C_STAR_HALO = "#8a7040";
C_WAVE_DARK = "#1a4a6a";
C_WAVE_MED = "#2a6a8a";
C_WAVE_LIGHT = "#4a8aaa";
C_FOAM = "#f0f0e8";
C_CYPRESS = "#1a3a1a";
C_CYPRESS_HIGHLIGHT = "#2a4a2a";
C_GEAR = "#b8a060";
C_GEAR_DARK = "#8a7040";
C_SHAFT = "#c0c0a0";
C_BEARING = "#606060";
C_COUPLER = "#a0a0a0";
C_LIGHTHOUSE = "#d4c4a8";
C_LIGHTHOUSE_STRIPE = "#7a5535";
C_BIRD = "#2a2a2a";
C_WIRE = "#404040";
C_RICE_TUBE = "#c4a060";
C_MOTOR = "#333333";
C_CAM_RAIL = "#505050";

// ═══════════════════════════════════════════════════════════════════════════════
// BASIC MECHANICAL MODULES
// ═══════════════════════════════════════════════════════════════════════════════

// Gear with configurable parameters
module gear(teeth, module_size=GEAR_MODULE, thickness=3, hole_d=SHAFT_D, col=C_GEAR) {
    r = teeth * module_size / 2;
    tooth_h = module_size * 1.2;
    
    color(col)
    difference() {
        union() {
            // Gear body
            cylinder(r=r - tooth_h * 0.3, h=thickness, $fn=max(32, teeth*2));
            // Teeth
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360 / teeth])
                translate([r - tooth_h * 0.2, 0, 0])
                cylinder(r=tooth_h * 0.9, h=thickness, $fn=6);
            }
        }
        // Center hole
        translate([0, 0, -0.5])
        cylinder(d=hole_d, h=thickness + 1, $fn=32);
        // Lightening holes for larger gears
        if (teeth > 24) {
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                translate([r * 0.55, 0, -0.5])
                cylinder(r=r * 0.15, h=thickness + 1, $fn=24);
            }
        }
    }
}

// Bearing mount (683ZZ)
module bearing_683zz() {
    color(C_BEARING)
    difference() {
        cylinder(d=BEARING_OD, h=BEARING_H, $fn=32);
        translate([0, 0, -0.5])
        cylinder(d=BEARING_ID, h=BEARING_H + 1, $fn=32);
    }
}

// Shaft segment
module shaft(length, d=SHAFT_D) {
    color(C_SHAFT)
    cylinder(d=d, h=length, $fn=24);
}

// Bearing mount block
module bearing_mount(height=10) {
    color(C_GEAR_DARK)
    difference() {
        // Block
        translate([-5, -5, 0])
        cube([10, 10, height]);
        // Bearing cavity
        translate([0, 0, height - BEARING_H])
        cylinder(d=BEARING_OD + 0.4, h=BEARING_H + 1, $fn=32);
        // Shaft hole
        translate([0, 0, -0.5])
        cylinder(d=SHAFT_D + 0.5, h=height + 1, $fn=24);
    }
}

// Coupler rod (stainless steel)
module coupler_rod(length, d=COUPLER_D) {
    color(C_COUPLER)
    cylinder(d=d, h=length, $fn=16);
}

// Cam lobe
module cam_lobe(offset=CAM_LOBE_OFFSET, shaft_d=CAMSHAFT_D, thickness=5) {
    color(C_GEAR_DARK)
    hull() {
        cylinder(d=shaft_d + 4, h=thickness, $fn=32);
        translate([offset, 0, 0])
        cylinder(d=CAM_LOBE_D, h=thickness, $fn=32);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOON MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════

module moon_halo_back(rot) {
    r = MOON_R;
    rotate([0, 0, rot])
    color(C_MOON_HALO_A, 0.6)
    difference() {
        cylinder(r=r, h=1.5, $fn=96);
        translate([0, 0, -0.5])
        cylinder(r=r * 0.82, h=2.5, $fn=96);
        // Decorative holes
        for (i = [0:7]) {
            rotate([0, 0, i * 45 + 22.5])
            translate([r * 0.91, 0, -0.5])
            cylinder(r=2.5, h=2.5, $fn=16);
        }
    }
}

module moon_halo_front(rot) {
    r = MOON_R * 0.82;
    rotate([0, 0, rot])
    color(C_MOON_HALO_B, 0.7)
    difference() {
        cylinder(r=r, h=1.5, $fn=96);
        translate([0, 0, -0.5])
        cylinder(r=r * 0.82, h=2.5, $fn=96);
        // Decorative holes
        for (i = [0:5]) {
            rotate([0, 0, i * 60])
            translate([r * 0.91, 0, -0.5])
            cylinder(r=2, h=2.5, $fn=16);
        }
    }
}

module moon_core(rot) {
    r_core = MOON_R * 0.65;
    // Glow base
    color(C_MOON, 0.3)
    cylinder(r=MOON_R * 0.70, h=1, $fn=96);
    // Solid core
    translate([0, 0, 1])
    color(C_MOON)
    cylinder(r=r_core * 0.7, h=2, $fn=96);
    // Rotating rings
    translate([0, 0, 1])
    rotate([0, 0, rot])
    color(C_MOON, 0.85)
    for (r_ring = [r_core * 0.75, r_core * 0.88, r_core]) {
        difference() {
            cylinder(r=r_ring + 1.2, h=1.8, $fn=96);
            translate([0, 0, -0.5])
            cylinder(r=r_ring - 0.8, h=3, $fn=96);
            // Break into arcs
            for (a = [0:3]) {
                rotate([0, 0, a * 90 + 20])
                translate([0, 0, -0.5])
                cube([r_core * 1.5, 2, 3]);
            }
        }
    }
    // Center axle hub
    translate([0, 0, 0])
    color(C_GEAR)
    cylinder(r=3, h=4, $fn=24);
}

module moon_assembly(halo_back_rot, halo_front_rot, core_rot) {
    // Back halo
    translate([0, 0, 0])
    moon_halo_back(halo_back_rot);
    // Front halo
    translate([0, 0, 2])
    moon_halo_front(halo_front_rot);
    // Core
    translate([0, 0, 4])
    moon_core(core_rot);
    // Axle
    translate([0, 0, -5])
    shaft(15);
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAR MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════

module star_body(r, rot) {
    rotate([0, 0, rot])
    color(C_STAR) {
        // Main body
        difference() {
            cylinder(r=r, h=2, $fn=64);
            translate([0, 0, -0.5])
            cylinder(r=r * 0.12, h=3, $fn=24);
            // Decorative holes
            for (i = [0:4]) {
                rotate([0, 0, i * 72])
                translate([r * 0.55, 0, -0.5])
                cylinder(r=r * 0.1, h=3, $fn=16);
            }
        }
        // Points
        for (i = [0:7]) {
            rotate([0, 0, i * 45])
            translate([r * 0.8, 0, 0])
            cylinder(r1=r * 0.15, r2=r * 0.05, h=2, $fn=3);
        }
    }
}

module star_halo(r, rot) {
    rotate([0, 0, rot])
    color(C_STAR_HALO, 0.8)
    difference() {
        cylinder(r=r * 1.5, h=1, $fn=64);
        translate([0, 0, -0.5])
        cylinder(r=r * 1.05, h=2, $fn=64);
        // Decorative holes
        for (i = [0:5]) {
            rotate([0, 0, i * 60 + 30])
            translate([r * 1.28, 0, -0.5])
            cylinder(r=r * 0.12, h=2, $fn=16);
        }
    }
}

module star_gear(r, star_rot, halo_rot) {
    // Halo (behind)
    translate([0, 0, -1.5])
    star_halo(r, halo_rot);
    // Star body
    star_body(r, star_rot);
    // Axle
    translate([0, 0, -5])
    shaft(8);
}

module all_stars() {
    // Stars positioned within ZONE_STARS [0, 198, 101, 202]
    star_positions = [
        [30, 180, 6],
        [55, 160, 5],
        [90, 185, 5],
        [120, 155, 4],
        [150, 175, 5],
        [175, 150, 4]
    ];
    
    for (i = [0:len(star_positions)-1]) {
        pos = star_positions[i];
        translate([pos[0], pos[1], 0])
        star_gear(pos[2], 
                  star_angle * (1 + i * 0.1) * (i % 2 == 0 ? 1 : -1),
                  star_halo_angle * (1 + i * 0.15) * (i % 2 == 0 ? -1 : 1));
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SWIRL MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════

module swirl_halo_back(r, rot) {
    rotate([0, 0, rot])
    color(C_SWIRL_HALO_DARK, 0.85)
    difference() {
        cylinder(r=r * 1.08, h=1.5, $fn=96);
        translate([0, 0, -0.5])
        cylinder(r=r * 0.80, h=2.5, $fn=96);
        // Decorative holes
        for (i = [0:7]) {
            rotate([0, 0, i * 45 + 22.5])
            translate([r * 0.94, 0, -0.5])
            cylinder(r=r * 0.07, h=2.5, $fn=16);
        }
    }
}

module swirl_halo_front(r, rot) {
    rotate([0, 0, rot])
    color(C_SWIRL_HALO, 0.9)
    difference() {
        cylinder(r=r * 0.90, h=1.5, $fn=96);
        translate([0, 0, -0.5])
        cylinder(r=r * 0.08, h=2.5, $fn=24);
        // Radial slots
        for (i = [0:8]) {
            rotate([0, 0, i * 40])
            translate([r * 0.30, -1, -0.5])
            cube([r * 0.50, 2, 2.5]);
        }
    }
}

module swirl_main(r, rot) {
    rotate([0, 0, rot])
    color(C_SWIRL_BLUE, 0.95)
    difference() {
        cylinder(r=r, h=2.5, $fn=96);
        translate([0, 0, -0.5])
        cylinder(r=r * 0.07, h=3.5, $fn=24);
        // Spiral pattern (simplified as holes)
        for (i = [0:2]) {
            rotate([0, 0, i * 120])
            translate([r * 0.5, 0, -0.5])
            cylinder(r=r * 0.12, h=3.5, $fn=24);
        }
        // Outer ring groove
        translate([0, 0, 1.5])
        difference() {
            cylinder(r=r * 0.95, h=1.5, $fn=96);
            cylinder(r=r * 0.80, h=2, $fn=96);
        }
    }
    // Hub
    translate([0, 0, 2])
    color(C_GEAR)
    cylinder(r=r * 0.12, h=1.5, $fn=24);
}

module swirl_assembly(r, main_rot, halo_back_rot, halo_front_rot) {
    // Back halo
    translate([0, 0, 0])
    swirl_halo_back(r, halo_back_rot);
    // Front halo
    translate([0, 0, 2])
    swirl_halo_front(r, halo_front_rot);
    // Main disc
    translate([0, 0, 4])
    swirl_main(r, main_rot);
    // Drive gear (on same shaft)
    translate([0, 0, 7])
    gear(SWIRL_MAIN_T, thickness=2, col=C_GEAR_DARK);
    // Axle
    translate([0, 0, -5])
    shaft(20);
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIND PATH
// ═══════════════════════════════════════════════════════════════════════════════

module wind_path_panel() {
    // Wind path zone: [0, 198, 105, 202] = 198 × 97
    w = zone_width(ZONE_WIND_PATH);
    h = zone_height(ZONE_WIND_PATH);
    
    // Organic wind shape with cutouts for swirls
    color(C_WIND)
    linear_extrude(height=3)
    difference() {
        // Main wind shape
        polygon([
            [0, 0],
            [w * 0.10, h * 0.25],
            [w * 0.25, h * 0.40],
            [w * 0.40, h * 0.30],
            [w * 0.55, h * 0.45],
            [w * 0.70, h * 0.35],
            [w * 0.85, h * 0.50],
            [w, h * 0.60],
            [w, h],
            [w * 0.90, h * 0.92],
            [w * 0.75, h * 0.80],
            [w * 0.60, h * 0.90],
            [w * 0.45, h * 0.78],
            [w * 0.30, h * 0.88],
            [w * 0.15, h * 0.75],
            [0, h * 0.95],
            [0, 0]
        ]);
        
        // Big swirl cutout (relative to wind path origin)
        big_cut_x = BIG_SWIRL_X - ZONE_WIND_PATH[0];
        big_cut_y = BIG_SWIRL_Y - ZONE_WIND_PATH[2];
        translate([big_cut_x, big_cut_y])
        circle(r=BIG_SWIRL_R + 3, $fn=96);
        
        // Small swirl cutout
        small_cut_x = SMALL_SWIRL_X - ZONE_WIND_PATH[0];
        small_cut_y = SMALL_SWIRL_Y - ZONE_WIND_PATH[2];
        translate([small_cut_x, small_cut_y])
        circle(r=SMALL_SWIRL_R + 3, $fn=96);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKY GEARS (Functional and Decorative)
// ═══════════════════════════════════════════════════════════════════════════════

module sky_gears_assembly() {
    // Sky gears zone: [52, 216, 109, 166] = 164 × 57
    sg_x = ZONE_SKY_GEARS[0];
    sg_y = ZONE_SKY_GEARS[2];
    sg_w = zone_width(ZONE_SKY_GEARS);
    sg_h = zone_height(ZONE_SKY_GEARS);
    
    // Gear positions and sizes within zone
    gears = [
        [sg_x + sg_w * 0.08, sg_y + sg_h * 0.75, 16, sky_gear_1],
        [sg_x + sg_w * 0.22, sg_y + sg_h * 0.40, 14, sky_gear_2],
        [sg_x + sg_w * 0.38, sg_y + sg_h * 0.70, 12, sky_gear_3],
        [sg_x + sg_w * 0.55, sg_y + sg_h * 0.35, 10, sky_gear_4],
        [sg_x + sg_w * 0.70, sg_y + sg_h * 0.60, 14, -sky_gear_1 * 0.8],
        [sg_x + sg_w * 0.85, sg_y + sg_h * 0.30, 11, -sky_gear_2 * 1.1],
    ];
    
    for (g = gears) {
        translate([g[0], g[1], 0])
        rotate([0, 0, g[3]])
        gear(g[2], thickness=3);
    }
    
    // Gear mesh connections (visual links)
    color(C_GEAR_DARK, 0.6)
    for (i = [0:len(gears)-2]) {
        g1 = gears[i];
        g2 = gears[i+1];
        hull() {
            translate([g1[0], g1[1], 1.5]) cylinder(r=1.5, h=0.5, $fn=16);
            translate([g2[0], g2[1], 1.5]) cylinder(r=1.5, h=0.5, $fn=16);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BIRD MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════

module bird_body(rotation=0) {
    rotate([0, 0, rotation])
    color(C_BIRD) {
        // Body
        scale([1, 0.5, 0.4])
        sphere(r=3.5, $fn=24);
        // Head
        translate([3, 0, 1])
        sphere(r=1.8, $fn=16);
        // Beak
        translate([5, 0, 1])
        rotate([0, 90, 0])
        cylinder(r1=0.6, r2=0, h=2, $fn=6);
        // Wings
        for (s = [-1, 1]) {
            translate([0, s * 2.5, 0.5])
            rotate([s * 15, 0, 8])
            scale([1.2, 0.12, 0.5])
            sphere(r=3.5, $fn=16);
        }
        // Tail
        translate([-3.5, 0, 0])
        rotate([0, -12, 0])
        scale([1.3, 0.1, 0.35])
        sphere(r=2.5, $fn=16);
    }
}

module bird_carriage(bird_rotation=0) {
    // Carriage body that rides on wire
    color(C_GEAR_DARK) {
        // Main body block
        difference() {
            translate([-4, -3, -4])
            cube([8, 6, 7]);
            // Wire groove (top)
            translate([0, 0, 2])
            rotate([90, 0, 0])
            cylinder(d=BIRD_WIRE_GAUGE + 0.5, h=10, center=true, $fn=16);
        }
    }
    // Vertical pivot bearing
    translate([0, 0, -1])
    bearing_683zz();
    // Bird on rotating platform
    translate([0, 0, 3])
    bird_body(bird_rotation);
    // Cam follower pin (extends down)
    translate([0, 0, -7])
    color(C_SHAFT)
    cylinder(d=1.5, h=4, $fn=12);
}

module bird_wire_track() {
    // Full width wire: [0, 302, 130, 150]
    wire_y = BIRD_WIRE_Y;
    sag = 4;  // Wire sag in middle
    
    // Main wire (12 gauge SS = 2mm)
    color(C_WIRE)
    for (offset = [0, 6]) {  // Two parallel wires
        for (i = [0:30]) {
            x1 = CANVAS_W * (i / 30);
            x2 = CANVAS_W * ((i + 1) / 30);
            y1 = wire_y + offset + sag * sin((i / 30) * 180);
            y2 = wire_y + offset + sag * sin(((i + 1) / 30) * 180);
            hull() {
                translate([x1, y1, 0]) sphere(r=BIRD_WIRE_GAUGE / 2, $fn=12);
                translate([x2, y2, 0]) sphere(r=BIRD_WIRE_GAUGE / 2, $fn=12);
            }
        }
    }
    
    // End loops (connect parallel wires)
    color(C_WIRE)
    for (x = [0, CANVAS_W]) {
        translate([x, wire_y + 3, 0])
        rotate([0, 90, x == 0 ? 0 : 180])
        rotate_extrude(angle=180, $fn=24)
        translate([3, 0, 0])
        circle(r=BIRD_WIRE_GAUGE / 2, $fn=12);
    }
    
    // End pulleys (drive and idler)
    color(C_GEAR_DARK)
    for (x = [5, CANVAS_W - 5]) {
        translate([x, wire_y + 3, -3])
        cylinder(r=BIRD_PULLEY_R, h=2, $fn=32);
    }
    
    // Drive pulley gear (right side)
    translate([CANVAS_W - 5, wire_y + 3, -6])
    gear(20, thickness=2, col=C_GEAR);
}

module bird_cam_track() {
    // Cam track below wire for bird rotation at ends
    color(C_CAM_RAIL)
    translate([0, BIRD_WIRE_Y - 5, -8]) {
        // Straight sections (birds don't rotate here)
        translate([30, 0, 0])
        cube([CANVAS_W - 60, 4, 2]);
        
        // Left turnaround cam (forces 180° rotation)
        translate([15, 2, 0])
        difference() {
            cylinder(r=15, h=2, $fn=48);
            translate([0, 0, -0.5])
            cylinder(r=10, h=3, $fn=48);
            translate([-20, -20, -0.5])
            cube([20, 40, 3]);
        }
        
        // Right turnaround cam
        translate([CANVAS_W - 15, 2, 0])
        difference() {
            cylinder(r=15, h=2, $fn=48);
            translate([0, 0, -0.5])
            cylinder(r=10, h=3, $fn=48);
            translate([0, -20, -0.5])
            cube([20, 40, 3]);
        }
    }
}

module bird_flock(progress, rotation) {
    // Two birds, 30mm apart, moving together
    wire_y = BIRD_WIRE_Y;
    sag = 4;
    
    // Calculate positions along track
    bird1_x = CANVAS_W * progress;
    bird1_y = wire_y + sag * sin(progress * 180);
    
    bird2_x = CANVAS_W * progress + BIRD_SPACING;
    bird2_y = wire_y + sag * sin(progress * 180);
    
    // Clamp bird2 to track
    bird2_x_clamped = min(bird2_x, CANVAS_W - 10);
    
    translate([bird1_x, bird1_y, 3])
    bird_carriage(rotation);
    
    translate([bird2_x_clamped, bird2_y, 3])
    bird_carriage(rotation);
}

module bird_assembly() {
    bird_wire_track();
    bird_cam_track();
    bird_flock(bird_progress, bird_rotation);
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLIFF AND LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════════

module cliff_hollow() {
    // Cliff zone: [0, 108, 0, 65]
    // Hollow inside to house motor
    
    color(C_CLIFF)
    difference() {
        // Outer shell
        linear_extrude(height=10)
        polygon([
            [0, 0],
            [ZONE_CLIFF[1] * 0.60, 0],
            [ZONE_CLIFF[1], ZONE_CLIFF[3]],
            [0, ZONE_CLIFF[3]]
        ]);
        
        // Hollow cavity for motor
        translate([5, 5, 2])
        linear_extrude(height=10)
        polygon([
            [0, 0],
            [ZONE_CLIFF[1] * 0.50, 0],
            [ZONE_CLIFF[1] * 0.70, ZONE_CLIFF[3] - 15],
            [0, ZONE_CLIFF[3] - 15]
        ]);
    }
    
    // Top texture layer
    translate([0, 0, 10])
    color(C_CLIFF_DARK)
    linear_extrude(height=3)
    polygon([
        [3, ZONE_CLIFF[3] * 0.1],
        [ZONE_CLIFF[1] * 0.55, ZONE_CLIFF[3] * 0.05],
        [ZONE_CLIFF[1] - 5, ZONE_CLIFF[3] * 0.92],
        [3, ZONE_CLIFF[3] * 0.92]
    ]);
    
    // Grass layer
    translate([0, ZONE_CLIFF[3] * 0.82, 13])
    color(C_CLIFF_GRASS)
    linear_extrude(height=2)
    polygon([
        [0, 0],
        [0, ZONE_CLIFF[3] * 0.20],
        [ZONE_CLIFF[1] - 8, ZONE_CLIFF[3] * 0.20],
        [ZONE_CLIFF[1] - 3, ZONE_CLIFF[3] * 0.08],
        [ZONE_CLIFF[1] * 0.60, -ZONE_CLIFF[3] * 0.02]
    ]);
}

module motor_in_cliff() {
    // N20 motor positioned inside cliff cavity
    translate([MOTOR_X, MOTOR_Y, Z_MOTOR])
    rotate([0, 90, 0]) {
        // Motor body
        color(C_MOTOR)
        cylinder(d=MOTOR_BODY_D, h=MOTOR_BODY_L, $fn=32);
        // Shaft
        translate([0, 0, MOTOR_BODY_L])
        color(C_SHAFT)
        cylinder(d=MOTOR_SHAFT_D, h=10, $fn=16);
        // Motor pinion
        translate([0, 0, MOTOR_BODY_L + 2])
        rotate([0, 0, motor_angle])
        gear(MOTOR_PINION_T, thickness=3, col=C_GEAR);
    }
}

module lighthouse() {
    // Lighthouse zone: [73, 82, 65, 117] = 9 × 52
    tower_h = zone_height(ZONE_LIGHTHOUSE) - 12;  // 40mm tower
    tower_r = (zone_width(ZONE_LIGHTHOUSE) - 1) / 2;  // ~4mm radius
    
    // Keeper's hut at base
    translate([-tower_r - 4, -2, 0])
    color(C_LIGHTHOUSE) {
        cube([tower_r * 2, 5, 5]);
        translate([0, 2.5, 5])
        rotate([90, 0, 90])
        linear_extrude(height=tower_r * 2)
        polygon([[0,0], [2.5, 2], [5, 0]]);
    }
    
    // Main tower
    color(C_LIGHTHOUSE)
    linear_extrude(height=tower_h, scale=0.7)
    circle(r=tower_r, $fn=32);
    
    // Stripes
    color(C_LIGHTHOUSE_STRIPE)
    for (z = [5, 15, 25]) {
        translate([0, 0, z])
        linear_extrude(height=3)
        circle(r=tower_r - 0.3 - z * 0.02, $fn=32);
    }
    
    // Platform
    translate([0, 0, tower_h])
    color("#333")
    cylinder(r=tower_r + 2, h=2, $fn=32);
    
    // Lamp room
    translate([0, 0, tower_h + 2])
    color("LightYellow", 0.6)
    difference() {
        cylinder(r=tower_r + 1, h=6, $fn=32);
        translate([0, 0, 1])
        cylinder(r=tower_r, h=7, $fn=32);
    }
    
    // Light source
    translate([0, 0, tower_h + 5])
    color("Yellow", 0.9)
    sphere(r=2, $fn=16);
    
    // Rotating beam
    translate([0, 0, tower_h + 4])
    rotate([0, 0, master_angle * 2])
    color("Yellow", 0.4)
    linear_extrude(height=3)
    polygon([[0, 0], [15, -1], [15, 1]]);
    
    // Roof
    translate([0, 0, tower_h + 8])
    color(C_LIGHTHOUSE_STRIPE)
    cylinder(r1=tower_r + 1.5, r2=1.5, h=4, $fn=32);
}

// ═══════════════════════════════════════════════════════════════════════════════
// CAMSHAFT AND FOUR-BAR LINKAGE (Wave Mechanism)
// ═══════════════════════════════════════════════════════════════════════════════

module camshaft_assembly() {
    // Camshaft spans from cliff waves to crank wheel
    // 5 cliff wave cams + 6 ocean wave cams + crank wheel
    
    camshaft_length = CAMSHAFT_X_END - CAMSHAFT_X_START;
    
    // Main shaft
    translate([CAMSHAFT_X_START, CAMSHAFT_Y, 0])
    rotate([0, 90, 0])
    shaft(camshaft_length);
    
    // Cliff wave cam lobes (5 lobes, 10mm spacing)
    cliff_cam_start = CAMSHAFT_X_START + 5;
    for (i = [0:CLIFF_WAVE_COUNT-1]) {
        translate([cliff_cam_start + i * 10, CAMSHAFT_Y, 0])
        rotate([0, 90, 0])
        rotate([0, 0, camshaft_angle + i * CAM_PHASE_SHIFT])
        cam_lobe(CAM_LOBE_OFFSET, CAMSHAFT_D, 6);
    }
    
    // Ocean wave cam lobes (6 lobes, 17mm spacing)
    ocean_cam_start = CAMSHAFT_X_START + 60;
    for (i = [0:OCEAN_WAVE_COUNT-1]) {
        translate([ocean_cam_start + i * 17, CAMSHAFT_Y, 0])
        rotate([0, 90, 0])
        rotate([0, 0, camshaft_angle + (CLIFF_WAVE_COUNT + i) * CAM_PHASE_SHIFT])
        cam_lobe(CAM_LOBE_OFFSET, CAMSHAFT_D, 6);
    }
    
    // Visible crank wheel at end
    translate([CAMSHAFT_X_END - 10, CAMSHAFT_Y, 0])
    rotate([0, 90, 0])
    rotate([0, 0, camshaft_angle]) {
        // Decorative crank wheel
        color(C_GEAR)
        difference() {
            cylinder(r=CRANK_WHEEL_R, h=CRANK_WHEEL_T, $fn=48);
            translate([0, 0, -0.5])
            cylinder(d=SHAFT_D, h=CRANK_WHEEL_T + 1, $fn=24);
            // Spoke cutouts
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                translate([CRANK_WHEEL_R * 0.55, 0, -0.5])
                cylinder(r=CRANK_WHEEL_R * 0.18, h=CRANK_WHEEL_T + 1, $fn=16);
            }
        }
        // Crank pin
        translate([CRANK_PIN_OFFSET, 0, CRANK_WHEEL_T])
        color(C_SHAFT)
        cylinder(d=3, h=5, $fn=16);
    }
    
    // Camshaft drive gear (receives power from motor)
    translate([CAMSHAFT_X_START - 5, CAMSHAFT_Y, 0])
    rotate([0, 90, 0])
    rotate([0, 0, camshaft_angle])
    gear(WAVE_DRIVE_T, thickness=3, col=C_GEAR_DARK);
    
    // Bearing mounts
    color(C_GEAR_DARK)
    for (x = [CAMSHAFT_X_START, CAMSHAFT_X_END - 20]) {
        translate([x, CAMSHAFT_Y, -8])
        bearing_mount(8);
    }
}

// Single wave layer with four-bar linkage
module wave_layer(index, is_cliff_wave=false, height_offset=0) {
    // Wave shape (simplified as polygon)
    wave_w = is_cliff_wave ? 45 : 80;
    wave_h = is_cliff_wave ? 60 : 55;
    
    // Calculate current wave position from cam
    current_height = wave_height(index);
    pivot_angle = current_height * 2;  // Convert to rotation
    
    // Fulcrum position
    fulcrum_x = is_cliff_wave ? CLIFF_WAVE_FULCRUM_X : OCEAN_WAVE_FULCRUM_X;
    
    translate([fulcrum_x, 0, 0])
    rotate([pivot_angle, 0, 0]) {
        // Wave shape
        wave_color = is_cliff_wave ? 
            (index < 2 ? C_WAVE_DARK : (index < 4 ? C_WAVE_MED : C_WAVE_LIGHT)) :
            (index < 2 ? C_WAVE_DARK : (index < 4 ? C_WAVE_MED : C_WAVE_LIGHT));
        
        color(wave_color)
        translate([0, height_offset, 0])
        linear_extrude(height=3)
        polygon([
            [0, 5],
            [wave_w * 0.2, 15],
            [wave_w * 0.5, wave_h * 0.7],
            [wave_w * 0.7, wave_h * 0.9],
            [wave_w * 0.85, wave_h],
            [wave_w, wave_h * 0.85],
            [wave_w, 0],
            [0, 0]
        ]);
    }
}

// Complete cliff waves (5 layers with foam curls)
module cliff_waves_assembly() {
    // Cliff waves zone: [108, 160, 0, 69]
    
    for (i = [0:CLIFF_WAVE_COUNT-1]) {
        translate([0, i * 4 + 3, i * 0.5])
        wave_layer(i, true, i * 8);
    }
    
    // Coupler rods from cam to wave layers
    cliff_cam_start = CAMSHAFT_X_START + 5;
    for (i = [0:CLIFF_WAVE_COUNT-1]) {
        cam_x = cliff_cam_start + i * 10;
        cam_y = CAMSHAFT_Y + CAM_LOBE_OFFSET * cos(camshaft_angle + i * CAM_PHASE_SHIFT);
        cam_z = CAM_LOBE_OFFSET * sin(camshaft_angle + i * CAM_PHASE_SHIFT);
        
        fulcrum_x = CLIFF_WAVE_FULCRUM_X + 20;
        fulcrum_y = 5 + i * 4;
        
        color(C_COUPLER)
        hull() {
            translate([cam_x, cam_y, cam_z])
            sphere(r=1.5, $fn=12);
            translate([fulcrum_x, fulcrum_y, i * 0.5 + 2])
            sphere(r=1.5, $fn=12);
        }
    }
}

// Complete ocean waves (6 layers)
module ocean_waves_assembly() {
    // Ocean waves zone: [151, 302, 0, 65]
    
    for (i = [0:OCEAN_WAVE_COUNT-1]) {
        translate([0, i * 3 + 5, i * 0.3])
        wave_layer(CLIFF_WAVE_COUNT + i, false, i * 6);
    }
    
    // Coupler rods
    ocean_cam_start = CAMSHAFT_X_START + 60;
    for (i = [0:OCEAN_WAVE_COUNT-1]) {
        cam_x = ocean_cam_start + i * 17;
        cam_y = CAMSHAFT_Y + CAM_LOBE_OFFSET * cos(camshaft_angle + (CLIFF_WAVE_COUNT + i) * CAM_PHASE_SHIFT);
        cam_z = CAM_LOBE_OFFSET * sin(camshaft_angle + (CLIFF_WAVE_COUNT + i) * CAM_PHASE_SHIFT);
        
        fulcrum_x = OCEAN_WAVE_FULCRUM_X + 30;
        fulcrum_y = 8 + i * 3;
        
        color(C_COUPLER)
        hull() {
            translate([cam_x, cam_y, cam_z])
            sphere(r=1.5, $fn=12);
            translate([fulcrum_x, fulcrum_y, i * 0.3 + 2])
            sphere(r=1.5, $fn=12);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOAM CURL MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════

module foam_curl_tip(curl_angle) {
    // Pivoting foam curl piece
    rotate([curl_angle, 0, 0])
    color(C_FOAM, 0.95)
    linear_extrude(height=2)
    polygon([
        [0, 0],
        [12, 3],
        [15, 8],
        [12, 12],
        [5, 10],
        [0, 5]
    ]);
}

module foam_curl_assembly() {
    // Foam curls at top of cliff waves
    // Positioned to create rolling curl effect
    
    for (i = [0:CLIFF_WAVE_COUNT-1]) {
        curl_x = CLIFF_WAVE_FULCRUM_X + 35;
        curl_y = 50 + i * 4;
        
        // Calculate curl angle based on wave height
        curl_angle = foam_curl_angle(i);
        
        translate([curl_x, curl_y, i * 0.5])
        foam_curl_tip(curl_angle);
    }
}

module cam_rail_for_foam() {
    // Fixed cam rail that activates foam curls
    // Staggered profile ensures 2-3 foams always curled
    
    color(C_CAM_RAIL)
    translate([CLIFF_WAVE_FULCRUM_X + 30, 45, -5]) {
        // Rail base
        cube([25, 35, 2]);
        
        // Cam profile (staggered peaks)
        for (i = [0:CLIFF_WAVE_COUNT-1]) {
            translate([5, 5 + i * 6, 2])
            rotate([0, 0, 0])
            linear_extrude(height=3)
            polygon([
                [0, 0],
                [8, 4],
                [16, 0]
            ]);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM GEARS (Visible Decorative + Functional)
// ═══════════════════════════════════════════════════════════════════════════════

module bottom_gears_assembly() {
    // Bottom gears zone: [164, 302, 0, 30]
    // These transfer power from motor shaft to camshaft
    
    bg_x = ZONE_BOTTOM_GEARS[0];
    bg_y = 15;
    
    // Transfer gears from motor drive shaft to camshaft
    gear_positions = [
        [bg_x + 10, bg_y, 18, bottom_gear_angle],
        [bg_x + 35, bg_y + 5, 22, -bottom_gear_angle * 0.82],
        [bg_x + 65, bg_y - 3, 16, bottom_gear_angle * 1.12],
        [bg_x + 90, bg_y + 2, 20, -bottom_gear_angle * 0.91],
    ];
    
    for (g = gear_positions) {
        translate([g[0], g[1], 0])
        rotate([0, 0, g[3]])
        gear(g[2], thickness=3, col=C_GEAR_DARK);
    }
    
    // Connecting rods (visual)
    color(C_GEAR, 0.7)
    for (i = [0:len(gear_positions)-2]) {
        g1 = gear_positions[i];
        g2 = gear_positions[i+1];
        hull() {
            translate([g1[0], g1[1], 1.5]) cylinder(r=1.8, h=0.5, $fn=16);
            translate([g2[0], g2[1], 1.5]) cylinder(r=1.8, h=0.5, $fn=16);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RICE TUBE (Sound Mechanism)
// ═══════════════════════════════════════════════════════════════════════════════

module rice_tube() {
    // Rice tube rocks with wave motion to create ocean sound
    
    rotate([rice_tube_angle, 0, 0])
    translate([RICE_TUBE_X - RICE_TUBE_LENGTH/2, RICE_TUBE_Y, 0])
    rotate([0, 90, 0]) {
        // Outer tube
        color(C_RICE_TUBE)
        difference() {
            cylinder(d=RICE_TUBE_OD, h=RICE_TUBE_LENGTH, $fn=48);
            translate([0, 0, 2])
            cylinder(d=RICE_TUBE_ID, h=RICE_TUBE_LENGTH - 4, $fn=48);
        }
        
        // End caps
        color(C_RICE_TUBE)
        for (z = [0, RICE_TUBE_LENGTH - 2]) {
            translate([0, 0, z])
            cylinder(d=RICE_TUBE_OD, h=2, $fn=48);
        }
        
        // Internal spiral baffles (simplified visualization)
        color(C_GEAR_DARK, 0.5)
        for (i = [0:15]) {
            translate([0, 0, 10 + i * 11])
            rotate([0, 0, i * 25])
            translate([0, RICE_TUBE_ID/2 - 1, 0])
            cube([2, 2, 8]);
        }
        
        // Rice grains visualization (when transparent)
        color("#f5e6c8", 0.3)
        translate([0, 0, RICE_TUBE_LENGTH * 0.3])
        cylinder(d=RICE_TUBE_ID - 4, h=RICE_TUBE_LENGTH * 0.2, $fn=24);
    }
    
    // Center pivot mount
    color(C_GEAR_DARK)
    translate([RICE_TUBE_X, RICE_TUBE_Y - 15, -3]) {
        cube([10, 30, 6], center=true);
        // Pivot pin
        translate([0, 0, 3])
        rotate([90, 0, 0])
        cylinder(d=3, h=35, center=true, $fn=16);
    }
    
    // Rocker arm connection to camshaft
    color(C_COUPLER)
    hull() {
        translate([RICE_TUBE_X + RICE_TUBE_LENGTH/2 - 20, RICE_TUBE_Y, 0])
        sphere(r=2, $fn=12);
        translate([CAMSHAFT_X_END - 30, CAMSHAFT_Y, 0])
        sphere(r=2, $fn=12);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CYPRESS TREE
// ═══════════════════════════════════════════════════════════════════════════════

module cypress_tree() {
    // Cypress zone: [35, 95, 0, 121] = 60 × 121
    cypress_w = zone_width(ZONE_CYPRESS);
    cypress_h = zone_height(ZONE_CYPRESS);
    
    // Main cypress shape (tall, narrow, flame-like)
    color(C_CYPRESS)
    linear_extrude(height=5)
    polygon([
        // Base (narrower)
        [cypress_w * 0.35, 0],
        [cypress_w * 0.65, 0],
        // Right edge (undulating)
        [cypress_w * 0.68, cypress_h * 0.10],
        [cypress_w * 0.75, cypress_h * 0.20],
        [cypress_w * 0.72, cypress_h * 0.30],
        [cypress_w * 0.80, cypress_h * 0.40],
        [cypress_w * 0.75, cypress_h * 0.50],
        [cypress_w * 0.82, cypress_h * 0.60],
        [cypress_w * 0.78, cypress_h * 0.70],
        [cypress_w * 0.70, cypress_h * 0.80],
        [cypress_w * 0.60, cypress_h * 0.90],
        // Top
        [cypress_w * 0.50, cypress_h],
        // Left edge (undulating)
        [cypress_w * 0.40, cypress_h * 0.90],
        [cypress_w * 0.30, cypress_h * 0.80],
        [cypress_w * 0.22, cypress_h * 0.70],
        [cypress_w * 0.18, cypress_h * 0.60],
        [cypress_w * 0.25, cypress_h * 0.50],
        [cypress_w * 0.20, cypress_h * 0.40],
        [cypress_w * 0.28, cypress_h * 0.30],
        [cypress_w * 0.25, cypress_h * 0.20],
        [cypress_w * 0.32, cypress_h * 0.10]
    ]);
    
    // Highlight layer (slightly offset)
    translate([2, 0, 5])
    color(C_CYPRESS_HIGHLIGHT, 0.7)
    linear_extrude(height=2)
    scale([0.85, 0.95])
    translate([cypress_w * 0.08, 0])
    polygon([
        [cypress_w * 0.38, cypress_h * 0.05],
        [cypress_w * 0.62, cypress_h * 0.05],
        [cypress_w * 0.70, cypress_h * 0.40],
        [cypress_w * 0.65, cypress_h * 0.70],
        [cypress_w * 0.50, cypress_h * 0.95],
        [cypress_w * 0.35, cypress_h * 0.70],
        [cypress_w * 0.30, cypress_h * 0.40]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRIVE TRAIN (Motor to All Mechanisms)
// ═══════════════════════════════════════════════════════════════════════════════

module drive_train() {
    // Master gear (driven by motor pinion)
    translate([MASTER_GEAR_X, MASTER_GEAR_Y, Z_MOTOR + 2])
    rotate([0, 0, master_angle])
    gear(MASTER_GEAR_T, thickness=4, col=C_GEAR);
    
    // Horizontal drive shaft to wave mechanism
    translate([MASTER_GEAR_X, MASTER_GEAR_Y, Z_DRIVE_SHAFT])
    rotate([0, 90, 0])
    shaft(CAMSHAFT_X_START - MASTER_GEAR_X - 10);
    
    // Transfer gears along bottom
    transfer_positions = [
        [MASTER_GEAR_X + 40, MASTER_GEAR_Y, 24],
        [MASTER_GEAR_X + 80, MASTER_GEAR_Y + 5, 20],
        [MASTER_GEAR_X + 120, MASTER_GEAR_Y, 22],
    ];
    
    for (i = [0:len(transfer_positions)-1]) {
        pos = transfer_positions[i];
        translate([pos[0], pos[1], Z_DRIVE_SHAFT])
        rotate([0, 0, master_angle * (i % 2 == 0 ? 1 : -1) * (1 + i * 0.1)])
        gear(pos[2], thickness=3, col=C_GEAR_DARK);
    }
    
    // Vertical shaft to sky mechanism
    translate([MASTER_GEAR_X + 20, MASTER_GEAR_Y + 30, Z_MOTOR])
    shaft(Z_SKY_GEARS - Z_MOTOR);
    
    // Sky drive gear
    translate([MASTER_GEAR_X + 20, MASTER_GEAR_Y + 30, Z_SKY_GEARS - 5])
    rotate([0, 0, sky_angle])
    gear(SKY_DRIVE_T, thickness=3, col=C_GEAR);
    
    // Idler gears connecting to swirls
    // Connection to big swirl
    idler1_x = (MASTER_GEAR_X + 20 + BIG_SWIRL_X) / 2;
    idler1_y = (MASTER_GEAR_Y + 30 + BIG_SWIRL_Y) / 2;
    translate([idler1_x, idler1_y, Z_SKY_GEARS - 5])
    rotate([0, 0, -sky_angle * 1.2])
    gear(18, thickness=3, col=C_GEAR_DARK);
    
    // Connection to small swirl
    idler2_x = (idler1_x + SMALL_SWIRL_X) / 2;
    idler2_y = (idler1_y + SMALL_SWIRL_Y) / 2;
    translate([idler2_x, idler2_y, Z_SKY_GEARS - 5])
    rotate([0, 0, sky_angle * 0.9])
    gear(16, thickness=3, col=C_GEAR_DARK);
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACK PLATE
// ═══════════════════════════════════════════════════════════════════════════════

module back_plate() {
    color(C_SKY, 0.8)
    cube([CANVAS_W, CANVAS_H, 2]);
    
    // Mounting holes for axles and bearings
    color(C_SKY)
    translate([0, 0, 2]) {
        // Moon axle mount
        translate([MOON_X, MOON_Y, 0])
        bearing_mount(8);
        
        // Big swirl axle mount
        translate([BIG_SWIRL_X, BIG_SWIRL_Y, 0])
        bearing_mount(8);
        
        // Small swirl axle mount
        translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, 0])
        bearing_mount(8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                              MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════
// Z-ORDER (Back to Front):
// 1. Sky mechanism (moon, stars, swirls, wind path, sky gears)
// 2. Bird wire + birds
// 3. Cliff + lighthouse
// 4. Ocean waves + bottom gears (same Z)
// 5. Cliff waves + foam curls
// 6. Cypress (frontmost)
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// BACK PLATE (Z = 0)
// ─────────────────────────────────────────────────────────────────────────────
translate([0, 0, Z_BACK_PLATE])
back_plate();

// ─────────────────────────────────────────────────────────────────────────────
// MOTOR AND DRIVE TRAIN (Z = 4-10)
// ─────────────────────────────────────────────────────────────────────────────
motor_in_cliff();
drive_train();

// ─────────────────────────────────────────────────────────────────────────────
// SKY MECHANISM (Z = 11-36)
// ─────────────────────────────────────────────────────────────────────────────

// Moon assembly
translate([MOON_X, MOON_Y, Z_MOON_HALO_BACK])
moon_assembly(moon_halo_back_angle, moon_halo_front_angle, moon_angle);

// Stars
translate([0, 0, Z_STARS])
all_stars();

// Big swirl
translate([BIG_SWIRL_X, BIG_SWIRL_Y, Z_SWIRL_HALO_BACK])
swirl_assembly(BIG_SWIRL_R, swirl_big_angle, swirl_big_halo_angle, -swirl_big_halo_angle * 0.7);

// Small swirl
translate([SMALL_SWIRL_X, SMALL_SWIRL_Y, Z_SWIRL_HALO_BACK])
swirl_assembly(SMALL_SWIRL_R, swirl_small_angle, swirl_small_halo_angle, -swirl_small_halo_angle * 0.8);

// Wind path panel
translate([ZONE_WIND_PATH[0], ZONE_WIND_PATH[2], Z_WIND_PATH])
wind_path_panel();

// Sky gears
translate([0, 0, Z_SKY_GEARS])
sky_gears_assembly();

// ─────────────────────────────────────────────────────────────────────────────
// BIRD MECHANISM (Z = 38-47)
// ─────────────────────────────────────────────────────────────────────────────
translate([0, 0, Z_BIRD_WIRE])
bird_assembly();

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF AND LIGHTHOUSE (Z = 48-56)
// ─────────────────────────────────────────────────────────────────────────────

// Cliff (hollow, contains motor)
translate([ZONE_CLIFF[0], ZONE_CLIFF[2], Z_CLIFF])
cliff_hollow();

// Lighthouse
translate([zone_center_x(ZONE_LIGHTHOUSE), ZONE_LIGHTHOUSE[2], Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse();

// ─────────────────────────────────────────────────────────────────────────────
// WAVE MECHANISM (Z = 57-63)
// ─────────────────────────────────────────────────────────────────────────────

// Camshaft and four-bar linkage
translate([0, 0, Z_BOTTOM_GEARS])
camshaft_assembly();

// Bottom gears (visible, decorative)
translate([0, 0, Z_BOTTOM_GEARS])
bottom_gears_assembly();

// Ocean waves (6 layers)
translate([0, 0, Z_OCEAN_WAVES])
ocean_waves_assembly();

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF WAVES AND FOAM (Z = 64-72)
// ─────────────────────────────────────────────────────────────────────────────

// Cliff waves (5 layers)
translate([0, 0, Z_CLIFF_WAVES])
cliff_waves_assembly();

// Foam curl tips
translate([0, 0, Z_FOAM_CURLS])
foam_curl_assembly();

// Cam rail for foam activation
translate([0, 0, Z_CAM_RAIL])
cam_rail_for_foam();

// ─────────────────────────────────────────────────────────────────────────────
// CYPRESS (Z = 73-78, Frontmost)
// ─────────────────────────────────────────────────────────────────────────────
translate([ZONE_CYPRESS[0], ZONE_CYPRESS[2], Z_CYPRESS])
cypress_tree();

// ─────────────────────────────────────────────────────────────────────────────
// RICE TUBE (Z = -15, Behind bottom tab)
// ─────────────────────────────────────────────────────────────────────────────
translate([0, 0, Z_RICE_TUBE])
rice_tube();

// ═══════════════════════════════════════════════════════════════════════════════
// DEBUG / VERIFICATION OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V38 - COMPLETE MECHANICAL KINETIC ART");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("CANVAS DIMENSIONS:");
echo(str("  Art area: ", CANVAS_W, " × ", CANVAS_H, " mm"));
echo(str("  Total with tabs: ", TOTAL_W, " × ", TOTAL_H, " mm"));
echo(str("  Total depth: ", TOTAL_DEPTH, " mm"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("MECHANICAL SPECIFICATIONS:");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("  Motor: N20 ", MOTOR_RPM, " RPM"));
echo(str("  Master gear ratio: ", MASTER_GEAR_T, ":", MOTOR_PINION_T, " (", MASTER_GEAR_T/MOTOR_PINION_T, ":1)"));
echo(str("  Shaft diameter: ", SHAFT_D, " mm brass"));
echo(str("  Bearings: 683ZZ (", BEARING_ID, "×", BEARING_OD, "×", BEARING_H, " mm)"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("WAVE MECHANISM:");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("  Cliff waves: ", CLIFF_WAVE_COUNT, " layers"));
echo(str("  Ocean waves: ", OCEAN_WAVE_COUNT, " layers"));
echo(str("  Total cam lobes: ", TOTAL_CAM_LOBES));
echo(str("  Phase shift: ", CAM_PHASE_SHIFT, "° between layers"));
echo(str("  Cam lobe offset: ", CAM_LOBE_OFFSET, " mm"));
echo(str("  Wave amplitude: ~", WAVE_AMPLITUDE, " mm at tips"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("SKY MECHANISM:");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("  Big swirl: center (", BIG_SWIRL_X, ", ", BIG_SWIRL_Y, "), R=", BIG_SWIRL_R));
echo(str("  Small swirl: center (", SMALL_SWIRL_X, ", ", SMALL_SWIRL_Y, "), R=", SMALL_SWIRL_R));
echo(str("  Moon: center (", MOON_X, ", ", MOON_Y, "), R=", MOON_R));
echo(str("  Counter-rotating halos: YES (via idler gears)"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("BIRD MECHANISM:");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("  Wire gauge: 12ga (", BIRD_WIRE_GAUGE, " mm)"));
echo(str("  Bird count: 2 (flock)"));
echo(str("  Bird spacing: ", BIRD_SPACING, " mm"));
echo(str("  Track: continuous loop with 180° rotation at ends"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("RICE TUBE (Sound):");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("  Length: ", RICE_TUBE_LENGTH, " mm"));
echo(str("  Diameter: ", RICE_TUBE_OD, " mm OD, ", RICE_TUBE_ID, " mm ID"));
echo(str("  Rock angle: ±", RICE_TUBE_ROCK_ANGLE, "°"));
echo(str("  Drive: synchronized with wave camshaft"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("Z-LAYER ORDER (Back → Front):");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("  Z=", Z_BACK_PLATE, "-", Z_VERTICAL_SHAFT, ": Back plate, motor, drive shafts"));
echo(str("  Z=", Z_MOON_HALO_BACK, "-", Z_SKY_CONNECTIONS, ": SKY MECHANISM"));
echo(str("  Z=", Z_BIRD_WIRE, "-", Z_BIRD_CARRIAGE, ": BIRD MECHANISM"));
echo(str("  Z=", Z_CLIFF, "-", Z_LIGHTHOUSE, ": CLIFF + LIGHTHOUSE"));
echo(str("  Z=", Z_OCEAN_WAVES, "-", Z_WAVE_COUPLERS, ": OCEAN WAVES + BOTTOM GEARS"));
echo(str("  Z=", Z_CLIFF_WAVES, "-", Z_CAM_RAIL, ": CLIFF WAVES + FOAM CURLS"));
echo(str("  Z=", Z_CYPRESS, "-78: CYPRESS (frontmost)"));
echo(str("  Z=", Z_RICE_TUBE, ": RICE TUBE (behind bottom tab)"));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("ANIMATION:");
echo("  View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
