from enum import Enum
from typing import Optional, List

from pydantic import BaseModel, Field, model_validator

class JointType(str, Enum):
    """Enum for common joint types."""
    REVOLUTE = "revolute"
    PRISMATIC = "prismatic"
    FIXED = "fixed"
    SPHERICAL = "spherical"
    PLANAR = "planar"
    CONTINUOUS = "continuous"  # A revolute joint with no position limits

class JointLimits(BaseModel):
    """Defines the operational limits for a joint's motion."""
    lower: Optional[float] = Field(None, description="Lower position/angle limit for the joint. (radians for revolute, meters for prismatic)")
    upper: Optional[float] = Field(None, description="Upper position/angle limit for the joint. (radians for revolute, meters for prismatic)")
    velocity: Optional[float] = Field(None, gt=0, description="Maximum velocity limit for the joint. (rad/s or m/s)")
    effort: Optional[float] = Field(None, gt=0, description="Maximum effort (torque or force) limit for the joint. (Nm or N)")

    @model_validator(mode="after")
    def validate_limits_order(self) -> "JointLimits":
        if self.lower is not None and self.upper is not None and self.lower > self.upper:
            raise ValueError("Lower limit cannot be greater than upper limit.")
        return self

class JointDynamics(BaseModel):
    """Defines dynamic properties for a joint, often used in simulation."""
    damping: float = Field(0.0, ge=0, description="Damping coefficient for the joint.")
    friction: float = Field(0.0, ge=0, description="Friction coefficient for the joint.")

class Joint(BaseModel):
    """Represents a single joint connecting two links in a kinematic system."""
    name: str = Field(..., description="Unique identifier for the joint.")
    type: JointType = Field(..., description="The type of the joint, e.g., revolute, prismatic, fixed.")
    parent: str = Field(..., description="Name of the parent link the joint is attached to.")
    child: str = Field(..., description="Name of the child link the joint is attached to.")
    
    # Origin and axis define the joint's pose and direction relative to the parent link
    origin: Optional[List[float]] = Field(
        None, min_length=6, max_length=6,
        description="The origin of the joint relative to the parent link's origin, specified as [x, y, z, roll, pitch, yaw]. (meters, radians)"
    )
    axis: Optional[List[float]] = Field(
        None, min_length=3, max_length=3,
        description="The axis of motion (rotation or translation) for the joint, specified as a 3D vector [x, y, z] in the joint frame."
    )
    
    limits: Optional[JointLimits] = Field(None, description="Operational limits for the joint, including position/angle, velocity, and effort.")
    dynamics: Optional[JointDynamics] = Field(None, description="Dynamic properties of the joint, such as damping and friction.")

    @model_validator(mode="after")
    def validate_joint_configuration(self) -> "Joint":
        # Validate fields based on joint type
        if self.type in [JointType.REVOLUTE, JointType.PRISMATIC, JointType.CONTINUOUS]:
            if self.axis is None:
                raise ValueError(f"Joint type '{self.type.value}' requires an 'axis'.")
            if self.origin is None:
                raise ValueError(f"Joint type '{self.type.value}' requires an 'origin'.")
        elif self.type == JointType.FIXED:
            if self.limits is not None:
                raise ValueError(f"Fixed joint cannot have 'limits'.")
            if self.dynamics is not None:
                raise ValueError(f"Fixed joint cannot have 'dynamics'.")
            if self.axis is not None:
                raise ValueError(f"Fixed joint cannot have an 'axis'.")
            # Origin is allowed for fixed joints to define the child's pose relative to parent.
        elif self.type in [JointType.SPHERICAL, JointType.PLANAR]:
            if self.axis is not None:
                raise ValueError(f"Joint type '{self.type.value}' cannot have an 'axis'.")
            if self.origin is None:
                raise ValueError(f"Joint type '{self.type.value}' requires an 'origin'.")
            if self.limits is not None:
                 raise ValueError(f"Joint type '{self.type.value}' cannot have generic 'limits' (multi-DOF joints require specific limit definitions).")

        # Specific validation for continuous joints
        if self.type == JointType.CONTINUOUS:
            if self.limits and (self.limits.lower is not None or self.limits.upper is not None):
                raise ValueError(f"Continuous joint cannot have 'lower' or 'upper' limits. Only 'velocity' and 'effort' limits are allowed.")
        
        return self

class MotionParameters(BaseModel):
    """Top-level model for defining motion parameters of a kinematic system."""
    joints: List[Joint] = Field(..., description="A list of joints defining the kinematic structure and motion properties.")
