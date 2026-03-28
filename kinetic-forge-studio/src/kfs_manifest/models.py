import re
from typing import Annotated, List, Literal, Optional, Union
from pydantic import BaseModel, Field, PositiveFloat, TypeAdapter, ValidationError, confloat


# --- Utility Models ---

class Vector3(BaseModel):
    """Represents a 3D vector or point."""
    x: float = Field(..., description="X component.")
    y: float = Field(..., description="Y component.")
    z: float = Field(..., description="Z component.")


class Quaternion(BaseModel):
    """Represents a 3D rotation using a quaternion."""
    x: float = Field(0.0, description="X component of the quaternion.")
    y: float = Field(0.0, description="Y component of the quaternion.")
    z: float = Field(0.0, description="Z component of the quaternion.")
    w: float = Field(1.0, description="W component of the quaternion.")


class Transform(BaseModel):
    """Represents the position, rotation, and scale of an object in 3D space."""
    position: Vector3 = Field(Vector3(x=0.0, y=0.0, z=0.0), description="Local position relative to parent.")
    rotation: Quaternion = Field(Quaternion(), description="Local rotation as a quaternion.")
    scale: Vector3 = Field(Vector3(x=1.0, y=1.0, z=1.0), description="Local scale factors.")


# --- Metadata ---

class Metadata(BaseModel):
    """Metadata about the kinetic sculpture."""
    name: str = Field(..., description="A human-readable name for the sculpture.")
    description: str = Field("", description="A brief description of the sculpture's design or purpose.")


# --- Geometry Models ---

class GeometryBase(BaseModel):
    """Abstract base class for all geometry types."""
    name: str = Field(..., description="Unique name for this geometry definition.")
    type: str = Field(..., description="The specific type of geometry.")


class BoxGeometry(GeometryBase):
    """A rectangular prism geometry."""
    type: Literal["box"] = "box"
    width: PositiveFloat = Field(1.0, description="Width of the box along X-axis.")
    height: PositiveFloat = Field(1.0, description="Height of the box along Y-axis.")
    depth: PositiveFloat = Field(1.0, description="Depth of the box along Z-axis.")


class SphereGeometry(GeometryBase):
    """A spherical geometry."""
    type: Literal["sphere"] = "sphere"
    radius: PositiveFloat = Field(0.5, description="Radius of the sphere.")


class CylinderGeometry(GeometryBase):
    """A cylindrical geometry."""
    type: Literal["cylinder"] = "cylinder"
    radius: PositiveFloat = Field(0.5, description="Radius of the cylinder base.")
    height: PositiveFloat = Field(1.0, description="Height of the cylinder.")


class MeshGeometry(GeometryBase):
    """A custom 3D mesh loaded from an external file."""
    type: Literal["mesh"] = "mesh"
    path: str = Field(..., description="Path to the external 3D model file (e.g., .obj, .glb).")
    import_scale: Vector3 = Field(Vector3(x=1.0, y=1.0, z=1.0), description="Scale factors applied during mesh import.")


# Discriminated union for all geometry types
_GeometryUnion = Annotated[
    Union[BoxGeometry, SphereGeometry, CylinderGeometry, MeshGeometry],
    Field(discriminator="type"),
]

_VALID_GEOMETRY_TYPES = {"box", "sphere", "cylinder", "mesh"}
_geometry_adapter = TypeAdapter(_GeometryUnion)


def _pre_validate_geometry(data):
    """Pre-validate geometry data to provide clearer error messages."""
    if isinstance(data, dict):
        if "type" not in data:
            raise ValidationError.from_exception_data(
                title="Geometry",
                line_errors=[{
                    "type": "missing",
                    "loc": ("type",),
                    "input": data,
                }],
            )
        geo_type = data.get("type")
        if geo_type not in _VALID_GEOMETRY_TYPES:
            raise ValidationError.from_exception_data(
                title="Geometry",
                line_errors=[{
                    "type": "value_error",
                    "loc": (),
                    "input": data,
                    "ctx": {"error": ValueError(f"type discriminant '{geo_type}' was not recognized")},
                }],
            )
    return data


class Geometry:
    """Wrapper providing model_validate() for the geometry discriminated union."""

    @classmethod
    def model_validate(cls, data):
        _pre_validate_geometry(data)
        return _geometry_adapter.validate_python(data)


# --- Material Models ---

class Color(BaseModel):
    """Represents an RGBA color."""
    r: confloat(ge=0, le=1) = Field(0.5, description="Red component (0.0-1.0).")
    g: confloat(ge=0, le=1) = Field(0.5, description="Green component (0.0-1.0).")
    b: confloat(ge=0, le=1) = Field(0.5, description="Blue component (0.0-1.0).")
    a: confloat(ge=0, le=1) = Field(1.0, description="Alpha component (0.0-1.0).")


class MaterialBase(BaseModel):
    """Abstract base class for all material types."""
    name: str = Field(..., description="Unique name for this material definition.")
    type: str = Field(..., description="The specific type of material.")


class PhongMaterial(MaterialBase):
    """A Phong shading material."""
    type: Literal["phong"] = "phong"
    color: Union[Color, str] = Field(Color(r=0.7, g=0.7, b=0.7), description="Diffuse color.")
    specular: Optional[Color] = Field(None, description="Specular color.")
    shininess: confloat(ge=0, le=1000) = Field(30.0, description="Shininess exponent.")


# --- Object Model ---

class SceneObject(BaseModel):
    """A visual/kinematic element of the sculpture."""
    name: str = Field(..., description="Unique name for this object.")
    type: str = Field(..., description="Object type.")
    geometry_ref: Optional[str] = Field(None, description="Name of the geometry definition to use.")
    material_ref: Optional[str] = Field(None, description="Name of the material definition to use.")
    transform: Transform = Field(Transform(), description="Initial local transform.")


# --- Simulation Parameters ---

class SimulationParameters(BaseModel):
    """Global simulation parameters for the kinetic sculpture."""
    gravity: Vector3 = Field(Vector3(x=0.0, y=-9.81, z=0.0), description="Gravitational acceleration vector.")
    solver: str = Field("euler", description="Simulation solver method.")
    timestep: float = Field(0.016, description="Fixed time step for simulation in seconds.")


# --- Component (for backwards compatibility) ---

class Component(BaseModel):
    """A component linking geometry, material, motion."""
    name: str = Field(..., description="Unique name for this component instance.")
    geometry: str = Field(..., description="Name of the geometry definition to use.")
    material: str = Field(..., description="Name of the material definition to use.")
    transform: Transform = Field(Transform(), description="Initial local transform.")
    children: List["Component"] = Field([], description="Child components.")


Component.model_rebuild()


# --- Top-level Manifest ---

class KineticSculptureManifest(BaseModel):
    """Top-level model for a Kinetic Forge Studio (KFS) manifest file."""
    version: Literal["1.0"] = Field("1.0", description="The schema version this manifest adheres to.")
    metadata: Metadata = Field(..., description="Metadata about the sculpture.")

    geometries: List[
        Union[BoxGeometry, SphereGeometry, CylinderGeometry, MeshGeometry]
    ] = Field([], description="Definitions of geometric shapes used in the sculpture.")

    materials: List[
        Union[PhongMaterial, MaterialBase]
    ] = Field([], description="Definitions of materials used in the sculpture.")

    objects: List[SceneObject] = Field([], description="Scene objects composing the sculpture.")

    animations: List[dict] = Field([], description="Placeholder for future animation definitions.")

    simulations: SimulationParameters = Field(
        SimulationParameters(), description="Global simulation parameters."
    )
