# Alpha Pulse — Full Vision Sprint Design

**Date:** 2026-03-02
**Approach:** Layer Cake (horizontal layers, each fully functional before next)
**Scope:** Top 30 assets + all Tier 1 research signals + auto-scanner + enhanced frontend

## Overview

Transform Alpha Pulse from a 3-asset demo into a comprehensive market intelligence platform.
Five layers built sequentially with QA gates between each.

## Layer 1: Data Foundation

### Asset Seeding

30 default assets seeded on first startup via `app/ingestion/seed.py`:

**Equities (20):** AAPL, MSFT, GOOGL, AMZN, NVDA, META, TSLA, BRK-B, JPM, V, UNH, JNJ, WMT, PG, MA, HD, XOM, LLY, AVGO, COST

**Crypto (10):** BTC-USD, ETH-USD, SOL-USD, BNB-USD, XRP-USD, ADA-USD, DOGE-USD, AVAX-USD, DOT-USD, LINK-USD

- `seed_default_assets()` is idempotent (skips existing)
- Called from `init_db()` so every fresh DB starts populated

### Bulk Ingestion

New `app/ingestion/bulk_ingest.py`:
- `bulk_ingest_all()` runs all 5 ingestion jobs once for all tracked assets
- Exposed as `POST /api/ingest/bulk` for on-demand use
- Called on first startup if no snapshots exist
- Rate limiting: 1 req/sec yfinance, 2 sec CoinGecko
- yfinance `history(period="2y")` for price history, `.info` for fundamentals

### QA Gate 1
- Existing 136 tests still pass
- New tests for seed + bulk_ingest (~8 tests)
- Verify DB has 30 assets with DataSnapshot rows
- Hit `/api/assets` and confirm all present

---

## Layer 2: Signal Calculators

### New DB Model: SignalScore

| Column | Type | Purpose |
|--------|------|---------|
| id | int PK | Auto |
| asset_id | FK -> Asset | Which asset |
| signal_name | string | "lifecycle", "insider_buys", "readability", "earnings_nlp", "employee_sentiment" |
| score | float (-1 to +1) | Normalized score |
| details | JSON | Breakdown, reasoning, raw metrics |
| computed_at | datetime | When calculated |

Indexed on `(asset_id, signal_name)`.

### Signal Calculators (app/signals/)

All programmatic (no LLM calls). Each returns score + details dict.

**1. lifecycle.py — Corporate Lifecycle Stage (Dickinson method)**
- Input: quarterly cash flow statements from yfinance snapshots
- Classify by sign pattern of operating/investing/financing CF
- Scores: Maturity +0.7, Growth +0.4, Shakeout -0.2, Introduction -0.5, Decline -0.8
- Equities only

**2. insider.py — Insider Purchase Tracking**
- Input: SEC EDGAR Form 4 filings via `edgartools`
- Net purchase ratio = (buys - sells) / total in last 90 days
- Cluster detection: multiple insiders buying within 2 weeks = bonus
- Scores: Strong net buying +0.8, net selling -0.6, mixed 0.0
- Equities only

**3. readability.py — 10-K Readability Scoring**
- Input: 10-K filing text from SEC EDGAR ingestion
- Compute Gunning Fog index via `textstat`, compare to prior year
- Count Loughran-McDonald negative/uncertainty words via `pysentiment`
- Scores: Increasing complexity (Fog delta > +2) = -0.5, decreasing +0.3, stable 0.0
- Equities only

**4. earnings_nlp.py — Earnings Call Sentiment**
- Input: Latest 8-K filing text (earnings press release) from SEC EDGAR
- FinBERT (HuggingFace transformers) for sentiment classification
- Tone surprise = sentiment vs earnings direction mismatch
- Scores: Aligned positive +0.5, sandbagging +0.3, deception flag -0.7
- Equities only

**5. employee_sentiment.py — Glassdoor/Employee Signal**
- Input: Glassdoor overall rating (scraped or cached)
- QoQ trend matters more than absolute rating
- Scores: Rising +0.6, falling -0.6, stable high +0.3, stable low -0.3
- Gracefully degrades to 0.0 if scraping fails
- Equities only

### Scheduler Integration
- New cron job `compute_signals` at 7 AM ET daily
- Computes all applicable signals for all tracked assets
- Stores results in SignalScore table

### New Dependencies
- `textstat` — readability metrics
- `pysentiment2` — Loughran-McDonald dictionary
- `transformers` + `torch` — FinBERT (~500MB first download)
- `edgartools` — SEC EDGAR Form 4 parsing

### QA Gate 2
- Unit tests for each signal calculator with fixture data (~25 tests)
- Integration test: seed -> ingest -> compute signals -> verify SignalScore rows
- Edge cases: missing data, crypto assets (should skip equity-only signals)

---

## Layer 3: Enhanced Orchestrator

### Search Agent Changes
- After gathering DataSnapshots, also query latest SignalScore rows
- Append "Quantitative Signal Summary" section to data bundle:
  ```
  === QUANTITATIVE SIGNALS ===
  Lifecycle: MATURITY (+0.7) — Operating CF positive, investing CF negative...
  Insider Activity: NET BUYING (+0.5) — 3 purchases, 1 sale in 90 days...
  ```

### Agent Prompt Updates
- **Analyst Agent**: Reference quantitative signals, weigh alongside fundamentals, call out conflicts
- **Risk Agent**: Flag worsening readability or heavy insider selling as independent red flags
- **Sentiment Agent**: Unchanged (handles crowd sentiment, no overlap)

### Synthesizer Changes
- Weighted score: `final_score = 0.6 * rule_score + 0.4 * avg_signal_score`
- Missing signals excluded from average (not zeroed)
- Crypto assets use only applicable signals

### 3 New Golden Rules
1. "Lifecycle Stage Alignment" (equity, weight=0.7)
2. "Insider Conviction Signal" (equity, weight=0.8)
3. "Linguistic Red Flag Detector" (equity, weight=0.6)

### QA Gate 3
- Integration test: full pipeline with signal scores included (~10 tests)
- Verify LLM prompt contains signal summary text
- Verify synthesizer blends scores correctly
- Test with crypto asset (equity-only signals excluded gracefully)

---

## Layer 4: Auto-Scanner & Market Intelligence

### New Scheduler Job: auto_scan
- Runs daily at 8 AM ET (after signal computation at 7 AM)
- Iterates all tracked assets, runs full orchestrator for each
- 5-second delay between assets (Groq rate limit: 30 req/min)
- ~30 assets x 5 LLM calls = ~150 calls over ~12 minutes
- STRONG_BUY or STRONG_SELL signals pushed to ntfy immediately

### New Endpoint: GET /api/dashboard/summary
- Top 5 buy opportunities (highest confidence BUY/STRONG_BUY)
- Top 5 risk alerts (highest confidence SELL/STRONG_SELL)
- Signal score leaders/laggards across all assets
- Stale data warnings (snapshots > 24h old)

### QA Gate 4
- End-to-end test: trigger scan, verify signals generated (~8 tests)
- Verify ntfy alerts for strong signals
- Test rate limiting doesn't exceed Groq free tier

---

## Layer 5: Frontend Enhancements

### Dashboard Updates
- New "Market Pulse" section: top opportunities + risk alerts
- Asset cards show signal score dots (green/yellow/red)
- "Scan All" button triggers bulk ingest + auto-scan
- Last scan timestamp

### New Page: /signals/scores
- Table of all assets with signal score columns
- Sortable: Asset, Lifecycle, Insider, Readability, Earnings NLP, Employee, Composite
- Color-coded cells (green positive, red negative, gray N/A)
- Click row -> existing SignalDetail page
- Filter by asset class

### QA Gate 5
- Manual verification via preview tools
- Screenshot dashboard, verify signal scores table
- Check responsive layout

---

## Test Target

136 existing + ~44 new = ~180 total tests

## Architecture Principles

- Signal calculators are pure functions (no LLM, no side effects) — fast and testable
- Signals degrade gracefully — missing data produces score=0.0, not errors
- Crypto assets skip equity-only signals automatically
- Rate limits respected everywhere — Groq 30 req/min, yfinance 1 req/sec, CoinGecko 2 sec
- Each layer delivers standalone value — Layer 1 alone transforms the app
