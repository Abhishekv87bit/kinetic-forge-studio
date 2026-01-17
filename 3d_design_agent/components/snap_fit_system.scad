// ═══════════════════════════════════════════════════════════════════════════════════════
//                           SNAP-FIT AXLE SYSTEM
//                           Full Parametric Modules for Printed Axles
//                           Designed for FDM 3D Printing
// ═══════════════════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                TOLERANCE PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Adjust these based on printer calibration

FIT_INTERFERENCE = 0.2;    // Press fit for snap features (mm)
FIT_TRANSITION = 0.1;      // Snug fit for located positions (mm)
FIT_CLEARANCE = 0.3;       // Running fit for rotating parts (mm)
FIT_LOOSE = 0.5;           // Loose fit for easy assembly (mm)

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                SNAP-FIT BOSS MODULE
//                     Receives snap-fit pin - mounts to background/frame
// ═══════════════════════════════════════════════════════════════════════════════════════
// Creates a boss with internal snap ring groove and flex slots
// Pin snaps into this boss and can rotate freely

module snap_fit_boss(
    shaft_diameter = 4,          // Shaft diameter to accept
    boss_height = 8,             // Total boss height
    boss_od = 12,                // Outer diameter of boss
    snap_depth = 0.8,            // Snap feature depth (radial)
    snap_height = 2,             // Height of snap groove
    snap_position = -1,          // Distance from top to snap (-1 = auto: boss_height - snap_height - 1)
    interference = -1,           // Press fit interference (-1 = use FIT_INTERFERENCE)
    wall_thickness = 2,          // Minimum wall thickness around bore
    chamfer = 0.5,               // Entry chamfer for easy insertion
    flex_slots = 4,              // Number of flexibility slots (0 to disable)
    flex_slot_width = 1,         // Width of flex slots
    flex_slot_depth = -1,        // Depth of flex slots (-1 = auto)
    mounting_flange = true,      // Add mounting flange at base
    flange_thickness = 2,        // Flange thickness
    flange_od = -1,              // Flange outer diameter (-1 = boss_od + 4)
    mounting_holes = 2,          // Number of mounting screw holes (0 to disable)
    mounting_hole_dia = 3        // Mounting hole diameter
) {
    // Resolve auto parameters
    _interference = interference == -1 ? FIT_INTERFERENCE : interference;
    _snap_position = snap_position == -1 ? boss_height - snap_height - 1 : snap_position;
    _flex_slot_depth = flex_slot_depth == -1 ? _snap_position + snap_height + 1 : flex_slot_depth;
    _flange_od = flange_od == -1 ? boss_od + 4 : flange_od;

    // Calculate bore diameter (shaft minus interference for grip)
    bore_d = shaft_diameter - _interference;

    // Validate parameters
    assert(boss_od >= shaft_diameter + wall_thickness * 2,
           "Boss OD too small for shaft + wall thickness");
    assert(snap_depth < (boss_od - shaft_diameter) / 2 - wall_thickness,
           "Snap depth too large - would compromise wall");

    union() {
        difference() {
            union() {
                // Main boss body
                cylinder(d=boss_od, h=boss_height);

                // Entry chamfer collar (makes insertion easier)
                if (chamfer > 0) {
                    translate([0, 0, boss_height - chamfer])
                    cylinder(d1=boss_od, d2=boss_od + chamfer*2, h=chamfer);
                }

                // Mounting flange at base
                if (mounting_flange) {
                    cylinder(d=_flange_od, h=flange_thickness);
                }
            }

            // Main bore (clearance fit for rotation)
            translate([0, 0, -0.1])
            cylinder(d=shaft_diameter + FIT_CLEARANCE, h=boss_height + 0.2);

            // Entry chamfer in bore
            translate([0, 0, boss_height - chamfer])
            cylinder(d1=shaft_diameter + FIT_CLEARANCE,
                     d2=shaft_diameter + FIT_CLEARANCE + chamfer*2,
                     h=chamfer + 0.1);

            // Snap ring groove (internal recess for snap bulge)
            translate([0, 0, _snap_position])
            difference() {
                cylinder(d=shaft_diameter + FIT_CLEARANCE + snap_depth*2, h=snap_height);
                translate([0, 0, -0.1])
                cylinder(d=shaft_diameter + FIT_CLEARANCE - 0.1, h=snap_height + 0.2);
            }

            // Flexibility slots (allow boss to flex during snap insertion)
            if (flex_slots > 0) {
                for (i = [0:flex_slots-1]) {
                    rotate([0, 0, i * (360/flex_slots)])
                    translate([0, -flex_slot_width/2, boss_height - _flex_slot_depth])
                    cube([boss_od/2 + 1, flex_slot_width, _flex_slot_depth + 0.1]);
                }
            }

            // Mounting holes in flange
            if (mounting_flange && mounting_holes > 0) {
                for (i = [0:mounting_holes-1]) {
                    rotate([0, 0, i * (360/mounting_holes) + 45])
                    translate([(_flange_od + boss_od)/4, 0, -0.1])
                    cylinder(d=mounting_hole_dia, h=flange_thickness + 0.2);
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                SNAP-FIT PIN MODULE
//                         Snaps into boss - attached to gear/component
// ═══════════════════════════════════════════════════════════════════════════════════════
// Creates a shaft with snap bulge(s) that lock into boss groove

module snap_fit_pin(
    shaft_diameter = 4,          // Shaft diameter
    shaft_length = 15,           // Total shaft length (including head)
    snap_diameter = -1,          // Diameter at snap bulge (-1 = auto: shaft + 0.5)
    snap_position = 10,          // Distance from head to center of snap
    snap_height = 1.5,           // Height of snap bulge
    head_diameter = 8,           // Shoulder/head diameter
    head_height = 2,             // Shoulder/head height
    head_style = "shoulder",     // "shoulder", "flat", "countersunk", "none"
    tip_chamfer = 0.5,           // Chamfer at tip for easy insertion
    double_snap = false,         // Add second snap bulge
    snap_2_position = -1         // Position of second snap (-1 = auto)
) {
    // Resolve auto parameters
    _snap_diameter = snap_diameter == -1 ? shaft_diameter + 0.5 : snap_diameter;
    _snap_2_position = snap_2_position == -1 ? snap_position - 5 : snap_2_position;

    union() {
        // Head/shoulder
        if (head_style == "shoulder") {
            cylinder(d=head_diameter, h=head_height);
        } else if (head_style == "flat") {
            cylinder(d=head_diameter, h=head_height);
            // Flat top - no additional geometry
        } else if (head_style == "countersunk") {
            cylinder(d1=head_diameter, d2=shaft_diameter, h=head_height);
        }
        // "none" = no head

        // Calculate shaft start position
        shaft_start = (head_style == "none") ? 0 : head_height;

        // Main shaft
        translate([0, 0, shaft_start])
        cylinder(d=shaft_diameter, h=shaft_length - shaft_start);

        // Primary snap bulge (ramped profile for easy insertion)
        translate([0, 0, shaft_start + snap_position - snap_height/2])
        snap_bulge(shaft_diameter, _snap_diameter, snap_height);

        // Secondary snap bulge (optional)
        if (double_snap) {
            translate([0, 0, shaft_start + _snap_2_position - snap_height/2])
            snap_bulge(shaft_diameter, _snap_diameter, snap_height);
        }

        // Tip chamfer
        if (tip_chamfer > 0) {
            translate([0, 0, shaft_length - tip_chamfer])
            cylinder(d1=shaft_diameter, d2=shaft_diameter - tip_chamfer*2, h=tip_chamfer);
        }
    }
}

// Helper module for snap bulge profile
module snap_bulge(shaft_d, snap_d, height) {
    // Asymmetric ramp: gradual entry, sharper retention
    entry_ratio = 0.7;  // 70% of height for gradual entry ramp
    retain_ratio = 0.3; // 30% of height for retention shoulder

    union() {
        // Entry ramp (gradual slope for insertion)
        cylinder(d1=shaft_d, d2=snap_d, h=height * entry_ratio);

        // Retention shoulder (steeper to prevent pull-out)
        translate([0, 0, height * entry_ratio])
        cylinder(d1=snap_d, d2=shaft_d, h=height * retain_ratio);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           SNAP-FIT GEAR AXLE MODULE
//                    Complete axle assembly for mounting gears
// ═══════════════════════════════════════════════════════════════════════════════════════
// Combines boss and pin into complete assembly for visualization

module snap_fit_gear_axle_assembly(
    shaft_diameter = 4,
    boss_height = 8,
    shaft_length = 15,
    gear_thickness = 5,
    show_exploded = false,       // Exploded view for visualization
    explode_distance = 10        // Distance to separate in exploded view
) {
    // Boss (mounts to background)
    color("#8b7355")
    snap_fit_boss(
        shaft_diameter = shaft_diameter,
        boss_height = boss_height
    );

    // Pin with gear placeholder
    translate([0, 0, show_exploded ? boss_height + explode_distance : boss_height - 2])
    color("#d4a060")
    snap_fit_pin(
        shaft_diameter = shaft_diameter,
        shaft_length = shaft_length,
        head_diameter = shaft_diameter * 2,
        head_height = gear_thickness,
        snap_position = shaft_length - boss_height + 3
    );

    // Gear placeholder (for visualization)
    translate([0, 0, show_exploded ? boss_height + explode_distance + gear_thickness : boss_height - 2 + 2])
    color("#b8860b", 0.5)
    cylinder(d=20, h=gear_thickness);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           CALIBRATION TEST PIECE
//                    Print this first to verify tolerances
// ═══════════════════════════════════════════════════════════════════════════════════════

module snap_fit_calibration_test(
    shaft_diameter = 4
) {
    // Base plate
    difference() {
        cube([50, 30, 3]);

        // Test holes with different clearances
        translate([10, 15, -0.1]) {
            // Tight (interference fit)
            cylinder(d=shaft_diameter - FIT_INTERFERENCE, h=3.2);
        }

        translate([25, 15, -0.1]) {
            // Nominal (transition fit)
            cylinder(d=shaft_diameter, h=3.2);
        }

        translate([40, 15, -0.1]) {
            // Clearance (running fit)
            cylinder(d=shaft_diameter + FIT_CLEARANCE, h=3.2);
        }
    }

    // Labels (embossed)
    translate([10, 5, 3]) linear_extrude(0.5) text("TIGHT", size=3, halign="center");
    translate([25, 5, 3]) linear_extrude(0.5) text("NOM", size=3, halign="center");
    translate([40, 5, 3]) linear_extrude(0.5) text("CLEAR", size=3, halign="center");

    // Test pins
    translate([10, 25, 0]) {
        cylinder(d=shaft_diameter, h=10);
        translate([0, 0, 10]) snap_bulge(shaft_diameter, shaft_diameter + 0.4, 1.5);
    }

    translate([25, 25, 0]) {
        cylinder(d=shaft_diameter, h=10);
        translate([0, 0, 10]) snap_bulge(shaft_diameter, shaft_diameter + 0.5, 1.5);
    }

    translate([40, 25, 0]) {
        cylinder(d=shaft_diameter, h=10);
        translate([0, 0, 10]) snap_bulge(shaft_diameter, shaft_diameter + 0.6, 1.5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
//                           AXLE TYPE RECOMMENDATION TABLE
// ═══════════════════════════════════════════════════════════════════════════════════════
// Reference: Which gears should use snap-fit vs metal axles
//
// SNAP-FIT SUITABLE (Low stress, non-critical):
//   - Zone 1 Crank disc (5mm throw, low load)
//   - Zone 2 Crank discs (8mm throw, moderate load)
//   - Idler gears (6x 18T, non-load-bearing)
//   - Decorative/visual gears
//   - Low-speed gears (< 30 RPM)
//
// METAL AXLE REQUIRED (High stress, critical):
//   - Zone 3 Crank disc (12mm throw, articulation stress)
//   - Master Gear (60T, primary power transmission)
//   - Drive Gear (30T, camshaft connection)
//   - Camshaft (8mm, multiple load points)
//   - Any gear with radial loads or side thrust

// ═══════════════════════════════════════════════════════════════════════════════════════
//                                DEMO / TEST
// ═══════════════════════════════════════════════════════════════════════════════════════

// Uncomment to view individual components:

// Boss example
// snap_fit_boss(shaft_diameter=4, boss_height=10);

// Pin example
// snap_fit_pin(shaft_diameter=4, shaft_length=15);

// Complete assembly (normal view)
// snap_fit_gear_axle_assembly(show_exploded=false);

// Complete assembly (exploded view)
// snap_fit_gear_axle_assembly(show_exploded=true);

// Calibration test piece
// snap_fit_calibration_test();

// Default: Show exploded assembly for visualization
snap_fit_gear_axle_assembly(show_exploded=true, explode_distance=15);

echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("SNAP-FIT AXLE SYSTEM - Component Library");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
echo("");
echo("MODULES:");
echo("  snap_fit_boss()     - Receives pin, mounts to background");
echo("  snap_fit_pin()      - Attaches to gear, snaps into boss");
echo("  snap_fit_gear_axle_assembly() - Complete visualization");
echo("  snap_fit_calibration_test()   - Print first to verify tolerances");
echo("");
echo("TOLERANCE SETTINGS:");
echo("  FIT_INTERFERENCE:", FIT_INTERFERENCE, "mm (press fit)");
echo("  FIT_CLEARANCE:", FIT_CLEARANCE, "mm (running fit)");
echo("");
echo("PRINT ORIENTATION: Flat (XY plane), no supports needed");
echo("═══════════════════════════════════════════════════════════════════════════════════════");
