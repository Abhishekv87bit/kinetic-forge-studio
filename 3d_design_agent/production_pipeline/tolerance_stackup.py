#!/usr/bin/env python3
"""
Generic Tolerance Stackup Calculator
=====================================
Worst-case, RSS, and Monte Carlo analysis for assembly dimension chains.
Used by Rule 99 Gate 2 (Prototype) and Gate 3 (Production).

Usage:
    # Python API
    from tolerance_stackup import StackupChain, run_stackup

    chain = StackupChain("Shaft through bearing")
    chain.add("Shaft length", nominal=50.0, tol_plus=0.05, tol_minus=0.05)
    chain.add("Bearing width", nominal=7.0, tol_plus=0.01, tol_minus=0.01)
    chain.add("Housing bore depth", nominal=58.0, tol_plus=0.1, tol_minus=0.1, subtract=True)
    chain.set_target(min_val=-0.5, max_val=1.5, label="End play")

    result = run_stackup(chain, monte_carlo=True, n_samples=10000)
    print(result.report())

    # With ISO 286 fit dimensions
    chain.add_iso286("Bearing bore", nominal=25.0, zone="H7")
    chain.add_iso286("Shaft OD", nominal=25.0, zone="g6", subtract=True)

    # CLI
    python tolerance_stackup.py --test
    python tolerance_stackup.py chain.json
"""

import sys
import os
import json
import math
import random

# Import iso286 from same directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from iso286_lookup import iso286_lookup


class Dimension:
    """A single dimension in the stackup chain."""

    def __init__(self, name, nominal, tol_plus, tol_minus, subtract=False, distribution="uniform"):
        """
        Args:
            name: Human-readable name
            nominal: Nominal dimension in mm
            tol_plus: Plus tolerance in mm (positive number)
            tol_minus: Minus tolerance in mm (positive number, will be subtracted)
            subtract: True if this dimension reduces the result (e.g., housing depth)
            distribution: "uniform" or "normal" for Monte Carlo sampling
        """
        self.name = name
        self.nominal = nominal
        self.tol_plus = abs(tol_plus)
        self.tol_minus = abs(tol_minus)
        self.subtract = subtract
        self.distribution = distribution

    @property
    def max_val(self):
        return self.nominal + self.tol_plus

    @property
    def min_val(self):
        return self.nominal - self.tol_minus

    @property
    def bilateral_tol(self):
        """Total tolerance band width."""
        return self.tol_plus + self.tol_minus

    @property
    def mean(self):
        """Mean of the tolerance zone (may differ from nominal if asymmetric)."""
        return self.nominal + (self.tol_plus - self.tol_minus) / 2

    def sample(self, rng=None):
        """Generate a random sample within tolerance."""
        r = rng if rng else random
        if self.distribution == "normal":
            # 3-sigma = half tolerance band, clamp to limits
            sigma = self.bilateral_tol / 6
            val = r.gauss(self.mean, sigma)
            return max(self.min_val, min(self.max_val, val))
        else:
            # Uniform within tolerance band
            return r.uniform(self.min_val, self.max_val)

    def __repr__(self):
        sign = "-" if self.subtract else "+"
        return f"{sign} {self.name}: {self.nominal} +{self.tol_plus}/-{self.tol_minus}"


class StackupChain:
    """A chain of dimensions for tolerance analysis."""

    def __init__(self, name="Untitled chain"):
        self.name = name
        self.dimensions = []
        self.target_min = None
        self.target_max = None
        self.target_label = "Result"

    def add(self, name, nominal, tol_plus, tol_minus=None, subtract=False, distribution="uniform"):
        """Add a dimension to the chain.

        Args:
            name: Dimension name
            nominal: Nominal value in mm
            tol_plus: Plus tolerance in mm
            tol_minus: Minus tolerance in mm (defaults to tol_plus if not given)
            subtract: True if this dimension subtracts from the result
            distribution: "uniform" or "normal"
        """
        if tol_minus is None:
            tol_minus = tol_plus
        self.dimensions.append(Dimension(name, nominal, tol_plus, tol_minus, subtract, distribution))
        return self

    def add_iso286(self, name, nominal, zone, subtract=False, distribution="uniform"):
        """Add a dimension using ISO 286 tolerance zone.

        Args:
            name: Dimension name
            nominal: Nominal diameter in mm
            zone: ISO 286 zone (e.g., "H7", "g6")
            subtract: True if subtracting
            distribution: "uniform" or "normal"
        """
        r = iso286_lookup(nominal, zone)
        # Convert deviations to plus/minus tolerances
        # upper_dev and lower_dev are in microns
        upper_mm = r["upper_dev_um"] / 1000
        lower_mm = r["lower_dev_um"] / 1000

        # Tolerance is relative to nominal
        tol_plus = upper_mm   # how much above nominal
        tol_minus = -lower_mm  # how much below nominal (positive number)

        # Handle cases where both deviations are same sign
        if tol_plus < 0:
            # Both deviations negative (e.g., g6: -7/-20um)
            # Shift nominal down and express as symmetric-ish tolerance
            actual_nominal = nominal + (upper_mm + lower_mm) / 2
            half_band = (upper_mm - lower_mm) / 2
            tol_plus = half_band
            tol_minus = half_band
            self.dimensions.append(Dimension(
                f"{name} [{zone}]", actual_nominal, tol_plus, tol_minus, subtract, distribution
            ))
        elif tol_minus < 0:
            # Both deviations positive (e.g., p6: +22/+35um)
            actual_nominal = nominal + (upper_mm + lower_mm) / 2
            half_band = (upper_mm - lower_mm) / 2
            tol_plus = half_band
            tol_minus = half_band
            self.dimensions.append(Dimension(
                f"{name} [{zone}]", actual_nominal, tol_plus, tol_minus, subtract, distribution
            ))
        else:
            self.dimensions.append(Dimension(
                f"{name} [{zone}]", nominal, tol_plus, tol_minus, subtract, distribution
            ))
        return self

    def set_target(self, min_val=None, max_val=None, label="Result"):
        """Set acceptable range for the stackup result."""
        self.target_min = min_val
        self.target_max = max_val
        self.target_label = label
        return self

    def _compute_nominal(self):
        """Compute nominal result of the chain."""
        total = 0.0
        for d in self.dimensions:
            if d.subtract:
                total -= d.nominal
            else:
                total += d.nominal
        return total


class StackupResult:
    """Results of a tolerance stackup analysis."""

    def __init__(self, chain):
        self.chain = chain
        self.nominal = 0.0
        self.worst_case_min = 0.0
        self.worst_case_max = 0.0
        self.rss_min = 0.0
        self.rss_max = 0.0
        self.monte_carlo_mean = None
        self.monte_carlo_std = None
        self.monte_carlo_min = None
        self.monte_carlo_max = None
        self.monte_carlo_pct_in_spec = None
        self.monte_carlo_n = 0
        self.pass_worst = None
        self.pass_rss = None
        self.pass_mc = None

    def report(self):
        """Generate human-readable consultant-mode report."""
        lines = [
            f"TOLERANCE STACKUP: {self.chain.name}",
            "=" * 55,
            "",
            "Dimensions:",
        ]

        for d in self.chain.dimensions:
            sign = "-" if d.subtract else "+"
            lines.append(
                f"  {sign} {d.name:30s}  {d.nominal:8.3f}  "
                f"+{d.tol_plus:.4f}/-{d.tol_minus:.4f}"
            )

        lines.extend([
            "",
            f"{'-'*55}",
            f"  Nominal {self.chain.target_label}:  {self.nominal:+.4f} mm",
            "",
            f"  WORST CASE:  [{self.worst_case_min:+.4f}, {self.worst_case_max:+.4f}] mm",
            f"  RSS (3-sigma): [{self.rss_min:+.4f}, {self.rss_max:+.4f}] mm",
        ])

        if self.monte_carlo_mean is not None:
            lines.extend([
                f"  MONTE CARLO ({self.monte_carlo_n:,d} samples):",
                f"    Mean:  {self.monte_carlo_mean:+.4f} mm",
                f"    Std:   {self.monte_carlo_std:.4f} mm",
                f"    Range: [{self.monte_carlo_min:+.4f}, {self.monte_carlo_max:+.4f}] mm",
            ])
            if self.monte_carlo_pct_in_spec is not None:
                lines.append(f"    In spec: {self.monte_carlo_pct_in_spec:.1f}%")

        # Target evaluation
        if self.chain.target_min is not None or self.chain.target_max is not None:
            tgt = ""
            if self.chain.target_min is not None:
                tgt += f"{self.chain.target_min:+.4f}"
            else:
                tgt += "-inf"
            tgt += " .. "
            if self.chain.target_max is not None:
                tgt += f"{self.chain.target_max:+.4f}"
            else:
                tgt += "+inf"

            lines.extend([
                "",
                f"  Target {self.chain.target_label}: {tgt} mm",
            ])

            if self.pass_worst is not None:
                status = "PASS" if self.pass_worst else "FAIL"
                lines.append(f"  Worst case: {status}")
            if self.pass_rss is not None:
                status = "PASS" if self.pass_rss else "FAIL"
                lines.append(f"  RSS (3-sigma): {status}")
            if self.pass_mc is not None:
                status = "PASS" if self.pass_mc else "FAIL"
                lines.append(f"  Monte Carlo: {status} ({self.monte_carlo_pct_in_spec:.1f}% in spec)")

        # Consultant recommendation
        lines.append("")
        if self.pass_worst:
            lines.append("VERDICT: All assemblies will be within spec. No changes needed.")
        elif self.pass_rss:
            lines.append("VERDICT: RSS passes but worst-case fails. ~99.7% of assemblies OK.")
            lines.append("  Accept if selective assembly is feasible, otherwise tighten tolerances.")
        elif self.pass_mc is not None and self.monte_carlo_pct_in_spec > 95:
            lines.append(f"VERDICT: {self.monte_carlo_pct_in_spec:.1f}% in spec. Acceptable for prototype,")
            lines.append("  but tighten tolerances for production.")
        else:
            lines.append("VERDICT: FAIL. Tolerances too loose for target. Tighten critical dimensions")
            lines.append("  or increase the allowable range.")

        return "\n".join(lines)


def run_stackup(chain, monte_carlo=False, n_samples=10000, seed=42):
    """
    Run tolerance stackup analysis on a dimension chain.

    Args:
        chain: StackupChain object
        monte_carlo: If True, run Monte Carlo simulation
        n_samples: Number of Monte Carlo samples
        seed: Random seed for reproducibility

    Returns:
        StackupResult object
    """
    result = StackupResult(chain)

    # Nominal
    nominal = 0.0
    for d in chain.dimensions:
        if d.subtract:
            nominal -= d.nominal
        else:
            nominal += d.nominal
    result.nominal = nominal

    # Worst case: accumulate all tolerances in the worst direction
    wc_plus = 0.0  # maximum positive deviation
    wc_minus = 0.0  # maximum negative deviation
    rss_plus_sq = 0.0
    rss_minus_sq = 0.0

    for d in chain.dimensions:
        if d.subtract:
            # Subtracting: larger dimension = smaller result, smaller dimension = larger result
            wc_plus += d.tol_minus   # smallest subtracted value = most positive result
            wc_minus += d.tol_plus   # largest subtracted value = most negative result
            rss_plus_sq += d.tol_minus ** 2
            rss_minus_sq += d.tol_plus ** 2
        else:
            # Adding: larger dimension = larger result
            wc_plus += d.tol_plus
            wc_minus += d.tol_minus
            rss_plus_sq += d.tol_plus ** 2
            rss_minus_sq += d.tol_minus ** 2

    result.worst_case_max = nominal + wc_plus
    result.worst_case_min = nominal - wc_minus
    result.rss_max = nominal + math.sqrt(rss_plus_sq)
    result.rss_min = nominal - math.sqrt(rss_minus_sq)

    # Monte Carlo
    if monte_carlo:
        rng = random.Random(seed)
        samples = []
        for _ in range(n_samples):
            total = 0.0
            for d in chain.dimensions:
                val = d.sample(rng)
                if d.subtract:
                    total -= val
                else:
                    total += val
            samples.append(total)

        result.monte_carlo_n = n_samples
        result.monte_carlo_mean = sum(samples) / len(samples)
        variance = sum((s - result.monte_carlo_mean) ** 2 for s in samples) / len(samples)
        result.monte_carlo_std = math.sqrt(variance)
        result.monte_carlo_min = min(samples)
        result.monte_carlo_max = max(samples)

        # Check against target
        if chain.target_min is not None or chain.target_max is not None:
            in_spec = 0
            for s in samples:
                lo_ok = chain.target_min is None or s >= chain.target_min
                hi_ok = chain.target_max is None or s <= chain.target_max
                if lo_ok and hi_ok:
                    in_spec += 1
            result.monte_carlo_pct_in_spec = 100 * in_spec / n_samples

    # Pass/fail against target
    if chain.target_min is not None or chain.target_max is not None:
        lo = chain.target_min if chain.target_min is not None else float("-inf")
        hi = chain.target_max if chain.target_max is not None else float("inf")

        result.pass_worst = (result.worst_case_min >= lo and result.worst_case_max <= hi)
        result.pass_rss = (result.rss_min >= lo and result.rss_max <= hi)
        if result.monte_carlo_pct_in_spec is not None:
            result.pass_mc = result.monte_carlo_pct_in_spec >= 99.7  # 3-sigma equivalent

    return result


def from_json(json_path):
    """Load a stackup chain from a JSON file.

    JSON format:
    {
        "name": "Shaft end play",
        "target": {"min": -0.5, "max": 1.5, "label": "End play"},
        "dimensions": [
            {"name": "Shaft length", "nominal": 50.0, "tol_plus": 0.05, "tol_minus": 0.05},
            {"name": "Bearing width", "nominal": 7.0, "tol_plus": 0.01, "tol_minus": 0.01},
            {"name": "Housing depth", "nominal": 58.0, "tol_plus": 0.1, "tol_minus": 0.1, "subtract": true},
            {"name": "Bore", "nominal": 25.0, "iso286_zone": "H7"},
            {"name": "Shaft OD", "nominal": 25.0, "iso286_zone": "g6", "subtract": true}
        ]
    }
    """
    with open(json_path) as f:
        data = json.load(f)

    chain = StackupChain(data.get("name", "Loaded chain"))

    for dim in data["dimensions"]:
        subtract = dim.get("subtract", False)
        dist = dim.get("distribution", "uniform")

        if "iso286_zone" in dim:
            chain.add_iso286(dim["name"], dim["nominal"], dim["iso286_zone"],
                             subtract=subtract, distribution=dist)
        else:
            tol_minus = dim.get("tol_minus", dim["tol_plus"])
            chain.add(dim["name"], dim["nominal"], dim["tol_plus"], tol_minus,
                      subtract=subtract, distribution=dist)

    if "target" in data:
        t = data["target"]
        chain.set_target(
            min_val=t.get("min"),
            max_val=t.get("max"),
            label=t.get("label", "Result"),
        )

    return chain


# --- Self-Test ---
def _run_tests():
    """Verify stackup calculations against hand-computed values."""
    passed = 0
    failed = 0

    def check(desc, actual, expected, tol=0.01):
        nonlocal passed, failed
        if abs(actual - expected) <= tol:
            passed += 1
            print(f"  PASS: {desc} = {actual:.4f} (expected {expected:.4f})")
        else:
            failed += 1
            print(f"  FAIL: {desc} = {actual:.4f} (expected {expected:.4f})")

    print("Tolerance Stackup Self-Test")
    print("=" * 55)

    # Test 1: Simple 3-link chain
    # Shaft 50 +/-0.05, Bearing 7 +/-0.01, Housing 58 +/-0.1 (subtract)
    # Nominal gap = 50 + 7 - 58 = -1.0 mm
    # WC max = -1 + 0.05 + 0.01 + 0.1 = -0.84
    # WC min = -1 - 0.05 - 0.01 - 0.1 = -1.16
    print("\nTest 1: 3-link shaft end play")
    chain = StackupChain("Shaft end play")
    chain.add("Shaft length", 50.0, 0.05)
    chain.add("Bearing width", 7.0, 0.01)
    chain.add("Housing depth", 58.0, 0.1, subtract=True)
    chain.set_target(min_val=-1.5, max_val=0.0, label="End play")

    r = run_stackup(chain, monte_carlo=True, n_samples=10000)
    check("nominal", r.nominal, -1.0)
    check("wc_max", r.worst_case_max, -0.84)
    check("wc_min", r.worst_case_min, -1.16)
    # RSS: sqrt(0.05^2 + 0.01^2 + 0.1^2) = sqrt(0.0126) = 0.1122
    check("rss_max", r.rss_max, -1.0 + 0.1122, tol=0.005)
    check("rss_min", r.rss_min, -1.0 - 0.1122, tol=0.005)
    assert r.pass_worst, "Should pass worst-case"
    passed += 1
    print("  PASS: worst-case passes target")

    # Test 2: ISO 286 bearing fit
    print("\nTest 2: ISO 286 bearing clearance (H7/g6 at 25mm)")
    chain2 = StackupChain("Bearing clearance")
    chain2.add_iso286("Bore", 25.0, "H7")
    chain2.add_iso286("Shaft", 25.0, "g6", subtract=True)
    chain2.set_target(min_val=0.005, max_val=0.050, label="Clearance")

    r2 = run_stackup(chain2, monte_carlo=True, n_samples=10000)
    # H7 at 25mm: 25.000 .. 25.021
    # g6 at 25mm: 24.980 .. 24.993
    # Min clearance = 25.000 - 24.993 = 0.007
    # Max clearance = 25.021 - 24.980 = 0.041
    print(f"  INFO: nominal={r2.nominal:.4f}, wc=[{r2.worst_case_min:.4f}, {r2.worst_case_max:.4f}]")
    check("wc_min (min clearance)", r2.worst_case_min, 0.007, tol=0.002)
    check("wc_max (max clearance)", r2.worst_case_max, 0.041, tol=0.002)
    assert r2.pass_worst, "H7/g6 should pass 5-50um target"
    passed += 1
    print("  PASS: H7/g6 clearance within target")

    # Test 3: Failing chain
    print("\nTest 3: Tight target (should fail)")
    chain3 = StackupChain("Tight gap")
    chain3.add("Part A", 10.0, 0.5)
    chain3.add("Part B", 10.0, 0.5, subtract=True)
    chain3.set_target(min_val=-0.1, max_val=0.1, label="Gap")

    r3 = run_stackup(chain3, monte_carlo=True)
    assert not r3.pass_worst, "Should fail worst-case"
    passed += 1
    print(f"  PASS: worst-case correctly fails (wc=[{r3.worst_case_min:.3f}, {r3.worst_case_max:.3f}])")

    # Test 4: Asymmetric tolerances
    print("\nTest 4: Asymmetric tolerances")
    chain4 = StackupChain("Asymmetric")
    chain4.add("Dim A", 20.0, tol_plus=0.1, tol_minus=0.05)
    chain4.add("Dim B", 30.0, tol_plus=0.02, tol_minus=0.08)
    chain4.add("Slot", 50.5, tol_plus=0.2, tol_minus=0.1, subtract=True)
    # Nominal = 20 + 30 - 50.5 = -0.5
    # WC max = -0.5 + 0.1 + 0.02 + 0.1 = -0.28
    # WC min = -0.5 - 0.05 - 0.08 - 0.2 = -0.83
    r4 = run_stackup(chain4)
    check("nominal", r4.nominal, -0.5)
    check("wc_max", r4.worst_case_max, -0.28)
    check("wc_min", r4.worst_case_min, -0.83)

    # Test 5: Report generation
    print("\nTest 5: Full report")
    print(r.report())
    passed += 1
    print("  PASS: Report generated")

    print(f"\n{'='*55}")
    print(f"Results: {passed} passed, {failed} failed")
    return failed == 0


if __name__ == "__main__":
    if "--test" in sys.argv:
        success = _run_tests()
        sys.exit(0 if success else 1)
    elif len(sys.argv) >= 2 and sys.argv[1].endswith(".json"):
        chain = from_json(sys.argv[1])
        mc = "--mc" in sys.argv or "--monte-carlo" in sys.argv
        n = 10000
        for arg in sys.argv:
            if arg.startswith("--n="):
                n = int(arg[4:])
        result = run_stackup(chain, monte_carlo=mc, n_samples=n)
        print(result.report())
    else:
        print("Usage:")
        print("  python tolerance_stackup.py --test")
        print("  python tolerance_stackup.py chain.json [--mc] [--n=10000]")
