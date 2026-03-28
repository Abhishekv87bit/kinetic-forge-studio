"""Contract tests for SC-05 Context Persistence.

Covers:
- log_action persists a row and returns a positive integer row-id.
- log_action accepts optional details dict and empty module_id.
- get_session_summary aggregates action counts and module lists correctly.
- get_session_summary returns zero-action summary for unknown session.
- SessionSummary.as_text() serialises to a human-readable string.
- build_module_context returns a non-empty block for a known module.
- build_module_context returns empty string for an unknown module.
- build_module_context respects max_actions cap.
- prompt_builder.build_prompt includes the MODULE_CONTEXT_HEADER section.
"""
from __future__ import annotations

import pytest

from backend.app.models.session_context import (
    SessionAction,
    SessionContextManager,
    SessionSummary,
)
from backend.app.ai.prompt_builder import build_prompt, MODULE_CONTEXT_HEADER


# ---------------------------------------------------------------------------
# Fixture
# ---------------------------------------------------------------------------


@pytest.fixture()
def mgr() -> SessionContextManager:
    """Fresh in-memory SessionContextManager for each test."""
    return SessionContextManager(":memory:")


SESSION = "sess-abc-123"
MOD_A = "gear_module"
MOD_B = "frame_module"


# ---------------------------------------------------------------------------
# log_action
# ---------------------------------------------------------------------------


class TestLogAction:
    def test_returns_positive_row_id(self, mgr: SessionContextManager):
        row_id = mgr.log_action(SESSION, "module_created", MOD_A)
        assert isinstance(row_id, int)
        assert row_id > 0

    def test_successive_ids_increment(self, mgr: SessionContextManager):
        id1 = mgr.log_action(SESSION, "module_created", MOD_A)
        id2 = mgr.log_action(SESSION, "module_executed", MOD_A)
        assert id2 > id1

    def test_accepts_details_dict(self, mgr: SessionContextManager):
        row_id = mgr.log_action(
            SESSION,
            "vlad_run",
            MOD_A,
            details={"verdict": "PASS", "fail_count": 0},
        )
        assert row_id > 0

    def test_accepts_empty_module_id(self, mgr: SessionContextManager):
        row_id = mgr.log_action(SESSION, "session_start")
        assert row_id > 0

    def test_accepts_none_details(self, mgr: SessionContextManager):
        row_id = mgr.log_action(SESSION, "module_created", MOD_A, details=None)
        assert row_id > 0

    def test_different_sessions_are_independent(self, mgr: SessionContextManager):
        mgr.log_action("sess-1", "module_created", MOD_A)
        mgr.log_action("sess-2", "module_created", MOD_B)
        summary_1 = mgr.get_session_summary("sess-1")
        summary_2 = mgr.get_session_summary("sess-2")
        assert summary_1.modules_touched == [MOD_A]
        assert summary_2.modules_touched == [MOD_B]


# ---------------------------------------------------------------------------
# get_session_summary
# ---------------------------------------------------------------------------


class TestGetSessionSummary:
    def test_empty_session_returns_zero_actions(self, mgr: SessionContextManager):
        summary = mgr.get_session_summary("unknown-session")
        assert isinstance(summary, SessionSummary)
        assert summary.total_actions == 0
        assert summary.modules_touched == []
        assert summary.action_counts == {}
        assert summary.last_action is None

    def test_total_actions_count(self, mgr: SessionContextManager):
        for _ in range(3):
            mgr.log_action(SESSION, "module_executed", MOD_A)
        summary = mgr.get_session_summary(SESSION)
        assert summary.total_actions == 3

    def test_action_counts_by_type(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        mgr.log_action(SESSION, "module_executed", MOD_A)
        mgr.log_action(SESSION, "module_executed", MOD_A)
        mgr.log_action(SESSION, "vlad_run", MOD_A)
        summary = mgr.get_session_summary(SESSION)
        assert summary.action_counts["module_created"] == 1
        assert summary.action_counts["module_executed"] == 2
        assert summary.action_counts["vlad_run"] == 1

    def test_modules_touched_deduplication(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        mgr.log_action(SESSION, "module_executed", MOD_A)
        mgr.log_action(SESSION, "module_created", MOD_B)
        summary = mgr.get_session_summary(SESSION)
        assert MOD_A in summary.modules_touched
        assert MOD_B in summary.modules_touched
        assert len(summary.modules_touched) == 2

    def test_modules_touched_excludes_empty_module_id(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "session_start")  # no module_id
        mgr.log_action(SESSION, "module_created", MOD_A)
        summary = mgr.get_session_summary(SESSION)
        assert "" not in summary.modules_touched
        assert MOD_A in summary.modules_touched

    def test_last_action_is_most_recent(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        mgr.log_action(SESSION, "module_executed", MOD_A)
        mgr.log_action(SESSION, "vlad_run", MOD_B)
        summary = mgr.get_session_summary(SESSION)
        assert summary.last_action is not None
        assert summary.last_action.action_type == "vlad_run"
        assert summary.last_action.module_id == MOD_B

    def test_last_action_is_session_action_instance(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        summary = mgr.get_session_summary(SESSION)
        assert isinstance(summary.last_action, SessionAction)

    def test_session_id_matches(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        summary = mgr.get_session_summary(SESSION)
        assert summary.session_id == SESSION


# ---------------------------------------------------------------------------
# SessionSummary.as_text
# ---------------------------------------------------------------------------


class TestSessionSummaryAsText:
    def test_empty_session_text(self, mgr: SessionContextManager):
        summary = mgr.get_session_summary("empty-session")
        text = summary.as_text()
        assert "no actions recorded" in text

    def test_non_empty_summary_contains_session_id(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        summary = mgr.get_session_summary(SESSION)
        assert SESSION in summary.as_text()

    def test_summary_text_contains_action_count(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        mgr.log_action(SESSION, "module_executed", MOD_A)
        text = mgr.get_session_summary(SESSION).as_text()
        assert "2" in text

    def test_summary_text_contains_module_name(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        text = mgr.get_session_summary(SESSION).as_text()
        assert MOD_A in text

    def test_summary_text_contains_action_type(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "vlad_run", MOD_A)
        text = mgr.get_session_summary(SESSION).as_text()
        assert "vlad_run" in text


# ---------------------------------------------------------------------------
# build_module_context
# ---------------------------------------------------------------------------


class TestBuildModuleContext:
    def test_returns_empty_string_for_unknown_module(self, mgr: SessionContextManager):
        result = mgr.build_module_context(SESSION, "nonexistent-module")
        assert result == ""

    def test_returns_non_empty_string_for_known_module(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        result = mgr.build_module_context(SESSION, MOD_A)
        assert result != ""

    def test_output_contains_module_id(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        result = mgr.build_module_context(SESSION, MOD_A)
        assert MOD_A in result

    def test_output_contains_action_type(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_executed", MOD_A)
        result = mgr.build_module_context(SESSION, MOD_A)
        assert "module_executed" in result

    def test_output_contains_details_field(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "vlad_run", MOD_A, details={"verdict": "PASS"})
        result = mgr.build_module_context(SESSION, MOD_A)
        assert "verdict" in result or "PASS" in result

    def test_max_actions_cap_respected(self, mgr: SessionContextManager):
        for i in range(10):
            mgr.log_action(SESSION, f"action_{i}", MOD_A)
        result = mgr.build_module_context(SESSION, MOD_A, max_actions=3)
        # Only the last 3 actions should appear; header line + 3 action lines = 4 lines
        lines = [ln for ln in result.splitlines() if ln.strip()]
        assert len(lines) <= 4  # header + 3 action lines

    def test_only_returns_actions_for_requested_module(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        mgr.log_action(SESSION, "module_created", MOD_B)
        result = mgr.build_module_context(SESSION, MOD_A)
        assert MOD_B not in result

    def test_returns_empty_string_for_wrong_session(self, mgr: SessionContextManager):
        mgr.log_action(SESSION, "module_created", MOD_A)
        result = mgr.build_module_context("other-session", MOD_A)
        assert result == ""


# ---------------------------------------------------------------------------
# prompt_builder — MODULE_CONTEXT_HEADER section is always present
# ---------------------------------------------------------------------------


class TestPromptBuilder:
    def test_prompt_contains_module_context_header(self):
        """build_prompt must embed MODULE_CONTEXT_HEADER regardless of history."""
        prompt = build_prompt(
            session_id="fresh-session",
            module_id="test_module",
            db_path=":memory:",
        )
        assert MODULE_CONTEXT_HEADER in prompt

    def test_prompt_contains_session_summary_section(self):
        prompt = build_prompt(
            session_id="fresh-session",
            module_id="test_module",
            db_path=":memory:",
        )
        assert "## Session Summary" in prompt

    def test_prompt_includes_user_message_when_provided(self):
        prompt = build_prompt(
            session_id="fresh-session",
            module_id="test_module",
            db_path=":memory:",
            user_message="generate a spur gear",
        )
        assert "generate a spur gear" in prompt

    def test_prompt_no_user_message_excludes_user_request_section(self):
        prompt = build_prompt(
            session_id="fresh-session",
            module_id="test_module",
            db_path=":memory:",
        )
        assert "## User Request" not in prompt

    def test_prompt_includes_module_history_after_log_action(self):
        """When actions have been logged, module context section shows them."""
        mgr = SessionContextManager(":memory:")
        mgr.log_action("live-session", "module_created", "spur_gear")
        # We cannot reuse the same in-memory DB since build_prompt opens its own
        # connection — use a temp file-based DB instead.
        import tempfile, os

        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            tmp_path = f.name
        try:
            mgr2 = SessionContextManager(tmp_path)
            mgr2.log_action("live-session", "module_created", "spur_gear")
            prompt = build_prompt(
                session_id="live-session",
                module_id="spur_gear",
                db_path=tmp_path,
            )
            assert MODULE_CONTEXT_HEADER in prompt
            assert "spur_gear" in prompt
        finally:
            os.unlink(tmp_path)
