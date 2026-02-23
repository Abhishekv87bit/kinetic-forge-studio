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
    freecad_path: str = "C:/Program Files/FreeCAD 1.0/bin/FreeCADCmd.exe"
    claude_api_key: str = ""
    cors_origins: list[str] = ["http://localhost:5173"]

settings = Settings()
