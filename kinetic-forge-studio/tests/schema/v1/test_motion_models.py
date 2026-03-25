import pytest
from pydantic import ValidationError

from backend.kfs_manifest.schema.v1.motion_models import (
    TimeDuration,
    JointState,
    CartesianPoint,
    KinematicMotion,
    DynamicMotion,
    Motion,
    MotionType
)

# Test TimeDuration
def test_time_duration_valid():
    td = TimeDuration(duration=10.5)
    assert td.duration == 10.5
    td_zero = TimeDuration(duration=0.0)
    assert td_zero.duration == 0.0

def test_time_duration_invalid_negative():
    with pytest.raises(ValidationError):
        TimeDuration(duration=-1.0)

def test_time_duration_invalid_type():
    with pytest.raises(ValidationError):
        TimeDuration(duration="ten")

def test_time_duration_missing():
    with pytest.raises(ValidationError):
        TimeDuration()

# Test JointState
def test_joint_state_valid():
    js = JointState(joint_angles=[0.1, 0.2, 0.3])
    assert js.joint_angles == [0.1, 0.2, 0.3]
    js_single = JointState(joint_angles=[1.5])
    assert js_single.joint_angles == [1.5]

def test_joint_state_invalid_empty_list():
    with pytest.raises(ValidationError):
        JointState(joint_angles=[])

def test_joint_state_invalid_non_list():
    with pytest.raises(ValidationError):
        JointState(joint_angles="not_a_list")

def test_joint_state_invalid_list_with_non_float():
    with pytest.raises(ValidationError):
        JointState(joint_angles=[0.1, "0.2", 0.3])

def test_joint_state_missing():
    with pytest.raises(ValidationError):
        JointState()

# Test CartesianPoint
def test_cartesian_point_valid():
    cp = CartesianPoint(x=1.0, y=2.0, z=3.0, qx=0.0, qy=0.0, qz=0.0, qw=1.0)
    assert cp.x == 1.0
    assert cp.y == 2.0
    assert cp.z == 3.0
    assert cp.qx == 0.0
    assert cp.qy == 0.0
    assert cp.qz == 0.0
    assert cp.qw == 1.0

def test_cartesian_point_invalid_missing_field():
    with pytest.raises(ValidationError):
        CartesianPoint(x=1.0, y=2.0, z=3.0, qx=0.0, qy=0.0, qz=0.0) # Missing qw

def test_cartesian_point_invalid_type():
    with pytest.raises(ValidationError):
        CartesianPoint(x="one", y=2.0, z=3.0, qx=0.0, qy=0.0, qz=0.0, qw=1.0)

# Test KinematicMotion
def test_kinematic_motion_valid():
    km = KinematicMotion(
        duration=5.0,
        target_joint_state={"joint_angles": [0.1, 0.2]}
    )
    assert km.duration == 5.0
    assert km.type == MotionType.KINEMATIC
    assert km.target_joint_state.joint_angles == [0.1, 0.2]

def test_kinematic_motion_invalid_duration():
    with pytest.raises(ValidationError):
        KinematicMotion(
            duration=-5.0,
            target_joint_state={"joint_angles": [0.1, 0.2]}
        )

def test_kinematic_motion_invalid_joint_state():
    with pytest.raises(ValidationError):
        KinematicMotion(
            duration=5.0,
            target_joint_state={"joint_angles": []} # Invalid JointState
        )

def test_kinematic_motion_invalid_type_field():
    with pytest.raises(ValidationError):
        KinematicMotion(
            duration=5.0,
            type="wrong_type", # Should be MotionType.KINEMATIC
            target_joint_state={"joint_angles": [0.1, 0.2]}
        )

def test_kinematic_motion_missing_fields():
    with pytest.raises(ValidationError):
        KinematicMotion(duration=5.0) # Missing target_joint_state

# Test DynamicMotion
def test_dynamic_motion_valid():
    dm = DynamicMotion(
        duration=7.5,
        target_cartesian_point={"x": 1.0, "y": 2.0, "z": 3.0, "qx": 0.0, "qy": 0.0, "qz": 0.0, "qw": 1.0},
        max_velocity=1.5
    )
    assert dm.duration == 7.5
    assert dm.type == MotionType.DYNAMIC
    assert dm.max_velocity == 1.5
    assert dm.target_cartesian_point.x == 1.0

def test_dynamic_motion_default_max_velocity():
    dm = DynamicMotion(
        duration=7.5,
        target_cartesian_point={"x": 1.0, "y": 2.0, "z": 3.0, "qx": 0.0, "qy": 0.0, "qz": 0.0, "qw": 1.0}
    )
    assert dm.max_velocity == 0.0 # Assuming 0.0 is the default

def test_dynamic_motion_invalid_max_velocity_negative():
    with pytest.raises(ValidationError):
        DynamicMotion(
            duration=7.5,
            target_cartesian_point={"x": 1.0, "y": 2.0, "z": 3.0, "qx": 0.0, "qy": 0.0, "qz": 0.0, "qw": 1.0},
            max_velocity=-1.0
        )

def test_dynamic_motion_invalid_cartesian_point():
    with pytest.raises(ValidationError):
        DynamicMotion(
            duration=7.5,
            target_cartesian_point={"x": 1.0, "y": 2.0, "z": 3.0, "qx": 0.0, "qy": 0.0, "qz": 0.0}, # Missing qw
            max_velocity=1.0
        )

# Test Motion (Union model)
def test_motion_with_kinematic_profile_valid():
    motion = Motion(
        name="approach_joint",
        motion_profile={
            "type": "kinematic",
            "duration": 2.0,
            "target_joint_state": {"joint_angles": [0.1, 0.2, 0.3, 0.4]}
        }
    )
    assert motion.name == "approach_joint"
    assert isinstance(motion.motion_profile, KinematicMotion)
    assert motion.motion_profile.duration == 2.0
    assert motion.motion_profile.target_joint_state.joint_angles == [0.1, 0.2, 0.3, 0.4]

def test_motion_with_dynamic_profile_valid():
    motion = Motion(
        name="move_cartesian",
        motion_profile={
            "type": "dynamic",
            "duration": 3.0,
            "target_cartesian_point": {"x": 1.0, "y": 2.0, "z": 3.0, "qx": 0.0, "qy": 0.0, "qz": 0.0, "qw": 1.0},
            "max_velocity": 0.5
        }
    )
    assert motion.name == "move_cartesian"
    assert isinstance(motion.motion_profile, DynamicMotion)
    assert motion.motion_profile.duration == 3.0
    assert motion.motion_profile.max_velocity == 0.5

def test_motion_invalid_missing_name():
    with pytest.raises(ValidationError):
        Motion(
            motion_profile={
                "type": "kinematic",
                "duration": 2.0,
                "target_joint_state": {"joint_angles": [0.1]}
            }
        )

def test_motion_invalid_profile_type():
    with pytest.raises(ValidationError):
        Motion(
            name="bad_motion",
            motion_profile={
                "type": "unsupported_type", # Neither kinematic nor dynamic
                "duration": 2.0,
                "target_joint_state": {"joint_angles": [0.1]}
            }
        )

def test_motion_invalid_profile_data():
    with pytest.raises(ValidationError):
        Motion(
            name="bad_data",
            motion_profile={
                "type": "kinematic",
                "duration": -2.0, # Invalid duration
                "target_joint_state": {"joint_angles": [0.1]}
            }
        )