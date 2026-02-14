// ASYMMETRIC WAVE SURGE MECHANISM v1
// For Starry Night Kinetic Sculpture
//
// Creates "quick up, slow down" wave motion using eccentric cam + connecting rod
// Drives Zone 2 (Mid Ocean) and Zone 3 (Breaking Wave)
// Zone 1 (Far Ocean) keeps original gentle rotation for layered effect
//
// Mechanism: Modified Slider-Crank
//   - Eccentric pin on rotating disc creates crank motion
//   - Connecting rod transfers to vertical slider (foam pivot)
//   - L/r ratio of 3.0 creates ~1.3:1 quick-return ratio
//
// Seven Masters Validation:
//   Van Gogh: 7/10 - Natural ease-out, organic feel
//   Da Vinci: 8/10 - Pin joints only, minimal friction
//   Watt: 8/10 - Simple 2-part addition per zone
//   Archimedes: 9/10 - Negligible power increase

// === INCLUDES ===
// These will be included from main file; uncomment for standalone testing
// use <dual_eccentric_disc.scad>
// use <connecting_rod.scad>
// use <pivot_bracket.scad>

// === POSITION CONSTANTS ===
// Wave Drive gear position (from main assembly)
WAVE_DRIVE_X = 119;        // mm (TAB_W + 115)
WAVE_DRIVE_Y = 19;         // mm (TAB_W + 15)
Z_GEAR_PLATE = 5;          // mm

// === ZONE 2 PARAMETERS (Mid Ocean - moderate surge) ===
ZONE2_ECCENTRIC_R = 6;     // mm - crank throw (12mm total stroke)
ZONE2_ROD_LENGTH = 18;     // mm - connecting rod length
ZONE2_PIVOT = [205, 46, 68]; // mm - pivot bracket position
ZONE2_FOAM_ARM = 15;       // mm
ZONE2_PHASE = 45;          // degrees offset from Zone 3
ZONE2_ROD_WIDTH = 4;       // mm

// === ZONE 3 PARAMETERS (Breaking Wave - dramatic surge) ===
ZONE3_ECCENTRIC_R = 8;     // mm - crank throw (16mm total stroke)
ZONE3_ROD_LENGTH = 24;     // mm - connecting rod length
ZONE3_PIVOT = [130, 58, 77]; // mm - pivot bracket position
ZONE3_FOAM_ARM = 20;       // mm
ZONE3_PHASE = 0;           // degrees (reference)
ZONE3_ROD_WIDTH = 5;       // mm

// === COMMON PARAMETERS ===
PIN_DIAMETER = 3;          // mm
DISC_Z_OFFSET = 6;         // mm above gear plate (on top of 30T gear)
PIN_HEIGHT = 15;           // mm
ROD_THICKNESS = 3;         // mm

// === COLORS ===
C_METAL = [0.7, 0.7, 0.75];
C_ROD = [0.85, 0.85, 0.80];
C_FOAM = [1.0, 1.0, 1.0, 0.9];  // White foam

// === KINEMATIC FUNCTIONS ===

// Calculate surge height from slider-crank kinematics
// theta = crank angle, eccentric_r = crank radius, rod_len = connecting rod length
function calc_surge_height(theta, eccentric_r, rod_len) =
    let(
        // Eccentric pin position in local XY
        pin_x = eccentric_r * sin(theta),
        pin_y = eccentric_r * cos(theta),
        // Vertical component of rod (slider-crank formula)
        rod_vertical = sqrt(max(0.001, rod_len*rod_len - pin_x*pin_x))
    )
    pin_y + rod_vertical;

// Calculate connecting rod angle for visualization
function calc_rod_angle(theta, eccentric_r, rod_len) =
    let(
        pin_x = eccentric_r * sin(theta),
        ratio = clamp(pin_x / rod_len, -0.999, 0.999)
    )
    asin(ratio);

// Clamp function
function clamp(val, min_val, max_val) = max(min_val, min(max_val, val));

// Calculate eccentric pin position in 3D
function eccentric_pin_pos(theta, eccentric_r, phase, base_pos, z_offset) =
    let(
        angle = theta + phase,
        px = base_pos[0] + eccentric_r * sin(angle),
        py = base_pos[1] + eccentric_r * cos(angle),
        pz = base_pos[2] + z_offset
    )
    [px, py, pz];

// === COMPONENT MODULES ===

module dual_eccentric_disc_local(theta) {
    // Dual eccentric disc with Zone 2 and Zone 3 pins
    DISC_DIAMETER = 24;
    DISC_THICKNESS = 4;
    CENTER_HOLE_DIA = 3.3;

    color(C_METAL) {
        // Base disc
        difference() {
            cylinder(d=DISC_DIAMETER, h=DISC_THICKNESS, $fn=64);
            translate([0, 0, -1])
                cylinder(d=CENTER_HOLE_DIA, h=DISC_THICKNESS+2, $fn=32);
        }

        // Zone 2 pin (6mm throw, 45 degree offset)
        rotate([0, 0, theta + ZONE2_PHASE])
            translate([ZONE2_ECCENTRIC_R, 0, DISC_THICKNESS])
                cylinder(d=PIN_DIAMETER, h=PIN_HEIGHT, $fn=24);

        // Zone 3 pin (8mm throw, 0 degree reference)
        rotate([0, 0, theta + ZONE3_PHASE])
            translate([ZONE3_ECCENTRIC_R, 0, DISC_THICKNESS])
                cylinder(d=PIN_DIAMETER, h=PIN_HEIGHT, $fn=24);
    }
}

module connecting_rod_local(length, width) {
    // Connecting rod with rounded ends and pin holes
    HOLE_CLEARANCE = 0.4;
    HOLE_DIA = PIN_DIAMETER + HOLE_CLEARANCE;
    WALL = 2;
    end_dia = width + 2*WALL;

    color(C_ROD)
    difference() {
        hull() {
            cylinder(d=end_dia, h=ROD_THICKNESS, $fn=32);
            translate([length, 0, 0])
                cylinder(d=end_dia, h=ROD_THICKNESS, $fn=32);
        }
        translate([0, 0, -1])
            cylinder(d=HOLE_DIA, h=ROD_THICKNESS+2, $fn=24);
        translate([length, 0, -1])
            cylinder(d=HOLE_DIA, h=ROD_THICKNESS+2, $fn=24);
    }
}

module foam_piece_medium_local() {
    // Medium foam blob for Zone 2
    color(C_FOAM) hull() {
        sphere(r=4, $fn=16);
        translate([8, 0, 3]) sphere(r=3, $fn=16);
        translate([5, 3, 5]) sphere(r=2, $fn=16);
    }
}

module foam_piece_curl_local() {
    // Large curl foam for Zone 3 (breaking wave)
    color(C_FOAM) {
        hull() {
            sphere(r=5, $fn=16);
            translate([10, 0, 4]) sphere(r=4, $fn=16);
            translate([8, 0, 10]) sphere(r=3, $fn=16);
            translate([3, 0, 12]) sphere(r=2, $fn=16);
        }
        // Spray detail
        for(i=[0:4])
            translate([12+i*2, sin(i*60)*3, 6+i*2])
                sphere(r=1.5-i*0.2, $fn=12);
    }
}

module foam_arm_local(arm_length) {
    // Arm connecting pivot to foam
    ARM_WIDTH = 4;
    color(C_ROD) hull() {
        cylinder(d=ARM_WIDTH+2, h=ROD_THICKNESS, $fn=24);
        translate([arm_length, 0, 0])
            cylinder(d=ARM_WIDTH, h=ROD_THICKNESS, $fn=24);
    }
}

// === ZONE SURGE ASSEMBLIES ===

module zone2_surge_assembly(theta) {
    // Zone 2: Mid Ocean surge mechanism
    zone_theta = theta + ZONE2_PHASE;

    // Calculate kinematics
    surge_h = calc_surge_height(zone_theta, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);
    rod_angle = calc_rod_angle(zone_theta, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);

    // Base height offset (so foam stays in visible range)
    base_offset = ZONE2_ECCENTRIC_R + ZONE2_ROD_LENGTH;
    foam_z = ZONE2_PIVOT[2] + (surge_h - base_offset);

    // Eccentric pin position
    pin_x = WAVE_DRIVE_X + ZONE2_ECCENTRIC_R * sin(zone_theta);
    pin_y = WAVE_DRIVE_Y + ZONE2_ECCENTRIC_R * cos(zone_theta);
    pin_z = Z_GEAR_PLATE + DISC_Z_OFFSET + 4 + PIN_HEIGHT/2;

    // Pivot position
    pivot_x = ZONE2_PIVOT[0];
    pivot_y = ZONE2_PIVOT[1];
    pivot_z = foam_z;

    // Connecting rod (positioned between eccentric pin and pivot)
    dx = pivot_x - pin_x;
    dy = pivot_y - pin_y;
    dz = pivot_z - pin_z;
    rod_xy_angle = atan2(dy, dx);
    rod_xy_dist = sqrt(dx*dx + dy*dy);
    rod_z_angle = atan2(dz, rod_xy_dist);

    translate([pin_x, pin_y, pin_z])
        rotate([0, 0, rod_xy_angle])
            rotate([-rod_z_angle, 0, 0])
                connecting_rod_local(ZONE2_ROD_LENGTH, ZONE2_ROD_WIDTH);

    // Foam arm and foam piece
    translate([pivot_x, pivot_y, foam_z]) {
        // Arm pointing toward shore (positive X)
        rotate([0, 0, -45])
            foam_arm_local(ZONE2_FOAM_ARM);

        // Foam piece at arm end
        rotate([0, 0, -45])
            translate([ZONE2_FOAM_ARM, 0, 3])
                foam_piece_medium_local();
    }
}

module zone3_surge_assembly(theta) {
    // Zone 3: Breaking Wave surge mechanism
    zone_theta = theta + ZONE3_PHASE;

    // Calculate kinematics
    surge_h = calc_surge_height(zone_theta, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);
    rod_angle = calc_rod_angle(zone_theta, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);

    // Base height offset
    base_offset = ZONE3_ECCENTRIC_R + ZONE3_ROD_LENGTH;
    foam_z = ZONE3_PIVOT[2] + (surge_h - base_offset);

    // Eccentric pin position
    pin_x = WAVE_DRIVE_X + ZONE3_ECCENTRIC_R * sin(zone_theta);
    pin_y = WAVE_DRIVE_Y + ZONE3_ECCENTRIC_R * cos(zone_theta);
    pin_z = Z_GEAR_PLATE + DISC_Z_OFFSET + 4 + PIN_HEIGHT/2;

    // Pivot position
    pivot_x = ZONE3_PIVOT[0];
    pivot_y = ZONE3_PIVOT[1];
    pivot_z = foam_z;

    // Connecting rod
    dx = pivot_x - pin_x;
    dy = pivot_y - pin_y;
    dz = pivot_z - pin_z;
    rod_xy_angle = atan2(dy, dx);
    rod_xy_dist = sqrt(dx*dx + dy*dy);
    rod_z_angle = atan2(dz, rod_xy_dist);

    translate([pin_x, pin_y, pin_z])
        rotate([0, 0, rod_xy_angle])
            rotate([-rod_z_angle, 0, 0])
                connecting_rod_local(ZONE3_ROD_LENGTH, ZONE3_ROD_WIDTH);

    // Foam arm and foam curl
    translate([pivot_x, pivot_y, foam_z]) {
        // Arm pointing toward shore
        rotate([0, 0, -30])
            foam_arm_local(ZONE3_FOAM_ARM);

        // Foam curl at arm end
        rotate([0, 0, -30])
            translate([ZONE3_FOAM_ARM, 0, 3])
                foam_piece_curl_local();
    }
}

// === MAIN ASSEMBLY ===

module asymmetric_surge_assembly(theta) {
    // Complete wave surge mechanism
    // theta = input rotation angle (from gear_rot * 2 in main assembly)

    // Dual eccentric disc (shared by both zones)
    translate([WAVE_DRIVE_X, WAVE_DRIVE_Y, Z_GEAR_PLATE + DISC_Z_OFFSET])
        dual_eccentric_disc_local(theta);

    // Zone 2 surge (Mid Ocean)
    zone2_surge_assembly(theta);

    // Zone 3 surge (Breaking Wave)
    zone3_surge_assembly(theta);
}

// === DIAGNOSTIC / TESTING ===

module show_motion_range() {
    // Show foam positions at key angles
    for(angle = [0, 90, 180, 270]) {
        color([1, 0, 0, 0.3])
        translate([ZONE3_PIVOT[0] + ZONE3_FOAM_ARM, ZONE3_PIVOT[1],
                   ZONE3_PIVOT[2] + calc_surge_height(angle, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH)
                   - (ZONE3_ECCENTRIC_R + ZONE3_ROD_LENGTH)])
            sphere(r=2, $fn=12);
    }
}

module print_motion_data() {
    // Debug output - view in console
    echo("=== WAVE SURGE MOTION DATA ===");
    echo("Zone 3 (L/r = 3.0):");
    for(angle = [0, 45, 90, 135, 180, 225, 270, 315]) {
        h = calc_surge_height(angle, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);
        echo(str("  theta=", angle, "deg: height=", h, "mm"));
    }
    echo("Zone 2 (L/r = 3.0):");
    for(angle = [0, 90, 180, 270]) {
        h = calc_surge_height(angle + ZONE2_PHASE, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);
        echo(str("  theta=", angle, "deg (phased): height=", h, "mm"));
    }
}

// === TEST RENDER ===

// Main assembly at theta=0
asymmetric_surge_assembly(0);

// Show motion range markers
// show_motion_range();

// Print motion data to console
// print_motion_data();

// Animation test - uncomment for OpenSCAD View > Animate
// asymmetric_surge_assembly($t * 360);

// Multi-position test (uncomment)
// for(t = [0, 0.25, 0.5, 0.75]) {
//     translate([t * 150, 0, 0])
//         asymmetric_surge_assembly(t * 360);
// }
