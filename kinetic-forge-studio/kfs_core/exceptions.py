"""Custom exceptions for the KFS (Kinetic Forge Studio) Core Library."""

class KFSBaseError(Exception):
    """Base exception for all KFS related errors."""
    pass

class InvalidKFSManifestError(KFSBaseError):
    """Raised when a KFS manifest is syntactically invalid or malformed."""
    pass

class KFSManifestValidationError(KFSBaseError):
    """Raised when a KFS manifest fails schema validation."""
    def __init__(self, message, errors=None):
        super().__init__(message)
        self.errors = errors if errors is not None else []

class AssetResolutionError(KFSBaseError):
    """Raised when an asset referenced in the manifest cannot be resolved or found."""
    pass

class ManifestVersionMismatchError(KFSBaseError):
    """Raised when the manifest version is incompatible with the parser."""
    pass