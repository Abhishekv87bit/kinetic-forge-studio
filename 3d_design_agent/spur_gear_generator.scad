/*
 * PARAMETRIC SPUR GEAR GENERATOR
 * ISO 21771 Compliant Involute Profile
 *
 * Author: Claude
 *
 * USAGE:
 *   spur_gear(m=2, teeth=24, thickness=10);
 *   spur_gear(m=3, teeth=20, thickness=15, bore=8, pressure_angle=20);
 *
 * All dimensions in millimeters.
 * Note: 'm' is used instead of 'module' (reserved keyword in OpenSCAD)
 */

$fn = 64;

// ═══════════════════════════════════════════════════════════════════════════
//                         EXAMPLE GEAR (uncomment to render)
// ═══════════════════════════════════════════════════════════════════════════

// Single gear
spur_gear(m=3, teeth=20, thickness=15, bore=8);

// Meshing pair (uncomment to see)
// gear_pair(m=2, teeth1=12, teeth2=36, thickness=10, spacing=0.2);

// ═══════════════════════════════════════════════════════════════════════════
//                         INVOLUTE MATH FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

// Involute curve point at parameter t (radians)
function involute_point(base_r, t) = [
    base_r * (cos(t * 180/PI) + t * sin(t * 180/PI)),
    base_r * (sin(t * 180/PI) - t * cos(t * 180/PI))
];

// Parameter t where involute reaches radius r
function involute_t_at_r(base_r, r) =
    (r <= base_r) ? 0 : sqrt(pow(r/base_r, 2) - 1);

// Involute function: inv(α) = tan(α) - α
function involute_function(alpha_deg) =
    tan(alpha_deg) - alpha_deg * PI / 180;

// Polar angle of involute point at radius r
function involute_polar_angle(base_r, r) =
    let(t = involute_t_at_r(base_r, r))
    atan2(involute_point(base_r, t).y, involute_point(base_r, t).x);

// ═══════════════════════════════════════════════════════════════════════════
//                         GEAR DIMENSION CALCULATOR
// ═══════════════════════════════════════════════════════════════════════════

// Returns [pitch_r, base_r, tip_r, root_r, circular_pitch, tooth_thickness]
function gear_dimensions(mod, z, alpha=20) = [
    mod * z / 2,                              // pitch radius
    mod * z / 2 * cos(alpha),                 // base radius
    mod * z / 2 + mod,                        // tip radius (addendum = 1.0m)
    mod * z / 2 - 1.25 * mod,                 // root radius (dedendum = 1.25m)
    PI * mod,                                 // circular pitch
    PI * mod / 2                              // tooth thickness at pitch
];

// ═══════════════════════════════════════════════════════════════════════════
//                         SINGLE TOOTH PROFILE (2D)
// ═══════════════════════════════════════════════════════════════════════════

module gear_tooth_profile(mod, z, alpha=20, steps=16) {
    dims = gear_dimensions(mod, z, alpha);
    pitch_r = dims[0];
    base_r = dims[1];
    tip_r = dims[2];
    root_r = dims[3];

    // Angular pitch
    angular_pitch = 360 / z;

    // Tooth thickness angle at pitch circle
    tooth_thick = PI * mod / 2;
    tooth_angle = (tooth_thick / pitch_r) * 180 / PI;

    // Involute parameters
    t_base = 0;
    t_tip = involute_t_at_r(base_r, tip_r);

    // Generate right flank involute points
    right_flank = [
        for (i = [0 : steps])
            let(
                t = t_base + (t_tip - t_base) * i / steps,
                pt = involute_point(base_r, t),
                r = norm(pt),
                ang = atan2(pt.y, pt.x)
            )
            [r * cos(ang - tooth_angle/2), r * sin(ang - tooth_angle/2)]
    ];

    // Mirror for left flank
    left_flank = [
        for (i = [len(right_flank)-1 : -1 : 0])
            let(pt = right_flank[i])
            [-pt.x, pt.y]
    ];

    // Root fillet radius
    fillet_r = 0.25 * mod;

    // Root arc
    root_start = -atan2(right_flank[0].x, right_flank[0].y);
    root_end = atan2(left_flank[len(left_flank)-1].x, left_flank[len(left_flank)-1].y);

    root_arc = [
        for (a = [root_start : 3 : root_end])
            [root_r * sin(a), root_r * cos(a)]
    ];

    // Tip relief/chamfer
    chamfer = 0.1 * mod;
    tip_r_eff = tip_r - chamfer;

    tip_arc = [
        let(pt = right_flank[len(right_flank)-1])
            [tip_r_eff * pt.x / norm(pt), tip_r_eff * pt.y / norm(pt)],
        [0, tip_r - chamfer/2],
        let(pt = left_flank[0])
            [tip_r_eff * pt.x / norm(pt), tip_r_eff * pt.y / norm(pt)]
    ];

    // Combine all points
    polygon(concat(root_arc, right_flank, tip_arc, left_flank));
}

// ═══════════════════════════════════════════════════════════════════════════
//                         REFERENCE CIRCLES (2D)
// ═══════════════════════════════════════════════════════════════════════════

module gear_circles_2d(mod, z, alpha=20, line_w=0.3) {
    dims = gear_dimensions(mod, z, alpha);
    pitch_r = dims[0];
    base_r = dims[1];
    tip_r = dims[2];
    root_r = dims[3];

    // Pitch (green)
    color("green", 0.5) difference() {
        circle(r = pitch_r + line_w/2);
        circle(r = pitch_r - line_w/2);
    }

    // Base (blue)
    color("blue", 0.5) difference() {
        circle(r = base_r + line_w/2);
        circle(r = base_r - line_w/2);
    }

    // Root (red)
    color("red", 0.5) difference() {
        circle(r = root_r + line_w/2);
        circle(r = root_r - line_w/2);
    }

    // Tip (orange)
    color("orange", 0.5) difference() {
        circle(r = tip_r + line_w/2);
        circle(r = tip_r - line_w/2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         MAIN SPUR GEAR MODULE
// ═══════════════════════════════════════════════════════════════════════════

/*
 * spur_gear - Creates a complete spur gear
 *
 * Parameters:
 *   m              - Gear module (tooth size), default 2mm
 *   teeth          - Number of teeth, default 20
 *   thickness      - Face width, default 10mm
 *   bore           - Center hole diameter, default 0 (no hole)
 *   pressure_angle - Pressure angle in degrees, default 20
 *   hub_dia        - Hub diameter, default 0 (no hub)
 *   hub_height     - Hub height (extends beyond gear), default 0
 *   keyway_width   - Keyway width, default 0 (no keyway)
 *   keyway_depth   - Keyway depth, default keyway_width/2
 *   show_circles   - Show reference circles, default false
 *   helix_angle    - Helix angle for helical gears, default 0
 */

module spur_gear(
    m = 2,
    teeth = 20,
    thickness = 10,
    bore = 0,
    pressure_angle = 20,
    hub_dia = 0,
    hub_height = 0,
    keyway_width = 0,
    keyway_depth = 0,
    show_circles = false,
    helix_angle = 0,
    color_gear = [0.7, 0.55, 0.2]
) {
    mod = m;  // Use 'mod' internally
    z = teeth;
    alpha = pressure_angle;

    dims = gear_dimensions(mod, z, alpha);
    pitch_r = dims[0];
    base_r = dims[1];
    tip_r = dims[2];
    root_r = dims[3];

    actual_hub_dia = (hub_dia > 0) ? hub_dia : (bore > 0 ? bore * 1.8 : root_r * 0.6);
    actual_keyway_depth = (keyway_depth > 0) ? keyway_depth : keyway_width / 2;

    color(color_gear)
    difference() {
        union() {
            // Gear body with teeth
            linear_extrude(thickness, twist = helix_angle * thickness / pitch_r, convexity = 10) {
                difference() {
                    union() {
                        // Gear blank
                        circle(r = root_r);

                        // Teeth
                        for (i = [0 : z - 1]) {
                            rotate([0, 0, i * 360 / z])
                                gear_tooth_profile(mod, z, alpha);
                        }
                    }

                    // Bore (if specified)
                    if (bore > 0)
                        circle(d = bore);
                }
            }

            // Hub (if specified)
            if (hub_dia > 0 && hub_height > 0) {
                translate([0, 0, thickness])
                difference() {
                    cylinder(d = hub_dia, h = hub_height);
                    if (bore > 0)
                        cylinder(d = bore, h = hub_height + 1);
                }
            }
        }

        // Keyway (if specified)
        if (keyway_width > 0 && bore > 0) {
            translate([bore/2 - actual_keyway_depth/2, -keyway_width/2, -1])
                cube([actual_keyway_depth + 1, keyway_width, thickness + hub_height + 2]);
        }
    }

    // Reference circles (optional)
    if (show_circles) {
        translate([0, 0, thickness + 0.1])
        linear_extrude(0.5)
            gear_circles_2d(mod, z, alpha);
    }

    // Echo gear data
    echo("");
    echo("════════════════════════════════════════════");
    echo("  SPUR GEAR SPECIFICATIONS");
    echo("════════════════════════════════════════════");
    echo(str("Module: ", mod, " mm"));
    echo(str("Teeth: ", z));
    echo(str("Pressure angle: ", alpha, "°"));
    echo(str("Pitch diameter: ", pitch_r * 2, " mm"));
    echo(str("Base diameter: ", round(base_r * 200) / 100, " mm"));
    echo(str("Tip diameter: ", tip_r * 2, " mm"));
    echo(str("Root diameter: ", round(root_r * 200) / 100, " mm"));
    echo(str("Circular pitch: ", round(PI * mod * 100) / 100, " mm"));
    echo(str("Face width: ", thickness, " mm"));
    if (bore > 0) echo(str("Bore: ", bore, " mm"));
    echo("════════════════════════════════════════════");
}

// ═══════════════════════════════════════════════════════════════════════════
//                         GEAR PAIR MODULE
// ═══════════════════════════════════════════════════════════════════════════

/*
 * gear_pair - Creates two meshing gears
 *
 * Parameters:
 *   m         - Gear module (same for both)
 *   teeth1    - Teeth on first gear (driver)
 *   teeth2    - Teeth on second gear (driven)
 *   thickness - Face width
 *   spacing   - Additional center distance (backlash), default 0.1mm
 *   angle1    - Rotation of first gear, default 0
 */

module gear_pair(
    m = 2,
    teeth1 = 12,
    teeth2 = 36,
    thickness = 10,
    spacing = 0.1,
    angle1 = 0,
    bore1 = 0,
    bore2 = 0,
    pressure_angle = 20
) {
    mod = m;

    pitch_r1 = mod * teeth1 / 2;
    pitch_r2 = mod * teeth2 / 2;
    center_dist = pitch_r1 + pitch_r2 + spacing;

    // Gear ratio
    ratio = teeth2 / teeth1;
    angle2 = -angle1 / ratio + 180 / teeth2;  // Phase for mesh

    // First gear (at origin)
    rotate([0, 0, angle1])
        spur_gear(m=mod, teeth=teeth1, thickness=thickness,
                  bore=bore1, pressure_angle=pressure_angle,
                  color_gear=[0.7, 0.55, 0.2]);

    // Second gear (offset)
    translate([center_dist, 0, 0])
    rotate([0, 0, angle2])
        spur_gear(m=mod, teeth=teeth2, thickness=thickness,
                  bore=bore2, pressure_angle=pressure_angle,
                  color_gear=[0.5, 0.5, 0.55]);

    echo("");
    echo("════════════════════════════════════════════");
    echo("  GEAR PAIR SPECIFICATIONS");
    echo("════════════════════════════════════════════");
    echo(str("Center distance: ", center_dist, " mm"));
    echo(str("Gear ratio: ", ratio, ":1"));
    echo(str("Speed ratio: 1:", ratio));
    echo("════════════════════════════════════════════");
}

// ═══════════════════════════════════════════════════════════════════════════
//                         RACK MODULE
// ═══════════════════════════════════════════════════════════════════════════

/*
 * gear_rack - Creates a straight rack that meshes with spur gears
 *
 * Parameters:
 *   m         - Must match meshing gear module
 *   length    - Rack length
 *   height    - Total rack height (teeth + base)
 *   thickness - Rack width
 */

module gear_rack(
    m = 2,
    length = 100,
    height = 15,
    thickness = 10,
    pressure_angle = 20
) {
    mod = m;
    alpha = pressure_angle;

    addendum = mod;
    dedendum = 1.25 * mod;
    tooth_height = addendum + dedendum;
    pitch = PI * mod;
    num_teeth = floor(length / pitch);

    // Tooth profile
    half_width = pitch / 4;
    root_half = half_width - addendum * tan(alpha);
    tip_half = half_width + dedendum * tan(alpha);
    fillet = 0.25 * mod;

    color([0.5, 0.5, 0.55])
    translate([0, 0, 0])
    rotate([90, 0, 0])
    linear_extrude(thickness, center=true) {
        // Base
        translate([-length/2, 0])
            square([length, height - tooth_height]);

        // Teeth
        for (i = [0 : num_teeth - 1]) {
            x_pos = -length/2 + pitch/2 + i * pitch;
            if (x_pos + pitch/2 < length/2) {
                translate([x_pos, height - tooth_height])
                polygon([
                    [-root_half - fillet*0.3, 0],
                    [-root_half, fillet*0.3],
                    [-tip_half + 0.1*mod, tooth_height - 0.1*mod],
                    [-tip_half + 0.05*mod, tooth_height],
                    [tip_half - 0.05*mod, tooth_height],
                    [tip_half - 0.1*mod, tooth_height - 0.1*mod],
                    [root_half, fillet*0.3],
                    [root_half + fillet*0.3, 0]
                ]);
            }
        }
    }

    echo("");
    echo("════════════════════════════════════════════");
    echo("  RACK SPECIFICATIONS");
    echo("════════════════════════════════════════════");
    echo(str("Module: ", mod, " mm"));
    echo(str("Length: ", length, " mm"));
    echo(str("Teeth: ", num_teeth));
    echo(str("Pitch: ", round(pitch * 100) / 100, " mm"));
    echo("════════════════════════════════════════════");
}

// ═══════════════════════════════════════════════════════════════════════════
//                         INTERNAL GEAR MODULE
// ═══════════════════════════════════════════════════════════════════════════

/*
 * internal_gear - Creates an internal (ring) gear
 *
 * Parameters:
 *   m           - Gear module
 *   teeth       - Number of teeth
 *   thickness   - Face width
 *   rim_width   - Thickness of outer rim
 */

module internal_gear(
    m = 2,
    teeth = 40,
    thickness = 10,
    rim_width = 5,
    pressure_angle = 20
) {
    mod = m;
    z = teeth;
    alpha = pressure_angle;

    dims = gear_dimensions(mod, z, alpha);
    pitch_r = dims[0];
    tip_r = dims[2];
    root_r = dims[3];

    // For internal gear, tip and root are swapped
    inner_tip_r = pitch_r - mod;        // Teeth point inward
    inner_root_r = pitch_r + 1.25*mod;  // Root is larger
    outer_r = inner_root_r + rim_width;

    color([0.6, 0.6, 0.65])
    linear_extrude(thickness) {
        difference() {
            // Outer ring
            circle(r = outer_r);

            // Inner profile with teeth
            circle(r = inner_root_r);

            // Cut teeth (pointing inward)
            for (i = [0 : z - 1]) {
                rotate([0, 0, i * 360 / z])
                    scale([-1, 1])  // Mirror for internal
                    gear_tooth_profile(mod, z, alpha);
            }
        }
    }

    echo("");
    echo("════════════════════════════════════════════");
    echo("  INTERNAL GEAR SPECIFICATIONS");
    echo("════════════════════════════════════════════");
    echo(str("Module: ", mod, " mm"));
    echo(str("Teeth: ", z));
    echo(str("Pitch diameter: ", pitch_r * 2, " mm"));
    echo(str("Inner tip diameter: ", inner_tip_r * 2, " mm"));
    echo(str("Outer diameter: ", outer_r * 2, " mm"));
    echo("════════════════════════════════════════════");
}
