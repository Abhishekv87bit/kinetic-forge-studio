from enum import Enum
from typing import List, Optional, Union, Annotated

from pydantic import BaseModel, Field, Discriminator
from .asset_models import Asset

# --- Enums ---

class GeometryType(str, Enum):
    """Enumeration of supported geometry types."""
    BOX = "box"
    SPHERE = "sphere"
    CYLINDER = "cylinder"
    CAPSULE = "capsule"
    CONE = "cone"
    PLANE = "plane"
    MESH = "mesh"

# --- Common Models ---

class Transform(BaseModel):
    """
    Represents a 3D transformation including translation, rotation, and scale.
    Rotation is specified in Euler angles (X, Y, Z) in degrees.
    """
    translation: List[float] = Field(default_factory=lambda: [0.0, 0.0, 0.0],
                                     min_length=3, max_length=3,
                                     description="Translation vector [x, y, z].")
    rotation: List[float] = Field(default_factory=lambda: [0.0, 0.0, 0.0],
                                  min_length=3, max_length=3,
                                  description="Rotation vector [rx, ry, rz] in degrees (Euler angles).")
    scale: List[float] = Field(default_factory=lambda: [1.0, 1.0, 1.0],
                               min_length=3, max_length=3,
                               description="Scale vector [sx, sy, sz].")

# --- Base Geometry Model ---

class BaseGeometry(BaseModel):
    """Abstract base class for all geometry definitions."""
    type: GeometryType = Field(..., description="The type of geometry.")
    name: Optional[str] = Field(None, description="Optional name for the geometry element.")
    id: Optional[str] = Field(None, description="Optional unique identifier for the geometry element.")

    model_config = {
        "extra": "forbid",
        "json_schema_extra": {
            "discriminator": "type"
        }
    }

# --- Primitive Geometry Models ---

class BoxGeometry(BaseGeometry):
    """Defines a box geometry."""
    type: GeometryType = Field(GeometryType.BOX, literal=True, description="The geometry type, must be 'box'.")
    x: float = Field(..., gt=0.0, description="Length along the X-axis.")
    y: float = Field(..., gt=0.0, description="Length along the Y-axis.")
    z: float = Field(..., gt=0.0, description="Length along the Z-axis.")

class SphereGeometry(BaseGeometry):
    """Defines a sphere geometry."""
    type: GeometryType = Field(GeometryType.SPHERE, literal=True, description="The geometry type, must be 'sphere'.")
    radius: float = Field(..., gt=0.0, description="Radius of the sphere.")

class CylinderGeometry(BaseGeometry):
    """Defines a cylinder geometry."""
    type: GeometryType = Field(GeometryType.CYLINDER, literal=True, description="The geometry type, must be 'cylinder'.")
    radius: float = Field(..., gt=0.0, description="Radius of the cylinder.")
    height: float = Field(..., gt=0.0, description="Height of the cylinder.")

class CapsuleGeometry(BaseGeometry):
    """Defines a capsule geometry (cylinder with hemispherical caps)."""
    type: GeometryType = Field(GeometryType.CAPSULE, literal=True, description="The geometry type, must be 'capsule'.")
    radius: float = Field(..., gt=0.0, description="Radius of the capsule.")
    height: float = Field(..., gt=0.0, description="Height of the cylindrical part of the capsule.")

class ConeGeometry(BaseGeometry):
    """Defines a cone geometry."""
    type: GeometryType = Field(GeometryType.CONE, literal=True, description="The geometry type, must be 'cone'.")
    radius: float = Field(..., gt=0.0, description="Radius of the cone's base.")
    height: float = Field(..., gt=0.0, description="Height of the cone.")

class PlaneGeometry(BaseGeometry):
    """Defines an infinite plane geometry."""
    type: GeometryType = Field(GeometryType.PLANE, literal=True, description="The geometry type, must be 'plane'.")
    # For an infinite plane, typically only orientation and position matter,
    # which would come from the parent transform. No intrinsic dimensions.

# --- Mesh Geometry Model ---

class MeshGeometry(BaseGeometry):
    """Defines a geometry by referencing an external mesh asset."""
    type: GeometryType = Field(GeometryType.MESH, literal=True, description="The geometry type, must be 'mesh'.")
    asset: Asset = Field(..., description="Reference to an external mesh asset.")

# --- Union Type for Geometry Definitions ---

GeometryDefinition = Annotated[
    Union[
        BoxGeometry,
        SphereGeometry,
        CylinderGeometry,
        CapsuleGeometry,
        ConeGeometry,
        PlaneGeometry,
        MeshGeometry,
    ],
    Discriminator("type")
]

# --- Component Structure Models ---

class ComponentGeometry(BaseModel):
    """
    Represents a single geometric element within a larger component,
    including its definition and local transformation.
    """
    name: Optional[str] = Field(None, description="Optional name for this specific geometry instance within the component.")
    geometry: GeometryDefinition = Field(..., description="The definition of the geometric shape.")
    transform: Optional[Transform] = Field(None, description="Local transform applied to this geometry element relative to its parent component.")

class ComponentInstance(BaseModel):
    """
    Represents an instance of another component within a parent component,
    allowing for hierarchical structures.
    """
    component_id: str = Field(..., description="The unique identifier (ID) of the component definition being instanced.")
    name: Optional[str] = Field(None, description="Optional name for this specific component instance.")
    transform: Optional[Transform] = Field(None, description="Local transform applied to this component instance relative to its parent component.")

class Component(BaseModel):
    """
    Defines a reusable component, which can contain its own geometry
    and/or instances of other components, forming a hierarchical structure.
    """
    id: str = Field(..., pattern=r"^[a-zA-Z0-9_-]+$", description="Unique identifier for this component definition. Must be alphanumeric, underscores, or hyphens.")
    name: Optional[str] = Field(None, description="Human-readable name for the component.")
    description: Optional[str] = Field(None, description="Optional description of the component.")
    geometry: List[ComponentGeometry] = Field(default_factory=list, description="List of geometric elements directly part of this component.")
    components: List[ComponentInstance] = Field(default_factory=list, description="List of instances of other components nested within this component.")

    model_config = {
        "extra": "forbid"
    }
