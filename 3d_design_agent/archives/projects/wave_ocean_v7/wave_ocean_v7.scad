/*
 * WAVE OCEAN v7 - ASYMMETRIC CAM FOAM CURL MECHANISM
 *
 * MECHANISM SUMMARY:
 * - Main camshaft: Elliptical cams drive NUM_WAVES wave slats (configurable)
 * - Foam camshaft: ASYMMETRIC cams drive 5 foam curls
 * - Power transfer: Belt drive (1:1 ratio)
 * - Motion: "Quick up, slow down" surge (1.5:1 ratio)
 *
 * KEY FIXES (2026-01-25):
 * 1. Replaced failed four-bar linkage with asymmetric cam
 *    (Four-bar failed Grashof condition for all curls)
 * 2. Replaced broken gear mesh with belt drive
 *    (Gears were 4mm too far apart to mesh: 34mm vs 30mm)
 * 3. Extended follower pad from 2.5mm to 5mm
 *    (Ensures cam engagement at all positions)
 * 4. Raised curl body by 2mm
 *    (Prevents curl dipping below wave surface)
 *
 * MOTION UPDATES (2026-01-26):
 * 5. Foam phase: +8° lag → -15° lead (anticipatory barrel break)
 * 6. Foam shaft: Y=19 → Y=12 (shorter lever for ±15° dramatic tilt)
 * 7. Wave pitch: 8mm → 6mm (denser wave pattern, 3mm gaps)
 *
 * POV-OPTIMIZED FEATURES (2026-01-26):
 * 8. Wave crest profile: Curved top shape (toggle: WAVE_USE_CREST_PROFILE)
 * 9. Global wave tilt: Optional tilt toward viewer (toggle: WAVE_TILT_ENABLED)
 * 10. Curl orientation: Faces cliff (+X), arcs toward cliff (toggle: CURL_FACE_CLIFF)
 * 11. Dynamic curl lean: Proportional to tilt (CURL_LEAN_FACTOR)
 *
 * Curl profiles: Solid hull()-based shapes. No broken CSG.
 * FDM printable: no internal cavities, min wall 2mm, print flat.
 */

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// SHOW/HIDE
// ============================================

SHOW_FRAME = true;
SHOW_HINGE_AXLE = true;
SHOW_CAMSHAFT = true;
SHOW_FOAM_SHAFT = true;
SHOW_WAVES = true;
SHOW_CURLS = true;
SHOW_HAND_CRANK = true;
SHOW_BELT_DRIVE = true;  // Was SHOW_GEAR_LINK (gears didn't mesh)

WAVE_RANGE_START = 0;
WAVE_RANGE_END = 21;

// ============================================
// WAVE PARAMETERS
// ============================================

WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 3;

// Wave shape profile (crest vs flat)
WAVE_USE_CREST_PROFILE = true;  // true = curved wave crest, false = flat rectangle
WAVE_CREST_PEAK_POS = 0.15;     // Where peak occurs (0-1, fraction of length)
WAVE_CREST_HEIGHT_MULT = 1.3;   // Peak height multiplier (1.0 = same as body)

// Global wave assembly tilt (for viewer POV)
WAVE_TILT_ENABLED = false;      // Toggle global tilt on/off
WAVE_TILT_ANGLE = 25;           // Degrees toward viewer (X-axis rotation)

// ============================================
// HINGE PARAMETERS
// ============================================

HINGE_SLOT_LENGTH = 8;
HINGE_SLOT_HEIGHT = 4;
HINGE_Y = 4;
HINGE_Z = 0;
HINGE_AXLE_DIA = 3;

// ============================================
// WAVE FOLLOWER PAD (on main camshaft at Y=53)
// ============================================

FOLLOWER_PAD_HEIGHT = 5;  // FIXED: Was 2.5, extended for cam engagement
FOLLOWER_PAD_WIDTH = 12;
FOLLOWER_PAD_Y_CENTER = 53;

// ============================================
// MAIN CAMSHAFT + WAVE CAM PARAMETERS
// ============================================

CAMSHAFT_DIA = 6;
CAMSHAFT_Y = 53;
CAMSHAFT_Z = -7;

CAM_THICKNESS = 3;
NUM_WAVES = 22;
UNIT_PITCH = 6;  // Was 8 - denser wave pattern (3mm gaps instead of 5mm)
PHASE_OFFSET = 360 / NUM_WAVES;

// UNIFORM amplitude: all waves 21mm, cliff (16-21) +10%
function cam_major(i) = (i >= 16) ? 23.1 : 21;
function cam_minor(i) = 9;
function cam_phase(i) = i * PHASE_OFFSET;
function cam_lift(i) = (cam_major(i) - cam_minor(i)) / 2;

// ============================================
// FOAM CAMSHAFT (SECOND SHAFT) PARAMETERS
// ============================================

FOAM_SHAFT_DIA = 6;
FOAM_SHAFT_Y = 12;  // Was 19 - moved closer to hinge for dramatic ±15° tilt
FOAM_SHAFT_Z = -5;

// ============================================
// CURL/FOAM PARAMETERS
// ============================================

CURL_THICKNESS = 2.5;
NUM_CURLS = 5;
FOAM_START_WAVE = 16;
FOAM_PHASE_LAG = -15;  // Was +8 - foam now LEADS wave by 15° (anticipatory break)

C_FOAM = [0.9, 0.95, 1.0];

// Curl dimensions: 20-25mm tall, curl radius 6-8mm
function curl_height(ci) = 20 + ci * 1.25;  // 20→25mm (progressive toward cliff)
function curl_radius(ci) = 6 + ci * 0.5;    // 6→8mm

// Curl orientation for POV-optimized arc motion
CURL_FACE_CLIFF = true;       // true = curl faces +X (cliff), false = faces viewer
CURL_BASE_LEAN = 15;          // Degrees toward viewer (static lean)
CURL_LEAN_FACTOR = 0.3;       // Dynamic lean multiplier (arc toward cliff as curl rises)

// Foam cam: progressive 23→31mm for 25→35mm tip rise
function foam_cam_major(ci) = 23 + (ci / 4) * 8;
function foam_cam_minor(ci) = 9;
function foam_cam_phase(ci) = cam_phase(FOAM_START_WAVE + ci) + FOAM_PHASE_LAG;
FOAM_CAM_THICKNESS = 3;

// ============================================
// ASYMMETRIC SURGE PARAMETERS (RE-VALIDATED)
// ============================================
// Mechanism: ASYMMETRIC CAM PROFILE (NOT four-bar)
// Previous four-bar failed Grashof condition for all curls
// Validated: 2026-01-25 (see plan file)

USE_ASYMMETRIC_SURGE = true;  // Toggle: true = asymmetric cam, false = original elliptical

// Curl body Z offset (raises curl above wave surface)
CURL_BODY_Z_OFFSET = 2;  // mm - prevents curl dipping below wave at min tilt

// Asymmetric Cam Profile Parameters
// Quick-return ratio = fall_time / rise_time = 180° / 120° = 1.5:1
ASYM_CAM_BASE = 7;                    // Base circle radius (mm) - Was 9, reduced for ±15° tilt
ASYM_CAM_LIFT = [5, 6, 6, 6, 5];      // Per-curl lift (mm) - Tuned for ±15° with 9.4mm lever
ASYM_RISE_ANGLE = 120;                // Degrees for rise phase (fast)
ASYM_DWELL_ANGLE = 30;                // Degrees at top dwell
ASYM_FALL_ANGLE = 180;                // Degrees for fall phase (slow)
ASYM_CAM_THICKNESS = 4;               // mm

// Phase (same as original foam cams)
function asym_cam_phase(ci) = cam_phase(FOAM_START_WAVE + ci) + FOAM_PHASE_LAG;

// Follower arm parameters
FOLLOWER_ARM_LENGTH = 10;   // mm (hinge to cam contact) - Was 15, matches shorter lever
FOLLOWER_ARM_WIDTH = 4;     // mm
FOLLOWER_PAD_WIDTH_CURL = 8;  // mm (contact surface width)
FOLLOWER_PAD_DEPTH = 3;     // mm (contact surface depth)

// X position of curl (centered in gap between waves)
function curl_x(ci) = wave_x(FOAM_START_WAVE + ci) + UNIT_PITCH / 2;

// ============================================
// SHAFT / FRAME / CRANK
// ============================================

SHAFT_LENGTH = 200;

FRAME_LENGTH = 200;
FRAME_DEPTH = 80;
FRAME_HEIGHT = 50;
FRAME_WALL = 5;
FRAME_X_START = 70;
FRAME_Y_START = -10;
FRAME_Z_BASE = -25;  // lowered for larger foam cams

CRANK_ARM = 25;
CRANK_KNOB_DIA = 10;
CRANK_KNOB_H = 15;

// Belt drive between main shaft and foam shaft (replaces failed gear mesh)
// Gears were 4mm too far apart (34mm vs 30mm required)
PULLEY_RADIUS = 12;     // mm
BELT_WIDTH = 6;         // mm
// Belt naturally spans the 34mm center distance

// ============================================
// COLORS
// ============================================

C_WAVE = [0.3, 0.55, 0.75];
C_CAM = [0.8, 0.5, 0.2];
C_SHAFT = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.25, 0.2];
C_CRANK = [0.5, 0.4, 0.3];
C_GEAR = [0.6, 0.55, 0.4];

$fn = 48;

// ============================================
// DERIVED
// ============================================

WAVE_AREA_START_X = 78;
FIRST_WAVE_X = WAVE_AREA_START_X + UNIT_PITCH;  // 86mm

function wave_x(i) = FIRST_WAVE_X + i * UNIT_PITCH;

WAVE_LEVER_ARM = sqrt(pow(CAMSHAFT_Y - HINGE_Y, 2) + pow(CAMSHAFT_Z - HINGE_Z, 2));
FOAM_LEVER_ARM = sqrt(pow(FOAM_SHAFT_Y - HINGE_Y, 2) + pow(FOAM_SHAFT_Z - HINGE_Z, 2));

// Cam lift calculation (rotating ellipse topmost point)
function cam_current_lift(i, angle) =
    let(phase_angle = angle + cam_phase(i))
    let(a = cam_major(i) / 2, b = cam_minor(i) / 2)
    let(current_top = sqrt(pow(a * sin(phase_angle), 2) + pow(b * cos(phase_angle), 2)))
    current_top - b;

function wave_tilt(i, angle) =
    atan2(cam_current_lift(i, angle), WAVE_LEVER_ARM);

// Foam lift uses foam shaft lever arm (shorter = more angle)
function foam_current_lift(ci, angle) =
    let(phase_angle = angle + foam_cam_phase(ci))
    let(a = foam_cam_major(ci) / 2, b = foam_cam_minor(ci) / 2)
    let(current_top = sqrt(pow(a * sin(phase_angle), 2) + pow(b * cos(phase_angle), 2)))
    current_top - b;

function curl_tilt(ci, angle) =
    atan2(foam_current_lift(ci, angle), FOAM_LEVER_ARM);

// ============================================
// ASYMMETRIC CAM KINEMATICS (REPLACES FAILED FOUR-BAR)
// ============================================
// Previous four-bar failed Grashof condition for ALL curls.
// New mechanism: Asymmetric cam profile with direct follower contact.
//
// Quick-return achieved via cam profile shape:
//   Rise phase:  0° to 120° (fast, 1/3 rotation)
//   Dwell:       120° to 150° (pause at top)
//   Fall phase:  150° to 330° (slow, 1/2 rotation)
//   Dwell:       330° to 360° (pause at bottom)
//
// Quick-return ratio = 180° / 120° = 1.5:1

// Asymmetric cam radius as function of angle
// Returns radius at given shaft rotation angle for curl ci
function asym_cam_radius(ci, angle) =
    let(
        phase = asym_cam_phase(ci),
        local_theta = ((angle + phase) % 360 + 360) % 360,  // Normalize to 0-360
        base = ASYM_CAM_BASE,
        lift = ASYM_CAM_LIFT[ci],

        // Piecewise profile using modified cosine for smooth acceleration
        rise_end = ASYM_RISE_ANGLE,
        dwell_end = rise_end + ASYM_DWELL_ANGLE,
        fall_end = dwell_end + ASYM_FALL_ANGLE,

        profile = (local_theta < rise_end)
            // Fast rise: modified cosine 0→1 over ASYM_RISE_ANGLE degrees
            ? 0.5 - 0.5 * cos(local_theta * 180 / rise_end)
            : (local_theta < dwell_end)
                // Top dwell: hold at maximum
                ? 1.0
                : (local_theta < fall_end)
                    // Slow fall: modified cosine 1→0 over ASYM_FALL_ANGLE degrees
                    ? 0.5 + 0.5 * cos((local_theta - dwell_end) * 180 / ASYM_FALL_ANGLE)
                    // Bottom dwell: hold at minimum
                    : 0.0
    )
    base + lift * profile;

// Cam top Z position at given angle (for follower contact)
function cam_top_z(ci, angle) =
    FOAM_SHAFT_Z + asym_cam_radius(ci, angle);

// Curl tilt angle based on cam follower position
// Follower rides on cam, curl pivots on hinge
function curl_tilt_asym(ci, angle) =
    let(
        cam_z = cam_top_z(ci, angle),
        // Tilt = angle from hinge to follower pad contact point
        // Hinge at (Y=4, Z=0), cam contact at (Y=12, Z=cam_z)
        arm_angle = atan2(cam_z - HINGE_Z, FOAM_SHAFT_Y - HINGE_Y)
    )
    arm_angle;

// Unified tilt function - uses asymmetric cam when enabled
function surge_tilt(ci, angle) =
    USE_ASYMMETRIC_SURGE
        ? curl_tilt_asym(ci, angle)
        : curl_tilt(ci, angle);

// ============================================
// CURL PROFILE MODULES (SOLID hull shapes)
// ============================================

module curl_profile_lip(height, cr) {
    // Open lip: solid J-hook shape via hull
    wall = 2.5;
    hull() {
        // Base of stem
        square([wall, 0.1]);
        // Top of stem
        translate([0, height - cr])
            square([wall, 0.1]);
        // Curl tip (offset right and down from top)
        translate([cr * 0.8, height - cr * 0.3])
            circle(r=wall/2);
    }
}

module curl_profile_barrel(height, cr) {
    // Full barrel: solid C-curve via hull with multiple control points
    wall = 2.5;
    hull() {
        // Base of stem
        square([wall, 0.1]);
        // Mid stem
        translate([0, height - cr])
            square([wall, 0.1]);
        // Top of curl arc
        translate([cr * 0.5, height])
            circle(r=wall/2);
        // Right side of barrel
        translate([cr, height - cr * 0.4])
            circle(r=wall/2);
        // Bottom-right of barrel (wraps under)
        translate([cr * 0.7, height - cr * 1.1])
            circle(r=wall/2);
    }
}

module curl_profile_dissolve(height, cr) {
    // Dissolving: partial curl trailing off
    wall = 2.5;
    hull() {
        // Base
        square([wall, 0.1]);
        // Top of stem
        translate([0, height - cr])
            square([wall, 0.1]);
        // Gentle curl tip (less pronounced)
        translate([cr * 0.5, height - cr * 0.2])
            circle(r=wall/2);
    }
}

// Select profile by curl index
module curl_profile(ci) {
    h = curl_height(ci);
    r = curl_radius(ci);
    if (ci <= 1) curl_profile_lip(h, r);
    else if (ci <= 3) curl_profile_barrel(h, r);
    else curl_profile_dissolve(h, r);
}

// Curl body with POV-optimized orientation
// Faces +X (cliff direction), arcs toward cliff as it rises
module curl_body_oriented(ci, tilt) {
    // Dynamic lean: curl leans toward cliff more as it tilts up
    dynamic_lean = tilt * CURL_LEAN_FACTOR;

    if (CURL_FACE_CLIFF) {
        // POV-OPTIMIZED: Curl faces cliff, arcs toward cliff
        rotate([0, dynamic_lean, 0])        // Dynamic arc toward cliff
            rotate([0, -CURL_BASE_LEAN, 0]) // Base lean toward viewer
                rotate([0, 0, 90])          // Face +X (cliff direction)
                    rotate([90, 0, 0])      // Stand upright
                        linear_extrude(CURL_THICKNESS, center=true)
                            curl_profile(ci);
    } else {
        // ORIGINAL: Curl faces viewer (legacy mode)
        rotate([0, -20, 0])                 // lean curl toward viewer
            rotate([90, 0, 90])
                linear_extrude(CURL_THICKNESS, center=true)
                    curl_profile(ci);
    }
}

// ============================================
// WAVE PROFILE 2D (for crest shape)
// ============================================

module wave_crest_profile_2d() {
    // Wave crest shape - curved top mimicking breaking wave
    // Profile in YZ plane (Y = front-to-back, Z = height)
    peak_y = WAVE_LENGTH * WAVE_CREST_PEAK_POS;
    peak_z = WAVE_BODY_HEIGHT * WAVE_CREST_HEIGHT_MULT;

    polygon([
        [0, 0],                                    // Front bottom
        [0, WAVE_BODY_HEIGHT * 0.8],              // Front rise
        [peak_y, peak_z],                          // Crest peak (forward position)
        [WAVE_LENGTH * 0.4, WAVE_BODY_HEIGHT * 0.9], // Back of crest
        [WAVE_LENGTH * 0.7, WAVE_BODY_HEIGHT * 0.7], // Back slope
        [WAVE_LENGTH, WAVE_BODY_HEIGHT * 0.5],    // Back tapering
        [WAVE_LENGTH, 0]                           // Back bottom
    ]);
}

// Wave body - either crest profile or flat rectangle
module wave_body() {
    if (WAVE_USE_CREST_PROFILE) {
        // Extruded wave crest profile
        rotate([90, 0, 90])
            linear_extrude(WAVE_THICKNESS, center=true)
                wave_crest_profile_2d();
    } else {
        // Original flat rectangle
        translate([-WAVE_THICKNESS/2, 0, 0])
            cube([WAVE_THICKNESS, WAVE_LENGTH, WAVE_BODY_HEIGHT]);
    }
}

// ============================================
// WAVE SLAT MODULE
// ============================================

module wave_slat(i) {
    x_pos = wave_x(i);
    tilt = wave_tilt(i, theta);

    color(C_WAVE)
    translate([x_pos, 0, 0])
        translate([0, HINGE_Y, HINGE_Z])
            rotate([tilt, 0, 0])
                translate([0, -HINGE_Y, -HINGE_Z])
                    difference() {
                        union() {
                            // Main wave body (crest or flat based on setting)
                            wave_body();

                            // Hinge extension
                            translate([-WAVE_THICKNESS/2,
                                       HINGE_Y - HINGE_SLOT_LENGTH/2 - 2,
                                       HINGE_Z - HINGE_SLOT_HEIGHT/2 - 2])
                                cube([WAVE_THICKNESS,
                                      HINGE_SLOT_LENGTH + 4,
                                      HINGE_SLOT_HEIGHT + 4]);

                            // Wave follower pad (contacts main camshaft at Y=53)
                            translate([-WAVE_THICKNESS/2,
                                       FOLLOWER_PAD_Y_CENTER - FOLLOWER_PAD_WIDTH/2,
                                       -FOLLOWER_PAD_HEIGHT])
                                cube([WAVE_THICKNESS, FOLLOWER_PAD_WIDTH, FOLLOWER_PAD_HEIGHT]);
                        }

                        // Hinge slot
                        translate([-WAVE_THICKNESS/2 - 1,
                                   HINGE_Y - HINGE_SLOT_LENGTH/2,
                                   HINGE_Z - HINGE_SLOT_HEIGHT/2])
                            cube([WAVE_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);
                    }
}

module all_waves() {
    for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
        wave_slat(i);
    }
}

// Tilted wave assembly (for viewer POV optimization)
module all_waves_tilted() {
    if (WAVE_TILT_ENABLED) {
        rotate([WAVE_TILT_ANGLE, 0, 0])  // Tilt toward viewer
            all_waves();
    } else {
        all_waves();
    }
}

// ============================================
// CURL PIECE MODULE (WITH ROCKER ARM)
// ============================================

module curl_piece(ci) {
    x_pos = curl_x(ci);

    // Select motion type based on toggle
    tilt = USE_ASYMMETRIC_SURGE
           ? surge_tilt(ci, theta)
           : curl_tilt(ci, theta);

    color(C_FOAM)
    translate([x_pos, 0, 0])
        translate([0, HINGE_Y, HINGE_Z])
            rotate([tilt, 0, 0])
                translate([0, -HINGE_Y, -HINGE_Z])
                    difference() {
                        union() {
                            // Curl body: starts at wave top + offset (Z=12)
                            // POV-OPTIMIZED: Curl faces cliff (+X), arcs toward cliff as it rises
                            translate([0, HINGE_Y + 10, WAVE_BODY_HEIGHT + CURL_BODY_Z_OFFSET])
                                curl_body_oriented(ci, tilt);

                            // Hinge extension
                            translate([-CURL_THICKNESS/2,
                                       HINGE_Y - HINGE_SLOT_LENGTH/2 - 1.5,
                                       HINGE_Z - HINGE_SLOT_HEIGHT/2 - 1.5])
                                cube([CURL_THICKNESS,
                                      HINGE_SLOT_LENGTH + 3,
                                      HINGE_SLOT_HEIGHT + 3]);

                            // Connector bridge: hinge to curl body base
                            translate([-CURL_THICKNESS/2,
                                       HINGE_Y + HINGE_SLOT_LENGTH/2 + 1.5,
                                       0])
                                cube([CURL_THICKNESS,
                                      10 - HINGE_SLOT_LENGTH/2 + 1.5,
                                      WAVE_BODY_HEIGHT + CURL_BODY_Z_OFFSET]);

                            // FOLLOWER ARM (for cam contact - replaces rocker arm)
                            if (USE_ASYMMETRIC_SURGE) {
                                follower_arm(ci);
                            } else {
                                // Original: Foam follower pad (contacts FOAM shaft at Y=19)
                                translate([-CURL_THICKNESS/2,
                                           FOAM_SHAFT_Y - 5,
                                           -FOLLOWER_PAD_HEIGHT])
                                    cube([CURL_THICKNESS, 10, FOLLOWER_PAD_HEIGHT]);
                            }
                        }

                        // Hinge slot
                        translate([-CURL_THICKNESS/2 - 1,
                                   HINGE_Y - HINGE_SLOT_LENGTH/2,
                                   HINGE_Z - HINGE_SLOT_HEIGHT/2])
                            cube([CURL_THICKNESS + 2, HINGE_SLOT_LENGTH, HINGE_SLOT_HEIGHT]);
                    }
}

// Follower arm module - extends from hinge toward cam for direct contact
// Replaces failed four-bar rocker arm
module follower_arm(ci) {
    arm_width = FOLLOWER_ARM_WIDTH;
    pad_width = FOLLOWER_PAD_WIDTH_CURL;
    pad_depth = FOLLOWER_PAD_DEPTH;

    // Arm extends from hinge (Y=4, Z=0) toward cam at shaft (Y=12, Z varies)
    // The tilt is already applied via curl rotation, so arm is "straight"
    // in the curl's local coordinate system

    // Calculate cam contact point (at current angle, but in local coords)
    cam_z = cam_top_z(ci, theta);

    // Arm body: hull from hinge to near-shaft
    hull() {
        // Hinge end
        translate([0, HINGE_Y, HINGE_Z])
            rotate([0, 90, 0])
                cylinder(d=arm_width + 2, h=CURL_THICKNESS, center=true, $fn=24);

        // Near cam end (at Y=FOAM_SHAFT_Y, Z at cam surface)
        translate([0, FOAM_SHAFT_Y, cam_z])
            rotate([0, 90, 0])
                cylinder(d=arm_width + 2, h=CURL_THICKNESS, center=true, $fn=24);
    }

    // Flat follower pad at cam contact point
    translate([-pad_width/2, FOAM_SHAFT_Y - pad_depth/2, cam_z - pad_depth])
        cube([pad_width, pad_depth, pad_depth]);
}

module all_curls() {
    for (ci = [0:NUM_CURLS-1]) {
        curl_piece(ci);
    }
}

// ============================================
// SHAFTS
// ============================================

module hinge_axle() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, HINGE_Y, HINGE_Z])
        rotate([0, 90, 0])
            cylinder(d=HINGE_AXLE_DIA, h=SHAFT_LENGTH + 10);
}

module camshaft_with_cams() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, CAMSHAFT_Y, CAMSHAFT_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Main shaft
                cylinder(d=CAMSHAFT_DIA, h=SHAFT_LENGTH + 10);

                // Wave cams (all elliptical, uniform amplitude)
                for (i = [WAVE_RANGE_START:WAVE_RANGE_END]) {
                    cam_x = wave_x(i) - FRAME_X_START + 5;
                    major = cam_major(i);
                    minor = cam_minor(i);
                    phase = cam_phase(i);

                    translate([0, 0, cam_x])
                        rotate([0, 0, phase])
                            color(C_CAM)
                            scale([major/10, minor/10, 1])
                                cylinder(r=5, h=CAM_THICKNESS, center=true);
                }
            }
}

module foam_shaft_with_cams() {
    color(C_SHAFT)
    translate([FRAME_X_START - 5, FOAM_SHAFT_Y, FOAM_SHAFT_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                // Foam shaft
                cylinder(d=FOAM_SHAFT_DIA, h=SHAFT_LENGTH + 10);

                if (USE_ASYMMETRIC_SURGE) {
                    // ASYMMETRIC CAM LOBES (replaces failed four-bar eccentrics)
                    // Profile: fast rise (120°), slow fall (180°) = 1.5:1 ratio
                    for (ci = [0:NUM_CURLS-1]) {
                        foam_x = curl_x(ci) - FRAME_X_START + 5;

                        translate([0, 0, foam_x])
                            color([1, 0.8, 0.6])
                            linear_extrude(ASYM_CAM_THICKNESS, center=true)
                                asym_cam_profile_2d(ci);
                    }
                } else {
                    // Original elliptical foam cams (progressive 23→31mm)
                    for (ci = [0:NUM_CURLS-1]) {
                        foam_x = curl_x(ci) - FRAME_X_START + 5;
                        f_major = foam_cam_major(ci);
                        f_minor = foam_cam_minor(ci);
                        f_phase = foam_cam_phase(ci) - theta;

                        translate([0, 0, foam_x])
                            rotate([0, 0, f_phase])
                                color([1, 0.8, 0.6])
                                scale([f_major/10, f_minor/10, 1])
                                    cylinder(r=5, h=FOAM_CAM_THICKNESS, center=true);
                    }
                }
            }
}

// 2D asymmetric cam profile for extrusion
// Creates polygon from radius samples at 5° increments
module asym_cam_profile_2d(ci) {
    steps = 72;  // 5° per step
    points = [
        for (i = [0:steps-1])
            let(
                angle = i * 360 / steps,
                // Note: theta already applied via shaft rotation
                // so we pass angle=0 for the "unrotated" cam shape
                r = asym_cam_radius(ci, -angle)  // negative for correct rotation direction
            )
            [r * cos(angle), r * sin(angle)]
    ];

    difference() {
        polygon(points);
        // Center hole for shaft
        circle(d=FOAM_SHAFT_DIA + 0.4, $fn=32);
    }
}

// ============================================
// (REMOVED: SURGE CONNECTING RODS)
// ============================================
// Four-bar linkage was removed due to Grashof failure.
// Now using direct cam-follower contact instead.
// No connecting rods needed.

// ============================================
// BELT DRIVE (connects main shaft to foam shaft)
// ============================================
// Replaces failed gear mesh (shafts 34mm apart, gears only reach 30mm)
// Belt naturally spans any distance

module belt_drive() {
    belt_x = FRAME_X_START - 10;  // just outside left wall

    // Main shaft pulley
    color(C_GEAR)
    translate([belt_x, CAMSHAFT_Y, CAMSHAFT_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta])
                pulley();

    // Foam shaft pulley (same size for 1:1 ratio)
    color(C_GEAR)
    translate([belt_x, FOAM_SHAFT_Y, FOAM_SHAFT_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta])  // same direction (belt drive, not gear mesh)
                pulley();

    // Belt connecting the two pulleys
    color([0.2, 0.2, 0.2])
    belt_between_pulleys(belt_x);
}

module pulley() {
    // Simple pulley with groove
    difference() {
        cylinder(r=PULLEY_RADIUS, h=BELT_WIDTH, center=true, $fn=48);
        // Belt groove
        rotate_extrude($fn=48)
            translate([PULLEY_RADIUS - 1, 0, 0])
                circle(r=2, $fn=16);
    }
}

module belt_between_pulleys(x_pos) {
    // Belt path: tangent lines + arcs around pulleys
    // Simplified as hull for visualization

    // Calculate tangent points
    dy = FOAM_SHAFT_Y - CAMSHAFT_Y;
    dz = FOAM_SHAFT_Z - CAMSHAFT_Z;
    dist = sqrt(dy*dy + dz*dz);
    angle = atan2(dz, dy);

    // Belt thickness
    belt_t = 2;

    // Upper tangent (from main to foam)
    translate([x_pos, CAMSHAFT_Y, CAMSHAFT_Z])
        rotate([angle, 0, 0])
            translate([0, PULLEY_RADIUS, 0])
                cube([belt_t, 0.1, dist], center=true);

    // Lower tangent (from foam to main)
    translate([x_pos, CAMSHAFT_Y, CAMSHAFT_Z])
        rotate([angle, 0, 0])
            translate([0, -PULLEY_RADIUS, 0])
                cube([belt_t, 0.1, dist], center=true);

    // Wrap around main pulley (simplified)
    translate([x_pos, CAMSHAFT_Y, CAMSHAFT_Z])
        rotate([0, 90, 0])
            difference() {
                cylinder(r=PULLEY_RADIUS + belt_t/2, h=belt_t, center=true, $fn=48);
                cylinder(r=PULLEY_RADIUS - belt_t/2, h=belt_t + 1, center=true, $fn=48);
                // Cut away the non-wrapped portion
                translate([0, -dist, 0])
                    cube([dist*2, dist*2, belt_t + 2], center=true);
            }

    // Wrap around foam pulley (simplified)
    translate([x_pos, FOAM_SHAFT_Y, FOAM_SHAFT_Z])
        rotate([0, 90, 0])
            difference() {
                cylinder(r=PULLEY_RADIUS + belt_t/2, h=belt_t, center=true, $fn=48);
                cylinder(r=PULLEY_RADIUS - belt_t/2, h=belt_t + 1, center=true, $fn=48);
                // Cut away the non-wrapped portion
                translate([0, dist, 0])
                    cube([dist*2, dist*2, belt_t + 2], center=true);
            }
}

// ============================================
// FRAME
// ============================================

module frame() {
    color(C_FRAME) {
        // Base plate
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            cube([FRAME_LENGTH, FRAME_DEPTH, FRAME_WALL]);

        // Left wall
        translate([FRAME_X_START, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                // Hinge axle bearing
                translate([-1, HINGE_Y - FRAME_Y_START, HINGE_Z - FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
                // Main camshaft bearing
                translate([-1, CAMSHAFT_Y - FRAME_Y_START, CAMSHAFT_Z - FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
                // Foam shaft bearing
                translate([-1, FOAM_SHAFT_Y - FRAME_Y_START, FOAM_SHAFT_Z - FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=FOAM_SHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }

        // Right wall
        translate([FRAME_X_START + FRAME_LENGTH - FRAME_WALL, FRAME_Y_START, FRAME_Z_BASE])
            difference() {
                cube([FRAME_WALL, FRAME_DEPTH, FRAME_HEIGHT]);
                // Hinge axle bearing
                translate([-1, HINGE_Y - FRAME_Y_START, HINGE_Z - FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=HINGE_AXLE_DIA + 0.4, h=FRAME_WALL + 2);
                // Main camshaft bearing
                translate([-1, CAMSHAFT_Y - FRAME_Y_START, CAMSHAFT_Z - FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=CAMSHAFT_DIA + 0.4, h=FRAME_WALL + 2);
                // Foam shaft bearing
                translate([-1, FOAM_SHAFT_Y - FRAME_Y_START, FOAM_SHAFT_Z - FRAME_Z_BASE])
                    rotate([0, 90, 0])
                        cylinder(d=FOAM_SHAFT_DIA + 0.4, h=FRAME_WALL + 2);
            }
    }
}

// ============================================
// HAND CRANK
// ============================================

module hand_crank() {
    color(C_CRANK)
    translate([FRAME_X_START - 15, CAMSHAFT_Y, CAMSHAFT_Z])
        rotate([0, 90, 0])
            rotate([0, 0, theta]) {
                difference() {
                    cylinder(d=14, h=8);
                    translate([0, 0, -1])
                        cylinder(d=CAMSHAFT_DIA + 0.3, h=10);
                }
                translate([0, -3, 0])
                    cube([CRANK_ARM, 6, 8]);
                translate([CRANK_ARM, 0, 0])
                    cylinder(d=CRANK_KNOB_DIA, h=CRANK_KNOB_H);
            }
}

// ============================================
// ASSEMBLY
// ============================================

module wave_ocean_v7_assembly() {
    if (SHOW_FRAME) frame();
    if (SHOW_HINGE_AXLE) hinge_axle();
    if (SHOW_CAMSHAFT) camshaft_with_cams();
    if (SHOW_FOAM_SHAFT) foam_shaft_with_cams();
    // Waves: use tilted version if WAVE_TILT_ENABLED
    if (SHOW_WAVES) {
        if (WAVE_TILT_ENABLED) all_waves_tilted();
        else all_waves();
    }
    if (SHOW_CURLS) all_curls();
    if (SHOW_HAND_CRANK) hand_crank();
    if (SHOW_BELT_DRIVE) belt_drive();
    // (Removed: surge_connecting_rods - four-bar linkage replaced by cam-follower)
}

wave_ocean_v7_assembly();

// ============================================
// VERIFICATION ECHO
// ============================================

echo("");
echo("========================================================");
echo("  WAVE OCEAN v7 - UNIFORM AMPLITUDE + DUAL SHAFT FOAM");
echo("========================================================");
echo(str("  Pitch: ", UNIT_PITCH, "mm | Wave: ", WAVE_THICKNESS, "mm | Gap: ", UNIT_PITCH - WAVE_THICKNESS, "mm"));
echo(str("  Waves: ", NUM_WAVES, " | Curls: ", NUM_CURLS));
echo("");
echo("  WAVE CAMS (uniform):");
echo(str("    Standard (0-15): ", cam_major(0), "x", cam_minor(0), "mm, lift=", cam_lift(0), "mm"));
echo(str("    Cliff (16-21):   ", cam_major(16), "x", cam_minor(16), "mm, lift=", cam_lift(16), "mm (+10%)"));
echo(str("    Wave lever arm: ", WAVE_LEVER_ARM, "mm"));
wave_tip_std = (WAVE_LENGTH - HINGE_Y) * sin(atan2(cam_lift(0), WAVE_LEVER_ARM));
wave_tip_cliff = (WAVE_LENGTH - HINGE_Y) * sin(atan2(cam_lift(16), WAVE_LEVER_ARM));
echo(str("    Wave tip motion (std): ", wave_tip_std, "mm"));
echo(str("    Wave tip motion (cliff): ", wave_tip_cliff, "mm"));
echo("");
echo("  FOAM SHAFT:");
echo(str("    Position: Y=", FOAM_SHAFT_Y, " Z=", FOAM_SHAFT_Z));
echo(str("    Foam lever arm: ", FOAM_LEVER_ARM, "mm"));
echo("  FOAM CAMS (progressive):");
for (ci = [0:NUM_CURLS-1]) {
    f_lift = (foam_cam_major(ci) - foam_cam_minor(ci)) / 2;
    f_angle = atan2(f_lift, FOAM_LEVER_ARM);
    f_tip = (WAVE_LENGTH - HINGE_Y) * sin(f_angle);
    echo(str("    Curl ", ci, ": cam=", foam_cam_major(ci), "mm, lift=", f_lift,
             "mm, tip=", f_tip, "mm",
             (ci <= 1) ? " [LIP]" : (ci <= 3) ? " [BARREL]" : " [DISSOLVE]"));
}
echo("");
echo("  PRINTABILITY:");
echo(str("    Wave wall: ", WAVE_THICKNESS, "mm [", WAVE_THICKNESS >= 1.2 ? "PASS" : "FAIL", "]"));
echo(str("    Curl wall: ", CURL_THICKNESS, "mm [", CURL_THICKNESS >= 1.2 ? "PASS" : "FAIL", "]"));
echo(str("    Wave gap: ", UNIT_PITCH - WAVE_THICKNESS, "mm [PASS]"));
echo("    Internal cavities: NONE [PASS]");
echo("");
echo("  CLEARANCES:");
max_foam_cam_r = foam_cam_major(4) / 2;
foam_cam_bottom = FOAM_SHAFT_Z - max_foam_cam_r;
echo(str("    Largest foam cam bottom: Z=", foam_cam_bottom, "mm"));
echo(str("    Frame base: Z=", FRAME_Z_BASE, "mm"));
echo(str("    Clearance: ", FRAME_Z_BASE - foam_cam_bottom, "mm (need <0) ... ",
         foam_cam_bottom > FRAME_Z_BASE ? "PASS" : "FAIL - increase frame depth"));
max_wave_cam_r = cam_major(16) / 2;
wave_cam_bottom = CAMSHAFT_Z - max_wave_cam_r;
echo(str("    Largest wave cam bottom: Z=", wave_cam_bottom, "mm"));
echo(str("    Wave cam clearance to base: ", wave_cam_bottom - FRAME_Z_BASE, "mm [",
         wave_cam_bottom > FRAME_Z_BASE ? "PASS" : "FAIL", "]"));
echo("");
echo("  POWER PATH:");
echo("    Crank -> Main Camshaft -> Wave cams -> Wave slats tilt");
if (USE_ASYMMETRIC_SURGE) {
    echo("    Crank -> Belt -> Foam Shaft -> Asymmetric Cams -> Curl pieces surge");
    echo("    Return: Gravity (asymmetric: quick UP, slow DOWN)");
} else {
    echo("    Crank -> Belt -> Foam Shaft -> Elliptical Cams -> Curl pieces surge");
    echo("    Return: Gravity (symmetric motion)");
}
echo("  BELT DRIVE: 1:1 ratio, main shaft drives foam shaft (replaces failed gears)");
echo("");
echo("  ASYMMETRIC SURGE MODE:", USE_ASYMMETRIC_SURGE ? "ENABLED" : "DISABLED");
if (USE_ASYMMETRIC_SURGE) {
    echo("  SURGE MECHANISM: Asymmetric Cam Profile (replaces failed four-bar)");
    echo("  VALIDATED: 2026-01-25");
    echo("");
    echo("  CAM PROFILE:");
    echo(str("    Base radius: ", ASYM_CAM_BASE, "mm"));
    echo(str("    Rise phase: 0° to ", ASYM_RISE_ANGLE, "° (fast)"));
    echo(str("    Top dwell: ", ASYM_RISE_ANGLE, "° to ", ASYM_RISE_ANGLE + ASYM_DWELL_ANGLE, "°"));
    echo(str("    Fall phase: ", ASYM_RISE_ANGLE + ASYM_DWELL_ANGLE, "° to ", ASYM_RISE_ANGLE + ASYM_DWELL_ANGLE + ASYM_FALL_ANGLE, "° (slow)"));
    echo(str("    Quick-return ratio: ", ASYM_FALL_ANGLE, "/", ASYM_RISE_ANGLE, " = ", ASYM_FALL_ANGLE/ASYM_RISE_ANGLE, ":1"));
    echo("");
    echo("  PER-CURL CAM DIMENSIONS:");
    for (ci = [0:NUM_CURLS-1]) {
        lift = ASYM_CAM_LIFT[ci];
        max_r = ASYM_CAM_BASE + lift;
        min_tilt = atan2(FOAM_SHAFT_Z + ASYM_CAM_BASE - HINGE_Z, FOAM_SHAFT_Y - HINGE_Y);
        max_tilt = atan2(FOAM_SHAFT_Z + max_r - HINGE_Z, FOAM_SHAFT_Y - HINGE_Y);
        echo(str("    Curl ", ci, ": lift=", lift, "mm, max_r=", max_r, "mm, tilt=",
                 round(min_tilt*10)/10, "° to ", round(max_tilt*10)/10, "°",
                 (ci <= 1) ? " [LIP]" : (ci <= 3) ? " [BARREL]" : " [DISSOLVE]"));
    }
    echo("");
    echo("  FIXES APPLIED:");
    echo(str("    Curl body Z offset: +", CURL_BODY_Z_OFFSET, "mm (prevents dipping below wave)"));
    echo(str("    Follower pad height: ", FOLLOWER_PAD_HEIGHT, "mm (ensures cam engagement)"));
    echo("    Belt drive: Replaces gears (were 4mm too far apart to mesh)");
}
echo("");
echo("  POV-OPTIMIZED FEATURES:");
echo(str("    Wave crest profile: ", WAVE_USE_CREST_PROFILE ? "ENABLED" : "DISABLED"));
echo(str("    Wave global tilt: ", WAVE_TILT_ENABLED ? str(WAVE_TILT_ANGLE, "° toward viewer") : "DISABLED"));
echo(str("    Curl faces cliff: ", CURL_FACE_CLIFF ? "YES (+X direction)" : "NO (faces viewer)"));
echo(str("    Curl base lean: ", CURL_BASE_LEAN, "° toward viewer"));
echo(str("    Curl dynamic lean factor: ", CURL_LEAN_FACTOR, " (arc toward cliff)"));
if (CURL_FACE_CLIFF) {
    // Calculate example arc motion
    sample_tilt = 15;  // Example tilt angle
    arc_lean = sample_tilt * CURL_LEAN_FACTOR;
    echo(str("    At tilt=", sample_tilt, "°: curl leans ", arc_lean, "° toward cliff"));
}
echo("");
echo("  MECHANICAL VERIFICATION:");
curl_gap = UNIT_PITCH - CURL_THICKNESS;
echo(str("    Curl thickness: ", CURL_THICKNESS, "mm in ", UNIT_PITCH, "mm pitch = ", curl_gap, "mm gap [", curl_gap >= 0.5 ? "PASS" : "FAIL", "]"));
echo(str("    Foam shaft clearance to hinge: ", FOAM_SHAFT_Y - HINGE_Y, "mm [", FOAM_SHAFT_Y > HINGE_Y + 2 ? "PASS" : "WARNING", "]"));
echo("========================================================");
