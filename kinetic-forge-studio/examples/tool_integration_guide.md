# KFS Tool Integration Guide

This guide is for developers and advanced users who want to integrate with the Kinetic Forge Studio (KFS) manifest system programmatically or via the command-line interface (CLI).

## KFS Command-Line Interface (CLI)

The KFS CLI (`kfs`) provides a set of commands to manage, validate, and prepare your kinetic sculpture manifests.

### Installation

Assuming you have Python installed, you can typically install the KFS CLI via pip:

```bash
pip install kfs-studio # (Placeholder: Actual package name might differ)
```

### Core Commands

-   `kfs --version`: Display the current version of the KFS CLI and manifest schema.

-   `kfs generate [FILENAME] [--overwrite|-o]`
    -   **Description**: Creates a blank KFS manifest file template. Useful for starting new projects.
    -   `FILENAME`: The desired name for the manifest file (defaults to `kfs.yaml`).
    -   `--overwrite`, `-o`: Force overwrite if the file already exists.
    -   **Example**:
        ```bash
        kfs generate my_new_sculpture.kfs.yaml
        ```

-   `kfs validate <FILES...>`
    -   **Description**: Validates one or more KFS manifest files against the JSON Schema and additional semantic rules. It checks for structural correctness, valid data types, and logical consistency (e.g., all `geometry_id`s and `material_id`s must refer to existing definitions).
    -   `FILES`: One or more paths to `.kfs.yaml` or `.kfs.json` files.
    -   **Example**:
        ```bash
        kfs validate my_sculpture.kfs.yaml another_project.kfs.yaml
        ```

-   `kfs bake <MANIFEST_FILE> <OUTPUT_DIR> [--name|-n <PROJECT_NAME>]`
    -   **Description**: Resolves all external assets (e.g., 3D models, textures) referenced in a KFS manifest and bundles them into a self-contained output directory. This creates a portable project ready for distribution or deployment.
    -   `MANIFEST_FILE`: Path to the input `.kfs.yaml` or `.kfs.json` manifest.
    -   `OUTPUT_DIR`: Path to the directory where the baked project will be saved. The manifest itself will be rewritten to point to the local copies of the assets within this directory.
    -   `--name`, `-n`: Optional. A name for the baked project. Defaults to the original manifest's name.
    -   **Example**:
        ```bash
        kfs bake my_sculpture.kfs.yaml ./baked_project -n "Exported Sculpture 2023"
        ```

## Programmatic Access (Python Library)

The KFS core library (`kfs_core`) provides Python classes and functions to work with manifests directly in your applications.

### Loading and Saving Manifests

You can load a manifest file into a Pydantic model for easy Pythonic access and validation:

```python
from kfs_core.manifest_parser import load_kfs_manifest, save_kfs_manifest
from kfs_core.manifest_models import KFSManifest
from pathlib import Path

try:
    manifest_path = Path("my_sculpture.kfs.yaml")
    manifest: KFSManifest = load_kfs_manifest(manifest_path)
    print(f"Manifest '{manifest.name}' loaded successfully.")

    # Modify the manifest programmatically
    manifest.description = "Updated description via Python API."
    if manifest.objects:
        manifest.objects[0].transform.position = [10.0, 5.0, 0.0]
    
    # Save the modified manifest (e.g., to a new file)
    save_kfs_manifest(manifest, Path("my_sculpture_modified.kfs.json"))
    print("Manifest saved successfully.")

except Exception as e:
    print(f"Error loading/saving manifest: {e}")
```

### Validation

For custom validation logic or integration into CI/CD pipelines, you can use the `KFSManifestValidator`:

```python
from kfs_core.validator.manifest_validator import KFSManifestValidator
from kfs_core.exceptions import KFSManifestValidationError, ManifestVersionMismatchError, InvalidKFSManifestError
from pathlib import Path

validator = KFSManifestValidator()
manifest_file = Path("my_sculpture.kfs.yaml")

try:
    validator.validate_manifest_file(manifest_file)
    print(f"'{manifest_file}' is valid.")
except KFSManifestValidationError as e:
    print(f"Validation failed for '{manifest_file}':")
    for error in e.errors:
        print(f"  - [Path: {error.get('path', 'N/A')}] {error.get('message', 'N/A')} (Type: {error.get('type', 'N/A')})")
except (ManifestVersionMismatchError, InvalidKFSManifestError, FileNotFoundError) as e:
    print(f"Error processing '{manifest_file}': {e}")
```

### Asset Resolution

The `AssetResolver` component allows you to programmatically resolve asset URIs (e.g., `http://`, `file://`, local paths) to local file paths, potentially downloading and caching remote assets.

```python
from kfs_core.assets.resolver import AssetResolver
from kfs_core.assets.handlers import FileAssetHandler, HttpAssetHandler
from kfs_core.exceptions import AssetResolutionError
from pathlib import Path

# Initialize with default handlers, or custom ones
asset_resolver = AssetResolver()

# Or with a custom cache directory
cache_dir = Path("./my_asset_cache")
asset_resolver_with_cache = AssetResolver(default_cache_dir=cache_dir)

try:
    # Resolve a local file path (relative to current working directory)
    local_asset_path = asset_resolver.resolve("assets/models/fancy_gear.obj")
    print(f"Local asset resolved to: {local_asset_path}")

    # Resolve a remote asset (will be downloaded to cache_dir if not present)
    remote_asset_uri = "https://example.com/models/remote_texture.png"
    remote_asset_path = asset_resolver_with_cache.resolve(remote_asset_uri)
    print(f"Remote asset resolved to: {remote_asset_path}")

except AssetResolutionError as e:
    print(f"Asset resolution failed: {e}")

```

## JSON Schema Integration

For IDEs and other tools that support JSON Schema, you can point them to the generated KFS manifest schema. This provides features like autocompletion, inline documentation, and real-time validation.

The schema is generated to `kfs_core/validator/schemas/kfs_vX.Y.json` (where `X.Y` is the major.minor version of the manifest).

-   **Schema URL**: `https://kineticforge.studio/schemas/kfs_v1.0.json` (for version 1.0 manifests)
-   **Local Schema Path**: `kfs_core/validator/schemas/kfs_v1.0.json` (relative to the KFS library root)

Many IDEs (like VS Code with the YAML Language Server extension) allow you to associate schema files with specific file patterns (`*.kfs.yaml`).

## Best Practices

-   **Version Control**: Always keep your `.kfs.yaml` files under version control (e.g., Git).
-   **Modularity**: For large projects, consider breaking down complex geometry or material definitions into separate files and using an external tooling layer to compose them if direct manifest features become insufficient (though the `geometries` and `materials` maps already offer good reuse).
-   **Asset Paths**: Use relative paths for local assets where possible to ensure portability within a project. For remote assets, use full URIs.
-   **Validation**: Regularly validate your manifests, especially before committing changes or deploying. The `kfs validate` CLI command is your friend!

---