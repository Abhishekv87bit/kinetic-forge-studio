from enum import Enum
from typing import Union, Optional

from pydantic import BaseModel, Field


class AssetType(str, Enum):
    LOCAL_FILE = "local_file"
    URL = "url"
    ARBITRARY_DATA = "arbitrary_data"
    MESH = "mesh"


class GeometryType(str, Enum):
    MESH = "mesh"
    PRIMITIVE = "primitive"


class Units(str, Enum):
    MM = "mm"
    CM = "cm"
    M = "m"
    IN = "in"


class MotionProfile(str, Enum):
    LINEAR = "linear"
    SINE = "sine"
    EASE_IN_OUT = "ease_in_out"


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


class FileAsset:
    """Represents a file asset with a path."""
    def __init__(self, path: str):
        self.path = path

    def __str__(self):
        return self.path


class GitAsset:
    """Represents a git repository asset."""
    def __init__(self, url: str, reference: str = "main"):
        self.url = url
        self.reference = reference

    def __str__(self):
        return f"{self.url}@{self.reference}"


class HttpAsset:
    """Represents an HTTP URL asset."""
    def __init__(self, url: str):
        self.url = url

    def __str__(self):
        return self.url


# A union type for common asset references
CommonAssetRef = Union[LocalFileAsset, UrlAsset]
