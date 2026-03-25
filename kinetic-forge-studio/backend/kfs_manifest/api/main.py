from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from .routes import router

app = FastAPI(
    title="KFS Manifest API",
    description="API for parsing and validating KFS manifest files.",
    version="0.1.0",
)


_MSG_MAP = {
    "missing": "field required",
    "string_type": "string type expected",
    "int_type": "value is not a valid integer",
    "float_type": "value is not a valid float",
    "enum": "value is not a valid enumeration member",
    "model_attributes_type": "JSON decode error",
    "json_invalid": "JSON decode error",
}


@app.exception_handler(RequestValidationError)
async def custom_validation_exception_handler(request: Request, exc: RequestValidationError):
    """Normalize Pydantic v2 validation errors to v1-compatible format for 422 responses."""
    errors = []
    for err in exc.errors():
        error_type = err.get("type", "")
        msg = _MSG_MAP.get(error_type, err.get("msg", ""))
        errors.append({
            "loc": list(err.get("loc", [])),
            "msg": msg,
            "type": error_type,
        })
    return JSONResponse(
        status_code=422,
        content={"detail": errors},
    )


# Include the API routes with a version prefix
app.include_router(router, prefix="/api/v1")
