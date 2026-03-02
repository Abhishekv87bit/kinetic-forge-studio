"""Tests for LLM client wrapper (multi-provider)."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from pydantic import BaseModel

from app.agents.claude_client import call_claude, _parse_response, _extract_json


class SampleOutput(BaseModel):
    """Test model for structured output parsing."""
    score: float
    reasoning: str


async def test_call_claude_raw():
    """Should return raw text + usage when no response_model given."""
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content="Hello from Groq"))]
    mock_response.usage = MagicMock(prompt_tokens=10, completion_tokens=5)

    with patch("app.agents.claude_client._get_groq_client") as mock_get, \
         patch("app.agents.claude_client.settings") as mock_settings:
        mock_settings.llm_provider = "groq"
        mock_settings.groq_model = "llama-3.3-70b-versatile"
        mock_settings.claude_max_tokens = 4096
        mock_client = AsyncMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_get.return_value = mock_client

        result = await call_claude(
            system_prompt="You are a test assistant.",
            user_prompt="Say hello.",
        )

    assert result["text"] == "Hello from Groq"
    assert "usage" in result


async def test_call_claude_with_response_model():
    """Should parse JSON response into Pydantic model when response_model given."""
    json_text = '{"score": 0.85, "reasoning": "Strong fundamentals"}'
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content=json_text))]
    mock_response.usage = MagicMock(prompt_tokens=50, completion_tokens=20)

    with patch("app.agents.claude_client._get_groq_client") as mock_get, \
         patch("app.agents.claude_client.settings") as mock_settings:
        mock_settings.llm_provider = "groq"
        mock_settings.groq_model = "llama-3.3-70b-versatile"
        mock_settings.claude_max_tokens = 4096
        mock_client = AsyncMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_get.return_value = mock_client

        result = await call_claude(
            system_prompt="You are an analyst.",
            user_prompt="Analyze AAPL.",
            response_model=SampleOutput,
        )

    assert isinstance(result, SampleOutput)
    assert result.score == 0.85
    assert result.reasoning == "Strong fundamentals"


async def test_call_claude_invalid_json_raises():
    """Should raise ValueError when LLM returns non-JSON but model expected."""
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content="Not valid JSON at all"))]
    mock_response.usage = MagicMock(prompt_tokens=10, completion_tokens=5)

    with patch("app.agents.claude_client._get_groq_client") as mock_get, \
         patch("app.agents.claude_client.settings") as mock_settings:
        mock_settings.llm_provider = "groq"
        mock_settings.groq_model = "llama-3.3-70b-versatile"
        mock_settings.claude_max_tokens = 4096
        mock_client = AsyncMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_get.return_value = mock_client

        with pytest.raises(ValueError, match="Failed to parse"):
            await call_claude(
                system_prompt="You are a test.",
                user_prompt="Test.",
                response_model=SampleOutput,
            )


def test_extract_json_from_markdown_fence():
    """Should extract JSON from markdown code fences."""
    fenced = '```json\n{"score": 0.72, "reasoning": "Moderate"}\n```'
    assert _extract_json(fenced) == '{"score": 0.72, "reasoning": "Moderate"}'


def test_extract_json_plain():
    """Should return plain JSON unchanged."""
    plain = '{"score": 0.5, "reasoning": "OK"}'
    assert _extract_json(plain) == plain


def test_parse_response_with_model():
    """Should parse raw text into Pydantic model."""
    text = '{"score": 0.85, "reasoning": "Strong"}'
    result = _parse_response(text, SampleOutput, "test")
    assert isinstance(result, SampleOutput)
    assert result.score == 0.85


def test_parse_response_without_model():
    """Should return dict with text key when no model."""
    result = _parse_response("Hello", None, "test")
    assert result["text"] == "Hello"


async def test_call_claude_passes_max_tokens():
    """Should use max_tokens override."""
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content="ok"))]
    mock_response.usage = MagicMock(prompt_tokens=5, completion_tokens=2)

    with patch("app.agents.claude_client._get_groq_client") as mock_get, \
         patch("app.agents.claude_client.settings") as mock_settings:
        mock_settings.llm_provider = "groq"
        mock_settings.groq_model = "llama-3.3-70b-versatile"
        mock_settings.claude_max_tokens = 4096
        mock_client = AsyncMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_get.return_value = mock_client

        await call_claude(
            system_prompt="Test.",
            user_prompt="Test.",
            max_tokens=1024,
        )

    call_kwargs = mock_client.chat.completions.create.call_args.kwargs
    assert call_kwargs["max_tokens"] == 1024
