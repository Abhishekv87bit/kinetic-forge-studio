from kfs_core.exceptions import AssetResolutionError

class UnsupportedSchemeError(AssetResolutionError):
    """Raised when an asset URI uses a scheme that no registered handler can process."""
    pass

class AssetHandlerError(AssetResolutionError):
    """Base exception for errors originating from an asset handler."""
    pass

class LocalAssetNotFoundError(AssetHandlerError):
    """Raised when a local file asset is not found."""
    pass

class RemoteAssetDownloadError(AssetHandlerError):
    """Raised when there's an error downloading a remote asset."""
    def __init__(self, message: str, status_code: int = None, original_exception: Exception = None):
        super().__init__(message)
        self.status_code = status_code
        self.original_exception = original_exception
