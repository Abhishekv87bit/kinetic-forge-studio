/*
 * WAVE OCEAN v5 - 2D PROFILE EXPORT FOR FUSION 360
 *
 * This file generates flat 2D profiles that can be exported as DXF
 * and imported into Fusion 360 as sketches.
 *
 * USAGE:
 * 1. Open in OpenSCAD
 * 2. Uncomment ONE profile at a time
 * 3. File → Export → Export as DXF
 * 4. Import DXF into Fusion 360 sketch
 *
 * Each profile is positioned at origin for easy import.
 */

$fn = 64;

// === PARAMETERS (match main file) ===
MODULE = 3;
PRESSURE_ANGLE = 20;
GEAR_TEETH = 20;
GEAR_PITCH_R = MODULE * GEAR_TEETH / 2;      // 30mm
GEAR_BASE_R = GEAR_PITCH_R * cos(PRESSURE_ANGLE);  // 28.19mm
GEAR_TIP_R = GEAR_PITCH_R + MODULE;          // 33mm
GEAR_ROOT_R = GEAR_PITCH_R - 1.25 * MODULE;  // 26.25mm

RACK_ADDENDUM = MODULE;
RACK_DEDENDUM = 1.25 * MODULE;
RACK_TOOTH_HEIGHT = RACK_ADDENDUM + RACK_DEDENDUM;

// === HELPER FUNCTIONS ===
function involute_point(base_r, angle_deg) =
    let(t = angle_deg * PI / 180)
    [base_r * (cos(angle_deg) + t * sin(angle_deg)),
     base_r * (sin(angle_deg) - t * cos(angle_deg))];

function inv_angle_at_r(base_r, r) =
    let(ratio = r / base_r)
    (ratio > 1) ? sqrt(ratio * ratio - 1) * 180 / PI : 0;

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 1: GEAR REFERENCE CIRCLES
// ═══════════════════════════════════════════════════════════════════════════
// Export this first to establish reference geometry in Fusion

module gear_reference_circles() {
    // Construction circles - import as construction geometry
    difference() {
        circle(r = GEAR_PITCH_R + 0.2);
        circle(r = GEAR_PITCH_R - 0.2);
    }
    difference() {
        circle(r = GEAR_BASE_R + 0.2);
        circle(r = GEAR_BASE_R - 0.2);
    }
    difference() {
        circle(r = GEAR_ROOT_R + 0.2);
        circle(r = GEAR_ROOT_R - 0.2);
    }
    difference() {
        circle(r = GEAR_TIP_R + 0.2);
        circle(r = GEAR_TIP_R - 0.2);
    }
    // Center crosshairs
    square([1, 70], center=true);
    square([70, 1], center=true);
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 2: SINGLE GEAR TOOTH
// ═══════════════════════════════════════════════════════════════════════════
// Import this, then use Circular Pattern × 20 in Fusion

module gear_tooth_profile() {
    inv_angle_tip = inv_angle_at_r(GEAR_BASE_R, GEAR_TIP_R);
    tooth_thick_linear = PI * MODULE / 2;
    tooth_half_angle = (tooth_thick_linear / GEAR_PITCH_R) * 180 / PI;

    // Generate involute points
    steps = 12;
    right_flank = [
        for (i = [0 : steps])
            let(a = (inv_angle_tip) * i / steps,
                pt = involute_point(GEAR_BASE_R, a),
                r = norm(pt), ang = atan2(pt.y, pt.x))
            [r * cos(ang - tooth_half_angle/2), r * sin(ang - tooth_half_angle/2)]
    ];

    left_flank = [for (i = [len(right_flank)-1 : -1 : 0])
        [-right_flank[i].x, right_flank[i].y]];

    // Root and tip arcs
    root_arc = [
        [GEAR_ROOT_R * sin(-tooth_half_angle * 0.8), GEAR_ROOT_R * cos(-tooth_half_angle * 0.8)],
        [GEAR_ROOT_R * sin(-tooth_half_angle * 0.4), GEAR_ROOT_R * cos(-tooth_half_angle * 0.4)],
        right_flank[0]
    ];

    tip_arc = [
        right_flank[len(right_flank)-1],
        [0, GEAR_TIP_R - 0.3],
        left_flank[0]
    ];

    end_arc = [
        left_flank[len(left_flank)-1],
        [GEAR_ROOT_R * sin(tooth_half_angle * 0.4), GEAR_ROOT_R * cos(tooth_half_angle * 0.4)],
        [GEAR_ROOT_R * sin(tooth_half_angle * 0.8), GEAR_ROOT_R * cos(tooth_half_angle * 0.8)]
    ];

    polygon(concat(root_arc, right_flank, tip_arc, left_flank, end_arc));
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 3: COMPLETE GEAR (2D)
// ═══════════════════════════════════════════════════════════════════════════
// Full gear profile - can be extruded directly in Fusion

module gear_complete_2d() {
    difference() {
        union() {
            circle(r = GEAR_ROOT_R);
            for (i = [0 : GEAR_TEETH - 1]) {
                rotate([0, 0, i * 360 / GEAR_TEETH])
                    gear_tooth_profile();
            }
        }
        // Bore
        circle(d = 15);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 4: SINGLE RACK TOOTH
// ═══════════════════════════════════════════════════════════════════════════
// Import this, then use Rectangular Pattern in Fusion (spacing = 9.42mm)

module rack_tooth_profile() {
    half_width_pitch = PI * MODULE / 4;
    root_half = half_width_pitch - RACK_ADDENDUM * tan(PRESSURE_ANGLE);
    tip_half = half_width_pitch + RACK_DEDENDUM * tan(PRESSURE_ANGLE);
    fillet = 0.75;
    chamfer = 0.3;

    polygon([
        [-root_half - fillet * 0.3, 0],
        [-root_half, fillet * 0.3],
        [-tip_half + chamfer, RACK_TOOTH_HEIGHT - chamfer],
        [-tip_half + chamfer * 0.3, RACK_TOOTH_HEIGHT],
        [tip_half - chamfer * 0.3, RACK_TOOTH_HEIGHT],
        [tip_half - chamfer, RACK_TOOTH_HEIGHT - chamfer],
        [root_half, fillet * 0.3],
        [root_half + fillet * 0.3, 0]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 5: ROD-END BEARING HOUSING
// ═══════════════════════════════════════════════════════════════════════════
// Cross-section for revolve in Fusion

module rod_end_housing_profile() {
    body_od = 16;
    body_width = 10;
    ball_d = 12;
    bore = 8;
    shank_od = 10;
    shank_length = 8;

    // Housing half-profile (revolve around Y axis)
    difference() {
        union() {
            // Main body
            translate([0, -body_width/2])
                square([body_od/2, body_width]);
            // Shank
            translate([0, body_width/2])
                square([shank_od/2, shank_length]);
        }
        // Ball socket (semicircle)
        translate([0, 0])
            circle(d = ball_d + 0.4);
        // Shank bore
        translate([0, body_width/2])
            square([bore/2 + 0.2, shank_length + 1]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 6: ROD-END BALL
// ═══════════════════════════════════════════════════════════════════════════
// Half-profile for revolve

module rod_end_ball_profile() {
    ball_d = 12;
    bore = 8;

    difference() {
        circle(d = ball_d);
        square([bore, ball_d + 2], center=true);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 7: CONNECTING ROD CROSS-SECTION
// ═══════════════════════════════════════════════════════════════════════════
// Extrude this along rod axis in Fusion

module rod_cross_section() {
    rod_width = 8;
    rod_height = 5;
    corner_r = 1.5;

    hull() {
        translate([-rod_width/2 + corner_r, -rod_height/2 + corner_r])
            circle(r = corner_r);
        translate([rod_width/2 - corner_r, -rod_height/2 + corner_r])
            circle(r = corner_r);
        translate([-rod_width/2 + corner_r, rod_height/2 - corner_r])
            circle(r = corner_r);
        translate([rod_width/2 - corner_r, rod_height/2 - corner_r])
            circle(r = corner_r);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 8: ROCKER BAR (TOP VIEW)
// ═══════════════════════════════════════════════════════════════════════════
// Extrude 6mm in Fusion, then add pivot/lightening holes

module rocker_bar_profile() {
    length = 100;
    width = 10;
    boss_d = 14;
    half = length / 2;

    hull() {
        // Main bar
        translate([-half + width/2, 0]) circle(d = width);
        translate([half - width/2, 0]) circle(d = width);
    }

    // End bosses
    translate([-half, 0]) circle(d = boss_d);
    translate([half, 0]) circle(d = boss_d);
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 9: PIVOT POST CROSS-SECTION
// ═══════════════════════════════════════════════════════════════════════════
// Square tube for extrusion

module pivot_post_section() {
    difference() {
        square([12, 12], center=true);
        square([8, 8], center=true);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         PROFILE 10: SHOULDER BOLT
// ═══════════════════════════════════════════════════════════════════════════
// Half-profile for revolve

module shoulder_bolt_profile() {
    head_d = 12;
    head_h = 4;
    shoulder_d = 8;
    shoulder_h = 10;
    thread_d = 6;
    thread_h = 6;

    // Profile for revolve (right side only)
    polygon([
        [0, 0],
        [head_d/2, 0],
        [head_d/2, head_h],
        [shoulder_d/2, head_h],
        [shoulder_d/2, head_h + shoulder_h],
        [thread_d/2 * 0.85, head_h + shoulder_h],
        [thread_d/2 * 0.85, head_h + shoulder_h + thread_h],
        [0, head_h + shoulder_h + thread_h]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════
//                              RENDER ONE PROFILE
// ═══════════════════════════════════════════════════════════════════════════
// UNCOMMENT ONE LINE AT A TIME, THEN EXPORT AS DXF

// gear_reference_circles();
// gear_tooth_profile();
gear_complete_2d();
// rack_tooth_profile();
// rod_end_housing_profile();
// rod_end_ball_profile();
// rod_cross_section();
// rocker_bar_profile();
// pivot_post_section();
// shoulder_bolt_profile();
