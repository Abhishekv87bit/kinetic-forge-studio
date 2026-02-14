// MINIMAL TEST - Wave Ocean v8 stripped to basics

echo("Starting minimal test...");

// Simple parameters
SHAFT_DIAMETER = 4;
DISC_DIAMETER = 12;
DISC_THICKNESS = 2;
ECCENTRICITY = 5;

theta = $t * 360;  // Animation angle

// Single disc module
module eccentric_disc() {
    color("blue")
    difference() {
        cylinder(h=DISC_THICKNESS, d=DISC_DIAMETER, center=true, $fn=32);
        translate([ECCENTRICITY, 0, 0])
            cylinder(h=DISC_THICKNESS + 1, d=4.2, center=true, $fn=24);
    }
}

// Mounted disc that rotates around shaft
module mounted_disc(angle) {
    rotate([angle, 0, 0])           // Rotate around X (shaft axis)
        translate([0, 0, -ECCENTRICITY])  // Offset so hole aligns with shaft
            rotate([0, 90, 0])      // Orient disc perpendicular to shaft
                eccentric_disc();
}

// Single shaft with 5 discs
module single_camshaft() {
    // Shaft
    color("gray")
    rotate([0, 90, 0])
        cylinder(d=SHAFT_DIAMETER, h=100, $fn=24);

    // 5 discs along shaft
    for (i = [0:4]) {
        translate([10 + i * 20, 0, 0])
            mounted_disc(theta + i * 20);  // Staggered phase
    }
}

// Render at visible height
translate([0, 0, 20])
    single_camshaft();

// Ground plane for reference
%cube([120, 40, 1], center=true);

echo("Minimal test complete - you should see a shaft with 5 blue discs");
