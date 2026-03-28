"""
LLM Evaluation Benchmark for Kinetic Forge Studio (GAP-PPL-004).

25 eval cases across 3 difficulty tiers test whether the ChatAgent
produces structured, mechanically-correct output.  Tests run offline
with mock responses -- no API key required.  A separate ``run_live_eval``
function calls the real provider and logs results to JSON.

Usage
-----
Offline (CI-safe):
    pytest tests/test_llm_eval.py -v

Live (manual, needs KFS_CLAUDE_API_KEY or similar):
    python -m tests.test_llm_eval          # runs run_live_eval()
    # Results written to tests/eval_results/eval_<timestamp>.json
"""

from __future__ import annotations

import json
import os
import re
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pytest

# ---------------------------------------------------------------------------
# Core data model
# ---------------------------------------------------------------------------

@dataclass
class EvalCase:
    """One benchmark prompt with its expected-output criteria."""

    id: str                          # e.g. "EASY-01"
    prompt: str                      # The user message
    difficulty: str                  # "easy", "medium", "hard"
    expected_keywords: list[str]     # Must appear (case-insensitive) in response
    expected_components: int         # Minimum component count in ```components```
    quality_criteria: list[str]      # Human-readable checks (for reporting)
    tags: list[str] = field(default_factory=list)  # Optional grouping tags


# ---------------------------------------------------------------------------
# The 25-case benchmark dataset
# ---------------------------------------------------------------------------

BENCHMARK_DATASET: list[EvalCase] = [
    # ------------------------------------------------------------------
    # EASY (8) -- single component, explicit parameters
    # ------------------------------------------------------------------
    EvalCase(
        id="EASY-01",
        prompt="Create a spur gear with 20 teeth, module 2, 10mm thick",
        difficulty="easy",
        expected_keywords=["gear", "teeth", "module"],
        expected_components=1,
        quality_criteria=[
            "Uses module=2, teeth=20 exactly",
            "Height/thickness is 10mm",
            "Pitch radius = module*teeth/2 = 20mm mentioned or implied",
            "Pressure angle stated or defaulted to 20 deg",
        ],
        tags=["gear", "single-part"],
    ),
    EvalCase(
        id="EASY-02",
        prompt="Make a cylinder 50mm diameter, 100mm tall",
        difficulty="easy",
        expected_keywords=["cylinder", "diameter", "height"],
        expected_components=1,
        quality_criteria=[
            "Diameter is 50mm (radius 25mm)",
            "Height is 100mm",
            "component_type is cylinder or custom",
        ],
        tags=["primitive", "single-part"],
    ),
    EvalCase(
        id="EASY-03",
        prompt="Design a 10mm bore bearing housing",
        difficulty="easy",
        expected_keywords=["bearing", "bore"],
        expected_components=1,
        quality_criteria=[
            "Bore ID is 10mm",
            "Housing OD larger than bore",
            "Wall thickness >= 1.2mm (FDM minimum)",
        ],
        tags=["bearing", "single-part"],
    ),
    EvalCase(
        id="EASY-04",
        prompt="Create a rectangular base plate 100x60x5mm",
        difficulty="easy",
        expected_keywords=["base", "plate"],
        expected_components=1,
        quality_criteria=[
            "Length 100mm, width 60mm, height 5mm",
            "component_type is frame or box",
            "grounded flag set or implied",
        ],
        tags=["frame", "single-part"],
    ),
    EvalCase(
        id="EASY-05",
        prompt="Make a shaft 8mm diameter, 80mm long with a keyway",
        difficulty="easy",
        expected_keywords=["shaft", "keyway"],
        expected_components=1,
        quality_criteria=[
            "Diameter 8mm",
            "Length 80mm",
            "Keyway feature mentioned in parameters or notes",
        ],
        tags=["shaft", "single-part"],
    ),
    EvalCase(
        id="EASY-06",
        prompt="Create a simple cam with 20mm base circle, 5mm rise",
        difficulty="easy",
        expected_keywords=["cam", "rise"],
        expected_components=1,
        quality_criteria=[
            "Base circle radius 20mm (or diameter 40mm)",
            "Rise is 5mm",
            "component_type is cam",
        ],
        tags=["cam", "single-part"],
    ),
    EvalCase(
        id="EASY-07",
        prompt="Design a pulley with 30mm diameter and 5mm groove",
        difficulty="easy",
        expected_keywords=["pulley", "groove"],
        expected_components=1,
        quality_criteria=[
            "Diameter 30mm",
            "Groove depth or width is 5mm",
            "component_type is pulley",
        ],
        tags=["pulley", "single-part"],
    ),
    EvalCase(
        id="EASY-08",
        prompt="Make a spacer ring, 20mm OD, 10mm ID, 3mm thick",
        difficulty="easy",
        expected_keywords=["spacer", "ring"],
        expected_components=1,
        quality_criteria=[
            "OD 20mm, ID 10mm",
            "Thickness/height 3mm",
            "Wall = (20-10)/2 = 5mm",
        ],
        tags=["spacer", "single-part"],
    ),

    # ------------------------------------------------------------------
    # MEDIUM (10) -- multi-component or implicit parameters
    # ------------------------------------------------------------------
    EvalCase(
        id="MED-09",
        prompt="Design a four-bar linkage that converts rotation to oscillation",
        difficulty="medium",
        expected_keywords=["linkage", "crank", "rocker"],
        expected_components=3,
        quality_criteria=[
            "At least 4 links identified (crank, coupler, rocker, frame)",
            "Grashof condition checked or referenced",
            "Transmission angle mentioned",
            "Frame link grounded",
        ],
        tags=["linkage", "mechanism"],
    ),
    EvalCase(
        id="MED-10",
        prompt="Create a sun gear and planet gear pair for a planetary gearbox",
        difficulty="medium",
        expected_keywords=["sun", "planet", "gear"],
        expected_components=2,
        quality_criteria=[
            "Sun and planet share same module",
            "Center distance = module*(sun_teeth+planet_teeth)/2",
            "Contact ratio > 1.2 or referenced",
            "Teeth counts avoid undercutting (>=17)",
        ],
        tags=["gear", "planetary"],
    ),
    EvalCase(
        id="MED-11",
        prompt="Make a crank-slider mechanism with 40mm crank radius",
        difficulty="medium",
        expected_keywords=["crank", "slider"],
        expected_components=3,
        quality_criteria=[
            "Crank radius 40mm",
            "Connecting rod length > crank radius",
            "Slider travel = 2 * crank radius = 80mm",
            "At least crank, connecting rod, slider components",
        ],
        tags=["linkage", "mechanism"],
    ),
    EvalCase(
        id="MED-12",
        prompt="Design a Geneva mechanism with 4 stops",
        difficulty="medium",
        expected_keywords=["geneva", "slot"],
        expected_components=2,
        quality_criteria=[
            "Drive wheel and driven wheel present",
            "4 slots on driven wheel",
            "Pin on drive wheel",
            "Locking arc covers idle dwell",
        ],
        tags=["mechanism", "intermittent"],
    ),
    EvalCase(
        id="MED-13",
        prompt="Create a worm gear pair, 30mm center distance",
        difficulty="medium",
        expected_keywords=["worm", "gear"],
        expected_components=2,
        quality_criteria=[
            "Worm and worm wheel present",
            "Center distance 30mm",
            "Axial pitch of worm matches circular pitch of wheel",
            "Self-locking ratio mentioned or achievable",
        ],
        tags=["gear", "worm"],
    ),
    EvalCase(
        id="MED-14",
        prompt="Design a cam-follower with dwell-rise-dwell profile",
        difficulty="medium",
        expected_keywords=["cam", "follower", "dwell"],
        expected_components=2,
        quality_criteria=[
            "Cam and follower as separate components",
            "Motion profile: dwell-rise-dwell stated",
            "Pressure angle constraint referenced",
            "Rise amount specified or inferred",
        ],
        tags=["cam", "mechanism"],
    ),
    EvalCase(
        id="MED-15",
        prompt="Make a helical gear with 30-degree helix angle, 25 teeth",
        difficulty="medium",
        expected_keywords=["helical", "gear", "helix"],
        expected_components=1,
        quality_criteria=[
            "Helix angle 30 degrees",
            "25 teeth",
            "Normal vs transverse module distinguished",
            "Axial thrust mentioned",
        ],
        tags=["gear", "helical"],
    ),
    EvalCase(
        id="MED-16",
        prompt="Create a bracket that mounts a NEMA 17 stepper motor",
        difficulty="medium",
        expected_keywords=["bracket", "nema", "motor"],
        expected_components=1,
        quality_criteria=[
            "NEMA 17 mounting pattern: 31mm bolt circle",
            "Central bore >= 22mm (pilot diameter)",
            "M3 bolt holes at 4 corners",
            "Wall thickness >= 3mm for structural rigidity",
        ],
        tags=["frame", "motor-mount"],
    ),
    EvalCase(
        id="MED-17",
        prompt="Design a ball bearing cage for 6mm balls, 8 balls",
        difficulty="medium",
        expected_keywords=["bearing", "cage", "ball"],
        expected_components=1,
        quality_criteria=[
            "8 ball pockets",
            "Ball diameter 6mm",
            "Pocket clearance ~0.3mm (FDM sliding tolerance)",
            "Cage ID and OD computed from ball circle",
        ],
        tags=["bearing", "cage"],
    ),
    EvalCase(
        id="MED-18",
        prompt="Make a herringbone gear with 20 teeth",
        difficulty="medium",
        expected_keywords=["herringbone", "gear"],
        expected_components=1,
        quality_criteria=[
            "20 teeth",
            "Two opposed helical sections (V-pattern)",
            "Helix angle specified",
            "Eliminates axial thrust",
        ],
        tags=["gear", "herringbone"],
    ),

    # ------------------------------------------------------------------
    # HARD (7) -- full assembly or complex reasoning
    # ------------------------------------------------------------------
    EvalCase(
        id="HARD-19",
        prompt="Design a complete planetary gearbox with 3:1 ratio",
        difficulty="hard",
        expected_keywords=["sun", "planet", "ring", "carrier"],
        expected_components=5,
        quality_criteria=[
            "Sun, planets (>=2), ring, carrier present",
            "Ratio = 1 + ring_teeth/sun_teeth = 3 satisfied",
            "Planetary constraint: ring = sun + 2*planet",
            "Assembly condition: (ring+sun) divisible by planet_count",
            "Frame/housing grounded",
            "Contact ratio checked",
        ],
        tags=["gear", "planetary", "assembly"],
    ),
    EvalCase(
        id="HARD-20",
        prompt="Create a harmonograph mechanism with two pendulums",
        difficulty="hard",
        expected_keywords=["pendulum", "harmonograph"],
        expected_components=4,
        quality_criteria=[
            "Two pendulum arms with pivot points",
            "Pen/stylus attachment point",
            "Phase offset between pendulums",
            "Frame/base structure grounded",
            "Frequency ratio for Lissajous-type patterns",
        ],
        tags=["mechanism", "kinetic-sculpture"],
    ),
    EvalCase(
        id="HARD-21",
        prompt="Design a Margolin-style wave sculpture base with 37 rods",
        difficulty="hard",
        expected_keywords=["wave", "rod"],
        expected_components=5,
        quality_criteria=[
            "37 rods (prime count avoids Moire)",
            "Cam or eccentric drive for vertical oscillation",
            "Phase offset between adjacent rods",
            "Base/frame structure",
            "Motor mount or drive mechanism",
        ],
        tags=["mechanism", "kinetic-sculpture", "margolin"],
    ),
    EvalCase(
        id="HARD-22",
        prompt="Make a clock escapement mechanism",
        difficulty="hard",
        expected_keywords=["escapement", "pallet"],
        expected_components=3,
        quality_criteria=[
            "Escape wheel with teeth",
            "Pallet fork / anchor",
            "Pendulum or balance wheel",
            "Entry and exit pallet angles",
            "Impulse and locking faces identified",
        ],
        tags=["mechanism", "horology"],
    ),
    EvalCase(
        id="HARD-23",
        prompt="Design a kinetic sculpture with a Scotch yoke and 3 decorative elements",
        difficulty="hard",
        expected_keywords=["scotch", "yoke"],
        expected_components=5,
        quality_criteria=[
            "Scotch yoke: crank pin, slotted yoke, slider",
            "3 decorative elements as separate components",
            "Sinusoidal output motion from yoke",
            "Motor mount or crank driver",
            "Frame/base grounded",
        ],
        tags=["mechanism", "kinetic-sculpture"],
    ),
    EvalCase(
        id="HARD-24",
        prompt="Create a differential gear assembly",
        difficulty="hard",
        expected_keywords=["differential", "bevel", "spider"],
        expected_components=5,
        quality_criteria=[
            "Ring gear (crown wheel)",
            "Pinion gear (drive)",
            "Spider gears (>=2)",
            "Side gears (2, one per axle)",
            "Carrier/cage for spider gears",
            "Equal torque split when straight",
        ],
        tags=["gear", "differential", "assembly"],
    ),
    EvalCase(
        id="HARD-25",
        prompt="Design a compliant mechanism gripper with 2mm wall thickness",
        difficulty="hard",
        expected_keywords=["compliant", "gripper", "flex"],
        expected_components=3,
        quality_criteria=[
            "Flexible hinges (living hinges) identified",
            "Wall thickness 2mm throughout",
            "Input force point and output grip point",
            "Mechanical advantage noted",
            "Material flexibility assumption stated (e.g. TPU/PP)",
        ],
        tags=["mechanism", "compliant"],
    ),
]


# ---------------------------------------------------------------------------
# Mock response generator
# ---------------------------------------------------------------------------

def _build_mock_response(case: EvalCase) -> str:
    """
    Generate a deterministic mock LLM response for offline testing.

    The mock is deliberately minimal -- just enough structured content
    to validate the parser and keyword/component-count checks.  It does
    NOT test LLM quality (that is what ``run_live_eval`` is for).
    """
    # Build fake components matching the expected count
    components: list[dict[str, Any]] = []
    for i in range(case.expected_components):
        comp_id = f"mock_{case.id.lower().replace('-', '_')}_part_{i+1}"
        # Pick a sensible component_type from expected keywords
        ctype = "custom"
        for kw in ("gear", "shaft", "cam", "bearing", "pulley", "frame",
                    "linkage", "cylinder"):
            if kw in [k.lower() for k in case.expected_keywords]:
                ctype = kw
                break

        comp: dict[str, Any] = {
            "id": comp_id,
            "display_name": f"Mock {case.id} Part {i+1}",
            "component_type": ctype,
            "parameters": {"height": 10.0, "diameter": 20.0},
            "position": {"x": i * 25.0, "y": 0, "z": 0},
            "notes": f"Auto-generated mock for eval case {case.id}",
        }

        # Inject expected keywords into parameters so keyword checks pass
        for kw in case.expected_keywords:
            comp["parameters"][kw] = True

        components.append(comp)

    components_json = json.dumps(components, indent=2)

    # Prose section embeds all expected keywords
    keyword_sentence = ", ".join(case.expected_keywords)

    # Build verification block
    verification = {
        "checks": [
            {"name": "mock_check", "status": "pass",
             "detail": f"Mock verification for {case.id}"},
        ],
        "warnings": [],
    }
    verification_json = json.dumps(verification, indent=2)

    return (
        f"Here is the design for: {case.prompt}\n\n"
        f"Key aspects: {keyword_sentence}.\n\n"
        f"```components\n{components_json}\n```\n\n"
        f"```verification\n{verification_json}\n```\n"
    )


# ---------------------------------------------------------------------------
# Response analysis helpers
# ---------------------------------------------------------------------------

@dataclass
class EvalResult:
    """Result of evaluating one case."""

    case_id: str
    difficulty: str
    passed: bool
    keyword_hits: dict[str, bool]
    component_count: int
    expected_components: int
    has_components_block: bool
    has_verification_block: bool
    has_code_block: bool
    errors: list[str] = field(default_factory=list)
    latency_ms: float = 0.0
    model: str = ""


def analyze_response(case: EvalCase, response_text: str) -> EvalResult:
    """
    Check a raw LLM response against an EvalCase's criteria.

    Returns an ``EvalResult`` with per-check detail.
    """
    errors: list[str] = []
    text_lower = response_text.lower()

    # -- Keyword presence --------------------------------------------------
    keyword_hits: dict[str, bool] = {}
    for kw in case.expected_keywords:
        keyword_hits[kw] = kw.lower() in text_lower
    missing_kw = [k for k, v in keyword_hits.items() if not v]
    if missing_kw:
        errors.append(f"Missing keywords: {missing_kw}")

    # -- Components block --------------------------------------------------
    comp_pattern = re.compile(r"```components\s*\n(.*?)\n```", re.DOTALL)
    comp_matches = comp_pattern.findall(response_text)
    has_components_block = len(comp_matches) > 0

    component_count = 0
    if has_components_block:
        for block in comp_matches:
            try:
                parsed = json.loads(block)
                if isinstance(parsed, list):
                    component_count += len(parsed)
                elif isinstance(parsed, dict):
                    component_count += 1
            except json.JSONDecodeError:
                errors.append("components block contains invalid JSON")
    else:
        errors.append("No ```components``` block found")

    if component_count < case.expected_components:
        errors.append(
            f"Component count {component_count} < expected {case.expected_components}"
        )

    # -- Verification block ------------------------------------------------
    verif_pattern = re.compile(r"```verification\s*\n(.*?)\n```", re.DOTALL)
    has_verification_block = bool(verif_pattern.search(response_text))

    # -- Code block (python or openscad) -----------------------------------
    code_pattern = re.compile(r"```(?:python|openscad)\s*\n(.*?)\n```", re.DOTALL)
    has_code_block = bool(code_pattern.search(response_text))

    passed = len(errors) == 0
    return EvalResult(
        case_id=case.id,
        difficulty=case.difficulty,
        passed=passed,
        keyword_hits=keyword_hits,
        component_count=component_count,
        expected_components=case.expected_components,
        has_components_block=has_components_block,
        has_verification_block=has_verification_block,
        has_code_block=has_code_block,
        errors=errors,
    )


# =========================================================================
# PYTEST TESTS -- run offline, no API key needed
# =========================================================================

class TestBenchmarkStructure:
    """Validate the benchmark dataset itself is well-formed."""

    def test_dataset_has_25_cases(self):
        assert len(BENCHMARK_DATASET) == 25, (
            f"Expected 25 eval cases, got {len(BENCHMARK_DATASET)}"
        )

    def test_unique_ids(self):
        ids = [c.id for c in BENCHMARK_DATASET]
        assert len(ids) == len(set(ids)), f"Duplicate IDs: {ids}"

    def test_difficulty_distribution(self):
        counts = {}
        for c in BENCHMARK_DATASET:
            counts[c.difficulty] = counts.get(c.difficulty, 0) + 1
        assert counts.get("easy") == 8, f"Expected 8 easy, got {counts.get('easy')}"
        assert counts.get("medium") == 10, f"Expected 10 medium, got {counts.get('medium')}"
        assert counts.get("hard") == 7, f"Expected 7 hard, got {counts.get('hard')}"

    def test_all_cases_have_required_fields(self):
        for c in BENCHMARK_DATASET:
            assert c.id, f"Case missing id"
            assert c.prompt, f"{c.id}: empty prompt"
            assert c.difficulty in ("easy", "medium", "hard"), (
                f"{c.id}: bad difficulty '{c.difficulty}'"
            )
            assert len(c.expected_keywords) > 0, f"{c.id}: no expected_keywords"
            assert c.expected_components >= 1, f"{c.id}: expected_components < 1"
            assert len(c.quality_criteria) > 0, f"{c.id}: no quality_criteria"

    def test_ids_match_difficulty_prefix(self):
        prefix_map = {"easy": "EASY-", "medium": "MED-", "hard": "HARD-"}
        for c in BENCHMARK_DATASET:
            expected_prefix = prefix_map[c.difficulty]
            assert c.id.startswith(expected_prefix), (
                f"{c.id} should start with '{expected_prefix}' for difficulty '{c.difficulty}'"
            )

    def test_prompts_are_non_trivial(self):
        for c in BENCHMARK_DATASET:
            word_count = len(c.prompt.split())
            assert word_count >= 4, (
                f"{c.id}: prompt too short ({word_count} words): '{c.prompt}'"
            )

    def test_expected_components_scale_with_difficulty(self):
        """Hard cases should generally require more components than easy ones."""
        easy_avg = sum(
            c.expected_components for c in BENCHMARK_DATASET if c.difficulty == "easy"
        ) / 8
        hard_avg = sum(
            c.expected_components for c in BENCHMARK_DATASET if c.difficulty == "hard"
        ) / 7
        assert hard_avg > easy_avg, (
            f"Hard avg components ({hard_avg:.1f}) should exceed easy ({easy_avg:.1f})"
        )


# Parametrize over all 25 cases for response-format checks
@pytest.mark.parametrize(
    "eval_case",
    BENCHMARK_DATASET,
    ids=[c.id for c in BENCHMARK_DATASET],
)
class TestResponseFormat:
    """
    Validate that mock (or cached) responses satisfy structural rules.

    These tests confirm the *evaluation harness itself* works correctly
    and that mock responses pass.  Real quality testing happens in
    ``run_live_eval``.
    """

    def test_mock_response_keywords(self, eval_case: EvalCase):
        """Mock response must contain all expected keywords."""
        response = _build_mock_response(eval_case)
        result = analyze_response(eval_case, response)
        missing = [k for k, v in result.keyword_hits.items() if not v]
        assert not missing, f"{eval_case.id}: missing keywords {missing}"

    def test_mock_response_components_block(self, eval_case: EvalCase):
        """Mock response must contain a parseable ```components``` block."""
        response = _build_mock_response(eval_case)
        result = analyze_response(eval_case, response)
        assert result.has_components_block, f"{eval_case.id}: no components block"

    def test_mock_response_component_count(self, eval_case: EvalCase):
        """Mock response must meet minimum component count."""
        response = _build_mock_response(eval_case)
        result = analyze_response(eval_case, response)
        assert result.component_count >= eval_case.expected_components, (
            f"{eval_case.id}: {result.component_count} components "
            f"< expected {eval_case.expected_components}"
        )

    def test_mock_response_passes(self, eval_case: EvalCase):
        """Mock response must pass all checks (no errors)."""
        response = _build_mock_response(eval_case)
        result = analyze_response(eval_case, response)
        assert result.passed, (
            f"{eval_case.id}: {result.errors}"
        )

    def test_components_have_valid_json(self, eval_case: EvalCase):
        """Each component in the mock should have required fields."""
        response = _build_mock_response(eval_case)
        matches = re.findall(
            r"```components\s*\n(.*?)\n```", response, re.DOTALL
        )
        for block in matches:
            parsed = json.loads(block)
            items = parsed if isinstance(parsed, list) else [parsed]
            for comp in items:
                assert "id" in comp, f"{eval_case.id}: component missing 'id'"
                assert "component_type" in comp, (
                    f"{eval_case.id}: component missing 'component_type'"
                )
                assert "parameters" in comp, (
                    f"{eval_case.id}: component missing 'parameters'"
                )


class TestEvalSummary:
    """Aggregate pass-rate report across all benchmark cases (mock responses)."""

    def test_overall_pass_rate(self):
        """All mock responses should pass (they are constructed to pass)."""
        results: list[EvalResult] = []
        for case in BENCHMARK_DATASET:
            response = _build_mock_response(case)
            results.append(analyze_response(case, response))

        total = len(results)
        passed = sum(1 for r in results if r.passed)
        assert passed == total, (
            f"Mock pass rate: {passed}/{total} "
            f"({100*passed/total:.0f}%). Failures: "
            + ", ".join(r.case_id for r in results if not r.passed)
        )

    def test_pass_rate_by_difficulty(self):
        """Report per-difficulty pass rates."""
        by_diff: dict[str, list[EvalResult]] = {"easy": [], "medium": [], "hard": []}
        for case in BENCHMARK_DATASET:
            response = _build_mock_response(case)
            result = analyze_response(case, response)
            by_diff[result.difficulty].append(result)

        for diff, results in by_diff.items():
            total = len(results)
            passed = sum(1 for r in results if r.passed)
            rate = passed / total if total else 0
            # All mocks should pass
            assert rate == 1.0, (
                f"{diff}: {passed}/{total} ({100*rate:.0f}%). "
                f"Failures: {[r.case_id for r in results if not r.passed]}"
            )

    def test_summary_report_structure(self):
        """The summary report dict has the expected shape."""
        report = _build_summary_report(
            [analyze_response(c, _build_mock_response(c)) for c in BENCHMARK_DATASET]
        )
        assert "timestamp" in report
        assert "total_cases" in report
        assert report["total_cases"] == 25
        assert "overall_pass_rate" in report
        assert "by_difficulty" in report
        for diff in ("easy", "medium", "hard"):
            assert diff in report["by_difficulty"]
            assert "total" in report["by_difficulty"][diff]
            assert "passed" in report["by_difficulty"][diff]
            assert "rate" in report["by_difficulty"][diff]


# ---------------------------------------------------------------------------
# Summary report builder (shared by test and live eval)
# ---------------------------------------------------------------------------

def _build_summary_report(
    results: list[EvalResult],
    model: str = "mock",
    total_latency_ms: float = 0.0,
) -> dict[str, Any]:
    """Build a JSON-serializable summary report from eval results."""
    total = len(results)
    passed = sum(1 for r in results if r.passed)

    by_diff: dict[str, dict[str, Any]] = {}
    for diff in ("easy", "medium", "hard"):
        subset = [r for r in results if r.difficulty == diff]
        diff_passed = sum(1 for r in subset if r.passed)
        diff_total = len(subset)
        by_diff[diff] = {
            "total": diff_total,
            "passed": diff_passed,
            "rate": diff_passed / diff_total if diff_total else 0,
            "failures": [r.case_id for r in subset if not r.passed],
        }

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model": model,
        "total_cases": total,
        "overall_passed": passed,
        "overall_pass_rate": passed / total if total else 0,
        "total_latency_ms": round(total_latency_ms, 1),
        "avg_latency_ms": round(total_latency_ms / total, 1) if total else 0,
        "by_difficulty": by_diff,
        "case_results": [asdict(r) for r in results],
    }


# =========================================================================
# LIVE EVAL -- manual invocation, calls real LLM
# =========================================================================

async def run_live_eval(
    provider: str | None = None,
    cases: list[EvalCase] | None = None,
) -> dict[str, Any]:
    """
    Run the full benchmark against a real LLM provider.

    Call this function manually (not via pytest) to measure live quality:

        import asyncio
        from tests.test_llm_eval import run_live_eval
        report = asyncio.run(run_live_eval())

    Or from the command line:
        python -m tests.test_llm_eval

    Parameters
    ----------
    provider : str, optional
        Force a specific provider ("claude", "groq", "grok", "gemini").
        If None, uses KFS_PREFERRED_PROVIDER or the fallback chain.
    cases : list[EvalCase], optional
        Subset of cases to run.  Defaults to the full BENCHMARK_DATASET.

    Returns
    -------
    dict
        Summary report, also written to tests/eval_results/eval_<ts>.json.
    """
    # Import here so pytest collection does not fail when app deps missing
    from app.orchestrator.chat_agent import ChatAgent

    agent = ChatAgent()
    if not agent.is_available():
        raise RuntimeError(
            "No LLM API key configured. Set KFS_CLAUDE_API_KEY, KFS_GROQ_API_KEY, "
            "KFS_GROK_API_KEY, or KFS_GEMINI_API_KEY to run live eval."
        )

    eval_cases = cases or BENCHMARK_DATASET
    model_name = agent.active_model()
    results: list[EvalResult] = []
    total_latency = 0.0

    print(f"\n{'='*70}")
    print(f"  KFS LLM Evaluation Benchmark  --  {len(eval_cases)} cases")
    print(f"  Model: {model_name}")
    print(f"{'='*70}\n")

    for i, case in enumerate(eval_cases, 1):
        print(f"  [{i:2d}/{len(eval_cases)}] {case.id} ({case.difficulty})  ", end="", flush=True)

        t0 = time.time()
        try:
            agent_response = await agent.chat(
                user_message=case.prompt,
                conversation_history=[],
                spec=None,
                gate_level="design",
            )
            latency_ms = (time.time() - t0) * 1000.0
            total_latency += latency_ms

            # Reconstruct the full text for analysis:
            # The ChatAgent._parse_response strips structured blocks from .message,
            # so we rebuild a synthetic "full response" from the parsed parts.
            full_response = agent_response.message + "\n"
            if agent_response.components:
                full_response += (
                    "```components\n"
                    + json.dumps(agent_response.components, indent=2)
                    + "\n```\n"
                )
            if agent_response.verification:
                full_response += (
                    "```verification\n"
                    + json.dumps(agent_response.verification, indent=2)
                    + "\n```\n"
                )
            for cb in agent_response.code_blocks:
                lang = cb.get("language", "python")
                code = cb.get("code", "")
                full_response += f"```{lang}\n{code}\n```\n"

            result = analyze_response(case, full_response)
            result.latency_ms = latency_ms
            result.model = agent_response.model_used

        except Exception as exc:
            latency_ms = (time.time() - t0) * 1000.0
            total_latency += latency_ms
            result = EvalResult(
                case_id=case.id,
                difficulty=case.difficulty,
                passed=False,
                keyword_hits={k: False for k in case.expected_keywords},
                component_count=0,
                expected_components=case.expected_components,
                has_components_block=False,
                has_verification_block=False,
                has_code_block=False,
                errors=[f"Exception: {exc}"],
                latency_ms=latency_ms,
                model=model_name,
            )

        results.append(result)
        status = "PASS" if result.passed else "FAIL"
        print(f"{status}  ({latency_ms:.0f}ms)")
        if not result.passed:
            for err in result.errors:
                print(f"         -> {err}")

    await agent.close()

    # Build and save report
    report = _build_summary_report(results, model=model_name, total_latency_ms=total_latency)

    output_dir = Path(__file__).parent / "eval_results"
    output_dir.mkdir(exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = output_dir / f"eval_{ts}.json"
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    # Print summary
    print(f"\n{'='*70}")
    print(f"  RESULTS: {report['overall_passed']}/{report['total_cases']} passed "
          f"({100*report['overall_pass_rate']:.0f}%)")
    print(f"  Avg latency: {report['avg_latency_ms']:.0f}ms")
    for diff in ("easy", "medium", "hard"):
        d = report["by_difficulty"][diff]
        print(f"    {diff:8s}: {d['passed']}/{d['total']} ({100*d['rate']:.0f}%)")
        if d["failures"]:
            print(f"             failures: {d['failures']}")
    print(f"\n  Report saved: {output_path}")
    print(f"{'='*70}\n")

    return report


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import asyncio
    asyncio.run(run_live_eval())
