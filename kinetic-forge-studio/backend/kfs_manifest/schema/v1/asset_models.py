from typing import Optional, Dict, Any, Literal
from pydantic import BaseModel, Field


class AssetPath(BaseModel):
    """Represents a file path for an asset within the KFS manifest system."""
    path: str = Field(
        ...,
        description="The path to the asset file. Can be absolute or relative."
    )


class AssetId(BaseModel):
    """Represents a unique identifier for an asset."""
    id: str = Field(
        ...,
        description="A unique string identifier for the asset.",
        min_length=1
    )


class MeshAsset(BaseModel):
    """Represents a mesh asset reference."""
    path: str = Field(..., description="Path or URI to the mesh file.")
    format: Optional[str] = Field(None, description="File format (e.g., 'gltf', 'obj', 'fbx').")


class StaticAsset(BaseModel):
    """Represents a static (non-moving) asset in the KFS system."""
    name: str = Field(..., description="Unique name for the asset.")
    type: Literal["static"] = Field("static", description="Asset type, must be 'static'.")
    geometry_path: str = Field(..., description="Path to the geometry file.")
    description: Optional[str] = Field(None, description="Human-readable description.")


class KineticAsset(BaseModel):
    """Represents a kinetic (moving) asset in the KFS system."""
    name: str = Field(..., description="Unique name for the asset.")
    type: Literal["kinetic"] = Field("kinetic", description="Asset type, must be 'kinetic'.")
    geometry_path: str = Field(..., description="Path to the geometry file.")
    motion_profile: str = Field(..., description="Path to the motion profile definition.")
    initial_state: Optional[Dict[str, Any]] = Field(None, description="Initial state of the asset.")
    description: Optional[str] = Field(None, description="Human-readable description.")
