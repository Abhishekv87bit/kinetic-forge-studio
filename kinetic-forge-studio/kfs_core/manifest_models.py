from typing import List, Literal, Union, Optional, Dict, Any, Annotated
from pydantic import (
    BaseModel, Field, ConfigDict, confloat, conint, constr, conlist,
    NonNegativeFloat, model_validator, Discriminator, Tag, TypeAdapter
)

from kfs_core.constants import KFS_MANIFEST_VERSION

# --- 1. RGBColor ---

class RGBColor(BaseModel):
    """Represents an RGB color with values from 0-255."""
    r: conint(ge=0, le=255) = Field(..., description="Red component (0-255)")
    g: conint(ge=0, le=255) = Field(..., description="Green component (0-255)")
    b: conint(ge=0, le=255) = Field(..., description="Blue component (0-255)")

    def to_hex(self) -> str:
        """Converts the RGB color to a hexadecimal string."""
        return f"#{self.r:02x}{self.g:02x}{self.b:02x}"


# --- 2. Geometry Models ---

class BaseGeometry(BaseModel):
    """Base class for all KFS geometry types."""
    model_config = ConfigDict(extra="forbid")

    id: constr(min_length=1, max_length=64) = Field(..., description="Unique identifier for this geometry definition")

    def __eq__(self, other):
        if isinstance(other, dict):
            return self.model_dump() == other
        return super().__eq__(other)

    def __hash__(self):
        return hash((type(self), self.id))


class SphereGeometry(BaseGeometry):
    """Defines a sphere geometry."""
    type: Literal["sphere"] = Field("sphere", description="Type of geometry")
    radius: NonNegativeFloat = Field(1.0, description="Radius of the sphere")


class CubeGeometry(BaseGeometry):
    """Defines a cube geometry."""
    type: Literal["cube"] = Field("cube", description="Type of geometry")
    size: NonNegativeFloat = Field(1.0, description="Side length of the cube")


class CylinderGeometry(BaseGeometry):
    """Defines a cylinder geometry."""
    type: Literal["cylinder"] = Field("cylinder", description="Type of geometry")
    radius: NonNegativeFloat = Field(0.5, description="Radius of the cylinder")
    height: NonNegativeFloat = Field(1.0, description="Height of the cylinder")


class MeshGeometry(BaseGeometry):
    """References an external mesh file."""
    type: Literal["mesh"] = Field("mesh", description="Type of geometry")
    path: constr(min_length=1) = Field(..., description="Path to the mesh file (e.g., .obj, .fbx)")


# Discriminated union for all geometry types
def _geometry_discriminator(v: Any) -> str:
    if isinstance(v, dict):
        return v.get("type", "")
    return getattr(v, "type", "")


_GeometryUnion = Annotated[
    Union[
        Annotated[SphereGeometry, Tag("sphere")],
        Annotated[CubeGeometry, Tag("cube")],
        Annotated[CylinderGeometry, Tag("cylinder")],
        Annotated[MeshGeometry, Tag("mesh")],
    ],
    Discriminator(_geometry_discriminator),
]

_geometry_adapter = TypeAdapter(_GeometryUnion)


class Geometry:
    """
    Callable factory for geometry types.
    Use Geometry(**data) to create the correct geometry subtype.
    Also used as type annotation via __class_getitem__.
    """

    def __new__(cls, **kwargs):
        return _geometry_adapter.validate_python(kwargs)

    def __class_getitem__(cls, item):
        return _GeometryUnion

    @classmethod
    def __get_pydantic_core_schema__(cls, source_type, handler):
        return _geometry_adapter.core_schema


# --- 3. Material Model ---

class Material(BaseModel):
    """Defines a material with color and physical properties."""
    model_config = ConfigDict(extra="forbid")

    id: Optional[constr(min_length=1, max_length=64)] = Field(None, description="Unique identifier for this material definition")
    color: RGBColor = Field(default_factory=lambda: RGBColor(r=255, g=255, b=255), description="Base color of the material")
    roughness: confloat(ge=0.0, le=1.0) = Field(0.5, description="Roughness of the material (0.0=smooth, 1.0=rough)")
    metallic: confloat(ge=0.0, le=1.0) = Field(0.0, description="Metallic property of the material (0.0=dielectric, 1.0=metallic)")
    emissive_color: Optional[RGBColor] = Field(None, description="Emissive color of the material")


# --- 4. Rotation Models (for Transform discriminated union in schema) ---

class EulerRotation(BaseModel):
    """Euler angle rotation."""
    type: Literal["euler"] = "euler"
    angles: conlist(float, min_length=3, max_length=3) = Field([0.0, 0.0, 0.0])
    order: str = Field("XYZ")


class AxisAngleRotation(BaseModel):
    """Axis-angle rotation."""
    type: Literal["axis_angle"] = "axis_angle"
    axis: conlist(float, min_length=3, max_length=3) = Field([0.0, 1.0, 0.0])
    angle: float = Field(0.0)


class QuaternionRotation(BaseModel):
    """Quaternion rotation."""
    type: Literal["quaternion"] = "quaternion"
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0
    w: float = 1.0


# --- 5. Transform Model ---

class Transform(BaseModel):
    """Represents an object's position, rotation, and scale in 3D space."""
    position: conlist(float, min_length=3, max_length=3) = Field(default=[0.0, 0.0, 0.0], description="[x, y, z] position")
    rotation: conlist(float, min_length=3, max_length=3) = Field(default=[0.0, 0.0, 0.0], description="[pitch, yaw, roll] rotation in degrees")
    scale: conlist(confloat(gt=0), min_length=3, max_length=3) = Field(default=[1.0, 1.0, 1.0], description="[sx, sy, sz] scale factors (must be > 0)")


# --- 6. Animation Models ---

class Keyframe(BaseModel):
    """Represents a single keyframe in an animation."""
    time: NonNegativeFloat = Field(..., description="Time in seconds at which this keyframe occurs")
    value: Union[float, conlist(float, min_length=3, max_length=3)] = Field(..., description="Scalar or [x, y, z] value at this keyframe")
    interpolation: Literal["linear", "spline", "step", "ease_in_out"] = Field("linear", description="Interpolation method to the next keyframe")


class AnimationTrack(BaseModel):
    """Defines an animation track targeting a specific property with keyframes."""
    property: Optional[constr(min_length=1)] = Field(None, description="The target property (e.g., 'position.x', 'rotation.y')")
    target: Optional[constr(min_length=1)] = Field(None, description="The target property (alias for property)")
    keyframes: List[Keyframe] = Field(..., min_length=2, description="List of keyframes (minimum 2)")

    @model_validator(mode="after")
    def validate_keyframe_order(self):
        """Validate that keyframe times are strictly increasing."""
        keyframes = self.keyframes
        for i in range(1, len(keyframes)):
            if keyframes[i].time <= keyframes[i - 1].time:
                raise ValueError("Keyframe times must be strictly increasing.")
        return self


class Animation(BaseModel):
    """Container for animation tracks on an object."""
    tracks: List[AnimationTrack] = Field(default_factory=list, description="List of animation tracks")


# --- 7. KFSObject Model (inline geometry/material style for test_manifest_models) ---

class KFSObject(BaseModel):
    """Represents a complete object in the sculpture."""
    id: constr(min_length=1, max_length=64) = Field(..., description="Unique identifier for this object")
    name: Optional[str] = Field(None, description="Optional human-readable name")
    geometry: Optional[Geometry] = Field(None, description="Inline geometry definition for this object")
    material: Optional[Material] = Field(None, description="Inline material definition for this object")
    transform: Transform = Field(default_factory=Transform, description="Transform for this object")
    animations: List[AnimationTrack] = Field(default_factory=list, description="Animation tracks for this object")

    # Reference-based fields (for parser/validator tests)
    geometry_id: Optional[constr(min_length=1, max_length=64)] = Field(None, description="ID referencing a geometry in the geometries dict")
    material_id: Optional[constr(min_length=1, max_length=64)] = Field(None, description="ID referencing a material in the materials dict")
    animation: Optional[Animation] = Field(None, description="Animation data with tracks")


# --- 8. Top-level KFSManifest Model ---

class KFSManifest(BaseModel):
    """The top-level Pydantic model for a KFS manifest file."""
    model_config = ConfigDict(extra="forbid")

    # Fields for test_manifest_models style
    api_version: Optional[constr(min_length=1)] = Field(None, description="Version of the KFS manifest schema (api_version style)")
    kind: Optional[Literal["KFSManifest"]] = Field(None, description="Kind of manifest")

    # Fields for parser/validator style
    kfs_version: Optional[constr(min_length=1)] = Field(None, description="Version of the KFS manifest schema (kfs_version style)")

    # Shared fields
    name: constr(min_length=1, max_length=128) = Field(..., description="Name of the kinetic sculpture project")
    description: Optional[constr(max_length=512)] = Field(None, description="A brief description of the sculpture")

    # Collections of definitions (for reference-based manifests)
    geometries: Dict[str, Geometry] = Field(default_factory=dict, description="Dictionary of geometry definitions, keyed by ID")
    materials: Dict[str, Material] = Field(default_factory=dict, description="Dictionary of material definitions, keyed by ID")

    # Objects list
    objects: List[KFSObject] = Field(..., description="List of objects in the sculpture")

    # Optional settings
    simulation_settings: Optional[Dict[str, Any]] = Field(None, description="Optional simulation specific settings")
    render_settings: Optional[Dict[str, Any]] = Field(None, description="Optional render specific settings")

    @model_validator(mode="after")
    def set_defaults_and_validate(self):
        """Set defaults for api_version/kind and validate version compatibility."""
        # If api_version is provided but kfs_version is not, set kfs_version from api_version
        if self.api_version is not None and self.kfs_version is None:
            self.kfs_version = self.api_version
        # If kfs_version is provided but api_version is not, set api_version from kfs_version
        if self.kfs_version is not None and self.api_version is None:
            self.api_version = self.kfs_version

        # Default api_version/kfs_version to KFS_MANIFEST_VERSION
        if self.api_version is None:
            self.api_version = KFS_MANIFEST_VERSION
        if self.kfs_version is None:
            self.kfs_version = KFS_MANIFEST_VERSION

        # Default kind
        if self.kind is None:
            self.kind = "KFSManifest"

        # Validate api_version matches supported version
        if self.api_version != KFS_MANIFEST_VERSION:
            raise ValueError(
                f"Unsupported api_version '{self.api_version}'. "
                f"This parser supports '{KFS_MANIFEST_VERSION}'."
            )

        return self
