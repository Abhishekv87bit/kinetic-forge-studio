import pytest
from pydantic import ValidationError
from backend.kfs_manifest.schema.v1.geometry_models import (
    CubeGeometry,
    SphereGeometry,
    CylinderGeometry,
    ConeGeometry,
    CapsuleGeometry,
    MeshGeometry,
    SDFGeometry,
    Geometry,
)


def test_cube_geometry_valid():
    cube = CubeGeometry(size=1.0)
    assert cube.type == "cube"
    assert cube.size == 1.0

def test_cube_geometry_invalid_size():
    with pytest.raises(ValidationError):
        CubeGeometry(size=-1.0)
    with pytest.raises(ValidationError):
        CubeGeometry(size=0.0)


def test_sphere_geometry_valid():
    sphere = SphereGeometry(radius=0.5)
    assert sphere.type == "sphere"
    assert sphere.radius == 0.5

def test_sphere_geometry_invalid_radius():
    with pytest.raises(ValidationError):
        SphereGeometry(radius=-0.5)
    with pytest.raises(ValidationError):
        SphereGeometry(radius=0.0)


def test_cylinder_geometry_valid():
    cylinder = CylinderGeometry(radius=0.2, length=1.0)
    assert cylinder.type == "cylinder"
    assert cylinder.radius == 0.2
    assert cylinder.length == 1.0

def test_cylinder_geometry_invalid_dimensions():
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=-0.2, length=1.0)
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=0.2, length=-1.0)
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=0.0, length=1.0)
    with pytest.raises(ValidationError):
        CylinderGeometry(radius=0.2, length=0.0)


def test_cone_geometry_valid():
    cone = ConeGeometry(radius=0.3, length=1.2)
    assert cone.type == "cone"
    assert cone.radius == 0.3
    assert cone.length == 1.2

def test_cone_geometry_invalid_dimensions():
    with pytest.raises(ValidationError):
        ConeGeometry(radius=-0.3, length=1.2)
    with pytest.raises(ValidationError):
        ConeGeometry(radius=0.3, length=-1.2)
    with pytest.raises(ValidationError):
        ConeGeometry(radius=0.0, length=1.2)
    with pytest.raises(ValidationError):
        ConeGeometry(radius=0.3, length=0.0)


def test_capsule_geometry_valid():
    capsule = CapsuleGeometry(radius=0.1, length=0.8)
    assert capsule.type == "capsule"
    assert capsule.radius == 0.1
    assert capsule.length == 0.8

def test_capsule_geometry_invalid_dimensions():
    with pytest.raises(ValidationError):
        CapsuleGeometry(radius=-0.1, length=0.8)
    with pytest.raises(ValidationError):
        CapsuleGeometry(radius=0.1, length=-0.8)
    with pytest.raises(ValidationError):
        CapsuleGeometry(radius=0.0, length=0.8)
    with pytest.raises(ValidationError):
        CapsuleGeometry(radius=0.1, length=0.0)


def test_mesh_geometry_valid():
    mesh = MeshGeometry(path="file:///path/to/mesh.obj")
    assert mesh.type == "mesh"
    assert mesh.path == "file:///path/to/mesh.obj"

def test_mesh_geometry_invalid_path():
    with pytest.raises(ValidationError):
        MeshGeometry(path="invalid-uri") # missing scheme
    with pytest.raises(ValidationError):
        MeshGeometry(path="/local/path/to/mesh.obj") # not a URI


def test_sdf_geometry_valid():
    sdf = SDFGeometry(path="file:///path/to/sdf.sdf")
    assert sdf.type == "sdf"
    assert sdf.path == "file:///path/to/sdf.sdf"

def test_sdf_geometry_invalid_path():
    with pytest.raises(ValidationError):
        SDFGeometry(path="invalid-sdf-uri")
    with pytest.raises(ValidationError):
        SDFGeometry(path="/local/path/to/sdf.sdf")


def test_geometry_union_cube():
    geom = Geometry.model_validate({"type": "cube", "size": 2.5})
    assert isinstance(geom, CubeGeometry)
    assert geom.size == 2.5

def test_geometry_union_sphere():
    geom = Geometry.model_validate({"type": "sphere", "radius": 1.0})
    assert isinstance(geom, SphereGeometry)
    assert geom.radius == 1.0

def test_geometry_union_mesh():
    geom = Geometry.model_validate({"type": "mesh", "path": "file:///data/model.stl"})
    assert isinstance(geom, MeshGeometry)
    assert geom.path == "file:///data/model.stl"

def test_geometry_union_invalid_type():
    with pytest.raises(ValidationError):
        Geometry.model_validate({"type": "unknown", "size": 1.0})

def test_geometry_union_missing_type():
    with pytest.raises(ValidationError):
        Geometry.model_validate({"size": 1.0})

def test_geometry_union_invalid_data_for_type():
    with pytest.raises(ValidationError):
        # Sphere with 'size' instead of 'radius'
        Geometry.model_validate({"type": "sphere", "size": 1.0})

