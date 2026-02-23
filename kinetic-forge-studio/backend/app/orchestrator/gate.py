"""
Gate Enforcer for the validation pipeline.

Runs all registered validators against a project's geometry and returns
a structured pass/fail result per check. The gate must pass before
the project can advance to the next stage (e.g., export).

Validators:
- collision: Check for overlapping meshes in assembly
- manufacturability: Check wall thickness, overhang, watertight

Usage:
    enforcer = GateEnforcer()
    result = enforcer.run(meshes, assembly_meshes)
"""

from dataclasses import dataclass, field
from typing import Any

import numpy as np
import trimesh

from app.validators.collision import check_collisions, CollisionResult
from app.validators.manufacturability import (
    check_manufacturability,
    ManufacturabilityResult,
)


@dataclass
class GateResult:
    """Aggregated result from all validators."""
    passed: bool
    validators: list[dict] = field(default_factory=list)
    summary: str = ""

    def to_dict(self) -> dict:
        return {
            "passed": self.passed,
            "validators": self.validators,
            "summary": self.summary,
        }


class GateEnforcer:
    """
    Orchestrates all validators for a project's geometry.

    Runs collision detection on the assembly and manufacturability
    checks on each individual mesh.
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
    ) -> GateResult:
        """
        Run all validators on the provided meshes.

        Args:
            meshes: List of (name, mesh, transform) tuples for the assembly.
                    Each mesh is checked individually for manufacturability
                    and the full set is checked for collisions.

        Returns:
            GateResult with per-validator results and overall pass/fail.
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

        # Aggregate pass/fail
        all_passed = all(v["passed"] for v in validators)

        failed_validators = [
            v.get("mesh_name", v["validator"])
            for v in validators
            if not v["passed"]
        ]

        if all_passed:
            summary = f"All checks passed ({len(validators)} validators)."
        else:
            summary = (
                f"Gate BLOCKED: {len(failed_validators)} validator(s) failed "
                f"({', '.join(failed_validators)})."
            )

        return GateResult(
            passed=all_passed,
            validators=validators,
            summary=summary,
        )

    def run_on_trimeshes(
        self,
        named_meshes: list[tuple[str, trimesh.Trimesh]],
    ) -> GateResult:
        """
        Convenience method: run validators on meshes without transforms.

        Args:
            named_meshes: List of (name, mesh) tuples.

        Returns:
            GateResult.
        """
        meshes_with_transforms = [
            (name, mesh, None) for name, mesh in named_meshes
        ]
        return self.run(meshes_with_transforms)
