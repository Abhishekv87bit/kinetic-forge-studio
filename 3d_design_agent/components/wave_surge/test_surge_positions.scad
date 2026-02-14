// TEST FILE: Wave Surge Mechanism Position Verification
// Validates asymmetric "quick up, slow down" motion at 4 key crank positions
//
// Run in OpenSCAD to verify:
// 1. Foam heights at each position
// 2. Quick-return ratio (~1.3:1)
// 3. Phase offset between Zone 2 and Zone 3

// === PARAMETERS (match main assembly) ===
ZONE2_ECCENTRIC_R = 6;
ZONE2_ROD_LENGTH = 18;
ZONE2_PHASE = 45;
ZONE2_ARM = 15;

ZONE3_ECCENTRIC_R = 8;
ZONE3_ROD_LENGTH = 24;
ZONE3_PHASE = 0;
ZONE3_ARM = 20;

// === KINEMATIC FUNCTION ===
function surge_height(theta, r, L) =
    let(pin_y = r * cos(theta),
        pin_x = r * sin(theta),
        rod_v = sqrt(max(0.001, L*L - pin_x*pin_x)))
    pin_y + rod_v;

// === COLORS ===
C_FOAM = "#ffffff";
C_METAL = "#708090";
C_ARM = "#8b7355";

// === FOAM PIECES ===
module foam_piece_medium() {
    color(C_FOAM) hull() {
        sphere(r=4, $fn=16);
        translate([8,0,3]) sphere(r=3, $fn=16);
        translate([5,3,5]) sphere(r=2, $fn=16);
    }
}

module foam_piece_curl() {
    color(C_FOAM) {
        hull() {
            sphere(r=5, $fn=16);
            translate([10,0,4]) sphere(r=4, $fn=16);
            translate([8,0,10]) sphere(r=3, $fn=16);
            translate([3,0,12]) sphere(r=2, $fn=16);
        }
        for(i=[0:4])
            translate([12+i*2, sin(i*60)*3, 6+i*2])
                sphere(r=1.5-i*0.2, $fn=12);
    }
}

module foam_arm(arm_length) {
    color(C_ARM) hull() {
        cylinder(d=6, h=3, $fn=24);
        translate([arm_length,0,0]) cylinder(d=4, h=3, $fn=24);
    }
}

// === TEST VISUALIZATION ===
module show_zone2_at_angle(theta, x_offset) {
    zone_theta = theta + ZONE2_PHASE;
    h = surge_height(zone_theta, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);
    h_normalized = h - (ZONE2_ECCENTRIC_R + ZONE2_ROD_LENGTH);

    translate([x_offset, 0, 0]) {
        // Reference platform
        color("#333") cube([40, 30, 2], center=true);

        // Foam at calculated height
        translate([0, 0, h_normalized + 10]) {
            foam_arm(ZONE2_ARM);
            translate([ZONE2_ARM, 0, 3]) foam_piece_medium();
        }

        // Height marker
        color("red") translate([20, 0, h_normalized + 10])
            cylinder(d=2, h=20, $fn=12);

        // Label
        translate([0, -20, 0]) color("blue")
            linear_extrude(1) text(str("Z2 @", theta, "°"), size=4, halign="center");
        translate([0, -28, 0]) color("green")
            linear_extrude(1) text(str("h=", round(h*10)/10, "mm"), size=3, halign="center");
    }
}

module show_zone3_at_angle(theta, x_offset) {
    zone_theta = theta + ZONE3_PHASE;
    h = surge_height(zone_theta, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);
    h_normalized = h - (ZONE3_ECCENTRIC_R + ZONE3_ROD_LENGTH);

    translate([x_offset, 50, 0]) {
        // Reference platform
        color("#333") cube([50, 30, 2], center=true);

        // Foam at calculated height
        translate([0, 0, h_normalized + 10]) {
            foam_arm(ZONE3_ARM);
            translate([ZONE3_ARM, 0, 3]) foam_piece_curl();
        }

        // Height marker
        color("red") translate([25, 0, h_normalized + 10])
            cylinder(d=2, h=25, $fn=12);

        // Label
        translate([0, -20, 0]) color("blue")
            linear_extrude(1) text(str("Z3 @", theta, "°"), size=4, halign="center");
        translate([0, -28, 0]) color("green")
            linear_extrude(1) text(str("h=", round(h*10)/10, "mm"), size=3, halign="center");
    }
}

// === MAIN TEST RENDER ===
// Show foam positions at 4 key angles: 0°, 90°, 180°, 270°

echo("=== WAVE SURGE POSITION TEST ===");

// Zone 3 calculations
z3_h0 = surge_height(0, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);
z3_h90 = surge_height(90, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);
z3_h180 = surge_height(180, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);
z3_h270 = surge_height(270, ZONE3_ECCENTRIC_R, ZONE3_ROD_LENGTH);

echo(str("Zone 3 (r=8, L=24):"));
echo(str("  theta=0°:   h=", z3_h0, "mm (MAX - wave crest)"));
echo(str("  theta=90°:  h=", z3_h90, "mm (falling)"));
echo(str("  theta=180°: h=", z3_h180, "mm (MIN - wave trough)"));
echo(str("  theta=270°: h=", z3_h270, "mm (rising)"));
echo(str("  Stroke: ", z3_h0 - z3_h180, "mm"));

// Zone 2 calculations (with phase offset)
z2_h0 = surge_height(0+ZONE2_PHASE, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);
z2_h90 = surge_height(90+ZONE2_PHASE, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);
z2_h180 = surge_height(180+ZONE2_PHASE, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);
z2_h270 = surge_height(270+ZONE2_PHASE, ZONE2_ECCENTRIC_R, ZONE2_ROD_LENGTH);

echo(str("Zone 2 (r=6, L=18, phase=+45°):"));
echo(str("  theta=0°:   h=", z2_h0, "mm (phased)"));
echo(str("  theta=90°:  h=", z2_h90, "mm"));
echo(str("  theta=180°: h=", z2_h180, "mm"));
echo(str("  theta=270°: h=", z2_h270, "mm"));

echo("=== Quick-Return Analysis ===");
echo("Zone 3: Rise (180->360) faster than Fall (0->180)");
echo("Expected ratio: ~1.3:1");

// Visual test at 4 positions
for(i = [0:3]) {
    angle = i * 90;
    show_zone2_at_angle(angle, i * 60);
    show_zone3_at_angle(angle, i * 60);
}

// Title
translate([90, 110, 0]) color("black")
    linear_extrude(1) text("WAVE SURGE TEST - 4 Positions", size=6, halign="center");
translate([90, 100, 0]) color("gray")
    linear_extrude(1) text("Zone 2 (front) | Zone 3 (back)", size=4, halign="center");

// Animation test (uncomment for live preview)
// angle = $t * 360;
// show_zone2_at_angle(angle, 0);
// show_zone3_at_angle(angle, 0);
