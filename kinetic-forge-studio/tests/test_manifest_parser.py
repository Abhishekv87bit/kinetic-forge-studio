import pytest
import yaml
import json
from pathlib import Path

from pydantic import ValidationError as PydanticValidationError

from kfs_core.manifest_models import (
    KFSManifest, RGBColor, SphereGeometry, Material, KFSObject, Transform, AnimationTrack, Keyframe, CubeGeometry
)
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_core.exceptions import (
    InvalidKFSManifestError,
    KFSManifestValidationError,
    ManifestVersionMismatchError,
    KFSBaseError
)
from kfs_core.manifest_parser import (
    _check_version_compatibility,
    load_kfs_manifest,
    save_kfs_manifest
)


# --- Fixtures ---

@pytest.fixture
def minimal_valid_manifest_data():
    """Returns a dictionary for a minimal valid KFS manifest."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Test Sculpture",
        "objects": [
            {
                "id": "obj1",
                "geometry_id": "sphere_geo",
                "material_id": "red_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
                "animation": None
            }
        ],
        "geometries": {
            "sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0}
        },
        "materials": {
            "red_material": {"id": "red_material", "color": {"r": 255, "g": 0, "b": 0}}
        }
    }

@pytest.fixture
def full_valid_manifest_data():
    """Returns a dictionary for a full valid KFS manifest, including animation."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Animated Sculpture",
        "description": "A sculpture with animated movement.",
        "geometries": {
            "cube_geo": {"type": "cube", "id": "cube_geo", "size": 2.5}
        },
        "materials": {
            "blue_material": {"id": "blue_material", "color": {"r": 0, "g": 0, "b": 255}}
        },
        "objects": [
            {
                "id": "animated_obj",
                "geometry_id": "cube_geo",
                "material_id": "blue_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
                "animation": {
                    "tracks": [
                        {
                            "target": "position.x",
                            "keyframes": [
                                {"time": 0.0, "value": 0.0, "interpolation": "linear"},
                                {"time": 1.0, "value": 5.0, "interpolation": "ease_in_out"}
                            ]
                        }
                    ]
                }
            }
        ],
        "simulation_settings": {"gravity": [0, -9.81, 0]}
    }


@pytest.fixture
def temp_yaml_file(tmp_path, minimal_valid_manifest_data):
    """Creates a temporary YAML file with valid manifest data."""
    file_path = tmp_path / "test_manifest.yaml"
    with open(file_path, "w", encoding="utf-8") as f:
        yaml.dump(minimal_valid_manifest_data, f, indent=2)
    return file_path

@pytest.fixture
def temp_json_file(tmp_path, minimal_valid_manifest_data):
    """Creates a temporary JSON file with valid manifest data."""
    file_path = tmp_path / "test_manifest.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(minimal_valid_manifest_data, f, indent=2)
    return file_path

@pytest.fixture
def manifest_instance(minimal_valid_manifest_data):
    """Returns a KFSManifest instance from minimal valid data."""
    return KFSManifest.model_validate(minimal_valid_manifest_data)


# --- Test _check_version_compatibility ---

def test_check_version_compatibility_same_major(minimal_valid_manifest_data):
    """Should pass when major versions match."""
    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["kfs_version"] = "1.2.3" # Manifest is 1.2.3
    _check_version_compatibility(manifest_data, "1.0.0") # Parser is 1.0.0, major 1 matches
    _check_version_compatibility(manifest_data, "1.5.0") # Parser is 1.5.0, major 1 matches

def test_check_version_compatibility_different_major():
    """Should raise ManifestVersionMismatchError when major versions differ."""
    manifest_data = {
        "kfs_version": "2.0.0",
        "name": "Future Test",
        "objects": []
    }
    with pytest.raises(ManifestVersionMismatchError) as excinfo:
        _check_version_compatibility(manifest_data, "1.0.0")
    assert "incompatible with parser version" in str(excinfo.value)
    assert "Major versions must match" in str(excinfo.value)

def test_check_version_compatibility_missing_version():
    """Should raise InvalidKFSManifestError when 'kfs_version' is missing."""
    manifest_data = {
        "name": "No Version",
        "objects": []
    }
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        _check_version_compatibility(manifest_data, "1.0.0")
    assert "Manifest data is missing 'kfs_version'." in str(excinfo.value)

def test_check_version_compatibility_malformed_manifest_version():
    """Should raise InvalidKFSManifestError for malformed manifest version."""
    manifest_data = {
        "kfs_version": "1", # Missing minor/patch, causes IndexError
        "name": "Malformed Version",
        "objects": []
    }
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        _check_version_compatibility(manifest_data, "1.0.0")
    assert "Invalid 'kfs_version' format" in str(excinfo.value)

    manifest_data["kfs_version"] = "1.abc" # Not an integer, causes ValueError
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        _check_version_compatibility(manifest_data, "1.0.0")
    assert "Invalid 'kfs_version' format" in str(excinfo.value)

def test_check_version_compatibility_malformed_parser_version():
    """Should raise InvalidKFSManifestError for malformed parser version."""
    manifest_data = {
        "kfs_version": "1.0.0",
        "name": "Valid Manifest",
        "objects": []
    }
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        _check_version_compatibility(manifest_data, "1") # Parser version missing minor/patch
    assert "Invalid 'kfs_version' format" in str(excinfo.value)


# --- Test load_kfs_manifest ---

def test_load_kfs_manifest_yaml_success(temp_yaml_file, minimal_valid_manifest_data):
    """Loads a valid YAML manifest successfully."""
    manifest = load_kfs_manifest(temp_yaml_file)
    assert isinstance(manifest, KFSManifest)
    assert manifest.name == minimal_valid_manifest_data["name"]
    assert manifest.kfs_version == KFS_MANIFEST_VERSION # KFSManifest will default if not explicitly in data, but here it is.
    assert len(manifest.objects) == 1
    assert manifest.objects[0].id == "obj1"
    assert manifest.geometries["sphere_geo"].radius == 1.0
    assert manifest.materials["red_material"].color.r == 255

def test_load_kfs_manifest_json_success(temp_json_file, minimal_valid_manifest_data):
    """Loads a valid JSON manifest successfully."""
    manifest = load_kfs_manifest(temp_json_file)
    assert isinstance(manifest, KFSManifest)
    assert manifest.name == minimal_valid_manifest_data["name"]
    assert manifest.kfs_version == KFS_MANIFEST_VERSION
    assert len(manifest.objects) == 1
    assert manifest.objects[0].id == "obj1"
    assert manifest.geometries["sphere_geo"].radius == 1.0
    assert manifest.materials["red_material"].color.r == 255

def test_load_kfs_manifest_full_data_success(tmp_path, full_valid_manifest_data):
    """Loads a full valid manifest including animation successfully."""
    file_path = tmp_path / "full_manifest.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(full_valid_manifest_data, f, indent=2)

    manifest = load_kfs_manifest(file_path)
    assert isinstance(manifest, KFSManifest)
    assert manifest.name == full_valid_manifest_data["name"]
    assert manifest.description == full_valid_manifest_data["description"]
    assert "cube_geo" in manifest.geometries
    assert isinstance(manifest.geometries["cube_geo"], CubeGeometry)
    assert "blue_material" in manifest.materials
    assert len(manifest.objects) == 1
    obj = manifest.objects[0]
    assert obj.id == "animated_obj"
    assert obj.animation is not None
    assert len(obj.animation.tracks) == 1
    track = obj.animation.tracks[0]
    assert track.target == "position.x"
    assert len(track.keyframes) == 2
    assert track.keyframes[0].value == 0.0
    assert track.keyframes[1].value == 5.0
    assert "gravity" in manifest.simulation_settings


def test_load_kfs_manifest_file_not_found(tmp_path):
    """Raises FileNotFoundError for a non-existent file."""
    non_existent_path = tmp_path / "non_existent.yaml"
    with pytest.raises(FileNotFoundError) as excinfo:
        load_kfs_manifest(non_existent_path)
    assert "Manifest file not found" in str(excinfo.value)

def test_load_kfs_manifest_malformed_yaml(tmp_path):
    """Raises InvalidKFSManifestError for syntactically incorrect YAML."""
    file_path = tmp_path / "malformed.yaml"
    # An invalid YAML structure that yaml.safe_load will fail on
    file_path.write_text("key: - value\n  - another_value")
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        load_kfs_manifest(file_path)
    assert "Malformed YAML content" in str(excinfo.value)

def test_load_kfs_manifest_malformed_json(tmp_path):
    """Raises InvalidKFSManifestError for syntactically incorrect JSON."""
    file_path = tmp_path / "malformed.json"
    file_path.write_text("{'key': 'value'") # Invalid JSON (single quotes)
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        load_kfs_manifest(file_path)
    assert "Malformed JSON content" in str(excinfo.value)

def test_load_kfs_manifest_unsupported_extension(tmp_path):
    """Raises InvalidKFSManifestError for unsupported file extension."""
    file_path = tmp_path / "unsupported.txt"
    file_path.write_text("some content")
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        load_kfs_manifest(file_path)
    assert "Unsupported file extension" in str(excinfo.value)

def test_load_kfs_manifest_empty_file(tmp_path):
    """Raises InvalidKFSManifestError for an empty file (YAML/JSON loaders return None)."""
    file_path = tmp_path / "empty.yaml"
    file_path.write_text("")
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        load_kfs_manifest(file_path)
    assert "content is not a valid dictionary" in str(excinfo.value)

def test_load_kfs_manifest_invalid_root_type(tmp_path):
    """Raises InvalidKFSManifestError if root is not a dict."""
    file_path = tmp_path / "not_dict.yaml"
    file_path.write_text("- item1\n- item2") # List instead of dict
    with pytest.raises(InvalidKFSManifestError) as excinfo:
        load_kfs_manifest(file_path)
    assert "content is not a valid dictionary" in str(excinfo.value)

def test_load_kfs_manifest_validation_error_missing_field(tmp_path):
    """Raises KFSManifestValidationError for missing required fields."""
    bad_data = {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Missing Objects Field"
        # 'objects' field is missing, which is required
    }
    file_path = tmp_path / "invalid_manifest.yaml"
    with open(file_path, "w", encoding="utf-8") as f:
        yaml.dump(bad_data, f)

    with pytest.raises(KFSManifestValidationError) as excinfo:
        load_kfs_manifest(file_path)
    assert "KFS manifest validation failed" in str(excinfo.value)
    assert "'objects': Field required" in str(excinfo.value)

def test_load_kfs_manifest_validation_error_invalid_type(tmp_path):
    """Raises KFSManifestValidationError for fields with invalid types."""
    bad_data = {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Test",
        "objects": "not a list" # Should be a list
    }
    file_path = tmp_path / "invalid_type.yaml"
    with open(file_path, "w", encoding="utf-8") as f:
        yaml.dump(bad_data, f)

    with pytest.raises(KFSManifestValidationError) as excinfo:
        load_kfs_manifest(file_path)
    assert "KFS manifest validation failed" in str(excinfo.value)
    assert "'objects': Input should be a valid list" in str(excinfo.value)

def test_load_kfs_manifest_version_mismatch(tmp_path, minimal_valid_manifest_data):
    """Raises ManifestVersionMismatchError for incompatible major version."""
    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["kfs_version"] = "2.0.0" # Incompatible major version
    file_path = tmp_path / "version_mismatch.yaml"
    with open(file_path, "w", encoding="utf-8") as f:
        yaml.dump(manifest_data, f)

    with pytest.raises(ManifestVersionMismatchError) as excinfo:
        load_kfs_manifest(file_path)
    assert "is incompatible with parser version" in str(excinfo.value)


# --- Test save_kfs_manifest ---

def test_save_kfs_manifest_yaml_success(tmp_path, manifest_instance):
    """Saves a manifest to a YAML file and verifies content."""
    output_path = tmp_path / "output.yaml"
    save_kfs_manifest(manifest_instance, output_path)

    assert output_path.exists()
    loaded_data = yaml.safe_load(output_path.read_text(encoding="utf-8"))

    # Pydantic's model_dump uses by_alias=True and excludes_none=True by default for manifest_parser.save_kfs_manifest
    # for cleaner output.
    expected_data = manifest_instance.model_dump(by_alias=True, exclude_none=True)

    # Compare specific fields as yaml.safe_load might retain 'null' for Optional fields omitted by model_dump.
    assert loaded_data["kfs_version"] == expected_data["kfs_version"]
    assert loaded_data["name"] == expected_data["name"]
    assert len(loaded_data["objects"]) == len(expected_data["objects"])
    assert loaded_data["geometries"]["sphere_geo"]["radius"] == expected_data["geometries"]["sphere_geo"]["radius"]

def test_save_kfs_manifest_json_success(tmp_path, manifest_instance):
    """Saves a manifest to a JSON file and verifies content."""
    output_path = tmp_path / "output.json"
    save_kfs_manifest(manifest_instance, output_path)

    assert output_path.exists()
    loaded_data = json.loads(output_path.read_text(encoding="utf-8"))

    expected_data = manifest_instance.model_dump(by_alias=True, exclude_none=True)
    assert loaded_data["kfs_version"] == expected_data["kfs_version"]
    assert loaded_data["name"] == expected_data["name"]
    assert len(loaded_data["objects"]) == len(expected_data["objects"])

def test_save_kfs_manifest_explicit_format(tmp_path, manifest_instance):
    """Saves a manifest using an explicitly specified format, overriding extension."""
    # Save as JSON, despite .yaml extension
    output_path_json = tmp_path / "output.yaml"
    save_kfs_manifest(manifest_instance, output_path_json, format="json")
    assert output_path_json.exists()
    # Check if it's valid JSON
    loaded_json = json.loads(output_path_json.read_text(encoding="utf-8"))
    assert loaded_json["name"] == manifest_instance.name
    assert loaded_json["kfs_version"] == manifest_instance.kfs_version

    # Save as YAML, despite .json extension
    output_path_yaml = tmp_path / "output.json"
    save_kfs_manifest(manifest_instance, output_path_yaml, format="yaml")
    assert output_path_yaml.exists()
    # Check if it's valid YAML
    loaded_yaml = yaml.safe_load(output_path_yaml.read_text(encoding="utf-8"))
    assert loaded_yaml["name"] == manifest_instance.name
    assert loaded_yaml["kfs_version"] == manifest_instance.kfs_version

def test_save_kfs_manifest_uninferable_format_no_explicit(tmp_path, manifest_instance):
    """Raises ValueError if format cannot be inferred from extension and is not specified."""
    output_path = tmp_path / "output.txt"
    with pytest.raises(ValueError) as excinfo:
        save_kfs_manifest(manifest_instance, output_path)
    assert "Could not infer output format from file extension" in str(excinfo.value)

def test_save_kfs_manifest_creates_parent_directories(tmp_path, manifest_instance):
    """Verifies that save_kfs_manifest creates necessary parent directories."""
    nested_dir = tmp_path / "a" / "b" / "c"
    output_path = nested_dir / "output.yaml"
    save_kfs_manifest(manifest_instance, output_path)
    assert output_path.exists()
    assert nested_dir.is_dir()
