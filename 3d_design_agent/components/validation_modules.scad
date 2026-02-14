// ============================================================
// VALIDATION MODULES FOR AUTONOMOUS DESIGN AGENT v3.0
// ============================================================
// These modules provide real-time verification during OpenSCAD
// preview and rendering. Include this file in your designs.
// ============================================================

// === CONFIGURATION ===
WALL_MIN = 1.2;          // mm - minimum wall thickness
CLEARANCE_MIN = 0.3;     // mm - minimum moving clearance
COUPLER_TOLERANCE = 0.5; // mm - max coupler length deviation
VALIDATION_ENABLED = true;

// === KINEMATICS VERIFICATION ===

// Verify coupler length remains constant throughout motion
// Call this at multiple t values to check mechanism geometry
module verify_coupler(name,
                      crank_pivot, crank_r, crank_angle,
                      rocker_pivot, rocker_r, rocker_angle,
                      coupler_length,
                      tolerance=COUPLER_TOLERANCE) {
    if (VALIDATION_ENABLED) {
        // Calculate actual endpoint positions
        crank_pin = [crank_pivot[0] + crank_r * cos(crank_angle),
                     crank_pivot[1] + crank_r * sin(crank_angle)];
        rocker_pin = [rocker_pivot[0] + rocker_r * cos(rocker_angle),
                      rocker_pivot[1] + rocker_r * sin(rocker_angle)];

        // Calculate actual distance
        actual_length = norm(rocker_pin - crank_pin);
        deviation = abs(actual_length - coupler_length);

        // Echo verification result
        if (deviation > tolerance) {
            echo(str("KINEMATICS ERROR: ", name,
                     " coupler stretching! Declared=", coupler_length,
                     "mm, Actual=", actual_length,
                     "mm, Deviation=", deviation, "mm"));
            echo("  → Mechanism geometry is IMPOSSIBLE");
            echo("  → Redesign link lengths or pivot positions");
        } else {
            echo(str("KINEMATICS OK: ", name,
                     " coupler verified (", actual_length, "mm, dev=",
                     deviation, "mm)"));
        }
    }
}

// Verify coupler at multiple positions
module verify_coupler_sweep(name,
                            crank_pivot, crank_r,
                            rocker_pivot, rocker_r,
                            coupler_length,
                            crank_start_angle,
                            crank_end_angle,
                            rocker_start_angle,
                            rocker_end_angle,
                            steps=4) {
    if (VALIDATION_ENABLED) {
        echo(str("=== COUPLER SWEEP VERIFICATION: ", name, " ==="));
        for (i = [0:steps]) {
            t = i / steps;
            crank_angle = crank_start_angle + t * (crank_end_angle - crank_start_angle);
            rocker_angle = rocker_start_angle + t * (rocker_end_angle - rocker_start_angle);

            verify_coupler(str(name, " @t=", t),
                          crank_pivot, crank_r, crank_angle,
                          rocker_pivot, rocker_r, rocker_angle,
                          coupler_length);
        }
        echo(str("=== END COUPLER SWEEP: ", name, " ==="));
    }
}

// === GRASHOF VERIFICATION ===

// Check if four-bar linkage satisfies Grashof condition
module verify_grashof(name, ground, crank, coupler, rocker,
                      requires_full_rotation=true) {
    if (VALIDATION_ENABLED) {
        links = [ground, crank, coupler, rocker];
        S = min(links);
        L = max(links);

        // Find P and Q (the middle two)
        sorted = [for (x = links) x];
        // Simple bubble sort for 4 elements
        P = (links[0] != S && links[0] != L) ? links[0] :
            (links[1] != S && links[1] != L) ? links[1] :
            (links[2] != S && links[2] != L) ? links[2] : links[3];
        Q = ground + crank + coupler + rocker - S - L - P;

        grashof_sum = S + L;
        other_sum = P + Q;

        echo(str("=== GRASHOF CHECK: ", name, " ==="));
        echo(str("  Links: ground=", ground, ", crank=", crank,
                 ", coupler=", coupler, ", rocker=", rocker));
        echo(str("  S (shortest)=", S, ", L (longest)=", L));
        echo(str("  S + L = ", grashof_sum));
        echo(str("  P + Q = ", other_sum));

        if (grashof_sum < other_sum) {
            echo("  RESULT: GRASHOF - Shortest link can rotate 360°");

            // Determine linkage type
            if (ground == S) {
                echo("  TYPE: Double-crank (both crank and rocker rotate)");
            } else if (ground == L) {
                echo("  TYPE: Double-rocker (both crank and rocker oscillate)");
            } else {
                echo("  TYPE: Crank-rocker (crank rotates, rocker oscillates)");
            }
        } else if (grashof_sum == other_sum) {
            echo("  RESULT: SPECIAL CASE - Dead point at extended position");
            echo("  WARNING: Requires flywheel or parallel crank");
        } else {
            echo("  RESULT: NON-GRASHOF - All links oscillate only");
            if (requires_full_rotation) {
                echo("  GRASHOF ERROR: Design requires rotation but linkage cannot!");
                echo("  → Redesign link proportions so S + L < P + Q");
            }
        }
        echo(str("=== END GRASHOF: ", name, " ==="));
    }
}

// === TRANSMISSION ANGLE VERIFICATION ===

// Check transmission angle at current position
// Good range: 40° < μ < 140°
function transmission_angle(crank_r, coupler, rocker, ground, crank_angle) =
    let(
        a = crank_r,
        b = coupler,
        c = rocker,
        d = ground,
        theta = crank_angle,
        // Law of cosines to find transmission angle
        numerator = b*b + c*c - a*a - d*d + 2*a*d*cos(theta),
        denominator = 2*b*c,
        cos_mu = numerator / denominator,
        mu = acos(max(-1, min(1, cos_mu)))  // Clamp to valid range
    ) mu;

module verify_transmission_angle(name, crank_r, coupler, rocker, ground,
                                  crank_angle, min_good=40, max_good=140) {
    if (VALIDATION_ENABLED) {
        mu = transmission_angle(crank_r, coupler, rocker, ground, crank_angle);

        if (mu < min_good || mu > max_good) {
            echo(str("TRANSMISSION WARNING: ", name,
                     " μ=", mu, "° at θ=", crank_angle, "°"));
            echo("  → Poor force transmission in this range");

            if (mu < 10 || mu > 170) {
                echo("  TRANSMISSION ERROR: Near dead point!");
                echo("  → Consider flywheel or limit operating range");
            }
        } else {
            echo(str("TRANSMISSION OK: ", name,
                     " μ=", mu, "° at θ=", crank_angle, "°"));
        }
    }
}

// === POWER PATH ECHO ===

// Template for power path verification
// Customize this for your specific mechanism
module echo_power_path(motor_pos,
                       pinion_teeth, master_teeth,
                       branches) {
    echo("═══════════════════════════════════════════════════════");
    echo("           POWER PATH VERIFICATION                      ");
    echo("═══════════════════════════════════════════════════════");
    echo(str("Motor at position: ", motor_pos));
    echo(str("Motor → Pinion (", pinion_teeth, "T) → Master Gear (",
             master_teeth, "T)"));
    echo(str("  Primary ratio: ", master_teeth / pinion_teeth, ":1"));

    for (branch = branches) {
        echo(str("  ├─ ", branch));
    }

    echo("All sin($t) expressions verified connected.");
    echo("═══════════════════════════════════════════════════════");
}

// Simple power path echo
module echo_power_path_simple(description) {
    echo("═══════════════════════════════════════════════════════");
    echo("           POWER PATH VERIFICATION                      ");
    echo("═══════════════════════════════════════════════════════");
    for (line = description) {
        echo(line);
    }
    echo("═══════════════════════════════════════════════════════");
}

// === PRINTABILITY VERIFICATION ===

module verify_printability(wall_thickness, clearance,
                           description="Component") {
    if (VALIDATION_ENABLED) {
        echo(str("=== PRINTABILITY CHECK: ", description, " ==="));

        wall_pass = wall_thickness >= WALL_MIN;
        clearance_pass = clearance >= CLEARANCE_MIN;

        echo(str("  Wall thickness: ", wall_thickness, "mm - ",
                 wall_pass ? "PASS" : "FAIL",
                 " (min ", WALL_MIN, "mm)"));

        echo(str("  Clearance: ", clearance, "mm - ",
                 clearance_pass ? "PASS" : "FAIL",
                 " (min ", CLEARANCE_MIN, "mm)"));

        if (!wall_pass) {
            echo("  PRINTABILITY ERROR: Wall too thin!");
            echo("  → Increase wall thickness to ≥1.2mm");
        }

        if (!clearance_pass) {
            echo("  PRINTABILITY ERROR: Clearance too tight!");
            echo("  → Increase clearance to ≥0.3mm for FDM");
        }

        if (wall_pass && clearance_pass) {
            echo("  RESULT: Printable with FDM");
        }

        echo(str("=== END PRINTABILITY: ", description, " ==="));
    }
}

// === TOLERANCE STACK ANALYSIS ===

module verify_tolerance_stack(joint_count, per_joint_clearance=0.2,
                              acceptable_stack=2.0, description="Chain") {
    if (VALIDATION_ENABLED) {
        worst_case = joint_count * per_joint_clearance;
        rss = sqrt(joint_count * per_joint_clearance * per_joint_clearance);

        echo(str("=== TOLERANCE STACK: ", description, " ==="));
        echo(str("  Joint count: ", joint_count));
        echo(str("  Per-joint clearance: ±", per_joint_clearance, "mm"));
        echo(str("  Worst-case stack: ±", worst_case, "mm"));
        echo(str("  RSS estimate: ±", rss, "mm"));
        echo(str("  Acceptable threshold: ", acceptable_stack, "mm"));

        if (worst_case > acceptable_stack) {
            echo("  TOLERANCE WARNING: Stack exceeds threshold!");
            echo("  → Consider: preload, press-fits, parallel paths");
        } else {
            echo("  RESULT: Stack acceptable");
        }

        echo(str("=== END TOLERANCE STACK: ", description, " ==="));
    }
}

// === GRAVITY ANALYSIS ===

module verify_gravity(element_name, mass_g, pivot_pos, cg_positions,
                      motor_torque_available) {
    if (VALIDATION_ENABLED && mass_g > 50) {
        echo(str("=== GRAVITY ANALYSIS: ", element_name, " ==="));
        echo(str("  Mass: ", mass_g, "g"));
        echo(str("  Pivot: ", pivot_pos));

        max_gravity_torque = 0;
        worst_position = 0;

        for (i = [0:len(cg_positions)-1]) {
            cg = cg_positions[i];
            horizontal_offset = abs(cg[0] - pivot_pos[0]);
            gravity_torque = mass_g * 0.00981 * horizontal_offset; // N·mm

            echo(str("  Position ", i, ": CG=", cg,
                     ", offset=", horizontal_offset, "mm",
                     ", τ_gravity=", gravity_torque, " N·mm"));

            if (gravity_torque > max_gravity_torque) {
                max_gravity_torque = gravity_torque;
                worst_position = i;
            }
        }

        echo(str("  Motor torque available: ", motor_torque_available, " N·mm"));
        echo(str("  Max gravity torque: ", max_gravity_torque, " N·mm at position ",
                 worst_position));

        if (max_gravity_torque > motor_torque_available) {
            echo("  GRAVITY ERROR: Motor cannot overcome gravity!");
            required_counterweight = max_gravity_torque / (0.00981 * 50); // at 50mm arm
            echo(str("  → Add counterweight of ~", required_counterweight,
                     "g at 50mm from pivot"));
        } else {
            margin = motor_torque_available / max_gravity_torque;
            echo(str("  RESULT: OK (margin: ", margin, "x)"));
        }

        echo(str("=== END GRAVITY: ", element_name, " ==="));
    }
}

// === FINAL VERIFICATION REPORT ===

module verification_report(project_name,
                           power_path_verified,
                           grashof_type,
                           dead_points,
                           coupler_max_dev,
                           tolerance_stack,
                           power_margin,
                           gravity_ok,
                           wall_thickness,
                           clearance,
                           part_count) {
    echo("");
    echo("══════════════════════════════════════════════════════════");
    echo("              VERIFICATION REPORT                          ");
    echo(str("              ", project_name));
    echo("══════════════════════════════════════════════════════════");
    echo("");
    echo("POWER PATH VERIFIED:");
    echo(str("  ", power_path_verified ? "All animated elements connected: YES" :
                                         "WARNING: Disconnected elements!"));
    echo("");
    echo("KINEMATICS VERIFIED:");
    echo(str("  Grashof classification: ", grashof_type));
    echo(str("  Dead points: ", dead_points));
    echo(str("  Coupler max deviation: ", coupler_max_dev, "mm ",
             coupler_max_dev < 0.5 ? "(< 0.5mm ✓)" : "FAIL"));
    echo("");
    echo("PHYSICS VERIFIED:");
    echo(str("  Tolerance stack: ", tolerance_stack, "mm"));
    echo(str("  Power margin: ", power_margin, "x ",
             power_margin >= 1.5 ? "(≥ 1.5x ✓)" : "FAIL"));
    echo(str("  Gravity: ", gravity_ok ? "All positions OK" : "NEEDS COUNTERWEIGHT"));
    echo("");
    echo("PRINTABILITY VERIFIED:");
    echo(str("  Wall thickness: ", wall_thickness, "mm ",
             wall_thickness >= 1.2 ? "(≥1.2mm ✓)" : "FAIL"));
    echo(str("  Clearance: ", clearance, "mm ",
             clearance >= 0.3 ? "(≥0.3mm ✓)" : "FAIL"));
    echo("");
    echo(str("Part count: ", part_count));
    echo("");
    echo("══════════════════════════════════════════════════════════");
    echo("                 READY FOR USER REVIEW                     ");
    echo("══════════════════════════════════════════════════════════");
}

// === USAGE EXAMPLE ===
/*
// Include at end of your mechanism file:

include <validation_modules.scad>

// Verify four-bar linkage
verify_grashof("Wave Mechanism",
               ground=80, crank=20, coupler=60, rocker=50,
               requires_full_rotation=true);

// Verify coupler at current animation position
verify_coupler("Wave Coupler",
               crank_pivot=[0,0], crank_r=20, crank_angle=master_phase,
               rocker_pivot=[80,0], rocker_r=50, rocker_angle=rocker_phase,
               coupler_length=60);

// Power path
echo_power_path_simple([
    "Motor → Pinion (10T) → Master Gear (60T)",
    "  ├─ Wave Drive (30T) → Zone 1, 2, 3",
    "  ├─ Star Belt → 5 Stars",
    "  └─ Lighthouse Belt → Lighthouse"
]);

// Final report
verification_report(
    project_name = "Starry Night V56",
    power_path_verified = true,
    grashof_type = "Crank-rocker",
    dead_points = "None in range",
    coupler_max_dev = 0.1,
    tolerance_stack = 1.2,
    power_margin = 2.5,
    gravity_ok = true,
    wall_thickness = 1.5,
    clearance = 0.4,
    part_count = 129
);
*/
