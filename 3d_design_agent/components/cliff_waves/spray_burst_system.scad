// ═══════════════════════════════════════════════════════════════════════════════
//                         SUBTLE SPRAY BURST SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════
// Spray particles triggered at wave impact moment
// User preference: Subtle foam (3-5mm particles, 5 particles, gentle appearance)
//
// Trigger: When wave is high AND falling (crash phase)
// ═══════════════════════════════════════════════════════════════════════════════

use <asymmetric_cam_profiles.scad>

// ═══════════════════════════════════════════════════════════════════════════════
//                           SPRAY PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════

SPRAY_PARTICLE_COUNT = 5;           // Number of spray particles
SPRAY_PARTICLE_SIZE_MIN = 1.5;      // Minimum particle radius (mm)
SPRAY_PARTICLE_SIZE_MAX = 2.5;      // Maximum particle radius (mm)
SPRAY_REACH = 5;                    // Max distance from impact point (mm)
SPRAY_OPACITY = 0.7;                // Particle transparency
SPRAY_HEIGHT_THRESHOLD = 0.7;       // Wave must be > 70% max height
SPRAY_VELOCITY_THRESHOLD = -0.3;    // Wave must be falling (negative velocity)

// Spray color (white foam)
SPRAY_COLOR = [0.95, 0.98, 1.0, SPRAY_OPACITY];

// ═══════════════════════════════════════════════════════════════════════════════
//                         SPRAY TRIGGER LOGIC
// ═══════════════════════════════════════════════════════════════════════════════
// Returns true when spray should be active (impact moment)

function spray_active(wave_height, max_height, velocity) =
    let(
        is_high = wave_height > (max_height * SPRAY_HEIGHT_THRESHOLD),
        is_falling = velocity < SPRAY_VELOCITY_THRESHOLD
    )
    is_high && is_falling;

// Spray intensity based on crash velocity
// Faster crash = more intense spray (0-1 range)
function spray_intensity(velocity) =
    let(
        // Velocity during crash is typically -0.5 to -2.0
        normalized = abs(velocity) / 2.0
    )
    min(1, max(0, normalized));

// ═══════════════════════════════════════════════════════════════════════════════
//                       DETERMINISTIC PARTICLE POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════
// Using fixed positions for consistent appearance (no randomness in preview)

// Pre-calculated spray particle offsets (deterministic)
// Format: [x_offset, y_offset, z_offset, size_factor]
SPRAY_PARTICLE_DATA = [
    [0.2, 0.8, 0.6, 1.0],     // Central upper
    [-0.4, 0.5, 0.3, 0.8],    // Left
    [0.5, 0.6, 0.4, 0.7],     // Right
    [0.0, 0.3, 0.9, 0.6],     // High
    [-0.2, 0.4, 0.2, 0.9]     // Low left
];

// ═══════════════════════════════════════════════════════════════════════════════
//                         SPRAY VISUALIZATION MODULE
// ═══════════════════════════════════════════════════════════════════════════════
// Renders spray particles at impact point

module spray_particles(intensity=1.0) {
    if (intensity > 0.1) {
        color(SPRAY_COLOR)
        for (i = [0:SPRAY_PARTICLE_COUNT-1]) {
            // Get pre-calculated position
            data = SPRAY_PARTICLE_DATA[i];

            // Scale position by reach and intensity
            x = data[0] * SPRAY_REACH * intensity;
            y = data[1] * SPRAY_REACH * intensity;
            z = data[2] * SPRAY_REACH * intensity * 0.7;  // Less vertical spread

            // Scale particle size
            size_factor = data[3];
            base_size = SPRAY_PARTICLE_SIZE_MIN +
                       (SPRAY_PARTICLE_SIZE_MAX - SPRAY_PARTICLE_SIZE_MIN) * size_factor;
            particle_size = base_size * intensity;

            translate([x, y, z])
            sphere(r=particle_size, $fn=12);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                     COMPLETE SPRAY BURST ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════
// Combines trigger logic with spray visualization
// Position at cliff impact point

module spray_burst_assembly(base_phase, wave_index=0, max_height=16) {
    // Get wave state
    phase = base_phase + ZONE3_PHASES[wave_index];
    wave_height = breaking_wave_cam_profile(phase, max_height);
    velocity = wave_velocity(phase, max_height);

    // Check if spray should be active
    is_active = spray_active(wave_height, max_height, velocity);

    if (is_active) {
        // Calculate intensity from crash velocity
        intensity = spray_intensity(velocity);

        // Debug output
        echo(str("SPRAY ACTIVE - Wave ", wave_index,
                 ", Height: ", wave_height,
                 ", Velocity: ", velocity,
                 ", Intensity: ", intensity));

        // Render spray particles
        spray_particles(intensity);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                         CLIFF IMPACT MARKER
// ═══════════════════════════════════════════════════════════════════════════════
// Visual reference for where spray originates

module cliff_impact_point() {
    color([0.4, 0.35, 0.3, 0.5])  // Rock color
    hull() {
        translate([0, 0, 0])
        cube([3, 3, 1]);
        translate([1, 1, 5])
        sphere(r=1);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//                    INTEGRATED SPRAY + IMPACT MODULE
// ═══════════════════════════════════════════════════════════════════════════════
// Positions spray at cliff face with optional impact marker

module cliff_spray_system(base_phase, wave_index=0, max_height=16, show_impact_point=false) {
    // Impact point reference (optional)
    if (show_impact_point) {
        cliff_impact_point();
    }

    // Spray burst (positioned above impact point, projecting outward)
    translate([0, 0, 3])  // Slightly above impact
    rotate([0, 0, 180])   // Project away from cliff
    spray_burst_assembly(base_phase, wave_index, max_height);
}

// ═══════════════════════════════════════════════════════════════════════════════
//                              TEST ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════
// Uncomment to test spray timing with animation

// test_phase = $t * 360;
// max_h = 16;
// height = breaking_wave_cam_profile(test_phase, max_h);
// vel = wave_velocity(test_phase, max_h);
//
// // Wave height indicator
// color([0.2, 0.4, 0.8, 0.5])
// cube([30, 3, height]);
//
// // Velocity indicator (green=rising, red=falling)
// vel_color = vel > 0 ? [0.2, 0.8, 0.2] : [0.8, 0.2, 0.2];
// color(vel_color)
// translate([35, 0, max_h/2 + vel * 5])
// cube([3, 3, 3]);
//
// // Spray system at cliff
// translate([0, 10, height])
// cliff_spray_system(test_phase, 0, max_h, true);
//
// // Status text
// echo(str("Phase: ", test_phase, "° | Height: ", height, "mm | Velocity: ", vel));
