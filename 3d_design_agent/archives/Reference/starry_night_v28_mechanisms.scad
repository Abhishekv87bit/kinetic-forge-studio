// ═══════════════════════════════════════════════════════════════════════════════
// STARRY NIGHT V28 - MECHANISM INTEGRATION
// ═══════════════════════════════════════════════════════════════════════════════
// Building on V27.2 visual assembly
// Adding: Four-bar linkage, gear train, coupler rods
// ═══════════════════════════════════════════════════════════════════════════════

$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════════
// VISIBILITY TOGGLES (1=show, 0=hide)
// ═══════════════════════════════════════════════════════════════════════════════
SHOW_FRAME = 1;
SHOW_SKY = 1;
SHOW_CLIFF = 1;
SHOW_LIGHTHOUSE = 1;
SHOW_CYPRESS = 1;
SHOW_WIND_PANEL = 1;
SHOW_WAVES = 1;
SHOW_SWIRLS = 1;
SHOW_MOON = 1;
SHOW_GEARS_DECORATIVE = 1;

// MECHANISM TOGGLES
SHOW_MOTOR = 1;
SHOW_GEAR_TRAIN = 1;
SHOW_FOUR_BAR = 1;
SHOW_COUPLER_RODS = 1;
SHOW_PIVOT_POINTS = 1;

// DEBUG TOGGLES
SHOW_ZONE_BOUNDARIES = 0;
SHOW_Z_MARKERS = 0;
TRANSPARENT_CLIFF = 0;  // Set to 1 to see mechanism inside cliff

// ═══════════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS (LOCKED)
// ═══════════════════════════════════════════════════════════════════════════════
W = 350;            // Total width
H = 275;            // Total height  
D = 80;             // Total depth
FW = 20;            // Frame width
IW = W - FW*2;      // Inner width (310mm)
IH = H - FW*2;      // Inner height (235mm)
ART_W = 302;        // Art area width
ART_H = 202;        // Art area height

LAYER_T = 5;        // Standard layer thickness

// ═══════════════════════════════════════════════════════════════════════════════
// Z-LAYER POSITIONS (LOCKED)
// ═══════════════════════════════════════════════════════════════════════════════
Z_BACK = 0;
Z_GEAR_PLATE = 5;
Z_RICE_TUBE = 6;
Z_MOON_BACK = 8;
Z_SWIRL_DISCS = 10;
Z_MOON_FRONT = 16;
Z_WIND_PANEL = 18;
Z_CLIFF = 22;
Z_LIGHTHOUSE = 25;
Z_WAVES_START = 30;
Z_BOTTOM_GEARS = 35;
Z_FOUR_BAR = 55;    // Mechanism layer
Z_CYPRESS = 55;
Z_FRAME = 70;
Z_BIRD_WIRE = 85;

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════
t = $t;
motor_rpm = 60;
master_reduction = 6;  // 60T/10T = 6:1

// Derived rotation speeds (per animation cycle)
motor_rot = t * 360;
master_rot = motor_rot / master_reduction;
swirl_rot_cw = master_rot * 0.5;
swirl_rot_ccw = -master_rot * 0.7;
moon_rot = master_rot * 0.3;
lighthouse_rot = master_rot * 6;
wave_crank_rot = master_rot * 2;  // Wave crank rotation

// ═══════════════════════════════════════════════════════════════════════════════
// FOUR-BAR LINKAGE PARAMETERS (GRASHOF VERIFIED)
// ═══════════════════════════════════════════════════════════════════════════════
// Grashof: s + l < p + q → 10 + 30 < 25 + 25 → 40 < 50 ✓
crank_length = 10;      // s = shortest (rotating input)
coupler_length = 30;    // l = longest (connecting rod)
rocker_length = 25;     // r = rocker (wave attachment)
ground_length = 25;     // g = fixed distance

// Pivot positions (in mechanism coordinate system)
crank_pivot_x = 80;     // Inside cliff, X position
crank_pivot_y = 25;     // Y position (low, near bottom)
rocker_pivot_x = crank_pivot_x + ground_length;  // 105mm

// Wave pivot line (where waves hinge at cliff edge)
wave_pivot_x = 108;     // Cliff edge X coordinate

// Phase offsets for wave layers (30° apart)
wave_phases = [0, 30, 60, 90, 120, 150];

// ═══════════════════════════════════════════════════════════════════════════════
// GEAR TRAIN PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════
module_size = 1.5;      // Gear module (mm)
motor_teeth = 10;
master_teeth = 60;
wave_drive_teeth = 30;
sky_drive_teeth = 20;
moon_drive_teeth = 24;
idler_teeth = 15;

// Calculate center distances
motor_to_master_dist = (motor_teeth + master_teeth) * module_size / 2;  // 52.5mm
master_to_wave_dist = (master_teeth + wave_drive_teeth) * module_size / 2;  // 67.5mm

// Motor position (inside cliff)
motor_x = FW + 25;      // Inside cliff
motor_y = FW + 30;

// Master gear position
master_x = motor_x + motor_to_master_dist;
master_y = motor_y;

// ═══════════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════════
C_FRAME = "#5a4030";
C_GEAR = "#8b7355";
C_GEAR_BRASS = "#b5a642";
C_SKY = "#1a3a6e";
C_WAVE = "#2a6a8e";
C_CLIFF = "#6b5344";
C_CYPRESS = "#1a3a1a";
C_LIGHTHOUSE = "#c4b498";
C_MOON = "#f0d060";
C_MECHANISM = "#404040";
C_COUPLER = "#cc4444";
C_PIVOT = "#222222";

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITY MODULES
// ═══════════════════════════════════════════════════════════════════════════════

module gear_2d(teeth) {
    // Simplified gear profile
    r = teeth * module_size / 2;
    tooth_depth = module_size * 2.25;
    
    difference() {
        circle(r=r);
        circle(r=r * 0.3);  // Center hole
    }
}

module gear_3d(teeth, thickness=5) {
    r = teeth * module_size / 2;
    difference() {
        cylinder(h=thickness, r=r, $fn=max(teeth*2, 36));
        translate([0, 0, -1])
            cylinder(h=thickness+2, r=3, $fn=24);  // Axle hole
    }
}

module link(length, width=6, thickness=3) {
    hull() {
        cylinder(h=thickness, r=width/2, $fn=24);
        translate([length, 0, 0])
            cylinder(h=thickness, r=width/2, $fn=24);
    }
}

module pivot_pin(height=15) {
    color(C_PIVOT)
    cylinder(h=height, r=2.5, $fn=24);
    
    // Bearing collar
    color("Silver")
    translate([0, 0, height/2])
        cylinder(h=3, r=4, $fn=24);
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOUR-BAR LINKAGE KINEMATICS
// ═══════════════════════════════════════════════════════════════════════════════

// Calculate four-bar positions for given crank angle
function four_bar_solve(theta_crank) = 
    let(
        // Crank endpoint
        Ax = crank_pivot_x,
        Ay = crank_pivot_y,
        Bx = Ax + crank_length * cos(theta_crank),
        By = Ay + crank_length * sin(theta_crank),
        
        // Rocker pivot
        Dx = rocker_pivot_x,
        Dy = crank_pivot_y,  // Same Y as crank pivot (ground is horizontal)
        
        // Distance from B to D
        BD = sqrt((Dx-Bx)*(Dx-Bx) + (Dy-By)*(Dy-By)),
        
        // Angle from D to B
        phi = atan2(By - Dy, Bx - Dx),
        
        // Use law of cosines to find rocker angle
        cos_beta = (rocker_length*rocker_length + BD*BD - coupler_length*coupler_length) 
                   / (2 * rocker_length * BD),
        beta = acos(max(-1, min(1, cos_beta))),  // Clamp to valid range
        
        // Rocker angle (from D toward B, minus beta for "elbow down" config)
        theta_rocker = phi + beta,
        
        // Rocker endpoint (C)
        Cx = Dx + rocker_length * cos(theta_rocker),
        Cy = Dy + rocker_length * sin(theta_rocker)
    )
    // Return: [Bx, By, Cx, Cy, theta_rocker]
    [Bx, By, Cx, Cy, theta_rocker];

// ═══════════════════════════════════════════════════════════════════════════════
// FOUR-BAR MECHANISM MODULE
// ═══════════════════════════════════════════════════════════════════════════════

module four_bar_mechanism(crank_angle) {
    // Solve kinematics
    solution = four_bar_solve(crank_angle);
    Bx = solution[0];  // Crank end
    By = solution[1];
    Cx = solution[2];  // Rocker end (coupler connection)
    Cy = solution[3];
    theta_rocker = solution[4];
    
    translate([0, 0, Z_FOUR_BAR]) {
        // Ground link (fixed) - shown as reference
        color(C_MECHANISM, 0.5)
        translate([crank_pivot_x, crank_pivot_y, 0])
            link(ground_length, 8, 2);
        
        // Crank (rotating input)
        color(C_GEAR_BRASS)
        translate([crank_pivot_x, crank_pivot_y, 2])
            rotate([0, 0, crank_angle])
                link(crank_length, 6, 3);
        
        // Rocker (oscillating output)
        color(C_GEAR_BRASS)
        translate([rocker_pivot_x, crank_pivot_y, 4])
            rotate([0, 0, theta_rocker])
                link(rocker_length, 6, 3);
        
        // Coupler (connecting crank to rocker)
        coupler_angle = atan2(Cy - By, Cx - Bx);
        color(C_COUPLER)
        translate([Bx, By, 6])
            rotate([0, 0, coupler_angle])
                link(coupler_length, 5, 3);
        
        // Pivot pins
        if(SHOW_PIVOT_POINTS) {
            // Ground pivot 1 (crank)
            translate([crank_pivot_x, crank_pivot_y, -5])
                pivot_pin(15);
            
            // Ground pivot 2 (rocker)
            translate([rocker_pivot_x, crank_pivot_y, -5])
                pivot_pin(15);
            
            // Moving pivot 1 (crank-coupler)
            color("Red")
            translate([Bx, By, 6])
                cylinder(h=5, r=3, $fn=24);
            
            // Moving pivot 2 (rocker-coupler)
            color("Blue")
            translate([Cx, Cy, 6])
                cylinder(h=5, r=3, $fn=24);
        }
    }
    
    echo("Rocker angle:", theta_rocker, "° | Coupler Y:", Cy);
}

// ═══════════════════════════════════════════════════════════════════════════════
// WAVE COUPLER RODS
// ═══════════════════════════════════════════════════════════════════════════════

module wave_coupler_rod(wave_index, crank_angle) {
    // Each wave has its own phase offset
    phase = wave_phases[wave_index];
    effective_angle = crank_angle + phase;
    
    // Solve four-bar for this phase
    solution = four_bar_solve(effective_angle);
    Cx = solution[2];
    Cy = solution[3];
    
    // Wave pivot point (at cliff edge)
    wave_pivot_y = FW + 10 + wave_index * 12;  // Stagger waves vertically
    
    // Calculate wave tilt from coupler position
    // Coupler Y drives wave tip up/down
    // Reference position is when coupler Cy equals wave_pivot_y
    wave_tilt = (Cy - crank_pivot_y) * 1.5;  // Amplification factor
    
    // Draw coupler rod from mechanism to wave
    z_wave = Z_WAVES_START + wave_index * 5;
    
    color(C_COUPLER, 0.8)
    translate([0, 0, Z_FOUR_BAR + 8]) {
        // Vertical rod segment (Z direction)
        hull() {
            translate([Cx, Cy, 0])
                sphere(r=2, $fn=16);
            translate([wave_pivot_x, wave_pivot_y, z_wave - Z_FOUR_BAR - 8])
                sphere(r=2, $fn=16);
        }
    }
    
    // Return wave tilt for use in wave rendering
    echo("Wave", wave_index, "tilt:", wave_tilt);
}

// ═══════════════════════════════════════════════════════════════════════════════
// GEAR TRAIN
// ═══════════════════════════════════════════════════════════════════════════════

module motor_assembly() {
    translate([motor_x, motor_y, Z_GEAR_PLATE]) {
        // Motor body (N20)
        color("DimGray")
        translate([0, 0, -20])
            cube([12, 10, 24], center=true);
        
        // Motor shaft
        color("Silver")
        cylinder(h=15, r=1.5, $fn=16);
        
        // Pinion gear
        color(C_GEAR_BRASS)
        translate([0, 0, 8])
            rotate([0, 0, motor_rot])
                gear_3d(motor_teeth, 6);
    }
}

module master_gear() {
    translate([master_x, master_y, Z_GEAR_PLATE]) {
        // Master gear
        color(C_GEAR)
        translate([0, 0, 8])
            rotate([0, 0, master_rot])
                gear_3d(master_teeth, 8);
        
        // Axle
        color("Silver")
        cylinder(h=25, r=3, $fn=24);
    }
}

module gear_train_to_waves() {
    // Idler gears connecting master to wave drive
    
    // Wave drive gear (on camshaft)
    wave_drive_x = crank_pivot_x;
    wave_drive_y = crank_pivot_y;
    
    color(C_GEAR_BRASS)
    translate([wave_drive_x, wave_drive_y, Z_GEAR_PLATE + 8])
        rotate([0, 0, wave_crank_rot])
            gear_3d(wave_drive_teeth, 6);
    
    // Idler gears to span the gap
    // Master is at X≈77.5, wave drive at X=80
    // Need idlers if gap > direct mesh distance
    
    idler1_x = master_x + (master_teeth + idler_teeth) * module_size / 2;
    idler1_y = master_y + 20;
    
    color(C_GEAR)
    translate([idler1_x, idler1_y, Z_GEAR_PLATE + 8])
        rotate([0, 0, -master_rot * (master_teeth/idler_teeth)])
            gear_3d(idler_teeth, 6);
}

module gear_train_to_swirls() {
    // Gear chain from master to swirl discs
    // This needs to span from cliff (X≈77) to swirl center (X≈172)
    
    // This is the 150mm+ gap mentioned in issues
    // We need multiple idler gears
    
    swirl_x = FW + IW * 0.62 * 0.55;  // ≈ 106
    swirl_y = FW + IH * 0.40 + IH * 0.45 * 0.50;  // ≈ 147
    
    // For now, show the target connection point
    if(SHOW_GEAR_TRAIN) {
        color("Yellow", 0.3)
        translate([swirl_x, swirl_y, Z_GEAR_PLATE])
            cylinder(h=Z_SWIRL_DISCS - Z_GEAR_PLATE, r=5, $fn=24);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VISUAL COMPONENTS (Simplified from V27.2)
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

module sky_background() {
    color(C_SKY)
    translate([FW, FW, Z_BACK])
        cube([IW, IH, 3]);
}

module cliff() {
    cliff_w = IW * 0.28;  // 87mm
    cliff_h = IH * 0.52;  // 122mm
    
    alpha = TRANSPARENT_CLIFF ? 0.3 : 1.0;
    color(C_CLIFF, alpha)
    translate([FW, FW, Z_CLIFF])
        cube([cliff_w, cliff_h, LAYER_T]);
}

module lighthouse() {
    lh_x = FW + IW * 0.12;
    lh_y = FW + IH * 0.48;
    
    color(C_LIGHTHOUSE)
    translate([lh_x, lh_y, Z_LIGHTHOUSE])
        rotate([-90, 0, 0])
            cylinder(h=80, r1=10, r2=6, $fn=24);
    
    // Rotating beam
    color("Yellow", 0.5)
    translate([lh_x, lh_y + 70, Z_LIGHTHOUSE])
        rotate([0, lighthouse_rot, 0])
            translate([0, 0, 0])
                cube([60, 3, 3], center=true);
}

module cypress_tree() {
    cy_x = FW + IW * 0.08;
    cy_y = FW + IH * 0.32;
    
    // Multi-layer cypress (simplified)
    for(i = [0:3]) {
        color(i % 2 == 0 ? C_CYPRESS : "#2a4a2a")
        translate([cy_x + i*2, cy_y, Z_CYPRESS + i*2])
            scale([0.5, 1, 0.1])
                sphere(r=30, $fn=24);
    }
}

module wave_layer(index, tilt=0) {
    // Wave position based on index
    is_cliff_wave = index < 5;
    
    if(is_cliff_wave) {
        wave_x = FW + IW * 0.25;
        wave_y = FW + 5 + index * 8;
        wave_z = Z_WAVES_START + index * 5;
        
        color(C_WAVE)
        translate([wave_x, wave_y, wave_z])
            rotate([tilt, 0, 0])  // Tilt around X-axis (tips bob up/down)
                cube([50, 30, LAYER_T]);
    }
}

module waves_assembly() {
    // Calculate tilts from four-bar
    for(i = [0:4]) {
        phase = wave_phases[i];
        effective_angle = wave_crank_rot + phase;
        solution = four_bar_solve(effective_angle);
        Cy = solution[3];
        tilt = (Cy - crank_pivot_y) * 0.8;  // Scale factor
        
        wave_layer(i, tilt);
    }
}

module swirl_disc_big() {
    sx = FW + IW * 0.62 * 0.55;
    sy = FW + IH * 0.40 + IH * 0.45 * 0.50;
    
    // Outer disc (CW)
    color("#c4a060")
    translate([sx, sy, Z_SWIRL_DISCS])
        rotate([0, 0, swirl_rot_cw])
            difference() {
                cylinder(h=3, r=33, $fn=48);
                translate([0, 0, -1])
                    cylinder(h=5, r=30, $fn=48);
            }
    
    // Inner disc (CCW)
    color("#d4b070")
    translate([sx, sy, Z_SWIRL_DISCS + 3])
        rotate([0, 0, swirl_rot_ccw])
            cylinder(h=3, r=28, $fn=48);
}

module swirl_disc_small() {
    sx = FW + IW * 0.62 * 0.85;
    sy = FW + IH * 0.40 + IH * 0.45 * 0.40;
    
    color("#c4a060")
    translate([sx, sy, Z_SWIRL_DISCS])
        rotate([0, 0, -swirl_rot_cw])
            difference() {
                cylinder(h=3, r=20, $fn=36);
                translate([0, 0, -1])
                    cylinder(h=5, r=17, $fn=36);
            }
}

module moon_assembly() {
    mx = FW + IW * 0.85;
    my = FW + IH * 0.78;
    
    // Core
    color(C_MOON)
    translate([mx, my, Z_MOON_FRONT])
        cylinder(h=5, r=30, $fn=48);
    
    // Rotating outer ring
    color("#e0c050")
    translate([mx, my, Z_MOON_FRONT + 5])
        rotate([0, 0, moon_rot])
            difference() {
                cylinder(h=3, r=48, $fn=60);
                translate([0, 0, -1])
                    cylinder(h=5, r=42, $fn=60);
            }
}

module decorative_gears() {
    // Gears under cliff (from V27.2)
    gear_positions = [
        [FW + 30, FW + 15, 25, 1.2],
        [FW + 55, FW + 20, 18, 0.9],
        [FW + 75, FW + 12, 30, 1.5],
        [FW + 45, FW + 35, 15, 0.7],
    ];
    
    for(g = gear_positions) {
        color(C_GEAR)
        translate([g[0], g[1], Z_BOTTOM_GEARS])
            rotate([0, 0, master_rot * g[3]])
                gear_3d(g[2], 5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ZONE BOUNDARY VISUALIZATION (DEBUG)
// ═══════════════════════════════════════════════════════════════════════════════

module zone_boundaries() {
    if(SHOW_ZONE_BOUNDARIES) {
        // CLIFF zone
        color("Red", 0.2)
        translate([FW, FW, 0])
            cube([108, 65, 80]);
        
        // CLIFF_WAVES zone
        color("Blue", 0.2)
        translate([FW + 108, FW, 0])
            cube([52, 69, 80]);
        
        // OCEAN_WAVES zone
        color("Cyan", 0.2)
        translate([FW + 151, FW, 0])
            cube([151, 65, 80]);
        
        // MOON zone
        color("Yellow", 0.2)
        translate([FW + 231, FW + 141, 0])
            cube([69, 61, 80]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════

module main_assembly() {
    // Static elements
    if(SHOW_FRAME) frame();
    if(SHOW_SKY) sky_background();
    if(SHOW_CLIFF) cliff();
    if(SHOW_LIGHTHOUSE) lighthouse();
    if(SHOW_CYPRESS) cypress_tree();
    
    // Moving elements
    if(SHOW_SWIRLS) {
        swirl_disc_big();
        swirl_disc_small();
    }
    if(SHOW_MOON) moon_assembly();
    if(SHOW_WAVES) waves_assembly();
    if(SHOW_GEARS_DECORATIVE) decorative_gears();
    
    // MECHANISM (the new stuff!)
    if(SHOW_MOTOR) motor_assembly();
    if(SHOW_GEAR_TRAIN) {
        master_gear();
        gear_train_to_waves();
        gear_train_to_swirls();
    }
    if(SHOW_FOUR_BAR) four_bar_mechanism(wave_crank_rot);
    if(SHOW_COUPLER_RODS) {
        for(i = [0:4]) {
            wave_coupler_rod(i, wave_crank_rot);
        }
    }
    
    // Debug
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
echo("STARRY NIGHT V28 - MECHANISM INTEGRATION");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("Canvas:", W, "×", H, "×", D, "mm");
echo("Motor position:", motor_x, ",", motor_y);
echo("Motor to Master distance:", motor_to_master_dist, "mm (calculated:", (motor_teeth + master_teeth) * module_size / 2, ")");
echo("Master gear position:", master_x, ",", master_y);
echo("");
echo("FOUR-BAR LINKAGE:");
echo("  Crank:", crank_length, "mm");
echo("  Coupler:", coupler_length, "mm");
echo("  Rocker:", rocker_length, "mm");
echo("  Ground:", ground_length, "mm");
echo("  Grashof:", crank_length, "+", coupler_length, "=", crank_length + coupler_length,
     "<", rocker_length, "+", ground_length, "=", rocker_length + ground_length,
     "→", (crank_length + coupler_length) < (rocker_length + ground_length) ? "VALID" : "INVALID!");
echo("");
echo("ANIMATION:");
echo("  Motor rotation:", motor_rot, "°");
echo("  Master rotation:", master_rot, "°");
echo("  Wave crank rotation:", wave_crank_rot, "°");
echo("═══════════════════════════════════════════════════════════════════════════════");

