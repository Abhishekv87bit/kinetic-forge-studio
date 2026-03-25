import pytest
import subprocess
import os
from pathlib import Path
import tempfile
import json
import shutil # For creating subdirectories

# Assuming the main CLI script is executable via python -m backend.kfs_manifest.cli.main
# We need to find the root of the project to correctly run the module.

# Determine project root dynamically
# Assuming this test file is located at project_root/tests/cli/test_cli.py
current_file_path = Path(__file__)
project_root = current_file_path.parents[2] 

CLI_SCRIPT = ["python", "-m", "backend.kfs_manifest.cli.main"]

def run_cli_command(command_args, manifest_content=None, asset_files=None, expected_exit_code=0):
    """
    Helper to run a CLI command with a temporary manifest file and optional asset files.
    Returns (exit_code, stdout, stderr).
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        manifest_path = None
        if manifest_content is not None:
            manifest_path = tmp_path / "test_manifest.kfs.yaml"
            manifest_path.write_text(manifest_content)
            # Add manifest path to command args unless it's already there (e.g., for non_existent_file tests)
            if not any(arg.endswith(".kfs.yaml") for arg in command_args):
                command_args = command_args + [str(manifest_path)]

        if asset_files:
            for asset_name, asset_content in asset_files.items():
                asset_file_path = tmp_path / asset_name
                asset_file_path.parent.mkdir(parents=True, exist_ok=True) # Ensure parent directories exist
                asset_file_path.write_text(asset_content)
        
        full_command = CLI_SCRIPT + command_args
        
        process = subprocess.run(
            full_command,
            capture_output=True,
            text=True,
            check=False, # Don't raise CalledProcessError on non-zero exit codes
            cwd=project_root # Run from project root
        )
        
        return process.returncode, process.stdout.strip(), process.stderr.strip()

# --- Test Cases for 'validate' command ---

def test_validate_valid_manifest():
    """Test validation of a valid KFS manifest."""
    valid_manifest_content = """
kfs_version: "1.0.0"
components: []
"""
    exit_code, stdout, stderr = run_cli_command(["validate"], valid_manifest_content)
    assert exit_code == 0
    assert "Validation successful." in stdout
    assert not stderr

def test_validate_invalid_yaml_syntax():
    """Test validation with a manifest containing invalid YAML syntax."""
    invalid_manifest_content = """
kfs_version: "1.0.0"
  components: - invalid indentation # YAML syntax error
"""
    exit_code, stdout, stderr = run_cli_command(["validate"], invalid_manifest_content, expected_exit_code=1)
    assert exit_code != 0
    assert "YAML parsing error" in stderr or "Error loading manifest" in stderr
    assert "Validation successful." not in stdout

def test_validate_invalid_schema_missing_required_field():
    """Test validation with a manifest that violates the KFS schema (missing required field)."""
    invalid_schema_content = """
components:
  - name: test_component
    type: "rigid_body"
    geometry:
      type: "mesh"
      source: "path/to/mesh.obj"
"""
    exit_code, stdout, stderr = run_cli_command(["validate"], invalid_schema_content, expected_exit_code=1)
    assert exit_code != 0
    assert "Validation failed." in stderr
    assert "'kfs_version' is a required property" in stderr or "Field required" in stderr
    assert not stdout

def test_validate_invalid_schema_unrecognized_component_type():
    """Test validation with a manifest using an unrecognized component type."""
    invalid_schema_content = """
kfs_version: "1.0.0"
components:
  - name: unknown_type_component
    type: "non_existent_type" # Should be a known type like "rigid_body", "kinematic_chain", etc.
    geometry:
      type: "mesh"
      source: "path/to/mesh.obj"
"""
    exit_code, stdout, stderr = run_cli_command(["validate"], invalid_schema_content, expected_exit_code=1)
    assert exit_code != 0
    assert "Validation failed." in stderr
    assert "value is not a valid enumeration member" in stderr or "Unknown discriminator value" in stderr
    assert not stdout

def test_validate_non_existent_file():
    """Test validation with a non-existent manifest file."""
    # We pass a path directly, so manifest_content is None
    exit_code, stdout, stderr = run_cli_command(["validate", "non_existent_file.kfs.yaml"], expected_exit_code=1)
    assert exit_code != 0
    assert "Error loading manifest" in stderr or "No such file or directory" in stderr or "FileNotFoundError" in stderr
    assert not stdout

# --- Test Cases for 'resolve' command ---

def test_resolve_valid_manifest_with_local_asset():
    """Test resolution of a valid manifest with a local asset."""
    asset_content = "This is some dummy asset data for my_asset.obj."
    valid_manifest_content = f"""
kfs_version: "1.0.0"
components:
  - name: my_geometry
    type: "rigid_body"
    geometry:
      type: "mesh"
      source: "data/my_asset.obj" # Relative path to an asset
    visual:
      - name: visual_geom
        geometry_ref: my_geometry
        material:
          color: [1.0, 0.0, 0.0, 1.0]
"""
    asset_files = {"data/my_asset.obj": asset_content}
    
    exit_code, stdout, stderr = run_cli_command(["resolve"], valid_manifest_content, asset_files)
    
    assert exit_code == 0
    assert "Resolution successful." in stdout
    assert not stderr

    # The `resolve` command is expected to print the resolved manifest as JSON.
    # The output might have a "Resolution successful." message first.
    json_output_start_index = stdout.find('{')
    if json_output_start_index == -1:
        pytest.fail(f"Could not find JSON output in stdout: {stdout}")
    
    json_part = stdout[json_output_start_index:]

    try:
        resolved_manifest = json.loads(json_part)
        assert "components" in resolved_manifest
        assert resolved_manifest["components"][0]["name"] == "my_geometry"
        
        resolved_source_path = resolved_manifest["components"][0]["geometry"]["source"]
        # The resolver should ideally convert the relative path to an absolute path within the temp directory.
        assert "data/my_asset.obj" not in resolved_source_path # Should be resolved from original relative path
        assert os.path.isabs(resolved_source_path) # Should be an absolute path
        assert "my_asset.obj" in resolved_source_path
        
        # Check if the resolved path actually exists (points to the temp asset file)
        assert Path(resolved_source_path).is_file()
        assert Path(resolved_source_path).read_text() == asset_content
        
    except json.JSONDecodeError:
        pytest.fail(f"Resolved output is not valid JSON:\n{json_part}\nFull stdout:\n{stdout}")
    except KeyError as e:
        pytest.fail(f"Missing key in resolved manifest: {e}. Output:\n{json_part}")


def test_resolve_manifest_with_missing_asset():
    """Test resolution of a manifest referencing a non-existent asset."""
    missing_asset_manifest_content = """
kfs_version: "1.0.0"
components:
  - name: my_geometry
    type: "rigid_body"
    geometry:
      type: "mesh"
      source: "non_existent_asset.obj"
"""
    exit_code, stdout, stderr = run_cli_command(["resolve"], missing_asset_manifest_content, expected_exit_code=1)
    assert exit_code != 0
    assert "Resolution failed." in stderr
    assert "AssetResolutionError" in stderr or "not found" in stderr or "FileNotFoundError" in stderr
    assert not stdout

def test_resolve_invalid_manifest_schema_error():
    """Test resolution with an invalid manifest (schema error)."""
    # The 'resolve' command should internally call validation first.
    invalid_manifest_content = """
components: [] # Missing kfs_version
"""
    exit_code, stdout, stderr = run_cli_command(["resolve"], invalid_manifest_content, expected_exit_code=1)
    assert exit_code != 0
    assert "Resolution failed." in stderr # Or "Validation failed" if it fails early
    assert "'kfs_version' is a required property" in stderr or "Field required" in stderr
    assert not stdout

def test_resolve_non_existent_file():
    """Test resolution with a non-existent manifest file."""
    exit_code, stdout, stderr = run_cli_command(["resolve", "non_existent_file.kfs.yaml"], expected_exit_code=1)
    assert exit_code != 0
    assert "Error loading manifest" in stderr or "No such file or directory" in stderr or "FileNotFoundError" in stderr
    assert not stdout

# --- Test Cases for 'generate-schema' command ---

def test_generate_schema_command():
    """Test the 'generate-schema' command."""
    exit_code, stdout, stderr = run_cli_command(["generate-schema"])
    assert exit_code == 0
    assert not stderr
    
    try:
        schema = json.loads(stdout)
        assert "$schema" in schema
        assert "title" in schema
        assert "properties" in schema
        assert "KFSManifest" in schema.get("title", "") # Assuming the main schema is named KFSManifest
        assert "kfs_version" in schema["properties"]
        assert "components" in schema["properties"]
    except json.JSONDecodeError:
        pytest.fail(f"Generated schema is not valid JSON:\n{stdout}")
