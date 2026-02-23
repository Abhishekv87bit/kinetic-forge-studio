"""
Reference library API routes.

Provides endpoints for searching, adding, and retrieving
entries from the reference mechanism library.
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from app.db.library import LibraryManager
from app.routes.projects import get_pm

router = APIRouter(prefix="/api/library", tags=["library"])


class AddLibraryEntryRequest(BaseModel):
    name: str
    mechanism_types: str = ""
    keywords: str = ""
    source: str = ""
    envelope_x: float | None = None
    envelope_y: float | None = None
    envelope_z: float | None = None
    file_path: str = ""
    thumbnail_path: str = ""
    project_id: str | None = None


async def _get_lm() -> LibraryManager:
    """Get a LibraryManager with an initialized database connection."""
    pm = await get_pm()
    await pm._ensure_db()
    return LibraryManager(pm.db)


@router.get("/search")
async def search_library(q: str = Query(default="", description="Search query")):
    """
    Search the reference library using full-text search.

    Searches across names, mechanism types, and keywords.
    Returns matching entries ranked by relevance.
    """
    lm = await _get_lm()
    results = await lm.search(q)
    return results


@router.post("")
async def add_library_entry(req: AddLibraryEntryRequest):
    """Add a new entry to the reference library."""
    lm = await _get_lm()
    entry = await lm.add(
        name=req.name,
        mechanism_types=req.mechanism_types,
        keywords=req.keywords,
        source=req.source,
        envelope_x=req.envelope_x,
        envelope_y=req.envelope_y,
        envelope_z=req.envelope_z,
        file_path=req.file_path,
        thumbnail_path=req.thumbnail_path,
        project_id=req.project_id,
    )
    return entry


@router.get("/{entry_id}")
async def get_library_entry(entry_id: str):
    """Get a specific library entry by ID."""
    lm = await _get_lm()
    try:
        return await lm.get(entry_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Library entry not found")
