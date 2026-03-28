"""Shared pytest fixtures for the KFS test suite.

Fixtures defined here are available to all test modules without explicit import.
"""
from __future__ import annotations

import os
import pytest
from unittest.mock import MagicMock

from backend.app.models.module import ModuleManager


def pytest_configure(config):
    """Register custom markers so they appear in --markers output."""
    config.addinivalue_line(
        "markers",
        "requires_cadquery: marks tests that need the real CadQuery engine installed",
    )


@pytest.fixture()
def manager(tmp_path) -> ModuleManager:
    """A :class:`ModuleManager` backed by a temporary SQLite file.

    Using a real file (not ``:memory:``) is required because
    :meth:`ModuleManager._connect` opens a *new* connection on every call —
    separate ``sqlite3.connect(":memory:")`` calls each produce an independent
    empty database, so state would be lost between operations.
    """
    db_path = str(tmp_path / "test_modules.db")
    return ModuleManager(db_path=db_path)


@pytest.fixture()
def cadquery_mock_engine():
    """Shared CadQuery engine mock: writes sentinel artefact files without real CadQuery.

    Exposed in conftest so both unit tests and integration tests can reuse it.
    The engine writes minimal valid-looking STL/STEP bytes so downstream file-
    existence checks pass without a real geometry kernel.
    """
    engine = MagicMock()

    def _run_code(code, *, stl_path, step_path):
        os.makedirs(os.path.dirname(stl_path), exist_ok=True)
        with open(stl_path, "wb") as f:
            f.write(b"solid mock\nendsolid\n")
        with open(step_path, "wb") as f:
            f.write(b"ISO-10303-21; mock STEP geometry")

    engine.run_code.side_effect = _run_code
    return engine
