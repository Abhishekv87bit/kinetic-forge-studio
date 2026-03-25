import pytest
from pydantic import ValidationError

from kfs_core.manifest_models import (
    RGBColor,
    BaseGeometry, SphereGeometry, CubeGeometry, MeshGeometry, Geometry,
    Material,
    Transform,
    Keyframe, AnimationTrack,
    KFSObject,
    KFSManifest
)
from kfs_core.constants import KFS_MANIFEST_VERSION


# --- RGBColor Tests ---
def test_rgbcolor_valid_input():
    color = RGBColor(r=255, g=128, b=0)
    assert color.r == 255
    assert color.g == 128
    assert color.b == 0

def test_rgbcolor_min_values():
    color = RGBColor(r=0, g=0, b=0)
    assert color.r == 0
    assert color.g == 0
    assert color.b == 0

def test_rgbcolor_max_values():
    color = RGBColor(r=255, g=255, b=255)
    assert color.r == 255
    assert color.g == 255
    assert color.b == 255

def test_rgbcolor_invalid_input_less_than_0():
    with pytest.raises(ValidationError):
        RGBColor(r=-1, g=0, b=0)

def test_rgbcolor_invalid_input_greater_than_255():
    with pytest.raises(ValidationError):
        RGBColor(r=256, g=0, b=0)

def test_rgbcolor_to_hex():
    color = RGBColor(r=255, g=128, b=16)
    assert color.to_hex() == "#ff8010"
    color_black = RGBColor(r=0, g=0, b=0)
    assert color_black.to_hex() == "#000000"
    color_white = RGBColor(r=255, g=255, b=255)
    assert color_white.to_hex() == "#ffffff"

def test_rgbcolor_serialization():
    color_data = {"r": 10, "g": 20, "b": 30}
    color = RGBColor(**color_data)
    assert color.model_dump(mode='json') == color_data


# --- Geometry Models Tests ---

def test_basegeometry_id_constraints():
    # Valid ID
    BaseGeometry(id="test_id_123")
    BaseGeometry(id="a" * 64)

    # Invalid ID: too short
    with pytest.raises(ValidationError):
        BaseGeometry(id="")

    # Invalid ID: too long
    with pytest.raises(ValidationError):
        BaseGeometry(id="a" * 65)

    # BaseGeometry cannot be directly instantiated due to extra='forbid' if type is not provided,
    # and it's intended as a base for discriminated unions.
    # The actual 'type' field is on subclasses.
    # We test ID constraints directly on BaseGeometry for simplicity,
    # but actual usage will be via SphereGeometry, CubeGeometry, etc.


def test_sphere_geometry_valid():
    sphere = SphereGeometry(id="s1", radius=5.0)
    assert sphere.type == "sphere"
    assert sphere.id == "s1"
    assert sphere.radius == 5.0

def test_sphere_geometry_default_radius():
    sphere = SphereGeometry(id="s2")
    assert sphere.radius == 1.0

def test_sphere_geometry_invalid_radius():
    with pytest.raises(ValidationError):
        SphereGeometry(id="s3", radius=-1.0)
    with pytest.raises(ValidationError):
        SphereGeometry(id="s3", radius="not_a_number")

def test_sphere_geometry_extra_field():
    with pytest.raises(ValidationError):
        SphereGeometry(id="s4", radius=1.0, extra_field="bad")

def test_cube_geometry_valid():
    cube = CubeGeometry(id="c1", size=10.0)
    assert cube.type == "cube"
    assert cube.id == "c1"
    assert cube.size == 10.0

def test_cube_geometry_default_size():
    cube = CubeGeometry(id="c2")
    assert cube.size == 1.0

def test_cube_geometry_invalid_size():
    with pytest.raises(ValidationError):
        CubeGeometry(id="c3", size=-0.5)

def test_mesh_geometry_valid():
    mesh = MeshGeometry(id="m1", path="assets/model.obj")
    assert mesh.type == "mesh"
    assert mesh.id == "m1"
    assert mesh.path == "assets/model.obj"

def test_mesh_geometry_invalid_path():
    with pytest.raises(ValidationError):
        MeshGeometry(id="m2", path="")
    with pytest.raises(ValidationError):
        MeshGeometry(id="m2") # path is required


def test_geometry_union_discriminator():
    # Sphere
    geometry_data_sphere = {"type": "sphere", "id": "union_s1", "radius": 3.0}
    geometry = Geometry(**geometry_data_sphere)
    assert isinstance(geometry, SphereGeometry)
    assert geometry.id == "union_s1"
    assert geometry.radius == 3.0

    # Cube
    geometry_data_cube = {"type": "cube", "id": "union_c1", "size": 4.0}
    geometry = Geometry(**geometry_data_cube)
    assert isinstance(geometry, CubeGeometry)
    assert geometry.id == "union_c1"
    assert geometry.size == 4.0

    # Mesh
    geometry_data_mesh = {"type": "mesh", "id": "union_m1", "path": "models/complex.fbx"}
    geometry = Geometry(**geometry_data_mesh)
    assert isinstance(geometry, MeshGeometry)
    assert geometry.id == "union_m1"
    assert geometry.path == "models/complex.fbx"

    # Invalid type
    with pytest.raises(ValidationError):
        Geometry(type="unknown", id="u1", value=1.0)


# --- Material Tests ---

def test_material_valid_input():
    material = Material(color={"r": 255, "g": 0, "b": 0}, roughness=0.1, metallic=0.9)
    assert material.color.r == 255
    assert material.roughness == 0.1
    assert material.metallic == 0.9
    assert material.emissive_color is None

def test_material_defaults():
    material = Material()
    assert material.color == RGBColor(r=255, g=255, b=255)
    assert material.roughness == 0.5
    assert material.metallic == 0.0
    assert material.emissive_color is None

def test_material_with_emissive_color():
    emissive_mat = Material(emissive_color={"r": 100, "g": 0, "b": 0})
    assert emissive_mat.emissive_color == RGBColor(r=100, g=0, b=0)

def test_material_invalid_roughness():
    with pytest.raises(ValidationError):
        Material(roughness=1.1)
    with pytest.raises(ValidationError):
        Material(roughness=-0.1)

def test_material_invalid_metallic():
    with pytest.raises(ValidationError):
        Material(metallic=1.01)
    with pytest.raises(ValidationError):
        Material(metallic=-0.01)

def test_material_serialization():
    mat_data = {"color": {"r": 10, "g": 20, "b": 30}, "roughness": 0.2, "metallic": 0.8}
    material = Material(**mat_data)
    assert material.model_dump(mode='json', exclude_unset=True) == mat_data 
    
    mat_data_with_emissive = {"color": {"r": 10, "g": 20, "b": 30}, "roughness": 0.2, "metallic": 0.8, "emissive_color": {"r": 50, "g": 0, "b": 0}}
    material_full = Material(**mat_data_with_emissive)
    assert material_full.model_dump(mode='json', exclude_unset=True) == mat_data_with_emissive


# --- Transform Tests ---

def test_transform_valid_input():
    transform = Transform(position=[1.0, 2.0, 3.0], rotation=[90.0, 45.0, 0.0], scale=[2.0, 2.0, 2.0])
    assert transform.position == [1.0, 2.0, 3.0]
    assert transform.rotation == [90.0, 45.0, 0.0]
    assert transform.scale == [2.0, 2.0, 2.0]

def test_transform_defaults():
    transform = Transform()
    assert transform.position == [0.0, 0.0, 0.0]
    assert transform.rotation == [0.0, 0.0, 0.0]
    assert transform.scale == [1.0, 1.0, 1.0]

def test_transform_invalid_position_count():
    with pytest.raises(ValidationError):
        Transform(position=[1.0, 2.0])
    with pytest.raises(ValidationError):
        Transform(position=[1.0, 2.0, 3.0, 4.0])

def test_transform_invalid_scale_zero_or_negative():
    with pytest.raises(ValidationError):
        Transform(scale=[0.0, 1.0, 1.0])
    with pytest.raises(ValidationError):
        Transform(scale=[-1.0, 1.0, 1.0])

def test_transform_invalid_value_type():
    with pytest.raises(ValidationError):
        Transform(position=[1, "two", 3])

def test_transform_serialization():
    transform_data = {"position": [1.0, 2.0, 3.0]}
    transform = Transform(**transform_data)
    assert transform.model_dump(mode='json', exclude_unset=True) == transform_data


# --- Animation Models Tests ---

def test_keyframe_valid_scalar():
    keyframe = Keyframe(time=0.5, value=10.0, interpolation="linear")
    assert keyframe.time == 0.5
    assert keyframe.value == 10.0
    assert keyframe.interpolation == "linear"

def test_keyframe_valid_vector():
    keyframe = Keyframe(time=1.0, value=[1.0, 2.0, 3.0], interpolation="spline")
    assert keyframe.time == 1.0
    assert keyframe.value == [1.0, 2.0, 3.0]
    assert keyframe.interpolation == "spline"

def test_keyframe_default_interpolation():
    keyframe = Keyframe(time=0.0, value=0.0)
    assert keyframe.interpolation == "linear"

def test_keyframe_invalid_time():
    with pytest.raises(ValidationError):
        Keyframe(time=-0.1, value=0.0)

def test_keyframe_invalid_value_type():
    with pytest.raises(ValidationError):
        Keyframe(time=0.0, value="abc")
    with pytest.raises(ValidationError):
        Keyframe(time=0.0, value=[1, 2]) # vector must have 3 items

def test_keyframe_invalid_interpolation():
    with pytest.raises(ValidationError):
        Keyframe(time=0.0, value=0.0, interpolation="invalid")

def test_keyframe_serialization():
    kf_data = {"time": 0.5, "value": 10.0, "interpolation": "linear"}
    kf = Keyframe(**kf_data)
    assert kf.model_dump(mode='json') == kf_data

    kf_vec_data = {"time": 1.0, "value": [1.0, 2.0, 3.0], "interpolation": "step"}
    kf_vec = Keyframe(**kf_vec_data)
    assert kf_vec.model_dump(mode='json') == kf_vec_data


def test_animation_track_valid():
    track = AnimationTrack(
        property="position.x",
        keyframes=[
            Keyframe(time=0.0, value=0.0),
            Keyframe(time=1.0, value=10.0)
        ]
    )
    assert track.property == "position.x"
    assert len(track.keyframes) == 2

def test_animation_track_invalid_min_keyframes():
    with pytest.raises(ValidationError):
        AnimationTrack(property="position.x", keyframes=[Keyframe(time=0.0, value=0.0)]) # Needs at least 2 keyframes

def test_animation_track_invalid_property_empty():
    with pytest.raises(ValidationError):
        AnimationTrack(property="", keyframes=[
            Keyframe(time=0.0, value=0.0), Keyframe(time=1.0, value=1.0)
        ])

def test_animation_track_keyframe_order_validation():
    # Valid order
    AnimationTrack(
        property="scale.x",
        keyframes=[
            Keyframe(time=0.0, value=1.0),
            Keyframe(time=1.0, value=2.0),
            Keyframe(time=2.0, value=1.0)
        ]
    )

    # Invalid order (not increasing time)
    with pytest.raises(ValidationError, match="Keyframe times must be strictly increasing."):
        AnimationTrack(
            property="rotation.z",
            keyframes=[
                Keyframe(time=1.0, value=0.0),
                Keyframe(time=0.0, value=10.0)
            ]
        )

    # Invalid order (duplicate time)
    with pytest.raises(ValidationError, match="Keyframe times must be strictly increasing."):
        AnimationTrack(
            property="rotation.z",
            keyframes=[
                Keyframe(time=0.0, value=0.0),
                Keyframe(time=0.0, value=10.0),
                Keyframe(time=1.0, value=20.0)
            ]
        )

def test_animation_track_serialization():
    track_data = {
        "property": "position.y",
        "keyframes": [
            {"time": 0.0, "value": 0.0, "interpolation": "linear"},
            {"time": 2.0, "value": 5.0, "interpolation": "spline"}
        ]
    }
    track = AnimationTrack(**track_data)
    # Pydantic's default JSON dump might include defaults, so we convert back to dict for comparison
    dumped_data = track.model_dump(mode='json')
    # Custom comparison due to default interpolation
    assert dumped_data["property"] == track_data["property"]
    assert len(dumped_data["keyframes"]) == len(track_data["keyframes"])
    assert dumped_data["keyframes"][0]["time"] == track_data["keyframes"][0]["time"]
    assert dumped_data["keyframes"][0]["value"] == track_data["keyframes"][0]["value"]
    # "linear" is default, so it might not be explicitly present if exclude_unset=True.
    # We'll assert it's "linear"
    assert dumped_data["keyframes"][0].get("interpolation", "linear") == "linear"
    assert dumped_data["keyframes"][1] == track_data["keyframes"][1]


# --- KFSObject Tests ---

@pytest.fixture
def valid_sphere_geometry_data():
    return {"type": "sphere", "id": "geom_s1", "radius": 1.0}

@pytest.fixture
def valid_material_data():
    return {"color": {"r": 255, "g": 255, "b": 255}, "roughness": 0.5, "metallic": 0.0}

@pytest.fixture
def valid_animation_track_data():
    return {
        "property": "rotation.y",
        "keyframes": [
            {"time": 0.0, "value": 0.0},
            {"time": 10.0, "value": 360.0}
        ]
    }

def test_kfsobject_valid_minimal(valid_sphere_geometry_data, valid_material_data):
    obj = KFSObject(
        id="obj_001",
        geometry=valid_sphere_geometry_data,
        material=valid_material_data
    )
    assert obj.id == "obj_001"
    assert obj.name is None
    assert isinstance(obj.geometry, SphereGeometry)
    assert obj.geometry.id == "geom_s1"
    assert isinstance(obj.material, Material)
    assert obj.material.color.r == 255
    assert isinstance(obj.transform, Transform)
    assert obj.animations == []

def test_kfsobject_valid_full(valid_sphere_geometry_data, valid_material_data, valid_animation_track_data):
    obj = KFSObject(
        id="obj_002",
        name="My Object",
        geometry=valid_sphere_geometry_data,
        material=valid_material_data,
        transform={"position": [1, 2, 3], "scale": [2, 2, 2]},
        animations=[valid_animation_track_data]
    )
    assert obj.id == "obj_002"
    assert obj.name == "My Object"
    assert obj.transform.position == [1.0, 2.0, 3.0]
    assert obj.transform.scale == [2.0, 2.0, 2.0]
    assert len(obj.animations) == 1
    assert obj.animations[0].property == "rotation.y"

def test_kfsobject_invalid_id():
    with pytest.raises(ValidationError):
        KFSObject(id="", geometry={"type": "sphere", "id": "g", "radius": 1}, material={"color": {"r": 0, "g": 0, "b": 0}})

def test_kfsobject_invalid_nested_geometry():
    with pytest.raises(ValidationError):
        KFSObject(
            id="obj_bad_geom",
            geometry={"type": "sphere", "id": "g", "radius": -1.0}, # Invalid radius
            material={"color": {"r": 0, "g": 0, "b": 0}}
        )

def test_kfsobject_invalid_nested_material():
    with pytest.raises(ValidationError):
        KFSObject(
            id="obj_bad_mat",
            geometry={"type": "sphere", "id": "g", "radius": 1.0},
            material={"color": {"r": 0, "g": 0, "b": 0}, "roughness": 1.1} # Invalid roughness
        )

def test_kfsobject_serialization(valid_sphere_geometry_data, valid_material_data, valid_animation_track_data):
    obj_data = {
        "id": "serialized_obj",
        "name": "Serialized Object",
        "geometry": valid_sphere_geometry_data,
        "material": valid_material_data,
        "transform": {"position": [1.0, 1.0, 1.0], "rotation": [0.0,0.0,0.0], "scale": [1.0,1.0,1.0]},
        "animations": [valid_animation_track_data]
    }
    obj = KFSObject(**obj_data)
    dumped_data = obj.model_dump(mode='json')

    assert dumped_data["id"] == obj_data["id"]
    assert dumped_data["name"] == obj_data["name"]
    assert dumped_data["geometry"]["id"] == obj_data["geometry"]["id"]
    assert dumped_data["material"]["color"]["r"] == obj_data["material"]["color"]["r"]
    assert dumped_data["transform"]["position"] == obj_data["transform"]["position"]
    assert len(dumped_data["animations"]) == 1


# --- KFSManifest Tests ---

def test_kfsmanifest_valid_minimal():
    manifest = KFSManifest(
        name="Test Manifest",
        objects=[]
    )
    assert manifest.api_version == KFS_MANIFEST_VERSION
    assert manifest.kind == "KFSManifest"
    assert manifest.name == "Test Manifest"
    assert manifest.description is None
    assert manifest.objects == []

def test_kfsmanifest_valid_full(valid_sphere_geometry_data, valid_material_data, valid_animation_track_data):
    obj_data = {
        "id": "sphere_obj_1",
        "geometry": valid_sphere_geometry_data,
        "material": valid_material_data,
        "animations": [valid_animation_track_data]
    }
    manifest = KFSManifest(
        api_version=KFS_MANIFEST_VERSION,
        kind="KFSManifest",
        name="Full Test Manifest",
        description="A manifest with one object and an animation.",
        objects=[obj_data]
    )
    assert manifest.api_version == KFS_MANIFEST_VERSION
    assert manifest.kind == "KFSManifest"
    assert manifest.name == "Full Test Manifest"
    assert manifest.description == "A manifest with one object and an animation."
    assert len(manifest.objects) == 1
    assert manifest.objects[0].id == "sphere_obj_1"
    assert isinstance(manifest.objects[0], KFSObject)

def test_kfsmanifest_invalid_api_version():
    with pytest.raises(ValidationError, match=f"Unsupported api_version '99.99.99'. This parser supports '{KFS_MANIFEST_VERSION}'."):
        KFSManifest(
            api_version="99.99.99",
            name="Invalid Version Manifest",
            objects=[]
        )

def test_kfsmanifest_invalid_kind():
    with pytest.raises(ValidationError):
        KFSManifest(
            name="Invalid Kind Manifest",
            kind="OtherKind", # Should be "KFSManifest"
            objects=[]
        )

def test_kfsmanifest_invalid_name_empty():
    with pytest.raises(ValidationError):
        KFSManifest(name="", objects=[])

def test_kfsmanifest_serialization(valid_sphere_geometry_data, valid_material_data, valid_animation_track_data):
    obj_data = {
        "id": "sphere_obj_1",
        "geometry": valid_sphere_geometry_data,
        "material": valid_material_data,
        "animations": [valid_animation_track_data]
    }
    manifest_data = {
        "api_version": KFS_MANIFEST_VERSION,
        "kind": "KFSManifest",
        "name": "Serialized Manifest",
        "description": "A manifest for testing serialization.",
        "objects": [obj_data]
    }
    manifest = KFSManifest(**manifest_data)
    dumped_data = manifest.model_dump(mode='json')

    assert dumped_data["api_version"] == manifest_data["api_version"]
    assert dumped_data["kind"] == manifest_data["kind"]
    assert dumped_data["name"] == manifest_data["name"]
    assert dumped_data["description"] == manifest_data["description"]
    assert len(dumped_data["objects"]) == 1
    assert dumped_data["objects"][0]["id"] == obj_data["id"]
    assert dumped_data["objects"][0]["geometry"]["type"] == obj_data["geometry"]["type"]
    assert dumped_data["objects"][0]["material"]["color"] == obj_data["material"]["color"]
    assert len(dumped_data["objects"][0]["animations"]) == 1
