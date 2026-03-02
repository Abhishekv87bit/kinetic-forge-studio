"""Paper trading routes — virtual portfolio management."""

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.db.models import PaperTrade
from app.paper_trading.engine import (
    execute_trade,
    execute_manual_trade,
    close_trade,
    get_portfolio_summary,
    update_open_positions,
    TradeNotFoundError,
    TradeAlreadyClosedError,
    SignalNotFoundError,
)
from app.validation.schema import (
    PaperTradeCreate,
    PaperTradeClose,
    PaperTradeRead,
    PortfolioSummary,
)


class ManualTradeCreate(BaseModel):
    asset_id: str
    action: str  # "buy" or "sell"
    quantity: float
    price: float

router = APIRouter(prefix="/api/portfolio", tags=["portfolio"])


@router.post("/trades", status_code=201, response_model=PaperTradeRead)
async def create_trade(body: PaperTradeCreate, db: AsyncSession = Depends(get_db)):
    """Open a new paper trade based on a signal."""
    try:
        trade = await execute_trade(
            db, signal_id=body.signal_id,
            price=body.price, quantity=body.quantity,
        )
    except SignalNotFoundError as exc:
        raise HTTPException(404, str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(422, str(exc)) from exc
    return _to_read(trade)


@router.post("/trades/manual", status_code=201, response_model=PaperTradeRead)
async def create_manual_trade(body: ManualTradeCreate, db: AsyncSession = Depends(get_db)):
    """Create a trade without a signal — manual portfolio entry."""
    try:
        trade = await execute_manual_trade(db, body.asset_id, body.action, body.price, body.quantity)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    return _to_read(trade)


@router.post("/trades/{trade_id}/close", response_model=PaperTradeRead)
async def close_trade_endpoint(
    trade_id: int,
    body: PaperTradeClose,
    db: AsyncSession = Depends(get_db),
):
    """Close an open paper trade at the given price."""
    try:
        trade = await close_trade(db, trade_id=trade_id, close_price=body.close_price)
    except TradeAlreadyClosedError as exc:
        raise HTTPException(409, str(exc)) from exc
    except TradeNotFoundError as exc:
        raise HTTPException(404, str(exc)) from exc
    return _to_read(trade)


@router.get("/trades", response_model=list[PaperTradeRead])
async def list_trades(
    status: Literal["open", "closed"] | None = None,
    asset_id: str | None = None,
    limit: int = Query(default=100, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
):
    """List paper trades, optionally filtered by status or asset."""
    stmt = select(PaperTrade)
    if status:
        stmt = stmt.where(PaperTrade.status == status)
    if asset_id:
        stmt = stmt.where(PaperTrade.asset_id == asset_id)
    stmt = stmt.order_by(PaperTrade.id.desc()).limit(limit)
    result = await db.execute(stmt)
    return [_to_read(t) for t in result.scalars().all()]


@router.post("/refresh/{asset_id}", response_model=list[PaperTradeRead])
async def refresh_positions(
    asset_id: str,
    current_price: float = Query(gt=0),
    db: AsyncSession = Depends(get_db),
):
    """Update price_now and unrealized P&L for all open trades of an asset."""
    trades = await update_open_positions(db, asset_id=asset_id, current_price=current_price)
    return [_to_read(t) for t in trades]


@router.get("/summary", response_model=PortfolioSummary)
async def portfolio_summary(db: AsyncSession = Depends(get_db)):
    """Get portfolio-level P&L summary across all trades."""
    return await get_portfolio_summary(db)


def _to_read(trade: PaperTrade) -> PaperTradeRead:
    return PaperTradeRead(
        id=trade.id,
        signal_id=trade.signal_id,
        asset_id=trade.asset_id,
        action=trade.action,
        quantity=trade.quantity,
        price_at=trade.price_at,
        price_now=trade.price_now,
        pnl=trade.pnl,
        status=trade.status,
        opened_at=trade.opened_at,
        closed_at=trade.closed_at,
    )
