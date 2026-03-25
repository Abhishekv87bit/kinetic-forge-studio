# KFS Core Library API Reference

This document outlines the main entry points and key components of the Kinetic Forge Studio (KFS) Python core library (`kfs_core`). This initial overview focuses on commonly used classes and functions for interacting with KFS manifests programmatically.

For detailed, auto-generated documentation, please refer to future Sphinx or similar documentation builds.

## `kfs_core.manifest_models`

This module contains the Pydantic models that define the structure of a `.kfs.yaml` manifest. These models provide data validation, serialization, and deserialization capabilities. They are the backbone of type-safe manifest manipulation.

-   **`KFSManifest`**: The root model representing an entire KFS project manifest.
-   **`KFSObject`**: Defines an individual kinetic sculpture object, including its geometry, material, transform, and animation.
-   **`Geometry` (Union)**: A type alias for various geometry definitions (`SphereGeometry`, `CubeGeometry`, `MeshGeometry`).
-   **`Material`**: Defines the visual properties of an object.
-   **`Transform`**: Represents position, rotation, and scale.
-   **`Animation`, `AnimationTrack`, `Keyframe`**: Models for defining object animations.
-   **`RGBColor`**: A utility model for representing colors.

**Usage Example**:
```python
from kfs_core.manifest_models import KFSManifest, SphereGeometry, RGBColor

# Create a new manifest object
manifest = KFSManifest(
    kfs_version="1.0.0",
    name="My Programmatic Sculpture",
    objects=[] # Objects are required, even if empty initially
)

# Define a geometry and material
sphere_geo = SphereGeometry(id="program_sphere", radius=2.0)
red_color = RGBColor(r=255, g=0, b=0)
red_material = manifest.materials.get("red_mat")
if not red_material:
    from kfs_core.manifest_models import Material
    red_material = Material(id="program_red", color=red_color)
    manifest.materials[red_material.id] = red_material

# Add them to the manifest (geometries are a Dict, not a list)
manifest.geometries[sphere_geo.id] = sphere_geo

# ... and so on for objects
```

## `kfs_core.manifest_parser`

This module provides functions for loading and saving `KFSManifest` objects from/to YAML or JSON files.

-   **`load_kfs_manifest(file_path: Union[str, Path]) -> KFSManifest`**:
    -   Loads a manifest file from the given path, performs basic parsing and Pydantic validation, and returns a `KFSManifest` object.
    -   Raises `FileNotFoundError`, `InvalidKFSManifestError`, `ManifestVersionMismatchError`, or `KFSManifestValidationError`.

-   **`save_kfs_manifest(manifest: KFSManifest, file_path: Union[str, Path]) -> None`**:
    -   Saves a `KFSManifest` object to the specified file path. Supports both YAML and JSON based on file extension.

**Usage Example**:
```python
from kfs_core.manifest_parser import load_kfs_manifest, save_kfs_manifest
from pathlib import Path

manifest = load_kfs_manifest(Path("my_sculpture.kfs.yaml"))
print(manifest.name)
manifest.description = "Modified via parser"
save_kfs_manifest(manifest, Path("my_sculpture_updated.kfs.yaml"))
```

## `kfs_core.validator.manifest_validator`

This module contains the primary class for performing comprehensive validation of KFS manifests.

-   **`class KFSManifestValidator(schema_path: Optional[Union[str, Path]] = None)`**:
    -   Initializes the validator. Can be configured with a custom JSON schema path, though it defaults to the built-in schema for the current KFS version.
    -   **`validate_manifest_file(file_path: Union[str, Path]) -> KFSManifest`**:
        -   Loads and validates a manifest file against both its JSON Schema and semantic rules (e.g., ID references).
        -   Returns the validated `KFSManifest` object if successful.
        -   Raises `KFSManifestValidationError` if any validation issues are found, containing a list of detailed errors.

**Usage Example**:
```python
from kfs_core.validator.manifest_validator import KFSManifestValidator
from kfs_core.exceptions import KFSManifestValidationError
from pathlib import Path

validator = KFSManifestValidator()
try:
    validated_manifest = validator.validate_manifest_file(Path("my_sculpture.kfs.yaml"))
    print(f"Manifest '{validated_manifest.name}' is valid.")
except KFSManifestValidationError as e:
    print(f"Validation failed: {e.errors}")
```

## `kfs_core.assets.resolver`

This module provides a unified interface for resolving external asset URIs to local file paths, handling various schemes like local files (`file://`, plain paths) and HTTP/HTTPS URLs.

-   **`class AssetResolver(handlers: Optional[List[AssetHandler]] = None, default_cache_dir: Optional[Path] = None)`**:
    -   Initializes the asset resolver. Can be configured with custom asset handlers and a default cache directory for remote assets.
    -   **`resolve(uri: str, cache_dir: Optional[Path] = None) -> Path`**:
        -   Resolves the given URI to a local file path. Downloads remote assets to `cache_dir` (or `default_cache_dir` or a temporary directory) if necessary.
        -   Raises `AssetResolutionError` if resolution fails.

**Usage Example**:
```python
from kfs_core.assets.resolver import AssetResolver
from pathlib import Path

resolver = AssetResolver(default_cache_dir=Path("./asset_cache"))

try:
    local_file = resolver.resolve("path/to/local/model.obj")
    remote_file = resolver.resolve("https://example.com/textures/wood.png")
    print(f"Resolved local: {local_file}")
    print(f"Resolved remote: {remote_file}")
except Exception as e:
    print(f"Error resolving asset: {e}")
```

## `kfs_core.constants` and `kfs_core.exceptions`

These modules define global constants (like `KFS_MANIFEST_VERSION`) and custom exception classes for KFS-specific errors, allowing for robust error handling.

---