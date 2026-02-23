from fastapi import APIRouter, UploadFile, File
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
    elif ext in (".stl",):
        file_type = "stl"
    elif ext in (".iges", ".igs"):
        file_type = "iges"
    elif ext in (".3mf",):
        file_type = "3mf"

    return {
        "filename": file.filename,
        "file_type": file_type,
        "size_bytes": len(content),
        "path": str(file_path),
        "analysis": f"{file_type} file received. (Analysis pipeline not yet connected — Phase 7)"
    }
