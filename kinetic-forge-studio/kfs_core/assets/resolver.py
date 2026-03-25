from pathlib import Path
from typing import List, Optional, Type

from kfs_core.assets.handlers import AssetHandler, FileAssetHandler, HttpAssetHandler
from kfs_core.assets.exceptions import AssetResolutionError, UnsupportedSchemeError

class AssetResolver:
    """
    A unified interface for resolving external asset references (URIs) to local file paths.
    It delegates resolution to registered AssetHandler instances based on the URI scheme.
    """
    def __init__(self, handlers: Optional[List[AssetHandler]] = None, default_cache_dir: Optional[Path] = None):
        self._handlers: List[AssetHandler] = []
        self.default_cache_dir = default_cache_dir

        if handlers is None:
            # Register default handlers if none are provided
            self.register_handler(FileAssetHandler())
            self.register_handler(HttpAssetHandler())
        else:
            for handler in handlers:
                self.register_handler(handler)

    def register_handler(self, handler: AssetHandler):
        """
        Registers an asset handler with the resolver.
        Handlers are checked in the order they are registered.
        Args:
            handler (AssetHandler): An instance of an AssetHandler.
        """
        if not isinstance(handler, AssetHandler):
            raise TypeError("Handler must be an instance of AssetHandler.")
        self._handlers.append(handler)

    def unregister_handler(self, handler_type: Type[AssetHandler]) -> bool:
        """
        Unregisters all instances of a specific AssetHandler type.
        Args:
            handler_type (Type[AssetHandler]): The class type of the handler to unregister.
        Returns:
            bool: True if any handlers were unregistered, False otherwise.
        """
        initial_count = len(self._handlers)
        self._handlers = [h for h in self._handlers if not isinstance(h, handler_type)]
        return len(self._handlers) < initial_count

    def resolve(self, uri: str, cache_dir: Optional[Path] = None) -> Path:
        """
        Resolves an asset URI to a local file path.
        Args:
            uri (str): The asset URI (e.g., "file:///path/to/model.obj", "http://example.com/texture.png").
            cache_dir (Optional[Path]): Override the default cache directory for this resolution.
                                        Only applicable to handlers that use caching (e.g., HTTP).
        Returns:
            Path: The local file path of the resolved asset.
        Raises:
            UnsupportedSchemeError: If no registered handler can process the URI's scheme.
            AssetResolutionError: If any other error occurs during asset resolution by a handler.
        """
        for handler in self._handlers:
            if handler.can_handle(uri):
                try:
                    # Pass the cache_dir preference to the handler
                    resolved_path = handler.resolve(uri, cache_dir=cache_dir or self.default_cache_dir)
                    if not resolved_path.exists():
                         raise AssetResolutionError(f"Handler {type(handler).__name__} resolved path '{resolved_path}' for URI '{uri}' but it does not exist.")
                    return resolved_path
                except AssetResolutionError:
                    # Re-raise specific AssetResolutionErrors from handlers
                    raise
                except Exception as e:
                    # Wrap other unexpected exceptions from handlers
                    raise AssetResolutionError(
                        f"An unexpected error occurred while resolving asset '{uri}' with handler {type(handler).__name__}: {e}"
                    ) from e
        raise UnsupportedSchemeError(f"No asset handler registered for URI scheme in: {uri}")
