"""
Keyword classifier for kinetic sculpture design intent.

Parses natural-language user messages against a taxonomy of mechanism types,
motion types, materials, size indicators, and numerical parameters.
Returns a structured dict of extracted fields, confidence scores, and unknowns.
"""

import re
from pathlib import Path
from typing import Any

import yaml


_TAXONOMY_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "taxonomy.yaml"


def _load_taxonomy(path: Path | None = None) -> dict:
    """Load taxonomy YAML file."""
    p = path or _TAXONOMY_PATH
    with open(p, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


class ClassificationResult:
    """Structured result from keyword classification."""

    def __init__(self):
        self.fields: dict[str, Any] = {}
        self.confidence: dict[str, float] = {}
        self.unknowns: list[str] = []
        self.feelings: list[str] = []
        self.raw_input: str = ""

    def to_dict(self) -> dict:
        return {
            "fields": self.fields,
            "confidence": self.confidence,
            "unknowns": self.unknowns,
            "feelings": self.feelings,
            "raw_input": self.raw_input,
        }


# Fields that a complete spec should have
REQUIRED_FIELDS = [
    "mechanism_type",
    "material",
    "envelope_mm",
    "motor_count",
]


class KeywordClassifier:
    """Classify user messages into structured design parameters."""

    def __init__(self, taxonomy_path: Path | None = None):
        self.taxonomy = _load_taxonomy(taxonomy_path)

    def classify(self, text: str) -> ClassificationResult:
        """
        Parse a user message and extract design parameters.

        Returns a ClassificationResult with:
        - fields: dict of extracted parameter names to values
        - confidence: dict of parameter names to confidence (0.0 - 1.0)
        - unknowns: list of REQUIRED_FIELDS not found in the message
        - feelings: list of aesthetic/emotional descriptors found
        """
        result = ClassificationResult()
        result.raw_input = text
        text_lower = text.lower()

        # 1. Mechanism types
        self._extract_category(text_lower, "mechanism_types", "mechanism_type", result)

        # 2. Motion types
        self._extract_category(text_lower, "motion_types", "motion_type", result)

        # 3. Materials
        self._extract_category(text_lower, "materials", "material", result)

        # 4. Size indicators — numeric
        self._extract_numeric_size(text, text_lower, result)

        # 5. Size indicators — word-based (only if no numeric size found)
        if "envelope_mm" not in result.fields:
            self._extract_size_words(text_lower, result)

        # 6. Numerical parameters (planet_count, teeth, module, motor, rpm)
        self._extract_numerical_params(text, text_lower, result)

        # 7. Feelings/aesthetic descriptors
        self._extract_feelings(text_lower, result)

        # 8. Determine unknowns — fields we need but didn't find
        for field in REQUIRED_FIELDS:
            if field not in result.fields:
                result.unknowns.append(field)

        return result

    def _extract_category(
        self, text_lower: str, taxonomy_key: str, field_name: str,
        result: ClassificationResult
    ):
        """Extract a categorical field by keyword matching."""
        category_data = self.taxonomy.get(taxonomy_key, {})
        best_match = None
        best_score = 0
        match_count = 0

        for type_name, type_info in category_data.items():
            keywords = type_info.get("keywords", [])
            score = 0
            for kw in keywords:
                if kw.lower() in text_lower:
                    # Longer keywords get higher score (more specific)
                    score += len(kw)
                    match_count += 1

            if score > best_score:
                best_score = score
                best_match = type_name

        if best_match is not None:
            result.fields[field_name] = best_match
            # Confidence: based on keyword specificity (longer matches = higher)
            # Normalize: a single short keyword match ~ 0.5, multi-keyword ~ 0.9
            confidence = min(0.95, 0.4 + (best_score / 20.0))
            result.confidence[field_name] = round(confidence, 2)

    def _extract_numeric_size(
        self, text: str, text_lower: str, result: ClassificationResult
    ):
        """Extract numeric dimensions (e.g. '70mm', '10cm')."""
        patterns = self.taxonomy.get("size_indicators", {}).get("envelope_patterns", [])
        for pat_info in patterns:
            pattern = pat_info["pattern"]
            multiplier = pat_info.get("multiplier", 1)
            match = re.search(pattern, text_lower)
            if match:
                value = float(match.group(1)) * multiplier
                result.fields["envelope_mm"] = value
                result.confidence["envelope_mm"] = 0.9
                break

    def _extract_size_words(self, text_lower: str, result: ClassificationResult):
        """Extract size from descriptive words (compact, large, etc.)."""
        size_words = self.taxonomy.get("size_indicators", {}).get("size_words", {})
        for size_name, size_info in size_words.items():
            keywords = size_info.get("keywords", [])
            for kw in keywords:
                if kw.lower() in text_lower:
                    result.fields["envelope_mm"] = size_info["estimated_envelope_mm"]
                    result.fields["size_category"] = size_name
                    result.confidence["envelope_mm"] = 0.5  # word-based = lower confidence
                    return

    def _extract_numerical_params(
        self, text: str, text_lower: str, result: ClassificationResult
    ):
        """Extract numerical parameters (planet_count, teeth, module, etc.)."""
        num_params = self.taxonomy.get("numerical_parameters", {})

        for param_name, param_info in num_params.items():
            patterns = param_info.get("patterns", [])
            special_words = param_info.get("special_words", {})

            # Try regex patterns first
            found = False
            for pattern in patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    try:
                        value = float(match.group(1))
                        # Store as int if it's a whole number
                        if value == int(value):
                            value = int(value)
                        result.fields[param_name] = value
                        result.confidence[param_name] = 0.85
                        found = True
                        break
                    except (ValueError, IndexError):
                        pass

            # Try special words (e.g. "single motor" -> 1)
            if not found and special_words:
                for word, value in special_words.items():
                    if word.lower() in text_lower:
                        result.fields[param_name] = value
                        result.confidence[param_name] = 0.8
                        break

    def _extract_feelings(self, text_lower: str, result: ClassificationResult):
        """Extract aesthetic/emotional descriptors."""
        feeling_keywords = self.taxonomy.get("feelings", {}).get("keywords", [])
        for kw in feeling_keywords:
            if kw.lower() in text_lower:
                result.feelings.append(kw)
