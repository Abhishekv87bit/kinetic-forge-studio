"""SC-01 / SC-02 Module API Routes.

Endpoints:
    POST /modules                   — create a module record (SC-01)
    POST /modules/{module_id}/execute — execute stored module code (SC-02)

The geometry endpoint (GET /modules/{module_id}/geometry) lives in viewport.py (SC-04).
"""
from __future__ import annotations

import sqlite3
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from backend.app.config import settings
from backend.app.services.module_executor import ExecutionResult, ModuleExecutor

router = APIRouter(prefix="/modules", tags=["modules"])


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------


def _db_path() -> str:
    """Extract the file path from settings.database_url (sqlite:///...)."""
    url = settings.database_url
    if url.startswith("sqlite:///"):
        return url[len("sqlite:///"):]
    return url


def _ensure_schema(conn: sqlite3.Connection) -> None:
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


def get_db():
    """Yield an open SQLite connection (dependency — override in tests)."""
    conn = sqlite3.connect(_db_path())
    conn.row_factory = sqlite3.Row
    _ensure_schema(conn)
    try:
        yield conn
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Executor dependency
# ---------------------------------------------------------------------------


def get_executor() -> ModuleExecutor:
    """Return a ModuleExecutor wired to the configured models directory.

    No engine is attached at this layer — the executor must be injected with
    a real engine (or mock) by callers that need actual geometry output.
    """
    return ModuleExecutor(output_dir=settings.models_dir)


# ---------------------------------------------------------------------------
# Request / response schemas
# ---------------------------------------------------------------------------


class CreateModuleRequest(BaseModel):
    name: str
    code: str


class ModuleResponse(BaseModel):
    id: str
    name: str
    code: str
    version: int


class ExecutionResultResponse(BaseModel):
    module_id: str
    status: str
    stl_path: Optional[str] = None
    step_path: Optional[str] = None
    error: Optional[str] = None


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@router.post("", status_code=201, response_model=ModuleResponse)
async def create_module(
    body: CreateModuleRequest,
    db: sqlite3.Connection = Depends(get_db),
) -> ModuleResponse:
    """Persist a new module and return its record."""
    module_id = str(uuid.uuid4())
    db.execute(
        "INSERT INTO modules (id, name, code, version) VALUES (?, ?, ?, 1)",
        (module_id, body.name, body.code),
    )
    db.commit()
    return ModuleResponse(id=module_id, name=body.name, code=body.code, version=1)


@router.post("/{module_id}/execute", response_model=ExecutionResultResponse)
async def execute_module(
    module_id: str,
    db: sqlite3.Connection = Depends(get_db),
    executor: ModuleExecutor = Depends(get_executor),
) -> ExecutionResultResponse:
    """Execute the stored code for *module_id* and return ExecutionResult."""
    row = db.execute(
        "SELECT id, name, code, version FROM modules WHERE id = ?",
        (module_id,),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")

    result: ExecutionResult = await executor.execute(module_id, row["code"])
    return ExecutionResultResponse(
        module_id=result.module_id,
        status=result.status,
        stl_path=result.stl_path,
        step_path=result.step_path,
        error=result.error,
    )
