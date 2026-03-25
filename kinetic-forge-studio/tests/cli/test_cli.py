#!/usr/bin/env python3

import pytest
from click.testing import CliRunner
from pathlib import Path
import yaml

from backend.kfs_manifest.cli.main import cli

@pytest.fixture
def runner():
    return CliRunner()

@pytest.fixture
def temp_manifest_dir(tmp_path):
    # Create a temporary directory for manifests
    manifest_dir = tmp_path / "manifests"
    manifest_dir.mkdir()
    return manifest_dir

@pytest.fixture
def valid_manifest_content():
    return {
        "kfs_version": "1.0.0",
        "metadata": {
            "name": "valid_test_system",
            "description": "A valid test kinetic system manifest."
        },
        "components": [
            {
                "type": "static_geometry",
                "name": "base_plate",
                "geometry": {
                    "type": "mesh",
                    "path": "kfs://asset/meshes/base_plate.stl"
                }
            }
        ]
    }

@pytest.fixture
def invalid_manifest_content_missing_kfs_version():
    return {
        "metadata": {
            "name": "invalid_test_system",
            "description": "An invalid manifest missing kfs_version."
        },
        "components": [
            {
                "type": "static_geometry",
                "name": "base_plate",
                "geometry": {
                    "type": "mesh",
                    "path": "kfs://asset/meshes/base_plate.stl"
                }
            }
        ]
    }

@pytest.fixture
def invalid_manifest_content_bad_kfs_version():
    return {
        "kfs_version": "99.99.99", # Non-existent version
        "metadata": {
            "name": "invalid_version_system",
            "description": "An invalid manifest with a bad kfs_version."
        },
        "components": [
            {
                "type": "static_geometry",
                "name": "base_plate",
                "geometry": {
                    "type": "mesh",
                    "path": "kfs://asset/meshes/base_plate.stl"
                }
            }
        ]
    }

def test_validate_valid_manifest(runner, temp_manifest_dir, valid_manifest_content):
    manifest_path = temp_manifest_dir / "valid_manifest.kfs.yaml"
    with open(manifest_path, "w") as f:
        yaml.dump(valid_manifest_content, f)

    result = runner.invoke(cli, ["validate", str(manifest_path)])

    assert result.exit_code == 0
    assert "Manifest is valid." in result.output
    assert "Error" not in result.output


def test_validate_invalid_manifest_missing_kfs_version(runner, temp_manifest_dir, invalid_manifest_content_missing_kfs_version):
    manifest_path = temp_manifest_dir / "invalid_manifest_missing_version.kfs.yaml"
    with open(manifest_path, "w") as f:
        yaml.dump(invalid_manifest_content_missing_kfs_version, f)

    result = runner.invoke(cli, ["validate", str(manifest_path)])

    assert result.exit_code == 1 # Expect a non-zero exit code for invalid manifest
    assert "Manifest validation failed." in result.output
    assert "field required" in result.output # Pydantic error message


def test_validate_invalid_manifest_bad_kfs_version(runner, temp_manifest_dir, invalid_manifest_content_bad_kfs_version):
    manifest_path = temp_manifest_dir / "invalid_manifest_bad_version.kfs.yaml"
    with open(manifest_path, "w") as f:
        yaml.dump(invalid_manifest_content_bad_kfs_version, f)

    result = runner.invoke(cli, ["validate", str(manifest_path)])

    assert result.exit_code == 1
    assert "Manifest validation failed." in result.output
    assert "Unsupported KFS version" in result.output


def test_validate_non_existent_manifest(runner, temp_manifest_dir):
    non_existent_path = temp_manifest_dir / "non_existent.kfs.yaml"

    result = runner.invoke(cli, ["validate", str(non_existent_path)])

    assert result.exit_code == 1
    assert f"Error: File not found: {non_existent_path}" in result.output


def test_validate_invalid_yaml_format(runner, temp_manifest_dir):
    malformed_yaml_path = temp_manifest_dir / "malformed.kfs.yaml"
    with open(malformed_yaml_path, "w") as f:
        f.write("kfs_version: 1.0.0\n  metadata:\n name: bad_indentation") # Intentional bad indentation

    result = runner.invoke(cli, ["validate", str(malformed_yaml_path)])

    assert result.exit_code == 1
    assert "Error: Failed to parse manifest file" in result.output
    assert "ScannerError" in result.output or "ParserError" in result.output # Specific YAML parsing error


def test_generate_schema_command(runner, temp_manifest_dir):
    output_path = temp_manifest_dir / "kfs_schema.json"

    result = runner.invoke(cli, ["generate-schema", "--output", str(output_path)])

    assert result.exit_code == 0
    assert "KFS Manifest JSON schema generated successfully" in result.output
    assert output_path.exists()

    # Optionally, load and validate the generated schema structure
    with open(output_path, "r") as f:
        schema = json.load(f)
    assert "$schema" in schema
    assert "$id" in schema
    assert "title" in schema
    assert "description" in schema
    assert "type" in schema
    assert "properties" in schema


import json # Moved import inside the test function where it's used if not needed globally for other tests
