"""SC-09 Integration Pipeline Tests.

Exercises two end-to-end scenarios without requiring external tools:

Happy path
    ModuleManager.create() → ModuleExecutor.execute() (mock engine) →
    status update in DB → VladRunner result stored → ManifestGenerator writes
    .kfs.yaml (kfs_core mocked via patch.dict).

Durga repair path
    Inject CadQuery code that triggers a deterministic Durga rule
    (NameError: name 'cq' is not defined → missing_cq_import rule) →
    assert DurgaRepairEngine fires at tier=deterministic →
    assert re-execution succeeds (mock engine passes on second call).

Tests that need a real CadQuery installation are marked
@pytest.mark.requires_cadquery and skipped automatically in CI.
"""
from __future__ import annotations

import json
import os
from unittest.mock import MagicMock, patch

import pytest

from backend.app.models.module import ModuleManager
from backend.app.services.durga import DurgaRepairEngine
from backend.app.services.module_executor import ExecutionResult, ModuleExecutor
from backend.app.services.vlad_runner import VladCheck, VladResult


# ---------------------------------------------------------------------------
# Local fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def db_path(tmp_path):
    """Isolated SQLite DB file for each integration test."""
    return str(tmp_path / "integration.db")


@pytest.fixture()
def output_dir(tmp_path):
    """Temporary output directory for STL/STEP artefacts."""
    d = tmp_path / "models"
    d.mkdir()
    return str(d)


@pytest.fixture()
def module_manager(db_path):
    """ModuleManager backed by the isolated test DB."""
    return ModuleManager(db_path=db_path)


@pytest.fixture()
def executor(output_dir, cadquery_mock_engine):
    """ModuleExecutor wired to the shared mock engine from conftest."""
    return ModuleExecutor(output_dir=output_dir, engine=cadquery_mock_engine)


@pytest.fixture()
def fake_vlad_pass():
    """A pre-built passing VladResult to substitute for a real VLAD run."""
    raw = json.dumps({
        "verdict": "PASS",
        "mechanism_type": "generic",
        "fixed_parts": 1,
        "moving_parts": 0,
        "counts": {"pass": 5, "fail": 0, "warn": 0, "info": 1},
        "checks": [{"id": "T001", "status": "PASS", "detail": "topology ok"}],
    })
    return VladResult(
        module_id="",  # caller sets this
        mechanism_type="generic",
        verdict="PASS",
        passed=True,
        fail_count=0,
        warn_count=0,
        pass_count=5,
        info_count=1,
        fixed_parts=1,
        moving_parts=0,
        checks=[VladCheck(check_id="T001", status="PASS", detail="topology ok")],
        raw_json=raw,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_GOOD_CODE = "import cadquery as cq\nresult = cq.Workplane('XY').box(10, 10, 5)\n"
_BAD_CODE_NO_CQ = "result = cq.Workplane('XY').box(5, 5, 5)\n"  # triggers missing_cq_import


def _kfs_core_patch():
    """Return a patch.dict context that mocks all kfs_core submodules."""
    mock_manifest_instance = MagicMock()
    mock_save = MagicMock()
    mock_kfs_manifest_cls = MagicMock(return_value=mock_manifest_instance)
    mock_kfs_object_cls = MagicMock(return_value=MagicMock())

    modules = {
        "kfs_core": MagicMock(),
        "kfs_core.manifest_models": MagicMock(
            KFSManifest=mock_kfs_manifest_cls,
            KFSObject=mock_kfs_object_cls,
            MeshGeometry=MagicMock(return_value=MagicMock()),
            Transform=MagicMock(return_value=MagicMock()),
        ),
        "kfs_core.manifest_parser": MagicMock(save_kfs_manifest=mock_save),
    }
    return patch.dict("sys.modules", modules), mock_kfs_manifest_cls, mock_kfs_object_cls, mock_save


# ---------------------------------------------------------------------------
# Happy path — full pipeline
# ---------------------------------------------------------------------------


class TestFullHappyPath:
    """Full pipeline: create → execute → status update → VLAD verdict → manifest."""

    @pytest.mark.asyncio
    async def test_create_module_persists_in_db(self, module_manager):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        fetched = module_manager.get(mod.id)
        assert fetched is not None
        assert fetched.name == "spur_gear"

    @pytest.mark.asyncio
    async def test_create_module_initial_status_is_draft(self, module_manager):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        assert mod.status == "draft"

    @pytest.mark.asyncio
    async def test_execute_returns_valid_status(self, module_manager, executor):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        result = await executor.execute(mod.id, mod.code)
        assert result.status == "valid"

    @pytest.mark.asyncio
    async def test_execute_writes_stl_file(self, module_manager, executor):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        result = await executor.execute(mod.id, mod.code)
        assert result.stl_path is not None
        assert os.path.isfile(result.stl_path)

    @pytest.mark.asyncio
    async def test_execute_writes_step_file(self, module_manager, executor):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        result = await executor.execute(mod.id, mod.code)
        assert result.step_path is not None
        assert os.path.isfile(result.step_path)

    @pytest.mark.asyncio
    async def test_execute_result_module_id_matches(self, module_manager, executor):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        result = await executor.execute(mod.id, mod.code)
        assert result.module_id == mod.id

    @pytest.mark.asyncio
    async def test_status_updated_to_valid_after_execution(self, module_manager, executor):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        result = await executor.execute(mod.id, mod.code)
        assert result.status == "valid"
        # Route layer updates status — replicate that here
        module_manager.update_status(mod.id, "valid")
        updated = module_manager.get(mod.id)
        assert updated.status == "valid"

    @pytest.mark.asyncio
    async def test_vlad_verdict_stored_in_db(self, module_manager, executor, fake_vlad_pass):
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        await executor.execute(mod.id, mod.code)
        module_manager.update_status(mod.id, "valid")

        fake_vlad_pass.module_id = mod.id
        module_manager.update_vlad_verdict(mod.id, {
            "verdict": fake_vlad_pass.verdict,
            "passed": fake_vlad_pass.passed,
            "fail_count": fake_vlad_pass.fail_count,
        })

        updated = module_manager.get(mod.id)
        assert updated.vlad_verdict is not None
        assert updated.vlad_verdict["verdict"] == "PASS"
        assert updated.vlad_verdict["passed"] is True

    @pytest.mark.asyncio
    async def test_manifest_generate_called_with_valid_module(
        self, module_manager, executor, tmp_path
    ):
        """ManifestGenerator.generate() must call save_kfs_manifest exactly once."""
        mod = module_manager.create(name="spur_gear", code=_GOOD_CODE)
        await executor.execute(mod.id, mod.code)
        module_manager.update_status(mod.id, "valid")

        ctx, mock_kfs_manifest_cls, _, mock_save = _kfs_core_patch()
        with ctx:
            from backend.app.services.manifest_generator import ManifestGenerator  # noqa: PLC0415
            gen = ManifestGenerator(
                module_manager=module_manager,
                output_dir=executor.output_dir,
            )
            manifest_path = str(tmp_path / "output.kfs.yaml")
            gen.generate(manifest_path=manifest_path, project_name="Test Project")

        mock_save.assert_called_once()

    @pytest.mark.asyncio
    async def test_manifest_excludes_draft_modules(self, module_manager, executor, tmp_path):
        """Modules in 'draft' status must not appear in the manifest objects list."""
        valid_mod = module_manager.create(name="valid_gear", code=_GOOD_CODE)
        _draft_mod = module_manager.create(name="draft_gear", code=_GOOD_CODE)

        await executor.execute(valid_mod.id, valid_mod.code)
        module_manager.update_status(valid_mod.id, "valid")
        # draft_mod intentionally left at "draft"

        captured: dict = {}

        def _capture_manifest(**kwargs):
            captured.update(kwargs)
            return MagicMock()

        mock_kfs_manifest_cls = MagicMock(side_effect=_capture_manifest)
        patch_ctx = patch.dict("sys.modules", {
            "kfs_core": MagicMock(),
            "kfs_core.manifest_models": MagicMock(
                KFSManifest=mock_kfs_manifest_cls,
                KFSObject=MagicMock(return_value=MagicMock()),
                MeshGeometry=MagicMock(return_value=MagicMock()),
                Transform=MagicMock(return_value=MagicMock()),
            ),
            "kfs_core.manifest_parser": MagicMock(save_kfs_manifest=MagicMock()),
        })

        with patch_ctx:
            from backend.app.services.manifest_generator import ManifestGenerator  # noqa: PLC0415
            gen = ManifestGenerator(
                module_manager=module_manager,
                output_dir=executor.output_dir,
            )
            gen.generate(
                manifest_path=str(tmp_path / "out.kfs.yaml"),
                project_name="Filter Test",
            )

        assert "objects" in captured, "KFSManifest must be called with an 'objects' kwarg"
        assert len(captured["objects"]) == 1, (
            f"Expected 1 object (only valid_gear), got {len(captured['objects'])}"
        )


# ---------------------------------------------------------------------------
# Durga repair path
# ---------------------------------------------------------------------------


class TestDurgaRepairPath:
    """Deterministic repair fires on bad code and re-execution succeeds."""

    @pytest.mark.asyncio
    async def test_deterministic_rule_matches_missing_cq_import(self):
        """DurgaRepairEngine must identify the 'missing_cq_import' rule."""
        engine = DurgaRepairEngine(chat_agent=None)
        error = "NameError: name 'cq' is not defined"
        result = await engine.attempt_repair(_BAD_CODE_NO_CQ, error)

        assert result.success is True
        assert result.tier_used == "deterministic"
        assert result.rule_name == "missing_cq_import"

    @pytest.mark.asyncio
    async def test_repair_prepends_cadquery_import(self):
        """Fixed code from the missing_cq_import rule must include the import line."""
        engine = DurgaRepairEngine(chat_agent=None)
        error = "NameError: name 'cq' is not defined"
        result = await engine.attempt_repair(_BAD_CODE_NO_CQ, error)

        assert result.fixed_code is not None
        assert "import cadquery as cq" in result.fixed_code

    @pytest.mark.asyncio
    async def test_repair_does_not_duplicate_import_if_already_present(self):
        """If code already has the import, the rule must not add it twice."""
        engine = DurgaRepairEngine(chat_agent=None)
        code_with_import = "import cadquery as cq\n" + _BAD_CODE_NO_CQ
        error = "NameError: name 'cq' is not defined"
        result = await engine.attempt_repair(code_with_import, error)

        if result.success:
            assert result.fixed_code.count("import cadquery as cq") == 1

    @pytest.mark.asyncio
    async def test_executor_re_executes_after_repair(self, output_dir):
        """After a deterministic repair the executor must retry and return status=valid."""
        first_done = [False]

        def _run_code(code, *, stl_path, step_path):
            if not first_done[0]:
                first_done[0] = True
                raise RuntimeError("NameError: name 'cq' is not defined")
            # Second call (repaired code) succeeds
            os.makedirs(os.path.dirname(stl_path), exist_ok=True)
            with open(stl_path, "wb") as f:
                f.write(b"solid repaired\nendsolid\n")
            with open(step_path, "wb") as f:
                f.write(b"ISO-10303-21; repaired")

        mock_engine = MagicMock()
        mock_engine.run_code.side_effect = _run_code
        ex = ModuleExecutor(output_dir=output_dir, engine=mock_engine)

        result = await ex.execute("repair_test", _BAD_CODE_NO_CQ)
        assert result.status == "valid", (
            f"Expected status=valid after repair, got status={result.status!r} "
            f"error={result.error!r}"
        )

    @pytest.mark.asyncio
    async def test_engine_called_twice_on_repair(self, output_dir):
        """The mock engine must be invoked twice: once for failure, once for retry."""
        first_done = [False]

        def _run_code(code, *, stl_path, step_path):
            if not first_done[0]:
                first_done[0] = True
                raise RuntimeError("NameError: name 'cq' is not defined")
            os.makedirs(os.path.dirname(stl_path), exist_ok=True)
            with open(stl_path, "wb") as f:
                f.write(b"solid mock\nendsolid\n")
            with open(step_path, "wb") as f:
                f.write(b"ISO-10303-21; mock")

        mock_engine = MagicMock()
        mock_engine.run_code.side_effect = _run_code
        ex = ModuleExecutor(output_dir=output_dir, engine=mock_engine)

        await ex.execute("call_count_test", _BAD_CODE_NO_CQ)
        assert mock_engine.run_code.call_count == 2

    @pytest.mark.asyncio
    async def test_repaired_stl_exists_on_disk(self, output_dir):
        """After a successful repair+retry the STL artefact must be on disk."""
        first_done = [False]

        def _run_code(code, *, stl_path, step_path):
            if not first_done[0]:
                first_done[0] = True
                raise RuntimeError("NameError: name 'cq' is not defined")
            os.makedirs(os.path.dirname(stl_path), exist_ok=True)
            with open(stl_path, "wb") as f:
                f.write(b"solid repaired\nendsolid\n")
            with open(step_path, "wb") as f:
                f.write(b"ISO-10303-21; repaired step")

        mock_engine = MagicMock()
        mock_engine.run_code.side_effect = _run_code
        ex = ModuleExecutor(output_dir=output_dir, engine=mock_engine)

        result = await ex.execute("stl_check", _BAD_CODE_NO_CQ)
        assert result.stl_path is not None
        assert os.path.isfile(result.stl_path)

    @pytest.mark.asyncio
    async def test_unrecognised_error_skips_repair(self, output_dir):
        """An error that matches no deterministic rule must return status=failed."""
        mock_engine = MagicMock()
        mock_engine.run_code.side_effect = RuntimeError("completely unrelated crash xyz_999")
        ex = ModuleExecutor(output_dir=output_dir, engine=mock_engine)

        result = await ex.execute("nomatch", _BAD_CODE_NO_CQ)
        assert result.status == "failed"

    @pytest.mark.asyncio
    async def test_unrecognised_error_engine_called_once(self, output_dir):
        """No retry must occur when Durga finds no matching rule."""
        mock_engine = MagicMock()
        mock_engine.run_code.side_effect = RuntimeError("completely unrelated crash xyz_999")
        ex = ModuleExecutor(output_dir=output_dir, engine=mock_engine)

        await ex.execute("nomatch_count", _BAD_CODE_NO_CQ)
        assert mock_engine.run_code.call_count == 1

    @pytest.mark.asyncio
    async def test_repair_integrated_with_module_manager(self, module_manager, output_dir):
        """Full path: create module with bad code → repair → DB status updated to valid."""
        mod = module_manager.create(name="broken_gear", code=_BAD_CODE_NO_CQ)
        assert mod.status == "draft"

        first_done = [False]

        def _run_code(code, *, stl_path, step_path):
            if not first_done[0]:
                first_done[0] = True
                raise RuntimeError("NameError: name 'cq' is not defined")
            os.makedirs(os.path.dirname(stl_path), exist_ok=True)
            with open(stl_path, "wb") as f:
                f.write(b"solid fixed\nendsolid\n")
            with open(step_path, "wb") as f:
                f.write(b"ISO-10303-21; fixed step")

        mock_engine = MagicMock()
        mock_engine.run_code.side_effect = _run_code
        ex = ModuleExecutor(output_dir=output_dir, engine=mock_engine)

        result = await ex.execute(mod.id, mod.code)
        assert result.status == "valid"

        # Simulate what the route layer does after execution
        module_manager.update_status(mod.id, "valid")
        refreshed = module_manager.get(mod.id)
        assert refreshed.status == "valid"


# ---------------------------------------------------------------------------
# CadQuery-dependent integration tests (skipped in CI)
# ---------------------------------------------------------------------------


@pytest.mark.requires_cadquery
class TestWithRealCadQuery:
    """Full pipeline tests requiring a real CadQuery installation."""

    GOOD_CODE = "import cadquery as cq\nresult = cq.Workplane('XY').box(10, 10, 5)\n"
    BAD_CODE = "result = cq.Workplane('XY').box(5, 5, 5)\n"

    @pytest.mark.asyncio
    async def test_real_happy_path_produces_stl(self, module_manager, tmp_path):
        try:
            from backend.app.engines.cadquery_engine import CadQueryEngine  # noqa: PLC0415
        except ImportError:
            pytest.skip("CadQueryEngine not installed")

        engine = CadQueryEngine()
        output = str(tmp_path / "models")
        ex = ModuleExecutor(output_dir=output, engine=engine)

        mod = module_manager.create(name="real_box", code=self.GOOD_CODE)
        result = await ex.execute(mod.id, mod.code)

        assert result.status == "valid"
        assert result.stl_path is not None
        assert os.path.isfile(result.stl_path)
        assert result.step_path is not None
        assert os.path.isfile(result.step_path)

    @pytest.mark.asyncio
    async def test_real_durga_repair_recovers_missing_import(self, module_manager, tmp_path):
        """Real CadQuery raises NameError → Durga repairs → second execution passes."""
        try:
            from backend.app.engines.cadquery_engine import CadQueryEngine  # noqa: PLC0415
        except ImportError:
            pytest.skip("CadQueryEngine not installed")

        engine = CadQueryEngine()
        output = str(tmp_path / "models")
        ex = ModuleExecutor(output_dir=output, engine=engine)

        mod = module_manager.create(name="broken_box", code=self.BAD_CODE)
        result = await ex.execute(mod.id, mod.code)

        # Durga should repair by adding the import; result should be valid
        assert result.status == "valid", (
            f"Expected Durga to repair missing import, got: {result.error}"
        )
