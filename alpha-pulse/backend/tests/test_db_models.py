from sqlalchemy import select
from app.db.models import Asset, DataSnapshot, GoldenRule, Signal, PaperTrade, AlertLog, SignalScore


async def test_create_asset(db_session):
    asset = Asset(id="AAPL", asset_class="equity", name="Apple Inc.")
    db_session.add(asset)
    await db_session.commit()
    assert asset.id == "AAPL"
    assert asset.tracked is True


async def test_create_signal_with_evidence(db_session):
    asset = Asset(id="AAPL", asset_class="equity", name="Apple Inc.")
    db_session.add(asset)
    await db_session.commit()

    signal = Signal(
        asset_id="AAPL",
        signal_type="buy",
        confidence=0.78,
        summary="Debt reduction + margin expansion",
        evidence=[{"rule_id": 1, "passed": True, "reason": "3Q debt decrease"}],
        risk_flags=[],
        raw_llm={"model": "test"},
    )
    db_session.add(signal)
    await db_session.commit()
    assert signal.id is not None
    assert signal.confidence == 0.78


async def test_create_golden_rule(db_session):
    rule = GoldenRule(
        name="Debt Reduction",
        description="Check 3Q consecutive debt decrease",
        rule_prompt="Evaluate whether...",
        asset_class="equity",
        weight=0.8,
    )
    db_session.add(rule)
    await db_session.commit()
    assert rule.active is True
    assert rule.weight == 0.8


async def test_paper_trade_requires_signal(db_session):
    asset = Asset(id="BTC-USD", asset_class="crypto", name="Bitcoin")
    db_session.add(asset)
    await db_session.commit()

    signal = Signal(
        asset_id="BTC-USD",
        signal_type="strong_buy",
        confidence=0.92,
        summary="Momentum",
        evidence=[],
        risk_flags=[],
        raw_llm={},
    )
    db_session.add(signal)
    await db_session.commit()

    trade = PaperTrade(
        signal_id=signal.id,
        asset_id="BTC-USD",
        action="buy",
        quantity=0.5,
        price_at=45000.0,
    )
    db_session.add(trade)
    await db_session.commit()
    assert trade.status == "open"
    assert trade.price_at == 45000.0


async def test_signal_score_crud(db_session):
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

    result = await db_session.execute(
        select(SignalScore).where(SignalScore.asset_id == "TEST")
    )
    saved = result.scalar_one()
    assert saved.signal_name == "lifecycle"
    assert saved.score == 0.7
    assert saved.details["stage"] == "maturity"
