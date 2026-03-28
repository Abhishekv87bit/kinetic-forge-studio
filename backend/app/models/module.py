"""SC-01 Module Manager.

Stores, versions, and retrieves CadQuery module source code in SQLite.
A "module" is a Python script that defines a CadQuery component.

Tables managed here:
  modules         — live record (current code + version + status)
  module_versions — append-only history of every code version
"""
from __future__ import annotations

import json
import sqlite3
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional


# ---------------------------------------------------------------------------
# Value objects
# ---------------------------------------------------------------------------


@dataclass
class Module:
    """Live record for a CadQuery module.

    Attributes:
        id:           UUID string, primary key.
        name:         Human-readable component name.
        code:         Current Python source (CadQuery script).
        version:      Monotonically increasing integer; starts at 1.
        status:       Lifecycle state: "draft" | "executing" | "valid" | "failed".
        parameters:   Optional JSON-serialisable dict of design parameters.
        vlad_verdict: Last VLAD validation result (JSON-serialisable dict).
        created_at:   ISO-8601 UTC timestamp of initial creation.
        updated_at:   ISO-8601 UTC timestamp of last modification.
    """

    id: str
    name: str
    code: str
    version: int
    status: str
    parameters: Optional[Dict[str, Any]] = None
    vlad_verdict: Optional[Dict[str, Any]] = None
    created_at: str = ""
    updated_at: str = ""


@dataclass
class ModuleVersion:
    """One historical snapshot of a module's code.

    Attributes:
        id:        UUID string, primary key of this version row.
        module_id: FK to modules.id.
        version:   The version number this snapshot represents.
        code:      Source code at that version.
        created_at: ISO-8601 UTC timestamp when the snapshot was saved.
    """

    id: str
    module_id: str
    version: int
    code: str
    created_at: str = ""


# ---------------------------------------------------------------------------
# Manager
# ---------------------------------------------------------------------------


class ModuleManager:
    """CRUD, versioning, and rollback for CadQuery modules in SQLite.

    Each public method opens/closes its own connection so the manager is
    safe to use from any async context without holding a long-lived conn.

    Args:
        db_path: Filesystem path to the SQLite database file.
    """

    _PATCHABLE_COLS: frozenset = frozenset({"status", "vlad_verdict", "code"})

    def __init__(self, db_path: str) -> None:
        self.db_path = db_path
        self._init_tables()

    # ------------------------------------------------------------------
    # Schema bootstrap
    # ------------------------------------------------------------------

    def _init_tables(self) -> None:
        """Create *modules* and *module_versions* tables if they don't exist."""
        with self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS modules (
                    id           TEXT PRIMARY KEY,
                    name         TEXT NOT NULL,
                    code         TEXT NOT NULL,
                    version      INTEGER NOT NULL DEFAULT 1,
                    status       TEXT NOT NULL DEFAULT 'draft',
                    parameters   TEXT,
                    vlad_verdict TEXT,
                    created_at   TEXT NOT NULL,
                    updated_at   TEXT NOT NULL
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS module_versions (
                    id        TEXT PRIMARY KEY,
                    module_id TEXT NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
                    version   INTEGER NOT NULL,
                    code      TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )
            conn.commit()

    # ------------------------------------------------------------------
    # CRUD
    # ------------------------------------------------------------------

    def create(
        self,
        name: str,
        code: str,
        parameters: Optional[Dict[str, Any]] = None,
    ) -> Module:
        """Insert a new module at version 1 with status "draft".

        The initial code snapshot is *not* written to module_versions;
        the live row in modules already carries version 1.

        Returns the newly created :class:`Module`.
        """
        now = _utcnow()
        module = Module(
            id=str(uuid.uuid4()),
            name=name,
            code=code,
            version=1,
            status="draft",
            parameters=parameters,
            vlad_verdict=None,
            created_at=now,
            updated_at=now,
        )
        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO modules
                    (id, name, code, version, status, parameters, vlad_verdict, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    module.id,
                    module.name,
                    module.code,
                    module.version,
                    module.status,
                    _json_dumps(module.parameters),
                    None,
                    module.created_at,
                    module.updated_at,
                ),
            )
            conn.commit()
        return module

    def get(self, module_id: str) -> Optional[Module]:
        """Fetch a module by *module_id*.  Returns ``None`` if not found."""
        with self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM modules WHERE id = ?", (module_id,)
            ).fetchone()
        if row is None:
            return None
        return _row_to_module(row)

    def list_all(self) -> List[Module]:
        """Return all modules ordered by creation time (oldest first)."""
        with self._connect() as conn:
            rows = conn.execute(
                "SELECT * FROM modules ORDER BY created_at ASC"
            ).fetchall()
        return [_row_to_module(r) for r in rows]

    def delete(self, module_id: str) -> None:
        """Delete a module and all its version history.

        Raises:
            KeyError: If *module_id* does not exist.
        """
        with self._connect() as conn:
            cur = conn.execute(
                "DELETE FROM modules WHERE id = ?", (module_id,)
            )
            conn.commit()
        if cur.rowcount == 0:
            raise KeyError(f"Module '{module_id}' not found")

    # ------------------------------------------------------------------
    # Versioning
    # ------------------------------------------------------------------

    def update_code(self, module_id: str, new_code: str) -> Module:
        """Replace the module's code and increment its version.

        The *current* code is snapshotted to module_versions before the
        live row is updated, so every previous version is recoverable.

        Returns the updated :class:`Module`.

        Raises:
            KeyError: If *module_id* does not exist.
        """
        with self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM modules WHERE id = ?", (module_id,)
            ).fetchone()
            if row is None:
                raise KeyError(f"Module '{module_id}' not found")

            # Snapshot current code into version history
            _insert_version(conn, module_id, row["version"], row["code"])

            new_version = row["version"] + 1
            now = _utcnow()
            conn.execute(
                """
                UPDATE modules
                SET code = ?, version = ?, updated_at = ?
                WHERE id = ?
                """,
                (new_code, new_version, now, module_id),
            )
            conn.commit()

            updated_row = conn.execute(
                "SELECT * FROM modules WHERE id = ?", (module_id,)
            ).fetchone()
        return _row_to_module(updated_row)

    def get_version_history(self, module_id: str) -> List[ModuleVersion]:
        """Return all historical snapshots for *module_id*, oldest first.

        Note: the *current* live version is **not** included — it lives in
        the modules table, not in module_versions.
        """
        with self._connect() as conn:
            rows = conn.execute(
                """
                SELECT * FROM module_versions
                WHERE module_id = ?
                ORDER BY version ASC
                """,
                (module_id,),
            ).fetchall()
        return [_row_to_version(r) for r in rows]

    def rollback(self, module_id: str, target_version: int) -> Module:
        """Restore *module_id* to the code from *target_version*.

        The current code is snapshotted first so nothing is lost.
        The module's version number continues to increment (it does NOT
        revert to *target_version*) so history remains monotonic.

        Returns the updated :class:`Module` after rollback.

        Raises:
            KeyError: If *module_id* does not exist.
            ValueError: If *target_version* snapshot is not found.
        """
        with self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM modules WHERE id = ?", (module_id,)
            ).fetchone()
            if row is None:
                raise KeyError(f"Module '{module_id}' not found")

            current_version = row["version"]

            # Special case: rolling back to the current live version is a no-op
            if target_version == current_version:
                return _row_to_module(row)

            # Retrieve the target snapshot from version history
            snap = conn.execute(
                """
                SELECT code FROM module_versions
                WHERE module_id = ? AND version = ?
                """,
                (module_id, target_version),
            ).fetchone()
            if snap is None:
                raise ValueError(
                    f"Version {target_version} not found for module '{module_id}'"
                )

            # Snapshot the current code before overwriting
            _insert_version(conn, module_id, current_version, row["code"])

            new_version = current_version + 1
            now = _utcnow()
            conn.execute(
                """
                UPDATE modules
                SET code = ?, version = ?, updated_at = ?
                WHERE id = ?
                """,
                (snap["code"], new_version, now, module_id),
            )
            conn.commit()

            updated_row = conn.execute(
                "SELECT * FROM modules WHERE id = ?", (module_id,)
            ).fetchone()
        return _row_to_module(updated_row)

    # ------------------------------------------------------------------
    # Status & VLAD verdict
    # ------------------------------------------------------------------

    def update_status(self, module_id: str, status: str) -> Module:
        """Set the module's lifecycle status.

        Valid values: ``"draft"``, ``"executing"``, ``"valid"``, ``"failed"``.

        Returns the updated :class:`Module`.

        Raises:
            KeyError: If *module_id* does not exist.
            ValueError: If *status* is not a recognised value.
        """
        _VALID_STATUSES = {"draft", "executing", "valid", "failed"}
        if status not in _VALID_STATUSES:
            raise ValueError(
                f"Invalid status {status!r}; must be one of {_VALID_STATUSES}"
            )
        return self._patch(module_id, {"status": status})

    def update_vlad_verdict(
        self, module_id: str, verdict: Dict[str, Any]
    ) -> Module:
        """Persist the latest VLAD validation result for *module_id*.

        *verdict* is stored as JSON in the ``vlad_verdict`` column and
        returned as a dict via :attr:`Module.vlad_verdict`.

        Returns the updated :class:`Module`.

        Raises:
            KeyError: If *module_id* does not exist.
        """
        return self._patch(module_id, {"vlad_verdict": _json_dumps(verdict)})

    # ------------------------------------------------------------------
    # Contract-spec aliases
    # (The protocol uses these names; they delegate to the canonical methods.)
    # ------------------------------------------------------------------

    def update_source(self, module_id: str, new_source: str) -> "Module":
        """Alias for :meth:`update_code` (contract name from SC-01 spec)."""
        return self.update_code(module_id, new_source)

    def set_status(self, module_id: str, status: str) -> "Module":
        """Alias for :meth:`update_status` (contract name from SC-01 spec)."""
        return self.update_status(module_id, status)

    def set_vlad_verdict(self, module_id: str, verdict: str) -> "Module":
        """Store a VLAD verdict string (contract name from SC-01 spec).

        Unlike :meth:`update_vlad_verdict` (which accepts a dict), this method
        stores the raw string so callers can pass any opaque verdict token.

        Raises:
            KeyError: If *module_id* does not exist.
        """
        return self._patch(module_id, {"vlad_verdict": verdict})

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    def _patch(self, module_id: str, fields: Dict[str, Any]) -> Module:
        """Apply an arbitrary column update to a module row.

        Raises:
            KeyError: If *module_id* does not exist.
        """
        if not fields:
            raise ValueError("_patch requires at least one field")

        invalid = set(fields.keys()) - self._PATCHABLE_COLS
        if invalid:
            raise ValueError(
                f"_patch received non-patchable column(s): {sorted(invalid)}. "
                f"Allowed: {sorted(self._PATCHABLE_COLS)}"
            )

        cols = ", ".join(f"{k} = ?" for k in fields)
        values = list(fields.values())

        with self._connect() as conn:
            now = _utcnow()
            cur = conn.execute(
                f"UPDATE modules SET {cols}, updated_at = ? WHERE id = ?",  # noqa: S608
                (*values, now, module_id),
            )
            conn.commit()
            if cur.rowcount == 0:
                raise KeyError(f"Module '{module_id}' not found")
            row = conn.execute(
                "SELECT * FROM modules WHERE id = ?", (module_id,)
            ).fetchone()
        return _row_to_module(row)


# ---------------------------------------------------------------------------
# Module-private helpers
# ---------------------------------------------------------------------------


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def _json_dumps(obj: Any) -> Optional[str]:
    return json.dumps(obj) if obj is not None else None


def _json_loads(s: Optional[str]) -> Optional[Any]:
    return json.loads(s) if s is not None else None


def _row_to_module(row: sqlite3.Row) -> Module:
    return Module(
        id=row["id"],
        name=row["name"],
        code=row["code"],
        version=row["version"],
        status=row["status"],
        parameters=_json_loads(row["parameters"]),
        vlad_verdict=row["vlad_verdict"],
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


def _row_to_version(row: sqlite3.Row) -> ModuleVersion:
    return ModuleVersion(
        id=row["id"],
        module_id=row["module_id"],
        version=row["version"],
        code=row["code"],
        created_at=row["created_at"],
    )


def _insert_version(
    conn: sqlite3.Connection, module_id: str, version: int, code: str
) -> None:
    """Write one row to module_versions inside an existing transaction."""
    conn.execute(
        """
        INSERT INTO module_versions (id, module_id, version, code, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (str(uuid.uuid4()), module_id, version, code, _utcnow()),
    )
