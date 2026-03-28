from pydantic import BaseModel
from typing import List, Optional, Dict, Any


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
    parsed_manifest: Optional[Dict[str, Any]] = None
    errors: Optional[List[str]] = None


class ManifestValidateRequest(BaseModel):
    """Request model for validating a KFS manifest."""
    manifest_content: str


class ManifestValidateResponse(BaseModel):
    """Response model for the KFS manifest validation endpoint."""
    status: str  # "success" or "error"
    message: str
    errors: Optional[List[Dict[str, Any]]] = None
