// ============================================================================
// PROJECT: Starry Night Kinetic Automaton
// VERSION: V30
// DESCRIPTION: Van Gogh-inspired kinetic wooden automaton with motorized
//              waves, rotating swirls, oscillating moon, and sweeping
//              lighthouse beam, driven by single motor through mechanical
//              distribution system hidden within the landscape.
// LAST MODIFIED: 2026-01-16
// STATUS: Verification Build
// ============================================================================
// LOCKED DECISIONS (DO NOT MODIFY):
//   L001: Frame 350x275x100mm     L007: 3 wave layers
//   L002: 3mm plywood             L008: 120 deg phase offset
//   L003: N20 5V 60RPM motor      L009: 5 swirl discs
//   L004: Motor inside cliff      L010: No front glass
//   L005: Module 1.5mm gears      L011: Sky zone Y=120mm
//   L006: 6:1 gear ratio          L012: USB 5V power
// ============================================================================

// === COMPONENT SURVIVAL FLAGS ===
// Set to true as each component is verified present
FRAME_PRESENT = true;
CLIFF_PRESENT = true;
MOTOR_PRESENT = true;
GEARS_PRESENT = true;
WAVES_PRESENT = true;
SWIRLS_PRESENT = true;
MOON_PRESENT = true;
LIGHTHOUSE_PRESENT = true;
VILLAGE_PRESENT = true;
CYPRESS_PRESENT = true;
STARS_PRESENT = true;

// ============================================================================
// SECTION 1: PARAMETERS (Locked - from specification)
// ============================================================================

// --- Frame Dimensions (L001) ---
FRAME_WIDTH = 350;      // X-axis (mm)
FRAME_HEIGHT = 275;     // Y-axis (mm)
FRAME_DEPTH = 100;      // Z-axis (mm)
WALL_THICKNESS = 3;     // Material thickness (L002)
BORDER_WIDTH = 15;      // Front frame decorative border

// --- Zone Boundaries (L011) ---
ZONE_SKY_MIN = 120;     // Sky starts at Y=120
ZONE_SKY_MAX = 272;     // Sky ends at Y=272
ZONE_LAND_MIN = 40;     // Landscape starts at Y=40
ZONE_LAND_MAX = 120;    // Landscape ends at Y=120
ZONE_WAVE_MIN = 0;      // Wave zone starts at Y=0
ZONE_WAVE_MAX = 40;     // Wave zone ends at Y=40

// --- Derived Dimensions ---
INNER_WIDTH = FRAME_WIDTH - WALL_THICKNESS * 2;   // 344mm
INNER_HEIGHT = FRAME_HEIGHT - WALL_THICKNESS * 2; // 269mm
INNER_DEPTH = FRAME_DEPTH - WALL_THICKNESS * 2;   // 94mm

// ============================================================================
// SECTION 2: MOTOR & GEAR PARAMETERS (L003, L005, L006)
// ============================================================================

// --- Motor Specs (N20) ---
MOTOR_RPM = 60;             // Input speed
MOTOR_VOLTAGE = 5;          // USB power (L012)
MOTOR_SHAFT_DIA = 6;        // mm

// --- Gear Parameters (L005, L006) ---
GEAR_MODULE = 1.5;          // Tooth size parameter
PINION_TEETH = 10;          // Motor gear
MASTER_TEETH = 60;          // Driven gear
GEAR_THICKNESS = 5;         // Gear face width

// --- CALCULATED Gear Dimensions (NEVER estimate) ---
PINION_RADIUS = PINION_TEETH * GEAR_MODULE / 2;   // 7.5mm
MASTER_RADIUS = MASTER_TEETH * GEAR_MODULE / 2;   // 45mm
GEAR_CENTER_DISTANCE = (PINION_TEETH + MASTER_TEETH) * GEAR_MODULE / 2; // 52.5mm EXACT

// --- Gear Ratio ---
GEAR_RATIO = MASTER_TEETH / PINION_TEETH;         // 6:1
OUTPUT_RPM = MOTOR_RPM / GEAR_RATIO;              // 10 RPM

// --- Motor Position (L004 - inside cliff) ---
MOTOR_POS = [45, 80, -10];  // Hidden in cliff cavity

// ============================================================================
// SECTION 3: WAVE PARAMETERS (L007, L008)
// ============================================================================

WAVE_COUNT = 3;             // Number of wave layers (L007)
WAVE_PHASE_OFFSET = 120;    // Degrees between layers (L008)
WAVE_AMPLITUDE = 12;        // mm displacement each direction
WAVE_LENGTH = 340;          // Width of wave bar
WAVE_HEIGHT = 20;           // Wave profile height
WAVE_THICKNESS = 3;         // Material thickness

// --- Wave Z-Positions (front to back) ---
WAVE_Z = [30, 20, 10];      // Wave 1, 2, 3 Z-layers
WAVE_Y = [25, 20, 15];      // Wave 1, 2, 3 Y-positions

// ============================================================================
// SECTION 4: SWIRL PARAMETERS (L009)
// ============================================================================

SWIRL_COUNT = 5;            // Number of swirl discs (L009)

// Swirl specifications: [X, Y, Diameter, Direction (1=CW, -1=CCW), Speed ratio]
SWIRL_SPECS = [
    [180, 200, 50, 1, 1.0],     // Swirl 1: Main large swirl
    [120, 220, 35, -1, 0.5],    // Swirl 2: Upper left, slow CCW
    [240, 180, 40, 1, 0.67],    // Swirl 3: Right side CW
    [280, 220, 30, -1, 0.5],    // Swirl 4: Upper right CCW
    [150, 170, 25, 1, 0.33]     // Swirl 5: Smallest, slowest
];

SWIRL_Z = 15;               // Z-layer for all swirls
SWIRL_THICKNESS = 3;        // Disc thickness

// ============================================================================
// SECTION 5: MOON PARAMETERS
// ============================================================================

MOON_POS = [300, 240];      // X, Y position
MOON_DIAMETER = 35;         // Crescent moon size
MOON_SWING = 15;            // Oscillation amplitude (degrees)
MOON_Z = 25;                // Z-layer
MOON_THICKNESS = 3;

// ============================================================================
// SECTION 6: LIGHTHOUSE PARAMETERS
// ============================================================================

LIGHTHOUSE_POS = [320, 80]; // X, Y base position
LIGHTHOUSE_HEIGHT = 40;     // Tower height
LIGHTHOUSE_WIDTH = 15;      // Tower width
LIGHTHOUSE_BEAM_Z = 20;     // Beam disc Z-layer
LIGHTHOUSE_GEAR_RATIO = 4;  // 1:4 reduction (2.5 RPM)
LIGHTHOUSE_Z = 10;          // Tower Z-layer

// ============================================================================
// SECTION 7: LANDSCAPE PARAMETERS
// ============================================================================

// --- Cliff (contains motor cavity) ---
CLIFF_POS = [0, 40];        // Bottom-left position
CLIFF_WIDTH = 80;           // Width of cliff area
CLIFF_HEIGHT = 110;         // Height to Y=150

// --- Cypress Tree ---
CYPRESS_POS = [45, 40];     // Base position
CYPRESS_HEIGHT = 160;       // Tall flame-shaped tree
CYPRESS_WIDTH = 30;         // Width at base

// --- Village ---
VILLAGE_START_X = 120;
VILLAGE_END_X = 260;
VILLAGE_Y = 50;

// --- Stars ---
STAR_COUNT = 12;
STAR_Z = 35;
// Star positions: [X, Y, size]
STAR_POSITIONS = [
    [80, 250, 8], [130, 260, 6], [170, 245, 7], [210, 265, 5],
    [250, 250, 8], [290, 240, 6], [100, 230, 5], [160, 220, 6],
    [220, 230, 7], [270, 255, 5], [310, 260, 6], [140, 255, 5]
];

// ============================================================================
// SECTION 8: Z-LAYER STACK (from specification)
// ============================================================================

Z_BACK_WALL = -20;      // Enclosure back panel
Z_MOTOR = -10;          // Motor layer
Z_GEAR = -5;            // Gear train
Z_LINKAGE = -3;         // Connecting rods, linkages
Z_MAIN = 0;             // Reference datum - main mechanism plane
Z_VILLAGE = 5;          // Village houses
Z_WAVE_3 = 10;          // Back wave + Lighthouse tower
Z_SWIRL = 15;           // Swirl discs
Z_WAVE_2 = 20;          // Middle wave + Lighthouse beam
Z_MOON = 25;            // Moon disc
Z_WAVE_1 = 30;          // Front wave
Z_STARS = 35;           // Star cutouts
Z_FRAME = 50;           // Front decorative frame

// ============================================================================
// SECTION 9: COLOR PALETTE
// ============================================================================

C_FRAME = "Gold";
C_BACK = "#2a1810";         // Dark wood
C_CLIFF = "#1a3020";        // Dark green-brown
C_VILLAGE = "#3d2817";      // Brown
C_WAVE = ["#061a3a", "#0a2a5e", "#0e3a82"];  // Dark to medium blue
C_SWIRL = "#f4e04d";        // Yellow swirl
C_MOON = "#f5f0c4";         // Pale yellow
C_STARS = "#ffffff";        // White stars
C_LIGHTHOUSE = "#8b4513";   // Saddle brown
C_LIGHTHOUSE_BEAM = "#ffff88"; // Light yellow
C_CYPRESS = "#0d260d";      // Dark green
C_MOTOR = "DarkGray";
C_GEAR = "Silver";
C_PINION = "Gold";

// ============================================================================
// SECTION 10: ANIMATION VARIABLES
// ============================================================================

// $t is OpenSCAD's built-in animation parameter (0 to 1)
t = $t;

// Motor rotation (full rotation per animation cycle at 60 RPM)
motor_angle = t * 360;

// Master gear rotation (6:1 reduction)
master_angle = -motor_angle / GEAR_RATIO;  // 60 degrees per cycle, opposite direction

// Wave positions (sinusoidal oscillation with phase offsets)
function wave_offset(phase) = WAVE_AMPLITUDE * sin(t * 360 + phase);
wave_1_offset = wave_offset(0);
wave_2_offset = wave_offset(WAVE_PHASE_OFFSET);
wave_3_offset = wave_offset(WAVE_PHASE_OFFSET * 2);

// Moon oscillation
moon_angle = MOON_SWING * sin(t * 360);

// Lighthouse beam rotation (1:4 ratio = 2.5 RPM)
lighthouse_angle = master_angle / LIGHTHOUSE_GEAR_RATIO;

// ============================================================================
// SECTION 11: VISIBILITY TOGGLES (for debugging)
// ============================================================================

SHOW_FRAME = true;
SHOW_BACK = true;
SHOW_CLIFF = true;
SHOW_MOTOR = true;
SHOW_GEARS = true;
SHOW_WAVES = true;
SHOW_SWIRLS = true;
SHOW_MOON = true;
SHOW_LIGHTHOUSE = true;
SHOW_VILLAGE = true;
SHOW_CYPRESS = true;
SHOW_STARS = true;
SHOW_LINKAGES = true;

TRANSPARENT_CLIFF = false;  // Set true to see motor cavity
DEBUG_MODE = false;         // Show debug helpers

// ============================================================================
// SECTION 12: UTILITY MODULES
// ============================================================================

// Simple gear visualization (for preview)
module simple_gear(teeth, mod, thickness, center_hole=0) {
    pitch_radius = teeth * mod / 2;
    difference() {
        union() {
            // Main gear body
            cylinder(h=thickness, r=pitch_radius, $fn=max(teeth*4, 36));
            // Hub
            cylinder(h=thickness*1.2, r=pitch_radius/3, $fn=24);
        }
        // Center hole
        if (center_hole > 0) {
            translate([0, 0, -1])
                cylinder(h=thickness*1.5, r=center_hole/2, $fn=24);
        }
        // Tooth profile (simplified as notches)
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * 360/teeth])
                translate([pitch_radius * 0.9, 0, -0.5])
                    cylinder(h=thickness+1, r=mod*0.3, $fn=6);
        }
    }
}

// Wave profile shape
module wave_profile(length, height, thickness) {
    // Sinusoidal wave shape
    points = concat(
        [[0, 0]],
        [for (x = [0:5:length])
            [x, height/2 + (height/2) * sin(x * 720 / length)]],
        [[length, 0]]
    );
    linear_extrude(height=thickness)
        polygon(points);
}

// Crescent moon shape
module crescent_moon(diameter, thickness) {
    difference() {
        circle(d=diameter, $fn=64);
        translate([diameter*0.25, 0, 0])
            circle(d=diameter*0.85, $fn=64);
    }
}

// Swirl disc with spiral pattern
module swirl_disc(diameter, thickness) {
    difference() {
        cylinder(h=thickness, d=diameter, $fn=64);
        // Spiral cutout pattern
        for (i = [0:5]) {
            rotate([0, 0, i * 60])
                translate([diameter*0.15, 0, -0.5])
                    linear_extrude(height=thickness+1)
                        scale([1, 0.3])
                            circle(d=diameter*0.25, $fn=24);
        }
        // Center hole
        translate([0, 0, -0.5])
            cylinder(h=thickness+1, d=4, $fn=16);
    }
}

// Star shape
module star(size, points=5, thickness=3) {
    linear_extrude(height=thickness) {
        polygon([for (i = [0:points*2-1])
            let(r = i % 2 == 0 ? size : size*0.4,
                a = i * 180 / points - 90)
            [r * cos(a), r * sin(a)]
        ]);
    }
}

// House silhouette
module house(width, height, roof_height, thickness) {
    linear_extrude(height=thickness) {
        polygon([
            [0, 0],
            [width, 0],
            [width, height],
            [width/2, height + roof_height],
            [0, height]
        ]);
    }
}

// Church with steeple
module church(width, height, steeple_height, thickness) {
    linear_extrude(height=thickness) {
        union() {
            // Main body
            square([width, height]);
            // Steeple
            translate([width/2 - width*0.15, height])
                polygon([
                    [0, 0],
                    [width*0.3, 0],
                    [width*0.15, steeple_height]
                ]);
        }
    }
}

// Cypress tree (flame shape)
module cypress_tree(width, height, thickness) {
    linear_extrude(height=thickness) {
        // Multiple overlapping ellipses for flame effect
        hull() {
            translate([width/2, height*0.1])
                scale([1, 3])
                    circle(d=width*0.9, $fn=32);
        }
        translate([width/2, 0])
            square([width*0.15, height*0.15], center=true);
    }
}

// Cliff profile with motor cavity
module cliff_profile(width, height, cavity=true) {
    difference() {
        // Main cliff shape (organic curve)
        polygon([
            [0, 0],
            [0, height],
            [width*0.3, height*0.95],
            [width*0.5, height*0.85],
            [width*0.7, height*0.6],
            [width*0.85, height*0.4],
            [width, height*0.2],
            [width, 0]
        ]);

        // Motor cavity (if enabled)
        if (cavity) {
            translate([width*0.2, height*0.3])
                square([width*0.5, height*0.4]);
        }
    }
}

// Rolling hills profile
module rolling_hills(width, height) {
    points = concat(
        [[0, 0]],
        [for (x = [0:10:width])
            [x, height * (0.5 + 0.3*sin(x*3) + 0.2*sin(x*5+45))]],
        [[width, 0]]
    );
    polygon(points);
}

// ============================================================================
// SECTION 13: COMPONENT MODULES
// ============================================================================

// --- Back Wall ---
module back_wall() {
    color(C_BACK)
        translate([0, 0, Z_BACK_WALL])
            cube([FRAME_WIDTH, FRAME_HEIGHT, WALL_THICKNESS]);
}

// --- Front Frame (decorative border) ---
module front_frame() {
    color(C_FRAME)
        translate([0, 0, Z_FRAME])
            difference() {
                cube([FRAME_WIDTH, FRAME_HEIGHT, WALL_THICKNESS]);
                translate([BORDER_WIDTH, BORDER_WIDTH, -0.5])
                    cube([FRAME_WIDTH - BORDER_WIDTH*2,
                          FRAME_HEIGHT - BORDER_WIDTH*2,
                          WALL_THICKNESS + 1]);
            }
}

// --- Side Walls ---
module side_walls() {
    color(C_BACK) {
        // Left wall
        translate([0, 0, Z_BACK_WALL])
            cube([WALL_THICKNESS, FRAME_HEIGHT, FRAME_DEPTH]);
        // Right wall
        translate([FRAME_WIDTH - WALL_THICKNESS, 0, Z_BACK_WALL])
            cube([WALL_THICKNESS, FRAME_HEIGHT, FRAME_DEPTH]);
    }
}

// --- Motor Assembly ---
module motor_assembly() {
    translate(MOTOR_POS) {
        // Motor body (N20 size approximately 12x10x24mm)
        color(C_MOTOR) {
            // Main body
            translate([-6, -5, 0])
                cube([12, 10, 24]);
            // Shaft
            translate([0, 0, 24])
                cylinder(h=10, d=MOTOR_SHAFT_DIA, $fn=16);
        }

        // Pinion gear on shaft
        translate([0, 0, 30])
            rotate([0, 0, motor_angle])
                color(C_PINION)
                    simple_gear(PINION_TEETH, GEAR_MODULE, GEAR_THICKNESS, MOTOR_SHAFT_DIA);
    }
}

// --- Master Gear ---
module master_gear() {
    // Position: motor position + center distance in X
    master_pos = [MOTOR_POS[0] + GEAR_CENTER_DISTANCE, MOTOR_POS[1], MOTOR_POS[2] + 30];

    translate(master_pos)
        rotate([0, 0, master_angle])
            color(C_GEAR)
                simple_gear(MASTER_TEETH, GEAR_MODULE, GEAR_THICKNESS, 8);

    // Debug: show center distance
    if (DEBUG_MODE) {
        echo("========== GEAR MESH ==========");
        echo("Pinion position:", MOTOR_POS);
        echo("Master position:", master_pos);
        echo("Center distance:", GEAR_CENTER_DISTANCE, "mm (calculated)");
        echo("================================");
    }
}

// --- Wave Crank and Linkage ---
module wave_linkage() {
    // Crank disc on master gear
    crank_radius = 15;  // Offset for crank pin
    crank_center = [MOTOR_POS[0] + GEAR_CENTER_DISTANCE, MOTOR_POS[1], Z_LINKAGE];

    translate(crank_center)
        rotate([0, 0, master_angle]) {
            // Crank disc
            color("DarkRed")
                cylinder(h=WALL_THICKNESS, r=crank_radius+5, $fn=32);

            // Crank pin
            translate([crank_radius, 0, 0])
                color("Black")
                    cylinder(h=10, r=2, $fn=16);
        }

    // Connecting rod (simplified - actual kinematics would be more complex)
    // For visualization, show approximate position
    crank_pin_pos = [
        crank_center[0] + crank_radius * cos(master_angle),
        crank_center[1] + crank_radius * sin(master_angle),
        Z_LINKAGE + 5
    ];

    // Rocker pivot point
    rocker_pivot = [crank_center[0] + 60, crank_center[1] - 30, Z_LINKAGE + 5];

    // Draw connecting rod
    color("DarkGreen")
        hull() {
            translate(crank_pin_pos) sphere(r=3, $fn=16);
            translate(rocker_pivot) sphere(r=3, $fn=16);
        }
}

// --- Wave Layers ---
module wave_layer(index) {
    phase = index * WAVE_PHASE_OFFSET;
    offset = wave_offset(phase);
    z = WAVE_Z[index];
    y = WAVE_Y[index];

    color(C_WAVE[index])
        translate([5 + offset, y, z])
            wave_profile(WAVE_LENGTH, WAVE_HEIGHT, WAVE_THICKNESS);
}

module all_waves() {
    for (i = [0:WAVE_COUNT-1]) {
        wave_layer(i);
    }
}

// --- Swirl Discs ---
module swirl_assembly() {
    for (i = [0:SWIRL_COUNT-1]) {
        spec = SWIRL_SPECS[i];
        x = spec[0];
        y = spec[1];
        dia = spec[2];
        dir = spec[3];
        speed = spec[4];

        // Rotation angle based on master gear and speed ratio
        rotation = master_angle * speed * dir;

        translate([x, y, SWIRL_Z])
            rotate([0, 0, rotation])
                color(C_SWIRL)
                    swirl_disc(dia, SWIRL_THICKNESS);
    }
}

// --- Moon ---
module moon_assembly() {
    translate([MOON_POS[0], MOON_POS[1], MOON_Z])
        rotate([0, 0, moon_angle])
            color(C_MOON)
                linear_extrude(height=MOON_THICKNESS)
                    crescent_moon(MOON_DIAMETER, MOON_THICKNESS);
}

// --- Lighthouse ---
module lighthouse_assembly() {
    // Tower (static)
    color(C_LIGHTHOUSE)
        translate([LIGHTHOUSE_POS[0], LIGHTHOUSE_POS[1], LIGHTHOUSE_Z])
            cube([LIGHTHOUSE_WIDTH, LIGHTHOUSE_HEIGHT, WALL_THICKNESS]);

    // Lamp housing
    lamp_y = LIGHTHOUSE_POS[1] + LIGHTHOUSE_HEIGHT - 5;
    color("Yellow")
        translate([LIGHTHOUSE_POS[0] + LIGHTHOUSE_WIDTH/2, lamp_y, Z_SWIRL])
            cylinder(h=WALL_THICKNESS, d=12, $fn=24);

    // Rotating beam disc
    color(C_LIGHTHOUSE_BEAM, 0.7)
        translate([LIGHTHOUSE_POS[0] + LIGHTHOUSE_WIDTH/2, lamp_y, LIGHTHOUSE_BEAM_Z])
            rotate([0, 0, lighthouse_angle])
                difference() {
                    cylinder(h=2, d=40, $fn=32);
                    // Beam slot
                    translate([-2, 0, -0.5])
                        cube([4, 25, 3]);
                    translate([-2, -25, -0.5])
                        cube([4, 25, 3]);
                    // Center hole
                    translate([0, 0, -0.5])
                        cylinder(h=3, d=6, $fn=16);
                }
}

// --- Village ---
module village_assembly() {
    color(C_VILLAGE) {
        translate([0, 0, Z_VILLAGE]) {
            // House 1
            translate([130, 55, 0])
                house(15, 20, 10, WALL_THICKNESS);
            // House 2
            translate([155, 50, 0])
                house(20, 25, 12, WALL_THICKNESS);
            // Church
            translate([185, 50, 0])
                church(18, 30, 25, WALL_THICKNESS);
            // House 3
            translate([215, 55, 0])
                house(18, 22, 11, WALL_THICKNESS);
            // House 4
            translate([240, 52, 0])
                house(16, 18, 9, WALL_THICKNESS);
        }
    }
}

// --- Cliff ---
module cliff_assembly() {
    alpha = TRANSPARENT_CLIFF ? 0.3 : 1.0;

    color(C_CLIFF, alpha)
        translate([CLIFF_POS[0], CLIFF_POS[1], Z_MAIN])
            linear_extrude(height=WALL_THICKNESS)
                cliff_profile(CLIFF_WIDTH, CLIFF_HEIGHT, true);

    // Rolling hills behind village
    color(C_CLIFF, alpha)
        translate([CLIFF_WIDTH, 40, Z_MAIN])
            linear_extrude(height=WALL_THICKNESS)
                rolling_hills(FRAME_WIDTH - CLIFF_WIDTH - WALL_THICKNESS, 40);
}

// --- Cypress Tree ---
module cypress_assembly() {
    color(C_CYPRESS)
        translate([CYPRESS_POS[0], CYPRESS_POS[1], Z_WAVE_3])
            cypress_tree(CYPRESS_WIDTH, CYPRESS_HEIGHT, WALL_THICKNESS);
}

// --- Stars ---
module stars_assembly() {
    color(C_STARS)
        for (s = STAR_POSITIONS) {
            translate([s[0], s[1], Z_STARS])
                star(s[2], 5, WALL_THICKNESS);
        }
}

// ============================================================================
// SECTION 14: MAIN ASSEMBLY
// ============================================================================

module main_assembly() {
    // --- Structural ---
    if (SHOW_BACK) back_wall();
    if (SHOW_FRAME) front_frame();
    if (SHOW_FRAME) side_walls();

    // --- Drive System ---
    if (SHOW_CLIFF) cliff_assembly();
    if (SHOW_MOTOR) motor_assembly();
    if (SHOW_GEARS) master_gear();
    if (SHOW_LINKAGES) wave_linkage();

    // --- Moving Elements ---
    if (SHOW_WAVES) all_waves();
    if (SHOW_SWIRLS) swirl_assembly();
    if (SHOW_MOON) moon_assembly();
    if (SHOW_LIGHTHOUSE) lighthouse_assembly();

    // --- Static Landscape ---
    if (SHOW_VILLAGE) village_assembly();
    if (SHOW_CYPRESS) cypress_assembly();
    if (SHOW_STARS) stars_assembly();
}

// ============================================================================
// SECTION 15: DEBUG VISUALIZATION
// ============================================================================

module debug_info() {
    // Zone boundaries
    color("Red", 0.1) {
        // Sky/Land boundary
        translate([0, ZONE_SKY_MIN, -25])
            cube([FRAME_WIDTH, 1, 80]);
        // Land/Wave boundary
        translate([0, ZONE_LAND_MIN, -25])
            cube([FRAME_WIDTH, 1, 80]);
    }

    // Coordinate axes
    translate([0, 0, 0]) {
        color("Red") cylinder(h=50, r=1, $fn=8);      // Z
        color("Green") rotate([0, 90, 0]) cylinder(h=50, r=1, $fn=8);  // X
        color("Blue") rotate([-90, 0, 0]) cylinder(h=50, r=1, $fn=8);  // Y
    }

    echo("========== ANIMATION STATE ==========");
    echo("$t =", t);
    echo("Motor angle:", motor_angle, "deg");
    echo("Master angle:", master_angle, "deg");
    echo("Wave 1 offset:", wave_1_offset, "mm");
    echo("Wave 2 offset:", wave_2_offset, "mm");
    echo("Wave 3 offset:", wave_3_offset, "mm");
    echo("Moon angle:", moon_angle, "deg");
    echo("Lighthouse angle:", lighthouse_angle, "deg");
    echo("=====================================");
}

// ============================================================================
// SECTION 16: SURVIVAL CHECK
// ============================================================================

module SURVIVAL_CHECK() {
    echo("");
    echo("+===========================================+");
    echo("|     STARRY NIGHT V30 SURVIVAL CHECK      |");
    echo("+===========================================+");
    echo(str("|  Frame:        ", FRAME_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Cliff:        ", CLIFF_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Motor:        ", MOTOR_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Gears:        ", GEARS_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Waves:        ", WAVES_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Swirls:       ", SWIRLS_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Moon:         ", MOON_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Lighthouse:   ", LIGHTHOUSE_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Village:      ", VILLAGE_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Cypress:      ", CYPRESS_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo(str("|  Stars:        ", STARS_PRESENT ? "PRESENT" : "MISSING", "                  |"));
    echo("+===========================================+");

    // Count components
    total = 11;
    present = (FRAME_PRESENT ? 1 : 0) + (CLIFF_PRESENT ? 1 : 0) +
              (MOTOR_PRESENT ? 1 : 0) + (GEARS_PRESENT ? 1 : 0) +
              (WAVES_PRESENT ? 1 : 0) + (SWIRLS_PRESENT ? 1 : 0) +
              (MOON_PRESENT ? 1 : 0) + (LIGHTHOUSE_PRESENT ? 1 : 0) +
              (VILLAGE_PRESENT ? 1 : 0) + (CYPRESS_PRESENT ? 1 : 0) +
              (STARS_PRESENT ? 1 : 0);

    echo(str("|  TOTAL: ", present, "/", total, " components             |"));

    if (present == total) {
        echo("|  STATUS: ALL COMPONENTS PRESENT          |");
    } else {
        echo("|  WARNING: MISSING COMPONENTS!            |");
    }
    echo("+===========================================+");
    echo("");
}

// ============================================================================
// SECTION 17: RENDER
// ============================================================================

// Version info
echo("");
echo("+===========================================+");
echo("|  STARRY NIGHT KINETIC AUTOMATON          |");
echo("|  VERSION: V30                            |");
echo("|  DATE: 2026-01-16                        |");
echo("|  STATUS: Verification Build              |");
echo("+===========================================+");
echo("");

// Render main assembly
main_assembly();

// Show debug info if enabled
if (DEBUG_MODE) debug_info();

// Run survival check
SURVIVAL_CHECK();

// ============================================================================
// END OF FILE
// ============================================================================
