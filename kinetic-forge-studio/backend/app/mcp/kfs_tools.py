"""
KFS MCP tool schema definitions (GAP-PPL-014).

Each entry is a plain dict following the MCP tool-definition format:
  - name        : unique tool identifier
  - description : shown to the AI agent
  - input_schema: JSON Schema for the tool's input parameters

These defs are consumed by kfs_mcp_server.py (FastMCP) which routes calls
to the service layer.  No business logic lives here — definitions only.
"""

from typing import Any


# ---------------------------------------------------------------------------
# Tool definitions
# ---------------------------------------------------------------------------

execute_cadquery: dict[str, Any] = {
    "name": "execute_cadquery",
    "description": (
        "Execute CadQuery or build123d Python code and produce geometry output files "
        "(STL + STEP). The script should build its result as a CadQuery Workplane or "
        "build123d Part. Returns output file paths and execution metadata."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "code": {
                "type": "string",
                "description": "Python script text using CadQuery or build123d.",
            },
            "output_dir": {
                "type": "string",
                "description": (
                    "Absolute path to write output files. "
                    "Defaults to a temp directory when omitted."
                ),
                "default": "",
            },
        },
        "required": ["code"],
    },
}

validate_with_vlad: dict[str, Any] = {
    "name": "validate_with_vlad",
    "description": (
        "Run VLAD geometry validation on a CadQuery production module. "
        "Performs 35 checks across 8 tiers: topology, interference, clearance, "
        "manufacturability, export quality, and more. "
        "The module must export get_fixed_parts(), get_moving_parts(), and "
        "get_mechanism_type()."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "module_path": {
                "type": "string",
                "description": (
                    "Python module path (e.g. 'my_sculpture' or "
                    "'projects.triple_helix'). Must be importable from CWD."
                ),
            },
        },
        "required": ["module_path"],
    },
}

list_modules: dict[str, Any] = {
    "name": "list_modules",
    "description": (
        "List all modules attached to a KFS project. "
        "Returns module IDs, names, versions, languages, and status."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "project_id": {
                "type": "string",
                "description": "The KFS project ID to list modules for.",
            },
        },
        "required": ["project_id"],
    },
}

get_module: dict[str, Any] = {
    "name": "get_module",
    "description": (
        "Get full details of a single KFS module including its current source code, "
        "version number, language, parameters, and status."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "project_id": {
                "type": "string",
                "description": "The KFS project ID that owns the module.",
            },
            "module_id": {
                "type": "string",
                "description": "The module ID to retrieve.",
            },
        },
        "required": ["project_id", "module_id"],
    },
}


# ---------------------------------------------------------------------------
# Registry — iterable collection for discovery by kfs_mcp_server.py
# ---------------------------------------------------------------------------

ALL_TOOLS: list[dict[str, Any]] = [
    execute_cadquery,
    validate_with_vlad,
    list_modules,
    get_module,
]
