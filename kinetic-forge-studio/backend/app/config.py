from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from pathlib import Path

class Settings(BaseSettings):
    model_config = ConfigDict(env_prefix="KFS_")

    app_name: str = "Kinetic Forge Studio"
    version: str = "0.1.0"
    debug: bool = True
    data_dir: Path = Path.home() / ".kinetic-forge-studio"
    projects_dir: Path = Path.home() / ".kinetic-forge-studio" / "projects"
    library_dir: Path = Path.home() / ".kinetic-forge-studio" / "library"
    openscad_path: str = "C:/Program Files/OpenSCAD (Nightly)/openscad.com"
    openscad_lib_path: str = "C:/Users/abhis/Documents/OpenSCAD/libraries"
    freecad_path: str = "C:/Program Files/FreeCAD 1.0/bin/FreeCADCmd.exe"
    claude_api_key: str = ""
    claude_model: str = "claude-sonnet-4-20250514"
    claude_max_tokens: int = 4096
    cors_origins: list[str] = ["*"]

    # Pipeline tool paths (external validation scripts)
    pipeline_dir: Path = Path("D:/Claude local/3d_design_agent")

    @property
    def validate_geometry_script(self) -> Path:
        return self.pipeline_dir / "waffle_grid_planetary" / "validate_geometry.py"

    @property
    def consistency_audit_script(self) -> Path:
        return self.pipeline_dir / "waffle_grid_planetary" / "consistency_audit.py"

    @property
    def tolerance_stackup_script(self) -> Path:
        return self.pipeline_dir / "triple_helix_mvp" / "check point" / "tolerance_stack.py"

    @property
    def iso286_script(self) -> Path:
        return self.pipeline_dir / "production_pipeline" / "iso286_lookup.py"

settings = Settings()
