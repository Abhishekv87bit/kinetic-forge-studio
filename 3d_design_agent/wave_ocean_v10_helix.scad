/*
 * WAVE OCEAN V10 - HELICAL CAM WITH GROOVE FOLLOWERS
 *
 * REAL BUILDABLE MECHANISM
 *
 * Concept:
 *   - Single helical cam (worm) with sinusoidal groove
 *   - Multiple slats, each with follower pin riding in groove
 *   - As worm rotates, groove pushes followers up/down
 *   - Phase offset built into helix geometry
 *   - Groove = positive engagement (no springs needed)
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   Wave travels RIGHT to LEFT
 *
 * PRINTABILITY:
 *   - Worm cam: Print as single piece, or split into sections
 *   - Slats: Simple flat pieces with follower pin hole
 *   - Frame: Standard bearing blocks
 */

$fn = 48;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// WORM CAM PARAMETERS
// ============================================

WORM_LENGTH = 200;           // Total length along X axis
WORM_CORE_DIA = 20;          // Central cylinder diameter
WORM_OUTER_DIA = 36;         // Outer diameter at groove peaks

GROOVE_DEPTH = 6;            // Depth of groove (radius difference)
GROOVE_WIDTH = 5;            // Width of groove channel
GROOVE_AMPLITUDE = 8;        // Sinusoidal amplitude of groove center

// Helix parameters
HELIX_PITCH = 25;            // mm per full rotation (wavelength)
NUM_WAVES = WORM_LENGTH / HELIX_PITCH;  // ~8 wave cycles

// ============================================
// SLAT PARAMETERS
// ============================================

NUM_SLATS = 24;
SLAT_SPACING = WORM_LENGTH / NUM_SLATS;  // ~8.3mm

SLAT_WIDTH = 4;              // X dimension (thin)
SLAT_DEPTH = 30;             // Y dimension (into screen)
SLAT_HEIGHT_BASE = 35;       // Base height above worm

// Follower pin
FOLLOWER_DIA = 4;            // Must fit in groove with clearance
FOLLOWER_LENGTH = 12;        // Length of pin

// Guide slot (constrains slat to vertical motion)
GUIDE_SLOT_WIDTH = 6;
GUIDE_SLOT_HEIGHT = 25;      // Vertical travel range

// ============================================
// FRAME PARAMETERS
// ============================================

FRAME_WIDTH = WORM_LENGTH + 30;
FRAME_DEPTH = 60;
FRAME_HEIGHT = 8;

BEARING_BLOCK_SIZE = 25;

// Worm shaft
WORM_SHAFT_DIA = 8;
WORM_SHAFT_Y = 0;            // Centered
WORM_SHAFT_Z = WORM_OUTER_DIA / 2 + 10;  // Above base

// ============================================
// COLORS
// ============================================

C_WORM = [0.75, 0.55, 0.25];  // Bronze
C_GROOVE = [0.6, 0.4, 0.15];  // Darker groove
C_SLAT = [0.2, 0.4, 0.7];     // Ocean blue
C_FOLLOWER = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.3, 0.35];
C_GUIDE = [0.35, 0.35, 0.4];

// Gradient for slats (deep to light, right to left)
function slat_color(i) =
    let(t = i / (NUM_SLATS - 1))
    [0.1 + 0.4 * (1-t), 0.3 + 0.35 * (1-t), 0.5 + 0.4 * (1-t)];

// ============================================
// KINEMATICS
// ============================================

// Groove center position at given X along worm (relative to worm rotation)
// As worm rotates by theta, the groove "travels" along X
function groove_phase_at_x(x) =
    (x / HELIX_PITCH) * 360;  // Phase based on X position

// Groove Z position (sinusoidal profile in the groove)
function groove_z_at_x(x) =
    let(
        local_phase = groove_phase_at_x(x) - theta,  // Subtract worm rotation
        base_radius = (WORM_CORE_DIA + WORM_OUTER_DIA) / 4  // Middle of groove
    )
    WORM_SHAFT_Z + base_radius + GROOVE_AMPLITUDE * sin(local_phase);

// Slat Z position (follows groove)
function slat_z(i) =
    let(
        slat_x = i * SLAT_SPACING - WORM_LENGTH / 2 + SLAT_SPACING / 2,
        gz = groove_z_at_x(slat_x)
    )
    gz + FOLLOWER_DIA / 2;  // Follower center rides in groove

// ============================================
// MODULES: WORM CAM
// ============================================

// Helical groove path (for visualization)
module groove_path() {
    color(C_GROOVE)
    for (x = [-WORM_LENGTH/2 : 2 : WORM_LENGTH/2]) {
        gz = groove_z_at_x(x);
        translate([x, 0, gz])
            sphere(d=GROOVE_WIDTH);
    }
}

// Simplified worm body (cylinder with groove hint)
// Full groove geometry would require complex boolean ops
module worm_cam_simplified() {
    // Core cylinder
    color(C_WORM)
    translate([-WORM_LENGTH/2, WORM_SHAFT_Y, WORM_SHAFT_Z])
    rotate([0, 90, 0])
        cylinder(d=WORM_CORE_DIA, h=WORM_LENGTH);

    // Outer envelope (shows max extent)
    color(C_WORM, 0.3)
    translate([-WORM_LENGTH/2, WORM_SHAFT_Y, WORM_SHAFT_Z])
    rotate([0, 90, 0])
        cylinder(d=WORM_OUTER_DIA, h=WORM_LENGTH);

    // Groove path visualization
    groove_path();
}

// More detailed worm with actual helical ridges
module worm_cam_detailed() {
    // Core shaft
    color(C_WORM)
    translate([-WORM_LENGTH/2 - 15, WORM_SHAFT_Y, WORM_SHAFT_Z])
    rotate([0, 90, 0])
        cylinder(d=WORM_SHAFT_DIA, h=WORM_LENGTH + 30);

    // Helical thread (simplified as series of angled discs)
    color(C_WORM)
    for (x = [-WORM_LENGTH/2 : 3 : WORM_LENGTH/2]) {
        local_theta = theta + groove_phase_at_x(x);

        translate([x, WORM_SHAFT_Y, WORM_SHAFT_Z])
        rotate([0, 90, 0])
        rotate([0, 0, local_theta])
        // Cam profile at this slice
        difference() {
            // Outer lobe
            hull() {
                cylinder(d=WORM_CORE_DIA, h=2, center=true);
                translate([GROOVE_AMPLITUDE, 0, 0])
                    cylinder(d=WORM_CORE_DIA * 0.6, h=2, center=true);
            }
            // Groove channel
            translate([GROOVE_AMPLITUDE, 0, 0])
                cylinder(d=GROOVE_WIDTH + 1, h=3, center=true);
        }
    }
}

// ============================================
// MODULES: SLAT WITH FOLLOWER
// ============================================

module slat_with_follower(i) {
    slat_x = i * SLAT_SPACING - WORM_LENGTH / 2 + SLAT_SPACING / 2;
    sz = slat_z(i);

    // Slat body (vertical piece)
    color(slat_color(i))
    translate([slat_x - SLAT_WIDTH/2, -SLAT_DEPTH/2, sz])
        cube([SLAT_WIDTH, SLAT_DEPTH, SLAT_HEIGHT_BASE]);

    // Rounded top
    color(slat_color(i))
    translate([slat_x, 0, sz + SLAT_HEIGHT_BASE])
    rotate([90, 0, 0])
        cylinder(d=SLAT_WIDTH, h=SLAT_DEPTH, center=true);

    // Follower pin (rides in groove)
    color(C_FOLLOWER)
    translate([slat_x, WORM_SHAFT_Y, sz - SLAT_WIDTH])
    rotate([90, 0, 0])
        cylinder(d=FOLLOWER_DIA, h=FOLLOWER_LENGTH, center=true);

    // Follower block (connects pin to slat)
    color(C_FOLLOWER)
    translate([slat_x - SLAT_WIDTH/2 - 1, -FOLLOWER_LENGTH/2, sz - SLAT_WIDTH - 3])
        cube([SLAT_WIDTH + 2, FOLLOWER_LENGTH, SLAT_WIDTH + 3]);
}

// ============================================
// MODULES: FRAME AND GUIDES
// ============================================

module frame_base() {
    color(C_FRAME)
    translate([-FRAME_WIDTH/2, -FRAME_DEPTH/2, 0])
        cube([FRAME_WIDTH, FRAME_DEPTH, FRAME_HEIGHT]);
}

module bearing_blocks() {
    // Left bearing
    color(C_FRAME)
    translate([-WORM_LENGTH/2 - BEARING_BLOCK_SIZE/2, -BEARING_BLOCK_SIZE/2, FRAME_HEIGHT])
    difference() {
        cube([BEARING_BLOCK_SIZE, BEARING_BLOCK_SIZE, WORM_SHAFT_Z]);
        translate([BEARING_BLOCK_SIZE/2, BEARING_BLOCK_SIZE/2, WORM_SHAFT_Z])
        rotate([0, 90, 0])
            cylinder(d=WORM_SHAFT_DIA + 1, h=BEARING_BLOCK_SIZE + 2, center=true);
    }

    // Right bearing
    color(C_FRAME)
    translate([WORM_LENGTH/2 - BEARING_BLOCK_SIZE/2, -BEARING_BLOCK_SIZE/2, FRAME_HEIGHT])
    difference() {
        cube([BEARING_BLOCK_SIZE, BEARING_BLOCK_SIZE, WORM_SHAFT_Z]);
        translate([BEARING_BLOCK_SIZE/2, BEARING_BLOCK_SIZE/2, WORM_SHAFT_Z])
        rotate([0, 90, 0])
            cylinder(d=WORM_SHAFT_DIA + 1, h=BEARING_BLOCK_SIZE + 2, center=true);
    }
}

// Guide rail with slots for all slats
module guide_rail() {
    rail_z = WORM_SHAFT_Z + WORM_OUTER_DIA/2 + 5;

    color(C_GUIDE)
    translate([-WORM_LENGTH/2, -SLAT_DEPTH/2 - 5, rail_z])
    difference() {
        cube([WORM_LENGTH, 5, GUIDE_SLOT_HEIGHT + 10]);

        // Slots for each slat
        for (i = [0:NUM_SLATS-1]) {
            slot_x = i * SLAT_SPACING + SLAT_SPACING/2 - GUIDE_SLOT_WIDTH/2;
            translate([slot_x, -1, 5])
                cube([GUIDE_SLOT_WIDTH, 7, GUIDE_SLOT_HEIGHT]);
        }
    }

    // Back guide rail
    color(C_GUIDE)
    translate([-WORM_LENGTH/2, SLAT_DEPTH/2, rail_z])
    difference() {
        cube([WORM_LENGTH, 5, GUIDE_SLOT_HEIGHT + 10]);

        for (i = [0:NUM_SLATS-1]) {
            slot_x = i * SLAT_SPACING + SLAT_SPACING/2 - GUIDE_SLOT_WIDTH/2;
            translate([slot_x, -1, 5])
                cube([GUIDE_SLOT_WIDTH, 7, GUIDE_SLOT_HEIGHT]);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_helix() {
    frame_base();
    bearing_blocks();
    guide_rail();

    // Choose worm visualization:
    worm_cam_simplified();
    // worm_cam_detailed();  // More detailed but slower

    // All slats
    for (i = [0:NUM_SLATS-1]) {
        slat_with_follower(i);
    }
}

// Render
wave_ocean_v10_helix();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("=== WAVE OCEAN V10 - HELICAL CAM (BUILDABLE) ===");
echo("");
echo("WORM CAM:");
echo(str("  Length: ", WORM_LENGTH, "mm"));
echo(str("  Core diameter: ", WORM_CORE_DIA, "mm"));
echo(str("  Outer diameter: ", WORM_OUTER_DIA, "mm"));
echo(str("  Groove depth: ", GROOVE_DEPTH, "mm"));
echo(str("  Groove width: ", GROOVE_WIDTH, "mm"));
echo(str("  Helix pitch: ", HELIX_PITCH, "mm (one wave cycle)"));
echo(str("  Visible waves: ", NUM_WAVES));
echo("");
echo("SLATS:");
echo(str("  Count: ", NUM_SLATS));
echo(str("  Spacing: ", SLAT_SPACING, "mm"));
echo(str("  Follower diameter: ", FOLLOWER_DIA, "mm"));
echo(str("  Clearance in groove: ", GROOVE_WIDTH - FOLLOWER_DIA, "mm"));
echo("");
echo("PRINTABILITY CHECK:");
echo(str("  Groove width > Follower: ", GROOVE_WIDTH, " > ", FOLLOWER_DIA, " = ",
         (GROOVE_WIDTH > FOLLOWER_DIA) ? "PASS" : "FAIL"));
echo(str("  Min wall thickness: ", (WORM_OUTER_DIA - WORM_CORE_DIA)/2 - GROOVE_DEPTH, "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Watch from FRONT (-Y) - wave travels RIGHT to LEFT");

// ============================================
// PHYSICAL BUILD NOTES
// ============================================

/*
 * PARTS LIST:
 *
 * 1. WORM CAM (1x)
 *    - Print in sections if too long for bed
 *    - 8mm shaft hole through center
 *    - Helical groove on surface
 *    - Groove profile: sinusoidal depth variation
 *
 * 2. SLATS (24x)
 *    - Simple flat pieces: 4mm x 30mm x ~35mm
 *    - Follower pin hole at bottom
 *    - Can print many at once
 *
 * 3. FOLLOWER PINS (24x)
 *    - 4mm diameter steel pins or printed
 *    - Press fit into slat holes
 *
 * 4. GUIDE RAILS (2x)
 *    - Front and back rails with slots
 *    - Keeps slats vertical
 *
 * 5. BEARING BLOCKS (2x)
 *    - Support worm shaft at ends
 *    - Use 608 bearings or printed bushings
 *
 * 6. FRAME BASE (1x)
 *    - Flat base plate
 *
 * 7. WORM SHAFT (1x)
 *    - 8mm steel rod
 *    - Extends past bearing for motor coupling
 *
 * ASSEMBLY:
 * 1. Press worm onto shaft
 * 2. Mount shaft in bearings
 * 3. Attach guide rails to frame
 * 4. Insert slats through guide slots
 * 5. Engage follower pins in groove
 * 6. Connect motor to shaft
 *
 * GROOVE MANUFACTURING:
 * Option A: 3D print entire worm (FDM may have rough groove)
 * Option B: Print core, wrap with helical wire/rod for groove walls
 * Option C: CNC or lathe with helical toolpath
 */
