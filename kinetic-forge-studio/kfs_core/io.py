import yaml
from pydantic import ValidationError
from typing import Union
from pathlib import Path

# Assume kfs_core.models exists and is complete
from kfs_core.models import KFSManifest, Material, BoxGeometry, SphereGeometry, KineticComponent, Vector3D, Color, Transformation

def load_kfs_manifest_from_string(yaml_content: str) -> KFSManifest:
    """
    Loads a KFS manifest from a YAML string, validates it against the KFSManifest schema.

    Args:
        yaml_content: The YAML content as a string.

    Returns:
        A validated KFSManifest object.

    Raises:
        yaml.YAMLError: If the YAML content is syntactically incorrect.
        pydantic.ValidationError: If the YAML content does not conform to the KFSManifest schema.
    """
    try:
        data = yaml.safe_load(yaml_content)
    except yaml.YAMLError as e:
        raise yaml.YAMLError(f"Malformed YAML content: {e}") from e

    if not isinstance(data, dict):
        raise ValueError("YAML content must represent a dictionary (KFSManifest object).")

    try:
        manifest = KFSManifest.parse_obj(data)
        return manifest
    except ValidationError as e:
        raise ValidationError(f"KFS Manifest validation failed: {e}") from e

def load_kfs_manifest(file_path: Union[str, Path]) -> KFSManifest:
    """
    Loads a KFS manifest from a file, validates it against the KFSManifest schema.

    Args:
        file_path: The path to the KFS manifest YAML file.

    Returns:
        A validated KFSManifest object.

    Raises:
        FileNotFoundError: If the specified file does not exist.
        yaml.YAMLError: If the file's content is syntactically incorrect YAML.
        pydantic.ValidationError: If the file's content does not conform to the KFSManifest schema.
    """
    file_path = Path(file_path)
    if not file_path.exists():
        raise FileNotFoundError(f"KFS manifest file not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        yaml_content = f.read()

    return load_kfs_manifest_from_string(yaml_content)
