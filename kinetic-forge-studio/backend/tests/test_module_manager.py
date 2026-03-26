"""
Tests for ModuleManager CRUD operations (app/models/module.py).
All tests use an in-memory-style aiosqlite database via the module_manager fixture.
"""
import pytest
import pytest_asyncio


PROJECT_ID = "proj-test-001"
INITIAL_SOURCE = "result = cq.Workplane('XY').box(10, 10, 10)"
UPDATED_SOURCE = "result = cq.Workplane('XY').box(20, 20, 20)"
SECOND_UPDATE = "result = cq.Workplane('XY').sphere(5)"


@pytest.mark.asyncio
async def test_create_module(module_manager):
    """create() returns a dict with all expected fields at version 1."""
    module = await module_manager.create(
        project_id=PROJECT_ID,
        name="gear_body",
        source_code=INITIAL_SOURCE,
        language="python",
        parameters={"module": 1.0, "teeth": 20},
    )

    assert module["id"]
    assert module["project_id"] == PROJECT_ID
    assert module["name"] == "gear_body"
    assert module["source_code"] == INITIAL_SOURCE
    assert module["language"] == "python"
    assert module["version"] == 1
    assert module["status"] == "active"
    assert isinstance(module["parameters"], dict)
    assert module["parameters"]["teeth"] == 20
    assert module["created_at"]
    assert module["updated_at"]


@pytest.mark.asyncio
async def test_list_modules(module_manager):
    """list_all() returns all modules for a project."""
    await module_manager.create(PROJECT_ID, "module_a", INITIAL_SOURCE)
    await module_manager.create(PROJECT_ID, "module_b", UPDATED_SOURCE)

    modules = await module_manager.list_all(PROJECT_ID)

    assert len(modules) == 2
    names = {m["name"] for m in modules}
    assert names == {"module_a", "module_b"}


@pytest.mark.asyncio
async def test_list_modules_empty_project(module_manager):
    """list_all() returns an empty list when a project has no modules."""
    modules = await module_manager.list_all("nonexistent-project")
    assert modules == []


@pytest.mark.asyncio
async def test_list_modules_isolated_by_project(module_manager):
    """list_all() only returns modules belonging to the specified project."""
    await module_manager.create(PROJECT_ID, "mod_in_proj", INITIAL_SOURCE)
    await module_manager.create("other-project", "mod_other", INITIAL_SOURCE)

    modules = await module_manager.list_all(PROJECT_ID)
    assert len(modules) == 1
    assert modules[0]["name"] == "mod_in_proj"


@pytest.mark.asyncio
async def test_get_module(module_manager):
    """get() returns the module dict with correct field values."""
    created = await module_manager.create(PROJECT_ID, "shaft", INITIAL_SOURCE)
    fetched = await module_manager.get(PROJECT_ID, created["id"])

    assert fetched["id"] == created["id"]
    assert fetched["name"] == "shaft"
    assert fetched["source_code"] == INITIAL_SOURCE
    assert fetched["version"] == 1


@pytest.mark.asyncio
async def test_get_nonexistent(module_manager):
    """get() raises ValueError for a module that does not exist."""
    with pytest.raises(ValueError, match="not found"):
        await module_manager.get(PROJECT_ID, "no-such-module-id")


@pytest.mark.asyncio
async def test_update_source(module_manager):
    """update_source() increments version and persists the new source."""
    module = await module_manager.create(PROJECT_ID, "gear", INITIAL_SOURCE)
    module_id = module["id"]

    updated = await module_manager.update_source(
        project_id=PROJECT_ID,
        module_id=module_id,
        source_code=UPDATED_SOURCE,
        change_summary="wider box",
    )

    assert updated["version"] == 2
    assert updated["source_code"] == UPDATED_SOURCE
    assert updated["id"] == module_id


@pytest.mark.asyncio
async def test_update_nonexistent(module_manager):
    """update_source() raises ValueError for a non-existent module."""
    with pytest.raises(ValueError, match="not found"):
        await module_manager.update_source(
            PROJECT_ID, "ghost-id", UPDATED_SOURCE
        )


@pytest.mark.asyncio
async def test_get_versions(module_manager):
    """get_versions() returns one entry per version after two updates."""
    module = await module_manager.create(PROJECT_ID, "crank", INITIAL_SOURCE)
    module_id = module["id"]

    await module_manager.update_source(PROJECT_ID, module_id, UPDATED_SOURCE)
    await module_manager.update_source(PROJECT_ID, module_id, SECOND_UPDATE)

    versions = await module_manager.get_versions(module_id)

    assert len(versions) == 3
    # Returned newest-first by default query ordering
    version_numbers = [v["version"] for v in versions]
    assert sorted(version_numbers, reverse=True) == version_numbers
    assert set(version_numbers) == {1, 2, 3}


@pytest.mark.asyncio
async def test_rollback(module_manager):
    """rollback() restores source to target version and bumps version counter."""
    module = await module_manager.create(PROJECT_ID, "piston", INITIAL_SOURCE)
    module_id = module["id"]

    await module_manager.update_source(PROJECT_ID, module_id, UPDATED_SOURCE)

    rolled = await module_manager.rollback(PROJECT_ID, module_id, target_version=1)

    assert rolled["source_code"] == INITIAL_SOURCE
    # Rollback is stored as a new version (v3 in this case)
    assert rolled["version"] == 3


@pytest.mark.asyncio
async def test_rollback_nonexistent_version(module_manager):
    """rollback() raises ValueError when the target version does not exist."""
    module = await module_manager.create(PROJECT_ID, "hub", INITIAL_SOURCE)

    with pytest.raises(ValueError):
        await module_manager.rollback(PROJECT_ID, module["id"], target_version=99)


@pytest.mark.asyncio
async def test_parameters_default_to_empty_dict(module_manager):
    """Parameters default to {} when not supplied."""
    module = await module_manager.create(PROJECT_ID, "plain", INITIAL_SOURCE)
    assert module["parameters"] == {}
