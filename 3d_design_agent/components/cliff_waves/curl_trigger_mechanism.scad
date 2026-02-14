// ═══════════════════════════════════════════════════════════════════════════════
//                    HEIGHT-DEPENDENT CURL TRIGGER MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════
// Real ocean physics: Wave curl tips forward ONLY when wave reaches peak height
// Not continuous rotation - curl triggers at the dramatic moment
//
// Reference: Big Sur coast - curl-over happens at wave peak, just before crash
// ═══════════════════════════════════════════════════════════════════════════════

use <asymmetric_cam_profiles.scad>

// ═══════════════════════════════════════════════════════════════════════════════
//                         CURL TRIGGER PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════

CURL_TRIGGER_THRESHOLD = 0.75;  // Curl starts when wave > 75% of max height
CURL_MAX_ANGLE = 45;            // Maximum curl tip-over angle (degrees)
CURL_EASE_FACTOR = 2.0;         // Easing exponent (higher = sharper threshold)

// ═══════════════════════════════════════════════════════════════════════════════
//                         CURL ANGLE CALCULATION
// ═══════════════════════════════════════════════════════════════════════════════
// Input: wave_height (current), max_height (amplitude for this wave)
// Output: curl angle in degrees (0 = no curl, CURL_MAX_ANGLE = full curl)
//
// Behavior:
//   wave_height < 75% max → curl = 0° (wave building, no curl yet)
//   wave_height 75-100% max → curl ramps 0° to 45° (curl tips forward at peak)
//   As wave crashes, height drops, curl angle follows
// ═══════════════════════════════════════════════════════════════════════════════

function curl_angle(wave_height, max_height) =
    let(
        // Normalize height to 0-1 range
        normalized = wave_height / max_height,

        // Calculate how far past threshold we are (0 if below, 0-1 if above)
        trigger_point = max_height * CURL_TRIGGER_THRESHOLD,
        progress = max(0, (wave_height - trigger_point) / (max_height - trigger_point)),

        // Apply easing for smooth curl motion
        eased_progress = pow(progress, 1 / CURL_EASE_FACTOR)
    )
    eased_progress * CURL_MAX_ANGLE;

// Velocity-aware curl (tips forward faster when rising, slower when falling)
function curl_angle_dynamic(wave_height, max_height, velocity) =
    let(
        base_curl = curl_angle(wave_height, max_height),
        // Add velocity bias: positive velocity = tip forward more
        velocity_factor = velocity > 0 ? 1.2 : 0.8
    )
    base_curl * velocity_factor;

// ═══════════════════════════════════════════════════════════════════════════════
//                           CURL FOAM ELEMENT
// ═══════════════════════════════════════════════════════════════════════════════
// The visual foam piece that tips forward based on curl_angle
// Organic shape using hull() of spheres

module curl_foam_element(curl_deg, size=8) {
    // Rotate around the base (tips forward at peak)
    rotate([curl_deg, 0, 0]) {
        color([0.95, 0.98, 1.0, 0.9])  // White foam
        hull() {
            // Base of curl
            translate([0, 0, 0])
            sphere(r=size * 0.6);

            // Curl peak (tips forward)
            translate([size * 0.3, size * 0.8, size * 0.4])
            sphere(r=size * 0.5);

            // Curl tip (the lip that curls over)
            translate([size * 0.5, size * 1.2, -size * 0.2])
            sphere(r=size * 0.35);
        }

        // Foam texture - small bubbles
        for (i = [0:4]) {
            angle = i * 72 + 15;
            dist = size * 0.4;
            translate([
                dist * cos(angle) * 0.3,
                dist * sin(angle) * 0.5 + size * 0.3,
                size * 0.2
            ])
            sphere(r=size * 0.15);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                    COMPLETE CURL TRIGGER ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════
// Combines height calculation with curl visualization
// Input: base_phase (master animation phase), wave_index (which layer)

module curl_trigger_assembly(base_phase, wave_index=0, foam_size=8) {
    // Get wave parameters for this layer
    phase = base_phase + ZONE3_PHASES[wave_index];
    max_height = ZONE3_AMPLITUDES[wave_index];

    // Calculate current wave height
    wave_height = breaking_wave_cam_profile(phase, max_height);

    // Calculate curl angle based on height
    curl_deg = curl_angle(wave_height, max_height);

    // Optional: Get velocity for dynamic curl
    velocity = wave_velocity(phase, max_height);

    // Debug output
    echo(str("Wave ", wave_index, " - Height: ", wave_height,
             "mm, Curl: ", curl_deg, "°, Velocity: ", velocity));

    // Render curl foam at current angle
    curl_foam_element(curl_deg, foam_size);
}

// ═══════════════════════════════════════════════════════════════════════════════
//                         MECHANICAL REPRESENTATION
// ═══════════════════════════════════════════════════════════════════════════════
// Visual representation of the height-to-curl mechanism (for understanding)
// Bell-crank converts vertical motion to rotational curl

module curl_mechanism_diagram(wave_height, max_height=16) {
    curl_deg = curl_angle(wave_height, max_height);

    // Height pusher (input from wave)
    color([0.5, 0.5, 0.5])
    translate([0, 0, 0])
    cube([3, 3, wave_height]);

    // Pivot point
    color([0.3, 0.3, 0.3])
    translate([10, 0, max_height * 0.75])
    rotate([0, 90, 0])
    cylinder(d=4, h=5);

    // Bell crank arm
    color([0.6, 0.4, 0.2])
    translate([10, 0, max_height * 0.75])
    rotate([curl_deg, 0, 0])
    translate([0, 0, -2])
    cube([3, 20, 4]);

    // Connection to foam
    color([0.7, 0.7, 0.7])
    translate([10, 18, max_height * 0.75])
    rotate([curl_deg, 0, 0])
    sphere(d=3);
}

// ═══════════════════════════════════════════════════════════════════════════════
//                              TEST ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
// Uncomment to test curl behavior with animation

// test_phase = $t * 360;  // Full cycle
// test_height = breaking_wave_cam_profile(test_phase, 16);
//
// translate([0, 0, test_height])
// curl_trigger_assembly(test_phase, 0, 10);
//
// // Show wave height reference
// color([0.2, 0.4, 0.8, 0.3])
// cube([50, 5, test_height]);
