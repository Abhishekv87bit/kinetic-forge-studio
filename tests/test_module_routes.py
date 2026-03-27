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
import sqlite3

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from unittest.mock import MagicMock

from backend.app.routes.modules import (
    CreateModuleRequest,
    get_db,
    get_executor,
    router as modules_router,
)
from backend.app.routes.viewport import router as viewport_router
from backend.app.services.module_executor import ModuleExecutor


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def db_path(tmp_path):
    """Isolated SQLite file per test."""
    return str(tmp_path / "test_modules.db")


@pytest.fixture()
def mock_engine(tmp_path):
    """CadQueryEngine mock that writes sentinel STL/STEP files synchronously."""
    engine = MagicMock()

    def _run_code(code, *, stl_path, step_path):
        os.makedirs(os.path.dirname(stl_path), exist_ok=True)
        with open(stl_path, "wb") as fh:
            fh.write(b"solid mock\nendsolid\n")
        with open(step_path, "wb") as fh:
            fh.write(b"ISO-10303-21;\nDATA;\nENDSEC;\nEND-ISO-10303-21;\n")

    engine.run_code.side_effect = _run_code
    return engine


@pytest.fixture()
def models_dir(tmp_path):
    """Temporary directory used as models_dir for the viewport route."""
    return str(tmp_path / "models")


@pytest.fixture()
def app(db_path, mock_engine, models_dir, monkeypatch):
    """FastAPI test application with DB and executor dependencies overridden."""
    # Patch settings.models_dir so viewport route looks in our temp dir
    import backend.app.routes.viewport as vp_module
    monkeypatch.setattr(vp_module.settings, "models_dir", models_dir)

    _app = FastAPI()
    _app.include_router(modules_router)
    _app.include_router(viewport_router)

    # ── DB override ────────────────────────────────────────────────────────
    def _override_db():
        conn = sqlite3.connect(db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS modules (
                id       TEXT PRIMARY KEY,
                name     TEXT NOT NULL,
                code     TEXT NOT NULL,
                version  INTEGER NOT NULL DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        conn.commit()
        try:
            yield conn
        finally:
            conn.close()

    # ── Executor override ─────────────────────────────────────────────────
    executor = ModuleExecutor(output_dir=models_dir, engine=mock_engine)

    def _override_executor():
        return executor

    _app.dependency_overrides[get_db] = _override_db
    _app.dependency_overrides[get_executor] = _override_executor

    return _app


@pytest.fixture()
def client(app):
    with TestClient(app) as c:
        yield c


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

    def test_db_record_created(self, client, db_path):
        """Module row must actually exist in SQLite after POST."""
        resp = client.post("/modules", json={"name": "db_check", "code": "# db"})
        module_id = resp.json()["id"]

        conn = sqlite3.connect(db_path)
        row = conn.execute(
            "SELECT id, name, code, version FROM modules WHERE id = ?", (module_id,)
        ).fetchone()
        conn.close()

        assert row is not None, "Row must exist in the modules table"
        assert row[1] == "db_check"
        assert row[3] == 1

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


# ---------------------------------------------------------------------------
# POST /modules/{module_id}/execute
# ---------------------------------------------------------------------------


class TestExecuteModule:
    @pytest.mark.asyncio
    async def test_returns_200(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        assert resp.status_code == 200

    @pytest.mark.asyncio
    async def test_response_has_module_id(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        assert resp.json()["module_id"] == module_id

    @pytest.mark.asyncio
    async def test_response_has_status_field(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        assert "status" in resp.json()

    @pytest.mark.asyncio
    async def test_successful_execution_status_valid(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        assert resp.json()["status"] == "valid"

    @pytest.mark.asyncio
    async def test_response_has_stl_path_on_success(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        body = resp.json()
        assert body["stl_path"] is not None

    @pytest.mark.asyncio
    async def test_response_has_step_path_on_success(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        body = resp.json()
        assert body["step_path"] is not None

    @pytest.mark.asyncio
    async def test_response_error_is_none_on_success(self, client):
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        assert resp.json()["error"] is None

    @pytest.mark.asyncio
    async def test_execution_result_shape_complete(self, client):
        """All five ExecutionResult fields must be present in the response."""
        module_id = _create_module(client)
        resp = client.post(f"/modules/{module_id}/execute")
        body = resp.json()
        for field in ("module_id", "status", "stl_path", "step_path", "error"):
            assert field in body, f"Missing field: {field}"

    @pytest.mark.asyncio
    async def test_unknown_module_returns_404(self, client):
        resp = client.post("/modules/does-not-exist/execute")
        assert resp.status_code == 404

    @pytest.mark.asyncio
    async def test_engine_not_called_for_unknown_module(self, client, mock_engine):
        client.post("/modules/does-not-exist/execute")
        mock_engine.run_code.assert_not_called()

    @pytest.mark.asyncio
    async def test_mock_engine_used_no_subprocess(self, client, mock_engine):
        """Verify the mock engine is invoked — no real CadQuery subprocess."""
        module_id = _create_module(client)
        client.post(f"/modules/{module_id}/execute")
        mock_engine.run_code.assert_called_once()


# ---------------------------------------------------------------------------
# GET /modules/{module_id}/geometry  (viewport route — SC-04)
# ---------------------------------------------------------------------------


class TestGetGeometry:
    def test_returns_404_when_no_stl(self, client):
        """Geometry endpoint must 404 when the STL artefact has not been created."""
        resp = client.get("/modules/nonexistent_module/geometry")
        assert resp.status_code == 404

    def test_404_detail_mentions_module(self, client):
        resp = client.get("/modules/nonexistent_module/geometry")
        assert "nonexistent_module" in resp.json()["detail"]

    def test_404_for_module_with_record_but_no_stl(self, client):
        """A module created via POST /modules has no STL until executed."""
        module_id = _create_module(client, name="no_stl_yet")
        resp = client.get(f"/modules/{module_id}/geometry")
        assert resp.status_code == 404
