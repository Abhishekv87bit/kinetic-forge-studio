/*
 * WAVE OCEAN V10 - APPROACH C: VERTICAL SLATS ARRAY
 *
 * Concept: Many thin vertical slats side-by-side
 *          Each slat bobs up/down on a shared camshaft
 *          Phase offset between adjacent slats creates traveling wave
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   Sees silhouette of all slat tops forming wave profile
 *   Wave crest appears to travel RIGHT to LEFT
 *
 * Reference: David C. Roy kinetic sculptures
 */

$fn = 32;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// LAYOUT PARAMETERS
// ============================================

NUM_SLATS = 24;              // Number of vertical slats
SLAT_SPACING = 8;            // X distance between slats (mm)
TOTAL_WIDTH = (NUM_SLATS - 1) * SLAT_SPACING;  // ~184mm

PHASE_OFFSET = 360 / 8;      // 45° between adjacent slats
                              // 8 slats = one full wave cycle
                              // With 24 slats = 3 visible waves

// ============================================
// SLAT DIMENSIONS
// ============================================

SLAT_WIDTH = 3;              // X dimension (thin)
SLAT_DEPTH = 25;             // Y dimension (into screen)
SLAT_BASE_HEIGHT = 30;       // Z dimension (base height)

AMPLITUDE = 10;              // Vertical motion amplitude (mm)

// ============================================
// CAMSHAFT (drives all slats)
// ============================================

CAMSHAFT_DIA = 6;
CAMSHAFT_Y = 0;              // Center depth
CAMSHAFT_Z = 10;             // Below slats

CAM_RADIUS = 5;              // Eccentric offset on cam
CAM_WIDTH = 6;               // Cam thickness

// ============================================
// COLORS
// ============================================

// Gradient from deep blue (left/shore) to light blue (right/ocean)
function slat_color(i) =
    let(t = i / (NUM_SLATS - 1))
    [0.1 + 0.4 * t, 0.3 + 0.3 * t, 0.5 + 0.4 * t];

C_SHAFT = [0.5, 0.5, 0.55];
C_CAM = [0.7, 0.5, 0.2];
C_FRAME = [0.3, 0.3, 0.35];

// ============================================
// KINEMATICS
// ============================================

// Each slat's phase (wave travels LEFT, so RIGHT slats lead)
function slat_phase(i) = theta + (NUM_SLATS - 1 - i) * PHASE_OFFSET;

// Slat vertical position (pure sinusoidal bob)
function slat_z(i) = SLAT_BASE_HEIGHT + AMPLITUDE * sin(slat_phase(i));

// Cam rotation angle for this slat
function cam_angle(i) = slat_phase(i);

// ============================================
// MODULES
// ============================================

// Single vertical slat
module slat(i) {
    x_pos = i * SLAT_SPACING - TOTAL_WIDTH / 2;
    z_pos = slat_z(i);

    color(slat_color(i))
    translate([x_pos, -SLAT_DEPTH/2, CAMSHAFT_Z + CAM_RADIUS])
        cube([SLAT_WIDTH, SLAT_DEPTH, z_pos]);

    // Rounded top for smoother silhouette
    color(slat_color(i))
    translate([x_pos + SLAT_WIDTH/2, 0, CAMSHAFT_Z + CAM_RADIUS + z_pos])
    rotate([90, 0, 0])
        cylinder(d=SLAT_WIDTH, h=SLAT_DEPTH, center=true);
}

// Single cam (eccentric disc on shaft)
module cam(i) {
    x_pos = i * SLAT_SPACING - TOTAL_WIDTH / 2;

    color(C_CAM)
    translate([x_pos + SLAT_WIDTH/2, CAMSHAFT_Y, CAMSHAFT_Z])
    rotate([0, 90, 0])
    rotate([0, 0, cam_angle(i)])
    translate([CAM_RADIUS, 0, 0])  // Eccentric offset
        cylinder(d=8, h=CAM_WIDTH, center=true);
}

// Camshaft (single shaft through all cams)
module camshaft() {
    color(C_SHAFT)
    translate([-TOTAL_WIDTH/2 - 10, CAMSHAFT_Y, CAMSHAFT_Z])
    rotate([0, 90, 0])
        cylinder(d=CAMSHAFT_DIA, h=TOTAL_WIDTH + 20);
}

// Follower pins (connect slats to cams)
module follower(i) {
    x_pos = i * SLAT_SPACING - TOTAL_WIDTH / 2;
    phase = slat_phase(i);

    // Cam contact point
    cam_x = x_pos + SLAT_WIDTH/2;
    cam_y = CAMSHAFT_Y + CAM_RADIUS * sin(phase);
    cam_z = CAMSHAFT_Z + CAM_RADIUS * cos(phase);

    color([0.6, 0.6, 0.6])
    translate([cam_x, cam_y, cam_z])
        sphere(d=4);
}

// Frame base
module frame() {
    color(C_FRAME)
    translate([-TOTAL_WIDTH/2 - 15, -20, 0])
        cube([TOTAL_WIDTH + 30, 40, 5]);

    // Shaft bearings
    color(C_FRAME) {
        translate([-TOTAL_WIDTH/2 - 15, -8, 0])
        difference() {
            cube([10, 16, CAMSHAFT_Z + 8]);
            translate([5, 8, CAMSHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA + 0.6, h=12, center=true);
        }

        translate([TOTAL_WIDTH/2 + 5, -8, 0])
        difference() {
            cube([10, 16, CAMSHAFT_Z + 8]);
            translate([5, 8, CAMSHAFT_Z])
            rotate([0, 90, 0])
                cylinder(d=CAMSHAFT_DIA + 0.6, h=12, center=true);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_slatsC() {
    frame();
    camshaft();

    for (i = [0:NUM_SLATS-1]) {
        slat(i);
        cam(i);
        // follower(i);  // Uncomment to see cam contact points
    }
}

// Render
wave_ocean_v10_slatsC();

// ============================================
// DEBUG
// ============================================

echo("=== WAVE OCEAN V10 - APPROACH C: VERTICAL SLATS ===");
echo(str("Slats: ", NUM_SLATS));
echo(str("Total width: ", TOTAL_WIDTH, "mm"));
echo(str("Phase offset per slat: ", PHASE_OFFSET, " degrees"));
echo(str("Visible wave cycles: ", NUM_SLATS * PHASE_OFFSET / 360));
echo(str("Amplitude: +/-", AMPLITUDE, "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Watch from FRONT (F5, rotate to -Y) - wave travels RIGHT to LEFT");

// ============================================
// PHYSICAL MECHANISM NOTES
// ============================================

/*
 * Each slat rides on an eccentric cam.
 * All cams are on ONE shared shaft.
 * Cams are mounted at different angles = phase offset.
 *
 * Physical assembly:
 * 1. Print 24 cams, each indexed to its mounting angle
 * 2. Press cams onto shaft at correct positions
 * 3. Each slat has a follower pin resting on its cam
 * 4. Gravity keeps follower on cam (or add spring)
 * 5. Rotate shaft = all slats bob in traveling wave pattern
 *
 * OR simpler:
 * - Use a WORM CAMSHAFT (helical cam surface)
 * - All slats follow the helix
 * - Phase offset is built into helix twist
 */
