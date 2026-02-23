from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/api/projects/{project_id}/chat", tags=["chat"])

class ChatMessage(BaseModel):
    content: str
    role: str = "user"

@router.post("")
async def send_message(project_id: str, msg: ChatMessage):
    # Phase 5 will wire this to the translator.
    # For now, echo back with a placeholder response.
    return {
        "user_message": msg.content,
        "response": f"Received: \"{msg.content}\". (Translator not yet connected — Phase 5)",
        "spec_updates": []
    }
