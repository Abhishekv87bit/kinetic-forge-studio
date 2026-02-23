"""
Orchestrator pipeline for Kinetic Forge Studio.

Flow:
  1. Parse user message
  2. Classify intent (keyword classifier)
  3. Merge extracted fields with existing spec
  4. Check for unknowns
  5. If unknowns remain, return a YAML-driven question
  6. If spec is complete, generate geometry (placeholder) and return response
  7. Optionally enhance with Claude API (if key is available)

The pipeline works WITHOUT the Claude API — classifier + question tree handle
the core loop. Claude is an optional enhancement for richer responses.
"""

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

        # Step 2: Merge new fields into running spec
        spec_updates = self._merge_fields(classification)

        # Step 3: Add feelings to spec if any
        if classification.feelings:
            self.spec["feelings"] = list(set(
                self.spec.get("feelings", []) + classification.feelings
            ))

        # Step 4: Determine unknowns against running spec
        unknowns = self._compute_unknowns()

        # Step 5: Route based on unknowns
        if unknowns:
            return self._ask_question(unknowns, spec_updates, classification)
        else:
            return self._generate(spec_updates, classification)

    def _merge_fields(self, classification: ClassificationResult) -> list[dict]:
        """Merge classified fields into the running spec. Return list of updates."""
        updates = []
        for key, value in classification.fields.items():
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
        Spec is complete — generate geometry (placeholder for now).

        In the future, this will call the geometry engine to produce
        CadQuery shapes and return GLB data for the viewport.
        """
        # Build a summary of the complete spec
        spec_summary = ", ".join(f"{k}={v}" for k, v in self.spec.items() if k != "feelings")
        feelings = self.spec.get("feelings", [])
        feelings_text = f" Style: {', '.join(feelings)}." if feelings else ""

        # Placeholder geometry info — Phase 4 geometry engine will fill this
        geometry_info = {
            "status": "ready",
            "spec": dict(self.spec),
            "message": "Spec complete. Geometry generation available.",
        }

        message = (
            f"Spec complete! Here's what I'll build:\n\n"
            f"**Parameters:** {spec_summary}.{feelings_text}\n\n"
            f"Ready to generate geometry. The design will be created based on these parameters."
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
