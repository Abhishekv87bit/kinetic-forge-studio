"""Shared pytest fixtures for the KFS test suite.

Fixtures defined here are available to all test modules without explicit import.
"""
from __future__ import annotations

import pytest

from backend.app.models.module import ModuleManager


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
