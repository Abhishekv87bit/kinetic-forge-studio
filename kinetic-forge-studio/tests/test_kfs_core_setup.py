import pytest

from kfs_core import constants
from kfs_core import exceptions

def test_kfs_manifest_version_constant():
    """Verify the KFS_MANIFEST_VERSION constant has the expected value and type."""
    assert isinstance(constants.KFS_MANIFEST_VERSION, str)
    assert constants.KFS_MANIFEST_VERSION == "1.0.0"

def test_kfs_schema_filename_constant():
    """Verify the KFS_SCHEMA_FILENAME constant has the expected value and type."""
    assert isinstance(constants.KFS_SCHEMA_FILENAME, str)
    assert constants.KFS_SCHEMA_FILENAME == "kfs_manifest.schema.json"

def test_kfs_default_manifest_filename_constant():
    """Verify the KFS_DEFAULT_MANIFEST_FILENAME constant has the expected value and type."""
    assert isinstance(constants.KFS_DEFAULT_MANIFEST_FILENAME, str)
    assert constants.KFS_DEFAULT_MANIFEST_FILENAME == "kfs.yaml"

def test_kfs_base_error_inheritance():
    """Verify KFSBaseError correctly inherits from Exception."""
    assert issubclass(exceptions.KFSBaseError, Exception)

def test_invalid_kfs_manifest_error_inheritance():
    """Verify InvalidKFSManifestError correctly inherits from KFSBaseError."""
    assert issubclass(exceptions.InvalidKFSManifestError, exceptions.KFSBaseError)

def test_kfs_manifest_validation_error_inheritance_and_attributes():
    """Verify KFSManifestValidationError inherits correctly and stores errors."""
    assert issubclass(exceptions.KFSManifestValidationError, exceptions.KFSBaseError)

    message = "Validation failed"
    errors_list = [{"field": "name", "message": "required"}]
    error = exceptions.KFSManifestValidationError(message, errors=errors_list)

    assert str(error) == message
    assert error.errors == errors_list

    error_no_errors = exceptions.KFSManifestValidationError("Another error")
    assert error_no_errors.errors == []

def test_asset_resolution_error_inheritance():
    """Verify AssetResolutionError correctly inherits from KFSBaseError."""
    assert issubclass(exceptions.AssetResolutionError, exceptions.KFSBaseError)

def test_manifest_version_mismatch_error_inheritance():
    """Verify ManifestVersionMismatchError correctly inherits from KFSBaseError."""
    assert issubclass(exceptions.ManifestVersionMismatchError, exceptions.KFSBaseError)
