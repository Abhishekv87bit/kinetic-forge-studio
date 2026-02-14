// =========================================================
// DRIVE SYSTEM — Single Motor + Belt/Chain to 3 Helices
// =========================================================
// One motor (or hand crank) drives one helix shaft.
// Two belts distribute rotation to the other two helices.
// All 3 helices rotate at same speed (1:1 pulleys).
//
// Belt routing:
//   Motor → Helix 1 shaft end (direct coupling or short belt)
//   Helix 1 other end → Belt → Helix 2 shaft end
//   Helix 1 other end → Belt → Helix 3 shaft end
//   (or: Motor → central, then 3 belts out to each helix)
//
// Motor placement: configurable angle on frame.
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_MOTOR      = true;
SHOW_CRANK      = true;
SHOW_BELTS      = true;
SHOW_PULLEYS    = true;

// =========================================================
// STANDALONE RENDER
// =========================================================
drive_system_assembly(anim_t());


// =========================================================
// DRIVE SYSTEM ASSEMBLY
// =========================================================

module drive_system_assembly(t = 0) {
    crank_angle = t * 360;

    // Helix shaft endpoint positions (for belt routing)
    // Each helix shaft center is at a hex vertex.
    // The shaft runs perpendicular to slider direction.
    // Belt pulleys are at the shaft ENDS (above and below the cam stack).
    helix_positions = [for (tier_idx = [0 : 2])
        let(
            vertex_angle = HELIX_VERTEX_ANGLES[tier_idx],
            helix_r = FRAME_HEX_R + HELIX_DISTANCE,
            hx = helix_r * cos(vertex_angle),
            hy = helix_r * sin(vertex_angle),
            tier_z = (1 - tier_idx) * TIER_PITCH
        )
        [hx, hy, tier_z]
    ];

    // Motor/crank position — on the frame near Helix 1
    motor_r = FRAME_HEX_R + HELIX_DISTANCE + 40;
    motor_angle = MOTOR_POSITION_ANGLE;
    motor_x = motor_r * cos(motor_angle);
    motor_y = motor_r * sin(motor_angle);
    motor_z = helix_positions[0][2];  // same Z as Helix 1

    // Hand crank
    if (SHOW_CRANK) {
        translate([motor_x, motor_y, motor_z]) {
            // Crank shaft
            color(C_STEEL)
            rotate([0, 0, motor_angle + 90])
                rotate([0, 90, 0])
                    cylinder(d = 8, h = 20, center = true, $fn = 20);

            // Crank arm (rotates with animation)
            color([0.6, 0.3, 0.3])
            rotate([0, 0, crank_angle]) {
                translate([CRANK_ARM/2, 0, 0])
                    cube([CRANK_ARM, 8, 5], center = true);

                // Handle
                translate([CRANK_ARM, 0, 0])
                    color([0.2, 0.2, 0.2])
                    cylinder(d = CRANK_HANDLE_DIA, h = CRANK_HANDLE_LEN,
                             center = true, $fn = 20);
            }

            // Drive pulley at motor
            if (SHOW_PULLEYS)
                color(C_STEEL)
                cylinder(d = DRIVE_PULLEY_DIA, h = BELT_WIDTH, center = true, $fn = 30);
        }
    }

    // Motor (simplified box representation)
    if (SHOW_MOTOR) {
        translate([motor_x, motor_y, motor_z])
            color([0.3, 0.3, 0.4])
            translate([0, 0, -30])
                cube([40, 40, 30], center = true);
    }

    // Belt pulleys on each helix shaft end
    if (SHOW_PULLEYS) {
        for (tier_idx = [0 : 2]) {
            hp = helix_positions[tier_idx];
            color(C_STEEL)
            translate([hp[0], hp[1], hp[2]])
                cylinder(d = DRIVE_PULLEY_DIA, h = BELT_WIDTH, center = true, $fn = 30);
        }
    }

    // Belts (simplified as lines/tubes between pulleys)
    if (SHOW_BELTS) {
        // Belt: Motor → Helix 1
        belt_segment([motor_x, motor_y, motor_z], helix_positions[0]);

        // Belt: Helix 1 → Helix 2
        belt_segment(helix_positions[0], helix_positions[1]);

        // Belt: Helix 1 → Helix 3
        belt_segment(helix_positions[0], helix_positions[2]);
    }

    echo(str("=== DRIVE SYSTEM ==="));
    echo(str("Motor position: angle=", motor_angle, "° r=", motor_r, "mm"));
    echo(str("Belt 1→2 length: ",
        sqrt(pow(helix_positions[0][0]-helix_positions[1][0], 2) +
             pow(helix_positions[0][1]-helix_positions[1][1], 2) +
             pow(helix_positions[0][2]-helix_positions[1][2], 2)), "mm"));
    echo(str("Belt 1→3 length: ",
        sqrt(pow(helix_positions[0][0]-helix_positions[2][0], 2) +
             pow(helix_positions[0][1]-helix_positions[2][1], 2) +
             pow(helix_positions[0][2]-helix_positions[2][2], 2)), "mm"));
}


// =========================================================
// BELT SEGMENT (tube between two points)
// =========================================================

module belt_segment(p1, p2) {
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];
    dz = p2[2] - p1[2];
    length = sqrt(dx*dx + dy*dy + dz*dz);

    // Direction angles
    az = atan2(dy, dx);
    ay = -atan2(dz, sqrt(dx*dx + dy*dy));

    color(C_BELT)
    translate([p1[0], p1[1], p1[2]])
        rotate([0, 0, az])
            rotate([0, -ay, 0])
                // Belt as a flattened cylinder
                scale([1, 0.3, 1])
                    cylinder(d = BELT_WIDTH, h = length, $fn = 16);
}
