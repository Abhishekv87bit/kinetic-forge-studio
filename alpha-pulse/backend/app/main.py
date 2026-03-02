import logging
import sys
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.database import init_db, dispose_engine, check_db, get_db
from app.middleware.auth import ApiKeyMiddleware
from app.ingestion.scheduler import create_scheduler, get_scheduled_jobs
from app.routes.alerts import router as alerts_router
from app.routes.analysis import router as analysis_router
from app.routes.assets import router as assets_router
from app.routes.portfolio import router as portfolio_router
from app.routes.rules import router as rules_router
from app.routes.backtest import router as backtest_router
from app.routes.ingest import router as ingest_router
from app.routes.signals import router as signals_router

# ── Structured logging ────────────────────────────────────────────
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)


# ── Lifespan (startup + graceful shutdown) ────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s v%s", settings.app_name, settings.version)
    await init_db()

    # Start ingestion scheduler
    scheduler = create_scheduler()
    if settings.scheduler_enabled:
        scheduler.start()
        logger.info("Scheduler started with %d jobs", len(scheduler.get_jobs()))
    app.state.scheduler = scheduler

    yield

    # Graceful shutdown
    logger.info("Shutting down...")
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Scheduler stopped")
    await dispose_engine()


app = FastAPI(title=settings.app_name, version=settings.version, lifespan=lifespan)


# ── Global exception handler ─────────────────────────────────────
@app.exception_handler(Exception)
async def _unhandled_exception(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


app.add_middleware(ApiKeyMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(alerts_router)
app.include_router(analysis_router)
app.include_router(assets_router)
app.include_router(backtest_router)
app.include_router(ingest_router)
app.include_router(portfolio_router)
app.include_router(rules_router)
app.include_router(signals_router)


# ── Health check (includes DB connectivity) ───────────────────────
@app.get("/api/health")
async def health(db: AsyncSession = Depends(get_db)):
    db_ok = await check_db(db)
    status = "ok" if db_ok else "degraded"
    return {
        "status": status,
        "version": settings.version,
        "db": "connected" if db_ok else "unreachable",
    }


@app.get("/api/scheduler")
async def scheduler_status(request: Request):
    scheduler = getattr(request.app.state, "scheduler", None)
    if scheduler is None:
        return {"enabled": False, "running": False, "jobs": []}
    return {
        "enabled": settings.scheduler_enabled,
        "running": scheduler.running,
        "jobs": get_scheduled_jobs(scheduler),
    }
