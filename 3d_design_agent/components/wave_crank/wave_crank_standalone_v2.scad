/*
 * WAVE CRANK MECHANISM v2 - CORRECTED
 *
 * Mechanism: Direct Eccentric Throw - 3 wave segments ride on crankshaft throws
 * Motion: Rolling waves with 120° phase offset
 *
 * FIXES from v1:
 * - Hand crank now OUTSIDE mechanism (top of shaft)
 * - Pulley now OUTSIDE base (accessible for belt)
 * - Guide rails now CONNECTED to base frame
 * - Proper structural support
 */

// ============================================
// PARAMETERS
// ============================================

// Animation control
MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// === LAYOUT (key positions) ===
// Shaft runs VERTICALLY along Z axis
// Waves are in XY plane, stacked along Z
// Base is at bottom, pulley below base (front), crank above top (back)

WAVE_ZONE_START = 0;      // Z where first wave segment starts
WAVE_ZONE_END = 70;       // Z where last wave segment ends
SEGMENT_SPACING = 25;     // Z spacing between segment centers

// === CRANKSHAFT ===
CRANK_SHAFT_DIA = 8;
CRANK_SHAFT_HOLE = 8.6;   // 0.3mm clearance each side

// Shaft extends from below base to above wave zone
SHAFT_BOTTOM = -20;       // Below base for pulley
SHAFT_TOP = 80;           // Above wave zone for crank
CRANK_SHAFT_LEN = SHAFT_TOP - SHAFT_BOTTOM;

// === THROWS (eccentric journals) ===
THROW_ECCENTRICITY = 8;   // Wave amplitude
THROW_DIAMETER = 10;
THROW_WIDTH = 12;         // Narrower than segment thickness

// Throw centers (Z positions)
THROW_1_Z = 5;            // Center of throw 1
THROW_2_Z = 30;           // Center of throw 2
THROW_3_Z = 55;           // Center of throw 3

// Phase offsets
PHASE_1 = 0;
PHASE_2 = 120;
PHASE_3 = 240;

// === WAVE SEGMENTS ===
SEGMENT_WIDTH = 80;       // X dimension
SEGMENT_DEPTH = 50;       // Y dimension (includes travel)
SEGMENT_THICKNESS = 15;   // Z thickness (throw rides inside)
SLOT_WIDTH = 12;          // X slot size (throw + clearance)
SLOT_LENGTH = 30;         // Y slot size (throw + travel + clearance)

// === BASE FRAME ===
BASE_WIDTH = 100;
BASE_DEPTH = 70;
BASE_THICKNESS = 8;
BASE_Z = -15;             // Top surface of base

// === SIDE WALLS (guide rails integrated into structure) ===
WALL_THICKNESS = 5;
WALL_HEIGHT = WAVE_ZONE_END + 20;  // Extends above wave zone

// === PULLEY (front of mechanism, below base) ===
PULLEY_OD = 30;
PULLEY_WIDTH = 8;
PULLEY_Z = SHAFT_BOTTOM + 2;  // Just above bottom of shaft

// === HAND CRANK (top of mechanism, above waves) ===
CRANK_ARM_LENGTH = 30;
CRANK_Z = SHAFT_TOP - 20;     // Near top of shaft

// Colors
C_SHAFT = [0.7, 0.7, 0.75];
C_THROW = [0.8, 0.6, 0.2];
C_SEGMENT = [0.3, 0.5, 0.9];
C_FRAME = [0.35, 0.35, 0.35];
C_PULLEY = [0.2, 0.2, 0.2];

$fn = 64;

// ============================================
// FUNCTIONS
// ============================================

function segment_y(phase) = THROW_ECCENTRICITY * sin(theta + phase);
function throw_x(phase) = THROW_ECCENTRICITY * cos(theta + phase);
function throw_y(phase) = THROW_ECCENTRICITY * sin(theta + phase);

// ============================================
// MODULES
// ============================================

// Crankshaft with throws and webs
module crankshaft() {
    // Main shaft
    color(C_SHAFT)
        translate([0, 0, SHAFT_BOTTOM])
            cylinder(d=CRANK_SHAFT_DIA, h=CRANK_SHAFT_LEN);

    // Three throws with webs
    for (i = [0:2]) {
        phase = i * 120;
        z = [THROW_1_Z, THROW_2_Z, THROW_3_Z][i];

        // Throw journal
        color(C_THROW)
            translate([throw_x(phase), throw_y(phase), z - THROW_WIDTH/2])
                cylinder(d=THROW_DIAMETER, h=THROW_WIDTH);

        // Web connecting shaft to throw
        color(C_SHAFT)
            translate([0, 0, z - 1.5])
                linear_extrude(height=3)
                    hull() {
                        circle(d=CRANK_SHAFT_DIA);
                        translate([throw_x(phase), throw_y(phase)])
                            circle(d=THROW_DIAMETER);
                    }
    }
}

// Wave segment with slot for throw
module wave_segment(segment_num) {
    phase = segment_num * 120;
    y_offset = segment_y(phase);
    z = [THROW_1_Z, THROW_2_Z, THROW_3_Z][segment_num];

    color(C_SEGMENT)
        translate([0, y_offset, z - SEGMENT_THICKNESS/2]) {
            difference() {
                // Main body - centered on origin
                translate([-SEGMENT_WIDTH/2, -SEGMENT_DEPTH/2, 0])
                    cube([SEGMENT_WIDTH, SEGMENT_DEPTH, SEGMENT_THICKNESS]);

                // Slot for throw - allows horizontal movement
                translate([-SLOT_WIDTH/2, -SLOT_LENGTH/2, -1])
                    cube([SLOT_WIDTH, SLOT_LENGTH, SEGMENT_THICKNESS + 2]);

                // Guide channels on sides (wave slides in guides)
                // Left channel
                translate([-SEGMENT_WIDTH/2 - 1, -SEGMENT_DEPTH/2 - 1, 2])
                    cube([WALL_THICKNESS + 1.5, SEGMENT_DEPTH + 2, SEGMENT_THICKNESS - 4]);
                // Right channel
                translate([SEGMENT_WIDTH/2 - WALL_THICKNESS - 0.5, -SEGMENT_DEPTH/2 - 1, 2])
                    cube([WALL_THICKNESS + 1.5, SEGMENT_DEPTH + 2, SEGMENT_THICKNESS - 4]);
            }
        }
}

// Base frame with integrated bearing
module base_frame() {
    color(C_FRAME) {
        difference() {
            union() {
                // Main base plate
                translate([-BASE_WIDTH/2, -BASE_DEPTH/2, BASE_Z - BASE_THICKNESS])
                    cube([BASE_WIDTH, BASE_DEPTH, BASE_THICKNESS]);

                // Bearing boss (above plate)
                translate([0, 0, BASE_Z])
                    cylinder(d=20, h=10);
            }

            // Shaft hole through everything
            translate([0, 0, BASE_Z - BASE_THICKNESS - 1])
                cylinder(d=CRANK_SHAFT_HOLE, h=BASE_THICKNESS + 12);
        }
    }
}

// Side walls with guide slots for wave segments
module side_walls() {
    color(C_FRAME) {
        for (side = [-1, 1]) {
            translate([side * (SEGMENT_WIDTH/2 + WALL_THICKNESS/2), 0, BASE_Z]) {
                difference() {
                    // Wall
                    translate([-WALL_THICKNESS/2, -BASE_DEPTH/2, 0])
                        cube([WALL_THICKNESS, BASE_DEPTH, WALL_HEIGHT]);

                    // Guide slots for each wave segment
                    for (i = [0:2]) {
                        z = [THROW_1_Z, THROW_2_Z, THROW_3_Z][i];
                        // Slot allows vertical movement
                        translate([-WALL_THICKNESS/2 - 1, -BASE_DEPTH/2 - 1, z - SEGMENT_THICKNESS/2 + 2])
                            cube([WALL_THICKNESS + 2, BASE_DEPTH + 2, SEGMENT_THICKNESS - 4]);
                    }
                }
            }
        }
    }
}

// Top beam connecting walls (structural)
module top_beam() {
    color(C_FRAME) {
        translate([-SEGMENT_WIDTH/2 - WALL_THICKNESS, -5, BASE_Z + WALL_HEIGHT - 5])
            cube([SEGMENT_WIDTH + 2*WALL_THICKNESS, 10, 5]);

        // Bearing at top
        translate([0, 0, BASE_Z + WALL_HEIGHT - 10])
            difference() {
                cylinder(d=20, h=10);
                translate([0, 0, -1])
                    cylinder(d=CRANK_SHAFT_HOLE, h=12);
            }
    }
}

// Pulley - positioned below base, accessible from front
module belt_pulley() {
    color(C_PULLEY)
        translate([0, 0, PULLEY_Z])
            difference() {
                union() {
                    cylinder(d=PULLEY_OD, h=PULLEY_WIDTH);
                    // Flange
                    cylinder(d=PULLEY_OD + 4, h=1);
                    translate([0, 0, PULLEY_WIDTH - 1])
                        cylinder(d=PULLEY_OD + 4, h=1);
                }
                // Shaft hole
                translate([0, 0, -1])
                    cylinder(d=CRANK_SHAFT_HOLE, h=PULLEY_WIDTH + 2);
            }
}

// Hand crank - positioned above top of mechanism
module hand_crank() {
    color(C_THROW)
        translate([0, 0, CRANK_Z]) {
            // Hub
            difference() {
                cylinder(d=16, h=5);
                translate([0, 0, -1])
                    cylinder(d=CRANK_SHAFT_DIA + 0.3, h=7);
            }
            // Arm
            translate([0, -4, 0])
                cube([CRANK_ARM_LENGTH, 8, 5]);
            // Knob
            translate([CRANK_ARM_LENGTH, 0, 0])
                cylinder(d=12, h=20);
        }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_crank_assembly() {
    // === STATIC STRUCTURE ===
    base_frame();
    side_walls();
    top_beam();

    // === ROTATING PARTS ===
    rotate([0, 0, theta]) {
        crankshaft();
        belt_pulley();
        hand_crank();
    }

    // === MOVING WAVE SEGMENTS ===
    wave_segment(0);
    wave_segment(1);
    wave_segment(2);
}

// ============================================
// RENDER
// ============================================

wave_crank_assembly();

// ============================================
// DEBUG
// ============================================

echo("=== WAVE CRANK v2 ===");
echo(str("Shaft: Z=", SHAFT_BOTTOM, " to Z=", SHAFT_TOP));
echo(str("Pulley: Z=", PULLEY_Z, " (below base at Z=", BASE_Z, ")"));
echo(str("Crank: Z=", CRANK_Z, " (above waves ending at Z=", WAVE_ZONE_END, ")"));
echo(str("Throws at Z=", THROW_1_Z, ", ", THROW_2_Z, ", ", THROW_3_Z));
echo(str("Current angle: ", theta, "°"));
