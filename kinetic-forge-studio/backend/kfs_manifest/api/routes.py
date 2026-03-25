from fastapi import APIRouter, HTTPException, status
from typing import List, Optional, Union, Literal
from enum import Enum

import yaml
from pydantic import BaseModel, Field, ValidationError as PydanticValidationError

from backend.kfs_manifest.parser import parse_manifest
from backend.kfs_manifest.validator import validate_manifest
from backend.kfs_manifest.errors import KFSManifestError, KFSManifestValidationError
from backend.kfs_manifest.schema.v1.kinetic_forge_schema import KineticForgeSchema
from .models import (
    HealthCheckResponse,
    ManifestParseRequest,
    ManifestParseResponse,
    ManifestValidateRequest,
    ManifestValidateResponse,
)

router = APIRouter()


# --- Manifest validation schema (API-specific format) ---

class ManifestVersion(str, Enum):
    V1_0 = "1.0"


class SystemComponent(BaseModel):
    name: str = Field(..., description="Component name.")
    type: str = Field(..., description="Component type.")
    description: Optional[str] = Field(None, description="Component description.")


class SystemDefinition(BaseModel):
    name: str = Field(..., description="System name.")
    description: Optional[str] = Field(None, description="System description.")
    components: List[SystemComponent] = Field(default_factory=list, description="System components.")


class KFSManifestEnvelope(BaseModel):
    version: ManifestVersion = Field(..., description="Manifest version.")
    system: SystemDefinition = Field(..., description="System definition.")


class KFSManifestWrapper(BaseModel):
    kfs_manifest: KFSManifestEnvelope = Field(..., description="KFS manifest envelope.")


@router.get("/health", response_model=HealthCheckResponse, summary="Health Check")
async def health_check():
    """Performs a health check on the API service."""
    return HealthCheckResponse(status="ok", message="KFS Manifest API is running.")


@router.post(
    "/parse_manifest",
    response_model=ManifestParseResponse,
    summary="Parse and Validate KFS Manifest",
)
async def parse_and_validate_manifest(request: ManifestParseRequest):
    """Receives a KFS manifest content (YAML string), parses and validates it."""
    try:
        parsed_data = parse_manifest(request.manifest_content)
        validate_manifest(parsed_data)
        return ManifestParseResponse(status="success", parsed_manifest=parsed_data)
    except KFSManifestValidationError as e:
        error_messages = [f"{err['loc']}: {err['msg']}" for err in e.errors]
        return ManifestParseResponse(status="failed", errors=error_messages)
    except KFSManifestError as e:
        return ManifestParseResponse(status="failed", errors=[str(e)])
    except Exception as e:
        return ManifestParseResponse(status="failed", errors=[f"An unexpected error occurred: {str(e)}"])


def _normalize_error_msg(msg: str, error_type: str) -> str:
    """Normalize Pydantic v2 error messages to v1-compatible format."""
    if error_type == "missing":
        return "field required"
    if error_type == "string_type":
        return "string type expected"
    if error_type == "enum":
        return "value is not a valid enumeration member"
    if error_type == "int_type":
        return "value is not a valid integer"
    if error_type == "float_type":
        return "value is not a valid float"
    if error_type == "json_invalid":
        return "JSON decode error"
    return msg.lower() if msg else msg


@router.post(
    "/manifest/validate",
    response_model=ManifestValidateResponse,
    summary="Validate KFS Manifest",
)
async def validate_kfs_manifest(request: ManifestValidateRequest):
    """Validates a KFS manifest YAML string against the schema."""
    try:
        data = yaml.safe_load(request.manifest_content)
    except yaml.YAMLError as e:
        return ManifestValidateResponse(
            status="error",
            message="Manifest validation failed.",
            errors=[{"loc": "manifest_content", "msg": f"YAML parsing error: {e}"}],
        )

    if not isinstance(data, dict):
        return ManifestValidateResponse(
            status="error",
            message="Manifest validation failed.",
            errors=[{"loc": "manifest_content", "msg": "YAML content must be a mapping."}],
        )

    try:
        KFSManifestWrapper.model_validate(data)
        return ManifestValidateResponse(
            status="success",
            message="Manifest is valid.",
        )
    except PydanticValidationError as e:
        errors = []
        for err in e.errors():
            loc_parts = [str(p) for p in err.get("loc", [])]
            errors.append({
                "loc": " -> ".join(loc_parts),
                "msg": _normalize_error_msg(err.get("msg", ""), err.get("type", "")),
                "type": err.get("type", ""),
            })
        return ManifestValidateResponse(
            status="error",
            message="Manifest validation failed.",
            errors=errors,
        )
