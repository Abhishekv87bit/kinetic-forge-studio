"""
Central database initialisation for KFS.

Provides a :class:`Database` helper that opens a SQLite connection and
creates all application tables via :meth:`_init_tables`.  Every table uses
``CREATE TABLE IF NOT EXISTS`` so the call is idempotent — safe to run on
every app startup.

Tables managed here
-------------------
modules          — CadQuery module source code records (SC-01)
module_versions  — Immutable version snapshots for each module (SC-01)
vlad_results     — Geometry validation run records (SC-03)
session_log      — Agent decision / context snapshots (SC-05)
"""
from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Optional

from backend.app.config import settings


# ---------------------------------------------------------------------------
# Table DDL
# ---------------------------------------------------------------------------

_DDL_MODULES = """
CREATE TABLE IF NOT EXISTS modules (
    id          TEXT    PRIMARY KEY,
    name        TEXT    NOT NULL,
    code        TEXT    NOT NULL,
    version     INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"""

_DDL_MODULE_VERSIONS = """
CREATE TABLE IF NOT EXISTS module_versions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id   TEXT    NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    version     INTEGER NOT NULL,
    code        TEXT    NOT NULL,
    created_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"""

_DDL_VLAD_RESULTS = """
CREATE TABLE IF NOT EXISTS vlad_results (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id      TEXT    NOT NULL,
    mechanism_type TEXT    NOT NULL DEFAULT '',
    verdict        TEXT    NOT NULL,
    passed         INTEGER NOT NULL,
    fail_count     INTEGER NOT NULL DEFAULT 0,
    warn_count     INTEGER NOT NULL DEFAULT 0,
    pass_count     INTEGER NOT NULL DEFAULT 0,
    info_count     INTEGER NOT NULL DEFAULT 0,
    fixed_parts    INTEGER NOT NULL DEFAULT 0,
    moving_parts   INTEGER NOT NULL DEFAULT 0,
    checks_json    TEXT    NOT NULL DEFAULT '[]',
    raw_json       TEXT    NOT NULL DEFAULT '',
    run_at         TEXT    NOT NULL
)
"""

_DDL_SESSION_LOG = """
CREATE TABLE IF NOT EXISTS session_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id  TEXT    NOT NULL,
    event_type  TEXT    NOT NULL,
    payload     TEXT    NOT NULL DEFAULT '{}',
    created_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"""

_ALL_DDL = [
    _DDL_MODULES,
    _DDL_MODULE_VERSIONS,
    _DDL_VLAD_RESULTS,
    _DDL_SESSION_LOG,
]


# ---------------------------------------------------------------------------
# Database helper
# ---------------------------------------------------------------------------


def _url_to_path(database_url: str) -> str:
    """Extract the filesystem path from a ``sqlite:///`` URL."""
    if database_url.startswith("sqlite:///"):
        return database_url[len("sqlite:///"):]
    return database_url


class Database:
    """
    Thin wrapper around a synchronous :mod:`sqlite3` connection with
    automatic schema initialisation.

    Parameters
    ----------
    db_path:
        Filesystem path to the SQLite file.  Defaults to the path derived
        from ``settings.database_url``.
    """

    def __init__(self, db_path: Optional[str] = None) -> None:
        self.db_path: str = db_path or _url_to_path(settings.database_url)

    # ------------------------------------------------------------------
    # Connection
    # ------------------------------------------------------------------

    def connect(self) -> sqlite3.Connection:
        """Open and return a new :class:`sqlite3.Connection`."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    # ------------------------------------------------------------------
    # Schema init
    # ------------------------------------------------------------------

    def _init_tables(self) -> None:
        """Create all application tables if they do not already exist."""
        with self.connect() as conn:
            for ddl in _ALL_DDL:
                conn.execute(ddl)
            conn.commit()

    def init(self) -> "Database":
        """Initialise schema and return *self* for chaining."""
        self._init_tables()
        return self


# ---------------------------------------------------------------------------
# Module-level singleton convenience
# ---------------------------------------------------------------------------

def get_db_path() -> str:
    """Return the configured SQLite file path."""
    return _url_to_path(settings.database_url)


def init_db(db_path: Optional[str] = None) -> Database:
    """Create a :class:`Database`, run ``_init_tables()``, and return it."""
    db = Database(db_path)
    db._init_tables()
    return db
