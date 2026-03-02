from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routes.projects import router as projects_router
from app.routes.chat import router as chat_router
from app.routes.upload import router as upload_router
from app.routes.viewport import router as viewport_router
from app.routes.validation import router as validation_router
from app.routes.library import router as library_router
from app.routes.export import router as export_router
from app.routes.profile import router as profile_router
from app.routes.viewer import router as viewer_router

app = FastAPI(title=settings.app_name, version=settings.version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(projects_router)
app.include_router(chat_router)
app.include_router(upload_router)
app.include_router(viewport_router)
app.include_router(validation_router)
app.include_router(library_router)
app.include_router(export_router)
app.include_router(profile_router)
app.include_router(viewer_router)

@app.on_event("shutdown")
async def shutdown():
    from app.routes.projects import _pm
    if _pm is not None:
        await _pm.db.close()


@app.get("/api/health")
async def health():
    return {"status": "ok", "version": settings.version}
