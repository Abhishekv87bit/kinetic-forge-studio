"""Chat agent orchestrator for KFS.

Receives a user message, logs the interaction to the session log (SC-05),
builds a context-enriched prompt via :mod:`backend.app.ai.prompt_builder`,
and returns the assistant response.

The agent is intentionally stateless across HTTP requests — all state is
reconstituted from the ``session_log`` table on each call.
"""
from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

from backend.app.ai.prompt_builder import PromptBuilder
from backend.app.models.session_context import SessionContextManager

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Value objects
# ---------------------------------------------------------------------------


@dataclass
class ChatMessage:
    """Single message in the chat history."""

    role: str   # "user" | "assistant" | "system"
    content: str


@dataclass
class ChatResponse:
    """Result of one agent turn."""

    session_id: str
    reply: str
    prompt_used: str   # The full prompt sent to the LLM (useful for debugging)
    log_row_id: int    # Row id of the "user_message" action in session_log


# ---------------------------------------------------------------------------
# Agent
# ---------------------------------------------------------------------------


class ChatAgent:
    """Orchestrates KFS chat turns with session-aware prompt construction.

    Parameters
    ----------
    db_path:
        Path to the shared KFS SQLite database.
    llm_client:
        Any object with a ``complete(prompt: str) -> str`` method.  In
        production this is an Anthropic / OpenAI client wrapper; in tests
        you can pass a lightweight stub.
    session_id:
        Identifies the chat session.  A fresh UUID is generated when not
        provided — callers should persist this and pass it on subsequent
        turns so the session log accumulates correctly.
    """

    def __init__(
        self,
        db_path: str,
        llm_client: Any,
        session_id: Optional[str] = None,
    ) -> None:
        self.db_path = db_path
        self._llm = llm_client
        self.session_id = session_id or str(uuid.uuid4())
        self._ctx = SessionContextManager(db_path)
        self._builder = PromptBuilder(self._ctx)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def chat(
        self,
        user_message: str,
        history: Optional[List[ChatMessage]] = None,
        active_module_id: Optional[str] = None,
    ) -> ChatResponse:
        """Process one user turn and return the assistant reply.

        Parameters
        ----------
        user_message:
            Raw text from the user.
        history:
            Prior turns in this session (for multi-turn context).  If omitted,
            only the session log is used to reconstruct context.
        active_module_id:
            When the user is working on a specific module, pass its id so
            :meth:`~backend.app.ai.prompt_builder.PromptBuilder.build_prompt`
            can inject that module's lifecycle history.

        Returns
        -------
        ChatResponse
            Contains the LLM reply, the prompt used, and the log row id.
        """
        # Log the incoming user message so it's part of session history
        log_row_id = self._ctx.log_action(
            session_id=self.session_id,
            action_type="user_message",
            module_id=active_module_id or "",
            details={"message_preview": user_message[:200]},
        )

        # Build context-enriched prompt
        prompt = self._builder.build_prompt(
            session_id=self.session_id,
            user_message=user_message,
            history=history or [],
            active_module_id=active_module_id,
        )

        logger.debug(
            "ChatAgent session=%r module=%r prompt_len=%d",
            self.session_id,
            active_module_id,
            len(prompt),
        )

        # Call the LLM
        reply: str = self._llm.complete(prompt)

        # Log the assistant reply
        self._ctx.log_action(
            session_id=self.session_id,
            action_type="assistant_reply",
            module_id=active_module_id or "",
            details={"reply_preview": reply[:200]},
        )

        return ChatResponse(
            session_id=self.session_id,
            reply=reply,
            prompt_used=prompt,
            log_row_id=log_row_id,
        )

    def log_module_event(
        self,
        action_type: str,
        module_id: str,
        details: Optional[Dict[str, Any]] = None,
    ) -> int:
        """Convenience method for pipeline stages to record module events.

        Callers (e.g. ModuleExecutor, VladRunner wrappers) can call this
        after execution so the session context reflects the full module
        lifecycle, not just chat turns.

        Returns the new row id.
        """
        return self._ctx.log_action(
            session_id=self.session_id,
            action_type=action_type,
            module_id=module_id,
            details=details,
        )

    def get_session_summary_text(self) -> str:
        """Return a human-readable session summary (delegates to SC-05)."""
        return self._ctx.get_session_summary(self.session_id).as_text()
