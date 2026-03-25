from typing import List, Optional
from pydantic import BaseModel, Field

from backend.kfs_manifest.schema.v1.asset_models import Asset
from backend.kfs_manifest.schema.v1.geometry_models import Geometry
from backend.kfs_manifest.schema.v1.motion_models import Motion


class KineticForgeSchema(BaseModel):
    """Root Pydantic model for the .kfs.yaml manifest file.

    This model combines asset, geometry, and motion definitions to provide a single
    source of truth for reproducible kinetic system builds.
    """
    kfs_version: str = Field(..., description="Version of the KineticForgeSchema.")
    
    assets: Optional[List[Asset]] = Field(
        default_factory=list,
        description="List of asset definitions included in the manifest."
    )
    geometries: Optional[List[Geometry]] = Field(
        default_factory=list,
        description="List of geometry definitions included in the manifest."
    )
    motions: Optional[List[Motion]] = Field(
        default_factory=list,
        description="List of motion definitions included in the manifest."
    )

