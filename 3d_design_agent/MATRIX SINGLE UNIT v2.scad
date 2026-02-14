// ==================================================
// V57: INDEPENDENT SLIDER PULLEY CONTROL
// ==================================================
// 1. SLIDER_PULLEY_PITCH: Spacing between slider pulleys.
// 2. SLIDER_SPLIT_ADDITION: Central gap for slider set.
// 3. SLIDER_X_OFFSET: Global shift for alignment.
// 4. Fixed Pulleys remain on their own separate grid.
// ==================================================

$fn = 60; 

// ==================================================
// 1. PARAMETERS
// ==================================================

// --- VISIBILITY ---
SHOW_HOUSING_WALLS = true;
SHOW_SLIDER_PLATES = true;

// --- FIXED PULLEY CONFIG (BLUE WALLS) ---
FIXED_PULLEY_SPLIT_ADDITION = 55.0; // Central Gap
FIXED_PULLEY_PITCH          = 27.0; // Spacing between fixed pulleys

// --- SLIDER PULLEY CONFIG (RED PLATES) ---
// Distance between pulleys WITHIN the set of 3
SLIDER_PULLEY_PITCH         = 27.0; 

// Central Gap between the Left Set and Right Set
SLIDER_SPLIT_ADDITION       = 27.0; 

// Global Shift for Slider Pulleys (Left - / Right +)
SLIDER_X_OFFSET             = 0.0;


// --- DIMENSIONS & GAPS ---
HOUSING_GAP = 19.0;
SLIDER_GAP  = 8.0;

// --- WIDTHS ---
FIXED_PULLEY_WIDTH  = 18.0;
SLIDER_PULLEY_WIDTH = 7.0;
ROLLER_WIDTH        = 5.0;

// --- GEOMETRY ---
MANUAL_HOUSING_LENGTH = 200.0;
NUM_PULLEYS  = 6;
AXLE_DIA     = 5.0;

// Slider Extensions
SLIDER_EXT_L = 10.0;
SLIDER_EXT_R = 10.0;

// Dimensions
HOUSING_H = 85.0;
WALL_T    = 6.0;

// ==================================================
// 2. MAIN RENDER
// ==================================================

anim_val = sin($t * 360) * 30;

rotate([90, 0, 0])
    generate_v57_unit(anim_val);


// ==================================================
// 3. UNIT GENERATOR
// ==================================================

module generate_v57_unit(slide_pos) {
    
    // Geometry Calcs
    h_len = MANUAL_HOUSING_LENGTH + FIXED_PULLEY_SPLIT_ADDITION;
    s_len_total = h_len + SLIDER_EXT_L + SLIDER_EXT_R;
    s_center_shift = (SLIDER_EXT_R - SLIDER_EXT_L) / 2;
    g_pos_x = (h_len / 2) - 15;

    // --- RENDER ---
    
    // 1. Walls (Blue)
    if (SHOW_HOUSING_WALLS) {
        translate([0, 0, -(HOUSING_GAP/2 + WALL_T)]) 
            wall_body_split(h_len, g_pos_x, true, false); 
            
        translate([0, 0, HOUSING_GAP/2]) 
            wall_body_split(h_len, g_pos_x, false, true); 
    }
    
    // 2. Fixed Pulleys
    translate([0, 31, 0]) 
        fixed_pulley_row_split(NUM_PULLEYS);
    translate([0, -31, 0]) 
        fixed_pulley_row_split(NUM_PULLEYS);

    // 3. Rollers
    floating_rollers(g_pos_x);
    
    // 4. Slider Assembly
    translate([slide_pos + s_center_shift, 0, 0])
        slider_assembly_independent(NUM_PULLEYS, s_len_total);
}


// --- COMPONENT MODULES ---

module wall_body_split(w_len, gx, up, down) {
    color([0.6, 0.6, 1.0, 1.0]) 
    difference() {
        translate([-w_len/2, -HOUSING_H/2, 0])
            cube([w_len, HOUSING_H, WALL_T]);
        
        if (w_len > 100) {
            translate([-40, -20, -1])
                cube([80, 40, 7]);
        }
        
        // Holes follow FIXED pitch
        split_off = FIXED_PULLEY_SPLIT_ADDITION / 2;
        steps = 4; 
        
        for (i = [0 : steps]) {
            base_offset = i * FIXED_PULLEY_PITCH;
            r_pos = base_offset + split_off;
            l_pos = -(base_offset + split_off);
            
            translate([r_pos, 31, -1]) cylinder(d=8, h=WALL_T+2);
            translate([r_pos, -31, -1]) cylinder(d=8, h=WALL_T+2);
            translate([l_pos, 31, -1]) cylinder(d=8, h=WALL_T+2);
            translate([l_pos, -31, -1]) cylinder(d=8, h=WALL_T+2);
        }
        
        // Center Holes
        if (FIXED_PULLEY_SPLIT_ADDITION > 20) {
             translate([0, 31, -1]) cylinder(d=8, h=WALL_T+2);
             translate([0, -31, -1]) cylinder(d=8, h=WALL_T+2);
        }
        if (FIXED_PULLEY_SPLIT_ADDITION > 50) {
             translate([FIXED_PULLEY_PITCH, 31, -1]) cylinder(d=8, h=WALL_T+2);
             translate([FIXED_PULLEY_PITCH, -31, -1]) cylinder(d=8, h=WALL_T+2);
             translate([-FIXED_PULLEY_PITCH, 31, -1]) cylinder(d=8, h=WALL_T+2);
             translate([-FIXED_PULLEY_PITCH, -31, -1]) cylinder(d=8, h=WALL_T+2);
        }
    }
    
    locs = [[gx, 13], [-gx, 13], [gx, -13], [-gx, -13]];
    for(pos = locs) translate([pos.x, pos.y, 0]) {
        if(up) translate([0,0, WALL_T]) mushroom_stud(5.5, 5, 1);
        if(down) mushroom_stud(5.5, 5, -1);
    }
}

module fixed_pulley_row_split(count) {
    pairs = count / 2;
    axle_L = HOUSING_GAP + (WALL_T * 2) + 0.2; 
    split_offset = FIXED_PULLEY_SPLIT_ADDITION / 2;
    
    for (i = [0 : pairs - 1]) {
        // Uses FIXED PITCH
        base_pos = (0.5 + i) * FIXED_PULLEY_PITCH;
        
        translate([base_pos + split_offset, 0, 0]) 
            captive_pulley(FIXED_PULLEY_WIDTH, axle_L, 13.0);
        translate([-(base_pos + split_offset), 0, 0]) 
            captive_pulley(FIXED_PULLEY_WIDTH, axle_L, 13.0);
    }
}

module slider_assembly_independent(count, len_val) {
    if (SHOW_SLIDER_PLATES) {
        color([0.9, 0.4, 0.4, 1.0])
        translate([-len_val/2, -7.5, -(SLIDER_GAP/2 + 5.0)])
            cube([len_val, 15, 5.0]);
    
        color([0.9, 0.4, 0.4, 1.0])
        translate([-len_val/2, -7.5, SLIDER_GAP/2]) 
            cube([len_val, 15, 5.0]); 
    }
        
    slider_pulley_row_independent(count);
}

module slider_pulley_row_independent(count) {
    pairs = count / 2;
    axle_L = SLIDER_GAP; 
    
    // Uses INDEPENDENT SLIDER SPLIT
    split_offset = SLIDER_SPLIT_ADDITION / 2;
    
    for (i = [0 : pairs - 1]) {
        // Uses INDEPENDENT SLIDER PITCH
        base_pos = (0.5 + i) * SLIDER_PULLEY_PITCH;
        
        // Apply Global Offset + Split + Pitch
        
        // Right Side (+X)
        translate([base_pos + split_offset + SLIDER_X_OFFSET, 0, 0]) 
            captive_pulley(SLIDER_PULLEY_WIDTH, axle_L, 10.0);
            
        // Left Side (-X)
        translate([-(base_pos + split_offset) + SLIDER_X_OFFSET, 0, 0]) 
            captive_pulley(SLIDER_PULLEY_WIDTH, axle_L, 10.0);
    }
}

module floating_rollers(gx) {
    locs = [[gx, 13], [-gx, 13], [gx, -13], [-gx, -13]];
    z_offset = (HOUSING_GAP/2) - (5.0/2) - 0.5; 
    
    for(pos = locs) translate([pos.x, pos.y, 0]) {
        translate([0,0, -z_offset]) 
            captive_pulley(ROLLER_WIDTH, ROLLER_WIDTH + 2.0, 10.0);
        translate([0,0, z_offset]) 
            captive_pulley(ROLLER_WIDTH, ROLLER_WIDTH + 2.0, 10.0);
    }
}

// --- CORE PARTS ---

module captive_pulley(w, axle_len, pulley_d) {
    color([0.5, 0.5, 0.5]) 
    union() {
        translate([0,0, -axle_len/2])
            cylinder(d=AXLE_DIA, h=axle_len);
        cylinder(d=AXLE_DIA + 1.5, h=2.0, center=true);
    }
    
    color([0.95, 0.95, 0.95]) 
    translate([0,0, -w/2]) 
        difference(){
            cylinder(d=pulley_d, h=w); 
            translate([0,0,-1]) cylinder(d=AXLE_DIA + 0.6, h=w+2);
            translate([0, 0, w/2])
                cylinder(d=AXLE_DIA + 2.0, h=2.5, center=true);
        }
}

module mushroom_stud(h, d, dir) {
    color([0.6,0.6,0.6])
    if(dir==1) union(){cylinder(d=d,h=h-1.5); translate([0,0,h-1.5]) cylinder(d1=d,d2=d+2,h=1.5);}
    else rotate([180,0,0]) union(){cylinder(d=d,h=h-1.5); translate([0,0,h-1.5]) cylinder(d1=d,d2=d+2,h=1.5);}
}