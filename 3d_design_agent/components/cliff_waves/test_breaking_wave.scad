// ═══════════════════════════════════════════════════════════════════════════════
//                    TEST: BREAKING WAVE MOTION VERIFICATION
// ═══════════════════════════════════════════════════════════════════════════════
// Use this file to test the wave motion at key animation points
// Run with Animation enabled: View → Animate, FPS=30, Steps=100
// ═══════════════════════════════════════════════════════════════════════════════

use <asymmetric_cam_profiles.scad>
use <curl_trigger_mechanism.scad>
use <spray_burst_system.scad>

$fn = 32;

// ═══════════════════════════════════════════════════════════════════════════════
//                          ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════

// Convert $t (0-1) to phase (0-360°)
test_phase = $t * 360;

// Wave parameters
MAX_HEIGHT = 16;
WAVE_PHASES = [0, 35, 70, 105];
WAVE_AMPLITUDES = [12, 14, 12, 10];
WAVE_COLORS = [
    [0.95, 0.98, 1.0],    // Front (white foam)
    [0.6, 0.8, 0.95],     // Light blue
    [0.4, 0.65, 0.85],    // Medium blue
    [0.25, 0.5, 0.75]     // Back (deep blue)
];

// ═══════════════════════════════════════════════════════════════════════════════
//                          MULTI-WAVE VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════════

module wave_layer(layer_index, base_phase) {
    phase = base_phase + WAVE_PHASES[layer_index];
    max_h = WAVE_AMPLITUDES[layer_index];
    height = breaking_wave_cam_profile(phase, max_h);
    velocity = wave_velocity(phase, max_h);

    // Wave bar visualization
    translate([layer_index * 25, 0, 0]) {
        // Base
        color([0.3, 0.3, 0.3])
        cube([20, 5, 2]);

        // Wave height bar
        color(WAVE_COLORS[layer_index])
        translate([2, 1, 2])
        cube([16, 3, height]);

        // Curl indicator (front wave only)
        if (layer_index == 0) {
            curl_deg = curl_angle(height, max_h);
            translate([10, 2.5, 2 + height]) {
                rotate([curl_deg, 0, 0])
                color([1, 1, 1])
                translate([0, 5, 0])
                sphere(r=3);
            }

            // Spray indicator
            is_crashing = height > (max_h * 0.7) && velocity < -0.3;
            if (is_crashing) {
                translate([10, 2.5, 2 + height + 5])
                color([1, 1, 1, 0.7])
                for (i = [0:4]) {
                    translate([i * 2 - 4, 0, i])
                    sphere(r=1.5);
                }
            }
        }

        // Label
        translate([5, -8, 0])
        color([0.5, 0.5, 0.5])
        text(str("L", layer_index), size=5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                          MAIN TEST SCENE
// ═══════════════════════════════════════════════════════════════════════════════

// Title
translate([0, 40, 0])
color([0.2, 0.2, 0.2])
text("BREAKING WAVE TEST", size=8);

// Phase indicator
translate([0, 30, 0])
color([0.4, 0.4, 0.4])
text(str("Phase: ", round(test_phase), "°"), size=5);

// Status text
front_height = breaking_wave_cam_profile(test_phase, 12);
front_velocity = wave_velocity(test_phase, 12);
status = front_velocity > 0.1 ? "BUILDING" :
         front_velocity < -0.5 ? "CRASHING" :
         front_height > 10 ? "PEAK" : "RETREAT";

translate([0, 22, 0])
color(status == "CRASHING" ? [0.8, 0.2, 0.2] :
      status == "PEAK" ? [0.8, 0.6, 0.2] :
      status == "BUILDING" ? [0.2, 0.6, 0.2] : [0.4, 0.4, 0.6])
text(str("Status: ", status), size=5);

// Wave layers
for (i = [0:3]) {
    wave_layer(i, test_phase);
}

// Cliff reference (static)
translate([110, 0, 0])
color([0.4, 0.35, 0.3])
cube([10, 5, 25]);

// ═══════════════════════════════════════════════════════════════════════════════
//                          TIMING PROFILE GRAPH
// ═══════════════════════════════════════════════════════════════════════════════

translate([0, -30, 0]) {
    // Graph background
    color([0.9, 0.9, 0.9])
    cube([120, 20, 0.5]);

    // Profile curve
    color([0.2, 0.4, 0.8])
    for (theta = [0:5:355]) {
        h = breaking_wave_cam_profile(theta, 16);
        translate([theta / 3, h, 1])
        sphere(r=0.8, $fn=8);
    }

    // Current position marker
    translate([test_phase / 3, breaking_wave_cam_profile(test_phase, 16), 2])
    color([1, 0, 0])
    sphere(r=2);

    // Phase markers
    for (p = [0, 200, 280, 360]) {
        translate([p / 3, -3, 0])
        color([0.3, 0.3, 0.3])
        text(str(p, "°"), size=3);
    }

    // Labels
    translate([30, -8, 0])
    color([0.2, 0.6, 0.2])
    text("BUILD", size=3);

    translate([70, -8, 0])
    color([0.8, 0.2, 0.2])
    text("CRASH", size=3);

    translate([100, -8, 0])
    color([0.4, 0.4, 0.6])
    text("RETREAT", size=3);
}

// ═══════════════════════════════════════════════════════════════════════════════
//                          TEST CHECKPOINTS
// ═══════════════════════════════════════════════════════════════════════════════
// Expected behavior at key $t values:
//
// $t = 0.00 (0°)   → All waves near rest, front wave starting to build
// $t = 0.25 (90°)  → Back waves building, front wave mid-rise
// $t = 0.45 (162°) → Front wave high, curl starting to trigger
// $t = 0.55 (198°) → Front wave at peak, curl fully forward
// $t = 0.60 (216°) → CRASHING - spray active, rapid height drop
// $t = 0.75 (270°) → Front wave draining, back waves in various phases
// $t = 0.90 (324°) → All waves low, retreating to start position

echo("═══════════════════════════════════════════════════════════════════════");
echo(str("TEST CHECKPOINT at $t=", $t, " (", round(test_phase), "°)"));
echo(str("  Front wave height: ", round(front_height * 10) / 10, "mm"));
echo(str("  Front wave velocity: ", round(front_velocity * 100) / 100));
echo(str("  Status: ", status));
echo(str("  Curl angle: ", round(curl_angle(front_height, 12) * 10) / 10, "°"));
echo("═══════════════════════════════════════════════════════════════════════");
