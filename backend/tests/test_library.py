"""Tests for the reference library (full-text search + API routes)."""

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db.library import LibraryManager


@pytest.fixture(autouse=True)
async def reset_pm(tmp_path, monkeypatch):
    from app.routes import projects
    from app.models.project import ProjectManager
    pm = ProjectManager(data_dir=tmp_path)
    projects._pm = pm
    yield
    projects._pm = None


@pytest.fixture
async def library_manager(tmp_path):
    """Create a LibraryManager with a fresh database."""
    from app.db.database import Database
    db = Database(tmp_path / "test_lib.db")
    await db.connect()
    lm = LibraryManager(db)
    yield lm
    await db.close()


class TestLibraryManagerUnit:
    @pytest.mark.asyncio
    async def test_add_entry(self, library_manager):
        entry = await library_manager.add(
            name="Four-Bar Linkage",
            mechanism_types="four-bar,linkage",
            keywords="oscillating,smooth,brass",
            source="user",
        )
        assert entry["name"] == "Four-Bar Linkage"
        assert len(entry["id"]) == 12

    @pytest.mark.asyncio
    async def test_get_entry(self, library_manager):
        entry = await library_manager.add(name="Test Gear", mechanism_types="gear")
        fetched = await library_manager.get(entry["id"])
        assert fetched["name"] == "Test Gear"
        assert fetched["mechanism_types"] == "gear"

    @pytest.mark.asyncio
    async def test_get_nonexistent_raises(self, library_manager):
        with pytest.raises(ValueError, match="not found"):
            await library_manager.get("nonexistent")

    @pytest.mark.asyncio
    async def test_search_by_name(self, library_manager):
        await library_manager.add(name="Geneva Drive", mechanism_types="geneva")
        await library_manager.add(name="Scotch Yoke", mechanism_types="slider-crank")
        results = await library_manager.search("Geneva")
        assert len(results) == 1
        assert results[0]["name"] == "Geneva Drive"

    @pytest.mark.asyncio
    async def test_search_by_mechanism_type(self, library_manager):
        await library_manager.add(name="Entry A", mechanism_types="cam-follower")
        await library_manager.add(name="Entry B", mechanism_types="gear-train")
        await library_manager.add(name="Entry C", mechanism_types="cam-follower,lever")
        results = await library_manager.search("cam")
        assert len(results) == 2

    @pytest.mark.asyncio
    async def test_search_by_keyword(self, library_manager):
        await library_manager.add(name="Smooth Oscillator", keywords="smooth,quiet,brass")
        await library_manager.add(name="Noisy Ratchet", keywords="loud,clicking")
        results = await library_manager.search("brass")
        assert len(results) == 1
        assert results[0]["name"] == "Smooth Oscillator"

    @pytest.mark.asyncio
    async def test_search_empty_query_returns_all(self, library_manager):
        await library_manager.add(name="Entry 1")
        await library_manager.add(name="Entry 2")
        results = await library_manager.search("")
        assert len(results) == 2

    @pytest.mark.asyncio
    async def test_list_all(self, library_manager):
        await library_manager.add(name="Entry 1")
        await library_manager.add(name="Entry 2")
        await library_manager.add(name="Entry 3")
        all_entries = await library_manager.list_all()
        assert len(all_entries) == 3

    @pytest.mark.asyncio
    async def test_delete_entry(self, library_manager):
        entry = await library_manager.add(name="To Delete")
        result = await library_manager.delete(entry["id"])
        assert result is True
        all_entries = await library_manager.list_all()
        assert len(all_entries) == 0

    @pytest.mark.asyncio
    async def test_delete_nonexistent(self, library_manager):
        result = await library_manager.delete("nonexistent")
        assert result is False

    @pytest.mark.asyncio
    async def test_entry_with_dimensions(self, library_manager):
        entry = await library_manager.add(
            name="Compact Gear",
            envelope_x=50.0,
            envelope_y=50.0,
            envelope_z=20.0,
        )
        fetched = await library_manager.get(entry["id"])
        assert fetched["envelope_x"] == 50.0
        assert fetched["envelope_z"] == 20.0


class TestLibraryAPI:
    @pytest.mark.asyncio
    async def test_add_and_search(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            # Add entries
            res = await c.post("/api/library", json={
                "name": "Cam Follower Drive",
                "mechanism_types": "cam-follower",
                "keywords": "reciprocating,precision",
            })
            assert res.status_code == 200
            entry = res.json()
            assert entry["name"] == "Cam Follower Drive"

            # Search
            res = await c.get("/api/library/search", params={"q": "cam"})
            assert res.status_code == 200
            results = res.json()
            assert len(results) == 1
            assert results[0]["name"] == "Cam Follower Drive"

    @pytest.mark.asyncio
    async def test_get_entry_by_id(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            res = await c.post("/api/library", json={"name": "Test Mechanism"})
            entry_id = res.json()["id"]

            res = await c.get(f"/api/library/{entry_id}")
            assert res.status_code == 200
            assert res.json()["name"] == "Test Mechanism"

    @pytest.mark.asyncio
    async def test_get_nonexistent_returns_404(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            res = await c.get("/api/library/nonexistent_id")
            assert res.status_code == 404

    @pytest.mark.asyncio
    async def test_search_empty_query(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            await c.post("/api/library", json={"name": "Entry 1"})
            await c.post("/api/library", json={"name": "Entry 2"})

            res = await c.get("/api/library/search", params={"q": ""})
            assert res.status_code == 200
            assert len(res.json()) == 2

    @pytest.mark.asyncio
    async def test_search_multiple_terms(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            await c.post("/api/library", json={
                "name": "Brass Geneva",
                "keywords": "brass,precision",
                "mechanism_types": "geneva",
            })
            await c.post("/api/library", json={
                "name": "Steel Gear Train",
                "keywords": "steel,robust",
                "mechanism_types": "gear-train",
            })

            # Search for "brass" should find the geneva entry
            res = await c.get("/api/library/search", params={"q": "brass"})
            assert res.status_code == 200
            results = res.json()
            assert len(results) >= 1
            names = [r["name"] for r in results]
            assert "Brass Geneva" in names
