// ============================================================
// 2D GEAR PROFILES — External + Internal involute
// ============================================================
// Hand-rolled involute profiles (no BOSL2 dependency).
// ============================================================

include <involute_math.scad>

// --- External involute gear 2D profile ---
module involute_gear_2d(teeth, mod, pressure_angle=20, clearance=0.25) {
    pitch_r  = teeth * mod / 2;
    base_r   = pitch_r * cos(pressure_angle);
    tip_r    = pitch_r + mod;
    root_r   = pitch_r - 1.25 * mod;

    alpha_tip = (base_r < tip_r) ? acos(base_r / tip_r) : 0;

    half_tooth_deg = (PI * mod / 2) / pitch_r * (180 / PI) / 2;

    pitch_polar = _inv_polar(base_r, pressure_angle);
    inv_ang_at_pitch = pitch_polar[1];

    right_offset = half_tooth_deg - inv_ang_at_pitch;

    steps = 30;

    tip_polar = _inv_polar(base_r, alpha_tip);
    right_tip_ang = tip_polar[1] + right_offset;
    left_tip_ang = -right_tip_ang;

    union() {
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * 360 / teeth])
            polygon(
                concat(
                    [[root_r * cos(-180/teeth), root_r * sin(-180/teeth)],
                     [root_r * cos(right_offset), root_r * sin(right_offset)]],

                    [for (s = [0:steps])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = p[1] + right_offset)
                        [r * cos(ang), r * sin(ang)]
                    ],

                    [for (s = [1:3])
                        let(ang = right_tip_ang + s * (left_tip_ang - right_tip_ang) / 4)
                        [tip_r * cos(ang), tip_r * sin(ang)]
                    ],

                    [for (s = [steps:-1:0])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = -(p[1] + right_offset))
                        [r * cos(ang), r * sin(ang)]
                    ],

                    [[root_r * cos(-right_offset), root_r * sin(-right_offset)],
                     [root_r * cos(180/teeth), root_r * sin(180/teeth)]]
                )
            );
        }
        circle(r=root_r, $fn=teeth * 8);
    }
}

// --- Internal involute gear 2D profile (boolean subtraction) ---
// Internal teeth: subtract external profile from annular blank.
// Root of internal gear is outward, tip is inward.
module internal_gear_2d(teeth, mod, pressure_angle=20, clearance=0.25) {
    pitch_r  = teeth * mod / 2;
    // Internal root radius = outward (dedendum outward from pitch)
    int_root_r = pitch_r + 1.25 * mod;

    difference() {
        circle(r = int_root_r, $fn = teeth * 4);
        involute_gear_2d(teeth, mod, pressure_angle, clearance);
    }
}

// ============================================================
// STANDALONE PREVIEW
// ============================================================
$fn = 64;
color("SteelBlue")
involute_gear_2d(teeth=31, mod=1.0, pressure_angle=20);

translate([60, 0, 0])
color("Tomato")
internal_gear_2d(teeth=88, mod=1.0, pressure_angle=20);
