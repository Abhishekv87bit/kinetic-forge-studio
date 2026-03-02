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

logger = logging.getLogger(__name__)


@dataclass
class GateResult:
    """Aggregated result from all validators."""
    passed: bool
    gate_level: str = "design"  # design, prototype, production
    validators: list[dict] = field(default_factory=list)
    summary: str = ""

    def to_dict(self) -> dict:
        return {
            "passed": self.passed,
            "gate_level": self.gate_level,
            "validators": self.validators,
            "summary": self.summary,
        }


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
        gate_level: str = "design",
    ) -> GateResult:
        """
        Run mesh-based validators (collision + manufacturability).

        For OpenSCAD/file-based validators, use run_full_async instead.
        """
        validators: list[dict] = []

        # 1. Collision detection (assembly-level)
        collision_result = check_collisions(meshes)
        validators.append(collision_result.to_dict())

        # 2. Manufacturability checks (per-mesh)
        for name, mesh, _ in meshes:
            mfg_result = check_manufacturability(
                mesh,
                min_wall_thickness=self.min_wall_thickness,
                max_overhang_angle=self.max_overhang_angle,
            )
            mfg_dict = mfg_result.to_dict()
            mfg_dict["mesh_name"] = name
            validators.append(mfg_dict)

        return self._aggregate(validators, gate_level)

    async def run_full_async(
        self,
        meshes: list[tuple[str, trimesh.Trimesh, np.ndarray | None]],
        scad_files: list[Path] | None = None,
        project_dir: Path | None = None,
        tolerance_pairs: list[dict] | None = None,
        stackup_contributors: list[dict] | None = None,
        gate_level: str = "design",
    ) -> GateResult:
        """
        Run all validators including async file-based validators.

        Args:
            meshes: Trimesh objects for collision + manufacturability.
            scad_files: OpenSCAD files for geometry validation.
            project_dir: Project directory for consistency audit.
            tolerance_pairs: ISO 286 shaft/hole pairs for tolerance check.
            stackup_contributors: Tolerance stackup contributors.
            gate_level: "design", "prototype", or "production".
        """
        validators: list[dict] = []

        # 1. Collision detection
        if meshes:
            collision_result = check_collisions(meshes)
            validators.append(collision_result.to_dict())

            # 2. Manufacturability
            for name, mesh, _ in meshes:
                mfg_result = check_manufacturability(
                    mesh,
                    min_wall_thickness=self.min_wall_thickness,
                    max_overhang_angle=self.max_overhang_angle,
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

        return self._aggregate(validators, gate_level)

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
