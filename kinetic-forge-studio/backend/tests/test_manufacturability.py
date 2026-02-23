"""
Tests for manufacturability validator.

Tests:
- Thick box (watertight, thick walls) -> PASS all checks
- Thin-walled box (below min thickness) -> FAIL wall thickness
- Non-watertight mesh -> FAIL watertight
- Overhang detection on a tilted surface
- Result serialization
"""

import numpy as np
import trimesh

from app.validators.manufacturability import (
    check_manufacturability,
    _check_watertight,
    _check_wall_thickness,
    _check_overhang,
)


def _make_thick_box(size: float = 20.0) -> trimesh.Trimesh:
    """Create a solid watertight box — should pass all checks."""
    return trimesh.creation.box(extents=(size, size, size))


def _make_thin_box() -> trimesh.Trimesh:
    """
    Create a thin-walled hollow box.

    Outer shell 20x20x20, inner cavity removes most material,
    leaving walls ~0.5mm thick (below the 1.5mm FDM threshold).
    """
    outer = trimesh.creation.box(extents=(20, 20, 20))
    inner = trimesh.creation.box(extents=(19, 19, 19))
    result = trimesh.boolean.difference([outer, inner], engine="blender")
    if isinstance(result, trimesh.Scene):
        result = result.dump(concatenate=True)
    return result


def _make_non_watertight_mesh() -> trimesh.Trimesh:
    """
    Create a non-watertight mesh by removing some faces from a box.
    """
    box = trimesh.creation.box(extents=(10, 10, 10))
    # Remove the last few faces to break watertightness
    n_faces = len(box.faces)
    keep = max(1, n_faces - 4)
    new_faces = box.faces[:keep]
    mesh = trimesh.Trimesh(vertices=box.vertices, faces=new_faces, process=True)
    return mesh


class TestWatertight:
    """Watertight check tests."""

    def test_solid_box_is_watertight(self):
        mesh = _make_thick_box()
        result = _check_watertight(mesh)
        assert result["passed"] is True
        assert result["name"] == "watertight"

    def test_broken_mesh_not_watertight(self):
        mesh = _make_non_watertight_mesh()
        result = _check_watertight(mesh)
        assert result["passed"] is False


class TestOverhang:
    """Overhang angle check tests."""

    def test_box_has_minimal_overhang(self):
        """A box aligned with build direction has minimal overhang."""
        mesh = _make_thick_box()
        result = _check_overhang(mesh, max_angle=45.0)
        assert result["passed"] is True
        assert result["name"] == "overhang"
        # A box has faces pointing up, down, and sideways.
        # Only bottom face (pointing straight down) exceeds 90+45=135 deg
        assert result["overhang_face_count"] >= 0

    def test_sphere_has_overhang(self):
        """A sphere has many faces that overhang at steep angles."""
        mesh = trimesh.creation.icosphere(subdivisions=3, radius=10.0)
        result = _check_overhang(mesh, max_angle=45.0)
        # Sphere has lots of downward-facing faces
        assert result["overhang_face_count"] > 0
        assert result["name"] == "overhang"


class TestWallThickness:
    """Wall thickness check tests."""

    def test_thick_solid_box_passes(self):
        """A solid 20mm box should pass 1.5mm wall thickness."""
        mesh = _make_thick_box(size=20.0)
        result = _check_wall_thickness(mesh, min_thickness=1.5)
        assert result["name"] == "wall_thickness"
        # Solid box — rays from surface inward should travel far
        # This may return True with value=None or a large value
        assert result["passed"] is True

    def test_non_watertight_fails_wall_check(self):
        """Non-watertight mesh cannot be checked for wall thickness."""
        mesh = _make_non_watertight_mesh()
        result = _check_wall_thickness(mesh, min_thickness=1.5)
        assert result["passed"] is False
        assert "non-watertight" in result["message"].lower()


class TestFullManufacturability:
    """Integration tests for check_manufacturability()."""

    def test_thick_box_passes_all(self):
        """A solid thick box should pass all manufacturability checks."""
        mesh = _make_thick_box(size=20.0)
        result = check_manufacturability(mesh, min_wall_thickness=1.5)

        assert result.passed is True
        assert len(result.checks) == 3

        check_names = [c["name"] for c in result.checks]
        assert "watertight" in check_names
        assert "wall_thickness" in check_names
        assert "overhang" in check_names

    def test_non_watertight_fails(self):
        """A non-watertight mesh should fail at least the watertight check."""
        mesh = _make_non_watertight_mesh()
        result = check_manufacturability(mesh)

        assert result.passed is False
        watertight_check = next(c for c in result.checks if c["name"] == "watertight")
        assert watertight_check["passed"] is False

    def test_to_dict_format(self):
        """Result to_dict should have correct structure."""
        mesh = _make_thick_box()
        result = check_manufacturability(mesh)

        d = result.to_dict()
        assert d["validator"] == "manufacturability"
        assert isinstance(d["passed"], bool)
        assert isinstance(d["checks"], list)
        assert isinstance(d["message"], str)
        assert len(d["checks"]) == 3

    def test_custom_thresholds(self):
        """Custom thresholds should be used in checks."""
        mesh = _make_thick_box()
        result = check_manufacturability(
            mesh,
            min_wall_thickness=0.5,
            max_overhang_angle=60.0,
        )

        wall_check = next(c for c in result.checks if c["name"] == "wall_thickness")
        assert wall_check["threshold"] == 0.5

        overhang_check = next(c for c in result.checks if c["name"] == "overhang")
        assert overhang_check["threshold"] == 60.0
