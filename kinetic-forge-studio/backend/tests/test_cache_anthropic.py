"""Tests for Anthropic prompt caching header (GAP-PPL-009 Layer 1)."""

from __future__ import annotations

import json
import logging
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


class TestCacheUsageParsing:
    """Verify cache usage fields are parsed from Claude response and stats are logged."""

    def _make_agent_and_mock(self, usage_payload: dict):
        """Return (agent, mock_client) with a pre-configured mock response."""
        from app.orchestrator.chat_agent import ChatAgent

        agent = ChatAgent()

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [{"type": "text", "text": "Test response"}],
            "model": "claude-sonnet-4-20250514",
            "usage": usage_payload,
        }

        async def mock_post(url, **kwargs):
            return mock_response

        mock_client = AsyncMock()
        mock_client.post = mock_post
        return agent, mock_client

    @pytest.mark.asyncio
    async def test_cache_fields_are_parsed_and_logged(self, caplog):
        """Cache usage fields in the API response are parsed and emitted via logger.info."""
        agent, mock_client = self._make_agent_and_mock({
            "input_tokens": 200,
            "output_tokens": 80,
            "cache_creation_input_tokens": 1500,
            "cache_read_input_tokens": 300,
        })

        with patch.object(agent, "_get_client", return_value=mock_client):
            with patch("app.orchestrator.chat_agent.settings") as mock_settings:
                mock_settings.claude_api_key = "test-key"
                mock_settings.claude_model = "claude-sonnet-4-20250514"
                mock_settings.claude_max_tokens = 4096

                with caplog.at_level(logging.INFO, logger="app.orchestrator.chat_agent"):
                    result = await agent._call_claude(
                        system_prompt="You are a design assistant.",
                        messages=[{"role": "user", "content": "hello"}],
                    )

        assert result is not None, "Expected a valid response dict, got None"

        # Find the cache-stats log line
        cache_log_lines = [r.message for r in caplog.records if "cache stats" in r.message.lower()]
        assert cache_log_lines, (
            "Expected at least one log line containing 'cache stats', found none. "
            f"All log messages: {[r.message for r in caplog.records]}"
        )

        stats_line = cache_log_lines[0]
        assert "created=1500" in stats_line, f"cache_creation count missing: {stats_line}"
        assert "read=300" in stats_line, f"cache_read count missing: {stats_line}"
        assert "input=200" in stats_line, f"input_tokens missing: {stats_line}"
        assert "output=80" in stats_line, f"output_tokens missing: {stats_line}"

    @pytest.mark.asyncio
    async def test_missing_cache_fields_default_to_zero(self, caplog):
        """If cache fields are absent from the response, they default to 0 without error."""
        agent, mock_client = self._make_agent_and_mock({
            "input_tokens": 50,
            "output_tokens": 20,
            # cache_creation_input_tokens and cache_read_input_tokens deliberately absent
        })

        with patch.object(agent, "_get_client", return_value=mock_client):
            with patch("app.orchestrator.chat_agent.settings") as mock_settings:
                mock_settings.claude_api_key = "test-key"
                mock_settings.claude_model = "claude-sonnet-4-20250514"
                mock_settings.claude_max_tokens = 4096

                with caplog.at_level(logging.INFO, logger="app.orchestrator.chat_agent"):
                    result = await agent._call_claude(
                        system_prompt="You are a design assistant.",
                        messages=[{"role": "user", "content": "hello"}],
                    )

        assert result is not None, "Expected a valid response dict, got None"

        cache_log_lines = [r.message for r in caplog.records if "cache stats" in r.message.lower()]
        assert cache_log_lines, "Expected cache stats log line even when fields absent"

        stats_line = cache_log_lines[0]
        assert "created=0" in stats_line, f"Expected created=0 for absent field: {stats_line}"
        assert "read=0" in stats_line, f"Expected read=0 for absent field: {stats_line}"
