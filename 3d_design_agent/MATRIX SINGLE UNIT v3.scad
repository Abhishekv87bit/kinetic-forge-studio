// ==================================================
// V68: INDEPENDENT OFFSETS + UPDATED PARAMS
// ==================================================
// 1. UPDATED: Wall T=3mm, Ext=10mm, Stack=25mm.
// 2. CONTROLS: 10 Sliders for full X-Axis control.
// 3. LOGIC: Holes follow Fixed Pulleys.
// ==================================================

$fn = 60; 

// ==================================================
// 1. CHANNEL OFFSET SLIDERS
// ==================================================

/* [Fixed Pulley & Wall Hole Offsets] */
// Shifts the Fixed Pulleys and the Wall Access Holes
CH1_FIXED_X = 0; // [-100:1:100]
CH2_FIXED_X = 0; // [-100:1:100]
CH3_FIXED_X = 0; // [-100:1:100]
CH4_FIXED_X = 0; // [-100:1:100]
CH5_FIXED_X = 0; // [-100:1:100]

/* [Slider Pulley Offsets] */
// Shifts the Slider Pulleys independently
CH1_SLIDER_X = 0; // [-100:1:100]
CH2_SLIDER_X = 0; // [-100:1:100]
CH3_SLIDER_X = 0; // [-100:1:100]
CH4_SLIDER_X = 0; // [-100:1:100]
CH5_SLIDER_X = 0; // [-100:1:100]


// ==================================================
// 2. CONFIGURATION (LOCKED TO IMAGE)
// ==================================================

/* [Hidden] */

// Stack Config
TIER_CONFIG  = [2, 4, 6, 4, 2];
TIER_LENGTHS = [120, 200, 280, 200, 120];
STACK_OFFSET = 25.0; // Updated

// Visibility
SHOW_HOUSING_WALLS = true;
SHOW_SLIDER_PLATES = true;

// Geometry Constants
FIXED_PULLEY_SPLIT_ADDITION = 55.0; 
FIXED_PULLEY_PITCH          = 27.0; 
SLIDER_PULLEY_PITCH         = 27.0; 
SLIDER_SPLIT_ADDITION       = 27.0; 

// Dimensions & Gaps
HOUSING_GAP = 19.0;
SLIDER_GAP  = 8.0;

// Widths
FIXED_PULLEY_WIDTH  = 18.0;
SLIDER_PULLEY_WIDTH = 7.0;
ROLLER_WIDTH        = 5.0;

// Geometry
AXLE_DIA     = 5.0;
SLIDER_EXT_L = 10.0; // Updated to 10
SLIDER_EXT_R = 10.0; // Updated to 10
HOUSING_H    = 85.0;
WALL_T       = 3.0;  // Updated to 3

// Arrays
FIXED_OFFSETS  = [CH1_FIXED_X, CH2_FIXED_X, CH3_FIXED_X, CH4_FIXED_X, CH5_FIXED_X];
SLIDER_OFFSETS = [CH1_SLIDER_X, CH2_SLIDER_X, CH3_SLIDER_X, CH4_SLIDER_X, CH5_SLIDER_X];


// ==================================================
// 3. MAIN RENDER LOOP
// ==================================================

anim_val = sin($t * 360) * 30;

generate_stack(anim_val);

module generate_stack(slide_pos) {
    rotate([90, 0, 0]) {
        for (i = [0 : len(TIER_CONFIG) - 1]) {
            
            p_count    = TIER_CONFIG[i];
            l_val      = TIER_LENGTHS[i];
            
            // Pull offsets from arrays
            fixed_off  = FIXED_OFFSETS[i];
            slider_off = SLIDER_OFFSETS[i];
            
            // Calculate Stack Height
            total_height = (len(TIER_CONFIG) - 1) * STACK_OFFSET;
            y_pos = (i * STACK_OFFSET) - (total_height / 2);
            
            translate([0, 0, y_pos])
                generate_single_unit(slide_pos, p_count, l_val, fixed_off, slider_off);
        }
    }
}


// ==================================================
// 4. UNIT GENERATOR
// ==================================================

module generate_single_unit(slide_pos, num_pulleys, h_len_base, fixed_offset, slider_offset) {
    
    // Geometry Calcs
    h_len = h_len_base + FIXED_PULLEY_SPLIT_ADDITION;
    s_len_total = h_len + SLIDER_EXT_L + SLIDER_EXT_R;
    s_center_shift = (SLIDER_EXT_R - SLIDER_EXT_L) / 2;
    g_pos_x = (h_len / 2) - 15;

    // --- RENDER ---
    
    // 1. Walls (Blue)
    // Wall shape stays centered (0), but Holes shift by fixed_offset
    if (SHOW_HOUSING_WALLS) {
        translate([0, 0, -(HOUSING_GAP/2 + WALL_T)]) 
            wall_body_split(h_len, g_pos_x, true, false, fixed_offset); 
            
        translate([0, 0, HOUSING_GAP/2]) 
            wall_body_split(h_len, g_pos_x, false, true, fixed_offset); 
    }
    
    // 2. Fixed Pulleys (Shifted by fixed_offset)
    translate([fixed_offset, 31, 0]) 
        fixed_pulley_row_split(num_pulleys);
    translate([fixed_offset, -31, 0]) 
        fixed_pulley_row_split(num_pulleys);

    // 3. Rollers (Shifted by fixed_offset)
    translate([fixed_offset, 0, 0])
        floating_rollers(g_pos_x);
    
    // 4. Slider Assembly (Shifted by slider_offset)
    translate([slide_pos + s_center_shift, 0, 0])
        slider_assembly_independent(num_pulleys, s_len_total, slider_offset);
}


// --- COMPONENT MODULES ---

module wall_body_split(w_len, gx, up, down, shift_val) {
    color([0.6, 0.6, 1.0, 1.0]) 
    difference() {
        // Wall Body (Static)
        translate([-w_len/2, -HOUSING_H/2, 0])
            cube([w_len, HOUSING_H, WALL_T]);
        
        if (w_len > 100) {
            translate([-40, -20, -1])
                cube([80, 40, 7]);
        }
        
        // Holes (Shifted)
        translate([shift_val, 0, 0]) {
            split_off = FIXED_PULLEY_SPLIT_ADDITION / 2;
            steps = floor((w_len/2 - 10) / FIXED_PULLEY_PITCH);
            
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
    }
    
    // Studs (Static)
    locs = [[gx, 13], [-gx, 13], [gx, -13], [-gx, -13]];
    for(pos = locs) translate([pos.x, pos.y, 0]) {
        if(up) translate([0,0, WALL_T]) mushroom_stud(5.5, 5, 1);
        if(down) mushroom_stud(5.5, 5, -1);
    }
}

module fixed_pulley_row_split(count) {
    pairs = count / 2;
    // Axle Length + Penetration
    axle_L = HOUSING_GAP + (WALL_T * 2) + 0.2; 
    split_offset = FIXED_PULLEY_SPLIT_ADDITION / 2;
    
    for (i = [0 : pairs - 1]) {
        base_pos = (0.5 + i) * FIXED_PULLEY_PITCH;
        
        translate([base_pos + split_offset, 0, 0]) 
            captive_pulley(FIXED_PULLEY_WIDTH, axle_L, 13.0);
        translate([-(base_pos + split_offset), 0, 0]) 
            captive_pulley(FIXED_PULLEY_WIDTH, axle_L, 13.0);
    }
}

module slider_assembly_independent(count, len_val, s_offset) {
    // Red Plates
    if (SHOW_SLIDER_PLATES) {
        // Move Red Plates with Slider Offset (Standard practice)
        // If you want plates static and only pulleys moving, remove `s_offset` here.
        translate([s_offset, 0, 0]) {
            color([0.9, 0.4, 0.4, 1.0])
            translate([-len_val/2, -7.5, -(SLIDER_GAP/2 + 5.0)])
                cube([len_val, 15, 5.0]);
        
            color([0.9, 0.4, 0.4, 1.0])
            translate([-len_val/2, -7.5, SLIDER_GAP/2]) 
                cube([len_val, 15, 5.0]); 
        }
    }
        
    slider_pulley_row_independent(count, s_offset);
}

module slider_pulley_row_independent(count, s_offset) {
    pairs = count / 2;
    axle_L = SLIDER_GAP; 
    split_offset = SLIDER_SPLIT_ADDITION / 2;
    
    for (i = [0 : pairs - 1]) {
        base_pos = (0.5 + i) * SLIDER_PULLEY_PITCH;
        
        // Apply Slider Offset
        translate([base_pos + split_offset + s_offset, 0, 0]) 
            captive_pulley(SLIDER_PULLEY_WIDTH, axle_L, 10.0);
            
        translate([-(base_pos + split_offset) + s_offset, 0, 0]) 
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