// ==================================================
// V27: EVEN-NUMBERED PARAMETRIC MATRIX (4, 6, 8)
// ==================================================
// 1. Optimized for EVEN counts (creates natural center gap).
// 2. Automatically scales housing length.
// 3. Maintains 120-degree Hexagonal Stacking geometry.
// ==================================================

$fn = 60; 

// ==================================================
// 1. CONFIGURATION
// ==================================================

// --- PARAMETRIC CONTROL ---
// Change this to 4, 6, or 8 as required.
// Even numbers create the necessary central drop-shaft.
NUM_PULLEYS_PER_ROW  = 6;  

// --- ROTATION & VIEW ---
// Standard upright unit for stacking
ROTATE_X = 90; 
ROTATE_Y = 0;
ROTATE_Z = 0;

// --- DIMENSIONS ---
PULLEY_PITCH         = 25.0;   
FIXED_CENTER_GAP     = 50.0;   // The clear zone for the drop line

// --- COMPONENT SPECS ---
HOUSING_HEIGHT       = 85;     
WALL_THICKNESS       = 5.0;    
WALL_HOLE_DIA        = 8.0;    
HOUSING_INTERNAL_WIDTH = 20.0; 
SLIDER_INTERNAL_WIDTH  = 9.0;
SLIDER_HEIGHT        = 15;     
SLIDER_WALL          = 5.0;    

// --- MECHANISM ---
FIXED_PULLEY_OD      = 13.0;   
FIXED_PULLEY_WIDTH   = 19.0;
SLIDER_PULLEY_OD     = 10.0;   
SLIDER_PULLEY_WIDTH  = 8.0;    
FIXED_AXLE_DIA       = 5.0;    
SLIDER_AXLE_DIA      = 4.0;    

// --- CUTOUT SPECS ---
CUTOUT_RECT_WIDTH    = 80.0;   
CUTOUT_RECT_HEIGHT   = 40.0;   
CUTOUT_CORNER_RADIUS = 8.0;    

// --- GUIDE ROLLERS ---
GUIDE_POS_Y          = 13.0;   
GUIDE_AXLE_DIA       = 5.0;     
GUIDE_AXLE_LENGTH    = 5.5;  
GUIDE_ROLLER_OD      = 10.0;
GUIDE_ROLLER_THICKNESS = 5.0;

// --- AUTO-CALCULATED LENGTHS ---
// Logic: (N/2 - 0.5) * 2 * Pitch + Gap
// This ensures the pulleys fit regardless of count (4, 6, 8...)
CALC_PULLEY_SPAN = ((NUM_PULLEYS_PER_ROW/2 - 0.5) * 2 * PULLEY_PITCH) + (FIXED_CENTER_GAP - PULLEY_PITCH);

// Housing grows with pulleys but has a minimum size of 160mm
HOUSING_LEN = max(160, CALC_PULLEY_SPAN + 70); 
SLIDER_LEN  = HOUSING_LEN + 30; 

// Guide rollers move out as the unit gets longer
GUIDE_POS_X = (HOUSING_LEN / 2) - 25; 


// ==================================================
// 2. MAIN RENDER LOOP
// ==================================================

anim_x = sin($t * 360) * 40;

rotate([ROTATE_X, ROTATE_Y, ROTATE_Z])
    generate_unit();


// ==================================================
// 3. GENERATOR MODULES
// ==================================================

module generate_unit() {
    
    // 1. BOTTOM WALL (Studs UP)
    complex_wall_with_holes(true, false);
    
    // 2. TOP WALL (Studs DOWN)
    translate([0, 0, HOUSING_INTERNAL_WIDTH + WALL_THICKNESS])
        complex_wall_with_holes(false, true);
    
    // 3. INTERNALS
    translate([0, 0, WALL_THICKNESS]) {
        
        // Fixed Pulleys (Top Row Y=31)
        translate([0, 31, 0]) 
            generate_even_row(NUM_PULLEYS_PER_ROW, HOUSING_INTERNAL_WIDTH, FIXED_PULLEY_WIDTH, FIXED_PULLEY_OD, FIXED_AXLE_DIA);

        // Fixed Pulleys (Bottom Row Y=-31)
        translate([0, -31, 0]) 
            generate_even_row(NUM_PULLEYS_PER_ROW, HOUSING_INTERNAL_WIDTH, FIXED_PULLEY_WIDTH, FIXED_PULLEY_OD, FIXED_AXLE_DIA);
            
        // Floating Guide Rollers
        generate_floating_rollers();
        
        // Moving Slider Assembly
        slider_total_ext_width = SLIDER_INTERNAL_WIDTH + (2 * SLIDER_WALL);
        slider_z_offset = (HOUSING_INTERNAL_WIDTH - slider_total_ext_width) / 2;
        
        translate([anim_x, 0, slider_z_offset])
            slider_assembly();
    }
}

module complex_wall_with_holes(studs_up, studs_down) {
    color([0.9, 0.9, 1, 0.3]) 
    difference() {
        // Parametric Base Plate
        translate([-HOUSING_LEN/2, -HOUSING_HEIGHT/2, 0])
            cube([HOUSING_LEN, HOUSING_HEIGHT, WALL_THICKNESS]);
        
        // --- CENTERED ROUNDED RECTANGLE CUTOUT ---
        if (CUTOUT_RECT_WIDTH > 0 && CUTOUT_RECT_HEIGHT > 0) {
            cx = CUTOUT_RECT_WIDTH/2 - CUTOUT_CORNER_RADIUS;
            cy = CUTOUT_RECT_HEIGHT/2 - CUTOUT_CORNER_RADIUS;

            translate([0,0,-1]) 
            linear_extrude(WALL_THICKNESS + 2) 
                hull() {
                    translate([cx, cy]) circle(r=CUTOUT_CORNER_RADIUS);
                    translate([-cx, cy]) circle(r=CUTOUT_CORNER_RADIUS);
                    translate([cx, -cy]) circle(r=CUTOUT_CORNER_RADIUS);
                    translate([-cx, -cy]) circle(r=CUTOUT_CORNER_RADIUS);
                }
        }

        // --- PARAMETRIC CHEESE HOLES ---
        generate_auto_hole_pattern(31);
        generate_auto_hole_pattern(-31);
    }
    
    // GUIDE STUDS
    locs = [ [GUIDE_POS_X, GUIDE_POS_Y], [-GUIDE_POS_X, GUIDE_POS_Y], 
             [GUIDE_POS_X, -GUIDE_POS_Y], [-GUIDE_POS_X, -GUIDE_POS_Y] ];
             
    for(pos = locs) {
        translate([pos.x, pos.y, 0]) {
            if (studs_up) {
                translate([0,0, WALL_THICKNESS])
                    mushroom_stud_manual(GUIDE_AXLE_LENGTH, GUIDE_AXLE_DIA, 1); 
            }
            if (studs_down) {
                mushroom_stud_manual(GUIDE_AXLE_LENGTH, GUIDE_AXLE_DIA, -1); 
            }
        }
    }
}

module generate_auto_hole_pattern(y_pos) {
    start_x = 50; 
    end_x = (HOUSING_LEN / 2) - 10;
    
    if (end_x > start_x) {
        steps = floor((end_x - start_x) / 20); 
        if (steps >= 0) {
            for (i = [0 : steps]) {
                offset = start_x + (i * 20);
                translate([offset, y_pos, -1]) cylinder(d=WALL_HOLE_DIA, h=WALL_THICKNESS+2);
                translate([-offset, y_pos, -1]) cylinder(d=WALL_HOLE_DIA, h=WALL_THICKNESS+2);
            }
        }
    }
}

module slider_assembly() {
    slider_plate();
    translate([0,0, SLIDER_INTERNAL_WIDTH + SLIDER_WALL]) slider_plate();
    translate([0,0, SLIDER_WALL]) {
        generate_even_row(NUM_PULLEYS_PER_ROW, SLIDER_INTERNAL_WIDTH, SLIDER_PULLEY_WIDTH, SLIDER_PULLEY_OD, SLIDER_AXLE_DIA);
    }
}

module slider_plate() {
    color([0.2, 0.5, 0.9, 0.5])
    translate([-SLIDER_LEN/2, -SLIDER_HEIGHT/2, 0])
        cube([SLIDER_LEN, SLIDER_HEIGHT, SLIDER_WALL]);
}

// ==================================================
// EVEN ROW GENERATOR (GAP IN MIDDLE)
// ==================================================
module generate_even_row(count, h, p_width, p_od, p_axle) {
    
    for(i = [0 : count-1]) {
        is_right_side = (i >= count/2);
        pos_index = (i - (count-1)/2);
        
        base_x = pos_index * PULLEY_PITCH;
        shift = (FIXED_CENTER_GAP - PULLEY_PITCH) / 2;
        final_x = (is_right_side) ? (base_x + shift) : (base_x - shift);
        
        translate([final_x, 0, 0]) 
            captive_smooth_pulley(h, p_width, p_od, p_axle);
    }
}

module generate_floating_rollers() {
    locs = [ [GUIDE_POS_X, GUIDE_POS_Y], [-GUIDE_POS_X, GUIDE_POS_Y], 
             [GUIDE_POS_X, -GUIDE_POS_Y], [-GUIDE_POS_X, -GUIDE_POS_Y] ];
     
    z_bottom = 0.3; 
    z_top = HOUSING_INTERNAL_WIDTH - 0.3 - GUIDE_ROLLER_THICKNESS;

    for(pos = locs) {
        translate([pos.x, pos.y, 0]) {
            translate([0,0, z_bottom])
                smooth_roller_body(GUIDE_ROLLER_THICKNESS, GUIDE_ROLLER_OD, GUIDE_AXLE_DIA);
            translate([0,0, z_top])
                smooth_roller_body(GUIDE_ROLLER_THICKNESS, GUIDE_ROLLER_OD, GUIDE_AXLE_DIA);
        }
    }
}

// ==================================================
// PARTS
// ==================================================

module mushroom_stud_manual(h_total, axle, dir) {
    color([0.6,0.6,0.6])
    if (dir == 1) {
        union() {
            cylinder(d=axle, h=(h_total - 1.5));
            translate([0,0, (h_total - 1.5)])
                cylinder(d1=axle, d2=axle+2.0, h=1.5);
        }
    } else {
        rotate([180, 0, 0])
        union() {
            cylinder(d=axle, h=(h_total - 1.5));
            translate([0,0, (h_total - 1.5)])
                cylinder(d1=axle, d2=axle+2.0, h=1.5);
        }
    }
}

module captive_smooth_pulley(h, w, od, axle) {
    color([0.6,0.6,0.6]) 
    union() {
        cylinder(d=axle, h=h);
        translate([0,0,h/2]) cylinder(d=axle+1.5, h=2, center=true, $fn=6); 
    }
    color([0.95, 0.95, 0.95])
    translate([0, 0, (h - w)/2])
    difference() {
        cylinder(d=od, h=w); 
        translate([0,0,-1]) cylinder(d=axle + 0.6, h=w+2);
        translate([0,0,w/2]) cylinder(d=axle+1.5 + 0.6, h=2 + 0.6, center=true);
    }
}

module smooth_roller_body(w, od, axle) {
    color([0.95, 0.95, 0.95])
    difference() {
        cylinder(d=od, h=w);
        union() {
            cylinder(d=axle + 0.6, h=w+1); 
            translate([0,0, w-1.5]) 
                cylinder(d1=axle+0.6, d2=axle+2.0+0.6, h=2.0);
             translate([0,0, -0.1]) 
                cylinder(d2=axle+0.6, d1=axle+2.0+0.6, h=1.6);
        }
    }
}