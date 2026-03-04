// --- VASHISHT PRINT-IN-PLACE KINETIC NODE (MANIFOLD FIXED) ---
// Fully mathematical 2D-extruded gears. No fractured booleans.

// ==========================================
// 1. CONFIGURATION & TOLERANCES
// ==========================================
$fn = 50; 
exploded_view = 25; // Set to 0 to assemble for printing!

// Clearances for 0.4mm nozzle
tol_xy = 0.25;  
tol_z  = 0.30;  

// Gear Math (Module = 1.5)
m = 1.5;
z_sun = 12;      
z_planet = 12;   
z_ring = 36;     // Equation: Ring = Sun + 2*Planet (36 = 12 + 24)

r_sun = (m * z_sun) / 2;          // 9mm
r_planet = (m * z_planet) / 2;    // 9mm
r_ring = (m * z_ring) / 2;        // 27mm
pitch_dist = r_sun + r_planet;    // 18mm

// Hardware Heights
gear_h = 10;
carrier_thick = 3.5;
shaft_diam = 8;
total_shaft_len = 84;

// ==========================================
// 2. MAIN ASSEMBLY
// ==========================================
translate([0,0,0]) {
    color("DarkSlateGray") translate([0,0, 35 + exploded_view*3]) ceiling_mount();
    color("Red") translate([0,0, 15 + exploded_view*2]) drive_shaft();
    color("Lime") translate([0,0, 15 + exploded_view*1]) gearbox(is_tier_1=true);
    color("DeepSkyBlue") translate([0,0, 0]) gearbox(is_tier_1=false);
    color("Gold") translate([0,0, -15 - exploded_view*1]) spool();
    color("White") translate([0,0, -32 - exploded_view*2]) lock_clip();
}

// ==========================================
// 3. MECHANICAL MODULES (SOLID & UNBREAKABLE)
// ==========================================

module ceiling_mount() {
    difference() {
        union() {
            cube([60, 60, 4], center=true);
            translate([0,0,-4]) cylinder(r=r_ring+4, h=8, center=true, $fn=8);
        }
        cylinder(r=shaft_diam/2 + tol_xy + 0.5, h=30, center=true);
        translate([0,0,2]) cylinder(r=shaft_diam/2 + 4, h=5, center=true);
        for(i=[0:90:360]) rotate([0,0,i]) translate([24,24,0]) cylinder(r=2, h=10, center=true);
    }
}

module drive_shaft() {
    difference() {
        union() {
            // Head
            translate([0,0, total_shaft_len/2 - 2]) cylinder(r=shaft_diam/2 + 3, h=4, center=true, $fn=6);
            // Main Spine
            cylinder(r=shaft_diam/2 - tol_xy, h=total_shaft_len, center=true);
            // Sun Gear (Fused)
            translate([0,0, 10]) linear_extrude(gear_h, center=true) spur_gear2D(r_sun, z_sun);
        }
        // FIXED GROOVE: Subtracts a hollow tube, NOT a solid cylinder
        translate([0,0, -total_shaft_len/2 + 4]) difference() {
            cylinder(r=shaft_diam, h=2.5, center=true); // Outer cut bound
            cylinder(r=shaft_diam/2 - 1.5, h=3, center=true); // Solid inner core remains
        }
    }
}

module gearbox(is_tier_1 = true) {
    total_h = gear_h + carrier_thick*2 + tol_z*2;
    
    // 1. THE RING GEAR HOUSING (Fused Outer Wall + Teeth)
    union() {
        difference() {
            // Faceted Outer Shell
            cylinder(r=r_ring + 4, h=total_h, center=true, $fn=8);
            // Hollow Core
            cylinder(r=r_ring + tol_xy, h=total_h + 2, center=true);
        }
        // External Drive Teeth
        for(i=[0:30:360]) rotate([0,0,i]) translate([r_ring+4, 0, 0]) cylinder(r=1.5, h=total_h, center=true);
        // Internal Gear Teeth (Mathematically embedded into the wall)
        linear_extrude(total_h, center=true) ring_gear2D_teeth(r_ring, z_ring);
    }

    // 2. THE PLANETS (With bored holes for axles)
    color("Silver")
    for(i=[0:120:360]) rotate([0,0,i]) translate([pitch_dist, 0, 0]) {
        difference() {
            linear_extrude(gear_h - tol_z*2, center=true) spur_gear2D(r_planet, z_planet);
            cylinder(r=3 + tol_xy, h=gear_h+2, center=true); // Clear axle hole
        }
    }

    // 3. THE CARRIER (Baseplate + Axles pointing UP)
    color("DimGray")
    translate([0,0, -gear_h/2 - carrier_thick/2 - tol_z]) {
        difference() {
            union() {
                cylinder(r=r_ring - 1, h=carrier_thick, center=true);
                // The Integrated Axles
                for(i=[0:120:360]) rotate([0,0,i]) translate([pitch_dist, 0, carrier_thick/2]) 
                    cylinder(r=3, h=gear_h + tol_z, center=false);
                
                // Outputs
                if(is_tier_1) {
                    translate([0,0, -carrier_thick/2 - gear_h/2 - tol_z]) 
                        linear_extrude(gear_h, center=true) spur_gear2D(r_sun, z_sun);
                } else {
                    translate([0,0, -carrier_thick/2 - 2.5]) 
                        cylinder(r=shaft_diam, h=5, center=true, $fn=6); // Hex output
                }
            }
            cylinder(r=shaft_diam/2 + tol_xy + 0.5, h=50, center=true); // Center clearance
        }
    }
}

module spool() {
    difference() {
        union() {
            cylinder(r=12, h=16, center=true);
            translate([0,0, 7.5]) cylinder(r=r_ring-2, h=2, center=true);
            translate([0,0,-7.5]) cylinder(r=r_ring-2, h=2, center=true);
        }
        translate([0,0, 8]) cylinder(r=shaft_diam + tol_xy, h=7, center=true, $fn=6); // Hex socket
        cylinder(r=shaft_diam/2 + tol_xy + 0.5, h=30, center=true);
        rotate([90,0,0]) cylinder(r=1.5, h=40, center=true);
    }
}

module lock_clip() {
    difference() {
        cylinder(r=shaft_diam/2 + 5, h=3, center=true, $fn=6); // Robust hex shape
        cylinder(r=shaft_diam/2 - 1.2, h=4, center=true); // Tighter inner grab
        translate([shaft_diam, 0, 0]) cube([shaft_diam*2, shaft_diam-1, 5], center=true); // Flex slit
    }
}

// ==========================================
// 4. 2D GEAR GENERATORS (Guarantees perfect manifolds)
// ==========================================

module spur_gear2D(pitch_r, teeth) {
    tooth_w = (PI * pitch_r * 2) / teeth / 2;
    tooth_d = 2.2 * m;
    union() {
        circle(r=pitch_r - tooth_d/2);
        for(i=[0:360/teeth:360]) rotate([0,0,i]) translate([pitch_r, 0, 0])
            polygon(points=[
                [-tooth_d/2, -tooth_w/2],
                [-tooth_d/2, tooth_w/2],
                [tooth_d/2, tooth_w*0.3],
                [tooth_d/2, -tooth_w*0.3]
            ]);
    }
}

module ring_gear2D_teeth(pitch_r, teeth) {
    tooth_w = (PI * pitch_r * 2) / teeth / 2;
    tooth_d = 2.2 * m;
    for(i=[0:360/teeth:360]) rotate([0,0,i]) translate([pitch_r, 0])
        polygon(points=[
            [3, -tooth_w/2 - tol_xy], // Embeds deeply into the housing wall
            [3, tooth_w/2 + tol_xy],
            [-tooth_d/2, tooth_w*0.3 + tol_xy],
            [-tooth_d/2, -tooth_w*0.3 - tol_xy]
        ]);
}