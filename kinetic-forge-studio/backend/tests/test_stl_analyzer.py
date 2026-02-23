"""Tests for the STL file analyzer."""

import pytest
from pathlib import Path

import trimesh
import numpy as np

from app.importers.stl_analyzer import STLAnalyzer


@pytest.fixture
def analyzer():
    return STLAnalyzer()


@pytest.fixture
def stl_box(tmp_path) -> Path:
    """Generate a test STL file containing a box (via trimesh primitive)."""
    mesh = trimesh.creation.box(extents=[20.0, 30.0, 40.0])
    path = tmp_path / "test_box.stl"
    mesh.export(str(path), file_type="stl")
    return path


@pytest.fixture
def stl_cylinder(tmp_path) -> Path:
    """Generate a test STL file containing a cylinder."""
    mesh = trimesh.creation.cylinder(radius=10.0, height=25.0)
    path = tmp_path / "test_cylinder.stl"
    mesh.export(str(path), file_type="stl")
    return path


class TestSTLAnalyzerBox:
    def test_box_format(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        assert result["format"] == "STL"

    def test_box_bounding_box_dimensions(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        bb = result["bounding_box"]
        assert abs(bb["x_size"] - 20.0) < 0.1
        assert abs(bb["y_size"] - 30.0) < 0.1
        assert abs(bb["z_size"] - 40.0) < 0.1

    def test_box_has_faces(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        # Trimesh box: 6 faces * 2 triangles each = 12 triangular faces
        assert result["face_count"] == 12

    def test_box_has_vertices(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        # Box has 8 unique vertices
        assert result["vertex_count"] == 8

    def test_box_is_watertight(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        assert result["is_watertight"] is True

    def test_box_volume(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        expected_volume = 20.0 * 30.0 * 40.0  # 24000
        assert abs(result["volume"] - expected_volume) < 1.0

    def test_box_surface_area(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        # 2*(20*30 + 20*40 + 30*40) = 5200
        expected_area = 5200.0
        assert abs(result["surface_area"] - expected_area) < 1.0

    def test_box_euler_number(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        # For a closed box: V - E + F = 2 (sphere topology)
        assert result["euler_number"] == 2

    def test_box_file_path_stored(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        assert result["file_path"] == str(stl_box)


class TestSTLAnalyzerCylinder:
    def test_cylinder_bounding_box(self, analyzer, stl_cylinder):
        result = analyzer.analyze(stl_cylinder)
        bb = result["bounding_box"]
        # Cylinder: radius=10, height=25 -> diameter=20
        assert abs(bb["x_size"] - 20.0) < 1.0
        assert abs(bb["y_size"] - 20.0) < 1.0
        assert abs(bb["z_size"] - 25.0) < 0.1

    def test_cylinder_is_watertight(self, analyzer, stl_cylinder):
        result = analyzer.analyze(stl_cylinder)
        assert result["is_watertight"] is True

    def test_cylinder_volume(self, analyzer, stl_cylinder):
        result = analyzer.analyze(stl_cylinder)
        # pi * r^2 * h = pi * 100 * 25 = ~7854
        expected = 3.14159 * 100.0 * 25.0
        # Mesh approximation - allow 5% tolerance
        assert abs(result["volume"] - expected) / expected < 0.05

    def test_cylinder_has_many_faces(self, analyzer, stl_cylinder):
        result = analyzer.analyze(stl_cylinder)
        # Tessellated cylinder has many triangular faces
        assert result["face_count"] > 20


class TestSTLAnalyzerLimitations:
    def test_limitations_message_present(self, analyzer, stl_box):
        result = analyzer.analyze(stl_box)
        assert "limitations" in result
        assert "STL lacks topology" in result["limitations"]
        assert "approximate" in result["limitations"]


class TestSTLAnalyzerErrors:
    def test_nonexistent_file(self, analyzer, tmp_path):
        with pytest.raises(FileNotFoundError):
            analyzer.analyze(tmp_path / "nonexistent.stl")

    def test_invalid_stl_file(self, analyzer, tmp_path):
        bad_file = tmp_path / "bad.stl"
        bad_file.write_bytes(b"\x00\x01\x02\x03")
        with pytest.raises(ValueError):
            analyzer.analyze(bad_file)
