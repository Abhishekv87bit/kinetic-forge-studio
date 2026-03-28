import yaml
from typing import Any, Dict

from pydantic import ValidationError as PydanticValidationError

from backend.kfs_manifest.schema.v1.kinetic_forge_schema import KineticForgeManifest
from backend.kfs_manifest.errors import KFSManifestError, InvalidManifestError


SUPPORTED_VERSIONS = {"v1"}


class KFSParser:
    """Parses and validates KFS manifest YAML content."""

    def parse_manifest_from_string(self, content: str) -> KineticForgeManifest:
        """Parse a YAML string into a KineticForgeManifest.

        Args:
            content: A YAML string representing a KFS manifest.

        Returns:
            A KineticForgeManifest instance.

        Raises:
            KFSManifestError: If the YAML is malformed or empty.
            InvalidManifestError: If the manifest fails schema validation.
        """
        if not content or not content.strip():
            raise KFSManifestError("YAML parsing error: document is empty or malformed.")

        try:
            data = yaml.safe_load(content)
        except yaml.YAMLError:
            # Try loading first document from multi-document stream
            try:
                docs = list(yaml.safe_load_all(content))
                data = docs[0] if docs else None
            except yaml.YAMLError as e2:
                raise KFSManifestError(f"YAML parsing error: {e2}") from e2

        if data is None:
            raise KFSManifestError("YAML parsing error: document is empty or malformed.")

        if not isinstance(data, dict):
            raise KFSManifestError("YAML parsing error: document is not a mapping.")

        # Check version
        version = data.get("kfs_schema_version")
        if version and version not in SUPPORTED_VERSIONS:
            raise InvalidManifestError(
                f"Unsupported KFS manifest schema version '{version}'.",
                errors=[{"loc": ("kfs_schema_version",), "msg": f"Unsupported KFS manifest schema version '{version}'."}]
            )

        try:
            manifest = KineticForgeManifest.model_validate(data)
            return manifest
        except PydanticValidationError as e:
            errors = e.errors()
            error_messages = "; ".join(f"{err['loc']}: {err['msg']}" for err in errors)
            raise InvalidManifestError(
                error_messages,
                errors=errors
            ) from e


def parse_manifest(content: str) -> Dict[str, Any]:
    """Parse a YAML manifest string into a dictionary.

    Args:
        content: A YAML string.

    Returns:
        Parsed dictionary.

    Raises:
        KFSManifestError: If parsing fails.
    """
    if not content or not content.strip():
        raise KFSManifestError("YAML parsing error: document is empty or malformed.")

    try:
        data = yaml.safe_load(content)
    except yaml.YAMLError as e:
        raise KFSManifestError(f"YAML parsing error: {e}") from e

    if data is None:
        raise KFSManifestError("YAML parsing error: document is empty or malformed.")

    if not isinstance(data, dict):
        raise KFSManifestError("YAML parsing error: document is not a mapping.")

    return data
