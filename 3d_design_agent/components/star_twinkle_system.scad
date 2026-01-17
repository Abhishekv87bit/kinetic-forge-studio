// ═══════════════════════════════════════════════════════════════════════════════════════
//                    STAR TWINKLE SYSTEM - 11 STARS WITH ROTATING HALOS
//                    Counter-rotating gear + halo creates sparkle effect
//                    Varied speeds for organic, magical appearance
// ═══════════════════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════════
t = $t;
master_phase = t * 360;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                STAR POSITIONS & PARAMETERS
//                                (11 stars distributed across sky zone)
// ═══════════════════════════════════════════════════════════════════════════════════════
// Format: [x%, y%, radius, gear_speed_mult, halo_speed_mult, brightness]
// x%, y% are percentages of inner canvas (302mm x 227mm)
// Speed multipliers create varied twinkle rates (0.4x to 0.75x per plan)

STAR_CONFIG = [
    // Upper left quadrant (near cypress)
    [0.12, 0.88, 8, 0.60, 0.45, 1.0],   // Star 1: Large, prominent
    [0.22, 0.82, 6, 0.50, 0.38, 0.9],   // Star 2: Medium

    // Upper center (between swirls)
    [0.32, 0.78, 7, 0.55, 0.42, 0.95],  // Star 3: Medium-large
    [0.42, 0.85, 5, 0.70, 0.52, 0.85],  // Star 4: Small, fast twinkle
    [0.52, 0.80, 6, 0.48, 0.35, 0.9],   // Star 5: Medium, slow

    // Mid sky (wind path area)
    [0.18, 0.70, 6, 0.65, 0.48, 0.88],  // Star 6: Medium
    [0.38, 0.68, 5, 0.72, 0.55, 0.82],  // Star 7: Small, fast

    // Upper right (near moon)
    [0.62, 0.75, 7, 0.45, 0.32, 0.92],  // Star 8: Large, slow (moon companion)
    [0.72, 0.82, 5, 0.75, 0.58, 0.8],   // Star 9: Small, fastest
    [0.58, 0.72, 6, 0.58, 0.43, 0.87],  // Star 10: Medium

    // Accent star (brightest)
    [0.78, 0.65, 9, 0.40, 0.28, 1.0]    // Star 11: Largest, slowest (like Venus)
];

// Inner canvas dimensions (from V47)
IW = 302;
IH = 227;
TAB_W = 4;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
Z_STAR_BASE = 8;        // Behind wind path
Z_STAR_HALO = 6;        // Behind gear
Z_STAR_GEAR = 10;       // Star gear itself

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════════════
C_STAR_BRIGHT = "#fffacd";   // Lemon chiffon (brightest)
C_STAR_MED = "#f0e68c";      // Khaki
C_STAR_DIM = "#daa520";      // Goldenrod
C_STAR_HALO = "#c0a050";     // Dark goldenrod (halo)
C_STAR_GLOW = "#ffff00";     // Yellow (LED glow)

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                STAR GEAR MODULE
//                                (Inner rotating gear with star points)
// ═══════════════════════════════════════════════════════════════════════════════════════
module star_gear(radius, rotation, brightness) {
    // Star color based on brightness
    star_color = brightness > 0.95 ? C_STAR_BRIGHT :
                 brightness > 0.85 ? C_STAR_MED : C_STAR_DIM;

    rotate([0, 0, rotation]) {
        // Central gear body
        color(star_color)
        difference() {
            cylinder(r=radius, h=4);
            translate([0, 0, -1])
            cylinder(r=radius * 0.12, h=6);

            // Decorative holes (5-point pattern)
            for (i = [0:4]) {
                rotate([0, 0, i * 72])
                translate([radius * 0.55, 0, -1])
                cylinder(r=radius * 0.12, h=6);
            }
        }

        // Star points (8 rays)
        color(star_color)
        for (i = [0:7]) {
            rotate([0, 0, i * 45])
            translate([radius * 0.7, 0, 0])
            cylinder(r1=radius * 0.18, r2=radius * 0.08, h=4, $fn=3);
        }

        // Central glow (simulated LED)
        translate([0, 0, 4])
        color(C_STAR_GLOW, brightness * 0.6)
        sphere(r=radius * 0.25);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                COUNTER-ROTATING HALO MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module star_halo(radius, rotation, brightness) {
    halo_outer = radius * 1.5;
    halo_inner = radius * 0.9;

    rotate([0, 0, rotation])
    color(C_STAR_HALO, brightness * 0.7)
    difference() {
        cylinder(r=halo_outer, h=2);
        translate([0, 0, -1])
        cylinder(r=halo_inner, h=4);

        // Decorative cutouts (6-point pattern, offset from star)
        for (i = [0:5]) {
            rotate([0, 0, i * 60 + 30])
            translate([halo_outer * 0.8, 0, -1])
            cylinder(r=radius * 0.2, h=4);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                COMPLETE STAR ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════════
module star_assembly(radius, gear_rotation, halo_rotation, brightness) {
    // Counter-rotating halo (behind)
    translate([0, 0, Z_STAR_HALO])
    star_halo(radius, halo_rotation, brightness);

    // Rotating star gear (front)
    translate([0, 0, Z_STAR_GEAR])
    star_gear(radius, gear_rotation, brightness);

    // Shaft
    color("#708090")
    cylinder(d=radius * 0.25, h=Z_STAR_GEAR + 5);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                FULL 11-STAR SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════
module star_twinkle_system() {
    for (i = [0:len(STAR_CONFIG)-1]) {
        cfg = STAR_CONFIG[i];
        x_pos = cfg[0] * IW;
        y_pos = cfg[1] * IH;
        radius = cfg[2];
        gear_speed = cfg[3];
        halo_speed = cfg[4];
        brightness = cfg[5];

        // Calculate rotations (gear and halo counter-rotate)
        gear_rot = master_phase * gear_speed;
        halo_rot = -master_phase * halo_speed;  // Negative = counter-rotating

        translate([TAB_W + x_pos, TAB_W + y_pos, 0])
        star_assembly(radius, gear_rot, halo_rot, brightness);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                STAR DRIVE GEAR TRAIN
//                                (Connects to sky drive in main assembly)
// ═══════════════════════════════════════════════════════════════════════════════════════
module star_drive_train() {
    // This would connect to the sky drive gear (20T @ 110,30)
    // For visualization, showing drive connection points

    // Drive gear position (behind wind path)
    drive_x = 150;
    drive_y = 180;
    drive_z = Z_STAR_BASE - 3;

    translate([TAB_W + drive_x, TAB_W + drive_y, drive_z]) {
        // Main star drive gear (24T)
        rotate([0, 0, master_phase * 0.5])
        color("#b8860b")
        difference() {
            cylinder(r=12, h=5);
            translate([0, 0, -1])
            cylinder(d=4, h=7);
            for (i = [0:3]) {
                rotate([0, 0, i * 90 + 45])
                translate([8, 0, -1])
                cylinder(r=2, h=7);
            }
        }

        // Shaft to sky area
        color("#708090")
        cylinder(d=4, h=30);
    }

    // Distribution idler gears (would connect to individual star shafts)
    // In practice, belts or additional gear chains would reach each star
    idler_positions = [
        [100, 200],
        [170, 190],
        [220, 185]
    ];

    for (pos = idler_positions) {
        translate([TAB_W + pos[0], TAB_W + pos[1], drive_z]) {
            rotate([0, 0, -master_phase * 0.4])
            color("#8b7355")
            difference() {
                cylinder(r=8, h=4);
                translate([0, 0, -1])
                cylinder(d=3, h=6);
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════════

// All 11 stars
star_twinkle_system();

// Drive train (optional visualization)
// star_drive_train();

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("STAR TWINKLE SYSTEM - 11 STARS WITH COUNTER-ROTATING HALOS");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("");
echo("STAR INVENTORY:");
for (i = [0:len(STAR_CONFIG)-1]) {
    cfg = STAR_CONFIG[i];
    echo(str("  Star ", i+1, ": R=", cfg[2], "mm @ (",
             round(cfg[0]*100), "%, ", round(cfg[1]*100), "%) ",
             "gear=", cfg[3], "x, halo=", cfg[4], "x"));
}
echo("");
echo("TWINKLE EFFECT:");
echo("  - Gear rotates CW at 0.40x to 0.75x master speed");
echo("  - Halo counter-rotates CCW at 0.28x to 0.58x");
echo("  - Speed difference creates sparkling interference");
echo("");
echo("BRIGHTNESS LEVELS:");
echo("  1.0  = Brightest (lemon chiffon)");
echo("  0.85+ = Medium (khaki)");
echo("  <0.85 = Dim (goldenrod)");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
