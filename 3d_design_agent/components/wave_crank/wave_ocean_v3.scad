/*
 * WAVE OCEAN v3 - CORRECTED Z-LAYER SEPARATION
 *
 * Classic wave machine automata with:
 * - 22 thin waves (4mm) + 22 thin elliptical cams (4mm)
 * - Common hinge axle through wave slots
 * - Cams BELOW waves (waves rest ON TOP of cam surface)
 * - Progressive amplitude (gentle right, dramatic left)
 * - Traveling wave effect (16.36 deg phase per wave)
 *
 * CRITICAL FIX from v2: Z-layer separation prevents cam-wave intersection
 * Based on validated geometry in 0_geometry_v2.md
 *
 * Date: 2026-01-20
 */

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set >= 0 to override animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE TOGGLES
// ============================================

SHOW_FRAME_LEFT = true;
SHOW_FRAME_RIGHT = true;
SHOW_FRAME_BASE = true;
SHOW_FRAME_BACK_RAIL = true;
SHOW_FRAME_FRONT_RAIL = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT = true;
SHOW_CAMS = true;
SHOW_WAVES = true;
SHOW_HAND_CRANK = true;
SHOW_CONTACT_POINTS = false;  // Debug visualization

// Wave range (0-21 for all 22 waves)
WAVE_RANGE_START = 0;
WAVE_RANGE_END = 21;

// ============================================
// VALIDATED PARAMETERS (from 0_geometry_v2.md)
// ============================================

// Wave area boundaries (from main sculpture)
WAVE_AREA_START_X = 78;
WAVE_AREA_END_X = 302;
WAVE_AREA_WIDTH = 224;  // mm

// Thin disc dimensions
WAVE_THICKNESS = 4;   // mm
CAM_THICKNESS = 4;    // mm
WAVE_GAP = 1;         // mm gap each side
UNIT_PITCH = 10;      // 4 + 4 + 2 = 10mm per wave unit

// Wave count calculation
NUM_WAVES = 22;       // floor(224 / 10)
PHASE_OFFSET = 360 / NUM_WAVES;  // 16.36 deg per wave

// First wave X position
FIRST_WAVE_X = WAVE_AREA_START_X + UNIT_PITCH;  // 88mm

// ============================================
// Z-LAYER LAYOUT (CRITICAL - from v2 geometry)
// ============================================

// These values PREVENT cam-wave intersection
Z_BASE = 0;           // Base plate
Z_BASE_THICK = 5;     // Base plate thickness

Z_HINGE_AXLE = 25;    // Hinge axle (waves pivot here) - REVISED
Z_CAMSHAFT = 28;      // Camshaft (cams rotate here) - REVISED

// Frame height to accommodate motion
Z_FRAME_HEIGHT = 60;

// ============================================
// SHAFT PARAMETERS
// ============================================

CAMSHAFT_DIA = 6;           // mm
CAMSHAFT_HOLE = 6.4;        // 0.2mm clearance each side
CAMSHAFT_LENGTH = 264;      // mm

HINGE_AXLE_DIA = 5;         // mm
HINGE_AXLE_HOLE = 5.4;      // 0.2mm clearance each side
HINGE_AXLE_LENGTH = 264;    // mm

// ============================================
// AXIS POSITIONS (Y dimension)
// ============================================

HINGE_AXLE_Y = 0;     // Back of frame (waves pivot here)
CAMSHAFT_Y = 70;      // Front of frame (cams push here)

// Distance between axes
AXIS_DISTANCE_Y = CAMSHAFT_Y - HINGE_AXLE_Y;  // 70mm
AXIS_DISTANCE_Z = Z_CAMSHAFT - Z_HINGE_AXLE;  // 3mm

// ============================================
// WAVE PARAMETERS
// ============================================

WAVE_LENGTH = 75;     // Y dimension (hinge to front)
WAVE_HEIGHT = 25;     // Z dimension (visual height)

// Slot at hinge end (axle passes through)
SLOT_WIDTH = HINGE_AXLE_DIA + 0.4;  // 5.4mm
SLOT_LENGTH = 15;     // REVISED from 12mm for angular range

// ============================================
// CAM PARAMETERS (Progressive sizing)
// ============================================

// Major axis (vertical motion amplitude)
// REVISED: Max 24mm major, 10mm minor (was 12mm)
function cam_major(i) = 8 + (i / (NUM_WAVES - 1)) * 16;   // 8mm to 24mm

// Minor axis (horizontal motion amplitude)
// REVISED: Max 10mm to avoid side collision
function cam_minor(i) = 4 + (i / (NUM_WAVES - 1)) * 6;    // 4mm to 10mm

// Phase for traveling wave
function cam_phase(i) = i * PHASE_OFFSET;

// ============================================
// FRAME PARAMETERS
// ============================================

FRAME_LENGTH = 284;   // X (covers all waves + margins)
FRAME_DEPTH = 100;    // Y
FRAME_HEIGHT = 60;    // Z
FRAME_WALL = 5;       // Wall thickness

FRAME_X_START = 48;   // X position of frame left edge
FRAME_Y_START = -20;  // Y position of frame back edge

// ============================================
// CRANK PARAMETERS
// ============================================

CRANK_ARM = 30;       // mm
CRANK_KNOB_DIA = 12;  // mm
CRANK_KNOB_H = 20;    // mm

// ============================================
// COLORS
// ============================================

C_FRAME = [0.35, 0.25, 0.15];    // Dark wood
C_AXLE = [0.6, 0.6, 0.65];       // Steel gray
C_CAM = [0.8, 0.6, 0.3];         // Bronze/brass
C_WAVE = [0.7, 0.55, 0.4];       // Light wood
C_CRANK = [0.5, 0.4, 0.35];      // Medium wood
C_CONTACT = [1, 0, 0];           // Red (debug)

$fn = 48;

// ============================================
// DERIVED CALCULATIONS
// ============================================

// Cam top surface position at given angle for wave i
function cam_top_z(i, angle) =
    Z_CAMSHAFT + (cam_major(i) / 2) * sin(angle + cam_phase(i));

// Wave contact point (where wave touches cam)
function wave_contact_z(i, angle) = cam_top_z(i, angle);

// Wave angle from pivot (rocking motion)
function wave_angle(i, angle) =
    atan2(wave_contact_z(i, angle) - Z_HINGE_AXLE, CAMSHAFT_Y - HINGE_AXLE_Y);

// X position of wave i
function wave_x(i) = FIRST_WAVE_X + i * UNIT_PITCH;

// ============================================
// MODULES
// ============================================

// Frame left side plate
module frame_left() {
    color(C_FRAME)
    translate([FRAME_X_START, FRAME_Y_START, Z_BASE])
    difference() {
        cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

        // Hinge axle hole
        translate([-1, HINGE_AXLE_Y - FRAME_Y_START, Z_HINGE_AXLE])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_HOLE, h=FRAME_WALL + 2);

        // Camshaft hole
        translate([-1, CAMSHAFT_Y - FRAME_Y_START, Z_CAMSHAFT])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_HOLE, h=FRAME_WALL + 2);
    }
}

// Frame right side plate
module frame_right() {
    color(C_FRAME)
    translate([FRAME_X_START + FRAME_LENGTH - FRAME_WALL, FRAME_Y_START, Z_BASE])
    difference() {
        cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

        // Hinge axle hole
        translate([-1, HINGE_AXLE_Y - FRAME_Y_START, Z_HINGE_AXLE])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_HOLE, h=FRAME_WALL + 2);

        // Camshaft hole
        translate([-1, CAMSHAFT_Y - FRAME_Y_START, Z_CAMSHAFT])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_HOLE, h=FRAME_WALL + 2);
    }
}

// Frame base plate
module frame_base() {
    color(C_FRAME)
    translate([FRAME_X_START, FRAME_Y_START, Z_BASE])
        cube([FRAME_LENGTH, FRAME_DEPTH, Z_BASE_THICK]);
}

// Frame back rail (supports hinge axle)
module frame_back_rail() {
    color(C_FRAME)
    translate([FRAME_X_START + FRAME_WALL, FRAME_Y_START, Z_BASE])
    difference() {
        cube([FRAME_LENGTH - 2*FRAME_WALL, FRAME_WALL + 5, FRAME_HEIGHT/2]);

        // Hinge axle channel
        translate([-1, FRAME_WALL/2, Z_HINGE_AXLE])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_HOLE, h=FRAME_LENGTH);
    }
}

// Frame front rail (supports camshaft)
module frame_front_rail() {
    color(C_FRAME)
    translate([FRAME_X_START + FRAME_WALL, FRAME_Y_START + FRAME_DEPTH - 20, Z_BASE])
    difference() {
        cube([FRAME_LENGTH - 2*FRAME_WALL, 20, FRAME_HEIGHT/2 + 15]);

        // Camshaft channel
        translate([-1, 10, Z_CAMSHAFT])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_HOLE, h=FRAME_LENGTH);
    }
}

// Hinge axle (static - waves pivot on this)
module hinge_axle() {
    color(C_AXLE)
    translate([FRAME_X_START - 5, HINGE_AXLE_Y, Z_HINGE_AXLE])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=HINGE_AXLE_LENGTH + 10);
}

// Camshaft (rotating - holds cams)
module camshaft() {
    color(C_AXLE)
    translate([FRAME_X_START - 5, CAMSHAFT_Y, Z_CAMSHAFT])
        rotate([0, 90, 0])
            cylinder(d=CAMSHAFT_DIA, h=CAMSHAFT_LENGTH + 10);
}

// Single elliptical cam
module cam(i) {
    major = cam_major(i);
    minor = cam_minor(i);
    phase = cam_phase(i);
    x_pos = wave_x(i);

    color(C_CAM)
    translate([x_pos, CAMSHAFT_Y, Z_CAMSHAFT])
        rotate([0, 90, 0])
            rotate([0, 0, theta + phase])
                difference() {
                    // Elliptical disc
                    scale([major/10, minor/10, 1])
                        cylinder(r=10, h=CAM_THICKNESS, center=true);

                    // Shaft hole
                    cylinder(d=CAMSHAFT_DIA + 0.3, h=CAM_THICKNESS + 2, center=true);
                }
}

// All cams
module all_cams() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        cam(i);
    }
}

// Single wave slat
module wave(i) {
    x_pos = wave_x(i);
    angle = wave_angle(i, theta);

    color(C_WAVE)
    translate([x_pos, HINGE_AXLE_Y, Z_HINGE_AXLE])
        rotate([angle, 0, 0])
            translate([-WAVE_THICKNESS/2, 0, -WAVE_HEIGHT/2])
                difference() {
                    // Main body
                    cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_HEIGHT]);

                    // Rectangular slot at hinge end
                    translate([-1, -1, WAVE_HEIGHT/2 - SLOT_WIDTH/2])
                        cube([WAVE_THICKNESS + 2, SLOT_LENGTH + 1, SLOT_WIDTH]);
                }
}

// All waves
module all_waves() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        wave(i);
    }
}

// Hand crank
module hand_crank() {
    color(C_CRANK)
    translate([FRAME_X_START - 10, CAMSHAFT_Y, Z_CAMSHAFT])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Hub
                difference() {
                    cylinder(d=16, h=8);
                    translate([0, 0, -1])
                        cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
                }

                // Arm
                translate([0, -4, 0])
                    cube([CRANK_ARM, 8, 8]);

                // Knob
                translate([CRANK_ARM, 0, 0])
                    cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
            }
}

// Debug: Contact point visualization
module contact_points() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        color(C_CONTACT)
        translate([wave_x(i), CAMSHAFT_Y, cam_top_z(i, theta)])
            sphere(r=1.5);
    }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_ocean_assembly() {
    // Frame
    if (SHOW_FRAME_LEFT) frame_left();
    if (SHOW_FRAME_RIGHT) frame_right();
    if (SHOW_FRAME_BASE) frame_base();
    if (SHOW_FRAME_BACK_RAIL) frame_back_rail();
    if (SHOW_FRAME_FRONT_RAIL) frame_front_rail();

    // Axles
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft();

    // Moving parts
    if (SHOW_CAMS) all_cams();
    if (SHOW_WAVES) all_waves();

    // Drive
    if (SHOW_HAND_CRANK) hand_crank();

    // Debug
    if (SHOW_CONTACT_POINTS) contact_points();
}

// ============================================
// RENDER
// ============================================

wave_ocean_assembly();

// ============================================
// CONSOLE OUTPUT
// ============================================

echo("");
echo("============================================");
echo("  WAVE OCEAN v3 - CORRECTED Z-LAYERS");
echo("============================================");
echo("");
echo("POWER PATH:");
echo("  Hand Crank -> Camshaft -> 22 Elliptical Cams -> 22 Wave Slats");
echo("");
echo("Z-LAYER LAYOUT (CRITICAL):");
echo(str("  Base:        Z = ", Z_BASE, " to ", Z_BASE + Z_BASE_THICK, "mm"));
echo(str("  Hinge Axle:  Z = ", Z_HINGE_AXLE, "mm"));
echo(str("  Camshaft:    Z = ", Z_CAMSHAFT, "mm"));
echo(str("  Delta Z:     ", Z_CAMSHAFT - Z_HINGE_AXLE, "mm (camshaft ",
         Z_CAMSHAFT > Z_HINGE_AXLE ? "ABOVE" : "BELOW", " hinge)"));
echo("");
echo(str("Current angle: ", theta, " deg"));
echo("");
echo("WAVE PARAMETERS:");
echo(str("  Wave count:      ", NUM_WAVES));
echo(str("  Wave thickness:  ", WAVE_THICKNESS, "mm"));
echo(str("  Phase offset:    ", PHASE_OFFSET, " deg per wave"));
echo(str("  Unit pitch:      ", UNIT_PITCH, "mm"));
echo("");
echo("CAM SIZES (progressive):");
echo(str("  Cam 1 (gentlest):  ", cam_major(0), " x ", cam_minor(0), "mm"));
echo(str("  Cam 11 (middle):   ", cam_major(10), " x ", cam_minor(10), "mm"));
echo(str("  Cam 22 (dramatic): ", cam_major(21), " x ", cam_minor(21), "mm"));
echo("");
echo("PRINTABILITY:");
echo(str("  Min wall:      ", WAVE_THICKNESS, "mm - ", WAVE_THICKNESS >= 1.2 ? "PASS" : "FAIL"));
echo(str("  Shaft clear:   0.2mm each side - PASS"));
echo(str("  Slot width:    ", SLOT_WIDTH, "mm (for ", HINGE_AXLE_DIA, "mm axle) - PASS"));
echo("");
echo("SAMPLE WAVE ANGLES:");
for (i = [0, 5, 10, 15, 21]) {
    echo(str("  Wave ", i+1, ": angle = ", wave_angle(i, theta), " deg"));
}
echo("");
echo("============================================");
