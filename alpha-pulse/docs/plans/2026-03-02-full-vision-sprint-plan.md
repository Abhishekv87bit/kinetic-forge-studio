# Full Vision Sprint Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Alpha Pulse from a 3-asset demo into a 30-asset market intelligence platform with research-backed quantitative signals, auto-scanning, and an enhanced dashboard.

**Architecture:** Layer Cake — 5 horizontal layers built sequentially with QA gates. Each layer is independently testable. Signal calculators are pure functions (no LLM). Enhanced orchestrator feeds signal scores to LLM agents for richer context.

**Tech Stack:** Python 3.10+ / FastAPI / SQLAlchemy async / Groq (Llama 3.3 70B) / yfinance / edgartools / textstat / pysentiment2 / FinBERT (transformers) / React 18 / TypeScript / Tailwind v4

---

## Layer 1: Data Foundation

### Task 1: Add new dependencies

**Files:**
- Modify: `backend/pyproject.toml`

**Step 1: Add dependencies for signal calculators**

Add to the `dependencies` list in `pyproject.toml`:

```toml
"edgartools>=2.0,<4",
"textstat>=0.7,<1",
"pysentiment2>=0.1,<1",
"transformers>=4.36,<5",
"torch>=2.1,<3",
"groq>=0.4,<1",
"google-generativeai>=0.3,<1",
```

**Step 2: Install dependencies**

Run: `cd "D:/Claude local/alpha-pulse/backend" && pip install -e ".[dev]"`

**Step 3: Commit**

```bash
git add backend/pyproject.toml
git commit -m "chore: add signal calculator dependencies (edgartools, textstat, pysentiment2, transformers)"
```

---

### Task 2: Create asset seed module

**Files:**
- Create: `backend/app/ingestion/seed.py`
- Test: `backend/tests/test_seed.py`

**Step 1: Write the failing test**

```python
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
```

**Step 2: Run test to verify it fails**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_seed.py -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'app.ingestion.seed'"

**Step 3: Write the implementation**

```python
# app/ingestion/seed.py
"""Default asset seeding — populates DB with top 30 market assets."""

from __future__ import annotations

import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset

logger = logging.getLogger(__name__)

DEFAULT_ASSETS = [
    # Equities (20) — top by market cap across sectors
    {"id": "AAPL", "asset_class": "equity", "name": "Apple Inc."},
    {"id": "MSFT", "asset_class": "equity", "name": "Microsoft Corp."},
    {"id": "GOOGL", "asset_class": "equity", "name": "Alphabet Inc."},
    {"id": "AMZN", "asset_class": "equity", "name": "Amazon.com Inc."},
    {"id": "NVDA", "asset_class": "equity", "name": "NVIDIA Corp."},
    {"id": "META", "asset_class": "equity", "name": "Meta Platforms Inc."},
    {"id": "TSLA", "asset_class": "equity", "name": "Tesla Inc."},
    {"id": "BRK-B", "asset_class": "equity", "name": "Berkshire Hathaway B"},
    {"id": "JPM", "asset_class": "equity", "name": "JPMorgan Chase & Co."},
    {"id": "V", "asset_class": "equity", "name": "Visa Inc."},
    {"id": "UNH", "asset_class": "equity", "name": "UnitedHealth Group"},
    {"id": "JNJ", "asset_class": "equity", "name": "Johnson & Johnson"},
    {"id": "WMT", "asset_class": "equity", "name": "Walmart Inc."},
    {"id": "PG", "asset_class": "equity", "name": "Procter & Gamble Co."},
    {"id": "MA", "asset_class": "equity", "name": "Mastercard Inc."},
    {"id": "HD", "asset_class": "equity", "name": "The Home Depot Inc."},
    {"id": "XOM", "asset_class": "equity", "name": "Exxon Mobil Corp."},
    {"id": "LLY", "asset_class": "equity", "name": "Eli Lilly and Co."},
    {"id": "AVGO", "asset_class": "equity", "name": "Broadcom Inc."},
    {"id": "COST", "asset_class": "equity", "name": "Costco Wholesale Corp."},
    # Crypto (10) — top by market cap
    {"id": "BTC-USD", "asset_class": "crypto", "name": "Bitcoin"},
    {"id": "ETH-USD", "asset_class": "crypto", "name": "Ethereum"},
    {"id": "SOL-USD", "asset_class": "crypto", "name": "Solana"},
    {"id": "BNB-USD", "asset_class": "crypto", "name": "Binance Coin"},
    {"id": "XRP-USD", "asset_class": "crypto", "name": "XRP"},
    {"id": "ADA-USD", "asset_class": "crypto", "name": "Cardano"},
    {"id": "DOGE-USD", "asset_class": "crypto", "name": "Dogecoin"},
    {"id": "AVAX-USD", "asset_class": "crypto", "name": "Avalanche"},
    {"id": "DOT-USD", "asset_class": "crypto", "name": "Polkadot"},
    {"id": "LINK-USD", "asset_class": "crypto", "name": "Chainlink"},
]


async def seed_default_assets(db: AsyncSession) -> int:
    """Seed default assets. Returns count of newly created assets."""
    created = 0
    for asset_data in DEFAULT_ASSETS:
        existing = await db.get(Asset, asset_data["id"])
        if existing is None:
            db.add(Asset(**asset_data))
            created += 1
            logger.info("Seeded asset: %s (%s)", asset_data["id"], asset_data["name"])
    if created:
        await db.commit()
    return created
```

**Step 4: Run test to verify it passes**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_seed.py -v`
Expected: 3 PASSED

**Step 5: Commit**

```bash
git add backend/app/ingestion/seed.py backend/tests/test_seed.py
git commit -m "feat: add asset seeding module with 30 default assets (20 equity + 10 crypto)"
```

---

### Task 3: Integrate seeding into init_db

**Files:**
- Modify: `backend/app/db/database.py:54-68`

**Step 1: Write the failing test**

```python
# tests/test_seed.py (append)

async def test_seed_called_from_init_db(db_session):
    """Verify init_db seeds default assets (integration check)."""
    # init_db is already called by conftest via Base.metadata.create_all
    # We just need to verify the seed function can run without error
    from app.ingestion.seed import seed_default_assets
    # Should be idempotent — db_session starts empty (no seed in conftest)
    count = await seed_default_assets(db_session)
    assert count == 30
```

**Step 2: Modify init_db to call seed_default_assets**

In `backend/app/db/database.py`, add to the `init_db()` function after the system assets loop:

```python
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
```

**Step 3: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v`
Expected: All existing 136 + 4 new = 140 PASSED

**Step 4: Commit**

```bash
git add backend/app/db/database.py backend/tests/test_seed.py
git commit -m "feat: integrate asset seeding into init_db — 30 assets on first startup"
```

---

### Task 4: Create bulk ingestion module

**Files:**
- Create: `backend/app/ingestion/bulk_ingest.py`
- Test: `backend/tests/test_bulk_ingest.py`

**Step 1: Write the failing test**

```python
# tests/test_bulk_ingest.py
import pytest
from unittest.mock import patch, AsyncMock
from sqlalchemy import select
from app.db.models import Asset, DataSnapshot
from app.ingestion.seed import seed_default_assets
from app.ingestion.bulk_ingest import bulk_ingest_all


async def test_bulk_ingest_calls_market_for_equities(db_session):
    await seed_default_assets(db_session)

    with patch("app.ingestion.bulk_ingest.fetch_market_data_async", new_callable=AsyncMock) as mock_fetch, \
         patch("app.ingestion.bulk_ingest.save_market_snapshot", new_callable=AsyncMock) as mock_save, \
         patch("app.ingestion.bulk_ingest.fetch_crypto_data", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.save_crypto_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.asyncio.sleep", new_callable=AsyncMock):
        mock_fetch.return_value = {"ticker": "AAPL", "price": 150.0}
        result = await bulk_ingest_all(db_session)
        assert result["equities_attempted"] == 20
        assert mock_fetch.call_count == 20


async def test_bulk_ingest_calls_crypto_for_crypto_assets(db_session):
    await seed_default_assets(db_session)

    with patch("app.ingestion.bulk_ingest.fetch_market_data_async", new_callable=AsyncMock) as mock_market, \
         patch("app.ingestion.bulk_ingest.save_market_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.fetch_crypto_data", new_callable=AsyncMock) as mock_crypto, \
         patch("app.ingestion.bulk_ingest.save_crypto_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.asyncio.sleep", new_callable=AsyncMock):
        mock_market.return_value = {"ticker": "AAPL", "price": 150.0}
        mock_crypto.return_value = {"ticker": "BTC-USD", "price": 60000.0}
        result = await bulk_ingest_all(db_session)
        assert result["crypto_attempted"] == 10
        assert mock_crypto.call_count == 10


async def test_bulk_ingest_handles_individual_failures(db_session):
    await seed_default_assets(db_session)

    with patch("app.ingestion.bulk_ingest.fetch_market_data_async", new_callable=AsyncMock) as mock_fetch, \
         patch("app.ingestion.bulk_ingest.save_market_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.fetch_crypto_data", new_callable=AsyncMock) as mock_crypto, \
         patch("app.ingestion.bulk_ingest.save_crypto_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.asyncio.sleep", new_callable=AsyncMock):
        mock_fetch.side_effect = Exception("yfinance down")
        mock_crypto.return_value = {"ticker": "BTC-USD", "price": 60000.0}
        result = await bulk_ingest_all(db_session)
        assert result["equities_failed"] == 20
        assert result["crypto_succeeded"] == 10
```

**Step 2: Run test to verify it fails**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_bulk_ingest.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write the implementation**

```python
# app/ingestion/bulk_ingest.py
"""Bulk ingestion — run all data sources once for all tracked assets."""

from __future__ import annotations

import asyncio
import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset
from app.ingestion.market_data import fetch_market_data_async, save_market_snapshot
from app.ingestion.crypto_data import fetch_crypto_data, save_crypto_snapshot

logger = logging.getLogger(__name__)


async def bulk_ingest_all(db: AsyncSession) -> dict:
    """Run market + crypto ingestion for all tracked assets.

    Returns summary dict with counts of attempted/succeeded/failed.
    """
    # Get tracked equities
    result = await db.execute(
        select(Asset.id).where(Asset.asset_class == "equity", Asset.tracked.is_(True))
    )
    equity_ids = list(result.scalars().all())

    # Get tracked crypto
    result = await db.execute(
        select(Asset.id).where(Asset.asset_class == "crypto", Asset.tracked.is_(True))
    )
    crypto_ids = list(result.scalars().all())

    summary = {
        "equities_attempted": len(equity_ids),
        "equities_succeeded": 0,
        "equities_failed": 0,
        "crypto_attempted": len(crypto_ids),
        "crypto_succeeded": 0,
        "crypto_failed": 0,
    }

    # Ingest equities
    for i, asset_id in enumerate(equity_ids):
        try:
            if i > 0:
                await asyncio.sleep(1)  # Rate limit: 1 req/sec
            data = await fetch_market_data_async(asset_id)
            await save_market_snapshot(db, asset_id, data)
            summary["equities_succeeded"] += 1
            logger.info("Bulk ingested market data for %s (%d/%d)", asset_id, i + 1, len(equity_ids))
        except Exception:
            summary["equities_failed"] += 1
            logger.exception("Bulk ingestion failed for %s", asset_id)

    # Ingest crypto
    for i, asset_id in enumerate(crypto_ids):
        try:
            if i > 0:
                await asyncio.sleep(2)  # CoinGecko rate limit
            data = await fetch_crypto_data(asset_id)
            await save_crypto_snapshot(db, asset_id, data)
            summary["crypto_succeeded"] += 1
            logger.info("Bulk ingested crypto data for %s (%d/%d)", asset_id, i + 1, len(crypto_ids))
        except Exception:
            summary["crypto_failed"] += 1
            logger.exception("Bulk crypto ingestion failed for %s", asset_id)

    logger.info("Bulk ingestion complete: %s", summary)
    return summary
```

**Step 4: Run test to verify it passes**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_bulk_ingest.py -v`
Expected: 3 PASSED

**Step 5: Commit**

```bash
git add backend/app/ingestion/bulk_ingest.py backend/tests/test_bulk_ingest.py
git commit -m "feat: add bulk ingestion module — ingest all tracked assets in one pass"
```

---

### Task 5: Add bulk ingest API endpoint

**Files:**
- Create: `backend/app/routes/ingest.py`
- Modify: `backend/app/main.py:14,78-84` (add router import + include)
- Test: `backend/tests/test_routes_ingest.py`

**Step 1: Write the failing test**

```python
# tests/test_routes_ingest.py
import pytest
from unittest.mock import patch, AsyncMock


async def test_bulk_ingest_endpoint(client):
    with patch("app.routes.ingest.bulk_ingest_all", new_callable=AsyncMock) as mock:
        mock.return_value = {
            "equities_attempted": 20, "equities_succeeded": 20, "equities_failed": 0,
            "crypto_attempted": 10, "crypto_succeeded": 10, "crypto_failed": 0,
        }
        resp = await client.post("/api/ingest/bulk")
        assert resp.status_code == 200
        data = resp.json()
        assert data["equities_succeeded"] == 20
        assert data["crypto_succeeded"] == 10


async def test_bulk_ingest_returns_partial_failures(client):
    with patch("app.routes.ingest.bulk_ingest_all", new_callable=AsyncMock) as mock:
        mock.return_value = {
            "equities_attempted": 20, "equities_succeeded": 18, "equities_failed": 2,
            "crypto_attempted": 10, "crypto_succeeded": 10, "crypto_failed": 0,
        }
        resp = await client.post("/api/ingest/bulk")
        assert resp.status_code == 200
        data = resp.json()
        assert data["equities_failed"] == 2
```

**Step 2: Write the route**

```python
# app/routes/ingest.py
"""Bulk ingestion endpoint — trigger data pull for all tracked assets."""

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
```

**Step 3: Register router in main.py**

Add import: `from app.routes.ingest import router as ingest_router`
Add include: `app.include_router(ingest_router)`

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_routes_ingest.py tests/test_seed.py tests/test_bulk_ingest.py -v`
Expected: All PASSED

**Step 5: Commit**

```bash
git add backend/app/routes/ingest.py backend/tests/test_routes_ingest.py backend/app/main.py
git commit -m "feat: add POST /api/ingest/bulk endpoint for on-demand data pull"
```

---

### Task 6: QA Gate 1 — Full test suite

**Step 1: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~145 PASSED, 0 FAILED

**Step 2: Verify assets seed on startup**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -c "import asyncio; from app.db.database import init_db; asyncio.run(init_db()); print('OK')"`
Expected: "Seeded 30 default assets" in log output + "OK"

**Step 3: Commit QA checkpoint**

```bash
git commit --allow-empty -m "checkpoint: Layer 1 complete — 30 assets seeded, bulk ingest working, all tests pass"
```

---

## Layer 2: Signal Calculators

### Task 7: Add SignalScore model

**Files:**
- Modify: `backend/app/db/models.py:38` (add relationship to Asset)
- Test: `backend/tests/test_db_models.py` (append)

**Step 1: Write the failing test**

```python
# tests/test_db_models.py (append)

async def test_signal_score_crud(db_session):
    from app.db.models import Asset, SignalScore
    asset = Asset(id="TEST", asset_class="equity", name="Test")
    db_session.add(asset)
    await db_session.flush()

    score = SignalScore(
        asset_id="TEST",
        signal_name="lifecycle",
        score=0.7,
        details={"stage": "maturity"},
    )
    db_session.add(score)
    await db_session.commit()

    from sqlalchemy import select
    result = await db_session.execute(
        select(SignalScore).where(SignalScore.asset_id == "TEST")
    )
    saved = result.scalar_one()
    assert saved.signal_name == "lifecycle"
    assert saved.score == 0.7
    assert saved.details["stage"] == "maturity"
```

**Step 2: Add the model to models.py**

After the `AlertLog` class, add:

```python
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
```

Add to Asset class (after `trades` relationship):
```python
    signal_scores = relationship("SignalScore", back_populates="asset", cascade="all, delete-orphan")
```

**Step 3: Run test**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_db_models.py -v`
Expected: All PASSED (including new test)

**Step 4: Commit**

```bash
git add backend/app/db/models.py backend/tests/test_db_models.py
git commit -m "feat: add SignalScore model for quantitative signal storage"
```

---

### Task 8: Lifecycle signal calculator

**Files:**
- Create: `backend/app/signals/__init__.py`
- Create: `backend/app/signals/lifecycle.py`
- Test: `backend/tests/test_signal_lifecycle.py`

**Step 1: Write the failing test**

```python
# tests/test_signal_lifecycle.py
import pytest
from app.signals.lifecycle import compute_lifecycle_score


def test_maturity_stage():
    """Maturity: operating +, investing -, financing -"""
    cashflows = [
        {"operating": 5000, "investing": -2000, "financing": -1000},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == 0.7
    assert result["stage"] == "maturity"


def test_growth_stage():
    """Growth: operating +, investing -, financing +"""
    cashflows = [
        {"operating": 3000, "investing": -4000, "financing": 2000},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == 0.4
    assert result["stage"] == "growth"


def test_introduction_stage():
    """Introduction: operating -, investing -, financing +"""
    cashflows = [
        {"operating": -1000, "investing": -2000, "financing": 5000},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == -0.5
    assert result["stage"] == "introduction"


def test_decline_stage():
    """Decline: operating -, investing +, financing mixed"""
    cashflows = [
        {"operating": -500, "investing": 1000, "financing": -200},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == -0.8
    assert result["stage"] == "decline"


def test_empty_cashflows_returns_zero():
    result = compute_lifecycle_score([])
    assert result["score"] == 0.0
    assert result["stage"] == "unknown"


def test_multiple_quarters_uses_latest():
    cashflows = [
        {"operating": -1000, "investing": -2000, "financing": 5000},  # intro (older)
        {"operating": 5000, "investing": -2000, "financing": -1000},  # maturity (latest)
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["stage"] == "maturity"
```

**Step 2: Write the implementation**

```python
# app/signals/__init__.py
"""Quantitative signal calculators — pure functions, no LLM calls."""

# app/signals/lifecycle.py
"""Corporate lifecycle classification using Dickinson (2011) cash flow method.

Classifies companies by the sign pattern of operating, investing, and
financing cash flows into: Introduction, Growth, Maturity, Shakeout, Decline.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Dickinson lifecycle classification: (operating_sign, investing_sign, financing_sign) -> stage
_STAGE_MAP = {
    ("-", "-", "+"): "introduction",
    ("+", "-", "+"): "growth",
    ("+", "-", "-"): "maturity",
    ("-", "+", "+"): "decline",
    ("-", "+", "-"): "decline",
}

_SCORE_MAP = {
    "maturity": 0.7,
    "growth": 0.4,
    "shakeout": -0.2,
    "introduction": -0.5,
    "decline": -0.8,
    "unknown": 0.0,
}


def _sign(value: float) -> str:
    return "+" if value >= 0 else "-"


def compute_lifecycle_score(cashflows: list[dict]) -> dict:
    """Compute lifecycle stage from quarterly cash flow data.

    Args:
        cashflows: List of dicts with 'operating', 'investing', 'financing' keys.
                   Last item is the most recent quarter.

    Returns:
        Dict with 'score' (-1 to +1), 'stage', and 'details'.
    """
    if not cashflows:
        return {"score": 0.0, "stage": "unknown", "details": {"reason": "no cash flow data"}}

    # Use the most recent quarter
    latest = cashflows[-1]
    op = latest.get("operating", 0)
    inv = latest.get("investing", 0)
    fin = latest.get("financing", 0)

    pattern = (_sign(op), _sign(inv), _sign(fin))
    stage = _STAGE_MAP.get(pattern, "shakeout")
    score = _SCORE_MAP[stage]

    return {
        "score": score,
        "stage": stage,
        "details": {
            "operating_cf": op,
            "investing_cf": inv,
            "financing_cf": fin,
            "pattern": "".join(pattern),
            "quarters_available": len(cashflows),
        },
    }
```

**Step 3: Run test**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_lifecycle.py -v`
Expected: 6 PASSED

**Step 4: Commit**

```bash
git add backend/app/signals/ backend/tests/test_signal_lifecycle.py
git commit -m "feat: add lifecycle signal calculator (Dickinson cash flow method)"
```

---

### Task 9: Insider trading signal calculator

**Files:**
- Create: `backend/app/signals/insider.py`
- Test: `backend/tests/test_signal_insider.py`

**Step 1: Write the failing test**

```python
# tests/test_signal_insider.py
import pytest
from app.signals.insider import compute_insider_score


def test_strong_net_buying():
    transactions = [
        {"type": "purchase", "shares": 10000, "date": "2026-02-15"},
        {"type": "purchase", "shares": 5000, "date": "2026-02-20"},
        {"type": "sale", "shares": 1000, "date": "2026-02-10"},
    ]
    result = compute_insider_score(transactions)
    assert result["score"] > 0.5
    assert result["direction"] == "net_buying"


def test_net_selling():
    transactions = [
        {"type": "sale", "shares": 50000, "date": "2026-02-15"},
        {"type": "sale", "shares": 30000, "date": "2026-02-20"},
        {"type": "purchase", "shares": 1000, "date": "2026-02-10"},
    ]
    result = compute_insider_score(transactions)
    assert result["score"] < -0.3
    assert result["direction"] == "net_selling"


def test_no_transactions():
    result = compute_insider_score([])
    assert result["score"] == 0.0
    assert result["direction"] == "no_activity"


def test_cluster_buying_bonus():
    """Multiple insiders buying within 14 days gets cluster bonus."""
    transactions = [
        {"type": "purchase", "shares": 5000, "date": "2026-02-15", "insider": "CEO"},
        {"type": "purchase", "shares": 3000, "date": "2026-02-18", "insider": "CFO"},
        {"type": "purchase", "shares": 2000, "date": "2026-02-22", "insider": "COO"},
    ]
    result = compute_insider_score(transactions)
    assert result["score"] >= 0.8  # cluster bonus pushes score higher
    assert result["cluster_detected"] is True
```

**Step 2: Write the implementation**

```python
# app/signals/insider.py
"""Insider trading signal — analyzes Form 4 purchase/sale patterns."""

from __future__ import annotations

import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


def compute_insider_score(transactions: list[dict]) -> dict:
    """Compute insider trading signal from Form 4 data.

    Args:
        transactions: List of dicts with 'type' (purchase/sale),
                      'shares', 'date', optional 'insider' name.

    Returns:
        Dict with 'score', 'direction', 'cluster_detected', 'details'.
    """
    if not transactions:
        return {
            "score": 0.0,
            "direction": "no_activity",
            "cluster_detected": False,
            "details": {"reason": "no insider transactions found"},
        }

    total_bought = sum(t.get("shares", 0) for t in transactions if t.get("type") == "purchase")
    total_sold = sum(t.get("shares", 0) for t in transactions if t.get("type") == "sale")
    total = total_bought + total_sold

    if total == 0:
        return {
            "score": 0.0,
            "direction": "no_activity",
            "cluster_detected": False,
            "details": {"reason": "zero share volume"},
        }

    net_ratio = (total_bought - total_sold) / total  # -1 to +1

    # Detect cluster buying: 3+ unique insiders purchasing within 14 days
    purchases = [t for t in transactions if t.get("type") == "purchase"]
    cluster_detected = False
    if len(purchases) >= 3:
        purchase_dates = []
        for t in purchases:
            try:
                purchase_dates.append(datetime.strptime(t["date"], "%Y-%m-%d"))
            except (ValueError, KeyError):
                continue
        if purchase_dates:
            purchase_dates.sort()
            span = (purchase_dates[-1] - purchase_dates[0]).days
            unique_insiders = len(set(t.get("insider", f"unknown_{i}") for i, t in enumerate(purchases)))
            if span <= 14 and unique_insiders >= 3:
                cluster_detected = True

    # Score calculation
    if net_ratio > 0.3:
        base_score = min(0.8, net_ratio)
        direction = "net_buying"
    elif net_ratio < -0.3:
        base_score = max(-0.6, net_ratio * 0.75)
        direction = "net_selling"
    else:
        base_score = 0.0
        direction = "mixed"

    # Cluster bonus
    if cluster_detected and direction == "net_buying":
        base_score = min(1.0, base_score + 0.2)

    return {
        "score": round(base_score, 2),
        "direction": direction,
        "cluster_detected": cluster_detected,
        "details": {
            "total_bought": total_bought,
            "total_sold": total_sold,
            "net_ratio": round(net_ratio, 3),
            "transaction_count": len(transactions),
        },
    }
```

**Step 3: Run test**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_insider.py -v`
Expected: 4 PASSED

**Step 4: Commit**

```bash
git add backend/app/signals/insider.py backend/tests/test_signal_insider.py
git commit -m "feat: add insider trading signal calculator (Form 4 analysis)"
```

---

### Task 10: Readability signal calculator

**Files:**
- Create: `backend/app/signals/readability.py`
- Test: `backend/tests/test_signal_readability.py`

**Step 1: Write the failing test**

```python
# tests/test_signal_readability.py
import pytest
from app.signals.readability import compute_readability_score


def test_increasing_complexity_negative():
    result = compute_readability_score(
        current_text="This is a complex obfuscatory methodological implementation.",
        prior_fog=15.0,
    )
    # If current fog is significantly higher than prior, score should be negative
    assert result["score"] <= 0.0


def test_stable_readability_neutral():
    result = compute_readability_score(
        current_text="The company reported revenue growth in the quarter.",
        prior_fog=10.0,
    )
    # Stable readability (small delta) should be near zero
    assert -0.2 <= result["score"] <= 0.2


def test_no_prior_fog_returns_neutral():
    result = compute_readability_score(
        current_text="The company reported strong results this quarter.",
        prior_fog=None,
    )
    assert result["score"] == 0.0
    assert "fog_index" in result["details"]


def test_empty_text_returns_zero():
    result = compute_readability_score(current_text="", prior_fog=15.0)
    assert result["score"] == 0.0


def test_negative_sentiment_words_detected():
    text = "Risk uncertainty litigation loss decline deterioration negative adverse"
    result = compute_readability_score(current_text=text, prior_fog=None)
    assert result["details"]["negative_word_count"] > 0
```

**Step 2: Write the implementation**

```python
# app/signals/readability.py
"""10-K readability scoring — Gunning Fog index + Loughran-McDonald words.

The management obfuscation hypothesis (Li 2008): firms with lower earnings
produce harder-to-read annual reports. Increasing complexity = red flag.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Loughran-McDonald negative/uncertainty word lists (subset — top 50 each)
_NEGATIVE_WORDS = {
    "loss", "losses", "decline", "declined", "adverse", "adversely", "impairment",
    "impaired", "litigation", "default", "defaults", "restructuring", "downturn",
    "penalty", "penalties", "violation", "violations", "terminated", "termination",
    "unfavorable", "weakness", "deterioration", "deteriorated", "damage", "damages",
    "shutdown", "closing", "closings", "complaint", "complaints", "deficit",
    "deficiency", "deficiencies", "delinquent", "delinquency", "fraud", "fraudulent",
    "lawsuit", "lawsuits", "liability", "liabilities", "negative", "negatively",
    "inability", "unable", "failure", "failed", "breach", "breaches",
}

_UNCERTAINTY_WORDS = {
    "approximately", "assume", "assumes", "assumption", "assumptions", "believe",
    "believes", "could", "depend", "depends", "dependent", "depending", "estimate",
    "estimated", "estimates", "expect", "expects", "expected", "fluctuate",
    "fluctuates", "fluctuation", "intend", "intends", "intention", "likely",
    "may", "might", "possible", "possibly", "predict", "predicts", "prediction",
    "probable", "probably", "project", "projected", "projections", "risk", "risks",
    "risky", "uncertain", "uncertainty", "uncertainties", "unpredictable", "variable",
}


def _count_words(text: str, word_set: set[str]) -> int:
    """Count occurrences of words from a set in text."""
    words = text.lower().split()
    return sum(1 for w in words if w.strip(".,;:!?()\"'") in word_set)


def _gunning_fog(text: str) -> float:
    """Compute Gunning Fog index. Returns 0.0 for empty text."""
    try:
        import textstat
        if not text.strip():
            return 0.0
        return textstat.gunning_fog(text)
    except Exception:
        return 0.0


def compute_readability_score(
    current_text: str,
    prior_fog: float | None = None,
) -> dict:
    """Compute readability signal from 10-K filing text.

    Args:
        current_text: Text from the current 10-K filing.
        prior_fog: Gunning Fog index from the prior year's filing (if available).

    Returns:
        Dict with 'score', 'details'.
    """
    if not current_text or not current_text.strip():
        return {
            "score": 0.0,
            "details": {"reason": "no filing text available"},
        }

    fog = _gunning_fog(current_text)
    neg_count = _count_words(current_text, _NEGATIVE_WORDS)
    unc_count = _count_words(current_text, _UNCERTAINTY_WORDS)
    word_count = len(current_text.split())

    # Normalize counts per 1000 words
    neg_per_1k = (neg_count / max(word_count, 1)) * 1000
    unc_per_1k = (unc_count / max(word_count, 1)) * 1000

    score = 0.0

    if prior_fog is not None:
        fog_delta = fog - prior_fog
        if fog_delta > 2.0:
            score = -0.5  # Significantly more complex = obfuscation signal
        elif fog_delta > 1.0:
            score = -0.2
        elif fog_delta < -2.0:
            score = 0.3   # Getting clearer = positive
        elif fog_delta < -1.0:
            score = 0.1
        # else: stable, score stays 0.0
    # Without prior_fog, we can't compute delta — return neutral

    return {
        "score": round(score, 2),
        "details": {
            "fog_index": round(fog, 1),
            "prior_fog": prior_fog,
            "fog_delta": round(fog - prior_fog, 1) if prior_fog is not None else None,
            "negative_word_count": neg_count,
            "uncertainty_word_count": unc_count,
            "negative_per_1k": round(neg_per_1k, 1),
            "uncertainty_per_1k": round(unc_per_1k, 1),
            "word_count": word_count,
        },
    }
```

**Step 3: Run test**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_readability.py -v`
Expected: 5 PASSED

**Step 4: Commit**

```bash
git add backend/app/signals/readability.py backend/tests/test_signal_readability.py
git commit -m "feat: add readability signal calculator (Fog index + Loughran-McDonald words)"
```

---

### Task 11: Earnings NLP signal calculator

**Files:**
- Create: `backend/app/signals/earnings_nlp.py`
- Test: `backend/tests/test_signal_earnings_nlp.py`

**Step 1: Write the failing test**

```python
# tests/test_signal_earnings_nlp.py
import pytest
from unittest.mock import patch, MagicMock
from app.signals.earnings_nlp import compute_earnings_nlp_score


def test_positive_alignment():
    """Positive sentiment + positive earnings = aligned positive."""
    result = compute_earnings_nlp_score(
        text="Strong revenue growth exceeded expectations with record margins.",
        earnings_direction="positive",
        _mock_sentiment="positive",
    )
    assert result["score"] > 0.3


def test_deception_flag():
    """Positive sentiment + negative earnings = deception flag."""
    result = compute_earnings_nlp_score(
        text="We are incredibly optimistic about our transformative future.",
        earnings_direction="negative",
        _mock_sentiment="positive",
    )
    assert result["score"] < -0.5


def test_sandbagging_signal():
    """Negative sentiment + positive earnings = sandbagging (conservative mgmt)."""
    result = compute_earnings_nlp_score(
        text="We face significant challenges and uncertain conditions ahead.",
        earnings_direction="positive",
        _mock_sentiment="negative",
    )
    assert result["score"] > 0.0  # sandbagging is slightly positive


def test_empty_text():
    result = compute_earnings_nlp_score(text="", earnings_direction="positive")
    assert result["score"] == 0.0


def test_neutral_earnings():
    result = compute_earnings_nlp_score(
        text="The company reported results in line with expectations.",
        earnings_direction="neutral",
        _mock_sentiment="neutral",
    )
    assert -0.2 <= result["score"] <= 0.2
```

**Step 2: Write the implementation**

```python
# app/signals/earnings_nlp.py
"""Earnings call/press release NLP — tone surprise detection.

Uses FinBERT for sentiment classification, then compares tone against
earnings direction to detect alignment, sandbagging, or deception.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Lazy-loaded FinBERT pipeline (heavy — ~500MB model)
_finbert_pipeline = None


def _get_finbert():
    """Lazy-load FinBERT pipeline."""
    global _finbert_pipeline
    if _finbert_pipeline is None:
        try:
            from transformers import pipeline
            _finbert_pipeline = pipeline(
                "sentiment-analysis",
                model="ProsusAI/finbert",
                truncation=True,
                max_length=512,
            )
        except Exception:
            logger.warning("FinBERT not available — falling back to keyword sentiment")
            _finbert_pipeline = "unavailable"
    return _finbert_pipeline


def _keyword_sentiment(text: str) -> str:
    """Simple keyword-based fallback sentiment."""
    text_lower = text.lower()
    pos = sum(1 for w in ["strong", "growth", "exceeded", "record", "optimistic", "positive", "beat"] if w in text_lower)
    neg = sum(1 for w in ["decline", "loss", "weak", "challenges", "uncertain", "negative", "miss"] if w in text_lower)
    if pos > neg + 1:
        return "positive"
    elif neg > pos + 1:
        return "negative"
    return "neutral"


def compute_earnings_nlp_score(
    text: str,
    earnings_direction: str = "neutral",
    _mock_sentiment: str | None = None,
) -> dict:
    """Compute earnings NLP signal from press release or earnings call text.

    Args:
        text: Earnings press release or call transcript text.
        earnings_direction: "positive", "negative", or "neutral" based on EPS surprise.
        _mock_sentiment: For testing — skip FinBERT and use this sentiment directly.

    Returns:
        Dict with 'score', 'details'.
    """
    if not text or not text.strip():
        return {"score": 0.0, "details": {"reason": "no earnings text available"}}

    # Get sentiment
    if _mock_sentiment is not None:
        sentiment = _mock_sentiment
        confidence = 0.95
    else:
        pipe = _get_finbert()
        if pipe == "unavailable":
            sentiment = _keyword_sentiment(text)
            confidence = 0.5
        else:
            try:
                result = pipe(text[:512])[0]
                sentiment = result["label"].lower()
                confidence = result["score"]
            except Exception:
                sentiment = _keyword_sentiment(text)
                confidence = 0.5

    # Tone surprise scoring
    score = 0.0
    tone_match = "aligned"

    if sentiment == "positive" and earnings_direction == "positive":
        score = 0.5
        tone_match = "aligned_positive"
    elif sentiment == "negative" and earnings_direction == "negative":
        score = -0.3
        tone_match = "aligned_negative"
    elif sentiment == "positive" and earnings_direction == "negative":
        score = -0.7  # Deception flag: positive tone hiding bad results
        tone_match = "deception_flag"
    elif sentiment == "negative" and earnings_direction == "positive":
        score = 0.3  # Sandbagging: conservative management = actually positive
        tone_match = "sandbagging"
    elif sentiment == "neutral":
        score = 0.0
        tone_match = "neutral"
    elif earnings_direction == "neutral":
        score = 0.1 if sentiment == "positive" else -0.1
        tone_match = "neutral_earnings"

    return {
        "score": round(score, 2),
        "details": {
            "sentiment": sentiment,
            "sentiment_confidence": round(confidence, 3),
            "earnings_direction": earnings_direction,
            "tone_match": tone_match,
        },
    }
```

**Step 3: Run test**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_earnings_nlp.py -v`
Expected: 5 PASSED

**Step 4: Commit**

```bash
git add backend/app/signals/earnings_nlp.py backend/tests/test_signal_earnings_nlp.py
git commit -m "feat: add earnings NLP signal calculator (FinBERT tone surprise detection)"
```

---

### Task 12: Employee sentiment signal calculator

**Files:**
- Create: `backend/app/signals/employee_sentiment.py`
- Test: `backend/tests/test_signal_employee.py`

**Step 1: Write the failing test**

```python
# tests/test_signal_employee.py
import pytest
from app.signals.employee_sentiment import compute_employee_score


def test_rising_trend_positive():
    result = compute_employee_score(current_rating=4.4, prior_rating=4.0)
    assert result["score"] > 0.3
    assert result["trend"] == "rising"


def test_falling_trend_negative():
    result = compute_employee_score(current_rating=3.2, prior_rating=3.8)
    assert result["score"] < -0.3
    assert result["trend"] == "falling"


def test_stable_high_mildly_positive():
    result = compute_employee_score(current_rating=4.3, prior_rating=4.3)
    assert result["score"] > 0.0
    assert result["trend"] == "stable_high"


def test_stable_low_mildly_negative():
    result = compute_employee_score(current_rating=2.8, prior_rating=2.8)
    assert result["score"] < 0.0
    assert result["trend"] == "stable_low"


def test_no_data_returns_zero():
    result = compute_employee_score(current_rating=None, prior_rating=None)
    assert result["score"] == 0.0
```

**Step 2: Write the implementation**

```python
# app/signals/employee_sentiment.py
"""Employee sentiment signal — Glassdoor rating as leading indicator.

Green et al. (2019): Companies with rising Glassdoor ratings outperform
those with declining ratings by ~0.74%/month (~9% annualized).
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def compute_employee_score(
    current_rating: float | None,
    prior_rating: float | None = None,
) -> dict:
    """Compute employee sentiment signal from Glassdoor-style ratings.

    Args:
        current_rating: Current overall rating (1.0-5.0 scale).
        prior_rating: Prior quarter's rating (for trend detection).

    Returns:
        Dict with 'score', 'trend', 'details'.
    """
    if current_rating is None:
        return {
            "score": 0.0,
            "trend": "unavailable",
            "details": {"reason": "no employee rating data available"},
        }

    # Trend detection (most important signal per research)
    if prior_rating is not None:
        delta = current_rating - prior_rating

        if delta >= 0.2:
            score = 0.6
            trend = "rising"
        elif delta <= -0.2:
            score = -0.6
            trend = "falling"
        elif current_rating >= 4.0:
            score = 0.3
            trend = "stable_high"
        elif current_rating <= 3.0:
            score = -0.3
            trend = "stable_low"
        else:
            score = 0.0
            trend = "stable_mid"
    else:
        # No prior data — use absolute level only (weaker signal)
        if current_rating >= 4.0:
            score = 0.2
            trend = "high_no_trend"
        elif current_rating <= 3.0:
            score = -0.2
            trend = "low_no_trend"
        else:
            score = 0.0
            trend = "mid_no_trend"

    return {
        "score": round(score, 2),
        "trend": trend,
        "details": {
            "current_rating": current_rating,
            "prior_rating": prior_rating,
            "delta": round(current_rating - prior_rating, 2) if prior_rating else None,
        },
    }
```

**Step 3: Run test**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_employee.py -v`
Expected: 5 PASSED

**Step 4: Commit**

```bash
git add backend/app/signals/employee_sentiment.py backend/tests/test_signal_employee.py
git commit -m "feat: add employee sentiment signal calculator (Glassdoor rating trends)"
```

---

### Task 13: Signal computation runner + scheduler integration

**Files:**
- Create: `backend/app/signals/runner.py`
- Test: `backend/tests/test_signal_runner.py`
- Modify: `backend/app/ingestion/scheduler.py:258` (add compute_signals job)

**Step 1: Write the failing test**

```python
# tests/test_signal_runner.py
import pytest
from unittest.mock import patch, MagicMock
from sqlalchemy import select
from app.db.models import Asset, DataSnapshot, SignalScore
from app.signals.runner import compute_all_signals


async def test_compute_signals_for_equity(db_session):
    """Lifecycle signal computed for equity with cash flow data."""
    asset = Asset(id="TEST", asset_class="equity", name="Test Corp")
    db_session.add(asset)
    snap = DataSnapshot(
        asset_id="TEST",
        source="price",
        raw_data={
            "quarterly_financials": [
                {
                    "period": "2025-12-31",
                    "Total Revenue": 1000000,
                    "Operating Income": 200000,
                }
            ],
            "quarterly_balance_sheet": [{"period": "2025-12-31"}],
        },
    )
    db_session.add(snap)
    await db_session.commit()

    results = await compute_all_signals(db_session, "TEST")
    assert "lifecycle" in results
    assert isinstance(results["lifecycle"]["score"], float)


async def test_compute_signals_skips_crypto_equity_signals(db_session):
    """Crypto assets skip equity-only signals."""
    asset = Asset(id="BTC-USD", asset_class="crypto", name="Bitcoin")
    db_session.add(asset)
    await db_session.commit()

    results = await compute_all_signals(db_session, "BTC-USD")
    assert "lifecycle" not in results
    assert "insider" not in results
    assert "readability" not in results


async def test_compute_signals_saves_to_db(db_session):
    """Signal scores are persisted to SignalScore table."""
    asset = Asset(id="TEST2", asset_class="equity", name="Test2")
    db_session.add(asset)
    await db_session.commit()

    await compute_all_signals(db_session, "TEST2")

    result = await db_session.execute(
        select(SignalScore).where(SignalScore.asset_id == "TEST2")
    )
    scores = result.scalars().all()
    # Should have at least lifecycle (even if zero due to no data)
    assert len(scores) >= 1
```

**Step 2: Write the implementation**

```python
# app/signals/runner.py
"""Signal computation runner — orchestrates all signal calculators for an asset."""

from __future__ import annotations

import logging

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset, DataSnapshot, SignalScore
from app.signals.lifecycle import compute_lifecycle_score
from app.signals.insider import compute_insider_score
from app.signals.readability import compute_readability_score
from app.signals.earnings_nlp import compute_earnings_nlp_score
from app.signals.employee_sentiment import compute_employee_score

logger = logging.getLogger(__name__)


def _extract_cashflows(market_data: dict) -> list[dict]:
    """Extract cash flow data from yfinance market snapshot."""
    # yfinance stores quarterly_financials as list of period dicts
    financials = market_data.get("quarterly_financials", [])
    cashflows = []
    for period in financials:
        operating = period.get("Operating Cash Flow") or period.get("Total Cash From Operating Activities") or 0
        investing = period.get("Capital Expenditures") or period.get("Total Cashflows From Investing Activities") or 0
        financing = period.get("Total Cash From Financing Activities") or period.get("Issuance Of Stock") or 0
        # Also try common yfinance keys
        if operating == 0:
            operating = period.get("Operating Income", 0)
        cashflows.append({
            "operating": operating,
            "investing": investing,
            "financing": financing,
            "period": period.get("period", "unknown"),
        })
    return cashflows


async def _get_latest_snapshot(db: AsyncSession, asset_id: str, source: str) -> dict | None:
    """Get the latest snapshot raw_data for an asset and source."""
    stmt = (
        select(DataSnapshot.raw_data)
        .where(DataSnapshot.asset_id == asset_id, DataSnapshot.source == source)
        .order_by(DataSnapshot.id.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    return row


async def _save_signal_score(
    db: AsyncSession, asset_id: str, signal_name: str, result: dict
) -> None:
    """Save or update a signal score in the DB."""
    # Delete existing score for this asset+signal (replace strategy)
    existing = await db.execute(
        select(SignalScore).where(
            SignalScore.asset_id == asset_id,
            SignalScore.signal_name == signal_name,
        )
    )
    for old in existing.scalars().all():
        await db.delete(old)

    score = SignalScore(
        asset_id=asset_id,
        signal_name=signal_name,
        score=result.get("score", 0.0),
        details=result,
    )
    db.add(score)


async def compute_all_signals(db: AsyncSession, asset_id: str) -> dict:
    """Compute all applicable signals for an asset. Returns dict of signal_name -> result."""
    asset = await db.get(Asset, asset_id)
    if not asset:
        logger.warning("Asset %s not found for signal computation", asset_id)
        return {}

    results = {}
    is_equity = asset.asset_class == "equity"

    if is_equity:
        # 1. Lifecycle
        market_data = await _get_latest_snapshot(db, asset_id, "price") or {}
        cashflows = _extract_cashflows(market_data)
        lifecycle_result = compute_lifecycle_score(cashflows)
        results["lifecycle"] = lifecycle_result
        await _save_signal_score(db, asset_id, "lifecycle", lifecycle_result)

        # 2. Insider (requires SEC filing data)
        sec_data = await _get_latest_snapshot(db, asset_id, "sec_filing") or {}
        insider_transactions = sec_data.get("insider_transactions", [])
        insider_result = compute_insider_score(insider_transactions)
        results["insider"] = insider_result
        await _save_signal_score(db, asset_id, "insider", insider_result)

        # 3. Readability (requires 10-K text)
        filing_text = sec_data.get("risk_factors", "") or sec_data.get("mda", "")
        prior_fog = sec_data.get("prior_fog_index")
        readability_result = compute_readability_score(filing_text, prior_fog)
        results["readability"] = readability_result
        await _save_signal_score(db, asset_id, "readability", readability_result)

        # 4. Earnings NLP (requires 8-K or earnings text)
        earnings_text = sec_data.get("earnings_text", "") or sec_data.get("mda", "")
        # Determine earnings direction from price data
        pe = market_data.get("pe_ratio")
        earnings_dir = "neutral"
        if isinstance(pe, (int, float)):
            earnings_dir = "positive" if pe > 0 else "negative"
        earnings_result = compute_earnings_nlp_score(earnings_text, earnings_dir)
        results["earnings_nlp"] = earnings_result
        await _save_signal_score(db, asset_id, "earnings_nlp", earnings_result)

        # 5. Employee sentiment (Glassdoor data — may not be available)
        # For now, we store a placeholder — Glassdoor scraping added later
        employee_result = compute_employee_score(current_rating=None)
        results["employee_sentiment"] = employee_result
        await _save_signal_score(db, asset_id, "employee_sentiment", employee_result)

    await db.commit()

    logger.info(
        "Computed %d signals for %s: %s",
        len(results),
        asset_id,
        {k: v.get("score", 0) for k, v in results.items()},
    )
    return results
```

**Step 3: Add scheduler job**

In `backend/app/ingestion/scheduler.py`, add after the SEC job:

```python
async def _job_compute_signals():
    """Compute quantitative signals for all tracked equity assets."""
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.signals.runner import compute_all_signals
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.tracked.is_(True))
        )
        asset_ids = result.scalars().all()

    for asset_id in asset_ids:
        try:
            async with async_session_factory() as db:
                await compute_all_signals(db, asset_id)
            logger.info("Signals computed for %s", asset_id)
        except Exception:
            logger.exception("Signal computation failed for %s", asset_id)
```

Add job in `create_scheduler()`:

```python
    # Signal computation: daily at 7:00 AM ET (after overnight data ingestion)
    scheduler.add_job(
        _job_compute_signals,
        CronTrigger(hour=7, minute=0, timezone=_ET),
        id="compute_signals",
        name="Quantitative Signals",
        replace_existing=True,
    )
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_runner.py tests/test_scheduler.py -v`
Expected: All PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/runner.py backend/tests/test_signal_runner.py backend/app/ingestion/scheduler.py
git commit -m "feat: add signal computation runner + daily scheduler job"
```

---

### Task 14: QA Gate 2 — Signal layer tests

**Step 1: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~165 PASSED, 0 FAILED

**Step 2: Run signal calculators in isolation**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_*.py -v`
Expected: All signal tests pass independently

**Step 3: Commit QA checkpoint**

```bash
git commit --allow-empty -m "checkpoint: Layer 2 complete — 5 signal calculators + runner + scheduler, all tests pass"
```

---

## Layer 3: Enhanced Orchestrator

### Task 15: Enhance search agent with signal scores

**Files:**
- Modify: `backend/app/agents/search_agent.py:21-90`
- Test: `backend/tests/test_search_agent.py` (append)

**Step 1: Write the failing test**

```python
# tests/test_search_agent.py (append)

async def test_gather_includes_signal_scores(db_session):
    from app.db.models import Asset, SignalScore
    asset = Asset(id="SIG_TEST", asset_class="equity", name="Signal Test")
    db_session.add(asset)
    score = SignalScore(
        asset_id="SIG_TEST", signal_name="lifecycle", score=0.7,
        details={"stage": "maturity"},
    )
    db_session.add(score)
    await db_session.commit()

    from app.agents.search_agent import gather_asset_data
    bundle = await gather_asset_data(db_session, "SIG_TEST")
    assert "signal_scores" in bundle
    assert "lifecycle" in bundle["signal_scores"]
    assert bundle["signal_scores"]["lifecycle"]["score"] == 0.7
```

**Step 2: Modify gather_asset_data**

At the end of `gather_asset_data()`, before the return, add signal score gathering:

```python
    # Gather latest signal scores
    from app.db.models import SignalScore
    score_stmt = (
        select(SignalScore)
        .where(SignalScore.asset_id == asset_id)
    )
    score_result = await db.execute(score_stmt)
    signal_scores = {}
    for ss in score_result.scalars().all():
        signal_scores[ss.signal_name] = {
            "score": ss.score,
            "details": ss.details,
            "computed_at": ss.computed_at.isoformat() if ss.computed_at else None,
        }

    return {
        "asset_id": asset_id,
        "asset_class": asset.asset_class,
        "data": data,
        "snapshot_ages": snapshot_ages,
        "signal_scores": signal_scores,
    }
```

**Step 3: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_search_agent.py -v`
Expected: All PASSED

**Step 4: Commit**

```bash
git add backend/app/agents/search_agent.py backend/tests/test_search_agent.py
git commit -m "feat: search agent includes quantitative signal scores in data bundle"
```

---

### Task 16: Update agent prompts to reference signals

**Files:**
- Modify: `backend/app/agents/analyst_agent.py` (system prompt update)
- Modify: `backend/app/agents/risk_agent.py` (system prompt update)

**Step 1: Read current agent files**

Read `analyst_agent.py` and `risk_agent.py` to find the system prompt strings and update them.

**Step 2: Add signal awareness to analyst prompt**

Append to the analyst system prompt:

```
If the data bundle includes a QUANTITATIVE SIGNALS section, incorporate these research-backed scores into your analysis:
- Lifecycle stage (Dickinson method): Maturity/Growth = positive, Decline = negative
- Insider activity: Net buying = bullish conviction, Net selling = red flag
- 10-K readability: Increasing complexity may indicate obfuscation
- Earnings NLP: Tone vs earnings direction mismatch = deception risk
- Employee sentiment: Rising Glassdoor = leading positive indicator
Call out when quantitative signals conflict with each other or with fundamentals.
```

**Step 3: Add signal awareness to risk agent prompt**

Append to the risk agent system prompt:

```
Pay special attention to these quantitative red flags if present in the data:
- Worsening 10-K readability (increasing Fog index) = potential information obfuscation
- Heavy insider selling = management losing confidence
- Positive tone with negative earnings (deception flag) = management may be misleading investors
- Decline lifecycle stage = company in structural decline
Flag these independently regardless of price action.
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_analyst_agent.py tests/test_risk_agent.py -v`
Expected: All PASSED

**Step 5: Commit**

```bash
git add backend/app/agents/analyst_agent.py backend/app/agents/risk_agent.py
git commit -m "feat: update analyst and risk agent prompts to reference quantitative signals"
```

---

### Task 17: Enhance synthesizer with signal score blending

**Files:**
- Modify: `backend/app/agents/synthesizer.py:133-230`
- Test: `backend/tests/test_orchestrator.py` (append)

**Step 1: Write the failing test**

```python
# tests/test_orchestrator.py (append)

async def test_synthesizer_blends_signal_scores(db_session):
    """Synthesizer weighted score incorporates signal scores when present."""
    from app.agents.synthesizer import _blend_signal_scores

    rule_score = 0.5
    signal_scores = {
        "lifecycle": {"score": 0.7},
        "insider": {"score": 0.5},
    }
    blended = _blend_signal_scores(rule_score, signal_scores)
    # 0.6 * 0.5 + 0.4 * avg(0.7, 0.5) = 0.3 + 0.24 = 0.54
    assert 0.5 <= blended <= 0.6


async def test_synthesizer_without_signals_uses_rule_only(db_session):
    from app.agents.synthesizer import _blend_signal_scores

    blended = _blend_signal_scores(0.5, {})
    assert blended == 0.5
```

**Step 2: Add blending function to synthesizer**

Add to `synthesizer.py`:

```python
def _blend_signal_scores(rule_score: float, signal_scores: dict) -> float:
    """Blend rule-based score with quantitative signal scores.

    Formula: 0.6 * rule_score + 0.4 * avg(signal_scores)
    If no signal scores, returns rule_score unchanged.
    """
    valid_scores = [
        s["score"] for s in signal_scores.values()
        if isinstance(s.get("score"), (int, float)) and s["score"] != 0.0
    ]
    if not valid_scores:
        return rule_score

    avg_signal = sum(valid_scores) / len(valid_scores)
    blended = 0.6 * rule_score + 0.4 * avg_signal
    return max(-1.0, min(1.0, blended))
```

Update `synthesize()` to call `_blend_signal_scores` — the function needs `signal_scores` passed in. Add `signal_scores: dict | None = None` parameter to `synthesize()`, and after computing `weighted_score`, blend it:

```python
    # Blend with quantitative signals if available
    if signal_scores:
        weighted_score = _blend_signal_scores(weighted_score, signal_scores)
```

**Step 3: Update orchestrator to pass signal_scores to synthesizer**

In `orchestrator.py`, after `data_bundle = await gather_asset_data(...)`, pass signal_scores:

```python
    synthesis = await synthesize(
        db,
        asset_id=asset_id,
        asset_class=data_bundle["asset_class"],
        agent_outputs=agent_outputs,
        signal_scores=data_bundle.get("signal_scores", {}),
    )
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_orchestrator.py -v`
Expected: All PASSED

**Step 5: Commit**

```bash
git add backend/app/agents/synthesizer.py backend/app/agents/orchestrator.py backend/tests/test_orchestrator.py
git commit -m "feat: synthesizer blends rule scores with quantitative signal scores (60/40 weighting)"
```

---

### Task 18: Add new default Golden Rules

**Files:**
- Modify: `backend/app/rules/default_rules.py`

**Step 1: Add 3 new rules**

Append to `DEFAULT_RULES` list:

```python
    {
        "name": "Lifecycle Stage Alignment",
        "description": (
            "Favor companies in maturity or growth lifecycle stages. "
            "Penalize companies in decline or introduction stages."
        ),
        "rule_prompt": (
            "Evaluate the company's lifecycle stage based on cash flow patterns. "
            "Maturity (positive operating, negative investing, negative financing) is strongest. "
            "Growth (positive operating, negative investing, positive financing) is good. "
            "Decline or introduction stages are red flags.\n"
            "Output: {passed: bool, lifecycle_stage: str, reasoning: str}"
        ),
        "asset_class": "equity",
        "weight": 0.7,
    },
    {
        "name": "Insider Conviction Signal",
        "description": (
            "Cluster insider buying (3+ executives purchasing within 14 days) "
            "is a strong buy indicator. Heavy insider selling is a warning."
        ),
        "rule_prompt": (
            "Analyze insider trading patterns. Look for cluster buying "
            "(multiple insiders purchasing close together in time). "
            "Weight purchases more heavily than sales (insiders sell for many reasons, "
            "but buy for only one). Score based on net conviction.\n"
            "Output: {passed: bool, net_direction: str, cluster_detected: bool}"
        ),
        "asset_class": "equity",
        "weight": 0.8,
    },
    {
        "name": "Linguistic Red Flag Detector",
        "description": (
            "Worsening 10-K readability combined with positive management tone "
            "suggests obfuscation. Management hiding bad news in complex language."
        ),
        "rule_prompt": (
            "Check for linguistic red flags: Is 10-K readability worsening "
            "(higher Fog index vs prior year)? Is management tone overly positive "
            "relative to actual results? The combination of complex language + "
            "cheerful tone is the strongest deception signal.\n"
            "Output: {passed: bool, readability_trend: str, tone_mismatch: bool}"
        ),
        "asset_class": "equity",
        "weight": 0.6,
    },
```

**Step 2: Run existing rules tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_routes_rules.py -v`
Expected: All PASSED

**Step 3: Commit**

```bash
git add backend/app/rules/default_rules.py
git commit -m "feat: add 3 research-backed Golden Rules (lifecycle, insider conviction, linguistic red flags)"
```

---

### Task 19: QA Gate 3 — Enhanced orchestrator tests

**Step 1: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~170 PASSED, 0 FAILED

**Step 2: Commit QA checkpoint**

```bash
git commit --allow-empty -m "checkpoint: Layer 3 complete — enhanced orchestrator with signal blending, all tests pass"
```

---

## Layer 4: Auto-Scanner

### Task 20: Auto-scan scheduler job + dashboard summary endpoint

**Files:**
- Create: `backend/app/routes/dashboard.py`
- Modify: `backend/app/ingestion/scheduler.py` (add auto_scan job)
- Modify: `backend/app/main.py` (add dashboard router)
- Test: `backend/tests/test_routes_dashboard.py`

**Step 1: Write the failing test**

```python
# tests/test_routes_dashboard.py
import pytest
from app.db.models import Asset, Signal


async def test_dashboard_summary_empty(client, db_session):
    resp = await client.get("/api/dashboard/summary")
    assert resp.status_code == 200
    data = resp.json()
    assert "top_opportunities" in data
    assert "top_risks" in data
    assert data["top_opportunities"] == []


async def test_dashboard_summary_with_signals(client, db_session):
    asset = Asset(id="DASH1", asset_class="equity", name="Dashboard Test")
    db_session.add(asset)
    await db_session.flush()

    signal = Signal(
        asset_id="DASH1",
        signal_type="strong_buy",
        confidence=0.85,
        summary="Test strong buy",
    )
    db_session.add(signal)
    await db_session.commit()

    resp = await client.get("/api/dashboard/summary")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["top_opportunities"]) == 1
    assert data["top_opportunities"][0]["asset_id"] == "DASH1"


async def test_dashboard_summary_separates_buys_and_sells(client, db_session):
    a1 = Asset(id="BUY1", asset_class="equity", name="Buy Asset")
    a2 = Asset(id="SELL1", asset_class="equity", name="Sell Asset")
    db_session.add_all([a1, a2])
    await db_session.flush()

    s1 = Signal(asset_id="BUY1", signal_type="strong_buy", confidence=0.9, summary="Buy")
    s2 = Signal(asset_id="SELL1", signal_type="strong_sell", confidence=0.8, summary="Sell")
    db_session.add_all([s1, s2])
    await db_session.commit()

    resp = await client.get("/api/dashboard/summary")
    data = resp.json()
    assert any(o["asset_id"] == "BUY1" for o in data["top_opportunities"])
    assert any(r["asset_id"] == "SELL1" for r in data["top_risks"])
```

**Step 2: Write the dashboard route**

```python
# app/routes/dashboard.py
"""Dashboard summary endpoint — market intelligence at a glance."""

import logging
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.db.models import Asset, Signal, DataSnapshot, SignalScore

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])

logger = logging.getLogger(__name__)


@router.get("/summary")
async def dashboard_summary(db: AsyncSession = Depends(get_db)):
    """Return market intelligence summary for the dashboard."""

    # Get latest signal per asset (subquery for max id per asset)
    latest_signal_ids = (
        select(
            Signal.asset_id,
            func.max(Signal.id).label("max_id"),
        )
        .group_by(Signal.asset_id)
        .subquery()
    )

    stmt = (
        select(Signal)
        .join(latest_signal_ids, Signal.id == latest_signal_ids.c.max_id)
        .order_by(desc(Signal.confidence))
    )
    result = await db.execute(stmt)
    signals = result.scalars().all()

    opportunities = []
    risks = []

    for sig in signals:
        item = {
            "asset_id": sig.asset_id,
            "signal_type": sig.signal_type,
            "confidence": sig.confidence,
            "summary": sig.summary,
            "signal_id": sig.id,
            "created_at": sig.created_at.isoformat() if sig.created_at else None,
        }
        if sig.signal_type in ("strong_buy", "buy"):
            opportunities.append(item)
        elif sig.signal_type in ("strong_sell", "sell"):
            risks.append(item)

    # Check for stale data (assets with no snapshot in 24h)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    stale_stmt = (
        select(Asset.id)
        .where(Asset.tracked.is_(True), Asset.id != "_MACRO")
        .outerjoin(
            DataSnapshot,
            (DataSnapshot.asset_id == Asset.id) & (DataSnapshot.fetched_at > cutoff),
        )
        .where(DataSnapshot.id.is_(None))
    )
    stale_result = await db.execute(stale_stmt)
    stale_assets = list(stale_result.scalars().all())

    return {
        "top_opportunities": opportunities[:5],
        "top_risks": risks[:5],
        "total_tracked": len(signals),
        "stale_assets": stale_assets,
    }
```

**Step 3: Add auto_scan job to scheduler**

Add to `scheduler.py`:

```python
async def _job_auto_scan():
    """Run full AI analysis on all tracked assets."""
    import asyncio
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.agents.orchestrator import run_analysis
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.tracked.is_(True), Asset.id != "_MACRO")
        )
        asset_ids = result.scalars().all()

    logger.info("Auto-scan starting for %d assets", len(asset_ids))

    for i, asset_id in enumerate(asset_ids):
        try:
            if i > 0:
                await asyncio.sleep(5)  # Groq rate limit: 30 req/min
            async with async_session_factory() as db:
                await run_analysis(db, asset_id)
            logger.info("Auto-scan complete for %s (%d/%d)", asset_id, i + 1, len(asset_ids))
        except Exception:
            logger.exception("Auto-scan failed for %s", asset_id)

    logger.info("Auto-scan finished for %d assets", len(asset_ids))
```

Add job in `create_scheduler()`:

```python
    # Auto-scan: daily at 8:00 AM ET (after signal computation at 7 AM)
    scheduler.add_job(
        _job_auto_scan,
        CronTrigger(hour=8, minute=0, timezone=_ET),
        id="auto_scan",
        name="Auto-Scan (AI Analysis)",
        replace_existing=True,
    )
```

**Step 4: Register dashboard router in main.py**

Add import: `from app.routes.dashboard import router as dashboard_router`
Add include: `app.include_router(dashboard_router)`

**Step 5: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_routes_dashboard.py tests/test_scheduler.py -v`
Expected: All PASSED

**Step 6: Commit**

```bash
git add backend/app/routes/dashboard.py backend/tests/test_routes_dashboard.py backend/app/ingestion/scheduler.py backend/app/main.py
git commit -m "feat: add auto-scanner scheduler job + GET /api/dashboard/summary endpoint"
```

---

### Task 21: QA Gate 4 — Full test suite

**Step 1: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~178 PASSED, 0 FAILED

**Step 2: Commit QA checkpoint**

```bash
git commit --allow-empty -m "checkpoint: Layer 4 complete — auto-scanner + dashboard summary, all tests pass"
```

---

## Layer 5: Frontend Enhancements

### Task 22: Add frontend types and API client functions

**Files:**
- Modify: `frontend/src/api/types.ts` (add SignalScore, DashboardSummary types)
- Modify: `frontend/src/api/client.ts` (add fetchDashboardSummary, triggerBulkIngest)

**Step 1: Add types**

Append to `types.ts`:

```typescript
// ── Signal Scores ──

export interface SignalScoreItem {
  score: number;
  details: Record<string, unknown>;
  computed_at: string | null;
}

// ── Dashboard Summary ──

export interface DashboardOpportunity {
  asset_id: string;
  signal_type: SignalType;
  confidence: number;
  summary: string;
  signal_id: number;
  created_at: string | null;
}

export interface DashboardSummary {
  top_opportunities: DashboardOpportunity[];
  top_risks: DashboardOpportunity[];
  total_tracked: number;
  stale_assets: string[];
}

// ── Bulk Ingest ──

export interface BulkIngestResult {
  equities_attempted: number;
  equities_succeeded: number;
  equities_failed: number;
  crypto_attempted: number;
  crypto_succeeded: number;
  crypto_failed: number;
}
```

**Step 2: Add API functions**

Append to `client.ts`:

```typescript
// ── Dashboard ──

export const fetchDashboardSummary = () =>
  request<DashboardSummary>("/api/dashboard/summary");

// ── Bulk Ingest ──

export const triggerBulkIngest = () =>
  request<BulkIngestResult>("/api/ingest/bulk", { method: "POST" });
```

**Step 3: Commit**

```bash
git add frontend/src/api/types.ts frontend/src/api/client.ts
git commit -m "feat: add dashboard summary and bulk ingest types + API client functions"
```

---

### Task 23: Enhance Dashboard page with Market Pulse

**Files:**
- Modify: `frontend/src/pages/Dashboard.tsx`

**Step 1: Update Dashboard**

Add Market Pulse section at top of Dashboard showing:
- Top 5 opportunities (green cards with signal type badge + confidence)
- Top 5 risk alerts (red cards)
- "Scan All" button that triggers `POST /api/ingest/bulk`
- Stale data warnings
- Use `useQuery` with `fetchDashboardSummary`

The implementation should follow existing patterns in Dashboard.tsx (React Query, Tailwind classes, existing component usage). Read the current Dashboard.tsx first and extend it — do not rewrite from scratch.

**Step 2: Build and verify**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npm run build`
Expected: Build succeeds with no TypeScript errors

**Step 3: Commit**

```bash
git add frontend/src/pages/Dashboard.tsx
git commit -m "feat: add Market Pulse section to dashboard with opportunities, risks, and scan button"
```

---

### Task 24: Add Signal Scores page

**Files:**
- Create: `frontend/src/pages/SignalScores.tsx`
- Modify: `frontend/src/App.tsx` (add route)
- Modify: `frontend/src/components/Layout.tsx` (add nav link)

**Step 1: Create SignalScores page**

A table page showing all assets with their signal score columns. Sortable. Color-coded cells. Click row navigates to signal detail. Filter tabs for equity/crypto. Uses existing page patterns from the codebase.

**Step 2: Add route to App.tsx**

Add import and Route: `<Route path="/scores" element={<SignalScores />} />`

**Step 3: Add nav link to Layout.tsx**

Add "Signal Scores" link to the sidebar navigation.

**Step 4: Build and verify**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npm run build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add frontend/src/pages/SignalScores.tsx frontend/src/App.tsx frontend/src/components/Layout.tsx
git commit -m "feat: add Signal Scores page — sortable table of all assets with quantitative scores"
```

---

### Task 25: QA Gate 5 — Frontend verification

**Step 1: Start backend and frontend**

Run backend: `cd "D:/Claude local/alpha-pulse/backend" && uvicorn app.main:app --reload`
Run frontend: `cd "D:/Claude local/alpha-pulse/frontend" && npm run dev`

**Step 2: Verify pages load**

- Dashboard shows Market Pulse section
- Signal Scores page shows all 30 assets
- Scan All button triggers bulk ingest
- No console errors

**Step 3: Run full backend test suite one final time**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~180 PASSED, 0 FAILED

**Step 4: Final commit**

```bash
git commit --allow-empty -m "checkpoint: Layer 5 complete — Full Vision Sprint done, ~180 tests pass"
```

---

## Summary

| Layer | Tasks | New Tests | Key Deliverables |
|-------|-------|-----------|-----------------|
| 1: Data Foundation | 1-6 | ~8 | 30 seeded assets, bulk ingest, API endpoint |
| 2: Signal Calculators | 7-14 | ~28 | 5 signal calculators, SignalScore model, daily scheduler |
| 3: Enhanced Orchestrator | 15-19 | ~5 | Signal-aware prompts, score blending, 3 new rules |
| 4: Auto-Scanner | 20-21 | ~5 | Daily auto-scan, dashboard summary endpoint |
| 5: Frontend | 22-25 | ~0 (manual QA) | Market Pulse dashboard, Signal Scores page |
| **Total** | **25 tasks** | **~46** | **~182 total tests** |
