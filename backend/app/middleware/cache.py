"""
Async-aware TTL cache with LRU eviction and observability.
==========================================================
GAP-PPL-009 -- Caching Layer

Provides TTLCache class and pre-configured cache instances for:
  - System prompt building (sync, invalidated on project state change)
  - Library FTS5 search (async, 1-hour TTL)
  - CadQuery execution (async, permanent / LRU-evicted)

Usage:
    from app.middleware.cache import prompt_cache, search_cache, execution_cache
    from app.middleware.cache import get_cache_stats, clear_all_caches
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import time
from collections import OrderedDict
from typing import Any

logger = logging.getLogger("cache")


class TTLCache:
    """
    Thread/async-safe in-memory cache with TTL expiry and LRU eviction.

    Args:
        max_size: Maximum number of entries. Oldest accessed entry evicted on overflow.
        ttl_seconds: Time-to-live in seconds. 0 means entries never expire.
        name: Human-readable name for stats/logging.
    """

    def __init__(self, max_size: int = 64, ttl_seconds: int | float = 0, name: str = ""):
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
        self.name = name or f"cache_{id(self)}"
        self.hits = 0
        self.misses = 0
        self._entries: OrderedDict[str, tuple[Any, float]] = OrderedDict()
        self._lock = asyncio.Lock()

    # -- Sync API (for non-async callers) --

    def get(self, key: str) -> Any | None:
        """Get a value by key. Returns None if missing or expired."""
        entry = self._entries.get(key)
        if entry is None:
            self.misses += 1
            return None

        value, timestamp = entry
        if self.ttl_seconds > 0 and (time.time() - timestamp) > self.ttl_seconds:
            del self._entries[key]
            self.misses += 1
            return None

        # Move to end (most recently used)
        self._entries.move_to_end(key)
        self.hits += 1
        return value

    def set(self, key: str, value: Any) -> None:
        """Set a value. Evicts oldest entry if at capacity."""
        if key in self._entries:
            self._entries.move_to_end(key)
            self._entries[key] = (value, time.time())
            return

        if len(self._entries) >= self.max_size:
            self._entries.popitem(last=False)  # evict oldest

        self._entries[key] = (value, time.time())

    def clear(self) -> None:
        """Remove all entries and reset stats."""
        self._entries.clear()
        self.hits = 0
        self.misses = 0

    @property
    def size(self) -> int:
        return len(self._entries)

    def stats(self) -> dict:
        """Return cache statistics."""
        total = self.hits + self.misses
        return {
            "name": self.name,
            "size": self.size,
            "max_size": self.max_size,
            "hits": self.hits,
            "misses": self.misses,
            "hit_rate": round(self.hits / total, 3) if total > 0 else 0.0,
        }

    # -- Async API (wraps sync with lock) --

    async def aget(self, key: str) -> Any | None:
        """Async get with lock protection."""
        async with self._lock:
            return self.get(key)

    async def aset(self, key: str, value: Any) -> None:
        """Async set with lock protection."""
        async with self._lock:
            self.set(key, value)


# ---------------------------------------------------------------------------
# Pre-configured cache instances
# ---------------------------------------------------------------------------

prompt_cache = TTLCache(max_size=32, ttl_seconds=0, name="system_prompt")
search_cache = TTLCache(max_size=128, ttl_seconds=3600, name="library_search")
execution_cache = TTLCache(max_size=64, ttl_seconds=0, name="cadquery_execution")

_ALL_CACHES = [prompt_cache, search_cache, execution_cache]


# ---------------------------------------------------------------------------
# Cache key helpers
# ---------------------------------------------------------------------------

def make_hash_key(*args: Any) -> str:
    """Create a SHA256 hash key from arbitrary arguments via JSON serialization."""
    serialized = json.dumps(args, sort_keys=True, default=str)
    return hashlib.sha256(serialized.encode()).hexdigest()


# ---------------------------------------------------------------------------
# Global operations
# ---------------------------------------------------------------------------

def get_cache_stats() -> dict:
    """Aggregate stats from all cache instances. Wired into /api/health."""
    return {
        "caches": {c.name: c.stats() for c in _ALL_CACHES},
    }


def clear_all_caches() -> None:
    """Reset all caches. Used in tests and on-demand invalidation."""
    for c in _ALL_CACHES:
        c.clear()


def clear_project_cache(project_id: str) -> None:
    """
    Invalidate prompt cache entries for a specific project.

    Called when project state changes (spec update, component registration,
    decision locking). Since prompt cache keys include project-specific data
    (spec, components, decisions), we clear the entire prompt cache -- it's
    small (max 32 entries) and rebuilds quickly.
    """
    prompt_cache.clear()
    logger.info("Cleared prompt cache (project %s state changed)", project_id)
