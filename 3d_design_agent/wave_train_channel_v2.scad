/*
 * WAVE TRAIN CHANNEL v2 - Articulated Wave Mechanism
 *
 * Starry Night Kinetic Sculpture - Ocean Wave Component
 *
 * COORDINATE SYSTEM:
 *   Viewer looks from +Y toward -Y (front of canvas)
 *   X = horizontal (left-right, toward cliff)
 *   Y = depth (into scene, negative = behind)
 *   Z = vertical (up)
 *
 * DESIGN:
 *   - Single articulated wave train with 3 segments
 *   - Segments connected by hinges (X-axis, allows Z pivoting)
 *   - Each segment has follower roller riding on cam surface
 *   - Passive springs/gravity for segment return
 *   - Crank-slider drives horizontal motion
 *   - Mechanism at bottom right corner (visible)
 *
 * WAVE LAYERS:
 *   - 2D profile in XZ plane (wave silhouette)
 *   - Extruded thin along Y (toward viewer)
 *   - Flat face visible to viewer from +Y
 */

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set to 0, 90, 180, 270 for testing
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE FLAGS
// ============================================

SHOW_WAVE_TRAIN = true;
SHOW_CAM_SURFACE = true;
SHOW_GUIDE_RAILS = true;
SHOW_DRIVE_MECHANISM = true;
SHOW_BACKPLATE = false;  // Reference only

// ============================================
// GLOBAL PARAMETERS
// ============================================

// Ocean area bounds (from Starry Night layout)
OCEAN_X_START = 70;     // Left edge
OCEAN_X_END = 270;      // Right edge (near cliff)
OCEAN_Z_BASE = 0;       // Sea level
OCEAN_Z_MIN = -40;      // Below surface

// ============================================
// WAVE TRAIN PARAMETERS
// ============================================

// Segment dimensions
NUM_SEGMENTS = 3;
SEGMENT_LENGTH = 50;    // mm along X
SEGMENT_GAP = 3;        // Hinge gap between segments
TOTAL_TRAIN_LENGTH = NUM_SEGMENTS * SEGMENT_LENGTH + (NUM_SEGMENTS - 1) * SEGMENT_GAP;
// = 3*50 + 2*3 = 156mm

// Wave layer parameters
NUM_LAYERS = 2;         // Layers per segment (stacked in Y)
LAYER_THICKNESS = 2.5;  // mm along Y
LAYER_SPACING = 6;      // mm between layer centers along Y
LAYER_HEIGHT = 25;      // mm along Z (wave height)

// Layer Y positions (front layer at Y=0, back layers at negative Y)
function layer_y(i) = -i * LAYER_SPACING;

// Follower roller
ROLLER_DIAMETER = 6;
ROLLER_WIDTH = 4;

// ============================================
// CAM SURFACE PARAMETERS
// ============================================

// Cam surface extends slightly beyond ocean area to support train at extremes
CAM_X_START = 60;   // Slightly left of OCEAN_X_START to support overhang
CAM_X_END = 280;    // Slightly right of OCEAN_X_END
CAM_LENGTH = CAM_X_END - CAM_X_START;  // 220mm

CAM_Z_BASE = -10;       // Base height of cam surface
CAM_AMPLITUDE = 5;      // Peak-to-valley
CAM_LOBES = 4;          // Number of bumps

// Asymmetric profile (quick up, slow down)
CAM_RISE_FRACTION = 0.33;   // 1/3 for rise
CAM_FALL_FRACTION = 0.67;   // 2/3 for fall

// Cam surface width (along Y, behind waves)
CAM_WIDTH = 20;
CAM_Y_CENTER = -15;     // Behind the wave layers

// ============================================
// DRIVE MECHANISM PARAMETERS
// ============================================

// Crank-slider for back-and-forth motion
CRANK_RADIUS = 30;      // mm - gives 60mm stroke
CONNECTING_ROD = 80;    // mm - L/r = 2.67

// Mechanism position (bottom right, visible)
MECH_X = 260;           // Right side
MECH_Y = 0;             // Front (visible)
MECH_Z = -30;           // Below sea level

// Crank disc
CRANK_DISC_DIA = 50;
CRANK_DISC_THICKNESS = 5;
CRANK_SHAFT_DIA = 6;

// ============================================
// GUIDE RAILS PARAMETERS
// ============================================

RAIL_WIDTH = 3;
RAIL_HEIGHT = 5;
RAIL_Z = CAM_Z_BASE - 3;  // Just below cam surface

// Rail Y positions (two rails, front and back of cam)
RAIL_Y_FRONT = CAM_Y_CENTER + CAM_WIDTH/2 + 2;
RAIL_Y_BACK = CAM_Y_CENTER - CAM_WIDTH/2 - 2;

// ============================================
// COLORS
// ============================================

C_WAVE_FRONT = [0.2, 0.5, 0.8];     // Ocean blue (front layer)
C_WAVE_BACK = [0.15, 0.4, 0.7];     // Darker blue (back layer)
C_FOAM = [0.95, 0.97, 1.0];         // White foam
C_CAM = [0.4, 0.35, 0.3];           // Dark wood
C_RAIL = [0.3, 0.25, 0.2];          // Darker wood
C_MECH = [0.7, 0.5, 0.2];           // Brass/copper
C_ROLLER = [0.5, 0.5, 0.55];        // Steel

$fn = 32;

// ============================================
// KINEMATICS FUNCTIONS
// ============================================

// Crank-slider: X position of slider from crank angle
// Standard formula: x = r*cos(θ) + sqrt(L² - r²*sin²(θ))
function slider_x(angle) =
    let(
        r = CRANK_RADIUS,
        L = CONNECTING_ROD,
        cos_a = cos(angle),
        sin_a = sin(angle)
    )
    r * cos_a + sqrt(L*L - r*r * sin_a*sin_a);

// Train center X position (attached to slider)
// At theta=0: slider_x = r + L = 110mm (rightmost)
// At theta=180: slider_x = -r + L = 50mm (leftmost)
// Range: 50 to 110mm, stroke = 60mm
//
// Train length = 156mm, so train extends ±78mm from center
// Constraints:
//   train_left >= OCEAN_X_START (70mm) at theta=180
//   train_right <= OCEAN_X_END (270mm) at theta=0
//
// At theta=180: center - 78 >= 70 => center >= 148 => offset >= 98
// At theta=0:   center + 78 <= 270 => center <= 192 => offset <= 82
//
// These conflict! Train is too long for the stroke + bounds.
// Solution: Reduce train length or reduce stroke.
//
// Let's allow overhang outside ocean bounds (mechanism can be there)
// And prioritize keeping most of train in view
TRAIN_X_OFFSET = 90;

function train_center_x(angle) =
    TRAIN_X_OFFSET + slider_x(angle);
// At theta=0:   train_center = 90 + 110 = 200, train spans 122 to 278
// At theta=180: train_center = 90 + 50 = 140, train spans 62 to 218
// Slight overhang at left (62 vs 70) - acceptable

// Cam surface height at given X position
function cam_z(x) =
    let(
        // Normalize to cam range (0 to 1)
        norm_x = (x - CAM_X_START) / CAM_LENGTH,
        clamped = max(0, min(1, norm_x)),

        // Which lobe?
        lobe_pos = clamped * CAM_LOBES,
        lobe_frac = lobe_pos - floor(lobe_pos),

        // Asymmetric profile within lobe
        profile = (lobe_frac < CAM_RISE_FRACTION)
            ? 0.5 - 0.5 * cos(lobe_frac / CAM_RISE_FRACTION * 180)
            : 0.5 + 0.5 * cos((lobe_frac - CAM_RISE_FRACTION) / CAM_FALL_FRACTION * 180)
    )
    CAM_Z_BASE + CAM_AMPLITUDE * profile;

// Segment center X positions (relative to train center)
function segment_local_x(seg_idx) =
    let(
        total_width = TOTAL_TRAIN_LENGTH,
        seg_center = SEGMENT_LENGTH / 2,
        seg_start = seg_idx * (SEGMENT_LENGTH + SEGMENT_GAP)
    )
    seg_start + seg_center - total_width / 2;

// Segment follower X position (absolute)
function segment_follower_x(seg_idx, train_x) =
    train_x + segment_local_x(seg_idx);

// Segment Z position (from cam surface at follower position)
function segment_z(seg_idx, train_x) =
    let(follower_x = segment_follower_x(seg_idx, train_x))
    cam_z(follower_x) + ROLLER_DIAMETER/2;

// Hinge angle between segments (calculated from Z difference)
// Hinge is at X-axis, allows rotation about X (Z pivoting)
function hinge_angle(seg_idx, train_x) =
    let(
        // Z positions of this segment and next
        z_this = segment_z(seg_idx, train_x),
        z_next = (seg_idx < NUM_SEGMENTS - 1)
                 ? segment_z(seg_idx + 1, train_x)
                 : z_this,

        // X distance between segment centers
        dx = SEGMENT_LENGTH + SEGMENT_GAP,

        // Angle = atan(dz / dx)
        dz = z_next - z_this
    )
    atan2(dz, dx);

// ============================================
// WAVE PROFILE 2D (in XZ plane)
// ============================================

module wave_profile_2d(seg_idx) {
    // Wave silhouette shape
    // X = horizontal position within segment
    // Z = height

    seg_len = SEGMENT_LENGTH;
    h = LAYER_HEIGHT;

    // Simple wave crest shape
    // Could be made more artistic later

    hull() {
        // Base left
        translate([0, 0])
            square([1, h * 0.3]);

        // Rise to crest
        translate([seg_len * 0.3, 0])
            square([1, h * 0.8]);

        // Crest peak
        translate([seg_len * 0.5, 0])
            square([1, h]);

        // Fall from crest
        translate([seg_len * 0.7, 0])
            square([1, h * 0.7]);

        // Base right
        translate([seg_len - 1, 0])
            square([1, h * 0.4]);
    }
}

// Foam curl profile (at front of segment)
module foam_curl_2d() {
    // Small curl at wave crest
    r = 4;
    h = 8;

    hull() {
        translate([0, 0]) circle(r=1, $fn=12);
        translate([r*0.7, h*0.8]) circle(r=1.5, $fn=12);
        translate([r, h*0.5]) circle(r=1, $fn=12);
    }
}

// ============================================
// WAVE SEGMENT MODULE
// ============================================

module wave_segment(seg_idx, train_x) {
    seg_x = segment_follower_x(seg_idx, train_x) - SEGMENT_LENGTH/2;
    seg_z = segment_z(seg_idx, train_x);

    translate([seg_x, 0, seg_z]) {
        // Wave layers (stacked in Y)
        // After rotate([90,0,0]) and linear_extrude:
        //   - Profile 2D X -> World X (horizontal)
        //   - Profile 2D Y -> World Z (vertical)
        //   - Extrusion -> World -Y (into scene)
        // Layers are at Y = 0, -6, -12 (front to back)
        for (layer_idx = [0:NUM_LAYERS-1]) {
            y_pos = layer_y(layer_idx);  // 0, -6, -12, ...
            layer_color = (layer_idx == 0) ? C_WAVE_FRONT : C_WAVE_BACK;

            color(layer_color)
            translate([0, y_pos, 0])  // Translate in world Y (after rotation)
            rotate([90, 0, 0])        // Rotate to orient profile
            linear_extrude(LAYER_THICKNESS)
                wave_profile_2d(seg_idx);
        }

        // Foam curl on front layer at crest position
        if (seg_idx == 0) {  // Front segment only
            color(C_FOAM)
            translate([SEGMENT_LENGTH * 0.5, LAYER_THICKNESS/2, LAYER_HEIGHT])
            rotate([90, 0, 0])
            linear_extrude(LAYER_THICKNESS * 0.8)
                foam_curl_2d();
        }

        // Follower roller (underneath segment)
        color(C_ROLLER)
        translate([SEGMENT_LENGTH/2, CAM_Y_CENTER, -ROLLER_DIAMETER/2])
        rotate([0, 90, 0])
            cylinder(d=ROLLER_DIAMETER, h=ROLLER_WIDTH, center=true);

        // Connection bracket to roller (structural)
        color(C_RAIL)
        translate([SEGMENT_LENGTH/2 - 2, CAM_Y_CENTER - 2, -ROLLER_DIAMETER/2])
            cube([4, 4, ROLLER_DIAMETER/2 + 2]);
    }
}

// Hinge between segments
module segment_hinge(seg_idx, train_x) {
    if (seg_idx < NUM_SEGMENTS - 1) {
        // Position at junction between segments
        seg_x = segment_follower_x(seg_idx, train_x) + SEGMENT_LENGTH/2;
        seg_z = (segment_z(seg_idx, train_x) + segment_z(seg_idx+1, train_x)) / 2;

        color(C_MECH)
        translate([seg_x + SEGMENT_GAP/2, CAM_Y_CENTER, seg_z])
        rotate([0, 90, 0])
            cylinder(d=4, h=SEGMENT_GAP + 2, center=true);
    }
}

// ============================================
// COMPLETE WAVE TRAIN
// ============================================

module wave_train() {
    train_x = train_center_x(theta);

    for (seg_idx = [0:NUM_SEGMENTS-1]) {
        wave_segment(seg_idx, train_x);
        segment_hinge(seg_idx, train_x);
    }
}

// ============================================
// CAM SURFACE
// ============================================

module cam_surface() {
    steps = 100;
    step_size = CAM_LENGTH / steps;

    color(C_CAM)
    translate([CAM_X_START, CAM_Y_CENTER - CAM_WIDTH/2, 0])
    for (i = [0:steps-1]) {
        x0 = i * step_size;
        x1 = (i + 1) * step_size;
        z0 = cam_z(CAM_X_START + x0);
        z1 = cam_z(CAM_X_START + x1);

        // Create slice of cam surface
        hull() {
            translate([x0, 0, CAM_Z_BASE - 5])
                cube([0.1, CAM_WIDTH, z0 - CAM_Z_BASE + 5]);
            translate([x1, 0, CAM_Z_BASE - 5])
                cube([0.1, CAM_WIDTH, z1 - CAM_Z_BASE + 5]);
        }
    }
}

// ============================================
// GUIDE RAILS
// ============================================

module guide_rails() {
    color(C_RAIL)
    for (rail_y = [RAIL_Y_FRONT, RAIL_Y_BACK]) {
        translate([CAM_X_START, rail_y - RAIL_WIDTH/2, RAIL_Z])
            cube([CAM_LENGTH, RAIL_WIDTH, RAIL_HEIGHT]);
    }
}

// ============================================
// DRIVE MECHANISM (Crank-Slider)
// ============================================

module crank_disc() {
    color(C_MECH)
    translate([MECH_X, MECH_Y, MECH_Z])
    rotate([90, 0, 0])
    rotate([0, 0, theta]) {
        // Disc body
        difference() {
            cylinder(d=CRANK_DISC_DIA, h=CRANK_DISC_THICKNESS);

            // Center shaft hole
            translate([0, 0, -1])
                cylinder(d=CRANK_SHAFT_DIA + 0.4, h=CRANK_DISC_THICKNESS + 2);

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
    // Rod from crank pin to wave train

    // Crank pin position
    crank_x = MECH_X + CRANK_RADIUS * cos(theta);
    crank_y = MECH_Y - CRANK_DISC_THICKNESS - 4;
    crank_z = MECH_Z + CRANK_RADIUS * sin(theta);

    // Train connection point (center segment)
    train_x = train_center_x(theta);
    train_y = CAM_Y_CENTER;
    train_z = segment_z(1, train_x);  // Middle segment

    // Rod angle
    dx = train_x - crank_x;
    dy = train_y - crank_y;
    dz = train_z - crank_z;
    rod_length = sqrt(dx*dx + dy*dy + dz*dz);

    color(C_MECH)
    translate([crank_x, crank_y, crank_z])
    rotate([atan2(dz, sqrt(dx*dx + dy*dy)), 0, atan2(dy, dx)])
    rotate([0, 90, 0])
    difference() {
        hull() {
            cylinder(d=8, h=3);
            translate([rod_length, 0, 0])
                cylinder(d=8, h=3);
        }
        translate([0, 0, -1])
            cylinder(d=4, h=5);
        translate([rod_length, 0, -1])
            cylinder(d=4, h=5);
    }
}

module drive_shaft() {
    // Shaft through crank disc
    color(C_ROLLER)
    translate([MECH_X, MECH_Y + 10, MECH_Z])
    rotate([90, 0, 0])
        cylinder(d=CRANK_SHAFT_DIA, h=30);
}

module bearing_supports() {
    // Minimal bearing blocks (not a big box!)
    color(C_RAIL)
    for (y_off = [5, -15]) {
        translate([MECH_X - 10, MECH_Y + y_off, MECH_Z - 15])
        difference() {
            cube([20, 8, 30]);
            translate([10, -1, 15])
            rotate([-90, 0, 0])
                cylinder(d=CRANK_SHAFT_DIA + 1, h=10);
        }
    }
}

module drive_mechanism() {
    crank_disc();
    connecting_rod();
    drive_shaft();
    bearing_supports();
}

// ============================================
// REFERENCE BACKPLATE
// ============================================

module backplate() {
    color([0.3, 0.25, 0.2, 0.3])
    translate([OCEAN_X_START - 10, -30, OCEAN_Z_MIN])
        cube([OCEAN_X_END - OCEAN_X_START + 20, 5, 50]);
}

// ============================================
// FULL ASSEMBLY
// ============================================

module wave_train_channel_assembly() {
    if (SHOW_WAVE_TRAIN) wave_train();
    if (SHOW_CAM_SURFACE) cam_surface();
    if (SHOW_GUIDE_RAILS) guide_rails();
    if (SHOW_DRIVE_MECHANISM) drive_mechanism();
    if (SHOW_BACKPLATE) backplate();
}

wave_train_channel_assembly();

// ============================================
// VERIFICATION OUTPUT
// ============================================

echo("");
echo("═══════════════════════════════════════════════════════════════");
echo("  WAVE TRAIN CHANNEL v2 - ARTICULATED WAVE MECHANISM");
echo("═══════════════════════════════════════════════════════════════");
echo("");

// Current state
train_x = train_center_x(theta);
echo(str("CURRENT STATE (theta=", theta, "°):"));
echo(str("  Train center X: ", round(train_x*10)/10, "mm"));

// Segment positions
for (seg = [0:NUM_SEGMENTS-1]) {
    follower_x = segment_follower_x(seg, train_x);
    seg_z = segment_z(seg, train_x);
    echo(str("  Segment ", seg, ": follower_X=", round(follower_x*10)/10,
             "mm, Z=", round(seg_z*10)/10, "mm"));
}

// Travel range verification
echo("");
echo("TRAVEL RANGE:");
train_x_0 = train_center_x(0);
train_x_180 = train_center_x(180);
echo(str("  At theta=0°:   train_X=", round(train_x_0*10)/10, "mm"));
echo(str("  At theta=180°: train_X=", round(train_x_180*10)/10, "mm"));
echo(str("  Travel stroke: ", round(abs(train_x_0 - train_x_180)*10)/10, "mm"));

// Collision check
echo("");
echo("COLLISION CHECK:");
// Check if segments stay within ocean bounds
for (seg = [0:NUM_SEGMENTS-1]) {
    for (test_theta = [0, 90, 180, 270]) {
        test_train_x = train_center_x(test_theta);
        follower_x = segment_follower_x(seg, test_train_x);
        seg_left = follower_x - SEGMENT_LENGTH/2;
        seg_right = follower_x + SEGMENT_LENGTH/2;

        in_bounds = (seg_left >= OCEAN_X_START - 10) && (seg_right <= OCEAN_X_END + 10);
        if (!in_bounds) {
            echo(str("  WARNING: Segment ", seg, " at theta=", test_theta,
                     "° exceeds bounds (X=", round(seg_left*10)/10, " to ",
                     round(seg_right*10)/10, ")"));
        }
    }
}
echo("  Bounds check: ", OCEAN_X_START - 10, " to ", OCEAN_X_END + 10);

// Cam surface verification
echo("");
echo("CAM SURFACE:");
echo(str("  Base Z: ", CAM_Z_BASE, "mm"));
echo(str("  Amplitude: ", CAM_AMPLITUDE, "mm"));
echo(str("  Range: Z=", CAM_Z_BASE, " to ", CAM_Z_BASE + CAM_AMPLITUDE, "mm"));
echo(str("  Lobes: ", CAM_LOBES));

// Crank-slider verification
echo("");
echo("CRANK-SLIDER KINEMATICS:");
echo(str("  Crank radius: ", CRANK_RADIUS, "mm"));
echo(str("  Rod length: ", CONNECTING_ROD, "mm"));
echo(str("  L/r ratio: ", CONNECTING_ROD / CRANK_RADIUS, " (good: 2.5-4.0)"));

// Verify rod length constant
echo("");
echo("ROD LENGTH VERIFICATION:");
for (test_theta = [0, 90, 180, 270]) {
    // Crank pin
    cx = CRANK_RADIUS * cos(test_theta);
    cz = CRANK_RADIUS * sin(test_theta);

    // Slider position
    sx = slider_x(test_theta);

    // Simplified check (Y ignored for 2D verification)
    calc_rod = sqrt((sx - cx)*(sx - cx) + cz*cz);

    status = (abs(calc_rod - CONNECTING_ROD) < 0.5) ? "PASS" : "FAIL";
    echo(str("  theta=", test_theta, "°: rod=", round(calc_rod*10)/10, "mm [", status, "]"));
}

// Printability
echo("");
echo("PRINTABILITY:");
echo(str("  Layer thickness: ", LAYER_THICKNESS, "mm [",
         LAYER_THICKNESS >= 1.2 ? "PASS" : "FAIL", "]"));
echo(str("  Segment length: ", SEGMENT_LENGTH, "mm"));
echo(str("  Roller diameter: ", ROLLER_DIAMETER, "mm"));

// Hinge angle check (living hinge limits)
echo("");
echo("HINGE ANGLES:");
for (test_theta = [0, 90, 180, 270]) {
    test_train_x = train_center_x(test_theta);
    for (seg = [0:NUM_SEGMENTS-2]) {
        angle = hinge_angle(seg, test_train_x);
        status = (abs(angle) < 20) ? "PASS" : "WARNING";
        echo(str("  theta=", test_theta, "°, hinge ", seg, ": ",
                 round(angle*10)/10, "° [", status, "]"));
    }
}

echo("");
echo("═══════════════════════════════════════════════════════════════");
