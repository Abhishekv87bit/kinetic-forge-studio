import os
import logging
from urllib.parse import urlparse
from typing import Any, Union

from backend.kfs_manifest.asset_types import (
    AssetType, AssetReference, LocalFileAsset, UrlAsset,
    FileAsset, GitAsset, HttpAsset,
)

logger = logging.getLogger(__name__)


class AssetResolutionError(Exception):
    """Custom exception for asset resolution errors."""
    pass


class AssetResolver:
    """Handles resolving various types of asset references.

    This resolver can be extended to support different asset types
    (e.g., local files, URLs, cloud storage, git repos).
    """

    def __init__(self, base_path: str = ".", cache_dir: str = None):
        """Initializes the AssetResolver.

        Args:
            base_path: The base path for resolving local files.
            cache_dir: Optional directory for caching resolved assets.
        """
        self.base_path = os.path.abspath(base_path)
        self.cache_dir = os.path.abspath(cache_dir) if cache_dir else None
        logger.info(f"AssetResolver initialized with base_path: {self.base_path}")

    def resolve(self, asset_ref) -> str:
        """Resolves an asset reference to an absolute path or URL.

        Args:
            asset_ref: A FileAsset, GitAsset, HttpAsset, or AssetReference.

        Returns:
            The resolved absolute path or URL as a string.

        Raises:
            AssetResolutionError: If resolution fails.
            TypeError: If the asset type is not supported.
        """
        if isinstance(asset_ref, FileAsset):
            return self._resolve_file_asset(asset_ref)
        elif isinstance(asset_ref, GitAsset):
            return self._resolve_git_asset(asset_ref)
        elif isinstance(asset_ref, HttpAsset):
            return self._resolve_http_asset(asset_ref)
        elif isinstance(asset_ref, AssetReference):
            ref_str = str(asset_ref)
            asset_type = self.get_asset_type_from_ref(ref_str)
            if asset_type == AssetType.LOCAL_FILE:
                return self._resolve_local_file(ref_str)
            elif asset_type == AssetType.URL:
                return self._resolve_url(ref_str)
        raise TypeError(f"Unsupported asset type: {type(asset_ref).__name__}")

    def _resolve_file_asset(self, asset: FileAsset) -> str:
        """Resolves a FileAsset to an absolute path."""
        path = asset.path
        if os.path.isabs(path):
            return os.path.abspath(path)
        return os.path.abspath(os.path.join(self.base_path, path))

    def _resolve_git_asset(self, asset: GitAsset) -> str:
        """Resolves a GitAsset by cloning/caching the repo."""
        repo_name = os.path.basename(asset.url).replace(".git", "")
        ref_safe = asset.reference.replace("/", "_")
        cached_path = os.path.join(self.cache_dir, f"{repo_name}-{ref_safe}")

        if not os.path.exists(cached_path):
            os.makedirs(cached_path, exist_ok=True)
            # Simulate cloning by writing a placeholder
            with open(os.path.join(cached_path, ".git_ref"), "w") as f:
                f.write(f"{asset.url}@{asset.reference}")

        return cached_path

    def _resolve_http_asset(self, asset: HttpAsset) -> str:
        """Resolves an HttpAsset by downloading/caching."""
        parsed_url = urlparse(asset.url)
        filename = os.path.basename(parsed_url.path)
        cached_path = os.path.join(self.cache_dir, filename)

        if not os.path.exists(cached_path):
            os.makedirs(self.cache_dir, exist_ok=True)
            # Simulate download by writing a placeholder
            with open(cached_path, "w") as f:
                f.write(f"downloaded from {asset.url}")

        return cached_path

    def _resolve_local_file(self, path: str) -> str:
        """Resolves a local file path."""
        if not path:
            raise AssetResolutionError("Local file path cannot be empty.")
        absolute_path = os.path.join(self.base_path, path)
        return os.path.abspath(absolute_path)

    def _resolve_url(self, url: str) -> str:
        """Resolves a URL asset (primarily validates it's a URL)."""
        if not url:
            raise AssetResolutionError("URL cannot be empty.")
        parsed_url = urlparse(url)
        if not all([parsed_url.scheme, parsed_url.netloc]):
            raise AssetResolutionError(f"Invalid URL format: {url}")
        return url

    @staticmethod
    def get_asset_type_from_ref(ref: str) -> AssetType:
        """Infers the asset type from a string reference."""
        if ref.startswith("http://") or ref.startswith("https://") or ref.startswith("ftp://"):
            return AssetType.URL
        return AssetType.LOCAL_FILE
