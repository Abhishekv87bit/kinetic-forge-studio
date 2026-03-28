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
            CREATE TABLE IF NOT EXISTS chat_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id TEXT NOT NULL,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                model_used TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE INDEX IF NOT EXISTS idx_chat_messages_project
                ON chat_messages(project_id, created_at);
            CREATE TABLE IF NOT EXISTS snapshots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id TEXT NOT NULL,
                label TEXT NOT NULL,
                gate TEXT NOT NULL,
                spec_json TEXT,
                components_json TEXT,
                decisions_json TEXT,
                trigger TEXT DEFAULT 'auto',
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE INDEX IF NOT EXISTS idx_snapshots_project
                ON snapshots(project_id, created_at);
            CREATE TABLE IF NOT EXISTS modules (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                name TEXT NOT NULL,
                source_code TEXT NOT NULL,
                language TEXT DEFAULT 'python',
                version INTEGER DEFAULT 1,
                status TEXT DEFAULT 'active',
                parameters TEXT DEFAULT '{}',
                created_at TEXT,
                updated_at TEXT,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE TABLE IF NOT EXISTS module_versions (
                id TEXT PRIMARY KEY,
                module_id TEXT NOT NULL,
                version INTEGER NOT NULL,
                source_code TEXT NOT NULL,
                change_summary TEXT,
                created_at TEXT,
                FOREIGN KEY (module_id) REFERENCES modules(id)
            );
            CREATE TABLE IF NOT EXISTS vlad_results (
                id TEXT PRIMARY KEY,
                module_id TEXT NOT NULL,
                version INTEGER,
                tier TEXT,
                passed INTEGER,
                checks_run TEXT DEFAULT '[]',
                checks_passed TEXT DEFAULT '[]',
                checks_failed TEXT DEFAULT '[]',
                findings TEXT DEFAULT '[]',
                created_at TEXT,
                FOREIGN KEY (module_id) REFERENCES modules(id)
            );
            CREATE TABLE IF NOT EXISTS session_log (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                action TEXT NOT NULL,
                details TEXT DEFAULT '{}',
                module_id TEXT,
                created_at TEXT,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE INDEX IF NOT EXISTS idx_modules_project
                ON modules(project_id);
            CREATE INDEX IF NOT EXISTS idx_module_versions_module
                ON module_versions(module_id, version);
            CREATE INDEX IF NOT EXISTS idx_vlad_results_module
                ON vlad_results(module_id);
            CREATE INDEX IF NOT EXISTS idx_session_log_project
                ON session_log(project_id, created_at);
        """)
        await self.conn.commit()

    async def close(self):
        await self.conn.close()
