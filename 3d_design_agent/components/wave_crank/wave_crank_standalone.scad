/*
 * WAVE CRANK MECHANISM v1
 *
 * Mechanism: Direct Eccentric Throw - 3 wave segments ride on crankshaft throws
 * Motion: Rolling waves with 120° phase offset
 * Validated: 2026-01-20
 *
 * All dimensions from: 0_geometry.md
 */

// ============================================
// PARAMETERS (from geometry checklist)
// ============================================

// Animation control
// MANUAL_ANGLE: -1 = animate with $t, 0/90/180/270 = fixed angle for testing
MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// Crankshaft parameters (from checklist Part 2)
CRANK_SHAFT_DIA = 8;        // mm - shaft diameter
CRANK_SHAFT_LEN = 90;       // mm - total shaft length
CRANK_SHAFT_HOLE = 8.6;     // mm - bearing hole (0.3mm clearance each side)

// Throw parameters (from checklist Parts 4-6)
THROW_ECCENTRICITY = 8;     // mm - offset from shaft center = wave amplitude
THROW_DIAMETER = 10;        // mm - throw journal diameter
THROW_WIDTH = 15;           // mm - throw width
THROW_CLEARANCE = 0.3;      // mm - clearance in slot

// Throw Z positions (from checklist)
THROW_1_Z = 0;              // mm - Phase 0°
THROW_2_Z = 25;             // mm - Phase 120°
THROW_3_Z = 50;             // mm - Phase 240°

// Phase offsets
PHASE_1 = 0;                // degrees
PHASE_2 = 120;              // degrees
PHASE_3 = 240;              // degrees

// Wave segment parameters (from checklist Parts 7-9)
SEGMENT_WIDTH = 70;         // mm - X dimension
SEGMENT_DEPTH = 40;         // mm - Y dimension (wave height)
SEGMENT_THICKNESS = 3;      // mm - Z thickness
SLOT_WIDTH = 12;            // mm - slot X dimension (throw + 2mm clearance)
SLOT_LENGTH = 30;           // mm - slot Y dimension (travel + throw + clearance)

// Guide rail parameters (from checklist Part 10)
GUIDE_WIDTH = 5;            // mm
GUIDE_LENGTH = 90;          // mm
GUIDE_HEIGHT = 20;          // mm
GUIDE_X_OFFSET = 25;        // mm - distance from center

// Base frame parameters (from checklist Part 1)
BASE_WIDTH = 100;           // mm - X
BASE_DEPTH = 60;            // mm - Y
BASE_THICKNESS = 5;         // mm - Z
BASE_Z = -25;               // mm - position below mechanism

// Belt pulley parameters (from checklist Part 3)
PULLEY_TEETH = 30;          // GT2 teeth
PULLEY_PITCH = 2;           // mm - GT2 pitch
PULLEY_RADIUS = PULLEY_TEETH * PULLEY_PITCH / (2 * PI);  // ~9.55mm
PULLEY_OD = 32;             // mm - outer diameter
PULLEY_WIDTH = 8;           // mm
PULLEY_Z = -35;             // mm - position on shaft

// Bearing parameters
BEARING_OD = 16;            // mm
BEARING_HEIGHT = 8;         // mm

// Colors
C_SHAFT = [0.7, 0.7, 0.75];      // Silver
C_THROW = [0.8, 0.6, 0.2];       // Bronze
C_SEGMENT = [0.3, 0.5, 0.8];     // Blue (wave)
C_GUIDE = [0.4, 0.4, 0.4];       // Dark gray
C_BASE = [0.3, 0.3, 0.3];        // Darker gray
C_PULLEY = [0.2, 0.2, 0.2];      // Black
C_BEARING = [0.6, 0.6, 0.6];     // Light gray

// Resolution
$fn = 64;

// Printability constants
WALL_MIN = 1.2;             // mm - minimum wall thickness
CLEARANCE_MIN = 0.3;        // mm - minimum clearance

// ============================================
// DERIVED CALCULATIONS
// ============================================

// Wave segment Y positions (driven by throws)
function segment_y(phase) = THROW_ECCENTRICITY * sin(theta + phase);

// Throw X,Y positions (eccentric rotation)
function throw_x(phase) = THROW_ECCENTRICITY * cos(theta + phase);
function throw_y(phase) = THROW_ECCENTRICITY * sin(theta + phase);

// ============================================
// MODULES
// ============================================

// Crankshaft with integrated throws
module crankshaft() {
    // Main shaft
    color(C_SHAFT)
        translate([0, 0, -40])
            cylinder(d=CRANK_SHAFT_DIA, h=CRANK_SHAFT_LEN);

    // Throw 1 (Phase 0°)
    color(C_THROW)
        translate([throw_x(PHASE_1), throw_y(PHASE_1), THROW_1_Z])
            cylinder(d=THROW_DIAMETER, h=THROW_WIDTH);

    // Throw 2 (Phase 120°)
    color(C_THROW)
        translate([throw_x(PHASE_2), throw_y(PHASE_2), THROW_2_Z])
            cylinder(d=THROW_DIAMETER, h=THROW_WIDTH);

    // Throw 3 (Phase 240°)
    color(C_THROW)
        translate([throw_x(PHASE_3), throw_y(PHASE_3), THROW_3_Z])
            cylinder(d=THROW_DIAMETER, h=THROW_WIDTH);

    // Crank webs connecting shaft to throws
    for (i = [0:2]) {
        phase = i * 120;
        z_pos = i * 25;
        color(C_SHAFT)
            translate([0, 0, z_pos])
                linear_extrude(height=3)
                    hull() {
                        circle(d=CRANK_SHAFT_DIA);
                        translate([throw_x(phase), throw_y(phase)])
                            circle(d=THROW_DIAMETER);
                    }
    }
}

// Wave segment with slot
module wave_segment(segment_num) {
    phase = segment_num * 120;
    y_offset = segment_y(phase);

    color(C_SEGMENT)
        translate([0, y_offset, 0])
            difference() {
                // Main body with wavy top
                linear_extrude(height=SEGMENT_THICKNESS)
                    difference() {
                        // Outer shape - rectangle with wavy top
                        polygon([
                            [-SEGMENT_WIDTH/2, -SEGMENT_DEPTH/2],
                            [SEGMENT_WIDTH/2, -SEGMENT_DEPTH/2],
                            [SEGMENT_WIDTH/2, SEGMENT_DEPTH/2 - 5],
                            // Wavy top edge
                            for (x = [SEGMENT_WIDTH/2 : -2 : -SEGMENT_WIDTH/2])
                                [x, SEGMENT_DEPTH/2 + 3*sin(x*10 + segment_num*60)]
                        ]);

                        // Slot for throw
                        translate([-SLOT_WIDTH/2, -SLOT_LENGTH/2])
                            square([SLOT_WIDTH, SLOT_LENGTH]);
                    }
            }
}

// Simplified wave segment (rectangular for easier debugging)
module wave_segment_simple(segment_num) {
    phase = segment_num * 120;
    y_offset = segment_y(phase);

    color(C_SEGMENT)
        translate([-SEGMENT_WIDTH/2, y_offset - SEGMENT_DEPTH/2, 0])
            difference() {
                // Main body
                cube([SEGMENT_WIDTH, SEGMENT_DEPTH, SEGMENT_THICKNESS]);

                // Slot for throw (centered)
                translate([SEGMENT_WIDTH/2 - SLOT_WIDTH/2, SEGMENT_DEPTH/2 - SLOT_LENGTH/2, -1])
                    cube([SLOT_WIDTH, SLOT_LENGTH, SEGMENT_THICKNESS + 2]);
            }
}

// Guide rail
module guide_rail() {
    color(C_GUIDE)
        translate([0, -GUIDE_HEIGHT/2, -5])
            cube([GUIDE_WIDTH, GUIDE_HEIGHT, GUIDE_LENGTH]);
}

// Base frame with bearing mounts
module base_frame() {
    color(C_BASE)
        difference() {
            // Main plate
            translate([-BASE_WIDTH/2, -BASE_DEPTH/2, BASE_Z])
                cube([BASE_WIDTH, BASE_DEPTH, BASE_THICKNESS]);

            // Shaft hole
            translate([0, 0, BASE_Z - 1])
                cylinder(d=CRANK_SHAFT_HOLE, h=BASE_THICKNESS + 2);
        }

    // Bearing mounts
    color(C_BEARING)
        translate([0, 0, BASE_Z + BASE_THICKNESS])
            difference() {
                cylinder(d=BEARING_OD, h=BEARING_HEIGHT);
                translate([0, 0, -1])
                    cylinder(d=CRANK_SHAFT_HOLE, h=BEARING_HEIGHT + 2);
            }
}

// Belt pulley (simplified)
module belt_pulley() {
    color(C_PULLEY)
        translate([0, 0, PULLEY_Z])
            difference() {
                cylinder(d=PULLEY_OD, h=PULLEY_WIDTH);
                translate([0, 0, -1])
                    cylinder(d=CRANK_SHAFT_HOLE, h=PULLEY_WIDTH + 2);
                // Belt groove
                translate([0, 0, 2])
                    difference() {
                        cylinder(d=PULLEY_OD + 1, h=4);
                        cylinder(d=PULLEY_OD - 4, h=4);
                    }
            }
}

// Hand crank for testing
module hand_crank() {
    crank_arm = 25;
    knob_d = 12;
    knob_h = 15;

    color(C_THROW)
        translate([0, 0, CRANK_SHAFT_LEN - 45]) {  // Top of shaft
            // Arm
            hull() {
                cylinder(d=CRANK_SHAFT_DIA + 4, h=3);
                translate([crank_arm, 0, 0])
                    cylinder(d=8, h=3);
            }
            // Knob
            translate([crank_arm, 0, 3])
                cylinder(d=knob_d, h=knob_h);
        }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_crank_assembly() {
    // Base frame (static)
    base_frame();

    // Rotating group - crankshaft + throws + pulley + crank
    rotate([0, 0, theta]) {
        crankshaft();
        belt_pulley();
        hand_crank();
    }

    // Wave segments (move vertically, constrained by guides)
    translate([0, 0, THROW_1_Z])
        wave_segment_simple(0);

    translate([0, 0, THROW_2_Z])
        wave_segment_simple(1);

    translate([0, 0, THROW_3_Z])
        wave_segment_simple(2);

    // Guide rails (static)
    translate([GUIDE_X_OFFSET, 0, 0])
        guide_rail();
    translate([-GUIDE_X_OFFSET - GUIDE_WIDTH, 0, 0])
        guide_rail();
}

// ============================================
// RENDER
// ============================================

wave_crank_assembly();

// ============================================
// POWER PATH ECHO
// ============================================

echo("=== WAVE CRANK MECHANISM ===");
echo("Power: Hand Crank / Belt → Crankshaft → 3 Throws → 3 Wave Segments");
echo("");
echo(str("Crankshaft angle: ", theta, "° ($t=", $t, ")"));
echo("");
echo("Segment positions (Y offset from center):");
echo(str("  Segment 1 (phase 0°):   Y = ", segment_y(PHASE_1), "mm"));
echo(str("  Segment 2 (phase 120°): Y = ", segment_y(PHASE_2), "mm"));
echo(str("  Segment 3 (phase 240°): Y = ", segment_y(PHASE_3), "mm"));
echo("");
echo("Throw positions:");
echo(str("  Throw 1: X=", throw_x(PHASE_1), " Y=", throw_y(PHASE_1)));
echo(str("  Throw 2: X=", throw_x(PHASE_2), " Y=", throw_y(PHASE_2)));
echo(str("  Throw 3: X=", throw_x(PHASE_3), " Y=", throw_y(PHASE_3)));

// ============================================
// PRINTABILITY ECHO
// ============================================

echo("");
echo("=== PRINTABILITY CHECK ===");
echo(str("Min wall (segment): ", SEGMENT_THICKNESS, "mm - ",
         SEGMENT_THICKNESS >= WALL_MIN ? "PASS" : "FAIL"));
echo(str("Min wall (guide): ", GUIDE_WIDTH, "mm - ",
         GUIDE_WIDTH >= WALL_MIN ? "PASS" : "FAIL"));
echo(str("Slot clearance: ", (SLOT_WIDTH - THROW_DIAMETER)/2, "mm - ",
         (SLOT_WIDTH - THROW_DIAMETER)/2 >= CLEARANCE_MIN ? "PASS" : "FAIL"));
echo(str("Shaft clearance: ", (CRANK_SHAFT_HOLE - CRANK_SHAFT_DIA)/2, "mm - ",
         (CRANK_SHAFT_HOLE - CRANK_SHAFT_DIA)/2 >= CLEARANCE_MIN ? "PASS" : "FAIL"));

// ============================================
// sin($t) AUDIT
// ============================================
/*
 * Animation audit - every sin() traces to physical mechanism:
 *
 * Line 72: segment_y(phase) = THROW_ECCENTRICITY * sin(theta + phase)
 *   Physical driver: Crankshaft throw at eccentric offset
 *   Traced to source: YES - throw rotation creates sinusoidal Y motion
 *
 * Line 75: throw_x(phase) = THROW_ECCENTRICITY * cos(theta + phase)
 * Line 76: throw_y(phase) = THROW_ECCENTRICITY * sin(theta + phase)
 *   Physical driver: Eccentric throw position on rotating crankshaft
 *   Traced to source: YES - direct eccentric rotation
 *
 * ORPHAN ANIMATIONS: 0
 */
