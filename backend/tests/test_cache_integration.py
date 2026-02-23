"""
Integration tests for cache wiring (GAP-PPL-009).

Tests that search_cache, execution_cache, and prompt_cache are actually
used in their respective code paths (library search, CadQuery execution,
system prompt building).
"""

from __future__ import annotations

import asyncio
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.middleware.cache import (
    clear_all_caches,
    execution_cache,
    make_hash_key,
    prompt_cache,
    search_cache,
)


@pytest.fixture(autouse=True)
def _clear_caches():
    """Reset all caches before and after each test."""
    clear_all_caches()
    yield
    clear_all_caches()


# ---------------------------------------------------------------------------
# Task 1: search_cache in LibraryManager.search()
# ---------------------------------------------------------------------------


class TestSearchCacheIntegration:
    """Verify search_cache is checked/populated by LibraryManager.search()."""

    @pytest.fixture
    async def library_manager(self, tmp_path):
        from app.db.database import Database
        from app.db.library import LibraryManager

        db = Database(tmp_path / "test_cache_int.db")
        await db.connect()
        lm = LibraryManager(db)
        yield lm
        await db.close()

    @pytest.mark.asyncio
    async def test_search_populates_cache(self, library_manager):
        """First search should store results in search_cache."""
        await library_manager.add(name="Planetary Gear", mechanism_types="gear")

        assert search_cache.size == 0
        results = await library_manager.search("Planetary")
        assert len(results) == 1

        # Cache should now have one entry
        assert search_cache.size == 1

    @pytest.mark.asyncio
    async def test_search_returns_cached_on_second_call(self, library_manager):
        """Second identical search should hit the cache, not the DB."""
        await library_manager.add(name="Scotch Yoke", mechanism_types="slider-crank")

        results1 = await library_manager.search("Scotch")
        assert search_cache.misses == 1
        assert search_cache.hits == 0

        results2 = await library_manager.search("Scotch")
        assert search_cache.hits == 1
        assert results1 == results2

    @pytest.mark.asyncio
    async def test_different_queries_cache_separately(self, library_manager):
        """Different queries should have different cache entries."""
        await library_manager.add(name="Geneva Drive", mechanism_types="geneva")
        await library_manager.add(name="Cam Follower", mechanism_types="cam")

        await library_manager.search("Geneva")
        await library_manager.search("Cam")

        assert search_cache.size == 2

    @pytest.mark.asyncio
    async def test_empty_query_is_cached(self, library_manager):
        """Even empty-string queries should be cached."""
        await library_manager.add(name="Entry 1")
        await library_manager.add(name="Entry 2")

        results1 = await library_manager.search("")
        assert search_cache.size == 1

        results2 = await library_manager.search("")
        assert search_cache.hits == 1
        assert len(results1) == len(results2)


# ---------------------------------------------------------------------------
# Task 2: execution_cache in CadQueryEngine.generate()
# ---------------------------------------------------------------------------


class TestExecutionCacheIntegration:
    """Verify execution_cache is checked/populated by CadQueryEngine.generate()."""

    @pytest.mark.asyncio
    async def test_successful_execution_is_cached(self, tmp_path):
        """A successful generate() should store the result in execution_cache."""
        from app.engines.cadquery_engine import CadQueryEngine, GenerationResult

        engine = CadQueryEngine()

        # Mock subprocess to simulate successful execution
        step_file = tmp_path / "test.step"
        stl_file = tmp_path / "test.stl"

        async def mock_subprocess(*args, **kwargs):
            # Create dummy output files
            step_file.write_text("STEP data")
            stl_file.write_text("STL data")
            proc = MagicMock()
            proc.returncode = 0

            async def communicate():
                return (b"Exported via CadQuery\n", b"")

            proc.communicate = communicate
            return proc

        code = "import cadquery as cq\nresult = cq.Workplane('XY').box(10, 10, 10)"

        assert execution_cache.size == 0

        with patch("asyncio.create_subprocess_exec", side_effect=mock_subprocess):
            result = await engine.generate(code, tmp_path, "test")

        assert result.success is True
        assert execution_cache.size == 1

    @pytest.mark.asyncio
    async def test_failed_execution_is_not_cached(self, tmp_path):
        """A failed generate() should NOT store the result in execution_cache."""
        from app.engines.cadquery_engine import CadQueryEngine

        engine = CadQueryEngine()

        async def mock_subprocess(*args, **kwargs):
            proc = MagicMock()
            proc.returncode = 1

            async def communicate():
                return (b"", b"SyntaxError: invalid syntax")

            proc.communicate = communicate
            return proc

        code = "this is not valid python"

        with patch("asyncio.create_subprocess_exec", side_effect=mock_subprocess):
            result = await engine.generate(code, tmp_path, "test")

        assert result.success is False
        assert execution_cache.size == 0

    @pytest.mark.asyncio
    async def test_cache_hit_skips_execution(self, tmp_path):
        """When cache has a result for the code, subprocess should not be called."""
        from app.engines.cadquery_engine import CadQueryEngine, GenerationResult

        engine = CadQueryEngine()
        code = "import cadquery as cq\nresult = cq.Workplane('XY').box(5, 5, 5)"

        # Pre-populate cache
        cache_key = make_hash_key("cadquery_exec", code)
        cached_result = GenerationResult(
            success=True,
            output_files={"step": Path("/fake/path.step")},
            execution_time=0.5,
        )
        await execution_cache.aset(cache_key, cached_result)

        with patch("asyncio.create_subprocess_exec") as mock_exec:
            result = await engine.generate(code, tmp_path, "test")

        # Subprocess should never have been called
        mock_exec.assert_not_called()
        assert result.success is True
        assert result.execution_time == 0.5


# ---------------------------------------------------------------------------
# Task 3: prompt_cache in ChatAgent.chat()
# ---------------------------------------------------------------------------


class TestPromptCacheIntegration:
    """Verify prompt_cache is checked/populated during system prompt building."""

    @pytest.mark.asyncio
    async def test_system_prompt_is_cached(self):
        """First call builds and caches the system prompt; second call reuses it."""
        from app.orchestrator.chat_agent import ChatAgent

        agent = ChatAgent()

        # Mock the API call so we don't hit a real endpoint
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [{"type": "text", "text": "Hello, I am a design assistant."}],
            "model": "claude-sonnet-4-20250514",
            "usage": {"input_tokens": 100, "output_tokens": 50},
        }

        async def mock_post(url, **kwargs):
            return mock_response

        mock_client = AsyncMock()
        mock_client.post = mock_post
        mock_client.is_closed = False

        spec = {"mechanism_type": "planetary", "envelope_mm": 100}
        components = [{"id": "sun", "component_type": "gear", "parameters": {"teeth": 18}}]

        with patch.object(agent, "_get_client", return_value=mock_client):
            with patch("app.orchestrator.chat_agent.settings") as mock_settings:
                mock_settings.claude_api_key = "test-key"
                mock_settings.claude_model = "claude-sonnet-4-20250514"
                mock_settings.claude_max_tokens = 4096
                mock_settings.preferred_provider = "claude"
                mock_settings.groq_api_key = ""
                mock_settings.grok_api_key = ""
                mock_settings.gemini_api_key = ""

                # First call — should miss and populate cache
                assert prompt_cache.size == 0
                await agent.chat(
                    user_message="Design a gear train",
                    conversation_history=[],
                    spec=spec,
                    components=components,
                )
                assert prompt_cache.size == 1
                assert prompt_cache.misses == 1
                assert prompt_cache.hits == 0

                # Second call with SAME context — should hit cache
                await agent.chat(
                    user_message="Make it bigger",
                    conversation_history=[],
                    spec=spec,
                    components=components,
                )
                assert prompt_cache.hits == 1
                # Still only 1 entry (same key)
                assert prompt_cache.size == 1

    @pytest.mark.asyncio
    async def test_different_context_creates_new_cache_entry(self):
        """Changing spec/components should produce a different cache key."""
        from app.orchestrator.chat_agent import ChatAgent

        agent = ChatAgent()

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [{"type": "text", "text": "OK"}],
            "model": "claude-sonnet-4-20250514",
            "usage": {"input_tokens": 50, "output_tokens": 10},
        }

        async def mock_post(url, **kwargs):
            return mock_response

        mock_client = AsyncMock()
        mock_client.post = mock_post
        mock_client.is_closed = False

        with patch.object(agent, "_get_client", return_value=mock_client):
            with patch("app.orchestrator.chat_agent.settings") as mock_settings:
                mock_settings.claude_api_key = "test-key"
                mock_settings.claude_model = "claude-sonnet-4-20250514"
                mock_settings.claude_max_tokens = 4096
                mock_settings.preferred_provider = "claude"
                mock_settings.groq_api_key = ""
                mock_settings.grok_api_key = ""
                mock_settings.gemini_api_key = ""

                # Call with spec A
                await agent.chat(
                    user_message="hello",
                    conversation_history=[],
                    spec={"mechanism_type": "planetary"},
                )

                # Call with spec B (different)
                await agent.chat(
                    user_message="hello",
                    conversation_history=[],
                    spec={"mechanism_type": "four-bar"},
                )

                # Should have 2 separate cache entries
                assert prompt_cache.size == 2

    @pytest.mark.asyncio
    async def test_no_provider_skips_prompt_building(self):
        """When no AI provider is configured, prompt cache should not be touched."""
        from app.orchestrator.chat_agent import ChatAgent

        agent = ChatAgent()

        with patch("app.orchestrator.chat_agent.settings") as mock_settings:
            mock_settings.claude_api_key = ""
            mock_settings.groq_api_key = ""
            mock_settings.grok_api_key = ""
            mock_settings.gemini_api_key = ""
            mock_settings.preferred_provider = ""

            result = await agent.chat(
                user_message="hello",
                conversation_history=[],
            )

        assert result.response_type == "error"
        # Prompt cache should be untouched — no prompt was built
        assert prompt_cache.size == 0
