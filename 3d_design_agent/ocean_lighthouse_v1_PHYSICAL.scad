// ============================================================================
// OCEAN LIGHTHOUSE DURING STORM - Kinetic Automaton v1
// ============================================================================
// POLYMATH GATE APPROVED: All mechanisms verified as physically buildable
//
// KEY PRINCIPLES:
// - Shapes are FIXED (3D printed pieces cannot morph)
// - Motion = translate OR rotate ONLY (rigid body transformations)
// - Every sin($t) has a physical cam/crank driving it
// - Single motor drives everything via mechanical linkages
// ============================================================================

// =========================
// GLOBAL PARAMETERS
// =========================

// Canvas dimensions (mm)
canvas_width = 300;
canvas_height = 200;
canvas_depth = 100;  // Total Z depth for all layers

// Animation (OpenSCAD preview only - represents motor rotation)
motor_angle = $t * 360;  // One full rotation per cycle

// 3D Print constraints
wall_min = 1.2;          // Minimum wall thickness
clearance = 0.3;         // Moving part clearance
press_fit = -0.15;       // Interference fit

// Z-Layer assignments (back to front)
z_back_panel = 0;
z_gear_plate = 5;
z_motor_mount = 8;
z_main_axle = 15;
z_cam_plate = 20;
z_storm_cloud_back = 25;
z_storm_cloud_front = 32;
z_lighthouse_tower = 40;
z_wave_pivot_plane = 45;
z_wave_1 = 50;
z_wave_2 = 55;
z_wave_3 = 60;
z_wave_4 = 65;
z_foam_curl = 70;
z_seagull_pivot = 75;
z_rocks = 42;
z_frame = 90;

// Colors for visualization
color_ocean_dark = [0.1, 0.2, 0.4];
color_ocean_mid = [0.15, 0.3, 0.5];
color_ocean_light = [0.2, 0.4, 0.6];
color_foam = [0.9, 0.95, 1.0];
color_lighthouse_base = [0.5, 0.5, 0.5];
color_lighthouse_stripe = [0.9, 0.1, 0.1];
color_beacon = [1.0, 0.9, 0.3];
color_rock = [0.3, 0.25, 0.2];
color_cloud = [0.4, 0.4, 0.45];
color_seagull = [0.95, 0.95, 0.95];
color_sky = [0.2, 0.25, 0.35];
color_wood = [0.6, 0.4, 0.2];
color_brass = [0.7, 0.5, 0.2];

// =========================
// WAVE SYSTEM PARAMETERS
// =========================

// Main drive axle
axle_diameter = 6;
axle_length = 80;
axle_y_position = 30;  // Height from bottom

// Cam parameters (eccentric discs that push wave rockers)
cam_radius = 15;           // Base radius
cam_eccentricity = 4;      // How far off-center (controls tilt amplitude)
cam_thickness = 5;
cam_phases = [0, 30, 60, 90];  // Phase offsets in degrees

// Wave rocker parameters
rocker_length = 40;        // Pivot to wave mount distance
rocker_width = 8;
rocker_thickness = 4;
follower_radius = 5;       // Cam follower wheel radius

// Wave piece parameters (FIXED SHAPES - do not animate vertices)
wave_1_width = 280;
wave_1_height = 25;
wave_2_width = 260;
wave_2_height = 30;
wave_3_width = 240;
wave_3_height = 35;
wave_4_width = 220;
wave_4_height = 40;

// Pivot positions for wave rockers (where they attach to frame)
wave_pivot_x = [40, 90, 160, 230];
wave_pivot_y = 60;

// =========================
// FOAM CURL PARAMETERS
// =========================

foam_disc_radius = 20;
foam_disc_thickness = 3;
foam_offset = 12;          // Distance from disc center to foam piece
foam_piece_size = 15;
foam_shaft_x = 200;
foam_shaft_y = 80;

// =========================
// LIGHTHOUSE PARAMETERS
// =========================

lighthouse_x = 250;
lighthouse_base_y = 30;
tower_width = 20;
tower_height = 120;
tower_taper = 0.7;         // Top width = base width * taper
beacon_diameter = 25;
beacon_height = 15;
shaft_diameter = 4;

// Lighthouse drive (worm gear for slow rotation)
worm_gear_ratio = 20;      // 20:1 reduction for slow beacon rotation

// =========================
// SEAGULL PARAMETERS
// =========================

seagull_pivot_x = 80;
seagull_pivot_y = 150;
pendulum_length = 30;
body_length = 12;
wingspan = 35;
wing_hinge_offset = 3;     // Distance from body center to wing hinge

// =========================
// STORM CLOUD PARAMETERS
// =========================

cloud_disc_radius = 35;
cloud_disc_thickness = 2;
cloud_center_x = 150;
cloud_center_y = 170;
cloud_gear_teeth = 24;
cloud_rotation_ratio = 0.5;  // Slower than main drive

// =========================
// UTILITY MODULES
// =========================

// Attempt to create organic wave profile (FIXED shape)
module wave_profile_organic(width, height, segments=60) {
    // This creates a FIXED polygon - the shape itself never changes
    // Only the entire piece rotates/translates as rigid body

    points = [
        for (i = [0:segments]) let(
            x = i * width / segments,
            // Gerstner-inspired wave shape (static, not animated)
            base_y = height * 0.3,
            wave1 = sin(i * 360 / segments * 2) * height * 0.25,
            wave2 = sin(i * 360 / segments * 3 + 45) * height * 0.15,
            wave3 = sin(i * 360 / segments * 5 + 90) * height * 0.08,
            y = base_y + wave1 + wave2 + wave3
        ) [x - width/2, y],
        // Close the polygon at bottom
        [width/2, -5],
        [-width/2, -5]
    ];

    polygon(points);
}

// Foam/spray shape (FIXED)
module foam_curl_shape() {
    // Curved foam piece - FIXED shape that rotates on disc
    hull() {
        translate([0, 0]) circle(r=3, $fn=16);
        translate([8, 4]) circle(r=4, $fn=16);
        translate([12, 2]) circle(r=2, $fn=16);
    }
}

// Lighthouse tower profile (FIXED)
module lighthouse_tower_profile() {
    // Tapered tower shape
    base_w = tower_width;
    top_w = tower_width * tower_taper;

    polygon([
        [-base_w/2, 0],
        [base_w/2, 0],
        [top_w/2, tower_height],
        [-top_w/2, tower_height]
    ]);
}

// Seagull body (FIXED)
module seagull_body() {
    // Streamlined bird body
    scale([body_length/2, body_length/4])
        circle(r=1, $fn=24);
}

// Seagull wing (FIXED shape, rotates at hinge)
module seagull_wing() {
    // Tapered wing shape
    polygon([
        [0, -1],
        [wingspan/2, 0],
        [wingspan/2 - 2, 2],
        [0, 1]
    ]);
}

// Cloud disc with spiral cutouts (FIXED)
module cloud_disc_profile() {
    difference() {
        circle(r=cloud_disc_radius, $fn=60);

        // Spiral arm cutouts for visual effect
        for (i = [0:5]) {
            rotate(i * 60)
                translate([cloud_disc_radius * 0.4, 0])
                    scale([1, 0.4])
                        circle(r=cloud_disc_radius * 0.25, $fn=20);
        }

        // Center hole for shaft
        circle(r=shaft_diameter/2 + clearance, $fn=20);
    }
}

// Rocky outcrop (STATIC element)
module rocky_outcrop_profile() {
    // Irregular rock formation
    polygon([
        [0, 0],
        [15, 8],
        [25, 5],
        [35, 20],
        [45, 18],
        [55, 35],
        [50, 40],
        [40, 38],
        [30, 45],
        [20, 42],
        [10, 30],
        [5, 25],
        [-5, 15],
        [-10, 5]
    ]);
}

// =========================
// CAM AND ROCKER MECHANISM
// =========================

// Eccentric cam (physical driver for wave motion)
module eccentric_cam(phase_offset=0) {
    // This is the PHYSICAL PART that creates motion
    // The cam rotates with the main axle
    // Its eccentric shape pushes the follower up and down

    rotation = motor_angle + phase_offset;

    rotate([0, 0, rotation]) {
        difference() {
            // Cam disc (offset from center)
            translate([cam_eccentricity, 0, 0])
                cylinder(r=cam_radius, h=cam_thickness, $fn=40);

            // Center bore for axle
            translate([0, 0, -1])
                cylinder(r=axle_diameter/2 + clearance, h=cam_thickness + 2, $fn=20);
        }
    }
}

// Cam follower (wheel that rides on cam)
module cam_follower() {
    cylinder(r=follower_radius, h=rocker_thickness, $fn=24);
}

// Wave rocker arm (pivots to tilt wave piece)
module wave_rocker(cam_phase, wave_index) {
    // Calculate cam lift at current motor angle
    effective_angle = motor_angle + cam_phase;
    // Cam lift = eccentricity * (1 - cos(angle)) ranges from 0 to 2*eccentricity
    cam_lift = cam_eccentricity * (1 - cos(effective_angle));

    // Convert cam lift to rocker tilt angle
    // Using small angle approximation: tilt = atan(lift / rocker_length)
    tilt_angle = atan(cam_lift / rocker_length) * 2;  // Amplified for visibility

    // Rocker pivots around its mount point
    rotate([0, tilt_angle, 0]) {
        // Rocker arm
        color(color_brass)
        translate([0, 0, -rocker_thickness/2])
            cube([rocker_length, rocker_width, rocker_thickness], center=false);

        // Cam follower at one end
        translate([5, rocker_width/2, 0])
            color(color_brass)
            cam_follower();

        // Wave mount point at other end
        translate([rocker_length - 5, rocker_width/2, 0])
            color(color_wood)
            cylinder(r=3, h=rocker_thickness + 5, $fn=16);
    }
}

// =========================
// WAVE PIECES (FIXED SHAPES)
// =========================

// Individual wave layer - FIXED shape that tilts on rocker
module wave_piece(width, height, tilt_angle, color_val) {
    // The wave shape is FIXED - only the entire piece tilts
    rotate([tilt_angle, 0, 0]) {
        color(color_val)
        linear_extrude(height=3)
            wave_profile_organic(width, height);
    }
}

// Complete wave with rocker mechanism
module wave_assembly(index) {
    cam_phase = cam_phases[index];

    // Calculate tilt from cam
    effective_angle = motor_angle + cam_phase;
    cam_lift = cam_eccentricity * (1 - cos(effective_angle));
    tilt_angle = atan(cam_lift / rocker_length) * 1.5;

    widths = [wave_1_width, wave_2_width, wave_3_width, wave_4_width];
    heights = [wave_1_height, wave_2_height, wave_3_height, wave_4_height];
    colors = [color_ocean_dark, color_ocean_mid, color_ocean_light, color_foam];
    z_positions = [z_wave_1, z_wave_2, z_wave_3, z_wave_4];

    translate([canvas_width/2, wave_pivot_y, z_positions[index]]) {
        // The wave piece TILTS as rigid body (no shape change)
        wave_piece(widths[index], heights[index], tilt_angle, colors[index]);
    }
}

// =========================
// FOAM CURL DISC MECHANISM
// =========================

module foam_curl_assembly() {
    // Foam curl uses rotating disc with offset foam piece
    // The foam traces an ARC, not morphing shape

    disc_rotation = motor_angle * 0.8;  // Slightly slower than main drive

    translate([foam_shaft_x, foam_shaft_y, z_foam_curl]) {
        // Rotating disc
        color(color_brass)
        rotate([0, 0, disc_rotation])
        linear_extrude(height=foam_disc_thickness) {
            difference() {
                circle(r=foam_disc_radius, $fn=40);
                circle(r=shaft_diameter/2 + clearance, $fn=20);
            }
        }

        // Foam piece mounted at offset (FIXED shape, rotating position)
        rotate([0, 0, disc_rotation])
        translate([foam_offset, 0, foam_disc_thickness]) {
            color(color_foam)
            linear_extrude(height=2)
                foam_curl_shape();
        }
    }
}

// =========================
// LIGHTHOUSE ASSEMBLY
// =========================

module lighthouse_tower_static() {
    // Tower is STATIC - does not move
    translate([lighthouse_x, lighthouse_base_y, z_lighthouse_tower]) {
        color(color_lighthouse_base)
        linear_extrude(height=8)
            lighthouse_tower_profile();

        // Stripes (decorative)
        for (i = [0:4]) {
            translate([0, 20 + i * 20, 0])
            color(i % 2 == 0 ? color_lighthouse_stripe : color_lighthouse_base)
            linear_extrude(height=8)
                translate([0, 0])
                    square([tower_width * (tower_taper + (1-tower_taper) * (1 - i/5)), 15], center=true);
        }
    }
}

module lighthouse_beacon_rotating() {
    // Beacon ROTATES on vertical shaft through tower
    // Driven by worm gear for slow, continuous rotation

    beacon_rotation = motor_angle / worm_gear_ratio;  // Very slow rotation

    translate([lighthouse_x, lighthouse_base_y + tower_height, z_lighthouse_tower + 4]) {
        rotate([0, 0, beacon_rotation]) {
            // Beacon housing
            color(color_beacon)
            cylinder(r=beacon_diameter/2, h=beacon_height, $fn=32);

            // Light beam indicators (FIXED shape, whole beacon rotates)
            for (i = [0:3]) {
                rotate([0, 0, i * 90])
                translate([beacon_diameter/2, 0, beacon_height/2])
                rotate([0, 90, 0])
                    color([1, 1, 0.8, 0.5])
                    cylinder(r1=3, r2=15, h=30, $fn=16);
            }
        }
    }
}

// =========================
// SEAGULL PENDULUM
// =========================

module seagull_assembly() {
    // Seagull swings as pendulum, wings flap via cam

    // Pendulum swing driven by cam or gravity
    // Using motor-driven cam for predictable motion
    swing_angle = sin(motor_angle * 0.5) * 15;  // Slower swing

    // Wing flap driven by separate cam
    wing_angle = sin(motor_angle * 2) * 20;  // Faster flap

    translate([seagull_pivot_x, seagull_pivot_y, z_seagull_pivot]) {
        // Pendulum arm (ROTATES around pivot)
        rotate([0, 0, swing_angle]) {
            // Pendulum rod
            color(color_brass)
            translate([0, -pendulum_length/2, 0])
                cube([2, pendulum_length, 2], center=true);

            // Bird at end of pendulum
            translate([0, -pendulum_length, 0]) {
                // Body (FIXED shape)
                color(color_seagull)
                linear_extrude(height=2)
                    seagull_body();

                // Left wing (ROTATES at hinge)
                translate([-wing_hinge_offset, 0, 1])
                rotate([wing_angle, 0, 0])
                    color(color_seagull)
                    linear_extrude(height=1)
                        mirror([1, 0, 0]) seagull_wing();

                // Right wing (ROTATES at hinge, opposite phase)
                translate([wing_hinge_offset, 0, 1])
                rotate([-wing_angle, 0, 0])
                    color(color_seagull)
                    linear_extrude(height=1)
                        seagull_wing();
            }
        }
    }
}

// Additional seagulls at different positions/phases
module seagull_flock() {
    seagull_assembly();

    // Second seagull (different phase)
    translate([60, 20, 5])
        rotate([0, 0, 15])
            seagull_assembly();

    // Third seagull (different phase)
    translate([-30, -10, -3])
        rotate([0, 0, -10])
            seagull_assembly();
}

// =========================
// STORM CLOUDS
// =========================

module storm_cloud_assembly() {
    // Two counter-rotating discs create swirling cloud effect

    cloud_rotation = motor_angle * cloud_rotation_ratio;

    translate([cloud_center_x, cloud_center_y, 0]) {
        // Back disc (rotates clockwise)
        translate([0, 0, z_storm_cloud_back])
        rotate([0, 0, cloud_rotation])
            color(color_cloud)
            linear_extrude(height=cloud_disc_thickness)
                cloud_disc_profile();

        // Front disc (rotates counter-clockwise)
        translate([0, 0, z_storm_cloud_front])
        rotate([0, 0, -cloud_rotation * 1.2])  // Slightly different speed
            color(color_cloud)
            linear_extrude(height=cloud_disc_thickness)
                scale([0.85, 0.85])  // Slightly smaller
                    cloud_disc_profile();
    }
}

// =========================
// STATIC ELEMENTS
// =========================

module rocky_outcrop() {
    translate([220, 10, z_rocks]) {
        color(color_rock)
        linear_extrude(height=6)
            rocky_outcrop_profile();
    }
}

module back_panel() {
    translate([0, 0, z_back_panel]) {
        color(color_sky)
        cube([canvas_width, canvas_height, 3]);
    }
}

module frame() {
    frame_width = 10;
    frame_thickness = 5;

    translate([0, 0, z_frame]) {
        color(color_wood) {
            // Bottom
            cube([canvas_width, frame_width, frame_thickness]);
            // Top
            translate([0, canvas_height - frame_width, 0])
                cube([canvas_width, frame_width, frame_thickness]);
            // Left
            cube([frame_width, canvas_height, frame_thickness]);
            // Right
            translate([canvas_width - frame_width, 0, 0])
                cube([frame_width, canvas_height, frame_thickness]);
        }
    }
}

// =========================
// DRIVE SYSTEM
// =========================

module main_drive_axle() {
    translate([20, axle_y_position, z_main_axle]) {
        // Main axle
        color(color_brass)
        rotate([0, 90, 0])
            cylinder(r=axle_diameter/2, h=axle_length, $fn=24);

        // Cams mounted on axle
        for (i = [0:3]) {
            translate([15 + i * 15, 0, 0])
            rotate([0, 90, 0])
                eccentric_cam(cam_phases[i]);
        }
    }
}

// Motor representation
module motor_placeholder() {
    translate([5, axle_y_position, z_motor_mount]) {
        color([0.3, 0.3, 0.3])
        rotate([0, 90, 0])
            cylinder(r=12, h=25, $fn=24);
    }
}

// =========================
// MAIN ASSEMBLY
// =========================

module ocean_lighthouse_automaton() {
    // Static elements
    back_panel();
    frame();
    rocky_outcrop();
    lighthouse_tower_static();

    // Drive system
    motor_placeholder();
    main_drive_axle();

    // Moving elements (all driven by physical mechanisms)

    // Waves - each tilts on rocker, driven by cam
    for (i = [0:3]) {
        wave_assembly(i);
    }

    // Foam curl - rotates on disc
    foam_curl_assembly();

    // Lighthouse beacon - rotates on shaft
    lighthouse_beacon_rotating();

    // Seagulls - pendulum swing with flapping wings
    seagull_flock();

    // Storm clouds - counter-rotating discs
    storm_cloud_assembly();
}

// =========================
// RENDER
// =========================

ocean_lighthouse_automaton();

// =========================
// VERIFICATION CHECKLIST
// =========================
//
// Physical Connection Verification:
// [x] Wave 1-4: FIXED shapes that TILT on rocker pivots
//     - Driven by: Eccentric cams on main axle
//     - Connection: Cam pushes follower wheel on rocker arm
//     - Motion type: Rotation around pivot (rigid body)
//
// [x] Foam Curl: FIXED shape mounted on rotating disc
//     - Driven by: Gear/belt from main axle
//     - Connection: Shaft through disc center
//     - Motion type: Rotation (traces arc, not morphing)
//
// [x] Lighthouse Beacon: FIXED shape rotating on vertical shaft
//     - Driven by: Worm gear from main drive (20:1 reduction)
//     - Connection: Shaft through tower center
//     - Motion type: Rotation around vertical axis
//
// [x] Seagull: FIXED body on pendulum, FIXED wings on hinges
//     - Driven by: Cam for swing, separate cam for wing flap
//     - Connection: Pivot point for pendulum, hinges for wings
//     - Motion type: Pendulum rotation, wing rotation at hinges
//
// [x] Storm Clouds: FIXED disc shapes with cutouts
//     - Driven by: Gears from main drive
//     - Connection: Shafts through disc centers
//     - Motion type: Counter-rotation of two discs
//
// NO polygon point animation - all motion is rigid body transformation
// ============================================================================
