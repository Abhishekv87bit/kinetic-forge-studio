// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V27.2 - MAIN ASSEMBLY
// Layout based on pic_4
// Cypress tree from pic_3 (multi-layer 2D cutouts)
// Gears ONLY under cliff
// ═══════════════════════════════════════════════════════════════════════════
$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
W = 350;            // Total width
H = 275;            // Total height  
D = 80;             // Total depth
FW = 20;            // Frame width
IW = W - FW*2;      // Inner width (310mm)
IH = H - FW*2;      // Inner height (235mm)

LAYER_T = 5;        // Standard layer thickness

// Animation
t = $t;
swirl_rot_cw = t * 360 * 0.5;
swirl_rot_ccw = -t * 360 * 0.7;
moon_rot = t * 360 * 0.3;
wave_phase = t * 360;
wave_drift = 8 * sin(t * 360);
wave_surge = 6 * sin(t * 360);
lighthouse_rot = t * 360 * 6;
gear_rot = t * 360 * 0.4;

// Colors
C_FRAME = "#5a4030";
C_GEAR = "#8b7355";      // Dark brass (pic_4 shows darker gears)
C_SKY = "#1a3a6e";
C_WIND = "#2a5a9e";
C_WAVE_DARK = "#1a4a6e";
C_WAVE_MID = "#2a6a8e";
C_WAVE_LIGHT = "#4a8aae";
C_FOAM = "#ffffff";
C_CLIFF = "#6b5344";
C_CYPRESS = "#1a3a1a";   // Very dark green
C_CYPRESS_LIGHT = "#2a4a2a";
C_LIGHTHOUSE = "#c4b498";
C_MOON = "#f0d060";

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════
Z_BACK = 0;
Z_GEARS_BACK = 5;       // Gears behind cliff
Z_SWIRL_DISCS = 10;     // Swirl disc mechanisms
Z_WIND_PANEL = 18;      // Wind path panel
Z_CLIFF = 22;           // Cliff
Z_LIGHTHOUSE = 25;      // Lighthouse (on cliff)
Z_WAVES_START = 30;     // Wave layers start
Z_GEARS_FRONT = 35;     // Some gears in front of cliff base
Z_CYPRESS = 55;         // Cypress IN FRONT of lighthouse and waves
Z_MOON = 15;            // Moon (in sky area, right side)
Z_FRAME = 70;

// ═══════════════════════════════════════════════════════════════════════════
// GEAR MODULE (Dark brass like pic_4)
// ═══════════════════════════════════════════════════════════════════════════
module gear(teeth, radius, thickness=4, hole_r=3) {
    tooth_h = radius * 0.15;
    color(C_GEAR)
    difference() {
        union() {
            // Main body
            cylinder(r=radius-tooth_h, h=thickness);
            // Teeth
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([radius-tooth_h, 0, 0])
                cylinder(r=tooth_h*1.2, h=thickness, $fn=6);
            }
        }
        // Center hole
        translate([0, 0, -1])
        cylinder(r=hole_r, h=thickness+2);
        
        // Spoke cutouts (for larger gears)
        if (radius > 20) {
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                translate([radius*0.55, 0, -1])
                cylinder(r=radius*0.22, h=thickness+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// DECORATIVE GEARS - ONLY UNDER CLIFF (per pic_4)
// ═══════════════════════════════════════════════════════════════════════════
module cliff_gears(rot) {
    // Based on pic_4: Large gears behind/under cliff on left side
    // Various sizes, some partially hidden by cliff
    
    // Large gear (back, partially behind cliff)
    translate([-10, IH*0.12, Z_GEARS_BACK])
    rotate([0, 0, rot])
    gear(32, 38, 5, 8);
    
    // Medium-large gear
    translate([25, IH*0.05, Z_GEARS_BACK])
    rotate([0, 0, -rot * 0.8])
    gear(28, 32, 5, 7);
    
    // Medium gear (upper left)
    translate([5, IH*0.28, Z_GEARS_BACK + 2])
    rotate([0, 0, rot * 1.2])
    gear(24, 28, 4, 6);
    
    // Medium gear
    translate([40, IH*0.18, Z_GEARS_BACK + 3])
    rotate([0, 0, -rot * 1.1])
    gear(22, 25, 4, 5);
    
    // Smaller gears
    translate([15, IH*0.38, Z_GEARS_FRONT])
    rotate([0, 0, rot * 1.5])
    gear(18, 20, 4, 4);
    
    translate([50, IH*0.08, Z_GEARS_FRONT + 2])
    rotate([0, 0, -rot * 1.8])
    gear(16, 18, 3, 4);
    
    translate([-5, IH*0.02, Z_GEARS_BACK + 4])
    rotate([0, 0, rot * 2])
    gear(20, 22, 4, 5);
    
    // Small accent gears
    translate([35, IH*0.32, Z_GEARS_FRONT + 3])
    rotate([0, 0, -rot * 2.2])
    gear(14, 15, 3, 3);
    
    translate([55, IH*0.22, Z_GEARS_FRONT + 4])
    rotate([0, 0, rot * 2.5])
    gear(12, 13, 3, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVE MECHANISM GEARS (Right corner, per pic_4)
// ═══════════════════════════════════════════════════════════════════════════
module wave_mechanism_gears(rot) {
    // Visible gear cluster in lower-right corner
    translate([IW*0.78, 15, Z_WAVES_START + 20])
    {
        rotate([0, 0, rot])
        gear(26, 30, 5, 6);
        
        translate([38, -18, 0])
        rotate([0, 0, -rot * 1.15])
        gear(22, 25, 5, 5);
        
        translate([25, 25, 0])
        rotate([0, 0, -rot * 0.87])
        gear(20, 22, 4, 4);
        
        translate([60, 8, 2])
        rotate([0, 0, rot * 1.4])
        gear(16, 18, 4, 4);
        
        translate([48, -32, 2])
        rotate([0, 0, rot * 1.8])
        gear(12, 13, 3, 3);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF (Based on pic_4 - takes up left ~25% of width)
// ═══════════════════════════════════════════════════════════════════════════
module cliff() {
    cliff_width = IW * 0.28;  // ~87mm
    
    color(C_CLIFF)
    linear_extrude(height=18)
    polygon([
        [0, 0],
        [0, IH * 0.52],      // Cliff top height
        [cliff_width * 0.15, IH * 0.55],
        [cliff_width * 0.35, IH * 0.53],
        [cliff_width * 0.55, IH * 0.48],
        [cliff_width * 0.75, IH * 0.42],
        [cliff_width * 0.90, IH * 0.35],
        [cliff_width, IH * 0.28],
        [cliff_width * 0.95, IH * 0.18],
        [cliff_width * 0.85, IH * 0.10],
        [cliff_width * 0.70, IH * 0.05],
        [cliff_width * 0.50, IH * 0.02],
        [cliff_width * 0.25, IH * 0.01],
        [0, 0]
    ]);
    
    // Texture layers
    color("#5a4334")
    for (i = [0:4]) {
        translate([10 + i*12, IH * 0.08 + i*IH*0.06, 18])
        linear_extrude(height=3)
        scale([1.5, 0.4])
        circle(r=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE (On cliff, per pic_4)
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    // Tower
    color(C_LIGHTHOUSE)
    linear_extrude(height=55, scale=0.7)
    circle(r=10);
    
    // Stripes
    color("#8b6914")
    for (z = [10, 25, 40]) {
        translate([0, 0, z])
        linear_extrude(height=6)
        circle(r=9 - z*0.05);
    }
    
    // Platform
    translate([0, 0, 55])
    color("#333") cylinder(r=12, h=3);
    
    // Lamp room
    translate([0, 0, 58])
    color("LightYellow", 0.5)
    difference() {
        cylinder(r=9, h=12);
        translate([0, 0, 2])
        cylinder(r=8, h=12);
    }
    
    // Light source
    translate([0, 0, 63])
    color("Yellow", 0.9) sphere(r=4);
    
    // Rotating beam slit
    translate([0, 0, 60])
    rotate([0, 0, beam_rot])
    color("#333", 0.8)
    difference() {
        cylinder(r=10, h=8);
        linear_extrude(height=10)
        polygon([[0, 0], [15, -2.5], [15, 2.5]]);
    }
    
    // Roof
    translate([0, 0, 70])
    color("#8b6914")
    cylinder(r1=11, r2=3, h=10);
    
    // Keeper's hut (at base)
    translate([15, -6, 0])
    color(C_LIGHTHOUSE) {
        cube([18, 14, 12]);
        translate([0, 7, 12])
        rotate([90, 0, 90])
        linear_extrude(height=18)
        polygon([[0, 0], [7, 6], [14, 0]]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS TREE (From pic_3 - Multi-layer 2D cutouts)
// Tall, narrow, flame-like shape with Van Gogh swirling texture
// IN FRONT of lighthouse (closest to viewer)
// ═══════════════════════════════════════════════════════════════════════════
module cypress_layer(layer_num, total_layers=4) {
    // Each layer is slightly different, creating depth
    // Shape based on pic_3: tall, narrow, flame-like with swirling edges
    
    offset_amount = layer_num * 2;  // Each layer slightly inset
    height_scale = 1 - layer_num * 0.03;
    
    // Cypress total height ~120mm (very tall, prominent)
    h = 120 * height_scale;
    w_base = 25 - layer_num * 2;
    
    color(layer_num % 2 == 0 ? C_CYPRESS : C_CYPRESS_LIGHT)
    linear_extrude(height=LAYER_T)
    translate([offset_amount, 0])
    scale([1 - layer_num*0.05, height_scale])
    polygon([
        // Base
        [-w_base/2, 0],
        
        // Left edge (swirling flame shape from pic_3)
        [-w_base*0.6, h*0.08],
        [-w_base*0.7, h*0.15],
        [-w_base*0.65, h*0.22],
        [-w_base*0.75, h*0.30],
        [-w_base*0.7, h*0.38],
        [-w_base*0.6, h*0.45],
        [-w_base*0.65, h*0.52],
        [-w_base*0.55, h*0.60],
        [-w_base*0.5, h*0.68],
        [-w_base*0.4, h*0.75],
        [-w_base*0.35, h*0.82],
        [-w_base*0.25, h*0.88],
        [-w_base*0.15, h*0.94],
        
        // Top point
        [0, h],
        
        // Right edge (mirror of left, slightly different)
        [w_base*0.12, h*0.95],
        [w_base*0.22, h*0.88],
        [w_base*0.32, h*0.82],
        [w_base*0.38, h*0.75],
        [w_base*0.48, h*0.68],
        [w_base*0.52, h*0.60],
        [w_base*0.62, h*0.52],
        [w_base*0.58, h*0.45],
        [w_base*0.68, h*0.38],
        [w_base*0.72, h*0.30],
        [w_base*0.62, h*0.22],
        [w_base*0.68, h*0.15],
        [w_base*0.58, h*0.08],
        
        // Back to base
        [w_base/2, 0]
    ]);
}

module cypress_tree() {
    // Multi-layer cypress (4 layers for depth, per user request)
    // Each layer at different Z depth
    for (i = [0:3]) {
        translate([0, 0, i * (LAYER_T + 1)])
        cypress_layer(i, 4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH PANEL (From pic_5 - left to mid)
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_panel() {
    // Dimensions: starts left, ends just past middle
    panel_w = IW * 0.62;  // ~192mm
    panel_h = IH * 0.45;  // ~106mm
    ribbon_w = 20;
    
    // Hole positions
    large_x = panel_w * 0.55;
    large_y = panel_h * 0.50;
    large_r = 35;
    
    small_x = panel_w * 0.85;
    small_y = panel_h * 0.40;
    small_r = 22;
    
    color(C_WIND)
    linear_extrude(height=LAYER_T)
    difference() {
        union() {
            // Left tail (wide, flowing)
            hull() {
                translate([0, panel_h * 0.75]) 
                scale([1.5, 1]) circle(r=ribbon_w);
                translate([panel_w * 0.08, panel_h * 0.85]) 
                circle(r=ribbon_w * 0.9);
            }
            hull() {
                translate([0, panel_h * 0.75]) 
                scale([1.5, 1]) circle(r=ribbon_w);
                translate([panel_w * 0.05, panel_h * 0.50]) 
                circle(r=ribbon_w * 0.8);
            }
            
            // Curve down then toward large hole
            hull() {
                translate([panel_w * 0.05, panel_h * 0.50]) 
                circle(r=ribbon_w * 0.8);
                translate([panel_w * 0.18, panel_h * 0.35]) 
                circle(r=ribbon_w * 0.7);
            }
            hull() {
                translate([panel_w * 0.18, panel_h * 0.35]) 
                circle(r=ribbon_w * 0.7);
                translate([large_x - large_r - ribbon_w*0.4, large_y - ribbon_w*0.3]) 
                circle(r=ribbon_w * 0.65);
            }
            
            // Wrap large hole
            translate([large_x, large_y])
            difference() {
                circle(r=large_r + ribbon_w * 0.9);
                circle(r=large_r);
            }
            
            // Connect to small hole
            hull() {
                translate([large_x + large_r + ribbon_w*0.2, large_y - ribbon_w*0.2]) 
                circle(r=ribbon_w * 0.5);
                translate([small_x - small_r - ribbon_w*0.2, small_y + ribbon_w*0.1]) 
                circle(r=ribbon_w * 0.45);
            }
            
            // Wrap small hole
            translate([small_x, small_y])
            difference() {
                circle(r=small_r + ribbon_w * 0.7);
                circle(r=small_r);
            }
            
            // Right tail (thin)
            hull() {
                translate([small_x + small_r + ribbon_w*0.15, small_y - ribbon_w*0.1]) 
                circle(r=ribbon_w * 0.4);
                translate([panel_w * 0.98, panel_h * 0.45]) 
                circle(r=ribbon_w * 0.3);
            }
        }
        
        // Cut holes
        translate([large_x, large_y]) circle(r=large_r);
        translate([small_x, small_y]) circle(r=small_r);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIRL DISC (Rotates inside wind path holes)
// ═══════════════════════════════════════════════════════════════════════════
module swirl_disc(radius, rot) {
    rotate([0, 0, rot])
    color("#4a7ab0", 0.9)
    difference() {
        cylinder(r=radius, h=LAYER_T);
        translate([0, 0, -1])
        cylinder(r=radius*0.12, h=LAYER_T+2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON (Right side, high up - per pic_4)
// Concentric yellow rings
// ═══════════════════════════════════════════════════════════════════════════
module moon_assembly(rot) {
    // Moon position: right side, high up
    // Large with concentric painted rings (from pic_4)
    
    // Glow
    color(C_MOON, 0.3)
    cylinder(r=50, h=2);
    
    // Inner moon
    translate([0, 0, 2])
    color(C_MOON)
    cylinder(r=30, h=LAYER_T);
    
    // Outer rotating ring with concentric pattern
    translate([0, 0, 2])
    rotate([0, 0, rot])
    color(C_MOON, 0.7) {
        difference() {
            cylinder(r=48, h=LAYER_T);
            translate([0, 0, -1])
            cylinder(r=35, h=LAYER_T+2);
        }
        
        // Concentric ring details
        for (r = [38, 42, 46]) {
            difference() {
                cylinder(r=r+1.5, h=LAYER_T+1);
                translate([0, 0, -1])
                cylinder(r=r, h=LAYER_T+3);
                // Break into arcs
                for (a = [0:3]) {
                    rotate([0, 0, a*90 + 15])
                    translate([0, 0, -1])
                    cube([60, 4, LAYER_T+3]);
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVE LAYERS (Cliff-facing: 5 layers, Ocean: 3 layers)
// ═══════════════════════════════════════════════════════════════════════════

// Cliff wave base shape
module cliff_wave_shape(scale_f=1.0) {
    scale([scale_f, scale_f])
    polygon([
        [0, 0], [0, 8], [5, 8], [5, 0],
        [10, 0], [10, 8], [15, 8], [15, 0],
        [20, 0], [20, 8], [25, 8], [25, 0],
        [30, 0],
        [30, 12], [28, 30], [28, 50], [32, 65], [40, 75],
        [55, 70], [70, 62], [85, 52], [100, 40], [112, 28],
        [120, 18], [120, 5], [100, 3], [70, 2], [40, 2]
    ]);
}

module cliff_wave_layer(layer_num, drift=0) {
    colors = [C_WAVE_DARK, "#1f5578", "#246082", "#2a6a8c", C_FOAM];
    
    translate([drift * (layer_num > 0 && layer_num < 4 ? 1 : 0), 0, 0])
    color(colors[layer_num])
    linear_extrude(height=LAYER_T)
    offset(delta = -layer_num * 1.5)
    cliff_wave_shape(1.0 - layer_num * 0.02);
}

// Ocean wave layers
module ocean_wave_base() {
    color(C_WAVE_DARK)
    linear_extrude(height=LAYER_T)
    polygon([
        [0, 0], [0, 15],
        [20, 25], [50, 32], [80, 36], [110, 38],
        [140, 36], [170, 38], [200, 35], [230, 25], [250, 15],
        [250, 0], [200, 3], [150, 5], [100, 5], [50, 3]
    ]);
}

module ocean_wave_swell(drift=0) {
    translate([drift, 0, 0])
    color(C_WAVE_MID)
    linear_extrude(height=LAYER_T)
    polygon([
        [10, 15], [30, 30], [60, 42], [90, 48], [115, 45],
        [140, 42], [165, 48], [195, 45], [225, 32], [245, 20],
        [240, 18], [210, 28], [180, 38], [150, 35], [120, 38],
        [90, 40], [60, 35], [30, 25], [15, 15]
    ]);
}

module ocean_wave_crest(surge=0) {
    translate([0, surge, 0])
    color(C_WAVE_LIGHT)
    linear_extrude(height=LAYER_T) {
        // C-shape curl
        polygon([
            [45, 35], [60, 52], [80, 65], [100, 70], [118, 65],
            [130, 55], [135, 42], [128, 48], [115, 55], [95, 55],
            [75, 48], [58, 38], [48, 32]
        ]);
        // Secondary curl
        translate([140, 0])
        polygon([
            [25, 32], [40, 48], [60, 55], [78, 50], [85, 40],
            [78, 45], [60, 48], [42, 42], [30, 32]
        ]);
        // Foam tips
        translate([105, 72]) circle(r=5);
        translate([115, 68]) circle(r=4);
        translate([200, 52]) circle(r=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FRAME
// ═══════════════════════════════════════════════════════════════════════════
module frame() {
    color(C_FRAME)
    difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1])
        cube([IW, IH, 12]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// Back panel
color(C_SKY, 0.5)
translate([FW, FW, Z_BACK])
cube([IW, IH, 3]);

// Gears ONLY under cliff (left side)
translate([FW, FW, 0])
cliff_gears(gear_rot);

// Swirl discs (behind wind panel)
// Large swirl
translate([FW + IW*0.62*0.55, FW + IH*0.40 + IH*0.45*0.50, Z_SWIRL_DISCS]) {
    swirl_disc(33, swirl_rot_ccw);
    translate([0, 0, LAYER_T+1])
    swirl_disc(30, swirl_rot_cw);
}

// Small swirl  
translate([FW + IW*0.62*0.85, FW + IH*0.40 + IH*0.45*0.40, Z_SWIRL_DISCS]) {
    swirl_disc(20, swirl_rot_cw);
    translate([0, 0, LAYER_T+1])
    swirl_disc(18, swirl_rot_ccw);
}

// Wind path panel
translate([FW, FW + IH*0.40, Z_WIND_PANEL])
wind_path_panel();

// Moon (right side, high up)
translate([FW + IW*0.85, FW + IH*0.78, Z_MOON])
moon_assembly(moon_rot);

// Cliff
translate([FW, FW, Z_CLIFF])
cliff();

// Lighthouse (on cliff)
translate([FW + IW*0.12, FW + IH*0.48, Z_LIGHTHOUSE])
rotate([-90, 0, 0])
lighthouse(lighthouse_rot);

// Cliff-facing waves (5 layers) - positioned next to cliff
for (i = [0:4]) {
    translate([FW + IW*0.25, FW + 5, Z_WAVES_START + i*LAYER_T])
    cliff_wave_layer(i, i > 0 && i < 4 ? wave_drift : 0);
}

// Ocean waves (3 layers) - to the right
translate([FW + IW*0.42, FW + 8, Z_WAVES_START]) {
    ocean_wave_base();
    translate([0, 0, LAYER_T])
    ocean_wave_swell(wave_drift * 0.7);
    translate([0, 0, LAYER_T*2])
    ocean_wave_crest(wave_surge);
}

// Wave mechanism gears (right corner)
wave_mechanism_gears(wave_phase);

// Cypress tree (IN FRONT of lighthouse - most forward element)
translate([FW + IW*0.08, FW + IH*0.32, Z_CYPRESS])
cypress_tree();

// Frame
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
// DEBUG INFO
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V27.2 - MAIN ASSEMBLY");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "×", D, "mm");
echo("");
echo("LAYOUT (from pic_4):");
echo("  Wind path: Left to 62% width");
echo("  Moon: Right side at 85% width, 78% height");
echo("  Cliff: Left 28% of width");
echo("  Gears: ONLY under cliff");
echo("  Cypress: Z=", Z_CYPRESS, "(in front of all)");
echo("");
echo("Animation time:", t);
echo("═══════════════════════════════════════════════════════════════════════");
