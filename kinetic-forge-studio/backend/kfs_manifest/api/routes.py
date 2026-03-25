from fastapi import APIRouter, HTTPException, status
from typing import List, Optional, Union

from ...parser import parse_manifest
from ...validator import validate_manifest
from ...errors import KFSManifestError, KFSManifestValidationError
from ...schema.v1.kinetic_forge_schema import KineticForgeSchema
from .models import HealthCheckResponse, ManifestParseRequest, ManifestParseResponse

router = APIRouter()


@router.get("/health", response_model=HealthCheckResponse, summary="Health Check")
async def health_check():
    """
    Performs a health check on the API service.

    Returns:
        HealthCheckResponse: A response indicating the API's status.
    """
    return HealthCheckResponse(status="ok", message="KFS Manifest API is running.")


@router.post(
    "/parse_manifest",
    response_model=ManifestParseResponse,
    summary="Parse and Validate KFS Manifest",
)
async def parse_and_validate_manifest(request: ManifestParseRequest):
    """
    Receives a KFS manifest content (YAML string), parses it,
    validates it against the schema, and returns the parsed object
    or a list of errors.

    Args:
        request (ManifestParseRequest): The request body containing the manifest content.

    Returns:
        ManifestParseResponse: The response containing the status, parsed manifest (if successful),
                               or a list of errors (if failed).
    """
    try:
        # Parse the manifest content
        parsed_data = parse_manifest(request.manifest_content)

        # Validate the parsed data
        validate_manifest(parsed_data)

        return ManifestParseResponse(status="success", parsed_manifest=parsed_data)
    except KFSManifestValidationError as e:
        # Extract detailed error messages from Pydantic's ValidationError
        error_messages = [f"{err['loc']}: {err['msg']}" for err in e.errors]
        return ManifestParseResponse(status="failed", errors=error_messages)
    except KFSManifestError as e:
        # Catch other KFS specific errors (e.g., parsing errors, asset resolution errors)
        return ManifestParseResponse(status="failed", errors=[str(e)])
    except Exception as e:
        # Catch any other unexpected errors during processing
        # For unexpected errors, still return a structured response.
        return ManifestParseResponse(status="failed", errors=[f"An unexpected error occurred: {str(e)}"])
