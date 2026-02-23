"""
Rule 99 Engine — Deterministic Consultant Dispatcher.

No AI calls. Examines project state, fires the right consultants based on
gate level and component types, returns structured findings.

Usage:
    engine = Rule99Engine()
    report = engine.run_gate_consultants("design", project_state)
    report = engine.run_targeted("cam", project_state)
    report = engine.run_pre_design(spec)
"""

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

logger = logging.getLogger(__name__)

# Path to data files (relative to backend/)
_DATA_DIR = Path(__file__).parent.parent.parent / "data"


@dataclass
class LibrarySuggestion:
    """A library from the roster that's relevant to the current project."""
    name: str
    pip: str | None
    github: str | None
    phase: str
    role: str
    purpose: str
    triggers: list[str]


@dataclass
class ConsultantResult:
    """Result from a single consultant run."""
    name: str
    passed: bool
    findings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)
    libraries_used: list[str] = field(default_factory=list)
    checks_run: list[str] = field(default_factory=list)
    checks_passed: list[str] = field(default_factory=list)
    checks_failed: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "passed": self.passed,
            "findings": self.findings,
            "recommendations": self.recommendations,
            "libraries_used": self.libraries_used,
            "checks_run": self.checks_run,
            "checks_passed": self.checks_passed,
            "checks_failed": self.checks_failed,
        }


@dataclass
class ConsultantReport:
    """Aggregated report from all consultants fired for a gate/topic."""
    gate: str
    consultants_fired: list[ConsultantResult] = field(default_factory=list)
    passed: bool = True
    recommendations: list[str] = field(default_factory=list)
    library_suggestions: list[LibrarySuggestion] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "gate": self.gate,
            "passed": self.passed,
            "consultants_fired": [c.to_dict() for c in self.consultants_fired],
            "recommendations": self.recommendations,
            "library_suggestions": [
                {
                    "name": ls.name,
                    "pip": ls.pip,
                    "github": ls.github,
                    "phase": ls.phase,
                    "role": ls.role,
                    "purpose": ls.purpose,
                }
                for ls in self.library_suggestions
            ],
            "total_checks": sum(len(c.checks_run) for c in self.consultants_fired),
            "checks_passed": sum(len(c.checks_passed) for c in self.consultants_fired),
            "checks_failed": sum(len(c.checks_failed) for c in self.consultants_fired),
        }


@dataclass
class ProjectState:
    """Current project state used for consultant dispatch."""
    gate_level: str = "design"
    mechanism_type: str = ""
    component_types: list[str] = field(default_factory=list)
    components: list[dict] = field(default_factory=list)
    spec: dict = field(default_factory=dict)
    scad_files: list[Path] = field(default_factory=list)
    project_dir: Path | None = None
    envelope: dict = field(default_factory=dict)  # {width, height, depth}
    motor_spec: dict = field(default_factory=dict)  # {voltage, rpm, torque_nm}
    material: str = ""
    tolerance_pairs: list[dict] = field(default_factory=list)
    stackup_contributors: list[dict] = field(default_factory=list)


class Rule99Engine:
    """
    Deterministic consultant dispatcher.

    Loads rule99_config.yaml and library_roster.yaml on init.
    Dispatches consultants based on gate level, component types, and triggers.
    """

    def __init__(self):
        self._config: dict = {}
        self._library_roster: list[dict] = []
        self._consultant_modules: dict[str, Any] = {}
        self._load_config()
        self._load_library_roster()
        self._load_consultant_modules()

    def _load_config(self):
        """Load rule99_config.yaml."""
        config_path = _DATA_DIR / "rule99_config.yaml"
        if config_path.exists():
            with open(config_path, "r") as f:
                self._config = yaml.safe_load(f) or {}
            logger.info("Loaded Rule 99 config: %d gates, %d topics",
                        len(self._config.get("gates", {})),
                        len(self._config.get("topics", {})))
        else:
            logger.warning("Rule 99 config not found at %s", config_path)

    def _load_library_roster(self):
        """Load library_roster.yaml."""
        roster_path = _DATA_DIR / "library_roster.yaml"
        if roster_path.exists():
            with open(roster_path, "r") as f:
                data = yaml.safe_load(f) or {}
            self._library_roster = data.get("libraries", [])
            logger.info("Loaded library roster: %d libraries", len(self._library_roster))
        else:
            logger.warning("Library roster not found at %s", roster_path)

    def _load_consultant_modules(self):
        """Lazy-import all consultant modules."""
        from app.consultants import (
            mechanism_consultant,
            physics_consultant,
            kinematic_chain_consultant,
            vertical_budget_consultant,
            aesthetics_consultant,
            iso286_consultant,
            stackup_consultant,
            fdm_ground_truth_consultant,
            collision_consultant,
            dfm_consultant,
            materials_consultant,
            bom_consultant,
            freecad_consultant,
        )

        self._consultant_modules = {
            "mechanism_consultant": mechanism_consultant,
            "physics_consultant": physics_consultant,
            "kinematic_chain_consultant": kinematic_chain_consultant,
            "vertical_budget_consultant": vertical_budget_consultant,
            "aesthetics_consultant": aesthetics_consultant,
            "iso286_consultant": iso286_consultant,
            "stackup_consultant": stackup_consultant,
            "fdm_ground_truth_consultant": fdm_ground_truth_consultant,
            "collision_consultant": collision_consultant,
            "dfm_consultant": dfm_consultant,
            "materials_consultant": materials_consultant,
            "bom_consultant": bom_consultant,
            "freecad_consultant": freecad_consultant,
        }

    def run_gate_consultants(
        self, gate_level: str, project_state: ProjectState
    ) -> ConsultantReport:
        """
        Run all consultants for the specified gate level.

        This is the main entry point. It:
        1. Looks up which consultants are registered for this gate
        2. Checks trigger conditions against project state
        3. Fires matching consultants
        4. Collects results into a ConsultantReport
        5. Suggests relevant libraries from the roster
        """
        report = ConsultantReport(gate=gate_level)

        gate_config = self._config.get("gates", {}).get(gate_level)
        if not gate_config:
            logger.warning("No gate config for '%s'", gate_level)
            return report

        consultants = gate_config.get("consultants", [])

        for consultant_def in consultants:
            name = consultant_def["name"]
            module_name = consultant_def["module"]
            triggers = consultant_def.get("triggers", [])
            checks = consultant_def.get("checks", [])
            component_types_filter = consultant_def.get("component_types", [])

            # Check if this consultant should fire
            if not self._should_fire(triggers, component_types_filter, project_state):
                continue

            # Fire the consultant
            result = self._fire_consultant(module_name, project_state, checks)
            result.name = name
            report.consultants_fired.append(result)

            if not result.passed:
                report.passed = False
                report.recommendations.extend(result.recommendations)

        # Suggest relevant libraries
        report.library_suggestions = self._suggest_libraries(project_state)

        return report

    def run_targeted(
        self, topic: str, project_state: ProjectState
    ) -> ConsultantReport:
        """
        Run targeted consultants for a specific topic.

        Usage: "Rule 99 cam" → fires mechanism + physics consultants
        Topics are mapped in rule99_config.yaml.
        """
        topics = self._config.get("topics", {})
        consultant_names = topics.get(topic, [])

        if not consultant_names:
            logger.warning("Unknown Rule 99 topic: '%s'", topic)
            return ConsultantReport(gate=f"targeted:{topic}")

        report = ConsultantReport(gate=f"targeted:{topic}")

        # Find consultant definitions across all gates
        all_consultants = {}
        for gate_data in self._config.get("gates", {}).values():
            for c in gate_data.get("consultants", []):
                all_consultants[c["name"]] = c

        for name in consultant_names:
            consultant_def = all_consultants.get(name)
            if not consultant_def:
                logger.warning("Consultant '%s' not found in any gate", name)
                continue

            module_name = consultant_def["module"]
            checks = consultant_def.get("checks", [])

            result = self._fire_consultant(module_name, project_state, checks)
            result.name = name
            report.consultants_fired.append(result)

            if not result.passed:
                report.passed = False
                report.recommendations.extend(result.recommendations)

        report.library_suggestions = self._suggest_libraries(project_state)
        return report

    def run_pre_design(self, spec: dict) -> ConsultantReport:
        """
        Run pre-design checks on a spec before any geometry is generated.

        Used by the translator layer to catch issues early.
        """
        project_state = ProjectState(
            gate_level="design",
            mechanism_type=spec.get("mechanism_type", ""),
            component_types=spec.get("component_types", []),
            spec=spec,
            envelope=spec.get("envelope", {}),
            motor_spec=spec.get("motor", {}),
            material=spec.get("material", ""),
        )

        return self.run_gate_consultants("design", project_state)

    def get_gate_consultant_info(self, gate_level: str) -> list[dict]:
        """
        Return metadata about consultants for a gate (for UI display).
        """
        gate_config = self._config.get("gates", {}).get(gate_level, {})
        return gate_config.get("consultants", [])

    def get_topics(self) -> dict[str, list[str]]:
        """Return the topic → consultant mapping."""
        return self._config.get("topics", {})

    def _should_fire(
        self,
        triggers: list[str],
        component_types_filter: list[str],
        state: ProjectState,
    ) -> bool:
        """
        Determine if a consultant should fire based on triggers.

        Triggers:
        - "always" → always fires
        - Component type matches (e.g., "four_bar", "planetary")
        - Mechanism type matches
        """
        if "always" in triggers:
            return True

        # Check mechanism type
        if state.mechanism_type and state.mechanism_type in triggers:
            return True

        # Check component types in project
        for ctype in state.component_types:
            if ctype in triggers:
                return True

        # Check component_types_filter (if specified, at least one must match)
        if component_types_filter:
            for ctype in state.component_types:
                if ctype in component_types_filter:
                    return True
            # If filter specified but nothing matched, don't fire
            return False

        return False

    def _fire_consultant(
        self,
        module_name: str,
        state: ProjectState,
        checks: list[str],
    ) -> ConsultantResult:
        """
        Import and execute a consultant module.

        Each consultant module exposes a `run(state, checks)` function.
        """
        module = self._consultant_modules.get(module_name)
        if module is None:
            logger.error("Consultant module '%s' not loaded", module_name)
            return ConsultantResult(
                name=module_name,
                passed=False,
                findings=[f"Consultant module '{module_name}' not found"],
            )

        try:
            result = module.run(state, checks)
            return result
        except Exception as e:
            logger.error("Consultant '%s' failed: %s", module_name, e, exc_info=True)
            return ConsultantResult(
                name=module_name,
                passed=False,
                findings=[f"Consultant error: {e}"],
                recommendations=["Fix consultant error and re-run"],
            )

    def _suggest_libraries(self, state: ProjectState) -> list[LibrarySuggestion]:
        """
        Suggest relevant libraries from the roster based on project state.
        """
        suggestions = []
        seen = set()

        # Collect all keywords from state
        keywords = set()
        keywords.add(state.mechanism_type)
        keywords.update(state.component_types)
        keywords.update(state.spec.get("component_types", []))

        # Also add implicit triggers
        if state.motor_spec:
            keywords.add("motor")
        if state.material:
            keywords.add(state.material.lower())
        if state.tolerance_pairs:
            keywords.update(["shaft", "bearing", "tolerance"])

        for lib in self._library_roster:
            lib_triggers = set(lib.get("triggers", []))
            lib_phase = lib.get("phase", "")

            # Skip libraries for later phases unless we're there
            phase_order = {"design": 0, "prototype": 1, "production": 2, "installed": 3}
            lib_phase_idx = phase_order.get(lib_phase, 0)
            state_phase_idx = phase_order.get(state.gate_level, 0)
            if lib_phase_idx > state_phase_idx + 1:
                continue

            # Check for trigger matches
            if "always" in lib_triggers or keywords & lib_triggers:
                name = lib["name"]
                if name not in seen:
                    seen.add(name)
                    suggestions.append(LibrarySuggestion(
                        name=name,
                        pip=lib.get("pip"),
                        github=lib.get("github"),
                        phase=lib_phase,
                        role=lib.get("role", ""),
                        purpose=lib.get("purpose", ""),
                        triggers=lib.get("triggers", []),
                    ))

        return suggestions


# Singleton instance
_engine: Rule99Engine | None = None


def get_engine() -> Rule99Engine:
    """Get or create the singleton Rule99Engine."""
    global _engine
    if _engine is None:
        _engine = Rule99Engine()
    return _engine
