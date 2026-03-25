from typing import Literal, Union, List, Optional
from pydantic import BaseModel, Field, conlist

# Import asset models for referencing meshes
# The problem statement indicates `asset_models.py` was previously completed.
# Assuming it contains a MeshAsset model.
from .asset_models import MeshAsset # If HeightmapAsset or a more generic Asset model exists, we might use that instead.

# --- Common Types ---
class Vector2D(BaseModel):
    """Represents a 2D vector or dimension."""
    x: float = Field(..., description="The X component.")
    y: float = Field(..., description="The Y component.")

class Vector3D(BaseModel):
    """Represents a 3D vector or dimension."""
    x: float = Field(..., description="The X component.")
    y: float = Field(..., description="The Y component.")
    z: float = Field(..., description="The Z component.")

class Pose(BaseModel):
    """Represents the position and orientation of an object."""
    position: Optional[Vector3D] = Field(None, description="Position vector relative to the parent frame.", examples=[{"x": 0.0, "y": 0.0, "z": 0.0}])
    orientation: Optional[Vector3D] = Field(None, description="Orientation as Euler angles (roll, pitch, yaw) in radians, relative to the parent frame.", examples=[{"x": 0.0, "y": 0.0, "z": 0.0}])
    # Future: Could add quaternion representation.

# --- Geometry Primitives ---

class BoxGeometry(BaseModel):
    """Defines a box (cuboid) primitive geometry."""
    type: Literal["box"] = "box"
    size: Vector3D = Field(..., description="Dimensions of the box (width, depth, height).", examples=[{"x": 1.0, "y": 1.0, "z": 1.0}])

class SphereGeometry(BaseModel):
    """Defines a sphere primitive geometry."""
    type: Literal["sphere"] = "sphere"
    radius: float = Field(..., gt=0, description="Radius of the sphere.", examples=[0.5])

class CylinderGeometry(BaseModel):
    """Defines a cylinder primitive geometry."""
    type: Literal["cylinder"] = "cylinder"
    radius: float = Field(..., gt=0, description="Radius of the cylinder.", examples=[0.25])
    length: float = Field(..., gt=0, description="Length of the cylinder along its axis.", examples=[1.0])

class PlaneGeometry(BaseModel):
    """Defines a plane primitive geometry."""
    type: Literal["plane"] = "plane"
    size: Vector2D = Field(..., description="Dimensions of the plane (width, depth).", examples=[{"x": 10.0, "y": 10.0}])
    thickness: float = Field(0.01, gt=0, description="Effective thickness of the plane, e.g., for collision detection.", examples=[0.01])

class CapsuleGeometry(BaseModel):
    """Defines a capsule primitive geometry."""
    type: Literal["capsule"] = "capsule"
    radius: float = Field(..., gt=0, description="Radius of the capsule's spherical ends.", examples=[0.1])
    length: float = Field(..., gt=0, description="Length of the cylindrical part of the capsule (excluding the spherical caps).", examples=[0.8])

class ConeGeometry(BaseModel):
    """Defines a cone primitive geometry."""
    type: Literal["cone"] = "cone"
    radius: float = Field(..., gt=0, description="Radius of the cone's base.", examples=[0.3])
    length: float = Field(..., gt=0, description="Length of the cone from base to apex.", examples=[1.0])

# --- Mesh References ---

class MeshGeometry(BaseModel):
    """Defines a geometry based on a referenced mesh asset."""
    type: Literal["mesh"] = "mesh"
    asset: MeshAsset = Field(..., description="Reference to a mesh asset (e.g., glTF, OBJ, FBX).")
    scale: Optional[Vector3D] = Field(None, description="Uniform or non-uniform scaling applied to the mesh.", examples=[{"x": 1.0, "y": 1.0, "z": 1.0}])
    collision_type: Literal["none", "auto", "convex_hull", "trimesh", "bounding_box"] = Field(
        "auto", description="Type of collision geometry to generate for the mesh. 'auto' defers to system default."
    )

class HeightmapGeometry(BaseModel):
    """Defines a terrain geometry based on a referenced heightmap image asset."""
    type: Literal["heightmap"] = "heightmap"
    asset: MeshAsset = Field(..., description="Reference to a heightmap image asset (e.g., PNG, TIFF). Assumes MeshAsset can also represent image assets used for heightmaps, or a more specific ImageAsset would be defined in asset_models.py.")
    size: Vector2D = Field(..., description="World dimensions (width, depth) of the heightmap terrain.", examples=[{"x": 100.0, "y": 100.0}])
    height_range: Vector2D = Field(..., description="Minimum and maximum height values corresponding to the heightmap's grayscale range. (min_height, max_height).", examples=[{"x": 0.0, "y": 10.0}])
    resolution: Optional[int] = Field(None, gt=0, description="Optional downsampling resolution for the heightmap. If not provided, the original resolution is used.", examples=[256])

# --- Union Type for all Geometry Definitions ---

Geometry = Union[
    BoxGeometry,
    SphereGeometry,
    CylinderGeometry,
    PlaneGeometry,
    CapsuleGeometry,
    ConeGeometry,
    MeshGeometry,
    HeightmapGeometry,
]

# --- Component Structure ---

class Component(BaseModel):
    """
    Represents a generic component within the kinetic system,
    which can include visual geometry, collision geometry, and other properties.
    """
    id: str = Field(..., description="Unique identifier for the component within the manifest.")
    name: Optional[str] = Field(None, description="Human-readable name for the component.", examples=["Main Chassis", "Left Wheel"])
    geometry: Geometry = Field(..., description="The geometric definition of the component's visual or collision representation.")
    pose: Optional[Pose] = Field(None, description="Relative pose (position and orientation) of the component.", examples=[{"position": {"x": 0.0, "y": 0.0, "z": 0.5}}])
    # Future: Could add properties for material, physics, attachments, children components, etc.
