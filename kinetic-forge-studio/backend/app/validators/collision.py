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


def check_collisions(
    meshes: list[tuple[str, trimesh.Trimesh, np.ndarray | None]],
) -> CollisionResult:
    """
    Check for collisions among a list of named meshes.

    Args:
        meshes: List of (name, trimesh.Trimesh, optional 4x4 transform).
                If transform is None, identity is used.

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

    # Normalize transforms
    entries: list[tuple[str, trimesh.Trimesh, np.ndarray]] = []
    for name, mesh, transform in meshes:
        if transform is None:
            transform = np.eye(4)
        entries.append((name, mesh, transform))

    collisions_found: list[dict] = []

    # Try trimesh.collision.CollisionManager first (uses FCL if available)
    try:
        manager = trimesh.collision.CollisionManager()
        for name, mesh, transform in entries:
            manager.add_object(name, mesh, transform=transform)

        is_collision, contact_names = manager.in_collision_internal(return_names=True)

        if is_collision:
            for name_a, name_b in contact_names:
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
                    collisions_found.append({
                        "mesh_a": name_a,
                        "mesh_b": name_b,
                        "type": "aabb",
                    })

    n = len(entries)
    pairs = n * (n - 1) // 2
    passed = len(collisions_found) == 0

    return CollisionResult(
        passed=passed,
        collisions=collisions_found,
        mesh_count=n,
        pairs_checked=pairs,
        message=(
            "No collisions detected."
            if passed
            else f"Found {len(collisions_found)} collision(s)."
        ),
    )
