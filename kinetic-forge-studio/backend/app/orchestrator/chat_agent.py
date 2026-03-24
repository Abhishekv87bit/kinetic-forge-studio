"""
AI chat agent for Kinetic Forge Studio.

This is the PRIMARY design brain of the application. The LLM receives a
methodology-rich system prompt and generates structured output that the
app parses automatically:
- ```components [...] ``` → registered in DB, rendered in viewport
- ```spec_update {...} ``` → updates the project spec sheet
- ```verification {...} ``` → physics checks displayed inline
- ```options {...} ``` → presented as clickable choices
- ```python/openscad ``` → code displayed in chat + available for execution

Supports multiple LLM providers:
  - Preferred provider checked first (KFS_PREFERRED_PROVIDER, default: claude)
  - Fallback chain: Claude → Groq → Grok
  - No AI — falls back to keyword Pipeline when no key is set
"""

import asyncio
import json
import re
import logging
import time
from dataclasses import dataclass, field
from typing import Any, Literal

import httpx

from app.config import settings
from app.ai.prompt_builder import PromptBuilder
from app.middleware.cache import prompt_cache, make_hash_key
from app.middleware.observability import log_llm_call, log_cache_stats

logger = logging.getLogger(__name__)

# API endpoints
CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
CLAUDE_API_VERSION = "2023-06-01"
GROK_API_URL = "https://api.x.ai/v1/chat/completions"
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"

# Retry configuration for transient failures
MAX_RETRIES = 2
RETRY_DELAY_SECONDS = 1.0
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 529}


@dataclass
class AgentResponse:
    """Structured response from the chat agent."""
    message: str
    response_type: str  # "answer", "question", "generation", "error"
    spec_updates: dict[str, Any] = field(default_factory=dict)
    code_blocks: list[dict[str, str]] = field(default_factory=list)
    components: list[dict[str, Any]] = field(default_factory=list)
    verification: dict[str, Any] | None = None
    options: dict | None = None
    model_used: str = ""


class ChatAgent:
    """
    Multi-provider AI chat agent — the primary design brain of KFS.

    The LLM receives the full methodology system prompt (gear math, four-bar
    rules, cam design, FDM constraints, etc.) and generates structured output
    that the app registers as real components.

    Priority: preferred_provider > Claude > Groq > Grok > fallback to Pipeline.
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

    def _active_provider(self) -> Literal["groq", "grok", "claude", "gemini"] | None:
        """Return the active LLM provider, respecting preferred_provider config."""
        preferred = settings.preferred_provider

        # Check preferred provider first
        key_map = {
            "claude": settings.claude_api_key,
            "groq": settings.groq_api_key,
            "grok": settings.grok_api_key,
            "gemini": settings.gemini_api_key,
        }
        if preferred in key_map and key_map[preferred]:
            return preferred

        # Fallback chain: claude → gemini → groq → grok
        if settings.claude_api_key:
            return "claude"
        if settings.gemini_api_key:
            return "gemini"
        if settings.groq_api_key:
            return "groq"
        if settings.grok_api_key:
            return "grok"
        return None

    def is_available(self) -> bool:
        """Check if any AI provider is configured."""
        return self._active_provider() is not None

    def active_model(self) -> str:
        """Return the model name for the active provider."""
        provider = self._active_provider()
        if provider == "groq":
            return settings.groq_model
        if provider == "grok":
            return settings.grok_model
        if provider == "claude":
            return settings.claude_model
        if provider == "gemini":
            return settings.gemini_model
        return ""

    async def chat(
        self,
        user_message: str,
        conversation_history: list[dict[str, str]],
        spec: dict[str, Any] | None = None,
        gate_level: str = "design",
        locked_decisions: list[dict] | None = None,
        components: list[dict] | None = None,
        user_profile: dict | None = None,
        classifier_results: dict | None = None,
        library_matches: list[dict] | None = None,
        consultant_context: dict | None = None,
        scad_source: dict[str, str] | None = None,
    ) -> AgentResponse:
        """
        Send a message to the active AI provider with full project context.

        The system prompt includes the complete methodology (gear math,
        physics rules, manufacturing constraints) so the LLM can reason
        about designs at the level of an experienced engineer.
        """
        provider = self._active_provider()
        if provider is None:
            return AgentResponse(
                message=(
                    "No AI API key configured. "
                    "Set KFS_GROQ_API_KEY, KFS_GROK_API_KEY, or KFS_CLAUDE_API_KEY "
                    "to enable the AI design agent."
                ),
                response_type="error",
            )

        # Build the methodology-rich system prompt with full context.
        # Cache by project-specific inputs so identical contexts reuse the prompt.
        prompt_key = make_hash_key(
            "system_prompt",
            spec,
            gate_level,
            locked_decisions,
            components,
            user_profile,
            library_matches,
            consultant_context,
            scad_source,
        )
        system_prompt = prompt_cache.get(prompt_key)
        if system_prompt is None:
            system_prompt = self.prompt_builder.build_system_prompt(
                spec=spec,
                gate_level=gate_level,
                locked_decisions=locked_decisions,
                components=components,
                user_profile=user_profile,
                library_matches=library_matches,
                consultant_context=consultant_context,
                scad_source=scad_source,
            )
            prompt_cache.set(prompt_key, system_prompt)
            logger.debug("prompt_cache STORE (key %s)", prompt_key[:12])

        # Build messages array from conversation history
        messages = [
            {"role": msg["role"], "content": msg["content"]}
            for msg in conversation_history
        ]
        messages.append({"role": "user", "content": user_message})

        # Route to the active provider
        if provider == "groq":
            data = await self._call_openai_compat(
                system_prompt, messages,
                api_url=GROQ_API_URL,
                api_key=settings.groq_api_key,
                model=settings.groq_model,
                max_tokens=settings.groq_max_tokens,
                provider_name="Groq",
            )
        elif provider == "grok":
            data = await self._call_openai_compat(
                system_prompt, messages,
                api_url=GROK_API_URL,
                api_key=settings.grok_api_key,
                model=settings.grok_model,
                max_tokens=settings.grok_max_tokens,
                provider_name="Grok",
            )
        elif provider == "gemini":
            data = await self._call_openai_compat(
                system_prompt, messages,
                api_url=GEMINI_API_URL,
                api_key=settings.gemini_api_key,
                model=settings.gemini_model,
                max_tokens=settings.gemini_max_tokens,
                provider_name="Gemini",
            )
        else:
            data = await self._call_claude(system_prompt, messages)

        if data is None:
            return AgentResponse(
                message=f"Could not reach {provider} API after retries. Check your connection and API key.",
                response_type="error",
            )

        # Extract text — different response shapes per provider
        if provider in ("groq", "grok", "gemini"):
            full_text = self._extract_openai_text(data)
            model_map = {"groq": settings.groq_model, "grok": settings.grok_model, "gemini": settings.gemini_model}
            model = data.get("model", model_map.get(provider, ""))
        else:
            full_text = self._extract_claude_text(data)
            model = data.get("model", settings.claude_model)

        return self._parse_response(full_text, model)

    # ------------------------------------------------------------------
    # Provider-specific API calls
    # ------------------------------------------------------------------

    async def _call_openai_compat(
        self,
        system_prompt: str,
        messages: list[dict],
        api_url: str,
        api_key: str,
        model: str,
        max_tokens: int,
        provider_name: str = "OpenAI-compat",
    ) -> dict | None:
        """Call any OpenAI-compatible chat completions API (Groq, Grok, etc.)."""
        client = await self._get_client()

        # OpenAI format: system prompt is a message, not a separate field
        api_messages = [{"role": "system", "content": system_prompt}] + messages

        for attempt in range(MAX_RETRIES + 1):
            call_start = time.time()
            try:
                response = await client.post(
                    api_url,
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": model,
                        "max_tokens": max_tokens,
                        "messages": api_messages,
                    },
                )
                latency_ms = (time.time() - call_start) * 1000

                if response.status_code == 200:
                    data = response.json()
                    usage = data.get("usage", {})
                    log_llm_call(
                        name=f"chat_{provider_name.lower()}",
                        model=data.get("model", model),
                        input_tokens=usage.get("prompt_tokens", 0),
                        output_tokens=usage.get("completion_tokens", 0),
                        latency_ms=latency_ms,
                        success=True,
                    )
                    return data

                if response.status_code in RETRYABLE_STATUS_CODES and attempt < MAX_RETRIES:
                    delay = RETRY_DELAY_SECONDS * (attempt + 1)
                    log_llm_call(
                        name=f"chat_{provider_name.lower()}",
                        model=model,
                        latency_ms=latency_ms,
                        success=False,
                        error=f"HTTP {response.status_code} (retry {attempt + 1}/{MAX_RETRIES})",
                    )
                    logger.warning(
                        "%s API returned %d, retrying in %.1fs (attempt %d/%d)",
                        provider_name, response.status_code, delay, attempt + 1, MAX_RETRIES,
                    )
                    await asyncio.sleep(delay)
                    continue

                log_llm_call(
                    name=f"chat_{provider_name.lower()}",
                    model=model,
                    latency_ms=latency_ms,
                    success=False,
                    error=f"HTTP {response.status_code}: {response.text[:200]}",
                )
                logger.error(
                    "%s API error %d: %s",
                    provider_name, response.status_code, response.text[:500],
                )
                return None

            except httpx.RequestError as e:
                latency_ms = (time.time() - call_start) * 1000
                log_llm_call(
                    name=f"chat_{provider_name.lower()}",
                    model=model,
                    latency_ms=latency_ms,
                    success=False,
                    error=str(e),
                )
                if attempt < MAX_RETRIES:
                    delay = RETRY_DELAY_SECONDS * (attempt + 1)
                    logger.warning("%s API request error: %s, retrying in %.1fs", provider_name, e, delay)
                    await asyncio.sleep(delay)
                    continue
                logger.error("%s API request failed after retries: %s", provider_name, e)
                return None

        return None

    async def _call_claude(
        self, system_prompt: str, messages: list[dict],
    ) -> dict | None:
        """Call Anthropic Claude API (Messages API)."""
        client = await self._get_client()

        for attempt in range(MAX_RETRIES + 1):
            call_start = time.time()
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
                        "system": [
                            {
                                "type": "text",
                                "text": system_prompt,
                                "cache_control": {"type": "ephemeral"},
                            }
                        ],
                        "messages": messages,
                    },
                )
                latency_ms = (time.time() - call_start) * 1000

                if response.status_code == 200:
                    data = response.json()
                    usage = data.get("usage", {})
                    input_tokens = usage.get("input_tokens", 0)
                    output_tokens = usage.get("output_tokens", 0)
                    cache_creation = usage.get("cache_creation_input_tokens", 0)
                    cache_read = usage.get("cache_read_input_tokens", 0)

                    log_llm_call(
                        name="chat_claude",
                        model=data.get("model", settings.claude_model),
                        input_tokens=input_tokens,
                        output_tokens=output_tokens,
                        latency_ms=latency_ms,
                        success=True,
                    )
                    logger.info(
                        "Claude API cache stats: created=%d, read=%d, input=%d, output=%d",
                        cache_creation, cache_read, input_tokens, output_tokens,
                    )
                    log_cache_stats(
                        model=data.get("model", settings.claude_model),
                        cache_creation_tokens=cache_creation,
                        cache_read_tokens=cache_read,
                        input_tokens=input_tokens,
                        output_tokens=output_tokens,
                    )
                    return data

                if response.status_code in RETRYABLE_STATUS_CODES and attempt < MAX_RETRIES:
                    delay = RETRY_DELAY_SECONDS * (attempt + 1)
                    log_llm_call(
                        name="chat_claude",
                        model=settings.claude_model,
                        latency_ms=latency_ms,
                        success=False,
                        error=f"HTTP {response.status_code} (retry {attempt + 1}/{MAX_RETRIES})",
                    )
                    logger.warning(
                        "Claude API returned %d, retrying in %.1fs (attempt %d/%d)",
                        response.status_code, delay, attempt + 1, MAX_RETRIES,
                    )
                    await asyncio.sleep(delay)
                    continue

                log_llm_call(
                    name="chat_claude",
                    model=settings.claude_model,
                    latency_ms=latency_ms,
                    success=False,
                    error=f"HTTP {response.status_code}: {response.text[:200]}",
                )
                logger.error(
                    "Claude API error %d: %s",
                    response.status_code, response.text[:500],
                )
                return None

            except httpx.RequestError as e:
                latency_ms = (time.time() - call_start) * 1000
                log_llm_call(
                    name="chat_claude",
                    model=settings.claude_model,
                    latency_ms=latency_ms,
                    success=False,
                    error=str(e),
                )
                if attempt < MAX_RETRIES:
                    delay = RETRY_DELAY_SECONDS * (attempt + 1)
                    logger.warning("Claude API request error: %s, retrying in %.1fs", e, delay)
                    await asyncio.sleep(delay)
                    continue
                logger.error("Claude API request failed after retries: %s", e)
                return None

        return None

    # ------------------------------------------------------------------
    # Response text extraction (different shapes per provider)
    # ------------------------------------------------------------------

    @staticmethod
    def _extract_openai_text(data: dict) -> str:
        """Extract text from OpenAI-format response (Groq, Grok, etc.)."""
        choices = data.get("choices", [])
        if choices:
            return choices[0].get("message", {}).get("content", "")
        return ""

    @staticmethod
    def _extract_claude_text(data: dict) -> str:
        """Extract text from Anthropic Messages response."""
        content_blocks = data.get("content", [])
        text_parts = [b["text"] for b in content_blocks if b.get("type") == "text"]
        return "\n".join(text_parts)

    # ------------------------------------------------------------------
    # Response parser — extracts ALL structured blocks
    # ------------------------------------------------------------------

    def _parse_response(self, text: str, model: str) -> AgentResponse:
        """
        Parse LLM response text for structured blocks.

        Extracts:
        - ```components [...] ``` → components list (THE KEY OUTPUT)
        - ```spec_update {...} ``` → spec_updates dict
        - ```verification {...} ``` → verification dict
        - ```options {...} ``` → options dict
        - ```python/openscad ... ``` → code_blocks list
        """
        spec_updates: dict[str, Any] = {}
        code_blocks: list[dict[str, str]] = []
        components: list[dict[str, Any]] = []
        verification: dict[str, Any] | None = None
        options: dict | None = None

        # Extract components blocks (THE PRIMARY OUTPUT)
        for match in re.finditer(r"```components\s*\n(.*?)\n```", text, re.DOTALL):
            try:
                parsed = json.loads(match.group(1))
                if isinstance(parsed, list):
                    components.extend(parsed)
                elif isinstance(parsed, dict):
                    # Single component wrapped in a dict
                    components.append(parsed)
            except json.JSONDecodeError:
                logger.warning("Failed to parse components block: %s", match.group(1)[:200])

        # Extract spec_update blocks
        for match in re.finditer(r"```spec_update\s*\n(.*?)\n```", text, re.DOTALL):
            try:
                updates = json.loads(match.group(1))
                spec_updates.update(updates)
            except json.JSONDecodeError:
                logger.warning("Failed to parse spec_update block: %s", match.group(1)[:100])

        # Extract verification blocks
        for match in re.finditer(r"```verification\s*\n(.*?)\n```", text, re.DOTALL):
            try:
                verification = json.loads(match.group(1))
            except json.JSONDecodeError:
                logger.warning("Failed to parse verification block: %s", match.group(1)[:100])

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

        # Clean display message: remove structured blocks, keep prose + code
        clean_text = text
        clean_text = re.sub(r"```components\s*\n.*?\n```", "", clean_text, flags=re.DOTALL)
        clean_text = re.sub(r"```spec_update\s*\n.*?\n```", "", clean_text, flags=re.DOTALL)
        clean_text = re.sub(r"```verification\s*\n.*?\n```", "", clean_text, flags=re.DOTALL)
        clean_text = re.sub(r"```options\s*\n.*?\n```", "", clean_text, flags=re.DOTALL)
        clean_text = clean_text.strip()

        # Determine response type based on what was generated
        if components:
            response_type = "generation"
        elif code_blocks:
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
            components=components,
            verification=verification,
            options=options,
            model_used=model,
        )
