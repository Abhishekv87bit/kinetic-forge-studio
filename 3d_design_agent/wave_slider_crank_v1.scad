/*
 * WAVE SLIDER-CRANK MECHANISM v1
 *
 * ENGINEERING-LEVEL DESIGN
 * This file contains ONLY the drive mechanism with:
 * - Real pin holes with clearances
 * - Printable parts with wall thicknesses
 * - Proper bearing fits
 * - Assembly tolerances
 *
 * NO visual placeholders. Every part is manufacturable.
 *
 * MECHANISM: Slider-Crank
 * - Input: Rotating crank (motor driven)
 * - Output: Linear reciprocating motion (wave carrier)
 * - Stroke: 60mm (crank radius 30mm)
 *
 * COORDINATE SYSTEM:
 * - X: Direction of linear motion (wave travel)
 * - Y: Depth (motor behind, wave in front)
 * - Z: Vertical (up)
 *
 * PRINT SETTINGS:
 * - Layer height: 0.2mm
 * - Walls: 3 perimeters minimum
 * - Infill: 30% for structural parts
 * - Material: PLA or PETG
 */

$fn = 64;  // High resolution for holes

// ============================================
// ENGINEERING PARAMETERS
// ============================================

// Clearances (CRITICAL for function)
CLEARANCE_TIGHT = 0.15;     // Press fit
CLEARANCE_SLIDING = 0.3;    // Rotating joints
CLEARANCE_LOOSE = 0.5;      // Easy assembly

// Pin dimensions
PIN_DIA = 3.0;              // M3 rod or 3mm steel pin
PIN_HOLE_DIA = PIN_DIA + CLEARANCE_SLIDING;  // 3.3mm

// Shaft dimensions (motor output)
SHAFT_DIA = 4.0;            // GA12-N20 geared motor shaft
SHAFT_HOLE_DIA = SHAFT_DIA + CLEARANCE_TIGHT;  // 4.15mm (press fit)
SHAFT_FLAT_DEPTH = 0.5;     // D-shaft flat

// Bearing dimensions (if using bearings)
BEARING_OD = 10;            // 624ZZ bearing OD
BEARING_ID = 4;             // 624ZZ bearing ID
BEARING_WIDTH = 4;          // 624ZZ width

// Wall thicknesses (minimum for strength)
WALL_MIN = 2.0;             // Minimum wall around holes
WALL_STRUCTURAL = 3.0;      // Structural members

// ============================================
// MECHANISM GEOMETRY
// ============================================

// Crank dimensions
CRANK_RADIUS = 30;          // mm - gives 60mm stroke
CRANK_DISC_DIA = 50;        // mm - disc diameter
CRANK_DISC_THICK = 8;       // mm - thick enough for strength

// Connecting rod
ROD_LENGTH = 80;            // mm - center to center
ROD_WIDTH = 12;             // mm - width of rod body
ROD_THICK = 6;              // mm - thickness

// Slider/Carrier
SLIDER_LENGTH = 40;         // mm along X (travel direction)
SLIDER_WIDTH = 30;          // mm along Y
SLIDER_HEIGHT = 15;         // mm along Z
SLIDER_TRAVEL = 60;         // mm total travel (2 × crank radius)

// Guide rail
RAIL_WIDTH = 8;             // mm
RAIL_HEIGHT = 6;            // mm
RAIL_LENGTH = SLIDER_TRAVEL + SLIDER_LENGTH + 20;  // Total rail length

// Base plate
BASE_LENGTH = 200;          // mm along X
BASE_WIDTH = 100;           // mm along Y
BASE_THICK = 5;             // mm

// Motor (GA12-N20)
MOTOR_DIA = 12;             // mm body diameter
MOTOR_LENGTH = 25;          // mm body length
GEARBOX_SIZE = 10;          // mm square
GEARBOX_LENGTH = 15;        // mm

// ============================================
// POSITION CALCULATIONS
// ============================================

// Crank center position (where motor shaft is)
CRANK_X = BASE_LENGTH - 50;
CRANK_Y = BASE_WIDTH / 2;
CRANK_Z = BASE_THICK + 30;  // Height above base

// Slider center line
SLIDER_Y = CRANK_Y;
SLIDER_Z = CRANK_Z;

// Animation
MANUAL_ANGLE = -1;  // Set to 0, 90, 180, 270 for testing
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// Slider-crank kinematics
function slider_x(angle, r=CRANK_RADIUS, L=ROD_LENGTH) =
    r * cos(angle) + sqrt(L*L - r*r * sin(angle)*sin(angle));

// Current slider position
SLIDER_X_OFFSET = 20;  // Left margin on base
slider_pos = SLIDER_X_OFFSET + slider_x(theta);

// Crank pin position
crank_pin_x = CRANK_X + CRANK_RADIUS * cos(theta);
crank_pin_z = CRANK_Z + CRANK_RADIUS * sin(theta);

// Connecting rod angle
rod_angle = atan2(crank_pin_z - SLIDER_Z, crank_pin_x - slider_pos);

// ============================================
// COLORS
// ============================================

C_METAL = [0.7, 0.7, 0.75];
C_BRASS = [0.8, 0.6, 0.2];
C_WOOD = [0.4, 0.3, 0.2];
C_MOTOR = [0.3, 0.3, 0.35];
C_PIN = [0.5, 0.5, 0.55];

// ============================================
// PART 1: CRANK DISC
// ============================================
/*
 * Crank disc with:
 * - Center hole for motor shaft (D-shaft compatible)
 * - Offset hole for crank pin
 * - Decorative lightening holes (optional)
 */

module crank_disc() {
    color(C_BRASS)
    difference() {
        // Main disc body
        cylinder(d=CRANK_DISC_DIA, h=CRANK_DISC_THICK);

        // Center shaft hole (D-shaft)
        translate([0, 0, -0.1])
        difference() {
            cylinder(d=SHAFT_HOLE_DIA, h=CRANK_DISC_THICK + 0.2);
            // D-flat
            translate([SHAFT_DIA/2 - SHAFT_FLAT_DEPTH, -SHAFT_DIA, -0.1])
            cube([SHAFT_DIA, SHAFT_DIA*2, CRANK_DISC_THICK + 0.4]);
        }

        // Crank pin hole
        translate([CRANK_RADIUS, 0, -0.1])
        cylinder(d=PIN_HOLE_DIA, h=CRANK_DISC_THICK + 0.2);

        // Lightening holes (optional, for aesthetics and weight)
        for (a = [60, 180, 300]) {
            rotate([0, 0, a])
            translate([CRANK_DISC_DIA * 0.3, 0, -0.1])
            cylinder(d=10, h=CRANK_DISC_THICK + 0.2);
        }
    }
}

// ============================================
// PART 2: CRANK PIN
// ============================================
/*
 * Steel pin that connects crank disc to connecting rod
 * Press fit into crank disc, rotating fit in rod
 */

module crank_pin() {
    pin_length = CRANK_DISC_THICK + ROD_THICK + 5;  // Extends through both

    color(C_PIN)
    cylinder(d=PIN_DIA, h=pin_length);
}

// ============================================
// PART 3: CONNECTING ROD
// ============================================
/*
 * Rod with:
 * - Hole at crank end (rotates on crank pin)
 * - Hole at slider end (rotates on slider pin)
 * - Proper wall thickness around holes
 */

module connecting_rod() {
    boss_dia = PIN_DIA + 2 * WALL_MIN;  // Minimum boss around pin hole

    color(C_METAL)
    difference() {
        union() {
            // Main rod body
            hull() {
                // Crank end boss
                cylinder(d=boss_dia, h=ROD_THICK);
                // Slider end boss
                translate([ROD_LENGTH, 0, 0])
                cylinder(d=boss_dia, h=ROD_THICK);
            }

            // Reinforced bosses at ends
            cylinder(d=boss_dia + 2, h=ROD_THICK);
            translate([ROD_LENGTH, 0, 0])
            cylinder(d=boss_dia + 2, h=ROD_THICK);
        }

        // Crank end pin hole
        translate([0, 0, -0.1])
        cylinder(d=PIN_HOLE_DIA, h=ROD_THICK + 0.2);

        // Slider end pin hole
        translate([ROD_LENGTH, 0, -0.1])
        cylinder(d=PIN_HOLE_DIA, h=ROD_THICK + 0.2);
    }
}

// ============================================
// PART 4: SLIDER / WAVE CARRIER
// ============================================
/*
 * Slider that:
 * - Rides on guide rails (linear motion)
 * - Has pin hole for connecting rod
 * - Has mounting points for wave
 */

module slider_carrier() {
    color(C_WOOD)
    difference() {
        union() {
            // Main body
            translate([-SLIDER_LENGTH/2, -SLIDER_WIDTH/2, 0])
            cube([SLIDER_LENGTH, SLIDER_WIDTH, SLIDER_HEIGHT]);

            // Boss for rod pin
            translate([0, 0, SLIDER_HEIGHT])
            cylinder(d=PIN_DIA + 2*WALL_MIN + 2, h=ROD_THICK + 2);
        }

        // Rod pin hole (through boss and into body)
        translate([0, 0, SLIDER_HEIGHT - 5])
        cylinder(d=PIN_HOLE_DIA, h=ROD_THICK + 10);

        // Guide rail slots (slider rides on rails)
        // Front rail slot
        translate([-SLIDER_LENGTH/2 - 1, -SLIDER_WIDTH/2 + 5, -0.1])
        cube([SLIDER_LENGTH + 2, RAIL_WIDTH + CLEARANCE_SLIDING*2, RAIL_HEIGHT + CLEARANCE_SLIDING]);

        // Back rail slot
        translate([-SLIDER_LENGTH/2 - 1, SLIDER_WIDTH/2 - 5 - RAIL_WIDTH - CLEARANCE_SLIDING*2, -0.1])
        cube([SLIDER_LENGTH + 2, RAIL_WIDTH + CLEARANCE_SLIDING*2, RAIL_HEIGHT + CLEARANCE_SLIDING]);

        // Wave mounting holes (M3)
        for (dx = [-15, 15]) {
            translate([dx, 0, -0.1])
            cylinder(d=3.2, h=SLIDER_HEIGHT + 0.2);
        }
    }
}

// ============================================
// PART 5: SLIDER PIN
// ============================================

module slider_pin() {
    pin_length = ROD_THICK + SLIDER_HEIGHT;

    color(C_PIN)
    cylinder(d=PIN_DIA, h=pin_length);
}

// ============================================
// PART 6: GUIDE RAILS
// ============================================
/*
 * Two parallel rails that guide slider motion
 * Mounted to base plate
 */

module guide_rail() {
    color(C_WOOD)
    difference() {
        cube([RAIL_LENGTH, RAIL_WIDTH, RAIL_HEIGHT]);

        // Mounting holes
        for (dx = [15, RAIL_LENGTH/2, RAIL_LENGTH - 15]) {
            translate([dx, RAIL_WIDTH/2, -0.1])
            cylinder(d=3.2, h=RAIL_HEIGHT + 0.2);
        }
    }
}

module guide_rails_pair() {
    // Front rail
    translate([0, SLIDER_Y - SLIDER_WIDTH/2 + 5, BASE_THICK])
    guide_rail();

    // Back rail
    translate([0, SLIDER_Y + SLIDER_WIDTH/2 - 5 - RAIL_WIDTH, BASE_THICK])
    guide_rail();
}

// ============================================
// PART 7: CRANK BEARING MOUNT
// ============================================
/*
 * Support structure that holds the crank shaft
 * Can use either pressed bearing or printed bushing
 */

module bearing_mount() {
    mount_width = 20;
    mount_depth = 15;
    mount_height = CRANK_Z - BASE_THICK;

    color(C_WOOD)
    translate([-mount_width/2, -mount_depth/2, 0])
    difference() {
        // Main body
        cube([mount_width, mount_depth, mount_height]);

        // Shaft hole (or bearing pocket)
        translate([mount_width/2, mount_depth/2, mount_height - 10])
        cylinder(d=SHAFT_HOLE_DIA + 1, h=15);  // Loose fit for shaft

        // Mounting holes to base
        for (dx = [4, mount_width - 4]) {
            translate([dx, mount_depth/2, -0.1])
            cylinder(d=3.2, h=10);
        }
    }
}

// ============================================
// PART 8: BASE PLATE
// ============================================
/*
 * Main structural plate
 * Everything mounts to this
 */

module base_plate() {
    color(C_WOOD)
    difference() {
        cube([BASE_LENGTH, BASE_WIDTH, BASE_THICK]);

        // Guide rail mounting holes
        for (dx = [15, RAIL_LENGTH/2, RAIL_LENGTH - 15]) {
            // Front rail
            translate([dx, SLIDER_Y - SLIDER_WIDTH/2 + 5 + RAIL_WIDTH/2, -0.1])
            cylinder(d=3.2, h=BASE_THICK + 0.2);
            // Back rail
            translate([dx, SLIDER_Y + SLIDER_WIDTH/2 - 5 - RAIL_WIDTH/2, -0.1])
            cylinder(d=3.2, h=BASE_THICK + 0.2);
        }

        // Bearing mount holes
        translate([CRANK_X, CRANK_Y, -0.1]) {
            for (dx = [-6, 6]) {
                translate([dx, 0, 0])
                cylinder(d=3.2, h=BASE_THICK + 0.2);
            }
        }

        // Motor mount holes
        translate([CRANK_X, CRANK_Y + 30, -0.1]) {
            for (dxy = [[-8, -8], [8, -8], [-8, 8], [8, 8]]) {
                translate([dxy[0], dxy[1], 0])
                cylinder(d=3.2, h=BASE_THICK + 0.2);
            }
        }
    }
}

// ============================================
// PART 9: MOTOR MOUNT
// ============================================
/*
 * Bracket to hold GA12-N20 geared motor
 * Aligns motor shaft with crank center
 */

module motor_mount() {
    mount_width = 30;
    mount_depth = 25;
    mount_height = CRANK_Z - BASE_THICK;

    color(C_METAL)
    translate([-mount_width/2, 0, 0])
    difference() {
        union() {
            // Vertical plate
            cube([mount_width, 5, mount_height + 10]);

            // Base flange
            cube([mount_width, mount_depth, 5]);

            // Motor clamp ring
            translate([mount_width/2, -5, mount_height])
            rotate([-90, 0, 0])
            difference() {
                cylinder(d=MOTOR_DIA + 6, h=10);
                translate([0, 0, -0.1])
                cylinder(d=MOTOR_DIA + CLEARANCE_SLIDING, h=10.2);
            }
        }

        // Shaft hole
        translate([mount_width/2, -1, mount_height])
        rotate([-90, 0, 0])
        cylinder(d=SHAFT_DIA + 2, h=20);

        // Mounting holes
        for (dxy = [[-8, 15], [8, 15]]) {
            translate([mount_width/2 + dxy[0], dxy[1], -0.1])
            cylinder(d=3.2, h=10);
        }
    }
}

// ============================================
// PART 10: MOTOR (Reference)
// ============================================
/*
 * GA12-N20 motor model for visualization
 * NOT a printed part
 */

module motor_reference() {
    color(C_MOTOR) {
        // Motor body
        cylinder(d=MOTOR_DIA, h=MOTOR_LENGTH);

        // Gearbox
        translate([-GEARBOX_SIZE/2, -GEARBOX_SIZE/2, MOTOR_LENGTH])
        cube([GEARBOX_SIZE, GEARBOX_SIZE, GEARBOX_LENGTH]);

        // Shaft
        color(C_PIN)
        translate([0, 0, MOTOR_LENGTH + GEARBOX_LENGTH])
        cylinder(d=SHAFT_DIA, h=10);
    }
}

// ============================================
// ASSEMBLY
// ============================================

module slider_crank_assembly() {
    // Base plate
    base_plate();

    // Guide rails
    guide_rails_pair();

    // Bearing mount
    translate([CRANK_X, CRANK_Y, BASE_THICK])
    bearing_mount();

    // Motor mount
    translate([CRANK_X, CRANK_Y + 30, BASE_THICK])
    motor_mount();

    // Motor (reference)
    translate([CRANK_X, CRANK_Y + 35, CRANK_Z])
    rotate([-90, 0, 0])
    motor_reference();

    // Crank disc (rotating with theta)
    translate([CRANK_X, CRANK_Y, CRANK_Z])
    rotate([90, 0, 0])
    rotate([0, 0, theta])
    crank_disc();

    // Crank pin
    translate([crank_pin_x, CRANK_Y - CRANK_DISC_THICK - 1, crank_pin_z])
    rotate([90, 0, 0])
    crank_pin();

    // Connecting rod
    translate([crank_pin_x, CRANK_Y - CRANK_DISC_THICK - ROD_THICK/2 - 2, crank_pin_z])
    rotate([90, 0, 0])
    rotate([0, 0, 180 - rod_angle])
    connecting_rod();

    // Slider carrier
    translate([slider_pos, SLIDER_Y, BASE_THICK + RAIL_HEIGHT])
    slider_carrier();

    // Slider pin
    translate([slider_pos, SLIDER_Y, BASE_THICK + RAIL_HEIGHT + SLIDER_HEIGHT - 3])
    slider_pin();
}

// Render assembly
slider_crank_assembly();

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("");
echo("═══════════════════════════════════════════════════════════════");
echo("  SLIDER-CRANK MECHANISM - ENGINEERING VERIFICATION");
echo("═══════════════════════════════════════════════════════════════");
echo("");

echo("CURRENT STATE:");
echo(str("  Theta: ", theta, "°"));
echo(str("  Slider X position: ", round(slider_pos*10)/10, "mm"));
echo(str("  Crank pin X: ", round(crank_pin_x*10)/10, "mm"));
echo(str("  Crank pin Z: ", round(crank_pin_z*10)/10, "mm"));
echo(str("  Rod angle: ", round(rod_angle*10)/10, "°"));
echo("");

echo("TRAVEL RANGE:");
slider_0 = SLIDER_X_OFFSET + slider_x(0);
slider_180 = SLIDER_X_OFFSET + slider_x(180);
echo(str("  At theta=0°:   slider X = ", round(slider_0*10)/10, "mm"));
echo(str("  At theta=180°: slider X = ", round(slider_180*10)/10, "mm"));
echo(str("  Stroke: ", round((slider_0 - slider_180)*10)/10, "mm"));
echo("");

echo("MECHANISM PARAMETERS:");
echo(str("  Crank radius: ", CRANK_RADIUS, "mm"));
echo(str("  Rod length: ", ROD_LENGTH, "mm"));
echo(str("  L/r ratio: ", ROD_LENGTH/CRANK_RADIUS, " (ideal: 2.5-4.0)"));
echo("");

echo("PIN & HOLE DIMENSIONS:");
echo(str("  Pin diameter: ", PIN_DIA, "mm"));
echo(str("  Pin hole diameter: ", PIN_HOLE_DIA, "mm (clearance: ", CLEARANCE_SLIDING, "mm)"));
echo(str("  Shaft diameter: ", SHAFT_DIA, "mm"));
echo(str("  Shaft hole diameter: ", SHAFT_HOLE_DIA, "mm (clearance: ", CLEARANCE_TIGHT, "mm)"));
echo("");

echo("ROD LENGTH VERIFICATION:");
for (test_theta = [0, 90, 180, 270]) {
    test_slider = SLIDER_X_OFFSET + slider_x(test_theta);
    test_crank_x = CRANK_X + CRANK_RADIUS * cos(test_theta);
    test_crank_z = CRANK_Z + CRANK_RADIUS * sin(test_theta);

    dx = test_crank_x - test_slider;
    dz = test_crank_z - SLIDER_Z;
    calc_rod = sqrt(dx*dx + dz*dz);

    status = (abs(calc_rod - ROD_LENGTH) < 0.5) ? "PASS" : "FAIL";
    echo(str("  theta=", test_theta, "°: rod length = ", round(calc_rod*10)/10, "mm [", status, "]"));
}

echo("");
echo("═══════════════════════════════════════════════════════════════");

// ============================================
// EXPORT INDIVIDUAL PARTS (uncomment to use)
// ============================================

// To export individual parts for printing:
// 1. Comment out slider_crank_assembly()
// 2. Uncomment ONE of these and render (F6), then export STL

// crank_disc();
// connecting_rod();
// slider_carrier();
// guide_rail();
// bearing_mount();
// motor_mount();
// base_plate();
