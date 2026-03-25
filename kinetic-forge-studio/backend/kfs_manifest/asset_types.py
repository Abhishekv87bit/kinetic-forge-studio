from enum import Enum
from typing import Union

class AssetType(str, Enum):
    LOCAL_FILE = "local_file"
    URL = "url"
    # Add other asset types as needed, e.g., cloud storage, package reference

class AssetReference:
    """Base class for all asset references."""
    def __init__(self, ref: str):
        self.ref = ref

    def __str__(self):
        return self.ref

    def __repr__(self):
        return f"{self.__class__.__name__}(ref='{self.ref}')"

class LocalFileAsset(AssetReference):
    """Represents a local file path asset."""
    pass

class UrlAsset(AssetReference):
    """Represents a URL asset."""
    pass

# A union type for common asset references
CommonAssetRef = Union[LocalFileAsset, UrlAsset]
