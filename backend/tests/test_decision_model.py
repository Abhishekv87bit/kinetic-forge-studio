import pytest
from app.models.project import ProjectManager
from app.models.decision import DecisionManager

@pytest.fixture
async def setup(tmp_path):
    pm = ProjectManager(data_dir=tmp_path)
    project = await pm.create("test")
    dm = DecisionManager(pm.db)
    return dm, project.id

@pytest.mark.asyncio
async def test_add_decision(setup):
    dm, pid = setup
    d = await dm.add(pid, parameter="ring_gear.OD", value="82mm", reason="Fits housing")
    assert d["id"] == 1
    assert d["status"] == "proposed"

@pytest.mark.asyncio
async def test_lock_decision(setup):
    dm, pid = setup
    await dm.add(pid, parameter="ring_gear.OD", value="82mm", reason="Fits housing")
    d = await dm.lock(pid, decision_id=1)
    assert d["status"] == "locked"

@pytest.mark.asyncio
async def test_conflict_detection(setup):
    dm, pid = setup
    await dm.add(pid, parameter="ring_gear.OD", value="82mm", reason="Fits housing")
    await dm.lock(pid, decision_id=1)
    conflicts = await dm.check_conflicts(pid, parameter="ring_gear.OD", value="55mm")
    assert len(conflicts) == 1
    assert conflicts[0]["value"] == "82mm"

@pytest.mark.asyncio
async def test_supersede_decision(setup):
    dm, pid = setup
    await dm.add(pid, parameter="module", value="1.5", reason="Standard")
    await dm.lock(pid, decision_id=1)
    await dm.supersede(pid, old_id=1, new_value="1.0", reason="Compacting")
    decisions = await dm.list_all(pid)
    old = [d for d in decisions if d["id"] == 1][0]
    assert old["status"] == "superseded"
    new = [d for d in decisions if d["id"] == 2][0]
    assert new["value"] == "1.0"

@pytest.mark.asyncio
async def test_list_locked_only(setup):
    dm, pid = setup
    await dm.add(pid, parameter="OD", value="82mm", reason="")
    await dm.add(pid, parameter="teeth", value="48", reason="")
    await dm.lock(pid, decision_id=1)
    locked = await dm.list_locked(pid)
    assert len(locked) == 1
