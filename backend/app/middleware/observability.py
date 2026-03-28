"""SC-10 Observability Wiring — cross-cutting timing and LLM call tracking.

Two public interfaces:

* :func:`observe_llm_call` — async function decorator.  Wrap any coroutine
  that makes an LLM/VLM call so its timing and outcome are recorded
  automatically.

* :func:`log_execution` — standalone coroutine.  Call it explicitly around
  non-LLM timed events (e.g. subprocess execution, VLAD runs) where a
  decorator is inconvenient.

Both write structured records via the standard :mod:`logging` module so that
the host application's log handler (file, stdout, LangFuse sink, etc.) decides
where they land.  No external dependencies are required.
"""
from __future__ import annotations

import functools
import logging
import time
from typing import Any, Awaitable, Callable, Dict, Optional

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# LLM call decorator
# ---------------------------------------------------------------------------


def observe_llm_call(func: Callable[..., Awaitable[Any]]) -> Callable[..., Awaitable[Any]]:
    """Decorator that records timing and outcome for async LLM/VLM calls.

    Usage::

        @observe_llm_call
        async def _call_llm(self, prompt: str) -> str:
            ...

    The decorator logs a structured record with:
    - ``component``: the class name extracted from ``func.__qualname__``
    - ``action``: the function name
    - ``status``: ``"success"`` or ``"failure"``
    - ``duration_s``: wall-clock seconds as a float
    - ``error``: exception message on failure (omitted on success)
    """

    @functools.wraps(func)
    async def _wrapper(*args: Any, **kwargs: Any) -> Any:
        # Derive a component name from "ClassName.method_name" → "ClassName"
        parts = func.__qualname__.split(".")
        component = parts[-2] if len(parts) >= 2 else parts[0]
        action = func.__name__
        start = time.perf_counter()
        try:
            result = await func(*args, **kwargs)
            duration = time.perf_counter() - start
            logger.info(
                "[OBSERVE_LLM] component=%s action=%s status=success duration_s=%.4f",
                component,
                action,
                duration,
            )
            return result
        except Exception as exc:
            duration = time.perf_counter() - start
            logger.warning(
                "[OBSERVE_LLM] component=%s action=%s status=failure duration_s=%.4f error=%s",
                component,
                action,
                duration,
                exc,
            )
            raise

    return _wrapper


# ---------------------------------------------------------------------------
# Generic execution timing helper
# ---------------------------------------------------------------------------


async def log_execution(
    component_name: str,
    action: str,
    status: str,
    duration_s: float,
    details: Optional[Dict[str, Any]] = None,
) -> None:
    """Record a timed execution event for non-LLM operations.

    Intended to be called explicitly inside a ``try/finally`` block::

        start = time.perf_counter()
        status = "failure"
        try:
            await do_work()
            status = "success"
        finally:
            await log_execution("ModuleExecutor", "execute", status,
                                time.perf_counter() - start,
                                {"module_id": module_id})

    Parameters
    ----------
    component_name:
        Human-readable name of the calling component (e.g. ``"ModuleExecutor"``).
    action:
        Name of the specific operation (e.g. ``"execute"``).
    status:
        Outcome string — by convention ``"success"`` or ``"failure"``.
    duration_s:
        Elapsed wall-clock time in seconds.
    details:
        Optional mapping of extra key/value context (module ids, error
        messages, file paths, etc.).
    """
    logger.info(
        "[EXECUTION] component=%s action=%s status=%s duration_s=%.4f details=%s",
        component_name,
        action,
        status,
        duration_s,
        details or {},
    )


def log_execution_sync(
    component_name: str,
    action: str,
    status: str,
    duration_s: float,
    details: Optional[Dict[str, Any]] = None,
) -> None:
    """Synchronous counterpart to :func:`log_execution` for non-async callers.

    Identical output format; use this from synchronous code such as
    :class:`~backend.app.services.vlad_runner.VladRunner` where awaiting an
    async helper is not possible without introducing an event-loop dependency.
    """
    logger.info(
        "[EXECUTION] component=%s action=%s status=%s duration_s=%.4f details=%s",
        component_name,
        action,
        status,
        duration_s,
        details or {},
    )
