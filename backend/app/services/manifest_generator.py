"""SC-08 Manifest Generator.

Queries all valid modules via ModuleManager (SC-01), translates each into a
KFSObject backed by a MeshGeometry pointing at its STL artefact, assembles a
KFSManifest, and persists it as a ``.kfs.yaml`` file using the existing
``kfs_core.manifest_parser.save_kfs_manifest`` helper.
"""
from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any, List, Protocol, runtime_checkable

from kfs_core.manifest_models import (
    KFSManifest,
    KFSObject,
    MeshGeometry,
    Transform,
)
from kfs_core.manifest_parser import save_kfs_manifest

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Structural interface for ModuleManager (SC-01)
# ---------------------------------------------------------------------------


@runtime_checkable
class ModuleManagerProtocol(Protocol):
    """Minimum interface consumed by ManifestGenerator.

    SC-01's concrete ModuleManager must implement this method.  Using a
    Protocol (structural sub-typing) keeps SC-08 decoupled from SC-01's
    internal database details.
    """

    async def list_valid(self) -> List[Any]:
        """Return all modules whose status is ``"valid"``."""
        ...


# ---------------------------------------------------------------------------
# Manifest Generator
# ---------------------------------------------------------------------------


class ManifestGenerator:
    """Generate a ``.kfs.yaml`` manifest from all currently valid modules.

    Args:
        module_manager: Any object that satisfies :class:`ModuleManagerProtocol`
                        (i.e. exposes ``await list_valid()``).
        output_dir:     Root directory where per-module STL/STEP artefacts are
                        stored.  Must match the ``output_dir`` passed to
                        :class:`~backend.app.services.module_executor.ModuleExecutor`.
    """

    def __init__(self, module_manager: Any, output_dir: str) -> None:
        self._mm = module_manager
        self.output_dir = output_dir

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    async def generate(
        self,
        manifest_path: str,
        *,
        project_name: str = "KFS Project",
        description: str | None = None,
    ) -> KFSManifest:
        """Build and write a manifest for all currently valid modules.

        Args:
            manifest_path: Absolute (or relative-to-cwd) path where the
                           ``.kfs.yaml`` will be written.  Parent directories
                           are created automatically.
            project_name:  ``name`` field in the manifest header.
            description:   Optional ``description`` field in the manifest header.

        Returns:
            The assembled :class:`~kfs_core.manifest_models.KFSManifest` that
            was saved to disk.

        Raises:
            RuntimeError: If no valid modules are found (manifests must contain
                          at least one object).
        """
        modules = await self._mm.list_valid()
        logger.info("ManifestGenerator: found %d valid module(s)", len(modules))

        if not modules:
            raise RuntimeError(
                "No valid modules found — cannot generate a KFS manifest "
                "with an empty objects list."
            )

        manifest_path_obj = Path(manifest_path).resolve()
        objects: List[KFSObject] = []

        for module in modules:
            module_id = self._get_attr(module, "id")
            stl_abs = os.path.join(self.output_dir, module_id, f"{module_id}.stl")
            kfs_obj = self._module_to_kfs_object(
                module, stl_abs, str(manifest_path_obj)
            )
            objects.append(kfs_obj)
            logger.debug("ManifestGenerator: added object %r", module_id)

        manifest = KFSManifest(
            name=project_name,
            description=description,
            objects=objects,
        )

        save_kfs_manifest(manifest, manifest_path_obj)
        logger.info("ManifestGenerator: manifest written to %s", manifest_path_obj)
        return manifest

    # ------------------------------------------------------------------
    # Translation
    # ------------------------------------------------------------------

    def _module_to_kfs_object(
        self,
        module: Any,
        stl_abs_path: str,
        manifest_abs_path: str,
    ) -> KFSObject:
        """Translate a module record into a :class:`KFSObject`.

        The ``MeshGeometry.path`` is stored relative to the directory that
        contains the manifest file so the manifest remains portable — moving
        the project root together with the ``.kfs.yaml`` preserves all paths.

        Args:
            module:            Module record (duck-typed; must expose ``id``
                               and optionally ``name``).
            stl_abs_path:      Absolute path to the STL artefact on disk.
            manifest_abs_path: Absolute path of the manifest file being written.

        Returns:
            A :class:`KFSObject` with inline :class:`MeshGeometry`.
        """
        module_id = self._get_attr(module, "id")
        module_name = self._get_attr(module, "name", default=module_id)

        # Compute path relative to the manifest's parent directory
        manifest_dir = Path(manifest_abs_path).parent
        try:
            rel_path = os.path.relpath(stl_abs_path, start=str(manifest_dir))
        except ValueError:
            # os.path.relpath raises ValueError on Windows when paths are on
            # different drives.  Fall back to the absolute path.
            rel_path = stl_abs_path

        # Normalise separators to forward slashes for cross-platform YAML
        rel_path = rel_path.replace("\\", "/")

        geometry = MeshGeometry(id=f"{module_id}_mesh", path=rel_path)

        return KFSObject(
            id=module_id,
            name=module_name,
            geometry=geometry,
            transform=Transform(),
        )

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _get_attr(obj: Any, attr: str, *, default: Any = None) -> Any:
        """Retrieve *attr* from *obj* whether it is a dict or an object."""
        if isinstance(obj, dict):
            value = obj.get(attr, default)
        else:
            value = getattr(obj, attr, default)
        if value is None and default is not None:
            return default
        return value
