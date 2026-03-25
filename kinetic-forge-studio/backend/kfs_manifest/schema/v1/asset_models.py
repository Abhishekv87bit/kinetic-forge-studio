from pydantic import BaseModel, Field, HttpUrl, FilePath


class AssetIdentifier(BaseModel):
    """A unique identifier for an asset within the KFS Manifest system."""
    id: str = Field(..., description="The unique string identifier for the asset.")


class LocalFilePath(BaseModel):
    """Represents a path to a local file asset."""
    path: FilePath = Field(..., description="The absolute or relative path to the local file.")


class RemoteHttpUrl(BaseModel):
    """Represents a URL to a remote asset accessible via HTTP."""
    url: HttpUrl = Field(..., description="The URL to the remote asset.")


class GenericAssetRef(BaseModel):
    """A generic reference to an asset, which can be a local file, a remote URL, or an internal identifier."""
    # Using a union type to allow different forms of asset references
    # The order matters for validation (most specific first usually)
    asset: LocalFilePath | RemoteHttpUrl | AssetIdentifier = Field(
        ..., description="Reference to an asset, can be a local file, remote URL, or an internal ID."
    )


