import pytest
from pathlib import Path
from app.models.project import ProjectManager, Project

@pytest.fixture
def pm(tmp_path):
    return ProjectManager(data_dir=tmp_path)

@pytest.mark.asyncio
async def test_create_project(pm):
    project = await pm.create("ravigneaux_compact")
    assert project.name == "ravigneaux_compact"
    assert project.id is not None
    assert project.gate == "design"
    assert project.data_dir.exists()

@pytest.mark.asyncio
async def test_list_projects(pm):
    await pm.create("project_a")
    await pm.create("project_b")
    projects = await pm.list_all()
    assert len(projects) == 2

@pytest.mark.asyncio
async def test_open_project(pm):
    created = await pm.create("test_project")
    opened = await pm.open(created.id)
    assert opened.name == "test_project"
    assert opened.id == created.id

@pytest.mark.asyncio
async def test_project_persists_across_instances(tmp_path):
    pm1 = ProjectManager(data_dir=tmp_path)
    created = await pm1.create("persistent")
    pm2 = ProjectManager(data_dir=tmp_path)
    projects = await pm2.list_all()
    assert len(projects) == 1
    assert projects[0].name == "persistent"
