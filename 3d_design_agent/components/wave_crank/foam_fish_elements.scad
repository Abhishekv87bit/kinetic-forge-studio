/*
 * FOAM & FISH ELEMENTS - PRINT PARTS
 *
 * Elements to mount on wave tops for Wave Ocean v6
 *
 * ZONES:
 *   Zone A (Waves 1-7):   Small organic foam - 7 pieces
 *   Zone B (Waves 8-14):  Medium organic foam - 7 pieces
 *   Zone C (Waves 15-22): Fish elements - 8 pieces
 *
 * PART SELECTION:
 *   0 = All elements on plate
 *   1 = Single small foam
 *   2 = All 7 small foam
 *   3 = Single medium foam
 *   4 = All 7 medium foam
 *   5 = Single fish
 *   6 = All 8 fish
 *   7 = Mixed plate (2 of each for test)
 */

PART_SELECT = 0;

$fn = 32;

// ============================================
// COLORS
// ============================================

C_FOAM = [0.95, 0.98, 1.0];     // White foam
C_FISH = [0.3, 0.5, 0.7];       // Blue-gray fish

// ============================================
// ELEMENT MODULES
// ============================================

// Small organic foam blob (Zone A) - 8×6×3mm
module foam_small() {
    color(C_FOAM)
    union() {
        // Organic blob using hull of spheres
        hull() {
            translate([0, 0, 2]) sphere(r=3);
            translate([-2, 0, 4]) sphere(r=2);
            translate([2, 0, 3.5]) sphere(r=2.5);
            translate([0, 0, 5]) sphere(r=1.5);
        }
        // Mount post (2mm dia × 3mm)
        translate([0, 0, -3])
            cylinder(d=2, h=3.5);
    }
}

// Medium organic foam blob (Zone B) - 12×9×4mm
module foam_medium() {
    color(C_FOAM)
    union() {
        // Larger organic blob
        hull() {
            translate([0, 0, 3]) sphere(r=4);
            translate([-3, 0, 5]) sphere(r=3);
            translate([3, 0, 4]) sphere(r=3);
            translate([0, 0, 7]) sphere(r=2);
            translate([-1, 0, 8]) sphere(r=1.5);
        }
        // Mount post (2.5mm dia × 4mm)
        translate([0, 0, -4])
            cylinder(d=2.5, h=4.5);
    }
}

// Fish element (Zone C) - 14×10×5mm, facing sideways
module fish_element() {
    color(C_FISH)
    union() {
        // Fish body - elongated hull
        hull() {
            // Head (front)
            translate([5, 0, 0]) sphere(r=3);
            // Body center
            translate([0, 0, 0]) scale([1, 0.6, 1]) sphere(r=4);
            // Tail junction
            translate([-5, 0, 0]) sphere(r=2);
        }

        // Tail fin
        hull() {
            translate([-5, 0, 0]) sphere(r=1);
            translate([-9, 0, 3]) sphere(r=0.5);
            translate([-9, 0, -3]) sphere(r=0.5);
        }

        // Dorsal fin
        hull() {
            translate([0, 0, 3.5]) sphere(r=0.5);
            translate([-2, 0, 5]) sphere(r=0.3);
            translate([2, 0, 3]) sphere(r=0.5);
        }

        // Pectoral fin (side)
        hull() {
            translate([1, 3, 0]) sphere(r=0.5);
            translate([-1, 5, 1]) sphere(r=0.3);
            translate([-1, 5, -1]) sphere(r=0.3);
        }

        // Eye (small bump)
        translate([4, 2.5, 1]) sphere(r=0.8);

        // Mount post (3mm dia × 5mm)
        translate([0, 0, -5])
            cylinder(d=3, h=5.5);
    }
}

// ============================================
// PRINT LAYOUTS
// ============================================

// All small foam on plate (7 pieces)
module print_all_small_foam() {
    spacing = 12;
    for (i = [0:6]) {
        translate([i * spacing, 0, 3])  // Z offset for post
            foam_small();
    }
}

// All medium foam on plate (7 pieces)
module print_all_medium_foam() {
    spacing = 16;
    for (i = [0:6]) {
        translate([i * spacing, 0, 4])  // Z offset for post
            foam_medium();
    }
}

// All fish on plate (8 pieces)
module print_all_fish() {
    spacing = 20;
    for (i = [0:7]) {
        translate([i * spacing, 0, 5])  // Z offset for post
            fish_element();
    }
}

// Mixed test plate (2 of each)
module print_mixed_test() {
    // Small foam
    translate([0, 0, 3]) foam_small();
    translate([12, 0, 3]) foam_small();

    // Medium foam
    translate([30, 0, 4]) foam_medium();
    translate([46, 0, 4]) foam_medium();

    // Fish
    translate([70, 0, 5]) fish_element();
    translate([90, 0, 5]) fish_element();
}

// Full plate with all 22 elements
module print_all_elements() {
    // Row 1: Small foam (7)
    for (i = [0:6]) {
        translate([i * 12, 0, 3])
            foam_small();
    }

    // Row 2: Medium foam (7)
    for (i = [0:6]) {
        translate([i * 16, 25, 4])
            foam_medium();
    }

    // Row 3: Fish (8)
    for (i = [0:7]) {
        translate([i * 20, 55, 5])
            fish_element();
    }
}

// ============================================
// PART SELECTION
// ============================================

if (PART_SELECT == 0) {
    echo("=== ALL 22 ELEMENTS ON PLATE ===");
    print_all_elements();
}
else if (PART_SELECT == 1) {
    echo("Part 1: Single small foam");
    translate([0, 0, 3]) foam_small();
}
else if (PART_SELECT == 2) {
    echo("Part 2: All 7 small foam");
    print_all_small_foam();
}
else if (PART_SELECT == 3) {
    echo("Part 3: Single medium foam");
    translate([0, 0, 4]) foam_medium();
}
else if (PART_SELECT == 4) {
    echo("Part 4: All 7 medium foam");
    print_all_medium_foam();
}
else if (PART_SELECT == 5) {
    echo("Part 5: Single fish");
    translate([0, 0, 5]) fish_element();
}
else if (PART_SELECT == 6) {
    echo("Part 6: All 8 fish");
    print_all_fish();
}
else if (PART_SELECT == 7) {
    echo("Part 7: Mixed test plate (2 of each)");
    print_mixed_test();
}

// ============================================
// CONSOLE OUTPUT
// ============================================

echo("");
echo("╔═══════════════════════════════════════════════════════════════╗");
echo("║         FOAM & FISH ELEMENTS - PRINT PARTS                    ║");
echo("╠═══════════════════════════════════════════════════════════════╣");
echo("║                                                               ║");
echo("║  ZONE A - Small Foam (Waves 1-7):                             ║");
echo("║    Qty: 7                                                     ║");
echo("║    Size: ~8×6×3mm + 2mm post                                  ║");
echo("║    Color: White                                               ║");
echo("║                                                               ║");
echo("║  ZONE B - Medium Foam (Waves 8-14):                           ║");
echo("║    Qty: 7                                                     ║");
echo("║    Size: ~12×9×4mm + 2.5mm post                               ║");
echo("║    Color: White                                               ║");
echo("║                                                               ║");
echo("║  ZONE C - Fish (Waves 15-22):                                 ║");
echo("║    Qty: 8                                                     ║");
echo("║    Size: ~14×10×5mm + 3mm post                                ║");
echo("║    Color: Blue-gray (or paint after printing)                 ║");
echo("║                                                               ║");
echo("╠═══════════════════════════════════════════════════════════════╣");
echo("║  PRINT TIPS:                                                  ║");
echo("║    - Print posts DOWN (touching bed)                          ║");
echo("║    - Use supports for overhangs                               ║");
echo("║    - 0.2mm layer height for detail                            ║");
echo("║    - White PLA for foam, blue/gray for fish                   ║");
echo("╚═══════════════════════════════════════════════════════════════╝");
