# Kinetic Forge Studio — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a standalone web app for kinetic sculpture design — chat-driven, 3D viewport, persistent project memory, automated validation, STEP export.

**Architecture:** FastAPI Python backend orchestrates all tools (CadQuery, OpenSCAD, trimesh, Claude API). React + React-Three-Fiber frontend with three-panel layout (chat, 3D viewport, spec/decisions). SQLite for project persistence and library indexing.

**Tech Stack:** Python 3.11+, FastAPI, React 18, TypeScript, React-Three-Fiber, Three.js, P5.js, CadQuery, trimesh, SQLite, Claude API

**Design Doc:** `docs/plans/2026-02-23-kinetic-forge-studio-design.md`

---

## Phase 1: Project Scaffold + Smoke Test

**Deliverable:** Backend serves API, frontend renders three-panel layout with a test cube in the 3D viewport. Proves the full stack works end-to-end.

---

### Task 1: Backend Scaffold

**Files:**
- Create: `kinetic-forge-studio/backend/pyproject.toml`
- Create: `kinetic-forge-studio/backend/app/__init__.py`
- Create: `kinetic-forge-studio/backend/app/main.py`
- Create: `kinetic-forge-studio/backend/app/config.py`
- Test: `kinetic-forge-studio/backend/tests/test_health.py`

**Step 1: Create project directory and pyproject.toml**

```toml
[project]
name = "kinetic-forge-studio"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.109",
    "uvicorn[standard]>=0.27",
    "pydantic>=2.5",
    "pydantic-settings>=2.1",
    "aiosqlite>=0.19",
    "python-multipart>=0.0.6",
]

[project.optional-dependencies]
dev = ["pytest>=8.0", "pytest-asyncio>=0.23", "httpx>=0.26"]
cad = ["cadquery>=2.4", "trimesh>=4.0", "Pillow>=10.0"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

**Step 2: Write the failing test**

```python
# tests/test_health.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data
```

**Step 3: Run test to verify it fails**

Run: `cd kinetic-forge-studio/backend && pip install -e ".[dev]" && pytest tests/test_health.py -v`
Expected: FAIL — `app.main` doesn't exist

**Step 4: Write config.py**

```python
# app/config.py
from pydantic_settings import BaseSettings
from pathlib import Path

class Settings(BaseSettings):
    app_name: str = "Kinetic Forge Studio"
    version: str = "0.1.0"
    debug: bool = True
    data_dir: Path = Path.home() / ".kinetic-forge-studio"
    projects_dir: Path = Path.home() / ".kinetic-forge-studio" / "projects"
    library_dir: Path = Path.home() / ".kinetic-forge-studio" / "library"
    openscad_path: str = "C:/Program Files/OpenSCAD (Nightly)/openscad.com"
    freecad_path: str = "C:/Program Files/FreeCAD 1.0/bin/FreeCADCmd.exe"
    claude_api_key: str = ""
    cors_origins: list[str] = ["http://localhost:5173"]

    class Config:
        env_prefix = "KFS_"

settings = Settings()
```

**Step 5: Write main.py**

```python
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(title=settings.app_name, version=settings.version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
async def health():
    return {"status": "ok", "version": settings.version}
```

**Step 6: Run test to verify it passes**

Run: `pytest tests/test_health.py -v`
Expected: PASS

**Step 7: Commit**

```bash
git add kinetic-forge-studio/backend/
git commit -m "feat: backend scaffold with FastAPI health endpoint"
```

---

### Task 2: Frontend Scaffold

**Files:**
- Create: `kinetic-forge-studio/frontend/` (via Vite)
- Modify: `kinetic-forge-studio/frontend/src/App.tsx`
- Create: `kinetic-forge-studio/frontend/src/api/client.ts`

**Step 1: Scaffold React + TypeScript project**

Run: `cd kinetic-forge-studio && npm create vite@latest frontend -- --template react-ts`

**Step 2: Install dependencies**

Run: `cd kinetic-forge-studio/frontend && npm install @react-three/fiber @react-three/drei three zustand && npm install -D @types/three`

**Step 3: Create API client**

```typescript
// src/api/client.ts
const API_BASE = "http://localhost:8000/api";

export async function fetchHealth() {
    const res = await fetch(`${API_BASE}/health`);
    return res.json();
}
```

**Step 4: Replace App.tsx with three-panel layout skeleton**

```tsx
// src/App.tsx
import { useState, useEffect } from "react";
import { fetchHealth } from "./api/client";

function App() {
    const [status, setStatus] = useState<string>("connecting...");

    useEffect(() => {
        fetchHealth()
            .then((data) => setStatus(`${data.status} v${data.version}`))
            .catch(() => setStatus("backend offline"));
    }, []);

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100vh" }}>
            <header style={{ padding: "8px 16px", borderBottom: "1px solid #333", background: "#1a1a2e", color: "#fff", display: "flex", justifyContent: "space-between" }}>
                <span>Kinetic Forge Studio</span>
                <span style={{ fontSize: "12px", opacity: 0.6 }}>{status}</span>
            </header>
            <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
                <div style={{ width: "280px", borderRight: "1px solid #333", padding: "16px", background: "#16213e", color: "#fff" }}>
                    <h3>Chat</h3>
                    <p style={{ opacity: 0.5 }}>Chat panel placeholder</p>
                </div>
                <div style={{ flex: 1, background: "#0a0a0a" }}>
                    <p style={{ color: "#666", padding: "16px" }}>3D Viewport placeholder</p>
                </div>
                <div style={{ width: "280px", borderLeft: "1px solid #333", padding: "16px", background: "#16213e", color: "#fff" }}>
                    <h3>Spec Sheet</h3>
                    <p style={{ opacity: 0.5 }}>Side panel placeholder</p>
                </div>
            </div>
            <div style={{ height: "48px", borderTop: "1px solid #333", padding: "8px 16px", background: "#1a1a2e", color: "#fff", display: "flex", alignItems: "center" }}>
                <span style={{ opacity: 0.5 }}>Timeline placeholder</span>
            </div>
        </div>
    );
}

export default App;
```

**Step 5: Verify frontend connects to backend**

Run (terminal 1): `cd kinetic-forge-studio/backend && uvicorn app.main:app --reload --port 8000`
Run (terminal 2): `cd kinetic-forge-studio/frontend && npm run dev`
Expected: Browser shows three-panel layout, header shows "ok v0.1.0"

**Step 6: Commit**

```bash
git add kinetic-forge-studio/frontend/
git commit -m "feat: frontend scaffold with three-panel layout + API connection"
```

---

### Task 3: 3D Viewport with Test Cube

**Files:**
- Create: `kinetic-forge-studio/frontend/src/components/Viewport3D.tsx`
- Modify: `kinetic-forge-studio/frontend/src/App.tsx`

**Step 1: Create Viewport3D component with R3F**

```tsx
// src/components/Viewport3D.tsx
import { Canvas } from "@react-three/fiber";
import { OrbitControls, Grid, Environment } from "@react-three/drei";

function TestCube() {
    return (
        <mesh>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="#4a9eff" />
        </mesh>
    );
}

export default function Viewport3D() {
    return (
        <Canvas camera={{ position: [3, 3, 3], fov: 50 }}>
            <ambientLight intensity={0.4} />
            <directionalLight position={[5, 5, 5]} intensity={0.8} />
            <TestCube />
            <OrbitControls
                enableDamping
                dampingFactor={0.05}
                rotateSpeed={0.5}
                panSpeed={0.5}
                zoomSpeed={0.8}
            />
            <Grid
                infiniteGrid
                cellSize={1}
                sectionSize={5}
                fadeDistance={30}
                cellColor="#333"
                sectionColor="#555"
            />
        </Canvas>
    );
}
```

**Step 2: Wire viewport into App.tsx**

Replace the viewport placeholder div with:
```tsx
import Viewport3D from "./components/Viewport3D";
// ...
<div style={{ flex: 1, background: "#0a0a0a" }}>
    <Viewport3D />
</div>
```

**Step 3: Verify in browser**

Run: both backend and frontend dev servers
Expected: Blue test cube in center panel. Orbit with left-drag. Pan with right-drag. Zoom with scroll. Grid visible on ground plane.

**Step 4: Commit**

```bash
git add kinetic-forge-studio/frontend/src/
git commit -m "feat: 3D viewport with R3F, orbit controls, and test cube"
```

---

## Phase 2: Backend Data Layer

**Deliverable:** Projects can be created, opened, listed. Decisions and components are persisted. User profile stores preferences. All data survives server restart.

---

### Task 4: SQLite Database + Project Model

**Files:**
- Create: `kinetic-forge-studio/backend/app/db/database.py`
- Create: `kinetic-forge-studio/backend/app/models/project.py`
- Test: `kinetic-forge-studio/backend/tests/test_project_model.py`

**Step 1: Write failing tests**

```python
# tests/test_project_model.py
import pytest
from pathlib import Path
from app.models.project import ProjectManager, Project

@pytest.fixture
def pm(tmp_path):
    return ProjectManager(data_dir=tmp_path)

@pytest.mark.asyncio
async def test_create_project(pm):
    project = await pm.create("ravigneaux_compact")
    assert project.name == "ravigneaux_compact"
    assert project.id is not None
    assert project.gate == "design"
    assert project.data_dir.exists()

@pytest.mark.asyncio
async def test_list_projects(pm):
    await pm.create("project_a")
    await pm.create("project_b")
    projects = await pm.list_all()
    assert len(projects) == 2

@pytest.mark.asyncio
async def test_open_project(pm):
    created = await pm.create("test_project")
    opened = await pm.open(created.id)
    assert opened.name == "test_project"
    assert opened.id == created.id

@pytest.mark.asyncio
async def test_project_persists_across_instances(tmp_path):
    pm1 = ProjectManager(data_dir=tmp_path)
    created = await pm1.create("persistent")
    pm2 = ProjectManager(data_dir=tmp_path)
    projects = await pm2.list_all()
    assert len(projects) == 1
    assert projects[0].name == "persistent"
```

**Step 2: Run tests to verify they fail**

Run: `pytest tests/test_project_model.py -v`
Expected: FAIL — modules don't exist

**Step 3: Write database.py**

```python
# app/db/database.py
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
```

**Step 4: Write project.py**

```python
# app/models/project.py
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

    async def list_all(self) -> list[Project]:
        await self._ensure_db()
        cursor = await self.db.conn.execute("SELECT * FROM projects ORDER BY updated_at DESC")
        rows = await cursor.fetchall()
        return [Project(id=r["id"], name=r["name"], gate=r["gate"],
                        created_at=r["created_at"], updated_at=r["updated_at"],
                        data_dir=Path(r["data_dir"])) for r in rows]

    async def open(self, project_id: str) -> Project:
        await self._ensure_db()
        cursor = await self.db.conn.execute("SELECT * FROM projects WHERE id = ?", (project_id,))
        r = await cursor.fetchone()
        if not r:
            raise ValueError(f"Project {project_id} not found")
        return Project(id=r["id"], name=r["name"], gate=r["gate"],
                       created_at=r["created_at"], updated_at=r["updated_at"],
                       data_dir=Path(r["data_dir"]))
```

**Step 5: Run tests to verify they pass**

Run: `pytest tests/test_project_model.py -v`
Expected: All 4 PASS

**Step 6: Commit**

```bash
git add kinetic-forge-studio/backend/
git commit -m "feat: SQLite database + project model with CRUD"
```

---

### Task 5: Decision Log Model

**Files:**
- Create: `kinetic-forge-studio/backend/app/models/decision.py`
- Test: `kinetic-forge-studio/backend/tests/test_decision_model.py`

**Step 1: Write failing tests**

```python
# tests/test_decision_model.py
import pytest
from app.models.project import ProjectManager
from app.models.decision import DecisionManager

@pytest.fixture
async def setup(tmp_path):
    pm = ProjectManager(data_dir=tmp_path)
    project = await pm.create("test")
    dm = DecisionManager(pm.db)
    return dm, project.id

@pytest.mark.asyncio
async def test_add_decision(setup):
    dm, pid = await setup
    d = await dm.add(pid, parameter="ring_gear.OD", value="82mm", reason="Fits housing")
    assert d["id"] == 1
    assert d["status"] == "proposed"

@pytest.mark.asyncio
async def test_lock_decision(setup):
    dm, pid = await setup
    await dm.add(pid, parameter="ring_gear.OD", value="82mm", reason="Fits housing")
    d = await dm.lock(pid, decision_id=1)
    assert d["status"] == "locked"

@pytest.mark.asyncio
async def test_conflict_detection(setup):
    dm, pid = await setup
    await dm.add(pid, parameter="ring_gear.OD", value="82mm", reason="Fits housing")
    await dm.lock(pid, decision_id=1)
    conflicts = await dm.check_conflicts(pid, parameter="ring_gear.OD", value="55mm")
    assert len(conflicts) == 1
    assert conflicts[0]["value"] == "82mm"

@pytest.mark.asyncio
async def test_supersede_decision(setup):
    dm, pid = await setup
    await dm.add(pid, parameter="module", value="1.5", reason="Standard")
    await dm.lock(pid, decision_id=1)
    await dm.supersede(pid, old_id=1, new_value="1.0", reason="Compacting")
    decisions = await dm.list_all(pid)
    old = [d for d in decisions if d["id"] == 1][0]
    assert old["status"] == "superseded"
    new = [d for d in decisions if d["id"] == 2][0]
    assert new["value"] == "1.0"

@pytest.mark.asyncio
async def test_list_locked_only(setup):
    dm, pid = await setup
    await dm.add(pid, parameter="OD", value="82mm", reason="")
    await dm.add(pid, parameter="teeth", value="48", reason="")
    await dm.lock(pid, decision_id=1)
    locked = await dm.list_locked(pid)
    assert len(locked) == 1
```

**Step 2: Run tests to verify they fail**

Run: `pytest tests/test_decision_model.py -v`
Expected: FAIL

**Step 3: Write decision.py**

```python
# app/models/decision.py
from app.db.database import Database

class DecisionManager:
    def __init__(self, db: Database):
        self.db = db

    async def add(self, project_id: str, parameter: str, value: str,
                  reason: str = "", source: str = "user", session_id: str = None) -> dict:
        cursor = await self.db.conn.execute(
            """INSERT INTO decisions (project_id, parameter, value, reason, source, session_id, status)
               VALUES (?, ?, ?, ?, ?, ?, 'proposed')""",
            (project_id, parameter, value, reason, source, session_id)
        )
        await self.db.conn.commit()
        return {"id": cursor.lastrowid, "parameter": parameter, "value": value,
                "reason": reason, "source": source, "status": "proposed"}

    async def lock(self, project_id: str, decision_id: int) -> dict:
        await self.db.conn.execute(
            "UPDATE decisions SET status = 'locked' WHERE id = ? AND project_id = ?",
            (decision_id, project_id)
        )
        await self.db.conn.commit()
        cursor = await self.db.conn.execute("SELECT * FROM decisions WHERE id = ?", (decision_id,))
        row = await cursor.fetchone()
        return dict(row)

    async def check_conflicts(self, project_id: str, parameter: str, value: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            """SELECT * FROM decisions
               WHERE project_id = ? AND parameter = ? AND status = 'locked' AND value != ?""",
            (project_id, parameter, value)
        )
        rows = await cursor.fetchall()
        return [dict(r) for r in rows]

    async def supersede(self, project_id: str, old_id: int, new_value: str, reason: str = "") -> dict:
        cursor = await self.db.conn.execute("SELECT * FROM decisions WHERE id = ?", (old_id,))
        old = await cursor.fetchone()
        new = await self.add(project_id, parameter=old["parameter"], value=new_value,
                             reason=reason, source="user")
        await self.db.conn.execute(
            "UPDATE decisions SET status = 'superseded', superseded_by = ? WHERE id = ?",
            (new["id"], old_id)
        )
        await self.db.conn.commit()
        return new

    async def list_all(self, project_id: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            "SELECT * FROM decisions WHERE project_id = ? ORDER BY id", (project_id,))
        return [dict(r) for r in await cursor.fetchall()]

    async def list_locked(self, project_id: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            "SELECT * FROM decisions WHERE project_id = ? AND status = 'locked' ORDER BY id",
            (project_id,))
        return [dict(r) for r in await cursor.fetchall()]
```

**Step 4: Run tests to verify they pass**

Run: `pytest tests/test_decision_model.py -v`
Expected: All 5 PASS

**Step 5: Commit**

```bash
git add kinetic-forge-studio/backend/
git commit -m "feat: decision log with lock, conflict detection, supersede"
```

---

### Task 6: Component Registry Model

**Files:**
- Create: `kinetic-forge-studio/backend/app/models/component.py`
- Test: `kinetic-forge-studio/backend/tests/test_component_model.py`

**Step 1: Write failing tests**

```python
# tests/test_component_model.py
import pytest
from app.models.project import ProjectManager
from app.models.component import ComponentManager

@pytest.fixture
async def setup(tmp_path):
    pm = ProjectManager(data_dir=tmp_path)
    project = await pm.create("test")
    cm = ComponentManager(pm.db)
    return cm, project.id

@pytest.mark.asyncio
async def test_register_component(setup):
    cm, pid = await setup
    c = await cm.register(pid, component_id="ring_gear_01", display_name="Ring Gear",
                          component_type="gear", parameters={"teeth": 48, "module": 1.5, "OD": 82.0})
    assert c["id"] == "ring_gear_01"
    assert c["display_name"] == "Ring Gear"

@pytest.mark.asyncio
async def test_get_component(setup):
    cm, pid = await setup
    await cm.register(pid, "sun_gear_01", "Sun Gear", "gear", {"teeth": 16})
    c = await cm.get(pid, "sun_gear_01")
    assert c["parameters"]["teeth"] == 16

@pytest.mark.asyncio
async def test_list_components(setup):
    cm, pid = await setup
    await cm.register(pid, "ring_01", "Ring", "gear", {})
    await cm.register(pid, "sun_01", "Sun", "gear", {})
    await cm.register(pid, "planet_01", "Planet 1", "gear", {})
    components = await cm.list_all(pid)
    assert len(components) == 3

@pytest.mark.asyncio
async def test_update_parameters(setup):
    cm, pid = await setup
    await cm.register(pid, "ring_01", "Ring", "gear", {"teeth": 48})
    await cm.update_params(pid, "ring_01", {"teeth": 42, "module": 1.0})
    c = await cm.get(pid, "ring_01")
    assert c["parameters"]["teeth"] == 42
    assert c["parameters"]["module"] == 1.0

@pytest.mark.asyncio
async def test_duplicate_id_raises(setup):
    cm, pid = await setup
    await cm.register(pid, "ring_01", "Ring", "gear", {})
    with pytest.raises(ValueError, match="already exists"):
        await cm.register(pid, "ring_01", "Another Ring", "gear", {})

@pytest.mark.asyncio
async def test_registry_as_context_dict(setup):
    cm, pid = await setup
    await cm.register(pid, "ring_01", "Ring Gear", "gear", {"teeth": 48})
    await cm.register(pid, "sun_01", "Sun Gear", "gear", {"teeth": 16})
    context = await cm.as_context(pid)
    assert "ring_01" in context
    assert context["ring_01"]["display_name"] == "Ring Gear"
```

**Step 2: Run tests to verify they fail**

Run: `pytest tests/test_component_model.py -v`
Expected: FAIL

**Step 3: Write component.py**

```python
# app/models/component.py
import json
from app.db.database import Database

class ComponentManager:
    def __init__(self, db: Database):
        self.db = db

    async def register(self, project_id: str, component_id: str, display_name: str,
                       component_type: str, parameters: dict, position: dict = None,
                       decided_by: list[int] = None) -> dict:
        existing = await self.db.conn.execute(
            "SELECT id FROM components WHERE id = ? AND project_id = ?",
            (component_id, project_id))
        if await existing.fetchone():
            raise ValueError(f"Component '{component_id}' already exists in this project")

        await self.db.conn.execute(
            """INSERT INTO components (id, project_id, display_name, component_type,
               parameters, position, decided_by) VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (component_id, project_id, display_name, component_type,
             json.dumps(parameters), json.dumps(position or {}),
             json.dumps(decided_by or []))
        )
        await self.db.conn.commit()
        return {"id": component_id, "display_name": display_name,
                "type": component_type, "parameters": parameters}

    async def get(self, project_id: str, component_id: str) -> dict:
        cursor = await self.db.conn.execute(
            "SELECT * FROM components WHERE id = ? AND project_id = ?",
            (component_id, project_id))
        row = await cursor.fetchone()
        if not row:
            raise ValueError(f"Component '{component_id}' not found")
        return {"id": row["id"], "display_name": row["display_name"],
                "type": row["component_type"],
                "parameters": json.loads(row["parameters"]),
                "position": json.loads(row["position"]),
                "decided_by": json.loads(row["decided_by"])}

    async def list_all(self, project_id: str) -> list[dict]:
        cursor = await self.db.conn.execute(
            "SELECT * FROM components WHERE project_id = ? ORDER BY created_at", (project_id,))
        rows = await cursor.fetchall()
        return [{"id": r["id"], "display_name": r["display_name"],
                 "type": r["component_type"],
                 "parameters": json.loads(r["parameters"])}
                for r in rows]

    async def update_params(self, project_id: str, component_id: str, params: dict):
        current = await self.get(project_id, component_id)
        merged = {**current["parameters"], **params}
        await self.db.conn.execute(
            "UPDATE components SET parameters = ? WHERE id = ? AND project_id = ?",
            (json.dumps(merged), component_id, project_id))
        await self.db.conn.commit()

    async def as_context(self, project_id: str) -> dict:
        components = await self.list_all(project_id)
        return {c["id"]: c for c in components}
```

**Step 4: Run tests to verify they pass**

Run: `pytest tests/test_component_model.py -v`
Expected: All 6 PASS

**Step 5: Commit**

```bash
git add kinetic-forge-studio/backend/
git commit -m "feat: component identity registry with locked IDs"
```

---

### Task 7: User Profile + REST API Routes

**Files:**
- Create: `kinetic-forge-studio/backend/app/models/profile.py`
- Create: `kinetic-forge-studio/backend/app/routes/projects.py`
- Test: `kinetic-forge-studio/backend/tests/test_profile.py`
- Test: `kinetic-forge-studio/backend/tests/test_routes_projects.py`

**Step 1: Write profile tests**

```python
# tests/test_profile.py
import pytest
from pathlib import Path
from app.models.profile import UserProfile

@pytest.fixture
def profile(tmp_path):
    return UserProfile(config_dir=tmp_path)

def test_default_profile(profile):
    data = profile.load()
    assert data["printer"]["tolerance"] == 0.2
    assert data["preferences"]["shaft_standard"] == 8

def test_update_profile(profile):
    profile.update({"printer": {"tolerance": 0.3}})
    data = profile.load()
    assert data["printer"]["tolerance"] == 0.3

def test_profile_persists(tmp_path):
    p1 = UserProfile(config_dir=tmp_path)
    p1.update({"preferences": {"default_material": "wood"}})
    p2 = UserProfile(config_dir=tmp_path)
    assert p2.load()["preferences"]["default_material"] == "wood"
```

**Step 2: Write profile.py**

```python
# app/models/profile.py
import json
from pathlib import Path
from copy import deepcopy

DEFAULT_PROFILE = {
    "printer": {
        "type": "FDM",
        "nozzle": 0.4,
        "layer_height": 0.2,
        "tolerance": 0.2,
        "min_wall": 1.5,
        "max_overhang": 45
    },
    "preferences": {
        "default_material": "PLA",
        "default_module": 1.5,
        "preferred_mechanisms": ["four_bar", "planetary", "scotch_yoke"],
        "shaft_standard": 8
    },
    "style_tags": ["organic", "wave", "museum_quality"],
    "production_target": "metal_and_wood"
}

class UserProfile:
    def __init__(self, config_dir: Path):
        self.path = config_dir / "profile.json"
        if not self.path.exists():
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self._save(DEFAULT_PROFILE)

    def load(self) -> dict:
        return json.loads(self.path.read_text())

    def update(self, updates: dict):
        data = self.load()
        self._deep_merge(data, updates)
        self._save(data)

    def _save(self, data: dict):
        self.path.write_text(json.dumps(data, indent=2))

    def _deep_merge(self, base: dict, updates: dict):
        for key, value in updates.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._deep_merge(base[key], value)
            else:
                base[key] = value
```

**Step 3: Write routes/projects.py**

```python
# app/routes/projects.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.models.project import ProjectManager
from app.models.decision import DecisionManager
from app.models.component import ComponentManager
from app.config import settings

router = APIRouter(prefix="/api/projects", tags=["projects"])

_pm: ProjectManager | None = None

async def get_pm() -> ProjectManager:
    global _pm
    if _pm is None:
        _pm = ProjectManager(data_dir=settings.data_dir)
    return _pm

class CreateProjectRequest(BaseModel):
    name: str

class AddDecisionRequest(BaseModel):
    parameter: str
    value: str
    reason: str = ""

class RegisterComponentRequest(BaseModel):
    component_id: str
    display_name: str
    component_type: str
    parameters: dict = {}

@router.get("")
async def list_projects():
    pm = await get_pm()
    projects = await pm.list_all()
    return [{"id": p.id, "name": p.name, "gate": p.gate,
             "created_at": p.created_at, "updated_at": p.updated_at} for p in projects]

@router.post("")
async def create_project(req: CreateProjectRequest):
    pm = await get_pm()
    project = await pm.create(req.name)
    return {"id": project.id, "name": project.name, "gate": project.gate}

@router.get("/{project_id}")
async def get_project(project_id: str):
    pm = await get_pm()
    try:
        p = await pm.open(project_id)
        dm = DecisionManager(pm.db)
        cm = ComponentManager(pm.db)
        return {
            "id": p.id, "name": p.name, "gate": p.gate,
            "decisions": await dm.list_all(p.id),
            "components": await cm.list_all(p.id)
        }
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

@router.post("/{project_id}/decisions")
async def add_decision(project_id: str, req: AddDecisionRequest):
    pm = await get_pm()
    dm = DecisionManager(pm.db)
    conflicts = await dm.check_conflicts(project_id, req.parameter, req.value)
    decision = await dm.add(project_id, req.parameter, req.value, req.reason)
    return {"decision": decision, "conflicts": conflicts}

@router.post("/{project_id}/decisions/{decision_id}/lock")
async def lock_decision(project_id: str, decision_id: int):
    pm = await get_pm()
    dm = DecisionManager(pm.db)
    return await dm.lock(project_id, decision_id)

@router.post("/{project_id}/components")
async def register_component(project_id: str, req: RegisterComponentRequest):
    pm = await get_pm()
    cm = ComponentManager(pm.db)
    try:
        return await cm.register(project_id, req.component_id, req.display_name,
                                 req.component_type, req.parameters)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))

@router.get("/{project_id}/components")
async def list_components(project_id: str):
    pm = await get_pm()
    cm = ComponentManager(pm.db)
    return await cm.list_all(project_id)
```

**Step 4: Wire routes into main.py**

Add to `app/main.py`:
```python
from app.routes.projects import router as projects_router
app.include_router(projects_router)
```

**Step 5: Write route tests**

```python
# tests/test_routes_projects.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.routes.projects import _pm, get_pm

@pytest.fixture(autouse=True)
async def reset_pm(tmp_path, monkeypatch):
    from app.routes import projects
    from app.models.project import ProjectManager
    pm = ProjectManager(data_dir=tmp_path)
    projects._pm = pm
    yield
    projects._pm = None

@pytest.mark.asyncio
async def test_create_and_list_projects():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.post("/api/projects", json={"name": "test_project"})
        assert res.status_code == 200
        project_id = res.json()["id"]

        res = await c.get("/api/projects")
        assert len(res.json()) == 1

@pytest.mark.asyncio
async def test_add_decision_with_conflict():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        res = await c.post("/api/projects", json={"name": "test"})
        pid = res.json()["id"]

        await c.post(f"/api/projects/{pid}/decisions",
                     json={"parameter": "OD", "value": "82mm"})
        await c.post(f"/api/projects/{pid}/decisions/1/lock")

        res = await c.post(f"/api/projects/{pid}/decisions",
                           json={"parameter": "OD", "value": "55mm"})
        assert len(res.json()["conflicts"]) == 1
```

**Step 6: Run all tests**

Run: `pytest tests/ -v`
Expected: All tests PASS

**Step 7: Commit**

```bash
git add kinetic-forge-studio/backend/
git commit -m "feat: user profile, REST API routes for projects/decisions/components"
```

---

## Phase 3: Frontend Core UI

**Deliverable:** Home screen with project list, design workspace with working chat panel and spec sheet sidebar. Frontend connects to real backend data.

---

### Task 8: Zustand State Store + Home Screen

**Files:**
- Create: `kinetic-forge-studio/frontend/src/stores/projectStore.ts`
- Create: `kinetic-forge-studio/frontend/src/components/HomeScreen.tsx`
- Modify: `kinetic-forge-studio/frontend/src/App.tsx`
- Create: `kinetic-forge-studio/frontend/src/api/client.ts` (expand)

**Step 1: Expand API client**

```typescript
// src/api/client.ts
const API_BASE = "http://localhost:8000/api";

async function api(path: string, options?: RequestInit) {
    const res = await fetch(`${API_BASE}${path}`, {
        headers: { "Content-Type": "application/json" },
        ...options,
    });
    if (!res.ok) throw new Error(`API error: ${res.status}`);
    return res.json();
}

export const projectsApi = {
    list: () => api("/projects"),
    create: (name: string) => api("/projects", { method: "POST", body: JSON.stringify({ name }) }),
    get: (id: string) => api(`/projects/${id}`),
    addDecision: (id: string, data: { parameter: string; value: string; reason?: string }) =>
        api(`/projects/${id}/decisions`, { method: "POST", body: JSON.stringify(data) }),
    lockDecision: (id: string, decisionId: number) =>
        api(`/projects/${id}/decisions/${decisionId}/lock`, { method: "POST" }),
    listComponents: (id: string) => api(`/projects/${id}/components`),
};

export async function fetchHealth() {
    return api("/health");
}
```

**Step 2: Create Zustand store**

```typescript
// src/stores/projectStore.ts
import { create } from "zustand";
import { projectsApi } from "../api/client";

interface Decision {
    id: number;
    parameter: string;
    value: string;
    reason: string;
    status: string;
}

interface Component {
    id: string;
    display_name: string;
    type: string;
    parameters: Record<string, unknown>;
}

interface ProjectSummary {
    id: string;
    name: string;
    gate: string;
    created_at: string;
}

interface ProjectState {
    screen: "home" | "workspace";
    projects: ProjectSummary[];
    activeProject: {
        id: string;
        name: string;
        gate: string;
        decisions: Decision[];
        components: Component[];
    } | null;
    loadProjects: () => Promise<void>;
    createProject: (name: string) => Promise<void>;
    openProject: (id: string) => Promise<void>;
    goHome: () => void;
}

export const useProjectStore = create<ProjectState>((set) => ({
    screen: "home",
    projects: [],
    activeProject: null,

    loadProjects: async () => {
        const projects = await projectsApi.list();
        set({ projects });
    },

    createProject: async (name: string) => {
        const project = await projectsApi.create(name);
        const full = await projectsApi.get(project.id);
        set({ screen: "workspace", activeProject: full });
    },

    openProject: async (id: string) => {
        const full = await projectsApi.get(id);
        set({ screen: "workspace", activeProject: full });
    },

    goHome: () => set({ screen: "home", activeProject: null }),
}));
```

**Step 3: Create HomeScreen component**

```tsx
// src/components/HomeScreen.tsx
import { useState, useEffect } from "react";
import { useProjectStore } from "../stores/projectStore";

export default function HomeScreen() {
    const { projects, loadProjects, createProject, openProject } = useProjectStore();
    const [newName, setNewName] = useState("");

    useEffect(() => { loadProjects(); }, []);

    const handleCreate = () => {
        if (newName.trim()) {
            createProject(newName.trim());
            setNewName("");
        }
    };

    return (
        <div style={{ maxWidth: 600, margin: "80px auto", color: "#fff" }}>
            <h1>Kinetic Forge Studio</h1>
            <div style={{ display: "flex", gap: 8, marginBottom: 32 }}>
                <input
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleCreate()}
                    placeholder="New project name..."
                    style={{ flex: 1, padding: "8px 12px", borderRadius: 4, border: "1px solid #444", background: "#1a1a2e", color: "#fff" }}
                />
                <button onClick={handleCreate} style={{ padding: "8px 16px", borderRadius: 4, background: "#4a9eff", color: "#fff", border: "none", cursor: "pointer" }}>
                    + New Project
                </button>
            </div>
            {projects.length === 0 ? (
                <p style={{ opacity: 0.5 }}>No projects yet. Create one to get started.</p>
            ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {projects.map((p) => (
                        <div key={p.id} onClick={() => openProject(p.id)}
                            style={{ padding: "12px 16px", background: "#16213e", borderRadius: 8, cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                            <div>
                                <strong>{p.name}</strong>
                                <span style={{ opacity: 0.5, marginLeft: 12, fontSize: 12 }}>
                                    Gate: {p.gate}
                                </span>
                            </div>
                            <span style={{ fontSize: 12, opacity: 0.4 }}>
                                {new Date(p.created_at).toLocaleDateString()}
                            </span>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
```

**Step 4: Update App.tsx with screen routing**

```tsx
// src/App.tsx
import { useProjectStore } from "./stores/projectStore";
import HomeScreen from "./components/HomeScreen";
import Viewport3D from "./components/Viewport3D";

function Workspace() {
    const { activeProject, goHome } = useProjectStore();
    if (!activeProject) return null;

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100vh" }}>
            <header style={{ padding: "8px 16px", borderBottom: "1px solid #333", background: "#1a1a2e", color: "#fff", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <button onClick={goHome} style={{ background: "none", border: "none", color: "#4a9eff", cursor: "pointer" }}>← Home</button>
                    <span>{activeProject.name}</span>
                </div>
                <span style={{ fontSize: 12, opacity: 0.6 }}>Gate: {activeProject.gate}</span>
            </header>
            <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
                <div style={{ width: 280, borderRight: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", overflowY: "auto" }}>
                    <h3>Chat</h3>
                    <p style={{ opacity: 0.5, fontSize: 14 }}>Type your design intent...</p>
                </div>
                <div style={{ flex: 1, background: "#0a0a0a" }}>
                    <Viewport3D />
                </div>
                <div style={{ width: 280, borderLeft: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", overflowY: "auto" }}>
                    <h3>Spec Sheet</h3>
                    <h4 style={{ marginTop: 16, opacity: 0.7 }}>Decisions ({activeProject.decisions.length})</h4>
                    {activeProject.decisions.map((d) => (
                        <div key={d.id} style={{ padding: 8, marginBottom: 4, background: "#0d1b3e", borderRadius: 4, fontSize: 13 }}>
                            <div>{d.parameter}: <strong>{d.value}</strong></div>
                            <div style={{ opacity: 0.5 }}>{d.status} {d.reason && `— ${d.reason}`}</div>
                        </div>
                    ))}
                    <h4 style={{ marginTop: 16, opacity: 0.7 }}>Components ({activeProject.components.length})</h4>
                    {activeProject.components.map((c) => (
                        <div key={c.id} style={{ padding: 8, marginBottom: 4, background: "#0d1b3e", borderRadius: 4, fontSize: 13 }}>
                            <strong>{c.display_name}</strong> <span style={{ opacity: 0.5 }}>({c.id})</span>
                        </div>
                    ))}
                </div>
            </div>
            <div style={{ height: 48, borderTop: "1px solid #333", padding: "8px 16px", background: "#1a1a2e", color: "#fff", display: "flex", alignItems: "center" }}>
                <span style={{ opacity: 0.5 }}>Timeline: no checkpoints yet</span>
            </div>
        </div>
    );
}

export default function App() {
    const screen = useProjectStore((s) => s.screen);
    return (
        <div style={{ height: "100vh", background: "#0f0f23" }}>
            {screen === "home" ? <HomeScreen /> : <Workspace />}
        </div>
    );
}
```

**Step 5: Verify end-to-end**

Run both servers. Create a project from home screen. Should navigate to workspace with 3D viewport, empty chat panel, empty spec sheet. Click Home to go back. Project appears in list. Click to reopen.

**Step 6: Commit**

```bash
git add kinetic-forge-studio/frontend/
git commit -m "feat: home screen, project store, workspace with live backend data"
```

---

### Task 9: Chat Panel (Text Input)

**Files:**
- Create: `kinetic-forge-studio/frontend/src/components/ChatPanel.tsx`
- Create: `kinetic-forge-studio/backend/app/routes/chat.py`
- Modify: `kinetic-forge-studio/frontend/src/stores/projectStore.ts` (add messages)

**Step 1: Create chat route (backend)**

```python
# app/routes/chat.py
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/api/projects/{project_id}/chat", tags=["chat"])

class ChatMessage(BaseModel):
    content: str
    role: str = "user"

@router.post("")
async def send_message(project_id: str, msg: ChatMessage):
    # Phase 5 will wire this to the translator.
    # For now, echo back with a placeholder response.
    return {
        "user_message": msg.content,
        "response": f"Received: \"{msg.content}\". (Translator not yet connected — Phase 5)",
        "spec_updates": []
    }
```

Wire into main.py: `from app.routes.chat import router as chat_router; app.include_router(chat_router)`

**Step 2: Create ChatPanel component**

```tsx
// src/components/ChatPanel.tsx
import { useState, useRef, useEffect } from "react";

interface Message {
    role: "user" | "assistant";
    content: string;
}

interface Props {
    projectId: string;
}

export default function ChatPanel({ projectId }: Props) {
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState("");
    const [loading, setLoading] = useState(false);
    const bottomRef = useRef<HTMLDivElement>(null);

    useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages]);

    const send = async () => {
        if (!input.trim() || loading) return;
        const text = input.trim();
        setInput("");
        setMessages((m) => [...m, { role: "user", content: text }]);
        setLoading(true);
        try {
            const res = await fetch(`http://localhost:8000/api/projects/${projectId}/chat`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ content: text }),
            });
            const data = await res.json();
            setMessages((m) => [...m, { role: "assistant", content: data.response }]);
        } catch {
            setMessages((m) => [...m, { role: "assistant", content: "Error connecting to backend." }]);
        }
        setLoading(false);
    };

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
            <h3 style={{ margin: "0 0 12px" }}>Chat</h3>
            <div style={{ flex: 1, overflowY: "auto", display: "flex", flexDirection: "column", gap: 8 }}>
                {messages.length === 0 && (
                    <p style={{ opacity: 0.4, fontSize: 13 }}>Describe what you want to design...</p>
                )}
                {messages.map((m, i) => (
                    <div key={i} style={{
                        padding: "8px 12px", borderRadius: 8, fontSize: 13,
                        background: m.role === "user" ? "#1a3a6e" : "#0d1b3e",
                        alignSelf: m.role === "user" ? "flex-end" : "flex-start",
                        maxWidth: "90%",
                    }}>
                        {m.content}
                    </div>
                ))}
                <div ref={bottomRef} />
            </div>
            <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
                <input
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && send()}
                    placeholder="Type here..."
                    disabled={loading}
                    style={{ flex: 1, padding: "8px 12px", borderRadius: 4, border: "1px solid #333", background: "#0d1b3e", color: "#fff" }}
                />
                <button onClick={send} disabled={loading}
                    style={{ padding: "8px 12px", borderRadius: 4, background: "#4a9eff", color: "#fff", border: "none", cursor: "pointer" }}>
                    Send
                </button>
            </div>
        </div>
    );
}
```

**Step 3: Wire ChatPanel into Workspace**

Replace the chat placeholder div in App.tsx Workspace:
```tsx
import ChatPanel from "./components/ChatPanel";
// ...
<div style={{ width: 280, borderRight: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", display: "flex", flexDirection: "column" }}>
    <ChatPanel projectId={activeProject.id} />
</div>
```

**Step 4: Verify**

Type a message in chat. Should appear as user bubble. Backend echoes back as assistant bubble.

**Step 5: Commit**

```bash
git add kinetic-forge-studio/
git commit -m "feat: chat panel with message display and backend echo route"
```

---

### Task 10: File Upload UI (Photo, Video, 3D)

**Files:**
- Create: `kinetic-forge-studio/frontend/src/components/FileUpload.tsx`
- Create: `kinetic-forge-studio/backend/app/routes/upload.py`

**Step 1: Create upload route**

```python
# app/routes/upload.py
from fastapi import APIRouter, UploadFile, File
from pathlib import Path
from app.config import settings

router = APIRouter(prefix="/api/projects/{project_id}/upload", tags=["upload"])

@router.post("")
async def upload_file(project_id: str, file: UploadFile = File(...)):
    project_dir = settings.data_dir / "projects" / project_id / "references"
    project_dir.mkdir(parents=True, exist_ok=True)
    file_path = project_dir / file.filename
    content = await file.read()
    file_path.write_bytes(content)

    ext = file_path.suffix.lower()
    file_type = "unknown"
    if ext in (".jpg", ".jpeg", ".png", ".webp"):
        file_type = "photo"
    elif ext in (".mp4", ".mov", ".avi", ".webm"):
        file_type = "video"
    elif ext in (".step", ".stp"):
        file_type = "step"
    elif ext in (".stl"):
        file_type = "stl"
    elif ext in (".iges", ".igs"):
        file_type = "iges"
    elif ext in (".3mf"):
        file_type = "3mf"

    return {
        "filename": file.filename,
        "file_type": file_type,
        "size_bytes": len(content),
        "path": str(file_path),
        "analysis": f"{file_type} file received. (Analysis pipeline not yet connected — Phase 7)"
    }
```

Wire into main.py.

**Step 2: Create FileUpload component**

```tsx
// src/components/FileUpload.tsx
import { useRef } from "react";

interface Props {
    projectId: string;
    onUpload: (result: { filename: string; file_type: string; analysis: string }) => void;
}

export default function FileUpload({ projectId, onUpload }: Props) {
    const inputRef = useRef<HTMLInputElement>(null);

    const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        const form = new FormData();
        form.append("file", file);
        const res = await fetch(`http://localhost:8000/api/projects/${projectId}/upload`, {
            method: "POST",
            body: form,
        });
        const data = await res.json();
        onUpload(data);
        if (inputRef.current) inputRef.current.value = "";
    };

    return (
        <div>
            <input ref={inputRef} type="file" onChange={handleUpload}
                accept=".jpg,.jpeg,.png,.webp,.mp4,.mov,.step,.stp,.stl,.iges,.igs,.3mf"
                style={{ display: "none" }} />
            <button onClick={() => inputRef.current?.click()}
                style={{ width: "100%", padding: "6px", borderRadius: 4, background: "#333", color: "#aaa", border: "1px dashed #555", cursor: "pointer", fontSize: 12 }}>
                📎 Upload photo, video, or 3D file
            </button>
        </div>
    );
}
```

**Step 3: Wire into ChatPanel** (add upload button below chat input, display upload results as assistant messages)

**Step 4: Verify**

Upload a .jpg → shows "photo file received" message. Upload a .step → shows "step file received."

**Step 5: Commit**

```bash
git add kinetic-forge-studio/
git commit -m "feat: file upload for photos, videos, and 3D files"
```

---

## Phase 4: CadQuery Engine + Viewport Integration

**Deliverable:** Backend generates real geometry from parameters. Frontend displays actual 3D models (not test cube). Click components to inspect.

---

### Task 11: CadQuery Engine Wrapper

**Files:**
- Create: `kinetic-forge-studio/backend/app/engines/cadquery_engine.py`
- Test: `kinetic-forge-studio/backend/tests/test_cadquery_engine.py`

**Step 1: Write failing tests** — test that engine generates a simple spur gear, exports to STEP and glTF. Test bounding box dimensions match spec.

**Step 2: Implement engine** — wrap CadQuery with parameter-driven generation. Simple shapes first (box, cylinder, gear). Export to STEP via `cq.exporters.export` and to glTF via trimesh conversion.

**Step 3: Run tests, verify pass**

**Step 4: Commit**

---

### Task 12: Geometry Serving API

**Files:**
- Create: `kinetic-forge-studio/backend/app/routes/viewport.py`

Endpoint: `GET /api/projects/{id}/geometry` returns glTF binary. Frontend fetches and loads into R3F viewport via `useGLTF` or `useLoader(GLTFLoader, url)`.

---

### Task 13: Dynamic Viewport (Load Real Geometry)

**Files:**
- Modify: `kinetic-forge-studio/frontend/src/components/Viewport3D.tsx`

Replace test cube with dynamic glTF loading. Add click-to-select with raycasting. Highlight selected component. Show params in sidebar.

---

### Task 14: Preset View Buttons + View Modes

**Files:**
- Create: `kinetic-forge-studio/frontend/src/components/ViewportToolbar.tsx`

Add: Front, Top, Right, Iso buttons. Wireframe toggle. X-ray toggle. These control Three.js camera position and material mode.

---

## Phase 5: Translator + Orchestrator

**Deliverable:** User types natural language in chat → app parses intent → asks clarifying questions → builds spec sheet → triggers generation.

---

### Task 15: Keyword Classifier

**Files:**
- Create: `kinetic-forge-studio/backend/app/translator/classifier.py`
- Create: `kinetic-forge-studio/backend/data/taxonomy.yaml`
- Test: `kinetic-forge-studio/backend/tests/test_classifier.py`

**Step 1: Write taxonomy.yaml** with mechanism types, motion types, materials, size indicators mapped to keywords.

**Step 2: Write failing tests** — input "compact planetary gear 3 planets 70mm" → extracts mechanism_type=planetary, planet_count=3, envelope=70mm. Input "breathing wave sculpture wood" → mechanism_type=wave, material=wood, feeling=breathing.

**Step 3: Implement classifier** — keyword matching against taxonomy with confidence scores. Returns structured dict of extracted fields + list of unknowns.

---

### Task 16: YAML Question Tree

**Files:**
- Create: `kinetic-forge-studio/backend/app/translator/question_tree.py`
- Create: `kinetic-forge-studio/backend/data/questions/`
- Test: `kinetic-forge-studio/backend/tests/test_question_tree.py`

YAML files define questions per unknown field. Each question has options with impact explanations. Engine selects the right question for each gap in the spec.

---

### Task 17: Claude API Client + Prompt Builder

**Files:**
- Create: `kinetic-forge-studio/backend/app/ai/claude_client.py`
- Create: `kinetic-forge-studio/backend/app/ai/prompt_builder.py`
- Test: `kinetic-forge-studio/backend/tests/test_prompt_builder.py`

Prompt builder auto-assembles context: spec sheet + locked decisions + component registry + user profile + focused question. Claude client sends and receives text. Tests verify prompt structure without making real API calls (mock).

---

### Task 18: Orchestrator Pipeline

**Files:**
- Create: `kinetic-forge-studio/backend/app/orchestrator/pipeline.py`
- Modify: `kinetic-forge-studio/backend/app/routes/chat.py`
- Test: `kinetic-forge-studio/backend/tests/test_pipeline.py`

The pipeline function from design doc Section 9: parse → check unknowns → YAML questions or Claude → confirm → generate → validate → render. Wire into chat route so text input flows through the full pipeline.

---

## Phase 6: Validation + Gates

**Deliverable:** All geometry is validated automatically. Gate status shown in UI. Buttons disabled until checks pass.

---

### Task 19: Collision Detection Validator

**Files:**
- Create: `kinetic-forge-studio/backend/app/validators/collision.py`
- Test: `kinetic-forge-studio/backend/tests/test_collision.py`

trimesh + python-fcl. Test with two overlapping boxes (FAIL) and two separated boxes (PASS).

---

### Task 20: Manufacturability Validator

**Files:**
- Create: `kinetic-forge-studio/backend/app/validators/manufacturability.py`
- Test: `kinetic-forge-studio/backend/tests/test_manufacturability.py`

Wall thickness (check min face-to-face distance), overhang angle (check face normals), watertight (trimesh.is_watertight).

---

### Task 21: Gate Enforcer + Status API

**Files:**
- Create: `kinetic-forge-studio/backend/app/orchestrator/gate.py`
- Create: `kinetic-forge-studio/backend/app/routes/validation.py`
- Test: `kinetic-forge-studio/backend/tests/test_gate.py`

Gate enforcer runs all validators, returns pass/fail per check. API endpoint: `GET /api/projects/{id}/gate-status`. Frontend gate status bar reads from this.

---

### Task 22: Frontend Gate Status + Disabled Buttons

**Files:**
- Create: `kinetic-forge-studio/frontend/src/components/GateStatus.tsx`
- Modify: `kinetic-forge-studio/frontend/src/components/Viewport3D.tsx` (add export button, disabled when gate fails)

Show pipeline progress: ✅ Compiled ✅ Validated ✅ Rendered. Export button grayed out until all pass.

---

## Phase 7: Import, Library, Export

**Deliverable:** STEP/STL import with analysis. Reference library with search. Export packages (STEP + STL + report).

---

### Task 23: STEP Analyzer

**Files:**
- Create: `kinetic-forge-studio/backend/app/importers/step_analyzer.py`
- Test: `kinetic-forge-studio/backend/tests/test_step_analyzer.py`

CadQuery `importStep` → extract bodies, face types, dimensions, hole positions. Return structured analysis dict. Test with a simple STEP file (generate one in test fixture via CadQuery).

---

### Task 24: STL Analyzer

**Files:**
- Create: `kinetic-forge-studio/backend/app/importers/stl_analyzer.py`
- Test: `kinetic-forge-studio/backend/tests/test_stl_analyzer.py`

trimesh load → bounding box, volume, surface area, watertight check, face count. Return structured dict with honest limitations message.

---

### Task 25: Photo Analyzer (Claude Vision)

**Files:**
- Create: `kinetic-forge-studio/backend/app/importers/photo_analyzer.py`
- Test: `kinetic-forge-studio/backend/tests/test_photo_analyzer.py`

Send image(s) to Claude Vision API with structured prompt. Parse response into mechanism identification dict. Test with mock API responses.

---

### Task 26: Reference Library

**Files:**
- Create: `kinetic-forge-studio/backend/app/db/library.py`
- Create: `kinetic-forge-studio/backend/app/routes/library.py`
- Test: `kinetic-forge-studio/backend/tests/test_library.py`

SQLite full-text search across mechanism_types, keywords, dimensions. API endpoints: search, add, get thumbnail. Auto-index on project completion.

---

### Task 27: Export Package

**Files:**
- Create: `kinetic-forge-studio/backend/app/routes/export.py`
- Test: `kinetic-forge-studio/backend/tests/test_export.py`

Bundle: STEP (assembly + individual parts) + STL + validation report HTML + renders + spec YAML + decision journal JSON + source code. Return as zip download.

---

### Task 28: Video Analyzer

**Files:**
- Create: `kinetic-forge-studio/backend/app/importers/video_analyzer.py`
- Test: `kinetic-forge-studio/backend/tests/test_video_analyzer.py`

ffmpeg frame extraction → Claude Vision on key frames → motion profile dict with cycle detection, component motion types, tempo estimate. Test with mock ffmpeg output + mock API.

---

## Phase Summary

| Phase | Tasks | Deliverable |
|-------|-------|------------|
| 1: Scaffold | 1-3 | Backend + frontend + 3D viewport with test cube |
| 2: Data Layer | 4-7 | Projects, decisions, components, profile — all persisted |
| 3: Frontend UI | 8-10 | Home screen, workspace, chat panel, file upload |
| 4: CadQuery + Viewport | 11-14 | Real geometry generation + interactive 3D display |
| 5: Translator + Orchestrator | 15-18 | Natural language → spec → generation pipeline |
| 6: Validation + Gates | 19-22 | Collision/manufacturability checks, gate enforcement |
| 7: Import + Library + Export | 23-28 | STEP/STL/photo/video import, library search, export packages |

**Total: 28 tasks across 7 phases.**

Each phase is independently testable and delivers visible value. Phase 1-3 gives you a working app shell. Phase 4 makes it generate real geometry. Phase 5 makes the chat intelligent. Phase 6 makes it safe. Phase 7 completes the feature set.
