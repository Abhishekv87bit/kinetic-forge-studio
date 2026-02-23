"""
Tests for Gate Enforcer and validation status API.

Tests:
- GateEnforcer with passing meshes -> all pass
- GateEnforcer with overlapping meshes -> collision fails
- GateEnforcer with non-watertight mesh -> manufacturability fails
- API: gate-status endpoint returns structured results
- API: gate-status for project with no components
"""

import numpy as np
import pytest
import trimesh
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.orchestrator.gate import GateEnforcer


def _make_box(center: tuple[float, float, float], size: float = 10.0):
    """Create a box mesh and a translation transform."""
    mesh = trimesh.creation.box(extents=(size, size, size))
    transform = np.eye(4)
    transform[:3, 3] = center
    return mesh, transform


class TestGateEnforcer:
    """Tests for the GateEnforcer orchestrator."""

    def test_separated_watertight_boxes_pass(self):
        """Two watertight separated boxes should pass all checks."""
        mesh_a, tf_a = _make_box((0, 0, 0), size=10)
        mesh_b, tf_b = _make_box((50, 0, 0), size=10)

        enforcer = GateEnforcer()
        result = enforcer.run([
            ("box_a", mesh_a, tf_a),
            ("box_b", mesh_b, tf_b),
        ])

        assert result.passed is True
        assert len(result.validators) >= 3  # 1 collision + 2 manufacturability
        assert "passed" in result.summary.lower() or "all" in result.summary.lower()

    def test_overlapping_boxes_fail_collision(self):
        """Two overlapping boxes should fail the collision check."""
        mesh_a, tf_a = _make_box((0, 0, 0), size=10)
        mesh_b, tf_b = _make_box((5, 0, 0), size=10)

        enforcer = GateEnforcer()
        result = enforcer.run([
            ("box_a", mesh_a, tf_a),
            ("box_b", mesh_b, tf_b),
        ])

        assert result.passed is False

        # Find the collision validator result
        collision_result = next(
            v for v in result.validators if v["validator"] == "collision"
        )
        assert collision_result["passed"] is False

    def test_non_watertight_mesh_fails(self):
        """A non-watertight mesh should fail manufacturability."""
        # Create a non-watertight mesh
        box = trimesh.creation.box(extents=(10, 10, 10))
        n_faces = len(box.faces)
        broken_mesh = trimesh.Trimesh(
            vertices=box.vertices,
            faces=box.faces[: max(1, n_faces - 4)],
            process=True,
        )

        enforcer = GateEnforcer()
        result = enforcer.run([
            ("broken_box", broken_mesh, None),
        ])

        assert result.passed is False

        # Find the manufacturability validator for broken_box
        mfg_results = [
            v for v in result.validators if v["validator"] == "manufacturability"
        ]
        assert len(mfg_results) >= 1
        assert mfg_results[0]["passed"] is False

    def test_convenience_run_on_trimeshes(self):
        """run_on_trimeshes should work without explicit transforms."""
        mesh_a = trimesh.creation.box(extents=(10, 10, 10))
        mesh_b = trimesh.creation.box(extents=(10, 10, 10))

        enforcer = GateEnforcer()
        # Both at origin -> collision
        result = enforcer.run_on_trimeshes([
            ("box_a", mesh_a),
            ("box_b", mesh_b),
        ])

        assert result.passed is False

    def test_to_dict_format(self):
        """GateResult.to_dict should have correct structure."""
        mesh, tf = _make_box((0, 0, 0))
        enforcer = GateEnforcer()
        result = enforcer.run([("box", mesh, tf)])

        d = result.to_dict()
        assert "passed" in d
        assert "validators" in d
        assert "summary" in d
        assert isinstance(d["validators"], list)

    def test_single_mesh_passes_all(self):
        """A single watertight mesh should pass all checks."""
        mesh = trimesh.creation.box(extents=(20, 20, 20))
        enforcer = GateEnforcer()
        result = enforcer.run([("solid_box", mesh, None)])

        assert result.passed is True
        # 1 collision (trivially passes) + 1 manufacturability
        assert len(result.validators) == 2

    def test_custom_thresholds(self):
        """Custom wall thickness threshold should be used."""
        mesh = trimesh.creation.box(extents=(20, 20, 20))
        enforcer = GateEnforcer(min_wall_thickness=0.1, max_overhang_angle=80.0)
        result = enforcer.run([("box", mesh, None)])

        # With very relaxed thresholds, should pass
        assert result.passed is True


class TestGateStatusAPI:
    """Tests for the GET /api/projects/{id}/gate-status endpoint."""

    @pytest.fixture(autouse=True)
    async def reset_pm(self, tmp_path, monkeypatch):
        from app.routes import projects
        from app.models.project import ProjectManager
        pm = ProjectManager(data_dir=tmp_path)
        projects._pm = pm
        yield
        projects._pm = None

    @pytest.mark.asyncio
    async def test_gate_status_no_components(self):
        """Gate status for project with no components returns empty validators."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            # Create project
            res = await c.post("/api/projects", json={"name": "test_gate"})
            pid = res.json()["id"]

            # Get gate status
            res = await c.get(f"/api/projects/{pid}/gate-status")
            assert res.status_code == 200
            data = res.json()
            assert data["passed"] is True
            assert data["validators"] == []
            assert "no components" in data["summary"].lower()

    @pytest.mark.asyncio
    async def test_gate_status_with_components(self):
        """Gate status with components runs validators and returns results."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            # Create project
            res = await c.post("/api/projects", json={"name": "test_gate_with_geo"})
            pid = res.json()["id"]

            # Register two separated box components
            await c.post(f"/api/projects/{pid}/components", json={
                "component_id": "box_a",
                "display_name": "Box A",
                "component_type": "box",
                "parameters": {"length": 10, "width": 10, "height": 10},
            })
            await c.post(f"/api/projects/{pid}/components", json={
                "component_id": "box_b",
                "display_name": "Box B",
                "component_type": "box",
                "parameters": {"length": 10, "width": 10, "height": 10},
            })

            # Get gate status
            res = await c.get(f"/api/projects/{pid}/gate-status")
            assert res.status_code == 200
            data = res.json()

            assert "passed" in data
            assert "validators" in data
            assert "summary" in data
            assert len(data["validators"]) >= 3  # collision + 2x manufacturability

    @pytest.mark.asyncio
    async def test_gate_status_404_for_missing_project(self):
        """Gate status returns 404 for non-existent project."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            res = await c.get("/api/projects/nonexistent/gate-status")
            assert res.status_code == 404
