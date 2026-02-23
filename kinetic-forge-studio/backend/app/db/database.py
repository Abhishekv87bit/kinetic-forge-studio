import aiosqlite
from pathlib import Path

class Database:
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

    async def connect(self):
        self.conn = await aiosqlite.connect(self.db_path)
        self.conn.row_factory = aiosqlite.Row
        await self._init_tables()
        return self

    async def _init_tables(self):
        await self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS projects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                gate TEXT DEFAULT 'design',
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now')),
                data_dir TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS decisions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id TEXT NOT NULL,
                parameter TEXT NOT NULL,
                value TEXT NOT NULL,
                reason TEXT,
                source TEXT DEFAULT 'user',
                session_id TEXT,
                status TEXT DEFAULT 'proposed',
                superseded_by INTEGER,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE TABLE IF NOT EXISTS components (
                id TEXT NOT NULL,
                project_id TEXT NOT NULL,
                display_name TEXT NOT NULL,
                component_type TEXT,
                parameters TEXT,
                position TEXT,
                decided_by TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                PRIMARY KEY (id, project_id),
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE TABLE IF NOT EXISTS library (
                id TEXT PRIMARY KEY,
                name TEXT,
                source TEXT,
                mechanism_types TEXT,
                keywords TEXT,
                envelope_x REAL,
                envelope_y REAL,
                envelope_z REAL,
                file_path TEXT,
                thumbnail_path TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                project_id TEXT
            );
        """)
        await self.conn.commit()

    async def close(self):
        await self.conn.close()
