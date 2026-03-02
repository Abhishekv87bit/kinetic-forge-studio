import asyncio

import yfinance as yf
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.db.models import Asset
from app.validation.schema import AssetCreate, AssetRead, AssetUpdate

router = APIRouter(prefix="/api/assets", tags=["assets"])


@router.get("/validate/{ticker}")
async def validate_ticker(ticker: str):
    """Check if a ticker exists on yfinance before adding."""

    def _check():
        t = yf.Ticker(ticker.upper())
        info = t.info or {}
        name = info.get("shortName") or info.get("longName")
        if not name:
            return {"valid": False}
        # Detect asset class from yfinance quoteType
        qt = info.get("quoteType", "").lower()
        if qt in ("cryptocurrency",):
            asset_class = "crypto"
        elif qt in ("equity", "etf", "mutualfund"):
            asset_class = "equity"
        elif qt in ("currency",):
            asset_class = "forex"
        elif qt in ("future", "commodity"):
            asset_class = "commodity"
        else:
            asset_class = "equity"
        return {"valid": True, "name": name, "asset_class": asset_class}

    result = await asyncio.to_thread(_check)
    return result


@router.post("", status_code=201, response_model=AssetRead)
async def create_asset(body: AssetCreate, db: AsyncSession = Depends(get_db)):
    existing = await db.get(Asset, body.id)
    if existing:
        raise HTTPException(409, f"Asset {body.id} already exists")
    asset = Asset(
        id=body.id,
        asset_class=body.asset_class.value,
        name=body.name,
        tracked=body.tracked,
        metadata_=body.metadata,
    )
    db.add(asset)
    await db.commit()
    await db.refresh(asset)
    return _to_read(asset)


@router.get("", response_model=list[AssetRead])
async def list_assets(db: AsyncSession = Depends(get_db)):
    # Fetch all, then exclude system assets (IDs starting with _) in Python
    # System assets like _MACRO have non-standard asset_class that fails Pydantic validation
    result = await db.execute(select(Asset))
    return [_to_read(a) for a in result.scalars().all() if not a.id.startswith("_")]


@router.get("/{asset_id}", response_model=AssetRead)
async def get_asset(asset_id: str, db: AsyncSession = Depends(get_db)):
    asset = await db.get(Asset, asset_id)
    if not asset:
        raise HTTPException(404, f"Asset {asset_id} not found")
    return _to_read(asset)


@router.delete("/{asset_id}")
async def delete_asset(asset_id: str, db: AsyncSession = Depends(get_db)):
    asset = await db.get(Asset, asset_id)
    if not asset:
        raise HTTPException(404, f"Asset {asset_id} not found")
    await db.delete(asset)
    await db.commit()
    return {"deleted": asset_id}


@router.patch("/{asset_id}", response_model=AssetRead)
async def update_asset(asset_id: str, body: AssetUpdate, db: AsyncSession = Depends(get_db)):
    asset = await db.get(Asset, asset_id)
    if not asset:
        raise HTTPException(404, f"Asset {asset_id} not found")
    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(asset, field, value)
    await db.commit()
    await db.refresh(asset)
    return _to_read(asset)


def _to_read(asset: Asset) -> AssetRead:
    return AssetRead(
        id=asset.id,
        asset_class=asset.asset_class,
        name=asset.name,
        tracked=asset.tracked,
        metadata=asset.metadata_ or {},
        created_at=asset.created_at,
    )
