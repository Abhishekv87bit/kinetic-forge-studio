
import pytest
import yaml
from pydantic import ValidationError

# Assuming these are available in the project structure as described
from backend.kfs_manifest.schema.v1.kinetic_forge_schema import KineticForgeSchema
from backend.kfs_manifest.parser import KFSParser

class TestKFSParserAndValidator:
    """
    Comprehensive tests for the KFS manifest parser and validator.
    These tests cover correct parsing of valid YAML examples,
    and proper error reporting for various invalid YAML structures
    and schema violations.
    """

    # --- Valid KFS YAML Examples ---
    VALID_MINIMAL_KFS_YAML = """
    manifest_version: "1.0"
    system_name: "MinimalSystem"
    unit_system: "metric"
    assets: []
    geometry: []
    motion: []
    """

    VALID_COMPLEX_KFS_YAML = """
    manifest_version: "1.0"
    system_name: "ComplexKineticSystem"
    unit_system: "imperial"
    assets:
      - name: "motor_a"
        asset_type: "motor"
        url: "file://./components/motor_a.json"
        metadata:
          torque_nm: 10.5
          speed_rpm: 3000
      - name: "sensor_b"
        asset_type: "sensor"
        url: "http://example.com/sensors/sensor_b.xml"
        metadata:
          accuracy: 0.01
    geometry:
      - name: "chassis"
        geometry_type: "mesh"
        source: "file://./models/chassis.obj"
        scale: [1.0, 1.0, 1.0]
        material:
          color: "#A0A0A0"
          roughness: 0.7
          metallic: 0.1
      - name: "wheel_left"
        geometry_type: "cylinder"
        radius: 0.1
        height: 0.05
        material:
          color: "#222222"
      - name: "wheel_right"
        geometry_type: "sphere"
        radius: 0.1
        material:
          color: "#222222"
    motion:
      - name: "drive_joint_left"
        motion_type: "continuous"
        parent_link: "chassis"
        child_link: "wheel_left"
        axis: [0, 1, 0]
        origin: [0.0, -0.2, 0.0]
        metadata:
          max_speed: 100
      - name: "caster_joint"
        motion_type: "fixed"
        parent_link: "chassis"
        child_link: "wheel_right"
        origin: [0.0, 0.2, 0.0]
    """

    def test_parse_valid_minimal_yaml(self):
        """
        Tests parsing of a minimal, valid KFS YAML string into a KineticForgeSchema object.
        """
        manifest = KFSParser.parse_yaml(self.VALID_MINIMAL_KFS_YAML)
        assert isinstance(manifest, KineticForgeSchema)
        assert manifest.manifest_version == "1.0"
        assert manifest.system_name == "MinimalSystem"
        assert manifest.unit_system == "metric"
        assert len(manifest.assets) == 0
        assert len(manifest.geometry) == 0
        assert len(manifest.motion) == 0

    def test_parse_valid_complex_yaml(self):
        """
        Tests parsing of a complex, valid KFS YAML string, ensuring correct structure
        and data integrity for nested models.
        """
        manifest = KFSParser.parse_yaml(self.VALID_COMPLEX_KFS_YAML)
        assert isinstance(manifest, KineticForgeSchema)
        assert manifest.manifest_version == "1.0"
        assert manifest.system_name == "ComplexKineticSystem"
        assert manifest.unit_system == "imperial"

        assert len(manifest.assets) == 2
        assert manifest.assets[0].name == "motor_a"
        assert manifest.assets[0].asset_type == "motor"
        assert manifest.assets[0].url == "file://./components/motor_a.json"
        assert manifest.assets[0].metadata["torque_nm"] == 10.5
        assert manifest.assets[1].name == "sensor_b"
        assert manifest.assets[1].asset_type == "sensor"
        assert manifest.assets[1].url == "http://example.com/sensors/sensor_b.xml"
        assert manifest.assets[1].metadata["accuracy"] == 0.01

        assert len(manifest.geometry) == 3
        assert manifest.geometry[0].name == "chassis"
        assert manifest.geometry[0].geometry_type == "mesh"
        assert manifest.geometry[0].source == "file://./models/chassis.obj"
        assert manifest.geometry[0].material.color == "#A0A0A0"

        assert manifest.geometry[1].name == "wheel_left"
        assert manifest.geometry[1].geometry_type == "cylinder"
        assert manifest.geometry[1].radius == 0.1
        assert manifest.geometry[1].height == 0.05

        assert manifest.geometry[2].name == "wheel_right"
        assert manifest.geometry[2].geometry_type == "sphere"
        assert manifest.geometry[2].radius == 0.1


        assert len(manifest.motion) == 2
        assert manifest.motion[0].name == "drive_joint_left"
        assert manifest.motion[0].motion_type == "continuous"
        assert manifest.motion[0].parent_link == "chassis"
        assert manifest.motion[0].child_link == "wheel_left"
        assert manifest.motion[0].axis == [0, 1, 0]
        assert manifest.motion[0].origin == [0.0, -0.2, 0.0]
        assert manifest.motion[0].metadata["max_speed"] == 100

        assert manifest.motion[1].name == "caster_joint"
        assert manifest.motion[1].motion_type == "fixed"
        assert manifest.motion[1].parent_link == "chassis"
        assert manifest.motion[1].child_link == "wheel_right"
        assert manifest.motion[1].origin == [0.0, 0.2, 0.0]

    # --- Invalid KFS YAML Examples (Pydantic Validation Errors) ---

    INVALID_MISSING_MANIFEST_VERSION = """
    system_name: "MissingVersion"
    unit_system: "metric"
    assets: []
    geometry: []
    motion: []
    """

    INVALID_MANIFEST_VERSION_TYPE = """
    manifest_version: 1.0 # Should be string, not float
    system_name: "WrongVersionType"
    unit_system: "metric"
    assets: []
    geometry: []
    motion: []
    """

    INVALID_UNIT_SYSTEM_VALUE = """
    manifest_version: "1.0"
    system_name: "InvalidUnitSystem"
    unit_system: "not_a_system" # Invalid enum value
    assets: []
    geometry: []
    motion: []
    """

    INVALID_ASSET_MISSING_TYPE = """
    manifest_version: "1.0"
    system_name: "InvalidAsset"
    unit_system: "metric"
    assets:
      - name: "bad_asset"
        url: "file://./bad.json"
        # asset_type is missing, which is a required field
    geometry: []
    motion: []
    """

    INVALID_GEOMETRY_MESH_MISSING_SOURCE = """
    manifest_version: "1.0"
    system_name: "InvalidGeometry"
    unit_system: "metric"
    assets: []
    geometry:
      - name: "bad_mesh"
        geometry_type: "mesh"
        # source is missing, required for mesh geometry_type
    motion: []
    """

    INVALID_GEOMETRY_CYLINDER_MISSING_HEIGHT = """
    manifest_version: "1.0"
    system_name: "InvalidCylinderGeometry"
    unit_system: "metric"
    assets: []
    geometry:
      - name: "bad_cylinder"
        geometry_type: "cylinder"
        radius: 0.1
        # height is missing, required for cylinder geometry_type
    motion: []
    """

    INVALID_MOTION_AXIS_TYPE = """
    manifest_version: "1.0"
    system_name: "InvalidMotion"
    unit_system: "metric"
    assets: []
    geometry:
      - name: "link_a"
        geometry_type: "box"
        size: [1, 1, 1]
    motion:
      - name: "bad_joint"
        motion_type: "revolute"
        parent_link: "link_a"
        child_link: "link_a"
        axis: "X_AXIS" # Should be list[float], not string
        origin: [0,0,0]
        limits: {lower: -1, upper: 1}
    """

    def test_parse_invalid_missing_manifest_version(self):
        """
        Tests that parsing fails with a ValidationError when 'manifest_version' is missing.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_MISSING_MANIFEST_VERSION)
        assert "manifest_version" in str(exc_info.value)
        assert "Field required" in str(exc_info.value)

    def test_parse_invalid_manifest_version_type(self):
        """
        Tests that parsing fails with a ValidationError when 'manifest_version' has an incorrect type.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_MANIFEST_VERSION_TYPE)
        assert "manifest_version" in str(exc_info.value)
        assert "Input should be a valid string" in str(exc_info.value)

    def test_parse_invalid_unit_system_value(self):
        """
        Tests that parsing fails with a ValidationError when 'unit_system' has an invalid enum value.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_UNIT_SYSTEM_VALUE)
        assert "unit_system" in str(exc_info.value)
        assert "Input should be 'metric' or 'imperial'" in str(exc_info.value)

    def test_parse_invalid_asset_missing_type(self):
        """
        Tests that parsing fails with a ValidationError when an asset is missing its 'asset_type'.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_ASSET_MISSING_TYPE)
        assert "asset_type" in str(exc_info.value)
        assert "Field required" in str(exc_info.value)

    def test_parse_invalid_geometry_mesh_missing_source(self):
        """
        Tests that parsing fails with a ValidationError when a 'mesh' geometry is missing its 'source'.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_GEOMETRY_MESH_MISSING_SOURCE)
        assert "source" in str(exc_info.value)
        assert "Field required" in str(exc_info.value)

    def test_parse_invalid_geometry_cylinder_missing_height(self):
        """
        Tests that parsing fails with a ValidationError when a 'cylinder' geometry is missing its 'height'.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_GEOMETRY_CYLINDER_MISSING_HEIGHT)
        assert "height" in str(exc_info.value)
        assert "Field required" in str(exc_info.value)

    def test_parse_invalid_motion_axis_type(self):
        """
        Tests that parsing fails with a ValidationError when motion 'axis' has an incorrect type.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.INVALID_MOTION_AXIS_TYPE)
        assert "axis" in str(exc_info.value)
        assert "Input should be a valid list" in str(exc_info.value) or "list[float]" in str(exc_info.value)


    # --- YAML Syntax Errors and Malformed Input ---

    MALFORMED_YAML_INDENTATION_ERROR = """
    manifest_version: "1.0"
    system_name: "MalformedYaml"
    assets:
      - name: "asset_a"
        asset_type: "motor"
        url: "file://./motor.json"
      another_field: "this_is_wrong" # Incorrect indentation for 'another_field'
    """

    EMPTY_YAML_STRING = ""
    NONE_INPUT = None # To simulate an empty file, KFSParser might explicitly handle None

    def test_parse_malformed_yaml_indentation(self):
        """
        Tests that parsing malformed YAML (indentation error) raises a yaml.YAMLError.
        """
        with pytest.raises(yaml.YAMLError) as exc_info:
            KFSParser.parse_yaml(self.MALFORMED_YAML_INDENTATION_ERROR)
        assert "mapping values are not allowed" in str(exc_info.value)
        # The line and column assertion might be brittle across YAML versions, focusing on message.
        # assert "line 8, column 7" in str(exc_info.value)

    def test_parse_empty_yaml_string(self):
        """
        Tests that parsing an empty YAML string raises a Pydantic ValidationError
        as it cannot construct a KineticForgeSchema from empty input (None after yaml.safe_load).
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.EMPTY_YAML_STRING)
        assert "Input should be a valid dictionary" in str(exc_info.value) or "Field required" in str(exc_info.value)
        assert "manifest_version" in str(exc_info.value) # Specific required field check

    def test_parse_none_input(self):
        """
        Tests that parsing None as input (e.g., if a file was truly empty or unreadable)
        raises a Pydantic ValidationError.
        """
        with pytest.raises(ValidationError) as exc_info:
            KFSParser.parse_yaml(self.NONE_INPUT)
        assert "Input should be a valid dictionary" in str(exc_info.value) or "Field required" in str(exc_info.value)
        assert "manifest_version" in str(exc_info.value) # Specific required field check
