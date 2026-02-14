// ═══════════════════════════════════════════════════════════════════════════════
//                    OCEAN WAVES V7 - ACTIVE BREAKING WAVE SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════
// SELF-CONTAINED kinetic wave sculpture - no external dependencies
//
// Features:
//   - 4 wave layers at different phases (depth effect)
//   - Asymmetric timing: SLOW BUILD (55%) → CRASH (22%) → RETREAT (22%)
//   - Height-dependent curl (tips forward at peak only)
//   - Subtle spray at cliff impact
//   - Static cliff/rocks reference
//   - Single motor drives all waves
//
// Reference: Big Sur coast - real ocean rhythm (8 second cycle)
// ═══════════════════════════════════════════════════════════════════════════════

$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════════
//                              PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════

// Overall dimensions
OCEAN_WIDTH = 200;          // mm - total wave area width
OCEAN_DEPTH = 80;           // mm - front to back
OCEAN_HEIGHT = 50;          // mm - max wave height
BASE_HEIGHT = 10;           // mm - base platform height

// Wave timing
WAVE_CYCLE_SECONDS = 8;     // Target: 6-10 seconds for real ocean feel

// Multi-wave system (4 layers, back to front)
WAVE_COUNT = 4;
WAVE_PHASES = [105, 70, 35, 0];           // Phase offsets (degrees) - back to front
WAVE_AMPLITUDES = [10, 12, 14, 16];       // Max heights (mm) - front waves taller
WAVE_Y_POSITIONS = [60, 45, 28, 10];      // Y positions (mm from front)
WAVE_WIDTHS = [180, 160, 140, 120];       // Width of each wave layer

// Wave colors (back to front: deep → white foam)
WAVE_COLORS = [
    [0.15, 0.35, 0.55],   // Layer 0 (back): Deep blue
    [0.25, 0.50, 0.70],   // Layer 1: Medium blue
    [0.45, 0.70, 0.88],   // Layer 2: Light blue
    [0.85, 0.92, 0.98]    // Layer 3 (front): White foam
];

// Curl parameters
CURL_TRIGGER = 0.75;        // Curl starts at 75% of max height
CURL_MAX_ANGLE = 45;        // Maximum tip-over (degrees)

// Spray parameters (subtle foam)
SPRAY_PARTICLE_COUNT = 5;
SPRAY_SIZE_MIN = 1.5;
SPRAY_SIZE_MAX = 2.5;
SPRAY_REACH = 5;

// Cliff parameters
CLIFF_X = -10;              // Cliff position (left edge)
CLIFF_WIDTH = 25;
CLIFF_HEIGHT = 45;
CLIFF_COLOR = [0.35, 0.30, 0.25];

// Animation
master_phase = $t * 360;

// ═══════════════════════════════════════════════════════════════════════════════
//                         MOTION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

// Cycloidal motion (smooth S-curve)
function cycloidal(t) = t - sin(t * 180) / PI;

// Ease functions
function ease_in_out(t) = t < 0.5 ? 2*t*t : 1 - pow(-2*t + 2, 2) / 2;

// ═══════════════════════════════════════════════════════════════════════════════
//                    ASYMMETRIC BREAKING WAVE CAM PROFILE
// ═══════════════════════════════════════════════════════════════════════════════
// Motion Profile:
//    _______________
//   /               \
//  /                 \____
//                         \___________
//  0°--------200°---280°---------360°
//    SLOW BUILD    CRASH    RETREAT
//        55%        22%        22%
// ═══════════════════════════════════════════════════════════════════════════════

function breaking_wave_profile(theta, max_lift=16) =
    let(norm = theta % 360)
    // Phase 1: Slow parabolic rise (0-200°) - wave builds
    norm < 200
        ? max_lift * pow(norm / 200, 1.8)
    // Phase 2: Brief dwell at peak (200-210°) - wave hangs
    : norm < 210
        ? max_lift
    // Phase 3: Fast cycloidal crash (210-280°) - dramatic fall
    : norm < 280
        ? max_lift * (1 - cycloidal((norm - 210) / 70))
    // Phase 4: Slow linear drain (280-360°) - retreat
    : max_lift * 0.1 * (1 - (norm - 280) / 80);

// Wave velocity (for spray triggering)
function wave_velocity(theta, max_lift=16, delta=1) =
    let(
        h1 = breaking_wave_profile(theta, max_lift),
        h2 = breaking_wave_profile(theta + delta, max_lift)
    )
    (h2 - h1) / delta;

// ═══════════════════════════════════════════════════════════════════════════════
//                    HEIGHT-DEPENDENT CURL
// ═══════════════════════════════════════════════════════════════════════════════

function curl_angle(wave_height, max_height) =
    let(
        trigger_point = max_height * CURL_TRIGGER,
        progress = max(0, (wave_height - trigger_point) / (max_height - trigger_point)),
        eased = pow(progress, 0.5)
    )
    eased * CURL_MAX_ANGLE;

// ═══════════════════════════════════════════════════════════════════════════════
//                         WAVE SHAPE MODULES
// ═══════════════════════════════════════════════════════════════════════════════

// Single wave layer shape
module wave_shape(width, height, thickness=5) {
    // Organic wave profile using polygon
    scale_h = height / 25;  // Normalize to base height

    linear_extrude(height=thickness)
    scale([width/100, scale_h, 1])
    polygon([
        [0, 0], [100, 0],
        [95, 8], [85, 15], [70, 20],
        [50, 23], [30, 22], [15, 18],
        [5, 12], [0, 5]
    ]);
}

// Curl foam element (tips forward based on curl angle)
module curl_foam(curl_deg, size=8) {
    rotate([curl_deg, 0, 0]) {
        color([0.95, 0.98, 1.0, 0.9])
        hull() {
            sphere(r=size * 0.6);
            translate([size * 0.3, size * 0.8, size * 0.3])
            sphere(r=size * 0.5);
            translate([size * 0.5, size * 1.1, -size * 0.15])
            sphere(r=size * 0.35);
        }

        // Foam bubbles
        for (i = [0:3]) {
            translate([i * 2 - 3, 3 + i * 2, 1])
            sphere(r=1.2, $fn=12);
        }
    }
}

// Spray particles (subtle foam burst)
module spray_burst(intensity) {
    if (intensity > 0.1) {
        color([0.95, 0.98, 1.0, 0.7])
        for (i = [0:SPRAY_PARTICLE_COUNT-1]) {
            // Deterministic positions
            px = [0.2, -0.4, 0.5, 0.0, -0.3][i] * SPRAY_REACH * intensity;
            py = [0.8, 0.5, 0.6, 0.3, 0.5][i] * SPRAY_REACH * intensity;
            pz = [0.5, 0.3, 0.4, 0.8, 0.2][i] * SPRAY_REACH * intensity * 0.7;
            ps = [1.0, 0.8, 0.7, 0.6, 0.9][i];

            translate([px, py, pz])
            sphere(r=SPRAY_SIZE_MIN + (SPRAY_SIZE_MAX - SPRAY_SIZE_MIN) * ps * intensity, $fn=12);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                         STATIC CLIFF
// ═══════════════════════════════════════════════════════════════════════════════

module cliff() {
    color(CLIFF_COLOR) {
        // Main cliff body
        hull() {
            translate([0, 0, 0])
            cube([CLIFF_WIDTH, OCEAN_DEPTH * 0.6, 1]);

            translate([5, 10, CLIFF_HEIGHT])
            cube([CLIFF_WIDTH - 10, OCEAN_DEPTH * 0.4, 1]);
        }

        // Rocky outcrops
        for (i = [0:2]) {
            translate([5 + i * 8, 5 + i * 3, 0])
            scale([1, 0.8, 1])
            cylinder(d1=12 - i * 2, d2=6 - i, h=15 + i * 5, $fn=6);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                         MAIN WAVE ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════

module ocean_waves_v7() {
    // Base platform
    color([0.2, 0.3, 0.4])
    translate([CLIFF_X, 0, 0])
    cube([OCEAN_WIDTH + abs(CLIFF_X) + 20, OCEAN_DEPTH, BASE_HEIGHT]);

    // Static cliff (left side)
    translate([CLIFF_X, 5, BASE_HEIGHT])
    cliff();

    // Wave layers (render back to front for proper Z-ordering)
    for (layer = [0:WAVE_COUNT-1]) {
        // Calculate this layer's motion
        layer_phase = master_phase + WAVE_PHASES[layer];
        max_h = WAVE_AMPLITUDES[layer];
        height = breaking_wave_profile(layer_phase, max_h);
        velocity = wave_velocity(layer_phase, max_h);

        // Layer positioning
        layer_y = WAVE_Y_POSITIONS[layer];
        layer_width = WAVE_WIDTHS[layer];
        layer_x = (OCEAN_WIDTH - layer_width) / 2;
        layer_z = BASE_HEIGHT + height;

        translate([layer_x, layer_y, layer_z]) {
            // Wave body
            color(WAVE_COLORS[layer])
            wave_shape(layer_width, 15 + layer * 3, 4);

            // Front wave (layer 3) gets curl and spray
            if (layer == WAVE_COUNT - 1) {
                // Height-dependent curl
                curl_deg = curl_angle(height, max_h);

                translate([layer_width * 0.7, 18, 5])
                curl_foam(curl_deg, 10);

                // Spray at crash moment
                is_crashing = height > (max_h * 0.7) && velocity < -0.3;
                if (is_crashing) {
                    spray_intensity = min(1, abs(velocity) / 1.5);
                    translate([layer_width * 0.1, 10, 8])
                    spray_burst(spray_intensity);
                }
            }
        }
    }

    // Debug output
    front_height = breaking_wave_profile(master_phase, WAVE_AMPLITUDES[3]);
    front_vel = wave_velocity(master_phase, WAVE_AMPLITUDES[3]);
    status = front_vel > 0.1 ? "BUILD" :
             front_vel < -0.5 ? "CRASH" :
             front_height > 12 ? "PEAK" : "RETREAT";

    echo(str("V7 Ocean - Phase: ", round(master_phase % 360),
             "° | Height: ", round(front_height * 10) / 10,
             "mm | Status: ", status));
}

// ═══════════════════════════════════════════════════════════════════════════════
//                              RENDER
// ═══════════════════════════════════════════════════════════════════════════════

ocean_waves_v7();

// ═══════════════════════════════════════════════════════════════════════════════
//                         ANIMATION INSTRUCTIONS
// ═══════════════════════════════════════════════════════════════════════════════
// 1. Open in OpenSCAD
// 2. View → Animate
// 3. Set FPS: 30, Steps: 100
// 4. Watch the wave cycle:
//    - $t=0.00: Waves at rest
//    - $t=0.45: Front wave building to peak
//    - $t=0.55: Peak, curl forward
//    - $t=0.60: CRASH, spray active
//    - $t=0.75: Retreating
// ═══════════════════════════════════════════════════════════════════════════════
