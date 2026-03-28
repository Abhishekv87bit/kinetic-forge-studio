import abc
import hashlib
import ipaddress
import requests
import socket
import tempfile
from pathlib import Path
from urllib.parse import urlparse, unquote
from typing import Optional

from kfs_core.assets.exceptions import (
    AssetHandlerError,
    LocalAssetNotFoundError,
    RemoteAssetDownloadError,
    UnsupportedSchemeError
)

class AssetHandler(abc.ABC):
    """Abstract base class for all asset handlers."""

    @abc.abstractmethod
    def can_handle(self, uri: str) -> bool:
        """
        Determines if this handler can process the given URI.
        Args:
            uri (str): The asset URI.
        Returns:
            bool: True if this handler can process the URI, False otherwise.
        """
        pass

    @abc.abstractmethod
    def resolve(self, uri: str, cache_dir: Optional[Path] = None) -> Path:
        """
        Resolves the asset URI to a local file path.
        For remote assets, this might involve downloading to a cache_dir.
        Args:
            uri (str): The asset URI.
            cache_dir (Optional[Path]): Directory for caching downloaded assets.
                                        If None, a temporary directory might be used.
        Returns:
            Path: The local path to the resolved asset.
        Raises:
            AssetHandlerError: If an error occurs during resolution.
        """
        pass

class FileAssetHandler(AssetHandler):
    """
    Handles local file paths and 'file://' URIs.
    """
    def can_handle(self, uri: str) -> bool:
        parsed_uri = urlparse(uri)
        # Handle 'file://' scheme or treat as local path if no scheme
        # The actual existence check is done in resolve().
        return parsed_uri.scheme == "file" or not parsed_uri.scheme

    def resolve(self, uri: str, cache_dir: Optional[Path] = None) -> Path:
        parsed_uri = urlparse(uri)
        
        if parsed_uri.scheme == "file":
            # Path from file:// URI might start with / on Windows for C:/ drive, e.g., file:///C:/path
            path_str = unquote(parsed_uri.path)
            if path_str.startswith('/') and len(path_str) > 2 and path_str[2] == ':' and path_str[1].isalpha():
                # Heuristic for Windows paths like /C:/path/to/file
                local_path = Path(path_str[1:])
            else:
                local_path = Path(path_str)
        elif not parsed_uri.scheme:
            # Assume it's a direct local path (relative or absolute)
            local_path = Path(uri)
        else:
            # Should not happen if can_handle is correct, but as a safeguard
            raise UnsupportedSchemeError(f"FileAssetHandler cannot handle scheme: {parsed_uri.scheme}")

        if not local_path.exists():
            raise LocalAssetNotFoundError(f"Local file asset not found: {local_path} (from URI: {uri})")
        
        return local_path

class HttpAssetHandler(AssetHandler):
    """
    Handles 'http://' and 'https://' URIs, downloading assets to a cache directory.
    """

    DEFAULT_TIMEOUT = 30  # seconds
    MAX_DOWNLOAD_SIZE = 100 * 1024 * 1024  # 100 MB

    def __init__(self, timeout: int = DEFAULT_TIMEOUT, max_download_size: int = MAX_DOWNLOAD_SIZE):
        self.timeout = timeout
        self.max_download_size = max_download_size

    def can_handle(self, uri: str) -> bool:
        parsed_uri = urlparse(uri)
        return parsed_uri.scheme in ["http", "https"]

    def _is_safe_url(self, uri: str) -> bool:
        """Check URL doesn't point to private/internal networks."""
        parsed = urlparse(uri)
        try:
            ip = socket.gethostbyname(parsed.hostname)
            addr = ipaddress.ip_address(ip)
            if addr.is_private or addr.is_loopback or addr.is_link_local:
                return False
        except (socket.gaierror, ValueError):
            return False
        return True

    def _make_cache_filename(self, uri: str) -> str:
        """Generate a cache-safe filename using a hash of the full URI."""
        parsed_uri = urlparse(uri)
        filename_from_path = Path(parsed_uri.path).name
        uri_hash = hashlib.sha256(uri.encode()).hexdigest()[:16]

        if filename_from_path and filename_from_path != '.' and filename_from_path != '..':
            filename = f"{uri_hash}_{filename_from_path}"
        else:
            filename = f"{uri_hash}_asset.bin"

        # Ensure filename is safe for file systems
        if len(filename) > 200:
            filename = f"{uri_hash}_{filename_from_path[:150]}" if filename_from_path else f"{uri_hash}_asset.bin"

        return filename

    def resolve(self, uri: str, cache_dir: Optional[Path] = None) -> Path:
        if not self._is_safe_url(uri):
            raise RemoteAssetDownloadError(
                f"URL points to a private/internal network address and is blocked: {uri}"
            )

        target_dir = cache_dir if cache_dir else Path(tempfile.gettempdir()) / "kfs_asset_cache"
        target_dir.mkdir(parents=True, exist_ok=True)

        filename = self._make_cache_filename(uri)
        local_path = target_dir / filename

        if local_path.exists():
            return local_path

        try:
            response = requests.get(uri, stream=True, timeout=self.timeout)
            response.raise_for_status()

            content_length = response.headers.get("Content-Length")
            if content_length and int(content_length) > self.max_download_size:
                raise RemoteAssetDownloadError(
                    f"Asset at {uri} exceeds maximum download size "
                    f"({int(content_length)} > {self.max_download_size} bytes)"
                )

            downloaded = 0
            with open(local_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    downloaded += len(chunk)
                    if downloaded > self.max_download_size:
                        f.close()
                        local_path.unlink(missing_ok=True)
                        raise RemoteAssetDownloadError(
                            f"Asset at {uri} exceeds maximum download size "
                            f"({self.max_download_size} bytes) during download"
                        )
                    f.write(chunk)

            return local_path
        except RemoteAssetDownloadError:
            raise
        except requests.exceptions.HTTPError as e:
            raise RemoteAssetDownloadError(
                f"HTTP error {e.response.status_code} while downloading {uri}",
                status_code=e.response.status_code,
                original_exception=e
            ) from e
        except requests.exceptions.ConnectionError as e:
            raise RemoteAssetDownloadError(
                f"Connection error while downloading {uri}: {e}",
                original_exception=e
            ) from e
        except requests.exceptions.Timeout as e:
            raise RemoteAssetDownloadError(
                f"Timeout while downloading {uri}: {e}",
                original_exception=e
            ) from e
        except requests.exceptions.RequestException as e:
            raise RemoteAssetDownloadError(
                f"An unexpected request error occurred while downloading {uri}: {e}",
                original_exception=e
            ) from e
        except IOError as e:
            raise AssetHandlerError(f"Failed to write downloaded asset to {local_path}: {e}") from e
