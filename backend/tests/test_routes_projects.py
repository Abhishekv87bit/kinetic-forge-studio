import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.routes.projects import _pm, get_pm

@pytest.fixture(autouse=True)
async def reset_pm(tmp_path, monkeypatch):
    from app.routes import projects
    from app.models.project import ProjectManager
    pm = ProjectManager(data_dir=tmp_path)
    projects._pm = pm
    yield
    projects._pm = None

@pytest.mark.asyncio
async def test_create_and_list_projects():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.post("/api/projects", json={"name": "test_project"})
        assert res.status_code == 200
        project_id = res.json()["id"]

        res = await c.get("/api/projects")
        assert len(res.json()) == 1

@pytest.mark.asyncio
async def test_add_decision_with_conflict():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.post("/api/projects", json={"name": "test"})
        pid = res.json()["id"]

        await c.post(f"/api/projects/{pid}/decisions",
                     json={"parameter": "OD", "value": "82mm"})
        await c.post(f"/api/projects/{pid}/decisions/1/lock")

        res = await c.post(f"/api/projects/{pid}/decisions",
                           json={"parameter": "OD", "value": "55mm"})
        assert len(res.json()["conflicts"]) == 1
