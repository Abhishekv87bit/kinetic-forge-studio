// ============================================================================
// OPENSCAD TEMPLATES AND PATTERNS
// For 3D Mechanical Design Agent
// ============================================================================
// This file contains reusable templates, modules, and best practices for
// creating parametric mechanical designs in OpenSCAD.
// ============================================================================

// ############################################################################
// SECTION 1: MASTER FILE STRUCTURE TEMPLATE
// ############################################################################
// Copy this template as the starting point for any new project.
// Customize parameters and modules as needed.
// ############################################################################

/*
// ============================================
// PROJECT: [Project Name]
// VERSION: V[XX]
// DESCRIPTION: [Brief description]
// LAST MODIFIED: [Date]
// ============================================

// === PARAMETERS (user adjustable) ===
// These are the primary dimensions that define the overall size
WIDTH = 350;        // Overall width in mm
HEIGHT = 275;       // Overall height in mm
DEPTH = 100;        // Overall depth in mm
FRAME_WIDTH = 10;   // Frame/border thickness

// Animation controls - toggle features on/off
ANIMATE = true;             // Enable/disable animation
SHOW_MOTOR = true;          // Show/hide motor assembly
TRANSPARENT_ENCLOSURE = false; // Make enclosure transparent for debugging

// === DERIVED DIMENSIONS ===
// Calculate dependent values from parameters - NEVER hardcode these
INNER_WIDTH = WIDTH - FRAME_WIDTH * 2;
INNER_HEIGHT = HEIGHT - FRAME_WIDTH * 2;

// === ANIMATION VARIABLES ===
// $t is OpenSCAD's built-in animation parameter (0 to 1)
t = $t;  // 0 to 1 animation parameter
motor_angle = t * 360;  // Full rotation per cycle

// === COLOR PALETTE ===
// Define all colors in one place for easy theming
C_FRAME = "Gold";
C_WAVE = ["#061a3a", "#0a2a5e", "#0e3a82"];  // Array for multiple layers
C_MOTOR = "DarkGray";
C_GEAR = "Silver";

// === GEAR PARAMETERS ===
// CALCULATED VALUES - DO NOT ESTIMATE OR EYEBALL
// Gear geometry follows strict mathematical relationships
MODULE = 1.5;           // Gear module (tooth size)
MOTOR_TEETH = 10;       // Number of teeth on motor pinion
MASTER_TEETH = 60;      // Number of teeth on driven gear

// Derived gear dimensions - ALWAYS calculate, never estimate
MOTOR_RADIUS = MOTOR_TEETH * MODULE / 2;  // 7.5mm
MASTER_RADIUS = MASTER_TEETH * MODULE / 2; // 45mm
CENTER_DISTANCE = (MOTOR_TEETH + MASTER_TEETH) * MODULE / 2; // 52.5mm EXACT

// === MODULES (building blocks) ===

module gear(teeth, module_val, thickness) {
    // Simplified gear representation
    // For visualization - use MCAD/involute_gears.scad for accurate teeth
    cylinder(h=thickness, r=teeth*module_val/2, $fn=teeth*2);
}

module four_bar_linkage(crank_angle) {
    // Four-bar linkage implementation
    // Uses calculated positions, not visual placement
    // See Section 3 for complete implementation
}

// === COMPONENT MODULES ===

module enclosure() {
    // 3 walls, front open for viewing
    // Implementation depends on project requirements
}

module motor_assembly() {
    // Motor body + pinion gear
    // Position at calculated location
}

module wave_layer(index, phase_offset) {
    // Single wave layer with animation
    // Uses phase offset for staggered motion
}

// === ASSEMBLY ===

module main_assembly() {
    enclosure();
    if (SHOW_MOTOR) motor_assembly();
    // ... other components
}

// === RENDER ===
main_assembly();
*/


// ############################################################################
// SECTION 2: GEAR CALCULATION MODULE
// ############################################################################
// CRITICAL: NEVER place gears visually - ALWAYS calculate positions
// Gear mesh requires precise center distance for proper engagement
// ############################################################################

// Gear module value (tooth size parameter)
// Common values: 0.5, 0.8, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0
DEFAULT_MODULE = 1.5;

// Simple gear visualization (for preview/layout)
// For production, use MCAD library's involute gears
module simple_gear(teeth, module_val, thickness, center_hole=0) {
    difference() {
        union() {
            // Main gear body
            cylinder(h=thickness, r=teeth*module_val/2, $fn=max(teeth*4, 36));
            // Hub
            cylinder(h=thickness*1.2, r=teeth*module_val/6, $fn=24);
        }
        // Center hole
        if (center_hole > 0) {
            translate([0, 0, -1])
                cylinder(h=thickness*1.5, r=center_hole/2, $fn=24);
        }
    }
}

// GEAR MESH CALCULATOR
// Calculates and places two meshing gears with correct center distance
module gear_pair(motor_teeth, driven_teeth, module_val, motor_pos,
                 motor_angle=0, thickness=5, motor_color="Silver",
                 driven_color="Gold") {

    // ===== CALCULATE EXACT POSITIONS =====
    // These formulas are from gear theory - DO NOT MODIFY
    motor_radius = motor_teeth * module_val / 2;
    driven_radius = driven_teeth * module_val / 2;
    center_distance = (motor_teeth + driven_teeth) * module_val / 2;

    // Gear ratio determines driven gear rotation
    gear_ratio = motor_teeth / driven_teeth;
    driven_angle = -motor_angle * gear_ratio;  // Negative for opposite rotation

    // ===== DEBUG OUTPUT =====
    echo("========== GEAR PAIR CALCULATION ==========");
    echo("Motor teeth:", motor_teeth);
    echo("Driven teeth:", driven_teeth);
    echo("Module:", module_val);
    echo("Motor radius:", motor_radius, "mm");
    echo("Driven radius:", driven_radius, "mm");
    echo("Center Distance:", center_distance, "mm (EXACT - do not estimate)");
    echo("Gear ratio:", gear_ratio);
    echo("==========================================");

    // ===== MOTOR GEAR at specified position =====
    translate(motor_pos) {
        rotate([0, 0, motor_angle]) {
            color(motor_color) simple_gear(motor_teeth, module_val, thickness);
        }
    }

    // ===== DRIVEN GEAR at CALCULATED position =====
    // Position is motor_pos + center_distance in X direction
    // Modify direction vector if gears are oriented differently
    driven_pos = [motor_pos[0] + center_distance, motor_pos[1], motor_pos[2]];

    translate(driven_pos) {
        rotate([0, 0, driven_angle]) {
            color(driven_color) simple_gear(driven_teeth, module_val, thickness);
        }
    }
}

// Compound gear train calculator
// For multi-stage reduction
module gear_train(stages, module_val, start_pos, input_angle=0) {
    // stages = [[motor_teeth, driven_teeth], [motor_teeth, driven_teeth], ...]
    // Each stage's driven gear shares shaft with next stage's motor gear

    current_pos = start_pos;
    current_angle = input_angle;
    cumulative_ratio = 1;

    echo("========== GEAR TRAIN ==========");
    for (i = [0:len(stages)-1]) {
        motor_t = stages[i][0];
        driven_t = stages[i][1];
        ratio = motor_t / driven_t;
        cumulative_ratio = cumulative_ratio * ratio;

        echo(str("Stage ", i+1, ": ", motor_t, "T -> ", driven_t, "T, ratio: ", ratio));
    }
    echo("Total ratio:", cumulative_ratio);
    echo("================================");
}


// ############################################################################
// SECTION 3: FOUR-BAR LINKAGE MODULE
// ############################################################################
// Four-bar linkages are fundamental mechanisms for converting rotation
// to complex motion. Grashof condition must be satisfied for full rotation.
// ############################################################################

// Grashof condition check
// For continuous rotation: s + l < p + q
// Where s = shortest link, l = longest link, p & q = other two links
function grashof_check(links) =
    let(
        sorted = [for (x = links) x],  // Copy array
        s = min(links),
        l = max(links),
        others = [for (x = links) if (x != s && x != l) x],
        // Handle case where multiple links have same length
        p = len(others) >= 1 ? others[0] : s,
        q = len(others) >= 2 ? others[1] : l
    )
    s + l < p + q;

// Law of cosines helper
// c^2 = a^2 + b^2 - 2ab*cos(C)
function law_of_cosines_angle(a, b, c) =
    acos((a*a + b*b - c*c) / (2*a*b));

function law_of_cosines_side(a, b, angle) =
    sqrt(a*a + b*b - 2*a*b*cos(angle));

// Four-bar linkage position calculator
// Returns [coupler_angle, rocker_angle] for given input angle
function four_bar_angles(crank, coupler, rocker, ground, input_angle) =
    let(
        // Crank tip position
        crank_x = crank * cos(input_angle),
        crank_y = crank * sin(input_angle),

        // Distance from rocker pivot to crank tip
        diag = sqrt(pow(ground - crank_x, 2) + pow(crank_y, 2)),

        // Angle of diagonal from rocker pivot
        diag_angle = atan2(crank_y, ground - crank_x),

        // Rocker angle using law of cosines
        rocker_internal = law_of_cosines_angle(rocker, diag, coupler),
        rocker_angle = diag_angle + rocker_internal,

        // Rocker tip position
        rocker_x = ground + rocker * cos(rocker_angle),
        rocker_y = rocker * sin(rocker_angle),

        // Coupler angle
        coupler_angle = atan2(rocker_y - crank_y, rocker_x - crank_x)
    )
    [coupler_angle, rocker_angle];

// Four-bar linkage visualization module
module four_bar_linkage(crank, coupler, rocker, ground, input_angle,
                        link_width=5, link_thickness=3, show_debug=true) {

    // ===== GRASHOF CHECK =====
    links = [crank, coupler, rocker, ground];
    grashof = grashof_check(links);

    if (show_debug) {
        echo("========== FOUR-BAR LINKAGE ==========");
        echo("Crank:", crank, "mm");
        echo("Coupler:", coupler, "mm");
        echo("Rocker:", rocker, "mm");
        echo("Ground:", ground, "mm");
        echo("Grashof condition:", grashof ? "VALID - continuous rotation possible" : "INVALID - limited rotation");
        echo("Input angle:", input_angle, "deg");
        echo("======================================");
    }

    // ===== CALCULATE POSITIONS =====
    // Ground link pivot points
    pivot_A = [0, 0, 0];           // Crank pivot (fixed)
    pivot_D = [ground, 0, 0];      // Rocker pivot (fixed)

    // Crank tip position (point B)
    B_x = crank * cos(input_angle);
    B_y = crank * sin(input_angle);
    pivot_B = [B_x, B_y, 0];

    // Calculate rocker and coupler angles
    angles = four_bar_angles(crank, coupler, rocker, ground, input_angle);
    rocker_angle = angles[1];

    // Rocker tip position (point C)
    C_x = ground + rocker * cos(rocker_angle);
    C_y = rocker * sin(rocker_angle);
    pivot_C = [C_x, C_y, 0];

    // ===== DRAW LINKAGE =====

    // Helper module for link visualization
    module link(start, end, width, thickness) {
        length = sqrt(pow(end[0]-start[0], 2) + pow(end[1]-start[1], 2));
        angle = atan2(end[1]-start[1], end[0]-start[0]);

        translate(start) {
            rotate([0, 0, angle]) {
                // Link body
                translate([0, -width/2, 0])
                    cube([length, width, thickness]);
                // End caps (circles)
                cylinder(h=thickness, r=width/2, $fn=24);
                translate([length, 0, 0])
                    cylinder(h=thickness, r=width/2, $fn=24);
            }
        }
    }

    // Ground link (usually not drawn, but shown as reference)
    color("DarkGray", 0.3)
        link(pivot_A, pivot_D, link_width*0.8, link_thickness*0.5);

    // Crank (input link)
    color("Red")
        link(pivot_A, pivot_B, link_width, link_thickness);

    // Coupler (connecting link)
    color("Green")
        link(pivot_B, pivot_C, link_width, link_thickness);

    // Rocker (output link)
    color("Blue")
        link(pivot_D, pivot_C, link_width, link_thickness);

    // Pivot points
    color("Black") {
        // Fixed pivots
        translate(pivot_A) cylinder(h=link_thickness*2, r=link_width/4, $fn=16);
        translate(pivot_D) cylinder(h=link_thickness*2, r=link_width/4, $fn=16);
        // Moving pivots
        translate(pivot_B) cylinder(h=link_thickness*2, r=link_width/4, $fn=16);
        translate(pivot_C) cylinder(h=link_thickness*2, r=link_width/4, $fn=16);
    }
}


// ############################################################################
// SECTION 4: ANIMATION PATTERNS
// ############################################################################
// OpenSCAD uses $t (0 to 1) for animation. Use View > Animate and set
// FPS and Steps in the animation panel.
// ############################################################################

// ===== LINEAR MOTION =====
// Moves from start_pos to end_pos over animation cycle
// linear_pos = start_pos + (end_pos - start_pos) * $t;

// Example: Moving platform
module animated_linear_example() {
    start_pos = [0, 0, 0];
    end_pos = [100, 0, 0];
    current_pos = start_pos + (end_pos - start_pos) * $t;

    translate(current_pos)
        cube([20, 20, 10], center=true);
}

// ===== OSCILLATION (SINE WAVE) =====
// Smooth back-and-forth motion
// oscillate = amplitude * sin($t * 360);

// Example: Oscillating pendulum
module animated_oscillate_example() {
    amplitude = 45;  // degrees
    angle = amplitude * sin($t * 360);

    rotate([0, 0, angle])
        translate([0, 50, 0])
            sphere(r=10);
}

// ===== OSCILLATION WITH PHASE OFFSET =====
// For multiple elements with staggered timing
// oscillate_phased = amplitude * sin($t * 360 + phase_offset);

// Example: Wave effect with multiple elements
module animated_wave_example() {
    amplitude = 20;
    num_elements = 10;

    for (i = [0:num_elements-1]) {
        phase_offset = i * 36;  // 360/10 = 36 degrees apart
        y_pos = amplitude * sin($t * 360 + phase_offset);

        translate([i * 15, y_pos, 0])
            sphere(r=5);
    }
}

// ===== CONTINUOUS ROTATION =====
// Full rotation per cycle (or use gear_ratio for speed changes)
// rotation_angle = $t * 360 * gear_ratio;

// Example: Spinning gear
module animated_rotation_example() {
    rotation_angle = $t * 360;

    rotate([0, 0, rotation_angle])
        simple_gear(20, 1.5, 5);
}

// ===== EASED MOTION =====
// Slow start and end (ease-in-out)
// eased = (1 - cos($t * 180)) / 2;

// Example: Smooth acceleration/deceleration
module animated_eased_example() {
    eased = (1 - cos($t * 180)) / 2;  // 0 to 1 with easing

    translate([eased * 100, 0, 0])
        cube([10, 10, 10], center=true);
}

// ===== PING-PONG (BOUNCE) =====
// Goes forward then backward
// ping_pong = abs(sin($t * 180));

// Example: Bouncing ball effect
module animated_pingpong_example() {
    ping_pong = abs(sin($t * 180));

    translate([0, 0, ping_pong * 50])
        sphere(r=10);
}

// ===== STEPPED MOTION =====
// Discrete steps instead of smooth motion
// step = floor($t * num_steps) / num_steps;

// Example: Clock-like motion
module animated_stepped_example() {
    num_steps = 12;
    step = floor($t * num_steps) / num_steps;
    angle = step * 360;

    rotate([0, 0, angle])
        translate([30, 0, 0])
            cube([5, 5, 5], center=true);
}

// ===== COMPLEX MOTION COMBINING PATTERNS =====
// Example: Mechanical arm with multiple motions
module animated_complex_example() {
    // Base rotation
    base_angle = $t * 360;

    // Arm oscillation
    arm_angle = 30 * sin($t * 360 * 2);  // 2x frequency

    // End effector opening/closing
    gripper = 5 + 10 * abs(sin($t * 360 * 4));  // 4x frequency

    rotate([0, 0, base_angle]) {
        // Base
        cylinder(h=10, r=20, $fn=32);

        // Arm
        translate([0, 0, 10]) {
            rotate([arm_angle, 0, 0]) {
                cube([10, 50, 5], center=true);

                // Gripper
                translate([0, 25, 0]) {
                    translate([gripper, 0, 0]) cube([3, 10, 5], center=true);
                    translate([-gripper, 0, 0]) cube([3, 10, 5], center=true);
                }
            }
        }
    }
}


// ############################################################################
// SECTION 5: Z-LAYER MANAGEMENT
// ############################################################################
// Define Z positions as constants to prevent collision and maintain
// clear layer organization. Always use these constants for positioning.
// ############################################################################

// ===== Z-LAYER STACK TEMPLATE =====
// Negative Z = back, Positive Z = front (toward viewer)
// Adjust values based on actual component thicknesses

Z_BACK_WALL = -50;      // Enclosure back wall
Z_MOTOR = -40;          // Motor assembly
Z_GEAR_LAYER = -30;     // Main gear train
Z_MECHANISM_BASE = -20; // Base of main mechanism
Z_MAIN_MECHANISM = 0;   // Primary mechanism plane
Z_WAVE_3 = 10;          // Deepest wave layer (if using waves)
Z_WAVE_2 = 20;          // Middle wave layer
Z_WAVE_1 = 30;          // Frontmost wave layer
Z_FRONT_FRAME = 40;     // Front frame/border
Z_FRONT_DECOR = 50;     // Front decorative elements
Z_GLASS = 55;           // Glass/transparent cover (if any)

// ===== LAYER THICKNESS CONSTANTS =====
// Use these to ensure no overlap
WALL_THICKNESS = 5;
GEAR_THICKNESS = 8;
WAVE_THICKNESS = 3;
FRAME_THICKNESS = 10;

// ===== Z-POSITION HELPER MODULE =====
// Use this to place components at correct Z levels
module at_z_layer(z_constant) {
    translate([0, 0, z_constant])
        children();
}

// Example usage:
/*
at_z_layer(Z_MOTOR) {
    motor_assembly();
}

at_z_layer(Z_WAVE_1) {
    wave_layer(0);
}
*/

// ===== LAYER VISUALIZATION DEBUG =====
// Shows all Z-layers as transparent planes
module show_z_layers() {
    layer_size = 100;  // Size of debug planes

    module debug_plane(z, name, col) {
        color(col, 0.2)
            translate([-layer_size/2, -layer_size/2, z])
                cube([layer_size, layer_size, 0.5]);
        echo(str(name, ": Z = ", z));
    }

    debug_plane(Z_BACK_WALL, "Back Wall", "Purple");
    debug_plane(Z_MOTOR, "Motor", "Red");
    debug_plane(Z_MAIN_MECHANISM, "Main Mechanism", "Green");
    debug_plane(Z_WAVE_3, "Wave 3", "Blue");
    debug_plane(Z_WAVE_2, "Wave 2", "Cyan");
    debug_plane(Z_WAVE_1, "Wave 1", "Yellow");
    debug_plane(Z_FRONT_DECOR, "Front Decor", "Orange");
}


// ############################################################################
// SECTION 6: SVG IMPORT PATTERN
// ############################################################################
// OpenSCAD can import SVG files, but for programmatic control,
// extract coordinates first and use polygon().
// NEVER use placeholder data - extract from actual SVG files.
// ############################################################################

// ===== SVG FILE IMPORT (Direct method) =====
// Simple but less flexible
/*
module imported_svg_shape(filename, thickness) {
    linear_extrude(height=thickness)
        import(filename, center=true);
}
*/

// ===== SVG COORDINATE EXTRACTION =====
// Preferred method: Extract coordinates via bash/Python first
// Then use the actual coordinates in OpenSCAD

// WRONG - Placeholder data (NEVER do this):
// wave_points_wrong = [[0,0], [100,0], [100,100], [0,100]];

// RIGHT - Data extracted from actual SVG file:
// Example wave points (replace with real extracted data)
wave_points_example = [
    [0.0, 25.0],
    [10.0, 30.2],
    [20.0, 38.5],
    [30.0, 42.1],
    [40.0, 40.0],
    [50.0, 35.8],
    [60.0, 28.3],
    [70.0, 22.5],
    [80.0, 20.0],
    [90.0, 22.5],
    [100.0, 28.3],
    [100.0, 0.0],
    [0.0, 0.0]
];

// Module to create 3D shape from 2D points
module svg_shape(points, thickness, center=false) {
    translate(center ? [0, 0, -thickness/2] : [0, 0, 0])
        linear_extrude(height=thickness)
            polygon(points);
}

// Module to create outline/stroke from points
module svg_outline(points, stroke_width, thickness) {
    linear_extrude(height=thickness) {
        difference() {
            offset(r=stroke_width/2) polygon(points);
            offset(r=-stroke_width/2) polygon(points);
        }
    }
}

// ===== BASH COMMAND FOR SVG COORDINATE EXTRACTION =====
// Use this command pattern to extract points from SVG path:
/*
# For simple SVG paths, extract with:
grep -o 'd="[^"]*"' input.svg | head -1

# For more complex extraction, use Python:
python3 -c "
from xml.dom import minidom
import re

doc = minidom.parse('input.svg')
paths = doc.getElementsByTagName('path')
for path in paths:
    d = path.getAttribute('d')
    # Parse path data...
    print(d)
"
*/

// ===== BEZIER CURVE APPROXIMATION =====
// SVG often uses Bezier curves. Approximate with line segments.
function bezier_point(t, p0, p1, p2, p3) =
    pow(1-t, 3) * p0 +
    3 * pow(1-t, 2) * t * p1 +
    3 * (1-t) * pow(t, 2) * p2 +
    pow(t, 3) * p3;

function bezier_curve(p0, p1, p2, p3, segments=10) =
    [for (i = [0:segments]) bezier_point(i/segments, p0, p1, p2, p3)];


// ############################################################################
// SECTION 7: DEBUG VISUALIZATION
// ############################################################################
// Debug helpers for development and troubleshooting.
// Use % prefix for transparent preview, # for highlight.
// ############################################################################

// ===== BOUNDING BOX =====
// Shows transparent bounding box for size reference
module show_bounds(w, h, d, center=true) {
    %cube([w, h, d], center=center);  // % makes it transparent
}

// Bounding box from min/max coordinates
module show_bounds_minmax(min_pt, max_pt) {
    size = max_pt - min_pt;
    %translate(min_pt)
        cube(size);
}

// ===== COORDINATE AXES =====
// Shows X (red), Y (green), Z (blue) axes
module show_axis(length=50, thickness=1) {
    // Z axis - Blue (up)
    color("Blue")
        cylinder(h=length, r=thickness, $fn=16);

    // X axis - Red (right)
    color("Red")
        rotate([0, 90, 0])
            cylinder(h=length, r=thickness, $fn=16);

    // Y axis - Green (forward/back)
    color("Green")
        rotate([-90, 0, 0])
            cylinder(h=length, r=thickness, $fn=16);

    // Origin sphere
    color("White")
        sphere(r=thickness*2, $fn=16);

    // Axis labels (as small spheres at ends)
    color("Red") translate([length, 0, 0]) sphere(r=thickness*1.5, $fn=12);
    color("Green") translate([0, length, 0]) sphere(r=thickness*1.5, $fn=12);
    color("Blue") translate([0, 0, length]) sphere(r=thickness*1.5, $fn=12);
}

// ===== POINT LABEL =====
// Marks a point with a sphere and echoes coordinates
module label_point(pos, name="Point", radius=2, col="Red") {
    translate(pos) {
        color(col) sphere(r=radius, $fn=16);
    }
    echo(str(name, " at [", pos[0], ", ", pos[1], ", ", pos[2], "]"));
}

// ===== DISTANCE INDICATOR =====
// Shows distance between two points
module show_distance(p1, p2, col="Yellow") {
    dist = sqrt(pow(p2[0]-p1[0], 2) + pow(p2[1]-p1[1], 2) + pow(p2[2]-p1[2], 2));

    // Line between points
    hull() {
        translate(p1) color(col) sphere(r=0.5, $fn=8);
        translate(p2) color(col) sphere(r=0.5, $fn=8);
    }

    // Midpoint label
    midpoint = (p1 + p2) / 2;
    translate(midpoint) color(col) sphere(r=1, $fn=12);

    echo(str("Distance: ", dist, " mm"));
}

// ===== ANGLE INDICATOR =====
// Shows an angle arc for debugging rotations
module show_angle(center, radius, start_angle, end_angle, col="Orange") {
    translate(center) {
        color(col, 0.5)
            rotate([0, 0, start_angle])
                rotate_extrude(angle=end_angle-start_angle, $fn=36)
                    translate([radius, 0, 0])
                        circle(r=1, $fn=8);
    }
    echo(str("Angle: ", end_angle - start_angle, " degrees"));
}

// ===== GRID HELPER =====
// Shows a reference grid on XY plane
module show_grid(size=100, spacing=10, col="Gray") {
    color(col, 0.3)
    for (x = [-size/2 : spacing : size/2]) {
        translate([x, -size/2, 0])
            cube([0.2, size, 0.2]);
    }
    for (y = [-size/2 : spacing : size/2]) {
        translate([-size/2, y, 0])
            cube([size, 0.2, 0.2]);
    }
}

// ===== COLLISION DETECTION HELPER =====
// Highlights overlapping regions
module show_collision(obj1_bounds, obj2_bounds) {
    // Check for overlap
    overlap_x = (obj1_bounds[0][0] < obj2_bounds[1][0]) && (obj1_bounds[1][0] > obj2_bounds[0][0]);
    overlap_y = (obj1_bounds[0][1] < obj2_bounds[1][1]) && (obj1_bounds[1][1] > obj2_bounds[0][1]);
    overlap_z = (obj1_bounds[0][2] < obj2_bounds[1][2]) && (obj1_bounds[1][2] > obj2_bounds[0][2]);

    collision = overlap_x && overlap_y && overlap_z;

    if (collision) {
        echo("WARNING: COLLISION DETECTED!");
        // Highlight collision region
        color("Red", 0.5) {
            min_pt = [max(obj1_bounds[0][0], obj2_bounds[0][0]),
                      max(obj1_bounds[0][1], obj2_bounds[0][1]),
                      max(obj1_bounds[0][2], obj2_bounds[0][2])];
            max_pt = [min(obj1_bounds[1][0], obj2_bounds[1][0]),
                      min(obj1_bounds[1][1], obj2_bounds[1][1]),
                      min(obj1_bounds[1][2], obj2_bounds[1][2])];
            translate(min_pt)
                cube(max_pt - min_pt);
        }
    } else {
        echo("No collision detected.");
    }
}


// ############################################################################
// SECTION 8: COMPONENT SURVIVAL MARKERS
// ############################################################################
// During iterative development, components can accidentally be deleted
// or commented out. Use these markers to track critical components.
// ############################################################################

// ===== COMPONENT PRESENCE FLAGS =====
// Set these to true when component is added to assembly
ENCLOSURE_PRESENT = false;   // Set true when enclosure module is called
MOTOR_PRESENT = false;       // Set true when motor is added
FOURBAR_PRESENT = false;     // Set true when four-bar linkage is added
WAVES_PRESENT = false;       // Set true when wave layers are added
GEARS_PRESENT = false;       // Set true when gear train is added

// ===== SURVIVAL CHECK MODULE =====
// Call this at end of file to verify all components are present
module SURVIVAL_CHECK() {
    echo("");
    echo("╔════════════════════════════════════════╗");
    echo("║     COMPONENT SURVIVAL CHECK           ║");
    echo("╠════════════════════════════════════════╣");
    echo(str("║  Enclosure:    ", ENCLOSURE_PRESENT ? "PRESENT" : "MISSING", "              ║"));
    echo(str("║  Motor:        ", MOTOR_PRESENT ? "PRESENT" : "MISSING", "              ║"));
    echo(str("║  Four-bar:     ", FOURBAR_PRESENT ? "PRESENT" : "MISSING", "              ║"));
    echo(str("║  Waves:        ", WAVES_PRESENT ? "PRESENT" : "MISSING", "              ║"));
    echo(str("║  Gears:        ", GEARS_PRESENT ? "PRESENT" : "MISSING", "              ║"));
    echo("╚════════════════════════════════════════╝");
    echo("");

    // Count missing components
    missing = (ENCLOSURE_PRESENT ? 0 : 1) +
              (MOTOR_PRESENT ? 0 : 1) +
              (FOURBAR_PRESENT ? 0 : 1) +
              (WAVES_PRESENT ? 0 : 1) +
              (GEARS_PRESENT ? 0 : 1);

    if (missing > 0) {
        echo(str("WARNING: ", missing, " component(s) missing!"));
    } else {
        echo("All components present.");
    }
}

// ===== COMPONENT REGISTRY =====
// Alternative approach: Register components as they're created
// Useful for dynamic assembly checking

// Global registry (use with caution - OpenSCAD scope rules apply)
COMPONENT_REGISTRY = [];

module register_component(name) {
    echo(str("Registered component: ", name));
    // Note: Can't actually modify global in OpenSCAD
    // This is mainly for echo/documentation purposes
}

// ===== VERSION TRACKING =====
// Include version info in output
module version_info(project, version, date) {
    echo("");
    echo("╔════════════════════════════════════════╗");
    echo(str("║  Project: ", project));
    echo(str("║  Version: ", version));
    echo(str("║  Date:    ", date));
    echo("╚════════════════════════════════════════╝");
    echo("");
}


// ############################################################################
// SECTION 9: UTILITY FUNCTIONS
// ############################################################################
// Common helper functions for calculations and transformations.
// ############################################################################

// ===== MATH HELPERS =====

// Clamp value between min and max
function clamp(val, min_val, max_val) =
    max(min_val, min(max_val, val));

// Linear interpolation
function lerp(a, b, t) = a + (b - a) * t;

// Map value from one range to another
function map_range(val, in_min, in_max, out_min, out_max) =
    out_min + (out_max - out_min) * ((val - in_min) / (in_max - in_min));

// Degrees to radians
function deg2rad(deg) = deg * PI / 180;

// Radians to degrees
function rad2deg(rad) = rad * 180 / PI;

// ===== VECTOR HELPERS =====

// Vector magnitude (length)
function vec_len(v) = sqrt(v[0]*v[0] + v[1]*v[1] + (len(v) > 2 ? v[2]*v[2] : 0));

// Normalize vector (unit vector)
function vec_normalize(v) = v / vec_len(v);

// Dot product
function vec_dot(a, b) = a[0]*b[0] + a[1]*b[1] + (len(a) > 2 ? a[2]*b[2] : 0);

// Cross product (3D only)
function vec_cross(a, b) = [
    a[1]*b[2] - a[2]*b[1],
    a[2]*b[0] - a[0]*b[2],
    a[0]*b[1] - a[1]*b[0]
];

// Angle between two vectors (degrees)
function vec_angle(a, b) = acos(vec_dot(a, b) / (vec_len(a) * vec_len(b)));

// ===== GEOMETRY HELPERS =====

// Circle points generator
function circle_points(radius, segments=36) =
    [for (i = [0:segments-1])
        [radius * cos(i * 360 / segments),
         radius * sin(i * 360 / segments)]];

// Arc points generator
function arc_points(radius, start_angle, end_angle, segments=36) =
    [for (i = [0:segments])
        let(angle = start_angle + (end_angle - start_angle) * i / segments)
        [radius * cos(angle), radius * sin(angle)]];

// Rectangle points (for polygon)
function rect_points(w, h, center=true) =
    center ?
        [[-w/2, -h/2], [w/2, -h/2], [w/2, h/2], [-w/2, h/2]] :
        [[0, 0], [w, 0], [w, h], [0, h]];

// Rounded rectangle points
function rounded_rect_points(w, h, r, segments=8) =
    let(
        corner_pts = segments,
        corners = [
            [w/2 - r, h/2 - r],   // Top right
            [-w/2 + r, h/2 - r],  // Top left
            [-w/2 + r, -h/2 + r], // Bottom left
            [w/2 - r, -h/2 + r]   // Bottom right
        ]
    )
    [for (c = [0:3])
        for (i = [0:corner_pts-1])
            let(angle = c * 90 + i * 90 / corner_pts)
            corners[c] + [r * cos(angle), r * sin(angle)]
    ];


// ############################################################################
// SECTION 10: EXAMPLE ASSEMBLY
// ############################################################################
// Demonstrates use of templates in a complete example.
// Uncomment to run.
// ############################################################################

/*
// === EXAMPLE PROJECT PARAMETERS ===
EX_WIDTH = 200;
EX_HEIGHT = 150;
EX_DEPTH = 80;

// === EXAMPLE ASSEMBLY ===
module example_assembly() {
    // Show reference axes
    show_axis(50);

    // Show bounding box
    show_bounds(EX_WIDTH, EX_HEIGHT, EX_DEPTH);

    // Gear pair example
    translate([0, 0, Z_GEAR_LAYER])
        gear_pair(
            motor_teeth = 12,
            driven_teeth = 48,
            module_val = 1.5,
            motor_pos = [-50, 0, 0],
            motor_angle = $t * 360
        );

    // Four-bar linkage example
    translate([50, -30, Z_MAIN_MECHANISM])
        four_bar_linkage(
            crank = 15,
            coupler = 50,
            rocker = 40,
            ground = 60,
            input_angle = $t * 360
        );
}

// Run example
example_assembly();

// Version info
version_info("Example Assembly", "V01", "2024");

// Survival check
SURVIVAL_CHECK();
*/


// ############################################################################
// END OF TEMPLATES FILE
// ############################################################################
// To use these templates:
// 1. Copy relevant sections to your project file
// 2. Customize parameters for your specific design
// 3. Use modules as building blocks
// 4. Always calculate positions - never estimate
// 5. Run SURVIVAL_CHECK() at end of file during development
// ############################################################################

echo("");
echo("OpenSCAD Templates loaded successfully.");
echo("See comments for usage instructions.");
echo("");
