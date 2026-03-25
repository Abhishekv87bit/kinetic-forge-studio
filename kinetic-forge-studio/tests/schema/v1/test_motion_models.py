import pytest
from pydantic import ValidationError
from backend.kfs_manifest.schema.v1.motion_models import (
    CartesianVector,
    SphericalVector,
    CylindricalVector,
    AxisRange,
    MotionConstraint,
    JointConfig,
    MotionConfig,
    KinematicJointType,
)


def test_cartesian_vector_valid_data():
    """Test CartesianVector with valid data."""
    vec = CartesianVector(x=1.0, y=2.0, z=3.0)
    assert vec.x == 1.0
    assert vec.y == 2.0
    assert vec.z == 3.0

def test_cartesian_vector_defaults():
    """Test CartesianVector with default values."""
    vec = CartesianVector()
    assert vec.x == 0.0
    assert vec.y == 0.0
    assert vec.z == 0.0

def test_cartesian_vector_invalid_type():
    """Test CartesianVector with invalid data types."""
    with pytest.raises(ValidationError):
        CartesianVector(x="not_a_float", y=2.0, z=3.0)
    with pytest.raises(ValidationError):
        CartesianVector(x=1, y="not_a_float", z=3.0)


def test_spherical_vector_valid_data():
    """Test SphericalVector with valid data."""
    vec = SphericalVector(radial=10.0, polar=0.5, azimuthal=1.5)
    assert vec.radial == 10.0
    assert vec.polar == 0.5
    assert vec.azimuthal == 1.5

def test_spherical_vector_defaults():
    """Test SphericalVector with default values."""
    vec = SphericalVector()
    assert vec.radial == 0.0
    assert vec.polar == 0.0
    assert vec.azimuthal == 0.0

def test_spherical_vector_invalid_type():
    """Test SphericalVector with invalid data types."""
    with pytest.raises(ValidationError):
        SphericalVector(radial="not_a_float", polar=0.5, azimuthal=1.5)

def test_spherical_vector_polar_range_validation():
    """Test SphericalVector polar angle range validation."""
    with pytest.raises(ValidationError):
        SphericalVector(radial=1.0, polar=-0.1, azimuthal=0.0) # Below 0
    with pytest.raises(ValidationError):
        SphericalVector(radial=1.0, polar=3.14159265359 + 0.1, azimuthal=0.0) # Above pi
    SphericalVector(radial=1.0, polar=0.0, azimuthal=0.0) # Valid
    SphericalVector(radial=1.0, polar=3.14159265359, azimuthal=0.0) # Valid

def test_spherical_vector_azimuthal_range_validation():
    """Test SphericalVector azimuthal angle range validation."""
    with pytest.raises(ValidationError):
        SphericalVector(radial=1.0, polar=0.0, azimuthal=-0.1) # Below 0
    with pytest.raises(ValidationError):
        SphericalVector(radial=1.0, polar=0.0, azimuthal=6.28318530718 + 0.1) # Above 2*pi
    SphericalVector(radial=1.0, polar=0.0, azimuthal=0.0) # Valid
    SphericalVector(radial=1.0, polar=0.0, azimuthal=6.28318530718) # Valid


def test_cylindrical_vector_valid_data():
    """Test CylindricalVector with valid data."""
    vec = CylindricalVector(radial=5.0, angle=1.0, z=2.0)
    assert vec.radial == 5.0
    assert vec.angle == 1.0
    assert vec.z == 2.0

def test_cylindrical_vector_defaults():
    """Test CylindricalVector with default values."""
    vec = CylindricalVector()
    assert vec.radial == 0.0
    assert vec.angle == 0.0
    assert vec.z == 0.0

def test_cylindrical_vector_invalid_type():
    """Test CylindricalVector with invalid data types."""
    with pytest.raises(ValidationError):
        CylindricalVector(radial="not_a_float", angle=1.0, z=2.0)

def test_cylindrical_vector_angle_range_validation():
    """Test CylindricalVector angle range validation."""
    with pytest.raises(ValidationError):
        CylindricalVector(radial=1.0, angle=-0.1, z=0.0) # Below 0
    with pytest.raises(ValidationError):
        CylindricalVector(radial=1.0, angle=6.28318530718 + 0.1, z=0.0) # Above 2*pi
    CylindricalVector(radial=1.0, angle=0.0, z=0.0) # Valid
    CylindricalVector(radial=1.0, angle=6.28318530718, z=0.0) # Valid


def test_axis_range_valid_data():
    """Test AxisRange with valid data."""
    ar = AxisRange(min=-10.0, max=10.0)
    assert ar.min == -10.0
    assert ar.max == 10.0

def test_axis_range_defaults():
    """Test AxisRange with default values."""
    ar = AxisRange()
    assert ar.min == 0.0
    assert ar.max == 0.0

def test_axis_range_invalid_type():
    """Test AxisRange with invalid data types."""
    with pytest.raises(ValidationError):
        AxisRange(min="not_a_float", max=10.0)

def test_axis_range_min_greater_than_max():
    """Test AxisRange validation where min > max."""
    with pytest.raises(ValidationError, match="'min' must be less than or equal to 'max'"):
        AxisRange(min=10.0, max=5.0)


def test_motion_constraint_valid_data():
    """Test MotionConstraint with valid data."""
    constraint = MotionConstraint(velocity=1.0, acceleration=0.5)
    assert constraint.velocity == 1.0
    assert constraint.acceleration == 0.5

def test_motion_constraint_defaults():
    """Test MotionConstraint with default values."""
    constraint = MotionConstraint()
    assert constraint.velocity is None
    assert constraint.acceleration is None

def test_motion_constraint_invalid_type():
    """Test MotionConstraint with invalid data types."""
    with pytest.raises(ValidationError):
        MotionConstraint(velocity="not_a_float")

def test_motion_constraint_negative_values():
    """Test MotionConstraint with negative velocity or acceleration."""
    with pytest.raises(ValidationError, match="'velocity' must be non-negative"):
        MotionConstraint(velocity=-1.0)
    with pytest.raises(ValidationError, match="'acceleration' must be non-negative"):
        MotionConstraint(acceleration=-0.5)


def test_joint_config_valid_data():
    """Test JointConfig with valid data."""
    joint = JointConfig(
        name="rotary_joint_1",
        type=KinematicJointType.REVOLUTE,
        axis=CartesianVector(x=1.0),
        range=AxisRange(min=0.0, max=3.14),
        constraints=MotionConstraint(velocity=10.0),
        description="A simple rotary joint"
    )
    assert joint.name == "rotary_joint_1"
    assert joint.type == KinematicJointType.REVOLUTE
    assert joint.axis.x == 1.0
    assert joint.range.min == 0.0
    assert joint.constraints.velocity == 10.0
    assert joint.description == "A simple rotary joint"

def test_joint_config_required_fields():
    """Test JointConfig for missing required fields."""
    with pytest.raises(ValidationError):
        JointConfig(type=KinematicJointType.REVOLUTE, axis=CartesianVector(x=1.0))
    with pytest.raises(ValidationError):
        JointConfig(name="joint1", axis=CartesianVector(x=1.0))
    with pytest.raises(ValidationError):
        JointConfig(name="joint1", type=KinematicJointType.REVOLUTE)

def test_joint_config_invalid_type():
    """Test JointConfig with invalid data types for nested models."""
    with pytest.raises(ValidationError):
        JointConfig(name="joint1", type="INVALID_TYPE", axis=CartesianVector(x=1.0))
    with pytest.raises(ValidationError):
        JointConfig(name="joint1", type=KinematicJointType.REVOLUTE, axis={"x": "not_a_float"})
    with pytest.raises(ValidationError):
        JointConfig(name="joint1", type=KinematicJointType.REVOLUTE, axis=CartesianVector(x=1.0),
                    range={"min": "not_a_float"})


def test_motion_config_valid_data():
    """Test MotionConfig with valid data."""
    motion_config = MotionConfig(
        joints=[
            JointConfig(name="joint_a", type=KinematicJointType.PRISMATIC, axis=CartesianVector(z=1.0), range=AxisRange(min=0, max=10)),
            JointConfig(name="joint_b", type=KinematicJointType.REVOLUTE, axis=CartesianVector(x=1.0), constraints=MotionConstraint(acceleration=5.0))
        ],
        description="A simple two-joint motion system"
    )
    assert len(motion_config.joints) == 2
    assert motion_config.joints[0].name == "joint_a"
    assert motion_config.joints[1].type == KinematicJointType.REVOLUTE
    assert motion_config.description == "A simple two-joint motion system"

def test_motion_config_empty_joints():
    """Test MotionConfig with an empty list of joints."""
    motion_config = MotionConfig(joints=[])
    assert len(motion_config.joints) == 0

def test_motion_config_invalid_joint_entry():
    """Test MotionConfig with an invalid entry in the joints list."""
    with pytest.raises(ValidationError):
        MotionConfig(joints=[
            {"name": "invalid_joint", "type": "UNKNOWN"} # Invalid type for KinematicJointType
        ])
    with pytest.raises(ValidationError):
        MotionConfig(joints=[
            JointConfig(name="joint_a", type=KinematicJointType.PRISMATIC, axis=CartesianVector(z=1.0)),
            {"name": "joint_b", "type": "REVOLUTE", "axis": {"x": "bad"}} # Invalid axis value
        ])



def test_motion_config_no_description():
    """Test MotionConfig with no description provided."""
    motion_config = MotionConfig(
        joints=[
            JointConfig(name="joint_a", type=KinematicJointType.PRISMATIC, axis=CartesianVector(z=1.0), range=AxisRange(min=0, max=10)),
        ]
    )
    assert motion_config.description is None
