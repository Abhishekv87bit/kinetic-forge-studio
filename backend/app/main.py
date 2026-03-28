"""KFS Backend — FastAPI application entry point.

Routers registered:
    /modules   — Module CRUD, execution, validation, geometry, manifest (SC-01…SC-08)

Run with:
    uvicorn backend.app.main:app --reload
"""
from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.app.routes.modules import router as modules_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
)

app = FastAPI(
    title="Kinetic Forge Studio API",
    description="Backend API for the KFS kinetic sculpture design application.",
    version="2.0.0",
)

# Allow the Three.js frontend (dev server typically on :5173) to call the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------

app.include_router(modules_router)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------


@app.get("/health", tags=["meta"])
async def health() -> dict:
    """Liveness probe — returns 200 when the service is up."""
    return {"status": "ok"}
