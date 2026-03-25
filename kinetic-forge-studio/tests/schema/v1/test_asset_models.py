import pytest
from pydantic import ValidationError
from backend.kfs_manifest.schema.v1.asset_models import StaticAsset, KineticAsset


def test_static_asset_creation_valid():
    """Test successful creation of StaticAsset with valid data."""
    data = {
        "name": "shelf_unit_1",
        "type": "static",
        "geometry_path": "models/static/shelf_unit.gltf",
        "description": "A standard shelf unit."
    }
    asset = StaticAsset(**data)
    assert asset.name == "shelf_unit_1"
    assert asset.type == "static"
    assert asset.geometry_path == "models/static/shelf_unit.gltf"
    assert asset.description == "A standard shelf unit."


def test_static_asset_creation_minimal_valid():
    """Test successful creation of StaticAsset with minimal valid data."""
    data = {
        "name": "floor_plane",
        "type": "static",
        "geometry_path": "models/static/floor.glb"
    }
    asset = StaticAsset(**data)
    assert asset.name == "floor_plane"
    assert asset.type == "static"
    assert asset.geometry_path == "models/static/floor.glb"
    assert asset.description is None


def test_static_asset_creation_missing_required_field():
    """Test StaticAsset creation fails with missing required fields."""
    # Missing 'name'
    data = {
        "type": "static",
        "geometry_path": "models/static/shelf_unit.gltf"
    }
    with pytest.raises(ValidationError):
        StaticAsset(**data)

    # Missing 'geometry_path'
    data = {
        "name": "shelf_unit_1",
        "type": "static",
    }
    with pytest.raises(ValidationError):
        StaticAsset(**data)


def test_static_asset_creation_invalid_type():
    """Test StaticAsset creation fails with invalid 'type'."""
    data = {
        "name": "shelf_unit_1",
        "type": "dynamic",  # Invalid type
        "geometry_path": "models/static/shelf_unit.gltf"
    }
    with pytest.raises(ValidationError):
        StaticAsset(**data)


def test_static_asset_serialization_deserialization():
    """Test StaticAsset serialization to JSON and deserialization back."""
    data = {
        "name": "wall_panel",
        "type": "static",
        "geometry_path": "models/static/wall_panel.obj",
        "description": "Modular wall panel."
    }
    asset = StaticAsset(**data)
    json_str = asset.model_dump_json()

    # Test deserialization
    deserialized_asset = StaticAsset.model_validate_json(json_str)
    assert deserialized_asset == asset


def test_kinetic_asset_creation_valid():
    """Test successful creation of KineticAsset with valid data."""
    data = {
        "name": "robotic_arm_v1",
        "type": "kinetic",
        "geometry_path": "models/kinetic/robot_arm.usd",
        "motion_profile": "profiles/robot_arm_pick_place.json",
        "initial_state": {"joint_1": 0.0, "joint_2": 90.0},
        "description": "A 6-axis robotic arm for pick and place operations."
    }
    asset = KineticAsset(**data)
    assert asset.name == "robotic_arm_v1"
    assert asset.type == "kinetic"
    assert asset.geometry_path == "models/kinetic/robot_arm.usd"
    assert asset.motion_profile == "profiles/robot_arm_pick_place.json"
    assert asset.initial_state == {"joint_1": 0.0, "joint_2": 90.0}
    assert asset.description == "A 6-axis robotic arm for pick and place operations."


def test_kinetic_asset_creation_minimal_valid():
    """Test successful creation of KineticAsset with minimal valid data."""
    data = {
        "name": "conveyor_belt",
        "type": "kinetic",
        "geometry_path": "models/kinetic/conveyor_1.gltf",
        "motion_profile": "profiles/conveyor_loop.yaml"
    }
    asset = KineticAsset(**data)
    assert asset.name == "conveyor_belt"
    assert asset.type == "kinetic"
    assert asset.geometry_path == "models/kinetic/conveyor_1.gltf"
    assert asset.motion_profile == "profiles/conveyor_loop.yaml"
    assert asset.initial_state is None
    assert asset.description is None


def test_kinetic_asset_creation_missing_required_field():
    """Test KineticAsset creation fails with missing required fields."""
    # Missing 'motion_profile'
    data = {
        "name": "robotic_arm_v1",
        "type": "kinetic",
        "geometry_path": "models/kinetic/robot_arm.usd",
    }
    with pytest.raises(ValidationError):
        KineticAsset(**data)

    # Missing 'name'
    data = {
        "type": "kinetic",
        "geometry_path": "models/kinetic/robot_arm.usd",
        "motion_profile": "profiles/robot_arm_pick_place.json",
    }
    with pytest.raises(ValidationError):
        KineticAsset(**data)


def test_kinetic_asset_creation_invalid_type():
    """Test KineticAsset creation fails with invalid 'type'."""
    data = {
        "name": "robotic_arm_v1",
        "type": "static",  # Invalid type
        "geometry_path": "models/kinetic/robot_arm.usd",
        "motion_profile": "profiles/robot_arm_pick_place.json",
    }
    with pytest.raises(ValidationError):
        KineticAsset(**data)


def test_kinetic_asset_serialization_deserialization():
    """Test KineticAsset serialization to JSON and deserialization back."""
    data = {
        "name": "actuator_2",
        "type": "kinetic",
        "geometry_path": "models/kinetic/actuator.obj",
        "motion_profile": "profiles/actuator_pulse.json",
        "initial_state": {"position": 0.5}
    }
    asset = KineticAsset(**data)
    json_str = asset.model_dump_json()

    # Test deserialization
    deserialized_asset = KineticAsset.model_validate_json(json_str)
    assert deserialized_asset == asset
