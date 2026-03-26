"""
Tests for manifest generation (app/services/manifest_generator.py).

generate_manifest(project_id, db) queries the live database and returns
a structured dict. Tests insert fixture rows directly into the DB.
"""
import json
import secrets
import pytest
import pytest_asyncio
from datetime import datetime, timezone

from app.services.manifest_generator import generate_manifest


PROJECT_ID = "proj-manifest-001"
PROJECT_NAME = "Test Project Alpha"


async def _insert_project(db, project_id=PROJECT_ID, name=PROJECT_NAME):
    """Helper: insert a minimal project row."""
    await db.conn.execute(
        """INSERT INTO projects (id, name, gate, data_dir)
           VALUES (?, ?, 'design', '/tmp/test')""",
        (project_id, name),
    )
    await db.conn.commit()


async def _insert_module(db, project_id, name, language="python", version=1, status="active"):
    """Helper: insert a minimal module row and return its id."""
    module_id = secrets.token_hex(6)
    now = datetime.now(timezone.utc).isoformat()
    await db.conn.execute(
        """INSERT INTO modules (id, project_id, name, source_code, language,
           version, status, parameters, created_at, updated_at)
           VALUES (?, ?, ?, 'pass', ?, ?, ?, '{}', ?, ?)""",
        (module_id, project_id, name, language, version, status, now, now),
    )
    await db.conn.commit()
    return module_id


async def _insert_vlad_result(db, module_id, passed: bool, version=1):
    """Helper: insert a vlad_results row."""
    result_id = secrets.token_hex(6)
    now = datetime.now(timezone.utc).isoformat()
    await db.conn.execute(
        """INSERT INTO vlad_results
           (id, module_id, version, tier, passed, checks_run, checks_passed,
            checks_failed, findings, created_at)
           VALUES (?, ?, ?, 'T1', ?, '[]', '[]', '[]', '[]', ?)""",
        (result_id, module_id, version, int(passed), now),
    )
    await db.conn.commit()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_generate_manifest_structure(db):
    """Output has all required top-level keys."""
    await _insert_project(db)

    manifest = await generate_manifest(PROJECT_ID, db)

    assert "project_name" in manifest
    assert "project_id" in manifest
    assert "modules" in manifest
    assert "vlad_summary" in manifest
    assert "generated_at" in manifest


@pytest.mark.asyncio
async def test_generate_manifest_project_name(db):
    """project_name is pulled from the projects table."""
    await _insert_project(db)
    manifest = await generate_manifest(PROJECT_ID, db)
    assert manifest["project_name"] == PROJECT_NAME


@pytest.mark.asyncio
async def test_generate_manifest_fallback_project_name(db):
    """When project is not in DB, project_name falls back to project_id."""
    manifest = await generate_manifest("unknown-project", db)
    assert manifest["project_name"] == "unknown-project"


@pytest.mark.asyncio
async def test_generate_manifest_empty_project(db):
    """A project with no modules produces an empty modules list."""
    await _insert_project(db)
    manifest = await generate_manifest(PROJECT_ID, db)

    assert manifest["modules"] == []
    summary = manifest["vlad_summary"]
    assert summary["total"] == 0
    assert summary["passed"] == 0
    assert summary["failed"] == 0
    assert summary["unvalidated"] == 0


@pytest.mark.asyncio
async def test_generate_manifest_module_fields(db):
    """Each module entry has the expected fields."""
    await _insert_project(db)
    await _insert_module(db, PROJECT_ID, "gear_body", version=3)

    manifest = await generate_manifest(PROJECT_ID, db)

    assert len(manifest["modules"]) == 1
    m = manifest["modules"][0]
    assert m["name"] == "gear_body"
    assert m["version"] == 3
    assert m["language"] == "python"
    assert m["status"] == "active"
    assert "vlad" in m


@pytest.mark.asyncio
async def test_generate_manifest_vlad_passed(db):
    """Module with a passing VLAD result shows vlad='passed'."""
    await _insert_project(db)
    module_id = await _insert_module(db, PROJECT_ID, "shaft")
    await _insert_vlad_result(db, module_id, passed=True)

    manifest = await generate_manifest(PROJECT_ID, db)
    assert manifest["modules"][0]["vlad"] == "passed"
    assert manifest["vlad_summary"]["passed"] == 1
    assert manifest["vlad_summary"]["failed"] == 0
    assert manifest["vlad_summary"]["unvalidated"] == 0


@pytest.mark.asyncio
async def test_generate_manifest_vlad_failed(db):
    """Module with a failing VLAD result shows vlad='failed'."""
    await _insert_project(db)
    module_id = await _insert_module(db, PROJECT_ID, "crank")
    await _insert_vlad_result(db, module_id, passed=False)

    manifest = await generate_manifest(PROJECT_ID, db)
    assert manifest["modules"][0]["vlad"] == "failed"
    assert manifest["vlad_summary"]["failed"] == 1


@pytest.mark.asyncio
async def test_generate_manifest_vlad_unvalidated(db):
    """Module with no VLAD result shows vlad=None."""
    await _insert_project(db)
    await _insert_module(db, PROJECT_ID, "housing")

    manifest = await generate_manifest(PROJECT_ID, db)
    assert manifest["modules"][0]["vlad"] is None
    assert manifest["vlad_summary"]["unvalidated"] == 1


@pytest.mark.asyncio
async def test_generate_manifest_mixed_vlad(db):
    """Summary counts across passed, failed, and unvalidated modules."""
    await _insert_project(db)
    m1 = await _insert_module(db, PROJECT_ID, "mod_pass")
    m2 = await _insert_module(db, PROJECT_ID, "mod_fail")
    await _insert_module(db, PROJECT_ID, "mod_unvalidated")

    await _insert_vlad_result(db, m1, passed=True)
    await _insert_vlad_result(db, m2, passed=False)

    manifest = await generate_manifest(PROJECT_ID, db)
    summary = manifest["vlad_summary"]

    assert summary["total"] == 3
    assert summary["passed"] == 1
    assert summary["failed"] == 1
    assert summary["unvalidated"] == 1


@pytest.mark.asyncio
async def test_generate_manifest_latest_vlad_used(db):
    """When multiple VLAD results exist, the most recent one is used."""
    await _insert_project(db)
    module_id = await _insert_module(db, PROJECT_ID, "versioned")

    # Insert older failing result then newer passing result
    await _insert_vlad_result(db, module_id, passed=False, version=1)
    await _insert_vlad_result(db, module_id, passed=True, version=2)

    manifest = await generate_manifest(PROJECT_ID, db)
    # Should reflect the latest (passing) result
    assert manifest["modules"][0]["vlad"] == "passed"


@pytest.mark.asyncio
async def test_generate_manifest_project_id_in_output(db):
    """project_id is echoed back in the manifest."""
    await _insert_project(db)
    manifest = await generate_manifest(PROJECT_ID, db)
    assert manifest["project_id"] == PROJECT_ID


@pytest.mark.asyncio
async def test_generate_manifest_generated_at_is_iso(db):
    """generated_at is a valid ISO-8601 timestamp string."""
    await _insert_project(db)
    manifest = await generate_manifest(PROJECT_ID, db)
    # Should parse without error
    dt = datetime.fromisoformat(manifest["generated_at"])
    assert dt.tzinfo is not None
