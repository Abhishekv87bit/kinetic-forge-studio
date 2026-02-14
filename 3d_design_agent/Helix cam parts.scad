// =========================================================
// ECCENTRIC HELIX - CORRECTED CIRCULAR DESIGN
// =========================================================

/* [Render Selection] */
part = "hub"; // [hub:Eccentric Hub, rib:Gravity Rib, plate:Rectangular End Plate]

/* [Engineering Dimensions] */
// BEARING: 6810 (50mm ID x 65mm OD x 7mm Width)
bearing_ID = 50.0;
bearing_OD = 65.0;
bearing_width = 7.0;

// ECCENTRICITY: How far is the Bolt Axis from the Bearing Center?
// This creates the "Cam" motion. 
// Max possible for 50mm hub approx 15mm before hitting edge.
eccentric_offset = 12.0; 

// HELIX TWIST: Angle per slice (360 / 30 cams = 12 degrees)
twist_angle = 12.0;

// BOLT PATTERN: The "Shaft" connecting the stack
bolt_circle_dia = 20.0;
bolt_hole_dia = 4.2; // M4 Loose Fit
nut_trap_dia = 8.0;  // M4 Hex Nut
nut_trap_depth = 3.5;

/* [Rectangular End Plate] */
plate_length = 80.0; // Pivot to Hub Center
plate_width = 40.0;
plate_thick = 6.0;
pivot_hole = 8.0;    // Motor Shaft

/* [Rib Dimensions] */
rib_length = 60.0;
rib_thick = 6.0;

// =========================================================
$fn = 100;

if (part == "hub") {
    eccentric_circular_hub();
} else if (part == "rib") {
    gravity_rib();
} else if (part == "plate") {
    rectangular_end_plate();
}

// ---------------------------------------------------------
// 1. THE ECCENTRIC HUB (Circular, Offset Holes)
// ---------------------------------------------------------
module eccentric_circular_hub() {
    difference() {
        // A. The Main Body (Bearing Seat)
        // Center is shifted by 'eccentric_offset' relative to rotation axis (0,0)
        translate([eccentric_offset, 0, 0])
            cylinder(h = bearing_width, d = bearing_ID - 0.1); // Tight fit for bearing

        // B. The Bolt Pattern (Axis of Rotation at 0,0)
        
        // Front Face: Through Holes
        for (i = [0 : 120 : 240]) {
            rotate([0, 0, i])
            translate([bolt_circle_dia/2, 0, -1]) {
                cylinder(h = bearing_width + 2, d = bolt_hole_dia);
                // Counterbore
                translate([0,0, bearing_width - 3])
                    cylinder(h = 4, d = bolt_hole_dia + 3.5);
            }
        }
        
        // Back Face: Nut Traps (Rotated by twist_angle!)
        // This forces the next hub to twist when aligned
        for (i = [0 : 120 : 240]) {
            rotate([0, 0, i + twist_angle]) 
            translate([bolt_circle_dia/2, 0, -0.1])
                cylinder(h = nut_trap_depth, d = nut_trap_dia, $fn=6);
        }
        
        // C. Center Hole (Optional, for alignment rod)
        translate([0,0,-1]) cylinder(h=bearing_width+2, d=5);
    }
}

// ---------------------------------------------------------
// 2. THE GRAVITY RIB (Fits over Bearing)
// ---------------------------------------------------------
module gravity_rib() {
    difference() {
        union() {
            // Ring
            cylinder(h = rib_thick, d = bearing_OD + 10);
            
            // Rib/Tail
            translate([-rib_thick/2, 0, 0])
                cube([rib_thick, bearing_OD/2 + rib_length, rib_thick]);
        }
        
        // Bearing Hole (Clearance)
        translate([0,0,-1])
            cylinder(h = rib_thick+2, d = bearing_OD + 0.5); // Slide fit
            
        // String Eyelet
        translate([0, bearing_OD/2 + rib_length - 5, -1])
            cylinder(h = rib_thick+2, d = 3);
    }
}

// ---------------------------------------------------------
// 3. THE RECTANGULAR END PLATE (Crank Arm)
// ---------------------------------------------------------
module rectangular_end_plate() {
    difference() {
        // Rectangular Body
        // Center the pivot at (0,0)
        translate([-plate_width/2, -plate_width/2, 0])
            cube([plate_length + plate_width, plate_width, plate_thick]);
            
        // Pivot Hole (Motor/Frame Connection) at (0,0)
        translate([0, 0, -1])
            cylinder(h = plate_thick+2, d = pivot_hole);
            
        // Hub Connection Holes (At 'plate_length' distance)
        translate([plate_length, 0, 0]) {
            // Center Hole
            translate([0,0,-1]) cylinder(h=plate_thick+2, d=5);
            
            // Bolt Pattern (Matches Hub)
            for (i = [0 : 120 : 240]) {
                rotate([0, 0, i])
                translate([bolt_circle_dia/2, 0, -1])
                    cylinder(h = plate_thick+2, d = bolt_hole_dia);
            }
        }
    }
}