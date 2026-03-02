# Quantitative Edge Sprint — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add asset search UI, manual portfolio management, 4 new quantitative signal calculators (momentum/value/quality/post-earnings-drift), Kelly Criterion sizing, regime detection, and chaos metrics — turning Alpha Pulse from a demo into a research-grade quant platform.

**Architecture:** Extend the existing pure-function signal calculator pattern (`signals/*.py`) for new quant signals. Each calculator is a stateless function: data in, `{score, details}` out. New frontend components follow existing React Query + Tailwind patterns. All new signals wire into the existing `runner.py` orchestrator.

**Tech Stack:** Python 3.10+, FastAPI, SQLAlchemy async, yfinance, numpy, scipy (for LPPL/Hurst), React 18, TanStack Query, TailwindCSS

---

## Layer 1: UX Gaps (Frontend + Small Backend)

### Task 1: Add Asset Search UI to Dashboard

**Files:**
- Modify: `frontend/src/pages/Dashboard.tsx`
- Modify: `frontend/src/api/client.ts`
- Modify: `frontend/src/api/types.ts`

**Step 1: Add `validateTicker` API function**

Append to `frontend/src/api/client.ts`:

```typescript
export const validateTicker = (ticker: string) =>
  request<{ valid: boolean; name?: string; asset_class?: string }>(
    `/api/assets/validate/${ticker}`
  );
```

**Step 2: Add backend validation endpoint**

Create validation route in `backend/app/routes/assets.py`. Add before the existing routes:

```python
@router.get("/validate/{ticker}")
async def validate_ticker(ticker: str):
    """Check if a ticker exists on yfinance before adding."""
    import yfinance as yf
    import asyncio

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
```

**Step 3: Write test for validation endpoint**

Create `backend/tests/test_validate_ticker.py`:

```python
import pytest
from unittest.mock import patch, MagicMock


@pytest.mark.asyncio
async def test_validate_valid_ticker(client):
    mock_info = {"shortName": "Apple Inc.", "quoteType": "EQUITY"}
    with patch("app.routes.assets.yf") as mock_yf:
        mock_ticker = MagicMock()
        mock_ticker.info = mock_info
        mock_yf.Ticker.return_value = mock_ticker
        resp = await client.get("/api/assets/validate/AAPL")
    assert resp.status_code == 200
    data = resp.json()
    assert data["valid"] is True
    assert data["name"] == "Apple Inc."
    assert data["asset_class"] == "equity"


@pytest.mark.asyncio
async def test_validate_invalid_ticker(client):
    with patch("app.routes.assets.yf") as mock_yf:
        mock_ticker = MagicMock()
        mock_ticker.info = {}
        mock_yf.Ticker.return_value = mock_ticker
        resp = await client.get("/api/assets/validate/ZZZZZ123")
    assert resp.status_code == 200
    assert resp.json()["valid"] is False


@pytest.mark.asyncio
async def test_validate_crypto_ticker(client):
    mock_info = {"shortName": "Bitcoin USD", "quoteType": "CRYPTOCURRENCY"}
    with patch("app.routes.assets.yf") as mock_yf:
        mock_ticker = MagicMock()
        mock_ticker.info = mock_info
        mock_yf.Ticker.return_value = mock_ticker
        resp = await client.get("/api/assets/validate/BTC-USD")
    assert resp.status_code == 200
    data = resp.json()
    assert data["valid"] is True
    assert data["asset_class"] == "crypto"
```

**Step 4: Run backend tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_validate_ticker.py -v`
Expected: 3 PASSED

**Step 5: Add search component to Dashboard**

In `Dashboard.tsx`, add an "Add Asset" search bar above the Tracked Assets section. The component should:
- Text input with "Search ticker..." placeholder
- On enter/click: call `validateTicker(ticker)`
- If valid: show name + asset_class, confirm button calls `createAsset({id: ticker, asset_class, name})`
- If invalid: show "Ticker not found" error
- On success: invalidate assets query, show success toast
- Use existing `createAsset` from client.ts

```typescript
// Add state inside Dashboard component:
const [searchTicker, setSearchTicker] = useState("");
const [searchResult, setSearchResult] = useState<{valid: boolean; name?: string; asset_class?: string} | null>(null);
const [searchError, setSearchError] = useState("");

const searchMutation = useMutation({
  mutationFn: (ticker: string) => validateTicker(ticker),
  onSuccess: (data) => {
    setSearchResult(data);
    setSearchError(data.valid ? "" : "Ticker not found on Yahoo Finance");
  },
  onError: () => setSearchError("Search failed"),
});

const addAssetMutation = useMutation({
  mutationFn: (data: { id: string; asset_class: string; name: string }) =>
    createAsset({ id: data.id, asset_class: data.asset_class as any, name: data.name }),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ["assets"] });
    setSearchTicker("");
    setSearchResult(null);
  },
});
```

Add `import { useState } from "react"` and `import { validateTicker } from "../api/client"` at top.

Add JSX above the "Tracked Assets" section:

```tsx
{/* Add Asset */}
<div className="card">
  <h2 className="mb-3 text-lg font-semibold text-white">Add Asset</h2>
  <div className="flex gap-2">
    <input
      type="text"
      value={searchTicker}
      onChange={(e) => setSearchTicker(e.target.value.toUpperCase())}
      onKeyDown={(e) => e.key === "Enter" && searchTicker && searchMutation.mutate(searchTicker)}
      placeholder="Search ticker (e.g. PLTR, SOL-USD)"
      className="flex-1 rounded border border-gray-700 bg-gray-800 px-3 py-2 text-sm text-white placeholder-gray-500 focus:border-indigo-500 focus:outline-none"
    />
    <button
      onClick={() => searchTicker && searchMutation.mutate(searchTicker)}
      disabled={!searchTicker || searchMutation.isPending}
      className="btn-secondary text-xs"
    >
      {searchMutation.isPending ? "..." : "Search"}
    </button>
  </div>
  {searchError && <p className="mt-2 text-xs text-red-400">{searchError}</p>}
  {searchResult?.valid && (
    <div className="mt-3 flex items-center justify-between rounded border border-gray-700 bg-gray-800/50 px-3 py-2">
      <div>
        <span className="font-mono text-sm font-bold text-white">{searchTicker}</span>
        <span className="ml-2 text-sm text-gray-400">{searchResult.name}</span>
        <span className="ml-2 rounded bg-gray-700 px-2 py-0.5 text-xs text-gray-400">{searchResult.asset_class}</span>
      </div>
      <button
        onClick={() => addAssetMutation.mutate({ id: searchTicker, asset_class: searchResult.asset_class!, name: searchResult.name! })}
        disabled={addAssetMutation.isPending}
        className="rounded bg-indigo-600 px-3 py-1 text-xs font-medium text-white hover:bg-indigo-500"
      >
        {addAssetMutation.isPending ? "Adding..." : "Add"}
      </button>
    </div>
  )}
  {addAssetMutation.isSuccess && (
    <p className="mt-2 text-xs text-emerald-400">Asset added successfully</p>
  )}
</div>
```

**Step 6: Verify frontend builds**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npx tsc --noEmit`
Expected: No errors

**Step 7: Commit**

```bash
git add backend/app/routes/assets.py backend/tests/test_validate_ticker.py frontend/src/pages/Dashboard.tsx frontend/src/api/client.ts
git commit -m "feat: add ticker search + asset creation UI on Dashboard"
```

---

### Task 2: Manual Trade Entry in Portfolio

**Files:**
- Modify: `frontend/src/pages/Portfolio.tsx`
- Modify: `backend/app/routes/portfolio.py`
- Modify: `backend/app/paper_trading/engine.py`
- Create: `backend/tests/test_manual_trade.py`

**Step 1: Add backend endpoint for manual trades (no signal required)**

Add to `backend/app/routes/portfolio.py`:

```python
class ManualTradeCreate(BaseModel):
    asset_id: str
    action: str  # "buy" or "sell"
    quantity: float
    price: float

@router.post("/trades/manual", status_code=201)
async def create_manual_trade(body: ManualTradeCreate, db: AsyncSession = Depends(get_db)):
    """Create a trade without a signal — manual portfolio entry."""
    from app.paper_trading.engine import execute_manual_trade
    try:
        trade = await execute_manual_trade(db, body.asset_id, body.action, body.price, body.quantity)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    return _trade_to_read(trade)
```

Add the `ManualTradeCreate` import: `from pydantic import BaseModel`

**Step 2: Add engine function**

Add to `backend/app/paper_trading/engine.py`:

```python
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
```

**Step 3: Make signal_id nullable in PaperTrade model**

In `backend/app/db/models.py`, change PaperTrade.signal_id:

```python
# Change from:
signal_id = Column(Integer, ForeignKey("signals.id", ondelete="CASCADE"), nullable=False)
# To:
signal_id = Column(Integer, ForeignKey("signals.id", ondelete="CASCADE"), nullable=True)
```

**Step 4: Write tests**

Create `backend/tests/test_manual_trade.py`:

```python
import pytest


@pytest.mark.asyncio
async def test_create_manual_buy(client):
    # Create asset first
    await client.post("/api/assets", json={"id": "AAPL", "asset_class": "equity", "name": "Apple"})
    resp = await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "AAPL",
        "action": "buy",
        "quantity": 10,
        "price": 150.0,
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["asset_id"] == "AAPL"
    assert data["action"] == "buy"
    assert data["quantity"] == 10
    assert data["price_at"] == 150.0
    assert data["status"] == "open"
    assert data["signal_id"] is None


@pytest.mark.asyncio
async def test_create_manual_sell(client):
    await client.post("/api/assets", json={"id": "TSLA", "asset_class": "equity", "name": "Tesla"})
    resp = await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "TSLA",
        "action": "sell",
        "quantity": 5,
        "price": 200.0,
    })
    assert resp.status_code == 201
    assert resp.json()["action"] == "sell"


@pytest.mark.asyncio
async def test_manual_trade_invalid_action(client):
    await client.post("/api/assets", json={"id": "MSFT", "asset_class": "equity", "name": "Microsoft"})
    resp = await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "MSFT",
        "action": "hold",
        "quantity": 10,
        "price": 100.0,
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_manual_trade_shows_in_summary(client):
    await client.post("/api/assets", json={"id": "GOOG", "asset_class": "equity", "name": "Alphabet"})
    await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "GOOG",
        "action": "buy",
        "quantity": 2,
        "price": 170.0,
    })
    resp = await client.get("/api/portfolio/summary")
    assert resp.status_code == 200
    assert resp.json()["total_trades"] == 1
    assert resp.json()["open_trades"] == 1
```

**Step 5: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_manual_trade.py -v`
Expected: 4 PASSED

**Step 6: Add manual trade UI to Portfolio page**

Add to `Portfolio.tsx` — a form section above the trades table:
- Asset ID input (text, uppercase)
- Action toggle (Buy / Sell buttons)
- Quantity input (number)
- Price input (number)
- Submit button

Add API function to `client.ts`:

```typescript
export const createManualTrade = (data: {
  asset_id: string;
  action: string;
  quantity: number;
  price: number;
}) =>
  request<PaperTrade>("/api/portfolio/trades/manual", {
    method: "POST",
    body: JSON.stringify(data),
  });
```

Add close trade button per open trade row in Portfolio table (calls existing `closeTrade` API).

**Step 7: Verify frontend builds**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npx tsc --noEmit`
Expected: No errors

**Step 8: Commit**

```bash
git add backend/app/routes/portfolio.py backend/app/paper_trading/engine.py backend/app/db/models.py backend/tests/test_manual_trade.py frontend/src/pages/Portfolio.tsx frontend/src/api/client.ts
git commit -m "feat: add manual trade entry + close trade UI in Portfolio"
```

---

### Task 3: QA Gate 1 — Full test suite after UX changes

**Step 1: Run all backend tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~191 PASSED (184 existing + 7 new), 0 FAILED

**Step 2: Run frontend build**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npx tsc --noEmit`
Expected: No errors

**Step 3: Commit checkpoint**

```bash
git commit --allow-empty -m "checkpoint: Layer 1 complete — UX gaps fixed, ~191 tests pass"
```

---

## Layer 2: Factor Signal Calculators (Pure Functions)

### Task 4: Momentum Factor Calculator

**Files:**
- Create: `backend/app/signals/momentum.py`
- Create: `backend/tests/test_signal_momentum.py`

**Step 1: Write failing tests**

Create `backend/tests/test_signal_momentum.py`:

```python
"""Momentum factor: 12-month return minus 1-month return (Jegadeesh & Titman 1993).
Uses trailing price data from yfinance."""

from app.signals.momentum import compute_momentum_score


def test_strong_positive_momentum():
    """Stock up 40% over 12mo, only 2% in last month → strong trend."""
    prices = {"price_12m_ago": 100, "price_1m_ago": 138, "price_now": 140}
    result = compute_momentum_score(prices)
    assert result["score"] > 0.5
    assert result["details"]["momentum_12m"] == pytest.approx(0.4, abs=0.01)
    assert result["details"]["momentum_1m"] == pytest.approx(0.0145, abs=0.01)


def test_negative_momentum():
    """Stock down 20% over 12mo."""
    prices = {"price_12m_ago": 100, "price_1m_ago": 82, "price_now": 80}
    result = compute_momentum_score(prices)
    assert result["score"] < -0.3


def test_reversal_signal():
    """Stock up 30% in 12mo but down 10% last month → weakening."""
    prices = {"price_12m_ago": 100, "price_1m_ago": 144, "price_now": 130}
    result = compute_momentum_score(prices)
    # Should be weaker than pure positive momentum
    assert result["score"] < 0.5
    assert result["details"]["reversal_flag"] is True


def test_missing_prices_returns_zero():
    result = compute_momentum_score({})
    assert result["score"] == 0.0


def test_flat_market():
    prices = {"price_12m_ago": 100, "price_1m_ago": 101, "price_now": 100}
    result = compute_momentum_score(prices)
    assert -0.1 <= result["score"] <= 0.1


import pytest
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_momentum.py -v`
Expected: FAIL (module not found)

**Step 3: Implement**

Create `backend/app/signals/momentum.py`:

```python
"""Momentum factor calculator (Jegadeesh & Titman 1993).

12-month return minus 1-month return = "residual momentum".
Avoids short-term reversal noise while capturing medium-term trend.

Score mapping:
  momentum > 0.20  → +0.7 (strong trend)
  momentum > 0.05  → +0.3 (mild trend)
  momentum < -0.20 → -0.7 (strong decline)
  momentum < -0.05 → -0.3 (mild decline)
  else              → 0.0  (flat)

Evidence: MSCI 50-year study — momentum factor delivered 13.5% annually.
"""


def compute_momentum_score(prices: dict) -> dict:
    p_now = prices.get("price_now")
    p_12m = prices.get("price_12m_ago")
    p_1m = prices.get("price_1m_ago")

    if not all(v and v > 0 for v in [p_now, p_12m, p_1m]):
        return {"score": 0.0, "details": {"error": "insufficient_price_data"}}

    mom_12m = (p_now - p_12m) / p_12m
    mom_1m = (p_now - p_1m) / p_1m
    residual = mom_12m - mom_1m  # strip short-term noise

    # Reversal detection: 12m positive but 1m sharply negative
    reversal_flag = mom_12m > 0.10 and mom_1m < -0.05

    # Score mapping
    if residual > 0.20:
        score = 0.7
    elif residual > 0.05:
        score = 0.3
    elif residual < -0.20:
        score = -0.7
    elif residual < -0.05:
        score = -0.3
    else:
        score = 0.0

    # Penalize reversals
    if reversal_flag:
        score *= 0.5

    return {
        "score": round(score, 2),
        "details": {
            "momentum_12m": round(mom_12m, 4),
            "momentum_1m": round(mom_1m, 4),
            "residual_momentum": round(residual, 4),
            "reversal_flag": reversal_flag,
        },
    }
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_momentum.py -v`
Expected: 5 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/momentum.py backend/tests/test_signal_momentum.py
git commit -m "feat: add momentum factor calculator (Jegadeesh-Titman residual momentum)"
```

---

### Task 5: Value Factor Calculator

**Files:**
- Create: `backend/app/signals/value_factor.py`
- Create: `backend/tests/test_signal_value.py`

**Step 1: Write failing tests**

Create `backend/tests/test_signal_value.py`:

```python
"""Value factor: composite of P/E, P/B, dividend yield.
Low P/E + low P/B + high dividend = deep value."""

from app.signals.value_factor import compute_value_score


def test_deep_value_stock():
    """Low P/E, low P/B, decent dividend → strong value signal."""
    fundamentals = {"pe_ratio": 8.0, "pb_ratio": 1.0, "dividend_yield": 0.04}
    result = compute_value_score(fundamentals)
    assert result["score"] > 0.5


def test_growth_stock_no_value():
    """High P/E, high P/B, no dividend → negative value signal."""
    fundamentals = {"pe_ratio": 80.0, "pb_ratio": 15.0, "dividend_yield": 0.0}
    result = compute_value_score(fundamentals)
    assert result["score"] < -0.3


def test_moderate_valuation():
    """Average P/E, average P/B → near zero."""
    fundamentals = {"pe_ratio": 20.0, "pb_ratio": 3.0, "dividend_yield": 0.02}
    result = compute_value_score(fundamentals)
    assert -0.3 <= result["score"] <= 0.3


def test_negative_pe_excluded():
    """Negative P/E (losses) → skip P/E component, use P/B and dividend."""
    fundamentals = {"pe_ratio": -5.0, "pb_ratio": 2.0, "dividend_yield": 0.03}
    result = compute_value_score(fundamentals)
    assert result["details"]["pe_excluded"] is True


def test_missing_data():
    result = compute_value_score({})
    assert result["score"] == 0.0
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_value.py -v`
Expected: FAIL

**Step 3: Implement**

Create `backend/app/signals/value_factor.py`:

```python
"""Value factor calculator — composite of P/E, P/B, dividend yield.

Based on Fama-French value factor (HML). Stocks with low price-to-fundamentals
ratios tend to outperform. MSCI enhanced value delivered 13.3% annually over 50 years.

Scoring: Each component mapped to [-1, +1] range, then averaged.
  P/E:  <12 = +1,  12-18 = +0.3,  18-30 = -0.3,  >30 = -1  (negative excluded)
  P/B:  <1.5 = +1, 1.5-3 = +0.3,  3-8 = -0.3,    >8 = -1
  Div:  >4% = +1,  2-4% = +0.3,   0.5-2% = -0.3,  <0.5% = -1
"""


def _score_pe(pe: float | None) -> tuple[float, bool]:
    if pe is None or pe <= 0:
        return 0.0, True  # excluded
    if pe < 12:
        return 1.0, False
    if pe < 18:
        return 0.3, False
    if pe < 30:
        return -0.3, False
    return -1.0, False


def _score_pb(pb: float | None) -> float:
    if pb is None or pb <= 0:
        return 0.0
    if pb < 1.5:
        return 1.0
    if pb < 3.0:
        return 0.3
    if pb < 8.0:
        return -0.3
    return -1.0


def _score_div(div_yield: float | None) -> float:
    if div_yield is None:
        return 0.0
    if div_yield > 0.04:
        return 1.0
    if div_yield > 0.02:
        return 0.3
    if div_yield > 0.005:
        return -0.3
    return -1.0


def compute_value_score(fundamentals: dict) -> dict:
    pe = fundamentals.get("pe_ratio")
    pb = fundamentals.get("pb_ratio")
    div_yield = fundamentals.get("dividend_yield")

    if pe is None and pb is None and div_yield is None:
        return {"score": 0.0, "details": {"error": "no_fundamental_data"}}

    pe_score, pe_excluded = _score_pe(pe)
    pb_score = _score_pb(pb)
    div_score = _score_div(div_yield)

    components = []
    if not pe_excluded:
        components.append(pe_score)
    components.append(pb_score)
    components.append(div_score)

    avg = sum(components) / len(components) if components else 0.0
    # Scale to [-0.8, 0.8] range (leave room for extreme signals)
    score = round(max(-0.8, min(0.8, avg * 0.8)), 2)

    return {
        "score": score,
        "details": {
            "pe_score": pe_score,
            "pb_score": pb_score,
            "div_score": div_score,
            "pe_excluded": pe_excluded,
            "raw_pe": pe,
            "raw_pb": pb,
            "raw_dividend_yield": div_yield,
        },
    }
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_value.py -v`
Expected: 5 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/value_factor.py backend/tests/test_signal_value.py
git commit -m "feat: add value factor calculator (P/E + P/B + dividend yield composite)"
```

---

### Task 6: Quality Factor Calculator

**Files:**
- Create: `backend/app/signals/quality_factor.py`
- Create: `backend/tests/test_signal_quality.py`

**Step 1: Write failing tests**

Create `backend/tests/test_signal_quality.py`:

```python
"""Quality factor: ROE, debt-to-equity, earnings stability.
High-quality companies have high ROE, low debt, stable earnings."""

from app.signals.quality_factor import compute_quality_score


def test_high_quality():
    """High ROE, low debt, stable earnings → strong quality."""
    data = {"roe": 0.25, "debt_to_equity": 0.3, "earnings_growth_std": 0.05}
    result = compute_quality_score(data)
    assert result["score"] > 0.5


def test_low_quality():
    """Low ROE, high debt, volatile earnings."""
    data = {"roe": 0.03, "debt_to_equity": 3.0, "earnings_growth_std": 0.40}
    result = compute_quality_score(data)
    assert result["score"] < -0.3


def test_moderate_quality():
    data = {"roe": 0.12, "debt_to_equity": 1.0, "earnings_growth_std": 0.15}
    result = compute_quality_score(data)
    assert -0.3 <= result["score"] <= 0.3


def test_negative_roe():
    """Losing money → bad quality signal."""
    data = {"roe": -0.10, "debt_to_equity": 2.0, "earnings_growth_std": 0.30}
    result = compute_quality_score(data)
    assert result["score"] < -0.5


def test_missing_data():
    result = compute_quality_score({})
    assert result["score"] == 0.0
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_quality.py -v`
Expected: FAIL

**Step 3: Implement**

Create `backend/app/signals/quality_factor.py`:

```python
"""Quality factor calculator — ROE, debt-to-equity, earnings stability.

High-quality stocks have lower volatility and complement momentum (MSCI research).
Quality factor is the weakest standalone but is a crucial risk-reducer in multi-factor.

Scoring:
  ROE:     >20% = +1, 10-20% = +0.3, 5-10% = -0.3, <5% = -1
  D/E:     <0.5 = +1, 0.5-1.5 = +0.3, 1.5-3 = -0.3, >3 = -1
  EarStd:  <0.10 = +1, 0.10-0.20 = +0.3, 0.20-0.35 = -0.3, >0.35 = -1
"""


def _score_roe(roe: float | None) -> float:
    if roe is None:
        return 0.0
    if roe < 0:
        return -1.0
    if roe > 0.20:
        return 1.0
    if roe > 0.10:
        return 0.3
    if roe > 0.05:
        return -0.3
    return -1.0


def _score_debt(de: float | None) -> float:
    if de is None:
        return 0.0
    if de < 0.5:
        return 1.0
    if de < 1.5:
        return 0.3
    if de < 3.0:
        return -0.3
    return -1.0


def _score_stability(std: float | None) -> float:
    if std is None:
        return 0.0
    if std < 0.10:
        return 1.0
    if std < 0.20:
        return 0.3
    if std < 0.35:
        return -0.3
    return -1.0


def compute_quality_score(data: dict) -> dict:
    roe = data.get("roe")
    de = data.get("debt_to_equity")
    eg_std = data.get("earnings_growth_std")

    if roe is None and de is None and eg_std is None:
        return {"score": 0.0, "details": {"error": "no_quality_data"}}

    roe_s = _score_roe(roe)
    de_s = _score_debt(de)
    stab_s = _score_stability(eg_std)

    components = [s for s in [roe_s, de_s, stab_s] if s != 0.0]
    if not components:
        return {"score": 0.0, "details": {"error": "all_components_zero"}}

    avg = sum(components) / len(components)
    score = round(max(-0.8, min(0.8, avg * 0.8)), 2)

    return {
        "score": score,
        "details": {
            "roe_score": roe_s,
            "debt_score": de_s,
            "stability_score": stab_s,
            "raw_roe": roe,
            "raw_debt_to_equity": de,
            "raw_earnings_std": eg_std,
        },
    }
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_quality.py -v`
Expected: 5 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/quality_factor.py backend/tests/test_signal_quality.py
git commit -m "feat: add quality factor calculator (ROE + D/E + earnings stability)"
```

---

### Task 7: Post-Earnings Drift Calculator

**Files:**
- Create: `backend/app/signals/earnings_drift.py`
- Create: `backend/tests/test_signal_drift.py`

**Step 1: Write failing tests**

Create `backend/tests/test_signal_drift.py`:

```python
"""Post-Earnings Announcement Drift (PEAD).
Prices keep drifting in the direction of earnings surprises for weeks.
Sharpe ratios nearly double when exploiting this. (Bernard & Thomas 1989)"""

from app.signals.earnings_drift import compute_drift_score


def test_positive_surprise_drift():
    """Beat estimates by 10%+ → strong positive drift expected."""
    data = {"actual_eps": 2.20, "estimated_eps": 2.00, "days_since_earnings": 5}
    result = compute_drift_score(data)
    assert result["score"] > 0.3
    assert result["details"]["surprise_pct"] > 0


def test_negative_surprise_drift():
    """Missed estimates → negative drift."""
    data = {"actual_eps": 1.80, "estimated_eps": 2.00, "days_since_earnings": 3}
    result = compute_drift_score(data)
    assert result["score"] < -0.3


def test_drift_decays_with_time():
    """After 60+ days, drift signal fades."""
    data = {"actual_eps": 2.50, "estimated_eps": 2.00, "days_since_earnings": 70}
    result = compute_drift_score(data)
    assert -0.1 <= result["score"] <= 0.1


def test_inline_earnings_neutral():
    """Met estimates exactly → no drift."""
    data = {"actual_eps": 2.00, "estimated_eps": 2.00, "days_since_earnings": 5}
    result = compute_drift_score(data)
    assert -0.1 <= result["score"] <= 0.1


def test_missing_data():
    result = compute_drift_score({})
    assert result["score"] == 0.0
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_drift.py -v`
Expected: FAIL

**Step 3: Implement**

Create `backend/app/signals/earnings_drift.py`:

```python
"""Post-Earnings Announcement Drift (PEAD) calculator.

Bernard & Thomas (1989): prices continue to drift 60 days after earnings surprises.
SUE = (actual - estimated) / |estimated|
Signal decays linearly over 60 days.

Score mapping:
  SUE > 10%  → +0.7 × decay
  SUE > 3%   → +0.4 × decay
  SUE < -10% → -0.7 × decay
  SUE < -3%  → -0.4 × decay
  else       → 0.0
"""

_DRIFT_WINDOW_DAYS = 60


def compute_drift_score(data: dict) -> dict:
    actual = data.get("actual_eps")
    estimated = data.get("estimated_eps")
    days = data.get("days_since_earnings")

    if actual is None or estimated is None or days is None:
        return {"score": 0.0, "details": {"error": "missing_earnings_data"}}

    if estimated == 0:
        return {"score": 0.0, "details": {"error": "zero_estimate"}}

    surprise_pct = (actual - estimated) / abs(estimated)

    # Time decay: 1.0 at day 0, 0.0 at day 60+
    decay = max(0.0, 1.0 - days / _DRIFT_WINDOW_DAYS)

    # Base score from surprise magnitude
    if surprise_pct > 0.10:
        base = 0.7
    elif surprise_pct > 0.03:
        base = 0.4
    elif surprise_pct < -0.10:
        base = -0.7
    elif surprise_pct < -0.03:
        base = -0.4
    else:
        base = 0.0

    score = round(base * decay, 2)

    return {
        "score": score,
        "details": {
            "surprise_pct": round(surprise_pct, 4),
            "days_since_earnings": days,
            "decay_factor": round(decay, 3),
            "drift_window_days": _DRIFT_WINDOW_DAYS,
        },
    }
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_drift.py -v`
Expected: 5 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/earnings_drift.py backend/tests/test_signal_drift.py
git commit -m "feat: add post-earnings drift calculator (PEAD, Bernard-Thomas decay)"
```

---

### Task 8: QA Gate 2

**Step 1: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~211 PASSED, 0 FAILED

**Step 2: Commit**

```bash
git commit --allow-empty -m "checkpoint: Layer 2 complete — 4 factor calculators, ~211 tests pass"
```

---

## Layer 3: Advanced Analytics

### Task 9: Regime Detection (Dalio's 4 Seasons)

**Files:**
- Create: `backend/app/signals/regime.py`
- Create: `backend/tests/test_signal_regime.py`

**Step 1: Write failing tests**

Create `backend/tests/test_signal_regime.py`:

```python
"""Regime detection: classify current macro environment into 4 quadrants.
Based on Ray Dalio's All Weather framework.

Quadrants:
  Rising growth + Rising inflation  → "reflation" (commodities, gold)
  Rising growth + Falling inflation → "goldilocks" (stocks)
  Falling growth + Rising inflation → "stagflation" (gold, TIPS)
  Falling growth + Falling inflation → "deflation" (bonds)
"""

from app.signals.regime import detect_regime, score_asset_for_regime


def test_goldilocks_regime():
    """GDP up, CPI down → best for stocks."""
    macro = {"gdp_trend": 0.03, "cpi_trend": -0.005, "yield_curve": 0.5}
    result = detect_regime(macro)
    assert result["regime"] == "goldilocks"


def test_stagflation_regime():
    """GDP down, CPI up → worst for stocks."""
    macro = {"gdp_trend": -0.02, "cpi_trend": 0.02, "yield_curve": -0.3}
    result = detect_regime(macro)
    assert result["regime"] == "stagflation"


def test_score_equity_in_goldilocks():
    """Equities thrive in goldilocks."""
    score = score_asset_for_regime("equity", "goldilocks")
    assert score > 0.3


def test_score_equity_in_stagflation():
    """Equities suffer in stagflation."""
    score = score_asset_for_regime("equity", "stagflation")
    assert score < -0.3


def test_score_crypto_in_reflation():
    """Crypto behaves like gold/commodities in reflation."""
    score = score_asset_for_regime("crypto", "reflation")
    assert score > 0


def test_missing_macro():
    result = detect_regime({})
    assert result["regime"] == "unknown"
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_regime.py -v`
Expected: FAIL

**Step 3: Implement**

Create `backend/app/signals/regime.py`:

```python
"""Macro regime detection — Dalio's All Weather 4-quadrant model.

Classifies current environment based on GDP trend and CPI trend:
  gdp_trend > 0, cpi_trend < 0  → goldilocks  (best for stocks)
  gdp_trend > 0, cpi_trend > 0  → reflation   (commodities, gold, TIPS)
  gdp_trend < 0, cpi_trend > 0  → stagflation  (gold, cash — worst for stocks)
  gdp_trend < 0, cpi_trend < 0  → deflation    (bonds)

yield_curve < 0 (inverted) adds recession risk penalty.
"""

# Asset-regime affinity matrix: {asset_class: {regime: score}}
_REGIME_SCORES = {
    "equity": {
        "goldilocks": 0.6,
        "reflation": 0.2,
        "deflation": -0.2,
        "stagflation": -0.6,
        "unknown": 0.0,
    },
    "crypto": {
        "goldilocks": 0.3,
        "reflation": 0.4,  # behaves like digital gold
        "deflation": -0.3,
        "stagflation": -0.2,
        "unknown": 0.0,
    },
    "commodity": {
        "goldilocks": 0.1,
        "reflation": 0.7,
        "deflation": -0.5,
        "stagflation": 0.3,
        "unknown": 0.0,
    },
    "forex": {
        "goldilocks": 0.0,
        "reflation": -0.1,
        "deflation": 0.1,
        "stagflation": -0.1,
        "unknown": 0.0,
    },
}


def detect_regime(macro: dict) -> dict:
    """Classify macro environment into one of 4 quadrants."""
    gdp = macro.get("gdp_trend")
    cpi = macro.get("cpi_trend")
    yc = macro.get("yield_curve", 0)

    if gdp is None or cpi is None:
        return {"regime": "unknown", "details": {"error": "missing_macro_data"}}

    growth_rising = gdp > 0
    inflation_rising = cpi > 0

    if growth_rising and not inflation_rising:
        regime = "goldilocks"
    elif growth_rising and inflation_rising:
        regime = "reflation"
    elif not growth_rising and inflation_rising:
        regime = "stagflation"
    else:
        regime = "deflation"

    return {
        "regime": regime,
        "details": {
            "gdp_trend": gdp,
            "cpi_trend": cpi,
            "yield_curve": yc,
            "inverted_curve": yc < 0,
            "recession_risk": yc < -0.2,
        },
    }


def score_asset_for_regime(asset_class: str, regime: str) -> float:
    """Return affinity score for an asset class in the given regime."""
    scores = _REGIME_SCORES.get(asset_class, _REGIME_SCORES["equity"])
    return scores.get(regime, 0.0)
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_regime.py -v`
Expected: 6 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/regime.py backend/tests/test_signal_regime.py
git commit -m "feat: add macro regime detection (Dalio 4-quadrant model)"
```

---

### Task 10: Kelly Criterion Position Sizing

**Files:**
- Create: `backend/app/signals/kelly.py`
- Create: `backend/tests/test_signal_kelly.py`

**Step 1: Write failing tests**

Create `backend/tests/test_signal_kelly.py`:

```python
"""Kelly Criterion — optimal bet sizing (Edward Thorp).
f* = (p * b - q) / b
where p = win probability, b = win/loss ratio, q = 1-p.

We use half-Kelly for safety (99% chance of not losing >50% of wealth).
"""

from app.signals.kelly import compute_kelly_fraction


def test_strong_edge():
    """60% win rate, 2:1 payoff → aggressive sizing."""
    result = compute_kelly_fraction(win_rate=0.60, avg_win=200, avg_loss=100)
    assert 0.15 < result["half_kelly"] < 0.40


def test_coin_flip_no_edge():
    """50% win rate, 1:1 payoff → zero allocation."""
    result = compute_kelly_fraction(win_rate=0.50, avg_win=100, avg_loss=100)
    assert result["half_kelly"] == 0.0


def test_losing_strategy():
    """40% win rate, 1:1 payoff → negative Kelly (don't bet)."""
    result = compute_kelly_fraction(win_rate=0.40, avg_win=100, avg_loss=100)
    assert result["half_kelly"] == 0.0
    assert result["details"]["full_kelly"] < 0


def test_caps_at_25_percent():
    """Even with massive edge, cap at 25% of portfolio."""
    result = compute_kelly_fraction(win_rate=0.90, avg_win=500, avg_loss=50)
    assert result["half_kelly"] <= 0.25


def test_insufficient_data():
    result = compute_kelly_fraction(win_rate=None, avg_win=None, avg_loss=None)
    assert result["half_kelly"] == 0.0
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_kelly.py -v`
Expected: FAIL

**Step 3: Implement**

Create `backend/app/signals/kelly.py`:

```python
"""Kelly Criterion position sizing (Edward Thorp, Beat the Dealer).

Full Kelly: f* = (p * b - q) / b
  p = win probability
  b = win/loss ratio (avg_win / avg_loss)
  q = 1 - p

Half Kelly: f*/2 — recommended for real trading.
  99% chance of never losing more than 50% of bankroll.

Cap at 25% max position size regardless of Kelly output.
"""

_MAX_POSITION = 0.25  # Never risk more than 25% on one position


def compute_kelly_fraction(
    win_rate: float | None,
    avg_win: float | None,
    avg_loss: float | None,
) -> dict:
    if win_rate is None or avg_win is None or avg_loss is None:
        return {
            "half_kelly": 0.0,
            "details": {"error": "insufficient_trade_history"},
        }

    if avg_loss <= 0 or avg_win <= 0:
        return {
            "half_kelly": 0.0,
            "details": {"error": "invalid_win_loss_values"},
        }

    p = win_rate
    q = 1.0 - p
    b = avg_win / avg_loss

    full_kelly = (p * b - q) / b if b > 0 else 0.0

    # No edge or negative edge → don't bet
    if full_kelly <= 0:
        return {
            "half_kelly": 0.0,
            "details": {
                "full_kelly": round(full_kelly, 4),
                "win_rate": p,
                "payoff_ratio": round(b, 4),
                "edge": "none",
            },
        }

    half = min(full_kelly / 2, _MAX_POSITION)

    return {
        "half_kelly": round(half, 4),
        "details": {
            "full_kelly": round(full_kelly, 4),
            "win_rate": p,
            "payoff_ratio": round(b, 4),
            "max_position": _MAX_POSITION,
            "edge": "positive",
        },
    }
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_kelly.py -v`
Expected: 5 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/kelly.py backend/tests/test_signal_kelly.py
git commit -m "feat: add Kelly Criterion position sizing (half-Kelly with 25% cap)"
```

---

### Task 11: Hurst Exponent (Chaos Metric)

**Files:**
- Create: `backend/app/signals/hurst.py`
- Create: `backend/tests/test_signal_hurst.py`

**Dependencies:** Add `numpy` to requirements (likely already present)

**Step 1: Write failing tests**

Create `backend/tests/test_signal_hurst.py`:

```python
"""Hurst exponent: detect if a price series is trending, mean-reverting, or random.
H > 0.5 → trending (momentum works)
H = 0.5 → random walk (no edge)
H < 0.5 → mean-reverting (contrarian works)

Mandelbrot proved markets are NOT random walks — H is rarely exactly 0.5.
"""

import numpy as np
from app.signals.hurst import compute_hurst_score


def test_trending_series():
    """Synthetic uptrend → H > 0.5 → positive score."""
    np.random.seed(42)
    # Cumulative sum of positive-biased random walk = trending
    prices = np.cumsum(np.random.normal(0.5, 1, 200)) + 100
    result = compute_hurst_score(prices.tolist())
    assert result["score"] > 0
    assert result["details"]["hurst"] > 0.5


def test_mean_reverting_series():
    """Synthetic oscillation → H < 0.5 → negative score (contrarian signal)."""
    prices = [100 + 5 * ((-1) ** i) + np.random.normal(0, 0.5) for i in range(200)]
    result = compute_hurst_score(prices)
    assert result["score"] < 0
    assert result["details"]["hurst"] < 0.5


def test_random_walk():
    """Pure random walk → H ≈ 0.5 → near-zero score."""
    np.random.seed(123)
    prices = np.cumsum(np.random.normal(0, 1, 500)) + 100
    result = compute_hurst_score(prices.tolist())
    assert -0.2 <= result["score"] <= 0.2


def test_too_few_prices():
    result = compute_hurst_score([100, 101, 102])
    assert result["score"] == 0.0
    assert "error" in result["details"]


def test_empty_prices():
    result = compute_hurst_score([])
    assert result["score"] == 0.0


import numpy as np
```

**Step 2: Run to verify failure**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_hurst.py -v`
Expected: FAIL

**Step 3: Implement**

Create `backend/app/signals/hurst.py`:

```python
"""Hurst exponent calculator — R/S (rescaled range) analysis.

Mandelbrot's key insight: market returns follow power laws, not bell curves.
The Hurst exponent reveals hidden structure:

  H > 0.5 → persistent (trending) — momentum strategies work
  H = 0.5 → random walk — no statistical edge
  H < 0.5 → anti-persistent (mean-reverting) — contrarian strategies work

Score mapping:
  H > 0.65 → +0.5 (strong trend)
  H > 0.55 → +0.2 (mild trend)
  H < 0.35 → -0.5 (strong mean reversion)
  H < 0.45 → -0.2 (mild mean reversion)
  else     → 0.0 (random)

Requires at least 50 price observations for statistical validity.
"""

import math

_MIN_OBSERVATIONS = 50


def _rescaled_range(series: list[float], n: int) -> float:
    """Compute R/S statistic for a subseries of length n."""
    num_subseries = len(series) // n
    if num_subseries == 0:
        return 0.0

    rs_values = []
    for i in range(num_subseries):
        subseries = series[i * n : (i + 1) * n]
        mean = sum(subseries) / len(subseries)
        deviations = [x - mean for x in subseries]
        cumulative = []
        s = 0
        for d in deviations:
            s += d
            cumulative.append(s)
        r = max(cumulative) - min(cumulative)
        std = (sum(d * d for d in deviations) / len(deviations)) ** 0.5
        if std > 0:
            rs_values.append(r / std)

    return sum(rs_values) / len(rs_values) if rs_values else 0.0


def _estimate_hurst(prices: list[float]) -> float:
    """Estimate Hurst exponent via R/S analysis on log returns."""
    if len(prices) < _MIN_OBSERVATIONS:
        return 0.5  # insufficient data → assume random

    # Compute log returns
    returns = [math.log(prices[i] / prices[i - 1]) for i in range(1, len(prices)) if prices[i - 1] > 0 and prices[i] > 0]
    if len(returns) < _MIN_OBSERVATIONS:
        return 0.5

    # R/S analysis at multiple scales
    ns = []
    rs = []
    n = 10
    while n <= len(returns) // 2:
        rs_val = _rescaled_range(returns, n)
        if rs_val > 0:
            ns.append(math.log(n))
            rs.append(math.log(rs_val))
        n = int(n * 1.5)

    if len(ns) < 3:
        return 0.5

    # Linear regression: log(R/S) = H * log(n) + c
    n_mean = sum(ns) / len(ns)
    rs_mean = sum(rs) / len(rs)
    num = sum((ns[i] - n_mean) * (rs[i] - rs_mean) for i in range(len(ns)))
    den = sum((ns[i] - n_mean) ** 2 for i in range(len(ns)))
    h = num / den if den > 0 else 0.5

    return max(0.0, min(1.0, h))


def compute_hurst_score(prices: list[float]) -> dict:
    if len(prices) < _MIN_OBSERVATIONS:
        return {"score": 0.0, "details": {"error": "need_50_observations_minimum"}}

    h = _estimate_hurst(prices)

    if h > 0.65:
        score = 0.5
    elif h > 0.55:
        score = 0.2
    elif h < 0.35:
        score = -0.5
    elif h < 0.45:
        score = -0.2
    else:
        score = 0.0

    regime = "trending" if h > 0.55 else "mean_reverting" if h < 0.45 else "random"

    return {
        "score": score,
        "details": {
            "hurst": round(h, 4),
            "regime": regime,
            "observations": len(prices),
            "interpretation": f"H={h:.3f} → {regime}",
        },
    }
```

**Step 4: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_signal_hurst.py -v`
Expected: 5 PASSED

**Step 5: Commit**

```bash
git add backend/app/signals/hurst.py backend/tests/test_signal_hurst.py
git commit -m "feat: add Hurst exponent calculator (R/S analysis, chaos detection)"
```

---

### Task 12: QA Gate 3

**Step 1: Run all tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~227 PASSED, 0 FAILED

**Step 2: Commit**

```bash
git commit --allow-empty -m "checkpoint: Layer 3 complete — regime, Kelly, Hurst added, ~227 tests pass"
```

---

## Layer 4: Integration

### Task 13: Wire New Calculators into Runner

**Files:**
- Modify: `backend/app/signals/runner.py`
- Create: `backend/tests/test_runner_extended.py`

**Step 1: Write integration tests**

Create `backend/tests/test_runner_extended.py`:

```python
"""Test that new signal calculators are wired into the runner."""

import pytest
from unittest.mock import patch, AsyncMock
from app.signals.runner import compute_all_signals


@pytest.mark.asyncio
async def test_runner_computes_momentum(db_session):
    """Runner should compute momentum for equity assets with price history."""
    from app.db.models import Asset, DataSnapshot
    import json
    from datetime import datetime, timezone

    asset = Asset(id="TEST", asset_class="equity", name="Test Co", tracked=True)
    db_session.add(asset)
    await db_session.flush()

    # Add price snapshot with historical prices
    snap = DataSnapshot(
        asset_id="TEST",
        source="price",
        raw_data={
            "currentPrice": 140,
            "price_12m_ago": 100,
            "price_1m_ago": 135,
            "pe_ratio": 15,
            "pb_ratio": 2.5,
            "dividend_yield": 0.02,
            "roe": 0.18,
            "debt_to_equity": 0.8,
        },
        fetched_at=datetime.now(timezone.utc),
    )
    db_session.add(snap)
    await db_session.commit()

    results = await compute_all_signals(db_session, "TEST")
    assert "momentum" in results
    assert "value" in results
    assert "quality" in results


@pytest.mark.asyncio
async def test_runner_computes_regime(db_session):
    """Runner should compute regime score using macro data."""
    from app.db.models import Asset, DataSnapshot
    from datetime import datetime, timezone

    asset = Asset(id="TEST2", asset_class="equity", name="Test 2", tracked=True)
    # Ensure _MACRO system asset exists
    macro_asset = Asset(id="_MACRO", asset_class="equity", name="Macro", tracked=False)
    db_session.add_all([asset, macro_asset])
    await db_session.flush()

    macro_snap = DataSnapshot(
        asset_id="_MACRO",
        source="macro",
        raw_data={
            "gdp_trend": 0.03,
            "cpi_trend": -0.01,
            "yield_curve": 0.5,
        },
        fetched_at=datetime.now(timezone.utc),
    )
    db_session.add(macro_snap)
    await db_session.commit()

    results = await compute_all_signals(db_session, "TEST2")
    assert "regime" in results
```

**Step 2: Update runner.py**

Add new calculator imports and computation blocks to `backend/app/signals/runner.py`. Add after existing signal computations:

```python
from app.signals.momentum import compute_momentum_score
from app.signals.value_factor import compute_value_score
from app.signals.quality_factor import compute_quality_score
from app.signals.earnings_drift import compute_drift_score
from app.signals.regime import detect_regime, score_asset_for_regime
from app.signals.hurst import compute_hurst_score
```

Add computation blocks inside `compute_all_signals()` for equity assets (after existing signals):

```python
# Momentum — from price snapshot
price_data = market_data or {}
momentum_prices = {
    "price_now": price_data.get("currentPrice"),
    "price_12m_ago": price_data.get("price_12m_ago"),
    "price_1m_ago": price_data.get("price_1m_ago"),
}
if momentum_prices["price_now"]:
    result = compute_momentum_score(momentum_prices)
    await _save_signal_score(db, asset_id, "momentum", result)
    results["momentum"] = result

# Value — from fundamentals
value_data = {
    "pe_ratio": price_data.get("pe_ratio"),
    "pb_ratio": price_data.get("pb_ratio"),
    "dividend_yield": price_data.get("dividend_yield"),
}
if any(v is not None for v in value_data.values()):
    result = compute_value_score(value_data)
    await _save_signal_score(db, asset_id, "value", result)
    results["value"] = result

# Quality — from fundamentals
quality_data = {
    "roe": price_data.get("roe"),
    "debt_to_equity": price_data.get("debt_to_equity"),
    "earnings_growth_std": price_data.get("earnings_growth_std"),
}
if any(v is not None for v in quality_data.values()):
    result = compute_quality_score(quality_data)
    await _save_signal_score(db, asset_id, "quality", result)
    results["quality"] = result

# Post-Earnings Drift
drift_data = {
    "actual_eps": price_data.get("actual_eps"),
    "estimated_eps": price_data.get("estimated_eps"),
    "days_since_earnings": price_data.get("days_since_earnings"),
}
if drift_data["actual_eps"] is not None:
    result = compute_drift_score(drift_data)
    await _save_signal_score(db, asset_id, "earnings_drift", result)
    results["earnings_drift"] = result

# Regime — from macro snapshot
macro_snap = await _get_latest_snapshot(db, "_MACRO", "macro")
if macro_snap:
    regime_result = detect_regime(macro_snap)
    regime_score = score_asset_for_regime(asset.asset_class, regime_result["regime"])
    combined = {"score": regime_score, "details": {**regime_result["details"], "regime": regime_result["regime"]}}
    await _save_signal_score(db, asset_id, "regime", combined)
    results["regime"] = combined

# Hurst exponent — from price history (if available)
price_history = price_data.get("price_history", [])
if len(price_history) >= 50:
    result = compute_hurst_score(price_history)
    await _save_signal_score(db, asset_id, "hurst", result)
    results["hurst"] = result
```

**Step 3: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_runner_extended.py -v`
Expected: 2 PASSED

**Step 4: Run full suite**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~229 PASSED, 0 FAILED

**Step 5: Commit**

```bash
git add backend/app/signals/runner.py backend/tests/test_runner_extended.py
git commit -m "feat: wire momentum, value, quality, drift, regime, hurst into signal runner"
```

---

### Task 14: Add New Golden Rules for Factor Signals

**Files:**
- Modify: `backend/app/rules/default_rules.py`
- Modify: `backend/tests/test_routes_rules.py`

**Step 1: Add 3 new rules**

Append to the `DEFAULT_RULES` list in `default_rules.py`:

```python
{
    "name": "Momentum Factor Alignment",
    "description": "Weight signals that align with 12-month price momentum",
    "rule_prompt": "If the asset shows strong positive residual momentum (12m return minus 1m return > 20%), favor buy signals. If momentum is strongly negative, favor caution.",
    "asset_class": "equity",
    "weight": 0.7,
},
{
    "name": "Multi-Factor Convergence",
    "description": "Strongest signal when momentum, value, and quality all agree",
    "rule_prompt": "When momentum, value, and quality factors all point in the same direction (all positive or all negative), increase conviction. When they diverge, reduce confidence and flag the conflict.",
    "asset_class": None,
    "weight": 0.9,
},
{
    "name": "Regime Awareness",
    "description": "Adjust signal strength based on macro regime",
    "rule_prompt": "In goldilocks regime (rising growth, falling inflation), favor equity buy signals. In stagflation (falling growth, rising inflation), increase risk flags and reduce buy confidence. Always note the current regime in analysis.",
    "asset_class": None,
    "weight": 0.6,
},
```

**Step 2: Update test rule count**

In `test_routes_rules.py`, change all `== 8` to `== 11` (8 existing + 3 new).

**Step 3: Run tests**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/test_routes_rules.py -v`
Expected: All PASSED

**Step 4: Commit**

```bash
git add backend/app/rules/default_rules.py backend/tests/test_routes_rules.py
git commit -m "feat: add momentum, multi-factor convergence, regime awareness golden rules"
```

---

### Task 15: Update Frontend Signal Scores Page

**Files:**
- Modify: `frontend/src/pages/SignalScores.tsx`

**Step 1: Update page to show new signal types**

The existing SignalScores page shows signals from the `/api/signals` endpoint. It already handles arbitrary signal data. No changes needed unless we want to show individual signal score breakdowns.

Add a tooltip or expandable row showing signal score details. For now, verify the page works with new data by running the frontend build.

**Step 2: Verify frontend builds**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npx tsc --noEmit`
Expected: No errors

**Step 3: Commit (if changes were made)**

```bash
git commit --allow-empty -m "checkpoint: frontend verified with new signal types"
```

---

### Task 16: QA Gate 4 — Final

**Step 1: Run full backend test suite**

Run: `cd "D:/Claude local/alpha-pulse/backend" && python -m pytest tests/ -v --tb=short`
Expected: ~232 PASSED, 0 FAILED

**Step 2: Run frontend build**

Run: `cd "D:/Claude local/alpha-pulse/frontend" && npx tsc --noEmit`
Expected: No errors

**Step 3: Verify app loads**

Start servers, navigate to `http://localhost:5174`, confirm:
- Dashboard loads with Add Asset search bar
- Portfolio page has manual trade form + close buttons
- Signal Scores page renders without errors

**Step 4: Final commit**

```bash
git commit --allow-empty -m "checkpoint: Quant Edge Sprint complete — ~232 tests pass, 7 new calculators, UX gaps fixed"
```

---

## Summary

| Layer | Tasks | New Tests | Key Deliverables |
|-------|-------|-----------|-----------------|
| 1: UX Gaps | 1-3 | ~7 | Add Asset search, manual trades, close trade UI |
| 2: Factor Calculators | 4-8 | ~20 | Momentum, value, quality, post-earnings drift |
| 3: Advanced Analytics | 9-12 | ~16 | Regime detection, Kelly sizing, Hurst exponent |
| 4: Integration | 13-16 | ~5 | Wire into runner, new golden rules, frontend verify |
| **Total** | **16 tasks** | **~48** | **~232 total tests** |

### New Python dependencies needed:
```
numpy  (likely already installed — used by Hurst exponent)
```

No new npm packages needed on the frontend.
