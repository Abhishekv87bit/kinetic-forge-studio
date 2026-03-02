from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field


class AssetClass(str, Enum):
    EQUITY = "equity"
    CRYPTO = "crypto"
    COMMODITY = "commodity"
    FOREX = "forex"


class SignalType(str, Enum):
    STRONG_BUY = "strong_buy"
    BUY = "buy"
    HOLD = "hold"
    SELL = "sell"
    STRONG_SELL = "strong_sell"


# ── Asset schemas ──


class AssetCreate(BaseModel):
    id: str = Field(pattern=r"^[A-Za-z0-9._-]{1,20}$")
    asset_class: AssetClass
    name: str = Field(min_length=1, max_length=200)
    tracked: bool = True
    metadata: dict = Field(default_factory=dict)


class AssetRead(AssetCreate):
    created_at: datetime | None = None


class AssetUpdate(BaseModel):
    tracked: bool | None = None
    name: str | None = Field(None, min_length=1)


# ── Rule schemas ──


class RuleCreate(BaseModel):
    name: str
    description: str = ""
    rule_prompt: str
    asset_class: AssetClass | None = None
    weight: float = Field(default=0.5, ge=0.0, le=1.0)
    active: bool = True


class RuleRead(RuleCreate):
    id: int
    created_at: datetime | None = None


class RuleUpdate(BaseModel):
    name: str | None = Field(None, min_length=1)
    description: str | None = None
    rule_prompt: str | None = Field(None, min_length=1)
    asset_class: AssetClass | None = None
    weight: float | None = Field(None, ge=0.0, le=1.0)
    active: bool | None = None


class RuleEvalResult(BaseModel):
    rule_name: str = ""
    rule_id: int = 0
    direction: str = ""
    score: float = Field(ge=-1.0, le=1.0, default=0.0)
    reasoning: str = ""


class EvidenceItem(BaseModel, extra="allow"):
    """Evidence item from an agent source — allows extra fields per source."""
    source: str


class RiskFlagItem(BaseModel):
    category: str
    severity: str
    headline: str


# ── Signal schemas ──


class SignalOutput(BaseModel):
    asset_id: str
    signal_type: SignalType
    confidence: float = Field(ge=0.0, le=1.0)
    summary: str
    evidence: list[EvidenceItem] = Field(default_factory=list)
    risk_flags: list[RiskFlagItem] = Field(default_factory=list)


class SignalRead(SignalOutput):
    id: int
    raw_llm: dict = Field(default_factory=dict)
    created_at: datetime | None = None


# ── Paper trade schemas ──


class PaperTradeCreate(BaseModel):
    signal_id: int
    price: float = Field(gt=0)
    quantity: float = Field(gt=0)


class PaperTradeClose(BaseModel):
    close_price: float = Field(gt=0)


class PaperTradeRead(BaseModel):
    id: int
    signal_id: int | None = None
    asset_id: str
    action: Literal["buy", "sell"]
    quantity: float
    price_at: float
    price_now: float
    pnl: float
    status: Literal["open", "closed"]
    opened_at: datetime | None = None
    closed_at: datetime | None = None


class PortfolioSummary(BaseModel):
    total_trades: int = 0
    open_trades: int = 0
    closed_trades: int = 0
    realized_pnl: float = 0.0
    unrealized_pnl: float = 0.0
    total_pnl: float = 0.0
    win_rate: float = 0.0


# ── Backtest schemas ──


class BacktestCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    asset_ids: list[str] = Field(min_length=1)
    date_from: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    date_to: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    rule_ids: list[int] = Field(default_factory=list)
    initial_capital: float = Field(default=100_000.0, gt=0)
    config: dict = Field(default_factory=lambda: {
        "position_size_pct": 0.10,
        "stop_loss_pct": 0.05,
        "max_hold_days": 30,
    })


class BacktestTradeRecord(BaseModel):
    asset_id: str
    signal_id: int
    signal_type: str
    entry_date: str
    entry_price: float
    exit_date: str | None = None
    exit_price: float | None = None
    pnl: float = 0.0
    pnl_pct: float = 0.0
    exit_reason: str = ""


class BacktestResultRead(BaseModel):
    id: int
    run_id: int
    total_return: float
    sharpe_ratio: float
    max_drawdown: float
    win_rate: float
    trades: list[BacktestTradeRecord]
    equity_curve: list[dict]
    benchmark: dict


class BacktestRunRead(BaseModel):
    id: int
    name: str
    rule_ids: list[int]
    date_from: str
    date_to: str
    asset_ids: list[str]
    initial_capital: float
    config: dict
    created_at: datetime | None = None
    results: list[BacktestResultRead] = Field(default_factory=list)
