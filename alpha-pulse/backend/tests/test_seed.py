# tests/test_seed.py
import pytest
from sqlalchemy import select
from app.db.models import Asset
from app.ingestion.seed import DEFAULT_ASSETS, seed_default_assets


async def test_seed_creates_all_assets(db_session):
    count = await seed_default_assets(db_session)
    assert count == len(DEFAULT_ASSETS)
    result = await db_session.execute(select(Asset).where(Asset.id != "_MACRO"))
    assets = result.scalars().all()
    assert len(assets) == len(DEFAULT_ASSETS)


async def test_seed_is_idempotent(db_session):
    first = await seed_default_assets(db_session)
    second = await seed_default_assets(db_session)
    assert first == len(DEFAULT_ASSETS)
    assert second == 0  # All skipped


async def test_seed_asset_classes_correct(db_session):
    await seed_default_assets(db_session)
    result = await db_session.execute(select(Asset).where(Asset.asset_class == "equity"))
    equities = result.scalars().all()
    result2 = await db_session.execute(select(Asset).where(Asset.asset_class == "crypto"))
    cryptos = result2.scalars().all()
    assert len(equities) == 20
    assert len(cryptos) == 10
