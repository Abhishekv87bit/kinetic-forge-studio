"""Bulk ingestion endpoint -- trigger data pull for all tracked assets."""

import logging

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.ingestion.bulk_ingest import bulk_ingest_all

router = APIRouter(prefix="/api/ingest", tags=["ingestion"])

logger = logging.getLogger(__name__)


@router.post("/bulk")
async def trigger_bulk_ingest(db: AsyncSession = Depends(get_db)):
    """Trigger a one-time bulk ingestion for all tracked assets."""
    logger.info("Bulk ingestion triggered via API")
    result = await bulk_ingest_all(db)
    return result
