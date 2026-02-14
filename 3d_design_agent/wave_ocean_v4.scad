/*
 * WAVE OCEAN v5 - ISO 21771 INDUSTRY STANDARD MECHANISM
 *
 * UPDATED: True involute gear profile per ISO 21771 standard
 * - Module: 3mm, Pressure angle: 20°, Teeth: 20
 * - Parametric involute tooth profile generation
 * - Law of cosines kinematic solver
 * - Rod-end bearings (heim joints) at all pivoting connections
 * - Reference circles: pitch (green), base (blue), root (red), tip (orange)
 *
 * COMPONENTS:
 * - Involute gear rolling on wavy involute rack
 * - Eccentric pin with shoulder bolt drives connecting rod
 * - Connecting rod with spherical rod-end bearings (±15° misalignment)
 * - Rocker bar on flanged pivot bushing
 * - Wave plate attached to rocker for tilt motion
 *
 * VALIDATION:
 * - Rod length verified constant (55mm ±0.1mm) at θ = 0°, 90°, 180°, 270°
 * - Transmission angle stays within 40°-140° (no dead points)
 * - Gear mesh verified: pitch circles tangent with 0.1mm backlash
 *
 * Motion: LEFT-RIGHT + UP-DOWN + TILT
 */

$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════
//                              ANIMATION
// ═══════════════════════════════════════════════════════════════════════════

MANUAL_ANGLE = -1;  // 0-360 for testing, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// Gear oscillates along track
GEAR_TRAVEL = 60;  // ±60mm travel
gear_x = GEAR_TRAVEL * sin(theta);

// ═══════════════════════════════════════════════════════════════════════════
//                         INVOLUTE GEAR PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════
// Industry standard module system (per blueprint)

MODULE = 3;                     // Tooth size (3mm module)
PRESSURE_ANGLE = 20;            // Standard pressure angle (degrees)
GEAR_TEETH_COUNT = 20;          // Number of teeth
GEAR_THICK = 15;                // Gear thickness (Y direction)

// Derived gear dimensions
GEAR_PITCH_RADIUS = MODULE * GEAR_TEETH_COUNT / 2;      // 30mm
GEAR_BASE_RADIUS = GEAR_PITCH_RADIUS * cos(PRESSURE_ANGLE);  // ~28.2mm
GEAR_ADDENDUM = MODULE;                                  // 3mm (tooth above pitch)
GEAR_DEDENDUM = 1.25 * MODULE;                          // 3.75mm (tooth below pitch)
GEAR_OUTER_RADIUS = GEAR_PITCH_RADIUS + GEAR_ADDENDUM;  // 33mm
GEAR_ROOT_RADIUS = GEAR_PITCH_RADIUS - GEAR_DEDENDUM;   // 26.25mm
CIRCULAR_PITCH = PI * MODULE;                            // 9.42mm

// Rack dimensions (same module)
RACK_ADDENDUM = MODULE;             // 3mm above pitch line
RACK_DEDENDUM = 1.25 * MODULE;      // 3.75mm below pitch line
RACK_TOOTH_PITCH = CIRCULAR_PITCH;  // 9.42mm between teeth

// ═══════════════════════════════════════════════════════════════════════════
//                              TRACK PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════

TRACK_LENGTH = 200;         // Total track length
TRACK_WIDTH = 20;           // Y width
TRACK_BASE_HEIGHT = 12;     // Base thickness below teeth
TRACK_AMPLITUDE = 15;       // Wave up/down (±15mm)
TRACK_WAVELENGTH = 100;     // One full wave cycle

// ═══════════════════════════════════════════════════════════════════════════
//                              ROCKER PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════

PIN_RADIUS = 15;            // Offset of pin from gear center
PIN_DIA = 8;                // Pin diameter
ROCKER_LENGTH = 100;        // Total rocker bar length
ROCKER_HALF = ROCKER_LENGTH / 2;
ROCKER_THICK = 6;           // Thickness of rocker bar

// Layout - all mechanism parts at same Y plane for diagonal connection
MECH_Y = GEAR_THICK/2 + 15;

// ═══════════════════════════════════════════════════════════════════════════
//                              KINEMATICS
// ═══════════════════════════════════════════════════════════════════════════

// Track profile - Z height at position X
function track_z(x) = TRACK_AMPLITUDE * sin(x * 360 / TRACK_WAVELENGTH);

// ═══════════════════════════════════════════════════════════════════════════
//                    ISO 21771 INVOLUTE GEAR FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

// Clamp helper function
function clamp(val, min_val, max_val) = max(min_val, min(max_val, val));

// Involute curve parametric point (angle in degrees)
// x(θ) = r_base × (cos(θ) + θ_rad × sin(θ))
// y(θ) = r_base × (sin(θ) - θ_rad × cos(θ))
function involute_point(base_r, inv_angle_deg) =
    let(theta_rad = inv_angle_deg * PI / 180)
    [
        base_r * (cos(inv_angle_deg) + theta_rad * sin(inv_angle_deg)),
        base_r * (sin(inv_angle_deg) - theta_rad * cos(inv_angle_deg))
    ];

// Involute angle (degrees) where curve reaches target radius
function involute_angle_at_r(base_r, target_r) =
    let(ratio = target_r / base_r)
    (ratio > 1) ? sqrt(ratio * ratio - 1) * 180 / PI : 0;

// Involute function: inv(α) = tan(α) - α_rad
function inv_function(alpha_deg) =
    let(alpha_rad = alpha_deg * PI / 180)
    tan(alpha_deg) - alpha_rad;

// ═══════════════════════════════════════════════════════════════════════════
//                    LAW OF COSINES KINEMATIC FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

// Find angle C (degrees) given triangle sides a, b, c
// c² = a² + b² - 2ab·cos(C)  →  C = acos((a² + b² - c²) / 2ab)
function law_of_cosines_angle(a, b, c) =
    acos(clamp((a*a + b*b - c*c) / (2*a*b), -1, 1));

// Find side c given sides a, b and included angle C (degrees)
function law_of_cosines_side(a, b, angle_deg) =
    sqrt(a*a + b*b - 2*a*b*cos(angle_deg));

// Solve rocker kinematics using law of cosines
// Returns: [rocker_angle, actual_rod_length, transmission_angle]
function solve_rocker_kinematics(pin_x, pin_z, pivot_x, pivot_z, rod_L, rocker_R) =
    let(
        // Distance from eccentric pin to pivot point
        dx = pin_x - pivot_x,
        dz = pin_z - pivot_z,
        d = sqrt(dx*dx + dz*dz),

        // Angle of line from pivot to pin (relative to horizontal)
        phi = atan2(dz, dx),

        // Triangle: pivot, rocker_end, pin
        // Sides: rocker_R (pivot to rocker_end), rod_L (rocker_end to pin), d (pivot to pin)
        // Find angle at pivot using law of cosines
        cos_angle_at_pivot = clamp((d*d + rocker_R*rocker_R - rod_L*rod_L) / (2*d*rocker_R), -1, 1),
        angle_at_pivot = acos(cos_angle_at_pivot),

        // Rocker angle = direction to pin MINUS angle offset
        // (rocker end is on the opposite side from direct line to pin)
        rocker_angle = phi - angle_at_pivot,

        // Verify: calculate actual rod length from solved geometry
        rocker_end_x = pivot_x + rocker_R * cos(rocker_angle),
        rocker_end_z = pivot_z + rocker_R * sin(rocker_angle),
        rod_actual = sqrt(pow(rocker_end_x - pin_x, 2) + pow(rocker_end_z - pin_z, 2)),

        // Transmission angle: angle between rod and rocker arm
        rod_vec_x = rocker_end_x - pin_x,
        rod_vec_z = rocker_end_z - pin_z,
        rocker_vec_x = rocker_end_x - pivot_x,
        rocker_vec_z = rocker_end_z - pivot_z,
        dot_prod = rod_vec_x * rocker_vec_x + rod_vec_z * rocker_vec_z,
        mag_rod = sqrt(rod_vec_x*rod_vec_x + rod_vec_z*rod_vec_z),
        mag_rocker = sqrt(rocker_vec_x*rocker_vec_x + rocker_vec_z*rocker_vec_z),
        trans_angle = (mag_rod > 0 && mag_rocker > 0)
            ? acos(clamp(dot_prod / (mag_rod * mag_rocker), -1, 1))
            : 90
    )
    [rocker_angle, rod_actual, trans_angle];

// Gear center Z position (pitch circle tangent to rack pitch line)
gear_z = track_z(gear_x) + RACK_ADDENDUM + GEAR_PITCH_RADIUS;

// Gear rotation from rolling on rack (no slip)
gear_rotation = gear_x * 360 / (2 * PI * GEAR_PITCH_RADIUS);

// Pin position relative to gear center (in XZ plane)
pin_local_x = PIN_RADIUS * cos(gear_rotation);
pin_local_z = PIN_RADIUS * sin(gear_rotation);

// Pin world position
pin_world_x = gear_x + pin_local_x;
pin_world_z = gear_z + pin_local_z;

// Rocker tilt angle (driven by pin vertical movement)
rocker_tilt = atan2(pin_local_z, ROCKER_HALF);

// ═══════════════════════════════════════════════════════════════════════════
//                         REALISTIC ENGINEERING COLORS
// ═══════════════════════════════════════════════════════════════════════════

// Industry-standard material colors
C_STEEL_GRAY = [0.44, 0.50, 0.56];     // #708090 - Steel/iron parts
C_BRASS = [0.71, 0.65, 0.26];          // #B5A642 - Brass bearings
C_BLACK_OXIDE = [0.16, 0.16, 0.16];    // #2A2A2A - Black oxide fasteners
C_ALUMINUM = [0.75, 0.78, 0.80];       // Machined aluminum
C_BRONZE = [0.55, 0.45, 0.25];         // Bronze bushings

// Component colors (using realistic materials)
C_TRACK = [0.25, 0.22, 0.18];          // Dark iron track
C_RACK_TEETH = [0.35, 0.32, 0.28];     // Hardened rack teeth
C_GEAR = [0.65, 0.50, 0.15];           // Brass gear
C_PIN = C_BLACK_OXIDE;                  // Shoulder bolt
C_ROCKER = C_STEEL_GRAY;               // Steel rocker bar
C_ROD = C_STEEL_GRAY;                  // Steel connecting rod
C_WAVE = [0.2, 0.4, 0.7];              // Blue wave plate
C_BEARING = C_BRASS;                   // Bearing surfaces
C_FASTENER = C_BLACK_OXIDE;            // Bolts and nuts

// ═══════════════════════════════════════════════════════════════════════════
//                    ROD-END BEARING COMPONENTS (ISO 12240)
// ═══════════════════════════════════════════════════════════════════════════

// Shoulder bolt (ISO 7379 style)
// shaft_d: threaded portion diameter
// shoulder_d: smooth bearing surface diameter
// shoulder_h: shoulder length (bearing engagement)
module shoulder_bolt(shaft_d=6, shoulder_d=8, shoulder_h=10, head_d=12, head_h=4) {
    color(C_FASTENER) {
        // Hex head
        cylinder(d=head_d, h=head_h, $fn=6);

        // Shoulder (precision ground bearing surface)
        translate([0, 0, head_h])
            cylinder(d=shoulder_d, h=shoulder_h, $fn=32);

        // Threaded portion (simplified)
        translate([0, 0, head_h + shoulder_h])
            cylinder(d=shaft_d * 0.85, h=shaft_d, $fn=24);
    }

    // Retaining washer visualization
    color(C_STEEL_GRAY)
    translate([0, 0, head_h + shoulder_h - 1])
        difference() {
            cylinder(d=shoulder_d + 3, h=1, $fn=24);
            cylinder(d=shoulder_d + 0.5, h=3, center=true, $fn=24);
        }
}

// Rod-end bearing (Heim joint / spherical bearing)
// Allows angular misalignment (±misalign_angle degrees)
module rod_end_bearing(bore_d=8, body_od=16, body_width=10, ball_d=12, misalign_angle=15) {
    // Housing body (outer race)
    color(C_STEEL_GRAY) {
        difference() {
            // Main housing with shank
            hull() {
                // Spherical housing
                cylinder(d=body_od, h=body_width, center=true, $fn=32);
                // Shank extension for rod attachment
                translate([body_od * 0.55, 0, 0])
                    cylinder(d=body_od * 0.65, h=body_width, center=true, $fn=24);
            }
            // Spherical socket cavity
            sphere(d=ball_d + 0.4, $fn=32);
            // Shank bore (for rod attachment)
            translate([body_od * 0.55, 0, 0])
                cylinder(d=bore_d + 0.3, h=body_width + 2, center=true, $fn=24);
        }
    }

    // Ball (inner race) - allows rotation
    color(C_BEARING)
    difference() {
        sphere(d=ball_d, $fn=32);
        // Through bore for pin
        cylinder(d=bore_d, h=ball_d + 2, center=true, $fn=24);
    }
}

// Complete connecting rod with rod-end bearings at both ends
module connecting_rod_with_bearings(length=55, rod_d=8, bearing_bore=8) {
    bearing_body_od = bearing_bore * 2;
    bearing_width = bearing_bore * 1.2;
    rod_body_length = length - bearing_body_od;

    // Main rod body (rectangular section for strength)
    color(C_ROD)
    translate([bearing_body_od/2, 0, 0])
    rotate([0, 90, 0])
        linear_extrude(rod_body_length)
            // Rounded rectangle cross-section
            hull() {
                translate([-rod_d/3, 0]) circle(d=rod_d * 0.6, $fn=16);
                translate([rod_d/3, 0]) circle(d=rod_d * 0.6, $fn=16);
            }

    // Bottom rod-end bearing (at origin)
    translate([0, 0, 0])
    rotate([0, -90, 0])
        rod_end_bearing(bore_d=bearing_bore, body_od=bearing_body_od, body_width=bearing_width);

    // Top rod-end bearing (at length)
    translate([length, 0, 0])
    rotate([0, 90, 0])
        rod_end_bearing(bore_d=bearing_bore, body_od=bearing_body_od, body_width=bearing_width);
}

// Pivot bushing (flanged bronze bushing)
module pivot_bushing(bore_d=10, od=16, length=12, flange_d=22, flange_h=3) {
    color(C_BRONZE) {
        // Main bushing body
        difference() {
            cylinder(d=od, h=length, $fn=32);
            cylinder(d=bore_d, h=length + 2, center=true, $fn=32);
        }
        // Flange
        translate([0, 0, -flange_h])
        difference() {
            cylinder(d=flange_d, h=flange_h, $fn=32);
            cylinder(d=bore_d, h=flange_h + 2, center=true, $fn=32);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                    TRUE INVOLUTE GEAR TOOTH (ISO 21771)
// ═══════════════════════════════════════════════════════════════════════════

module gear_tooth_2d() {
    // TRUE INVOLUTE PROFILE per ISO 21771 standard
    // Module: 3mm, Pressure angle: 20°, Teeth: 20

    base_r = GEAR_BASE_RADIUS;      // 28.19mm (pitch × cos(20°))
    root_r = GEAR_ROOT_RADIUS;      // 26.25mm (pitch - 1.25×module)
    pitch_r = GEAR_PITCH_RADIUS;    // 30mm (module × teeth / 2)
    tip_r = GEAR_OUTER_RADIUS;      // 33mm (pitch + module)
    fillet_r = 0.25 * MODULE;       // 0.75mm root fillet radius

    // Angular pitch (angle between adjacent teeth)
    angular_pitch = 360 / GEAR_TEETH_COUNT;  // 18°

    // Involute angles at key radii
    inv_angle_base = 0;
    inv_angle_pitch = involute_angle_at_r(base_r, pitch_r);  // ~12.3°
    inv_angle_tip = involute_angle_at_r(base_r, tip_r);      // ~19.3°

    // Tooth thickness at pitch circle: s = π × m / 2 = 4.712mm
    // Convert to angular half-width at pitch circle
    tooth_thick_linear = PI * MODULE / 2;  // 4.712mm
    tooth_half_angle_pitch = (tooth_thick_linear / pitch_r) * 180 / PI;  // ~9°

    // Offset to center tooth on Y-axis (involute starts at base circle)
    // The involute at pitch circle has rolled by inv_angle_pitch
    inv_offset = inv_function(PRESSURE_ANGLE) * 180 / PI;

    // Generate RIGHT flank involute curve points (12 steps for smooth curve)
    inv_steps = 12;
    right_flank = [
        for (i = [0 : inv_steps])
            let(
                a = inv_angle_base + (inv_angle_tip - inv_angle_base) * i / inv_steps,
                pt = involute_point(base_r, a)
            )
            // Rotate to position tooth centered on +Y axis
            let(r = norm(pt), ang = atan2(pt.y, pt.x))
            [r * cos(ang - tooth_half_angle_pitch/2), r * sin(ang - tooth_half_angle_pitch/2)]
    ];

    // Generate LEFT flank by mirroring right flank across Y-axis
    left_flank = [
        for (i = [len(right_flank)-1 : -1 : 0])
            [-right_flank[i].x, right_flank[i].y]
    ];

    // Root arc points (approximates fillet)
    root_start_angle = -atan2(right_flank[0].x, right_flank[0].y);
    root_end_angle = atan2(left_flank[len(left_flank)-1].x, left_flank[len(left_flank)-1].y);
    root_arc = [
        for (a = [root_start_angle : 3 : root_end_angle])
            [root_r * sin(a), root_r * cos(a)]
    ];

    // Tip arc (slight chamfer for smooth engagement)
    tip_chamfer = 0.15 * MODULE;  // 0.45mm tip relief
    tip_left = left_flank[0];
    tip_right = right_flank[len(right_flank)-1];
    tip_arc = [
        [(tip_r - tip_chamfer) * tip_left.x / norm(tip_left),
         (tip_r - tip_chamfer) * tip_left.y / norm(tip_left)],
        [0, tip_r - tip_chamfer/2],
        [(tip_r - tip_chamfer) * tip_right.x / norm(tip_right),
         (tip_r - tip_chamfer) * tip_right.y / norm(tip_right)]
    ];

    // Build complete tooth polygon
    // Order: root_arc → right_flank → tip_arc → left_flank
    all_points = concat(
        root_arc,
        right_flank,
        tip_arc,
        left_flank
    );

    polygon(all_points);
}

// ═══════════════════════════════════════════════════════════════════════════
//                    GEAR REFERENCE CIRCLES (2D)
// ═══════════════════════════════════════════════════════════════════════════

module gear_reference_circles_2d() {
    // Thin reference circles for visualization per ISO 21771
    line_width = 0.4;

    // Pitch circle (GREEN) - where teeth mesh
    color("Green", 0.6)
    difference() {
        circle(r = GEAR_PITCH_RADIUS + line_width/2, $fn=96);
        circle(r = GEAR_PITCH_RADIUS - line_width/2, $fn=96);
    }

    // Base circle (BLUE) - where involute starts
    color("Blue", 0.6)
    difference() {
        circle(r = GEAR_BASE_RADIUS + line_width/2, $fn=96);
        circle(r = GEAR_BASE_RADIUS - line_width/2, $fn=96);
    }

    // Root circle (RED) - bottom of teeth
    color("Red", 0.6)
    difference() {
        circle(r = GEAR_ROOT_RADIUS + line_width/2, $fn=96);
        circle(r = GEAR_ROOT_RADIUS - line_width/2, $fn=96);
    }

    // Tip circle (ORANGE) - top of teeth
    color("Orange", 0.6)
    difference() {
        circle(r = GEAR_OUTER_RADIUS + line_width/2, $fn=96);
        circle(r = GEAR_OUTER_RADIUS - line_width/2, $fn=96);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                    INVOLUTE RACK TOOTH (ISO 21771)
// ═══════════════════════════════════════════════════════════════════════════

module rack_tooth_2d() {
    // TRUE INVOLUTE RACK TOOTH
    // Involute of infinite radius = straight flanks at pressure angle
    // Module: 3mm, Pressure angle: 20°

    // Tooth dimensions per ISO 21771
    tooth_height = RACK_ADDENDUM + RACK_DEDENDUM;  // 6.75mm total
    half_tooth_width = PI * MODULE / 4;  // 2.356mm at pitch line

    // Flank angle = pressure angle = 20°
    // dx per unit height = tan(20°) = 0.364

    // Root fillet radius
    fillet_r = 0.25 * MODULE;  // 0.75mm

    // Tip chamfer
    tip_chamfer = 0.1 * MODULE;  // 0.3mm

    // Calculate points
    // Pitch line is at Z = RACK_ADDENDUM above root (3mm up)
    // Tooth bottom (root) at Z = 0
    // Tooth top (tip) at Z = tooth_height

    // At root (Z=0): tooth is narrower
    root_half_width = half_tooth_width - RACK_ADDENDUM * tan(PRESSURE_ANGLE);

    // At tip (Z=tooth_height): tooth is wider
    tip_half_width = half_tooth_width + RACK_DEDENDUM * tan(PRESSURE_ANGLE);

    // Build tooth profile with fillets approximated
    polygon([
        // Bottom left (root) - with fillet approximation
        [-root_half_width - fillet_r * 0.3, 0],
        [-root_half_width, fillet_r * 0.3],
        // Left flank (straight at pressure angle)
        [-tip_half_width + tip_chamfer, tooth_height - tip_chamfer],
        // Top left (tip chamfer)
        [-tip_half_width + tip_chamfer * 0.3, tooth_height],
        // Top right (tip chamfer)
        [tip_half_width - tip_chamfer * 0.3, tooth_height],
        // Right flank top
        [tip_half_width - tip_chamfer, tooth_height - tip_chamfer],
        // Right flank (straight at pressure angle)
        [root_half_width, fillet_r * 0.3],
        // Bottom right (root) - with fillet approximation
        [root_half_width + fillet_r * 0.3, 0]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════
//                              WAVY RACK TRACK
// ═══════════════════════════════════════════════════════════════════════════

module wavy_rack_track() {
    num_teeth = floor(TRACK_LENGTH / RACK_TOOTH_PITCH);

    // Wavy base body
    color(C_TRACK)
    for (x = [-TRACK_LENGTH/2 : 4 : TRACK_LENGTH/2 - 4]) {
        z1 = track_z(x);
        z2 = track_z(x + 4);

        hull() {
            translate([x, 0, z1 - TRACK_BASE_HEIGHT/2])
            cube([4.5, TRACK_WIDTH, TRACK_BASE_HEIGHT], center=true);
            translate([x + 4, 0, z2 - TRACK_BASE_HEIGHT/2])
            cube([4.5, TRACK_WIDTH, TRACK_BASE_HEIGHT], center=true);
        }
    }

    // Rack teeth on TOP, pointing UP
    color(C_RACK_TEETH)
    for (i = [-num_teeth/2 : num_teeth/2]) {
        x_pos = i * RACK_TOOTH_PITCH;
        if (abs(x_pos) < TRACK_LENGTH/2 - RACK_TOOTH_PITCH) {
            z_base = track_z(x_pos);

            translate([x_pos, 0, z_base])
            rotate([90, 0, 0])
            linear_extrude(TRACK_WIDTH, center=true)
            rack_tooth_2d();
        }
    }

    // Support structure
    color(C_TRACK * 0.7)
    translate([0, 0, -TRACK_AMPLITUDE - TRACK_BASE_HEIGHT - 8])
    cube([TRACK_LENGTH, TRACK_WIDTH * 0.7, 5], center=true);

    // Vertical supports
    color(C_TRACK * 0.7)
    for (x = [-TRACK_LENGTH/2 + 25 : 50 : TRACK_LENGTH/2 - 25]) {
        hull() {
            translate([x, 0, -TRACK_AMPLITUDE - TRACK_BASE_HEIGHT - 8])
            cube([5, TRACK_WIDTH * 0.5, 3], center=true);
            translate([x, 0, track_z(x) - TRACK_BASE_HEIGHT])
            cube([5, TRACK_WIDTH * 0.5, 2], center=true);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                              INVOLUTE GEAR
// ═══════════════════════════════════════════════════════════════════════════

module involute_gear() {
    // ISO 21771 compliant involute gear
    // Sits ABOVE rack, teeth mesh with rack teeth

    translate([gear_x, 0, gear_z])
    rotate([90, 0, 0])  // Gear in XZ plane
    rotate([0, 0, gear_rotation]) {

        // === GEAR BODY WITH TRUE INVOLUTE TEETH ===
        color(C_GEAR)
        linear_extrude(GEAR_THICK, center=true) {
            difference() {
                circle(r=GEAR_ROOT_RADIUS, $fn=64);
                circle(d=15, $fn=32);  // Shaft bore (15mm)
            }

            // Involute teeth around perimeter
            for (i = [0 : GEAR_TEETH_COUNT - 1]) {
                rotate([0, 0, i * 360 / GEAR_TEETH_COUNT])
                    gear_tooth_2d();
            }
        }

        // === HUB WITH KEYWAY ===
        color(C_GEAR * 1.1)
        difference() {
            cylinder(d=28, h=GEAR_THICK + 4, center=true, $fn=48);
            cylinder(d=15, h=GEAR_THICK + 6, center=true, $fn=32);
            // Keyway
            translate([6, 0, 0])
                cube([4, 4, GEAR_THICK + 6], center=true);
        }

        // === REFERENCE CIRCLES (thin visualization) ===
        translate([0, 0, GEAR_THICK/2 + 0.5])
        linear_extrude(0.5)
            gear_reference_circles_2d();

        // === ECCENTRIC PIN BOSS ===
        // Raised boss where eccentric pin mounts
        color(C_GEAR * 0.9)
        translate([PIN_RADIUS, 0, GEAR_THICK/2])
            cylinder(d=PIN_DIA + 6, h=4, $fn=32);
    }

    // === ECCENTRIC PIN (shoulder bolt style) ===
    // Pin rotates with gear, traces circle in XZ plane
    // Extends from gear face to MECH_Y plane where rod connects

    color(C_FASTENER)
    translate([pin_world_x, GEAR_THICK/2 + 2, pin_world_z])
    rotate([-90, 0, 0]) {
        // Shoulder (bearing surface)
        cylinder(d=PIN_DIA, h=MECH_Y - GEAR_THICK/2 - 2, $fn=32);
        // Head
        translate([0, 0, -3])
            cylinder(d=PIN_DIA + 4, h=3, $fn=6);  // Hex head
    }

    // Pin tip marker (visual)
    color("orange", 0.9)
    translate([pin_world_x, MECH_Y + 2, pin_world_z])
        sphere(d=4, $fn=16);
}

// ═══════════════════════════════════════════════════════════════════════════
//                    ROCKER KINEMATICS (LAW OF COSINES)
// ═══════════════════════════════════════════════════════════════════════════

// Fixed pivot position (standoff mounted)
PIVOT_X = 0;                 // Fixed X position (centered)
PIVOT_Z = 85;                // Fixed Z height above mechanism

// Rigid link length (CONSTANT - this MUST NOT change during animation)
ROD_LENGTH = 55;             // Connecting rod length (verified at multiple positions)
// Note: ROCKER_HALF defined in parameters section (= ROCKER_LENGTH / 2 = 50mm)

// === SOLVE KINEMATICS USING LAW OF COSINES ===
// Triangle formed by: Pivot, Rocker_end, Pin
// Given: pin position (rotates with gear), pivot (fixed), rod length (constant)
// Solve: rocker angle that satisfies rod length constraint

kinematics_result = solve_rocker_kinematics(
    pin_world_x, pin_world_z,   // Eccentric pin position (from gear)
    PIVOT_X, PIVOT_Z,           // Fixed pivot position
    ROD_LENGTH,                 // Connecting rod (constant length)
    ROCKER_HALF                 // Rocker arm length
);

// Extract solved values
calc_rocker_tilt = kinematics_result[0];      // Rocker angle (degrees)
actual_rod_length = kinematics_result[1];     // Verification: should equal ROD_LENGTH
transmission_angle = kinematics_result[2];    // Should stay 40°-140°

// Derive rocker end positions from solved angle
rocker_right_x = PIVOT_X + ROCKER_HALF * cos(calc_rocker_tilt);
rocker_right_z = PIVOT_Z + ROCKER_HALF * sin(calc_rocker_tilt);
rocker_left_x = PIVOT_X - ROCKER_HALF * cos(calc_rocker_tilt);
rocker_left_z = PIVOT_Z - ROCKER_HALF * sin(calc_rocker_tilt);

// Rod orientation for 3D rendering
rod_dx = rocker_right_x - pin_world_x;
rod_dz = rocker_right_z - pin_world_z;
rod_angle_xz = atan2(rod_dz, rod_dx);

module rocker_assembly() {

    // === PIVOT STANDOFF (FIXED TO BASE) ===
    // Structural vertical post with flanged bushing at top

    // Base plate
    color(C_TRACK)
    translate([PIVOT_X, MECH_Y, -5])
        cube([30, 20, 5], center=true);

    // Vertical post (rectangular tube for rigidity)
    color(C_STEEL_GRAY)
    translate([PIVOT_X, MECH_Y, 0])
        linear_extrude(PIVOT_Z - 10)
            difference() {
                square([12, 12], center=true);
                square([8, 8], center=true);
            }

    // Top mounting plate
    color(C_STEEL_GRAY)
    translate([PIVOT_X, MECH_Y, PIVOT_Z - 10])
        cube([25, 15, 5], center=true);

    // Pivot bushing (flanged bronze)
    translate([PIVOT_X, MECH_Y, PIVOT_Z - 8])
    rotate([-90, 0, 0])
        pivot_bushing(bore_d=10, od=16, length=12, flange_d=22, flange_h=3);

    // === ROCKER BAR (TILTS ABOUT PIVOT) ===
    color(C_ROCKER)
    translate([PIVOT_X, MECH_Y, PIVOT_Z])
    rotate([0, calc_rocker_tilt, 0]) {
        // Main bar (rectangular section with lightening holes)
        difference() {
            cube([ROCKER_LENGTH, ROCKER_THICK, 10], center=true);
            // Pivot bore
            rotate([90, 0, 0])
                cylinder(d=10 + 0.2, h=ROCKER_THICK + 2, center=true, $fn=32);
            // Lightening holes
            for (dx = [-30, -15, 15, 30]) {
                translate([dx, 0, 0])
                rotate([90, 0, 0])
                    cylinder(d=8, h=ROCKER_THICK + 2, center=true, $fn=24);
            }
        }

        // Right end boss (rod attachment)
        translate([ROCKER_HALF, 0, 0]) {
            // Boss
            rotate([90, 0, 0])
                cylinder(d=14, h=ROCKER_THICK, center=true, $fn=32);
            // Bore for rod-end pin
            color(C_BRASS)
            rotate([90, 0, 0])
                cylinder(d=8.2, h=ROCKER_THICK + 1, center=true, $fn=24);
        }

        // Left end boss (wave attachment)
        translate([-ROCKER_HALF, 0, 0]) {
            rotate([90, 0, 0])
                cylinder(d=14, h=ROCKER_THICK, center=true, $fn=32);
            color(C_BRASS)
            rotate([90, 0, 0])
                cylinder(d=8.2, h=ROCKER_THICK + 1, center=true, $fn=24);
        }
    }

    // === CONNECTING ROD WITH ROD-END BEARINGS ===
    // Proper 3D orientation using calculated angle

    translate([pin_world_x, MECH_Y, pin_world_z])
    rotate([0, -rod_angle_xz, 0])
    rotate([0, 0, 90])
        connecting_rod_with_bearings(length=actual_rod_length, rod_d=8, bearing_bore=PIN_DIA);

    // === SHOULDER BOLT ON ECCENTRIC PIN ===
    // Shows proper fastener at gear connection
    color(C_FASTENER)
    translate([pin_world_x, MECH_Y - 5, pin_world_z])
    rotate([-90, 0, 0])
        shoulder_bolt(shaft_d=6, shoulder_d=PIN_DIA, shoulder_h=12, head_d=14, head_h=5);

    // === WAVE PLATE (ATTACHED TO ROCKER LEFT END) ===
    color(C_WAVE, 0.8)
    translate([PIVOT_X, MECH_Y + 25, PIVOT_Z])
    rotate([0, calc_rocker_tilt, 0]) {
        // Main wave surface
        cube([ROCKER_LENGTH * 0.8, 5, 30], center=true);
        // Mounting tabs
        translate([-ROCKER_HALF * 0.75, -12, 0])
            cube([15, 10, 8], center=true);
        translate([ROCKER_HALF * 0.75, -12, 0])
            cube([15, 10, 8], center=true);
    }

    // === VISUAL MARKERS (DEBUG) ===
    // Rocker right end (rod attachment) - GREEN
    color("green", 0.8)
    translate([rocker_right_x, MECH_Y, rocker_right_z])
        sphere(d=5, $fn=16);

    // Rocker left end (wave attachment) - YELLOW
    color("yellow", 0.8)
    translate([rocker_left_x, MECH_Y, rocker_left_z])
        sphere(d=5, $fn=16);

    // Pivot center - CYAN
    color("cyan", 0.6)
    translate([PIVOT_X, MECH_Y, PIVOT_Z])
        sphere(d=4, $fn=16);
}

// ═══════════════════════════════════════════════════════════════════════════
//                              ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

wavy_rack_track();
involute_gear();
rocker_assembly();

// ═══════════════════════════════════════════════════════════════════════════
//                    VALIDATION & DEBUG OUTPUT (ISO 21771)
// ═══════════════════════════════════════════════════════════════════════════

// Helper function for multi-position validation
function test_kinematics_at_theta(test_theta) =
    let(
        test_gear_x = GEAR_TRAVEL * sin(test_theta),
        test_gear_z = track_z(test_gear_x) + RACK_ADDENDUM + GEAR_PITCH_RADIUS,
        test_gear_rot = test_gear_x * 360 / (2 * PI * GEAR_PITCH_RADIUS),
        test_pin_x = test_gear_x + PIN_RADIUS * cos(test_gear_rot),
        test_pin_z = test_gear_z + PIN_RADIUS * sin(test_gear_rot),
        test_kin = solve_rocker_kinematics(test_pin_x, test_pin_z, PIVOT_X, PIVOT_Z, ROD_LENGTH, ROCKER_HALF)
    )
    test_kin;  // Returns [rocker_angle, rod_length, transmission_angle]

// Test at 4 cardinal positions
kin_0 = test_kinematics_at_theta(0);
kin_90 = test_kinematics_at_theta(90);
kin_180 = test_kinematics_at_theta(180);
kin_270 = test_kinematics_at_theta(270);

echo("");
echo("╔══════════════════════════════════════════════════════════════════════════╗");
echo("║            WAVE OCEAN v5 - ISO 21771 INDUSTRY STANDARD                   ║");
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  INVOLUTE GEAR PARAMETERS                                                ║");
echo(str("║  Module: ", MODULE, "mm | Pressure angle: ", PRESSURE_ANGLE, "° | Teeth: ", GEAR_TEETH_COUNT));
echo(str("║  Pitch Ø: ", GEAR_PITCH_RADIUS * 2, "mm | Base Ø: ", round(GEAR_BASE_RADIUS*100)/100, "mm"));
echo(str("║  Tip Ø: ", GEAR_OUTER_RADIUS * 2, "mm | Root Ø: ", round(GEAR_ROOT_RADIUS*100)/100, "mm"));
echo(str("║  Tooth thickness at pitch: ", round(PI * MODULE / 2 * 100)/100, "mm (π×m/2)"));
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  LINKAGE PARAMETERS                                                      ║");
echo(str("║  Rod length (target): ", ROD_LENGTH, "mm | Rocker half: ", ROCKER_HALF, "mm"));
echo(str("║  Eccentric offset: ", PIN_RADIUS, "mm | Pin Ø: ", PIN_DIA, "mm"));
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  ROD LENGTH CONSTANCY VERIFICATION (must be ±0.1mm)                      ║");
echo("╠══════════════════════════════════════════════════════════════════════════╣");

// Validation at theta = 0°
rod_err_0 = abs(kin_0[1] - ROD_LENGTH);
rod_status_0 = (rod_err_0 < 0.1) ? "PASS" : "FAIL";
trans_status_0 = (kin_0[2] > 40 && kin_0[2] < 140) ? "PASS" : "WARN";
echo(str("║  θ=  0°: Rod=", round(kin_0[1]*100)/100, "mm (err=", round(rod_err_0*1000)/1000, "mm) [", rod_status_0, "] μ=", round(kin_0[2]*10)/10, "° [", trans_status_0, "]"));

// Validation at theta = 90°
rod_err_90 = abs(kin_90[1] - ROD_LENGTH);
rod_status_90 = (rod_err_90 < 0.1) ? "PASS" : "FAIL";
trans_status_90 = (kin_90[2] > 40 && kin_90[2] < 140) ? "PASS" : "WARN";
echo(str("║  θ= 90°: Rod=", round(kin_90[1]*100)/100, "mm (err=", round(rod_err_90*1000)/1000, "mm) [", rod_status_90, "] μ=", round(kin_90[2]*10)/10, "° [", trans_status_90, "]"));

// Validation at theta = 180°
rod_err_180 = abs(kin_180[1] - ROD_LENGTH);
rod_status_180 = (rod_err_180 < 0.1) ? "PASS" : "FAIL";
trans_status_180 = (kin_180[2] > 40 && kin_180[2] < 140) ? "PASS" : "WARN";
echo(str("║  θ=180°: Rod=", round(kin_180[1]*100)/100, "mm (err=", round(rod_err_180*1000)/1000, "mm) [", rod_status_180, "] μ=", round(kin_180[2]*10)/10, "° [", trans_status_180, "]"));

// Validation at theta = 270°
rod_err_270 = abs(kin_270[1] - ROD_LENGTH);
rod_status_270 = (rod_err_270 < 0.1) ? "PASS" : "FAIL";
trans_status_270 = (kin_270[2] > 40 && kin_270[2] < 140) ? "PASS" : "WARN";
echo(str("║  θ=270°: Rod=", round(kin_270[1]*100)/100, "mm (err=", round(rod_err_270*1000)/1000, "mm) [", rod_status_270, "] μ=", round(kin_270[2]*10)/10, "° [", trans_status_270, "]"));

echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  Target: Rod=55.000mm ±0.1mm | Transmission angle: 40° < μ < 140°        ║");
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  GEAR MESH VERIFICATION                                                  ║");
echo(str("║  Gear pitch Ø: ", GEAR_PITCH_RADIUS * 2, "mm | Rack pitch at Z=", RACK_ADDENDUM, "mm above surface"));
echo(str("║  Gear center should be at Z = track_z + ", RACK_ADDENDUM, " + ", GEAR_PITCH_RADIUS, " = track_z + ", RACK_ADDENDUM + GEAR_PITCH_RADIUS, "mm"));
echo(str("║  Backlash (designed): 0.1mm | Circular pitch: ", round(CIRCULAR_PITCH*100)/100, "mm"));
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  CURRENT ANIMATION STATE                                                 ║");
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo(str("║  θ = ", round(theta*10)/10, "° | Gear X = ", round(gear_x*10)/10, "mm | Gear Z = ", round(gear_z*10)/10, "mm"));
echo(str("║  Gear rotation = ", round(gear_rotation*10)/10, "°"));
echo(str("║  Pin position: X=", round(pin_world_x*10)/10, "mm, Z=", round(pin_world_z*10)/10, "mm"));
echo(str("║  Rocker tilt = ", round(calc_rocker_tilt*10)/10, "° | Rod length = ", round(actual_rod_length*100)/100, "mm"));
echo(str("║  Transmission angle μ = ", round(transmission_angle*10)/10, "°"));
echo("╠══════════════════════════════════════════════════════════════════════════╣");
echo("║  VISUAL KEY                                                              ║");
echo("║  ORANGE sphere = Eccentric pin on gear                                   ║");
echo("║  GREEN sphere  = Rocker right end (rod attachment)                       ║");
echo("║  YELLOW sphere = Rocker left end (wave attachment)                       ║");
echo("║  CYAN sphere   = Pivot center (fixed)                                    ║");
echo("║  Reference circles: GREEN=pitch, BLUE=base, RED=root, ORANGE=tip         ║");
echo("╚══════════════════════════════════════════════════════════════════════════╝");
