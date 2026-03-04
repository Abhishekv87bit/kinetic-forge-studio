import json

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


class SetScadDirRequest(BaseModel):
    scad_dir: str


@router.post("/{project_id}/scad-dir")
async def set_scad_dir(project_id: str, req: SetScadDirRequest):
    """Link an OpenSCAD source directory to a project."""
    pm = await get_pm()
    project = await pm.set_scad_dir(project_id, req.scad_dir)
    return {"id": project.id, "name": project.name, "scad_dir": project.scad_dir}


# ------------------------------------------------------------------
# Timeline / Snapshot endpoints
# ------------------------------------------------------------------

class CreateSnapshotRequest(BaseModel):
    label: str


@router.get("/{project_id}/snapshots")
async def list_snapshots(project_id: str):
    """List all snapshots for a project (most recent first)."""
    pm = await get_pm()
    await _ensure_snapshots_table(pm)
    cursor = await pm.db.conn.execute(
        "SELECT id, label, gate, trigger, created_at FROM snapshots "
        "WHERE project_id = ? ORDER BY created_at DESC",
        (project_id,),
    )
    rows = await cursor.fetchall()
    return [
        {"id": r["id"], "label": r["label"], "gate": r["gate"],
         "trigger": r["trigger"], "created_at": r["created_at"]}
        for r in rows
    ]


@router.post("/{project_id}/snapshots")
async def create_snapshot_endpoint(project_id: str, req: CreateSnapshotRequest):
    """Create a manual snapshot of the current project state."""
    pm = await get_pm()
    project = await pm.open(project_id)
    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)

    cursor = await pm.db.conn.execute(
        "SELECT parameter, value, reason, status FROM decisions "
        "WHERE project_id = ?",
        (project_id,),
    )
    decisions = [dict(r) for r in await cursor.fetchall()]

    await _ensure_snapshots_table(pm)
    cursor = await pm.db.conn.execute(
        "INSERT INTO snapshots "
        "(project_id, label, gate, spec_json, components_json, "
        "decisions_json, trigger) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            project_id, req.label, project.gate,
            "{}", json.dumps(components, default=str),
            json.dumps(decisions, default=str), "manual",
        ),
    )
    await pm.db.conn.commit()
    return {"id": cursor.lastrowid, "label": req.label}


@router.post("/{project_id}/snapshots/{snapshot_id}/rollback")
async def rollback_to_snapshot(project_id: str, snapshot_id: int):
    """
    Rollback a project to a previous snapshot.

    Restores components, decisions, and gate level from the snapshot.
    """
    pm = await get_pm()
    await _ensure_snapshots_table(pm)

    cursor = await pm.db.conn.execute(
        "SELECT * FROM snapshots WHERE id = ? AND project_id = ?",
        (snapshot_id, project_id),
    )
    snap = await cursor.fetchone()
    if not snap:
        raise HTTPException(status_code=404, detail="Snapshot not found")

    components = json.loads(snap["components_json"] or "[]")
    decisions = json.loads(snap["decisions_json"] or "[]")

    # Atomic rollback — all-or-nothing via explicit transaction
    try:
        await pm.db.conn.execute("BEGIN IMMEDIATE")

        # Restore gate level
        await pm.db.conn.execute(
            "UPDATE projects SET gate = ?, updated_at = datetime('now') "
            "WHERE id = ?",
            (snap["gate"], project_id),
        )

        # Restore components: clear existing, re-insert from snapshot
        await pm.db.conn.execute(
            "DELETE FROM components WHERE project_id = ?", (project_id,)
        )
        for comp in components:
            comp_id = comp.get("id", "")
            if not comp_id:
                continue  # Skip components with empty IDs
            params = comp.get("parameters", {})
            if isinstance(params, str):
                params = json.loads(params)
            pos = comp.get("position", {})
            if isinstance(pos, str):
                pos = json.loads(pos)
            await pm.db.conn.execute(
                "INSERT INTO components "
                "(id, project_id, display_name, component_type, "
                "parameters, position) VALUES (?, ?, ?, ?, ?, ?)",
                (
                    comp_id, project_id,
                    comp.get("display_name", comp_id),
                    comp.get("type", comp.get("component_type", "box")),
                    json.dumps(params, default=str),
                    json.dumps(pos, default=str),
                ),
            )

        # Restore decisions: clear and re-insert
        await pm.db.conn.execute(
            "DELETE FROM decisions WHERE project_id = ?", (project_id,)
        )
        for d in decisions:
            if not d.get("parameter"):
                continue
            await pm.db.conn.execute(
                "INSERT INTO decisions "
                "(project_id, parameter, value, reason, status) "
                "VALUES (?, ?, ?, ?, ?)",
                (
                    project_id, d["parameter"], d["value"],
                    d.get("reason", ""), d.get("status", "proposed"),
                ),
            )

        await pm.db.conn.execute("COMMIT")
    except Exception as e:
        await pm.db.conn.execute("ROLLBACK")
        raise HTTPException(
            status_code=500,
            detail=f"Rollback failed, no changes applied: {e}",
        )

    # Reset in-memory chat state so it doesn't show stale data
    from app.routes.chat import _chat_states
    if project_id in _chat_states:
        _chat_states[project_id].conversation_history.clear()
        _chat_states[project_id].pipeline.reset()
        _chat_states[project_id].history_loaded = False

    return {
        "status": "rolled_back",
        "snapshot_id": snapshot_id,
        "label": snap["label"],
        "gate": snap["gate"],
        "components_restored": len(components),
        "decisions_restored": len(decisions),
    }


async def _ensure_snapshots_table(pm) -> None:
    """Ensure snapshots table exists (backwards-compatible migration)."""
    try:
        await pm.db.conn.execute("SELECT 1 FROM snapshots LIMIT 1")
    except Exception:
        await pm.db.conn.executescript("""
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
        """)
        await pm.db.conn.commit()
