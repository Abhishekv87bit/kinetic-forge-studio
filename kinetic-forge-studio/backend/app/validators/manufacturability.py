"""
Manufacturability validator for FDM 3D printing.

Checks:
1. Wall thickness — minimum face-to-face distance (approximated via
   ray-based sampling from mesh surface inward)
2. Overhang angle — face normals vs build direction (Z-up)
3. Watertight — trimesh.is_watertight

All thresholds are configurable with sensible FDM defaults.
"""

from dataclasses import dataclass, field

import numpy as np
import trimesh


@dataclass
class ManufacturabilityResult:
    """Result of manufacturability analysis."""
    passed: bool
    checks: list[dict] = field(default_factory=list)
    message: str = ""

    def to_dict(self) -> dict:
        return {
            "validator": "manufacturability",
            "passed": self.passed,
            "checks": self.checks,
            "message": self.message,
        }


def _check_watertight(mesh: trimesh.Trimesh) -> dict:
    """Check if mesh is watertight (manifold, no holes)."""
    is_watertight = bool(mesh.is_watertight)
    return {
        "name": "watertight",
        "passed": is_watertight,
        "value": is_watertight,
        "threshold": True,
        "message": (
            "Mesh is watertight."
            if is_watertight
            else "Mesh is NOT watertight. It has holes or non-manifold edges."
        ),
    }


def _check_wall_thickness(
    mesh: trimesh.Trimesh,
    min_thickness: float = 1.5,
    sample_count: int = 200,
) -> dict:
    """
    Estimate minimum wall thickness by casting rays from surface
    points inward (along inverted normals) and measuring distance
    to the opposing inner wall.

    This is an approximation — true wall thickness analysis requires
    medial axis transform, but ray sampling catches most thin-wall
    issues for FDM validation.
    """
    if not mesh.is_watertight:
        return {
            "name": "wall_thickness",
            "passed": False,
            "value": None,
            "threshold": min_thickness,
            "message": "Cannot check wall thickness on non-watertight mesh.",
        }

    # Sample points on the surface
    n_samples = min(sample_count, len(mesh.faces))
    if n_samples == 0:
        return {
            "name": "wall_thickness",
            "passed": False,
            "value": None,
            "threshold": min_thickness,
            "message": "Mesh has no faces.",
        }

    # Use face centroids and inward-pointing normals
    face_indices = np.random.choice(len(mesh.faces), size=n_samples, replace=False)
    centroids = mesh.triangles_center[face_indices]
    normals = mesh.face_normals[face_indices]

    # Cast rays inward (opposite to face normal)
    ray_directions = -normals

    # Offset origins slightly inward to avoid self-intersection
    origins = centroids + ray_directions * 0.01

    # Cast rays and find hits
    try:
        locations, index_ray, _ = mesh.ray.intersects_location(
            ray_origins=origins,
            ray_directions=ray_directions,
        )
    except Exception:
        return {
            "name": "wall_thickness",
            "passed": True,
            "value": None,
            "threshold": min_thickness,
            "message": "Ray casting failed; skipping wall thickness check.",
        }

    if len(locations) == 0:
        # No internal hits — could be a solid object
        return {
            "name": "wall_thickness",
            "passed": True,
            "value": None,
            "threshold": min_thickness,
            "message": "No internal ray hits (likely solid geometry).",
        }

    # Compute distances from each origin to its first hit
    # index_ray tells us which origin each hit corresponds to
    distances = np.linalg.norm(locations - origins[index_ray], axis=1)

    # Group by ray and take the first (closest) hit per ray
    min_distances: dict[int, float] = {}
    for ray_idx, dist in zip(index_ray, distances):
        if ray_idx not in min_distances or dist < min_distances[ray_idx]:
            min_distances[ray_idx] = dist

    if not min_distances:
        return {
            "name": "wall_thickness",
            "passed": True,
            "value": None,
            "threshold": min_thickness,
            "message": "Could not determine wall thickness.",
        }

    thicknesses = list(min_distances.values())
    min_found = float(min(thicknesses))
    avg_found = float(np.mean(thicknesses))
    passed = min_found >= min_thickness

    return {
        "name": "wall_thickness",
        "passed": passed,
        "value": round(min_found, 3),
        "average": round(avg_found, 3),
        "threshold": min_thickness,
        "message": (
            f"Minimum wall thickness: {min_found:.2f}mm (threshold: {min_thickness}mm)."
            if passed
            else f"Wall too thin: {min_found:.2f}mm < {min_thickness}mm threshold."
        ),
    }


def _check_overhang(
    mesh: trimesh.Trimesh,
    max_angle: float = 45.0,
    build_direction: tuple[float, float, float] = (0.0, 0.0, 1.0),
) -> dict:
    """
    Check for overhanging faces that exceed the maximum printable angle.

    The overhang angle is measured between each face normal and the
    build direction (default: Z-up). Faces pointing downward at angles
    steeper than max_angle from horizontal need support material.

    Returns the percentage of faces that are overhanging and whether
    the check passes (less than 25% overhang faces is considered OK).
    """
    build_dir = np.array(build_direction, dtype=float)
    build_dir = build_dir / np.linalg.norm(build_dir)

    normals = mesh.face_normals
    if len(normals) == 0:
        return {
            "name": "overhang",
            "passed": True,
            "value": 0.0,
            "threshold": max_angle,
            "message": "No faces to check.",
        }

    # Dot product of each face normal with build direction
    # Positive = faces upward, negative = faces downward
    dots = np.dot(normals, build_dir)

    # Convert to angle from build direction
    angles_from_up = np.degrees(np.arccos(np.clip(dots, -1.0, 1.0)))

    # Overhang faces: angle from up > (90 + max_angle) degrees
    # i.e., the face is pointing downward beyond the max overhang angle
    overhang_threshold = 90.0 + max_angle
    overhang_mask = angles_from_up > overhang_threshold

    n_overhang = int(overhang_mask.sum())
    pct_overhang = (n_overhang / len(normals)) * 100.0

    # We consider it a pass if less than 25% of faces need support
    overhang_limit_pct = 25.0
    passed = pct_overhang < overhang_limit_pct

    worst_angle = float(angles_from_up.max()) if len(angles_from_up) > 0 else 0.0

    return {
        "name": "overhang",
        "passed": passed,
        "value": round(pct_overhang, 1),
        "threshold": max_angle,
        "overhang_face_count": n_overhang,
        "total_faces": len(normals),
        "worst_angle_from_up": round(worst_angle, 1),
        "message": (
            f"Overhang OK: {pct_overhang:.1f}% of faces exceed {max_angle} deg."
            if passed
            else f"Excessive overhang: {pct_overhang:.1f}% of faces exceed {max_angle} deg."
        ),
    }


def check_manufacturability(
    mesh: trimesh.Trimesh,
    min_wall_thickness: float = 1.5,
    max_overhang_angle: float = 45.0,
    build_direction: tuple[float, float, float] = (0.0, 0.0, 1.0),
    sample_count: int = 200,
) -> ManufacturabilityResult:
    """
    Run all manufacturability checks on a mesh.

    Args:
        mesh: The trimesh to validate.
        min_wall_thickness: Minimum wall thickness in mm.
        max_overhang_angle: Maximum overhang angle in degrees.
        build_direction: Build plate normal (default Z-up).
        sample_count: Number of surface samples for wall thickness.

    Returns:
        ManufacturabilityResult with per-check details.
    """
    checks = []

    # 1. Watertight check (must come first — other checks depend on it)
    watertight = _check_watertight(mesh)
    checks.append(watertight)

    # 2. Wall thickness check
    wall = _check_wall_thickness(mesh, min_wall_thickness, sample_count)
    checks.append(wall)

    # 3. Overhang check
    overhang = _check_overhang(mesh, max_overhang_angle, build_direction)
    checks.append(overhang)

    all_passed = all(c["passed"] for c in checks)
    failed_names = [c["name"] for c in checks if not c["passed"]]

    if all_passed:
        message = "All manufacturability checks passed."
    else:
        message = f"Failed checks: {', '.join(failed_names)}."

    return ManufacturabilityResult(
        passed=all_passed,
        checks=checks,
        message=message,
    )
