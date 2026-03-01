# Alpha Pulse — Agentic Investment Pipeline

**Date**: 2026-02-28
**Status**: Approved
**Architecture**: Monolithic (FastAPI + React), modular internals

---

## Overview

Alpha Pulse is an AI-powered financial research pipeline that automates fundamental analysis across multiple asset classes (equities, crypto, commodities, forex). It ingests data from diverse sources, evaluates it against user-defined "Golden Rules" using Claude, and emits structured signals (BUY/HOLD/SELL) with confidence scores and evidence trails. Includes paper trading for backtesting rule effectiveness.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | Monolithic | Fastest to ship for solo dev. Clean module boundaries allow future extraction. |
| LLM | Claude API only (Sonnet 4) | Single billing, excellent structured extraction, user has API key. |
| Automation level | Research + paper trading | Full feedback loop without real-money risk. |
| Interface | CLI + web dashboard | Power users get CLI, visual overview via React dashboard. |
| Database | SQLite (dev) → PostgreSQL (prod) | Zero-config start, migrate when scaling. |
| Agent framework | None (plain Python functions) | No LangGraph/CrewAI lock-in. Functions that call Claude with specific prompts. Debuggable. |
| Fact-checking | Programmatic (Pandas) | Never let LLM do math. Extract numbers → verify with Python. |

---

## Project Structure

```
alpha-pulse/
├── backend/
│   ├── app/
│   │   ├── main.py                 # FastAPI entry point
│   │   ├── config.py               # Settings (API keys, schedules, thresholds)
│   │   ├── db/
│   │   │   ├── database.py         # SQLAlchemy + SQLite
│   │   │   └── models.py           # ORM models
│   │   ├── ingestion/              # Layer 1: Data sources
│   │   │   ├── sec_edgar.py        # SEC filing scraper
│   │   │   ├── market_data.py      # Price/volume (yfinance, Alpha Vantage)
│   │   │   ├── crypto_data.py      # CoinGecko / exchange APIs
│   │   │   ├── macro_data.py       # FRED (interest rates, CPI)
│   │   │   ├── sentiment.py        # Reddit, news, Fear & Greed
│   │   │   └── scheduler.py        # APScheduler for periodic pulls
│   │   ├── agents/                 # Layer 2: AI evaluation
│   │   │   ├── orchestrator.py     # Runs the agent pipeline
│   │   │   ├── search_agent.py     # Retrieves relevant data for ticker
│   │   │   ├── analyst_agent.py    # Extracts KPIs, compares to consensus
│   │   │   ├── risk_agent.py       # Red flag detection
│   │   │   ├── sentiment_agent.py  # NLP sentiment scoring
│   │   │   └── synthesizer.py      # Applies Golden Rules, produces signal
│   │   ├── rules/                  # Layer 2.5: Golden Rules engine
│   │   │   ├── engine.py           # Rule evaluator
│   │   │   └── default_rules.py    # Starter rule set
│   │   ├── validation/             # Layer 3: Anti-hallucination
│   │   │   ├── schema.py           # Pydantic models for structured output
│   │   │   ├── fact_checker.py     # Verify numbers against source data
│   │   │   └── confidence.py       # Confidence scoring logic
│   │   ├── paper_trading/          # Layer 4a: Simulated execution
│   │   │   ├── engine.py           # Paper trade execution engine
│   │   │   ├── portfolio.py        # Virtual portfolio state
│   │   │   └── performance.py      # P&L, Sharpe, drawdown tracking
│   │   ├── alerts/                 # Layer 4b: Notifications
│   │   │   ├── ntfy.py             # ntfy.sh push notifications
│   │   │   └── dispatcher.py       # Route alerts by priority
│   │   └── routes/                 # API endpoints
│   │       ├── assets.py           # CRUD for tracked assets
│   │       ├── signals.py          # View AI-generated signals
│   │       ├── rules.py            # Manage Golden Rules
│   │       ├── portfolio.py        # Paper portfolio state
│   │       └── analysis.py         # Trigger on-demand analysis
│   ├── tests/
│   └── pyproject.toml
├── frontend/                       # React + TypeScript dashboard
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard.tsx       # Main overview
│   │   │   ├── SignalCard.tsx      # Individual signal display
│   │   │   ├── RuleEditor.tsx     # Create/edit Golden Rules
│   │   │   ├── PortfolioView.tsx  # Paper trading performance
│   │   │   ├── AssetDetail.tsx    # Deep-dive on single asset
│   │   │   └── AlertHistory.tsx   # Past notifications
│   │   └── api/
│   │       └── client.ts
│   └── package.json
├── cli/
│   └── alpha_pulse_cli.py          # Click-based CLI
└── docs/
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Python 3.12 (strict type hints) |
| Backend | FastAPI, SQLAlchemy, APScheduler |
| Frontend | React 18, TypeScript, Vite, Recharts, TanStack Query |
| Database | SQLite (dev) → PostgreSQL (prod) |
| AI | Claude Sonnet 4 (Anthropic SDK) |
| Alerts | ntfy.sh (topic: existing user topic) |
| CLI | Click |
| Validation | Pydantic v2 |

---

## Database Schema

### assets
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Ticker symbol (e.g., "AAPL", "BTC-USD") |
| asset_class | ENUM | equity, crypto, commodity, forex |
| name | TEXT | Human-readable name |
| tracked | BOOL | Actively monitored |
| metadata | JSON | Sector, exchange, market_cap_tier, etc. |
| created_at | DATETIME | |

### data_snapshots
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| asset_id | FK → assets | |
| source | ENUM | sec_filing, earnings, price, sentiment, macro |
| source_url | TEXT | Provenance link |
| raw_data | JSON | Extracted data |
| period | TEXT | "2025-Q4", "2026-02-28" |
| fetched_at | DATETIME | |

### golden_rules
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| name | TEXT | Human-readable rule name |
| description | TEXT | Explanation |
| rule_prompt | TEXT | Prompt fragment sent to Claude |
| asset_class | ENUM or NULL | NULL = applies to all |
| weight | FLOAT | 0.0-1.0, for weighted scoring |
| active | BOOL | |
| created_at | DATETIME | |

### signals
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| asset_id | FK → assets | |
| signal_type | ENUM | strong_buy, buy, hold, sell, strong_sell |
| confidence | FLOAT | 0.0-1.0 |
| summary | TEXT | 1-2 sentence explanation |
| evidence | JSON | [{rule_id, passed, reason, source_ref}] |
| risk_flags | JSON | List of detected red flags |
| raw_llm | JSON | Full Claude response (audit trail) |
| created_at | DATETIME | |

### paper_trades
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| signal_id | FK → signals | What triggered this trade |
| asset_id | FK → assets | |
| action | ENUM | buy, sell |
| quantity | FLOAT | |
| price_at | FLOAT | Price when signal generated |
| price_now | FLOAT | Current price (updated periodically) |
| pnl | FLOAT | Unrealized P&L |
| status | ENUM | open, closed |
| opened_at | DATETIME | |
| closed_at | DATETIME or NULL | |

### backtest_runs
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| name | TEXT | "Q4 2025 rules vs S&P 500" |
| rule_ids | JSON | List of golden_rule IDs tested |
| date_from | DATE | |
| date_to | DATE | |
| asset_ids | JSON | Asset universe |
| initial_capital | FLOAT | |
| config | JSON | Position sizing, max drawdown, etc. |
| created_at | DATETIME | |

### backtest_results
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| run_id | FK → backtest_runs | |
| total_return | FLOAT | % |
| sharpe_ratio | FLOAT | |
| max_drawdown | FLOAT | % |
| win_rate | FLOAT | % |
| trades | JSON | List of simulated trades |
| equity_curve | JSON | Daily portfolio values |
| benchmark | JSON | S&P 500 / BTC comparison |

### alert_log
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | |
| signal_id | FK → signals or NULL | |
| channel | ENUM | ntfy, console, dashboard |
| priority | ENUM | urgent, high, default, low |
| message | TEXT | |
| sent_at | DATETIME | |
| acknowledged | BOOL | |

---

## Data Source Integrations

### Equities

| Source | Data | Library/API | Rate Limit | Cost |
|--------|------|------------|------------|------|
| SEC EDGAR | 10-K, 10-Q, 8-K filings | sec-edgar-downloader | 10 req/sec | Free |
| yfinance | Price, volume, fundamentals | yfinance | ~2000/hr | Free |
| Alpha Vantage | Earnings, financials | REST API | 25/day free | Free/$50 |
| Financial Modeling Prep | Ratios, DCF, insider trades | REST API | 250/day free | Free/$20 |

### Crypto

| Source | Data | API | Rate Limit | Cost |
|--------|------|-----|------------|------|
| CoinGecko | Price, market cap, trending | REST API | 30/min | Free |
| CryptoCompare | Social stats, on-chain | REST API | 100K/month | Free |

### Macro & Sentiment

| Source | Data | API | Rate Limit | Cost |
|--------|------|-----|------------|------|
| FRED | Interest rates, CPI, unemployment | fredapi | 120/min | Free |
| CNN Fear & Greed | Sentiment index | Scrape | Gentle | Free |
| Reddit | WSB, r/stocks, r/crypto | PRAW | 60/min | Free |
| NewsAPI | Headlines 80K+ sources | REST API | 100/day | Free |

### Ingestion Schedule

```python
SCHEDULES = {
    "market_data":   "*/15 * * * *",    # Every 15 min (market hours)
    "crypto_data":   "*/30 * * * *",    # Every 30 min (24/7)
    "sec_filings":   "0 */4 * * *",     # Every 4 hours
    "macro_data":    "0 9 * * *",       # Daily 9 AM
    "sentiment":     "0 */2 * * *",     # Every 2 hours
    "news":          "*/30 * * * *",    # Every 30 min
}
```

---

## Agent Pipeline

```
User triggers analysis (CLI: `ap analyze AAPL` or Dashboard: [Run Analysis])
         │
         ▼
┌─────────────────┐    For each tracked asset:
│   Orchestrator   │───────────────────────────────────┐
└────────┬────────┘                                    │
         │                                             │
         ▼                                             ▼
┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Search Agent   │  │  Analyst Agent   │  │ Sentiment Agent  │
│ (query local DB │  │ (extract KPIs,   │  │ (Reddit, news,   │
│  for relevant   │  │  compare to      │  │  Fear & Greed)   │
│  data_snapshots)│  │  consensus)      │  │                  │
└────────┬────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                    │                      │
         └────────────────────┼──────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Risk Agent     │
                    │ (red flags,      │
                    │  litigation,     │
                    │  insider sells)  │
                    └────────┬─────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Synthesizer    │
                    │ (apply Golden    │
                    │  Rules, weighted │
                    │  scoring)        │
                    └────────┬─────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Fact Checker    │
                    │ (Pandas/Python,  │
                    │  NOT LLM math)   │
                    └────────┬─────────┘
                              │
                              ▼
                    Signal → DB + Dashboard + Alert
```

### Agent Design Principles

1. **Agents are Python functions**, not framework nodes. Each calls Claude with a specific prompt and returns structured data.
2. **Search/Analyst/Sentiment run in parallel** (asyncio.gather). Risk Agent runs after (needs their output).
3. **Fact Checker uses Pandas**, never a second LLM call for math verification.
4. **Every signal stores `raw_llm`** — the full Claude response for audit trail.
5. **Golden Rules are prompt fragments** stored in DB, injected into Synthesizer's system prompt dynamically.

---

## Golden Rules Engine

### Rule Format

Rules are natural language prompts stored in the DB. Claude evaluates data against each applicable rule and returns structured JSON.

```python
# Example rule_prompt:
"""
Evaluate whether this company's total debt has decreased for 3+ consecutive
quarters while gross profit margin OR operating margin has expanded.
Use the quarterly financial data provided.
Output: {passed: bool, evidence: str, quarters_examined: list}
"""
```

### Synthesizer Scoring

```
Score = sum(rule_weight * rule_score) / sum(rule_weight)

rule_score: 1.0 (passed/bullish), 0.0 (failed/bearish), 0.5 (neutral)

Signal mapping:
  score > 0.80 → STRONG_BUY
  score > 0.65 → BUY
  score > 0.45 → HOLD
  score > 0.30 → SELL
  score <= 0.30 → STRONG_SELL

Confidence = agreement_ratio * data_freshness_factor
  agreement_ratio: % of rules agreeing on direction
  data_freshness: penalty if data > 7 days old
```

### Starter Rules

1. **Debt Reduction + Margin Expansion** (equity, w=0.8)
2. **Insider Selling Red Flag** (equity, w=0.9)
3. **Revenue Growth Trend** (equity, w=0.7)
4. **Crypto Social Momentum** (crypto, w=0.6)
5. **Macro Headwind Detector** (all, w=0.5)

---

## Alert System

```python
ALERT_ROUTING = {
    "urgent":  ["ntfy"],        # STRONG signals with confidence > 0.85
    "high":    ["ntfy"],        # BUY/SELL signals
    "default": ["dashboard"],   # HOLD changes, rule triggers
    "low":     ["dashboard"],   # Data refresh confirmations
}
```

Alerts use ntfy.sh with the user's existing topic. Format:
```
STRONG_SELL: AAPL (confidence: 0.91)
Debt increased 3Q, insider selling 12%, macro risk-off
```

---

## Dashboard Layout

- **Portfolio Summary**: Paper P&L, win rate, Sharpe ratio
- **Active Signals**: Card grid showing signal + confidence per asset
- **Signal Detail**: Expandable view showing rule-by-rule evaluation with evidence
- **Equity Curve**: Recharts line graph of paper portfolio over time
- **Golden Rules**: CRUD interface for managing rules (name, prompt, weight, active)
- **Alert History**: Past notifications with acknowledgment tracking

---

## Safety Protocols

1. **No real money execution** — paper trading only in V1
2. **Hallucination prevention** — all math done in Python, not by LLM
3. **Rate limiting** — respect all API limits, cache-first pattern
4. **Audit trail** — every signal stores full LLM response
5. **Kill switch** — global toggle to pause all analysis and alerts
6. **Data freshness** — confidence penalty for stale data
7. **NOT investment advice** — the tool is a research assistant, user makes all decisions
