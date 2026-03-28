"""SC-07 MCP Tools.

Expose five KFS capabilities as MCP-compatible tools so that external LLM
agents (Claude Desktop, API tool-use, etc.) can manipulate modules without
knowing internal service boundaries.

Tools
-----
kfs_create_module   -> ModuleManager.create()
kfs_list_modules    -> ModuleManager.list_all()
kfs_get_module      -> ModuleManager.get()
kfs_execute_module  -> ModuleExecutor.execute()
kfs_validate_module -> VladBridge + VladRunner.run() + ModuleManager.set_vlad_verdict()

Usage (host application wires together the dependencies)::

    from backend.app.mcp.kfs_tools import KFSMCPServer, get_tools, dispatch_tool

    server = KFSMCPServer(
        module_manager=mgr,
        module_executor=executor,
        vlad_runner=runner,
    )

    # Return tool schemas to the MCP host
    tools = get_tools()

    # Dispatch an incoming tool call
    result = await dispatch_tool("kfs_create_module", arguments, server)
"""
from __future__ import annotations

import asyncio
import dataclasses
import logging
from typing import Any, Dict, List, Optional

from backend.app.models.module import Module, ModuleManager
from backend.app.services.module_executor import ExecutionResult, ModuleExecutor
from backend.app.services.vlad_bridge import VladBridge
from backend.app.services.vlad_runner import VladResult, VladRunner

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# MCP tool schema definitions
# ---------------------------------------------------------------------------

#: Each dict follows the MCP tool schema format:
#: {"name": str, "description": str, "inputSchema": JSON-Schema-dict}
_TOOL_SCHEMAS: List[Dict[str, Any]] = [
    {
        "name": "kfs_create_module",
        "description": (
            "Create a new KFS module (CadQuery geometry component). "
            "Returns the new module record including its assigned id."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "UUID of the project this module belongs to.",
                },
                "name": {
                    "type": "string",
                    "description": "Human-readable module name (e.g. 'Spur Gear 20T').",
                },
                "geometry_type": {
                    "type": "string",
                    "description": "Geometry category (e.g. 'gear', 'slider', 'cam').",
                },
                "source_code": {
                    "type": "string",
                    "description": "CadQuery Python script that builds the geometry.",
                },
                "parameters": {
                    "type": "object",
                    "description": (
                        "Parametric values used by the code "
                        "(e.g. {'teeth': 20, 'module': 1.5})."
                    ),
                    "additionalProperties": True,
                },
            },
            "required": ["project_id", "name", "geometry_type", "source_code"],
        },
    },
    {
        "name": "kfs_list_modules",
        "description": "List all modules in a project, ordered by creation time.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "UUID of the project whose modules to list.",
                },
            },
            "required": ["project_id"],
        },
    },
    {
        "name": "kfs_get_module",
        "description": "Retrieve a single KFS module by its id.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "UUID of the project this module belongs to.",
                },
                "module_id": {
                    "type": "string",
                    "description": "UUID of the module to retrieve.",
                },
            },
            "required": ["project_id", "module_id"],
        },
    },
    {
        "name": "kfs_execute_module",
        "description": (
            "Execute a module's CadQuery source code through the CadQuery engine, "
            "write STL and STEP artefacts to disk, and return the execution result. "
            "The module must already exist."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "UUID of the project this module belongs to.",
                },
                "module_id": {
                    "type": "string",
                    "description": "UUID of the module to execute.",
                },
            },
            "required": ["project_id", "module_id"],
        },
    },
    {
        "name": "kfs_validate_module",
        "description": (
            "Run VLAD (geometry validator) against a module's CadQuery source code "
            "and record the verdict ('PASS' or 'FAIL') on the module record. "
            "Returns full VLAD results including per-check details."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_id": {
                    "type": "string",
                    "description": "UUID of the project this module belongs to.",
                },
                "module_id": {
                    "type": "string",
                    "description": "UUID of the module to validate.",
                },
                "mechanism_type": {
                    "type": "string",
                    "description": (
                        "VLAD mechanism category hint "
                        "(e.g. 'gear', 'slider', 'cam'). "
                        "Defaults to 'structural' if omitted."
                    ),
                },
            },
            "required": ["project_id", "module_id"],
        },
    },
]

#: Public alias — lets callers import TOOLS directly if preferred.
TOOLS: List[Dict[str, Any]] = _TOOL_SCHEMAS


def get_tools() -> List[Dict[str, Any]]:
    """Return the list of MCP tool schema dicts for all KFS tools.

    The host application passes this list to the MCP ``list_tools`` handler.
    """
    return list(_TOOL_SCHEMAS)


# ---------------------------------------------------------------------------
# Server — holds injected dependencies and implements tool handlers
# ---------------------------------------------------------------------------


class KFSMCPServer:
    """Central registry that wires MCP tool calls to KFS service methods.

    Parameters
    ----------
    module_manager:
        SC-01 :class:`~backend.app.models.module.ModuleManager`.
    module_executor:
        SC-02 :class:`~backend.app.services.module_executor.ModuleExecutor`.
    vlad_runner:
        SC-03 :class:`~backend.app.services.vlad_runner.VladRunner`.
    """

    def __init__(
        self,
        module_manager: ModuleManager,
        module_executor: ModuleExecutor,
        vlad_runner: VladRunner,
    ) -> None:
        self._mgr = module_manager
        self._executor = module_executor
        self._vlad = vlad_runner

    # ------------------------------------------------------------------
    # Tool handlers
    # ------------------------------------------------------------------

    async def kfs_create_module(
        self,
        project_id: str,
        name: str,
        geometry_type: str,
        source_code: str,
        parameters: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Create a new module and return its serialised record."""
        module: Module = await self._mgr.create(
            project_id=project_id,
            name=name,
            geometry_type=geometry_type,
            source_code=source_code,
            parameters=parameters,
        )
        return _serialise_module(module)

    async def kfs_list_modules(self, project_id: str) -> List[Dict[str, Any]]:
        """Return serialised records for all modules in a project."""
        modules: List[Module] = await self._mgr.list_all(project_id=project_id)
        return [_serialise_module(m) for m in modules]

    async def kfs_get_module(self, project_id: str, module_id: str) -> Dict[str, Any]:
        """Return the serialised record for a single module.

        Raises
        ------
        KeyError
            When *module_id* is not found.
        """
        module: Optional[Module] = await self._mgr.get(
            project_id=project_id, module_id=module_id
        )
        if module is None:
            raise KeyError(f"Module '{module_id}' not found")
        return _serialise_module(module)

    async def kfs_execute_module(
        self, project_id: str, module_id: str
    ) -> Dict[str, Any]:
        """Execute a module's CadQuery code and return the ExecutionResult.

        Fetches the module's source code from the database, runs the
        CadQuery engine, and returns a result dict.

        Raises
        ------
        KeyError
            When *module_id* is not found.
        """
        module: Optional[Module] = await self._mgr.get(
            project_id=project_id, module_id=module_id
        )
        if module is None:
            raise KeyError(f"Module '{module_id}' not found")

        result: ExecutionResult = await self._executor.execute(
            module_id=module_id,
            code=module.source_code,
        )
        return _serialise_execution(result)

    async def kfs_validate_module(
        self,
        project_id: str,
        module_id: str,
        mechanism_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Run VLAD against a module and record the verdict.

        Raises
        ------
        KeyError
            When *module_id* is not found.
        """
        module: Optional[Module] = await self._mgr.get(
            project_id=project_id, module_id=module_id
        )
        if module is None:
            raise KeyError(f"Module '{module_id}' not found")

        mech_type = mechanism_type or "structural"

        # Build a temporary bridge file for VLAD, run in thread to avoid blocking
        bridge = VladBridge(module.source_code, mechanism_type=mech_type)
        try:
            bridge_path = await asyncio.to_thread(bridge.write_bridge)
            vlad_result: VladResult = await asyncio.to_thread(
                self._vlad.run, module_id, str(bridge_path)
            )
        finally:
            bridge.cleanup()

        # Persist the verdict string on the module record
        await self._mgr.set_vlad_verdict(
            project_id=project_id,
            module_id=module_id,
            verdict=vlad_result.verdict,
        )

        return _serialise_vlad(vlad_result)


# ---------------------------------------------------------------------------
# Tool dispatcher
# ---------------------------------------------------------------------------

#: Maps tool name -> KFSMCPServer method name
_HANDLER_MAP: Dict[str, str] = {
    "kfs_create_module": "kfs_create_module",
    "kfs_list_modules": "kfs_list_modules",
    "kfs_get_module": "kfs_get_module",
    "kfs_execute_module": "kfs_execute_module",
    "kfs_validate_module": "kfs_validate_module",
}


async def dispatch_tool(
    tool_name: str,
    arguments: Dict[str, Any],
    server: KFSMCPServer,
) -> Any:
    """Route an incoming MCP tool call to the correct handler method.

    Parameters
    ----------
    tool_name:
        The ``name`` field from the MCP ``call_tool`` request.
    arguments:
        The ``arguments`` dict from the request (already parsed from JSON).
    server:
        Configured :class:`KFSMCPServer` instance.

    Returns
    -------
    Any
        JSON-serialisable result dict returned by the handler.

    Raises
    ------
    ValueError
        When *tool_name* is not one of the five registered KFS tools.
    """
    method_name = _HANDLER_MAP.get(tool_name)
    if method_name is None:
        raise ValueError(
            f"Unknown KFS tool {tool_name!r}. "
            f"Available: {sorted(_HANDLER_MAP)}"
        )
    handler = getattr(server, method_name)
    logger.debug("MCP dispatch: tool=%s args=%s", tool_name, list(arguments))
    return await handler(**arguments)


#: Public alias for dispatch_tool — matches the expected call_tool interface.
call_tool = dispatch_tool


# ---------------------------------------------------------------------------
# Serialisation helpers
# ---------------------------------------------------------------------------


def _serialise_module(module: Module) -> Dict[str, Any]:
    """Convert a Module dataclass to a plain JSON-serialisable dict."""
    return dataclasses.asdict(module)


def _serialise_execution(result: ExecutionResult) -> Dict[str, Any]:
    """Convert an ExecutionResult to a plain dict."""
    return {
        "module_id": result.module_id,
        "status": result.status,
        "stl_path": result.stl_path,
        "step_path": result.step_path,
        "error": result.error,
    }


def _serialise_vlad(result: VladResult) -> Dict[str, Any]:
    """Convert a VladResult to a plain dict suitable for MCP response."""
    return {
        "module_id": result.module_id,
        "verdict": result.verdict,
        "passed": result.passed,
        "mechanism_type": result.mechanism_type,
        "counts": {
            "pass": result.pass_count,
            "fail": result.fail_count,
            "warn": result.warn_count,
            "info": result.info_count,
        },
        "fixed_parts": result.fixed_parts,
        "moving_parts": result.moving_parts,
        "checks": [
            {"id": c.check_id, "status": c.status, "detail": c.detail}
            for c in result.checks
        ],
        "run_at": result.run_at.isoformat(),
    }
