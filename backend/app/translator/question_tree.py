"""
YAML-driven question tree for guided specification.

Given a list of unknown fields from the classifier, returns the most
important question to ask next. Each question has multiple-choice options
with impact explanations to help the user make informed decisions.
"""

from pathlib import Path
from typing import Any

import yaml


_QUESTIONS_DIR = Path(__file__).resolve().parent.parent.parent / "data" / "questions"


class Question:
    """A single question loaded from YAML."""

    def __init__(self, data: dict):
        self.field: str = data["field"]
        self.priority: int = data.get("priority", 99)
        self.question: str = data["question"]
        self.options: list[dict] = data.get("options", [])
        self.default: Any = data.get("default")
        self.allow_custom: bool = data.get("allow_custom", False)
        self.custom_prompt: str = data.get("custom_prompt", "")

    def to_dict(self) -> dict:
        result = {
            "field": self.field,
            "priority": self.priority,
            "question": self.question,
            "options": self.options,
            "default": self.default,
        }
        if self.allow_custom:
            result["allow_custom"] = True
            result["custom_prompt"] = self.custom_prompt
        return result


class QuestionTree:
    """
    Loads YAML question files and selects the next question to ask
    based on a list of unknown fields.
    """

    def __init__(self, questions_dir: Path | None = None):
        self.questions_dir = questions_dir or _QUESTIONS_DIR
        self._questions: dict[str, Question] = {}
        self._load_questions()

    def _load_questions(self):
        """Load all YAML question files from the questions directory."""
        if not self.questions_dir.exists():
            return
        for yaml_file in self.questions_dir.glob("*.yaml"):
            with open(yaml_file, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
            if data and "field" in data:
                self._questions[data["field"]] = Question(data)

    @property
    def available_fields(self) -> list[str]:
        """List of fields that have questions defined."""
        return list(self._questions.keys())

    def get_question(self, field: str) -> Question | None:
        """Get the question for a specific field."""
        return self._questions.get(field)

    def next_question(self, unknowns: list[str]) -> Question | None:
        """
        Given a list of unknown fields, return the highest-priority question.

        Returns None if no questions match the unknowns list.
        Priority: lower number = asked first.
        """
        candidates = []
        for field in unknowns:
            q = self._questions.get(field)
            if q is not None:
                candidates.append(q)

        if not candidates:
            return None

        # Sort by priority (lowest first)
        candidates.sort(key=lambda q: q.priority)
        return candidates[0]

    def all_questions_for(self, unknowns: list[str]) -> list[Question]:
        """
        Return all questions matching the unknowns list, sorted by priority.
        """
        candidates = []
        for field in unknowns:
            q = self._questions.get(field)
            if q is not None:
                candidates.append(q)
        candidates.sort(key=lambda q: q.priority)
        return candidates

    def apply_answer(self, field: str, value: Any, fields: dict) -> dict:
        """
        Apply a user's answer to the fields dict.

        If the question has allow_custom and value is a string that looks
        numeric, convert it. Otherwise store as-is.
        """
        q = self._questions.get(field)
        if q and q.allow_custom:
            try:
                value = float(value)
                if value == int(value):
                    value = int(value)
            except (ValueError, TypeError):
                pass

        fields[field] = value
        return fields
