// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT MECHANICAL CANVAS - V26 ASSEMBLED VIEW
// Static view for assembly reference
// ═══════════════════════════════════════════════════════════════════════════
$fn=48;

// ═══════════════════════════════════════════════════════════════════════════
// PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════
W = 350;
H = 275;
D = 100;
FW = 25;
IW = W - FW*2;
IH = H - FW*2;

// Z-LAYERS
Z_LED = 0;
Z_DIFFUSER = 3;
Z_BACK = 5;
Z_SKY_DISK = 8;
Z_STARS = 20;
Z_MOON = 22;
Z_CLIFF = 26;
Z_WAVE_BASE = 64;
Z_BEACH = 84;
Z_FRAME = 88;

// COLORS
C_FRAME = "Gold";
C_WAVE = ["#061a3a", "#0a2a5e", "#1a4a7e", "#2a5a8e", "#4a7aae"];
C_CLIFF = "#3d3d3d";
C_CLIFF_DARK = "#2a2a2a";
C_BEACH = "#c4a574";
C_CYPRESS = "#1a3d1a";
C_LIGHTHOUSE = "Ivory";
C_LIGHTHOUSE_RED = "#8b0000";
C_SKY = "#0a1a3a";
C_MOON = "Gold";

// STARS
STARS = [
    [0.12, 0.85, "narrow"], [0.25, 0.82, "broad"], [0.45, 0.88, "narrow"],
    [0.35, 0.72, "broad"], [0.52, 0.75, "narrow"], [0.68, 0.78, "broad"],
    [0.15, 0.65, "narrow"], [0.38, 0.62, "broad"], [0.55, 0.68, "narrow"],
    [0.72, 0.65, "broad"], [0.75, 0.72, "narrow"], [0.48, 0.55, "broad"]
];

// WAVE CURLS
WAVE_CURLS = [
    [[0.08, 0.9], [0.22, 0.85], [0.38, 0.9], [0.52, 0.85], [0.68, 0.9], [0.82, 0.85], [0.95, 0.9]],
    [[0.05, 0.95], [0.18, 0.9], [0.32, 0.95], [0.48, 0.9], [0.62, 0.95], [0.78, 0.9], [0.92, 0.95]],
    [[0.10, 1.0], [0.25, 0.95], [0.42, 1.0], [0.55, 0.95], [0.72, 1.0], [0.88, 0.95]],
    [[0.03, 1.0], [0.15, 0.95], [0.30, 1.0], [0.45, 0.95], [0.60, 1.0], [0.75, 0.95], [0.90, 1.0]],
    [[0.07, 1.1], [0.20, 1.05], [0.35, 1.1], [0.50, 1.05], [0.65, 1.1], [0.80, 1.05], [0.93, 1.1]]
];

// ═══════════════════════════════════════════════════════════════════════════
// MODULES
// ═══════════════════════════════════════════════════════════════════════════

module star_cutout(type="broad") {
    if (type == "broad") {
        cylinder(d=11, h=5, center=true);
    } else {
        for (a = [0:60:300]) rotate([0, 0, a]) cube([2, 8, 5], center=true);
    }
}

module sky_mask() {
    color(C_SKY, 0.9)
    difference() {
        cube([IW, IH, 2]);
        for (s = STARS) translate([s[0]*IW, s[1]*IH, -1]) star_cutout(s[2]);
        translate([IW*0.85, IH*0.78, -1]) cylinder(d=55, h=5);
        translate([-1, -1, -1]) cube([IW*0.42, IH*0.65, 5]);
        translate([-1, -1, -1]) cube([IW+2, IH*0.35, 5]);
    }
}

module sky_spiral_disk(radius, arms, slot_width) {
    color(C_SKY, 0.7)
    difference() {
        cylinder(r=radius, h=3);
        translate([0, 0, -1]) cylinder(d=8, h=5);
        for (arm = [0:arms-1])
            for (r = [15:6:radius-5])
                rotate([0, 0, arm * (360/arms) + r * 2.2])
                translate([r, 0, -1])
                cylinder(d=slot_width + r*0.04, h=5);
    }
}

module moon() {
    r = 25;
    color(C_MOON) cylinder(r=r, h=4);
    // Half moon phase shown
    translate([0, 0, 4]) color(C_SKY)
    difference() {
        cylinder(r=r+1, h=2);
        translate([r, 0, -1]) cylinder(r=r, h=4);
    }
}

module cliff() {
    color(C_CLIFF)
    hull() {
        translate([5, 5, 0]) cylinder(r=25, h=38);
        translate([60, 8, 0]) cylinder(r=20, h=38);
        translate([70, IH*0.35, 0]) cylinder(r=18, h=35);
        translate([55, IH*0.50, 0]) cylinder(r=20, h=32);
        translate([35, IH*0.58, 0]) cylinder(r=15, h=28);
        translate([10, IH*0.55, 0]) cylinder(r=18, h=30);
    }
    color(C_CLIFF_DARK)
    for (p = [[15, IH*0.12, 18], [40, IH*0.18, 22], [55, IH*0.25, 20],
              [25, IH*0.32, 25], [50, IH*0.38, 22], [18, IH*0.45, 18]])
        translate([p[0], p[1], p[2]]) scale([1.3, 1.1, 0.6]) sphere(r=6);
    color(C_CLIFF) translate([38, IH*0.52, 36]) cylinder(r=16, h=4, $fn=12);
    color(C_CLIFF_DARK)
    for (p = [[10, 3], [28, 4], [48, 3], [65, 5], [78, 4]])
        translate([p[0], p[1], 0]) scale([1.8, 1.4, 1]) sphere(r=7);
    color("#4a4a4a")
    for (p = [[18, 5], [38, 3], [58, 6], [72, 3]])
        translate([p[0], p[1], 0]) scale([1.3, 1, 0.7]) sphere(r=5);
    color("#5a5a5a")
    for (i = [0:20])
        translate([8 + i*3.5, 2 + sin(i)*1.5, 0]) sphere(r=1.5 + sin(i*0.5));
}

module cypress() {
    color(C_CYPRESS) {
        cylinder(r1=4, r2=2, h=15);
        for (z = [10:8:75]) {
            sf = 1 - (z-10)/80;
            translate([0, 0, z]) scale([sf, sf*0.6, 1]) cylinder(r1=12, r2=3, h=15);
        }
    }
}

module lighthouse() {
    rotate([-90, 0, 0]) {
        color(C_LIGHTHOUSE) cylinder(r1=8, r2=6, h=45);
        color(C_LIGHTHOUSE_RED)
        for (z = [8, 22, 36]) translate([0, 0, z]) cylinder(r=7 - z*0.03, h=6);
        translate([0, 0, 45]) {
            color("#333") cylinder(r=8, h=3);
            color("LightBlue", 0.4) translate([0, 0, 3])
            difference() { cylinder(r=7, h=10); translate([0, 0, 1]) cylinder(r=6, h=10); }
            color("Yellow") translate([0, 0, 6]) cylinder(r=4, h=5);
            color("White", 0.7) translate([0, 0, 5]) rotate([0, 90, 0])
            linear_extrude(height=30) polygon([[0, -2], [0, 2], [25, 8], [25, -8]]);
            color(C_LIGHTHOUSE_RED) translate([0, 0, 13]) cylinder(r1=8, r2=2, h=6);
        }
    }
}

module wave_curl(size, dir=1) {
    scale([dir, 1, 1])
    linear_extrude(height=4)
    polygon(concat([[0, 0]],
        [for (t = [0:10:180]) let(r = size * (1 - t/220)) [r * cos(t) * 0.8, size*0.4 + r * sin(t)]],
        [[size*-0.3, size*0.2], [0, 0]]));
}

module foam_tip(size) {
    color("White", 0.8) translate([0, size*0.35, 4]) scale([0.6, 0.3, 0.15]) sphere(r=size*0.4);
}

module wave_panel(wave_num) {
    pw = IW - 85;
    curl_data = WAVE_CURLS[wave_num];
    base_size = 22 + wave_num * 3;
    wave_color = C_WAVE[wave_num];
    base_y = [12, 6, 0, -6, -12][wave_num];
    
    translate([0, base_y, 0])
    color(wave_color, 0.85) {
        linear_extrude(height=4) translate([0, -10]) square([pw, 14]);
        for (i = [0:len(curl_data)-1]) {
            cx = curl_data[i][0] * pw;
            cs = base_size * curl_data[i][1];
            dir = (i % 2 == 0) ? 1 : -1;
            translate([cx, 0, 0]) rotate([0, 0, dir * 8]) wave_curl(cs, dir);
            if (i == 0 || i == len(curl_data)-1) {
                translate([cx, 0, 0]) foam_tip(cs);
            }
        }
    }
}

module ship() {
    color("SaddleBrown") {
        linear_extrude(height=5)
        polygon([[-18, 0], [-15, 5], [-8, 8], [8, 8], [15, 5], [20, 0], [15, -4], [-15, -4]]);
        translate([0, 8, 0]) cube([2, 2, 40], center=true);
        translate([3, 8, 8]) linear_extrude(height=2)
        polygon([[0, 0], [18, 3], [18, 22], [0, 25]]);
    }
}

module bird(wing_angle) {
    rotate([0, 0, 180])
    union() {
        color("Black") {
            scale([2.2, 1, 0.8]) sphere(r=2.5);
            translate([5.5, 0, 0]) sphere(r=2);
            translate([7.5, 0, 0]) rotate([0, 90, 0]) cylinder(r1=0.8, r2=0, h=3.5);
            translate([-4.5, 0, 0]) scale([2, 0.5, 0.2]) sphere(r=2.5);
        }
        color("#333") {
            translate([0, 0, 2]) rotate([0, wing_angle, 0]) scale([0.9, 0.15, 0.9])
            rotate([90, 0, 0]) linear_extrude(height=2) polygon([[0, 0], [-3, 10], [3, 10], [4, 0]]);
            translate([0, 0, -2]) rotate([0, -wing_angle, 0]) scale([0.9, 0.15, 0.9])
            rotate([90, 0, 0]) linear_extrude(height=2) polygon([[0, 0], [-3, -10], [3, -10], [4, 0]]);
        }
    }
}

module beach() {
    color(C_BEACH) {
        linear_extrude(height=4) polygon([[0, 0], [IW*0.4, 0], [IW, IH*0.08], [IW, 0], [0, 0]]);
        for (i = [0:8])
            translate([IW*0.1 + i*IW*0.08, IH*0.02, 4]) rotate([0, 0, 15]) scale([3, 0.5, 0.15]) sphere(r=8);
    }
    color("White", 0.7)
    for (i = [0:5])
        translate([IW*0.08 + i*IW*0.06, IH*0.04, 4]) scale([1.5, 0.8, 0.3]) sphere(r=6);
}

module rice_tube() {
    color("#444") {
        difference() { cube([14, 12, 14], center=true); rotate([0, 90, 0]) cylinder(d=10, h=16, center=true); }
        translate([IW-100, 0, 0])
        difference() { cube([14, 12, 14], center=true); rotate([0, 90, 0]) cylinder(d=10, h=16, center=true); }
    }
    translate([10, 0, 0]) color("Tan", 0.85) rotate([0, 90, 0])
    difference() {
        cylinder(d=22, h=IW-120);
        translate([0, 0, 3]) cylinder(d=18, h=IW-126);
        for (i = [1:6]) translate([0, 0, i*(IW-120)/7]) rotate([0, 0, i*30]) cube([20, 2, 2], center=true);
    }
}

module frame() {
    color(C_FRAME)
    difference() {
        cube([W, H, 12]);
        translate([FW, FW, -1]) cube([IW, IH, 14]);
        translate([FW+15, H-FW+3, -1]) cube([IW-30, FW-6, 14]);
    }
}

module gear(teeth, radius) {
    color("Goldenrod")
    linear_extrude(height=3)
    difference() {
        union() {
            circle(r=radius-2);
            for (i = [0:teeth-1]) rotate([0, 0, i*360/teeth]) translate([radius-2, 0]) square([4, 3], center=true);
        }
        circle(r=3);
    }
}

module gear_train_A() {
    translate([FW + 20, -5, 0]) rotate([90, 0, 0]) {
        gear(12, 10);
        translate([22, 0, 0]) gear(24, 16);
        translate([44, 0, 0]) gear(18, 12);
        translate([62, 0, 0]) gear(30, 20);
        translate([88, 0, 0]) gear(36, 24);
    }
}

module gear_train_B() {
    translate([W - FW - 110, -5, 0]) rotate([90, 0, 0]) {
        gear(12, 10);
        translate([22, 0, 0]) gear(36, 24);
        translate([52, 0, 0]) gear(20, 14);
        translate([72, 0, 0]) gear(28, 18);
        translate([96, 0, 0]) gear(48, 32);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// LED Panel
color("DarkBlue", 0.3) translate([0, 0, Z_LED]) cube([W, H, 3]);

// Diffuser
color("White", 0.3) translate([FW, FW, Z_DIFFUSER]) cube([IW, IH, 2]);

// Back panel
color(C_SKY) translate([FW, FW, Z_BACK]) cube([IW, IH, 3]);

// Sky spiral disks
translate([FW + IW*0.35, FW + IH*0.75, Z_SKY_DISK]) {
    sky_spiral_disk(100, 8, 8);
    translate([0, 0, 4]) sky_spiral_disk(75, 6, 6);
    translate([0, 0, 8]) sky_spiral_disk(50, 5, 5);
}

// Star LEDs
translate([FW, FW, Z_STARS])
for (s = STARS) translate([s[0]*IW, s[1]*IH, 0]) color("Yellow") cylinder(d=6, h=3);

// Sky mask
translate([FW, FW, Z_STARS + 2]) sky_mask();

// Moon
translate([FW + IW*0.85, FW + IH*0.78, Z_MOON]) moon();

// Cliff
translate([FW, FW, Z_CLIFF]) cliff();

// Cypress
translate([FW + 25, FW + IH*0.48, Z_CLIFF]) cypress();

// Lighthouse
translate([FW + 40, FW + IH*0.54, Z_CLIFF + 38]) lighthouse();

// Waves
for (i = [0:4]) translate([FW + 80, FW + 10, Z_WAVE_BASE + i*4]) wave_panel(i);

// Ship
translate([FW + 160, FW + 25, Z_WAVE_BASE + 6]) ship();

// Beach
translate([FW, FW, Z_BEACH]) beach();

// Rice tube
translate([FW + 50, H - FW/2, Z_FRAME + 6]) rice_tube();

// Birds (static positions)
translate([FW + IW*0.7, FW + IH*0.72, 78]) bird(20);
translate([FW + IW*0.5, FW + IH*0.75, 75]) scale([0.9, 0.9, 0.9]) bird(-15);
translate([FW + IW*0.3, FW + IH*0.78, 72]) scale([0.85, 0.85, 0.85]) bird(25);

// Frame
translate([0, 0, Z_FRAME]) frame();

// Gear trains
translate([0, FW, Z_FRAME - 3]) {
    gear_train_A();
    gear_train_B();
}

// ═══════════════════════════════════════════════════════════════════════════
// DIMENSION ANNOTATIONS
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT V26 - ASSEMBLED VIEW SPECIFICATIONS");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Overall dimensions:", W, "×", H, "×", D, "mm");
echo("Inner scene:", IW, "×", IH, "mm");
echo("Frame width:", FW, "mm");
echo("Total depth used:", Z_FRAME + 12, "mm");
echo("═══════════════════════════════════════════════════════════════════════");
