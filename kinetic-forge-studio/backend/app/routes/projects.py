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
