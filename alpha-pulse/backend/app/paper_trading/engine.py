"""Paper trading engine — execute, close, and track virtual trades.

All trades are virtual. No real money is involved. The engine records
trades against Signal records so you can later evaluate whether your
Golden Rules actually produce profitable signals.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import PaperTrade, Signal

# Custom exceptions for unambiguous error handling at route boundaries
class TradeNotFoundError(ValueError):
    """Raised when a trade ID does not exist."""

class TradeAlreadyClosedError(ValueError):
    """Raised when attempting to close a trade that is already closed."""

class SignalNotFoundError(ValueError):
    """Raised when a signal ID does not exist."""

logger = logging.getLogger(__name__)


async def execute_trade(
    db: AsyncSession,
    *,
    signal_id: int,
    price: float,
    quantity: float,
) -> PaperTrade:
    """Open a new paper trade based on a signal.

    Args:
        db: Async database session.
        signal_id: The signal that triggered this trade.
        price: Entry price.
        quantity: Number of units.

    Returns:
        The created PaperTrade (status="open").

    Raises:
        ValueError: If signal doesn't exist.
    """
    signal = await db.get(Signal, signal_id)
    if not signal:
        raise SignalNotFoundError(f"Signal {signal_id} not found")

    # Derive action from signal type — hold signals are rejected (I-3)
    if signal.signal_type == "hold":
        raise ValueError("Cannot create trade from a 'hold' signal")
    action = "sell" if signal.signal_type in ("sell", "strong_sell") else "buy"

    trade = PaperTrade(
        signal_id=signal_id,
        asset_id=signal.asset_id,
        action=action,
        quantity=quantity,
        price_at=price,
        price_now=price,
        pnl=0.0,
        status="open",
    )
    db.add(trade)
    await db.commit()
    await db.refresh(trade)

    logger.info(
        "Paper trade opened: %s %s x%.1f @ %.2f (signal=%d)",
        action.upper(), signal.asset_id, quantity, price, signal_id,
    )
    return trade


async def execute_manual_trade(
    db: AsyncSession,
    asset_id: str,
    action: str,
    price: float,
    quantity: float,
) -> PaperTrade:
    """Create a paper trade without requiring an existing signal."""
    if action not in ("buy", "sell"):
        raise ValueError(f"action must be 'buy' or 'sell', got '{action}'")
    if price <= 0 or quantity <= 0:
        raise ValueError("price and quantity must be positive")

    trade = PaperTrade(
        signal_id=None,
        asset_id=asset_id,
        action=action,
        quantity=quantity,
        price_at=price,
        price_now=price,
        pnl=0.0,
        status="open",
    )
    db.add(trade)
    await db.commit()
    await db.refresh(trade)
    return trade


async def close_trade(
    db: AsyncSession,
    *,
    trade_id: int,
    close_price: float,
) -> PaperTrade:
    """Close an open paper trade and lock in P&L.

    Args:
        db: Async database session.
        trade_id: The trade to close.
        close_price: Exit price.

    Returns:
        The closed PaperTrade with final P&L.

    Raises:
        ValueError: If trade doesn't exist or is already closed.
    """
    # SELECT ... FOR UPDATE prevents concurrent close on the same row.
    # SQLite ignores FOR UPDATE (single-writer) but this is correct for Postgres.
    result = await db.execute(
        select(PaperTrade)
        .where(PaperTrade.id == trade_id)
        .with_for_update()
    )
    trade = result.scalar_one_or_none()
    if not trade:
        raise TradeNotFoundError(f"Trade {trade_id} not found")
    if trade.status == "closed":
        raise TradeAlreadyClosedError(f"Trade {trade_id} is already closed")

    trade.price_now = close_price
    trade.status = "closed"
    trade.closed_at = datetime.now(timezone.utc)

    # P&L calculation:
    # Buy trade: profit = (close - entry) * qty
    # Sell (short) trade: profit = (entry - close) * qty
    if trade.action == "buy":
        trade.pnl = (close_price - trade.price_at) * trade.quantity
    else:
        trade.pnl = (trade.price_at - close_price) * trade.quantity

    await db.commit()
    await db.refresh(trade)

    logger.info(
        "Paper trade closed: %s %s x%.1f @ %.2f → PnL=%.2f",
        trade.action.upper(), trade.asset_id, trade.quantity,
        close_price, trade.pnl,
    )
    return trade


async def update_open_positions(
    db: AsyncSession,
    *,
    asset_id: str,
    current_price: float,
) -> list[PaperTrade]:
    """Update price_now and unrealized P&L for all open trades of an asset.

    Called periodically by the scheduler when new market data arrives.

    Args:
        db: Async database session.
        asset_id: The asset to update.
        current_price: Current market price.

    Returns:
        List of updated open trades.
    """
    result = await db.execute(
        select(PaperTrade).where(
            PaperTrade.asset_id == asset_id,
            PaperTrade.status == "open",
        )
    )
    trades = list(result.scalars().all())

    for trade in trades:
        trade.price_now = current_price
        if trade.action == "buy":
            trade.pnl = (current_price - trade.price_at) * trade.quantity
        else:
            trade.pnl = (trade.price_at - current_price) * trade.quantity

    if trades:
        await db.commit()
        logger.debug(
            "Updated %d open positions for %s @ %.2f",
            len(trades), asset_id, current_price,
        )

    return trades


async def get_portfolio_summary(db: AsyncSession) -> dict:
    """Compute portfolio-level summary across all trades.

    Uses SQL-level aggregation — only scalar results come back,
    regardless of how many trades exist in the DB.

    Returns:
        Dict with: total_trades, open_trades, closed_trades,
        realized_pnl, unrealized_pnl, total_pnl, win_rate.
    """
    is_open = PaperTrade.status == "open"
    is_closed = PaperTrade.status == "closed"

    stmt = select(
        func.count().label("total"),
        func.count(case((is_open, 1))).label("n_open"),
        func.count(case((is_closed, 1))).label("n_closed"),
        func.coalesce(func.sum(case((is_closed, PaperTrade.pnl))), 0.0).label("realized"),
        func.coalesce(func.sum(case((is_open, PaperTrade.pnl))), 0.0).label("unrealized"),
        func.count(case((is_closed & (PaperTrade.pnl > 0), 1))).label("wins"),
    )

    result = await db.execute(stmt)
    row = result.one()

    total = row.total
    n_open = row.n_open
    n_closed = row.n_closed
    realized = float(row.realized)
    unrealized = float(row.unrealized)
    wins = row.wins
    win_rate = wins / n_closed if n_closed > 0 else 0.0

    return {
        "total_trades": total,
        "open_trades": n_open,
        "closed_trades": n_closed,
        "realized_pnl": round(realized, 2),
        "unrealized_pnl": round(unrealized, 2),
        "total_pnl": round(realized + unrealized, 2),
        "win_rate": round(win_rate, 4),
    }
