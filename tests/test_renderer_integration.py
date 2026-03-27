"""Contract tests for SC-04 Three.js Renderer Integration.

Covers:
1. GET /modules/{module_id}/geometry → 200 with model/gltf-binary content-type
   when the STL artefact exists on disk (trimesh conversion mocked).
2. GET /modules/{module_id}/geometry → 404 when no STL artefact exists.
3. Static export check: moduleStore.ts exposes activeModuleId + setActiveModuleId.
4. Static smoke-test: ModuleListPanel.tsx imports from moduleStore and iterates
   the modules array.
"""
from __future__ import annotations

import re
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from backend.app.main import app

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_REPO_ROOT = Path(__file__).resolve().parent.parent
_STORE_PATH = _REPO_ROOT / "frontend" / "src" / "stores" / "moduleStore.ts"
_PANEL_PATH = _REPO_ROOT / "frontend" / "src" / "components" / "ModuleListPanel.tsx"

# Fake GLB header bytes — the router returns whatever _stl_to_glb_bytes returns
_FAKE_GLB = b"glTF\x02\x00\x00\x00FAKE"


# ---------------------------------------------------------------------------
# Shared client fixture
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def client() -> TestClient:
    """FastAPI TestClient backed by the real KFS app."""
    return TestClient(app)


# ---------------------------------------------------------------------------
# Helper: plant a minimal STL file in the temp models dir
# ---------------------------------------------------------------------------


def _write_stl(models_dir: str, module_id: str) -> Path:
    """Write a minimal ASCII STL so Path.exists() returns True."""
    module_dir = Path(models_dir) / module_id
    module_dir.mkdir(parents=True, exist_ok=True)
    stl_path = module_dir / f"{module_id}.stl"
    stl_path.write_text(
        "solid test\n"
        "  facet normal 0 0 1\n"
        "    outer loop\n"
        "      vertex 0 0 0\n"
        "      vertex 1 0 0\n"
        "      vertex 0 1 0\n"
        "    endloop\n"
        "  endfacet\n"
        "endsolid test\n",
        encoding="utf-8",
    )
    return stl_path


# ---------------------------------------------------------------------------
# 1. 200 with binary content-type when STL exists
# ---------------------------------------------------------------------------


def test_geometry_returns_200_with_binary_content_type(tmp_path, client):
    """GET /modules/{id}/geometry returns 200 and model/gltf-binary when STL is present."""
    module_id = "mod-contract-test"
    _write_stl(str(tmp_path), module_id)

    with (
        patch("backend.app.routes.modules.settings.models_dir", str(tmp_path)),
        patch(
            "backend.app.routes.modules._stl_to_glb_bytes",
            return_value=_FAKE_GLB,
        ),
    ):
        response = client.get(f"/modules/{module_id}/geometry")

    assert response.status_code == 200
    assert response.headers["content-type"] == "model/gltf-binary"
    assert response.content == _FAKE_GLB


def test_geometry_response_includes_module_id_header(tmp_path, client):
    """The X-Module-Id header echoes the requested module id."""
    module_id = "mod-header-check"
    _write_stl(str(tmp_path), module_id)

    with (
        patch("backend.app.routes.modules.settings.models_dir", str(tmp_path)),
        patch(
            "backend.app.routes.modules._stl_to_glb_bytes",
            return_value=_FAKE_GLB,
        ),
    ):
        response = client.get(f"/modules/{module_id}/geometry")

    assert response.status_code == 200
    assert response.headers.get("x-module-id") == module_id


def test_geometry_version_query_param_is_accepted(tmp_path, client):
    """?v=N cache-buster is accepted without error (ignored server-side)."""
    module_id = "mod-version-param"
    _write_stl(str(tmp_path), module_id)

    with (
        patch("backend.app.routes.modules.settings.models_dir", str(tmp_path)),
        patch(
            "backend.app.routes.modules._stl_to_glb_bytes",
            return_value=_FAKE_GLB,
        ),
    ):
        response = client.get(f"/modules/{module_id}/geometry?v=42")

    assert response.status_code == 200


# ---------------------------------------------------------------------------
# 2. 404 when STL not found
# ---------------------------------------------------------------------------


def test_geometry_returns_404_when_stl_missing(tmp_path, client):
    """GET /modules/{id}/geometry returns 404 when no STL artefact exists."""
    module_id = "nonexistent-module-xyz"

    with patch("backend.app.routes.modules.settings.models_dir", str(tmp_path)):
        response = client.get(f"/modules/{module_id}/geometry")

    assert response.status_code == 404


def test_geometry_404_detail_mentions_module_id(tmp_path, client):
    """404 detail should reference the missing module so callers can diagnose."""
    module_id = "ghost-module"

    with patch("backend.app.routes.modules.settings.models_dir", str(tmp_path)):
        response = client.get(f"/modules/{module_id}/geometry")

    detail = response.json().get("detail", "")
    assert "ghost-module" in detail or "geometry artefact" in detail.lower()


# ---------------------------------------------------------------------------
# 3. moduleStore static export check
# ---------------------------------------------------------------------------


def test_modulestore_file_exists():
    assert _STORE_PATH.exists(), f"moduleStore.ts not found at {_STORE_PATH}"


def test_modulestore_exports_active_module_id():
    """moduleStore must expose the activeModuleId field."""
    content = _STORE_PATH.read_text(encoding="utf-8")
    assert "activeModuleId" in content, (
        "moduleStore.ts must define/export 'activeModuleId'"
    )


def test_modulestore_exports_set_active_module_id():
    """moduleStore must expose the setActiveModuleId action."""
    content = _STORE_PATH.read_text(encoding="utf-8")
    assert "setActiveModuleId" in content, (
        "moduleStore.ts must define/export 'setActiveModuleId'"
    )


def test_modulestore_exports_use_module_store_hook():
    """The store must be created via Zustand's create() and exported."""
    content = _STORE_PATH.read_text(encoding="utf-8")
    assert "useModuleStore" in content, (
        "moduleStore.ts must export 'useModuleStore' Zustand hook"
    )


def test_modulestore_has_modules_array():
    """moduleStore must include a modules array for the module list."""
    content = _STORE_PATH.read_text(encoding="utf-8")
    assert re.search(r"\bmodules\b", content), (
        "moduleStore.ts must contain a 'modules' state field"
    )


# ---------------------------------------------------------------------------
# 4. ModuleListPanel smoke test
# ---------------------------------------------------------------------------


def test_module_list_panel_file_exists():
    assert _PANEL_PATH.exists(), f"ModuleListPanel.tsx not found at {_PANEL_PATH}"


def test_module_list_panel_is_exported():
    """ModuleListPanel must be a named (or default) export."""
    content = _PANEL_PATH.read_text(encoding="utf-8")
    assert re.search(r"export\b.+ModuleListPanel", content), (
        "ModuleListPanel.tsx must export 'ModuleListPanel'"
    )


def test_module_list_panel_imports_use_module_store():
    """Panel must pull data from the Zustand module store."""
    content = _PANEL_PATH.read_text(encoding="utf-8")
    assert "useModuleStore" in content, (
        "ModuleListPanel must import useModuleStore from moduleStore"
    )


def test_module_list_panel_renders_module_rows():
    """Panel must iterate over the modules array to render one row per module."""
    content = _PANEL_PATH.read_text(encoding="utf-8")
    assert re.search(r"modules\.map\b", content), (
        "ModuleListPanel must use modules.map() to render per-module rows"
    )


def test_module_list_panel_tracks_active_module():
    """Panel must read activeModuleId to highlight the selected module."""
    content = _PANEL_PATH.read_text(encoding="utf-8")
    assert "activeModuleId" in content, (
        "ModuleListPanel must reference activeModuleId for active-row styling"
    )
