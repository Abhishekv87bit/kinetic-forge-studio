"""Contract tests for SC-01 Module Manager.

Tests exercise ModuleManager against a real SQLite database (backed by a
tmp_path file — see conftest.py).  No CadQuery import, no subprocess.

Method coverage:
  create            — insert module at version 1
  get               — fetch by id
  list_all          — all modules, oldest first
  update_source     — replace code + bump version (contract alias for update_code)
  set_status        — lifecycle state update (contract alias for update_status)
  set_vlad_verdict  — persist VLAD string verdict (contract alias)
  get_version_history — immutable snapshots of previous code versions
  rollback          — restore code from a historical snapshot
"""
from __future__ import annotations

import pytest

from backend.app.models.module import Module, ModuleManager, ModuleVersion


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make(
    manager: ModuleManager,
    *,
    name: str = "spur_gear",
    code: str = "result = 'gear_v1'",
    parameters: dict | None = None,
) -> Module:
    """Create a module with sensible defaults and return the Module record."""
    return manager.create(name=name, code=code, parameters=parameters or {"teeth": 20})


# ===========================================================================
# create
# ===========================================================================


class TestCreate:
    def test_returns_module_instance(self, manager):
        record = _make(manager)
        assert isinstance(record, Module)

    def test_has_non_empty_id(self, manager):
        record = _make(manager)
        assert record.id and len(record.id) > 0

    def test_name_stored(self, manager):
        record = _make(manager, name="helix_driver")
        assert record.name == "helix_driver"

    def test_code_stored(self, manager):
        code = "result = cq.Workplane('XY').box(10, 10, 10)"
        record = _make(manager, code=code)
        assert record.code == code

    def test_initial_version_is_one(self, manager):
        record = _make(manager)
        assert record.version == 1

    def test_initial_status_is_draft(self, manager):
        record = _make(manager)
        assert record.status == "draft"

    def test_vlad_verdict_is_none(self, manager):
        record = _make(manager)
        assert record.vlad_verdict is None

    def test_parameters_stored_as_dict(self, manager):
        params = {"module": 1.5, "teeth": 32, "pressure_angle": 20}
        record = _make(manager, parameters=params)
        assert record.parameters == params

    def test_parameters_none_when_omitted(self, manager):
        record = manager.create(name="bare", code="# code")
        assert record.parameters is None

    def test_unique_ids_per_create(self, manager):
        a = _make(manager, name="a")
        b = _make(manager, name="b")
        assert a.id != b.id

    def test_timestamps_populated(self, manager):
        record = _make(manager)
        assert record.created_at
        assert record.updated_at


# ===========================================================================
# get
# ===========================================================================


class TestGet:
    def test_returns_same_module(self, manager):
        record = _make(manager)
        fetched = manager.get(record.id)
        assert fetched is not None
        assert fetched.id == record.id

    def test_returns_none_for_unknown_id(self, manager):
        assert manager.get("does-not-exist") is None

    def test_fetched_name_matches(self, manager):
        record = _make(manager, name="bevel_gear")
        fetched = manager.get(record.id)
        assert fetched.name == "bevel_gear"

    def test_fetched_code_matches(self, manager):
        code = "# unique_marker_xyz"
        record = _make(manager, code=code)
        fetched = manager.get(record.id)
        assert fetched.code == code

    def test_fetched_parameters_match(self, manager):
        params = {"teeth": 40}
        record = _make(manager, parameters=params)
        fetched = manager.get(record.id)
        assert fetched.parameters == params


# ===========================================================================
# list_all
# ===========================================================================


class TestListAll:
    def test_empty_when_no_modules(self, manager):
        assert manager.list_all() == []

    def test_returns_one_after_create(self, manager):
        _make(manager)
        assert len(manager.list_all()) == 1

    def test_returns_all_created_modules(self, manager):
        _make(manager, name="a")
        _make(manager, name="b")
        _make(manager, name="c")
        assert len(manager.list_all()) == 3

    def test_all_items_are_module_instances(self, manager):
        _make(manager)
        _make(manager, name="second")
        for m in manager.list_all():
            assert isinstance(m, Module)

    def test_ordered_oldest_first(self, manager):
        a = _make(manager, name="first")
        b = _make(manager, name="second")
        listing = manager.list_all()
        assert listing[0].id == a.id
        assert listing[1].id == b.id


# ===========================================================================
# update_source  (contract alias for update_code)
# ===========================================================================


class TestUpdateSource:
    def test_code_replaced(self, manager):
        record = _make(manager)
        updated = manager.update_source(record.id, "# new_code_v2")
        assert updated.code == "# new_code_v2"

    def test_version_incremented(self, manager):
        record = _make(manager)
        updated = manager.update_source(record.id, "# v2")
        assert updated.version == 2

    def test_second_update_version_three(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# v2")
        updated = manager.update_source(record.id, "# v3")
        assert updated.version == 3

    def test_returns_module_instance(self, manager):
        record = _make(manager)
        updated = manager.update_source(record.id, "# v2")
        assert isinstance(updated, Module)

    def test_raises_key_error_for_unknown_module(self, manager):
        with pytest.raises(KeyError):
            manager.update_source("does-not-exist", "# code")

    def test_old_code_accessible_in_history(self, manager):
        original = "original_code = True"
        record = manager.create(name="versioned", code=original)
        manager.update_source(record.id, "# replaced")
        history = manager.get_version_history(record.id)
        assert any(v.code == original for v in history)

    def test_live_get_reflects_update(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# persisted")
        fetched = manager.get(record.id)
        assert fetched.code == "# persisted"


# ===========================================================================
# set_status  (contract alias for update_status)
# ===========================================================================


class TestSetStatus:
    def test_status_set_to_executing(self, manager):
        record = _make(manager)
        updated = manager.set_status(record.id, "executing")
        assert updated.status == "executing"

    def test_status_set_to_valid(self, manager):
        record = _make(manager)
        updated = manager.set_status(record.id, "valid")
        assert updated.status == "valid"

    def test_status_set_to_failed(self, manager):
        record = _make(manager)
        updated = manager.set_status(record.id, "failed")
        assert updated.status == "failed"

    def test_returns_module_instance(self, manager):
        record = _make(manager)
        updated = manager.set_status(record.id, "valid")
        assert isinstance(updated, Module)

    def test_raises_key_error_for_unknown_module(self, manager):
        with pytest.raises(KeyError):
            manager.set_status("does-not-exist", "valid")

    def test_raises_value_error_for_bad_status(self, manager):
        record = _make(manager)
        with pytest.raises(ValueError):
            manager.set_status(record.id, "not_a_status")

    def test_get_reflects_new_status(self, manager):
        record = _make(manager)
        manager.set_status(record.id, "valid")
        fetched = manager.get(record.id)
        assert fetched.status == "valid"


# ===========================================================================
# set_vlad_verdict  (contract alias storing string verdict)
# ===========================================================================


class TestSetVladVerdict:
    def test_verdict_stored(self, manager):
        record = _make(manager)
        updated = manager.set_vlad_verdict(record.id, "PASS")
        assert updated.vlad_verdict == "PASS"

    def test_verdict_fail_string_stored(self, manager):
        record = _make(manager)
        updated = manager.set_vlad_verdict(record.id, "FAIL:clearance_2.1mm")
        assert updated.vlad_verdict == "FAIL:clearance_2.1mm"

    def test_returns_module_instance(self, manager):
        record = _make(manager)
        updated = manager.set_vlad_verdict(record.id, "PASS")
        assert isinstance(updated, Module)

    def test_raises_key_error_for_unknown_module(self, manager):
        with pytest.raises(KeyError):
            manager.set_vlad_verdict("does-not-exist", "PASS")

    def test_get_reflects_verdict(self, manager):
        record = _make(manager)
        manager.set_vlad_verdict(record.id, "PASS")
        fetched = manager.get(record.id)
        assert fetched.vlad_verdict == "PASS"

    def test_verdict_overwritten_on_second_call(self, manager):
        record = _make(manager)
        manager.set_vlad_verdict(record.id, "FAIL:topology")
        updated = manager.set_vlad_verdict(record.id, "PASS")
        assert updated.vlad_verdict == "PASS"


# ===========================================================================
# get_version_history
# ===========================================================================


class TestGetVersionHistory:
    def test_empty_after_create(self, manager):
        """History is empty until update_source is called — v1 lives in modules."""
        record = _make(manager)
        history = manager.get_version_history(record.id)
        assert history == []

    def test_one_snapshot_after_first_update(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# v2")
        history = manager.get_version_history(record.id)
        assert len(history) == 1

    def test_two_snapshots_after_two_updates(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# v2")
        manager.update_source(record.id, "# v3")
        history = manager.get_version_history(record.id)
        assert len(history) == 2

    def test_snapshots_ordered_oldest_first(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# v2")
        manager.update_source(record.id, "# v3")
        history = manager.get_version_history(record.id)
        versions = [v.version for v in history]
        assert versions == sorted(versions)

    def test_snapshot_contains_original_code(self, manager):
        original = "original_v1_sentinel"
        record = manager.create(name="snap_test", code=original)
        manager.update_source(record.id, "# v2")
        history = manager.get_version_history(record.id)
        assert history[0].code == original

    def test_returns_module_version_instances(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# v2")
        history = manager.get_version_history(record.id)
        for snap in history:
            assert isinstance(snap, ModuleVersion)

    def test_empty_list_for_unknown_module(self, manager):
        assert manager.get_version_history("no-such-module") == []

    def test_history_has_correct_module_id(self, manager):
        record = _make(manager)
        manager.update_source(record.id, "# v2")
        history = manager.get_version_history(record.id)
        assert history[0].module_id == record.id


# ===========================================================================
# rollback
# ===========================================================================


class TestRollback:
    def _setup_two_versions(self, manager) -> tuple[Module, str, str]:
        """Create a module and update once; returns (initial_record, v1_code, v2_code)."""
        v1_code = "# original_v1_code"
        v2_code = "# updated_v2_code"
        record = manager.create(name="rollback_test", code=v1_code)
        manager.update_source(record.id, v2_code)
        return record, v1_code, v2_code

    def test_code_restored_to_v1(self, manager):
        record, v1_code, _ = self._setup_two_versions(manager)
        manager.rollback(record.id, 1)
        fetched = manager.get(record.id)
        assert fetched.code == v1_code

    def test_returns_module_instance(self, manager):
        record, _, _ = self._setup_two_versions(manager)
        result = manager.rollback(record.id, 1)
        assert isinstance(result, Module)

    def test_version_continues_to_increment_after_rollback(self, manager):
        """Rollback does NOT revert the version counter — it continues forward."""
        record, _, _ = self._setup_two_versions(manager)
        result = manager.rollback(record.id, 1)
        # Started at v2, rollback creates v3 (monotonic)
        assert result.version == 3

    def test_rollback_to_current_version_is_noop(self, manager):
        record = _make(manager)
        # Version 1 is current and not yet in history — treated as no-op
        result = manager.rollback(record.id, 1)
        assert result.version == 1
        assert result.code == record.code

    def test_raises_key_error_for_unknown_module(self, manager):
        with pytest.raises(KeyError):
            manager.rollback("does-not-exist", 1)

    def test_raises_value_error_for_missing_version(self, manager):
        """Requesting a version that was never snapshotted raises ValueError."""
        record = _make(manager)
        with pytest.raises(ValueError):
            manager.rollback(record.id, 99)

    def test_multiple_rollbacks_possible(self, manager):
        v1 = "# v1_sentinel"
        record = manager.create(name="multi_roll", code=v1)
        manager.update_source(record.id, "# v2")
        manager.update_source(record.id, "# v3")
        manager.rollback(record.id, 1)
        fetched = manager.get(record.id)
        assert fetched.code == v1

    def test_get_reflects_rolled_back_code(self, manager):
        record, v1_code, _ = self._setup_two_versions(manager)
        manager.rollback(record.id, 1)
        assert manager.get(record.id).code == v1_code
