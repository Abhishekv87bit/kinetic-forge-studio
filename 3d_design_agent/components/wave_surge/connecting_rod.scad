// CONNECTING ROD MODULE
// For Starry Night Wave Surge Mechanism
// Parametric connecting rod for slider-crank motion
//
// Creates link between eccentric pin and pivot bracket
// Two variants: Zone 2 (18mm) and Zone 3 (24mm)
//
// FDM Tolerances (from research):
//   - Pin holes: 3.4mm for 3mm pins (0.4mm clearance)
//   - Wall around holes: 2mm minimum
//   - Rod thickness: 3mm (printable, strong)

// === PARAMETERS ===

// Zone 2 Rod (Mid Ocean - moderate surge)
ZONE2_ROD_LENGTH = 18;     // mm center-to-center
ZONE2_ROD_WIDTH = 4;       // mm (slightly smaller)

// Zone 3 Rod (Breaking Wave - dramatic surge)
ZONE3_ROD_LENGTH = 24;     // mm center-to-center
ZONE3_ROD_WIDTH = 5;       // mm (structural)

// Common parameters
ROD_THICKNESS = 3;         // mm
PIN_DIAMETER = 3;          // mm
HOLE_CLEARANCE = 0.4;      // mm (FDM tolerance)
HOLE_DIAMETER = PIN_DIAMETER + HOLE_CLEARANCE;  // 3.4mm
WALL_THICKNESS = 2;        // mm minimum around holes

// Colors
C_ROD = [0.85, 0.85, 0.80];  // Light gear color

// === MODULES ===

module connecting_rod(length, width) {
    // Parametric connecting rod with rounded ends
    // length = center-to-center distance
    // width = rod body width

    end_diameter = width + 2 * WALL_THICKNESS;  // Diameter at hole ends

    color(C_ROD)
    difference() {
        // Rod body with rounded ends
        hull() {
            // End 1 (eccentric pin end)
            cylinder(d=end_diameter, h=ROD_THICKNESS, $fn=32);

            // End 2 (pivot end)
            translate([length, 0, 0])
                cylinder(d=end_diameter, h=ROD_THICKNESS, $fn=32);
        }

        // Hole 1 (eccentric pin)
        translate([0, 0, -1])
            cylinder(d=HOLE_DIAMETER, h=ROD_THICKNESS+2, $fn=24);

        // Hole 2 (pivot)
        translate([length, 0, -1])
            cylinder(d=HOLE_DIAMETER, h=ROD_THICKNESS+2, $fn=24);
    }
}

// Zone-specific convenience modules
module zone2_connecting_rod() {
    connecting_rod(ZONE2_ROD_LENGTH, ZONE2_ROD_WIDTH);
}

module zone3_connecting_rod() {
    connecting_rod(ZONE3_ROD_LENGTH, ZONE3_ROD_WIDTH);
}

// Rod positioned in 3D space based on kinematics
module connecting_rod_positioned(length, width, eccentric_pos, pivot_pos) {
    // Calculate rod orientation from eccentric pin to pivot
    // eccentric_pos = [x, y, z] of eccentric pin center
    // pivot_pos = [x, y, z] of pivot center

    dx = pivot_pos[0] - eccentric_pos[0];
    dy = pivot_pos[1] - eccentric_pos[1];
    dz = pivot_pos[2] - eccentric_pos[2];

    // Calculate angles
    xy_angle = atan2(dy, dx);
    xy_dist = sqrt(dx*dx + dy*dy);
    z_angle = atan2(dz, xy_dist);

    translate(eccentric_pos)
        rotate([0, 0, xy_angle])
            rotate([z_angle, 0, 0])
                connecting_rod(length, width);
}

// === KINEMATIC HELPER FUNCTIONS ===

// Calculate vertical component of slider-crank position
// Returns height offset from base
function calc_slider_crank_height(theta, eccentric_r, rod_len) =
    let(
        pin_x = eccentric_r * sin(theta),
        pin_y = eccentric_r * cos(theta),
        // Vertical component considering rod length constraint
        rod_vertical = sqrt(max(0, rod_len*rod_len - pin_x*pin_x))
    )
    pin_y + rod_vertical;

// Calculate rod angle for animation
function calc_rod_swing_angle(theta, eccentric_r, rod_len) =
    let(
        pin_x = eccentric_r * sin(theta)
    )
    asin(clamp(pin_x / rod_len, -1, 1));

// Clamp function for safety
function clamp(val, min_val, max_val) =
    max(min_val, min(max_val, val));

// === TEST RENDER ===

// Show both rod variants side by side
translate([0, 0, 0])
    zone2_connecting_rod();

translate([0, 15, 0])
    zone3_connecting_rod();

// Labels (for reference - remove in production)
// translate([9, -3, 0]) text("Zone 2: 18mm", size=2);
// translate([12, 12, 0]) text("Zone 3: 24mm", size=2);

// Animation test - rod swinging (uncomment)
// angle = sin($t * 360) * 20;  // +/-20 degree swing
// rotate([0, 0, angle])
//     zone3_connecting_rod();
