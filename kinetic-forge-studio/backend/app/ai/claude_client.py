"""
Claude API client for Kinetic Forge Studio.

Wraps httpx calls to the Anthropic messages endpoint. All API communication
goes through this single client so we can mock it cleanly in tests and the
orchestrator doesn't need to know about HTTP details.
"""

from dataclasses import dataclass
from typing import Any

import httpx

from app.config import settings


ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
DEFAULT_MODEL = "claude-sonnet-4-20250514"
DEFAULT_MAX_TOKENS = 4096


@dataclass
class ClaudeResponse:
    """Structured response from the Claude API."""
    content: str
    model: str
    usage: dict[str, int]
    stop_reason: str

    def to_dict(self) -> dict:
        return {
            "content": self.content,
            "model": self.model,
            "usage": self.usage,
            "stop_reason": self.stop_reason,
        }


class ClaudeClient:
    """
    Async client for the Claude (Anthropic) Messages API.

    Usage:
        client = ClaudeClient()  # uses settings.claude_api_key
        response = await client.send("Design a planetary gear train...")
    """

    def __init__(self, api_key: str | None = None, model: str = DEFAULT_MODEL):
        self.api_key = api_key or settings.claude_api_key
        self.model = model
        self._http_client: httpx.AsyncClient | None = None

    async def _get_client(self) -> httpx.AsyncClient:
        """Lazily create the httpx async client."""
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(timeout=60.0)
        return self._http_client

    async def send(
        self,
        user_message: str,
        system_prompt: str = "",
        max_tokens: int = DEFAULT_MAX_TOKENS,
        temperature: float = 0.7,
    ) -> ClaudeResponse:
        """
        Send a message to the Claude API and return the response.

        Args:
            user_message: The user's message content.
            system_prompt: Optional system prompt for context.
            max_tokens: Maximum tokens in the response.
            temperature: Sampling temperature (0.0 - 1.0).

        Returns:
            ClaudeResponse with the assistant's reply.

        Raises:
            ValueError: If no API key is configured.
            httpx.HTTPStatusError: If the API returns an error.
        """
        if not self.api_key:
            raise ValueError(
                "Claude API key not configured. Set KFS_CLAUDE_API_KEY environment variable."
            )

        client = await self._get_client()

        payload: dict[str, Any] = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": [{"role": "user", "content": user_message}],
        }
        if system_prompt:
            payload["system"] = system_prompt

        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }

        response = await client.post(ANTHROPIC_API_URL, json=payload, headers=headers)
        response.raise_for_status()
        data = response.json()

        # Extract text content from the response
        content_blocks = data.get("content", [])
        text = ""
        for block in content_blocks:
            if block.get("type") == "text":
                text += block.get("text", "")

        return ClaudeResponse(
            content=text,
            model=data.get("model", self.model),
            usage=data.get("usage", {}),
            stop_reason=data.get("stop_reason", "unknown"),
        )

    async def close(self):
        """Close the underlying HTTP client."""
        if self._http_client:
            await self._http_client.aclose()
            self._http_client = None
