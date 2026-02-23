"""Tests for the prompt builder and Claude client (mock only, no real API calls)."""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from app.ai.prompt_builder import PromptBuilder, SYSTEM_PROMPT
from app.ai.claude_client import ClaudeClient, ClaudeResponse


# ---------------------------------------------------------------------------
# PromptBuilder Tests
# ---------------------------------------------------------------------------

@pytest.fixture
def builder():
    return PromptBuilder()


def test_system_prompt_exists(builder):
    """System prompt should be non-empty and mention kinetic sculpture."""
    sp = builder.build_system_prompt()
    assert len(sp) > 100
    assert "kinetic" in sp.lower() or "Kinetic" in sp


def test_system_prompt_mentions_rules(builder):
    """System prompt should mention key design rules."""
    sp = builder.build_system_prompt()
    assert "millimeters" in sp.lower()
    assert "single motor" in sp.lower()


def test_user_prompt_basic(builder):
    """Basic user prompt with just a message."""
    prompt = builder.build_user_prompt("Design a planetary gear")
    assert "## User Message" in prompt
    assert "Design a planetary gear" in prompt


def test_user_prompt_with_spec_fields(builder):
    """Prompt includes spec sheet section."""
    fields = {"mechanism_type": "planetary", "envelope_mm": 70, "material": "PLA"}
    prompt = builder.build_user_prompt("Add 3 planets", spec_fields=fields)
    assert "## Current Spec Sheet" in prompt
    assert "mechanism_type" in prompt
    assert "planetary" in prompt
    assert "70" in prompt
    assert "PLA" in prompt


def test_user_prompt_with_locked_decisions(builder):
    """Prompt includes locked decisions section."""
    decisions = [
        {"parameter": "ring_gear.OD", "value": "82mm", "status": "locked", "reason": "Fits housing"},
        {"parameter": "module", "value": "1.5", "status": "locked", "reason": "Standard"},
    ]
    prompt = builder.build_user_prompt("Next step?", locked_decisions=decisions)
    assert "## Locked Decisions" in prompt
    assert "ring_gear.OD" in prompt
    assert "82mm" in prompt
    assert "Fits housing" in prompt
    assert "module" in prompt


def test_user_prompt_with_components(builder):
    """Prompt includes component registry section."""
    components = {
        "ring_01": {"display_name": "Ring Gear", "type": "gear", "parameters": {"teeth": 48}},
        "sun_01": {"display_name": "Sun Gear", "type": "gear", "parameters": {"teeth": 16}},
    }
    prompt = builder.build_user_prompt("Add planets", components=components)
    assert "## Component Registry" in prompt
    assert "Ring Gear" in prompt
    assert "Sun Gear" in prompt
    assert "48" in prompt


def test_user_prompt_with_profile(builder):
    """Prompt includes user profile section."""
    profile = {
        "printer": {"type": "FDM", "nozzle": 0.4, "tolerance": 0.2},
        "preferences": {"default_material": "PLA", "default_module": 1.5},
        "style_tags": ["organic", "wave"],
        "production_target": "metal_and_wood",
    }
    prompt = builder.build_user_prompt("New design", user_profile=profile)
    assert "## User Profile" in prompt
    assert "FDM" in prompt
    assert "0.4" in prompt
    assert "organic" in prompt
    assert "metal_and_wood" in prompt


def test_user_prompt_with_question_context(builder):
    """Prompt includes question context section."""
    prompt = builder.build_user_prompt(
        "I want waves",
        question_context="We need to determine the envelope size before generating geometry."
    )
    assert "## Current Question" in prompt
    assert "envelope size" in prompt


def test_user_prompt_all_sections(builder):
    """Prompt with all sections present and in order."""
    prompt = builder.build_user_prompt(
        user_message="Build it",
        spec_fields={"mechanism_type": "wave"},
        locked_decisions=[{"parameter": "material", "value": "wood", "status": "locked", "reason": ""}],
        components={"wave_01": {"display_name": "Wave Arm", "type": "linkage", "parameters": {}}},
        user_profile={"printer": {"type": "FDM", "nozzle": 0.4, "tolerance": 0.2}},
        question_context="All fields complete. Ready to generate.",
    )
    # Verify all sections exist
    assert "## Current Spec Sheet" in prompt
    assert "## Locked Decisions" in prompt
    assert "## Component Registry" in prompt
    assert "## User Profile" in prompt
    assert "## Current Question" in prompt
    assert "## User Message" in prompt
    # Verify order: spec < decisions < components < profile < question < message
    idx_spec = prompt.index("## Current Spec Sheet")
    idx_decisions = prompt.index("## Locked Decisions")
    idx_components = prompt.index("## Component Registry")
    idx_profile = prompt.index("## User Profile")
    idx_question = prompt.index("## Current Question")
    idx_message = prompt.index("## User Message")
    assert idx_spec < idx_decisions < idx_components < idx_profile < idx_question < idx_message


def test_user_prompt_empty_sections_omitted(builder):
    """Sections with no data should not appear."""
    prompt = builder.build_user_prompt("Just text")
    assert "## Current Spec Sheet" not in prompt
    assert "## Locked Decisions" not in prompt
    assert "## Component Registry" not in prompt
    assert "## User Profile" not in prompt
    assert "## Current Question" not in prompt
    assert "## User Message" in prompt


# ---------------------------------------------------------------------------
# ClaudeClient Tests (Mock only — no real API calls)
# ---------------------------------------------------------------------------

def test_claude_response_to_dict():
    """ClaudeResponse serialization."""
    resp = ClaudeResponse(
        content="Here is a gear design...",
        model="claude-sonnet-4-20250514",
        usage={"input_tokens": 100, "output_tokens": 50},
        stop_reason="end_turn",
    )
    d = resp.to_dict()
    assert d["content"] == "Here is a gear design..."
    assert d["model"] == "claude-sonnet-4-20250514"
    assert d["usage"]["input_tokens"] == 100
    assert d["stop_reason"] == "end_turn"


@pytest.mark.asyncio
async def test_claude_client_no_api_key():
    """Client should raise ValueError if no API key is set."""
    client = ClaudeClient(api_key="")
    with pytest.raises(ValueError, match="API key not configured"):
        await client.send("Hello")
    await client.close()


@pytest.mark.asyncio
async def test_claude_client_sends_correctly():
    """Client should send the right payload to the API (mocked)."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {
        "content": [{"type": "text", "text": "Design response here"}],
        "model": "claude-sonnet-4-20250514",
        "usage": {"input_tokens": 50, "output_tokens": 30},
        "stop_reason": "end_turn",
    }

    mock_http = AsyncMock()
    mock_http.post = AsyncMock(return_value=mock_response)

    client = ClaudeClient(api_key="test-key-123")
    client._http_client = mock_http

    response = await client.send("Design a planetary gear", system_prompt="You are helpful")

    assert response.content == "Design response here"
    assert response.model == "claude-sonnet-4-20250514"
    assert response.stop_reason == "end_turn"

    # Verify the payload was correct
    call_args = mock_http.post.call_args
    payload = call_args.kwargs.get("json") or call_args[1].get("json")
    assert payload["messages"][0]["content"] == "Design a planetary gear"
    assert payload["system"] == "You are helpful"
    assert "x-api-key" in (call_args.kwargs.get("headers") or call_args[1].get("headers"))

    await client.close()
