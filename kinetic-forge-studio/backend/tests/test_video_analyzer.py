"""Tests for the video analyzer (ffmpeg + Claude Vision, all mocked)."""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock

from app.importers.video_analyzer import (
    VideoAnalyzer,
    _parse_motion_profile,
    SUPPORTED_VIDEO_EXTENSIONS,
)


@pytest.fixture
def analyzer_no_key():
    """Analyzer without API key (placeholder mode)."""
    return VideoAnalyzer(claude_api_key="")


@pytest.fixture
def analyzer_with_key():
    """Analyzer with a mock API key."""
    return VideoAnalyzer(claude_api_key="test-key-12345")


@pytest.fixture
def test_video(tmp_path) -> Path:
    """Create a minimal fake video file for testing."""
    path = tmp_path / "test_video.mp4"
    # Write minimal MP4-like header (just enough for file detection)
    path.write_bytes(b"\x00\x00\x00\x1c\x66\x74\x79\x70" + b"\x00" * 200)
    return path


@pytest.fixture
def test_mov(tmp_path) -> Path:
    """Create a minimal fake MOV file."""
    path = tmp_path / "test_video.mov"
    path.write_bytes(b"\x00\x00\x00\x14\x66\x74\x79\x70\x71\x74" + b"\x00" * 100)
    return path


class TestParseMotionProfile:
    def test_parse_complete_response(self):
        response = """CYCLE_PERIOD: 2.5s
MOTION_TYPES: oscillating, rotary
COMPONENT_COUNT: 15
TEMPO: moderate
NOTES: Smooth wave-like motion with interlocking gears."""

        result = _parse_motion_profile(response)
        assert result["cycle_period"] == 2.5
        assert "oscillating" in result["motion_types"]
        assert "rotary" in result["motion_types"]
        assert result["component_count"] == 15
        assert result["tempo"] == "moderate"
        assert "wave-like" in result["notes"]

    def test_parse_partial_response(self):
        response = """MOTION_TYPES: reciprocating
TEMPO: slow"""
        result = _parse_motion_profile(response)
        assert result["motion_types"] == ["reciprocating"]
        assert result["tempo"] == "slow"
        assert result["cycle_period"] is None
        assert result["component_count"] == 0

    def test_parse_empty_response(self):
        result = _parse_motion_profile("")
        assert result["cycle_period"] is None
        assert result["motion_types"] == []
        assert result["component_count"] == 0
        assert result["tempo"] == "unknown"

    def test_parse_unknown_cycle_period(self):
        response = "CYCLE_PERIOD: unknown"
        result = _parse_motion_profile(response)
        assert result["cycle_period"] is None

    def test_parse_numeric_cycle_period(self):
        response = "CYCLE_PERIOD: 3.7"
        result = _parse_motion_profile(response)
        assert result["cycle_period"] == 3.7


class TestVideoAnalyzerPlaceholder:
    @patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=False)
    def test_placeholder_when_no_ffmpeg(self, mock_ffmpeg, analyzer_no_key, test_video):
        result = analyzer_no_key.analyze(test_video)
        assert result["source"] == "placeholder"
        assert result["format"] == "video"
        assert "ffmpeg" in result["notes"]

    @patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=True)
    def test_placeholder_when_no_key(self, mock_ffmpeg, analyzer_no_key, test_video):
        """Even with ffmpeg, no API key means placeholder (after frame extraction attempt)."""
        # Mock frame extraction to return some frame paths
        with patch.object(analyzer_no_key, "_extract_frames") as mock_extract:
            mock_frames = [test_video.parent / f"frame_{i:03d}.png" for i in range(3)]
            for f in mock_frames:
                f.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 50)
            mock_extract.return_value = mock_frames

            result = analyzer_no_key.analyze(test_video)
            assert result["source"] == "placeholder"
            assert "API key" in result["notes"]

    def test_placeholder_file_path_stored(self, analyzer_no_key, test_video):
        with patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=False):
            result = analyzer_no_key.analyze(test_video)
            assert result["file_path"] == str(test_video)

    def test_placeholder_structure(self, analyzer_no_key, test_video):
        with patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=False):
            result = analyzer_no_key.analyze(test_video)
            assert "cycle_period" in result
            assert "motion_types" in result
            assert "component_count" in result
            assert "tempo" in result
            assert "notes" in result
            assert "frame_count" in result
            assert "source" in result
            assert "format" in result


class TestVideoAnalyzerWithMockedDeps:
    @patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=True)
    @patch("app.importers.photo_analyzer.httpx")
    def test_full_analysis_pipeline(self, mock_httpx, mock_ffmpeg, analyzer_with_key, test_video):
        """Test the full pipeline with mocked ffmpeg and Claude API."""
        # Mock Claude Vision response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [
                {
                    "type": "text",
                    "text": """MECHANISM_TYPE: cam-follower
MOTION_TYPE: oscillating
COMPONENT_COUNT: 10
MATERIALS: brass, steel
NOTES: Precision mechanism.""",
                }
            ]
        }
        mock_httpx.post.return_value = mock_response

        # Mock frame extraction
        with patch.object(analyzer_with_key, "_extract_frames") as mock_extract:
            frame_dir = test_video.parent / "frames"
            frame_dir.mkdir()
            mock_frames = []
            for i in range(3):
                fp = frame_dir / f"frame_{i:03d}.png"
                # Write minimal PNG header
                fp.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 50)
                mock_frames.append(fp)
            mock_extract.return_value = mock_frames

            result = analyzer_with_key.analyze(test_video)

            assert result["source"] == "claude_vision"
            assert result["format"] == "video"
            assert result["frame_count"] == 3
            assert result["component_count"] == 10

    @patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=True)
    def test_frame_extraction_failure(self, mock_ffmpeg, analyzer_with_key, test_video):
        """If frame extraction fails, return placeholder."""
        with patch.object(analyzer_with_key, "_extract_frames", side_effect=RuntimeError("ffmpeg crashed")):
            result = analyzer_with_key.analyze(test_video)
            assert result["source"] == "placeholder"
            assert "extraction failed" in result["notes"]


class TestVideoAnalyzerErrors:
    def test_nonexistent_file(self, analyzer_no_key, tmp_path):
        with pytest.raises(FileNotFoundError):
            analyzer_no_key.analyze(tmp_path / "nonexistent.mp4")

    def test_unsupported_format(self, analyzer_no_key, tmp_path):
        bad_file = tmp_path / "photo.jpg"
        bad_file.write_bytes(b"\xff\xd8\xff\xe0" + b"\x00" * 100)
        with pytest.raises(ValueError, match="Unsupported video format"):
            analyzer_no_key.analyze(bad_file)

    def test_supported_extensions_documented(self):
        assert ".mp4" in SUPPORTED_VIDEO_EXTENSIONS
        assert ".mov" in SUPPORTED_VIDEO_EXTENSIONS
        assert ".avi" in SUPPORTED_VIDEO_EXTENSIONS
        assert ".webm" in SUPPORTED_VIDEO_EXTENSIONS


class TestVideoAnalyzerMotionProfile:
    def test_motion_profile_aggregation(self):
        """Test that motion profile correctly aggregates frame analyses."""
        analyzer = VideoAnalyzer(claude_api_key="test-key")

        # Directly test the aggregation logic
        with patch("app.importers.video_analyzer._is_ffmpeg_available", return_value=True):
            with patch.object(analyzer, "_extract_frames") as mock_extract:
                with patch.object(analyzer.photo_analyzer, "analyze") as mock_photo:
                    # Simulate frame extraction
                    import tempfile
                    tmp_dir = Path(tempfile.mkdtemp())
                    frames = []
                    for i in range(2):
                        fp = tmp_dir / f"frame_{i}.png"
                        fp.write_bytes(b"\x89PNG" + b"\x00" * 50)
                        frames.append(fp)
                    mock_extract.return_value = frames

                    # Simulate photo analysis results
                    mock_photo.side_effect = [
                        {
                            "mechanism_type": "cam-follower",
                            "motion_type": "oscillating",
                            "component_count": 8,
                            "materials": ["brass"],
                            "notes": "Frame 1",
                        },
                        {
                            "mechanism_type": "gear-train",
                            "motion_type": "rotary",
                            "component_count": 12,
                            "materials": ["steel"],
                            "notes": "Frame 2",
                        },
                    ]

                    # Create a test video file
                    video = tmp_dir / "test.mp4"
                    video.write_bytes(b"\x00" * 100)

                    result = analyzer.analyze(video)

                    assert result["source"] == "claude_vision"
                    assert result["component_count"] == 12  # max across frames
                    assert "brass" in result["notes"]
                    assert "steel" in result["notes"]
