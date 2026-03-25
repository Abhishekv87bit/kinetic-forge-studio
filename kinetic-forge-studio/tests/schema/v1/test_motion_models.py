import pytest
from pydantic import ValidationError

from backend.kfs_manifest.schema.v1.motion_models import (
    ConstantMotion,
    PeriodicMotion,
    LimitConstraint,
    GearConstraint,
    KinematicChain,
    MotionConstraint,
    MotionModel,
)


def test_constant_motion_valid_data():
    """Tests ConstantMotion with valid data."""
    motion = ConstantMotion(speed=10.5)
    assert motion.type == "constant"
    assert motion.speed == 10.5


def test_constant_motion_missing_speed():
    """Tests ConstantMotion with missing speed, expecting ValidationError."""
    with pytest.raises(ValidationError):
        ConstantMotion()


def test_constant_motion_invalid_speed_type():
    """Tests ConstantMotion with invalid speed type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        ConstantMotion(speed="not_a_float")


def test_periodic_motion_valid_data():
    """Tests PeriodicMotion with valid data."""
    motion = PeriodicMotion(amplitude=5.0, frequency=0.5, offset=0.1)
    assert motion.type == "periodic"
    assert motion.amplitude == 5.0
    assert motion.frequency == 0.5
    assert motion.offset == 0.1


def test_periodic_motion_valid_data_default_offset():
    """Tests PeriodicMotion with valid data and default offset."""
    motion = PeriodicMotion(amplitude=5.0, frequency=0.5)
    assert motion.type == "periodic"
    assert motion.amplitude == 5.0
    assert motion.frequency == 0.5
    assert motion.offset == 0.0  # Default value


def test_periodic_motion_missing_amplitude():
    """Tests PeriodicMotion with missing amplitude, expecting ValidationError."""
    with pytest.raises(ValidationError):
        PeriodicMotion(frequency=0.5)


def test_periodic_motion_missing_frequency():
    """Tests PeriodicMotion with missing frequency, expecting ValidationError."""
    with pytest.raises(ValidationError):
        PeriodicMotion(amplitude=5.0)


def test_periodic_motion_invalid_amplitude_type():
    """Tests PeriodicMotion with invalid amplitude type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        PeriodicMotion(amplitude="invalid", frequency=0.5)


def test_periodic_motion_invalid_frequency_type():
    """Tests PeriodicMotion with invalid frequency type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        PeriodicMotion(amplitude=5.0, frequency="invalid")


def test_periodic_motion_invalid_offset_type():
    """Tests PeriodicMotion with invalid offset type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        PeriodicMotion(amplitude=5.0, frequency=0.5, offset="invalid")


def test_limit_constraint_valid_data():
    """Tests LimitConstraint with valid data."""
    constraint = LimitConstraint(min_value=0.0, max_value=10.0)
    assert constraint.type == "limit"
    assert constraint.min_value == 0.0
    assert constraint.max_value == 10.0


def test_limit_constraint_missing_min_value():
    """Tests LimitConstraint with missing min_value, expecting ValidationError."""
    with pytest.raises(ValidationError):
        LimitConstraint(max_value=10.0)


def test_limit_constraint_missing_max_value():
    """Tests LimitConstraint with missing max_value, expecting ValidationError."""
    with pytest.raises(ValidationError):
        LimitConstraint(min_value=0.0)


def test_limit_constraint_invalid_value_type():
    """Tests LimitConstraint with invalid value type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        LimitConstraint(min_value="zero", max_value=10.0)
    with pytest.raises(ValidationError):
        LimitConstraint(min_value=0.0, max_value="ten")


def test_gear_constraint_valid_data():
    """Tests GearConstraint with valid data."""
    constraint = GearConstraint(ratio=2.5)
    assert constraint.type == "gear"
    assert constraint.ratio == 2.5


def test_gear_constraint_missing_ratio():
    """Tests GearConstraint with missing ratio, expecting ValidationError."""
    with pytest.raises(ValidationError):
        GearConstraint()


def test_gear_constraint_invalid_ratio_type():
    """Tests GearConstraint with invalid ratio type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        GearConstraint(ratio="two_point_five")


def test_kinematic_chain_valid_data():
    """Tests KinematicChain with valid data (elements only)."""
    chain = KinematicChain(elements=["joint_a", "joint_b"])
    assert chain.type == "kinematic_chain"
    assert chain.elements == ["joint_a", "joint_b"]
    assert chain.constraints == []


def test_kinematic_chain_valid_data_with_constraints():
    """Tests KinematicChain with valid data including constraints."""
    constraints_data = [
        {"type": "limit", "min_value": 0.0, "max_value": 1.0},
        {"type": "gear", "ratio": 3.0},
    ]
    chain = KinematicChain(elements=["joint_c"], constraints=constraints_data)
    assert chain.type == "kinematic_chain"
    assert chain.elements == ["joint_c"]
    assert len(chain.constraints) == 2
    assert isinstance(chain.constraints[0], LimitConstraint)
    assert chain.constraints[0].min_value == 0.0
    assert isinstance(chain.constraints[1], GearConstraint)
    assert chain.constraints[1].ratio == 3.0


def test_kinematic_chain_missing_elements():
    """Tests KinematicChain with missing elements, expecting ValidationError."""
    with pytest.raises(ValidationError):
        KinematicChain()


def test_kinematic_chain_empty_elements():
    """Tests KinematicChain with empty elements list, expecting ValidationError."""
    with pytest.raises(ValidationError):
        KinematicChain(elements=[])


def test_kinematic_chain_invalid_elements_type():
    """Tests KinematicChain with invalid elements type, expecting ValidationError."""
    with pytest.raises(ValidationError):
        KinematicChain(elements="not_a_list")
    with pytest.raises(ValidationError):
        KinematicChain(elements=[1, 2]) # Elements must be strings


def test_kinematic_chain_invalid_constraint_data():
    """Tests KinematicChain with invalid constraint data, expecting ValidationError."""
    invalid_constraints = [
        {"type": "limit", "min_value": "bad", "max_value": 1.0} # Invalid type
    ]
    with pytest.raises(ValidationError):
        KinematicChain(elements=["joint_d"], constraints=invalid_constraints)

    invalid_constraints_no_type = [
        {"min_value": 0.0, "max_value": 1.0} # Missing type
    ]
    with pytest.raises(ValidationError):
        KinematicChain(elements=["joint_e"], constraints=invalid_constraints_no_type)


def test_motion_model_union_constant_motion():
    """Tests MotionModel union with ConstantMotion data."""
    data = {"type": "constant", "speed": 15.0}
    motion = MotionModel.model_validate(data)
    assert isinstance(motion, ConstantMotion)
    assert motion.speed == 15.0


def test_motion_model_union_periodic_motion():
    """Tests MotionModel union with PeriodicMotion data."""
    data = {"type": "periodic", "amplitude": 8.0, "frequency": 1.2}
    motion = MotionModel.model_validate(data)
    assert isinstance(motion, PeriodicMotion)
    assert motion.amplitude == 8.0
    assert motion.frequency == 1.2


def test_motion_model_union_kinematic_chain():
    """Tests MotionModel union with KinematicChain data."""
    data = {
        "type": "kinematic_chain",
        "elements": ["link1", "link2"],
        "constraints": [
            {"type": "limit", "min_value": -5.0, "max_value": 5.0}
        ]
    }
    motion = MotionModel.model_validate(data)
    assert isinstance(motion, KinematicChain)
    assert motion.elements == ["link1", "link2"]
    assert len(motion.constraints) == 1
    assert isinstance(motion.constraints[0], LimitConstraint)


def test_motion_model_union_invalid_type():
    """Tests MotionModel union with an invalid type, expecting ValidationError."""
    data = {"type": "unknown_motion", "value": 10}
    with pytest.raises(ValidationError):
        MotionModel.model_validate(data)


def test_motion_constraint_union_limit_constraint():
    """Tests MotionConstraint union with LimitConstraint data."""
    data = {"type": "limit", "min_value": 0.0, "max_value": 360.0}
    constraint = MotionConstraint.model_validate(data)
    assert isinstance(constraint, LimitConstraint)
    assert constraint.min_value == 0.0
    assert constraint.max_value == 360.0


def test_motion_constraint_union_gear_constraint():
    """Tests MotionConstraint union with GearConstraint data."""
    data = {"type": "gear", "ratio": 4.0}
    constraint = MotionConstraint.model_validate(data)
    assert isinstance(constraint, GearConstraint)
    assert constraint.ratio == 4.0


def test_motion_constraint_union_invalid_type():
    """Tests MotionConstraint union with an invalid type, expecting ValidationError."""
    data = {"type": "unknown_constraint", "param": 1}
    with pytest.raises(ValidationError):
        MotionConstraint.model_validate(data)

