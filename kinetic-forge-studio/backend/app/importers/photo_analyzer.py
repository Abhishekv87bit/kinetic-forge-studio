"""
Photo analyzer using Claude Vision API.

Accepts an image file path, builds a prompt for Claude's vision capabilities,
and parses the response into a structured mechanism identification dict.

If no API key is configured, returns a placeholder analysis.
"""

import base64
from pathlib import Path
from typing import Any

import httpx


# Supported image extensions
SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp"}

# The prompt sent to Claude Vision for mechanism identification
VISION_PROMPT = """Analyze this image of a kinetic sculpture or mechanical device.
Identify and describe:
1. The type of mechanism visible (e.g., four-bar linkage, gear train, cam-follower, crank-slider, escapement, wave mechanism)
2. The type of motion produced (e.g., rotary, oscillating, reciprocating, linear, wave-like, compound)
3. An estimate of the number of distinct components/parts visible
4. Materials visible or likely used (e.g., wood, metal, acrylic, 3D printed PLA/PETG)
5. Any notable design features or engineering observations

Respond in a structured format:
MECHANISM_TYPE: <type>
MOTION_TYPE: <type>
COMPONENT_COUNT: <integer>
MATERIALS: <comma-separated list>
NOTES: <1-2 sentence observation>
"""


def _parse_vision_response(response_text: str) -> dict[str, Any]:
    """
    Parse a structured Claude Vision response into a dict.

    Expected format:
        MECHANISM_TYPE: four-bar linkage
        MOTION_TYPE: oscillating
        COMPONENT_COUNT: 12
        MATERIALS: wood, brass, steel
        NOTES: The linkage uses a Grashof-compliant configuration...

    Returns a dict with keys: mechanism_type, motion_type, component_count,
    materials, notes.
    """
    result = {
        "mechanism_type": "unknown",
        "motion_type": "unknown",
        "component_count": 0,
        "materials": [],
        "notes": "",
    }

    for line in response_text.strip().splitlines():
        line = line.strip()
        if line.startswith("MECHANISM_TYPE:"):
            result["mechanism_type"] = line.split(":", 1)[1].strip()
        elif line.startswith("MOTION_TYPE:"):
            result["motion_type"] = line.split(":", 1)[1].strip()
        elif line.startswith("COMPONENT_COUNT:"):
            try:
                result["component_count"] = int(line.split(":", 1)[1].strip())
            except ValueError:
                result["component_count"] = 0
        elif line.startswith("MATERIALS:"):
            raw = line.split(":", 1)[1].strip()
            result["materials"] = [m.strip() for m in raw.split(",") if m.strip()]
        elif line.startswith("NOTES:"):
            result["notes"] = line.split(":", 1)[1].strip()

    return result


def _encode_image_base64(file_path: Path) -> str:
    """Read an image file and return its base64-encoded content."""
    return base64.b64encode(file_path.read_bytes()).decode("utf-8")


def _get_media_type(file_path: Path) -> str:
    """Map file extension to MIME media type."""
    ext = file_path.suffix.lower()
    media_types = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
        ".gif": "image/gif",
        ".bmp": "image/bmp",
    }
    return media_types.get(ext, "image/jpeg")


class PhotoAnalyzer:
    """
    Analyze photos of kinetic sculptures using Claude Vision API.

    If no API key is configured, returns a placeholder analysis
    with reasonable defaults and a note indicating mock mode.
    """

    def __init__(self, claude_api_key: str = ""):
        self.api_key = claude_api_key

    def analyze(self, file_path: str | Path) -> dict[str, Any]:
        """
        Analyze a photo and return mechanism identification.

        Args:
            file_path: Path to the image file.

        Returns:
            Dict containing:
                - file_path: Original file path
                - mechanism_type: Identified mechanism type
                - motion_type: Type of motion produced
                - component_count: Estimated number of components
                - materials: List of identified materials
                - notes: Additional observations
                - source: "claude_vision" or "placeholder"
                - format: "photo"

        Raises:
            FileNotFoundError: If file does not exist.
            ValueError: If file format is not supported.
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Image file not found: {file_path}")

        ext = file_path.suffix.lower()
        if ext not in SUPPORTED_IMAGE_EXTENSIONS:
            raise ValueError(
                f"Unsupported image format: {ext}. "
                f"Supported: {', '.join(sorted(SUPPORTED_IMAGE_EXTENSIONS))}"
            )

        if not self.api_key:
            return self._placeholder_analysis(file_path)

        return self._call_claude_vision(file_path)

    def _placeholder_analysis(self, file_path: Path) -> dict[str, Any]:
        """Return a placeholder analysis when no API key is available."""
        return {
            "file_path": str(file_path),
            "mechanism_type": "unidentified (no API key configured)",
            "motion_type": "unknown",
            "component_count": 0,
            "materials": [],
            "notes": (
                "Photo analysis requires a Claude API key. "
                "Set KFS_CLAUDE_API_KEY to enable vision-based mechanism identification."
            ),
            "source": "placeholder",
            "format": "photo",
        }

    def _call_claude_vision(self, file_path: Path) -> dict[str, Any]:
        """
        Call Claude Vision API to analyze the image.

        Builds the API request with the image encoded as base64
        and parses the structured response.
        """
        image_data = _encode_image_base64(file_path)
        media_type = _get_media_type(file_path)

        response = httpx.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": self.api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": "claude-sonnet-4-20250514",
                "max_tokens": 1024,
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": media_type,
                                    "data": image_data,
                                },
                            },
                            {
                                "type": "text",
                                "text": VISION_PROMPT,
                            },
                        ],
                    }
                ],
            },
            timeout=30.0,
        )

        if response.status_code != 200:
            return {
                "file_path": str(file_path),
                "mechanism_type": "analysis_failed",
                "motion_type": "unknown",
                "component_count": 0,
                "materials": [],
                "notes": f"Claude API returned status {response.status_code}",
                "source": "claude_vision",
                "format": "photo",
            }

        data = response.json()
        text_content = data.get("content", [{}])[0].get("text", "")
        parsed = _parse_vision_response(text_content)

        return {
            "file_path": str(file_path),
            **parsed,
            "source": "claude_vision",
            "format": "photo",
        }
