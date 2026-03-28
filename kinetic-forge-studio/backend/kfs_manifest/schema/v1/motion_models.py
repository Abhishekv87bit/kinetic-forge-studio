from enum import Enum
from typing import List, Literal, Optional, Union, Annotated
from pydantic import BaseModel, Field, StrictFloat, StrictInt, field_validator, model_validator


class MotionType(str, Enum):
    """Enumeration of motion types."""
    KINEMATIC = "kinematic"
    DYNAMIC = "dynamic"


class TimeDuration(BaseModel):
    """Represents a time duration (must be non-negative)."""
    duration: float = Field(..., ge=0, description="Duration in seconds.")


class JointState(BaseModel):
    """Represents a joint state as a list of joint angles."""
    joint_angles: List[Union[StrictFloat, StrictInt]] = Field(..., min_length=1, description="List of joint angles in radians.")


class CartesianPoint(BaseModel):
    """Represents a point in Cartesian space with orientation as quaternion."""
    x: float = Field(..., description="X coordinate.")
    y: float = Field(..., description="Y coordinate.")
    z: float = Field(..., description="Z coordinate.")
    qx: float = Field(..., description="Quaternion X component.")
    qy: float = Field(..., description="Quaternion Y component.")
    qz: float = Field(..., description="Quaternion Z component.")
    qw: float = Field(..., description="Quaternion W component.")


class KinematicMotion(BaseModel):
    """Defines a kinematic motion profile targeting a joint state."""
    type: Literal["kinematic"] = Field("kinematic", description="Motion type.")
    duration: float = Field(..., ge=0, description="Duration in seconds.")
    target_joint_state: JointState = Field(..., description="Target joint state.")


class DynamicMotion(BaseModel):
    """Defines a dynamic motion profile targeting a Cartesian point."""
    type: Literal["dynamic"] = Field("dynamic", description="Motion type.")
    duration: float = Field(..., ge=0, description="Duration in seconds.")
    target_cartesian_point: CartesianPoint = Field(..., description="Target Cartesian point.")
    max_velocity: float = Field(0.0, ge=0, description="Maximum velocity.")


class Motion(BaseModel):
    """Represents a named motion with a profile (kinematic or dynamic)."""
    name: str = Field(..., description="Name of the motion.")
    motion_profile: Annotated[
        Union[KinematicMotion, DynamicMotion],
        Field(discriminator="type"),
    ] = Field(..., description="The motion profile definition.")
