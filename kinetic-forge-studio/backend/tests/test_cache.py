"""Tests for TTLCache + caching decorators (GAP-PPL-009)."""

from __future__ import annotations

import asyncio
import time
from unittest.mock import patch

import pytest

# We'll import from the module we're about to create
from app.middleware.cache import TTLCache, get_cache_stats, clear_all_caches


# ---------------------------------------------------------------------------
# TTLCache unit tests
# ---------------------------------------------------------------------------

class TestTTLCacheBasic:
    """Core get/set/eviction behavior."""

    def test_set_and_get(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("key1", "value1")
        assert cache.get("key1") == "value1"

    def test_get_missing_returns_none(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        assert cache.get("nonexistent") is None

    def test_ttl_expiry(self):
        cache = TTLCache(max_size=10, ttl_seconds=1)
        cache.set("key1", "value1")
        assert cache.get("key1") == "value1"
        # Simulate time passing by manipulating the stored timestamp
        cache._entries["key1"] = (cache._entries["key1"][0], time.time() - 2)
        assert cache.get("key1") is None

    def test_lru_eviction(self):
        cache = TTLCache(max_size=2, ttl_seconds=60)
        cache.set("a", 1)
        cache.set("b", 2)
        cache.set("c", 3)  # should evict "a"
        assert cache.get("a") is None
        assert cache.get("b") == 2
        assert cache.get("c") == 3

    def test_set_updates_existing(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("key1", "old")
        cache.set("key1", "new")
        assert cache.get("key1") == "new"
        assert cache.size == 1

    def test_clear(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("a", 1)
        cache.set("b", 2)
        cache.clear()
        assert cache.size == 0
        assert cache.get("a") is None

    def test_no_ttl_means_permanent(self):
        cache = TTLCache(max_size=10, ttl_seconds=0)
        cache.set("key1", "value1")
        # Manipulate timestamp to 1 hour ago
        cache._entries["key1"] = (cache._entries["key1"][0], time.time() - 3600)
        assert cache.get("key1") == "value1"  # still there


class TestTTLCacheStats:
    """Hit/miss counting."""

    def test_hit_miss_tracking(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("a", 1)
        cache.get("a")       # hit
        cache.get("missing")  # miss
        cache.get("a")       # hit
        assert cache.hits == 2
        assert cache.misses == 1

    def test_stats_dict(self):
        cache = TTLCache(max_size=10, ttl_seconds=60, name="test")
        cache.set("a", 1)
        cache.get("a")
        stats = cache.stats()
        assert stats["name"] == "test"
        assert stats["size"] == 1
        assert stats["max_size"] == 10
        assert stats["hits"] == 1
        assert stats["misses"] == 0
        assert stats["hit_rate"] == 1.0


class TestTTLCacheAsync:
    """Async-safe operations."""

    @pytest.mark.asyncio
    async def test_async_set_get(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        await cache.aset("key1", "value1")
        result = await cache.aget("key1")
        assert result == "value1"

    @pytest.mark.asyncio
    async def test_concurrent_access(self):
        """Multiple coroutines writing simultaneously should not corrupt state."""
        cache = TTLCache(max_size=100, ttl_seconds=60)

        async def writer(prefix: str, count: int):
            for i in range(count):
                await cache.aset(f"{prefix}_{i}", i)

        await asyncio.gather(
            writer("a", 20),
            writer("b", 20),
            writer("c", 20),
        )
        # All 60 entries should be present (max_size=100)
        total = sum(1 for k in [f"{p}_{i}" for p in "abc" for i in range(20)]
                    if cache.get(k) is not None)
        assert total == 60


class TestGetCacheStats:
    """Global stats aggregation."""

    def test_get_cache_stats_returns_dict(self):
        stats = get_cache_stats()
        assert isinstance(stats, dict)
        assert "caches" in stats


class TestClearAllCaches:
    """Global cache reset."""

    def test_clear_all_resets_everything(self):
        clear_all_caches()
        stats = get_cache_stats()
        for cache_info in stats["caches"].values():
            assert cache_info["size"] == 0
