// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V38 - LOCKED ELEMENT OUTLINES
// Each element MUST fit within its designated zone boundary
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// SELF-CONTAINED ASSEMBLY - No external files required
// All shapes defined inline with traced coordinates

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
TOTAL_W = 350;
TOTAL_H = 250;
TAB = 24;
CANVAS_W = 302;  // Inner canvas width
CANVAS_H = 202;  // Inner canvas height

// ═══════════════════════════════════════════════════════════════════════════
// LOCKED ZONE DEFINITIONS - IMMUTABLE
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// ═══════════════════════════════════════════════════════════════════════════
ZONE_CLIFF       = [0, 108, 0, 65];
ZONE_LIGHTHOUSE  = [73, 82, 65, 117];
ZONE_CYPRESS     = [35, 95, 0, 121];
ZONE_CLIFF_WAVES = [108, 160, 0, 69];
ZONE_OCEAN_WAVES = [151, 302, 0, 65];
ZONE_BOTTOM_GEARS= [164, 302, 0, 30];
ZONE_WIND_PATH   = [0, 198, 105, 202];
ZONE_BIG_SWIRL   = [86, 160, 110, 170];
ZONE_SMALL_SWIRL = [151, 198, 105, 154];  // UPDATED: Y=105-154
ZONE_MOON        = [231, 300, 141, 202];
ZONE_STARS       = [0, 198, 101, 202];
ZONE_SKY_GEARS   = [52, 216, 109, 166];
ZONE_BIRD_WIRE   = [0, 302, 81, 97];

// Helper functions
function zone_w(z) = z[1] - z[0];
function zone_h(z) = z[3] - z[2];
function zone_cx(z) = (z[0] + z[1]) / 2;
function zone_cy(z) = (z[2] + z[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS (Back → Front)
// ═══════════════════════════════════════════════════════════════════════════
Z_BACK          = 0;
Z_SKY           = 2;
Z_MOON_HALO2    = 5;
Z_MOON_HALO1    = 8;
Z_MOON_CORE     = 10;
Z_STARS         = 15;
Z_WIND_PATH     = 20;
Z_BIG_SWIRL     = 22;
Z_SMALL_SWIRL   = 24;
Z_CLIFF         = 32;
Z_LIGHTHOUSE    = 35;
Z_CLIFF_WAVE_L1 = 40;
Z_CLIFF_WAVE_L2 = 43;
Z_CLIFF_WAVE_L3 = 46;
Z_OCEAN_WAVE_L1 = 42;
Z_OCEAN_WAVE_L2 = 45;
Z_OCEAN_WAVE_L3 = 48;
Z_BOTTOM_GEARS  = 38;
Z_CYPRESS       = 55;
Z_SKY_GEARS     = 58;
Z_BIRD_WIRE     = 62;
Z_FRAME         = 70;

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════
t = $t;
swirl_big_rot   = t * 360 * 0.3;
swirl_small_rot = -t * 360 * 0.5;
moon_phase      = t;
wave_phase      = t * 360;
wave_drift      = 5 * sin(wave_phase);
wave_surge      = 4 * sin(wave_phase);
lighthouse_rot  = t * 360 * 2;
gear_rot        = t * 360 * 0.4;

// ═══════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_SKY       = "#1a3a6e";
C_FRAME     = "#5a4030";
C_CLIFF     = "#5a4a3a";
C_WAVE_DARK = "#1a4a6e";
C_WAVE_MID  = "#2a6a8e";
C_WAVE_LITE = "#4a8aae";
C_FOAM      = "#ffffff";
C_CYPRESS   = "#1a3a1a";
C_WIND      = "#2a5a9e";
C_MOON      = "#f0d060";
C_MOON_HALO = "#c4a040";
C_GEAR      = "#8b7355";

// ═══════════════════════════════════════════════════════════════════════════
// ELEMENT SCALING CALCULATIONS
// Each element is scaled to fit WITHIN its designated zone
// ═══════════════════════════════════════════════════════════════════════════

// CYPRESS: Original ~30×130mm, Zone 60×121mm
// Scale to fit height: 121/130 = 0.93 (height is limiting factor)
CYPRESS_ORIG_W = 30;
CYPRESS_ORIG_H = 130;
CYPRESS_SCALE = min(zone_w(ZONE_CYPRESS)/CYPRESS_ORIG_W, 
                    zone_h(ZONE_CYPRESS)/CYPRESS_ORIG_H) * 0.95;  // 5% margin

// CLIFF_WAVES: Original traced ~130×98mm, Zone 52×69mm
// Scale: min(52/130, 69/98) = min(0.4, 0.7) = 0.4
CLIFF_WAVE_ORIG_W = 130;
CLIFF_WAVE_ORIG_H = 98;
CLIFF_WAVE_SCALE = min(zone_w(ZONE_CLIFF_WAVES)/CLIFF_WAVE_ORIG_W,
                       zone_h(ZONE_CLIFF_WAVES)/CLIFF_WAVE_ORIG_H) * 0.9;

// OCEAN_WAVES: Original traced ~260×65mm, Zone 151×65mm
// Scale: min(151/260, 65/65) = min(0.58, 1.0) = 0.58
OCEAN_WAVE_ORIG_W = 260;
OCEAN_WAVE_ORIG_H = 65;
OCEAN_WAVE_SCALE = min(zone_w(ZONE_OCEAN_WAVES)/OCEAN_WAVE_ORIG_W,
                       zone_h(ZONE_OCEAN_WAVES)/OCEAN_WAVE_ORIG_H) * 0.9;

// WIND_PATH: Original 192×60mm, Zone 198×97mm
// Scale: min(198/192, 97/60) = min(1.03, 1.62) = 1.03
WIND_PATH_ORIG_W = 192;
WIND_PATH_ORIG_H = 60;
WIND_PATH_SCALE = min(zone_w(ZONE_WIND_PATH)/WIND_PATH_ORIG_W,
                      zone_h(ZONE_WIND_PATH)/WIND_PATH_ORIG_H) * 0.95;

// SWIRL DISCS: Must fit within their zones
BIG_SWIRL_R   = min(zone_w(ZONE_BIG_SWIRL), zone_h(ZONE_BIG_SWIRL)) / 2 - 2;
SMALL_SWIRL_R = min(zone_w(ZONE_SMALL_SWIRL), zone_h(ZONE_SMALL_SWIRL)) / 2 - 2;

// MOON: Zone 69×61mm - use smaller dimension for diameter
MOON_R = min(zone_w(ZONE_MOON), zone_h(ZONE_MOON)) / 2 - 3;

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: FRAME
// ═══════════════════════════════════════════════════════════════════════════
module frame() {
    color(C_FRAME)
    difference() {
        cube([TOTAL_W, TOTAL_H, 10]);
        translate([TAB, TAB, -1])
        cube([CANVAS_W, CANVAS_H, 12]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: SKY BACKGROUND
// ═══════════════════════════════════════════════════════════════════════════
module sky_background() {
    color(C_SKY)
    cube([CANVAS_W, CANVAS_H, 2]);
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: CLIFF - LOCKED TO ZONE_CLIFF
// Zone: X=0-108, Y=0-65
// ═══════════════════════════════════════════════════════════════════════════
module cliff_locked() {
    color(C_CLIFF)
    linear_extrude(height=8)
    polygon([
        [ZONE_CLIFF[0], ZONE_CLIFF[2]],  // Bottom-left: (0, 0)
        [ZONE_CLIFF[1] * 0.7, ZONE_CLIFF[2]],  // 75.6, 0
        [ZONE_CLIFF[1], ZONE_CLIFF[3] * 0.3],  // 108, 19.5 (right side, low)
        [ZONE_CLIFF[1] * 0.85, ZONE_CLIFF[3] * 0.5],  // 91.8, 32.5
        [ZONE_CLIFF[1] * 0.75, ZONE_CLIFF[3]],  // 81, 65 (top-right)
        [ZONE_CLIFF[0], ZONE_CLIFF[3]]   // Top-left: (0, 65)
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: LIGHTHOUSE - LOCKED TO ZONE_LIGHTHOUSE
// Zone: X=73-82, Y=65-117
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse_locked() {
    lh_x = zone_cx(ZONE_LIGHTHOUSE);
    lh_y = ZONE_LIGHTHOUSE[2];  // Base at Y=65
    lh_h = zone_h(ZONE_LIGHTHOUSE);  // Height = 52mm
    lh_w = zone_w(ZONE_LIGHTHOUSE);  // Width = 9mm
    
    translate([lh_x, lh_y, 0])
    rotate([-90, 0, 0]) {
        // Tower
        color("Ivory")
        cylinder(r1=lh_w/2, r2=lh_w/2.5, h=lh_h * 0.85);
        
        // Stripes
        color("DarkRed")
        for (z=[lh_h*0.2, lh_h*0.45, lh_h*0.7])
            translate([0, 0, z])
            cylinder(r=lh_w/2 - 0.5, h=lh_h*0.08);
        
        // Lantern room
        translate([0, 0, lh_h * 0.85]) {
            color("DarkGray")
            cylinder(r=lh_w/2, h=2);
            
            color("Yellow")
            translate([0, 0, 2])
            cylinder(r=lh_w/3, h=lh_h*0.08);
            
            // Rotating beam
            color("Chrome")
            translate([0, 0, 4])
            rotate([0, 0, lighthouse_rot])
            difference() {
                cylinder(r=lh_w/2.2, h=3);
                cylinder(r=lh_w/4, h=4);
                for (i=[0:1])
                    rotate([0, 0, i*180])
                    translate([lh_w/4, 0, 1])
                    cube([lh_w/2, 1, 3], center=true);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: CYPRESS - LOCKED TO ZONE_CYPRESS
// Zone: X=35-95, Y=0-121
// Original shape centered at origin, ~30mm wide, 130mm tall
// ═══════════════════════════════════════════════════════════════════════════
module cypress_locked() {
    cx = zone_cx(ZONE_CYPRESS);  // Center X = 65
    cy = ZONE_CYPRESS[2];        // Base Y = 0
    
    // Cypress original bounds: X=-15 to +15, Y=0 to 130
    // Scale to fit: 121/130 = 0.93
    s = 0.93;
    
    translate([cx, cy, 0])
    scale([s, s, 1])
    cypress_layers();
}

module cypress_layers() {
    for (layer=[0:3]) {
        inset = layer * 2;
        translate([0, 0, layer * 5])
        color(layer % 2 == 0 ? "#1a3a1a" : "#2a4a2a")
        linear_extrude(height=5)
        offset(delta=-inset)
        polygon([
            [-4, 0], [-5, 8],
            [-9, 15], [-7, 22], [-11, 30], [-8, 38],
            [-13, 48], [-9, 55], [-14, 65], [-10, 72],
            [-15, 82], [-11, 90], [-13, 98], [-9, 105],
            [-11, 112], [-7, 118], [-9, 122], [-5, 126],
            [-3, 128],
            [0, 130],
            [3, 128], [5, 126], [9, 122], [7, 118],
            [11, 112], [9, 105], [13, 98], [11, 90],
            [15, 82], [10, 72], [14, 65], [9, 55],
            [13, 48], [8, 38], [11, 30], [7, 22],
            [9, 15], [5, 8], [4, 0]
        ]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: CLIFF WAVES - LOCKED TO ZONE_CLIFF_WAVES
// Zone: X=108-160, Y=0-69
// Original ~130×98mm, need scale ~0.4
// ═══════════════════════════════════════════════════════════════════════════
module cliff_waves_locked() {
    s = 0.4;  // Scale to fit zone
    translate([ZONE_CLIFF_WAVES[0] + 2, ZONE_CLIFF_WAVES[2], 0])
    scale([s, s, 1]) {
        // Layer 1 (base)
        translate([0, wave_drift, Z_CLIFF_WAVE_L1 - Z_CLIFF])
        cliff_wave_L1();
        
        // Layer 2 (mid crest)
        translate([wave_drift * 0.7, 0, Z_CLIFF_WAVE_L2 - Z_CLIFF])
        cliff_wave_L2();
        
        // Layer 3 (foam)
        translate([0, wave_surge, Z_CLIFF_WAVE_L3 - Z_CLIFF])
        cliff_wave_L3();
    }
}

module cliff_wave_L1() {
    color(C_WAVE_DARK)
    rotate([0, 0, -70])
    linear_extrude(height=5)
    polygon([
        [0, 0], [0, 6], [4, 6], [4, 0],
        [8, 0], [8, 6], [12, 6], [12, 0],
        [16, 0], [16, 6], [20, 6], [20, 0],
        [24, 0], [24, 6], [28, 6], [28, 0],
        [40, 0], [50, 2], [65, 3], [80, 3],
        [95, 3], [110, 2], [120, 2],
        [125, 5], [128, 12], [130, 20], [128, 28],
        [125, 32], [120, 35],
        [110, 38], [100, 42], [90, 48], [80, 55],
        [70, 62], [60, 68], [50, 72], [45, 75],
        [40, 80], [35, 88], [32, 95], [30, 98], [28, 95],
        [25, 88], [22, 78], [18, 65], [14, 50],
        [10, 35], [5, 20], [2, 10], [0, 5]
    ]);
}

module cliff_wave_L2() {
    color(C_WAVE_MID)
    rotate([0, 0, -70])
    linear_extrude(height=5)
    offset(delta=-3)
    polygon([
        [10, 5], [15, 8], [25, 10], [40, 12],
        [55, 12], [70, 10], [85, 8],
        [95, 10], [105, 15], [112, 22], [118, 32],
        [122, 42], [124, 52],
        [125, 60], [124, 68], [120, 75], [114, 80],
        [106, 82], [98, 80], [92, 75], [88, 68],
        [86, 60], [88, 52], [92, 46], [98, 42],
        [104, 40], [108, 42], [110, 48], [108, 55],
        [104, 58], [100, 56], [98, 52],
        [90, 55], [80, 60], [70, 68], [60, 75],
        [50, 82], [42, 88], [35, 92], [30, 95],
        [25, 90], [20, 80], [16, 68], [12, 52],
        [10, 35], [8, 20]
    ]);
}

module cliff_wave_L3() {
    color(C_FOAM)
    rotate([0, 0, -70])
    linear_extrude(height=5) {
        polygon([
            [30, 70], [35, 78], [42, 86], [50, 92],
            [60, 96], [70, 98], [80, 96], [88, 90],
            [92, 82], [90, 75], [84, 72], [76, 74],
            [68, 78], [60, 80], [52, 78], [45, 74], [38, 68]
        ]);
        polygon([
            [85, 78], [92, 85], [100, 88], [108, 85],
            [112, 78], [110, 72], [104, 70], [96, 72], [90, 75]
        ]);
        translate([115, 80]) circle(r=4);
        translate([120, 72]) circle(r=3);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: OCEAN WAVES - LOCKED TO ZONE_OCEAN_WAVES
// Zone: X=151-302, Y=0-65
// Original ~260×65mm, need scale ~0.58
// ═══════════════════════════════════════════════════════════════════════════
module ocean_waves_locked() {
    s = 0.55;  // Scale to fit zone
    translate([ZONE_OCEAN_WAVES[0], ZONE_OCEAN_WAVES[2], 0])
    scale([s, s, 1]) {
        // Layer 1 (base)
        translate([0, 0, Z_OCEAN_WAVE_L1 - Z_CLIFF])
        ocean_wave_L1();
        
        // Layer 2 (swell)
        translate([wave_drift * 0.8, 0, Z_OCEAN_WAVE_L2 - Z_CLIFF])
        ocean_wave_L2();
        
        // Layer 3 (crest)
        translate([0, wave_surge * 0.8, Z_OCEAN_WAVE_L3 - Z_CLIFF])
        ocean_wave_L3();
    }
}

module ocean_wave_L1() {
    color(C_WAVE_DARK)
    linear_extrude(height=5)
    polygon([
        [0, 0], [30, 2], [70, 3], [110, 4],
        [150, 4], [190, 3], [230, 2], [260, 0],
        [260, 8], [258, 15],
        [250, 22], [240, 28], [228, 32], [215, 30],
        [200, 28], [185, 32], [170, 35], [155, 38],
        [140, 36], [125, 34], [110, 38], [95, 42],
        [80, 45], [65, 48], [50, 45], [35, 40],
        [22, 35], [12, 28],
        [5, 20], [2, 12], [0, 5]
    ]);
}

module ocean_wave_L2() {
    color(C_WAVE_MID)
    linear_extrude(height=5)
    polygon([
        [5, 20], [12, 28], [22, 38], [35, 48],
        [50, 55], [65, 60], [80, 58],
        [95, 52], [108, 48], [120, 50],
        [135, 55], [150, 62], [165, 65], [180, 62],
        [195, 55], [208, 50], [220, 52],
        [232, 58], [245, 55], [255, 48],
        [260, 40], [260, 32],
        [255, 35], [242, 42], [228, 45], [212, 40],
        [198, 38], [182, 42], [168, 50], [152, 52],
        [138, 48], [122, 42], [108, 38], [92, 42],
        [78, 48], [62, 50], [48, 45], [35, 38],
        [22, 28], [12, 20], [5, 12]
    ]);
}

module ocean_wave_L3() {
    color(C_WAVE_LITE)
    linear_extrude(height=5) {
        polygon([
            [20, 30], [30, 40], [42, 52], [55, 65],
            [70, 75], [88, 82], [105, 85], [120, 82],
            [132, 75], [140, 65], [145, 52], [142, 42],
            [135, 48], [125, 55], [112, 62], [98, 65],
            [85, 62], [72, 55], [62, 48], [52, 40],
            [42, 32], [32, 25]
        ]);
        polygon([
            [160, 28], [170, 38], [182, 50], [195, 60],
            [210, 65], [225, 62], [235, 55], [240, 45], [238, 38],
            [230, 42], [218, 48], [205, 50], [192, 45],
            [180, 38], [170, 30]
        ]);
        translate([110, 88]) circle(r=5);
        translate([125, 85]) circle(r=4);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: WIND PATH - LOCKED TO ZONE_WIND_PATH
// Zone: X=0-198, Y=105-202
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_locked() {
    s = 1.0;  // Already fits well
    translate([ZONE_WIND_PATH[0], ZONE_WIND_PATH[2], 0])
    scale([zone_w(ZONE_WIND_PATH)/192, zone_h(ZONE_WIND_PATH)/80, 1])
    wind_path_panel();
}

module wind_path_panel() {
    pw = 192;
    ph = 80;
    
    // Big cutout position (centered in BIG_SWIRL zone relative to wind path)
    big_cx = (zone_cx(ZONE_BIG_SWIRL) - ZONE_WIND_PATH[0]) * 192 / zone_w(ZONE_WIND_PATH);
    big_cy = (zone_cy(ZONE_BIG_SWIRL) - ZONE_WIND_PATH[2]) * 80 / zone_h(ZONE_WIND_PATH);
    big_r = BIG_SWIRL_R * 192 / zone_w(ZONE_WIND_PATH) + 2;
    
    // Small cutout position
    small_cx = (zone_cx(ZONE_SMALL_SWIRL) - ZONE_WIND_PATH[0]) * 192 / zone_w(ZONE_WIND_PATH);
    small_cy = (zone_cy(ZONE_SMALL_SWIRL) - ZONE_WIND_PATH[2]) * 80 / zone_h(ZONE_WIND_PATH);
    small_r = SMALL_SWIRL_R * 192 / zone_w(ZONE_WIND_PATH) + 2;
    
    color(C_WIND)
    difference() {
        linear_extrude(height=5)
        polygon([
            [0, ph*0.6], [pw*0.02, ph*0.75], [pw*0.05, ph*0.85],
            [pw*0.08, ph*0.9], [pw*0.12, ph*0.88], [pw*0.16, ph*0.82],
            [pw*0.20, ph*0.75], [pw*0.25, ph*0.65], [pw*0.30, ph*0.52],
            [pw*0.35, ph*0.42], [pw*0.40, ph*0.35],
            [pw*0.65, ph*0.32], [pw*0.70, ph*0.38],
            [pw*0.75, ph*0.45], [pw*0.80, ph*0.55],
            [pw*0.85, ph*0.60], [pw*0.90, ph*0.58],
            [pw*0.95, ph*0.52], [pw, ph*0.48],
            [pw, ph*0.38], [pw*0.95, ph*0.35],
            [pw*0.90, ph*0.32], [pw*0.85, ph*0.28],
            [pw*0.80, ph*0.25], [pw*0.75, ph*0.22],
            [pw*0.70, ph*0.20], [pw*0.65, ph*0.18],
            [pw*0.40, ph*0.15], [pw*0.35, ph*0.18],
            [pw*0.30, ph*0.22], [pw*0.25, ph*0.28],
            [pw*0.20, ph*0.20], [pw*0.16, ph*0.15],
            [pw*0.12, ph*0.12], [pw*0.08, ph*0.10],
            [pw*0.05, ph*0.08], [pw*0.02, ph*0.12], [0, ph*0.20]
        ]);
        
        // Big cutout
        translate([big_cx, big_cy, -1])
        cylinder(r=big_r, h=7);
        
        // Small cutout
        translate([small_cx, small_cy, -1])
        cylinder(r=small_r, h=7);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: BIG SWIRL - LOCKED TO ZONE_BIG_SWIRL
// Zone: X=86-160, Y=110-170
// ═══════════════════════════════════════════════════════════════════════════
module big_swirl_locked() {
    cx = zone_cx(ZONE_BIG_SWIRL);  // Center X = 123
    cy = zone_cy(ZONE_BIG_SWIRL);  // Center Y = 140
    r = BIG_SWIRL_R;
    
    translate([cx, cy, 0])
    rotate([0, 0, swirl_big_rot]) {
        // Halo 1 (back)
        color(C_MOON_HALO, 0.6)
        cylinder(r=r + 4, h=2);
        
        // Halo 2
        translate([0, 0, 2])
        color(C_WIND, 0.7)
        cylinder(r=r + 2, h=2);
        
        // Main disc
        translate([0, 0, 4])
        color(C_WIND)
        swirl_disc(r, 5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: SMALL SWIRL - LOCKED TO ZONE_SMALL_SWIRL
// Zone: X=151-198, Y=105-154 (UPDATED)
// ═══════════════════════════════════════════════════════════════════════════
module small_swirl_locked() {
    cx = zone_cx(ZONE_SMALL_SWIRL);  // Center X = 174.5
    cy = zone_cy(ZONE_SMALL_SWIRL);  // Center Y = 129.5
    r = SMALL_SWIRL_R;
    
    translate([cx, cy, 0])
    rotate([0, 0, swirl_small_rot]) {
        // Halo 1 (back)
        color(C_MOON_HALO, 0.6)
        cylinder(r=r + 3, h=2);
        
        // Halo 2
        translate([0, 0, 2])
        color(C_WIND, 0.7)
        cylinder(r=r + 1.5, h=2);
        
        // Main disc
        translate([0, 0, 4])
        color(C_WIND)
        swirl_disc(r, 5);
    }
}

module swirl_disc(r, h) {
    difference() {
        cylinder(r=r, h=h);
        translate([0, 0, -1])
        cylinder(r=r/5, h=h+2);  // Center hole
        
        // Spiral slots
        for (a=[0:30:330]) {
            rotate([0, 0, a])
            translate([r*0.3, 0, -1])
            for (i=[0:5]) {
                translate([i*r*0.1, 0, 0])
                rotate([0, 0, i*15])
                cylinder(r=r*0.06, h=h+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: MOON - LOCKED TO ZONE_MOON
// Zone: X=231-300, Y=141-202
// ═══════════════════════════════════════════════════════════════════════════
module moon_locked() {
    cx = zone_cx(ZONE_MOON);  // Center X = 265.5
    cy = zone_cy(ZONE_MOON);  // Center Y = 171.5
    r = MOON_R;
    
    translate([cx, cy, 0]) {
        // Outer halo
        color(C_MOON_HALO, 0.4)
        cylinder(r=r + 6, h=2);
        
        // Mid halo
        translate([0, 0, 2])
        color(C_MOON_HALO, 0.6)
        cylinder(r=r + 3, h=2);
        
        // Moon core
        translate([0, 0, 4])
        color(C_MOON)
        cylinder(r=r, h=5);
        
        // Phase shadow
        phase_offset = moon_phase * r * 4 - r * 2;
        translate([0, 0, 9])
        color(C_SKY)
        difference() {
            cylinder(r=r + 1, h=2);
            translate([phase_offset, 0, -1])
            cylinder(r=r, h=4);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: BOTTOM GEARS - LOCKED TO ZONE_BOTTOM_GEARS
// Zone: X=164-302, Y=0-30
// ═══════════════════════════════════════════════════════════════════════════
module bottom_gears_locked() {
    // 3 gears spread across the zone
    gear_positions = [
        [ZONE_BOTTOM_GEARS[0] + 25, 15, 12],  // [x, y, teeth]
        [ZONE_BOTTOM_GEARS[0] + 70, 12, 16],
        [ZONE_BOTTOM_GEARS[0] + 115, 18, 10]
    ];
    
    for (g=gear_positions) {
        translate([g[0], g[1], 0])
        rotate([0, 0, gear_rot * (g[2] > 12 ? 1 : -1)])
        gear_module(g[2], 5);
    }
}

module gear_module(teeth, h) {
    pitch_r = teeth * 0.9;
    color(C_GEAR)
    difference() {
        cylinder(r=pitch_r, h=h);
        translate([0, 0, -1])
        cylinder(r=2, h=h+2);
        
        for (i=[0:teeth-1]) {
            rotate([0, 0, i*360/teeth])
            translate([pitch_r - 1, 0, -1])
            cylinder(r=1.5, h=h+2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: SKY GEARS - LOCKED TO ZONE_SKY_GEARS
// Zone: X=52-216, Y=109-166
// ═══════════════════════════════════════════════════════════════════════════
module sky_gears_locked() {
    gear_positions = [
        [ZONE_SKY_GEARS[0] + 20, ZONE_SKY_GEARS[2] + 30, 8],
        [ZONE_SKY_GEARS[0] + 50, ZONE_SKY_GEARS[2] + 45, 10],
        [ZONE_SKY_GEARS[0] + 90, ZONE_SKY_GEARS[2] + 25, 6],
        [ZONE_SKY_GEARS[0] + 130, ZONE_SKY_GEARS[2] + 40, 12]
    ];
    
    for (g=gear_positions) {
        translate([g[0], g[1], 0])
        rotate([0, 0, gear_rot * (g[2] > 8 ? -1 : 1)])
        gear_module(g[2], 3);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULE: BIRD WIRE - LOCKED TO ZONE_BIRD_WIRE
// Zone: X=0-302, Y=81-97
// ═══════════════════════════════════════════════════════════════════════════
module bird_wire_locked() {
    wire_y = zone_cy(ZONE_BIRD_WIRE);  // Y = 89
    
    // Wire
    color("DarkGray")
    translate([0, wire_y, 0])
    rotate([0, 90, 0])
    cylinder(r=0.8, h=CANVAS_W);
    
    // Supports at ends
    for (x=[5, CANVAS_W - 5]) {
        color(C_GEAR)
        translate([x, wire_y, -3])
        cylinder(r=3, h=6);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════
// Sky background
translate([TAB, TAB, Z_SKY])
sky_background();

// Moon
translate([TAB, TAB, Z_MOON_HALO2])
moon_locked();

// Wind path
translate([TAB, TAB, Z_WIND_PATH])
wind_path_locked();

// Swirl discs
translate([TAB, TAB, Z_BIG_SWIRL])
big_swirl_locked();

translate([TAB, TAB, Z_SMALL_SWIRL])
small_swirl_locked();

// Cliff
translate([TAB, TAB, Z_CLIFF])
cliff_locked();

// Lighthouse
translate([TAB, TAB, Z_LIGHTHOUSE])
lighthouse_locked();

// Waves
translate([TAB, TAB, Z_CLIFF])
cliff_waves_locked();

translate([TAB, TAB, Z_CLIFF])
ocean_waves_locked();

// Bottom gears
translate([TAB, TAB, Z_BOTTOM_GEARS])
bottom_gears_locked();

// Sky gears
translate([TAB, TAB, Z_SKY_GEARS])
sky_gears_locked();

// Cypress (FRONT - highest Z)
translate([TAB, TAB, Z_CYPRESS])
cypress_locked();

// Bird wire
translate([TAB, TAB, Z_BIRD_WIRE])
bird_wire_locked();

// Frame
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
// DEBUG INFO
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V38 - LOCKED ELEMENT OUTLINES");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas:", CANVAS_W, "×", CANVAS_H, "mm");
echo("");
echo("LOCKED ZONES (X: min-max, Y: min-max):");
echo("  CLIFF:       ", ZONE_CLIFF[0], "-", ZONE_CLIFF[1], ",", ZONE_CLIFF[2], "-", ZONE_CLIFF[3]);
echo("  LIGHTHOUSE:  ", ZONE_LIGHTHOUSE[0], "-", ZONE_LIGHTHOUSE[1], ",", ZONE_LIGHTHOUSE[2], "-", ZONE_LIGHTHOUSE[3]);
echo("  CYPRESS:     ", ZONE_CYPRESS[0], "-", ZONE_CYPRESS[1], ",", ZONE_CYPRESS[2], "-", ZONE_CYPRESS[3]);
echo("  CLIFF_WAVES: ", ZONE_CLIFF_WAVES[0], "-", ZONE_CLIFF_WAVES[1], ",", ZONE_CLIFF_WAVES[2], "-", ZONE_CLIFF_WAVES[3]);
echo("  OCEAN_WAVES: ", ZONE_OCEAN_WAVES[0], "-", ZONE_OCEAN_WAVES[1], ",", ZONE_OCEAN_WAVES[2], "-", ZONE_OCEAN_WAVES[3]);
echo("  BOTTOM_GEARS:", ZONE_BOTTOM_GEARS[0], "-", ZONE_BOTTOM_GEARS[1], ",", ZONE_BOTTOM_GEARS[2], "-", ZONE_BOTTOM_GEARS[3]);
echo("  WIND_PATH:   ", ZONE_WIND_PATH[0], "-", ZONE_WIND_PATH[1], ",", ZONE_WIND_PATH[2], "-", ZONE_WIND_PATH[3]);
echo("  BIG_SWIRL:   ", ZONE_BIG_SWIRL[0], "-", ZONE_BIG_SWIRL[1], ",", ZONE_BIG_SWIRL[2], "-", ZONE_BIG_SWIRL[3]);
echo("  SMALL_SWIRL: ", ZONE_SMALL_SWIRL[0], "-", ZONE_SMALL_SWIRL[1], ",", ZONE_SMALL_SWIRL[2], "-", ZONE_SMALL_SWIRL[3]);
echo("  MOON:        ", ZONE_MOON[0], "-", ZONE_MOON[1], ",", ZONE_MOON[2], "-", ZONE_MOON[3]);
echo("  SKY_GEARS:   ", ZONE_SKY_GEARS[0], "-", ZONE_SKY_GEARS[1], ",", ZONE_SKY_GEARS[2], "-", ZONE_SKY_GEARS[3]);
echo("  BIRD_WIRE:   ", ZONE_BIRD_WIRE[0], "-", ZONE_BIRD_WIRE[1], ",", ZONE_BIRD_WIRE[2], "-", ZONE_BIRD_WIRE[3]);
echo("");
echo("SWIRL RADII:");
echo("  BIG_SWIRL:   R =", BIG_SWIRL_R, "mm (fits in", zone_w(ZONE_BIG_SWIRL), "×", zone_h(ZONE_BIG_SWIRL), "zone)");
echo("  SMALL_SWIRL: R =", SMALL_SWIRL_R, "mm (fits in", zone_w(ZONE_SMALL_SWIRL), "×", zone_h(ZONE_SMALL_SWIRL), "zone)");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════");
