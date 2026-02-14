// ═══════════════════════════════════════════════════════════════════════════════
//                    MARBLE CREATURE RUN v1.0
//                    Gravity-Powered Whimsical Kinetic Sculpture
// ═══════════════════════════════════════════════════════════════════════════════
// SIZE: 100 × 100 × 100 mm
// POWER: 16mm glass marble (gravity-driven)
// CREATURES: 4 moving elements triggered by marble passage
//   1. Tipping Bird - pecks when marble crosses platform
//   2. Spinning Owl - twirls when marble hits paddles
//   3. See-saw Frogs - teeter-totter as marble crosses
//   4. Wagging Dog - tail wags when marble hits lever
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
//                              PARAMETERS
// ─────────────────────────────────────────────────────────────────────────────

// Marble
marble_d = 16;              // Marble diameter (mm)
marble_clearance = 1;       // Clearance each side in track

// Track dimensions
track_width = marble_d + 2*marble_clearance;  // 18mm
track_wall = 2;             // Wall thickness for tracks
track_depth = marble_d * 0.6;  // Marble sits 60% deep in channel

// Frame
frame_size = 100;           // Outer dimension (cube)
frame_wall = 2;             // Frame wall thickness

// Pivot hardware
pivot_d = 3;                // 3mm brass rod
pivot_hole = 3.3;           // Clearance hole for pivot
pivot_clearance = 0.3;      // Gap around moving parts

// Print settings
min_wall = 1.2;             // Minimum wall thickness
min_feature = 0.8;          // Minimum feature size

// Animation
$fn = 32;                   // Default resolution

// ─────────────────────────────────────────────────────────────────────────────
//                              Z-HEIGHT STATIONS
// ─────────────────────────────────────────────────────────────────────────────

z_entry = 92;               // Entry funnel top
z_bird = 70;                // Bird pivot height
z_owl = 52;                 // Owl center height
z_frogs = 34;               // Frog beam height
z_dog = 18;                 // Dog/tail height
z_bowl = 5;                 // Collection bowl

// ─────────────────────────────────────────────────────────────────────────────
//                              CREATURE 1: TIPPING BIRD
// ─────────────────────────────────────────────────────────────────────────────
// Mechanism: Marble rolls onto platform, shifts CG, bird tips forward (pecks)
//            Marble exits, counterweight tail returns bird upright

bird_body_l = 30;           // Beak to tail
bird_body_w = 15;
bird_body_h = 18;
bird_platform_l = 25;       // Platform length (marble rolls on this)
bird_platform_w = 20;
bird_pivot_from_beak = 18;  // Pivot point location
bird_tail_weight = [6, 6, 10];  // Counterweight block

module bird_body() {
    // Main body - egg shape
    scale([1.5, 1, 1.2])
        sphere(d=bird_body_w);

    // Beak
    translate([bird_body_w*0.7, 0, 2])
        rotate([0, 45, 0])
            cylinder(d1=5, d2=1, h=10, $fn=16);

    // Eyes
    for (side = [-1, 1]) {
        translate([bird_body_w*0.3, side*bird_body_w*0.35, bird_body_h*0.25])
            sphere(d=4, $fn=16);
    }

    // Tail feathers (counterweight)
    translate([-bird_body_l*0.4, 0, 0])
        cube(bird_tail_weight, center=true);
}

module bird_platform() {
    // Platform where marble rolls
    translate([bird_pivot_from_beak - bird_body_l/2, 0, -bird_body_h/2 - 2])
        cube([bird_platform_l, bird_platform_w, 2], center=true);

    // Side rails to keep marble on track
    for (side = [-1, 1]) {
        translate([bird_pivot_from_beak - bird_body_l/2, side*(bird_platform_w/2 - 1.5), -bird_body_h/2 - 2])
            cube([bird_platform_l, 3, 6], center=true);
    }
}

module bird_pivot_holes() {
    // Holes for pivot rod
    translate([0, 0, 0])
        rotate([90, 0, 0])
            cylinder(d=pivot_hole, h=bird_body_w + 10, center=true);
}

module tipping_bird(angle=0) {
    // angle: 0 = level, positive = pecking forward
    rotate([0, -angle, 0]) {
        difference() {
            union() {
                bird_body();
                bird_platform();
            }
            bird_pivot_holes();
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//                              CREATURE 2: SPINNING OWL
// ─────────────────────────────────────────────────────────────────────────────
// Mechanism: Marble drops onto angled paddles, impulse spins owl
//            Friction naturally stops rotation

owl_body_d = 28;
owl_body_h = 25;
owl_paddle_count = 4;
owl_paddle_size = [15, 10, 2];
owl_paddle_angle = 45;      // Angled to catch falling marble

module owl_body() {
    // Main body - cylinder with dome top
    cylinder(d=owl_body_d, h=owl_body_h*0.7);
    translate([0, 0, owl_body_h*0.7])
        scale([1, 1, 0.6])
            sphere(d=owl_body_d);

    // Big eyes
    for (side = [-1, 1]) {
        translate([owl_body_d*0.3, side*owl_body_d*0.25, owl_body_h*0.5]) {
            sphere(d=10, $fn=24);
            // Pupils
            translate([4, 0, 0])
                sphere(d=5, $fn=16);
        }
    }

    // Beak
    translate([owl_body_d*0.4, 0, owl_body_h*0.35])
        rotate([0, 45, 0])
            cylinder(d1=6, d2=2, h=8, $fn=3);  // Triangle beak

    // Ear tufts
    for (side = [-1, 1]) {
        translate([0, side*owl_body_d*0.35, owl_body_h*0.85])
            rotate([side*20, -20, 0])
                cylinder(d1=6, d2=2, h=10, $fn=16);
    }
}

module owl_paddles() {
    // Paddles around base to catch marble
    for (i = [0:owl_paddle_count-1]) {
        rotate([0, 0, i * 360/owl_paddle_count + 45]) {
            translate([owl_body_d/2 + owl_paddle_size[0]/2 - 3, 0, owl_body_h*0.3]) {
                rotate([owl_paddle_angle, 0, 0])
                    cube(owl_paddle_size, center=true);
            }
        }
    }
}

module owl_pivot_hole() {
    // Vertical pivot through center
    translate([0, 0, -1])
        cylinder(d=pivot_hole, h=owl_body_h + 10);
}

module spinning_owl(angle=0) {
    rotate([0, 0, angle]) {
        difference() {
            union() {
                owl_body();
                owl_paddles();
            }
            owl_pivot_hole();
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//                              CREATURE 3: SEE-SAW FROGS
// ─────────────────────────────────────────────────────────────────────────────
// Mechanism: Beam with frog on each end, pivots at center
//            Marble lands on one side, tips beam, frog dips

frog_beam_l = 50;
frog_beam_w = 10;
frog_beam_h = 3;
frog_size = [12, 10, 8];
frog_eye_d = 5;

module frog_body() {
    // Body - squished sphere
    scale([1.2, 1, 0.7])
        sphere(d=frog_size[1], $fn=24);

    // Big eyes on top
    for (side = [-1, 1]) {
        translate([frog_size[0]*0.2, side*frog_size[1]*0.3, frog_size[2]*0.4]) {
            sphere(d=frog_eye_d, $fn=16);
            // Pupils
            translate([2, 0, 1])
                sphere(d=2, $fn=12);
        }
    }

    // Front legs
    for (side = [-1, 1]) {
        translate([frog_size[0]*0.3, side*frog_size[1]*0.4, -frog_size[2]*0.3])
            scale([1.5, 0.6, 0.4])
                sphere(d=5, $fn=16);
    }

    // Back legs (folded)
    for (side = [-1, 1]) {
        translate([-frog_size[0]*0.3, side*frog_size[1]*0.5, -frog_size[2]*0.2])
            scale([1, 0.8, 0.5])
                sphere(d=8, $fn=16);
    }
}

module frog_beam() {
    // Main beam
    cube([frog_beam_l, frog_beam_w, frog_beam_h], center=true);

    // Track channel on top for marble
    translate([0, 0, frog_beam_h/2 + track_depth/2]) {
        difference() {
            cube([frog_beam_l, track_width + track_wall*2, track_depth + 2], center=true);
            cube([frog_beam_l + 2, track_width, track_depth*2], center=true);
        }
    }

    // Pivot reinforcement
    cylinder(d=pivot_hole + 4, h=frog_beam_h, center=true);
}

module frog_beam_pivot_hole() {
    rotate([90, 0, 0])
        cylinder(d=pivot_hole, h=frog_beam_w + 10, center=true);
}

module seesaw_frogs(angle=0) {
    // angle: positive = left frog down, right frog up
    rotate([0, 0, 90])  // Align beam with X axis
    rotate([angle, 0, 0]) {
        difference() {
            union() {
                frog_beam();

                // Left frog
                translate([-frog_beam_l/2 + frog_size[0]/2 + 2, 0, frog_beam_h/2 + frog_size[2]/2])
                    frog_body();

                // Right frog
                translate([frog_beam_l/2 - frog_size[0]/2 - 2, 0, frog_beam_h/2 + frog_size[2]/2])
                    rotate([0, 0, 180])  // Face opposite direction
                        frog_body();
            }
            frog_beam_pivot_hole();
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//                              CREATURE 4: WAGGING DOG
// ─────────────────────────────────────────────────────────────────────────────
// Mechanism: Marble rolls past, hits vertical lever, kicks tail pivot
//            Tail swings side-to-side, dampens naturally

dog_body_l = 22;
dog_body_w = 14;
dog_body_h = 16;
dog_tail_l = 18;
dog_tail_w = 5;
dog_lever_h = 15;

module dog_body() {
    // Body - elongated rounded box
    hull() {
        translate([dog_body_l*0.3, 0, 0])
            sphere(d=dog_body_w, $fn=24);
        translate([-dog_body_l*0.3, 0, 0])
            sphere(d=dog_body_w*0.9, $fn=24);
    }

    // Head
    translate([dog_body_l*0.5, 0, dog_body_h*0.3]) {
        sphere(d=dog_body_w*0.9, $fn=24);

        // Snout
        translate([dog_body_w*0.4, 0, -2])
            scale([1.5, 1, 0.8])
                sphere(d=6, $fn=16);

        // Ears (floppy)
        for (side = [-1, 1]) {
            translate([0, side*dog_body_w*0.4, dog_body_w*0.3])
                rotate([side*30, 0, 0])
                    scale([0.6, 0.4, 1])
                        sphere(d=8, $fn=16);
        }

        // Eyes
        for (side = [-1, 1]) {
            translate([dog_body_w*0.25, side*dog_body_w*0.25, 3])
                sphere(d=3, $fn=12);
        }
    }

    // Legs
    for (fb = [-1, 1]) {
        for (side = [-1, 1]) {
            translate([fb*dog_body_l*0.35, side*dog_body_w*0.35, -dog_body_h*0.4])
                cylinder(d=4, h=dog_body_h*0.5, $fn=16);
        }
    }
}

module dog_tail(wag_angle=0) {
    // Tail that wags side to side
    rotate([0, wag_angle, 0]) {
        translate([0, 0, dog_tail_l/2]) {
            // Tail shaft
            cylinder(d=dog_tail_w, h=dog_tail_l, center=true, $fn=16);
            // Fluffy end
            translate([0, 0, dog_tail_l/2])
                sphere(d=dog_tail_w*1.5, $fn=16);
        }
    }
}

module dog_lever() {
    // Vertical lever that marble hits
    translate([0, dog_body_w/2 + track_width/2 + 5, 0])
        cube([3, 2, dog_lever_h], center=true);
}

module wagging_dog(tail_angle=0) {
    // Dog body is static, only tail moves
    dog_body();

    // Tail pivot point at rear
    translate([-dog_body_l*0.5, 0, dog_body_h*0.2])
        rotate([90, 0, 0])
            dog_tail(tail_angle);

    // Lever for marble to hit (connected to tail internally)
    translate([-dog_body_l*0.5, 0, 0])
        dog_lever();
}

// ─────────────────────────────────────────────────────────────────────────────
//                              TRACK SECTIONS
// ─────────────────────────────────────────────────────────────────────────────

module track_channel(length) {
    // U-channel track for marble
    difference() {
        cube([length, track_width + track_wall*2, track_depth + track_wall], center=true);
        translate([0, 0, track_wall])
            cube([length + 2, track_width, track_depth + 1], center=true);
    }
}

module track_ramp(length, drop, twist=0) {
    // Angled track section
    angle = atan(drop/length);
    actual_length = sqrt(length*length + drop*drop);

    rotate([angle, 0, 0])
    rotate([0, 0, twist])
        track_channel(actual_length);
}

module entry_funnel() {
    // Funnel to catch marble and guide into track
    difference() {
        cylinder(d1=30, d2=track_width + track_wall*2, h=15, $fn=32);
        translate([0, 0, -1])
            cylinder(d1=25, d2=track_width, h=17, $fn=32);
    }
}

module collection_bowl() {
    // Bowl at bottom to catch marble
    difference() {
        cylinder(d1=25, d2=35, h=12, $fn=32);
        translate([0, 0, 2])
            cylinder(d1=15, d2=30, h=12, $fn=32);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//                              FRAME
// ─────────────────────────────────────────────────────────────────────────────

module frame() {
    difference() {
        // Outer cube
        cube([frame_size, frame_size, frame_size], center=true);

        // Hollow interior
        cube([frame_size - frame_wall*2, frame_size - frame_wall*2, frame_size - frame_wall*2], center=true);

        // Open front face for viewing
        translate([0, -frame_size/2, 0])
            cube([frame_size - 20, frame_wall*4, frame_size - 20], center=true);

        // Open top for marble entry
        translate([frame_size*0.3, frame_size*0.3, frame_size/2])
            cylinder(d=35, h=frame_wall*4, center=true, $fn=32);
    }
}

module pivot_mount(height, direction="horizontal") {
    // Mount bracket for pivot rod
    difference() {
        cube([10, 8, height], center=true);
        if (direction == "horizontal") {
            rotate([90, 0, 0])
                cylinder(d=pivot_hole, h=12, center=true);
        } else {
            cylinder(d=pivot_hole, h=height + 2, center=true);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//                              MARBLE (for visualization)
// ─────────────────────────────────────────────────────────────────────────────

module marble() {
    color("lightblue", 0.7)
        sphere(d=marble_d, $fn=32);
}

// ─────────────────────────────────────────────────────────────────────────────
//                              ASSEMBLY
// ─────────────────────────────────────────────────────────────────────────────

module assembly(t=0) {
    // t = 0 to 1 for animation cycle
    // Marble position phases:
    //   0.00-0.15: Entry to bird
    //   0.15-0.35: Bird station
    //   0.35-0.50: Bird to owl
    //   0.50-0.65: Owl station
    //   0.65-0.75: Owl to frogs
    //   0.75-0.85: Frog station
    //   0.85-0.95: Frogs to dog
    //   0.95-1.00: Dog to bowl

    // Frame
    color("burlywood", 0.3) frame();

    // Entry funnel
    translate([30, 30, z_entry])
        color("peru") entry_funnel();

    // ═══ STATION 1: TIPPING BIRD ═══
    bird_active = (t > 0.15 && t < 0.35);
    bird_angle = bird_active ? 25 * sin((t-0.15)/0.2 * 180) : 0;

    translate([20, 15, z_bird])
        rotate([0, 0, -30])
            color("gold") tipping_bird(bird_angle);

    // Bird pivot mounts
    translate([20, 15, z_bird])
        rotate([0, 0, -30])
            for (side = [-1, 1])
                translate([0, side*15, 0])
                    color("sienna") pivot_mount(8, "horizontal");

    // Ramp: Entry to Bird
    translate([25, 22, z_entry - 10])
        rotate([0, 0, -30])
            rotate([25, 0, 0])
                color("peru") track_channel(25);

    // ═══ STATION 2: SPINNING OWL ═══
    owl_active = (t > 0.50 && t < 0.65);
    owl_spin = owl_active ? 180 * (t-0.50)/0.15 :
               (t >= 0.65 ? 180 : 0);

    translate([35, -10, z_owl])
        color("sienna") spinning_owl(owl_spin);

    // Owl pivot mount (vertical post)
    translate([35, -10, z_owl - owl_body_h/2 - 5])
        color("sienna") cylinder(d=pivot_d + 4, h=5);

    // Ramp: Bird to Owl
    translate([28, 2, z_bird - 8])
        rotate([0, 0, 160])
            rotate([30, 0, 0])
                color("peru") track_channel(22);

    // ═══ STATION 3: SEE-SAW FROGS ═══
    frog_active = (t > 0.75 && t < 0.85);
    frog_angle = frog_active ? 15 * sin((t-0.75)/0.1 * 180) : 0;

    translate([0, 0, z_frogs])
        color("limegreen") seesaw_frogs(frog_angle);

    // Frog pivot mounts
    translate([0, 0, z_frogs])
        for (side = [-1, 1])
            translate([0, side*12, 0])
                color("sienna") pivot_mount(8, "horizontal");

    // Ramp: Owl to Frogs
    translate([18, -10, z_owl - 8])
        rotate([0, 0, 100])
            rotate([25, 0, 0])
                color("peru") track_channel(25);

    // ═══ STATION 4: WAGGING DOG ═══
    dog_active = (t > 0.92 && t < 1.0);
    tail_wag = dog_active ? 30 * sin((t-0.92)/0.08 * 360) : 0;

    translate([-25, -15, z_dog])
        rotate([0, 0, 45])
            color("sandybrown") wagging_dog(tail_wag);

    // Ramp: Frogs to Dog
    translate([-15, -8, z_frogs - 5])
        rotate([0, 0, -135])
            rotate([30, 0, 0])
                color("peru") track_channel(22);

    // ═══ COLLECTION BOWL ═══
    translate([-30, -30, z_bowl])
        color("peru") collection_bowl();

    // Final ramp to bowl
    translate([-28, -22, z_dog - 5])
        rotate([0, 0, -135])
            rotate([35, 0, 0])
                color("peru") track_channel(20);

    // ═══ MARBLE POSITION (animated) ═══
    marble_pos = marble_path(t);
    translate(marble_pos)
        marble();
}

// ─────────────────────────────────────────────────────────────────────────────
//                              MARBLE PATH FUNCTION
// ─────────────────────────────────────────────────────────────────────────────

function marble_path(t) =
    t < 0.15 ? [30 - t/0.15*10, 30 - t/0.15*15, z_entry - t/0.15*12] :
    t < 0.35 ? [20, 15, z_bird - 5] :  // At bird
    t < 0.50 ? [20 + (t-0.35)/0.15*15, 15 - (t-0.35)/0.15*25, z_bird - 8 - (t-0.35)/0.15*12] :
    t < 0.65 ? [35, -10, z_owl + 5] :  // At owl (on paddle)
    t < 0.75 ? [35 - (t-0.65)/0.1*35, -10 + (t-0.65)/0.1*10, z_owl - (t-0.65)/0.1*18] :
    t < 0.85 ? [0, 0, z_frogs + 8] :   // On frog beam
    t < 0.95 ? [(t-0.85)/0.1*-25, (t-0.85)/0.1*-15, z_frogs - (t-0.85)/0.1*16] :
    [-30, -30, z_bowl + 5];  // In bowl

// ─────────────────────────────────────────────────────────────────────────────
//                              RENDER
// ─────────────────────────────────────────────────────────────────────────────

// Animate with $t (0 to 1)
assembly($t);

// ─────────────────────────────────────────────────────────────────────────────
//                              PRINT MODULES (Uncomment to export)
// ─────────────────────────────────────────────────────────────────────────────

// For printing individual parts, uncomment one at a time:

// translate([0,0,0]) tipping_bird(0);       // Print flat, beak up
// translate([0,0,0]) spinning_owl(0);       // Print flat, base down
// translate([0,0,0]) seesaw_frogs(0);       // Print flat
// translate([0,0,0]) wagging_dog(0);        // Print flat
// translate([0,0,0]) entry_funnel();        // Print wide end down
// translate([0,0,0]) collection_bowl();     // Print base down
// translate([0,0,0]) frame();               // Print in orientation shown
