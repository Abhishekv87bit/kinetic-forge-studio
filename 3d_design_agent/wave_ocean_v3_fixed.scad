/*
 * WAVE OCEAN v3 FIXED - Simplified Kinetic Wave Mechanism
 *
 * Starry Night Kinetic Sculpture - Ocean Wave Component
 * FIXES applied based on user feedback:
 *   - Correct Y positions (background BEHIND main wave)
 *   - Removed track/channel (crank-slider only)
 *   - Removed RED attached waves and GREEN curl tips (later phase)
 *   - Added base plate and motor mount for standalone testing
 *   - Simplified main wave (no flex zones)
 *
 * COORDINATE SYSTEM:
 *   Viewer looks from +Y toward -Y (front of canvas)
 *   X = horizontal (left = cliff side, right = open ocean)
 *   Y = depth (negative = behind, toward backplate)
 *   Z = vertical (up)
 *
 * LAYER ORDER (front to back):
 *   Y = 0     Main wave (FRONT)
 *   Y = -8    Background layer 2
 *   Y = -16   Background layer 3
 *   Y = -20   Yellow surge waves
 *   Y = -24   Horizon (BACK)
 */

$fn = 32;

// ============================================
// ANIMATION CONTROL
// ============================================

MANUAL_ANGLE = -1;  // Set to 0, 90, 180, 270 for testing. -1 = animate
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE FLAGS
// ============================================

SHOW_MAIN_WAVE = true;
SHOW_BACKGROUND_LAYERS = true;
SHOW_YELLOW_SURGE = true;
SHOW_DRIVE_MECHANISM = true;
SHOW_BASE_PLATE = true;
SHOW_MOTOR_MOUNT = true;

// ============================================
// GLOBAL PARAMETERS
// ============================================

LAYER_THICKNESS = 3;    // mm (along Y)

// ============================================
// MAIN WAVE LAYER PARAMETERS
// ============================================

MAIN_WAVE_WIDTH = 220;  // mm along X

// Main wave profile control points (X, Z) in mm
// Matching reference image silhouette
MAIN_WAVE_PROFILE = [
    // Left edge (cliff side) - lower
    [0, 8],
    [10, 10],
    [20, 14],
    // First crest
    [30, 20],
    [40, 26],      // First peak
    [50, 24],
    // Trough
    [60, 18],
    [70, 14],
    [80, 11],
    [90, 10],      // Trough bottom
    [100, 11],
    [110, 14],
    // Second crest (tallest)
    [120, 18],
    [130, 23],
    [140, 28],
    [150, 32],
    [160, 35],     // Second peak (tallest)
    [170, 33],
    [180, 28],
    // Descending tail
    [190, 22],
    [200, 17],
    [210, 14],
    [220, 12]
];

// ============================================
// LAYER Y POSITIONS (CRITICAL - FRONT TO BACK)
// ============================================
// Viewer at +Y looking toward -Y
// More negative Y = further back from viewer

LAYER_Y_MAIN = 0;           // FRONT (closest to viewer)
LAYER_Y_BG2 = -8;           // Behind main
LAYER_Y_BG3 = -16;          // Further back
LAYER_Y_SURGE = -20;        // Between BG3 and horizon
LAYER_Y_HORIZON = -24;      // BACK (furthest from viewer)

// ============================================
// BACKGROUND LAYER PARAMETERS (PARALLAX)
// ============================================

LAYER_2_SCALE = 0.8;        // 80% of main
LAYER_3_SCALE = 0.5;        // 50% of main

LAYER_2_STROKE_RATIO = 0.75;
LAYER_3_STROKE_RATIO = 0.5;
HORIZON_STROKE_RATIO = 0.25;

// ============================================
// YELLOW SURGE WAVE PARAMETERS
// ============================================

// Each surge: [x_pos, height, phase_offset]
YELLOW_SURGES = [
    [60, 15, 0],      // Surge 1
    [140, 18, 90],    // Surge 2
    [200, 12, 180]    // Surge 3
];

SURGE_MAX_ANGLE = 35;       // degrees
SURGE_BASE_Z = 40;          // Base of surge pivot (at horizon level)

// ============================================
// DRIVE MECHANISM PARAMETERS
// ============================================

// Crank-slider for horizontal motion
CRANK_RADIUS = 30;          // 60mm stroke
CONNECTING_ROD = 80;        // L/r = 2.67
MECH_X = 260;               // Right side, visible
MECH_Y = -15;               // Behind wave stack
MECH_Z = 0;                 // At base plate level

CRANK_DISC_DIA = 50;
CRANK_DISC_THICKNESS = 5;
SHAFT_DIA = 4;              // Motor shaft diameter

// Eccentric cam for surge waves
ECCENTRIC_OFFSET = 6;
ECCENTRIC_PHASE = 75;       // degrees offset from main crank

// ============================================
// BASE PLATE AND MOTOR MOUNT
// ============================================

BASE_PLATE_LENGTH = 320;    // Along X
BASE_PLATE_WIDTH = 80;      // Along Y
BASE_PLATE_THICKNESS = 5;
BASE_PLATE_X = -30;         // Start position
BASE_PLATE_Y = -50;         // Behind everything
BASE_PLATE_Z = -10;         // Below mechanisms

// Motor mount for N20/GA12-N20 geared motor
MOTOR_BODY_DIA = 12;        // N20 motor diameter
MOTOR_BODY_LENGTH = 25;     // N20 motor length
MOTOR_GEARBOX_WIDTH = 10;   // Gearbox width
MOTOR_GEARBOX_LENGTH = 15;  // Gearbox length

// ============================================
// COLORS
// ============================================

C_MAIN_WAVE = [0.2, 0.5, 0.8];      // Ocean blue
C_LAYER_2 = [0.18, 0.45, 0.75];     // Slightly darker
C_LAYER_3 = [0.15, 0.4, 0.7];       // Deeper blue
C_HORIZON = [0.12, 0.35, 0.6];      // Deep blue
C_SURGE = [0.4, 0.65, 0.9];         // Light blue surge
C_MECH = [0.7, 0.5, 0.2];           // Brass
C_RAIL = [0.3, 0.25, 0.2];          // Dark wood
C_ROLLER = [0.5, 0.5, 0.55];        // Steel
C_BASE = [0.25, 0.22, 0.2];         // Dark wood base

// ============================================
// KINEMATICS FUNCTIONS
// ============================================

// Crank-slider: X position of slider from crank angle
function slider_x(angle) =
    let(
        r = CRANK_RADIUS,
        L = CONNECTING_ROD,
        cos_a = cos(angle),
        sin_a = sin(angle)
    )
    r * cos_a + sqrt(L*L - r*r * sin_a*sin_a);

// Main wave origin X (attached to slider)
// Centers wave in visible area
WAVE_X_OFFSET = 30;

function wave_origin_x(angle) = WAVE_X_OFFSET + slider_x(angle);

// Parallax layer origins (different amounts of travel)
function layer_2_origin_x(angle) =
    WAVE_X_OFFSET + slider_x(angle) * LAYER_2_STROKE_RATIO;

function layer_3_origin_x(angle) =
    WAVE_X_OFFSET + slider_x(angle) * LAYER_3_STROKE_RATIO;

function horizon_origin_x(angle) =
    WAVE_X_OFFSET + slider_x(angle) * HORIZON_STROKE_RATIO;

// Surge wave angle from eccentric cam
function surge_angle(surge_idx) =
    let(
        phase = YELLOW_SURGES[surge_idx][2],
        effective_angle = theta + ECCENTRIC_PHASE + phase,
        norm = (effective_angle % 360) / 360,
        // Asymmetric: quick up (1/3), slow down (2/3)
        profile = (norm < 0.33)
            ? norm / 0.33
            : 1 - (norm - 0.33) / 0.67
    )
    SURGE_MAX_ANGLE * profile;

// ============================================
// MAIN WAVE PROFILE 2D
// ============================================

module main_wave_profile_2d() {
    bottom_z = -5;  // Below visible area

    points = concat(
        [[MAIN_WAVE_PROFILE[0][0], bottom_z]],
        MAIN_WAVE_PROFILE,
        [[MAIN_WAVE_PROFILE[len(MAIN_WAVE_PROFILE)-1][0], bottom_z]]
    );

    polygon(points);
}

// ============================================
// MAIN WAVE LAYER (Simplified - No Flex Zones)
// ============================================

module main_wave_layer(origin_x) {
    color(C_MAIN_WAVE)
    translate([origin_x, LAYER_Y_MAIN, 0])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS, center=true)
        main_wave_profile_2d();
}

// ============================================
// BACKGROUND LAYERS
// ============================================

module background_layer_2(origin_x) {
    color(C_LAYER_2)
    translate([origin_x, LAYER_Y_BG2, 0])
    scale([LAYER_2_SCALE, 1, LAYER_2_SCALE])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS, center=true)
        main_wave_profile_2d();
}

module background_layer_3(origin_x) {
    color(C_LAYER_3)
    translate([origin_x, LAYER_Y_BG3, 0])
    scale([LAYER_3_SCALE, 1, LAYER_3_SCALE])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS, center=true)
        main_wave_profile_2d();
}

module horizon_layer(origin_x) {
    // Simple horizontal strip at horizon level
    color(C_HORIZON)
    translate([origin_x, LAYER_Y_HORIZON, SURGE_BASE_Z - 5])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS, center=true)
    polygon([
        [0, 0], [220, 0],
        [220, 12], [200, 14], [160, 12], [120, 15], [80, 13], [40, 14], [0, 10]
    ]);
}

module all_background_layers() {
    background_layer_2(layer_2_origin_x(theta));
    background_layer_3(layer_3_origin_x(theta));
    horizon_layer(horizon_origin_x(theta));
}

// ============================================
// YELLOW SURGE WAVES
// ============================================

module surge_wave_shape(height) {
    // Wave-shaped surge that rises from horizon
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS, center=true)
    polygon([
        [-4, 0], [4, 0],
        [6, height * 0.3],
        [5, height * 0.6],
        [2, height * 0.9],
        [0, height],
        [-2, height * 0.85],
        [-4, height * 0.5],
        [-5, height * 0.2]
    ]);
}

module yellow_surge_wave(idx) {
    surge = YELLOW_SURGES[idx];
    x_pos = surge[0];
    height = surge[1];

    angle = surge_angle(idx);

    // Position relative to horizon layer
    origin_x = horizon_origin_x(theta);

    color(C_SURGE)
    translate([origin_x + x_pos, LAYER_Y_SURGE, SURGE_BASE_Z]) {
        // Pivot at base, swing forward/back
        rotate([angle, 0, 0])
        surge_wave_shape(height);
    }
}

module all_yellow_surges() {
    for (i = [0:len(YELLOW_SURGES)-1]) {
        yellow_surge_wave(i);
    }
}

// ============================================
// DRIVE MECHANISM
// ============================================

module crank_disc() {
    color(C_MECH)
    translate([MECH_X, MECH_Y, MECH_Z + 25])
    rotate([90, 0, 0])
    rotate([0, 0, theta]) {
        // Disc body with decorative cutouts
        difference() {
            cylinder(d=CRANK_DISC_DIA, h=CRANK_DISC_THICKNESS);
            translate([0, 0, -1])
            cylinder(d=SHAFT_DIA + 0.4, h=CRANK_DISC_THICKNESS + 2);
            // Decorative holes
            for (a = [0:60:300]) {
                rotate([0, 0, a])
                translate([CRANK_DISC_DIA * 0.32, 0, -1])
                cylinder(d=8, h=CRANK_DISC_THICKNESS + 2);
            }
        }
        // Crank pin
        translate([CRANK_RADIUS, 0, CRANK_DISC_THICKNESS])
        cylinder(d=4, h=10);
    }
}

module connecting_rod() {
    // From crank pin to wave carrier
    crank_angle_rad = theta * PI / 180;

    // Crank pin position
    crank_x = MECH_X + CRANK_RADIUS * cos(theta);
    crank_y = MECH_Y - CRANK_DISC_THICKNESS - 5;
    crank_z = MECH_Z + 25 + CRANK_RADIUS * sin(theta);

    // Wave carrier connection point
    wave_x = wave_origin_x(theta) + MAIN_WAVE_WIDTH/2;
    wave_y = LAYER_Y_MAIN - 5;
    wave_z = 15;  // Connection height on wave

    // Draw connecting rod
    dx = wave_x - crank_x;
    dy = wave_y - crank_y;
    dz = wave_z - crank_z;
    rod_length = sqrt(dx*dx + dy*dy + dz*dz);

    color(C_MECH)
    translate([crank_x, crank_y, crank_z]) {
        // Simplified rod visualization
        hull() {
            sphere(d=8);
            translate([dx, dy, dz])
            sphere(d=8);
        }
    }
}

module eccentric_cam() {
    // Eccentric cam for surge waves
    color(C_MECH, 0.8)
    translate([MECH_X, MECH_Y + 20, MECH_Z + 25])
    rotate([90, 0, 0])
    rotate([0, 0, theta + ECCENTRIC_PHASE]) {
        translate([ECCENTRIC_OFFSET, 0, 0])
        cylinder(d=15, h=4);
    }
}

module drive_shaft() {
    color(C_ROLLER)
    translate([MECH_X, MECH_Y + 30, MECH_Z + 25])
    rotate([90, 0, 0])
    cylinder(d=SHAFT_DIA, h=50);
}

module bearing_supports() {
    color(C_RAIL)
    // Front bearing support
    translate([MECH_X - 15, MECH_Y - 5, BASE_PLATE_Z + BASE_PLATE_THICKNESS])
    difference() {
        cube([30, 10, 35]);
        translate([15, -1, 25])
        rotate([-90, 0, 0])
        cylinder(d=SHAFT_DIA + 1, h=12);
    }

    // Rear bearing support
    translate([MECH_X - 15, MECH_Y + 25, BASE_PLATE_Z + BASE_PLATE_THICKNESS])
    difference() {
        cube([30, 10, 35]);
        translate([15, -1, 25])
        rotate([-90, 0, 0])
        cylinder(d=SHAFT_DIA + 1, h=12);
    }
}

module drive_mechanism() {
    crank_disc();
    connecting_rod();
    eccentric_cam();
    drive_shaft();
    bearing_supports();
}

// ============================================
// BASE PLATE
// ============================================

module base_plate() {
    color(C_BASE)
    translate([BASE_PLATE_X, BASE_PLATE_Y, BASE_PLATE_Z])
    difference() {
        cube([BASE_PLATE_LENGTH, BASE_PLATE_WIDTH, BASE_PLATE_THICKNESS]);

        // Mounting holes for motor
        translate([MECH_X - BASE_PLATE_X + 15, -BASE_PLATE_Y + MECH_Y + 40, -1])
        cylinder(d=3, h=BASE_PLATE_THICKNESS + 2);

        translate([MECH_X - BASE_PLATE_X - 15, -BASE_PLATE_Y + MECH_Y + 40, -1])
        cylinder(d=3, h=BASE_PLATE_THICKNESS + 2);
    }
}

// ============================================
// MOTOR MOUNT
// ============================================

module motor_mount() {
    color(C_RAIL)
    translate([MECH_X, MECH_Y + 35, BASE_PLATE_Z + BASE_PLATE_THICKNESS]) {
        // Motor mounting bracket
        difference() {
            union() {
                // Vertical plate
                translate([-20, 0, 0])
                cube([40, 5, 40]);

                // Motor clamp
                translate([0, 5, 25])
                rotate([90, 0, 0])
                difference() {
                    cylinder(d=MOTOR_BODY_DIA + 8, h=10);
                    translate([0, 0, -1])
                    cylinder(d=MOTOR_BODY_DIA + 0.5, h=12);
                }
            }

            // Shaft hole
            translate([0, -1, 25])
            rotate([-90, 0, 0])
            cylinder(d=SHAFT_DIA + 1, h=20);
        }
    }

    // Motor placeholder (for visualization)
    color([0.3, 0.3, 0.35])
    translate([MECH_X, MECH_Y + 45, MECH_Z + 25])
    rotate([-90, 0, 0]) {
        // Motor body
        cylinder(d=MOTOR_BODY_DIA, h=MOTOR_BODY_LENGTH);
        // Gearbox
        translate([-MOTOR_GEARBOX_WIDTH/2, -MOTOR_GEARBOX_WIDTH/2, MOTOR_BODY_LENGTH])
        cube([MOTOR_GEARBOX_WIDTH, MOTOR_GEARBOX_WIDTH, MOTOR_GEARBOX_LENGTH]);
    }
}

// ============================================
// WAVE CARRIER (connects wave to mechanism)
// ============================================

module wave_carrier() {
    // Connects main wave to crank-slider
    origin_x = wave_origin_x(theta);

    color(C_RAIL)
    translate([origin_x + MAIN_WAVE_WIDTH/2 - 10, LAYER_Y_MAIN - 8, 0]) {
        // Vertical arm from base to wave
        cube([20, 5, 18]);

        // Connection to wave
        translate([0, 0, 15])
        cube([20, 10, 3]);
    }
}

// ============================================
// PARALLAX LINKAGE
// ============================================

module parallax_linkage() {
    // Bell crank system connecting all layers
    // Simplified visualization

    main_x = wave_origin_x(theta) + MAIN_WAVE_WIDTH/2;
    l2_x = layer_2_origin_x(theta) + MAIN_WAVE_WIDTH * LAYER_2_SCALE / 2;
    l3_x = layer_3_origin_x(theta) + MAIN_WAVE_WIDTH * LAYER_3_SCALE / 2;

    pivot_x = MECH_X - 50;
    pivot_y = -30;
    pivot_z = 10;

    color(C_MECH, 0.6) {
        // Pivot point
        translate([pivot_x, pivot_y, pivot_z])
        sphere(d=8);

        // Arms to each layer (simplified)
        hull() {
            translate([pivot_x, pivot_y, pivot_z]) sphere(d=4);
            translate([main_x, LAYER_Y_MAIN - 5, 15]) sphere(d=4);
        }
        hull() {
            translate([pivot_x, pivot_y, pivot_z]) sphere(d=4);
            translate([l2_x, LAYER_Y_BG2, 10]) sphere(d=4);
        }
        hull() {
            translate([pivot_x, pivot_y, pivot_z]) sphere(d=4);
            translate([l3_x, LAYER_Y_BG3, 5]) sphere(d=4);
        }
    }
}

// ============================================
// FULL ASSEMBLY
// ============================================

module wave_ocean_v3_assembly() {
    // Main wave (FRONT - Y=0)
    if (SHOW_MAIN_WAVE) {
        main_wave_layer(wave_origin_x(theta));
        wave_carrier();
    }

    // Background layers (BEHIND main wave - negative Y)
    if (SHOW_BACKGROUND_LAYERS) {
        all_background_layers();
        parallax_linkage();
    }

    // Yellow surge waves (between BG3 and horizon)
    if (SHOW_YELLOW_SURGE) {
        all_yellow_surges();
    }

    // Drive mechanism
    if (SHOW_DRIVE_MECHANISM) {
        drive_mechanism();
    }

    // Base plate
    if (SHOW_BASE_PLATE) {
        base_plate();
    }

    // Motor mount
    if (SHOW_MOTOR_MOUNT) {
        motor_mount();
    }
}

// Render
wave_ocean_v3_assembly();

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("");
echo("═══════════════════════════════════════════════════════════════");
echo("  WAVE OCEAN v3 FIXED - VERIFICATION");
echo("═══════════════════════════════════════════════════════════════");
echo("");

echo(str("CURRENT ANGLE: theta = ", theta, "°"));
echo("");

echo("LAYER Y POSITIONS (front to back):");
echo(str("  Main wave:    Y = ", LAYER_Y_MAIN, "mm (FRONT)"));
echo(str("  Background 2: Y = ", LAYER_Y_BG2, "mm"));
echo(str("  Background 3: Y = ", LAYER_Y_BG3, "mm"));
echo(str("  Surge waves:  Y = ", LAYER_Y_SURGE, "mm"));
echo(str("  Horizon:      Y = ", LAYER_Y_HORIZON, "mm (BACK)"));
echo("");

echo("HORIZONTAL POSITIONS:");
main_x = wave_origin_x(theta);
echo(str("  Main wave origin: X = ", round(main_x*10)/10, "mm"));
echo(str("  Layer 2 origin:   X = ", round(layer_2_origin_x(theta)*10)/10, "mm (", LAYER_2_STROKE_RATIO*100, "% stroke)"));
echo(str("  Layer 3 origin:   X = ", round(layer_3_origin_x(theta)*10)/10, "mm (", LAYER_3_STROKE_RATIO*100, "% stroke)"));
echo(str("  Horizon origin:   X = ", round(horizon_origin_x(theta)*10)/10, "mm (", HORIZON_STROKE_RATIO*100, "% stroke)"));
echo("");

echo("TRAVEL RANGE:");
echo(str("  At theta=0°:   main wave X = ", round(wave_origin_x(0)*10)/10, "mm"));
echo(str("  At theta=180°: main wave X = ", round(wave_origin_x(180)*10)/10, "mm"));
echo(str("  Stroke: ", round(abs(wave_origin_x(0) - wave_origin_x(180))*10)/10, "mm"));
echo("");

echo("SURGE WAVE ANGLES:");
for (i = [0:len(YELLOW_SURGES)-1]) {
    echo(str("  Surge ", i+1, ": ", round(surge_angle(i)*10)/10, "° at X=", YELLOW_SURGES[i][0]));
}
echo("");

echo("BASE PLATE:");
echo(str("  Position: X=", BASE_PLATE_X, ", Y=", BASE_PLATE_Y, ", Z=", BASE_PLATE_Z));
echo(str("  Size: ", BASE_PLATE_LENGTH, " x ", BASE_PLATE_WIDTH, " x ", BASE_PLATE_THICKNESS, "mm"));
echo("");

echo("═══════════════════════════════════════════════════════════════");
echo("  TO TEST: Set MANUAL_ANGLE = 0, 90, 180, 270 and render");
echo("  View from FRONT (+Y looking at -Y) to verify layer order");
echo("═══════════════════════════════════════════════════════════════");
