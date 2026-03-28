"""Contract tests for Module API Routes (SC-09).

Covers:
- POST /modules      → 201 + DB record written
- POST /modules/{id}/execute → 200 + ExecutionResult shape (mock engine, no subprocess)
- POST /modules/{id}/execute for unknown module → 404
- GET  /modules/{id}/geometry when no STL exists → 404

CadQueryEngine is mocked so no subprocess or CadQuery install is required.
"""
from __future__ import annotations

import os
from typing import Optional
from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.models.module import ModuleManager
from backend.app.routes.modules import get_executor, get_module_manager, get_vlad_runner
from backend.app.services.module_executor import ExecutionResult, ModuleExecutor
from backend.app.services.vlad_runner import VladResult, VladRunner


# ---------------------------------------------------------------------------
# Mock helpers
# ---------------------------------------------------------------------------


def _make_manager(tmp_path) -> ModuleManager:
    """Real ModuleManager backed by a temporary SQLite file."""
    return ModuleManager(db_path=str(tmp_path / "routes_test.db"))


def _make_mock_executor(
    *,
    status: str = "valid",
    stl_path: Optional[str] = "/tmp/fake.stl",
    step_path: Optional[str] = "/tmp/fake.step",
    error: Optional[str] = None,
) -> ModuleExecutor:
    """ModuleExecutor whose execute() returns a pre-canned ExecutionResult."""
    executor = MagicMock(spec=ModuleExecutor)

    async def _execute(module_id: str, code: str) -> ExecutionResult:
        return ExecutionResult(
            module_id=module_id,
            status=status,
            stl_path=stl_path,
            step_path=step_path,
            error=error,
        )

    executor.execute = _execute
    return executor


def _make_mock_vlad_runner() -> MagicMock:
    """VladRunner mock with a no-op run() and empty history."""
    runner = MagicMock(spec=VladRunner)
    runner.run = MagicMock(
        return_value=VladResult(
            module_id="test",
            mechanism_type="generic",
            verdict="PASS",
            passed=True,
            fail_count=0,
            warn_count=0,
            pass_count=3,
            info_count=0,
            fixed_parts=1,
            moving_parts=0,
            checks=[],
        )
    )
    runner.get_history = MagicMock(return_value=[])
    return runner


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def _manager(tmp_path) -> ModuleManager:
    return _make_manager(tmp_path)


@pytest.fixture()
def client(_manager, tmp_path):
    """TestClient with real ModuleManager (temp DB) + mock executor/vlad."""
    executor = _make_mock_executor()
    vlad = _make_mock_vlad_runner()

    app.dependency_overrides[get_module_manager] = lambda: _manager
    app.dependency_overrides[get_executor] = lambda: executor
    app.dependency_overrides[get_vlad_runner] = lambda: vlad

    with TestClient(app) as c:
        yield c

    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------


def _create_module(client, name="spur_gear", code="import cadquery as cq") -> str:
    """POST /modules and return the new module_id."""
    resp = client.post("/modules", json={"name": name, "code": code})
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# POST /modules
# ---------------------------------------------------------------------------


class TestCreateModule:
    def test_returns_201(self, client):
        resp = client.post("/modules", json={"name": "helix", "code": "# code"})
        assert resp.status_code == 201

    def test_response_contains_id(self, client):
        resp = client.post("/modules", json={"name": "helix", "code": "# code"})
        body = resp.json()
        assert "id" in body
        assert len(body["id"]) > 0

    def test_response_contains_name(self, client):
        resp = client.post("/modules", json={"name": "spur_gear", "code": "# code"})
        assert resp.json()["name"] == "spur_gear"

    def test_response_contains_code(self, client):
        code = "import cadquery as cq\nresult = cq.Workplane('XY').box(10,10,10)"
        resp = client.post("/modules", json={"name": "box", "code": code})
        assert resp.json()["code"] == code

    def test_response_version_is_one(self, client):
        resp = client.post("/modules", json={"name": "v1", "code": "# v1"})
        assert resp.json()["version"] == 1

    def test_response_status_is_draft(self, client):
        resp = client.post("/modules", json={"name": "g", "code": "x=1"})
        assert resp.json()["status"] == "draft"

    def test_db_record_created(self, client, _manager):
        """Module row must actually exist in the DB after POST."""
        resp = client.post("/modules", json={"name": "db_check", "code": "# db"})
        module_id = resp.json()["id"]

        record = _manager.get(module_id)
        assert record is not None, "Module must be retrievable from the DB"
        assert record.name == "db_check"
        assert record.version == 1

    def test_each_module_gets_unique_id(self, client):
        id1 = _create_module(client, name="mod_a")
        id2 = _create_module(client, name="mod_b")
        assert id1 != id2

    def test_missing_name_returns_422(self, client):
        resp = client.post("/modules", json={"code": "# code"})
        assert resp.status_code == 422

    def test_missing_code_returns_422(self, client):
        resp = client.post("/modules", json={"name": "no_code"})
        assert resp.status_code == 422

    def test_parameters_stored(self, client, _manager):
        params = {"teeth": 20, "module": 1.5}
        resp = client.post(
            "/modules", json={"name": "gear", "code": "x=1", "parameters": params}
        )
        assert resp.status_code == 201
        record = _manager.get(resp.json()["id"])
        assert record.parameters == params


# ---------------------------------------------------------------------------
# GET /modules
# ---------------------------------------------------------------------------


class TestListModules:
    def test_returns_200(self, client):
        assert client.get("/modules").status_code == 200

    def test_returns_list(self, client):
        assert isinstance(client.get("/modules").json(), list)

    def test_includes_created_module(self, client):
        client.post("/modules", json={"name": "Cam", "code": "c=3"})
        names = [m["name"] for m in client.get("/modules").json()]
        assert "Cam" in names


# ---------------------------------------------------------------------------
# GET /modules/{module_id}
# ---------------------------------------------------------------------------


class TestGetModule:
    def test_returns_200(self, client):
        mid = _create_module(client, name="Rod")
        assert client.get(f"/modules/{mid}").status_code == 200

    def test_returns_correct_name(self, client):
        mid = _create_module(client, name="Rod")
        assert client.get(f"/modules/{mid}").json()["name"] == "Rod"

    def test_unknown_id_returns_404(self, client):
        assert client.get("/modules/nonexistent-id-xyz").status_code == 404


# ---------------------------------------------------------------------------
# PUT /modules/{module_id}
# ---------------------------------------------------------------------------


class TestUpdateModule:
    def test_returns_200(self, client):
        mid = _create_module(client)
        assert client.put(f"/modules/{mid}", json={"code": "a=2"}).status_code == 200

    def test_bumps_version(self, client):
        mid = _create_module(client)
        resp = client.put(f"/modules/{mid}", json={"code": "a=2"})
        assert resp.json()["version"] == 2

    def test_unknown_id_returns_404(self, client):
        assert (
            client.put("/modules/no-such-module", json={"code": "x=1"}).status_code == 404
        )


# ---------------------------------------------------------------------------
# POST /modules/{module_id}/execute — ExecutionResult shape
# ---------------------------------------------------------------------------


class TestExecuteModule:
    def test_returns_200(self, client):
        mid = _create_module(client)
        assert client.post(f"/modules/{mid}/execute").status_code == 200

    def test_response_has_module_id(self, client):
        mid = _create_module(client)
        data = client.post(f"/modules/{mid}/execute").json()
        assert data["module_id"] == mid

    def test_response_has_status_field(self, client):
        mid = _create_module(client)
        data = client.post(f"/modules/{mid}/execute").json()
        assert "status" in data

    def test_successful_execution_status_valid(self, client):
        mid = _create_module(client)
        data = client.post(f"/modules/{mid}/execute").json()
        assert data["status"] == "valid"

    def test_response_has_stl_path_on_success(self, client):
        mid = _create_module(client)
        data = client.post(f"/modules/{mid}/execute").json()
        assert data["stl_path"] is not None

    def test_response_has_step_path_on_success(self, client):
        mid = _create_module(client)
        data = client.post(f"/modules/{mid}/execute").json()
        assert data["step_path"] is not None

    def test_response_error_is_none_on_success(self, client):
        mid = _create_module(client)
        data = client.post(f"/modules/{mid}/execute").json()
        assert data["error"] is None

    def test_execution_result_shape_complete(self, client):
        """All five ExecutionResult fields must be present in the response."""
        mid = _create_module(client)
        body = client.post(f"/modules/{mid}/execute").json()
        for field_name in ("module_id", "status", "stl_path", "step_path", "error"):
            assert field_name in body, f"Missing field: {field_name}"

    def test_unknown_module_returns_404(self, client):
        assert client.post("/modules/does-not-exist/execute").status_code == 404

    def test_failed_result_returns_error_field(self, tmp_path):
        """Executor returning status=failed should still yield 200 with error field."""
        manager = _make_manager(tmp_path)
        executor = _make_mock_executor(
            status="failed", stl_path=None, step_path=None, error="boom"
        )
        vlad = _make_mock_vlad_runner()

        app.dependency_overrides[get_module_manager] = lambda: manager
        app.dependency_overrides[get_executor] = lambda: executor
        app.dependency_overrides[get_vlad_runner] = lambda: vlad

        with TestClient(app) as c:
            mid = c.post("/modules", json={"name": "Bad", "code": "x"}).json()["id"]
            data = c.post(f"/modules/{mid}/execute").json()

        app.dependency_overrides.clear()

        assert data["status"] == "failed"
        assert data["error"] == "boom"
        assert data["stl_path"] is None


# ---------------------------------------------------------------------------
# GET /modules/{module_id}/geometry — 404 when no STL
# ---------------------------------------------------------------------------


class TestGetGeometry:
    def test_returns_404_when_no_stl(self, client):
        """Geometry endpoint must 404 when the STL artefact has not been created."""
        mid = _create_module(client, name="no_stl_yet")
        resp = client.get(f"/modules/{mid}/geometry")
        assert resp.status_code == 404

    def test_404_detail_mentions_module_id(self, client):
        mid = _create_module(client, name="no_stl_yet")
        resp = client.get(f"/modules/{mid}/geometry")
        assert mid in resp.json()["detail"]

    def test_unknown_module_id_also_returns_404(self, client):
        """Even an unknown module_id must return 404 (no STL on disk)."""
        resp = client.get("/modules/nonexistent_module/geometry")
        assert resp.status_code == 404

    def test_404_detail_mentions_nonexistent_module(self, client):
        resp = client.get("/modules/nonexistent_module/geometry")
        assert "nonexistent_module" in resp.json()["detail"]

    def test_version_query_param_accepted(self, client):
        """?v= cache-buster must be accepted without 422."""
        mid = _create_module(client)
        resp = client.get(f"/modules/{mid}/geometry?v=42")
        # Still 404 (no STL) but NOT 422
        assert resp.status_code == 404


# ---------------------------------------------------------------------------
# Rollback
# ---------------------------------------------------------------------------


class TestRollback:
    def test_unknown_module_returns_404(self, client):
        resp = client.post("/modules/no-such/rollback", json={"target_version": 1})
        assert resp.status_code == 404

    def test_bad_version_returns_400(self, client):
        mid = _create_module(client)
        resp = client.post(f"/modules/{mid}/rollback", json={"target_version": 99})
        assert resp.status_code == 400


# ---------------------------------------------------------------------------
# VLAD history
# ---------------------------------------------------------------------------


class TestVladHistory:
    def test_returns_200(self, client):
        mid = _create_module(client)
        assert client.get(f"/modules/{mid}/vlad-history").status_code == 200

    def test_returns_list(self, client):
        mid = _create_module(client)
        assert isinstance(client.get(f"/modules/{mid}/vlad-history").json(), list)

    def test_unknown_module_returns_404(self, client):
        assert client.get("/modules/ghost-id/vlad-history").status_code == 404


# ---------------------------------------------------------------------------
# Health check (sanity)
# ---------------------------------------------------------------------------


def test_health_returns_200(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
