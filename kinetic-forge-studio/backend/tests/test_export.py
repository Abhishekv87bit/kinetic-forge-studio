"""Tests for the export package API."""

import io
import json
import zipfile

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture(autouse=True)
async def reset_pm(tmp_path, monkeypatch):
    from app.routes import projects
    from app.models.project import ProjectManager
    pm = ProjectManager(data_dir=tmp_path)
    projects._pm = pm
    yield
    projects._pm = None


async def _create_project_with_components(c: AsyncClient) -> str:
    """Helper: create a project and register some components."""
    res = await c.post("/api/projects", json={"name": "Test Export Project"})
    pid = res.json()["id"]

    # Register components
    await c.post(f"/api/projects/{pid}/components", json={
        "component_id": "base_plate",
        "display_name": "Base Plate",
        "component_type": "box",
        "parameters": {"length": 50, "width": 50, "height": 5},
    })
    await c.post(f"/api/projects/{pid}/components", json={
        "component_id": "main_shaft",
        "display_name": "Main Shaft",
        "component_type": "cylinder",
        "parameters": {"radius": 3, "height": 40},
    })

    # Add a decision
    await c.post(f"/api/projects/{pid}/decisions", json={
        "parameter": "material",
        "value": "brass",
        "reason": "Aesthetic choice",
    })

    return pid


class TestExportEndpoint:
    @pytest.mark.asyncio
    async def test_export_returns_zip(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")
            assert res.status_code == 200
            assert res.headers["content-type"] == "application/zip"

    @pytest.mark.asyncio
    async def test_export_contains_readme(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            names = zf.namelist()
            assert "README.txt" in names

            readme = zf.read("README.txt").decode("utf-8")
            assert "Test Export Project" in readme
            assert "Kinetic Forge Studio" in readme

    @pytest.mark.asyncio
    async def test_export_contains_spec_sheet(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            assert "spec_sheet.json" in zf.namelist()

            spec = json.loads(zf.read("spec_sheet.json"))
            assert spec["project_name"] == "Test Export Project"
            assert spec["component_count"] == 2
            assert spec["decision_count"] == 1
            assert len(spec["components"]) == 2
            assert len(spec["decisions"]) == 1

    @pytest.mark.asyncio
    async def test_export_contains_validation_report(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            assert "validation_report.json" in zf.namelist()

            report = json.loads(zf.read("validation_report.json"))
            assert "passed" in report

    @pytest.mark.asyncio
    async def test_export_contains_step_files(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            names = zf.namelist()
            step_files = [n for n in names if n.startswith("step/") and n.endswith(".step")]
            assert len(step_files) == 2
            assert "step/base_plate.step" in step_files
            assert "step/main_shaft.step" in step_files

    @pytest.mark.asyncio
    async def test_export_contains_stl_files(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            names = zf.namelist()
            stl_files = [n for n in names if n.startswith("stl/") and n.endswith(".stl")]
            assert len(stl_files) == 2
            assert "stl/base_plate.stl" in stl_files
            assert "stl/main_shaft.stl" in stl_files

    @pytest.mark.asyncio
    async def test_export_step_files_are_valid(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            step_data = zf.read("step/base_plate.step")
            # STEP files start with ISO header
            assert len(step_data) > 100

    @pytest.mark.asyncio
    async def test_export_stl_files_are_valid(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            stl_data = zf.read("stl/main_shaft.stl")
            assert len(stl_data) > 0

    @pytest.mark.asyncio
    async def test_export_nonexistent_project_404(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            res = await c.get("/api/projects/nonexistent/export")
            assert res.status_code == 404

    @pytest.mark.asyncio
    async def test_export_empty_project(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            res = await c.post("/api/projects", json={"name": "Empty Project"})
            pid = res.json()["id"]

            res = await c.get(f"/api/projects/{pid}/export")
            assert res.status_code == 200

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            assert "README.txt" in zf.namelist()
            assert "spec_sheet.json" in zf.namelist()
            assert "validation_report.json" in zf.namelist()

    @pytest.mark.asyncio
    async def test_export_filename_header(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")
            disposition = res.headers.get("content-disposition", "")
            assert "attachment" in disposition
            assert ".zip" in disposition

    @pytest.mark.asyncio
    async def test_export_readme_lists_components(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            readme = zf.read("README.txt").decode("utf-8")
            assert "Base Plate" in readme
            assert "Main Shaft" in readme

    @pytest.mark.asyncio
    async def test_export_readme_lists_decisions(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            pid = await _create_project_with_components(c)
            res = await c.get(f"/api/projects/{pid}/export")

            zf = zipfile.ZipFile(io.BytesIO(res.content))
            readme = zf.read("README.txt").decode("utf-8")
            assert "material" in readme
            assert "brass" in readme
