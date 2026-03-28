import pytest
from pydantic import ValidationError
from src.kfs_manifest.models import (
    Vector3,
    Quaternion,
    Transform,
    BoxGeometry,
    SphereGeometry,
    Geometry
)

# --- Test Vector3 Model ---

def test_vector3_valid_input():
    vec = Vector3(x=1.0, y=2.0, z=3.0)
    assert vec.x == 1.0
    assert vec.y == 2.0
    assert vec.z == 3.0

def test_vector3_from_dict():
    vec = Vector3.model_validate({'x': 10.0, 'y': 20.0, 'z': 30.0})
    assert vec.x == 10.0
    assert vec.y == 20.0
    assert vec.z == 30.0

def test_vector3_invalid_input_type():
    with pytest.raises(ValidationError):
        Vector3(x="invalid", y=2.0, z=3.0)

def test_vector3_missing_field():
    with pytest.raises(ValidationError):
        Vector3(x=1.0, y=2.0)

def test_vector3_serialization():
    vec = Vector3(x=1.0, y=2.0, z=3.0)
    assert vec.model_dump() == {'x': 1.0, 'y': 2.0, 'z': 3.0}

# --- Test Quaternion Model ---

def test_quaternion_valid_input():
    quat = Quaternion(x=0.1, y=0.2, z=0.3, w=0.9)
    assert quat.x == 0.1
    assert quat.y == 0.2
    assert quat.z == 0.3
    assert quat.w == 0.9

def test_quaternion_default_values():
    quat = Quaternion()
    assert quat.x == 0.0
    assert quat.y == 0.0
    assert quat.z == 0.0
    assert quat.w == 1.0

def test_quaternion_partial_input_and_defaults():
    quat = Quaternion(x=0.5)
    assert quat.x == 0.5
    assert quat.y == 0.0
    assert quat.z == 0.0
    assert quat.w == 1.0

def test_quaternion_invalid_input_type():
    with pytest.raises(ValidationError):
        Quaternion(x=1, y=2, z=3, w="invalid")

def test_quaternion_serialization():
    quat = Quaternion(x=0.1, y=0.2, z=0.3, w=0.9)
    assert quat.model_dump() == {'x': 0.1, 'y': 0.2, 'z': 0.3, 'w': 0.9}

# --- Test Transform Model ---

def test_transform_default_values():
    transform = Transform()
    assert transform.position == Vector3(x=0.0, y=0.0, z=0.0)
    assert transform.rotation == Quaternion(x=0.0, y=0.0, z=0.0, w=1.0)
    assert transform.scale == Vector3(x=1.0, y=1.0, z=1.0)

def test_transform_custom_values():
    pos = Vector3(x=1, y=2, z=3)
    rot = Quaternion(x=0.1, y=0.2, z=0.3, w=0.9)
    sca = Vector3(x=2, y=2, z=2)
    transform = Transform(position=pos, rotation=rot, scale=sca)
    assert transform.position == pos
    assert transform.rotation == rot
    assert transform.scale == sca

def test_transform_from_dict_with_nested_dicts():
    data = {
        'position': {'x': 10, 'y': 20, 'z': 30},
        'rotation': {'x': 0.5, 'y': 0, 'z': 0, 'w': 0.866},
        'scale': {'x': 3, 'y': 3, 'z': 3}
    }
    transform = Transform.model_validate(data)
    assert transform.position == Vector3(x=10, y=20, z=30)
    assert transform.rotation == Quaternion(x=0.5, y=0, z=0, w=0.866)
    assert transform.scale == Vector3(x=3, y=3, z=3)

def test_transform_partial_override_and_defaults():
    transform = Transform(position={'x': 5, 'y': 5, 'z': 5})
    assert transform.position == Vector3(x=5, y=5, z=5)
    assert transform.rotation == Quaternion()
    assert transform.scale == Vector3(x=1, y=1, z=1)

def test_transform_invalid_nested_type():
    with pytest.raises(ValidationError):
        Transform(position={'x': 1, 'y': 'invalid', 'z': 3})
    with pytest.raises(ValidationError):
        Transform(rotation={'x': 1, 'y': 2, 'z': 'bad', 'w': 4})

def test_transform_serialization():
    transform = Transform(
        position=Vector3(x=1, y=2, z=3),
        rotation=Quaternion(x=0.1, y=0.2, z=0.3, w=0.9),
        scale=Vector3(x=2, y=2, z=2)
    )
    expected_dict = {
        'position': {'x': 1.0, 'y': 2.0, 'z': 3.0},
        'rotation': {'x': 0.1, 'y': 0.2, 'z': 0.3, 'w': 0.9},
        'scale': {'x': 2.0, 'y': 2.0, 'z': 2.0}
    }
    assert transform.model_dump() == expected_dict

# --- Test BoxGeometry Model ---

def test_box_geometry_valid_input():
    box = BoxGeometry(name="my_box", width=2.0, height=3.0, depth=4.0)
    assert box.name == "my_box"
    assert box.type == "box"
    assert box.width == 2.0
    assert box.height == 3.0
    assert box.depth == 4.0

def test_box_geometry_default_values():
    box = BoxGeometry(name="default_box")
    assert box.name == "default_box"
    assert box.type == "box"
    assert box.width == 1.0
    assert box.height == 1.0
    assert box.depth == 1.0

def test_box_geometry_invalid_name_type():
    with pytest.raises(ValidationError):
        BoxGeometry(name=123, width=1.0)

def test_box_geometry_missing_name():
    with pytest.raises(ValidationError):
        BoxGeometry(width=1.0)

def test_box_geometry_invalid_dimensions():
    with pytest.raises(ValidationError): # PositiveFloat check
        BoxGeometry(name="bad_box", width=-1.0)
    with pytest.raises(ValidationError):
        BoxGeometry(name="bad_box", height=0.0)
    with pytest.raises(ValidationError):
        BoxGeometry(name="bad_box", depth="not_a_float")

def test_box_geometry_wrong_type_literal():
    # The type field is a Literal, cannot be changed by user input
    with pytest.raises(ValidationError):
        BoxGeometry(name="wrong_type", type="sphere", width=1.0)

def test_box_geometry_serialization():
    box = BoxGeometry(name="my_box_to_dump", width=2.5, height=3.5, depth=4.5)
    expected_dict = {
        'name': 'my_box_to_dump',
        'type': 'box',
        'width': 2.5,
        'height': 3.5,
        'depth': 4.5
    }
    assert box.model_dump() == expected_dict

# --- Test SphereGeometry Model ---

def test_sphere_geometry_valid_input():
    sphere = SphereGeometry(name="my_sphere", radius=5.0)
    assert sphere.name == "my_sphere"
    assert sphere.type == "sphere"
    assert sphere.radius == 5.0

def test_sphere_geometry_default_radius():
    sphere = SphereGeometry(name="default_sphere")
    assert sphere.name == "default_sphere"
    assert sphere.type == "sphere"
    assert sphere.radius == 0.5

def test_sphere_geometry_invalid_radius():
    with pytest.raises(ValidationError): # PositiveFloat check
        SphereGeometry(name="bad_sphere", radius=-0.1)
    with pytest.raises(ValidationError):
        SphereGeometry(name="bad_sphere", radius=0.0)
    with pytest.raises(ValidationError):
        SphereGeometry(name="bad_sphere", radius="invalid_radius")

def test_sphere_geometry_wrong_type_literal():
    with pytest.raises(ValidationError):
        SphereGeometry(name="wrong_type", type="box", radius=1.0)

def test_sphere_geometry_serialization():
    sphere = SphereGeometry(name="my_sphere_to_dump", radius=7.5)
    expected_dict = {
        'name': 'my_sphere_to_dump',
        'type': 'sphere',
        'radius': 7.5
    }
    assert sphere.model_dump() == expected_dict

# --- Test Geometry (Discriminated Union) ---

def test_geometry_discriminated_union_box():
    data = {"name": "union_box", "type": "box", "width": 10.0}
    geo = Geometry.model_validate(data)
    assert isinstance(geo, BoxGeometry)
    assert geo.name == "union_box"
    assert geo.type == "box"
    assert geo.width == 10.0
    assert geo.height == 1.0 # default

def test_geometry_discriminated_union_sphere():
    data = {"name": "union_sphere", "type": "sphere", "radius": 2.0}
    geo = Geometry.model_validate(data)
    assert isinstance(geo, SphereGeometry)
    assert geo.name == "union_sphere"
    assert geo.type == "sphere"
    assert geo.radius == 2.0

def test_geometry_discriminated_union_invalid_type():
    with pytest.raises(ValidationError) as exc_info:
        Geometry.model_validate({"name": "invalid_geo", "type": "unknown", "radius": 1.0})
    assert "type discriminant 'unknown' was not recognized" in str(exc_info.value)

def test_geometry_discriminated_union_missing_discriminant():
    with pytest.raises(ValidationError) as exc_info:
        Geometry.model_validate({"name": "missing_type", "radius": 1.0})
    assert "Field required" in str(exc_info.value)
    assert "type" in str(exc_info.value)

def test_geometry_discriminated_union_invalid_child_field():
    with pytest.raises(ValidationError):
        Geometry.model_validate({"name": "bad_box", "type": "box", "width": -5.0})
    with pytest.raises(ValidationError):
        Geometry.model_validate({"name": "bad_sphere", "type": "sphere", "radius": "not_a_number"})

def test_geometry_discriminated_union_serialization_box():
    geo = BoxGeometry(name="ser_box", width=10.0)
    expected_dict = {
        'name': 'ser_box',
        'type': 'box',
        'width': 10.0,
        'height': 1.0,
        'depth': 1.0
    }
    assert geo.model_dump() == expected_dict

def test_geometry_discriminated_union_serialization_sphere():
    geo = SphereGeometry(name="ser_sphere", radius=3.0)
    expected_dict = {
        'name': 'ser_sphere',
        'type': 'sphere',
        'radius': 3.0
    }
    assert geo.model_dump() == expected_dict