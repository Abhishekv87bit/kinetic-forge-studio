// ============================================================
// INVOLUTE MATH — Polar coordinate helper
// ============================================================
// Used by involute_gear_2d and internal_gear_2d.
// ============================================================

function _inv_polar(rb, alpha_deg) =
    let(a_rad = alpha_deg * PI / 180,
        x = rb * (cos(alpha_deg) + a_rad * sin(alpha_deg)),
        y = rb * (sin(alpha_deg) - a_rad * cos(alpha_deg)),
        r = sqrt(x*x + y*y),
        ang = atan2(y, x))
    [r, ang];

// ============================================================
// STANDALONE PREVIEW — pure math, no geometry
// ============================================================
// This file defines only a function. No standalone render.
// Open gear_profiles_2d.scad or gear_primitives_3d.scad to preview.
