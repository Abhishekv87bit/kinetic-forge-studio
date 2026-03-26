"""
Shared pytest fixtures for the KFS module system tests.
"""
import pytest
import pytest_asyncio
from pathlib import Path

from app.db.database import Database
from app.models.module import ModuleManager
from app.models.session_context import SessionLogManager


@pytest_asyncio.fixture
async def db(tmp_path):
    """In-memory-style Database using a temp-dir path. Tables are initialized on connect."""
    database = Database(tmp_path / "test_studio.db")
    await database.connect()
    yield database
    await database.close()


@pytest_asyncio.fixture
async def module_manager(tmp_path):
    """ModuleManager backed by a temp-dir database."""
    mm = ModuleManager(data_dir=tmp_path)
    await mm._ensure_db()
    yield mm
    await mm.db.close()


@pytest_asyncio.fixture
async def session_log_manager(tmp_path):
    """SessionLogManager backed by a temp-dir database."""
    sl = SessionLogManager(data_dir=tmp_path)
    await sl._ensure_db()
    yield sl
    await sl.db.close()


@pytest.fixture
def client(tmp_path):
    """
    FastAPI TestClient with module manager and session log manager
    reset to use an isolated temp-dir database.
    """
    from httpx import AsyncClient, ASGITransport
    from app.main import app
    from app.routes import modules as modules_route

    mm = ModuleManager(data_dir=tmp_path)
    sl = SessionLogManager(data_dir=tmp_path)

    modules_route._mm = mm
    modules_route._sl = sl

    yield app

    modules_route._mm = None
    modules_route._sl = None
