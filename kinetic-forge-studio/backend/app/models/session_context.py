import json
import secrets
from pathlib import Path
from datetime import datetime, timezone
from app.db.database import Database


class SessionLogManager:
    def __init__(self, data_dir: Path):
        self.data_dir = data_dir
        self.db = Database(data_dir / "studio.db")

    async def _ensure_db(self):
        if not hasattr(self.db, 'conn'):
            await self.db.connect()

    def _row_to_dict(self, r) -> dict:
        d = dict(r)
        if 'details' in d and isinstance(d['details'], str):
            try:
                d['details'] = json.loads(d['details'])
            except (json.JSONDecodeError, TypeError):
                d['details'] = {}
        return d

    async def log_action(self, project_id: str, action: str,
                         details: dict = None, module_id: str = None) -> dict:
        await self._ensure_db()
        entry_id = secrets.token_hex(6)
        now = datetime.now(timezone.utc).isoformat()
        details_str = json.dumps(details or {})
        await self.db.conn.execute(
            """INSERT INTO session_log (id, project_id, action, details, module_id, created_at)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (entry_id, project_id, action, details_str, module_id, now)
        )
        await self.db.conn.commit()
        cursor = await self.db.conn.execute(
            "SELECT * FROM session_log WHERE id = ?", (entry_id,)
        )
        row = await cursor.fetchone()
        return self._row_to_dict(row)

    async def get_log(self, project_id: str, limit: int = 50) -> list[dict]:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            """SELECT * FROM session_log WHERE project_id = ?
               ORDER BY created_at DESC LIMIT ?""",
            (project_id, limit)
        )
        rows = await cursor.fetchall()
        return [self._row_to_dict(r) for r in rows]

    async def get_module_log(self, module_id: str, limit: int = 50) -> list[dict]:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            """SELECT * FROM session_log WHERE module_id = ?
               ORDER BY created_at DESC LIMIT ?""",
            (module_id, limit)
        )
        rows = await cursor.fetchall()
        return [self._row_to_dict(r) for r in rows]
