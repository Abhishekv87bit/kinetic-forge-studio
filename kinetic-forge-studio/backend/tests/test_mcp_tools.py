"""
Tests for MCP tool schema definitions (SC-07).
Validates that ALL_TOOLS is well-formed and each tool satisfies the MCP contract.
"""
import pytest

from app.mcp.kfs_tools import ALL_TOOLS


EXPECTED_TOOL_NAMES = {"execute_cadquery", "validate_with_vlad", "list_modules", "get_module"}


def test_all_tools_is_list():
    """ALL_TOOLS must be a list (iterable for discovery by kfs_mcp_server)."""
    assert isinstance(ALL_TOOLS, list)


def test_tool_count():
    """Exactly 4 tools should be registered."""
    assert len(ALL_TOOLS) == 4


def test_each_tool_has_required_keys():
    """Every tool dict must contain name, description, and input_schema."""
    for tool in ALL_TOOLS:
        for key in ("name", "description", "input_schema"):
            assert key in tool, f"Tool missing '{key}': {tool.get('name', '<unnamed>')}"


def test_tool_names():
    """Exact tool names match the expected set."""
    actual_names = {tool["name"] for tool in ALL_TOOLS}
    assert actual_names == EXPECTED_TOOL_NAMES


def test_input_schemas_are_valid():
    """Each input_schema must be a JSON Schema object with type and properties."""
    for tool in ALL_TOOLS:
        schema = tool["input_schema"]
        assert isinstance(schema, dict), f"{tool['name']}: input_schema must be a dict"
        assert schema.get("type") == "object", (
            f"{tool['name']}: input_schema.type must be 'object'"
        )
        assert "properties" in schema, (
            f"{tool['name']}: input_schema must have 'properties'"
        )
        assert isinstance(schema["properties"], dict), (
            f"{tool['name']}: input_schema.properties must be a dict"
        )


def test_execute_cadquery_requires_source_code():
    """execute_cadquery's required list must include 'code' (the primary input)."""
    tool = next(t for t in ALL_TOOLS if t["name"] == "execute_cadquery")
    required = tool["input_schema"].get("required", [])
    assert "code" in required, (
        "execute_cadquery must declare 'code' as a required field"
    )


def test_validate_with_vlad_requires_file_path():
    """validate_with_vlad's required list must include 'module_path'."""
    tool = next(t for t in ALL_TOOLS if t["name"] == "validate_with_vlad")
    required = tool["input_schema"].get("required", [])
    assert "module_path" in required, (
        "validate_with_vlad must declare 'module_path' as a required field"
    )
