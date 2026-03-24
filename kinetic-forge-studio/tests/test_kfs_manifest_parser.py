
import pytest
import yaml
from backend.kfs_manifest_parser import KFSManifestParser
from backend.kfs_manifest_types import KFSManifest, GeometrySpec, SimulationSpec

@pytest.fixture
def parser():
    """Provides a KFSManifestParser instance for tests."""
    return KFSManifestParser()

# --- Test Cases for Valid Manifests ---

def test_parse_valid_manifest(parser):
    """Tests parsing of a well-formed KFS manifest."""
    valid_yaml_content = """
geometry:
  type: "cube"
  parameters:
    side_length: 1.0
    material: "steel"
simulation:
  type: "kinematic_chain"
  parameters:
    duration: 10.0
    steps: 100
    sensors:
      - type: "position"
        location: [0,0,0]
      - type: "velocity"
        frequency: 1000
"""
    manifest = parser.parse_manifest(valid_yaml_content)

    assert isinstance(manifest, KFSManifest)
    assert manifest.geometry.type == "cube"
    assert manifest.geometry.parameters == {"side_length": 1.0, "material": "steel"}
    assert manifest.simulation.type == "kinematic_chain"
    assert manifest.simulation.parameters == {
        "duration": 10.0,
        "steps": 100,
        "sensors": [
            {"type": "position", "location": [0, 0, 0]},
            {"type": "velocity", "frequency": 1000}
        ]
    }

def test_parse_minimal_valid_manifest(parser):
    """Tests parsing of a minimal but valid KFS manifest."""
    minimal_yaml_content = """
geometry:
  type: "sphere"
simulation:
  type: "ode_solver"
"""
    manifest = parser.parse_manifest(minimal_yaml_content)

    assert isinstance(manifest, KFSManifest)
    assert manifest.geometry.type == "sphere"
    assert manifest.geometry.parameters == {}
    assert manifest.simulation.type == "ode_solver"
    assert manifest.simulation.parameters == {}

# --- Test Cases for Invalid YAML Syntax ---

def test_parse_invalid_yaml_syntax(parser):
    """Tests handling of malformed YAML syntax."""
    invalid_yaml_content = """
geometry:
  type: "cube"
simulation:
  type: "kinematic_chain"
  parameters:  # Missing value after colon
    duration: 10.0
"""
    with pytest.raises(ValueError, match="Invalid YAML syntax:") as exc_info:
        parser.parse_manifest(invalid_yaml_content)
    assert isinstance(exc_info.value.__cause__, yaml.YAMLError)

def test_parse_empty_string(parser):
    """Tests parsing an empty string as input."""
    with pytest.raises(ValueError, match="Manifest content cannot be empty"):
        parser.parse_manifest("")

def test_parse_non_dict_root_yaml(parser):
    """Tests parsing YAML that is not a dictionary at the root."""
    non_dict_yaml = """
- item1
- item2
"""
    with pytest.raises(ValueError, match="Manifest content must be a dictionary."):
        parser.parse_manifest(non_dict_yaml)

# --- Test Cases for Invalid KFS Manifest Structure (Semantic Errors) ---

def test_parse_missing_geometry_section(parser):
    """Tests manifest missing the top-level 'geometry' section."""
    missing_geometry_yaml = """
simulation:
  type: "kinematic_chain"
  parameters:
    duration: 10.0
"""
    with pytest.raises(ValueError, match="Missing or invalid 'geometry' section."):
        parser.parse_manifest(missing_geometry_yaml)

def test_parse_missing_simulation_section(parser):
    """Tests manifest missing the top-level 'simulation' section."""
    missing_simulation_yaml = """
geometry:
  type: "cube"
  parameters:
    side_length: 1.0
"""
    with pytest.raises(ValueError, match="Missing or invalid 'simulation' section."):
        parser.parse_manifest(missing_simulation_yaml)

def test_parse_geometry_not_dict(parser):
    """Tests manifest where 'geometry' is not a dictionary."""
    geometry_not_dict_yaml = """
geometry: "not_a_dict"
simulation:
  type: "kinematic_chain"
"""
    with pytest.raises(ValueError, match="Missing or invalid 'geometry' section."):
        parser.parse_manifest(geometry_not_dict_yaml)

def test_parse_simulation_not_dict(parser):
    """Tests manifest where 'simulation' is not a dictionary."""
    simulation_not_dict_yaml = """
geometry:
  type: "cube"
simulation: "not_a_dict"
"""
    with pytest.raises(ValueError, match="Missing or invalid 'simulation' section."):
        parser.parse_manifest(simulation_not_dict_yaml)

def test_parse_missing_geometry_type(parser):
    """Tests manifest where 'geometry.type' is missing."""
    missing_type_yaml = """
geometry:
  parameters:
    side_length: 1.0
simulation:
  type: "kinematic_chain"
"""
    with pytest.raises(ValueError, match="Geometry 'type' is required."):
        parser.parse_manifest(missing_type_yaml)

def test_parse_missing_simulation_type(parser):
    """Tests manifest where 'simulation.type' is missing."""
    missing_type_yaml = """
geometry:
  type: "cube"
simulation:
  parameters:
    duration: 10.0
"""
    with pytest.raises(ValueError, match="Simulation 'type' is required."):
        parser.parse_manifest(missing_type_yaml)

def test_parse_geometry_type_not_string(parser):
    """Tests manifest where 'geometry.type' is not a string."""
    type_not_string_yaml = """
geometry:
  type: 123 # Should be a string
simulation:
  type: "kinematic_chain"
"""
    with pytest.raises(ValueError, match="Geometry 'type' must be a string."):
        parser.parse_manifest(type_not_string_yaml)

def test_parse_simulation_type_not_string(parser):
    """Tests manifest where 'simulation.type' is not a string."""
    type_not_string_yaml = """
geometry:
  type: "cube"
simulation:
  type: 123 # Should be a string
"""
    with pytest.raises(ValueError, match="Simulation 'type' must be a string."):
        parser.parse_manifest(type_not_string_yaml)

def test_parse_geometry_parameters_not_dict(parser):
    """Tests manifest where 'geometry.parameters' is not a dictionary."""
    params_not_dict_yaml = """
geometry:
  type: "cube"
  parameters: "not_a_dict"
simulation:
  type: "kinematic_chain"
"""
    with pytest.raises(ValueError, match="Geometry 'parameters' must be a dictionary."):
        parser.parse_manifest(params_not_dict_yaml)

def test_parse_simulation_parameters_not_dict(parser):
    """Tests manifest where 'simulation.parameters' is not a dictionary."""
    params_not_dict_yaml = """
geometry:
  type: "cube"
simulation:
  type: "kinematic_chain"
  parameters: "not_a_dict"
"""
    with pytest.raises(ValueError, match="Simulation 'parameters' must be a dictionary."):
        parser.parse_manifest(params_not_dict_yaml)

def test_parse_extra_top_level_field(parser):
    """Tests manifest with an extra top-level field (should be ignored or handled gracefully)."""
    extra_field_yaml = """
geometry:
  type: "cube"
simulation:
  type: "kinematic_chain"
extra_field: "should_be_ignored"
"""
    # Assuming the parser only extracts known fields and ignores unknown ones.
    # No error should be raised for this unless strict schema validation is in place.
    manifest = parser.parse_manifest(extra_field_yaml)
    assert isinstance(manifest, KFSManifest)
    assert manifest.geometry.type == "cube"
    assert manifest.simulation.type == "kinematic_chain"

def test_parse_null_values_for_optional_fields(parser):
    """Tests manifest with explicit null values for optional parameters."""
    null_params_yaml = """
geometry:
  type: "sphere"
  parameters: null
simulation:
  type: "ode_solver"
  parameters: null
"""
    manifest = parser.parse_manifest(null_params_yaml)

    assert isinstance(manifest, KFSManifest)
    assert manifest.geometry.type == "sphere"
    assert manifest.geometry.parameters == {}
    assert manifest.simulation.type == "ode_solver"
    assert manifest.simulation.parameters == {}
