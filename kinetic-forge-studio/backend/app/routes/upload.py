"""
Upload route with Phase 7 analyzer integration.

When a file is uploaded, it is saved to the project's references directory,
then routed to the appropriate analyzer based on file type:
- STEP -> STEPAnalyzer (CadQuery B-rep analysis)
- STL  -> STLAnalyzer (trimesh mesh analysis)
- Photo -> PhotoAnalyzer (Claude Vision or placeholder)
- Video -> VideoAnalyzer (ffmpeg + Claude Vision or placeholder)
- Other formats -> basic file info only
"""

import logging
from fastapi import APIRouter, UploadFile, File
from app.config import settings

router = APIRouter(prefix="/api/projects/{project_id}/upload", tags=["upload"])

logger = logging.getLogger(__name__)


def _analyze_step(file_path) -> dict:
    """Run STEP analyzer on the uploaded file."""
    from app.importers.step_analyzer import STEPAnalyzer
    analyzer = STEPAnalyzer()
    return analyzer.analyze(file_path)


def _analyze_stl(file_path) -> dict:
    """Run STL analyzer on the uploaded file."""
    from app.importers.stl_analyzer import STLAnalyzer
    analyzer = STLAnalyzer()
    return analyzer.analyze(file_path)


def _analyze_photo(file_path) -> dict:
    """Run photo analyzer on the uploaded file."""
    from app.importers.photo_analyzer import PhotoAnalyzer
    analyzer = PhotoAnalyzer(claude_api_key=settings.claude_api_key)
    return analyzer.analyze(file_path)


def _analyze_video(file_path) -> dict:
    """Run video analyzer on the uploaded file."""
    from app.importers.video_analyzer import VideoAnalyzer
    analyzer = VideoAnalyzer(claude_api_key=settings.claude_api_key)
    return analyzer.analyze(file_path)


@router.post("")
async def upload_file(project_id: str, file: UploadFile = File(...)):
    """
    Upload a file and run the appropriate analyzer.

    Supported file types:
    - STEP/STP: B-rep geometry analysis (faces, volume, bounding box)
    - STL: Mesh analysis (vertices, faces, watertight check)
    - JPG/PNG/WEBP: Photo analysis (mechanism identification via Claude Vision)
    - MP4/MOV/AVI/WEBM: Video analysis (motion profiling via frame extraction)
    - IGES/3MF: Saved but no analyzer yet (returns basic file info)
    """
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

    # Route to the appropriate analyzer
    analysis = None
    analysis_error = None

    try:
        if file_type == "step":
            analysis = _analyze_step(file_path)
        elif file_type == "stl":
            analysis = _analyze_stl(file_path)
        elif file_type == "photo":
            analysis = _analyze_photo(file_path)
        elif file_type == "video":
            analysis = _analyze_video(file_path)
    except Exception as e:
        logger.warning("Analyzer failed for %s: %s", file.filename, e)
        analysis_error = str(e)

    # Build response
    result = {
        "filename": file.filename,
        "file_type": file_type,
        "size_bytes": len(content),
        "path": str(file_path),
    }

    if analysis is not None:
        result["analysis"] = analysis
    elif analysis_error:
        result["analysis"] = {
            "error": analysis_error,
            "message": f"Analysis failed for {file_type} file: {analysis_error}",
        }
    else:
        result["analysis"] = {
            "message": f"{file_type} file saved. No analyzer available for this format yet.",
        }

    return result
