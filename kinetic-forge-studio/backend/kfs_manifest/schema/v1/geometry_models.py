from typing import Literal, Union, List, Optional, Annotated
from pydantic import BaseModel, Field, TypeAdapter, field_validator


# --- Geometry Primitives ---

class CubeGeometry(BaseModel):
    """Defines a cube primitive geometry."""
    type: Literal["cube"] = "cube"
    size: float = Field(..., gt=0, description="Side length of the cube.")


class SphereGeometry(BaseModel):
    """Defines a sphere primitive geometry."""
    type: Literal["sphere"] = "sphere"
    radius: float = Field(..., gt=0, description="Radius of the sphere.")


class CylinderGeometry(BaseModel):
    """Defines a cylinder primitive geometry."""
    type: Literal["cylinder"] = "cylinder"
    radius: float = Field(..., gt=0, description="Radius of the cylinder.")
    length: float = Field(..., gt=0, description="Length of the cylinder.")


class ConeGeometry(BaseModel):
    """Defines a cone primitive geometry."""
    type: Literal["cone"] = "cone"
    radius: float = Field(..., gt=0, description="Radius of the cone base.")
    length: float = Field(..., gt=0, description="Length of the cone.")


class CapsuleGeometry(BaseModel):
    """Defines a capsule primitive geometry."""
    type: Literal["capsule"] = "capsule"
    radius: float = Field(..., gt=0, description="Radius of the capsule.")
    length: float = Field(..., gt=0, description="Length of the cylindrical part.")


class MeshGeometry(BaseModel):
    """Defines a geometry based on a mesh file reference."""
    type: Literal["mesh"] = "mesh"
    path: str = Field(..., description="URI to the mesh file (must have a scheme like file://).")

    @field_validator("path")
    @classmethod
    def validate_path_is_uri(cls, v: str) -> str:
        if "://" not in v:
            raise ValueError("Path must be a valid URI with a scheme (e.g., file://).")
        return v


class SDFGeometry(BaseModel):
    """Defines a geometry based on an SDF file reference."""
    type: Literal["sdf"] = "sdf"
    path: str = Field(..., description="URI to the SDF file (must have a scheme like file://).")

    @field_validator("path")
    @classmethod
    def validate_path_is_uri(cls, v: str) -> str:
        if "://" not in v:
            raise ValueError("Path must be a valid URI with a scheme (e.g., file://).")
        return v


# --- Discriminated Union for all Geometry types ---

_GeometryUnion = Annotated[
    Union[
        CubeGeometry,
        SphereGeometry,
        CylinderGeometry,
        ConeGeometry,
        CapsuleGeometry,
        MeshGeometry,
        SDFGeometry,
    ],
    Field(discriminator="type"),
]

_geometry_adapter = TypeAdapter(_GeometryUnion)


class Geometry:
    """Wrapper providing model_validate() for the geometry discriminated union."""

    @classmethod
    def model_validate(cls, data):
        return _geometry_adapter.validate_python(data)
