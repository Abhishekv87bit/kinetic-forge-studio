from fastapi import FastAPI
from .routes import router

app = FastAPI(
    title="KFS Manifest API",
    description="API for parsing and validating KFS manifest files.",
    version="0.1.0",
)

# Include the API routes with a version prefix
app.include_router(router, prefix="/api/v1")
