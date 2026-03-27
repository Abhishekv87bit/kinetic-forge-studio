"""
KFS application configuration.
Settings are read from environment variables with sensible defaults.
"""
import os
from pathlib import Path

# Resolve repo root: backend/app/config.py → repo root is three levels up
_REPO_ROOT = Path(__file__).resolve().parent.parent.parent


class Settings:
    """Application-wide settings loaded from environment variables."""

    # Database
    database_url: str

    # VLAD validator script location
    vlad_script_path: str

    # CadQuery execution sandbox timeout (seconds)
    cadquery_timeout: int

    # Output directory for generated geometry files
    models_dir: str

    def __init__(self) -> None:
        self.database_url = os.environ.get(
            "DATABASE_URL",
            f"sqlite:///{_REPO_ROOT / 'kfs.db'}",
        )
        self.vlad_script_path = os.environ.get(
            "VLAD_SCRIPT_PATH",
            str(_REPO_ROOT / "tools" / "vlad.py"),
        )
        self.cadquery_timeout = int(os.environ.get("CADQUERY_TIMEOUT", "120"))
        self.models_dir = os.environ.get(
            "MODELS_DIR",
            str(_REPO_ROOT / "models"),
        )


settings = Settings()
