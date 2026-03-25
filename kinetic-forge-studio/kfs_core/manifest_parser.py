import yaml
import json
from pathlib import Path
from typing import Union, Literal, Dict, Any

from pydantic import ValidationError as PydanticValidationError

from kfs_core.manifest_models import KFSManifest
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_core.exceptions import (
    InvalidKFSManifestError,
    KFSManifestValidationError,
    ManifestVersionMismatchError,
    KFSBaseError
)

def _check_version_compatibility(manifest_data: Dict[str, Any], parser_version: str):
    """
    Checks if the manifest_data's kfs_version is compatible with the parser_version.
    Compatibility is defined by matching major versions.
    """
    manifest_kfs_version = manifest_data.get("kfs_version")
    if not manifest_kfs_version:
        raise InvalidKFSManifestError("Manifest data is missing 'kfs_version'.")

    try:
        manifest_major_version = int(manifest_kfs_version.split(".")[0])
        parser_major_version = int(parser_version.split(".")[0])
    except (ValueError, IndexError):
        raise InvalidKFSManifestError(
            f"Invalid 'kfs_version' format in manifest ('{manifest_kfs_version}') "
            f"or parser ('{parser_version}'). Expected 'X.Y.Z'."
        )

    if manifest_major_version != parser_major_version:
        raise ManifestVersionMismatchError(
            f"Manifest version '{manifest_kfs_version}' is incompatible with parser version '{parser_version}'. "
            f"Major versions must match." # Strict major version compatibility
        )


def load_kfs_manifest(file_path: Union[str, Path]) -> KFSManifest:
    """
    Loads a KFS manifest from a YAML or JSON file into a KFSManifest Pydantic model.

    Args:
        file_path (Union[str, Path]): The path to the .kfs.yaml or .kfs.json file.

    Returns:
        KFSManifest: An instance of the loaded KFSManifest model.

    Raises:
        FileNotFoundError: If the specified file does not exist.
        InvalidKFSManifestError: If the file content is not valid YAML or JSON, or malformed.
        ManifestVersionMismatchError: If the manifest's KFS version is incompatible with the parser.
        KFSManifestValidationError: If the manifest content fails schema validation against KFSManifest model.
        KFSBaseError: For other unexpected KFS-related errors during loading.
    """
    path = Path(file_path)

    if not path.exists():
        raise FileNotFoundError(f"KFS manifest file not found: {path}")
    if not path.is_file():
        raise InvalidKFSManifestError(f"Path '{path}' is not a file.")

    content = path.read_text(encoding="utf-8")
    data: Dict[str, Any] = {}

    # Attempt to parse as YAML first
    try:
        data = yaml.safe_load(content)
        if not isinstance(data, dict):
            # yaml.safe_load returns None for empty string, or other types for non-dict roots
            raise InvalidKFSManifestError("KFS manifest root must be a dictionary.")
    except yaml.YAMLError:
        # If YAML parsing fails, try JSON
        try:
            data = json.loads(content)
            if not isinstance(data, dict):
                raise InvalidKFSManifestError("KFS manifest root must be a dictionary.")
        except json.JSONDecodeError as e:
            raise InvalidKFSManifestError(
                f"File '{path}' is neither valid YAML nor JSON: {e}"
            )
    except Exception as e:
        # Catch any other parsing errors not specific to YAML/JSON syntax
        raise InvalidKFSManifestError(f"Failed to parse manifest '{path}': {e}")

    try:
        _check_version_compatibility(data, KFS_MANIFEST_VERSION)
    except (InvalidKFSManifestError, ManifestVersionMismatchError) as e:
        # Re-raise directly, it's already a specific error type
        raise e

    try:
        # Pydantic v2's model_validate is preferred for validating raw data
        manifest = KFSManifest.model_validate(data)
        return manifest
    except PydanticValidationError as e:
        # Extract Pydantic errors for a more informative custom exception
        errors = e.errors()
        error_messages = [f"{' -> '.join(str(loc) for loc in err['loc'])}: {err['msg']}" for err in errors]
        raise KFSManifestValidationError(
            f"KFS manifest validation failed for '{path}': {'; '.join(error_messages)}",
            errors=errors
        )
    except Exception as e:
        # Catch any other unexpected errors during manifest loading
        raise KFSBaseError(f"An unexpected error occurred while loading manifest '{path}': {e}")


def save_kfs_manifest(
    manifest: KFSManifest,
    file_path: Union[str, Path],
    format: Literal["yaml", "json"] = "yaml",
    indent: int = 2
) -> None:
    """
    Saves a KFSManifest Pydantic model instance to a YAML or JSON file.

    Args:
        manifest (KFSManifest): The KFSManifest model instance to save.
        file_path (Union[str, Path]): The path to save the manifest file.
        format (Literal["yaml", "json"]): The output format ('yaml' or 'json'). Defaults to 'yaml'.
        indent (int): The indentation level for the output file. Defaults to 2.

    Raises:
        ValueError: If an unsupported format is specified.
        KFSBaseError: For errors during file writing.
    """
    path = Path(file_path)
    path.parent.mkdir(parents=True, exist_ok=True)  # Ensure parent directory exists

    # Convert Pydantic model to a dictionary suitable for serialization.
    # by_alias=True ensures fields with `alias` are exported with their alias names,
    # which is important for compatibility with the schema (e.g., 'kfs_version').
    manifest_data = manifest.model_dump(by_alias=True, exclude_unset=False)

    try:
        if format == "yaml":
            with open(path, "w", encoding="utf-8") as f:
                # sort_keys=False to preserve definition order for readability
                yaml.dump(manifest_data, f, indent=indent, sort_keys=False)
        elif format == "json":
            with open(path, "w", encoding="utf-8") as f:
                json.dump(manifest_data, f, indent=indent)
        else:
            raise ValueError(f"Unsupported format '{format}'. Must be 'yaml' or 'json'.")
    except Exception as e:
        raise KFSBaseError(f"Failed to save KFS manifest to '{path}' in {format} format: {e}")