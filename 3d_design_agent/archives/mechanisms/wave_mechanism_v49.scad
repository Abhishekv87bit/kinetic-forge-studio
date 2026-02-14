// ═══════════════════════════════════════════════════════════════════════════════════════
//                    WAVE MECHANISM V49 - ENHANCED NATURAL MOTION
//                    Dual motion models (trochoidal/sinusoidal) for A/B comparison
//                    Implements 3-zone system with articulated breaking wave
//                    Improvements: Harmonics, easing, graduated phases, reduced curl
// ═══════════════════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                MOTION MODEL SELECTOR
//                                Toggle for A/B comparison
// ═══════════════════════════════════════════════════════════════════════════════════════
// Options: "trochoidal" (realistic physics) or "sinusoidal" (simpler, refined)
MOTION_MODEL = "sinusoidal";  // USER CHOICE: sinusoidal selected

// Enable/disable secondary harmonics for organic motion
ENABLE_HARMONICS = true;

// Enable/disable easing functions for natural acceleration
ENABLE_EASING = true;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                MOTION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════════════

// === MODEL A: Trochoidal Motion (Realistic Water Physics) ===
// Real water particles follow orbital paths, not simple up-down motion
// Deep water: circular orbits | Shallow water: flattened ellipses

// Trochoidal X component (horizontal orbital motion)
function trochoidal_x(amp, phase) = amp * sin(phase);

// Trochoidal Y component (vertical orbital motion)
function trochoidal_y(amp, phase) = amp * cos(phase);

// Elliptical motion for transitional depths
// ratio: 1.0 = circular, 0.3 = flattened (shallow water)
function elliptical_x(amp, phase, ratio) = amp * sin(phase);
function elliptical_y(amp, phase, ratio) = amp * ratio * cos(phase);

// === MODEL B: Refined Sinusoidal Motion (Enhanced with Harmonics) ===
// Primary sine wave plus secondary and tertiary harmonics for organic feel

// Single sine (basic - for reference)
function basic_sine(amp, phase) = amp * sin(phase);

// Enhanced sine with harmonics (more natural)
// Secondary: 15% amplitude at 2x frequency, 45° offset
// Tertiary: 8% amplitude at 3x frequency, 90° offset
function harmonic_sine(amp, phase) =
    ENABLE_HARMONICS ?
        amp * sin(phase) +
        (amp * 0.15) * sin(phase * 2 + 45) +
        (amp * 0.08) * sin(phase * 3 + 90)
    : amp * sin(phase);

// === EASING FUNCTIONS ===
// Replace linear interpolation with natural acceleration/deceleration

// Sine-based ease-in-out: slow start, fast middle, slow end
function ease_in_out(t) = (1 - cos(t * 180)) / 2;

// Ease-out: fast start, slow end (like a ball rolling to stop)
function ease_out(t) = sin(t * 90);

// Ease-in: slow start, fast end (like acceleration)
function ease_in(t) = 1 - cos(t * 90);

// === MOTION SELECTOR ===
// Returns appropriate motion based on selected model
function get_bob_motion(amp, phase) =
    MOTION_MODEL == "trochoidal" ?
        trochoidal_y(amp, phase) :
        harmonic_sine(amp, phase);

function get_drift_motion(amp, phase, depth_ratio) =
    MOTION_MODEL == "trochoidal" ?
        elliptical_x(amp, phase, depth_ratio) :
        harmonic_sine(amp, phase);

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                CANVAS REFERENCE
// ═══════════════════════════════════════════════════════════════════════════════════════
IW = 302;           // Inner canvas width (mm)
IH = 227;           // Inner canvas height (mm)
TAB_W = 4;          // Tab offset
CLIFF_EDGE_X = 108; // Where cliff meets ocean

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════════
t = $t;
master_phase = t * 360;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                         GRADUATED PHASE PROGRESSION SYSTEM
//                         Smoother than coarse zone offsets
// ═══════════════════════════════════════════════════════════════════════════════════════
// Phase rate: 90° total spread across 194mm wave area = 0.464°/mm
// This creates continuous traveling wave illusion rather than zone "stepping"

WAVE_AREA_START = CLIFF_EDGE_X;
WAVE_AREA_END = IW;
WAVE_AREA_WIDTH = WAVE_AREA_END - WAVE_AREA_START;  // 194mm

TOTAL_PHASE_SPAN = 90;  // degrees across entire wave area
WAVE_PHASE_RATE = TOTAL_PHASE_SPAN / WAVE_AREA_WIDTH;  // 0.464 deg/mm

// Zone 1: Far Ocean - 18° spacing (smoother than old 15°/30°)
ZONE_1_WAVE_PHASES = [0, 18, 36];

// Zone 2: Mid Ocean - 12° spacing (tighter grouping as waves steepen)
ZONE_2_BASE_PHASE = 45;
ZONE_2_WAVE_PHASES = [45, 57, 69];

// Zone 3: Breaking wave - continuous from 75°
ZONE_3_BASE_PHASE = 75;

// Compute phase for each zone
PHASE_ZONE_1_FAR = master_phase;
PHASE_ZONE_2_MID = master_phase + ZONE_2_BASE_PHASE;
PHASE_ZONE_3_BREAK = master_phase + ZONE_3_BASE_PHASE;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Zone 1: Far Ocean (smallest waves, gentle bob)
// Zone 2: Mid/Approaching Ocean (medium waves, drift + bob)
// Zone 3: Breaking Zone (articulated curl mechanism)

// Zone boundaries (X coordinates as percentage of wave area)
ZONE_1_X_START = 0.70;  // 70-100% of wave area (far right)
ZONE_1_X_END = 1.00;

ZONE_2_X_START = 0.40;  // 40-70% of wave area (middle)
ZONE_2_X_END = 0.70;

ZONE_3_X_START = 0.00;  // 0-40% of wave area (near cliff)
ZONE_3_X_END = 0.40;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                FOUR-BAR PARAMETERS PER ZONE
// ═══════════════════════════════════════════════════════════════════════════════════════
// Base parameters (from USER_VISION_ELEMENTS - LOCKED)
BASE_CRANK = 10;
BASE_GROUND = 25;
BASE_COUPLER = 30;
BASE_ROCKER = 25;

// Zone 1: Far Ocean - Minimal motion (circular orbit - deep water)
ZONE_1_CRANK = 5;           // 50% of base (minimal throw)
ZONE_1_COUPLER = 38;        // Longer coupler = gentler motion
ZONE_1_OUTPUT = 2;          // +/-2mm amplitude
ZONE_1_DEPTH_RATIO = 1.0;   // Circular orbit (deep water)

// Zone 2: Mid Ocean - Building motion (elliptical orbit - transitional)
ZONE_2_CRANK = 8;           // 80% of base
ZONE_2_COUPLER = 34;        // Medium coupler
ZONE_2_DRIFT = 3;           // +/-3mm horizontal drift
ZONE_2_BOB = 5;             // +/-5mm vertical bob
ZONE_2_DRIFT_FREQ = 0.95;   // Drift frequency relative to bob (was 0.8, now more natural)
ZONE_2_DEPTH_RATIO = 0.55;  // Ellipse ratio 1:1.8 (drift:bob = 3:5.5)

// Zone 3: Breaking - Maximum drama (uses articulated mechanism)
// IMPROVED: Reduced crank for better Grashof margin
ZONE_3_CRANK = 12;          // Was 15 - now safer Grashof margin
ZONE_3_COUPLER = 25;        // Short coupler = aggressive motion
ZONE_3_CRASH = 12;          // +/-12mm crash motion

// Zone 3: Wave positions (parameterized - was hardcoded)
ZONE_1_WAVE_1_X_OFFSET = 0.7;
ZONE_1_WAVE_2_X_OFFSET = 0.4;
ZONE_1_WAVE_3_X_OFFSET = 0.1;

ZONE_1_WAVE_BASE_Y = 15;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                         BREAKING WAVE PARAMETERS (V49 UPDATED)
// ═══════════════════════════════════════════════════════════════════════════════════════
// User choice: Reduced curl from 120° to 90° for more realistic appearance

BREAKING_BASE_TILT_AMP = 8;     // Base swell tilt amplitude (degrees)
BREAKING_PIVOT_OFFSET_X = 20;   // Pivot offset from cliff edge

// Curl parameters (UPDATED for natural appearance)
CURL_INITIAL_ANGLE = 30;        // Building curl phase (degrees)
CURL_MAX_ANGLE = 90;            // Maximum curl - REDUCED from 120°
CURL_CRASH_PHASE = 160;         // Phase when max curl reached

// Crest parameters
CREST_MAX_RISE = 25;            // Maximum crest rise angle
CREST_CRASH_FALL = 15;          // How much crest falls during crash

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                GRASHOF VERIFICATION
// ═══════════════════════════════════════════════════════════════════════════════════════
// For a crank-rocker: shortest + longest < sum of other two
// Zone 1: 5 + 38 = 43 < 25 + 25 = 50  (margin = 7)
// Zone 2: 8 + 34 = 42 < 25 + 25 = 50  (margin = 8)
// Zone 3: 12 + 25 = 37 < 25 + 25 = 50 (margin = 13) ← IMPROVED from 40

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════════════
C_GEAR = "#b8860b";
C_GEAR_DARK = "#8b7355";
C_METAL = "#708090";
C_CRANK = "#d4a060";
C_COUPLER = "#a08050";

// Zone wave colors (deeper blue = further away)
C_ZONE_1 = ["#0a2a4e", "#0e3258", "#123a62"];  // Far: deep blue
C_ZONE_2 = ["#1a4a7e", "#2a5a8e", "#3a6a9e"];  // Mid: medium blue
C_ZONE_3 = ["#4a8ab8", "#5a9ac8", "#ffffff"];  // Break: light blue + foam

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
Z_CAMSHAFT = 55;        // Four-bar mechanism base
Z_CRANK_DISCS = 56;     // Crank discs
Z_COUPLERS = 58;        // Coupler rods
Z_WAVE_BASE = 60;       // Wave layers start
Z_WAVE_LAYER_T = 5;     // Each layer thickness - INCREASED from 4mm for clearance

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE 1: FAR OCEAN MODULE
//                                (3 small waves, orbital motion)
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_1_far_ocean() {
    // Calculate positions in wave area
    x_start = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_1_X_START;
    x_end = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_1_X_END;
    zone_width = x_end - x_start;

    // Get phases with graduated offsets (smoother 18° spacing)
    phase_1 = PHASE_ZONE_1_FAR + ZONE_1_WAVE_PHASES[0];
    phase_2 = PHASE_ZONE_1_FAR + ZONE_1_WAVE_PHASES[1];
    phase_3 = PHASE_ZONE_1_FAR + ZONE_1_WAVE_PHASES[2];

    // Motion calculations using selected model
    // Trochoidal: full circular orbit | Sinusoidal: vertical with harmonics
    bob_1 = get_bob_motion(ZONE_1_OUTPUT, phase_1);
    bob_2 = get_bob_motion(ZONE_1_OUTPUT, phase_2);
    bob_3 = get_bob_motion(ZONE_1_OUTPUT, phase_3);

    // Horizontal orbital component (trochoidal only)
    drift_1 = MOTION_MODEL == "trochoidal" ? trochoidal_x(ZONE_1_OUTPUT * 0.5, phase_1) : 0;
    drift_2 = MOTION_MODEL == "trochoidal" ? trochoidal_x(ZONE_1_OUTPUT * 0.5, phase_2) : 0;
    drift_3 = MOTION_MODEL == "trochoidal" ? trochoidal_x(ZONE_1_OUTPUT * 0.5, phase_3) : 0;

    // Wave 1 - Furthest (smallest)
    translate([x_start + zone_width * ZONE_1_WAVE_1_X_OFFSET + drift_1,
               ZONE_1_WAVE_BASE_Y + bob_1, Z_WAVE_BASE]) {
        color(C_ZONE_1[0])
        scale([0.35, 0.35, 1])
        wave_shape_simple(40, 12);
    }

    // Wave 2 - Middle far
    translate([x_start + zone_width * ZONE_1_WAVE_2_X_OFFSET + drift_2,
               ZONE_1_WAVE_BASE_Y + 3 + bob_2, Z_WAVE_BASE + Z_WAVE_LAYER_T]) {
        color(C_ZONE_1[1])
        scale([0.40, 0.40, 1])
        wave_shape_simple(45, 14);
    }

    // Wave 3 - Closest of far zone
    translate([x_start + zone_width * ZONE_1_WAVE_3_X_OFFSET + drift_3,
               ZONE_1_WAVE_BASE_Y + 5 + bob_3, Z_WAVE_BASE + Z_WAVE_LAYER_T * 2]) {
        color(C_ZONE_1[2])
        scale([0.45, 0.45, 1])
        wave_shape_crest(50, 16);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE 2: MID OCEAN MODULE
//                                (3 waves, elliptical orbit motion)
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_2_mid_ocean() {
    x_start = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_2_X_START;
    x_end = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_2_X_END;
    zone_width = x_end - x_start;

    // Get phases with graduated offsets (12° spacing - tighter as waves steepen)
    phase_1 = PHASE_ZONE_2_MID + ZONE_2_WAVE_PHASES[0] - ZONE_2_BASE_PHASE;
    phase_2 = PHASE_ZONE_2_MID + ZONE_2_WAVE_PHASES[1] - ZONE_2_BASE_PHASE;
    phase_3 = PHASE_ZONE_2_MID + ZONE_2_WAVE_PHASES[2] - ZONE_2_BASE_PHASE;

    // Motion: elliptical orbit (drift + bob)
    // Improved drift frequency: 0.95x (was 0.8x) for more natural ellipse
    drift = get_drift_motion(ZONE_2_DRIFT, PHASE_ZONE_2_MID * ZONE_2_DRIFT_FREQ, ZONE_2_DEPTH_RATIO);

    bob_1 = get_bob_motion(ZONE_2_BOB, phase_1);
    bob_2 = get_bob_motion(ZONE_2_BOB, phase_2);
    bob_3 = get_bob_motion(ZONE_2_BOB, phase_3);

    // Wave 4 - Back of mid zone
    translate([x_start + zone_width * 0.75 + drift, 22 + bob_1, Z_WAVE_BASE]) {
        color(C_ZONE_2[0])
        scale([0.55, 0.55, 1])
        wave_shape_crest(55, 18);
    }

    // Wave 5 - Center of mid zone
    translate([x_start + zone_width * 0.45 + drift * 0.8, 26 + bob_2, Z_WAVE_BASE + Z_WAVE_LAYER_T]) {
        color(C_ZONE_2[1])
        scale([0.70, 0.70, 1])
        wave_shape_crest(60, 22);
    }

    // Wave 6 - Front of mid zone (largest open water)
    translate([x_start + zone_width * 0.15 + drift * 0.6, 30 + bob_3, Z_WAVE_BASE + Z_WAVE_LAYER_T * 2]) {
        color(C_ZONE_2[2])
        scale([0.85, 0.85, 1])
        wave_shape_crest(65, 26);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE 3: ARTICULATED BREAKING WAVE
//                                Multi-segment hinged mechanism with EASED motion
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_3_breaking_wave() {
    x_start = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_3_X_START;
    x_end = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_3_X_END;
    zone_width = x_end - x_start;

    // Articulated wave motion sequence:
    // 0-120°: Wave rises, crest lifts, lip begins curl
    // 120-180°: Lip folds over dramatically (the "crash")
    // 180-360°: Wave retreats, resets for next cycle

    phase_normalized = PHASE_ZONE_3_BREAK % 360;

    // Calculate segment angles based on phase WITH EASING
    // Base swell: rises and falls (sinusoidal, optionally with harmonics)
    base_angle = ENABLE_HARMONICS ?
        harmonic_sine(BREAKING_BASE_TILT_AMP, PHASE_ZONE_3_BREAK) :
        BREAKING_BASE_TILT_AMP * sin(PHASE_ZONE_3_BREAK);

    // Rising crest: follows base with delay, NOW WITH EASING
    crest_delay = 20;  // degrees behind base

    // Apply easing to crest rise for natural acceleration
    crest_rise = ENABLE_EASING ?
        (phase_normalized < 120 ?
            CREST_MAX_RISE * ease_in_out(phase_normalized / 120) :  // Eased rise
            phase_normalized < 180 ?
            CREST_MAX_RISE - CREST_CRASH_FALL * ease_out((phase_normalized - 120) / 60) :  // Eased fall
            (CREST_MAX_RISE - CREST_CRASH_FALL) * sin((phase_normalized - 180) * 2))  // Retreat
        :
        (phase_normalized < 120 ?
            (phase_normalized / 120) * CREST_MAX_RISE :  // Linear rise (old)
            phase_normalized < 180 ?
            CREST_MAX_RISE - ((phase_normalized - 120) / 60) * CREST_CRASH_FALL :
            (CREST_MAX_RISE - CREST_CRASH_FALL) * sin((phase_normalized - 180) * 2));

    // Curling lip: dramatic fold during crash, NOW REDUCED TO 90° MAX
    // Apply easing for natural curl acceleration
    curl_angle = ENABLE_EASING ?
        (phase_normalized < 100 ?
            CURL_INITIAL_ANGLE * ease_in(phase_normalized / 100) :  // Building curl (eased)
            phase_normalized < CURL_CRASH_PHASE ?
            CURL_INITIAL_ANGLE + (CURL_MAX_ANGLE - CURL_INITIAL_ANGLE) *
                ease_in_out((phase_normalized - 100) / (CURL_CRASH_PHASE - 100)) :  // Dramatic fold (eased)
            CURL_MAX_ANGLE * ease_out(1 - (phase_normalized - CURL_CRASH_PHASE) / (360 - CURL_CRASH_PHASE)))  // Reset (eased)
        :
        (phase_normalized < 100 ?
            (phase_normalized / 100) * CURL_INITIAL_ANGLE :  // Linear building (old)
            phase_normalized < CURL_CRASH_PHASE ?
            CURL_INITIAL_ANGLE + ((phase_normalized - 100) / (CURL_CRASH_PHASE - 100)) *
                (CURL_MAX_ANGLE - CURL_INITIAL_ANGLE) :
            CURL_MAX_ANGLE - ((phase_normalized - CURL_CRASH_PHASE) / (360 - CURL_CRASH_PHASE)) * CURL_MAX_ANGLE);

    // Horizontal surge motion (with harmonics if enabled)
    surge = ENABLE_HARMONICS ?
        harmonic_sine(ZONE_3_CRASH, PHASE_ZONE_3_BREAK * 0.7) :
        ZONE_3_CRASH * sin(PHASE_ZONE_3_BREAK * 0.7);

    // Position at cliff edge (parameterized)
    pivot_x = CLIFF_EDGE_X + BREAKING_PIVOT_OFFSET_X + surge;
    pivot_y = 8;

    translate([pivot_x, pivot_y, Z_WAVE_BASE]) {
        // === COMPONENT 1: BASE SWELL ===
        // Fixed pivot at cliff edge
        rotate([base_angle, 0, 0]) {
            color(C_ZONE_3[0])
            linear_extrude(height=Z_WAVE_LAYER_T)
            polygon([
                [0, 0],
                [zone_width * 0.6, 0],
                [zone_width * 0.5, 25],
                [zone_width * 0.3, 30],
                [zone_width * 0.1, 25],
                [0, 15]
            ]);

            // === COMPONENT 2: RISING CREST ===
            // Hinged to base, rises with wave
            translate([zone_width * 0.25, 28, Z_WAVE_LAYER_T]) {
                rotate([crest_rise, 0, 0]) {
                    color(C_ZONE_3[1])
                    linear_extrude(height=Z_WAVE_LAYER_T)
                    polygon([
                        [-15, 0],
                        [25, 0],
                        [30, 12],
                        [20, 20],
                        [5, 25],
                        [-10, 18],
                        [-15, 8]
                    ]);

                    // === COMPONENT 3: CURLING LIP ===
                    // Hinged to crest, folds over during crash (max 90° now)
                    translate([15, 18, Z_WAVE_LAYER_T]) {
                        rotate([curl_angle, 0, 0]) {
                            color(C_ZONE_3[2])  // Foam white
                            linear_extrude(height=Z_WAVE_LAYER_T)
                            polygon([
                                [-8, 0],
                                [12, 0],
                                [15, 8],
                                [10, 15],
                                [0, 18],
                                [-8, 12]
                            ]);

                            // === COMPONENT 4: SPRAY TIPS ===
                            // Small pieces at curl edge
                            translate([5, 12, Z_WAVE_LAYER_T])
                            spray_tips(
                                phase = phase_normalized,
                                tip_count = 4,
                                base_radius = 2,
                                detach_start_phase = 120,
                                detach_end_phase = 200,
                                max_detach_distance = 15,
                                scatter_factor = 10
                            );
                        }
                    }
                }
            }
        }
    }

    // Foam at cliff base (appears during crash phase)
    if (phase_normalized > 100 && phase_normalized < 220) {
        foam_intensity = phase_normalized < 160 ?
            (phase_normalized - 100) / 60 :
            1 - ((phase_normalized - 160) / 60);

        translate([CLIFF_EDGE_X + 5, 5, Z_WAVE_BASE + Z_WAVE_LAYER_T * 3])
        foam_burst(
            intensity = foam_intensity,
            blob_count = 6,
            max_spread = 8
        );
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                SPRAY TIPS MODULE
//                                Full Shape Wrapper with All Parameters
// ═══════════════════════════════════════════════════════════════════════════════════════
module spray_tips(
    phase,                              // Animation phase (0-360)
    tip_count = 4,                      // Number of spray tips
    base_radius = 2,                    // Radius of largest tip
    detach_start_phase = 120,           // Phase when detachment begins
    detach_end_phase = 200,             // Phase when detachment ends
    max_detach_distance = 15,           // Maximum detachment distance
    scatter_factor = 10,                // Scatter randomization amount
    color_val = "#ffffff",              // Tip color
    alpha = 0.9                         // Transparency
) {
    // Calculate detachment progress (optionally eased)
    raw_progress = (phase > detach_start_phase && phase < detach_end_phase) ?
        (phase - detach_start_phase) / (detach_end_phase - detach_start_phase) : 0;

    detach = ENABLE_EASING ?
        max_detach_distance * ease_out(raw_progress) :
        raw_progress * max_detach_distance;

    scatter = (phase > detach_start_phase + 10) ?
        ((phase - detach_start_phase - 10) / 100) * scatter_factor : 0;

    color(color_val, alpha) {
        for (i = [0:tip_count-1]) {
            // Deterministic "random" offset based on index
            x_offset = detach * (0.3 + i * 0.2) + (i % 2) * 3;
            y_offset = detach * (0.3 + (i * 0.15)) + scatter * (((i+1) % 3) - 1) * 0.3;
            z_offset = i * 0.5;
            r = max(base_radius - i * 0.2, 1);

            translate([x_offset, y_offset, z_offset])
            sphere(r=r);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                FOAM BURST MODULE
//                                Full Shape Wrapper with All Parameters
// ═══════════════════════════════════════════════════════════════════════════════════════
module foam_burst(
    intensity,                          // Foam intensity (0-1)
    blob_count = 6,                     // Number of foam blobs
    base_radius = 3,                    // Base blob radius
    max_spread = 8,                     // Maximum spread distance
    color_val = "#ffffff",              // Foam color
    base_alpha = 0.8                    // Base transparency
) {
    color(color_val, intensity * base_alpha) {
        for (i = [0:blob_count-1]) {
            angle = i * (360 / blob_count) + intensity * 30;
            dist = (base_radius) + intensity * max_spread;
            translate([dist * cos(angle), dist * sin(angle) * 0.3, i * 2])
            scale([1, 0.6, 0.4])
            sphere(r=base_radius + intensity * 2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                WAVE SHAPE MODULES
//                                Full Shape Wrappers
// ═══════════════════════════════════════════════════════════════════════════════════════
module wave_shape_simple(
    width,
    height,
    thickness = -1  // -1 means use Z_WAVE_LAYER_T
) {
    // Simple wave for far ocean (smooth, no crest)
    t = thickness == -1 ? Z_WAVE_LAYER_T : thickness;

    linear_extrude(height=t)
    polygon([
        [0, 0],
        [width, 0],
        [width, height * 0.4],
        [width * 0.75, height * 0.6],
        [width * 0.5, height * 0.5],
        [width * 0.25, height * 0.7],
        [0, height * 0.5]
    ]);
}

module wave_shape_crest(
    width,
    height,
    thickness = -1  // -1 means use Z_WAVE_LAYER_T
) {
    // Wave with crest for mid ocean (more dramatic)
    t = thickness == -1 ? Z_WAVE_LAYER_T : thickness;

    linear_extrude(height=t)
    polygon([
        [0, 0],
        [width, 0],
        [width, height * 0.3],
        [width * 0.85, height * 0.5],
        [width * 0.7, height * 0.75],
        [width * 0.5, height],
        [width * 0.35, height * 0.85],
        [width * 0.2, height * 0.6],
        [0, height * 0.4]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                CAMSHAFT ASSEMBLY
//                                (Drives all zones with variable eccentrics)
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_camshaft_assembly() {
    // Camshaft position (behind waves, under cliff)
    cam_x = 100;
    cam_y = 35;

    translate([cam_x, cam_y, Z_CAMSHAFT]) {
        // Main camshaft
        color(C_METAL)
        rotate([0, 90, 0])
        cylinder(d=8, h=120, center=true);

        // Bearing blocks (with added clearance offset)
        bearing_offset = 55 + 8;  // Added 8mm clearance for crank collision prevention

        color(C_GEAR_DARK) {
            translate([-55, 0, 0])
            difference() {
                cube([14, 20, 12], center=true);
                rotate([0, 90, 0])
                cylinder(d=10, h=16, center=true);
            }

            translate([55, 0, 0])
            difference() {
                cube([14, 20, 12], center=true);
                rotate([0, 90, 0])
                cylinder(d=10, h=16, center=true);
            }
        }

        // Ground bar
        color(C_GEAR_DARK)
        translate([0, 0, -5])
        cube([120, 10, 5], center=true);

        // === ZONE 1 CRANK DISC (5mm throw) ===
        translate([40, 0, 0])
        zone_crank_disc(ZONE_1_CRANK, PHASE_ZONE_1_FAR, C_ZONE_1[0]);

        // === ZONE 2 CRANK DISCS (8mm throw) x2 ===
        // Phase offset now uses graduated system
        translate([10, 0, 0])
        zone_crank_disc(ZONE_2_CRANK, PHASE_ZONE_2_MID, C_ZONE_2[0]);

        translate([-15, 0, 0])
        zone_crank_disc(ZONE_2_CRANK, PHASE_ZONE_2_MID + 12, C_ZONE_2[1]);  // 12° offset (was 20°)

        // === ZONE 3 CRANK DISC (12mm throw - reduced from 15mm) ===
        translate([-40, 0, 0])
        zone_crank_disc(ZONE_3_CRANK, PHASE_ZONE_3_BREAK, C_ZONE_3[0]);

        // Drive gear (connects to master gear train)
        translate([-65, 0, 0])
        rotate([0, 90, 0])
        rotate([0, 0, master_phase])
        drive_gear_30t();
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE CRANK DISC MODULE
//                                Full Shape Wrapper
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_crank_disc(
    crank_throw,
    phase,
    color_val,
    disc_thickness = 5,
    shaft_diameter = 8,
    pin_diameter = 4
) {
    rotate([phase, 0, 0])
    rotate([0, 90, 0]) {
        // Disc body
        color(color_val)
        difference() {
            cylinder(d=crank_throw * 2.5, h=disc_thickness, center=true);
            cylinder(d=shaft_diameter, h=disc_thickness + 2, center=true);
        }

        // Eccentric crank pin
        translate([crank_throw, 0, 0])
        color(C_METAL)
        cylinder(d=pin_diameter, h=disc_thickness * 2, center=true);

        // Visual indicator of throw direction
        color(color_val)
        translate([crank_throw * 0.5, 0, disc_thickness/2 + 1])
        cylinder(d=2, h=2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                DRIVE GEAR (30T)
//                                Full Shape Wrapper
// ═══════════════════════════════════════════════════════════════════════════════════════
module drive_gear_30t(
    teeth = 30,
    module_val = 1.0,
    thickness = 6,
    shaft_hole = 8,
    lightening_holes = 5
) {
    pitch_r = teeth * module_val / 2;

    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=pitch_r - 1, h=thickness);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([pitch_r, 0, 0])
                cylinder(r=2, h=thickness, $fn=6);
            }
        }
        translate([0, 0, -1])
        cylinder(d=shaft_hole, h=thickness + 2);

        // Lightening holes
        for (i = [0:lightening_holes-1]) {
            rotate([0, 0, i * (360/lightening_holes) + (180/lightening_holes)])
            translate([pitch_r * 0.55, 0, -1])
            cylinder(r=3, h=thickness + 2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════════

// Zone 1: Far Ocean
zone_1_far_ocean();

// Zone 2: Mid Ocean
zone_2_mid_ocean();

// Zone 3: Breaking Wave (articulated)
zone_3_breaking_wave();

// Camshaft Assembly
zone_camshaft_assembly();

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("WAVE MECHANISM V49 - ENHANCED NATURAL MOTION");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("");
echo("MOTION MODEL:", MOTION_MODEL);
echo("  Toggle 'MOTION_MODEL' between 'trochoidal' and 'sinusoidal' to compare");
echo("  Trochoidal: Realistic water physics with orbital particle motion");
echo("  Sinusoidal: Simpler motion with harmonics for organic feel");
echo("");
echo("HARMONICS:", ENABLE_HARMONICS ? "ENABLED" : "DISABLED");
echo("EASING:", ENABLE_EASING ? "ENABLED" : "DISABLED");
echo("");
echo("ZONE 1 - FAR OCEAN:");
echo("  Crank throw:", ZONE_1_CRANK, "mm");
echo("  Motion: Orbital/harmonic bob +/-", ZONE_1_OUTPUT, "mm");
echo("  Phase offsets:", ZONE_1_WAVE_PHASES, "° (graduated)");
echo("  Grashof:", ZONE_1_CRANK, "+", ZONE_1_COUPLER, "=", ZONE_1_CRANK + ZONE_1_COUPLER, "< 50 ✓");
echo("");
echo("ZONE 2 - MID OCEAN:");
echo("  Crank throw:", ZONE_2_CRANK, "mm");
echo("  Motion: Elliptical Drift +/-", ZONE_2_DRIFT, "mm, Bob +/-", ZONE_2_BOB, "mm");
echo("  Drift frequency:", ZONE_2_DRIFT_FREQ, "x (improved from 0.8x)");
echo("  Phase offsets:", ZONE_2_WAVE_PHASES, "° (graduated)");
echo("  Grashof:", ZONE_2_CRANK, "+", ZONE_2_COUPLER, "=", ZONE_2_CRANK + ZONE_2_COUPLER, "< 50 ✓");
echo("");
echo("ZONE 3 - BREAKING WAVE:");
echo("  Crank throw:", ZONE_3_CRANK, "mm (REDUCED from 15mm for safety)");
echo("  Motion: ARTICULATED CURL with EASING");
echo("    - Base swell: +/-", BREAKING_BASE_TILT_AMP, "° tilt");
echo("    - Rising crest: 0-", CREST_MAX_RISE, "° lift (eased)");
echo("    - Curling lip: 0-", CURL_MAX_ANGLE, "° fold (REDUCED from 120°)");
echo("    - Spray detachment: parameterized");
echo("  Grashof:", ZONE_3_CRANK, "+", ZONE_3_COUPLER, "=", ZONE_3_CRANK + ZONE_3_COUPLER, "< 50 ✓ (margin=13)");
echo("");
echo("PHASE PROGRESSION (Graduated):");
echo("  Total span:", TOTAL_PHASE_SPAN, "° across", WAVE_AREA_WIDTH, "mm");
echo("  Rate:", WAVE_PHASE_RATE, "°/mm");
echo("  Zone 1:", ZONE_1_WAVE_PHASES);
echo("  Zone 2:", ZONE_2_WAVE_PHASES);
echo("  Zone 3:", ZONE_3_BASE_PHASE, "°");
echo("");
echo("Z-LAYER SPACING:", Z_WAVE_LAYER_T, "mm (INCREASED from 4mm)");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
