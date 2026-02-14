/*
 * WAVE OCEAN v3 - STL Wave Import with Kinetic Mechanism
 *
 * Starry Night Kinetic Sculpture - Ocean Wave Component
 * USER-PROVIDED STL WAVES + CRANK-SLIDER MECHANISM
 *
 * COORDINATE SYSTEM:
 *   Viewer looks from +Y toward -Y (front of canvas)
 *   X = horizontal (left = cliff side, right = open ocean)
 *   Y = depth (negative = behind, toward backplate)
 *   Z = vertical (up)
 *
 * WAVE LAYERS (from STL, rotated 90° on X):
 *   STL Z-layers become Y-depth layers after rotation
 *   Front (Y≈0) → Back (Y≈-100) as viewer sees it
 */

$fn = 32;

// ============================================
// ANIMATION CONTROL
// ============================================

MANUAL_ANGLE = -1;  // Set to 0, 90, 180, 270 for testing. -1 = animate
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE FLAGS
// ============================================

SHOW_STL_WAVES = true;      // User-provided STL waves
SHOW_TRACK = true;          // Cam track mechanism
SHOW_DRIVE_MECHANISM = true; // Crank-slider drive
SHOW_DEBUG_MARKERS = false;  // Show reference markers

// ============================================
// STL WAVE IMPORT
// ============================================
STL_WAVE_PATH = "C:/Users/abhis/OneDrive/Documents/Ref/Van gogh/HORIZONTAL WAVWAS/Wvaves main2.stl";
DISCOVER_STL_BOUNDS = true; // Set true to visualize bounding box

// ============================================
// STL WAVE LAYER CATALOG
// ============================================
//
// STL FILE: Wvaves main2.stl (147KB)
// Original STL bounding box:
//   X: 1.13 to 7.73mm (width: 6.60mm)
//   Y: -5.81 to -3.81mm (depth: 1.99mm)
//   Z: 1.82 to 4.82mm (height: 3.00mm)
//
// TRANSFORMATION:
//   1. Rotate 90° on X-axis: Z becomes -Y (depth)
//   2. Scale to fit ocean area (220mm target width)
//   3. Position in scene
//
// AFTER ROTATION (viewer's POV):
//   X = horizontal wave extent (scaled to 220mm)
//   Y = layer depth (front to back, 0 to -100mm)
//   Z = wave height (scaled proportionally)
//
// LAYER ORDER (front to back after rotation):
//   Front (Y≈0):   Top of STL (Z=4.82) - foam crests
//   Middle:        Mid STL layers
//   Back (Y≈-100): Bottom of STL (Z=1.82) - deep ocean
//

// ============================================
// GLOBAL PARAMETERS
// ============================================

// Ocean area bounds
OCEAN_X_START = 0;      // Left edge (cliff side)
OCEAN_X_END = 220;      // Right edge
OCEAN_Z_BASE = 0;       // Sea level reference

// Layer thickness
LAYER_THICKNESS = 3;    // mm (along Y)

// ============================================
// MAIN WAVE LAYER PARAMETERS
// ============================================

MAIN_WAVE_WIDTH = 220;  // mm along X
MAIN_WAVE_THICKNESS = LAYER_THICKNESS;

// Main wave profile control points (X, Z) in mm
// Based on reference image silhouette
MAIN_WAVE_PROFILE = [
    // Left edge (cliff side) - lower
    [0, 8],
    [10, 10],
    [20, 14],

    // First crest
    [30, 20],
    [40, 26],      // First peak
    [50, 24],

    // Trough
    [60, 18],
    [70, 14],
    [80, 11],
    [90, 10],      // Trough bottom
    [100, 11],
    [110, 14],

    // Second crest (tallest)
    [120, 18],
    [130, 23],
    [140, 28],
    [150, 32],
    [160, 35],     // Second peak (tallest)
    [170, 33],
    [180, 28],

    // Descending tail
    [190, 22],
    [200, 17],
    [210, 14],
    [220, 12]
];

// Flex zone positions (X coordinates where living hinges go)
FLEX_ZONE_1_X = 55;    // Between first crest and trough
FLEX_ZONE_2_X = 105;   // At trough low point
FLEX_ZONE_3_X = 175;   // After second crest peak

FLEX_ZONE_WIDTH = 4;   // mm wide
FLEX_ZONE_THICKNESS = 0.5;  // mm thin (living hinge)

// Main wave follower positions (one per rigid section)
// Section 1: X = 0 to 55 (follower at 25)
// Section 2: X = 55 to 105 (follower at 80)
// Section 3: X = 105 to 175 (follower at 140)
// Section 4: X = 175 to 220 (follower at 195)
FOLLOWER_POSITIONS = [25, 80, 140, 195];
FOLLOWER_DIAMETER = 6;

// ============================================
// RED ATTACHED WAVE PARAMETERS
// ============================================

// Each RED component: [x_pos, width, height, hinge_axis, swing_direction]
// hinge_axis: "Y" = swing in XZ plane, "X" = bob up/down
// swing_direction: 1 = toward cliff, -1 = away from cliff
RED_COMPONENTS = [
    [45, 15, 12, "Y", 1],     // R1: near first crest, swing toward cliff
    [85, 20, 15, "Y", -1],    // R2: in trough, swing away
    [130, 25, 18, "Y", 1],    // R3: rising to second crest, swing toward cliff
    [175, 18, 14, "Y", -1],   // R4: past second crest, swing away
    [200, 12, 10, "Y", -1]    // R5: tail, small wobble
];

RED_FOLLOWER_ARM_LENGTH = 10;  // mm below wave
RED_FOLLOWER_DIAMETER = 3;
RED_SWING_MAX = 20;  // degrees

// ============================================
// GREEN CURL TIP PARAMETERS
// ============================================

// Each GREEN curl: [x_pos, size, facing_direction]
// facing_direction: 1 = curl toward cliff, -1 = curl away
GREEN_CURLS = [
    [40, 10, 1],    // Curl 1: top of first crest
    [65, 8, -1],    // Curl 2: small crest (between first and trough)
    [155, 12, 1],   // Curl 3: peak of second crest
    [195, 8, -1]    // Curl 4: rear crest
];

CURL_FOLLOWER_ARM_LENGTH = 15;  // mm below curl
CURL_FOLLOWER_DIAMETER = 4;
CURL_MAX_ANGLE = 40;  // degrees

// ============================================
// BACKGROUND LAYER PARAMETERS (PARALLAX)
// ============================================

// Layer scales and strokes (relative to main)
LAYER_2_SCALE = 0.8;
LAYER_3_SCALE = 0.5;
HORIZON_SCALE = 1.0;  // Full width but simple

LAYER_2_STROKE_RATIO = 0.75;
LAYER_3_STROKE_RATIO = 0.5;
HORIZON_STROKE_RATIO = 0.25;

// Y positions (front to back)
LAYER_Y_MAIN = 0;
LAYER_Y_2 = -8;
LAYER_Y_3 = -16;
LAYER_Y_HORIZON = -24;

// ============================================
// YELLOW SURGE WAVE PARAMETERS
// ============================================

// Each surge: [x_pos, height, phase_offset]
YELLOW_SURGES = [
    [60, 20, 0],      // Surge 1
    [140, 25, 90],    // Surge 2 (90 degree phase offset)
    [200, 18, 180]    // Surge 3 (180 degree phase offset)
];

SURGE_MAX_ANGLE = 45;  // degrees
SURGE_PIVOT_Z = 45;    // Z position of surge pivot (above main waves)

// ============================================
// TRACK / CHANNEL PARAMETERS
// ============================================

TRACK_X_START = -20;
TRACK_X_END = 240;
TRACK_LENGTH = TRACK_X_END - TRACK_X_START;
TRACK_WIDTH = 30;  // Along Y
TRACK_Y_CENTER = -15;

// Main cam surface
CAM_Z_BASE = -15;
CAM_AMPLITUDE = 6;
CAM_LOBES = 4;
CAM_RISE_FRACTION = 0.33;  // Quick up
CAM_FALL_FRACTION = 0.67;  // Slow down

// Curl/RED bump positions and heights
// These are ABSOLUTE X positions on track
CURL_BUMP_POSITIONS = [120, 150, 185, 215];  // Where curl followers will pass
CURL_BUMP_AMPLITUDE = 4;

RED_BUMP_POSITIONS = [130, 160, 190, 210, 225];  // Where RED followers will pass
RED_BUMP_AMPLITUDE = 3;

// Guide rails
RAIL_WIDTH = 3;
RAIL_HEIGHT = 5;
RAIL_Z = CAM_Z_BASE - 3;

// ============================================
// DRIVE MECHANISM PARAMETERS
// ============================================

// Crank-slider for main wave horizontal motion
CRANK_RADIUS = 30;      // 60mm stroke
CONNECTING_ROD = 80;    // L/r = 2.67
MECH_X = 250;           // Right side, visible
MECH_Y = -10;
MECH_Z = -25;

CRANK_DISC_DIA = 50;
CRANK_DISC_THICKNESS = 5;
SHAFT_DIA = 6;

// Eccentric cam for surge waves
ECCENTRIC_OFFSET = 8;   // mm offset from center
ECCENTRIC_PHASE = 75;   // degrees offset from main crank

// ============================================
// COLORS
// ============================================

C_MAIN_WAVE = [0.2, 0.5, 0.8];      // Ocean blue
C_LAYER_2 = [0.18, 0.45, 0.75];     // Slightly darker
C_LAYER_3 = [0.15, 0.4, 0.7];       // Deeper blue
C_HORIZON = [0.12, 0.35, 0.6];      // Deep blue
C_FOAM = [0.95, 0.97, 1.0];         // White foam
C_RED_WAVE = [0.3, 0.55, 0.85];     // Blue (attached waves)
C_SURGE = [0.4, 0.6, 0.9];          // Light blue surge
C_CAM = [0.4, 0.35, 0.3];           // Dark wood
C_MECH = [0.7, 0.5, 0.2];           // Brass
C_RAIL = [0.3, 0.25, 0.2];          // Dark wood
C_ROLLER = [0.5, 0.5, 0.55];        // Steel

// ============================================
// KINEMATICS FUNCTIONS
// ============================================

// Crank-slider: X position of slider from crank angle
function slider_x(angle) =
    let(
        r = CRANK_RADIUS,
        L = CONNECTING_ROD,
        cos_a = cos(angle),
        sin_a = sin(angle)
    )
    r * cos_a + sqrt(L*L - r*r * sin_a*sin_a);

// Main wave origin X (attached to slider)
// At theta=0: slider_x = r + L = 110mm (rightmost)
// At theta=180: slider_x = -r + L = 50mm (leftmost)
WAVE_X_OFFSET = 60;  // Centers the wave in ocean area

function wave_origin_x(angle) = WAVE_X_OFFSET + slider_x(angle);
// At theta=0: origin = 60 + 110 = 170
// At theta=180: origin = 60 + 50 = 110
// Stroke: 60mm

// Parallax layer origins (different amounts of travel)
function layer_2_origin_x(angle) =
    WAVE_X_OFFSET + slider_x(angle) * LAYER_2_STROKE_RATIO;

function layer_3_origin_x(angle) =
    WAVE_X_OFFSET + slider_x(angle) * LAYER_3_STROKE_RATIO;

function horizon_origin_x(angle) =
    WAVE_X_OFFSET + slider_x(angle) * HORIZON_STROKE_RATIO;

// Cam surface height at given absolute X position
function cam_z(x) =
    let(
        norm_x = (x - TRACK_X_START) / TRACK_LENGTH,
        clamped = max(0, min(1, norm_x)),
        lobe_pos = clamped * CAM_LOBES,
        lobe_frac = lobe_pos - floor(lobe_pos),
        profile = (lobe_frac < CAM_RISE_FRACTION)
            ? 0.5 - 0.5 * cos(lobe_frac / CAM_RISE_FRACTION * 180)
            : 0.5 + 0.5 * cos((lobe_frac - CAM_RISE_FRACTION) / CAM_FALL_FRACTION * 180)
    )
    CAM_Z_BASE + CAM_AMPLITUDE * profile;

// Get height at specific bump position (for curl/RED actuation)
function curl_bump_height(bump_idx, follower_x) =
    let(
        bump_x = CURL_BUMP_POSITIONS[bump_idx],
        dist = abs(follower_x - bump_x),
        width = 15  // Bump width
    )
    (dist < width)
        ? CURL_BUMP_AMPLITUDE * (1 - dist/width) *
          ((follower_x < bump_x)
            ? sin((1 - dist/width) * 90 / CAM_RISE_FRACTION)  // Quick rise
            : cos((1 - dist/width) * 90))                      // Slow fall
        : 0;

function red_bump_height(bump_idx, follower_x) =
    let(
        bump_x = RED_BUMP_POSITIONS[bump_idx],
        dist = abs(follower_x - bump_x),
        width = 12
    )
    (dist < width)
        ? RED_BUMP_AMPLITUDE * (1 - dist/width)
        : 0;

// Interpolate Z height from profile at given X
function profile_z_at_x(profile, x) =
    let(
        n = len(profile),
        // Find bracketing points
        idx = max(0, min(n-2, floor(x / (MAIN_WAVE_WIDTH / (n-1)))))
    )
    (x <= profile[0][0]) ? profile[0][1] :
    (x >= profile[n-1][0]) ? profile[n-1][1] :
    let(
        x0 = profile[idx][0],
        x1 = profile[idx+1][0],
        z0 = profile[idx][1],
        z1 = profile[idx+1][1],
        t = (x - x0) / (x1 - x0)
    )
    z0 + t * (z1 - z0);

// Surge wave angle from eccentric cam
function surge_angle(surge_idx) =
    let(
        phase = YELLOW_SURGES[surge_idx][2],
        effective_angle = theta + ECCENTRIC_PHASE + phase,
        // Asymmetric motion: quick up, slow down
        norm = (effective_angle % 360) / 360,
        profile = (norm < CAM_RISE_FRACTION)
            ? norm / CAM_RISE_FRACTION
            : 1 - (norm - CAM_RISE_FRACTION) / CAM_FALL_FRACTION
    )
    SURGE_MAX_ANGLE * profile;

// ============================================
// COMPONENT 1: MAIN WAVE PROFILE 2D
// ============================================

module main_wave_profile_2d() {
    // Create polygon from control points
    // Add bottom edge to close the shape

    bottom_z = -5;  // Below visible area

    points = concat(
        [[MAIN_WAVE_PROFILE[0][0], bottom_z]],  // Bottom left
        MAIN_WAVE_PROFILE,                        // Top edge (wave profile)
        [[MAIN_WAVE_PROFILE[len(MAIN_WAVE_PROFILE)-1][0], bottom_z]]  // Bottom right
    );

    polygon(points);
}

// Main wave with flex zones (rendered as separate sections)
module main_wave_layer_3d(wave_x_origin) {
    // The wave is divided into sections by flex zones
    // Each section has its own follower riding on the cam

    // Section boundaries
    sections = [
        [0, FLEX_ZONE_1_X],
        [FLEX_ZONE_1_X + FLEX_ZONE_WIDTH, FLEX_ZONE_2_X],
        [FLEX_ZONE_2_X + FLEX_ZONE_WIDTH, FLEX_ZONE_3_X],
        [FLEX_ZONE_3_X + FLEX_ZONE_WIDTH, MAIN_WAVE_WIDTH]
    ];

    for (i = [0:len(sections)-1]) {
        section_x_start = sections[i][0];
        section_x_end = sections[i][1];
        follower_x_local = FOLLOWER_POSITIONS[i];

        // Absolute X of follower
        follower_x_abs = wave_x_origin + follower_x_local;

        // Z offset from cam
        section_z_offset = cam_z(follower_x_abs) - CAM_Z_BASE + FOLLOWER_DIAMETER/2;

        color(C_MAIN_WAVE)
        translate([wave_x_origin + section_x_start, 0, section_z_offset])
        render_wave_section(section_x_start, section_x_end);

        // Follower roller
        if (SHOW_DEBUG_MARKERS) {
            color(C_ROLLER)
            translate([follower_x_abs, TRACK_Y_CENTER, cam_z(follower_x_abs)])
            sphere(d=FOLLOWER_DIAMETER);
        }
    }

    // Flex zones (thin sections connecting the rigid sections)
    for (flex_x = [FLEX_ZONE_1_X, FLEX_ZONE_2_X, FLEX_ZONE_3_X]) {
        // Calculate Z based on adjacent followers
        idx = (flex_x == FLEX_ZONE_1_X) ? 0 :
              (flex_x == FLEX_ZONE_2_X) ? 1 : 2;

        follower_x_before = wave_x_origin + FOLLOWER_POSITIONS[idx];
        follower_x_after = wave_x_origin + FOLLOWER_POSITIONS[idx+1];

        z_before = cam_z(follower_x_before) - CAM_Z_BASE + FOLLOWER_DIAMETER/2;
        z_after = cam_z(follower_x_after) - CAM_Z_BASE + FOLLOWER_DIAMETER/2;

        // Flex zone interpolates between
        flex_z = (z_before + z_after) / 2;

        color(C_MAIN_WAVE, 0.8)
        translate([wave_x_origin + flex_x, 0, flex_z])
        render_flex_zone(flex_x);
    }
}

module render_wave_section(x_start, x_end) {
    // Clip the main wave profile to this section
    section_width = x_end - x_start;

    translate([0, -MAIN_WAVE_THICKNESS/2, 0])
    rotate([90, 0, 0])
    linear_extrude(MAIN_WAVE_THICKNESS)
    intersection() {
        translate([-x_start, 0, 0])
        main_wave_profile_2d();

        square([section_width, 50]);
    }
}

module render_flex_zone(flex_x) {
    // Thin living hinge section
    z_at_flex = profile_z_at_x(MAIN_WAVE_PROFILE, flex_x);

    translate([0, -FLEX_ZONE_THICKNESS/2, 0])
    rotate([90, 0, 0])
    linear_extrude(FLEX_ZONE_THICKNESS)
    square([FLEX_ZONE_WIDTH, z_at_flex + 5]);
}

// ============================================
// STL WAVE IMPORT MODULE (Rotated for Viewer POV)
// ============================================
// Imports user-provided STL and rotates 90° on X-axis
// so Z-layers become Y-depth layers (front to back)

// STL measured dimensions (before transformation)
STL_MEASURED_WIDTH = 6.60;    // mm (X extent in STL)
STL_MEASURED_DEPTH = 1.99;    // mm (Y extent in STL)
STL_MEASURED_HEIGHT = 3.00;   // mm (Z extent in STL)
STL_MIN_X = 1.13;
STL_MAX_X = 7.73;
STL_MIN_Y = -5.81;
STL_MAX_Y = -3.81;
STL_MIN_Z = 1.82;
STL_MAX_Z = 4.82;
STL_CENTER_X = (STL_MIN_X + STL_MAX_X) / 2;  // 4.43
STL_CENTER_Y = (STL_MIN_Y + STL_MAX_Y) / 2;  // -4.81
STL_CENTER_Z = (STL_MIN_Z + STL_MAX_Z) / 2;  // 3.32

// Target dimensions
STL_TARGET_WIDTH = MAIN_WAVE_WIDTH;  // 220mm
STL_SCALE_FACTOR = STL_TARGET_WIDTH / STL_MEASURED_WIDTH;  // ~33.3x

// After 90° X rotation and scaling:
//   Original X → X (width: 220mm)
//   Original Y → Z (becomes height)
//   Original Z → -Y (becomes depth, inverted)
// Scaled depth = STL_MEASURED_HEIGHT * STL_SCALE_FACTOR = 100mm

module wave_stl_imported(wave_x_origin) {
    // Calculate cam-based Z offset for wave height
    mid_x = wave_x_origin + MAIN_WAVE_WIDTH/2;
    z_offset = cam_z(mid_x) - CAM_Z_BASE + FOLLOWER_DIAMETER/2;

    // TRANSFORMATION ORDER (read bottom to top):
    // 5. Final position in scene
    // 4. Adjust Z height
    // 3. Scale uniformly
    // 2. Rotate 90° on X-axis (Z becomes -Y)
    // 1. Center STL at origin

    translate([wave_x_origin, 0, z_offset])
    scale([STL_SCALE_FACTOR, STL_SCALE_FACTOR, STL_SCALE_FACTOR])
    rotate([90, 0, 0])  // Z → -Y (layers become depth)
    translate([-STL_CENTER_X, -STL_CENTER_Y, -STL_CENTER_Z])
    color([0.2, 0.5, 0.8])
    import(STL_WAVE_PATH);

    // Debug visualization
    if (DISCOVER_STL_BOUNDS) {
        // Show target ocean area (red box)
        color("red", 0.1)
        translate([wave_x_origin, -120, 0])
        cube([MAIN_WAVE_WIDTH, 120, 80]);

        // Origin marker (green cylinder)
        color("green")
        translate([wave_x_origin, 0, 0])
        cylinder(d=8, h=60);

        // Front reference plane (Y=0)
        color("yellow", 0.1)
        translate([wave_x_origin, -1, 0])
        cube([MAIN_WAVE_WIDTH, 2, 60]);

        // Echo transformation info
        echo("");
        echo("═══ STL TRANSFORMATION ═══");
        echo(str("Scale: ", STL_SCALE_FACTOR, "x"));
        echo(str("Original: ", STL_MEASURED_WIDTH, " x ", STL_MEASURED_DEPTH, " x ", STL_MEASURED_HEIGHT, " mm"));
        echo(str("After scale: ", STL_MEASURED_WIDTH * STL_SCALE_FACTOR, " x ",
                 STL_MEASURED_DEPTH * STL_SCALE_FACTOR, " x ",
                 STL_MEASURED_HEIGHT * STL_SCALE_FACTOR, " mm"));
        echo("After 90° X rotation:");
        echo(str("  Width (X): ", STL_MEASURED_WIDTH * STL_SCALE_FACTOR, "mm"));
        echo(str("  Depth (Y): ", STL_MEASURED_HEIGHT * STL_SCALE_FACTOR, "mm (layers front→back)"));
        echo(str("  Height (Z): ", STL_MEASURED_DEPTH * STL_SCALE_FACTOR, "mm"));
        echo("Layer order: STL top (foam) → Front (Y≈0), STL bottom (deep) → Back (Y≈-100)");
    }
}

// ============================================
// COMPONENT 2: RED ATTACHED WAVES
// ============================================

module red_attached_wave(idx, wave_x_origin) {
    comp = RED_COMPONENTS[idx];
    local_x = comp[0];
    width = comp[1];
    height = comp[2];
    hinge_axis = comp[3];
    swing_dir = comp[4];

    abs_x = wave_x_origin + local_x;

    // Calculate swing angle from track bumps
    follower_x = abs_x;  // Follower directly below

    // Sum contributions from all RED bumps
    total_bump = 0;
    for (i = [0:len(RED_BUMP_POSITIONS)-1]) {
        total_bump = total_bump + red_bump_height(i, follower_x);
    }

    swing_angle = swing_dir * RED_SWING_MAX * min(1, total_bump / RED_BUMP_AMPLITUDE);

    // Z position based on main wave profile
    base_z = profile_z_at_x(MAIN_WAVE_PROFILE, local_x);

    // Position and rotate
    color(C_RED_WAVE)
    translate([abs_x, 0, base_z + cam_z(abs_x) - CAM_Z_BASE]) {
        if (hinge_axis == "Y") {
            // Swing in XZ plane (rotate about Y)
            rotate([0, 0, swing_angle])
            render_red_wave_shape(width, height);
        } else {
            // Bob up/down (rotate about X)
            rotate([swing_angle, 0, 0])
            render_red_wave_shape(width, height);
        }
    }

    // Debug: show follower
    if (SHOW_DEBUG_MARKERS) {
        color(C_ROLLER)
        translate([abs_x, TRACK_Y_CENTER, CAM_Z_BASE - RED_FOLLOWER_ARM_LENGTH])
        sphere(d=RED_FOLLOWER_DIAMETER);
    }
}

module render_red_wave_shape(width, height) {
    // Small wave cutout shape
    translate([-width/2, -LAYER_THICKNESS/2, 0])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS)
    polygon([
        [0, 0],
        [width * 0.2, height * 0.3],
        [width * 0.5, height],
        [width * 0.8, height * 0.5],
        [width, height * 0.2],
        [width, 0]
    ]);
}

module all_red_attached(wave_x_origin) {
    for (i = [0:len(RED_COMPONENTS)-1]) {
        red_attached_wave(i, wave_x_origin);
    }
}

// ============================================
// COMPONENT 3: GREEN FOAM CURL TIPS
// ============================================

module green_curl_tip(idx, wave_x_origin) {
    curl = GREEN_CURLS[idx];
    local_x = curl[0];
    size = curl[1];
    facing = curl[2];

    abs_x = wave_x_origin + local_x;

    // Calculate curl angle from track bumps
    follower_x = abs_x;

    total_bump = 0;
    for (i = [0:len(CURL_BUMP_POSITIONS)-1]) {
        total_bump = total_bump + curl_bump_height(i, follower_x);
    }

    curl_angle = CURL_MAX_ANGLE * min(1, total_bump / CURL_BUMP_AMPLITUDE);

    // Z position at top of wave profile
    base_z = profile_z_at_x(MAIN_WAVE_PROFILE, local_x);

    // Position curl at top of wave crest
    color(C_FOAM)
    translate([abs_x, LAYER_THICKNESS/2, base_z + cam_z(abs_x) - CAM_Z_BASE]) {
        rotate([facing * curl_angle, 0, 0])
        render_curl_shape(size);
    }

    // Debug: show follower arm
    if (SHOW_DEBUG_MARKERS) {
        color(C_ROLLER)
        translate([abs_x, TRACK_Y_CENTER, CAM_Z_BASE - CURL_FOLLOWER_ARM_LENGTH])
        sphere(d=CURL_FOLLOWER_DIAMETER);
    }
}

module render_curl_shape(size) {
    // Organic foam curl shape
    translate([0, 0, 0])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS * 0.8)
    hull() {
        circle(r=size * 0.3);
        translate([size * 0.4, size * 0.6])
        circle(r=size * 0.25);
        translate([size * 0.6, size * 0.3])
        circle(r=size * 0.15);
    }
}

module all_green_curls(wave_x_origin) {
    for (i = [0:len(GREEN_CURLS)-1]) {
        green_curl_tip(i, wave_x_origin);
    }
}

// ============================================
// COMPONENT 4: BACKGROUND LAYERS (PARALLAX)
// ============================================

module background_layer_2(origin_x) {
    // 80% scale, simpler profile
    color(C_LAYER_2)
    translate([origin_x, LAYER_Y_2, cam_z(origin_x + 110) - CAM_Z_BASE])
    scale([LAYER_2_SCALE, 1, LAYER_2_SCALE])
    translate([0, -LAYER_THICKNESS/2, 0])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS)
    main_wave_profile_2d();
}

module background_layer_3(origin_x) {
    // 50% scale, focused toward cliff (left side)
    color(C_LAYER_3)
    translate([origin_x, LAYER_Y_3, cam_z(origin_x + 60) - CAM_Z_BASE])
    scale([LAYER_3_SCALE, 1, LAYER_3_SCALE])
    translate([0, -LAYER_THICKNESS/2, 0])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS)
    main_wave_profile_2d();
}

module horizon_layer(origin_x) {
    // Simple strip with slight undulation
    color(C_HORIZON)
    translate([origin_x, LAYER_Y_HORIZON, SURGE_PIVOT_Z - 10])
    translate([0, -LAYER_THICKNESS/2, 0])
    rotate([90, 0, 0])
    linear_extrude(LAYER_THICKNESS)
    polygon([
        [0, 0], [220, 0],
        [220, 15], [200, 18], [160, 16], [120, 19], [80, 17], [40, 18], [0, 15]
    ]);
}

module all_background_layers() {
    origin_2 = layer_2_origin_x(theta);
    origin_3 = layer_3_origin_x(theta);
    origin_h = horizon_origin_x(theta);

    background_layer_2(origin_2);
    background_layer_3(origin_3);
    horizon_layer(origin_h);
}

// ============================================
// COMPONENT 5: YELLOW SURGE WAVES
// ============================================

module yellow_surge_wave(idx) {
    surge = YELLOW_SURGES[idx];
    x_pos = surge[0];
    height = surge[1];

    angle = surge_angle(idx);

    // Surge pivots from horizon level
    color(C_SURGE)
    translate([x_pos + horizon_origin_x(theta), LAYER_Y_HORIZON - 2, SURGE_PIVOT_Z]) {
        rotate([angle, 0, 0])
        translate([0, -LAYER_THICKNESS/2, 0])
        rotate([90, 0, 0])
        linear_extrude(LAYER_THICKNESS)
        polygon([
            [-5, 0], [5, 0],
            [8, height * 0.3],
            [6, height * 0.7],
            [0, height],
            [-4, height * 0.6],
            [-6, height * 0.2]
        ]);
    }
}

module all_yellow_surges() {
    for (i = [0:len(YELLOW_SURGES)-1]) {
        yellow_surge_wave(i);
    }
}

// ============================================
// COMPONENT 6: TRACK / CHANNEL
// ============================================

module track_cam_surface() {
    steps = 100;
    step_size = TRACK_LENGTH / steps;

    color(C_CAM)
    translate([TRACK_X_START, TRACK_Y_CENTER - TRACK_WIDTH/2, 0])
    for (i = [0:steps-1]) {
        x0 = i * step_size;
        x1 = (i + 1) * step_size;
        z0 = cam_z(TRACK_X_START + x0);
        z1 = cam_z(TRACK_X_START + x1);

        hull() {
            translate([x0, 0, CAM_Z_BASE - 5])
            cube([0.1, TRACK_WIDTH, z0 - CAM_Z_BASE + 5]);
            translate([x1, 0, CAM_Z_BASE - 5])
            cube([0.1, TRACK_WIDTH, z1 - CAM_Z_BASE + 5]);
        }
    }
}

module track_guide_rails() {
    color(C_RAIL)
    for (y_off = [TRACK_Y_CENTER - TRACK_WIDTH/2 - RAIL_WIDTH,
                  TRACK_Y_CENTER + TRACK_WIDTH/2]) {
        translate([TRACK_X_START, y_off, RAIL_Z])
        cube([TRACK_LENGTH, RAIL_WIDTH, RAIL_HEIGHT]);
    }
}

module track_curl_bumps() {
    // Secondary bumps for curl tips
    color(C_CAM, 0.8)
    for (bump_x = CURL_BUMP_POSITIONS) {
        translate([bump_x, TRACK_Y_CENTER, CAM_Z_BASE - CURL_FOLLOWER_ARM_LENGTH - 5])
        scale([1, 0.5, 1])
        cylinder(d1=15, d2=8, h=CURL_BUMP_AMPLITUDE + 5);
    }
}

module track_assembly() {
    track_cam_surface();
    track_guide_rails();
    track_curl_bumps();
}

// ============================================
// COMPONENT 7: DRIVE MECHANISM
// ============================================

module crank_disc() {
    color(C_MECH)
    translate([MECH_X, MECH_Y, MECH_Z])
    rotate([90, 0, 0])
    rotate([0, 0, theta]) {
        // Disc body
        difference() {
            cylinder(d=CRANK_DISC_DIA, h=CRANK_DISC_THICKNESS);
            translate([0, 0, -1])
            cylinder(d=SHAFT_DIA + 0.4, h=CRANK_DISC_THICKNESS + 2);

            // Decorative cutouts
            for (a = [0:60:300]) {
                rotate([0, 0, a])
                translate([CRANK_DISC_DIA * 0.3, 0, -1])
                cylinder(d=8, h=CRANK_DISC_THICKNESS + 2);
            }
        }

        // Crank pin
        translate([CRANK_RADIUS, 0, CRANK_DISC_THICKNESS])
        cylinder(d=4, h=8);
    }
}

module connecting_rod() {
    // From crank pin to wave
    crank_x = MECH_X + CRANK_RADIUS * cos(theta);
    crank_y = MECH_Y - CRANK_DISC_THICKNESS - 4;
    crank_z = MECH_Z + CRANK_RADIUS * sin(theta);

    wave_x = wave_origin_x(theta) + MAIN_WAVE_WIDTH/2;
    wave_y = TRACK_Y_CENTER;
    wave_z = cam_z(wave_x) + 5;

    dx = wave_x - crank_x;
    dy = wave_y - crank_y;
    dz = wave_z - crank_z;
    rod_length = sqrt(dx*dx + dy*dy + dz*dz);

    color(C_MECH)
    translate([crank_x, crank_y, crank_z])
    rotate([atan2(dz, sqrt(dx*dx + dy*dy)), 0, atan2(dy, dx)])
    rotate([0, 90, 0])
    hull() {
        cylinder(d=6, h=2);
        translate([rod_length, 0, 0])
        cylinder(d=6, h=2);
    }
}

module eccentric_cam() {
    // Eccentric for surge waves
    color(C_MECH, 0.8)
    translate([MECH_X, MECH_Y + 15, MECH_Z])
    rotate([90, 0, 0])
    rotate([0, 0, theta + ECCENTRIC_PHASE]) {
        translate([ECCENTRIC_OFFSET, 0, 0])
        cylinder(d=20, h=3);
    }
}

module drive_shaft() {
    color(C_ROLLER)
    translate([MECH_X, MECH_Y + 20, MECH_Z])
    rotate([90, 0, 0])
    cylinder(d=SHAFT_DIA, h=40);
}

module bearing_supports() {
    color(C_RAIL)
    for (y_off = [5, -20]) {
        translate([MECH_X - 12, MECH_Y + y_off, MECH_Z - 20])
        difference() {
            cube([24, 8, 40]);
            translate([12, -1, 20])
            rotate([-90, 0, 0])
            cylinder(d=SHAFT_DIA + 1, h=10);
        }
    }
}

module drive_mechanism() {
    crank_disc();
    connecting_rod();
    eccentric_cam();
    drive_shaft();
    bearing_supports();
}

// ============================================
// FULL ASSEMBLY
// ============================================

module wave_ocean_v3_assembly() {
    wave_x = wave_origin_x(theta);

    // ════════════════════════════════════════════════════════════
    // USER-PROVIDED STL WAVES (replaces all procedural waves)
    // ════════════════════════════════════════════════════════════
    // - Rotated 90° on X-axis so Z-layers become Y-depth
    // - Front layers (Y≈0) closest to viewer
    // - Back layers (Y≈-100) furthest from viewer
    // - Moves with crank-slider mechanism

    if (SHOW_STL_WAVES) {
        wave_stl_imported(wave_x);
    }

    // ════════════════════════════════════════════════════════════
    // PROCEDURAL WAVES REMOVED - All replaced by STL import above
    // ════════════════════════════════════════════════════════════
    // The following have been removed:
    // - main_wave_layer_3d() - procedural main wave
    // - all_red_attached() - red attached wave cutouts
    // - all_green_curls() - green foam curl tips
    // - all_background_layers() - parallax background layers
    // - all_yellow_surges() - yellow surge waves

    // Track
    if (SHOW_TRACK) {
        track_assembly();
    }

    // Drive mechanism
    if (SHOW_DRIVE_MECHANISM) {
        drive_mechanism();
    }
}

// Render
wave_ocean_v3_assembly();

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("");
echo("═══════════════════════════════════════════════════════════════");
echo("  WAVE OCEAN v3 - COMPONENT VERIFICATION");
echo("═══════════════════════════════════════════════════════════════");
echo("");

// Wave source info
echo("WAVE SOURCE: STL IMPORT (User-provided)");
echo(str("  File: ", STL_WAVE_PATH));
echo(str("  Scale: ", STL_SCALE_FACTOR, "x"));
echo(str("  Rotation: 90° on X-axis (Z→-Y)"));
echo(str("  Discovery: ", DISCOVER_STL_BOUNDS ? "ON" : "OFF"));
echo("");
echo("LAYER ORIENTATION (after rotation):");
echo("  Front (Y≈0): Foam crests (STL top)");
echo("  Back (Y≈-100): Deep ocean (STL bottom)");
echo("");

echo(str("CURRENT ANGLE: theta = ", theta, "°"));
echo("");

// Main wave position
wave_x = wave_origin_x(theta);
echo(str("MAIN WAVE: origin_x = ", round(wave_x*10)/10, "mm"));
echo(str("  Wave spans X = ", round(wave_x*10)/10, " to ", round((wave_x + MAIN_WAVE_WIDTH)*10)/10, "mm"));

// Travel verification
echo("");
echo("TRAVEL RANGE:");
echo(str("  At theta=0°:   wave_x = ", round(wave_origin_x(0)*10)/10, "mm"));
echo(str("  At theta=180°: wave_x = ", round(wave_origin_x(180)*10)/10, "mm"));
echo(str("  Stroke: ", round(abs(wave_origin_x(0) - wave_origin_x(180))*10)/10, "mm"));

// Crank-slider verification
echo("");
echo("CRANK-SLIDER:");
echo(str("  Crank radius: ", CRANK_RADIUS, "mm"));
echo(str("  Rod length: ", CONNECTING_ROD, "mm"));
echo(str("  L/r ratio: ", CONNECTING_ROD / CRANK_RADIUS));

echo("");
echo("═══════════════════════════════════════════════════════════════");
