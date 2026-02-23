"""
Production Pipeline: Rate Limiter Middleware
=============================================
GAP-PPL-013 — Rate Limiting & Quotas

Setup in main.py:
    from app.middleware.rate_limiter import setup_rate_limiting
    setup_rate_limiting(app)

Per-route usage in route files:
    from app.middleware.rate_limiter import limiter

    @router.post("/")
    @limiter.limit("10/minute")
    async def chat(request: Request, ...):
        ...
"""

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


# Module-level limiter — created immediately so route files can import it.
# setup_rate_limiting() registers it on app.state and adds the error handler.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["60/minute"],
    storage_uri="memory://",  # Use "redis://localhost:6379" for multi-process
)


def setup_rate_limiting(app: FastAPI, default_limit: str = "60/minute") -> Limiter:
    """Attach the module-level limiter to a FastAPI app."""
    limiter.default_limits = [default_limit]
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    return limiter
