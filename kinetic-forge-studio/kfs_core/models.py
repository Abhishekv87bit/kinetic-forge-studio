from pydantic import BaseModel, Field, ValidationError, PositiveFloat, NonNegativeFloat
from typing import List, Optional, Literal, Dict, Any

# --- Core KFS Pydantic Models ---

class Vector3D(BaseModel):
    x: float = Field(..., description="X coordinate")
    y: float = Field(..., description="Y coordinate")
    z: float = Field(..., description="Z coordinate")

    def __str__(self):
        return f"({self.x}, {self.y}, {self.z})"

class Color(BaseModel):
    r: int = Field(..., ge=0, le=255, description="Red component (0-255)")
    g: int = Field(..., ge=0, le=255, description="Green component (0-255)")
    b: int = Field(..., ge=0, le=255, description="Blue component (0-255)")

    def to_hex(self) -> str:
        return f"#{self.r:02x}{self.g:02x}{self.b:02x}"

class Material(BaseModel):
    name: str = Field(..., description="Unique name for the material")
    color: Color = Field(..., description="Base color of the material")
    roughness: NonNegativeFloat = Field(0.5, le=1.0, description="Material roughness (0.0 - 1.0)")
    metallic: NonNegativeFloat = Field(0.0, le=1.0, description="Material metallicness (0.0 - 1.0)")
    emissive_color: Optional[Color] = Field(None, description="Emissive color, if the material glows")

class Geometry(BaseModel):
    type: str = Field(..., description="Type of geometry (e.g., 'box', 'sphere', 'cylinder')")
    # Additional fields would be defined in subclasses or dynamically based on type

class BoxGeometry(Geometry):
    type: Literal["box"] = "box"
    width: PositiveFloat = Field(..., description="Width of the box")
    height: PositiveFloat = Field(..., description="Height of the box")
    depth: PositiveFloat = Field(..., description="Depth of the box")

class SphereGeometry(Geometry):
    type: Literal["sphere"] = "sphere"
    radius: PositiveFloat = Field(..., description="Radius of the sphere")

class KineticComponent(BaseModel):
    id: str = Field(..., description="Unique identifier for the component")
    name: Optional[str] = Field(None, description="Display name of the component")
    geometry: Geometry = Field(..., description="The 3D geometry of the component")
    material: str = Field(..., description="Reference to a defined material by name")
    position: Vector3D = Field(Vector3D(x=0.0, y=0.0, z=0.0), description="Local position relative to parent")
    rotation: Vector3D = Field(Vector3D(x=0.0, y=0.0, z=0.0), description="Local rotation in Euler angles (degrees)")
    parent: Optional[str] = Field(None, description="ID of the parent component, if nested")
    motion_profile: Optional[str] = Field(None, description="Reference to a motion profile by name")

class MotionParameter(BaseModel):
    id: str = Field(..., description="Unique identifier for the motion parameter")
    type: Literal["rotation", "translation", "scale"] = Field(..., description="Type of motion")
    axis: Optional[Literal["x", "y", "z"]] = Field(None, description="Axis of motion for rotation/translation")
    start_value: float = Field(..., description="Initial value")
    end_value: float = Field(..., description="Final value")
    duration: PositiveFloat = Field(..., description="Duration of the motion in seconds")
    ease_function: str = Field("linear", description="Easing function name (e.g., 'linear', 'ease_in_out')")

class SimulationSettings(BaseModel):
    duration: PositiveFloat = Field(60.0, description="Total simulation duration in seconds")
    time_step: PositiveFloat = Field(0.016, description="Simulation time step in seconds (e.g., 1/60 for 60fps)")
    gravity: Vector3D = Field(Vector3D(x=0.0, y=-9.81, z=0.0), description="Global gravity vector")
    ambient_light_color: Color = Field(Color(r=50, g=50, b=50), description="Ambient light color")

class KFSManifest(BaseModel):
    metadata: Dict[str, str] = Field(default_factory=dict, description="Arbitrary metadata")
    materials: List[Material] = Field(default_factory=list, description="List of defined materials")
    components: List[KineticComponent] = Field(default_factory=list, description="List of kinetic sculpture components")
    motion_parameters: List[MotionParameter] = Field(default_factory=list, description="List of motion parameter definitions")
    simulation_settings: SimulationSettings = Field(default_factory=SimulationSettings, description="Simulation global settings")

    def find_material(self, name: str) -> Optional[Material]:
        return next((m for m in self.materials if m.name == name), None)

    def find_component(self, id: str) -> Optional[KineticComponent]:
        return next((c for c in self.components if c.id == id), None)

    def find_motion_parameter(self, id: str) -> Optional[MotionParameter]:
        return next((mp for mp in self.motion_parameters if mp.id == id), None)
