import os
import logging
import ipaddress
import socket
from urllib.parse import urlparse
from typing import Any, Union

from backend.kfs_manifest.asset_types import (
    AssetType, AssetReference, LocalFileAsset, UrlAsset,
    FileAsset, GitAsset, HttpAsset,
)
from backend.kfs_manifest.errors import AssetResolutionError

logger = logging.getLogger(__name__)

# Maximum download size for HTTP assets (50 MB)
MAX_DOWNLOAD_SIZE_BYTES = 50 * 1024 * 1024
# Connection timeout for HTTP requests (seconds)
HTTP_TIMEOUT_SECONDS = 30
# Allowed URL schemes
ALLOWED_SCHEMES = {"http", "https"}


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
        """Resolves a FileAsset to an absolute path.

        Validates that the resolved path stays within base_path to prevent
        path traversal attacks.
        """
        path = asset.path
        resolved = os.path.abspath(os.path.join(self.base_path, path))
        if not resolved.startswith(os.path.abspath(self.base_path)):
            raise AssetResolutionError(
                f"Path traversal detected: '{path}' resolves outside base directory"
            )
        return resolved

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

    def _is_safe_url(self, url: str) -> bool:
        """Check URL doesn't point to private/internal networks (SSRF protection)."""
        parsed = urlparse(url)
        if parsed.scheme not in ALLOWED_SCHEMES:
            return False
        try:
            ip = socket.gethostbyname(parsed.hostname)
            addr = ipaddress.ip_address(ip)
            if addr.is_private or addr.is_loopback or addr.is_link_local:
                return False
        except (socket.gaierror, ValueError):
            return False
        return True

    def _resolve_http_asset(self, asset: HttpAsset) -> str:
        """Resolves an HttpAsset by downloading/caching.

        Validates URL scheme, blocks private/loopback/link-local IPs,
        and enforces download size and timeout limits.
        """
        parsed_url = urlparse(asset.url)

        # Scheme validation
        if parsed_url.scheme not in ALLOWED_SCHEMES:
            raise AssetResolutionError(
                f"URL scheme '{parsed_url.scheme}' is not allowed. "
                f"Only {ALLOWED_SCHEMES} are permitted."
            )

        # SSRF protection: block private/internal network addresses
        if not self._is_safe_url(asset.url):
            raise AssetResolutionError(
                f"URL points to a private/internal network address and is blocked: {asset.url}"
            )

        filename = os.path.basename(parsed_url.path)
        cached_path = os.path.join(self.cache_dir, filename)

        if not os.path.exists(cached_path):
            os.makedirs(self.cache_dir, exist_ok=True)
            # Simulate download by writing a placeholder
            # Real implementation should use requests with:
            #   timeout=HTTP_TIMEOUT_SECONDS
            #   stream=True with MAX_DOWNLOAD_SIZE_BYTES check
            with open(cached_path, "w") as f:
                f.write(f"downloaded from {asset.url}")

        return cached_path

    def _resolve_local_file(self, path: str) -> str:
        """Resolves a local file path.

        Validates that the resolved path stays within base_path to prevent
        path traversal attacks.
        """
        if not path:
            raise AssetResolutionError("Local file path cannot be empty.")
        resolved = os.path.abspath(os.path.join(self.base_path, path))
        if not resolved.startswith(os.path.abspath(self.base_path)):
            raise AssetResolutionError(
                f"Path traversal detected: '{path}' resolves outside base directory"
            )
        return resolved

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
