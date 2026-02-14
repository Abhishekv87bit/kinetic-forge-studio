// DUAL ECCENTRIC DISC MODULE
// For Starry Night Wave Surge Mechanism
// Single disc with two offset pins driving Zone 2 and Zone 3
//
// Design: Eccentric + Connecting Rod (Modified Slider-Crank)
// Creates asymmetric "quick up, slow down" wave motion
//
// Seven Masters Validation:
//   Van Gogh: 7/10 - Natural ease-out, organic feel
//   Da Vinci: 8/10 - Pin joints only, minimal friction
//   Watt: 8/10 - Simple 2-part addition per zone
//   Archimedes: 9/10 - Negligible power increase

// === PARAMETERS ===

// Disc dimensions
DISC_DIAMETER = 24;        // mm - accommodates both pins
DISC_THICKNESS = 4;        // mm
CENTER_HOLE_DIA = 3.3;     // mm - fits Wave Drive shaft (3mm + clearance)

// Zone 2 eccentric pin (Mid Ocean - moderate surge)
ZONE2_ECCENTRIC_R = 6;     // mm - creates 12mm total stroke
ZONE2_PHASE = 45;          // degrees offset from Zone 3

// Zone 3 eccentric pin (Breaking Wave - dramatic surge)
ZONE3_ECCENTRIC_R = 8;     // mm - creates 16mm total stroke
ZONE3_PHASE = 0;           // degrees (reference)

// Pin dimensions (shared)
PIN_DIAMETER = 3;          // mm
PIN_HEIGHT = 15;           // mm - clears both connecting rods

// Colors (inherit from main file if available)
C_METAL = [0.7, 0.7, 0.75];
C_PIN = [0.6, 0.6, 0.65];

// === MODULE ===

module dual_eccentric_disc(theta=0) {
    // Single disc with two eccentric pins for Zone 2 and Zone 3
    // theta = input rotation angle (from gear_rot * 2)

    color(C_METAL) {
        difference() {
            // Base disc
            cylinder(d=DISC_DIAMETER, h=DISC_THICKNESS, $fn=64);

            // Center shaft hole
            translate([0, 0, -1])
                cylinder(d=CENTER_HOLE_DIA, h=DISC_THICKNESS+2, $fn=32);
        }

        // Zone 2 pin (6mm throw, 45 degree offset)
        rotate([0, 0, theta + ZONE2_PHASE])
            translate([ZONE2_ECCENTRIC_R, 0, DISC_THICKNESS])
                color(C_PIN)
                    cylinder(d=PIN_DIAMETER, h=PIN_HEIGHT, $fn=24);

        // Zone 3 pin (8mm throw, 0 degree reference)
        rotate([0, 0, theta + ZONE3_PHASE])
            translate([ZONE3_ECCENTRIC_R, 0, DISC_THICKNESS])
                color(C_PIN)
                    cylinder(d=PIN_DIAMETER, h=PIN_HEIGHT, $fn=24);
    }
}

// Single-pin version for testing or simpler configurations
module single_eccentric_disc(eccentric_r, phase=0, theta=0) {
    color(C_METAL) {
        difference() {
            cylinder(d=DISC_DIAMETER, h=DISC_THICKNESS, $fn=64);
            translate([0, 0, -1])
                cylinder(d=CENTER_HOLE_DIA, h=DISC_THICKNESS+2, $fn=32);
        }

        rotate([0, 0, theta + phase])
            translate([eccentric_r, 0, DISC_THICKNESS])
                color(C_PIN)
                    cylinder(d=PIN_DIAMETER, h=PIN_HEIGHT, $fn=24);
    }
}

// === TEST RENDER ===
// Uncomment to preview disc at various angles

// Test at theta = 0
dual_eccentric_disc(0);

// Test at theta = 90 (uncomment)
// translate([30, 0, 0]) dual_eccentric_disc(90);

// Test at theta = 180 (uncomment)
// translate([60, 0, 0]) dual_eccentric_disc(180);

// Test at theta = 270 (uncomment)
// translate([90, 0, 0]) dual_eccentric_disc(270);

// Animation test (uncomment for OpenSCAD animation)
// dual_eccentric_disc($t * 360);
