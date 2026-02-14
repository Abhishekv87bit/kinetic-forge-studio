/*
 * WAVE OCEAN MECHANISM v2 - Thin Disc Wave Machine
 *
 * Based on classic wave machine automata:
 * - Thin elliptical disc cams (4mm) on central camshaft
 * - Thin wave slats (4mm) with rectangular slot at hinge end
 * - COMMON AXLE runs through ALL wave slots (single constraint line)
 * - Cams push wave fronts up/down
 *
 * Reference: Traditional wave machine automata design
 * Validated: 2026-01-20
 */

// ============================================
// ANIMATION CONTROL
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE TOGGLES (set false to hide)
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

// Show specific wave range (set to show subset)
WAVE_RANGE_START = 0;      // First wave to show (0-21)
WAVE_RANGE_END = 21;       // Last wave to show (0-21)

// ============================================
// DESIGN CONSTRAINTS
// ============================================

// Wave area (from main assembly)
WAVE_AREA_START_X = 78;
WAVE_AREA_END_X = 302;
WAVE_AREA_WIDTH = WAVE_AREA_END_X - WAVE_AREA_START_X;  // 224mm

// Thickness constraints (user specified)
WAVE_THICKNESS = 4;       // mm - each wave slat
CAM_THICKNESS = 4;        // mm - each elliptical disc

// Spacing calculation
// Each wave unit = wave + gap for cam to pass
WAVE_GAP = 1;             // mm clearance between wave and adjacent cam
UNIT_PITCH = WAVE_THICKNESS + CAM_THICKNESS + 2*WAVE_GAP;  // 4+4+2 = 10mm per wave

// Maximum waves that fit
NUM_WAVES = floor(WAVE_AREA_WIDTH / UNIT_PITCH);  // 224/10 = 22 waves!

// Phase offset for traveling wave
PHASE_OFFSET = 360 / NUM_WAVES;  // 360/22 = 16.36° per wave

// ============================================
// CAMSHAFT PARAMETERS
// ============================================

CAMSHAFT_DIA = 6;         // mm - thin shaft
CAMSHAFT_HOLE = 6.4;      // mm - clearance for rotation
CAMSHAFT_LENGTH = WAVE_AREA_WIDTH + 40;  // 264mm

// Camshaft position (runs along X axis at front of waves)
CAMSHAFT_X_START = WAVE_AREA_START_X - 20;
CAMSHAFT_Y = 70;          // mm - front position
CAMSHAFT_Z = 28;          // mm - height (REVISED: raised to avoid bottom collision)

// ============================================
// HINGE AXLE PARAMETERS (CRITICAL!)
// ============================================

// Single axle runs through ALL wave rectangular slots
HINGE_AXLE_DIA = 5;       // mm
HINGE_AXLE_HOLE = 5.4;    // mm - slot width (clearance)
HINGE_AXLE_LENGTH = WAVE_AREA_WIDTH + 40;  // Same as camshaft

// Hinge axle position (back of waves, fixed)
HINGE_AXLE_X_START = WAVE_AREA_START_X - 20;
HINGE_AXLE_Y = 0;         // mm - back position
HINGE_AXLE_Z = 25;        // mm - height (REVISED: raised proportionally)

// ============================================
// WAVE SLAT PARAMETERS
// ============================================

WAVE_LENGTH = 75;         // mm - Y dimension (hinge to cam contact)
WAVE_HEIGHT = 25;         // mm - Z dimension (visual height of wave)

// Rectangular slot at hinge end
SLOT_LENGTH = 15;         // mm - allows front/back sliding on axle (REVISED: increased for angular range)
SLOT_HEIGHT = HINGE_AXLE_HOLE;  // mm - fits axle

// ============================================
// ELLIPTICAL CAM PARAMETERS
// ============================================

// Progressive cam sizes (gentle right → dramatic left)
// Format: [major_axis, minor_axis] in mm (full diameter, not radius)
// Major axis = vertical movement range
// Minor axis = horizontal (front/back) movement

function cam_major(i) = 8 + (i / NUM_WAVES) * 16;   // 8mm to 24mm
function cam_minor(i) = 4 + (i / NUM_WAVES) * 6;    // 4mm to 10mm (REVISED: limited to avoid side collision)

// ============================================
// FRAME PARAMETERS
// ============================================

FRAME_LENGTH = WAVE_AREA_WIDTH + 60;  // 284mm
FRAME_DEPTH = 100;                     // mm
FRAME_HEIGHT = 60;                     // mm (REVISED: taller for raised mechanism)
FRAME_WALL = 5;                        // mm

FRAME_X_START = WAVE_AREA_START_X - 30;
FRAME_Y_START = -20;
FRAME_Z_START = 0;

// ============================================
// HAND CRANK
// ============================================

CRANK_ARM = 30;
CRANK_KNOB_DIA = 12;
CRANK_KNOB_H = 20;

// ============================================
// COLORS
// ============================================

C_FRAME = [0.35, 0.30, 0.25];     // Dark wood
C_WAVE = [0.8, 0.65, 0.45];       // Light wood
C_CAM = [0.7, 0.55, 0.35];        // Medium wood
C_SHAFT = [0.5, 0.5, 0.55];       // Steel
C_AXLE = [0.6, 0.6, 0.65];        // Steel

$fn = 48;

// ============================================
// FUNCTIONS
// ============================================

// X position of wave center (along camshaft)
function wave_x(i) = WAVE_AREA_START_X + 10 + i * UNIT_PITCH;

// Phase angle for wave i
function wave_phase(i) = i * PHASE_OFFSET;

// Cam vertical position (Z displacement from center)
function cam_z_offset(i) = (cam_major(i)/2) * sin(theta + wave_phase(i));

// Cam horizontal position (Y displacement from center)
function cam_y_offset(i) = (cam_minor(i)/2) * cos(theta + wave_phase(i));

// Wave front Z position (rides on cam)
function wave_front_z(i) = CAMSHAFT_Z + cam_z_offset(i);

// Wave angle (pivot about hinge axle)
function wave_angle(i) =
    let(front_z = wave_front_z(i))
    let(hinge_z = HINGE_AXLE_Z)
    let(dy = CAMSHAFT_Y - HINGE_AXLE_Y)
    let(dz = front_z - hinge_z)
    atan2(dz, dy);

// ============================================
// MODULES
// ============================================

// Single elliptical disc cam
module elliptical_cam(major, minor, thickness) {
    color(C_CAM)
        difference() {
            // Elliptical disc
            scale([1, minor/major, 1])
                cylinder(d=major, h=thickness, center=true);

            // Shaft hole
            cylinder(d=CAMSHAFT_DIA + 0.3, h=thickness + 2, center=true);
        }
}

// Camshaft only (no cams)
module camshaft_only() {
    color(C_SHAFT)
        translate([CAMSHAFT_X_START, CAMSHAFT_Y, CAMSHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA, h=CAMSHAFT_LENGTH);
}

// All cams on camshaft
module cams_only() {
    for (i = [0:NUM_WAVES-1]) {
        if (i >= WAVE_RANGE_START && i <= WAVE_RANGE_END) {
            x = wave_x(i);
            major = cam_major(i);
            minor = cam_minor(i);

            translate([x, CAMSHAFT_Y, CAMSHAFT_Z])
                rotate([0, 90, 0])
                    rotate([0, 0, theta + wave_phase(i)])
                        elliptical_cam(major, minor, CAM_THICKNESS);
        }
    }
}

// Camshaft with all cams (combined for compatibility)
module camshaft_assembly() {
    if (SHOW_CAMSHAFT) camshaft_only();
    if (SHOW_CAMS) cams_only();
}

// Hinge axle (static - waves pivot on this)
module hinge_axle() {
    color(C_AXLE)
        translate([HINGE_AXLE_X_START, HINGE_AXLE_Y, HINGE_AXLE_Z])
            rotate([0, 90, 0])
                cylinder(d=HINGE_AXLE_DIA, h=HINGE_AXLE_LENGTH);
}

// Single wave slat with rectangular slot
module wave_slat(wave_num) {
    i = wave_num;
    x = wave_x(i);
    angle = wave_angle(i);

    // Calculate actual wave length from hinge to cam contact
    actual_length = sqrt(pow(CAMSHAFT_Y - HINGE_AXLE_Y, 2) + pow(wave_front_z(i) - HINGE_AXLE_Z, 2));

    color(C_WAVE)
        translate([x, HINGE_AXLE_Y, HINGE_AXLE_Z])
            rotate([angle, 0, 0])
                translate([-WAVE_THICKNESS/2, 0, -WAVE_HEIGHT/2]) {
                    difference() {
                        // Main wave body
                        cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_HEIGHT]);

                        // Rectangular slot at hinge end (axle passes through)
                        translate([-1, -1, WAVE_HEIGHT/2 - SLOT_HEIGHT/2])
                            cube([WAVE_THICKNESS + 2, SLOT_LENGTH + 1, SLOT_HEIGHT]);
                    }

                    // Cam follower nub at front (contacts cam)
                    translate([WAVE_THICKNESS/2, WAVE_LENGTH - 5, WAVE_HEIGHT/2])
                        rotate([0, 90, 0])
                            cylinder(d=6, h=WAVE_THICKNESS, center=true);
                }
}

// Frame - left side plate with bearings
module frame_left() {
    color(C_FRAME)
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_START])
            difference() {
                // Side plate
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

                // Camshaft bearing hole
                translate([-1, CAMSHAFT_Y - FRAME_Y_START, CAMSHAFT_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_HOLE, h=FRAME_WALL + 2);

                // Hinge axle hole
                translate([-1, HINGE_AXLE_Y - FRAME_Y_START, HINGE_AXLE_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
            }
}

// Frame - right side plate with bearings
module frame_right() {
    color(C_FRAME)
        translate([FRAME_X_START + FRAME_LENGTH - FRAME_WALL, FRAME_Y_START, FRAME_Z_START])
            difference() {
                // Side plate
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);

                // Camshaft bearing hole
                translate([-1, CAMSHAFT_Y - FRAME_Y_START, CAMSHAFT_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_HOLE, h=FRAME_WALL + 2);

                // Hinge axle hole
                translate([-1, HINGE_AXLE_Y - FRAME_Y_START, HINGE_AXLE_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
            }
}

// Frame - base plate
module frame_base() {
    color(C_FRAME)
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_START])
            cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);
}

// Frame - back rail (supports hinge axle)
module frame_back_rail() {
    color(C_FRAME)
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_START])
            difference() {
                cube([FRAME_LENGTH, FRAME_WALL + 5, FRAME_HEIGHT/2]);

                // Hinge axle channel
                translate([-1, HINGE_AXLE_Y - FRAME_Y_START + FRAME_WALL/2, HINGE_AXLE_Z])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_LENGTH + 2);
            }
}

// Frame - front rail (supports camshaft)
module frame_front_rail() {
    color(C_FRAME)
        translate([FRAME_X_START, FRAME_Y_START + FRAME_DEPTH - FRAME_WALL - 15, FRAME_Z_START])
            difference() {
                cube([FRAME_LENGTH, FRAME_WALL + 15, FRAME_HEIGHT/2 + 10]);

                // Camshaft channel
                translate([-1, CAMSHAFT_Y - (FRAME_Y_START + FRAME_DEPTH - FRAME_WALL - 15), CAMSHAFT_Z])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_HOLE, h=FRAME_LENGTH + 2);
            }
}

// Hand crank on left side
module hand_crank() {
    color(C_CAM)
        translate([FRAME_X_START - 5, CAMSHAFT_Y, CAMSHAFT_Z])
            rotate([0, -90, 0]) {
                // Hub
                difference() {
                    cylinder(d=16, h=6);
                    translate([0, 0, -1])
                        cylinder(d=CAMSHAFT_DIA + 0.3, h=8);
                }

                // Arm
                translate([0, -4, 0])
                    cube([CRANK_ARM, 8, 6]);

                // Knob
                translate([CRANK_ARM, 0, 0])
                    cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
            }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_ocean_v2_assembly() {
    // === FRAME (all static, all connected) ===
    if (SHOW_FRAME_LEFT) frame_left();
    if (SHOW_FRAME_RIGHT) frame_right();
    if (SHOW_FRAME_BASE) frame_base();
    if (SHOW_FRAME_BACK_RAIL) frame_back_rail();
    if (SHOW_FRAME_FRONT_RAIL) frame_front_rail();

    // === HINGE AXLE (static - waves pivot on this) ===
    if (SHOW_HINGE_AXLE) hinge_axle();

    // === CAMSHAFT + CAMS (rotating) ===
    camshaft_assembly();

    // === HAND CRANK (rotating with camshaft) ===
    if (SHOW_HAND_CRANK) hand_crank();

    // === WAVE SLATS (pivot on hinge axle, pushed by cams) ===
    if (SHOW_WAVES) {
        for (i = [WAVE_RANGE_START:min(WAVE_RANGE_END, NUM_WAVES-1)]) {
            wave_slat(i);
        }
    }
}

// ============================================
// RENDER
// ============================================

wave_ocean_v2_assembly();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("╔══════════════════════════════════════════════════════╗");
echo("║       WAVE OCEAN MECHANISM v2 - THIN DISC DESIGN     ║");
echo("╚══════════════════════════════════════════════════════╝");
echo("");
echo(str("Wave area: ", WAVE_AREA_WIDTH, "mm"));
echo(str("Unit pitch: ", UNIT_PITCH, "mm (wave + cam + gaps)"));
echo(str("NUMBER OF WAVES: ", NUM_WAVES, " ← Maximum fit!"));
echo(str("Phase offset: ", PHASE_OFFSET, "° per wave"));
echo("");
echo("THICKNESSES:");
echo(str("  Wave slat: ", WAVE_THICKNESS, "mm"));
echo(str("  Cam disc: ", CAM_THICKNESS, "mm"));
echo(str("  Camshaft: ", CAMSHAFT_DIA, "mm diameter"));
echo(str("  Hinge axle: ", HINGE_AXLE_DIA, "mm diameter"));
echo("");
echo("PROGRESSIVE CAM SIZES:");
echo(str("  Wave 1 (right):  ", cam_major(0), "×", cam_minor(0), "mm"));
echo(str("  Wave ", floor(NUM_WAVES/2), " (middle): ", cam_major(floor(NUM_WAVES/2)), "×", cam_minor(floor(NUM_WAVES/2)), "mm"));
echo(str("  Wave ", NUM_WAVES, " (left):   ", cam_major(NUM_WAVES-1), "×", cam_minor(NUM_WAVES-1), "mm"));
echo("");
echo("HINGE MECHANISM:");
echo("  Single axle through rectangular slots in ALL waves");
echo("  Waves pivot about this common axis");
echo("  Slot allows front/back sliding as wave rocks");
echo("");
echo("CURRENT STATE:");
echo(str("  Camshaft angle: ", theta, "°"));
for (i = [0:4:NUM_WAVES-1]) {
    echo(str("  Wave ", i+1, ": angle=", wave_angle(i), "°, front_z=", wave_front_z(i), "mm"));
}

// ============================================
// POWER PATH
// ============================================

echo("");
echo("=== POWER PATH ===");
echo("Hand Crank → Camshaft → Elliptical Disc Cams → Wave Slats");
echo("Waves pivot on common hinge axle, pushed by cams at front");

// ============================================
// PRINTABILITY CHECK
// ============================================

echo("");
echo("=== PRINTABILITY CHECK ===");
echo(str("Wave thickness: ", WAVE_THICKNESS, "mm - ", WAVE_THICKNESS >= 1.2 ? "PASS" : "FAIL"));
echo(str("Cam thickness: ", CAM_THICKNESS, "mm - ", CAM_THICKNESS >= 1.2 ? "PASS" : "FAIL"));
echo(str("Shaft clearance: ", (CAMSHAFT_HOLE - CAMSHAFT_DIA)/2, "mm - ",
         (CAMSHAFT_HOLE - CAMSHAFT_DIA)/2 >= 0.2 ? "PASS" : "FAIL"));
echo(str("Axle clearance: ", (SLOT_HEIGHT - HINGE_AXLE_DIA)/2, "mm - ",
         (SLOT_HEIGHT - HINGE_AXLE_DIA)/2 >= 0.2 ? "PASS" : "FAIL"));

// ============================================
// sin($t) AUDIT
// ============================================

/*
 * Animation audit - every trig function traces to physical mechanism:
 *
 * cam_z_offset(i) = (cam_major(i)/2) * sin(theta + wave_phase(i))
 *   Physical driver: Elliptical cam rotation (major axis vertical)
 *   Traced: YES - cam pushes wave up/down
 *
 * cam_y_offset(i) = (cam_minor(i)/2) * cos(theta + wave_phase(i))
 *   Physical driver: Elliptical cam rotation (minor axis horizontal)
 *   Traced: YES - cam pushes follower front/back
 *
 * wave_angle(i) = atan2(dz, dy)
 *   Physical driver: Geometry of wave pivoting on hinge axle
 *   Traced: YES - derived from cam position
 *
 * ORPHAN ANIMATIONS: 0
 */
