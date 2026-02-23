"""Tests for the keyword classifier."""

import pytest
from app.translator.classifier import KeywordClassifier, ClassificationResult


@pytest.fixture
def classifier():
    return KeywordClassifier()


def test_planetary_gear_full_spec(classifier):
    """'compact planetary gear 3 planets 70mm' should extract multiple fields."""
    result = classifier.classify("compact planetary gear 3 planets 70mm")
    assert result.fields["mechanism_type"] == "planetary"
    assert result.fields["planet_count"] == 3
    assert result.fields["envelope_mm"] == 70.0
    assert "mechanism_type" in result.confidence
    assert result.confidence["mechanism_type"] > 0.0


def test_wave_sculpture_wood(classifier):
    """'breathing wave sculpture wood' should extract mechanism, material, feeling."""
    result = classifier.classify("breathing wave sculpture wood")
    assert result.fields["mechanism_type"] == "wave"
    assert result.fields["material"] == "wood"
    assert "breathing" in result.feelings


def test_four_bar_linkage(classifier):
    """'four-bar linkage with oscillating motion' should detect four_bar + oscillation."""
    result = classifier.classify("four-bar linkage with oscillating motion")
    assert result.fields["mechanism_type"] == "four_bar"
    assert result.fields["motion_type"] == "oscillation"


def test_geneva_drive(classifier):
    """'geneva drive intermittent indexing mechanism' should detect geneva."""
    result = classifier.classify("geneva drive intermittent indexing mechanism")
    assert result.fields["mechanism_type"] == "geneva"


def test_numeric_size_mm(classifier):
    """Numeric mm extraction."""
    result = classifier.classify("make a gear box 120mm")
    assert result.fields["envelope_mm"] == 120.0
    assert result.confidence["envelope_mm"] == 0.9


def test_numeric_size_cm(classifier):
    """Numeric cm extraction with multiplier."""
    result = classifier.classify("a 15cm tall sculpture")
    assert result.fields["envelope_mm"] == 150.0


def test_size_word_compact(classifier):
    """Size word 'compact' maps to ~70mm."""
    result = classifier.classify("compact gear mechanism")
    assert result.fields["envelope_mm"] == 70
    assert result.fields["size_category"] == "compact"
    assert result.confidence["envelope_mm"] == 0.5  # word-based = lower confidence


def test_material_metal(classifier):
    """Material extraction for metal."""
    result = classifier.classify("I want a brass gear train CNC machined")
    assert result.fields["material"] == "metal"


def test_material_pla(classifier):
    """Material extraction for PLA/3D print."""
    result = classifier.classify("3d printed planetary gearbox in PLA")
    assert result.fields["material"] == "PLA"
    assert result.fields["mechanism_type"] == "planetary"


def test_teeth_extraction(classifier):
    """Extract tooth count."""
    result = classifier.classify("ring gear with 48 teeth")
    assert result.fields["teeth"] == 48


def test_gear_module_extraction(classifier):
    """Extract gear module."""
    result = classifier.classify("module 1.5 spur gear")
    assert result.fields["gear_module"] == 1.5


def test_motor_count_single(classifier):
    """'single motor' should map to motor_count=1."""
    result = classifier.classify("single motor driven wave sculpture")
    assert result.fields["motor_count"] == 1


def test_motor_count_numeric(classifier):
    """'2 motors' should map to motor_count=2."""
    result = classifier.classify("driven by 2 motors")
    assert result.fields["motor_count"] == 2


def test_rpm_extraction(classifier):
    """Extract RPM."""
    result = classifier.classify("running at 60 rpm")
    assert result.fields["speed_rpm"] == 60


def test_feelings_multiple(classifier):
    """Multiple feeling descriptors."""
    result = classifier.classify("elegant flowing organic sculpture")
    assert "elegant" in result.feelings
    assert "organic" in result.feelings
    assert "flowing" in result.feelings


def test_unknowns_list(classifier):
    """When fields are missing, they appear in unknowns."""
    result = classifier.classify("something vague")
    assert "mechanism_type" in result.unknowns
    assert "material" in result.unknowns
    assert "envelope_mm" in result.unknowns
    assert "motor_count" in result.unknowns


def test_unknowns_reduced_when_found(classifier):
    """Found fields should NOT be in unknowns."""
    result = classifier.classify("planetary gear 70mm PLA single motor")
    assert "mechanism_type" not in result.unknowns
    assert "envelope_mm" not in result.unknowns
    assert "material" not in result.unknowns
    assert "motor_count" not in result.unknowns
    assert len(result.unknowns) == 0


def test_to_dict(classifier):
    """Result should serialize to dict."""
    result = classifier.classify("wave sculpture wood")
    d = result.to_dict()
    assert "fields" in d
    assert "confidence" in d
    assert "unknowns" in d
    assert "feelings" in d
    assert "raw_input" in d
    assert d["raw_input"] == "wave sculpture wood"


def test_scotch_yoke(classifier):
    """Scotch yoke detection."""
    result = classifier.classify("scotch yoke mechanism for reciprocating motion")
    assert result.fields["mechanism_type"] == "scotch_yoke"


def test_cam_mechanism(classifier):
    """Cam mechanism detection."""
    result = classifier.classify("cam follower with eccentric profile")
    assert result.fields["mechanism_type"] == "cam"


def test_empty_input(classifier):
    """Empty input should return all unknowns."""
    result = classifier.classify("")
    assert len(result.unknowns) == len(classifier.classify("").unknowns)
    assert len(result.fields) == 0
    assert len(result.feelings) == 0
