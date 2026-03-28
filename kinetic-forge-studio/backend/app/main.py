import logging
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
from app.routes.modules import router as modules_router

# Production pipeline middleware (GAP-PPL-003, 005, 008, 013)
from app.middleware.input_guardrails import InputGuardrailsMiddleware
from app.middleware.observability import setup_observability, get_cost_summary
from app.middleware.rate_limiter import setup_rate_limiting
from app.middleware.resilience import get_all_circuit_states
from app.middleware.cache import get_cache_stats

logger = logging.getLogger("kfs")

app = FastAPI(title=settings.app_name, version=settings.version)

# ── Middleware stack (order matters: outermost first) ──

# 1. CORS (must be outermost)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. Input guardrails — block injection before reaching routes (GAP-PPL-005)
app.add_middleware(InputGuardrailsMiddleware)

# 3. Rate limiting (GAP-PPL-013)
limiter = setup_rate_limiting(app, default_limit="60/minute")

# 4. Observability — trace LLM calls, track costs (GAP-PPL-003 + GAP-PPL-007)
setup_observability()

# ── Routes ──
app.include_router(projects_router)
app.include_router(chat_router)
app.include_router(upload_router)
app.include_router(viewport_router)
app.include_router(validation_router)
app.include_router(library_router)
app.include_router(export_router)
app.include_router(profile_router)
app.include_router(viewer_router)
app.include_router(modules_router)

@app.on_event("shutdown")
async def shutdown():
    from app.routes.projects import _pm
    if _pm is not None:
        await _pm.db.close()
    from app.routes.modules import _mm, _sl
    if _mm and hasattr(_mm, 'db'):
        await _mm.db.close()
    if _sl and hasattr(_sl, 'db'):
        await _sl.db.close()


@app.get("/api/health")
async def health():
    """Health endpoint with pipeline status (GAP-PPL-008)."""
    return {
        "status": "ok",
        "version": settings.version,
        "circuits": get_all_circuit_states(),
        "costs": get_cost_summary(),
        "cache": get_cache_stats(),
    }
