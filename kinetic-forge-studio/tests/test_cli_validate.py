import pytest
from click.testing import CliRunner
from pathlib import Path
import yaml

from kfs_cli.main import cli
from kfs_core.constants import KFS_MANIFEST_VERSION

@pytest.fixture
def runner():
    """Fixture for invoking CLI commands."""
    return CliRunner()

@pytest.fixture
def valid_manifest_content():
    """Returns a dictionary for a minimal valid KFS manifest."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Valid Sculpture",
        "objects": [
            {
                "id": "obj1",
                "geometry_id": "sphere_geo",
                "material_id": "red_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
                "animation": None
            }
        ],
        "geometries": {
            "sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0}
        },
        "materials": {
            "red_material": {"id": "red_material", "color": {"r": 255, "g": 0, "b": 0}}
        }
    }

@pytest.fixture
def invalid_schema_manifest_content():
    """Returns a dictionary for an invalid KFS manifest (missing required 'name')."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        # "name": "Invalid Sculpture", # This field is intentionally missing
        "objects": [
            {
                "id": "obj1",
                "geometry_id": "sphere_geo",
                "material_id": "red_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]}
            }
        ],
        "geometries": {
            "sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0}
        },
        "materials": {
            "red_material": {"id": "red_material", "color": {"r": 255, "g": 0, "b": 0}}
        }
    }

@pytest.fixture
def invalid_semantic_manifest_content():
    """Returns a dictionary for an invalid KFS manifest (duplicate object IDs)."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Semantic Error Sculpture",
        "objects": [
            {
                "id": "obj1",
                "geometry_id": "sphere_geo",
                "material_id": "red_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]}
            },
            {
                "id": "obj1", # Duplicate ID
                "geometry_id": "cube_geo",
                "material_id": "blue_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]}
            }
        ],
        "geometries": {
            "sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0},
            "cube_geo": {"type": "cube", "id": "cube_geo", "size": 2.0}
        },
        "materials": {
            "red_material": {"id": "red_material", "color": {"r": 255, "g": 0, "b": 0}},
            "blue_material": {"id": "blue_material", "color": {"r": 0, "g": 0, "b": 255}}
        }
    }

@pytest.fixture
def version_mismatch_manifest_content():
    """Returns a dictionary for a KFS manifest with an incompatible major version."""
    return {
        "kfs_version": "2.0.0", # Mismatched major version
        "name": "Version Mismatch Sculpture",
        "objects": [
            {
                "id": "obj1",
                "geometry_id": "sphere_geo",
                "material_id": "red_material",
                "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]}
            }
        ],
        "geometries": {
            "sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0}
        },
        "materials": {
            "red_material": {"id": "red_material", "color": {"r": 255, "g": 0, "b": 0}}
        }
    }

def write_manifest(path: Path, content: dict):
    """Helper to write a dictionary to a YAML file."""
    with open(path, "w", encoding="utf-8") as f:
        yaml.dump(content, f, indent=2, sort_keys=False)

def test_validate_single_valid_manifest(runner, tmp_path, valid_manifest_content):
    """Test `kfs validate` with a single valid manifest file."""
    manifest_path = tmp_path / "valid.kfs.yaml"
    write_manifest(manifest_path, valid_manifest_content)

    # For valid cases, input 'y' to confirm the prompt and allow normal exit
    result = runner.invoke(cli, ["validate", str(manifest_path)], input='y\n')

    assert result.exit_code == 0
    assert f"Validating '{manifest_path}'..." in result.stdout
    assert f"'{manifest_path}' is VALID." in result.stdout
    assert "Encountered 0 validation errors." in result.stdout
    assert "Overall KFS manifest validation: SUCCESS" in result.stdout
    assert "Validation FAILED" not in result.stdout
    assert result.exception is None

def test_validate_single_invalid_schema_manifest(runner, tmp_path, invalid_schema_manifest_content):
    """Test `kfs validate` with a single manifest file having schema validation errors."""
    manifest_path = tmp_path / "invalid_schema.kfs.yaml"
    write_manifest(manifest_path, invalid_schema_manifest_content)

    # For invalid cases, input 'n' to trigger `click.Abort` and thus a non-zero exit code
    result = runner.invoke(cli, ["validate", str(manifest_path)], input='n\n')

    assert result.exit_code == 1
    assert f"Validating '{manifest_path}'..." in result.stdout
    assert f"'{manifest_path}' is INVALID." in result.stdout
    assert "Schema Validation Error (Missing)" in result.stdout # Pydantic error for missing 'name'
    assert "field required" in result.stdout
    assert "Encountered 1 validation error." in result.stdout
    assert "Overall KFS manifest validation: FAILED" in result.stdout
    assert isinstance(result.exception, SystemExit) or isinstance(result.exception, Exception) # click.Abort is a subclass of SystemExit

def test_validate_single_invalid_semantic_manifest(runner, tmp_path, invalid_semantic_manifest_content):
    """Test `kfs validate` with a single manifest file having semantic validation errors."""
    manifest_path = tmp_path / "invalid_semantic.kfs.yaml"
    write_manifest(manifest_path, invalid_semantic_manifest_content)

    # For invalid cases, input 'n' to trigger `click.Abort` and thus a non-zero exit code
    result = runner.invoke(cli, ["validate", str(manifest_path)], input='n\n')

    assert result.exit_code == 1
    assert f"Validating '{manifest_path}'..." in result.stdout
    assert f"'{manifest_path}' is INVALID." in result.stdout
    assert "Semantic (DUPLICATE_OBJECTS_ID)" in result.stdout # Semantic error for duplicate object ID
    assert "Duplicate ID 'obj1' found in 'objects' collection." in result.stdout
    assert "Encountered 1 validation error." in result.stdout
    assert "Overall KFS manifest validation: FAILED" in result.stdout
    assert isinstance(result.exception, SystemExit) or isinstance(result.exception, Exception)

def test_validate_single_version_mismatch_manifest(runner, tmp_path, version_mismatch_manifest_content):
    """Test `kfs validate` with a single manifest file having a version mismatch."""
    manifest_path = tmp_path / "version_mismatch.kfs.yaml"
    write_manifest(manifest_path, version_mismatch_manifest_content)

    # Version mismatch errors are caught at a higher level, leading to an immediate error output
    # and then the `click.confirm` prompt. Input 'n' to cause non-zero exit.
    result = runner.invoke(cli, ["validate", str(manifest_path)], input='n\n')

    assert result.exit_code == 1
    assert f"Validating '{manifest_path}'..." in result.stdout
    assert f"Error processing '{manifest_path}': Manifest version '2.0.0' is incompatible with parser version '{KFS_MANIFEST_VERSION}'." in result.stderr
    assert f"'{manifest_path}' is INVALID (version mismatch)." in result.stdout # This message is printed to stdout in the CLI command
    assert "Overall KFS manifest validation: FAILED" in result.stdout
    assert isinstance(result.exception, SystemExit) or isinstance(result.exception, Exception)

def test_validate_non_existent_file(runner):
    """Test `kfs validate` with a file that does not exist."""
    # No tmp_path needed as we expect CLI to fail before filesystem interaction via click.Path(exists=True)
    non_existent_path_str = "non_existent.kfs.yaml"
    result = runner.invoke(cli, ["validate", non_existent_path_str])

    # Click's default exit code for missing argument file is 2
    assert result.exit_code == 2
    assert f"Error: No such file or directory: '{non_existent_path_str}'" in result.stderr
    assert result.exception is not None

def test_validate_multiple_files_mixed_results(
    runner, tmp_path, valid_manifest_content, invalid_schema_manifest_content
):
    """Test `kfs validate` with multiple files, some valid, some invalid."""
    valid_file = tmp_path / "valid_multi.kfs.yaml"
    invalid_file = tmp_path / "invalid_multi.kfs.yaml"
    write_manifest(valid_file, valid_manifest_content)
    write_manifest(invalid_file, invalid_schema_manifest_content)

    # Overall failure because one file failed. Input 'n' for the prompt.
    result = runner.invoke(cli, ["validate", str(valid_file), str(invalid_file)], input='n\n')

    assert result.exit_code == 1 # Overall failure because one file failed
    
    # Check output for valid file
    assert f"Validating '{valid_file}'..." in result.stdout
    assert f"'{valid_file}' is VALID." in result.stdout
    
    # Check output for invalid file
    assert f"Validating '{invalid_file}'..." in result.stdout
    assert f"'{invalid_file}' is INVALID." in result.stdout
    assert "Schema Validation Error (Missing)" in result.stdout
    assert "field required" in result.stdout
    
    assert "Overall KFS manifest validation: FAILED" in result.stdout
    assert "Total files checked: 2, Valid: 1, Invalid: 1" in result.stdout
    assert isinstance(result.exception, SystemExit) or isinstance(result.exception, Exception)
