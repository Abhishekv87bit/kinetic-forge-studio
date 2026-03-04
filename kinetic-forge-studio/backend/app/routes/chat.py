"""
Chat route — the primary interface between users and the AI design agent.

Architecture:
  1. User sends a message
  2. If API key configured: ChatAgent (LLM) handles it with full methodology
     - LLM generates structured ```components``` blocks → registered directly
     - LLM generates ```spec_update``` → updates project spec
     - LLM generates ```verification``` → physics checks shown inline
  3. If no API key: Falls back to Pipeline (keyword classifier + question tree)
     - Pipeline extracts fields → mechanism_mapper generates dummy shapes
  4. After component registration, gate validation runs automatically

The KEY DIFFERENCE from the old architecture: the LLM designs the actual
components with real engineering parameters. The mechanism_mapper is ONLY
used as a fallback when no AI is available.
"""

import json
import logging
import time
from dataclasses import dataclass, field as dc_field
from pathlib import Path

import numpy as np
import trimesh

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Any

from app.config import settings
from app.orchestrator.pipeline import Pipeline
from app.orchestrator.chat_agent import ChatAgent
from app.orchestrator.mechanism_mapper import spec_to_components
from app.orchestrator.gate import GateEnforcer
from app.engines.geometry_engine import GeometryEngine
from app.engines.cadquery_engine import CadQueryEngine
from app.models.component import ComponentManager
from app.models.profile import UserProfile
from app.db.library import LibraryManager
from app.routes.projects import get_pm
from app.utils.geometry import component_to_geometry
from app.consultants.rule99_engine import get_engine as get_rule99_engine, ProjectState

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/projects/{project_id}/chat", tags=["chat"])

_engine = GeometryEngine()
_enforcer = GateEnforcer()


@dataclass
class ProjectChatState:
    """Tracks per-project chat state for both Pipeline and ChatAgent."""
    pipeline: Pipeline = dc_field(default_factory=Pipeline)
    agent: ChatAgent = dc_field(default_factory=ChatAgent)
    conversation_history: list[dict[str, str]] = dc_field(default_factory=list)
    history_loaded: bool = False


# In-memory chat state per project (Pipeline + agent instances).
# Conversation history is loaded from SQLite on first access per project.
_chat_states: dict[str, ProjectChatState] = {}


async def _get_state(project_id: str) -> ProjectChatState:
    """Get or create chat state, loading persisted history from DB."""
    if project_id not in _chat_states:
        _chat_states[project_id] = ProjectChatState()

    state = _chat_states[project_id]

    # Load conversation history from DB on first access
    if not state.history_loaded:
        try:
            pm = await get_pm()
            await _ensure_chat_table(pm)
            cursor = await pm.db.conn.execute(
                "SELECT role, content FROM chat_messages "
                "WHERE project_id = ? ORDER BY created_at ASC",
                (project_id,),
            )
            rows = await cursor.fetchall()
            state.conversation_history = [
                {"role": r["role"], "content": r["content"]} for r in rows
            ]
            state.history_loaded = True
            if rows:
                logger.info(
                    "Loaded %d persisted messages for project %s",
                    len(rows), project_id,
                )
        except Exception as e:
            logger.warning("Could not load chat history for %s: %s", project_id, e)
            state.history_loaded = True  # don't retry on failure

    return state


async def _persist_message(
    project_id: str, role: str, content: str, model_used: str = "",
) -> None:
    """Save a single chat message to SQLite for persistence."""
    try:
        pm = await get_pm()
        await _ensure_chat_table(pm)
        await pm.db.conn.execute(
            "INSERT INTO chat_messages (project_id, role, content, model_used) "
            "VALUES (?, ?, ?, ?)",
            (project_id, role, content, model_used),
        )
        await pm.db.conn.commit()
    except Exception as e:
        logger.warning("Could not persist chat message for %s: %s", project_id, e)


async def _ensure_chat_table(pm) -> None:
    """Ensure chat_messages table exists (backwards-compatible migration)."""
    try:
        await pm.db.conn.execute("SELECT 1 FROM chat_messages LIMIT 1")
    except Exception:
        await pm.db.conn.executescript("""
            CREATE TABLE IF NOT EXISTS chat_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id TEXT NOT NULL,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                model_used TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE INDEX IF NOT EXISTS idx_chat_messages_project
                ON chat_messages(project_id, created_at);
        """)
        await pm.db.conn.commit()


class ChatMessage(BaseModel):
    content: str
    role: str = "user"


class AnswerMessage(BaseModel):
    field: str
    value: Any


@router.post("")
async def send_message(project_id: str, msg: ChatMessage):
    """
    Process a user chat message through the AI design agent.

    The LLM receives the full methodology system prompt and generates
    structured output (components, spec updates, verification checks)
    that the app processes automatically.

    Special commands:
    - "Rule 99" / "Rule 99 [topic]" — run consultant pipeline
    - "design locked" — attempt gate transition to prototype
    - "prototype validated" — attempt gate transition to production
    - "Rule 500" — run full production pipeline
    """
    state = await _get_state(project_id)

    # Check for Rule 99 / Rule 500 / gate transition commands
    rule99_result = await _handle_rule99_command(project_id, msg.content)
    if rule99_result:
        state.conversation_history.append({"role": "user", "content": msg.content})
        state.conversation_history.append(
            {"role": "assistant", "content": rule99_result["message"]}
        )
        await _persist_message(project_id, "user", msg.content)
        await _persist_message(project_id, "assistant", rule99_result["message"])
        return rule99_result

    if state.agent.is_available():
        try:
            result = await _send_via_agent(state, project_id, msg)
            if result.get("response_type") != "error":
                return result
            # AI returned an error — fall back to Pipeline
            logger.warning("ChatAgent returned error, falling back to Pipeline")
        except Exception as e:
            logger.warning("ChatAgent failed (%s), falling back to Pipeline", e)

    # Fallback: keyword pipeline (no AI available)
    result = _send_via_pipeline(state, msg)

    if result.get("response_type") == "generation":
        reg_error = await _register_components_from_mapper(project_id, state.pipeline.spec)
        result["geometry_ready"] = True
        if reg_error:
            result["message"] += f"\n\n⚠ Component registration: {reg_error}"
        gate = await _run_gate_check(project_id)
        if gate:
            result["gate_result"] = gate
            if not gate["passed"] and gate.get("suggestions"):
                result["message"] += (
                    "\n\nValidation Issues:\n"
                    + "\n".join(f"  - {s}" for s in gate["suggestions"])
                )

    return result


def _read_scad_source(project) -> dict[str, str] | None:
    """Read .scad files from project's scad_dir for LLM context.

    Dependency-aware loading:
    1. Parse include/use statements to find the config root
    2. Load config first (full content — it's the source of truth)
    3. Load remaining design files in dependency order
    4. Skip test/debug files (prefixed with _ or test)
    """
    if not getattr(project, 'scad_dir', None):
        return None
    scad_dir = Path(project.scad_dir)
    if not scad_dir.exists():
        return None

    import re

    MAX_CHARS_PER_FILE = 8000  # generous per-file for complex designs
    MAX_CONFIG_CHARS = 16000   # config files get extra budget (source of truth)
    MAX_FILES = 12
    MAX_TOTAL_CHARS = 60000    # ~60K total context for design files

    all_scad = list(scad_dir.glob("**/*.scad"))
    if not all_scad:
        return None

    # Phase 1: Identify config/root files (included by others, no includes themselves)
    include_pattern = re.compile(r'(?:include|use)\s*<([^>]+)>')
    file_deps: dict[str, set[str]] = {}
    included_by_others: set[str] = set()

    for f in all_scad:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")[:2000]  # scan head only
            deps = set(include_pattern.findall(text))
            file_deps[f.name] = deps
            included_by_others.update(deps)
        except Exception:
            continue

    # Config files: included by others but don't include anything themselves
    config_files = [f for f in all_scad
                    if f.name in included_by_others and not file_deps.get(f.name)]
    # Also catch files with "config" in the name
    for f in all_scad:
        if "config" in f.name.lower() and f not in config_files:
            config_files.insert(0, f)

    # Phase 2: Rank design files (skip test/debug/underscore-prefixed)
    design_files = []
    for f in all_scad:
        name_lower = f.name.lower()
        if f in config_files:
            continue
        if name_lower.startswith("_") or name_lower.startswith("test"):
            continue
        design_files.append(f)

    # Sort design files: files with more dependents first (more important)
    def importance(f):
        # Files referenced by others are more fundamental
        ref_count = sum(1 for deps in file_deps.values() if f.name in deps)
        return (-ref_count, f.name)  # most-referenced first, then alphabetical

    design_files.sort(key=importance)

    # Phase 3: Load in order: config first, then design files
    ordered = config_files + design_files[:MAX_FILES - len(config_files)]

    scad_source = {}
    total_chars = 0

    for scad_file in ordered:
        try:
            content = scad_file.read_text(encoding="utf-8", errors="replace")
            is_config = scad_file in config_files
            cap = MAX_CONFIG_CHARS if is_config else MAX_CHARS_PER_FILE
            if len(content) > cap:
                content = content[:cap] + "\n// ... (truncated)"
            if total_chars + len(content) > MAX_TOTAL_CHARS:
                break
            scad_source[scad_file.name] = content
            total_chars += len(content)
        except Exception:
            continue

    return scad_source if scad_source else None


async def _send_via_agent(
    state: ProjectChatState, project_id: str, msg: ChatMessage
) -> dict:
    """
    Route message through the AI design agent.

    The LLM gets the full methodology prompt and generates:
    - components: structured JSON → registered directly in DB
    - spec_updates: parameter changes → applied to spec
    - verification: physics checks → shown to user
    - code_blocks: OpenSCAD/CadQuery → displayed in chat
    """
    # Still run the classifier to extract fields (helps the LLM with context)
    pipeline_result = state.pipeline.process(msg.content)
    spec = dict(state.pipeline.spec)

    # Load project context for the system prompt
    pm = await get_pm()
    project = await pm.open(project_id)
    cm = ComponentManager(pm.db)
    existing_components = await cm.list_all(project_id)
    gate_level = project.gate if hasattr(project, "gate") else "design"

    # Load locked decisions for context injection
    locked_decisions = []
    try:
        cursor = await pm.db.conn.execute(
            "SELECT parameter, value, reason, status FROM decisions "
            "WHERE project_id = ? AND status = 'locked'",
            (project_id,),
        )
        rows = await cursor.fetchall()
        locked_decisions = [
            {"parameter": r["parameter"], "value": r["value"],
             "reason": r["reason"] or "", "status": r["status"]}
            for r in rows
        ]
    except Exception as e:
        logger.warning("Could not load locked decisions: %s", e)

    # Load user profile for context injection
    user_profile = None
    try:
        profile = UserProfile(settings.data_dir)
        user_profile = profile.load()
    except Exception as e:
        logger.warning("Could not load user profile: %s", e)

    # Library-first search: find similar designs before generating from scratch
    library_matches = []
    try:
        lib_mgr = LibraryManager(pm.db)
        # Build search query from message + spec keywords
        search_terms = []
        mech_type = spec.get("mechanism_type", "")
        if mech_type:
            search_terms.append(mech_type)
        # Extract key terms from user message (first 3 words)
        msg_words = [w for w in msg.content.lower().split()
                     if len(w) > 3 and w not in ("want", "make", "need", "like", "this", "that", "with")]
        search_terms.extend(msg_words[:3])

        if search_terms:
            query = " ".join(search_terms)
            results = await lib_mgr.search(query)
            library_matches = results[:3]  # Top 3 matches
            if library_matches:
                logger.info(
                    "Library-first: found %d matches for '%s'",
                    len(library_matches), query,
                )
    except Exception as e:
        logger.warning("Library search failed: %s", e)

    # Read OpenSCAD source files from project scad_dir for LLM context
    scad_source = _read_scad_source(project)

    # Fetch consultant context from Rule 99 for current gate
    consultant_context = None
    try:
        rule99 = get_rule99_engine()
        project_state = ProjectState(
            gate_level=gate_level,
            mechanism_type=spec.get("mechanism_type", ""),
            component_types=[
                c.get("type", "") for c in existing_components if isinstance(c, dict)
            ],
            components=existing_components,
            spec=spec,
        )
        report = rule99.run_gate_consultants(gate_level, project_state)
        consultant_context = {
            "gate": gate_level,
            "consultants": [
                {"name": c.name, "checks": c.findings, "passed": c.passed}
                for c in report.consultants_fired
            ],
            "recommendations": report.recommendations,
            "library_suggestions": [
                {"name": lib.name, "purpose": lib.purpose}
                for lib in report.library_suggestions
            ],
        }
    except Exception:
        pass  # Rule 99 is advisory, don't block chat

    # Call the LLM with full methodology context
    response = await state.agent.chat(
        user_message=msg.content,
        conversation_history=state.conversation_history,
        spec=spec,
        gate_level=gate_level,
        locked_decisions=locked_decisions,
        components=existing_components,
        user_profile=user_profile,
        classifier_results=pipeline_result.classification,
        library_matches=library_matches,
        consultant_context=consultant_context,
        scad_source=scad_source,
    )

    # Track conversation history (in-memory + persisted to SQLite)
    state.conversation_history.append({"role": "user", "content": msg.content})
    state.conversation_history.append({"role": "assistant", "content": response.message})
    await _persist_message(project_id, "user", msg.content)
    await _persist_message(project_id, "assistant", response.message, response.model_used)

    # Apply spec updates — but check for conflicts with locked decisions first
    conflicts = []
    if response.spec_updates and locked_decisions:
        from app.models.decision import DecisionManager
        dm = DecisionManager(pm.db)
        for key, value in response.spec_updates.items():
            found = await dm.check_conflicts(project_id, key, str(value))
            for c in found:
                conflicts.append({
                    "parameter": key,
                    "new_value": str(value),
                    "locked_value": c.get("value", "?"),
                    "locked_reason": c.get("reason", ""),
                })

    if conflicts:
        # Don't silently overwrite — warn and skip conflicting updates
        conflict_lines = ["\n\n**Decision Conflicts Detected:**"]
        for c in conflicts:
            conflict_lines.append(
                f"  - **{c['parameter']}**: AI suggested `{c['new_value']}` "
                f"but locked at `{c['locked_value']}`"
                + (f" (reason: {c['locked_reason']})" if c["locked_reason"] else "")
            )
        conflict_lines.append(
            "\nLocked values preserved. Use `supersede` to change locked decisions."
        )
        response.message += "\n".join(conflict_lines)
        # Only apply non-conflicting updates
        conflict_keys = {c["parameter"] for c in conflicts}
        for key, value in response.spec_updates.items():
            if key not in conflict_keys:
                state.pipeline.spec[key] = value
    else:
        for key, value in response.spec_updates.items():
            state.pipeline.spec[key] = value

    result: dict[str, Any] = {
        "user_message": msg.content,
        "message": response.message,
        "response_type": response.response_type,
        "spec_updates": [
            {"field": k, "value": v} for k, v in response.spec_updates.items()
        ],
        "conflicts": conflicts,
        "code_blocks": response.code_blocks,
        "options": response.options,
        "model_used": response.model_used,
        "ai_powered": True,
    }

    # Add verification results if present
    if response.verification:
        result["verification"] = response.verification

    # Execute Python/CadQuery/build123d code blocks if present
    if response.code_blocks:
        code_exec_results = await _execute_code_blocks(
            project_id, response.code_blocks
        )
        result["code_execution"] = code_exec_results
        executed = [r for r in code_exec_results if not r.get("skipped")]
        succeeded = [r for r in executed if r["success"]]
        if executed:
            if succeeded:
                result["geometry_ready"] = True
                file_list = []
                for r in succeeded:
                    file_list.extend(r.get("output_files", {}).keys())
                response.message += (
                    f"\n\n**Code executed** — generated "
                    f"{', '.join(file_list)} files."
                )
            else:
                errors = [
                    r.get("error", "unknown")
                    for r in executed if not r["success"]
                ]
                response.message += (
                    "\n\n**Code execution failed:**\n"
                    + "\n".join(f"  - {e[:120]}" for e in errors[:3])
                )

    # If the LLM generated components, register THOSE (not mechanism_mapper output)
    if response.components:
        reg_error = await _register_components_from_llm(project_id, response.components)
        result["geometry_ready"] = True
        if reg_error:
            result["message"] += f"\n\n⚠ Component registration: {reg_error}"

        # Run gate validation with auto-retry on failure (max 3 attempts)
        gate = await _run_gate_check(project_id)
        retry_count = 0
        max_retries = 2  # 2 retries = 3 total attempts

        while (gate and not gate["passed"] and gate.get("suggestions")
               and retry_count < max_retries):
            retry_count += 1
            failure_lines = "\n".join(
                f"  - {s}" for s in gate["suggestions"]
            )
            retry_prompt = (
                f"Validation FAILED (attempt {retry_count}/{max_retries + 1}). "
                f"Fix these issues and regenerate components:\n{failure_lines}"
            )
            logger.info(
                "Auto-retry %d/%d for project %s",
                retry_count, max_retries, project_id,
            )

            # Re-fetch components so LLM sees current state, not stale
            retry_components = await cm.list_all(project_id)

            retry_response = await state.agent.chat(
                user_message=retry_prompt,
                conversation_history=state.conversation_history,
                spec=spec,
                gate_level=gate_level,
                locked_decisions=locked_decisions,
                components=retry_components,
                user_profile=user_profile,
                library_matches=library_matches,
                consultant_context=consultant_context,
                scad_source=scad_source,
            )

            state.conversation_history.append(
                {"role": "user", "content": retry_prompt}
            )
            state.conversation_history.append(
                {"role": "assistant", "content": retry_response.message}
            )
            # Persist retry conversation to DB
            await _persist_message(project_id, "user", retry_prompt)
            await _persist_message(
                project_id, "assistant",
                retry_response.message, retry_response.model_used,
            )

            if not retry_response.components:
                break  # LLM didn't produce new components

            reg_error = await _register_components_from_llm(
                project_id, retry_response.components
            )
            if reg_error:
                break
            gate = await _run_gate_check(project_id)

        if gate:
            result["gate_result"] = gate
            result["retry_count"] = retry_count
            if not gate["passed"] and gate.get("suggestions"):
                result["message"] += (
                    "\n\n**Validation Issues:**\n"
                    + "\n".join(f"  - {s}" for s in gate["suggestions"])
                )
                if retry_count > 0:
                    result["message"] += (
                        f"\n\n(Auto-retry exhausted after "
                        f"{retry_count + 1} attempts)"
                    )
            elif retry_count > 0:
                result["message"] += (
                    f"\n\nPassed validation after "
                    f"{retry_count + 1} attempts (auto-retry)"
                )

        # Snapshot after successful component registration
        if not reg_error:
            await _create_snapshot(
                project_id,
                f"Components: {len(response.components)} parts",
                trigger="component_registration",
            )

    elif response.response_type == "generation" and not response.components:
        # LLM said "generation" but didn't emit components — fall back to mapper
        spec_complete = not state.pipeline._compute_unknowns()
        if spec_complete:
            reg_error = await _register_components_from_mapper(project_id, state.pipeline.spec)
            result["geometry_ready"] = True
            if reg_error:
                result["message"] += f"\n\n⚠ Component registration: {reg_error}"
            gate = await _run_gate_check(project_id)
            if gate:
                result["gate_result"] = gate
                if not gate["passed"] and gate.get("suggestions"):
                    result["message"] += (
                        "\n\nValidation Issues:\n"
                        + "\n".join(f"  - {s}" for s in gate["suggestions"])
                    )

    return result


def _send_via_pipeline(state: ProjectChatState, msg: ChatMessage) -> dict:
    """Route message through Pipeline (keyword classifier fallback)."""
    response = state.pipeline.process(msg.content)
    return {
        "user_message": msg.content,
        **response.to_dict(),
        "ai_powered": False,
    }


@router.post("/answer")
async def answer_question(project_id: str, answer: AnswerMessage):
    """
    Apply a direct answer to a question (e.g., button selection).

    When the answer completes the spec, triggers component registration
    and gate validation.
    """
    state = await _get_state(project_id)
    response = state.pipeline.apply_answer(answer.field, answer.value)
    result = response.to_dict()

    if result.get("response_type") == "generation":
        reg_error = await _register_components_from_mapper(project_id, state.pipeline.spec)
        result["geometry_ready"] = True
        if reg_error:
            result["message"] += f"\n\n⚠ Component registration: {reg_error}"
        gate = await _run_gate_check(project_id)
        if gate:
            result["gate_result"] = gate
            if not gate["passed"] and gate.get("suggestions"):
                result["message"] += (
                    "\n\nValidation Issues:\n"
                    + "\n".join(f"  - {s}" for s in gate["suggestions"])
                )

    return result


@router.post("/reset")
async def reset_chat(project_id: str):
    """Reset chat state for this project (clears in-memory + DB history)."""
    if project_id in _chat_states:
        state = _chat_states[project_id]
        state.pipeline.reset()
        state.conversation_history.clear()
        state.history_loaded = True  # Mark as loaded (empty)
    # Also clear persisted history
    try:
        pm = await get_pm()
        await _ensure_chat_table(pm)
        await pm.db.conn.execute(
            "DELETE FROM chat_messages WHERE project_id = ?", (project_id,)
        )
        await pm.db.conn.commit()
    except Exception as e:
        logger.warning("Could not clear persisted chat for %s: %s", project_id, e)
    return {"status": "reset", "project_id": project_id}


@router.get("/history")
async def chat_history(project_id: str):
    """Return persisted chat messages for this project (restored on page load)."""
    try:
        pm = await get_pm()
        await _ensure_chat_table(pm)
        cursor = await pm.db.conn.execute(
            "SELECT role, content, model_used, created_at FROM chat_messages "
            "WHERE project_id = ? ORDER BY created_at ASC",
            (project_id,),
        )
        rows = await cursor.fetchall()
        return {
            "messages": [
                {"role": r["role"], "content": r["content"],
                 "model_used": r["model_used"], "created_at": r["created_at"]}
                for r in rows
            ],
            "count": len(rows),
        }
    except Exception as e:
        logger.warning("Could not load chat history for %s: %s", project_id, e)
        return {"messages": [], "count": 0}


@router.get("/status")
async def chat_status(project_id: str):
    """Return chat configuration status."""
    state = await _get_state(project_id)
    return {
        "ai_available": state.agent.is_available(),
        "model": state.agent.active_model() or None,
        "provider": state.agent._active_provider(),
        "history_length": len(state.conversation_history),
        "spec_fields": len(state.pipeline.spec),
    }


# ------------------------------------------------------------------
# Component registration — two paths
# ------------------------------------------------------------------

async def _register_components_from_llm(
    project_id: str, components: list[dict]
) -> str | None:
    """
    Register components designed by the LLM directly.

    The LLM generates components with real engineering parameters
    (correct gear math, proper positions, verified physics).
    These are registered as-is — they are NOT dummy shapes.
    """
    try:
        pm = await get_pm()
        cm = ComponentManager(pm.db)

        # Clear existing components (re-generation overwrites)
        existing = await cm.list_all(project_id)
        for comp in existing:
            await pm.db.conn.execute(
                "DELETE FROM components WHERE id = ? AND project_id = ?",
                (comp["id"], project_id),
            )
        if existing:
            await pm.db.conn.commit()

        if not components:
            return "No components in LLM response"

        for comp in components:
            comp_id = comp.get("id", f"comp_{hash(str(comp)) % 10000}")
            display_name = comp.get("display_name", comp_id)
            component_type = comp.get("component_type", comp.get("type", "box"))
            parameters = comp.get("parameters", {})
            position = comp.get("position", {"x": 0, "y": 0, "z": 0})
            # Preserve material and notes inside parameters so they survive DB roundtrip
            if comp.get("material"):
                parameters.setdefault("material", comp["material"])
            if comp.get("notes"):
                parameters.setdefault("notes", comp["notes"])

            await cm.register(
                project_id=project_id,
                component_id=comp_id,
                display_name=display_name,
                component_type=component_type,
                parameters=parameters,
                position=position,
            )

        logger.info(
            "Registered %d LLM-designed components for project %s",
            len(components), project_id,
        )
        return None
    except Exception as e:
        logger.error("Failed to register LLM components for %s: %s", project_id, e)
        return str(e)


async def _register_components_from_mapper(
    project_id: str, spec: dict
) -> str | None:
    """
    Register components from the mechanism mapper (FALLBACK only).

    Used when no AI is available and the keyword pipeline completes
    a spec. These are visualization-only shapes, not real designs.
    """
    try:
        pm = await get_pm()
        cm = ComponentManager(pm.db)

        # Clear existing components
        existing = await cm.list_all(project_id)
        for comp in existing:
            await pm.db.conn.execute(
                "DELETE FROM components WHERE id = ? AND project_id = ?",
                (comp["id"], project_id),
            )
        if existing:
            await pm.db.conn.commit()

        # Map spec → concrete component list
        components = spec_to_components(spec)

        if not components:
            msg = f"No components generated for mechanism '{spec.get('mechanism_type', 'unknown')}'"
            logger.warning(msg)
            return msg

        for comp in components:
            await cm.register(
                project_id=project_id,
                component_id=comp["id"],
                display_name=comp["display_name"],
                component_type=comp["component_type"],
                parameters=comp["parameters"],
                position=comp.get("position", {}),
            )

        logger.info(
            "Registered %d mapper components for project %s (mechanism=%s)",
            len(components), project_id, spec.get("mechanism_type", "unknown"),
        )
        return None
    except Exception as e:
        logger.error("Failed to register mapper components for %s: %s", project_id, e)
        return str(e)


# ------------------------------------------------------------------
# Rule 99, Rule 500, and gate transition commands
# ------------------------------------------------------------------

async def _handle_rule99_command(project_id: str, content: str) -> dict | None:
    """
    Detect and handle Rule 99 commands and gate transitions in chat.

    Returns a response dict if the message was a command, else None.
    """
    text = content.strip().lower()

    # Rule 99 commands
    if text.startswith("rule 99"):
        topic = text.replace("rule 99", "").strip()
        return await _run_rule99_in_chat(project_id, topic or None)

    # Gate transition commands
    if text in ("design locked", "lock design"):
        return await _attempt_gate_transition(project_id, "prototype")
    if text in ("prototype validated", "validate prototype"):
        return await _attempt_gate_transition(project_id, "production")

    # Rule 500 pipeline commands
    if text.startswith("rule 500"):
        gate_arg = text.replace("rule 500", "").strip()
        return await _run_rule500_in_chat(project_id, gate_arg or "production")

    return None


async def _run_rule99_in_chat(project_id: str, topic: str | None) -> dict:
    """Execute Rule 99 and format results for chat display."""
    try:
        pm = await get_pm()
        project = await pm.open(project_id)
        cm = ComponentManager(pm.db)
        components = await cm.list_all(project_id)

        component_types = [c.get("type", "") for c in components]
        mechanism_type = project.mechanism_type if hasattr(project, "mechanism_type") else ""

        project_state = ProjectState(
            gate_level=project.gate,
            mechanism_type=mechanism_type,
            component_types=component_types,
            components=components,
            project_dir=settings.projects_dir / project_id,
        )

        engine = get_rule99_engine()
        if topic:
            report = engine.run_targeted(topic, project_state)
        else:
            report = engine.run_gate_consultants(project.gate, project_state)

        # Format report as chat message
        lines = []
        mode = f"targeted: {topic}" if topic else f"gate: {project.gate}"
        lines.append(f"**Rule 99 Consultant Report** ({mode})")
        lines.append("")

        if report.passed:
            lines.append("**Result: PASS**")
        else:
            lines.append("**Result: FAIL** — issues found")

        for cr in report.consultants_fired:
            icon = "+" if cr.passed else "x"
            lines.append(f"\n[{icon}] **{cr.name}** "
                        f"({len(cr.checks_passed)}/{len(cr.checks_run)} checks passed)")
            for finding in cr.findings:
                lines.append(f"  {finding}")

        if report.recommendations:
            lines.append("\n**Recommendations:**")
            for rec in report.recommendations:
                lines.append(f"  - {rec}")

        if report.library_suggestions:
            lines.append(f"\n**Library suggestions:** "
                        f"{', '.join(ls.name for ls in report.library_suggestions[:5])}")

        return {
            "user_message": f"Rule 99{' ' + topic if topic else ''}",
            "message": "\n".join(lines),
            "response_type": "consultant",
            "consultant_report": report.to_dict(),
            "ai_powered": False,
        }

    except Exception as e:
        logger.error("Rule 99 chat command failed: %s", e)
        return {
            "user_message": f"Rule 99{' ' + topic if topic else ''}",
            "message": f"Rule 99 failed: {e}",
            "response_type": "error",
            "ai_powered": False,
        }


async def _attempt_gate_transition(project_id: str, target_gate: str) -> dict:
    """Attempt to advance the project gate, running Rule 99 consultants first."""
    try:
        pm = await get_pm()
        project = await pm.open(project_id)
        current_gate = project.gate

        # Run Rule 99 for the target gate
        cm = ComponentManager(pm.db)
        components = await cm.list_all(project_id)
        component_types = [c.get("type", "") for c in components]

        project_state = ProjectState(
            gate_level=target_gate,
            mechanism_type=project.mechanism_type if hasattr(project, "mechanism_type") else "",
            component_types=component_types,
            components=components,
            project_dir=settings.projects_dir / project_id,
        )

        engine = get_rule99_engine()
        report = engine.run_gate_consultants(target_gate, project_state)

        lines = []
        lines.append(f"**Gate Transition: {current_gate} -> {target_gate}**")
        lines.append("")

        if report.passed:
            # Snapshot before advancing (preserves pre-transition state)
            await _create_snapshot(
                project_id,
                f"Pre-gate: {current_gate} -> {target_gate}",
                trigger="gate_advance",
            )
            # Advance the gate
            await pm.update_gate(project_id, target_gate)
            lines.append(f"**APPROVED** — Gate advanced to {target_gate}")
        else:
            lines.append(f"**BLOCKED** — Cannot advance to {target_gate}")

        lines.append("")
        for cr in report.consultants_fired:
            icon = "+" if cr.passed else "x"
            lines.append(f"[{icon}] **{cr.name}** "
                        f"({len(cr.checks_passed)}/{len(cr.checks_run)} passed)")
            for finding in cr.findings[:3]:  # Show top 3 findings
                lines.append(f"  {finding}")
            if len(cr.findings) > 3:
                lines.append(f"  ... +{len(cr.findings) - 3} more findings")

        if report.recommendations:
            lines.append("\n**Fix before advancing:**")
            for rec in report.recommendations[:5]:
                lines.append(f"  - {rec}")

        return {
            "user_message": f"{'design locked' if target_gate == 'prototype' else 'prototype validated'}",
            "message": "\n".join(lines),
            "response_type": "gate_transition",
            "gate_advanced": report.passed,
            "previous_gate": current_gate,
            "target_gate": target_gate,
            "consultant_report": report.to_dict(),
            "ai_powered": False,
        }

    except Exception as e:
        logger.error("Gate transition failed: %s", e)
        return {
            "user_message": "gate transition",
            "message": f"Gate transition failed: {e}",
            "response_type": "error",
            "ai_powered": False,
        }


async def _run_rule500_in_chat(project_id: str, gate_level: str) -> dict:
    """Execute Rule 500 pipeline and format results for chat display."""
    try:
        from app.orchestrator.rule500_pipeline import get_pipeline

        pm = await get_pm()
        project = await pm.open(project_id)
        cm = ComponentManager(pm.db)
        components = await cm.list_all(project_id)

        # Gather scad_source and spec for production gate steps
        scad_source = _read_scad_source(project) or {}
        spec = project.spec if hasattr(project, 'spec') and project.spec else {}

        pipeline = get_pipeline()
        report = await pipeline.run(
            project_id=project_id,
            project_dir=settings.projects_dir / project_id,
            gate_level=gate_level,
            components=components,
            spec=spec,
            scad_source=scad_source,
        )

        lines = [f"**Rule 500 Pipeline Report** (through {gate_level} gate)"]
        lines.append("")

        if report.passed:
            lines.append(f"**Result: ALL PASS** ({len(report.steps)} steps)")
        else:
            lines.append(f"**Result: FAIL** — stopped at step {report.stopped_at or '?'}")

        lines.append("")

        # Group by phase
        current_phase = ""
        for step in report.steps:
            if step.phase != current_phase:
                current_phase = step.phase
                lines.append(f"\n**Phase: {current_phase.upper()}**")

            icon = "+" if step.passed else "x"
            critical = " [CRITICAL]" if step.critical and not step.passed else ""
            lines.append(f"  [{icon}] Step {step.step}: {step.name}{critical} ({step.duration_ms}ms)")

            if not step.passed:
                for finding in step.findings[:2]:
                    lines.append(f"      {finding}")

        lines.append(f"\nTotal time: {report.total_duration_ms}ms")
        lines.append(report.summary)

        return {
            "user_message": f"Rule 500 {gate_level}",
            "message": "\n".join(lines),
            "response_type": "pipeline",
            "pipeline_report": report.to_dict(),
            "ai_powered": False,
        }

    except Exception as e:
        logger.error("Rule 500 chat command failed: %s", e)
        return {
            "user_message": f"Rule 500 {gate_level}",
            "message": f"Rule 500 failed: {e}",
            "response_type": "error",
            "ai_powered": False,
        }


# ------------------------------------------------------------------
# Gate validation
# ------------------------------------------------------------------

async def _run_gate_check(project_id: str) -> dict | None:
    """
    Run gate validation on a project's registered components.

    Returns a dict with gate results including pass/fail, validator details,
    and a human-readable summary. Returns None if no components exist.
    """
    try:
        pm = await get_pm()
        cm = ComponentManager(pm.db)
        components = await cm.list_all(project_id)

        if not components:
            return None

        # Build meshes with transforms and component type map
        named_meshes = []
        component_types: dict[str, str] = {}

        for comp in components:
            gr = component_to_geometry(_engine, comp)
            if gr is None:
                continue

            mesh = _engine._to_trimesh(gr)
            component_types[gr.name] = comp.get("type", "")

            pos = comp.get("position", {})
            if isinstance(pos, dict) and any(pos.get(k, 0) != 0 for k in ("x", "y", "z")):
                transform = trimesh.transformations.translation_matrix([
                    float(pos.get("x", 0)),
                    float(pos.get("y", 0)),
                    float(pos.get("z", 0)),
                ])
            else:
                transform = None

            named_meshes.append((gr.name, mesh, transform))

        if not named_meshes:
            return None

        gate_result = _enforcer.run(
            meshes=named_meshes,
            component_types=component_types,
            gate_level="design",
        )

        result = gate_result.to_dict()

        # Add actionable suggestions for each failure
        suggestions = []
        for v in result.get("validators", []):
            if v["passed"]:
                continue
            validator_type = v.get("validator", "")
            mesh_name = v.get("mesh_name", "")

            if validator_type == "collision":
                for col in v.get("collisions", []):
                    suggestions.append(
                        f"COLLISION: {col['mesh_a']} + {col['mesh_b']} "
                        f"-- try increasing spacing or adjusting positions."
                    )
            elif validator_type == "manufacturability":
                for check in v.get("checks", []):
                    if check["passed"]:
                        continue
                    check_name = check.get("name", "")
                    if check_name == "watertight":
                        suggestions.append(
                            f"NOT WATERTIGHT: {mesh_name} -- check for gaps in the mesh."
                        )
                    elif check_name == "overhang":
                        pct = check.get("value", 0)
                        suggestions.append(
                            f"OVERHANG: {mesh_name} has {pct:.0f}% overhang faces "
                            f"-- consider print orientation or supports."
                        )
                    elif check_name == "wall_thickness":
                        val = check.get("value")
                        thresh = check.get("threshold", 1.5)
                        suggestions.append(
                            f"THIN WALL: {mesh_name} ({val}mm < {thresh}mm) "
                            f"-- increase wall thickness."
                        )

        result["suggestions"] = suggestions
        return result

    except Exception as e:
        logger.error("Gate check failed for project %s: %s", project_id, e)
        return None


# ------------------------------------------------------------------
# CadQuery/build123d code execution
# ------------------------------------------------------------------

async def _execute_code_blocks(
    project_id: str, code_blocks: list[dict[str, str]]
) -> list[dict]:
    """
    Execute Python/CadQuery/build123d code blocks from LLM response.

    Each code block with language 'python', 'cadquery', or 'build123d' is
    run in a sandboxed subprocess via CadQueryEngine. Output STEP/STL files
    are written to the project's models/ directory.
    """
    results = []
    cq_engine = CadQueryEngine()
    models_dir = settings.projects_dir / project_id / "models"
    models_dir.mkdir(parents=True, exist_ok=True)

    for i, block in enumerate(code_blocks):
        lang = block.get("language", "").lower()
        code = block.get("code", "")

        if lang not in ("python", "cadquery", "build123d") or not code.strip():
            results.append({"language": lang, "skipped": True, "success": False})
            continue

        filename_base = f"generated_{int(time.time())}_{i}"
        gen_result = await cq_engine.generate(
            code=code,
            output_dir=models_dir,
            filename_base=filename_base,
        )

        exec_info = {
            "language": lang,
            "skipped": False,
            "success": gen_result.success,
            "error": gen_result.error,
            "stdout": gen_result.stdout[:500] if gen_result.stdout else "",
            "stderr": gen_result.stderr[:500] if gen_result.stderr else "",
            "execution_time": gen_result.execution_time,
            "output_files": {
                fmt: str(p) for fmt, p in gen_result.output_files.items()
            },
        }
        results.append(exec_info)

        if gen_result.success:
            logger.info(
                "CadQuery execution succeeded for project %s: %s (%.1fs)",
                project_id, list(gen_result.output_files.keys()),
                gen_result.execution_time,
            )
        else:
            logger.warning(
                "CadQuery execution failed for project %s: %s",
                project_id, gen_result.error[:200],
            )

    return results


# ------------------------------------------------------------------
# Timeline / version history snapshots
# ------------------------------------------------------------------

async def _ensure_snapshots_table(pm) -> None:
    """Ensure snapshots table exists (backwards-compatible migration)."""
    try:
        await pm.db.conn.execute("SELECT 1 FROM snapshots LIMIT 1")
    except Exception:
        await pm.db.conn.executescript("""
            CREATE TABLE IF NOT EXISTS snapshots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id TEXT NOT NULL,
                label TEXT NOT NULL,
                gate TEXT NOT NULL,
                spec_json TEXT,
                components_json TEXT,
                decisions_json TEXT,
                trigger TEXT DEFAULT 'auto',
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (project_id) REFERENCES projects(id)
            );
            CREATE INDEX IF NOT EXISTS idx_snapshots_project
                ON snapshots(project_id, created_at);
        """)
        await pm.db.conn.commit()


async def _create_snapshot(
    project_id: str, label: str, trigger: str = "auto"
) -> int | None:
    """
    Create a project snapshot (spec + components + decisions).

    Snapshots are taken automatically at key moments:
    - After successful component registration
    - Before gate transitions
    These enable rollback to any previous design state.
    """
    try:
        pm = await get_pm()
        project = await pm.open(project_id)
        cm = ComponentManager(pm.db)
        components = await cm.list_all(project_id)

        cursor = await pm.db.conn.execute(
            "SELECT parameter, value, reason, status FROM decisions "
            "WHERE project_id = ?",
            (project_id,),
        )
        decisions = [dict(r) for r in await cursor.fetchall()]

        spec = {}
        if project_id in _chat_states:
            spec = dict(_chat_states[project_id].pipeline.spec)

        await _ensure_snapshots_table(pm)
        cursor = await pm.db.conn.execute(
            "INSERT INTO snapshots "
            "(project_id, label, gate, spec_json, components_json, "
            "decisions_json, trigger) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (
                project_id, label, project.gate,
                json.dumps(spec, default=str),
                json.dumps(components, default=str),
                json.dumps(decisions, default=str), trigger,
            ),
        )
        await pm.db.conn.commit()
        snap_id = cursor.lastrowid
        logger.info("Snapshot #%d for %s: %s", snap_id, project_id, label)
        return snap_id
    except Exception as e:
        logger.warning("Could not create snapshot for %s: %s", project_id, e)
        return None
