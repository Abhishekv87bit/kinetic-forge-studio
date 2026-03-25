import os
import logging
from urllib.parse import urlparse
from typing import Any, Union

from backend.kfs_manifest.asset_types import AssetType, AssetReference, LocalFileAsset, UrlAsset

logger = logging.getLogger(__name__)

class AssetResolverError(Exception):
    """Custom exception for asset resolution errors."""
    pass

class AssetResolver:
    """Handles resolving various types of asset references.

    This resolver can be extended to support different asset types
    (e.g., local files, URLs, cloud storage, package references).
    """

    def __init__(self, base_path: str = "."):
        """Initializes the AssetResolver.

        Args:
            base_path: The base path for resolving local files.
                       Defaults to the current directory.
        """
        self.base_path = os.path.abspath(base_path)
        logger.info(f"AssetResolver initialized with base_path: {self.base_path}")

    def resolve(self, asset_ref: Union[str, AssetReference], asset_type: AssetType) -> str:
        """Resolves an asset reference to an absolute path or URL.

        Args:
            asset_ref: The string reference or an AssetReference object.
            asset_type: The type of asset to resolve.

        Returns:
            The resolved absolute path or URL as a string.

        Raises:
            AssetResolverError: If the asset type is not supported or resolution fails.
        """
        ref_str = str(asset_ref) # Ensure we work with a string representation

        if asset_type == AssetType.LOCAL_FILE:
            return self._resolve_local_file(ref_str)
        elif asset_type == AssetType.URL:
            return self._resolve_url(ref_str)
        else:
            raise AssetResolverError(f"Unsupported asset type: {asset_type.value}")

    def _resolve_local_file(self, path: str) -> str:
        """Resolves a local file path."""
        if not path:
            raise AssetResolverError("Local file path cannot be empty.")

        absolute_path = os.path.join(self.base_path, path)
        absolute_path = os.path.abspath(absolute_path) # Normalize path

        if not os.path.exists(absolute_path):
            logger.warning(f"Local file not found: {absolute_path}")
            # Depending on requirements, could raise an error here or return as-is
            # For now, we'll return the absolute path even if it doesn't exist yet.
            # Validation of existence might be better handled during a 'load' phase.
        else:
            logger.debug(f"Resolved local file: {path} -> {absolute_path}")

        return absolute_path

    def _resolve_url(self, url: str) -> str:
        """Resolves a URL asset (primarily validates it's a URL)."""
        if not url:
            raise AssetResolverError("URL cannot be empty.")

        parsed_url = urlparse(url)
        if not all([parsed_url.scheme, parsed_url.netloc]):
            raise AssetResolverError(f"Invalid URL format: {url}")

        logger.debug(f"Resolved URL: {url}")
        return url

    @staticmethod
    def get_asset_type_from_ref(ref: str) -> AssetType:
        """Infers the asset type from a string reference.

        This is a heuristic and might not always be accurate for all cases.
        """
        if ref.startswith("http://") or ref.startswith("https://") or ref.startswith("ftp://"):
            return AssetType.URL
        # Assume local file if it's not a URL
        return AssetType.LOCAL_FILE

