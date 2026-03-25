from typing import List, Dict, Any, Tuple, Literal, Optional, Union
from pydantic import BaseModel, Field

# --- Core Primitive Types ---

class Pose(BaseModel):
    """Represents a position and orientation (Roll, Pitch, Yaw in radians)."""
    position: Tuple[float, float, float] = Field((0.0, 0.0, 0.0), description="Position in (x, y, z) coordinates.")
    orientation_rpy: Tuple[float, float, float] = Field((0.0, 0.0, 0.0), description="Orientation as Roll, Pitch, Yaw (radians).")

# --- Geometry Definitions ---

class BaseGeometryParameters(BaseModel):
    """Base class for common geometry parameters."""
    name: str = Field(..., description="Unique name for this geometry definition.")
    material: Optional[str] = Field(None, description="Reference to a material definition (future work).")

class SphereGeometry(BaseGeometryParameters):
    """Parameters for a sphere geometry."""
    type: Literal["sphere"] = "sphere"
    radius: float = Field(..., gt=0, description="Radius of the sphere.")
    center: Tuple[float, float, float] = Field((0.0, 0.0, 0.0), description="Center of the sphere in local coordinates.")

class BoxGeometry(BaseGeometryParameters):
    """Parameters for a box geometry."""
    type: Literal["box"] = "box"
    dimensions: Tuple[float, float, float] = Field(..., description="Dimensions (x, y, z) of the box.")
    origin: Tuple[float, float, float] = Field((0.0, 0.0, 0.0), description="Origin of the box in local coordinates.")

class MeshGeometry(BaseGeometryParameters):
    """Parameters for a mesh geometry imported from a file."""
    type: Literal["mesh"] = "mesh"
    file_path: str = Field(..., description="Path to the mesh file (e.g., .stl, .obj).")
    scale: float = Field(1.0, gt=0, description="Scaling factor to apply to the mesh.")

# Union type for all possible geometry definitions. Pydantic will use the 'type' field
# as a discriminator for parsing from dictionaries (e.g., YAML/JSON).
GeometryDefinition = Union[SphereGeometry, BoxGeometry, MeshGeometry]

# --- Body Definitions (linking geometry to simulation objects) ---

class BodyDefinition(BaseModel):
    """Defines a rigid body in the simulation with its physical properties and initial pose."""
    name: str = Field(..., description="Unique name for the body.")
    geometry_ref: str = Field(..., description="Name of the geometry defined in the 'geometry_definitions' section.")
    mass: float = Field(..., gt=0, description="Mass of the body in kilograms.")
    inertia_matrix: List[List[float]] = Field(
        ...,
        min_length=3, max_length=3,
        description="3x3 inertia matrix (row-major) relative to the body's center of mass. "
                    "e.g., [[Ixx, Ixy, Ixz], [Iyx, Iyy, Iyz], [Izx, Izy, Izz]]."
    )
    initial_pose: Optional[Pose] = Field(None, description="Initial pose of the body in the world frame.")

# --- Simulation Definitions ---

class SimulationParameters(BaseModel):
    """Overall simulation settings and solver configuration."""
    solver: Literal["mujoco", "bullet", "unity"] = Field(..., description="The simulation solver to use.")
    time_step: float = Field(..., gt=0, description="Simulation time step in seconds.")
    duration: float = Field(..., gt=0, description="Total simulation duration in seconds.")
    gravity: Tuple[float, float, float] = Field((0.0, 0.0, -9.81), description="Gravity vector (x, y, z).")
    # Future extension: Add more solver-specific configuration fields or a generic 'solver_config: Dict[str, Any]'

# --- Top-level KFS Manifest ---

class KFSManifest(BaseModel):
    """
    Kinetic Forge Studio Manifest: Defines a complete scene for geometry generation
    and motion simulation, intended for a declarative .kfs.yaml format.
    """
    version: str = Field("1.0", description="Version of the KFS manifest schema.")
    name: str = Field(..., description="Name of the KFS project/manifest.")

    geometry_definitions: List[GeometryDefinition] = Field(
        ...,
        description="List of geometry definitions (e.g., spheres, boxes, meshes) to be used."
    )
    body_definitions: List[BodyDefinition] = Field(
        ...,
        description="List of rigid body definitions, linking geometries to physical properties and initial poses."
    )
    simulation_settings: SimulationParameters = Field(
        ...,
        description="Overall simulation settings and solver configuration."
    )

    # Future extensions could include:
    # materials: Optional[List[MaterialDefinition]] = None
    # sensors: Optional[List[SensorDefinition]] = None
    # actuators: Optional[List[ActuatorDefinition]] = None
    # controllers: Optional[List[ControllerDefinition]] = None
    # plugins: Optional[List[PluginConfiguration]] = None


# --- Lightweight spec types for KFSManifestParser ---

class GeometrySpec(BaseModel):
    """Lightweight geometry specification parsed from a manifest."""
    type: str = Field(..., description="Type of geometry (e.g., 'cube', 'sphere').")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Geometry parameters.")

class SimulationSpec(BaseModel):
    """Lightweight simulation specification parsed from a manifest."""
    type: str = Field(..., description="Type of simulation (e.g., 'kinematic_chain', 'ode_solver').")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Simulation parameters.")


class KFSManifestParsed:
    """Simple container for parsed manifest data from KFSManifestParser."""
    def __init__(self, geometry: GeometrySpec, simulation: SimulationSpec):
        self.geometry = geometry
        self.simulation = simulation
