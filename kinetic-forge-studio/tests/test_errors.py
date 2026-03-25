import pytest

from backend.kfs_manifest.errors import (
    KFSManifestError,
    ManifestValidationError,
    AssetResolutionError,
)


def test_kfs_manifest_error_can_be_raised():
    """Test that KFSManifestError can be raised and caught."""
    with pytest.raises(KFSManifestError) as excinfo:
        raise KFSManifestError("A general manifest error occurred")
    assert str(excinfo.value) == "A general manifest error occurred"


def test_manifest_validation_error_can_be_raised():
    """Test that ManifestValidationError can be raised and caught."""
    with pytest.raises(ManifestValidationError) as excinfo:
        raise ManifestValidationError("Validation failed for manifest")
    assert str(excinfo.value) == "Validation failed for manifest"
    assert isinstance(excinfo.value, KFSManifestError)


def test_asset_resolution_error_can_be_raised():
    """Test that AssetResolutionError can be raised and caught."""
    with pytest.raises(AssetResolutionError) as excinfo:
        raise AssetResolutionError("Could not resolve asset 'some_asset'")
    assert str(excinfo.value) == "Could not resolve asset 'some_asset'"
    assert isinstance(excinfo.value, KFSManifestError)


def test_custom_error_inherits_from_base_error():
    """Test that specific custom errors inherit from the base KFSManifestError."""
    try:
        raise ManifestValidationError("Test inheritance")
    except KFSManifestError as e:
        assert str(e) == "Test inheritance"
    else:
        pytest.fail("Expected KFSManifestError to be caught")

    try:
        raise AssetResolutionError("Test inheritance")
    except KFSManifestError as e:
        assert str(e) == "Test inheritance"
    else:
        pytest.fail("Expected KFSManifestError to be caught")
