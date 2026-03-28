import pytest
from pathlib import Path
import json

from src.kfs_manifest.parser import parse_kfs_manifest
from src.kfs_manifest.models import KineticSculptureManifest, Metadata, SimulationParameters # Assuming these will be fully defined

# Path to the example manifest file relative to the project root
EXAMPLE_MANIFEST_PATH = Path(__file__).parent.parent / "examples" / "simple_sculpture.kfs.yaml"

def test_example_manifest_is_valid():
    """
    Verifies that the example manifest file 'examples/simple_sculpture.kfs.yaml'
    can be successfully parsed and validated against the KFS schema.
    """
    manifest = parse_kfs_manifest(EXAMPLE_MANIFEST_PATH)
    assert manifest is not None, f"Example manifest '{EXAMPLE_MANIFEST_PATH}' failed to parse or validate."
    assert manifest.version == "1.0"
    assert manifest.metadata.name == "Simple Kinetic Sculpture"
    assert len(manifest.geometries) == 1
    assert len(manifest.materials) == 1
    assert len(manifest.objects) == 1
    assert len(manifest.animations) == 0
    assert manifest.simulations.gravity.y == -9.81

def test_documentation_reflects_schema_structure():
    """
    Performs a basic check to ensure that the core structure documented in
    'docs/manifest_spec.md' is reflected in the Pydantic schema generated
    by KineticSculptureManifest. This test checks for presence of key fields
    and basic types/descriptions, rather than parsing markdown directly.
    """
    schema = KineticSculptureManifest.model_json_schema()

    # Check top-level required properties as per documentation
    expected_top_level_keys = [
        "version",
        "metadata",
        "geometries",
        "materials",
        "objects",
        "animations",
        "simulations"
    ]

    for key in expected_top_level_keys:
        assert key in schema["properties"], f"Missing top-level property '{key}' in schema, but documented."

    # --- Check 'version' field ---
    version_prop = schema["properties"]["version"]
    assert version_prop["type"] == "string"
    assert version_prop["description"] == "The schema version this manifest adheres to."
    assert version_prop["const"] == "1.0", "Version should be fixed to '1.0'."

    # --- Check 'metadata' structure ---
    metadata_prop = schema["properties"]["metadata"]
    assert "description" in metadata_prop, "Metadata property should have a description."
    assert "$ref" in metadata_prop, "Metadata should reference a definition."

    # Resolve metadata definition
    metadata_def_key = metadata_prop["$ref"].split("/")[-1]
    metadata_definition = schema["$defs"].get(metadata_def_key)
    assert metadata_definition is not None, f"Definition for '{metadata_def_key}' (Metadata) not found."

    assert "name" in metadata_definition["properties"], "Metadata definition missing 'name' field."
    assert metadata_definition["properties"]["name"]["type"] == "string"
    assert metadata_definition["properties"]["name"]["description"] == "A human-readable name for the sculpture."

    assert "description" in metadata_definition["properties"], "Metadata definition missing 'description' field."
    assert metadata_definition["properties"]["description"]["type"] == "string"
    assert metadata_definition["properties"]["description"]["description"] == "A brief description of the sculpture's design or purpose."

    # --- Check 'geometries' as an array ---
    geometries_prop = schema["properties"]["geometries"]
    assert geometries_prop["type"] == "array", "Geometries should be an array."
    assert "description" in geometries_prop, "Geometries property should have a description."

    # --- Check 'materials' as an array ---
    materials_prop = schema["properties"]["materials"]
    assert materials_prop["type"] == "array", "Materials should be an array."
    assert "description" in materials_prop, "Materials property should have a description."

    # --- Check 'objects' as an array ---
    objects_prop = schema["properties"]["objects"]
    assert objects_prop["type"] == "array", "Objects should be an array."
    assert "description" in objects_prop, "Objects property should have a description."

    # --- Check 'animations' as an array ---
    animations_prop = schema["properties"]["animations"]
    assert animations_prop["type"] == "array", "Animations should be an array."
    assert animations_prop["description"] == "Placeholder for future animation definitions."

    # --- Check 'simulations' structure ---
    simulations_prop = schema["properties"]["simulations"]
    assert "description" in simulations_prop, "Simulations property should have a description."
    assert "$ref" in simulations_prop, "Simulations should reference a definition."

    # Resolve simulations definition
    simulations_def_key = simulations_prop["$ref"].split("/")[-1]
    simulations_definition = schema["$defs"].get(simulations_def_key)
    assert simulations_definition is not None, f"Definition for '{simulations_def_key}' (SimulationParameters) not found."

    assert "gravity" in simulations_definition["properties"], "Simulation definition missing 'gravity' field."
    assert "solver" in simulations_definition["properties"], "Simulation definition missing 'solver' field."
    assert "timestep" in simulations_definition["properties"], "Simulation definition missing 'timestep' field."

    assert simulations_definition["properties"]["gravity"]["$ref"].endswith("Vector3"), "Gravity should reference Vector3."
    assert simulations_definition["properties"]["solver"]["type"] == "string"
    assert simulations_definition["properties"]["timestep"]["type"] == "number"