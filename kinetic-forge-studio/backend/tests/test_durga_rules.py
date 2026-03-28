"""
Tests for the deterministic Durga repair rules (app/services/durga_rules.py).

get_repair(error_text, source_code) returns a patched source string or None.
"""
import pytest

from app.services.durga_rules import get_repair


# ---------------------------------------------------------------------------
# Rule 1: No pending wires
# ---------------------------------------------------------------------------

class TestNoPendingWiresFix:
    def test_adds_workplane_before_extrude(self):
        source = "result = cq.Workplane('XY').circle(5).extrude(10)"
        patched = get_repair("No pending wires found", source)
        assert patched is not None
        assert ".workplane().extrude(" in patched

    def test_no_pending_edges_variant(self):
        source = "r = cq.Workplane('XY').rect(10, 10).extrude(5)"
        patched = get_repair("No pending edges", source)
        assert patched is not None
        assert ".workplane().extrude(" in patched

    def test_no_change_when_no_extrude(self):
        """Rule 1 should return None if source has no .extrude() to patch."""
        source = "result = cq.Workplane('XY').box(10, 10, 10)"
        patched = get_repair("No pending wires found", source)
        assert patched is None


# ---------------------------------------------------------------------------
# Rule 2: Empty STL / no geometry
# ---------------------------------------------------------------------------

class TestEmptyStlFix:
    def test_appends_exportstl_when_result_present(self):
        source = "result = cq.Workplane('XY').box(10, 10, 10)"
        patched = get_repair("empty geometry produced", source)
        assert patched is not None
        assert "exportStl" in patched

    def test_no_bytes_variant(self):
        source = "result = cq.Workplane('XY').box(5, 5, 5)"
        patched = get_repair("file has 0 bytes", source)
        assert patched is not None
        assert "exportStl" in patched

    def test_does_not_double_add_exportstl(self):
        """Rule 2 must not append if exportStl is already present."""
        source = "result = cq.Workplane('XY').box(10,10,10)\nresult.val().exportStl('out.stl')"
        patched = get_repair("empty", source)
        assert patched is None

    def test_no_match_when_no_result_or_shape_var(self):
        """Append requires 'result' or 'shape' variable in source."""
        source = "x = cq.Workplane('XY').box(10, 10, 10)"
        patched = get_repair("empty geometry", source)
        assert patched is None


# ---------------------------------------------------------------------------
# Rule 3: Unknown error — no match
# ---------------------------------------------------------------------------

class TestNoMatch:
    def test_unknown_error_returns_none(self):
        source = "result = cq.Workplane('XY').box(10, 10, 10)"
        patched = get_repair("some completely unknown runtime failure", source)
        assert patched is None

    def test_empty_error_returns_none(self):
        source = "result = cq.Workplane('XY').box(10, 10, 10)"
        patched = get_repair("", source)
        assert patched is None


# ---------------------------------------------------------------------------
# Rule 6: Missing cadquery import
# ---------------------------------------------------------------------------

class TestMissingImport:
    def test_missing_cadquery_import_prepended(self):
        source = "result = cq.Workplane('XY').box(10, 10, 10)"
        patched = get_repair(
            "ImportError: cannot import name 'cadquery'", source
        )
        assert patched is not None
        assert patched.startswith("import cadquery as cq")

    def test_no_double_import(self):
        """Should return None if import already present."""
        source = "import cadquery as cq\nresult = cq.Workplane('XY').box(10,10,10)"
        patched = get_repair("ImportError: cannot import name 'cadquery'", source)
        assert patched is None


# ---------------------------------------------------------------------------
# Rule 5: Division by zero — clamp parameters
# ---------------------------------------------------------------------------

class TestZeroDivisionFix:
    def test_module_zero_clamped(self):
        source = "gear = make_gear(module=0, teeth=20)"
        patched = get_repair("ZeroDivisionError: division by zero", source)
        assert patched is not None
        assert "module = 1.0" in patched

    def test_teeth_zero_clamped(self):
        source = "gear = make_gear(module=1.0, teeth=0)"
        patched = get_repair("ZeroDivisionError", source)
        assert patched is not None
        assert "teeth = 20" in patched


# ---------------------------------------------------------------------------
# Rule 7: Sketch not closed
# ---------------------------------------------------------------------------

class TestSketchNotClosed:
    def test_close_added_before_extrude(self):
        source = "result = cq.Workplane('XY').rect(10, 10).extrude(5)"
        patched = get_repair("sketch is not closed", source)
        assert patched is not None
        assert ".close().extrude(" in patched


# ---------------------------------------------------------------------------
# Rule 4: No solid found
# ---------------------------------------------------------------------------

class TestNoSolidFound:
    def test_solids_selector_inserted(self):
        source = "shape = result.val()"
        patched = get_repair("No solid found in compound", source)
        assert patched is not None
        assert ".solids().val()" in patched


# ---------------------------------------------------------------------------
# Rule 8: Missing semicolons (OpenSCAD)
# ---------------------------------------------------------------------------

class TestMissingSemicolons:
    def test_semicolons_appended(self):
        source = "cube([10, 10, 10])"
        patched = get_repair("expected ';' near 'cube'", source)
        assert patched is not None
        assert patched.strip().endswith(";")


# ---------------------------------------------------------------------------
# Rule 10: Invalid workplane selector
# ---------------------------------------------------------------------------

class TestInvalidWorkplane:
    def test_custom_selector_replaced_with_xy(self):
        # Rule 10 targets lowercase .workplane() method calls (CadQuery chain calls)
        source = "result = cq.Workplane('XY').workplane('BOGUS').box(10, 10, 10)"
        patched = get_repair("Invalid workplane selector", source)
        assert patched is not None
        assert ".workplane('XY')" in patched

    def test_valid_xy_selector_not_changed(self):
        # No non-standard selectors present — rule should not fire
        source = "result = cq.Workplane('XY').workplane('XZ').box(10, 10, 10)"
        patched = get_repair("Invalid workplane selector", source)
        assert patched is None
