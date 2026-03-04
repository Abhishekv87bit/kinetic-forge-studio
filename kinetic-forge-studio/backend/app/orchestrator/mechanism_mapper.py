"""
Mechanism-to-components mapper.

Translates abstract design specs (mechanism_type + envelope_mm) into
concrete component lists that the GeometryEngine can generate.

Each mechanism type maps to a set of representative shapes (box, cylinder, gear)
sized proportionally to the envelope and **positioned** so they don't overlap.
These are *visualization* components — enough for the viewport to show meaningful
geometry and gate validators to check clearances, not production-ready CAD.
"""

from __future__ import annotations

import math
from typing import Any


def spec_to_components(spec: dict[str, Any]) -> list[dict]:
    """
    Convert a completed spec into a list of component dicts ready for
    ComponentManager.register().

    Args:
        spec: The accumulated spec from the Pipeline classifier.
              Expected keys: mechanism_type, envelope_mm, material, motor_count.

    Returns:
        List of dicts, each with:
          id, display_name, component_type, parameters, position
    """
    mech = spec.get("mechanism_type", "box")
    envelope = float(spec.get("envelope_mm", 70))
    motor_count = int(spec.get("motor_count", 1))

    mapper = _MECHANISM_MAP.get(mech, _default_components)
    return mapper(envelope, motor_count, spec)


def _pos(x: float = 0, y: float = 0, z: float = 0) -> dict:
    """Shorthand for a position dict with rounded values."""
    return {"x": round(x, 1), "y": round(y, 1), "z": round(z, 1)}


# ---------------------------------------------------------------------------
# Per-mechanism component generators (all include positions)
# ---------------------------------------------------------------------------

def _scotch_yoke(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Scotch yoke: crank disc at left, yoke in center, slider at right."""
    r = envelope * 0.15
    yoke_w = envelope * 0.6
    yoke_h = envelope * 0.12
    slider_w = envelope * 0.18
    slider_h = envelope * 0.25

    return [
        {
            "id": "crank_disc",
            "display_name": "Crank Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(r, 1), "height": round(yoke_h, 1)},
            "position": _pos(x=-yoke_w * 0.4),
        },
        {
            "id": "yoke_body",
            "display_name": "Yoke Body",
            "component_type": "box",
            "parameters": {
                "length": round(yoke_w, 1),
                "width": round(yoke_h, 1),
                "height": round(slider_h, 1),
            },
            "position": _pos(x=0),
        },
        {
            "id": "slider_block",
            "display_name": "Slider Block",
            "component_type": "box",
            "parameters": {
                "length": round(slider_w, 1),
                "width": round(slider_w, 1),
                "height": round(slider_h, 1),
            },
            "position": _pos(x=yoke_w * 0.4),
        },
    ]


def _four_bar(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Four-bar linkage: ground at bottom, crank left, coupler top, rocker right."""
    bar_w = envelope * 0.06
    crank_l = envelope * 0.25
    coupler_l = envelope * 0.45
    rocker_l = envelope * 0.35
    frame_l = envelope * 0.5
    spacing = envelope * 0.2

    return [
        {
            "id": "ground_frame",
            "display_name": "Ground Frame",
            "component_type": "box",
            "parameters": {"length": round(frame_l, 1), "width": round(bar_w * 2, 1), "height": round(bar_w, 1)},
            "position": _pos(y=-spacing),
        },
        {
            "id": "crank_bar",
            "display_name": "Crank",
            "component_type": "box",
            "parameters": {"length": round(crank_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
            "position": _pos(x=-frame_l * 0.3, y=0),
        },
        {
            "id": "coupler_bar",
            "display_name": "Coupler",
            "component_type": "box",
            "parameters": {"length": round(coupler_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
            "position": _pos(y=spacing),
        },
        {
            "id": "rocker_bar",
            "display_name": "Rocker",
            "component_type": "box",
            "parameters": {"length": round(rocker_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
            "position": _pos(x=frame_l * 0.3, y=0),
        },
    ]


def _slider_crank(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Slider-crank: crank at left, rod in middle, piston at right."""
    r = envelope * 0.12
    rod_l = envelope * 0.4
    bar_w = envelope * 0.05
    piston_w = envelope * 0.15
    piston_h = envelope * 0.2

    return [
        {
            "id": "crank_disc",
            "display_name": "Crank Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(r, 1), "height": round(bar_w * 2, 1)},
            "position": _pos(x=-rod_l * 0.6),
        },
        {
            "id": "connecting_rod",
            "display_name": "Connecting Rod",
            "component_type": "box",
            "parameters": {"length": round(rod_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
            "position": _pos(x=0),
        },
        {
            "id": "piston_block",
            "display_name": "Piston Block",
            "component_type": "box",
            "parameters": {"length": round(piston_w, 1), "width": round(piston_w, 1), "height": round(piston_h, 1)},
            "position": _pos(x=rod_l * 0.6),
        },
    ]


def _planetary(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Planetary gear set: sun at center, planets at orbital radius, ring concentric."""
    ring_od = envelope * 0.45
    teeth_ring = spec.get("ring_teeth", 72)
    module = round(ring_od * 2 / teeth_ring, 2)
    teeth_sun = spec.get("sun_teeth", max(12, int(teeth_ring * 0.25)))
    teeth_planet = (teeth_ring - teeth_sun) // 2
    gear_h = max(5, envelope * 0.1)
    planet_count = spec.get("planet_count", 3)

    # Orbital radius: midpoint between sun OD and ring ID
    sun_pitch_r = module * teeth_sun / 2
    planet_pitch_r = module * teeth_planet / 2
    orbital_r = sun_pitch_r + planet_pitch_r

    components = [
        {
            "id": "sun_gear",
            "display_name": "Sun Gear",
            "component_type": "gear",
            "parameters": {"module": module, "teeth": teeth_sun, "height": round(gear_h, 1)},
            "position": _pos(),
        },
        {
            "id": "ring_gear",
            "display_name": "Ring Gear",
            "component_type": "gear",
            "parameters": {"module": module, "teeth": teeth_ring, "height": round(gear_h, 1)},
            "position": _pos(),  # concentric with sun
        },
    ]

    for i in range(planet_count):
        angle = 2 * math.pi * i / planet_count
        px = orbital_r * math.cos(angle)
        py = orbital_r * math.sin(angle)
        components.append({
            "id": f"planet_gear_{i+1}",
            "display_name": f"Planet Gear {i+1}",
            "component_type": "gear",
            "parameters": {"module": module, "teeth": teeth_planet, "height": round(gear_h, 1)},
            "position": _pos(x=px, y=py),
        })

    return components


def _cam(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Cam mechanism: cam at center, follower above, base below."""
    cam_r = envelope * 0.2
    cam_h = envelope * 0.08
    follower_w = envelope * 0.05
    follower_h = envelope * 0.4
    base_w = envelope * 0.35

    return [
        {
            "id": "cam_disc",
            "display_name": "Cam Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(cam_r, 1), "height": round(cam_h, 1)},
            "position": _pos(),
        },
        {
            "id": "follower_rod",
            "display_name": "Follower Rod",
            "component_type": "box",
            "parameters": {"length": round(follower_w, 1), "width": round(follower_w, 1), "height": round(follower_h, 1)},
            "position": _pos(y=cam_r + follower_h * 0.5 + 2),
        },
        {
            "id": "cam_base",
            "display_name": "Base Mount",
            "component_type": "box",
            "parameters": {"length": round(base_w, 1), "width": round(base_w, 1), "height": round(cam_h, 1)},
            "position": _pos(z=-cam_h - 2),
        },
    ]


def _eccentric(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Eccentric drive: disc offset from bearing, frame below."""
    disc_r = envelope * 0.2
    disc_h = envelope * 0.1
    bearing_r = disc_r * 0.6
    frame_w = envelope * 0.5
    offset = disc_r * 0.3  # eccentric offset

    return [
        {
            "id": "eccentric_disc",
            "display_name": "Eccentric Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(disc_r, 1), "height": round(disc_h, 1)},
            "position": _pos(x=offset),
        },
        {
            "id": "bearing_ring",
            "display_name": "Bearing Ring",
            "component_type": "cylinder",
            "parameters": {"radius": round(bearing_r, 1), "height": round(disc_h * 0.8, 1)},
            "position": _pos(),
        },
        {
            "id": "eccentric_frame",
            "display_name": "Frame",
            "component_type": "box",
            "parameters": {"length": round(frame_w, 1), "width": round(frame_w, 1), "height": round(disc_h * 0.5, 1)},
            "position": _pos(z=-disc_h - 2),
        },
    ]


def _geneva(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Geneva mechanism: drive and driven wheels side by side."""
    r = envelope * 0.2
    h = envelope * 0.08
    spacing = r * 2.5  # center-to-center distance

    return [
        {
            "id": "drive_wheel",
            "display_name": "Drive Wheel",
            "component_type": "cylinder",
            "parameters": {"radius": round(r, 1), "height": round(h, 1)},
            "position": _pos(x=-spacing * 0.5),
        },
        {
            "id": "driven_wheel",
            "display_name": "Driven Wheel",
            "component_type": "cylinder",
            "parameters": {"radius": round(r * 1.2, 1), "height": round(h, 1)},
            "position": _pos(x=spacing * 0.5),
        },
    ]


def _rack_and_pinion(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """
    Rack and pinion: pinion gear meshed with a linear rack.

    The pinion sits above the rack with teeth engaged. A mounting bracket
    holds the pinion shaft. Module is derived from envelope to give
    reasonable proportions.

    Gear math:
      - Pinion pitch radius = module * teeth / 2
      - Rack length = num_rack_teeth * pi * module
      - Mesh distance = pinion pitch radius (tooth tips at pitch line)
    """
    pinion_teeth = spec.get("pinion_teeth", 16)
    rack_teeth = spec.get("rack_teeth", 12)
    # Module sized so pinion OD fits ~40% of envelope
    module = round(envelope * 0.4 / pinion_teeth, 2)
    module = max(0.5, module)
    gear_h = max(5, round(envelope * 0.12, 1))
    body_h = max(6, round(envelope * 0.15, 1))

    pitch_radius = module * pinion_teeth / 2.0

    # Positions: rack at bottom, pinion above at mesh distance
    # Pinion center sits at y = pitch_radius above the rack pitch line
    rack_y = 0.0
    pinion_y = pitch_radius + module  # addendum clearance

    bracket_w = round(envelope * 0.15, 1)
    bracket_h = round(envelope * 0.25, 1)
    bracket_d = round(gear_h * 0.6, 1)

    return [
        {
            "id": "rack",
            "display_name": "Rack",
            "component_type": "rack",
            "parameters": {
                "module": module,
                "num_teeth": rack_teeth,
                "height": round(gear_h, 1),
                "body_height": round(body_h, 1),
            },
            "position": _pos(y=rack_y),
        },
        {
            "id": "pinion",
            "display_name": "Pinion Gear",
            "component_type": "gear",
            "parameters": {
                "module": module,
                "teeth": pinion_teeth,
                "height": round(gear_h, 1),
            },
            "position": _pos(y=pinion_y),
        },
        {
            "id": "pinion_shaft",
            "display_name": "Pinion Shaft",
            "component_type": "cylinder",
            "parameters": {
                "radius": round(module * 1.5, 1),
                "height": round(gear_h * 2, 1),
            },
            "position": _pos(y=pinion_y, z=gear_h * 0.5),
        },
        {
            "id": "mount_bracket",
            "display_name": "Mounting Bracket",
            "component_type": "box",
            "parameters": {
                "length": round(bracket_w, 1),
                "width": round(bracket_h, 1),
                "height": round(bracket_d, 1),
            },
            "position": _pos(y=pinion_y + pitch_radius * 0.5, z=-gear_h),
        },
    ]


def _default_components(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Fallback: base plate below, shaft on top, disc at top."""
    plate_w = envelope * 0.5
    plate_h = envelope * 0.04
    shaft_r = envelope * 0.03
    shaft_h = envelope * 0.3
    disc_r = envelope * 0.15
    disc_h = envelope * 0.06

    return [
        {
            "id": "base_plate",
            "display_name": "Base Plate",
            "component_type": "box",
            "parameters": {"length": round(plate_w, 1), "width": round(plate_w, 1), "height": round(plate_h, 1)},
            "position": _pos(z=-plate_h),
        },
        {
            "id": "drive_shaft",
            "display_name": "Drive Shaft",
            "component_type": "cylinder",
            "parameters": {"radius": round(shaft_r, 1), "height": round(shaft_h, 1)},
            "position": _pos(z=shaft_h * 0.5),
        },
        {
            "id": "drive_disc",
            "display_name": "Drive Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(disc_r, 1), "height": round(disc_h, 1)},
            "position": _pos(z=shaft_h + disc_h * 0.5),
        },
    ]


def _wave(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """
    Wave mechanism: a row of cams on a shared shaft with phase offsets
    that produce a sinusoidal ripple across the top surface.

    Components: base plate, drive shaft, and a set of cam discs.
    """
    num_cams = spec.get("cam_count", 5)
    cam_r = envelope * 0.08
    cam_h = envelope * 0.06
    shaft_r = envelope * 0.02
    shaft_l = envelope * 0.6
    plate_w = shaft_l + cam_r * 4
    plate_h = envelope * 0.03
    spacing = shaft_l / max(num_cams - 1, 1)

    components: list[dict] = [
        {
            "id": "wave_base",
            "display_name": "Base Plate",
            "component_type": "box",
            "parameters": {
                "length": round(plate_w, 1),
                "width": round(plate_w * 0.4, 1),
                "height": round(plate_h, 1),
            },
            "position": _pos(z=-plate_h),
        },
        {
            "id": "wave_shaft",
            "display_name": "Drive Shaft",
            "component_type": "cylinder",
            "parameters": {"radius": round(shaft_r, 1), "height": round(shaft_l, 1)},
            "position": _pos(z=cam_r),
        },
    ]

    start_x = -shaft_l / 2
    for i in range(num_cams):
        cx = start_x + i * spacing
        components.append({
            "id": f"wave_cam_{i+1}",
            "display_name": f"Wave Cam {i+1}",
            "component_type": "cylinder",
            "parameters": {"radius": round(cam_r, 1), "height": round(cam_h, 1)},
            "position": _pos(x=cx, z=cam_r),
        })

    return components


def _ratchet(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """
    Ratchet mechanism: ratchet wheel with a pawl arm and mounting base.

    The pawl engages the wheel's teeth to allow one-way rotation.
    """
    wheel_r = envelope * 0.2
    wheel_h = envelope * 0.08
    teeth = spec.get("ratchet_teeth", 12)
    pawl_l = envelope * 0.25
    pawl_w = envelope * 0.04
    base_w = envelope * 0.5
    base_h = envelope * 0.03
    pivot_r = envelope * 0.03

    return [
        {
            "id": "ratchet_base",
            "display_name": "Base Plate",
            "component_type": "box",
            "parameters": {
                "length": round(base_w, 1),
                "width": round(base_w, 1),
                "height": round(base_h, 1),
            },
            "position": _pos(z=-base_h),
        },
        {
            "id": "ratchet_wheel",
            "display_name": "Ratchet Wheel",
            "component_type": "gear",
            "parameters": {
                "module": round(wheel_r * 2 / max(teeth, 6), 2),
                "teeth": teeth,
                "height": round(wheel_h, 1),
            },
            "position": _pos(),
        },
        {
            "id": "pawl_arm",
            "display_name": "Pawl Arm",
            "component_type": "box",
            "parameters": {
                "length": round(pawl_l, 1),
                "width": round(pawl_w, 1),
                "height": round(wheel_h, 1),
            },
            "position": _pos(x=wheel_r + pawl_l * 0.3, y=0),
        },
        {
            "id": "pawl_pivot",
            "display_name": "Pawl Pivot",
            "component_type": "cylinder",
            "parameters": {
                "radius": round(pivot_r, 1),
                "height": round(wheel_h * 1.5, 1),
            },
            "position": _pos(x=wheel_r + pawl_l * 0.7),
        },
    ]


def _belt_drive(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """
    Belt and pulley drive: two pulleys connected by a belt representation.

    The driver and driven pulleys are spaced apart, with a connecting bar
    representing the belt path between them.
    """
    driver_r = envelope * 0.1
    driven_r = envelope * 0.15
    pulley_h = envelope * 0.08
    shaft_r = envelope * 0.025
    shaft_h = pulley_h * 2
    spacing = envelope * 0.4  # center-to-center
    belt_w = envelope * 0.03
    base_w = spacing + driven_r * 3
    base_h = envelope * 0.03
    # Clearance gap between base plate top and component bottoms
    gap = 2.0

    return [
        {
            "id": "belt_base",
            "display_name": "Base Plate",
            "component_type": "box",
            "parameters": {
                "length": round(base_w, 1),
                "width": round(base_w * 0.4, 1),
                "height": round(base_h, 1),
            },
            "position": _pos(z=-(base_h + gap)),
        },
        {
            "id": "driver_pulley",
            "display_name": "Driver Pulley",
            "component_type": "cylinder",
            "parameters": {"radius": round(driver_r, 1), "height": round(pulley_h, 1)},
            "position": _pos(x=-spacing * 0.5),
        },
        {
            "id": "driver_shaft",
            "display_name": "Driver Shaft",
            "component_type": "cylinder",
            "parameters": {"radius": round(shaft_r, 1), "height": round(shaft_h, 1)},
            "position": _pos(x=-spacing * 0.5),
        },
        {
            "id": "driven_pulley",
            "display_name": "Driven Pulley",
            "component_type": "cylinder",
            "parameters": {"radius": round(driven_r, 1), "height": round(pulley_h, 1)},
            "position": _pos(x=spacing * 0.5),
        },
        {
            "id": "driven_shaft",
            "display_name": "Driven Shaft",
            "component_type": "cylinder",
            "parameters": {"radius": round(shaft_r, 1), "height": round(shaft_h, 1)},
            "position": _pos(x=spacing * 0.5),
        },
        {
            "id": "belt_top",
            "display_name": "Belt (top span)",
            "component_type": "box",
            "parameters": {
                "length": round(spacing, 1),
                "width": round(belt_w, 1),
                "height": round(belt_w, 1),
            },
            "position": _pos(y=max(driver_r, driven_r) + belt_w),
        },
        {
            "id": "belt_bottom",
            "display_name": "Belt (bottom span)",
            "component_type": "box",
            "parameters": {
                "length": round(spacing, 1),
                "width": round(belt_w, 1),
                "height": round(belt_w, 1),
            },
            "position": _pos(y=-(max(driver_r, driven_r) + belt_w)),
        },
    ]


# ---------------------------------------------------------------------------
# Lookup table: mechanism_type string → generator function
# ---------------------------------------------------------------------------

_MECHANISM_MAP = {
    "scotch_yoke": _scotch_yoke,
    "four_bar": _four_bar,
    "slider_crank": _slider_crank,
    "planetary": _planetary,
    "rack_and_pinion": _rack_and_pinion,
    "cam": _cam,
    "eccentric": _eccentric,
    "geneva": _geneva,
    "wave": _wave,
    "ratchet": _ratchet,
    "belt_drive": _belt_drive,
    # Aliases
    "linkage": _four_bar,
    "crank": _slider_crank,
    "gear_train": _planetary,
    "cam_follower": _cam,
    "rack_pinion": _rack_and_pinion,
    "rack": _rack_and_pinion,
    "pinion": _rack_and_pinion,
    "pulley": _belt_drive,
    "belt": _belt_drive,
}
