"""Tests for SC-03: VladBridge and VladRunner.

Covers:
  - VladBridge generates syntactically valid Python bridge module
  - VladRunner.run() with subprocess mocked to return sample JSON
  - VladRunner.get_latest() reads most-recent row from vlad_results
  - VladRunner.get_history() returns ordered history with limit
"""
from __future__ import annotations

import ast
import json
import subprocess
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from backend.app.services.vlad_bridge import VladBridge
from backend.app.services.vlad_runner import VladCheck, VladResult, VladRunner


# ---------------------------------------------------------------------------
# Shared sample JSON (mirrors vlad.py --json output schema)
# ---------------------------------------------------------------------------

_SAMPLE_PASS_JSON = json.dumps({
    "module": "test_gear",
    "mechanism_type": "slider",
    "fixed_parts": 2,
    "moving_parts": 1,
    "verdict": "PASS",
    "counts": {"pass": 5, "fail": 0, "warn": 1, "info": 2},
    "checks": [
        {"id": "topology_check", "status": "PASS", "detail": "manifold"},
        {"id": "clearance_check", "status": "WARN", "detail": "tight fit"},
    ],
})

_SAMPLE_FAIL_JSON = json.dumps({
    "module": "test_gear",
    "mechanism_type": "gear",
    "fixed_parts": 1,
    "moving_parts": 0,
    "verdict": "FAIL",
    "counts": {"pass": 2, "fail": 3, "warn": 0, "info": 1},
    "checks": [
        {"id": "interference_check", "status": "FAIL", "detail": "overlap 0.5mm"},
    ],
})


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture()
def db_path(tmp_path) -> str:
    return str(tmp_path / "vlad_test.db")


@pytest.fixture()
def runner(db_path) -> VladRunner:
    return VladRunner(db_path=db_path, vlad_script_path="/fake/vlad.py", timeout=30)


# ---------------------------------------------------------------------------
# VladBridge — syntactic validity
# ---------------------------------------------------------------------------

class TestVladBridge:
    def test_write_bridge_creates_file(self, tmp_path):
        bridge = VladBridge("result = None", mechanism_type="slider")
        path = bridge.write_bridge(dest_dir=tmp_path)
        assert path.exists()

    def test_bridge_is_syntactically_valid_python(self, tmp_path):
        """The generated bridge file must parse without SyntaxError."""
        module_code = "import cadquery as cq\nresult = cq.Workplane('XY').box(1,1,1)"
        bridge = VladBridge(module_code, mechanism_type="rotary")
        path = bridge.write_bridge(dest_dir=tmp_path)
        source = path.read_text(encoding="utf-8")
        # ast.parse raises SyntaxError if invalid — no assertion needed beyond no-raise
        ast.parse(source)

    def test_bridge_contains_original_code(self, tmp_path):
        module_code = "MY_SENTINEL = 42"
        bridge = VladBridge(module_code, mechanism_type="slider")
        path = bridge.write_bridge(dest_dir=tmp_path)
        assert "MY_SENTINEL = 42" in path.read_text(encoding="utf-8")

    def test_bridge_contains_vlad_stubs(self, tmp_path):
        bridge = VladBridge("x = 1", mechanism_type="slider")
        path = bridge.write_bridge(dest_dir=tmp_path)
        content = path.read_text(encoding="utf-8")
        assert "get_fixed_parts" in content
        assert "get_moving_parts" in content
        assert "get_mechanism_type" in content

    def test_mechanism_type_embedded_in_bridge(self, tmp_path):
        bridge = VladBridge("x = 1", mechanism_type="cam_follower")
        path = bridge.write_bridge(dest_dir=tmp_path)
        assert "cam_follower" in path.read_text(encoding="utf-8")

    def test_bridge_filename_is_unique(self, tmp_path):
        b1 = VladBridge("x = 1")
        b2 = VladBridge("x = 1")
        p1 = b1.write_bridge(dest_dir=tmp_path)
        p2 = b2.write_bridge(dest_dir=tmp_path)
        assert p1.name != p2.name

    def test_cleanup_removes_tmpdir(self):
        bridge = VladBridge("x = 1")
        path = bridge.write_bridge()  # auto-creates tmpdir
        tmpdir = bridge._tmpdir
        assert Path(tmpdir).exists()
        bridge.cleanup()
        assert not Path(tmpdir).exists()

    def test_context_manager_cleans_up(self):
        with VladBridge("x = 1") as bridge:
            path = bridge.write_bridge()
            tmpdir = bridge._tmpdir
        assert not Path(tmpdir).exists()

    def test_explicit_dest_dir_not_removed_on_cleanup(self, tmp_path):
        bridge = VladBridge("x = 1")
        bridge.write_bridge(dest_dir=tmp_path)
        bridge.cleanup()
        # Explicit dest_dir is not the tmpdir — cleanup should not remove it
        assert tmp_path.exists()


# ---------------------------------------------------------------------------
# VladRunner.run() — subprocess mocked
# ---------------------------------------------------------------------------

class TestVladRunnerRun:
    def _make_mock_proc(self, stdout: str, returncode: int = 0) -> MagicMock:
        proc = MagicMock()
        proc.stdout = stdout
        proc.stderr = ""
        proc.returncode = returncode
        return proc

    def test_run_returns_vlad_result(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-001", str(bridge_file))
        assert isinstance(result, VladResult)

    def test_run_pass_verdict_sets_passed_true(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-001", str(bridge_file))
        assert result.passed is True
        assert result.verdict == "PASS"

    def test_run_fail_verdict_sets_passed_false(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_FAIL_JSON, returncode=1)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-002", str(bridge_file))
        assert result.passed is False
        assert result.verdict == "FAIL"

    def test_run_parses_counts(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-001", str(bridge_file))
        assert result.pass_count == 5
        assert result.fail_count == 0
        assert result.warn_count == 1
        assert result.info_count == 2

    def test_run_parses_parts(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-001", str(bridge_file))
        assert result.fixed_parts == 2
        assert result.moving_parts == 1

    def test_run_parses_checks(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-001", str(bridge_file))
        assert len(result.checks) == 2
        assert result.checks[0].check_id == "topology_check"
        assert result.checks[1].status == "WARN"

    def test_run_stores_module_id(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-xyz", str(bridge_file))
        assert result.module_id == "mod-xyz"

    def test_run_assigns_db_row_id(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc(_SAMPLE_PASS_JSON)
        with patch("subprocess.run", return_value=mock_proc):
            result = runner.run("mod-001", str(bridge_file))
        assert result.db_row_id is not None
        assert result.db_row_id >= 1

    def test_run_exit_2_raises_value_error(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc("", returncode=2)
        mock_proc.stderr = "import failed"
        with patch("subprocess.run", return_value=mock_proc):
            with pytest.raises(ValueError, match="exit 2"):
                runner.run("mod-001", str(bridge_file))

    def test_run_empty_output_raises_value_error(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc("", returncode=0)
        with patch("subprocess.run", return_value=mock_proc):
            with pytest.raises(ValueError, match="no JSON output"):
                runner.run("mod-001", str(bridge_file))

    def test_run_non_json_output_raises_value_error(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = self._make_mock_proc("not json at all", returncode=0)
        with patch("subprocess.run", return_value=mock_proc):
            with pytest.raises(ValueError, match="not valid JSON"):
                runner.run("mod-001", str(bridge_file))

    def test_run_timeout_raises_timeout_expired(self, runner, tmp_path):
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        with patch("subprocess.run", side_effect=subprocess.TimeoutExpired([], 30)):
            with pytest.raises(subprocess.TimeoutExpired):
                runner.run("mod-001", str(bridge_file))


# ---------------------------------------------------------------------------
# VladRunner.get_latest() and get_history() — DB reads
# ---------------------------------------------------------------------------

class TestVladRunnerDB:
    def _insert_result(self, runner: VladRunner, module_id: str, verdict: str) -> VladResult:
        """Helper: store a result directly via _store to avoid subprocess."""
        from datetime import datetime, timezone
        result = VladResult(
            module_id=module_id,
            mechanism_type="slider",
            verdict=verdict,
            passed=(verdict == "PASS"),
            fail_count=0 if verdict == "PASS" else 2,
            warn_count=0,
            pass_count=3,
            info_count=1,
            fixed_parts=1,
            moving_parts=1,
            checks=[VladCheck("t1", verdict, "ok")],
            raw_json='{"verdict":"' + verdict + '"}',
            run_at=datetime.now(timezone.utc),
        )
        result.db_row_id = runner._store(result)
        return result

    def test_get_latest_returns_none_when_no_results(self, runner):
        assert runner.get_latest("nonexistent-module") is None

    def test_get_latest_returns_vlad_result(self, runner):
        self._insert_result(runner, "mod-A", "PASS")
        result = runner.get_latest("mod-A")
        assert isinstance(result, VladResult)

    def test_get_latest_returns_correct_module_id(self, runner):
        self._insert_result(runner, "mod-A", "PASS")
        result = runner.get_latest("mod-A")
        assert result.module_id == "mod-A"

    def test_get_latest_returns_most_recent(self, runner):
        """Insert two rows; get_latest must return the second (FAIL)."""
        self._insert_result(runner, "mod-B", "PASS")
        self._insert_result(runner, "mod-B", "FAIL")
        result = runner.get_latest("mod-B")
        assert result.verdict == "FAIL"

    def test_get_latest_ignores_other_modules(self, runner):
        self._insert_result(runner, "mod-A", "PASS")
        self._insert_result(runner, "mod-B", "FAIL")
        result = runner.get_latest("mod-A")
        assert result.verdict == "PASS"

    def test_get_latest_has_db_row_id(self, runner):
        self._insert_result(runner, "mod-C", "PASS")
        result = runner.get_latest("mod-C")
        assert result.db_row_id is not None

    def test_get_history_empty_list_when_none(self, runner):
        assert runner.get_history("mod-ghost") == []

    def test_get_history_returns_all_results(self, runner):
        self._insert_result(runner, "mod-D", "PASS")
        self._insert_result(runner, "mod-D", "FAIL")
        self._insert_result(runner, "mod-D", "PASS")
        history = runner.get_history("mod-D")
        assert len(history) == 3

    def test_get_history_ordered_most_recent_first(self, runner):
        """Results must come back newest-first (ORDER BY run_at DESC)."""
        r1 = self._insert_result(runner, "mod-E", "PASS")
        r2 = self._insert_result(runner, "mod-E", "FAIL")
        history = runner.get_history("mod-E")
        # The last-inserted row has a newer run_at
        assert history[0].db_row_id == r2.db_row_id

    def test_get_history_respects_limit(self, runner):
        for _ in range(5):
            self._insert_result(runner, "mod-F", "PASS")
        history = runner.get_history("mod-F", limit=3)
        assert len(history) == 3

    def test_get_history_only_returns_matching_module(self, runner):
        self._insert_result(runner, "mod-G", "PASS")
        self._insert_result(runner, "mod-H", "FAIL")
        history = runner.get_history("mod-G")
        assert all(r.module_id == "mod-G" for r in history)

    def test_get_history_reconstructs_checks(self, runner):
        self._insert_result(runner, "mod-I", "PASS")
        history = runner.get_history("mod-I")
        assert len(history[0].checks) == 1
        assert history[0].checks[0].check_id == "t1"

    def test_run_result_readable_via_get_latest(self, runner, tmp_path):
        """End-to-end: run() stores a result that get_latest() can retrieve."""
        bridge_file = tmp_path / "bridge.py"
        bridge_file.write_text("x = 1")
        mock_proc = MagicMock()
        mock_proc.stdout = _SAMPLE_PASS_JSON
        mock_proc.stderr = ""
        mock_proc.returncode = 0
        with patch("subprocess.run", return_value=mock_proc):
            stored = runner.run("mod-E2E", str(bridge_file))
        retrieved = runner.get_latest("mod-E2E")
        assert retrieved is not None
        assert retrieved.verdict == stored.verdict
        assert retrieved.db_row_id == stored.db_row_id
