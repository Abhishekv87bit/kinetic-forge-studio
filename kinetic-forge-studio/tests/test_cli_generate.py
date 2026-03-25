import pytest
from click.testing import CliRunner
from pathlib import Path
import yaml

from kfs_cli.main import cli
from kfs_core.manifest_models import KFSManifest
from kfs_core.manifest_parser import load_kfs_manifest
from kfs_core.constants import KFS_MANIFEST_VERSION, KFS_DEFAULT_MANIFEST_FILENAME

@pytest.fixture
def runner():
    """Fixture for invoking CLI commands."""
    return CliRunner()

def test_generate_default_filename(runner, tmp_path):
    """Test `kfs generate` creates a default manifest file with correct content."""
    # Change the current working directory to tmp_path
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        result = runner.invoke(cli, ["generate"])

        assert result.exit_code == 0, f"CLI exited with error: {result.stderr}"
        assert f"Generated blank KFS manifest to: {KFS_DEFAULT_MANIFEST_FILENAME}" in result.stdout

        manifest_path = Path(fs) / KFS_DEFAULT_MANIFEST_FILENAME
        assert manifest_path.exists()
        
        # Verify content can be loaded as a KFSManifest
        manifest = load_kfs_manifest(manifest_path)
        assert isinstance(manifest, KFSManifest)
        assert manifest.kfs_version == KFS_MANIFEST_VERSION
        assert manifest.name == "Untitled Kinetic Sculpture"
        assert manifest.description is None
        assert manifest.geometries == {}
        assert manifest.materials == {}
        assert manifest.objects == []
        assert manifest.simulation_settings == {}

def test_generate_custom_filename(runner, tmp_path):
    """Test `kfs generate [filename]` creates a manifest file with a custom name."""
    custom_filename = "my_sculpture.kfs.yaml"
    
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        result = runner.invoke(cli, ["generate", custom_filename])

        assert result.exit_code == 0
        assert f"Generated blank KFS manifest to: {custom_filename}" in result.stdout

        manifest_path = Path(fs) / custom_filename
        assert manifest_path.exists()

        # Verify content
        manifest = load_kfs_manifest(manifest_path)
        assert isinstance(manifest, KFSManifest)
        assert manifest.name == "My Sculpture"
        assert manifest.kfs_version == KFS_MANIFEST_VERSION

def test_generate_existing_file_no_overwrite(runner, tmp_path):
    """Test `kfs generate` fails if file exists and --overwrite is not used."""
    existing_filename = "existing.yaml"
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        # Create an empty file
        (Path(fs) / existing_filename).touch()

        result = runner.invoke(cli, ["generate", existing_filename])

        assert result.exit_code == 1  # Error: file exists without --overwrite
        assert f"Error: File '{existing_filename}' already exists. Use --overwrite to force overwrite." in result.stderr

        # Verify the file content was NOT changed
        with open(Path(fs) / existing_filename, "r", encoding="utf-8") as f:
            content = f.read()
        assert content == "" # Still empty

def test_generate_existing_file_with_overwrite(runner, tmp_path):
    """Test `kfs generate --overwrite` overwrites an existing file."""
    existing_filename = "overwrite.yaml"
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        # Create an existing file with dummy content
        initial_content = "not a kfs manifest: true"
        (Path(fs) / existing_filename).write_text(initial_content)

        result = runner.invoke(cli, ["generate", existing_filename, "--overwrite"])

        assert result.exit_code == 0
        assert f"Generated blank KFS manifest to: {existing_filename}" in result.stdout

        manifest_path = Path(fs) / existing_filename
        assert manifest_path.exists()

        # Verify content is now a valid KFS manifest
        manifest = load_kfs_manifest(manifest_path)
        assert isinstance(manifest, KFSManifest)
        assert manifest.kfs_version == KFS_MANIFEST_VERSION
        assert manifest.name == "Overwrite"

        # Ensure the old content is gone
        with open(manifest_path, "r", encoding="utf-8") as f:
            new_content_raw = f.read()
        assert initial_content not in new_content_raw
        assert "kfs_version" in new_content_raw

def test_generate_filename_with_spaces_and_hyphens(runner, tmp_path):
    """Test `kfs generate` correctly infers project name from complex filenames."""
    filename_hyphen = "my-awesome-sculpture.yaml"
    filename_underscore = "another_project.yaml"
    
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        # Test hyphenated filename
        result_hyphen = runner.invoke(cli, ["generate", filename_hyphen])
        assert result_hyphen.exit_code == 0
        manifest_hyphen = load_kfs_manifest(Path(fs) / filename_hyphen)
        assert manifest_hyphen.name == "My Awesome Sculpture"

        # Test underscored filename
        result_underscore = runner.invoke(cli, ["generate", filename_underscore])
        assert result_underscore.exit_code == 0
        manifest_underscore = load_kfs_manifest(Path(fs) / filename_underscore)
        assert manifest_underscore.name == "Another Project"

def test_generate_non_yaml_extension_is_not_blocked(runner, tmp_path):
    """Test that generate doesn't strictly enforce .yaml/.json extension for the path, 
    but still produces YAML content."""
    filename = "manifest.txt"
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        result = runner.invoke(cli, ["generate", filename])
        assert result.exit_code == 0
        assert f"Generated blank KFS manifest to: {filename}" in result.stdout

        manifest_path = Path(fs) / filename
        assert manifest_path.exists()
        
        # Ensure it's valid YAML, even if extension is .txt
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        loaded_content = yaml.safe_load(content)
        assert loaded_content["kfs_version"] == KFS_MANIFEST_VERSION
        assert loaded_content["name"] == "Manifest"

def test_generate_parent_directory_creation(runner, tmp_path):
    """Test `kfs generate` creates parent directories if they don't exist."""
    nested_filename = "subdir/nested/kfs.yaml"
    with runner.isolated_filesystem(temp_dir=tmp_path) as fs:
        result = runner.invoke(cli, ["generate", nested_filename])
        assert result.exit_code == 0
        assert f"Generated blank KFS manifest to: {nested_filename}" in result.stdout

        manifest_path = Path(fs) / nested_filename
        assert manifest_path.exists()
        assert manifest_path.parent.is_dir()
        
        # Verify content
        manifest = load_kfs_manifest(manifest_path)
        assert isinstance(manifest, KFSManifest)
        assert manifest.name == "Kfs"
