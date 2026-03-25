from typing import Optional, Union, Literal
from pydantic import BaseModel, Field


class Vector3D(BaseModel):
    """A 3D vector representing coordinates or an axis direction."""
    x: float = Field(..., description="The X component of the vector.")
    y: float = Field(..., description="The Y component of the vector.")
    z: float = Field(..., description="The Z component of the vector.")


class Origin(BaseModel):
    """Represents the origin (position and orientation) of a kinematic element."""
    xyz: Vector3D = Field(Vector3D(x=0.0, y=0.0, z=0.0), description="Position of the origin relative to the parent frame.")
    rpy: Vector3D = Field(Vector3D(x=0.0, y=0.0, z=0.0), description="Roll, Pitch, Yaw orientation of the origin (in radians) relative to the parent frame.")


class Axis(BaseModel):
    """Represents the axis of rotation or translation for a joint."""
    xyz: Vector3D = Field(Vector3D(x=0.0, y=0.0, z=0.0), description="The vector defining the axis direction.")


class JointLimit(BaseModel):
    """Defines the physical limits of a joint."""
    lower: Optional[float] = Field(None, description="The lower joint limit (in meters or radians).")
    upper: Optional[float] = Field(None, description="The upper joint limit (in meters or radians).")
    velocity: Optional[float] = Field(None, description="The maximum joint velocity (in m/s or rad/s).")
    effort: Optional[float] = Field(None, description="The maximum joint effort (in N or N*m).")


class BaseJoint(BaseModel):
    """Base class for all joint types, defining common properties."""
    name: str = Field(..., description="Unique name of the joint.")
    parent: str = Field(..., description="Name of the parent link.")
    child: str = Field(..., description="Name of the child link.")
    origin: Origin = Field(Origin(), description="Origin of the joint relative to the parent link.")
    type: Literal['revolute', 'prismatic', 'fixed'] = Field(..., description="Type of the joint.")

    class Config:
        extra = "forbid"


class RevoluteJoint(BaseJoint):
    """A revolute joint allows rotation around a single axis."""
    type: Literal['revolute'] = Field('revolute', description="Specifies the joint type as revolute.")
    axis: Axis = Field(Axis(xyz=Vector3D(x=1.0, y=0.0, z=0.0)), description="Axis of rotation.")
    limit: Optional[JointLimit] = Field(None, description="Rotational limits for the joint.")


class PrismaticJoint(BaseJoint):
    """A prismatic joint allows translation along a single axis."""
    type: Literal['prismatic'] = Field('prismatic', description="Specifies the joint type as prismatic.")
    axis: Axis = Field(Axis(xyz=Vector3D(x=1.0, y=0.0, z=0.0)), description="Axis of translation.")
    limit: Optional[JointLimit] = Field(None, description="Translational limits for the joint.")


class FixedJoint(BaseJoint):
    """A fixed joint completely restricts motion between two links."""
    type: Literal['fixed'] = Field('fixed', description="Specifies the joint type as fixed.")


Joint = Union[RevoluteJoint, PrismaticJoint, FixedJoint]
