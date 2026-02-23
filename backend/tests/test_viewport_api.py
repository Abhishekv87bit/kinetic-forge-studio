"""Tests for the geometry serving API."""

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture(autouse=True)
async def reset_pm(tmp_path):
    from app.routes import projects
    from app.models.project import ProjectManager
    pm = ProjectManager(data_dir=tmp_path)
    projects._pm = pm
    yield
    projects._pm = None


@pytest.mark.asyncio
async def test_geometry_default_scene():
    """New project with no components should return a default demo scene."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        # Create a project
        res = await c.post("/api/projects", json={"name": "test_project"})
        assert res.status_code == 200
        project_id = res.json()["id"]

        # Get geometry — should return GLB binary
        res = await c.get(f"/api/projects/{project_id}/geometry")
        assert res.status_code == 200
        assert res.headers["content-type"] == "model/gltf-binary"
        # Check GLB magic number
        assert res.content[:4] == b"glTF"
        assert len(res.content) > 100


@pytest.mark.asyncio
async def test_geometry_info_default():
    """Geometry info for empty project should list demo components."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.post("/api/projects", json={"name": "test"})
        project_id = res.json()["id"]

        res = await c.get(f"/api/projects/{project_id}/geometry/info")
        assert res.status_code == 200
        data = res.json()
        assert data["source"] == "demo"
        assert data["component_count"] == 3


@pytest.mark.asyncio
async def test_geometry_with_components():
    """Project with registered components should generate from them."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.post("/api/projects", json={"name": "test"})
        project_id = res.json()["id"]

        # Register a gear component
        await c.post(f"/api/projects/{project_id}/components", json={
            "component_id": "ring_gear",
            "display_name": "Ring Gear",
            "component_type": "gear",
            "parameters": {"module": 1.5, "teeth": 48, "height": 10},
        })

        # Register a box component
        await c.post(f"/api/projects/{project_id}/components", json={
            "component_id": "housing",
            "display_name": "Housing",
            "component_type": "box",
            "parameters": {"length": 50, "width": 50, "height": 5},
        })

        # Get geometry
        res = await c.get(f"/api/projects/{project_id}/geometry")
        assert res.status_code == 200
        assert res.content[:4] == b"glTF"

        # Check info
        res = await c.get(f"/api/projects/{project_id}/geometry/info")
        data = res.json()
        assert data["source"] == "project"
        assert data["component_count"] == 2


@pytest.mark.asyncio
async def test_geometry_404_for_missing_project():
    """Non-existent project should return 404."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.get("/api/projects/nonexistent/geometry")
        assert res.status_code == 404
