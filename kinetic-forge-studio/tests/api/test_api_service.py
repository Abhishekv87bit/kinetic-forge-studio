
import pytest
from fastapi.testclient import TestClient

# Assuming 'app' is the FastAPI instance exposed by main.py
from backend.kfs_manifest.api.main import app

client = TestClient(app)

# --- Test cases for /validate-manifest ---

def test_validate_manifest_valid_input():
    """Test with a minimal, valid KFS manifest."""
    valid_manifest = """
kfs_version: "1.0"
manifest_name: "test_manifest_valid"
metadata:
  description: "A simple valid manifest for testing."
components: []
    """
    response = client.post("/validate-manifest", json={"manifest_content": valid_manifest})
    assert response.status_code == 200
    assert response.json()["is_valid"] is True
    assert response.json()["errors"] == []

def test_validate_manifest_invalid_schema_extra_field():
    """Test with a manifest that has an extra, unknown field in a component."""
    invalid_manifest = """
kfs_version: "1.0"
manifest_name: "test_manifest_invalid_schema"
metadata:
  description: "Manifest with an extra field."
components:
  - name: "component1"
    type: "Part"
    geometry:
      format: "STEP"
      path: "path/to/part.step"
    extra_field: "this should not be here" # Extra field
    """
    response = client.post("/validate-manifest", json={"manifest_content": invalid_manifest})
    assert response.status_code == 200
    assert response.json()["is_valid"] is False
    assert any("extra fields not permitted" in error for error in response.json()["errors"])

def test_validate_manifest_missing_required_field():
    """Test with a manifest missing a top-level required field (e.g., kfs_version)."""
    invalid_manifest = """
manifest_name: "test_manifest_missing_kfs_version"
metadata:
  description: "Missing kfs_version."
components: []
    """
    response = client.post("/validate-manifest", json={"manifest_content": invalid_manifest})
    assert response.status_code == 200
    assert response.json()["is_valid"] is False
    assert any("field required" in error for error in response.json()["errors"])

def test_validate_manifest_empty_content():
    """Test with an empty manifest content string."""
    response = client.post("/validate-manifest", json={"manifest_content": ""})
    assert response.status_code == 200
    assert response.json()["is_valid"] is False
    # Expecting an error from the parser indicating empty document
    assert any("Document is empty" in error for error in response.json()["errors"])

def test_validate_manifest_malformed_yaml():
    """Test with a manifest containing malformed YAML syntax."""
    malformed_manifest = """
kfs_version: "1.0"
manifest_name: "test_malformed_yaml"
components:
  - name: "comp1"
    type: "Part"
    geometry:
      format: "STEP"
      path: "path/to/model.step"
invalid_indentation: "should_fail" # Malformed YAML line
    """
    response = client.post("/validate-manifest", json={"manifest_content": malformed_manifest})
    assert response.status_code == 200
    assert response.json()["is_valid"] is False
    # Expecting an error from the parser due to YAML syntax issues
    assert any("Invalid YAML format" in error or "could not be parsed" in error for error in response.json()["errors"])

# --- Test cases for /parse-manifest ---

def test_parse_manifest_valid_input():
    """Test parsing a valid and well-formed KFS manifest."""
    valid_manifest = """
kfs_version: "1.0"
manifest_name: "test_manifest_parse_valid"
metadata:
  description: "A simple valid manifest for parsing."
  tags: ["test", "api"]
components:
  - name: "part_a"
    type: "Part"
    geometry:
      format: "STEP"
      path: "models/part_a.step"
      scale: 1.0
    assembly_properties:
      parent_frame: "world"
      transform:
        type: "relative"
        x: 0.0
        y: 0.0
        z: 0.0
        qx: 0.0
        qy: 0.0
        qz: 0.0
        qw: 1.0
    """
    response = client.post("/parse-manifest", json={"manifest_content": valid_manifest})
    assert response.status_code == 200
    parsed_data = response.json()["parsed_data"]
    assert parsed_data is not None
    assert parsed_data["kfs_version"] == "1.0"
    assert parsed_data["manifest_name"] == "test_manifest_parse_valid"
    assert "description" in parsed_data["metadata"]
    assert len(parsed_data["components"]) == 1
    assert parsed_data["components"][0]["name"] == "part_a"
    assert response.json()["errors"] == [] # Expect no errors in the result structure

def test_parse_manifest_invalid_schema_type_error():
    """Test parsing a manifest with a schema validation type error (e.g., string for float)."""
    invalid_schema_manifest = """
kfs_version: "1.0"
manifest_name: "test_manifest_invalid_schema_type"
metadata:
  description: "Invalid schema type for parsing."
components:
  - name: "part_b"
    type: "Part"
    geometry:
      format: "STEP"
      path: "models/part_b.step"
      scale: "not_a_number" # Invalid type for scale
    """
    response = client.post("/parse-manifest", json={"manifest_content": invalid_schema_manifest})
    assert response.status_code == 400 # Expecting 400 due to Pydantic ValidationError
    assert "Validation Error" in response.json()["detail"]["message"]
    assert any("Input should be a valid number" in error["msg"] for error in response.json()["detail"]["errors"])

def test_parse_manifest_malformed_yaml():
    """Test parsing a manifest with malformed YAML syntax."""
    malformed_manifest = """
kfs_version: "1.0"
manifest_name: "test_parse_malformed_yaml"
components:
  - name: "comp1"
    type: "Part"
    geometry:
      format: "STEP"
      path: "path/to/model.step"
invalid_indentation: "should_fail" # Malformed YAML
    """
    response = client.post("/parse-manifest", json={"manifest_content": malformed_manifest})
    assert response.status_code == 400 # Expecting 400 for unparseable YAML
    assert "Invalid YAML format" in response.json()["detail"] or "could not be parsed" in response.json()["detail"] # or similar error message for YAML parsing

def test_parse_manifest_empty_content():
    """Test parsing an empty manifest content string."""
    response = client.post("/parse-manifest", json={"manifest_content": ""})
    assert response.status_code == 400 # Expecting 400 for empty content, as parsing will fail
    assert "Document is empty" in response.json()["detail"]
