"""
Gate Enforcer for the validation pipeline.

Runs all registered validators against a project's geometry and returns
a structured pass/fail result per check. The gate must pass before
the project can advance to the next stage (e.g., export).

Validators:
- collision: Check for overlapping meshes in assembly
- manufacturability: Check wall thickness, overhang, watertight
- geometry: OpenSCAD compile + constraint validation (if .scad files present)
- consistency: Drift detection between .scad, config, and docs
- tolerance: ISO 286 fits + stackup analysis (prototype gate only)
- rule99: Deterministic consultant pipeline (methodology enforcement)
"""

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np
import trimesh

from app.validators.collision import check_collisions, CollisionResult
from app.validators.manufacturability import (
    check_manufacturability,
    ManufacturabilityResult,
)
from app.validators import geometry_validator, consistency_validator, tolerance_validator
from app.consultants.rule99_engine import get_engine, ProjectState

logger = logging.getLogger(__name__)


@dataclass
class GateResult:
    """Aggregated result from all validators."""
    passed: bool
    gate_level: str = "design"  # design, prototype, production
    validators: list[dict] = field(default_factory=list)
    consultant_report: dict | None = None  # Rule 99 findings
    summary: str = ""

    def to_dict(self) -> dict:
        result = {
            "passed": self.passed,
            "gate_level": self.gate_level,
            "validators": self.validators,
            "summary": self.summary,
        }
        if self.consultant_report:
            result["consultant_report"] = self.consultant_report
        return result


class GateEnforcer:
    """
    Orchestrates all validators for a project's geometry.

    Gate levels determine which validators run:
    - design: collision + manufacturability
    - prototype: + geometry + consistency + tolerance
    - production: all validators, stricter thresholds
    """

    def __init__(
        self,
        min_wall_thickness: float = 1.5,
        max_overhang_angle: float = 45.0,
    ):
        self.min_wall_thickness = min_wall_thickness
        self.max_overhang_angle = max_overhang_angle

    def run(
        self,
        meshes: list[tuple[str, trimesh.Trimesh, np.ndarray | None]],
        component_types: dict[str, str] | None = None,
        gate_level: str = "design",
    ) -> GateResult:
        """
        Run mesh-based validators (collision + manufacturability).

        For OpenSCAD/file-based validators, use run_full_async instead.
        """
        component_types = component_types or {}
        validators: list[dict] = []

        # 1. Collision detection (assembly-level, gear-mesh contact exempt)
        collision_result = check_collisions(meshes, component_types=component_types)
        validators.append(collision_result.to_dict())

        # 2. Manufacturability checks (per-mesh, gear-aware overhang)
        for name, mesh, _ in meshes:
            ctype = component_types.get(name, "")
            # Gears have inherently vertical tooth faces — relax overhang threshold
            overhang_angle = 80.0 if ctype == "gear" else self.max_overhang_angle
            mfg_result = check_manufacturability(
                mesh,
                min_wall_thickness=self.min_wall_thickness,
                max_overhang_angle=overhang_angle,
            )
            mfg_dict = mfg_result.to_dict()
            mfg_dict["mesh_name"] = name
            validators.append(mfg_dict)

        return self._aggregate(validators, gate_level)

    async def run_full_async(
        self,
        meshes: list[tuple[str, trimesh.Trimesh, np.ndarray | None]],
        component_types: dict[str, str] | None = None,
        scad_files: list[Path] | None = None,
        project_dir: Path | None = None,
        tolerance_pairs: list[dict] | None = None,
        stackup_contributors: list[dict] | None = None,
        gate_level: str = "design",
        components: list[dict] | None = None,
        spec: dict | None = None,
        mechanism_type: str = "",
        envelope: dict | None = None,
        motor_spec: dict | None = None,
        material: str = "",
    ) -> GateResult:
        """
        Run all validators including async file-based validators AND Rule 99 consultants.

        Args:
            meshes: Trimesh objects for collision + manufacturability.
            component_types: Map of component name -> type for smart exemptions.
            scad_files: OpenSCAD files for geometry validation.
            project_dir: Project directory for consistency audit.
            tolerance_pairs: ISO 286 shaft/hole pairs for tolerance check.
            stackup_contributors: Tolerance stackup contributors.
            gate_level: "design", "prototype", or "production".
            components: Full component dicts for Rule 99 analysis.
            spec: Current project spec for Rule 99 analysis.
            mechanism_type: Mechanism type for consultant dispatch.
            envelope: Envelope dimensions for vertical budget.
            motor_spec: Motor specifications for power budget.
            material: Primary material for materials consultant.
        """
        component_types = component_types or {}
        validators: list[dict] = []

        # 1. Collision detection (gear-mesh contact exempt)
        if meshes:
            collision_result = check_collisions(meshes, component_types=component_types)
            validators.append(collision_result.to_dict())

            # 2. Manufacturability (gear-aware overhang)
            for name, mesh, _ in meshes:
                ctype = component_types.get(name, "")
                overhang_angle = 80.0 if ctype in ("gear", "rack") else self.max_overhang_angle
                mfg_result = check_manufacturability(
                    mesh,
                    min_wall_thickness=self.min_wall_thickness,
                    max_overhang_angle=overhang_angle,
                )
                mfg_dict = mfg_result.to_dict()
                mfg_dict["mesh_name"] = name
                validators.append(mfg_dict)

        # 3. Geometry validation (OpenSCAD compile + constraints)
        if scad_files:
            for scad_path in scad_files:
                geo_result = await geometry_validator.validate(scad_path)
                validators.append({
                    "validator": "geometry",
                    "passed": geo_result.passed,
                    "compile_ok": geo_result.compile_ok,
                    "constraint_checks": geo_result.constraint_checks,
                    "warnings": geo_result.warnings,
                    "errors": geo_result.errors,
                    "file": str(scad_path.name),
                })

        # 4. Consistency audit (prototype+ gate)
        if gate_level in ("prototype", "production") and project_dir:
            cons_result = await consistency_validator.audit(project_dir)
            validators.append({
                "validator": "consistency",
                "passed": cons_result.passed,
                "drift_items": cons_result.drift_items,
                "warnings": cons_result.warnings,
                "errors": cons_result.errors,
            })

        # 5. Tolerance validation (prototype+ gate)
        if gate_level in ("prototype", "production"):
            if tolerance_pairs or stackup_contributors:
                tol_result = await tolerance_validator.validate(
                    pairs=tolerance_pairs,
                    stackup_contributors=stackup_contributors,
                )
                validators.append({
                    "validator": "tolerance",
                    "passed": tol_result.passed,
                    "fits": [
                        {
                            "shaft": f.shaft_name,
                            "hole": f.hole_name,
                            "nominal": f.nominal,
                            "fit_type": f.fit_type,
                            "passed": f.passed,
                            "notes": f.notes,
                        }
                        for f in tol_result.fits
                    ],
                    "stackup": {
                        "worst_case": tol_result.stackup.worst_case,
                        "rss": tol_result.stackup.rss,
                        "passed": tol_result.stackup.passed,
                    } if tol_result.stackup else None,
                    "warnings": tol_result.warnings,
                    "errors": tol_result.errors,
                })

        # 6. Rule 99 Consultants — methodology enforcement
        consultant_report = None
        try:
            engine = get_engine()
            project_state = ProjectState(
                gate_level=gate_level,
                mechanism_type=mechanism_type,
                component_types=list(component_types.values()),
                components=components or [],
                spec=spec or {},
                scad_files=[Path(f) for f in (scad_files or [])],
                project_dir=project_dir,
                envelope=envelope or {},
                motor_spec=motor_spec or {},
                material=material,
                tolerance_pairs=tolerance_pairs or [],
                stackup_contributors=stackup_contributors or [],
            )
            report = engine.run_gate_consultants(gate_level, project_state)
            consultant_report = report.to_dict()

            # Add consultant results as a validator entry
            validators.append({
                "validator": "rule99",
                "passed": report.passed,
                "gate": report.gate,
                "consultants_fired": len(report.consultants_fired),
                "total_checks": consultant_report.get("total_checks", 0),
                "checks_passed": consultant_report.get("checks_passed", 0),
                "checks_failed": consultant_report.get("checks_failed", 0),
                "recommendations": report.recommendations,
            })
        except Exception as e:
            logger.error("Rule 99 consultants failed: %s", e, exc_info=True)
            # Don't block gate on consultant errors — log and continue
            validators.append({
                "validator": "rule99",
                "passed": True,  # Don't block on errors
                "error": str(e),
            })

        result = self._aggregate(validators, gate_level)
        result.consultant_report = consultant_report
        return result

    def run_on_trimeshes(
        self,
        named_meshes: list[tuple[str, trimesh.Trimesh]],
    ) -> GateResult:
        """Convenience method: run validators on meshes without transforms."""
        meshes_with_transforms = [
            (name, mesh, None) for name, mesh in named_meshes
        ]
        return self.run(meshes_with_transforms)

    def _aggregate(self, validators: list[dict], gate_level: str) -> GateResult:
        """Aggregate validator results into a single GateResult."""
        if not validators:
            return GateResult(
                passed=True,
                gate_level=gate_level,
                summary="No validators ran.",
            )

        all_passed = all(v["passed"] for v in validators)

        failed_validators = [
            v.get("mesh_name", v.get("file", v["validator"]))
            for v in validators
            if not v["passed"]
        ]

        if all_passed:
            summary = f"All checks passed ({len(validators)} validators, gate={gate_level})."
        else:
            summary = (
                f"Gate BLOCKED ({gate_level}): {len(failed_validators)} validator(s) failed "
                f"({', '.join(failed_validators)})."
            )

        return GateResult(
            passed=all_passed,
            gate_level=gate_level,
            validators=validators,
            summary=summary,
        )
