"""Tests for Anthropic prompt caching header (GAP-PPL-009 Layer 1)."""

from __future__ import annotations

import json
from unittest.mock import AsyncMock, patch, MagicMock

import pytest


class TestAnthropicCacheControl:
    """Verify cache_control is included in Claude API request body."""

    @pytest.mark.asyncio
    async def test_claude_request_has_cache_control(self):
        """The system prompt must be sent as a content block with cache_control."""
        from app.orchestrator.chat_agent import ChatAgent

        agent = ChatAgent()
        captured_json = {}

        # Mock the httpx client to capture the request body
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [{"type": "text", "text": "Hello"}],
            "model": "claude-sonnet-4-20250514",
            "usage": {
                "input_tokens": 100,
                "output_tokens": 50,
                "cache_creation_input_tokens": 100,
                "cache_read_input_tokens": 0,
            },
        }

        async def mock_post(url, **kwargs):
            captured_json.update(kwargs.get("json", {}))
            return mock_response

        mock_client = AsyncMock()
        mock_client.post = mock_post

        with patch.object(agent, "_get_client", return_value=mock_client):
            with patch("app.orchestrator.chat_agent.settings") as mock_settings:
                mock_settings.claude_api_key = "test-key"
                mock_settings.claude_model = "claude-sonnet-4-20250514"
                mock_settings.claude_max_tokens = 4096

                result = await agent._call_claude(
                    system_prompt="You are a design assistant.",
                    messages=[{"role": "user", "content": "hello"}],
                )

        # Verify system field is a list of content blocks, not a plain string
        system_field = captured_json.get("system")
        assert isinstance(system_field, list), (
            f"Expected system to be a list of content blocks, got {type(system_field)}"
        )
        assert len(system_field) == 1
        block = system_field[0]
        assert block["type"] == "text"
        assert block["text"] == "You are a design assistant."
        assert block["cache_control"] == {"type": "ephemeral"}
