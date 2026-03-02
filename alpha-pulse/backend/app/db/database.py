import logging

from sqlalchemy import event, text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.config import settings

logger = logging.getLogger(__name__)

engine = create_async_engine(settings.db_url, echo=settings.debug)


@event.listens_for(engine.sync_engine, "connect")
def _set_sqlite_pragma(dbapi_conn, connection_record):
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


async_session_factory = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


# System assets that must exist for FK integrity (e.g. _MACRO snapshots).
SYSTEM_ASSETS = [
    {"id": "_MACRO", "asset_class": "macro", "name": "Macro Indicators"},
]


async def get_db():
    async with async_session_factory() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def check_db(db: AsyncSession) -> bool:
    """Lightweight DB connectivity check (SELECT 1).

    Accepts an AsyncSession so it works through FastAPI DI
    (overridable in tests).
    """
    try:
        await db.execute(text("SELECT 1"))
        return True
    except Exception:
        logger.exception("DB health check failed")
        return False


async def init_db():
    from app.db.models import Base, Asset
    from app.ingestion.seed import seed_default_assets

    settings.data_dir.mkdir(parents=True, exist_ok=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed system assets (idempotent)
    async with async_session_factory() as session:
        for asset_data in SYSTEM_ASSETS:
            existing = await session.get(Asset, asset_data["id"])
            if not existing:
                session.add(Asset(**asset_data))
                logger.info("Seeded system asset: %s", asset_data["id"])
        await session.commit()

    # Seed default market assets (idempotent)
    async with async_session_factory() as session:
        count = await seed_default_assets(session)
        if count:
            logger.info("Seeded %d default assets", count)


async def dispose_engine():
    """Graceful shutdown — close all DB connections."""
    await engine.dispose()
    logger.info("Database engine disposed")
