from typing import Union
from pathlib import Path

from backend.kfs_manifest.asset_types import AssetReference, LocalFileAssetReference, URLAssetReference, AssetType


class AssetResolutionError(Exception):
    """Custom exception for asset resolution failures."""
    pass


class AssetResolver:
    """Resolves various types of asset references into their usable forms.

    This class provides methods to process different AssetReference types
    and return their resolved paths or URLs, potentially performing checks
    or transformations.
    """

    def __init__(self, base_path: Union[Path, str] = None):
        """Initializes the AssetResolver.

        Args:
            base_path: An optional base path to resolve relative file paths against.
                       If None, relative paths are resolved against the current working directory.
        """
        self._base_path = Path(base_path).resolve() if base_path else Path.cwd()

    def resolve_local_file(self, asset_ref: LocalFileAssetReference) -> Path:
        """Resolves a local file asset reference.

        Args:
            asset_ref: The LocalFileAssetReference object.

        Returns:
            The absolute path to the local file.

        Raises:
            AssetResolutionError: If the file path is invalid or cannot be resolved.
        """
        if not isinstance(asset_ref, LocalFileAssetReference):
            raise TypeError("Expected LocalFileAssetReference type.")

        try:
            # FilePath from Pydantic automatically handles basic path validation during model creation.
            # Here we resolve to an absolute path, potentially against a base path.
            resolved_path = Path(asset_ref.path)
            if not resolved_path.is_absolute():
                resolved_path = (self._base_path / resolved_path).resolve()
            return resolved_path
        except Exception as e:
            raise AssetResolutionError(f"Failed to resolve local file asset '{asset_ref.path}': {e}") from e

    def resolve_url(self, asset_ref: URLAssetReference) -> str:
        """Resolves a URL asset reference.

        For URLs, resolution primarily means returning the validated URL string.
        Future enhancements might include fetching the asset or validating URL accessibility.

        Args:
            asset_ref: The URLAssetReference object.

        Returns:
            The URL string.

        Raises:
            AssetResolutionError: If the URL is invalid (though Pydantic's HttpUrl handles most of this).
        """
        if not isinstance(asset_ref, URLAssetReference):
            raise TypeError("Expected URLAssetReference type.")

        try:
            # HttpUrl from Pydantic handles validation during model creation.
            return str(asset_ref.url)
        except Exception as e:
            raise AssetResolutionError(f"Failed to resolve URL asset '{asset_ref.url}': {e}") from e

    def resolve(self, asset_ref: AssetReference) -> Union[Path, str]:
        """Resolves a generic asset reference based on its type.

        Args:
            asset_ref: An AssetReference object (LocalFileAssetReference or URLAssetReference).

        Returns:
            The resolved asset, either a Path object for local files or a string for URLs.

        Raises:
            TypeError: If the asset_ref is not a recognized AssetReference type.
            AssetResolutionError: If there's an issue resolving the specific asset type.
        """
        if isinstance(asset_ref, LocalFileAssetReference):
            return self.resolve_local_file(asset_ref)
        elif isinstance(asset_ref, URLAssetReference):
            return self.resolve_url(asset_ref)
        else:
            raise TypeError(f"Unsupported asset reference type: {type(asset_ref)}")


# Example usage (for internal testing/understanding, not for production runtime here)
if __name__ == "__main__":
    import os
    # Create dummy files for testing local file resolution
    current_dir = Path(__file__).parent
    test_assets_dir = current_dir / "_test_assets"
    test_assets_dir.mkdir(exist_ok=True)
    dummy_file_path = test_assets_dir / "dummy_model.obj"
    dummy_file_path.write_text("This is a dummy model file.")

    resolver = AssetResolver(base_path=current_dir)

    print("\n--- Testing Local File Resolution ---")
    local_ref_abs = LocalFileAssetReference(path=str(dummy_file_path.resolve()))
    resolved_abs_path = resolver.resolve(local_ref_abs)
    print(f"Resolved absolute local file: {resolved_abs_path}")
    assert resolved_abs_path == dummy_file_path.resolve()

    local_ref_rel = LocalFileAssetReference(path=str(dummy_file_path.relative_to(current_dir)))
    resolved_rel_path = resolver.resolve(local_ref_rel)
    print(f"Resolved relative local file: {resolved_rel_path}")
    assert resolved_rel_path == dummy_file_path.resolve()

    # Test a non-existent local file (FilePath validates existence if specified, but Pydantic's default is less strict on FilePath for just string parsing)
    # The resolver's `resolve_local_file` will return the path, but `exists()` would fail if called afterwards.
    non_existent_file = test_assets_dir / "non_existent.txt"
    local_ref_non_exist = LocalFileAssetReference(path=str(non_existent_file))
    resolved_non_exist_path = resolver.resolve(local_ref_non_exist)
    print(f"Resolved non-existent local file path: {resolved_non_exist_path} (exists: {resolved_non_exist_path.exists()})")
    assert not resolved_non_exist_path.exists()

    print("\n--- Testing URL Resolution ---")
    url_ref = URLAssetReference(url="https://example.com/models/car.glb")
    resolved_url = resolver.resolve(url_ref)
    print(f"Resolved URL: {resolved_url}")
    assert resolved_url == "https://example.com/models/car.glb"

    print("\n--- Testing Error Handling ---")
    try:
        invalid_ref_type = "just_a_string" # Not an AssetReference instance
        resolver.resolve(invalid_ref_type) # type: ignore
    except TypeError as e:
        print(f"Caught expected error for invalid type: {e}")

    try:
        # Attempt to create an invalid URLAssetReference directly (Pydantic will catch this)
        URLAssetReference(url="not a valid url")
    except Exception as e:
        print(f"Caught expected error for invalid URL during creation: {e}")

    # Clean up dummy files
    if dummy_file_path.exists():
        dummy_file_path.unlink()
    if test_assets_dir.exists():
        test_assets_dir.rmdir()
    print("\nCleanup complete.")

