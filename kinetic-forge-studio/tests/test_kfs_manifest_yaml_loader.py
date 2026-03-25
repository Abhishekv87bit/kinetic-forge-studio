import pytest
from pathlib import Path
from unittest.mock import patch, mock_open

from src.kfs_manifest.yaml_loader import load_kfs_yaml

# Helper function to create a dummy file for testing
@pytest.fixture
def temp_yaml_file(tmp_path: Path):
    def _create_file(filename: str, content: str):
        file_path = tmp_path / filename
        file_path.write_text(content, encoding='utf-8')
        return file_path
    return _create_file


def test_load_kfs_yaml_success(temp_yaml_file):
    """Tests successful loading of a valid YAML file."""
    yaml_content = """
    version: "1.0"
    metadata:
      name: "test_sculpture"
      description: "A simple test sculpture"
    objects:
      - name: "box_1"
        type: "box"
        transform:
          position: {x: 0, y: 0, z: 0}
    """
    file_path = temp_yaml_file("valid.kfs.yaml", yaml_content)
    data = load_kfs_yaml(file_path)

    assert data is not None
    assert isinstance(data, dict)
    assert data["version"] == "1.0"
    assert data["metadata"]["name"] == "test_sculpture"
    assert len(data["objects"]) == 1


def test_load_kfs_yaml_file_not_found(capfd):
    """Tests handling of a non-existent file."""
    non_existent_path = Path("non_existent.kfs.yaml")
    data = load_kfs_yaml(non_existent_path)

    assert data is None
    out, err = capfd.readouterr()
    assert f"Error: File not found at {non_existent_path}" in out


def test_load_kfs_yaml_malformed_yaml(temp_yaml_file, capfd):
    """Tests handling of malformed YAML content."""
    malformed_content = """
    version: "1.0"
    objects:
      - name: "box_1"
        type: "box"
    - This line is not valid YAML syntax
    """
    file_path = temp_yaml_file("malformed.kfs.yaml", malformed_content)
    data = load_kfs_yaml(file_path)

    assert data is None
    out, err = capfd.readouterr()
    assert f"Error parsing YAML from {file_path}" in out
    assert "syntax error" in out or "parser error" in out.lower()


def test_load_kfs_yaml_empty_file(temp_yaml_file):
    """Tests loading an empty YAML file (which is valid YAML, resulting in None)."""
    file_path = temp_yaml_file("empty.kfs.yaml", "")
    data = load_kfs_yaml(file_path)

    assert data == {} # yaml.safe_load('') returns None, but our function converts to {} if not dict

def test_load_kfs_yaml_scalar_root(temp_yaml_file):
    """Tests loading a YAML file whose root is a scalar, not a dictionary."""
    file_path = temp_yaml_file("scalar_root.kfs.yaml", "just_a_string")
    data = load_kfs_yaml(file_path)

    assert data == {}

def test_load_kfs_yaml_list_root(temp_yaml_file):
    """Tests loading a YAML file whose root is a list, not a dictionary."""
    list_content = """
    - item1
    - item2
    """
    file_path = temp_yaml_file("list_root.kfs.yaml", list_content)
    data = load_kfs_yaml(file_path)

    assert data == {}


def test_load_kfs_yaml_io_error(tmp_path, capfd):
    """Tests handling of an IOError during file reading."""
    # Simulate an IOError by mocking open
    mock_file_path = tmp_path / "io_error.kfs.yaml"
    mock_file_path.touch() # Ensure the file exists for the initial check

    with patch('builtins.open', mock_open()) as mocked_open:
        mocked_open.side_effect = IOError("Permission denied")
        data = load_kfs_yaml(mock_file_path)

        assert data is None
        out, err = capfd.readouterr()
        assert f"Error reading file {mock_file_path}: Permission denied" in out
