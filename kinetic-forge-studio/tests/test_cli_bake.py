import pytest
from click.testing import CliRunner
from pathlib import Path
import yaml
from unittest.mock import patch, MagicMock
import requests

from kfs_cli.main import cli
from kfs_core.manifest_models import KFSManifest, MeshGeometry
from kfs_core.manifest_parser import load_kfs_manifest
from kfs_core.constants import KFS_MANIFEST_VERSION
from kfs_core.exceptions import AssetResolutionError, KFSManifestValidationError

@pytest.fixture
def runner():
    """Fixture for invoking CLI commands."""
    return CliRunner()

@pytest.fixture
def minimal_valid_manifest_data():
    """Returns a dictionary for a minimal valid KFS manifest template."""
    return {
        "kfs_version": KFS_MANIFEST_VERSION,
        "name": "Test Sculpture",
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
def create_manifest_file(tmp_path, minimal_valid_manifest_data):
    """Helper to create a KFS manifest file in a temporary directory."""
    def _creator(filename: str, manifest_data: dict, sub_dir: Path = tmp_path) -> Path:
        file_path = sub_dir / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, "w", encoding="utf-8") as f:
            yaml.dump(manifest_data, f)
        return file_path
    return _creator

@pytest.fixture
def create_dummy_asset(tmp_path):
    """Helper to create a dummy asset file."""
    def _creator(filename: str, content: str, sub_dir: Path = tmp_path) -> Path:
        asset_path = sub_dir / filename
        asset_path.parent.mkdir(parents=True, exist_ok=True)
        asset_path.write_text(content, encoding="utf-8")
        return asset_path
    return _creator

def test_bake_local_assets(runner, tmp_path, create_manifest_file, create_dummy_asset, minimal_valid_manifest_data):
    """Test `kfs bake` command with local asset references."""
    source_dir = tmp_path / "source_project"
    source_dir.mkdir()

    # Create a local OBJ asset
    obj_content = "v 0 0 0\nv 1 0 0\nf 1 2"
    local_obj_path = create_dummy_asset("models/simple.obj", obj_content, sub_dir=source_dir)

    # Create a manifest referencing the local OBJ
    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["name"] = "Local Asset Sculpture"
    manifest_data["geometries"]["mesh_geo"] = {"type": "mesh", "id": "mesh_geo", "path": str(Path("models") / "simple.obj")}
    manifest_data["objects"].append({
        "id": "obj2", "geometry_id": "mesh_geo", "material_id": "red_material",
        "transform": {"position": [1, 1, 1], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
        "animation": None
    })
    input_manifest_path = create_manifest_file("local_manifest.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_output"
    baked_project_name = "local_asset_sculpture_baked"
    expected_baked_dir = output_dir / baked_project_name
    expected_baked_manifest_path = expected_baked_dir / "kfs.yaml"
    expected_baked_asset_path = expected_baked_dir / "assets" / "simple.obj"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 0, f"CLI exited with error: {result.stderr}"
    assert f"Manifest loaded from '{input_manifest_path}'" in result.stdout
    assert f"Resolved asset '{local_obj_path}' to '{expected_baked_asset_path}'" in result.stdout
    assert f"Project baked to '{expected_baked_dir}'" in result.stdout

    # Verify output directory structure and files
    assert expected_baked_dir.is_dir()
    assert expected_baked_manifest_path.is_file()
    assert expected_baked_asset_path.is_file()
    assert expected_baked_asset_path.read_text() == obj_content

    # Verify baked manifest content
    baked_manifest = load_kfs_manifest(expected_baked_manifest_path)
    assert isinstance(baked_manifest, KFSManifest)
    assert baked_manifest.name == "Local Asset Sculpture"
    assert "mesh_geo" in baked_manifest.geometries
    assert isinstance(baked_manifest.geometries["mesh_geo"], MeshGeometry)
    assert baked_manifest.geometries["mesh_geo"].path == "assets/simple.obj"

def test_bake_remote_assets(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` command with remote HTTP asset references."""
    source_dir = tmp_path / "source_project_remote"
    source_dir.mkdir()

    remote_obj_url = "http://example.com/remote_models/complex.obj"
    remote_obj_content = b"# Remote OBJ content\nv 0 0 0\nv 1 0 0"

    # Create a manifest referencing the remote OBJ
    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["name"] = "Remote Asset Sculpture"
    manifest_data["geometries"]["remote_mesh_geo"] = {"type": "mesh", "id": "remote_mesh_geo", "path": remote_obj_url}
    manifest_data["objects"].append({
        "id": "obj3", "geometry_id": "remote_mesh_geo", "material_id": "red_material",
        "transform": {"position": [2, 2, 2], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
        "animation": None
    })
    input_manifest_path = create_manifest_file("remote_manifest.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_remote_output"
    baked_project_name = "remote_asset_sculpture_baked"
    expected_baked_dir = output_dir / baked_project_name
    expected_baked_manifest_path = expected_baked_dir / "kfs.yaml"
    # Mock requests.get for HTTPAssetHandler
    with patch('requests.get') as mock_get, \
         patch.object(__import__('kfs_core.assets.handlers', fromlist=['HttpAssetHandler']).HttpAssetHandler, '_is_safe_url', return_value=True):
        mock_response = MagicMock(spec=requests.Response)
        mock_response.status_code = 200
        mock_response.content = remote_obj_content
        mock_response.headers = {"Content-Length": str(len(remote_obj_content))}
        mock_response.iter_content = MagicMock(return_value=[remote_obj_content])
        mock_response.raise_for_status.return_value = None # No HTTP errors
        mock_get.return_value = mock_response

        result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

        assert result.exit_code == 0, f"CLI exited with error: {result.stderr}"
        mock_get.assert_called_once_with(remote_obj_url, stream=True, timeout=30)
        assert f"Project baked to '{expected_baked_dir}'" in result.stdout

        # Verify output directory structure and files
        assert expected_baked_dir.is_dir()
        assert expected_baked_manifest_path.is_file()

        # The cached filename includes a hash prefix for cache poisoning protection
        baked_assets = list((expected_baked_dir / "assets").glob("*complex.obj"))
        assert len(baked_assets) == 1, f"Expected one baked asset matching *complex.obj, found: {baked_assets}"
        assert baked_assets[0].read_bytes() == remote_obj_content

        # Verify baked manifest content
        baked_manifest = load_kfs_manifest(expected_baked_manifest_path)
        assert isinstance(baked_manifest, KFSManifest)
        assert baked_manifest.name == "Remote Asset Sculpture"
        assert "remote_mesh_geo" in baked_manifest.geometries
        assert isinstance(baked_manifest.geometries["remote_mesh_geo"], MeshGeometry)
        assert baked_manifest.geometries["remote_mesh_geo"].path.endswith("complex.obj")
        assert "assets/" in baked_manifest.geometries["remote_mesh_geo"].path

def test_bake_custom_name(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` with a custom project name using the --name option."""
    source_dir = tmp_path / "source_project_custom_name"
    source_dir.mkdir()

    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["name"] = "Original Project Name"
    input_manifest_path = create_manifest_file("custom_name_manifest.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_output_custom"
    custom_project_name = "MyCustomBakedProject"
    # --name is slugified for filesystem safety
    expected_baked_dir = output_dir / "mycustombakedproject"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir), "--name", custom_project_name])

    assert result.exit_code == 0, f"CLI exited with error: {result.stderr}"
    assert f"Project baked to '{expected_baked_dir}'" in result.stdout
    assert expected_baked_dir.is_dir()

    # Load the baked manifest and verify its 'name' field is updated
    # manifest.name keeps the original unsanitized value; only dir name is slugified
    baked_manifest = load_kfs_manifest(expected_baked_dir / "kfs.yaml")
    assert baked_manifest.name == custom_project_name

def test_bake_no_assets(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` with a manifest that has no external assets."""
    source_dir = tmp_path / "source_no_assets"
    source_dir.mkdir()

    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["name"] = "No Assets Sculpture"
    input_manifest_path = create_manifest_file("no_assets.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_no_assets_output"
    baked_project_name = "no_assets_sculpture_baked"
    expected_baked_dir = output_dir / baked_project_name
    expected_baked_manifest_path = expected_baked_dir / "kfs.yaml"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 0, f"CLI exited with error: {result.stderr}"
    assert "No external assets found in manifest." in result.stdout
    assert f"Project baked to '{expected_baked_dir}'" in result.stdout

    assert expected_baked_dir.is_dir()
    assert expected_baked_manifest_path.is_file()
    assert not (expected_baked_dir / "assets").exists() # No assets directory should be created

    baked_manifest = load_kfs_manifest(expected_baked_manifest_path)
    assert baked_manifest.name == "No Assets Sculpture"
    assert "geometries" in baked_manifest.model_dump()
    assert baked_manifest.geometries == {"sphere_geo": {"type": "sphere", "id": "sphere_geo", "radius": 1.0}}

def test_bake_handles_asset_resolution_error(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` correctly handles an AssetResolutionError during baking."""
    source_dir = tmp_path / "source_resolution_error"
    source_dir.mkdir()

    # Create a manifest referencing a non-existent local OBJ
    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["name"] = "Error Sculpture"
    manifest_data["geometries"]["missing_mesh"] = {"type": "mesh", "id": "missing_mesh", "path": "non_existent_models/missing.obj"}
    manifest_data["objects"].append({
        "id": "obj4", "geometry_id": "missing_mesh", "material_id": "red_material",
        "transform": {"position": [0, 0, 0], "rotation": [0, 0, 0], "scale": [1, 1, 1]},
        "animation": None
    })
    input_manifest_path = create_manifest_file("error_manifest.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_error_output"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 1 # Expect a failure
    assert "Error baking project:" in result.stderr
    assert "AssetResolutionError" in result.stderr
    assert "non_existent_models/missing.obj" in result.stderr
    assert not output_dir.exists() # Output directory should not be created on failure

def test_bake_manifest_load_error(runner, tmp_path, create_manifest_file):
    """Test `kfs bake` handles errors during manifest loading (e.g., invalid YAML)."""
    source_dir = tmp_path / "source_load_error"
    source_dir.mkdir()

    # Create an invalid YAML file
    invalid_yaml_content = "kfs_version: 1.0.0\nname: Invalid Manifest\nobjects: - id: obj1\n  invalid_indentation: true"
    input_manifest_path = create_manifest_file("invalid_syntax.kfs.yaml", invalid_yaml_content, sub_dir=source_dir)

    output_dir = tmp_path / "baked_load_error_output"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 1 # Expect a failure
    assert "Error baking project:" in result.stderr
    assert "InvalidKFSManifestError" in result.stderr
    assert "YAMLSyntaxError" in result.stderr
    assert not output_dir.exists() # Output directory should not be created on failure

def test_bake_manifest_validation_error(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` handles Pydantic validation errors during manifest loading."""
    source_dir = tmp_path / "source_validation_error"
    source_dir.mkdir()

    # Create a manifest with an invalid field (e.g., negative sphere radius)
    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["name"] = "Validation Error Sculpture"
    manifest_data["geometries"]["sphere_geo"] = {"type": "sphere", "id": "sphere_geo", "radius": -1.0} # Invalid

    input_manifest_path = create_manifest_file("validation_error.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_validation_error_output"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 1 # Expect a failure
    assert "Error baking project:" in result.stderr
    assert "KFSManifestValidationError" in result.stderr
    assert "radius" in result.stderr
    assert "ensure this value is greater than or equal to 0" in result.stderr
    assert not output_dir.exists() # Output directory should not be created on failure

def test_bake_missing_output_dir_parent(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` creates parent directories for the output directory if they don't exist."""
    source_dir = tmp_path / "source_project_missing_parent"
    source_dir.mkdir()

    manifest_data = minimal_valid_manifest_data.copy()
    input_manifest_path = create_manifest_file("manifest.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "non_existent_parent" / "baked_output_with_parent"
    baked_project_name = "test_sculpture_baked"
    expected_baked_dir = output_dir / baked_project_name

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 0, f"CLI exited with error: {result.stderr}"
    assert expected_baked_dir.is_dir()
    assert (expected_baked_dir / "kfs.yaml").is_file()

def test_bake_empty_manifest_object_list(runner, tmp_path, create_manifest_file, minimal_valid_manifest_data):
    """Test `kfs bake` with a manifest that has an empty 'objects' list (should fail validation)."""
    source_dir = tmp_path / "source_empty_objects"
    source_dir.mkdir()

    manifest_data = minimal_valid_manifest_data.copy()
    manifest_data["objects"] = [] # This makes it invalid per schema minItems: 1
    input_manifest_path = create_manifest_file("empty_objects.kfs.yaml", manifest_data, sub_dir=source_dir)

    output_dir = tmp_path / "baked_empty_objects_output"

    result = runner.invoke(cli, ["bake", str(input_manifest_path), str(output_dir)])

    assert result.exit_code == 1 # Expect a failure due to validation error
    assert "Error baking project:" in result.stderr
    assert "KFSManifestValidationError" in result.stderr
    assert "minItems" in result.stderr
    assert not output_dir.exists()
