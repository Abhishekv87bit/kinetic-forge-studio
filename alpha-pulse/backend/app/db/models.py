from datetime import datetime, timezone


def _utcnow():
    return datetime.now(timezone.utc)

from sqlalchemy import (
    Column,
    Index,
    String,
    Integer,
    Float,
    Boolean,
    DateTime,
    Text,
    ForeignKey,
    JSON,
)
from sqlalchemy.orm import DeclarativeBase, relationship


class Base(DeclarativeBase):
    pass


class Asset(Base):
    __tablename__ = "assets"

    id = Column(String, primary_key=True)  # ticker symbol
    asset_class = Column(String, nullable=False)  # equity, crypto, commodity, forex
    name = Column(String, nullable=False)
    tracked = Column(Boolean, default=True)
    metadata_ = Column("metadata", JSON, default=dict)
    created_at = Column(DateTime(timezone=True), default=_utcnow)

    signals = relationship("Signal", back_populates="asset", cascade="all, delete-orphan")
    snapshots = relationship("DataSnapshot", back_populates="asset", cascade="all, delete-orphan")
    trades = relationship("PaperTrade", back_populates="asset", cascade="all, delete-orphan")
    signal_scores = relationship("SignalScore", back_populates="asset", cascade="all, delete-orphan")


class DataSnapshot(Base):
    __tablename__ = "data_snapshots"
    __table_args__ = (
        Index("ix_datasnapshot_asset_source", "asset_id", "source"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    asset_id = Column(String, ForeignKey("assets.id"), nullable=False)
    source = Column(String, nullable=False)
    source_url = Column(Text, default="")
    raw_data = Column(JSON, default=dict)
    period = Column(String, default="")
    fetched_at = Column(DateTime(timezone=True), default=_utcnow)

    asset = relationship("Asset", back_populates="snapshots")


class GoldenRule(Base):
    __tablename__ = "golden_rules"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    description = Column(Text, default="")
    rule_prompt = Column(Text, nullable=False)
    asset_class = Column(String, nullable=True)
    weight = Column(Float, default=0.5)
    active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=_utcnow)


class Signal(Base):
    __tablename__ = "signals"
    __table_args__ = (
        Index("ix_signal_asset_id", "asset_id"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    asset_id = Column(String, ForeignKey("assets.id"), nullable=False)
    signal_type = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    summary = Column(Text, default="")
    evidence = Column(JSON, default=list)
    risk_flags = Column(JSON, default=list)
    raw_llm = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), default=_utcnow)

    asset = relationship("Asset", back_populates="signals")
    trades = relationship("PaperTrade", back_populates="signal")


class PaperTrade(Base):
    __tablename__ = "paper_trades"
    __table_args__ = (
        Index("ix_papertrade_asset_status", "asset_id", "status"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    signal_id = Column(Integer, ForeignKey("signals.id"), nullable=False)
    asset_id = Column(String, ForeignKey("assets.id", ondelete="CASCADE"), nullable=False)
    action = Column(String, nullable=False)
    quantity = Column(Float, nullable=False)
    price_at = Column(Float, nullable=False)
    price_now = Column(Float, default=0.0)
    pnl = Column(Float, default=0.0)
    status = Column(String, default="open")
    opened_at = Column(DateTime(timezone=True), default=_utcnow)
    closed_at = Column(DateTime(timezone=True), nullable=True)

    signal = relationship("Signal", back_populates="trades")
    asset = relationship("Asset", back_populates="trades")


class BacktestRun(Base):
    __tablename__ = "backtest_runs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    rule_ids = Column(JSON, default=list)
    date_from = Column(String, nullable=False)
    date_to = Column(String, nullable=False)
    asset_ids = Column(JSON, default=list)
    initial_capital = Column(Float, default=100000.0)
    config = Column(JSON, default=dict)
    created_at = Column(DateTime(timezone=True), default=_utcnow)

    results = relationship("BacktestResult", back_populates="run")


class BacktestResult(Base):
    __tablename__ = "backtest_results"

    id = Column(Integer, primary_key=True, autoincrement=True)
    run_id = Column(Integer, ForeignKey("backtest_runs.id"), nullable=False)
    total_return = Column(Float, default=0.0)
    sharpe_ratio = Column(Float, default=0.0)
    max_drawdown = Column(Float, default=0.0)
    win_rate = Column(Float, default=0.0)
    trades = Column(JSON, default=list)
    equity_curve = Column(JSON, default=list)
    benchmark = Column(JSON, default=dict)

    run = relationship("BacktestRun", back_populates="results")


class SignalScore(Base):
    __tablename__ = "signal_scores"
    __table_args__ = (
        Index("ix_signalscore_asset_signal", "asset_id", "signal_name"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    asset_id = Column(String, ForeignKey("assets.id"), nullable=False)
    signal_name = Column(String, nullable=False)
    score = Column(Float, default=0.0)
    details = Column(JSON, default=dict)
    computed_at = Column(DateTime(timezone=True), default=_utcnow)

    asset = relationship("Asset", back_populates="signal_scores")


class AlertLog(Base):
    __tablename__ = "alert_log"

    id = Column(Integer, primary_key=True, autoincrement=True)
    signal_id = Column(Integer, ForeignKey("signals.id"), nullable=True)
    channel = Column(String, nullable=False)
    priority = Column(String, default="default")
    message = Column(Text, nullable=False)
    sent_at = Column(DateTime(timezone=True), default=_utcnow)
    acknowledged = Column(Boolean, default=False)
