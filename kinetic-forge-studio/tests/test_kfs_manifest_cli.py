import pytest
import subprocess
import sys
from pathlib import Path

# Helper fixture to create temporary KFS YAML files
@pytest.fixture
def temp_kfs_yaml_file(tmp_path: Path):
    def _create_file(filename: str, content: str):
        file_path = tmp_path / filename
        file_path.write_text(content, encoding='utf-8')
        return file_path
    return _create_file

# Path to the CLI script relative to the project root
CLI_SCRIPT_PATH = Path(__file__).parent.parent / "src" / "kfs_manifest" / "cli.py"

# Content for a minimal valid KFS manifest (based on expected model structure)
VALID_KFS_CONTENT = """
version: "1.0"
metadata:
  name: "test_sculpture"
  description: "A simple test sculpture"
objects:
  - name: "cube_1"
    type: "rigid_body"
    transform:
      position: {x: 0, y: 0, z: 0}
      rotation: {x: 0, y: 0, z: 0, w: 1}
      scale: {x: 1, y: 1, z: 1}
    geometry_ref: "geometry_cube"
    material_ref: "material_default"
geometries:
  - name: "geometry_cube"
    type: "box"
    width: 1.0
    height: 1.0
    depth: 1.0
materials:
  - name: "material_default"
    type: "phong"
    color: "#FFFFFF"
animations: []
simulations:
  gravity: {x: 0, y: -9.81, z: 0}
  solver: "euler"
  timestep: 0.01
"""

# Content for a malformed YAML file (syntax error)
MALFORMED_YAML_CONTENT = """
version: "1.0"
metadata:
  name: "test_sculpture"
  description: "A simple test sculpture"
invalid_indent: this is a bad indentation
  field: value
"""

# Content for a YAML file with Pydantic validation errors (missing required field 'type' for object)
INVALID_SCHEMA_CONTENT = """
version: "1.0"
metadata:
  name: "test_sculpture"
  description: "A simple test sculpture"
objects:
  - name: "cube_1"
    # 'type' field is missing, which is required by KFSObject model
    transform:
      position: {x: 0, y: 0, z: 0}
      rotation: {x: 0, y: 0, z: 0, w: 1}
      scale: {x: 1, y: 1, z: 1}
    geometry_ref: "geometry_cube"
    material_ref: "material_default"
geometries:
  - name: "geometry_cube"
    type: "box"
    width: 1.0
    height: 1.0
    depth: 1.0
materials:
  - name: "material_default"
    type: "phong"
    color: "#FFFFFF"
animations: []
simulations:
  gravity: {x: 0, y: -9.81, z: 0}
  solver: "euler"
  timestep: 0.01
"""

def _run_cli(manifest_path: Path):
    """Helper to run the CLI script using subprocess and capture output."""
    result = subprocess.run(
        [sys.executable, str(CLI_SCRIPT_PATH), str(manifest_path)],
        capture_output=True,
        text=True,
        check=False  # Do not raise CalledProcessError for non-zero exit codes
    )
    return result

def test_cli_valid_manifest(temp_kfs_yaml_file):
    """Test CLI with a valid KFS manifest file."""
    manifest_path = temp_kfs_yaml_file("valid.kfs.yaml", VALID_KFS_CONTENT)
    result = _run_cli(manifest_path)

    assert result.returncode == 0
    assert f"Attempting to validate KFS manifest: '{manifest_path}'" in result.stdout
    assert f"Success: KFS Manifest '{manifest_path}' is valid." in result.stdout
    assert not result.stderr

def test_cli_malformed_yaml_manifest(temp_kfs_yaml_file):
    """Test CLI with a malformed YAML file (syntax error)."""
    manifest_path = temp_kfs_yaml_file("malformed.kfs.yaml", MALFORMED_YAML_CONTENT)
    result = _run_cli(manifest_path)

    assert result.returncode == 1
    assert f"Attempting to validate KFS manifest: '{manifest_path}'" in result.stdout
    combined = result.stdout + result.stderr
    assert f"Error parsing YAML from {manifest_path}" in combined
    assert "syntax error" in combined.lower() or "parser error" in combined.lower()
    assert f"Validation Failed: KFS Manifest '{manifest_path}' is invalid." in combined
    assert not result.stdout.strip().endswith("Success") # Ensure success message is not printed

def test_cli_invalid_schema_manifest(temp_kfs_yaml_file):
    """Test CLI with a YAML file that violates the KFS schema (Pydantic validation error)."""
    manifest_path = temp_kfs_yaml_file("invalid_schema.kfs.yaml", INVALID_SCHEMA_CONTENT)
    result = _run_cli(manifest_path)

    assert result.returncode == 1
    assert f"Attempting to validate KFS manifest: '{manifest_path}'" in result.stdout
    assert f"Error: KFS Manifest validation failed for '{manifest_path}':" in result.stderr
    assert "Field required" in result.stderr # Specific Pydantic error for missing 'type'
    assert f"Validation Failed: KFS Manifest '{manifest_path}' is invalid." in result.stderr
    assert not result.stdout.strip().endswith("Success") # Ensure success message is not printed

def test_cli_file_not_found(tmp_path: Path):
    """Test CLI when the specified manifest file does not exist."""
    non_existent_path = tmp_path / "non_existent.kfs.yaml"
    result = _run_cli(non_existent_path)

    assert result.returncode == 1
    assert f"Error: File not found at '{non_existent_path}'" in result.stderr
    assert not result.stdout

def test_cli_path_is_directory(tmp_path: Path):
    """Test CLI when the specified path is a directory, not a file."""
    directory_path = tmp_path / "my_dir"
    directory_path.mkdir()
    result = _run_cli(directory_path)

    assert result.returncode == 1
    assert f"Error: Path '{directory_path}' is not a file." in result.stderr
    assert not result.stdout

def test_cli_no_arguments():
    """Test CLI when no arguments are provided (argparse usage error)."""
    result = subprocess.run(
        [sys.executable, str(CLI_SCRIPT_PATH)],
        capture_output=True,
        text=True,
        check=False
    )
    assert result.returncode == 2 # argparse typically exits with 2 for usage errors
    assert "argument manifest_file: the following arguments are required: manifest_file" in result.stderr
    assert "usage: cli.py" in result.stderr
    assert not result.stdout
