"""
Collision detection validator for kinetic sculpture assemblies.

Uses trimesh's CollisionManager (backed by python-fcl if available,
otherwise falls back to AABB overlap checks).

Each mesh is given a name and a 4x4 transform. The validator checks
all pairs and returns a pass/fail result with details on which
pairs collide.
"""

from dataclasses import dataclass, field
from typing import Any

import numpy as np
import trimesh


@dataclass
class CollisionResult:
    """Result of a collision check between assembly meshes."""
    passed: bool
    collisions: list[dict] = field(default_factory=list)
    mesh_count: int = 0
    pairs_checked: int = 0
    message: str = ""

    def to_dict(self) -> dict:
        return {
            "validator": "collision",
            "passed": self.passed,
            "collisions": self.collisions,
            "mesh_count": self.mesh_count,
            "pairs_checked": self.pairs_checked,
            "message": self.message,
        }


def _aabb_overlap(
    mesh_a: trimesh.Trimesh,
    transform_a: np.ndarray,
    mesh_b: trimesh.Trimesh,
    transform_b: np.ndarray,
) -> bool:
    """
    Check axis-aligned bounding box overlap between two meshes.

    This is a fast conservative check: if AABBs don't overlap, meshes
    definitely don't collide. If they do overlap, there *might* be
    a collision (false positives possible).
    """
    # Apply transforms to get world-space bounds
    verts_a = trimesh.transform_points(mesh_a.vertices, transform_a)
    verts_b = trimesh.transform_points(mesh_b.vertices, transform_b)

    min_a = verts_a.min(axis=0)
    max_a = verts_a.max(axis=0)
    min_b = verts_b.min(axis=0)
    max_b = verts_b.max(axis=0)

    # AABB overlap test: overlap on ALL three axes
    return bool(
        (min_a[0] <= max_b[0] and max_a[0] >= min_b[0])
        and (min_a[1] <= max_b[1] and max_a[1] >= min_b[1])
        and (min_a[2] <= max_b[2] and max_a[2] >= min_b[2])
    )


def _is_intentional_contact(name_a: str, name_b: str, component_types: dict[str, str]) -> str | None:
    """
    Check if two components have intentional physical contact.

    Returns exemption type string if the pair should be exempted,
    or None if it's a real collision.

    Exempted pairs:
      - gear + gear: teeth mesh (sun/planet, planet/ring, drive/driven)
      - gear + rack: rack-and-pinion engagement
      - gear + pawl: ratchet pawl engaging wheel teeth
      - cylinder + gear: shaft through gear bore
      - cylinder + cylinder: shaft through bearing / pulley on shaft
      - belt + pulley: belt wrapping around pulley
      - base/frame/mount + anything: mounting/support contact
    """
    type_a = component_types.get(name_a, "")
    type_b = component_types.get(name_b, "")
    types = frozenset([type_a, type_b])
    na, nb = name_a.lower(), name_b.lower()

    # Gear-to-gear mesh (planetary, gear trains, ratchet wheel)
    if type_a == "gear" and type_b == "gear":
        return "gear_mesh"

    # Rack-to-gear mesh (rack and pinion)
    if types == frozenset(["gear", "rack"]):
        return "rack_gear_mesh"

    # Shaft through gear bore (pinion_shaft + pinion, drive_shaft + gear)
    shaft_words = ("shaft", "axle", "spindle", "pin")
    if types == frozenset(["cylinder", "gear"]):
        if any(s in na for s in shaft_words) or any(s in nb for s in shaft_words):
            return "shaft_through_gear"

    # Shaft through bearing / pulley-on-shaft / cam-on-shaft
    if type_a == "cylinder" and type_b == "cylinder":
        bearing_words = ("bearing", "pulley", "bushing", "ring", "cam", "disc")
        a_shaft = any(s in na for s in shaft_words)
        b_shaft = any(s in nb for s in shaft_words)
        a_bearing = any(s in na for s in bearing_words)
        b_bearing = any(s in nb for s in bearing_words)
        if (a_shaft and b_bearing) or (b_shaft and a_bearing):
            return "shaft_through_bearing"

    # Eccentric disc inside bearing ring
    if type_a == "cylinder" and type_b == "cylinder":
        if ("eccentric" in na and "bearing" in nb) or ("eccentric" in nb and "bearing" in na):
            return "eccentric_in_bearing"

    # Pawl engaging ratchet wheel
    if ("pawl" in na or "pawl" in nb):
        other = nb if "pawl" in na else na
        if "ratchet" in other or "wheel" in other or type_a == "gear" or type_b == "gear":
            return "pawl_engagement"

    # Belt touching pulley
    if ("belt" in na and "pulley" in nb) or ("belt" in nb and "pulley" in na):
        return "belt_on_pulley"

    # Base plate / frame / mount contacts adjacent components (mounting)
    mount_words = ("base", "frame", "mount", "bracket", "plate")
    a_is_mount = any(s in na for s in mount_words)
    b_is_mount = any(s in nb for s in mount_words)
    if a_is_mount or b_is_mount:
        return "mount_contact"

    return None


def check_collisions(
    meshes: list[tuple[str, trimesh.Trimesh, np.ndarray | None]],
    component_types: dict[str, str] | None = None,
) -> CollisionResult:
    """
    Check for collisions among a list of named meshes.

    Args:
        meshes: List of (name, trimesh.Trimesh, optional 4x4 transform).
                If transform is None, identity is used.
        component_types: Optional dict mapping component name → type string.
                         Used to exempt intentional contact pairs (gear mesh,
                         rack-gear, shaft-through-gear, belt-on-pulley, etc.).

    Returns:
        CollisionResult with pass/fail and collision details.
    """
    if len(meshes) < 2:
        return CollisionResult(
            passed=True,
            mesh_count=len(meshes),
            pairs_checked=0,
            message="Need at least 2 meshes to check collisions.",
        )

    component_types = component_types or {}

    # Normalize transforms
    entries: list[tuple[str, trimesh.Trimesh, np.ndarray]] = []
    for name, mesh, transform in meshes:
        if transform is None:
            transform = np.eye(4)
        entries.append((name, mesh, transform))

    collisions_found: list[dict] = []
    exempted: list[dict] = []

    # Try trimesh.collision.CollisionManager first (uses FCL if available)
    try:
        manager = trimesh.collision.CollisionManager()
        for name, mesh, transform in entries:
            manager.add_object(name, mesh, transform=transform)

        is_collision, contact_names = manager.in_collision_internal(return_names=True)

        if is_collision:
            for name_a, name_b in contact_names:
                exemption = _is_intentional_contact(name_a, name_b, component_types)
                if exemption:
                    exempted.append({"mesh_a": name_a, "mesh_b": name_b, "type": exemption})
                else:
                    collisions_found.append({
                        "mesh_a": name_a,
                        "mesh_b": name_b,
                        "type": "fcl",
                    })
    except Exception:
        # FCL not available or failed — fall back to AABB overlap
        for i in range(len(entries)):
            for j in range(i + 1, len(entries)):
                name_a, mesh_a, tf_a = entries[i]
                name_b, mesh_b, tf_b = entries[j]
                if _aabb_overlap(mesh_a, tf_a, mesh_b, tf_b):
                    exemption = _is_intentional_contact(name_a, name_b, component_types)
                    if exemption:
                        exempted.append({"mesh_a": name_a, "mesh_b": name_b, "type": exemption})
                    else:
                        collisions_found.append({
                            "mesh_a": name_a,
                            "mesh_b": name_b,
                            "type": "aabb",
                        })

    n = len(entries)
    pairs = n * (n - 1) // 2
    passed = len(collisions_found) == 0

    msg_parts = []
    if passed:
        msg_parts.append("No collisions detected.")
    else:
        msg_parts.append(f"Found {len(collisions_found)} collision(s).")
    if exempted:
        msg_parts.append(f"{len(exempted)} intentional contact(s) exempted.")

    return CollisionResult(
        passed=passed,
        collisions=collisions_found,
        mesh_count=n,
        pairs_checked=pairs,
        message=" ".join(msg_parts),
    )
