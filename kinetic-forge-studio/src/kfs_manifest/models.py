from typing import List, Literal, Optional, Union
from pydantic import BaseModel, Field, PositiveFloat, confloat

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

# --- Geometry Models ---

class Geometry(BaseModel):
    """Abstract base class for all geometry types, allowing for discriminated unions."""
    name: str = Field(..., description="Unique name for this geometry definition.")
    type: Literal["box", "sphere", "cylinder", "mesh"] = Field(..., description="The specific type of geometry.")

class BoxGeometry(Geometry):
    """A rectangular prism geometry."""
    type: Literal["box"] = "box"
    width: PositiveFloat = Field(1.0, description="Width of the box along X-axis.")
    height: PositiveFloat = Field(1.0, description="Height of the box along Y-axis.")
    depth: PositiveFloat = Field(1.0, description="Depth of the box along Z-axis.")

class SphereGeometry(Geometry):
    """A spherical geometry."""
    type: Literal["sphere"] = "sphere"
    radius: PositiveFloat = Field(0.5, description="Radius of the sphere.")

class CylinderGeometry(Geometry):
    """A cylindrical geometry."""
    type: Literal["cylinder"] = "cylinder"
    radius: PositiveFloat = Field(0.5, description="Radius of the cylinder base.")
    height: PositiveFloat = Field(1.0, description="Height of the cylinder.")

class MeshGeometry(Geometry):
    """A custom 3D mesh loaded from an external file."""
    type: Literal["mesh"] = "mesh"
    path: str = Field(..., description="Path to the external 3D model file (e.g., .obj, .glb).")
    import_scale: Vector3 = Field(Vector3(x=1.0, y=1.0, z=1.0), description="Scale factors applied during mesh import.")

# --- Material Models ---

class Material(BaseModel):
    """Abstract base class for all material types, allowing for discriminated unions."""
    name: str = Field(..., description="Unique name for this material definition.")
    type: Literal["phong", "basic", "pbr"] = Field(..., description="The specific type of material.")

class Color(BaseModel):
    """Represents an RGBA color."""
    r: confloat(ge=0, le=1) = Field(0.5, description="Red component (0.0-1.0).")
    g: confloat(ge=0, le=1) = Field(0.5, description="Green component (0.0-1.0).")
    b: confloat(ge=0, le=1) = Field(0.5, description="Blue component (0.0-1.0).")
    a: confloat(ge=0, le=1) = Field(1.0, description="Alpha component (0.0-1.0).")

class PhongMaterial(Material):
    """A Phong shading material with diffuse, specular, and shininess properties."""
    type: Literal["phong"] = "phong"
    color: Color = Field(Color(r=0.7, g=0.7, b=0.7), description="Diffuse color of the material.")
    specular: Color = Field(Color(r=0.1, g=0.1, b=0.1), description="Specular color.")
    shininess: confloat(ge=0, le=1000) = Field(30.0, description="Shininess exponent.")

class BasicMaterial(Material):
    """A simple material with only a base color."""
    type: Literal["basic"] = "basic"
    color: Color = Field(Color(r=0.5, g=0.5, b=0.5), description="Base color of the material.")

class PBRMaterial(Material):
    """A Physically Based Rendering (PBR) material."""
    type: Literal["pbr"] = "pbr"
    base_color: Color = Field(Color(r=0.7, g=0.7, b=0.7), description="Base color of the material.")
    metallic: confloat(ge=0, le=1) = Field(0.0, description="Metallic property (0.0-1.0).")
    roughness: confloat(ge=0, le=1) = Field(0.5, description="Roughness property (0.0-1.0).")

# --- Motion Profile Models ---

class MotionProfile(BaseModel):
    """Abstract base class for all motion profile types, allowing for discriminated unions."""
    name: str = Field(..., description="Unique name for this motion profile definition.")
    type: Literal["static", "linear_rotation", "linear_translation", "oscillation"] = Field(..., description="The specific type of motion profile.")

class StaticMotion(MotionProfile):
    """A motion profile representing no movement or a fixed state."""
    type: Literal["static"] = "static"

class LinearRotationMotion(MotionProfile):
    """A motion profile for constant rotation around an axis."""
    type: Literal["linear_rotation"] = "linear_rotation"
    axis: Vector3 = Field(Vector3(x=0.0, y=1.0, z=0.0), description="Axis of rotation.")
    speed_rad_s: float = Field(0.1, description="Constant rotational speed in radians per second.")

class LinearTranslationMotion(MotionProfile):
    """A motion profile for constant translation along a direction."""
    type: Literal["linear_translation"] = "linear_translation"
    direction: Vector3 = Field(Vector3(x=0.0, y=0.0, z=1.0), description="Direction of translation.")
    speed_units_s: float = Field(0.1, description="Constant translational speed in units per second.")

class OscillationMotion(MotionProfile):
    """A motion profile for oscillatory (e.g., sinusoidal) movement."""
    type: Literal["oscillation"] = "oscillation"
    axis: Vector3 = Field(Vector3(x=0.0, y=1.0, z=0.0), description="Axis/direction of oscillation.")
    amplitude: float = Field(1.0, description="Maximum displacement/angle from origin for oscillation.")
    frequency_hz: PositiveFloat = Field(0.5, description="Frequency of oscillation in Hertz.")
    offset: float = Field(0.0, description="Phase offset for the oscillation in radians.")

# --- Component and Top-Level Models ---

class Component(BaseModel):
    """A visual/kinematic element of the sculpture, linking geometry, material, and motion."""
    name: str = Field(..., description="Unique name for this component instance.")
    geometry: str = Field(..., description="Name of the geometry definition to use.")
    material: str = Field(..., description="Name of the material definition to use.")
    motion_profile: str = Field(..., description="Name of the motion profile definition to use.")
    transform: Transform = Field(Transform(), description="Initial local transform for the component.")
    children: List["Component"] = Field([], description="Child components, forming a hierarchical structure.")

# Forward reference for recursive models (Pydantic needs this for `children`)
Component.update_forward_refs()

class SimulationSettings(BaseModel):
    """Global simulation parameters for the kinetic sculpture."""
    gravity: Vector3 = Field(Vector3(x=0.0, y=-9.81, z=0.0), description="Gravitational acceleration vector.")
    time_step_s: PositiveFloat = Field(0.016, description="Fixed time step for simulation in seconds (e.g., 1/60 fps). A smaller value means higher fidelity.")
    duration_s: PositiveFloat = Field(60.0, description="Total simulation duration in seconds.")
    
class KineticSculptureManifest(BaseModel):
    """Top-level model for a Kinetic Forge Studio (KFS) manifest file."""
    manifest_version: Literal["1.0"] = Field("1.0", description="Version of the KFS manifest schema.")
    name: str = Field(..., description="Name of the kinetic sculpture.")
    description: Optional[str] = Field(None, description="Optional description of the sculpture.")

    geometries: List[
        Union[BoxGeometry, SphereGeometry, CylinderGeometry, MeshGeometry]
    ] = Field([], description="Definitions of geometric shapes used in the sculpture.")

    materials: List[
        Union[PhongMaterial, BasicMaterial, PBRMaterial]
    ] = Field([], description="Definitions of materials used in the sculpture.")

    motion_profiles: List[
        Union[StaticMotion, LinearRotationMotion, LinearTranslationMotion, OscillationMotion]
    ] = Field([], description="Definitions of motion patterns applied to components.")

    root_components: List[Component] = Field(
        [], description="Top-level components of the sculpture, forming the root of the hierarchy."
    )
    
    simulation_settings: SimulationSettings = Field(
        SimulationSettings(), description="Global simulation parameters."
    )