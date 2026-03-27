"""SC-05 — Prompt builder that injects session context into LLM prompts.

Assembles a structured system prompt from the current session's action log.
The output contains clearly labelled sections so downstream parsers and tests
can verify each section is present.
"""
from __future__ import annotations

from backend.app.models.session_context import SessionContextManager


# Section header used by downstream code and contract tests.
MODULE_CONTEXT_HEADER = "## Module Context"


def build_prompt(
    session_id: str,
    module_id: str,
    db_path: str,
    user_message: str = "",
    max_actions: int = 20,
) -> str:
    """Return a full prompt string with an embedded module-context section.

    Parameters
    ----------
    session_id:
        Identifies the current chat session.
    module_id:
        The module whose lifecycle history to embed.
    db_path:
        Path to the SQLite database that backs :class:`SessionContextManager`.
    user_message:
        The raw user turn to append after context sections.
    max_actions:
        Passed through to :meth:`SessionContextManager.build_module_context`.

    Returns
    -------
    str
        Assembled prompt text.  Always contains ``MODULE_CONTEXT_HEADER`` so
        callers can assert its presence.
    """
    mgr = SessionContextManager(db_path)
    session_summary = mgr.get_session_summary(session_id).as_text()
    module_context = mgr.build_module_context(session_id, module_id, max_actions)

    parts = [
        "## Session Summary",
        session_summary,
        MODULE_CONTEXT_HEADER,
        module_context if module_context else "(no module history for this session)",
    ]
    if user_message:
        parts += ["## User Request", user_message]

    return "\n\n".join(parts)
