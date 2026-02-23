"""
Tests for collision detection validator.

Tests:
- Two overlapping boxes -> FAIL
- Two separated boxes -> PASS
- Single mesh -> PASS (trivially)
- Three meshes, one pair overlapping -> FAIL with correct pair
- Empty list -> PASS
"""

import numpy as np
import trimesh

from app.validators.collision import check_collisions, _aabb_overlap


def _make_box(center: tuple[float, float, float], size: float = 10.0) -> tuple[trimesh.Trimesh, np.ndarray]:
    """Create a box mesh and a translation transform."""
    mesh = trimesh.creation.box(extents=(size, size, size))
    transform = np.eye(4)
    transform[:3, 3] = center
    return mesh, transform


class TestCollisionDetection:
    """Collision detection tests."""

    def test_two_overlapping_boxes_fail(self):
        """Two boxes at the same location must collide."""
        mesh_a, tf_a = _make_box((0, 0, 0), size=10)
        mesh_b, tf_b = _make_box((5, 0, 0), size=10)  # Overlaps with A

        result = check_collisions([
            ("box_a", mesh_a, tf_a),
            ("box_b", mesh_b, tf_b),
        ])

        assert not result.passed, "Overlapping boxes should FAIL collision check"
        assert len(result.collisions) >= 1
        assert result.mesh_count == 2
        assert result.pairs_checked == 1

        # Check that the collision pair is reported
        pair = result.collisions[0]
        names = {pair["mesh_a"], pair["mesh_b"]}
        assert names == {"box_a", "box_b"}

    def test_two_separated_boxes_pass(self):
        """Two boxes far apart must not collide."""
        mesh_a, tf_a = _make_box((0, 0, 0), size=10)
        mesh_b, tf_b = _make_box((100, 0, 0), size=10)  # Far away

        result = check_collisions([
            ("box_a", mesh_a, tf_a),
            ("box_b", mesh_b, tf_b),
        ])

        assert result.passed, "Separated boxes should PASS collision check"
        assert len(result.collisions) == 0
        assert result.mesh_count == 2
        assert result.pairs_checked == 1

    def test_single_mesh_passes(self):
        """A single mesh cannot collide with itself."""
        mesh, tf = _make_box((0, 0, 0))

        result = check_collisions([("solo", mesh, tf)])

        assert result.passed
        assert result.mesh_count == 1
        assert result.pairs_checked == 0

    def test_empty_list_passes(self):
        """No meshes means no collisions."""
        result = check_collisions([])
        assert result.passed
        assert result.mesh_count == 0

    def test_three_meshes_one_pair_colliding(self):
        """Three meshes, only one pair overlaps."""
        mesh_a, tf_a = _make_box((0, 0, 0), size=10)
        mesh_b, tf_b = _make_box((5, 0, 0), size=10)   # Overlaps with A
        mesh_c, tf_c = _make_box((100, 0, 0), size=10)  # Far from both

        result = check_collisions([
            ("box_a", mesh_a, tf_a),
            ("box_b", mesh_b, tf_b),
            ("box_c", mesh_c, tf_c),
        ])

        assert not result.passed
        assert result.mesh_count == 3
        assert result.pairs_checked == 3

        # At least one collision found (A-B)
        collision_pairs = {
            frozenset((c["mesh_a"], c["mesh_b"])) for c in result.collisions
        }
        assert frozenset(("box_a", "box_b")) in collision_pairs

    def test_none_transform_uses_identity(self):
        """Passing None for transform should use identity."""
        mesh_a = trimesh.creation.box(extents=(10, 10, 10))
        mesh_b = trimesh.creation.box(extents=(10, 10, 10))

        # Both at origin with None transform -> overlap
        result = check_collisions([
            ("box_a", mesh_a, None),
            ("box_b", mesh_b, None),
        ])

        assert not result.passed, "Two boxes at origin should collide"

    def test_to_dict_format(self):
        """Result to_dict should have correct structure."""
        mesh_a, tf_a = _make_box((0, 0, 0))
        mesh_b, tf_b = _make_box((100, 0, 0))

        result = check_collisions([
            ("box_a", mesh_a, tf_a),
            ("box_b", mesh_b, tf_b),
        ])

        d = result.to_dict()
        assert d["validator"] == "collision"
        assert d["passed"] is True
        assert isinstance(d["collisions"], list)
        assert isinstance(d["mesh_count"], int)
        assert isinstance(d["pairs_checked"], int)
        assert isinstance(d["message"], str)


class TestAABBOverlap:
    """Direct tests for the AABB overlap helper."""

    def test_overlapping_aabb(self):
        mesh_a = trimesh.creation.box(extents=(10, 10, 10))
        mesh_b = trimesh.creation.box(extents=(10, 10, 10))
        tf_a = np.eye(4)
        tf_b = np.eye(4)
        tf_b[:3, 3] = [5, 0, 0]  # Shift 5 units — still overlapping

        assert _aabb_overlap(mesh_a, tf_a, mesh_b, tf_b)

    def test_separated_aabb(self):
        mesh_a = trimesh.creation.box(extents=(10, 10, 10))
        mesh_b = trimesh.creation.box(extents=(10, 10, 10))
        tf_a = np.eye(4)
        tf_b = np.eye(4)
        tf_b[:3, 3] = [50, 0, 0]  # Far away

        assert not _aabb_overlap(mesh_a, tf_a, mesh_b, tf_b)

    def test_touching_edge_overlaps(self):
        """Boxes touching at an edge count as overlapping (conservative)."""
        mesh_a = trimesh.creation.box(extents=(10, 10, 10))
        mesh_b = trimesh.creation.box(extents=(10, 10, 10))
        tf_a = np.eye(4)
        tf_b = np.eye(4)
        tf_b[:3, 3] = [10, 0, 0]  # Exactly touching

        assert _aabb_overlap(mesh_a, tf_a, mesh_b, tf_b)
