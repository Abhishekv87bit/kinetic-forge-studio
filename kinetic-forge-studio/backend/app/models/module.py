import json
import secrets
from pathlib import Path
from datetime import datetime, timezone
from app.db.database import Database


class ModuleManager:
    def __init__(self, data_dir: Path):
        self.data_dir = data_dir
        self.db = Database(data_dir / "studio.db")

    async def _ensure_db(self):
        if not hasattr(self.db, 'conn'):
            await self.db.connect()

    def _row_to_dict(self, r) -> dict:
        d = dict(r)
        if 'parameters' in d and isinstance(d['parameters'], str):
            try:
                d['parameters'] = json.loads(d['parameters'])
            except (json.JSONDecodeError, TypeError):
                d['parameters'] = {}
        return d

    async def create(self, project_id: str, name: str, source_code: str,
                     language: str = "python", parameters: dict = None) -> dict:
        await self._ensure_db()
        module_id = secrets.token_hex(6)
        now = datetime.now(timezone.utc).isoformat()
        params_str = json.dumps(parameters or {})
        await self.db.conn.execute(
            """INSERT INTO modules (id, project_id, name, source_code, language,
               version, status, parameters, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, 1, 'active', ?, ?, ?)""",
            (module_id, project_id, name, source_code, language, params_str, now, now)
        )
        version_id = secrets.token_hex(6)
        await self.db.conn.execute(
            """INSERT INTO module_versions (id, module_id, version, source_code,
               change_summary, created_at) VALUES (?, ?, 1, ?, 'initial', ?)""",
            (version_id, module_id, source_code, now)
        )
        await self.db.conn.commit()
        return await self.get(project_id, module_id)

    async def get(self, project_id: str, module_id: str) -> dict:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            "SELECT * FROM modules WHERE id = ? AND project_id = ?",
            (module_id, project_id)
        )
        row = await cursor.fetchone()
        if not row:
            raise ValueError(f"Module {module_id} not found in project {project_id}")
        return self._row_to_dict(row)

    async def list_all(self, project_id: str) -> list[dict]:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            "SELECT * FROM modules WHERE project_id = ? ORDER BY created_at DESC",
            (project_id,)
        )
        rows = await cursor.fetchall()
        return [self._row_to_dict(r) for r in rows]

    async def update_source(self, project_id: str, module_id: str,
                            source_code: str, change_summary: str = "") -> dict:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            "SELECT version FROM modules WHERE id = ? AND project_id = ?",
            (module_id, project_id)
        )
        row = await cursor.fetchone()
        if not row:
            raise ValueError(f"Module {module_id} not found in project {project_id}")
        new_version = row["version"] + 1
        now = datetime.now(timezone.utc).isoformat()
        await self.db.conn.execute(
            """UPDATE modules SET source_code = ?, version = ?, updated_at = ?
               WHERE id = ? AND project_id = ?""",
            (source_code, new_version, now, module_id, project_id)
        )
        version_id = secrets.token_hex(6)
        await self.db.conn.execute(
            """INSERT INTO module_versions (id, module_id, version, source_code,
               change_summary, created_at) VALUES (?, ?, ?, ?, ?, ?)""",
            (version_id, module_id, new_version, source_code, change_summary, now)
        )
        await self.db.conn.commit()
        return await self.get(project_id, module_id)

    async def get_versions(self, module_id: str) -> list[dict]:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            """SELECT * FROM module_versions WHERE module_id = ?
               ORDER BY version DESC""",
            (module_id,)
        )
        rows = await cursor.fetchall()
        return [dict(r) for r in rows]

    async def rollback(self, project_id: str, module_id: str,
                       target_version: int) -> dict:
        await self._ensure_db()
        cursor = await self.db.conn.execute(
            """SELECT source_code FROM module_versions
               WHERE module_id = ? AND version = ?""",
            (module_id, target_version)
        )
        row = await cursor.fetchone()
        if not row:
            raise ValueError(
                f"Version {target_version} not found for module {module_id}"
            )
        return await self.update_source(
            project_id, module_id, row["source_code"],
            change_summary=f"rollback to v{target_version}"
        )
