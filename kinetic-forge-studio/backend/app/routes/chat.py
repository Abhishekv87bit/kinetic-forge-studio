"""
Chat route — wired to the orchestrator pipeline.

Maintains a pipeline instance per project (in-memory for now).
Messages flow through: classify -> check unknowns -> question or generate.
"""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Any

from app.orchestrator.pipeline import Pipeline

router = APIRouter(prefix="/api/projects/{project_id}/chat", tags=["chat"])

# In-memory pipeline instances per project.
# In production, this would be backed by the database.
_pipelines: dict[str, Pipeline] = {}


def _get_pipeline(project_id: str) -> Pipeline:
    """Get or create a pipeline for the given project."""
    if project_id not in _pipelines:
        _pipelines[project_id] = Pipeline()
    return _pipelines[project_id]


class ChatMessage(BaseModel):
    content: str
    role: str = "user"


class AnswerMessage(BaseModel):
    field: str
    value: Any


@router.post("")
async def send_message(project_id: str, msg: ChatMessage):
    """
    Process a user chat message through the orchestrator pipeline.

    Returns the pipeline response with:
    - message: The assistant's reply text
    - response_type: "question", "generation", "info", or "error"
    - spec_updates: List of spec field changes
    - question: (optional) The next question to ask
    - geometry: (optional) Geometry generation result
    - classification: (optional) Raw classification result
    """
    pipeline = _get_pipeline(project_id)
    response = pipeline.process(msg.content)
    return {
        "user_message": msg.content,
        **response.to_dict(),
    }


@router.post("/answer")
async def answer_question(project_id: str, answer: AnswerMessage):
    """
    Apply a direct answer to a question (e.g., button selection).

    Used when the user picks an option from a presented question
    rather than typing free text.
    """
    pipeline = _get_pipeline(project_id)
    response = pipeline.apply_answer(answer.field, answer.value)
    return response.to_dict()


@router.post("/reset")
async def reset_chat(project_id: str):
    """Reset the pipeline for this project (start fresh)."""
    if project_id in _pipelines:
        _pipelines[project_id].reset()
    return {"status": "reset", "project_id": project_id}
