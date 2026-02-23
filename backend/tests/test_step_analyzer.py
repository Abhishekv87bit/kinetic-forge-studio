"""Tests for the STEP file analyzer."""

import pytest
from pathlib import Path

import cadquery as cq

from app.importers.step_analyzer import STEPAnalyzer


@pytest.fixture
def analyzer():
    return STEPAnalyzer()


@pytest.fixture
def step_box(tmp_path) -> Path:
    """Generate a test STEP file containing a simple box."""
    box = cq.Workplane("XY").box(20, 30, 40)
    path = tmp_path / "test_box.step"
    cq.exporters.export(box, str(path))
    return path


@pytest.fixture
def step_cylinder(tmp_path) -> Path:
    """Generate a test STEP file containing a cylinder."""
    cyl = cq.Workplane("XY").cylinder(25, 10)
    path = tmp_path / "test_cylinder.step"
    cq.exporters.export(cyl, str(path))
    return path


@pytest.fixture
def step_compound(tmp_path) -> Path:
    """Generate a test STEP file with a box + cylinder compound."""
    box = cq.Workplane("XY").box(20, 20, 10)
    cyl = cq.Workplane("XY").workplane(offset=10).cylinder(15, 5)
    compound = box.union(cyl)
    path = tmp_path / "test_compound.step"
    cq.exporters.export(compound, str(path))
    return path


class TestSTEPAnalyzerBox:
    def test_box_body_count(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        assert result["body_count"] == 1

    def test_box_format(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        assert result["format"] == "STEP"

    def test_box_bounding_box_dimensions(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        bb = result["bounding_box"]
        # Box is 20x30x40, centered at origin
        assert abs(bb["x_size"] - 20.0) < 0.1
        assert abs(bb["y_size"] - 30.0) < 0.1
        assert abs(bb["z_size"] - 40.0) < 0.1

    def test_box_face_count(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        # A box has 6 faces
        assert result["face_count"] == 6

    def test_box_all_faces_planar(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        assert result["face_types"].get("planar", 0) == 6

    def test_box_volume(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        expected_volume = 20.0 * 30.0 * 40.0  # 24000
        assert abs(result["volume"] - expected_volume) < 1.0

    def test_box_surface_area(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        # 2*(20*30 + 20*40 + 30*40) = 2*(600+800+1200) = 5200
        expected_area = 5200.0
        assert abs(result["surface_area"] - expected_area) < 1.0

    def test_box_file_path_stored(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        assert result["file_path"] == str(step_box)


class TestSTEPAnalyzerCylinder:
    def test_cylinder_body_count(self, analyzer, step_cylinder):
        result = analyzer.analyze(step_cylinder)
        assert result["body_count"] == 1

    def test_cylinder_has_cylindrical_face(self, analyzer, step_cylinder):
        result = analyzer.analyze(step_cylinder)
        assert "cylindrical" in result["face_types"]
        assert result["face_types"]["cylindrical"] >= 1

    def test_cylinder_has_planar_faces(self, analyzer, step_cylinder):
        result = analyzer.analyze(step_cylinder)
        # Cylinder has 2 planar end caps
        assert result["face_types"].get("planar", 0) == 2

    def test_cylinder_bounding_box(self, analyzer, step_cylinder):
        result = analyzer.analyze(step_cylinder)
        bb = result["bounding_box"]
        # Cylinder: radius=10, height=25 -> diameter=20, height=25
        assert abs(bb["x_size"] - 20.0) < 0.1
        assert abs(bb["y_size"] - 20.0) < 0.1
        assert abs(bb["z_size"] - 25.0) < 0.1


class TestSTEPAnalyzerCompound:
    def test_compound_body_count(self, analyzer, step_compound):
        result = analyzer.analyze(step_compound)
        # Union produces 1 solid body
        assert result["body_count"] == 1

    def test_compound_has_mixed_face_types(self, analyzer, step_compound):
        result = analyzer.analyze(step_compound)
        # Compound of box+cylinder should have both planar and cylindrical faces
        assert "planar" in result["face_types"]
        assert "cylindrical" in result["face_types"]

    def test_compound_volume_positive(self, analyzer, step_compound):
        result = analyzer.analyze(step_compound)
        assert result["volume"] > 0


class TestSTEPAnalyzerErrors:
    def test_nonexistent_file(self, analyzer, tmp_path):
        with pytest.raises(FileNotFoundError):
            analyzer.analyze(tmp_path / "nonexistent.step")

    def test_invalid_step_file(self, analyzer, tmp_path):
        bad_file = tmp_path / "bad.step"
        bad_file.write_text("this is not a STEP file")
        with pytest.raises(ValueError, match="Failed to import STEP"):
            analyzer.analyze(bad_file)


class TestSTEPAnalyzerFaceDetails:
    def test_faces_list_has_correct_structure(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        for face in result["faces"]:
            assert "index" in face
            assert "type" in face
            assert isinstance(face["index"], int)
            assert isinstance(face["type"], str)

    def test_face_type_counts_sum_to_face_count(self, analyzer, step_box):
        result = analyzer.analyze(step_box)
        total_from_types = sum(result["face_types"].values())
        assert total_from_types == result["face_count"]
