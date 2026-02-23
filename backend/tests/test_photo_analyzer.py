"""Tests for the photo analyzer (Claude Vision API integration)."""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock

from app.importers.photo_analyzer import (
    PhotoAnalyzer,
    _parse_vision_response,
    SUPPORTED_IMAGE_EXTENSIONS,
)


@pytest.fixture
def analyzer_no_key():
    """Analyzer without API key (placeholder mode)."""
    return PhotoAnalyzer(claude_api_key="")


@pytest.fixture
def analyzer_with_key():
    """Analyzer with a mock API key."""
    return PhotoAnalyzer(claude_api_key="test-key-12345")


@pytest.fixture
def test_image(tmp_path) -> Path:
    """Create a minimal valid PNG file for testing."""
    # Minimal 1x1 pixel PNG
    import struct
    import zlib

    def _minimal_png() -> bytes:
        signature = b"\x89PNG\r\n\x1a\n"
        # IHDR chunk
        ihdr_data = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
        ihdr_crc = zlib.crc32(b"IHDR" + ihdr_data) & 0xFFFFFFFF
        ihdr = struct.pack(">I", 13) + b"IHDR" + ihdr_data + struct.pack(">I", ihdr_crc)
        # IDAT chunk
        raw = zlib.compress(b"\x00\xff\x00\x00")
        idat_crc = zlib.crc32(b"IDAT" + raw) & 0xFFFFFFFF
        idat = struct.pack(">I", len(raw)) + b"IDAT" + raw + struct.pack(">I", idat_crc)
        # IEND chunk
        iend_crc = zlib.crc32(b"IEND") & 0xFFFFFFFF
        iend = struct.pack(">I", 0) + b"IEND" + struct.pack(">I", iend_crc)
        return signature + ihdr + idat + iend

    path = tmp_path / "test_photo.png"
    path.write_bytes(_minimal_png())
    return path


@pytest.fixture
def test_jpg(tmp_path) -> Path:
    """Create a minimal JPEG-like file for testing."""
    path = tmp_path / "test_photo.jpg"
    # Minimal JPEG header (just enough for file detection)
    path.write_bytes(b"\xff\xd8\xff\xe0" + b"\x00" * 100 + b"\xff\xd9")
    return path


class TestParseVisionResponse:
    def test_parse_complete_response(self):
        response = """MECHANISM_TYPE: four-bar linkage
MOTION_TYPE: oscillating
COMPONENT_COUNT: 12
MATERIALS: wood, brass, steel
NOTES: The linkage uses a Grashof-compliant configuration with smooth motion."""

        result = _parse_vision_response(response)
        assert result["mechanism_type"] == "four-bar linkage"
        assert result["motion_type"] == "oscillating"
        assert result["component_count"] == 12
        assert result["materials"] == ["wood", "brass", "steel"]
        assert "Grashof" in result["notes"]

    def test_parse_partial_response(self):
        response = """MECHANISM_TYPE: gear train
MOTION_TYPE: rotary"""

        result = _parse_vision_response(response)
        assert result["mechanism_type"] == "gear train"
        assert result["motion_type"] == "rotary"
        assert result["component_count"] == 0
        assert result["materials"] == []
        assert result["notes"] == ""

    def test_parse_empty_response(self):
        result = _parse_vision_response("")
        assert result["mechanism_type"] == "unknown"
        assert result["motion_type"] == "unknown"
        assert result["component_count"] == 0

    def test_parse_invalid_component_count(self):
        response = "COMPONENT_COUNT: many"
        result = _parse_vision_response(response)
        assert result["component_count"] == 0

    def test_parse_single_material(self):
        response = "MATERIALS: aluminum"
        result = _parse_vision_response(response)
        assert result["materials"] == ["aluminum"]

    def test_parse_whitespace_handling(self):
        response = """  MECHANISM_TYPE:   cam-follower
  MOTION_TYPE:   reciprocating  """
        result = _parse_vision_response(response)
        assert result["mechanism_type"] == "cam-follower"
        assert result["motion_type"] == "reciprocating"


class TestPhotoAnalyzerPlaceholder:
    def test_placeholder_when_no_key(self, analyzer_no_key, test_image):
        result = analyzer_no_key.analyze(test_image)
        assert result["source"] == "placeholder"
        assert result["format"] == "photo"
        assert "no API key" in result["mechanism_type"]

    def test_placeholder_file_path_stored(self, analyzer_no_key, test_image):
        result = analyzer_no_key.analyze(test_image)
        assert result["file_path"] == str(test_image)

    def test_placeholder_notes_suggest_api_key(self, analyzer_no_key, test_image):
        result = analyzer_no_key.analyze(test_image)
        assert "KFS_CLAUDE_API_KEY" in result["notes"]

    def test_placeholder_structure(self, analyzer_no_key, test_image):
        result = analyzer_no_key.analyze(test_image)
        assert "mechanism_type" in result
        assert "motion_type" in result
        assert "component_count" in result
        assert "materials" in result
        assert "notes" in result


class TestPhotoAnalyzerWithMockedAPI:
    @patch("app.importers.photo_analyzer.httpx")
    def test_successful_api_call(self, mock_httpx, analyzer_with_key, test_image):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [
                {
                    "type": "text",
                    "text": """MECHANISM_TYPE: cam-follower
MOTION_TYPE: reciprocating
COMPONENT_COUNT: 8
MATERIALS: brass, steel, acrylic
NOTES: A precision cam mechanism with roller followers.""",
                }
            ]
        }
        mock_httpx.post.return_value = mock_response

        result = analyzer_with_key.analyze(test_image)

        assert result["source"] == "claude_vision"
        assert result["mechanism_type"] == "cam-follower"
        assert result["motion_type"] == "reciprocating"
        assert result["component_count"] == 8
        assert result["materials"] == ["brass", "steel", "acrylic"]
        assert "precision cam" in result["notes"]
        assert result["format"] == "photo"

    @patch("app.importers.photo_analyzer.httpx")
    def test_api_error_response(self, mock_httpx, analyzer_with_key, test_image):
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_httpx.post.return_value = mock_response

        result = analyzer_with_key.analyze(test_image)
        assert result["mechanism_type"] == "analysis_failed"
        assert "500" in result["notes"]

    @patch("app.importers.photo_analyzer.httpx")
    def test_api_sends_correct_headers(self, mock_httpx, analyzer_with_key, test_image):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"content": [{"text": ""}]}
        mock_httpx.post.return_value = mock_response

        analyzer_with_key.analyze(test_image)

        call_kwargs = mock_httpx.post.call_args
        headers = call_kwargs.kwargs.get("headers", call_kwargs[1].get("headers", {}))
        assert headers["x-api-key"] == "test-key-12345"
        assert "anthropic-version" in headers


class TestPhotoAnalyzerErrors:
    def test_nonexistent_file(self, analyzer_no_key, tmp_path):
        with pytest.raises(FileNotFoundError):
            analyzer_no_key.analyze(tmp_path / "nonexistent.png")

    def test_unsupported_format(self, analyzer_no_key, tmp_path):
        bad_file = tmp_path / "model.step"
        bad_file.write_bytes(b"not an image")
        with pytest.raises(ValueError, match="Unsupported image format"):
            analyzer_no_key.analyze(bad_file)

    def test_supported_extensions_documented(self):
        assert ".jpg" in SUPPORTED_IMAGE_EXTENSIONS
        assert ".png" in SUPPORTED_IMAGE_EXTENSIONS
        assert ".webp" in SUPPORTED_IMAGE_EXTENSIONS
