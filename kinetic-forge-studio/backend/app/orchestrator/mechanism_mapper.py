"""
Mechanism-to-components mapper.

Translates abstract design specs (mechanism_type + envelope_mm) into
concrete component lists that the GeometryEngine can generate.

Each mechanism type maps to a set of representative shapes (box, cylinder, gear)
sized proportionally to the envelope. These are *visualization* components —
enough for the viewport to show meaningful geometry and gate validators to check
clearances, not production-ready CAD.
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
          id, display_name, component_type, parameters
    """
    mech = spec.get("mechanism_type", "box")
    envelope = float(spec.get("envelope_mm", 70))
    motor_count = int(spec.get("motor_count", 1))

    mapper = _MECHANISM_MAP.get(mech, _default_components)
    return mapper(envelope, motor_count, spec)


# ---------------------------------------------------------------------------
# Per-mechanism component generators
# ---------------------------------------------------------------------------

def _scotch_yoke(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Scotch yoke: crank disc + slotted yoke + slider block."""
    r = envelope * 0.15         # crank radius
    yoke_w = envelope * 0.6     # yoke slot width
    yoke_h = envelope * 0.12    # yoke thickness
    slider_w = envelope * 0.18  # slider block width
    slider_h = envelope * 0.25  # slider block height

    return [
        {
            "id": "crank_disc",
            "display_name": "Crank Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(r, 1), "height": round(yoke_h, 1)},
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
        },
    ]


def _four_bar(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Four-bar linkage: crank + coupler + rocker + ground frame."""
    bar_w = envelope * 0.06     # bar cross-section width
    crank_l = envelope * 0.25
    coupler_l = envelope * 0.45
    rocker_l = envelope * 0.35
    frame_l = envelope * 0.5

    return [
        {
            "id": "crank_bar",
            "display_name": "Crank",
            "component_type": "box",
            "parameters": {"length": round(crank_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
        },
        {
            "id": "coupler_bar",
            "display_name": "Coupler",
            "component_type": "box",
            "parameters": {"length": round(coupler_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
        },
        {
            "id": "rocker_bar",
            "display_name": "Rocker",
            "component_type": "box",
            "parameters": {"length": round(rocker_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
        },
        {
            "id": "ground_frame",
            "display_name": "Ground Frame",
            "component_type": "box",
            "parameters": {"length": round(frame_l, 1), "width": round(bar_w * 2, 1), "height": round(bar_w, 1)},
        },
    ]


def _slider_crank(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Slider-crank: crank disc + connecting rod + piston block."""
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
        },
        {
            "id": "connecting_rod",
            "display_name": "Connecting Rod",
            "component_type": "box",
            "parameters": {"length": round(rod_l, 1), "width": round(bar_w, 1), "height": round(bar_w, 1)},
        },
        {
            "id": "piston_block",
            "display_name": "Piston Block",
            "component_type": "box",
            "parameters": {"length": round(piston_w, 1), "width": round(piston_w, 1), "height": round(piston_h, 1)},
        },
    ]


def _planetary(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Planetary gear set: sun + planets + ring."""
    # Derive from envelope: ring OD ≈ envelope * 0.9
    ring_od = envelope * 0.45
    teeth_ring = spec.get("ring_teeth", 72)
    module = round(ring_od * 2 / teeth_ring, 2)
    teeth_sun = spec.get("sun_teeth", max(12, int(teeth_ring * 0.25)))
    teeth_planet = (teeth_ring - teeth_sun) // 2
    gear_h = max(5, envelope * 0.1)
    planet_count = spec.get("planet_count", 3)

    components = [
        {
            "id": "sun_gear",
            "display_name": "Sun Gear",
            "component_type": "gear",
            "parameters": {"module": module, "teeth": teeth_sun, "height": round(gear_h, 1)},
        },
        {
            "id": "ring_gear",
            "display_name": "Ring Gear",
            "component_type": "gear",
            "parameters": {"module": module, "teeth": teeth_ring, "height": round(gear_h, 1)},
        },
    ]

    for i in range(planet_count):
        components.append({
            "id": f"planet_gear_{i+1}",
            "display_name": f"Planet Gear {i+1}",
            "component_type": "gear",
            "parameters": {"module": module, "teeth": teeth_planet, "height": round(gear_h, 1)},
        })

    return components


def _cam(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Cam mechanism: cam disc + follower rod + base."""
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
        },
        {
            "id": "follower_rod",
            "display_name": "Follower Rod",
            "component_type": "box",
            "parameters": {"length": round(follower_w, 1), "width": round(follower_w, 1), "height": round(follower_h, 1)},
        },
        {
            "id": "cam_base",
            "display_name": "Base Mount",
            "component_type": "box",
            "parameters": {"length": round(base_w, 1), "width": round(base_w, 1), "height": round(cam_h, 1)},
        },
    ]


def _eccentric(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Eccentric drive: offset disc + bearing + frame."""
    disc_r = envelope * 0.2
    disc_h = envelope * 0.1
    bearing_r = disc_r * 0.6
    frame_w = envelope * 0.5

    return [
        {
            "id": "eccentric_disc",
            "display_name": "Eccentric Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(disc_r, 1), "height": round(disc_h, 1)},
        },
        {
            "id": "bearing_ring",
            "display_name": "Bearing Ring",
            "component_type": "cylinder",
            "parameters": {"radius": round(bearing_r, 1), "height": round(disc_h * 0.8, 1)},
        },
        {
            "id": "eccentric_frame",
            "display_name": "Frame",
            "component_type": "box",
            "parameters": {"length": round(frame_w, 1), "width": round(frame_w, 1), "height": round(disc_h * 0.5, 1)},
        },
    ]


def _geneva(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Geneva mechanism: drive wheel + driven wheel."""
    r = envelope * 0.2
    h = envelope * 0.08

    return [
        {
            "id": "drive_wheel",
            "display_name": "Drive Wheel",
            "component_type": "cylinder",
            "parameters": {"radius": round(r, 1), "height": round(h, 1)},
        },
        {
            "id": "driven_wheel",
            "display_name": "Driven Wheel",
            "component_type": "cylinder",
            "parameters": {"radius": round(r * 1.2, 1), "height": round(h, 1)},
        },
    ]


def _default_components(envelope: float, motor_count: int, spec: dict) -> list[dict]:
    """Fallback: base plate + shaft + drive disc."""
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
        },
        {
            "id": "drive_shaft",
            "display_name": "Drive Shaft",
            "component_type": "cylinder",
            "parameters": {"radius": round(shaft_r, 1), "height": round(shaft_h, 1)},
        },
        {
            "id": "drive_disc",
            "display_name": "Drive Disc",
            "component_type": "cylinder",
            "parameters": {"radius": round(disc_r, 1), "height": round(disc_h, 1)},
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
    "cam": _cam,
    "eccentric": _eccentric,
    "geneva": _geneva,
    # Aliases
    "linkage": _four_bar,
    "crank": _slider_crank,
    "gear_train": _planetary,
    "cam_follower": _cam,
}
