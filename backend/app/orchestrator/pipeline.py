"""
Orchestrator pipeline for Kinetic Forge Studio.

Flow:
  1. Parse user message
  2. Classify intent (keyword classifier)
  3. Check for iterative feedback (bigger, smaller, more teeth, etc.)
  4. Merge extracted fields with existing spec
  5. Check for unknowns
  6. If unknowns remain, return a YAML-driven question
  7. If spec is complete, generate geometry and return response
  8. Optionally enhance with Claude API (if key is available)

The pipeline works WITHOUT the Claude API — classifier + question tree handle
the core loop. Claude is an optional enhancement for richer responses.
"""

import re
from dataclasses import dataclass, field
from typing import Any

from app.translator.classifier import KeywordClassifier, ClassificationResult
from app.translator.question_tree import QuestionTree


@dataclass
class PipelineResponse:
    """Response from the orchestrator pipeline."""
    message: str
    response_type: str  # "question", "generation", "info", "error"
    spec_updates: list[dict] = field(default_factory=list)
    question: dict | None = None
    geometry: dict | None = None
    classification: dict | None = None

    def to_dict(self) -> dict:
        result = {
            "message": self.message,
            "response_type": self.response_type,
            "spec_updates": self.spec_updates,
        }
        if self.question:
            result["question"] = self.question
        if self.geometry:
            result["geometry"] = self.geometry
        if self.classification:
            result["classification"] = self.classification
        return result


class Pipeline:
    """
    Main orchestrator pipeline.

    Maintains a running spec (accumulated fields from all messages)
    and uses the classifier + question tree to guide the conversation.
    """

    def __init__(
        self,
        classifier: KeywordClassifier | None = None,
        question_tree: QuestionTree | None = None,
    ):
        self.classifier = classifier or KeywordClassifier()
        self.question_tree = question_tree or QuestionTree()
        # Accumulated spec fields across conversation turns
        self.spec: dict[str, Any] = {}
        # History of user messages
        self.history: list[str] = []

    def process(self, user_message: str) -> PipelineResponse:
        """
        Process a user message through the full pipeline.

        Args:
            user_message: The raw text from the user.

        Returns:
            PipelineResponse with the assistant's response, spec updates, and
            optionally a question or geometry result.
        """
        self.history.append(user_message)

        # Step 1: Classify the message
        classification = self.classifier.classify(user_message)

        # Step 2: If spec is already complete, check for iterative feedback
        feedback_updates = []
        feedback_fields: set[str] = set()
        if not self._compute_unknowns():
            feedback_updates = self._apply_feedback(user_message)
            feedback_fields = {u["field"] for u in feedback_updates}

        # Step 3: Merge new fields into running spec (skip fields already adjusted by feedback)
        spec_updates = self._merge_fields(classification, skip_fields=feedback_fields)
        spec_updates.extend(feedback_updates)

        # Step 4: Add feelings to spec if any
        if classification.feelings:
            self.spec["feelings"] = list(set(
                self.spec.get("feelings", []) + classification.feelings
            ))

        # Step 5: Determine unknowns against running spec
        unknowns = self._compute_unknowns()

        # Step 6: Route based on unknowns
        if unknowns:
            return self._ask_question(unknowns, spec_updates, classification)
        else:
            return self._generate(spec_updates, classification)

    def _apply_feedback(self, text: str) -> list[dict]:
        """
        Detect relative feedback phrases and adjust the existing spec.

        Handles: bigger/smaller (envelope), more/fewer teeth, more/fewer planets,
        change material, change mechanism type, adjust motor count.
        Returns list of spec update dicts.
        """
        text_lower = text.lower()
        updates = []

        # Size adjustments: bigger/larger → scale up, smaller → scale down
        scale_up = re.search(r"\b(bigger|larger|increase size|scale up|grow)\b", text_lower)
        scale_down = re.search(r"\b(smaller|compact|decrease size|scale down|shrink)\b", text_lower)
        if scale_up and "envelope_mm" in self.spec:
            old = self.spec["envelope_mm"]
            self.spec["envelope_mm"] = round(float(old) * 1.3, 1)
            updates.append({"field": "envelope_mm", "value": self.spec["envelope_mm"],
                            "confidence": 0.8, "previous": old})
        elif scale_down and "envelope_mm" in self.spec:
            old = self.spec["envelope_mm"]
            self.spec["envelope_mm"] = round(float(old) * 0.7, 1)
            updates.append({"field": "envelope_mm", "value": self.spec["envelope_mm"],
                            "confidence": 0.8, "previous": old})

        # Teeth adjustments: more/fewer teeth
        more_teeth = re.search(r"\b(more teeth|add teeth|increase teeth)\b", text_lower)
        fewer_teeth = re.search(r"\b(fewer teeth|less teeth|reduce teeth|decrease teeth)\b", text_lower)
        if more_teeth:
            for key in ["ring_teeth", "sun_teeth"]:
                if key in self.spec:
                    old = self.spec[key]
                    self.spec[key] = int(old * 1.25)
                    updates.append({"field": key, "value": self.spec[key],
                                    "confidence": 0.75, "previous": old})
        elif fewer_teeth:
            for key in ["ring_teeth", "sun_teeth"]:
                if key in self.spec:
                    old = self.spec[key]
                    self.spec[key] = max(8, int(old * 0.8))
                    updates.append({"field": key, "value": self.spec[key],
                                    "confidence": 0.75, "previous": old})

        # Planet count adjustments
        more_planets = re.search(r"\b(more planets?|add planets?|increase planets?)\b", text_lower)
        fewer_planets = re.search(r"\b(fewer planets?|less planets?|reduce planets?|decrease planets?)\b", text_lower)
        if more_planets and "planet_count" in self.spec:
            old = self.spec["planet_count"]
            self.spec["planet_count"] = min(8, int(old) + 1)
            updates.append({"field": "planet_count", "value": self.spec["planet_count"],
                            "confidence": 0.85, "previous": old})
        elif fewer_planets and "planet_count" in self.spec:
            old = self.spec["planet_count"]
            self.spec["planet_count"] = max(2, int(old) - 1)
            updates.append({"field": "planet_count", "value": self.spec["planet_count"],
                            "confidence": 0.85, "previous": old})

        # Speed adjustments
        faster = re.search(r"\b(faster|speed up|quicker)\b", text_lower)
        slower = re.search(r"\b(slower|slow down|gentler)\b", text_lower)
        if faster and "rpm" in self.spec:
            old = self.spec["rpm"]
            self.spec["rpm"] = round(float(old) * 1.5, 1)
            updates.append({"field": "rpm", "value": self.spec["rpm"],
                            "confidence": 0.7, "previous": old})
        elif slower and "rpm" in self.spec:
            old = self.spec["rpm"]
            self.spec["rpm"] = round(float(old) * 0.67, 1)
            updates.append({"field": "rpm", "value": self.spec["rpm"],
                            "confidence": 0.7, "previous": old})

        # Height/thickness adjustments
        taller = re.search(r"\b(taller|thicker|increase height)\b", text_lower)
        shorter = re.search(r"\b(shorter|thinner|decrease height|flatten)\b", text_lower)
        if taller and "gear_height" in self.spec:
            old = self.spec["gear_height"]
            self.spec["gear_height"] = round(float(old) * 1.3, 1)
            updates.append({"field": "gear_height", "value": self.spec["gear_height"],
                            "confidence": 0.7, "previous": old})
        elif shorter and "gear_height" in self.spec:
            old = self.spec["gear_height"]
            self.spec["gear_height"] = round(float(old) * 0.7, 1)
            updates.append({"field": "gear_height", "value": self.spec["gear_height"],
                            "confidence": 0.7, "previous": old})

        return updates

    def _merge_fields(
        self,
        classification: ClassificationResult,
        skip_fields: set[str] | None = None,
    ) -> list[dict]:
        """Merge classified fields into the running spec. Return list of updates."""
        updates = []
        for key, value in classification.fields.items():
            if skip_fields and key in skip_fields:
                continue  # feedback already adjusted this field
            old_value = self.spec.get(key)
            if old_value != value:
                self.spec[key] = value
                updates.append({
                    "field": key,
                    "value": value,
                    "confidence": classification.confidence.get(key, 0.0),
                    "previous": old_value,
                })
        return updates

    def _compute_unknowns(self) -> list[str]:
        """Check which required fields are still missing from the spec."""
        from app.translator.classifier import REQUIRED_FIELDS
        return [f for f in REQUIRED_FIELDS if f not in self.spec]

    def _ask_question(
        self,
        unknowns: list[str],
        spec_updates: list[dict],
        classification: ClassificationResult,
    ) -> PipelineResponse:
        """Return a question for the most important unknown field."""
        question = self.question_tree.next_question(unknowns)

        if question is None:
            # No YAML question available for these unknowns — ask generically
            missing = ", ".join(unknowns)
            return PipelineResponse(
                message=f"I need a bit more information. Could you specify: {missing}?",
                response_type="question",
                spec_updates=spec_updates,
                classification=classification.to_dict(),
            )

        # Format a response with the question
        q_dict = question.to_dict()
        options_text = "\n".join(
            f"  {i+1}. **{opt['label']}** — {opt['impact']}"
            for i, opt in enumerate(question.options)
        )
        message = f"{question.question}\n\n{options_text}"

        if question.default is not None:
            message += f"\n\n(Default: {question.default})"

        # Summarize what we already know
        known_fields = {k: v for k, v in self.spec.items() if k != "feelings"}
        if known_fields:
            known_text = ", ".join(f"{k}={v}" for k, v in known_fields.items())
            message = f"Got it! So far: {known_text}.\n\n{message}"

        return PipelineResponse(
            message=message,
            response_type="question",
            spec_updates=spec_updates,
            question=q_dict,
            classification=classification.to_dict(),
        )

    def _generate(
        self,
        spec_updates: list[dict],
        classification: ClassificationResult,
    ) -> PipelineResponse:
        """
        Spec is complete — trigger geometry generation.

        If spec_updates exist, this is an iterative refinement — the message
        reflects what changed rather than repeating the full spec.
        """
        # Build a summary of the complete spec
        spec_summary = ", ".join(f"{k}={v}" for k, v in self.spec.items() if k != "feelings")
        feelings = self.spec.get("feelings", [])
        feelings_text = f" Style: {', '.join(feelings)}." if feelings else ""

        geometry_info = {
            "status": "ready",
            "spec": dict(self.spec),
            "message": "Geometry generation ready.",
        }

        # If we have updates, this is an iterative refinement
        changes_with_previous = [u for u in spec_updates if u.get("previous") is not None]
        if changes_with_previous:
            changes_text = ", ".join(
                f"{u['field']}: {u['previous']} → {u['value']}"
                for u in changes_with_previous
            )
            message = (
                f"Updated: {changes_text}.\n\n"
                f"**Current spec:** {spec_summary}.{feelings_text}\n\n"
                f"Regenerating geometry with these changes."
            )
        else:
            message = (
                f"Spec complete! Here's what I'll build:\n\n"
                f"**Parameters:** {spec_summary}.{feelings_text}\n\n"
                f"Generating geometry based on these parameters."
            )

        return PipelineResponse(
            message=message,
            response_type="generation",
            spec_updates=spec_updates,
            geometry=geometry_info,
            classification=classification.to_dict(),
        )

    def apply_answer(self, field: str, value: Any) -> PipelineResponse:
        """
        Apply a user's answer to a question (e.g., from button click).

        This is used when the user selects an option from a presented question
        rather than typing free text.
        """
        self.question_tree.apply_answer(field, value, self.spec)

        # Check if we have more unknowns
        unknowns = self._compute_unknowns()
        if unknowns:
            question = self.question_tree.next_question(unknowns)
            if question:
                q_dict = question.to_dict()
                options_text = "\n".join(
                    f"  {i+1}. **{opt['label']}** — {opt['impact']}"
                    for i, opt in enumerate(question.options)
                )
                message = f"Great, {field} set to {value}.\n\n{question.question}\n\n{options_text}"
                return PipelineResponse(
                    message=message,
                    response_type="question",
                    spec_updates=[{"field": field, "value": value, "confidence": 1.0, "previous": None}],
                    question=q_dict,
                )
            else:
                missing = ", ".join(unknowns)
                return PipelineResponse(
                    message=f"{field} set to {value}. Still need: {missing}",
                    response_type="question",
                    spec_updates=[{"field": field, "value": value, "confidence": 1.0, "previous": None}],
                )
        else:
            # Spec complete after this answer
            return self._generate(
                spec_updates=[{"field": field, "value": value, "confidence": 1.0, "previous": None}],
                classification=ClassificationResult(),
            )

    def reset(self):
        """Reset the pipeline state for a new conversation."""
        self.spec.clear()
        self.history.clear()
