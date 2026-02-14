/*
 * TWISTED CAM - Helical Ridge Surface
 *
 * Printable part: 1x
 * Print orientation: Horizontal along X axis
 * Supports: Minimal (smooth surfaces)
 *
 * Features:
 * - Core cylinder with single helical ridge
 * - Ridge spirals around, pushing slats up as it passes
 * - Shaft hole with set screws for 8mm rod
 * - Smooth transition on ridge for quiet operation
 */

include <../common.scad>

$fn = 96;  // High quality for smooth cam surface

// ============================================
// MAIN TWISTED CAM MODULE
// ============================================

module twisted_cam() {
    difference() {
        union() {
            // Core cylinder with helical ridge
            cam_body();

            // End caps for strength
            end_caps();
        }

        // Shaft hole
        shaft_hole();

        // Set screw holes
        set_screw_holes();
    }
}

// ============================================
// CAM BODY - Core with Helical Ridge
// ============================================

module cam_body() {
    // Build cam as series of cross-sections
    segments = 200;
    dx = CAM_LENGTH / segments;

    for (i = [0 : segments - 1]) {
        x = -CAM_LENGTH/2 + i * dx;
        phase = helix_phase(x);

        translate([x, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height = dx + 0.1)
            cam_profile(phase);
    }
}

// Cross-section profile at given phase angle
module cam_profile(phase) {
    // Smooth sinusoidal ridge that rotates around circumference
    points = [for (a = [0 : 360/72 : 359])
        let(
            // Single smooth ridge (cosine peak)
            // Phase determines where the ridge is around the circumference
            ridge = CAM_RIDGE_HEIGHT * smooth_ridge(a - phase)
        )
        let(r = CAM_CORE_RADIUS + ridge)
        [r * cos(a), r * sin(a)]
    ];
    polygon(points);
}

// Smooth ridge function - single bump, not harsh
function smooth_ridge(angle) =
    let(a = ((angle % 360) + 360) % 360)  // Normalize to 0-360
    let(
        // Use smoothstep-like function for gradual rise/fall
        // Ridge is centered at 90° (top), spans about 120°
        half_width = 60,
        dist = min(abs(a - 90), abs(a - 90 + 360), abs(a - 90 - 360))
    )
    dist < half_width ?
        pow(cos(dist * 90 / half_width), 2) :  // Smooth cosine falloff
        0;

// ============================================
// END CAPS
// ============================================

module end_caps() {
    cap_thickness = 5;

    // Left cap
    translate([-CAM_LENGTH/2 - cap_thickness, 0, 0])
    rotate([0, 90, 0])
        cylinder(r = CAM_CORE_RADIUS + 2, h = cap_thickness);

    // Right cap
    translate([CAM_LENGTH/2, 0, 0])
    rotate([0, 90, 0])
        cylinder(r = CAM_CORE_RADIUS + 2, h = cap_thickness);
}

// ============================================
// SHAFT HOLE
// ============================================

module shaft_hole() {
    rotate([0, 90, 0])
        cylinder(d = SHAFT_HOLE, h = CAM_LENGTH + 20, center = true);
}

// ============================================
// SET SCREW HOLES
// ============================================

module set_screw_holes() {
    // M3 set screws to lock cam on shaft
    // Two holes, 90° apart, near each end

    for (x_sign = [-1, 1]) {
        x = x_sign * (CAM_LENGTH/2 - 15);

        // First set screw (from top)
        translate([x, 0, 0])
        rotate([0, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS + 5);

        // Second set screw (90° rotated)
        translate([x, 0, 0])
        rotate([90, 0, 0])
            cylinder(d = M3_HOLE, h = CAM_CORE_RADIUS + 5);
    }
}

// ============================================
// RENDER
// ============================================

color(C_CAM)
twisted_cam();

// Show shaft for reference
%rotate([0, 90, 0])
    cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);

// ============================================
// INFO
// ============================================

echo("=== TWISTED CAM ===");
echo(str("Length: ", CAM_LENGTH, "mm"));
echo(str("Core radius: ", CAM_CORE_RADIUS, "mm"));
echo(str("Max radius: ", CAM_MAX_RADIUS, "mm"));
echo(str("Ridge height: ", CAM_RIDGE_HEIGHT, "mm"));
echo(str("Helix turns: ", HELIX_TURNS));
echo("");
echo("Print: 1x");
echo("Orientation: Horizontal (X axis along bed)");
echo("Material: PLA or PETG");
echo("Infill: 20-30% for weight");
