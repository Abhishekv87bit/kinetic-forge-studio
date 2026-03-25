from typing import List, Literal, Union, Optional, Dict, Any
from pydantic import BaseModel, Field, conlist, constr, NonNegativeFloat, confloat, root_validator

from kfs_core.constants import KFS_MANIFEST_VERSION

# --- 1. Geometry Models ---

class RGBColor(BaseModel):
    """Represents an RGB color with values from 0-255."""
    r: conint(ge=0, le=255) = Field(..., description="Red component (0-255)")
    g: conint(ge=0, le=255) = Field(..., description="Green component (0-255)")
    b: conint(ge=0, le=255) = Field(..., description="Blue component (0-255)")

    def to_hex(self) -> str:
        """Converts the RGB color to a hexadecimal string."""
        return f"#{self.r:02x}{self.g:02x}{self.b:02x}"


class BaseGeometry(BaseModel):
    """Base class for all KFS geometry types."""
    id: constr(min_length=1, max_length=64) = Field(..., description="Unique identifier for this geometry definition")

    class Config:
        extra = "forbid"
        # This makes it an abstract base for discriminated unions
        # by setting an underscore prefix which Pydantic uses internally
        # for base models in unions when discriminator is used.
        # Or, just ensure it's not instantiated directly.
        allow_population_by_field_name = True
        json_schema_extra = {
            "examples": [
                {"type": "sphere", "id": "sphere01", "radius": 1.5},
                {"type": "cube", "id": "cube01", "size": 2.0},
                {"type": "mesh", "id": "mesh01", "path": "assets/model.obj"}
            ]
        }


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


# Union type for all geometry types
Geometry = Union[SphereGeometry, CubeGeometry, CylinderGeometry, MeshGeometry]

# --- 2. Material Models ---

class Material(BaseModel):
    """Defines a material with color and physical properties."""
    id: constr(min_length=1, max_length=64) = Field(..., description="Unique identifier for this material definition")
    color: RGBColor = Field(RGBColor(r=128, g=128, b=128), description="Base color of the material")
    roughness: confloat(ge=0.0, le=1.0) = Field(0.5, description="Roughness of the material (0.0=smooth, 1.0=rough)")
    metallic: confloat(ge=0.0, le=1.0) = Field(0.0, description="Metallic property of the material (0.0=dielectric, 1.0=metallic)")

    class Config:
        extra = "forbid"
        json_schema_extra = {
            "examples": [
                {"id": "red_plastic", "color": {"r": 255, "g": 0, "b": 0}, "roughness": 0.2, "metallic": 0.0},
                {"id": "brushed_metal", "color": {"r": 180, "g": 180, "b": 190}, "roughness": 0.4, "metallic": 0.9}
            ]
        }


# --- 3. Motion Profile Models ---

class BaseMotionProfile(BaseModel):
    """Base class for all KFS motion profile types."""
    id: constr(min_length=1, max_length=64) = Field(..., description="Unique identifier for this motion profile")

    class Config:
        extra = "forbid"
        allow_population_by_field_name = True
        json_schema_extra = {
            "examples": [
                {"type": "keyframe", "id": "rotate_x", "keyframes": [{"time": 0, "rotation": [0,0,0]}, {"time": 10, "rotation": [90,0,0]}], "interpolation": "linear"},
                {"type": "parametric", "id": "sine_wave", "expression": "sin(t)", "parameters": {"amplitude": 1.0}}
            ]
        }


class Keyframe(BaseModel):
    """Represents a single keyframe in a keyframe motion profile."""
    time: NonNegativeFloat = Field(..., description="Time in seconds at which this keyframe occurs")
    position: Optional[conlist(float, min_items=3, max_items=3)] = Field(None, description="[x, y, z] position")
    rotation: Optional[conlist(float, min_items=3, max_items=3)] = Field(None, description="[pitch, yaw, roll] rotation in degrees")
    scale: Optional[conlist(float, min_items=3, max_items=3)] = Field(None, description="[sx, sy, sz] scale factors")

    class Config:
        extra = "forbid"


class KeyframeMotion(BaseMotionProfile):
    """Defines motion using a series of keyframes."""
    type: Literal["keyframe"] = Field("keyframe", description="Type of motion profile")
    keyframes: List[Keyframe] = Field(..., description="List of keyframes defining the motion")
    interpolation: Literal["linear", "spline"] = Field("linear", description="Interpolation method between keyframes")


class ParametricMotion(BaseMotionProfile):
    """Defines motion using a mathematical expression."""
    type: Literal["parametric"] = Field("parametric", description="Type of motion profile")
    expression: constr(min_length=1) = Field(..., description="Mathematical expression defining the motion over time (e.g., 'A * sin(t + phi)')")
    parameters: Optional[Dict[constr(min_length=1), float]] = Field(None, description="Parameters used in the expression (e.g., {'A': 1.0, 'phi': 0.0})")
    # Optionally, specify which transform property the expression applies to
    target_property: Literal["position.x", "position.y", "position.z",
                             "rotation.pitch", "rotation.yaw", "rotation.roll",
                             "scale.x", "scale.y", "scale.z"] = Field("position.y", description="The target property this expression controls")


class ProceduralMotion(BaseMotionProfile):
    """References an external script for procedural motion generation."""
    type: Literal["procedural"] = Field("procedural", description="Type of motion profile")
    script_path: constr(min_length=1) = Field(..., description="Path to the Python script or executable for procedural motion")
    config: Optional[Dict[str, Any]] = Field(None, description="Configuration parameters passed to the procedural script")


# Union type for all motion profile types
MotionProfile = Union[KeyframeMotion, ParametricMotion, ProceduralMotion]

# --- 4. Component Model ---

class SculptureComponent(BaseModel):
    """Represents a single kinetic sculpture component, combining geometry, material, and optional motion."""
    id: constr(min_length=1, max_length=64) = Field(..., description="Unique identifier for this component")
    geometry_id: constr(min_length=1, max_length=64) = Field(..., description="ID of the geometry definition to use for this component")
    material_id: constr(min_length=1, max_length=64) = Field(..., description="ID of the material definition to use for this component")
    motion_profile_id: Optional[constr(min_length=1, max_length=64)] = Field(None, description="ID of the motion profile to apply to this component")
    initial_position: Optional[conlist(float, min_items=3, max_items=3)] = Field([0.0, 0.0, 0.0], description="Initial [x, y, z] position of the component")
    initial_rotation: Optional[conlist(float, min_items=3, max_items=3)] = Field([0.0, 0.0, 0.0], description="Initial [pitch, yaw, roll] rotation in degrees")
    initial_scale: Optional[conlist(float, min_items=3, max_items=3)] = Field([1.0, 1.0, 1.0], description="Initial [sx, sy, sz] scale factors")
    parent_id: Optional[constr(min_length=1, max_length=64)] = Field(None, description="ID of a parent component for hierarchical transformations")

    class Config:
        extra = "forbid"
        json_schema_extra = {
            "examples": [
                {"id": "base_sphere", "geometry_id": "sphere01", "material_id": "red_plastic"},
                {"id": "moving_cube", "geometry_id": "cube01", "material_id": "brushed_metal", "motion_profile_id": "rotate_x", "parent_id": "base_sphere"}
            ]
        }


# --- 5. Top-level Sculpture Definition ---

class KFSManifest(BaseModel):
    """The top-level Pydantic model for a KFS manifest file."""
    kfs_version: constr(min_length=1) = Field(KFS_MANIFEST_VERSION, description="Version of the KFS manifest schema")
    name: constr(min_length=1, max_length=128) = Field(..., description="Name of the kinetic sculpture project")
    description: Optional[constr(max_length=512)] = Field(None, description="A brief description of the sculpture")

    # Collections of definitions
    geometries: Dict[str, Geometry] = Field(default_factory=dict, description="Dictionary of geometry definitions, keyed by ID")
    materials: Dict[str, Material] = Field(default_factory=dict, description="Dictionary of material definitions, keyed by ID")
    motion_profiles: Dict[str, MotionProfile] = Field(default_factory=dict, description="Dictionary of motion profile definitions, keyed by ID")

    # The actual components that form the sculpture
    components: List[SculptureComponent] = Field(..., description="List of sculpture components")

    simulation_settings: Optional[Dict[str, Any]] = Field(None, description="Optional simulation specific settings")
    render_settings: Optional[Dict[str, Any]] = Field(None, description="Optional render specific settings")

    class Config:
        extra = "forbid"
        json_schema_extra = {
            "examples": [
                {
                    "kfs_version": "1.0.0",
                    "name": "Example Kinetic Sculpture",
                    "description": "A simple sculpture demonstrating sphere and cube components.",
                    "geometries": {
                        "sphere01": {"type": "sphere", "id": "sphere01", "radius": 1.0},
                        "cube01": {"type": "cube", "id": "cube01", "size": 0.5}
                    },
                    "materials": {
                        "red": {"id": "red", "color": {"r": 255, "g": 0, "b": 0}, "roughness": 0.3},
                        "blue": {"id": "blue", "color": {"r": 0, "g": 0, "b": 255}, "roughness": 0.7}
                    },
                    "motion_profiles": {
                        "spin_fast": {"type": "keyframe", "id": "spin_fast", "keyframes": [{"time": 0, "rotation": [0,0,0]}, {"time": 5, "rotation": [360,0,0]}], "interpolation": "linear"}
                    },
                    "components": [
                        {
                            "id": "main_body",
                            "geometry_id": "sphere01",
                            "material_id": "red",
                            "initial_position": [0, 0, 0],
                            "motion_profile_id": "spin_fast"
                        },
                        {
                            "id": "arm",
                            "geometry_id": "cube01",
                            "material_id": "blue",
                            "initial_position": [0, 1.5, 0],
                            "parent_id": "main_body"
                        }
                    ],
                    "simulation_settings": {"gravity": [0, -9.8, 0]},
                    "render_settings": {"resolution": [1920, 1080]}
                }
            ]
        }

    @root_validator(pre=False, skip_on_failure=True)
    def validate_component_references(cls, values):
        """Validate that component references (geometry, material, motion) exist in the definitions."""
        geometries = values.get('geometries', {})
        materials = values.get('materials', {})
        motion_profiles = values.get('motion_profiles', {})
        components = values.get('components', [])

        component_ids = {c.id for c in components}

        for component in components:
            # Validate geometry_id
            if component.geometry_id not in geometries:
                raise ValueError(f"Component '{component.id}' references unknown geometry ID '{component.geometry_id}'")

            # Validate material_id
            if component.material_id not in materials:
                raise ValueError(f"Component '{component.id}' references unknown material ID '{component.material_id}'")

            # Validate motion_profile_id if present
            if component.motion_profile_id and component.motion_profile_id not in motion_profiles:
                raise ValueError(f"Component '{component.id}' references unknown motion profile ID '{component.motion_profile_id}'")

            # Validate parent_id if present
            if component.parent_id and component.parent_id not in component_ids:
                raise ValueError(f"Component '{component.id}' references unknown parent ID '{component.parent_id}'")

        return values

from pydantic import conint
