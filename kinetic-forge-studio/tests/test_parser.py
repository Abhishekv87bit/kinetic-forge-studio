
import pytest
import yaml
from pathlib import Path
from pydantic import ValidationError

# Assuming these are available as previously completed files
from backend.kfs_manifest.schema.v1.kinetic_forge_schema import (
    KineticForgeManifest, Metadata, Component, StaticGeometryComponent,
    Geometry, MeshGeometry, KineticGeometryComponent, Motion, RotationMotion, TranslationMotion,
    AssetComponent, Asset, ArbitraryDataAsset
)
from backend.kfs_manifest.asset_types import GeometryType, Units, AssetType, MotionProfile
from backend.kfs_manifest.parser import KFSParser
from backend.kfs_manifest.validator import KFSValidator
from backend.kfs_manifest.errors import KFSManifestError, InvalidManifestError

@pytest.fixture
def parser():
    """Provides a KFSParser instance for tests."""
    return KFSParser()

@pytest.fixture
def validator():
    """Provides a KFSValidator instance for tests."""
    return KFSValidator()

# --- Valid KFS YAML Examples ---
VALID_KFS_YAML_MINIMAL = """
kfs_schema_version: "v1"
metadata:
  name: "minimal_system"
  description: "A minimal valid KFS manifest."
components: []
"""

VALID_KFS_YAML_COMPLEX = """
kfs_schema_version: "v1"
metadata:
  name: "complex_system"
  description: "A complex valid KFS manifest with geometry, motion, and assets."
components:
  - name: "base_frame"
    type: "static_geometry"
    description: "The main base frame of the system."
    geometry:
      type: "mesh"
      source: "file:///assets/base_frame.stl"
      units: "mm"
  - name: "rotary_joint"
    type: "kinetic_geometry"
    description: "A rotary joint with defined motion."
    geometry:
      type: "mesh"
      source: "file:///assets/rotary_joint.obj"
      units: "m"
    motion:
      type: "rotation"
      axis: [0, 0, 1]
      origin: [0, 0, 0]
      duration_seconds: 5.0
      profile: "sine"
  - name: "linear_actuator"
    type: "kinetic_geometry"
    description: "A linear actuator with defined motion."
    geometry:
      type: "mesh"
      source: "file:///assets/actuator.gltf"
      units: "m"
    motion:
      type: "translation"
      direction: [1, 0, 0]
      distance_mm: 100.0
      duration_seconds: 2.5
      profile: "linear"
  - name: "system_config_asset"
    type: "asset"
    description: "Configuration data for the system."
    asset:
      type: "arbitrary_data"
      source: "file:///data/system_config.json"
      hash: "sha256:abcdef12345678901234567890abcdef1234567890abcdef1234567890"
"""

# --- Invalid YAML Examples (Parser specific errors) ---
INVALID_YAML_SYNTAX = """
kfs_schema_version: "v1"
  metadata:
name: "bad_indent"
components: []
"""

INVALID_YAML_EMPTY_DOCUMENT = ""

INVALID_YAML_NON_KFS_CONTENT = """
---
some_other_key: "value"
data:
  nested: 123
---
"""

# --- Invalid KFS YAML Examples (Validation errors) ---
INVALID_KFS_MISSING_VERSION_KEY = """
metadata:
  name: "missing_version_key"
components: []
"""

INVALID_KFS_UNSUPPORTED_VERSION = """
kfs_schema_version: "v2" # Unsupported version
metadata:
  name: "unsupported_version_system"
components: []
"""

INVALID_KFS_MISSING_METADATA_NAME = """
kfs_schema_version: "v1"
metadata:
  description: "Missing name field for metadata."
components: []
"""

INVALID_KFS_WRONG_TYPE_DURATION = """
kfs_schema_version: "v1"
metadata:
  name: "wrong_type_duration"
components:
  - name: "motor"
    type: "kinetic_geometry"
    geometry:
      type: "mesh"
      source: "file:///assets/motor.obj"
      units: "m"
    motion:
      type: "rotation"
      axis: [0, 0, 1]
      origin: [0, 0, 0]
      duration_seconds: "should_be_float" # Invalid type
      profile: "linear"
"""

INVALID_KFS_NEGATIVE_DURATION = """
kfs_schema_version: "v1"
metadata:
  name: "negative_duration"
components:
  - name: "motor"
    type: "kinetic_geometry"
    geometry:
      type: "mesh"
      source: "file:///assets/motor.obj"
      units: "m"
    motion:
      type: "rotation"
      axis: [0, 0, 1]
      origin: [0, 0, 0]
      duration_seconds: -10.0 # Should be non-negative
      profile: "linear"
"""

INVALID_KFS_INVALID_ENUM_UNIT = """
kfs_schema_version: "v1"
metadata:
  name: "invalid_enum_unit"
components:
  - name: "part_with_bad_unit"
    type: "static_geometry"
    geometry:
      type: "mesh"
      source: "file:///assets/part.stl"
      units: "lightyears" # Invalid enum value
"""

INVALID_KFS_DUPLICATE_COMPONENT_NAME = """
kfs_schema_version: "v1"
metadata:
  name: "duplicate_components"
components:
  - name: "common_part"
    type: "static_geometry"
    geometry:
      type: "mesh"
      source: "file:///assets/part_a.stl"
      units: "mm"
  - name: "another_part"
    type: "static_geometry"
    geometry:
      type: "mesh"
      source: "file:///assets/part_b.stl"
      units: "mm"
  - name: "common_part" # Duplicate name
    type: "kinetic_geometry"
    geometry:
      type: "mesh"
      source: "file:///assets/part_c.stl"
      units: "mm"
"""

INVALID_KFS_MISSING_REQUIRED_COMPONENT_FIELD = """
kfs_schema_version: "v1"
metadata:
  name: "missing_component_type"
components:
  - name: "missing_type_component"
    # type: "static_geometry" # Missing required field
    geometry:
      type: "mesh"
      source: "file:///assets/missing_type.stl"
      units: "mm"
"""

class TestKFSManifestProcessing:
    """
    Comprehensive tests for KFSParser and KFSValidator, covering valid and invalid
    .kfs.yaml examples for correct parsing, validation, and error reporting.
    """

    # --- Tests for Valid Manifests ---
    def test_parse_valid_minimal_yaml(self, parser):
        """Ensures a minimal valid KFS manifest can be parsed correctly."""
        manifest = parser.parse_manifest_from_string(VALID_KFS_YAML_MINIMAL)
        assert isinstance(manifest, KineticForgeManifest)
        assert manifest.kfs_schema_version == "v1"
        assert manifest.metadata.name == "minimal_system"
        assert len(manifest.components) == 0

    def test_parse_valid_complex_yaml(self, parser):
        """Ensures a complex valid KFS manifest with various components can be parsed correctly."""
        manifest = parser.parse_manifest_from_string(VALID_KFS_YAML_COMPLEX)
        assert isinstance(manifest, KineticForgeManifest)
        assert manifest.kfs_schema_version == "v1"
        assert manifest.metadata.name == "complex_system"
        assert len(manifest.components) == 4

        # Verify a static geometry component
        comp0 = manifest.components[0]
        assert isinstance(comp0, StaticGeometryComponent)
        assert comp0.name == "base_frame"
        assert comp0.type == "static_geometry"
        assert isinstance(comp0.geometry, MeshGeometry)
        assert comp0.geometry.type == GeometryType.MESH
        assert comp0.geometry.source == "file:///assets/base_frame.stl"
        assert comp0.geometry.units == Units.MM

        # Verify a kinetic geometry component (rotation)
        comp1 = manifest.components[1]
        assert isinstance(comp1, KineticGeometryComponent)
        assert comp1.name == "rotary_joint"
        assert isinstance(comp1.motion, RotationMotion)
        assert comp1.motion.type == "rotation"
        assert comp1.motion.axis == [0, 0, 1]
        assert comp1.motion.duration_seconds == 5.0
        assert comp1.motion.profile == MotionProfile.SINE

        # Verify a kinetic geometry component (translation)
        comp2 = manifest.components[2]
        assert isinstance(comp2, KineticGeometryComponent)
        assert comp2.name == "linear_actuator"
        assert isinstance(comp2.motion, TranslationMotion) # Changed to TranslationMotion
        assert comp2.motion.type == "translation"
        assert comp2.motion.distance_mm == 100.0
        assert comp2.motion.direction == [1, 0, 0]

        # Verify an asset component
        comp3 = manifest.components[3]
        assert isinstance(comp3, AssetComponent)
        assert comp3.name == "system_config_asset"
        assert isinstance(comp3.asset, ArbitraryDataAsset)
        assert comp3.asset.type == AssetType.ARBITRARY_DATA
        assert comp3.asset.source == "file:///data/system_config.json"
        assert comp3.asset.hash == "sha256:abcdef12345678901234567890abcdef1234567890abcdef1234567890"

    # --- Tests for Parser-specific Errors (Malformed YAML) ---
    def test_parse_malformed_yaml_syntax_error(self, parser):
        """Ensures parser raises KFSManifestError for YAML syntax issues."""
        with pytest.raises(KFSManifestError, match="YAML parsing error"): # More specific match
            parser.parse_manifest_from_string(INVALID_YAML_SYNTAX)

    def test_parse_empty_yaml_document(self, parser):
        """Ensures parser raises KFSManifestError for an empty YAML string."""
        with pytest.raises(KFSManifestError, match="YAML parsing error: document is empty or malformed."):
            parser.parse_manifest_from_string(INVALID_YAML_EMPTY_DOCUMENT)

    def test_parse_non_kfs_content(self, parser):
        """Ensures parser handles non-KFS YAML content by raising validation error for missing version."""
        # This will be caught by the version check in the parser, then Pydantic validation if it passes
        with pytest.raises(InvalidManifestError, match="Field required"): # Specific Pydantic error for missing version
            parser.parse_manifest_from_string(INVALID_YAML_NON_KFS_CONTENT)

    # --- Tests for Validator-specific Errors (Schema and Custom Validation) ---
    def test_parse_missing_kfs_schema_version_key(self, parser):
        """Ensures parser/validator catches missing kfs_schema_version key."""
        with pytest.raises(InvalidManifestError, match="Field required"): # Specific Pydantic error for missing version
            parser.parse_manifest_from_string(INVALID_KFS_MISSING_VERSION_KEY)

    def test_parse_unsupported_kfs_schema_version(self, parser):
        """Ensures parser/validator catches unsupported kfs_schema_version."""
        with pytest.raises(InvalidManifestError, match="Unsupported KFS manifest schema version 'v2'."):
            parser.parse_manifest_from_string(INVALID_KFS_UNSUPPORTED_VERSION)

    def test_parse_missing_metadata_name(self, parser):
        """Ensures parser/validator catches missing required field (metadata.name)."""
        with pytest.raises(InvalidManifestError, match="Field required"): # Specific Pydantic error
            parser.parse_manifest_from_string(INVALID_KFS_MISSING_METADATA_NAME)

    def test_parse_wrong_type_for_field(self, parser):
        """Ensures parser/validator catches incorrect data type for a field."""
        with pytest.raises(InvalidManifestError, match="Input should be a valid 'float'"): # Specific Pydantic error
            parser.parse_manifest_from_string(INVALID_KFS_WRONG_TYPE_DURATION)

    def test_parse_negative_duration_value(self, parser):
        """Ensures parser/validator catches non-negative constraint violation."""
        with pytest.raises(InvalidManifestError, match="Input should be greater than or equal to 0"): # Specific Pydantic error
            parser.parse_manifest_from_string(INVALID_KFS_NEGATIVE_DURATION)

    def test_parse_invalid_enum_value(self, parser):
        """Ensures parser/validator catches invalid enum values."""
        with pytest.raises(InvalidManifestError, match="Input should be 'mm', 'cm', 'm', or 'in'"): # Specific Pydantic error
            parser.parse_manifest_from_string(INVALID_KFS_INVALID_ENUM_UNIT)

    def test_parse_duplicate_component_names(self, parser):
        """Ensures parser/validator catches duplicate component names (custom validation)."""
        with pytest.raises(InvalidManifestError, match="Duplicate component name 'common_part' found"): # Specific KFS custom validation error
            parser.parse_manifest_from_string(INVALID_KFS_DUPLICATE_COMPONENT_NAME)

    def test_parse_missing_required_component_field(self, parser):
        """Ensures parser/validator catches missing required fields within a component."""
        with pytest.raises(InvalidManifestError, match="Field required"): # Specific Pydantic error
            parser.parse_manifest_from_string(INVALID_KFS_MISSING_REQUIRED_COMPONENT_FIELD)

    # --- Direct KFSValidator tests (for additional KFS-specific logic and error wrapping) ---
    def test_validator_valid_manifest(self, parser, validator):
        """Ensures validator passes a valid manifest without errors."""
        manifest = parser.parse_manifest_from_string(VALID_KFS_YAML_COMPLEX)
        # This explicitly calls the KFSValidator's public method.
        # It should not raise an error for a valid manifest.
        validator.validate_manifest(manifest)

    def test_validator_errors_are_wrapped(self, parser, validator):
        """Ensures KFSValidator wraps Pydantic ValidationErrors into InvalidManifestError."""
        # We'll use an invalid YAML string that would normally cause a Pydantic ValidationError.
        # The parser's call to validate_manifest should ensure it's wrapped.
        with pytest.raises(InvalidManifestError) as exc_info:
            parser.parse_manifest_from_string(INVALID_KFS_MISSING_METADATA_NAME)
        # Verify the top-level error type
        assert isinstance(exc_info.value, InvalidManifestError)
        # Verify the underlying Pydantic error details are present
        assert any("Field required" in error["msg"] for error in exc_info.value.errors)



