"""SC-06 Durga Pattern — three-tier deterministic/VLM/LLM repair escalation.

Tier 1 (deterministic): regex-based pattern fixes defined in durga_rules.py.
Tier 2 (vlm):           vision-language model analysis (placeholder; not yet wired).
Tier 3 (llm):           LLM escalation via the existing ChatAgent.

The engine is intentionally stateless — callers supply the broken code and raw
error string and receive a RepairResult describing what was done.
"""
from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from typing import Optional

from backend.app.middleware.observability import observe_llm_call
from backend.app.services.durga_rules import DETERMINISTIC_RULES

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Value object
# ---------------------------------------------------------------------------


@dataclass
class RepairResult:
    """Outcome of a single repair attempt.

    Attributes:
        success:         True when a corrected code string was produced.
        tier_used:       Which tier produced the result:
                         ``"deterministic"``, ``"vlm"``, ``"llm"``, or ``"failed"``.
        fixed_code:      The repaired code (populated on success).
        error_message:   Why repair failed (populated on failure).
        rule_name:       Which DETERMINISTIC_RULES entry fired (tier 1 only).
        llm_explanation: Raw LLM response text (tier 3 only).
    """

    success: bool
    tier_used: str
    fixed_code: Optional[str] = None
    error_message: Optional[str] = None
    rule_name: Optional[str] = None
    llm_explanation: Optional[str] = None


# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------


class DurgaRepairEngine:
    """Three-tier repair escalation for failed CadQuery executions.

    Args:
        chat_agent: An object with an async ``chat(prompt: str) -> str`` method
                    used for tier-3 LLM escalation.  Pass ``None`` to disable
                    tier 3 (the engine will return ``tier_used="failed"``).
    """

    def __init__(self, chat_agent=None) -> None:
        self._chat_agent = chat_agent

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    async def attempt_repair(self, code: str, error: str) -> RepairResult:
        """Attempt to repair *code* that produced *error*.

        Tiers are tried in order; the first success short-circuits the rest.

        Returns:
            A :class:`RepairResult` with ``tier_used`` indicating which tier
            produced the result (or ``"failed"`` if all tiers were exhausted).
        """
        # ── Tier 1: deterministic ──────────────────────────────────────
        result = self._try_deterministic(code, error)
        if result is not None:
            return result

        # ── Tier 2: VLM (placeholder) ─────────────────────────────────
        # Will be wired in a future SC when a VLM endpoint is available.
        logger.debug("VLM tier skipped — not yet implemented")

        # ── Tier 3: LLM via ChatAgent ──────────────────────────────────
        if self._chat_agent is not None:
            return await self._try_llm(code, error)

        return RepairResult(
            success=False,
            tier_used="failed",
            error_message=(
                f"No deterministic rule matched and no LLM agent configured. "
                f"Original error: {error}"
            ),
        )

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _try_deterministic(self, code: str, error: str) -> Optional[RepairResult]:
        """Scan DETERMINISTIC_RULES and return a result on the first match."""
        for rule in DETERMINISTIC_RULES:
            match = re.search(rule.error_pattern, error)
            if match:
                logger.info(
                    "Durga tier=deterministic rule=%r matched error=%r",
                    rule.name,
                    error[:120],
                )
                try:
                    fixed_code = rule.apply(code, error, match)
                    return RepairResult(
                        success=True,
                        tier_used="deterministic",
                        fixed_code=fixed_code,
                        rule_name=rule.name,
                    )
                except Exception as exc:  # noqa: BLE001
                    logger.warning(
                        "Durga rule %r raised during apply: %s", rule.name, exc
                    )
        return None

    @observe_llm_call
    async def _try_llm(self, code: str, error: str) -> RepairResult:
        """Escalate to the ChatAgent for a free-form LLM fix."""
        prompt = (
            "The following CadQuery Python code failed to execute.\n\n"
            f"Error:\n{error}\n\n"
            f"Code:\n```python\n{code}\n```\n\n"
            "Return ONLY the corrected Python code inside a ```python ... ``` block."
        )
        try:
            response = await self._chat_agent.chat(prompt)
            fixed_code = _extract_code_block(response)
            logger.info("Durga tier=llm repair succeeded")
            return RepairResult(
                success=True,
                tier_used="llm",
                fixed_code=fixed_code,
                llm_explanation=response,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("Durga tier=llm failed: %s", exc)
            return RepairResult(
                success=False,
                tier_used="llm",
                error_message=str(exc),
            )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _extract_code_block(text: str) -> str:
    """Extract Python code from a markdown fenced block, or return raw text."""
    match = re.search(r"```python\n(.*?)```", text, re.DOTALL)
    if match:
        return match.group(1).strip()
    match = re.search(r"```\n(.*?)```", text, re.DOTALL)
    if match:
        return match.group(1).strip()
    return text.strip()
