// ═══════════════════════════════════════════════════════════════════════════════════════
//                           RICE TUBE ACOUSTIC MECHANISM
//                     Wave-Synchronized Sound Generator
//                     Creates ocean wave sounds through material cascade
// ═══════════════════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           ACOUSTIC TUNING PARAMETERS
//                     Adjust these to dial in the wave sound
// ═══════════════════════════════════════════════════════════════════════════════════════

// === TUBE DIMENSIONS ===
RICE_TUBE_LENGTH = 125;         // Total tube length (mm)
RICE_TUBE_OD = 24;              // Outer diameter (mm)
RICE_TUBE_WALL = 2;             // Wall thickness (mm)
RICE_TUBE_ID = RICE_TUBE_OD - RICE_TUBE_WALL * 2;  // Inner diameter (20mm)

// === MOTION PARAMETERS ===
// Tilt range controls volume and intensity
RICE_TUBE_TILT_RANGE = 20;      // Degrees (+/-) - increase for louder
RICE_TUBE_TILT_MIN = -20;       // Minimum tilt angle
RICE_TUBE_TILT_MAX = 20;        // Maximum tilt angle

// === INTERNAL BAFFLE SYSTEM ===
// Baffles create the cascade sound - more baffles = longer whoosh
RICE_BAFFLE_COUNT = 8;          // Number of internal baffles
RICE_BAFFLE_ANGLE = 15;         // Baffle spiral angle (degrees) - steeper = faster cascade
RICE_BAFFLE_DEPTH = 5;          // How far baffles extend into tube (mm)
RICE_BAFFLE_THICKNESS = 1.5;    // Baffle material thickness (mm)
RICE_BAFFLE_SPACING = -1;       // Auto-calculate from count (-1 = auto)

// === FILL RECOMMENDATIONS ===
// Different materials create different sound qualities
// Rice: soft, organic whoosh (recommended for wave sound)
// Small beads: sharper, more distinct particles
// Mixed: combination of textures
RICE_FILL_LEVEL = 0.15;         // Fraction of tube volume (0.1-0.2 recommended)
                                 // Less fill = distinct grains
                                 // More fill = continuous whoosh

// === SOUND TIMING ===
// Tube motion syncs to wave phase
// Rice cascades as tube tilts, peaks align with visual wave crest
RICE_PHASE_OFFSET = 0;          // Phase offset from wave (degrees)
                                 // 0 = in sync, +90 = 1/4 cycle ahead

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           DERIVED CALCULATIONS
// ═══════════════════════════════════════════════════════════════════════════════════════

// Auto-calculate baffle spacing if not specified
RICE_BAFFLE_SPACING_CALC = RICE_BAFFLE_SPACING == -1 ?
    RICE_TUBE_LENGTH / (RICE_BAFFLE_COUNT + 1) :
    RICE_BAFFLE_SPACING;

// Internal volume calculation
RICE_TUBE_VOLUME = 3.14159 * pow(RICE_TUBE_ID/2, 2) * RICE_TUBE_LENGTH;  // mm^3
RICE_FILL_VOLUME = RICE_TUBE_VOLUME * RICE_FILL_LEVEL;                    // mm^3

// Cascade time estimate (rough)
// Time for material to cascade full length depends on angle and baffles
// At 20° tilt, roughly 1-2 seconds for full cascade with 8 baffles

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           PHYSICAL MOUNTING
// ═══════════════════════════════════════════════════════════════════════════════════════

// Pivot position (from USER_VISION_ELEMENTS)
RICE_PIVOT_POS = [233, 20];     // X, Y position on canvas

// Z position
Z_RICE_TUBE = 87;               // Z layer for rice tube

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           LINKAGE TO WAVE MECHANISM
// ═══════════════════════════════════════════════════════════════════════════════════════

// Connection to wave camshaft
RICE_LINKAGE_LENGTH = 40;       // Length of linkage arm (mm)
RICE_LINKAGE_ATTACH_Z = 55;     // Z height where linkage attaches (Z_CAMSHAFT)

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           RICE TUBE BODY MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module rice_tube_body(
    length = RICE_TUBE_LENGTH,
    outer_diameter = RICE_TUBE_OD,
    wall_thickness = RICE_TUBE_WALL,
    show_baffles = true
) {
    inner_d = outer_diameter - wall_thickness * 2;

    difference() {
        // Outer tube
        cylinder(d=outer_diameter, h=length);

        // Inner bore
        translate([0, 0, wall_thickness])
        cylinder(d=inner_d, h=length - wall_thickness * 2);
    }

    // Internal baffles
    if (show_baffles) {
        for (i = [1:RICE_BAFFLE_COUNT]) {
            z_pos = i * RICE_BAFFLE_SPACING_CALC;
            angle_offset = i * RICE_BAFFLE_ANGLE;

            translate([0, 0, z_pos])
            rotate([0, 0, angle_offset])
            rice_baffle(inner_d, RICE_BAFFLE_DEPTH, RICE_BAFFLE_THICKNESS);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           BAFFLE MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module rice_baffle(
    tube_id,
    depth,
    thickness
) {
    // Baffle extends partway into tube, creating obstacle for cascade
    // Spiral arrangement creates longer cascade path

    translate([0, -tube_id/2, 0])
    rotate([90, 0, 0])
    linear_extrude(height=thickness)
    polygon([
        [0, 0],
        [tube_id/2 - depth, 0],
        [tube_id/2, depth],
        [0, depth]
    ]);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           END CAP MODULES
// ═══════════════════════════════════════════════════════════════════════════════════════
module rice_tube_end_cap(
    outer_diameter = RICE_TUBE_OD,
    wall_thickness = RICE_TUBE_WALL,
    cap_height = 5,
    has_pivot = false,
    pivot_diameter = 6
) {
    inner_d = outer_diameter - wall_thickness * 2;

    difference() {
        union() {
            // Cap body (slightly larger to fit over tube)
            cylinder(d=outer_diameter + 1, h=cap_height);

            // Lip that fits inside tube
            translate([0, 0, cap_height])
            cylinder(d=inner_d - 0.3, h=3);  // 0.3mm clearance for fit

            // Pivot mount (if needed)
            if (has_pivot) {
                translate([0, 0, -5])
                cylinder(d=pivot_diameter + 4, h=5);
            }
        }

        // Pivot hole
        if (has_pivot) {
            translate([0, 0, -6])
            cylinder(d=pivot_diameter, h=cap_height + 7);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           PIVOT FRAME MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module rice_tube_pivot_frame(
    tube_length = RICE_TUBE_LENGTH,
    pivot_diameter = 6,
    frame_height = 20,
    frame_width = 30,
    frame_thickness = 5
) {
    // Two upright supports with bearings for pivot

    support_spacing = tube_length + 20;  // Space between supports

    for (side = [-1, 1]) {
        translate([0, side * support_spacing/2, 0]) {
            difference() {
                // Support block
                translate([-frame_width/2, -frame_thickness/2, 0])
                cube([frame_width, frame_thickness, frame_height]);

                // Pivot bearing hole
                translate([0, 0, frame_height * 0.7])
                rotate([90, 0, 0])
                cylinder(d=pivot_diameter + 0.5, h=frame_thickness + 2, center=true);
            }
        }
    }

    // Base plate connecting supports
    translate([-frame_width/2, -support_spacing/2 - frame_thickness/2, 0])
    cube([frame_width, support_spacing + frame_thickness, 3]);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           LINKAGE ARM MODULE
// ═══════════════════════════════════════════════════════════════════════════════════════
module rice_tube_linkage(
    arm_length = RICE_LINKAGE_LENGTH,
    arm_width = 8,
    arm_thickness = 3,
    tube_attach_offset = 20,     // Distance from pivot to attachment point
    pivot_hole_dia = 6,
    crank_hole_dia = 4
) {
    difference() {
        // Arm body
        hull() {
            // Tube attachment end (pivot)
            cylinder(d=arm_width, h=arm_thickness);

            // Crank attachment end
            translate([arm_length, 0, 0])
            cylinder(d=arm_width, h=arm_thickness);
        }

        // Tube pivot hole
        translate([0, 0, -0.1])
        cylinder(d=pivot_hole_dia, h=arm_thickness + 0.2);

        // Crank pin hole
        translate([arm_length, 0, -0.1])
        cylinder(d=crank_hole_dia + 0.3, h=arm_thickness + 0.2);  // Clearance fit
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           ANIMATED RICE TUBE ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════════════════
module rice_tube_assembly(
    wave_phase = 0,              // Current wave phase (0-360)
    show_linkage = true,
    show_frame = true
) {
    // Calculate tilt based on wave phase (synced to wave motion)
    effective_phase = wave_phase + RICE_PHASE_OFFSET;
    tilt_angle = RICE_TUBE_TILT_RANGE * sin(effective_phase);

    // Pivot position
    translate([RICE_PIVOT_POS[0], RICE_PIVOT_POS[1], Z_RICE_TUBE]) {

        // Frame (static)
        if (show_frame) {
            color("#8b7355")
            rice_tube_pivot_frame();
        }

        // Tube (animated)
        translate([0, 0, 15])  // Pivot height
        rotate([0, tilt_angle, 0]) {
            // Main tube body (centered on pivot)
            translate([0, 0, -RICE_TUBE_LENGTH/2])
            color("#a0d0f0", 0.7)  // Translucent blue (acrylic look)
            rice_tube_body();

            // End caps
            translate([0, 0, -RICE_TUBE_LENGTH/2 - 5])
            color("#8b7355")
            rice_tube_end_cap(has_pivot=true);

            translate([0, 0, RICE_TUBE_LENGTH/2])
            color("#8b7355")
            rice_tube_end_cap(has_pivot=false);

            // Linkage arm
            if (show_linkage) {
                translate([0, -RICE_TUBE_LENGTH/2 - 10, 0])
                rotate([90, 0, 0])
                color("#d4a060")
                rice_tube_linkage();
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           TUNING GUIDE
// ═══════════════════════════════════════════════════════════════════════════════════════
//
// ADJUSTING WAVE SOUND CHARACTERISTICS:
//
// VOLUME/INTENSITY:
//   - Increase RICE_TUBE_TILT_RANGE for louder cascade
//   - More fill = more material = louder sound
//
// CASCADE DURATION:
//   - More baffles = longer whoosh (increase RICE_BAFFLE_COUNT)
//   - Steeper baffle angle = faster cascade (increase RICE_BAFFLE_ANGLE)
//   - Longer tube = longer sound (increase RICE_TUBE_LENGTH)
//
// SOUND CHARACTER:
//   - Rice = soft, organic whoosh (like ocean waves)
//   - Small beads = sharper, more percussive
//   - Mix rice + beads = complex texture
//   - Less fill = distinct grain sounds
//   - More fill = continuous flowing sound
//
// TIMING:
//   - RICE_PHASE_OFFSET = 0: Sound peaks with visual wave crest
//   - RICE_PHASE_OFFSET = -45: Sound slightly anticipates wave
//   - RICE_PHASE_OFFSET = +45: Sound slightly trails wave
//
// PRINTABILITY:
//   - Print tube standing up (vertical)
//   - Print baffles attached or separately (glue in)
//   - Clear/translucent filament for tube (PETG recommended)
//   - Print end caps flat, press-fit or glue
//
// ═══════════════════════════════════════════════════════════════════════════════════════
//                           DEMO / TEST
// ═══════════════════════════════════════════════════════════════════════════════════════

// Animation variable (0-1)
t = $t;
demo_phase = t * 360;

// Show animated assembly
rice_tube_assembly(wave_phase = demo_phase);

// Debug output
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("RICE TUBE ACOUSTIC MECHANISM");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("");
echo("TUBE DIMENSIONS:");
echo("  Length:", RICE_TUBE_LENGTH, "mm");
echo("  Outer diameter:", RICE_TUBE_OD, "mm");
echo("  Inner diameter:", RICE_TUBE_ID, "mm");
echo("  Internal volume:", RICE_TUBE_VOLUME, "mm^3");
echo("");
echo("ACOUSTIC PARAMETERS:");
echo("  Tilt range: +/-", RICE_TUBE_TILT_RANGE, "degrees");
echo("  Baffle count:", RICE_BAFFLE_COUNT);
echo("  Baffle spacing:", RICE_BAFFLE_SPACING_CALC, "mm");
echo("  Baffle angle:", RICE_BAFFLE_ANGLE, "degrees");
echo("  Fill level:", RICE_FILL_LEVEL * 100, "%");
echo("  Fill volume:", RICE_FILL_VOLUME, "mm^3");
echo("");
echo("TUNING TIPS:");
echo("  - More baffles = longer whoosh");
echo("  - Steeper angle = faster cascade");
echo("  - Rice = soft organic sound");
echo("  - Beads = sharper percussive sound");
echo("");
echo("Animation: View > Animate | FPS=30, Steps=360");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
