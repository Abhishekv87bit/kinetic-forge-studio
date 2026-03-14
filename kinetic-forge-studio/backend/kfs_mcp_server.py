"""
KFS MCP Server -- Model Context Protocol tools for Kinetic Forge Studio.
=======================================================================
GAP-PPL-014 -- MCP Exposure

Exposes 3 KFS tools to AI agents (e.g., Claude Code) via FastMCP:
  1. vlad_validate   -- Run VLAD geometry validator on a CadQuery module
  2. cadquery_execute -- Execute CadQuery/build123d code, return file paths
  3. library_search   -- Search the KFS parts library via FTS5

Usage:
    # As MCP server (Claude Code auto-discovers via .mcp.json):
    python kfs_mcp_server.py

    # Register in .mcp.json:
    {"mcpServers": {"kfs-tools": {"command": "python", "args": ["kfs_mcp_server.py"]}}}
"""

from __future__ import annotations

import asyncio
import json
import logging
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from fastmcp import FastMCP

# Ensure backend app is importable
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.engines.cadquery_engine import CadQueryEngine, GenerationResult

logger = logging.getLogger("kfs_mcp")

mcp = FastMCP(
    "KFS Tools",
    instructions="Kinetic Forge Studio design tools: VLAD validator, CadQuery executor, library search",
)

# Path to VLAD script (relative to this repo)
VLAD_PATH = Path(__file__).resolve().parent.parent.parent / "tools" / "vlad.py"

# Default output directory for CadQuery execution
DEFAULT_OUTPUT_DIR = Path(tempfile.gettempdir()) / "kfs_mcp_output"


def _make_response(success: bool, data: Any = None, error: str | None = None) -> str:
    """Create a structured JSON response string."""
    return json.dumps({"success": success, "data": data, "error": error}, default=str)


# ---------------------------------------------------------------------------
# Tool 1: VLAD Validate
# ---------------------------------------------------------------------------

@mcp.tool()
async def vlad_validate(module_path: str) -> str:
    """
    Run VLAD geometry validator on a CadQuery production module.

    The module must export get_fixed_parts(), get_moving_parts(), and
    get_mechanism_type(). VLAD runs 35 checks across 8 tiers (topology,
    interference, clearance, manufacturability, etc.).

    Args:
        module_path: Python module path (e.g., 'my_sculpture' or 'projects.triple_helix').
                     Must be importable from the current working directory.

    Returns:
        JSON with tier results, pass/fail counts, and any errors.
    """
    try:
        # Run in thread to avoid blocking the asyncio event loop (VLAD can take 30s+)
        result = await asyncio.to_thread(
            subprocess.run,
            [sys.executable, str(VLAD_PATH), "--json", module_path],
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode == 2:
            # Fatal error (module not found, import error, etc.)
            return _make_response(
                success=False,
                error=result.stderr.strip() or "VLAD fatal error (exit code 2)",
            )

        # returncode 0 = all pass, 1 = some failures (both are valid results)
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            data = {"raw_output": result.stdout, "raw_stderr": result.stderr}

        return _make_response(
            success=(result.returncode == 0),
            data=data,
            error=result.stderr.strip() if result.returncode != 0 else None,
        )

    except subprocess.TimeoutExpired:
        return _make_response(success=False, error="VLAD timeout (120s exceeded)")
    except Exception as e:
        return _make_response(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Tool 2: CadQuery Execute
# ---------------------------------------------------------------------------

@mcp.tool()
async def cadquery_execute(code: str, output_dir: str = "") -> str:
    """
    Execute CadQuery or build123d Python code and return output file paths.

    The script should assign its result to a variable named 'result'.
    Output STEP and STL files are written to the output directory.

    Args:
        code: Python script text (CadQuery or build123d).
        output_dir: Directory for output files. Defaults to a temp directory.

    Returns:
        JSON with success status, output file paths (as strings), and any errors.
    """
    try:
        out_path = Path(output_dir) if output_dir else DEFAULT_OUTPUT_DIR
        out_path.mkdir(parents=True, exist_ok=True)

        engine = CadQueryEngine()
        result: GenerationResult = await engine.generate(
            code=code,
            output_dir=out_path,
            filename_base="mcp_output",
        )

        return _make_response(
            success=result.success,
            data={
                "output_files": {fmt: str(path) for fmt, path in result.output_files.items()},
                "execution_time": result.execution_time,
                "stderr": result.stderr,
            },
            error=result.error if not result.success else None,
        )
    except Exception as e:
        return _make_response(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Tool 3: Library Search
# ---------------------------------------------------------------------------

_library_manager = None


async def _get_library_manager():
    """Lazy-create a singleton LibraryManager with a persistent DB connection."""
    global _library_manager
    if _library_manager is None:
        from app.db.database import Database
        from app.db.library import LibraryManager

        db = Database()
        await db.connect()
        _library_manager = LibraryManager(db)
    return _library_manager


@mcp.tool()
async def library_search(query: str) -> str:
    """
    Search the KFS parts library using full-text search.

    Searches across name, mechanism_types, and keywords fields.
    Returns matching library entries with metadata.

    Args:
        query: Search query (e.g., 'planetary', 'four-bar linkage', 'wave').
               Empty string returns all entries.

    Returns:
        JSON with list of matching library entries.
    """
    try:
        manager = await _get_library_manager()
        entries = await manager.search(query)
        return _make_response(success=True, data=entries)
    except Exception as e:
        return _make_response(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
