// =========================================================
// FRAME V5.5 — Standalone Frame Render (fast iteration)
// =========================================================
// Renders ONLY the frame — no matrix, no helix cams, no blocks.
// Use this file for fast frame aesthetic iteration.
//
// How it works: uses monolith_v5_5.scad modules directly.
// The `use` directive imports modules/functions without executing
// top-level code, so monolith_v5_5() doesn't auto-run.
// =========================================================

include <config_v5_5.scad>
use <monolith_v5_5.scad>

$fn = 24;

// Call the assembly with frame-only visibility.
// monolith_v5_5() checks SHOW_* variables defined inside the
// monolith file — they default to true. We can't override them
// from here. Instead, we call the frame sub-modules directly.

// --- HEX RINGS ---
_hex_ring_ledge_top();
_hex_ring_ledge_bot();

// --- THREE UNIFIED CORRIDORS ---
// Each = fork + arms + linkage + carrier bridges + dampener buttresses
for (si = [0 : 2])
    _render_corridor(si);

// --- FRAME POSTS ---
_all_frame_posts();

// --- IDLER BRACKETS ---
_all_idler_brackets();

// --- MOTOR BRACKET ---
_motor_bracket();

// --- BUILD PLATE GHOST (optional — uncomment to see) ---
// %cylinder(d=349, h=0.5, center=true, $fn=64);
