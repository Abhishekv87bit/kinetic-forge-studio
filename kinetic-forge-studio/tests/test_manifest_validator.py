import pytest
import json
import yaml
from pathlib import Path
from unittest.mock import patch, MagicMock

from kfs_core.validator.manifest_validator import KFSManifestValidator
from kfs_core.exceptions import (
    KFSManifestValidationError,
    ManifestVersionMismatchError,
    InvalidKFSManifestError,
    KFSBaseError
)
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_core.manifest_models import KFSManifest # For type hinting and understanding structure
from kfs_core.schema_generator import generate_kfs_schema # To ensure schema exists for validation

from kfs_core.validator.rules import (
    SemanticValidationError,
    _check_duplicates_in_list,
    _check_referenced_ids_exist
)


# --- Fixtures ---

@pytest.fixture(scope="module")
def kfs_schema_path(tmp_path_factory):
    """
    Generates the KFS JSON schema into a temporary directory
    and returns the path to the schema file.
    This uses tmp_path_factory for a session/module-scoped temporary path.
    """
    schema_tmp_dir = tmp_path_factory.mktemp("kfs_schemas")
    
    # Mock Path(__file__).parent to point to our temporary directory for schema generation
    with patch('kfs_core.schema_generator.Path') as MockPathConstructor:
        mock_file_path_instance = MagicMock(spec=Path)
        mock_file_path_instance.parent = schema_tmp_dir
        MockPathConstructor.return_value = mock_file_path_instance

        generated_schema_path = generate_kfs_schema()
        assert generated_schema_path.exists()
        yield generated_schema_path

@pytest.fixture
def manifest_validator(kfs_schema_path):
    """Provides a KFSManifestValidator instance configured with the generated schema."""
    return KFSManifestValidator(schema_path=kfs_schema_path)

@pytest.fixture
def minimal_valid_manifest_data():
    """Returns a dictionary for a minimal valid KFS manifest."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Minimal Sculpture",
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
def complex_valid_manifest_data():
    """Returns a dictionary for a more complex valid KFS manifest."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Complex Animated Sculpture",
        "description": "A sculpture with multiple objects, varied geometries, materials, and animation.",
        "geometries": {
            "sphere01": {"type": "sphere", "id": "sphere01", "radius": 0.5},
            "cube01": {"type": "cube", "id": "cube01", "size": 1.0},
            "mesh01": {"type": "mesh", "id": "mesh01", "path": "assets/model.obj"}
        },
        "materials": {
            "red_glossy": {"id": "red_glossy", "color": {"r": 255, "g": 0, "b": 0}, "roughness": 0.2, "metallic": 0.8},
            "blue_matte": {"id": "blue_matte", "color": {"r": 0, "g": 0, "b": 255}, "roughness": 0.8, "metallic": 0.1},
            "green_glass": {"id": "green_glass", "color": {"r": 0, "g": 255, "b": 0}, "opacity": 0.5}
        },
        "objects": [
            {
                "id": "obj_sphere_anim",
                "geometry_id": "sphere01",
                "material_id": "red_glossy",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
                "animation": {
                    "tracks": [
                        {"property": "position.x", "keyframes": [
                            {"time": 0.0, "value": 0.0},
                            {"time": 1.0, "value": 1.0}
                        ]},
                        {"property": "rotation.y", "keyframes": [
                            {"time": 0.0, "value": 0.0},
                            {"time": 1.0, "value": 90.0}
                        ]}
                    ]
                }
            },
            {
                "id": "obj_cube_static",
                "geometry_id": "cube01",
                "material_id": "blue_matte",
                "transform": {"position": [2, 1, 0], "rotation": [0, 45, 0], "scale": [1.2, 1.2, 1.2]}
            },
            {
                "id": "obj_mesh_anim",
                "geometry_id": "mesh01",
                "material_id": "green_glass",
                "transform": {"position": [-1, 0, 1], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
                "animation": {
                    "tracks": [
                        {"property": "scale.z", "keyframes": [
                            {"time": 0.0, "value": 1.0},
                            {"time": 0.5, "value": 1.5},
                            {"time": 1.0, "value": 1.0}
                        ]}
                    ]
                }
            }
        ],
        "simulation_settings": {
            "gravity": [0, -9.8, 0],
            "solver_steps": 100
        }
    }


@pytest.fixture
def create_manifest_file(tmp_path):
    """
    A factory fixture to create a manifest file (YAML or JSON) in a temporary directory.
    Returns a function that takes filename and data, and returns the Path to the created file.
    """
    def _create(filename: str, data: dict, format: str = "yaml") -> Path:
        file_path = tmp_path / filename
        with open(file_path, "w", encoding="utf-8") as f:
            if format == "yaml":
                yaml.dump(data, f, indent=2)
            elif format == "json":
                json.dump(data, f, indent=2)
            else:
                raise ValueError("Unsupported format. Must be 'yaml' or 'json'.")
        return file_path
    return _create

# --- Tests for SemanticValidationError (from rules.py) ---

def test_semantic_validation_error_init():
    error = SemanticValidationError(
        code="TEST_CODE",
        message="Test Message",
        path=["objects", 0, "id"],
        value="obj_a"
    )
    assert error.code == "TEST_CODE"
    assert error.message == "Test Message"
    assert error.path == ["objects", 0, "id"]
    assert error.value == "obj_a"
    
    error_minimal = SemanticValidationError(code="MINIMAL", message="Minimal message")
    assert error_minimal.path == []
    assert error_minimal.value is None

def test_semantic_validation_error_to_dict():
    error = SemanticValidationError(
        code="TEST_CODE",
        message="Test Message",
        path=["objects", 0, "id"],
        value="obj_a"
    )
    expected_dict = {
        "type": "semantic",
        "code": "TEST_CODE",
        "message": "Test Message",
        "path": "objects/0/id",
        "value": "obj_a"
    }
    assert error.to_dict() == expected_dict

    error_no_path_value = SemanticValidationError(code="NOPATH", message="No path or value")
    expected_dict_no_path_value = {
        "type": "semantic",
        "code": "NOPATH",
        "message": "No path or value",
        "path": "",
        "value": None
    }
    assert error_no_path_value.to_dict() == expected_dict_no_path_value


# --- Tests for _check_duplicates_in_list (from rules.py) ---

class MockItem:
    def __init__(self, id_val):
        self.id = id_val

def test_check_duplicates_in_list_no_duplicates():
    items = [MockItem("a"), MockItem("b"), MockItem("c")]
    errors = _check_duplicates_in_list(items, "id", "test_collection", ["path", "to", "collection"])
    assert not errors

def test_check_duplicates_in_list_with_duplicates():
    items = [MockItem("a"), MockItem("b"), MockItem("a"), MockItem("c")]
    errors = _check_duplicates_in_list(items, "id", "test_collection", ["path", "to", "collection"])
    assert len(errors) == 1
    assert errors[0].code == "DUPLICATE_TEST_COLLECTION_ID"
    assert "Duplicate ID 'a'" in errors[0].message
    assert errors[0].path == ["path", "to", "collection", 2, "id"]
    assert errors[0].value == "a"

def test_check_duplicates_in_list_multiple_duplicates():
    items = [MockItem("a"), MockItem("b"), MockItem("a"), MockItem("c"), MockItem("b")]
    errors = _check_duplicates_in_list(items, "id", "test_collection", ["path", "to", "collection"])
    assert len(errors) == 2
    # Convert errors to a set of tuples for order-independent assertion
    error_details = {(e.code, e.value) for e in errors}
    assert ("DUPLICATE_TEST_COLLECTION_ID", "a") in error_details
    assert ("DUPLICATE_TEST_COLLECTION_ID", "b") in error_details

def test_check_duplicates_in_list_missing_id_field():
    class MissingIdItem:
        pass # No 'id' attribute

    items = [MockItem("a"), MissingIdItem(), MockItem("b")]
    errors = _check_duplicates_in_list(items, "id", "test_collection", ["path", "to", "collection"])
    assert len(errors) == 1
    assert errors[0].code == "MISSING_ID"
    assert "Item in test_collection at index 1 is missing an ID." in errors[0].message
    assert errors[0].path == ["path", "to", "collection", 1]


# --- Tests for _check_referenced_ids_exist (from rules.py) ---

def test_check_referenced_ids_exist_all_exist():
    referenced_ids = ["geo1", "mat1"]
    available_ids = {"geo1", "geo2", "mat1"}
    errors = _check_referenced_ids_exist(referenced_ids, available_ids, "GEO", "Geometry", ["obj", 0, "geometry_id"])
    assert not errors

def test_check_referenced_ids_exist_one_missing():
    referenced_ids = ["geo1", "missing_geo"]
    available_ids = {"geo1", "mat1"}
    errors = _check_referenced_ids_exist(referenced_ids, available_ids, "GEO", "Geometry", ["obj", 0, "geometry_id"])
    assert len(errors) == 1
    assert errors[0].code == "MISSING_GEO_REFERENCE"
    assert "Geometry reference 'missing_geo' not found" in errors[0].message
    assert errors[0].path == ["obj", 0, "geometry_id"]
    assert errors[0].value == "missing_geo"

def test_check_referenced_ids_exist_multiple_missing():
    referenced_ids = ["geo1", "missing_geo_1", "missing_geo_2"]
    available_ids = {"geo1", "mat1"}
    errors = _check_referenced_ids_exist(referenced_ids, available_ids, "GEO", "Geometry", ["obj", 0, "geometry_id"])
    assert len(errors) == 2
    missing_values = {e.value for e in errors}
    assert "missing_geo_1" in missing_values
    assert "missing_geo_2" in missing_values
    assert errors[0].code == "MISSING_GEO_REFERENCE"
    assert errors[1].code == "MISSING_GEO_REFERENCE"

def test_check_referenced_ids_exist_empty_referenced_list():
    referenced_ids = []
    available_ids = {"geo1", "mat1"}
    errors = _check_referenced_ids_exist(referenced_ids, available_ids, "GEO", "Geometry", ["obj", 0, "geometry_id"])
    assert not errors


# --- Tests for KFSManifestValidator ---

def test_validator_init_default_schema_path(kfs_schema_path):
    # Test that validator can initialize with default path which should be resolved correctly
    # by _get_default_schema_path, given the schema generation fixture ensures one exists.
    with patch('kfs_core.validator.manifest_validator.KFSManifestValidator._get_default_schema_path', 
               return_value=kfs_schema_path):
        validator = KFSManifestValidator()
        assert validator is not None
        assert validator._schema is not None
        assert "$id" in validator._schema
        assert validator._validator is not None

def test_validator_init_custom_schema_path(kfs_schema_path):
    validator = KFSManifestValidator(schema_path=kfs_schema_path)
    assert validator is not None
    assert validator._schema is not None
    assert "$id" in validator._schema
    assert validator._validator is not None

def test_validator_init_invalid_schema_path():
    with pytest.raises(KFSBaseError, match="Schema file not found"):
        KFSManifestValidator(schema_path="/non/existent/path/schema.json")

def test_validator_init_malformed_schema_file(tmp_path):
    malformed_schema_path = tmp_path / "malformed.json"
    malformed_schema_path.write_text("{'invalid json': }") # Invalid JSON
    
    with pytest.raises(KFSBaseError, match="Invalid schema file format"):
        KFSManifestValidator(schema_path=malformed_schema_path)

def test_validate_manifest_data_valid_minimal(manifest_validator, minimal_valid_manifest_data):
    # Should not raise any exception
    try:
        manifest_validator.validate_manifest_data(minimal_valid_manifest_data)
    except KFSManifestValidationError as e:
        pytest.fail(f"Validation failed for minimal valid manifest: {e.errors}")

def test_validate_manifest_data_valid_complex(manifest_validator, complex_valid_manifest_data):
    # Should not raise any exception
    try:
        manifest_validator.validate_manifest_data(complex_valid_manifest_data)
    except KFSManifestValidationError as e:
        pytest.fail(f"Validation failed for complex valid manifest: {e.errors}")

def test_validate_manifest_data_invalid_json_schema_missing_required(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    del invalid_data["name"] # 'name' is required

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "json_schema"
    assert "name" in errors[0]["message"] # Should indicate missing 'name'
    assert "name" in errors[0]["path"] # Path should point to 'name'

def test_validate_manifest_data_invalid_json_schema_incorrect_type(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    # radius expects a number, provide a string
    invalid_data["geometries"]["sphere_geo"]["radius"] = "not_a_number"

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "json_schema"
    assert "not_a_number" in errors[0]["message"]
    assert "geometries/sphere_geo/radius" in errors[0]["path"]

def test_validate_manifest_data_invalid_json_schema_empty_objects(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["objects"] = [] # minItems is 1 for objects

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "json_schema"
    assert "[] is too short" in errors[0]["message"] # specific for minItems
    assert "objects" in errors[0]["path"]

def test_validate_manifest_data_semantic_duplicate_object_ids(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    obj_duplicate = invalid_data["objects"][0].copy()
    invalid_data["objects"].append(obj_duplicate) # Add a duplicate object ID

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "semantic"
    assert errors[0]["code"] == "DUPLICATE_OBJECTS_ID"
    assert "Duplicate ID 'obj1'" in errors[0]["message"]
    assert errors[0]["path"] == "objects/1/id" # The second 'obj1' is at index 1

def test_validate_manifest_data_semantic_duplicate_geometry_ids(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["geometries"]["sphere_geo_duplicate"] = invalid_data["geometries"]["sphere_geo"].copy()
    invalid_data["geometries"]["sphere_geo_duplicate"]["id"] = "sphere_geo" # Force duplicate ID

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "semantic"
    assert errors[0]["code"] == "DUPLICATE_GEOMETRIES_ID"
    assert "Duplicate ID 'sphere_geo'" in errors[0]["message"]
    assert errors[0]["path"] == "geometries/sphere_geo_duplicate/id" # This path points to the key in the dict where the duplicate ID is defined

def test_validate_manifest_data_semantic_missing_geometry_reference(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["objects"][0]["geometry_id"] = "non_existent_geo"

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "semantic"
    assert errors[0]["code"] == "MISSING_GEOMETRY_REFERENCE"
    assert "non_existent_geo" in errors[0]["message"]
    assert errors[0]["path"] == "objects/0/geometry_id"

def test_validate_manifest_data_semantic_missing_material_reference(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["objects"][0]["material_id"] = "non_existent_material"

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "semantic"
    assert errors[0]["code"] == "MISSING_MATERIAL_REFERENCE"
    assert "non_existent_material" in errors[0]["message"]
    assert errors[0]["path"] == "objects/0/material_id"

def test_validate_manifest_data_version_mismatch(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["kfs_version"] = "2.0.0" # Incompatible major version

    with pytest.raises(ManifestVersionMismatchError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    assert "Major versions must match" in str(excinfo.value)

def test_validate_manifest_data_missing_version_field(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    del invalid_data["kfs_version"]

    with pytest.raises(InvalidKFSManifestError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    assert "Manifest data is missing 'kfs_version'." in str(excinfo.value)

def test_validate_manifest_data_invalid_version_format(manifest_validator, minimal_valid_manifest_data):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["kfs_version"] = "1.x.0"

    with pytest.raises(InvalidKFSManifestError) as excinfo:
        manifest_validator.validate_manifest_data(invalid_data)
    
    assert "Invalid 'kfs_version' format" in str(excinfo.value)


# --- Tests for validate_manifest_file ---

def test_validate_manifest_file_valid_yaml(manifest_validator, minimal_valid_manifest_data, create_manifest_file):
    manifest_path = create_manifest_file("test_valid.yaml", minimal_valid_manifest_data, format="yaml")
    try:
        manifest_validator.validate_manifest_file(manifest_path)
    except KFSBaseError as e:
        pytest.fail(f"Validation failed for valid YAML file: {e}")

def test_validate_manifest_file_valid_json(manifest_validator, complex_valid_manifest_data, create_manifest_file):
    manifest_path = create_manifest_file("test_valid.json", complex_valid_manifest_data, format="json")
    try:
        manifest_validator.validate_manifest_file(manifest_path)
    except KFSBaseError as e:
        pytest.fail(f"Validation failed for valid JSON file: {e}")

def test_validate_manifest_file_not_found(manifest_validator, tmp_path):
    non_existent_path = tmp_path / "non_existent.yaml"
    with pytest.raises(FileNotFoundError):
        manifest_validator.validate_manifest_file(non_existent_path)

def test_validate_manifest_file_malformed_yaml(manifest_validator, tmp_path):
    malformed_content = """
kfs_version: 1.0.0
name: Malformed
objects:
- id: obj1
  geometry_id: sphere_geo
  material_id: red_material
  transform:
    position: [0,0,0]
    rotation: [0,0,0]
    scale: [1,1,1]
geometries:
sphere_geo:
    type: sphere
    id: sphere_geo
    radius: 1.0
materials:
red_material: # Missing indent here for content, should cause YAML parse error
    id: red_material
    color: {r: 255, g: 0, b: 0}
    """
    file_path = tmp_path / "malformed.yaml"
    file_path.write_text(malformed_content)

    with pytest.raises(InvalidKFSManifestError) as excinfo:
        manifest_validator.validate_manifest_file(file_path)
    assert "Invalid YAML format" in str(excinfo.value)

def test_validate_manifest_file_malformed_json(manifest_validator, tmp_path):
    malformed_content = """
    {
        "kfs_version": "1.0.0",
        "name": "Malformed JSON",
        "objects": [
            {"id": "obj1", "geometry_id": "sphere_geo", "material_id": "red_material"}
        ],
        "geometries": {
            "sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0}
        },
        "materials": {
            "red_material": {"id": "red_material", "color": {"r": 255, "g": 0, "b": 0}}
        , 
    """
    file_path = tmp_path / "malformed.json"
    file_path.write_text(malformed_content) # Trailing comma outside an array/object is strictly invalid JSON

    with pytest.raises(InvalidKFSManifestError) as excinfo:
        manifest_validator.validate_manifest_file(file_path)
    assert "Invalid JSON format" in str(excinfo.value)

def test_validate_manifest_file_json_schema_error(manifest_validator, minimal_valid_manifest_data, create_manifest_file):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["objects"] = [] # minItems is 1
    
    file_path = create_manifest_file("invalid_schema.yaml", invalid_data)

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_file(file_path)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "json_schema"
    assert "objects" in errors[0]["path"]

def test_validate_manifest_file_semantic_error(manifest_validator, minimal_valid_manifest_data, create_manifest_file):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["objects"].append(invalid_data["objects"][0].copy()) # Duplicate object
    
    file_path = create_manifest_file("invalid_semantic.yaml", invalid_data)

    with pytest.raises(KFSManifestValidationError) as excinfo:
        manifest_validator.validate_manifest_file(file_path)
    
    errors = excinfo.value.errors
    assert len(errors) == 1
    assert errors[0]["type"] == "semantic"
    assert errors[0]["code"] == "DUPLICATE_OBJECTS_ID"

def test_validate_manifest_file_version_mismatch(manifest_validator, minimal_valid_manifest_data, create_manifest_file):
    invalid_data = minimal_valid_manifest_data.copy()
    invalid_data["kfs_version"] = "2.0.0" # Incompatible version
    
    file_path = create_manifest_file("version_mismatch.yaml", invalid_data)

    with pytest.raises(ManifestVersionMismatchError) as excinfo:
        manifest_validator.validate_manifest_file(file_path)
    assert "Major versions must match" in str(excinfo.value)
