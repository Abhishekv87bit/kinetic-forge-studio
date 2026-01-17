// ============================================================================
// PROJECT: Starry Night Kinetic Automaton - Animation Wrapper
// VERSION: V30
// DESCRIPTION: Animation test wrapper for verifying motion at multiple $t values
// LAST MODIFIED: 2026-01-16
// ============================================================================
// USAGE:
//   1. Open this file in OpenSCAD
//   2. Go to View -> Animate
//   3. Set FPS: 30, Steps: 360
//   4. Click play to see full animation cycle
//
// MANUAL TESTING:
//   Set TEST_T to specific values (0.0, 0.25, 0.5, 0.75, 1.0) to verify
//   positions at key animation frames.
// ============================================================================

// --- Include main design file ---
include <starry_night_v30.scad>

// ============================================================================
// MANUAL TEST MODE
// ============================================================================
// Set USE_TEST_T = true to override animation and test specific $t values
// This allows verification at exact positions without running animation

USE_TEST_T = false;     // Set to true to use TEST_T instead of $t
TEST_T = 0.0;           // Test value: try 0.0, 0.25, 0.5, 0.75, 1.0

// Override $t if in test mode
$t = USE_TEST_T ? TEST_T : $t;

// ============================================================================
// ANIMATION TEST REPORT
// ============================================================================

module animation_test_report() {
    current_t = USE_TEST_T ? TEST_T : $t;

    echo("");
    echo("+===========================================+");
    echo("|     ANIMATION TEST REPORT - V30          |");
    echo("+===========================================+");
    echo(str("|  Mode: ", USE_TEST_T ? "MANUAL TEST" : "ANIMATION", "                   |"));
    echo(str("|  $t = ", current_t, "                              |"));
    echo("+===========================================+");
    echo("");

    // Calculate all animated values at current $t
    _motor = current_t * 360;
    _master = -_motor / 6;
    _wave1 = 12 * sin(current_t * 360);
    _wave2 = 12 * sin(current_t * 360 + 120);
    _wave3 = 12 * sin(current_t * 360 + 240);
    _moon = 15 * sin(current_t * 360);
    _lighthouse = _master / 4;

    echo("MOTION VALUES:");
    echo(str("  Motor angle:      ", _motor, " deg"));
    echo(str("  Master angle:     ", _master, " deg"));
    echo(str("  Wave 1 offset:    ", _wave1, " mm"));
    echo(str("  Wave 2 offset:    ", _wave2, " mm"));
    echo(str("  Wave 3 offset:    ", _wave3, " mm"));
    echo(str("  Moon swing:       ", _moon, " deg"));
    echo(str("  Lighthouse angle: ", _lighthouse, " deg"));
    echo("");

    // Verify expected values at key frames
    if (abs(current_t - 0.0) < 0.01) {
        echo("EXPECTED at t=0.0:");
        echo("  Motor: 0 deg, Waves: [0, -10.4, 10.4] mm, Moon: 0 deg");
    }
    if (abs(current_t - 0.25) < 0.01) {
        echo("EXPECTED at t=0.25:");
        echo("  Motor: 90 deg, Waves: [12, 6, -6] mm, Moon: 15 deg");
    }
    if (abs(current_t - 0.5) < 0.01) {
        echo("EXPECTED at t=0.5:");
        echo("  Motor: 180 deg, Waves: [0, -10.4, 10.4] mm, Moon: 0 deg");
    }
    if (abs(current_t - 0.75) < 0.01) {
        echo("EXPECTED at t=0.75:");
        echo("  Motor: 270 deg, Waves: [-12, -6, 6] mm, Moon: -15 deg");
    }
    if (abs(current_t - 1.0) < 0.01) {
        echo("EXPECTED at t=1.0:");
        echo("  Motor: 360 deg (=0), Waves: [0, -10.4, 10.4] mm, Moon: 0 deg");
    }
    echo("");
}

// Run animation test report
animation_test_report();

// ============================================================================
// VERIFICATION CHECKLIST
// ============================================================================

module verification_checklist() {
    echo("+===========================================+");
    echo("|     VERIFICATION CHECKLIST               |");
    echo("+===========================================+");
    echo("|  [ ] All 3 waves move side-to-side       |");
    echo("|  [ ] Wave phases are offset (rolling)    |");
    echo("|  [ ] All 5 swirl discs rotate            |");
    echo("|  [ ] Swirls rotate correct directions    |");
    echo("|  [ ] Moon oscillates back and forth      |");
    echo("|  [ ] Lighthouse beam rotates steadily    |");
    echo("|  [ ] No component disappears             |");
    echo("|  [ ] No visible collisions               |");
    echo("|  [ ] Gears mesh properly                 |");
    echo("|  [ ] Motor pinion drives master gear     |");
    echo("+===========================================+");
    echo("");
}

verification_checklist();

// ============================================================================
// QUICK TEST CONFIGURATIONS
// ============================================================================
// Uncomment one of these blocks to test specific configurations:

// --- Test 1: Only show waves ---
/*
SHOW_FRAME = false;
SHOW_BACK = false;
SHOW_CLIFF = false;
SHOW_MOTOR = false;
SHOW_GEARS = false;
SHOW_WAVES = true;
SHOW_SWIRLS = false;
SHOW_MOON = false;
SHOW_LIGHTHOUSE = false;
SHOW_VILLAGE = false;
SHOW_CYPRESS = false;
SHOW_STARS = false;
*/

// --- Test 2: Only show gears and motor ---
/*
SHOW_FRAME = false;
SHOW_BACK = false;
SHOW_CLIFF = true;  // Keep cliff to see motor cavity
SHOW_MOTOR = true;
SHOW_GEARS = true;
SHOW_WAVES = false;
SHOW_SWIRLS = false;
SHOW_MOON = false;
SHOW_LIGHTHOUSE = false;
SHOW_VILLAGE = false;
SHOW_CYPRESS = false;
SHOW_STARS = false;
TRANSPARENT_CLIFF = true;  // See inside cliff
*/

// --- Test 3: Only show swirls ---
/*
SHOW_FRAME = false;
SHOW_BACK = false;
SHOW_CLIFF = false;
SHOW_MOTOR = false;
SHOW_GEARS = false;
SHOW_WAVES = false;
SHOW_SWIRLS = true;
SHOW_MOON = false;
SHOW_LIGHTHOUSE = false;
SHOW_VILLAGE = false;
SHOW_CYPRESS = false;
SHOW_STARS = false;
*/

// --- Test 4: Only show moon and lighthouse ---
/*
SHOW_FRAME = false;
SHOW_BACK = false;
SHOW_CLIFF = false;
SHOW_MOTOR = false;
SHOW_GEARS = false;
SHOW_WAVES = false;
SHOW_SWIRLS = false;
SHOW_MOON = true;
SHOW_LIGHTHOUSE = true;
SHOW_VILLAGE = false;
SHOW_CYPRESS = false;
SHOW_STARS = false;
*/

// ============================================================================
// BATCH TEST SCRIPT
// ============================================================================
// To test at multiple $t values from command line:
//
// Windows (PowerShell):
// ```
// $t_values = @(0.0, 0.25, 0.5, 0.75, 1.0)
// foreach ($t in $t_values) {
//     Write-Host "Testing t=$t"
//     & "C:\Program Files\OpenSCAD\openscad.exe" `
//         -D "USE_TEST_T=true" -D "TEST_T=$t" `
//         -o "test_t_$t.png" `
//         starry_night_v30_animate.scad
// }
// ```
//
// Linux/Mac (Bash):
// ```
// for t in 0.0 0.25 0.5 0.75 1.0; do
//     echo "Testing t=$t"
//     openscad -D "USE_TEST_T=true" -D "TEST_T=$t" \
//         -o "test_t_$t.png" \
//         starry_night_v30_animate.scad
// done
// ```
// ============================================================================

// ============================================================================
// ANIMATION EXPORT SETTINGS
// ============================================================================
// To export animation as image sequence:
//   View -> Animate
//   Set FPS: 30, Steps: 360
//   View -> Export -> Export Image Sequence
//
// To create GIF from image sequence (using ImageMagick):
//   convert -delay 3 -loop 0 frame*.png starry_night_v30.gif
//
// Recommended export settings:
//   Resolution: 1920x1080 or 1280x720
//   File format: PNG (for quality) or JPG (for size)
// ============================================================================

echo("");
echo("Animation wrapper loaded successfully.");
echo("Use View -> Animate to see motion, or set USE_TEST_T=true for manual testing.");
echo("");

// ============================================================================
// END OF ANIMATION WRAPPER
// ============================================================================
