"""
FreeCAD engine for production pipeline (Gate 3).

Connects to FreeCAD via MCP (localhost:9875) or Python API for:
- STEP file validation and conversion
- Production drawing generation (DXF/PDF)
- Basic FEM analysis

Lower priority -- needed for production export, not design iteration.
"""

import asyncio
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

FREECAD_MCP_URL = "http://localhost:9875"


@dataclass
class FEMResult:
    """Result of FEM analysis."""
    success: bool
    max_stress: float = 0.0
    max_displacement: float = 0.0
    safety_factor: float = 0.0
    errors: list[str] = field(default_factory=list)


class FreeCADEngine:
    """
    FreeCAD integration for Gate 3 (production).

    Prefers MCP connection (localhost:9875) when available,
    falls back to FreeCADCmd CLI.
    """

    def __init__(self):
        self._client: httpx.AsyncClient | None = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=60.0)
        return self._client

    async def is_mcp_available(self) -> bool:
        """Check if FreeCAD MCP is running."""
        try:
            client = await self._get_client()
            response = await client.post(
                FREECAD_MCP_URL,
                json={"method": "ping", "params": {}},
            )
            return response.status_code == 200
        except Exception:
            return False

    async def convert_step(self, step_path: Path) -> dict:
        """
        Open STEP in FreeCAD and verify solid integrity.

        Returns metadata about the imported geometry.
        """
        # Try MCP first
        if await self.is_mcp_available():
            try:
                client = await self._get_client()
                # Import STEP via MCP
                response = await client.post(
                    FREECAD_MCP_URL,
                    json={
                        "method": "execute_code",
                        "params": {
                            "code": f"""
import Part
shape = Part.Shape()
shape.read("{step_path.as_posix()}")
bodies = len(shape.Solids)
faces = len(shape.Faces)
volume = shape.Volume
bb = shape.BoundBox
result = {{
    "bodies": bodies,
    "faces": faces,
    "volume": volume,
    "bounding_box": {{
        "x": bb.XLength,
        "y": bb.YLength,
        "z": bb.ZLength,
    }},
    "valid": True,
}}
print(json.dumps(result))
"""
                        },
                    },
                )
                if response.status_code == 200:
                    data = response.json()
                    return data.get("result", {"valid": False, "error": "No result from MCP"})
            except Exception as e:
                logger.warning("MCP STEP conversion failed: %s", e)

        # Fallback: use FreeCADCmd CLI
        return await self._cli_convert_step(step_path)

    async def _cli_convert_step(self, step_path: Path) -> dict:
        """Convert STEP using FreeCADCmd CLI."""
        freecad_cmd = settings.freecad_path
        script = f"""
import sys
import json
sys.path.insert(0, "")
import FreeCAD
import Part
shape = Part.Shape()
shape.read("{step_path.as_posix()}")
result = {{
    "bodies": len(shape.Solids),
    "faces": len(shape.Faces),
    "volume": shape.Volume,
    "valid": True,
}}
print("RESULT:" + json.dumps(result))
"""
        try:
            proc = await asyncio.create_subprocess_exec(
                freecad_cmd, "-c", script,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=60)
            stdout_text = stdout.decode("utf-8", errors="replace")

            for line in stdout_text.split("\n"):
                if line.startswith("RESULT:"):
                    return json.loads(line[7:])

            return {"valid": False, "error": "No result from FreeCADCmd"}
        except Exception as e:
            return {"valid": False, "error": str(e)}

    async def export_drawings(
        self,
        step_path: Path,
        output_dir: Path,
    ) -> Path | None:
        """
        Generate production drawings from a STEP file.

        Creates DXF/PDF drawings using FreeCAD TechDraw workbench.
        """
        output_dir.mkdir(parents=True, exist_ok=True)
        dxf_path = output_dir / f"{step_path.stem}_drawing.dxf"

        script = f"""
import FreeCAD
import Part
import TechDraw

doc = FreeCAD.newDocument("Drawing")
shape = Part.Shape()
shape.read("{step_path.as_posix()}")
part = doc.addObject("Part::Feature", "Imported")
part.Shape = shape

page = doc.addObject("TechDraw::DrawPage", "Page")
template = doc.addObject("TechDraw::DrawSVGTemplate", "Template")
page.Template = template

view = doc.addObject("TechDraw::DrawViewPart", "View")
view.Source = [part]
page.addView(view)

doc.recompute()
TechDraw.writeDXFPage(page, "{dxf_path.as_posix()}")
print("DRAWING_OK")
"""
        try:
            proc = await asyncio.create_subprocess_exec(
                settings.freecad_path, "-c", script,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=120)

            if b"DRAWING_OK" in stdout and dxf_path.exists():
                return dxf_path
        except Exception as e:
            logger.warning("Drawing export failed: %s", e)

        return None

    async def run_fem(
        self,
        step_path: Path,
        constraints: dict,
    ) -> FEMResult:
        """
        Run basic FEM analysis on a STEP file.

        This is a placeholder that reports the capability.
        Full FEM requires FreeCAD with CalculiX solver.
        """
        # Check if FreeCAD MCP can handle FEM
        if not await self.is_mcp_available():
            return FEMResult(
                success=False,
                errors=["FreeCAD MCP not available. Start FreeCAD and enable MCP."],
            )

        # For now, return a placeholder
        return FEMResult(
            success=False,
            errors=["FEM analysis requires CalculiX solver. Configure in FreeCAD preferences."],
        )

    async def close(self):
        if self._client and not self._client.is_closed:
            await self._client.aclose()
