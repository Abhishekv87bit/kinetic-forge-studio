import yaml
import json
from pathlib import Path
from typing import Union, Literal, Dict, Any, Optional

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
        manifest_parts = manifest_kfs_version.split(".")
        parser_parts = parser_version.split(".")
        if len(manifest_parts) < 3:
            raise ValueError(f"Manifest version '{manifest_kfs_version}' does not have 3 parts")
        if len(parser_parts) < 3:
            raise ValueError(f"Parser version '{parser_version}' does not have 3 parts")
        # Validate all parts are integers
        _ = [int(p) for p in manifest_parts[:3]]
        _ = [int(p) for p in parser_parts[:3]]
        manifest_major_version = int(manifest_parts[0])
        parser_major_version = int(parser_parts[0])
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
    """
    path = Path(file_path)
    if not path.is_file():
        raise FileNotFoundError(f"Manifest file not found: {path}")

    file_extension = path.suffix.lower()
    raw_data: Dict[str, Any] = {}

    try:
        with open(path, "r", encoding="utf-8") as f:
            if file_extension in (".yaml", ".yml"):
                raw_data = yaml.safe_load(f)
            elif file_extension == ".json":
                raw_data = json.load(f)
            else:
                raise InvalidKFSManifestError(f"Unsupported file extension: {file_extension}. Must be .yaml, .yml, or .json.")
    except (InvalidKFSManifestError, ManifestVersionMismatchError):
        raise  # Re-raise KFS-specific errors directly
    except yaml.YAMLError as e:
        raise InvalidKFSManifestError(f"Malformed YAML content in {path}: {e}") from e
    except json.JSONDecodeError as e:
        raise InvalidKFSManifestError(f"Malformed JSON content in {path}: {e}") from e
    except Exception as e:
        raise KFSBaseError(f"An unexpected error occurred while reading {path}: {e}") from e

    if not isinstance(raw_data, dict):
        raise InvalidKFSManifestError(
            f"YAMLSyntaxError: Manifest file {path} content is not a valid dictionary "
            f"(expected a root object, got {type(raw_data).__name__})."
        )

    # Check version compatibility before Pydantic parsing for clearer error messages
    _check_version_compatibility(raw_data, KFS_MANIFEST_VERSION)

    try:
        # Pydantic will perform the actual schema validation
        manifest = KFSManifest.model_validate(raw_data)
        return manifest
    except PydanticValidationError as e:
        # Transform Pydantic's ValidationError into a custom KFSManifestValidationError
        errors = e.errors()

        # Format loc as 'field_name' with dots for nested paths
        def format_loc(loc):
            return "/".join(str(part) for part in loc)

        def _compat_msg(msg: str) -> str:
            """Translate Pydantic v2 messages to v1-style for backwards compatibility."""
            msg = msg.replace(
                "Input should be greater than or equal to",
                "ensure this value is greater than or equal to",
            )
            msg = msg.replace(
                "Input should be less than or equal to",
                "ensure this value is less than or equal to",
            )
            return msg

        error_messages = [f"'{format_loc(err['loc'])}': {_compat_msg(err['msg'])}" for err in errors]
        raise KFSManifestValidationError(
            f"KFS manifest validation failed for {path}: {'; '.join(error_messages)}",
            errors=errors
        ) from e
    except Exception as e:
        raise KFSBaseError(f"An unexpected error occurred during manifest parsing for {path}: {e}") from e


def save_kfs_manifest(manifest: KFSManifest, file_path: Union[str, Path], format: Optional[Literal["yaml", "json"]] = None):
    """
    Saves a KFSManifest Pydantic model to a YAML or JSON file.
    """
    path = Path(file_path)
    file_extension = path.suffix.lower()

    if format is None:
        if file_extension in (".yaml", ".yml"):
            output_format = "yaml"
        elif file_extension == ".json":
            output_format = "json"
        else:
            raise ValueError(f"Could not infer output format from file extension '{file_extension}'. "
                             "Please specify 'format' argument ('yaml' or 'json').")
    else:
        output_format = format

    try:
        # Convert Pydantic model to a dictionary, using aliases and excluding unset/None fields
        manifest_data = manifest.model_dump(by_alias=True, exclude_none=True)

        # Ensure parent directories exist before writing
        path.parent.mkdir(parents=True, exist_ok=True)

        with open(path, "w", encoding="utf-8") as f:
            if output_format == "yaml":
                yaml.dump(manifest_data, f, indent=2, sort_keys=False)
            elif output_format == "json":
                json.dump(manifest_data, f, indent=2)
            else:
                raise ValueError(f"Unsupported output format specified: {output_format}")
    except ValueError:
        raise  # Re-raise ValueError directly
    except Exception as e:
        raise KFSBaseError(f"An error occurred while saving manifest to {path}: {e}") from e
