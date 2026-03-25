import pytest
from pydantic import ValidationError
from backend.kfs_manifest.schema.v1.geometry_models import (
    BoxGeometry,
    SphereGeometry,
    CylinderGeometry,
    MeshGeometry,
    Geometry,
)

def test_box_geometry_valid():
    box = BoxGeometry(x=1.0, y=2.0, z=3.0)
    assert box.x == 1.0
    assert box.y == 2.0
    assert box.z == 3.0
    assert box.type == "box"

def test_box_geometry_invalid_dimensions():
    with pytest.raises(ValidationError):
        BoxGeometry(x=-1.0, y=2.0, z=3.0)
    with pytest.raises(ValidationError):
        BoxGeometry(x=1.0, y=0.0, z=3.0)
    with pytest.raises(ValidationError):
        BoxGeometry(x=1.0, y=2.0, z=-3.0)

def test_sphere_geometry_valid():
    sphere = SphereGeometry(radius=5.0)
    assert sphere.radius == 5.0
    assert sphere.type == "sphere"

def test_sphere_geometry_invalid_radius():
    with pytest.raises(ValidationError):
        SphereGeometry(radius=0.0)
    with pytest.raises(ValidationError):
        SphereGeometry(radius=-1.0)

def test_cylinder_geometry_valid():
    cylinder = CylinderGeometry(radius=2.0, height=10.0)
    assert cylinder.radius == 2.0
    assert cylinder.height == 10.0
    assert cylinder.type == "cylinder"

def test_cylinder_geometry_invalid_dimensions():
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=-2.0, height=10.0)
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=2.0, height=0.0)
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=0.0, height=10.0)

def test_mesh_geometry_valid():
    mesh = MeshGeometry(file_path="assets/mesh.stl")
    assert mesh.file_path == "assets/mesh.stl"
    assert mesh.type == "mesh"

def test_mesh_geometry_invalid_file_path():
    with pytest.raises(ValidationError):
        MeshGeometry(file_path="")
    with pytest.raises(ValidationError):
        MeshGeometry(file_path=None) # type: ignore

def test_geometry_union_box():
    geom = Geometry(type="box", x=1.0, y=2.0, z=3.0)
    assert isinstance(geom, BoxGeometry)
    assert geom.x == 1.0
    assert geom.type == "box"

def test_geometry_union_sphere():
    geom = Geometry(type="sphere", radius=5.0)
    assert isinstance(geom, SphereGeometry)
    assert geom.radius == 5.0
    assert geom.type == "sphere"

def test_geometry_union_cylinder():
    geom = Geometry(type="cylinder", radius=2.0, height=10.0)
    assert isinstance(geom, CylinderGeometry)
    assert geom.radius == 2.0
    assert geom.type == "cylinder"

def test_geometry_union_mesh():
    geom = Geometry(type="mesh", file_path="path/to/mesh.obj")
    assert isinstance(geom, MeshGeometry)
    assert geom.file_path == "path/to/mesh.obj"
    assert geom.type == "mesh"

def test_geometry_union_invalid_type():
    with pytest.raises(ValidationError):
        Geometry(type="invalid_type", x=1, y=2, z=3)

def test_geometry_union_missing_fields_for_type():
    with pytest.raises(ValidationError):
        Geometry(type="box", radius=1.0) # Missing x, y, z
    with pytest.raises(ValidationError):
        Geometry(type="sphere", x=1.0) # Missing radius

def test_geometry_serialization():
    box = BoxGeometry(x=1.0, y=2.0, z=3.0)
    expected_json = '{"type":"box","x":1.0,"y":2.0,"z":3.0}'
    assert box.model_dump_json(exclude_none=True) == expected_json

    sphere = SphereGeometry(radius=5.0)
    expected_json = '{"type":"sphere","radius":5.0}'
    assert sphere.model_dump_json(exclude_none=True) == expected_json

    mesh = MeshGeometry(file_path="assets/file.glb")
    expected_json = '{"type":"mesh","file_path":"assets/file.glb"}'
    assert mesh.model_dump_json(exclude_none=True) == expected_json
