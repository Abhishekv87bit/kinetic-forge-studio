// ============================================================
// TEST GEAR MESH HARNESS — Phase 0
// Gate: This MUST compile + animate clean before anything else.
// ============================================================
// Three test cells, toggled by Customizer:
//   1. External spur mesh: 13T + 8T
//   2. Internal ring mesh: 29T ring + 8T planet
//   3. Full planetary: Sun(13) + 3×Planet(8) + Ring(29)
// All use BOSL2 gear_spin for phasing — NO hand-computed angles.
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

/* [Test Selection] */
SHOW_EXTERNAL_MESH = true;
SHOW_INTERNAL_MESH = false;
SHOW_FULL_PLANETARY = false;

/* [Animation] */
// Use $t for OpenSCAD animation, or this slider for manual
MANUAL_POSITION = 0.0; // [0:0.01:1]
USE_MANUAL = true;

/* [Parameters] */
MOD = 1.0;
PA = 20;
GFW = 6;        // gear face width
BACKLASH = 0.21;

// Stage 1 tooth counts
S1_T = 13;
P1_T = 8;
R1_T = 29;  // 13 + 2*8 = 29 ✓

$fn = 64;

// ============================================================
// Derived values
// ============================================================
T = USE_MANUAL ? MANUAL_POSITION : $t;
ANIM_DEG = T * 360;  // one full sun rotation per animation cycle

// Center distances (no profile shift — all zero)
SUN_PLANET_CD = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                          profile_shift1=0, profile_shift2=0);
// For internal mesh: planet center to ring center
PLANET_RING_CD = gear_dist(mod=MOD, teeth1=R1_T, teeth2=P1_T,
                          internal1=true,
                          profile_shift1=0, profile_shift2=0);

echo("=== PHASE 0 PARAMETERS ===");
echo(SUN_PLANET_CD=SUN_PLANET_CD);
echo(PLANET_RING_CD=PLANET_RING_CD);
echo(str("ORBs match: ", SUN_PLANET_CD == PLANET_RING_CD ? "YES" : "NO"));

// ============================================================
// CELL 1: External Spur Mesh — 13T + 8T
// ============================================================
// Canonical BOSL2 pattern from gears.scad:4291-4295:
//   spur_gear(teeth=T1, gear_spin=-90);
//   right(d) spur_gear(teeth=T2, gear_spin=90-180/T2);
// With animation: gear1 rotates by ANIM_DEG, gear2 counter-rotates by ratio.

module cell_external_mesh() {
    d = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                  profile_shift1=0, profile_shift2=0);
    ratio = S1_T / P1_T;  // 13/8 = 1.625

    // Gear 1 (sun) — red
    color("red")
    spur_gear(
        mod=MOD, teeth=S1_T,
        pressure_angle=PA,
        thickness=GFW,
        backlash=BACKLASH/2,
        gear_spin=-90 + ANIM_DEG
    );

    // Gear 2 (planet) — green
    color("green")
    right(d)
    spur_gear(
        mod=MOD, teeth=P1_T,
        pressure_angle=PA,
        thickness=GFW,
        backlash=BACKLASH/2,
        gear_spin=90 - 180/P1_T - ANIM_DEG * ratio
    );

    // Visual: center distance line
    color("gray", 0.3)
    translate([0, 0, -1])
    linear_extrude(0.5)
    hull() {
        circle(0.3);
        translate([d, 0, 0]) circle(0.3);
    }
}

// ============================================================
// CELL 2: Internal Ring Mesh — 29T ring + 8T planet
// ============================================================
// Ring uses gear_spin. Planet placed at orbit distance inside ring.
// From BOSL2 example (gears.scad:1543-1548):
//   dist = gear_dist(teeth1=ring, teeth2=planet, internal1=true);
//   ring_gear(teeth=ring);
//   back(dist) spur_gear(teeth=planet);

module cell_internal_mesh() {
    // Distance from ring center to planet center
    d = gear_dist(mod=MOD, teeth1=R1_T, teeth2=P1_T,
                  internal1=true, profile_shift1=0, profile_shift2=0);
    ratio = R1_T / P1_T;  // 29/8 = 3.625

    echo(str("Internal mesh CD = ", d, " (should equal sun-planet CD = ", SUN_PLANET_CD, ")"));

    // Ring gear — blue, static
    color("blue", 0.5)
    ring_gear(
        mod=MOD, teeth=R1_T,
        pressure_angle=PA,
        thickness=GFW,
        backing=3,
        backlash=BACKLASH/2,
        gear_spin=0
    );

    // Planet — green, orbiting inside ring
    // For this test, planet stays at fixed position, just self-rotates
    color("green")
    back(d)
    spur_gear(
        mod=MOD, teeth=P1_T,
        pressure_angle=PA,
        thickness=GFW,
        backlash=BACKLASH/2,
        gear_spin=ANIM_DEG  // planet self-rotation
    );
}

// ============================================================
// CELL 3: Full Planetary — Sun(13) + 3×Planet(8) + Ring(29)
// ============================================================
// Uses BOSL2 planetary_gears() to get correct phasing, then
// applies differential animation on top.
//
// From BOSL2 source (gears.scad:3688):
//   planet_spin_i = (S/P)*(orbit_angle_i - 90) + 90 + orbit_angle_i + 180/P/2 + planet_spin
// From BOSL2 source (gears.scad:3699):
//   ring_spin = 180/R/2 * (1 - (S%2))
//
// For animation with carrier rotating by CARRIER_DEG:
//   - Sun rotates by ANIM_DEG (input)
//   - Carrier rotates by CARRIER_DEG = ANIM_DEG * S/(S+R) [ring fixed]
//   - Planet self-spin = -(ANIM_DEG - CARRIER_DEG) * S/P

module cell_full_planetary() {
    // Direct formulas from BOSL2 gears.scad lines 3685-3699
    // We know our tooth counts, so we apply the phasing formulas directly.
    //
    // Planet spacing quantization: quant = 360/(S+R)
    // Planet angles: evenly spaced, quantized to mesh constraint
    // Planet spin at angle_i: (S/P)*(angle_i - 90) + 90 + angle_i + 180/P
    // Ring spin: 180/R * (1 - (S%2))
    // Sun spin: 0 (reference, with gear_spin applied)

    orbit_r = SUN_PLANET_CD;  // = (S+P)*MOD/2 = 10.5

    // Planet angle quantization
    quant = 360 / (S1_T + R1_T);  // 360/42 = 8.571°
    // 3 planets at 120° apart, quantized
    planet_angles = [for (i = [0:2])
        let(raw = i * 120)
        quant * round(raw / quant)
    ];

    // Static phasing (zero animation)
    sun_spin0 = 0;  // sun is reference
    ring_spin0 = 180/R1_T * (1 - (S1_T % 2));  // S1=13 is odd → (1-1)=0 → ring_spin0=0

    // Planet static spins (from gears.scad:3688)
    // planet_spin_i = (S/P)*(angle_i - 90) + 90 + angle_i + 180/P
    planet_spins0 = [for (ang = planet_angles)
        (S1_T/P1_T) * (ang - 90) + 90 + ang + 180/P1_T
    ];

    echo("=== PLANETARY PHASING (direct formulas) ===");
    echo(planet_angles=planet_angles);
    echo(sun_spin0=sun_spin0);
    echo(ring_spin0=ring_spin0);
    echo(planet_spins0=planet_spins0);
    echo(orbit_r=orbit_r);
    echo(quant=quant);

    // Animation: ring is FIXED, sun is input
    // Carrier angular velocity = sun_input * S/(S+R) [ring fixed]
    CARRIER_DEG = ANIM_DEG * S1_T / (S1_T + R1_T);
    // Planet self-spin relative to carrier frame
    PLANET_SELF = -(ANIM_DEG - CARRIER_DEG) * S1_T / P1_T;

    // --- Sun gear (red) ---
    color("red")
    spur_gear(
        mod=MOD, teeth=S1_T,
        pressure_angle=PA,
        thickness=GFW,
        profile_shift=0,
        backlash=BACKLASH/2,
        gear_spin=sun_spin0 + ANIM_DEG
    );

    // --- Ring gear (blue) — FIXED ---
    color("blue", 0.4)
    ring_gear(
        mod=MOD, teeth=R1_T,
        pressure_angle=PA,
        thickness=GFW,
        backing=3,
        profile_shift=0,
        backlash=BACKLASH/2,
        gear_spin=ring_spin0
    );

    // --- Planets (green) — orbit with carrier, self-rotate ---
    for (i = [0:2]) {
        orbit_angle_i = planet_angles[i];
        planet_spin0_i = planet_spins0[i];

        // Carrier rotation shifts the orbit angle
        current_orbit = orbit_angle_i + CARRIER_DEG;

        // Planet position on orbit
        px = orbit_r * cos(current_orbit);
        py = orbit_r * sin(current_orbit);

        color("green")
        translate([px, py, 0])
        spur_gear(
            mod=MOD, teeth=P1_T,
            pressure_angle=PA,
            thickness=GFW,
            profile_shift=0,
            backlash=BACKLASH/2,
            gear_spin=planet_spin0_i + PLANET_SELF
        );
    }

    // --- Carrier plate (orange, thin) ---
    color("orange", 0.3)
    translate([0, 0, GFW/2 + 0.5])
    linear_extrude(1) {
        circle(orbit_r + 3);
        for (i = [0:2]) {
            current_orbit = planet_angles[i] + CARRIER_DEG;
            translate([orbit_r * cos(current_orbit), orbit_r * sin(current_orbit)])
            circle(1.5);
        }
    }
}

// ============================================================
// LAYOUT
// ============================================================
CELL_SPACING = 50;

if (SHOW_EXTERNAL_MESH) {
    translate([-CELL_SPACING, 0, 0])
    cell_external_mesh();
}

if (SHOW_INTERNAL_MESH) {
    cell_internal_mesh();
}

if (SHOW_FULL_PLANETARY) {
    translate([CELL_SPACING, 0, 0])
    cell_full_planetary();
}
