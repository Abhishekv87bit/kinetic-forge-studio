from enum import Enum
from typing import Union

from pydantic import BaseModel, Field, HttpUrl, FilePath


class AssetType(str, Enum):
    """Enum for different types of asset references."""
    LOCAL_FILE = "local_file"
    URL = "url"


class LocalFileAssetReference(BaseModel):
    """Represents a reference to a local file asset."""
    type: AssetType = Field(AssetType.LOCAL_FILE, frozen=True)
    path: FilePath = Field(..., description="The local file path.")


class URLAssetReference(BaseModel):
    """Represents a reference to a URL-based asset."""
    type: AssetType = Field(AssetType.URL, frozen=True)
    url: HttpUrl = Field(..., description="The URL to the asset.")


AssetReference = Union[LocalFileAssetReference, URLAssetReference]


# Example usage (for internal testing/understanding, not for production runtime here)
if __name__ == "__main__":
    local_ref = LocalFileAssetReference(path="/path/to/my/model.gltf")
    print(f"Local File Ref: {local_ref.model_dump_json(indent=2)}")

    url_ref = URLAssetReference(url="http://example.com/assets/texture.png")
    print(f"URL Ref: {url_ref.model_dump_json(indent=2)}")

    # Demonstrate validation
    try:
        invalid_local_ref = LocalFileAssetReference(path="not_a_valid_path") # Pydantic path validation might allow this if it's just a string, but FilePath would check existence or relative path logic
        print(f"Invalid Local File Ref: {invalid_local_ref}")
    except Exception as e:
        print(f"Error creating invalid local ref: {e}")

    try:
        invalid_url_ref = URLAssetReference(url="not_a_url")
    except Exception as e:
        print(f"Error creating invalid URL ref: {e}")


