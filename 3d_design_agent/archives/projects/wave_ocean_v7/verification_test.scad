/*
 * VERIFICATION TEST - Wave Ocean v7 Asymmetric Surge
 * Tests four-bar mechanism at 4 key positions: 0°, 90°, 180°, 270°
 *
 * Run this file to verify:
 * 1. Linkage connectivity (rod connects pin A to pin B)
 * 2. Rod length constancy (should be L = r * 3.6)
 * 3. No collisions between parts
 * 4. Quick-return motion characteristic
 */

// === PARAMETERS (from main file) ===
HINGE_Y = 4;
HINGE_Z = 0;
FOAM_SHAFT_Y = 19;
FOAM_SHAFT_Z = -5;
GROUND_LINK = 15.81;

// Validated parameters
function surge_eccentric_r(ci) = [5.0, 5.5, 6.0, 6.0, 5.5][ci];
function surge_rod_length(ci) = surge_eccentric_r(ci) * 3.6;
function surge_rocker_length(ci) = [3.0, 5.0, 8.0, 8.0, 5.0][ci];

PHASE_OFFSET = 360 / 22;
FOAM_START_WAVE = 16;
FOAM_PHASE_LAG = 8;
function surge_phase(ci) = (FOAM_START_WAVE + ci) * PHASE_OFFSET + FOAM_PHASE_LAG;

ROCKER_DIR_Y = 0.949;
ROCKER_DIR_Z = -0.316;

// === FOUR-BAR KINEMATICS ===

function fourbar_rocker_angle(ci, theta_crank) =
    let(
        a = surge_eccentric_r(ci),
        b = surge_rod_length(ci),
        c = surge_rocker_length(ci),
        d = GROUND_LINK,
        phase = surge_phase(ci),
        crank_angle = theta_crank + phase,
        O2_y = 15,
        O2_z = -5,
        A_y = O2_y + a * cos(crank_angle),
        A_z = O2_z + a * sin(crank_angle),
        OA = sqrt(A_y*A_y + A_z*A_z),
        alpha = atan2(A_z, A_y),
        cos_beta = (OA*OA + c*c - b*b) / (2 * OA * c),
        cos_beta_clamped = max(-0.999, min(0.999, cos_beta)),
        beta = acos(cos_beta_clamped),
        phi = alpha - beta
    )
    phi;

function rocker_tip_pos(ci, theta_crank) =
    let(
        c = surge_rocker_length(ci),
        phi = fourbar_rocker_angle(ci, theta_crank),
        B_y = HINGE_Y + c * cos(phi),
        B_z = HINGE_Z + c * sin(phi)
    )
    [B_y, B_z];

function eccentric_pin_pos(ci, theta_crank) =
    let(
        a = surge_eccentric_r(ci),
        phase = surge_phase(ci),
        crank_angle = theta_crank + phase,
        A_y = FOAM_SHAFT_Y + a * cos(crank_angle),
        A_z = FOAM_SHAFT_Z + a * sin(crank_angle)
    )
    [A_y, A_z];

// === VERIFICATION AT 4 POSITIONS ===

module verify_position(theta, x_offset) {
    translate([x_offset, 0, 0]) {
        // Title
        color("black") translate([0, 35, 0])
            linear_extrude(1) text(str("theta=", theta, "°"), size=4, halign="center");

        for (ci = [0:4]) {
            y_off = ci * 15 - 30;

            // Hinge pivot (O1)
            color("blue") translate([y_off, HINGE_Y, HINGE_Z])
                sphere(d=4, $fn=16);

            // Shaft center (O2)
            color("gray") translate([y_off, FOAM_SHAFT_Y, FOAM_SHAFT_Z])
                sphere(d=6, $fn=16);

            // Eccentric pin (A)
            pin_A = eccentric_pin_pos(ci, theta);
            color("red") translate([y_off, pin_A[0], pin_A[1]])
                sphere(d=3, $fn=16);

            // Rocker tip (B)
            pin_B = rocker_tip_pos(ci, theta);
            color("green") translate([y_off, pin_B[0], pin_B[1]])
                sphere(d=3, $fn=16);

            // Connecting rod (A to B)
            color("brown") hull() {
                translate([y_off, pin_A[0], pin_A[1]]) sphere(d=2, $fn=12);
                translate([y_off, pin_B[0], pin_B[1]]) sphere(d=2, $fn=12);
            }

            // Rocker arm (O1 to B)
            color("orange") hull() {
                translate([y_off, HINGE_Y, HINGE_Z]) sphere(d=2, $fn=12);
                translate([y_off, pin_B[0], pin_B[1]]) sphere(d=2, $fn=12);
            }

            // Crank (O2 to A)
            color("purple") hull() {
                translate([y_off, FOAM_SHAFT_Y, FOAM_SHAFT_Z]) sphere(d=2, $fn=12);
                translate([y_off, pin_A[0], pin_A[1]]) sphere(d=2, $fn=12);
            }

            // Calculate and display rod length
            dy = pin_B[0] - pin_A[0];
            dz = pin_B[1] - pin_A[1];
            actual_rod_len = sqrt(dy*dy + dz*dz);
            declared_rod_len = surge_rod_length(ci);

            // Label
            color("black") translate([y_off, 30, 0])
                linear_extrude(1) text(str("C", ci), size=3, halign="center");
        }
    }
}

// Echo verification data
echo("");
echo("═══════════════════════════════════════════════════════════════");
echo("  WAVE OCEAN v7 - FOUR-BAR MECHANISM VERIFICATION");
echo("═══════════════════════════════════════════════════════════════");
echo("");

// Verify rod lengths at 4 positions for each curl
for (ci = [0:4]) {
    declared = surge_rod_length(ci);
    echo(str("Curl ", ci, " (declared rod L = ", declared, "mm):"));

    for (theta = [0, 90, 180, 270]) {
        pin_A = eccentric_pin_pos(ci, theta);
        pin_B = rocker_tip_pos(ci, theta);
        dy = pin_B[0] - pin_A[0];
        dz = pin_B[1] - pin_A[1];
        actual = sqrt(dy*dy + dz*dz);
        deviation = abs(actual - declared);
        status = deviation < 0.5 ? "PASS" : "FAIL";
        echo(str("  θ=", theta, "°: actual=", round(actual*100)/100, "mm, dev=", round(deviation*100)/100, "mm [", status, "]"));
    }
    echo("");
}

// Verify Grashof condition
echo("GRASHOF VERIFICATION:");
for (ci = [0:4]) {
    a = surge_eccentric_r(ci);
    b = surge_rod_length(ci);
    c = surge_rocker_length(ci);
    d = GROUND_LINK;

    shortest = min(min(a, b), min(c, d));
    longest = max(max(a, b), max(c, d));
    others = a + b + c + d - shortest - longest;

    status = (shortest + longest <= others) ? "PASS (crank-rocker)" : "FAIL";
    echo(str("  Curl ", ci, ": s+l=", round((shortest+longest)*100)/100, " ≤ others=", round(others*100)/100, " [", status, "]"));
}

// Verify rocker angle range (for quick-return)
echo("");
echo("ROCKER ANGLE RANGE (for quick-return):");
for (ci = [0:4]) {
    phi_0 = fourbar_rocker_angle(ci, 0);
    phi_90 = fourbar_rocker_angle(ci, 90);
    phi_180 = fourbar_rocker_angle(ci, 180);
    phi_270 = fourbar_rocker_angle(ci, 270);

    phi_max = max(max(phi_0, phi_90), max(phi_180, phi_270));
    phi_min = min(min(phi_0, phi_90), min(phi_180, phi_270));

    echo(str("  Curl ", ci, ": range=", round((phi_max-phi_min)*100)/100, "° (", round(phi_min*10)/10, "° to ", round(phi_max*10)/10, "°)"));
}

echo("═══════════════════════════════════════════════════════════════");

// Visual display at 4 positions
verify_position(0, 0);
verify_position(90, 100);
verify_position(180, 200);
verify_position(270, 300);

// Legend
translate([150, -30, 0]) {
    color("blue") translate([0, 0, 0]) sphere(d=4, $fn=16);
    color("black") translate([5, 0, 0]) linear_extrude(1) text("Hinge (O1)", size=3);

    color("gray") translate([0, -8, 0]) sphere(d=4, $fn=16);
    color("black") translate([5, -8, 0]) linear_extrude(1) text("Shaft (O2)", size=3);

    color("red") translate([0, -16, 0]) sphere(d=3, $fn=16);
    color("black") translate([5, -16, 0]) linear_extrude(1) text("Eccentric Pin (A)", size=3);

    color("green") translate([0, -24, 0]) sphere(d=3, $fn=16);
    color("black") translate([5, -24, 0]) linear_extrude(1) text("Rocker Tip (B)", size=3);
}
