// ═══════════════════════════════════════════════════════════════════════════════
//                    ASYMMETRIC CAM PROFILES FOR BREAKING WAVES
// ═══════════════════════════════════════════════════════════════════════════════
// Motion Profile: SLOW BUILD (0°-200°) → CRASH (200°-280°) → RETREAT (280°-360°)
//                      55%                    22%                    22%
//
// Reference: Big Sur coast waves - asymmetric timing with dramatic curl-over
// ═══════════════════════════════════════════════════════════════════════════════

// Cycloidal motion for smooth acceleration/deceleration
// Returns 0-1 over input range 0-1
function cycloidal_motion(t) =
    t - sin(t * 180) / PI;

// Ease-in-out for parabolic rise
// Returns 0-1 over input range 0-1
function ease_in_out(t) =
    t < 0.5
        ? 2 * t * t
        : 1 - pow(-2 * t + 2, 2) / 2;

// ═══════════════════════════════════════════════════════════════════════════════
//                         BREAKING WAVE CAM PROFILE
// ═══════════════════════════════════════════════════════════════════════════════
// Input: theta (degrees, 0-360 per cycle)
// Output: wave height (0 to max_lift mm)
//
// Profile breakdown:
//   0° - 200° (55.5%): Slow parabolic rise - wave builds tension
//   200° - 210° (2.8%): Brief dwell at peak - wave "hangs" before breaking
//   210° - 280° (19.4%): Fast cycloidal crash - dramatic fall
//   280° - 360° (22.2%): Slow linear drain - water retreats
// ═══════════════════════════════════════════════════════════════════════════════

function breaking_wave_cam_profile(theta, max_lift=16) =
    let(norm = theta % 360)
    // Phase 1: Slow parabolic rise (0-200°) - wave builds
    norm < 200
        ? max_lift * pow(norm / 200, 1.8)
    // Phase 2: Brief dwell at peak (200-210°) - wave hangs
    : norm < 210
        ? max_lift
    // Phase 3: Fast cycloidal crash (210-280°) - dramatic fall
    : norm < 280
        ? max_lift * (1 - cycloidal_motion((norm - 210) / 70))
    // Phase 4: Slow linear drain (280-360°) - retreat
    : max_lift * 0.1 * (1 - (norm - 280) / 80);

// Derivative of wave profile (for velocity/spray triggering)
// Returns rate of change (positive = rising, negative = falling)
function wave_velocity(theta, max_lift=16, delta=1) =
    let(
        h1 = breaking_wave_cam_profile(theta, max_lift),
        h2 = breaking_wave_cam_profile(theta + delta, max_lift)
    )
    (h2 - h1) / delta;

// ═══════════════════════════════════════════════════════════════════════════════
//                         MULTI-WAVE PHASE SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════
// Creates overlapping waves at different phases for depth effect
//
// Layer layout (front to back):
//   Layer 0 (front): Phase 0°, near cliff - the breaking wave
//   Layer 1: Phase 35°
//   Layer 2: Phase 70°
//   Layer 3 (back): Phase 105° - far ocean swell
// ═══════════════════════════════════════════════════════════════════════════════

// Wave layer parameters
ZONE3_WAVE_COUNT = 4;
ZONE3_PHASES = [0, 35, 70, 105];        // Phase offsets (degrees)
ZONE3_AMPLITUDES = [12, 14, 12, 10];    // Max heights (mm) - middle waves tallest
ZONE3_X_OFFSETS = [0, 20, 40, 60];      // X positions from zone start (mm)
ZONE3_COLORS = [
    [0.95, 0.98, 1.0],   // Layer 0: White foam (breaking)
    [0.6, 0.8, 0.95],    // Layer 1: Light blue
    [0.4, 0.65, 0.85],   // Layer 2: Medium blue
    [0.25, 0.5, 0.75]    // Layer 3: Deep blue (far)
];

// Get wave height for a specific layer at given base phase
function get_wave_height(layer_index, base_phase) =
    let(
        phase = base_phase + ZONE3_PHASES[layer_index],
        amplitude = ZONE3_AMPLITUDES[layer_index]
    )
    breaking_wave_cam_profile(phase, amplitude);

// Get all wave heights as a vector
function get_all_wave_heights(base_phase) =
    [for (i = [0:ZONE3_WAVE_COUNT-1]) get_wave_height(i, base_phase)];

// ═══════════════════════════════════════════════════════════════════════════════
//                              TIMING PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════
// Target: 8-second wave cycle (real ocean rhythm: 6-10 seconds)

WAVE_CYCLE_SECONDS = 8;         // User-adjustable cycle time
MASTER_RPM = 5;                 // Base motor speed
ZONE3_SPEED_RATIO = 60 / (WAVE_CYCLE_SECONDS * MASTER_RPM);  // Calculated ratio

// ═══════════════════════════════════════════════════════════════════════════════
//                            VISUALIZATION MODULE
// ═══════════════════════════════════════════════════════════════════════════════
// Test module to visualize cam profile as a shape

module cam_profile_visualization(radius=30, lift=16) {
    points = [
        for (theta = [0:5:360])
            let(
                r = radius + breaking_wave_cam_profile(theta, lift),
                x = r * cos(theta),
                y = r * sin(theta)
            )
            [x, y]
    ];

    color([0.4, 0.6, 0.8])
    linear_extrude(height=5)
    polygon(points);

    // Center mark
    color([0.8, 0.2, 0.2])
    cylinder(d=3, h=7);
}

// Test: Uncomment to see cam profile shape
// cam_profile_visualization();
