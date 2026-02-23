from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routes.projects import router as projects_router
from app.routes.chat import router as chat_router
from app.routes.upload import router as upload_router
from app.routes.viewport import router as viewport_router
from app.routes.validation import router as validation_router

app = FastAPI(title=settings.app_name, version=settings.version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(projects_router)
app.include_router(chat_router)
app.include_router(upload_router)
app.include_router(viewport_router)
app.include_router(validation_router)

@app.get("/api/health")
async def health():
    return {"status": "ok", "version": settings.version}
