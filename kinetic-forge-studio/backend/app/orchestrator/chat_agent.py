"""
Claude API-powered chat agent for Kinetic Forge Studio.

Replaces the rigid classifier->question_tree loop with a conversational agent
that understands natural language, asks clarifying questions, updates specs,
and generates CAD code.

Uses httpx for async Claude API calls (Messages API).
Falls back gracefully when no API key is configured.
"""

import asyncio
import json
import re
import logging
from dataclasses import dataclass, field
from typing import Any

import httpx

from app.config import settings
from app.ai.prompt_builder import PromptBuilder

logger = logging.getLogger(__name__)

CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
CLAUDE_API_VERSION = "2023-06-01"

# Retry configuration for transient failures
MAX_RETRIES = 2
RETRY_DELAY_SECONDS = 1.0
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 529}

# System prompt for the chat agent
AGENT_SYSTEM_PROMPT = """\
You are the design agent for Kinetic Forge Studio, a kinetic sculpture design orchestrator.

Your job:
1. Understand the user's design intent through conversation
2. Ask 1-3 clarifying questions (not more) when needed
3. Update the design spec as parameters become clear
4. Generate CAD code (CadQuery/build123d Python or OpenSCAD .scad) when ready
5. Iterate on feedback ("too big", "add clearance", "change module")

{context}

Rules:
- All dimensions in millimeters
- Single motor unless impossible
- Every dimension must be a named constant
- For CadQuery: generate Python script using CadQuery API
- For OpenSCAD: follow the template (Header -> Quality -> Tolerances -> Dimensions -> Toggles -> Colors -> Functions -> Primitives -> Assemblies)
- When generating code, output it in a ```python or ```openscad code block
- When updating spec parameters, include a JSON block tagged as:
  ```spec_update
  {{"field": "value", ...}}
  ```
- When presenting options, format them as a JSON block:
  ```options
  {{"field": "field_name", "options": [{{"label": "Option A", "value": "a", "description": "..."}}, ...]}}
  ```
- For iterative feedback, modify specific constants -- never full rewrites
- Be concise. Use bullet points. Include specific numbers.
"""


@dataclass
class AgentResponse:
    """Structured response from the chat agent."""
    message: str
    response_type: str  # "answer", "question", "generation", "error"
    spec_updates: dict[str, Any] = field(default_factory=dict)
    code_blocks: list[dict[str, str]] = field(default_factory=list)
    options: dict | None = None
    model_used: str = ""


class ChatAgent:
    """
    Wraps Claude API calls for conversational design assistance.

    Every call auto-includes project context (spec, decisions, components,
    profile, classifier results) so Claude has full situational awareness.
    """

    def __init__(self):
        self.prompt_builder = PromptBuilder()
        self._client: httpx.AsyncClient | None = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=120.0)
        return self._client

    async def close(self):
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    def is_available(self) -> bool:
        """Check if Claude API is configured."""
        return bool(settings.claude_api_key)

    async def chat(
        self,
        user_message: str,
        conversation_history: list[dict[str, str]],
        spec: dict[str, Any] | None = None,
        locked_decisions: list[dict] | None = None,
        components: list[dict] | None = None,
        user_profile: dict | None = None,
        classifier_results: dict | None = None,
        library_matches: list[dict] | None = None,
    ) -> AgentResponse:
        """Send a message to Claude with full project context."""
        if not self.is_available():
            return AgentResponse(
                message=(
                    "Claude API key not configured. "
                    "Set KFS_CLAUDE_API_KEY environment variable to enable AI chat."
                ),
                response_type="error",
            )

        # Build context for system prompt
        context = self._build_context(
            spec, locked_decisions, components, user_profile,
            classifier_results, library_matches,
        )
        system_prompt = AGENT_SYSTEM_PROMPT.format(context=context)

        # Build messages array
        messages = [
            {"role": msg["role"], "content": msg["content"]}
            for msg in conversation_history
        ]
        messages.append({"role": "user", "content": user_message})

        # Call Claude API with retry
        data = await self._call_api(system_prompt, messages)
        if data is None:
            return AgentResponse(
                message="Could not reach Claude API after retries. Check your connection and API key.",
                response_type="error",
            )

        # Extract text from response
        content_blocks = data.get("content", [])
        text_parts = [b["text"] for b in content_blocks if b.get("type") == "text"]
        full_text = "\n".join(text_parts)

        return self._parse_response(full_text, data.get("model", settings.claude_model))

    async def _call_api(
        self, system_prompt: str, messages: list[dict],
    ) -> dict | None:
        """Call Claude API with automatic retry on transient failures."""
        client = await self._get_client()

        for attempt in range(MAX_RETRIES + 1):
            try:
                response = await client.post(
                    CLAUDE_API_URL,
                    headers={
                        "x-api-key": settings.claude_api_key,
                        "anthropic-version": CLAUDE_API_VERSION,
                        "content-type": "application/json",
                    },
                    json={
                        "model": settings.claude_model,
                        "max_tokens": settings.claude_max_tokens,
                        "system": system_prompt,
                        "messages": messages,
                    },
                )

                if response.status_code == 200:
                    return response.json()

                # Retryable error
                if response.status_code in RETRYABLE_STATUS_CODES and attempt < MAX_RETRIES:
                    delay = RETRY_DELAY_SECONDS * (attempt + 1)
                    logger.warning(
                        "Claude API returned %d, retrying in %.1fs (attempt %d/%d)",
                        response.status_code, delay, attempt + 1, MAX_RETRIES,
                    )
                    await asyncio.sleep(delay)
                    continue

                # Non-retryable error
                logger.error(
                    "Claude API error %d: %s",
                    response.status_code, response.text[:500],
                )
                return None

            except httpx.RequestError as e:
                if attempt < MAX_RETRIES:
                    delay = RETRY_DELAY_SECONDS * (attempt + 1)
                    logger.warning("Claude API request error: %s, retrying in %.1fs", e, delay)
                    await asyncio.sleep(delay)
                    continue
                logger.error("Claude API request failed after retries: %s", e)
                return None

        return None

    def _build_context(
        self,
        spec: dict | None,
        locked_decisions: list[dict] | None,
        components: list[dict] | None,
        user_profile: dict | None,
        classifier_results: dict | None,
        library_matches: list[dict] | None,
    ) -> str:
        """Build context string for the system prompt."""
        parts = []

        if spec:
            lines = ["Current project spec:"]
            for k, v in spec.items():
                lines.append(f"- {k}: {v}")
            parts.append("\n".join(lines))

        if locked_decisions:
            lines = ["Locked decisions:"]
            for d in locked_decisions:
                lines.append(
                    f"- [{d.get('status', '?')}] {d.get('parameter', '?')} = {d.get('value', '?')}"
                )
            parts.append("\n".join(lines))

        if components:
            lines = ["Components:"]
            for c in components:
                name = c.get("display_name", c.get("id", "?"))
                ctype = c.get("component_type", "?")
                lines.append(f"- {name} ({ctype})")
            parts.append("\n".join(lines))

        if user_profile:
            printer = user_profile.get("printer", {})
            prefs = user_profile.get("preferences", {})
            lines = ["User profile:"]
            if printer:
                lines.append(
                    f"- Printer: {printer.get('type', '?')}, "
                    f"nozzle={printer.get('nozzle', '?')}mm, "
                    f"tolerance={printer.get('tolerance', '?')}mm"
                )
            if prefs:
                lines.append(f"- Material: {prefs.get('default_material', '?')}")
                lines.append(f"- Shaft standard: {prefs.get('shaft_standard', '?')}mm")
            style = user_profile.get("style_tags", [])
            if style:
                lines.append(f"- Style: {', '.join(style)}")
            parts.append("\n".join(lines))

        if library_matches:
            lines = ["Library matches (consider before generating from scratch):"]
            for match in library_matches[:3]:
                name = match.get("name", "?")
                mech = match.get("mechanism_types", "?")
                lines.append(f"- {name} (mechanisms: {mech})")
            parts.append("\n".join(lines))

        if classifier_results:
            fields = classifier_results.get("fields", {})
            if fields:
                lines = ["Classifier pre-extracted:"]
                for k, v in fields.items():
                    conf = classifier_results.get("confidence", {}).get(k, "?")
                    lines.append(f"- {k} = {v} (confidence: {conf})")
                parts.append("\n".join(lines))

        return "\n\n".join(parts) if parts else "No project context yet."

    def _parse_response(self, text: str, model: str) -> AgentResponse:
        """
        Parse Claude's response text for structured blocks.

        Extracts:
        - ```spec_update {...} ``` blocks -> spec_updates dict
        - ```python ... ``` or ```openscad ... ``` blocks -> code_blocks list
        - ```options {...} ``` blocks -> options dict
        """
        spec_updates: dict[str, Any] = {}
        code_blocks: list[dict[str, str]] = []
        options: dict | None = None

        # Extract spec_update blocks
        for match in re.finditer(r"```spec_update\s*\n(.*?)\n```", text, re.DOTALL):
            try:
                updates = json.loads(match.group(1))
                spec_updates.update(updates)
            except json.JSONDecodeError:
                logger.warning("Failed to parse spec_update block: %s", match.group(1)[:100])

        # Extract options blocks
        for match in re.finditer(r"```options\s*\n(.*?)\n```", text, re.DOTALL):
            try:
                options = json.loads(match.group(1))
            except json.JSONDecodeError:
                logger.warning("Failed to parse options block: %s", match.group(1)[:100])

        # Extract code blocks (python or openscad)
        for match in re.finditer(r"```(python|openscad)\s*\n(.*?)\n```", text, re.DOTALL):
            code_blocks.append({
                "language": match.group(1),
                "code": match.group(2),
            })

        # Clean display message: remove spec_update and options blocks, keep code
        clean_text = re.sub(r"```spec_update\s*\n.*?\n```", "", text, flags=re.DOTALL)
        clean_text = re.sub(r"```options\s*\n.*?\n```", "", clean_text, flags=re.DOTALL)
        clean_text = clean_text.strip()

        # Determine response type
        if code_blocks:
            response_type = "generation"
        elif options:
            response_type = "question"
        else:
            response_type = "answer"

        return AgentResponse(
            message=clean_text,
            response_type=response_type,
            spec_updates=spec_updates,
            code_blocks=code_blocks,
            options=options,
            model_used=model,
        )
