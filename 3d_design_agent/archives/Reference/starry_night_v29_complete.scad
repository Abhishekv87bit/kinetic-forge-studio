// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V29 - COMPLETE MECHANISM IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════════
// Based on V27.2 layout + V28 four-bar + user decisions:
//   1. Long idler gear chain (visible brass gears)
//   2. Coupler rods from below (through bottom)
//   3. Idler gear reversal for swirl counter-rotation
//   4. Rice tube: MUST HAVE
//   5. Star twinkle: MUST HAVE
//   6. Bird wire: NICE TO HAVE (simplified)
// ═══════════════════════════════════════════════════════════════════════════════

$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════════
// VISIBILITY TOGGLES (1=show, 0=hide)
// ═══════════════════════════════════════════════════════════════════════════════

// STRUCTURE
SHOW_FRAME = 1;
SHOW_BACK_PANEL = 1;

// STATIC SCENERY
SHOW_SKY = 1;
SHOW_CLIFF = 1;
SHOW_LIGHTHOUSE = 1;
SHOW_CYPRESS = 1;
SHOW_WIND_PANEL = 1;

// MOVING SCENERY
SHOW_WAVES = 1;
SHOW_SWIRLS = 1;
SHOW_MOON = 1;

// MECHANISMS
SHOW_MOTOR = 1;
SHOW_MASTER_GEAR = 1;
SHOW_IDLER_CHAIN = 1;
SHOW_FOUR_BAR = 1;
SHOW_COUPLER_RODS = 1;
SHOW_RICE_TUBE = 1;
SHOW_STAR_TWINKLE = 1;
SHOW_BIRD_WIRE = 0;  // Nice to have, off by default

// DEBUG
SHOW_ZONE_BOUNDARIES = 0;
SHOW_PIVOT_MARKERS = 1;
TRANSPARENT_CLIFF = 0;  // See mechanism inside cliff
SHOW_GEAR_LABELS = 0;

// ═══════════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS (LOCKED)
// ═══════════════════════════════════════════════════════════════════════════════
W = 350;            // Total width
H = 275;            // Total height  
D = 80;             // Total depth
FW = 20;            // Frame width
IW = W - FW*2;      // Inner width (310mm)
IH = H - FW*2;      // Inner height (235mm)
LAYER_T = 5;        // Standard layer thickness
WALL_T = 4;         // Enclosure wall thickness

// ═══════════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS (LOCKED)
// ═══════════════════════════════════════════════════════════════════════════════
Z_BACK = 0;
Z_GEAR_PLATE = 5;
Z_RICE_TUBE = 6;
Z_MOON_BACK = 8;
Z_SWIRL_INNER = 10;
Z_SWIRL_GEARS = 13;
Z_SWIRL_OUTER = 15;
Z_MOON_FRONT = 16;
Z_WIND_PANEL = 18;
Z_CLIFF = 22;
Z_LIGHTHOUSE = 25;
Z_STARS = 28;
Z_WAVES_START = 30;
Z_BOTTOM_GEARS = 35;
Z_FOUR_BAR = 55;
Z_COUPLER_RODS = 58;
Z_CYPRESS = 60;
Z_FRAME = 70;
Z_BIRD_WIRE = 85;

// ═══════════════════════════════════════════════════════════════════════════════
// GEAR PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════
M = 1.5;                    // Module (mm)
GEAR_T = 5;                 // Gear thickness
MOTOR_TEETH = 10;
MASTER_TEETH = 60;
IDLER_TEETH = 15;
WAVE_DRIVE_TEETH = 30;
SWIRL_DRIVE_TEETH = 20;
MOON_DRIVE_TEETH = 24;
STAR_TWINKLE_TEETH = 12;

// Gear radii (calculated)
MOTOR_R = MOTOR_TEETH * M / 2;      // 7.5mm
MASTER_R = MASTER_TEETH * M / 2;    // 45mm
IDLER_R = IDLER_TEETH * M / 2;      // 11.25mm
WAVE_R = WAVE_DRIVE_TEETH * M / 2;  // 22.5mm
SWIRL_R = SWIRL_DRIVE_TEETH * M / 2;// 15mm
MOON_R = MOON_DRIVE_TEETH * M / 2;  // 18mm
STAR_R = STAR_TWINKLE_TEETH * M / 2;// 9mm

// Center distance formula: (T1 + T2) * M / 2
function gear_dist(t1, t2) = (t1 + t2) * M / 2;

// ═══════════════════════════════════════════════════════════════════════════════
// MOTOR & MASTER GEAR POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════
MOTOR_X = FW + 25;
MOTOR_Y = FW + 35;
MASTER_X = MOTOR_X + gear_dist(MOTOR_TEETH, MASTER_TEETH);  // 77.5mm from left
MASTER_Y = MOTOR_Y;

// ═══════════════════════════════════════════════════════════════════════════════
// FOUR-BAR LINKAGE (GRASHOF VERIFIED: 10+30=40 < 25+25=50 ✓)
// ═══════════════════════════════════════════════════════════════════════════════
CRANK_L = 10;       // Shortest (s) - rotating input
COUPLER_L = 30;     // Longest (l) - connecting rod
ROCKER_L = 25;      // Rocker (r) - wave attachment
GROUND_L = 25;      // Ground (g) - fixed distance

// Four-bar pivot positions
CRANK_PIVOT_X = FW + 80;
CRANK_PIVOT_Y = FW + 20;
ROCKER_PIVOT_X = CRANK_PIVOT_X + GROUND_L;  // 105mm

// Wave pivot line (cliff edge)
WAVE_PIVOT_X = FW + 108;

// Phase offsets for 6 wave layers (30° apart)
WAVE_PHASES = [0, 30, 60, 90, 120, 150];

// ═══════════════════════════════════════════════════════════════════════════════
// SWIRL DISC POSITIONS (with counter-rotation idler)
// ═══════════════════════════════════════════════════════════════════════════════
BIG_SWIRL_X = FW + IW * 0.35;    // ≈129mm
BIG_SWIRL_Y = FW + IH * 0.68;   // ≈180mm
BIG_SWIRL_R_OUTER = 33;
BIG_SWIRL_R_INNER = 30;

SMALL_SWIRL_X = FW + IW * 0.52; // ≈181mm
SMALL_SWIRL_Y = FW + IH * 0.58; // ≈156mm
SMALL_SWIRL_R_OUTER = 20;
SMALL_SWIRL_R_INNER = 17;

// ═══════════════════════════════════════════════════════════════════════════════
// MOON POSITION
// ═══════════════════════════════════════════════════════════════════════════════
MOON_X = FW + IW * 0.85;        // ≈284mm
MOON_Y = FW + IH * 0.78;        // ≈203mm
MOON_R_CORE = 25;
MOON_R_RING = 40;

// ═══════════════════════════════════════════════════════════════════════════════
// RICE TUBE PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════
RICE_TUBE_L = 180;              // Length (slightly less than full width)
RICE_TUBE_D = 20;               // Diameter
RICE_TUBE_X = FW + IW/2;        // Center X
RICE_TUBE_Y = FW - 15;          // Below bottom edge (behind panel)
RICE_TUBE_AMPLITUDE = 12;       // Degrees of rock

// ═══════════════════════════════════════════════════════════════════════════════
// STAR TWINKLE POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════
STAR_POSITIONS = [
    [FW + IW*0.25, FW + IH*0.88],   // Star 1 - upper left sky
    [FW + IW*0.45, FW + IH*0.92],   // Star 2 - upper center
    [FW + IW*0.65, FW + IH*0.85],   // Star 3 - upper right
    [FW + IW*0.75, FW + IH*0.72],   // Star 4 - mid right
    [FW + IW*0.55, FW + IH*0.75],   // Star 5 - center
];

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
t = $t;

// Motor and gear rotations
motor_rot = t * 360 * 2;                    // 2 rotations per cycle
master_rot = motor_rot / 6;                 // 6:1 reduction
wave_crank_rot = master_rot * 2;            // Wave drive
swirl_rot = master_rot * 0.8;               // Swirl speed
moon_rot = master_rot * 0.3;                // Moon speed (slow)
star_rot = master_rot * 1.5;                // Star twinkle speed
rice_rock = RICE_TUBE_AMPLITUDE * sin(wave_crank_rot);  // Sync with waves

// ═══════════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════════
C_FRAME = "#5a4030";
C_BACK = "#1a1a2e";
C_SKY = "#1a3a6e";
C_GEAR_BRASS = "#b5a642";
C_GEAR_DARK = "#8b7355";
C_WAVE = "#2a6a8e";
C_WAVE_LIGHT = "#4a9abe";
C_CLIFF = "#6b5344";
C_CYPRESS = "#1a3a1a";
C_LIGHTHOUSE = "#c4b498";
C_LIGHTHOUSE_LIGHT = "#ffffaa";
C_MOON = "#f0d060";
C_SWIRL_INNER = "#d4b070";
C_SWIRL_OUTER = "#c4a060";
C_MECHANISM = "#404040";
C_COUPLER = "#cc4444";
C_PIVOT = "#222222";
C_RICE_TUBE = "#8b4513";
C_STAR = "#ffffcc";
C_BIRD = "#333333";
C_WIRE = "#888888";

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITY MODULES
// ═══════════════════════════════════════════════════════════════════════════════

// Gear with proper involute-ish profile
module gear_2d(teeth, hole_r=3) {
    r = teeth * M / 2;
    tooth_h = M * 2.25;
    difference() {
        union() {
            circle(r=r - M*0.5);
            for(i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([r - M*0.3, 0])
                    circle(r=M*0.8, $fn=12);
            }
        }
        circle(r=hole_r);
    }
}

module gear_3d(teeth, thickness=GEAR_T, hole_r=3) {
    linear_extrude(height=thickness)
        gear_2d(teeth, hole_r);
}

module link_2d(length, width=6) {
    hull() {
        circle(r=width/2);
        translate([length, 0])
            circle(r=width/2);
    }
}

module link_3d(length, width=6, thickness=3) {
    linear_extrude(height=thickness)
        link_2d(length, width);
}

module pivot_pin(h=15, r=2.5) {
    color(C_PIVOT)
    cylinder(h=h, r=r, $fn=24);
}

module axle(h=30, r=1.5) {
    color("Silver")
    cylinder(h=h, r=r, $fn=16);
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOUR-BAR KINEMATICS SOLVER
// ═══════════════════════════════════════════════════════════════════════════════

function four_bar_solve(theta_crank) = 
    let(
        // Crank endpoint (B)
        Bx = CRANK_PIVOT_X + CRANK_L * cos(theta_crank),
        By = CRANK_PIVOT_Y + CRANK_L * sin(theta_crank),
        
        // Rocker ground pivot (D)
        Dx = ROCKER_PIVOT_X,
        Dy = CRANK_PIVOT_Y,
        
        // Distance B to D
        BD = sqrt((Dx-Bx)*(Dx-Bx) + (Dy-By)*(Dy-By)),
        
        // Angle from D toward B
        phi = atan2(By - Dy, Bx - Dx),
        
        // Law of cosines for rocker angle
        cos_beta = (ROCKER_L*ROCKER_L + BD*BD - COUPLER_L*COUPLER_L) / (2 * ROCKER_L * BD),
        beta = acos(max(-1, min(1, cos_beta))),
        
        // Rocker angle (elbow-down configuration)
        theta_rocker = phi + beta,
        
        // Rocker endpoint (C)
        Cx = Dx + ROCKER_L * cos(theta_rocker),
        Cy = Dy + ROCKER_L * sin(theta_rocker)
    )
    [Bx, By, Cx, Cy, theta_rocker];

// ═══════════════════════════════════════════════════════════════════════════════
// IDLER GEAR CHAIN - CALCULATED POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════

// Route 1: Master → Wave Drive (short chain)
WAVE_DRIVE_X = CRANK_PIVOT_X;
WAVE_DRIVE_Y = CRANK_PIVOT_Y;

// Route 2: Master → Swirl (needs idler chain going UP)
// Master at (77.5, 55), Big Swirl at (~129, ~180)
// Distance: ~130mm, need ~6 idlers

SWIRL_CHAIN = [
    // [X, Y, teeth, rotation_direction]
    [MASTER_X + 30, MASTER_Y + 25, IDLER_TEETH, -1],    // Idler 1
    [MASTER_X + 50, MASTER_Y + 55, IDLER_TEETH, 1],     // Idler 2
    [MASTER_X + 65, MASTER_Y + 90, IDLER_TEETH, -1],    // Idler 3
    [MASTER_X + 75, MASTER_Y + 120, IDLER_TEETH, 1],    // Idler 4
    [BIG_SWIRL_X - 25, BIG_SWIRL_Y - 20, SWIRL_DRIVE_TEETH, -1], // Drive gear
];

// Counter-rotation idler for swirls (creates opposite rotation)
SWIRL_COUNTER_X = BIG_SWIRL_X + 20;
SWIRL_COUNTER_Y = BIG_SWIRL_Y - 15;

// Route 3: Swirl → Moon (horizontal chain along top)
MOON_CHAIN = [
    [BIG_SWIRL_X + 45, BIG_SWIRL_Y, IDLER_TEETH, 1],
    [BIG_SWIRL_X + 70, BIG_SWIRL_Y - 5, IDLER_TEETH, -1],
    [BIG_SWIRL_X + 95, BIG_SWIRL_Y - 10, IDLER_TEETH, 1],
    [BIG_SWIRL_X + 120, BIG_SWIRL_Y - 5, IDLER_TEETH, -1],
    [MOON_X - 25, MOON_Y - 20, MOON_DRIVE_TEETH, 1],
];

// Route 4: Star twinkle chain (branches off swirl chain)
STAR_CHAIN = [
    [STAR_POSITIONS[0][0] + 15, STAR_POSITIONS[0][1] - 10, IDLER_TEETH, 1],
    [STAR_POSITIONS[1][0] - 10, STAR_POSITIONS[1][1] - 15, IDLER_TEETH, -1],
];

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: MOTOR ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════

module motor_assembly() {
    translate([MOTOR_X, MOTOR_Y, Z_GEAR_PLATE]) {
        // N20 motor body
        color("DimGray")
        translate([0, 0, -22])
            cube([12, 10, 24], center=true);
        
        // Motor shaft
        axle(20, 1.5);
        
        // Pinion gear
        color(C_GEAR_BRASS)
        translate([0, 0, 5])
            rotate([0, 0, motor_rot])
                gear_3d(MOTOR_TEETH, 6, 2);
        
        if(SHOW_GEAR_LABELS)
            color("White") translate([0, 15, 10])
                text("MOTOR 10T", size=4, halign="center");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: MASTER GEAR
// ═══════════════════════════════════════════════════════════════════════════════

module master_gear_assembly() {
    translate([MASTER_X, MASTER_Y, Z_GEAR_PLATE]) {
        // Axle
        axle(35, 3);
        
        // Master gear
        color(C_GEAR_DARK)
        translate([0, 0, 5])
            rotate([0, 0, master_rot])
                gear_3d(MASTER_TEETH, 8, 4);
        
        // Decorative spokes
        color(C_GEAR_BRASS)
        translate([0, 0, 6])
            rotate([0, 0, master_rot])
                for(i = [0:5])
                    rotate([0, 0, i*60])
                        translate([MASTER_R * 0.5, 0, 0])
                            cylinder(h=6, r=3, $fn=6);
        
        if(SHOW_GEAR_LABELS)
            color("White") translate([0, MASTER_R + 10, 15])
                text("MASTER 60T", size=4, halign="center");
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: IDLER GEAR CHAIN
// ═══════════════════════════════════════════════════════════════════════════════

module idler_chain() {
    // Chain to swirls
    for(i = [0:len(SWIRL_CHAIN)-1]) {
        g = SWIRL_CHAIN[i];
        translate([g[0], g[1], Z_GEAR_PLATE + 5]) {
            axle(25, 1.5);
            color(C_GEAR_BRASS)
            translate([0, 0, 8])
                rotate([0, 0, master_rot * 2 * g[3]])
                    gear_3d(g[2], 5, 1.5);
        }
    }
    
    // Chain to moon
    for(i = [0:len(MOON_CHAIN)-1]) {
        g = MOON_CHAIN[i];
        translate([g[0], g[1], Z_GEAR_PLATE + 5]) {
            axle(20, 1.5);
            color(C_GEAR_BRASS)
            translate([0, 0, 5])
                rotate([0, 0, swirl_rot * 1.5 * g[3]])
                    gear_3d(g[2], 5, 1.5);
        }
    }
    
    // Counter-rotation idler for swirl
    translate([SWIRL_COUNTER_X, SWIRL_COUNTER_Y, Z_SWIRL_GEARS]) {
        axle(15, 1.5);
        color(C_GEAR_DARK)
        translate([0, 0, 2])
            rotate([0, 0, -swirl_rot])
                gear_3d(IDLER_TEETH, 5, 1.5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: FOUR-BAR LINKAGE
// ═══════════════════════════════════════════════════════════════════════════════

module four_bar_mechanism() {
    solution = four_bar_solve(wave_crank_rot);
    Bx = solution[0];
    By = solution[1];
    Cx = solution[2];
    Cy = solution[3];
    theta_rocker = solution[4];
    
    translate([0, 0, Z_FOUR_BAR]) {
        // Ground link (reference - dotted)
        color(C_MECHANISM, 0.3)
        translate([CRANK_PIVOT_X, CRANK_PIVOT_Y, 0])
            link_3d(GROUND_L, 8, 2);
        
        // Crank (rotating input) - connected to wave drive gear
        color(C_GEAR_BRASS)
        translate([CRANK_PIVOT_X, CRANK_PIVOT_Y, 2])
            rotate([0, 0, wave_crank_rot])
                link_3d(CRANK_L, 6, 3);
        
        // Rocker (oscillating output)
        color(C_GEAR_BRASS)
        translate([ROCKER_PIVOT_X, CRANK_PIVOT_Y, 4])
            rotate([0, 0, theta_rocker])
                link_3d(ROCKER_L, 6, 3);
        
        // Coupler (connects crank to rocker)
        coupler_angle = atan2(Cy - By, Cx - Bx);
        color(C_COUPLER)
        translate([Bx, By, 6])
            rotate([0, 0, coupler_angle])
                link_3d(COUPLER_L, 5, 3);
        
        // Wave drive gear on crank shaft
        color(C_GEAR_DARK)
        translate([CRANK_PIVOT_X, CRANK_PIVOT_Y, -5])
            rotate([0, 0, wave_crank_rot])
                gear_3d(WAVE_DRIVE_TEETH, 5, 2);
        
        // Pivot markers
        if(SHOW_PIVOT_MARKERS) {
            // Crank pivot (ground)
            translate([CRANK_PIVOT_X, CRANK_PIVOT_Y, -8])
                pivot_pin(20);
            
            // Rocker pivot (ground)
            translate([ROCKER_PIVOT_X, CRANK_PIVOT_Y, -8])
                pivot_pin(20);
            
            // Moving joint B (crank-coupler)
            color("Red")
            translate([Bx, By, 8])
                sphere(r=3, $fn=16);
            
            // Moving joint C (rocker-coupler)
            color("Blue")
            translate([Cx, Cy, 8])
                sphere(r=3, $fn=16);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: COUPLER RODS (FROM BELOW)
// ═══════════════════════════════════════════════════════════════════════════════

module coupler_rods() {
    for(i = [0:4]) {
        phase = WAVE_PHASES[i];
        effective_angle = wave_crank_rot + phase;
        solution = four_bar_solve(effective_angle);
        Cy = solution[3];
        
        // Wave layer position
        wave_z = Z_WAVES_START + i * 5;
        wave_y = FW + 15 + i * 10;
        
        // Coupler endpoint Y position drives wave tilt
        tilt_amount = (Cy - CRANK_PIVOT_Y) * 1.2;
        
        // Rod from four-bar (below) up to wave pivot
        color(C_COUPLER, 0.8) {
            // Vertical section going UP from mechanism to wave
            rod_bottom_z = Z_GEAR_PLATE + 10;
            rod_top_z = wave_z - 2;
            
            translate([WAVE_PIVOT_X - 5 - i*3, wave_y, rod_bottom_z]) {
                // Vertical rod
                cylinder(h=rod_top_z - rod_bottom_z, r=1.5, $fn=12);
                
                // Connection ball at top
                translate([0, 0, rod_top_z - rod_bottom_z])
                    sphere(r=2.5, $fn=16);
                
                // Connection ball at bottom
                sphere(r=2.5, $fn=16);
            }
        }
        
        // Echo tilt for debugging
        if(i == 0)
            echo("Wave 0 tilt:", tilt_amount, "° at crank angle:", effective_angle);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: WAVE LAYERS (DRIVEN BY FOUR-BAR)
// ═══════════════════════════════════════════════════════════════════════════════

module wave_layer(index) {
    phase = WAVE_PHASES[index];
    effective_angle = wave_crank_rot + phase;
    solution = four_bar_solve(effective_angle);
    Cy = solution[3];
    
    // Calculate tilt from coupler position
    tilt = (Cy - CRANK_PIVOT_Y) * 0.8;
    
    wave_z = Z_WAVES_START + index * 5;
    wave_y = FW + 15 + index * 10;
    wave_x = WAVE_PIVOT_X;
    
    // Color gradient for depth
    wave_color = index < 3 ? C_WAVE : C_WAVE_LIGHT;
    
    color(wave_color)
    translate([wave_x, wave_y, wave_z])
        // Pivot around X-axis at the cliff edge
        rotate([tilt, 0, 0])
            translate([0, 0, 0])
                // Wave shape (simplified - replace with traced shape)
                scale([1, 0.3, 0.1])
                    rotate([90, 0, 0])
                        cylinder(h=80, r1=30, r2=25, $fn=32);
}

module waves_assembly() {
    for(i = [0:4])
        wave_layer(i);
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: SWIRL DISCS (WITH COUNTER-ROTATION VIA IDLER)
// ═══════════════════════════════════════════════════════════════════════════════

module swirl_disc(x, y, r_outer, r_inner, rot_cw, rot_ccw) {
    translate([x, y, Z_SWIRL_INNER]) {
        // Inner disc (driven by gear chain - one direction)
        color(C_SWIRL_INNER)
        rotate([0, 0, rot_cw])
            difference() {
                cylinder(h=4, r=r_inner, $fn=48);
                translate([0, 0, -1])
                    cylinder(h=6, r=r_inner * 0.6, $fn=48);
                // Swirl pattern cutouts
                for(i = [0:5])
                    rotate([0, 0, i * 60 + 15])
                        translate([r_inner * 0.7, 0, -1])
                            cylinder(h=6, r=r_inner * 0.15, $fn=16);
            }
        
        // Outer disc (driven by counter-rotation idler - opposite direction)
        color(C_SWIRL_OUTER)
        translate([0, 0, Z_SWIRL_OUTER - Z_SWIRL_INNER])
        rotate([0, 0, rot_ccw])
            difference() {
                cylinder(h=3, r=r_outer, $fn=48);
                translate([0, 0, -1])
                    cylinder(h=5, r=r_inner + 1, $fn=48);
                // Swirl pattern cutouts
                for(i = [0:7])
                    rotate([0, 0, i * 45])
                        translate([r_outer * 0.85, 0, -1])
                            scale([0.6, 1, 1])
                                cylinder(h=5, r=r_outer * 0.1, $fn=12);
            }
        
        // Center axle
        axle(25, 2);
    }
}

module swirls_assembly() {
    // Big swirl
    swirl_disc(BIG_SWIRL_X, BIG_SWIRL_Y, 
               BIG_SWIRL_R_OUTER, BIG_SWIRL_R_INNER,
               swirl_rot, -swirl_rot * 1.4);
    
    // Small swirl (opposite rotation)
    swirl_disc(SMALL_SWIRL_X, SMALL_SWIRL_Y,
               SMALL_SWIRL_R_OUTER, SMALL_SWIRL_R_INNER,
               -swirl_rot * 0.8, swirl_rot * 1.2);
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: MOON ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════

module moon_assembly() {
    translate([MOON_X, MOON_Y, Z_MOON_FRONT]) {
        // Core (fixed or slow)
        color(C_MOON)
        cylinder(h=5, r=MOON_R_CORE, $fn=48);
        
        // Crescent cutout
        color(C_SKY)
        translate([8, 5, -1])
            cylinder(h=7, r=MOON_R_CORE * 0.7, $fn=32);
        
        // Rotating outer ring with arcs
        color(C_MOON, 0.8)
        translate([0, 0, 5])
        rotate([0, 0, moon_rot])
            difference() {
                cylinder(h=3, r=MOON_R_RING, $fn=60);
                translate([0, 0, -1])
                    cylinder(h=5, r=MOON_R_RING - 8, $fn=60);
                // Arc gaps
                for(i = [0:3])
                    rotate([0, 0, i * 90 + 45])
                        translate([MOON_R_RING - 4, 0, -1])
                            cylinder(h=5, r=6, $fn=24);
            }
        
        // Drive gear underneath
        color(C_GEAR_BRASS)
        translate([0, 0, -8])
            rotate([0, 0, moon_rot])
                gear_3d(MOON_DRIVE_TEETH, 5, 2);
        
        // Axle
        translate([0, 0, -15])
            axle(30, 2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: RICE TUBE (MUST HAVE)
// ═══════════════════════════════════════════════════════════════════════════════

module rice_tube() {
    translate([RICE_TUBE_X, RICE_TUBE_Y, Z_RICE_TUBE]) {
        // Center pivot bearing
        color(C_PIVOT)
        cylinder(h=RICE_TUBE_D + 5, r=4, $fn=24);
        
        // Tube (rocks around Z-axis, synchronized with waves)
        color(C_RICE_TUBE)
        rotate([0, 0, rice_rock])  // XY plane rotation (Z-axis)
            translate([-RICE_TUBE_L/2, 0, RICE_TUBE_D/2 + 2])
                rotate([0, 90, 0])
                    difference() {
                        cylinder(h=RICE_TUBE_L, r=RICE_TUBE_D/2, $fn=32);
                        // Hollow inside
                        translate([0, 0, 3])
                            cylinder(h=RICE_TUBE_L - 6, r=RICE_TUBE_D/2 - 2, $fn=32);
                    }
        
        // Pivot collar
        color("Silver")
        translate([0, 0, RICE_TUBE_D/2])
            rotate([0, 90, rice_rock])
                cylinder(h=20, r=5, center=true, $fn=24);
        
        // Cam follower arm (connects to wave mechanism)
        color(C_MECHANISM)
        rotate([0, 0, rice_rock])
            translate([0, -RICE_TUBE_D, RICE_TUBE_D/2 + 2])
                cube([10, 30, 3], center=true);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: STAR TWINKLE GEARS (MUST HAVE)
// ═══════════════════════════════════════════════════════════════════════════════

module star_twinkle() {
    for(i = [0:len(STAR_POSITIONS)-1]) {
        pos = STAR_POSITIONS[i];
        
        translate([pos[0], pos[1], Z_STARS]) {
            // LED hole (backlit)
            color(C_STAR, 0.8)
            translate([0, 0, -3])
                cylinder(h=3, r=4, $fn=24);
            
            // Rotating shutter gear (creates twinkle)
            color(C_GEAR_BRASS)
            translate([0, 0, 0])
                rotate([0, 0, star_rot * (i % 2 == 0 ? 1 : -1)])
                    difference() {
                        gear_3d(STAR_TWINKLE_TEETH, 3, 1.5);
                        // Aperture holes that pass over LED
                        for(j = [0:2])
                            rotate([0, 0, j * 120])
                                translate([STAR_R * 0.6, 0, -1])
                                    cylinder(h=5, r=3, $fn=16);
                    }
            
            // Tiny axle
            axle(10, 1);
        }
    }
    
    // Drive chain connecting stars (simplified)
    color(C_GEAR_DARK, 0.5)
    for(i = [0:len(STAR_POSITIONS)-2]) {
        p1 = STAR_POSITIONS[i];
        p2 = STAR_POSITIONS[i+1];
        hull() {
            translate([p1[0], p1[1], Z_STARS + 2])
                cylinder(h=1, r=2, $fn=12);
            translate([p2[0], p2[1], Z_STARS + 2])
                cylinder(h=1, r=2, $fn=12);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: BIRD WIRE (NICE TO HAVE - SIMPLIFIED)
// ═══════════════════════════════════════════════════════════════════════════════

module bird_wire() {
    wire_y = FW + IH * 0.42;
    
    // Wire track
    color(C_WIRE)
    translate([FW + 10, wire_y, Z_BIRD_WIRE])
        rotate([0, 90, 0])
            cylinder(h=IW - 20, r=1, $fn=12);
    
    // Bird silhouette (simple, slides along wire)
    bird_x = FW + 50 + (IW - 100) * (0.5 + 0.4 * sin(t * 360 * 0.2));
    
    color(C_BIRD)
    translate([bird_x, wire_y, Z_BIRD_WIRE + 3]) {
        // Body
        scale([1.5, 0.5, 0.3])
            sphere(r=8, $fn=16);
        // Head
        translate([10, 0, 2])
            sphere(r=4, $fn=12);
        // Tail
        translate([-12, 0, 0])
            scale([2, 0.3, 0.5])
                sphere(r=5, $fn=12);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: STATIC SCENERY
// ═══════════════════════════════════════════════════════════════════════════════

module frame() {
    color(C_FRAME)
    translate([0, 0, Z_FRAME])
    difference() {
        cube([W, H, 10]);
        translate([FW, FW, -1])
            cube([IW, IH, 12]);
    }
}

module back_panel() {
    color(C_BACK)
    translate([FW, FW, Z_BACK])
        cube([IW, IH, 3]);
}

module sky_background() {
    color(C_SKY)
    translate([FW, FW, Z_BACK + 3])
        cube([IW, IH, 2]);
}

module cliff() {
    cliff_w = IW * 0.28;
    cliff_h = IH * 0.52;
    
    alpha = TRANSPARENT_CLIFF ? 0.3 : 1.0;
    color(C_CLIFF, alpha)
    translate([FW, FW, Z_CLIFF])
        cube([cliff_w, cliff_h, LAYER_T]);
}

module lighthouse() {
    lh_x = FW + IW * 0.14;
    lh_y = FW + IH * 0.40;
    
    // Tower
    color(C_LIGHTHOUSE)
    translate([lh_x, lh_y, Z_LIGHTHOUSE])
        rotate([-90, 0, 0])
            cylinder(h=70, r1=10, r2=6, $fn=24);
    
    // Lamp room
    color(C_LIGHTHOUSE)
    translate([lh_x, lh_y + 70, Z_LIGHTHOUSE])
        rotate([-90, 0, 0])
            cylinder(h=12, r=8, $fn=24);
    
    // Rotating light beam
    color(C_LIGHTHOUSE_LIGHT, 0.6)
    translate([lh_x, lh_y + 76, Z_LIGHTHOUSE])
        rotate([0, master_rot * 3, 0])
            cube([80, 2, 4], center=true);
}

module cypress_tree() {
    cy_x = FW + IW * 0.12;
    cy_y = FW + IH * 0.25;
    
    // Multi-layer simplified cypress
    for(i = [0:3]) {
        layer_color = i % 2 == 0 ? C_CYPRESS : "#2a4a2a";
        color(layer_color)
        translate([cy_x, cy_y, Z_CYPRESS + i * 3])
            scale([0.25 + i*0.03, 1, 0.15])
                cylinder(h=100, r1=15, r2=8, $fn=24);
    }
}

module wind_panel() {
    // Wind path panel with swirl cutouts
    panel_w = IW * 0.64;
    panel_h = IH * 0.40;
    panel_y = FW + IH * 0.50;
    
    color("#2a5a9e")
    translate([FW, panel_y, Z_WIND_PANEL])
    difference() {
        cube([panel_w, panel_h, LAYER_T]);
        
        // Big swirl cutout
        translate([BIG_SWIRL_X - FW, BIG_SWIRL_Y - panel_y, -1])
            cylinder(h=LAYER_T + 2, r=BIG_SWIRL_R_OUTER + 3, $fn=48);
        
        // Small swirl cutout
        translate([SMALL_SWIRL_X - FW, SMALL_SWIRL_Y - panel_y, -1])
            cylinder(h=LAYER_T + 2, r=SMALL_SWIRL_R_OUTER + 3, $fn=36);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE: DEBUG - ZONE BOUNDARIES
// ═══════════════════════════════════════════════════════════════════════════════

module zone_boundaries() {
    if(SHOW_ZONE_BOUNDARIES) {
        // Cliff zone
        color("Red", 0.15)
        translate([FW, FW, 0])
            cube([108, 122, D]);
        
        // Wave zone
        color("Blue", 0.15)
        translate([FW + 108, FW, 0])
            cube([IW - 108, 69, D]);
        
        // Sky zone
        color("Cyan", 0.15)
        translate([FW, FW + IH*0.4, 0])
            cube([IW*0.65, IH*0.6, D]);
        
        // Moon zone
        color("Yellow", 0.15)
        translate([MOON_X - 50, MOON_Y - 50, 0])
            cube([100, 100, D]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════

module main_assembly() {
    // ─── STRUCTURE ───
    if(SHOW_FRAME) frame();
    if(SHOW_BACK_PANEL) back_panel();
    
    // ─── STATIC SCENERY ───
    if(SHOW_SKY) sky_background();
    if(SHOW_CLIFF) cliff();
    if(SHOW_LIGHTHOUSE) lighthouse();
    if(SHOW_CYPRESS) cypress_tree();
    if(SHOW_WIND_PANEL) wind_panel();
    
    // ─── MOVING SCENERY ───
    if(SHOW_WAVES) waves_assembly();
    if(SHOW_SWIRLS) swirls_assembly();
    if(SHOW_MOON) moon_assembly();
    
    // ─── MECHANISMS ───
    if(SHOW_MOTOR) motor_assembly();
    if(SHOW_MASTER_GEAR) master_gear_assembly();
    if(SHOW_IDLER_CHAIN) idler_chain();
    if(SHOW_FOUR_BAR) four_bar_mechanism();
    if(SHOW_COUPLER_RODS) coupler_rods();
    if(SHOW_RICE_TUBE) rice_tube();
    if(SHOW_STAR_TWINKLE) star_twinkle();
    if(SHOW_BIRD_WIRE) bird_wire();
    
    // ─── DEBUG ───
    zone_boundaries();
}

// ═══════════════════════════════════════════════════════════════════════════════
// RENDER
// ═══════════════════════════════════════════════════════════════════════════════

main_assembly();

// ═══════════════════════════════════════════════════════════════════════════════
// DIAGNOSTIC OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════

echo("═══════════════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V29 - COMPLETE MECHANISM IMPLEMENTATION");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("USER DECISIONS IMPLEMENTED:");
echo("  1. ✓ Long idler gear chain (visible brass gears)");
echo("  2. ✓ Coupler rods from below");
echo("  3. ✓ Idler gear reversal for swirl counter-rotation");
echo("  4. ✓ Rice tube (MUST HAVE)");
echo("  5. ✓ Star twinkle gears (MUST HAVE)");
echo("  6. ○ Bird wire (NICE TO HAVE - toggle SHOW_BIRD_WIRE)");
echo("");
echo("GEAR TRAIN:");
echo("  Motor:", MOTOR_TEETH, "T @ M", M, "→ R=", MOTOR_R, "mm");
echo("  Master:", MASTER_TEETH, "T @ M", M, "→ R=", MASTER_R, "mm");
echo("  Center distance:", gear_dist(MOTOR_TEETH, MASTER_TEETH), "mm");
echo("  Reduction ratio: 6:1");
echo("");
echo("FOUR-BAR (GRASHOF VERIFIED):");
echo("  Crank:", CRANK_L, "mm (s)");
echo("  Coupler:", COUPLER_L, "mm (l)");
echo("  Rocker:", ROCKER_L, "mm (r)");
echo("  Ground:", GROUND_L, "mm (g)");
echo("  Check: s+l=", CRANK_L + COUPLER_L, " < p+q=", ROCKER_L + GROUND_L,
     "→", (CRANK_L + COUPLER_L) < (ROCKER_L + GROUND_L) ? "VALID ✓" : "INVALID!");
echo("");
echo("RICE TUBE:");
echo("  Length:", RICE_TUBE_L, "mm");
echo("  Diameter:", RICE_TUBE_D, "mm");
echo("  Amplitude:", RICE_TUBE_AMPLITUDE, "°");
echo("  Synced to wave phase");
echo("");
echo("STAR TWINKLE:");
echo("  Stars:", len(STAR_POSITIONS));
echo("  Gear teeth:", STAR_TWINKLE_TEETH, "T");
echo("  Apertures: 3 per gear");
echo("");
echo("ANIMATION STATE:");
echo("  t =", t);
echo("  Motor rotation:", motor_rot, "°");
echo("  Master rotation:", master_rot, "°");
echo("  Wave crank:", wave_crank_rot, "°");
echo("  Rice rock:", rice_rock, "°");
echo("═══════════════════════════════════════════════════════════════════════════════");
