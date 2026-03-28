"""SC-05 Context Persistence — SessionContextManager.

Tracks module lifecycle actions (create, execute, validate, repair) in the
``session_log`` SQLite table and surfaces them as structured context for chat
prompt construction.

The table is created automatically on first use so no migration step is needed.
"""
from __future__ import annotations

import contextlib
import json
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional


# ---------------------------------------------------------------------------
# Schema SQL
# ---------------------------------------------------------------------------

_CREATE_SESSION_LOG = """
CREATE TABLE IF NOT EXISTS session_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id  TEXT    NOT NULL,
    action_type TEXT    NOT NULL,
    module_id   TEXT    NOT NULL DEFAULT '',
    details     TEXT    NOT NULL DEFAULT '{}',
    timestamp   TEXT    NOT NULL
)
"""

_INSERT_ACTION = """
INSERT INTO session_log (session_id, action_type, module_id, details, timestamp)
VALUES (?, ?, ?, ?, ?)
"""

_SELECT_BY_SESSION = """
SELECT id, session_id, action_type, module_id, details, timestamp
FROM   session_log
WHERE  session_id = ?
ORDER  BY id ASC
"""

_SELECT_BY_MODULE = """
SELECT id, session_id, action_type, module_id, details, timestamp
FROM   session_log
WHERE  session_id = ?
  AND  module_id  = ?
ORDER  BY id ASC
"""


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class SessionAction:
    """Single entry in the session action log."""

    row_id: int
    session_id: str
    action_type: str       # e.g. "module_created", "module_executed", "vlad_run", "repair"
    module_id: str
    details: Dict[str, Any]
    timestamp: datetime


@dataclass
class SessionSummary:
    """High-level summary of a session, ready for LLM prompt injection."""

    session_id: str
    total_actions: int
    modules_touched: List[str]
    action_counts: Dict[str, int]
    last_action: Optional[SessionAction]

    def as_text(self) -> str:
        """Return a compact, human-readable summary string for prompt injection."""
        if self.total_actions == 0:
            return f"Session {self.session_id}: no actions recorded yet."

        lines = [
            f"Session {self.session_id} — {self.total_actions} action(s):",
            f"  Modules touched: {', '.join(self.modules_touched) or 'none'}",
        ]
        for action_type, count in sorted(self.action_counts.items()):
            lines.append(f"  {action_type}: {count}")
        if self.last_action:
            lines.append(
                f"  Last action: {self.last_action.action_type} "
                f"on '{self.last_action.module_id}' "
                f"at {self.last_action.timestamp.isoformat()}"
            )
        return "\n".join(lines)


# ---------------------------------------------------------------------------
# Manager
# ---------------------------------------------------------------------------


class SessionContextManager:
    """Persist and retrieve per-session module lifecycle actions.

    The ``session_log`` table is created in the SQLite database at *db_path*
    automatically on first instantiation.

    For in-memory databases (``":memory:"``), a single persistent connection is
    kept for the lifetime of the manager so that all callers share the same
    in-memory database (each ``sqlite3.connect(":memory:")`` call would otherwise
    create an independent, empty database).

    Parameters
    ----------
    db_path:
        Path to the SQLite database file shared with other KFS services.
        Pass ``":memory:"`` for a transient, test-friendly in-memory database.
    """

    def __init__(self, db_path: str) -> None:
        self.db_path = db_path
        # For ":memory:" keep a single shared connection so the table (and data)
        # created in _ensure_table are visible to every subsequent operation.
        if db_path == ":memory:":
            self._shared_conn: Optional[sqlite3.Connection] = sqlite3.connect(
                ":memory:", check_same_thread=False
            )
        else:
            self._shared_conn = None
        self._ensure_table()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def log_action(
        self,
        session_id: str,
        action_type: str,
        module_id: str = "",
        details: Optional[Dict[str, Any]] = None,
    ) -> int:
        """Append one action to the session log and return its row id.

        Parameters
        ----------
        session_id:
            Identifies the chat session (e.g. a UUID or HTTP session token).
        action_type:
            Short label: ``"module_created"``, ``"module_executed"``,
            ``"vlad_run"``, ``"repair_attempted"``, ``"repair_succeeded"``, etc.
        module_id:
            Identifier of the affected module (empty string when not applicable).
        details:
            Arbitrary JSON-serialisable metadata (VLAD verdict, error text, …).

        Returns
        -------
        int
            Row id of the newly inserted record.
        """
        ts = datetime.now(timezone.utc).isoformat()
        details_json = json.dumps(details or {})
        with self._open_conn() as conn:
            cur = conn.execute(
                _INSERT_ACTION,
                (session_id, action_type, module_id, details_json, ts),
            )
            conn.commit()
            return cur.lastrowid

    def get_session_summary(self, session_id: str) -> SessionSummary:
        """Return an aggregated :class:`SessionSummary` for *session_id*.

        Suitable for injecting a brief "what happened this session" block into
        an LLM prompt without overwhelming it with raw rows.
        """
        actions = self._load_actions(session_id)

        action_counts: Dict[str, int] = {}
        modules_seen: list = []
        for a in actions:
            action_counts[a.action_type] = action_counts.get(a.action_type, 0) + 1
            if a.module_id and a.module_id not in modules_seen:
                modules_seen.append(a.module_id)

        return SessionSummary(
            session_id=session_id,
            total_actions=len(actions),
            modules_touched=modules_seen,
            action_counts=action_counts,
            last_action=actions[-1] if actions else None,
        )

    def build_module_context(
        self,
        session_id: str,
        module_id: str,
        max_actions: int = 20,
    ) -> str:
        """Build a prompt-ready context string for a specific module.

        Returns a structured text block describing recent lifecycle events for
        *module_id* within *session_id*, capped at *max_actions* to avoid
        ballooning the context window.

        Parameters
        ----------
        session_id:
            The current chat session.
        module_id:
            The module whose history to include.
        max_actions:
            Maximum number of actions to include (most recent wins).

        Returns
        -------
        str
            Ready-to-embed text block. Empty string if no history exists.
        """
        actions = self._load_module_actions(session_id, module_id)
        if not actions:
            return ""

        # Cap to most recent max_actions
        recent = actions[-max_actions:]

        lines = [f"Module '{module_id}' history ({len(recent)} event(s)):"]
        for a in recent:
            detail_str = ""
            if a.details:
                # Surface key fields; skip empty dicts
                relevant = {k: v for k, v in a.details.items() if v is not None}
                if relevant:
                    detail_str = " — " + ", ".join(
                        f"{k}={v}" for k, v in list(relevant.items())[:4]
                    )
            lines.append(
                f"  [{a.timestamp.strftime('%H:%M:%S')}] {a.action_type}{detail_str}"
            )
        return "\n".join(lines)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _load_actions(self, session_id: str) -> List[SessionAction]:
        with self._open_conn() as conn:
            rows = conn.execute(_SELECT_BY_SESSION, (session_id,)).fetchall()
        return [self._row_to_action(r) for r in rows]

    def _load_module_actions(
        self, session_id: str, module_id: str
    ) -> List[SessionAction]:
        with self._open_conn() as conn:
            rows = conn.execute(
                _SELECT_BY_MODULE, (session_id, module_id)
            ).fetchall()
        return [self._row_to_action(r) for r in rows]

    def _row_to_action(self, row: tuple) -> SessionAction:
        row_id, session_id, action_type, module_id, details_json, ts = row
        return SessionAction(
            row_id=row_id,
            session_id=session_id,
            action_type=action_type,
            module_id=module_id,
            details=json.loads(details_json or "{}"),
            timestamp=datetime.fromisoformat(ts),
        )

    def _ensure_table(self) -> None:
        with self._open_conn() as conn:
            conn.execute(_CREATE_SESSION_LOG)
            conn.commit()

    @contextlib.contextmanager
    def _open_conn(self):
        """Yield a connection; close it afterwards for file-based DBs."""
        if self._shared_conn is not None:
            yield self._shared_conn
            return
        conn = sqlite3.connect(self.db_path)
        try:
            yield conn
        finally:
            conn.close()
