class KFSManifestError(Exception):
  """Base exception for all KFS Manifest related errors."""
  pass


class ManifestValidationError(KFSManifestError):
  """Exception raised when manifest validation fails."""

  def __init__(self, message: str, errors: list | None = None):
    super().__init__(message)
    self.errors = errors if errors is not None else []


class ManifestResolutionError(KFSManifestError):
  """Exception raised when an asset or reference within the manifest cannot be resolved."""
  pass


class ManifestFileNotFoundError(KFSManifestError):
  """Exception raised when a manifest file is not found at the specified path."""
  pass


class ManifestSchemaError(KFSManifestError):
  """Exception raised for issues related to the manifest schema definition itself."""
  pass


class InvalidManifestFormatError(KFSManifestError):
  """Exception raised when the manifest file format is invalid (e.g., malformed YAML)."""
  pass
