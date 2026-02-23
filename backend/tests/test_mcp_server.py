"""Tests for KFS MCP server (GAP-PPL-014)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch, AsyncMock, MagicMock

import pytest

# Import the server module (will fail until we create it)
from kfs_mcp_server import (
    vlad_validate,
    cadquery_execute,
    library_search,
)


class TestVladValidate:
    """VLAD validation tool via MCP."""

    @pytest.mark.asyncio
    async def test_valid_module_returns_structured_json(self):
        """Valid module path should return tier results."""
        mock_result = subprocess.CompletedProcess(
            args=["python", "vlad.py", "--json", "test_module"],
            returncode=0,
            stdout=json.dumps({
                "module": "test_module",
                "mechanism_type": "gear",
                "tiers": {"A": "PASS", "B": "PASS", "C": "PASS"},
                "total_checks": 12,
                "passed": 12,
                "failed": 0,
            }),
            stderr="",
        )
        # Mock asyncio.to_thread which wraps subprocess.run
        with patch("kfs_mcp_server.asyncio.to_thread", return_value=mock_result):
            result = await vlad_validate(module_path="test_module")

        parsed = json.loads(result)
        assert parsed["success"] is True
        assert "tiers" in parsed["data"]
        assert parsed["error"] is None

    @pytest.mark.asyncio
    async def test_invalid_module_returns_error(self):
        """Nonexistent module should return error, not crash."""
        mock_result = subprocess.CompletedProcess(
            args=["python", "vlad.py", "--json", "nonexistent"],
            returncode=2,
            stdout="",
            stderr="ModuleNotFoundError: No module named 'nonexistent'",
        )
        with patch("kfs_mcp_server.asyncio.to_thread", return_value=mock_result):
            result = await vlad_validate(module_path="nonexistent")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "ModuleNotFoundError" in parsed["error"]

    @pytest.mark.asyncio
    async def test_timeout_returns_error(self):
        """VLAD subprocess timeout should return structured error."""
        with patch(
            "kfs_mcp_server.asyncio.to_thread",
            side_effect=subprocess.TimeoutExpired(cmd="vlad", timeout=120),
        ):
            result = await vlad_validate(module_path="slow_module")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "timeout" in parsed["error"].lower()


class TestCadQueryExecute:
    """CadQuery execution tool via MCP."""

    @pytest.mark.asyncio
    async def test_valid_code_returns_file_paths(self):
        """Valid CadQuery code should return output file paths as strings."""
        mock_result = MagicMock()
        mock_result.success = True
        mock_result.output_files = {"step": Path("/tmp/out.step"), "stl": Path("/tmp/out.stl")}
        mock_result.error = ""
        mock_result.stderr = ""
        mock_result.execution_time = 2.5

        mock_engine = AsyncMock()
        mock_engine.generate.return_value = mock_result

        with patch("kfs_mcp_server.CadQueryEngine", return_value=mock_engine):
            result = await cadquery_execute(code="import cadquery as cq\nresult = cq.Workplane().box(10,10,10)")

        parsed = json.loads(result)
        assert parsed["success"] is True
        # Paths must be strings, not Path objects
        assert isinstance(parsed["data"]["output_files"]["step"], str)

    @pytest.mark.asyncio
    async def test_invalid_code_returns_error(self):
        """Invalid CadQuery code should return error, not crash."""
        mock_result = MagicMock()
        mock_result.success = False
        mock_result.output_files = {}
        mock_result.error = "SyntaxError: invalid syntax"
        mock_result.stderr = "SyntaxError: invalid syntax"
        mock_result.execution_time = 0.1

        mock_engine = AsyncMock()
        mock_engine.generate.return_value = mock_result

        with patch("kfs_mcp_server.CadQueryEngine", return_value=mock_engine):
            result = await cadquery_execute(code="this is not valid python")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "SyntaxError" in parsed["error"]


class TestLibrarySearch:
    """Library search tool via MCP."""

    @pytest.mark.asyncio
    async def test_search_returns_matching_entries(self):
        """Search query should return matching library entries."""
        mock_entries = [
            {"id": "1", "name": "Planetary Gearbox", "mechanism_types": "gear"},
            {"id": "2", "name": "Planetary Reducer", "mechanism_types": "gear"},
        ]
        mock_manager = AsyncMock()
        mock_manager.search.return_value = mock_entries

        with patch("kfs_mcp_server._get_library_manager", return_value=mock_manager):
            result = await library_search(query="planetary")

        parsed = json.loads(result)
        assert parsed["success"] is True
        assert len(parsed["data"]) == 2
        assert parsed["data"][0]["name"] == "Planetary Gearbox"

    @pytest.mark.asyncio
    async def test_empty_query_returns_all(self):
        """Empty query should return all entries."""
        mock_entries = [{"id": "1", "name": "Entry 1"}, {"id": "2", "name": "Entry 2"}]
        mock_manager = AsyncMock()
        mock_manager.search.return_value = mock_entries

        with patch("kfs_mcp_server._get_library_manager", return_value=mock_manager):
            result = await library_search(query="")

        parsed = json.loads(result)
        assert parsed["success"] is True

    @pytest.mark.asyncio
    async def test_search_error_returns_structured_error(self):
        """Database errors should return structured error, not crash."""
        mock_manager = AsyncMock()
        mock_manager.search.side_effect = Exception("Database connection failed")

        with patch("kfs_mcp_server._get_library_manager", return_value=mock_manager):
            result = await library_search(query="test")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "Database connection failed" in parsed["error"]


class TestMCPResponseContract:
    """All tools must follow the structured response contract."""

    @pytest.mark.asyncio
    @pytest.mark.parametrize("tool_fn,kwargs", [
        (vlad_validate, {"module_path": "test"}),
        (cadquery_execute, {"code": "pass"}),
        (library_search, {"query": "test"}),
    ])
    async def test_all_tools_return_valid_json(self, tool_fn, kwargs):
        """Every tool must return parseable JSON."""
        # Mock away all external deps so the tool runs
        with patch("kfs_mcp_server.asyncio.to_thread", side_effect=Exception("mocked")), \
             patch("kfs_mcp_server.CadQueryEngine", side_effect=Exception("mocked")), \
             patch("kfs_mcp_server._get_library_manager", side_effect=Exception("mocked")):
            result = await tool_fn(**kwargs)

        parsed = json.loads(result)
        assert "success" in parsed
        assert "data" in parsed
        assert "error" in parsed
