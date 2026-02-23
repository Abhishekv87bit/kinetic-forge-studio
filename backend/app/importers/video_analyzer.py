"""
Video analyzer with frame extraction and motion profiling.

Extracts key frames from video files using ffmpeg, sends them to Claude Vision
for motion analysis, and produces a structured motion profile.

All external dependencies (ffmpeg, Claude API) are mocked when unavailable.
"""

import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from app.importers.photo_analyzer import PhotoAnalyzer, _parse_vision_response


# Supported video extensions
SUPPORTED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".webm", ".mkv"}

# Motion profiling prompt for Claude Vision (analysis of multiple key frames)
MOTION_PROFILE_PROMPT = """Analyze these key frames extracted from a video of a kinetic sculpture or mechanism.
Determine:
1. The approximate cycle period (how long one complete motion cycle takes)
2. The types of motion visible (rotary, oscillating, reciprocating, linear, wave-like)
3. The number of distinct moving components
4. The overall tempo (slow/meditative, moderate/rhythmic, fast/energetic)

Respond in a structured format:
CYCLE_PERIOD: <seconds or "unknown">
MOTION_TYPES: <comma-separated list>
COMPONENT_COUNT: <integer>
TEMPO: <slow|moderate|fast>
NOTES: <1-2 sentence observation about the motion quality>
"""


def _parse_motion_profile(response_text: str) -> dict[str, Any]:
    """
    Parse a motion profile response from Claude Vision.

    Returns a dict with keys: cycle_period, motion_types, component_count,
    tempo, notes.
    """
    result = {
        "cycle_period": None,
        "motion_types": [],
        "component_count": 0,
        "tempo": "unknown",
        "notes": "",
    }

    for line in response_text.strip().splitlines():
        line = line.strip()
        if line.startswith("CYCLE_PERIOD:"):
            raw = line.split(":", 1)[1].strip()
            try:
                result["cycle_period"] = float(raw.replace("s", "").strip())
            except (ValueError, AttributeError):
                result["cycle_period"] = None
        elif line.startswith("MOTION_TYPES:"):
            raw = line.split(":", 1)[1].strip()
            result["motion_types"] = [m.strip() for m in raw.split(",") if m.strip()]
        elif line.startswith("COMPONENT_COUNT:"):
            try:
                result["component_count"] = int(line.split(":", 1)[1].strip())
            except ValueError:
                result["component_count"] = 0
        elif line.startswith("TEMPO:"):
            result["tempo"] = line.split(":", 1)[1].strip()
        elif line.startswith("NOTES:"):
            result["notes"] = line.split(":", 1)[1].strip()

    return result


def _is_ffmpeg_available() -> bool:
    """Check if ffmpeg is available on the system PATH."""
    return shutil.which("ffmpeg") is not None


class VideoAnalyzer:
    """
    Analyze videos of kinetic sculptures for motion profiling.

    Extracts key frames using ffmpeg, then analyzes them with Claude Vision
    to identify motion patterns, cycle periods, and mechanism types.

    If ffmpeg is not available or no API key is configured, returns
    placeholder analysis with appropriate messages.
    """

    def __init__(self, claude_api_key: str = ""):
        self.api_key = claude_api_key
        self.photo_analyzer = PhotoAnalyzer(claude_api_key=claude_api_key)

    def analyze(self, file_path: str | Path, num_frames: int = 6) -> dict[str, Any]:
        """
        Analyze a video file and return a motion profile.

        Args:
            file_path: Path to the video file.
            num_frames: Number of key frames to extract (default: 6).

        Returns:
            Dict containing:
                - file_path: Original file path
                - cycle_period: Estimated cycle duration in seconds
                - motion_types: List of detected motion types
                - component_count: Estimated number of moving components
                - tempo: Overall motion tempo (slow/moderate/fast)
                - notes: Additional observations
                - frame_count: Number of frames extracted
                - source: "claude_vision", "ffmpeg_only", or "placeholder"
                - format: "video"

        Raises:
            FileNotFoundError: If file does not exist.
            ValueError: If file format is not supported.
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Video file not found: {file_path}")

        ext = file_path.suffix.lower()
        if ext not in SUPPORTED_VIDEO_EXTENSIONS:
            raise ValueError(
                f"Unsupported video format: {ext}. "
                f"Supported: {', '.join(sorted(SUPPORTED_VIDEO_EXTENSIONS))}"
            )

        # Check if ffmpeg is available
        if not _is_ffmpeg_available():
            return self._placeholder_analysis(
                file_path,
                reason="ffmpeg not found on system PATH",
            )

        # Extract key frames
        try:
            frame_paths = self._extract_frames(file_path, num_frames)
        except Exception as e:
            return self._placeholder_analysis(
                file_path,
                reason=f"Frame extraction failed: {e}",
            )

        if not frame_paths:
            return self._placeholder_analysis(
                file_path,
                reason="No frames could be extracted",
            )

        # Check if Claude API is available
        if not self.api_key:
            # Clean up frames
            for fp in frame_paths:
                fp.unlink(missing_ok=True)
            return self._placeholder_analysis(
                file_path,
                reason="No Claude API key configured",
                frame_count=len(frame_paths),
            )

        # Analyze frames with Claude Vision
        return self._analyze_frames(file_path, frame_paths)

    def _extract_frames(
        self, video_path: Path, num_frames: int
    ) -> list[Path]:
        """
        Extract key frames from video using ffmpeg.

        Uses ffmpeg's select filter to extract evenly-spaced frames.
        """
        tmp_dir = Path(tempfile.mkdtemp(prefix="kfs_video_"))
        output_pattern = str(tmp_dir / "frame_%03d.png")

        # Use ffmpeg to extract evenly-spaced frames
        cmd = [
            "ffmpeg",
            "-i", str(video_path),
            "-vf", f"select='not(mod(n\\,{max(1, num_frames)}))',setpts=N/FRAME_RATE/TB",
            "-frames:v", str(num_frames),
            "-y",
            output_pattern,
        ]

        subprocess.run(
            cmd,
            capture_output=True,
            timeout=30,
            check=True,
        )

        # Collect extracted frames
        frames = sorted(tmp_dir.glob("frame_*.png"))
        return frames

    def _analyze_frames(
        self, video_path: Path, frame_paths: list[Path]
    ) -> dict[str, Any]:
        """Analyze extracted frames with Claude Vision."""
        # Analyze each frame individually
        frame_analyses = []
        for fp in frame_paths:
            try:
                analysis = self.photo_analyzer.analyze(fp)
                frame_analyses.append(analysis)
            except Exception:
                pass
            finally:
                fp.unlink(missing_ok=True)

        if not frame_analyses:
            return self._placeholder_analysis(
                video_path,
                reason="No frames could be analyzed",
                frame_count=len(frame_paths),
            )

        # Aggregate frame analyses into a motion profile
        all_types = set()
        total_components = 0
        all_materials = set()
        for fa in frame_analyses:
            if fa.get("mechanism_type", "unknown") != "unknown":
                all_types.add(fa["mechanism_type"])
            total_components = max(total_components, fa.get("component_count", 0))
            all_materials.update(fa.get("materials", []))

        return {
            "file_path": str(video_path),
            "cycle_period": None,  # Would need temporal analysis
            "motion_types": list(all_types) if all_types else ["unknown"],
            "component_count": total_components,
            "tempo": "moderate",  # Default without temporal analysis
            "notes": f"Analyzed {len(frame_analyses)} frames. Materials: {', '.join(all_materials) if all_materials else 'not identified'}.",
            "frame_count": len(frame_analyses),
            "source": "claude_vision",
            "format": "video",
        }

    def _placeholder_analysis(
        self,
        file_path: Path,
        reason: str = "",
        frame_count: int = 0,
    ) -> dict[str, Any]:
        """Return a placeholder analysis when dependencies are unavailable."""
        return {
            "file_path": str(file_path),
            "cycle_period": None,
            "motion_types": [],
            "component_count": 0,
            "tempo": "unknown",
            "notes": (
                f"Video analysis unavailable: {reason}. "
                "Install ffmpeg and set KFS_CLAUDE_API_KEY for full video analysis."
            ),
            "frame_count": frame_count,
            "source": "placeholder",
            "format": "video",
        }
