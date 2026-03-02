"""
Chat route — wired to both Pipeline (keyword classifier) and ChatAgent (Claude API).

When KFS_CLAUDE_API_KEY is set, uses ChatAgent for conversational AI.
Otherwise falls back to Pipeline (keyword classifier + question tree).
"""

import logging
from dataclasses import dataclass, field as dc_field

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Any

from app.config import settings
from app.orchestrator.pipeline import Pipeline
from app.orchestrator.chat_agent import ChatAgent

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/projects/{project_id}/chat", tags=["chat"])


@dataclass
class ProjectChatState:
    """Tracks per-project chat state for both Pipeline and ChatAgent."""
    pipeline: Pipeline = dc_field(default_factory=Pipeline)
    agent: ChatAgent = dc_field(default_factory=ChatAgent)
    conversation_history: list[dict[str, str]] = dc_field(default_factory=list)


# In-memory chat state per project.
_chat_states: dict[str, ProjectChatState] = {}


def _get_state(project_id: str) -> ProjectChatState:
    """Get or create chat state for the given project."""
    if project_id not in _chat_states:
        _chat_states[project_id] = ProjectChatState()
    return _chat_states[project_id]


class ChatMessage(BaseModel):
    content: str
    role: str = "user"


class AnswerMessage(BaseModel):
    field: str
    value: Any


@router.post("")
async def send_message(project_id: str, msg: ChatMessage):
    """
    Process a user chat message.

    When Claude API key is configured, uses ChatAgent for conversational AI.
    Otherwise falls back to the keyword classifier Pipeline.
    """
    state = _get_state(project_id)

    if state.agent.is_available():
        try:
            result = await _send_via_agent(state, project_id, msg)
            if result.get("response_type") != "error":
                return result
            # AI returned an error — fall back to Pipeline
            logger.warning("ChatAgent returned error, falling back to Pipeline")
        except Exception as e:
            logger.warning("ChatAgent failed (%s), falling back to Pipeline", e)
    return _send_via_pipeline(state, msg)


async def _send_via_agent(
    state: ProjectChatState, project_id: str, msg: ChatMessage
) -> dict:
    """Route message through ChatAgent (Claude API)."""
    # Get spec from pipeline's accumulated state (classifier still extracts fields)
    pipeline_result = state.pipeline.process(msg.content)
    spec = dict(state.pipeline.spec)

    response = await state.agent.chat(
        user_message=msg.content,
        conversation_history=state.conversation_history,
        spec=spec,
        classifier_results=pipeline_result.classification,
    )

    # Track conversation history
    state.conversation_history.append({"role": "user", "content": msg.content})
    state.conversation_history.append({"role": "assistant", "content": response.message})

    # Apply spec updates from Claude's response back to pipeline
    for key, value in response.spec_updates.items():
        state.pipeline.spec[key] = value

    return {
        "user_message": msg.content,
        "message": response.message,
        "response_type": response.response_type,
        "spec_updates": [
            {"field": k, "value": v} for k, v in response.spec_updates.items()
        ],
        "code_blocks": response.code_blocks,
        "options": response.options,
        "model_used": response.model_used,
        "ai_powered": True,
    }


def _send_via_pipeline(state: ProjectChatState, msg: ChatMessage) -> dict:
    """Route message through Pipeline (keyword classifier fallback)."""
    response = state.pipeline.process(msg.content)
    return {
        "user_message": msg.content,
        **response.to_dict(),
        "ai_powered": False,
    }


@router.post("/answer")
async def answer_question(project_id: str, answer: AnswerMessage):
    """Apply a direct answer to a question (e.g., button selection)."""
    state = _get_state(project_id)
    response = state.pipeline.apply_answer(answer.field, answer.value)
    return response.to_dict()


@router.post("/reset")
async def reset_chat(project_id: str):
    """Reset chat state for this project."""
    if project_id in _chat_states:
        state = _chat_states[project_id]
        state.pipeline.reset()
        state.conversation_history.clear()
    return {"status": "reset", "project_id": project_id}


@router.get("/status")
async def chat_status(project_id: str):
    """Return chat configuration status."""
    state = _get_state(project_id)
    return {
        "ai_available": state.agent.is_available(),
        "model": settings.claude_model if state.agent.is_available() else None,
        "history_length": len(state.conversation_history),
        "spec_fields": len(state.pipeline.spec),
    }
