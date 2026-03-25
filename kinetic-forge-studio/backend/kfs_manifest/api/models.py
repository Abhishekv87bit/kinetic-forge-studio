from pydantic import BaseModel
from typing import List, Optional, Union

from ...schema.v1.kinetic_forge_schema import KineticForgeSchema


class HealthCheckResponse(BaseModel):
    """Response model for the API health check."""
    status: str
    message: Optional[str] = None


class ManifestParseRequest(BaseModel):
    """Request model for parsing a KFS manifest."""
    manifest_content: str


class ManifestParseResponse(BaseModel):
    """Response model for the KFS manifest parsing and validation endpoint."""
    status: str  # "success" or "failed"
    parsed_manifest: Optional[KineticForgeSchema] = None
    errors: Optional[List[str]] = None
