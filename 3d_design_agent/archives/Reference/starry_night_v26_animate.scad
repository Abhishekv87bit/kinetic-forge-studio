// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT MECHANICAL CANVAS - V26 FINAL
// Van Gogh inspired kinetic art with waves, birds, moon phases, lighthouse
// View > Animate: FPS=30, Steps=360
// ═══════════════════════════════════════════════════════════════════════════
$fn=32;

// ═══════════════════════════════════════════════════════════════════════════
// PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════
W = 350;            // Total width
H = 275;            // Total height
D = 100;            // Total depth
FW = 25;            // Frame width
IW = W - FW*2;      // Inner width (300mm)
IH = H - FW*2;      // Inner height (225mm)

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS (back to front)
// ═══════════════════════════════════════════════════════════════════════════
Z_LED = 0;          // LED panel
Z_DIFFUSER = 3;     // Diffuser
Z_BACK = 5;         // Back panel
Z_SKY_DISK = 8;     // Sky spiral disks (8-20mm)
Z_STARS = 20;       // Star LED mounts
Z_MOON = 22;        // Moon + phase disk
Z_CLIFF = 26;       // Cliff + Lighthouse + Cypress (26-64mm)
Z_WAVE_BASE = 64;   // Wave panels start (64-84mm)
Z_BEACH = 84;       // Beach
Z_FRAME = 88;       // Frame bottom

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATION VARIABLES
// ═══════════════════════════════════════════════════════════════════════════
t = $t;                                     // 0 to 1

// Moon phase (1 full cycle per animation)
moon_phase = t;                             // 0=new, 0.5=full, 1=new

// Wave speed varies with moon (full=fast, new=slow)
wave_speed_mult = 0.5 + moon_phase * (moon_phase < 0.5 ? moon_phase : (1-moon_phase)) * 2;
wave_phase = t * 360 * wave_speed_mult;

// Wave drift (R↔L, ±10mm)
drift_cycle = sin(wave_phase * 0.8);        // Slower than vertical bob
wave_drift = drift_cycle * 10;              // ±10mm

// Surge timing
ocean_surge_phase = sin(wave_phase + 72);   // Ocean surge at specific phase
cliff_surge_phase = sin(wave_phase + 216);  // Cliff surge later in cycle
ocean_surge = max(0, ocean_surge_phase) * 20;
cliff_surge = max(0, cliff_surge_phase);

// Lighthouse beam (10 sec rotation = 6 RPM at 1 min cycle)
lighthouse_rot = t * 360 * 6;

// Bird movement (R→L across scene)
bird_cycle = t;
bird_x = IW - 30 - bird_cycle * (IW - 60);  // R to L
wing_phase = t * 360 * 12;                   // Flapping frequency

// Ship wobble (linked to wave motion)
ship_wobble = 4 * sin(wave_phase * 1.5);
ship_rot = 3 * sin(wave_phase * 1.2);

// Rice tube tilt (synced to wave collision)
rice_tilt = 15 * sin(wave_phase + 144);

// Sky disk rotations (different speeds)
sky_disk1_rot = t * 360 * 1;                // 1 RPM (slowest)
sky_disk2_rot = t * 360 * -1.5;             // 1.5 RPM (opposite direction)
sky_disk3_rot = t * 360 * 2;                // 2 RPM (fastest)

// Beach foam drift (linked to wave drift)
foam_drift = wave_drift;

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = "Gold";
C_WAVE = ["#061a3a", "#0a2a5e", "#1a4a7e", "#2a5a8e", "#4a7aae"];
C_CLIFF = "#3d3d3d";
C_CLIFF_DARK = "#2a2a2a";
C_BEACH = "#c4a574";
C_CYPRESS = "#1a3d1a";
C_LIGHTHOUSE = "Ivory";
C_LIGHTHOUSE_RED = "#8b0000";
C_SKY = "#0a1a3a";
C_MOON = "Gold";

// ═══════════════════════════════════════════════════════════════════════════
// STAR POSITIONS (normalized 0-1, updated Star 11)
// ═══════════════════════════════════════════════════════════════════════════
STARS = [
    [0.12, 0.85, "narrow"],   // 1
    [0.25, 0.82, "broad"],    // 2
    [0.45, 0.88, "narrow"],   // 3
    [0.35, 0.72, "broad"],    // 4
    [0.52, 0.75, "narrow"],   // 5
    [0.68, 0.78, "broad"],    // 6
    [0.15, 0.65, "narrow"],   // 7
    [0.38, 0.62, "broad"],    // 8
    [0.55, 0.68, "narrow"],   // 9
    [0.72, 0.65, "broad"],    // 10
    [0.75, 0.72, "narrow"],   // 11 (moved inward)
    [0.48, 0.55, "broad"]     // 12
];

// ═══════════════════════════════════════════════════════════════════════════
// WAVE CURL POSITIONS (manually staggered per layer)
// Format: [x_position (0-1), size_multiplier]
// ═══════════════════════════════════════════════════════════════════════════
WAVE_CURLS = [
    // Wave 1 (back) - smallest curls
    [[0.08, 0.9], [0.22, 0.85], [0.38, 0.9], [0.52, 0.85], [0.68, 0.9], [0.82, 0.85], [0.95, 0.9]],
    // Wave 2
    [[0.05, 0.95], [0.18, 0.9], [0.32, 0.95], [0.48, 0.9], [0.62, 0.95], [0.78, 0.9], [0.92, 0.95]],
    // Wave 3
    [[0.10, 1.0], [0.25, 0.95], [0.42, 1.0], [0.55, 0.95], [0.72, 1.0], [0.88, 0.95]],
    // Wave 4
    [[0.03, 1.0], [0.15, 0.95], [0.30, 1.0], [0.45, 0.95], [0.60, 1.0], [0.75, 0.95], [0.90, 1.0]],
    // Wave 5 (front) - largest curls
    [[0.07, 1.1], [0.20, 1.05], [0.35, 1.1], [0.50, 1.05], [0.65, 1.1], [0.80, 1.05], [0.93, 1.1]]
];

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - SKY ELEMENTS
// ═══════════════════════════════════════════════════════════════════════════

// Star cutout - broad (bright) or narrow (dim)
module star_cutout(type="broad") {
    if (type == "broad") {
        cylinder(d=11, h=5, center=true);
    } else {
        // Star shape - narrower, creates dimmer light
        for (a = [0:60:300]) {
            rotate([0, 0, a])
            cube([2, 8, 5], center=true);
        }
    }
}

// Sky mask with star holes
module sky_mask() {
    color(C_SKY, 0.9)
    difference() {
        cube([IW, IH, 2]);
        
        // Star cutouts
        for (s = STARS) {
            translate([s[0]*IW, s[1]*IH, -1])
            star_cutout(s[2]);
        }
        
        // Moon cutout
        translate([IW*0.85, IH*0.78, -1])
        cylinder(d=55, h=5);
        
        // Cliff area cutout
        translate([-1, -1, -1])
        cube([IW*0.42, IH*0.65, 5]);
        
        // Wave area cutout (bottom)
        translate([-1, -1, -1])
        cube([IW+2, IH*0.35, 5]);
    }
}

// Spiral disk with slots
module sky_spiral_disk(radius, arms, slot_width, rot) {
    rotate([0, 0, rot])
    color(C_SKY, 0.7)
    difference() {
        cylinder(r=radius, h=3);
        
        // Center hole for shaft
        translate([0, 0, -1])
        cylinder(d=8, h=5);
        
        // Spiral arm slots
        for (arm = [0:arms-1]) {
            for (r = [15:6:radius-5]) {
                rotate([0, 0, arm * (360/arms) + r * 2.2])
                translate([r, 0, -1])
                cylinder(d=slot_width + r*0.04, h=5);
            }
        }
    }
}

// Moon with phase shadow
module moon() {
    r = 25; // 50mm diameter
    
    // Moon body (gold)
    color(C_MOON)
    cylinder(r=r, h=4);
    
    // Phase shadow disk
    translate([0, 0, 4])
    color(C_SKY) {
        if (moon_phase < 0.02 || moon_phase > 0.98) {
            // New moon - fully covered
            cylinder(r=r+1, h=2);
        } else if (moon_phase > 0.48 && moon_phase < 0.52) {
            // Full moon - no shadow
        } else if (moon_phase < 0.5) {
            // Waxing - shadow on left, shrinking
            off = (0.5 - moon_phase) * r * 4;
            difference() {
                cylinder(r=r+1, h=2);
                translate([off, 0, -1])
                cylinder(r=r, h=4);
            }
        } else {
            // Waning - shadow on right, growing
            off = (moon_phase - 0.5) * r * 4;
            difference() {
                cylinder(r=r+1, h=2);
                translate([-off, 0, -1])
                cylinder(r=r, h=4);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - CLIFF & LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════

// Rocky cliff with shoreline
module cliff() {
    // Main cliff body
    color(C_CLIFF)
    hull() {
        translate([5, 5, 0]) cylinder(r=25, h=38);
        translate([60, 8, 0]) cylinder(r=20, h=38);
        translate([70, IH*0.35, 0]) cylinder(r=18, h=35);
        translate([55, IH*0.50, 0]) cylinder(r=20, h=32);
        translate([35, IH*0.58, 0]) cylinder(r=15, h=28);
        translate([10, IH*0.55, 0]) cylinder(r=18, h=30);
    }
    
    // Rock texture bumps
    color(C_CLIFF_DARK)
    for (p = [[15, IH*0.12, 18], [40, IH*0.18, 22], [55, IH*0.25, 20],
              [25, IH*0.32, 25], [50, IH*0.38, 22], [18, IH*0.45, 18],
              [42, IH*0.48, 24], [60, IH*0.42, 19]]) {
        translate([p[0], p[1], p[2]])
        scale([1.3, 1.1, 0.6])
        sphere(r=6);
    }
    
    // Lighthouse platform
    color(C_CLIFF)
    translate([38, IH*0.52, 36])
    cylinder(r=16, h=4, $fn=12);
    
    // Shoreline rocks at base
    color(C_CLIFF_DARK)
    for (p = [[10, 3], [28, 4], [48, 3], [65, 5], [78, 4]]) {
        translate([p[0], p[1], 0])
        scale([1.8, 1.4, 1])
        sphere(r=7);
    }
    
    // Medium rocks
    color("#4a4a4a")
    for (p = [[18, 5], [38, 3], [58, 6], [72, 3]]) {
        translate([p[0], p[1], 0])
        scale([1.3, 1, 0.7])
        sphere(r=5);
    }
    
    // Small pebbles at waterline
    color("#5a5a5a")
    for (i = [0:20]) {
        translate([8 + i*3.5, 2 + sin(i)*1.5, 0])
        sphere(r=1.5 + sin(i*0.5));
    }
}

// Cypress tree
module cypress() {
    color(C_CYPRESS) {
        // Trunk
        translate([0, 0, 0])
        cylinder(r1=4, r2=2, h=15);
        
        // Foliage - flame-like shape
        for (z = [10:8:75]) {
            sf = 1 - (z-10)/80;
            translate([0, 0, z])
            scale([sf, sf*0.6, 1])
            cylinder(r1=12, r2=3, h=15);
        }
    }
}

// Lighthouse with rotating beam
module lighthouse() {
    rotate([-90, 0, 0]) {
        // Tower base
        color(C_LIGHTHOUSE)
        cylinder(r1=8, r2=6, h=45);
        
        // Red stripes
        color(C_LIGHTHOUSE_RED)
        for (z = [8, 22, 36]) {
            translate([0, 0, z])
            cylinder(r=7 - z*0.03, h=6);
        }
        
        // Lamp room base
        translate([0, 0, 45]) {
            color("#333")
            cylinder(r=8, h=3);
            
            // Glass enclosure
            color("LightBlue", 0.4)
            translate([0, 0, 3])
            difference() {
                cylinder(r=7, h=10);
                translate([0, 0, 1])
                cylinder(r=6, h=10);
            }
            
            // Light source
            color("Yellow")
            translate([0, 0, 6])
            cylinder(r=4, h=5);
            
            // Rotating beam (translucent wedge)
            color("White", 0.7)
            rotate([0, 0, lighthouse_rot])
            translate([0, 0, 5])
            rotate([0, 90, 0])
            linear_extrude(height=30)
            polygon([[0, -2], [0, 2], [25, 8], [25, -8]]);
            
            // Roof
            color(C_LIGHTHOUSE_RED)
            translate([0, 0, 13])
            cylinder(r1=8, r2=2, h=6);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - WAVES
// ═══════════════════════════════════════════════════════════════════════════

// Single wave curl shape
module wave_curl(size, dir=1) {
    scale([dir, 1, 1])
    linear_extrude(height=4)
    polygon(concat(
        [[0, 0]],
        [for (t = [0:10:180]) 
            let(r = size * (1 - t/220))
            [r * cos(t) * 0.8, size*0.4 + r * sin(t)]
        ],
        [[size*-0.3, size*0.2], [0, 0]]
    ));
}

// Translucent foam tip (for surge curls)
module foam_tip(size) {
    color("White", 0.8)
    translate([0, size*0.35, 4])
    scale([0.6, 0.3, 0.15])
    sphere(r=size*0.4);
}

// Wave panel with hinged curls
module wave_panel(wave_num) {
    pw = IW - 85;               // Panel width
    curl_data = WAVE_CURLS[wave_num];
    base_size = 22 + wave_num * 3;  // Larger curls toward front
    
    // Wave base colors (Van Gogh style)
    wave_color = C_WAVE[wave_num];
    
    // Y offset for staggering (back highest, front lowest)
    base_y = [12, 6, 0, -6, -12][wave_num];
    
    // Vertical bob motion
    bob_amp = [3, 4, 5, 6, 7][wave_num];
    bob_phase = wave_num * 55;
    bob = bob_amp * sin(wave_phase + bob_phase);
    
    // Tilt motion
    tilt = 2 * sin(wave_phase + bob_phase + 30);
    
    // Surge amounts (varies by wave)
    ocean_surge_amt = [10, 15, 15, 18, 20][wave_num] * max(0, ocean_surge_phase);
    cliff_surge_amt = [10, 0, 15, 0, 20][wave_num] * max(0, cliff_surge_phase); // Only W1,W3,W5
    
    translate([wave_drift, base_y + bob, 0])
    rotate([tilt, 0, 0])
    color(wave_color, 0.85) {
        // Base plate
        linear_extrude(height=4)
        translate([0, -10])
        square([pw, 14]);
        
        // Static curls (middle section)
        for (i = [1:len(curl_data)-2]) {
            cx = curl_data[i][0] * pw;
            cs = base_size * curl_data[i][1];
            dir = (i % 2 == 0) ? 1 : -1;
            
            translate([cx, 0, 0])
            rotate([0, 0, dir * 8])
            wave_curl(cs, dir);
        }
        
        // Ocean-side surge curls (right, index=last)
        oc = curl_data[len(curl_data)-1];
        translate([oc[0] * pw, ocean_surge_amt, 0])
        rotate([0, 0, -10]) {
            wave_curl(base_size * oc[1] * 1.1, -1);
            foam_tip(base_size * oc[1]);
        }
        
        // Second ocean curl
        oc2 = curl_data[len(curl_data)-2];
        translate([oc2[0] * pw, ocean_surge_amt * 0.7, 0])
        rotate([0, 0, 8]) {
            wave_curl(base_size * oc2[1], 1);
            foam_tip(base_size * oc2[1] * 0.8);
        }
        
        // Third ocean curl
        oc3 = curl_data[len(curl_data)-3];
        translate([oc3[0] * pw, ocean_surge_amt * 0.4, 0])
        rotate([0, 0, -6]) {
            wave_curl(base_size * oc3[1] * 0.9, -1);
        }
        
        // Cliff-side surge curls (left, only on W1, W3, W5)
        if (wave_num == 0 || wave_num == 2 || wave_num == 4) {
            cc = curl_data[0];
            translate([cc[0] * pw, cliff_surge_amt, 0])
            rotate([0, 0, 12]) {
                wave_curl(base_size * cc[1] * 1.05, 1);
                foam_tip(base_size * cc[1] * 0.9);
            }
            
            // Second cliff curl
            cc2 = curl_data[1];
            translate([cc2[0] * pw, cliff_surge_amt * 0.6, 0])
            rotate([0, 0, -8]) {
                wave_curl(base_size * cc2[1] * 0.95, -1);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - SHIP
// ═══════════════════════════════════════════════════════════════════════════

module ship() {
    translate([0, ship_wobble, 0])
    rotate([0, 0, ship_rot])
    color("SaddleBrown") {
        // Hull
        linear_extrude(height=5)
        polygon([[-18, 0], [-15, 5], [-8, 8], [8, 8], [15, 5], [20, 0], [15, -4], [-15, -4]]);
        
        // Mast
        translate([0, 8, 0])
        cube([2, 2, 40], center=true);
        
        // Sail
        translate([3, 8, 8])
        linear_extrude(height=2)
        polygon([[0, 0], [18, 3], [18, 22], [0, 25]]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - BIRDS
// ═══════════════════════════════════════════════════════════════════════════

module bird(wing_angle) {
    // Bird flying left (negative X direction)
    rotate([0, 0, 180])  // Face left
    union() {
        // Body
        color("Black") {
            scale([2.2, 1, 0.8])
            sphere(r=2.5);
            
            // Head
            translate([5.5, 0, 0])
            sphere(r=2);
            
            // Beak
            translate([7.5, 0, 0])
            rotate([0, 90, 0])
            cylinder(r1=0.8, r2=0, h=3.5);
            
            // Tail
            translate([-4.5, 0, 0])
            scale([2, 0.5, 0.2])
            sphere(r=2.5);
        }
        
        // Wings with flapping
        color("#333") {
            // Upper wing
            translate([0, 0, 2])
            rotate([0, wing_angle, 0])
            scale([0.9, 0.15, 0.9])
            rotate([90, 0, 0])
            linear_extrude(height=2)
            polygon([[0, 0], [-3, 10], [3, 10], [4, 0]]);
            
            // Lower wing
            translate([0, 0, -2])
            rotate([0, -wing_angle, 0])
            scale([0.9, 0.15, 0.9])
            rotate([90, 0, 0])
            linear_extrude(height=2)
            polygon([[0, 0], [-3, -10], [3, -10], [4, 0]]);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - BEACH
// ═══════════════════════════════════════════════════════════════════════════

module beach() {
    // Beach base
    color(C_BEACH) {
        // Tapered shape from cliff to right
        linear_extrude(height=4)
        polygon([
            [0, 0],
            [IW*0.4, 0],
            [IW, IH*0.08],
            [IW, 0],
            [0, 0]
        ]);
        
        // Sand ripple texture
        for (i = [0:8]) {
            translate([IW*0.1 + i*IW*0.08, IH*0.02, 4])
            rotate([0, 0, 15])
            scale([3, 0.5, 0.15])
            sphere(r=8);
        }
    }
    
    // Foam strips (move with waves)
    color("White", 0.7)
    for (i = [0:5]) {
        translate([IW*0.08 + i*IW*0.06 + foam_drift*0.1, IH*0.04, 4])
        scale([1.5, 0.8, 0.3])
        sphere(r=6);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - RICE TUBE
// ═══════════════════════════════════════════════════════════════════════════

module rice_tube() {
    // Pivot brackets
    color("#444") {
        difference() {
            cube([14, 12, 14], center=true);
            rotate([0, 90, 0])
            cylinder(d=10, h=16, center=true);
        }
        translate([IW-100, 0, 0])
        difference() {
            cube([14, 12, 14], center=true);
            rotate([0, 90, 0])
            cylinder(d=10, h=16, center=true);
        }
    }
    
    // Tilting tube
    rotate([rice_tilt, 0, 0])
    translate([10, 0, 0])
    color("Tan", 0.85)
    rotate([0, 90, 0])
    difference() {
        cylinder(d=22, h=IW-120);
        translate([0, 0, 3])
        cylinder(d=18, h=IW-126);
        
        // Internal baffles
        for (i = [1:6]) {
            translate([0, 0, i*(IW-120)/7])
            rotate([0, 0, i*30])
            cube([20, 2, 2], center=true);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODULES - FRAME & GEARS
// ═══════════════════════════════════════════════════════════════════════════

module frame() {
    color(C_FRAME)
    difference() {
        cube([W, H, 12]);
        translate([FW, FW, -1])
        cube([IW, IH, 14]);
        
        // Cutout for viewing sky through top
        translate([FW+15, H-FW+3, -1])
        cube([IW-30, FW-6, 14]);
    }
}

// Decorative gear
module gear(teeth, radius) {
    color("Goldenrod")
    linear_extrude(height=3)
    difference() {
        union() {
            circle(r=radius-2);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i*360/teeth])
                translate([radius-2, 0])
                square([4, 3], center=true);
            }
        }
        circle(r=3);  // Center hole
    }
}

// Gear train on bottom frame (visible from front)
module gear_train_A() {
    // Motor A gear train (left side)
    translate([FW + 20, -5, 0]) {
        rotate([90, 0, 0]) {
            gear(12, 10);                           // G1: Motor pinion
            translate([22, 0, 0]) gear(24, 16);    // G2: Reduction
            translate([44, 0, 0]) gear(18, 12);    // G3: To wave shaft
            translate([62, 0, 0]) gear(30, 20);    // G4: To bird pulley
            translate([88, 0, 0]) gear(36, 24);    // G5: Decorative
        }
    }
}

module gear_train_B() {
    // Motor B gear train (right side)
    translate([W - FW - 110, -5, 0]) {
        rotate([90, 0, 0]) {
            gear(12, 10);                           // G1: Motor pinion
            translate([22, 0, 0]) gear(36, 24);    // G2: 3:1 reduction
            translate([52, 0, 0]) gear(20, 14);    // G3: To sky disk
            translate([72, 0, 0]) gear(28, 18);    // G4: To lighthouse
            translate([96, 0, 0]) gear(48, 32);    // G5: To moon (very slow)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// LED Panel (back)
color("DarkBlue", 0.3)
translate([0, 0, Z_LED])
cube([W, H, 3]);

// Diffuser
color("White", 0.3)
translate([FW, FW, Z_DIFFUSER])
cube([IW, IH, 2]);

// Back panel
color(C_SKY)
translate([FW, FW, Z_BACK])
cube([IW, IH, 3]);

// Sky spiral disks
translate([FW + IW*0.35, FW + IH*0.75, Z_SKY_DISK]) {
    sky_spiral_disk(100, 8, 8, sky_disk1_rot);
    translate([0, 0, 4])
    sky_spiral_disk(75, 6, 6, sky_disk2_rot);
    translate([0, 0, 8])
    sky_spiral_disk(50, 5, 5, sky_disk3_rot);
}

// Star LEDs
translate([FW, FW, Z_STARS])
for (s = STARS) {
    translate([s[0]*IW, s[1]*IH, 0])
    color("Yellow")
    cylinder(d=6, h=3);
}

// Sky mask
translate([FW, FW, Z_STARS + 2])
sky_mask();

// Moon
translate([FW + IW*0.85, FW + IH*0.78, Z_MOON])
moon();

// Cliff
translate([FW, FW, Z_CLIFF])
cliff();

// Cypress tree (in front of lighthouse)
translate([FW + 25, FW + IH*0.48, Z_CLIFF])
cypress();

// Lighthouse
translate([FW + 40, FW + IH*0.54, Z_CLIFF + 38])
lighthouse();

// Wave panels (5 layers)
for (i = [0:4]) {
    translate([FW + 80, FW + 10, Z_WAVE_BASE + i*4])
    wave_panel(i);
}

// Ship (between wave 1 and 2)
translate([FW + 160, FW + 25, Z_WAVE_BASE + 6])
ship();

// Beach
translate([FW, FW, Z_BEACH])
beach();

// Rice tube (in top frame rail)
translate([FW + 50, H - FW/2, Z_FRAME + 6])
rice_tube();

// Birds (3 on track)
for (i = [0:2]) {
    // Evenly spaced on track, wrapping
    bx = (bird_x + i * (IW/3)) % IW;
    
    // Only show if in visible zone (front half of track)
    if (bx > 30 && bx < IW - 60) {
        by = IH * 0.72 + sin(bx * 0.5) * 10;  // Slight wave in flight path
        bz = 75 + i * 3;
        
        wing_ang = 25 * sin(wing_phase + i * 120);
        
        translate([FW + bx, FW + by, bz])
        scale([0.9 - i*0.05, 0.9 - i*0.05, 0.9 - i*0.05])
        bird(wing_ang);
    }
}

// Frame
translate([0, 0, Z_FRAME])
frame();

// Gear trains (visible on front of bottom rail)
translate([0, FW, Z_FRAME - 3]) {
    gear_train_A();
    gear_train_B();
}

// Debug output
echo("═══════════════════════════════════════════════════════════");
echo("STARRY NIGHT V26 - ANIMATION STATE");
echo("═══════════════════════════════════════════════════════════");
echo("t =", t);
echo("Moon phase =", moon_phase, moon_phase < 0.25 ? "waxing crescent" : 
                                  moon_phase < 0.5 ? "waxing gibbous" :
                                  moon_phase < 0.75 ? "waning gibbous" : "waning crescent");
echo("Wave speed multiplier =", wave_speed_mult);
echo("Wave drift =", wave_drift, "mm");
echo("Lighthouse rotation =", lighthouse_rot, "degrees");
echo("Bird X position =", bird_x);
echo("═══════════════════════════════════════════════════════════");
