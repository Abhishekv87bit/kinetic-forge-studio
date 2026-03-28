"""SC-08 Manifest Generator.

Queries all valid modules via ModuleManager, maps each to a KFSObject using
existing kfs_core models, assembles a KFSManifest, and writes a .kfs.yaml
file via the existing manifest_parser.
"""
from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, List, Optional

from backend.app.models.module import Module, ModuleManager


@dataclass
class ManifestResult:
    """Result returned by :meth:`ManifestGenerator.generate`."""

    path: str
    project_name: str
    object_count: int

logger = logging.getLogger(__name__)


class ManifestGenerator:
    """Generate a .kfs.yaml manifest from all currently valid modules.

    Args:
        module_manager: ModuleManager instance (SC-01) used to query modules.
        output_dir:     Root directory where per-module STL/STEP artefacts are
                        stored.  Must match the ``output_dir`` used by
                        :class:`~backend.app.services.module_executor.ModuleExecutor`.
    """

    def __init__(self, module_manager: ModuleManager, output_dir: str) -> None:
        self.module_manager = module_manager
        self.output_dir = output_dir

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    def generate(
        self,
        manifest_path: str,
        project_name: str = "KFS Project",
        description: Optional[str] = None,
    ) -> ManifestResult:
        """Build and write a .kfs.yaml for all modules with status 'valid'.

        Args:
            manifest_path: Destination path for the manifest file.
            project_name:  ``name`` field in the manifest header.
            description:   Optional ``description`` field.

        Returns:
            :class:`ManifestResult` with the absolute path, project name, and
            number of objects written to the manifest.

        Raises:
            RuntimeError: If kfs_core is not installed.
        """
        try:
            from kfs_core.manifest_models import KFSManifest  # noqa: PLC0415
            from kfs_core.manifest_parser import save_kfs_manifest  # noqa: PLC0415
        except ImportError as exc:
            raise RuntimeError(
                "kfs_core is required for manifest generation — "
                "install it with: pip install kfs_core"
            ) from exc

        manifest_abs = Path(manifest_path).resolve()

        all_modules: List[Module] = self.module_manager.list_all()
        valid_modules = [m for m in all_modules if m.status == "valid"]

        logger.info(
            "ManifestGenerator: %d total modules, %d valid",
            len(all_modules),
            len(valid_modules),
        )

        objects = [
            self._module_to_kfs_object(module, manifest_abs)
            for module in valid_modules
        ]

        manifest = KFSManifest(
            name=project_name,
            description=description,
            objects=objects,
        )

        save_kfs_manifest(manifest, manifest_abs)
        logger.info("Manifest written to %s", manifest_abs)
        return ManifestResult(
            path=str(manifest_abs),
            project_name=manifest.name,
            object_count=len(manifest.objects),
        )

    # ------------------------------------------------------------------
    # Translation
    # ------------------------------------------------------------------

    def _module_to_kfs_object(self, module: Module, manifest_path: Path):
        """Translate one Module record into a KFSObject.

        The ``MeshGeometry.path`` is stored relative to the manifest file's
        parent directory so the manifest stays portable.

        Args:
            module:        Module dataclass from SC-01 ModuleManager.
            manifest_path: Absolute path of the manifest file being written.

        Returns:
            A :class:`~kfs_core.manifest_models.KFSObject` with inline
            :class:`~kfs_core.manifest_models.MeshGeometry`.
        """
        from kfs_core.manifest_models import KFSObject, MeshGeometry, Transform  # noqa: PLC0415

        stl_abs = Path(self.output_dir) / module.id / f"{module.id}.stl"
        manifest_dir = manifest_path.parent

        try:
            rel_path = os.path.relpath(str(stl_abs), start=str(manifest_dir))
        except ValueError:
            # os.path.relpath raises ValueError on Windows when paths cross
            # drive letters.  Fall back to the absolute path.
            rel_path = str(stl_abs)

        # Normalise separators to forward slashes for cross-platform YAML
        rel_path = rel_path.replace("\\", "/")

        geometry = MeshGeometry(
            id=f"{module.id}_mesh",
            path=rel_path,
        )

        return KFSObject(
            id=module.id,
            name=module.name,
            geometry=geometry,
            transform=Transform(),
        )
