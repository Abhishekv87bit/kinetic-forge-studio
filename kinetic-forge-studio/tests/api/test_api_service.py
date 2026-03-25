
import pytest
from fastapi.testclient import TestClient
from backend.kfs_manifest.api.main import app

client = TestClient(app)

# --- Test Cases for Valid Manifests ---

def test_validate_manifest_success():
    """
    Test that a valid KFS manifest is successfully validated by the API.
    """
    valid_manifest_yaml = """
kfs_manifest:
  version: "1.0"
  system:
    name: "SimpleSystem"
    description: "A minimal valid system for testing."
    components: []
"""
    response = client.post(
        "/api/v1/manifest/validate",
        json={"manifest_content": valid_manifest_yaml}
    )

    assert response.status_code == 200
    response_data = response.json()
    assert response_data["status"] == "success"
    assert response_data["message"] == "Manifest is valid."
    assert "errors" not in response_data or response_data["errors"] is None

def test_validate_manifest_with_simple_component_success():
    """
    Test that a valid KFS manifest with a simple component is successfully validated.
    """
    valid_manifest_yaml = """
kfs_manifest:
  version: "1.0"
  system:
    name: "SystemWithComponent"
    description: "A system with a basic component."
    components:
      - name: "Motor1"
        type: "Motor"
        description: "A simple motor component."
"""
    response = client.post(
        "/api/v1/manifest/validate",
        json={"manifest_content": valid_manifest_yaml}
    )

    assert response.status_code == 200
    response_data = response.json()
    assert response_data["status"] == "success"
    assert response_data["message"] == "Manifest is valid."
    assert "errors" not in response_data or response_data["errors"] is None

# --- Test Cases for Invalid Manifests (content-wise) ---

def test_validate_manifest_invalid_version():
    """
    Test that a KFS manifest with an unsupported version is correctly flagged as invalid.
    """
    invalid_manifest_yaml = """
kfs_manifest:
  version: "2.0" # Assuming 2.0 is not supported by the schema
  system:
    name: "InvalidVersionSystem"
    description: "System with an unsupported manifest version."
    components: []
"""
    response = client.post(
        "/api/v1/manifest/validate",
        json={"manifest_content": invalid_manifest_yaml}
    )

    assert response.status_code == 200 # Service processed the request, but content is invalid
    response_data = response.json()
    assert response_data["status"] == "error"
    assert "Manifest validation failed." in response_data["message"]
    assert len(response_data["errors"]) > 0
    # Check for specific error related to version
    version_error_found = False
    for error in response_data["errors"]:
        if "loc" in error and "version" in error["loc"] and "value is not a valid enumeration member" in error.get("msg", ""):
            version_error_found = True
            break
    assert version_error_found, "Expected error for invalid manifest version not found."


def test_validate_manifest_missing_required_field():
    """
    Test that a KFS manifest missing a required field (e.g., system name) is flagged as invalid.
    """
    invalid_manifest_yaml = """
kfs_manifest:
  version: "1.0"
  system: # Missing 'name' field
    description: "System missing required name."
    components: []
"""
    response = client.post(
        "/api/v1/manifest/validate",
        json={"manifest_content": invalid_manifest_yaml}
    )

    assert response.status_code == 200
    response_data = response.json()
    assert response_data["status"] == "error"
    assert "Manifest validation failed." in response_data["message"]
    assert len(response_data["errors"]) > 0
    # Check for specific error related to missing 'name'
    name_error_found = False
    for error in response_data["errors"]:
        if "loc" in error and "system" in error["loc"] and "name" in error["loc"] and "field required" in error.get("msg", ""):
            name_error_found = True
            break
    assert name_error_found, "Expected error for missing 'system.name' not found."

def test_validate_manifest_invalid_data_type():
    """
    Test that a KFS manifest with an invalid data type for a field is flagged as invalid.
    """
    invalid_manifest_yaml = """
kfs_manifest:
  version: "1.0"
  system:
    name: 123 # Name should be string, not int
    description: "System with invalid name type."
    components: []
"""
    response = client.post(
        "/api/v1/manifest/validate",
        json={"manifest_content": invalid_manifest_yaml}
    )

    assert response.status_code == 200
    response_data = response.json()
    assert response_data["status"] == "error"
    assert "Manifest validation failed." in response_data["message"]
    assert len(response_data["errors"]) > 0
    # Check for specific error related to 'name' type
    type_error_found = False
    for error in response_data["errors"]:
        if "loc" in error and "system" in error["loc"] and "name" in error["loc"] and "string type expected" in error.get("msg", ""):
            type_error_found = True
            break
    assert type_error_found, "Expected error for invalid 'system.name' type not found."

# --- Test Cases for API request payload validation ---

def test_validate_manifest_missing_payload_field():
    """
    Test that sending a request with a missing 'manifest_content' field results in a 422 error.
    """
    response = client.post(
        "/api/v1/manifest/validate",
        json={"some_other_field": "content"} # Missing 'manifest_content'
    )

    assert response.status_code == 422 # FastAPI Pydantic validation error for the request body
    response_data = response.json()
    assert "detail" in response_data
    assert any("field required" in err["msg"] and "manifest_content" in err["loc"] for err in response_data["detail"])

def test_validate_manifest_malformed_payload_type():
    """
    Test that sending a request with 'manifest_content' as a non-string type results in a 422 error.
    """
    response = client.post(
        "/api/v1/manifest/validate",
        json={"manifest_content": 12345} # manifest_content should be a string
    )

    assert response.status_code == 422
    response_data = response.json()
    assert "detail" in response_data
    assert any("string type expected" in err["msg"] and "manifest_content" in err["loc"] for err in response_data["detail"])

def test_validate_manifest_empty_payload():
    """
    Test that sending an empty JSON payload results in a 422 error.
    """
    response = client.post(
        "/api/v1/manifest/validate",
        json={}
    )

    assert response.status_code == 422
    response_data = response.json()
    assert "detail" in response_data
    assert any("field required" in err["msg"] and "manifest_content" in err["loc"] for err in response_data["detail"])

def test_validate_manifest_non_json_payload():
    """
    Test that sending a non-JSON payload results in a 422 error.
    FastAPI typically handles this as a 422 for malformed JSON body due to Pydantic parsing.
    """
    response = client.post(
        "/api/v1/manifest/validate",
        content="This is not JSON",
        headers={"Content-Type": "text/plain"}
    )

    assert response.status_code == 422 # FastAPI expects JSON body by default for pydantic models
    response_data = response.json()
    assert "detail" in response_data
    assert any("JSON decode error" in err["msg"] for err in response_data["detail"])
