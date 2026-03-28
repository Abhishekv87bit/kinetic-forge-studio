import pytest
from pathlib import Path

from kfs_core.manifest_parser import load_kfs_manifest
from kfs_core.exceptions import KFSBaseError

# List of documentation files that should exist and not be empty
DOC_FILES = [
    "docs/kfs_manifest_spec.md",
    "docs/api_reference.md",
    "docs/tool_integration_guide.md",
]

# List of example KFS manifest files that should exist, not be empty, and be loadable
EXAMPLE_MANIFEST_FILES = [
    "examples/complex_motion.kfs.yaml",
    # Add other example manifests here as they are created
]

@pytest.mark.parametrize("doc_file", DOC_FILES)
def test_documentation_files_exist(doc_file):
    """Ensure that essential documentation files exist and are not empty."""
    file_path = Path(doc_file)
    assert file_path.exists(), f"Documentation file '{file_path}' does not exist."
    assert file_path.is_file(), f"Path '{file_path}' is not a file."
    assert file_path.stat().st_size > 0, f"Documentation file '{file_path}' is empty."

@pytest.mark.parametrize("example_manifest_file", EXAMPLE_MANIFEST_FILES)
def test_example_manifests_are_valid_and_loadable(example_manifest_file):
    """
    Ensure example manifest files exist, are syntactically valid YAML,
    and can be successfully loaded by the KFS manifest parser.
    """
    file_path = Path(example_manifest_file)
    assert file_path.exists(), f"Example manifest file '{file_path}' does not exist."
    assert file_path.is_file(), f"Path '{file_path}' is not a file."
    assert file_path.stat().st_size > 0, f"Example manifest file '{file_path}' is empty."

    try:
        manifest = load_kfs_manifest(file_path)
        # A basic check to ensure the manifest object is instantiated and has core fields
        assert manifest is not None, "Loaded manifest should not be None."
        assert isinstance(manifest.kfs_version, str) and len(manifest.kfs_version) > 0, "Manifest 'kfs_version' is missing or invalid."
        assert isinstance(manifest.name, str) and len(manifest.name) > 0, "Manifest 'name' is missing or invalid."
        assert isinstance(manifest.objects, list), "Manifest 'objects' field should be a list."

    except KFSBaseError as e:
        pytest.fail(f"Failed to load or validate example manifest '{file_path}': {type(e).__name__} - {e}")
    except Exception as e:
        pytest.fail(f"An unexpected error occurred while loading example manifest '{file_path}': {type(e).__name__} - {e}")
