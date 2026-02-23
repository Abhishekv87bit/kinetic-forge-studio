import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data


@pytest.mark.asyncio
async def test_health_includes_cache_stats():
    """Health endpoint should include cache statistics (GAP-PPL-009)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert "cache" in data
    assert "caches" in data["cache"]
    # Should have our 3 named caches
    cache_names = set(data["cache"]["caches"].keys())
    assert "system_prompt" in cache_names
    assert "library_search" in cache_names
    assert "cadquery_execution" in cache_names
