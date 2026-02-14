// ═══════════════════════════════════════════════════════════════════════════
//                    SINGLE WAVE MECHANISM v1
//                    One crank, one wave, actually connected
// ═══════════════════════════════════════════════════════════════════════════
// This file demonstrates a WORKING slider-crank mechanism where:
//   - Every part position derives from the motor shaft
//   - Coupler rod physically connects crank pin to slider
//   - No floating parts, no orphan animations
// ═══════════════════════════════════════════════════════════════════════════

$fn = 32;

// ═══════════════════════════════════════════════════════════════════════════
//                          SINGLE SOURCE OF TRUTH
// ═══════════════════════════════════════════════════════════════════════════
// All positions derive from these values

// Frame dimensions
FRAME_W = 200;
FRAME_H = 100;
FRAME_D = 50;
WALL = 5;

// Motor position (the ONLY fixed reference)
MOTOR_X = FRAME_W / 2;  // 100mm - center of frame
MOTOR_Y = 15;           // 15mm from back panel
MOTOR_Z = 30;           // 30mm up from bottom

// Mechanism parameters (from calculations)
CRANK_R = 15;           // Crank radius (mm)
COUPLER_L = 60;         // Coupler length (mm) - MUST stay constant
PIN_D = 4;              // Pin diameter
ROD_D = 6;              // Coupler rod diameter

// Animation
angle = $t * 360;       // Crank rotation (degrees)

// ═══════════════════════════════════════════════════════════════════════════
//                          DERIVED POSITIONS
// ═══════════════════════════════════════════════════════════════════════════
// These are CALCULATED from motor position + angle, not independently set

// Crank pin position (rotates around motor shaft)
function pin_x(a) = MOTOR_X + CRANK_R * cos(a);
function pin_z(a) = MOTOR_Z + CRANK_R * sin(a);

// CRITICAL GEOMETRY for collision avoidance:
//
// The crank disc rotates in the X-Z plane at Y = MOTOR_Y to Y = MOTOR_Y + thickness
// The pin sticks out in the +Y direction from the disc face
// The coupler rod connects pin tip to slider
//
// To avoid collision: the ENTIRE coupler rod must be at Y > disc_front_face
// This means BOTH the pin tip AND the slider must be at the same Y, in front of disc
//
CRANK_DISC_THICKNESS = 5;
PIN_LENGTH = 12;  // Longer pin to get connection point further from disc

// Pin tip Y position (where coupler connects to crank)
PIN_TIP_Y = MOTOR_Y + CRANK_DISC_THICKNESS + PIN_LENGTH;  // 15 + 5 + 12 = 32mm

// Slider Y position - SAME as pin tip so rod stays in one Y plane, clear of disc
SLIDER_Y = PIN_TIP_Y;  // 32mm - entirely in front of disc (which ends at Y=20)

// Slider position (constrained to move vertically below motor)
function slider_z(a) =
    let(
        pz = pin_z(a),
        horiz = CRANK_R * cos(a),
        vert_from_pin = sqrt(COUPLER_L * COUPLER_L - horiz * horiz)
    )
    pz + vert_from_pin;

// ═══════════════════════════════════════════════════════════════════════════
//                          COLORS
// ═══════════════════════════════════════════════════════════════════════════
C_FRAME = [0.3, 0.3, 0.35];
C_MOTOR = [0.2, 0.2, 0.2];
C_CRANK = [0.8, 0.4, 0.1];
C_ROD = [0.6, 0.6, 0.65];
C_SLIDER = [0.2, 0.5, 0.8];
C_WAVE = [0.1, 0.4, 0.7];

// ═══════════════════════════════════════════════════════════════════════════
//                          FRAME MODULE
// ═══════════════════════════════════════════════════════════════════════════
module frame() {
    color(C_FRAME)
    difference() {
        // Outer shell
        cube([FRAME_W, FRAME_D, FRAME_H]);

        // Hollow interior
        translate([WALL, WALL, WALL])
            cube([FRAME_W - 2*WALL, FRAME_D - 2*WALL, FRAME_H]);

        // Motor hole in back panel
        translate([MOTOR_X, -1, MOTOR_Z])
            rotate([-90, 0, 0])
            cylinder(d = 14, h = WALL + 2);

        // Slider rail slot (vertical slot for slider to move in)
        translate([MOTOR_X - 6, 20, 60])
            cube([12, 20, 50]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                          MOTOR MODULE
// ═══════════════════════════════════════════════════════════════════════════
module motor() {
    color(C_MOTOR)
    translate([MOTOR_X, MOTOR_Y, MOTOR_Z])
    rotate([90, 0, 0]) {
        // Motor body
        translate([0, 0, -25])
            cylinder(d = 12, h = 25);

        // Motor mount plate
        translate([-15, -10, -26])
            cube([30, 20, 2]);

        // Shaft (extends forward)
        cylinder(d = 4, h = 15);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                          CRANK DISC MODULE
// ═══════════════════════════════════════════════════════════════════════════
module crank_disc(a) {
    color(C_CRANK)
    translate([MOTOR_X, MOTOR_Y, MOTOR_Z])
    rotate([-90, 0, 0])
    rotate([0, 0, a]) {
        // Disc rotates in X-Z plane, faces +Y direction
        // Disc spans Y = MOTOR_Y (15) to Y = MOTOR_Y + thickness (20)
        cylinder(d = CRANK_R * 2 + 10, h = CRANK_DISC_THICKNESS);

        // Hub
        cylinder(d = 10, h = CRANK_DISC_THICKNESS + 2);

        // Pin at crank radius - extends from disc face toward +Y
        // Pin spans Y = 20 to Y = 20 + PIN_LENGTH (32)
        // Coupler connects at pin tip (Y = 32), well clear of disc
        translate([CRANK_R, 0, CRANK_DISC_THICKNESS])
            cylinder(d = PIN_D, h = PIN_LENGTH);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                          COUPLER ROD MODULE
// ═══════════════════════════════════════════════════════════════════════════
// This is the KEY module - it PHYSICALLY connects the pin to the slider
module coupler_rod(a) {
    // Calculate positions
    px = pin_x(a);
    pz = pin_z(a);
    sz = slider_z(a);

    color(C_ROD)
    hull() {
        // Ball joint at crank pin
        translate([px, PIN_TIP_Y, pz])
            sphere(d = ROD_D);

        // Ball joint at slider
        translate([MOTOR_X, PIN_TIP_Y, sz])
            sphere(d = ROD_D);
    }

    // Debug: verify coupler length
    coupler_actual = sqrt(pow(px - MOTOR_X, 2) + pow(sz - pz, 2));
    echo(str("Angle: ", a, "° | Coupler length: ", coupler_actual, "mm (should be ", COUPLER_L, ")"));
}

// ═══════════════════════════════════════════════════════════════════════════
//                          SLIDER MODULE
// ═══════════════════════════════════════════════════════════════════════════
module slider(a) {
    sz = slider_z(a);

    color(C_SLIDER)
    translate([MOTOR_X, SLIDER_Y, sz]) {
        // Connection point at SLIDER_Y (same as PIN_TIP_Y = 32mm)
        // This keeps the entire coupler rod at Y=32, clear of disc at Y=20
        sphere(d = 8);

        // Slider block - extends backward from connection point
        translate([-20, -12, -5])
            cube([40, 12, 10]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                          WAVE PIECE MODULE
// ═══════════════════════════════════════════════════════════════════════════
module wave_piece(a) {
    sz = slider_z(a);

    color(C_WAVE)
    translate([MOTOR_X, SLIDER_Y + 3, sz]) {
        // Wave shape - attached to front of slider
        scale([1, 0.3, 1])
        rotate([90, 0, 0])
        difference() {
            cylinder(d = 60, h = 5, center = true);
            cylinder(d = 50, h = 6, center = true);
            translate([-40, -40, -5])
                cube([80, 40, 10]);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                          RAIL GUIDES MODULE
// ═══════════════════════════════════════════════════════════════════════════
module rail_guides() {
    color(C_FRAME)
    for (dx = [-25, 25]) {
        // Rails at SLIDER_Y to guide vertical motion
        translate([MOTOR_X + dx, SLIDER_Y - 8, 65])
            cube([5, 8, 50]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                          MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════
// Everything is connected through the angle parameter

frame();
motor();
crank_disc(angle);
coupler_rod(angle);
slider(angle);
wave_piece(angle);
rail_guides();

// ═══════════════════════════════════════════════════════════════════════════
//                          DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════");
echo("SINGLE WAVE MECHANISM v1 - Geometry Verification");
echo("═══════════════════════════════════════════════════════════════════");
echo(str("Disc Y range: ", MOTOR_Y, " to ", MOTOR_Y + CRANK_DISC_THICKNESS, " (ends at Y=20)"));
echo(str("Pin tip Y: ", PIN_TIP_Y, " (coupler connects here)"));
echo(str("Slider Y: ", SLIDER_Y, " (same as pin tip)"));
echo(str("Clearance: ", PIN_TIP_Y - (MOTOR_Y + CRANK_DISC_THICKNESS), "mm between disc and coupler"));
echo("───────────────────────────────────────────────────────────────────");
echo(str("Current angle: ", angle, "°"));
echo(str("Pin XZ: (", pin_x(angle), ", ", pin_z(angle), ")"));
echo(str("Slider Z: ", slider_z(angle)));
echo("═══════════════════════════════════════════════════════════════════");
