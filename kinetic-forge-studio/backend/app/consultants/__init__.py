"""
Rule 99 Consultant Engine — deterministic design methodology enforcement.

Each consultant checks specific conditions without AI calls.
The Rule99Engine dispatches the right consultants based on gate level
and project state.

Gate 1 (Design):
    mechanism, physics, kinematic_chain, vertical_budget, aesthetics

Gate 2 (Prototype):
    iso286, stackup, fdm_ground_truth, collision_enhanced

Gate 3 (Production):
    dfm, materials, bom, freecad_export
"""

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

__all__ = [
    "mechanism_consultant",
    "physics_consultant",
    "kinematic_chain_consultant",
    "vertical_budget_consultant",
    "aesthetics_consultant",
    "iso286_consultant",
    "stackup_consultant",
    "fdm_ground_truth_consultant",
    "collision_consultant",
    "dfm_consultant",
    "materials_consultant",
    "bom_consultant",
    "freecad_consultant",
]
