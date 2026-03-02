"""Tests for the Orchestrator — end-to-end pipeline with mocked Claude."""

from unittest.mock import patch, AsyncMock

from sqlalchemy import select

from app.agents.analyst_agent import AnalystOutput, Insight
from app.agents.orchestrator import run_analysis
from app.agents.risk_agent import RiskOutput, RedFlag
from app.agents.sentiment_agent import SentimentOutput
from app.agents.synthesizer import RuleEvaluation
from app.db.models import Asset, DataSnapshot, GoldenRule, Signal
from app.validation.fact_checker import check_facts


# ── Fixtures ──────────────────────────────────────────────────────


def _seed_asset_and_snapshots(db_session):
    """Helper to create test asset with snapshots."""
    asset = Asset(id="AAPL", asset_class="equity", name="Apple Inc.")

    snapshots = [
        DataSnapshot(
            asset_id="AAPL",
            source="price",
            raw_data={
                "close": 175.50,
                "change_pct": 2.1,
                "volume": 50_000_000,
                "sma_20": 172.0,
                "sma_50": 168.0,
            },
            period="2026-03-01",
        ),
        DataSnapshot(
            asset_id="AAPL",
            source="sentiment",
            raw_data={
                "reddit": {"post_count": 25, "avg_score": 200.0, "total_comments": 500},
                "news": {"article_count": 5, "articles": []},
                "fear_greed": {"score": 55, "rating": "neutral"},
            },
            period="2026-03-01",
        ),
        DataSnapshot(
            asset_id="AAPL",
            source="sec_filing",
            raw_data={
                "filings": [
                    {
                        "filing_type": "10-K",
                        "sections": {
                            "risk_factors": "Standard business risks. No litigation pending.",
                            "mda": "Revenue grew 8% YoY. Margins stable at 30%.",
                        },
                        "text_length": 30000,
                    }
                ]
            },
            period="2026-02-28",
        ),
    ]

    rules = [
        GoldenRule(
            name="Momentum Check",
            description="Is the stock trending upward?",
            rule_prompt="Check if price is above SMA 20 and SMA 50. Score bullish if above both.",
            asset_class="equity",
            weight=0.6,
            active=True,
        ),
        GoldenRule(
            name="Fundamental Health",
            description="Are the company fundamentals strong?",
            rule_prompt="Check revenue growth and margins. Score bullish if growing with stable margins.",
            asset_class="equity",
            weight=0.8,
            active=True,
        ),
        GoldenRule(
            name="Sentiment Pulse",
            description="What does the crowd think?",
            rule_prompt="Check Reddit and news sentiment. Score bullish if majority positive.",
            asset_class=None,  # Applies to all asset classes
            weight=0.4,
            active=True,
        ),
    ]

    return asset, snapshots, rules


# ── Mock responses ────────────────────────────────────────────────


MOCK_ANALYST = AnalystOutput(
    revenue_growth=8.0,
    operating_margin=30.0,
    key_metrics={"sma_trend": "bullish", "volume": "50M"},
    insights=[
        Insight(
            headline="Revenue is growing steadily",
            detail="8% growth is solid and sustainable.",
            signal="bullish",
        ),
    ],
    bottom_line="Apple looks healthy — growing revenue with stable margins.",
    strengths=["Revenue growing 8%", "Margins holding at 30%"],
    concerns=["Standard business risks"],
    outlook="positive",
    confidence_note="Good data coverage.",
)

MOCK_RISK = RiskOutput(
    red_flags=[],
    overall_risk_level="low",
    risk_summary="No significant red flags. Standard business risks only.",
    watch_items=["Monitor next earnings for continued growth"],
)

MOCK_SENTIMENT = SentimentOutput(
    overall_sentiment="bullish",
    confidence=0.65,
    crowd_mood="Reddit is moderately positive. Fear & Greed is neutral.",
    reddit_read="25 posts, average sentiment positive.",
    news_read="5 articles, mixed coverage.",
    fear_greed_read="Score of 55 — neither scared nor greedy.",
    contrarian_note="Sentiment isn't extreme, which is healthy.",
)

MOCK_RULE_EVAL = RuleEvaluation(
    rule_name="placeholder",
    rule_id=0,
    direction="bullish",
    score=0.7,
    reasoning="Price above moving averages, fundamentals solid.",
)


# ── Tests ─────────────────────────────────────────────────────────


async def test_full_pipeline_produces_signal(db_session):
    """End-to-end: should gather data, run agents, synthesize, and save a Signal."""
    asset, snapshots, rules = _seed_asset_and_snapshots(db_session)
    db_session.add(asset)
    for s in snapshots:
        db_session.add(s)
    for r in rules:
        db_session.add(r)
    await db_session.commit()

    with patch("app.agents.analyst_agent.call_claude", new_callable=AsyncMock) as mock_analyst, \
         patch("app.agents.risk_agent.call_claude", new_callable=AsyncMock) as mock_risk, \
         patch("app.agents.sentiment_agent.call_claude", new_callable=AsyncMock) as mock_sentiment, \
         patch("app.agents.synthesizer.call_claude", new_callable=AsyncMock) as mock_synth:

        mock_analyst.return_value = MOCK_ANALYST
        mock_risk.return_value = MOCK_RISK
        mock_sentiment.return_value = MOCK_SENTIMENT
        mock_synth.return_value = MOCK_RULE_EVAL  # Called once per rule

        result = await run_analysis(db_session, "AAPL")

    # Should have all pipeline outputs
    assert result["asset_id"] == "AAPL"
    assert result["signal_type"] in ("strong_buy", "buy", "hold", "sell", "strong_sell")
    assert 0.0 <= result["confidence"] <= 1.0
    assert "analyst" in result
    assert "risk" in result
    assert "sentiment" in result
    assert "synthesis" in result
    assert "fact_check" in result
    assert result["signal_id"] is not None

    # Signal should be in DB
    db_result = await db_session.execute(
        select(Signal).where(Signal.asset_id == "AAPL")
    )
    signal = db_result.scalar_one()
    assert signal.signal_type == result["signal_type"]
    assert signal.confidence == result["confidence"]
    assert len(signal.evidence) == 3  # analyst + risk + sentiment


async def test_pipeline_parallel_agents(db_session):
    """Analyst and sentiment should run in parallel (both get called)."""
    asset, snapshots, rules = _seed_asset_and_snapshots(db_session)
    db_session.add(asset)
    for s in snapshots:
        db_session.add(s)
    for r in rules:
        db_session.add(r)
    await db_session.commit()

    with patch("app.agents.analyst_agent.call_claude", new_callable=AsyncMock) as mock_analyst, \
         patch("app.agents.risk_agent.call_claude", new_callable=AsyncMock) as mock_risk, \
         patch("app.agents.sentiment_agent.call_claude", new_callable=AsyncMock) as mock_sentiment, \
         patch("app.agents.synthesizer.call_claude", new_callable=AsyncMock) as mock_synth:

        mock_analyst.return_value = MOCK_ANALYST
        mock_risk.return_value = MOCK_RISK
        mock_sentiment.return_value = MOCK_SENTIMENT
        mock_synth.return_value = MOCK_RULE_EVAL

        await run_analysis(db_session, "AAPL")

    # Both analyst and sentiment should have been called
    mock_analyst.assert_called_once()
    mock_sentiment.assert_called_once()
    mock_risk.assert_called_once()
    # Synthesizer called once per active rule (3 rules)
    assert mock_synth.call_count == 3


async def test_pipeline_no_rules_still_works(db_session):
    """Pipeline should produce a hold signal when no Golden Rules exist."""
    asset = Asset(id="TSLA", asset_class="equity", name="Tesla Inc.")
    db_session.add(asset)
    db_session.add(DataSnapshot(
        asset_id="TSLA", source="price",
        raw_data={"close": 250.0}, period="2026-03-01",
    ))
    await db_session.commit()

    with patch("app.agents.analyst_agent.call_claude", new_callable=AsyncMock) as mock_analyst, \
         patch("app.agents.risk_agent.call_claude", new_callable=AsyncMock) as mock_risk, \
         patch("app.agents.sentiment_agent.call_claude", new_callable=AsyncMock) as mock_sentiment:

        mock_analyst.return_value = MOCK_ANALYST
        mock_risk.return_value = MOCK_RISK
        mock_sentiment.return_value = MOCK_SENTIMENT

        result = await run_analysis(db_session, "TSLA")

    # No rules → hold signal
    assert result["signal_type"] == "hold"
    assert result["synthesis"]["rule_evaluations"] == []


async def test_fact_checker_catches_bad_numbers():
    """Fact checker should flag when analyst numbers don't match raw data."""
    analyst_data = {
        "revenue_growth": 8.0,
        "operating_margin": 30.0,
        "key_metrics": {"close": "200.00", "volume": "50M"},
    }
    raw_data = {
        "price": {"close": 175.50, "volume": 50_000_000},
    }

    result = check_facts(analyst_data, raw_data)

    # Price mismatch: analyst said 200, actual is 175.50 — that's ~14% off
    assert len(result.mismatches) >= 1
    price_mismatch = [m for m in result.mismatches if m.field == "close_price"]
    assert len(price_mismatch) == 1
    assert price_mismatch[0].severity in ("notable", "major")


async def test_fact_checker_passes_clean_data():
    """Fact checker should pass when numbers are consistent."""
    analyst_data = {
        "revenue_growth": 8.0,
        "operating_margin": 30.0,
        "key_metrics": {},
    }
    raw_data = {
        "price": {"close": 175.50, "volume": 50_000_000},
    }

    result = check_facts(analyst_data, raw_data)

    assert result.passed is True
    assert len(result.mismatches) == 0


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
