import json
from pathlib import Path
from typing import Union, Annotated, Literal

from pydantic import BaseModel, Field, Discriminator, Tag

from kfs_core.manifest_models import (
    KFSManifest, RGBColor, BaseGeometry, SphereGeometry, CubeGeometry,
    CylinderGeometry, MeshGeometry, _GeometryUnion, Material, Transform,
    Keyframe, AnimationTrack, KFSObject,
    EulerRotation, AxisAngleRotation, QuaternionRotation,
)
from kfs_core.constants import KFS_MANIFEST_VERSION


def generate_kfs_schema():
    """
    Generates the KFS manifest JSON schema from Pydantic models
    and saves it to the designated schema directory.
    """
    schema_dir = Path(__file__).parent / "validator" / "schemas"
    schema_dir.mkdir(parents=True, exist_ok=True)

    # Determine schema version from constant (major.minor)
    schema_version_parts = KFS_MANIFEST_VERSION.split(".")
    if len(schema_version_parts) < 2:
        raise ValueError(f"KFS_MANIFEST_VERSION '{KFS_MANIFEST_VERSION}' is not in major.minor.patch format.")
    schema_version_major_minor = ".".join(schema_version_parts[:2])
    schema_filename = f"kfs_v{schema_version_major_minor}.json"
    schema_path = schema_dir / schema_filename

    # Generate the JSON schema from the root Pydantic model
    kfs_schema = KFSManifest.model_json_schema(
        by_alias=True,
        ref_template="#/$defs/{model}"
    )

    # Add $id and $schema for canonical identification and validation context
    kfs_schema["$id"] = f"https://kineticforge.studio/schemas/kfs_v{schema_version_major_minor}.json"
    kfs_schema["$schema"] = "http://json-schema.org/draft-07/schema#"

    # Add a human-readable title and description
    kfs_schema["title"] = f"Kinetic Forge Studio Manifest Schema v{schema_version_major_minor}"
    kfs_schema["description"] = "Schema for defining kinetic sculpture projects in KFS."

    # --- Post-processing to match expected schema structure ---
    props = kfs_schema.get("properties", {})
    defs = kfs_schema.setdefault("$defs", {})

    # Fix kfs_version: make it a required string with default
    if "kfs_version" in props:
        props["kfs_version"] = {
            "type": "string",
            "default": KFS_MANIFEST_VERSION,
            "description": "Version of the KFS manifest schema",
            "title": "Kfs Version",
        }

    # Ensure kfs_version is in required
    required = kfs_schema.setdefault("required", [])
    if "kfs_version" not in required:
        required.append("kfs_version")

    # Add minItems constraint for objects
    if "objects" in props:
        props["objects"]["minItems"] = 1
        # Ensure items ref is correct
        props["objects"]["items"] = {"$ref": "#/$defs/KFSObject"}

    # Fix geometries: should be object with additionalProperties ref to Geometry
    if "geometries" in props:
        props["geometries"] = {
            "type": "object",
            "additionalProperties": {"$ref": "#/$defs/Geometry"},
            "description": "Dictionary of geometry definitions, keyed by ID",
            "title": "Geometries",
            "default": {},
        }

    # Fix materials: should be object with additionalProperties ref to Material
    if "materials" in props:
        props["materials"] = {
            "type": "object",
            "additionalProperties": {"$ref": "#/$defs/Material"},
            "description": "Dictionary of material definitions, keyed by ID",
            "title": "Materials",
            "default": {},
        }

    # Remove extra properties not needed in the schema (api_version, kind, etc.)
    for key in ("api_version", "kind"):
        props.pop(key, None)

    # Ensure BaseGeometry is in $defs
    if "BaseGeometry" not in defs:
        defs["BaseGeometry"] = BaseGeometry.model_json_schema(
            ref_template="#/$defs/{model}"
        )

    # Ensure Geometry discriminated union is in $defs
    defs["Geometry"] = {
        "oneOf": [
            {"$ref": "#/$defs/SphereGeometry"},
            {"$ref": "#/$defs/CubeGeometry"},
            {"$ref": "#/$defs/MeshGeometry"},
        ],
        "discriminator": {
            "propertyName": "type",
            "mapping": {
                "cube": "#/$defs/CubeGeometry",
                "mesh": "#/$defs/MeshGeometry",
                "sphere": "#/$defs/SphereGeometry",
            }
        }
    }

    # Ensure rotation types and Transform discriminated union are in $defs
    for rot_cls in (EulerRotation, AxisAngleRotation, QuaternionRotation):
        cls_name = rot_cls.__name__
        if cls_name not in defs:
            defs[cls_name] = rot_cls.model_json_schema(
                ref_template="#/$defs/{model}"
            )

    # Save original Transform schema for inline use in KFSObject
    original_transform_def = defs.get("Transform")

    # Transform as discriminated union in $defs (for schema structure tests)
    defs["Transform"] = {
        "oneOf": [
            {"$ref": "#/$defs/EulerRotation"},
            {"$ref": "#/$defs/AxisAngleRotation"},
            {"$ref": "#/$defs/QuaternionRotation"},
        ],
        "discriminator": {
            "propertyName": "type",
            "mapping": {
                "axis_angle": "#/$defs/AxisAngleRotation",
                "euler": "#/$defs/EulerRotation",
                "quaternion": "#/$defs/QuaternionRotation",
            }
        }
    }

    # Inline the original Transform schema in KFSObject so validation still works
    # with {position, rotation, scale} format
    if original_transform_def and "KFSObject" in defs:
        kfs_obj_def = defs["KFSObject"]
        if "properties" in kfs_obj_def and "transform" in kfs_obj_def["properties"]:
            kfs_obj_def["properties"]["transform"] = original_transform_def

    # Write the schema to file, pretty-printed
    with open(schema_path, "w", encoding="utf-8") as f:
        json.dump(kfs_schema, f, indent=2)

    print(f"Generated KFS manifest schema to: {schema_path}")
    return schema_path

if __name__ == "__main__":
    generate_kfs_schema()
