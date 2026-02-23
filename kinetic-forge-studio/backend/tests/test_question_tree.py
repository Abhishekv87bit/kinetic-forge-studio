"""Tests for the YAML question tree."""

import pytest
from pathlib import Path
from app.translator.question_tree import QuestionTree, Question


@pytest.fixture
def tree():
    """Load question tree from the default questions directory."""
    return QuestionTree()


def test_questions_loaded(tree):
    """Verify that YAML question files are loaded."""
    assert len(tree.available_fields) > 0
    assert "mechanism_type" in tree.available_fields
    assert "material" in tree.available_fields
    assert "envelope_mm" in tree.available_fields
    assert "motor_count" in tree.available_fields


def test_get_question_mechanism_type(tree):
    """Get a specific question by field name."""
    q = tree.get_question("mechanism_type")
    assert q is not None
    assert q.field == "mechanism_type"
    assert len(q.options) > 0
    assert q.priority == 1


def test_get_question_material(tree):
    """Material question has expected options."""
    q = tree.get_question("material")
    assert q is not None
    values = [opt["value"] for opt in q.options]
    assert "PLA" in values
    assert "wood" in values
    assert "metal" in values


def test_get_question_nonexistent(tree):
    """Nonexistent field returns None."""
    q = tree.get_question("nonexistent_field_xyz")
    assert q is None


def test_next_question_priority(tree):
    """Next question should be the highest-priority one from unknowns."""
    # mechanism_type has priority 1, material has priority 2
    q = tree.next_question(["material", "mechanism_type"])
    assert q is not None
    assert q.field == "mechanism_type"


def test_next_question_single_unknown(tree):
    """Single unknown returns that question."""
    q = tree.next_question(["motor_count"])
    assert q is not None
    assert q.field == "motor_count"


def test_next_question_no_match(tree):
    """No matching unknowns returns None."""
    q = tree.next_question(["some_unknown_field", "another_thing"])
    assert q is None


def test_next_question_empty_unknowns(tree):
    """Empty unknowns list returns None."""
    q = tree.next_question([])
    assert q is None


def test_all_questions_for(tree):
    """Get all questions sorted by priority."""
    unknowns = ["motor_count", "envelope_mm", "mechanism_type", "material"]
    questions = tree.all_questions_for(unknowns)
    assert len(questions) >= 4
    # Verify sorted by priority
    for i in range(len(questions) - 1):
        assert questions[i].priority <= questions[i + 1].priority


def test_question_to_dict(tree):
    """Question serialization."""
    q = tree.get_question("mechanism_type")
    d = q.to_dict()
    assert "field" in d
    assert "question" in d
    assert "options" in d
    assert "default" in d
    assert d["field"] == "mechanism_type"


def test_question_options_have_impact(tree):
    """Each option should have a value, label, and impact."""
    q = tree.get_question("mechanism_type")
    for opt in q.options:
        assert "value" in opt
        assert "label" in opt
        assert "impact" in opt


def test_envelope_allows_custom(tree):
    """Envelope question should support custom input."""
    q = tree.get_question("envelope_mm")
    assert q.allow_custom is True
    assert len(q.custom_prompt) > 0


def test_apply_answer_basic(tree):
    """Apply a simple answer to fields dict."""
    fields = {}
    result = tree.apply_answer("mechanism_type", "planetary", fields)
    assert result["mechanism_type"] == "planetary"


def test_apply_answer_custom_numeric(tree):
    """Apply a custom numeric answer (string that looks like a number)."""
    fields = {}
    result = tree.apply_answer("envelope_mm", "125", fields)
    assert result["envelope_mm"] == 125  # converted to int


def test_apply_answer_custom_float(tree):
    """Apply a custom float answer."""
    fields = {}
    result = tree.apply_answer("envelope_mm", "125.5", fields)
    assert result["envelope_mm"] == 125.5


def test_custom_questions_dir(tmp_path):
    """Test with a custom questions directory."""
    # Write a test question YAML
    q_file = tmp_path / "test_field.yaml"
    q_file.write_text(
        "field: test_field\n"
        "priority: 1\n"
        "question: What is the test?\n"
        "options:\n"
        "  - value: a\n"
        "    label: Option A\n"
        "    impact: Impact A\n"
        "default: a\n"
    )
    tree = QuestionTree(questions_dir=tmp_path)
    assert "test_field" in tree.available_fields
    q = tree.get_question("test_field")
    assert q.question == "What is the test?"


def test_empty_questions_dir(tmp_path):
    """Empty directory should produce no questions."""
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    tree = QuestionTree(questions_dir=empty_dir)
    assert len(tree.available_fields) == 0
    assert tree.next_question(["mechanism_type"]) is None
