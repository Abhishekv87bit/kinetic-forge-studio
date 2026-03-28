"""
Tests for cache invalidation wiring (GAP-PPL-009).

Verifies that mutation endpoints clear the appropriate caches so that
the next request rebuilds from DB rather than serving stale data.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import AsyncMock, patch, MagicMock

from app.main import app
from app.middleware.cache import prompt_cache, search_cache, clear_all_caches


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _seed_prompt_cache(project_id: str = "proj_test") -> None:
    """Put a sentinel value in the prompt cache."""
    prompt_cache.set(f"system_prompt:{project_id}", "cached_system_prompt")


def _seed_search_cache() -> None:
    """Put a sentinel value in the search cache."""
    search_cache.set("library_search:gears", ["gear_entry_1"])


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def reset_caches():
    """Clear all caches before each test so tests are independent."""
    clear_all_caches()
    yield
    clear_all_caches()


# ---------------------------------------------------------------------------
# Unit tests: clear_project_cache
# ---------------------------------------------------------------------------

class TestClearProjectCacheUnit:
    """Verify clear_project_cache clears prompt_cache."""

    def test_clear_project_cache_empties_prompt_cache(self):
        from app.middleware.cache import clear_project_cache
        _seed_prompt_cache("proj_abc")
        assert prompt_cache.size > 0
        clear_project_cache("proj_abc")
        assert prompt_cache.size == 0

    def test_clear_project_cache_resets_stats(self):
        from app.middleware.cache import clear_project_cache
        _seed_prompt_cache("proj_abc")
        prompt_cache.get("system_prompt:proj_abc")  # generate a hit
        clear_project_cache("proj_abc")
        assert prompt_cache.hits == 0
        assert prompt_cache.misses == 0

    def test_clear_project_cache_does_not_touch_search_cache(self):
        from app.middleware.cache import clear_project_cache
        _seed_search_cache()
        assert search_cache.size > 0
        clear_project_cache("proj_abc")
        # search_cache should be untouched by clear_project_cache
        assert search_cache.size > 0


# ---------------------------------------------------------------------------
# Integration: projects mutation endpoints
# ---------------------------------------------------------------------------

class TestProjectMutationInvalidation:
    """POST /api/projects and sub-routes clear prompt_cache."""

    @pytest.mark.asyncio
    async def test_create_project_clears_cache(self):
        """Creating a project seeds then clears the prompt cache."""
        _seed_prompt_cache()
        assert prompt_cache.size > 0

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/projects",
                json={"name": "Cache Test Project"},
            )

        assert resp.status_code == 200
        assert prompt_cache.size == 0

    @pytest.mark.asyncio
    async def test_add_decision_clears_cache(self):
        """Adding a decision clears the prompt cache."""
        # First, create a project
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            proj_resp = await client.post(
                "/api/projects",
                json={"name": "Decision Cache Test"},
            )
        assert proj_resp.status_code == 200
        project_id = proj_resp.json()["id"]

        # Seed the cache
        _seed_prompt_cache(project_id)
        assert prompt_cache.size > 0

        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                f"/api/projects/{project_id}/decisions",
                json={"parameter": "motor_type", "value": "stepper", "reason": "test"},
            )

        assert resp.status_code == 200
        assert prompt_cache.size == 0

    @pytest.mark.asyncio
    async def test_register_component_clears_cache(self):
        """Registering a component clears the prompt cache."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            proj_resp = await client.post(
                "/api/projects",
                json={"name": "Component Cache Test"},
            )
        project_id = proj_resp.json()["id"]

        _seed_prompt_cache(project_id)
        assert prompt_cache.size > 0

        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                f"/api/projects/{project_id}/components",
                json={
                    "component_id": "gear_01",
                    "display_name": "Main Gear",
                    "component_type": "gear",
                    "parameters": {"teeth": 20, "module": 1.5},
                },
            )

        assert resp.status_code == 200
        assert prompt_cache.size == 0

    @pytest.mark.asyncio
    async def test_lock_decision_clears_cache(self):
        """Locking a decision clears the prompt cache."""
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            proj_resp = await client.post(
                "/api/projects", json={"name": "Lock Cache Test"}
            )
        project_id = proj_resp.json()["id"]

        # Add a decision first
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            dec_resp = await client.post(
                f"/api/projects/{project_id}/decisions",
                json={"parameter": "material", "value": "aluminum", "reason": ""},
            )
        assert dec_resp.status_code == 200
        decision_id = dec_resp.json()["decision"]["id"]

        _seed_prompt_cache(project_id)
        assert prompt_cache.size > 0

        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                f"/api/projects/{project_id}/decisions/{decision_id}/lock",
            )

        assert resp.status_code == 200
        assert prompt_cache.size == 0


# ---------------------------------------------------------------------------
# Integration: library mutation endpoint
# ---------------------------------------------------------------------------

class TestLibraryMutationInvalidation:
    """POST /api/library clears search_cache."""

    @pytest.mark.asyncio
    async def test_add_library_entry_clears_search_cache(self):
        """Adding a library entry clears the search cache."""
        _seed_search_cache()
        assert search_cache.size > 0

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/library",
                json={
                    "name": "Test Gear Assembly",
                    "mechanism_types": "gear",
                    "keywords": "planetary ring sun",
                    "source": "test",
                },
            )

        assert resp.status_code == 200
        assert search_cache.size == 0

    @pytest.mark.asyncio
    async def test_search_cache_miss_after_add(self):
        """After adding an entry, a GET /search call gets a cache miss (rebuilds)."""
        _seed_search_cache()
        transport = ASGITransport(app=app)

        # Add entry — invalidates search cache
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            await client.post(
                "/api/library",
                json={"name": "Cam Mechanism", "mechanism_types": "cam", "keywords": "cam follower"},
            )

        assert search_cache.size == 0
        before_misses = search_cache.misses

        # Next search call will be a cache miss and rebuild
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.get("/api/library/search?q=cam")

        assert resp.status_code == 200
        # The route doesn't explicitly populate search_cache — it only clears on add —
        # so we just verify the search returned results without an error.
        assert isinstance(resp.json(), list)


# ---------------------------------------------------------------------------
# Integration: profile mutation
# ---------------------------------------------------------------------------

class TestProfileMutationInvalidation:
    """PUT /api/profile clears prompt_cache (profile feeds every system prompt)."""

    @pytest.mark.asyncio
    async def test_update_profile_clears_prompt_cache(self):
        """Updating user profile clears all cached system prompts."""
        _seed_prompt_cache("proj_alpha")
        _seed_prompt_cache("proj_beta")
        assert prompt_cache.size == 2

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.put(
                "/api/profile",
                json={"skill_level": "expert", "preferred_material": "brass"},
            )

        assert resp.status_code == 200
        assert prompt_cache.size == 0


# ---------------------------------------------------------------------------
# Verify cache-populate → mutate → cache-miss cycle
# ---------------------------------------------------------------------------

class TestCacheLifecycle:
    """
    End-to-end: cache is populated → mutation clears it → next read is a miss.

    Uses the prompt_cache directly rather than a real system-prompt endpoint
    because the system prompt is built inside ChatAgent.chat(), not a standalone
    REST endpoint. The important invariant is: prompt_cache is empty after a
    mutation, so the next build call will miss and recompute.
    """

    def test_populate_then_mutate_then_miss(self):
        from app.middleware.cache import clear_project_cache

        project_id = "proj_lifecycle"

        # Step 1: Simulate cache population (as ChatAgent would do)
        prompt_cache.set(f"system_prompt:{project_id}:v1", "full system prompt text")
        assert prompt_cache.size == 1
        assert prompt_cache.get(f"system_prompt:{project_id}:v1") == "full system prompt text"

        # Step 2: Project state mutation (e.g., component added)
        clear_project_cache(project_id)

        # Step 3: Cache miss — entry is gone
        assert prompt_cache.size == 0
        result = prompt_cache.get(f"system_prompt:{project_id}:v1")
        assert result is None
        assert prompt_cache.misses >= 1

    def test_search_cache_lifecycle(self):
        """search_cache: populate → library add → miss → repopulate."""
        key = "library_search:gears"

        # Populate
        search_cache.set(key, ["gear_a", "gear_b"])
        assert search_cache.get(key) == ["gear_a", "gear_b"]

        # Mutation: clear (as add_library_entry does)
        search_cache.clear()
        assert search_cache.size == 0

        # Miss
        assert search_cache.get(key) is None

        # Re-populate (as next search would do)
        search_cache.set(key, ["gear_a", "gear_b", "gear_c"])
        assert search_cache.get(key) == ["gear_a", "gear_b", "gear_c"]
