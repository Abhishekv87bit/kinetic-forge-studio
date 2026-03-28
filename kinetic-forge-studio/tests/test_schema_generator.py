from unittest.mock import patch, MagicMock
import pytest
import json
from pathlib import Path

from kfs_core.schema_generator import generate_kfs_schema
from kfs_core.constants import KFS_MANIFEST_VERSION

def test_generate_kfs_schema(tmp_path):
    """
    Test that generate_kfs_schema produces a valid JSON schema file
    with expected content and structure, writing to a temporary directory.
    """

    # The schema_generator constructs its output path relative to Path(__file__).parent
    # We want Path(__file__).parent to effectively be our tmp_path for this test.
    with patch('kfs_core.schema_generator.Path') as MockPathConstructor:
        # Create a mock for the Path(__file__) instance
        mock_file_path_instance = MagicMock(spec=Path)
        # Configure its .parent property to return the actual tmp_path Path object
        mock_file_path_instance.parent = tmp_path

        # When Path() is called (e.g., Path(__file__) in schema_generator), return our mock instance
        MockPathConstructor.return_value = mock_file_path_instance

        # Determine expected file path based on KFS_MANIFEST_VERSION
        schema_version_parts = KFS_MANIFEST_VERSION.split(".")
        schema_version_major_minor = ".".join(schema_version_parts[:2])
        expected_schema_filename = f"kfs_v{schema_version_major_minor}.json"
        
        # The schema_generator will construct `tmp_path / "validator" / "schemas" / expected_schema_filename`
        expected_schema_dir = tmp_path / "validator" / "schemas"
        expected_schema_path = expected_schema_dir / expected_schema_filename

        # Call the function under test
        generated_path = generate_kfs_schema()

        # --- Assertions ---

        # 1. Verify the function returned the correct path
        assert generated_path == expected_schema_path

        # 2. Verify the schema directory and file were created
        assert expected_schema_dir.exists()
        assert expected_schema_dir.is_dir()
        assert expected_schema_path.exists()
        assert expected_schema_path.is_file()

        # 3. Load the generated JSON schema
        with open(expected_schema_path, 'r', encoding='utf-8') as f:
            schema = json.load(f)

        # 4. Basic JSON schema structure checks
        assert isinstance(schema, dict)
        assert "$id" in schema
        assert "$schema" in schema
        assert "title" in schema
        assert "description" in schema
        assert "type" in schema and schema["type"] == "object"
        assert "properties" in schema
        assert "required" in schema
        assert "$defs" in schema  # Check for definitions section

        # 5. Verify top-level specific values derived from constants
        expected_schema_id = f"https://kineticforge.studio/schemas/kfs_v{schema_version_major_minor}.json"
        expected_title = f"Kinetic Forge Studio Manifest Schema v{schema_version_major_minor}"
        expected_description = "Schema for defining kinetic sculpture projects in KFS."

        assert schema["$id"] == expected_schema_id
        assert schema["$schema"] == "http://json-schema.org/draft-07/schema#"
        assert schema["title"] == expected_title
        assert schema["description"] == expected_description

        # 6. Verify KFSManifest's main properties
        manifest_properties = schema["properties"]
        assert "kfs_version" in manifest_properties
        assert manifest_properties["kfs_version"]["type"] == "string"
        assert manifest_properties["kfs_version"]["default"] == KFS_MANIFEST_VERSION

        assert "name" in manifest_properties
        assert manifest_properties["name"]["type"] == "string"

        assert "objects" in manifest_properties
        assert manifest_properties["objects"]["type"] == "array"
        assert "$ref" in manifest_properties["objects"]["items"]
        assert manifest_properties["objects"]["items"]["$ref"] == "#/$defs/KFSObject"
        assert manifest_properties["objects"]["minItems"] == 1

        assert "geometries" in manifest_properties
        assert manifest_properties["geometries"]["type"] == "object"
        assert "$ref" in manifest_properties["geometries"]["additionalProperties"]
        assert manifest_properties["geometries"]["additionalProperties"]["$ref"] == "#/$defs/Geometry"

        assert "materials" in manifest_properties
        assert manifest_properties["materials"]["type"] == "object"
        assert "$ref" in manifest_properties["materials"]["additionalProperties"]
        assert manifest_properties["materials"]["additionalProperties"]["$ref"] == "#/$defs/Material"

        # 7. Verify required fields of KFSManifest
        assert sorted(schema["required"]) == sorted(["kfs_version", "name", "objects"])

        # 8. Verify key definitions are present in $defs section
        defs = schema["$defs"]
        expected_def_keys = [
            "RGBColor", "BaseGeometry", "SphereGeometry", "CubeGeometry", "MeshGeometry", "Geometry",
            "Material", "Transform", "Keyframe", "AnimationTrack", "KFSObject",
            "EulerRotation", "AxisAngleRotation", "QuaternionRotation"
        ]
        for key in expected_def_keys:
            assert key in defs, f"Missing definition for {key} in $defs"

        # 9. Deeper check for discriminated unions (e.g., Geometry, Transform)
        geometry_def = defs.get("Geometry")
        assert geometry_def is not None
        assert "oneOf" in geometry_def
        assert "discriminator" in geometry_def
        assert geometry_def["discriminator"]["propertyName"] == "type"
        assert geometry_def["discriminator"]["mapping"] == {
            "cube": "#/$defs/CubeGeometry",
            "mesh": "#/$defs/MeshGeometry",
            "sphere": "#/$defs/SphereGeometry",
        }

        transform_def = defs.get("Transform")
        assert transform_def is not None
        assert "oneOf" in transform_def
        assert "discriminator" in transform_def
        assert transform_def["discriminator"]["propertyName"] == "type"
        assert transform_def["discriminator"]["mapping"] == {
            "axis_angle": "#/$defs/AxisAngleRotation",
            "euler": "#/$defs/EulerRotation",
            "quaternion": "#/$defs/QuaternionRotation",
        }
