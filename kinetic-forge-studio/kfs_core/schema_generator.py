import json
from pathlib import Path

from kfs_core.manifest_models import KFSManifest
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
    kfs_schema["$schema"] = "http://json-schema.org/draft-07/schema#" # Using Draft 7 for broad compatibility

    # Add a human-readable title and description
    kfs_schema["title"] = f"Kinetic Forge Studio Manifest Schema v{schema_version_major_minor}"
    kfs_schema["description"] = "Schema for defining kinetic sculpture projects in KFS." # As per design context

    # Write the schema to file, pretty-printed
    with open(schema_path, "w", encoding="utf-8") as f:
        json.dump(kfs_schema, f, indent=2)

    print(f"Generated KFS manifest schema to: {schema_path}")
    return schema_path

if __name__ == "__main__":
    generate_kfs_schema()
