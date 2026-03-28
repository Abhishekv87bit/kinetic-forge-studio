from backend.kfs_manifest.schema.v1.kinetic_forge_schema import KineticForgeManifest


class KFSValidator:
    """Validates KFS manifest instances."""

    def validate_manifest(self, manifest: KineticForgeManifest) -> None:
        """Validate a parsed KineticForgeManifest instance.

        Args:
            manifest: A KineticForgeManifest instance to validate.

        Raises:
            ValueError: If the manifest fails custom validation checks.
        """
        # The Pydantic model already handles most validation.
        # Additional custom validation can be added here.
        pass


def validate_manifest(data: dict) -> None:
    """Validate a manifest data dictionary.

    Args:
        data: A dictionary of manifest data.
    """
    # Basic validation - can be extended
    pass
