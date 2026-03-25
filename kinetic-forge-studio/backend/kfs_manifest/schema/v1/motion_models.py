from enum import Enum
from typing import List, Optional, Tuple

from pydantic import BaseModel, Field, model_validator


class JointType(str, Enum):
    """Enumeration of standard joint types."""
    REVOLUTE = "revolute"
    PRISMATIC = "prismatic"
    CONTINUOUS = "continuous"
    FIXED = "fixed"
    FLOATING = "floating"
    PLANAR = "planar"


class Vector3(BaseModel):
    """Represents a 3D vector (x, y, z)."""
    xyz: Tuple[float, float, float] = Field((0.0, 0.0, 0.0), description="x, y, z components of the vector.")

    @model_validator(mode="before")
    def validate_xyz_input(cls, values):
        # Allows passing a list/tuple directly for xyz
        if isinstance(values, (list, tuple)) and len(values) == 3:
            return {"xyz": tuple(values)}
        elif isinstance(values, dict) and "xyz" in values:
            if isinstance(values["xyz"], (list, tuple)) and len(values["xyz"]) == 3:
                return {"xyz": tuple(values["xyz"]) }
        return values


class RPY(BaseModel):
    """Represents Roll, Pitch, Yaw angles."""
    rpy: Tuple[float, float, float] = Field((0.0, 0.0, 0.0), description="Roll, Pitch, Yaw angles in radians.")

    @model_validator(mode="before")
    def validate_rpy_input(cls, values):
        # Allows passing a list/tuple directly for rpy
        if isinstance(values, (list, tuple)) and len(values) == 3:
            return {"rpy": tuple(values)}
        elif isinstance(values, dict) and "rpy" in values:
            if isinstance(values["rpy"], (list, tuple)) and len(values["rpy"]) == 3:
                return {"rpy": tuple(values["rpy"]) }
        return values


class OriginModel(BaseModel):
    """
    Represents the origin of a joint or link frame relative to its parent frame.
    Default is an identity transform (zero position and orientation).
    """
    xyz: Vector3 = Field(default_factory=Vector3, description="Position (x, y, z) relative to the parent frame.")
    rpy: RPY = Field(default_factory=RPY, description="Orientation (roll, pitch, yaw) relative to the parent frame.")


class AxisModel(BaseModel):
    """
    Represents the axis of motion for a joint. The vector must not be (0,0,0).
    """
    xyz: Vector3 = Field(..., description="A 3D vector defining the axis of rotation or translation.")

    @model_validator(mode="after")
    def check_non_zero_vector(self):
        x, y, z = self.xyz.xyz
        if x == 0.0 and y == 0.0 and z == 0.0:
            raise ValueError("Axis vector (xyz) cannot be (0, 0, 0).")
        return self


class JointLimitsModel(BaseModel):
    """
    Defines the physical limits of a joint. Applicable to revolute and prismatic joints.
    """
    lower: Optional[float] = Field(None, description="Lower joint limit (rad for revolute, m for prismatic).")
    upper: Optional[float] = Field(None, description="Upper joint limit (rad for revolute, m for prismatic).")
    velocity: float = Field(..., gt=0, description="Maximum joint velocity (rad/s or m/s). Must be positive.")
    effort: float = Field(..., gt=0, description="Maximum joint effort/torque (Nm or N). Must be positive.")

    @model_validator(mode="after")
    def check_limits_order(self):
        if self.lower is not None and self.upper is not None and self.lower > self.upper:
            raise ValueError("Joint lower limit cannot be greater than the upper limit.")
        return self


class JointDynamicsModel(BaseModel):
    """
    Defines the dynamic properties of a joint, such as friction and damping.
    """
    friction: float = Field(0.0, ge=0, description="Friction value (Nm or Ns/m). Must be non-negative.")
    damping: float = Field(0.0, ge=0, description="Damping value (Nm/s or Ns/m). Must be non-negative.")


class JointMimicModel(BaseModel):
    """
    Defines a joint that mimics the motion of another joint.
    """
    joint: str = Field(..., description="The name of the joint to mimic.")
    multiplier: float = Field(1.0, description="A scaling factor applied to the mimicked joint's position.")
    offset: float = Field(0.0, description="An offset added to the mimicked joint's position.")


class JointModel(BaseModel):
    """
    Represents a single joint, connecting two links within a kinetic system.
    """
    name: str = Field(..., description="The unique name of the joint.")
    type: JointType = Field(..., description="The type of the joint (e.g., revolute, prismatic, fixed).")
    parent_link: str = Field(..., description="The name of the parent link.")
    child_link: str = Field(..., description="The name of the child link.")
    origin: Optional[OriginModel] = Field(None, description="The transform of the joint frame relative to the parent link frame.")
    axis: Optional[AxisModel] = Field(None, description="The axis of motion for revolute, prismatic, and continuous joints.")
    limits: Optional[JointLimitsModel] = Field(None, description="Physical limits for revolute and prismatic joints.")
    dynamics: Optional[JointDynamicsModel] = Field(None, description="Dynamic properties of the joint (friction, damping).")
    mimic: Optional[JointMimicModel] = Field(None, description="If this joint mimics another joint.")

    @model_validator(mode="after")
    def validate_joint_type_specific_fields(self):
        """
        Validates fields based on joint type rules:
        - Fixed joints cannot have axis, limits, dynamics, or mimic.
        - Revolute, Prismatic, Continuous require an axis.
        - Revolute, Prismatic require limits.
        """
        if self.type == JointType.FIXED:
            if self.axis:
                raise ValueError("Fixed joint cannot have an 'axis'.")
            if self.limits:
                raise ValueError("Fixed joint cannot have 'limits'.")
            if self.dynamics:
                raise ValueError("Fixed joint cannot have 'dynamics'.")
            if self.mimic:
                raise ValueError("Fixed joint cannot have 'mimic'.")
        elif self.type in {JointType.REVOLUTE, JointType.PRISMATIC, JointType.CONTINUOUS}:
            if not self.axis:
                raise ValueError(f"{self.type.value} joint requires an 'axis'.")

        if self.type in {JointType.REVOLUTE, JointType.PRISMATIC}:
            if not self.limits:
                raise ValueError(f"{self.type.value} joint requires 'limits'.")

        return self
