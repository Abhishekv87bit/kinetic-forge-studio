
import pytest
from pydantic import ValidationError

from backend.kfs_manifest.schema.v1.asset_models import MeshAsset, FileAsset
from backend.kfs_manifest.schema.v1.geometry_models import MeshGeometry, BoxGeometry
from backend.kfs_manifest.schema.v1.motion_models import RevoluteJoint, LinearActuator, Sensor
from backend.kfs_manifest.schema.v1.kinetic_forge_schema import KFSManifest

# --- Test Data ---

VALID_KFS_MANIFEST_DATA = {
    "version": "v1.0",
    "name": "robotic_arm_manifest",
    "description": "Manifest for a simple robotic arm.",
    "assets": {
        "arm_link_mesh": {
            "type": "mesh",
            "uri": "kfs://meshes/arm_link.stl",
            "format": "stl",
        },
        "base_link_mesh": {
            "type": "mesh",
            "uri": "kfs://meshes/base_link.obj",
            "format": "obj",
        },
        "config_file": {
            "type": "file",
            "uri": "kfs://configs/robot.json",
            "mime_type": "application/json",
        }
    },
    "geometries": {
        "base_geometry": {
            "type": "mesh",
            "asset_ref": "base_link_mesh",
            "scale": [1.0, 1.0, 1.0],
            "offset": [0.0, 0.0, 0.0]
        },
        "link1_geometry": {
            "type": "mesh",
            "asset_ref": "arm_link_mesh",
            "scale": [1.0, 1.0, 1.0],
            "offset": [0.0, 0.0, 0.5]
        },
        "joint_box_collision": {
            "type": "box",
            "size": [0.1, 0.1, 0.1],
            "offset": [0.0, 0.0, 0.0]
        }
    },
    "motions": {
        "base_joint": {
            "type": "revolute",
            "axis": [0, 0, 1],
            "limit": {"lower": -3.14, "upper": 3.14},
            "parent_link": "world",
            "child_link": "base_link"
        },
        "shoulder_joint": {
            "type": "revolute",
            "axis": [0, 1, 0],
            "limit": {"lower": -1.57, "upper": 1.57},
            "parent_link": "base_link",
            "child_link": "link1"
        },
        "shoulder_actuator": {
            "type": "linear",
            "joint_ref": "shoulder_joint",
            "max_force": 100.0,
            "max_velocity": 10.0
        },
        "end_effector_sensor": {
            "type": "sensor",
            "sensor_type": "force_torque",
            "frame": "end_effector_frame"
        }
    }
}

INVALID_KFS_MANIFEST_DATA_MISSING_VERSION = {
    "name": "invalid_manifest",
    "assets": {},
    "geometries": {},
    "motions": {}
}

INVALID_KFS_MANIFEST_DATA_BAD_ASSET = {
    "version": "v1.0",
    "name": "invalid_manifest",
    "assets": {
        "bad_asset": {
            "type": "mesh",
            "uri": "kfs://invalid.stl",
            # Missing required 'format'
        }
    },
    "geometries": {},
    "motions": {}
}

# --- Test Class ---

class TestKineticForgeSchema:
    def test_valid_kfs_manifest_creation(self):
        """
        Tests successful parsing and validation of a complete, valid KFS manifest.
        Ensures correct integration of all sub-models.
        """
        manifest = KFSManifest(**VALID_KFS_MANIFEST_DATA)

        assert manifest.version == "v1.0"
        assert manifest.name == "robotic_arm_manifest"
        assert manifest.description == "Manifest for a simple robotic arm."

        # Verify Assets
        assert len(manifest.assets) == 3
        assert "arm_link_mesh" in manifest.assets
        assert isinstance(manifest.assets["arm_link_mesh"], MeshAsset)
        assert manifest.assets["arm_link_mesh"].uri == "kfs://meshes/arm_link.stl"
        assert manifest.assets["arm_link_mesh"].format == "stl"

        assert "config_file" in manifest.assets
        assert isinstance(manifest.assets["config_file"], FileAsset)
        assert manifest.assets["config_file"].uri == "kfs://configs/robot.json"
        assert manifest.assets["config_file"].mime_type == "application/json"

        # Verify Geometries
        assert len(manifest.geometries) == 3
        assert "base_geometry" in manifest.geometries
        assert isinstance(manifest.geometries["base_geometry"], MeshGeometry)
        assert manifest.geometries["base_geometry"].asset_ref == "base_link_mesh"
        assert manifest.geometries["base_geometry"].scale == [1.0, 1.0, 1.0]

        assert "joint_box_collision" in manifest.geometries
        assert isinstance(manifest.geometries["joint_box_collision"], BoxGeometry)
        assert manifest.geometries["joint_box_collision"].size == [0.1, 0.1, 0.1]

        # Verify Motions
        assert len(manifest.motions) == 4
        assert "base_joint" in manifest.motions
        assert isinstance(manifest.motions["base_joint"], RevoluteJoint)
        assert manifest.motions["base_joint"].axis == [0, 0, 1]
        assert manifest.motions["base_joint"].limit.lower == -3.14

        assert "shoulder_actuator" in manifest.motions
        assert isinstance(manifest.motions["shoulder_actuator"], LinearActuator)
        assert manifest.motions["shoulder_actuator"].joint_ref == "shoulder_joint"
        assert manifest.motions["shoulder_actuator"].max_force == 100.0

        assert "end_effector_sensor" in manifest.motions
        assert isinstance(manifest.motions["end_effector_sensor"], Sensor)
        assert manifest.motions["end_effector_sensor"].sensor_type == "force_torque"


    def test_invalid_kfs_manifest_missing_required_field(self):
        """
        Tests that a ValidationError is raised when a top-level required field (version) is missing.
        """
        with pytest.raises(ValidationError, match="version"):
            KFSManifest(**INVALID_KFS_MANIFEST_DATA_MISSING_VERSION)

    def test_invalid_kfs_manifest_bad_sub_model_validation(self):
        """
        Tests that a ValidationError is raised when an embedded sub-model is invalid.
        (e.g., a MeshAsset missing its 'format' field).
        """
        with pytest.raises(ValidationError, match="format"):
            KFSManifest(**INVALID_KFS_MANIFEST_DATA_BAD_ASSET)

    def test_invalid_kfs_manifest_bad_motion_definition(self):
        """
        Tests that a ValidationError is raised for an invalid motion definition (e.g., missing axis for RevoluteJoint).
        """
        bad_motion_data = VALID_KFS_MANIFEST_DATA.copy()
        bad_motion_data["motions"] = {
            "bad_joint": {
                "type": "revolute",
                # "axis": [0, 0, 1], # Missing
                "limit": {"lower": -3.14, "upper": 3.14},
                "parent_link": "world",
                "child_link": "base_link"
            }
        }
        with pytest.raises(ValidationError, match="axis"):
            KFSManifest(**bad_motion_data)

    def test_kfs_manifest_serialization_deserialization(self):
        """
        Tests that a KFSManifest can be serialized to JSON and then deserialized back,
        maintaining data integrity.
        """
        manifest = KFSManifest(**VALID_KFS_MANIFEST_DATA)
        serialized_data = manifest.model_dump(mode="json", exclude_unset=True)

        # Check if the serialized data can be used to re-create the model
        re_manifest = KFSManifest(**serialized_data)
        assert re_manifest == manifest, "Deserialized manifest does not match original."

        # Verify a few specific serialized values
        assert serialized_data["version"] == "v1.0"
        assert serialized_data["name"] == "robotic_arm_manifest"
        assert "arm_link_mesh" in serialized_data["assets"]
        assert serialized_data["assets"]["arm_link_mesh"]["type"] == "mesh"
        assert serialized_data["geometries"]["base_geometry"]["asset_ref"] == "base_link_mesh"
        assert serialized_data["motions"]["shoulder_actuator"]["joint_ref"] == "shoulder_joint"


    def test_kfs_manifest_default_values(self):
        """
        Tests that optional fields correctly default to empty dictionaries or None
        when not provided in the input data.
        """
        minimal_data = {
            "version": "v1.0",
            "name": "minimal_manifest",
        }
        manifest = KFSManifest(**minimal_data)
        assert manifest.version == "v1.0"
        assert manifest.name == "minimal_manifest"
        assert manifest.description is None
        assert manifest.assets == {}
        assert manifest.geometries == {}
        assert manifest.motions == {}
