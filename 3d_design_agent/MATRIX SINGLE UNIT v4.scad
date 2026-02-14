// ==================================================
// V87: CENTER-RELATIVE GEOMETRY (AUTO-SYMMETRY)
// ==================================================
// 1. CENTER PULLEYS: Defined by FIXED_CENTER_X.
// 2. WALLS: Defined as Extensions from that Center.
//    (Set L and R equal for perfect symmetry).
// 3. SLIDERS: Defined relative to SLIDER_CENTER_X.
// ==================================================

$fn = 60; 

// ==================================================
// 1. GLOBAL PITCH
// ==================================================
FIXED_PULLEY_PITCH  = 27.0; 
SLIDER_PULLEY_PITCH = 27.0; 


// ==================================================
// 2. CHANNEL CONFIGURATION
// ==================================================

/* [Channel 1 (Top)] */
CH1_FIXED_COUNT    = 3;     // [0:1:20]
CH1_SLIDER_COUNT   = 3;     // [0:1:20]
// Position of the Pulley Center in X
CH1_FIXED_CENTER_X = -51;   // [-500:1:500]
CH1_SLIDER_CENTER_X= -44;   // [-500:1:500]
// Wall Extension from Center (Set Equal for Symmetry)
CH1_WALL_EXT_L     = 51;    // [10:1:300]
CH1_WALL_EXT_R     = 51;    // [10:1:300]
// Plate Extension from Slider Center
CH1_PLATE_EXT_L    = 55;    // [10:1:300]
CH1_PLATE_EXT_R    = 55;    // [10:1:300]

/* [Channel 2] */
CH2_FIXED_COUNT    = 4; 
CH2_SLIDER_COUNT   = 4; 
CH2_FIXED_CENTER_X = -51; 
CH2_SLIDER_CENTER_X= -44; 
CH2_WALL_EXT_L     = 55; 
CH2_WALL_EXT_R     = 55; 
CH2_PLATE_EXT_L    = 60; 
CH2_PLATE_EXT_R    = 60; 

/* [Channel 3 (Middle)] */
CH3_FIXED_COUNT    = 5; 
CH3_SLIDER_COUNT   = 5; 
CH3_FIXED_CENTER_X = -52; 
CH3_SLIDER_CENTER_X= -44; 
CH3_WALL_EXT_L     = 67; 
CH3_WALL_EXT_R     = 67; 
CH3_PLATE_EXT_L    = 70; 
CH3_PLATE_EXT_R    = 70; 

/* [Channel 4] */
CH4_FIXED_COUNT    = 4; 
CH4_SLIDER_COUNT   = 4; 
CH4_FIXED_CENTER_X = -53; 
CH4_SLIDER_CENTER_X= -44; 
CH4_WALL_EXT_L     = 52.5; 
CH4_WALL_EXT_R     = 52.5; 
CH4_PLATE_EXT_L    = 60; 
CH4_PLATE_EXT_R    = 60; 

/* [Channel 5 (Bottom)] */
CH5_FIXED_COUNT    = 3; 
CH5_SLIDER_COUNT   = 3; 
CH5_FIXED_CENTER_X = -53; 
CH5_SLIDER_CENTER_X= -44; 
CH5_WALL_EXT_L     = 49; 
CH5_WALL_EXT_R     = 49; 
CH5_PLATE_EXT_L    = 55; 
CH5_PLATE_EXT_R    = 55; 


// ==================================================
// 3. GLOBAL SETTINGS
// ==================================================

/* [Stack Settings] */
STACK_OFFSET = 22.0; 

/* [Visibility] */
SHOW_HOUSING_WALLS  = true;
SHOW_SLIDER_PLATES  = true;
SHOW_FIXED_PULLEYS  = true;
SHOW_SLIDER_PULLEYS = true;

/* [Rail Geometry] */
GUIDE_RAIL_HEIGHT = 4.0;
GUIDE_RAIL_DEPTH  = 1.5; 
GUIDE_TOLERANCE   = 0.4; 

/* [Hidden] */
HOUSING_GAP = 19.0;
SLIDER_GAP  = 8.0;
FIXED_PULLEY_WIDTH  = 18.0;
SLIDER_PULLEY_WIDTH = 7.0;
AXLE_DIA     = 5.0;
HOUSING_H    = 85.0;
WALL_T       = 3.0;  

// Arrays
FIXED_COUNTS   = [CH1_FIXED_COUNT, CH2_FIXED_COUNT, CH3_FIXED_COUNT, CH4_FIXED_COUNT, CH5_FIXED_COUNT];
SLIDER_COUNTS  = [CH1_SLIDER_COUNT, CH2_SLIDER_COUNT, CH3_SLIDER_COUNT, CH4_SLIDER_COUNT, CH5_SLIDER_COUNT];

FIXED_CENTERS  = [CH1_FIXED_CENTER_X, CH2_FIXED_CENTER_X, CH3_FIXED_CENTER_X, CH4_FIXED_CENTER_X, CH5_FIXED_CENTER_X];
SLIDER_CENTERS = [CH1_SLIDER_CENTER_X, CH2_SLIDER_CENTER_X, CH3_SLIDER_CENTER_X, CH4_SLIDER_CENTER_X, CH5_SLIDER_CENTER_X];

WALL_EXT_L     = [CH1_WALL_EXT_L, CH2_WALL_EXT_L, CH3_WALL_EXT_L, CH4_WALL_EXT_L, CH5_WALL_EXT_L];
WALL_EXT_R     = [CH1_WALL_EXT_R, CH2_WALL_EXT_R, CH3_WALL_EXT_R, CH4_WALL_EXT_R, CH5_WALL_EXT_R];
PLATE_EXT_L    = [CH1_PLATE_EXT_L, CH2_PLATE_EXT_L, CH3_PLATE_EXT_L, CH4_PLATE_EXT_L, CH5_PLATE_EXT_L];
PLATE_EXT_R    = [CH1_PLATE_EXT_R, CH2_PLATE_EXT_R, CH3_PLATE_EXT_R, CH4_PLATE_EXT_R, CH5_PLATE_EXT_R];


// ==================================================
// 4. MAIN RENDER
// ==================================================

anim_val = sin($t * 360) * 30;

generate_stack(anim_val);

module generate_stack(slide_pos) {
    rotate([90, 0, 0]) {
        for (i = [0 : 4]) {
            
            f_count    = FIXED_COUNTS[i];
            s_count    = SLIDER_COUNTS[i];
            
            // Centers
            f_cx       = FIXED_CENTERS[i];
            s_cx       = SLIDER_CENTERS[i];
            
            // Extensions
            w_ext_l    = WALL_EXT_L[i];
            w_ext_r    = WALL_EXT_R[i];
            p_ext_l    = PLATE_EXT_L[i];
            p_ext_r    = PLATE_EXT_R[i];
            
            // Stack Position
            total_height = 4 * STACK_OFFSET;
            y_pos = (i * STACK_OFFSET) - (total_height / 2);
            
            translate([0, 0, y_pos])
                generate_unit_centered(slide_pos, f_count, s_count, f_cx, s_cx, w_ext_l, w_ext_r, p_ext_l, p_ext_r);
        }
    }
}

module generate_unit_centered(slide_pos, f_count, s_count, f_cx, s_cx, w_l, w_r, p_l, p_r) {
    
    // 1. Walls (Centered on Fixed Center)
    if (SHOW_HOUSING_WALLS) {
        translate([f_cx, 0, -(HOUSING_GAP/2 + WALL_T)]) 
            wall_centered(w_l, w_r); 
            
        translate([f_cx, 0, HOUSING_GAP/2]) 
            rotate([180,0,0]) 
            wall_centered(w_l, w_r); 
    }
    
    // 2. Fixed Pulleys (At Fixed Center)
    translate([f_cx, 31, 0]) 
        fixed_pulley_row(f_count);
    translate([f_cx, -31, 0]) 
        fixed_pulley_row(f_count);

    // 3. Slider Assembly (Centered on Slider Center)
    // Moves with Animation
    translate([slide_pos + s_cx, 0, 0])
        slider_assembly_centered(s_count, p_l, p_r);
}


// ==================================================
// 5. COMPONENT MODULES
// ==================================================

module wall_centered(ext_l, ext_r) {
    total_len = ext_l + ext_r;
    
    difference() {
        color([0.6, 0.6, 1.0, 1.0]) 
        union() {
            // Draw wall relative to 0 (which is now the Pulley Center)
            // Extends from -Left to +Right
            translate([-ext_l, -HOUSING_H/2, 0])
                cube([total_len, HOUSING_H, WALL_T]);
            
            // Guide Rail
            translate([0, 0, WALL_T]) 
                translate([-ext_l, -GUIDE_RAIL_HEIGHT/2, 0])
                    cube([total_len, GUIDE_RAIL_HEIGHT, GUIDE_RAIL_DEPTH]);
        }
        
        // Holes (Also centered on 0)
        // We iterate out from center
        steps_l = floor(ext_l / FIXED_PULLEY_PITCH);
        steps_r = floor(ext_r / FIXED_PULLEY_PITCH);
        
        // Center Hole (Always at 0)
        translate([0, 31, -1]) cylinder(d=8, h=10);
        translate([0, -31, -1]) cylinder(d=8, h=10);

        // Right Side Holes
        for (i = [1 : steps_r]) {
            base_pos = i * FIXED_PULLEY_PITCH; // Pitch multiples from center
            // Pitch 27 -> Holes at 27, 54, etc.
            // Or should they be BETWEEN pulleys?
            // "Ensure center-most pulley is in center point".
            // Standard: Holes align with pulleys for axle access.
            if (base_pos < ext_r - 5) {
                translate([base_pos, 31, -1]) cylinder(d=8, h=10);
                translate([base_pos, -31, -1]) cylinder(d=8, h=10);
            }
        }
        // Left Side Holes
        for (i = [1 : steps_l]) {
            base_pos = -i * FIXED_PULLEY_PITCH;
            if (abs(base_pos) < ext_l - 5) {
                translate([base_pos, 31, -1]) cylinder(d=8, h=10);
                translate([base_pos, -31, -1]) cylinder(d=8, h=10);
            }
        }
    }
}

module slider_assembly_centered(count, ext_l, ext_r) {
    total_len = ext_l + ext_r;
    
    if (SHOW_SLIDER_PLATES) {
        // BOTTOM PLATE
        color([0.9, 0.4, 0.4, 1.0])
        difference() {
            translate([-ext_l, -7.5, -(SLIDER_GAP/2 + 5.0)])
                cube([total_len, 15, 5.0]);
            
            // SLOT
            slot_h = GUIDE_RAIL_HEIGHT + (GUIDE_TOLERANCE * 2);
            slot_d = GUIDE_RAIL_DEPTH + 0.5;
            translate([-ext_l - 1, -slot_h/2, -(SLIDER_GAP/2 + 5.0) - 0.1])
                cube([total_len + 2, slot_h, slot_d]);
        }
    
        // TOP PLATE
        color([0.9, 0.4, 0.4, 1.0])
        difference() {
            translate([-ext_l, -7.5, SLIDER_GAP/2]) 
                cube([total_len, 15, 5.0]);
            
            // SLOT
            slot_h = GUIDE_RAIL_HEIGHT + (GUIDE_TOLERANCE * 2);
            slot_d = GUIDE_RAIL_DEPTH + 0.5; 
            translate([-ext_l - 1, -slot_h/2, SLIDER_GAP/2 + 5.0 - slot_d + 0.1])
                cube([total_len + 2, slot_h, slot_d]);
        }
    }
    
    if (SHOW_SLIDER_PULLEYS) {
        // Pulleys are centered at 0 (relative to the slider group)
        slider_pulley_row(count);
    }
}

module fixed_pulley_row(count) {
    axle_L = HOUSING_GAP + (WALL_T * 2) + 0.2; 
    start_x = -((count - 1) / 2) * FIXED_PULLEY_PITCH;
    
    for (i = [0 : count - 1]) {
        pos = start_x + (i * FIXED_PULLEY_PITCH);
        translate([pos, 0, 0]) {
            color([0.5, 0.5, 0.5]) 
            union() {
                translate([0,0, -axle_L/2]) cylinder(d=AXLE_DIA, h=axle_L);
                cylinder(d=AXLE_DIA + 1.5, h=2.0, center=true);
            }
            if (SHOW_FIXED_PULLEYS) {
                 color([0.95, 0.95, 0.95]) 
                 translate([0,0, -FIXED_PULLEY_WIDTH/2]) 
                 difference(){
                    cylinder(d=13.0, h=FIXED_PULLEY_WIDTH); 
                    translate([0,0,-1]) cylinder(d=AXLE_DIA + 0.6, h=FIXED_PULLEY_WIDTH+2);
                    translate([0, 0, FIXED_PULLEY_WIDTH/2]) cylinder(d=AXLE_DIA + 2.0, h=2.5, center=true);
                 }
            }
        }
    }
}

module slider_pulley_row(count) {
    axle_L = SLIDER_GAP; 
    start_x = -((count - 1) / 2) * SLIDER_PULLEY_PITCH;
    
    for (i = [0 : count - 1]) {
        pos = start_x + (i * SLIDER_PULLEY_PITCH);
        translate([pos, 0, 0]) {
            color([0.5, 0.5, 0.5]) 
            union() {
                translate([0,0, -axle_L/2]) cylinder(d=AXLE_DIA, h=axle_L);
                cylinder(d=AXLE_DIA + 1.5, h=2.0, center=true);
            }
            if (SHOW_SLIDER_PULLEYS) {
                color([0.95, 0.95, 0.95]) 
                translate([0,0, -SLIDER_PULLEY_WIDTH/2]) 
                difference(){
                    cylinder(d=10.0, h=SLIDER_PULLEY_WIDTH); 
                    translate([0,0,-1]) cylinder(d=AXLE_DIA + 0.6, h=SLIDER_PULLEY_WIDTH+2);
                    translate([0, 0, SLIDER_PULLEY_WIDTH/2]) cylinder(d=AXLE_DIA + 2.0, h=2.5, center=true);
                }
            }
        }
    }
}