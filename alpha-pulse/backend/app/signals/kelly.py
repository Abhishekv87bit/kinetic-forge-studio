"""Kelly Criterion position sizing (Edward Thorp, Beat the Dealer).

Full Kelly: f* = (p * b - q) / b
  p = win probability
  b = win/loss ratio (avg_win / avg_loss)
  q = 1 - p

Half Kelly: f*/2 -- recommended for real trading.
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

    # No edge or negative edge -> don't bet
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
