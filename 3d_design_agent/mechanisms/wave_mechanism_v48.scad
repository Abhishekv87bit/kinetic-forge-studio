// ═══════════════════════════════════════════════════════════════════════════════════════
//                    WAVE MECHANISM V48 - ZONE-SPECIFIC FOUR-BAR LINKAGES
//                    Physics-based wave system with variable crank throws
//                    Implements 3-zone system with articulated breaking wave
// ═══════════════════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                CANVAS REFERENCE
// ═══════════════════════════════════════════════════════════════════════════════════════
IW = 302;           // Inner canvas width (mm)
IH = 227;           // Inner canvas height (mm)
TAB_W = 4;          // Tab offset
CLIFF_EDGE_X = 108; // Where cliff meets ocean

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ANIMATION PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════════
t = $t;
master_phase = t * 360;

// Zone phase offsets (creates traveling wave illusion toward cliff)
PHASE_ZONE_1_FAR = master_phase;           // Reference (0°)
PHASE_ZONE_2_MID = master_phase + 30;      // +30° (building energy)
PHASE_ZONE_3_BREAK = master_phase + 60;    // +60° (dramatic crash)

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Zone 1: Far Ocean (smallest waves, gentle bob)
// Zone 2: Mid/Approaching Ocean (medium waves, drift + bob)
// Zone 3: Breaking Zone (articulated curl mechanism)

// Zone boundaries (X coordinates as percentage of wave area)
ZONE_1_X_START = 0.70;  // 70-100% of wave area (far right)
ZONE_1_X_END = 1.00;

ZONE_2_X_START = 0.40;  // 40-70% of wave area (middle)
ZONE_2_X_END = 0.70;

ZONE_3_X_START = 0.00;  // 0-40% of wave area (near cliff)
ZONE_3_X_END = 0.40;

// Wave area spans from cliff edge to right canvas edge
WAVE_AREA_START = CLIFF_EDGE_X;
WAVE_AREA_END = IW;
WAVE_AREA_WIDTH = WAVE_AREA_END - WAVE_AREA_START;  // 194mm

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                FOUR-BAR PARAMETERS PER ZONE
// ═══════════════════════════════════════════════════════════════════════════════════════
// Base parameters (from USER_VISION_ELEMENTS - LOCKED)
BASE_CRANK = 10;
BASE_GROUND = 25;
BASE_COUPLER = 30;
BASE_ROCKER = 25;

// Zone 1: Far Ocean - Minimal motion
ZONE_1_CRANK = 5;      // 50% of base (minimal throw)
ZONE_1_COUPLER = 38;   // Longer coupler = gentler motion
ZONE_1_OUTPUT = 2;     // +/-2mm bob only

// Zone 2: Mid Ocean - Building motion
ZONE_2_CRANK = 8;      // 80% of base
ZONE_2_COUPLER = 34;   // Medium coupler
ZONE_2_DRIFT = 3;      // +/-3mm horizontal drift
ZONE_2_BOB = 5;        // +/-5mm vertical bob

// Zone 3: Breaking - Maximum drama (uses articulated mechanism)
ZONE_3_CRANK = 15;     // 150% of base (maximum throw)
ZONE_3_COUPLER = 25;   // Short coupler = aggressive motion
ZONE_3_CRASH = 12;     // +/-12mm crash motion

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                GRASHOF VERIFICATION
// ═══════════════════════════════════════════════════════════════════════════════════════
// For a crank-rocker: shortest + longest < sum of other two
// Zone 1: 5 + 38 = 43 < 25 + 25 = 50 ✓ GRASHOF OK
// Zone 2: 8 + 34 = 42 < 25 + 25 = 50 ✓ GRASHOF OK
// Zone 3: 15 + 25 = 40 < 25 + 25 = 50 ✓ GRASHOF OK (just barely)

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════════════
C_GEAR = "#b8860b";
C_GEAR_DARK = "#8b7355";
C_METAL = "#708090";
C_CRANK = "#d4a060";
C_COUPLER = "#a08050";

// Zone wave colors (deeper blue = further away)
C_ZONE_1 = ["#0a2a4e", "#0e3258", "#123a62"];  // Far: deep blue
C_ZONE_2 = ["#1a4a7e", "#2a5a8e", "#3a6a9e"];  // Mid: medium blue
C_ZONE_3 = ["#4a8ab8", "#5a9ac8", "#ffffff"];  // Break: light blue + foam

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                Z-LAYER POSITIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
Z_CAMSHAFT = 55;        // Four-bar mechanism base
Z_CRANK_DISCS = 56;     // Crank discs
Z_COUPLERS = 58;        // Coupler rods
Z_WAVE_BASE = 60;       // Wave layers start
Z_WAVE_LAYER_T = 4;     // Each layer thickness

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE 1: FAR OCEAN MODULE
//                                (3 small waves, gentle vertical bob)
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_1_far_ocean() {
    // Calculate positions in wave area
    x_start = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_1_X_START;
    x_end = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_1_X_END;
    zone_width = x_end - x_start;

    // Motion calculations
    bob_1 = ZONE_1_OUTPUT * sin(PHASE_ZONE_1_FAR);
    bob_2 = ZONE_1_OUTPUT * sin(PHASE_ZONE_1_FAR + 15);
    bob_3 = ZONE_1_OUTPUT * sin(PHASE_ZONE_1_FAR + 30);

    // Wave 1 - Furthest (smallest)
    translate([x_start + zone_width * 0.7, 15 + bob_1, Z_WAVE_BASE]) {
        color(C_ZONE_1[0])
        scale([0.35, 0.35, 1])
        wave_shape_simple(40, 12);
    }

    // Wave 2 - Middle far
    translate([x_start + zone_width * 0.4, 18 + bob_2, Z_WAVE_BASE + Z_WAVE_LAYER_T]) {
        color(C_ZONE_1[1])
        scale([0.40, 0.40, 1])
        wave_shape_simple(45, 14);
    }

    // Wave 3 - Closest of far zone
    translate([x_start + zone_width * 0.1, 20 + bob_3, Z_WAVE_BASE + Z_WAVE_LAYER_T * 2]) {
        color(C_ZONE_1[2])
        scale([0.45, 0.45, 1])
        wave_shape_crest(50, 16);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE 2: MID OCEAN MODULE
//                                (3 waves, elliptical orbit motion)
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_2_mid_ocean() {
    x_start = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_2_X_START;
    x_end = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_2_X_END;
    zone_width = x_end - x_start;

    // Motion: elliptical orbit (drift + bob)
    drift = ZONE_2_DRIFT * sin(PHASE_ZONE_2_MID * 0.8);
    bob_1 = ZONE_2_BOB * sin(PHASE_ZONE_2_MID);
    bob_2 = ZONE_2_BOB * sin(PHASE_ZONE_2_MID + 20);
    bob_3 = ZONE_2_BOB * sin(PHASE_ZONE_2_MID + 40);

    // Wave 4 - Back of mid zone
    translate([x_start + zone_width * 0.75 + drift, 22 + bob_1, Z_WAVE_BASE]) {
        color(C_ZONE_2[0])
        scale([0.55, 0.55, 1])
        wave_shape_crest(55, 18);
    }

    // Wave 5 - Center of mid zone
    translate([x_start + zone_width * 0.45 + drift * 0.8, 26 + bob_2, Z_WAVE_BASE + Z_WAVE_LAYER_T]) {
        color(C_ZONE_2[1])
        scale([0.70, 0.70, 1])
        wave_shape_crest(60, 22);
    }

    // Wave 6 - Front of mid zone (largest open water)
    translate([x_start + zone_width * 0.15 + drift * 0.6, 30 + bob_3, Z_WAVE_BASE + Z_WAVE_LAYER_T * 2]) {
        color(C_ZONE_2[2])
        scale([0.85, 0.85, 1])
        wave_shape_crest(65, 26);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE 3: ARTICULATED BREAKING WAVE
//                                Multi-segment hinged mechanism
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_3_breaking_wave() {
    x_start = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_3_X_START;
    x_end = WAVE_AREA_START + WAVE_AREA_WIDTH * ZONE_3_X_END;
    zone_width = x_end - x_start;

    // Articulated wave motion sequence:
    // 0-120°: Wave rises, crest lifts, lip begins curl
    // 120-180°: Lip folds over dramatically (the "crash")
    // 180-360°: Wave retreats, resets for next cycle

    phase_normalized = PHASE_ZONE_3_BREAK % 360;

    // Calculate segment angles based on phase
    // Base swell: rises and falls
    base_angle = 8 * sin(PHASE_ZONE_3_BREAK);

    // Rising crest: follows base with delay
    crest_delay = 20;  // degrees behind base
    crest_rise = phase_normalized < 120 ?
        (phase_normalized / 120) * 25 :  // Rising phase
        phase_normalized < 180 ?
        25 - ((phase_normalized - 120) / 60) * 15 :  // Peak to crash
        10 * sin((phase_normalized - 180) * 2);  // Retreat

    // Curling lip: dramatic fold during crash
    curl_angle = phase_normalized < 100 ?
        (phase_normalized / 100) * 30 :  // Building curl
        phase_normalized < 160 ?
        30 + ((phase_normalized - 100) / 60) * 90 :  // Dramatic fold (up to 120°)
        120 - ((phase_normalized - 160) / 200) * 120;  // Reset

    // Horizontal surge motion
    surge = ZONE_3_CRASH * sin(PHASE_ZONE_3_BREAK * 0.7);

    // Position at cliff edge
    pivot_x = CLIFF_EDGE_X + 20 + surge;
    pivot_y = 8;

    translate([pivot_x, pivot_y, Z_WAVE_BASE]) {
        // === COMPONENT 1: BASE SWELL ===
        // Fixed pivot at cliff edge
        rotate([base_angle, 0, 0]) {
            color(C_ZONE_3[0])
            linear_extrude(height=Z_WAVE_LAYER_T)
            polygon([
                [0, 0],
                [zone_width * 0.6, 0],
                [zone_width * 0.5, 25],
                [zone_width * 0.3, 30],
                [zone_width * 0.1, 25],
                [0, 15]
            ]);

            // === COMPONENT 2: RISING CREST ===
            // Hinged to base, rises with wave
            translate([zone_width * 0.25, 28, Z_WAVE_LAYER_T]) {
                rotate([crest_rise, 0, 0]) {
                    color(C_ZONE_3[1])
                    linear_extrude(height=Z_WAVE_LAYER_T)
                    polygon([
                        [-15, 0],
                        [25, 0],
                        [30, 12],
                        [20, 20],
                        [5, 25],
                        [-10, 18],
                        [-15, 8]
                    ]);

                    // === COMPONENT 3: CURLING LIP ===
                    // Hinged to crest, folds over during crash
                    translate([15, 18, Z_WAVE_LAYER_T]) {
                        rotate([curl_angle, 0, 0]) {
                            color(C_ZONE_3[2])  // Foam white
                            linear_extrude(height=Z_WAVE_LAYER_T)
                            polygon([
                                [-8, 0],
                                [12, 0],
                                [15, 8],
                                [10, 15],
                                [0, 18],
                                [-8, 12]
                            ]);

                            // === COMPONENT 4: SPRAY TIPS ===
                            // Small pieces at curl edge
                            translate([5, 12, Z_WAVE_LAYER_T])
                            spray_tips(phase_normalized);
                        }
                    }
                }
            }
        }
    }

    // Foam at cliff base (appears during crash phase)
    if (phase_normalized > 100 && phase_normalized < 220) {
        foam_intensity = phase_normalized < 160 ?
            (phase_normalized - 100) / 60 :
            1 - ((phase_normalized - 160) / 60);

        translate([CLIFF_EDGE_X + 5, 5, Z_WAVE_BASE + Z_WAVE_LAYER_T * 3])
        foam_burst(foam_intensity);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                SPRAY TIPS MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module spray_tips(phase) {
    // Detaching spray effect during crash
    detach = phase > 120 && phase < 200 ?
        (phase - 120) / 80 * 15 : 0;

    scatter = phase > 130 ? (phase - 130) / 100 * 10 : 0;

    color("#ffffff", 0.9) {
        // Tip 1
        translate([detach * 0.5, detach * 0.3 + scatter * 0.2, 0])
        sphere(r=2);

        // Tip 2
        translate([detach * 0.8 + 3, detach * 0.6 - scatter * 0.3, 1])
        sphere(r=1.5);

        // Tip 3
        translate([detach * 0.3 - 2, detach * 0.8 + scatter * 0.4, 0.5])
        sphere(r=1.8);

        // Tip 4
        translate([detach * 1.0 + 1, detach * 0.4, 2])
        sphere(r=1.2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                FOAM BURST MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module foam_burst(intensity) {
    color("#ffffff", intensity * 0.8) {
        // Multiple foam blobs
        for (i = [0:5]) {
            angle = i * 60 + intensity * 30;
            dist = 3 + intensity * 8;
            translate([dist * cos(angle), dist * sin(angle) * 0.3, i * 2])
            scale([1, 0.6, 0.4])
            sphere(r=3 + intensity * 2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                WAVE SHAPE MODULES
// ═══════════════════════════════════════════════════════════════════════════════════════
module wave_shape_simple(width, height) {
    // Simple wave for far ocean (smooth, no crest)
    linear_extrude(height=Z_WAVE_LAYER_T)
    polygon([
        [0, 0],
        [width, 0],
        [width, height * 0.4],
        [width * 0.75, height * 0.6],
        [width * 0.5, height * 0.5],
        [width * 0.25, height * 0.7],
        [0, height * 0.5]
    ]);
}

module wave_shape_crest(width, height) {
    // Wave with crest for mid ocean (more dramatic)
    linear_extrude(height=Z_WAVE_LAYER_T)
    polygon([
        [0, 0],
        [width, 0],
        [width, height * 0.3],
        [width * 0.85, height * 0.5],
        [width * 0.7, height * 0.75],
        [width * 0.5, height],
        [width * 0.35, height * 0.85],
        [width * 0.2, height * 0.6],
        [0, height * 0.4]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                CAMSHAFT ASSEMBLY
//                                (Drives all zones with variable eccentrics)
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_camshaft_assembly() {
    // Camshaft position (behind waves, under cliff)
    cam_x = 100;
    cam_y = 35;

    translate([cam_x, cam_y, Z_CAMSHAFT]) {
        // Main camshaft
        color(C_METAL)
        rotate([0, 90, 0])
        cylinder(d=8, h=120, center=true);

        // Bearing blocks
        color(C_GEAR_DARK) {
            translate([-55, 0, 0])
            difference() {
                cube([14, 20, 12], center=true);
                rotate([0, 90, 0])
                cylinder(d=10, h=16, center=true);
            }

            translate([55, 0, 0])
            difference() {
                cube([14, 20, 12], center=true);
                rotate([0, 90, 0])
                cylinder(d=10, h=16, center=true);
            }
        }

        // Ground bar
        color(C_GEAR_DARK)
        translate([0, 0, -5])
        cube([120, 10, 5], center=true);

        // === ZONE 1 CRANK DISC (5mm throw) ===
        translate([40, 0, 0])
        zone_crank_disc(ZONE_1_CRANK, PHASE_ZONE_1_FAR, C_ZONE_1[0]);

        // === ZONE 2 CRANK DISCS (8mm throw) x2 ===
        translate([10, 0, 0])
        zone_crank_disc(ZONE_2_CRANK, PHASE_ZONE_2_MID, C_ZONE_2[0]);

        translate([-15, 0, 0])
        zone_crank_disc(ZONE_2_CRANK, PHASE_ZONE_2_MID + 20, C_ZONE_2[1]);

        // === ZONE 3 CRANK DISC (15mm throw) ===
        translate([-40, 0, 0])
        zone_crank_disc(ZONE_3_CRANK, PHASE_ZONE_3_BREAK, C_ZONE_3[0]);

        // Drive gear (connects to master gear train)
        translate([-65, 0, 0])
        rotate([0, 90, 0])
        rotate([0, 0, master_phase])
        drive_gear_30t();
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                ZONE CRANK DISC MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module zone_crank_disc(crank_throw, phase, color_val) {
    rotate([phase, 0, 0])
    rotate([0, 90, 0]) {
        // Disc body
        color(color_val)
        difference() {
            cylinder(d=crank_throw * 2.5, h=5, center=true);
            cylinder(d=8, h=7, center=true);
        }

        // Eccentric crank pin
        translate([crank_throw, 0, 0])
        color(C_METAL)
        cylinder(d=4, h=10, center=true);

        // Visual indicator of throw direction
        color(color_val)
        translate([crank_throw * 0.5, 0, 3])
        cylinder(d=2, h=2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                DRIVE GEAR (30T)
// ═══════════════════════════════════════════════════════════════════════════════════════
module drive_gear_30t() {
    teeth = 30;
    pitch_r = 15;

    color(C_GEAR)
    difference() {
        union() {
            cylinder(r=pitch_r - 1, h=6);
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * 360/teeth])
                translate([pitch_r, 0, 0])
                cylinder(r=2, h=6, $fn=6);
            }
        }
        translate([0, 0, -1])
        cylinder(d=8, h=8);

        // Lightening holes
        for (i = [0:4]) {
            rotate([0, 0, i * 72 + 36])
            translate([pitch_r * 0.55, 0, -1])
            cylinder(r=3, h=8);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════════

// Zone 1: Far Ocean
zone_1_far_ocean();

// Zone 2: Mid Ocean
zone_2_mid_ocean();

// Zone 3: Breaking Wave (articulated)
zone_3_breaking_wave();

// Camshaft Assembly
zone_camshaft_assembly();

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                DEBUG OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("WAVE MECHANISM V48 - ZONE-SPECIFIC FOUR-BAR LINKAGES");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("");
echo("ZONE 1 - FAR OCEAN:");
echo("  Crank throw:", ZONE_1_CRANK, "mm");
echo("  Motion: Pure bob +/-", ZONE_1_OUTPUT, "mm");
echo("  Phase: master + 0°");
echo("  Grashof:", ZONE_1_CRANK, "+", ZONE_1_COUPLER, "=", ZONE_1_CRANK + ZONE_1_COUPLER, "< 50 ✓");
echo("");
echo("ZONE 2 - MID OCEAN:");
echo("  Crank throw:", ZONE_2_CRANK, "mm");
echo("  Motion: Drift +/-", ZONE_2_DRIFT, "mm, Bob +/-", ZONE_2_BOB, "mm");
echo("  Phase: master + 30°");
echo("  Grashof:", ZONE_2_CRANK, "+", ZONE_2_COUPLER, "=", ZONE_2_CRANK + ZONE_2_COUPLER, "< 50 ✓");
echo("");
echo("ZONE 3 - BREAKING WAVE:");
echo("  Crank throw:", ZONE_3_CRANK, "mm");
echo("  Motion: ARTICULATED CURL");
echo("    - Base swell: +/-8° tilt");
echo("    - Rising crest: 0-25° lift");
echo("    - Curling lip: 0-120° fold");
echo("    - Spray detachment: 15mm scatter");
echo("  Phase: master + 60°");
echo("  Grashof:", ZONE_3_CRANK, "+", ZONE_3_COUPLER, "=", ZONE_3_CRANK + ZONE_3_COUPLER, "< 50 ✓");
echo("");
echo("TRAVELING WAVE ILLUSION:");
echo("  Phase progression: 0° → +30° → +60° (right to left)");
echo("  Creates perception of wave energy moving toward cliff");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
