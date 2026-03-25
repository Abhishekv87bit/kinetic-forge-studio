from pydantic import BaseModel, Field, FilePath

class AssetPath(BaseModel):
    """
    Represents a file path for an asset within the KFS manifest system.
    This can be an absolute or relative path to an asset file.
    """
    path: FilePath = Field(
        ...,
        description="The path to the asset file. Can be absolute or relative."
    )

class AssetId(BaseModel):
    """
    Represents a unique identifier for an asset within the KFS manifest system.
    This could be a UUID, a custom ID string, or any other unique string.
    """
    id: str = Field(
        ...,
        description="A unique string identifier for the asset. E.g., a UUID or a custom ID.",
        min_length=1
    )
