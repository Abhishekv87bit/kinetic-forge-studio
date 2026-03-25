from pathlib import Path
from typing import Optional, Union

from pydantic import ValidationError

from src.kfs_manifest.models import KineticSculptureManifest # Assuming this model is defined in models.py
from src.kfs_manifest.yaml_loader import load_kfs_yaml

def parse_kfs_manifest(
    file_path: Union[str, Path]
) -> Optional[KineticSculptureManifest]:
    """
    Parses and validates a .kfs.yaml manifest file against the KineticSculptureManifest Pydantic model.

    Args:
        file_path: The path to the .kfs.yaml file.

    Returns:
        A fully validated KineticSculptureManifest object if successful,
        otherwise None (after printing error messages to stderr).
    """
    path = Path(file_path)

    # 1. Load the YAML file content
    yaml_data = load_kfs_yaml(path)
    if yaml_data is None:
        # load_kfs_yaml already prints an error message if loading fails.
        return None

    # 2. Validate the loaded data against the Pydantic model
    try:
        manifest = KineticSculptureManifest.model_validate(yaml_data)
        return manifest
    except ValidationError as e:
        print(f"Error: KFS Manifest validation failed for '{path}':")
        print(e)
        return None
    except Exception as e:
        print(f"An unexpected error occurred during manifest parsing for '{path}': {e}")
        return None
