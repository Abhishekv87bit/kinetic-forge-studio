"""Contract tests for SC-06 Durga Pattern.

Covers:
- Each DETERMINISTIC_RULES entry has the required fields (schema contract).
- Each rule's error_pattern regex matches its documented target error string.
- attempt_repair returns tier_used="deterministic" for known error patterns.
- attempt_repair returns tier_used="llm" when no deterministic rule matches
  and a ChatAgent is wired (mocked).
- attempt_repair returns tier_used="failed" when no rule matches and no agent.
- RepairResult fields are populated correctly for each outcome.
"""
from __future__ import annotations

import re
import pytest
from unittest.mock import AsyncMock, MagicMock

from backend.app.services.durga import DurgaRepairEngine, RepairResult
from backend.app.services.durga_rules import DETERMINISTIC_RULES, DeterministicRule


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

MINIMAL_CODE = "import cadquery as cq\nresult = cq.Workplane('XY').box(1,1,1)"


# ---------------------------------------------------------------------------
# Schema tests — every rule entry must satisfy the structural contract
# ---------------------------------------------------------------------------


class TestDeterministicRulesSchema:
    """DETERMINISTIC_RULES must be a non-empty list of well-formed DeterministicRule objects."""

    def test_rules_list_is_not_empty(self):
        assert len(DETERMINISTIC_RULES) > 0

    @pytest.mark.parametrize("rule", DETERMINISTIC_RULES, ids=lambda r: r.name)
    def test_rule_is_deterministic_rule_instance(self, rule):
        assert isinstance(rule, DeterministicRule)

    @pytest.mark.parametrize("rule", DETERMINISTIC_RULES, ids=lambda r: r.name)
    def test_rule_name_is_non_empty_string(self, rule):
        assert isinstance(rule.name, str) and rule.name.strip()

    @pytest.mark.parametrize("rule", DETERMINISTIC_RULES, ids=lambda r: r.name)
    def test_rule_error_pattern_is_valid_regex(self, rule):
        # Must compile without raising
        compiled = re.compile(rule.error_pattern)
        assert compiled is not None

    @pytest.mark.parametrize("rule", DETERMINISTIC_RULES, ids=lambda r: r.name)
    def test_rule_description_is_non_empty_string(self, rule):
        assert isinstance(rule.description, str) and rule.description.strip()

    @pytest.mark.parametrize("rule", DETERMINISTIC_RULES, ids=lambda r: r.name)
    def test_rule_apply_is_callable(self, rule):
        assert callable(rule.apply)

    def test_rule_names_are_unique(self):
        names = [r.name for r in DETERMINISTIC_RULES]
        assert len(names) == len(set(names)), "Duplicate rule names found"


# ---------------------------------------------------------------------------
# Pattern matching — each rule must match its documented target error
# ---------------------------------------------------------------------------


# Mapping: rule name → an error string the rule must match
RULE_TARGET_ERRORS = {
    "missing_cq_import": "NameError: name 'cq' is not defined",
    "show_object_undefined": "NameError: name 'show_object' is not defined",
    "invalid_workplane_case": "ValueError: workplane 'xy' is not a valid workplane",
    "missing_result_val": "AttributeError: 'Workplane' object has no attribute 'val'",
    "result_name_not_defined": "NameError: name 'result' is not defined",
}


@pytest.mark.parametrize(
    "rule_name,error_string",
    list(RULE_TARGET_ERRORS.items()),
    ids=list(RULE_TARGET_ERRORS.keys()),
)
def test_deterministic_rule_matches_target_error(rule_name, error_string):
    """Each documented target error string must be matched by its rule's pattern."""
    rule = next((r for r in DETERMINISTIC_RULES if r.name == rule_name), None)
    assert rule is not None, f"Rule {rule_name!r} not found in DETERMINISTIC_RULES"
    assert re.search(rule.error_pattern, error_string), (
        f"Rule {rule_name!r} pattern {rule.error_pattern!r} "
        f"did not match error string {error_string!r}"
    )


def test_no_rule_matches_unrelated_error():
    """A generic Python error unrelated to CadQuery must not match any rule."""
    unrelated = "ZeroDivisionError: division by zero"
    for rule in DETERMINISTIC_RULES:
        assert re.search(rule.error_pattern, unrelated) is None, (
            f"Rule {rule.name!r} unexpectedly matched unrelated error"
        )


# ---------------------------------------------------------------------------
# attempt_repair — deterministic tier
# ---------------------------------------------------------------------------


class TestAttemptRepairDeterministic:
    """attempt_repair must return tier_used="deterministic" for known patterns."""

    @pytest.mark.asyncio
    async def test_missing_cq_import_returns_deterministic_tier(self):
        engine = DurgaRepairEngine()
        code = "result = cq.Workplane('XY').box(1,1,1)"
        error = "NameError: name 'cq' is not defined"

        result = await engine.attempt_repair(code, error)

        assert result.tier_used == "deterministic"
        assert result.success is True

    @pytest.mark.asyncio
    async def test_show_object_returns_deterministic_tier(self):
        engine = DurgaRepairEngine()
        code = "import cadquery as cq\nshow_object(cq.Workplane('XY').box(1,1,1))"
        error = "NameError: name 'show_object' is not defined"

        result = await engine.attempt_repair(code, error)

        assert result.tier_used == "deterministic"
        assert result.success is True

    @pytest.mark.asyncio
    async def test_invalid_workplane_case_returns_deterministic_tier(self):
        engine = DurgaRepairEngine()
        code = "import cadquery as cq\nresult = cq.Workplane('xy').box(1,1,1)"
        error = "ValueError: workplane 'xy' is not a valid workplane"

        result = await engine.attempt_repair(code, error)

        assert result.tier_used == "deterministic"
        assert result.success is True

    @pytest.mark.asyncio
    async def test_result_name_not_defined_returns_deterministic_tier(self):
        engine = DurgaRepairEngine()
        code = "import cadquery as cq\nr = cq.Workplane('XY').box(1,1,1)"
        error = "NameError: name 'result' is not defined"

        result = await engine.attempt_repair(code, error)

        assert result.tier_used == "deterministic"
        assert result.success is True

    @pytest.mark.asyncio
    async def test_deterministic_result_has_rule_name(self):
        engine = DurgaRepairEngine()
        error = "NameError: name 'cq' is not defined"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        # Either matched (rule_name populated) or didn't (but if tier=deterministic, must have it)
        if result.tier_used == "deterministic":
            assert result.rule_name is not None and result.rule_name.strip()

    @pytest.mark.asyncio
    async def test_deterministic_result_fixed_code_is_string(self):
        engine = DurgaRepairEngine()
        code = "result = cq.Workplane('XY').box(1,1,1)"
        error = "NameError: name 'cq' is not defined"

        result = await engine.attempt_repair(code, error)

        assert result.tier_used == "deterministic"
        assert isinstance(result.fixed_code, str)
        assert len(result.fixed_code) > 0

    @pytest.mark.asyncio
    async def test_missing_cq_import_fix_adds_import(self):
        engine = DurgaRepairEngine()
        code = "result = cq.Workplane('XY').box(1,1,1)"
        error = "NameError: name 'cq' is not defined"

        result = await engine.attempt_repair(code, error)

        assert "import cadquery as cq" in result.fixed_code

    @pytest.mark.asyncio
    async def test_show_object_fix_removes_show_object_line(self):
        engine = DurgaRepairEngine()
        code = (
            "import cadquery as cq\n"
            "box = cq.Workplane('XY').box(1,1,1)\n"
            "show_object(box)\n"
            "result = box"
        )
        error = "NameError: name 'show_object' is not defined"

        result = await engine.attempt_repair(code, error)

        assert "show_object" not in result.fixed_code

    @pytest.mark.asyncio
    async def test_workplane_case_fix_capitalises_xy(self):
        engine = DurgaRepairEngine()
        code = "import cadquery as cq\nresult = cq.Workplane('xy').box(1,1,1)"
        error = "ValueError: workplane 'xy' is not a valid workplane"

        result = await engine.attempt_repair(code, error)

        assert "'XY'" in result.fixed_code or '"XY"' in result.fixed_code


# ---------------------------------------------------------------------------
# attempt_repair — LLM fallback tier
# ---------------------------------------------------------------------------


class TestAttemptRepairLLMFallback:
    """When no deterministic rule matches, attempt_repair must fall back to LLM."""

    def _make_chat_agent(self, response: str) -> MagicMock:
        agent = MagicMock()
        agent.chat = AsyncMock(return_value=response)
        return agent

    @pytest.mark.asyncio
    async def test_unknown_error_falls_back_to_llm_tier(self):
        llm_response = "```python\nimport cadquery as cq\nresult = cq.Workplane('XY').box(1,1,1)\n```"
        agent = self._make_chat_agent(llm_response)
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: something CadQuery specific went wrong"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.tier_used == "llm"

    @pytest.mark.asyncio
    async def test_llm_fallback_success_flag_is_true(self):
        llm_response = "```python\nresult = cq.Workplane('XY').box(1,1,1)\n```"
        agent = self._make_chat_agent(llm_response)
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: unknown"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.success is True

    @pytest.mark.asyncio
    async def test_llm_fallback_fixed_code_extracted_from_code_block(self):
        fixed = "result = cq.Workplane('XY').box(2,2,2)"
        llm_response = f"```python\n{fixed}\n```"
        agent = self._make_chat_agent(llm_response)
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: unknown"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.fixed_code == fixed

    @pytest.mark.asyncio
    async def test_llm_fallback_explanation_populated(self):
        llm_response = "```python\nresult = cq.Workplane('XY').box(1,1,1)\n```"
        agent = self._make_chat_agent(llm_response)
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: unknown"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.llm_explanation == llm_response

    @pytest.mark.asyncio
    async def test_llm_fallback_chat_agent_called_once(self):
        agent = self._make_chat_agent("```python\nresult = None\n```")
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: unknown"

        await engine.attempt_repair(MINIMAL_CODE, error)

        agent.chat.assert_called_once()

    @pytest.mark.asyncio
    async def test_llm_fallback_prompt_contains_error(self):
        agent = self._make_chat_agent("```python\nresult = None\n```")
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: this exact string"

        await engine.attempt_repair(MINIMAL_CODE, error)

        call_args = agent.chat.call_args
        prompt = call_args[0][0] if call_args[0] else call_args[1].get("prompt", "")
        assert "SomeObscureError: this exact string" in prompt

    @pytest.mark.asyncio
    async def test_llm_fallback_when_agent_raises_returns_failed_tier(self):
        agent = MagicMock()
        agent.chat = AsyncMock(side_effect=RuntimeError("LLM API down"))
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: unknown"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.tier_used == "llm"
        assert result.success is False
        assert result.error_message is not None

    @pytest.mark.asyncio
    async def test_llm_raw_text_used_when_no_code_block_present(self):
        raw = "result = cq.Workplane('XY').box(1,1,1)"
        agent = self._make_chat_agent(raw)
        engine = DurgaRepairEngine(chat_agent=agent)
        error = "SomeObscureError: unknown"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.fixed_code == raw.strip()


# ---------------------------------------------------------------------------
# attempt_repair — no agent, no match → failed tier
# ---------------------------------------------------------------------------


class TestAttemptRepairNoAgent:
    """When no rule matches and no agent is configured, tier_used must be "failed"."""

    @pytest.mark.asyncio
    async def test_unmatched_error_no_agent_returns_failed_tier(self):
        engine = DurgaRepairEngine(chat_agent=None)
        error = "SomeObscureError: nothing can fix this deterministically"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.tier_used == "failed"

    @pytest.mark.asyncio
    async def test_failed_result_success_is_false(self):
        engine = DurgaRepairEngine(chat_agent=None)
        error = "SomeObscureError: nothing can fix this deterministically"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.success is False

    @pytest.mark.asyncio
    async def test_failed_result_error_message_populated(self):
        engine = DurgaRepairEngine(chat_agent=None)
        error = "SomeObscureError: nothing can fix this deterministically"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.error_message is not None and len(result.error_message) > 0

    @pytest.mark.asyncio
    async def test_failed_result_fixed_code_is_none(self):
        engine = DurgaRepairEngine(chat_agent=None)
        error = "SomeObscureError: nothing can fix this deterministically"

        result = await engine.attempt_repair(MINIMAL_CODE, error)

        assert result.fixed_code is None


# ---------------------------------------------------------------------------
# RepairResult dataclass field contract
# ---------------------------------------------------------------------------


class TestRepairResultFields:
    """RepairResult must expose all required fields with correct types."""

    def test_success_field_exists_and_is_bool(self):
        r = RepairResult(success=True, tier_used="deterministic")
        assert isinstance(r.success, bool)

    def test_tier_used_field_exists_and_is_str(self):
        r = RepairResult(success=True, tier_used="deterministic")
        assert isinstance(r.tier_used, str)

    def test_fixed_code_defaults_to_none(self):
        r = RepairResult(success=False, tier_used="failed")
        assert r.fixed_code is None

    def test_error_message_defaults_to_none(self):
        r = RepairResult(success=True, tier_used="deterministic")
        assert r.error_message is None

    def test_rule_name_defaults_to_none(self):
        r = RepairResult(success=True, tier_used="deterministic")
        assert r.rule_name is None

    def test_llm_explanation_defaults_to_none(self):
        r = RepairResult(success=True, tier_used="llm")
        assert r.llm_explanation is None

    def test_all_fields_settable(self):
        r = RepairResult(
            success=True,
            tier_used="llm",
            fixed_code="result = None",
            error_message=None,
            rule_name=None,
            llm_explanation="Here is the fixed code...",
        )
        assert r.success is True
        assert r.tier_used == "llm"
        assert r.fixed_code == "result = None"
        assert r.llm_explanation == "Here is the fixed code..."

    def test_deterministic_result_has_rule_name_not_llm_explanation(self):
        r = RepairResult(
            success=True,
            tier_used="deterministic",
            fixed_code="import cadquery as cq\nresult = cq.Workplane('XY').box(1,1,1)",
            rule_name="missing_cq_import",
        )
        assert r.rule_name == "missing_cq_import"
        assert r.llm_explanation is None

    def test_llm_result_has_llm_explanation_not_rule_name(self):
        r = RepairResult(
            success=True,
            tier_used="llm",
            fixed_code="result = None",
            llm_explanation="LLM provided this fix.",
        )
        assert r.llm_explanation == "LLM provided this fix."
        assert r.rule_name is None

    def test_failed_result_shape(self):
        r = RepairResult(
            success=False,
            tier_used="failed",
            error_message="No repair strategy succeeded.",
        )
        assert r.success is False
        assert r.tier_used == "failed"
        assert r.fixed_code is None
        assert r.rule_name is None
        assert r.llm_explanation is None
