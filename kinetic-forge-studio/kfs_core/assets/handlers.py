import abc
import requests
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
    def can_handle(self, uri: str) -> bool:
        parsed_uri = urlparse(uri)
        return parsed_uri.scheme in ["http", "https"]

    def resolve(self, uri: str, cache_dir: Optional[Path] = None) -> Path:
        target_dir = cache_dir if cache_dir else Path(tempfile.gettempdir()) / "kfs_asset_cache"
        target_dir.mkdir(parents=True, exist_ok=True)

        parsed_uri = urlparse(uri)
        # Use filename from URL if available, otherwise hash the URL
        filename_from_path = Path(parsed_uri.path).name
        if filename_from_path and filename_from_path != '.' and filename_from_path != '..': # Ensure not just a directory or empty
            filename = filename_from_path
        else:
            # Fallback for URLs without a clear filename or with just a directory path
            # Using a hash of the full URI and a generic extension
            filename = f"asset_{hash(uri) % (10**10)}.bin" # Use .bin as generic fallback
        
        # Ensure filename is safe for file systems, maybe limit length
        if len(filename) > 200: # Arbitrary limit, truncate and add a shorter hash
            filename = f"{filename[:150]}_{hash(uri) % (10**5)}"

        local_path = target_dir / filename

        if local_path.exists():
            # Basic caching: if file exists, assume it's valid.
            # More advanced caching would involve ETag, Last-Modified, etc.
            return local_path

        try:
            response = requests.get(uri, stream=True)
            response.raise_for_status() # Raise an HTTPError for bad responses (4xx or 5xx)

            with open(local_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return local_path
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
