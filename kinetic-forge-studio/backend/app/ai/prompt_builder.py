"""
Prompt builder for assembling Claude API context.

Constructs a structured prompt that includes:
- System context (who Claude is in this app)
- Current spec sheet (locked decisions + extracted fields)
- Component registry (what's been generated so far)
- User profile (printer, preferences, style)
- The specific question or task

This keeps all prompt logic in one place so the orchestrator just calls
`build_prompt(...)` and gets back a ready-to-send string.
"""

from typing import Any


# System prompt that defines Claude's role in Kinetic Forge Studio
SYSTEM_PROMPT = """You are the design assistant for Kinetic Forge Studio, a kinetic sculpture design tool.

Your role:
- Help users design kinetic sculptures with precise mechanical parameters
- Ask clarifying questions when specs are incomplete
- Suggest mechanisms with specific numbers (teeth, module, dimensions)
- Flag physics violations (Grashof, transmission angle, power budget)
- Generate OpenSCAD code when requested

Rules:
- All dimensions in millimeters unless stated otherwise
- Single motor unless physics requires multiple
- Every animation must trace to a physical mechanism
- Four-bar: verify Grashof, transmission angle 40-140 deg
- Power budget: required < available / 2

Respond concisely. Use bullet points for options. Include specific numbers."""


class PromptBuilder:
    """Builds structured prompts for the Claude API."""

    def __init__(self):
        self.system_prompt = SYSTEM_PROMPT

    def build_system_prompt(self) -> str:
        """Return the system prompt."""
        return self.system_prompt

    def build_user_prompt(
        self,
        user_message: str,
        spec_fields: dict[str, Any] | None = None,
        locked_decisions: list[dict] | None = None,
        components: dict[str, Any] | None = None,
        user_profile: dict[str, Any] | None = None,
        question_context: str | None = None,
    ) -> str:
        """
        Assemble a full user prompt with all available context.

        Args:
            user_message: The user's raw chat message.
            spec_fields: Current spec sheet fields from classifier.
            locked_decisions: List of locked design decisions.
            components: Component registry dict.
            user_profile: User's printer/preference profile.
            question_context: Additional context about what we're asking.

        Returns:
            A formatted prompt string with all context sections.
        """
        sections = []

        # Section 1: Current Spec Sheet
        if spec_fields:
            sections.append(self._format_spec_sheet(spec_fields))

        # Section 2: Locked Decisions
        if locked_decisions:
            sections.append(self._format_decisions(locked_decisions))

        # Section 3: Component Registry
        if components:
            sections.append(self._format_components(components))

        # Section 4: User Profile
        if user_profile:
            sections.append(self._format_profile(user_profile))

        # Section 5: Question Context
        if question_context:
            sections.append(f"## Current Question\n{question_context}")

        # Section 6: User Message
        sections.append(f"## User Message\n{user_message}")

        return "\n\n".join(sections)

    def _format_spec_sheet(self, fields: dict[str, Any]) -> str:
        """Format the current spec sheet."""
        lines = ["## Current Spec Sheet"]
        for key, value in fields.items():
            lines.append(f"- **{key}**: {value}")
        return "\n".join(lines)

    def _format_decisions(self, decisions: list[dict]) -> str:
        """Format locked decisions."""
        lines = ["## Locked Decisions"]
        for d in decisions:
            status = d.get("status", "unknown")
            param = d.get("parameter", "?")
            value = d.get("value", "?")
            reason = d.get("reason", "")
            line = f"- [{status}] **{param}** = {value}"
            if reason:
                line += f" (reason: {reason})"
            lines.append(line)
        return "\n".join(lines)

    def _format_components(self, components: dict[str, Any]) -> str:
        """Format the component registry."""
        lines = ["## Component Registry"]
        for comp_id, comp in components.items():
            name = comp.get("display_name", comp_id)
            comp_type = comp.get("type", "unknown")
            params = comp.get("parameters", {})
            lines.append(f"- **{name}** ({comp_type}): {params}")
        return "\n".join(lines)

    def _format_profile(self, profile: dict[str, Any]) -> str:
        """Format the user profile."""
        lines = ["## User Profile"]
        printer = profile.get("printer", {})
        if printer:
            lines.append(f"- Printer: {printer.get('type', 'unknown')}, "
                         f"nozzle={printer.get('nozzle', '?')}mm, "
                         f"tolerance={printer.get('tolerance', '?')}mm")
        prefs = profile.get("preferences", {})
        if prefs:
            lines.append(f"- Default material: {prefs.get('default_material', '?')}")
            lines.append(f"- Default module: {prefs.get('default_module', '?')}")
        style = profile.get("style_tags", [])
        if style:
            lines.append(f"- Style: {', '.join(style)}")
        target = profile.get("production_target", "")
        if target:
            lines.append(f"- Production target: {target}")
        return "\n".join(lines)
