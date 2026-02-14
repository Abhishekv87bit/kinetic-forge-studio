/*
 * WAVE OCEAN V10 - APPROACH B: CAM-FOLLOWER
 * Single wave test - validates mechanism geometry
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   X = horizontal (left/right)
 *   Z = vertical (up/down)
 *   Y = depth (into screen)
 *
 * MECHANISM: Elliptical cam drives wave slat that pivots on tab-in-slot
 *   - Camshaft with elliptical cam
 *   - Wave slat has follower pin riding on cam surface
 *   - Tab at back end slides in horizontal slot (constrained pivot)
 *
 * Expected motion: Wave rocks like seesaw, front rises/falls with cam
 */

$fn = 48;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// PHYSICAL DIMENSIONS (mm)
// ============================================

// Camshaft (runs along Y axis, perpendicular to viewer)
CAMSHAFT_DIA = 6;
CAMSHAFT_LENGTH = 80;
CAMSHAFT_X = 0;        // Centered in X
CAMSHAFT_Z = 15;       // Height of shaft axis

// Elliptical cam (mounted on shaft)
CAM_MAJOR = 12;        // Vertical radius (determines amplitude)
CAM_MINOR = 8;         // Horizontal radius (along shaft axis)
CAM_WIDTH = 8;         // Thickness of cam

// Slot rail (back of mechanism, wave tab slides in slot)
SLOT_RAIL_Y = -30;     // Position (back, away from viewer)
SLOT_RAIL_Z = 35;      // Height of slot
SLOT_RAIL_LENGTH = 60; // X dimension
SLOT_RAIL_HEIGHT = 15; // Z dimension
SLOT_RAIL_DEPTH = 12;  // Y dimension

SLOT_WIDTH = 10;       // X dimension (allows horizontal slide)
SLOT_HEIGHT = 5;       // Z dimension (fits 4mm tab)

// Wave slat (connects tab to follower)
SLAT_LENGTH = 50;      // From tab pivot to follower contact
SLAT_WIDTH = 6;        // X dimension
SLAT_THICKNESS = 4;    // Y dimension

// Tab (at back end, slides in slot)
TAB_WIDTH = 8;
TAB_HEIGHT = 4;
TAB_DEPTH = 10;

// Follower pin (at front end, contacts cam)
FOLLOWER_DIA = 5;
FOLLOWER_LENGTH = 10;

// Wave profile (decorative shape on top of slat)
WAVE_PROFILE_WIDTH = 40;
WAVE_PROFILE_HEIGHT = 20;

// Frame reference
FRAME_WIDTH = 80;
FRAME_DEPTH = 60;
FRAME_HEIGHT = 5;

// ============================================
// COLORS
// ============================================

C_SHAFT = [0.6, 0.6, 0.65];
C_CAM = [0.8, 0.5, 0.2];       // Bronze
C_SLOT_RAIL = [0.35, 0.35, 0.4];
C_SLAT = [0.25, 0.45, 0.75];   // Ocean blue
C_FOLLOWER = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.3, 0.35];

// ============================================
// KINEMATICS
// ============================================

// Cam surface position (where follower contacts cam)
// Cam is ellipse: z = CAM_MAJOR * cos(theta), y = CAM_MINOR * sin(theta)
function cam_contact_z() = CAMSHAFT_Z + CAM_MAJOR * cos(theta);
function cam_contact_y() = CAM_MINOR * sin(theta);  // Relative to shaft Y

// Tab position (pivot point, slides in slot)
TAB_Y = SLOT_RAIL_Y + SLOT_RAIL_DEPTH / 2;
TAB_Z = SLOT_RAIL_Z;

// Wave slat angle (from geometry)
// Slat goes from tab (back) to follower contact (front)
// tan(angle) = (cam_z - tab_z) / (cam_y - tab_y)
function slat_angle() =
    let(
        fz = cam_contact_z(),
        fy = cam_contact_y(),
        tz = TAB_Z,
        ty = TAB_Y
    )
    atan2(fz - tz, fy - ty);

// Tab X position (slides to accommodate angle change)
// As slat rotates, tab needs to move horizontally
function tab_x_offset() =
    let(angle = slat_angle())
    SLAT_LENGTH * (1 - cos(angle - 45)) * 0.3;  // Approximate

// Verify slat length is constant
function verify_slat_length() =
    let(
        fz = cam_contact_z(),
        fy = cam_contact_y(),
        tz = TAB_Z,
        ty = TAB_Y
    )
    sqrt(pow(fy - ty, 2) + pow(fz - tz, 2));

// ============================================
// MODULES: MECHANISM PARTS
// ============================================

// Camshaft (runs along Y axis)
module camshaft() {
    color(C_SHAFT)
    translate([CAMSHAFT_X, -CAMSHAFT_LENGTH/2, CAMSHAFT_Z])
    rotate([-90, 0, 0])
        cylinder(d=CAMSHAFT_DIA, h=CAMSHAFT_LENGTH);
}

// Elliptical cam (mounted on shaft, rotates with it)
module elliptical_cam() {
    cam_y = 0;  // Center position along shaft

    color(C_CAM)
    translate([CAMSHAFT_X, cam_y, CAMSHAFT_Z])
    rotate([-90, 0, 0])  // Align with shaft
    rotate([0, 0, theta])  // Rotate with animation
    scale([1, CAM_MINOR / CAM_MAJOR, 1])
    difference() {
        cylinder(r=CAM_MAJOR, h=CAM_WIDTH, center=true);
        cylinder(d=CAMSHAFT_DIA + 0.4, h=CAM_WIDTH + 2, center=true);
    }
}

// Slot rail (tab slides in slot, constrained pivot)
module slot_rail() {
    color(C_SLOT_RAIL)
    translate([-SLOT_RAIL_LENGTH/2, SLOT_RAIL_Y, SLOT_RAIL_Z - SLOT_RAIL_HEIGHT/2])
    difference() {
        // Rail body
        cube([SLOT_RAIL_LENGTH, SLOT_RAIL_DEPTH, SLOT_RAIL_HEIGHT]);
        // Slot for tab
        translate([SLOT_RAIL_LENGTH/2 - SLOT_WIDTH/2, -1, SLOT_RAIL_HEIGHT/2 - SLOT_HEIGHT/2])
            cube([SLOT_WIDTH, SLOT_RAIL_DEPTH + 2, SLOT_HEIGHT]);
    }
}

// Wave slat with tab and follower
module wave_slat() {
    angle = slat_angle();
    tx = tab_x_offset();

    // Position at tab pivot point
    translate([tx, TAB_Y, TAB_Z])
    rotate([angle - 90, 0, 0]) {  // Rotate to follow cam
        // Tab (back end, rides in slot)
        color(C_SLAT)
        translate([-TAB_WIDTH/2, -TAB_DEPTH, -TAB_HEIGHT/2])
            cube([TAB_WIDTH, TAB_DEPTH, TAB_HEIGHT]);

        // Slat body (connects tab to follower)
        color(C_SLAT)
        translate([-SLAT_WIDTH/2, 0, -SLAT_THICKNESS/2])
            cube([SLAT_WIDTH, SLAT_LENGTH, SLAT_THICKNESS]);

        // Follower pin (front end, contacts cam)
        color(C_FOLLOWER)
        translate([0, SLAT_LENGTH, 0])
        rotate([0, 90, 0])
            cylinder(d=FOLLOWER_DIA, h=FOLLOWER_LENGTH, center=true);

        // Wave profile (decorative ocean wave shape on top)
        color(C_SLAT)
        translate([0, SLAT_LENGTH * 0.4, SLAT_THICKNESS/2])
        rotate([90, 0, 90])
        linear_extrude(height=4, center=true)
        polygon([
            [0, 0],
            [SLAT_LENGTH * 0.3, WAVE_PROFILE_HEIGHT * 0.4],
            [SLAT_LENGTH * 0.5, WAVE_PROFILE_HEIGHT],
            [SLAT_LENGTH * 0.7, WAVE_PROFILE_HEIGHT * 0.6],
            [SLAT_LENGTH * 0.8, 0]
        ]);
    }
}

// Base frame (static reference)
module base_frame() {
    color(C_FRAME)
    translate([-FRAME_WIDTH/2, -FRAME_DEPTH/2, 0])
        cube([FRAME_WIDTH, FRAME_DEPTH, FRAME_HEIGHT]);

    // Shaft supports
    color(C_FRAME) {
        // Front bearing
        translate([CAMSHAFT_X - 8, CAMSHAFT_LENGTH/2 - 5, 0])
        difference() {
            cube([16, 10, CAMSHAFT_Z + 8]);
            translate([8, 5, CAMSHAFT_Z])
            rotate([-90, 0, 0])
                cylinder(d=CAMSHAFT_DIA + 0.6, h=12, center=true);
        }

        // Back bearing
        translate([CAMSHAFT_X - 8, -CAMSHAFT_LENGTH/2 - 5, 0])
        difference() {
            cube([16, 10, CAMSHAFT_Z + 8]);
            translate([8, 5, CAMSHAFT_Z])
            rotate([-90, 0, 0])
                cylinder(d=CAMSHAFT_DIA + 0.6, h=12, center=true);
        }
    }
}

// Follower contact point visualization (debug)
module follower_contact_point() {
    color([1, 0, 0])
    translate([CAMSHAFT_X, cam_contact_y(), cam_contact_z()])
        sphere(d=3);
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_camB() {
    base_frame();
    slot_rail();
    camshaft();
    elliptical_cam();
    wave_slat();
    // follower_contact_point();  // Uncomment to see contact point
}

// Render
wave_ocean_v10_camB();

// ============================================
// DEBUG OUTPUT
// ============================================

echo("=== WAVE OCEAN V10 - APPROACH B: CAM-FOLLOWER ===");
echo(str("theta = ", theta, " degrees"));
echo(str("Cam contact: Y=", cam_contact_y(), " Z=", cam_contact_z()));
echo(str("Slat angle = ", slat_angle(), " degrees"));
echo(str("Tab X offset = ", tab_x_offset(), "mm"));
echo("");
echo("Mechanism check:");
echo(str("  Cam major (Z amplitude): ", CAM_MAJOR, "mm"));
echo(str("  Cam minor (Y offset): ", CAM_MINOR, "mm"));
echo(str("  Slat length: ", SLAT_LENGTH, "mm (should be constant)"));
echo(str("  Verified slat length: ", verify_slat_length(), "mm"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Watch from FRONT (looking at -Y) to see wave rocking motion");

// ============================================
// SIN($t) AUDIT - ALL TRIG TRACES TO MECHANISM
// ============================================

/*
 * cam_contact_z() = CAMSHAFT_Z + CAM_MAJOR * cos(theta)
 *   Physical: Elliptical cam rotation, major axis lifts follower
 *
 * cam_contact_y() = CAM_MINOR * sin(theta)
 *   Physical: Elliptical cam rotation, minor axis shifts follower forward/back
 *
 * slat_angle() = atan2(cam_z - tab_z, cam_y - tab_y)
 *   Physical: Geometry from fixed tab pivot to moving follower contact
 *
 * ORPHAN ANIMATIONS: 0
 */

// ============================================
// MOTION COMPARISON NOTES
// ============================================

/*
 * At theta=0:   Cam pushes follower UP (cam_z = 15 + 12 = 27)
 *               Wave front is HIGH, wave tips forward
 *
 * At theta=90:  Cam at side (cam_z = 15, cam_y = 8)
 *               Wave front at mid height, shifted forward
 *
 * At theta=180: Cam at bottom (cam_z = 15 - 12 = 3)
 *               Wave front is LOW, wave tips back
 *
 * At theta=270: Cam at side (cam_z = 15, cam_y = -8)
 *               Wave front at mid height, shifted back
 *
 * This creates a ROCKING motion with slight Y drift.
 * From front view: looks like wave rising and falling while
 * tilting forward at peak (like a real wave about to break).
 */
