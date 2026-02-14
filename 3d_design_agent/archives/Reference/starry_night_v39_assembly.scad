// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V39 - COMPLETE MECHANICAL KINETIC ART ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════
// Canvas: 350 × 250 mm total (302 × 202 mm art area)
// Depth: 80mm
// Enclosure: 4mm walls, removable back panel
// Motor: Inside cliff (hidden), N20 60RPM
// ═══════════════════════════════════════════════════════════════════════════════════
$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         SHOW/HIDE CONTROLS
// Set to true/false to show/hide elements for verification
// ═══════════════════════════════════════════════════════════════════════════════════
SHOW_ENCLOSURE      = true;   // Box enclosure with mounting tabs
SHOW_BACK_PANEL     = true;   // Removable back panel
SHOW_CLIFF          = true;   // Cliff landmass
SHOW_LIGHTHOUSE     = true;   // Lighthouse on cliff
SHOW_CYPRESS        = true;   // Cypress tree (traced shape)
SHOW_CLIFF_WAVES    = true;   // Breaking waves at cliff
SHOW_OCEAN_WAVES    = true;   // Open ocean waves
SHOW_WIND_PATH      = true;   // Wind path panel (traced shape)
SHOW_BIG_SWIRL      = true;   // Large swirl disc
SHOW_SMALL_SWIRL    = true;   // Small swirl disc
SHOW_MOON           = true;   // Moon assembly
SHOW_BOTTOM_GEARS   = true;   // Visible bottom gears + crank
SHOW_SKY_GEARS      = true;   // Sky area gears
SHOW_BIRD_WIRE      = true;   // Bird wire track
SHOW_RICE_TUBE      = true;   // Sound tube mechanism
SHOW_MOTOR          = true;   // Motor inside cliff
SHOW_DRIVE_TRAIN    = true;   // Drive shafts and gears
SHOW_CAMSHAFT       = true;   // Wave drive camshaft
SHOW_ZONE_OUTLINES  = false;  // Debug: show zone boundaries

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MASTER DIMENSIONS (LOCKED)
// ═══════════════════════════════════════════════════════════════════════════════════
TOTAL_W = 350;              // Total width with tabs
TOTAL_H = 250;              // Total height with tabs
TOTAL_D = 80;               // Total depth
TAB_W = 24;                 // Mounting tab width
WALL_T = 4;                 // Enclosure wall thickness
CANVAS_W = 302;             // Art area width (TOTAL_W - 2*TAB_W)
CANVAS_H = 202;             // Art area height (TOTAL_H - 2*TAB_W)

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS (LOCKED - DO NOT MODIFY)
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX] - relative to canvas origin
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
ZONE_RICE_TUBE    = [50, 250, -TAB_W, 0];  // Behind bottom tab

// Zone helper functions
function zone_w(z) = z[1] - z[0];
function zone_h(z) = z[3] - z[2];
function zone_cx(z) = (z[0] + z[1]) / 2;
function zone_cy(z) = (z[2] + z[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════
Z_BACK_PANEL      = 0;
Z_MOTOR           = 5;
Z_DRIVE_SHAFT     = 8;
Z_RICE_TUBE       = -15;     // Behind bottom tab
Z_MOON            = 12;
Z_SKY_GEARS_BACK  = 15;
Z_SWIRL_BACK      = 18;
Z_SWIRL_FRONT     = 24;
Z_WIND_PATH       = 30;
Z_SKY_GEARS_FRONT = 35;
Z_BIRD_WIRE       = 40;
Z_CLIFF           = 45;
Z_LIGHTHOUSE      = 48;
Z_CAMSHAFT        = 50;
Z_BOTTOM_GEARS    = 52;
Z_OCEAN_WAVES     = 54;
Z_CLIFF_WAVES     = 58;
Z_CYPRESS         = 70;
Z_FRAME_FRONT     = 76;

// ═══════════════════════════════════════════════════════════════════════════════════
//                         ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════
t = $t;  // 0 to 1

// Motor: N20 60RPM, Master gear 60:10 = 6:1 reduction → 10 RPM at master
MOTOR_RPM = 60;
MASTER_RATIO = 6;
MASTER_RPM = MOTOR_RPM / MASTER_RATIO;  // 10 RPM

// Animation speeds (derived from master)
motor_rot = t * 360 * 6;           // Fast motor rotation
master_rot = t * 360;              // 1 full rotation per cycle
swirl_big_rot = t * 360 * 0.5;     // Slow CCW
swirl_small_rot = -t * 360 * 0.7;  // Slow CW (counter)
moon_rot = t * 360 * 0.3;          // Very slow
wave_phase = t * 360;              // Wave camshaft
bird_pos = t;                      // 0-1 along track
rice_tilt = 15 * sin(t * 360);     // ±15° rocking

// ═══════════════════════════════════════════════════════════════════════════════════
//                         COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════════
C_ENCLOSURE     = "#3a3028";      // Dark wood/metal
C_BACK_PANEL    = "#2a2018";      // Darker back
C_CLIFF         = "#6b5344";      // Brown rock
C_LIGHTHOUSE    = "#c4b498";      // Cream stone
C_CYPRESS       = "#1a3a1a";      // Dark green
C_WAVE_DARK     = "#1a4a6e";      // Deep blue
C_WAVE_MID      = "#2a6a8e";      // Mid blue
C_WAVE_LIGHT    = "#4a8aae";      // Light blue
C_FOAM          = "#ffffff";      // White foam
C_WIND          = "#2a5a9e";      // Sky blue
C_SWIRL         = "#4a7ab0";      // Swirl disc
C_MOON          = "#f0d060";      // Golden yellow
C_GEAR          = "#8b7355";      // Dark brass
C_SHAFT         = "#b0a090";      // Light brass
C_MOTOR         = "#333333";      // Motor body
C_RICE_TUBE     = "#8b6914";      // Wood color

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MECHANICAL SPECIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════════
SHAFT_D = 3;                      // 3mm brass rod
BEARING_ID = 3;                   // 683ZZ bearing inner
BEARING_OD = 7;                   // 683ZZ bearing outer
BEARING_H = 3;                    // 683ZZ bearing height
GEAR_MODULE = 1;                  // Gear module (m=1)

// Gear tooth counts
MOTOR_PINION_T = 10;              // Motor pinion
MASTER_GEAR_T = 60;               // Master gear (6:1)
WORM_LEADS = 1;                   // Worm gear leads
WORM_WHEEL_T = 30;                // Worm wheel teeth (30:1)
SKY_DRIVE_T = 20;                 // Sky mechanism
WAVE_DRIVE_T = 30;                // Wave mechanism
BIRD_DRIVE_T = 15;                // Bird mechanism

// ═══════════════════════════════════════════════════════════════════════════════════
//                         INCLUDE TRACED SHAPE WRAPPERS
// ═══════════════════════════════════════════════════════════════════════════════════
use <cliffs_wrapper.scad>
use <cypress_shape_wrapper.scad>
use <wind_path_shape_wrapper.scad>

// Shape bounding boxes (from wrapper functions)
// cliffs_shape: X[-70.094, 70.103], Y[-34.616, 34.634], Z[0, 10] → ~140×69mm
// cypress_shape: X[-22.469, 64.572], Y[-112.572, 48.404], Z[0, 10] → ~87×161mm  
// wind_path_shape: X[-892.309, 891.951], Y[-266.834, 266.564], Z[0, 10] → ~1784×533mm

// Calculated scale factors (prioritize shape, scale uniformly)
CLIFF_ORIG_W = 140.197;
CLIFF_ORIG_H = 69.25;
CLIFF_SCALE = min(zone_w(ZONE_CLIFF) / CLIFF_ORIG_W, zone_h(ZONE_CLIFF) / CLIFF_ORIG_H);  // ~0.77

CYPRESS_ORIG_W = 87.041;
CYPRESS_ORIG_H = 160.976;
CYPRESS_SCALE = min(zone_w(ZONE_CYPRESS) / CYPRESS_ORIG_W, zone_h(ZONE_CYPRESS) / CYPRESS_ORIG_H);  // ~0.69

WIND_ORIG_W = 1784.26;
WIND_ORIG_H = 533.398;
WIND_SCALE = min(zone_w(ZONE_WIND_PATH) / WIND_ORIG_W, zone_h(ZONE_WIND_PATH) / WIND_ORIG_H);  // ~0.11

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: ENCLOSURE BOX
// 4mm walls on all sides except front (open for viewing)
// Mounting tabs sit on wooden frame
// ═══════════════════════════════════════════════════════════════════════════════════
module enclosure() {
    color(C_ENCLOSURE)
    difference() {
        // Outer shell
        cube([TOTAL_W, TOTAL_H, TOTAL_D]);
        
        // Inner cavity (leave walls on bottom, left, right, top - front open)
        translate([WALL_T, WALL_T, WALL_T])
        cube([TOTAL_W - 2*WALL_T, TOTAL_H - 2*WALL_T, TOTAL_D]);
        
        // Front opening (full art area visible)
        translate([TAB_W, TAB_W, WALL_T])
        cube([CANVAS_W, CANVAS_H, TOTAL_D]);
    }
    
    // Mounting tabs (extend beyond canvas, sit on wooden frame)
    // Bottom tab
    color(C_ENCLOSURE)
    translate([0, 0, 0])
    cube([TOTAL_W, TAB_W, WALL_T]);
    
    // Top tab
    translate([0, TOTAL_H - TAB_W, 0])
    cube([TOTAL_W, TAB_W, WALL_T]);
    
    // Left tab
    translate([0, 0, 0])
    cube([TAB_W, TOTAL_H, WALL_T]);
    
    // Right tab
    translate([TOTAL_W - TAB_W, 0, 0])
    cube([TAB_W, TOTAL_H, WALL_T]);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: REMOVABLE BACK PANEL
// ═══════════════════════════════════════════════════════════════════════════════════
module back_panel() {
    color(C_BACK_PANEL)
    difference() {
        translate([WALL_T + 2, WALL_T + 2, 0])
        cube([TOTAL_W - 2*WALL_T - 4, TOTAL_H - 2*WALL_T - 4, WALL_T - 1]);
        
        // Motor access cutout (behind cliff)
        translate([TAB_W + 20, TAB_W + 10, -1])
        cube([60, 50, WALL_T + 2]);
        
        // Wiring access holes
        translate([TAB_W + 250, TAB_W + 20, -1])
        cylinder(r=8, h=WALL_T + 2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: GEAR (Parametric)
// ═══════════════════════════════════════════════════════════════════════════════════
module gear(teeth, module_=1, thickness=4, hole_r=1.5, spokes=true) {
    pitch_r = teeth * module_ / 2;
    outer_r = pitch_r + module_;
    root_r = pitch_r - 1.25 * module_;
    tooth_h = 2.25 * module_;
    
    color(C_GEAR)
    difference() {
        union() {
            // Main body
            cylinder(r=root_r, h=thickness);
            // Teeth
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([pitch_r, 0, 0])
                cylinder(r=module_*0.9, h=thickness, $fn=6);
            }
        }
        // Center hole
        translate([0, 0, -1])
        cylinder(r=hole_r, h=thickness+2);
        
        // Spoke cutouts (for larger gears)
        if (spokes && pitch_r > 15) {
            spoke_count = pitch_r > 25 ? 6 : 4;
            for (i = [0:spoke_count-1]) {
                rotate([0, 0, i * 360/spoke_count + 30])
                translate([pitch_r*0.55, 0, -1])
                cylinder(r=pitch_r*0.25, h=thickness+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WORM GEAR (Perpendicular to main gear)
// ═══════════════════════════════════════════════════════════════════════════════════
module worm_gear(length=30, diameter=8, leads=1, rot=0) {
    pitch = 3.14159 * diameter / leads;
    
    color(C_SHAFT)
    rotate([0, 0, rot])
    difference() {
        union() {
            // Worm body
            cylinder(r=diameter/2, h=length);
            // Thread helix (simplified as ridges)
            for (i = [0:length/pitch*leads]) {
                translate([0, 0, i * pitch / leads])
                rotate([0, 0, i * 360 / leads])
                linear_extrude(height=pitch/leads, twist=360/leads)
                translate([diameter/2 - 1, 0])
                circle(r=1.5, $fn=8);
            }
        }
        // Center bore
        translate([0, 0, -1])
        cylinder(r=SHAFT_D/2, h=length+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MOTOR (N20 Gear Motor)
// ═══════════════════════════════════════════════════════════════════════════════════
module motor_n20(rot=0) {
    // N20 motor: ~12×10×24mm body + 10mm shaft
    color(C_MOTOR) {
        // Motor body
        cube([12, 10, 24]);
        // Gearbox
        translate([0, 0, 24])
        cube([12, 10, 10]);
    }
    // Output shaft
    color(C_SHAFT)
    translate([6, 5, 34])
    rotate([0, 0, rot])
    cylinder(r=1.5, h=12);
    
    // Pinion gear on shaft
    translate([6, 5, 40])
    rotate([0, 0, rot])
    gear(MOTOR_PINION_T, GEAR_MODULE, 5, 1.5, false);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CLIFF (Traced Shape)
// ═══════════════════════════════════════════════════════════════════════════════════
module cliff_traced() {
    // Original shape center offset
    cx = 0;  // Shape is centered around 0
    cy = 0;
    
    // Position in zone
    zone_cx = zone_cx(ZONE_CLIFF);
    zone_cy = zone_cy(ZONE_CLIFF);
    
    translate([zone_cx, zone_cy, 0])
    scale([CLIFF_SCALE, CLIFF_SCALE, 1])
    translate([-cx, -cy, 0])
    color(C_CLIFF)
    cliffs_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CYPRESS TREE (Traced Shape)
// ═══════════════════════════════════════════════════════════════════════════════════
module cypress_traced() {
    // Original shape bounds: X[-22.469, 64.572], Y[-112.572, 48.404]
    // Shape origin offset to place base at Y=0
    orig_y_min = -112.572;
    orig_x_min = -22.469;
    orig_x_max = 64.572;
    orig_cx = (orig_x_min + orig_x_max) / 2;  // ~21
    
    // Scale and position
    scaled_h = CYPRESS_ORIG_H * CYPRESS_SCALE;  // ~111mm
    scaled_w = CYPRESS_ORIG_W * CYPRESS_SCALE;  // ~60mm
    
    // Position so base touches Y=0, centered in zone X
    zone_cx = zone_cx(ZONE_CYPRESS);
    
    translate([zone_cx, 0, 0])
    scale([CYPRESS_SCALE, CYPRESS_SCALE, 1])
    translate([-orig_cx, -orig_y_min, 0])  // Move base to Y=0
    color(C_CYPRESS)
    cypress_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WIND PATH (Traced Shape)
// ═══════════════════════════════════════════════════════════════════════════════════
module wind_path_traced() {
    // Original shape bounds: X[-892.309, 891.951], Y[-266.834, 266.564]
    // Massive shape needs significant scaling
    orig_cx = 0;  // Centered
    orig_cy = 0;  // Centered
    
    // Position in zone
    zone_cx = zone_cx(ZONE_WIND_PATH);
    zone_cy = zone_cy(ZONE_WIND_PATH);  // ~153.5
    
    translate([zone_cx, zone_cy, 0])
    scale([WIND_SCALE, WIND_SCALE, 1])
    color(C_WIND)
    wind_path_shape(1);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot=0) {
    lh_w = zone_w(ZONE_LIGHTHOUSE);  // 9mm
    lh_h = zone_h(ZONE_LIGHTHOUSE);  // 52mm
    
    // Tower (tapered)
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
    
    // Rotating beam housing
    translate([0, 0, lh_h*0.75])
    rotate([0, 0, beam_rot])
    color("#333", 0.8)
    difference() {
        cylinder(r=lh_w/2*1.2, h=lh_h*0.1);
        // Beam slit
        translate([0, -1, -1])
        cube([lh_w*2, 2, lh_h*0.15]);
    }
    
    // Roof
    translate([0, 0, lh_h*0.87])
    color("#8b6914")
    cylinder(r1=lh_w/2*1.2, r2=lh_w/4, h=lh_h*0.13);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SWIRL DISC
// ═══════════════════════════════════════════════════════════════════════════════════
module swirl_disc(radius, rot=0, thickness=5) {
    rotate([0, 0, rot])
    color(C_SWIRL)
    difference() {
        cylinder(r=radius, h=thickness);
        // Center hole for shaft
        translate([0, 0, -1])
        cylinder(r=SHAFT_D/2 + 0.2, h=thickness+2);
        // Decorative spiral cutouts
        for (i = [0:5]) {
            rotate([0, 0, i*60])
            translate([radius*0.5, 0, -1])
            cylinder(r=radius*0.15, h=thickness+2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: MOON ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════
module moon_assembly(rot=0) {
    moon_r = min(zone_w(ZONE_MOON), zone_h(ZONE_MOON)) / 2 - 5;  // ~30mm
    
    // Glow halo
    color(C_MOON, 0.2)
    cylinder(r=moon_r + 10, h=2);
    
    // Inner moon disc
    translate([0, 0, 2])
    color(C_MOON)
    cylinder(r=moon_r * 0.7, h=5);
    
    // Rotating outer ring
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.8)
    difference() {
        cylinder(r=moon_r, h=5);
        translate([0, 0, -1])
        cylinder(r=moon_r * 0.75, h=7);
    }
    
    // Concentric ring details
    translate([0, 0, 3])
    rotate([0, 0, rot * 0.5])
    color(C_MOON, 0.6) {
        for (r = [moon_r*0.8, moon_r*0.9]) {
            difference() {
                cylinder(r=r+1, h=4);
                translate([0, 0, -1])
                cylinder(r=r-1, h=6);
                // Arc breaks
                for (a = [0:3]) {
                    rotate([0, 0, a*90+20])
                    translate([0, 0, -1])
                    cube([moon_r*1.5, 3, 6]);
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: WAVE LAYER (Simplified - within Y bounds)
// ═══════════════════════════════════════════════════════════════════════════════════
module cliff_wave_layer(layer_num, drift=0, surge=0) {
    // Constrained to ZONE_CLIFF_WAVES [108, 160, 0, 69]
    wave_w = zone_w(ZONE_CLIFF_WAVES);  // 52mm
    wave_h = zone_h(ZONE_CLIFF_WAVES) - 5;  // 64mm (margin from top)
    
    layer_colors = [C_WAVE_DARK, "#1f5578", "#246082", "#2a6a8c", C_WAVE_LIGHT];
    layer_offset = layer_num * 2;  // Progressively smaller
    
    translate([drift, surge, 0])
    color(layer_colors[min(layer_num, 4)])
    linear_extrude(height=5)
    offset(delta=-layer_offset)
    polygon([
        // Wave profile that stays within bounds
        [0, 0],
        [0, 8], [5, 8], [5, 0],     // Mounting teeth
        [10, 0], [10, 8], [15, 8], [15, 0],
        [20, 0],
        [25, 5], [30, 10],
        [35, 20], [38, 35],
        [40, 50], [42, wave_h - 5],  // Curl top (within bounds)
        [45, wave_h], [48, wave_h - 2],
        [wave_w - 5, wave_h * 0.5],
        [wave_w, wave_h * 0.3],
        [wave_w, 0]
    ]);
}

module ocean_wave_layer(layer_num, drift=0, surge=0) {
    // Constrained to ZONE_OCEAN_WAVES [151, 302, 0, 65]
    wave_w = zone_w(ZONE_OCEAN_WAVES);  // 151mm
    wave_h = zone_h(ZONE_OCEAN_WAVES) - 5;  // 60mm (margin)
    
    layer_colors = [C_WAVE_DARK, C_WAVE_MID, C_WAVE_LIGHT];
    layer_offset = layer_num * 3;
    
    translate([drift, surge, 0])
    color(layer_colors[min(layer_num, 2)])
    linear_extrude(height=5)
    offset(delta=-layer_offset)
    polygon([
        // Gentle undulating wave within bounds
        [0, 5],
        [20, 15], [40, 25], [60, wave_h * 0.6],
        [80, wave_h * 0.8], [100, wave_h],  // Peak
        [120, wave_h * 0.7], [140, wave_h * 0.5],
        [wave_w - 10, wave_h * 0.3],
        [wave_w, 10], [wave_w, 0],
        [100, 2], [50, 3], [0, 2]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: BOTTOM GEARS (Visible, Decorative)
// ═══════════════════════════════════════════════════════════════════════════════════
module bottom_gears_assembly(rot=0) {
    // Within ZONE_BOTTOM_GEARS [164, 302, 0, 30]
    zone_start_x = ZONE_BOTTOM_GEARS[0];
    
    // Crank wheel (visible, large)
    translate([zone_start_x + 20, 15, 0])
    rotate([0, 0, rot])
    gear(24, GEAR_MODULE, 6, 3, true);
    
    // Drive gears in sequence
    translate([zone_start_x + 55, 12, 0])
    rotate([0, 0, -rot * 1.2])
    gear(18, GEAR_MODULE, 5, 2);
    
    translate([zone_start_x + 85, 18, 2])
    rotate([0, 0, rot * 1.5])
    gear(14, GEAR_MODULE, 5, 2);
    
    translate([zone_start_x + 110, 10, 0])
    rotate([0, 0, -rot * 1.8])
    gear(12, GEAR_MODULE, 4, 1.5);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: SKY GEARS
// ═══════════════════════════════════════════════════════════════════════════════════
module sky_gears_assembly(rot=0) {
    // Within ZONE_SKY_GEARS [52, 216, 109, 166]
    cx = zone_cx(ZONE_SKY_GEARS);
    cy = zone_cy(ZONE_SKY_GEARS);
    
    // Central drive gear
    translate([cx, cy, 0])
    rotate([0, 0, rot])
    gear(20, GEAR_MODULE, 5, 2.5);
    
    // Satellite gears
    translate([cx - 35, cy + 15, 2])
    rotate([0, 0, -rot * 1.3])
    gear(16, GEAR_MODULE, 4, 2);
    
    translate([cx + 40, cy - 10, 2])
    rotate([0, 0, -rot * 1.1])
    gear(18, GEAR_MODULE, 4, 2);
    
    translate([cx + 70, cy + 5, 0])
    rotate([0, 0, rot * 1.5])
    gear(14, GEAR_MODULE, 4, 1.5);
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: BIRD WIRE TRACK
// ═══════════════════════════════════════════════════════════════════════════════════
module bird_wire_track() {
    // Within ZONE_BIRD_WIRE [0, 302, 130, 146]
    wire_y = zone_cy(ZONE_BIRD_WIRE);  // 138mm
    wire_r = 1;  // 12ga = ~2mm diameter
    
    color("#888")
    translate([0, wire_y, 0])
    rotate([0, 90, 0])
    cylinder(r=wire_r, h=CANVAS_W);
    
    // End loops
    color("#888") {
        translate([5, wire_y, 0])
        rotate([90, 0, 0])
        rotate_extrude(angle=180)
        translate([5, 0]) circle(r=wire_r);
        
        translate([CANVAS_W - 5, wire_y, 0])
        rotate([90, 0, 180])
        rotate_extrude(angle=180)
        translate([5, 0]) circle(r=wire_r);
    }
}

module bird(pos=0) {
    // Simple bird shape
    bird_x = 20 + pos * (CANVAS_W - 40);  // Move along track
    bird_y = zone_cy(ZONE_BIRD_WIRE);
    
    // Rotate 180° at ends
    bird_rot = pos < 0.1 ? pos * 10 * 180 : 
               pos > 0.9 ? (1 - pos) * 10 * 180 + 180 : 
               pos < 0.5 ? 0 : 180;
    
    translate([bird_x, bird_y, 5])
    rotate([0, 0, bird_rot])
    color("#333") {
        // Body
        scale([1, 0.5, 0.3])
        sphere(r=8);
        // Wings
        translate([0, 0, 2])
        scale([0.3, 1.5, 0.1])
        sphere(r=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: RICE TUBE (Sound Mechanism)
// ═══════════════════════════════════════════════════════════════════════════════════
module rice_tube(tilt=0) {
    // Position: behind bottom tab, centered
    tube_length = 200;
    tube_od = 20;
    tube_id = 16;
    
    // Center pivot with tilt
    translate([CANVAS_W/2, -12, 0])
    rotate([tilt, 0, 0])  // Tilt along X axis (right-up/left-down from viewer POV)
    translate([-tube_length/2, 0, 0])
    rotate([0, 90, 0])
    color(C_RICE_TUBE) {
        // Outer tube
        difference() {
            cylinder(r=tube_od/2, h=tube_length);
            translate([0, 0, 3])
            cylinder(r=tube_id/2, h=tube_length - 6);
        }
        
        // End caps (with holes for sound)
        cylinder(r=tube_od/2, h=3);
        translate([0, 0, tube_length - 3])
        cylinder(r=tube_od/2, h=3);
        
        // Internal spiral baffles (visible through translucent tube)
        color(C_RICE_TUBE, 0.5)
        for (z = [10:20:tube_length-10]) {
            translate([0, 0, z])
            linear_extrude(height=2, twist=45)
            difference() {
                circle(r=tube_id/2 - 0.5);
                circle(r=tube_id/2 - 3);
            }
        }
    }
    
    // Center pivot mount
    translate([CANVAS_W/2, -12, 0])
    color("#555") {
        cube([10, 5, 15], center=true);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: CAMSHAFT (Wave Drive)
// ═══════════════════════════════════════════════════════════════════════════════════
module camshaft(rot=0) {
    shaft_length = 180;
    cam_r = 5;
    lobe_offset = 3;
    
    // Main shaft
    color(C_SHAFT)
    rotate([0, 90, 0])
    cylinder(r=SHAFT_D/2, h=shaft_length);
    
    // Cam lobes (11 total: 5 cliff + 6 ocean, 30° phase each)
    for (i = [0:10]) {
        phase = i * 30;  // 30° phase shift each
        lobe_x = 10 + i * 15;
        
        translate([lobe_x, 0, 0])
        rotate([0, 90, 0])
        rotate([0, 0, rot + phase])
        color(C_GEAR) {
            // Eccentric cam
            translate([lobe_offset, 0, 0])
            cylinder(r=cam_r, h=8);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MODULE: DRIVE TRAIN
// ═══════════════════════════════════════════════════════════════════════════════════
module drive_train(rot=0) {
    // Horizontal drive shaft from motor
    shaft_length = CANVAS_W * 0.8;
    
    color(C_SHAFT)
    translate([40, 25, 0])
    rotate([0, 90, 0])
    cylinder(r=SHAFT_D/2, h=shaft_length);
    
    // Master gear (driven by motor)
    translate([45, 25, 0])
    rotate([0, 90, 0])
    rotate([0, 0, rot])
    gear(MASTER_GEAR_T, GEAR_MODULE, 8, SHAFT_D/2);
    
    // Worm gear (perpendicular axis for sky drive)
    translate([80, 25, 25])
    rotate([90, 0, 0])  // Perpendicular to main shaft
    rotate([0, 0, rot * WORM_WHEEL_T])
    worm_gear(25, 8, WORM_LEADS, rot);
    
    // Worm wheel (sky drive)
    translate([80, 25, 35])
    rotate([0, 0, rot])
    gear(WORM_WHEEL_T, GEAR_MODULE, 6, SHAFT_D/2);
    
    // Vertical shaft to sky mechanism
    color(C_SHAFT)
    translate([80, 25, 35])
    cylinder(r=SHAFT_D/2, h=40);
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
    
    // Label
    color(col)
    translate([zone_cx(zone), zone_cy(zone), 2])
    linear_extrude(height=0.5)
    text(name, size=6, halign="center", valign="center");
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────────────
// ENCLOSURE
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_ENCLOSURE) {
    enclosure();
}

if (SHOW_BACK_PANEL) {
    translate([0, 0, Z_BACK_PANEL])
    back_panel();
}

// ─────────────────────────────────────────────────────────────────────────────────────
// MOTOR & DRIVE TRAIN (Inside cliff area)
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_MOTOR) {
    translate([TAB_W + 25, TAB_W + 15, Z_MOTOR])
    rotate([0, 0, 0])
    motor_n20(motor_rot);
}

if (SHOW_DRIVE_TRAIN) {
    translate([TAB_W, TAB_W, Z_DRIVE_SHAFT])
    drive_train(master_rot);
}

if (SHOW_CAMSHAFT) {
    translate([TAB_W + ZONE_CLIFF_WAVES[0], TAB_W + 20, Z_CAMSHAFT])
    camshaft(wave_phase);
}

// ─────────────────────────────────────────────────────────────────────────────────────
// RICE TUBE (Behind bottom tab)
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_RICE_TUBE) {
    translate([TAB_W, TAB_W, Z_RICE_TUBE])
    rice_tube(rice_tilt);
}

// ─────────────────────────────────────────────────────────────────────────────────────
// SKY ELEMENTS
// ─────────────────────────────────────────────────────────────────────────────────────
// Moon
if (SHOW_MOON) {
    translate([TAB_W + zone_cx(ZONE_MOON), TAB_W + zone_cy(ZONE_MOON), Z_MOON])
    moon_assembly(moon_rot);
}

// Sky gears (behind wind path)
if (SHOW_SKY_GEARS) {
    translate([TAB_W, TAB_W, Z_SKY_GEARS_BACK])
    sky_gears_assembly(master_rot * 0.8);
}

// Swirl discs
if (SHOW_BIG_SWIRL) {
    big_swirl_r = min(zone_w(ZONE_BIG_SWIRL), zone_h(ZONE_BIG_SWIRL)) / 2 - 2;  // ~35mm
    translate([TAB_W + zone_cx(ZONE_BIG_SWIRL), TAB_W + zone_cy(ZONE_BIG_SWIRL), Z_SWIRL_BACK])
    swirl_disc(big_swirl_r, swirl_big_rot, 5);
    
    // Counter-rotating inner disc
    translate([TAB_W + zone_cx(ZONE_BIG_SWIRL), TAB_W + zone_cy(ZONE_BIG_SWIRL), Z_SWIRL_FRONT])
    swirl_disc(big_swirl_r * 0.7, -swirl_big_rot * 1.3, 4);
}

if (SHOW_SMALL_SWIRL) {
    small_swirl_r = min(zone_w(ZONE_SMALL_SWIRL), zone_h(ZONE_SMALL_SWIRL)) / 2 - 2;  // ~22mm
    translate([TAB_W + zone_cx(ZONE_SMALL_SWIRL), TAB_W + zone_cy(ZONE_SMALL_SWIRL), Z_SWIRL_BACK])
    swirl_disc(small_swirl_r, swirl_small_rot, 5);
    
    translate([TAB_W + zone_cx(ZONE_SMALL_SWIRL), TAB_W + zone_cy(ZONE_SMALL_SWIRL), Z_SWIRL_FRONT])
    swirl_disc(small_swirl_r * 0.7, -swirl_small_rot * 1.3, 4);
}

// Wind path panel
if (SHOW_WIND_PATH) {
    translate([TAB_W, TAB_W, Z_WIND_PATH])
    wind_path_traced();
}

// ─────────────────────────────────────────────────────────────────────────────────────
// BIRD WIRE
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_BIRD_WIRE) {
    translate([TAB_W, TAB_W, Z_BIRD_WIRE]) {
        bird_wire_track();
        bird(bird_pos);
        bird(fmod(bird_pos + 0.3, 1));  // Second bird offset
    }
}

// ─────────────────────────────────────────────────────────────────────────────────────
// CLIFF & LIGHTHOUSE
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_CLIFF) {
    translate([TAB_W, TAB_W, Z_CLIFF])
    cliff_traced();
}

if (SHOW_LIGHTHOUSE) {
    translate([TAB_W + zone_cx(ZONE_LIGHTHOUSE), TAB_W + ZONE_LIGHTHOUSE[2], Z_LIGHTHOUSE])
    lighthouse(motor_rot * 6);
}

// ─────────────────────────────────────────────────────────────────────────────────────
// BOTTOM GEARS
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_BOTTOM_GEARS) {
    translate([TAB_W, TAB_W, Z_BOTTOM_GEARS])
    bottom_gears_assembly(wave_phase);
}

// ─────────────────────────────────────────────────────────────────────────────────────
// WAVES
// ─────────────────────────────────────────────────────────────────────────────────────
wave_drift = 5 * sin(wave_phase);
wave_surge = 3 * sin(wave_phase);

if (SHOW_CLIFF_WAVES) {
    // 5 cliff wave layers within ZONE_CLIFF_WAVES
    for (i = [0:4]) {
        translate([TAB_W + ZONE_CLIFF_WAVES[0], TAB_W + ZONE_CLIFF_WAVES[2], Z_CLIFF_WAVES + i*5])
        cliff_wave_layer(i, 
            i > 0 && i < 4 ? wave_drift * (1 - i*0.15) : 0,
            i == 4 ? wave_surge : 0);
    }
}

if (SHOW_OCEAN_WAVES) {
    // 3 ocean wave layers within ZONE_OCEAN_WAVES
    for (i = [0:2]) {
        translate([TAB_W + ZONE_OCEAN_WAVES[0], TAB_W + ZONE_OCEAN_WAVES[2], Z_OCEAN_WAVES + i*5])
        ocean_wave_layer(i,
            i > 0 ? wave_drift * 0.8 : 0,
            i == 2 ? wave_surge * 0.5 : 0);
    }
}

// ─────────────────────────────────────────────────────────────────────────────────────
// CYPRESS (Frontmost element)
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_CYPRESS) {
    translate([TAB_W, TAB_W, Z_CYPRESS])
    cypress_traced();
}

// ─────────────────────────────────────────────────────────────────────────────────────
// DEBUG: Zone outlines
// ─────────────────────────────────────────────────────────────────────────────────────
if (SHOW_ZONE_OUTLINES) {
    translate([TAB_W, TAB_W, 75]) {
        zone_outline(ZONE_CLIFF, "CLIFF", "#8B4513");
        zone_outline(ZONE_LIGHTHOUSE, "LH", "#FFD700");
        zone_outline(ZONE_CYPRESS, "CYP", "#228B22");
        zone_outline(ZONE_CLIFF_WAVES, "CW", "#4169E1");
        zone_outline(ZONE_OCEAN_WAVES, "OW", "#1E90FF");
        zone_outline(ZONE_BOTTOM_GEARS, "BG", "#FF8C00");
        zone_outline(ZONE_WIND_PATH, "WIND", "#9370DB");
        zone_outline(ZONE_BIG_SWIRL, "BS", "#FF00FF");
        zone_outline(ZONE_SMALL_SWIRL, "SS", "#FF69B4");
        zone_outline(ZONE_MOON, "MOON", "#FFD700");
        zone_outline(ZONE_SKY_GEARS, "SG", "#FFA500");
        zone_outline(ZONE_BIRD_WIRE, "BIRD", "#696969");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════
//                         DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V39 - COMPLETE MECHANICAL KINETIC ART");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("CANVAS:");
echo("  Total size:", TOTAL_W, "×", TOTAL_H, "×", TOTAL_D, "mm");
echo("  Art area:", CANVAS_W, "×", CANVAS_H, "mm");
echo("  Wall thickness:", WALL_T, "mm");
echo("  Mounting tabs:", TAB_W, "mm");
echo("");
echo("TRACED SHAPES:");
echo("  Cliff scale:", CLIFF_SCALE);
echo("  Cypress scale:", CYPRESS_SCALE);
echo("  Wind path scale:", WIND_SCALE);
echo("");
echo("MECHANICAL:");
echo("  Motor: N20", MOTOR_RPM, "RPM");
echo("  Master ratio:", MASTER_RATIO, ":1");
echo("  Shaft diameter:", SHAFT_D, "mm");
echo("  Bearings: 683ZZ (", BEARING_ID, "×", BEARING_OD, "×", BEARING_H, "mm)");
echo("");
echo("ANIMATION: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════");
