import pytest
from app.models.project import ProjectManager
from app.models.component import ComponentManager

@pytest.fixture
async def setup(tmp_path):
    pm = ProjectManager(data_dir=tmp_path)
    project = await pm.create("test")
    cm = ComponentManager(pm.db)
    return cm, project.id

@pytest.mark.asyncio
async def test_register_component(setup):
    cm, pid = setup
    c = await cm.register(pid, component_id="ring_gear_01", display_name="Ring Gear",
                          component_type="gear", parameters={"teeth": 48, "module": 1.5, "OD": 82.0})
    assert c["id"] == "ring_gear_01"
    assert c["display_name"] == "Ring Gear"

@pytest.mark.asyncio
async def test_get_component(setup):
    cm, pid = setup
    await cm.register(pid, "sun_gear_01", "Sun Gear", "gear", {"teeth": 16})
    c = await cm.get(pid, "sun_gear_01")
    assert c["parameters"]["teeth"] == 16

@pytest.mark.asyncio
async def test_list_components(setup):
    cm, pid = setup
    await cm.register(pid, "ring_01", "Ring", "gear", {})
    await cm.register(pid, "sun_01", "Sun", "gear", {})
    await cm.register(pid, "planet_01", "Planet 1", "gear", {})
    components = await cm.list_all(pid)
    assert len(components) == 3

@pytest.mark.asyncio
async def test_update_parameters(setup):
    cm, pid = setup
    await cm.register(pid, "ring_01", "Ring", "gear", {"teeth": 48})
    await cm.update_params(pid, "ring_01", {"teeth": 42, "module": 1.0})
    c = await cm.get(pid, "ring_01")
    assert c["parameters"]["teeth"] == 42
    assert c["parameters"]["module"] == 1.0

@pytest.mark.asyncio
async def test_duplicate_id_raises(setup):
    cm, pid = setup
    await cm.register(pid, "ring_01", "Ring", "gear", {})
    with pytest.raises(ValueError, match="already exists"):
        await cm.register(pid, "ring_01", "Another Ring", "gear", {})

@pytest.mark.asyncio
async def test_registry_as_context_dict(setup):
    cm, pid = setup
    await cm.register(pid, "ring_01", "Ring Gear", "gear", {"teeth": 48})
    await cm.register(pid, "sun_01", "Sun Gear", "gear", {"teeth": 16})
    context = await cm.as_context(pid)
    assert "ring_01" in context
    assert context["ring_01"]["display_name"] == "Ring Gear"
