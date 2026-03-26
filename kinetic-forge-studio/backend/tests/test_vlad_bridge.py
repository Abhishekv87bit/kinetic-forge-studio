"""
Tests for VLAD output parsing (app/services/vlad_bridge.py).

parse_vlad_output(raw_json) -> VladResult
Handles both structured JSON from vlad.py and raw text fallback.
"""
import json
import pytest

from app.services.vlad_bridge import parse_vlad_output
from app.services.vlad_runner import VladResult


# ---------------------------------------------------------------------------
# Structured JSON input
# ---------------------------------------------------------------------------

class TestParseValidJson:
    def test_full_payload(self):
        payload = {
            "tier": "T3",
            "passed": True,
            "checks_run": ["topology", "interference", "clearance"],
            "checks_passed": ["topology", "clearance"],
            "checks_failed": ["interference"],
            "findings": ["Minor interference at joint A"],
        }
        result = parse_vlad_output(json.dumps(payload))

        assert isinstance(result, VladResult)
        assert result.tier == "T3"
        assert result.passed is True
        assert result.checks_run == ["topology", "interference", "clearance"]
        assert result.checks_passed == ["topology", "clearance"]
        assert result.checks_failed == ["interference"]
        assert result.findings == ["Minor interference at joint A"]

    def test_passed_false(self):
        payload = {"tier": "T1", "passed": False, "checks_failed": ["topology"]}
        result = parse_vlad_output(json.dumps(payload))
        assert result.passed is False
        assert result.checks_failed == ["topology"]

    def test_empty_json_object(self):
        """Empty JSON object should produce a VladResult with defaults."""
        result = parse_vlad_output("{}")
        assert isinstance(result, VladResult)
        assert result.passed is False
        assert result.tier == ""
        assert result.checks_run == []

    def test_findings_alias_errors(self):
        """If 'findings' is absent but 'errors' is present, use 'errors'."""
        payload = {"passed": False, "errors": ["bad geometry"]}
        result = parse_vlad_output(json.dumps(payload))
        assert result.findings == ["bad geometry"]

    def test_numeric_tier_coerced_to_str(self):
        payload = {"tier": 2, "passed": True}
        result = parse_vlad_output(json.dumps(payload))
        assert result.tier == "2"

    def test_passed_integer_truthy(self):
        """vlad.py may emit passed as integer 1/0."""
        payload = {"passed": 1}
        result = parse_vlad_output(json.dumps(payload))
        assert result.passed is True

    def test_passed_integer_zero_falsy(self):
        payload = {"passed": 0}
        result = parse_vlad_output(json.dumps(payload))
        assert result.passed is False


# ---------------------------------------------------------------------------
# Plain-text / non-JSON fallback
# ---------------------------------------------------------------------------

class TestParsePlainText:
    def test_plain_text_no_error_keywords(self):
        raw = "All checks passed.\nGeometry is valid."
        result = parse_vlad_output(raw)

        assert isinstance(result, VladResult)
        assert result.passed is True
        assert "All checks passed." in result.findings

    def test_plain_text_with_fail_keyword(self):
        raw = "FAIL: topology check failed\nGeometry invalid."
        result = parse_vlad_output(raw)
        assert result.passed is False

    def test_plain_text_with_error_keyword(self):
        raw = "ERROR running interference check"
        result = parse_vlad_output(raw)
        assert result.passed is False

    def test_plain_text_with_exception_keyword(self):
        raw = "EXCEPTION: AttributeError in vlad.py"
        result = parse_vlad_output(raw)
        assert result.passed is False

    def test_empty_string_fallback(self):
        """Empty output: no findings, passed defaults to True (no error keywords)."""
        result = parse_vlad_output("")
        assert isinstance(result, VladResult)
        assert result.findings == []

    def test_whitespace_only_fallback(self):
        result = parse_vlad_output("   \n  \n  ")
        assert isinstance(result, VladResult)
        assert result.findings == []

    def test_multiline_findings_captured(self):
        raw = "Line one finding\nLine two finding\nLine three finding"
        result = parse_vlad_output(raw)
        assert len(result.findings) == 3

    def test_case_insensitive_fail_detection(self):
        """'fail' in mixed case should still mark as failed."""
        raw = "Fail: some check did not pass"
        result = parse_vlad_output(raw)
        assert result.passed is False


# ---------------------------------------------------------------------------
# VladResult model defaults
# ---------------------------------------------------------------------------

class TestVladResultDefaults:
    def test_default_fields(self):
        r = VladResult()
        assert r.tier == ""
        assert r.passed is False
        assert r.checks_run == []
        assert r.checks_passed == []
        assert r.checks_failed == []
        assert r.findings == []
