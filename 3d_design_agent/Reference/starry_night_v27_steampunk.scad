// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V27 - STEAMPUNK VAN GOGH
// Mechanical art piece with visible gears, linkages, and mechanisms
// Inspired by pic_3 and pic_4 reference images
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════
// PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════
W = 350;            // Total width
H = 275;            // Total height  
D = 80;             // Total depth (reduced from 100)
FW = 20;            // Frame width
IW = W - FW*2;      // Inner width (310mm)
IH = H - FW*2;      // Inner height (235mm)

// Animation
t = $t;
swirl_rot_cw = t * 360 * 0.5;      // 0.5 RPM clockwise
swirl_rot_ccw = -t * 360 * 0.7;    // 0.7 RPM counter-clockwise
moon_outer_rot = t * 360 * 0.3;    // Moon outer ring
star_gear_rot = t * 360 * 2;       // Star gears (faster)
wave_phase = t * 360;
lighthouse_rot = t * 360 * 6;      // 6 RPM lighthouse beam
bird_cycle = t;                     // 90 second cycle

// Colors
C_FRAME = "#5a4030";               // Rustic wood
C_GEAR = "#b8860b";                // Brass/gold gears
C_GEAR_DARK = "#8b7355";           // Darker gear accent
C_SKY = "#1a3a6e";                 // Van Gogh sky blue
C_SKY_LIGHT = "#4a7ab0";           // Lighter sky blue
C_SWIRL = "#2a5a9e";               // Swirl blue
C_WAVE = ["#0a2a4e", "#1a4a7e", "#2a5a8e", "#3a6a9e", "#4a7aae"];
C_CLIFF = "#6b5344";               // Brown cliff
C_CLIFF_DARK = "#4a3a2a";          // Dark cliff accent
C_CYPRESS = "#1a3d1a";             // Dark green
C_LIGHTHOUSE = "#d4c4a8";          // Cream/tan
C_MOON = "#f0d060";                // Yellow moon
C_STAR = "#fffacd";                // Light yellow stars
C_FOAM = "#ffffff";                // White foam

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════
Z_LED = 0;
Z_DIFFUSER = 3;
Z_STAR_LED = 5;
Z_SWIRL_INNER = 7;
Z_SWIRL_OUTER = 11;
Z_WIND_PANEL = 15;
Z_CLIFF = 18;
Z_CYPRESS = 38;
Z_WAVE_START = 48;
Z_WAVE_MECH = 66;
Z_FRAME = 70;

// ═══════════════════════════════════════════════════════════════════════════
// GEAR MODULE
// ═══════════════════════════════════════════════════════════════════════════
module gear(teeth, radius, thickness=3, hole=3) {
    tooth_height = radius * 0.12;
    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=radius-tooth_height, h=thickness);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([radius-tooth_height, 0, 0])
                cylinder(r=tooth_height*1.2, h=thickness, $fn=6);
            }
        }
        translate([0, 0, -1])
        cylinder(r=hole, h=thickness+2);
        
        // Decorative spokes cutout
        if (radius > 15) {
            for (i = [0:5]) {
                rotate([0, 0, i * 60 + 30])
                translate([radius*0.5, 0, -1])
                cylinder(r=radius*0.2, h=thickness+2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SWIRL DISC MODULE (Painted swirl art on rotating disc)
// ═══════════════════════════════════════════════════════════════════════════
module swirl_disc(radius, rot, is_inner=true) {
    rotate([0, 0, rot])
    color(is_inner ? C_SWIRL : C_SKY_LIGHT, 0.9) {
        difference() {
            cylinder(r=radius, h=3);
            // Center hole
            translate([0, 0, -1])
            cylinder(r=radius*0.15, h=5);
        }
        
        // Painted swirl pattern (raised lines)
        color(C_SKY_LIGHT)
        for (arm = [0:2]) {
            rotate([0, 0, arm * 120])
            for (r = [radius*0.2 : radius*0.15 : radius*0.9]) {
                rotate([0, 0, r * 3])
                translate([r, 0, 3])
                sphere(r=2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LARGE SWIRL ASSEMBLY (Two discs + gears)
// ═══════════════════════════════════════════════════════════════════════════
module swirl_assembly_large(rot_inner, rot_outer) {
    // Inner disc (back)
    translate([0, 0, 0])
    swirl_disc(55, rot_inner, true);
    
    // Center gear (visible between discs)
    translate([0, 0, 3])
    gear(16, 12, 3, 4);
    
    // Outer disc (front)
    translate([0, 0, 6])
    swirl_disc(50, rot_outer, false);
    
    // Edge gears (decorative, connecting)
    for (a = [45, 135, 225, 315]) {
        rotate([0, 0, a])
        translate([45, 0, 3])
        rotate([0, 0, -rot_inner * 2])
        gear(12, 8, 3, 2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SMALL SWIRL ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════
module swirl_assembly_small(rot_inner, rot_outer) {
    // Inner disc
    translate([0, 0, 0])
    swirl_disc(35, rot_inner, true);
    
    // Center gear
    translate([0, 0, 3])
    gear(12, 8, 3, 3);
    
    // Outer disc
    translate([0, 0, 6])
    swirl_disc(30, rot_outer, false);
    
    // Edge gears
    for (a = [60, 180, 300]) {
        rotate([0, 0, a])
        translate([30, 0, 3])
        rotate([0, 0, -rot_inner * 2])
        gear(10, 6, 3, 2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIND PATH PANEL (Static, one piece with cutouts)
// ═══════════════════════════════════════════════════════════════════════════
module wind_path_panel() {
    color(C_SKY, 0.95)
    difference() {
        // Main panel (covers upper portion of scene)
        translate([0, IH*0.35, 0])
        cube([IW, IH*0.65, 3]);
        
        // Cutout for LARGE swirl (center)
        translate([IW*0.45, IH*0.65, -1])
        cylinder(r=58, h=5);
        
        // Cutout for SMALL swirl (right of large)
        translate([IW*0.72, IH*0.55, -1])
        cylinder(r=38, h=5);
        
        // Cutout for MOON swirl (far right)
        translate([IW*0.88, IH*0.75, -1])
        cylinder(r=45, h=5);
        
        // Star holes (12 positions)
        star_positions = [
            [0.08, 0.85], [0.18, 0.78], [0.28, 0.88],
            [0.35, 0.72], [0.55, 0.82], [0.62, 0.68],
            [0.25, 0.58], [0.40, 0.48], [0.58, 0.52],
            [0.75, 0.45], [0.82, 0.62], [0.68, 0.75]
        ];
        for (s = star_positions) {
            translate([s[0]*IW, s[1]*IH, -1])
            cylinder(d=20, h=5);
        }
        
        // Cutout for cypress area (left side)
        translate([-1, IH*0.35, -1])
        cube([IW*0.15, IH*0.35, 5]);
        
        // Cutout for lighthouse area
        translate([IW*0.12, IH*0.35, -1])
        cube([IW*0.12, IH*0.35, 5]);
    }
    
    // Wind flow brush strokes (raised detail)
    color(C_SKY_LIGHT)
    translate([0, IH*0.35, 3]) {
        // Flowing lines from left to center swirl
        for (i = [0:8]) {
            y_off = i * 8;
            hull() {
                translate([5, y_off + 40, 0]) sphere(r=2);
                translate([IW*0.2, y_off + 50 + sin(i*30)*10, 0]) sphere(r=2);
                translate([IW*0.35, y_off + 55 + sin(i*40)*15, 0]) sphere(r=2);
            }
        }
        
        // Lines from center swirl to small swirl
        for (i = [0:5]) {
            y_off = i * 10;
            hull() {
                translate([IW*0.55, IH*0.25 + y_off, 0]) sphere(r=2);
                translate([IW*0.65, IH*0.20 + y_off - 5, 0]) sphere(r=2);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAR WITH TWINKLE GEAR
// ═══════════════════════════════════════════════════════════════════════════
module star_with_gear(rot) {
    // LED glow (back)
    color(C_STAR, 0.8)
    translate([0, 0, -5])
    cylinder(d=15, h=3);
    
    // Twinkle gear (front, rotates)
    rotate([0, 0, rot])
    color(C_GEAR) {
        difference() {
            cylinder(d=22, h=2);
            // Three gaps for light to pass through
            for (a = [0:2]) {
                rotate([0, 0, a * 120 + 20])
                translate([0, 0, -1])
                linear_extrude(height=4)
                polygon([[0, 0], [15, -4], [15, 4]]);
            }
            translate([0, 0, -1])
            cylinder(d=4, h=4);
        }
    }
    
    // Painted halo ring (static, on wind panel)
    color(C_STAR, 0.3)
    translate([0, 0, 2])
    difference() {
        cylinder(d=28, h=1);
        translate([0, 0, -1])
        cylinder(d=18, h=3);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOON WITH PHASE AND ROTATING OUTER RING
// ═══════════════════════════════════════════════════════════════════════════
module moon_assembly(outer_rot, phase=0.3) {
    // LED glow (back)
    color(C_MOON, 0.5)
    translate([0, 0, -3])
    cylinder(r=35, h=2);
    
    // Moon disc
    color(C_MOON)
    cylinder(r=25, h=4);
    
    // Phase shadow (crescent)
    color(C_SKY)
    translate([15 - phase*30, 0, 4])
    cylinder(r=22, h=2);
    
    // Outer rotating ring with swirl pattern
    rotate([0, 0, outer_rot])
    color(C_MOON, 0.7)
    difference() {
        cylinder(r=42, h=3);
        translate([0, 0, -1])
        cylinder(r=32, h=5);
    }
    
    // Concentric swirl lines on outer ring
    rotate([0, 0, outer_rot])
    color("#e0c050")
    for (r = [34, 37, 40]) {
        difference() {
            cylinder(r=r+1, h=4);
            translate([0, 0, -1])
            cylinder(r=r, h=6);
            // Break the ring into segments
            for (a = [0:3]) {
                rotate([0, 0, a * 90 + 20])
                translate([0, 0, -1])
                cube([50, 3, 6]);
            }
        }
    }
    
    // Gear at edge
    translate([40, 0, 0])
    rotate([0, 0, -outer_rot * 3])
    gear(14, 10, 3, 3);
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIFF (2.5D Relief with decorative gears on left)
// ═══════════════════════════════════════════════════════════════════════════
module cliff() {
    // Main cliff body
    color(C_CLIFF)
    hull() {
        translate([0, 0, 0]) cylinder(r=20, h=20);
        translate([50, 10, 0]) cylinder(r=25, h=20);
        translate([80, 5, 0]) cylinder(r=15, h=18);
        translate([70, IH*0.30, 0]) cylinder(r=20, h=15);
        translate([40, IH*0.35, 0]) cylinder(r=25, h=12);
        translate([10, IH*0.32, 0]) cylinder(r=18, h=15);
    }
    
    // Cliff texture layers
    color(C_CLIFF_DARK)
    for (i = [0:6]) {
        translate([10 + i*10, 5 + i*3, 15 + i*0.5])
        scale([1.5, 1, 0.3])
        sphere(r=8);
    }
    
    // Vertical striations
    color("#5a4a3a")
    for (i = [0:4]) {
        translate([15 + i*15, IH*0.15, 0])
        cube([3, IH*0.15, 18]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// DECORATIVE GEARS (Left side of cliff)
// ═══════════════════════════════════════════════════════════════════════════
module cliff_gears(rot) {
    // Large gear (back)
    translate([0, IH*0.15, -5])
    rotate([0, 0, rot])
    gear(24, 25, 4, 5);
    
    // Medium gear 1
    translate([-5, IH*0.32, -3])
    rotate([0, 0, -rot * 1.5])
    gear(18, 18, 4, 4);
    
    // Medium gear 2
    translate([15, IH*0.05, -2])
    rotate([0, 0, rot * 0.8])
    gear(20, 20, 4, 4);
    
    // Small gears
    translate([30, IH*0.25, 0])
    rotate([0, 0, -rot * 2])
    gear(14, 12, 3, 3);
    
    translate([-10, IH*0.45, 2])
    rotate([0, 0, rot * 1.2])
    gear(12, 10, 3, 3);
    
    translate([5, IH*0.02, 0])
    rotate([0, 0, -rot * 1.8])
    gear(16, 14, 3, 3);
    
    // Tiny accent gears
    translate([25, IH*0.38, 3])
    rotate([0, 0, rot * 3])
    gear(10, 7, 2, 2);
    
    translate([-8, IH*0.22, 4])
    rotate([0, 0, -rot * 2.5])
    gear(8, 5, 2, 1.5);
}

// ═══════════════════════════════════════════════════════════════════════════
// CYPRESS TREE (Large, Van Gogh style)
// ═══════════════════════════════════════════════════════════════════════════
module cypress() {
    color(C_CYPRESS) {
        // Trunk
        translate([0, 0, 0])
        cylinder(r1=6, r2=4, h=20);
        
        // Foliage - flame-like swirling shape
        for (z = [15:6:100]) {
            sf = 1 - (z-15)/100;
            rotate([0, 0, z * 3])  // Twist as it goes up
            translate([0, 0, z])
            scale([sf * 1.2, sf * 0.8, 1])
            cylinder(r1=18*sf, r2=8*sf, h=12);
        }
        
        // Brush stroke texture
        color("#0a2d0a")
        for (z = [20:10:90]) {
            for (a = [0:40:320]) {
                rotate([0, 0, a + z*2])
                translate([8 * (1 - z/100), 0, z])
                scale([0.3, 0.1, 1])
                sphere(r=8);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIGHTHOUSE
// ═══════════════════════════════════════════════════════════════════════════
module lighthouse(beam_rot) {
    // Tower
    color(C_LIGHTHOUSE)
    cylinder(r1=10, r2=7, h=50);
    
    // Stripes
    color("#8b4513")
    for (z = [8, 22, 36]) {
        translate([0, 0, z])
        cylinder(r=9 - z*0.05, h=6);
    }
    
    // Lamp room base
    translate([0, 0, 50])
    color("#333")
    cylinder(r=10, h=3);
    
    // Lamp room (glass)
    translate([0, 0, 53])
    color("LightYellow", 0.6)
    difference() {
        cylinder(r=8, h=12);
        translate([0, 0, 1])
        cylinder(r=7, h=12);
    }
    
    // Light source
    translate([0, 0, 57])
    color("Yellow")
    sphere(r=4);
    
    // Rotating beam slit disc
    translate([0, 0, 55])
    rotate([0, 0, beam_rot])
    color("#333", 0.8)
    difference() {
        cylinder(r=9, h=8);
        // Slit opening (30 degrees)
        translate([0, 0, -1])
        linear_extrude(height=10)
        polygon([[0, 0], [12, -2], [12, 2]]);
    }
    
    // Roof
    translate([0, 0, 65])
    color("#8b4513")
    cylinder(r1=10, r2=3, h=8);
    
    // HUT at base
    translate([12, -5, 0])
    color(C_LIGHTHOUSE) {
        cube([18, 15, 12]);
        // Roof
        translate([0, 0, 12])
        rotate([0, 90, 0])
        linear_extrude(height=18)
        polygon([[0, 0], [-8, 7.5], [0, 15]]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVE WITH VISIBLE LINKAGE
// ═══════════════════════════════════════════════════════════════════════════
module wave_layer(width, phase_offset, layer_num) {
    wave_color = C_WAVE[layer_num];
    bob = 5 * sin(wave_phase + phase_offset);
    
    translate([0, bob, 0]) {
        // Wave body
        color(wave_color, 0.9)
        linear_extrude(height=4)
        polygon(concat(
            [[0, 0]],
            [for (x = [0:5:width]) [x, 8 + 4*sin(x*0.1 + phase_offset/30)]],
            [[width, 0]]
        ));
        
        // Wave curls
        for (i = [0:floor(width/40)]) {
            x = 20 + i * 40;
            if (x < width - 20) {
                translate([x, 10, 0])
                rotate([0, 0, (i % 2) * 180])
                color(wave_color)
                scale([1, 0.6, 1])
                rotate_extrude(angle=180)
                translate([8, 0, 0])
                circle(r=3);
            }
        }
        
        // Foam tips
        color(C_FOAM)
        for (i = [0:floor(width/50)]) {
            x = 30 + i * 50;
            if (x < width - 10) {
                translate([x, 15, 4])
                scale([1.5, 0.8, 0.4])
                sphere(r=5);
            }
        }
        
        // Linkage pivot point (visible)
        translate([width/2, -5, 2])
        color(C_GEAR_DARK)
        cylinder(d=8, h=6);
    }
    
    // Linkage rod (visible)
    translate([width/2, -5 + bob, -15])
    color(C_GEAR) {
        cylinder(d=4, h=20);
        // Connection joint
        translate([0, 0, 0])
        sphere(d=8);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WAVE MECHANISM (Exposed gears in corner)
// ═══════════════════════════════════════════════════════════════════════════
module wave_mechanism(rot) {
    // Main drive gear
    translate([0, 0, 0])
    rotate([0, 0, rot])
    gear(30, 35, 5, 6);
    
    // Secondary gears
    translate([45, -20, 0])
    rotate([0, 0, -rot * 1.2])
    gear(24, 28, 5, 5);
    
    translate([30, 25, 0])
    rotate([0, 0, -rot * 0.8])
    gear(20, 22, 5, 4);
    
    translate([70, 10, 0])
    rotate([0, 0, rot * 1.5])
    gear(18, 18, 4, 4);
    
    // Small linking gears
    translate([55, -35, 2])
    rotate([0, 0, rot * 2])
    gear(14, 14, 3, 3);
    
    translate([80, -15, 2])
    rotate([0, 0, -rot * 2.2])
    gear(12, 12, 3, 3);
    
    // Crank arms (connect to wave linkages)
    for (i = [0:4]) {
        rotate([0, 0, rot + i * 72])
        translate([25, 0, 5])
        color(C_GEAR_DARK) {
            cube([40, 4, 3]);
            translate([40, 2, 1.5])
            sphere(d=6);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BIRD
// ═══════════════════════════════════════════════════════════════════════════
module bird(wing_angle) {
    color("#333") {
        // Body
        scale([1.8, 0.8, 0.6])
        sphere(r=3);
        
        // Head
        translate([5, 0, 0])
        sphere(r=2);
        
        // Beak
        translate([7, 0, 0])
        rotate([0, 90, 0])
        cylinder(r1=0.8, r2=0, h=3);
        
        // Wings
        for (side = [-1, 1]) {
            translate([0, 0, side * 2])
            rotate([side * wing_angle, 0, 0])
            scale([1, 0.1, 0.8])
            sphere(r=8);
        }
        
        // Tail
        translate([-5, 0, 0])
        scale([2, 0.3, 0.15])
        sphere(r=3);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FRAME (Rustic wood, simple)
// ═══════════════════════════════════════════════════════════════════════════
module frame() {
    color(C_FRAME)
    difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1])
        cube([IW, IH, 12]);
    }
    
    // Wood grain texture
    color("#4a3020")
    for (i = [0:10]) {
        // Top rail
        translate([FW + i*30, H - FW/2, 10])
        cube([15, 2, 1]);
        // Bottom rail
        translate([FW + i*30, FW/2, 10])
        cube([15, 2, 1]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// LED Panel (back)
color("DarkBlue", 0.5)
translate([0, 0, Z_LED])
cube([W, H, 3]);

// Diffuser
color("White", 0.3)
translate([FW, FW, Z_DIFFUSER])
cube([IW, IH, 2]);

// Star LEDs (12 positions)
star_positions = [
    [0.08, 0.85], [0.18, 0.78], [0.28, 0.88],
    [0.35, 0.72], [0.55, 0.82], [0.62, 0.68],
    [0.25, 0.58], [0.40, 0.48], [0.58, 0.52],
    [0.75, 0.45], [0.82, 0.62], [0.68, 0.75]
];

// Swirl assemblies (at Z_SWIRL_INNER to Z_SWIRL_OUTER)
// Large central swirl
translate([FW + IW*0.45, FW + IH*0.65, Z_SWIRL_INNER])
swirl_assembly_large(swirl_rot_ccw, swirl_rot_cw);

// Small swirl (right of large)
translate([FW + IW*0.72, FW + IH*0.55, Z_SWIRL_INNER])
swirl_assembly_small(swirl_rot_cw, swirl_rot_ccw);

// Wind path panel with star gears
translate([FW, FW, Z_WIND_PANEL]) {
    wind_path_panel();
    
    // Star twinkle gears on panel
    for (i = [0:len(star_positions)-1]) {
        s = star_positions[i];
        if (s[1] > 0.40) {  // Only stars in sky area
            translate([s[0]*IW, s[1]*IH, 0])
            star_with_gear(star_gear_rot + i*30);
        }
    }
}

// Moon assembly (upper right)
translate([FW + IW*0.88, FW + IH*0.75, Z_SWIRL_INNER])
moon_assembly(moon_outer_rot, 0.3);

// Cliff with decorative gears
translate([FW, FW, Z_CLIFF]) {
    cliff();
    cliff_gears(swirl_rot_cw * 0.5);
}

// Cypress tree (large, in front)
translate([FW + 25, FW + IH*0.38, Z_CYPRESS])
cypress();

// Lighthouse
translate([FW + 70, FW + IH*0.35, Z_CLIFF])
rotate([-90, 0, 0])
lighthouse(lighthouse_rot);

// Waves (5 cliff-side layers)
for (i = [0:4]) {
    wave_width = 80 + i * 30;  // Perspective: back waves shorter
    translate([FW + 90, FW + 5 + i*3, Z_WAVE_START + i*4])
    wave_layer(wave_width, i * 60, i);
}

// Waves (2-3 right side, calmer)
for (i = [0:2]) {
    wave_width = 100 - i * 20;  // Perspective
    translate([FW + IW*0.5 + i*30, FW + 5, Z_WAVE_START + i*4])
    wave_layer(wave_width, i * 45 + 180, min(i, 4));
}

// Wave mechanism (exposed in right corner)
translate([FW + IW*0.75, FW + 20, Z_WAVE_MECH])
wave_mechanism(wave_phase);

// Birds (flock of 3-4)
bird_visible = (bird_cycle > 0.1 && bird_cycle < 0.25);  // Visible 15% of cycle
if (bird_visible) {
    bird_progress = (bird_cycle - 0.1) / 0.15;  // 0 to 1 during visible time
    bird_x = IW * (0.9 - bird_progress * 0.7);  // Right to left
    bird_y = IH * (0.5 + bird_progress * 0.3);  // Lower to upper
    wing_flap = 25 * sin(bird_cycle * 360 * 8);  // Flapping
    
    for (i = [0:3]) {
        translate([FW + bird_x + i*15, FW + bird_y + i*5, Z_CYPRESS + 20 + i*3])
        rotate([0, 0, 150])  // Flying direction
        bird(wing_flap + i*10);
    }
}

// Frame
translate([0, 0, Z_FRAME])
frame();

// ═══════════════════════════════════════════════════════════════════════════
// DEBUG INFO
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V27 - STEAMPUNK VAN GOGH");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Dimensions:", W, "×", H, "×", D, "mm");
echo("Frame width:", FW, "mm");
echo("Animation time:", t);
echo("Bird visible:", bird_visible);
echo("═══════════════════════════════════════════════════════════════════════");
