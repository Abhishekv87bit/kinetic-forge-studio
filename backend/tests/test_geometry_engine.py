"""Tests for the geometry engine (CadQuery + trimesh)."""

import pytest
from pathlib import Path
from app.engines.geometry_engine import GeometryEngine, BoundingBox


@pytest.fixture
def engine():
    return GeometryEngine()


class TestBoxGeneration:
    def test_box_dimensions(self, engine):
        result = engine.generate_box(length=20, width=30, height=40, name="test_box")
        assert result.name == "test_box"
        assert result.shape_type == "box"
        bb = result.bounding_box
        assert abs(bb.x_size - 20.0) < 0.01
        assert abs(bb.y_size - 30.0) < 0.01
        assert abs(bb.z_size - 40.0) < 0.01

    def test_box_centered(self, engine):
        result = engine.generate_box(length=10, width=10, height=10)
        bb = result.bounding_box
        assert abs(bb.x_min + 5.0) < 0.01
        assert abs(bb.x_max - 5.0) < 0.01

    def test_box_parameters_stored(self, engine):
        result = engine.generate_box(length=15, width=25, height=35)
        assert result.parameters["length"] == 15
        assert result.parameters["width"] == 25
        assert result.parameters["height"] == 35


class TestCylinderGeneration:
    def test_cylinder_dimensions(self, engine):
        result = engine.generate_cylinder(radius=10, height=20, name="test_cyl")
        assert result.name == "test_cyl"
        assert result.shape_type == "cylinder"
        bb = result.bounding_box
        # Diameter should be 2 * radius = 20
        assert abs(bb.x_size - 20.0) < 0.1
        assert abs(bb.y_size - 20.0) < 0.1
        assert abs(bb.z_size - 20.0) < 0.1

    def test_cylinder_parameters(self, engine):
        result = engine.generate_cylinder(radius=7.5, height=15)
        assert result.parameters["radius"] == 7.5
        assert result.parameters["height"] == 15


class TestGearGeneration:
    def test_gear_outer_radius(self, engine):
        module = 1.5
        teeth = 20
        result = engine.generate_gear(module=module, teeth=teeth, height=8, name="test_gear")
        assert result.name == "test_gear"
        assert result.shape_type == "gear"

        expected_outer_radius = module * teeth / 2.0 + module  # pitch_r + addendum
        bb = result.bounding_box
        actual_x_extent = bb.x_size / 2.0
        actual_y_extent = bb.y_size / 2.0

        # Outer radius should be close to expected (within 5% for polygon approx)
        assert abs(actual_x_extent - expected_outer_radius) < expected_outer_radius * 0.1
        assert abs(actual_y_extent - expected_outer_radius) < expected_outer_radius * 0.1

    def test_gear_height(self, engine):
        result = engine.generate_gear(module=1.5, teeth=20, height=12)
        bb = result.bounding_box
        assert abs(bb.z_size - 12.0) < 0.1

    def test_gear_parameters(self, engine):
        result = engine.generate_gear(module=2.0, teeth=30, height=10)
        assert result.parameters["module"] == 2.0
        assert result.parameters["teeth"] == 30
        assert result.parameters["height"] == 10
        assert result.parameters["pitch_radius"] == 30.0  # 2.0 * 30 / 2
        assert result.parameters["outer_radius"] == 32.0  # 30 + 2.0


class TestSTLExport:
    def test_stl_export(self, engine, tmp_path):
        result = engine.generate_box(length=10, width=10, height=10)
        stl_path = tmp_path / "test.stl"
        exported = engine.export_stl(result, stl_path)
        assert exported.exists()
        assert exported.stat().st_size > 0

    def test_stl_export_creates_dirs(self, engine, tmp_path):
        result = engine.generate_cylinder(radius=5, height=10)
        stl_path = tmp_path / "subdir" / "deep" / "test.stl"
        exported = engine.export_stl(result, stl_path)
        assert exported.exists()


class TestSTEPExport:
    def test_step_export(self, engine, tmp_path):
        result = engine.generate_box(length=10, width=10, height=10)
        step_path = tmp_path / "test.step"
        exported = engine.export_step(result, step_path)
        assert exported.exists()
        assert exported.stat().st_size > 100  # STEP files have headers

    def test_step_gear_export(self, engine, tmp_path):
        result = engine.generate_gear(module=1.5, teeth=20, height=8)
        step_path = tmp_path / "gear.step"
        exported = engine.export_step(result, step_path)
        assert exported.exists()
        assert exported.stat().st_size > 100


class TestGLTFExport:
    def test_gltf_export(self, engine, tmp_path):
        result = engine.generate_box(length=10, width=20, height=30)
        glb_path = tmp_path / "test.glb"
        exported = engine.export_gltf(result, glb_path)
        assert exported.exists()
        assert exported.stat().st_size > 0
        # GLB magic number check
        with open(exported, "rb") as f:
            magic = f.read(4)
        assert magic == b"glTF"

    def test_gltf_cylinder_export(self, engine, tmp_path):
        result = engine.generate_cylinder(radius=10, height=20)
        glb_path = tmp_path / "cyl.glb"
        exported = engine.export_gltf(result, glb_path)
        assert exported.exists()

    def test_gltf_gear_export(self, engine, tmp_path):
        result = engine.generate_gear(module=1.5, teeth=20, height=8)
        glb_path = tmp_path / "gear.glb"
        exported = engine.export_gltf(result, glb_path)
        assert exported.exists()

    def test_glb_bytes(self, engine):
        result = engine.generate_box(length=10, width=10, height=10)
        data = engine.to_glb_bytes(result)
        assert isinstance(data, bytes)
        assert len(data) > 0
        assert data[:4] == b"glTF"


class TestAssemblyExport:
    def test_assembly_glb(self, engine):
        box = engine.generate_box(length=10, width=10, height=5, name="base_plate")
        cyl = engine.generate_cylinder(radius=3, height=15, name="shaft")
        gear = engine.generate_gear(module=1.5, teeth=16, height=6, name="sun_gear")

        glb_data = engine.generate_assembly_glb([box, cyl, gear])
        assert isinstance(glb_data, bytes)
        assert len(glb_data) > 0
        assert glb_data[:4] == b"glTF"


class TestBoundingBox:
    def test_bounding_box_properties(self):
        bb = BoundingBox(x_min=-5, y_min=-10, z_min=-15, x_max=5, y_max=10, z_max=15)
        assert bb.x_size == 10
        assert bb.y_size == 20
        assert bb.z_size == 30
