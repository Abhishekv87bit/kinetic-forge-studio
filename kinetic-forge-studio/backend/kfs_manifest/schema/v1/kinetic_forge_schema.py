from typing import List, Literal, Optional, Union, Annotated
from enum import Enum
from pydantic import BaseModel, BeforeValidator, Field, model_validator


# --- Enums ---

class GeometryType(str, Enum):
    MESH = "mesh"
    PRIMITIVE = "primitive"


class Units(str, Enum):
    MM = "mm"
    CM = "cm"
    M = "m"
    IN = "in"


class AssetType(str, Enum):
    ARBITRARY_DATA = "arbitrary_data"
    MESH = "mesh"


class MotionProfile(str, Enum):
    LINEAR = "linear"
    SINE = "sine"
    EASE_IN_OUT = "ease_in_out"


# --- Geometry Models ---

class MeshGeometry(BaseModel):
    type: GeometryType = GeometryType.MESH
    source: str = Field(..., description="URI to the mesh file.")
    units: Units = Field(Units.MM, description="Units of the geometry.")


class Geometry(BaseModel):
    type: GeometryType = GeometryType.MESH
    source: str = Field(..., description="URI to the geometry source.")
    units: Units = Field(Units.MM, description="Units.")


# --- Motion Models ---

class RotationMotion(BaseModel):
    type: str = "rotation"
    axis: List[float] = Field(..., description="Axis of rotation.")
    origin: List[float] = Field(default_factory=lambda: [0, 0, 0], description="Origin of rotation.")
    duration_seconds: float = Field(..., ge=0, description="Duration in seconds.")
    profile: MotionProfile = Field(MotionProfile.LINEAR, description="Motion profile.")


class TranslationMotion(BaseModel):
    type: str = "translation"
    direction: List[float] = Field(..., description="Direction of translation.")
    distance_mm: float = Field(..., description="Distance in mm.")
    duration_seconds: float = Field(..., ge=0, description="Duration in seconds.")
    profile: MotionProfile = Field(MotionProfile.LINEAR, description="Motion profile.")


Motion = Union[RotationMotion, TranslationMotion]


# --- Asset Models ---

class ArbitraryDataAsset(BaseModel):
    type: AssetType = AssetType.ARBITRARY_DATA
    source: str = Field(..., description="URI to the asset.")
    hash: Optional[str] = Field(None, description="Hash of the asset.")


Asset = Union[ArbitraryDataAsset]


# --- Metadata ---

class Metadata(BaseModel):
    name: str = Field(..., description="Name of the system.")
    description: Optional[str] = Field(None, description="Description of the system.")


# --- Component Models ---

class StaticGeometryComponent(BaseModel):
    name: str = Field(..., description="Component name.")
    type: Literal["static_geometry"] = Field(..., description="Component type.")
    description: Optional[str] = None
    geometry: MeshGeometry = Field(..., description="Geometry definition.")


class KineticGeometryComponent(BaseModel):
    name: str = Field(..., description="Component name.")
    type: Literal["kinetic_geometry"] = Field(..., description="Component type.")
    description: Optional[str] = None
    geometry: MeshGeometry = Field(..., description="Geometry definition.")
    motion: Union[RotationMotion, TranslationMotion] = Field(..., description="Motion definition.")


class AssetComponent(BaseModel):
    name: str = Field(..., description="Component name.")
    type: Literal["asset"] = Field(..., description="Component type.")
    description: Optional[str] = None
    asset: ArbitraryDataAsset = Field(..., description="Asset definition.")


def _check_component_type(value):
    """Pre-validator that ensures 'type' field is present on component dicts."""
    if isinstance(value, dict) and "type" not in value:
        from pydantic_core import PydanticCustomError
        raise PydanticCustomError("missing", "Field required")
    return value


Component = Annotated[
    Union[StaticGeometryComponent, KineticGeometryComponent, AssetComponent],
    Field(discriminator="type"),
    BeforeValidator(_check_component_type),
]


# --- Top-level Manifest ---

class KineticForgeManifest(BaseModel):
    kfs_schema_version: str = Field(..., description="Schema version.")
    metadata: Metadata = Field(..., description="Manifest metadata.")
    components: List[Component] = Field(default_factory=list, description="List of components.")

    @model_validator(mode="before")
    @classmethod
    def check_duplicate_component_names(cls, values):
        if isinstance(values, dict):
            components = values.get("components", [])
            if isinstance(components, list):
                seen = set()
                for comp in components:
                    if isinstance(comp, dict):
                        name = comp.get("name")
                        if name and name in seen:
                            raise ValueError(f"Duplicate component name '{name}' found")
                        if name:
                            seen.add(name)
        return values


# Alias for API routes compatibility
KineticForgeSchema = KineticForgeManifest
