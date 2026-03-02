import uuid
import json
from pathlib import Path
from dataclasses import dataclass, field
from datetime import datetime
from app.db.database import Database

@dataclass
class Project:
    id: str
    name: str
    gate: str = "design"
    created_at: str = ""
    updated_at: str = ""
    data_dir: Path = field(default_factory=Path)
    scad_dir: str | None = None

class ProjectManager:
    def __init__(self, data_dir: Path):
        self.data_dir = data_dir
        self.db = Database(data_dir / "studio.db")

    async def _ensure_db(self):
        if not hasattr(self.db, 'conn'):
            await self.db.connect()

    async def create(self, name: str) -> Project:
        await self._ensure_db()
        project_id = uuid.uuid4().hex[:12]
        project_dir = self.data_dir / "projects" / project_id
        project_dir.mkdir(parents=True, exist_ok=True)
        (project_dir / "references").mkdir(exist_ok=True)
        (project_dir / "models").mkdir(exist_ok=True)
        (project_dir / "exports").mkdir(exist_ok=True)
        (project_dir / "renders").mkdir(exist_ok=True)
        (project_dir / "validation").mkdir(exist_ok=True)
        (project_dir / "sessions").mkdir(exist_ok=True)

        now = datetime.utcnow().isoformat()
        await self.db.conn.execute(
            "INSERT INTO projects (id, name, gate, created_at, updated_at, data_dir) VALUES (?, ?, ?, ?, ?, ?)",
            (project_id, name, "design", now, now, str(project_dir))
        )
        await self.db.conn.commit()
        return Project(id=project_id, name=name, gate="design", created_at=now, updated_at=now, data_dir=project_dir)

    def _row_to_project(self, r) -> Project:
        """Convert a database row to a Project, handling optional columns."""
        # scad_dir may not exist in older databases
        scad_dir = r["scad_dir"] if "scad_dir" in r.keys() else None
        return Project(
            id=r["id"], name=r["name"], gate=r["gate"],
            created_at=r["created_at"], updated_at=r["updated_at"],
            data_dir=Path(r["data_dir"]), scad_dir=scad_dir,
        )

    async def list_all(self) -> list[Project]:
        await self._ensure_db()
        # Ensure scad_dir column exists (migration for older databases)
        await self._ensure_scad_dir_column()
        cursor = await self.db.conn.execute("SELECT * FROM projects ORDER BY updated_at DESC")
        rows = await cursor.fetchall()
        return [self._row_to_project(r) for r in rows]

    async def open(self, project_id: str) -> Project:
        await self._ensure_db()
        await self._ensure_scad_dir_column()
        cursor = await self.db.conn.execute("SELECT * FROM projects WHERE id = ?", (project_id,))
        r = await cursor.fetchone()
        if not r:
            raise ValueError(f"Project {project_id} not found")
        return self._row_to_project(r)

    async def set_scad_dir(self, project_id: str, scad_dir: str) -> Project:
        """Link an OpenSCAD source directory to a project."""
        await self._ensure_db()
        await self._ensure_scad_dir_column()
        await self.db.conn.execute(
            "UPDATE projects SET scad_dir = ?, updated_at = datetime('now') WHERE id = ?",
            (scad_dir, project_id),
        )
        await self.db.conn.commit()
        return await self.open(project_id)

    async def _ensure_scad_dir_column(self):
        """Add scad_dir column if missing (backwards-compatible migration)."""
        try:
            await self.db.conn.execute("SELECT scad_dir FROM projects LIMIT 1")
        except Exception:
            await self.db.conn.execute("ALTER TABLE projects ADD COLUMN scad_dir TEXT")
            await self.db.conn.commit()
