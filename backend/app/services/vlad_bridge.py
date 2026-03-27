"""
VladBridge — Generates a temporary Python module that adapts a KFS module
to the VLAD validator's expected interface.

VLAD requires a module to expose three functions:
    get_fixed_parts()    -> dict[str, cq.Workplane]
    get_moving_parts()   -> dict[str, tuple[cq.Workplane, str, float, float]]
    get_mechanism_type() -> str

KFS modules that already define these functions are passed through unchanged.
Modules that do not define them get synthesised stubs that attempt to extract
geometry from a top-level ``result`` variable.
"""
import os
import tempfile
import textwrap
from pathlib import Path
from typing import Optional


# Appended to every bridge file; uses Python's module-level ``hasattr`` check
# so that modules which already define the VLAD interface are never overridden.
_VLAD_STUB = textwrap.dedent(
    """\

    # ── VLAD Bridge (auto-generated) ──────────────────────────────────────────
    import sys as _vlad_sys
    _vlad_mod = _vlad_sys.modules[__name__]

    if not hasattr(_vlad_mod, 'get_mechanism_type'):
        def get_mechanism_type():
            return {mechanism_type!r}

    if not hasattr(_vlad_mod, 'get_fixed_parts'):
        def get_fixed_parts():
            _result = getattr(_vlad_mod, 'result', None)
            if _result is not None:
                return {{'part': _result}}
            return {{}}

    if not hasattr(_vlad_mod, 'get_moving_parts'):
        def get_moving_parts():
            return {{}}
    # ─────────────────────────────────────────────────────────────────────────
    """
)


class VladBridge:
    """
    Wraps a KFS module's source code in a VLAD-compatible bridge file.

    Usage::

        bridge = VladBridge(module_code, mechanism_type="slider")
        bridge_path = bridge.write_bridge()          # returns Path to .py file
        # ... pass bridge_path to VladRunner ...
        bridge.cleanup()                             # removes temp files
    """

    def __init__(self, module_code: str, mechanism_type: str = "slider") -> None:
        self.module_code = module_code
        self.mechanism_type = mechanism_type
        self._tmpdir: Optional[str] = None
        self._bridge_path: Optional[Path] = None

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def write_bridge(self, dest_dir: Optional[Path] = None) -> Path:
        """
        Write the bridge module to disk and return its path.

        Parameters
        ----------
        dest_dir:
            Directory in which to write the bridge file.  When *None* a
            temporary directory is created automatically and cleaned up by
            :meth:`cleanup`.

        Returns
        -------
        Path
            Absolute path to the generated ``vlad_bridge_<uid>.py`` file.
        """
        if dest_dir is None:
            self._tmpdir = tempfile.mkdtemp(prefix="kfs_vlad_bridge_")
            dest_dir = Path(self._tmpdir)

        dest_dir = Path(dest_dir)
        dest_dir.mkdir(parents=True, exist_ok=True)

        # Unique filename per bridge instance avoids collisions when multiple
        # bridges exist in the same directory simultaneously.
        uid = os.urandom(4).hex()
        bridge_filename = f"vlad_bridge_{uid}.py"
        bridge_path = dest_dir / bridge_filename

        stub = _VLAD_STUB.format(mechanism_type=self.mechanism_type)
        bridge_path.write_text(
            self.module_code + "\n" + stub,
            encoding="utf-8",
        )

        self._bridge_path = bridge_path
        return bridge_path

    def cleanup(self) -> None:
        """Remove the temporary directory created by :meth:`write_bridge`."""
        if self._tmpdir and os.path.isdir(self._tmpdir):
            import shutil
            shutil.rmtree(self._tmpdir, ignore_errors=True)
            self._tmpdir = None
            self._bridge_path = None

    # ------------------------------------------------------------------
    # Context manager support
    # ------------------------------------------------------------------

    def __enter__(self) -> "VladBridge":
        return self

    def __exit__(self, *_: object) -> None:
        self.cleanup()

    # ------------------------------------------------------------------
    # Repr
    # ------------------------------------------------------------------

    def __repr__(self) -> str:
        return (
            f"VladBridge(mechanism_type={self.mechanism_type!r}, "
            f"bridge_path={self._bridge_path})"
        )
